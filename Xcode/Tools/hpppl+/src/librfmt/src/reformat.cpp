// The MIT License (MIT)
//
// Copyright (c) 2023-2025 Insoft.
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

#include "reformat.hpp"
#include "hpppl.hpp"
#include "strings.hpp"
#include "unary.hpp"


#define INDENT_WIDTH 2


static bool isWordChar(char c)
{
    return std::isalnum(static_cast<unsigned char>(c)) || c == '_';
}

static bool isWordBoundary(const std::string& s, size_t pos)
{
    if (pos == 0 || pos >= s.size())
        return true;

    return isWordChar(s[pos - 1]) != isWordChar(s[pos]);
}

static bool isOnlyWhitespaceUntilNewline(const std::string& s, size_t pos)
{
    for (size_t i = pos; i < s.size(); ++i) {
        if (s[i] == '\n')
            return true;
        if (!std::isspace(static_cast<unsigned char>(s[i])))
            return false;
    }
    return true;
}

static std::string insertNewlineAfterSemicolon(const std::string& input)
{
    std::string output;
    const size_t n = input.size();

    for (size_t i = 0; i < n; ++i) {
        output += input[i];

        if (input[i] == ';') {
            size_t next = i + 1;

            if (next < n &&
                input[next] != '\n' &&
                !isOnlyWhitespaceUntilNewline(input, next))
            {
                output += '\n';
            }
        }
    }

    return output;
}

static std::string insertSpaceAfterComma(const std::string& input)
{
    std::string output;
    const size_t n = input.size();

    for (size_t i = 0; i < n; ++i) {
        output += input[i];

        if (input[i] == ',' && i + 1 < n && input[i + 1] != '\n') {
            output += ' ';
        }
    }

    return output;
}

static std::string insertNewlineAfterWords(
    const std::string& input,
    const std::unordered_set<std::string>& words)
{
    std::string output;
    const size_t n = input.size();

    for (size_t i = 0; i < n; ) {
        bool matched = false;

        for (const auto& word : words) {
            const size_t len = word.length();
            const size_t end = i + len;

            if (end <= n &&
                input.compare(i, len, word) == 0 &&
                isWordBoundary(input, i) &&
                isWordBoundary(input, end))
            {
                output += word;

                // Insert newline ONLY if meaningful text follows on same line
                if (end < n &&
                    input[end] != '\n' &&
                    !isOnlyWhitespaceUntilNewline(input, end))
                {
                    output += '\n';
                }

                i = end;
                matched = true;
                break;
            }
        }

        if (!matched) {
            output += input[i++];
        }
    }

    return output;
}

static std::string insertNewlineBeforeWords(
    const std::string& input,
    const std::unordered_set<std::string>& words)
{
    std::string output;
    const size_t n = input.size();

    for (size_t i = 0; i < n; ) {
        bool matched = false;

        for (const auto& word : words) {
            const size_t len = word.length();
            const size_t end = i + len;

            if (end <= n &&
                input.compare(i, len, word) == 0 &&
                isWordBoundary(input, i) &&
                isWordBoundary(input, end))
            {
                // Insert newline if previous char exists and is NOT whitespace
                if (i > 0 &&
                    input[i - 1] != '\n' &&
                    !std::isspace(static_cast<unsigned char>(input[i - 1])))
                {
                    output += '\n';
                }

                output += word;
                i = end;
                matched = true;
                break;
            }
        }

        if (!matched) {
            output += input[i++];
        }
    }

    return output;
}

// MARK: - Utills


static std::string reformatLine(const std::string& str) {
    static int depth = 0;
    std::string output = str;
    
    std::regex tokenRegex(R"(\b(?:BEGIN|FOR|IF|WHILE|REPEAT|CASE|UNTIL|ELSE)\b|END;)");
    std::smatch match;
    if (std::regex_search(output, match, tokenRegex)) {
        std::string token = match.str();
        
        if (token == "BEGIN" || token == "FOR" || token == "IF" ||
            token == "WHILE" || token == "REPEAT" || token == "CASE")
        {
            output.insert(0, std::string(depth * INDENT_WIDTH, ' '));
            depth++;
        }
        
        if (token == "END;" || token == "UNTIL")
        {
            depth--;
            if (depth > -1) {
                output.insert(0, std::string(depth * INDENT_WIDTH, ' '));
            }
        }
        
        if (token == "ELSE")
        {
            output.insert(0, std::string((depth - 1) * INDENT_WIDTH, ' '));
        }
    } else {
        output.insert(0, std::string(depth * INDENT_WIDTH, ' '));
    }
    return output + '\n';
}

static std::string reformatAllLines(std::istringstream& iss)
{
    std::string str;
    std::string result;
    
    while(getline(iss, str)) {
        result.append(reformatLine(str));
    }
    
    return result;
}

std::string reformat::prgm(const std::string& s)
{
    std::string output = s;
    std::regex re;

    
    auto comments = extractComments(output);
    output = blankOutComments(output);
    
    auto python = extractPythonBlocks(output) ;
    output = blankOutPythonBlocks(output);
    
    auto strings = preserveStrings(output);
    output = blankOutStrings(output);
    
    output = insertNewlineAfterWords(output, {"THEN", "DO", "REPEAT", "ELSE", "DEFAULT", "CASE"});
    output = insertNewlineBeforeWords(output, {"EXPORT", "LOCAL", "CONST", "IF", "CASE", "REPEAT", "FOR", "WHILE", "DEFAULT", "UNTIL", "ELSE", "IFERR", "END;"});

    
    // Keywords
    output = capitalizeWords(output, {
        "begin", "end", "return", "kill", "if", "then", "else", "xor", "or", "and", "not",
        "case", "default", "iferr", "ifte", "for", "from", "step", "downto", "to", "do",
        "while", "repeat", "until", "break", "continue", "export", "const", "local",
        "eval", "freeze", "view"
    });
    
    output = cleanWhitespace(output);
    output = insertSpaceAfterComma(output);
    output = fixUnaryMinus(output);
    output = replaceOperators(output);
    
    std::istringstream iss;
    iss.str(output);
    output = reformatAllLines(iss);
    
    output = ensureSpaceAfterKeywordsCaseInsensitive(output, {
        "begin", "return", "kill", "if", "then", "else", "xor", "or", "and", "not",
        "case", "default", "iferr", "ifte", "for", "from", "step", "downto", "to", "do",
        "while", "repeat", "until", "break", "continue", "export", "const", "local", "key",
        "eval", "freeze", "view"
    });
    
    output = separatePythonMarkers(output);
    output = restorePythonBlocks(output, python);
    output = restoreStrings(output, strings);
    output = restoreComments(output, comments);
    
    return output;
}
