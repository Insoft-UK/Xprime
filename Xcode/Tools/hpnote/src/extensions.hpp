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

#pragma once

#include <string>
#include <string_view>
#include <algorithm>
#include <cctype>

#if defined(__cpp_lib_byteswap)
    #include <bit>
#endif

namespace stdext {
    inline std::string lowercased(std::string_view s)
    {
        std::string result{s};
        std::transform(result.begin(), result.end(),
                       result.begin(),
                       [](unsigned char c) {
            return static_cast<char>(std::tolower(c));
        });
        return result;
    }
    
    inline std::string uppercased(std::string_view s)
    {
        std::string result{s};
        std::transform(result.begin(), result.end(),
                       result.begin(),
                       [](unsigned char c) {
            return static_cast<char>(std::toupper(c));
        });
        return result;
    }

#if defined(__cpp_lib_byteswap)
    using std::byteswap;
#else
    template <typename T>
    constexpr T byteswap(T value)
    {
        static_assert(std::is_integral_v<T>, "byteswap requires integral type");
        
        T result = 0;
        for (size_t i = 0; i < sizeof(T); ++i) {
            result <<= 8;
            result |= (value & 0xFF);
            value >>= 8;
        }
        return result;
    }
#endif
}
