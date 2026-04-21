<img src="assets/icon.png?raw=true" width="128" />

## Xprime Code Editor for HP Prime
- Edit your PPL or <a href="Xcode/Tools/hpppl%2B">**PPL+**</a> code for the HP Prime.
- Package your application for deployment for the HP Prime or testing on the Virtual Calculator.
- Export a G1 .hpprgm file for use on a real HP Prime or the Virtual Calculator.
- Compress code to fit more programs on your HP Prime

**Universal**
Download link: <a href="http://insoft.uk/action/?method=downlink&path=macos&file=xprime-universal.pkg">Xprime 26.4.2</a></br>
Requires **macOS 14.6** or later

**Apple Silicon**
Download link: <a href="http://insoft.uk/action/?method=downlink&path=macos&file=xprime-arm64.pkg">Xprime 26.4.3</a></br>
Requires **macOS 26** or later

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
|Type|Description|
|:-|:-|
|.xprimeproj|Xprime project|
|.ntf|NoteText|
|.bmp|Bitmap (.hpppl)|
|.png|Portable Network Graphic (.hpppl)|
|.h|Adafruit GFX Font (.hpppl)|
|.hpprgm|Standalone program binary|
|.hpappprgm|App program binary (inside .hpappdir)|
|.hpappnote|App note binary (inside .hpappdir)|
|.hpnote|Standalone note binary|
|.prgm|HP PPL source text (UTF16le)|
|.hpppl|HP PPL source text|
|.hppplplus|HP PPL+ source text|

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
