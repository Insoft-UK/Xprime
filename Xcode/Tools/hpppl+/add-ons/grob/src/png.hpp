// The MIT License (MIT)
//
// Copyright (c) 2024-2025 Insoft.
// Originally created in 2025
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


#ifndef png_hpp
#define png_hpp

#if __APPLE__

#include <cstdint>
#include <filesystem>
#include <vector>

#include "image.hpp"

namespace png {
    /**
     @brief    Loads a file in the Portable Network Graphics  (PNG) format.
     @param    path The pathname of the Portable Network Graphics  (PNG) to be loaded.
     @return   A structure containing the bitmap image data.
     */
    image::TImage load(const std::filesystem::path& path);
    
    /**
     @brief    Saves a file in the Portable Network Graphics  (PNG) format.
     @param    path The pathname of the Portable Network Graphics  (PNG) to be saved.
     @param    image A structure containing the bitmap image data.
     */
    bool save(const std::filesystem::path& path, const image::TImage &image);
}

#endif // __APPLE__

#endif /* png_hpp */
