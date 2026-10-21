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
//    private var vc: MainViewController!
    
    @IBOutlet weak var librarySearchPath: NSTextField!
    @IBOutlet weak var headerSearchPath: NSTextField!
    @IBOutlet weak var defaultButton: NSButton!
    @IBOutlet weak var doneButton: NSButton!

    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        librarySearchPath.delegate = self
        headerSearchPath.delegate = self
        
        librarySearchPath.stringValue = ProjectSettings.shared.lib
        headerSearchPath.stringValue = ProjectSettings.shared.include
    }
    
    private var vc: MainViewController!

    override func viewDidAppear() {
        super.viewDidAppear()

        guard let window = view.window,
              let mainVC = presentingViewController as? MainViewController else {
            return
        }
        
        window.isMovableByWindowBackground = false
        window.styleMask.remove(.resizable)
        
        vc = mainVC

        DispatchQueue.main.async {
            if let editor = window.fieldEditor(false, for: self.headerSearchPath) as? NSTextView {
                let end = self.headerSearchPath.stringValue.count
                editor.selectedRange = NSRange(location: end, length: 0)
            }
        }

        configureViews()
    }
    
    @IBAction func showAdvanced(_ sender: NSButton) {
        guard let storyboard,
              let advancedVC = storyboard.instantiateController(
                  withIdentifier: "AdvanceViewController"
              ) as? AdvanceViewController else {
            return
        }

        presentAsSheet(advancedVC)
    }
    

    // MARK: - Include or Lib Paths
    func controlTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else { return }

        switch textField.tag {
        case 1:
            ProjectSettings.shared.include = textField.stringValue
            
        case 2:
            ProjectSettings.shared.lib = textField.stringValue
            
        case 3:
            ProjectSettings.shared.bin = textField.stringValue
            
        default:
            break
        }
    }
    
    @IBAction func defaultSettings(_ sender: Any) {
        ProjectSettings.shared.plainFallbackText = true
        ProjectSettings.shared.compression = false
        ProjectSettings.shared.include = Constants.Toolchain.include
        ProjectSettings.shared.lib = Constants.Toolchain.lib
        ProjectSettings.shared.bin = Constants.Toolchain.bin
        
        librarySearchPath.stringValue = ProjectSettings.shared.lib
        headerSearchPath.stringValue = ProjectSettings.shared.include
    }
    
 
    @IBAction func close(_ sender: Any) {
        vc.projectManager.saveProject()
        dismiss(nil)
    }
    
    @objc private func selectedBaseApplication(_ sender: NSPopUpButton) {
        guard let url = vc.projectManager.projectDirectoryURL else { return }
        guard let name = vc.projectManager.projectName else { return }
        try? HPPrimeServices.resetHPAppContents(at: url, named: name, fromBaseApplicationNamed: sender.title)
        vc.outputTextView.appendTextAndScroll("Base application is \"\(vc.projectManager.baseApplicationName)\"\n")
    }
    
    private func configureViews() {
        guard vc.projectManager.isProjectOpen else {
            return
        }
        let isHidden = !vc.projectManager.isProjectApplication
        
        
        if let popupButton: NSPopUpButton = view.findView(
            withIdentifier: Constants.Identifiers.baseAppication
        ) {
            // Configure popup button
            popupButton.target = self
            popupButton.action = #selector(selectedBaseApplication(_:))
            popupButton.selectItem(withTitle: vc.projectManager.baseApplicationName)
            popupButton.isHidden = isHidden
        }

        if let textField: NSTextField = view.findView(
            withIdentifier: Constants.Identifiers.baseAppication
        ) {
            textField.isHidden = isHidden
        }
    }
}

