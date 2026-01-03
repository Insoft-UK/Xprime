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


extension NSTextView {    
    func highlightBold(_ searchString: String, caseInsensitive: Bool = true) {
        guard let textStorage = self.textStorage, !searchString.isEmpty else { return }
        
        let nsString = textStorage.string as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        
        textStorage.beginEditing()
        
        // Reset fonts in full range (optional, only if needed)
        textStorage.enumerateAttribute(.font, in: fullRange) { value, range, _ in
            var searchRange = range
            while true {
                let options: NSString.CompareOptions = caseInsensitive ? [.caseInsensitive] : []
                let foundRange = nsString.range(of: searchString, options: options, range: searchRange)
                
                if foundRange.location == NSNotFound { break }
                
                // Convert to bold preserving traits
                if let font = textStorage.attribute(.font, at: foundRange.location, effectiveRange: nil) as? NSFont {
                    let boldFont = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
                    textStorage.addAttribute(.font, value: boldFont, range: foundRange)
                }
                
                // Move search range forward
                let nextLocation = foundRange.location + foundRange.length
                if nextLocation >= nsString.length { break }
                searchRange = NSRange(location: nextLocation, length: nsString.length - nextLocation)
            }
        }
        
        textStorage.endEditing()
    }
}
