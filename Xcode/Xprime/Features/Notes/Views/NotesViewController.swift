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
import WebKit

final class NotesViewController: NSViewController {
    @IBOutlet weak var html: WKWebView!
    private var vc: MainViewController!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    
        guard let window = NSApplication.shared.windows.first else {
            self.view.window?.close(); return
        }
        vc = window.contentViewController as? MainViewController
        loadHTMLString()
    }
    
    private func loadHTMLString() {
        guard let url = vc.projectManager.projectDirectoryURL else { return }
        vc.documentManager.saveDocument()
        
        let executable = URL(fileURLWithPath: ToolchainPaths.bin)
            .appendingPathComponent("hpnote")
        let result = ProcessRunner.run(executable: executable, arguments: [url.appendingPathComponent("info.ntf").path, "--html", "-o", "/dev/stdout"])
        
        guard result.exitCode == 0, let out = result.out else {
            let errorHTML = """
            <html>
              <head>
                <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
                <style>
                  body { font-family: -apple-system, system-ui, Helvetica, Arial, sans-serif; color: #555; padding: 24px; }
                  h1 { font-size: 18px; color: #c00; margin: 0 0 8px 0; }
                  p { margin: 0; }
                </style>
              </head>
              <body>
                <h1>Failed to generate HTML</h1>
                <p>Please check that <code>info.ntf</code> exists and the toolchain is configured.</p>
              </body>
            </html>
            """
            html.loadHTMLString(errorHTML, baseURL: nil)
            return
        }
        html.loadHTMLString(out, baseURL: nil)
    }
    
    @IBAction func close(_ sender: Any) {
        self.view.window?.close()
    }
}

