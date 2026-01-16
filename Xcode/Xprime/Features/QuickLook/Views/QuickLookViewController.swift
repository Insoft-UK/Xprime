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


final class QuickLookViewController: NSViewController {
    
    @IBOutlet weak var quickLookTextView: QuickLookTextView!
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard let window = view.window else { return }
        
        // Make window background transparent
        window.isOpaque = false
        window.backgroundColor = NSColor(white: 0, alpha: 0.9)
        
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask = [.nonactivatingPanel, .titled]
        window.styleMask.insert(.fullSizeContentView)
      
        
        window.center()
        window.level = .floating
        window.hasShadow = true
        
        if let path = UserDefaults.standard.string(forKey: "lastOpenedFilePath") {
            let url = URL(fileURLWithPath: path)
                .deletingLastPathComponent()
            
            // Prioritize main.prgm+
            if FileManager.default.fileExists(
                atPath: url
                    .appendingPathComponent("main.prgm+")
                    .path
            ) {
                loadText(
                    from: url
                        .appendingPathComponent("main.prgm+")
                )
            } else {
                loadText(
                    from: url
                        .appendingPathComponent(url.lastPathComponent + ".prgm+")
                )
            }
        } else {
            self.view.window?.close()
        }
        
    }
    
    @IBAction func close(_ sender: Any) {
        self.view.window?.close()
    }
    
    private func loadText(from url: URL) {
        let destinationURL = URL(fileURLWithPath: "/dev/stdout")
        
        let result = HPServices.preProccess(at: url, to: destinationURL)
        guard let out = result.out, result.exitCode == 0 else {
            self.view.window?.close()
            return
        }
        
        quickLookTextView.changeText(out)
    }
}

