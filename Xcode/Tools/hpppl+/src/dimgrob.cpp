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

#include "dimgrob.hpp"
#include "inverter.hpp"
#include "singleton.hpp"
#include "png.h"

#include <regex>
#include <fstream>
#include <sstream>

//#include <cstdint>
#include <vector>
//#include <string>
//#include <stdexcept>
//#include <cstdio>


static std::string pattern = R"(\bDIMGROB_P *\( *(G\d) *, *\"((?:\\.|[^"\\])*)\" *\))";

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

// A list is limited to 10,000 elements. Attempting to create a longer list will result in error 38 (Insufficient memory) being thrown.
static std::string formatPPLHexData(const void *data, const size_t lengthInBytes) {
    std::ostringstream os;
    uint64_t n;
    size_t count = 0;
    size_t length = lengthInBytes;
    uint64_t *bytes = (uint64_t *)data;
    
    while (length >= 8) {
        n = *bytes++;
        
        if (count) os << ",";
        os << "#" << std::uppercase << std::hex << std::setfill('0') << std::setw(16) << n << ":64h";
        
        count += 1;
        length -= 8;
    }
    return os.str();
}

typedef struct {
    uint16_t width;
    uint16_t height;
    uint8_t  bpp;
    std::vector<uint32_t> palette; // !Palette stored in RGBA format.
    std::vector<uint8_t> bytes;
} TImage;

static TImage load(const std::filesystem::path& path)
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

bool DIMGROB::isDIMGROB(const std::string &str) {
    return regex_search(str, std::regex(pattern, std::regex_constants::icase));
}

std::string DIMGROB::processDIMGROB(const std::string &str) {
    std::smatch match;
    std::string code = str;
    static const std::regex re(
                               pattern,
                               std::regex_constants::icase
                               );
    
    if (!std::regex_search(str, match, re)) {
        return str;
    }
    
    std::filesystem::path path(match.str(2));
    std::string name;
    
    name = path.stem().string();
    name = regex_replace(name, std::regex(R"([-.])"), "_");
    
    
    if (path.parent_path().empty()) {
        path = hppplplus::Singleton::shared()->getMainSourceDir() / path;
    }
    
    TImage image = load(path);

    if (image.bpp != 32) {
        std::cerr << MessageType::Warning;
        std::cerr << "Unsupported PNG colour type for DIMGROB_P in " << path.filename() << "!\n";
        return std::regex_replace(str, re, "DIMGROB_P(" + match.str(1) + ",4,4,{#7C007FFF7FFF7C00:64h,#7FFF7C007C007FFF:64h,#7FFF7C007C007FFF:64h,#7C007FFF7FFF7C00:64h}))");
    }
    
    if (image.bytes.size() / 8 > 10000) {
        std::cerr << MessageType::Warning;
        std::cerr << "list limit of 10,000 reached for " << path.filename() << "!\n";
        return std::regex_replace(str, re, "DIMGROB_P(" + match.str(1) + ",4,4,{#7C007FFF7FFF7C00:64h,#7FFF7C007C007FFF:64h,#7FFF7C007C007FFF:64h,#7C007FFF7FFF7C00:64h}))");
    }
    
    // Convert to HP Prime GROB format.
    for (std::size_t i = 0; i < image.bytes.size(); i += 4) {
        std::swap(image.bytes[i], image.bytes[i + 2]);
        image.bytes[i + 3] = 255 - image.bytes[i + 3];
    }
    
    // Generate the PPL code for DIMGROB_P.
    code = formatPPLHexData(image.bytes.data(), image.bytes.size());

    const std::string replacement =
        "DIMGROB_P(" + match.str(1) + "," +
        std::to_string(image.width) + "," +
        std::to_string(image.height) + ",{" + code + "})";

    return std::regex_replace(str, re, replacement);
}
