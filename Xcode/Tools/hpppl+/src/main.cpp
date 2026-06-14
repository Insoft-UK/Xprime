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

#include <iostream>
#include <fstream>
#include <sstream>
#include <regex>
#include <cstring>
#include <iomanip>
#include <cmath>
#include <sys/time.h>
#include <ctime>
#include <vector>
#include <array>
#include <iterator>
#include <cstdlib>
#include <cctype>
#include <algorithm>
#include <string>
#include <ranges>
#include <unordered_set>

#include "timer.hpp"
#include "singleton.hpp"

#include "directives.hpp"
#include "dictionary.hpp"
#include "alias.hpp"
#include "base.hpp"
#include "calc.hpp"
#include "utf.hpp"
#include "hpprgm.hpp"
#include "strings.hpp"
#include "hpppl.hpp"
#include "unary.hpp"
#include "minifier.hpp"
#include "reformat.hpp"
#include "extensions.hpp"
#include "tool.hpp"
#include "pascal.hpp"

#include "../version_code.h"

#define NAME "HP PPL+ Pre-Processor for HP PPL"
#define COMMAND_NAME "hpppl+"
#define INDENT_WIDTH indentation

static unsigned int indentation = 2;

using hppplplus::Singleton;
using hppplplus::Aliases;
using hppplplus::Alias;
using hppplplus::Calc;
using hppplplus::Dictionary;
using hppplplus::Directives;
using hppplplus::Base;

using std::regex_replace;
using std::sregex_iterator;
using std::sregex_token_iterator;

namespace fs = std::filesystem;
namespace rc = std::regex_constants;

static Directives directives = Directives();

typedef struct {
    std::string command;
    std::string extension;
    std::vector<std::string> arguments; // Unused
} addon_t;

static std::vector<addon_t> addons = {};

std::string include(const std::filesystem::path& path);

// MARK: - Other

void terminator() {
    std::cerr << MessageType::CriticalError << "An internal pre-processing problem occurred at line:" << Singleton::shared()->currentLineNumber() << "\nPlease review the syntax before this point.\n";
    exit(1);
}
void (*old_terminate)() = std::set_terminate(terminator);

std::string translatePPLPlusToPPL(const fs::path& path);

// MARK: - PPL+ To PPL Translater...

