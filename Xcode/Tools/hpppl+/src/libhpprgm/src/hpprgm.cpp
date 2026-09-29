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

#include "hpprgm.hpp"
#include "ppl.hpp"

struct Record
{
    uint32_t length;
    std::vector<uint8_t> payload;
};

// MARK: - Helper Functions

static inline std::vector<uint8_t> readBytes(const std::filesystem::path& path) {
    std::ifstream f(path, std::ios::binary);
    if (!f) throw std::runtime_error("Cannot open file");

    std::vector<uint8_t> buf((std::istreambuf_iterator<char>(f)),
                              std::istreambuf_iterator<char>());
    return buf;
}

static inline void writeBytes(const std::filesystem::path& path, const std::vector<uint8_t>& data) {
    std::ofstream f(path, std::ios::binary);
    if (!f) throw std::runtime_error("Cannot write file");
    f.write((const char*)data.data(), data.size());
}

static inline std::vector<uint8_t> utf16le(const std::string& s)
{
    std::vector<uint8_t> out;
    out.reserve(s.size() * 2); // worst case UTF-16 length

    uint32_t code = 0;
    int bytesNeeded = 0;

    for (unsigned char c : s) {

        if (bytesNeeded == 0) {
            // Start of a new UTF-8 sequence
            if (c <= 0x7F) {
                // 1-byte ASCII
                uint16_t v = c;
                out.push_back(v & 0xFF);
                out.push_back((v >> 8) & 0xFF);
            }
            else if ((c & 0xE0) == 0xC0) {
                code = c & 0x1F;
                bytesNeeded = 1;
            }
            else if ((c & 0xF0) == 0xE0) {
                code = c & 0x0F;
                bytesNeeded = 2;
            }
            else if ((c & 0xF8) == 0xF0) {
                code = c & 0x07;
                bytesNeeded = 3;
            }
            else {
                // invalid UTF-8 start byte
                continue;
            }
        }
        else {
            // continuation byte
            if ((c & 0xC0) != 0x80) {
                // invalid UTF-8 continuation
                bytesNeeded = 0;
                continue;
            }

            code = (code << 6) | (c & 0x3F);

            if (--bytesNeeded == 0) {
                if (code <= 0xFFFF) {
                    // Direct UTF-16
                    uint16_t v = static_cast<uint16_t>(code);
                    out.push_back(v & 0xFF);
                    out.push_back((v >> 8) & 0xFF);
                }
                else {
                    // Surrogate pair
                    code -= 0x10000;
                    uint16_t high = 0xD800 + (code >> 10);
                    uint16_t low  = 0xDC00 + (code & 0x3FF);

                    out.push_back(high & 0xFF);
                    out.push_back((high >> 8) & 0xFF);

                    out.push_back(low & 0xFF);
                    out.push_back((low >> 8) & 0xFF);
                }
            }
        }
    }

    out.push_back(0);
    out.push_back(0);
    return out;
}

static void append16le(std::vector<uint8_t>& data, uint16_t value)
{
    data.push_back(static_cast<uint8_t>(value & 0xFF));
    data.push_back(static_cast<uint8_t>((value >> 8) & 0xFF));
}

static void append32le(std::vector<uint8_t>& data, uint32_t value)
{
    data.push_back(static_cast<uint8_t>(value & 0xFF));
    data.push_back(static_cast<uint8_t>((value >> 8) & 0xFF));
    data.push_back(static_cast<uint8_t>((value >> 16) & 0xFF));
    data.push_back(static_cast<uint8_t>((value >> 24) & 0xFF));
}

static void append_u16string(std::vector<uint8_t>& data, std::u16string_view s, const int len = 64)
{
    std::u16string str(len / 2, u'\0');
    str.replace(0, std::min(s.size(), str.size()), s);

    const auto* bytes =
        reinterpret_cast<const std::uint8_t*>(str.data());

    data.insert(data.end(), bytes, bytes + str.size() * sizeof(char16_t));
}

static void append_record(const Record record, std::vector<uint8_t>& data)
{
    if (!record.length)
        return;
    
    data.insert(data.end(), record.payload.begin(), record.payload.end());
}

