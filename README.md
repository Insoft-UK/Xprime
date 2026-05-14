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

**Download link**: <a href="http://insoft.uk/action/?method=downlink&path=macos&file=xprime-installer-universal.zip">Xprime 26.5 Installer</a> | [Xprime 26.5](http://insoft.uk/action/?method=downlink&path=macos&file=xprime-universal.zip)</br>
>[!NOTE]
>Xprime Installer is a package-based installer. The other version is simply the Xprime application, which you can drag and drop into your Applications folder. It also includes the Tools, which can be installed separately if you do not already have the latest Xprime Tools installed.

### Requirements
AppleSilicon or intel</br>
**macOS 14.6** or later</br>
[HP Prime Virtual Calculator](https://updates.moravia-consulting.com/beta/macos/HP_Prime_Virtual_Calculator_BETA_2026_04_01.dmg)</br>
[HP Connectivity Kit](https://updates.moravia-consulting.com/beta/macos/HP_Prime_Connectivity_Kit_BETA_20260401.dmg) (for calculator sync)</br>

**Ongoing Development**</br>
Nothing significant is planned between now and next year. However, any tweaks, refinements, or issues I address in Xprime will be part of Xprime 27, codenamed Opux — inspired by the Latin word Opus, meaning “work” or “creation,” but stylized with an x instead of an s.

**Opux**: <a href="http://insoft.uk/action/?method=downlink&path=macos&file=xprime-installer-arm64.zip">Xprime 27 BUILD(20260514)</a></br>
### Requirements
AppleSilicon</br>
**macOS 26** or later</br>

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

>[!NOTE]
>In light of [HP Prime Development Tools](https://marketplace.visualstudio.com/items?itemName=AndreaBaccin.vscode-hpprime)￼ support, Xprime adopts the **.hpppl** **.hppplplus** and **.hpppl+** file types. This simplify development for those using either Visual Studio Code or Xprime.

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
