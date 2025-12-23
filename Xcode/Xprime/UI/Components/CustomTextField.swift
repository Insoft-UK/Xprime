/*
 The MIT License (MIT)
 
 Copyright (c) 2023 Insoft. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Cocoa

@IBDesignable
open class CustomTextField: NSTextField {
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        installCenteredCellIfNeeded()
        setup()
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        installCenteredCellIfNeeded()
        setup()
    }
    
    private func installCenteredCellIfNeeded() {
        // Replace default cell with our vertically-centering cell, preserving properties
        guard !(self.cell is CustomTextFieldCell) else { return }
        if let oldCell = self.cell {
            let newCell = CustomTextFieldCell(textCell: "")
            newCell.controlSize = oldCell.controlSize
            newCell.isEditable = (oldCell as? NSTextFieldCell)?.isEditable ?? self.isEditable
            newCell.isSelectable = (oldCell as? NSTextFieldCell)?.isSelectable ?? self.isSelectable
            newCell.isBezeled = (oldCell as? NSTextFieldCell)?.isBezeled ?? self.isBezeled
            newCell.isBordered = (oldCell as? NSTextFieldCell)?.isBordered ?? self.isBordered
            newCell.drawsBackground = (oldCell as? NSTextFieldCell)?.drawsBackground ?? self.drawsBackground
            newCell.backgroundColor = (oldCell as? NSTextFieldCell)?.backgroundColor ?? self.backgroundColor
            newCell.placeholderAttributedString = (oldCell as? NSTextFieldCell)?.placeholderAttributedString
            newCell.font = (oldCell as? NSTextFieldCell)?.font ?? self.font
            newCell.alignment = (oldCell as? NSTextFieldCell)?.alignment ?? self.alignment
            newCell.lineBreakMode = (oldCell as? NSTextFieldCell)?.lineBreakMode ?? self.lineBreakMode
            self.cell = newCell
        } else {
            self.cell = CustomTextFieldCell()
        }
    }
    
    private func setup() {
        wantsLayer = true
        if let layer = layer {
            layer.masksToBounds = true
            layer.cornerRadius = 15
            layer.borderWidth = 1.0
            layer.borderColor = .init(gray: 0.25, alpha: 1.0)
        }
        needsDisplay = true
    }

    override open func drawFocusRingMask() {}
}
