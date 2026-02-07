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

#include "hpnote.hpp"
#include "ntf.hpp"
#include "utf.hpp"

#include <cstdlib>
#include <fstream>
#include <vector>
#include <iostream>
#include <stdexcept>
#include <sstream>
#include <iomanip>

using namespace hpnote;

static constexpr uint16_t STYLE_BOLD = 1u << 10;
static constexpr uint16_t STYLE_ITALIC = 1u << 11;
static constexpr uint16_t STYLE_UNDERLINE = 1u << 12;
static constexpr uint16_t STYLE_STRIKETHROUGH = 1u << 14;

static std::wstring toBase48(uint64_t value)
{
    static constexpr wchar_t digits[] = LR"(0123456789abcdefghijklmnopqrstuv !"#$%&'()*+,-./)";

    if (value == 0)
        return L"0";

    std::wstring result;
    while (value > 0) {
        result.push_back(digits[value % 48]);
        value /= 48;
    }

    std::reverse(result.begin(), result.end());
    return result;
}

static std::wstring encodeParagraphAttributes(const ntf::Align align, const ntf::Bullet bullet)
{
    return LR"(\0\m\)" +
           std::wstring(1, static_cast<wchar_t>(static_cast<char>(bullet) + '0')) +
           LR"(\0\)" +
           std::wstring(1, static_cast<wchar_t>(static_cast<char>(align) + '0')) +
           LR"(\0\n)";
}

static std::wstring encodeTextAttributes(const ntf::Style style, const ntf::FontSize fontSize)
{
    uint32_t attributeBits = 0x1FE001FF;
    
    if (style.bold) attributeBits |= STYLE_BOLD;
    if (style.italic) attributeBits |= STYLE_ITALIC;
    if (style.underline) attributeBits |= STYLE_UNDERLINE;
    if (style.strikethrough) attributeBits |= STYLE_STRIKETHROUGH;
    
    attributeBits |= static_cast<uint32_t>(fontSize) << 15;
    
#ifdef DEBUG
    auto wstr = LR"(\o)" +
    std::wstring(1, static_cast<wchar_t>(attributeBits)) +
    std::wstring(1, static_cast<wchar_t>(attributeBits >> 16));
    
    std::cerr << utf::utf8(wstr) << "\n";
#endif // DEBUG
    
    return LR"(\o)" +
           std::wstring(1, static_cast<wchar_t>(attributeBits)) +
           std::wstring(1, static_cast<wchar_t>(attributeBits >> 16));
}

static std::wstring encodeColorAttributes(const ntf::Format format)
{
    switch (format.foreground) {
        case 0xFFFF:
            /// Default: Black for Light Mode, White for Dark Mode
            switch (format.background) {
                case 0xFFFF:
                    /// Clear
                    return LR"(\0\0Ā\1)";
                    
                case 0:
                    /// Black
                    return LR"(\0\0Ā\0)";
                    
                default:
                    /// Color
                    return LR"(\0)" +
                           std::wstring(1, static_cast<wchar_t>(format.background)) +
                           LR"(Ā\0)";
            }
            
        case 0:
            /// Black
            switch (format.background) {
                case 0xFFFF:
                    /// Clear
                    return LR"(\0\0\0\1)";
                    
                case 0:
                    /// Black
                    return LR"(\0\0\0\0)";
                    
                default:
                    /// Color
                    return LR"(\0)" +
                           std::wstring(1, static_cast<wchar_t>(format.background)) +
                           LR"(\1\0)";
            }
            
        default:
            /// Color
            switch (format.background) {
                case 0xFFFF:
                    /// Clear
                    return std::wstring(1, static_cast<wchar_t>(format.foreground)) +
                           LR"(0\1\1)";
                    
                case 0:
                    /// Black
                    return std::wstring(1, static_cast<wchar_t>(format.foreground)) +
                           LR"(\0\1\0)";
                    
                default:
                    /// Color
                    return std::wstring(1, static_cast<wchar_t>(format.foreground)) +
                           std::wstring(1, static_cast<wchar_t>(format.background)) +
                           LR"(\1\0)";
            }
    }
}

static std::wstring encodeLineLength(const std::string& str)
{
    auto size = toBase48(str.size() % 48);
    return str.size() < 32 ? LR"(\)" + size + LR"(\0)" : size + LR"(\0)";
}

static std::wstring encodePixel(const uint16_t color, const int run = 1)
{
    return encodeTextAttributes({}, ntf::FontSize::Font10pt) +
           encodeColorAttributes({.foreground = 0xFFFF, .background = color}) +
           LR"(\0\0x\)" +
           std::wstring(1, static_cast<wchar_t>(run + '0')) +
           LR"(\0)" +
           std::wstring(run, L' ');
}

