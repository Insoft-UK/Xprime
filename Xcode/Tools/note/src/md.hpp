// The MIT License (MIT)
//
// Copyright (c) 2026 Insoft.
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

#pragma once

#include <cstdlib>
#include <fstream>
#include <string>
#include <vector>
#include <iostream>
#include <filesystem>
#include <cctype>

namespace md {
    enum class Alignment {
        Left,
        Center,
        Right
    };

    struct Attributes {
        std::string foreground;
        std::string background;
        int fontSize = 14;          // 0 = inherit
        Alignment align = Alignment::Left;  // default left
    };

    enum class BulletType {
        None,
        Dash
    };
    
    union Style {
        unsigned flags;
        struct {
            unsigned Bold : 1;
            unsigned Italic : 1;
            unsigned Underline : 1;
            unsigned Strikethrough : 1;
            unsigned Highlight : 1;
        };
    };

    struct Token {
        Style style;
        Attributes attr;
        BulletType bullet;
        int bulletLevel = 0; // 0 = no bullet, 1 = main, 2 = sub, etc.
        std::string text;
        Alignment align = Alignment::Left; // optional override
    };
    
    std::vector<Token> parseMarkdown(const std::string& input);
    void printTokens(const std::vector<Token>& tokens);
}


