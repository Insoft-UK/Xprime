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

final class ThemeManager {
    private var editor: CodeEditorTextView
    private weak var statusLabel: NSTextField?
    private weak var window: NSWindow?

    init(editor: CodeEditorTextView, statusLabel: NSTextField?, window: NSWindow?) {
        self.editor = editor
        self.statusLabel = statusLabel
        self.window = window
    }

    
    func applyTheme(from url: URL) {
        editor.loadTheme(from: url)
        guard let theme = editor.theme else { return }

        // Gutter
        if let scrollView = editor.enclosingScrollView, let ruler = scrollView.verticalRulerView as? LineNumberGutterView {
            ruler.gutterNumberAttributes[.foregroundColor] = NSColor(hex: theme.lineNumberRuler?["foreground"] ?? "") ?? .gray
            ruler.gutterNumberAttributes[.backgroundColor] = NSColor(hex: theme.lineNumberRuler?["background"] ?? "") ?? .clear
            ruler.needsDisplay = true
        }
    }
}
