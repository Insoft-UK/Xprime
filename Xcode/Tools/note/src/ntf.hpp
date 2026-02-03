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

#pragma once

#include <iostream>
#include <string>
#include <vector>
#include <list>
#include <cctype>

namespace ntf {
    enum FontSize : uint16_t {
        FONT8  = 0,
        FONT10 = 1,
        FONT12 = 2, SMALL  = 2,
        FONT14 = 3, MEDIUM = 3,
        FONT16 = 4, LARGE  = 4,
        FONT18 = 5,
        FONT20 = 6,
        FONT22 = 7
    };
    
    enum Align {
        LEFT = 0, CENTER = 1, RIGHT = 2
    };
    
    enum Para {
        NONE = 0, BOTTOM = 1, TOP = 2
    };
    
    typedef uint16_t Color;
    
    struct Format {
        FontSize fontSize = MEDIUM;
        Color foreground = 0xFFFF;
        Color background = 0xFFFF;
        Align align = LEFT;
    };
    
    struct Style {
        bool bold = false;
        bool italic = false;
        bool underline = false;
        bool strikethrough = false;
        Para para = NONE;
    };
    
    enum Endian {
        Big = 0, Little = 1
    };
    
    struct Pict {
        int width  = 0;
        int height = 0;
        Endian endian = Little;
        int aspect = 1;               // 1:1 (default), 2 = 1:2, 3 = 1:3
        uint16_t keycolor = 0x7C1F;   // RGB555 (FFFF)
        std::vector<uint16_t> pixels;
    };
    
    struct TextRun {
        std::string text;
        Format format;
        Style style;
        int level = 0;
    };
    
    /**
     * @brief Resets the parser formatting state to defaults.
     *
     * Clears all active style flags and formatting attributes used during
     * parsing (such as bold, italic, underline, strikethrough, and colors),
     * returning the parser to its initial state. This does not modify any
     * previously parsed output, only the internal state used for subsequent
     * parsing.
     */
    void reset(void);
    
    /**
     * @brief Extracts and removes all pict entries from the input text.
     *
     * Scans the input string for `{\pict ...}` groups, parses each pict entry,
     * and removes the entire pict group from the returned string. The extracted
     * pict data is decoded and stored internally for later use, while the
     * resulting string contains only the non-pict content.
     *
     * This function preserves all other text and formatting unchanged and does
     * not alter the relative order of non-pict content. It operates only on the
     * pict entries encountered and does not perform any rendering.
     *
     * @param ntf The input text containing zero or more pict entries.
     * @return A copy of the input text with all pict groups removed.
     */
    std::string extractPicts(const std::string& ntf);
    
    /**
     * @brief Retrieves a parsed pict entry by index.
     *
     * Returns the `Pict` structure corresponding to the specified index `N`
     * from the internal pict table populated during parsing. Each `Pict`
     * contains the width, height, and pixel data (in RGB555 format) of a
     * previously extracted pict entry.
     *
     * @param N The zero-based index of the pict entry to retrieve.
     * @return The `Pict` object at the specified index.
     *
     * @note The index must be within the range of previously parsed picts.
     *       Accessing an out-of-range index results in undefined behavior.
     */
    Pict pict(const int N);
    
    /**
     * @brief Parses a NoteText Format (NTF) string into styled text runs.
     *
     * This function scans the input string for embedded NTF control sequences
     * (such as bold, italic, underline, strikethrough, and color commands) and
     * converts the stream into a sequence of TextRun objects. Each TextRun
     * represents a contiguous range of text sharing the same formatting state.
     *
     * Control sequences affect subsequent text until they are modified or
     * reset by another control sequence. The control codes themselves are not
     * included in the output text.
     *
     * @param input The raw NTF-formatted string to parse.
     * @return A vector of TextRun objects representing the parsed text and
     *         associated formatting.
     */
    std::vector<TextRun> parseNTF(const std::string& input);
    
    /**
     * @brief Converts a RichText string into NoteText Format (NTF).
     *
     * Translates supported RichText format into equivalent NTF control
     * sequences, emitting an NTF-formatted string suitable for processing
     * by the NTF parser. Formatting that is not representable in NTF may be
     * ignored or approximated.
     *
     * The returned string contains NTF control codes embedded directly
     * within the text stream.
     *
     * @param rtf The RichText-formatted input string.
     * @return A string encoded in NoteText Format (NTF).
     */
    std::string richTextToNTF(const std::string& rtf);
    
    /**
     * @brief Converts a Markdown string into NoteText Format (NTF).
     *
     * Translates supported Markdown syntax into equivalent NTF control
     * sequences, emitting an NTF-formatted string suitable for processing
     * by the NTF parser. Formatting that is not representable in NTF may be
     * ignored or approximated.
     *
     * The returned string contains NTF control codes embedded directly
     * within the text stream.
     *
     * @param md The Markdown-formatted input string.
     * @return A string encoded in NoteText Format (NTF).
     */
    std::string markdownToNTF(const std::string& md);
    
    /**
     * @brief Gets the current formatting state.
     *
     * @return Current formatting settings as a `Format` structure.
     */
    Format currentFormatState(void);
    
    /**
     * @brief Gets the current style state.
     *
     * @return Current style settings as a `Style` structure.
     */
    Style currentStyleState(void);
    
    /**
     * @brief Gets the current level state.
     *
     * @return Current level setting.
     */
    int currentLevelState(void);
    
    /**
     * @brief Clears any custom color entries and restores the default color table.
     */
    void defaultColorTable(void);
    
    /**
     * @brief Prints a sequence of styled text runs to the console.
     *
     * Iterates through the provided vector of TextRun objects and outputs
     * their text along with formatting information (such as bold, italic,
     * underline, strikethrough, and colors). Primarily intended for
     * debugging or inspecting parsed NoteText Format (NTF) content.
     *
     * @param runs A vector of TextRun objects representing parsed text and
     *             their associated formatting.
     */
    void printRuns(const std::vector<TextRun>& runs);
}
