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

#pragma once

#include <sstream>
#include <fstream>
#include <cstdlib>
#include <filesystem>

namespace utf {
    enum class BOM {
        le,
        be,
        none
    };
    
    enum class ReadMode
    {
        UntilNull,
        FullFile
    };

    std::string to_string(std::u16string_view s);
    
    std::string to_string(std::wstring_view s);
    [[deprecated("Use to_string instead")]]
    inline std::string utf8(std::wstring_view s) {
        return utf::to_string(s);
    }
    
    std::u16string to_u16string(std::string_view s);
    [[deprecated("Use utf::to_u16string instead")]]
    inline std::u16string u16(std::string_view s) {
        return utf::to_u16string(s);
    }
    
    std::u16string to_u16string(std::wstring_view s);
    [[deprecated("Use utf::to_u16string instead")]]
    inline std::u16string u16(std::wstring_view s) {
        return utf::to_u16string(s);
    }
    
    std::wstring to_wstring(std::string_view s);
    [[deprecated("Use to_wstring instead")]]
    inline std::wstring utf16(std::string_view s) {
        return utf::to_wstring(s);
    }
    
    std::wstring to_wstring(std::u16string_view s);
    [[deprecated("Use to_wstring instead")]]
    inline std::wstring utf16(std::u16string_view s) {
        return utf::to_wstring(s);
    }
    
    std::string read(std::ifstream& is);
    std::wstring read(std::ifstream& is, const BOM bom, bool eof = false);
    std::u16string read(std::ifstream& is, const ReadMode mode);
    
    std::string load(const std::filesystem::path& path);
    std::wstring load(const std::filesystem::path& path, const BOM bom, bool eof = false);
    std::u16string load(const std::filesystem::path& path, const ReadMode mode);
    
    size_t write(std::ofstream& os, std::string_view s);
    size_t write(std::ofstream& os, std::wstring_view s, const BOM bom = BOM::le);
    void write(std::ofstream& os, std::u16string_view data, const bool writeBOM = true);
    
    bool save(const std::filesystem::path& path, std::string_view s);
    bool save(const std::filesystem::path& path, std::wstring_view s, const BOM bom = BOM::le);
    bool save(const std::filesystem::path& path, std::u16string_view s, const bool writeBOM = true);
    
    BOM bom(std::ifstream& is);
    BOM bom(const std::filesystem::path& path);
    
    size_t size(std::string_view s);
    size_t size(std::wstring_view s);
    size_t size(std::u16string_view s);
};
