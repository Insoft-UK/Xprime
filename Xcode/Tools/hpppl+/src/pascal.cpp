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

#include "pascal.hpp"

#include <iostream>
#include <regex>
#include <string>
#include <sstream>
#include <unordered_set>

namespace hppplplus::pascal {
    static std::string lowercased(const std::string& s) {
        std::string result = s;
        std::transform(result.begin(), result.end(), result.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        return result;
    }

    static std::string replaceWords(const std::string& input, const std::vector<std::string>& words, const std::string& replacement) {
        // Create lowercase word set
        std::unordered_set<std::string> wordSet;
        for (const auto& w : words) {
            wordSet.insert(lowercased(w));
        }

        std::string result;
        size_t i = 0;
        
        while (i < input.size()) {
            if (!isalpha(static_cast<unsigned char>(input[i])) && input[i] != '_') {
                result += input[i];
                ++i;
                continue;
            }
            size_t start = i;
            
            while (i < input.size() && (isalpha(static_cast<unsigned char>(input[i])) || input[i] == '_')) {
                ++i;
            }
            
            std::string word = input.substr(start, i - start);
            std::string lowercase = lowercased(word);
            
            if (wordSet.count(lowercase)) {
                result += replacement;
                continue;
            }
            
            result += word;
        }
        
        return result;
    }
    
    static std::string trim(const std::string& s)
    {
        size_t a = s.find_first_not_of(" \t\r\n");
        size_t b = s.find_last_not_of(" \t\r\n");
        if (a == std::string::npos) return "";
        return s.substr(a, b - a + 1);
    }

    static std::vector<std::string> split(const std::string& s, char c)
    {
        std::vector<std::string> r;
        std::stringstream ss(s);
        std::string item;

        while (std::getline(ss, item, c))
            r.push_back(trim(item));

        return r;
    }

    std::vector<std::string> getInterfaceRoutines(const std::string& source)
    {
        std::vector<std::string> result;

        std::regex interfaceRe(R"(\binterface\b([\s\S]*?)\bimplementation\b)", std::regex::icase);
        std::smatch interfaceMatch;

        if (!std::regex_search(source, interfaceMatch, interfaceRe))
            return result;

        std::string interfaceBlock = interfaceMatch[1].str();

        std::regex routineRe(R"(\b(?:procedure|function)\s+([A-Za-z_][A-Za-z0-9_]*)\b)", std::regex::icase);

        auto it = std::sregex_iterator(interfaceBlock.begin(), interfaceBlock.end(), routineRe);
        auto end = std::sregex_iterator();

        for (; it != end; ++it)
            result.push_back((*it)[1].str());

        return result;
    }

    static std::string prefixExportToImplementation(
        const std::string& source,
        const std::vector<std::string>& routines)
    {
        std::string result = source;

        // find implementation section
        std::regex implRe(R"(\bimplementation\b([\s\S]*))", std::regex::icase);
        std::smatch implMatch;

        if (!std::regex_search(result, implMatch, implRe))
            return result;

        std::string implBlock = implMatch[1].str();
        size_t implPos = implMatch.position(1);

        for (const auto& name : routines)
        {
            std::regex routineRe(
                "\\b(procedure|function)\\s+" + name + "\\b",
                std::regex::icase);

            implBlock = std::regex_replace(
                implBlock,
                routineRe,
                "EXPORT $1 " + name);
        }

        result.replace(implPos, implMatch.length(1), implBlock);

        return result;
    }

    static bool startsWithWord(const std::string& s, size_t pos, const std::string& word)
    {
        if (pos + word.size() > s.size())
            return false;

        for (size_t i = 0; i < word.size(); i++)
            if (tolower(s[pos + i]) != tolower(word[i]))
                return false;

        if (pos > 0 && std::isalnum((unsigned char)s[pos - 1]))
            return false;

        if (pos + word.size() < s.size() && std::isalnum((unsigned char)s[pos + word.size()]))
            return false;

        return true;
    }

    static bool isDecl(const std::string& s, size_t pos)
    {
        static const char* words[] = { "label","const","type","var","threadvar" };

        for (auto w : words)
            if (startsWithWord(s, pos, w))
                return true;

        return false;
    }

    static std::string moveDeclarationsAfterBegin(const std::string& input)
    {
        std::string result = input;

        // Matches each function or procedure
        std::regex funcProcBlock(
            R"((function|procedure)\s+[A-Za-z_]\w*\s*(\([^)]*\))?\s*:\s*\w+[\s\S]*?\bbegin\b[\s\S]*?\bend\b;?)",
            std::regex::icase
        );

        std::smatch match;
        std::string output;
        std::string temp = result;

        while (std::regex_search(temp, match, funcProcBlock))
        {
            // Append everything before this match
            output += temp.substr(0, match.position(0));

            std::string block = match.str(0);

            // Search for var block inside this function/procedure
            std::regex varRegex(R"(\bvar\b([\s\S]*?)\bbegin\b)", std::regex::icase);
            std::smatch varMatch;

            if (std::regex_search(block, varMatch, varRegex))
            {
                std::string varContent = varMatch.str(1); // keep contents after 'var' before 'begin'
                // Remove original var block
                block = std::regex_replace(block, varRegex, "begin");
                // Insert var content after begin
                block = std::regex_replace(block, std::regex(R"(begin)"), "begin\nvar" + varContent + "\n", std::regex_constants::format_first_only);
            }

            output += block;

            // Move past this match
            temp = temp.substr(match.position(0) + match.length(0));
        }

        // Append any remaining text
        output += temp;

        return output;
    }

    static std::string convertPascalCase(const std::string& src)
    {
        std::stringstream in(src);
        std::stringstream out;

        std::string line;
        std::string expr;
        bool inCase = false;

        while (getline(in, line))
        {
            std::string t = trim(line);

            if (!inCase)
            {
                size_t p = t.find("case ");
                if (p != std::string::npos && t.find(" of") != std::string::npos)
                {
                    expr = trim(t.substr(5, t.find("of") - 5));
                    out << "CASE\n";
                    inCase = true;
                }
                else
                    out << line << "\n";

                continue;
            }

            if (t == "end;" || t == "end")
            {
                out << "END;\n";
                inCase = false;
                continue;
            }

            if (t.rfind("else",0)==0)
            {
                std::string stmt = trim(t.substr(4));

                out << "DEFAULT\n";
                inCase = false;
                if (!stmt.empty())
                    out << stmt << "\n";

                continue;
            }

            size_t colon = t.find(':');
            if (colon == std::string::npos)
                continue;

            std::string selector = trim(t.substr(0, colon));
            std::string statement = trim(t.substr(colon+1));

            std::string cond;

            if (selector.find("..") != std::string::npos)
            {
                auto parts = split(selector,'.');
                cond = expr + " >= " + parts[0] + " AND " +
                       expr + " <= " + parts[2];
            }
            else if (selector.find(',') != std::string::npos)
            {
                auto vals = split(selector,',');

                for (size_t i=0;i<vals.size();i++)
                {
                    if (i) cond += " OR ";
                    cond += expr + " == " + vals[i];
                }
            }
            else
            {
                cond = expr + " == " + selector;
            }

            out << "IF " << cond << " THEN\n";
            out << statement << "\n";
            out << "END;\n";
        }

        return out.str();
    }

    static std::string removePascalTypes(const std::string& input)
    {
        std::regex re(R"(:\s*[a-z]+;)", std::regex::icase);
        return std::regex_replace(input, re, ";");
    }
    
    static std::string convertFunctions(const std::string& input, bool implementation = false)
    {
        std::string output;
        
        output = std::regex_replace(
            input,
            std::regex(R"(\bfunction\s+([a-z_]\w*)\s*(\([^)]*\))?\s*:\s*\w+\s*;)", std::regex::icase),
            implementation ? "$1$2" : "$1$2;"
        );
        
        return output;
    }
    
    static std::string convertProcedure(const std::string& input, bool implementation = false)
    {
        std::string output;
        
        output = std::regex_replace(
            input,
            std::regex(R"(\bprocedure\s+([a-z_]\w*)\s*(\([^)]*\))?\s*;)", std::regex::icase),
            implementation ? "$1$2" : "$1$2;"
        );
        
        return output;
    }
    
    static std::string addEmptyParams(const std::string& input)
    {
        std::string result = input;

        // function without parameters
        std::regex funcRegex(
            R"(\bfunction\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*)",
            std::regex::icase
        );

        // procedure without parameters
        std::regex procRegex(
            R"(\bprocedure\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?=;|\bbegin\b))",
            std::regex::icase
        );

        result = std::regex_replace(result, funcRegex, "function $1(): ");
        result = std::regex_replace(result, procRegex, "procedure $1()");

        return result;
    }
    
    static std::string convertPascalToPPL(const std::string& input)
    {
        size_t implPos = input.find("implementation");

        std::string iface = input.substr(0, implPos);
        std::string impl  = (implPos == std::string::npos) ? "" : input.substr(implPos);

        // ---- Interface ----
        iface = addEmptyParams(iface);
        iface = convertFunctions(iface);
        iface = convertProcedure(iface);

        // ---- Implementation ----
        impl = addEmptyParams(impl);
        impl = convertFunctions(impl, true);
        impl = convertProcedure(impl, true);

        return iface + impl;
    }
    

    static std::string removeInnerBegins(const std::string& input)
    {
        std::string out;

        bool inFunc = false;
        int beginCount = 0;

        for (size_t i = 0; i < input.size(); )
        {
            if (!inFunc &&
                (startsWithWord(input, i, "function") ||
                 startsWithWord(input, i, "procedure")))
            {
                inFunc = true;
            }

            if (inFunc && startsWithWord(input, i, "begin"))
            {
                beginCount++;

                if (beginCount == 1)
                    out += "begin";   // keep first begin

                i += 5;
                continue;
            }

            if (inFunc && startsWithWord(input, i, "end"))
            {
                beginCount--;

                out += "end";
                i += 3;

                if (beginCount == 0)
                    inFunc = false;

                continue;
            }

            out += input[i];
            i++;
        }

        return out;
    }
    
    static std::string convertProgramHeader(const std::string& input)
    {
        std::stringstream in(input);
        std::vector<std::string> lines;

        std::string line;
        std::string programName;

        while (std::getline(in, line))
        {
            std::string t = line;
            t.erase(0, t.find_first_not_of(" \t"));

            std::string lower = lowercased(t);

            if (lower.rfind("program ", 0) == 0)
            {
                size_t start = 8;
                size_t end = t.find(';', start);
                if (end != std::string::npos)
                    programName = t.substr(start, end - start);

                continue; // remove PROGRAM line
            }

            lines.push_back(line);
        }

        if (programName.empty())
            return input;

        // Find END.
        int endLine = -1;
        for (int i = (int)lines.size() - 1; i >= 0; --i)
        {
            std::string t = lines[i];
            t.erase(0, t.find_first_not_of(" \t"));
            std::string lower = lowercased(t);

            if (lower.rfind("end.", 0) == 0)
            {
                endLine = i;
                break;
            }
        }

        if (endLine == -1)
            return input;

        // Find matching BEGIN before END.
        int beginLine = -1;
        for (int i = endLine; i >= 0; --i)
        {
            std::string t = lines[i];
            t.erase(0, t.find_first_not_of(" \t"));
            std::string lower = lowercased(t);

            if (lower.rfind("begin", 0) == 0)
            {
                beginLine = i;
                break;
            }
        }

        if (beginLine != -1)
            lines.insert(lines.begin() + beginLine, "EXPORT" + programName + "()");

        std::stringstream out;
        for (auto& l : lines)
            out << l << "\n";

        return out.str();
    }
    
    std::string convertPascalSyntax(const std::string &code) {
        std::string s;
        std::regex re;
        std::smatch matches;
        std::string output = code;
        
        output = convertPascalCase(output);
        output = convertProgramHeader(output);
        output = removeInnerBegins(output);
        
        output = moveDeclarationsAfterBegin(output);
        auto routines = getInterfaceRoutines(output);
        output = prefixExportToImplementation(output, routines);
        output = convertPascalToPPL(output);
        output = removePascalTypes(output);
        output = std::regex_replace(output, std::regex(R"(\bend.)", std::regex::icase), "end;");
        output = replaceWords(output, {"var"}, "LOCAL");
        output = capitalizeWords(output, {
            "interface", "implementation", "procedure"
        });
        output = replaceWords(output, {"INTERFACE", "IMPLEMENTATION", "PROCEDURE"}, "");
        output = capitalizeWords(output, {
            "end", "return", "kill", "if", "then", "else", "xor", "or", "and", "not",
            "case", "default", "iferr", "ifte", "for", "from", "step", "downto", "to", "do",
            "while", "repeat", "until", "break", "continue", "const", "local",
            "eval", "freeze", "view", "begin", "export"
        });
        output = std::regex_replace(output, std::regex(R"(\{.*\})", std::regex::icase), "");
        output = std::regex_replace(output, std::regex(R"(\bwriteLn\b)", std::regex::icase), "PRINT");
        output = std::regex_replace(output, std::regex("\\s*\n", std::regex::icase), "\n");
        output = regex_replace(output, std::regex(R"(: *(integer|real|char|string|boolean|arrays))", std::regex::icase), "");
        
        output = reformat::prgm(output);
        return output;
    }
}
