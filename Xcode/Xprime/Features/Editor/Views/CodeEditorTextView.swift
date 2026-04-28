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

// MARK: - Snippet Models
struct JSONSnippet: Decodable {
    let title: String
    let body: [String]
    let description: String?
}

struct SnippetPlaceholder {
    let index: Int
    var ranges: [NSRange]
}

// MARK: - Snippet Parsing
func parseSnippet(_ body: String) -> (text: String, placeholders: [SnippetPlaceholder]) {
    let pattern = #"\$\{(\d+):([^}]+)\}|\$\{(\d+)\}|\$(\d+)"#
    let regex = try! NSRegularExpression(pattern: pattern)
    
    let nsBody = body as NSString
    let matches = regex.matches(in: body, range: NSRange(location: 0, length: nsBody.length))
    
    var text = ""
    var placeholderRanges: [Int: [NSRange]] = [:]
    
    var lastIndex = 0
    
    for match in matches {
        let prefixRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
        text += nsBody.substring(with: prefixRange)
        
        var index = 0
        var value = ""
        
        if match.range(at: 1).location != NSNotFound {
            index = Int(nsBody.substring(with: match.range(at: 1))) ?? 0
            value = nsBody.substring(with: match.range(at: 2))
        } else if match.range(at: 3).location != NSNotFound {
            index = Int(nsBody.substring(with: match.range(at: 3))) ?? 0
        } else {
            index = Int(nsBody.substring(with: match.range(at: 4))) ?? 0
        }
        
        let start = (text as NSString).length
        text += value
        let range = NSRange(location: start, length: value.count)
        placeholderRanges[index, default: []].append(range)
        
        lastIndex = match.range.location + match.range.length
    }
    
    if lastIndex < nsBody.length {
        text += nsBody.substring(from: lastIndex)
    }
    
    let placeholders = placeholderRanges
        .map { SnippetPlaceholder(index: $0.key, ranges: $0.value.sorted { $0.location < $1.location }) }
        .sorted {
            if $0.index == 0 { return false }
            if $1.index == 0 { return true }
            return $0.index < $1.index
        }
    
    return (text, placeholders)
}

func loadSnippets(from folder: URL) -> [String: String] {
    var snippets: [String: String] = [:]
    let decoder = JSONDecoder()
    
    guard let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else {
        return snippets
    }
    
    for file in files where file.pathExtension == "xpsnippet" {
        guard let data = try? Data(contentsOf: file),
              let json = try? decoder.decode(JSONSnippet.self, from: data) else { continue }
        let text = json.body.joined(separator: "\n")
        let trigger = file.deletingPathExtension().lastPathComponent
        snippets["$\(trigger)"] = text
    }
    
    return snippets
}

// MARK: - Snippet Session
class SnippetSession {
    var placeholders: [SnippetPlaceholder]
    var currentIndex = 0
    
    init(placeholders: [SnippetPlaceholder]) {
        self.placeholders = placeholders
    }
    
    func nextPlaceholder() -> [NSRange]? {
        guard currentIndex < placeholders.count else { return nil }
        let ranges = placeholders[currentIndex].ranges
        currentIndex += 1
        return ranges
    }
}

// MARK: - Substitutions
fileprivate struct Substitution: Codable {
    let from: String
    let to: String
}

fileprivate struct Substitutions: Codable {
    let replacements: [Substitution]
    enum CodingKeys: String, CodingKey { case replacements = "substitutions" }
}

// MARK: - CodeEditorTextView
final class CodeEditorTextView: NSTextView {
    
    private var snippets: [String: String] = [:]
    private var isUpdatingMirrors = false
    private var substitutions: Substitutions!
    
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
    var editorForegroundColor = NSColor(.white)
    
    private let syntaxHighlighter = SyntaxHighlighter()
    var snippetSession: SnippetSession?
    
    
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
        loadTheme(named: Settings.shared.preferredTheme)
        loadGrammar(named: ".hppplplus")
        
