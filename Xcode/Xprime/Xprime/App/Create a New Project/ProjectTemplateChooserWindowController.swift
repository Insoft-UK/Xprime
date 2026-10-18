import AppKit

final class ProjectTemplateChooserWindowController: NSWindowController {

    private var selectionHandler: ((ProjectTemplateSelection) -> Void)?

    init(
        onSelect: @escaping (ProjectTemplateSelection) -> Void
    ) {
        let contentController =
            ProjectTemplateChooserViewController()

        let window = NSWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: 620,
                height: 440
            ),
            styleMask: [
                .titled,
                .fullSizeContentView
            ],
            backing: .buffered,
            defer: false
        )

        window.title = "New Project"
        window.contentViewController = contentController
        window.center()
        window.isReleasedWhenClosed = false

        window.hasShadow = true
        window.isOpaque = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true

        super.init(window: window)

        selectionHandler = onSelect

        contentController.onContinue = { [weak self] selection in
            guard let self else { return }

            self.close()
            NSApp.stopModal()
            self.selectionHandler?(selection)
        }

        contentController.onCancel = { [weak self] in
            guard let self else { return }

            self.close()
            NSApp.stopModal()
        }
    }

    func showModal() {
        guard let window else { return }

        NSApp.runModal(for: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
