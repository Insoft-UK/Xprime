### HPPRGM or HPAPPPRGM
**.hpprgm** G1</br>
There are two known types of files using the .hpprgm extension, one includes the script name in the metadata. Both versions use UTF16 (little endian byte order) for the name and the main data.

**Unamed .hpprgm files**
This version of the file does not includes any name, just the length of the data, and the data itself.

|Byte       |00         |01|02|03|04|05|06|07|08       |09|10|11|12|13|14|15|16  |17|18|19|20  |
|:------    |:----------|:-|:-|:-|:-|:-|:-|:-|:--------|:-|:-|:-|:-|:-|:-|:-|:---|:-|:-|:-|:---|
|Example    |0C         |00|00|00|00|00|00|00|00       |00|00|00|00|00|00|00|08  |00|00|00|--  |
|Description|Header Size|  |  |  |  |  |  |  |Name Flag|  |  |  |  |  |  |  |Size|00|00|00|Data|
|Additional |    |  |  |  |  |  |  |  |Unnamed  |  |  |  |  |  |  |  |64K

**Named .hpprgm files**
Here, the name is appended to the header without any size descriptors (the name ends with two consecutive zero-valued bytes and after that, the data begins).

|Byte       |00         |01|02|03|04|05|06|07|08       |09|10|11|12|13|14|15|16        |17  |.. |..|..  |
|:------    |:----------|:-|:-|:-|:-|:-|:-|:-|:--------|:-|:-|:-|:-|:-|:-|:-|:---------|:---|:--|:-|:---|
|Example    |0C         |00|00|00|00|00|00|00|01       |00|00|00|00|00|00|00|31        |....|00 |00|... |
|Description|Header Size|  |  |  |  |  |  |  |Name Flag|  |  |  |  |  |  |  |Name Start|Name|End|Data|
|Additional |    |  |  |  |  |  |  |  |Named    |  |  |  |  |  |  |  |Name end with 0×00, 0×00

**.hpprgm** G2</br>

A .hpprgm is a nested TLV container, little-endian:

    7C 61 8A B2                        magic
    FE FF FF FF  00 00 00 00           preamble
    [u32 len][len bytes of payload]    records, nested
    ...
    <trailer>

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


