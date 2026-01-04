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

final class QuickHelpViewController: NSViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let maxTextWidth: CGFloat = 600
        static let minContentWidth: CGFloat = 200
        static let padding: CGFloat = 10
    }
    
    // MARK: - Properties
    
    private let text: String
    private let hasHorizontalScroller: Bool
    
    private var theme: Theme!
    private var grammar: Grammar!
    
    
    private var size: NSSize = .zero
    
    // MARK: - Initializers
    
    init(
        text: String,
        hasHorizontalScroller: Bool = false
    ) {
        self.text = text
        self.hasHorizontalScroller = hasHorizontalScroller
        self.grammar = GrammarLoader.shared.loadGrammar(named: "Prime")
        self.theme = ThemeLoader.shared.loadTheme(named: "Catalog")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        let textView = makeTextView(with: text)

        applyHighlighting(to: textView)
        
        let contentSize = textViewContentSize(
            textView: textView,
            maxWidth: Constants.maxTextWidth
        )
        
        let scrollView = makeScrollView(containing: textView)
        let rootView = makeRootView(with: scrollView)
        
        rootView.widthAnchor
            .constraint(greaterThanOrEqualToConstant: Constants.minContentWidth)
            .isActive = true
        
        
        self.view = rootView
        self.preferredContentSize = contentSize
    }
    
    
    // MARK: - View Construction
    
    private func makeTextView(with text: String) -> XprimeTextView {
        let textStorage = NSTextStorage(string: text)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(
            size: NSSize(
                width: Constants.maxTextWidth,
                height: .greatestFiniteMagnitude
            )
        )
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        let textView = XprimeTextView(
            frame: .zero,
            textContainer: textContainer
        )
        
        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false
        
        return textView
    }
    
    
    private func textViewContentSize(
        textView: NSTextView,
        maxWidth: CGFloat
    ) -> NSSize {
        guard
            let textContainer = textView.textContainer,
            let layoutManager = textView.layoutManager
        else { return .zero }
        // Constrain wrapping width
        textContainer.containerSize = NSSize(
            width: maxWidth,
            height: .greatestFiniteMagnitude + 10
        )
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = true
        // Force layout
        layoutManager.ensureLayout(for: textContainer)

        let usedSize = layoutManager.usedRect(for: textContainer).integral.size

        return usedSize
    }

    
    private func makeScrollView(
        containing textView: NSTextView
    ) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = hasHorizontalScroller
        scrollView.autohidesScrollers = false
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }
    
    private func makeRootView(
        with scrollView: NSScrollView
    ) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constants.padding
            ),
            scrollView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constants.padding
            ),
            scrollView.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: Constants.padding
            ),
            scrollView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -Constants.padding
            )
        ])
        
        return view
    }
    
    // MARK: - Styling
    
    private func applyHighlighting(to textView: XprimeTextView) {
        textView.applySyntaxHighlighting(
            theme: theme,
            syntaxPatterns: GrammarManager.syntaxPatterns(grammar: grammar)
        )
        
        ["Syntax:", "Example:", "Note:"].forEach {
            textView.highlightBold($0, caseInsensitive: false)
        }
    }

}
