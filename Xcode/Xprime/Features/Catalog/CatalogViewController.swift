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


final class CatalogViewController: NSViewController {
    @IBOutlet weak var catalogComboButton: NSComboButton!

    @IBOutlet weak var catalogHelpTextView: CatalogHelpTextView!
    private var catalog: [String] = []
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let resourceURLs = Bundle.main.urls(forResourcesWithExtension: "rtf", subdirectory: "Help") else {
            return
        }
        
        for fileURL in resourceURLs {
            let command = fileURL.deletingPathExtension().lastPathComponent
            catalog.append(command)
        }
        
        catalog.sort {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
        
        populateCatalogComboButtonMenu()
    }
    
    @IBAction private func searchCatalog(_ sender: NSSearchField) {
        if sender.stringValue.isEmpty {
            return
        }
        
        if let match = catalog.first(where: {
            $0.localizedCaseInsensitiveContains(sender.stringValue)
        }) {
            loadHelp(for: match)
        }
    }
    
    private func loadHelp(for command: String) {
        guard let rtfURL = Bundle.main.url(forResource: command, withExtension: "rtf", subdirectory: "Help") else {
            // ⚠️ No .rtf file found.
            catalogHelpTextView.string = ""
            return
        }
        
        do {
            let text = try String(rtfContentsOf: rtfURL)
            catalogHelpTextView.string = text
            catalogHelpTextView.syntaxHighlight()
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
    
    @IBAction func selectCatalogItem(_ sender: NSComboButton) {
        loadHelp(for: catalogComboButton.title)
    }
    
    
    private func populateCatalogComboButtonMenu() {
        var catalog: [String] = []
        
        guard let resourceURLs = Bundle.main.urls(forResourcesWithExtension: "rtf", subdirectory: "Help") else {
            return
        }
        
        for fileURL in resourceURLs {
            let command = fileURL.deletingPathExtension().lastPathComponent
            catalog.append(command)
        }
        
        catalog.sort {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
        
        let menu = NSMenu()
            
        for command in catalog {
            menu.addItem(
                withTitle: command,
                action: #selector(catalogSelectItem(_:)),
                keyEquivalent: ""
            )
        }
        
        catalogComboButton.menu = menu
    }
    
    @objc func catalogSelectItem(_ sender: NSMenuItem) {
        catalogComboButton.title = sender.title
        loadHelp(for: sender.title)
    }
}

