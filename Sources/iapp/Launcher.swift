import AppKit
import SwiftUI

final class LauncherController {
    private let catalog = AppCatalog()
    private var panel: LauncherPanel?
    private var model: LauncherModel?
    private var escapeMonitor: Any?

    func toggle() {
        if let panel, panel.isVisible {
            panel.orderOut(nil)
        } else {
            show()
        }
    }

    func show() {
        let model = LauncherModel(catalog: catalog, dismiss: { [weak self] in self?.hide() })
        self.model = model
        let panel = LauncherPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 120),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.cancelHandler = { [weak self] in self?.hide() }
        panel.contentView = NSHostingView(rootView: LauncherView(model: model))
        panel.center()
        self.panel = panel
        if let escapeMonitor { NSEvent.removeMonitor(escapeMonitor) }
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event } // kVK_Escape
            self?.hide()
            return nil
        }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
        if let escapeMonitor { NSEvent.removeMonitor(escapeMonitor) }
        escapeMonitor = nil
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
                submit: model.openMatch
            )

            HStack(spacing: 8) {
                Image(systemName: "return")
                Text(model.match?.name ?? "No matching application")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text("esc to cancel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(model.match == nil ? .secondary : .primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 17)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Borderless panels do not reliably become key windows. This subclass does.
private final class LauncherPanel: NSPanel {
    var cancelHandler: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func cancelOperation(_ sender: Any?) { cancelHandler?() }
}

private struct LauncherTextField: NSViewRepresentable {
    @Binding var text: String
    let submit: () -> Void

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
    }
}