std::string translatePPLPlusLine(const std::string& input) {
    std::regex re;
    std::smatch match;
    std::ifstream infile;
    std::string output = input;
    
    // Remove any leading white spaces before or after.

    if (output.empty()) {
        return output;
    }
    
    output = directives.parse(output);

    /*
     While parsing the contents, strings may inadvertently undergo parsing, leading
     to potential disruptions in the string's content as well as comments.
     
     To address this issue, we prioritize the preservation of any existing strings
     and comments. After we prioritize the preservation of any existing strings and
     comments, we blank out the string/s.
     
     Subsequently, after parsing, any strings that have been blanked out can be
     restored to their original state.
     */
    auto strings = preserveStrings(output);
    output = blankOutStrings(output);
 
    std::string comment = extractComment(output);
    output = removeComment(output);
    
    // Resolve all regular expressions
    Singleton::shared()->regexp.applyAllRegularExpressions(output);
    output = processEscapes(output);
    
    output = replaceOperators(output);
    output = fixUnaryMinus(output);
    
    output = Singleton::shared()->aliases.resolveAllAliasesInText(output);
   
    /*
     A code stack provides a convenient way to store code snippets
     that can be retrieved and used later.
     */
    output = Singleton::shared()->codeStack.parse(output);

    if (Dictionary::isDictionaryDefinition(output)) {
        Dictionary::proccessDictionaryDefinition(output);
        output = Dictionary::removeDictionaryDefinition(output);
        if (output.empty())
            return "";
    }

    output = replaceWords(output, {"var"}, "LOCAL");
    output = regex_replace(output, std::regex(R"(\bloop\b)", std::regex_constants::icase), "WHILE 1 DO");
    output = capitalizeWords(output, {"log", "cos", "sin", "tan", "ln", "min", "max"});
    
    //MARK: User Define Alias Parsing
    output = Alias::parse(output);
    
    if (Singleton::shared()->scopeDepth > 0) {
        output = replaceWords(output, {"begin"}, "");
    }
    // Keywords
    output = capitalizeWords(output, {
        "end", "return", "kill", "if", "then", "else", "xor", "or", "and", "not",
        "case", "default", "iferr", "ifte", "for", "from", "step", "downto", "to", "do",
        "while", "repeat", "until", "break", "continue", "const", "local",
        "eval", "freeze", "view", "begin", "export", "const", "local"
    });
    
    re = R"(\b(BEGIN|IF|FOR|CASE|REPEAT|WHILE|IFERR)\b)";
    for(auto it = sregex_iterator(output.begin(), output.end(), re); it != sregex_iterator(); ++it) {
        Singleton::shared()->increaseScopeDepth();
    }
    
    re = R"(\b(END|UNTIL)\b)";
    for(auto it = sregex_iterator(output.begin(), output.end(), re); it != sregex_iterator(); ++it) {
        Singleton::shared()->decreaseScopeDepth();
        Singleton::shared()->aliases.removeAllOutOfScopeAliases();
        Singleton::shared()->regexp.removeAllOutOfScopeRegexps();
    }
    
    if (Singleton::shared()->scopeDepth == 0) {
        re = R"(^ *(KS?A?_[A-Z\d][a-z]*) *$)";
        sregex_token_iterator it = sregex_token_iterator {
            output.begin(), output.end(), re, {1}
        };
        if (it != sregex_token_iterator()) {
            std::string s = *it;
            output = "KEY " + s + "()";
        }
    }
    
    output = Calc::parse(output);
    output = Base::parse(output);
    
    // Include
    if (Directives::isIncludeDirective(output)) {
        Singleton& singleton = *Singleton::shared();
        auto path = singleton.currentSourceFilePath();
        std::filesystem::path includePath = Directives::extractIncludeDirective(input);
        static const std::regex re(
                                   R"(\{\$(?:INCLUDE|I) +[\w \-_~,;\[\]\(\).']+ *\})",
                                   std::regex_constants::icase
                                   );
        std::string ext = std::lowercased(includePath.extension().string());
        if (ext != ".hppplplus" || ext != ".hpppl+") {
            if (includePath.parent_path().empty() && !fs::exists(includePath))
                includePath = path.parent_path() / includePath;
        }
        
        auto content = include(includePath);
        output = std::regex_replace(output, re, content);
    }
    
    
    output = restoreStrings(output, strings);
    
    if (!comment.empty()) output += comment;

    if (output.empty())
        return "";
    return output + "\n";
}


void loadRegexLib(const fs::path path, const bool verbose) {
    std::string utf8;
    std::ifstream infile;
    
    infile.open(path, std::ios::in);
    if (!infile.is_open()) {
        return;
    }
    
    if (verbose) std::cerr << "Library " << (path.filename() == ".base.re" ? "base" : path.stem()) << " successfully loaded.\n";
    
    while (getline(infile, utf8)) {
        utf8.insert(0, "regex ");
        Singleton::shared()->regexp.parse(utf8);
    }
    
    infile.close();
}

void loadRegexLibs(const std::filesystem::path& path, const bool verbose) {
    if (path.empty()) return;
    loadRegexLib(path / "base.re", verbose);
    
    try {
        for (const auto& entry : fs::directory_iterator(path)) {
            if (fs::path(entry.path()).extension() != ".re" || fs::path(entry.path()).filename() == "base.re") {
                continue;
            }
            loadRegexLib(entry.path(), verbose);
        }
    } catch (const fs::filesystem_error& e) {
        std::cerr << "error: " << e.what() << '\n';
    }
}

