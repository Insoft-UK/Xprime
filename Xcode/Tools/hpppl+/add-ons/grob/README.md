<img src="assets/Icon.png" style="width: 128px" />

## GROB
**Command Line Tool**
A utility for generating HP PPL code from an image file for use with the BLIT and BLIT_P functions on the HP Prime.

`Usage: grob <input-file> [-o <output-file>] [-G&lt;1-9&gt;] [--language &lt;language&gt;]`

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
      <td>-G&lt;1-9&gt;</td><td>Graphic object G1-G9 to for DIMGROB_P</td>
    </tr>
    <tr>
      <td>-l --language &lt;language&gt;</td><td>Specify the output language (ppl or python).</td>
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

<img width="64" height="64" src="assets/spectrum-8bit.png" >

```
grob spectrum-8bit.bmp -G1
```

> [!NOTE]
The only image file format currently supported by this utility tool is the Bitmap (BMP) format for Windows & Linux, with 1-bit, 4-bit, 8-bit, 16-bit, or 32-bit color depth.
PNG is only supported for macOS.

