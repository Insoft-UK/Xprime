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
        static let defaultThemeName = "Catalog"
        static let defaultBackgroundColor = NSColor(white: 0, alpha: 0.75)
        static let defaultTextColor = NSColor.white
    }
    
    // MARK: - Properties
    
    private var theme: Theme?
    
    // Precompiled regex patterns and their theme scope
    private let syntaxPatterns: [(pattern: String, scope: String)] = [
        (#"(?mi)[%a-z\u0080-\uFFFF][\w\u0080-\uFFFF]*(\.[%a-z\u0080-\uFFFF][\w\u0080-\uFFFF]*)*(?=\()"#, "Functions"),
        (#"(?m)\b(BEGIN|END|RETURN|KILL|IF|THEN|ELSE|XOR|OR|AND|NOT|CASE|DEFAULT|IFERR|IFTE|FOR|FROM|STEP|DOWNTO|TO|DO|WHILE|REPEAT|UNTIL|BREAK|CONTINUE|EXPORT|CONST|LOCAL|KEY)\b"#, "Keywords"),
        (#"[\u0080-\uFFFF]+"#, "Symbols"),
        (#"[▶:=+\-*/<>≠≤≥\.]+"#, "Operators"),
        (#"[{}()\[\]]+"#, "Brackets"),
        (#"(?:#(?:(?:[0-1]+(?::-?\d+)?b)|(?:[0-7]+(?::-?\d+)?o)|(?:[0-9A-F]+(?::-?\d+)?h)|(?:[0-9]+(?::-?\d+)?d?)|))|(?:(?<![a-zA-Z\u0080-\uFFFF$])-?\d+(?:[\.|e]\d+)?)"#, "Numbers"),
        (#""([^"\\]|\\.)*""#, "Strings"),
        (#"(?m)^\s*#[a-z]{2}.+"#, "Preprocessor Statements")
    ]
    
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
        applySyntaxHighlighting()
    }
    
    /// Appends text and scrolls reliably to the bottom
    func appendTextAndScroll(_ newText: String) {
        // Append text
        self.string += newText
        
        // Force layout
        self.layoutManager?.ensureLayout(for: self.textContainer!)
        self.needsDisplay = true
        
        // Scroll to the very bottom
        if let scrollView = self.enclosingScrollView {
            scrollView.layoutSubtreeIfNeeded() // make sure scrollView layout is updated
            let bottom = NSPoint(x: 0, y: self.bounds.height - scrollView.contentView.bounds.height)
            scrollView.contentView.scroll(to: bottom)
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
        
        applySyntaxHighlighting()
    }

    
    
    func applySyntaxHighlighting() {
        guard let textStorage = textStorage, let theme = theme else { return }
        let fullRange = NSRange(location: 0, length: textStorage.length)
        
        textStorage.beginEditing()
        textStorage.setAttributes(baseAttributes(), range: fullRange)
        
        for (pattern, scope) in syntaxPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let color = color(for: scope, theme: theme)
            regex.enumerateMatches(in: textStorage.string, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    textStorage.addAttribute(.foregroundColor, value: color, range: range)
                }
            }
        }
        
        textStorage.endEditing()
    }
    
    // MARK: - Private Methods
    
    private func setupEditor() {
        configureTextViewAppearance()
        configureTextContainer()
        configureScrollView()
        configureTypingAttributes()
        configureBehavior()
        
        theme = ThemeLoader.shared.loadTheme(named: Constants.defaultThemeName)
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
