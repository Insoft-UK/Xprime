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


final class SettingsViewController: NSViewController, NSTextFieldDelegate, NSComboBoxDelegate {
    
    
    @IBOutlet weak var librarySearchPath: NSTextField!
    @IBOutlet weak var headerSearchPath: NSTextField!
    @IBOutlet weak var macOS: NSButton!
    @IBOutlet weak var Wine: NSButton!
    @IBOutlet weak var compressionSwitch: NSSwitch!
    @IBOutlet weak var calculator: NSImageView!
    @IBOutlet weak var archiveProjectAppOnly: NSSwitch!
    
    @IBOutlet weak var calculatorComboBox: NSComboBox!
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        librarySearchPath.delegate = self
        headerSearchPath.delegate = self
        
        let platform = UserDefaults.standard.object(forKey: "platform") as? String ?? "macOS"
        let compression = UserDefaults.standard.object(forKey: "compression") as? Bool ?? false
        let include = UserDefaults.standard.object(forKey: "include") as? String ?? "$(SDK)/include"
        let lib = UserDefaults.standard.object(forKey: "lib") as? String ?? "$(SDK)/lib"
        let calculator = UserDefaults.standard.object(forKey: "calculator") as? String ?? "Prime"
//        let bin = "" // Reserved!
        let archiveProjectAppOnly = UserDefaults.standard.object(forKey: "archiveProjectAppOnly") as? Bool ?? true
        
        librarySearchPath.stringValue = lib
        headerSearchPath.stringValue = include
        
        if !FileManager.default.fileExists(atPath: "/Applications/Wine.app/Contents/MacOS/wine") {
            macOS.isEnabled = false
            Wine.isEnabled = false
            UserDefaults.standard.set("macOS", forKey: "platform")
        } else {
            if platform == "macOS" {
                macOS.state = .on
                Wine.state = .off
            } else {
                macOS.state = .off
                Wine.state = .on
            }
        }
        
        compressionSwitch.state = compression ? .on : .off
        self.archiveProjectAppOnly.state = archiveProjectAppOnly ? .on : .off
        
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
        window.isOpaque = false
        window.backgroundColor = NSColor(white: 0, alpha: 0.9)
        window.titlebarAppearsTransparent = true
        
        window.center()
        window.level = .floating
        window.hasShadow = true
        
       
        window.titlebarAppearsTransparent = true
        window.styleMask = [.nonactivatingPanel, .titled]
        window.styleMask.insert(.fullSizeContentView)
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
    

    
    @IBAction func platform(_ sender: NSButton) {
        if sender.title == "macOS" {
            UserDefaults.standard.set(sender.state == .on ? "macOS" : "Wine", forKey: "platform")
        } else {
            UserDefaults.standard.set(sender.state == .on ? "Wine" : "macOS", forKey: "platform")
        }
    }
    
    @IBAction func compressionSwitchToggled(_ sender: NSSwitch) {
        UserDefaults.standard.set(sender.state == .on, forKey: "compression")
    }
    
    @IBAction func archiveProjectAppOnlySwitchToggled(_ sender: NSSwitch) {
        UserDefaults.standard.set(sender.state == .on, forKey: "archiveProjectAppOnly")
    }
    
    @IBAction func defaultSettings(_ sender: Any) {
        headerSearchPath.stringValue = "$(SDK)/include"
        librarySearchPath.stringValue = "$(SDK)/lib"
        macOS.state = .on
        Wine.state = .off
        archiveProjectAppOnly.state = .on
        compressionSwitch.state = .off
        calculatorComboBox.selectItem(withObjectValue: "Virtual Calculator")
        calculator.image = NSImage(named: "VirtualCalculator")
        
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

