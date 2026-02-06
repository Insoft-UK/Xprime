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
|\o|000111111110000[000][S]0[U][I][B]111111111|\0\0Ā\1 Foreground (DEFAULT), Background (CLEAR)|"\0\0 " Include Spaces|\\[0...9a...v] Length < 32|\0|
||[000]: Font10 = 1, Font12 = 2, ... Font22 = 7|\0\0Ā\0 Foreground (DEFAULT) & Background (BLACK)|"\0\0x" Excludes Spaces|[ !"#$%&'()*+,-./0...9a...v]||
||B: Bold [On/Off]|\0BĀ\0 Foreground (DEFAULT) & Background (COLOR)||||
||I: Italic [On/Off]|\0\0\0\1 Foreground (BLACK) & Background (CLEAR)||||
||U: Underlined [On/Off]|\0\0\0\0 Foreground (BLACK) & Background (BLACK)||||
||S: Strikethrough [On/Off]|\0B\1\0 Foreground (BLACK) & Background (COLOR)||||
|||F0\1\1 Foreground (COLOR) & Background (CLEAR)||||
|||F\0\1\0 Foreground (COLOR) & Background (BLACK)||||
|||FB\1\0 Foreground (COLOR) & Background (COLOR)||||

|End of Line|
|:-|
|\0|

**Background**
Color RGB555 | Black \0 | Clear 0 if Foreground is not Color else \0
