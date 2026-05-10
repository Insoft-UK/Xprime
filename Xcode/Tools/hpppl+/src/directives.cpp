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

#include "directives.hpp"
#include "singleton.hpp"
#include "common.hpp"
#include "calc.hpp"

#include <regex>
#include <sstream>
#include <fstream>
#include <cctype>

using hppplplus::Directives;
using hppplplus::Singleton;

static Singleton *_singleton  = Singleton::shared();

std::string Directives::parse(const std::string& str) {
    std::string s;
    std::regex re;
    std::smatch match;
    std::sregex_token_iterator it;
    std::sregex_token_iterator end;
    Aliases::TIdentity  identity;
    filename = std::string("");

    
    
    if (disregard == false) {
        /*
         eg. {$DEFINE NAME}
         Group  0 {$DEFINE NAME}
                1 NAME
         */
        re = std::regex(R"(^ *\{\$DEFINE +([a-z\d_]+)\})", std::regex_constants::icase);
        if (std::regex_search(str, match, re)) {
            identity.identifier = match.str(1);
            identity.real = "1";
            
            identity.scope = 0;
            identity.type = Aliases::Type::CompileTimeSymbol;
            
            identity.real = _singleton->aliases.resolveAllAliasesInText(identity.real);
            identity.real = Calc::evaluateMathExpression(identity.real);
            
            _singleton->aliases.append(identity);
            return "";
        }
 
        /*
         eg. {$UNDEF NAME}
         Group  0 {$UNDEF NAME}
                1 NAME
         */
        re = std::regex(R"(^ *\{\$UNDEF +([a-z\d_]+)\})", std::regex_constants::icase);
        if (std::regex_search(str, match, re)) {
            _singleton->aliases.remove(match[1].str());
            return "";
        }

        /*
         eg. {$IFDEF NAME}
         Group  0 {$IFDEF NAME}
                1 NAME
         */
        re = std::regex(R"(^ *\{\$IFDEF +([a-z\d_]+) *\} *$)", std::regex_constants::icase);
        if (std::regex_search(str, match, re)) {
            identity.identifier = match[1].str();
            disregard = !_singleton->aliases.identifierExists(identity.identifier);
            return "";
        }
        
        /*
         eg. {$IFNDEF NAME}
         Group  0 {$IFNDEF NAME}
                1 NAME
         */
        re = std::regex(R"(^ *\{\$IFNDEF +([a-z\d_]+) *\} *$)", std::regex_constants::icase);
        if (std::regex_search(str, match, re)) {
            identity.identifier = match[1].str();
            disregard = _singleton->aliases.identifierExists(identity.identifier);
            return "";
        }
    }
    
    if (regex_search(str, std::regex(R"(^ *\{\$ELSE\} *$)", std::regex_constants::icase))) {
        disregard = !disregard;
        return "";
    }
    
    if (regex_search(str, std::regex(R"(^ *\{\$ENDIF\} *$)", std::regex_constants::icase))) {
        disregard = false;
        return "";
    }

    return str;
}

bool Directives::isIncludeDirective(const std::string& str) {
    static const std::regex re(
        R"(\{\$(?:INCLUDE|I) +[\w \-_~,;\[\]\(\).']+ *\})",
        std::regex_constants::icase
    );

    return std::regex_search(str, re);
}

std::filesystem::path Directives::extractIncludeDirective(const std::string& str) {
    std::smatch match;
    std::filesystem::path path;
    
    auto re = std::regex(
        R"(\{\$(?:INCLUDE|I) +([\w \-_~,;\[\]\(\).']+) *\})",
        std::regex_constants::icase
    );

    if (std::regex_search(str, match, re)) {
        path = std::filesystem::path(match.str(1));
    }
    return path;
}


