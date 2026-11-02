// The MIT License (MIT)
//
// Copyright (c) 2023-2026 Insoft.
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

#include "GROB.hpp"

#include <png.h>

#include <fstream>
#include <sstream>
#include <regex>

using namespace image;

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

static std::string formatPPLHexData(const std::vector<uint8_t>& bytes) {
    std::ostringstream os;
    size_t length = bytes.size();
    uint64_t *data = (uint64_t *)bytes.data();
    
    for (;length >= 8; length-=8) {
        if (length != bytes.size()) os << ",";
        os << "#" << std::uppercase << std::hex << std::setfill('0') << std::setw(16) << *data++ << ":64h";
    }
    return os.str();
}

static std::string generatePPLCode(const Image& image) {
    std::string utf8;
    std::ostringstream os;
    
    switch (image.bitCount) {
        case 1:
            os
            << "{\n"
            << "  {" << formatPPLHexData(image.pixels) << "},\n"
            << "  {" << std::dec << std::to_string(image.width) << "," << std::to_string(image.height) << "," << std::to_string(image.bitCount) << "},\n"
            << "  {#FFFFFF:32h,#000000:32h}\n}";
            
            utf8.append(os.str());
            break;
            
        case 4:
        case 8:
            os
            << "{\n"
            << "  {" << formatPPLHexData(image.pixels) << "},\n"
            << "  {" << std::dec << std::to_string(image.width) << "," << std::to_string(image.height) << "," << std::to_string(image.bitCount) << "},\n"
            << "  {";
            for (int i = 0; i < image.palette.size(); i += 1) {
                uint32_t color = image.palette.at(i);
#ifdef __LITTLE_ENDIAN__
                color = std::byteswap(color);
#endif
                color &= 0xFFFFFF;
                if (i) os << ",";
                
                os << "#" << std::uppercase << std::hex << std::setfill('0') << std::setw(6) << color << ":32h";
            }
            os << "}\n}";
            
            utf8.append(os.str());
            break;
            
        case 16:
        case 32:
            os
            << "{\n"
            << "  {" << formatPPLHexData(image.pixels) << "},\n"
            << "  {" << std::dec << std::to_string(image.width) << ", " << std::to_string(image.height) << "}\n"
            << "}";
            
            utf8.append(os.str());
            break;
            
        default:
            utf8 += "{" + formatPPLHexData(image.pixels) + "}";
            break;
    }
    
    return utf8;
}

static std::string replaceAllOccurrences(std::string text,
                                         const std::string& from,
                                         const std::string& to)
{
    if (from.empty()) return text;
    
    size_t pos = 0;
    while ((pos = text.find(from, pos)) != std::string::npos)
    {
        text.replace(pos, from.length(), to);
        pos += to.length();
    }
    
    return text;
}

static std::string convertPPLToPython(const std::string& str) {
    std::string out = str;
    
    out = replaceAllOccurrences(out, "#", "0x");
    out = regex_replace(out, std::regex(R"(:\d+h)"), "");
    out = replaceAllOccurrences(out, "{", "[");
    out = replaceAllOccurrences(out, "}", "]");

    return out;
}

namespace hpprime {
    std::string GROB(Image image, const Language language) {
        auto output = generatePPLCode(image);
        
        if (language == Language::Python)
            output = convertPPLToPython(output);
        
        return generatePPLCode(image);
    }
}
