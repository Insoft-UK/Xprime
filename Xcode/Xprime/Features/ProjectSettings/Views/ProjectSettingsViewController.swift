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


final class ProjectSettingsViewController: NSViewController, NSTextFieldDelegate {
    private var vc: MainViewController!
    
    @IBOutlet weak var librarySearchPath: NSTextField!
    @IBOutlet weak var headerSearchPath: NSTextField!
    @IBOutlet weak var defaultButton: NSButton!
    @IBOutlet weak var doneButton: NSButton!

    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        librarySearchPath.delegate = self
        headerSearchPath.delegate = self
        
        librarySearchPath.stringValue = ProjectSettings.shared.lib // ToolchainPaths.lib
        headerSearchPath.stringValue = ProjectSettings.shared.include //ToolchainPaths.include
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard let window = view.window else { return }
        
        // Make window background transparent
        window.titleVisibility = .hidden

        window.center()
        window.level = .modalPanel
        window.hasShadow = true
        window.titlebarAppearsTransparent = true
        window.styleMask = [.nonactivatingPanel, .titled]
        window.styleMask.insert(.fullSizeContentView)
        
        guard let window = NSApplication.shared.windows.first else {
            self.view.window?.close(); return
        }
        vc = window.contentViewController as? MainViewController
    }
    

    // MARK: - Include or Lib Paths
    func controlTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else { return }

        switch textField.tag {
        case 1:
            ProjectSettings.shared.include = textField.stringValue
            break;
        case 2:
            ProjectSettings.shared.lib = textField.stringValue
            break;
        default:
            break
        }
    }
    
    @IBAction func defaultSettings(_ sender: Any) {
        ProjectSettings.shared.archiveProjectAppOnly = true
        ProjectSettings.shared.plainFallbackText = true
        ProjectSettings.shared.compression = false
        ProjectSettings.shared.include = "$(SDKROOT)/include"
        ProjectSettings.shared.lib = "$(SDKROOT)/lib"
        ProjectSettings.shared.bin = "/usr/local/bin"
        
        
        librarySearchPath.stringValue = ProjectSettings.shared.lib
        headerSearchPath.stringValue = ProjectSettings.shared.include
    }
    
 
    @IBAction func close(_ sender: Any) {
        vc.projectManager.saveProject()
        self.view.window?.close()
    }
}

