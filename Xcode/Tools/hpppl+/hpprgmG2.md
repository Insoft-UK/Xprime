**.hpprgm** G2</br>

>[!WARNING]
>Draft documentation — incomplete and written as I document findings along the way. Mistakes are likely, so please don’t treat this as 100% accurate.

An .hpprgm file is the standard compiled program file format used by the HP Prime graphing calculator.

Overview of the Format
* **Encoding**: Uses UTF-16 (little-endian byte order) for internal script names and metadata strings.

* **Language**: Contains code written in HP PPL (Prime Programming Language).

* **Structure**: Consists of a nested, little-endian TLV container. It consists of a top-level header, an exported-item table describing the program’s exported variables and functions, and separate data/value blocks containing the associated program data.

| Offset | Size | Field | Description |
|---:|---:|---|---|
| `0x00` | 4 | Magic | `7C 61 8A B2` — file magic |
| `0x04` | 4 | Preamble | `FE FF FF FF` |
| `0x08` | 4 | Reserved | `00 00 00 00` |
| `0x0C` | 4 | Length | Little-endian `u32`; length of the following payload |
| `0x10` | `len` | Payload | `len` bytes containing the nested records |

The file begins with a fixed 12-byte header (`magic`, `preamble`, and reserved
field), followed by a little-endian `u32` payload length and that many bytes of
payload. The payload consists of nested records, each encoded as a TLV structure.  

Nested Records

    [ 08 00 00 00 ]:[ 05 FF 7F 00 00 00 00 00 ]    ❓
    [ 08 00 00 00 ]:[ 05 FF 3F 02 00 00 00 00 ]    ❓
    [ 08 00 00 00 ]:[ 05 FF BF 00 02 00 00 00 ]    ❓
    [ xx xx xx xx ]:[ 3E 02 00 01 [ 
        [ 54 00 00 00 ]:[
            [ 44 00 00 00 ]:[ 0B 02 40 00 (UTF16LE Named... 64 bytes) ]
            [ 08 00 00 00 ]:[ 05 02 80 00 xx 00 00 00 ]
                                          ├── 09 : EXPORT
                                          └── 08 : LOCAL or Defined
        ]
        ...
    ]
    [ xx xx xx xx ]:[ BE 00 40 01
        [ xx xx xx xx ]:[
            [ 44 00 00 00 ]:[ 8B 00 40 00 (UTF16LE Named... 64 bytes) ]
            [ 08 00 00 00 ]:[ 85 00 80 00 00 00 0 00 ]
            [ xx xx xx xx ]:[ 9B 00 C0 00 (UTF16LE PPL Code) ]
        ]
    ]
        
A TLV container is a simple way of storing multiple pieces of data inside a file or binary stream using:

T — Type
Identifies what the data is.

L — Length
Specifies how many bytes the data occupies.

V — Value
The actual data.

The PPL source is stored inside one of these records as UTF-16LE, using LF line endings (not CRLF) and a terminating NUL. It is stored verbatim: neither compressed nor encrypted.

The trailer, if present, is 1008 bytes in programs created by the Connectivity Kit. However, the calculator’s built-in applications demonstrate that this size is not universal, so the format does not rely on a fixed trailer length. Instead, the source record is located by its structure (see _source_record), and everything following it is preserved unchanged.

A code program consists of a header, source record, and trailer. Programs that declare large matrices may also contain a COMPILED BLOCK before the source. This contains the matrix data in the calculator’s internal format, which explains why these files can be roughly three times the size of their source and can be opened without waiting for compilation.

