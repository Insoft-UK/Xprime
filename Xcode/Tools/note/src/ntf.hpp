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
    enum class FontSize : uint16_t {
        Font8  = 0,
        Font10 = 1,
        Font12 = 2, Small  = 2,
        Font14 = 3, Medium = 3,
        Font16 = 4, Large  = 4,
        Font18 = 5,
        Font20 = 6,
        Font22 = 7
    };
    
    enum class Align {
        Left = 0, Center = 1, Right = 2
    };
    
    enum class Para {
        None = 0, Bottom = 1, Top = 2
    };
    
    typedef uint16_t Color;
    
    struct Format {
        FontSize fontSize = FontSize::Medium;
        Color foreground = 0xFFFF;
        Color background = 0xFFFF;
        Align align = Align::Left;
    };
    
    struct Style {
        bool bold = false;
        bool italic = false;
        bool underline = false;
        bool strikethrough = false;
        Para para = Para::None;
    };
    
    enum class Endian {
        Big = 0, Little = 1
    };
    
    enum Aspect {
        SQUARE = 1, THIN = 2, NARROW = 3
    };
    
    struct Pict {
        int width  = 0;
        int height = 0;
        Endian endian = Endian::Little;
        Align align = Align::Left;
        int aspect = 1;
        uint16_t keycolor = 0x7C1F;
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
     * @brief Extracts embedded picture groups from an NTF string.
     *
     * Scans the input NoteText Format (NTF) stream for `{\pict ...}` groups,
     * parses each picture definition, and—if valid and within size limits—
     * stores it in the internal picture table. Each accepted picture group
     * is removed from the text stream and replaced with a `\pictN` marker
     * referencing its index in the picture table.
     *
     * Malformed picture groups are skipped safely, and all non-picture
     * content is passed through unchanged.
     *
     * @param ntf The raw NTF-formatted string to process.
     * @return A rewritten NTF string with picture groups stripped and
     *         replaced by `\pictN` references.
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
     * @param ntf The raw NTF-formatted string to parse.
     * @return A vector of TextRun objects representing the parsed text and
     *         associated formatting.
     */
    std::vector<TextRun> parseNTF(const std::string& ntf);
    
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
