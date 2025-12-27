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

enum ToolchainPaths {

    static var developerRoot: URL {
        Bundle.main.bundleURL
            .appendingPathComponent("Contents/Resources/Developer")
    }

    static var bin: URL {
        developerRoot.appendingPathComponent("usr/bin")
    }

    static var include: URL {
        resolveUserPath(
            key: "include",
            fallback: "$(SDK)/include",
            bundled: developerRoot.appendingPathComponent("usr/include")
        )
    }

    static var lib: URL {
        resolveUserPath(
            key: "lib",
            fallback: "$(SDK)/lib",
            bundled: developerRoot.appendingPathComponent("usr/lib")
        )
    }

    private static func resolveUserPath(
        key: String,
        fallback: String,
        bundled: URL
    ) -> URL {

        let value = UserDefaults.standard.string(forKey: key) ?? fallback

        if value == "~" {
            return bundled
        }

        return URL(fileURLWithPath: value)
    }
}
