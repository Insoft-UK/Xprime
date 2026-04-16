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

#include "code_stack.hpp"
#include "common.hpp"

#include <regex>

using pplplus::CodeStack;

std::string CodeStack::parse(const std::string& str) {
    std::regex re;
    std::smatch match;
    std::string::const_iterator it;
    std::string output = str;
    
    re = R"(__PUSH__`([^`]*)`|__POP__|__TOP__)";
    it = output.cbegin();
    while (std::regex_search(it, output.cend(), match, re)) {
        if (match.str() == "__POP__") {
            // Replace the match with the last value from the stack
            it = output.erase(it + match.position(), it + match.position() +  match.length());
            if (!_stack.empty()) {
                it = output.insert(it, _stack.top().begin(), _stack.top().end());
                _stack.pop();
            }
            continue;
        }
        
        if (match.str() == "__TOP__") {
            // Replace the match with the last value from the stack
            it = output.erase(it + match.position(), it + match.position() +  match.length());
            if (!_stack.empty()) {
                it = output.insert(it, _stack.top().begin(), _stack.top().end());
            }
            continue;
        }
        
        // __PUSH__``
        _stack.push(match.str(1));
        
        // Erase only the matched portion and update the iterator correctly
        it = output.erase(it + match.position(), it + match.position() + match.length());
    }
    
    return output;
}
