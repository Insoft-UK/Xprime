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
    static var binURL: URL {
        let url = URL(fileURLWithPath: "/Applications/HP/PrimeSDK/bin")
        if url.isDirectory == false || AppSettings.usePrimeSDK == false {
            return URL(fileURLWithPath: Bundle.main.bundleURL.path)
                .appendingPathComponent("Contents/Developer/usr/bin")
        }
        return url
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
    
    static func `ppl+`(i infile: URL, o outfile: URL? = nil) -> (out: String?, err: String?) {
        
        let process = Process()
        process.executableURL = URL(filePath: binURL.path)
            .appendingPathComponent("ppl+")
        
        process.arguments = [infile.path]
        
        if AppSettings.librarySearchPath.isEmpty == false {
            process.arguments?.append("-L\(AppSettings.librarySearchPath)")
        }
        
        if AppSettings.headerSearchPath.isEmpty == false {
            process.arguments?.append("-I\(AppSettings.headerSearchPath)")
        }
        
        if let outfile = outfile {
            process.arguments?.append("-o")
            process.arguments?.append(outfile.path)
        }
        
        if AppSettings.compressHPPRGM == true {
            process.arguments?.append("-c")
        }
        
        return run(process)
    }
}

