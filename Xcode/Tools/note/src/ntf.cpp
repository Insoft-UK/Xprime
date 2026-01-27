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

#include "ntf.hpp"

#include <regex>
#include <iomanip>

using namespace ntf;

static Format format{};
static Style style{};
static int level = 0;

static uint8_t hexByte(const std::string& s, size_t pos) {
    return static_cast<uint8_t>(std::stoi(s.substr(pos, 2), nullptr, 16));
}

static uint16_t rgb888ToArgb1555(uint8_t r, uint8_t g, uint8_t b, bool opaque = true)
{
    uint16_t r5 = (r * 31 + 127) / 255;
    uint16_t g5 = (g * 31 + 127) / 255;
    uint16_t b5 = (b * 31 + 127) / 255;

    uint16_t a1 = opaque ? 1 : 0;

    return (a1 << 15) | (r5 << 10) | (g5 << 5) | b5;
}

uint16_t rgba8888ToArgb1555(
    uint8_t r,
    uint8_t g,
    uint8_t b,
    uint8_t a
) {
    uint16_t r5 = (r * 31 + 127) / 255;
    uint16_t g5 = (g * 31 + 127) / 255;
    uint16_t b5 = (b * 31 + 127) / 255;

    uint16_t a1 = (a >= 128) ? 1 : 0;

    return (a1 << 15) | (r5 << 10) | (g5 << 5) | b5;
}

static Color parseHexColor(const std::string& hex) {
    Color c = 0xFFFF;
    
    if (hex.size() == 4) {
        c = static_cast<Color>(hexByte(hex, 0)) << 8 | hexByte(hex, 2);
    }
    
    if (hex.size() == 6) {
        c = rgb888ToArgb1555(hexByte(hex, 0), hexByte(hex, 2), hexByte(hex, 4));
    }
    
    if (hex.size() == 8) {
        c = rgba8888ToArgb1555(hexByte(hex, 0), hexByte(hex, 2), hexByte(hex, 4), hexByte(hex, 6));
    }
    
    return c;
}

void ntf::reset(void) {
    format = {};
    style = {};
    level = 0;
}

std::vector<TextRun> ntf::parseNTF(const std::string& input) {
    std::vector<TextRun> runs;
    std::string buffer;

    auto flush = [&]() {
        if (!buffer.empty()) {
            runs.push_back({ buffer, format, style, level });
            buffer.clear();
        }
    };

    for (size_t i = 0; i < input.size(); ) {
        if (input[i] == '\\') {
            // Flush text before control word
            flush();
            i++;

            // Read control word name
            std::string cmd;
            while (i < input.size() && std::isalpha(input[i])) {
                cmd += input[i++];
            }

            
            // Hex color value (for fg#XXXX / bg#XXXX)
            std::string hex;
            if (input[i] == '#') {
                i++;
                while (i < input.size() && std::isxdigit(input[i])) {
                    hex += input[i++];
                }
            }
            
            // Read optional numeric value (e.g. 0 or 1)
            int value = -1;
            if (i < input.size() && std::isdigit(input[i])) {
                value = 0;
                while (i < input.size() && std::isdigit(input[i])) {
                    value = value * 10 + (input[i++] - '0');
                }
            }

            // Apply command
            if (cmd == "b") {
                if (value != -1) style.bold = (value != 0); else style.bold = !style.bold;
            }
            if (cmd == "i") {
                if (value != -1) style.italic = (value != 0); else style.italic = !style.italic;
            }
            if (cmd == "u") {
                if (value != -1) style.underline = (value != 0); else style.underline = !style.underline;
            }
            if (cmd == "s") {
                if (value != -1) style.strikethrough = (value != 0); else style.strikethrough = !style.strikethrough;
            }
            if (cmd == "fs") {
                if (value != -1) format.fontSize = static_cast<FontSize>(value); else format.fontSize = MEDIUM;
            }
            if (cmd == "fg" && !hex.empty()) {
                format.foreground = parseHexColor(hex);
            }
            if (cmd == "bg" && !hex.empty()) {
                if (!hex.empty()) format.background = parseHexColor(hex); else format.background = 0xFFFF;
            }
            if (cmd == "a") {
                if (value != -1) format.align = static_cast<Align>(value); else format.align = static_cast<Align>((static_cast<int>(format.align) + 1) % 3);
            }
            if (cmd == "l") {
                if (value != -1) level = value; else level = (level + 1) % 4;
            }

            // Skip optional space after control word
            if (i < input.size() && input[i] == ' ')
                i++;
        } else {
            buffer += input[i++];
        }
    }

    flush();
    return runs;
}

std::string ntf::markdownToNTF(const std::string md) {
    std::string ntf = md;
    
    std::regex re;
    
    re = R"(#{4} )";
    ntf = std::regex_replace(ntf, re, R"(\fs4 \b1 )");
    
    re = R"(#{3} )";
    ntf = std::regex_replace(ntf, re, R"(\fs5 \b1 )");
    
    re = R"(#{2} )";
    ntf = std::regex_replace(ntf, re, R"(\fs6 \b1 )");
    
    re = R"(#{1} )";
    ntf = std::regex_replace(ntf, re, R"(\fs7 \b1 )");
    
    re = R"(\*{2}(.*)\*{2})";
    ntf = std::regex_replace(ntf, re, R"(\b1 $1)");
    
    re = R"(\*(.*)\*)";
    ntf = std::regex_replace(ntf, re, R"(\i1 $1)");
    
    re = R"(~~(.*)~~)";
    ntf = std::regex_replace(ntf, re, R"(\s1 $1)");
    
    re = R"(==(.*)==)";
    ntf = std::regex_replace(ntf, re, R"(\bg#7F40 $1)");
    
    re = R"( {4}- )";
    ntf = std::regex_replace(ntf, re, R"(\l3 )");
    
    re = R"( {2}- )";
    ntf = std::regex_replace(ntf, re, R"(\l2 )");
    
    re = R"(- )";
    ntf = std::regex_replace(ntf, re, R"(\l1 )");
    
    return ntf;
}


void ntf::printRuns(const std::vector<TextRun>& runs) {
    for (const auto& r : runs) {
        std::cerr
        << (r.style.bold ? "B" : "-") << (r.style.italic ? "I" : "-") << (r.style.underline ? "U" : "-") << (r.style.strikethrough ? "S" : "-")
        << " pt:" << (static_cast<int>(r.format.fontSize) + 4) * 2
        << " bg:#" << std::uppercase << std::setw(4) << std::hex << r.format.background << " fg:#" << r.format.foreground
        << std::dec
        << " " << (r.format.align == 0 ? "L" : (r.format.align == 1 ? "C" : "R"))
        << " " << (r.level == 0 ? " " : (r.level == 1 ? "●" : (r.level == 2 ? "○" : "▶")))
        << " \"" << r.text << "\" "
        << "\n";
    }
}
