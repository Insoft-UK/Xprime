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
    @IBOutlet private weak var baseApplication: NSPopUpButton!
    
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
        documentManager = DocumentManager(editor: codeEditorTextView, outputTextView: outputTextView)
        documentManager.delegate = self
        projectManager = ProjectManager(documentManager: documentManager)
        projectManager.delegate = self
        statusManager = StatusManager(editor: codeEditorTextView, statusLabel: statusLabel)
        
        setupObservers()
        setupEditor()
        
        if let menu = NSApp.mainMenu {
            populateThemesMenu(menu: menu)
            populateGrammarMenu(menu: menu)
        }
        
        configureBaseApplicationAction()
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
        themeManager.applySavedTheme()
        registerWindowFocusObservers()
        refreshBaseApplicationMenu()
        
        projectManager.openLastOrUntitled()
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
        
        guard let projectDirectoryURL = projectManager.projectDirectoryURL else { return }
        
        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        let currentDirectoryURL = URL(fileURLWithPath: currentDirectoryPath)
        
        if currentDirectoryPath != projectDirectoryURL.path && projectManager.doseProjectExist(at: currentDirectoryURL) == true {
            projectManager.openProject(in: currentDirectoryURL)
        } else {
            refreshQuickOpenToolbar()
            refreshProjectIconImage()
            refreshBaseApplicationMenu()
        }
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
    
    // MARK:- Base Application
    private func refreshBaseApplicationMenu() {
        guard let menu = baseApplication.menu else { return }
        let baseApplicationName = projectManager.baseApplicationName
        for item in menu.items {
            if item.title == baseApplicationName {
                item.state = .on
                baseApplication.select(item)
            } else {
                item.state = .off
            }
            item.image?.size = NSSize(width: 16, height: 16)
        }
        baseApplication.isEnabled = documentManager.currentDocumentURL != nil
    }
    
    private func configureBaseApplicationAction() {
        baseApplication.target = self
        baseApplication.action = #selector(preferBaseApplicationSelection(_:))
    }
    
    // MARK: - Base Application Action Handler
    @objc func preferBaseApplicationSelection(_ sender: NSMenuItem) {
        guard let currentDocumentURL = documentManager.currentDocumentURL else { return }
        guard let name = projectManager.projectName else { return }
        
        let directoryURL = currentDocumentURL.deletingLastPathComponent()
        
        if directoryURL.appendingPathComponent("\(name).hpappdir").isDirectory {
            outputTextView.appendTextAndScroll("⚠️ Changing base application \"\(projectManager.baseApplicationName)\" to \"\(sender.title)\".\n")
        } else {
            outputTextView.appendTextAndScroll("🔨 Creating application directory\n")
        }
        
        try? HPServices.resetHPAppContents(at: directoryURL, named: name, fromBaseApplicationNamed: sender.title)
        outputTextView.appendTextAndScroll("Base application is \"\(projectManager.baseApplicationName)\"\n")
        
        
        refreshQuickOpenToolbar()
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
        window.title = projectManager.projectName ?? ""
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
            "Python": ["py"],
            ".ntf": ["hpnote", "hpappnote", "note", "ntf"],
            ".md": ["md"]
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
    
    private func mainURL(in directoryURL: URL) -> URL? {
        for main in [
            "main.prgm+",
            "main.prgm",
            "main.ppl+",
            "main.ppl"
        ] {
            let url = directoryURL
                .appendingPathComponent(main)
            
            if FileManager.default.fileExists(
                atPath: url.path) == true
            {
                return url
            }
        }
        
        return nil
    }
    
    private func ntfToHpNote(in url: URL) {
        guard let projectName = projectManager.projectName else { return }
        
        for file in [
            "info.note",
            "info.ntf",
            "info.md"
        ] {
            if FileManager.default.fileExists(
                atPath: url
                    .appendingPathComponent(file)
                    .path) == false
            {
                continue
            }
            
            convertFileToHPNote(
                from: url
                    .appendingPathComponent(file),
                to: url
                    .appendingPathComponent(projectName)
                    .appendingPathExtension("hpappdir")
                    .appendingPathComponent(projectName)
                    .appendingPathExtension("hpappnote")
                
                )
            break
        }
    }
    
    private func buildProgram() {
        guard let url = projectManager.projectDirectoryURL else { return }
        guard let sourceURL = mainURL(in: url) else {
            AlertPresenter.showInfo(on: view.window, title: "Build Failed", message: "Unable to find main.prgm+ or main.prgm file.")
            return
        }
        guard let projectName = projectManager.projectName else { return }
        
        let destinationURL = url
            .appendingPathComponent("\(projectName).hpprgm")

        let compression = UserDefaults.standard.object(forKey: "compression") as? Bool ?? false
        let result = HPServices.preProccess(at: sourceURL, to: destinationURL,  compress: compression)
        outputTextView.appendTextAndScroll(result.err ?? "")
    }
    
    private func buildApplication() {
        guard let url = projectManager.projectDirectoryURL else { return }
        guard let sourceURL = mainURL(in: url) else {
            AlertPresenter.showInfo(on: view.window, title: "Archive Build Failed", message: "Unable to find main.prgm+ or main.prgm file.")
            return
        }
        guard let projectName = projectManager.projectName else { return }
        
        do {
            try HPServices.ensureHPAppDirectory(at: url, named: projectName, fromBaseApplicationNamed: projectManager.baseApplicationName)
        } catch {
            outputTextView.appendTextAndScroll("Failed to build for archiving: \(error)\n")
            return
        }
        
        ntfToHpNote(in: url)
        
        let result = HPServices.preProccess(at: sourceURL, to: url
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpappdir")
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpappprgm"),
                                            compress: UserDefaults.standard.object(forKey: "compression") as? Bool ?? false
        )
        outputTextView.appendTextAndScroll(result.err ?? "")
    }
    
    private func archiveProcess() {
        guard let projectDirectoryURL = projectManager.projectDirectoryURL else { return }
        guard let projectName = projectManager.projectName else { return }
        
        let url: URL
        
        let dirA = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/HP Prime/Calculators/Prime")
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpappdir")
        let dirB = projectDirectoryURL
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpappdir")
        
        
        let archiveProjectAppOnly = UserDefaults.standard.object(forKey: "archiveProjectAppOnly") as? Bool ?? true
        if dirA.isNewer(than: dirB), archiveProjectAppOnly == false {
            url = dirA.deletingLastPathComponent()
            outputTextView.appendTextAndScroll("📦 Archiving from the virtual calculator directory.\n")
        } else {
            url = projectDirectoryURL
            outputTextView.appendTextAndScroll("📦 Archiving from the current project directory.\n")
        }
        
        let result = HPServices.archiveHPAppDirectory(in: url, named: projectName, to: projectDirectoryURL)
        
        if let out = result.out, !out.isEmpty {
            outputTextView.appendTextAndScroll(out)
        }
        outputTextView.appendTextAndScroll(result.err ?? "")
    }
    
    // MARK: - Xprime #require extension to PPL+ for importing Programs
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
    
    private func installRequiredApps(requiredApps: [String]) {
        for file in requiredApps {
            do {
                try HPServices.installHPAppDirectory(at: URL(fileURLWithPath: file))
                outputTextView.appendTextAndScroll("Installed: \"\(file)\"\n")
            } catch {
                outputTextView.appendTextAndScroll("Error installing \"\(file).hpappdir\": \(error)\n")
            }
        }
    }
    
    // MARK: - Xprime #require extension to PPL+ for importing Apps
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
                outputTextView.appendTextAndScroll("Installed: \"\(file)\"\n")
            } catch {
                outputTextView.appendTextAndScroll("Error installing \"\(file).hpprgm\": \(error)\n")
            }
        }
    }
    
    // MARK: -
    @objc private func quickOpen(_ sender: NSMenuItem) {
        guard let projectDirectoryURL = projectManager.projectDirectoryURL else {
            return
        }
       
        if let currentDocumentURL = documentManager.currentDocumentURL, documentManager.documentIsModified {
            AlertPresenter.presentYesNo(
                on: view.window,
                title: "Save Changes",
                message: "Do you want to save changes to '\(currentDocumentURL.lastPathComponent)' before opening another document",
                primaryActionTitle: "Save"
            ) { confirmed in
                if confirmed {
                    self.documentManager.saveDocument()
                    self.documentManager.openDocument(at: projectDirectoryURL.appendingPathComponent(sender.title))
                } else {
                    return
                }
            }
        } else {
            self.documentManager.openDocument(at: projectDirectoryURL.appendingPathComponent(sender.title))
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
        guard let url = projectManager.projectDirectoryURL else {
            return
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
        

        let menu = NSMenu()
        
        let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
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
                    url.pathExtension == "ntf" ||
                    url.pathExtension == "txt" ||
                    url.pathExtension == "note" ||
                    url.pathExtension == "bmp" ||
                    url.pathExtension == "png" ||
                    url.pathExtension == "h"
                {
                    menu.addItem(
                        withTitle: url.lastPathComponent,
                        action: #selector(quickOpen(_:)),
                        keyEquivalent: ""
                    )
                    
                    let image: NSImage
                    switch url.pathExtension.lowercased() {
                    case "note", "md", "ntf", "txt":
                        image = NSImage(imageLiteralResourceName: "Notes")

                    case "app":
                        image = NSImage(imageLiteralResourceName: "Apps")
                        
                    case "ppl", "ppl+", "py", "h", "bmp", "png":
                        image = NSImage(imageLiteralResourceName: "Program")
                        
                    case "prgm", "prgm+":
                        if projectManager.isProjectAnApplication, url.deletingPathExtension().lastPathComponent == "main" {
                            image = NSImage(imageLiteralResourceName: "Apps")
                        } else {
                            image = NSImage(imageLiteralResourceName: "Program")
                        }
                    
                    default:
                        image = NSImage(imageLiteralResourceName: "File")
                    }
                    
                    image.size = NSSize(width: 20, height: 12)
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
    
    // MARK: - Add Files to Current Project
    @IBAction private func addFilesTo(_ sender : Any) {
        let panel = NSOpenPanel()
        
        panel.prompt = "Add"
        panel.title = ""
        panel.directoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        panel.allowedContentTypes = [
            UTType(filenameExtension: "prgm+")!,
            UTType(filenameExtension: "prgm")!,
            UTType(filenameExtension: "app")!,
            UTType(filenameExtension: "ppl")!,
            UTType(filenameExtension: "ppl+")!,
            UTType(filenameExtension: "md")!,
            UTType(filenameExtension: "ntf")!,
            UTType(filenameExtension: "note")!,
            UTType(filenameExtension: "hpnote")!,
            UTType(filenameExtension: "hpappnote")!,
            UTType(filenameExtension: "bmp")!,
            UTType(filenameExtension: "png")!,
            UTType.pythonScript,
            UTType.cHeader,
            UTType.text
        ]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        panel.begin { result in
            guard result == .OK else { return }
            guard let projectDirectoryURL = self.projectManager.projectDirectoryURL else { return }
            
            let selectedURLs = panel.urls
            
            for url in selectedURLs {
                let destinationURL = projectDirectoryURL.appendingPathComponent(url.lastPathComponent)
                self.copyFileHandlingDuplicates(
                    from: url,
                    to: destinationURL
                )
                if destinationURL == self.documentManager.currentDocumentURL {
                    self.documentManager.openDocument(at: destinationURL)
                }
            }
        }
    }
    
    private func copyFileHandlingDuplicates(from url: URL, to destinationURL: URL) {
        let fileManager = FileManager.default

        do {
            try fileManager.copyItem(at: url, to: destinationURL)
        } catch {
            if (error as NSError).code == NSFileWriteFileExistsError {
                let alert = NSAlert()
                alert.messageText = "File Already Exists"
                alert.informativeText = "\(url.lastPathComponent) already exists in the project. Replace it?"
                alert.addButton(withTitle: "Replace")
                alert.addButton(withTitle: "Cancel")

                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    do {
                        try fileManager.removeItem(at: destinationURL)
                        try fileManager.copyItem(at: url, to: destinationURL)
                    } catch {
                        print("❌ Failed to replace file:", error)
                    }
                }
            } else {
                print("❌ Copy failed:", error)
            }
        }
    }
    
    // MARK: - Opening Document
    private func openDocument(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        documentManager.openDocument(at: url)
    }
    
    private func proceedWithOpeningDocument() {
        let panel = NSOpenPanel()
        
        panel.title = ""
        panel.directoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        panel.allowedContentTypes = [
            UTType(filenameExtension: "xprimeproj")!,
            UTType(filenameExtension: "prgm+")!,
            UTType(filenameExtension: "prgm")!,
            UTType(filenameExtension: "app")!,
            UTType(filenameExtension: "hpprgm")!,
            UTType(filenameExtension: "hpappprgm")!,
            UTType(filenameExtension: "ppl")!,
            UTType(filenameExtension: "ppl+")!,
            UTType(filenameExtension: "md")!,
            UTType(filenameExtension: "ntf")!,
            UTType(filenameExtension: "note")!,
            UTType(filenameExtension: "bmp")!,
            UTType(filenameExtension: "png")!,
            UTType(filenameExtension: "h")!,
            UTType(filenameExtension: "hpnote")!,
            UTType(filenameExtension: "hpappnote")!,
            UTType.pythonScript,
            UTType.cHeader,
            UTType.text
        ]
        
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            let ext = url.pathExtension.lowercased()
            
            if ext == "bmp" || ext == "png" || ext == "h" {
                self.loadAppropriateGrammar(forType: "ppl")
            }
            
            if url.lastPathComponent.hasSuffix(".xprimeproj") {
                self.projectManager.openProject(at: url)
            } else {
                self.documentManager.openDocument(at: url)
            }
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
        documentManager.saveDocumentAs(
            allowedContentTypes: [
                UTType(filenameExtension: "prgm+")!,
                UTType(filenameExtension: "ppl+")!,
                UTType(filenameExtension: "prgm")!,
                UTType(filenameExtension: "hpprgm")!,
                UTType(filenameExtension: "hpappprgm")!,
                UTType(filenameExtension: "ppl")!,
                UTType(filenameExtension: "app")!,
                UTType(filenameExtension: "note")!,
                UTType(filenameExtension: "ntf")!,
                UTType(filenameExtension: "hpnote")!,
                UTType(filenameExtension: "hpappnote")!,
                UTType(filenameExtension: "py")!,
                UTType(filenameExtension: "md")!,
                UTType(filenameExtension: "txt")!,
                .pythonScript
            ],
            defaultFileName: documentManager.currentDocumentURL?.lastPathComponent ?? "Untitled"
        )
    }
    
    @IBAction func saveDocumentAs(_ sender: Any) {
        proceedWithSavingDocumentAs()
    }
    
    private func convertFileToHPNote(
        from sourceURL: URL,
        to destinationURL: URL
    ) {
        let command = ToolchainPaths.bin.appendingPathComponent("note").path
        let arguments: [String] = [
            sourceURL.path,
            "-o",
            destinationURL.path
        ]
        
        let commandURL = URL(fileURLWithPath: command)
        let result = ProcessRunner.run(executable: commandURL, arguments: arguments)
        
        guard result.exitCode == 0 else {
            outputTextView.appendTextAndScroll("🛑 Required Note conversion tool not installed.\n")
            return
        }
        outputTextView.appendTextAndScroll(result.err ?? "")
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
        buildForRunning(sender)
        guard documentManager.currentDocumentURL != nil else { return }
        HPServices.launchVirtualCalculator()
    }
    
    @IBAction func archive(_ sender: Any) {
        build(sender)
        guard let _ = documentManager.currentDocumentURL else { return }
        archiveProcess()
    }
    
    @IBAction func buildForRunning(_ sender: Any) {
        saveDocument(sender)
        guard let _ = documentManager.currentDocumentURL else { return }
        
        let result = processRequires(in: codeEditorTextView.string)
        installRequiredPrograms(requiredFiles: result.requiredFiles)
        
        let appsToInstall = processAppRequires(in: codeEditorTextView.string)
        installRequiredApps(requiredApps: appsToInstall.requiredApps)
        
        if projectManager.isProjectAnApplication {
            buildApplication()
            installHPAppDirectoryToCalculator(sender)
        } else {
            buildProgram()
            installHPPrgmFileToCalculator(sender)
        }
    }
    
    @IBAction func installHPPrgmFileToCalculator(_ sender: Any) {
        guard let currentDirectoryURL = projectManager.projectDirectoryURL else { return }
        guard let projectName = projectManager.projectName else { return }
        
        let programURL = currentDirectoryURL
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpprgm")
        outputTextView.appendTextAndScroll("Installing: \(programURL.lastPathComponent)\n")
        do {
            let calculator = UserDefaults.standard.object(forKey: "calculator") as? String ?? "Prime"
            try HPServices.installHPPrgm(at: programURL, forUser: calculator)
            outputTextView.appendTextAndScroll("✅ Successfully installed \"\(programURL.lastPathComponent)\" \n")
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
        guard let currentDirectoryURL = projectManager.projectDirectoryURL else { return }
        guard let projectName = projectManager.projectName else { return }
        
        let appDirURL = currentDirectoryURL
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpappdir")
        outputTextView.appendTextAndScroll("Installing: \(appDirURL.lastPathComponent)\n")
        do {
            let calculator = UserDefaults.standard.object(forKey: "calculator") as? String ?? "Prime"
            try HPServices.installHPAppDirectory(at: appDirURL, forUser: calculator)
            outputTextView.appendTextAndScroll("✅ Successfully installed \"\(appDirURL.lastPathComponent)\" \n")
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
        saveDocument(sender)
        guard let _ = documentManager.currentDocumentURL else { return }
        
        if !projectManager.isProjectAnApplication {
            buildProgram()
        } else {
            buildApplication()
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
        guard let currentDirectoryURL = projectManager.projectDirectoryURL, let projectName = projectManager.projectName else {
            return
        }
        
        outputTextView.appendTextAndScroll("Cleaning...\n")
        
        let files: [URL] = [
            currentDirectoryURL.appendingPathComponent("\(projectName).hpprgm"),
            currentDirectoryURL.appendingPathComponent("\(projectName).hpappdir/\(projectName).hpappprgm"),
            currentDirectoryURL.appendingPathComponent("\(projectName).hpappdir.zip")
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
        guard let projectDirectoryURL = projectManager.projectDirectoryURL else {
            return
        }
        projectDirectoryURL.revealInFinderWithCooldown()
    }
    
    @IBAction func showCalculatorFolderInFinder(_ sender: Any) {
        let calculator = UserDefaults.standard.object(forKey: "calculator") as? String ?? "Prime"
        guard let url = HPServices.hpPrimeDirectory(forUser: calculator) else {
            return
        }
        url.revealInFinderWithCooldown()
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
            if projectManager.projectDirectoryURL != nil  {
                return true
            }
            return false
            
        case #selector(showBuildFolderInFinder(_:)):
            if projectManager.projectDirectoryURL != nil {
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
            if let projectName = projectManager.projectName, HPServices.hpPrgmIsInstalled(named: projectName) {
                    menuItem.title = "Update Program"
            }
            if let currentDirectoryURL = projectManager.projectDirectoryURL, let projectName = projectManager.projectName  {
                return HPServices.hpPrgmExists(atPath: currentDirectoryURL.path, named: projectName)
            }
            return false
            
        case #selector(installHPAppDirectoryToCalculator(_:)):
            menuItem.title = "Install Application"
            if let projectName = projectManager.projectName, HPServices.hpAppDirectoryIsInstalled(named: projectName) {
                menuItem.title = "Update Application"
            }
            if let projectName = projectManager.projectName, let currentDirectoryURL = projectManager.projectDirectoryURL {
                return HPServices.hpAppDirIsComplete(atPath: currentDirectoryURL.path, named: projectName)
            }
            return false
            
        case #selector(run(_:)), #selector(archive(_:)), #selector(build(_:)), #selector(buildForRunning(_:)):
            if projectManager.projectDirectoryURL != nil   {
                return true
            }
            return false
            
        case #selector(insertTemplate(_:)):
            if ext == "prgm" || ext == "prgm+" || ext == "hpprgm" || ext == "hpappprgm" || ext == "ppl" || ext == "ppl+" {
                return true
            }
            return false
            
        case #selector(revertDocumentToSaved(_:)):
            return documentManager.documentIsModified
            
        case #selector(cleanBuildFolder(_:)):
            if projectManager.projectDirectoryURL != nil {
                return true
            }
            return false
            
        case #selector(showBuildFolderInFinder(_:)):
            if projectManager.projectDirectoryURL != nil {
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
            
        case #selector(addFilesTo(_:)):
            if projectManager.projectDirectoryURL != nil, let projectName = projectManager.projectName {
                menuItem.title = "Add Files to \"\(projectName)\"…"
                return true
            }
            menuItem.title = "Add Files to \"\"…"
            return false
            
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
        guard let projectDirectoryURL = projectManager.projectDirectoryURL else { return }
        guard let projectName = projectManager.projectName else { return }
        
        let projectFileURL = projectDirectoryURL
            .appendingPathComponent("\(projectName).xprimeproj")
        
        projectManager.saveProjectAs(at: projectFileURL)
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
        if let url = documentManager.currentDocumentURL {
            loadAppropriateGrammar(forType: url.pathExtension.lowercased())
        }
        
        gutterView.updateLines()
        
        refreshQuickOpenToolbar()
        refreshProjectIconImage()
        refreshBaseApplicationMenu()
        updateWindowDocumentIcon()
    }
    
    func documentManager(_ manager: DocumentManager, didFailToOpen error: Error) {
#if Debug
        print("Open failed:", error)
#endif
    }
}

// MARK: - 🤝 ProjectManagerDelegate
extension MainViewController: ProjectManagerDelegate {
    func projectManagerDidSave(_ manager: ProjectManager) {
#if Debug
        print("Saved successfully project settings")
#endif
    }
    
    func projectManager(_ manager: ProjectManager, didFailWith error: any Error) {
        AlertPresenter.showInfo(
            on: self.view.window,
            title: "Saving Project Failed",
            message: "\(error)"
        )
    }
    
    func projectManagerDidOpen(_ manager: ProjectManager) {
        guard let projectDirectoryURL = projectManager.projectDirectoryURL else { return }
        
        if let url = mainURL(in: projectDirectoryURL) {
            documentManager.openDocument(at: url)
        }
        
        refreshQuickOpenToolbar()
        refreshProjectIconImage()
        refreshBaseApplicationMenu()
        updateWindowDocumentIcon()
    }
    
    func projectManager(_ manager: ProjectManager, didFailToOpen error: any Error) {
        AlertPresenter.showInfo(
            on: self.view.window,
            title: "Opening Project Failed",
            message: "\(error)"
        )
    }
    
}
