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

Download links: <a href="http://insoft.uk/action/?method=downlink&path=macos&file=note.zip">macOS</a> | <a href="http://insoft.uk/action/?method=downlink&path=pc&file=note.exe.zip">Windows

>[!NOTE]
>This <a href="http://insoft.uk/action/?method=downlink&path=macos&file=note.pkg">package installer</a> upgrades the command-line tool for Xprime version 26.1 and later.

### Supported File Types
|Type|Description|Format|
|:-|:-|:-|
|.note|HP Prime note plain text|UTF16le|
|.note|NoteText Format|UTF8|
|.ntf|NoteText Format|UTF8|
|.md|Markdown Language|UTF8|
|.hpnote|HP Prime note (Plain Text without BOM)|UTF16le|
|.hpappnote|HP Prime note (Plain Text without BOM)|UTF16le|

# Text Formatting Reference

## Bold
- `\b0` — Disable bold  
- `\b1` — Enable bold  
- `\b` — Toggle bold on/off  

## Italic
- `\i0` — Disable italic  
- `\i1` — Enable italic  
- `\i` — Toggle italic on/off  

## Underline
- `\u0` — Disable underline  
- `\u1` — Enable underline  
- `\u` — Toggle underline on/off  

## Strikethrough
- `\s0` — Disable strikethrough  
- `\s1` — Enable strikethrough  
- `\s` — Toggle strikethrough on/off  

---

## Text Alignment
- `\a0` — Left-aligned text (default)  
- `\a1` — Center-aligned text  
- `\a2` — Right-aligned text  

---

## Font Size
- `\fs7` — Font size 22  
- `\fs` — Default font size (14)  

---

## Colors

### Foreground (Text Color)
- `\fg#7C00` — Red text  
- `\fg#FFFF` — Default text color  
- `\fg` — Reset to default  

### Background
- `\bg#7C00` — Red background  
- `\bg#FFFF` — Default background  
- `\bg` — Reset to default  

---

## Bullets
- `\l0` — No bullet  
- `\l1` — ●  
- `\l2` — ○  
- `\l3` — ▶  
- `\l` — Toggle between: none, ●, ○, ▶

>[!NOTE]
>Markdown supports embedded NoteText Format commands to handle features it lacks, such as text alignment.
