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


#include "aliases.hpp"
#include "common.hpp"

#include "singleton.hpp"
#include <regex>
#include <sstream>
#include <algorithm>

using pplplus::Aliases;

//MARK: - Functions

static bool compareInterval(Aliases::TIdentity i1, Aliases::TIdentity i2) {
    return (i1.identifier.length() > i2.identifier.length());
}

//static bool compareIntervalString(std::string i1, std::string i2) {
//    return (i1.length() > i2.length());
//}

/**
 * @brief Extracts and preserves all double-quoted substrings from the input string.
 *
 * Handles escaped quotes (e.g., \" inside quoted text) and does not use regex.
 *
 * @param str The input string.
 * @return std::list<std::string> A list of quoted substrings, including the quote characters.
 */
static std::list<std::string> preserveStrings(const std::string& str) {
    std::list<std::string> strings;
    bool inQuotes = false;
    std::string current;
    
    for (size_t i = 0; i < str.size(); ++i) {
        char c = str[i];

        if (!inQuotes) {
            if (c == '"') {
                inQuotes = true;
                current.clear();
                current += c;  // start quote
            }
        } else {
            current += c;

            if (c == '"' && (i == 0 || str[i - 1] != '\\')) {
                // End of quoted string (unescaped quote)
                inQuotes = false;
                strings.push_back(current);
            }
        }
    }

    return strings;
}
/**
 * @brief Replaces all double-quoted substrings in the input string with "".
 *
 * Handles escaped quotes (e.g., \" inside strings) and does not use regex.
 *
 * @param str The input string to process.
 * @return std::string A new string with quoted substrings replaced by "".
 */
static std::string blankOutStrings(const std::string& str) {
    std::string result;
    bool inQuotes = false;
    size_t start = 0;

    for (size_t i = 0; i < str.length(); ++i) {
        // Start of quoted string
        if (!inQuotes && str[i] == '"') {
            inQuotes = true;
            result.append(str, start, i - start);  // Append text before quote
            start = i; // mark quote start
        }
        // Inside quoted string
        else if (inQuotes && str[i] == '"' && (i == 0 || str[i - 1] != '\\')) {
            // End of quoted string
            inQuotes = false;
            result += "\"\"";  // Replace quoted string with empty quotes
            start = i + 1;     // Next copy chunk starts after closing quote
        }
    }

    // Append remaining text after last quoted section
    if (start < str.size()) {
        result.append(str, start, str.size() - start);
    }

    return result;
}

/**
 * @brief Restores quoted strings into a string that had them blanked out.
 *
 * @param str The string with blanked-out quoted substrings (e.g., `""`).
 * @param strings A list of original quoted substrings, in the order they appeared.
 * @return std::string A new string with the original quoted substrings restored.
 */
