<img src="assets/icon.png?raw=true" width="128" />

## Xprime Code Editor for HP Prime
- Edit your PPL or <a href="https://github.com/Insoft-UK/PrimePlus">**PPL+**</a> code for the HP Prime.
- Package your application for deployment for the HP Prime or testing on the Virtual Calculator.
- Export a G1 .hpprgm file for use on a real HP Prime or the Virtual Calculator.
- Compress code to fit more programs on your HP Prime

Download links: <a href="http://insoft.uk/action/?method=downlink&path=macos&file=xprime-universal.pkg">Xprime 26.4</a></br>
**Requires** macOS 14.6 or later

### Xprime 26
Read [Whats New](UPDATE.md)

### Hidden Version Detail
In Xprime, you can reveal the full version number from the About window.
Hold down the **Option (⌥) key**, then **click and hold** on the About window to display the extended version format, combining the app version and build number — for example: **26.3.20260311**.

<img src="assets/screenshots/xprime.png?raw=true" width="756" />

<img src="assets/screenshots/xprime/project.png?raw=true" width="294" /><img src="assets/screenshots/xprime/advance.png?raw=true" width="294" /></br>
<img src="assets/screenshots/xprime/program.png?raw=true" width="281" /><img src="assets/screenshots/xprime/application.png?raw=true" width="281" /></br>
<img src="assets/screenshots/xprime/recent.png?raw=true" width="318" /><img src="assets/screenshots/xprime/settings.png?raw=true" width="294" /></br>

### Supported File Types
|Type|Description|Format|
|:-|:-|:-|
|.xprimeproj|Xprime project|JSON|
|.ntf|NoteText|UTF8|
|.md|Markdown Language|UTF8|
|.bmp|Bitmap|.hpppl|
|.png|Portable Network Graphic|.hpppl|
|.h|Adafruit GFX Font (.hpppl)|.hpppl|
|.hpprgm|Standalone program binary|.hpppl|
|.hpappprgm|App program binary (inside .hpappdir)|.hpppl|
|.hpnote|Standalone note binary|.ntf|
|.hpappnote|App note binary (inside .hpappdir)|.ntf|
|.prgm|HP PPL source code|UTF16le|
|.hpppl|HP PPL source code|UTF8|
|.hppplplus|HP PPL Plus extended program source code|UTF8|
|.ppl|HP PPL source code|UTF8|
|.ppl+|HP PPL Plus source code|UTF8|

>In light of [HP Prime Development Tools](https://marketplace.visualstudio.com/items?itemName=AndreaBaccin.vscode-hpprime)￼ support, Xprime will adopt the .hpppl and .hppplplus file types and discontinue .prgm+. This change will simplify development for those using either Visual Studio Code or Xprime.

Typical File Structure for an HP Prime **Application**
```
MyApp/
├── Example.hpappdir/
│   │── icon.png
│   │── Example.hpapp
│   │── Example.hpappnote
│   └── Example.hpappprgm
│── Example.hpappdir.zip
│── Example.xprimeproj
│── main.hppplplus or main.hpppl
└── info.ntf
```

Typical File Structure for an HP Prime **Program**
```
MyProgram/
│── Example.xprimeproj
│── Example.hpprgm
│── main.hppplplus or main.hpppl
└── info.ntf
```

>[!NOTE]
>Use the .ppl+ extension for extended program source code and .hppplplus for the main application or program source code.

Recommended running HP Prime Virtual Calculator for Windows on macOS via **Wine Stable**.</br>
<img src="assets/screenshots/hp-prime-win.png?raw=true" width="191" /><img src="assets/screenshots/hp-prime-win-about.png?raw=true" width="440" /></br>
Download links: <a href="http://insoft.uk/downloads/macos/wine-mac-x86_64.zip">Wine Stable</a> | <a href="http://insoft.uk/downloads/pc/virtual_calculator-win-64.zip">HP Prime</a>
