## NOTE for HP Prime

**Command Line Tool**
A command-line tool that converts .md and .ntf files into the HP Prime .hpnote format, preserving formatting such as bold and italic text, font sizes, and foreground and background colors.

<img src="assets/screenshots/screenshot_1.png?raw=true" width="160" /> <img src="assets/screenshots/screenshot_2.png?raw=true" width="160" /> <img src="assets/screenshots/screenshot_3.png?raw=true" width="160" /> <img src="assets/screenshots/screenshot_4.png?raw=true" width="160" /> <img src="assets/screenshots/screenshot_5.png?raw=true" width="160" /> <img src="assets/screenshots/screenshot_6.png?raw=true" width="160" />

Download links: [macOS Apple silicon](http://insoft.uk/action/?method=downlink&path=macos&file=hpnote-arm64.zip) | [macOS Intel](http://insoft.uk/action/?method=downlink&path=macos&file=hpnote-x86_64.zip) | [Windows](http://insoft.uk/action/?method=downlink&path=pc&file=hpnote-win-x86_64.zip) | [Linux](http://insoft.uk/action/?method=downlink&path=linux&file=hpnote-linux-x86_64.zip)

>[!IMPORTANT]
>The NOTE tool currently dosn't support formulars.

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
      <td>--plain-fallback</td><td>Includes the plain-text carbon copy fallback used for recovery</br >if the formatted content is unreadable.</td>
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
|Type|Description|
|:-|:-|
|.note|Note source text
|.rtf|RichText Format
|.md|Markdown Language
|.hpnote|Standalone note binary
|.hpappnote|App note binary

## Note source text formatting reference

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
