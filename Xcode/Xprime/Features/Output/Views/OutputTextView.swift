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


final class OutputTextView: XprimeTextView {
    // minHeightConstraint: added by Jozef Dekoninck
    private var minHeightConstraint: NSLayoutConstraint?
    
    private func ensureMinHeightConstraint() {
        if minHeightConstraint == nil {
            minHeightConstraint = NSLayoutConstraint(
                item: self,
                attribute: .height,
                relatedBy: .greaterThanOrEqual,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: 100
            )
        }
    }
    
    // MARK: - Initializers
    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        textContainerInset = NSSize(width: 5, height: 5)
    }
    
    func toggleVisability(_ sender: NSButton) {
        guard let scrollView = self.enclosingScrollView else {
            return
        }
        let shouldShow = scrollView.isHidden
        ensureMinHeightConstraint()
        
        if shouldShow {
            show()
            sender.contentTintColor = .systemBlue
        } else {
            hide()
            if let window = sender.subviews.first?.window {
                sender.contentTintColor = window.backgroundColor?.contrastColor()
            } else {
                sender.contentTintColor = .systemGray
            }
        }
        scrollView.updateLayer()
    }
    
  
    func hide() {
        if let scrollView = self.enclosingScrollView {
            scrollView.isHidden = true
            scrollView.hasVerticalScroller = true
        }
        minHeightConstraint?.isActive = false
    }
    
    func show() {
        if let scrollView = self.enclosingScrollView {
            scrollView.isHidden = false
            scrollView.hasVerticalScroller = true
        }
        minHeightConstraint?.isActive = true
        backgroundColor = NSColor(white: 0, alpha: 0.75)
    }
}
