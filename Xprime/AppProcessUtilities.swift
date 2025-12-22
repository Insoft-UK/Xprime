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

// getBundleIdentifier by Jozef Dekoninck
func getBundleIdentifier(forApp appName: String) -> String? {
    let runningApps = NSWorkspace.shared.runningApplications
    for app in runningApps {
        if app.localizedName == appName {
            return app.bundleIdentifier
        }
    }
    return nil
}

func terminateApp(withBundleIdentifier bundleIdentifier: String) {
    // Code by Jozef Dekoninck
    let runningApps = NSWorkspace.shared.runningApplications
    if let running = runningApps.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
        kill(running.processIdentifier, SIGTERM)
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.5))
    }
}

func isProcessRunning(_ name: String) -> Bool {
    let process = Process()
//    let pipe = Pipe()

    process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    process.arguments = ["-f", name]     // -f = match full command line
//    process.standardOutput = pipe
//    process.standardError = Pipe()
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice

    do {
        try process.run()
    } catch { return false }
    
    process.waitUntilExit()

    return process.terminationStatus == 0
}

func killProcess(named name: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
    process.arguments = ["-f", name]   // -f matches full command line
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice

    do { try process.run() }
    catch { print("Failed to kill: \(error)") }
}

enum AppLaunchError: Error {
    case notFound
    case invalidPath
    case launchFailed(Error)
}

@discardableResult
func launchApp(named name: String,
               arguments: [String] = []) -> Result<Process, AppLaunchError> {

    
    var resolvedPath: String?

    // If "name" ends with .app, treat it as a bundle.
    if name.hasSuffix(".app") {
        let appURL = URL(fileURLWithPath: "/Applications/" + name)

        if FileManager.default.fileExists(atPath: appURL.path) {
            resolvedPath = appURL.appendingPathComponent("Contents/MacOS/" + name)
                .deletingPathExtension()
                .path
        }
    }

    // Otherwise treat as executable path
    if resolvedPath == nil, FileManager.default.fileExists(atPath: name) {
        resolvedPath = name
    }

    guard let path = resolvedPath else {
        return .failure(.notFound)
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: path)
    process.arguments = arguments
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice

    do {
        try process.run()
        return .success(process)
    } catch {
        return .failure(.launchFailed(error))
    }
}
