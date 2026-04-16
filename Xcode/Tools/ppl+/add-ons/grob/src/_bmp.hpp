// The MIT License (MIT)
//
// Copyright (c) 2024-2025 Insoft.
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

#ifndef bmp_hpp
#define bmp_hpp

#include <iostream>
#include <stdint.h>
#include <vector>

#ifndef __BITMAP_TYPE
#define __BITMAP_TYPE
typedef struct {
    uint16_t width;
    uint16_t height;
    uint8_t  bpp;
    std::vector<uint32_t> palette;
    std::vector<uint8_t> bytes;
} TBitmap;
#endif

/**
 @brief    Loads a file in the Bitmap (BMP) format.
 @param    filename The filename of the Bitmap (BMP) to be loaded.
 @return   A structure containing the bitmap image data.
 */
TBitmap loadBitmapImage(const std::string &filename);


#endif /* bmp_hpp */
