//
//  Autocomplete.swift
//  Xprime
//
//  Created by Richie on 14/04/2026.
//

import Cocoa

struct AutocompleteItem {
    let title: String
    let detail: String?
    let icon: NSImage?
    var priority: Int = 0   // higher = more relevant
}

struct FuzzyMatcher {

    static func score(_ query: String, _ text: String) -> Int? {
        if query.isEmpty { return 0 }

        var score = 0
        var lastMatchIndex: Int = -1
        var qIndex = query.startIndex

        for (i, c) in text.enumerated() {
            if qIndex == query.endIndex { break }

            if c.lowercased() == query[qIndex].lowercased() {
                score += (lastMatchIndex + 1 == i) ? 15 : 8
                lastMatchIndex = i
                qIndex = query.index(after: qIndex)
            }
        }

        return qIndex == query.endIndex ? score : nil
    }

    static func filter(_ items: [AutocompleteItem], query: String) -> [AutocompleteItem] {
        let scored: [(item: AutocompleteItem, score: Int)] = items.compactMap { item in
            guard let s = score(query, item.title) else { return nil }
            return (item: item, score: s + item.priority)
        }

        let sorted = scored.sorted { a, b in
            a.score > b.score
        }

        return sorted.map { $0.item }
    }
}

class AutocompleteCellView: NSTableCellView {

    let iconView = NSImageView()
    let titleLabel = NSTextField(labelWithString: "")
    let detailLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        wantsLayer = true

        titleLabel.font = NSFont.systemFont(ofSize: 13)
        detailLabel.font = NSFont.systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor

        [iconView, titleLabel, detailLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: detailLabel.leadingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            detailLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            detailLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        titleLabel.lineBreakMode = .byTruncatingTail
    }

    required init?(coder: NSCoder) { fatalError() }
}


class AutocompleteViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    var items: [AutocompleteItem] = [] {
        didSet {
            tableView.reloadData()
            tableView.frame.size.height = 220
        }
    }

    var onSelect: ((AutocompleteItem) -> Void)?

    private let tableView = NSTableView()
    private let scrollView = NSScrollView()

    override func loadView() {
        let size = NSSize(width: 360, height: 360)

        let v = NSView(frame: NSRect(origin: .zero, size: size))
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        self.view = v
        setup()
    }

    private func setup() {
        let col = NSTableColumn(identifier: .init("col"))
        col.width = 360
        col.resizingMask = .autoresizingMask

        tableView.addTableColumn(col)
        tableView.headerView = nil
        tableView.rowHeight = 28
        tableView.delegate = self
        tableView.dataSource = self
        tableView.focusRingType = .none
        tableView.refusesFirstResponder = true

        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle

        tableView.frame = NSRect(x: 0, y: 0, width: 360, height: 220)

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder

        view.addSubview(scrollView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        preferredContentSize = NSSize(width: 360, height: 360)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(nil)
    }

    func numberOfRows(in tableView: NSTableView) -> Int { items.count }

    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {

        let item = items[row]
        let id = NSUserInterfaceItemIdentifier("cell")

        let cell = tableView.makeView(withIdentifier: id, owner: self) as? AutocompleteCellView
            ?? AutocompleteCellView(frame: NSRect(x: 0, y: 0, width: tableView.bounds.width, height: 28))

        cell.identifier = id

        cell.autoresizingMask = [.width]

        cell.titleLabel.stringValue = item.title
        cell.detailLabel.stringValue = item.detail ?? ""
        cell.iconView.image = item.icon

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard row >= 0 else { return }
        onSelect?(items[row])
    }

    func move(_ delta: Int) {
        guard items.count > 0 else { return }

        let current = tableView.selectedRow
        let next = max(0, min(current + delta, items.count - 1))

        tableView.selectRowIndexes(IndexSet(integer: next), byExtendingSelection: false)
        tableView.scrollRowToVisible(next)
    }

    func confirm() {
        let row = tableView.selectedRow
        if row >= 0 { onSelect?(items[row]) }
    }
}

class AutocompletePopover {

    var popoverRef: NSPopover { popover }
    private let popover = NSPopover()
    private let vc = AutocompleteViewController()

