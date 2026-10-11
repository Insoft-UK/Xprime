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
    
    private struct PythonToken {
        let text: String
        let start: String.Index
        let end: String.Index
        let line: Int
        let indent: Int
        let isIdentifier: Bool
    }

    private struct PythonScope {
        var startLine: Int
        var endLine: Int
        var indent: Int
        var locals: Set<String> = []
        var globals: Set<String> = []
        var replacements: [String: String] = [:]
        var name: String?
    }

    private static let pythonKeywords: Set<String> = [
        "False", "None", "True", "and", "as", "assert",
        "async", "await", "break", "class", "continue",
        "def", "del", "elif", "else", "except", "finally",
        "for", "from", "global", "if", "import", "in",
        "is", "lambda", "nonlocal", "not", "or", "pass",
        "raise", "return", "try", "while", "with", "yield"
    ]

    private static let pythonBuiltins: Set<String> = [
        "abs", "all", "any", "ascii", "bin", "bool",
        "breakpoint", "bytearray", "bytes", "callable",
        "chr", "classmethod", "compile", "complex",
        "delattr", "dict", "dir", "divmod", "enumerate",
        "eval", "exec", "filter", "float", "format",
        "frozenset", "getattr", "globals", "hasattr",
        "hash", "help", "hex", "id", "input", "int",
        "isinstance", "issubclass", "iter", "len", "list",
        "locals", "map", "max", "memoryview", "min",
        "next", "object", "oct", "open", "ord", "pow",
        "print", "property", "range", "repr", "reversed",
        "round", "set", "setattr", "slice", "sorted",
        "staticmethod", "str", "sum", "super", "tuple",
        "type", "vars", "zip", "__import__"
    ]

    private static let assignmentOperators: Set<String> = [
        "=", "+=", "-=", "*=", "/=", "//=", "%=",
        "**=", "&=", "|=", "^=", ">>=", "<<="
    ]

    static func shortenVariableNames(_ source: String) -> String {
        let tokens = tokenizePython(source)
        var scopes = identifyScopes(in: tokens)

        discoverVariables(
            in: tokens,
            scopes: &scopes
        )

        assignReplacements(
            in: tokens,
            scopes: &scopes
        )

        return applyReplacements(
            to: source,
            tokens: tokens,
            scopes: scopes
        )
    }

    private static func tokenizePython(
        _ source: String
    ) -> [PythonToken] {
        let chars = Array(source)
        var tokens: [PythonToken] = []

        var index = 0
        var line = 0
        var indent = 0
        var lineStart = true

        while index < chars.count {
            let startOffset = index
            let character = chars[index]

            if character == "\n" {
                index += 1
                line += 1
                indent = 0
                lineStart = true
                continue
            }

            if lineStart && (character == " " || character == "\t") {
                indent += character == "\t" ? 8 : 1
                index += 1
                continue
            }

            if character.isWhitespace {
                index += 1
                continue
            }

            lineStart = false

            if character == "#" {
                skipComment(
                    in: chars,
                    index: &index
                )
                continue
            }

            if character == "'" || character == "\"" {
                skipString(
                    in: chars,
                    index: &index
                )

                tokens.append(makeToken(
                    from: source,
                    chars: chars,
                    startOffset: startOffset,
                    endOffset: index,
                    line: line,
                    indent: indent,
                    isIdentifier: false
                ))
                continue
            }

            if character == "_" || character.isLetter {
                index += 1

                while index < chars.count,
                      chars[index] == "_"
                        || chars[index].isLetter
                        || chars[index].isNumber {
                    index += 1
                }

                tokens.append(makeToken(
                    from: source,
                    chars: chars,
                    startOffset: startOffset,
                    endOffset: index,
                    line: line,
                    indent: indent,
                    isIdentifier: true
                ))
                continue
            }

            index += 1

            tokens.append(makeToken(
                from: source,
                chars: chars,
                startOffset: startOffset,
                endOffset: index,
                line: line,
                indent: indent,
                isIdentifier: false
            ))
        }

        return tokens
    }

    private static func skipComment(
        in chars: [Character],
        index: inout Int
    ) {
        while index < chars.count && chars[index] != "\n" {
            index += 1
        }
    }

    private static func skipString(
        in chars: [Character],
        index: inout Int
    ) {
        let quote = chars[index]
        let isTripleQuoted = index + 2 < chars.count
            && chars[index + 1] == quote
            && chars[index + 2] == quote

        index += isTripleQuoted ? 3 : 1

        while index < chars.count {
            if chars[index] == "\\" {
                index += min(2, chars.count - index)
                continue
            }

            if chars[index] == quote {
                if !isTripleQuoted {
                    index += 1
                    break
                }

                if index + 2 < chars.count,
                   chars[index + 1] == quote,
                   chars[index + 2] == quote {
                    index += 3
                    break
                }
            }

            index += 1
        }
    }

    private static func makeToken(
        from source: String,
        chars: [Character],
        startOffset: Int,
        endOffset: Int,
        line: Int,
        indent: Int,
        isIdentifier: Bool
    ) -> PythonToken {
        PythonToken(
            text: String(chars[startOffset..<endOffset]),
            start: source.index(
                source.startIndex,
                offsetBy: startOffset
            ),
            end: source.index(
                source.startIndex,
                offsetBy: endOffset
            ),
            line: line,
            indent: indent,
            isIdentifier: isIdentifier
        )
    }

    private static func identifyScopes(
        in tokens: [PythonToken]
    ) -> [PythonScope] {
        var scopes: [PythonScope] = [
            PythonScope(
                startLine: -1,
                endLine: Int.max,
                indent: -1
            )
        ]

        for index in tokens.indices
        where tokens[index].text == "def" {
            guard index + 1 < tokens.count,
                  tokens[index + 1].isIdentifier else {
                continue
            }

            let functionToken = tokens[index]
            let endLine = findScopeEndLine(
                for: index,
                in: tokens
            )

            scopes.append(
                PythonScope(
                    startLine: functionToken.line,
                    endLine: endLine,
                    indent: functionToken.indent,
                    name: tokens[index + 1].text
                )
            )
        }

        return scopes
    }

    private static func findScopeEndLine(
        for index: Int,
        in tokens: [PythonToken]
    ) -> Int {
        let functionToken = tokens[index]

        for nextIndex in (index + 1)..<tokens.count {
            let token = tokens[nextIndex]

            if token.line > functionToken.line,
               token.indent <= functionToken.indent,
               token.text != ")" {
                return token.line
            }
        }

        return Int.max
    }

    private static func discoverVariables(
        in tokens: [PythonToken],
        scopes: inout [PythonScope]
    ) {
        for index in tokens.indices
        where tokens[index].isIdentifier {
            let scopeIndex = scopeIndex(
                forLine: tokens[index].line,
                in: scopes
            )

            discoverGlobalDeclarations(
                at: index,
                in: tokens,
                scopeIndex: scopeIndex,
                scopes: &scopes
            )

            discoverFunctionParameters(
                at: index,
                in: tokens,
                scopes: &scopes
            )

            discoverAssignments(
                at: index,
                in: tokens,
                scopeIndex: scopeIndex,
                scopes: &scopes
            )

            discoverLoopVariables(
                at: index,
                in: tokens,
                scopeIndex: scopeIndex,
                scopes: &scopes
            )
        }
    }

    private static func discoverGlobalDeclarations(
        at index: Int,
        in tokens: [PythonToken],
        scopeIndex: Int,
        scopes: inout [PythonScope]
    ) {
        guard tokens[index].text == "global",
              scopeIndex != 0 else {
            return
        }

        var nextIndex = index + 1

        while nextIndex < tokens.count,
              tokens[nextIndex].line == tokens[index].line {
            if tokens[nextIndex].isIdentifier {
                scopes[scopeIndex].globals.insert(
                    tokens[nextIndex].text
                )
            }

            nextIndex += 1
        }
    }

    private static func discoverFunctionParameters(
        at index: Int,
        in tokens: [PythonToken],
        scopes: inout [PythonScope]
    ) {
        guard tokens[index].text == "def",
              index + 1 < tokens.count else {
            return
        }

        let functionName = tokens[index + 1].text

        guard let functionScope = scopes.indices.first(where: {
            $0 != 0
                && scopes[$0].name == functionName
                && scopes[$0].startLine == tokens[index].line
        }) else {
            return
        }

        var nextIndex = index + 2

        while nextIndex < tokens.count,
              tokens[nextIndex].text != ")" {
            if tokens[nextIndex].isIdentifier,
               nextIndex + 1 < tokens.count,
               [",", "=", ":", "/"].contains(
                    tokens[nextIndex + 1].text
               ) {
                scopes[functionScope].locals.insert(
                    tokens[nextIndex].text
                )
            }

            nextIndex += 1
        }
    }

    private static func discoverAssignments(
        at index: Int,
        in tokens: [PythonToken],
        scopeIndex: Int,
        scopes: inout [PythonScope]
    ) {
        guard index + 1 < tokens.count,
              assignmentOperators.contains(
                tokens[index + 1].text
              ),
              !pythonKeywords.contains(tokens[index].text) else {
            return
        }

        addLocalVariable(
            tokens[index].text,
            to: scopeIndex,
            scopes: &scopes
        )
    }

    private static func discoverLoopVariables(
        at index: Int,
        in tokens: [PythonToken],
        scopeIndex: Int,
        scopes: inout [PythonScope]
    ) {
        guard index > 0,
              tokens[index - 1].text == "for" else {
            return
        }

        addLocalVariable(
            tokens[index].text,
            to: scopeIndex,
            scopes: &scopes
        )
    }

    private static func addLocalVariable(
        _ name: String,
        to scopeIndex: Int,
        scopes: inout [PythonScope]
    ) {
        if scopeIndex == 0 {
            scopes[0].locals.insert(name)
        } else if !scopes[scopeIndex].globals.contains(name) {
            scopes[scopeIndex].locals.insert(name)
        }
    }

    private static func assignReplacements(
        in tokens: [PythonToken],
        scopes: inout [PythonScope]
    ) {
        var counter = 1

        for index in tokens.indices
        where tokens[index].isIdentifier {
            let name = tokens[index].text
            let scopeIndex = scopeIndex(
                forLine: tokens[index].line,
                in: scopes
            )

            guard shouldRename(
                tokenIndex: index,
                name: name,
                tokens: tokens
            ) else {
                continue
            }

            let targetScope = targetScopeIndex(
                for: name,
                in: scopeIndex,
                scopes: scopes
            )

            if scopes[targetScope].replacements[name] == nil {
                scopes[targetScope].replacements[name] = "v\(counter)"
                counter += 1
            }
        }
    }

    private static func applyReplacements(
        to source: String,
        tokens: [PythonToken],
        scopes: [PythonScope]
    ) -> String {
        var result = source

        for index in tokens.indices.reversed()
        where tokens[index].isIdentifier {
            let name = tokens[index].text
            let scopeIndex = scopeIndex(
                forLine: tokens[index].line,
                in: scopes
            )

            guard shouldRename(
                tokenIndex: index,
                name: name,
                tokens: tokens
            ) else {
                continue
            }

            let targetScope = targetScopeIndex(
                for: name,
                in: scopeIndex,
                scopes: scopes
            )

            guard let replacement = scopes[targetScope]
                .replacements[name] else {
                continue
            }

            result.replaceSubrange(
                tokens[index].start..<tokens[index].end,
                with: replacement
            )
        }

        return result
    }

    private static func scopeIndex(
        forLine line: Int,
        in scopes: [PythonScope]
    ) -> Int {
        scopes.indices
            .filter {
                $0 != 0
                    && scopes[$0].startLine < line
                    && line < scopes[$0].endLine
            }
            .max {
                scopes[$0].startLine < scopes[$1].startLine
            } ?? 0
    }

    private static func targetScopeIndex(
        for name: String,
        in scopeIndex: Int,
        scopes: [PythonScope]
    ) -> Int {
        if scopeIndex == 0 {
            return 0
        }

        if scopes[scopeIndex].globals.contains(name) {
            return 0
        }

        if scopes[scopeIndex].locals.contains(name) {
            return scopeIndex
        }

        return scopes[0].locals.contains(name)
            ? 0
            : scopeIndex
    }

    private static func shouldRename(
        tokenIndex: Int,
        name: String,
        tokens: [PythonToken]
    ) -> Bool {
        guard name.count > 3,
              !pythonKeywords.contains(name),
              !pythonBuiltins.contains(name) else {
            return false
        }

        if tokenIndex > 0,
           ["def", "class", "."].contains(
                tokens[tokenIndex - 1].text
           ) {
            return false
        }

        if tokenIndex + 1 < tokens.count,
           tokens[tokenIndex + 1].text == "=",
           tokenIndex > 0,
           ["(", ","].contains(
                tokens[tokenIndex - 1].text
           ) {
            return false
        }

        return true
    }
}
