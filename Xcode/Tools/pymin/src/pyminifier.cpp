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

#include "pyminifier.hpp"

#include <algorithm>
#include <cctype>
#include <sstream>
#include <unordered_map>

// MARK: - Public interface

std::string PythonMinifier::minify(const std::string& source)
{
    reset(source);

    while (!atEnd())
        processCharacter();

    trimTrailingWhitespace();

    while (!output_.empty() && output_.back() == '\n')
        output_.pop_back();

    if (!output_.empty())
        output_ += '\n';
    
    output_ = combineStatements(output_);
    output_ = shortenVariables(output_);
    
    return output_;
}

// MARK: - Initialisation

void PythonMinifier::reset(const std::string& source)
{
    source_ = &source;
    output_.clear();
    indentation_.assign(1, 0);

    position_ = 0;
    bracketDepth_ = 0;
    indentationColumn_ = 0;

    stringState_ = StringState::None;
    lineStart_ = true;
    pendingSpace_ = false;
    escaped_ = false;
}

// MARK: - Source scanning

bool PythonMinifier::atEnd() const
{
    return position_ >= source_->size();
}

char PythonMinifier::currentChar() const
{
    return atEnd() ? '\0' : (*source_)[position_];
}

char PythonMinifier::peekChar(std::size_t offset) const
{
    const auto index = position_ + offset;

    return index < source_->size()
        ? (*source_)[index]
        : '\0';
}

void PythonMinifier::advance()
{
    if (!atEnd())
        ++position_;
}

// MARK: - Character classification

bool PythonMinifier::isIdentifierCharacter(char c)
{
    const auto value = static_cast<unsigned char>(c);

    return std::isalnum(value) || c == '_';
}

bool PythonMinifier::isOperatorCharacter(char c)
{
    return std::string("+-*/%@&|^~<>=:!").find(c)
        != std::string::npos;
}

bool PythonMinifier::isOpeningBracket(char c)
{
    return c == '(' || c == '[' || c == '{';
}

bool PythonMinifier::isClosingBracket(char c)
{
    return c == ')' || c == ']' || c == '}';
}

// MARK: - Character processing

void PythonMinifier::processCharacter()
{
    if (stringState_ != StringState::None)
    {
        processString();
        return;
    }

    if (lineStart_)
    {
        processIndentation();

        if (atEnd())
            return;

        if (lineStart_)
        {
            processNewline();
            return;
        }
    }

    const char c = currentChar();

    if (c == '\r' || c == '\n')
        processNewline();
    else if (c == '#')
        processComment();
    else if (c == ' ' || c == '\t' || c == '\f')
        processWhitespace();
    else if (c == '\\' &&
             (peekChar() == '\n' || peekChar() == '\r'))
        processLineContinuation();
    else if (c == '\'' || c == '"')
        processStringStart();
    else if (isOpeningBracket(c) || isClosingBracket(c))
        processBracket();
    else
    {
        appendCharacter(c);
        advance();
    }
}

// MARK: - Indentation

void PythonMinifier::processIndentation()
{
    int column = 0;

    while (!atEnd() &&
           (currentChar() == ' ' || currentChar() == '\t'))
    {
        if (currentChar() == '\t')
            column += 8 - (column % 8);
        else
            ++column;

        advance();
    }

    indentationColumn_ = column;

    if (atEnd() ||
        currentChar() == '\n' ||
        currentChar() == '\r')
    {
        return;
    }

    if (currentChar() == '#')
    {
        processComment();
        return;
    }

    lineStart_ = false;

    if (bracketDepth_ > 0)
        return;

    updateIndentation(column);

    const int level =
        static_cast<int>(indentation_.size()) - 1;

    output_.append(level, ' ');
}

void PythonMinifier::updateIndentation(int column)
{
    while (indentation_.size() > 1 &&
           column < indentation_.back())
    {
        indentation_.pop_back();
    }

    if (column > indentation_.back())
        indentation_.push_back(column);
}

// MARK: - Comments and whitespace

void PythonMinifier::processComment()
{
    while (!atEnd() &&
           currentChar() != '\n' &&
           currentChar() != '\r')
    {
        advance();
    }
}

void PythonMinifier::processWhitespace()
{
    pendingSpace_ = true;
    advance();
}

void PythonMinifier::processNewline()
{
    if (currentChar() == '\r' && peekChar() == '\n')
        advance();

    advance();

    if (bracketDepth_ > 0)
    {
        pendingSpace_ = true;
        lineStart_ = true;
        indentationColumn_ = 0;
        return;
    }

    appendNewline();
}

void PythonMinifier::processLineContinuation()
{
    advance();

    if (currentChar() == '\r')
    {
        advance();

        if (currentChar() == '\n')
            advance();
    }
    else if (currentChar() == '\n')
    {
        advance();
    }

    pendingSpace_ = true;
    lineStart_ = true;
    indentationColumn_ = 0;
}

