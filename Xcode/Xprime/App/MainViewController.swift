// The MIT License (MIT)
//
// Copyright (c) 2025 Insoft.
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

extension NSColor {
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Remove "#" prefix
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        
        // Handle shorthand (#RGB)
        if hexString.count == 3 {
            let r = hexString[hexString.startIndex]
            let g = hexString[hexString.index(hexString.startIndex, offsetBy: 1)]
            let b = hexString[hexString.index(hexString.startIndex, offsetBy: 2)]
            hexString = "\(r)\(r)\(g)\(g)\(b)\(b)"
        }
        
        guard hexString.count == 6,
              let rgb = Int(hexString, radix: 16) else {
            return nil
        }
        
        let red   = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue  = CGFloat(rgb & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

extension MainViewController: NSWindowRestoration {
    static func restoreWindow(withIdentifier identifier: NSUserInterfaceItemIdentifier, state: NSCoder, completionHandler: @escaping (NSWindow?, Error?) -> Void) {
        // Restore your window here if needed
        completionHandler(nil, nil) // or provide restored window
    }
}

final class MainViewController: NSViewController, NSTextViewDelegate, NSToolbarItemValidation, NSMenuItemValidation, NSSplitViewDelegate {
    @IBOutlet weak var toolbar: NSToolbar!
    @IBOutlet weak var icon: NSImageView!
    
    @IBOutlet weak var splitView: NSSplitView!
    @IBOutlet weak var fixedPane: NSView!
    
    private var currentURL: URL?
    private var parentURL: URL? {
        guard let url = currentURL else { return nil }
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path, isDirectory: &isDir) && isDir.boolValue {
            return url.deletingLastPathComponent()
        }
        return nil
    }
    private var projectName: String? {
        guard let currentURL = currentURL else { return nil }
        if currentURL.pathComponents.count <= 1 {
            return nil
        }
        let projectName = currentURL
            .deletingLastPathComponent()
            .lastPathComponent
        
        return projectName
    }
    
    private var projectURL: URL? {
        guard let projectName, let parentURL else { return nil }
        let url = parentURL.appendingPathComponent(projectName).appendingPathExtension("prgm+")
        if !FileManager.default.fileExists(atPath: url.path) {
            return nil
        }
        return url
    }
    
    @IBOutlet var codeEditorTextView: CodeEditorTextView!
    @IBOutlet var outputTextView: NSTextView!
    @IBOutlet var statusTextLabel: NSTextField!
    @IBOutlet var outputScrollView: NSScrollView!
    
    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        // Optionally hide the divider when the output is collapsed
        return outputScrollView.isHidden
    }
   
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        codeEditorTextView.delegate = self
        splitView.delegate = self
        
        // Add the Line Number Ruler
        if let scrollView = codeEditorTextView.enclosingScrollView {
            let ruler = LineNumberRulerView(textView: codeEditorTextView)
            scrollView.verticalRulerView = ruler
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
            
            // Force layout to avoid invisible window
            scrollView.tile()
        }
        
