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

protocol DocumentManagerDelegate: AnyObject {
    // Called when a document is successfully saved
    func documentManagerDidSave(_ manager: DocumentManager)
    
    // Called when saving fails
    func documentManager(_ manager: DocumentManager, didFailWith error: Error)
    
    // Called when a document is successfully opened
    func documentManagerDidOpen(_ manager: DocumentManager)
    
    // Optional: called when opening fails
    func documentManager(_ manager: DocumentManager, didFailToOpen error: Error)
}

final class DocumentManager {
    
    weak var delegate: DocumentManagerDelegate?
    
    private(set) var currentDocumentURL: URL?
    private var editor: CodeEditorTextView

    var documentIsModified: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .documentModificationChanged, object: nil)
        }
    }

    init(editor: CodeEditorTextView) {
        self.editor = editor
    }

    func openLastOrUntitled() {
        if let path = UserDefaults.standard.string(forKey: "lastOpenedFilePath"),
           FileManager.default.fileExists(atPath: path) {
            openDocument(url: URL(fileURLWithPath: path))
        } else {
            openUntitled()
        }
    }

    private func openUntitled() {
        editor.string = ""
        currentDocumentURL = nil
        documentIsModified = false
    }

    func openDocument(url: URL) {
        let ext = url.pathExtension.lowercased()
        
        // Handle HPPRGM / HPAPPRGM files
        if ext == "hpprgm" || ext == "hpappprgm" {
            let pplPath = ToolchainPaths.bin.appendingPathComponent("ppl+")
            let result = ProcessRunner.run(executable: pplPath, arguments: [url.path, "-o", "/dev/stdout"])
            
            guard let output = result.out, !output.isEmpty else {
                let error = NSError(
                    domain: "Error",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to read from the program file."]
                )
                delegate?.documentManager(self, didFailToOpen: error)
                return
            }
            
            editor.string = output
            currentDocumentURL = url.deletingPathExtension().appendingPathExtension("prgm")
            documentIsModified = false
            UserDefaults.standard.set(url.deletingPathExtension().appendingPathExtension("prgm").path, forKey: "lastOpenedFilePath")
            delegate?.documentManagerDidOpen(self)
            FileManager.default.changeCurrentDirectoryPath(url.deletingLastPathComponent().path)
            return
        }
        
        // Handle normal text-based documents
        let encoding: String.Encoding
        switch ext {
        case "prgm", "app", "note":
            encoding = .utf16
        case "hpnote", "hpappnote":
            encoding = .utf16LittleEndian
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
        
        FileManager.default.changeCurrentDirectoryPath(url.deletingLastPathComponent().path)
    }
    
    @discardableResult
    func saveDocument() -> Bool {
        guard let url = currentDocumentURL else { return false }
        return saveDocumentAs(to: url)
    }
    
    @discardableResult
    func saveDocumentAs(to url: URL) -> Bool {
        let encoding: String.Encoding
        switch url.pathExtension.lowercased() {
        case "prgm", "app", "note":
            encoding = .utf16
        case "hpnote", "hpappnote":
            encoding = .utf16LittleEndian
        default:
            encoding = .utf8
        }
        
        do {
            guard var data = editor.string.data(using: encoding) else {
                throw NSError(domain: "EncodingError", code: 1)
            }

            if url.pathExtension.lowercased() == "hpnote" {
                // Append 0x0000 (two zero bytes)
                data.append(contentsOf: [0x00, 0x00])
            }

            try data.write(to: url, options: .atomic)
            
//            try editor.string.write(to: url, atomically: true, encoding: encoding)
            
            documentIsModified = false
            delegate?.documentManagerDidSave(self)
            return true
        } catch {
            delegate?.documentManager(self, didFailWith: error)
            return false
        }
    }
}

extension Notification.Name {
    static let documentModificationChanged = Notification.Name("documentModificationChanged")
}
