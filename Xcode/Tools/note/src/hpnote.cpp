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
#include "md.hpp"
#include "utf.hpp"

/*
 B 0000 01xx - xxxx xxxx
 I 0000 10xx - xxxx xxxx
 U 0001 00xx - xxxx xxxx
 S 0100 00xx - xxxx xxxx

 BIUS
   0101 1101

   0011 0000
 ● 0011 0001
 ○ 0011 0010
 ‣ 0011 0011

 Align
 L 0011 0000
 C 0011 0001
 R 0011 0010
 
 Font Size le
 10 1110 0000 - 1000 0001
 12 1110 0001 - 0000 0001
 14 1110 0000 - 0000 0001
 16 1110 0010 - 0000 0001
 18 1110 0010 - 1000 0001
 20 1110 0011 - 0000 0001
 22 1110 0011 - 1000 0001
 
 Foreground le
 R 0000 0000 - 0111 1100
 G 1110 0000 - 0000 0011
 B 0101 1100 - 0000 0000
 W 1111 1111 - 0111 1111
 
 :B:I
 */

using namespace hpnote;

//// Convert "#RRGGBB" or "RRGGBB" to ARGB1555 uint16_t
//static uint16_t parseColorARGB1555(const std::string& hex) {
//    std::string s = hex;
//    if (!s.empty() && s[0] == '#') s = s.substr(1);
//    if (s.size() != 6) throw std::invalid_argument("Invalid color string");
//
//    // Parse RGB as integers
//    unsigned int r, g, b;
//    std::istringstream(s.substr(0,2)) >> std::hex >> r;
//    std::istringstream(s.substr(2,2)) >> std::hex >> g;
//    std::istringstream(s.substr(4,2)) >> std::hex >> b;
//
//    // Convert 8-bit to 5-bit
//    uint16_t r5 = (r * 31 + 127) / 255;
//    uint16_t g5 = (g * 31 + 127) / 255;
//    uint16_t b5 = (b * 31 + 127) / 255;
//
//    // Compose ARGB1555
//    uint16_t color = 0;
//    color |= (r5 & 0x1F) << 10;
//    color |= (g5 & 0x1F) << 5;
//    color |= (b5 & 0x1F);
//
//    return color;
//}

//static std::vector<std::string> splitPreservingSpaces(const std::string& line)
//{
//    std::vector<std::string> result;
//    std::string current;
//
//    for (char c : line)
//    {
//        if (c == ' ')
//        {
//            // Flush current word if any
//            if (!current.empty())
//            {
//                result.push_back(current);
//                current.clear();
//            }
//
//            // Each space is its own entry
//            result.emplace_back(" ");
//        }
//        else
//        {
//            current += c;
//        }
//    }
//
//    // Flush final word
//    if (!current.empty())
//    {
//        result.push_back(current);
//    }
//
//    return result;
//}

static std::wstring parseLine(const std::string& str) {
    std::wstring wstr;
    
    auto tokens = md::parseMarkdown(str);
#ifdef DEBUG
    md::printTokens(tokens);
#endif
    
    for (const auto& t : tokens) {
        wstr += LR"(\0\m\)";
        wstr += L'0' + t.bulletLevel;
        wstr += LR"(\0\0\0\n)";
        
            {
                std::wstring ws;
                ws = LR"(\oǿῠ\0\0ā\1\0\0 \)"; // Plain Text
                // f = LR"(\oǿῠ\0罀ā\0\0\0 \)" b = LR"(\oǿῠ簀\0\1\1\0\0 \")  bf = LR"(\oǿῠ簀罀\1\0\0\0 \")
                // bfB22 LR"(\o藿ΰ簀罀\0\0\0\0 ")
                uint32_t n = 0x1FE001FF;
                
                // MARK: - Bold & Italic
                
                switch (t.style) {
                    case md::Style::Highlight:
                        ws.at(7) = L'罀';
                        ws.at(10) = L'0';
                        ws.erase(6, 1);
                        break;
                        
                    case md::Style::Bold:
                        n |= 1 << 10;
                        break;
                        
                    case md::Style::Italic:
                        n |= 1 << 11;
                        break;
                        
                    case md::Style::Strikethrough:
                        n |= 1 << 14;
                        break;
                        
                    case md::Style::BoldItalic:
                        n |= 3 << 10;
                        break;
                        
                    case md::Style::Heading1:
                        n |= 1 << 10;
                        n |= 7 << 15;
                        ws.at(8) = L'Ā';
                        break;
                        
                    case md::Style::Heading2:
                        n |= 1 << 10;
                        n |= 6 << 15;
                        ws.at(8) = L'Ā';
                        break;
                        
                    case md::Style::Heading3:
                        n |= 1 << 10;
                        n |= 5 << 15;
                        ws.at(8) = L'Ā';
                        break;
                        
                    case md::Style::Heading4:
                        n |= 1 << 10;
                        n |= 4 << 15;
                        ws.at(8) = L'Ā';
                        break;
                        
                    default:
                        break;
                }
                
                
                ws.at(2) = n & 0xFFFF;
                ws.at(3) = n >> 16;
                
                wstr += ws;
            }
        
            if (t.text.length() > 9) {
                wstr.append(1, static_cast<wchar_t>(87 + t.text.length()));
            } else {
                wstr.append(1, static_cast<wchar_t>(48 + t.text.length()));
            }
            wstr += LR"(\0)";
        
            wstr += utf::utf16(t.text);
            wstr += LR"(\0)";
    }
    
    
    
    return wstr;
}

static std::wstring parseAllLines(std::istringstream& iss) {
    std::string str;
    std::wstring wstr;
    
    int lines = -1;
    while(getline(iss, str)) {
        wstr += parseLine(str);
        lines++;
    }
    
    wstr += LR"(\0\0\3\0\)";
    
    if (lines > 9) {
        wstr.append(1, static_cast<wchar_t>(87 + lines));
    } else {
        wstr.append(1, static_cast<wchar_t>(48 + lines));
    }
    
    wstr += LR"(\0\0\0\0\0\1\0)";

    return wstr;
}

std::wstring hpnote::convertToHpNote(std::filesystem::path& path, bool minify) {
    std::string input;
    std::wstring wstr;
    std::vector<uint8_t> bytes;
    
    
    input = utf::load(path);

    if (!minify) {
        auto tokens = md::parseMarkdown(input);
        for (const auto& t : tokens) {
            if (!wstr.empty()) wstr.append(1, L'\n');
            wstr.append(utf::utf16(t.text));
        }
    }
    
    wstr.append(1, L'\0');
    wstr += LR"(CSWD110￿￿\lľ)";
    
    std::istringstream iss;
    iss.str(input);

    wstr += parseAllLines(iss);

    
    return wstr;
}
