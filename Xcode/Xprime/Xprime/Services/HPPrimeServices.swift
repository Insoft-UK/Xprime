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

// ✅ Completed: CLOSED TO FURTHER IMPROVMENTS

import Cocoa

enum HPPrimeServices {
    /// Checks whether an HP Prime program is installed in the HP Connectivity Kit.
    ///
    /// - Parameters:
    ///   - name: The name of the program to check for, without the .hpprgm extension.
    ///   - user: An optional username reserved for user-specific checks. Currently unused.
    /// - Returns: true if the program file exists in the Connectivity Kit’s Content directory; otherwise, false.
    static func isProgramInstalled(named name: String, forUser user: String? = nil) -> Bool {
        let url = Constants.HPConnectivityKit.directoryURL
            .appending(path: "Content/\(name).hpprgm")

        return FileManager.default.fileExists(atPath: url.path)
    }
    
    /// Checks whether an HP Prime application directory is installed in the
    /// expected calculator or Connectivity Kit location.
    ///
    /// If a username is provided and a corresponding directory exists in the
    /// Connectivity Kit, that user’s content directory is checked. Otherwise,
    /// the default HP Prime calculator directory is used.
    ///
    /// - Parameters:
    ///   - name: The name of the application directory to check for, without the .hpappdir extension.
    ///   - user: An optional username used to select a user-specific content directory.
    /// - Returns: true if the application directory exists at the selected location; otherwise, false.
    static func isAppDirectoryInstalled(named name: String, forUser user: String? = nil) -> Bool {
        let baseURL: URL
        
        if let user = user, Constants.HPConnectivityKit.directoryURL.appending(path: user).directoryExists {
            baseURL = FileManager.default.homeDirectoryForCurrentUser
                .appending(path: "Documents/HP Connectivity Kit/Content")
                .appending(path: user)
        } else {
            baseURL = FileManager.default.homeDirectoryForCurrentUser
                .appending(path: "Documents/HP Prime/Calculators/Prime")
        }

        let appDirURL = baseURL.appending(path: "\(name).hpappdir")
        return appDirURL.directoryExists
    }

    
    // MARK: - HP Prime Application
    enum AppError: Error {
        case invalidAppName
    }
    
    /// Sanitizes an application name by removing invalid filename characters
    /// and trimming surrounding whitespace. Throws an error if the resulting
    /// name is empty.
    private static func fileSafeName(from name: String) throws -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let sanitized = name
            .components(separatedBy: invalidCharacters)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sanitized.isEmpty else {
            throw AppError.invalidAppName
        }

