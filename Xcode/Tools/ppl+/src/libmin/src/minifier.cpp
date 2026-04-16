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

#include "minifier.hpp"
#include "strings.hpp"
#include "unary.hpp"
#include "ppl.hpp"

static std::string removeNewlinesAfterDelimiters(const std::string& input, const std::vector<char>& delimiters) {
    std::string output;
    output.reserve(input.size()); // optional optimization
    size_t len = input.length();

    for (size_t i = 0; i < len; ++i) {
        if (input[i] == '\n' && i > 0) {
            // Check if the previous character is in the delimiters list
            if (std::find(delimiters.begin(), delimiters.end(), input[i - 1]) != delimiters.end()) {
                continue; // skip the newline
            }
        }
        output += input[i];
    }

    return output;
}


// MARK: - ● BEGIN/END block parsing

static std::string base10ToBase32(unsigned int num) {
    if (num == 0) {
        return "0";  // Edge case: if the number is 0, return "0"
    }

    std::string result;
    const char digits[] = "0123456789ABCDEFGHIJKLMNabcdefgh";  // Base-32 digits
    
    // Keep dividing the number by 32 and store the remainders
    while (num > 0) {
        int remainder = num % 32;  // Get the current base-32 digit
        result += digits[remainder];  // Add the corresponding character
        num /= 32;  // Reduce the number
    }

    // The digits are accumulated in reverse order, so reverse the result string
    std::reverse(result.begin(), result.end());

    return result;
}

static std::pair<size_t, size_t> findBeginEndBlock(const std::string& code, size_t beginPos = 0) {
    std::regex tokenRegex(R"(\b(?:BEGIN|FOR|IF|WHILE|REPEAT|CASE|UNTIL)\b|END;)");
    std::smatch match;
    
    std::regex pattern(R"(\bBEGIN\b)");
    // Create iterators for all matches
    auto begin = std::sregex_iterator(code.begin(), code.end(), pattern);
    auto end = std::sregex_iterator();

    // Loop through all matches
    for (auto it = begin; it != end; ++it) {
        std::smatch match = *it;
        if (match.position() >= beginPos) {
            beginPos = match.position() + match.length();
            break;
        }
        if (std::next(it) == end) return {std::string::npos, std::string::npos};
    }
    
    
    size_t searchPos = beginPos;
    int depth = 1;
    
    while (std::regex_search(code.begin() + searchPos, code.end(), match, tokenRegex))
    {
        std::string token = match.str();
        size_t pos = match.position() + searchPos;
        
        if (token == "BEGIN" || token == "FOR" || token == "IF" ||
            token == "WHILE" || token == "REPEAT" || token == "CASE")
        {
            depth++;
        }
        else if (token == "END;" || token == "UNTIL")
        {
            depth--;
            if (depth == 0)
            {
                size_t endPos = pos; // start of matching END;
                return {beginPos, endPos};
            }
        }
        
        searchPos = pos + token.length();
    }
    
    return {std::string::npos, std::string::npos};
}

// Extracts variable names from all LOCAL declarations
static std::vector<std::string> extractLocalVariables(const std::string& code) {
    std::vector<std::string> variables;

    // Match full LOCAL lines: e.g. LOCAL a, b:=10;
    std::regex localRegex(R"(\bLOCAL +([^;:]*);)", std::regex_constants::icase);
    std::smatch match;
    std::string::const_iterator searchStart(code.cbegin());

    while (std::regex_search(searchStart, code.cend(), match, localRegex))
    {
        std::string locals = match[1]; // everything after LOCAL up to ;
        
        // Split by commas
        std::regex varRegex(R"([a-z]\w*)", std::regex_constants::icase);
        std::smatch varMatch;
        std::string::const_iterator varSearch(locals.cbegin());

        while (std::regex_search(varSearch, locals.cend(), varMatch, varRegex))
        {
            std::string varName = varMatch.str();
            variables.push_back(varName);
            varSearch = varMatch.suffix().first;
        }

        searchStart = match.suffix().first;
    }

    return variables;
}

static std::string shortenVariableNames(const std::string& code) {
    auto str = code;
    auto pos = findBeginEndBlock(str);
    
    if (pos.first == std::string::npos && pos.second == std::string::npos) return str;
   
    do {
        auto s = str.substr(pos.first, pos.second - pos.first);
        
        int count = 0;
        auto vars = extractLocalVariables(s);
        for (const auto& v : vars) {
            if (v.length() < 3) continue;
            s = replaceWords(s, {v}, "v" + std::to_string(++count));
        }
        str = str.replace(pos.first, pos.second - pos.first, s);
        pos = findBeginEndBlock(str, pos.first);
           
    } while (pos.first != std::string::npos && pos.second != std::string::npos);
    
    return str;
}


// MARK: - 📣 Public API functions

std::string minifier::minify(const std::string& code) {
    std::string str = code;
    
    auto python = extractPythonBlocks(str);
    str = blankOutPythonBlocks(str);
    
    str = removeComments(str);
    
    auto strings = preserveStrings(str);
    str = blankOutStrings(str);
    
    str = replaceOperators(str);
    
    str = capitalizeWords(str, {
        "begin", "end", "return", "kill", "if", "then", "else", "xor", "or", "and", "not",
        "case", "default", "iferr", "ifte", "for", "from", "step", "downto", "to", "do",
        "while", "repeat", "until", "break", "continue", "export", "const", "local", "key"
    });
    
    str = shortenVariableNames(str);
    str = replaceWords(str, {"FROM"}, ":=");
    
    str = cleanWhitespace(str);
    str = fixUnaryMinus(str);
    
    str = restoreStrings(str, strings);
    str = separatePythonMarkers(str);
    str = restorePythonBlocks(str, python);
    str = removeNewlinesAfterDelimiters(str, {';', ',', '{', '}'});
    
    str = regex_replace(str, std::regex(R"(^#pragma mode\(([a-z]+\([^()]+\))+\))"), "$0\n");
    str = regex_replace(str, std::regex(R"(\n{2,})"), "\n");
    str = regex_replace(str, std::regex(R"(#0+)"), "#");

    std::regex re(R"((?:\b(EXPORT|LOCAL) )?([a-zA-Z\u0080-\uFFFF][\w\u0080-\uFFFF]*)\([a-zA-Z,]*\)\s*(?=BEGIN\b))");
    std::sregex_iterator begin(str.begin(), str.end(), re);
    std::sregex_iterator end;
    std::string result = str;
    int fn = 0;
    
    for (auto it = begin; it != end; ++it) {
        std::smatch match = *it;

        if (match[1].str() == "LOCAL") {
            result = replaceWords(result, {match[2].str()}, "fn" + base10ToBase32(fn++));
        }
    }
    
    return result;
}
