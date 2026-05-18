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

class ViewController: NSViewController {
    @IBOutlet weak var cancel: NSButton!
    @IBOutlet weak var install: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        guard let window = view.window else { return }
        
        // Make window background transparent
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask = [.borderless]
        window.isMovableByWindowBackground = true
        window.center()
        
        if let contentView = window.contentView {
            contentView.wantsLayer = true
            if let layer = contentView.layer {
                layer.cornerRadius = 16
                layer.masksToBounds = true
                layer.borderWidth = 0.0
                layer.borderColor = NSColor(white: 0.5, alpha: 0.15).cgColor
            }
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


    @IBAction func quitApp(_ sender: Any) {
        NSApp.terminate(sender)
    }
    
    @IBAction func install(_ sender: Any) {
        self.install.isHidden = true
        self.cancel.isHidden = true
        
        let defaultWorkingDirectoryURL = FileManager
            .default
            .homeDirectoryForCurrentUser
            .appending(path: "Xprime", directoryHint: .isDirectory)
        
        // Create the Xprime default working directory if missing!
        if !defaultWorkingDirectoryURL.hasDirectoryPath {
            let directorys: [URL] = [
                defaultWorkingDirectoryURL,
                defaultWorkingDirectoryURL.appending(path: "Themes"),
                defaultWorkingDirectoryURL.appending(path: "Snippets"),
                defaultWorkingDirectoryURL.appending(path: "Stubs")
            ]
            directorys.forEach {
                try? FileManager.default.createDirectory(at: $0, withIntermediateDirectories: true)
            }
        }
        
        installThemes()
        installSnippets()
        installStubs()
        
        self.install.isHidden = false
        self.install.isEnabled = false
        self.cancel.isHidden = false
        self.cancel.title = "Close"
    }
    
    
    
    
    private func installThemes() {
        let destinationURL = FileManager
            .default
            .homeDirectoryForCurrentUser
            .appending(path: "Xprime", directoryHint: .isDirectory)
        
        if !destinationURL.appendingPathComponent("Themes").hasDirectoryPath {
            try? FileManager.default.createDirectory(at: destinationURL.appendingPathComponent("Themes"), withIntermediateDirectories: true)
        }
        
        let sourceURL = Bundle.main.resourceURL!
        let contents = try? FileManager.default.contentsOfDirectory(
            at: sourceURL
                .appendingPathComponent("Themes"),
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        contents?.forEach { url in
            try? FileManager.default.copyItem(at: url, to: destinationURL.appendingPathComponent("Themes").appendingPathComponent(url.lastPathComponent))
        }
    }
    
    private func installSnippets() {
        let destinationURL = FileManager
            .default
            .homeDirectoryForCurrentUser
            .appending(path: "Xprime", directoryHint: .isDirectory)
        
        if !destinationURL.appendingPathComponent("Snippets").hasDirectoryPath {
            try? FileManager.default.createDirectory(at: destinationURL.appendingPathComponent("Snippets"), withIntermediateDirectories: true)
        }
        
        let sourceURL = Bundle.main.resourceURL!
        let contents = try? FileManager.default.contentsOfDirectory(
            at: sourceURL
                .appendingPathComponent("Snippets"),
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        contents?.forEach { url in
            try? FileManager.default.copyItem(at: url, to: destinationURL.appendingPathComponent("Snippets").appendingPathComponent(url.lastPathComponent))
        }
    }
    
    private func installStubs() {
        let destinationURL = FileManager
            .default
            .homeDirectoryForCurrentUser
            .appending(path: "Xprime", directoryHint: .isDirectory)
        
        if !destinationURL.appendingPathComponent("Stubs").hasDirectoryPath {
            try? FileManager.default.createDirectory(at: destinationURL.appendingPathComponent("Stubs"), withIntermediateDirectories: true)
        }
        
        let sourceURL = Bundle.main.resourceURL!
        let contents = try? FileManager.default.contentsOfDirectory(
            at: sourceURL
                .appendingPathComponent("Stubs"),
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        contents?.forEach { url in
            try? FileManager.default.copyItem(at: url, to: destinationURL.appendingPathComponent("Stubs").appendingPathComponent(url.lastPathComponent))
        }
    }
}

