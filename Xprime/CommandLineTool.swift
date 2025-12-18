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

fileprivate func run(_ task: Process) -> (out: String?, err: String?) {
    let outPipe = Pipe()
    let errPipe = Pipe()
    
    task.standardOutput = outPipe
    task.standardError = errPipe
    
    do {
        try task.run()
    } catch {
        return (nil, "Failed to run task: \(error.localizedDescription)")
    }
    
    task.waitUntilExit()
    
    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
    
    let outStr = outData.isEmpty ? nil : String(data: outData, encoding: .utf8)
    let errStr = errData.isEmpty ? nil : String(data: errData, encoding: .utf8)
    
    return (outStr, errStr)
}

enum CommandLineTool {
    static private var binURL: URL {
        return URL(fileURLWithPath: Bundle.main.bundleURL.path).appendingPathComponent("Contents/Resources/Developer/usr/bin")
    }
    
    static private var includeURL: URL {
        guard AppSettings.headerSearchPath == "~" else {
            return URL(fileURLWithPath: AppSettings.headerSearchPath)
        }
        return URL(fileURLWithPath: Bundle.main.bundleURL.path).appendingPathComponent("Contents/Resources/Developer/usr/include")
    }
    
    static private var libURL: URL {
        guard AppSettings.headerSearchPath == "~" else {
            return URL(fileURLWithPath: AppSettings.headerSearchPath)
        }
        return URL(fileURLWithPath: Bundle.main.bundleURL.path).appendingPathComponent("Contents/Resources/Developer/usr/lib")
    }
    
    static func execute(_ command: String, arguments: [String], currentDirectory: URL? = nil) -> (out: String?, err: String?) {
        let task = Process()
    
        task.executableURL = URL(fileURLWithPath: command)
        task.arguments = arguments
        if let url = currentDirectory {
            task.currentDirectoryURL = url
        }
        
        return run(task)
    }
}

