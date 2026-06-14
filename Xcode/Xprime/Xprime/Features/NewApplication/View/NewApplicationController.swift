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

final class NewApplicationViewController: CustomViewController, NSTextFieldDelegate, NSComboBoxDelegate {
    @IBOutlet private weak var productName: NSTextField!
    @IBOutlet private weak var baseApplication: NSPopUpButton!
    
    private var vc: MainViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard let window = view.window else { return }
        window.center()
        
        DispatchQueue.main.async {
            if let editor = window.fieldEditor(false, for: self.productName) as? NSTextView {
                let end = self.productName.stringValue.count
                editor.selectedRange = NSRange(location: end, length: 0)
            }
        }
        
        guard let window = NSApplication.shared.windows.first else {
            self.view.window?.close(); return
        }
        vc = window.contentViewController as? MainViewController
    }
    
    private func setup() {
        refreshBaseApplicationMenu()
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
                let name = try self.safeName(from: self.productName.stringValue)
                self.create(named: name, in: folderURL)
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
    private func refreshBaseApplicationMenu() {
        guard let menu = baseApplication.menu else { return }
        for item in menu.items {
            item.image?.size = iconSize.tiny
        }
    }
    
    private func create(named name: String, in directoryURL: URL) {
   
        do {
            
            
            let sourceURL = Bundle.main.url(forResource: "application", withExtension: "hpppl")
            let destinationURL = directoryURL
                .appendingPathComponent(name)
                .appendingPathComponent("main")
                .appendingPathExtension("hpppl")
            
            guard let sourceURL else { return }
            
            try FileManager.default.createDirectory(
                at: directoryURL
                    .appendingPathComponent(name),
                withIntermediateDirectories: false
            )
            
            try FileManager.default.copyItem(
                at: sourceURL,
                to: destinationURL
            )
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd"
            let dateString = formatter.string(from: Date())
            
            createFileIfNeeded(
                at: directoryURL
                    .appendingPathComponent(name)
                    .appendingPathComponent("info.note"),
                defaultContent: "\\fs18\\b \(name)\n\\fs12\\b0Created by \(NSFullUserName()) on \(dateString)."
            )
            
            
            if let url = Bundle.main.url(forResource: "default", withExtension: "xprimeproj") {
                try FileManager.default.copyItem(
                    at: url,
                    to: directoryURL
                        .appendingPathComponent(name)
                        .appendingPathComponent(name.replacingOccurrences(of: " ", with: "_"))
                        .appendingPathExtension("xprimeproj")
                )
            }
            
            let baseApplicationName = baseApplication.selectedItem!.title
            try HPServices.resetHPAppContents(at: directoryURL.appendingPathComponent(name), named: name.replacingOccurrences(of: " ", with: "_"), fromBaseApplicationNamed: baseApplicationName)
            
            FileManager.default.changeCurrentDirectoryPath(
                directoryURL.appendingPathComponent(name).path
            )
        } catch {
            return
        }
    }
    
    private func createFileIfNeeded(at url: URL, defaultContent: String = "") {
        guard !FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            try defaultContent.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to create file:", error)
        }
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
