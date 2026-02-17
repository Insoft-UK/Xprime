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
    private static var lastRevealedPath: String?
    private static var lastRevealedTime: Date?
    
    func revealInFinderWithCooldown(timeout: TimeInterval = 5.0) {
        let path = standardizedFileURL.path
        let now = Date()
        
        // If same path was revealed recently → block and reset timer
        if URL.lastRevealedPath == path,
           let lastTime = URL.lastRevealedTime,
           now.timeIntervalSince(lastTime) < timeout {
            
            // ⏱ Reset cooldown on spam click
            URL.lastRevealedTime = now
            return
        }
        
        // Different path OR cooldown expired → allow reveal
        URL.lastRevealedPath = path
        URL.lastRevealedTime = now
        NSWorkspace.shared.activateFileViewerSelecting([self])
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
