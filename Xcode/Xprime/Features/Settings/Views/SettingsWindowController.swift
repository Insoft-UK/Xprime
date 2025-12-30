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

final class SettingsWindowController: NSWindowController {
    // Customize this to any color you like; supports alpha as well
    var preferredBackgroundColor: NSColor = .init(white: 0.1, alpha: 1.0)
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.titleVisibility = .hidden
        window?.titlebarAppearsTransparent = false
        window?.level = .floating // Keeps the window above other windows if needed
        window?.isOpaque = false // allow alpha in background color
        window?.hasShadow = true
        window?.backgroundColor = preferredBackgroundColor.withAlphaComponent(1.0)
        applyPersistedWindowSettings()

        
        if let contentView = window?.contentView {
            contentView.wantsLayer = true
            contentView.layer?.backgroundColor = preferredBackgroundColor.cgColor
        }
        
        
    }
    
    private func applyPersistedWindowSettings() {
        guard let window = window else { return }
        
        
        // Lock content view to a fixed size to prevent Auto Layout-driven resizing
        if let contentView = window.contentView {
            contentView.translatesAutoresizingMaskIntoConstraints = false

            // Remove any prior size constraints you may have added before (optional if not applicable)
            NSLayoutConstraint.deactivate(contentView.constraints.filter {
                $0.firstAttribute == .width || $0.firstAttribute == .height
            })

            let widthConstraint = contentView.widthAnchor.constraint(equalToConstant: window.contentRect(forFrameRect: window.frame).size.width)
            let heightConstraint = contentView.heightAnchor.constraint(equalToConstant: window.contentRect(forFrameRect: window.frame).size.height)
            widthConstraint.priority = .required
            heightConstraint.priority = .required
            NSLayoutConstraint.activate([widthConstraint, heightConstraint])
        }
    }
}

