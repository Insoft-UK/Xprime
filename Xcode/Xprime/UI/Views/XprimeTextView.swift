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

class XprimeTextView: NSTextView {
    
    // MARK: - Constants
    
    private struct Constants {
        static let defaultFontSize: CGFloat = 13
        static let defaultThemeName = ".Help"
        static let defaultBackgroundColor = NSColor(white: 0, alpha: 0.75)
        static let defaultTextColor = NSColor.white
    }
    
    // MARK: - Properties
    
    private var theme: Theme!
    private var grammar: Grammar!
    
    
    // MARK: - Initializers
    
    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        setupEditor()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEditor()
    }
    
    convenience init() {
        self.init(frame: .zero, textContainer: nil)
        setupEditor()
    }
    
    // MARK: - Public Methods
    
    func setTheme(_ theme: Theme) {
        self.theme = theme
        applySyntaxHighlighting(theme: self.theme, syntaxPatterns: GrammarManager.syntaxPatterns(grammar: self.grammar))
    }
    
    func ScrollToBottom() {
        // Force layout
        self.layoutManager?.ensureLayout(for: self.textContainer!)
        self.needsDisplay = true
        
        if let scrollView = self.enclosingScrollView {
            scrollView.layoutSubtreeIfNeeded() 
            let bottom = NSPoint(x: 0, y: self.bounds.height - scrollView.contentView.bounds.height)
            scrollView.contentView.scroll(to: bottom)
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
    }
    
    /// Appends text and scrolls reliably to the bottom
    func appendTextAndScroll(_ newText: String) {
        self.string += newText

        ScrollToBottom()
        applySyntaxHighlighting(theme: theme, syntaxPatterns: GrammarManager.syntaxPatterns(grammar: grammar))
    }
    
    func changeText(_ newText: String) {
        self.string = newText
        
        applySyntaxHighlighting(theme: theme, syntaxPatterns: GrammarManager.syntaxPatterns(grammar: grammar))
    }
    
    func changeTextAndScroll(_ newText: String) {
        self.string = newText
        
        ScrollToBottom()
        applySyntaxHighlighting(theme: theme, syntaxPatterns: GrammarManager.syntaxPatterns(grammar: grammar))
    }

    
    // MARK: - Private Methods
    
    private func setupEditor() {
        configureTextViewAppearance()
        configureTextContainer()
        configureScrollView()
        configureTypingAttributes()
        configureBehavior()
        
        theme = ThemeLoader.shared.loadTheme(named: Constants.defaultThemeName)
        grammar = GrammarLoader.shared.loadGrammar(named: ".Help")
    }
    
    private func configureTextViewAppearance() {
        font = NSFont.monospacedSystemFont(ofSize: Constants.defaultFontSize, weight: .regular)
        backgroundColor = Constants.defaultBackgroundColor
        isRichText = false
    }
    
    private func configureTextContainer() {
        guard let textContainer = textContainer else { return }
        textContainer.widthTracksTextView = false
        textContainer.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textContainerInset = NSSize(width: 0, height: 0)
    }
    
    private func configureScrollView() {
        enclosingScrollView?.hasHorizontalScroller = true
        isHorizontallyResizable = true
        isVerticallyResizable = true
        smartInsertDeleteEnabled = false
    }
    
    private func configureTypingAttributes() {
        typingAttributes[.kern] = 0
        typingAttributes[.ligature] = 0
    }
    
    private func configureBehavior() {
        isEditable = false
        isSelectable = false
        usesFindPanel = true
        
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDataDetectionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticLinkDetectionEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isContinuousSpellCheckingEnabled = false
    }
    
    private func baseAttributes() -> [NSAttributedString.Key: Any] {
        let font = NSFont.systemFont(ofSize: Constants.defaultFontSize, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.alignment = .left
        
        return [
            .font: font,
            .foregroundColor: NSColor.textColor,
            .kern: 0,
            .ligature: 0,
            .paragraphStyle: paragraphStyle
        ]
    }
    
    private func color(for scope: String, theme: Theme) -> NSColor {
        for token in theme.tokenColors {
            if token.scope.contains(scope), let color = NSColor(hex: token.settings.foreground) {
                return color
            }
        }
        return Constants.defaultTextColor
    }
    
}
