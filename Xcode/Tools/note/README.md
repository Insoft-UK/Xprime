## NOTE for HP Prime
**Command Line Tool**

A command-line tool that converts .md and .ntf files into the HP Prime .hpnote format, preserving formatting such as bold and italic text, font sizes, and foreground and background colors.

>[!NOTE]
>A font size of 8 can be achieved using the control word `\fs0`. While this size is not accessible directly on the HP Prime calculator itself, it is supported when using the command-line tool.

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
`fsN` N = font size (N + 4) * 2
- `\fs7` → 22-point font (7 + 4) * 2 = 22
- `\fs0` → 8-point font (0 + 4) * 2 = 8

---

### Foreground (Text Color)
**NoteText**
- `\fg#7C00` — Red text  
- `\fg#FFFF` — Default text color  
- `\fg` — Reset to default

**RichText** Control Word Supported
- `\cfN` → N 0 Default 1-... Color Table  

### Background
**NoteText**
- `\bg#7C00` — Red background  
- `\bg#FFFF` — Default background  
- `\bg` — Reset to default

**RichText** Control Word Supported
- `\highlightN` → N 0 Default 1-... Color Table 

---

### Bullets
- `\li0` — No bullet  
- `\li1` — ●  
- `\li2` — 　○  
- `\li3` — 　　■

>[!NOTE]
>Markdown supports embedded NoteText Format commands to handle features it lacks, such as text alignment.
