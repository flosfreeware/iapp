import AppKit
import Carbon.HIToolbox
import ServiceManagement
import SwiftUI

@main
struct IApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // iapp owns its windows explicitly so a login launch remains unobtrusive.
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let launcher = LauncherController()
    private let info = InfoWindowController()
    private var commandPressInterceptor: CommandPressInterceptor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // no Dock icon and no menu-bar item
        commandPressInterceptor = CommandPressInterceptor { [weak self] in self?.launcher.toggle() }

        if InstallationState.isFirstLaunch {
            info.showInstallation()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { info.showInfo() }
        return true
    }
}

private enum InstallationState {
    private static let installedAtKey = "installedAt"
    static var isFirstLaunch: Bool { UserDefaults.standard.object(forKey: installedAtKey) == nil }

    static var installedAt: Date {
        if let date = UserDefaults.standard.object(forKey: installedAtKey) as? Date { return date }
        let now = Date()
        UserDefaults.standard.set(now, forKey: installedAtKey)
        return now
    }
}

private final class InfoWindowController: NSWindowController {
    private var mode: InfoMode = .info

    func showInstallation() {
        mode = .installation
        showWindow(nil)
    }

    func showInfo() {
        mode = .info
        showWindow(nil)
    }

    override func loadWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "iapp"
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
    }

    override func showWindow(_ sender: Any?) {
        if window == nil { loadWindow() }
        guard let window else { return }
        window.contentView = NSHostingView(rootView: InfoView(mode: mode, close: { [weak self] in
            self?.close()
        }))
        super.showWindow(sender)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private enum InfoMode { case info, installation }

private struct InfoView: View {
    let mode: InfoMode
    let close: () -> Void
    @State private var startAtLogin = true
    @State private var loginItemError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(mode == .installation ? "Welcome to iapp" : "iapp")
                .font(.title2.weight(.semibold))

            if mode == .installation {
                Text("A quiet, instant application launcher.")
                    .foregroundStyle(.secondary)
                Text("Press and release Command on its own to open the launcher.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Open iapp at login", isOn: $startAtLogin)
                if let loginItemError {
                    Text(loginItemError).font(.caption).foregroundStyle(.red)
                }
                HStack {
                    Spacer()
                    Button("Continue") { finishInstallation() }
                        .keyboardShortcut(.defaultAction)
                }
            } else {
                LabeledContent("Contact", value: "contact@iapp.app")
                LabeledContent("Installed", value: InstallationState.installedAt.formatted(date: .long, time: .shortened))
                Divider()
                Text("Press and release Command on its own to open the launcher.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack {
                    Spacer()
                    Button("Close", action: close).keyboardShortcut(.cancelAction)
                }
            }
        }
        .padding(22)
        .frame(width: 360, height: 220, alignment: .topLeading)
    }

    private func finishInstallation() {
        _ = InstallationState.installedAt
        if startAtLogin {
            do { try SMAppService.mainApp.register() }
            catch { loginItemError = "Could not enable login item: \(error.localizedDescription)"; return }
        }
        close()
    }

}
