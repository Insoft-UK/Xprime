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

#include <iostream>
#include <fstream>
#include <sstream>
#include <filesystem>
#include <regex>
#include <cstring>
#include <iomanip>
#include <cstdint>
#include "utf.hpp"
#include "hpprgm.hpp"

#include "../version_code.h"
#include "bmp.hpp"
#include "png.hpp"
#include "pbm.hpp"
#include "timer.hpp"
#include "extensions.hpp"

#define NAME "GROB"
#define COMMAND_NAME "grob"

namespace fs = std::filesystem;

// MARK: - Functions

// A list is limited to 10,000 elements. Attempting to create a longer list will result in error 38 (Insufficient memory) being thrown.
static std::string ppl(const void *data, const size_t lengthInBytes, const int columns, bool le = true) {
    std::ostringstream os;
    uint64_t n;
    size_t count = 0;
    size_t length = lengthInBytes;
    uint64_t *bytes = (uint64_t *)data;
    
    while (length >= 8) {
        n = *bytes++;
        
        if (!le) {
            n = std::byteswap(n);
        }
        
#ifdef __BIG_ENDIAN__
        /*
         This platform utilizes big-endian, not little-endian. To ensure
         that data is processed correctly when generating the list, we
         must convert between big-endian and little-endian.
         */
        if (le) n = std::byteswap(n);
#endif // __BIG_ENDIAN__

        if (count) os << ", ";
        if (count % columns == 0) {
            os << (count ? "\n    " : "    ");
        }
        os << "#" << std::uppercase << std::hex << std::setfill('0') << std::setw(16) << n << ":64h";
        
        count += 1;
        length -= 8;
    }
    return os.str();
}

static std::ifstream::pos_type filesize(const char* filename)
{
    std::ifstream in(filename, std::ifstream::ate | std::ifstream::binary);
    std::ifstream::pos_type pos = in.tellg();
    in.close();
    return pos;
}

static size_t loadBinaryFile(const char* filename, image::TImage &bitmap) {
    size_t fsize;
    std::ifstream infile;
    
    if ((fsize = filesize(filename)) == 0) return 0;
    
    infile.open(filename, std::ios::in | std::ios::binary);
    
    if (!infile.is_open()) return 0;

    bitmap.bytes.reserve(fsize);
    bitmap.bytes.resize(fsize);
    infile.read((char *)bitmap.bytes.data(), fsize);
    bitmap.bpp = 0;
    
    infile.close();
    return fsize;
}

std::string expandTilde(const std::string &path) {
    if (path.starts_with("~/")) {
        const char* home = getenv("HOME");
        if (home) {
            return std::string(home) + path.substr(1);  // Replace '~' with $HOME
        }
    }
    return path;
}

// MARK: - Command Line
void help(void)
{
    std::cerr
    << "Copyright (C) 2024-" << YEAR << " Insoft.\n"
    << "Insoft "<< NAME << " version, " << VERSION_NUMBER << " (BUILD " << BUNDLE_VERSION << ")\n"
    << "\n"
    << "Usage: " << COMMAND_NAME << " <input-file> [-o <output-file>] [-c <columns>] [-n <name>] [-g<1-9>] [-ppl] \n"
    << "\n"
    << "Options:\n"
    << "  -o <output-file>           Specify the filename for generated PPL code.\n"
    << "  -c <columns>               Number of columns.\n"
    << "  --pragma                   Include \"#pragma mode( separator(.,;) integer(h64) )\" line.\n"
    << "  --endian <le|be>           Endianes le(default).\n"
    << "\n"
    << "Additional Commands:\n"
    << "  " << COMMAND_NAME << " {--version | --help}\n"
    << "    --version                Display the version information.\n"
    << "    --help                   Show this help message.\n";
}


void error(void) {
    std::cerr << COMMAND_NAME << ": try '" << COMMAND_NAME << " --help' for more information\n";
    exit(0);
}

fs::path resolveAndValidateInputFile(const char *input_file) {
    fs::path path;
    
    path = input_file;
    if (path == "/dev/stdin") return path;
    
    path = fs::expand_tilde(path);
    if (path.parent_path().empty()) path = fs::path("./") / path;
    
    
    if (!fs::exists(path)) {
        std::cerr << "❓File " << path.filename() << " not found at " << path.parent_path() << " location.\n";
        exit(0);
    }
    
    return path;
}

