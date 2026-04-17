// The MIT License (MIT)
//
// Copyright (c) 2024-2025 Insoft.
//
// Created: 2025-05-27
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

#include "utf.hpp"

std::string utf::utf8(const std::wstring& wstr) {
    std::string utf8;
    uint16_t utf16 = 0;

    for (size_t i = 0; i < wstr.size(); i++) {
        utf16 = static_cast<uint16_t>(wstr[i]);

        if (utf16 <= 0x007F) {
            // 1-byte UTF-8: 0xxxxxxx
            utf8 += static_cast<char>(utf16 & 0x7F);
        } else if (utf16 <= 0x07FF) {
            // 2-byte UTF-8: 110xxxxx 10xxxxxx
            utf8 += static_cast<char>(0b11000000 | ((utf16 >> 6) & 0b00011111));
            utf8 += static_cast<char>(0b10000000 | (utf16 & 0b00111111));
        } else {
            // 3-byte UTF-8: 1110xxxx 10xxxxxx 10xxxxxx
            utf8 += static_cast<char>(0b11100000 | ((utf16 >> 12) & 0b00001111));
            utf8 += static_cast<char>(0b10000000 | ((utf16 >> 6) & 0b00111111));
            utf8 += static_cast<char>(0b10000000 | (utf16 & 0b00111111));
        }
    }

    return utf8;
}


std::wstring utf::utf16(const std::string& str) {
    std::wstring utf16;
    size_t i = 0;

    while (i < str.size()) {
        uint8_t byte1 = static_cast<uint8_t>(str[i]);

        if ((byte1 & 0b10000000) == 0) {
            // 1-byte UTF-8: 0xxxxxxx
            utf16 += static_cast<wchar_t>(byte1);
            i += 1;
        } else if ((byte1 & 0b11100000) == 0b11000000) {
            // 2-byte UTF-8: 110xxxxx 10xxxxxx
            if (i + 1 >= str.size()) break;
            uint8_t byte2 = static_cast<uint8_t>(str[i + 1]);

            uint16_t ch = ((byte1 & 0b00011111) << 6) |
                          (byte2 & 0b00111111);
            utf16 += static_cast<wchar_t>(ch);
            i += 2;
        } else if ((byte1 & 0b11110000) == 0b11100000) {
            // 3-byte UTF-8: 1110xxxx 10xxxxxx 10xxxxxx
            if (i + 2 >= str.size()) break;
            uint8_t byte2 = static_cast<uint8_t>(str[i + 1]);
            uint8_t byte3 = static_cast<uint8_t>(str[i + 2]);

            uint16_t ch = ((byte1 & 0b00001111) << 12) |
                          ((byte2 & 0b00111111) << 6) |
                          (byte3 & 0b00111111);
            utf16 += static_cast<wchar_t>(ch);
            i += 3;
        } else {
            // Invalid or unsupported UTF-8 sequence
            i += 1; // Skip it
        }
    }

    return utf16;
}


static uint16_t convertUTF8ToUTF16(const char* str) {
    uint8_t *utf8 = (uint8_t *)str;
    uint16_t utf16 = *utf8;
    
    if ((utf8[0] & 0b11110000) == 0b11100000) {
        utf16 = utf8[0] & 0b11111;
        utf16 <<= 6;
        utf16 |= utf8[1] & 0b111111;
        utf16 <<= 6;
        utf16 |= utf8[2] & 0b111111;
        return utf16;
    }
    
    // 110xxxxx 10xxxxxx
    if ((utf8[0] & 0b11100000) == 0b11000000) {
        utf16 = utf8[0] & 0b11111;
        utf16 <<= 6;
        utf16 |= utf8[1] & 0b111111;
        return utf16;
    }
    
    return utf16;
}


std::wstring utf::read(std::ifstream& is, BOM bom) {
    std::wstring wstr;
    uint16_t byte_order_mark;
    
    is.read(reinterpret_cast<char*>(&byte_order_mark), sizeof(byte_order_mark));
    
#ifdef __BIG_ENDIAN__
    if (bom == BOMle && byte_order_mark != 0xFFFE) {
        utf16 = utf16 >> 8 | utf16 << 8;
    }
    if (bom == BOMbe && byte_order_mark != 0xFEFF) {
        utf16 = utf16 >> 8 | utf16 << 8;
    }
#else
    if (bom == BOMle && byte_order_mark != 0xFEFF) {
        return wstr;
    }
    if (bom == BOMbe && byte_order_mark != 0xFFFE) {
        return wstr;
    }
#endif
    
    while (true) {
        char16_t ch;
        // Read 2 bytes (UTF-16)
        is.read(reinterpret_cast<char*>(&ch), sizeof(ch));
        
        if (!is || ch == 0x0000) {
            break; // EOF or null terminator
        }
        
        wstr += static_cast<wchar_t>(ch);
        is.peek();
        if (is.eof()) break;
    }
    
    return wstr;
}

std::wstring utf::load(const std::filesystem::path& path, BOM bom) {
    std::wstring wstr;
    std::ifstream is;
    
    is.open(path, std::ios::in | std::ios::binary);
    if(!is.is_open()) return wstr;

    wstr = read(is, bom);
    
    is.close();
    return wstr;
}


size_t utf::write(std::ofstream& os, const std::string& str) {
    if (str.empty()) return 0;

    os.write(str.data(), str.size());
    return os.tellp();
}


size_t utf::write(std::ofstream& os, const std::wstring& wstr, BOM bom) {
    if (wstr.empty()) return 0;
    
    if (bom == BOMle) {
        os.put(0xFF);
        os.put(0xFE);
    }
    
    if (bom == BOMbe) {
        os.put(0xFE);
        os.put(0xFF);
    }
    
    std::string str = utf8(wstr);
    
    
    size_t size = 0;
    for ( int n = 0; n < str.length(); n++, size += 2) {
        uint8_t *ascii = (uint8_t *)&str.at(n);
        if (str.at(n) == '\r') continue;
        
        // Output as UTF-16LE
        if (*ascii >= 0x80) {
            uint16_t utf16 = convertUTF8ToUTF16(&str.at(n));
            
#ifndef __LITTLE_ENDIAN__
            if (bom == BOMle) {
                utf16 = utf16 >> 8 | utf16 << 8;
            }
#else
            if (bom == BOMbe) {
                utf16 = utf16 >> 8 | utf16 << 8;
            }
#endif
            os.write((const char *)&utf16, 2);
            if ((*ascii & 0b11100000) == 0b11000000) n++;
            if ((*ascii & 0b11110000) == 0b11100000) n+=2;
            if ((*ascii & 0b11111000) == 0b11110000) n+=3;
        } else {
            os.put(str.at(n));
            os.put('\0');
        }
    }
    return size;
}


bool utf::save(const std::filesystem::path& path, const std::string& str) {
    std::ofstream os;
    
    os.open(path, std::ios::out | std::ios::binary);
    if(!os.is_open()) return false;
    
    write(os, str);
    
    os.close();
    return true;
}

bool utf::save(const std::filesystem::path& path, const std::wstring& wstr, BOM bom) {
    std::ofstream os;
    
    os.open(path, std::ios::out | std::ios::binary);
    if(!os.is_open()) return false;
    
    write(os, wstr, bom);
    
    os.close();
    return true;
}
