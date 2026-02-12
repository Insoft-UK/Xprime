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

#include <vector>

namespace utf {
    std::string to_string(std::u16string_view s)
    {
        return to_string(to_wstring(s));
    }
    
    std::string to_string(std::wstring_view s)
    {
        std::string utf8;
        uint16_t utf16 = 0;
        
        for (size_t i = 0; i < s.size(); i++) {
            utf16 = static_cast<uint16_t>(s[i]);
            
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
    
    std::u16string to_u16string(std::string_view s)
    {
        return to_u16string(to_wstring(s));
    }
    
    std::u16string to_u16string(std::wstring_view s)
    {
#if WCHAR_MAX == 0xFFFF
        // Windows: wchar_t is UTF-16
        return std::u16string(ws.begin(), ws.end());
#else
        // macOS/Linux: wchar_t is UTF-32
        std::u16string out;
        out.reserve(s.size());
        
        for (wchar_t wc : s) {
            char32_t c32 = static_cast<char32_t>(wc);
            
            if (c32 <= 0xFFFF) {
                // BMP character
                out.push_back(static_cast<char16_t>(c32));
            } else {
                // Non-BMP character → surrogate pair
                c32 -= 0x10000;
                out.push_back(static_cast<char16_t>(0xD800 + (c32 >> 10)));
                out.push_back(static_cast<char16_t>(0xDC00 + (c32 & 0x3FF)));
            }
        }
        
        return out;
#endif
    }
    
    std::wstring to_wstring(std::string_view s)
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
    
    std::wstring to_wstring(std::u16string_view s)
    {
#if WCHAR_MAX == 0xFFFF
        // Windows: wchar_t is UTF-16
        return std::wstring(s.begin(), s.end());
#else
        // macOS/Linux: wchar_t is UTF-32, need surrogate pair decoding
        std::wstring out;
        out.reserve(s.size());
        
        for (size_t i = 0; i < s.size(); ++i) {
            char16_t c = s[i];
            
            // Check for high surrogate
            if (c >= 0xD800 && c <= 0xDBFF && i + 1 < s.size()) {
                char16_t low = s[++i];
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
    
    std::string read(std::ifstream& is)
    {
        if (!is) throw std::runtime_error("Cannot open file");
        
        std::string str((std::istreambuf_iterator<char>(is)),
                        std::istreambuf_iterator<char>());
        
        return str;
    }
    
    std::wstring read(std::ifstream& is, const BOM bom, bool eof)
    {
        if (bom != BOM::none) {
            uint16_t byte_order_mark;
            
            is.read(reinterpret_cast<char*>(&byte_order_mark), sizeof(byte_order_mark));
            
#ifdef __BIG_ENDIAN__
            if (bom == BOM::le && byte_order_mark != 0xFFFE) {
                utf16 = utf16 >> 8 | utf16 << 8;
            }
            if (bom == BOM::be && byte_order_mark != 0xFEFF) {
                utf16 = utf16 >> 8 | utf16 << 8;
            }
#else
            if (bom == BOM::le && byte_order_mark != 0xFEFF) {
                return L"";
            }
            if (bom == BOM::be && byte_order_mark != 0xFFFE) {
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
    
    std::u16string read(std::ifstream& is, const ReadMode mode)
    {
        if (!is)
            throw std::runtime_error("Input stream is not open");
        
        // Read file into a byte buffer
        is.seekg(0, std::ios::end);
        std::streamsize size = is.tellg();
        if (size < 0) throw std::runtime_error("Failed to determine file size");
        is.seekg(0, std::ios::beg);
        
        // UTF-16 uses 2 bytes per character
        if (size % 2 != 0)
            throw std::runtime_error("File size is not a multiple of 2 (invalid UTF-16)");
        
        std::vector<char16_t> buffer(size / 2);
        is.read(reinterpret_cast<char*>(buffer.data()), size);
        
        if (!is)
            throw std::runtime_error("Failed to read entire file");
        
        std::u16string result;
        
        if (mode == ReadMode::FullFile)
        {
            result.assign(buffer.begin(), buffer.end());
        }
        else // UntilNull
        {
            for (char16_t c : buffer)
            {
                if (c == u'\0')
                    break;
                result.push_back(c);
            }
        }
        
        return result;
    }
    
    std::string load(const std::filesystem::path& path)
    {
        std::string str;
        std::ifstream is;
        
        is.open(path, std::ios::in | std::ios::binary);
        if(!is.is_open()) return str;
        
        str = read(is);
        
        is.close();
        return str;
    }
    
    
    std::wstring load(const std::filesystem::path& path, const BOM bom, bool eof)
    {
        std::wstring ws;
        std::ifstream is;
        
        is.open(path, std::ios::in | std::ios::binary);
        if(!is.is_open()) return ws;
        
        ws = read(is, bom, eof);
        
        is.close();
        return ws;
    }
    
    std::u16string load(const std::filesystem::path& path, const ReadMode mode)
    {
        std::u16string s;
        std::ifstream is;
        
        is.open(path, std::ios::in | std::ios::binary);
        if(!is.is_open()) return s;
        
        s = read(is, mode);
        
        is.close();
        return s;
    }
    
    size_t write(std::ofstream& os, std::string_view s)
    {
        if (s.empty()) return 0;
        
        os.write(s.data(), s.size());
        return os.tellp();
    }
    
    
    size_t write(std::ofstream& os, std::wstring_view s, BOM bom)
    {
        if (s.empty()) return 0;
        
        if (bom == BOM::le) {
            os.put(0xFF);
            os.put(0xFE);
        }
        
        if (bom == BOM::be) {
            os.put(0xFE);
            os.put(0xFF);
        }
        
        std::string utf8 = to_string(s);
        
        size_t size = 0;
        for ( int n = 0; n < utf8.length(); n++, size += 2) {
            uint8_t *ascii = (uint8_t *)&utf8.at(n);
            if (utf8.at(n) == '\r') continue;
            
            // Output as UTF-16LE
            if (*ascii >= 0x80) {
                uint16_t utf16 = convertUTF8ToUTF16(&utf8.at(n));
                
#ifndef __LITTLE_ENDIAN__
                if (bom == BOM::le) {
                    utf16 = utf16 >> 8 | utf16 << 8;
                }
#else
                if (bom == BOM::be) {
                    utf16 = utf16 >> 8 | utf16 << 8;
                }
#endif
                os.write((const char *)&utf16, 2);
                if ((*ascii & 0b11100000) == 0b11000000) n++;
                if ((*ascii & 0b11110000) == 0b11100000) n+=2;
                if ((*ascii & 0b11111000) == 0b11110000) n+=3;
            } else {
                os.put(utf8.at(n));
                os.put('\0');
            }
        }
        
        return size;
    }
    
    void write(std::ofstream& os, std::u16string_view data, const bool writeBOM)
    {
        // Write BOM (UTF-16 little-endian by default)
        if (writeBOM)
        {
            char16_t bom = 0xFEFF;
            os.write(reinterpret_cast<const char*>(&bom), sizeof(bom));
        }
        
        // Write UTF-16 data
        os.write(reinterpret_cast<const char*>(data.data()), data.size() * sizeof(char16_t));
        
        if (!os)
            throw std::runtime_error("Failed to write data to file");
    }
    
    bool save(const std::filesystem::path& path, std::string_view s)
    {
        std::ofstream os;
        
        os.open(path, std::ios::out | std::ios::binary);
        if(!os.is_open()) return false;
        
        write(os, s);
        
        os.close();
        return true;
    }
    
    bool save(const std::filesystem::path& path, std::wstring_view s, const BOM bom)
    {
        std::ofstream os;
        
        os.open(path, std::ios::out | std::ios::binary);
        if(!os.is_open()) return false;
        
        write(os, s, bom);
        
        os.close();
        return true;
    }
    
    bool save(const std::filesystem::path& path, std::u16string_view s, const bool writeBOM)
    {
        std::ofstream os(path, std::ios::binary);
        if (!os)
            throw std::runtime_error("Cannot open file for writing");
        
        write(os, s, writeBOM);
        
        os.close();
        return true;
    }
    
    BOM bom(std::ifstream& is)
    {
        if(!is.is_open()) return BOM::none;
        
        uint16_t byte_order_mark;
        
        is.read(reinterpret_cast<char*>(&byte_order_mark), sizeof(byte_order_mark));
        is.seekg(std::ios_base::beg);
        
#ifdef __BIG_ENDIAN__
        if (byte_order_mark == 0xFFFE) {
            return BOM::le;
        }
        if (byte_order_mark == 0xFEFF) {
            return BOM::be;
        }
#else
        if (byte_order_mark == 0xFFFE) {
            return BOM::be;
        }
        if (byte_order_mark == 0xFEFF) {
            return BOM::le;
        }
#endif
        
        return BOM::none;
    }
    
    BOM bom(const std::filesystem::path& path)
    {
        std::ifstream is;
        
        is.open(path, std::ios::in | std::ios::binary);
        if(!is.is_open()) return BOM::none;
        
        BOM b = bom(is);
        is.close();
        
        return b;
    }
    
    size_t size(std::string_view s)
    {
        size_t count = 0;
        for (unsigned char c : s) {
            if ((c & 0b1100'0000) != 0b1000'0000) {
                ++count; // start of a UTF-8 code point
            }
        }
        return count;
    }
    
    size_t size(std::wstring_view s)
    {
#if WCHAR_MAX == 0xFFFF
        // Windows → UTF-16
        size_t count = 0;
        for (size_t i = 0; i < s.size(); ++i) {
            wchar_t c = s[i];
            // count only non-surrogate code units
            if (c < 0xD800 || c > 0xDBFF) {
                ++count;
            }
        }
        return count;
#else
        // Linux/macOS → UTF-32
        return s.size();
#endif
    }
    
    size_t size(std::u16string_view s)
    {
        size_t count = 0;
        
        for (size_t i = 0; i < s.size(); ++i) {
            char16_t c = s[i];
            
            // If this is a high surrogate and followed by a low surrogate,
            // consume both but count only once
            if (c >= 0xD800 && c <= 0xDBFF) {
                if (i + 1 < s.size()) {
                    char16_t low = s[i + 1];
                    if (low >= 0xDC00 && low <= 0xDFFF) {
                        ++i; // skip low surrogate
                    }
                }
            }
            
            ++count;
        }
        
        return count;
    }
};

