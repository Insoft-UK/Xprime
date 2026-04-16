import AppKit

enum RetroStyle {

    static let background = NSColor(calibratedWhite: 0.85, alpha: 1.0)
    static let border = NSColor.black
    static let text = NSColor.black

    static func applyFlatBorder(_ view: NSView) {
        view.wantsLayer = true
        view.layer?.borderWidth = 1
        view.layer?.borderColor = border.cgColor
        view.layer?.backgroundColor = background.cgColor
    }
}
