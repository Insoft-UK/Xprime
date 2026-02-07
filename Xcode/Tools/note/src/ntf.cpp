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
#include <bit>

#define PICT_MAX_WIDTH 106

using namespace ntf;

static std::vector<Color> colortbl;
static std::vector<Pict> picttbl;

static Format format{};
static Style style{};
static Bullet bullet = Bullet::None;


static inline int hexVal(char c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1; // everything else is noise (including a–f)
}

static bool parsePict(const std::string& ntf, size_t startPos, Pict& out)
{
    if (ntf.compare(startPos, 6, "{\\pict") != 0)
        return false;

    size_t i = startPos + 6;
    int depth = 1;

    uint16_t pixel = 0;
    int nibbleCount = 0;

    out.pixels.clear();

    for (; i < ntf.size(); ++i) {
        char c = ntf[i];

        if (c == '{') { depth++; continue; }
        if (c == '}') {
            if (--depth == 0)
                break;
            continue;
        }

        if (c == '\\') {
            size_t s = ++i;
            while (i < ntf.size() && std::isalpha(ntf[i]))
                ++i;

            std::string word = ntf.substr(s, i - s);

            int value = 0;
            bool hasValue = false;
            
            // Hex color value (for fg#XXXX / bg#XXXX)
            std::string hex;
            if (ntf[i] == '#') {
                i++;
                while (i < ntf.size() && std::isxdigit(ntf[i])) {
                    hex += ntf[i++];
                }
            }
            
            if (!hex.empty()) {
                hasValue = true;
                value = std::stoi(hex, nullptr, 16);
            }

            if (i < ntf.size() && std::isdigit(ntf[i])) {
                hasValue = true;
                while (i < ntf.size() && std::isdigit(ntf[i])) {
                    value = value * 10 + (ntf[i] - '0');
                    ++i;
                }
            }

            if (hasValue) {
                if (word == "picw")  out.width  = value;
                if (word == "pich")  out.height = value;
                if (word == "endian")  out.endian = value == 1 ? Endian::Little : Endian::Big;
                if (word == "pixelw")  out.pixelWidth = value > 0 && value <= 3 ? static_cast<PixelWidth>(value) : PixelWidth::Square;
                if (word == "keycolor") out.keycolor = value != -1 ? value : 0x7C1F;
                if (word == "align")  out.align  = static_cast<Align>(value);
            }

            --i;
            continue;
        }

        int v = hexVal(c);
        if (v >= 0) {
            pixel = (pixel << 4) | v;
            if (++nibbleCount == 4) {
                if (out.endian == ntf::Endian::Little) {
                    pixel = std::byteswap(pixel);
                }
                out.pixels.push_back(pixel);
                pixel = 0;
                nibbleCount = 0;
            }
        }
        // EVERYTHING else is ignored by design
    }

    if (nibbleCount != 0)
        return false; // half pixel left

    if (out.width && out.height) {
        size_t expected = static_cast<size_t>(out.width) * out.height;
        if (out.pixels.size() != expected)
            return false;
    }

    return true;
}

static size_t findGroupEnd(const std::string& s, size_t start)
{
    int depth = 0;
    for (size_t i = start; i < s.size(); ++i) {
        if (s[i] == '{') depth++;
        else if (s[i] == '}') {
            if (--depth == 0)
                return i;
        }
    }
    return std::string::npos;
}

static inline uint16_t to5(int v)
{
    return static_cast<uint16_t>((v * 31 + 127) / 255);
}

static inline uint16_t packRGB555(int r, int g, int b)
{
    return (to5(r) << 10) | (to5(g) << 5) | to5(b);
}

