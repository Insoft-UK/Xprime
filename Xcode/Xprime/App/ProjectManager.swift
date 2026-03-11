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
    
    // Called when fails
    func projectManager(_ manager: ProjectManager, didFailWith error: Error)
    
    // Called when a project is successfully opened
    func projectManagerDidOpen(_ manager: ProjectManager)
    
    // Optional: called when opening fails
    func projectManager(_ manager: ProjectManager, didFailToOpen error: Error)
    
    // Called when a project is successfully closed
    func projectManagerDidClose(_ manager: ProjectManager)
    
}

fileprivate struct Project: Codable {
    let compression: Bool
    let include: String
    let lib: String
    let calculator: String
    let bin: String
    let archiveProjectAppOnly: Bool
    let plainFallbackText: Bool
}

final class ProjectManager {
    weak var delegate: ProjectManagerDelegate?
    
    private(set) var projectDirectoryURL: URL? = nil
  
    var isProjectOpen: Bool {
        return projectDirectoryURL != nil
    }
    
    var projectName: String? {
        guard let url = projectDirectoryURL else {
            return nil
        }
        return ProjectManager.projectName(in: url)
    }
    
    var isProjectApplication: Bool {
        guard let projectDirectoryURL, let name = ProjectManager.projectName(in: projectDirectoryURL) else {
            return false
        }
        return projectDirectoryURL
            .appendingPathComponent(name)
            .appendingPathExtension("hpappdir")
            .isDirectory
    }
    
    var projectIcon: NSImage? {
        guard isProjectApplication, let projectDirectoryURL, let projectName = self.projectName else {
            return NSImage(named: "Icon")?.copy() as? NSImage
        }
        
        let url = projectDirectoryURL
            .appendingPathComponent(projectName)
            .appendingPathExtension("hpappdir")
            .appendingPathComponent("icon.png")
        
        return NSImage(contentsOfFile: url.path)?.copy() as? NSImage
    }
    
    var baseApplicationName: String {
        guard let projectDirectoryURL, let projectName = ProjectManager.projectName(in: projectDirectoryURL) else {
            return "None"
        }
   
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
        
        let url = projectDirectoryURL
            .appendingPathComponent("\(projectName).hpappdir")
            .appendingPathComponent("\(projectName).hpapp")
        do {
            let fileHandle = try FileHandle(forReadingFrom: url)
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
    
    // MARK: - Public API
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
                    compression: ProjectSettings.shared.compression,
                    include: ProjectSettings.shared.include,
                    lib: ProjectSettings.shared.lib,
                    calculator: ProjectSettings.shared.calculator,
                    bin: ProjectSettings.shared.bin,
                    archiveProjectAppOnly: ProjectSettings.shared.archiveProjectAppOnly,
                    plainFallbackText: ProjectSettings.shared.plainFallbackText
                )
            }
        } else {
            projectDirectoryURL = nil
            delegate?.projectManager(self, didFailToOpen: NSError(domain: "XcodeProjectManager", code: 0, userInfo: nil))
            return
        }
        
        ProjectSettings.shared.compression = project.compression
        ProjectSettings.shared.include = project.include
        ProjectSettings.shared.lib = project.lib
        ProjectSettings.shared.calculator = project.calculator
        ProjectSettings.shared.bin = project.bin
        ProjectSettings.shared.archiveProjectAppOnly = project.archiveProjectAppOnly
        ProjectSettings.shared.plainFallbackText = project.plainFallbackText
        
        projectDirectoryURL = url.deletingLastPathComponent()
        UserDefaults.standard.set(url.path, forKey: "lastOpenedProjectPath")
        delegate?.projectManagerDidOpen(self)
    }
    
    func openProject(in url: URL) {
        guard let projectName = ProjectManager.projectName(in: url) else {
            projectDirectoryURL = nil
            delegate?.projectManager(self, didFailToOpen: NSError(domain: "XcodeProjectManager", code: 0, userInfo: nil))
            return
        }
        openProject(at: url.appendingPathComponent("\(projectName).xprimeproj"))
    }
    
    func closeProject() {
        guard let projectDirectoryURL, let url = ProjectManager.projectURL(in: projectDirectoryURL) else {
            return
        }
        
        saveProjectAs(at: url)
        self.projectDirectoryURL = nil
        
        UserDefaults.standard.set("", forKey: "lastOpenedProjectPath")
        FileManager
            .default
            .changeCurrentDirectoryPath(Settings.shared.location)
        
        delegate?.projectManagerDidClose(self)
    }
    
    @discardableResult
    func saveProjectAs(at url: URL) -> Bool {
        let project = Project(
            compression: ProjectSettings.shared.compression,
            include: ProjectSettings.shared.include,
            lib: ProjectSettings.shared.lib,
            calculator: ProjectSettings.shared.calculator,
            bin: ProjectSettings.shared.bin,
            archiveProjectAppOnly: ProjectSettings.shared.archiveProjectAppOnly,
            plainFallbackText: ProjectSettings.shared.plainFallbackText
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
            UserDefaults.standard.set(url.path, forKey: "lastOpenedProjectPath")
            delegate?.projectManagerDidSave(self)
            return true
        } catch {
            delegate?.projectManager(self, didFailWith: error)
            return false
        }
    }
    
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
            saveProjectAs(at: directoryURL.appendingPathComponent("\(name)/\(name).xprimeproj"))
            projectDirectoryURL = directoryURL.appendingPathComponent(name)
        } catch {
            delegate?.projectManager(self, didFailWith: "Failed to create new project." as! Error)
            return false
        }
        return false
    }
    
    // MARK: - Type Methods
    class func projectURL(in directory: URL) -> URL? {
        guard let projectName = ProjectManager.projectName(in: directory) else {
            return nil as URL?
        }
        
        return directory
            .appendingPathComponent(projectName)
            .appendingPathExtension("xprimeproj")
    }
    
    class func projectName(in directory: URL) -> String? {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
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
    
    // MARK: - Private Instance Helpers
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
    
    private func defaultProjectSettings() {
        ProjectSettings.shared.compression = false
        ProjectSettings.shared.include = "$(SDKROOT)/include"
        ProjectSettings.shared.lib = "$(SDKROOT)/lib"
        ProjectSettings.shared.calculator = "Prime"
        ProjectSettings.shared.bin = "/usr/local/bin"
        ProjectSettings.shared.archiveProjectAppOnly = true
        ProjectSettings.shared.plainFallbackText = true
    }
}
