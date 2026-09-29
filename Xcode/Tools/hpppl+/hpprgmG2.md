**.hpprgm** G2</br>

>[!WARNING]
>Draft documentation — incomplete and written as I document findings along the way. Mistakes are likely, so please don’t treat this as 100% accurate.

An .hpprgm file is the standard compiled program file format used by the HP Prime graphing calculator.

Overview of the Format
* **Encoding**: Uses UTF-16 (little-endian byte order) for internal script names and metadata strings.

* **Language**: Contains code written in HP PPL (Prime Programming Language).

* **Structure**: Consists of a nested, little-endian TLV container. It consists of a top-level header, an exported-item table describing the program’s exported variables and functions, and separate data/value blocks containing the associated program data.

A TLV container is a simple way of storing multiple pieces of data inside a file or binary stream using:

T — Type
Identifies what the data is.

L — Length
Specifies how many bytes the data occupies.

V — Value
The actual data.

The PPL source is stored inside one of these records as UTF-16LE, using LF line endings (not CRLF) and a terminating NUL. It is stored verbatim: neither compressed nor encrypted.

The trailer, if present, is 1008 bytes in programs created by the Connectivity Kit. However, the calculator’s built-in applications demonstrate that this size is not universal, so the format does not rely on a fixed trailer length.

Programs that declare large matrices may also contain a COMPILED BLOCK before the source. This contains the matrix data in the calculator’s internal format, which explains why these files can be roughly three times the size of their source and can be opened without waiting for compilation.

<table><thead>
  <tr>
    <th align="left">Bytes</th>
    <th>0</th>
    <th>1</th>
    <th>2</th>
    <th>3</th>
    <th>4</th>
    <th>5</th>
    <th>6</th>
    <th>7</th>
    <th>8</th>
    <th>9</th>
    <th>10</th>
    <th>11</th>
    <th>12</th>
    <th>13</th>
    <th>14</th>
    <th>15</th>
    <th></th>
  </tr></thead>
<tbody>
  <tr>
    <td>Example</td>
    <td>7C</td>
    <td>61</td>
    <td>8A</td>
    <td>B2</td>
    <td>FE</td>
    <td>FF</td>
    <td>FF</td>
    <td>FF</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>...</td>
    <td>...</td>
    <td>...</td>
    <td>...</td>
    <td>...</td>
  </tr>
  <tr>
    <td>Description</td>
    <td colspan="4">Magic</td>
    <td colspan="4">Preamble</td>
    <td colspan="4" nowrap>Reserved</td>
    <td colspan="4" nowrap>Little-endian u32; length of the following data</td>
    <td>Data</td>
  </tr>
</tbody>
</table>

The file begins with a fixed 12-byte header (`magic`, `preamble`, and reserved
field), followed by a little-endian `u32` payload length and that many bytes of
payload. The payload consists of nested records, each encoded as a TLV structure.  

Nested Records

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
        