std::string include(const std::filesystem::path& path) {
    std::string output;
    auto ext = std::lowercased(path.extension().string());
    
    if (!fs::exists(path)) {
        std::cerr << MessageType::Verbose << path.filename() << " file not found\n";
        return output;
    }
    
    if (ext == ".hppplplus" || ext == ".hpppl+") {
        output = translatePPLPlusToPPL(path);
    }
    
    if (ext == ".hpppl") {
        output = utf::load(path);
    }
    
    if (!addons.empty()) {
        for (const addon_t &addon : addons) {
            if (ext != addon.extension) continue;
            std::vector<std::string> arguments = {path.string(), "-o", "/dev/stdout"};
            arguments.insert(arguments.end(), addon.arguments.begin(), addon.arguments.end());
            auto result = tool::runTool(addon.command, arguments);
            if (result.exitCode == 0) {
                output = result.out;
            }
            break;
        }
    }
    
    if (output.empty()) {
        utf::BOM bom = utf::bom(path);
        if (bom == utf::BOM::none) {
            output = utf::load(path);
        } else {
            auto utf16 = utf::load(path, bom);
            output = utf::to_string(utf16);
        }
    }
    
    return output;
}

bool verbose(void) {
    if (Singleton::shared()->aliases.verbose) return true;
    if (directives.verbose) return true;
    
    return false;
}

enum BlockType
{
    BlockType_Python, BlockType_PPL, BlockType_PrimePlus
};

bool isPythonBlock(const std::string& str) {
    return str.find("#PYTHON") != std::string::npos;
}

bool isPPLBlock(const std::string& str) {
    return str.find("#PPL") != std::string::npos;
}

std::string processPPLBlock(std::istringstream& iss) {
    std::string str;
    std::string output;
    
    Singleton::shared()->incrementLineNumber();
    
    while(getline(iss, str)) {
        if (str.find("#END") != std::string::npos) {
            Singleton::shared()->incrementLineNumber();
            return output;
        }
        
        output += str + '\n';
        Singleton::shared()->incrementLineNumber();
    }
    return str;
}

std::string processPythonBlock(std::istringstream& iss, const std::string& input) {
    std::regex re;
    std::string str;
    std::string output;
    std::smatch match;
    
    Aliases aliases;
    aliases.verbose = Singleton::shared()->aliases.verbose;
    
    Singleton::shared()->incrementLineNumber();
    
    str = cleanWhitespace(input);

    size_t start = str.find('(');
    size_t end = str.find(')', start);
        
    if (start != std::string::npos && end != std::string::npos && end > start) {
        std::vector<std::string> arguments = splitCommas(input.substr(start + 1, end - start - 1));
        output = "#PYTHON (";
        int index = 0, n = 0;
        
        Aliases::TIdentity identity = {
            .type = Aliases::Type::Argument
        };
        for (const std::string& argument : arguments) {
            if (index++) output.append(",");
            start = argument.find(':');
            
            if (start != std::string::npos) {
                output.append(argument.substr(0, start));
                identity.identifier = argument.substr(start + 1, argument.length() - start - 1);
                identity.real = "argv[" + std::to_string(n++) + "]";
                aliases.append(identity);
                continue;
            }
            output.append(argument);
        }
        output.append(")\n");
    } else {
        output = "#PYTHON\n";
    }

    while(getline(iss, str)) {
        if (str.find("#END") != std::string::npos) {
            output += "#END\n";
            Singleton::shared()->incrementLineNumber();
            return output;
        }
        
        Singleton::shared()->incrementLineNumber();
        str = aliases.resolveAllAliasesInText(str);
        
        // alias aliasname as realname
        re = R"(^ *alias +([A-Za-z_]\w*) *as *([a-zA-Z][\w\[\]]*) *$)";
        if (regex_search(str, match, re)) {
            Aliases::TIdentity identity;
            identity.identifier = match[1].str();
            identity.real = match[2].str();
            identity.type = Aliases::Type::Alias;
            identity.scope = -1;
            
            aliases.append(identity);
            str = "";
            continue;
        }
        
        output += str + '\n';
    }
    return output;
}

static bool is_all_whitespace(const std::string& s) {
    auto trimmed = s
        | std::views::filter([](unsigned char c){ return !std::isspace(c); });

    return trimmed.begin() == trimmed.end();
}

