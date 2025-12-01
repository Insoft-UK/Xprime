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
import UniformTypeIdentifiers

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSToolbarItemValidation, NSMenuItemValidation {
    @IBOutlet weak var mainMenu: NSMenu!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApp.appearance = NSAppearance(named: .darkAqua)
        
        UserDefaults.standard.set(false, forKey: "NSAutomaticPeriodSubstitutionEnabled")
        UserDefaults.standard.set(false, forKey: "NSAutomaticTextReplacementEnabled")
        UserDefaults.standard.set(false, forKey: "NSAutomaticQuoteSubstitutionEnabled")
        UserDefaults.standard.set(false, forKey: "NSAutomaticDashSubstitutionEnabled")
        UserDefaults.standard.synchronize()
        
        
        populateThemesMenu(menu: mainMenu)
        populateGrammarMenu(menu: mainMenu)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    
    private func populateThemesMenu(menu: NSMenu) {
        guard let resourceURLs = Bundle.main.urls(forResourcesWithExtension: "xpcolortheme", subdirectory: nil) else {
            print("⚠️ No .xpcolortheme files found.")
            return
        }

        for fileURL in resourceURLs {
            let filename = fileURL.deletingPathExtension().lastPathComponent

            let menuItem = NSMenuItem(title: filename, action: #selector(handleThemeSelection(_:)), keyEquivalent: "")
            menuItem.representedObject = fileURL
            menuItem.target = self  // or another target if needed
            if filename == AppSettings.selectedTheme {
                menuItem.state = .on
            }

            menu.item(withTitle: "Editor")?.submenu?.item(withTitle: "Theme")?.submenu?.addItem(menuItem)
        }
    }
    
    private func populateGrammarMenu(menu: NSMenu) {
        guard let resourceURLs = Bundle.main.urls(forResourcesWithExtension: "xpgrammar", subdirectory: nil) else {
            print("⚠️ No .xpgrammar files found.")
            return
        }
        
        for fileURL in resourceURLs {
            let name = fileURL.deletingPathExtension().lastPathComponent
            
            let menuItem = NSMenuItem(title: name, action: #selector(handleGrammarSelection(_:)), keyEquivalent: "")
            menuItem.representedObject = fileURL
            menuItem.target = self  // or another target if needed
            if name == AppSettings.selectedGrammar {
                menuItem.state = .on
            }

            menu.item(withTitle: "Editor")?.submenu?.item(withTitle: "Grammar")?.submenu?.addItem(menuItem)
        }
    }
    
    // MARK: - Interface Builder Action Handlers
    
    @IBAction func launchHPConnectiveKit(_ sender: Any) {
        HP.launchConnectivityKit()
    }
    
    @IBAction func launchHPPrimeVirtualCalculator(_ sender: Any) {
        HP.launchVirtualCalculator()
    }
    
    @IBAction func primeSDK(_ sender: NSMenuItem) {
        AppSettings.usePrimeSDK = !AppSettings.usePrimeSDK
    }

    // MARK: - Action Handlers

    
    @objc func handleThemeSelection(_ sender: NSMenuItem) {
        guard let vc = NSApp.mainWindow?.contentViewController as? MainViewController else { return }
        
        guard let fileURL = sender.representedObject as? URL else { return }
        vc.codeEditorTextView.loadTheme(at: fileURL)
        AppSettings.selectedTheme = sender.title
        
        for menuItem in mainMenu.item(withTitle: "Editor")?.submenu?.item(withTitle: "Theme")!.submenu!.items ?? [] {
            menuItem.state = .off
        }
        sender.state = .on
    }
    
    @objc func handleGrammarSelection(_ sender: NSMenuItem) {
        guard let vc = NSApp.mainWindow?.contentViewController as? MainViewController else { return }
        
        guard let fileURL = sender.representedObject as? URL else { return }
        vc.codeEditorTextView.loadGrammar(at: fileURL)
        AppSettings.selectedGrammar = sender.title
        
        for menuItem in mainMenu.item(withTitle: "Editor")?.submenu?.item(withTitle: "Grammar")!.submenu!.items ?? [] {
            menuItem.state = .off
        }
        sender.state = .on
    }
    
    internal func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.action {
        case #selector(launchHPConnectiveKit(_:)):
            return HP.isConnectivityKitInstalled
            
        case #selector(launchHPPrimeVirtualCalculator(_:)):
            return HP.isVirtualCalculatorInstalled
        default:
            break
        }
        return true
    }
    
    internal func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(launchHPConnectiveKit(_:)):
            return HP.isConnectivityKitInstalled
            
        case #selector(launchHPPrimeVirtualCalculator(_:)):
            return HP.isVirtualCalculatorInstalled
            
        case #selector(primeSDK(_:)):
            if let item = menuItem.menu?.item(withTitle: "Prime SDK") {
                if HP.isPrimeSDKInstalled {
                    item.state = AppSettings.usePrimeSDK ? .on : .off
                    item.isHidden = false
                    return true
                }
                item.isHidden = false
            }
            return false
            
        default:
            break
        }
        return true
    }
}
