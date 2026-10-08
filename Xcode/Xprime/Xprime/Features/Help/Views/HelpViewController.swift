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

import WebKit
import Cocoa


final class HelpViewController: CustomViewController, NSComboBoxDelegate, NSTextFieldDelegate {
    @IBOutlet weak var catalog: NSPopUpButton!
    @IBOutlet weak var html: WKWebView!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateCatalogMenu()
        
        loadHelp(for: Help.shared.lastOpenedCatalogHelpFile)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard let window = view.window else { return }
        window.level = .modalPanel
    }
    
    private func loadHelp(for command: String) {
        let filename = command.percentEncoded()

        guard let url = URL(string: "http://insoft.uk/docs/hpprime/catlg/\(filename).txt") else {
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try String(contentsOf: url, encoding: .utf8)

                let html = """
                    <style>
                        body {
                            font-family: "Arial";
                            font-size: 10pt;
                            white-space: pre-wrap;
                            overflow: scroll;
                            margin: 0;
                            padding: 0;
                            line-height: 1.5;
                        }
                    </style>
                    <body>\(result)</body>
                    """

                DispatchQueue.main.async {
                    self.html.loadHTMLString(html, baseURL: nil)
                }

            } catch {
                print("Failed to load help: \(error)")
            }
        }
    }
    
    
    private func populateCatalogMenu() {
        let menu = NSMenu()
        
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
        
        if let url = Bundle.main.url(
            forResource: "catlg",
            withExtension: "txt",
            subdirectory: "Help"
        ) {
            do {
                let contents = try String(contentsOf: url, encoding: .utf8)
                
                for line in contents.components(separatedBy: .newlines) {
                    let name = line
                    let menuItem = NSMenuItem(
                        title: name,
                        action: #selector(catalogSelected(_:)),
                        keyEquivalent: ""
                        
                    )
                    
                    menuItem.image = NSImage(named: "HPPrimeFunction")?.copy() as? NSImage
                    
                    if keywords.contains(name) {
                        menuItem.image = NSImage(named: "HPPPLKeyword")?.copy() as? NSImage
                    }
                    if builtins.contains(name) {
                        menuItem.image = NSImage(named: "HPPPLFunction")?.copy() as? NSImage
                    }
                    
                    if symbols.contains(name) {
                        menuItem.image = NSImage(named: "Code")?.copy() as? NSImage
                    }
                    
                    menuItem.image?.size = Constants.IconSizes.small
                    menuItem.representedObject = url as NSURL
                    menu.addItem(menuItem)
                }
            } catch {
                print("Failed to read file: \(error)")
            }
        }
        
        menu.item(withTitle: Help.shared.lastOpenedCatalogHelpFile)?.state = .on
        self.catalog.menu = menu
    }
    
    @objc private func catalogSelected(_ sender: NSMenuItem) {
        loadHelp(for: sender.title)
        Help.shared.lastOpenedCatalogHelpFile = sender.title
    }
    
    @IBAction func close(_ sender: Any) {
        self.view.window?.close()
    }
}