        if let url = Bundle.main.resourceURL?.appendingPathComponent("Developer/Library/Xprime/Snippets") {
            snippets = loadSnippets(from: url)
        }
    }
    
    // MARK: - Editor Setup
    private func setupEditor() {
        font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDataDetectionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticLinkDetectionEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isContinuousSpellCheckingEnabled = false
        smartInsertDeleteEnabled = false
        isHorizontallyResizable = true
        isVerticallyResizable = true
        textContainerInset = NSSize(width: 0, height: 10)
        backgroundColor = NSColor.textBackgroundColor
        
        if let tc = textContainer {
            tc.widthTracksTextView = false
            tc.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
        enclosingScrollView?.hasHorizontalScroller = true
        typingAttributes[.kern] = 0
        typingAttributes[.ligature] = 0
        isRichText = false
        usesFindPanel = true
        
        if let url = Bundle.main.url(forResource: "substitutions", withExtension: "json") {
            loadSubstitutions(at: url)
        }
    }
    
 
    // MARK: - Key Handling
    override func keyDown(with event: NSEvent) {
        isDeleting = (event.keyCode == 51 || event.keyCode == 117)
        
        if event.keyCode == 48 { // Tab
            if jumpToNextPlaceholder() { return }
            insertText("  ", replacementRange: selectedRange())
            return
        }
        super.keyDown(with: event)
        expandSnippetIfNeeded()
    }
    
    // MARK: - Snippet Expansion
    func expandSnippetIfNeeded() {
        guard let selected = selectedRanges.first as? NSRange else { return }
        let text = string as NSString
        let prefix = text.substring(to: selected.location)
        
        let components = prefix.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        guard let lastWord = components.last else { return }
        let trigger = String(lastWord)
        
        guard snippets.keys.contains(trigger) else { return }
        
        registerUndo(actionName: "Snippet Expansion")
        expandSnippet(trigger)
        
        // 🔹 Highlight after expansion
        applySyntaxHighlighting()
    }
    
    func expandSnippet(_ trigger: String) {
        let result = parseSnippet(snippets[trigger] ?? "")
        guard let selected = selectedRanges.first as? NSRange else { return }
        let prefix = (string as NSString).substring(to: selected.location)
        guard let wordRange = prefix.range(of: trigger, options: .backwards) else { return }
        let nsRange = NSRange(wordRange, in: prefix)
        
        textStorage?.replaceCharacters(in: nsRange, with: result.text)
        let offset = nsRange.location
        let adjusted = result.placeholders.map { placeholder -> SnippetPlaceholder in
            var p = placeholder
            p.ranges = p.ranges.map { NSRange(location: $0.location + offset, length: $0.length) }
            return p
        }
        snippetSession = SnippetSession(placeholders: adjusted)
        _ = jumpToNextPlaceholder()
    }
    
    func jumpToNextPlaceholder() -> Bool {
        guard let session = snippetSession else { return false }
        guard let ranges = session.nextPlaceholder() else { snippetSession = nil; return false }
        if let first = ranges.first { setSelectedRange(first) }
        return true
    }
    
    func placeholder(at location: Int) -> (placeholderIndex: Int, rangeIndex: Int)? {
        guard let session = snippetSession else { return nil }
        for (pIndex, placeholder) in session.placeholders.enumerated() {
            for (rIndex, range) in placeholder.ranges.enumerated() {
                if location >= range.location && location < range.location + range.length {
                    return (pIndex, rIndex)
                }
            }
        }
        return nil
    }
    
    // MARK: - Mirror Handling
    func updateMirrors(for placeholderIndex: Int) {
        guard let session = snippetSession else { return }
        guard let primaryRange = session.placeholders[placeholderIndex].ranges.first else { return }

        let value = (string as NSString).substring(with: primaryRange)

        isUpdatingMirrors = true
        textStorage?.beginEditing()

        let mirrors = session.placeholders[placeholderIndex].ranges
        // Iterate over all mirrors except primary (index 0)
        for i in 1..<mirrors.count {
            var mirrorRange = mirrors[i]
            
            // Replace safely if within text bounds
            if mirrorRange.location + mirrorRange.length <= (string as NSString).length {
                textStorage?.replaceCharacters(in: mirrorRange, with: value)
                mirrorRange.length = value.count
                session.placeholders[placeholderIndex].ranges[i] = mirrorRange
            }
        }

        textStorage?.endEditing()
        isUpdatingMirrors = false
    }
    
    func adjustRanges(after location: Int, delta: Int, excludingPlaceholder skipIndex: Int? = nil) {
        guard let session = snippetSession else { return }
        for p in 0..<session.placeholders.count {
            if p == skipIndex { continue }
            for r in 0..<session.placeholders[p].ranges.count {
                var range = session.placeholders[p].ranges[r]
                if range.location >= location {
                    range.location += delta
                    session.placeholders[p].ranges[r] = range
                }
            }
        }
    }
    
    // MARK: - Syntax Highlighting
    private func baseAttributes() -> [NSAttributedString.Key: Any] {
        if let enclosingScrollView {
            let gutterView = enclosingScrollView.verticalRulerView as! LineNumberGutterView
            gutterView.pointSize = CGFloat(theme?.pointSize ?? 12)
        }
        let font = NSFont.monospacedSystemFont(ofSize: CGFloat(theme?.pointSize ?? 12), weight: weight)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 0
        style.paragraphSpacing = 2.5
        style.alignment = .left
        return [.font: font, .foregroundColor: NSColor.textColor, .kern: 0, .ligature: 0, .paragraphStyle: style]
    }
    
    func applySyntaxHighlighting() {
        guard let grammar = grammar, theme != nil else { return }
        syntaxHighlighter.highlight(textView: self, grammar: grammar, baseAttributes: baseAttributes(), colors: colors, defaultColor: editorForegroundColor)
    }
    
    func loadTheme(named name: String) {
        if let theme = ThemeLoader.shared.loadTheme(named: name) {
            self.theme = theme
            EditorThemeApplier.apply(theme, to: self)
            applySyntaxHighlighting()
        }
    }
    
    func loadGrammar(named name: String) {
        if let grammar = GrammarLoader.shared.loadGrammar(named: name) {
            self.grammar = grammar
            applySyntaxHighlighting()
        }
    }
    
    // MARK: - Undo & Substitutions
    private func registerUndo<T: AnyObject>(target: T, oldValue: @autoclosure @escaping () -> String, keyPath: ReferenceWritableKeyPath<T, String>, undoManager: UndoManager?, actionName: String = "Edit") {
        guard let undoManager = undoManager else { return }
        let previousValue = oldValue()
        undoManager.registerUndo(withTarget: target) { target in
            let currentValue = target[keyPath: keyPath]
            self.registerUndo(target: target, oldValue: currentValue, keyPath: keyPath, undoManager: undoManager, actionName: actionName)
            target[keyPath: keyPath] = previousValue
        }
        undoManager.setActionName(actionName)
    }
    
    func registerUndo(actionName: String = "Text Changed") {
        registerUndo(target: self, oldValue: self.string, keyPath: \.string, undoManager: undoManager, actionName: actionName)
    }
    
    private func replaceLastTyped() {
        guard (substitutions != nil) else { return }
        guard let textStorage = textStorage else { return }
        let cursor = selectedRange().location
        guard cursor >= 2 else { return }
        let maxLookback = 10
        let start = max(cursor - maxLookback, 0)
        let range = NSRange(location: start, length: cursor - start)
        let recent = (string as NSString).substring(with: range)
        
        textStorage.beginEditing()
        for sub in substitutions.replacements {
            if recent.hasSuffix(sub.from) {
                let replaceRange = NSRange(location: cursor - sub.from.count, length: sub.from.count)
                textStorage.replaceCharacters(in: replaceRange, with: sub.to)
                break
            }
        }
        textStorage.endEditing()
    }
    
    private func loadJSONString(_ url: URL) -> String? {
        try? String(contentsOf: url, encoding: .utf8)
    }
    
    func loadSubstitutions(at url: URL) {
        if let jsonString = loadJSONString(url), let jsonData = jsonString.data(using: .utf8) {
            substitutions = try? JSONDecoder().decode(Substitutions.self, from: jsonData)
        }
    }
    
    // MARK: - Overrides
    var isDeleting = false
 
    override func didChangeText() {
        super.didChangeText()
        applySyntaxHighlighting()

        if isDeleting {
            isDeleting = false
            return
        }

        if Settings.shared.keywordNormalization {
            let keywords: Set<String> = [
                "REGEX", "DICTIONARY", "USES", "ALIAS",
                "BEGIN", "END",
                "IF", "THEN", "ELSE", "CASE",
                "FOR", "FROM", "TO", "STEP", "DO",
                "WHILE", "REPEAT", "UNTIL",
                "BREAK", "CONTINUE", "RETURN",
                "IFERR", "KILL", "DEFAULT",
                "AND", "OR", "NOT", "XOR", "MOD",
                "VAR", "LOCAL", "EXPORT", "CONST", "KEY", "VIEW"
            ]

            let text = self.string
            let cursorLocation = self.selectedRange().location
            let nsText = text as NSString

            let separators = CharacterSet.whitespacesAndNewlines
                .union(.punctuationCharacters)

            var start = cursorLocation

            // Find start of current word
            while start > 0 {
                let char = nsText.substring(with: NSRange(location: start - 1, length: 1))
                if char.rangeOfCharacter(from: separators) != nil {
                    break
                }
                start -= 1
            }

            let length = cursorLocation - start

            if length > 0 {
                let range = NSRange(location: start, length: length)
                let typedWord = nsText.substring(with: range)
                let uppercased = typedWord.uppercased()

                if keywords.contains(uppercased) && typedWord != uppercased {
                    self.textStorage?.replaceCharacters(in: range, with: uppercased)
                    self.setSelectedRange(
                        NSRange(location: start + uppercased.count, length: 0)
                    )
                }
            }
        }

        if Settings.shared.substitutionEnabled {
            replaceLastTyped()
        }
    }

    
    override func insertText(_ string: Any, replacementRange: NSRange) {
        super.insertText(string, replacementRange: replacementRange)
        expandSnippetIfNeeded()
    }

    // MARK: - MouseDown Event Handler
  
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
            forResource: symbol,
            withExtension: "txt",
            subdirectory: "Help"
        ) else {
            return
        }
        
        do {
            let helpText = try String(contentsOf: url, encoding: .utf8)
            
            let popover = NSPopover()
            popover.behavior = .transient
            popover.contentViewController = QuickHelpViewController(text: helpText, hasHorizontalScroller: false)
            popover.show(
                relativeTo: NSRect(origin: point, size: .zero),
                of: self,
                preferredEdge: .maxY
            )
        } catch {
            return
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
