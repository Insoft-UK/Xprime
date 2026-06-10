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

fileprivate let hoverColor = NSColor(white: 1.0, alpha: 0.05)
fileprivate let pressedColor = NSColor(white: 1.0, alpha: 0.1)

//@IBDesignable
final class CustomIconButton: NSButton {

    private var trackingArea: NSTrackingArea?
    private(set) var isHovered = false
    private(set) var isPressed = false
    
    @IBInspectable var ignoreState: Bool = false
//    {
//        didSet {
//            needsDisplay = true
//        }
//    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true

        state = .off

        if let layer {
            layer.cornerRadius = 4
            layer.backgroundColor = state == .on
                ? pressedColor.cgColor
                : .clear
        }

        frame.size = CGSize(width: 32, height: 32)
        title = ""
        bezelColor = .clear
        isBordered = false
        bezelStyle = .regularSquare
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [
                .mouseEnteredAndExited,
                .activeInKeyWindow,
                .inVisibleRect
            ],
            owner: self,
            userInfo: nil
        )

        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        isPressed = true
        super.mouseDown(with: event)
        isPressed = false
    }

    override func mouseUp(with event: NSEvent) {
        isPressed = false
        super.mouseUp(with: event)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if isEnabled {
            let color: NSColor
            
            if isPressed {
                color = pressedColor
            } else {
                color = isHovered || (state == .on && ignoreState == false) ? hoverColor : .clear
            }

            color.setFill()
        } else {
            NSColor.clear.setFill()
        }
        
        bounds.fill()
        

        if let image {
            let tinted = image.copy() as! NSImage
            tinted.isTemplate = false

            tinted.lockFocus()
            if isEnabled {
                if state == .on && !ignoreState {
                    NSColor.systemBlue.set()
                } else {
                    contentTintColor?.set()
                }
            } else {
                NSColor.gray.set()
            }
            NSRect(origin: .zero, size: tinted.size).fill(using: .sourceAtop)
            tinted.unlockFocus()

            tinted.draw(in: NSRect(
                x: dirtyRect.width / 2 - image.size.width / 2,
                y: dirtyRect.height / 2 - image.size.height / 2,
                width: image.size.width,
                height: image.size.height)
            )
        }
    }
}
