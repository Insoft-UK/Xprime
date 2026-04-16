// The MIT License (MIT)
//
// Copyright (c) 2023-2025 Insoft.
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


#ifndef ALIASES_HPP
#define ALIASES_HPP

#include <iostream>
#include <list>
#include <vector>
#include <stdint.h>
#include <fstream>
#include <filesystem>

namespace pplplus {
    class Aliases {
    public:
        enum class Type {
            Unknown,
            Macro,
            Alias,
            Function,
            Argument,
            Variable
        };
        

        typedef struct TIdentity {
            std::string identifier;
            std::string real;
            Type type;
            int scope;
            long line;              // line that definition accoured;
            std::filesystem::path path;   // path and filename that definition accoured
            bool deprecated = false;
            std::string message;    // Used by deprecated, holds the message for deprecated.
        } TIdentity;
        
        
        bool verbose = false;
        
        bool append(const TIdentity &identity);
        void removeAllOutOfScopeAliases();
        void removeAllAliasesOfType(const Type type);
        std::string resolveAllAliasesInText(const std::string &str);
        void remove(const std::string &identifier);
        
        bool identifierExists(const std::string &identifier);
        bool realExists(const std::string &real);
        
        void dumpIdentities();
        const TIdentity getIdentity(const std::string &identifier);
        
        
        
    private:
        std::vector<TIdentity> _identities;
    };
}
#endif // ALIASES_HPP
