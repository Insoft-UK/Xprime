//
//  html.cpp
//  note
//
//  Created by Richie on 20/03/2026.
//

#include "html.hpp"

#include "ntf.hpp"
#include "utf.hpp"
#include "extensions.hpp"

namespace html {
    // MARK: - Encode ntf to html
    static std::string encodeHighColor(const uint16_t rgb)
    {
        union __attribute__((packed)) Color {
            uint16_t value;
            struct __attribute__((packed)) {
                uint16_t b : 5;
                uint16_t g : 5;
                uint16_t r : 5;
            };
        } color = {.value = rgb};
        
        std::ostringstream ss;
        ss << "#"
        << std::hex << std::uppercase << std::setfill('0')
        << std::setw(2) << (static_cast<int>(color.r) * 255 / 31)
        << std::setw(2) << (static_cast<int>(color.g) * 255 / 31)
        << std::setw(2) << (static_cast<int>(color.b) * 255 / 31);
        
        return ss.str();
    }
    
    static std::string encodeParagraphAttributes(const ntf::Align align, const ntf::Bullet bullet)
    {
        std::string out;
        
        if (align == ntf::Align::Left) out += "display: flex;justify-content: flex-start;";
        if (align == ntf::Align::Right) out += "display: flex;justify-content: right;";
        if (align == ntf::Align::Center) out += "display: flex;justify-content: center;";
        
        if (bullet == ntf::Bullet::Primary) out += "\" class=\"li1";
        if (bullet == ntf::Bullet::Secondary) out += "\" class=\"li2";
        if (bullet == ntf::Bullet::Tertiary) out += "\" class=\"li3";
        
        return out;
    }
    
    static std::string encodeTextAttributes(const ntf::Style style, const ntf::FontSize fontSize)
    {
        
        std::string out;
        
        switch (fontSize) {
            case ntf::FontSize::Font8pt:
                out += "font-size: 5.4pt;line-height: 10px;";
                break;
                
            case ntf::FontSize::Font10pt:
                out += "font-size: 8.10pt;line-height: 12px;";
                break;
                
            case ntf::FontSize::Font12pt:
                out += "font-size: 12px;line-height: 14px;";
                break;
                
            case ntf::FontSize::Font14pt:
                out += "font-size: 14px;line-height: 16px;";
                break;
                
            case ntf::FontSize::Font16pt:
                out += "font-size: 16px;line-height: 18px;";
                break;
                
            case ntf::FontSize::Font18pt:
                out += "font-size: 18px;line-height: 20px;";
                break;
                
            case ntf::FontSize::Font20pt:
                out += "font-size: 20px;line-height: 22px;";
                break;
                
            case ntf::FontSize::Font22pt:
                out += "font-size: 22px;line-height: 24px;";
                break;
                
            default:
                break;
        }
        
        if (style.bold) out += "font-weight: bold;";
        if (style.italic) out += "font-style: italic;";
        if (style.underline && style.strikethrough)
            out += "text-decoration: underline line-through;";
        else {
            if (style.underline) out += "text-decoration: underline;";
            if (style.strikethrough) out += "text-decoration: line-through;";
        }
        
        return out;
    }
    
    static std::string encodeColorAttributes(const ntf::Format format)
    {
        std::string out;
        
        out += format.foreground <= 0x7FFF ? "color: " + encodeHighColor(format.foreground & 0x7FFF) + ";" : "";
        out += format.background <= 0x7FFF ? "background-color: " + encodeHighColor(format.background & 0x7FFF) + ";" : "";
        
        return out;
    }
    
    static std::string encodePixel(const uint16_t color, const int run = 1)
    {
        std::string out;
        
        out = "<span style=\"font-size: 8.10pt;line-height: 12px;background-color: " + encodeHighColor(color & 0x7FFF) + ";\">";
        for (int i=0; i<run; ++i) {
            out.append("&nbsp;");
        }
        out += "</span>";
        
        return out;
    }
    
