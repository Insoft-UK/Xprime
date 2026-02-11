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
#include "extensions.hpp"

#include <cstdlib>
#include <fstream>
#include <vector>
#include <iostream>
#include <stdexcept>
#include <sstream>
#include <iomanip>
#include <span>

#define DECODE

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
//#include <stdexcept>

// MARK: - Encode ntf to hpnote

static char16_t base32Char(uint16_t value)
{
    if (value < 10)
        return u'0' + value;

    if (value < 32)
        return u'a' + (value - 10);

    throw std::runtime_error("Invalid base32 value");
}

static std::u16string encodeValue(uint16_t value)
{
    // Backslash must always be escaped
    if (value == u'\\') {
        return u"\\\\";
    }

    // Values that would be interpreted as escaped base32 digits
    // must be escaped to preserve round-trip behavior.
    if (value < 32) {
        return std::u16string{ u'\\', base32Char(value) };
    }

    // Otherwise emit directly
    return std::u16string{ static_cast<char16_t>(value) };
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
    std::u16string out;
    
    out += format.foreground <= 0x7FFF ? encodeValue(format.foreground & 0x7FFF) : u"\\0";
    out += format.background <= 0x7FFF ? encodeValue(format.background & 0x7FFF) : u"\\0";
    
    if (format.foreground > 0x7FFF)
        out.push_back(format.fontSize == ntf::FontSize::Font14pt ? 257 : 256);
    else {
        out += format.foreground ? u"\\1" : u"\\0";
    }
    
    out += format.background > 0x7FFF ? u"\\1" : u"\\0";
    
    return out;
}

