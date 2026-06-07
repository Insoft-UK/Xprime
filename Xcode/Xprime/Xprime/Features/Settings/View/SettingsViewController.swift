// The MIT License (MIT)
//
// Copyright (c) 2025-2026 Insoft.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the Software), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Cocoa

final class SettingsViewController: CustomViewController, NSTextFieldDelegate {
    @IBOutlet weak var substitution: NSButton!
    @IBOutlet weak var theme: NSPopUpButton!
    @IBOutlet weak var location: NSTextField!
    @IBOutlet weak var useBetaApplications: NSButton!
    @IBOutlet weak var keywordNormalization: NSButton!
    @IBOutlet weak var visualEffect: NSButton!
    
    private var vc: MainViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard let window = view.window else { return }
        window.center()
        window.isMovableByWindowBackground = false
        window.isMovable = false
        
        
        DispatchQueue.main.async {
            if let editor = window.fieldEditor(false, for: self.location) as? NSTextView {
                let end = self.location.stringValue.count
                editor.selectedRange = NSRange(location: end, length: 0)
            }
        }
        
        guard let window = NSApplication.shared.windows.first else {
            self.view.window?.close(); return
        }
        vc = window.contentViewController as? MainViewController
    }
    
    private func setup() {
        configureThemeSelection()
        configureSubtitutionActions()
        configureUseBetaApplicationsActions()
        configureKeywordNormalizationActions()
        
        visualEffect.target = self
        visualEffect.action = #selector(preferVisualEffectSwitchToggled(_:))
        visualEffect.state = Settings.shared.visualEffectEnabled ? .on : .off
        
        location.delegate = self
        location.stringValue = Settings.shared.workingDirectory
    }
    
    func controlTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else { return }

        switch textField.tag {
        case 1:
            Settings.shared.workingDirectory = textField.stringValue
            break;
        default:
            break
        }
    }
    
    // MARK: - Actions
    @objc private func preferKeywordNormalizationToggled(_ sender: NSSwitch) {
        Settings.shared.keywordNormalization = sender.state == .on
    }
    
    @objc private func preferSubtitutionSwitchToggled(_ sender: NSSwitch) {
        Settings.shared.substitutionEnabled = sender.state == .on
    }
    
    @objc private func preferUseBetaApplicationsSwitchToggled(_ sender: NSMenuItem) {
        Settings.shared.useBetaApplications = sender.state == .on
    }
    
    @objc private func handleThemeSelection(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else {
            return
        }
        Settings.shared.preferredTheme = url.path
        vc.themeManager.applyTheme(from: url)
    }
    
    
    @objc private func preferVisualEffectSwitchToggled(_ sender: NSMenuItem) {
        Settings.shared.visualEffectEnabled = sender.state == .on
    }
    
    
    @IBAction func close(_ sender: Any) {
        self.view.window?.close()
    }
    
    @IBAction func defaultSettings(_ sender: Any) {
        Settings.shared.substitutionEnabled = false
        Settings.shared.useBetaApplications = false
        Settings.shared.preferredTheme = Bundle.main.resourceURL!.appendingPathComponent("HP Connectivity Kit.xpcolortheme").path
        Settings.shared.workingDirectory = FileManager
            .default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Xprime")
            .path
        
        location.stringValue = Settings.shared.workingDirectory
        substitution.state = .off
        
        let url = URL(fileURLWithPath: Settings.shared.preferredTheme)
        theme.selectItem(withTitle: url.deletingPathExtension().lastPathComponent)
        useBetaApplications.state = .off
        
        vc.themeManager.applyTheme(from: url)
    }
    
    // MARK: - Private Helpers
    private func configureThemeSelection() {
        populateThemeSelection(from: Bundle.main.resourceURL!)
        theme.menu?.addItem(NSMenuItem.separator())
        populateThemeSelection(from: defaultWorkingDirectoryURL.appendingPathComponent("Themes"))
    }
    
    private func populateThemeSelection(from directoryURL: URL) {
        let fileManager = FileManager.default
        
        guard let resourceURLs = try? fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return
        }
        
        let sortedURLs = resourceURLs
            .filter { $0.pathExtension == "xpcolortheme" }
            .sorted {
                $0.deletingPathExtension().lastPathComponent
                    .localizedCaseInsensitiveCompare(
                        $1.deletingPathExtension().lastPathComponent
                    ) == .orderedAscending
            }
        
        for url in sortedURLs {
//            let name = ThemeLoader.shared.loadTheme(from: url)?.name ?? url.deletingPathExtension().lastPathComponent
            
            let name = url.deletingPathExtension().lastPathComponent
            
            let menuItem = NSMenuItem(
                title: name,
                action: #selector(handleThemeSelection(_:)),
                keyEquivalent: ""
            )
        
            menuItem.representedObject = url
            menuItem.target = self
            menuItem.state = (name == URL(fileURLWithPath: Settings.shared.preferredTheme).deletingPathExtension().lastPathComponent) ? .on : .off
            
            if FileManager.default.fileExists(atPath: url
                .deletingPathExtension()
                .appendingPathExtension("png")
                .path
            ) {
                menuItem.image = NSImage(byReferencing: url
                    .deletingPathExtension()
                    .appendingPathExtension("png")
                )
            } else {
                menuItem.image = NSImage(named: "xpcolortheme")?.copy() as? NSImage
            }
            
            menuItem.image?.size = NSSize(width: 24, height: 24)
            theme.menu?.addItem(menuItem)
        }
        
        theme.selectItem(withTitle: URL(fileURLWithPath: Settings.shared.preferredTheme).deletingPathExtension().lastPathComponent)
        
        if theme.itemArray.isEmpty {
            theme.isEnabled = false
        }
    }
    
    private func configureSubtitutionActions() {
        substitution.target = self
        substitution.action = #selector(preferSubtitutionSwitchToggled(_:))
        substitution.state = Settings.shared.substitutionEnabled ? .on : .off
    }
    
    private func configureUseBetaApplicationsActions() {
        useBetaApplications.target = self
        useBetaApplications.action = #selector(preferUseBetaApplicationsSwitchToggled(_:))
        useBetaApplications.state = Settings.shared.useBetaApplications ? .on : .off
    }
    
    private func configureKeywordNormalizationActions() {
        keywordNormalization.target = self
        keywordNormalization.action = #selector(preferKeywordNormalizationToggled(_:))
        keywordNormalization.state = Settings.shared.keywordNormalization ? .on : .off
    }
}