static void write32le(std::vector<uint8_t>& data, size_t offset, uint32_t value)
{
    data[offset + 0] = static_cast<uint8_t>(value & 0xFF);
    data[offset + 1] = static_cast<uint8_t>((value >> 8) & 0xFF);
    data[offset + 2] = static_cast<uint8_t>((value >> 16) & 0xFF);
    data[offset + 3] = static_cast<uint8_t>((value >> 24) & 0xFF);
}

static std::vector<uint16_t> extractDataSizeBased(const std::vector<uint16_t>& hpprgm)
{
    std::vector<uint16_t> result;
    
    if (hpprgm.empty())
        return result;

    // 1. Read first word → number of bytes
    uint16_t byteCount = hpprgm[0];

    // 2. Add an extra 4 bytes
    byteCount += 4;

    // 3. Convert byte count to 16-bit word count
    size_t wordCount = byteCount / 2;         // bytes → words
    if (byteCount % 2 != 0) wordCount++;      // round up, safety
    
    // 3. Capture all values until 0x0000
    auto i = wordCount + 2;
    
    while (i < hpprgm.size() && hpprgm[i] != 0x0000) {
        result.push_back(hpprgm[i]);
        i++;
    }

    return result;
}

static std::vector<uint16_t> extractData(const std::vector<uint16_t>& hpprgm)
{
    std::vector<uint16_t> result;

    size_t n = hpprgm.size();
    size_t i = 0;

    // 1. Find the starting 32-bit signature: 0xB28A617C
    while (i + 1 < n) {
        if (hpprgm[i] == 0x617C && hpprgm[i + 1] == 0xB28A)
            break; // found signature
        i++;
    }

    if (i + 1 >= n)
        return {}; // signature not found

    i += 2; // move past signature

    // 2. Find 0x009B followed by 0x00C0
    while (i + 1 < n) {
        if (hpprgm[i] == 0x009B && hpprgm[i + 1] == 0x00C0)
            break; // found the marker
        i++;
    }

    if (i + 1 >= n)
        return {}; // not found

    i += 2; // move past 009B 00C0

    // 3. Capture all values until 0x0000
    while (i < n && hpprgm[i] != 0x0000) {
        result.push_back(hpprgm[i]);
        i++;
    }

    return result;
}

static void writeG1(const std::filesystem::path& path, const std::string& prgm, const bool includeProgramName)
{
    std::vector<uint8_t> header = {
        0x0C, 0, 0, 0, 0, 0, 0, 0,
        0,    0, 0, 0, 0, 0, 0, 0
    };
    
    if (includeProgramName) {
        auto filename = utf16le(path.filename().stem().string());
        
        uint32_t headerSize = static_cast<uint32_t>(14 + filename.size());
        write32le(header, 0, headerSize);

        header[8] = 1;
        
        append16le(header, 0x0031);
        header.insert(header.end(), filename.begin(), filename.end());
    }
    
    auto sourceCode = utf16le(prgm);
    uint32_t programSize = static_cast<uint32_t>(sourceCode.size());
    
    append32le(header, programSize);

    std::vector<uint8_t> out;
    out.reserve((uint32_t)(header.size() + sourceCode.size()));
    
    out.insert(out.end(), header.begin(), header.end());
    out.insert(out.end(), sourceCode.begin(), sourceCode.end());

    writeBytes(path, out);
}

static Record createFunctionRecord(const std::string& name, const ppl::kind type)
{
    Record record;
    const int len = 64;
    
    append32le(record.payload, len + 20);
    append32le(record.payload, len + 4);
    
    append16le(record.payload, 0x020B); // 0000 0010 0000 1011 ❓
    
    append16le(record.payload, len);
    append_u16string(record.payload, std::u16string(name.begin(), name.end()), len);
    
    append32le(record.payload, 8);
    append16le(record.payload, 0x0205); // 0000 0010 0000 0101 ❓
    append16le(record.payload, 0x0080); // 0000 0000 1000 0000 ❓
    append16le(record.payload, type == ppl::kind::Export ? 9 : 8); // 0000 0000 0000 1001 or 0000 0000 0000 1000
    append16le(record.payload, 0);

    record.length = static_cast<uint32_t>(record.payload.size());
    
    return record;
}