fs::path resolveOutputFile(const char *output_file) {
    fs::path path;
    
    path = output_file;
    if (path == "/dev/stdout") return path;
    
    path = fs::expand_tilde(path);
    
    return path;
}

fs::path resolveOutputPath(const fs::path& inpath, const fs::path& outpath) {
    fs::path path = outpath;
    
    if (path == "/dev/stdout") return path;
    
    
    if (path.empty()) {
        // User did not specify specify an output filename, use the input filename with a .prgm extension.
        path = inpath;
        path.replace_extension(".prgm");
        return path;
    }
    
    if (fs::is_directory(path)) {
        /* User did not specify specify an output filename but has specified a path, so append
         with the input filename and subtitute the extension with .prgm
         */
        path = path / inpath.stem();
        path.replace_extension("prgm");
        return path;
    }
    
    if (!path.has_extension()) path.replace_extension("prgm");
    if (path.parent_path().empty()) path = inpath.parent_path() / path;
    
    return path;
}

// MARK: - Main
int main(int argc, const char * argv[]) {
    std::string prefix, sufix, name;
    fs::path inpath, outpath;
    
    int columns = 8;
    std::string grob("G0");
    bool le = true;
    bool data = false;
    
    std::string utf8;
    std::ostringstream os;

    if ( argc == 1 )
    {
        error();
        exit( 0 );
    }
   
    for( int n = 1; n < argc; n++ ) {
        std::string args = argv[n];
        
        if (args == "-o" || args == "--outfile") {
            if ( ++n >= argc ) {
                error();
                exit(0);
            }
            outpath = resolveOutputFile(argv[n]);
            continue;
        }
        
        if (args == "--data") {
            data = true;
            continue;
        }
        
        if (args == "--help") {
            help();
            exit(0);
        }
        
        if (args == "--version") {
            std::cout << VERSION_NUMBER << "." << BUNDLE_VERSION << "\n";
            return 0;
        }
        
        if (args == "--build") {
            std::cout << NUMERIC_BUILD << "\n";
            return 0;
        }
        
        if (args == "--pragma") {
            utf8.append("#pragma mode( separator(.,;) integer(h64) )\n\n");
            continue;
        }
        
        if (args == "--endian") {
            if ( n + 1 >= argc ) {
                exit(0);
            }
            
            n++;
            if (strcmp( argv[n], "le" ) == 0) le = true;
            if (strcmp( argv[n], "be" ) == 0) le = false;
        
            continue;
        }
        
        if (args.substr(0,2) == "-G") {
            grob = args.substr(1);
            continue;
        }
        
        if (args == "-c") {
            if ( n + 1 >= argc ) {
                exit(0);
            }
            
            n++;
            columns = atoi(argv[n]);
        
            continue;
        }
        
        if (args == "-n")
        {
            if ( n + 1 >= argc ) {
                error();
                exit(-1);
            }
            
            n++;
            name = argv[n];
        
            continue;
        }
        
        inpath = resolveAndValidateInputFile(argv[n]);
    }
    outpath = resolveOutputPath(inpath, outpath);

    if (name == "*") {
        name = inpath.stem().string();
        name = regex_replace(name, std::regex(R"([-.])"), "_");
    }
    
    // Start measuring time
    Timer timer;
    
    size_t lengthInBytes = 0;
    image::TImage bitmap{};
    
    auto ext = std::lowercased(inpath.extension().string());
    if (ext == ".bmp") bitmap = bmp::load(inpath);
#if __APPLE__
    if (ext == ".png") bitmap = png::load(inpath);
#endif
    if (ext == ".pbm") bitmap = pbm::load(inpath);
    
    if (bitmap.bytes.empty()) {
        lengthInBytes = loadBinaryFile(inpath.string().c_str(), bitmap);
    } else {
        switch (bitmap.bpp) {
            case 1:
                lengthInBytes = bitmap.width * bitmap.height / 8;
                columns = bitmap.width / 64;
                bitmap.palette.resize(0);
                bitmap.palette.push_back(0xFFFFFFFF);
                bitmap.palette.push_back(0xFF);
                if (!bitmap.bytes.empty()) {
                    uint8_t *bytes = (uint8_t *)bitmap.bytes.data();
                    for (int i = 0; i < lengthInBytes; i += 1) {
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
                lengthInBytes = bitmap.width * bitmap.height / 2;
                columns = bitmap.width / 16;
                if (!bitmap.bytes.empty() && le) {
                    /*
                     Due to the use of little-endian format, when the 8-byte sequence
                     is interpreted as a single 64-bit number, the bytes are stored in
                     reverse order (from least significant to most significant).
                     Since this data represents an image where each nibble corresponds
                     to an index, we must first swap the nibbles in the entire data
                     sequence to ensure they remain in the correct order when read from
                     right to left.
                     */
                    
                    uint8_t *bytes = (uint8_t *)bitmap.bytes.data();
                    for (int i = 0; i < lengthInBytes; i += 1) {
                        // Swap nibbles
                        bytes[i] = bytes[i] >> 4 | bytes[i] << 4;
                    }
                }
                break;
                
            case 8:
                lengthInBytes = bitmap.width * bitmap.height;
                columns = bitmap.width / 8;
                break;
                
            case 16:
                lengthInBytes = bitmap.width * bitmap.height * 2;
                break;
                
            case 32:
                lengthInBytes = bitmap.width * bitmap.height * 4;
                break;
                
            default:
                return -1;
                break;
        }
    }

    if (columns < 1) columns = 1;
    
    switch (bitmap.bpp) {
        case 0:
            if (name.size()) utf8 += name + " := ";
            utf8 += "{\n" + ppl(bitmap.bytes.data(), lengthInBytes, columns, le) + "\n}";
            break;

        case 1:
        case 4:
        case 8:
            if (name.size()) os << name << " := ";
            os << "{\n";
            os << "  {\n" << ppl(bitmap.bytes.data(), lengthInBytes, columns, le) << "\n  },\n";
            os << "  { " << std::dec << std::to_string(bitmap.width) << ", " << std::to_string(bitmap.height) << ", " << std::to_string(bitmap.bpp) << " },\n";

            os << "  {\n    ";
            for (int i = 0; i < bitmap.palette.size(); i += 1) {
                uint32_t color = bitmap.palette.at(i);
#ifdef __LITTLE_ENDIAN__
                color = std::byteswap(color);
#endif
                color &= 0xFFFFFF;
                if (i) os << ", ";
                if (i % 16 == 0 && i) os << "\n    ";
                os << "#" << std::uppercase << std::hex << std::setfill('0') << std::setw(6) << color << ":32h";
            }
            os << "\n  }\n}";
            
            utf8.append(os.str());
            break;

        default:
            if (data) {
                os << "{\n" << ppl(bitmap.bytes.data(), lengthInBytes, columns, le) << "\n};\n";
            } else {
                if (name.size()) os << name << " := ";
                os << "{\n";
                os << "  {\n" << ppl(bitmap.bytes.data(), lengthInBytes, columns, le) << "\n  },\n";
                os << "  { " << std::dec << std::to_string(bitmap.width) << ", " << std::to_string(bitmap.height) << ", " << std::to_string(bitmap.bpp) << " }\n";
                os << "}";
            }
            utf8.append(os.str());
            break;
    }

    if (outpath == "/dev/stdout") {
        std::cout << utf8;
    } else {
        auto extension = std::lowercased(outpath.extension().string());
        
        if (extension == ".prgm" || extension == ".hpprgm") {
            if (extension == ".hpprgm") {
                hpprgm::create(outpath, "", utf8);
            } else {
                std::wstring utf16 = utf::utf16(utf8);
                utf::save(outpath, utf16);
            }
        } else {
            utf::save(outpath, utf8);
        }
        
        if (fs::exists(outpath)) {
            std::cerr << "Successfully created " << outpath.filename() << "\n";
        } else {
            std::cerr << "❌ Unable to create file " << outpath.filename() << ".\n";
            return 0;
        }
    }

    // Stop measuring time and calculate the elapsed time.
    long long elapsed_time = timer.elapsed();
    
    // Display elasps time in secononds.
    if (elapsed_time / 1e9 < 1.0) {
        std::cerr << "✅ Completed in " << std::fixed << std::setprecision(2) << elapsed_time / 1e6 << " milliseconds\n";
    } else {
        std::cerr << "✅ Completed in " << std::fixed << std::setprecision(2) << elapsed_time / 1e9 << " seconds\n";
    }
    
    return 0;
}
