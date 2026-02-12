<img src="https://github.com/Insoft-UK/Xprime/blob/main/assets/icon.png?raw=true" width="128" />

## Xprime Code Editor for macOS
- Edit your PPL or <a href="https://github.com/Insoft-UK/PrimePlus">**PPL+**</a> code for the HP Prime.
- Package your application for deployment for the HP Prime or testing on the Virtual Calculator.
- Export a G1 .hpprgm file for use on a real HP Prime or the Virtual Calculator.
- Compress code to fit more programs on your HP Prime

### Hidden Version Detail
In Xprime, you can reveal the full version number from the About window.
Hold down the **Option (⌥) key**, then **click and hold** on the About window to display the extended version format, combining the app version and build number — for example: **26.1.20260131**.

<img src="https://github.com/Insoft-UK/Xprime/blob/main/assets/screenshots/xprime.png?raw=true" width="756" />

### Supported File Types
|Type|Description|Format|
|:-|:-|:-|
|.ppl|HP Prime Programming Language source file|UTF8|
|.prgm|HP Prime program source code|UTF16le|
|.app|HP Prime application source code (PPL)|UTF16le|
|.note|HP Prime note plain text|UTF16le|
|.note|*HP Prime note text format|UTF8|
|.md|Markdown Language|UTF8|
|.hpnote|HP Prime note (Plain Text without BOM)|UTF16le|
|.hpappnote|HP Prime note (Plain Text without BOM)|UTF16le|
|.hpprgm|HP Prime program (exported/packaged)|Binary|
|.hpappprgm|HP Prime application (exported/packaged)|Binary|
|.prgm+|HP Prime PRGM+ extended program source code|UTF8|
|.ppl+|HP Prime PPL+ extended program source code|UTF8|

*Ritch Text like format file for notes.

Typical File Structure for an HP Prime **Application**

```
MyApp/
├── MyApp.hpappdir/
│   │── icon.png
│   │── MyApp.hpapp
│   │── MyApp.hpappnote
│   └── MyApp.hpappprgm
│── MyApp.xprimeproj
│── MyApp.prgm+ or main.prgm+
│── README.ntf or README.md *info.ntf
│── info.ntf or info.md
└── other.ppl+
```

>[!IMPORTANT]
>The README.ntf/README.md files will be renamed to info.ntf/info.md in a future update.

Typical File Structure for an HP Prime **Program**

```
MyProgram/
│── MyProgram.xprimeproj
│── MyProgram.prgm+ or main.prgm+
└── other.ppl+
```

>[!NOTE]
>Use the **.ppl+** extension for extended program source code and **.prgm+** for the main application or program source code.
>
>For standard PPL source code, use **.ppl** and never **.prgm**, as **.prgm** is reserved for the main application or program source file in projects that do not use extended PPL.
