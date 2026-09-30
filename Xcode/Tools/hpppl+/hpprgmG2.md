**.hpprgm** G2</br>

>[!WARNING]
>Draft documentation — incomplete and written as I document findings along the way. Mistakes are likely, so please don’t treat this as 100% accurate.

An .hpprgm file is the standard compiled program file format used by the HP Prime graphing calculator.

### Overview of the Format

* **Encoding**: Uses UTF-16LE (little-endian byte order) for internal program names, metadata strings, and PPL source code.
* **Language**: Contains code written in HP PPL (Prime Programming Language).
* **Structure**: Consists of a nested, little-endian, length-prefixed record structure. The file contains a top-level header followed by a hierarchy of records and subrecords. These describe the program’s exported items, local or defined items, associated names and metadata, program source, and other data/value blocks.

The structure is **TLV-like**, but it is not a conventional Type-Length-Value (TLV) format. Records are primarily identified by their length, while type and flag information is contained within the record’s data rather than necessarily preceding the length as a separate type field.

A conventional TLV structure consists of:

**T — Type**<br />
Identifies what the data represents.

**L — Length**<br />
Specifies the size of the associated value.

**V — Value**<br />
Contains the actual data.

The ***.hpprgm*** format instead uses length-prefixed records, which may contain typed fields and further nested records. Therefore, “nested length-prefixed record structure” is a more precise description than simply calling it a TLV container.

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
    <td colspan="4" nowrap>Little-endian u32; length of the following payload</td>
    <td>Payload</td>
  </tr>
</tbody>
</table>

The file begins with a fixed 12-byte header consisting of a magic value, preamble, and reserved field. This is followed by a 32-bit little-endian payload length and the specified number of payload bytes.

The payload consists of nested, length-prefixed records. These records may contain typed fields and further nested records; the format is therefore TLV-like, but is not a conventional Type-Length-Value (TLV) structure. 

### Nested Records

The payload is organised as a hierarchy of length-prefixed records. The examples below show the general structure and the meaning of the fields identified so far.


    [ u32 length ][ record data
        [ u32 length ][ record data
            [ u32 length ][ field data ]
            [ u32 length ][ field data ]
            ...
        ]
    ]
    
**Example**:

<table>
  <thead>
    <tr>
      <th align="left" colspan="4">Size</th>
      <th align="left" colspan="5">Payload</th>
  </tr>
  </thead>
  <tbody>
  <tr>
    <td>xx</td>
    <td>xx</td>
    <td>xx</td>
    <td>xx</td>
    <td>3E</td>
    <td>02</td>
    <td>00</td>
    <td>01</td>
    <td>
      <table>
        <thead>
          <tr>
            <th align="left" colspan="4">Size</th>
            <th align="left" colspan="16">Payload</th>
          </tr>
        </thead>
        <tr>
          <td>54</td>
          <td>00</td>
          <td>00</td>
          <td>00</td>
          <td>
            <table>
              <thead>
                <tr>
                  <th align="left" colspan="4">Size</th>
                  <th align="left" colspan="8">Payload</th>
                </tr>
              </thead>
              <tr>
                <td>44</td>
                <td>00</td>
                <td>00</td>
                <td>00</td>
                <td>0B</td>
                <td>02</td>
                <td>40</td>
                <td>00</td>
                <td>...</td>
              </tr>
                <td colspan="4" nowrap>Payload Size (68)</td>
                <td colspan="2" nowrap>Function</td>
                <td colspan="2" nowrap>Name Size (64)</td>
                <td nowrap>UTF-16LE Name, 64 bytes</td>
              </tr>
            </table>
          </td>
          <td>
            <table>
              <thead>
                <tr>
                  <th align="left" colspan="4">Size</th>
                  <th align="left" colspan="8">Payload</th>
                </tr>
              </thead>
              <tr>
                <td>08</td>
                <td>00</td>
                <td>00</td>
                <td>00</td>
                <td>05</td>
                <td>02</td>
                <td>80</td>
                <td>00</td>
                <td>xx</td>
                <td>00</td>
                <td>00</td>
                <td>00</td>
              </tr>
              <tr>
                <td colspan="4" nowrap></td>
                <td colspan="2" nowrap></td>
                <td colspan="2" nowrap></td>
                <td nowrap>09 EXPORT else 08</td>
              <td></td>
              <td></td>
              <td></td>
              </tr>
            </table>
          </td>
          <tr>
            <td colspan="4" nowrap>Payload Size (84)</td>
            <td colspan="2"></td>
          </tr>
        </tr>
      </table>
    </td>
  </tr>
    </tbody>
</table>
    
    [ xx xx xx xx ][ BE 00 40 01
        [ xx xx xx xx ][
            [ 44 00 00 00 ][ 8B 00 40 00 <UTF-16LE name, 64 bytes> ]
            [ 08 00 00 00 ][ 85 00 80 00 00 00 00 00 ]
            [ xx xx xx xx ][ 9B 00 C0 00 <UTF-16LE PPL source> ]
        ]
    ]

The four-byte values shown as **xx xx xx xx** are lengths whose exact interpretation depends on the containing record. The data following each length may itself contain additional length-prefixed records, producing the nested structure.



