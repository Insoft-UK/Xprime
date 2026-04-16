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

#include "ppl.hpp"

static bool isWordChar(char c) {
    return std::isalnum(static_cast<unsigned char>(c)) || c == '_';
}

std::string ensureSpaceAfterKeywords(const std::string& input, const std::vector<std::string>& keywords) {
    std::unordered_set<std::string> keywordSet(
        keywords.begin(), keywords.end()
    );

    std::string output;
    size_t i = 0;

    while (i < input.size()) {
        // Try to read a word
        if (isWordChar(input[i])) {
            size_t start = i;
            while (i < input.size() && isWordChar(input[i])) {
                i++;
            }

            std::string word = input.substr(start, i - start);
            output += word;

            // Word boundary on both sides + keyword match
            if (keywordSet.count(word)) {
                // If next character exists and is NOT whitespace
                if (i < input.size() && !std::isspace(static_cast<unsigned char>(input[i]))) {
                    output += ' ';
                }
            }
        } else {
            output += input[i];
            i++;
        }
    }

    return output;
}

static std::string toLower(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(),
                   [](unsigned char c) { return std::tolower(c); });
    return s;
}

std::string ensureSpaceAfterKeywordsCaseInsensitive(const std::string& input, const std::vector<std::string>& keywords) {
    // Store keywords lowercased
    std::unordered_set<std::string> keywordSet;
    for (const auto& k : keywords) {
        keywordSet.insert(toLower(k));
    }

    std::string output;
    size_t i = 0;

    while (i < input.size()) {
        if (isWordChar(input[i])) {
            size_t start = i;
            while (i < input.size() && isWordChar(input[i])) {
                i++;
            }

            std::string word = input.substr(start, i - start);
            output += word;

            // Case-insensitive check
            if (keywordSet.count(toLower(word))) {
                // Insert space if next char exists and is NOT whitespace
                if (i < input.size() &&
                    !std::isspace(static_cast<unsigned char>(input[i])))
                {
                    output += ' ';
                }
            }
        } else {
            output += input[i];
            i++;
        }
    }

    return output;
}

std::string replaceOperators(const std::string& input) {
    std::string output;
    output.reserve(input.size());  // Reserve space to reduce reallocations

    for (std::size_t i = 0; i < input.size(); ++i) {
        if (i + 1 < input.size()) {
            // Lookahead for 2-character operators
            if (input[i] == '>' && input[i + 1] == '=') {
                output += "≥";
                ++i;
                continue;
            }
            if (input[i] == '<' && input[i + 1] == '=') {
                output += "≤";
                ++i;
                continue;
            }
            if (input[i] == '<' && input[i + 1] == '>') {
                output += "≠";
                ++i;
                continue;
            }
        }

        // Default: copy character
        output += input[i];
    }

    return output;
}

std::string extractComment(const std::string &str) {
    std::string output;
    size_t pos = str.find("//");
    
    if (pos != std::string::npos) {
        output = str.substr(pos + 2, str.length() - pos - 2);
    }
    return output;
}

std::vector<std::string> extractComments(const std::string& str) {
    std::string comment;
    std::vector<std::string> comments;

    size_t i = 0;
    while (i < str.size()) {
        // Detect start of comment
        if (i + 1 < str.size() && str[i] == '/' && str[i + 1] == '/') {
            comment = "";
            // Skip until the next newline
            i += 2;
            while (i < str.size() && str[i] != '\n') {
                comment += str[i];
                i++;
            }
            comments.push_back(comment);
        } else {
            i++;
        }
    }

    return comments;
}

std::string restoreComments(const std::string& str, const std::vector<std::string>& comments) {
    std::string output;
    size_t commentIndex = 0;

    size_t i = 0;
    while (i < str.size()) {
        // Detect "//" with nothing after it on the line
        if (i + 1 < str.size() &&
            str[i] == '/' &&
            str[i + 1] == '/' &&
            commentIndex < comments.size())
        {
            // Copy "//"
            output += "//";
            i += 2;

            // If immediately end-of-line or whitespace then newline,
            // restore the original comment text
            if (i >= str.size() || str[i] == '\n') {
                output += comments[commentIndex++];
            } else {
                // Skip anything up to newline (defensive)
                while (i < str.size() && str[i] != '\n') {
                    i++;
                }
                output += comments[commentIndex++];
            }
        } else {
            output += str[i];
            i++;
        }
    }

    return output;
}

