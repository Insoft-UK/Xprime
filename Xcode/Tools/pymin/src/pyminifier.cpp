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

//std::string PythonMinifier::shortenVariables(const std::string& source)
//{
//    std::istringstream input(source);
//    std::string line;
//    std::string output;
//    std::unordered_map<std::string, std::string> replacements;
//
//    int nextName = 1;
//    int functionIndent = -1;
//    bool inFunction = false;
//
//    auto nextVariable = [&]() {
//        return "v" + std::to_string(nextName++);
//    };
//
//    auto assignName = [&](const std::string& name) {
//        if (replacements.count(name))
//            return;
//
//        const std::string alias = nextVariable();
//
//        if (alias.size() < name.size())
//            replacements[name] = alias;
//    };
//
//    auto replaceIdentifiers = [&](const std::string& text) {
//        std::string rewritten;
//        char quote = '\0';
//        bool escaped = false;
//
//        for (std::size_t i = 0; i < text.size();)
//        {
//            const char c = text[i];
//
//            if (quote)
//            {
//                rewritten += c;
//                ++i;
//
//                if (escaped)
//                    escaped = false;
//                else if (c == '\\')
//                    escaped = true;
//                else if (c == quote)
//                    quote = '\0';
//
//                continue;
//            }
//
//            if (c == '\'' || c == '"')
//            {
//                quote = c;
//                rewritten += c;
//                ++i;
//                continue;
//            }
//
//            if (c == '#')
//            {
//                rewritten.append(text.substr(i));
//                break;
//            }
//
//            if (std::isalpha(static_cast<unsigned char>(c)) || c == '_')
//            {
//                const std::size_t begin = i++;
//
//                while (i < text.size() &&
//                       (std::isalnum(static_cast<unsigned char>(text[i])) ||
//                        text[i] == '_'))
//                {
//                    ++i;
//                }
//
//                const std::string name = text.substr(begin, i - begin);
//                const auto found = replacements.find(name);
//                const bool attribute =
//                    begin > 0 && text[begin - 1] == '.';
//
//                rewritten += !attribute && found != replacements.end()
//                    ? found->second
//                    : name;
//            }
//            else
//            {
//                rewritten += c;
//                ++i;
//            }
//        }
//
//        return rewritten;
//    };
//
//    while (std::getline(input, line))
//    {
//        const auto start = line.find_first_not_of(' ');
//
//        if (start == std::string::npos)
//        {
//            output += '\n';
//            continue;
//        }
//
//        const int indent = static_cast<int>(start);
//        const std::string text = line.substr(start);
//
//        if (text.compare(0, 4, "def ") == 0)
//        {
//            replacements.clear();
//            nextName = 1;
//            functionIndent = indent;
//            inFunction = true;
//
//            const std::size_t open = text.find('(');
//            const std::size_t close = text.rfind(')');
//
//            if (open == std::string::npos ||
//                close == std::string::npos ||
//                close <= open)
//            {
//                output += line + '\n';
//                continue;
//            }
//
//            using Alias = std::pair<std::size_t,
//                                    std::pair<std::size_t, std::string>>;
//
//            std::vector<Alias> aliases;
//
//            std::size_t segmentStart = open + 1;
//            int depth = 0;
//            int nextParameter = 1;
//            char quote = '\0';
//            bool escaped = false;
//
//            auto processParameter = [&](std::size_t begin,
//                                        std::size_t end)
//            {
//                std::size_t pos = begin;
//
//                while (pos < end &&
//                       std::isspace(static_cast<unsigned char>(text[pos])))
//                    ++pos;
//
//                // Preserve *args and **kwargs prefixes.
//                while (pos < end && text[pos] == '*')
//                    ++pos;
//
//                if (pos >= end ||
//                    !(std::isalpha(static_cast<unsigned char>(text[pos])) ||
//                      text[pos] == '_'))
//                    return;
//
//                const std::size_t nameStart = pos++;
//
//                while (pos < end &&
//                       (std::isalnum(static_cast<unsigned char>(text[pos])) ||
//                        text[pos] == '_'))
//                    ++pos;
//
//                const std::string name =
//                    text.substr(nameStart, pos - nameStart);
//
//                std::size_t check = pos;
//
//                while (check < end &&
//                       std::isspace(static_cast<unsigned char>(text[check])))
//                    ++check;
//
//                if (check < end && text[check] != '=')
//                    return;
//
//                const std::string alias =
//                    "p" + std::to_string(nextParameter++);
//
//                if (alias.size() < name.size())
//                {
//                    replacements[name] = alias;
//                    aliases.push_back({
//                        nameStart,
//                        {name.size(), alias}
//                    });
//                }
//            };
//
//            for (std::size_t i = open + 1; i <= close; ++i)
//            {
//                const char c = i < close ? text[i] : ',';
//
//                if (quote)
//                {
//                    if (escaped)
//                        escaped = false;
//                    else if (c == '\\')
//                        escaped = true;
//                    else if (c == quote)
//                        quote = '\0';
//
//                    continue;
//                }
//
//                if (c == '\'' || c == '"')
//                {
//                    quote = c;
//                    continue;
//                }
//
//                if (c == '(' || c == '[' || c == '{')
//                    ++depth;
//                else if (c == ')' || c == ']' || c == '}')
//                    --depth;
//                else if (c == ',' && depth == 0)
//                {
//                    processParameter(segmentStart, i);
//                    segmentStart = i + 1;
//                }
//            }
//
//            // Apply replacements right to left to preserve original offsets.
//            std::string signature = text;
//
//            for (auto it = aliases.rbegin(); it != aliases.rend(); ++it)
//            {
//                signature.replace(
//                    it->first,
//                    it->second.first,
//                    it->second.second);
//            }
//
//            output += line.substr(0, start) + signature + '\n';
//            continue;
//        }
//
//        if (inFunction && indent <= functionIndent)
//        {
//            replacements.clear();
//            nextName = 1;
//            functionIndent = -1;
//            inFunction = false;
//        }
//
//        if (!inFunction)
//        {
//            output += line + '\n';
//            continue;
//        }
//
//        // Collect local assignment targets without scanning strings/comments.
//        char quote = '\0';
//        bool escaped = false;
//
//        for (std::size_t i = 0; i < text.size();)
//        {
//            const char c = text[i];
//
//            if (quote)
//            {
//                if (escaped)
//                    escaped = false;
//                else if (c == '\\')
//                    escaped = true;
//                else if (c == quote)
//                    quote = '\0';
//
//                ++i;
//                continue;
//            }
//
//            if (c == '\'' || c == '"')
//            {
//                quote = c;
//                ++i;
//                continue;
//            }
//
//            if (c == '#')
//                break;
//
//            if (std::isalpha(static_cast<unsigned char>(c)) || c == '_')
//            {
//                const std::size_t begin = i++;
//
//                while (i < text.size() &&
//                       (std::isalnum(static_cast<unsigned char>(text[i])) ||
//                        text[i] == '_'))
//                    ++i;
//
//                const std::string name = text.substr(begin, i - begin);
//
//                std::size_t j = i;
//
//                while (j < text.size() &&
//                       std::isspace(static_cast<unsigned char>(text[j])))
//                    ++j;
//
//                if (j < text.size() &&
//                    text[j] == '=' &&
//                    (j + 1 >= text.size() || text[j + 1] != '=') &&
//                    (j == 0 || text[j - 1] != '=') &&
//                    name != "global" &&
//                    name != "nonlocal")
//                {
//                    assignName(name);
//                }
//            }
//            else
//            {
//                ++i;
//            }
//        }
//
//        output += line.substr(0, start) + replaceIdentifiers(text) + '\n';
//    }
//
//    return output;
//}


