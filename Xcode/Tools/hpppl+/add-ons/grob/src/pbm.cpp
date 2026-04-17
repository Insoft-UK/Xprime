// The MIT License (MIT)
//
// Copyright (c) 2024-2025 Insoft. All rights reserved.
// Originally created in 2023
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

#include "pbm.hpp"

#include <fstream>
#include <iostream>

using namespace image;

TImage pbm::load(const std::filesystem::path& path)
{
    std::ifstream infile;
    TImage image;
    
    infile.open(path.string(), std::ios::in | std::ios::binary);
    if (!infile.is_open()) return image;
    
    std::string s;
    
    getline(infile, s);
    if (s != "P4") {
        infile.close();
        return image;
    }
    
    image.bpp = 1;
    
    getline(infile, s);
    image.width = atoi(s.c_str());
    
    getline(infile, s);
    image.height = atoi(s.c_str());
    
    size_t length = ((image.width + 7) >> 3) * image.height;
    image.bytes.reserve(length);
    image.bytes.resize(length);
    
    infile.read((char *)image.bytes.data(), length);
    infile.close();
        
    return image;
}

