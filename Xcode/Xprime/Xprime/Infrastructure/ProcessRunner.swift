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

/*
 2026-10-08
 
 What changed
 Before: The child process could fill a pipe and become blocked while XPrime waited for it to exit.
 After: Both output streams are drained concurrently, so the child can continue running.
 Also: A DispatchGroup ensures both streams have finished reading before the method returns.
 */

import Cocoa

enum ProcessRunner {
    @discardableResult
    static func run(
        executable: URL,
        arguments: [String] = [],
        currentDirectory: URL? = nil
    ) -> (out: String?, err: String?, exitCode: Int32) {

        let task = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()

        task.executableURL = executable
        task.arguments = arguments
        task.standardOutput = outPipe
        task.standardError = errPipe

        if let currentDirectory {
            task.currentDirectoryURL = currentDirectory
        }

        do {
            try task.run()
        } catch {
            return (nil, error.localizedDescription, -1)
        }

        let group = DispatchGroup()
        let lock = NSLock()

        var outData = Data()
        var errData = Data()

        group.enter()
        DispatchQueue.global(qos: .utility).async {
            let data = outPipe.fileHandleForReading.readDataToEndOfFile()

            lock.lock()
            outData = data
            lock.unlock()

            group.leave()
        }

        group.enter()
        DispatchQueue.global(qos: .utility).async {
            let data = errPipe.fileHandleForReading.readDataToEndOfFile()

            lock.lock()
            errData = data
            lock.unlock()

            group.leave()
        }

        task.waitUntilExit()
        group.wait()

        let out = outData.isEmpty
            ? nil
            : String(data: outData, encoding: .utf8)

        let err = errData.isEmpty
            ? nil
            : String(data: errData, encoding: .utf8)

        return (out, err, task.terminationStatus)
    }
}
