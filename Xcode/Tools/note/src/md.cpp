// The MIT License (MIT)
//
// Copyright (c) 2026 Insoft.
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

#include "md.hpp"

using namespace md;

struct Frame {
    Style style;
    Attributes attr;
    std::string buffer;
};

// Parse {foreground=red background=yellow size=12} style spans
static Attributes parseAttributes(const std::string& s) {
    Attributes a;
    size_t i = 0;
    while (i < s.size()) {
        while (i < s.size() && s[i] == ' ') i++;
        size_t k = i;
        while (i < s.size() && s[i] != '=' && s[i] != ' ') i++;
        if (i >= s.size() || s[i] != '=') break;

        std::string key = s.substr(k, i - k);
        ++i; // skip '='

        size_t v = i;
        while (i < s.size() && s[i] != ' ') i++;
        std::string value = s.substr(v, i - v);

        if (key == "foreground") a.foreground = value;
        else if (key == "background") a.background = value;
//        else if (key == "align") {
//            if (value == "left") a.align = Alignment::Left;
//            else if (value == "center") a.align = Alignment::Center;
//            else if (value == "right") a.align = Alignment::Right;
//        }
    }
    return a;
}

static Attributes merge(const Attributes& parent, const Attributes& child) {
    Attributes r = parent;
    if (!child.foreground.empty()) r.foreground = child.foreground;
    if (!child.background.empty()) r.background = child.background;
    return r;
}