std::string removeComment(const std::string& str) {
    std::string output = str;
    size_t pos = str.find("//");
    
    if (pos != std::string::npos) {
        output.resize(pos + 2);
    }
    
    return output;
}

std::string removeComments(const std::string& str) {
    std::string output;
    output.reserve(str.size());

    size_t i = 0;
    while (i < str.size()) {
        // Detect start of comment
        if (i + 1 < str.size() && str[i] == '/' && str[i + 1] == '/') {
            // Skip until the next newline
            i += 2;
            while (i < str.size() && str[i] != '\n') {
                i++;
            }
            // If newline exists, keep the newline
            if (i < str.size()) {
                output += '\n';
                i++;
            }
        } else {
            // Normal character: keep it
            output += str[i++];
        }
    }

    return output;
}

std::string blankOutComments(const std::string& str) {
    std::string output;
    output.reserve(str.size());

    size_t i = 0;
    while (i < str.size()) {
        // Detect start of comment
        if (i + 1 < str.size() && str[i] == '/' && str[i + 1] == '/') {
            // Skip until the next newline
            i += 2;
            while (i < str.size() && str[i] != '\n') {
                i++;
            }
            // If newline exists, keep the newline
            if (i < str.size()) {
                output += "//\n";
                i++;
            }
        } else {
            // Normal character: keep it
            output += str[i++];
        }
    }

    return output;
}

std::string processEscapes(const std::string& input, int indentWidth) {
    std::string result;
    for (size_t i = 0; i < input.length(); ++i) {
        if (input[i] != '\\' || i + 1 == input.length()) {
            result += input[i];
            continue;
        }
        char next = input[i + 1];
        if (next == 'n') {
            result += '\n';
            ++i;
            continue;
        }
        if (next == 's') {
            result += ' ';
            ++i;
            continue;
        }
        if (next == 't') {
            result += (std::string(indentWidth, ' '));
            ++i;
            continue;
        }
        if (next == 'i') {
            size_t count = input.find_first_not_of(" \t\r\n");
            result += std::string(count, ' ');
            ++i;
            continue;
        }
        if (next == 'a') {
            size_t count = input.find_first_not_of(" \t\r\n");
            result += "\n" + std::string(count, ' ');
            ++i;
            continue;
        }
        result += input[i]; // add the backslash
        result += next;     // add the next character as is
        ++i; // skip the next character
    }
    return result;
}

std::string removeTripleSlashComment(const std::string& str) {
    std::string output = str;
    
    size_t pos = output.find("///");
    if (pos == std::string::npos) return output;
    
    std::size_t newline = output.find('\n', pos);
    if (newline != std::string::npos) {
        // Remove from '///' up to (but not including) the newline
        output.erase(pos, newline - pos);
        return output;
    }
    
    // No newline after '///', remove till end of string
    output.erase(pos);
    
    return output;
}


std::string convertAssignToColonEqual(const std::string& input) {
    std::string output;
    output.reserve(input.size() * 2);  // Conservative buffer size

    for (size_t i = 0; i < input.size(); ++i) {
        if (input[i] == '=') {
            // Check for '=='
            if (i + 1 < input.size() && input[i + 1] == '=') {
                output += "==";
                ++i;
            }
            // Check for ':=' (don't modify)
            else if (i > 0 && input[i - 1] == ':') {
                output += '=';
            }
            // Replace single '=' with ':='
            else {
                output += ":=";
            }
        } else {
            output += input[i];
        }
    }

    return output;
}

std::string expandAssignmentEquals(const std::string& input) {
    std::string output;
    output.reserve(input.size() * 2);  // Worst-case growth

    for (size_t i = 0; i < input.size(); ++i) {
        if (input[i] == '=') {
            // Check if preceded by ':' (:=), do not expand
            if (i > 0 && input[i - 1] == ':') {
                output += '=';
            }
            // Check if followed by '=' (already '=='), copy as-is
            else if (i + 1 < input.size() && input[i + 1] == '=') {
                output += "==";
                ++i;  // skip next '='
            }
            else {
                output += "==";
            }
        } else {
            output += input[i];
        }
    }

    return output;
}


