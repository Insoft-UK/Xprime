// The MIT License (MIT)
// 
// Copyright (c) 2026 Insoft.
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

#include <fstream>  // for file streams
#include <iostream> // for std::cout
#include <string>   // for std::string

#include "../version_code.h"
#include "timer.hpp"
#include "extensions.hpp"
#include "utf.hpp"

#include "ntf.hpp"
#include "hpnote.hpp"

#define NAME "HP Note"
#define COMMAND_NAME "note"

namespace fs = std::filesystem;

// MARK: - Functions
namespace std::filesystem {
    std::filesystem::path expand_tilde(const std::filesystem::path& path) {
        if (!path.empty() && path.string().starts_with("~")) {
#ifdef _WIN32
            const char* home = std::getenv("USERPROFILE");
#else
            const char* home = std::getenv("HOME");
#endif
            
            if (home) {
                return std::filesystem::path(std::string(home) + path.string().substr(1));  // Replace '~' with $HOME
            }
        }
        return path;  // return as-is if no tilde or no HOME
    }
}

// MARK: - Command Line

void help(void)
{
    std::cerr
    << "Copyright (C) " << YEAR << " Insoft.\n"
    << "Insoft "<< NAME << " version, " << VERSION_NUMBER << " (BUILD " << BUNDLE_VERSION << ")\n"
    << "\n"
    << "Usage: " << COMMAND_NAME << " <input-file>\n"
    << "  --cc                       Includes the plain-text carbon copy fallback used for recovery"
    << "                             if the formatted content is unreadable.\n"
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

fs::path resolveOutputExtension(const fs::path& inpath, const fs::path& outpath) {
    fs::path path = outpath;
    auto in_extension = std::lowercased(inpath.extension().string());
    
    if (in_extension == ".note" || in_extension == ".md" || in_extension == ".txt" || in_extension == ".ntf" || in_extension == ".rtf") {
        path.replace_extension("hpnote");
        return path;
    }
    
    path.replace_extension("note");
    return path;
}

fs::path resolveOutputPath(const fs::path& inpath, const fs::path& outpath) {
    fs::path path = outpath;
    
    if (path == "/dev/stdout") return path;

    if (path.empty()) {
        // User did not specify specify an output filename, use the input filename with a .hpnote extension.
        path = inpath;
        path = resolveOutputExtension(inpath, path);
        return path;
    }
    
    if (fs::is_directory(path)) {
        /* User did not specify specify an output filename but has specified a path, so append
         with the input filename and subtitute the extension with .hpnote or .note
         */
        path = path / inpath.stem();
        path = resolveOutputExtension(inpath, path);
        return path;
    }
    
    if (!path.has_extension()) {
        path = resolveOutputExtension(inpath, path);
    }
    if (path.parent_path().empty()) path = inpath.parent_path() / path;
    
    return path;
}

// MARK: - Main

int main(int argc, const char * argv[]) {
    std::string prefix, sufix, name;
    fs::path inpath, outpath;
    bool verbose = false;
    bool cc = false;

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
        
        if ( args == "--cc" ) {
            cc = true;
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
        
        if (args == "-v" || args == "--verbose") {
            verbose = true;
            continue;
        }
        
        inpath = resolveAndValidateInputFile(argv[n]);
    }
    
    outpath = resolveOutputPath(inpath, outpath);
    
    
    // Start measuring time
    Timer timer;
    
    std::u16string out;
    
    auto in_extension = std::lowercased(inpath.extension().string());
    auto out_extension = std::lowercased(outpath.extension().string());
 
    if (in_extension == ".md") {
        std::string md = utf::load(inpath);
        std::string ntf = ntf::markdownToNTF(md);
        ntf::defaultColorTable();
        out = hpnote::ntf_to_hpnote(ntf, cc);
    }
    
    if (in_extension == ".ntf") {
        std::string ntf = utf::load(inpath);
        ntf::defaultColorTable();
        out = hpnote::ntf_to_hpnote(ntf, cc);
    }
    
    if (in_extension == ".rtf") {
        std::string rtf = utf::load(inpath);
        std::string ntf = ntf::richTextToNTF(rtf);
        out = hpnote::ntf_to_hpnote(ntf, cc);
    }
    
    if (in_extension == ".txt") {
        out = utf::to_u16string(utf::load(inpath));
    }
    
    if (in_extension == ".note") {
        auto bom = utf::bom(inpath);
        if (bom == utf::BOM::none) {
            std::string ntf = utf::load(inpath);
            out = hpnote::ntf_to_hpnote(ntf, cc);
        } else {
            out = utf::to_u16string(utf::load(inpath, bom));
        }
    }
    
    if (in_extension == ".hpnote" || in_extension == ".hpappnote") {
        if (out_extension == ".ntf") {
            auto hpnote = utf::load(inpath, utf::BOM::none, true);
            std::u16string s = utf::to_u16string(hpnote);
            auto ntf = hpnote::to_ntf(s);
            out = utf::to_u16string(ntf);
        } else {
            auto s = utf::load(inpath, utf::BOM::none, false);
            out = utf::to_u16string(s);
        }
    }

    if (outpath == "/dev/stdout") {
        std::cout << utf::to_string(out);
    } else {
        if (out_extension == ".hpappnote")
            hpnote::to_hpappnote(out);
    
        if (out_extension == ".hpnote" || out_extension == ".hpappnote")
            utf::save(outpath, out, false);
        
        else
            utf::save(outpath, utf::to_string(out));
        
        
        if (!std::filesystem::exists(outpath)) {
            std::cerr << "❌ Unable to create file " << outpath.filename() << ".\n";
            return -1;
        }
    }

    // Stop measuring time and calculate the elapsed time.
    long long elapsed_time = timer.elapsed();
    
    
    std::cerr << "Successfully created " << outpath.filename() << "\n";
    
    // Display elasps time in secononds.
    if (elapsed_time / 1e9 < 1.0) {
        std::cerr << "✅ Completed in " << std::fixed << std::setprecision(2) << elapsed_time / 1e6 << " milliseconds\n";
    } else {
        std::cerr << "✅ Completed in " << std::fixed << std::setprecision(2) << elapsed_time / 1e9 << " seconds\n";
    }
    
    return 0;
}