// MARK: - Strings

void PythonMinifier::processStringStart()
{
    const char quote = currentChar();

    const bool triple =
        peekChar() == quote &&
        peekChar(2) == quote;

    if (triple)
    {
        output_ += quote;
        output_ += quote;
        output_ += quote;

        advance();
        advance();
        advance();

        stringState_ = quote == '\''
            ? StringState::TripleSingle
            : StringState::TripleDouble;
    }
    else
    {
        appendCharacter(quote);
        advance();

        stringState_ = quote == '\''
            ? StringState::Single
            : StringState::Double;
    }

    escaped_ = false;
}

void PythonMinifier::processString()
{
    const char c = currentChar();

    output_ += c;
    advance();

    if (escaped_)
    {
        escaped_ = false;
        return;
    }

    if (c == '\\')
    {
        escaped_ = true;
        return;
    }

    if (stringState_ == StringState::Single ||
        stringState_ == StringState::Double)
    {
        const char quote =
            stringState_ == StringState::Single ? '\'' : '"';

        if (c == quote)
            stringState_ = StringState::None;

        return;
    }

    const char quote =
        stringState_ == StringState::TripleSingle ? '\'' : '"';

    if (c == quote &&
        currentChar() == quote &&
        peekChar() == quote)
    {
        output_ += currentChar();
        output_ += peekChar();

        advance();
        advance();

        stringState_ = StringState::None;
    }
}

// MARK: - Brackets

void PythonMinifier::processBracket()
{
    const char c = currentChar();

    if (isClosingBracket(c))
        bracketDepth_ = std::max(0, bracketDepth_ - 1);

    appendCharacter(c);
    advance();

    if (isOpeningBracket(c))
        ++bracketDepth_;
}

// MARK: - Output formatting

void PythonMinifier::appendCharacter(char c)
{
    if (pendingSpace_ && !output_.empty() &&
        requiresSeparator(output_.back(), c))
    {
        output_ += ' ';
    }

    pendingSpace_ = false;
    output_ += c;
}

bool PythonMinifier::requiresSeparator(char previous, char next) const
{
    if (isIdentifierCharacter(previous) &&
        isIdentifierCharacter(next))
    {
        return true;
    }

    if (isOperatorCharacter(previous) &&
        isOperatorCharacter(next))
    {
        return true;
    }

    if (std::isdigit(static_cast<unsigned char>(previous)) &&
        (next == '.' || next == '_'))
    {
        return true;
    }

    if (previous == '.' &&
        std::isdigit(static_cast<unsigned char>(next)))
    {
        return true;
    }

    return false;
}

void PythonMinifier::appendNewline()
{
    trimTrailingWhitespace();

    if (!output_.empty() && output_.back() != '\n')
        output_ += '\n';

    pendingSpace_ = false;
    lineStart_ = true;
    indentationColumn_ = 0;
}

void PythonMinifier::trimTrailingWhitespace()
{
    while (!output_.empty() &&
           (output_.back() == ' ' ||
            output_.back() == '\t'))
    {
        output_.pop_back();
    }
}

std::string PythonMinifier::combineStatements(const std::string& source)
{
    std::istringstream input(source);
    std::string line;
    std::string output;
    std::string pending;
    std::string pendingIndent;

    auto hasTopLevelColon = [](const std::string& text) {
        int depth = 0;
        char quote = '\0';
        bool triple = false;
        bool escaped = false;

        for (std::size_t i = 0; i < text.size(); ++i)
        {
            const char c = text[i];

            if (quote)
            {
                if (escaped)
                    escaped = false;
                else if (c == '\\')
                    escaped = true;
                else if (c == quote)
                {
                    if (triple && i + 2 < text.size() &&
                        text[i + 1] == quote &&
                        text[i + 2] == quote)
                    {
                        i += 2;
                        quote = '\0';
                        triple = false;
                    }
                    else if (!triple)
                    {
                        quote = '\0';
                    }
                }

                continue;
            }

            if (c == '\'' || c == '"')
            {
                quote = c;
                triple = i + 2 < text.size() &&
                    text[i + 1] == c && text[i + 2] == c;

                if (triple)
                    i += 2;
            }
            else if (c == '#')
            {
                break;
            }
            else if (c == '(' || c == '[' || c == '{')
            {
                ++depth;
            }
            else if (c == ')' || c == ']' || c == '}')
            {
                --depth;
            }
            else if (c == ':' && depth == 0)
            {
                return true;
            }
        }

        return false;
    };

    auto flush = [&]() {
        if (!pending.empty())
        {
            output += pending;
            output += '\n';
            pending.clear();
            pendingIndent.clear();
        }
    };

    while (std::getline(input, line))
    {
        const auto start = line.find_first_not_of(" \t");

        if (start == std::string::npos)
        {
            flush();
            output += '\n';
            continue;
        }

        const std::string indent = line.substr(0, start);
        const std::string statement = line.substr(start);

        const bool special =
            statement[0] == '@' ||
            hasTopLevelColon(statement);

        if (special)
        {
            flush();
            output += line + '\n';
            continue;
        }

        if (pending.empty())
        {
            pending = line;
            pendingIndent = indent;
        }
        else if (indent == pendingIndent)
        {
            pending += ';' + statement;
        }
        else
        {
            flush();
            pending = line;
            pendingIndent = indent;
        }
    }

    flush();

    if (!output.empty() && output.back() == '\n')
        output.pop_back();

    if (!output.empty())
        output += '\n';

    return output;
}

