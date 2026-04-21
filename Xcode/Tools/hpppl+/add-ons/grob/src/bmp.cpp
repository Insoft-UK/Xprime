// The MIT License (MIT)
//
// Copyright (c) 2024-2025 Insoft. All rights reserved.
// Originally created in 2023
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

#include "bmp.hpp"

#include <fstream>
#include <iostream>
#include <cstring>
#include <climits>

using namespace image;

#define BI_RGB 0

/* Windows 3.x bitmap file header */
typedef struct __attribute__((__packed__)) {
    char      bfType[2];   /* magic - always 'B' 'M' */
    uint32_t  bfSize;
    uint16_t  bfReserved1;
    uint16_t  bfReserved2;
    uint32_t  bfOffBits;    /* offset in bytes to actual bitmap data */
} BMPHeader;

/* Windows 3.x bitmap full header, including file header */

typedef struct __attribute__((__packed__)) {
    BMPHeader fileHeader;
    uint32_t  biSize;
    int32_t   biWidth;
    int32_t   biHeight;
    int16_t   biPlanes;           // Number of colour planes, set to 1
    int16_t   biBitCount;         // Colour bits per pixel. 1 4 8 24 or 32
    uint32_t  biCompression;      // *Code for the compression scheme
    uint32_t  biSizeImage;        // *Size of the bitmap bits in bytes
    int32_t   biXPelsPerMeter;    // *Horizontal resolution in pixels per meter
    int32_t   biYPelsPerMeter;    // *Vertical resolution in pixels per meter
    uint32_t  biClrUsed;          // *Number of colours defined in the palette
    uint32_t  biClImportant;      // *Number of important colours in the image
} BIPHeader;

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

static void flipBitmapImageVertically(const TImage &image)
{
    uint8_t *byte = (uint8_t *)image.bytes.data();
    int w = (int)((float)image.width / (8.0 / (float)image.bpp));
    int h = (int)image.height;
    
    for (int row = 0; row < h / 2; ++row)
        for (int col = 0; col < w; ++col)
            std::swap(byte[col + row * w], byte[col + (h - 1 - row) * w]);
    
}

TImage bmp::load(const std::filesystem::path& path)
{
    BIPHeader bip_header{};
    TImage image{};

    std::ifstream infile(path, std::ios::binary);
    if (!infile)
        return image;

    infile.read(reinterpret_cast<char*>(&bip_header), sizeof(BIPHeader));

    // Signature check
    std::string_view type{ bip_header.fileHeader.bfType, 2 };
    if (type != "BM")
        return image;

    // Only uncompressed BMP supported
    if (bip_header.biCompression != BI_RGB)
        return image;

    image.bpp = bip_header.biBitCount;

    // Fix: infer image size when missing (BI_RGB allows 0)
    if (bip_header.biSizeImage == 0) {
        bip_header.biSizeImage =
            ((bip_header.biWidth * bip_header.biBitCount + 31) / 32) * 4 *
            std::abs(bip_header.biHeight);
    }

    image.bytes.resize(bip_header.biSizeImage);

    /*
      Fix: determine palette size correctly
    */
    if (bip_header.biClrUsed == 0 && bip_header.biBitCount <= 8) {
        bip_header.biClrUsed = 1u << bip_header.biBitCount;
        bip_header.biClImportant = bip_header.biClrUsed;
    }

    // Fix: infer palette from bfOffBits if present
    if (bip_header.fileHeader.bfOffBits > sizeof(BIPHeader)) {
        size_t inferred =
            (bip_header.fileHeader.bfOffBits - sizeof(BIPHeader)) /
            sizeof(uint32_t);
        if (inferred > bip_header.biClrUsed)
            bip_header.biClrUsed = static_cast<uint32_t>(inferred);
    }

    // Read palette
    for (uint32_t i = 0; i < bip_header.biClrUsed; ++i) {
        uint32_t color;
        infile.read(reinterpret_cast<char*>(&color), sizeof(color));

#ifdef __LITTLE_ENDIAN__
        color = byteswap(color);
#endif
        image.palette.push_back(color | 0xFF);
    }

    image.palette.resize(bip_header.biClrUsed);

    image.width  = std::abs(bip_header.biWidth);
    image.height = std::abs(bip_header.biHeight);

    // Fix: correct row math (no floats)
    const size_t rowSize =
        ((image.width * bip_header.biBitCount + 31) / 32) * 4;
    const size_t pixelBytes =
        (image.width * bip_header.biBitCount + 7) / 8;

    infile.seekg(bip_header.fileHeader.bfOffBits, std::ios_base::beg);

    uint8_t* dst = image.bytes.data();

    for (int y = 0; y < image.height; ++y) {
        infile.read(reinterpret_cast<char*>(dst + y * pixelBytes), pixelBytes);
        if (infile.gcount() != static_cast<std::streamsize>(pixelBytes)) {
            std::cerr << path.filename() << " Read failed!\n";
            break;
        }
        infile.seekg(rowSize - pixelBytes, std::ios_base::cur);
    }

    // BMP stored bottom-up when height > 0
    if (bip_header.biHeight > 0)
        flipBitmapImageVertically(image);

    return image;
}

