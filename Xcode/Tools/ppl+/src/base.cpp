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

#include "base.hpp"

#include <regex>

using pplplus::Base;

std::string Base::parse(const std::string &str) {
    std::smatch matches;
    std::string output = str;
    std::regex re(R"(#(-)?(\d+)([bodh])\((0x[[:xdigit:]]+|[[:xdigit:]]+(?:\.[[:xdigit:]]+)?|0[0-7]+|0b[0-1]+)\))");
    
    if (regex_search(output, matches, re)) {
        std::string s;
        s = "#" + matches.str(4) + ":" + matches.str(1) + matches.str(2) + matches.str(3);
        output.replace(matches.position(), matches.length(), s);
    }
    return output;
}
