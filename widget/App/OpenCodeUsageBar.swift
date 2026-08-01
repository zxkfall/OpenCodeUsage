import AppKit
import SwiftUI

// MARK: - Settings Window

class SettingsWindowController: NSObject {
    private var window: NSWindow?

    func show(fetcher: UsageFetcher) {
        if let win = window {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "OpenCode Go — Settings"
        win.contentView = NSHostingView(rootView: SettingsView(fetcher: fetcher) { [weak win] in
            win?.close()
        })
        win.center()
        win.isReleasedWhenClosed = false
        window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct SettingsView: View {
    @ObservedObject var fetcher: UsageFetcher
    let onDismiss: () -> Void

    @State private var accounts: [Account] = []
    @State private var selection: AccountSelection = .fixed
    @State private var fixedAccountIndex = 0
    @State private var rotationInterval = 10
    @State private var saved = false

    init(fetcher: UsageFetcher, onDismiss: @escaping () -> Void) {
        self.fetcher = fetcher
        self.onDismiss = onDismiss
        let settings = fetcher.settings
        _accounts = State(initialValue: settings.accounts.isEmpty ? [Account()] : settings.accounts)
        _selection = State(initialValue: settings.selection)
        _fixedAccountIndex = State(initialValue: settings.fixedAccountIndex)
        _rotationInterval = State(initialValue: settings.rotationIntervalSec)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("OpenCode Go Usage Settings")
                    .font(.title2)
                    .bold()

                Divider()

                // Accounts section
                Text("账户 (\(accounts.count)/\(AppSettings.maxAccounts))")
                    .font(.headline)

                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, _ in
                    accountEditor(index: index)
                }

                if accounts.count < AppSettings.maxAccounts {
                    Button("+ 添加账户") {
                        accounts.append(Account())
                    }
                    .disabled(accounts.count >= AppSettings.maxAccounts)
                }

                Divider()

                // Display config section
                Text("显示配置")
                    .font(.headline)

                Picker("账户间规则", selection: $selection) {
                    ForEach(AccountSelection.allCases, id: \.self) { s in
                        Text(s.displayName).tag(s)
                    }
                }
                .pickerStyle(.segmented)

                if selection == .fixed {
                    Picker("显示账户", selection: $fixedAccountIndex) {
                        ForEach(Array(accounts.enumerated()), id: \.element.id) { index, acc in
                            Text(acc.displayName).tag(index)
                        }
                    }
                    .disabled(accounts.isEmpty)
                }

                if selection == .rotate {
                    Stepper("轮换间隔: \(rotationInterval) 秒", value: $rotationInterval, in: 1...300)
                }

                Divider()

                // How to find credentials
                Text("如何获取凭据:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("1. Open https://opencode.ai/auth in browser and sign in")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("2. Go to your Go workspace page (URL contains wrk_.../go)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("3. DevTools → Application → Cookies → opencode.ai")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("4. Copy the \"auth\" cookie value (starts with Fe26.2)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack {
                    if saved {
                        Text("Saved").foregroundColor(.green)
                    }
                    Spacer()
                    Button("Save & Fetch Now") {
                        let cleaned = accounts.map { acc in
                            Account(id: acc.id,
                                    name: acc.name.trimmingCharacters(in: .whitespaces),
                                    workspaceId: acc.workspaceId.trimmingCharacters(in: .whitespaces),
                                    authCookie: acc.authCookie.trimmingCharacters(in: .whitespaces),
                                    metric: acc.metric)
                        }.filter { !$0.workspaceId.isEmpty && !$0.authCookie.isEmpty }

                        var newSettings = AppSettings()
                        newSettings.accounts = cleaned
                        newSettings.selection = selection
                        newSettings.fixedAccountIndex = min(fixedAccountIndex, max(cleaned.count - 1, 0))
                        newSettings.rotationIntervalSec = rotationInterval

                        KeychainManager.shared.saveSettings(newSettings)
                        fetcher.settings = newSettings
                        fetcher.startRotation()
                        saved = true
                        fetcher.fetch()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onDismiss() }
                    }
                    .keyboardShortcut(.return)
                    .disabled(accounts.filter { !$0.workspaceId.isEmpty && !$0.authCookie.isEmpty }.isEmpty)
                }
            }
            .padding(24)
            .frame(minWidth: 520)
        }
        .frame(minWidth: 560, minHeight: 500)
    }

    @ViewBuilder
    private func accountEditor(index: Int) -> some View {
        let binding = $accounts[index]
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("账户 \(index + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("删除") {
                    accounts.remove(at: index)
                }
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }

            HStack(spacing: 8) {
                TextField("名称(可选)", text: binding.name)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                Picker("", selection: binding.metric) {
                    ForEach(WindowMetric.allCases, id: \.self) { m in
                        Text(m.displayName).tag(m)
                    }
                }
                .labelsHidden()
                .frame(width: 100)
            }

            TextField("Workspace ID", text: binding.workspaceId)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            SecureField("Auth Cookie", text: binding.authCookie)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Menu Bar App

