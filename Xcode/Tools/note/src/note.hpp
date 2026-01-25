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

#include <iostream>
#include <string>
#include <vector>
#include <cctype>

namespace note {
    enum FontSize : uint16_t {
        FONT10 = 1, FONT12 = 2, SMALL = 2, FONT14 = 3, MEDIUM = 3, FONT16 = 4, LARGE = 4, FONT18 = 5, FONT20 = 6, FONT22 = 7
    };
    
    enum Align {
        LEFT = 0, CENTER = 1, RIGHT = 2
    };
    
    typedef uint16_t Color;
    
    struct Format {
        FontSize fontSize = MEDIUM;
        Color foreground = 0xFFFF;
        Color background = 0xFFFF;
        Align align = LEFT;
    };
    
    struct Style {
        bool bold = false;
        bool italic = false;
        bool underline = false;
        bool strikethrough = false;
    };
    
    struct TextRun {
        std::string text;
        Format format;
        Style style;
        int level = 0;
    };
    
    std::vector<TextRun> parseNote(const std::string& input);
    std::string ntf(const std::string md);
    void printRuns(const std::vector<TextRun>& runs);
}
