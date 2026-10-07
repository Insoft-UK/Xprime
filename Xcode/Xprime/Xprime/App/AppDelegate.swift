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
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    @IBOutlet weak var mainMenu: NSMenu!
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
       
        guard isApplicationInstalled(withBundleIdentifier: Constants.BundleIdentifier.hpConnectivityKit) else {
            NSApp.terminate(nil)
            return
        }
        
        registerInstallation()
        print("🔥 applicationDidFinishLaunching CALLED")
        
//        
//        // Insert code here to initialize your application
        NSApp.appearance = NSAppearance(named: .darkAqua)
        
        UserDefaults.standard.set(false, forKey: "NSAutomaticPeriodSubstitutionEnabled")
        UserDefaults.standard.set(false, forKey: "NSAutomaticTextReplacementEnabled")
        UserDefaults.standard.set(false, forKey: "NSAutomaticQuoteSubstitutionEnabled")
        UserDefaults.standard.set(false, forKey: "NSAutomaticDashSubstitutionEnabled")
        UserDefaults.standard.synchronize()
        
        NSApp.helpMenu = nil
       
        if !Constants.HPConnectivityKit.directoryURL.hasDirectoryPath {
            let directorys: [URL] = [
                Constants.HPConnectivityKit.directoryURL,
                Constants.HPConnectivityKit.directoryURL.appending(path: "Xprime/Templates"),
                Constants.HPConnectivityKit.directoryURL.appending(path: "Xprime/Themes"),
                Constants.HPConnectivityKit.directoryURL.appending(path: "Projects")
            ]
            directorys.forEach {
                try? FileManager.default.createDirectory(
                    at: $0,
                    withIntermediateDirectories: true
                )
            }
        }
        
        FileManager.default.changeCurrentDirectoryPath(Constants.HPConnectivityKit.directoryURL.appendingPathComponent("Projects").path)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Interface Builder Action Handlers
    @IBAction func launchHPConnectiveKit(_ sender: Any) {
        runApplication(withBundleIdentifier: Constants.BundleIdentifier.hpConnectivityKit)
    }
    
    @IBAction func launchHPPrimeVirtualCalculator(_ sender: Any) {
        runApplication(withBundleIdentifier: Constants.BundleIdentifier.hpPrime)
    }
    
    
    // MARK: - Action Handlers
    internal func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(launchHPConnectiveKit(_:)):
            if !isApplicationInstalled(withBundleIdentifier: Constants.BundleIdentifier.hpConnectivityKit) {
                return false
            }
            return !isApplicationRunning(withBundleIdentifier: Constants.BundleIdentifier.hpConnectivityKit)
            
        case #selector(launchHPPrimeVirtualCalculator(_:)):
            if !isApplicationInstalled(withBundleIdentifier: Constants.BundleIdentifier.hpPrime) {
                return false
            }
            return !isApplicationRunning(withBundleIdentifier: Constants.BundleIdentifier.hpPrime)
            
        default:
            break
        }
        return true
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let window = NSApplication.shared.windows.first,
              let vc = window.contentViewController as? MainViewController
        else { return }
        
        for url in urls {
            if url.pathExtension.lowercased() == "xprimeproj" {
                vc.projectManager.openProject(at: url)
                return
            } else {
                vc.documentManager.openDocument(at: url)
                return
            }
        }
    }
}