static std::string restoreStrings(const std::string& str, std::list<std::string>& strings) {
    static const std::regex re(R"("[^"]*")");

    if (strings.empty()) return str;

    std::string result;
    std::size_t lastPos = 0;

    auto stringIt = strings.begin();
    for (auto it = std::sregex_iterator(str.begin(), str.end(), re);
         it != std::sregex_iterator() && stringIt != strings.end(); ++it, ++stringIt)
    {
        const std::smatch& match = *it;

        // Append the part before the match
        result.append(str, lastPos, match.position() - lastPos);

        // Append the preserved quoted string
        result.append(*stringIt);

        // Update the last position
        lastPos = match.position() + match.length();
    }

    // Append the remaining part of the string after the last match
    result.append(str, lastPos, std::string::npos);

    return result;
}

//MARK: - Public Methods

bool Aliases::append(const TIdentity &idty) {
    TIdentity identity = idty;
    Singleton *singleton = Singleton::shared();
    
    if (identity.identifier.empty()) return false;
    
    trim(identity.identifier);
    trim(identity.real);
    identity.path = singleton->currentSourceFilePath();
    identity.line = singleton->currentLineNumber();
    
    if (!identity.message.empty()) {
        trim(identity.message);
        identity.message.insert(0, ", ");
    }
    
    if (identity.scope == -1) {
        identity.scope = Singleton::shared()->scopeDepth;
    }
    
    if (identity.type == Type::Argument) identity.scope = 1;
    
    std::string filename = Singleton::shared()->currentSourceFilePath().filename().string();
    
    
    if (identifierExists(identity.identifier)) {
        for (const auto &it : _identities) {
            if (it.identifier == identity.identifier) {
                std::cerr
                << MessageType::Warning
                << "redefinition of: " << identity.identifier << ", ";
                if (filename == it.path.filename()) {
                    std::cerr << "previous definition on line " << it.line << "\n";
                }
                else {
                    std::cerr << "previous definition in " << it.path.filename() << " on line " << it.line << "\n";
                }
                break;
            }
        }
        return false;
    }
    
    _identities.push_back(identity);
    
    // Resort in descending order
    std::sort(_identities.begin(), _identities.end(), compareInterval);
    
    if (verbose) std::cerr
        << MessageType::Verbose
        << "defined "
        << (identity.scope > 0 ? "local " : "")
        << (Type::Unknown == identity.type ? "alias " : "")
        << (Type::Macro == identity.type ? "macro " : "")
        << (Type::Alias == identity.type ? "alias " : "")
        << (Type::Function == identity.type ? "function alias " : "")
        << (Type::Argument == identity.type ? "argument alias " : "")
        << (Type::Variable == identity.type ? "variable alias" : "")
        << "'" << identity.identifier << "' "
        << (identity.real.empty() ? "\n" : (identity.type == Type::Macro ? "as '" : "for '") + identity.real + "'\n");
    
    return true;
}

void Aliases::removeAllOutOfScopeAliases() {
    for (auto it = _identities.begin(); it != _identities.end(); ++it) {
        if (it->scope > Singleton::shared()->scopeDepth) {
            if (verbose) std::cerr
                << MessageType::Verbose
                << "removed " << "local" << " "
                << (Type::Unknown == it->type ? "alias " : "")
                << (Type::Macro == it->type ? "macro " : "")
                << (Type::Alias == it->type ? "alias " : "")
                << (Type::Function == it->type ? "function alias " : "")
                << (Type::Argument == it->type ? "argument alias " : "")
                << (Type::Variable == it->type ? "variable alias " : "")
                << "'" << it->identifier << "'\n";
            _identities.erase(it);
            removeAllOutOfScopeAliases();
            break;
        }
    }
}

void Aliases::removeAllAliasesOfType(const Type type) {
    for (auto it = _identities.begin(); it != _identities.end(); ++it) {
        if (it->type == type) {
            if (verbose) std::cerr
                << MessageType::Verbose
                << "removed " << "local" << " "
                << (Type::Unknown == it->type ? "alias " : "")
                << (Type::Macro == it->type ? "macro " : "")
                << (Type::Alias == it->type ? "alias " : "")
                << (Type::Function == it->type ? "function alias " : "")
                << (Type::Argument == it->type ? "argument alias " : "")
                << (Type::Variable == it->type ? "variable alias " : "")
                << "'" << it->identifier << "'\n";
            _identities.erase(it);
            removeAllAliasesOfType(type);
            break;
        }
    }
}

static std::string resolveMacroFunction(const std::string &str, const std::string &identifier, const std::string &real) {
    std::string result;
    std::regex re;
    std::smatch match;
    std::string pattern;
    
    re = R"(\b)" + identifier + R"( *\(([^()]*)\))";
    if (!std::regex_search(str, match, re)) {
        return result;
    }
    result = match.str(1);
    
    re = R"([^,]+(?=[^,]*))";
    std::vector<std::string> arguments;
    for (auto it = std::sregex_iterator(result.begin(), result.end(), re); it != std::sregex_iterator(); ++it) {
        arguments.push_back(it->str());
    }
    
    result = real;
    size_t i = 0;
    for (auto it = arguments.begin(); it != arguments.end(); ++it, ++i) {
        pattern = "\\$" + std::to_string(i + 1);
        result = std::regex_replace(result, std::regex(pattern), arguments.at(i));
        
        pattern = "\\$0";
        result = std::regex_replace(result, std::regex(pattern), identifier);
    }
    
    return result;
}

std::string Aliases::resolveAllAliasesInText(const std::string &str) {
    std::string s = str;
    std::regex re;
    std::smatch match;
    std::string namespaces, pattern;
    
    if (s.empty()) return s;
    
    auto strings = preserveStrings(s);
    s = blankOutStrings(s);
    
    for (auto it = _identities.begin(); it != _identities.end(); ++it) {
        if ('`' == it->identifier.at(0) && '`' == it->identifier.at(it->identifier.length() - 1)) {
            pattern = it->identifier;
        } else {
            pattern = R"(\b)" + it->identifier + R"(\b)";
        }
        
        re = pattern;

        if (it->type == Type::Macro) {
            if (!regex_search(s, match, std::regex(R"(\b)" + it->identifier + R"( *\([^()]*\))"))) {
                if (!regex_search(s, re)) continue;
                s = regex_replace(s, re, it->real);
                continue;
            }
                
            while (regex_search(s, match, std::regex(R"(\b)" + it->identifier + R"( *\([^()]*\))"))) {
                std::string result = resolveMacroFunction(match.str(), it->identifier, it->real);
                s.replace(match.position(), match.length(), result);
            }
            continue;
        }
        
        if (!regex_search(s, re)) continue;
        s = regex_replace(s, re, it->real);
    }
    s = restoreStrings(s, strings);
    
    if (s != str) {
        s = resolveAllAliasesInText(s);
    }
    

    return s;
}



void Aliases::remove(const std::string &identifier) {
    for (auto it = _identities.begin(); it != _identities.end(); ++it) {
        if (it->identifier == identifier) {
            if (verbose) std::cerr
                << MessageType::Verbose
                << "removed "
                << (it->scope > 0 ? "local " : "")
                << (Type::Unknown == it->type ? "alias " : "")
                << (Type::Macro == it->type ? "macro " : "")
                << (Type::Alias == it->type ? "alias " : "")
                << (Type::Function == it->type ? "function alias " : "")
                << (Type::Argument == it->type ? "argument alias " : "")
                << (Type::Variable == it->type ? "variable alias " : "")
                << "'" << it->identifier << "'\n";
            
            _identities.erase(it);
            break;
        }
    }
}



bool Aliases::identifierExists(const std::string &identifier) {
    for (auto it = _identities.begin(); it != _identities.end(); ++it) {
        if (it->identifier == identifier) {
            return true;
        }
    }
    
    return false;
}

bool Aliases::realExists(const std::string &real) {
    for (auto it = _identities.begin(); it != _identities.end(); ++it) {
        if (it->real == real) {
            return true;
        }
    }
    
    return false;
}

void Aliases::dumpIdentities() {
    for (auto it = _identities.begin(); it != _identities.end(); ++it) {
        if (verbose) std::cerr << "_identities : " << it->identifier << " = " << it->real << "\n";
    }
}

const Aliases::TIdentity Aliases::getIdentity(const std::string &identifier) {
    TIdentity identity;
    for (auto it = _identities.begin(); it != _identities.end(); ++it) {
        if (it->identifier == identifier) {
            return *it;
        }
    }
    return identity;
}




