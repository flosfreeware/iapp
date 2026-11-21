import AppKit
import SwiftUI

final class LauncherController {
    private let catalog = AppCatalog()
    private var panel: NSPanel?
    private var model: LauncherModel?

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
        let panel = NSPanel(
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
        panel.contentView = NSHostingView(rootView: LauncherView(model: model))
        panel.center()
        self.panel = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() { panel?.orderOut(nil) }
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
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            TextField("Open an application…", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 27, weight: .regular))
                .focused($inputFocused)
                .onSubmit { model.openMatch() }

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
        .onAppear { inputFocused = true }
        .onExitCommand { model.cancel() }
    }
}
