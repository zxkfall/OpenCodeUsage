import Foundation
import Security

struct Credentials: Codable {
    var workspaceId: String  // wrk_01XXXXXXXX
    var authCookie: String   // Fe26.2**...
}

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

    func save(_ credentials: Credentials) {
        guard let data = try? JSONEncoder().encode(credentials) else { return }
        delete()
        SecItemAdd(query(service: service, data: data) as CFDictionary, nil)
    }

    func load() -> Credentials? {
        var item: CFTypeRef?
        var q = query(service: service)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne

        // Try new service name first
        if SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess,
           let data = item as? Data {
            return try? JSONDecoder().decode(Credentials.self, from: data)
        }

        // Migrate from old service name
        var oldQ = query(service: oldService)
        oldQ[kSecReturnData as String] = true
        oldQ[kSecMatchLimit as String] = kSecMatchLimitOne
        if SecItemCopyMatching(oldQ as CFDictionary, &item) == errSecSuccess,
           let data = item as? Data,
           let creds = try? JSONDecoder().decode(Credentials.self, from: data) {
            save(creds)
            SecItemDelete(query(service: oldService) as CFDictionary)
            return creds
        }

        return nil
    }

    func delete() {
        SecItemDelete(query(service: service) as CFDictionary)
        SecItemDelete(query(service: oldService) as CFDictionary)
    }
}

// MARK: - Usage Data Models

struct UsageWindow: Codable {
    let status: String
    let resetInSec: Int
    let usagePercent: Int

    var pct: Double { Double(usagePercent) }
    var resetDescription: String {
        if resetInSec <= 0 { return "now" }
        let h = resetInSec / 3600
        let m = (resetInSec % 3600) / 60
        if h > 24 { return "\(h / 24)d \(h % 24)h" }
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

struct GoUsage: Codable {
    let rolling: UsageWindow
    let weekly: UsageWindow
    let monthly: UsageWindow
    let region: [String]
    let useBalance: Bool
    let error: String?
}

// MARK: - Usage Fetcher

class UsageFetcher: ObservableObject {
    @Published var usage: GoUsage?
    @Published var isLoading = false
    @Published var error: String?

    private var timer: Timer?

    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.start()
        }
    }

    func start(interval: TimeInterval = 300) {
        fetch()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.fetch()
        }
    }

    func fetch() {
        guard let creds = KeychainManager.shared.load() else {
            DispatchQueue.main.async { self.error = "Not configured. Open Settings to set up." }
            return
        }
        guard !creds.workspaceId.isEmpty, !creds.authCookie.isEmpty else {
            DispatchQueue.main.async { self.error = "Missing credentials." }
            return
        }

        DispatchQueue.main.async { self.isLoading = true }

        let url = URL(string: "https://opencode.ai/workspace/\(creds.workspaceId)/go")!
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("auth=\(creds.authCookie)", forHTTPHeaderField: "Cookie")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
                return
            }

            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self.error = "Invalid response"
                    self.isLoading = false
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                DispatchQueue.main.async {
                    self.error = "HTTP \(httpResponse.statusCode) — cookie may have expired"
                    self.isLoading = false
                }
                return
            }

            let parsed = self.parseUsage(from: html)
            let encoded = try? JSONEncoder().encode(parsed)

            DispatchQueue.main.async {
                self.usage = parsed
                self.error = parsed.error
                self.isLoading = false
            }

            // Write to App Group for widget AND to widget's sandbox
            if let encoded = encoded {
                // App Group containers
                let home = FileManager.default.homeDirectoryForCurrentUser
                let groupDir = home.appendingPathComponent("Library/Group Containers")
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: groupDir.path) {
                    for item in contents where item.contains("opencode") {
                        let fileURL = groupDir.appendingPathComponent(item).appendingPathComponent("usage.json")
                        try? encoded.write(to: fileURL)
                    }
                }
                // Widget's sandbox container (bypasses App Group sandbox issue)
                let widgetSandbox = home.appendingPathComponent("Library/Containers/com.flywinter.opencode-usage-bar.widget/Data/Documents")
                try? FileManager.default.createDirectory(at: widgetSandbox, withIntermediateDirectories: true)
                try? encoded.write(to: widgetSandbox.appendingPathComponent("usage.json"))
            }
        }.resume()
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
