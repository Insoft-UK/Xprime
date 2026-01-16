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

extension MainViewController: NSWindowRestoration {
    static func restoreWindow(withIdentifier identifier: NSUserInterfaceItemIdentifier, state: NSCoder, completionHandler: @escaping (NSWindow?, Error?) -> Void) {
        // Restore your window here if needed
        completionHandler(nil, nil) // or provide restored window
    }
}

final class MainViewController: NSViewController, NSTextViewDelegate, NSToolbarItemValidation, NSMenuItemValidation, NSSplitViewDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var splitView: NSSplitView!
    @IBOutlet var codeEditorTextView: CodeEditorTextView!
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var outputTextView: OutputTextView!
    @IBOutlet var outputScrollView: NSScrollView!
    @IBOutlet private weak var outputButton: NSButton!
    @IBOutlet private weak var clearOutputButton: NSButton!
    @IBOutlet private weak var baseApplicationPopUpButton: NSPopUpButton!
    
    // MARK: - Managers
    private var documentManager: DocumentManager!
    private var projectManager: ProjectManager!
    private var themeManager: ThemeManager!
    private var updateManager: UpdateManager!
    private var statusManager: StatusManager!
    
    // MARK: - Outlets
    @IBOutlet weak var icon: NSImageView!
    
    
    // MARK: - Class Private Properties
    
    private var gutterView: LineNumberGutterView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Managers that don’t depend on window
        documentManager = DocumentManager(editor: codeEditorTextView)
        documentManager.delegate = self
        projectManager = ProjectManager(documentManager: documentManager)
        statusManager = StatusManager(editor: codeEditorTextView, statusLabel: statusLabel)
        
        setupObservers()
        setupEditor()
        
        if let menu = NSApp.mainMenu {
            populateThemesMenu(menu: menu)
            populateGrammarMenu(menu: menu)
        }
        populateBaseApplicationMenu()
    }
    
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // Now view.window exists
        themeManager = ThemeManager(editor: codeEditorTextView,
                                    statusLabel: statusLabel,
                                    outputButtons: [outputButton, clearOutputButton],
                                    window: view.window)
        updateManager = UpdateManager(presenterWindow: view.window)
        setupWindowAppearance()
        documentManager.openLastOrUntitled()
        themeManager.applySavedTheme()
        registerWindowFocusObservers()
        refreshBaseApplicationMenu()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupEditor() {
        codeEditorTextView.delegate = self
        splitView.delegate = self
        
        // Add the Line Number Ruler
        if let scrollView = codeEditorTextView.enclosingScrollView {
            gutterView = LineNumberGutterView(textView: codeEditorTextView)
            
            scrollView.verticalRulerView = gutterView
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
            // Force layout to avoid invisible window
            scrollView.tile()
        }
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            statusManager!,
            selector: #selector(StatusManager.textDidChange(_:)),
            name: NSTextView.didChangeSelectionNotification,
            object: codeEditorTextView
        )
    }
    
    private func setupWindowAppearance() {
        guard let window = view.window else { return }
        window.isOpaque = false
        window.titlebarAppearsTransparent = true
        window.styleMask = [.resizable, .titled, .miniaturizable]
        window.hasShadow = true
    }
    
    // MARK: - Observers

    
    func textDidChange(_ notification: Notification) {
#if Debug
        print("Text did change!")
#endif
        documentManager.documentIsModified = true
    }
    
    private func registerWindowFocusObservers() {
        guard let window = view.window else { return }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: window
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: window
        )
    }
    
    @objc private func windowDidBecomeKey() {
        // window gained focus
#if Debug
        print("Window gained focus")
#endif
        refreshQuickOpenToolbar()
        projectManager.saveProject()
        refreshProjectIconImage()
        refreshBaseApplicationMenu()
    }
    
    @objc private func windowDidResignKey() {
        // window lost focus
#if Debug
        print("Window lost focus")
#endif
    }
    
    // MARK: -
    
    private func populateThemesMenu(menu: NSMenu) {
        guard let resourceURLs = Bundle.main.urls(
            forResourcesWithExtension: "xpcolortheme",
            subdirectory: "Themes"
        ) else {
#if Debug
            print("⚠️ No .xpcolortheme files found.")
#endif
            return
        }
        
        let sortedURLs = resourceURLs
            .filter { !$0.lastPathComponent.hasPrefix(".") }
            .sorted {
                $0.deletingPathExtension().lastPathComponent
                    .localizedCaseInsensitiveCompare(
                        $1.deletingPathExtension().lastPathComponent
                    ) == .orderedAscending
            }
        
        for fileURL in sortedURLs {
            let name = fileURL.deletingPathExtension().lastPathComponent
            
            let menuItem = NSMenuItem(
                title: name,
                action: #selector(handleThemeSelection(_:)),
                keyEquivalent: ""
            )
            menuItem.representedObject = fileURL
            menuItem.target = self
            
            menu.item(withTitle: "Editor")?
                .submenu?
                .item(withTitle: "Theme")?
                .submenu?
                .addItem(menuItem)
        }
    }

    private func populateGrammarMenu(menu: NSMenu) {
        guard let resourceURLs = Bundle.main.urls(forResourcesWithExtension: "xpgrammar", subdirectory: "Grammars") else {
#if Debug
            print("⚠️ No .xpgrammar files found.")
#endif
            return
        }
        
        for fileURL in resourceURLs {
            let name = fileURL.deletingPathExtension().lastPathComponent
            if name.first == "." { continue }
            
            let menuItem = NSMenuItem(title: name, action: #selector(handleGrammarSelection(_:)), keyEquivalent: "")
            menuItem.representedObject = fileURL
            menuItem.target = self  // or another target if needed
            menu.item(withTitle: "Editor")?.submenu?.item(withTitle: "Grammar")?.submenu?.addItem(menuItem)
        }
    }
    
    private func populateBaseApplicationMenu() {
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
        let baseApplicationName = projectManager.baseApplicationName
        for application in applications {
            let item = NSMenuItem(
                title: application,
                action: #selector(handleBaseApplicationSelection(_:)),
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
            item.state = baseApplicationName == application ? .on: .off
            menu.addItem(item)
        }

        baseApplicationPopUpButton.menu = menu
        
        baseApplicationPopUpButton.isEnabled = documentManager.currentDocumentURL != nil
    }
    
    private func refreshBaseApplicationMenu() {
        guard let menu = baseApplicationPopUpButton.menu else { return }
        let baseApplicationName = projectManager.baseApplicationName
        for item in menu.items {
            if item.title == baseApplicationName {
                item.state = .on
                baseApplicationPopUpButton.select(item)
            } else {
                item.state = .off
            }
        }
        baseApplicationPopUpButton.isEnabled = documentManager.currentDocumentURL != nil
    }
    
    // MARK: - Base Application Action Handler
    @objc func handleBaseApplicationSelection(_ sender: NSMenuItem) {
        guard let currentDocumentURL = documentManager.currentDocumentURL else { return }
        
        let name = currentDocumentURL.deletingLastPathComponent().lastPathComponent
        let directoryURL = currentDocumentURL.deletingLastPathComponent()
        
        if directoryURL.appendingPathComponent("\(name).hpappdir").isDirectory {
            outputTextView.appendTextAndScroll("⚠️ Changing base application \"\(projectManager.baseApplicationName)\" to \"\(sender.title)\".\n")
        } else {
            outputTextView.appendTextAndScroll("🔨 Create application directory.\n")
        }
        
        try? HPServices.resetHPAppContents(at: directoryURL, named: name, fromBaseApplicationNamed: sender.title)
        outputTextView.appendTextAndScroll("Base application is \"\(projectManager.baseApplicationName)\"\n")
        refreshProjectIconImage()
    }
    
    // MARK: - Theme & Grammar Action Handlers
    
    
    @objc func handleThemeSelection(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.title, forKey: "preferredTheme")
        themeManager.applySavedTheme()
    }
    
    @objc func handleGrammarSelection(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.title, forKey: "preferredGrammar")
        codeEditorTextView.loadGrammar(named: sender.title)
    }
    
    
    // MARK: - Helper Functions
    
    private func updateWindowDocumentIcon() {
        guard
            let url = documentManager.currentDocumentURL,
            url.isFileURL,
            let window = view.window
        else { return }
        
        // 1️⃣ Force document-style titlebar
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = true
        
        // 2️⃣ Set document identity
        window.title = url.deletingLastPathComponent().lastPathComponent
        window.representedURL = url
        
        // 3️⃣ Re-apply icon AFTER AppKit finishes layout
        DispatchQueue.main.async {
            window.standardWindowButton(.documentIconButton)?.image = self.icon.image
        }
    }

    private func loadAppropriateGrammar(forType fileExtension: String) {
        let grammar:[String : [String]] = [
            "Prime Plus": ["prgm+", "ppl+"],
            "Prime": ["prgm", "ppl", "hpprgm", "hpappprgm"],
            "Python": ["py"]
        ]
        
        for (grammarName, ext) in grammar where ext.contains(fileExtension.lowercased()) {
            codeEditorTextView.loadGrammar(named: grammarName)
            UserDefaults.standard.set(grammarName, forKey: "preferredGrammar")
            return
        }
    }
    
    private func refreshProjectIconImage() {
        guard let currentDocumentURL = documentManager.currentDocumentURL else { return }
        
        let name = currentDocumentURL
            .deletingLastPathComponent()
            .lastPathComponent
        
        let fm = FileManager.default
        let iconFileName = "icon.png"
        
        let urlsToCheck: [URL] = [
            currentDocumentURL
                .deletingLastPathComponent()
                .appendingPathComponent("\(name).hpappdir")
                .appendingPathComponent(iconFileName),
            currentDocumentURL
                .deletingLastPathComponent()
                .appendingPathComponent(iconFileName),
            Bundle.main.url(
                forResource: "icon",
                withExtension: "png",
                subdirectory: "Developer/Library/Xprime/Templates/Application Template"
            )!
        ]
        
        if let existingURL = urlsToCheck.first(where: { fm.fileExists(atPath: $0.path) }) {
            let targetSize = NSSize(width: 38, height: 38)
            
            if let image = NSImage(contentsOf: existingURL) {
                image.size = targetSize
                icon.image = image
            }
        }
        
        updateWindowDocumentIcon()
    }
    
    private func buildForArchive() {
        guard
            let currentDirectoryURL = projectManager.currentDirectoryURL
        else { return }
        
        let sourceURL: URL
        if FileManager.default.fileExists(
            atPath: currentDirectoryURL
                .appendingPathComponent("main.prgm+")
                .path
        ) {
            sourceURL = currentDirectoryURL
                .appendingPathComponent("main.prgm+")
        } else {
            // Fall back to v26.0
            sourceURL = currentDirectoryURL
                .appendingPathComponent("\(projectManager.projectName).prgm+")
        }
        
        if FileManager.default.fileExists(atPath: sourceURL.path) == false {
            AlertPresenter.showInfo(on: view.window, title: "Archive Build Failed", message: "Unable to find \(sourceURL.lastPathComponent) file.")
            return
        }
        
        do {
            try HPServices.ensureHPAppDirectory(at: currentDirectoryURL, named: projectManager.projectName, fromBaseApplicationNamed: projectManager.baseApplicationName)
        } catch {
            outputTextView.appendTextAndScroll("Failed to build for archiving: \(error)\n")
            return
        }
        
        let result = HPServices.preProccess(at: sourceURL, to: currentDirectoryURL
            .appendingPathComponent(projectManager.projectName)
            .appendingPathExtension("hpappdir")
            .appendingPathComponent(projectManager.projectName)
            .appendingPathExtension("hpappprgm"),
                                            compress: UserDefaults.standard.object(forKey: "compression") as? Bool ?? false
        )
        outputTextView.appendTextAndScroll(result.err ?? "")
    }
    
    private func archiveProcess() {
        guard let currentDirectoryURL = projectManager.currentDirectoryURL else { return }
        
        let url: URL
        
        let dirA = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/HP Prime/Calculators/Prime")
            .appendingPathComponent(projectManager.projectName)
            .appendingPathExtension("hpappdir")
        let dirB = currentDirectoryURL
            .appendingPathComponent(projectManager.projectName)
            .appendingPathExtension("hpappdir")
        
        
        let archiveProjectAppOnly = UserDefaults.standard.object(forKey: "archiveProjectAppOnly") as? Bool ?? true
        if dirA.isNewer(than: dirB), archiveProjectAppOnly == false {
            url = dirA.deletingLastPathComponent()
            outputTextView.appendTextAndScroll("📦 Archiving from the virtual calculator directory.\n")
        } else {
            url = currentDirectoryURL
            outputTextView.appendTextAndScroll("📦 Archiving from the current project directory.\n")
        }
        
        let result = HPServices.archiveHPAppDirectory(in: url, named: projectManager.projectName, to: currentDirectoryURL)
        
        if let out = result.out, !out.isEmpty {
            outputTextView.appendTextAndScroll(out)
        }
        outputTextView.appendTextAndScroll(result.err ?? "")
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
                outputTextView.appendTextAndScroll("Installed: \(file)\n")
            } catch {
                outputTextView.appendTextAndScroll("Error installing \(file).hpprgm: \(error)\n")
            }
        }
    }
    
    private func installRequiredApps(requiredApps: [String]) {
        for file in requiredApps {
            do {
                try HPServices.installHPAppDirectory(at: URL(fileURLWithPath: file))
                outputTextView.appendTextAndScroll("Installed: \(file)\n")
            } catch {
                outputTextView.appendTextAndScroll("Error installing \(file).hpappdir: \(error)\n")
            }
        }
    }
    
    private func performBuild() {
        guard let url = documentManager.currentDocumentURL else {
            return
        }
        
        let sourceURL: URL
        if FileManager.default.fileExists(
            atPath: url
                .deletingLastPathComponent()
                .appendingPathComponent("main.prgm+")
                .path
        ) {
            sourceURL = url
                .deletingLastPathComponent()
                .appendingPathComponent("main.prgm+")
        } else {
            // Fall back to v26.0
            sourceURL = url
                .deletingLastPathComponent()
                .appendingPathComponent("\(projectManager.projectName).prgm+")
        }
        
        if FileManager.default.fileExists(atPath: sourceURL.path) == false {
            AlertPresenter.showInfo(on: view.window, title: "Build Failed", message: "Unable to find \(sourceURL.lastPathComponent) file.")
            return
        }
       
        let destinationURL = sourceURL
            .deletingLastPathComponent()
            .appendingPathComponent("\(projectManager.projectName).hpprgm")

        let compression = UserDefaults.standard.object(forKey: "compression") as? Bool ?? false
        let result = HPServices.preProccess(at: sourceURL, to: destinationURL,  compress: compression)
        outputTextView.appendTextAndScroll(result.err ?? "")
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
                self.outputTextView.appendTextAndScroll(out)
            } else {
                self.outputTextView.appendTextAndScroll(result.err ?? "")
            }
        }
    }
    
    @objc private func quickOpen(_ sender: NSMenuItem) {
        guard let url = documentManager.currentDocumentURL else {
            return
        }
        
        if documentManager.documentIsModified {
            AlertPresenter.presentYesNo(
                on: view.window,
                title: "Save Changes",
                message: "Do you want to save changes to '\(url.lastPathComponent)' before opening another document",
                primaryActionTitle: "Save"
            ) { confirmed in
                if confirmed {
                    self.documentManager.saveDocument()
                    self.documentManager.openDocument(url: url.deletingLastPathComponent().appendingPathComponent(sender.title))
                } else {
                    return
                }
            }
        } else {
            self.documentManager.openDocument(url: url.deletingLastPathComponent().appendingPathComponent(sender.title))
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
        
        comboButton.image = sender.image
    }
    
    private func refreshQuickOpenToolbar() {
        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        let currentDirectoryURL = URL(fileURLWithPath: currentDirectoryPath)
        
        guard
            let toolbar = view.window?.toolbar,
            let item = toolbar.items.first(where: {
                $0.paletteLabel == "Quick Open"
            }),
            let comboButton = item.view as? NSComboButton
        else {
            return
        }

        let menu = NSMenu()
        
        let contents = try? FileManager.default.contentsOfDirectory(
            at: currentDirectoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        contents?
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == false }
            .forEach { url in
                if url.pathExtension == "prgm" ||
                    url.pathExtension == "app" ||
                    url.pathExtension == "ppl" ||
                    url.pathExtension == "prgm+" ||
                    url.pathExtension == "ppl+" ||
                    url.pathExtension == "py"  ||
                    url.pathExtension == "md" ||
                    url.pathExtension == "txt" ||
                    url.pathExtension == "note"
                {
                    menu.addItem(
                        withTitle: url.lastPathComponent,
                        action: #selector(quickOpen(_:)),
                        keyEquivalent: ""
                    )
                    
                    let image: NSImage
                    switch url.pathExtension.lowercased() {
                    case "py": image = NSImage(imageLiteralResourceName: "Python")
                    case "md": image = NSImage(imageLiteralResourceName: "Note")
                    case "note": image = NSImage(imageLiteralResourceName: "Note")
                    case "txt": image = NSImage(imageLiteralResourceName: "File")
                    case "app": image = NSImage(imageLiteralResourceName: "Application")
                    case "prgm", "ppl": image = NSImage(imageLiteralResourceName: "Program")
                    case "prgm+", "ppl+": image = NSImage(imageLiteralResourceName: "Program")
                    default:
                        image = NSImage(imageLiteralResourceName: "File")
                    }
                    image.size = NSSize(width: 20, height: 20)
                    
                    menu.items.last?.image = image
                    if url == documentManager.currentDocumentURL {
                        menu.items.last?.state = .on
                        comboButton.image = image
                    }
                }
            }
        
        comboButton.menu = menu
        comboButton.title = documentManager.currentDocumentURL?
            .lastPathComponent
            ?? "Untitled"
        comboButton.target = self
        comboButton.action = #selector(revertDocumentToSaved(_:))
    }
    
    // MARK: - Actions
    @IBAction func checkForUpdates(_ sender: Any) {
        updateManager.checkForUpdates()
    }
    
    
    // MARK: - File IO Action Handlers
    
    @IBAction func newProject(_ sender: Any) {
        let panel = NSSavePanel()
        if let url = documentManager.currentDocumentURL {
            panel.directoryURL = url.deletingLastPathComponent()
        }
        panel.title = ""
        panel.allowedContentTypes = ["xprimeproj"].compactMap { UTType(filenameExtension: $0) }
        panel.nameFieldStringValue = "Untitled"
        
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            
            let projectName = url.deletingPathExtension().lastPathComponent
            let directoryURL = url.deletingLastPathComponent()
            
            self.projectManager.createProject(named: projectName, at: directoryURL)
        }
    }
    
    @IBAction func newDocument(_ sender: Any) {
        let panel = NSSavePanel()
        if let url = documentManager.currentDocumentURL {
            panel.directoryURL = url.deletingLastPathComponent()
        }
        panel.title = ""
        panel.allowedContentTypes = [
            UTType(filenameExtension: "prgm+")!
        ]
        panel.nameFieldStringValue = "Untitled"
        
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            
            guard let templateURL = Bundle.main.resourceURL?.appendingPathComponent("Untitled.prgm+") else { return }
            do {
                try FileManager.default.copyItem(at: templateURL, to: url)
                self.documentManager.openDocument(url: url)
            } catch {
                print("❌ copyItem failed:", error)
            }
        }
    }
    
    // MARK: - Opening Document
    
    private func openDocument(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        documentManager.openDocument(url: url)
    }
    
    private func proceedWithOpeningDocument() {
        let panel = NSOpenPanel()
        
        panel.title = ""
        panel.allowedContentTypes = [
            UTType(filenameExtension: "prgm+")!,
            UTType(filenameExtension: "prgm")!,
            UTType(filenameExtension: "app")!,
            UTType(filenameExtension: "hpprgm")!,
            UTType(filenameExtension: "hpappprgm")!,
            UTType(filenameExtension: "ppl")!,
            UTType(filenameExtension: "ppl+")!,
            UTType(filenameExtension: "ppl+")!,
            UTType(filenameExtension: "md")!,
            UTType(filenameExtension: "note")!,
            UTType.pythonScript,
            UTType.cHeader,
            UTType.text
        ]
        
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            self.documentManager.openDocument(url: url)
        }
    }
    
    @IBAction func openDocument(_ sender: Any) {
        if let url = documentManager.currentDocumentURL, documentManager.documentIsModified {
            AlertPresenter.presentYesNo(
                on: view.window,
                title: "Save Changes",
                message: "Do you want to save changes to '\(url.lastPathComponent)' before opening another document",
                primaryActionTitle: "Save"
            ) { confirmed in
                if confirmed {
                    self.documentManager.saveDocument()
                    self.proceedWithOpeningDocument()
                } else {
                    return
                }
            }
        } else {
            proceedWithOpeningDocument()
        }
    }
    
    // MARK: - Saving Document
    @IBAction func saveDocument(_ sender: Any) {
        guard let _ = documentManager.currentDocumentURL else {
            proceedWithSavingDocumentAs()
            return
        }
        documentManager.saveDocument()
    }
    
    // MARK: - Saving Document As
    
    private func proceedWithSavingDocumentAs() {
        let panel = NSSavePanel()
        if let url = documentManager.currentDocumentURL {
            panel.directoryURL = url.deletingLastPathComponent()
        }
        panel.allowedContentTypes = [
            UTType(filenameExtension: "prgm+")!,
            UTType(filenameExtension: "ppl+")!,
            UTType(filenameExtension: "prgm")!,
            UTType(filenameExtension: "ppl")!,
            UTType(filenameExtension: "app")!,
            UTType(filenameExtension: "note")!,
            UTType(filenameExtension: "hpnote")!,
            UTType(filenameExtension: "py")!,
            UTType(filenameExtension: "md")!,
            UTType(filenameExtension: "txt")!,
            .pythonScript
        ]
        panel.nameFieldStringValue = "Untitled"
        panel.title = ""
        
        
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            self.documentManager.saveDocumentAs(to: url)
            self.documentManager.openDocument(url: url)
        }
    }
    
    @IBAction func saveDocumentAs(_ sender: Any) {
        proceedWithSavingDocumentAs()
    }
    
    // MARK: - Export as HP Prime Program
    
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
            guard let url = documentManager.currentDocumentURL else { return }
            exportHPProgram(from: url)
        }
        
        if let _ = documentManager.currentDocumentURL, documentManager.documentIsModified {
            AlertPresenter.presentYesNo(
                on: window,
                title: "Save Changes",
                message: "Do you want to save your changes before exporting as HPPRGM?",
                primaryActionTitle: "Save"
            ) { confirmed in
                guard confirmed else { return }
                self.documentManager.saveDocument()

                proceedWithExport()
            }
        } else {
            proceedWithExport()
        }
    }
    
    // MARK: - Export as HP Prime Source Code UTF16-le
    
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
            guard let url = documentManager.currentDocumentURL else { return }
            exportPRGM(from: url)
        }
        
        // Document already exists
        if documentManager.currentDocumentURL != nil {
            
            if documentManager.documentIsModified {
                AlertPresenter.presentYesNo(
                    on: window,
                    title: "Save Changes",
                    message: "Do you want to save your changes before exporting as PRGM?",
                    primaryActionTitle: "Save"
                ) { confirmed in
                    guard confirmed else { return }
                    self.documentManager.saveDocument()
                    proceedWithExport()
                }
            } else {
                proceedWithExport()
            }
            
        } else {
            // First save required
            proceedWithSavingDocumentAs()
            
            guard let url = documentManager.currentDocumentURL,
                  FileManager.default.fileExists(atPath: url.path) else {
                return
            }
            
            exportPRGM(from: url)
        }
    }
    
    // MARK: - Export as HP Prime Application Archive
    
    @IBAction func exportAsArchive(_ sender: Any) {
        guard let currentDirectoryURL = projectManager.currentDirectoryURL else { return }
        
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
            
            let result = HPServices.archiveHPAppDirectory(in: currentDirectoryURL, named: self.projectManager.projectName, to: destination)
            
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
    
    // MARK: -
    
    @IBAction func revertDocumentToSaved(_ sender: Any) {
        guard let url = documentManager.currentDocumentURL, documentManager.documentIsModified else { return }
        
        AlertPresenter.presentYesNo(
            on: view.window,
            title: "Revert to Original",
            message: "All changes to '\(url.lastPathComponent)' will be lost.",
            primaryActionTitle: "Revert"
        ) { confirmed in
            if confirmed {
                self.openDocument(url: url)
            } else {
                return
            }
        }
    }
    
    // MARK: - Project Actions
    
    @IBAction func stop(_ sender: Any) {
        HPServices.terminateVirtualCalculator()
    }
    
    @IBAction func run(_ sender: Any) {
        if let _ = documentManager.currentDocumentURL {
            documentManager.saveDocument()
        } else {
            proceedWithSavingDocumentAs()
        }
        
        guard let currentDirectoryURL = projectManager.currentDirectoryURL else {
            return
        }
        
        let programs = processRequires(in: codeEditorTextView.string)
        installRequiredPrograms(requiredFiles: programs.requiredFiles)
        
        let apps = processAppRequires(in: codeEditorTextView.string)
        installRequiredApps(requiredApps: apps.requiredApps)
        
        performBuild()
        
        if HPServices.hpPrgmExists(atPath: currentDirectoryURL.path, named: projectManager.projectName) {
            installHPPrgmFileToCalculator(sender)
            HPServices.launchVirtualCalculator()
        }
    }
    
    @IBAction func archive(_ sender: Any) {
        if let _ = documentManager.currentDocumentURL {
            documentManager.saveDocument()
        } else {
            proceedWithSavingDocumentAs()
        }
        buildForArchive()
        archiveProcess()
    }
    
    @IBAction func buildForRunning(_ sender: Any) {
        if let _ = documentManager.currentDocumentURL {
            documentManager.saveDocument()
        } else {
            proceedWithSavingDocumentAs()
        }
        
        guard let currentDirectoryURL = projectManager.currentDirectoryURL else {
            return
        }
        
        let result = processRequires(in: codeEditorTextView.string)
        installRequiredPrograms(requiredFiles: result.requiredFiles)
        
        let appsToInstall = processAppRequires(in: codeEditorTextView.string)
        installRequiredApps(requiredApps: appsToInstall.requiredApps)
        
        performBuild()
        
        if HPServices.hpPrgmExists(atPath: currentDirectoryURL.path, named: projectManager.projectName) {
            installHPPrgmFileToCalculator(sender)
        }
    }
    
    @IBAction func buildForArchiving(_ sender: Any) {
        if let _ = documentManager.currentDocumentURL {
            documentManager.saveDocument()
        } else {
            proceedWithSavingDocumentAs()
        }
        buildForArchive()
    }
    
    @IBAction func installHPPrgmFileToCalculator(_ sender: Any) {
        guard let currentDirectoryURL = projectManager.currentDirectoryURL else { return }
        
        let programURL = currentDirectoryURL
            .appendingPathComponent(projectManager.projectName)
            .appendingPathExtension("hpprgm")
        outputTextView.appendTextAndScroll("Installing: \(programURL.lastPathComponent)\n")
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
        guard let currentDirectoryURL = projectManager.currentDirectoryURL else { return }
        
        let appDirURL = currentDirectoryURL
            .appendingPathComponent(projectManager.projectName)
            .appendingPathExtension("hpappdir")
        outputTextView.appendTextAndScroll("Installing: \(appDirURL.lastPathComponent)\n")
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
    
    @IBAction func build(_ sender: Any) {
        if let _ = documentManager.currentDocumentURL {
            documentManager.saveDocument()
        } else {
            proceedWithSavingDocumentAs()
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
                self.outputTextView.appendTextAndScroll("Importing \(url.pathExtension.uppercased()) Image...\n")
                self.codeEditorTextView.insertCode(out)
            }
            self.outputTextView.appendTextAndScroll(contents.err ?? "")
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
                self.outputTextView.appendTextAndScroll("Importing Adafruit GFX Font...\n")
                self.codeEditorTextView.insertCode(contents.out ?? "")
            }
            self.outputTextView.appendTextAndScroll(contents.err ?? "")
        }
    }
    
    @IBAction func importCode(_ sender: Any) {
        let openPanel = NSOpenPanel()
        let contentTypes = ["prgm", "ppl", "prgm+", "ppl+"].compactMap { UTType(filenameExtension: $0) }
        
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
#if Debug
                print("Item '\(item.title)' is in menu: \(parentMenu.title)")
#endif
                
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
        guard let currentDirectoryURL = projectManager.currentDirectoryURL else {
            return
        }
        
        outputTextView.appendTextAndScroll("Cleaning...\n")
        
        let files: [URL] = [
            currentDirectoryURL.appendingPathComponent("\(projectManager.projectName).hpprgm"),
            currentDirectoryURL.appendingPathComponent("\(projectManager.projectName).hpappdir/\(projectManager.projectName).hpappprgm"),
            currentDirectoryURL.appendingPathComponent("\(projectManager.projectName).hpappdir.zip")
        ]
        
        for file in files {
            do {
                try FileManager.default.removeItem(at: file)
                outputTextView.appendTextAndScroll("✅ File removed: \(file.lastPathComponent)\n")
            } catch {
                outputTextView.appendTextAndScroll("⚠️ No file found: \(file.lastPathComponent)\n")
            }
        }
    }
    
    @IBAction func showBuildFolderInFinder(_ sender: Any) {
        guard let currentDocumentURL = documentManager.currentDocumentURL else {
            return
        }
        currentDocumentURL.revealInFinder()
    }
    
    @IBAction func showCalculatorFolderInFinder(_ sender: Any) {
        let calculator = UserDefaults.standard.object(forKey: "calculator") as? String ?? "Prime"
        guard let url = HPServices.hpPrimeDirectory(forUser: calculator) else {
            return
        }
        url.revealInFinder()
    }
    
    @IBAction func reformatCode(_ sender: Any) {
        if let _ = documentManager.currentDocumentURL {
            documentManager.saveDocument()
        } else {
            proceedWithSavingDocumentAs()
        }
        
        guard let currentURL = documentManager.currentDocumentURL else {
            return
        }
        
        let contents = ProcessRunner.run(executable: ToolchainPaths.bin.appendingPathComponent("ppl+"), arguments: [currentURL.path, "--reformat", "-o", "/dev/stdout"])
        if let out = contents.out, !out.isEmpty {
            codeEditorTextView.string = out
        }
        self.outputTextView.appendTextAndScroll(contents.err ?? "")
    }
    
    // MARK: - Editor
    
    @IBAction func toggleSmartSubtitution(_ sender: NSMenuItem) {
        codeEditorTextView.smartSubtitution = !codeEditorTextView.smartSubtitution
        sender.state = codeEditorTextView.smartSubtitution ? .on : .off
    }
    
    // MARK: - Output Information
    
    @IBAction func toggleOutput(_ sender: NSButton) {
        outputTextView.toggleVisability(sender)
    }
    
    @IBAction func clearOutput(_ sender: NSButton) {
        outputTextView.string = ""
    }
    
    
    // MARK: - Validation for Toolbar Items
    
    internal func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.action {
        case #selector(build(_:)), #selector(run(_:)):
            if projectManager.currentDirectoryURL != nil  {
                return true
            }
            return false
            
        case #selector(showBuildFolderInFinder(_:)):
            if projectManager.currentDirectoryURL != nil {
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
        if codeEditorTextView.isEditable == false {
            return false
        }
        
        let ext = (documentManager.currentDocumentURL != nil) ? documentManager.currentDocumentURL!.pathExtension.lowercased() : ""
        
        switch menuItem.action {
        case #selector(reformatCode(_:)):
            if let _ = documentManager.currentDocumentURL, ext == "prgm" || ext == "ppl" {
                return true
            }
            return false
            
        case #selector(installHPPrgmFileToCalculator(_:)):
            menuItem.title = "Install Program"
            if HPServices.hpPrgmIsInstalled(named: projectManager.projectName) {
                    menuItem.title = "Update Program"
            }
            if let currentDirectoryURL = projectManager.currentDirectoryURL {
                return HPServices.hpPrgmExists(atPath: currentDirectoryURL.path, named: projectManager.projectName)
            }
            return false
            
        case #selector(installHPAppDirectoryToCalculator(_:)):
            menuItem.title = "Install Application"
            if HPServices.hpAppDirectoryIsInstalled(named: projectManager.projectName) {
                menuItem.title = "Update Application"
            }
            if let currentDirectoryURL = projectManager.currentDirectoryURL {
                return HPServices.hpAppDirIsComplete(atPath: currentDirectoryURL.path, named: projectManager.projectName)
            }
            return false
            
        case #selector(exportAsHPPrgm(_:)):
            if let _ = documentManager.currentDocumentURL, ext == "prgm" || ext == "prgm+" || ext == "ppl" || ext == "ppl+"  {
                return true
            }
            return false
            
        case #selector(exportAsPrgm(_:)):
            if let _ = documentManager.currentDocumentURL, ext == "prgm+" || ext == "ppl+" {
                return true
            }
            return false
            
        case #selector(exportAsArchive(_:)), #selector(archiveWithoutBuilding(_:)):
            if let currentDirectoryURL = projectManager.currentDirectoryURL {
                return HPServices.hpAppDirIsComplete(atPath: currentDirectoryURL.path, named: projectManager.projectName)
            }
            return false
            
        case #selector(run(_:)), #selector(archive(_:)), #selector(build(_:)), #selector(buildForRunning(_:)), #selector(buildForArchiving(_:)):
            if projectManager.currentDirectoryURL != nil   {
                return true
            }
            return false
            
        case #selector(importCode(_:)):
            return true
            
        case #selector(insertTemplate(_:)), #selector(importImage(_:)), #selector(importAdafruitGFXFont(_:)):
            if ext == "prgm" || ext == "prgm+" || ext == "hpprgm" || ext == "hpappprgm" || ext == "ppl" || ext == "ppl+" {
                return true
            }
            return false
            
        case #selector(revertDocumentToSaved(_:)):
            return documentManager.documentIsModified
            
        case #selector(cleanBuildFolder(_:)):
            if projectManager.currentDirectoryURL != nil {
                return true
            }
            return false
            
        case #selector(showBuildFolderInFinder(_:)):
            if projectManager.currentDirectoryURL != nil {
                return true
            }
            return false
            
        case #selector(handleThemeSelection(_:)):
            if ThemeLoader.shared.preferredTheme == menuItem.title {
                menuItem.state = .on
            } else {
                menuItem.state = .off
            }
            return true
            
        case #selector(handleGrammarSelection(_:)):
            if GrammarLoader.shared.preferredGrammar == menuItem.title {
                menuItem.state = .on
            } else {
                menuItem.state = .off
            }
            return true
            
        default:
            break
        }
        
        return true
    }
}

// MARK: - 🤝 DocumentManagerDelegate
extension MainViewController: DocumentManagerDelegate {
    func documentManagerDidSave(_ manager: DocumentManager) {
#if Debug
        print("Saved successfully")
#endif
        projectManager.saveProject()
    }
    
    func documentManager(_ manager: DocumentManager, didFailWith error: Error) {
#if Debug
        print("Save failed:", error)
#endif
    }
    
    func documentManagerDidOpen(_ manager: DocumentManager) {
#if Debug
        print("Opened successfully")
#endif
        refreshQuickOpenToolbar()
        projectManager.openProject()
        if let url = documentManager.currentDocumentURL {
            loadAppropriateGrammar(forType: url.pathExtension.lowercased())
        }
        
        refreshProjectIconImage()
        refreshBaseApplicationMenu()
    }
    
    func documentManager(_ manager: DocumentManager, didFailToOpen error: Error) {
#if Debug
        print("Open failed:", error)
#endif
    }
}

