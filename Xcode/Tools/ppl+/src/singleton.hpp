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


#ifndef SINGLETON_HPP
#define SINGLETON_HPP

#include <iostream>
#include <vector>
#include <filesystem>

#include "aliases.hpp"
#include "common.hpp"
#include "regexp.hpp"
#include "code_stack.hpp"

namespace pplplus {
    
    class Singleton {
        
    public:
        Aliases aliases;
        Regexp regexp;
        CodeStack codeStack;
        
        const int &scopeDepth;
        const int &count;
        
        static Singleton *shared();
        
        void incrementLineNumber(void);
        long currentLineNumber(void);
        std::filesystem::path mainSourceFilePath(void)
        {
            return std::filesystem::path(_paths.front());
        }
        
        std::filesystem::path currentSourceFilePath(void);
        
        std::filesystem::path getMainSourceDir(void)
        {
            return std::filesystem::path(_paths.front()).parent_path();
        }
        
        
        void pushPath(const std::filesystem::path &path);
        void popPath(void);
        
        void increaseScopeDepth(const std::string &endCode = "") {
            if (_scopeDepth == 0) {
                _store = _count;
                _count = 0;
            }
            _scopeDepth++;
        }
        
        void decreaseScopeDepth()
        {
            if (_scopeDepth == 0) {
                std::cout << "Error: Unexpected '" << "END; at line:" << _currentline << "'\n";
                return;
            }
            if (_scopeDepth == 1) {
                _count = _store;
            }
            _scopeDepth--;
            
        }
        
        void advanceCount(void) {
            _count++;
        }
        
        void resetCount(void) {
            _count = 0;
        }

        
    private:
        std::vector<std::filesystem::path> _paths;
        std::vector<long> _lines;
        static Singleton *_shared;
        
        int _scopeDepth;
        int _count;
        
        Singleton() : scopeDepth(_scopeDepth), count(_count) {
            _currentline = 1;
            _scopeDepth = 0;
            _count = 0;
        }
        Singleton(const Singleton &);
        Singleton &operator=(const Singleton &);
        
    protected:
        long _currentline;
        int _store = 0;
    };
}

#endif /* SINGLETON_HPP */
