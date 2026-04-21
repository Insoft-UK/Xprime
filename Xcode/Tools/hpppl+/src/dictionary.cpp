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

#include "dictionary.hpp"

using hppplplus::Dictionary;

bool Dictionary::isDictionaryDefinition(const std::string &str) {
    return regex_search(str, std::regex(R"(\bdictionary +([\w[\](),:=#\- ]+) *@?\b([A-Za-z_]\w*(?:::[A-Za-z_]\w*)*);)", std::regex_constants::icase));
}

std::string Dictionary::removeDictionaryDefinition(const std::string& str) {
    return std::regex_replace(str, std::regex(R"(\bdictionary +([\w[\](),:=#\- ]+) *@?\b([A-Za-z_]\w*(?:::[A-Za-z_]\w*)*);)", std::regex_constants::icase), "");
}

bool Dictionary::proccessDictionaryDefinition(const std::string &str) {
    std::regex re;
    std::smatch match;
    std::string code;
    
    code = str;
    
    Aliases::TIdentity identity;
    identity.scope = Singleton::shared()->scopeDepth;
    identity.type = Aliases::Type::Alias;
    
    std::string pattern;
    
    pattern = R"(\bdictionary +([^\r\n\t\f\v@]+) +(@)?\b([a-z_]\w*(?:::[a-z_]\w*)*);)";
    
    if (regex_search(code, match, std::regex(pattern, std::regex_constants::icase))) {
        
        identity.scope = match[2].matched ? 0 : Singleton::shared()->scopeDepth;

        std::string s = match[1].str();
        
        pattern = R"(([a-z_]\w*)([^\r\n\t\f\v ,:=]+)?(?: *:= *([^\r\n\t\f\v ,]+))?)";
        re = std::regex(pattern, std::regex_constants::icase);
        for (auto it = std::sregex_iterator(s.begin(), s.end(), re); it != std::sregex_iterator(); it++) {
            identity.identifier = match[3].str() + "." + it->str(1);

            std::string alias = match.str(3), name = it->str(1), sufix = it->str(2), value = it->str(3);
            identity.real = value;
            
            if (!sufix.empty()) {
                // List
                identity.real = alias + sufix;
            }
            if (!value.empty()) {
                identity.real = it->str(3);
            }
            
            if (sufix.empty() && value.empty()) {
                identity.real = alias;
            }
            
            Singleton::shared()->aliases.append(identity);
        }
        return true;
    }
    return false;
}
