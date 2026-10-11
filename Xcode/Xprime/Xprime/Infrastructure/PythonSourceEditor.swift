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

enum PythonSourceEditor {
    static func reduceIndentation(_ source: String) -> String {
        let lines = source.components(separatedBy: .newlines)
        var indentationLevels: [Int] = [0]

        return lines.map { line in
            let indentation = line.prefix(while: { $0 == " " }).count
            let content = String(line.dropFirst(indentation))

            // Preserve blank lines.
            guard !content.trimmingCharacters(in: .whitespaces).isEmpty else {
                return ""
            }

            // Find the matching indentation level or create a new one.
            if indentation > indentationLevels.last! {
                indentationLevels.append(indentation)
            } else {
                while indentationLevels.count > 1,
                      indentation < indentationLevels.last! {
                    indentationLevels.removeLast()
                }

                // Handle an indentation width not previously encountered.
                if indentation != indentationLevels.last! {
                    indentationLevels.append(indentation)
                }
            }

            let newIndentation = indentationLevels.count - 1

            return String(repeating: " ", count: newIndentation) + content
        }
        .joined(separator: "\n")
    }
    
    
    static func preprocessAliases(in source: String) -> String {
        var aliases: [String: String] = [:]
        var output: [String] = []
        var tripleQuote: String? = nil

        for line in source.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Directives are recognised only outside multiline strings.
            if tripleQuote == nil,
               let directive = parseAliasDirective(trimmed) {

                switch directive {
                case .alias(let original, let alias):
                    aliases[alias] = original

                case .unalias(let alias):
                    aliases.removeValue(forKey: alias)
                }

                // Do not include the directive in the output.
                continue
            }

            output.append(
                replacingAliasIdentifiers(
                    in: line,
                    aliases: aliases,
                    tripleQuote: &tripleQuote
                )
            )
        }

        return output.joined(separator: "\n")
    }

    private enum AliasDirective {
        case alias(original: String, alias: String)
        case unalias(String)
    }

    private static func parseAliasDirective(
        _ line: String
    ) -> AliasDirective? {
        // Allow trailing comments on directive lines.
        let statement = String(line.prefix { $0 != "#" })
            .trimmingCharacters(in: .whitespaces)

        let parts = statement.split(whereSeparator: {
            $0.isWhitespace
        })

        if parts.count == 4,
           parts[0] == "alias",
           parts[2] == "as",
           isPythonIdentifier(String(parts[1])),
           isPythonIdentifier(String(parts[3])) {

            return .alias(
                original: String(parts[1]),
                alias: String(parts[3])
            )
        }

        if parts.count == 2,
           parts[0] == "unalias",
           isPythonIdentifier(String(parts[1])) {

            return .unalias(String(parts[1]))
        }

        return nil
    }

    private static func isPythonIdentifier(_ name: String) -> Bool {
        guard let first = name.first,
              first == "_" || first.isLetter else {
            return false
        }

        return name.dropFirst().allSatisfy {
            $0 == "_" || $0.isLetter || $0.isNumber
        }
    }

    private static func replacingAliasIdentifiers(
        in line: String,
        aliases: [String: String],
        tripleQuote: inout String?
    ) -> String {
        let chars = Array(line)
        var result = ""
        var index = 0
        var quote: Character? = nil
        var escaped = false
        var inComment = false

        func resolve(_ name: String) -> String {
            var current = name
            var visited = Set<String>()

            while let replacement = aliases[current],
                  visited.insert(current).inserted {
                current = replacement
            }

            return current
        }

        while index < chars.count {
            let char = chars[index]

            // Inside a Python triple-quoted string.
            if let triple = tripleQuote {
                if index + 2 < chars.count,
                   String(chars[index...index + 2]) == triple {
                    result += triple
                    index += 3
                    tripleQuote = nil
                } else {
                    result.append(char)
                    index += 1
                }
                continue
            }

            // Inside a normal single- or double-quoted string.
            if let activeQuote = quote {
                result.append(char)
                index += 1

                if escaped {
                    escaped = false
                } else if char == "\\" {
                    escaped = true
                } else if char == activeQuote {
                    quote = nil
                }

                continue
            }

            // Comments must remain unchanged.
            if inComment {
                result.append(char)
                index += 1
                continue
            }

            if char == "#" {
                inComment = true
                result.append(char)
                index += 1
                continue
            }

            // Detect triple-quoted strings.
            if char == "'" || char == "\"" {
                if index + 2 < chars.count,
                   chars[index + 1] == char,
                   chars[index + 2] == char {
                    let triple = String(repeating: String(char), count: 3)
                    result += triple
                    tripleQuote = triple
                    index += 3
                } else {
                    quote = char
                    result.append(char)
                    index += 1
                }
                continue
            }

            // Replace identifiers, not substrings.
            if char == "_" || char.isLetter {
                let start = index
                index += 1

                while index < chars.count,
                      chars[index] == "_" ||
                        chars[index].isLetter ||
                        chars[index].isNumber {
                    index += 1
                }

                let identifier = String(chars[start..<index])
                result += resolve(identifier)
                continue
            }

            result.append(char)
            index += 1
        }

        return result
    }

}
