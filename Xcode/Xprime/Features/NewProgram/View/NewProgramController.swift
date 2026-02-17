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

final class NewProgramViewController: NSViewController, NSTextFieldDelegate, NSComboBoxDelegate {
    @IBOutlet private weak var language: NSPopUpButton!
    @IBOutlet private weak var productName: NSTextField!
    @IBOutlet private weak var CAS: NSSwitch!
    
//    private var language = "prgm+"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        guard let window = view.window else { return }
        
        // Make window background transparent
        window.titleVisibility = .hidden
        window.center()
        window.titlebarAppearsTransparent = true
        window.styleMask = [.nonactivatingPanel, .titled]
        window.styleMask.insert(.fullSizeContentView)
    }
    
    
    // MARK: - Actions
    @IBAction func create(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        panel.prompt = "Create"
        panel.level = .modalPanel

        panel.begin { result in
            guard result == .OK, let folderURL = panel.url else { return }

            do {
                let name = try self.safeName(from: self.productName.stringValue)
                self.create(named: name, in: folderURL)
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
    private func create(named name: String, in directoryURL: URL) {
        guard let selectedLanguage = language.titleOfSelectedItem else { return }
        
        do {
            let sourceURL = Bundle.main.url(forResource: CAS.state == .on ? "program-cas" : "program", withExtension: selectedLanguage == "PPL" ? "ppl" : "ppl+")
            let destinationURL = directoryURL
                .appendingPathComponent(name)
                .appendingPathComponent("main")
                .appendingPathExtension(selectedLanguage == "PPL" ? "prgm" : "prgm+")
            
            guard let sourceURL else { return }
            
            try FileManager.default.createDirectory(
                at: directoryURL.appendingPathComponent(name),
                withIntermediateDirectories: false
            )
            
            try replaceProjectName(
                in: sourceURL,
                to: destinationURL,
                newName: name
            )
            
            if let url = Bundle.main.url(forResource: "info", withExtension: "note") {
                try FileManager.default.copyItem(
                    at: url,
                    to: directoryURL
                        .appendingPathComponent(name)
                        .appendingPathComponent("info.note")
                )
            }
            
            if let url = Bundle.main.url(forResource: "Xprime", withExtension: "xprimeproj") {
                try FileManager.default.copyItem(
                    at: url,
                    to: directoryURL
                        .appendingPathComponent(name)
                        .appendingPathComponent(name.replacingOccurrences(of: " ", with: "_"))
                        .appendingPathExtension("xprimeproj")
                )
            }
            
            FileManager.default.changeCurrentDirectoryPath(
                directoryURL.appendingPathComponent(name).path
            )
        } catch {
            return
        }
    }
    
    
    private func replaceProjectName(
        in sourceURL: URL,
        to destinationURL: URL,
        newName: String
    ) throws {
        // Read file contents
        let sourceEncoding: String.Encoding = sourceURL.pathExtension.lowercased() == "prgm" ? .utf16 : .utf8
        let destinationEncoding: String.Encoding = destinationURL.pathExtension.lowercased() == "prgm" ? .utf16 : .utf8
        
        let contents = try String(contentsOf: sourceURL, encoding: sourceEncoding)

        // Replace placeholder
        let updatedContents = contents.replacingOccurrences(
            of: "$(PRODUCT_NAME)",
            with: newName.replacingOccurrences(of: " ", with: "_")
        )

        // Write back to destination
        try updatedContents.write(
            to: destinationURL,
            atomically: true,
            encoding: destinationEncoding
        )
    }
    
    enum AppError: Error {
        case invalidAppName
    }
    
    private func safeName(from name: String) throws -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let sanitized = name
            .components(separatedBy: invalidCharacters)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sanitized.isEmpty else {
            throw AppError.invalidAppName
        }

        return sanitized
    }
}
