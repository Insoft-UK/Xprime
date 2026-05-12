<img src="assets/icon.png?raw=true" width="128" />

## Xprime Code Editor for HP Prime
- Edit your PPL or <a href="Xcode/Tools/hpppl%2B">**PPL+**</a> code for the HP Prime.
- Package your application for deployment for the HP Prime or testing on the Virtual Calculator.
- Export a G1 .hpprgm/.hpappprgm file for use on a real HP Prime or the Virtual Calculator.
- Compress code to fit more programs on your HP Prime

>[!IMPORTANT]
>Before running your program or application on either the Virtual HP Prime or a physical HP Prime calculator, you must first open the source code and perform a “Check” once.  
>
>This is required because Xprime currently generates .hpprgm and .hpappprgm files using an older format originally used by early HP Prime G1 firmware. The HP Prime will initially accept the file, but it must be resaved by the calculator before it becomes a fully valid modern .hpprgm or .hpappprgm file.  
>
>Simply opening the source code in the editor and performing a “Check” — or even just viewing the code and exiting the editor — causes the HP Prime to automatically resave the file using the current supported format. Once this has been done, the program or application will run normally.

**Universal**
Download link: <a href="http://insoft.uk/action/?method=downlink&path=macos&file=xprime-installer-universal.zip">Xprime 26.5</a></br>
Requires **macOS 14.6** or later

### Reveal Version Detail
In Xprime, you can reveal the full version number from the About window.
Hold down the **Option (⌥) key**, then **click and hold** on the About window to display the extended version format, combining the app version and build number — for example: **26.5.20260511**.

<img src="assets/screenshots/xprime.png?raw=true" width="756" />

### Supported File Types
|Type|Description|
|:-|:-|
|.xprimeproj|Xprime project|
|.bmp|Bitmap (opens as .hpppl)|
|.png|Portable Network Graphic (opens as .hpppl)|
|.h|Adafruit GFX Font (opens as .hpppl)|
|.hpprgm|Standalone program binary|
|.hpappprgm|App program binary (inside .hpappdir)|
|.hpappnote|App note binary (inside .hpappdir)|
|.hpnote|Standalone note binary (opens as .hpppl)|
|.note|Note source text|
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
│── Example.xprimeproj
│── main.hppplplus or main.hpppl
└── info.note
```

Typical File Structure for an HP Prime **Program**
```
MyProgram/
│── Example.xprimeproj
│── Example.hpprgm
│── main.hppplplus or main.hpppl
└── info.note
```
