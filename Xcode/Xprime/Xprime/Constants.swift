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

enum Constants {
    enum IconSizes {
        static let tiny = CGSize(width: 16, height: 16)
        static let small = CGSize(width: 18, height: 18)
        static let big = CGSize(width: 24, height: 24)
    }
    
    enum Identifiers {
        static let notes = "notes"
        static let autoIndentation = "autoIndentation"
        static let substitution = "substitution"
    }
    
    enum BundleIdentifier {
        static let hpPrime = "com.moravia-consulting.hp-prime"
        static let hpPrimeBeta = "com.moravia-consulting.hp-prime.beta"
        
        static let hpConnectivityKit = "com.moravia-consulting.hp-connectivity-kit"
        static let hpConnectivityKitBeta = "com.moravia-consulting.hp-connectivity-kit.beta"
    }
    
    enum HPConnectivityKit {
        static let directoryURL = FileManager
            .default
            .homeDirectoryForCurrentUser
            .appending(path: "Documents", directoryHint: .isDirectory)
            .appending(path: "HP Connectivity Kit", directoryHint: .isDirectory)
    }
    
    enum HPPrime {
        static let directoryURL = FileManager
            .default
            .homeDirectoryForCurrentUser
            .appending(path: "Documents", directoryHint: .isDirectory)
            .appending(path: "HP Prime", directoryHint: .isDirectory)
    }
}
