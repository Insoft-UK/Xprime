>[!IMPORTANT]
>Draft documentation — incomplete and written as I document findings along the way. Mistakes are likely, so please don’t treat this as 100% accurate.

## HPNote Format
### UTF16le
|Line Attributes|Level|?|Alignment|?|
|:-|:-|:-|:-|:-|
|\0\m|\0 None|\0|\0 Left|\0\0\n|
||\1 ●||\1 Center||
||\2 ○||\2 Right||
||\3 ▻||||

|Text Formatting|Style & Font Size|Foreground & Background|?|Length|Start of Text|
|:-|:-|:----|:-|:-|:-|
|\o|000111111110000[000][S]0[U][I][B]111111111|🔲🔲 `\0\0Ā\1`|`\0\0 ` Text contains white spaces|\\[0...9a...v] Length < 32|\0|
||[000]: 10pt = 1 ... 22pt = 7|🔲⬛️ `\0\0Ā\0`|`\0\0x` No white spaces|[ !"#$%&'()*+,-./0...9a...v]||
||B: [On/Off]|🔲🟧 `\0BĀ\0`||||
||I: [On/Off]|⬛️🔲 `\0\0\0\1`||||
||U: [On/Off]|⬛️⬛️ `\0\0\0\0`||||
||S: [On/Off]|⬛️🟧 `\0B\1\0`||||
|||🟥🔲 `F0\1\1`||||
|||🟩⬛️ `F\0\1\0`||||
|||🟦🟧 `FB\1\0`||||

|End of Line|
|:-|
|\0|

>[!NOTE]
>The 🔲 *Default* color is ⬛️ *Black* or ⬜️ *White* for foreground color, depending on whether the theme is light or dark. 🔲 *Clear* is fully transparent, regardless of the theme.

**F** :- Foreground UInt16le

**B** :- Background UInt16le
