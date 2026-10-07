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

/*
 * private → use when only the declaring scope needs it
 * fileprivate → use when multiple declarations in the same file need it
 * internal (default) → accessible throughout the module
 * public → accessible to clients of the module
 */

func isApplicationInstalled(withBundleIdentifier bundleIdentifier: String) -> Bool {
    NSWorkspace.shared.urlForApplication(
        withBundleIdentifier: bundleIdentifier
    ) != nil
}

func isApplicationRunning(withBundleIdentifier bundleIdentifier: String) -> Bool {
    NSWorkspace.shared.runningApplications.contains {
        $0.bundleIdentifier == bundleIdentifier
    }
}

func runApplication(withBundleIdentifier bundleIdentifier: String) {
    guard let url = NSWorkspace.shared.urlForApplication(
        withBundleIdentifier: bundleIdentifier
    ) else {
        return
    }

    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = true

    NSWorkspace.shared.openApplication(
        at: url,
        configuration: configuration
    ) { application, error in
        if let error {
            print("Failed to launch application: \(error)")
        }
    }
}

func terminateApp(
    withBundleIdentifier bundleIdentifier: String,
    completion: (() -> Void)? = nil
) {
    guard let application = NSWorkspace.shared.runningApplications.first(
        where: { $0.bundleIdentifier == bundleIdentifier }
    ) else {
        completion?()
        return
    }

    application.terminate()

    waitForApplicationToTerminate(
        withBundleIdentifier: bundleIdentifier,
        completion: completion
    )
}

private func waitForApplicationToTerminate(
    withBundleIdentifier bundleIdentifier: String,
    completion: (() -> Void)?
) {
    if !isApplicationRunning(withBundleIdentifier: bundleIdentifier) {
        completion?()
        return
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        waitForApplicationToTerminate(
            withBundleIdentifier: bundleIdentifier,
            completion: completion
        )
    }
}

func restartApplication(withBundleIdentifier bundleIdentifier: String) {
    terminateApp(withBundleIdentifier: bundleIdentifier) {
        runApplication(withBundleIdentifier: bundleIdentifier)
    }
}

func isProcessRunning(_ name: String) -> Bool {
    let process = Process()

    process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    process.arguments = ["-f", name]     // -f = match full command line
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

func registerInstallation() {

    print("registerInstallation: START")

    let uuid = XprimeUserID.get()
    print("registerInstallation: UUID =", uuid)

    var components = URLComponents(
        string: "http://api.insoft.uk/"
    )!
    
    
    components.queryItems = [
        URLQueryItem(name: "method", value: "installation"),
        URLQueryItem(name: "uuid", value: uuid),
        URLQueryItem(
            name: "bundle_id",
            value: Bundle.main.bundleIdentifier ?? ""
        ),
        URLQueryItem(
            name: "app_version",
            value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        ),
        URLQueryItem(
            name: "build",
            value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        ),
        URLQueryItem(
            name: "macos_version",
            value: ProcessInfo.processInfo.operatingSystemVersionString
        )
    ]

    guard let url = components.url else {
        print("registerInstallation: INVALID URL")
        return
    }

    print("registerInstallation: URL =", url.absoluteString)
    print("registerInstallation: starting request")

    URLSession.shared.dataTask(with: url) { data, response, error in

        print("registerInstallation: RESPONSE")

        if let error {
            print("API error:", error)
            return
        }

        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP status:", httpResponse.statusCode)
        }

        guard let data else {
            print("No data returned")
            return
        }

        print(String(data: data, encoding: .utf8) ?? "")
        
    }.resume()

    print("registerInstallation: REQUEST STARTED")
}
