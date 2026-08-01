import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        completion(loadUsageData())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        let (payload, _) = loadPayload()
        guard let payload, !payload.accounts.isEmpty else {
            let entry = errorEntry("No data")
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
            completion(timeline)
            return
        }

        let interval = max(payload.settings.rotationIntervalSec, 5)
        var entries: [UsageEntry] = []

        // If multiple accounts + rotate, create one entry per account; else just first account.
        let shouldRotate = payload.accounts.count > 1 && payload.settings.selection == .rotate
        if shouldRotate {
            for index in payload.accounts.indices {
                let date = Date().addingTimeInterval(TimeInterval(index) * Double(interval))
                let entry = makeEntry(from: payload, index: index, date: date)
                entries.append(entry)
            }
            let last = Date().addingTimeInterval(TimeInterval(payload.accounts.count) * Double(interval))
            let timeline = Timeline(entries: entries, policy: .after(last))
            completion(timeline)
        } else {
            let entry = makeEntry(from: payload, index: 0, date: Date())
            let next = Date().addingTimeInterval(300)
            let timeline = Timeline(entries: [entry], policy: .after(next))
            completion(timeline)
        }
    }

    private func makeEntry(from payload: WidgetPayload, index: Int, date: Date) -> UsageEntry {
        let idx = min(index, payload.accounts.count - 1)
        let au = payload.accounts[idx]
        let metric = payload.settings.metrics.indices.contains(idx) ? payload.settings.metrics[idx] : .monthly

        if let err = au.error, !err.isEmpty {
            return errorEntry(err, date: date)
        }
        return UsageEntry(
            date: date,
            accountName: au.name,
            rollingPct: au.rolling.usagePercent,
            rollingReset: formatReset(au.rolling.resetInSec),
            weeklyPct: au.weekly.usagePercent,
            weeklyReset: formatReset(au.weekly.resetInSec),
            monthlyPct: au.monthly.usagePercent,
            monthlyReset: formatReset(au.monthly.resetInSec),
            metric: metric,
            isError: false,
            errorMessage: ""
        )
    }
}

struct UsageEntry: TimelineEntry {
    let date: Date
    let accountName: String
    let rollingPct: Int
    let rollingReset: String
    let weeklyPct: Int
    let weeklyReset: String
    let monthlyPct: Int
    let monthlyReset: String
    let metric: WindowMetric
    let isError: Bool
    let errorMessage: String

    static var placeholder: UsageEntry {
        UsageEntry(date: Date(), accountName: "", rollingPct: 0, rollingReset: "",
                   weeklyPct: 0, weeklyReset: "", monthlyPct: 0, monthlyReset: "",
                   metric: .monthly, isError: false, errorMessage: "")
    }
}

func loadUsageData() -> UsageEntry {
    let (payload, _) = loadPayload()
    guard let payload, !payload.accounts.isEmpty else {
        return errorEntry("No data")
    }
    // For snapshot/placeholder, just show the first account.
    let au = payload.accounts[0]
    let metric = payload.settings.metrics.first ?? .monthly
    if let err = au.error, !err.isEmpty {
        return errorEntry(err)
    }
    return UsageEntry(date: Date(), accountName: au.name,
                      rollingPct: au.rolling.usagePercent,
                      rollingReset: formatReset(au.rolling.resetInSec),
                      weeklyPct: au.weekly.usagePercent,
                      weeklyReset: formatReset(au.weekly.resetInSec),
                      monthlyPct: au.monthly.usagePercent,
                      monthlyReset: formatReset(au.monthly.resetInSec),
                      metric: metric, isError: false, errorMessage: "")
}

private func loadPayload() -> (WidgetPayload?, URL?) {
    // Read from widget's own sandbox (written by app)
    if let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let dataURL = docsURL.appendingPathComponent("usage.json")
        if let payload = parsePayload(at: dataURL) { return (payload, dataURL) }
    }
    // Fallback: try App Group
    if let groupId = getAppGroupId(),
       let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: groupId
       ) {
        let dataURL = containerURL.appendingPathComponent("usage.json")
        if let payload = parsePayload(at: dataURL) { return (payload, dataURL) }
    }
    return (nil, nil)
}

private func parsePayload(at url: URL) -> WidgetPayload? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(WidgetPayload.self, from: data)
}

func errorEntry(_ msg: String, date: Date = Date()) -> UsageEntry {
    UsageEntry(date: date, accountName: "", rollingPct: 0, rollingReset: "",
               weeklyPct: 0, weeklyReset: "", monthlyPct: 0, monthlyReset: "",
               metric: .monthly, isError: true, errorMessage: msg)
}
