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

#include "unary.hpp"

static bool isUnaryTarget(char c) {
    return std::isdigit((unsigned char)c) ||
           std::isalpha((unsigned char)c) ||
           c == '.';
}

std::string fixUnaryMinus(const std::string& s) {
    std::string out;
    out.reserve(s.size());

    size_t i = 0;
    while (i < s.size()) {

        if ((s[i] == '-' || s[i] == '+' || s[i] == '*' || s[i] == '/') && i + 1 < s.size() && s[i + 1] == '-') {
            size_t j = i + 2;

            // Skip spaces after the second '-'
            while (j < s.size() && std::isspace((unsigned char)s[j]))
                j++;

            if (j < s.size() && isUnaryTarget(s[j])) {
                out.push_back(s[i]);
                out.push_back(' ');
                out.push_back('-');
                // Continue from character after second '-'
                i = i + 2;
                continue;
            }
        }

        if (s[i] == '-') {
            size_t j = i + 1;

            // Skip spaces after '-'
            while (j < s.size() && std::isspace((unsigned char)s[j]))
                j++;

            // If minus followed by unary target => remove spaces
            if (j < s.size() && isUnaryTarget(s[j])) {
                out.push_back('-');
                i = j;
                continue;
            }
        }

        // Normal character
        out.push_back(s[i]);
        i++;
    }
    return out;
}
