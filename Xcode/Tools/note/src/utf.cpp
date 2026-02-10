// The MIT License (MIT)
//
// Copyright (c) 2025-2026 Insoft.
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

std::string utf::utf8(const std::wstring& ws)
{
    std::string utf8;
    uint16_t utf16 = 0;

    for (size_t i = 0; i < ws.size(); i++) {
        utf16 = static_cast<uint16_t>(ws[i]);

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

std::wstring utf::utf16(const std::string& s)
{
    std::wstring utf16;
    size_t i = 0;

    while (i < s.size()) {
        uint8_t byte1 = static_cast<uint8_t>(s[i]);

        if ((byte1 & 0b10000000) == 0) {
            // 1-byte UTF-8: 0xxxxxxx
            utf16 += static_cast<wchar_t>(byte1);
            i += 1;
        } else if ((byte1 & 0b11100000) == 0b11000000) {
            // 2-byte UTF-8: 110xxxxx 10xxxxxx
            if (i + 1 >= s.size()) break;
            uint8_t byte2 = static_cast<uint8_t>(s[i + 1]);

            uint16_t ch = ((byte1 & 0b00011111) << 6) |
                          (byte2 & 0b00111111);
            utf16 += static_cast<wchar_t>(ch);
            i += 2;
        } else if ((byte1 & 0b11110000) == 0b11100000) {
            // 3-byte UTF-8: 1110xxxx 10xxxxxx 10xxxxxx
            if (i + 2 >= s.size()) break;
            uint8_t byte2 = static_cast<uint8_t>(s[i + 1]);
            uint8_t byte3 = static_cast<uint8_t>(s[i + 2]);

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

std::wstring utf::utf16(const std::u16string& u16s)
{
#if WCHAR_MAX == 0xFFFF
    // Windows: wchar_t is UTF-16
    return std::wstring(u16s.begin(), u16s.end());
#else
    // macOS/Linux: wchar_t is UTF-32, need surrogate pair decoding
    std::wstring out;
    out.reserve(u16s.size());

    for (size_t i = 0; i < u16s.size(); ++i) {
        char16_t c = u16s[i];

        // Check for high surrogate
        if (c >= 0xD800 && c <= 0xDBFF && i + 1 < u16s.size()) {
            char16_t low = u16s[++i];
            if (low >= 0xDC00 && low <= 0xDFFF) {
                char32_t codepoint =
                    ((c - 0xD800) << 10) + (low - 0xDC00) + 0x10000;
                out.push_back(static_cast<wchar_t>(codepoint));
                continue;
            }
        }

        // BMP character
        out.push_back(static_cast<wchar_t>(c));
    }

    return out;
#endif
}

std::u16string utf::u16(const std::string& s)
{
    auto ws = utf16(s);
    return u16(ws);
}

std::u16string utf::u16(const std::wstring& ws)
{
#if WCHAR_MAX == 0xFFFF
    // Windows: wchar_t is UTF-16
    return std::u16string(ws.begin(), ws.end());
#else
    // macOS/Linux: wchar_t is UTF-32
    std::u16string out;
    out.reserve(ws.size());

    for (wchar_t wc : ws) {
        char32_t cp = static_cast<char32_t>(wc);

        if (cp <= 0xFFFF) {
            // BMP character
            out.push_back(static_cast<char16_t>(cp));
        } else {
            // Non-BMP character → surrogate pair
            cp -= 0x10000;
            out.push_back(static_cast<char16_t>(0xD800 + (cp >> 10)));
            out.push_back(static_cast<char16_t>(0xDC00 + (cp & 0x3FF)));
        }
    }

    return out;
#endif
}

static uint16_t convertUTF8ToUTF16(const char* s)
{
    uint8_t *utf8 = (uint8_t *)s;
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

std::string utf::read(std::ifstream& is)
{
    if (!is) throw std::runtime_error("Cannot open file");

    std::string str((std::istreambuf_iterator<char>(is)),
                              std::istreambuf_iterator<char>());
    
    return str;
}

std::wstring utf::read(std::ifstream& is, BOM bom, bool eof)
{
    if (bom != BOMnone) {
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
            return L"";
        }
        if (bom == BOMbe && byte_order_mark != 0xFFFE) {
            return L"";
        }
#endif
    }
    
    std::wstring out;
    
    while (true) {
        char16_t ch;
        // Read 2 bytes (UTF-16)
        is.read(reinterpret_cast<char*>(&ch), sizeof(ch));
        
        if ((!is || ch == 0x0000) && eof == false) {
            break; // EOF or null terminator
        }
        
        out += static_cast<wchar_t>(ch);
        is.peek();
        if (is.eof()) break;
    }
    
    return out;
}

std::string utf::load(const std::filesystem::path& path)
{
    std::string str;
    std::ifstream is;
    
    is.open(path, std::ios::in | std::ios::binary);
    if(!is.is_open()) return str;

    str = read(is);
    
    is.close();
    return str;
}


std::wstring utf::load(const std::filesystem::path& path, BOM bom, bool eof)
{
    std::wstring ws;
    std::ifstream is;
    
    is.open(path, std::ios::in | std::ios::binary);
    if(!is.is_open()) return ws;

    ws = read(is, bom, eof);
    
    is.close();
    return ws;
}

size_t utf::write(std::ofstream& os, const std::string& s)
{
    if (s.empty()) return 0;

    os.write(s.data(), s.size());
    return os.tellp();
}


size_t utf::write(std::ofstream& os, const std::wstring& ws, BOM bom)
{
    if (ws.empty()) return 0;
    
    if (bom == BOMle) {
        os.put(0xFF);
        os.put(0xFE);
    }
    
    if (bom == BOMbe) {
        os.put(0xFE);
        os.put(0xFF);
    }
    
    std::string s = utf8(ws);
    
    size_t size = 0;
    for ( int n = 0; n < s.length(); n++, size += 2) {
        uint8_t *ascii = (uint8_t *)&s.at(n);
        if (s.at(n) == '\r') continue;
        
        // Output as UTF-16LE
        if (*ascii >= 0x80) {
            uint16_t utf16 = convertUTF8ToUTF16(&s.at(n));
            
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
            os.put(s.at(n));
            os.put('\0');
        }
    }
    
    return size;
}

bool utf::save(const std::filesystem::path& path, const std::string& s)
{
    std::ofstream os;
    
    os.open(path, std::ios::out | std::ios::binary);
    if(!os.is_open()) return false;
    
    write(os, s);
    
    os.close();
    return true;
}

bool utf::save(const std::filesystem::path& path, const std::wstring& ws, BOM bom)
{
    std::ofstream os;
    
    os.open(path, std::ios::out | std::ios::binary);
    if(!os.is_open()) return false;
    
    write(os, ws, bom);
    
    os.close();
    return true;
}

utf::BOM utf::bom(std::ifstream& is)
{
    if(!is.is_open()) return BOMnone;
    
    uint16_t byte_order_mark;
    
    is.read(reinterpret_cast<char*>(&byte_order_mark), sizeof(byte_order_mark));
    is.seekg(std::ios_base::beg);
    
#ifdef __BIG_ENDIAN__
    if (byte_order_mark == 0xFFFE) {
        return BOMle;
    }
    if (byte_order_mark == 0xFEFF) {
        return BOMbe;
    }
#else
    if (byte_order_mark == 0xFFFE) {
        return BOMbe;
    }
    if (byte_order_mark == 0xFEFF) {
        return BOMle;
    }
#endif
    
    return BOMnone;
}

utf::BOM utf::bom(const std::filesystem::path& path)
{
    std::ifstream is;
    
    is.open(path, std::ios::in | std::ios::binary);
    if(!is.is_open()) return utf::BOMnone;
    
    utf::BOM bom = utf::bom(is);
    is.close();
    
    return bom;
}

size_t utf::size(const std::string& s)
{
    size_t count = 0;
    for (unsigned char c : s) {
        if ((c & 0b1100'0000) != 0b1000'0000) {
            ++count; // start of a UTF-8 code point
        }
    }
    return count;
}

size_t utf::size(const std::wstring& ws)
{
#if WCHAR_MAX == 0xFFFF
    // Windows → UTF-16
    size_t count = 0;
    for (size_t i = 0; i < ws.size(); ++i) {
        wchar_t c = s[i];
        // count only non-surrogate code units
        if (c < 0xD800 || c > 0xDBFF) {
            ++count;
        }
    }
    return count;
#else
    // Linux/macOS → UTF-32
    return ws.size();
#endif
}

size_t utf::size(const std::u16string& u16s)
{
    size_t count = 0;

    for (size_t i = 0; i < u16s.size(); ++i) {
        char16_t c = u16s[i];

        // If this is a high surrogate and followed by a low surrogate,
        // consume both but count only once
        if (c >= 0xD800 && c <= 0xDBFF) {
            if (i + 1 < u16s.size()) {
                char16_t low = u16s[i + 1];
                if (low >= 0xDC00 && low <= 0xDFFF) {
                    ++i; // skip low surrogate
                }
            }
        }

        ++count;
    }

    return count;
}