// MARK: - Variable shortening

std::string PythonMinifier::nextVariableAlias()
{
   return "v" + std::to_string(nextVariableNumber_++);
}

std::string PythonMinifier::nextParameterAlias()
{
   return "p" + std::to_string(nextParameterNumber_++);
}

void PythonMinifier::assignVariableAlias(const std::string& name)
{
   // Do not replace an existing parameter or previously assigned local.
   if (replacements_.find(name) != replacements_.end())
       return;

   const std::string alias = nextVariableAlias();

   // Only use the alias when it actually shortens the identifier.
   if (alias.size() < name.size())
       replacements_[name] = alias;
}

std::string PythonMinifier::shortenParameters(
   const std::string& signature)
{
   // Parameter aliases are assigned independently of local variables.
   replacements_.clear();
   nextVariableNumber_ = 1;
   nextParameterNumber_ = 1;

   const std::size_t open = signature.find('(');

   if (open == std::string::npos)
       return signature;

   // Locate the matching closing parenthesis, ignoring strings and
   // brackets nested inside default expressions or annotations.
   std::size_t close = std::string::npos;
   int depth = 0;
   char quote = '\0';
   bool triple = false;
   bool escaped = false;

   for (std::size_t i = open; i < signature.size(); ++i)
   {
       const char c = signature[i];

       if (quote != '\0')
       {
           if (escaped)
           {
               escaped = false;
               continue;
           }

           if (c == '\\')
           {
               escaped = true;
               continue;
           }

           if (c == quote)
           {
               if (triple &&
                   i + 2 < signature.size() &&
                   signature[i + 1] == quote &&
                   signature[i + 2] == quote)
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
           triple = i + 2 < signature.size() &&
                    signature[i + 1] == c &&
                    signature[i + 2] == c;

           if (triple)
               i += 2;

           continue;
       }

       if (c == '#')
           break;

       if (c == '(')
       {
           ++depth;
       }
       else if (c == ')')
       {
           --depth;

           if (depth == 0)
           {
               close = i;
               break;
           }
       }
   }

   if (close == std::string::npos)
       return signature;

   struct ParameterAlias
   {
       std::size_t position;
       std::size_t length;
       std::string alias;
   };

   std::vector<ParameterAlias> aliases;

   auto processParameter = [&](std::size_t begin, std::size_t end)
   {
       while (begin < end &&
              std::isspace(
                  static_cast<unsigned char>(signature[begin])))
       {
           ++begin;
       }

       // Ignore positional/keyword separators.
       if (begin >= end ||
           signature[begin] == '/' ||
           signature[begin] == '*')
       {
           return;
       }

       // Locate the parameter identifier. The * and ** prefixes are
       // preserved, as are annotations and default expressions.
       std::size_t nameStart = begin;

       while (nameStart < end && signature[nameStart] == '*')
           ++nameStart;

       if (nameStart >= end)
           return;

       const unsigned char first =
           static_cast<unsigned char>(signature[nameStart]);

       if (!std::isalpha(first) && signature[nameStart] != '_')
           return;

       std::size_t nameEnd = nameStart + 1;

       while (nameEnd < end)
       {
           const unsigned char c =
               static_cast<unsigned char>(signature[nameEnd]);

           if (!std::isalnum(c) && signature[nameEnd] != '_')
               break;

           ++nameEnd;
       }

       const std::string name =
           signature.substr(nameStart, nameEnd - nameStart);

       // Do not alias Python keywords or parameter separators.
       static const std::vector<std::string> keywords = {
           "False", "None", "True"
       };

       if (std::find(keywords.begin(), keywords.end(), name)
           != keywords.end())
       {
           return;
       }

       const std::string alias = nextParameterAlias();

       if (alias.size() >= name.size())
           return;

       // Do not overwrite an existing mapping.
       if (replacements_.find(name) != replacements_.end())
           return;

       replacements_[name] = alias;

       aliases.push_back({
           nameStart,
           nameEnd - nameStart,
           alias
       });
   };

   // Split parameters only at commas outside nested brackets and strings.
   std::size_t segmentStart = open + 1;
   depth = 0;
   quote = '\0';
   triple = false;
   escaped = false;

   for (std::size_t i = open + 1; i <= close; ++i)
   {
       const char c = i < close ? signature[i] : ',';

       if (quote != '\0')
       {
           if (escaped)
           {
               escaped = false;
               continue;
           }

           if (c == '\\')
           {
               escaped = true;
               continue;
           }

           if (c == quote)
           {
               if (triple &&
                   i + 2 < close &&
                   signature[i + 1] == quote &&
                   signature[i + 2] == quote)
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
           triple = i + 2 < close &&
                    signature[i + 1] == c &&
                    signature[i + 2] == c;

           if (triple)
               i += 2;

           continue;
       }

       if (c == '(' || c == '[' || c == '{')
       {
           ++depth;
       }
       else if (c == ')' || c == ']' || c == '}')
       {
           --depth;
       }
       else if (c == ',' && depth == 0)
       {
           processParameter(segmentStart, i);
           segmentStart = i + 1;
       }
   }

   // Replace parameter names from right to left so offsets remain valid.
   std::string result = signature;

   for (auto it = aliases.rbegin(); it != aliases.rend(); ++it)
   {
       result.replace(
           it->position,
           it->length,
           it->alias);
   }

   return result;
}

void PythonMinifier::collectLocalVariables(
   const std::string& statement)
{
   // Look for simple assignment targets. Strings and comments are skipped.
   // Statements combined with semicolons are processed independently.
   std::size_t segmentStart = 0;

   char quote = '\0';
   bool triple = false;
   bool escaped = false;
   int depth = 0;

   auto processSegment = [&](std::size_t begin, std::size_t end)
   {
       while (begin < end &&
              std::isspace(
                  static_cast<unsigned char>(statement[begin])))
       {
           ++begin;
       }

       // Only treat an identifier at the start of a statement as an
       // assignment target. This avoids mistaking keyword arguments
       // inside function calls for local-variable assignments.
       if (begin >= end)
           return;

       const unsigned char first =
           static_cast<unsigned char>(statement[begin]);

       if (!std::isalpha(first) && statement[begin] != '_')
           return;

       std::size_t nameEnd = begin + 1;

       while (nameEnd < end)
       {
           const unsigned char c =
               static_cast<unsigned char>(statement[nameEnd]);

           if (!std::isalnum(c) && statement[nameEnd] != '_')
               break;

           ++nameEnd;
       }

       const std::string name =
           statement.substr(begin, nameEnd - begin);

       std::size_t pos = nameEnd;

       while (pos < end &&
              std::isspace(
                  static_cast<unsigned char>(statement[pos])))
       {
           ++pos;
       }

       if (pos >= end || statement[pos] != '=')
           return;

       // Exclude comparison, augmented, and walrus operators.
       if (pos + 1 < end &&
           (statement[pos + 1] == '=' ||
            statement[pos + 1] == '>'))
       {
           return;
       }

       if (pos > begin &&
           (statement[pos - 1] == '=' ||
            statement[pos - 1] == '!' ||
            statement[pos - 1] == '<' ||
            statement[pos - 1] == '>' ||
            statement[pos - 1] == ':'))
       {
           return;
       }

       static const std::vector<std::string> nonVariables = {
           "and", "as", "assert", "async", "await", "break",
           "class", "continue", "def", "del", "elif", "else",
           "except", "False", "finally", "for", "from", "global",
           "if", "import", "in", "is", "lambda", "None", "nonlocal",
           "not", "or", "pass", "raise", "return", "True", "try",
           "while", "with", "yield"
       };

       if (std::find(nonVariables.begin(), nonVariables.end(), name)
           != nonVariables.end())
       {
           return;
       }

       assignVariableAlias(name);
   };

   for (std::size_t i = 0; i <= statement.size(); ++i)
   {
       const char c =
           i < statement.size() ? statement[i] : ';';

       if (quote != '\0')
       {
           if (escaped)
           {
               escaped = false;
               continue;
           }

           if (c == '\\')
           {
               escaped = true;
               continue;
           }

           if (c == quote)
           {
               if (triple &&
                   i + 2 < statement.size() &&
                   statement[i + 1] == quote &&
                   statement[i + 2] == quote)
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
           triple = i + 2 < statement.size() &&
                    statement[i + 1] == c &&
                    statement[i + 2] == c;

           if (triple)
               i += 2;

           continue;
       }

       if (c == '#')
           break;

       if (c == '(' || c == '[' || c == '{')
       {
           ++depth;
       }
       else if (c == ')' || c == ']' || c == '}')
       {
           --depth;
       }
       else if (c == ';' && depth == 0)
       {
           processSegment(segmentStart, i);
           segmentStart = i + 1;
       }
   }
}

std::string PythonMinifier::replaceIdentifiers(
   const std::string& text)
{
   std::string rewritten;
   rewritten.reserve(text.size());

   char quote = '\0';
   bool triple = false;
   bool escaped = false;

   for (std::size_t i = 0; i < text.size();)
   {
       const char c = text[i];

       if (quote != '\0')
       {
           rewritten += c;
           ++i;

           if (escaped)
           {
               escaped = false;
               continue;
           }

           if (c == '\\')
           {
               escaped = true;
               continue;
           }

           if (c == quote)
           {
               if (triple &&
                   i + 1 < text.size() &&
                   text[i] == quote &&
                   text[i + 1] == quote)
               {
                   rewritten += text[i++];
                   rewritten += text[i++];
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
                    text[i + 1] == c &&
                    text[i + 2] == c;

           rewritten += c;
           ++i;

           if (triple)
           {
               rewritten += text[i++];
               rewritten += text[i++];
           }

           continue;
       }

       if (c == '#')
       {
           rewritten.append(text.substr(i));
           break;
       }

       const unsigned char first =
           static_cast<unsigned char>(c);

       if (std::isalpha(first) || c == '_')
       {
           const std::size_t begin = i++;

           while (i < text.size())
           {
               const unsigned char next =
                   static_cast<unsigned char>(text[i]);

               if (!std::isalnum(next) && text[i] != '_')
                   break;

               ++i;
           }

           const std::string name =
               text.substr(begin, i - begin);

           const bool attribute =
               begin > 0 && text[begin - 1] == '.';

           const auto found = replacements_.find(name);

           if (!attribute && found != replacements_.end())
               rewritten += found->second;
           else
               rewritten += name;

           continue;
       }

       rewritten += c;
       ++i;
   }

   return rewritten;
}

std::string PythonMinifier::shortenVariables(
   const std::string& source)
{
   std::istringstream input(source);
   std::string line;
   std::string output;

   replacements_.clear();
   nextVariableNumber_ = 1;
   nextParameterNumber_ = 1;

   int functionIndent = -1;
   bool inFunction = false;

   while (std::getline(input, line))
   {
       const std::size_t start =
           line.find_first_not_of(" \t");

       if (start == std::string::npos)
       {
           output += '\n';
           continue;
       }

       const int indent = static_cast<int>(start);
       const std::string statement = line.substr(start);

       // A function definition starts a new alias scope.
       if (statement.compare(0, 4, "def ") == 0)
       {
           functionIndent = indent;
           inFunction = true;

           const std::string rewritten =
               shortenParameters(statement);

           output += line.substr(0, start);
           output += rewritten;
           output += '\n';
           continue;
       }

       // End the current function scope when indentation returns to
       // the function's level or above.
       if (inFunction && indent <= functionIndent)
       {
           replacements_.clear();
           nextVariableNumber_ = 1;
           nextParameterNumber_ = 1;

           functionIndent = -1;
           inFunction = false;
       }

       // Leave module-level names unchanged.
       if (!inFunction)
       {
           output += line;
           output += '\n';
           continue;
       }

       collectLocalVariables(statement);

       output += line.substr(0, start);
       output += replaceIdentifiers(statement);
       output += '\n';
   }

   return output;
}
