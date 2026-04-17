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

#include "preprocessor.hpp"
#include "singleton.hpp"
#include "common.hpp"
#include "calc.hpp"

#include <regex>
#include <sstream>
#include <fstream>
#include <cctype>

using hppplplus::Preprocessor;
using hppplplus::Singleton;

static Singleton *_singleton  = Singleton::shared();

std::string Preprocessor::parse(const std::string& str) {
    std::string s;
    std::regex re;
    std::smatch match;
    std::sregex_token_iterator it;
    std::sregex_token_iterator end;
    Aliases::TIdentity  identity;
    filename = std::string("");

    
    
    if (disregard == false) {
        /*
         eg. #define NAME(a,b,c) c := a+b
         Group  0 #define NAME(a,b,c) c := a+b
                1 NAME
                2 a,b,c
                3 c := a+b
         */
        re = R"(^ *#define +([A-Za-z_]\w*)\b(.*))";
        if (std::regex_search(str, match, re)) {
            identity.identifier = match.str(1);
            identity.real = match.str(2);
            
            identity.scope = 0;
            identity.type = Aliases::Type::Macro;
            
            identity.real = _singleton->aliases.resolveAllAliasesInText(identity.real);
            identity.real = Calc::evaluateMathExpression(identity.real);
            
            _singleton->aliases.append(identity);
            return "";
        }
 
        /*
         eg. #undef NAME
         Group  0 #undef NAME
                1 NAME
         */
        re = R"(^ *#undef +([A-Za-z_][\w]*) *$)";
        if (std::regex_search(str, match, re)) {
            _singleton->aliases.remove(match[1].str());
            return "";
        }

        /*
         eg. #ifdef NAME
         Group  0 #ifdef NAME
                1 NAME
         */
        re = R"(^ *#ifdef +([A-Za-z_]\w*) *$)";
        if (std::regex_search(str, match, re)) {
            identity.identifier = match[1].str();
            disregard = !_singleton->aliases.identifierExists(identity.identifier);
            return "";
        }
        
        /*
         eg. #ifndef NAME
         Group  0 #ifndef NAME
                1 NAME
         */
        re = R"(^\ *#ifndef +([A-Za-z_]\w*) *$)";
        if (std::regex_search(str, match, re)) {
            identity.identifier = match[1].str();
            disregard = _singleton->aliases.identifierExists(identity.identifier);
            return "";
        }
        
        
        re = R"(^ *#if +([A-Za-z_]\w*) *(==|!=|>=|<=|>|<) *(.+)$)";
        if (std::regex_search(str, match, re)) {
            identity = _singleton->aliases.getIdentity(match[1].str());
            if (identity.identifier.empty()) return "";
            std::string op = match[2].str();
            std::string real = match[3].str();
            
            disregard = true;
            if (op == "==" && identity.real == real) disregard = false;
            if (op == "!=" && identity.real != real) disregard = false;
            if (op == ">=" && op >= identity.real) disregard = false;
            if (op == "<=" && op <= identity.real) disregard = false;
            if (op == ">" && op >= identity.real) disregard = false;
            if (op == "<" && op <= identity.real) disregard = false;
            
            return "";
        }
    }
    
    if (regex_search(str, std::regex(R"(^ *#else\b *((\/\/.*)|)$)"))) {
        disregard = !disregard;
        return "";
    }
    
    if (regex_search(str, std::regex(R"(^ *#(end|endif)\b)"))) {
        disregard = false;
        return "";
    }
    
    if (regex_search(str, std::regex(R"(^ *#[a-z]+\b)", std::regex_constants::icase))) {
        return "";
    }

    return str;
}