std::list<std::string> extractPythonBlocks(const std::string& str) {
    std::list<std::string> blocks;
    const std::string startTag = "#PYTHON";
    const std::string endTag = "#END";
    
    size_t pos = 0;

    while (true) {
        size_t start = str.find(startTag, pos);
        if (start == std::string::npos)
            break;

        start += startTag.length();  // move past the #PYTHON tag

        size_t end = str.find(endTag, start);
        if (end == std::string::npos)
            break;  // no matching #END, so stop

        blocks.push_back(str.substr(start, end - start));
        pos = end + endTag.length();  // move past this #END
    }

    return blocks;
}


std::string blankOutPythonBlocks(const std::string& str) {
    std::string result;
    const std::string startTag = "#PYTHON";
    const std::string endTag = "#END";
    
    size_t pos = 0;

    while (pos < str.length()) {
        size_t start = str.find(startTag, pos);

        if (start == std::string::npos) {
            result.append(str, pos, str.length() - pos);
            break;
        }

        // Append everything before #PYTHON
        result.append(str, pos, start - pos);

        size_t end = str.find(endTag, start + startTag.length());
        if (end == std::string::npos) {
            // No matching #END — treat rest as normal text
            result.append(str, start, str.length() - start);
            break;
        }

        // Keep the #PYTHON and #END markers, but blank out in between
        result += startTag;
        result.append(end - (start + startTag.length()), ' ');
        result += endTag;

        pos = end + endTag.length();
    }

    return result;
}

std::string restorePythonBlocks(const std::string& str, std::list<std::string>& blocks) {
    if (blocks.empty()) return str;

    const std::string startTag = "#PYTHON";
    const std::string endTag = "#END";

    std::string result;
    size_t pos = 0;

    while (pos < str.size()) {
        size_t start = str.find(startTag, pos);
        if (start == std::string::npos) {
            result.append(str, pos, str.size() - pos);  // append rest
            break;
        }

        // Append text before #PYTHON
        result.append(str, pos, start - pos);

        size_t end = str.find(endTag, start + startTag.length());
        if (end == std::string::npos || blocks.empty()) {
            // No matching #END or no block left — append rest
            result.append(str, start, str.size() - start);
            break;
        }

        // Append #PYTHON
        result.append(str, start, startTag.length());

        // Append original block content
        result.append(blocks.front());
        blocks.pop_front();

        // Append #END
        result.append(str, end, endTag.length());

        pos = end + endTag.length();
    }

    return result;
}

std::string separatePythonMarkers(const std::string& input) {
    std::istringstream iss(input);
    std::ostringstream oss;
    std::string line;

    const std::string markers[] = {"#PYTHON", "#END"};

    while (std::getline(iss, line)) {
        size_t pos = 0;

        while (pos < line.size()) {
            bool foundMarker = false;
            for (const std::string& marker : markers) {
                size_t markerPos = line.find(marker, pos);
                if (markerPos != std::string::npos) {
                    // Add any content before the marker (if any) as a separate line
                    if (markerPos > pos) {
                        oss << line.substr(pos, markerPos - pos) << '\n';
                    }
                    // Add the marker as its own line
                    oss << marker << '\n';
                    pos = markerPos + marker.length();
                    foundMarker = true;
                    break;
                }
            }

            if (!foundMarker) {
                // No more markers on this line, output the rest
                oss << line.substr(pos) << '\n';
                break;
            }
        }
    }

    return oss.str();
}

std::string normalizeOperators(const std::string& input, const std::vector<std::string> operators) {
    // List of all operators to normalize
        
        std::string result;
        size_t i = 0;

        while (i < input.size()) {
            bool matched = false;

            for (const std::string& op : operators) {
                if (input.compare(i, op.size(), op) == 0) {
                    if (!result.empty() && result.back() != ' ') result += ' ';
                    result += op;
                    i += op.size();
                    if (i < input.size() && input[i] != ' ') result += ' ';
                    matched = true;
                    break;
                }
            }

            if (!matched) {
                result += input[i++];
            }
        }

        // Final cleanup: collapse multiple spaces
        std::istringstream iss(result);
        std::string word, cleaned;
        while (iss >> word) {
            if (!cleaned.empty()) cleaned += ' ';
            cleaned += word;
        }

        return cleaned;
}
