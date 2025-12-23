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


final class OutputTextView: NSTextView {
    
    var editorForegroundColor = NSColor(.black)
    
    
    
    // MARK: - Initializers
    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        setupEditor()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEditor()
    }
    
    // MARK: - Setup
    private func setupEditor() {
        font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDataDetectionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticLinkDetectionEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isContinuousSpellCheckingEnabled = false
        
        textContainerInset = NSSize(width: 0, height: 0)
        backgroundColor = NSColor.textBackgroundColor
        
        smartInsertDeleteEnabled = false
        
        // No Wrapping, Horizontal Scroll Enabled
        isHorizontallyResizable = true
        isVerticallyResizable = true
        
        if let textContainer = textContainer {
            textContainer.widthTracksTextView = false // THIS is the key line
            textContainer.containerSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
        }
        
        enclosingScrollView?.hasHorizontalScroller = true
        typingAttributes[.kern] = 0
        typingAttributes[.ligature] = 0
        isRichText = false
        usesFindPanel = true
    }
    
    
}
