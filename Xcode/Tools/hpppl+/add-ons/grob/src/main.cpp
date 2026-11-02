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

#include "image.hpp"
#include "DIMGROB_P.hpp"
#include "ICON.hpp"
#include "GROB.hpp"

#include "../version_code.h"
#include "timer.hpp"
#include "extensions.hpp"

#define NAME "HP GROB"
#define COMMAND_NAME "grob"
#define MAX_LIST_LENGTH 10000

namespace fs = std::filesystem;

// MARK: - Functions

static std::string expandHomeDirectory(const std::string &path) {
    if (path.starts_with("~/")) {
        const char* home = getenv("HOME");
        if (home) {
            return std::string(home) + path.substr(1);  // Replace '~' with $HOME
        }
    }
    return path;
}

static bool writeFile(const std::filesystem::path& path, const std::string& data) {
    std::ofstream file(path, std::ios::binary);
    if (!file) return false;

    file.write(data.data(), data.size());
    return file.good();
}


// MARK: - Command Line
static void printHelp(void)
{
    std::cerr
    << "Copyright (C) 2024-" << YEAR << " Insoft.\n"
    << "Insoft "<< NAME << " version, " << VERSION_NUMBER << " (BUILD " << BUNDLE_VERSION << ")\n"
    << "\n"
    << "Usage: " << COMMAND_NAME << " <input-file> [-o <output-file>] [-G<1-9>] \n"
    << "\n"
    << "Options:\n"
    << "  -o <output-file>           Specify the filename for generated code.\n"
    << "  -l --language <language>   Specify the output language (ppl or python).\n"
    << "\n"
    << "Additional Commands:\n"
    << "  " << COMMAND_NAME << " {--version | --help}\n"
    << "    --version                Display the version information.\n"
    << "    --help                   Show this help message.\n";
}


static void printUsageError(void) {
    std::cerr << COMMAND_NAME << ": try '" << COMMAND_NAME << " --help' for more information\n";
    exit(0);
}

fs::path resolveInputFilePath(const char *input_file) {
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

fs::path resolveOutputFilePath(const char *output_file) {
    fs::path path;
    
    path = output_file;
    if (path == "/dev/stdout") return path;
    
    path = fs::expand_tilde(path);
    
    return path;
}

fs::path determineOutputPath(const fs::path& inpath, const fs::path& outpath) {
    fs::path path = outpath;
    
    if (path == "/dev/stdout") return path;
    
    
    if (path.empty()) {
        // User did not specify specify an output filename, use the input filename with a .hpppl extension.
        path = inpath;
        path.replace_extension("hpppl");
        return path;
    }
    
    if (fs::is_directory(path)) {
        /* User did not specify specify an output filename but has specified a path, so append
         with the input filename and subtitute the extension with .hpppl
         */
        path = path / inpath.stem();
        path.replace_extension("hpppl");
        return path;
    }
    
    if (!path.has_extension()) path.replace_extension("hpppl");
    if (path.parent_path().empty()) path = inpath.parent_path() / path;
    
    return path;
}

// MARK: - Main
int main(int argc, const char * argv[]) {
    std::string prefix, sufix;
    fs::path inpath, outpath;
    
    unsigned int grob = 0;
    bool icon = false;

    
    std::string outpath_extension;
    
    std::string utf8;
    std::ostringstream os;

    if ( argc == 1 )
    {
        printUsageError();
        exit( 0 );
    }
   
    for( int n = 1; n < argc; n++ ) {
        std::string args = argv[n];
        
        if (args == "-o" || args == "--outfile") {
            if ( ++n >= argc ) {
                printUsageError();
                exit(0);
            }
            outpath = resolveOutputFilePath(argv[n]);
            continue;
        }
        
        if (args == "-l" || args == "--language") {
            if ( ++n >= argc ) {
                printUsageError();
                exit(0);
            }
            args = argv[n];
            
            if (args == "python") {
                outpath_extension = ".py";
            }
            
            if (args == "ppl") {
                outpath_extension = ".hpppl";
            }
            continue;
        }
        
        if (args == "--icon") {
            icon = true;
            continue;
        }
        
        if (args == "--help") {
            printHelp();
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
        
        if (args.substr(0,2) == "-G") {
            grob = std::atoi(args.substr(2).c_str());
            continue;
        }
        
        inpath = resolveInputFilePath(argv[n]);
    }
    outpath = determineOutputPath(inpath, outpath);
    if (outpath_extension.empty()) {
        outpath_extension = std::lowercased(outpath.extension().string());
    }
    
    // Start measuring time
    Timer timer;
    std::string output;
    
    if (icon) {
        output = hpprime::ICON(inpath);
    } else {
        image::Image image = image::loadImage(inpath);
        
        if (image.pixels.size() / 8 > 10000) {
            std::cerr << "⚠️ Image too large.\n";
            return 0;
        }
        
        if (grob != 0) {
            output = hpprime::DIMGROB_P(image, grob);
        } else {
            output = hpprime::GROB(image, outpath_extension == "py" ? hpprime::Language::Python : hpprime::Language::HPPPL);
            
            if (output.empty()) {
                std::cerr << "❌ Unable to create GROB " << outpath.filename() << ".\n";
                return 0;
            }
        }
    }
    

    if (outpath == "/dev/stdout") {
        std::cout << output;
        std::cerr << "\n";
    } else {
        writeFile(outpath, output);
        
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
