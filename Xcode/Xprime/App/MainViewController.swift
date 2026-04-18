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
    // MARK: - Outlets
    @IBOutlet weak var splitView: NSSplitView!
    @IBOutlet var codeEditorTextView: CodeEditorTextView!
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var outputTextView: OutputTextView!
    @IBOutlet var outputScrollView: NSScrollView!
    @IBOutlet private weak var outputButton: NSButton!
    @IBOutlet private weak var clearOutputButton: NSButton!
    @IBOutlet private weak var baseApplication: NSPopUpButton!
    @IBOutlet private weak var snippets: NSPopUpButton!

    @IBOutlet private weak var projectIcon: NSButton!
    
    // MARK: - Managers
    var documentManager: DocumentManager!
    var projectManager: ProjectManager!
    var themeManager: ThemeManager!
    private var updateManager: UpdateManager!
    private var statusManager: StatusManager!

    // MARK: - Class Private Properties
    private var gutterView: LineNumberGutterView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Managers that don’t depend on window
        documentManager = DocumentManager(editor: codeEditorTextView, outputTextView: outputTextView)
        documentManager.delegate = self
        projectManager = ProjectManager()
        projectManager.delegate = self
        statusManager = StatusManager(editor: codeEditorTextView, statusLabel: statusLabel)
        
        setupObservers()
        setupEditor()
        
        if let menu = NSApp.mainMenu {
            populateOpenRecentMenu(menu: menu)
            populateTemplateMenu(menu: menu)
        }
        
        populateSnippetsMenu()
        
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

        themeManager.applySavedTheme()
        registerWindowFocusObservers()
        refreshBaseApplicationMenu()
        
        let lastOpenedFile = Settings.shared.lastOpenedFile
        if FileManager.default.fileExists(atPath: Settings.shared.lastOpenedProjectFile) {
            projectManager.openProject(at: URL(fileURLWithPath: Settings.shared.lastOpenedProjectFile))
        } else {
            FileManager
                .default
                .changeCurrentDirectoryPath(
                    UserDefaults
                        .standard
                        .string(forKey: "location") ?? FileManager
                        .default
                        .homeDirectoryForCurrentUser
                        .appendingPathComponent("Xprime/Projects")
                        .path
                )
        }
        
        if FileManager.default.fileExists(atPath: lastOpenedFile) {
            documentManager.openDocument(at: URL(fileURLWithPath: lastOpenedFile))
        }
        
        updateManager.checkForAvaliableUpdates()
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
        refreshProjectIconImage()
        updateWindowDocumentIcon()
        refreshBaseApplicationMenu()
    }
    
    @objc private func windowDidResignKey() {
        // window lost focus
#if Debug
        print("Window lost focus")
#endif
    }

    // MARK: - Snippets
    private func populateSnippetsMenu() {
        let url = Bundle.main.resourceURL!.appendingPathComponent("Developer/Library/Xprime/Snippets")
        let menu = NSMenu()
        
        let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        contents?.forEach { itemURL in
            if itemURL.isDirectory == false {
                let snippet = loadSnippet(at: itemURL)
                
                let menuItem = NSMenuItem(
                    title: snippet.trigger,
                    action: #selector(snippetSelected(_:)),
                    keyEquivalent: ""
                )
                menuItem.subtitle = snippet.title
                menuItem.representedObject = itemURL
                menuItem.image = NSImage(named: "hpppl")?.copy() as? NSImage
                menuItem.image?.size = NSSize(width: 22, height: 22)
                menu.addItem(menuItem)
            }
        }
        
        snippets.menu = menu
    }
    
    @objc private func snippetSelected(_ sender: NSMenuItem) {
        
        codeEditorTextView.insertText("$\(sender.title)", replacementRange: codeEditorTextView.selectedRange())
    }
    
    private func loadSnippet(at file: URL) -> (title: String, trigger: String) {
        let decoder = JSONDecoder()
        
        guard let data = try? Data(contentsOf: file),
                let json = try? decoder.decode(JSONSnippet.self, from: data) else { return (file.deletingPathExtension().lastPathComponent, file.deletingPathExtension().lastPathComponent) }
        
        let trigger = file.deletingPathExtension().lastPathComponent
        return (json.title, trigger)
    }
    
    // MARK: - Templates
    private func populateTemplateMenu(menu: NSMenu) {
        let url = Bundle.main.resourceURL!.appendingPathComponent("Developer/Library/Xprime/Templates/File Templates")
        menu.item(withTitle: "Edit")?.submenu?.item(withTitle: "Template")?.submenu = populateTemplateMenu(url: url)
    }
    
    private func populateTemplateMenu(url: URL) -> NSMenu {
        let menu = NSMenu()
        
        let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        contents?.forEach { itemURL in
            if itemURL.isDirectory {
                let submenu = populateTemplateMenu(url: itemURL)

                let submenuItem = NSMenuItem(
                    title: itemURL.lastPathComponent,
                    action: nil,
                    keyEquivalent: ""
                )
                submenuItem.submenu = submenu
                submenuItem.image = NSImage(named: NSImage.folderName)
                submenuItem.image?.size = NSSize(width: 16, height: 16)
                menu.addItem(submenuItem)
            } else {
                let name = itemURL.deletingPathExtension().lastPathComponent

                let menuItem = NSMenuItem(
                    title: name,
                    action: #selector(templateSelected(_:)),
                    keyEquivalent: ""
                )
                menuItem.representedObject = itemURL
                menuItem.image = NSImage(named: "hpppl")?.copy() as? NSImage
                menuItem.image?.size = NSSize(width: 22, height: 22)
                menu.addItem(menuItem)
            }
        }

        return menu
    }
    
    @objc private func templateSelected(_ sender: NSMenuItem) {
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
        
        let url = Bundle.main.bundleURL
            .appendingPathComponent(templatesBasePath)
            .appendingPathComponent(traceMenuItem(sender))
            .appendingPathComponent(sender.title)
            .appendingPathExtension("prgm")
        
        if let contents = HPServices.loadHPPrgm(at: url) {
            codeEditorTextView.registerUndo(actionName: "Template")
            if let selectedRange = codeEditorTextView.selectedRanges.first as? NSRange {
                if let textStorage = codeEditorTextView.textStorage {
                    textStorage.replaceCharacters(in: selectedRange, with: contents)
                    codeEditorTextView.setSelectedRange(NSRange(location: selectedRange.location + contents.count, length: 0))
                }
            }
            codeEditorTextView.applySyntaxHighlighting()
        }
    }
    
    private func populateOpenRecentMenu(menu: NSMenu) {
        guard let submenu = menu.item(withTitle: "File")?.submenu?.item(withTitle: "Open Recent")?.submenu else { return }

        submenu.removeAllItems()
    
        let icon = NSImage(named: "Icon")?.copy() as? NSImage
        let pythonIcon = NSImage(named: "Python")?.copy() as? NSImage

        for path in Settings.shared.recentFiles {
            if FileManager.default.fileExists(atPath: path) == false {
                continue
            }
            let name = URL(fileURLWithPath: path).lastPathComponent
            
            let menuItem = NSMenuItem(
                title: name,
                action: #selector(handleOpenRecent(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self   // Important so the selector fires
            menuItem.representedObject = URL(fileURLWithPath: path)
            if path.hasSuffix(".xprimeproj") == true {
                let url = URL(fileURLWithPath: path)
                
                if url.deletingPathExtension().appendingPathExtension("hpappdir").isDirectory == true {
                    menuItem.image = NSImage(contentsOf: url
                        .deletingPathExtension()
                        .appendingPathExtension("hpappdir")
                        .appendingPathComponent("icon.png")
                    )?.copy() as? NSImage
                } else {
                    menuItem.image = icon
                }
            } else {
                let url = URL(fileURLWithPath: path)
                
                switch url.pathExtension.lowercased() {
                    case "py":
                    menuItem.image = pythonIcon
                        case "note", "md", "ntf":
                        menuItem.image = NSImage(named: "Notes")?.copy() as? NSImage
                default:
                    menuItem.image = icon
                    break
                }
            }
            menuItem.image?.size = NSSize(width: 16, height: 16)
            submenu.addItem(menuItem)
        }
        
        submenu.addItem(NSMenuItem.separator())
        submenu.addItem(NSMenuItem(title: "Clear Menu", action: Settings.shared.recentFiles.count != 0 ? #selector(clearRecentMenu) : nil, keyEquivalent: ""))
    }
    
    private func appendToRecentMenu(url: URL) {
        let recentLimit = 10
      
        let path = url.path

        var recents = Settings.shared.recentFiles

        // Remove duplicates (so the item can move to the top)
        recents.removeAll { $0 == path }

        // Insert most-recent at the top
        recents.insert(path, at: 0)

        // Enforce max limit
        if recents.count > recentLimit {
            recents = Array(recents.prefix(recentLimit))
        }

        Settings.shared.recentFiles = recents

        if let menu = NSApp.mainMenu {
            populateOpenRecentMenu(menu: menu)
        }
    }
    
    @objc private func clearRecentMenu(_ sender: NSMenuItem) {
        Settings.shared.recentFiles.removeAll()
        if let menu = NSApp.mainMenu {
            populateOpenRecentMenu(menu: menu)
        }
    }
    
    @objc private func handleOpenRecent(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        
        if let url = documentManager.currentDocumentURL, documentManager.documentIsModified {
            AlertPresenter.presentYesNo(
                on: view.window,
                title: "Save Changes",
                message: "Do you want to save changes to '\(url.lastPathComponent)' before opening another document",
                primaryActionTitle: "Save"
            ) { confirmed in
                if confirmed {
                    self.documentManager.saveDocument()
                    if url.lastPathComponent.hasSuffix(".xprimeproj") {
                        self.projectManager.openProject(at: url)
                    } else {
                        self.documentManager.openDocument(at: url)
                    }
                } else {
                    return
                }
            }
        } else {
            if url.lastPathComponent.hasSuffix(".xprimeproj") {
                self.projectManager.openProject(at: url)
            } else {
                self.documentManager.openDocument(at: url)
            }
        }
    }
    
    // MARK:- Base Application
    private func refreshBaseApplicationMenu() {
        guard let menu = baseApplication.menu else { return }
        let baseApplicationName = projectManager.baseApplicationName
        
        for item in menu.items {
            item.image?.size = NSSize(width: 18, height: 18)
            if item.title == baseApplicationName {
                item.state = .on
                baseApplication.select(item)
            } else {
                item.state = .off
            }
        }
        baseApplication.isEnabled = documentManager.currentDocumentURL != nil
    }
    
    private func configureBaseApplicationAction() {
        baseApplication.target = self
        baseApplication.action = #selector(preferBaseApplicationSelection(_:))
        
        guard let menu = baseApplication.menu else { return }
        for item in menu.items {
            item.image?.size = NSSize(width: 18, height: 18)
        }
    }
    
    // MARK: - Base Application Action Handler
    @objc func preferBaseApplicationSelection(_ sender: NSMenuItem) {
        guard let projectDirectoryURL = projectManager.projectDirectoryURL else { return }
        guard let name = projectManager.projectName else { return }
        
        
        if projectDirectoryURL.appendingPathComponent("\(name).hpappdir").isDirectory {
            outputTextView.appendTextAndScroll("⚠️ Changing base application \"\(projectManager.baseApplicationName)\" to \"\(sender.title)\".\n")
        } else {
            outputTextView.appendTextAndScroll("🔨 Creating application directory\n")
        }
        
        try? HPServices.resetHPAppContents(at: projectDirectoryURL, named: name, fromBaseApplicationNamed: sender.title)
        outputTextView.appendTextAndScroll("Base application is \"\(projectManager.baseApplicationName)\"\n")
        
        
        refreshQuickOpenToolbar()
        refreshProjectIconImage()
        updateWindowDocumentIcon()
    }
    
    // MARK: - Helper Functions
    private func updateWindowDocumentIcon() {
        guard let window = view.window else { return }
    
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = true
        
        if let projectName = projectManager.projectName {
            window.title = projectName
            window.representedURL = documentManager.currentDocumentURL
            // Re-apply icon AFTER AppKit finishes layout
            DispatchQueue.main.async {
                window.standardWindowButton(.documentIconButton)?.image = self.projectIcon.image
            }
            return
        }
        
        if let url = documentManager.currentDocumentURL {
            window.title = url.lastPathComponent
            window.representedURL = url
        } else {
            window.title = "Untitled"
            window.representedURL = nil
        }
            
        // Re-apply icon AFTER AppKit finishes layout
        DispatchQueue.main.async {
            let url = Bundle.main.url(
                forResource: "icon",
                withExtension: "png",
                subdirectory: "Developer/Library/Xprime/Templates/Application Template"
            )!
            window.standardWindowButton(.documentIconButton)?.image = NSImage(contentsOfFile: url.path)!
        }
    }

    private func loadAppropriateGrammar(forType fileExtension: String) {
        let grammar:[String : [String]] = [
            ".hppplplus": ["hppplplus", "ppl+"],
            ".hpppl": ["hpppl", "ppl", "hpprgm", "hpappprgm", "bmp", "png", "h"],
            ".py": ["py"],
            ".ntf": ["hpnote", "hpappnote", "ntf"],
            ".md": ["md"]
        ]
        
        for (grammarName, ext) in grammar where ext.contains(fileExtension.lowercased()) {
            codeEditorTextView.loadGrammar(named: grammarName)
            return
        }
    }
    
    private func refreshProjectIconImage() {
        guard let currentDirectoryURL = projectManager.projectDirectoryURL else {
            let url = Bundle.main.url(
                forResource: "icon",
                withExtension: "png",
                subdirectory: "Developer/Library/Xprime/Templates/Application Template"
                )!
            projectIcon.image = NSImage(contentsOfFile: url.path)!
            return
        }
        guard let projectURL = ProjectManager.projectURL(in: currentDirectoryURL) else { return }
      
        let urlsToCheck: [URL] = [
            projectURL
                .deletingPathExtension()
                .appendingPathExtension("hpappdir")
                .appendingPathComponent("icon.png"),
            Bundle.main.url(
                forResource: "icon",
                withExtension: "png",
                subdirectory: "Developer/Library/Xprime/Templates/Application Template"
            )!
        ]
        
        if let existingURL = urlsToCheck.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            let targetSize = NSSize(width: 38, height: 38)
            
            if let image = NSImage(contentsOf: existingURL) {
                image.size = targetSize
                projectIcon.image = image
            }
        }
    }
    
    private func mainURL(in directoryURL: URL) -> URL? {
        for main in [
            "main.hpppl",
            "main.hppplplus",
            "main.pas",
            "main.prgm",
            "main.prgm+",
            "main.ppl",
            "main.ppl+"
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
            AlertPresenter.showInfo(on: view.window, title: "Build Failed", message: "Unable to find main.hpppl or main.hppplplus file.")
            return
        }
        guard let projectName = projectManager.projectName else { return }
        
        let destinationURL = url
            .appendingPathComponent("\(projectName).hpprgm")

        let result = HPServices.preProccess(at: sourceURL, to: destinationURL,  compress: ProjectSettings.shared.compression)
        outputTextView.appendTextAndScroll(result.err ?? "")
    }
    
    private func buildApplication() {
        guard let url = projectManager.projectDirectoryURL else { return }
        guard let sourceURL = mainURL(in: url) else {
            AlertPresenter.showInfo(on: view.window, title: "Archive Build Failed", message: "Unable to find main.hpppl or main.hppplplus file.")
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
                                            compress: ProjectSettings.shared.compression
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
        
        if dirA.isNewer(than: dirB), ProjectSettings.shared.archiveProjectAppOnly == false {
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
    
    // MARK: - Xprime `uses` support to PPL+ for importing Apps used by Program/App
    private func processUses(in text: String) -> (cleaned: String, units: [String]) {
        // Matches: uses A, B, C;
        // Also supports multiline uses blocks
        let pattern = #"(?is)\buses\s+([^;]+);"#
        let regex = try! NSRegularExpression(pattern: pattern)

        var units: [String] = []
        var cleanedText = text

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches.reversed() {
            // Capture group: everything between 'uses' and ';'
            if let range = Range(match.range(at: 1), in: text) {
                let usesBody = text[range]

                // Split by commas and trim whitespace/newlines
                let extracted = usesBody
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                units.append(contentsOf: extracted)
            }

            // Remove the entire uses ...; block
            if let fullRange = Range(match.range, in: cleanedText) {
                cleanedText.removeSubrange(fullRange)
            }
        }
        
        cleanedText = cleanedText
            .replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (cleaned: cleanedText, units: units)
    }
    
    private func installRequiredUnits(units: [String]) {
        let basePath = ToolchainPaths.developerRoot
            .appendingPathComponent("usr")
            .appendingPathComponent("hpappdir")

        for unit in units {
            if HPServices.hpAppDirectoryIsInstalled(named: unit) {
                continue
            }
            let fileURL = basePath
                .appendingPathComponent(unit)
                .appendingPathExtension("hpappdir")

            do {
                try HPServices.installHPAppDirectory(at: fileURL)
                outputTextView.appendTextAndScroll("Installed: \"\(unit)\"\n")
            } catch {
                outputTextView.appendTextAndScroll("Error installing \"\(unit)\": \(error)\n")
            }
        }
    }
    
    // MARK: -
    @objc private func quickOpen(_ sender: NSMenuItem) {
        guard let projectDirectoryURL = projectManager.projectDirectoryURL else {
            return
        }
       
        if let url = documentManager.currentDocumentURL, FileManager.default.fileExists(atPath: url.path), documentManager.documentIsModified {
            AlertPresenter.presentYesNo(
                on: view.window,
                title: "Save Changes",
                message: "Do you want to save changes to '\(url.lastPathComponent)' before opening another document",
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
        
        switch documentManager.currentDocumentURL?.pathExtension.lowercased() {
        case "hpppl":
            comboButton.image = NSImage(named: "hpppl")?.copy() as? NSImage
            comboButton.image?.size = NSSize(width: 24, height: 24)
        default:
            comboButton.image = sender.image
        }
        
    }
    
    private func refreshQuickOpenToolbar() {
        guard
            let toolbar = view.window?.toolbar,
            let item = toolbar.items.first(where: {
                $0.paletteLabel == "Quick Open"
            }),
            let comboButton = item.view as? NSComboButton
        else {
            return
        }
        
        guard let url = projectManager.projectDirectoryURL else {
            let menu = NSMenu()
            comboButton.menu = menu
            comboButton.image = nil
            comboButton.title = ""
            comboButton.action = nil
            return
        }
        

        let menu = NSMenu()
        
        let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        let python = NSImage(named: "py")?.copy() as! NSImage
        let hpnote = NSImage(named: "hpnote")?.copy() as! NSImage
        let file = NSImage(named: "file")?.copy() as! NSImage
        let hpppl = NSImage(named: "hpppl")?.copy() as! NSImage
        let hppplplus = NSImage(named: "hppplplus")?.copy() as! NSImage
        let h = NSImage(named: "h")?.copy() as! NSImage
        let bmp = NSImage(named: "bmp")?.copy() as! NSImage
        let png = NSImage(named: "png")?.copy() as! NSImage
        
        contents?
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == false }
            .forEach { url in
                if url.pathExtension == "hpppl" ||
                   url.pathExtension == "hppplplus" ||
                   url.pathExtension == "ppl" ||
                   url.pathExtension == "ppl+" ||
                   url.pathExtension == "py"  ||
                   url.pathExtension == "ntf" ||
                   url.pathExtension == "bmp" ||
                   url.pathExtension == "png" ||
                   url.pathExtension == "h"
                {
                    menu.addItem(
                        withTitle: url.lastPathComponent,
                        action: #selector(quickOpen(_:)),
                        keyEquivalent: ""
                    )
                
                    switch url.pathExtension.lowercased() {
                    case "hppplplus", "hpppl+":
                        menu.items.last?.image = hppplplus
                        
                    case "hpnote", "ntf":
                        menu.items.last?.image = hpnote
                        
                    case "py":
                        menu.items.last?.image = python
                        
                    case "h":
                        menu.items.last?.image = h
                        
                    case "hpppl":
                        menu.items.last?.image = hpppl
                        
                    case "bmp":
                        menu.items.last?.image = bmp
                        
                    case "png":
                        menu.items.last?.image = png
                    
                    default:
                        menu.items.last?.image = file
                    }
                    
                    menu.items.last?.image?.size = NSSize(width: 22, height: 22)
                    if url == documentManager.currentDocumentURL {
                        menu.items.last?.state = .on
                        comboButton.image = menu.items.last?.image
                        comboButton.image?.size = NSSize(width: 22, height: 22)
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
    @IBAction private func newDocument(_ sender : Any) {
        if let url = documentManager.currentDocumentURL, documentManager.documentIsModified {
            AlertPresenter.presentYesNo(
                on: view.window,
                title: "Save Changes",
                message: "Do you want to save changes to '\(url.lastPathComponent)' before creating another document",
                primaryActionTitle: "Save"
            ) { confirmed in
                if confirmed {
                    self.documentManager.saveDocument()
                    self.proceedWithNewDocument()
                } else {
                    return
                }
            }
        } else {
            proceedWithNewDocument()
        }
    }
    
    @IBAction private func addFilesTo(_ sender : Any) {
        let panel = NSOpenPanel()
        
        panel.prompt = "Add"
        panel.title = ""
        panel.directoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        panel.allowedContentTypes = [
            UTType(filenameExtension: "bmp")!,
            UTType(filenameExtension: "png")!,
            UTType.cHeader
        ]
        for `extension` in Settings.shared.supportedDocumentExtensions {
            let allowedType = UTType(filenameExtension: `extension`)!
            panel.allowedContentTypes.append(allowedType)
        }
        
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
    
    
    private func proceedWithNewDocument() {
        let panel = NSSavePanel()
        
        panel.title = ""
        panel.directoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        for type in Settings.shared.supportedDocumentExtensions {
            panel.allowedContentTypes.append(UTType(filenameExtension: type)!)
        }
        
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            self.documentManager.closeDocument()
            self.documentManager.saveDocument(to: url)
            self.documentManager.openDocument(at: url)
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
        for type in Settings.shared.allowedOpenFileExtensions {
            panel.allowedContentTypes.append(UTType(filenameExtension: type)!)
        }
        
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            
            if url.lastPathComponent.hasSuffix(".xprimeproj") {
                self.projectManager.openProject(at: url)
            } else {
                self.documentManager.openDocument(at: url)
            }
        }
    }
    
    @IBAction func openDocument(_ sender: Any) {
        if let url = documentManager.currentDocumentURL, FileManager.default.fileExists(atPath: url.path), documentManager.documentIsModified {
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
        guard let url = documentManager.currentDocumentURL else {
            proceedWithSavingDocumentAs()
            return
        }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            proceedWithSavingDocumentAs()
            return
        }
        documentManager.saveDocument()
    }
    
    @IBAction func closeDocument(_ sender: Any) {
        documentManager.closeDocument()
    }
    
    @IBAction func closeProject(_ sender: Any) {
        projectManager.closeProject()
    }
    
    // MARK: - Saving Document As
    private func proceedWithSavingDocumentAs() {
        var allowedContentTypes: [UTType] = []
        
        for type in Settings.shared.allowedSaveFileExtensions {
            allowedContentTypes.append(UTType(filenameExtension: type)!)
        }
        documentManager.saveDocumentAs(
            allowedContentTypes: allowedContentTypes,
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
        let command = ToolchainPaths.bin + "/hpnote"
        var arguments: [String] = [
            sourceURL.path,
            "-o",
            destinationURL.path
        ]
        if ProjectSettings.shared.plainFallbackText == true {
            arguments.append("--plain-fallback")
        }
        
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
        
        installRequiredUnits(units: processUses(in: codeEditorTextView.string).units)
       
        if projectManager.isProjectApplication {
            buildApplication()
            installHPAppDirectoryToCalculator()
        } else {
            buildProgram()
            installHPPrgmFileToCalculator()
        }
    }
    
    private func installHPPrgmFileToCalculator() {
        guard let currentDirectoryURL = projectManager.projectDirectoryURL else { return }
        guard let projectName = projectManager.projectName else { return }
        
        let programURL = currentDirectoryURL
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpprgm")
        outputTextView.appendTextAndScroll("Installing: \(programURL.lastPathComponent)\n")
        do {
            try HPServices.installHPPrgm(at: programURL, forUser: ProjectSettings.shared.calculator)
            
            if let projectName = projectManager.projectName, HPServices.hpPrgmIsInstalled(named: projectName) {
                outputTextView.appendTextAndScroll("✅ Successfully re-installed \"\(programURL.lastPathComponent)\" \n")
            } else {
                outputTextView.appendTextAndScroll("✅ Successfully installed \"\(programURL.lastPathComponent)\" \n")
            }
        } catch {
            AlertPresenter.showInfo(
                on: self.view.window,
                title: "Installing Failed",
                message: "Installing file: \(error)"
            )
            return
        }
    }
    
    private func installHPAppDirectoryToCalculator() {
        guard let currentDirectoryURL = projectManager.projectDirectoryURL else { return }
        guard let projectName = projectManager.projectName else { return }
        
        let appDirURL = currentDirectoryURL
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpappdir")
        outputTextView.appendTextAndScroll("Installing: \(appDirURL.lastPathComponent)\n")
        do {
            try HPServices.installHPAppDirectory(at: appDirURL, forUser: ProjectSettings.shared.calculator)
            
            if let projectName = projectManager.projectName, HPServices.hpAppDirectoryIsInstalled(named: projectName) {
                outputTextView.appendTextAndScroll("✅ Successfully re-installed \"\(appDirURL.lastPathComponent)\" \n")
            } else {
                outputTextView.appendTextAndScroll("✅ Successfully installed \"\(appDirURL.lastPathComponent)\" \n")
            }
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
        
        if !projectManager.isProjectApplication {
            buildProgram()
        } else {
            buildApplication()
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
        guard let url = HPServices.hpPrimeDirectory(forUser: ProjectSettings.shared.calculator) else {
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
        
        let contents = ProcessRunner.run(executable: URL(fileURLWithPath: ToolchainPaths.bin + "/hpppl+"), arguments: [currentURL.path, "--reformat", "-o", "/dev/stdout"])
        if let out = contents.out, !out.isEmpty {
            codeEditorTextView.string = out
        }
        self.outputTextView.appendTextAndScroll(contents.err ?? "")
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
            if let _ = documentManager.currentDocumentURL, ext == "prgm" || ext == "appprgm" || ext == "hpppl" {
                return true
            }
            return false
        
            
        case #selector(run(_:)), #selector(archive(_:)), #selector(build(_:)), #selector(buildForRunning(_:)):
            if projectManager.projectDirectoryURL != nil   {
                return true
            }
            return false
            
        case #selector(templateSelected(_:)):
            if ext == "prgm" || ext == "appprgm" || ext == "hpprgm" || ext == "hpappprgm" || ext == "hpppl" || ext == "hppplplus" {
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
            
        case #selector(addFilesTo(_:)):
            if projectManager.projectDirectoryURL != nil, let projectName = projectManager.projectName {
                menuItem.title = "Add Files to \"\(projectName)\"…"
                return true
            }
            menuItem.title = "Add Files to \"\"…"
            return false
            
        case #selector(closeDocument(_:)):
            if let currentDocumentURL = documentManager.currentDocumentURL {
                menuItem.title = "Close \"\(currentDocumentURL.lastPathComponent)\""
                menuItem.isHidden = false
                return true
            }
            menuItem.isHidden = true
            return false
            
            
        case #selector(closeProject(_:)):
            if let _ = projectManager.projectDirectoryURL {
                return true
            }
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
        } else {
            loadAppropriateGrammar(forType:URL(fileURLWithPath: Settings.shared.lastOpenedFile).pathExtension.lowercased())
        }
        
        gutterView.updateLines()
        
        refreshProjectIconImage()
        refreshQuickOpenToolbar()
        if let url = documentManager.currentDocumentURL, url.pathExtension.lowercased() == "hpppl" || url.pathExtension.lowercased() == "hppplplus" {
            snippets.isEnabled = true
        } else {
            snippets.isEnabled = false
        }
        updateWindowDocumentIcon()
    }
    
    func documentManager(_ manager: DocumentManager, didFailToOpen error: Error) {
#if Debug
        print("Open failed:", error)
#endif
    }
    
    func documentManagerDidClose(_ manager: DocumentManager) {
        codeEditorTextView.string = ""
        
        refreshProjectIconImage()
        refreshQuickOpenToolbar()
        
        updateWindowDocumentIcon()
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
        
        FileManager.default.changeCurrentDirectoryPath(projectDirectoryURL.path)
        if let url = mainURL(in: projectDirectoryURL) {
            documentManager.openDocument(at: url)
        }
        
        refreshProjectIconImage()
        refreshBaseApplicationMenu()
        
        updateWindowDocumentIcon()
    
        if let projectURL = ProjectManager.projectURL(in: projectDirectoryURL) {
            appendToRecentMenu(url: projectURL)
        }
    }
    
    func projectManager(_ manager: ProjectManager, didFailToOpen error: any Error) {
        AlertPresenter.showInfo(
            on: self.view.window,
            title: "Opening Project Failed",
            message: "\(error)"
        )
    }
    
    func projectManagerDidClose(_ manager: ProjectManager) {
        documentManager.closeDocument()
        
        refreshProjectIconImage()
        refreshQuickOpenToolbar()
        refreshBaseApplicationMenu()
        
        updateWindowDocumentIcon()
    }
}
