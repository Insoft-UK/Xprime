// The MIT License (MIT)
//
// Copyright (c) 2023-2025 Insoft.
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
#include <sstream>
#include <vector>
#include <list>
#include <regex>
#include <unordered_set>

std::string ensureSpaceAfterKeywords(const std::string& input, const std::vector<std::string>& keywords);
std::string ensureSpaceAfterKeywordsCaseInsensitive(const std::string& input, const std::vector<std::string>& keywords) ;

/**
 * @brief Replaces common two-character operators with their symbolic Unicode equivalents.
 *
 * This function scans the input string and replaces specific two-character operator
 * sequences with their corresponding Unicode symbols:
 *
 * - `>=` becomes `≥`
 * - `<=` becomes `≤`
 * - `<>` becomes `≠`
 *
 * All other characters are copied as-is.
 *
 * @param input The input string potentially containing ASCII operator sequences.
 * @return A new string with supported operators replaced by Unicode symbols.
 *
 * @note Useful for rendering more readable mathematical or logical expressions in UI output,
 *       documents, or educational tools.
 */
std::string replaceOperators(const std::string& input);

/**
 * @brief Extracts a single-line PPL comment from a given string.
 *
 * This function searches for the occurrence of a PPL  comment
 * marker (`//`) in the input string and returns the comment, excluding the `//`.
 * If no comment is found, an empty string is returned.
 *
 * @param str The input string potentially containing a PPL comment.
 * @return The extracted comment starting with `//`, or an empty string if none is found.
 */
std::string extractComment(const std::string &str);

std::vector<std::string> extractComments(const std::string& str);
std::string restoreComments(const std::string& str, const std::vector<std::string>& comments);

std::string removeComment(const std::string& str);

/**
 * @brief Removes a PPL single-line comment from a line of source code.
 *
 * This function scans a string representing a line of PPL (HP Prime Programming Language)
 * source code and removes any single-line comment starting with `//`.
 * If no comment is found, the original string is returned unchanged.
 *
 * @param str A line of PPL source code.
 * @return The input line without the `//` comment, if present.
 *
 */
std::string removeComments(const std::string& str);

std::string blankOutComments(const std::string& str);

/**
 * @brief Processes escape sequences in a string and replaces them with corresponding characters.
 *
 * This function scans the input string for backslash-prefixed escape sequences and replaces
 * them with their corresponding characters or strings. Supported escape sequences include:
 *
 * - `\\n` → newline character (`\n`)
 * - `\\s` → space (`' '`)
 * - `\\t` → tab-like spacing (4 spaces)
 *
 * Unrecognized escape sequences are preserved as-is (i.e., the backslash and the following character).
 *
 * @param input The input string potentially containing escape sequences.
 * @return A new string with escape sequences expanded into their corresponding characters.
 */
std::string processEscapes(const std::string& input, int indentWidth = 2);

/**
 * @brief Removes a triple-slash (`///`) comment from a line of source code.
 *
 * This function searches for the first occurrence of a `///` comment in the input
 * string and removes the comment portion. If a newline follows the comment, only the
 * comment part up to the newline is removed; otherwise, the remainder of the string
 * is removed. This is useful for stripping documentation-style comments (e.g., in PPL or C++).
 *
 * @param str A string potentially containing a `///` comment.
 * @return A copy of the input string with the `///` comment removed.
 *
 * @note This function does not remove standard `//` comments or handle multiline block comments.
 */
std::string removeTripleSlashComment(const std::string& str);


/**
 * @brief Converts single assignment `=` operators to `:=`, preserving comparison and existing assignment syntax.
 *
 * This function scans the input string and replaces standalone `=` characters with `:=`,
 * often used in languages like Pascal or certain calculators to represent assignment.
 * It carefully handles the following cases:
 *
 * - `==` (equality comparison) is preserved and not modified.
 * - `:=` (already valid assignment syntax) is left unchanged.
 * - Any other standalone `=` is converted to `:=`.
 *
 * @param input The input string potentially containing assignment or comparison operators.
 * @return A new string with appropriate `=` characters converted to `:=`.
 *
 * @note Useful for translating code or expressions from languages that use `=` for assignment
 *       into those that use `:=`, while avoiding accidental changes to comparison or already-valid syntax.
 */
std::string convertAssignToColonEqual(const std::string& input);


/**
 * @brief Expands single `=` characters into `==` for comparison, preserving special cases.
 *
 * This function processes an input string and replaces single `=` characters with `==`,
 * which is commonly used for comparison in many programming languages. It handles the
 * following exceptions:
 *
 * - `:=` (colon-equals) is left unchanged, as it may represent assignment in some languages.
 * - `==` is preserved and not duplicated.
 *
 * This is useful for transforming assignment-style expressions into comparison-style
 * expressions for parsing or analysis.
 *
 * @param input The input string containing `=` characters.
 * @return A new string with applicable `=` characters expanded to `==`.
 *
 * @note This function assumes a language syntax where `==` is the comparison operator and
 *       `:=` has a distinct meaning. It does not perform full syntax validation.
 */
std::string expandAssignmentEquals(const std::string& input);

std::list<std::string> extractPythonBlocks(const std::string& str);
std::string blankOutPythonBlocks(const std::string& str);
std::string restorePythonBlocks(const std::string& str, std::list<std::string>& blocks);
std::string separatePythonMarkers(const std::string& input);

/**
 * @brief Normalizes spacing around operators in a string.
 *
 * This function ensures that operators from a predefined list are properly spaced
 * within the input string. It scans the string, identifies any known operators,
 * and inserts spaces before and after them if needed to ensure consistent formatting.
 *
 * After operator normalization, the function also removes any extra or redundant
 * whitespace, ensuring clean and readable output.
 *
 * @param input The input string that may contain operators with inconsistent spacing.
 * @param operators The list of `operators`.
 * @return A new string with operators consistently spaced and extraneous whitespace removed.
 */

std::string normalizeOperators(const std::string& input, const std::vector<std::string> operators);
