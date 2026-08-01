import Foundation
import Security

// MARK: - Legacy Credentials (for migration)

struct Credentials: Codable {
    var workspaceId: String
    var authCookie: String
}

// MARK: - Keychain Manager

class KeychainManager {
    static let shared = KeychainManager()
    private let service = "com.flywinter.opencode-usage-bar"
    private let oldService = "com.flywinter.opencode.usage-bar"
    private let account = "opencode-go"

    private func query(service: String, data: Data? = nil) -> [String: Any] {
        var q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        if let data = data {
            q[kSecValueData as String] = data
            q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        }
        return q
    }

    private func loadData(service: String) -> Data? {
        var q = query(service: service)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return data
    }

    func loadSettings() -> AppSettings {
        // New format: AppSettings JSON
        if let data = loadData(service: service),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return settings
        }

        // Migrate from old single-account Credentials format
        if let oldData = loadData(service: service),
           let creds = try? JSONDecoder().decode(Credentials.self, from: oldData) {
            var settings = AppSettings()
            settings.accounts = [Account(name: "", workspaceId: creds.workspaceId,
                                         authCookie: creds.authCookie, metric: .monthly)]
            saveSettings(settings)
            return settings
        }
        if let oldData = loadData(service: oldService),
           let creds = try? JSONDecoder().decode(Credentials.self, from: oldData) {
            var settings = AppSettings()
            settings.accounts = [Account(name: "", workspaceId: creds.workspaceId,
                                         authCookie: creds.authCookie, metric: .monthly)]
            saveSettings(settings)
            SecItemDelete(query(service: oldService) as CFDictionary)
            return settings
        }

        return AppSettings()
    }

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        SecItemDelete(query(service: service) as CFDictionary)
        SecItemAdd(query(service: service, data: data) as CFDictionary, nil)
    }

    func delete() {
        SecItemDelete(query(service: service) as CFDictionary)
        SecItemDelete(query(service: oldService) as CFDictionary)
    }
}

// MARK: - Usage Fetcher

class UsageFetcher: ObservableObject {
    @Published var accountUsages: [AccountUsage] = []
    @Published var settings: AppSettings
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentRotateIndex = 0

    private var timer: Timer?
    private var rotateTimer: Timer?

