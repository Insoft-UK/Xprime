// The MIT License (MIT)
//
// Copyright (c) 2025-2026 Insoft.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
enum XprimeUserID {
    private static let fileName = "XprimeUserID"
    /// Returns the existing XPrime ID, or creates one on first run.
    static func get() -> String {
        if let existingID = read() {
            return existingID
        }
        let newID = UUID().uuidString
        if save(newID) {
            return newID
        }
        // If the ID cannot be saved, still provide an ID for this session.
        return newID
    }
    // MARK: - Storage
    private static var fileURL: URL? {
        guard let applicationSupport =
                FileManager.default.urls(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask
                ).first
        else {
            return nil
        }
        let directory =
            applicationSupport
                .appendingPathComponent("Insoft", isDirectory: true)
                .appendingPathComponent("Xprime", isDirectory: true)
        return directory.appendingPathComponent(fileName)
    }
    
    private static func read() -> String? {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url),
              let value = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        let id = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !id.isEmpty,
              UUID(uuidString: id) != nil
        else {
            return nil
        }

        return id
    }
    
    @discardableResult
    private static func save(_ id: String) -> Bool {
        guard let url = fileURL,
              let data = id.data(using: .utf8)
        else {
            return false
        }
        do {
            let directory = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try data.write(
                to: url,
                options: .atomic
            )
            return true
        } catch {
            return false
        }
    }
}
