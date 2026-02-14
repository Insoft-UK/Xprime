## NOTE for HP Prime
**Command Line Tool**
A command-line tool that converts .md and .ntf files into the HP Prime .hpnote format, preserving formatting such as bold and italic text, font sizes, and foreground and background colors.

<img src="assets/screenshots/screenshot_1.png?raw=true" width="160" /> <img src="assets/screenshots/screenshot_2.png?raw=true" width="160" /> <img src="assets/screenshots/screenshot_3.png?raw=true" width="160" /> <img src="assets/screenshots/screenshot_4.png?raw=true" width="160" /> <img src="assets/screenshots/screenshot_5.png?raw=true" width="160" /> <img src="assets/screenshots/screenshot_6.png?raw=true" width="160" />

**RELEASE** v1.0.0.20260214</br>
Download links: <a href="http://insoft.uk/action/?method=downlink&path=macos&file=note-mac-universal.zip">macOS</a> | <a href="http://insoft.uk/action/?method=downlink&path=pc&file=note-win-x86_64.zip">Windows</a> | <a href="http://insoft.uk/action/?method=downlink&path=linux&file=note-linux-x86_64.zip">Linux</a>

>[!NOTE]
>This <a href="http://insoft.uk/action/?method=downlink&path=macos&file=note-universal.pkg">package installer</a> upgrades the command-line tool for Xprime version 26.1 and later.

`Usage: note <input-file> [-o <output-file>]`

<table>
  <thead>
    <tr align="left">
      <th>Options</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>-o <output-file></td><td>Specify the filename for generated note</td>
    </tr>
    <tr>
      <td>--cc</td><td>Includes the plain-text carbon copy fallback used for recovery</br >if the formatted content is unreadable.</td>
    </tr>
    <tr>
      <td>-v or --verbose</td><td>Display detailed processing information</td>
    </tr>
    <tr>
      <td colspan="2"><b>Additional Commands</b></td>
    </tr>
    <tr>
      <td>--version</td><td>Displays the version information</td>
    </tr>
    <tr>
      <td>--build</td><td>Displays the build information</td>
    </tr>
    <tr>
      <td>--help</td><td>Show this help message</td>
    </tr>
  </tbody>
</table>

### Supported File Types
|Type|Description|Format|
|:-|:-|:-|
|.note|HP Prime note plain text|UTF16le|
|.note|NoteText Format|UTF8|
|.ntf|NoteText Format|UTF8|
|.rtf|RichText Format|UTF8|
|.md|Markdown Language|UTF8|
|.hpnote|HP Prime note|UTF16le|
|.hpappnote|HP Prime note|UTF16le|

## Text Formatting Reference

>[!WARNING]
>To support future RTF compatibility and RTF-to-NTF conversion, several changes have been made to NTF. Toggle-style formatting replaced with explicit state-setting control words, matching RTF semantics (for example, `\b` treated as shorthand for `\b1`). Additionally, `\u` replaced with `\ul` to avoid conflicts with RTF Unicode control words.

### Bold
- `\b0` – disable bold  
- `\b1` or `\b ` – enable bold

### Italic
- `\i0` – Disable italic  
- `\i1` or `\i ` – enable italic

### Underline
- `\ul0` – disable underline  
- `\ul1` or `ul ` – enable underline 

### Strikethrough
- `\srike0` – disable strikethrough  
- `\strike1` or `\strike ` — enable strikethrough

### Superscript
- `\super0` – disable superscript  
- `\super1` or `\super ` — enable superscript

### Subscript
- `\sub0` – disable subscript  
- `\sub1` or `\sub ` — enable subscript 

---

### Text Alignment
- `\ql` – left-aligned text (default)  
- `\qc` – center-aligned text  
- `\qr` – right-aligned text  

---

### Font Size
`fsN` N = font size
- `\fs22` – 22-point font
- `\fs8` – 8-point font
- `\fs ` – 14-point font (default)

In RichText, the font size values are effectively doubled compared to what you might expect. That means:

-	If a font is specified as \fs24 in RichText, it actually renders at 12 points, because the value in the RTF control word (\fsN) is twice the real point size.
-	This doubling is part of the RTF specification: the \fsN value is always measured in half-points, not full points.

So whenever you read a font size from RichText, you need to divide by 2 to get the actual point size, and when writing a font size, you multiply by 2 to encode it.

>[!NOTE]
>Unlike RichText, NoteText font sizes are specified in actual points, so no doubling is applied.

---

### Foreground (Text Color)
- `\cfN` – N 0 default 1-... Color Table
- `\cf0` or `\cf ` – default color (black/white) depending on theme

>[!IMPORTANT]
>When specifying a hex value, e.g., `\cf#7FFF`, it is interpreted as an explicit RGB555 color rather than as an index into the default color table.

### Background
- `\cbN` → N 0 default 1-... Color Table
- `\cb0` or `\cb ` – default color (transparent)
- `\highlightN` – N 0 default 1-... Color Table

>[!IMPORTANT]
>When specifying a hex value, e.g., `\cb#7FFF`, it is interpreted as an explicit RGB555 color rather than as an index into the default color table.

---

### Bullets
- `\li0` – No bullet  
- `\li1` – ●  
- `\li2` – 　○  
- `\li3` – 　　▷

---

### Picture
`{\pict\picwN\pichN\endianN 0123456789ABCDEEF...}`

-	`\picwN` – picture width (N)
-	`\pichN` — picture height (N)
- `\endianN` – byte order
  - 0 = big-endian (default)
  - 1 = little-endian
- `\pixelwN` – pixel width
  - 1 = very narrow 1:3
  - 2 = narrow      2:3
  - 3 = square      1:1 (default)
- `\keycolorN` – color treated as transparent
- `\alignN` – picture alignment
  - 0 = Left
  - 1 = Center
  - 2 = Right
-	`0123456789ABCDEEF...` — Raw picture data. Any characters outside 0–9 and A–F are treated as noise and ignored.

>[!NOTE]
>The maximum supported picture width depends on pixel shape: 106 for very narrow pixels, 53 for narrow pixels, and 35 for square pixels.

`\pictN`
- N — Picture table index (0–…)

Reuse a previously added picture from the picture table.

---

>[!NOTE]
>Markdown supports embedded NoteText Format control words to handle features it lacks, such as text alignment.
