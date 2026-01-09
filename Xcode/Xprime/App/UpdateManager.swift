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

// MARK: ✅ Done

import Cocoa

final class UpdateManager {
    private weak var presenterWindow: NSWindow?
    
    init(presenterWindow: NSWindow?) {
        self.presenterWindow = presenterWindow
    }
    
    func checkForUpdates() {
        guard let url = URL(string: "http://insoft.uk/downloads/macos/xprime-app-version.json") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            guard error == nil, let data = data else {
                self.showError("Could not check for updates: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let latestVersion = json["latestVersion"] as? String,
                   let downloadString = json["downloadURL"] as? String,
                   let downloadURL = URL(string: downloadString) {
                    
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
                    let currentVersion = "\(version).\(build)"
                    
                    if self.isRemoteVersionNewer(latestVersion: latestVersion,
                                                 currentVersion: currentVersion) {
                        self.promptUpdate(downloadURL: downloadURL, latestVersion: latestVersion)
                    } else {
                        self.showInfo("You have the latest version.")
                    }
                } else {
                    self.showError("Invalid update info received.")
                }
            } catch {
                self.showError("Failed to parse update info: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    // MARK: - Version comparison
    private func isRemoteVersionNewer(latestVersion: String, currentVersion: String) -> Bool {
        return latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending
    }
    
    // MARK: - Alerts
    private func promptUpdate(downloadURL: URL, latestVersion: String) {
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
            let alert = NSAlert()
            alert.messageText = "Update Available"
            alert.informativeText = "Version \(latestVersion) is available. Download now?"
            alert.addButton(withTitle: "Download")
            alert.addButton(withTitle: "Later")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(downloadURL)
            }
        }
    }
    
    private func showInfo(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard (self?.presenterWindow) != nil else { return }
            let alert = NSAlert()
            alert.messageText = message
            alert.runModal()
        }
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard (self?.presenterWindow) != nil else { return }
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "Update Check Failed"
            alert.informativeText = message
            alert.runModal()
        }
    }
}
