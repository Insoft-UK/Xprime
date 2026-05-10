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

class CustomViewController: NSViewController {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // Ensure UI work happens on the main thread without spawning a new Task to avoid QoS inversions
        if let window = view.window {
            // Make window background transparent
            window.isOpaque = false
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            
            if Settings.shared.visualEffectEnabled, let contentView = window.contentView {
                // Add blur view behind content
                let blurView = NSVisualEffectView(frame: contentView.bounds)
                blurView.autoresizingMask = [.width, .height]
                blurView.material = .hudWindow // .underWindowBackground
                blurView.blendingMode = .behindWindow
                blurView.state = .active
                
                
                final class PassthroughView: NSView {
                    override func hitTest(_ point: NSPoint) -> NSView? {
                        nil
                    }
                }
                
                let tintView = PassthroughView(frame: contentView.bounds)
                tintView.autoresizingMask = [.width, .height]
                tintView.wantsLayer = true
                
                tintView.layer?.backgroundColor =
                    NSColor.black.withAlphaComponent(0.25).cgColor
                
                
                contentView.addSubview(tintView, positioned: .below, relativeTo: nil)
                contentView.addSubview(blurView, positioned: .below, relativeTo: nil)
                
                contentView.wantsLayer = true
                if let layer = contentView.layer {
                    layer.cornerRadius = 16
                    layer.masksToBounds = true
                    layer.borderWidth = 0.0
                    layer.borderColor = NSColor(white: 0.5, alpha: 0.15).cgColor
                }
            }
            
//            window.initialFirstResponder = nil
//            window.makeFirstResponder(nil)
        }
    }
}
