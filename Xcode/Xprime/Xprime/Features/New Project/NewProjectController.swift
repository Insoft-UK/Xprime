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

final class NewProjectViewController: NSViewController, NSTextFieldDelegate, NSComboBoxDelegate {
    @IBOutlet private weak var projectTemplate: NSPopUpButton!
    @IBOutlet private weak var projectName: NSTextField!
    
    private var vc: MainViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidAppear() {
        guard let window = view.window else { return }
        
        // Make window background transparent
        window.titleVisibility = .hidden
        window.center()
        window.titlebarAppearsTransparent = true
        window.styleMask = [.nonactivatingPanel, .titled]
        window.styleMask.insert(.fullSizeContentView)
        
        DispatchQueue.main.async {
            if let editor = window.fieldEditor(false, for: self.projectName) as? NSTextView {
                let end = self.projectName.stringValue.count
                editor.selectedRange = NSRange(location: end, length: 0)
            }
        }
        
        guard let window = NSApplication.shared.windows.first else {
            self.view.window?.close(); return
        }
        vc = window.contentViewController as? MainViewController
    }
    
    private func setup() {
        refreshProjectTemplateMenu()
    }
    
    // MARK: - Actions
    @IBAction func create(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = URL(fileURLWithPath: Settings.shared.workingDirectory + "/Projects")
        panel.prompt = "Create"
        
        panel.begin { result in
            guard result == .OK, let folderURL = panel.url else { return }
            
            do {
                let name = try self.safeName(from: self.projectName.stringValue)
                self.create(named: name, in: folderURL, from: self.projectTemplate.selectedItem?.representedObject as! URL)
                self.vc.projectManager.openProject(in: folderURL.appendingPathComponent(name))
            } catch {
                return
            }
            
            self.view.window?.close()
        }
    }
    
    @IBAction func close(_ sender: Any) {
        self.view.window?.close()
    }
    
    // MARK: - Private Helpers
    private func refreshProjectTemplateMenu() {
        guard let resourceURL = Bundle.main.resourceURL else { return }
        
        let url = resourceURL
            .appendingPathComponent("Developer/Library/Xprime/Templates/Project Templates")
        
        func add(_ url: URL, to: inout NSMenu) {
            let contents = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            for url in contents ?? [] {
                if !url.isDirectory {
                    continue
                }
                
                to.addItem(
                    withTitle: url.lastPathComponent,
                    action: nil,
                    keyEquivalent: ""
                )
                
                if FileManager.default.fileExists(atPath: url.appendingPathExtension("png").path) {
                    let icon = NSImage(contentsOf: url.appendingPathExtension("png"))?.copy() as! NSImage
                    to.items.last?.image = icon
                    to.items.last?.image?.size = NSSize(width: 18, height: 18)
                } else {
                    if FileManager.default.fileExists(atPath: url.appendingPathComponent("Template.hpappdir/icon.png").path) {
                        let icon = NSImage(contentsOf: url.appendingPathComponent("Template.hpappdir/icon.png"))?.copy() as! NSImage
                        to.items.last?.image = icon
                        to.items.last?.image?.size = NSSize(width: 18, height: 18)
                    }
                }
                
                
                to.items.last?.representedObject = url
            }
        }
        
        var menu = NSMenu()
        
        add(url.appendingPathComponent("Applications"), to: &menu)
        menu.addItem(NSMenuItem.separator())
        add(url.appendingPathComponent("Programs"), to: &menu)
        menu.addItem(NSMenuItem.separator())
        add(URL(fileURLWithPath: Settings.shared.workingDirectory + "/Project Templates"), to: &menu)
        
        projectTemplate.menu = menu
    }
    
    
    private func create(named name: String, in directoryURL: URL, from templateURL: URL) {
        
        let destinationURL = directoryURL
            .appendingPathComponent(name)
        
        func copy(from: URL, to: URL) {
            let contents = try? FileManager.default.contentsOfDirectory(
                at: from,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            contents?.forEach { url in
                let lastPathComponent = url.lastPathComponent.replacingOccurrences(of: "Template", with: name)
                
                if url.isDirectory {
                    try? FileManager.default.createDirectory(at: to.appendingPathComponent(lastPathComponent), withIntermediateDirectories: true)
                    copy(from: url, to: to.appendingPathComponent(lastPathComponent))
                } else {
                    try? FileManager.default.copyItem(at: url, to: to.appendingPathComponent(lastPathComponent))
                }
            }
        }
        
        copy(from: templateURL, to: destinationURL)
    }
    
    enum AppError: Error {
        case invalidProjectName
    }
    
    private func safeName(from name: String) throws -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let sanitized = name
            .components(separatedBy: invalidCharacters)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !sanitized.isEmpty else {
            throw AppError.invalidProjectName
        }
        
        return sanitized
    }
    
}
