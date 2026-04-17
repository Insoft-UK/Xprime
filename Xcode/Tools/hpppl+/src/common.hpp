// The MIT License (MIT)
//
// Copyright (c) 2024-2026 Insoft.
//
// Created: 2025-12-19
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

#pragma once

#ifndef common_hpp
#define common_hpp

#include <stdint.h>
#include <stdio.h>
#include <iostream>
#include <vector>
#include <ostream>
#include <fstream>
#include <filesystem>

#include "singleton.hpp"


//#define basename(path)  path.string().substr(path.string().find_last_of("/") + 1)



enum class MessageType {
    Warning,
    Error,
    CriticalError,
    Verbose,
    Deprecated,
    Tip
};


bool hasErrors(void);
std::ostream &operator<<(std::ostream &os, MessageType type);

std::string &ltrim(std::string &str);
std::string &rtrim(std::string &str);
std::string &trim(std::string &str);

std::string trim_copy(const std::string &str);

std::string &strip(std::string &str);
std::string strip_copy(const std::string &str);




#endif /* common_hpp */
