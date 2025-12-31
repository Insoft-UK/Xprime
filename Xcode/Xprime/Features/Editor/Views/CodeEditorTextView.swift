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

final class CodeEditorTextView: NSTextView {
    var theme: Theme?
    var grammar: Grammar?
    
    
    private var _smartSubtitution: Bool = false
    var smartSubtitution: Bool {
        get { _smartSubtitution }
        set { _smartSubtitution = newValue }
    }
    
    var colors: [String: NSColor] = [
        "Functions": .black,
        "Keywords": .black,
        "Namespace": .black,
        "Symbols": .black,
        "Operators": .black,
        "Brackets": .black,
        "Units": .black,
        "Numbers": .black,
        "Strings": .black,
        "Backquotes": .black,
        "Preprocessor Statements": .black,
        "Comments": .black
    ]
   
    var weight: NSFont.Weight = .medium
    var editorForegroundColor = NSColor(.white)
    
    private let syntaxHighlighter = SyntaxHighlighter()
    
    // MARK: - Initializers
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
        loadInitialTheme()
        loadInitialGrammar()
    }
    
    // MARK: - Setup
    private func setupEditor() {
        font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDataDetectionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticLinkDetectionEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isContinuousSpellCheckingEnabled = false
        
        textContainerInset = NSSize(width: 5, height: 0)
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
    
    
    
    func loadTheme(named name: String) {
        if let theme = ThemeLoader.shared.loadTheme(named: name) {
            UserDefaults.standard.set(name, forKey: "preferredTheme")
            
            self.theme = theme
            EditorThemeApplier.apply(theme, to: self)
            applySyntaxHighlighting()
        }
    }
    
    private func loadInitialTheme() {
        if let theme = ThemeLoader.shared.loadPreferredTheme() {
            self.theme = theme
            EditorThemeApplier.apply(theme, to: self)
            applySyntaxHighlighting()
        }
    }
    
    func loadGrammar(named name: String) {
        guard GrammarLoader.shared.isGrammarLoaded(named: name) == false else {
            return
        }
        
        if let grammar = GrammarLoader.shared.loadGrammar(named: name) {
            self.grammar = grammar
            applySyntaxHighlighting()
        }
    }
    
    private func loadInitialGrammar() {
        self.grammar = GrammarLoader.shared.loadPreferredGrammar()
    }
    
    private func baseAttributes() -> [NSAttributedString.Key: Any] {
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: weight)
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
    
    private func applySyntaxHighlighting() {
        guard let grammar = grammar else { return }
        guard let _ = theme else { return }
        
        syntaxHighlighter.highlight(
            textView: self,
            grammar: grammar,
            baseAttributes: baseAttributes(),
            colors: colors,
            defaultColor: editorForegroundColor
        )
    }
    
    
    
    // MARK: - Helper Functions
    private func registerUndo<T: AnyObject>(
        target: T,
        oldValue: @autoclosure @escaping () -> String,
        keyPath: ReferenceWritableKeyPath<T, String>,
        undoManager: UndoManager?,
        actionName: String = "Edit"
    ) {
        guard let undoManager = undoManager else { return }
        let previousValue = oldValue()
        
        undoManager.registerUndo(withTarget: target) { target in
            let currentValue = target[keyPath: keyPath]
            self.registerUndo(target: target,
                              oldValue: currentValue,
                              keyPath: keyPath,
                              undoManager: undoManager,
                              actionName: actionName)
            target[keyPath: keyPath] = previousValue
        }
        undoManager.setActionName(actionName)
    }
    
    
    // MARK: - Override
    
    override func replaceCharacters(in range: NSRange, with string: String) {
        super.replaceCharacters(in: range, with: string)
        applySyntaxHighlighting()
    }
    
    override func didChangeText() {
        super.didChangeText()
        registerUndo()
        applySyntaxHighlighting()
    }
    
    override func insertNewline(_ sender: Any?) {
        super.insertNewline(sender)
        autoIndentCurrentLine()
    }
    
    // MARK: - Public/s
    
    func removePragma(_ string: String) -> String {
        return string
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("#pragma") }
            .joined(separator: "\n")
    }
    
    func insertCode(_ string: String) {
        registerUndo()
        if let selectedRange = selectedRanges.first as? NSRange {
            if let textStorage = textStorage {
                textStorage.replaceCharacters(in: selectedRange, with: string)
                setSelectedRange(NSRange(location: selectedRange.location + string.count, length: 0))
            }
        }
        applySyntaxHighlighting()
    }
    
    // MARK: - Private/s
    
    private func registerUndo(actionName: String = "Text Changed") {
        registerUndo(target: self,
                     oldValue: self.string,
                     keyPath: \NSTextView.string,
                     undoManager: undoManager,
                     actionName: actionName)
        if _smartSubtitution {
            replaceLastTypedOperator()
        }
    }
    
    private func autoIndentCurrentLine() {
        let text = string as NSString
        let selectedRange = selectedRange()
        let cursorPosition = selectedRange.location
        
        // Find previous line range
        let prevLineRange = text.lineRange(for: NSRange(location: max(0, cursorPosition - 1), length: 0))
        let prevLine = text.substring(with: prevLineRange)
        
        // Get leading whitespace from previous line
        let indentMatch = prevLine.prefix { $0 == " " || $0 == "\t" }
        var indent = String(indentMatch)
        
        // Optional: increase indent if line ends with certain patterns
        let trimmed = prevLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let increaseIndentAfter = ["then", "do", "repeat", "case"]
        if increaseIndentAfter.contains(where: { trimmed.hasSuffix($0) }) {
            indent += "  " // add one level (2 spaces)
        }
        
        // Insert the indent at the cursor position
        insertText(indent, replacementRange: selectedRange)
    }
    
    private func replaceLastTypedOperator() {
        guard let textStorage = textStorage else { return }
        
        let replacements: [(String, String)] = [
            ("!=", "≠"),
            ("<>", "≠"),
            (">=", "≥"),
            ("<=", "≤"),
            ("=>", "▶")
        ]
        
        let cursorLocation = selectedRange().location
        guard cursorLocation >= 2 else { return } // Need at least 2 chars to match most patterns
        
        let originalText = string as NSString
        
        // Check the last 2–3 characters before the cursor
        let maxLookback = 3
        let start = max(cursorLocation - maxLookback, 0)
        let range = NSRange(location: start, length: cursorLocation - start)
        let recentText = originalText.substring(with: range)
        
        textStorage.beginEditing()
        
        for (find, replace) in replacements {
            if recentText.hasSuffix(find) {
                let replaceRange = NSRange(location: cursorLocation - find.count, length: find.count)
                textStorage.replaceCharacters(in: replaceRange, with: replace)
                
                // Move cursor after replacement
                let newCursor = replaceRange.location + replace.count
                if newCursor >= textStorage.length {
                    break
                }
                setSelectedRange(NSRange(location: newCursor, length: 0))
                break
            }
        }
        
        textStorage.endEditing()
    }
    
    
    private func loadJSONString(_ url: URL) -> String? {
        do {
            let jsonString = try String(contentsOf: url, encoding: .utf8)
            return jsonString
        } catch {
            return nil
        }
    }
    
    
    // MARK: - HELP
    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.option) {
            handleOptionClick(event)
            return
        }
        super.mouseDown(with: event)
    }
    
    private func handleOptionClick(_ event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        
        guard let symbol = word(at: point),
              !symbol.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Now it can find this method because it's in the class scope
        self.showQuickHelp(for: symbol, at: point)
    }
    
    private func showQuickHelp(for symbol: String, at point: NSPoint) {
        guard let url = Bundle.main.url(
            forResource: symbol.uppercased(),
            withExtension: "txt",
            subdirectory: "Help"
        ) else {
            return
        }

        do {
            let helpText = try String(contentsOf: url, encoding: .utf8)
            
            let vc = QuickLookViewController(text: helpText, withSizeOf: NSSize(width: 500, height: 250))

            let popover = NSPopover()
            popover.behavior = .transient
            popover.contentViewController = vc
            popover.show(
                relativeTo: NSRect(origin: point, size: .zero),
                of: self,
                preferredEdge: .maxY
            )
        } catch {
            return
        }
        
//        let vc = QuickHelpViewController(symbol: symbol, withSizeOf: NSSize(width: 500, height: 250))
//
//        let popover = NSPopover()
//        popover.behavior = .transient
//        popover.contentViewController = vc
//        popover.show(
//            relativeTo: NSRect(origin: point, size: .zero),
//            of: self,
//            preferredEdge: .maxY
//        )
    }
    
    private var trackingArea: NSTrackingArea?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // Remove the old area if it exists
        if let oldArea = trackingArea {
            removeTrackingArea(oldArea)
        }
        
        // Create and add the new one
        let newArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        
        addTrackingArea(newArea)
        self.trackingArea = newArea
    }
    
    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        
        if let _ = word(at: point), event.modifierFlags.contains(.option) {
            NSCursor.contextualMenu.set()
        } else {
            NSCursor.current.set()
        }
    }
    
    func word(at point: CGPoint) -> String? {
        guard let layoutManager = self.layoutManager,
              let textContainer = self.textContainer else { return nil }
        
        // 1. Adjust for the text container's position within the view
        let containerOrigin = self.textContainerOrigin
        let localPoint = CGPoint(x: point.x - containerOrigin.x, y: point.y - containerOrigin.y)
        
        // 2. Get the index
        let index = layoutManager.characterIndex(for: localPoint,
                                                 in: textContainer,
                                                 fractionOfDistanceBetweenInsertionPoints: nil)
        
        // 3. SAFETY CHECK: The crash preventer
        if index >= self.string.count || index == NSNotFound {
            return nil
        }
        
        // 4. Correct method: Call on 'self' (the NSTextView)
        let wordRange = self.selectionRange(forProposedRange: NSRange(location: index, length: 0),
                                            granularity: .selectByWord)
        
        // 5. Extract safely
        if wordRange.location != NSNotFound && (wordRange.location + wordRange.length) <= (self.string as NSString).length {
            return (self.string as NSString).substring(with: wordRange)
        }
        
        return nil
    }
}

// Small helper to get a word range (you can customize)
fileprivate extension NSString {
    func rangeOfWord(at index: Int) -> NSRange {
        _ = NSRange(location: 0, length: length)
        guard index >= 0 && index < length else { return NSRange(location: NSNotFound, length: 0) }
        
        let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault,
            self,
            CFRange(location: 0, length: length),
            CFOptionFlags(kCFStringTokenizerUnitWord),
            nil
        )
        
        CFStringTokenizerGoToTokenAtIndex(tokenizer, index)
        let cfRange = CFStringTokenizerGetCurrentTokenRange(tokenizer)
        if cfRange.location == kCFNotFound {
            return NSRange(location: NSNotFound, length: 0)
        }
        return NSRange(location: cfRange.location, length: cfRange.length)
    }
}
