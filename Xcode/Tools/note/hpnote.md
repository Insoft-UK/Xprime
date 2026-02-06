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
|:-|:-|:-|:-|:-|:-|
|\o|000111111110000[000][S]0[U][I][B]111111111|\0\0Ā\1 Foreground (*Default*), Background (*Clear*)|"\0\0 " Include Spaces|\\[0...9a...v] Length < 32|\0|
||[000]: Font10 = 1, Font12 = 2, ... Font22 = 7|\0\0Ā\0 Foreground (*Default*) & Background (BLACK)|"\0\0x" Excludes Spaces|[ !"#$%&'()*+,-./0...9a...v]||
||B: Bold [On/Off]|\0**B**Ā\0 Foreground (*Default*) & Background (COLOR)||||
||I: Italic [On/Off]|\0\0\0\1 Foreground (BLACK) & Background (*Clear*)||||
||U: Underlined [On/Off]|\0\0\0\0 Foreground (BLACK) & Background (BLACK)||||
||S: Strikethrough [On/Off]|\0**B**\1\0 Foreground (BLACK) & Background (COLOR)||||
|||**F**0\1\1 Foreground (COLOR) & Background (*Clear*)||||
|||**F**\0\1\0 Foreground (COLOR) & Background (BLACK)||||
|||**FB**\1\0 Foreground (COLOR) & Background (COLOR)||||

|End of Line|
|:-|
|\0|

>[!NOTE]
>The “*Default*“ color is black or white for foreground color, depending on whether the theme is light or dark. “*Clear*” is fully transparent, regardless of the theme.

**F** = Foreground UInt16le

**B** = Background UInt16le
