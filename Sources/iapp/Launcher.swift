import AppKit
import SwiftUI

final class LauncherController {
    private let catalog = AppCatalog()
    private var panel: LauncherPanel?
    private var model: LauncherModel?
    private var escapeMonitor: Any?
    private var workspaceActivationObserver: NSObjectProtocol?
    private var launcherIsVisible = false

    func toggle() {
        if launcherIsVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard !launcherIsVisible else { return }
        catalog.refresh()
        let model = LauncherModel(catalog: catalog, dismiss: { [weak self] in self?.hide() })
        self.model = model
        let panel = LauncherPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 120),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        // This is a non-activating panel: hiding when iapp is inactive would
        // make it disappear immediately after the global shortcut opens it.
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.cancelHandler = { [weak self] in self?.hide() }
        panel.resignHandler = { [weak self] in self?.hide() }
        panel.contentView = NSHostingView(rootView: LauncherView(model: model))
        panel.center()
        self.panel = panel
        launcherIsVisible = true
        if let escapeMonitor { NSEvent.removeMonitor(escapeMonitor) }
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event } // kVK_Escape
            self?.hide()
            return nil
        }
        workspaceActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hide()
        }
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
        launcherIsVisible = false
        if let escapeMonitor { NSEvent.removeMonitor(escapeMonitor) }
        escapeMonitor = nil
        if let workspaceActivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceActivationObserver)
        }
        workspaceActivationObserver = nil
    }
}

final class LauncherModel: ObservableObject {
    @Published var query = "" { didSet { refresh() } }
    @Published private(set) var match: LaunchableApp?
    private let catalog: AppCatalog
    private let dismiss: () -> Void

    init(catalog: AppCatalog, dismiss: @escaping () -> Void) {
        self.catalog = catalog
        self.dismiss = dismiss
        refresh()
    }

    func openMatch() {
        guard let match else { return }
        NSWorkspace.shared.openApplication(at: match.url, configuration: .init()) { _, _ in }
        dismiss()
    }

    func cancel() { dismiss() }

    private func refresh() { match = catalog.bestMatch(for: query) }
}

private struct LauncherView: View {
    @ObservedObject var model: LauncherModel

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            LauncherTextField(
                text: $model.query,
                submit: model.openMatch,
                cancel: model.cancel
            )

            if !model.query.isEmpty {
                HStack(spacing: 8) {
                    if let match = model.match {
                        AppIcon(app: match)
                        Text(match.name)
                            .font(.system(size: 14, weight: .medium))
                    } else {
                        Image(systemName: "return")
                        Text("No matching application")
                    }
                    Spacer()
                    Text("esc to cancel")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(model.match == nil ? .secondary : .primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 17)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct AppIcon: View {
    let app: LaunchableApp
    private static let cache = NSCache<NSString, NSImage>()

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .frame(width: 22, height: 22)
    }

    private var image: NSImage {
        let key = app.url.path as NSString
        if let cached = Self.cache.object(forKey: key) { return cached }
        let icon = NSWorkspace.shared.icon(forFile: app.url.path)
        Self.cache.setObject(icon, forKey: key)
        return icon
    }
}

/// Borderless panels do not reliably become key windows. This subclass does.
private final class LauncherPanel: NSPanel {
    var cancelHandler: (() -> Void)?
    var resignHandler: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func cancelOperation(_ sender: Any?) { cancelHandler?() }
    override func resignKey() {
        super.resignKey()
        DispatchQueue.main.async { [weak self] in self?.resignHandler?() }
    }
}

private struct LauncherTextField: NSViewRepresentable {
    @Binding var text: String
    let submit: () -> Void
    let cancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.placeholderString = "Open an application…"
        field.font = .systemFont(ofSize: 27)
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.delegate = context.coordinator
        field.target = context.coordinator
        field.action = #selector(Coordinator.submit)
        DispatchQueue.main.async { field.window?.makeFirstResponder(field) }
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        if field.stringValue != text { field.stringValue = text }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: LauncherTextField
        init(_ parent: LauncherTextField) { self.parent = parent }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        @objc func submit() { parent.submit() }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.cancelOperation(_:)) else { return false }
            parent.cancel()
            return true
        }
    }
}
