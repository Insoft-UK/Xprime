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

let templatesBasePath = "Contents/Resources/Developer/Library/Xprime/Templates/File Templates"
let applicationTemplateBasePath = "Contents/Resources/Developer/Library/Xprime/Templates/Application Template"
let baseApplicationPath = "Contents/Resources/Developer/Library/Xprime/Templates/Base Applications"


fileprivate func launchApplication(named appName: String, arguments: [String] = []) {
    switch launchApp(named: appName, arguments: arguments) {
    case .success:
        return
    case .failure(let error):
        let alert = NSAlert()
        alert.messageText = "Launch Failed"
        
        switch error {
        case .notFound:
            alert.informativeText = "The app was not found: \(appName)"
        case .invalidPath:
            alert.informativeText = "Invalid app path: \(appName)"
        case .launchFailed(let err):
            alert.informativeText = "Failed to launch: \(err.localizedDescription)"
        }
        
        alert.runModal()
        return
    }
}

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

enum HPServices {
    static private func loadTextFile(at url: URL) -> String? {
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
    

    static var isVirtualCalculatorInstalled: Bool {
        let platform = UserDefaults.standard.object(forKey: "platform") as? String ?? "macOS"
        
        if platform == "macOS" {
            return FileManager.default.fileExists(atPath: "/Applications/HP Prime.app/Contents/MacOS/HP Prime")
        }
        
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        return FileManager.default.fileExists(atPath: homeDirectory.appendingPathComponent(".wine/drive_c/Program Files/HP/HP Prime Virtual Calculator/HPPrime.exe").path)
    }
    
    static var isConnectivityKitInstalled: Bool {
        let platform = UserDefaults.standard.object(forKey: "platform") as? String ?? "macOS"
        
        if platform == "macOS" {
            return FileManager.default.fileExists(atPath: "/Applications/HP Connectivity Kit.app/Contents/MacOS/HP Connectivity Kit")
        }
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        return FileManager.default.fileExists(atPath: homeDirectory.appendingPathComponent(".wine/drive_c/Program Files/HP/HP Connectivity Kit/ConnectivityKit.exe").path)
    }
    
    static func hpPrimeCalculatorExists(named name: String) -> Bool {
        guard !name.isEmpty else { return false }
        
        let calculatorURL = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/HP Connectivity Kit/Calculators")
            .appendingPathComponent(name)
        
        print(calculatorURL.isDirectory)
        return calculatorURL.isDirectory
    }
    
    static func hpPrimeDirectory(forUser user: String = "Prime") -> URL? {
        let calculator = UserDefaults.standard.object(forKey: "calculator") as? String ?? "Prime"
        
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        
        let directoryURL: URL
        let user = calculator
        
        if hpPrimeCalculatorExists(named: user) {
            if HPServices.isConnectivityKitInstalled == false {
                return nil
            }
            directoryURL = homeURL
                .appendingPathComponent("Documents/HP Connectivity Kit/Calculators")
                .appendingPathComponent(user)
        } else {
            if HPServices.isVirtualCalculatorInstalled == false {
                return nil
            }
            directoryURL = homeURL
                .appendingPathComponent("Documents/HP Prime/Calculators/Prime")
        }
        
        if directoryURL.isDirectory == false {
            return nil
        }
        
        return directoryURL
    }
    
    static func hpPrgmIsInstalled(named name: String, forUser user: String? = nil) -> Bool {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser

        // Determine base folder
        let baseURL: URL
        if let user = user, hpPrimeCalculatorExists(named: user) {
            baseURL = homeURL
                .appendingPathComponent("Documents/HP Connectivity Kit/Calculators")
                .appendingPathComponent(user)
        } else {
            baseURL = homeURL
                .appendingPathComponent("Documents/HP Prime/Calculators/Prime")
        }
        
        return hpPrgmExists(atPath: baseURL.path, named: name)
    }
    
    static func hpAppDirectoryIsInstalled(named name: String, forUser user: String? = nil) -> Bool {
        let baseURL: URL
        if let user = user, hpPrimeCalculatorExists(named: user) {
            baseURL = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Documents/HP Connectivity Kit/Calculators")
                .appendingPathComponent(user)
        } else {
            baseURL = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Documents/HP Prime/Calculators/Prime")
        }

        let appDirURL = baseURL.appendingPathComponent("\(name).hpappdir")
        return appDirURL.isDirectory
    }
    
    static func prgmExists(atPath path: String, named name: String) -> Bool {
        let programURL = URL(fileURLWithPath: path)
            .appendingPathComponent(name)
            .appendingPathExtension("prgm")
        return FileManager.default.fileExists(atPath: programURL.path)
    }
    
    static func prgmPlusExists(atPath path: String, named name: String) -> Bool {
        let programURL = URL(fileURLWithPath: path)
            .appendingPathComponent(name)
            .appendingPathExtension("prgm+")
        return FileManager.default.fileExists(atPath: programURL.path)
    }
    
    static func hpPrgmExists(atPath path: String, named name: String) -> Bool {
        let programURL = URL(fileURLWithPath: path)
            .appendingPathComponent(name)
            .appendingPathExtension("hpprgm")
        return FileManager.default.fileExists(atPath: programURL.path)
    }

    
    static func hpAppDirIsComplete(atPath path: String, named name: String) -> Bool {
        let appDirURL = URL(fileURLWithPath: path)
            .appendingPathComponent(name)
            .appendingPathExtension("hpappdir")
        
        guard appDirURL.isDirectory else {
            return false
        }
        
        let files: [URL] = [
            appDirURL.appendingPathComponent("icon.png"),
            appDirURL.appendingPathComponent("\(name).hpapp"),
            appDirURL.appendingPathComponent("\(name).hpappprgm")
        ]
        for file in files {
            if !FileManager.default.fileExists(atPath: file.path) {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - HP Prime Application
    enum AppError: Error {
        case invalidAppName
    }
    
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
    
    private static func ensureDirectoryExists(_ url: URL) throws {
        if !url.isDirectory {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
        }
    }
    
    private static func createNoteFileIfMissing(
        to destination: URL,
        named appName: String,
        date seedDate: Date? = nil,
        fileManager: FileManager = .default
    ) throws {
        let fileURL = destination
            .appendingPathComponent(appName)
            .appendingPathExtension("hpappnote")
        
        guard !fileManager.fileExists(atPath: fileURL.path) else { return }

        let data = Data([0x00, 0x00])
        try data.write(to: fileURL, options: .atomic)
        guard let seedDate else { return }
        try setFileDates(at: fileURL, creationDate: seedDate, modificationDate: seedDate)
    }
        
    
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
    
    private static func seedAppDirectory(
        _ appDirectoryURL: URL,
        appName: String,
        baseApplicationURL: URL,
        baseApplicationName: String
    ) throws {

        let seedDate = creationDate()
        
        try copyIfMissing(
            from: baseApplicationURL.appendingPathComponent("\(baseApplicationName).png"),
            to: appDirectoryURL
                .appendingPathComponent("icon.png"),
            date: seedDate
        )

        try copyIfMissing(
            from: baseApplicationURL.appendingPathComponent("\(baseApplicationName).hpapp"),
            to: appDirectoryURL
                .appendingPathComponent(appName)
                .appendingPathExtension("hpapp"),
            date: seedDate
        )
        
        try createNoteFileIfMissing(to: appDirectoryURL, named: appName, date: seedDate)
    }
    
    static func ensureHPAppDirectory(
        at directory: URL,
        named appName: String,
        fromBaseApplicationNamed baseAppName: String = "None"
    ) throws {

        let safeName = try fileSafeName(from: appName)

        let baseApplicationURL = Bundle.main.bundleURL
            .appendingPathComponent(baseApplicationPath)
            .appendingPathComponent(baseAppName)
            .appendingPathExtension("hpappdir")

        let appDirectoryURL = directory
            .appendingPathComponent(safeName)
            .appendingPathExtension("hpappdir")

        try ensureDirectoryExists(appDirectoryURL)

        try seedAppDirectory(
            appDirectoryURL,
            appName: safeName,
            baseApplicationURL: baseApplicationURL,
            baseApplicationName: baseAppName
        )
    }
    
    static func creationDate() -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)! // UTC

        let components = DateComponents(year: 2026, month: 1, day: 1, hour: 0, minute: 0, second: 0)

        guard let date = calendar.date(from: components) else {
            return Date(timeIntervalSince1970: 0)
        }
        return date
    }
    
    static func resetHPAppContents(
        at directory: URL,
        named appName: String,
        fromBaseApplicationNamed baseAppName: String = "None"
    ) throws {

        let safeName = try fileSafeName(from: appName)

        let appDirectoryURL = directory
            .appendingPathComponent(safeName)
            .appendingPathExtension("hpappdir")

        try ensureDirectoryExists(appDirectoryURL)
        
        let iconURL = appDirectoryURL
            .appendingPathComponent("icon")
            .appendingPathExtension("png")
        
        let seedDate = creationDate()
        if let attributes = try? FileManager.default.attributesOfItem(atPath: iconURL.path),
           let modificationDate = attributes[.modificationDate] as? Date,
           modificationDate == seedDate {
            
            try? FileManager.default.removeItem(at: iconURL)
        }


        try? FileManager.default.removeItem(
            at: appDirectoryURL
                .appendingPathComponent(safeName)
                .appendingPathExtension("hpapp")
        )

        try ensureHPAppDirectory(
            at: directory,
            named: appName,
            fromBaseApplicationNamed: baseAppName
        )
    }
    
    static func baseApplicationName(
        at directory: URL,
        named appName: String
    ) -> String {
        let applications: [String] = [
            "Function",
            "Solve",
            "Statistics 1Var",
            "Statistics 2Var",
            "Inference",
            "Parametric",
            "Polar",
            "Sequence",
            "Finance",
            "Linear Solver",
            "Triangle Solver",
            "",
            "",
            "",
            "Data Streamer",
            "Geometry",
            "Spreadsheet",
            "Advanced Graphing",
            "Graph 3D",
            "Explorer",
            "None",
            "Python"
        ]
        
        let fileURL = directory
            .appendingPathComponent("\(appName).hpappdir")
            .appendingPathComponent("\(appName).hpapp")
        do {
            let fileHandle = try FileHandle(forReadingFrom: fileURL)
            if let data = try fileHandle.read(upToCount: 21), !data.isEmpty {
                let name = applications[Int(data[20])]
                return name.isEmpty ? "None" : name
            }
            return "None"
        } catch {
#if Debug
            print("Base application name: None\n")
#endif
            return "None"
        }
    }
    
    // MARK: -
    
    static func archiveHPAppDirectory(in directory: URL, named name: String, to desctinationURL: URL? = nil) -> (out: String?, err: String?, exitCode: Int32)  {
        do {
            try ensureHPAppDirectory(at: directory, named: name)
        } catch {
            return (nil, "Failed to restore missing app files: \(error)", -1)
        }
        
        var destinationPath = "\(name).hpappdir.zip"
        
        if let desctinationURL = desctinationURL {
            try? FileManager.default.removeItem(at: desctinationURL.appendingPathComponent("\(name).hpappdir.zip"))
            destinationPath = desctinationURL.appendingPathComponent("\(name).hpappdir.zip").path
        } else {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent("\(name).hpappdir.zip"))
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
    
    static func loadHPPrgm(at url: URL) -> String? {
        
        if url.pathExtension.lowercased() == "hpprgm" || url.pathExtension.lowercased() == "hpappprgm" {
            let result = ProcessRunner.run(executable: ToolchainPaths.bin.appendingPathComponent("ppl+"), arguments: [url.path, "-o", "/dev/stdout"])
            if let out = result.out, !out.isEmpty {
                return result.out
            }
            return nil
        }
        
        return loadTextFile(at: url)
    }
    
    static func savePrgm(at url: URL, content prgm: String) throws {
        let ext = url.pathExtension.lowercased()
        let encoding: String.Encoding = ext == "prgm" ? .utf16LittleEndian : .utf8
        
        if encoding == .utf8 {
            try prgm.write(to: url, atomically: true, encoding: .utf8)
        } else {
            // UTF-16 LE with BOM
            guard let body = prgm.data(using: .utf16LittleEndian) else {
                throw NSError(domain: "HPFileSaveError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode string as UTF-16LE"])
            }
            var data = Data([0xFF, 0xFE]) // BOM
            data.append(body)
            try data.write(to: url, options: .atomic)
        }
    }
    
    static func installHPPrgm(at programURL: URL, forUser user: String? = nil) throws {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        
        // Determine destination folder
        let destinationURL: URL
        
        if let user = user, hpPrimeCalculatorExists(named: user) {
            destinationURL = homeURL
                .appendingPathComponent("Documents/HP Connectivity Kit/Calculators")
                .appendingPathComponent(user)
                .appendingPathComponent(programURL.lastPathComponent)
        } else {
            destinationURL = homeURL
                .appendingPathComponent("Documents/HP Prime/Calculators/Prime")
                .appendingPathComponent(programURL.lastPathComponent)
        }

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.copyItem(at: programURL, to: destinationURL)
        }
    }
    
    static func preProccess(at sourceURL: URL, to destinationURL: URL, compress: Bool = false) -> (out: String?, err: String?, exitCode: Int32) {
    
        let command = ToolchainPaths.bin.appendingPathComponent("ppl+").path
        
        var arguments: [String] = [sourceURL.path, "-o", destinationURL.path]
        
        if compress {
            arguments.append(contentsOf: ["--compress"])
        }
        
        let include = UserDefaults.standard.object(forKey: "include") as? String ?? "$(SDK)/include"
        if include.isEmpty == false {
            let path = include.replacingOccurrences(of: "$(SDK)", with: ToolchainPaths.developerRoot.appendingPathComponent("usr").path)
            arguments.append(contentsOf: ["-I\(path)"])
        }
        
        let lib = UserDefaults.standard.object(forKey: "lib") as? String ?? "$(SDK)/lib"
        if lib.isEmpty == false {
            let path = lib.replacingOccurrences(of: "$(SDK)", with: ToolchainPaths.developerRoot.appendingPathComponent("usr").path)
            arguments.append(contentsOf: ["-L\(path)"])
        }
        
        /*
         A directory’s modification date changes only when:
            • A file is added
            • A file is removed
            • A file is renamed
         
         ❌ It does NOT change when:
            • A file inside the directory is edited
         */
        try? FileManager.default.removeItem(at: destinationURL)
        
        let commandURL = URL(fileURLWithPath: command)
        let result = ProcessRunner.run(executable: commandURL, arguments: arguments)
        return result
    }
    
    static func installHPAppDirectory(at appURL: URL, forUser user: String? = nil) throws {
        guard appURL.isDirectory else {
            return
        }
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        
        // Determine destination folder
        let destinationURL: URL
        
        if let user = user, hpPrimeCalculatorExists(named: user) {
            destinationURL = homeURL
                .appendingPathComponent("Documents/HP Connectivity Kit/Calculators")
                .appendingPathComponent(user)
                .appendingPathComponent(appURL.lastPathComponent)
        } else {
            destinationURL = homeURL
                .appendingPathComponent("Documents/HP Prime/Calculators/Prime")
                .appendingPathComponent(appURL.lastPathComponent)
        }
        

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.copyItem(at: appURL, to: destinationURL)
        }
    }
    
