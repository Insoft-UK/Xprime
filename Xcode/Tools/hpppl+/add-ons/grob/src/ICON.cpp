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

#include "ICON.hpp"
#include "image.hpp"

#include <fstream>
#include <sstream>

#include <png.h>
#include <zlib.h>
#include <stdexcept>
#include <array>
#include <cstring>
#include <limits>

namespace PNG {
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
        
        uint8_t colorType;
        uint8_t bitDepth;
        
        std::vector<uint32_t> palette; // RGBA palette entries
        std::vector<uint8_t> pixels;
    } Image;
    
    struct Chunk {
        std::array<char, 4> type{};
        Bytes data;
        Bytes original;
    };
    
    static std::uint32_t readBE32(const std::uint8_t* p)
    {
        return (std::uint32_t(p[0]) << 24) |
        (std::uint32_t(p[1]) << 16) |
        (std::uint32_t(p[2]) << 8)  |
        std::uint32_t(p[3]);
    }
    
    static void writeBE32(Bytes& out, std::uint32_t value)
    {
        out.push_back(std::uint8_t(value >> 24));
        out.push_back(std::uint8_t(value >> 16));
        out.push_back(std::uint8_t(value >> 8));
        out.push_back(std::uint8_t(value));
    }
    
    static void appendChunk(Bytes& out, const char type[4], const Bytes& data)
    {
        if (data.size() > std::numeric_limits<std::uint32_t>::max())
            throw std::runtime_error("PNG chunk is too large");
        
        if (data.size() > std::numeric_limits<uInt>::max())
            throw std::runtime_error("PNG chunk exceeds zlib CRC limits");
        
        writeBE32(out, static_cast<std::uint32_t>(data.size()));
        
        const auto typeOffset = out.size();
        for (int i = 0; i < 4; ++i)
            out.push_back(static_cast<std::uint8_t>(type[i]));
        
        out.insert(out.end(), data.begin(), data.end());
        
        uLong crc = crc32(0L, Z_NULL, 0);
        crc = crc32(crc, out.data() + typeOffset,
                    static_cast<uInt>(4 + data.size()));
        
        writeBE32(out, static_cast<std::uint32_t>(crc));
    }
    
    static int paeth(int a, int b, int c)
    {
        const int p  = a + b - c;
        const int pa = std::abs(p - a);
        const int pb = std::abs(p - b);
        const int pc = std::abs(p - c);
        
        if (pa <= pb && pa <= pc) return a;
        if (pb <= pc) return b;
        return c;
    }
    
    ColourType getColourType(const Bytes& png)
    {
        static constexpr std::uint8_t signature[] = {
            0x89, 'P', 'N', 'G', '\r', '\n', 0x1A, '\n'
        };
        
        if (png.size() < 26 ||
            !std::equal(std::begin(signature), std::end(signature), png.begin()) ||
            std::memcmp(png.data() + 12, "IHDR", 4) != 0)
            return ColourType::Unknown;
        
        switch (png[25]) {
            case 0: return ColourType::Grayscale;
            case 2: return ColourType::RGB;
            case 3: return ColourType::Indexed;
            case 4: return ColourType::GrayscaleAlpha;
            case 6: return ColourType::RGBA;
            default: return ColourType::Unknown;
        }
    }
    
    
    // Inverts alpha for non-interlaced, 8-bit RGBA PNG images.
    // Throws std::runtime_error if the PNG format is unsupported or invalid.
    void invertRGBAAlpha(Bytes& png)
    {
        static constexpr std::uint8_t signature[] = {
            0x89, 'P', 'N', 'G', '\r', '\n', 0x1A, '\n'
        };
        
        if (png.size() < sizeof(signature) ||
            !std::equal(std::begin(signature), std::end(signature), png.begin()))
            throw std::runtime_error("Invalid PNG signature");
        
        std::vector<Chunk> chunks;
        Bytes compressed;
        
        std::uint32_t width = 0;
        std::uint32_t height = 0;
        bool foundIHDR = false;
        bool foundIDAT = false;
        bool foundIEND = false;
        
        // Read the PNG chunks.
        for (std::size_t pos = sizeof(signature); pos < png.size();) {
            if (png.size() - pos < 12)
                throw std::runtime_error("Truncated PNG chunk");
            
            const std::uint32_t length = readBE32(png.data() + pos);
            
            if (length > png.size() - pos - 12)
                throw std::runtime_error("Invalid PNG chunk length");
            
            Chunk chunk;
            for (int i = 0; i < 4; ++i)
                chunk.type[i] = static_cast<char>(png[pos + 4 + i]);
            
            const std::size_t chunkSize = std::size_t(length) + 12;
            
            chunk.data.assign(
                              png.begin() + pos + 8,
                              png.begin() + pos + 8 + length
                              );
            
            chunk.original.assign(
                                  png.begin() + pos,
                                  png.begin() + pos + chunkSize
                                  );
            
            const std::string type(chunk.type.data(), 4);
            
            if (type == "IHDR") {
                if (foundIHDR || length != 13)
                    throw std::runtime_error("Invalid PNG header");
                
                width  = readBE32(chunk.data.data());
                height = readBE32(chunk.data.data() + 4);
                
                // Bit depth 8, colour type 6 (RGBA), standard methods,
                // and no interlacing.
                if (chunk.data[8] != 8 || chunk.data[9] != 6)
                    throw std::runtime_error(
                                             "PNG must be 8-bit RGBA (colour type 6)");
                
                if (chunk.data[10] != 0 ||
                    chunk.data[11] != 0 ||
                    chunk.data[12] != 0)
                    throw std::runtime_error(
                                             "Unsupported PNG compression, filter or interlace method");
                
                foundIHDR = true;
            }
            else if (type == "IDAT") {
                if (!foundIHDR)
                    throw std::runtime_error("PNG IDAT precedes IHDR");
                
                if (length > std::numeric_limits<std::size_t>::max()
                    - compressed.size())
                    throw std::runtime_error("PNG image data is too large");
                
                compressed.insert(
                                  compressed.end(), chunk.data.begin(), chunk.data.end());
                
                foundIDAT = true;
            }
            else if (type == "IEND") {
                foundIEND = true;
            }
            
            chunks.push_back(std::move(chunk));
            pos += chunkSize;
            
            if (type == "IEND")
                break;
        }
        
        if (!foundIHDR || !foundIDAT || !foundIEND || width == 0 || height == 0)
            throw std::runtime_error("Incomplete PNG");
        
        // Calculate the expected decompressed scanline size.
        if constexpr (sizeof(std::size_t) <= sizeof(width)) {
            if (width > (std::numeric_limits<std::size_t>::max() - 1) / 4)
                throw std::runtime_error("PNG dimensions are too large");
        }
        
        const std::size_t rowBytes = std::size_t(width) * 4;
        
        if (height > std::numeric_limits<std::size_t>::max() / (rowBytes + 1))
            throw std::runtime_error("PNG dimensions are too large");
        
        const std::size_t rawSize = std::size_t(height) * (rowBytes + 1);
        
        if (rawSize > std::numeric_limits<uLongf>::max() ||
            compressed.size() > std::numeric_limits<uLong>::max())
            throw std::runtime_error("PNG image data exceeds zlib limits");
        
        // Decompress the PNG image data.
        Bytes raw(rawSize);
        uLongf decompressedSize = static_cast<uLongf>(raw.size());
        
        const int result = uncompress(
                                      raw.data(), &decompressedSize,
                                      compressed.data(), static_cast<uLong>(compressed.size()));
        
        if (result != Z_OK || decompressedSize != raw.size())
            throw std::runtime_error("Could not decompress PNG image data");
        
        // Reverse PNG scanline filters.
        Bytes pixels(std::size_t(height) * rowBytes);
        
        for (std::size_t y = 0; y < height; ++y) {
            const std::uint8_t filter = raw[y * (rowBytes + 1)];
            const std::size_t src = y * (rowBytes + 1) + 1;
            const std::size_t dst = y * rowBytes;
            
            if (filter > 4)
                throw std::runtime_error("Invalid PNG scanline filter");
            
            for (std::size_t x = 0; x < rowBytes; ++x) {
                const int value = raw[src + x];
                const int left  = x >= 4 ? pixels[dst + x - 4] : 0;
                const int above = y > 0 ? pixels[dst - rowBytes + x] : 0;
                const int upperLeft =
                (y > 0 && x >= 4)
                ? pixels[dst - rowBytes + x - 4]
                : 0;
                
                int predictor = 0;
                
                switch (filter) {
                    case 0: predictor = 0; break;
                    case 1: predictor = left; break;
                    case 2: predictor = above; break;
                    case 3: predictor = (left + above) / 2; break;
                    case 4: predictor = paeth(left, above, upperLeft); break;
                }
                
                pixels[dst + x] =
                static_cast<std::uint8_t>((value + predictor) & 0xFF);
            }
        }
        
        // Invert the alpha byte of every RGBA pixel.
        for (std::size_t i = 3; i < pixels.size(); i += 4)
            pixels[i] = 255 - pixels[i];
        
        // Rebuild scanlines using PNG filter 0 (no filtering).
        Bytes newRaw(rawSize);
        
        for (std::size_t y = 0; y < height; ++y) {
            const std::size_t dst = y * (rowBytes + 1);
            newRaw[dst] = 0;
            
            std::memcpy(
                        newRaw.data() + dst + 1,
                        pixels.data() + y * rowBytes,
                        rowBytes
                        );
        }
        
        // Compress the modified image.
        if (newRaw.size() > std::numeric_limits<uLong>::max())
            throw std::runtime_error("PNG image data exceeds zlib limits");
        
        Bytes newCompressed(compressBound(static_cast<uLong>(newRaw.size())));
        uLongf newCompressedSize = static_cast<uLongf>(newCompressed.size());
        
        if (compress2(
                      newCompressed.data(), &newCompressedSize,
                      newRaw.data(), static_cast<uLong>(newRaw.size()),
                      Z_DEFAULT_COMPRESSION) != Z_OK)
            throw std::runtime_error("Could not compress PNG image data");
        
        newCompressed.resize(static_cast<std::size_t>(newCompressedSize));
        
        // Rebuild the PNG, replacing all IDAT chunks with one new IDAT.
        Bytes output(std::begin(signature), std::end(signature));
        bool wroteIDAT = false;
        
        for (const auto& chunk : chunks) {
            const std::string type(chunk.type.data(), 4);
            
            if (type == "IDAT") {
                if (!wroteIDAT) {
                    appendChunk(output, "IDAT", newCompressed);
                    wroteIDAT = true;
                }
            } else {
                output.insert(
                              output.end(), chunk.original.begin(), chunk.original.end());
            }
        }
        
        png = std::move(output);
    }
    
    void invertPNGTransparency(Bytes& data)
    {
        static constexpr std::uint8_t signature[] = {
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A
        };
        
        if (data.size() < sizeof(signature) ||
            !std::equal(std::begin(signature), std::end(signature),
                        data.begin()))
        {
            throw std::runtime_error("Invalid PNG file");
        }
        
        // PNG CRC-32, using polynomial 0xEDB88320.
        auto crc32 = [](const std::uint8_t* ptr, std::size_t length) {
            std::uint32_t crc = 0xFFFFFFFF;
            
            while (length--) {
                crc ^= *ptr++;
                
                for (int bit = 0; bit < 8; ++bit)
                    crc = (crc >> 1) ^
                    (0xEDB88320u & (0u - (crc & 1u)));
            }
            
            return crc ^ 0xFFFFFFFF;
        };
        
        auto readBE32 = [](const std::uint8_t* p) -> std::uint32_t {
            return (std::uint32_t(p[0]) << 24) |
            (std::uint32_t(p[1]) << 16) |
            (std::uint32_t(p[2]) <<  8) |
            std::uint32_t(p[3]);
        };
        
        auto writeBE32 = [](std::uint8_t* p, std::uint32_t value) {
            p[0] = static_cast<std::uint8_t>(value >> 24);
            p[1] = static_cast<std::uint8_t>(value >> 16);
            p[2] = static_cast<std::uint8_t>(value >> 8);
            p[3] = static_cast<std::uint8_t>(value);
        };
        
        std::size_t offset = sizeof(signature);
        
        while (offset + 12 <= data.size()) {
            const std::uint32_t length = readBE32(&data[offset]);
            
            // Check chunk bounds, including type, data and CRC.
            if (length > data.size() - offset - 12)
                throw std::runtime_error("Invalid PNG chunk length");
            
            const std::size_t typeOffset = offset + 4;
            const std::size_t dataOffset = offset + 8;
            const std::size_t crcOffset = dataOffset + length;
            
            if (data[typeOffset] == 't' &&
                data[typeOffset + 1] == 'R' &&
                data[typeOffset + 2] == 'N' &&
                data[typeOffset + 3] == 'S')
            {
                // Invert each alpha byte: 00 <-> FF.
                for (std::size_t i = dataOffset; i < crcOffset; ++i) {
                    if (data[i] == 0x00)
                        data[i] = 0xFF;
                    else if (data[i] == 0xFF)
                        data[i] = 0x00;
                }
                
                // CRC covers the chunk type and data, not length or CRC.
                const std::uint32_t crc = crc32(
                                                &data[typeOffset],
                                                4 + length
                                                );
                
                writeBE32(&data[crcOffset], crc);
                return;
            }
            
            if (data[typeOffset] == 'I' &&
                data[typeOffset + 1] == 'E' &&
                data[typeOffset + 2] == 'N' &&
                data[typeOffset + 3] == 'D')
            {
                break;
            }
            
            offset = crcOffset + 4;
        }
        
        throw std::runtime_error("PNG has no tRNS chunk");
    }
    
}