std::string PythonMinifier::shortenVariables(const std::string& source)
{
    std::istringstream input(source);
    std::string line;
    std::string output;
    std::unordered_map<std::string, std::string> replacements;
    int nextName = 1;
    int functionIndent = -1;
    bool inFunction = false;

    auto nextVariable = [&]() {
        return "v" + std::to_string(nextName++);
    };

    auto assignName = [&](const std::string& name) {
        if (replacements.count(name))
            return;

        const std::string replacement = nextVariable();

        if (replacement.size() < name.size())
            replacements[name] = replacement;
    };

    auto replaceIdentifiers = [&](const std::string& text) {
        std::string rewritten;
        char quote = '\0';
        bool escaped = false;

        for (std::size_t i = 0; i < text.size();)
        {
            const char c = text[i];

            if (quote)
            {
                rewritten += c;
                ++i;

                if (escaped)
                    escaped = false;
                else if (c == '\\')
                    escaped = true;
                else if (c == quote)
                    quote = '\0';

                continue;
            }

            if (c == '\'' || c == '"')
            {
                quote = c;
                rewritten += c;
                ++i;
                continue;
            }

            if (std::isalpha(static_cast<unsigned char>(c)) || c == '_')
            {
                const auto begin = i++;

                while (i < text.size() &&
                       (std::isalnum(static_cast<unsigned char>(text[i])) ||
                        text[i] == '_'))
                {
                    ++i;
                }

                const std::string name = text.substr(begin, i - begin);
                const auto found = replacements.find(name);
                const bool attribute = begin > 0 && text[begin - 1] == '.';

                rewritten += !attribute && found != replacements.end()
                    ? found->second
                    : name;
            }
            else
            {
                rewritten += c;
                ++i;
            }
        }

        return rewritten;
    };

    while (std::getline(input, line))
    {
        const auto start = line.find_first_not_of(' ');

        if (start == std::string::npos)
        {
            output += '\n';
            continue;
        }

        const int indent = static_cast<int>(start);
        const std::string text = line.substr(start);

        if (text.compare(0, 4, "def ") == 0)
        {
            replacements.clear();
            nextName = 1;
            functionIndent = indent;
            inFunction = true;

            // Collect parameters before rewriting the function signature.
            const auto open = text.find('(');
            const auto close = text.rfind(')');

            if (open != std::string::npos &&
                close != std::string::npos && close > open)
            {
                std::size_t i = open + 1;

                while (i < close)
                {
                    while (i < close &&
                           !(std::isalpha(static_cast<unsigned char>(text[i])) ||
                             text[i] == '_'))
                    {
                        ++i;
                    }

                    if (i >= close)
                        break;

                    const auto begin = i++;

                    while (i < close &&
                           (std::isalnum(static_cast<unsigned char>(text[i])) ||
                            text[i] == '_'))
                    {
                        ++i;
                    }

                    const std::string name = text.substr(begin, i - begin);
                    assignName(name);
                }
            }
        }
        else if (inFunction && indent <= functionIndent)
        {
            replacements.clear();
            nextName = 1;
            functionIndent = -1;
            inFunction = false;
        }

        if (inFunction)
        {
            // Collect simple assignment targets.
            for (std::size_t i = 0; i < text.size();)
            {
                if (std::isalpha(static_cast<unsigned char>(text[i])) ||
                    text[i] == '_')
                {
                    const auto begin = i++;

                    while (i < text.size() &&
                           (std::isalnum(static_cast<unsigned char>(text[i])) ||
                            text[i] == '_'))
                    {
                        ++i;
                    }

                    const std::string name = text.substr(begin, i - begin);

                    std::size_t j = i;
                    while (j < text.size() && text[j] == ' ')
                        ++j;

                    if (j < text.size() && text[j] == '=' &&
                        (j + 1 >= text.size() || text[j + 1] != '=') &&
                        name != "global" && name != "nonlocal")
                    {
                        assignName(name);
                    }
                }
                else
                {
                    ++i;
                }
            }

            output += line.substr(0, start) + replaceIdentifiers(text);
        }
        else
        {
            output += line;
        }

        output += '\n';
    }

    return output;
}
