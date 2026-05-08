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


final class CatalogViewController: CustomViewController, NSComboBoxDelegate, NSTextFieldDelegate {
    @IBOutlet weak var catalogHelpTextView: CatalogHelpTextView!
    @IBOutlet weak var catalog: NSPopUpButton!
    @IBOutlet weak var search: NSTextField!
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateCatalogMenu()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(searchTextDidChange(_:)),
                                               name: NSControl.textDidChangeNotification,
                                               object: search)
        loadHelp(for: Catalog.shared.lastOpenedCatalogHelpFile)
        search.stringValue = Catalog.shared.lastOpenedCatalogHelpFile
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
//        guard let window = view.window else { return }
//        window.title = "Catalog"
//        window.level = .floating
//        window.titleVisibility = .visible
//        window.minSize = window.frame.size
//        window.backgroundColor = NSColor(white: 0.125, alpha: 0.95)
//        window.styleMask.insert(.fullSizeContentView)
        
        // Re-apply icon AFTER AppKit finishes layout
//        DispatchQueue.main.async {
//            let url = Bundle.main.url(
//                forResource: "icon",
//                withExtension: "png",
//                subdirectory: "Developer/Library/Xprime/Templates/Application Template"
//            )!
//            window.representedURL = url
//            window.standardWindowButton(.documentIconButton)?.image = NSImage(contentsOfFile: url.path)!
//        }
    }

    private func loadHelp(for command: String) {
        guard let txtURL = Bundle.main.url(forResource: command, withExtension: "txt", subdirectory: "Help") else {
            // ⚠️ No .txt file found.
            catalogHelpTextView.string = ""
            return
        }
        
        do {
            let text = try String(contentsOf: txtURL, encoding: .utf8)
            catalogHelpTextView.changeText(text)

            catalogHelpTextView.highlightBold("Syntax:")
            catalogHelpTextView.highlightBold("Example:")
            catalogHelpTextView.highlightBold("Note:")
        } catch {
            // Failed to read RTF contents. Clear the view and optionally log.
            catalogHelpTextView.string = ""
            #if DEBUG
            NSLog("Failed to load RTF for command \(command): \(error.localizedDescription)")
            #endif
        }
    }
    
    
    
    func handleInput(_ text: String) {
        guard let file = searchCatalog(text) else { return }
        loadHelp(for: file)
        Catalog.shared.lastOpenedCatalogHelpFile = file
    }
    
    
    
    private func searchCatalog(_ text: String) -> String? {
        guard !text.isEmpty,
              let items = self.catalog.menu?.items.map({ $0.title }),
              !items.isEmpty else {
            return nil
        }

        return items.first { $0.localizedCaseInsensitiveContains(text) }
    }
    
    
    
    private func populateCatalogMenu() {
        let menu = NSMenu()
        
        guard let resourceURLs = Bundle.main.urls(
            forResourcesWithExtension: "txt",
            subdirectory: "Help"
        ) else {
            return
        }
        
        let keywords: Set<String> = [
            "BEGIN", "END",
            "IF", "THEN", "ELSE", "CASE",
            "FOR", "FROM", "TO", "STEP", "DO",
            "WHILE", "REPEAT", "UNTIL",
            "BREAK", "CONTINUE", "RETURN",
            "IFERR", "KILL", "DEFAULT",
            "AND", "OR", "NOT", "XOR", "MOD",
            "LOCAL", "EXPORT", "CONST", "KEY", "VIEW"
        ]
        
        let builtins: Set<String> = [
            "RECT_P", "RECT", "LINE_P", "LINE", "ARC_P",
            "ARC", "PIXON_P", "PIXON", "PIXOFF_P", "PIXOFF",
            "GETPIX_P", "GETPIX", "TEXTOUT_P", "TEXTOUT",
            "TEXTSIZE", "DIMGROB_P", "DIMGROB", "BLIT_P",
            "BLIT", "STRBLIT", "TRIANGLE_P", "TRIANGLE",
            "FILLPOLY_P", "FILLPOLY", "GROBW_P", "GROBW",
            "GROBH_P", "GROBH", "DRAWMENU", "FREEZE", "WAIT",
            "RGB", "GETKEY", "MOUSE", "PRINT", "INPUT", "CHOOSE",
            "MSGBOX", "EDITMAT", "EDITLIST", "STARTVIEW",
            "STARTAPP", "ABS", "CEIL", "FLOOR", "ROUND", "IP",
            "FP", "SIGN", "MAX", "MIN", "MOD", "SIN", "COS",
            "TAN", "ASIN", "ACOS", "ATAN", "LN", "LOG", "EXP",
            "SQRT", "SQ", "SIZE", "DIM", "MAKEMAT", "MAKELIST",
            "ADDROW", "ADDCOL", "REPLACE", "SUPPRESS", "APPEND",
            "CONCAT", "POS", "SORT", "REVERSE", "CROSS", "DOT",
            "ROUND", "l2norm", "rowDim", "colDim", "subMat", "LEFT",
            "RIGHT", "MID", "INSTRING", "DIM", "ASC", "CHAR",
            "LOWER", "UPPER", "TRIM", "ROTATE", "STRING", "EXPR",
            "IFTE", "TYPE", "TICKS", "PYTHON", "AFiles", "Theme", "BITAND",
            "BITOR", "BITNOT", "BITSL", "BITSR"
        ]
        
        let symbols: Set<String> = [
            "!", "%", "(", "*", "+", "+", "-", ".*", ".+", ".-", "./", ".^", "/", ":=",
            "<", "<=", "<>", ">", ">=", "^", "|"
        ]
        
        let catalog = resourceURLs
            .map { $0.deletingPathExtension().lastPathComponent.customPercentDecoded() }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        for name in catalog {
            if let url = Bundle.main.url(
                forResource: name.customPercentEncoded(),
                withExtension: "txt",
                subdirectory: "Help"
            ) {
                let menuItem = NSMenuItem(
                    title: name,
                    action: #selector(catalogSelected(_:)),
                    keyEquivalent: ""
                    
                )
                menuItem.image = NSImage(named: "function")?.copy() as? NSImage
                
                if keywords.contains(name) {
                    menuItem.image = NSImage(named: "keyword")?.copy() as? NSImage
                }
                if builtins.contains(name) {
                    menuItem.image = NSImage(named: "builtin")?.copy() as? NSImage
                }
                
                if symbols.contains(name) {
                    menuItem.image = NSImage(named: "code")?.copy() as? NSImage
                }
                
                menuItem.image?.size = NSSize(width: 18, height: 18)
                menuItem.representedObject = url as NSURL
                menu.addItem(menuItem)
            }
        }
        menu.item(withTitle: Catalog.shared.lastOpenedCatalogHelpFile)?.state = .on
        self.catalog.menu = menu
    }
    
    @objc private func catalogSelected(_ sender: NSMenuItem) {
        if let url = sender.representedObject as? URL {
            loadHelp(for: url.deletingPathExtension().lastPathComponent)
        }
    }
    
    @objc private func searchTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else { return }

        let text = textField.stringValue
        handleInput(text)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSControl.textDidChangeNotification, object: search)
    }
    
    @IBAction func close(_ sender: Any) {
        self.view.window?.close()
    }
}

