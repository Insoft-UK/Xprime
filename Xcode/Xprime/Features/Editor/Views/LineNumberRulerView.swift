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

final class LineNumberRulerView: NSRulerView {

    weak var textView: NSTextView?

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView!, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 40
        self.registerObservers()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func registerObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateLines),
                                               name: NSText.didChangeNotification,
                                               object: textView)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateLines),
                                               name: NSView.boundsDidChangeNotification,
                                               object: textView?.enclosingScrollView?.contentView)

        textView?.enclosingScrollView?.contentView.postsBoundsChangedNotifications = true
    }

    @objc func updateLines() {
        needsDisplay = true
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = self.textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }
        

        // Clip to avoid drawing outside bounds
        NSGraphicsContext.current?.cgContext.clip(to: rect)

        let visibleRect = textView.enclosingScrollView?.contentView.bounds ?? textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        
        let fullText = textView.string as NSString
        let startCharIndex = layoutManager.characterIndexForGlyph(at: glyphRange.location)
        var lineNumber = fullText.substring(to: startCharIndex).components(separatedBy: .newlines).count

        var index = glyphRange.location

        while index < NSMaxRange(glyphRange) {
            let charRange = layoutManager.characterRange(forGlyphRange: NSRange(location: index, length: 1), actualGlyphRange: nil)
            let lineRange = fullText.lineRange(for: charRange)
            let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)

            let lineRect = layoutManager.lineFragmentUsedRect(forGlyphAt: glyphRange.location, effectiveRange: nil)
            let yPosition = lineRect.minY - visibleRect.origin.y

            let labelRect = NSRect(x: 0, y: yPosition, width: self.ruleThickness - 5, height: lineRect.height)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .right

            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular),
                .foregroundColor: NSColor.gray,
                .backgroundColor: NSColor.clear,
                .paragraphStyle: paragraphStyle
            ]

            let lineStr = "\(lineNumber)" as NSString
            lineStr.draw(in: labelRect, withAttributes: attrs)

            index = NSMaxRange(lineRange)
            lineNumber += 1
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
