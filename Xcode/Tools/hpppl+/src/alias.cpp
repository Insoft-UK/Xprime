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

#include "alias.hpp"

#include <sstream>
#include <regex>

using hppplplus::Alias;


std::string Alias::parse(const std::string &str) {
    std::string s;
    std::regex re;
    std::smatch matches;
    std::string output = str;
    
    re = std::regex(R"(\balias\b *(@)?([a-z_]\w*(?:::[a-z]\w*)*) *:= *([^\r\n\t\f\v ]+) *;)", std::regex_constants::icase);
    while (regex_search(output, matches, re)) {
        Aliases::TIdentity identity;
        identity.identifier = matches.str(2);
        identity.real = matches.str(3);
        identity.type = Aliases::Type::Alias;
        identity.scope = matches[1].matched ? 0 : Singleton::shared()->scopeDepth;
        
        Singleton::shared()->aliases.append(identity);
        output.replace(matches.position(), matches.length(), "");
    }
    
    
    return output;
}
