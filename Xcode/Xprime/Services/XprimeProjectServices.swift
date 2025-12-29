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

fileprivate struct Project: Codable {
    let compression: Bool
    let include: String
    let lib: String
    let calculator: String
    let bin: String
    let archiveProjectAppOnly: Bool
}

enum XprimeProjectServices {
    static private func loadJSONString(_ url: URL) -> String? {
        do {
            let jsonString = try String(contentsOf: url, encoding: .utf8)
            return jsonString
        } catch {
            return nil
        }
    }
    
    static func load(at directoryURL: URL, named name: String) {
        var project: Project?
        let projectURL = directoryURL.appendingPathComponent(name + ".xprimeproj")
        
        if let jsonString = loadJSONString(projectURL),
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
    }

    
    static func save(to dirURL: URL, named name: String) {
        let projectURL = dirURL.appendingPathComponent(name + ".xprimeproj")
        let project = Project(
            compression: UserDefaults.standard.object(forKey: "compression") as? Bool ?? false,
            include: UserDefaults.standard.object(forKey: "include") as? String ?? "$(SDK)/include",
            lib: UserDefaults.standard.object(forKey: "lib") as? String ?? "$(SDK)/lib",
            calculator: UserDefaults.standard.object(forKey: "calculator") as? String ?? "Prime",
            bin: "", // Reserved!
            archiveProjectAppOnly: UserDefaults.standard.object(forKey: "archiveProjectAppOnly") as? Bool ?? true
        )
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            let data = try encoder.encode(project)
            if let jsonString = String(data: data, encoding: .utf8) {
                try jsonString.write(to: projectURL, atomically: true, encoding: .utf8)
            } else {
                // Fallback: write raw data if string conversion fails
                try data.write(to: projectURL)
            }
        } catch {
            // Silently ignore errors to mirror load(at:) behavior; consider logging in the future
        }
    }
}
