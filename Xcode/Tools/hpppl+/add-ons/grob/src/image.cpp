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

#include "image.hpp"

#include <fstream>
#include <iostream>

#include <png.h>

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

static void flipBitmapImageVertically(const image::Image &image)
{
    uint8_t *byte = (uint8_t *)image.pixels.data();
    int w = (int)((float)image.width / (8.0 / (float)image.bitCount));
    int h = (int)image.height;
    
    for (int row = 0; row < h / 2; ++row)
        for (int col = 0; col < w; ++col)
            std::swap(byte[col + row * w], byte[col + (h - 1 - row) * w]);
    
}

static image::Image loadBMPImage(const std::filesystem::path& path)
{
    BIPHeader bip_header{};
    image::Image image{};

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

    switch (bip_header.biBitCount) {
        case 32:
            image.colorType = image::ColourType::RGBA;
            image.bitDepth = 8;
            image.bitCount = bip_header.biBitCount;
            break;
            
        case 24:
            image.colorType = image::ColourType::RGB;
            image.bitDepth = 8;
            image.bitCount = bip_header.biBitCount;
            break;
            
        case 16:
            image.colorType = image::ColourType::HighColour;
            image.bitDepth = 16;
            image.bitCount = bip_header.biBitCount;
            break;
            
        case 8:
            image.colorType = image::ColourType::Indexed;
            image.bitDepth = 8;
            image.bitCount = bip_header.biBitCount;
            break;
            
        case 4:
            image.colorType = image::ColourType::Indexed;
            image.bitDepth = 4;
            image.bitCount = bip_header.biBitCount;
            break;
            
        case 1:
            image.colorType = image::ColourType::Grayscale;
            image.bitDepth = 1;
            image.bitCount = bip_header.biBitCount;
            break;
            
        default:
            break;
    }

    // Fix: infer image size when missing (BI_RGB allows 0)
    if (bip_header.biSizeImage == 0) {
        bip_header.biSizeImage =
            ((bip_header.biWidth * bip_header.biBitCount + 31) / 32) * 4 *
            std::abs(bip_header.biHeight);
    } else {
        // biSizeImage may be incorrect, so calculate the image data size manually instead.
        auto size =
            ((bip_header.biWidth * bip_header.biBitCount + 31) / 32) * 4 *
            std::abs(bip_header.biHeight);
        image.pixels.resize(size);
    }

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

    uint8_t* dst = image.pixels.data();

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
    
    
    if (image.colorType == image::ColourType::RGBA && image.bitDepth == 8) {
        for (std::size_t i = 0; i < image.pixels.size(); i += 4) {
            std::swap(image.pixels[i], image.pixels[i + 2]);
            image.pixels[i + 3] = 255 - image.pixels[i + 3];
        }
    }

    return image;
}

static bool saveBMPImage(const std::filesystem::path& path, const image::Image& image)
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
            .biBitCount = static_cast<int16_t>(image.bitCount),
            .biCompression = static_cast<uint32_t>(image.bitDepth == 16 ? 3 : 0),
            .biSizeImage = static_cast<uint32_t>((image.width * image.bitDepth + 31) / 32 * 4 * (image.height)),
            .biClrUsed = image.bitDepth >= 16 ? 0 : static_cast<uint32_t>(image.palette.size()),
            .biClImportant = image.bitDepth >= 16 ? 0 : static_cast<uint32_t>(image.palette.size())
    };
    
    bip_header.biSizeImage = (bip_header.biWidth * bip_header.biBitCount + 31) / 32 * 4 * abs(bip_header.biHeight);
    
    bip_header.fileHeader.bfType[0] = 'B';
    bip_header.fileHeader.bfType[1] = 'M';
    bip_header.fileHeader.bfSize = bip_header.biSizeImage + (uint32_t)image.palette.size() * sizeof(uint32_t);
    bip_header.fileHeader.bfOffBits = sizeof(BIPHeader) + bip_header.biClrUsed * sizeof(uint32_t);

    std::ofstream outfile;
    outfile.open(path, std::ios::out | std::ios::binary);
    if (!outfile.is_open()) {
        return false;
    }
    
    outfile.write((char *)&bip_header, sizeof(BIPHeader));
    if (bip_header.biClrUsed) {
        outfile.write((char *)image.palette.data(), bip_header.biClrUsed * sizeof(uint32_t));
    }
    
    int bytesPerLine = (float)image.width / (8.0 / (float)image.bitDepth);
    char *pixelData = (char *)image.pixels.data();
    
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

/**
 @brief Loads a file in the Portable Bitmap (PBM) format.
 @param path The pathname of the Portable Bitmap (PBM) to be loaded.
 @return A structure containing the image data.
 */
static image::Image loadPBMImage(const std::filesystem::path& path)
{
    std::ifstream infile;
    image::Image image;
    
    infile.open(path.string(), std::ios::in | std::ios::binary);
    if (!infile.is_open()) return image;
    
    std::string s;
    
    getline(infile, s);
    if (s != "P4") {
        infile.close();
        return image;
    }
    
    image.colorType = image::ColourType::Grayscale;
    image.bitDepth = 1;
    image.bitCount = 1;
    
    getline(infile, s);
    image.width = atoi(s.c_str());
    
    getline(infile, s);
    image.height = atoi(s.c_str());
    
    size_t length = ((image.width + 7) >> 3) * image.height;
    image.pixels.reserve(length);
    image.pixels.resize(length);
    
    infile.read((char *)image.pixels.data(), length);
    infile.close();
        
    return image;
}

