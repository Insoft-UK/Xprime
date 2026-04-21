// The MIT License (MIT)
//
// Copyright (c) 2024-2025 Insoft.
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

#include "png.hpp"

#if __APPLE__

#include <stdio.h>
#include <iostream>
#include <fstream>

#include "png.h"

using namespace image;

TImage png::load(const std::filesystem::path& path)
{
    TImage image;
    
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
    image.bpp = 32;
    image.width = static_cast<uint16_t>(width);
    image.height = static_cast<uint16_t>(height);
    // Assume we're loading in RGBA format (32 bits per pixel)
    
    // Allocate memory for the pixel data
    size_t dataSize = width * height * 4; // 4 bytes per pixel (RGBA)
    image.bytes.reserve(dataSize);
    image.bytes.resize(dataSize);
    
    // Read the image data row by row
    std::vector<png_bytep> row_pointers(height);
    for (int y = 0; y < height; ++y) {
        row_pointers[y] = image.bytes.data() + y * width * 4;
    }
    
    png_read_image(png, row_pointers.data());
    
    // Clean up
    png_destroy_read_struct(&png, &info, nullptr);
    
    return image;
}

bool png::save(const std::filesystem::path& path, const TImage &image) {

    // Open file
    FILE* fp = fopen(path.c_str(), "wb");
    if (!fp) {
        std::cerr << "Error: Unable to open file for writing: " << path.filename().string() << std::endl;
        return false;
    }

    // Create PNG write struct
    png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, nullptr, nullptr, nullptr);
    if (!png) {
        std::cerr << "Error: Unable to create PNG write struct." << std::endl;
        fclose(fp);
        return false;
    }

    // Create PNG info struct
    png_infop info = png_create_info_struct(png);
    if (!info) {
        std::cerr << "Error: Unable to create PNG info struct." << std::endl;
        png_destroy_write_struct(&png, nullptr);
        fclose(fp);
        return false;
    }

    // Setup error handling
    if (setjmp(png_jmpbuf(png))) {
        std::cerr << "Error: Exception during PNG creation." << std::endl;
        png_destroy_write_struct(&png, &info);
        fclose(fp);
        return false;
    }

    // Initialize file I/O
    png_init_io(png, fp);

    // Set image header info
    int color_type;
    switch (image.bpp) {
        case 8:
            color_type = PNG_COLOR_TYPE_GRAY;
            break;
        case 24:
            color_type = PNG_COLOR_TYPE_RGB;
            break;
        case 32:
            color_type = PNG_COLOR_TYPE_RGBA;
            break;
        default:
            std::cerr << "Error: Unsupported bit width." << std::endl;
            png_destroy_write_struct(&png, &info);
            fclose(fp);
            return false;
    }

    png_set_IHDR(png, info, image.width, image.height, 8, color_type,
                 PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);

    png_write_info(png, info);

    // Write image data row by row
    const int bytes_per_pixel = image.bpp / 8;
    std::vector<png_bytep> row_pointers(image.height);
    for (size_t y = 0; y < image.height; ++y) {
        row_pointers[y] = (png_bytep)(&image.bytes.data()[y * image.width * bytes_per_pixel]);
    }
    png_write_image(png, row_pointers.data());

    // End write
    png_write_end(png, nullptr);

    // Cleanup
    png_destroy_write_struct(&png, &info);
    fclose(fp);

    std::cerr << "PNG file saved successfully: " << path.filename().string() << std::endl;
    return true;
}

#endif // __APPLE__