namespace hpprime {
    std::string ICON(const std::filesystem::path& path)
    {
        
        std::ifstream file(path, std::ios::binary);
        
        if (!file)
            throw std::runtime_error("Cannot open PNG file: " + path.filename().string());
        
        std::vector<std::uint8_t> data(
                                       std::istreambuf_iterator<char>(file),
                                       {}
                                       );
        
        // Validate the PNG signature.
        static constexpr std::uint8_t signature[] = {
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A
        };
        
        if (data.size() < sizeof(signature) ||
            !std::equal(std::begin(signature), std::end(signature),
                        data.begin()))
        {
            throw std::runtime_error("Invalid PNG file");
        }
        
        switch (PNG::getColourType(data)) {
            case PNG::ColourType::Indexed:
                // Palette-based PNG
                PNG::invertPNGTransparency(data); // HP Prime uses inverted transparency values.
                break;
                
            case PNG::ColourType::RGBA:
                // Truecolour with alpha channel
                PNG::invertRGBAAlpha(data);
                break;
                
            default:
                break;
        }
        
        std::ostringstream output;
        output << "ICON " << path.stem().string() << ' '
        << std::uppercase << std::hex << std::setfill('0');
        
        for (std::uint8_t byte : data)
            output << std::setw(2) << static_cast<unsigned>(byte);
        
        output << ';';
        return output.str();
    }
}