std::string translatePPLPlusToPPL(const fs::path& path) {
    Singleton& singleton = *Singleton::shared();
    std::istringstream hppplplus;
    std::regex re;
    std::string input;
    std::string output;
    std::string code;

    singleton.pushPath(path);
    code = utf::load(path);
    
    hppplplus.str(code);
    while (getline(hppplplus, input)) {
        /*
         Handle any escape lines `\` by continuing to read line joining them all up as one long line.
         */
        
        if (!input.empty()) {
            while (input.at(input.length() - 1) == '\\' && !input.empty()) {
                input.resize(input.length() - 1);
                std::string s;
                getline(hppplplus, s);
                input.append(s);
                Singleton::shared()->incrementLineNumber();
                if (s.empty()) break;
            }
        } else {
            Singleton::shared()->incrementLineNumber();
            output += "\n";
            continue;
        }
        
        input = removeTripleSlashComment(input);
        
        input = regex_replace(input, std::regex(R"(\t)"), std::string(INDENT_WIDTH, ' '));
        
        if (input.find("#EXIT") != std::string::npos) {
            break;
        }
        
        while (directives.disregard == true) {
            input = directives.parse(input);
            Singleton::shared()->incrementLineNumber();
            getline(hppplplus, input);
        }
        
        if (isPythonBlock(input)) {
            output += processPythonBlock(hppplplus, input);
            continue;
        }
        
        if (isPPLBlock(input)) {
            output += processPPLBlock(hppplplus);
            continue;
        }
        
        // Addons
        std::smatch match;
        re = std::regex(
            R"(^ *\{\$ADDON +([\w \-_~,;\[\]\(\).']+)(\.[a-z0-9]{1,10}) *\} *$)",
            std::regex_constants::icase
        );
        if (std::regex_search(input, match, re)) {
            addons.push_back({
                .command = match.str(1),
                .extension = match.str(2)
            });
            continue;
        }
        
        // Unit
        re = std::regex(
            R"(^ *unit +([\w \-_~,;\[\]\(\).']+) *$)",
            std::regex_constants::icase
        );
        if (std::regex_search(input, match, re)) {
            fs::path file = match.str(1);
            for (const auto& path : directives.systemIncludePath) {
                if (file.parent_path().empty())
                    file = path / file;
                if (file.has_extension() == false) {
                    file.replace_extension("hpppl+");
                }
                if (fs::exists(file)) {
                    output += translatePPLPlusToPPL(file);
                    continue;
                }
            }
              
            continue;
        }
        
        // Handle `#pragma mode` for PPL+
        if (input.find("#pragma mode") != std::string::npos) {
            re = R"(([a-zA-Z]\w*)\(([^()]*)\))";
            std::string s = input;
            input = "";
            for(auto it = sregex_iterator(s.begin(), s.end(), re); it != sregex_iterator(); ++it) {
                if (it->str(1) == "indentation") {
                    indentation = atoi(it->str(2).c_str());
                    continue;
                }
                
                if (it->str(1) == "separator" || it->str(1) == "integer") {
                    input.append(it->str() + " ");
                    continue;
                }
            }
            if (input.size()) {
                output += "#pragma mode( " + input + ")\n";
            }
            Singleton::shared()->incrementLineNumber();
            continue;
        }
        
        if (Singleton::shared()->regexp.parse(input)) {
            input = regex_replace(input, std::regex(R"(^ *\bregex +([@<>=≠≤≥~])?`([^`]*)`(i)? *(.*)$)"), "");
            Singleton::shared()->incrementLineNumber();
            continue;
        }
       
        std::istringstream iss;
        iss.str(input);
        std::string str;
        

        while(getline(iss, str)) {
            std::string s = translatePPLPlusLine(str);
            if (is_all_whitespace(s)) {
                continue;
            }
            output += s;
        }
        
        Singleton::shared()->incrementLineNumber();
    }
    
    singleton.popPath();
    
    // Removes `uses`
    output = regex_replace(output, std::regex(R"(\buses\s+([^;]+);)", std::regex_constants::icase), "\n");
    
    // Collapse multiple consecutive blank lines into a single blank line.
    output = regex_replace(output, std::regex(R"(\n{3,})"), "\n\n");
    
    return output;
}


