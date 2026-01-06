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


final class CatalogViewController: NSViewController, NSComboBoxDelegate, NSTextFieldDelegate {
    @IBOutlet weak var catalogComboBox: NSComboBox!
    @IBOutlet weak var catalogHelpTextView: CatalogHelpTextView!
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateCatalogComboBoxItems()
        
        catalogComboBox.delegate = self
        catalogComboBox.usesDataSource = false
        catalogComboBox.focusRingType = .none
        catalogComboBox.numberOfVisibleItems = 20
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard let window = view.window else { return }
        
        // Make window background transparent
        window.isOpaque = false
        window.backgroundColor = NSColor(white: 0, alpha: 0.75)
        
        // Optional: remove title bar / standard window decorations
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask = [.closable, .titled]
        window.styleMask.insert(.fullSizeContentView)
        window.hasShadow = true
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
    
    func controlTextDidChange(_ notification: Notification) {
        guard let comboBox = notification.object as? NSComboBox else { return }

        let text = comboBox.stringValue
        handleInput(text)
    }
    
    func handleInput(_ text: String) {
        guard let file = searchCatalog(text) else { return }
        loadHelp(for: file)
        UserDefaults.standard.set(file, forKey: "lastOpenedCatalogHelpFile")
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        guard let comboBox = notification.object as? NSComboBox else { return }

        let index = comboBox.indexOfSelectedItem
        guard index >= 0 else { return }

        let value = comboBox.itemObjectValue(at: index) as? String ?? ""
        handleInput(value)

        DispatchQueue.main.async {
            if let editor = comboBox.currentEditor() {
                let length = editor.string.count
                editor.selectedRange = NSRange(location: length, length: 0)
            }
        }
    }
    
    private func searchCatalog(_ text: String) -> String? {
        guard !text.isEmpty,
              let items = catalogComboBox.objectValues as? [String] else {
            return nil
        }

        return items.first {
            $0.localizedCaseInsensitiveContains(text)
        }
    }
    
    private func populateCatalogComboBoxItems() {
        guard let resourceURLs = Bundle.main.urls(
            forResourcesWithExtension: "txt",
            subdirectory: "Help"
        ) else {
            return
        }

        let catalog = resourceURLs
            .map { $0.deletingPathExtension().lastPathComponent.customPercentDecoded() }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        catalogComboBox.removeAllItems()
        catalogComboBox.addItems(withObjectValues: catalog)
        
        let lastOpenedCatalogHelpFile = UserDefaults.standard.object(forKey: "lastOpenedCatalogHelpFile") as? String ?? "-"
        
        let index = catalogComboBox.indexOfItem(withObjectValue: lastOpenedCatalogHelpFile)
        catalogComboBox.selectItem(at: index)
        loadHelp(for: lastOpenedCatalogHelpFile)
        
        DispatchQueue.main.async {
            if let editor = self.catalogComboBox.currentEditor() {
                let length = editor.string.count
                editor.selectedRange = NSRange(location: length, length: 0)
            }
        }
    }
}

