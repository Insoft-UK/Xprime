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

final class AdvanceViewController: NSViewController, NSTextFieldDelegate, NSComboBoxDelegate {
    @IBOutlet weak var preferProjectBuildSwitch: NSSwitch!
    @IBOutlet weak var macOS: NSButton!
    @IBOutlet weak var Wine: NSButton!
    @IBOutlet weak var compressionSwitch: NSSwitch!
    
    private var projectManager: ProjectManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        configureArchiveSourceSelection()
        configureArchiveSourceActions()
        
        configurePlatformAvailability()
        configurePlatformSelection()
        configurePlatformActions()
        
        configureCompressionSelection()
        configureCompressionActions()
    }
    
    // MARK: - Actions
    @objc private func preferProjectBuildSwitchToggled(_ sender: NSSwitch) {
        UserDefaults.standard.set(sender.state == .on, forKey: "archiveProjectAppOnly")
    }
    
    @objc private func platform(_ sender: NSButton) {
        if sender.title == "macOS" {
            UserDefaults.standard.set(sender.state == .on ? "macOS" : "Wine", forKey: "platform")
        } else {
            UserDefaults.standard.set(sender.state == .on ? "Wine" : "macOS", forKey: "platform")
        }
    }
    
    @objc private func compressionSwitchToggled(_ sender: NSSwitch) {
        UserDefaults.standard.set(sender.state == .on, forKey: "compression")
    }
    
    @IBAction func close(_ sender: Any) {
        self.view.window?.close()
    }
    
    // MARK: - Private Helpers
    private func configureArchiveSourceSelection() {
        let archiveProjectAppOnly = UserDefaults.standard.object(forKey: "archiveProjectAppOnly") as? Bool ?? true
        
        self.preferProjectBuildSwitch.state = archiveProjectAppOnly ? .on : .off
    }
    
    private func configureArchiveSourceActions() {
        preferProjectBuildSwitch.target = self
        preferProjectBuildSwitch.action = #selector(preferProjectBuildSwitchToggled)
    }
    
    private func configurePlatformAvailability() {
        if !FileManager.default.fileExists(atPath: "/Applications/Wine.app/Contents/MacOS/wine") {
            macOS.isEnabled = false
            Wine.isEnabled = false
            UserDefaults.standard.set("macOS", forKey: "platform")
        }
    }
    
    private func configurePlatformSelection() {
        let platform = UserDefaults.standard.object(forKey: "platform") as? String ?? "macOS"

        if platform == "macOS" {
            macOS.state = .on
            Wine.state = .off
        } else {
            macOS.state = .off
            Wine.state = .on
        }
    }
    
    private func configurePlatformActions() {
        macOS.target = self
        macOS.action = #selector(platform(_:))
        Wine.target = self
        Wine.action = #selector(platform(_:))
    }
    
    private func configureCompressionSelection() {
        let compression = UserDefaults.standard.object(forKey: "compression") as? Bool ?? false
        compressionSwitch.state = compression ? .on : .off
    }
    
    private func configureCompressionActions() {
        compressionSwitch.target = self
        compressionSwitch.action = #selector(compressionSwitchToggled)
    }
}
