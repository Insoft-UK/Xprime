// The MIT License (MIT)
//
// Copyright (c) 2023-2026 Insoft.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#pragma once

#include <cstddef>
#include <string>
#include <vector>

class PythonMinifier
{
public:
    [[nodiscard]]
    std::string minify(const std::string& source);

private:
    enum class StringState
    {
        None,
        Single,
        Double,
        TripleSingle,
        TripleDouble
    };

    const std::string* source_ = nullptr;
    std::string output_;
    std::vector<int> indentation_{0};

    std::size_t position_ = 0;
    int bracketDepth_ = 0;
    int indentationColumn_ = 0;

    StringState stringState_ = StringState::None;

    bool lineStart_ = true;
    bool pendingSpace_ = false;
    bool escaped_ = false;

    // Initialisation
    void reset(const std::string& source);

    // Source scanning
    [[nodiscard]] bool atEnd() const;
    [[nodiscard]] char currentChar() const;
    [[nodiscard]] char peekChar(std::size_t offset = 1) const;
    void advance();

    // Character classification
    [[nodiscard]] static bool isIdentifierCharacter(char c);
    [[nodiscard]] static bool isOperatorCharacter(char c);
    [[nodiscard]] static bool isOpeningBracket(char c);
    [[nodiscard]] static bool isClosingBracket(char c);

    // Processing
    void processCharacter();
    void processIndentation();
    void updateIndentation(int column);
    void processComment();
    void processWhitespace();
    void processNewline();
    void processLineContinuation();
    void processStringStart();
    void processString();
    void processBracket();
    
    // Output formatting
    void appendCharacter(char c);
    [[nodiscard]] bool requiresSeparator(char previous, char next) const;
    void appendNewline();
    void trimTrailingWhitespace();
    std::string combineStatements(const std::string& source);
    std::string shortenVariables(const std::string& source);
};
