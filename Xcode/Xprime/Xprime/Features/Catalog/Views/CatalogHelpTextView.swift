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

final class CatalogHelpTextView: NSTextView {
    private(set) var theme: Theme?
    private(set) var grammar: Grammar?
    
    var colors: [String: NSColor] = [
        "Keywords": .black,
        "Storage": .black,
        "Builtins": .black,
        "Namespace": .black,
        "Numbers": .black,
        "Symbols": .black,
        "Constants": .black,
        "Operators": .black,
        "Functions": .black,
        "Brackets": .black,
        "Units": .black,
        "Backquotes": .black,
        "Strings": .black,
        "Preprocessor Statements": .black,
        "Comments": .black
    ]
    
    var weight: NSFont.Weight = .medium
    var editorForegroundColor = NSColor(white: 1.0, alpha: 1.0)
    
    private let syntaxHighlighter = SyntaxHighlighter()
    
    // MARK: - Init
    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        setupEditor()
        let url = Bundle.main.url(forResource: "HP Connectivity Kit (Light)", withExtension: "xpcolortheme")!

        loadGrammar(named: ".txt")
        loadTheme(from: url)
        if let theme {
            apply(theme)
        }
    }
    
    // MARK: - Setup
    private func setupEditor() {
        isHorizontallyResizable = false      // Disable horizontal scrolling
        autoresizingMask = [.width]          // Allow width to adjust with superview
        textContainer?.widthTracksTextView = true
        textContainer?.containerSize = NSSize(width: bounds.width, height: .greatestFiniteMagnitude)
        textContainer?.lineBreakMode = .byWordWrapping
        
        textContainerInset = NSSize(width: 10, height: 20)
    }
    
    
    
    // MARK: - Syntax Highlighting
    private func baseAttributes() -> [NSAttributedString.Key: Any] {
        let font = NSFont.systemFont(ofSize: CGFloat(theme?.pointSize ?? 13), weight: weight)
        let style = NSMutableParagraphStyle()
        
        style.lineSpacing = 0
        style.paragraphSpacing = 2.5
        style.alignment = .left
        return [.font: font, .foregroundColor: NSColor.textColor, .kern: 0, .ligature: 0, .paragraphStyle: style]
    }
    
    func applySyntaxHighlighting() {
        guard let grammar = grammar else { return }
        syntaxHighlighter.highlight(textView: self, grammar: grammar, baseAttributes: baseAttributes(), colors: colors, defaultColor: editorForegroundColor)
    }
    
    private func loadTheme(from url: URL) {
        if let theme = ThemeLoader.shared.loadTheme(from: url) {
            self.theme = theme
            if let grammar = self.grammar {
                applySyntaxHighlighting(theme: self.theme, syntaxPatterns: GrammarManager.syntaxPatterns(grammar: grammar))
            }
            apply(theme)
        }
    }
    
    private func loadGrammar(named name: String) {
        if let grammar = GrammarLoader.shared.loadGrammar(named: name) {
            self.grammar = grammar
            if let grammar = self.grammar, self.theme != nil {
                applySyntaxHighlighting(theme: self.theme, syntaxPatterns: GrammarManager.syntaxPatterns(grammar: grammar))
            }
        }
    }
    
    
    private func apply(_ theme: Theme) {

        func color(for scope: String) -> NSColor {
            for token in theme.tokenColors {
                if token.scope.contains(scope) {
                    let hex = token.settings.foreground
                    if let color = NSColor(hex: hex) {
                        return color
                    }
                }
            }
            return editorForegroundColor
        }

        editorForegroundColor =
            NSColor(hex: theme.colors["editor.foreground"]!)!

        backgroundColor =
            NSColor(hex: theme.colors["editor.background"]!)!

        textColor = editorForegroundColor

        selectedTextAttributes = [
            .backgroundColor: NSColor(
                hex: theme.colors["editor.selectionBackground"]!
            )!
        ]

        insertionPointColor =
            NSColor(hex: theme.colors["editor.cursor"]!)!
        
        
        
        switch theme.weight {
        case "ultraLight":
            weight = .ultraLight
        case "thin":
            weight = .thin
        case "light":
            weight = .light
        case "regular":
            weight = .regular
        case "medium":
            weight = .medium
        case "semibold":
            weight = .semibold
        case "bold":
            weight = .bold
        case "heavy":
            weight = .heavy
        case "black":
            weight = .black
        default:
            weight = .regular
        }
        
        font = .monospacedSystemFont(ofSize: 13 , weight: weight)
        

        colors["Functions"] = color(for: "Functions")
        colors["Keywords"] = color(for: "Keywords")
        colors["Namespace"] = color(for: "Namespace")
        colors["Symbols"] = color(for: "Symbols")
        colors["Operators"] = color(for: "Operators")
        colors["Brackets"] = color(for: "Brackets")
        colors["Units"] = color(for: "Units")
        colors["Numbers"] = color(for: "Numbers")
        colors["Strings"] = color(for: "Strings")
        colors["Backquotes"] = color(for: "Backquotes")
        colors["Preprocessor Statements"] = color(for: "Preprocessor Statements")
        colors["Comments"] = color(for: "Comments")
        colors["Builtins"] = color(for: "Builtins")
        colors["Constants"] = color(for: "Constants")
        colors["Storage"] = color(for: "Storage")
    }
}
