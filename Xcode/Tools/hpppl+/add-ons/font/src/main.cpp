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

#include <regex>

#include "../../../src/extensions.hpp"
#include "../../../src/timer.hpp"
#include "adafruit.hpp"
#include "utf.hpp"


namespace fs = std::filesystem;

static bool ppl = false;

#include "../version_code.h"
#define NAME "Adafruit GFX Font Converter"
#define COMMAND_NAME "font"

// MARK: - Command Line
void error(void) {
    std::cerr << COMMAND_NAME << ": try '" << COMMAND_NAME << " --help' for more information\n";
    exit(0);
}

void help(void) {
    std::cerr
    << "Insoft "<< NAME << " version, " << VERSION_NUMBER << " (BUILD " << BUNDLE_VERSION << ")\n"
    << "Copyright (C) " << YEAR << " Insoft.\n"
    << "\n"
    << "Usage: " << COMMAND_NAME << " <input-file> [-o <output-file>] [-n <name>] [-v flags]\n"
    << "\n"
    << "Options:\n"
    << "  -o <output-file>        Specify the filename for generated .hpprgm file.\n"
    << "  -c or --compress        Specify if the PPL code should be compressed.\n"
    << "  -n or --name            Specify the variable name to use.\n"
    << "\n"
    << "Additional Commands:\n"
    << "  " << COMMAND_NAME << " {--version | --help }\n"
    << "    --version              Display the version information.\n"
    << "    --help                 Show this help message.\n"
    << "    --ppl                  Only esesntial PPL code.\n";
}

// MARK: -

std::string cleanWhitespace(const std::string& input) {
    std::string output;
    bool lastWasWordChar = false;
    bool pendingSpace = false;

    auto isWordChar = [](char c) {
        /*
         by Jozef Dekoninck || c == '('
         Fixes an issue when parentheses after UNTIL, compression removes
         the space after UNTIL what gives an error in compression.
         */
        return std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '(' || c == ')';
    };

    for (char ch : input) {
        if (ch == '\n') {
            if (pendingSpace) {
                pendingSpace = false; // discard pending space before newline
            }
            output += '\n';
            lastWasWordChar = false;
            continue;
        }
        
        if (std::isspace(static_cast<unsigned char>(ch))) {
            if (lastWasWordChar) {
                pendingSpace = true;
            }
            continue;
        }
        
        if (pendingSpace && lastWasWordChar && isWordChar(ch)) {
            output += ' ';
        }
        output += ch;
        lastWasWordChar = isWordChar(ch);
        pendingSpace = false;
    }

    return output;
}

std::string normalizeOperators(const std::string& input, const std::vector<std::string> operators) {
    // List of all operators to normalize
        
        std::string result;
        size_t i = 0;

        while (i < input.size()) {
            bool matched = false;

            for (const std::string& op : operators) {
                if (input.compare(i, op.size(), op) == 0) {
                    if (!result.empty() && result.back() != ' ') result += ' ';
                    result += op;
                    i += op.size();
                    if (i < input.size() && input[i] != ' ') result += ' ';
                    matched = true;
                    break;
                }
            }

            if (!matched) {
                result += input[i++];
            }
        }

        // Final cleanup: collapse multiple spaces
        std::istringstream iss(result);
        std::string word, cleaned;
        while (iss >> word) {
            if (!cleaned.empty()) cleaned += ' ';
            cleaned += word;
        }

        return cleaned;
}

fs::path resolveAndValidateInputFile(const char *input_file) {
    fs::path path;
    
    path = input_file;
    if (path == "/dev/stdin") return path;
    
    path = fs::expand_tilde(path);
    if (path.parent_path().empty()) path = fs::path("./") / path;
    
    if (path.has_extension() == false) {
        // default extension
        path.replace_extension("h");
    }
    
    if (!fs::exists(path)) {
        std::cerr << "❓File " << path.filename() << " not found at " << path.parent_path() << " location.\n";
        exit(0);
    }
    
    return path;
}

std::string wrapAfterChars(const std::string& input, std::size_t maxLen, const std::vector<char>& breakChars)
{
    std::string result;
    result.reserve(input.size());

    std::size_t lineLen = 0;

    for (std::size_t i = 0; i < input.size(); ++i)
    {
        char c = input[i];
        result.push_back(c);

        if (c == '\n')
        {
            lineLen = 0;
            continue;
        }

        ++lineLen;

        // Only insert newline if:
        // 1) Line is too long
        // 2) Current character is in breakChars
        if (lineLen >= maxLen &&
            std::find(breakChars.begin(), breakChars.end(), c) != breakChars.end())
        {
            result.push_back('\n');
            lineLen = 0;
        }
    }

    return result;
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

int main(int argc, const char **argv)
{
    namespace fs = std::filesystem;
    
    if (argc == 1) {
        error();
        return 0;
    }
    
    bool minify = false;
    
    std::string args(argv[0]);
    std::string name, prefix, sufix;
    std::filesystem::path inpath, outpath;

    for( int n = 1; n < argc; n++ ) {
        if (*argv[n] == '-') {
            std::string args(argv[n]);
            
            if (args == "-o") {
                if ( ++n >= argc ) {
                    error();
                    exit(0);
                }
                outpath = resolveOutputFile(argv[n]);
                continue;
            }
            
            if ( args == "-c" || args == "--compress" ) {
                minify = true;
                continue;
            }

            if (args == "-n" || args == "name") {
                if (++n > argc) error();
                name = argv[n];
                continue;
            }

            if (args == "--help") {
                help();
                return 0;
            }
            
            if (args == "--version") {
                std::cout << VERSION_NUMBER << "." << BUNDLE_VERSION << "\n";
                return 0;
            }
            
            if (args == "--build") {
                std::cout << NUMERIC_BUILD << "\n";
                return 0;
            }
            
            if (args == "--ppl") {
                ppl = true;
                continue;
            }
            
            error();
            return 0;
        }
        
        inpath = resolveAndValidateInputFile(argv[n]);
    }
    
    outpath = resolveOutputPath(inpath, outpath);
    
    if (outpath == inpath) {
        std::cerr << "❌ error: Input file and output file cannot be the same. Choose a different output path.\n";
        exit(0);
        return 0;
    }
   
    // Start measuring time
    Timer timer;
   
    std::string output = adafruit::convertAdafruitFontToPPL(inpath, name);
    if (minify) {
        output = regex_replace(output, std::regex(R"(#0+)"), "#");
        output = normalizeOperators(output, {"{", "}"});
        output = cleanWhitespace(output);
        output = wrapAfterChars(output, 128, {',', ';', '}', '{'});
    }
    
    if (outpath == "/dev/stdout") {
        std::cout << output;
        std::cerr << '\n';
    } else {
        if (!utf::save(outpath, utf::utf16(output), utf::BOMle)) {
            std::cerr << "❌ Unable to create file " << outpath.filename() << ".\n";
            return 0;
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