@main
struct OpenCodeUsageApp: App {
    @StateObject private var fetcher = UsageFetcher()
    private let settingsController = SettingsWindowController()

    var body: some Scene {
        MenuBarExtra {
            menuContent
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    // MARK: - Menu Bar Label

    private var menuBarText: String {
        if let value = fetcher.menuBarValue() {
            return "Go \(value.pct)%"
        } else if fetcher.error != nil {
            return "Go"
        } else if fetcher.isLoading {
            return "Go ..."
        } else {
            return "Go"
        }
    }

    private var menuBarColor: Color {
        if let value = fetcher.menuBarValue() {
            return color(for: value.pct)
        }
        return .orange
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        Text(menuBarText)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(menuBarColor)
    }

    // MARK: - Menu Content

    @ViewBuilder
    private var menuContent: some View {
        if !fetcher.accountUsages.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                // Title bar
                HStack {
                    Text("OpenCode Go").font(.system(size: 13, weight: .semibold))
                    Spacer()
                    if fetcher.isLoading {
                        ProgressView().scaleEffect(0.5).frame(width: 12, height: 12)
                    }
                    Button(action: { settingsController.show(fetcher: fetcher) }) {
                        Image(systemName: "gearshape").font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                }
                .padding(.horizontal, 10).padding(.vertical, 6)

                Divider()

                ForEach(fetcher.settings.accounts) { account in
                    if let usage = fetcher.accountUsages.first(where: { $0.accountId == account.id }) {
                        AccountMenuRow(account: account, usage: usage)
                    }
                }

                Divider()

                HStack(spacing: 0) {
                    Button(action: { fetcher.fetch() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                        .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("r")
                    Spacer()
                    Button(action: { NSApp.terminate(nil) }) {
                        Text("Quit").font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("q")
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
            }
            .frame(width: 260)
        } else if let error = fetcher.error {
            VStack(spacing: 8) {
                Text("OpenCode Go").font(.headline)
                Text(error)
                    .font(.caption)
                    .foregroundColor(redIfError(error) ? .red : .secondary)
                HStack {
                    Button("Settings") { settingsController.show(fetcher: fetcher) }
                    Button("Retry") { fetcher.fetch() }
                }
            }
            .padding()
            .frame(width: 260)
        } else {
            VStack {
                ProgressView()
                Text("Loading...").font(.caption).padding(.top, 4)
            }
            .padding()
            .frame(width: 160)
        }
    }

    // MARK: - Helpers

    private func color(for pct: Int) -> Color {
        if pct > 80 { return .red }
        if pct > 50 { return .orange }
        return .green
    }

    private func redIfError(_ msg: String) -> Bool {
        msg.contains("expired") || msg.contains("401") || msg.contains("403")
    }
}

// MARK: - Account Menu Row (expandable)

struct AccountMenuRow: View {
    let account: Account
    let usage: AccountUsage
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Summary line
            Button(action: { withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() } }) {
                HStack(spacing: 6) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text(account.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    summaryLabel
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)

            if expanded {
                VStack(alignment: .leading, spacing: 0) {
                    WindowRow(label: "5h", window: usage.rolling)
                    WindowRow(label: "Week", window: usage.weekly)
                    WindowRow(label: "Month", window: usage.monthly)
                }
                .padding(.leading, 8)
            }
        }
    }

    @ViewBuilder
    private var summaryLabel: some View {
        let result = representativeResult(for: usage, metric: account.metric)
        let windowTag: String = {
            switch account.metric {
            case .max: return "Max·\(result.window.displayName)"
            case .min: return "Min·\(result.window.displayName)"
            default: return result.window.displayName
            }
        }()
        HStack(spacing: 5) {
            Text(windowTag)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .frame(width: 62, alignment: .trailing)
            Text("\(result.pct)%")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(result.pct > 80 ? .red :
                                  result.pct > 50 ? .orange : .green)
                .frame(width: 34, alignment: .trailing)
        }
    }
}

// MARK: - Window Row

struct WindowRow: View {
    let label: String
    let window: UsageWindow

    var body: some View {
        let pct = window.usagePercent
        let barColor: Color = pct > 80 ? .red : pct > 50 ? .orange : .green

        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 42, alignment: .leading)
            Text("\(pct)%")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(barColor)
                .frame(width: 36, alignment: .trailing)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.primary.opacity(0.1))
                .frame(width: 96, height: 4)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor)
                        .frame(width: 96 * min(Double(pct) / 100.0, 1.0), height: 4)
                }
            Text(window.resetDescription)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .frame(width: 42, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .frame(height: 22)
    }
}
