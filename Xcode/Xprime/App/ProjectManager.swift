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

protocol ProjectManagerDelegate: AnyObject {
    // Called when a document is successfully saved
    func projectManagerDidSave(_ manager: ProjectManager)
    
    // Called when saving fails
    func projectManager(_ manager: ProjectManager, didFailWith error: Error)
    
    // Called when a project is successfully opened
    func projectManagerDidOpen(_ manager: ProjectManager)
    
    // Optional: called when opening fails
    func projectManager(_ manager: ProjectManager, didFailToOpen error: Error)
}

fileprivate struct Project: Codable {
    let compression: Bool
    let include: String
    let lib: String
    let calculator: String
    let bin: String
    let archiveProjectAppOnly: Bool
}

final class ProjectManager {
    weak var delegate: ProjectManagerDelegate?
    
    private var documentManager: DocumentManager
    private(set) var projectDirectoryURL: URL?
    
    var projectName: String? {
        guard let url = projectDirectoryURL else {
            return "Untitled"
        }
        return xprimeProjectName(in: url)
    }
    
    var isProjectAnApplication: Bool {
        guard let projectDirectoryURL, let name = projectName else {
            return false
        }
        return projectDirectoryURL
            .appendingPathComponent(name)
            .appendingPathExtension("hpappdir")
            .isDirectory
    }
    
    var baseApplicationName: String {
        guard let projectDirectoryURL else {
            return "None"
        }
        return HPServices.hpPrimeBaseApplicationName(for: projectDirectoryURL.lastPathComponent, in: projectDirectoryURL)
    }
    
    init(documentManager: DocumentManager) {
        self.documentManager = documentManager
    }
    
    func openLastOrUntitled() {
        guard let path = UserDefaults.standard.string(forKey: "lastOpenedProjectPath"),
           FileManager.default.fileExists(atPath: path) else {
            return
        }
        
        openProject(at: URL(fileURLWithPath: path))
    }
    
    private func xprimeProjectName(in directory: URL) -> String? {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            
            for fileURL in contents {
                if fileURL.pathExtension.lowercased() == "xprimeproj" {
                    return fileURL.deletingPathExtension().lastPathComponent
                }
            }
        } catch {
            print("Error reading directory: \(error)")
        }
        
        return nil
    }
    
    func openProject(at url: URL) {
        var project: Project!
        
        if let jsonString = loadJSONString(url),
           let jsonData = jsonString.data(using: .utf8) {
            do {
                project = try JSONDecoder().decode(Project.self, from: jsonData)
            } catch {
                // Project is invalid/outdated
                defaultProjectSettings()
                project = .init(
                    compression: false,
                    include: "$(SDK)/include",
                    lib: "$(SDK)/lib",
                    calculator: "Prime",
                    bin: "$(SDK)/bin",
                    archiveProjectAppOnly: true
                )
            }
        } else {
            delegate?.projectManager(self, didFailToOpen: NSError(domain: "XcodeProjectManager", code: 0, userInfo: nil))
            return
        }
        
        UserDefaults.standard.set(project.compression, forKey: "compression")
        UserDefaults.standard.set(project.include, forKey: "include")
        UserDefaults.standard.set(project.lib, forKey: "lib")
        UserDefaults.standard.set(project.calculator, forKey: "calculator")
        UserDefaults.standard.set(project.bin, forKey: "bin")
        UserDefaults.standard.set(project.archiveProjectAppOnly, forKey: "archiveProjectAppOnly")
        
        projectDirectoryURL = url.deletingLastPathComponent()
        UserDefaults.standard.set(url.path, forKey: "lastOpenedProjectPath")
        delegate?.projectManagerDidOpen(self)
    }
    
    func openProject(in url: URL) {
        guard let projectName = self.xprimeProjectName(in: url) else {
            delegate?.projectManager(self, didFailToOpen: NSError(domain: "XcodeProjectManager", code: 0, userInfo: nil))
            return
        }
        openProject(at: url.appendingPathComponent("\(projectName).xprimeproj"))
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
    func saveProjectAs(at url: URL) -> Bool {
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
                try jsonString.write(to: url, atomically: true, encoding: .utf8)
            } else {
                // Fallback: write raw data if string conversion fails
                try data.write(to: url)
            }
            documentManager.outputTextView.appendTextAndScroll("✅ Successful in saving project \"\(url.deletingPathExtension().lastPathComponent)\"\n")
            UserDefaults.standard.set(url.path, forKey: "lastOpenedProjectPath")
            delegate?.projectManagerDidSave(self)
            return true
        } catch {
            documentManager.outputTextView.appendTextAndScroll("❌ Unsuccessful in saving project \"\(url.deletingPathExtension().lastPathComponent)\"\n")
            delegate?.projectManager(self, didFailWith: error)
            return false
        }
    }
    
//    @discardableResult
//    func saveProject() -> Bool {
//        guard let projectDirectoryURL else { return false }
//        guard let projectName else { return false }
//        
//        let projectFileURL = projectDirectoryURL
//            .appendingPathComponent("\(projectName).xprimeproj")
//        
//        return saveProjectAs(at: projectFileURL)
//    }
    
    @discardableResult
    func createNewProject(named name: String, in directoryURL: URL) -> Bool {
        do {
            try FileManager.default.createDirectory(
                at: directoryURL
                    .appendingPathComponent(name),
                withIntermediateDirectories: false
            )
            FileManager.default.changeCurrentDirectoryPath(directoryURL.path)
            
            if let url = Bundle.main.url(forResource: "info", withExtension: "note") {
                try FileManager.default.copyItem(
                    at: url,
                    to: directoryURL.appendingPathComponent("\(name)/info.note")
                )
            }

            if let url = Bundle.main.url(forResource: "main", withExtension: "prgm+") {
                try FileManager.default.copyItem(
                    at: url,
                    to: directoryURL.appendingPathComponent("\(name)/main.prgm+")
                )
            }
            
            defaultProjectSettings()
            documentManager.outputTextView.appendTextAndScroll("⚠️ Default project settings applied\n")
            saveProjectAs(at: directoryURL.appendingPathComponent("\(name)/\(name).xprimeproj"))
            
            projectDirectoryURL = directoryURL.appendingPathComponent(name)
            documentManager.openDocument(at: directoryURL.appendingPathComponent("\(name)/main.prgm+"))
        } catch {
            documentManager.outputTextView.appendTextAndScroll("❌ New Project Failed:-\n\(error).\n")
            return false
        }
        return false
    }
    
    private func defaultProjectSettings() {
        UserDefaults.standard.set(false, forKey: "compression")
        UserDefaults.standard.set("$(SDK)/include", forKey: "include")
        UserDefaults.standard.set("$(SDK)/lib", forKey: "lib")
        UserDefaults.standard.set("Prime", forKey: "calculator")
        UserDefaults.standard.set("$(SDK)/bin", forKey: "bin")
        UserDefaults.standard.set(true, forKey: "archiveProjectAppOnly")
    }
}