static Record createFunctionRecords(const std::string& prgm)
{
    Record record;
    ppl::Parser parser(prgm);
    auto functions = parser.parse();
    
    std::vector<uint8_t> records;
    
    for (const auto& function : functions) {
        append_record(createFunctionRecord(function.name, function.type), records);
    }
    
    append32le(record.payload, (uint32_t)records.size() + 4);
    append16le(record.payload, 0x023E);
    append16le(record.payload, 0x0100);
    
    record.payload.insert(record.payload.end(), records.begin(), records.end());
    record.length = static_cast<uint32_t>(record.payload.size());
    
    return record;
}

static Record createPPLCodeRecord(const std::string& prgm)
{
    Record record;
    auto sourceCode = utf16le(prgm);
    uint32_t programSize = static_cast<uint32_t>(sourceCode.size());
    
    
    append32le(record.payload, programSize + 100);
    append16le(record.payload, 0x00BE);
    append16le(record.payload, 0x0140);
    append32le(record.payload, programSize + 100 - 8);
    append16le(record.payload, 68);
    append16le(record.payload, 0);
    append16le(record.payload, 139);
    append16le(record.payload, 64);
    
    append_u16string(record.payload, u"Main", 64);
    
    append32le(record.payload, 8);
    append16le(record.payload, 133);
    append16le(record.payload, 128);
    append32le(record.payload, 0);
    
    append32le(record.payload, programSize + 4);
    append16le(record.payload, 155);
    append16le(record.payload, 192);
    
    record.payload.reserve(sourceCode.size());
    record.payload.insert(record.payload.end(), sourceCode.begin(), sourceCode.end());
    
    record.length = static_cast<uint32_t>(record.payload.size());
    
    return record;
}

static void writeG2(const std::filesystem::path& path, const std::string& prgm)
{
    /**
     A .hpprgm is a nested TLV container, little-endian:

         7C 61 8A B2                        magic
         FE FF FF FF  00 00 00 00           preamble
         [u32 len][len bytes of payload]    records, nested
         ...
         <trailer>
     */
    
    const std::vector<uint8_t> magic = {
        0x7C, 0x61, 0x8A, 0xB2
    };
    
    const std::vector<uint8_t> preamble = {
        0xFE, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00
    };
    
    std::vector<uint8_t> out;
    
    out.insert(out.end(), magic.begin(), magic.end());
    out.insert(out.end(), preamble.begin(), preamble.end());
//    const std::vector<uint8_t> uknownRecords = {
//        0x08, 0x00, 0x00, 0x00, 0x05, 0xFF, 0x7F, 0x00, 0x00, 0x00, 0x00, 0x00,
//        0x08, 0x00, 0x00, 0x00, 0x05, 0xFF, 0x3F, 0x02, 0x00, 0x00, 0x00, 0x00,
//        0x08, 0x00, 0x00, 0x00, 0x05, 0xFF, 0xBF, 0x00, 0x02, 0x00, 0x00, 0x00
//    };
//    out.insert(out.end(), uknownRecords.begin(), uknownRecords.end());
    
    append_record(createFunctionRecords(prgm), out);
    append_record(createPPLCodeRecord(prgm), out);
    
    writeBytes(path, out);
}

// MARK: - 📣 Public API functions

void hpprgm::write(const std::filesystem::path& path, const std::string& prgm, const format fmt, const bool includeProgramName)
{
    if (fmt == format::G1) {
        writeG1(path, prgm, includeProgramName);
        return;
    }
    
    writeG2(path, prgm);
}

std::wstring hpprgm::source(const std::filesystem::path& path)
{
    std::wstring wstr;
    std::vector<uint8_t> bytes;

    // Read raw bytes from file
    bytes = readBytes(path);

    // Convert raw bytes to 16-bit words (little-endian) for parsing
    std::vector<uint16_t> words;
    words.reserve(bytes.size() / 2);
    for (size_t i = 0; i + 1 < bytes.size(); i += 2) {
        uint16_t v = static_cast<uint16_t>(bytes[i]) | (static_cast<uint16_t>(bytes[i + 1]) << 8);
        words.push_back(v);
    }

    // Extract the UTF-16LE payload words using existing parser
    auto prgm = extractData(words);
    if (prgm.empty()) {
        prgm = extractDataSizeBased(words);
    }

    // Convert UTF-16LE payload to wstring (stop at 0x0000 if present)
    for (uint16_t u : prgm) {
        if (u == 0x0000) break;
        wstr.push_back(static_cast<wchar_t>(u));
    }

    return wstr;
}