static std::wstring encodeNTFPict(const std::string& str, int& lines)
{
    std::wstring wstr;
    int value = -1;
    
    for (size_t i = 5; i < str.size(); ) {
        if (i < str.size() && std::isdigit(str[i])) {
            value = 0;
            while (i < str.size() && std::isdigit(str[i])) {
                value = value * 10 + (str[i++] - '0');
            }
        }
    }
    auto pict = ntf::pict(value);
    
    if (pict.pixels.empty())
        return wstr;
    
    auto pixelWidth = static_cast<int>(pict.pixelWidth);
    
    int i = 0;
    for (int y=0; y<pict.height; y++) {
        wstr.append(LR"(\0\m\0\0\0\0\n)");
        wstr.at(wstr.size() - 5) = toBase48(static_cast<uint64_t>(pict.align)).at(0);
        
        /// Compression of consecutive pixels sharing the same color.
        for (int x = 0; x < pict.width; ) {
            int count = 1;
            int current = pict.pixels[i];
            
            
            while (x + count < pict.width && pict.pixels[i + count] == current && count < 8) {
                count++;
            }
            
            if (current == pict.keycolor)
                current = 0xFFFF;
            
            // Encode the pixel with current color
            wstr.append(encodePixel(current, count * pixelWidth));
            
            // Move to next different color
            x += count;
            i += count;
        }
        
        wstr.append(LR"(\0)");
        
        lines++;
    }
    
    return wstr;
}

static std::wstring encodeNTFLine(const std::string& str)
{
    std::wstring encodedLine;
    
    auto runs = ntf::parseNTF(str);
    
#ifdef DEBUG
    static int lines = 0;
        std::cerr << ++lines << ":\n";
        ntf::printRuns(runs);
        std::cerr << "\n";
#endif // DEBUG
    
    if (!runs.size()) {
        /// Blank line
        auto style = ntf::currentStyleState();
        auto format = ntf::currentFormatState();
        
        encodedLine.append(encodeParagraphAttributes(ntf::Align::Left, ntf::Bullet::None));
        encodedLine.append(encodeTextAttributes(style, format.fontSize));
        encodedLine.append(encodeColorAttributes(format));
        encodedLine.append(LR"(\0\0 \0\0\0)");
        
        return encodedLine;
    }
    
    std::wstring encodedParagraphAttributes;
    
    encodedLine = encodeParagraphAttributes(runs.back().format.align, runs.back().bullet);
    
    for (const auto& r : runs) {
        encodedLine.append(encodeTextAttributes(r.style, r.format.fontSize));
        encodedLine.append(encodeColorAttributes(r.format));
        encodedLine += LR"(\0\0 )";
        
        /// Length
        encodedLine.append(encodeLineLength(r.text));
        
        /// Text
        encodedLine.append(utf::utf16(r.text));
    }
    encodedLine.append(LR"(\0)");
    
    return encodedLine;
}

static std::wstring encodeNTFDocument(std::istringstream& iss) {
    std::string str;
    std::wstring wstr;
    
    ntf::reset();
    
    int lines = -1;
    while(getline(iss, str)) {
        if (str.substr(0, 5) == "\\pict") {
            wstr += encodeNTFPict(str, lines);
            continue;
        } else
            wstr += encodeNTFLine(str);
        
        lines++;
    }
    
    // Footer control bytes
    wstr.append(LR"(\0\0\3\0\)");
    
    // Line count (base-48 style)
    wstr.append(toBase48((uint64_t)lines));
  
    // Footer control bytes
    wstr.append(LR"(\0\0\0\0\0\0\0)");
    
    return wstr;
}

static std::wstring extractPlainText(const std::string ntf) {
    std::wstring wstr;
    
    auto runs = ntf::parseNTF(ntf);
    
    for (const auto& r : runs) {
        wstr.append(utf::utf16(r.text));
    }
    
    return wstr;
}

std::wstring hpnote::encodeHPNoteFromNTF(const std::string& ntf, bool minify) {
    std::wstring wstr;
    wstr.reserve(ntf.size() * 2);
    
    std::string input = ntf::extractPicts(ntf);
    
    if (!minify) {
        wstr.append(extractPlainText(input));
    }
    
    wstr.push_back(L'\0');
    wstr += L"CSWD110\xFFFF\xFFFF\\l\x013E";
    
    std::istringstream iss(input);
    wstr += encodeNTFDocument(iss);
    
    return wstr;
}