static std::vector<uint16_t> parseColorTable(const std::string& rtf)
{
    std::vector<uint16_t> colors;

    // index 0 = default color (\cf0)
    colors.push_back(0xFFFF);

    size_t pos = rtf.find("\\colortbl");
    if (pos == std::string::npos)
        return colors;

    // rewind to group start
    while (pos > 0 && rtf[pos] != '{')
        --pos;

    int depth = 0;
    int r = 0, g = 0, b = 0;
    bool inTable = false;
    bool firstEntry = true; // skip mandatory empty entry

    for (size_t i = pos; i < rtf.size(); ++i) {
        char c = rtf[i];

        if (c == '{') {
            depth++;
            inTable = true;
            continue;
        }

        if (c == '}') {
            depth--;
            if (depth == 0)
                break; // end of colortbl
            continue;
        }

        if (!inTable)
            continue;

        if (c == '\\') {
            size_t start = ++i;
            while (i < rtf.size() && std::isalpha(rtf[i]))
                ++i;

            std::string word = rtf.substr(start, i - start);

            int value = 0;
            bool hasValue = false;

            if (i < rtf.size() && std::isdigit(rtf[i])) {
                hasValue = true;
                while (i < rtf.size() && std::isdigit(rtf[i])) {
                    value = value * 10 + (rtf[i] - '0');
                    ++i;
                }
            }

            if (hasValue) {
                if (word == "red")        r = value;
                else if (word == "green") g = value;
                else if (word == "blue")  b = value;
            }

            --i;
        }
        else if (c == ';') {
            if (firstEntry) {
                firstEntry = false; // skip leading empty entry
            } else {
                colors.push_back(packRGB555(r, g, b));
            }
            r = g = b = 0;
        }
    }

#if DEBUG
    std::cerr << "Defined Color RGB555 Table:\n";
    int i = 0;
    for (uint16_t color : colors) {
        std::cerr << i++ << ": 0x"
                  << std::setw(4) << std::setfill('0')
                  << std::hex << color << "\n";
    }
#endif

    return colors;
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

            // Transform N → N/2
            int newValue = value / 2;
            if (newValue < 0)
                newValue = 0;
            
            if (newValue > 22)
                newValue = 22;

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

static std::string removeNonNestedGroups(const std::string& rtf)
{
    std::string out;
    out.reserve(rtf.size());

    for (size_t i = 0; i < rtf.size(); ++i) {
        if (rtf[i] == '{') {
            size_t j = i + 1;
            bool nested = false;

            while (j < rtf.size() && rtf[j] != '}') {
                if (rtf[j] == '{') {
                    nested = true;
                    break;
                }
                ++j;
            }

            // Skip flat group
            if (!nested && j < rtf.size()) {
                i = j;
                continue;
            }
        }

        out.push_back(rtf[i]);
    }

    return out;
}

static void removeNewlines(std::string& text)
{
    std::string out;
    out.reserve(text.size());

    for (char c: text) {
        if (c == '\n' || c == '\r')
            continue;
         
        out.push_back(c);
    }

    text.swap(out);
}

static void normalizeNewlines(std::string& text)
{
    std::string out;
    out.reserve(text.size());

    for (size_t i = 0; i < text.size(); ++i) {
        char c = text[i];

        if (c == '\n' || c == '\r') {
            // Preserve newline if previous character is '\'
            if (i > 0 && text[i - 1] == '\\') {
                out.push_back('p');
                out.push_back('a');
                out.push_back('r');
                out.push_back(' ');
            }
            // otherwise: drop it
            continue;
        }

        out.push_back(c);
    }

    text.swap(out);
}

static void normalizeParagraphs(std::string& text)
{
    std::string out;
    out.reserve(text.size());

    bool lastWasNewline = false;

    for (size_t i = 0; i < text.size(); ++i) {
        // Handle \par
        if (i + 4 < text.size() && text.compare(i, 4, "\\par") == 0 && !std::isalpha(text[i+4])) {
            if (!lastWasNewline) {
                out.push_back('\n');
                lastWasNewline = true;
            }
            i += 4;
            continue;
        }

        char c = text[i];

        // Normalize raw newlines
        if (i + 1 < text.size() && c == '\\' && (text[i+1] == '\n' || text[i+1] == '\r')) {
            if (!lastWasNewline) {
                out.push_back('\n');
                lastWasNewline = true;
            }
            continue;
        }

        out.push_back(c);
        lastWasNewline = false;
    }

    text.swap(out);
}

void ntf::reset(void)
{
    format = {};
    style = {};
    bullet = Bullet::None;
}

std::string ntf::extractPicts(const std::string& ntf)
{
    std::string out;
    out.reserve(ntf.size());

    for (size_t i = 0; i < ntf.size(); ) {
        if (ntf.compare(i, 6, "{\\pict") == 0) {
            size_t end = findGroupEnd(ntf, i);
            if (end == std::string::npos)
                break; // malformed RTF, bail safely

            Pict pict;
            if (parsePict(ntf, i, pict)) {
                if (pict.width * static_cast<int>(pict.pixelWidth) <= PICT_MAX_WIDTH) {
                    picttbl.push_back(std::move(pict));
                    if (out.size() && out[out.size() - 1] != '\n')
                        out.push_back('\n');
                    out.append("\\pict" + std::to_string(picttbl.size() - 1));
                    out.push_back('\n');
                }
            }

            // skip entire pict group (no output)
            i = end + 1;
            while (i < ntf.size() && ntf.at(i) <= ' ') {
                i++;
            }
            continue;
        }

        // normal text passes through unchanged
        out.push_back(ntf[i++]);
    }

    return out;
}

Pict ntf::pict(const int N)
{
    if (N > -1 && N < picttbl.size())
        return picttbl[N];
    return {};
}

std::vector<TextRun> ntf::parseNTF(const std::string& ntf)
{
    std::vector<TextRun> runs;
    std::string buffer;
    
    auto flush = [&]() {
        if (!buffer.empty()) {
            runs.push_back({ buffer, format, style, bullet });
            buffer.clear();
        }
    };

    for (size_t i = 0; i < ntf.size(); ) {
        if (ntf[i] == '{') {
            // Ignore group
            while (ntf[++i] != '}');
            continue;
        }
        
        if (ntf[i] == '\\') {
            // Flush text before control word
            flush();
            i++;

            // Read control word name
            std::string cmd;
            while (i < ntf.size() && std::isalpha(ntf[i])) {
                cmd += ntf[i++];
            }

            // Hex color value (for fg#XXXX / bg#XXXX)
            std::string hex;
            if (ntf[i] == '#') {
                i++;
                while (i < ntf.size() && std::isxdigit(ntf[i])) {
                    hex += ntf[i++];
                }
            }
            
            // Read optional numeric value (e.g. 0 or 1)
            int value = -1;
            if (i < ntf.size() && std::isdigit(ntf[i])) {
                value = 0;
                while (i < ntf.size() && std::isdigit(ntf[i])) {
                    value = value * 10 + (ntf[i++] - '0');
                }
            }
            
            if (!hex.empty()) {
                value = std::stoi(hex, nullptr, 16);
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
                format.fontSize = value != -1 ? static_cast<FontSize>((value / 2 - 4) % 8) : FontSize::Font14pt;
            }
            
            if (cmd == "ql") {
                format.align = Align::Left;
            }
            
            if (cmd == "qc") {
                format.align = Align::Center;
            }
            
            if (cmd == "qr") {
                format.align = Align::Right;
            }
            
            if (cmd == "li" && value != -1) {
                bullet = static_cast<Bullet>(value % 4);
            }
            
            if (cmd == "cf") {
                if (hex.empty()) {
                    format.foreground = value < colortbl.size() && value != -1 ? colortbl[value] : 0xFFFF;
                } else {
                    format.foreground = value;
                }
            }
            
            if (cmd == "cb" || cmd == "highlight") {
                if (hex.empty()) {
                    format.background = value < colortbl.size() && value != -1 ? colortbl[value] : 0xFFFF;
                } else {
                    format.background = value;
                }
            }
            
            if (cmd == "pict" && value != -1) {
                buffer.append("\\pict" + std::to_string(value));
            }

            // Skip optional space after control word
            if (i < ntf.size() && ntf[i] == ' ')
                i++;
        } else {
            buffer += ntf[i++];
        }
    }

    flush();
    return runs;
}

std::string ntf::richTextToNTF(const std::string& rtf)
{
    clearColorTable();
    colortbl = parseColorTable(rtf);

    std::string ntf = removeNonNestedGroups(rtf);

    // strip outer braces
    if (!ntf.empty() && ntf.front() == '{')
        ntf.erase(0, 1);
    if (!ntf.empty() && ntf.back() == '}')
        ntf.pop_back();
    
    normalizeNewlines(ntf);
    removeNewlines(ntf);

    normalizeParagraphs(ntf);
    rewriteFontSizes(ntf);

    return ntf;
}

std::string ntf::markdownToNTF(const std::string& md)
{
    std::string ntf = md;
    
    std::regex re;
    
    re = R"(#{4} (.*))";
    ntf = std::regex_replace(ntf, re, R"(\fs16\b1 $1\b0\fs14 )");
    
    re = R"(#{3} (.*))";
    ntf = std::regex_replace(ntf, re, R"(\fs18\b1 $1\b0\fs14 )");
    
    re = R"(#{2} (.*))";
    ntf = std::regex_replace(ntf, re, R"(\fs20\b1 $1\b0\fs14 )");
    
    re = R"(# (.*))";
    ntf = std::regex_replace(ntf, re, R"(\fs22\b1 $1\b0\fs14 )");
    
    re = R"(\*{2}(.*)\*{2})";
    ntf = std::regex_replace(ntf, re, R"(\b $1\b0 )");
    
    re = R"(\*(.*)\*)";
    ntf = std::regex_replace(ntf, re, R"(\i $1\i0 )");
    
    re = R"(~~(.*)~~)";
    ntf = std::regex_replace(ntf, re, R"(\strike $1\strike0 )");
    
    re = R"(==(.*)==)";
    ntf = std::regex_replace(ntf, re, R"(\cb8 $1\cb0 )");
    
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
        0xFFFF, 0x0000, 0x7FFF, 0x6318,
        0x4210, 0x294A, 0x7C00, 0x7E80,
        0x7FE0, 0x7F40, 0x03E0, 0x03FF,
        0x0076, 0x7C1F, 0x4000, 0x4200,
        0x0200, 0x0210, 0x027A
    };
}

void ntf::printRuns(const std::vector<TextRun>& runs)
{
    for (const auto& r : runs) {
        std::cerr
        << (r.style.bold ? "B" : "-") << (r.style.italic ? "I" : "-") << (r.style.underline ? "U" : "-") << (r.style.strikethrough ? "S" : "-") << (r.style.superscript ? "s" : "-") << (r.style.subscript ? "s" : "-")
        << " pt:" << (static_cast<int>(r.format.fontSize) + 4) * 2
        << " bg:#" << std::uppercase << std::setw(4) << std::hex << r.format.background << " fg:#" << r.format.foreground
        << std::dec
        << " " << (r.format.align == Align::Left ? "L" : (r.format.align == Align::Center ? "C" : "R"))
        << " " << (r.bullet == Bullet::None ? " " : (r.bullet == Bullet::Primary ? "●" : (r.bullet == Bullet::Secondary ? "○" : "▶")))
        << " \"" << r.text << "\" "
        << "\n";
    }
}
