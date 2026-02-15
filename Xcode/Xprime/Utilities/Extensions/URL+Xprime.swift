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

extension URL {
    // Track the last revealed path
    private static var lastRevealedPath: String?
    
    /// Reveal in Finder only if this URL is different from the last revealed URL
    func revealInFinderIfNeeded() {
        let path = standardizedFileURL.path
        
        // Skip if this path is the same as the last revealed URL
        if URL.lastRevealedPath == path {
            return
        }
        
        // Skip if Finder is already frontmost
        let workspace = NSWorkspace.shared
        if workspace.frontmostApplication?.bundleIdentifier == "com.apple.finder" {
            return
        }
        
        // Record this path as last revealed and reveal in Finder
        URL.lastRevealedPath = path
        workspace.activateFileViewerSelecting([self])
    }
    
    var isDirectory: Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return isDir.boolValue
    }
    
    var modificationDate: Date? {
        try? resourceValues(forKeys: [.contentModificationDateKey])
            .contentModificationDate
    }
    
    func isNewer(than other: URL) -> Bool {
        guard let a = modificationDate,
              let b = other.modificationDate else { return false }
        return a > b
    }
}
