// The MIT License (MIT)
//
// Copyright (c) 2025 Insoft.
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
    
    
    @IBOutlet weak var librarySearchPath: NSTextField!
    @IBOutlet weak var headerSearchPath: NSTextField!
    @IBOutlet weak var macOS: NSButton!
    @IBOutlet weak var Wine: NSButton!
    @IBOutlet weak var compressionSwitch: NSSwitch!
    @IBOutlet weak var calculator: NSImageView!
    @IBOutlet weak var archiveProjectAppOnly: NSSwitch!
    
    @IBOutlet weak var calculatorComboButton: NSComboButton!
    
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
        
        let menu = NSMenu()
        menu.addItem(withTitle: "Virtual Calculator", action: #selector(optionSelected(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "HP Connectivity Kit", action: #selector(optionSelected(_:)), keyEquivalent: "")
        menu.addItem(.separator())
       
        
        let connectivityKitURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/HP Connectivity Kit/Calculators")
        
        let contents = try? FileManager.default.contentsOfDirectory(
            at: connectivityKitURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        contents?
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .forEach { url in
                if url.lastPathComponent != "Prime" && url.lastPathComponent != "HP Prime" {
                    menu.addItem(
                        withTitle: url.lastPathComponent,
                        action: #selector(optionSelected(_:)),
                        keyEquivalent: ""
                    )
                }
            }

        calculatorComboButton.menu = menu
        if let defaultItem = menu.items.first {
            calculatorComboButton.title = defaultItem.title
        }
        
        switch calculator {
        case "Prime":
            calculatorComboButton.title = "Virtual Calculator"
            break;
            
        case "HP Prime":
            calculatorComboButton.title = "HP Connectivity Kit"
            break;
            
        default:
            calculatorComboButton.title = calculator
        }
        
    }
  
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }

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
    
    @IBAction func calculatorComboButtonTapped(_ sender: NSComboButton) {
        // Handle selection or present menu items here
    }
    
    @objc func optionSelected(_ sender: NSMenuItem) {
        calculatorComboButton.title = sender.title
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
        calculatorComboButton.title = "Virtual Calculator"
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