        return sanitized
    }
    
    /// Ensures the specified directory exists, creating it and any
    /// intermediate directories if necessary.
    private static func ensureDirectoryExists(_ url: URL) throws {
        if !url.directoryExists {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
        }
    }
    
    /// Creates an empty `.hpappnote` file for the specified application if one does not already exist.
    /// Optionally sets the file's creation and modification dates to the supplied seed date.
    private static func createNoteFileIfMissing(
        to destination: URL,
        named appName: String,
        date seedDate: Date? = nil,
        fileManager: FileManager = .default
    ) throws {
        let fileURL = destination
            .appending(path: appName)
            .appendingPathExtension("hpappnote")
        
        guard !fileManager.fileExists(atPath: fileURL.path) else { return }

        let data = Data([0x00, 0x00])
        try data.write(to: fileURL, options: .atomic)
        guard let seedDate else { return }
        try setFileDates(at: fileURL, creationDate: seedDate, modificationDate: seedDate)
    }
      
    /// Copies the source file to the destination if it does not already exist.
    /// Optionally sets the destination file's creation and modification dates
    /// to the supplied seed date.
    private static func copyIfMissing(
        from source: URL,
        to destination: URL,
        date seedDate: Date? = nil,
        fileManager: FileManager = .default
    ) throws {
        guard !fileManager.fileExists(atPath: destination.path) else { return }
        try fileManager.copyItem(at: source, to: destination)
        guard let seedDate else { return }
        try setFileDates(at: destination, creationDate: seedDate, modificationDate: seedDate)
    }
    
    /// Sets the creation and modification dates of the specified file or directory.
    private static func setFileDates(
        at url: URL,
        creationDate: Date,
        modificationDate: Date,
        fileManager: FileManager = .default
    ) throws {
        let attributes: [FileAttributeKey: Any] = [
            .creationDate: creationDate,
            .modificationDate: modificationDate
        ]

        try fileManager.setAttributes(attributes, ofItemAtPath: url.path)
    }
    
    /// Populates the application directory with the default icon, application file,
    /// and note file if they do not already exist, using a shared creation date
    /// for any newly created files.
    private static func seedAppDirectory(
        _ appDirectoryURL: URL,
        appName: String,
        baseApplicationURL: URL,
        baseApplicationName: String
    ) throws {

        let seedDate = creationDate()
        
        try copyIfMissing(
            from: baseApplicationURL.appending(path: "\(baseApplicationName).png"),
            to: appDirectoryURL
                .appending(path: "icon.png"),
            date: seedDate
        )

        try copyIfMissing(
            from: baseApplicationURL.appending(path: "\(baseApplicationName).hpapp"),
            to: appDirectoryURL
                .appending(path: appName)
                .appendingPathExtension("hpapp"),
            date: seedDate
        )
        
        try createNoteFileIfMissing(to: appDirectoryURL, named: appName, date: seedDate)
    }
    
    /// Returns a fixed reference date of 1 January 2026 at 00:00:00 UTC.
    /// Falls back to the Unix epoch if the date cannot be constructed.
    private static func creationDate() -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)! // UTC

        let components = DateComponents(year: 2026, month: 1, day: 1, hour: 0, minute: 0, second: 0)

        guard let date = calendar.date(from: components) else {
            return Date(timeIntervalSince1970: 0)
        }
        return date
    }
    
    // MARK: -
    
    /// Ensures that an HP application directory exists and is initialised using
    /// the specified base application template.
    ///
    /// - Parameters:
    ///   - directory: The parent directory in which the HP application directory resides.
    ///   - appName: The name of the HP application to create or initialise.
    ///   - baseAppName: The name of the base application template to use.
    ///     Defaults to "None".
    /// - Throws: An error if the application name is invalid or the directory
    ///   cannot be created or initialised.
    static func ensureAppDirectory(
        at directory: URL,
        named appName: String,
        fromBaseApplicationNamed baseAppName: String = "None"
    ) throws {

        let safeName = try fileSafeName(from: appName)

        let baseApplicationURL = Bundle.main.bundleURL
            .appending(path: "Contents/Resources/Developer/Library/Xprime/Templates/Base Applications")
            .appending(path: baseAppName)
            .appendingPathExtension("hpappdir")

        let appDirectoryURL = directory
            .appending(path: safeName)
            .appendingPathExtension("hpappdir")

        try ensureDirectoryExists(appDirectoryURL)

        try seedAppDirectory(
            appDirectoryURL,
            appName: safeName,
            baseApplicationURL: baseApplicationURL,
            baseApplicationName: baseAppName
        )
    }
    
    /// Resets the contents of an HP application directory by removing its existing
    /// application file and, if applicable, its default icon, then recreating the
    /// application directory using the specified base application as a template.
    ///
    /// - Parameters:
    ///   - directory: The parent directory in which the HP application directory resides.
    ///   - appName: The name of the HP application to reset.
    ///   - baseAppName: The name of the base application used to recreate the contents.
    ///     Defaults to `"None"`.
    /// - Throws: An error if the application name is invalid or a required directory
    ///   or application setup operation fails.
    static func resetHPAppContents(
        at directory: URL,
        named appName: String,
        fromBaseApplicationNamed baseAppName: String = "None"
    ) throws {

        let safeName = try fileSafeName(from: appName)

        let appDirectoryURL = directory
            .appending(path: safeName)
            .appendingPathExtension("hpappdir")

        try ensureDirectoryExists(appDirectoryURL)
        
        let iconURL = appDirectoryURL
            .appending(path: "icon")
            .appendingPathExtension("png")
        
        let seedDate = creationDate()
        if let attributes = try? FileManager.default.attributesOfItem(atPath: iconURL.path),
           let modificationDate = attributes[.modificationDate] as? Date,
           modificationDate == seedDate {
            
            try? FileManager.default.removeItem(at: iconURL)
        }


        try? FileManager.default.removeItem(
            at: appDirectoryURL
                .appending(path: safeName)
                .appendingPathExtension("hpapp")
        )

        try ensureAppDirectory(
            at: directory,
            named: appName,
            fromBaseApplicationNamed: baseAppName
        )
    }
    
    // MARK: -
    /// Archives an HP application directory into a ZIP file, ensuring the application
    /// directory is initialised before creating the archive.
    ///
    /// The archive is named name.hpappdir.zip and excludes .DS_Store files.
    /// An existing archive at the destination is removed before archiving.
    ///
    /// - Parameters:
    ///   - directory: The directory containing the HP application directory.
    ///   - name: The name of the HP application directory to archive.
    ///   - desctinationURL: An optional directory in which to save the archive.
    ///     Defaults to nil, which saves the archive in directory.
    /// - Returns: A tuple containing the standard output, standard error, and
    ///   process exit code. If application initialisation fails, the output is
    ///   nil, the error describes the failure, and the exit code is -1.
    static func archiveAppDirectory(in directory: URL, named name: String, to desctinationURL: URL? = nil) -> (out: String?, err: String?, exitCode: Int32)  {
        do {
            try ensureAppDirectory(at: directory, named: name)
        } catch {
            return (nil, "Failed to restore missing app files: \(error)", -1)
        }
        
        var destinationPath = "\(name).hpappdir.zip"
        
        if let desctinationURL = desctinationURL {
            try? FileManager.default.removeItem(at: desctinationURL.appending(path: "\(name).hpappdir.zip"))
            destinationPath = desctinationURL.appending(path: "\(name).hpappdir.zip").path
        } else {
            try? FileManager.default.removeItem(at: directory.appending(path: "\(name).hpappdir.zip"))
        }
        
        
        return ProcessRunner.run(
            executable: URL(fileURLWithPath: "/usr/bin/zip"),
            arguments: [
                "-r",
                destinationPath,
                "\(name).hpappdir",
                "-x", "*.DS_Store"
            ],
            currentDirectory: directory
        )
    }
    
    /// Exports application content to the HP Connectivity Kit by replacing its
    /// existing Content directory with a copy of the specified source.
    ///
    /// - Parameter url: The URL of the content to export.
    /// - Throws: An error if the existing destination cannot be removed or the
    ///   source content cannot be copied to the Connectivity Kit.
    static func exportToConnectivityKitContent(at url: URL) throws {
        let destinationURL = Constants.HPConnectivityKit.directoryURL
            .appending(path: "Content")
            .appending(path: url.lastPathComponent)

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.copyItem(at: url, to: destinationURL)
        }
    }
    
    /// Exports an HP Prime application or program to the specified calculator
    /// directory within the HP Prime Virtual Calculator.
    ///
    /// Existing items at the destination are replaced. If the source is an HP Prime
    /// program rather than an application directory, its associated .hpnote file
    /// is also copied, replacing any existing note file.
    ///
    /// - Parameters:
    ///   - url: The URL of the HP Prime application directory or program file to export.
    ///   - name: The name of the destination calculator directory. Defaults to "Prime".
    /// - Throws: An error if an existing destination cannot be removed or the
    ///   application, program, or associated note file cannot be copied.
    static func exportToPrimeVirtualCalculator(at url: URL, named name: String = "Prime") throws {
        let destinationURL = Constants.HPPrimeVirtualCalculator.directoryURL
            .appending(path: "Calculators/\(name)")
            .appending(path: url.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.copyItem(at: url, to: destinationURL)
        }
        
        if url.directoryExists {
            // It's a HP Prime Application, so were done an nothing else required.
            return
        }
        
        // It's a HP Prime Program so we must copy over the .hpnote is exits
        if FileManager.default.fileExists(
            atPath: Constants.HPPrimeVirtualCalculator.directoryURL
                .appending(path: "Calculators/\(name)/\(url.deletingPathExtension().lastPathComponent).hpnote")
                .path
        ) {
            try FileManager.default.removeItem(
                at: Constants.HPPrimeVirtualCalculator.directoryURL
                    .appending(path: "Calculators/\(name)/\(url.deletingPathExtension().lastPathComponent).hpnote")
            )
        }
        
        if url.deletingPathExtension()
            .appendingPathExtension("hpnote")
            .fileExists
        {
            try FileManager.default.copyItem(
                at: url.deletingPathExtension()
                    .appendingPathExtension("hpnote"),
                to: Constants.HPPrimeVirtualCalculator.directoryURL
                    .appending(path: "Calculators/\(name)/\(url.deletingPathExtension().lastPathComponent).hpnote")
            )
        }
        
    }
}