    init() {
        settings = KeychainManager.shared.loadSettings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.start()
        }
    }

    func start(interval: TimeInterval = 300) {
        fetch()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.fetch()
        }
        startRotation()
    }

    func startRotation() {
        rotateTimer?.invalidate()
        guard settings.accounts.count > 1, settings.selection == .rotate else {
            currentRotateIndex = 0
            return
        }
        let interval = Double(max(settings.rotationIntervalSec, 1))
        rotateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self, !self.settings.accounts.isEmpty else { return }
            self.currentRotateIndex = (self.currentRotateIndex + 1) % self.settings.accounts.count
        }
    }

    func fetch() {
        settings = KeychainManager.shared.loadSettings()
        let accounts = settings.accounts
        guard !accounts.isEmpty else {
            DispatchQueue.main.async { self.error = "Not configured. Open Settings to set up." }
            return
        }

        DispatchQueue.main.async { self.isLoading = true }
        let group = DispatchGroup()
        var results: [AccountUsage] = []
        let lock = NSLock()

        for account in accounts {
            group.enter()
            fetchAccount(account) { accountUsage in
                lock.lock()
                if let au = accountUsage { results.append(au) }
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            results.sort { $0.accountId.uuidString < $1.accountId.uuidString }
            self.accountUsages = results
            self.isLoading = false
            if results.count < accounts.count {
                self.error = "部分账户拉取失败"
            } else {
                self.error = nil
            }
            self.writeWidgetPayload()
        }
    }

    private func fetchAccount(_ account: Account, completion: @escaping (AccountUsage?) -> Void) {
        guard !account.workspaceId.isEmpty, !account.authCookie.isEmpty else {
            completion(nil)
            return
        }

        let url = URL(string: "https://opencode.ai/workspace/\(account.workspaceId)/go")!
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("auth=\(account.authCookie)", forHTTPHeaderField: "Cookie")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { completion(nil); return }

            if let error = error {
                completion(self.errorAccount(account, message: error.localizedDescription))
                return
            }

            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(self.errorAccount(account, message: "Invalid response"))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(self.errorAccount(account, message: "HTTP \(httpResponse.statusCode) — cookie may have expired"))
                return
            }

            let parsed = self.parseUsage(from: html)
            if let err = parsed.error {
                completion(AccountUsage(accountId: account.id, name: account.displayName,
                                        rolling: parsed.rolling, weekly: parsed.weekly,
                                        monthly: parsed.monthly, error: err))
            } else {
                completion(AccountUsage(accountId: account.id, name: account.displayName, usage: parsed))
            }
        }.resume()
    }

    private func errorAccount(_ account: Account, message: String) -> AccountUsage {
        AccountUsage(accountId: account.id, name: account.displayName,
                     rolling: UsageWindow(status: "error", resetInSec: 0, usagePercent: 0),
                     weekly: UsageWindow(status: "error", resetInSec: 0, usagePercent: 0),
                     monthly: UsageWindow(status: "error", resetInSec: 0, usagePercent: 0),
                     error: message)
    }

    private func writeWidgetPayload() {
        let payload = WidgetPayload(accounts: accountUsages, settings: settings.nonSecretSettings)
        guard let encoded = try? JSONEncoder().encode(payload) else { return }

        let home = FileManager.default.homeDirectoryForCurrentUser
        // App Group containers
        let groupDir = home.appendingPathComponent("Library/Group Containers")
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: groupDir.path) {
            for item in contents where item.contains("opencode") {
                let fileURL = groupDir.appendingPathComponent(item).appendingPathComponent("usage.json")
                try? encoded.write(to: fileURL)
            }
        }
        // Widget's sandbox container
        let widgetSandbox = home.appendingPathComponent("Library/Containers/com.flywinter.opencode-usage-bar.widget/Data/Documents")
        try? FileManager.default.createDirectory(at: widgetSandbox, withIntermediateDirectories: true)
        try? encoded.write(to: widgetSandbox.appendingPathComponent("usage.json"))
    }

    // MARK: - Menu Bar Value

    func menuBarValue() -> (pct: Int, color: Int, text: String)? {
        guard !accountUsages.isEmpty else { return nil }
        let accounts = settings.accounts

        // Build representative results per account, preserving settings order
        var reps: [(account: Account, result: MetricResult)] = []
        for account in accounts {
            guard let usage = accountUsages.first(where: { $0.accountId == account.id }) else { continue }
            reps.append((account, representativeResult(for: usage, metric: account.metric)))
        }
        guard !reps.isEmpty else { return nil }

        let selection = settings.selection

        switch selection {
        case .fixed:
            let idx = min(settings.fixedAccountIndex, reps.count - 1)
            let r = reps[idx].result
            return (r.pct, r.pct, "\(r.window.displayName) \(r.pct)%")
        case .max:
            let best = reps.max(by: { $0.result.pct < $1.result.pct })!
            return (best.result.pct, best.result.pct, "\(best.result.window.displayName) \(best.result.pct)%")
        case .min:
            let worst = reps.min(by: { $0.result.pct < $1.result.pct })!
            return (worst.result.pct, worst.result.pct, "\(worst.result.window.displayName) \(worst.result.pct)%")
        case .rotate:
            let idx = min(currentRotateIndex, reps.count - 1)
            let r = reps[idx].result
            return (r.pct, r.pct, "\(r.window.displayName) \(r.pct)%")
        }
    }

    private func parseUsage(from html: String) -> GoUsage {
        func extract(_ name: String) -> UsageWindow? {
            let pattern = #"\#(name)Usage:\$R\[\d+\]=\{([^}]+)\}"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                  let capture = Range(match.range(at: 1), in: html)
            else { return nil }

            let body = String(html[capture])

            let statusPattern = #"status:"([^"]+)""#
            let resetPattern = #"resetInSec:(\d+)"#
            let pctPattern = #"usagePercent:(\d+)"#

            func find(_ p: String, in s: String) -> String? {
                guard let r = try? NSRegularExpression(pattern: p),
                      let m = r.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
                      let c = Range(m.range(at: 1), in: s) else { return nil }
                return String(s[c])
            }

            guard let status = find(statusPattern, in: body),
                  let resetStr = find(resetPattern, in: body),
                  let pctStr = find(pctPattern, in: body),
                  let resetSec = Int(resetStr),
                  let pct = Int(pctStr) else { return nil }

            return UsageWindow(status: status, resetInSec: resetSec, usagePercent: pct)
        }

        let rolling = extract("rolling") ?? UsageWindow(status: "error", resetInSec: 0, usagePercent: 0)
        let weekly = extract("weekly") ?? UsageWindow(status: "error", resetInSec: 0, usagePercent: 0)
        let monthly = extract("monthly") ?? UsageWindow(status: "error", resetInSec: 0, usagePercent: 0)

        if rolling.status == "error" && weekly.status == "error" && monthly.status == "error" {
            return GoUsage(rolling: rolling, weekly: weekly, monthly: monthly,
                           region: [], useBalance: false,
                           error: "Unable to parse usage data. The page format may have changed.")
        }

        return GoUsage(rolling: rolling, weekly: weekly, monthly: monthly,
                       region: [], useBalance: false, error: nil)
    }
}
