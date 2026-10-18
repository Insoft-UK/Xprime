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

// ✅ Completed: CLOSED TO FURTHER IMPROVMENTS

import Foundation

/// Returns the existing application UUID, or generates and saves one on first use.
///
/// - Parameter companyName: The company name used to determine the UUID’s storage directory.
/// - Returns: The existing UUID if available, or a newly generated UUID. If saving fails, returns a UUID for the current session.
enum AppUUID {
    private static let fileName = Bundle.main.bundleIdentifier

    /// Returns the existing UUID or generates a new one if none exists.
    /// - Parameter companyName: The company name used with the application name to determine the UUID’s storage location.
    /// - Returns: The UUID as a string.
    static func get(companyName: String) -> String {
        if let existingID = read(companyName: companyName) {
            return existingID
        }

        let newID = UUID().uuidString

        if save(newID, companyName: companyName) {
            return newID
        }

        return newID
    }

    private static func fileURL(companyName: String) -> URL? {
        guard let applicationSupport =
                FileManager.default.urls(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask
                ).first,
              let fileName,
              let appName = Bundle.main.object(
                  forInfoDictionaryKey: "CFBundleName"
              ) as? String
        else {
            return nil
        }

        let directory = applicationSupport
            .appendingPathComponent(companyName, isDirectory: true)
            .appendingPathComponent(appName, isDirectory: true)

        return directory.appendingPathComponent(fileName)
    }

    private static func read(companyName: String) -> String? {
        guard let url = fileURL(companyName: companyName),
              let data = try? Data(contentsOf: url),
              let value = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        let id = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return UUID(uuidString: id) == nil ? nil : id
    }

    @discardableResult
    private static func save(
        _ id: String,
        companyName: String
    ) -> Bool {
        guard let url = fileURL(companyName: companyName),
              let data = id.data(using: .utf8)
        else {
            return false
        }

        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
