
|Start|Style & Font Size|Foreground & Background|
|:-|:-|:-|
|\o|000111111110000[000][S]0[U][I][B]111111111|\0\0Ā\1 Foreground (DEFAULT), Background (CLEAR)|
||[000]: Font10 = 1, Font12 = 2, ... Font22 = 7|\0BĀ\0 Foreground (DEFAULT) & Background (COLOR)|
||B: Bold [On/Off]|FB\1\0 Foreground (COLOR), Background (COLOR)|
||I: Italic [On/Off]|F\0\1\0 Foreground (COLOR), Background (BLACK)|
||U: Underlined [On/Off]|F\0\1\1 Foreground (COLOR), Background (CLEAR)|
||S: Strikethrough [On/Off]|\0B\1\0 Foreground (BLACK), Background (COLOR)|
|||\00\0\1 Foreground (BLACK), Background (CLEAR)|
|||\0\0\1\0 Foreground (BLACK), Background (BLACK)|

**Background**
Color RGB555 | Black \0 | Clear 0 if Foreground is not Color else \0