bool bmp::save(const char *filename, const TImage &image)
{
    BIPHeader bip_header = {
        .fileHeader = {
            .bfType = {'B', 'M'},
            .bfSize = 0,
            .bfOffBits = 0
        },
            .biSize = sizeof(BIPHeader) - sizeof(BMPHeader),
            .biWidth = image.width,
            .biHeight = image.height,
            .biPlanes = 1,
            .biBitCount = static_cast<int16_t>(image.bpp),
            .biCompression = static_cast<uint32_t>(image.bpp == 16 ? 3 : 0),
            .biSizeImage = static_cast<uint32_t>((image.width * image.bpp + 31) / 32 * 4 * (image.height)),
            .biClrUsed = image.bpp >= 16 ? 0 : static_cast<uint32_t>(image.palette.size()),
            .biClImportant = image.bpp >= 16 ? 0 : static_cast<uint32_t>(image.palette.size())
    };
    
    bip_header.biSizeImage = (bip_header.biWidth * bip_header.biBitCount + 31) / 32 * 4 * abs(bip_header.biHeight);
    
    bip_header.fileHeader.bfType[0] = 'B';
    bip_header.fileHeader.bfType[1] = 'M';
    bip_header.fileHeader.bfSize = bip_header.biSizeImage + (uint32_t)image.palette.size() * sizeof(uint32_t);
    bip_header.fileHeader.bfOffBits = sizeof(BIPHeader) + bip_header.biClrUsed * sizeof(uint32_t);

    std::ofstream outfile;
    outfile.open(filename, std::ios::out | std::ios::binary);
    if (!outfile.is_open()) {
        return false;
    }
    
    outfile.write((char *)&bip_header, sizeof(BIPHeader));
    if (bip_header.biClrUsed) {
        outfile.write((char *)image.palette.data(), bip_header.biClrUsed * sizeof(uint32_t));
    }
    
    int bytesPerLine = (float)image.width / (8.0 / (float)image.bpp);
    char *pixelData = (char *)image.bytes.data();
    
    flipBitmapImageVertically(image);
    
    for (int line = 0; line < image.height; line++) {
        outfile.write(pixelData, bytesPerLine);
        pixelData += bytesPerLine;
        
        /*
         Each scan line is zero padded to the nearest 4-byte boundary.
         
         If the image has a width that is not divisible by four, say, 21 bytes, there
         would be 3 bytes of padding at the end of every scan line.
         */
        int padding = bip_header.biSizeImage / abs(bip_header.biHeight) - bytesPerLine;
        while (padding--) {
            outfile.put(0);
        }
    }
    
    
    outfile.close();
    return true;
}


