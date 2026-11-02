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

#include "DIMGROB_P.hpp"
#include "image.hpp"

#include <regex>
#include <fstream>
#include <sstream>
#include <vector>

using namespace image;

// A list is limited to 10,000 elements. Attempting to create a longer list will result in error 38 (Insufficient memory) being thrown.
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

namespace hpprime {
    std::string DIMGROB_P(Image image, const unsigned int grob) {
        if (image.colorType != ColourType::HighColour && image.colorType != ColourType::RGBA) {
            std::cerr << "Unsupported PNG colour type for DIMGROB_P!\n";
            return "";
        }
        
        std::ostringstream os;
        
        os << "DIMGROB_P("
        << "G" << grob << ","
        << image.width << ","
        << image.height << ","
        << "{" << formatPPLHexData(image.pixels) << "});";
        
        return os.str();
    }
}
