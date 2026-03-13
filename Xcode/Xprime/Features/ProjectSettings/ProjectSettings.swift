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

fileprivate enum DefaultsKey {
    static let compression = "Compression"
    static let include = "include"
    static let lib = "lib"
    static let calculator = "Calculator"
    static let bin = "bin"
    static let archiveProjectApplicationOnly = "ArchiveProjectApplicationOnly"
    static let plainFallbackText = "PlainFallbackText"
    static let language = "Language"
}

final class ProjectSettings {

    static let shared = ProjectSettings()
    private init() {}

    @UserDefault(key: DefaultsKey.compression, defaultValue: false)
    var compression: Bool

    @UserDefault(key: DefaultsKey.include, defaultValue: "$(SDKROOT)/include")
    var include: String

    @UserDefault(key: DefaultsKey.lib, defaultValue: "$(SDKROOT)/lib")
    var lib: String

    @UserDefault(key: DefaultsKey.calculator, defaultValue: "Prime")
    var calculator: String

    @UserDefault(key: DefaultsKey.bin, defaultValue: "/usr/local/bin")
    var bin: String

    @UserDefault(key: DefaultsKey.archiveProjectApplicationOnly, defaultValue: true)
    var archiveProjectAppOnly: Bool

    @UserDefault(key: DefaultsKey.plainFallbackText, defaultValue: true)
    var plainFallbackText: Bool
    
    @UserDefault(key: DefaultsKey.language, defaultValue: "hpppl")
    var language: String
}
