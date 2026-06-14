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

// MARK: - Snippet Models
struct JSONSnippet: Decodable {
    let title: String
    let body: [String]
    let description: String?
}

struct SnippetPlaceholder {
    let index: Int
    var ranges: [NSRange]
}

// MARK: - Snippet Parsing
func parseSnippet(_ body: String) -> (text: String, placeholders: [SnippetPlaceholder]) {
    let pattern = #"\$\{(\d+):([^}]+)\}|\$\{(\d+)\}|\$(\d+)"#
    let regex = try! NSRegularExpression(pattern: pattern)
    
    let nsBody = body as NSString
    let matches = regex.matches(in: body, range: NSRange(location: 0, length: nsBody.length))
    
    var text = ""
    var placeholderRanges: [Int: [NSRange]] = [:]
    
    var lastIndex = 0
    
    for match in matches {
        let prefixRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
        text += nsBody.substring(with: prefixRange)
        
        var index = 0
        var value = ""
        
        if match.range(at: 1).location != NSNotFound {
            index = Int(nsBody.substring(with: match.range(at: 1))) ?? 0
            value = nsBody.substring(with: match.range(at: 2))
        } else if match.range(at: 3).location != NSNotFound {
            index = Int(nsBody.substring(with: match.range(at: 3))) ?? 0
        } else {
            index = Int(nsBody.substring(with: match.range(at: 4))) ?? 0
        }
        
        let start = (text as NSString).length
        text += value
        let range = NSRange(location: start, length: value.count)
        placeholderRanges[index, default: []].append(range)
        
        lastIndex = match.range.location + match.range.length
    }
    
    if lastIndex < nsBody.length {
        text += nsBody.substring(from: lastIndex)
    }
    
    let placeholders = placeholderRanges
        .map { SnippetPlaceholder(index: $0.key, ranges: $0.value.sorted { $0.location < $1.location }) }
        .sorted {
            if $0.index == 0 { return false }
            if $1.index == 0 { return true }
            return $0.index < $1.index
        }
    
    return (text, placeholders)
}

func loadSnippets(from url: URL) -> [String: String] {
    var snippets: [String: String] = [:]
    let decoder = JSONDecoder()
    
    let resolvedURL = url.resolvingSymlinksInPath()
    
    do {
        let files = try FileManager.default.contentsOfDirectory(
            at: resolvedURL,
            includingPropertiesForKeys: nil
        )
        for file in files where file.pathExtension == "xpsnippet" {
            guard let data = try? Data(contentsOf: file),
                  let json = try? decoder.decode(JSONSnippet.self, from: data) else { continue }
            let text = json.body.joined(separator: "\n")
            let trigger = file.deletingPathExtension().lastPathComponent
            snippets["§\(trigger)"] = text
        }
    } catch {
        print(error)
    }
    
    
    return snippets
}

// MARK: - Snippet Session
final class SnippetSession {
    var placeholders: [SnippetPlaceholder]
    var currentIndex = 0
    
    init(placeholders: [SnippetPlaceholder]) {
        self.placeholders = placeholders
    }
    
    func nextPlaceholder() -> [NSRange]? {
        guard currentIndex < placeholders.count else { return nil }
        let ranges = placeholders[currentIndex].ranges
        currentIndex += 1
        return ranges
    }
}
