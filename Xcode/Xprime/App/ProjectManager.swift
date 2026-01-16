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

// MARK: ✅ Done

import Cocoa

fileprivate struct Project: Codable {
    let compression: Bool
    let include: String
    let lib: String
    let calculator: String
    let bin: String
    let archiveProjectAppOnly: Bool
}

final class ProjectManager {
    
    private var documentManager: DocumentManager
    private(set) var currentDirectoryURL: URL?
    
    var projectName: String {
        guard let currentDirectoryURL else {
            return "Untitled"
        }
        return currentDirectoryURL
            .lastPathComponent
    }
    
    var baseApplicationName: String {
        guard let currentDirectoryURL else {
            return "None"
        }
        return HPServices.hpPrimeBaseApplicationName(for: currentDirectoryURL.lastPathComponent, in: currentDirectoryURL)
    }
    
    init(documentManager: DocumentManager) {
        self.documentManager = documentManager
    }
    
    func openProject() {
        guard let url = documentManager.currentDocumentURL else {
            return
        }
        
        let name = url
            .deletingLastPathComponent()
            .lastPathComponent
        
        let projectFileURL = url
            .deletingLastPathComponent()
            .appendingPathComponent("\(name).xprimeproj")
        
        
        
        var project: Project?
        
        if let jsonString = loadJSONString(projectFileURL),
           let jsonData = jsonString.data(using: .utf8) {
            project = try? JSONDecoder().decode(Project.self, from: jsonData)
        }
        
        guard let project = project else {
            return
        }
        
        UserDefaults.standard.set(project.compression, forKey: "compression")
        UserDefaults.standard.set(project.include, forKey: "include")
        UserDefaults.standard.set(project.lib, forKey: "lib")
        UserDefaults.standard.set(project.calculator, forKey: "calculator")
        UserDefaults.standard.set(project.bin, forKey: "bin")
        UserDefaults.standard.set(project.archiveProjectAppOnly, forKey: "archiveProjectAppOnly")
    
        currentDirectoryURL = url
            .deletingLastPathComponent()
    }
    
    
    private func loadJSONString(_ url: URL) -> String? {
        do {
            let jsonString = try String(contentsOf: url, encoding: .utf8)
            return jsonString
        } catch {
#if Debug
        print("Loading JSON from \(url) failed:", error)
#endif
            return nil
        }
    }
    
    @discardableResult
    func saveProject() -> Bool {
        guard let url = documentManager.currentDocumentURL else { return false }
        let name = url
            .deletingLastPathComponent()
            .lastPathComponent
        
        let projectFileURL = url
            .deletingLastPathComponent()
            .appendingPathComponent("\(name).xprimeproj")
        
        let project = Project(
            compression: UserDefaults.standard.object(forKey: "compression") as? Bool ?? false,
            include: UserDefaults.standard.object(forKey: "include") as? String ?? "$(SDK)/include",
            lib: UserDefaults.standard.object(forKey: "lib") as? String ?? "$(SDK)/lib",
            calculator: UserDefaults.standard.object(forKey: "calculator") as? String ?? "Prime",
            bin: UserDefaults.standard.object(forKey: "bin") as? String ?? "$(SDK)/bin",
            archiveProjectAppOnly: UserDefaults.standard.object(forKey: "archiveProjectAppOnly") as? Bool ?? true,
        )
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            let data = try encoder.encode(project)
            if let jsonString = String(data: data, encoding: .utf8) {
                try jsonString.write(to: projectFileURL, atomically: true, encoding: .utf8)
            } else {
                // Fallback: write raw data if string conversion fails
                try data.write(to: projectFileURL)
            }
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    func createProject(named name: String, at directoryURL: URL) -> Bool {
        do {
            try FileManager.default.createDirectory(
                at: directoryURL
                    .appendingPathComponent(name),
                withIntermediateDirectories: false
            )

            if let url = Bundle.main.url(forResource: "Untitled", withExtension: "prgm+") {
                try FileManager.default.copyItem(
                    at: url,
                    to: directoryURL.appendingPathComponent("\(name)/\(name).prgm+")
                )
                documentManager.openDocument(url: directoryURL.appendingPathComponent("\(name)/\(name).prgm+"))
                defaultSettings()
                saveProject()
                currentDirectoryURL = directoryURL
            }
        } catch {
            return false
        }
        return false
    }
    
    private func defaultSettings() {
        UserDefaults.standard.set(false, forKey: "compression")
        UserDefaults.standard.set("$(SDK)/include", forKey: "include")
        UserDefaults.standard.set("$(SDK)/lib", forKey: "lib")
        UserDefaults.standard.set("Prime", forKey: "calculator")
        UserDefaults.standard.set("$(SDK)/bin", forKey: "bin")
        UserDefaults.standard.set(true, forKey: "archiveProjectAppOnly")
    }
}
