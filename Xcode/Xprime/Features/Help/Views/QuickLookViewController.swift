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

final class QuickLookViewController: NSViewController {

    private var text: String
    private var size: NSSize = .zero
    private var hasHorizontalScroller: Bool = false

    init(text: String, withSizeOf size: NSSize? = nil, hasHorizontalScroller: Bool = false) {
        self.text = text
        if let size = size {
            self.size = size
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }
    
    override func loadView() {
        let textView = makeTextView(with: text)
        applyHighlighting(to: textView)

        let scrollView = makeScrollView(containing: textView)

        let rootView = makeRootView(with: scrollView)
        self.view = rootView

        preferredContentSize = self.size
    }
    
    
    private func makeTextView(with text: String) -> NSTextView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false
        textView.string = text
        return textView
    }
    
    private func applyHighlighting(to textView: NSTextView) {
        textView.syntaxHighlight()
        textView.highlightBold("Syntax:", caseInsensitive: false)
        textView.highlightBold("Example:", caseInsensitive: false)
        textView.highlightBold("Note:", caseInsensitive: false)
    }
    
    private func makeScrollView(containing textView: NSTextView) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = self.hasHorizontalScroller
        scrollView.autohidesScrollers = false
        scrollView.drawsBackground = false
        scrollView.documentView = textView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }
    
    private func makeRootView(with scrollView: NSScrollView) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor

        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])

        return view
    }
}


