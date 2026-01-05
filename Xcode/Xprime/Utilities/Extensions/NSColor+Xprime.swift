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

extension NSColor {
    convenience init?(hex: String) {
        var hexString = hex
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        
        var hexNumber: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&hexNumber) else { return nil }
        
        let r, g, b, a: CGFloat
        
        switch hexString.count {
        case 6: // RRGGBB
            r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
            g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
            b = CGFloat(hexNumber & 0x0000FF) / 255
            a = 1.0
        case 8: // RRGGBBAA
            r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000FF) / 255
        default:
            return nil
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
    /// Returns either black or white, whichever has higher contrast
    func contrastColor() -> NSColor {
        guard let color = self.usingColorSpace(.deviceRGB) else {
            return .black
        }
        
        func linearize(_ c: CGFloat) -> CGFloat {
            (c <= 0.03928) ? (c / 12.92) : pow((c + 0.055) / 1.055, 2.4)
        }
        
        let r = linearize(color.redComponent)
        let g = linearize(color.greenComponent)
        let b = linearize(color.blueComponent)
        
        let backgroundLuminance =
        0.2126 * r +
        0.7152 * g +
        0.0722 * b
        
        let whiteContrast = (1.0 + 0.05) / (backgroundLuminance + 0.05)
        let blackContrast = (backgroundLuminance + 0.05) / 0.05
        
        return whiteContrast >= blackContrast ? .white : .black
    }
}
