// The MIT License (MIT)
//
// Copyright (c) 2024-2025 Insoft. All rights reserved.
// Originally created in 2025
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

#include <filesystem>
#include <cstdint>
#include <vector>

namespace image {
    
    using Bytes = std::vector<std::uint8_t>;

    enum class ColourType : std::uint8_t {
        Grayscale      = 0,
        RGB            = 2,
        Indexed        = 3,
        GrayscaleAlpha = 4,
        RGBA           = 6,
        
        HighColour     = 7,  // ARGB1555 (16-bit),
        
        Unknown        = 255
    };
    
    typedef struct {
        int width;
        int height;
        
        ColourType colorType;
        uint8_t bitDepth; // bits per channel
        uint8_t bitCount;
        
        std::vector<uint32_t> palette; // RGBA palette entries
        std::vector<uint8_t> pixels;
    } Image;
    
    Image loadImage(const std::filesystem::path& path);
    bool saveImage(const std::filesystem::path& path, const Image& image);
}
