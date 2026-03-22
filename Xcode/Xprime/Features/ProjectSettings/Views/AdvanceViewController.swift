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
    @IBOutlet weak var preferProjectBuild: NSSwitch!
    @IBOutlet weak var fallback: NSSwitch!
    @IBOutlet weak var compression: NSSwitch!
    
    private var projectManager: ProjectManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        configureArchiveSourceSelection()
        configureArchiveSourceActions()
        
        configureFallbackSelection()
        configureFallbackActions()
        
        configureCompressionSelection()
        configureCompressionActions()
    }
    
    // MARK: - Actions
    @objc private func preferProjectBuildSwitchToggled(_ sender: NSSwitch) {
        ProjectSettings.shared.archiveProjectAppOnly = sender.state == .on
    }
    
    @objc private func fallbackSwitchToggled(_ sender: NSSwitch) {
        ProjectSettings.shared.plainFallbackText = sender.state == .on
    }
    
    @objc private func compressionSwitchToggled(_ sender: NSSwitch) {
        ProjectSettings.shared.compression = sender.state == .on
    }
    
    @IBAction func close(_ sender: Any) {
        self.view.window?.close()
    }
    
    // MARK: - Private Helpers
    private func configureArchiveSourceSelection() {
        self.preferProjectBuild.state = ProjectSettings.shared.archiveProjectAppOnly ? .on : .off
    }
    
    private func configureArchiveSourceActions() {
        preferProjectBuild.target = self
        preferProjectBuild.action = #selector(preferProjectBuildSwitchToggled)
    }
    
    private func configureFallbackSelection() {
        self.fallback.state = ProjectSettings.shared.plainFallbackText ? .on : .off
    }
    
    private func configureFallbackActions() {
        fallback.target = self
        fallback.action = #selector(fallbackSwitchToggled(_:))
    }
    
    private func configureCompressionSelection() {
        self.compression.state = ProjectSettings.shared.compression ? .on : .off
    }
    
    private func configureCompressionActions() {
        compression.target = self
        compression.action = #selector(compressionSwitchToggled)
    }
}
