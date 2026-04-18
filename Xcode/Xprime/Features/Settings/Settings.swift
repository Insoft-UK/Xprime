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

fileprivate enum DefaultsKey {
    static let subtitutionEnabled = "SubstitutionEnabled"
    static let preferredTheme = "PreferredTheme"
    static let lastOpenedFile = "LastOpenedFile"
    static let lastOpenedProjectFile = "LastOpenedProjectFile"
    static let location = "Location"
    static let supportedDocumentExtensions = "SupportedDocumentExtensions"
    static let allowedOpenFileExtensions = "AllowedOpenFileExtensions"
    static let allowedSaveFileExtensions = "AllowedSaveFileExtensions"
    static let recentFiles = "RecentFiles"
    static let useBetaApplications = "UseBetaApplications"
}

final class Settings {

    static let shared = Settings()
    private init() {}

    @UserDefault(key: "SubstitutionEnabled", defaultValue: false)
    var substitutionEnabled: Bool
    
    @UserDefault(key: "PreferredTheme", defaultValue: "Default (Dark)")
    var preferredTheme: String
    
    @UserDefault(key: DefaultsKey.lastOpenedFile, defaultValue: "")
    var lastOpenedFile: String
    
    @UserDefault(key: DefaultsKey.lastOpenedProjectFile, defaultValue: "")
    var lastOpenedProjectFile: String
    
    @UserDefault(
        key: DefaultsKey.location,
        defaultValue: FileManager
        .default
        .homeDirectoryForCurrentUser
        .appendingPathComponent("Xprime")
        .path
    )
    var location: String
    
    @UserDefault(
        key: DefaultsKey.supportedDocumentExtensions,
        defaultValue: [
            "hpppl", "hppplplus", "ntf", "py"
        ]
    )
    var supportedDocumentExtensions: [String]
    
    @UserDefault(
        key: DefaultsKey.allowedOpenFileExtensions,
        defaultValue: [
            "xprimeproj", "hpppl", "hppplplus", "prgm", "hpprgm", "hpappprgm", "hpappnote", "hpnote", "ntf", "py", "h", "bmp", "png"
        ]
    )
    var allowedOpenFileExtensions: [String]
    
    @UserDefault(
        key: DefaultsKey.allowedSaveFileExtensions,
        defaultValue: [
            "hpppl", "hppplplus", "prgm", "hpprgm", "hpappprgm", "hpappnote", "hpnote", "ntf", "py"
        ]
    )
    var allowedSaveFileExtensions: [String]
    
    @UserDefault(
        key: DefaultsKey.recentFiles,
        defaultValue: []
    )
    var recentFiles: [String]

    @UserDefault(key: DefaultsKey.useBetaApplications, defaultValue: false)
    var useBetaApplications: Bool
}
