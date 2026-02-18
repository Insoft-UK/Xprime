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
import UniformTypeIdentifiers

protocol DocumentManagerDelegate: AnyObject {
    // Called when a document is successfully saved
    func documentManagerDidSave(_ manager: DocumentManager)
    
    // Called when saving fails
    func documentManager(_ manager: DocumentManager, didFailWith error: Error)
    
    // Called when a document is successfully opened
    func documentManagerDidOpen(_ manager: DocumentManager)
    
    // Optional: called when opening fails
    func documentManager(_ manager: DocumentManager, didFailToOpen error: Error)
    
    // Called when a document is successfully closed
    func documentManagerDidClose(_ manager: DocumentManager)
}

final class DocumentManager {
    
    weak var delegate: DocumentManagerDelegate?
    
    private(set) var currentDocumentURL: URL?
    private var editor: CodeEditorTextView
    private(set) var outputTextView: OutputTextView
    
    var documentIsModified: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .documentModificationChanged, object: nil)
        }
    }
    
    init(editor: CodeEditorTextView, outputTextView output: OutputTextView) {
        self.editor = editor
        self.outputTextView = output
    }
    
    private func openUntitled() {
        editor.string = ""
        currentDocumentURL = nil
        documentIsModified = false
    }
    
    private func saveNote(url: URL) {
        saveDocument(to: url.appendingPathExtension("ntf"))
        let path = ToolchainPaths.bin.appendingPathComponent("note")
        let result = ProcessRunner.run(executable: path, arguments: [url.appendingPathExtension("ntf").path, "-o", url.path])
        
        guard result.exitCode == 0 else {
            let error = NSError(
                domain: "Error",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to write to file \"\(url.lastPathComponent)\""]
            )
            
            try? FileManager.default.removeItem(at: url.appendingPathExtension("ntf"))
            outputTextView.appendTextAndScroll(result.err ?? "")
            delegate?.documentManager(self, didFailWith: error)
            return
        }
        
        try? FileManager.default.removeItem(at: url.appendingPathExtension("ntf"))
        outputTextView.appendTextAndScroll(result.err ?? "")
        documentIsModified = false
        delegate?.documentManagerDidSave(self)
    }
    
    private func openAdafruitGFXFont(url: URL) {
        let contents = ProcessRunner.run(executable: ToolchainPaths.bin.appendingPathComponent("font"), arguments: [url.path, "-o", "/dev/stdout"])
        if let out = contents.out, !out.isEmpty {
            self.outputTextView.appendTextAndScroll("Importing Adafruit GFX Font...\n")
            
            editor.string = out
            currentDocumentURL = nil
            documentIsModified = false
            delegate?.documentManagerDidOpen(self)
        }
        self.outputTextView.appendTextAndScroll(contents.err ?? "")
    }
    
    private func openImage(url: URL) {
        let command = ToolchainPaths.developerRoot.appendingPathComponent("usr")
            .appendingPathComponent("bin")
            .appendingPathComponent("grob")
            .path
        
        let commandURL = URL(fileURLWithPath: command)
        let contents = ProcessRunner.run(executable: commandURL, arguments: [url.path, "-o", "/dev/stdout"])
        if let out = contents.out, !out.isEmpty {
            self.outputTextView.appendTextAndScroll("Importing \"\(url.pathExtension.uppercased())\" Image...\n")
            
            editor.string = out
            currentDocumentURL = nil
            documentIsModified = false
            delegate?.documentManagerDidOpen(self)
        }
        self.outputTextView.appendTextAndScroll(contents.err ?? "")
    }
    
    private func openNote(url: URL) {
        let path = ToolchainPaths.bin.appendingPathComponent("note")
        let result = ProcessRunner.run(executable: path, arguments: [url.path, "-o", "/dev/stdout"])
        
        guard result.exitCode == 0, let out = result.out else {
            let error = NSError(
                domain: "Error",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to read from the note file."]
            )
            outputTextView.appendTextAndScroll(result.err ?? "")
            delegate?.documentManager(self, didFailToOpen: error)
            return
        }
        
        outputTextView.appendTextAndScroll(result.err ?? "")
        editor.string = out
        currentDocumentURL = url
        documentIsModified = false
        delegate?.documentManagerDidOpen(self)
    }
    
    private func saveProgram(url: URL) {
        guard let currentDocumentURL else { return }
        
        let path = ToolchainPaths.bin.appendingPathComponent("ppl+")
        let result = ProcessRunner.run(executable: path, arguments: [currentDocumentURL.path, "-o", url.path])
        
        guard result.exitCode == 0 else {
            let error = NSError(
                domain: "Error",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to write \"\(url.lastPathComponent)\" to file."]
            )
            outputTextView.appendTextAndScroll(result.err ?? "")
            delegate?.documentManager(self, didFailWith: error)
            return
        }
        
        outputTextView.appendTextAndScroll(result.err ?? "")
        self.currentDocumentURL = url
        documentIsModified = false
        delegate?.documentManagerDidSave(self)
    }
    
    private func openProgram(url: URL) {
        let path = ToolchainPaths.bin.appendingPathComponent("ppl+")
        let result = ProcessRunner.run(executable: path, arguments: [url.path, "-o", "/dev/stdout"])
        
        guard result.exitCode == 0, let out = result.out else {
            let error = NSError(
                domain: "Error",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to read from the program file."]
            )
            outputTextView.appendTextAndScroll(result.err ?? "")
            delegate?.documentManager(self, didFailToOpen: error)
            return
        }
        
        outputTextView.appendTextAndScroll(result.err ?? "")
        editor.string = out
        currentDocumentURL = url
        documentIsModified = false
        delegate?.documentManagerDidOpen(self)
    }
    
    func openDocument(at url: URL) {
        let encoding: String.Encoding
        switch url.pathExtension.lowercased() {
        case "prgm", "app":
            encoding = .utf16
            
        case "hpnote", "hpappnote":
            openNote(url: url)
            return
            
        case "hpprgm", "hpappprgm":
            openProgram(url: url)
            return
            
        case "bmp", "png":
            openImage(url: url)
            return
            
        case "h":
            openAdafruitGFXFont(url: url)
            return
            
        default:
            encoding = .utf8
        }
        
        do {
            let content = try String(contentsOf: url, encoding: encoding)
            editor.string = content
            currentDocumentURL = url
            documentIsModified = false
            UserDefaults.standard.set(url.path, forKey: "lastOpenedFilePath")
            delegate?.documentManagerDidOpen(self)
        } catch {
            delegate?.documentManager(self, didFailToOpen: error)
        }
    }
    
    func closeDocument() {
        currentDocumentURL = nil
        documentIsModified = false
        delegate?.documentManagerDidClose(self)
    }
    
    @discardableResult
    func saveDocument() -> Bool {
        guard let url = currentDocumentURL else { return false }
        return saveDocument(to: url)
    }
    
    @discardableResult
    func saveDocument(to url: URL) -> Bool {
        let encoding: String.Encoding
        switch url.pathExtension.lowercased() {
        case "prgm", "app":
            encoding = .utf16
        case "hpnote", "hpappnote":
            saveNote(url: url)
            return true
        case "hpprgm", "hpappprgm":
            saveProgram(url: url)
            return true
        default:
            encoding = .utf8
        }
        
        do {
            if url.pathExtension.lowercased() == "hpnote" || url.pathExtension.lowercased() == "hpappnote" {
                guard var data = editor.string.data(using: encoding) else {
                    throw NSError(domain: "EncodingError", code: 1)
                }
                data.append(contentsOf: [0x00, 0x00])
                try data.write(to: url, options: .atomic)
            } else {
                try editor.string.write(to: url, atomically: true, encoding: encoding)
            }
            
            documentIsModified = false
            delegate?.documentManagerDidSave(self)
            return true
        } catch {
            delegate?.documentManager(self, didFailWith: error)
            return false
        }
    }
    
    func saveDocumentAs(
        allowedContentTypes: [UTType],
        defaultFileName: String = "Untitled"
    ) {
        let allowedExtensions = allowedContentTypes.compactMap { type in
            type.preferredFilenameExtension
        }
        
        saveAs(allowedExtensions: allowedExtensions, defaultFileName: defaultFileName) { outputURL in
            self.saveDocument(to: outputURL)
            self.openDocument(at: outputURL)
        }
    }
    
    private func saveAs(
        allowedExtensions: [String],
        defaultFileName: String,
        action: @escaping (_ outputURL: URL) -> Void
    ) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = allowedExtensions.compactMap { UTType(filenameExtension: $0) }
        savePanel.nameFieldStringValue = defaultFileName
        savePanel.title = ""
        savePanel.directoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        savePanel.begin { result in
            guard result == .OK, let outURL = savePanel.url else { return }
            action(outURL)
        }
    }
}

extension Notification.Name {
    static let documentModificationChanged = Notification.Name("documentModificationChanged")
}
