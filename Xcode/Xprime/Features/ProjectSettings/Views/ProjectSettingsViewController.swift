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


final class ProjectSettingsViewController: NSViewController, NSTextFieldDelegate, NSComboBoxDelegate {
    
    
    @IBOutlet weak var librarySearchPath: NSTextField!
    @IBOutlet weak var headerSearchPath: NSTextField!
    @IBOutlet weak var calculator: NSImageView!
    @IBOutlet weak var calculatorComboBox: NSComboBox!
    @IBOutlet weak var defaultButton: NSButton!
    @IBOutlet weak var doneButton: NSButton!
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        librarySearchPath.delegate = self
        headerSearchPath.delegate = self
        
        let include = UserDefaults.standard.object(forKey: "include") as? String ?? "$(SDK)/include"
        let lib = UserDefaults.standard.object(forKey: "lib") as? String ?? "$(SDK)/lib"
        let calculator = UserDefaults.standard.object(forKey: "calculator") as? String ?? "Prime"

        
        librarySearchPath.stringValue = lib
        headerSearchPath.stringValue = include
        
        
        if HPServices.hpPrimeCalculatorExists(named: calculator) {
            self.calculator.image = NSImage(named: "ConnectivityKit")
        } else {
            self.calculator.image = NSImage(named: "VirtualCalculator")
        }
        
        populateCalculatorComboBoxItems()
        
        calculatorComboBox.delegate = self
        calculatorComboBox.usesDataSource = false
        calculatorComboBox.focusRingType = .none
        calculatorComboBox.numberOfVisibleItems = 20
        calculatorComboBox.isEditable = false
        calculatorComboBox.isSelectable = false
        
        
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
        
        
        if let theme = ThemeLoader.shared.loadTheme(named: ThemeLoader.shared.preferredTheme) {
            if let color = NSColor(hex: theme.settings?["background"] ?? "") {
                window.backgroundColor = color
            }
            if let color = NSColor(hex: theme.settings?["default.color"] ?? "") {
                defaultButton.bezelColor = color
            }
            if let color = NSColor(hex: theme.settings?["done.color"] ?? "") {
                doneButton.bezelColor = color
            }
        }
    }
    
    // MARK: - Calculator Selection
    
    
    func handleInput(_ text: String) {
        if text == "Virtual Calculator" {
            calculator.image = NSImage(named: "VirtualCalculator")
            UserDefaults.standard.set("Prime", forKey: "calculator")
        } else {
            if text == "Connectivity Kit" {
                UserDefaults.standard.set("HP Prime", forKey: "calculator")
            } else {
                UserDefaults.standard.set(text, forKey: "calculator")
            }
            calculator.image = NSImage(named: "ConnectivityKit")
        }
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        guard let comboBox = notification.object as? NSComboBox else { return }

        let index = comboBox.indexOfSelectedItem
        guard index >= 0 else { return }

        let value = comboBox.itemObjectValue(at: index) as? String ?? ""
        handleInput(value)

        DispatchQueue.main.async {
            if let editor = comboBox.currentEditor() {
                let length = editor.string.count
                editor.selectedRange = NSRange(location: length, length: 0)
            }
        }
    }
    
    private func populateCalculatorComboBoxItems() {
        let connectivityKitURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/HP Connectivity Kit/Calculators")
        

        let content = try? FileManager.default.contentsOfDirectory(
            at: connectivityKitURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles],
        )
            .map { $0.deletingPathExtension().lastPathComponent.customPercentDecoded() }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        guard var content = content else {
            return
        }
        content.removeAll(where: { $0.contains("HP Prime") })
        calculatorComboBox.addItems(withObjectValues: content)
        
        let calculator = UserDefaults.standard.object(forKey: "calculator") as? String ?? "Prime"
        
        switch calculator {
        case "Prime":
            let index = calculatorComboBox.indexOfItem(withObjectValue: "Virtual Calculator")
            calculatorComboBox.selectItem(at: index)
            break
            
        case "HP Prime":
            let index = calculatorComboBox.indexOfItem(withObjectValue: "Connectivity Kit")
            calculatorComboBox.selectItem(at: index)
            break
            
        default:
            let index = calculatorComboBox.indexOfItem(withObjectValue: calculator)
            calculatorComboBox.selectItem(at: index)
        }
    }
    
    // MARK: - Include or Lib Paths
  
    func controlTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else { return }

        switch textField.tag {
        case 1:
            UserDefaults.standard.set(textField.stringValue, forKey: "include")
            break;
        case 2:
            UserDefaults.standard.set(textField.stringValue, forKey: "lib")
            break;
        default:
            break
        }
    }
    
    @IBAction func defaultSettings(_ sender: Any) {
        headerSearchPath.stringValue = "$(SDK)/include"
        librarySearchPath.stringValue = "$(SDK)/lib"
        calculatorComboBox.selectItem(withObjectValue: "Virtual Calculator")
        calculator.image = NSImage(named: "VirtualCalculator")
        
        UserDefaults.standard.set("macOS", forKey: "platform")
        UserDefaults.standard.set(false, forKey: "compression")
        UserDefaults.standard.set("$(SDK)/include", forKey: "include")
        UserDefaults.standard.set("$(SDK)/lib", forKey: "lib")
        UserDefaults.standard.set("Prime", forKey: "calculator")
        UserDefaults.standard.set("", forKey: "bin")
        UserDefaults.standard.set(true, forKey: "archiveProjectAppOnly")
    }
    
 
    @IBAction func close(_ sender: Any) {
        self.view.window?.close()
    }
}

