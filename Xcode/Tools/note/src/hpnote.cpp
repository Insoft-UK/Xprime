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

static std::wstring parseLine(const std::string& str) {
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
    
    for (const auto& r : runs) {
        wstr.at(5) = toBase48(r.level).at(0);
        
        std::wstring ws;
        ws = LR"(\oǿῠ\0\0Ā\1\0\0 )"; // Plain Text
        
        uint32_t n = 0x1FE001FF;
        
        // MARK: - Bold & Italic
        
        if (r.style.bold) n |= 1 << 10;
        if (r.style.italic) n |= 1 << 11;
        if (r.style.underline) n |= 1 << 12;
        if (r.style.strikethrough) n |= 1 << 14;
        
        switch (r.format.fontSize) {
            case ntf::FONT22:
                n |= 7 << 15;
                break;
                
            case ntf::FONT20:
                n |= 6 << 15;
                break;
                
            case ntf::FONT18:
                n |= 5 << 15;
                break;
                
            case ntf::LARGE:
                n |= 4 << 15;
                break;
                
            case ntf::MEDIUM:
                n |= 3 << 15;
                break;
                
            case ntf::SMALL:
                n |= 2 << 15;
                break;
                
            case ntf::FONT10:
                n |= 1 << 15;
                break;
                
            default:
                break;
        }
        
        
        ws.at(2) = n & 0xFFFF;
        ws.at(3) = n >> 16;
        
        if (r.format.background != 0xFFFF) {
            if (r.format.foreground == 0xFFFF) {
                ws.erase(6,1);
                ws.at(6) = r.format.background;
                ws.at(9) = L'0';
            } else {
                ws.erase(8,1);
                ws.at(4) = r.format.foreground;
                ws.at(5) = r.format.background;
                ws.at(7) = L'1';
                ws.at(9) = L'0';
            }
        } else if (r.format.foreground != 0xFFFF) {
            ws.at(4) = r.format.foreground;
            ws.at(5) = L'\\';
            ws.at(6) = L'0';
            ws.at(7) = L'\\';
            ws.at(8) = L'1';
        }
        
        wstr += ws;
        
        // Line length
        if (r.text.length() < 32)  wstr.append(LR"(\)");
        wstr.append(toBase48(r.text.length()));
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
        wstr += parseLine(str);
        lines++;
    }
    
    // Footer control bytes
    wstr.append(LR"(\0\0\3\0\)");
    
    // Line count (base-48 style)
    wstr.append(toBase48((uint64_t)lines));
  
    // Footer control bytes
    wstr.append(LR"(\0\0\0\0\0\1\0)");
    
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

static std::wstring convertNTF(const std::string& ntf, bool minify) {
    std::wstring wstr;
    wstr.reserve(ntf.size() * 2);
    
    if (!minify) {
        wstr.append(plainText(ntf));
    }
    
    wstr.push_back(L'\0');
    wstr += L"CSWD110\xFFFF\xFFFF\\l\x013E";
    
    std::istringstream iss(ntf);
    wstr += parseAllLines(iss);
    
    return wstr;
}

std::wstring hpnote::ntfToHPNote(std::filesystem::path& path, bool minify) {
    std::wstring wstr;
    std::string ntf;
    
    std::string extension = path.extension().string();
    std::transform(extension.begin(), extension.end(), extension.begin(),
                   [](unsigned char c) { return std::tolower(c); });
    
    if (extension == ".md") {
        // Markdown is first converted to NoteText Format
        std::string md = utf::load(path);
        ntf = ntf::markdownToNTF(md);
    } else {
        ntf = utf::load(path);
    }
    
    return convertNTF(ntf, minify);
}
