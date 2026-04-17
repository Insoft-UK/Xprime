<img src="https://github.com/Insoft-UK/PrimePlus/blob/main/add-ons/grob/assets/Icon.png" style="width: 128px" />

## GROB
**Command Line Tool**
A utility for generating PPL code from an image file for use with the BLIT and BLIT_P functions on the HP Prime.

Download links: <a href="http://insoft.uk/action/?method=downlink&path=macos&file=grob-mac-universal.zip">macOS</a> | <a href="http://insoft.uk/action/?method=downlink&path=pc&file=grob-win-x86_64.zip">Windows</a> | <a href="http://insoft.uk/action/?method=downlink&path=linux&file=grob-linux-x86_64.zip">Linux</a>

`Usage: grob <input-file> [-o <output-file>] [-c <columns>] [-n <name>] [-g<1-9>] [-ppl]`

<table>
  <thead>
    <tr align="left">
      <th>Options</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>-o <output-file></td><td>Specify the filename for generated code</td>
    </tr>
    <tr>
      <td>-c or --columns</td><td>Number of columns</td>
    </tr>
    <tr>
      <td>-n or --name</td><td>Custom name</td>
    </tr>
    <tr>
      <td>-G<1-9></td><td>Graphic object G1-G9 to use if file is an image</td>
    </tr>
    <tr>
      <td>--pragma</td><td>Include \"#pragma mode( separator(.,;) integer(h64) )\" line</td>
    </tr>
    <tr>
      <td>--endian <le|be></td><td>Endianes le(default)</td>
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

<img width="64" height="64" src="https://github.com/Insoft-UK/PrimePlus/blob/main/add-ons/grob/assets/spectrum-8bit.png" >

```
grob spectrum-8bit.bmp -G1
```

> [!NOTE]
The only image file format currently supported by this utility tool is the Bitmap (BMP) format for Windows & Linux, with 1-bit, 4-bit, 8-bit, 16-bit, or 32-bit color depth.
PNG is only supported for macOS.