static image::Image loadPNGImage(const std::filesystem::path& path)
{
    image::Image image;
    
    // Open the file using an ifstream
    std::ifstream file(path, std::ios::binary);
    if (!file.is_open()) {
        throw std::runtime_error("Failed to open file: " + path.filename().string());
    }
    
    // Read the PNG signature (first 8 bytes)
    png_byte header[8];
    file.read(reinterpret_cast<char*>(header), sizeof(header));
    if (file.gcount() != sizeof(header) || png_sig_cmp(header, 0, 8)) {
        throw std::runtime_error("File is not a valid PNG: " + path.filename().string());
    }
    
    // Initialize PNG structs
    png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, nullptr, nullptr, nullptr);
    if (!png) throw std::runtime_error("Failed to create PNG read struct");
    
    png_infop info = png_create_info_struct(png);
    if (!info) {
        png_destroy_read_struct(&png, nullptr, nullptr);
        throw std::runtime_error("Failed to create PNG info struct");
    }
    
    if (setjmp(png_jmpbuf(png))) {
        png_destroy_read_struct(&png, &info, nullptr);
        throw std::runtime_error("Error during PNG read");
    }
    
    // Set the custom read function to use ifstream
    png_set_read_fn(png, &file, [](png_structp png, png_bytep data, png_size_t length) {
        std::ifstream* file = static_cast<std::ifstream*>(png_get_io_ptr(png));
        file->read(reinterpret_cast<char*>(data), length);
    });
    
    // Inform libpng we've already read the first 8 bytes
    png_set_sig_bytes(png, 8);
    
    // Read the image info
    png_read_info(png, info);
    
    int width = png_get_image_width(png, info);
    int height = png_get_image_height(png, info);
    png_byte color_type = png_get_color_type(png, info);
    png_byte bit_depth = png_get_bit_depth(png, info);
    
    // Convert the PNG to 8-bit RGBA format
    if (bit_depth == 16) png_set_strip_16(png);
    if (color_type == PNG_COLOR_TYPE_PALETTE) png_set_palette_to_rgb(png);
    if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8) png_set_expand_gray_1_2_4_to_8(png);
    if (png_get_valid(png, info, PNG_INFO_tRNS)) png_set_tRNS_to_alpha(png);
    if (color_type == PNG_COLOR_TYPE_RGB || color_type == PNG_COLOR_TYPE_GRAY) png_set_filler(png, 0xFF, PNG_FILLER_AFTER);
    
    png_read_update_info(png, info);
    
    // Create the TImage structure
    image.bitDepth = bit_depth;
    image.colorType = static_cast<image::ColourType>(color_type);
    image.width = static_cast<uint16_t>(width);
    image.height = static_cast<uint16_t>(height);
    if (image.colorType == image::ColourType::RGBA) {
        image.bitCount = 32;
    } else if (image.colorType == image::ColourType::RGB) {
        image.bitCount = 24;
    } else {
        image.bitCount = image.bitDepth;
    }
    // Assume we're loading in RGBA format (32 bits per pixel)
    
    // Allocate memory for the pixel data
    size_t dataSize = width * height * 4; // 4 bytes per pixel (RGBA)
    image.pixels.reserve(dataSize);
    image.pixels.resize(dataSize);
    
    // Read the image data row by row
    std::vector<png_bytep> row_pointers(height);
    for (int y = 0; y < height; ++y) {
        row_pointers[y] = image.pixels.data() + y * width * 4;
    }
    
    png_read_image(png, row_pointers.data());
    
    // Clean up
    png_destroy_read_struct(&png, &info, nullptr);
    
    return image;
}

static void pngWriteCallback(png_structp png, png_bytep data, png_size_t length) {
    auto* stream = static_cast<std::ofstream*>(png_get_io_ptr(png));
    stream->write(reinterpret_cast<const char*>(data), static_cast<std::streamsize>(length));

    if (!*stream) {
        png_error(png, "Failed to write PNG data.");
    }
}

static void pngFlushCallback(png_structp png) {
    auto* stream = static_cast<std::ofstream*>(png_get_io_ptr(png));
    stream->flush();

    if (!*stream) {
        png_error(png, "Failed to flush PNG data.");
    }
}

