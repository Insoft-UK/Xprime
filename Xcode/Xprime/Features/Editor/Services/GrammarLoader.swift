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

final class GrammarLoader {

    static let shared = GrammarLoader()
    private init() {}
    
    func isGrammarLoaded(named name: String) -> Bool {
        return name == UserDefaults.standard.string(forKey: "preferredGrammar")
    }

    func loadGrammar(named name: String) -> Grammar? {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: "xpgrammar",
            subdirectory: "Grammars"
        ) else {
            return nil
        }

        guard let json = try? String(contentsOf: url, encoding: .utf8),
              let data = json.data(using: .utf8)
        else {
            return nil
        }

        UserDefaults.standard.set(name, forKey: "preferredGrammar")
        
        return try? JSONDecoder().decode(Grammar.self, from: data)
    }

    func loadPreferredGrammar() -> Grammar? {
        let name = UserDefaults.standard.string(forKey: "preferredGrammar")
            ?? "Prime Plus"
        return loadGrammar(named: name)
    }
}
