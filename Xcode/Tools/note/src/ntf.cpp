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
#include <sstream>

using namespace ntf;

static std::vector<Color> colortbl;

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

    uint16_t a1 = opaque ? 0 : 1;

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

static Color parseHexColor(const std::string& hex)
{
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

static void parseColorTbl(const std::string& input)
{
    std::regex re;
    std::smatch match;
    
    re = R"(\{\\colortbl *;([\\a-z\d\s ;]*)\})";

    if (!std::regex_search(input, match, re)) return;
    
    auto s = match.str(1);
    
    re = R"((?:\\red(\d+) *\\green(\d+) *\\blue(\d+)))";
    for (auto it = std::sregex_iterator(s.begin(), s.end(), re); it != std::sregex_iterator(); ++it) {
        auto color = rgb888ToArgb1555(
                                      std::stoi(it->str(1)), // Red
                                      std::stoi(it->str(2)), // Green
                                      std::stoi(it->str(3))  // Blue
                                      );
        
        colortbl.push_back(color);
    }
}

static void rewriteFontSizes(std::string& rtf)
{
    for (size_t i = 0; i + 3 < rtf.size(); ++i) {
        // Look for "\fs"
        if (rtf[i] == '\\' && rtf[i + 1] == 'f' && rtf[i + 2] == 's') {

            size_t j = i + 3;
            if (j >= rtf.size() || !std::isdigit(rtf[j]))
                continue;

            // Parse N
            int value = 0;
            size_t start = j;
            while (j < rtf.size() && std::isdigit(rtf[j])) {
                value = value * 10 + (rtf[j] - '0');
                ++j;
            }

            // Transform N → N/4 - 4
            int newValue = value / 4 - 4;
            if (newValue < 0)
                newValue = 0;

            // Replace old number with new one
            rtf.replace(start, j - start, std::to_string(newValue));

            // Adjust index to continue safely
            i = start + std::to_string(newValue).size() - 1;
        }
    }
}

static void clearColorTable(bool freeMemory = false)
{
    colortbl.clear();
    if (freeMemory)
        colortbl.shrink_to_fit();
}

static FontSize fontSize(const int value)
{
    if (value == -1) return FONT14;
    if (value >= 0 && value <= 7) return static_cast<FontSize>(value);
    if (value <= 22) return static_cast<FontSize>((value & ~1) / 2 - 4);
    return static_cast<FontSize>((value & ~1) / 4 - 4);
}

static Color color(const int value, const std::string& hex)
{
    if (hex.empty()) {
        switch (value) {
            case -1:
            case 0:
                return 0xFFFF;
                
            default:
                return colortbl[value - 1];
        }
    } else {
        return parseHexColor(hex);
    }
}

void ntf::reset(void)
{
    format = {};
    style = {};
    level = 0;
}

std::vector<TextRun> ntf::parseNTF(const std::string& input)
{
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
                style.bold = value != 0;
            }
            if (cmd == "i") {
                style.italic = value != 0;
            }
            if (cmd == "ul") {
                style.underline = value != 0;
            }
            if (cmd == "strike") {
                style.strikethrough = value != 0;
            }
            if (cmd == "fs") {
                format.fontSize = fontSize(value);
            }
            if (cmd == "fg") {
                format.foreground = color(value, hex);
            }
            if (cmd == "bg") {
                format.background = color(value, hex);
            }
            if (cmd == "ql") {
                format.align = LEFT;
            }
            if (cmd == "qc") {
                format.align = CENTER;
            }
            if (cmd == "qr") {
                format.align = RIGHT;
            }
            if (cmd == "li" && value != -1) {
                level = value % 4;
            }
            if (cmd == "cf" && value != -1) {
                format.foreground = color(value, "");
            }
            if (cmd == "highlight" && value != -1) {
                format.background = color(value, "");
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

std::string ntf::richTextToNTF(const std::string rtf)
{
    std::string ntf = rtf;
    
    std::regex ex;
    clearColorTable();
    parseColorTbl(ntf);
    
    ntf = std::regex_replace(ntf, std::regex(R"(\{[^{}]*\})"), "");
    ntf = ntf.substr(1, ntf.length() - 2);
    
    ntf = std::regex_replace(ntf, std::regex(R"(\\par )"), "\\ql ");
    
    rewriteFontSizes(ntf);
    
    return ntf;
}

std::string ntf::markdownToNTF(const std::string& md)
{
    std::string ntf = md;
    
    std::regex re;
    
    re = R"(#{4} (.*))";
    ntf = std::regex_replace(ntf, re, R"(\fs4\b1 $1\b0\fs3 )");
    
    re = R"(#{3} (.*))";
    ntf = std::regex_replace(ntf, re, R"(\fs5\b1 $1\b0\fs3 )");
    
    re = R"(#{2} (.*))";
    ntf = std::regex_replace(ntf, re, R"(\fs6\b1 $1\b0\fs3 )");
    
    re = R"(# (.*))";
    ntf = std::regex_replace(ntf, re, R"(\fs7\b1 $1\b0\fs3 )");
    
    re = R"(\*{2}(.*)\*{2})";
    ntf = std::regex_replace(ntf, re, R"(\b1 $1\b0 )");
    
    re = R"(\*(.*)\*)";
    ntf = std::regex_replace(ntf, re, R"(\i1 $1\i0 )");
    
    re = R"(~~(.*)~~)";
    ntf = std::regex_replace(ntf, re, R"(\strike1 $1\strike0 )");
    
    re = R"(==(.*)==)";
    ntf = std::regex_replace(ntf, re, R"(\bg#7F40 $1\bg#FFFF )");
    
    re = R"( {4}- )";
    ntf = std::regex_replace(ntf, re, R"(\li3 )");
    
    re = R"( {2}- )";
    ntf = std::regex_replace(ntf, re, R"(\li2 )");
    
    re = R"(- )";
    ntf = std::regex_replace(ntf, re, R"(\li1 )");
    
    return ntf;
}

Format ntf::currentFormatState(void)
{
    return format;
}

Style ntf::currentStyleState(void)
{
    return style;
}

void ntf::defaultColorTable(void)
{
    clearColorTable(true);
    colortbl = {
                0x0000, 0x7FFF, 0x0421,
        0x4210, 0x294A, 0x7C00, 0x7D00,
        0x7FE0, 0x7E80, 0x03E0, 0x03FF,
        0x001F, 0x7C1F, 0x4000, 0x4200,
        0x0200, 0x0210, 0x026A
    };
}

void ntf::printRuns(const std::vector<TextRun>& runs)
{
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
