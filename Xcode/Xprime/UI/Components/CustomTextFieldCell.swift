// CustomTextFieldCell.swift
import Cocoa

final class CustomTextFieldCell: NSTextFieldCell {

    /// Horizontal padding to keep text away from rounded corners
    var horizontalPadding: CGFloat = 6

    // Computes a rect whose origin.y is adjusted so the text is vertically centered
    override func titleRect(forBounds rect: NSRect) -> NSRect {
        var titleRect = super.titleRect(forBounds: rect)
        guard let font = self.font else { return titleRect }

      
        let baselineOffset = floor((rect.height - font.ascender - (-font.descender)) * 0.5)
        titleRect.origin.y = rect.origin.y + baselineOffset

        // Inset left/right to avoid clipping with rounded corners
        titleRect = titleRect.insetBy(dx: horizontalPadding, dy: 0)
    
        
        return titleRect
    }

    // Ensure editing/insertion rects match our centered title rect
    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        let adjusted = titleRect(forBounds: rect)
        super.edit(withFrame: adjusted, in: controlView, editor: textObj, delegate: delegate, event: event)
    }

    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: titleRect(forBounds: rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: titleRect(forBounds: cellFrame), in: controlView)
    }
}
