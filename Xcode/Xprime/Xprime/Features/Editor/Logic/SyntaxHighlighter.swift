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

final class SyntaxHighlighter {

    func highlight(
        textView: NSTextView,
        grammar: Grammar,
        baseAttributes: [NSAttributedString.Key: Any],
        colors: [String: NSColor],
        defaultColor: NSColor
    ) {
        guard let textStorage = textView.textStorage else { return }

        let text = textView.string as NSString
        let fullRange = NSRange(location: 0, length: text.length)

        textStorage.beginEditing()
        textStorage.setAttributes(baseAttributes, range: fullRange)
        textStorage.foregroundColor = defaultColor

        /*
         The order in which highlighting matches are applied is determined by their
         sequence in the grammar pattern list.
         */
        for pattern in grammar.patterns where !pattern.match.isEmpty {
            guard let color = colors[pattern.name] else { continue }

            let regex = try? NSRegularExpression(pattern: pattern.match)
            regex?.enumerateMatches(in: text as String, range: fullRange) {
                match, _, _ in
                if let match = match {
                    textStorage.addAttribute(
                        .foregroundColor,
                        value: color,
                        range: match.range
                    )
                }
            }
        }

        textStorage.endEditing()
    }
}
