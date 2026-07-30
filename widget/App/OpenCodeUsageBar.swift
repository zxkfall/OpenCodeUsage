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
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 360),
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
    @State private var workspaceId: String = ""
    @State private var authCookie: String = ""
    @State private var saved = false
    let onDismiss: () -> Void

    init(fetcher: UsageFetcher, onDismiss: @escaping () -> Void) {
        self.fetcher = fetcher
        self.onDismiss = onDismiss
        let creds = KeychainManager.shared.load()
        _workspaceId = State(initialValue: creds?.workspaceId ?? "")
        _authCookie = State(initialValue: creds?.authCookie ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OpenCode Go Usage Settings")
                .font(.title2)
                .bold()

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Workspace ID")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("wrk_01XXXXXXXX", text: $workspaceId)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Auth Cookie")
                    .font(.caption)
                    .foregroundColor(.secondary)
                SecureField("Fe26.2**...", text: $authCookie)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("How to find these:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("1. Open https://opencode.ai/auth in browser and sign in")
                    .font(.caption2)
                Text("2. Go to your Go workspace page (URL contains wrk_.../go)")
                    .font(.caption2)
                Text("3. DevTools → Application → Cookies → opencode.ai")
                    .font(.caption2)
                Text("4. Copy the \"auth\" cookie value (starts with Fe26.2)")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)

            HStack {
                if saved {
                    Text("Saved").foregroundColor(.green)
                }
                Spacer()
                Button("Save & Fetch Now") {
                    let creds = Credentials(workspaceId: workspaceId.trimmingCharacters(in: .whitespaces),
                                            authCookie: authCookie.trimmingCharacters(in: .whitespaces))
                    KeychainManager.shared.save(creds)
                    saved = true
                    fetcher.fetch()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onDismiss() }
                }
                .keyboardShortcut(.return)
                .disabled(workspaceId.isEmpty || authCookie.isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 440)
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
        if let usage = fetcher.usage, usage.error == nil {
            return "Go \(usage.monthly.usagePercent)%"
        } else if fetcher.error != nil {
            return "Go"
        } else if fetcher.isLoading {
            return "Go ..."
        } else {
            return "Go"
        }
    }

    private var menuBarColor: Color {
        if let usage = fetcher.usage, usage.error == nil {
            return color(for: usage.monthly.usagePercent)
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
        if let usage = fetcher.usage, usage.error == nil {
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

                WindowRow(label: "5h", window: usage.rolling)
                WindowRow(label: "Week", window: usage.weekly)
                WindowRow(label: "Month", window: usage.monthly)

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

// MARK: - Reusable Views

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
