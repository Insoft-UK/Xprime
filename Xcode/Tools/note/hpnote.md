>[!IMPORTANT]
>Draft documentation — incomplete and written as I document findings along the way. Mistakes are likely, so please don’t treat this as 100% accurate.

## HPNote Format
### UTF16le

**Plain Text Fallback**

The plain text fallback is a duplicate of the note’s content stored at the start of the .hpnote file, with all formatting, styles, and colors removed. It is not normally displayed, but serves as a backup: if the main formatted content cannot be read or is invalid, the plain text version is used instead to ensure the note’s content remains accessible.

`blar blar blar blar ...` Ends with two zero bytes (0x00) as a termination marker.

**Header**

`CSWD110￿￿\lľ`

|Start of Line|Level|?|Alignment|?|
|:-|:-|:-|:-|:-|
|`\0\m`|`\0` None|`\0`|`\0` Left|`\0\0\n`
||`\1` ●||`\1` Center
||`\2` ○||`\2` Right
||`\3` ▻

|Text Formatting|Typography & Decorations|Color|?|?|Span Length|Text Offset|TXT|EOT
|:-|:-|:----|:-|:-|:-|:-|:-|:-
|\o|000111111110000[000][S]0[U][I][B]111111111|🔲🔲 `\0\0Ā\1`|`\0\0`|` ` Ensures this text is spaced from the previous text.|Base-32 or Integer|`\0`|Your Text...|`\0`
||[000]: 10pt = 1 ... 22pt = 7|🔲⬛️ `\0\0Ā\0`|`\0\0`|`x` Ensures this text is not spaced from the previous text.
||B: [On/Off]|🔲🟧 `\0BĀ\0`
||I: [On/Off]|⬛️🔲 `\0\0\0\1`
||U: [On/Off]|⬛️⬛️ `\0\0\0\0`
||S: [On/Off]|⬛️🟧 `\0B\0\0`
|||🟥🔲 `F0\1\1`
|||🟩⬛️ `F\0\1\0`
|||🟦🟧 `FB\1\0`

**BASE-32**</br>`0123456789abcdefghijklmnopqrstuv`

**F** :- Foreground UInt16le</br>
**B** :- Background UInt16le

|End of Line|
|:-|
|`\0`|

**Footer**
|?|Base-32 or Integer|?|
|:-|:-|:-|
|`\0\0\3\0`|Number of Lines|`\0\0\0\0\0\0\0`

>[!NOTE]
>The 🔲 *Default* color is ⬛️ *Black* or ⬜️ *White* for foreground color, depending on whether the theme is light or dark. 🔲 *Clear* is fully transparent, regardless of the theme.

>[!IMPORTANT]
>Values encoded in base-32 are marked with a leading escape character `\`. Integer values are stored directly, without an escape prefix.


