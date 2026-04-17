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


final class PreviewViewController: NSViewController {
    @IBOutlet weak var previewTextView: PreviewTextView!
    private var vc: MainViewController!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let window = NSApplication.shared.windows.first else {
            self.view.window?.close(); return
        }
        vc = window.contentViewController as? MainViewController
        guard let url = vc.projectManager.projectDirectoryURL else { return }
        
        vc.documentManager.saveDocument()
        
        let executable = URL(fileURLWithPath: ToolchainPaths.bin).appendingPathComponent("hpppl+")
        
        var mainURL = url.appendingPathComponent("main.hppplplus")
        if FileManager.default.fileExists(atPath: url.appendingPathComponent("main.hppplplus").path) == false {
            mainURL = url.appendingPathComponent("main.hpppl")
        }
        
        var arguments: [String] = [mainURL.path, "-o", "/dev/stdout"]
        
        if ProjectSettings.shared.compression {
            arguments.append(contentsOf: ["--compress"])
        }
        
        let result = ProcessRunner.run(
            executable: executable,
            arguments: arguments
        )
        
        guard result.exitCode == 0, let out = result.out else {
            return
        }
        
        previewTextView.appendTextAndScroll(out)
        previewTextView.ScrollToTop()
        previewTextView.backgroundColor = .clear
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard let window = view.window else { return }
        
        // Make window background transparent
        window.isOpaque = false
        
        // Optional: remove title bar / standard window decorations
        window.titleVisibility = .hidden
        window.center()
        window.titlebarAppearsTransparent = true
        window.styleMask = [.nonactivatingPanel, .titled]
        window.styleMask.insert(.fullSizeContentView)
        window.level = .floating
    }

    
    
}

