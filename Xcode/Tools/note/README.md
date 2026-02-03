## NOTE for HP Prime
**Command Line Tool**

A command-line tool that converts .md and .ntf files into the HP Prime .hpnote format, preserving formatting such as bold and italic text, font sizes, and foreground and background colors.

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
      <td>-c or --compress</td><td>Specify if the CC note should be included</td>
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

Download links: <a href="http://insoft.uk/action/?method=downlink&path=macos&file=note_macOS.zip">macOS</a> | <a href="http://insoft.uk/action/?method=downlink&path=pc&file=note_win_x86_64.zip">Windows</a> | <a href="http://insoft.uk/action/?method=downlink&path=linux&file=note_linux_x86_64.zip">Linux</a>

>[!NOTE]
>This <a href="http://insoft.uk/action/?method=downlink&path=macos&file=note.pkg">package installer</a> upgrades the command-line tool for Xprime version 26.1 and later.

### Supported File Types
|Type|Description|Format|
|:-|:-|:-|
|.note|HP Prime note plain text|UTF16le|
|.note|NoteText Format|UTF8|
|.ntf|NoteText Format|UTF8|
|.rtf|RichText Format|UTF8|
|.md|Markdown Language|UTF8|
|.hpnote|HP Prime note (Plain Text without BOM)|UTF16le|
|.hpappnote|HP Prime note (Plain Text without BOM)|UTF16le|

## Text Formatting Reference

>[!WARNING]
>To support future RTF compatibility and RTF-to-NTF conversion, several changes have been made to NTF. Toggle-style formatting replaced with explicit state-setting control words, matching RTF semantics (for example, `\b` treated as shorthand for `\b1`). Additionally, `\u` replaced with `\ul` to avoid conflicts with RTF Unicode control words.

### Bold
- `\b0` — Disable bold  
- `\b1` or `\b ` — Enable bold

### Italic
- `\i0` — Disable italic  
- `\i1` or `\i ` — Enable italic

### Underline
- `\ul0` — Disable underline  
- `\ul1` or `ul ` — Enable underline 

### Strikethrough
- `\srike0` — Disable strikethrough  
- `\strike1` or `\strike ` — Enable strikethrough 

---

### Text Alignment
- `\ql` — Left-aligned text (default)  
- `\qc` — Center-aligned text  
- `\qr` — Right-aligned text  

---

### Font Size
`fsN` N = font size
- `\fs22` → 22-point font
- `\fs8` → 8-point font

In RichText, the font size values are effectively doubled compared to what you might expect. That means:

-	If a font is specified as \fs24 in RichText, it actually renders at 12 points, because the value in the RTF control word (\fsN) is twice the real point size.
-	This doubling is part of the RTF specification: the \fsN value is always measured in half-points, not full points.

So whenever you read a font size from RichText, you need to divide by 2 to get the actual point size, and when writing a font size, you multiply by 2 to encode it.

>[!NOTE]
>Unlike RichText, NoteText font sizes are specified in actual points, so no doubling is applied.

---

### Foreground (Text Color)
- `\cfN` → N 0 Default 1-... Color Table  

>[!IMPORTANT]
>When specifying a hex value, e.g., `\cf#7FFF`, it is interpreted as an explicit RGB555 color rather than as an index into the default color table.

### Background
- `\cbN` → N 0 Default 1-... Color Table 
- `\highlightN` → N 0 Default 1-... Color Table

>[!IMPORTANT]
>When specifying a hex value, e.g., `\cb#7FFF`, it is interpreted as an explicit RGB555 color rather than as an index into the default color table.

---

### Bullets
- `\li0` — No bullet  
- `\li1` — ●  
- `\li2` — 　○  
- `\li3` — 　　■

---

### Picture
`{\pict\picwN\pichN\endianN 0123456789ABCDEEF...}`

-	`\picwN` – picture width (N)
-	`\pichN` — picture height (N)
- `\endianN` – byte order
  - 0 = big-endian (default)
  - 1 = little-endian
- `\pixelwN` – pixel width
  - 1 = Very Narrow 1:3
  - 2 = Narrow      2:3
  - 3 = Square      1:1
- `\keycolorN` – color treated as transparent
- `\alignN` – picture alignment
  - 0 = Left
  - 1 = Center
  - 2 = Right
-	`0123456789ABCDEEF...` — Raw picture data. Any characters outside 0–9 and A–F are treated as noise and ignored.

`\pictN`
- N — Picture table index (0–…)

>[!WARNING]
>Picture support is still preliminary and not fully finalized. Behavior and implementation may change in future updates.

---

>[!NOTE]
>Markdown supports embedded NoteText Format control words to handle features it lacks, such as text alignment.
