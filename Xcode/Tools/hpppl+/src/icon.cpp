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

#include "icon.hpp"
#include "inverter.hpp"
#include "singleton.hpp"

//#include <vector>
#include <regex>
#include <fstream>
#include <sstream>

using hppplplus::ICON;

static std::string pattern = R"(\bICON +\"((?:\\.|[^"\\])*)\" *;)";

static std::string generatePPLIconDirective(const std::string& filePath,
                      const std::string& iconName)
{
    std::ifstream file(filePath, std::ios::binary);

    if (!file)
        throw std::runtime_error("Cannot open PNG file: " + filePath);

    std::vector<std::uint8_t> data(
        std::istreambuf_iterator<char>(file),
        {}
    );

    // Validate the PNG signature.
    static constexpr std::uint8_t signature[] = {
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A
    };

    if (data.size() < sizeof(signature) ||
        !std::equal(std::begin(signature), std::end(signature),
                    data.begin()))
    {
        throw std::runtime_error("Invalid PNG file");
    }
    
    switch (PNG::getColourType(data)) {
        case PNG::ColourType::Indexed:
            // Palette-based PNG
            PNG::invertPNGTransparency(data); // HP Prime uses inverted transparency values.
            break;

        case PNG::ColourType::RGBA:
            // Truecolour with alpha channel
            PNG::invertRGBAAlpha(data);
            break;

        default:
            break;
    }
    
    std::ostringstream output;
    output << "ICON " << iconName << ' '
           << std::uppercase << std::hex << std::setfill('0');

    for (std::uint8_t byte : data)
        output << std::setw(2) << static_cast<unsigned>(byte);

    output << ';';
    return output.str();
}

bool ICON::isIconDirective(const std::string &str) {
    return regex_search(str, std::regex(pattern, std::regex_constants::icase));
}

std::string ICON::processIconDirective(const std::string &str) {
    std::smatch match;
    std::string code = str;
    static const std::regex re(
                               pattern,
                               std::regex_constants::icase
                               );
    
    if (!std::regex_search(str, match, re)) {
        return str;
    }
    
    std::filesystem::path path(match.str(1));
    std::string name;
    
    name = path.stem().string();
    name = regex_replace(name, std::regex(R"([-.])"), "_");
    
    
    if (path.parent_path().empty()) {
        path = Singleton::shared()->getMainSourceDir() / path;
    }
    

    return generatePPLIconDirective(path.string(), name);
}
