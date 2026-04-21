>[!WARNING]
>Draft documentation — incomplete and written as I document findings along the way. Mistakes are likely, so please don’t treat this as 100% accurate.

>[!IMPORTANT]
>Values encoded in base-32 are indicated by a leading escape character `\`. Integer values are stored directly, without any escape prefix. The only exception is the integer 92, which is also marked with a leading `\`, because 92 corresponds to `\` in ASCII.

## HPNote Format
### UTF16le

**Plain Text Fallback**

The plain text fallback is a duplicate of the note’s content stored at the start of the .hpnote file, with all formatting, styles, and colors removed. It is not normally displayed, but serves as a backup: if the main formatted content cannot be read or is invalid, the plain text version is used instead to ensure the note’s content remains accessible.

`blar blar blar blar ...` </br>
Ends with a 16-bit integer value of zero **0x0000** as a termination marker.

**Header**

|MAGIC|TYPE|VERSION|
|:-|:-|:-|
|`CSW`|`D`|`110`|
||`T`||

**D** Notes | **T** Info

After the header comes two 16-bit integers, values set to 0xFFFF (65535) for both.
`￿￿`

Next comes the first entry, all entries are terminated by `\0` (zero), Uknown what `ľ` is for ?
|BEGIN||END|
|:-|:-|:-|
|`\l`|`ľ`|`\0`

Every line starts with data defining bullets and alignment.
Data Size (5)
|BEGIN|BULLET|?|ALIGNMENT|END
|:-|:-|:-|:-|:-|
|`\m`|`\0` None|`\0`|`\0` Left|`\0`
||`\1` ●||`\1` Center
||`\2` ○||`\2` Right
||`\3` ▻

Start of line
|START|
|:-|
|`\n`|

Every line cotains an entry.

|BEGIN|Typography & Decorations|COLORS|?|Script|Span Length|-|TXT|END
|:-|:-|:----|:-|:-|:-|:-|:-|:-
|\o|00011111111[00]00[000][S]0[U][I][B]111111111|🔲🔲 `\0\0Ā\1`|`\0`|`\0` None|` ` Ensures this text is spaced from the previous text.|Base-32 or Integer|`\0`|Your Text...|`\0`
||[000] 8pt (Not Used)</br>[001] 10pt</br>[010] 12pt</br>[011] 14pt</br>[100] 16pt</br>[101] 18pt</br>[110] 20pt</br>[111] 22pt|🔲⬛️ `\0\0Ā\0`||`\1` Superscript|`x` Ensures this text is not spaced from the previous text.
||B: [On/Off]|🔲🟧 `\0BĀ\0`||`\2` Subscript
||I: [On/Off]|⬛️🔲 `\0\0\0\1`
||U: [On/Off]|⬛️⬛️ `\0\0\0\0`
||S: [On/Off]|⬛️🟧 `\0B\0\0`
||[00] L|🟥🔲 `F\0\1\1`
||[01] C|🟩⬛️ `F\0\1\0`
||[10] R|🟦🟧 `FB\1\0`


**F** :- Foreground UInt16le</br>
**B** :- Background UInt16le

The line ends with two zeros, no more line entries.
|BEGIN|END|
|:-|:-|
|`\0`|`\0`|

**Footer**
After all the lines comes the footer, that states the number of lines entries.
Data Size (10)
|?|Base-32 or Integer|?|
|:-|:-|:-|
|`\0\3\0`|Number of Lines|`\0\0\0\0\0\0\0`

>[!NOTE]
>The 🔲 *Default* color is ⬛️ *Black* or ⬜️ *White* for foreground color, depending on whether the theme is light or dark. 🔲 *Clear* is fully transparent, regardless of the theme.



