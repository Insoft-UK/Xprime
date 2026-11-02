// The MIT License (MIT)
//
// Copyright (c) 2024-2026 Insoft. All rights reserved.
// Originally created in 2026
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

#ifndef PNG_HPP
#define PNG_HPP

#include <cstdint>
#include <vector>

namespace PNG {
    using Bytes = std::vector<std::uint8_t>;

    enum class ColourType : std::uint8_t {
        Greyscale      = 0,
        RGB            = 2,
        Indexed        = 3,
        GreyscaleAlpha = 4,
        RGBA           = 6,
        Unknown        = 255
    };
    
    ColourType getColourType(const Bytes& png);
    
    // Inverts the alpha channel of an 8-bit RGBA PNG (colour type 6).
    // Supports non-interlaced PNG files.
    // Throws std::runtime_error if the PNG is invalid or unsupported.
    void invertRGBAAlpha(Bytes& png);
    
    void invertPNGTransparency(Bytes& data);
    
} // namespace PNG

#endif // PNG_HPP
