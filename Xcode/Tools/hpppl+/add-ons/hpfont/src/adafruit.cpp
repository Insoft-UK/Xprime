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

#include "adafruit.hpp"

#include <regex>
#include <fstream>
#include "utf.hpp"

#if __cplusplus >= 202302L
    #include <bit>
    using std::byteswap;
#elif __cplusplus >= 201103L
    #include <cstdint>
    namespace std {
        template <typename T>
        T byteswap(T u)
        {
            
            static_assert (CHAR_BIT == 8, "CHAR_BIT != 8");
            
            union
            {
                T u;
                unsigned char u8[sizeof(T)];
            } source, dest;
            
            source.u = u;
            
            for (size_t k = 0; k < sizeof(T); k++)
                dest.u8[k] = source.u8[sizeof(T) - k - 1];
            
            return dest.u;
        }
    }
#else
    #error "C++11 or newer is required"
#endif

typedef struct {
    uint16_t   bitmapOffset;    // Offset address into the bitmap data.
    uint8_t    width, height;   // Bitmap dimensions in pixels.
    uint8_t    xAdvance;        // Distance to advance cursor in the x-axis.
    int8_t     dX;              // Used to position the glyph within the cell in the horizontal direction.
    int8_t     dY;              // Distance from the baseline of the character to the top of the glyph.
} TGlyph;

typedef struct {
    uint8_t   *bitmap;          // Glyph bitmaps, concatenated.
    TGlyph    *glyph;           // Glyph array.
    uint8_t   first;           // The first UTF16 value of your first character.
    uint8_t   last;            // The last UTF16 value of your last character.
    uint8_t    yAdvance;        // Newline distance in the y-axis.
} TFont;

/*
 The UTF8 table stores the index of each glyph within the glyph table, indicating where the glyph entry
 for a particular UTF16 character resides. The table does not include entries for the first and last glyph
 indices, as they are unnecessary: the first glyph index always corresponds to the first glyph entry, and
 the last glyph in the font is always the last glyph entry.
 */

typedef struct {
    std::vector<uint8_t> data;
    std::vector<TGlyph> glyphs;
    uint8_t first;
    uint8_t last;
    uint8_t yAdvance;
} TAdafruitFont;

static int parseNumber(const std::string &str)
{
    std::regex hexPattern("^0x[\\da-fA-F]+$");
    std::regex decPattern("^[+-]?\\d+$");
    std::regex octPattern("^0[0-8]+$");
    std::regex binPattern("^0b[01]+$");
    
    if (std::regex_match(str, hexPattern)) return std::stoi(str, nullptr, 16);
    if (std::regex_match(str, decPattern)) return std::stoi(str, nullptr, 10);
    if (std::regex_match(str, octPattern)) return std::stoi(str, nullptr, 8);
    if (std::regex_match(str, binPattern)) return std::stoi(str, nullptr, 2);
    
    return 0;
}

static bool parseHAdafruitFont(const std::filesystem::path& path, TAdafruitFont &font)
{
    std::ifstream infile;
    std::string utf8;
    
    utf8 = utf::load(path);
    
    // Check if the file is successfully opened
    if (utf8.empty()) {
        std::cerr << "Error opening file: " << path.filename().string() << std::endl;
        return false;
    }
    
    utf8 = std::regex_replace(utf8, std::regex(R"(\bunsigned char\b)"), "uint8_t");
    
    std::smatch match;
    std::regex_search(utf8, match, std::regex(R"(const uint8_t \w+\[\] PROGMEM = \{([^}]*))"));
    if (match[1].matched) {
        auto s = match.str(1);
        while (std::regex_search(s, match, std::regex(R"((?:0x)?[\d[a-fA-F]{1,2})"))) {
            font.data.push_back(parseNumber(match.str()));
            s = match.suffix().str();
        }
    } else {
        std::cerr << "Failed to find <Bitmap Data>.\n";
        return false;
    }
    
    auto s = utf8;
    while (std::regex_search(s, match, std::regex(R"(\{ *((?:0x)?[\d[a-fA-F]+) *, *(-?[xb\da-fA-F]+) *, *(-?[xb\da-fA-F]+) *, *(-?[xb\da-fA-F]+) *, *(-?[xb\da-fA-F]+) *, *(-?[xb\da-fA-F]+) *\})"))) {
        TGlyph glyph;
        glyph.bitmapOffset = parseNumber(match.str(1));
        glyph.width = parseNumber(match.str(2));
        glyph.height = parseNumber(match.str(3));
        glyph.xAdvance = parseNumber(match.str(4));
        glyph.dX = parseNumber(match.str(5));
        glyph.dY = parseNumber(match.str(6));
        font.glyphs.push_back(glyph);
        s = match.suffix().str();
    }
    if (font.glyphs.empty()) {
        std::cerr << "Failed to find <Glyph Table>.\n";
        return false;
    }
    
    if (std::regex_search(s, match, std::regex(R"(((?:0x)?[\da-fA-F]+)\s*,\s*((?:0x)?[\da-fA-F]+)\s*,\s*((?:0x)?[\da-fA-F]+)\s*\};)"))) {
        font.first = parseNumber(match.str(1));
        font.last = parseNumber(match.str(2));
        font.yAdvance = parseNumber(match.str(3));
    } else {
        std::cerr << "Failed to find <Font>.\n";
        return false;
    }
    
    return true;
}

