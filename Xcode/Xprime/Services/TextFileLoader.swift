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

fileprivate func encodingType(_ data: inout Data) -> String.Encoding {
    if data.starts(with: [0xFF, 0xFE]) {
        data.removeFirst(2)
        return .utf16LittleEndian
    }
    if data.starts(with: [0xFE, 0xFF]) {
        data.removeFirst(2)
        return .utf16BigEndian
    }
    
    if data.count > 2, data[0] > 0, data[1] == 0 {
        return .utf16BigEndian
    }
    
    if data.count > 2, data[0] == 0, data[1] > 0 {
        return .utf16LittleEndian
    }
    
    return .utf8
}

func loadTextFile(at url: URL) -> String? {
    var encoding: String.Encoding = .utf8
    
    do {
        var data = try Data(contentsOf: url)
        encoding = encodingType(&data)
        
        return String(data: data, encoding: encoding)
    } catch {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = "Failed to open file: \(error)"
        alert.runModal()
    }
    
    return nil
}