static bool savePNGImage(const std::filesystem::path& path, const image::Image& image) {

    // Open file
    std::ofstream file(path, std::ios::binary);
    if (!file) {
        std::cerr << "Error: Unable to open file for writing: "
                  << path.filename().string() << std::endl;
        return false;
    }

    // Create PNG write struct
    png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, nullptr, nullptr, nullptr);
    if (!png) {
        std::cerr << "Error: Unable to create PNG write struct." << std::endl;
        return false;
    }

    // Create PNG info struct
    png_infop info = png_create_info_struct(png);
    if (!info) {
        std::cerr << "Error: Unable to create PNG info struct." << std::endl;
        png_destroy_write_struct(&png, nullptr);
        return false;
    }

    // Setup error handling
    if (setjmp(png_jmpbuf(png))) {
        std::cerr << "Error: Exception during PNG creation." << std::endl;
        png_destroy_write_struct(&png, &info);
        return false;
    }

    // Initialize custom file I/O
    png_set_write_fn(png, &file, pngWriteCallback, pngFlushCallback);

    // Set image header info
    if (image.bitDepth == 24 || image.bitDepth == 32) {
        std::cerr << "Error: Unsupported bit depth." << std::endl;
        png_destroy_write_struct(&png, &info);
        return false;
    }

    png_set_IHDR(png, info,
                 image.width,
                 image.height,
                 8,
                 static_cast<uint8_t>(image.colorType),
                 PNG_INTERLACE_NONE,
                 PNG_COMPRESSION_TYPE_DEFAULT,
                 PNG_FILTER_TYPE_DEFAULT);

    png_write_info(png, info);

    // Write image data row by row
    std::vector<png_bytep> row_pointers(image.height);

    for (size_t y = 0; y < image.height; ++y) {
        row_pointers[y] = const_cast<png_bytep>(
            image.pixels.data() + y * image.width * image.bitDepth
        );
    }

    png_write_image(png, row_pointers.data());

    // End write
    png_write_end(png, nullptr);

    // Cleanup
    png_destroy_write_struct(&png, &info);

    file.close();

    if (!file) {
        std::cerr << "Error: Failed to save PNG file: "
                  << path.filename().string() << std::endl;
        return false;
    }

    std::cerr << "PNG file saved successfully: "
              << path.filename().string() << std::endl;

    return true;
}

static std::ifstream::pos_type getFileSize(const std::filesystem::path& path)
{
    std::ifstream in(path, std::ifstream::ate | std::ifstream::binary);
    std::ifstream::pos_type pos = in.tellg();
    in.close();
    return pos;
}

static image::Image loadRawImage(const std::filesystem::path& path) {
    size_t fsize;
    std::ifstream infile;
    image::Image image{};
    
    if ((fsize = getFileSize(path)) == 0) return image;
    
    infile.open(path, std::ios::in | std::ios::binary);
    if (!infile.is_open()) return image;

    image.pixels.reserve(fsize);
    image.pixels.resize(fsize);
    infile.read((char *)image.pixels.data(), fsize);
    image.bitDepth = 8;
    image.colorType = image::ColourType::Unknown;
    image.bitCount = 8;
    
    infile.close();
    return image;
}

static void convertToHPPrimeGROB(image::Image& image) {
    switch (image.bitCount) {
        case 1:
            if (!image.pixels.empty()) {
                uint8_t *bytes = (uint8_t *)image.pixels.data();
                for (int i = 0; i < image.pixels.size(); i += 1) {
                    uint8_t result = 0;
                    for (int n = 0; n < 8; n += 1) {
                        result <<= 1;
                        result |= bytes[i] & 1;
                        bytes[i] >>= 1;
                    }
                    bytes[i] = result;
                }
            }
            break;
            
        case 4:
            if (!image.pixels.empty()) {
                /*
                 Due to the use of little-endian format, when the 8-byte sequence
                 is interpreted as a single 64-bit number, the bytes are stored in
                 reverse order (from least significant to most significant).
                 Since this data represents an image where each nibble corresponds
                 to an index, we must first swap the nibbles in the entire data
                 sequence to ensure they remain in the correct order when read from
                 right to left.
                 */
                
                uint8_t *bytes = (uint8_t *)image.pixels.data();
                for (int i = 0; i < image.pixels.size(); i += 1) {
                    // Swap nibbles
                    bytes[i] = bytes[i] >> 4 | bytes[i] << 4;
                }
            }
            break;
            
        case 32:
            // Convert to HP Prime GROB format.
            if (image.colorType == image::ColourType::RGBA && image.bitDepth == 8) {
                for (std::size_t i = 0; i < image.pixels.size(); i += 4) {
                    std::swap(image.pixels[i], image.pixels[i + 2]);
                    image.pixels[i + 3] = 255 - image.pixels[i + 3];
                }
            }
            break;
            
        default:
            break;
    }
}

namespace image {
    Image loadImage(const std::filesystem::path& path)
    {
        Image image{};
        auto extension = path.extension().string();
        
        std::transform(extension.begin(), extension.end(), extension.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        
        
        if (extension == ".bmp")
            image = loadBMPImage(path);
        
        if (extension == ".pbm")
            image = loadPBMImage(path);
        
        if (extension == ".png")
            image = loadPNGImage(path);
        
        convertToHPPrimeGROB(image);
        
        return image;
    }
    
    bool saveImage(const std::filesystem::path& path, const Image& image)
    {
        auto extension = path.extension().string();
        
        std::transform(extension.begin(), extension.end(), extension.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        
        if (extension == ".png")
            return savePNGImage(path, image);
        
        if (extension == ".bmp")
            return saveBMPImage(path, image);
        
        return false;
    }
}
