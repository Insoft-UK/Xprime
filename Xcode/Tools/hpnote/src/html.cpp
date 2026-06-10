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
    }
    body {
        background: #000;
        font-family: "Arial", monospace;
        display: flex;
        justify-content: center;
    }
    .notes {
        width: 320px;
        height: 240px;
        background: white;
    }
    .titlebar {
        height: 20px;
        line-height: 20px;
        text-align: center;
        color: white;
        font-size: 12px;
        background: #2550a0 50%;
        border-bottom: 1px solid #000;
    }
    .document {
        width: 320px;
        height: 200px;
        white-space: nowrap;
        overflow: auto;
        box-sizing: border-box;
        white-space: nowrap;
        padding-left: 1px;
        padding-right: 1px;
        line-height: 0;
    }
    .menubar {
        display: flex;
        gap: 1px;
        padding: 0px;
    }
    .button {
        min-width: 53px;
        height: 20px;

        background: #383838 50%;

        color: white;
        font-size: 10px;

        display: flex;
        align-items: center;
        justify-content: center;
    }
    .button.double {
        width: 105px;
    }
    .button.menu {
        clip-path: polygon(
            4px 0,
            100% 0,
            100% 100%,
            0 100%,
            0 4px
        );
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
    <div class="notes">
        <div class="titlebar">
            Notes
        </div>
        <div class="document">
            $(HTML)
        </div>
        <div class="menubar">
            <div class="button menu">Format</div>
            <div class="button menu">Style</div>

            <div class="button double"></div>

            <div class="button">•</div>
            <div class="button menu">Insert</div>
        </div>
    </div>
</body>
</html>)";
        
        auto pos = out.find("$(HTML)");
        auto html = encodeNTFDocument(iss);
        
        return out.replace(pos, 7, html);
    }
}
