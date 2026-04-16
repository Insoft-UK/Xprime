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

#ifndef regexp_hpp
#define regexp_hpp

#include <iostream>
#include <vector>
#include <regex>
#include <filesystem>

namespace pplplus {
    class Regexp {
    public:
        bool verbose = false;
        
        typedef struct TRegexp {
            std::string pattern;
            std::string replacement;
            bool insensitive;
            size_t scopeLevel;
            std::string compare;
            
            long line;              // line that definition accoured;
            std::filesystem::path path;   // path and filename that definition accoured
        } TRegexp;
        
        bool parse(const std::string &str);
        void removeAllOutOfScopeRegexps(void);
        void resolveAllRegularExpression(std::string &str, const size_t index = -1);
        
        
    private:
        std::vector<TRegexp> _regexps;
        bool regularExpressionExists(const std::string &pattern, const std::string &compare);
    };
}

#endif /* regexp_hpp */
