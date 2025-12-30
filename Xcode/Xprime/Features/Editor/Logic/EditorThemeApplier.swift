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

final class EditorThemeApplier {

    static func apply(_ theme: Theme, to editor: CodeEditorTextView) {

        func color(for scope: String) -> NSColor {
            for token in theme.tokenColors {
                if token.scope.contains(scope) {
                    let hex = token.settings.foreground
                    if let color = NSColor(hex: hex) {
                        return color
                    }
                }
            }
            return editor.editorForegroundColor
        }

        editor.editorForegroundColor =
            NSColor(hex: theme.colors["editor.foreground"]!)!

        editor.backgroundColor =
            NSColor(hex: theme.colors["editor.background"]!)!

        editor.textColor = editor.editorForegroundColor

        editor.selectedTextAttributes = [
            .backgroundColor: NSColor(
                hex: theme.colors["editor.selectionBackground"]!
            )!
        ]

        editor.insertionPointColor =
            NSColor(hex: theme.colors["editor.cursor"]!)!
        
        
        
        switch theme.weight {
        case "ultraLight":
            editor.weight = .ultraLight
        case "thin":
            editor.weight = .thin
        case "light":
            editor.weight = .light
        case "regular":
            editor.weight = .regular
        case "medium":
            editor.weight = .medium
        case "semibold":
            editor.weight = .semibold
        case "bold":
            editor.weight = .bold
        case "heavy":
            editor.weight = .heavy
        case "black":
            editor.weight = .black
        default:
            editor.weight = .regular
        }
        
        
        editor.font = .monospacedSystemFont(ofSize: 12 , weight: editor.weight)
        

        editor.colors["Keywords"] = color(for: "Keywords")
        editor.colors["Symbols"] = color(for: "Symbols")
        editor.colors["Operators"] = color(for: "Operators")
        editor.colors["Brackets"] = color(for: "Brackets")
        editor.colors["Numbers"] = color(for: "Numbers")
        editor.colors["Strings"] = color(for: "Strings")
        editor.colors["Comments"] = color(for: "Comments")
        editor.colors["Backquotes"] = color(for: "Backquotes")
        editor.colors["Preprocessor Statements"] = color(for: "Preprocessor Statements")
        editor.colors["Functions"] = color(for: "Functions")
        editor.colors["Namespace"] = color(for: "Namespace")
    }
}
