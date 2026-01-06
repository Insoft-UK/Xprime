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
        
        NSApp.helpMenu = nil
    }
    
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    
    
    // MARK: - Interface Builder Action Handlers
    
    @IBAction func launchHPConnectiveKit(_ sender: Any) {
        HPServices.launchConnectivityKit()
    }
    
    @IBAction func launchHPPrimeVirtualCalculator(_ sender: Any) {
        HPServices.launchVirtualCalculator()
    }
    
    

    // MARK: - Action Handlers

    
    internal func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.action {
        case #selector(launchHPConnectiveKit(_:)):
            return HPServices.isConnectivityKitInstalled
            
        case #selector(launchHPPrimeVirtualCalculator(_:)):
            return HPServices.isVirtualCalculatorInstalled
        default:
            break
        }
        return true
    }
    
    internal func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(launchHPConnectiveKit(_:)):
            return HPServices.isConnectivityKitInstalled
            
        case #selector(launchHPPrimeVirtualCalculator(_:)):
            return HPServices.isVirtualCalculatorInstalled
            
        default:
            break
        }
        return true
    }
}

