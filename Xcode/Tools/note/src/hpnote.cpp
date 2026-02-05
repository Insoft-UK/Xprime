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
#include <bit>

using namespace hpnote;

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

static void applyFormat(const ntf::Format format, std::wstring& wstr) {
    uint32_t n = 0x1FE001FF;
    
    switch (format.fontSize) {
        case ntf::FontSize::Font22:
            n |= 7 << 15;
            break;
            
        case ntf::FontSize::Font20:
            n |= 6 << 15;
            break;
            
        case ntf::FontSize::Font18:
            n |= 5 << 15;
            break;
            
        case ntf::FontSize::Font16:
            n |= 4 << 15;
            break;
            
        case ntf::FontSize::Font14:
            n |= 3 << 15;
            break;
            
        case ntf::FontSize::Font12:
            n |= 2 << 15;
            break;
            
        case ntf::FontSize::Font10:
            n |= 1 << 15;
            break;
            
        default:
            break;
    }
    
    wstr.at(2) = n & 0xFFFF;
    wstr.at(3) = n >> 16;
    
    if (format.background != 0xFFFF) {
        if (format.foreground == 0xFFFF) {
            wstr.at(10) = L'0';
            if (format.background) {
                // MARK: Background (NONE BLACK)
                wstr.erase(6,1);
                wstr.at(6) = format.background;
            }
        } else {
            if (format.foreground && format.background ) {
                wstr.erase(8,1);
                wstr.at(4) = format.foreground;
                wstr.at(5) = format.background;
                wstr.at(7) = L'1';
                wstr.at(9) = L'0';
            }
            
            if (format.foreground == 0 && format.background == 0) {
                // MARK: Foreground & Background (BLACK)
                /// \o臿ῡ\0\0\1\0\0\0
                wstr.erase(8,1);
                wstr.insert(14, L"\\0");
            }
            
            if (format.foreground == 0 && format.background) {
                // MARK: Foreground (BLACK)
                /// \o臿ῡ\0簀\1\0\0\0
                wstr.at(6) = format.background;
                wstr.at(7) = L'\\';
                wstr.at(8) = L'1';
                wstr.at(10) = L'0';
            }
            
            if (format.foreground && format.background == 0) {
                // MARK: Background (BLACK)
                /// \oǿῠ簀\0\1\0\0\0x
                wstr.erase(8,1);
                wstr.insert(4, L"0");
                wstr.at(4) = format.foreground;
                wstr.at(8) = L'1';
                wstr.at(10) = L'0';
            }
        }
    } else if (format.foreground != 0xFFFF) {
        if (format.foreground) {
            wstr.at(4) = format.foreground;
            wstr.at(5) = L'\\';
            wstr.at(6) = L'0';
            wstr.at(7) = L'\\';
            wstr.at(8) = L'1';
        } else {
            wstr.at(8) = L'1';
            wstr.insert(8, L"\\");
        }
    }
}

static void applyStyle(const ntf::Style style, std::wstring& wstr) {
    if (style.bold) wstr.at(2) = wstr.at(2) | (1 << 10);
    if (style.italic) wstr.at(2) = wstr.at(2) | (1 << 11);
    if (style.underline) wstr.at(2) = wstr.at(2) | (1 << 12);
    if (style.strikethrough) wstr.at(2) = wstr.at(2) | (1 << 14);
}

static std::wstring parsePict(const std::string& str, int& lines)
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
    
    std::wstring black = LR"(\o臿ῠ\0\0Ā\0\0\0x\3\0   )";
    std::wstring color = LR"(\o臿ῠ\0纀Ā\0\0\0x\3\0   )";
    
    color.at(16) = '0' + static_cast<int>(pict.pixelWidth);
    color.resize(color.size() - (3 - static_cast<int>(pict.pixelWidth)));
    black.at(17) = '0' + static_cast<int>(pict.pixelWidth);
    black.resize(black.size() - (3 - static_cast<int>(pict.pixelWidth)));
    
    int i = 0;
    for (int y=0; y<pict.height; y++) {
        wstr.append(LR"(\0\)");
        wstr.append(toBase48(22));
        wstr.append(LR"(\0\0\0\0\)");
        wstr.append(toBase48(23));
        
        wstr.at(wstr.size() - 5) = toBase48(static_cast<uint64_t>(pict.align)).at(0);
        
        for (int x=0; x<pict.width; x++) {
            uint16_t c;
            if (pict.endian == ntf::Endian::Little) {
                c = std::byteswap(pict.pixels[i]);
            } else {
                c = pict.pixels[i];
            }
            if (c == 0) {
                wstr.append(black);
            } else {
                if (c == pict.keycolor)
                    c = 0xFFFF;
                color.at(6) = c;
                wstr.append(color);
            }
            
            i++;
        }
        wstr.append(LR"(\0)");
        
        lines++;
    }
    
    return wstr;
}

static std::wstring parseLine(const std::string& str)
{
    std::wstring wstr;
    
    auto runs = ntf::parseNTF(str);
    
#ifdef DEBUG
    static int lines = 0;
        std::cerr << ++lines << ":\n";
        ntf::printRuns(runs);
        std::cerr << "\n";
#endif
    
    wstr.append(LR"(\0\)");
    wstr.append(toBase48(22));
    wstr.append(LR"(\0\0\0\0\)");
    wstr.append(toBase48(23));
    
    if (!runs.size()) {
        std::wstring ws;
        ws = LR"(\oǿῠ\0\0Ā\1\0\0 \0\0\0)"; // Plain Text
        applyFormat(ntf::currentFormatState(), ws);
        applyStyle(ntf::currentStyleState(), ws);
        
        return wstr += ws;
    }
    
    for (const auto& r : runs) {
        wstr.at(9) = toBase48(static_cast<uint64_t>(r.format.align)).at(0);
        wstr.at(5) = toBase48(r.level).at(0);
        
        std::wstring ws;
        ws = LR"(\oǿῠ\0\0Ā\1\0\0 )"; // Plain Text
        
        applyFormat(r.format, ws);
        applyStyle(r.style, ws);
        
        wstr += ws;
        
        // Line length
        if (r.text.length() < 32) wstr.append(LR"(\)");
        wstr.append(toBase48(r.text.length() % 48));
        wstr.append(LR"(\0)");
        
        // Text
        wstr.append(utf::utf16(r.text));
    }
    wstr.append(LR"(\0)");
    
    return wstr;
}

static std::wstring parseAllLines(std::istringstream& iss) {
    std::string str;
    std::wstring wstr;
    
    ntf::reset();
    
    int lines = -1;
    while(getline(iss, str)) {
        if (str.substr(0, 5) == "\\pict") {
            wstr += parsePict(str, lines);
            continue;
        } else
            wstr += parseLine(str);
        
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

static std::wstring plainText(const std::string ntf) {
    std::wstring wstr;
    
    auto runs = ntf::parseNTF(ntf);
    
    for (const auto& r : runs) {
        wstr.append(utf::utf16(r.text));
    }
    
    return wstr;
}

std::wstring hpnote::ntfToHPNote(const std::string& ntf, bool minify) {
    std::wstring wstr;
    wstr.reserve(ntf.size() * 2);
    
    std::string input = ntf::extractPicts(ntf);
    
    if (!minify) {
        wstr.append(plainText(input));
    }
    
    wstr.push_back(L'\0');
    wstr += L"CSWD110\xFFFF\xFFFF\\l\x013E";
    
    std::istringstream iss(input);
    wstr += parseAllLines(iss);
    
    return wstr;
}
