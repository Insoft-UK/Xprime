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

final class TiledBackgroundView: NSView {

    var backgroundImage = NSImage(named: "PaperTexture")

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let image = backgroundImage else { return }

        let pattern = NSColor(patternImage: image)
        pattern.setFill()
        dirtyRect.fill()
    }
}

final class NewProjectViewController: NSViewController, NSTextFieldDelegate, NSComboBoxDelegate {
    @IBOutlet private weak var projectTemplate: NSPopUpButton!
    @IBOutlet private weak var projectName: NSTextField!
    
    private var vc: MainViewController!
    
  
    override func viewDidLoad() {
        super.viewDidLoad()

//        if let image = NSImage(named: "PaperTexture") {
//            view.wantsLayer = true
//            view.layer?.backgroundColor = NSColor(patternImage: image).cgColor
//        }

        setup()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard let window = view.window else { return }
        window.isOpaque = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.styleMask = [.titled, .fullSizeContentView]
        window.center()
        
        if Settings.shared.visualEffectEnabled, let contentView = window.contentView {
            // Add blur view behind content
            let blurView = NSVisualEffectView(frame: contentView.bounds)
            blurView.autoresizingMask = [.width, .height]
            blurView.material = .hudWindow
            blurView.blendingMode = .behindWindow
            blurView.state = .active
            
            
            final class PassthroughView: NSView {
                override func hitTest(_ point: NSPoint) -> NSView? {
                    nil
                }
            }
            
            let tintView = PassthroughView(frame: contentView.bounds)
            tintView.autoresizingMask = [.width, .height]
            tintView.wantsLayer = true
            
            tintView.layer?.backgroundColor =
            NSColor.black.withAlphaComponent(0.25).cgColor
            
            let wallpaperView = TiledBackgroundView()
            
            contentView.addSubview(wallpaperView, positioned: .below, relativeTo: nil)
            contentView.addSubview(tintView, positioned: .below, relativeTo: nil)
            contentView.addSubview(blurView, positioned: .below, relativeTo: nil)
        }
        
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
                if !url.directoryExists {
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
                    to.items.last?.image?.size = iconSize.big
                } else {
                    let icon = NSImage(named: "Project")?.copy() as! NSImage
                    to.items.last?.image = icon
                    to.items.last?.image?.size = iconSize.big
                }
                
                
                to.items.last?.representedObject = url
            }
        }
        
        var menu = NSMenu()
        
        add(url.appendingPathComponent("Applications"), to: &menu)
        menu.addItem(NSMenuItem.separator())
        add(url.appendingPathComponent("Programs"), to: &menu)
        menu.addItem(NSMenuItem.separator())
        add(URL(fileURLWithPath: Settings.shared.workingDirectory + "/Libraries/Templates"), to: &menu)
        
        projectTemplate.menu = menu
    }
    
    private func showInfo(_ message: String, informationalText: String = "") {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = message
            alert.informativeText = informationalText
            alert.runModal()
        }
    }
    
    private func create(named name: String, in directoryURL: URL, from templateURL: URL) {
        
        let destinationURL = directoryURL
            .appendingPathComponent(name)
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            showInfo("Unable to create project", informationalText: "A directory already exists at \(destinationURL.path)")
            return
        }
        
        
        do {
            try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        } catch {
            showInfo("Unable to create project", informationalText: "Unable to create directory at \(destinationURL.path)")
            return
        }
        
        
        func copy(from: URL, to: URL) {
            let contents = try? FileManager.default.contentsOfDirectory(
                at: from,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            contents?.forEach { url in
                let lastPathComponent = url.lastPathComponent.replacingOccurrences(of: "$(PROJECT_NAME)", with: name)
                
                if url.directoryExists {
                    do {
                        try FileManager.default.createDirectory(at: to.appendingPathComponent(lastPathComponent), withIntermediateDirectories: true)
                        copy(from: url, to: to.appendingPathComponent(lastPathComponent))
                    } catch {
                        showInfo("Create directory error", informationalText: "Unable to create directory at \(to.appendingPathComponent(lastPathComponent).path)")
                    }
                } else {
                    do {
                        if url.path.hasSuffix(".pas") || url.path.hasSuffix(".hpppl") || url.path.hasSuffix(".hppplplus") || url.path.hasSuffix(".note") {
                            try replaceAllPlaceholders(in: url, to: to.appendingPathComponent(lastPathComponent), projectName: name)
                        } else {
                            try FileManager.default.copyItem(at: url, to: to.appendingPathComponent(lastPathComponent))
                        }
                    } catch {
                        showInfo("Create file error", informationalText: "Unable to create file at \(to.appendingPathComponent(lastPathComponent).path)")
                    }
                }
            }
        }
        
        copy(from: templateURL, to: destinationURL)
    }
    
//    private func replaceProjectName(
//        in sourceURL: URL,
//        to destinationURL: URL,
//        newName: String
//    ) throws {
//        // Read file contents
//        let contents = try String(contentsOf: sourceURL, encoding: .utf8)
//
//        // Replace placeholder
//        let updatedContents = contents.replacingOccurrences(
//            of: "$(PROJECT_NAME)",
//            with: newName.replacingOccurrences(of: " ", with: "_")
//        )
//
//        // Write back to destination
//        try updatedContents.write(
//            to: destinationURL,
//            atomically: true,
//            encoding: .utf8
//        )
//    }
    
    private func replaceAllPlaceholders(
        in sourceURL: URL,
        to destinationURL: URL,
        projectName: String
    ) throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        
        // Read file contents
        let contents = try String(contentsOf: sourceURL, encoding: .utf8)
        var updatedContents: String
        
        // Replace placeholder
        updatedContents = contents.replacingOccurrences(
            of: "$(PROJECT_NAME)",
            with: projectName.replacingOccurrences(of: " ", with: "_")
        )
        
        updatedContents = updatedContents.replacingOccurrences(
            of: "$(USER_NAME)",
            with: NSFullUserName()
        )
        
        updatedContents = updatedContents.replacingOccurrences(
            of: "$(DATE)",
            with: formatter.string(from: Date())
        )
        
        // Write back to destination
        try updatedContents.write(
            to: destinationURL,
            atomically: true,
            encoding: .utf8
        )
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
