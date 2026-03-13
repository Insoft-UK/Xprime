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
    @IBOutlet weak var calculator: NSImageView!
    @IBOutlet weak var defaultButton: NSButton!
    @IBOutlet weak var doneButton: NSButton!
    
    @IBOutlet weak var calculators: NSPopUpButton!
    

    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        librarySearchPath.delegate = self
        headerSearchPath.delegate = self
        
        librarySearchPath.stringValue = ProjectSettings.shared.lib // ToolchainPaths.lib
        headerSearchPath.stringValue = ProjectSettings.shared.include //ToolchainPaths.include
        
//        let calculator = UserDefaults.standard.object(forKey: "calculator") as? String ?? "Prime"

        if HPServices.hpPrimeCalculatorExists(named: ProjectSettings.shared.calculator) {
            self.calculator.image = NSImage(named: "ConnectivityKit")
        } else {
            self.calculator.image = NSImage(named: "VirtualCalculator")
        }
        
        populateCalculatorsMenu()
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
    
    // MARK: - Calculator Selection
    private func populateCalculatorsMenu() {
        let menu = calculators.menu
        menu?.removeAllItems()

        func makeMenuItem(title: String, stateName: String) -> NSMenuItem {
            let item = NSMenuItem(
                title: title,
                action: #selector(calculatorSelected(_:)),
                keyEquivalent: ""
            )

            if let image = NSImage(named: stateName == "Prime" ? "VirtualCalculator" : "ConnectivityKit")?.copy() as? NSImage {
                image.size = NSSize(width: 16, height: 16)
                item.image = image
            }

            item.state = ProjectSettings.shared.calculator == stateName ? .on : .off
            return item
        }

        // Built-in calculators
        menu?.addItem(makeMenuItem(title: "Virtual Calculator", stateName: "Prime"))
        menu?.addItem(makeMenuItem(title: "Connectivity Kit", stateName: "HP Prime"))
        menu?.addItem(.separator())

        // User calculators from disk
        let calculatorsURL = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/HP Connectivity Kit/Calculators")

        let contents = try? FileManager.default.contentsOfDirectory(
            at: calculatorsURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        contents?
            .map { $0.deletingPathExtension().lastPathComponent }
            .filter { $0 != "HP Prime" }
            .forEach { name in
                let item = makeMenuItem(title: name, stateName: name)
                menu?.addItem(item)
            }

        // Selection
        switch ProjectSettings.shared.calculator {
        case "Prime":
            calculators.selectItem(withTitle: "Virtual Calculator")
        case "HP Prime":
            calculators.selectItem(withTitle: "Connectivity Kit")
        default:
            calculators.selectItem(withTitle: ProjectSettings.shared.calculator)
        }
    }

    
    @objc private func calculatorSelected(_ sender: NSMenuItem) {
        if sender.title == "Virtual Calculator" {
            calculator.image = NSImage(named: "VirtualCalculator")
            UserDefaults.standard.set("Prime", forKey: "calculator")
        } else {
            if sender.title == "Connectivity Kit" {
                UserDefaults.standard.set("HP Prime", forKey: "calculator")
            } else {
                UserDefaults.standard.set(sender.title, forKey: "calculator")
            }
            calculator.image = NSImage(named: "ConnectivityKit")
        }
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
        ProjectSettings.shared.calculator = "Prime"
        ProjectSettings.shared.archiveProjectAppOnly = true
        ProjectSettings.shared.plainFallbackText = true
        ProjectSettings.shared.compression = false
        ProjectSettings.shared.include = "$(SDKROOT)/include"
        ProjectSettings.shared.lib = "$(SDKROOT)/lib"
        ProjectSettings.shared.bin = "/usr/local/bin"
        
        
        librarySearchPath.stringValue = ProjectSettings.shared.lib
        headerSearchPath.stringValue = ProjectSettings.shared.include
        calculators.selectItem(withTitle: "Virtual Calculator")
        calculator.image = NSImage(named: "VirtualCalculator")
    }
    
 
    @IBAction func close(_ sender: Any) {
        vc.projectManager.saveProject()
        self.view.window?.close()
    }
}

