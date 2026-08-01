import Foundation

// MARK: - Shared Models (compiled into both App and Widget targets)

enum WindowMetric: String, Codable, CaseIterable {
    case rolling, weekly, monthly, max, min

    var displayName: String {
        switch self {
        case .rolling: return "5h"
        case .weekly: return "Week"
        case .monthly: return "Month"
        case .max: return "Max"
        case .min: return "Min"
        }
    }
}

enum AccountSelection: String, Codable, CaseIterable {
    case fixed, max, min, rotate

    var displayName: String {
        switch self {
        case .fixed: return "固定账户"
        case .max: return "取最大"
        case .min: return "取最小"
        case .rotate: return "轮换"
        }
    }
}

struct AppSettings: Codable {
    var accounts: [Account] = []
    var selection: AccountSelection = .fixed
    var fixedAccountIndex: Int = 0
    var rotationIntervalSec: Int = 10

    static let maxAccounts = 3

    var nonSecretSettings: NonSecretSettings {
        NonSecretSettings(
            metrics: accounts.map(\.metric),
            selection: selection,
            rotationIntervalSec: rotationIntervalSec
        )
    }
}

/// Settings safe to expose to the sandboxed widget (no credentials).
struct NonSecretSettings: Codable {
    var metrics: [WindowMetric]
    var selection: AccountSelection
    var rotationIntervalSec: Int
}

struct Account: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var workspaceId: String = ""
    var authCookie: String = ""
    var metric: WindowMetric = .monthly

    var displayName: String {
        name.isEmpty ? workspaceId : name
    }
}

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

struct AccountUsage: Codable, Identifiable {
    var id: UUID { accountId }
    let accountId: UUID
    let name: String
    let rolling: UsageWindow
    let weekly: UsageWindow
    let monthly: UsageWindow
    let error: String?

    init(accountId: UUID, name: String, usage: GoUsage) {
        self.accountId = accountId
        self.name = name
        self.rolling = usage.rolling
        self.weekly = usage.weekly
        self.monthly = usage.monthly
        self.error = usage.error
    }

    init(accountId: UUID, name: String,
         rolling: UsageWindow, weekly: UsageWindow,
         monthly: UsageWindow, error: String?) {
        self.accountId = accountId
        self.name = name
        self.rolling = rolling
        self.weekly = weekly
        self.monthly = monthly
        self.error = error
    }
}

/// Combined payload written for the widget (all accounts + non-secret settings).
struct WidgetPayload: Codable {
    let accounts: [AccountUsage]
    let settings: NonSecretSettings
}

struct MetricResult {
    let pct: Int
    let window: WindowMetric
}

func representativeResult(for usage: AccountUsage, metric: WindowMetric) -> MetricResult {
    let rolling = usage.rolling.usagePercent
    let weekly = usage.weekly.usagePercent
    let monthly = usage.monthly.usagePercent

    switch metric {
    case .rolling: return MetricResult(pct: rolling, window: .rolling)
    case .weekly: return MetricResult(pct: weekly, window: .weekly)
    case .monthly: return MetricResult(pct: monthly, window: .monthly)
    case .max:
        let m = max(rolling, weekly, monthly)
        let w: WindowMetric = m == rolling ? .rolling : m == weekly ? .weekly : .monthly
        return MetricResult(pct: m, window: w)
    case .min:
        let m = min(rolling, weekly, monthly)
        let w: WindowMetric = m == rolling ? .rolling : m == weekly ? .weekly : .monthly
        return MetricResult(pct: m, window: w)
    }
}

func formatReset(_ sec: Int) -> String {
    if sec <= 0 { return "now" }
    let h = sec / 3600
    let m = (sec % 3600) / 60
    if h > 24 { return "\(h / 24)d \(h % 24)h" }
    if h > 0 { return "\(h)h \(m)m" }
    return "\(m)m"
}

// MARK: - App Group

func getAppGroupId() -> String? {
    if let id = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String,
       !id.contains("$(") {
        return id
    }
    if FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "com.flywinter.opencode-usage-bar"
    ) != nil {
        return "com.flywinter.opencode-usage-bar"
    }
    return nil
}
