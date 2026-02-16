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

final class NewApplicationViewController: NSViewController, NSTextFieldDelegate, NSComboBoxDelegate {
    @IBOutlet private weak var baseApp: NSPopUpButton!
    @IBOutlet private weak var language: NSPopUpButton!
    @IBOutlet private weak var productName: NSTextField!
    
    private var baseApps = "None"
    
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
    }
    
    private func setup() {
        populateBaseAppMenu()
    }
    
    // MARK: - Actions
    @objc func preferBaseAppSeclection(_ sender: NSMenuItem) {
        baseApps = sender.title
    }
    
    
    @IBAction func create(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        panel.prompt = "Create"

        panel.begin { result in
            guard result == .OK, let folderURL = panel.url else { return }

            do {
                let name = try self.fileSafeName(from: self.productName.stringValue)
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
    private func populateBaseAppMenu() {
        let applications: [String] = [
            "None",
            "Function",
            "Advanced Graphing",
            "Graph 3D",
            "Geometry",
            "Spreadsheet",
            "Statistics 1Var",
            "Statistics 2Var",
            "Inference",
            "Data Streamer",
            "Solve",
            "Linear Solver",
            "Explorer",
            "Triangle Solver",
            "Finance",
            "Python",
            "Parametric",
            "Polar",
            "Sequence"
        ]

        let menu = NSMenu()
        for application in applications {
            let item = NSMenuItem(
                title: application,
                action: #selector(preferBaseAppSeclection(_:)),
                keyEquivalent: ""
            )

            if let url = Bundle.main.url(
                forResource: application,
                withExtension: "png",
                subdirectory: "Developer/Library/Xprime/Templates/Base Applications/\(application).hpappdir"
            ) {
                if let image = NSImage(contentsOf: url) {
                    image.size = NSSize(width: 16, height: 16) // standard menu icon size
                    item.image = image
                }
            }
            menu.addItem(item)
        }

        baseApp.menu = menu
    }
    
    func create(named name: String, in directoryURL: URL) {
        do {
            let ext = language.titleOfSelectedItem! == "PPL" ? "prgm" : "prgm+"
            let appDirectoryURL = directoryURL.appendingPathComponent(name)
            
            try FileManager.default.createDirectory(
                at: appDirectoryURL,
                withIntermediateDirectories: false
            )

            if let url = Bundle.main.url(forResource: "application", withExtension: ext) {
                try FileManager.default.copyItem(
                    at: url,
                    to: directoryURL.appendingPathComponent("\(name)/main.\(ext)")
                )
            }
            
            if let url = Bundle.main.url(forResource: "info", withExtension: "note") {
                try FileManager.default.copyItem(
                    at: url,
                    to: directoryURL.appendingPathComponent("\(name)/info.note")
                )
            }
            
            if let url = Bundle.main.url(forResource: "Xprime", withExtension: "xprimeproj") {
                try FileManager.default.copyItem(
                    at: url,
                    to: directoryURL
                        .appendingPathComponent(name)
                        .appendingPathComponent(name)
                        .appendingPathExtension("xprimeproj")
                )
            }
            
            try HPServices.resetHPAppContents(at: directoryURL.appendingPathComponent(name), named: name, fromBaseApplicationNamed: baseApps)
            
            FileManager.default.changeCurrentDirectoryPath(
                directoryURL.appendingPathComponent(name).path
            )
        } catch {
            return
        }
    }
    
    enum AppError: Error {
        case invalidAppName
    }
    
    private func fileSafeName(from name: String) throws -> String {
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