    static func terminateVirtualCalculator() {
        guard isProcessRunning("HP Prime Virtual Calculator") else {
            return
        }
        killProcess(named: "HP Prime Virtual Calculator")
        
        let platform = UserDefaults.standard.object(forKey: "platform") as? String ?? "macOS"
        
        if platform == "macOS" {
            if let targetBundleIdentifier = getBundleIdentifier(forApp: "HP Prime") {
                terminateApp(withBundleIdentifier: targetBundleIdentifier)
            }
        }
    }
    
    static func launchVirtualCalculator() {
        let platform = UserDefaults.standard.object(forKey: "platform") as? String ?? "macOS"
        if platform == "macOS" {
            if let targetBundleIdentifier = getBundleIdentifier(forApp: "HP Prime") {
                terminateApp(withBundleIdentifier: targetBundleIdentifier)
            }
            
            launchApplication(named: "HP Prime.app")
            return
        }
        
        if isProcessRunning("HP Prime Virtual Calculator") {
            killProcess(named: "HP Prime Virtual Calculator")
        }
        
        launchApplication(
            named: "/Applications/Wine.app/Contents/MacOS/wine",
            arguments: [
                FileManager
                    .default
                    .homeDirectoryForCurrentUser
                    .appendingPathComponent(".wine/drive_c/Program Files/HP/HP Prime Virtual Calculator/HPPrime.exe")
                    .path
            ])
    }
    
    static func launchConnectivityKit() {
        let appName = "HP Connectivity Kit"
        
        let platform = UserDefaults.standard.object(forKey: "platform") as? String ?? "macOS"
        if platform == "macOS" {
            if let targetBundleIdentifier = getBundleIdentifier(forApp: appName) {
                terminateApp(withBundleIdentifier: targetBundleIdentifier)
            }
            
            launchApplication(named: appName + ".app")
            return
        }
        
        if isProcessRunning("HP Connectivity Kit") {
            killProcess(named: "HP Connectivity Kit")
        }
        
        launchApplication(
            named: "/Applications/Wine.app/Contents/MacOS/wine",
            arguments: [
                FileManager
                    .default
                    .homeDirectoryForCurrentUser
                    .appendingPathComponent(".wine/drive_c/Program Files/HP/HP Connectivity Kit/ConnectivityKit.exe")
                    .path
            ])
    }
}
