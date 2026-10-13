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
    func documentManagerDidOpen(_ manager: DocumentManager, withResult result: (out: String?, err: String?, exitCode: Int32))
    
    // Optional: called when opening fails
    func documentManager(_ manager: DocumentManager, didFailToOpen error: Error)
    
    // Called when a document is successfully closed
    func documentManagerDidClose(_ manager: DocumentManager)
    
    func appendOutput(_ text: String)
}


final class DocumentManager {
    
    weak var delegate: DocumentManagerDelegate?
    
    private(set) var currentDocumentURL: URL?
    
    var documentIsModified: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .documentModificationChanged, object: nil)
        }
    }

    private func saveNote(url: URL) {
        let path = URL(fileURLWithPath: ToolchainPaths.bin).appending(path: "hpnote")
        
        
        var arguments: [String] = [url.appendingPathExtension("note").path, "-o", url.path]
        if ProjectSettings.shared.plainFallbackText == true {
            arguments.append("--plain-fallback")
        }
        
        let result = ProcessRunner.run(executable: path, arguments: arguments)
        
        guard result.exitCode == 0 else {
            let error = NSError(
                domain: "Error",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to write to file \"\(url.lastPathComponent)\""]
            )
            
            try? FileManager.default.removeItem(at: url.appendingPathExtension("note"))
            delegate?.appendOutput(result.err ?? "")
            delegate?.documentManager(self, didFailWith: error)
            return
        }
        
        try? FileManager.default.removeItem(at: url.appendingPathExtension("note"))
        delegate?.appendOutput(result.err ?? "")
        documentIsModified = false
        delegate?.documentManagerDidSave(self)
    }
    
    private func resolveDocumentURL(from url: URL) -> URL? {
        let documentURL: URL
        
        switch url.pathExtension.lowercased() {
        case "h", "bmp", "png":
            documentURL = url
                .deletingPathExtension()
                .appendingPathExtension(ProjectSettings.shared.language)
            
            if FileManager.default.fileExists(atPath: documentURL.path) {
                return nil
            } else {
                return documentURL
            }
            
        case "hpprgm", "hpappprgm":
            documentURL = url
                .deletingPathExtension()
                .appendingPathExtension("hpppl")
            
            if FileManager.default.fileExists(atPath: documentURL.path) {
                return nil
            } else {
                return documentURL
            }

        case "hpnote", "hpappnote":
            documentURL = url
                .deletingPathExtension()
                .appendingPathExtension("note")
            
            if FileManager.default.fileExists(atPath: documentURL.path) {
                return nil
            } else {
                return documentURL
            }

        default:
            return nil
        }
    }
    
    private func openWithTool(
        executableName: String,
        url: URL,
        arguments: [String],
        failureMessage: String,
        successLog: String? = nil,
        printStdErrOnSuccess: Bool = false,
    ) {
        let path = URL(fileURLWithPath: ToolchainPaths.bin).appending(path: executableName)
        let result = ProcessRunner.run(executable: path, arguments: [url.path, "-o", "/dev/stdout"] + arguments)
        
        guard result.exitCode == 0 else {
            let error = NSError(
                domain: "Error",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: failureMessage]
            )
            delegate?.appendOutput(result.err ?? "")
            delegate?.documentManager(self, didFailToOpen: error)
            return
        }
        
        if let successLog {
            delegate?.appendOutput(successLog)
        }
        
        if printStdErrOnSuccess {
            delegate?.appendOutput(result.err ?? "")
        }
        
        documentIsModified = false
        Settings.shared.lastOpenedFile = url.path
        currentDocumentURL = resolveDocumentURL(from: url)
        
        delegate?.documentManagerDidOpen(self, withResult: result)
    }
    
    private func openImage(url: URL) {
        openWithTool(
            executableName: "grob",
            url: url,
            arguments: ["--type", ProjectSettings.shared.language],
            failureMessage: "Failed to read from the image file.",
            successLog: "Importing \"\(url.lastPathComponent)\"\n"
        )
    }

    private func openNote(url: URL) {
        openWithTool(
            executableName: "hpnote",
            url: url,
            arguments: [],
            failureMessage: "Failed to read from the note file.",
            printStdErrOnSuccess: true
        )
    }
    
    private func openAdafruitGFXFont(url: URL) {
        openWithTool(
            executableName: "hpfont",
            url: url,
            arguments: ["--type", ProjectSettings.shared.language],
            failureMessage: "Failed to read from the font file.",
            successLog: "Importing \"\(url.lastPathComponent)\"\n",
            printStdErrOnSuccess: true
        )
    }
    
    private func saveProgram(url: URL) {
        guard let currentDocumentURL else { return }
        
        let path = URL(fileURLWithPath: ToolchainPaths.bin).appending(path: "hpppl+")
        let result = ProcessRunner.run(executable: path, arguments: [currentDocumentURL.path, "-o", url.path])
        
        guard result.exitCode == 0 else {
            let error = NSError(
                domain: "Error",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to write \"\(url.lastPathComponent)\" to file."]
            )
            delegate?.appendOutput(result.err ?? "")
            delegate?.documentManager(self, didFailWith: error)
            return
        }
        
        delegate?.appendOutput(result.err ?? "")
        self.currentDocumentURL = url
        documentIsModified = false
        delegate?.documentManagerDidSave(self)
    }
    
    private func openProgram(url: URL) {
        openWithTool(
            executableName: "hpppl+",
            url: url,
            arguments: [],
            failureMessage: "Failed to read from the program file.",
            successLog: "Importing \"\(url.lastPathComponent)\"\n",
            printStdErrOnSuccess: true
        )
    }
    
    func openDocument(at url: URL) {
        let encoding: String.Encoding
        switch url.pathExtension.lowercased() {
        case "prgm":
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
            currentDocumentURL = url
            documentIsModified = false
            Settings.shared.lastOpenedFile = url.path
            delegate?.documentManagerDidOpen(self, withResult: (out: content, err: "", exitCode: 0))
            
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
    func saveDocument(content: String, _ silent: Bool = false) -> Bool {
        guard let url = currentDocumentURL else { return false }
        return saveDocument(to: url, content: content, silent: silent)
    }
    
    @discardableResult
    func saveDocument(to url: URL, content: String, silent: Bool = false) -> Bool {
        let encoding: String.Encoding
        switch url.pathExtension.lowercased() {
        case "prgm":
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
            try content.write(to: url, atomically: true, encoding: encoding)
//            try editor.string.write(to: url, atomically: true, encoding: encoding)
            if silent {
                return true
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
        content: String,
        allowedContentTypes: [UTType],
        defaultFileName: String = "Untitled",
    ) {
        let allowedExtensions = allowedContentTypes.compactMap { type in
            type.preferredFilenameExtension
        }
        
        saveAs(allowedExtensions: allowedExtensions, defaultFileName: defaultFileName) { outputURL in
            self.saveDocument(to: outputURL, content: content)
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
