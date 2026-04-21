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

final class SettingsViewController: NSViewController, NSTextFieldDelegate {
    @IBOutlet weak var substitution: NSButton!
    @IBOutlet weak var theme: NSPopUpButton!
    @IBOutlet weak var location: NSTextField!
    @IBOutlet weak var useBetaApplications: NSButton!
    @IBOutlet weak var keywordNormalization: NSButton!
    
    private var vc: MainViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidAppear() {
        guard let window = view.window else { return }
        
        // Make window background transparent
        window.titleVisibility = .hidden
        window.center()
        window.titlebarAppearsTransparent = true
        window.styleMask = [.nonactivatingPanel, .titled]
        window.styleMask.insert(.fullSizeContentView)
        
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
        
        location.delegate = self
        location.stringValue = Settings.shared.location
    }
    
    func controlTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else { return }

        switch textField.tag {
        case 1:
            Settings.shared.location = textField.stringValue
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
        Settings.shared.preferredTheme = sender.title
        vc.themeManager.applySavedTheme()
    }
    
    
    
    @IBAction func close(_ sender: Any) {
        self.view.window?.close()
    }
    
    @IBAction func defaultSettings(_ sender: Any) {
        Settings.shared.substitutionEnabled = false
        Settings.shared.useBetaApplications = false
        Settings.shared.preferredTheme = "Default (Dark)"
        Settings.shared.location = FileManager
            .default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Xprime")
            .path
        
        location.stringValue = Settings.shared.location
        substitution.state = .off
        theme.selectItem(withTitle: Settings.shared.preferredTheme)
        useBetaApplications.state = .off
        vc.themeManager.applySavedTheme()
    }
    
    // MARK: - Private Helpers
    private func configureThemeSelection() {
        guard let resourceURLs = Bundle.main.urls(
            forResourcesWithExtension: "xpcolortheme",
            subdirectory: "Themes"
        ) else {
#if Debug
            print("⚠️ No .xpcolortheme files found.")
#endif
            return
        }
        
        let sortedURLs = resourceURLs
            .filter { !$0.lastPathComponent.hasPrefix(".") }
            .sorted {
                $0.deletingPathExtension().lastPathComponent
                    .localizedCaseInsensitiveCompare(
                        $1.deletingPathExtension().lastPathComponent
                    ) == .orderedAscending
            }
        
        let themeName = Settings.shared.preferredTheme
        
        for fileURL in sortedURLs {
            let name = fileURL.deletingPathExtension().lastPathComponent
            
            let menuItem = NSMenuItem(
                title: name,
                action: #selector(handleThemeSelection(_:)),
                keyEquivalent: ""
            )
            menuItem.representedObject = fileURL
            menuItem.target = self
            menuItem.state = themeName == name ? .on : .off
            
            theme.menu!.addItem(menuItem)
        }
        
        theme.selectItem(withTitle: themeName)
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
