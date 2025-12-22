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



//        guard let enumerator = FileManager.default.enumerator(atPath: parentURL.path) else { return }
//        for case let fileURL as URL in enumerator where fileURL.pathExtension == "hpprgm" {
//            let fileName = fileURL.deletingPathExtension().lastPathComponent
//            if fileName == name {
//                continue
//            }
//
//        }

enum HP {
    static let sdkURL = URL(fileURLWithPath: Bundle.main.bundleURL.path).appendingPathComponent("Contents/Resources/Developer/usr")

    static var isVirtualCalculatorInstalled: Bool {
        if AppSettings.HPPrime == "macOS" {
            return FileManager.default.fileExists(atPath: "/Applications/HP Prime.app/Contents/MacOS/HP Prime")
        }
        
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        return FileManager.default.fileExists(atPath: homeDirectory.appendingPathComponent(".wine/drive_c/Program Files/HP/HP Prime Virtual Calculator/HPPrime.exe").path)
    }
    
    static var isConnectivityKitInstalled: Bool {
        if AppSettings.HPPrime == "macOS" {
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
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        
        let directoryURL: URL
        let user = AppSettings.calculatorName
        
        if hpPrimeCalculatorExists(named: user) {
            if HP.isConnectivityKitInstalled == false {
                return nil
            }
            directoryURL = homeURL
                .appendingPathComponent("Documents/HP Connectivity Kit/Calculators")
                .appendingPathComponent(user)
        } else {
            if HP.isVirtualCalculatorInstalled == false {
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
    
    static func restoreMissingAppFiles(at parentURL: URL, named name: String) throws {
        if hpAppDirIsComplete(atPath: parentURL.path, named: name) {
            return
        }
        
        let templateDirURL = Bundle.main.bundleURL
            .appendingPathComponent(applicationTemplateBasePath)
        
        let hpAppDirURL = parentURL.appendingPathComponent("\(name).hpappdir")
        
        if hpAppDirURL.isDirectory == false {
            try FileManager.default.createDirectory(
                at: hpAppDirURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        if !FileManager.default.fileExists(atPath: hpAppDirURL
            .appendingPathComponent("icon.png")
            .path
        )
        {
            if FileManager.default.fileExists(atPath: parentURL.appendingPathComponent("icon.png").path) == true {
                try FileManager.default.copyItem(
                    at: templateDirURL
                        .appendingPathComponent("icon.png"),
                    to: hpAppDirURL
                        .appendingPathComponent("icon.png")
                )
            } else {
                try FileManager.default.copyItem(
                    at: templateDirURL
                        .appendingPathComponent("icon.png"),
                    to: hpAppDirURL
                        .appendingPathComponent("icon.png")
                )
            }
        }
        
        if !FileManager.default.fileExists(atPath: hpAppDirURL
            .appendingPathComponent(name)
            .appendingPathExtension("hpapp")
            .path
        )
        {
            try FileManager.default.copyItem(
                at: templateDirURL
                    .appendingPathComponent("template.hpapp"),
                to: hpAppDirURL
                    .appendingPathComponent(name)
                    .appendingPathExtension("hpapp")
            )
        }
    }
    
    static func archiveHPAppDirectory(at url: URL, named name: String, to desctinationURL: URL? = nil) -> (out: String?, err: String?)  {
        do {
            try restoreMissingAppFiles(at: url, named: name)
        } catch {
            return (nil, "Failed to restore missing app files: \(error)")
        }
        
        var destinationPath = "\(name).hpappdir.zip"
        
        if let desctinationURL = desctinationURL {
            try? FileManager.default.removeItem(at: desctinationURL.appendingPathComponent("\(name).hpappdir.zip"))
            destinationPath = desctinationURL.appendingPathComponent("\(name).hpappdir.zip").path
        } else {
            try? FileManager.default.removeItem(at: url.appendingPathComponent("\(name).hpappdir.zip"))
        }
        
        return CommandLineTool.execute(
            "/usr/bin/zip",
            arguments: [
                "-r",
                destinationPath,
                "\(name).hpappdir",
                "-x", "*.DS_Store"
            ],
            currentDirectory: url
        )
    }
    
    static func loadHPPrgm(at url: URL) -> String? {
        
        if url.pathExtension.lowercased() == "hpprgm" || url.pathExtension.lowercased() == "hpappprgm" {
            let commandURL = HP.sdkURL
                .appendingPathComponent("bin")
                .appendingPathComponent("ppl+")
            
            let result = CommandLineTool.execute(commandURL.path, arguments: [url.path, "-o", "/dev/stdout"])
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
    
    static func preProccess(at sourceURL: URL, to destinationURL: URL, compress: Bool = false) -> (out: String?, err: String?) {
    
        let command = HP.sdkURL
            .appendingPathComponent("bin")
            .appendingPathComponent("ppl+")
            .path
        
        var arguments: [String] = [sourceURL.path, "-o", destinationURL.path]
        
        if compress {
            arguments.append(contentsOf: ["--compress"])
        }
        
        if AppSettings.headerSearchPath.isEmpty == false {
            let path = AppSettings.headerSearchPath.replacingOccurrences(of: "$(SDK)", with: HP.sdkURL.path)
            arguments.append(contentsOf: ["-I\(path)"])
        }
        
        if AppSettings.librarySearchPath.isEmpty == false {
            let path = AppSettings.librarySearchPath.replacingOccurrences(of: "$(SDK)", with: HP.sdkURL.path)
            arguments.append(contentsOf: ["-L\(path)"])
        }
        
        let result = CommandLineTool.execute(command, arguments: arguments)
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
    
    static func launchVirtualCalculator() {
        let appName = "HP Prime"
        
        if AppSettings.HPPrime == "macOS" {
            if let targetBundleIdentifier = getBundleIdentifier(forApp: appName) {
                terminateApp(withBundleIdentifier: targetBundleIdentifier)
            }
            
            launchApplication(named: appName + ".app")
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
        
        if AppSettings.HPPrime == "macOS" {
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
