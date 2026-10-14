// The MIT License (MIT)
// 
// Copyright (c) 2024-2026 Insoft.
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

#include "pyminifier.hpp"

#include <fstream>
#include <iostream>
#include <string>
#include <locale>

#include "../version_code.h"
#include "timer.hpp"
#include "extensions.hpp"

#define NAME "Add-On"
#define COMMAND_NAME "addon"

namespace fs = std::filesystem;

// MARK: - Functions

// MARK: - Command Line

void help(void)
{
    std::cerr
    << "Copyright (C) 2024-" << YEAR << " Insoft.\n"
    << "Insoft "<< NAME << " version, " << VERSION_NUMBER << " (BUILD " << BUNDLE_VERSION << ")\n"
    << "\n"
    << "Usage: " << COMMAND_NAME << " <input-file>\n"
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
        path = inpath;
        path.replace_extension("min.py");
        return path;
    }
    
    if (fs::is_directory(path)) {
        path = path / inpath.stem();
        path.replace_extension("min.py");
        return path;
    }
    
    if (!path.has_extension()) path.replace_extension("min.py");
    if (path.parent_path().empty()) path = inpath.parent_path() / path;
    
    return path;
}

// Custom facet to use comma as the thousands separator
struct comma_numpunct : std::numpunct<char> {
protected:
    virtual char do_thousands_sep() const override {
        return ',';  // Define the thousands separator as a comma
    }

    virtual std::string do_grouping() const override {
        return "\3";  // Group by 3 digits
    }
};

// MARK: - Main

int main(int argc, const char * argv[]) {
    std::string prefix, sufix, name;
    fs::path inpath, outpath;

    if ( argc == 1 )
    {
        error();
        exit( 0 );
    }
   
    for( int n = 1; n < argc; n++ ) {
        std::string args = argv[n];
        
        if (args == "-o") {
            if ( ++n >= argc ) {
                error();
                exit(1);
            }
            outpath = resolveOutputFile(argv[n]);
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
        
        inpath = resolveAndValidateInputFile(argv[n]);
    }
    
    outpath = resolveOutputPath(inpath, outpath);
    
    // Start measuring time
    Timer timer;
    
    std::ifstream inputFile(inpath.string());
    
    std::string source((std::istreambuf_iterator<char>(inputFile)),
                        std::istreambuf_iterator<char>());
    
    PythonMinifier minifier;
    
    const std::string result = minifier.minify(source);
    
    std::cout << result;
    
    
    // Percentage Reduction = (Original Size - New Size) / Original Size * 100
    auto original_size = source.size();
    auto new_size = result.size();
    
    // Create a locale with the custom comma-based numpunct
    std::locale commaLocale(std::locale::classic(), new comma_numpunct);
    std::cerr.imbue(commaLocale);
    
    std::cerr << "Python Code (deflated " << (original_size - new_size) * 100 / original_size << "%)\n";
    
    if (outpath == "/dev/stdout")
    {
        std::cout << result;
        std::cerr << '\n';
    }
    else
    {
        std::ofstream outputFile(outpath.string());

        if (outputFile.is_open()) {
            outputFile << result;
            outputFile.close();

            if (!outputFile)
                throw std::runtime_error("Failed to write output file");
        } else {
            throw std::runtime_error("Failed to create output file");
        }
        std::cerr << "Successfully created " << outpath.filename() << "\n";
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