        outputTextView.textContainerInset = NSSize(width: 5, height: 0)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateStatus),
            name: NSTextView.didChangeSelectionNotification,
            object: codeEditorTextView
        )
        
        NotificationCenter.default.addObserver(
            forName: NSText.didChangeNotification,
            object: codeEditorTextView,
            queue: .main
        ) { [weak self] _ in
            self?.documentIsModified = true
        }
      
        if let menu = NSApp.mainMenu {
            populateThemesMenu(menu: menu)
            populateGrammarMenu(menu: menu)
        }
    }
    
    @objc private func updateStatus() {
        if let editor = codeEditorTextView {
            let text = editor.string as NSString
            let selectedRange = editor.selectedRange
            let cursorLocation = selectedRange.location
            
            // Find line number
            var lineNumber = 1
            var columnNumber = 1
            
            // Count newlines up to the cursor
            for i in 0..<cursorLocation {
                if text.character(at: i) == 10 { // '\n'
                    lineNumber += 1
                    columnNumber = 1
                } else {
                    columnNumber += 1
                }
            }
            statusTextLabel.stringValue = "Line: \(lineNumber) Col: \(columnNumber)"
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if let path = UserDefaults.standard.string(forKey: "lastOpenedFilePath") {
            let url = URL(fileURLWithPath: path)
            openDocument(url: url)
        } else {
            if let window = self.view.window, let url = Bundle.main.resourceURL?.appendingPathComponent("Untitled.prgm+") {
                window.representedURL = url
                window.title = "Untitled (UNSAVED)"
                openDocument(url: url)
                currentURL = nil
            }
        }
    }
    
   
    var documentIsModified: Bool = false {
        didSet {
            if let window = self.view.window {
                if documentIsModified {
                    if let url = currentURL {
                        window.title = url.lastPathComponent + " — Edited"
                    }
                } else {
                    // When saved, show current file name or default title
                    if let url = currentURL {
                        window.title = url.lastPathComponent
                    } else {
                        window.title = "Untitled"
                    }
                }
            }
        }
    }
    
    private func populateThemesMenu(menu: NSMenu) {
        guard let resourceURLs = Bundle.main.urls(forResourcesWithExtension: "xpcolortheme", subdirectory: "Themes") else {
            print("⚠️ No .xpcolortheme files found.")
            return
        }

        for fileURL in resourceURLs {
            let filename = fileURL.deletingPathExtension().lastPathComponent

            let menuItem = NSMenuItem(title: filename, action: #selector(handleThemeSelection(_:)), keyEquivalent: "")
            menuItem.representedObject = fileURL
            menuItem.target = self  // or another target if needed
            let theme = UserDefaults.standard.object(forKey: "theme") as? String ?? "Default (Dark)"
            if filename == theme {
                menuItem.state = .on
            }

            menu.item(withTitle: "Editor")?.submenu?.item(withTitle: "Theme")?.submenu?.addItem(menuItem)
        }
    }
    
    private func populateGrammarMenu(menu: NSMenu) {
        guard let resourceURLs = Bundle.main.urls(forResourcesWithExtension: "xpgrammar", subdirectory: "Grammars") else {
            print("⚠️ No .xpgrammar files found.")
            return
        }
        
        for fileURL in resourceURLs {
            let name = fileURL.deletingPathExtension().lastPathComponent
            
            let menuItem = NSMenuItem(title: name, action: #selector(handleGrammarSelection(_:)), keyEquivalent: "")
            menuItem.representedObject = fileURL
            menuItem.target = self  // or another target if needed
            let grammar = UserDefaults.standard.object(forKey: "grammar") as? String ?? "Language"
            if name == grammar {
                menuItem.state = .on
            }

            menu.item(withTitle: "Editor")?.submenu?.item(withTitle: "Grammar")?.submenu?.addItem(menuItem)
        }
    }
    
    
    // MARK: - Action Handlers
    
    @objc func handleThemeSelection(_ sender: NSMenuItem) {
        guard let mainVC = NSApp.mainWindow?.contentViewController as? MainViewController else { return }
        guard let mainMenu = NSApp.mainMenu else { return }
        
        guard let fileURL = sender.representedObject as? URL else { return }
        mainVC.codeEditorTextView.loadTheme(named: sender.title)
      
        UserDefaults.standard.set(sender.title, forKey: "theme")
        
        for menuItem in mainMenu.item(withTitle: "Editor")?.submenu?.item(withTitle: "Theme")!.submenu!.items ?? [] {
            menuItem.state = .off
        }
        sender.state = .on
    }
    
    @objc func handleGrammarSelection(_ sender: NSMenuItem) {
        guard let mainVC = NSApp.mainWindow?.contentViewController as? MainViewController else { return }
        guard let mainMenu = NSApp.mainMenu else { return }
        
        guard let fileURL = sender.representedObject as? URL else { return }
//        mainVC.codeEditorTextView.loadGrammar(at: fileURL)
        mainVC.codeEditorTextView.loadGrammar(named: sender.title)
        UserDefaults.standard.set(sender.title, forKey: "grammar")
        
        for menuItem in mainMenu.item(withTitle: "Editor")?.submenu?.item(withTitle: "Grammar")!.submenu!.items ?? [] {
            menuItem.state = .off
        }
        sender.state = .on
    }
    
    
    // MARK: - Helper Functions
    
    private func updateDocumentIconButtonImage() {
        guard let url = self.currentURL else {
            return
        }
        if let window = self.view.window {
            window.title = url.lastPathComponent
            
            window.representedURL = url
            if let iconButton = window.standardWindowButton(.documentIconButton) {
                if url.pathExtension.lowercased() == "prgm+" {
                    iconButton.image = NSImage(named: "pplplus")
                } else {
                    iconButton.image = NSImage(named: "ppl")
                }
                iconButton.isHidden = false
            }
        }
    }
    
    // MARK: - Action-handling methods
    
    private func openDocument(url: URL) {
        guard let contents = HPServices.loadHPPrgm(at: url) else { return }
        
        UserDefaults.standard.set(url.path, forKey: "lastOpenedFilePath")
        
        currentURL = url
        codeEditorTextView.string = contents
        
        refreshQuickOpenToolbar()
        
        guard let projectName = projectName else { return }
        guard let parentURL = parentURL else { return }
        let folderURL = parentURL.appendingPathComponent("\(projectName).hpappdir")
        
        let ext = url.pathExtension.lowercased()
        
        if ext == "prgm+" || ext == "ppl+" {
            codeEditorTextView.loadGrammar(named: "Prime Plus")
        }
        
        if ext == "prgm" || ext == "ppl" || ext == "hpprgm" || ext == "hpappprgm" {
            codeEditorTextView.loadGrammar(named: "Prime")
        }
        
        if ext == "py" {
            codeEditorTextView.loadGrammar(named: "Python")
        }
        
        updateDocumentIconButtonImage()
        
        let fm = FileManager.default
        
        if fm.fileExists(atPath: folderURL.appendingPathComponent("icon.png").path) {
            icon.image = NSImage(contentsOf: folderURL.appendingPathComponent("icon.png"))
            return
        }
        
        if fm.fileExists(atPath: parentURL.appendingPathComponent("icon.png").path) {
            icon.image = NSImage(contentsOf: parentURL.appendingPathComponent("icon.png"))
            return
        }
        
        icon.image = NSImage(contentsOf: Bundle.main.url(forResource: "icon", withExtension: "png", subdirectory:"Developer/Library/Xprime/Templates/Application Template")!)
        
        
    }
    
    private func saveDocumentAs() {
        let savePanel = NSSavePanel()
        let extensions = ["prgm+"]
        let contentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        
        savePanel.allowedContentTypes = contentTypes
        savePanel.nameFieldStringValue = "Untitled.prgm+"
        
        if let window = self.view.window {
            let url = URL(fileURLWithPath: window.title)
            savePanel.nameFieldStringValue = url.deletingPathExtension().appendingPathExtension("prgm+").lastPathComponent
        }
        
        savePanel.begin { result in
            guard result == .OK, let url = savePanel.url else { return }

            do {
                try HPServices.savePrgm(at: url, content: self.codeEditorTextView.string)
                self.currentURL = url
                self.documentIsModified = false
                
                if let projectName = self.projectName {
                    XprimeProjectServices.save(to: url.deletingLastPathComponent(), named: projectName)
                }
                
            } catch {
                let alert = NSAlert()
                alert.messageText = "Error"
                alert.informativeText = "Failed to save file: \(error)"
                alert.runModal()
            }
        }
    }
    
    private func saveDocument() {
        guard let url = currentURL else {
            saveDocumentAs()
            return
        }
        
        if url.pathExtension.lowercased() == "hpprgm" || url.pathExtension.lowercased()  == "hpappprgm" {
            saveDocumentAs()
            return
        }
        
        do {
            try HPServices.savePrgm(at: url, content: codeEditorTextView.string)
            currentURL = url
            if let projectName = self.projectName {
                XprimeProjectServices.save(to: url.deletingLastPathComponent(), named: projectName)
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Failed to save file: \(error)"
            alert.runModal()
        }
    }
    
    private func prepareForArchive() {
        guard
            let currentURL = currentURL,
                let projectName = projectName ,
                let parentURL = parentURL
        else { return }
        
        do {
            try HPServices.restoreMissingAppFiles(in: parentURL, named: projectName)
        } catch {
            outputTextView.string = "Failed to build for archiving: \(error)"
            return
        }
        
        let result = HPServices.preProccess(at: currentURL, to: parentURL
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpappdir")
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpappprgm"),
            compress: UserDefaults.standard.object(forKey: "compression") as? Bool ?? false
        )
        outputTextView.string = result.err ?? ""
    }
    
    private func archiveProcess() {
        guard let projectName = projectName , let parentURL = parentURL else { return }
        
        let url: URL
        
        let dirA = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/HP Prime/Calculators/Prime")
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpappdir")
        let dirB = parentURL
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpappdir")
        
        let archiveProjectAppOnly = UserDefaults.standard.object(forKey: "archiveProjectAppOnly") as? Bool ?? true
        if dirA.isNewer(than: dirB), archiveProjectAppOnly == false {
            url = dirA.deletingLastPathComponent()
            self.outputTextView.string = "Archiving from the virtual calculator directory.\n"
        } else {
            url = parentURL
            self.outputTextView.string = "Archiving from the current project directory.\n"
        }

        
        let result = HPServices.archiveHPAppDirectory(in: url, named: projectName, to: parentURL)
        
        if let out = result.out, !out.isEmpty {
            self.outputTextView.string += out
        }
        self.outputTextView.string += result.err ?? ""
    }
    
    @discardableResult
    private func processRequires(in text: String) -> (cleaned: String, requiredFiles: [String]) {
        let pattern = #"#require\s*"([^"<>]+)""#
        let regex = try! NSRegularExpression(pattern: pattern)

        var requiredFiles: [String] = []
        var cleanedText = text
        
        let basePath = ToolchainPaths.developerRoot.appendingPathComponent("usr")
            .appendingPathComponent("hpprgm")
            .path

        // Find matches
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches.reversed() {
            // Extract filename
            if let range = Range(match.range(at: 1), in: text) {
                let filePath = URL(fileURLWithPath: basePath)
                    .appendingPathComponent(String(text[range]))
                    .appendingPathExtension("hpprgm")
                    .path
                    
                requiredFiles.append(filePath)
            }

            // Remove entire #require line from the output
            if let fullRange = Range(match.range, in: cleanedText) {
                cleanedText.removeSubrange(fullRange)
            }
        }

        return (cleanedText, requiredFiles)
    }
    
    @discardableResult
    private func processAppRequires(in text: String) -> (cleaned: String, requiredApps: [String]) {
        let pattern = #"#require\s*<([^"<>]+)>"#
        let regex = try! NSRegularExpression(pattern: pattern)

        var requiredApps: [String] = []
        var cleanedText = text
        
        let basePath = ToolchainPaths.developerRoot.appendingPathComponent("usr")
            .appendingPathComponent("hpappdir")
            .path

        // Find matches
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches.reversed() {
            // Extract filename
            if let range = Range(match.range(at: 1), in: text) {
                let filePath = URL(fileURLWithPath: basePath)
                    .appendingPathComponent(String(text[range]))
                    .appendingPathExtension("hpappdir")
                    .path
                    
                requiredApps.append(filePath)
            }

            // Remove entire #require line from the output
            if let fullRange = Range(match.range, in: cleanedText) {
                cleanedText.removeSubrange(fullRange)
            }
        }

        return (cleanedText, requiredApps)
    }
    
   
    
    private func installRequiredPrograms(requiredFiles: [String]) {
        for file in requiredFiles {
            do {
                try HPServices.installHPPrgm(at: URL(fileURLWithPath: file))
                outputTextView.string += "Installed: \(file)\n"
            } catch {
                outputTextView.string += "Error installing \(file).hpprgm: \(error)"
            }
        }
    }
    
    private func installRequiredApps(requiredApps: [String]) {
        for file in requiredApps {
            do {
                try HPServices.installHPAppDirectory(at: URL(fileURLWithPath: file))
                outputTextView.string += "Installed: \(file)\n"
            } catch {
                outputTextView.string += "Error installing \(file).hpappdir: \(error)"
            }
        }
    }
    

    private func performBuild() {
        guard let sourceURL = projectURL else {
            return
        }
        let destinationURL = sourceURL
            .deletingPathExtension()
            .appendingPathExtension("hpprgm")
        
        let compression = UserDefaults.standard.object(forKey: "compression") as? Bool ?? false
        let result = HPServices.preProccess(at: sourceURL, to: destinationURL,  compress: compression)
        outputTextView.string = result.err ?? ""
    }
    
    func runExport(
        allowedExtensions: [String],
        defaultName: String,
        action: @escaping (_ outputURL: URL) -> (out: String?, err: String?, exitCode: Int32)
    ) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = allowedExtensions.compactMap { UTType(filenameExtension: $0) }
        savePanel.nameFieldStringValue = defaultName
        
        savePanel.begin { result in
            guard result == .OK, let outURL = savePanel.url else { return }
            
            let result = action(outURL)
            
            if let out = result.out, !out.isEmpty {
                self.outputTextView.string = out
            } else {
                self.outputTextView.string = result.err ?? ""
            }
        }
    }
    
    @objc private func quickOpen(_ sender: NSMenuItem) {
        guard let parentURL = parentURL else { return }
        openDocument(url: parentURL.appendingPathComponent(sender.title))
    }
    
    private func refreshQuickOpenToolbar() {
        guard let directoryURL = parentURL else { return }
        let menu = NSMenu()
       
    
        let contents = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        contents?
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == false }
            .forEach { url in
                if url.pathExtension == "prgm" ||
                    url.pathExtension == "prgm+" ||
                    url.pathExtension == "ppl" ||
                    url.pathExtension == "ppl+" ||
                    url.pathExtension == "py" {
                    menu.addItem(
                        withTitle: url.lastPathComponent,
                        action: #selector(quickOpen(_:)),
                        keyEquivalent: ""
                    )
                    menu.items.last?.state = (url == currentURL) ? .on : .off
                }
            }
  
        guard
                let toolbar = view.window?.toolbar,
                let item = toolbar.items.first(where: {
                    $0.paletteLabel == "Quick Open"
                }),
                let comboButton = item.view as? NSComboButton
            else {
                return
            }
        
        comboButton.menu = menu
        comboButton.title = currentURL?.lastPathComponent ?? ""
    }
    
    // MARK: - Interface Builder Action Handlers
    
    @IBAction func newProject(_ sender: Any) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = ["xprimeproj"].compactMap { UTType(filenameExtension: $0) }
        savePanel.nameFieldStringValue = "Untitled"
        
        savePanel.begin { result in
            guard result == .OK, let selectedURL = savePanel.url else { return }
            
            do {
                // Strip extension from panel result
                let projectName = selectedURL.deletingPathExtension().lastPathComponent
                
                // Project directory path
                let parentDir = selectedURL.deletingLastPathComponent()
                let projectDir = parentDir.appendingPathComponent(projectName)
                
                // Create the project directory
                try FileManager.default.createDirectory(
                    at: projectDir,
                    withIntermediateDirectories: false
                )
                
                // File inside project directory
                let prgmURL = projectDir.appendingPathComponent(projectName + ".prgm+")
                
                if let url = Bundle.main.resourceURL?.appendingPathComponent("Untitled.prgm+") {
                    self.codeEditorTextView.string = HPServices.loadHPPrgm(at: url) ?? ""
                }
                
                // Save the .prgm+ file
                try HPServices.savePrgm(
                    at: prgmURL,
                    content: self.codeEditorTextView.string
                )
                
                // Update document state
                self.currentURL = prgmURL
                self.documentIsModified = false
                
                // Save project metadata
                XprimeProjectServices.save(to: projectDir, named: projectName)
                
                // Change working directory (if your app depends on this)
                FileManager.default.changeCurrentDirectoryPath(projectDir.path)
                
            } catch {
                let alert = NSAlert()
                alert.messageText = "Error"
                alert.informativeText = "Failed to save project: \(error.localizedDescription)"
                alert.runModal()
            }
        }
    }
    
    @IBAction func newDocument(_ sender: Any) {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("Untitled.prgm+") {
            codeEditorTextView.string = HPServices.loadHPPrgm(at: url) ?? ""
            currentURL = nil
            if let window = self.view.window {
                window.title = "Untitled.prgm+"
            }
        }
    }
    
    @IBAction func openDocument(_ sender: Any) {
        if documentIsModified {
            saveDocument()
        }
        let openPanel = NSOpenPanel()
        let extensions = ["py", "prgm", "prgm+", "hpprgm", "hpappprgm", "ppl", "ppl+"]
        let contentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        
        openPanel.allowedContentTypes = contentTypes
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        openPanel.begin { result in
            guard result == .OK, let url = openPanel.url else { return }
            self.openDocument(url: url)
            if let projectName = self.projectName {
                XprimeProjectServices.load(at: url.deletingLastPathComponent(), named: projectName)
            }
        }
    }
    
    @IBAction func saveDocument(_ sender: Any) {
        saveDocument()
    }
    
    @IBAction func saveDocumentAs(_ sender: Any) {
        saveDocumentAs()
    }
    
    private func exportHPProgram(from sourceURL: URL) {
        let defaultName = sourceURL
            .deletingPathExtension()
            .lastPathComponent + ".hpprgm"

        let compression = UserDefaults.standard.bool(forKey: "compression")

        runExport(
            allowedExtensions: ["hpprgm"],
            defaultName: defaultName
        ) { outputURL in
            HPServices.preProccess(
                at: sourceURL,
                to: outputURL,
                compress: compression
            )
        }
    }
    
    @IBAction func exportAsHPPrgm(_ sender: Any) {
        guard let window = view.window else { return }

        func proceedWithExport() {
            guard let url = currentURL else { return }
            exportHPProgram(from: url)
        }

        // Document already exists
        if currentURL != nil {

            if documentIsModified {
                AlertPresenter.presentYesNo(
                    on: window,
                    title: "Save Changes",
                    message: "Do you want to save your changes before exporting as HPPRGM?",
                    primaryActionTitle: "Save"
                ) { confirmed in
                    guard confirmed else { return }
                    self.saveDocument()
                    proceedWithExport()
                }
            } else {
                proceedWithExport()
            }

        } else {
            // First-time save required
            saveDocumentAs()

            guard let url = currentURL,
                  FileManager.default.fileExists(atPath: url.path) else {
                return
            }

            exportHPProgram(from: url)
        }
    }
    
    private func exportPRGM(from sourceURL: URL) {
        let defaultName = sourceURL
            .deletingPathExtension()
            .lastPathComponent + ".prgm"

        runExport(
            allowedExtensions: ["prgm"],
            defaultName: defaultName
        ) { outputURL in
            HPServices.preProccess(
                at: sourceURL,
                to: outputURL
            )
        }
    }
    
    @IBAction func exportAsPrgm(_ sender: Any) {

        guard let window = view.window else { return }

        func proceedWithExport() {
            guard let url = currentURL else { return }
            exportPRGM(from: url)
        }

        // Document already exists
        if currentURL != nil {

            if documentIsModified {
                AlertPresenter.presentYesNo(
                    on: window,
                    title: "Save Changes",
                    message: "Do you want to save your changes before exporting as PRGM?",
                    primaryActionTitle: "Save"
                ) { confirmed in
                    guard confirmed else { return }
                    self.saveDocument()
                    proceedWithExport()
                }
            } else {
                proceedWithExport()
            }

        } else {
            // First save required
            saveDocumentAs()

            guard let url = currentURL,
                  FileManager.default.fileExists(atPath: url.path) else {
                return
            }

            exportPRGM(from: url)
        }
    }
    
    
    @IBAction func exportAsArchive(_ sender: Any) {
        guard let parentURL = parentURL, let projectName = projectName else { return }
        
        runExport(
            allowedExtensions: ["hpappdir.zip"],
            defaultName: "Untitled"
        ) { url in
            
            // Ensure final extension is correct
            var destination = url
            while !destination.pathExtension.isEmpty {
                destination.deletePathExtension()
            }
            destination = destination.appendingPathExtension("hpappdir.zip")
            
            let result = HPServices.archiveHPAppDirectory(in: parentURL, named: projectName, to: destination)
            
            if let out = result.out, !out.isEmpty {
                return result
            }
            
            AlertPresenter.showInfo(
                on: self.view.window,
                title: "Export Failed",
                message: "Could not export the archive “\(url.lastPathComponent)”."
            )
            
            return result
        }
    }
    
    @IBAction func revertDocumentToSaved(_ sender: Any) {
        if let contents = HPServices.loadHPPrgm(at: currentURL!) {
            codeEditorTextView.string = contents
            self.documentIsModified = false
            updateDocumentIconButtonImage()
        }
    }
    @IBAction func stop(_ sender: Any) {
        HPServices.terminateVirtualCalculator()
    }

    @IBAction func run(_ sender: Any) {
        if let _ = currentURL {
            saveDocument()
        } else {
            saveDocumentAs()
        }
        
        guard let parentURL = parentURL, let projectName = projectName else {
            return
        }
        
        let programs = processRequires(in: codeEditorTextView.string)
        installRequiredPrograms(requiredFiles: programs.requiredFiles)
        
        let apps = processAppRequires(in: codeEditorTextView.string)
        installRequiredApps(requiredApps: apps.requiredApps)
        
        performBuild()
        
        if HPServices.hpPrgmExists(atPath: parentURL.path, named: projectName) {
            installHPPrgmFileToCalculator(sender)
            HPServices.launchVirtualCalculator()
        }
    }
    
    @IBAction func archive(_ sender: Any) {
        if let _ = currentURL {
            saveDocument()
        } else {
            saveDocumentAs()
        }
        prepareForArchive()
        archiveProcess()
    }
    
    @IBAction func buildForRunning(_ sender: Any) {
        if let _ = currentURL {
            saveDocument()
        } else {
            saveDocumentAs()
        }
        
        guard let parentURL = parentURL, let projectName = projectName else {
            return
        }
        
        let result = processRequires(in: codeEditorTextView.string)
        installRequiredPrograms(requiredFiles: result.requiredFiles)
        
        let appsToInstall = processAppRequires(in: codeEditorTextView.string)
        installRequiredApps(requiredApps: appsToInstall.requiredApps)
        
        performBuild()
        
        if HPServices.hpPrgmExists(atPath: parentURL.path, named: projectName) {
            installHPPrgmFileToCalculator(sender)
        }
    }
    
    
    @IBAction func buildForArchiving(_ sender: Any) {
        if let _ = currentURL {
            saveDocument()
        } else {
            saveDocumentAs()
        }
        prepareForArchive()
    }
    
    
    @IBAction func installHPPrgmFileToCalculator(_ sender: Any) {
        guard let projectName = projectName, let parentURL = parentURL else { return }
        
        let programURL = parentURL
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpprgm")
        outputTextView.string = "Installing: \(programURL.lastPathComponent)\n"
        do {
            let calculator = UserDefaults.standard.object(forKey: "calculator") as? String ?? "Prime"
            try HPServices.installHPPrgm(at: programURL, forUser: calculator)
        } catch {
            AlertPresenter.showInfo(
                on: self.view.window,
                title: "Installing Failed",
                message: "Installing file: \(error)"
            )
            return
        }
    }
    
    @IBAction func installHPAppDirectoryToCalculator(_ sender: Any) {
        guard let projectName = projectName, let parentURL = parentURL else { return }

        let appDirURL = parentURL
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpappdir")
        outputTextView.string = "Installing: \(appDirURL.lastPathComponent)\n"
        do {
            let calculator = UserDefaults.standard.object(forKey: "calculator") as? String ?? "Prime"
            try HPServices.installHPAppDirectory(at: appDirURL, forUser: calculator)
        } catch {
            AlertPresenter.showInfo(
                on: self.view.window,
                title: "Installing Failed",
                message: "Installing application directory: \(error)"
            )
            return
        }
    }

    @IBAction func archiveWithoutBuilding(_ sender: Any) {
        archiveProcess()
    }
    
    
    
    @IBAction func convert(_ sender: Any) {
        if let _ = currentURL {
            saveDocument()
        } else {
            saveDocumentAs()
        }
        guard let sourceURL = currentURL else {
            return
        }
        let destinationURL = URL(fileURLWithPath: "/dev/stdout")
        
        let result = HPServices.preProccess(at: sourceURL, to: destinationURL)
        if let out = result.out, !out.isEmpty {
            outputTextView.string = "Converting...\n"
            codeEditorTextView.string = out
        }
        outputTextView.string = result.err ?? ""
    }
    
    @IBAction func build(_ sender: Any) {
        if let _ = currentURL {
            saveDocument()
        } else {
            saveDocumentAs()
        }
        performBuild()
    }
    
    
    @IBAction func importImage(_ sender: Any) {
        let openPanel = NSOpenPanel()
        let extensions = ["bmp"]
        let contentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        
        openPanel.allowedContentTypes = contentTypes
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        openPanel.begin { result in
            guard result == .OK, let url = openPanel.url else { return }
            let command = ToolchainPaths.developerRoot.appendingPathComponent("usr")
                .appendingPathComponent("bin")
                .appendingPathComponent("grob")
                .path
            
            let commandURL = URL(fileURLWithPath: command)
            let contents = ProcessRunner.run(executable: commandURL, arguments: [url.path, "-o", "/dev/stdout"])
            if let out = contents.out, !out.isEmpty {
                self.outputTextView.string = "Importing \(url.pathExtension.uppercased()) Image...\n"
                self.codeEditorTextView.insertCode(out)
            }
            self.outputTextView.string = contents.err ?? ""
        }
    }
    
    @IBAction func importAdafruitGFXFont(_ sender: Any) {
        let openPanel = NSOpenPanel()
        let extensions = ["h"]
        let contentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        
        openPanel.allowedContentTypes = contentTypes
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        openPanel.begin { result in
            guard result == .OK, let url = openPanel.url else { return }
            
            let contents = ProcessRunner.run(executable: ToolchainPaths.bin.appendingPathComponent("font"), arguments: [url.path, "-o", "/dev/stdout"])
            if let out = contents.out, !out.isEmpty {
                self.outputTextView.string = "Importing Adafruit GFX Font...\n"
                self.codeEditorTextView.insertCode(contents.out ?? "")
            }
            self.outputTextView.string = contents.err ?? ""
        }
    }
    
    @IBAction func importCode(_ sender: Any) {
        let openPanel = NSOpenPanel()
        let contentTypes = ["prgm", "ppl", "prgm+", "ppl+", "pp"].compactMap { UTType(filenameExtension: $0) }
        
        openPanel.allowedContentTypes = contentTypes
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        openPanel.begin { result in
            guard result == .OK, let url = openPanel.url else { return }
            
            if let contents = HPServices.loadHPPrgm(at: url) {
                self.codeEditorTextView.insertCode(self.codeEditorTextView.removePragma(contents))
            }
        }
    }
    
    @IBAction func insertTemplate(_ sender: Any) {
        func traceMenuItem(_ item: NSMenuItem) -> String {
            if let parentMenu = item.menu {
                print("Item '\(item.title)' is in menu: \(parentMenu.title)")
                
                // Try to find the parent NSMenuItem that links to this menu
                for superitem in parentMenu.supermenu?.items ?? [] {
                    if superitem.submenu == parentMenu {
                        return superitem.title
                    }
                }
            }
            return ""
        }
        
        guard let menuItem = sender as? NSMenuItem else { return }
        let url = Bundle.main.bundleURL
            .appendingPathComponent(templatesBasePath)
            .appendingPathComponent(traceMenuItem(menuItem))
            .appendingPathComponent(menuItem.title)
            .appendingPathExtension("prgm")
        
        
        
        if let contents = HPServices.loadHPPrgm(at: url) {
            codeEditorTextView.insertCode(contents)
        }
    }
    
    
    @IBAction func cleanBuildFolder(_ sender: Any) {
        guard let projectName = projectName, let parentURL = parentURL else {
            return
        }
        
        outputTextView.string = "Cleaning...\n"
        
        let files: [URL] = [
            parentURL.appendingPathComponent("\(projectName).hpprgm"),
            parentURL.appendingPathComponent("\(projectName).hpappdir/\(projectName).hpappprgm"),
            parentURL.appendingPathComponent("\(projectName).hpappdir.zip")
        ]
        
        for file in files {
            do {
                try FileManager.default.removeItem(at: file)
                outputTextView.string += ("✅ File removed: \(file.lastPathComponent)\n")
            } catch {
                outputTextView.string += ("⚠️ No file found: \(file.lastPathComponent)\n")
            }
        }
    }
    
    @IBAction func showBuildFolderInFinder(_ sender: Any) {
        guard let currentURL = currentURL else {
            return
        }
        currentURL.revealInFinder()
    }
    
    @IBAction func showCalculatorFolderInFinder(_ sender: Any) {
        let calculator = UserDefaults.standard.object(forKey: "calculator") as? String ?? "Prime"
        guard let url = HPServices.hpPrimeDirectory(forUser: calculator) else {
            return
        }
        url.revealInFinder()
    }
    
    @IBAction func reformatCode(_ sender: Any) {
        if let _ = currentURL {
            saveDocument()
        } else {
            saveDocumentAs()
        }
        
        guard let currentURL = currentURL else {
            return
        }
        
        
        let contents = ProcessRunner.run(executable: ToolchainPaths.bin.appendingPathComponent("ppl+"), arguments: [currentURL.path, "--reformat", "-o", "/dev/stdout"])
        if let out = contents.out, !out.isEmpty {
            codeEditorTextView.string = out
        }
        self.outputTextView.string = contents.err ?? ""
    }
    
    @IBAction func toggleSmartSubtitution(_ sender: NSMenuItem) {
        codeEditorTextView.smartSubtitution = !codeEditorTextView.smartSubtitution
        sender.state = codeEditorTextView.smartSubtitution ? .on : .off
    }
    
    
    @IBAction func toggleOutput(_ sender: NSButton) {
        let shouldShow = outputScrollView.isHidden
        
        if shouldShow {
            outputScrollView.isHidden = false
            sender.contentTintColor = .systemBlue
        } else {
            outputScrollView.isHidden = true
            sender.contentTintColor = .systemGray
        }
    }
    
    // MARK: - Validation for Toolbar Items
    
    internal func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.action {
        case #selector(build(_:)), #selector(run(_:)):
            if let _ = projectURL  {
                return true
            }
            return false
            
         default :
            break
        }
        return true
    }
    
    // MARK: - Validation for Menu Items
    
    internal func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let ext = (currentURL != nil) ? currentURL!.pathExtension.lowercased() : ""
    
        switch menuItem.action {
        case #selector(reformatCode(_:)):
            if let _ = currentURL, ext == "prgm" || ext == "ppl" {
                return true
            }
            return false
            
        case #selector(installHPPrgmFileToCalculator(_:)):
            menuItem.title = "Install Program"
            if let projectName = projectName {
                if HPServices.hpPrgmIsInstalled(named: projectName) {
                    menuItem.title = "Update Program"
                }
            }
            if let parentURL = parentURL, let projectName = projectName {
                return HPServices.hpPrgmExists(atPath: parentURL.path, named: projectName)
            }
            return false
            
        case #selector(installHPAppDirectoryToCalculator(_:)):
            menuItem.title = "Install Application"
            if let projectName = projectName {
                if HPServices.hpAppDirectoryIsInstalled(named: projectName) {
                    menuItem.title = "Update Application"
                }
            }
            if let parentURL = parentURL, let projectName = projectName {
                return HPServices.hpAppDirIsComplete(atPath: parentURL.path, named: projectName)
            }
            return false
            
        case #selector(exportAsHPPrgm(_:)):
            if let _ = currentURL, ext == "prgm" || ext == "prgm+" || ext == "ppl" || ext == "ppl+" || ext == "pp"  {
                return true
            }
            return false
            
        case #selector(exportAsPrgm(_:)), #selector(convert(_:)):
            if let _ = currentURL, ext == "prgm+" || ext == "ppl+" || ext == "pp" {
                return true
            }
            return false
            
        case #selector(exportAsArchive(_:)), #selector(archiveWithoutBuilding(_:)):
            if let projectName = projectName, let parentURL = parentURL {
                return HPServices.hpAppDirIsComplete(atPath: parentURL.path, named: projectName)
            }
            return false
            
        case #selector(run(_:)), #selector(archive(_:)), #selector(build(_:)), #selector(buildForRunning(_:)), #selector(buildForArchiving(_:)):
            if let _ = projectURL  {
                return true
            }
            return false
            
        case #selector(importCode(_:)):
            return true
            
        case #selector(insertTemplate(_:)), #selector(importImage(_:)), #selector(importAdafruitGFXFont(_:)):
            if ext == "prgm" || ext == "prgm+" || ext == "hpprgm" || ext == "hpappprgm" || ext == "ppl" || ext == "ppl+" || ext == "pp" {
                return true
            }
            return false
            
        case #selector(revertDocumentToSaved(_:)):
            return documentIsModified
            
        case #selector(cleanBuildFolder(_:)):
            if let _ = projectURL {
                return true
            }
            return false
            
        case #selector(showBuildFolderInFinder(_:)):
            if let _ = projectURL {
                return true
            }
            return false
            
        default:
            break
        }
        
        return true
    }
}