// MARK: - Command Line
void error(void) {
    std::cerr << COMMAND_NAME << ": try '" << COMMAND_NAME << " --help' for more information\n";
    exit(1);
}


void help(void) {
    using namespace std;
    std::cerr
    << "Copyright (C) 2023-" << YEAR << " Insoft.\n"
    << "Insoft "<< NAME << " version, " << VERSION_NUMBER << " (BUILD " << BUNDLE_VERSION << ")\n"
    << "\n"
    << "Usage: " << COMMAND_NAME << " <input-file> [-o <output-file>] [-v]\n"
    << "\n"
    << "Options:\n"
    << "  -o <output-file>        Specify the filename for generated code.\n"
    << "  -c or --compress        Specify whether the PPL code should be compressed.\n"
    << "  -r or --reformat        Specify whether the PPL code should be reformatted.\n"
    << "  -n or --named           Create the .hpprgm as a named program.\n"
    << "  --indent                Set the indentation width for reformatting."
    << "  -v or --verbose         Display detailed processing information.\n"
    << "\n"
    << "Additional Commands:\n"
    << "  " << COMMAND_NAME << " {--version | --help }\n"
    << "    --version              Display the version information.\n"
    << "    --help                 Show this help message.\n";
}

fs::path resolveAndValidateInputFile(const char *input_file) {
    fs::path path;
    
    path = input_file;
    if (path == "/dev/stdin") return path;
    
    path = fs::expand_tilde(path);
    if (path.parent_path().empty()) path = fs::path("./") / path;
    
    if (path.has_extension() == false) {
        // default extension
        path.replace_extension("hppplplus");
    }
    
    std::string in_ext = std::lowercased(path.extension().string());
    std::array<std::string, 7> extensions = {
        ".hpppl",
        ".hppplplus",
        ".hpppl+"
        ".pas"
    };
    auto bom = utf::bom(path);
    for (auto extension : extensions) {
        if (in_ext == extension) {
            if (bom != utf::BOM::none) {
                std::cerr << "❓File " << path.filename() << " not utf-8 at " << path.parent_path() << " location.\n";
                exit(1);
            }
        }
    }
    
    
    if (!fs::exists(path)) {
        std::cerr << "❓File " << path.filename() << " not found at " << path.parent_path() << " location.\n";
        exit(1);
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
        // User did not specify specify an output filename, use the input filename with a .hpppl extension.
        path = inpath;
        path.replace_extension(".hpppl");
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
int main(int argc, char **argv) {
    fs::path inpath, outpath;
    
    if (argc == 1) {
        error();
        exit(100);
    }
    
    bool verbose = false;
    bool minify = false;
    bool reformat = false;
    bool includeProgramName = false;
    
    std::string args(argv[0]);
    
    for (int n = 1; n < argc; n++) {
        args = argv[n];
        
        if (args.at(0) == '-') {
            if (args == "-o") {
                if ( ++n >= argc ) {
                    error();
                    exit(1);
                }
                outpath = resolveOutputFile(argv[n]);
                continue;
            }
            
            if ( args == "-c" || args == "--compress" ) {
                minify = true;
                reformat = false;
                continue;
            }
            
            if ( args == "-r" || args == "--reformat" ) {
                reformat = true;
                minify = false;
                continue;
            }
            
            if ( args == "--indent" ) {
                if ( ++n >= argc ) {
                    error();
                    exit(1);
                }
                indentation = std::atoi(argv[n]);
                continue;
            }
            
            if ( args == "-n" or args == "--named" ) {
                includeProgramName = true;
                continue;
            }
            
            if ( args == "-h" or args == "--help" ) {
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
            
            if (args == "-v" || args == "--verbose") {
                Singleton::shared()->aliases.verbose = true;
                directives.verbose = true;
                Singleton::shared()->regexp.verbose = true;
                verbose = true;
                
                continue;
            }
            
            if (args.starts_with("-I")) {
                fs::path path = fs::path(args.substr(2)).has_filename() ? fs::path(args.substr(2)) : fs::path(args.substr(2)).parent_path();
                path = fs::expand_tilde(path);
                directives.systemIncludePath.push_front(path);
                continue;
            }
            
            if (args.starts_with("-L")) {
                fs::path path = fs::path(args.substr(2)).has_filename() ? fs::path(args.substr(2)) : fs::path(args.substr(2)).parent_path();
                loadRegexLibs(fs::expand_tilde(path), verbose);
                continue;
            }
            
            error();
            exit(1);
        }
        
        inpath = resolveAndValidateInputFile(argv[n]);
    }
    
    outpath = resolveOutputPath(inpath, outpath);
    
    if (outpath == inpath) {
        std::cerr << "❌ error: Input file and output file cannot be the same. Choose a different output path.\n";
        exit(1);
    }
    
    auto in_ext = std::lowercased(inpath.extension().string());
    auto out_ext = std::lowercased(outpath.extension().string());
    
    
    std::string str;
    
    str = "{$DEFINE __hppplplus}";
    directives.parse(str);
    
    // Start measuring time
    Timer timer;
    
    std::string output;
    
    std::array<std::string, 2> extensions = {
        ".hppplplus",
        ".hpppl+"
    };
    for (auto extension : extensions) {
        if (in_ext == extension) {
            std::cerr << "Pre-Processing...\n";
            output = translatePPLPlusToPPL(inpath);
            if (hasErrors() == true) {
                std::cerr << "🛑 errors!" << "\n";
            }
            break;
        }
    }
    
    if (in_ext == ".pas") {
        std::cerr << "Pre-Processing...\n";
        auto code = utf::load(inpath);
        output = hppplplus::pascal::convertPascalSyntax(code);
        if (hasErrors() == true) {
            std::cerr << "🛑 errors!" << "\n";
        }
    }
    
    
    if (output.empty()) {
        if (in_ext == ".hpprgm" || in_ext == ".hpappprgm") {
            std::wstring prgm = hpprgm::source(inpath);
            output = utf::to_string(prgm);
        }
    }
    
    if (output.empty()) {
        for (const addon_t &addon : addons) {
            if (in_ext != addon.extension) continue;
            std::vector<std::string> arguments = {inpath.string(), "-o", "/dev/stdout"};
            arguments.insert(arguments.end(), addon.arguments.begin(), addon.arguments.end());
            auto result = tool::runTool(addon.command, arguments);
            if (result.exitCode == 0) {
                output = result.out;
            }
            break;
        }
    }
    
    if (output.empty()) {
        auto bom = utf::bom(inpath);
        if (bom != utf::BOM::none) {
            auto prgm = utf::load(inpath, bom);
            output = utf::to_string(prgm);
        } else {
            output = utf::load(inpath);
        }
    }
    
    if (reformat == true) {
        output = reformat::prgm(output, indentation);
    }
    
    if (minify == true) {
        // Percentage Reduction = (Original Size - New Size) / Original Size * 100
        std::ifstream::pos_type original_size = output.length();
        output = minifier::minify(output);
        std::ifstream::pos_type new_size = output.length();
        
        // Create a locale with the custom comma-based numpunct
        std::locale commaLocale(std::locale::classic(), new comma_numpunct);
        std::cerr.imbue(commaLocale);
        
        std::cerr << "PPL Code (deflated " << (original_size - new_size) * 100 / original_size << "%)\n";
    }
    
    
    if (outpath == "/dev/stdout") {
        std::cout << output;
        std::cerr << '\n';
    } else {
        if (out_ext == ".hpprgm" || out_ext == ".hpappprgm") {
            auto programName = inpath.stem().string();
            hpprgm::write(outpath, output, includeProgramName);
        } else {
            if (!utf::save(outpath, utf::to_wstring(output), utf::BOM::le)) {
                std::cerr << "❌ Unable to create file " << outpath.filename() << ".\n";
                exit(1);
            }
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

