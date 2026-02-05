
|Start|Style & Font Size|Foreground & Background|
|:-|:-|:-|
|\o|000111111110000[000][S]0[U][I][B]111111111|\0\0Ā\1\0\0 Foreground (DEFAULT), Background (CLEAR)|
||[000]: Font10 = 1, Font12 = 2, ... Font22 = 7|\0BĀ\0\0\0 Foreground (DEFAULT) & Background (COLOR)|
||B: Bold [On/Off]|FB\1\0\0\0 F =  Foreground (COLOR), Background (COLOR)|
||I: Italic [On/Off]|\0\0\1\0\0\0 Foreground (BLACK), Background (BLACK)|
||U: Underlined [On/Off]|\0B\1\0\0\0 Foreground (BLACK), Background (COLOR)|
||S: Strikethrough [On/Off]|F\0\1\0\0\0 Foreground (COLOR), Background (BLACK)|
|||F\0\1\1\0\0 Foreground (COLOR), Background (CLEAR)|
|||\00\0\1\0\0 Foreground (BLACK), Background (CLEAR)|
