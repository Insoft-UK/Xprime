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

extension String {
    init(rtfContentsOf url: URL) throws {
        let attributed = try NSAttributedString(
            url: url,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
        self = attributed.string
    }
    
    /// Encodes characters that are invalid in macOS filenames or have special meaning in URLs.
    func underscoreEncoded(
        replacing chars: [Character: String] = [
            "%": "_25",
            "/": "_2F",
            ":": "_3A",
//            "?": "%3F",
//            "#": "%23",
//            "[": "%5B",
//            "]": "%5D",
//            "@": "%40",
//            "!": "%21",
//            "$": "%24",
//            "&": "%26",
//            "'": "%27",
//            "(": "%28",
//            ")": "%29",
//            "*": "%2A",
            "+": "_2B",
//            ",": "%2C",
//            ";": "%3B",
//            "=": "%3D",
//            "\\": "%5C",
//            "<": "%3C",
//            ">": "%3E",
//            "\"": "%22",
//            "|": "_7C"
        ]
    ) -> String {
        var result = ""

        for char in self {
            if let replacement = chars[char] {
                result += replacement
            } else {
                result.append(char)
            }
        }

        return result
    }
    
    func save(to url: URL) throws {
        if url.pathExtension.lowercased() != "prgm" {
            try write(to: url, atomically: true, encoding: .utf8)
            return
        }
        
        // UTF-16 LE with BOM
        guard let body = data(using: .utf16LittleEndian) else {
            throw NSError(domain: "Error", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode string as UTF-16LE"])
        }
        
        var data = Data([0xFF, 0xFE]) // BOM
        data.append(body)
        try data.write(to: url, options: .atomic)
    }
    
    var shellEscaped: String {
        "'" + self.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
