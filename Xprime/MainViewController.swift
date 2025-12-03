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

final class MainViewController: NSViewController, NSTextViewDelegate, NSToolbarItemValidation, NSMenuItemValidation {
    @IBOutlet weak var toolbar: NSToolbar!
    @IBOutlet weak var icon: NSImageView!
    
    private var currentURL: URL?
    private var parentURL: URL? {
        guard let url = currentURL else { return nil }
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path, isDirectory: &isDir) && isDir.boolValue {
            return url.deletingLastPathComponent()
        }
        return nil
    }
    private var applicationName: String? {
        guard let currentURL = currentURL else { return nil }
        if currentURL.pathComponents.count <= 1 {
            return nil
        }
        let projectName = currentURL
            .deletingLastPathComponent()
            .lastPathComponent
        
        return projectName
    }
    
    @IBOutlet var codeEditorTextView: CodeEditorTextView!
    @IBOutlet var outputTextView: NSTextView!
    @IBOutlet var statusTextLabel: NSTextField!
    @IBOutlet var outputScrollView: NSScrollView!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        codeEditorTextView.delegate = self
        
        // Add the Line Number Ruler
        if let scrollView = codeEditorTextView.enclosingScrollView {
            let ruler = LineNumberRulerView(textView: codeEditorTextView)
            scrollView.verticalRulerView = ruler
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
            
            // Force layout to avoid invisible window
            scrollView.tile()
        }
        
        
        if let url = Bundle.main.resourceURL?.appendingPathComponent("Untitled.prgm+") {
            codeEditorTextView.string = HP.loadHPPrgm(at: url) ?? ""
        }
        
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
        
       
        if let window = self.view.window {
            window.representedURL = Bundle.main.resourceURL?.appendingPathComponent("Untitled.prgm+")
            window.title = "Untitled (UNSAVED)"
            openDocument(withContentsOf: window.representedURL!)
            currentURL = nil
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
    
    
    // MARK: - Helper Functions
    
    private func updateDocumentIconButtonImage() {
        guard let url = self.currentURL else {
            return
        }
        if let window = self.view.window {
            window.title = url.lastPathComponent
            
            window.representedURL = URL(fileURLWithPath: url.path)
            if let iconButton = window.standardWindowButton(.documentIconButton) {
                if url.pathExtension == "prgm+" {
                    iconButton.image = NSImage(named: "pplplus")
                } else {
                    iconButton.image = NSImage(named: "ppl")
                }
                iconButton.isHidden = false
            }
        }
    }
    
    private func openDocument(withContentsOf url: URL) {
        guard let contents = HP.loadHPPrgm(at: url) else { return }
        
        currentURL = url
        codeEditorTextView.string = contents
        
        guard let name = applicationName else { return }
        guard let parentURL = parentURL else { return }
        let folderURL = parentURL.appendingPathComponent("\(name).hpappdir")
        
        let ext = url.pathExtension.lowercased()
        
        if ext == "prgm+" || ext == "ppl+" {
            self.codeEditorTextView.loadGrammar(at: Bundle.main.url(forResource: "Prime Plus", withExtension: "xpgrammar")!)
        }
        
        if ext == "prgm" || ext == "ppl" || ext == "hpprgm" || ext == "hpappprgm" {
            self.codeEditorTextView.loadGrammar(at: Bundle.main.url(forResource: "Prime", withExtension: "xpgrammar")!)
        }
        
        if ext == "py" {
            self.codeEditorTextView.loadGrammar(at: Bundle.main.url(forResource: "Python", withExtension: "xpgrammar")!)
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
        
        icon.image = NSImage(contentsOf: Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/icon.png"))
    }
    
    @discardableResult
    private func processRequires(in text: String) -> (cleaned: String, requiredFiles: [String]) {
        let pattern = #"#require\s*"([^"]+)""#
        let regex = try! NSRegularExpression(pattern: pattern)

        var requiredFiles: [String] = []
        var cleanedText = text

        // Find matches
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches.reversed() {
            // Extract filename
            if let range = Range(match.range(at: 1), in: text) {
                requiredFiles.append(String(text[range]))
            }

            // Remove entire #require line from the output
            if let fullRange = Range(match.range, in: cleanedText) {
                cleanedText.removeSubrange(fullRange)
            }
        }

        return (cleanedText, requiredFiles)
    }
    
    // MARK: - Interface Builder Action Handlers
    
    @IBAction func newProject(_ sender: Any) {
        let savePanel = NSSavePanel()
        let extensions = ["prgm+"]
        let contentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        
        savePanel.allowedContentTypes = contentTypes
        savePanel.nameFieldStringValue = "Untitled"
        
        savePanel.begin { result in
            guard result == .OK, let url = savePanel.url else { return }

            do {
                let projectName = url.deletingPathExtension().lastPathComponent
                
                let dirURL = url
                    .deletingLastPathComponent()
                    .appendingPathComponent(projectName)
                
                try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: false)
                
                let fileURL = dirURL.appendingPathComponent(projectName + ".prgm+")
                try HP.savePrgm(at: fileURL, content: self.codeEditorTextView.string)
                self.currentURL = fileURL
                self.documentIsModified = false
                
                XprimeProject.save(to: dirURL, named: projectName)
                FileManager.default.changeCurrentDirectoryPath(dirURL.path)
                
            } catch {
                let alert = NSAlert()
                alert.messageText = "Error"
                alert.informativeText = "Failed to save project: \(error)"
                alert.runModal()
            }
        }
    }
    
    @IBAction func newDocument(_ sender: Any) {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("Untitled.prgm+") {
            codeEditorTextView.string = HP.loadHPPrgm(at: url) ?? ""
            currentURL = nil
        }
    }
    
    @IBAction func openDocument(_ sender: Any) {
        let openPanel = NSOpenPanel()
        let extensions = ["py", "prgm", "prgm+", "hpprgm", "hpappprgm", "ppl", "ppl+"]
        let contentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        
        openPanel.allowedContentTypes = contentTypes
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        openPanel.begin { result in
            guard result == .OK, let url = openPanel.url else { return }
            self.openDocument(withContentsOf: url)
            if let applicationName = self.applicationName {
                XprimeProject.load(at: url.deletingLastPathComponent(), named: applicationName)
            }
        }
    }
    
    @IBAction func saveDocument(_ sender: Any) {
        guard let url = currentURL else {
            saveDocumentAs(sender)
            return
        }
        
        if url.pathExtension.lowercased() == "hpprgm" || url.pathExtension.lowercased()  == "hpappprgm" {
            saveDocumentAs(sender)
            return
        }
        
        do {
            try HP.savePrgm(at: url, content: codeEditorTextView.string)
            currentURL = url
            self.documentIsModified = false
            if let applicationName = self.applicationName {
                XprimeProject.save(to: url.deletingLastPathComponent(), named: applicationName)
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Failed to save file: \(error)"
            alert.runModal()
        }
    }
    
    @IBAction func saveDocumentAs(_ sender: Any) {
        let savePanel = NSSavePanel()
        let extensions = ["py", "prgm", "prgm+"]
        let contentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        
        savePanel.allowedContentTypes = contentTypes
        savePanel.nameFieldStringValue = "Untitled.prgm+"
        
        savePanel.begin { result in
            guard result == .OK, let url = savePanel.url else { return }

            do {
                try HP.savePrgm(at: url, content: self.codeEditorTextView.string)
                self.currentURL = url
                self.documentIsModified = false
                
                if let applicationName = self.applicationName {
                    XprimeProject.save(to: url.deletingLastPathComponent(), named: applicationName)
                }
                
            } catch {
                let alert = NSAlert()
                alert.messageText = "Error"
                alert.informativeText = "Failed to save file: \(error)"
                alert.runModal()
            }
        }
    }
    
    
    @IBAction func exportAsHPPrgm(_ sender: Any) {
        saveDocument(sender)
        
        guard let currentURL = currentURL,
           FileManager.default.fileExists(atPath: currentURL.path) else
        {
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = ["hpprgm"].compactMap { UTType(filenameExtension: $0) }
        savePanel.nameFieldStringValue = currentURL.deletingPathExtension().lastPathComponent + ".hpprgm"
        savePanel.begin { result in
            guard result == .OK, let outURL = savePanel.url else { return }
            
            let result = HP.preProccess(at: currentURL, to: outURL)
            if let out = result.out, !out.isEmpty {
                self.outputTextView.string = out
            }
            self.outputTextView.string = result.err ?? ""
        }
    }
    
    @IBAction func exportAsPrgm(_ sender: Any) {
        saveDocument(sender)
        
        guard let currentURL = currentURL,
           FileManager.default.fileExists(atPath: currentURL.path) else
        {
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = ["prgm"].compactMap { UTType(filenameExtension: $0) }
        savePanel.nameFieldStringValue = currentURL.deletingPathExtension().lastPathComponent + ".prgm"
        savePanel.begin { result in
            guard result == .OK, let outURL = savePanel.url else { return }
            
            
            let result = HP.preProccess(at: currentURL, to: outURL)
            if let out = result.out, !out.isEmpty {
                self.outputTextView.string = out
            }
            self.outputTextView.string = result.err ?? ""
        }
    }
    
    @IBAction func exportAsArchive(_ sender: Any) {
        guard let parentURL = parentURL, let name = applicationName else { return }
        
        
        let savePanel = NSSavePanel()
        let extensions = ["hpappdir.zip"]
        let contentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        
        savePanel.allowedContentTypes = contentTypes
        savePanel.nameFieldStringValue = "Untitled"
        
        savePanel.begin { result in
            guard result == .OK, let url = savePanel.url else { return }

            var destination = url
            while !destination.pathExtension.isEmpty {
                destination.deletePathExtension()
            }
            destination = destination.appendingPathExtension("hpappdir.zip")
            
            let contents = HP.archiveHPAppDirectory(at: parentURL, named: name, to: destination)
                if let out = contents.out, !out.isEmpty {
                    self.outputTextView.string = out
                    return
                }
                let alert = NSAlert()
                alert.messageText = "Error"
                alert.informativeText = "Failed to save file: \(url.lastPathComponent)"
                alert.runModal()
        }
    }
    
    @IBAction func revertDocumentToSaved(_ sender: Any) {
        if let contents = HP.loadHPPrgm(at: currentURL!) {
            codeEditorTextView.string = contents
            self.documentIsModified = false
            updateDocumentIconButtonImage()
        }
    }
    

    @IBAction func run(_ sender: Any) {
        guard let parentURL = parentURL, let name = applicationName else {
            return
        }
        
        let result = processRequires(in: codeEditorTextView.string)

        let baseURL = HP.sdkURL
            .appendingPathComponent("hpprgm")
        for file in result.requiredFiles {
            do {
                try HP.installHPPrgm(at: baseURL
                    .appendingPathComponent(file)
                    .appendingPathExtension("hpprgm"))
                outputTextView.string += "Installed: \(file)\n"
            } catch {
                outputTextView.string += "Error installing \(file).hpprgm: \(error)"
            }
        }
        
        build(sender)
        
        if HP.hpPrgmExists(atPath: parentURL.path, named: name) {
            installHPPrgmFileToCalculator(sender)
            HP.launchVirtualCalculator()
        }
    }
    
    @IBAction func archive(_ sender: Any) {
        buildForArchiving(sender)
        archiveWithoutBuilding(sender)
    }
    
    @IBAction func buildForRunning(_ sender: Any) {
        guard let parentURL = parentURL, let name = applicationName else {
            return
        }
        
        let result = processRequires(in: codeEditorTextView.string)

        let baseURL = HP.sdkURL
            .appendingPathComponent("hpprgm")
        
        for file in result.requiredFiles {
            do {
                try HP.installHPPrgm(at: baseURL
                    .appendingPathComponent(file)
                    .appendingPathExtension("hpprgm"))
                outputTextView.string += "Installed: \(file)\n"
            } catch {
                outputTextView.string += "Error installing \(file).hpprgm: \(error)"
            }
        }
        
        build(sender)
        
        if HP.hpPrgmExists(atPath: parentURL.path, named: name) {
            installHPPrgmFileToCalculator(sender)
        }
    }
    
    
    @IBAction func buildForArchiving(_ sender: Any) {
        guard
            let currentURL = currentURL,
                let name = applicationName ,
                let parentURL = parentURL
        else { return }

        saveDocument(sender)
        
        do {
            try HP.restoreMissingAppFiles(at: parentURL, named: name)
        } catch {
            outputTextView.string = "Failed to build for archiving: \(error)"
            return
        }
        
        let result = HP.preProccess(at: currentURL, to: parentURL
            .appendingPathComponent(name)
            .appendingPathExtension("hpappdir")
            .appendingPathComponent(name)
            .appendingPathExtension("hpappprgm")
        )
        outputTextView.string = result.err ?? ""
    }
    
    
    @IBAction func installHPPrgmFileToCalculator(_ sender: Any) {
        guard let name = applicationName, let parentURL = parentURL else { return }
        
        let programURL = parentURL
            .appendingPathComponent(name)
            .appendingPathExtension("hpprgm")
        outputTextView.string = "Installing: \(programURL.lastPathComponent)\n"
        do {
            try HP.installHPPrgm(at: programURL, forUser: AppSettings.calculatorName)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Installing file: \(error)"
            alert.runModal()
            return
        }
    }
    
    @IBAction func installHPAppDirectoryToCalculator(_ sender: Any) {
        guard let name = applicationName, let parentURL = parentURL else { return }

        let appDirURL = parentURL
            .appendingPathComponent(name)
            .appendingPathExtension("hpappdir")
        outputTextView.string = "Installing: \(appDirURL.lastPathComponent)\n"
        do {
            try HP.installHPAppDirectory(at: appDirURL, forUser: AppSettings.calculatorName)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Installing file: \(error)"
            alert.runModal()
            return
        }
    }
    
    
    
    @IBAction func archiveWithoutBuilding(_ sender: Any) {
        guard let name = applicationName , let parentURL = parentURL else { return }
       
        let result = HP.archiveHPAppDirectory(at: parentURL, named: name)
        
        if let out = result.out, !out.isEmpty {
            self.outputTextView.string = out
        }
        self.outputTextView.string = result.err ?? ""
    }
    
    @IBAction func convert(_ sender: Any) {
        guard let currentURL = currentURL else { return }
    
        let result = HP.preProccess(at: currentURL, to: currentURL
            .deletingPathExtension()
            .appendingPathExtension("prgm")
        )
        if let out = result.out, !out.isEmpty {
            outputTextView.string = "Converting...\n"
        }
        outputTextView.string = result.err ?? ""
        
        openDocument(withContentsOf: currentURL
            .deletingPathExtension()
            .appendingPathExtension("prgm"))
    }
    
    @IBAction func build(_ sender: Any) {
        guard let currentURL = currentURL else {
            return
        }

        saveDocument(sender)

        let result = HP.preProccess(at: currentURL, to: currentURL
            .deletingPathExtension()
            .appendingPathExtension("hpprgm")
        )
        
        outputTextView.string = result.err ?? ""
    }
    
    
    @IBAction func importImage(_ sender: Any) {
        let openPanel = NSOpenPanel()
        let extensions = ["bmp", "png", "pbm"]
        let contentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        
        openPanel.allowedContentTypes = contentTypes
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        openPanel.begin { result in
            guard result == .OK, let url = openPanel.url else { return }
            let command = HP.sdkURL
                .appendingPathComponent("bin")
                .appendingPathComponent("grob")
                .path
            
            let contents = CommandLineTool.execute(command, arguments: [url.path, "-o", "/dev/stdout"])
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
            
            let command = HP.sdkURL
                .appendingPathComponent("bin")
                .appendingPathComponent("pplfont")
                .path
            
            let contents = CommandLineTool.execute(command, arguments: [url.path, "-o", "/dev/stdout", "--ppl"])
            if let out = contents.out, !out.isEmpty {
                self.outputTextView.string = "Importing Adafruit GFX Font...\n"
                self.codeEditorTextView.insertCode(contents.out ?? "")
            }
            self.outputTextView.string = contents.err ?? ""
        }
    }
    
    @IBAction func importCode(_ sender: Any) {
        let openPanel = NSOpenPanel()
        var extensions = ["prgm"]
        if let currentURL = currentURL, currentURL.pathExtension.lowercased() == "prgm+" {
            extensions.append("prgm+")
        }
        let contentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        
        openPanel.allowedContentTypes = contentTypes
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        openPanel.begin { result in
            guard result == .OK, let url = openPanel.url else { return }
            
            if let contents = HP.loadHPPrgm(at: url) {
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
        
        
        
        if let contents = HP.loadHPPrgm(at: url) {
            codeEditorTextView.insertCode(contents)
        }
    }
    
    
   
    
    @IBAction func cleanBuildFolder(_ sender: Any) {
        guard let name = applicationName, let parentURL = parentURL else {
            return
        }
        
        outputTextView.string = "Cleaning...\n"
        
        let files: [URL] = [
            parentURL.appendingPathComponent("\(name).hpprgm"),
            parentURL.appendingPathComponent("\(name).hpappdir/\(name).hpappprgm"),
            parentURL.appendingPathComponent("\(name).hpappdir.zip")
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
        guard let url = HP.hpPrimeDirectory(forUser: AppSettings.calculatorName) else {
            return
        }
        url.revealInFinder()
    }
    
    @IBAction func reformatCode(_ sender: Any) {
        guard let url = currentURL,
           FileManager.default.fileExists(atPath: url.path) else
        {
            return
        }
        
        saveDocument(sender)
        
        let command = HP.sdkURL
            .appendingPathComponent("bin")
            .appendingPathComponent("pplref")
            .path
        
        let contents = CommandLineTool.execute(command, arguments: [url.path, "-o", "/dev/stdout"])
        if let out = contents.out, !out.isEmpty {
            codeEditorTextView.string = out
        }
        self.outputTextView.string = contents.err ?? ""
    }
    
    @IBAction func toggleSmartSubtitution(_ sender: NSMenuItem) {
        codeEditorTextView.smartSubtitution = !codeEditorTextView.smartSubtitution
        sender.state = codeEditorTextView.smartSubtitution ? .on : .off
    }
    
    
    // MARK: - Validation for Toolbar Items
    
    internal func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        let ext = (currentURL != nil) ? currentURL!.pathExtension.lowercased() : ""
    
        switch item.action {
        case #selector(build(_:)), #selector(run(_:)), #selector(exportAsHPPrgm(_:)):
            if let _ = currentURL, ext == "prgm" || ext == "prgm+" || ext == "ppl" || ext == "ppl+" {
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
            
        case #selector(exportAsPrgm(_:)), #selector(convert(_:)):
            if let _ = currentURL, ext == "prgm+" || ext == "ppl+" {
                return true
            }
            return false
            
        case #selector(installHPPrgmFileToCalculator(_:)):
            menuItem.title = "Install Program"
            if let name = applicationName {
                if HP.hpPrgmIsInstalled(named: name) {
                    menuItem.title = "Update Program"
                }
            }
            if let parentURL = parentURL, let name = applicationName {
                return HP.hpPrgmExists(atPath: parentURL.path, named: name)
            }
            return false
            
        case #selector(installHPAppDirectoryToCalculator(_:)):
            menuItem.title = "Install Application"
            if let name = applicationName {
                if HP.hpAppDirectoryIsInstalled(named: name) {
                    menuItem.title = "Update Application"
                }
            }
            if let parentURL = parentURL, let name = applicationName {
                return HP.hpAppDirIsComplete(atPath: parentURL.path, named: name)
            }
            return false
            
        case
            #selector(exportAsHPPrgm(_:)):
            
            if let _ = currentURL, ext == "prgm" || ext == "prgm+" || ext == "ppl" || ext == "ppl+"  {
                return true
            }
            return false
        
        case
            #selector(run(_:)),
            #selector(archive(_:)),
            #selector(buildForRunning(_:)),
            #selector(buildForArchiving(_:)),
            #selector(build(_:)):
            
            if let currentURL = currentURL, let name = applicationName,
                    ext == "prgm" || ext == "prgm+" || ext == "ppl" || ext == "ppl+"  {
                return currentURL.deletingPathExtension().lastPathComponent == name
            }
            return false
            
        case
            #selector(insertTemplate(_:)),
            #selector(importCode(_:)),
            #selector(importImage(_:)),
            #selector(importAdafruitGFXFont(_:)):
            
            if ext == "prgm" || ext == "prgm+" || ext == "hpprgm" || ext == "hpappprgm" || ext == "ppl" || ext == "ppl+" || ext.isEmpty {
                return true
            }
            return false
            
        case #selector(revertDocumentToSaved(_:)):
            return documentIsModified
            
        case #selector(cleanBuildFolder(_:)):
            if let _ = currentURL, let name = applicationName, let parentURL = parentURL {
                return parentURL.appendingPathComponent("\(name).hpappdir").isDirectory
            }
            return false
            
        case
            #selector(exportAsArchive(_:)),
            #selector(archiveWithoutBuilding(_:)):
            
            if let _ = currentURL, let name = applicationName, let parentURL = parentURL {
                return HP.hpAppDirIsComplete(atPath: parentURL.path, named: name)
            }
            return false
            
            
        case #selector(showBuildFolderInFinder(_:)):
            if let _ = currentURL, ext == "prgm" || ext == "prgm+" || ext == "ppl" || ext == "ppl+" {
                return true
            }
            return false
            
      
        default:
            break
        }
        
        return true
    }
}

