import AppKit

final class ProjectTemplateChooserViewController: NSViewController {

    var onContinue: ((ProjectTemplateSelection) -> Void)?
    var onCancel: (() -> Void)?

    private var selectedType: ProjectTemplateType = .application
    private var optionButtons: [ProjectTemplateType: NSButton] = [:]

    private let nameField = NSTextField()

    override func loadView() {
        view = NSView()
        buildInterface()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard let window = view.window else { return }

        
        if let contentView = window.contentView {
            // Add blur view behind content
            let blurView = NSVisualEffectView(frame: contentView.bounds)
            blurView.autoresizingMask = [.width, .height]
            blurView.material = .hudWindow // .underWindowBackground
            blurView.blendingMode = .behindWindow
            blurView.state = .active
            
            
            final class PassthroughView: NSView {
                override func hitTest(_ point: NSPoint) -> NSView? {
                    nil
                }
            }
            
            let tintView = PassthroughView(frame: contentView.bounds)
            tintView.autoresizingMask = [.width, .height]
            tintView.wantsLayer = true
            
            tintView.layer?.backgroundColor =
            NSColor.black.withAlphaComponent(0.25).cgColor
            
            contentView.addSubview(tintView, positioned: .below, relativeTo: nil)
            contentView.addSubview(blurView, positioned: .below, relativeTo: nil)
        }
    }
    

    private func buildInterface() {
        let heading = NSTextField(
            labelWithString: "Create a New Project"
        )
        heading.font = .systemFont(ofSize: 22, weight: .semibold)

        let subtitle = NSTextField(
            labelWithString: "Select the type of project you want to create."
        )
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabelColor

        let optionsStack = NSStackView()
        optionsStack.orientation = .vertical
        optionsStack.alignment = .leading
        optionsStack.distribution = .fill
        optionsStack.spacing = 8

        for type in ProjectTemplateType.allCases {
            optionsStack.addArrangedSubview(makeOptionRow(type))
        }
        
        optionsStack.addArrangedSubview(NSView())

        let nameLabel = NSTextField(
            labelWithString: "Project Name:"
        )
        nameLabel.font = .systemFont(ofSize: 13, weight: .medium)

        nameField.placeholderString = "Untitled"
        nameField.font = .systemFont(ofSize: 13)
        nameField.translatesAutoresizingMaskIntoConstraints = false

        let nameStack = NSStackView(
            views: [nameLabel, nameField]
        )
        nameStack.orientation = .vertical
        nameStack.alignment = .leading
        nameStack.spacing = 6

        nameField.widthAnchor.constraint(
            equalTo: nameStack.widthAnchor
        ).isActive = true

        let cancelButton = NSButton(
            title: "Cancel",
            target: self,
            action: #selector(cancelPressed)
        )
        cancelButton.bezelStyle = .rounded
        cancelButton.controlSize = .large

        let continueButton = NSButton(
            title: "Continue",
            target: self,
            action: #selector(continuePressed)
        )
        continueButton.bezelStyle = .rounded
        continueButton.controlSize = .large
        continueButton.keyEquivalent = "\r"
        continueButton.bezelColor = .white

        let spacer = NSView()
        
        let buttonStack = NSStackView(
            views: [cancelButton, spacer, continueButton]
        )
        buttonStack.orientation = .horizontal
        buttonStack.distribution = .fill
        buttonStack.spacing = 10
    
        let root = NSStackView(
            views: [
                heading,
                subtitle,
                optionsStack,
                nameStack,
                buttonStack
            ]
        )
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 12
        root.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 28
            ),
            root.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -28
            ),
            root.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: 26
            ),
            root.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -20
            ),

            optionsStack.widthAnchor.constraint(
                equalTo: root.widthAnchor
            ),
            optionsStack.heightAnchor.constraint(
                equalToConstant: 210
            ),

            nameStack.widthAnchor.constraint(
                equalTo: root.widthAnchor
            ),
            nameField.heightAnchor.constraint(
                equalToConstant: 28
            ),

            buttonStack.trailingAnchor.constraint(
                equalTo: root.trailingAnchor
            )
        ])
    }

    private func makeOptionRow(
        _ type: ProjectTemplateType
    ) -> NSView {
        let radio = NSButton(
            radioButtonWithTitle: "",
            target: self,
            action: #selector(optionChanged(_:))
        )

        radio.identifier = NSUserInterfaceItemIdentifier(type.rawValue)
        radio.state = type == selectedType ? .on : .off
        optionButtons[type] = radio

        let imageView = NSImageView()
        imageView.image = NSImage(
            systemSymbolName: type.symbolName,
            accessibilityDescription: type.title
        )
        imageView.symbolConfiguration = NSImage.SymbolConfiguration(
            pointSize: 24,
            weight: .regular
        )
        imageView.contentTintColor = .secondaryLabelColor

        let title = NSTextField(
            labelWithString: type.title
        )
        title.font = .systemFont(ofSize: 14, weight: .medium)

        let description = NSTextField(
            labelWithString: type.subtitle
        )
        description.font = .systemFont(ofSize: 12)
        description.textColor = .secondaryLabelColor

        let textStack = NSStackView(
            views: [title, description]
        )
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4

        let row = NSStackView(
            views: [radio, imageView, textStack]
        )
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12

        NSLayoutConstraint.activate([
            radio.widthAnchor.constraint(equalToConstant: 18),
            imageView.widthAnchor.constraint(equalToConstant: 32),
            imageView.heightAnchor.constraint(equalToConstant: 32),
            row.heightAnchor.constraint(equalToConstant: 62)
        ])

        return row
    }

    @objc private func optionChanged(_ sender: NSButton) {
        guard
            let rawValue = sender.identifier?.rawValue,
            let type = ProjectTemplateType(rawValue: rawValue)
        else {
            return
        }

        selectedType = type

        for (option, button) in optionButtons {
            button.state = option == type ? .on : .off
        }
    }

    @objc private func continuePressed() {
        let name = nameField.stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            nameField.becomeFirstResponder()
            NSSound.beep()
            return
        }

        onContinue?(
            ProjectTemplateSelection(
                type: selectedType,
                name: name
            )
        )
    }

    @objc private func cancelPressed() {
        onCancel?()
    }
}

