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

static constexpr std::u16string_view STYLE_SCRIPT = u"\\0\\m\\0\\0\\0\\0\\n\\o臿ῡ\\0\\0Ā\\1\\0\\0x\\0\\0\\0";

#include <string>
#include <climits>

#include <string>
#include <climits>

// Base-32 values are preceded by the escape character (\), while integer values are not.
static std::u16string encodeValue(uint16_t value)
{
    static constexpr char16_t digits[] = u"0123456789abcdefghijklmnopqrstuv";
 
    if (value < 32)
        return std::u16string{L'\\', digits[value]};
    
    /**
     ⚠️ Checks that the value to be encoded is not 0x5C. If 0x5C is encountered, it is
     encoded as escape '\', since 0x5C is the ASCII '\' escape character
     used to indicate that a number is encoded in base-32 rather than as a plain integer.
     */
    if (value == 0x5C)
        return uR"(\\)";
    
    return std::u16string{static_cast<char16_t>(
        static_cast<uint16_t>(value)
    )};
}

static std::u16string encodeParagraphAttributes(const ntf::Align align, const ntf::Bullet bullet)
{
    return u"\\0\\m" +
           encodeValue(static_cast<uint64_t>(bullet)) +
           u"\\0" +
           encodeValue(static_cast<uint64_t>(align)) +
           u"\\0\\n";
}

static std::u16string encodeTextAttributes(const ntf::Style style, const ntf::FontSize fontSize)
{
    uint32_t attributeBits = 0x1FE001FF;
    
    if (style.bold) attributeBits |= STYLE_BOLD;
    if (style.italic) attributeBits |= STYLE_ITALIC;
    if (style.underline) attributeBits |= STYLE_UNDERLINE;
    if (style.strikethrough) attributeBits |= STYLE_STRIKETHROUGH;
    
    attributeBits |= static_cast<uint32_t>(fontSize) << 15;
    
    return u"\\o" +
           std::u16string(1, static_cast<char16_t>(attributeBits & 0xFFFF)) +
           std::u16string(1, static_cast<char16_t>(attributeBits >> 16));
}

static std::u16string encodeColorAttributes(const ntf::Format format)
{
    return
        encodeValue(format.foreground & 0x7FFF) +
        encodeValue(format.background & 0x7FFF) +
        (format.foreground & 0x8000 ? u"Ā" : encodeValue((format.foreground != 0))) +
        encodeValue((format.background & 0x8000));
}

static std::u16string encodePixel(const uint16_t color, const int run = 1)
{
    return
        encodeTextAttributes({}, ntf::FontSize::Font10pt) +
        encodeColorAttributes({.foreground = 0xFFFF, .background = color}) +
        u"\\0\\0x" +
        encodeValue(run) +
        u"\\0" +
        std::u16string(run, u' ');
}

static std::u16string encodeNTFPict(const std::string& str, int& lines)
{
    std::u16string wstr;
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
    
    for (int y=0; y<pict.height; y++) {
        // Alignment: Left | Center | Right
        wstr += u"\\0\\m\\0\\0" +
                encodeValue(static_cast<uint64_t>(pict.align)) +
                u"\\0\\n";
        
        // Compression of consecutive pixels sharing the same color.
        for (int x = 0; x < pict.width; ) {
            int index = y * pict.width + x;
            int count = 1;
            int current = pict.pixels[index];
            
            while (x + count < pict.width &&
                   pict.pixels[index + count] == current)
            {
                ++count;
            }
            
            if (current == pict.keycolor)
                current = 0xFFFF;
            
            // Encode the pixel with current color
            wstr += encodePixel(current, count * pixelWidth);
            
            // Move to next different color
            x += count;
        }
        
        wstr += u"\\0";
        
        lines++;
    }
    
    return wstr;
}

static std::u16string encodeNTFLine(const std::string& str)
{
    std::u16string encodedLine;
    
    auto runs = ntf::parseNTF(str);
    auto style = ntf::currentStyleState();
    auto format = ntf::currentFormatState();
    
    if (!runs.size()) {
        // Blank line
        encodedLine += encodeParagraphAttributes(ntf::Align::Left, ntf::Bullet::None);
        encodedLine += encodeTextAttributes(style, format.fontSize);
        encodedLine += encodeColorAttributes(format);
        encodedLine += u"\\0\\0x\\0\\0\\0";
        
        return encodedLine;
    }
    
    std::u16string encodedParagraphAttributes;
    
    encodedLine = encodeParagraphAttributes(runs.back().format.align, runs.back().bullet);
    
    for (const auto& r : runs) {
        encodedLine += encodeTextAttributes(r.style, r.format.fontSize);
        encodedLine += encodeColorAttributes(r.format);
        encodedLine += u"\\0\\0x";
        
        auto length = utf::size(r.text);
        encodedLine += encodeValue(length) + u"\\0";
        
        encodedLine += utf::u16(r.text);
    }
    encodedLine += u"\\0";
    
    if (style.superscript)
        encodedLine += STYLE_SCRIPT;
    else if (style.subscript)
        return encodedLine.insert(0, STYLE_SCRIPT);
    
    return encodedLine;
}

static std::u16string encodeNTFDocument(std::istringstream& iss) {
    std::string str;
    std::u16string wstr;
    
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
    wstr.append(uR"(\0\0\3\0)");
    
    /*
     Values encoded in base-32 are marked with a leading escape character \.
     Integer values are stored directly, without an escape prefix.
     */
    wstr.append(encodeValue(lines));
  
    // Footer control bytes
    wstr.append(uR"(\0\0\0\0\0\0\0)");
    
    return wstr;
}

static std::u16string extractPlainText(const std::string ntf) {
    std::u16string wstr;
    
    auto runs = ntf::parseNTF(ntf);
    
    for (const auto& r : runs) {
        
        wstr.append(utf::u16(r.text));
    }
    
    return wstr;
}

std::wstring hpnote::encodeHPNoteFromNTF(const std::string& ntf, bool minify) {
    std::u16string wstr;
    wstr.reserve(ntf.size() * 2);
    
    std::string input = ntf::extractPicts(ntf);
    
    if (!minify) {
        wstr.append(extractPlainText(input));
    }
    
    wstr.push_back(L'\0');
    wstr += u"CSWD110\xFFFF\xFFFF\\l\x013E";
    
    std::istringstream iss(input);
    wstr += encodeNTFDocument(iss);
    
    return utf::utf16(wstr);
}
