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

import Foundation
import AppKit

struct AppSettings {
    
    private static let defaults = UserDefaults.standard
    private static let bundleURL = Bundle.main.bundleURL
    
    private enum Key: String {
        case librarySearchPath
        case headerSearchPath
        case selectedTheme
        case selectedGrammar
        case HPPrime
        case compressHPPRGM
        case calculatorName
        case usePrimeSDK
    }
    
    static var usePrimeSDK: Bool {
        get { defaults.object(forKey: Key.usePrimeSDK.rawValue) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.usePrimeSDK.rawValue) }
    }
    
    static var compressHPPRGM: Bool {
        get { defaults.object(forKey: Key.compressHPPRGM.rawValue) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.compressHPPRGM.rawValue) }
    }

    static var librarySearchPath: String {
        get { defaults.object(forKey: Key.librarySearchPath.rawValue) as? String ?? "$(SDK)/lib" }
        set { defaults.set(newValue, forKey: Key.librarySearchPath.rawValue) }
    }
    
    static var headerSearchPath: String {
        get { defaults.object(forKey: Key.headerSearchPath.rawValue) as? String ?? "$(SDK)/include" }
        set { defaults.set(newValue, forKey: Key.headerSearchPath.rawValue) }
    }
    
    static var selectedTheme: String {
        get { defaults.object(forKey: Key.selectedTheme.rawValue) as? String ?? "Default (Dark)" }
        set { defaults.set(newValue, forKey: Key.selectedTheme.rawValue) }
    }
    
    static var selectedGrammar: String {
        get { defaults.object(forKey: Key.selectedGrammar.rawValue) as? String ?? "Language" }
        set { defaults.set(newValue, forKey: Key.selectedGrammar.rawValue) }
    }
    
    static var HPPrime: String {
        get { defaults.object(forKey: Key.HPPrime.rawValue) as? String ?? "macOS" }
        set { defaults.set(newValue, forKey: Key.HPPrime.rawValue) }
    }
    
    static var calculatorName: String {
        get { defaults.object(forKey: Key.calculatorName.rawValue) as? String ?? "Prime" }
        set { defaults.set(newValue, forKey: Key.calculatorName.rawValue) }
    }
    
    
}

