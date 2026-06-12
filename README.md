<img src="assets/icon.png?raw=true" width="128" /></br>
## HP Prime Development Tools

### Xprime Code Editor
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

***Download link:*** [Xprime 26.5.x](http://insoft.uk/action/?method=downlink&path=macos&file=xprime_20260611.zip)</a></br>

### Requirements
Apple Silicon or intel</br>
**macOS 13.5** or later</br>
HP Prime Virtual Calculator</br>
HP Connectivity Kit (for calculator sync)</br>
[HP Prime Beta Software Downloads](https://updates.moravia-consulting.com/beta.html)

### Reveal Version Detail
In Xprime, you can reveal the full version number from the About window.
Hold down the **Option (⌥) key**, then **click and hold** on the About window to display the extended version format, combining the app version and build number — for example: **26.5.2.20260610**.

<img src="assets/screenshots/xprime.png?raw=true" width="756" />

### Automaticaly Text Expansion Table
|Pattern|Text Expansion|
|:-|:-|
|!=|≠|
|<>|≠|
|>=|≥|
|<=|≤|
|=>|▶|
|->|→|
|<-|←|
|\\pi|π|
|\|\||OR|
|&&|AND|
|!!|NOT|
|^^|XOR|
|{{|BEGIN|
|}}|END;|
|{*|FOR|
|[]|FROM|
|:>|TO|
|<:|DOWNTO|
|??|IF|
|?:|THEN|
|?!|ELSE|
|{?|WHILE|
|{}|WHILE 1 DO|
|{:|REPEAT|
|?}|UNTIL|
|::|CASE|
|*:|DEFAULT|
|\\*|EXPR|
|\\&|BITAND|
|\\\||BITOR|
|\\^|BITXOR|
|\\~|BITNOT|
|\\>|BITSR|
|\\<|BITSL|

>[!NOTE]
>The `EXPR`, `WHILE`, `REPEAT`, `UNTIL` and `WHILE 1 DO` have been changed.

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

Snippets & Stubs from HP Prime Development Tools are also included in Xprime Installer.

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