std::vector<Token> md::parseMarkdown(const std::string& input) {
    std::vector<Token> output;
    std::vector<Frame> stack;
    stack.push_back({Style{}, Attributes{}, ""});

    BulletType currentBullet = BulletType::None;
    int bulletLevel = 0;
    bool bulletAssigned = false;

    auto flushFrame = [&](Frame& f, bool assignBullet) {
        if (!f.buffer.empty()) {
            output.push_back({f.style, f.attr, assignBullet ? currentBullet : BulletType::None,
                              assignBullet ? bulletLevel : 0, f.buffer});
            
            f.buffer.clear();
            if (assignBullet) bulletAssigned = true;
        }
    };

    size_t i = 0;
    while (i < input.size()) {
        // Start of line: detect leading spaces for sub-bullets
        if (i == 0 || input[i-1] == '\n') {
            size_t lineStart = i;
            size_t indent = 0;
            while (i < input.size() && input[i] == ' ') {
                ++indent;
                ++i;
            }
            
            // Heading detection (#, ##, ###, ####)
            size_t hashCount = 0;
            size_t j = i;
            while (j < input.size() && input[j] == '#') {
                ++hashCount;
                ++j;
            }

            if (hashCount >= 1 && hashCount <= 4 &&
                j < input.size() && input[j] == ' ') {

                // Flush any previous text
                flushFrame(stack.back(), false);

                Attributes a = stack.back().attr;
                Style s = { .Bold = 1 };
                switch (hashCount) {
                    case 1:
                        a.fontSize = 22;
                        break;
                    case 2:
                        a.fontSize = 20;
                        break;
                    case 3:
                        a.fontSize = 18;
                        break;
                    case 4:
                        a.fontSize = 16;
                        break;
                        
                    default:
                        break;
                }

                stack.push_back({s, a, ""});
                i = j + 1; // skip "# " / "## " / "### " / "#### "
                continue;
            }
            
            // Check for bullet
            if (i + 1 < input.size() && input[i] == '-' && input[i+1] == ' ') {
                currentBullet = BulletType::Dash;
                bulletLevel = static_cast<int>(indent / 2) + 1; // 2 spaces per level
                bulletAssigned = false;
                i += 2;
                continue;
            } else {
                currentBullet = BulletType::None;
                bulletLevel = 0;
                bulletAssigned = false;
                i = lineStart; // reset to start of line
            }
        }

        // Escaping
        if (input[i] == '\\' && i + 1 < input.size()) {
            stack.back().buffer += input[i + 1];
            i += 2;
            continue;
        }

        // Attribute span
        if (input[i] == '{') {
            size_t end = input.find('}', i + 1);
            if (end != std::string::npos) {
                std::string tag = input.substr(i + 1, end - i - 1);

                // Closing span
                if (!tag.empty() && tag[0] == '/') {
                    Frame finished = stack.back();
                    stack.pop_back();
                    flushFrame(finished, !bulletAssigned);
                    if (!stack.empty())
                        stack.back().buffer += finished.buffer;
                    i = end + 1;
                    continue;
                }

                // Opening span
                Attributes a = parseAttributes(tag);
                stack.push_back({stack.back().style, merge(stack.back().attr, a), ""});
                i = end + 1;
                continue;
            }
        }

        size_t count;
        
        // Star emphasis
        count = 0;
        while (i + count < input.size() && input[i + count] == '*') ++count;
        if (count >= 1 && count <= 3) {
            Style style{};
            switch (count) {
                case 1:
                    style.Italic = 1;
                    break;
                    
                case 2:
                    style.Bold = 1;
                    break;
                    
                case 3:
                    style.Bold = 1;
                    style.Italic = 1;
                    break;
                    
                default:
                    break;
            }

            if (stack.back().style.flags == style.flags) {
                Frame finished = stack.back();
                stack.pop_back();
                flushFrame(finished, !bulletAssigned);
                if (!stack.empty())
                    stack.back().buffer += finished.buffer;
            } else {
                stack.push_back({style, stack.back().attr, ""});
            }
            i += count;
            continue;
        }
        
        count = 0;
        while (i + count < input.size() && input[i + count] == '~') ++count;
        if (count == 2) {
            Style style = { .Strikethrough = 1 };

            if (stack.back().style.Bold == 1) {
                Frame finished = stack.back();
                stack.pop_back();
                flushFrame(finished, !bulletAssigned);
                if (!stack.empty())
                    stack.back().buffer += finished.buffer;
            } else {
                stack.push_back({style, stack.back().attr, ""});
            }
            i += count;
            continue;
        }
        
        count = 0;
        
        while (i + count < input.size() && input[i + count] == '=') ++count;
        if (count == 2) {
            Attributes attr = { .background = "#FFA500" };
            if (stack.back().attr.background == "#FFA500") {
                Frame finished = stack.back();
                stack.pop_back();
                flushFrame(finished, !bulletAssigned);
                if (!stack.empty())
                    stack.back().buffer += finished.buffer;
            } else {
                stack.push_back({stack.back().style, attr, ""});
            }
            i += count;
            continue;
        }

        // Normal character
        char c = input[i++];
        if (c == '\n') {
            flushFrame(stack.back(), !bulletAssigned);
            bulletAssigned = false;
        } else {
            stack.back().buffer += c;
        }
    }

    // Flush remaining frames
    while (!stack.empty()) {
        flushFrame(stack.back(), !bulletAssigned);
        stack.pop_back();
    }

    return output;
}

// Optional: helper to print tokens for testing
void md::printTokens(const std::vector<Token>& tokens) {
    for (const auto& t : tokens) {
        std::cerr << "Level " << t.bulletLevel << " | "
                  << ((t.style.Bold) ? "B" : "-")
        << ((t.style.Italic) ? "I" : "-")
        << ((t.style.Underline) ? "U" : "-")
        << ((t.style.Strikethrough) ? "S" : "-") << " | "
        << "Font Size: " << std::to_string(t.attr.fontSize) << " | "
//        (
//                      (t.style == Style::Heading1) ? "Heading1" :
//                      (t.style == Style::Heading2) ? "Heading2" :
//                      (t.style == Style::Heading3) ? "Heading3" :
//                      (t.style == Style::Heading4) ? "Heading4" :
//                      (t.style == Style::Italic) ? "Highlight" :
//                      (t.style == Style::Italic) ? "Strikethrough" :
//                      (t.style == Style::Normal) ? "Normal" :
//                      (t.style.Italic) ? "Italic" :
//                      (t.style.Bold) ? "Bold" : "BoldItalic"
//                      )
                  << " | " << t.attr.foreground << " " << t.attr.background
                  << " | " << ((t.align == Alignment::Left) ? "Left" : (t.align == Alignment::Right) ? "Right" : "Center")
                  << " | [" << t.text << "]\n";
    }
}
