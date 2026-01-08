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

// MARK: ✅ Done

import Cocoa

final class StatusManager: NSObject, NSTextViewDelegate {
    private var editor: CodeEditorTextView?
    private weak var statusLabel: NSTextField?

    init(editor: CodeEditorTextView, statusLabel: NSTextField?) {
        self.editor = editor
        self.statusLabel = statusLabel
    }

    @objc func textDidChange(_ notification: Notification) {
        updateStatus()
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        updateStatus()
    }

    private func updateStatus() {
        guard let editor = editor else { return }
        
        let text = editor.string as NSString
        let cursor = editor.selectedRange.location
        var line = 1, column = 1
        for i in 0..<cursor {
            if text.character(at: i) == 10 { line += 1; column = 1 } else { column += 1 }
        }
        statusLabel?.stringValue = "Line: \(line) Col: \(column)"
    }
}
