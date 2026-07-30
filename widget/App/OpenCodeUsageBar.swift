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
    }

    // MARK: - Menu Bar Label

    @ViewBuilder
    private var menuBarLabel: some View {
        if let usage = fetcher.usage, usage.error == nil {
            let pct = usage.monthly.usagePercent
            HStack(spacing: 3) {
                Image(systemName: icon(for: pct))
                    .foregroundColor(color(for: pct))
                    .font(.system(size: 8))
                Text("\(pct)%")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
        } else if fetcher.error != nil {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 10))
        } else if fetcher.isLoading {
            Text("...")
                .font(.system(size: 10, design: .monospaced))
        } else {
            Text("Go")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
        }
    }

    // MARK: - Menu Content

    @ViewBuilder
    private var menuContent: some View {
        if let usage = fetcher.usage, usage.error == nil {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.orange)
                    Text("OpenCode Go").font(.headline)
                    Spacer()
                    if fetcher.isLoading {
                        ProgressView().scaleEffect(0.6).frame(width: 14, height: 14)
                    }
                    Button(action: { settingsController.show(fetcher: fetcher) }) {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                }
                .padding(.horizontal, 12).padding(.vertical, 8)

                Divider()

                WindowRow(label: "Rolling (5h)", window: usage.rolling)
                WindowRow(label: "Weekly", window: usage.weekly)
                WindowRow(label: "Monthly", window: usage.monthly)

                Divider()

                Button(action: { fetcher.fetch() }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .keyboardShortcut("r")

                Divider()

                Button(action: { NSApp.terminate(nil) }) {
                    HStack {
                        Text("Quit")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .keyboardShortcut("q")
            }
            .frame(width: 280)
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

    private func icon(for pct: Int) -> String {
        if pct > 80 { return "circle.fill" }
        if pct > 50 { return "circle.lefthalf.filled" }
        return "circle"
    }

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
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.orange)
                Spacer()
                Text("\(window.usagePercent)%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(window.usagePercent > 80 ? .red :
                                      window.usagePercent > 50 ? .orange : .green)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(window.usagePercent > 80 ? Color.red :
                                window.usagePercent > 50 ? Color.orange : Color.green)
                        .frame(width: geo.size.width * min(Double(window.usagePercent) / 100.0, 1.0), height: 4)
                }
            }
            .frame(height: 4)

            Text("resets in \(window.resetDescription)")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
