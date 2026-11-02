<img src="assets/Icon.png" style="width: 128px" />

## GROB
**Command Line Tool**
A utility for generating HP PPL code from an image file for use with the BLIT and BLIT_P functions on the HP Prime.

`Usage: grob <input-file> [-o <output-file>] [-G<1-9>] [--language <language>]`

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

> [!NOTE]
This utility currently supports three image formats: Bitmap (BMP), with 1-bit, 4-bit, 8-bit, 16-bit, and 32-bit colour depths; Portable Bitmap (PBM), with 1-bit colour depth; and PNG, with 8-bit and 32-bit colour depths.

