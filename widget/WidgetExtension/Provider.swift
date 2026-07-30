import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        completion(UsageEntry.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        let entry = loadUsageData()
        let next = Date().addingTimeInterval(300)
        let timeline = Timeline(entries: [entry], policy: .after(next))
        completion(timeline)
    }
}

struct UsageEntry: TimelineEntry {
    let date: Date
    let rollingPct: Int
    let rollingReset: String
    let weeklyPct: Int
    let weeklyReset: String
    let monthlyPct: Int
    let monthlyReset: String
    let isError: Bool
    let errorMessage: String

    static var placeholder: UsageEntry {
        UsageEntry(date: Date(), rollingPct: 0, rollingReset: "",
                   weeklyPct: 0, weeklyReset: "", monthlyPct: 0, monthlyReset: "",
                   isError: false, errorMessage: "")
    }
}

func loadUsageData() -> UsageEntry {
    guard let groupId = getAppGroupId(),
          let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupId
          ) else {
        return errorEntry("App Group not configured")
    }

    let dataURL = containerURL.appendingPathComponent("usage.json")

    guard let data = try? Data(contentsOf: dataURL),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return errorEntry("No data")
    }

    if let err = json["error"] as? String, !err.isEmpty {
        return errorEntry(err)
    }

    func window(_ key: String) -> [String: Any]? { json[key] as? [String: Any] }

    let r = window("rolling")
    let w = window("weekly")
    let m = window("monthly")

    return UsageEntry(
        date: Date(),
        rollingPct: r?["usagePercent"] as? Int ?? 0,
        rollingReset: formatReset(r?["resetInSec"] as? Int ?? 0),
        weeklyPct: w?["usagePercent"] as? Int ?? 0,
        weeklyReset: formatReset(w?["resetInSec"] as? Int ?? 0),
        monthlyPct: m?["usagePercent"] as? Int ?? 0,
        monthlyReset: formatReset(m?["resetInSec"] as? Int ?? 0),
        isError: false,
        errorMessage: ""
    )
}

func formatReset(_ sec: Int) -> String {
    if sec <= 0 { return "now" }
    let h = sec / 3600
    let m = (sec % 3600) / 60
    if h > 24 { return "\(h / 24)d \(h % 24)h" }
    if h > 0 { return "\(h)h \(m)m" }
    return "\(m)m"
}

func errorEntry(_ msg: String) -> UsageEntry {
    UsageEntry(date: Date(), rollingPct: 0, rollingReset: "",
               weeklyPct: 0, weeklyReset: "", monthlyPct: 0, monthlyReset: "",
               isError: true, errorMessage: msg)
}
