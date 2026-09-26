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

#include <cctype>
#include <iostream>
#include <string>
#include <string_view>
#include <vector>

struct FunctionInfo
{
    std::string name;

    enum class Kind
    {
        Defined,
        Local,
        Export
    };

    Kind kind;
};

class PPLParser
{
public:
    explicit PPLParser(std::string_view source)
        : source(source)
    {
    }

    std::vector<FunctionInfo> parse()
    {
        std::vector<FunctionInfo> functions;

        while (!eof())
        {
            skipWhitespaceAndComments();

            if (eof())
                break;

            std::string word = readIdentifier();

            if (word.empty())
            {
                ++pos;
                continue;
            }

            if (equalsIgnoreCase(word, "LOCAL"))
            {
                parseDeclaration(functions, FunctionInfo::Kind::Local);
            }
            else if (equalsIgnoreCase(word, "EXPORT"))
            {
                parseDeclaration(functions, FunctionInfo::Kind::Export);
            }
//            else if (equalsIgnoreCase(word, "EXPORT"))
//            {
//                parseDefinition(functions);
//            }
        }

        return functions;
    }

private:
    std::string_view source;
    size_t pos = 0;

    bool eof() const
    {
        return pos >= source.size();
    }

    char peek() const
    {
        return eof() ? '\0' : source[pos];
    }

    char get()
    {
        return eof() ? '\0' : source[pos++];
    }

    static bool isIdentifierStart(char c)
    {
        return std::isalpha(static_cast<unsigned char>(c)) ||
               c == '_';
    }

    static bool isIdentifierChar(char c)
    {
        return std::isalnum(static_cast<unsigned char>(c)) ||
               c == '_';
    }

    std::string readIdentifier()
    {
        if (!isIdentifierStart(peek()))
            return {};

        size_t start = pos++;

        while (!eof() && isIdentifierChar(peek()))
            ++pos;

        return std::string(source.substr(start, pos - start));
    }

    static bool equalsIgnoreCase(std::string_view a,
                                 std::string_view b)
    {
        if (a.size() != b.size())
            return false;

        for (size_t i = 0; i < a.size(); ++i)
        {
            if (std::tolower(static_cast<unsigned char>(a[i])) !=
                std::tolower(static_cast<unsigned char>(b[i])))
            {
                return false;
            }
        }

        return true;
    }

    void skipWhitespaceAndComments()
    {
        for (;;)
        {
            while (!eof() &&
                   std::isspace(static_cast<unsigned char>(peek())))
            {
                ++pos;
            }

            // // comment
            if (pos + 1 < source.size() &&
                source[pos] == '/' &&
                source[pos + 1] == '/')
            {
                pos += 2;

                while (!eof() && peek() != '\n')
                    ++pos;

                continue;
            }

            // /* comment */
            if (pos + 1 < source.size() &&
                source[pos] == '/' &&
                source[pos + 1] == '*')
            {
                pos += 2;

                while (!eof())
                {
                    if (source[pos] == '*' &&
                        pos + 1 < source.size() &&
                        source[pos + 1] == '/')
                    {
                        pos += 2;
                        break;
                    }

                    ++pos;
                }

                continue;
            }

            break;
        }
    }

    void skipString()
    {
        char quote = get();

        while (!eof())
        {
            char c = get();

            if (c == '\\')
            {
                // Skip escaped character.
                if (!eof())
                    ++pos;
            }
            else if (c == quote)
            {
                break;
            }
        }
    }

    void skipTo(char wanted)
    {
        while (!eof())
        {
            if (peek() == '\'' || peek() == '"')
            {
                skipString();
                continue;
            }

            if (peek() == wanted)
                return;

            ++pos;
        }
    }

    void parseDeclaration(std::vector<FunctionInfo>& functions,
                          FunctionInfo::Kind kind)
    {
        skipWhitespaceAndComments();

        std::string name = readIdentifier();

        if (name.empty())
            return;

        skipWhitespaceAndComments();

        // Only consider it a function if followed by '('.
        if (peek() != '(')
            return;

        functions.push_back({
            std::move(name),
            kind
        });
    }

    void parseDefinition(std::vector<FunctionInfo>& functions)
    {
        skipWhitespaceAndComments();

        std::string name = readIdentifier();

        if (name.empty())
            return;

        skipWhitespaceAndComments();

        // EXPORT foo(...)
        if (peek() != '(')
            return;

        functions.push_back({
            std::move(name),
            FunctionInfo::Kind::Defined
        });
    }
};