static std::u16string encodePixel(const uint16_t color, const int run = 1)
{
    return
        encodeTextAttributes({}, ntf::FontSize::Font10pt) +
        encodeColorAttributes({.foreground = 0xFFFF, .background = color, .fontSize = ntf::FontSize::Font10pt}) +
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

static std::u16string encodeNTFDocument(std::istringstream& iss)
{
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

static std::u16string extractPlainText(const std::string& ntf)
{
    std::u16string wstr;
    
    auto runs = ntf::parseNTF(ntf);
    
    for (const auto& r : runs) {
        
        wstr.append(utf::u16(r.text));
    }
    
    return wstr;
}

#ifdef DECODE
// MARK: - Decode hpnote to ntf

static bool isHex(char c)
{
    return std::isdigit(c) ||
           (c >= 'A' && c <= 'F');
}

std::string normalizeControlWordSpacing(const std::string& input)
{
    std::string out;
    size_t i = 0;

    while (i < input.size()) {
        if (input[i] != '\\') {
            out += input[i++];
            continue;
        }

        // Start of control word
        size_t start = i++;
        out += '\\';

        // Read control word name (letters only)
        while (i < input.size() && std::isalpha(static_cast<unsigned char>(input[i]))) {
            out += input[i++];
        }

        bool hasDecimal = false;
        bool hasHex = false;

        // Hex parameter: #XXXX
        if (i < input.size() && input[i] == '#') {
            hasHex = true;
            out += input[i++];

            while (i < input.size() && isHex(input[i])) {
                out += input[i++];
            }
        }
        // Decimal parameter
        else {
            size_t digitStart = i;
            while (i < input.size() && std::isdigit(static_cast<unsigned char>(input[i]))) {
                out += input[i++];
            }
            hasDecimal = (i != digitStart);
        }

        // Check for a space after the control word
        if (i < input.size() && input[i] == ' ') {
            char next = (i + 1 < input.size()) ? input[i + 1] : '\0';

            bool keepSpace = false;

            if (hasHex) {
                // Space not needed if next is non-hex
                keepSpace = isHex(next);
            }
            else if (hasDecimal) {
                // Space not needed if next is non-digit
                keepSpace = std::isdigit(static_cast<unsigned char>(next));
            }
            else {
                // No parameter → space required if text follows
                keepSpace = (next != '\\' && next != '\0');
            }

            if (keepSpace) {
                out += ' ';
            }

            ++i; // consume space
        }
    }

    return out;
}

static uint16_t base32Value(char16_t c)
{
    if (c >= u'0' && c <= u'9')
        return c - u'0';

    if (c >= u'a' && c <= u'v')
        return 10 + (c - u'a');

    throw std::runtime_error("Invalid base32 digit");
}

static uint16_t parseValue(const std::u16string& data, size_t& i)
{
    char16_t c = data[i];

    if (c != u'\\') {
        // direct value
        return static_cast<uint16_t>(c);
    }

    // escape sequence
    if (++i >= data.size())
        throw std::runtime_error("Dangling escape");

    char16_t next = data[i];

    if (next == u'\\') {
        return 0x005C; // literal backslash
    }

    return base32Value(next);
}

std::u16string to_u16string(int value)
{
    std::string s = std::to_string(value);
    return std::u16string(s.begin(), s.end());
}

static ntf::Format format;
static ntf::Style style;
static ntf::Bullet  _bullet;

static std::string decodeParagraphAttributes(std::span<const uint16_t> data)
{
    std::string s;
    auto bullet = static_cast<ntf::Bullet>(data[2]);
    
    if (bullet != _bullet) {
        _bullet = bullet;
        
        switch (bullet) {
            case ntf::Bullet::None:
                s += "\\li0 ";
                break;
            case ntf::Bullet::Primary:
                s += "\\li1 ";
                break;
            case ntf::Bullet::Secondary:
                s += "\\li2 ";
                break;
            case ntf::Bullet::Tertiary:
                s += "\\li3 ";
                break;
        }
    }
    
    auto align = static_cast<ntf::Align>(data[4]);
    
    if (align != format.align) {
        format.align = align;
        
        switch (align) {
            case ntf::Align::Left:
                s += "\\ql ";
                break;
            case ntf::Align::Center:
                s += "\\qc ";
                break;
            case ntf::Align::Right:
                s += "\\qr ";
                break;
        }
    }
    
    return s;
}

static std::string decodeTextAttributes(std::span<const uint16_t> data)
{
    std::string s;
    ntf::FontSize fontSize;
    
    uint32_t attributeBits = data[1] | data[2] << 16;
    
    if (attributeBits & STYLE_BOLD) {
        if (!style.bold)
            s += "\\b ";
    } else {
        if (style.bold)
            s += "\\b0 ";
    }
    style.bold = attributeBits & STYLE_BOLD;
    
    if (attributeBits & STYLE_ITALIC) {
        if (!style.italic)
            s += "\\i ";
    } else {
        if (style.italic)
            s += "\\i0 ";
    }
    style.italic = attributeBits & STYLE_ITALIC;
    
    if (attributeBits & STYLE_UNDERLINE) {
        if (!style.underline)
            s += "\\ul ";
    } else {
        if (style.underline)
            s += "\\ul0 ";
    }
    style.italic = attributeBits & STYLE_UNDERLINE;
    
    if (attributeBits & STYLE_STRIKETHROUGH) {
        if (!style.strikethrough)
            s += "\\strike ";
    } else {
        if (style.strikethrough)
            s += "\\strike0 ";
    }
    style.italic = attributeBits & STYLE_STRIKETHROUGH;
    
    fontSize = static_cast<ntf::FontSize>((attributeBits >> 15) & 7);
    
    if (fontSize != format.fontSize) {
        format.fontSize = fontSize;
        
        s += "\\fs" + std::to_string((attributeBits >> 15) & 7) + " ";
    }
    
    return s;
}

static std::string decodeColorAttributes(std::span<const uint16_t> data)
{
    std::string s;
    
    auto foreground = data[0];
    auto background = data[1];
    
    if (data[2] == 256 || data[2] == 257) {
        foreground = 0xFFFF;
    } else if (data[2] == 0)
        foreground = 0;
    
    if (data[3] == 1) {
        background = 0xFFFF;
    }
    
    if (foreground != format.foreground) {
        format.foreground = foreground;
        s += "\\cf#" + std::uppercased(std::format("{:04x}", foreground)) + " ";
    }
    
    if (background != format.background) {
        format.background = background;
        s += "\\cb#" + std::uppercased(std::format("{:04x}", background)) + " ";
    }
    
    return s;
}

std::vector<uint16_t> decodeValues(const std::u16string& data)
{
    std::vector<uint16_t> out;
    
    for (size_t i = 0; i < data.size(); ++i) {
        out.push_back(parseValue(data, i));
    }

    return out;
}

std::vector<size_t> findOffsets(const std::vector<uint16_t>& data, const std::vector<uint16_t>& pattern)
{
    std::vector<size_t> offsets;
    
    if (pattern.empty() || data.size() < pattern.size())
        return offsets;
    
    for (size_t i = 0; i <= data.size() - pattern.size(); ++i) {
        bool match = true;
        
        for (size_t j = 0; j < pattern.size(); ++j) {
            if (data[i + j] != pattern[j]) {
                match = false;
                break;
            }
        }
        
        if (match)
            offsets.push_back(i);
    }
    
    return offsets;
}

std::string decodeLine(std::span<const uint16_t> slice)
{
    std::string s;
    size_t pos = 0;

    auto take = [&](size_t n) {
        auto sub = slice.subspan(pos, n);
        pos += n;
        return sub;
    };

    // Paragraph attributes (7)
    s += decodeParagraphAttributes(take(7));

    while (true) {
        // Text attributes (3)
        s += decodeTextAttributes(take(3));

        // Color attributes (4)
        s += decodeColorAttributes(take(4));

        // Header before text (5)
        auto header = take(5);
        uint16_t length = header[3];

        if (header[2] != 120 && length && !s.empty() && s.back() != ' ')
            s += ' ';

        // Text payload
        for (size_t i = 0; i < length; ++i) {
            s.push_back(static_cast<char>(slice[pos]));
            ++pos;
        }
        
        if (slice[pos] == 24)
            continue;
        
        break;
    }

    return s;
}

std::string decodeHPNote(const std::u16string u16s)
{
    std::string s;
    
    auto data = decodeValues(u16s);
    auto lines = data[data.size() - 8];
    auto offsets = findOffsets(data, {0,22});
    
    while (lines--) {
        if (s.size()) s += "\n";
        s += decodeLine(std::span(data).subspan(offsets.front()));
        offsets.erase(offsets.begin(), offsets.begin() + 1);
    }
    return s;
}
#endif // DECODE

std::u16string hpnote::encodeHPNoteFromNTF(const std::string& ntf, bool cc)
{
    std::u16string wstr;
    wstr.reserve(ntf.size() * 2);
    
    std::string input = ntf::extractPicts(ntf);
    
    if (cc) {
        wstr.append(extractPlainText(input));
    }
    
    wstr.push_back(L'\0');
    // T for Apps, D for Programs ?
    wstr += u"CSW?110\xFFFF\xFFFF\\l\x013E";
    
    std::istringstream iss(input);
    wstr += encodeNTFDocument(iss);
    
    return wstr;
}

std::string hpnote::decodeHPNoteToNTF(const std::u16string& u16s)
{
    auto i = u16s.find(u"CSWD110\xFFFF\xFFFF\\l\x013E");

#ifndef DECODE
    i = std::u16string::npos;
#endif
    if (i == std::u16string::npos) {
        std::u16string out;
        
#ifdef __BIG_ENDIAN__
        out.push_back(u'\xFFFE');
#else
        out.push_back(u'\xFEFF');
#endif
        for (size_t i = 0; i < u16s.size() && u16s.at(i) != 0; i++) {
            out.push_back(u16s.at(i));
        }
        out.push_back(u'\0');
        return utf::utf8(utf::utf16(out));
    }
#ifdef DECODE
    auto out = decodeHPNote(u16s.substr(i, u16s.size() - 1));
    out = normalizeControlWordSpacing(out);
    return out;
#endif // DECODE
    return "";
}
