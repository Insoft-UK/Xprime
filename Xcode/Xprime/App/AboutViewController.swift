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

// MARK: ✅ Done

import Cocoa


final class AboutViewController: NSViewController {
    @IBOutlet weak var Version: NSTextField!
    @IBOutlet weak var Tools: NSTextField!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let bundleShortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "26.0"
        Version.stringValue = "Version \(bundleShortVersion)"
        toolsInfo()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard let window = view.window else { return }
        
        // Make window background transparent
        window.isOpaque = false
        window.backgroundColor = NSColor(white: 0, alpha: 0.0)
        
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask = [.nonactivatingPanel, .titled]
        window.styleMask.insert(.fullSizeContentView)
      
        window.center()
        window.level = .floating
        window.hasShadow = true
        
    }
    
    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.option) {
            let bundleShortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "26.0"
            let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
            Version.stringValue = "Version \(bundleShortVersion).\(bundleVersion)"
            Tools.isHidden = false
            return
        }
        self.view.window?.close()
    }
    
    override func mouseUp(with event: NSEvent) {
        let bundleShortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "26.0"
        Version.stringValue = "Version \(bundleShortVersion)"
        Tools.isHidden = true
    }
    
    private func toolsInfo() {
        let `ppl+` = version(forTool: "ppl+");
        let grob = version(forTool: "GROB");
        let font = version(forTool: "font");
        let note = version(forTool: "note");
        
        Tools.stringValue = "PPL+ \(`ppl+`) - GROB+ \(grob) - FONT \(font) - NOTE \(note)"
    }
    
    private func version(forTool tool: String) -> String {
        let command = ToolchainPaths.bin.appendingPathComponent(tool).path
        let version = ProcessRunner.run(
            executable: URL(fileURLWithPath: command),
            arguments: ["--version"]
        )
        
        var text = version.out ?? ""
        
        if text.hasSuffix("\n") {
            text.removeLast()
        }
        
        return text
    }
}