    static std::string encodeNTFPict(std::string_view str)
    {
        std::string out;
        int value = -1;
        
        for (size_t i = 5; i < str.size(); ) {
            if (i < str.size() && std::isdigit(str[i])) {
                value = 0;
                while (i < str.size() && std::isdigit(str[i])) {
                    value = value * 10 + (str[i++] - '0');
                }
            }
        }
        auto pict = ntf::pict(value);
        
        if (pict.pixels.empty())
            return out;
        
        auto pixelWidth = static_cast<int>(pict.pixelWidth);
        
        for (int y=0; y<pict.height; y++) {
            // Alignment: Left | Center | Right
            out += "<div";
            if (pict.align == ntf::Align::Right) {
                out += R"( style="text-align: right")";
            }
            if (pict.align == ntf::Align::Center) {
                out += R"( style="text-align: center")";
            }
            out += ">";
            
            // Compression of consecutive pixels sharing the same color.
            for (int x = 0; x < pict.width; ) {
                int index = y * pict.width + x;
                int count = 1;
                int current = pict.pixels[index];
                
                while (x + count < pict.width &&
                       pict.pixels[index + count] == current)
                {
                    ++count;
                }
                
                if (current == pict.keycolor)
                    current = 0xFFFF;
                
                // Encode the pixel with current color
                out += encodePixel(current, count * pixelWidth);
                
                // Move to next different color
                x += count;
            }
            
            out += "</div>";
        }
        
        return out;
    }
    
    static std::string replaceSpaces(const std::string& input)
    {
        std::string out;
        out.reserve(input.size()); // optional optimisation

        for (char c : input) {
            if (c == ' ')
                out += "&nbsp;";
            else
                out += c;
        }
        return out;
    }
    
    static std::string encodeNTFLine(std::string& str)
    {
        std::string out;
        
        auto runs = ntf::parseNTF(str);
        auto style = ntf::currentStyleState();
        auto format = ntf::currentFormatState();
        
        if (!runs.size()) {
            out = R"(<div><span style=")";
            out += encodeTextAttributes({}, format.fontSize);
            out += R"(">&nbsp;</span></div>)";
            return out;
        }
        
        auto paragraphAttributes = encodeParagraphAttributes(runs.back().format.align, runs.back().bullet);
        out = "<div style=\"" + paragraphAttributes + "\">\n";
        
          
        for (const auto& r : runs) {
            out += "<span style=\"";
            out += encodeTextAttributes(r.style, r.format.fontSize);
            out += encodeColorAttributes(r.format);
            out += "\">";
            
            
            out += replaceSpaces(r.text);
            out += "</span>";
        }
        out += "\n</div>\n";
        
        return out;
    }
    
    static std::string encodeNTFDocument(std::istringstream& iss)
    {
        std::string str;
        std::string out;
        
        ntf::reset();
        
        int lines = -1;
        while(getline(iss, str)) {
            if (str.substr(0, 5) == "\\pict") {
                out += encodeNTFPict(str);
                continue;
            } else
                out += encodeNTFLine(str);
            
            lines++;
        }
        
        
        
        return out;
    }
    
    std::string ntf_to_html(const std::string& ntf)
    {
        std::string out;
        std::string input = ntf::extractPicts(ntf);
        
        std::istringstream iss(input);
        
        out = R"(<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <style>
            * {
                box-sizing: border-box;
                margin: 0;
                padding: 0;
                font-family: "Arial", monospace;
            }
            body {
                width: 320px;
                height: 240px;
            }
            header {
                height: 18px;
                line-height: 18px;
                text-align: center;
                color: white;
                font-size: 12px;
                background: linear-gradient(to bottom, #2562a8, #26509e);
                border-bottom: 1px solid black;
            }
            .scroll-box {
                width: 320px;
                height: 200px;
                overflow: auto;
                border-top: 1px solid gray;
                box-sizing: border-box;
                white-space: nowrap;
                padding-left: 1px;
                padding-right: 1px;
                line-height: 0;
            }
            button {
                background: linear-gradient(to bottom, #202020, #4f4f4f);
                border: 1px solid black;
                width: 52px;
                height: 20px;
                font-size: 10pt;
                color: white;
                text-align: center;
                padding: 0px;
                border-radius: 3px;
                margin-right: 1px;
            }
            button.menu {
                border-radius: 0 0 3px 3px;
            }
            button.double {
                width: 105px;
            }
            button.end {
                width: 55px;
                margin: 0;
            }
            .li0::before {
                display: inline-block;
            }
            .li1::before {
                content: '•';
                padding-left: 4px;
                padding-right: 8px;
                line-height: 100%;
            }
            .li2::before {
                content: '◦';
                padding-left: 20px;
                padding-right: 8px;
                line-height: 100%;
            }
            .li3::before {
                content: '▻';
                padding-left: 36px;
                padding-right: 8px;
                line-height: 100%;
            }
        </style>
    </head>
    <body>
        <header>Notes</header>
        <div class="scroll-box">
)";
        
        out += encodeNTFDocument(iss);
        
        out += R"(        </div>
        <button class="menu">Format</button><button class="menu">Style</button><button class="double">&nbsp;</button><button>•</button><button class="menu end">Insert</button>
    </body>
</html>)";
        
        return out;
    }
}