    init() {
        popover.contentViewController = vc
        popover.behavior = .semitransient   // 🔥 IMPORTANT (not .transient)
        popover.animates = false

        let size = NSSize(width: 360, height: 220)
        popover.contentSize = size
        vc.preferredContentSize = size
    }

    func show(relativeTo rect: NSRect, of view: NSView) {
        popover.show(relativeTo: rect, of: view, preferredEdge: .maxY)
    }

    func close() { popover.performClose(nil) }

    func update(items: [AutocompleteItem]) {
        vc.items = items
    }

    func setHandler(_ handler: @escaping (AutocompleteItem) -> Void) {
        vc.onSelect = handler
    }

    func moveDown() { vc.move(1) }
    func moveUp() { vc.move(-1) }
    func confirm() { vc.confirm() }

    var isShown: Bool { popover.isShown }
}

class AutocompleteTextView: NSTextView {

    private let popup = AutocompletePopover()
    var allItems: [AutocompleteItem] = []

    private var ghostLayer: CATextLayer?

    override func didChangeText() {
        super.didChangeText()
        updateAutocomplete()
    }

    // MARK: Current word

    private func currentWordRange() -> NSRange {
        let cursor = selectedRange().location
        guard cursor > 0 else { return NSRange(location: 0, length: 0) }

        let ns = string as NSString
        var start = cursor

        while start > 0 {
            let c = ns.character(at: start - 1)
            if CharacterSet.whitespacesAndNewlines.contains(UnicodeScalar(c)!) {
                break
            }
            start -= 1
        }

        return NSRange(location: start, length: cursor - start)
    }

    private func currentWord() -> String {
        let range = currentWordRange()
        return (string as NSString).substring(with: range)
    }

    // MARK: Caret position

    private func caretRect() -> NSRect {
        guard let lm = layoutManager, let tc = textContainer else { return .zero }

        let glyphRange = lm.glyphRange(forCharacterRange: selectedRange(), actualCharacterRange: nil)
        var rect = lm.boundingRect(forGlyphRange: glyphRange, in: tc)

        rect = rect.offsetBy(dx: textContainerOrigin.x, dy: textContainerOrigin.y)
        return rect
    }

    // MARK: Autocomplete logic

    private func updateAutocomplete() {
        let word = currentWord()
        let results = FuzzyMatcher.filter(allItems, query: word)

        if results.isEmpty {
            popup.close()
            clearGhost()
            return
        }

        if !popup.isShown {
            popup.show(relativeTo: caretRect(), of: self)
        }

        popup.update(items: results)

        showGhostText(results.first?.title ?? "", prefix: word)
    }

    private func applyCompletion(_ item: AutocompleteItem) {
        let range = currentWordRange()
        replaceCharacters(in: range, with: item.title)
        didChangeText()

        popup.close()
        clearGhost()
    }

    // MARK: Ghost text (inline preview)

    private func showGhostText(_ suggestion: String, prefix: String) {
        guard suggestion.hasPrefix(prefix), suggestion != prefix else {
            clearGhost()
            return
        }

        let remaining = String(suggestion.dropFirst(prefix.count))

        if ghostLayer == nil {
            wantsLayer = true

            let layer = CATextLayer()
            layer.fontSize = 13
            layer.foregroundColor = NSColor.placeholderTextColor.cgColor
            layer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
            layer.alignmentMode = .left

            self.layer?.addSublayer(layer)
            ghostLayer = layer
        }

        ghostLayer?.string = remaining

        let r = caretRect()
        ghostLayer?.frame = NSRect(
            x: r.origin.x + 2,
            y: r.origin.y,
            width: 300,
            height: 20
        )
    }

    private func clearGhost() {
        ghostLayer?.removeFromSuperlayer()
        ghostLayer = nil
    }

    // MARK: Keyboard

    override func keyDown(with event: NSEvent) {
        if popup.isShown {
            switch event.keyCode {
            case 125: popup.moveDown(); return
            case 126: popup.moveUp(); return
            case 36, 48: popup.confirm(); return
            case 53:
                popup.close()
                clearGhost()
                return
            default:
                break
            }
        }

        super.keyDown(with: event)
    }
}
