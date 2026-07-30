import WidgetKit
import SwiftUI

struct OpenCodeUsageWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: UsageEntry

    var body: some View {
        Group {
            if entry.isError {
                VStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title3)
                        .foregroundColor(.orange)
                    Text(entry.errorMessage)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                switch family {
                case .systemSmall: SmallView(entry: entry)
                case .systemMedium: MediumView(entry: entry)
                case .systemLarge: LargeView(entry: entry)
                default: MediumView(entry: entry)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SmallView: View {
    let entry: UsageEntry
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "brain.head.profile")
                .font(.title3)
                .foregroundColor(color(entry.monthlyPct))
            Text("\(entry.monthlyPct)%")
                .font(.system(.title, design: .monospaced))
                .bold()
            Text("monthly")
                .font(.caption2)
                .foregroundColor(.secondary)
            Gauge(value: Double(entry.monthlyPct), in: 0...100) {}
                .tint(color(entry.monthlyPct))
                .gaugeStyle(.accessoryLinearCapacity)
            Text("resets \(entry.monthlyReset)")
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct MediumView: View {
    let entry: UsageEntry
    var body: some View {
        VStack(spacing: 6) {
            WideSegmentView(label: "Rolling (5h)", pct: entry.rollingPct, reset: entry.rollingReset)
            WideSegmentView(label: "Weekly", pct: entry.weeklyPct, reset: entry.weeklyReset)
            WideSegmentView(label: "Monthly", pct: entry.monthlyPct, reset: entry.monthlyReset)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

struct LargeView: View {
    let entry: UsageEntry
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.orange)
                Text("OpenCode Go Usage")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 10).padding(.top, 8).padding(.bottom, 4)

            Divider()

            VStack(spacing: 4) {
                Text("\(entry.monthlyPct)%")
                    .font(.system(size: 36, weight: .black, design: .monospaced))
                    .foregroundColor(color(entry.monthlyPct))
                Text("Monthly Usage")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Gauge(value: Double(entry.monthlyPct), in: 0...100) {}
                    .tint(color(entry.monthlyPct))
                    .gaugeStyle(.accessoryLinearCapacity)
                    .padding(.horizontal, 10)
                Text("Resets \(entry.monthlyReset)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 10)

            Divider()

            VStack(spacing: 6) {
                CompactRow(label: "Rolling (5h)", pct: entry.rollingPct, reset: entry.rollingReset)
                CompactRow(label: "Weekly", pct: entry.weeklyPct, reset: entry.weeklyReset)
                CompactRow(label: "Monthly", pct: entry.monthlyPct, reset: entry.monthlyReset)
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
        }
    }
}

struct CompactRow: View {
    let label: String
    let pct: Int
    let reset: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Spacer()
            Text("\(pct)%")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color(pct))
            Spacer()
            Text(reset)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Reusable

struct SegmentView: View {
    let label: String
    let pct: Int
    let reset: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(pct)%")
                .font(.system(.title2, design: .monospaced))
                .bold()
                .foregroundColor(color(pct))
            Gauge(value: Double(pct), in: 0...100) {}
                .tint(color(pct))
                .gaugeStyle(.accessoryLinearCapacity)
            Text(reset)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WideSegmentView: View {
    let label: String
    let pct: Int
    let reset: String

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(pct)%")
                    .font(.caption)
                    .bold()
                    .foregroundColor(color(pct))
                Text("reset \(reset)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color(pct))
                        .frame(width: geo.size.width * min(Double(pct)/100, 1), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

func color(_ pct: Int) -> Color {
    if pct > 80 { return .red }
    if pct > 50 { return .orange }
    return .green
}

// MARK: - Widget

struct OpenCodeUsageWidget: Widget {
    let kind = "OpenCodeUsageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            OpenCodeUsageWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("OpenCode Go Usage")
        .description("Rolling, weekly, and monthly usage at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