static uint8_t mirrorByte(uint8_t b)
{
    b = ((b & 0xF0) >> 4) | ((b & 0x0F) << 4);  // Swap upper and lower 4 bits
    b = ((b & 0xCC) >> 2) | ((b & 0x33) << 2);  // Swap pairs of bits
    b = ((b & 0xAA) >> 1) | ((b & 0x55) << 1);  // Swap individual bits
    return b;
}

// A list is limited to 10,000 elements. Attempting to create a longer list will result in error 38 (Insufficient memory) being thrown.
static std::string createPPLList(const void *data, const size_t lengthInBytes, const int columns, bool le = true) {
    std::ostringstream os;
    uint64_t n;
    size_t count = 0;
    size_t length = lengthInBytes;
    uint64_t *bytes = (uint64_t *)data;
    
    while (length >= 8) {
        n = *bytes++;
        
        if (!le) {
            n = std::byteswap<uint64_t>(n);
        }
        
#ifdef __BIG_ENDIAN__
        /*
         This platform utilizes big-endian, not little-endian. To ensure
         that data is processed correctly when generating the list, we
         must convert between big-endian and little-endian.
         */
        if (le) n = std::byteswap<uint64_t>(n);
#endif // __BIG_ENDIAN__

        if (count) os << ", ";
        if (count % columns == 0) {
            os << (count ? "\n  " : "  ");
        }
        os << "#" << std::uppercase << std::hex << std::setfill('0') << std::setw(16) << n << ":64h";
        
        count += 1;
        length -= 8;
    }
    
    if (length) {
        n = *bytes++;
        
        if (!le) {
            n = std::byteswap<uint64_t>(n);
        }
        
        os << " ,";
        if (count % columns == 0) {
            os << (count ? "\n  " : "  ");
        }
        
        // TODO: improve this code for readability.
        os << "#" << std::uppercase << std::hex << std::setfill('0') << std::setw(16) << (n & (0xFFFFFFFFFFFFFFFF >> ((8-length) * 8))) << ":64h";
    }
    
    return os.str();
}

static std::string createPPLAdafruitFont(TAdafruitFont &adafruitFont, const std::string &name)
{
    std::ostringstream os;
    
    for (auto it = adafruitFont.data.begin(); it < adafruitFont.data.end(); it++) {
        *it = mirrorByte(*it);
    }
    
    if (name.size()) os << name << " := ";
    os << "{\n"
       << " {\n" << createPPLList(adafruitFont.data.data(), adafruitFont.data.size(), 16) << "\n"
       << " },{\n"
       << createPPLList(adafruitFont.glyphs.data(), adafruitFont.glyphs.size() * sizeof(TGlyph), 16) << "\n"
       << " }, " << (int)adafruitFont.first << ", " << (int)adafruitFont.last << ", " << (int)adafruitFont.yAdvance << "\n"
       << "}";
    
    return os.str();
}

std::string adafruit::convertAdafruitFontToPPL(const std::filesystem::path& inpath, const std::string name = "")
{
    TAdafruitFont adafruitFont;
    std::string str;
    
    if (!parseHAdafruitFont(inpath, adafruitFont)) {
        std::cerr << "Failed to find valid Adafruit Font data.\n";
        exit(2);
    }

    if (name == "*")
        str = createPPLAdafruitFont(adafruitFont, inpath.stem().string());
    else
        str = createPPLAdafruitFont(adafruitFont, name);
    
    return str;
}
