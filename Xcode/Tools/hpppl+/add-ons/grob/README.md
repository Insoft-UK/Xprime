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

For 1-bit, 4-bit, and 8-bit GROB images.<br />
for HP PPL [GROB_P](GROB_P.hpppl)
```
#PYTHON GROB_P(trgtG, dx, dy, img, scaleX, scaleY)
from sys import argv
from hpprime import *

trgtG = int(argv[0][1:])
dx = int(argv[1])
dy = int(argv[2])
img = eval(argv[3])
scaleX = int(argv[4])
scaleY = int(argv[5])

w = int(img[1][0]); h = int(img[1][1]); bpp = int(img[1][2])
m = (1 << bpp) - 1; s = 64 / bpp
x = 0; y = 0

size = len(img[0])
for i in range(size):
  d = int(img[0][i])
  for j in range(64 / bpp):
    c = img[2][d & m]
    if scaleX == 1 and scaleY == 1:
      pixon(trgtG, x+dx, y+dy, c),0,0
    elif scaleX == 1 and scaleY > 1:
      line(trgtG, x+dx, y+dy, x+dx, y+dy+scaleY - 1, c)
    elif scaleX > 1 and scaleY == 1:
      line(trgtG, x+dx, y+dy, x+dx+scaleX-1, y+dy, c)
    else:
      fillrect(trgtG, x+dx, y+dy, scaleX, scaleY, c, c)
    d = d >> bpp
    x = x + scaleX
    if x == w * scaleX:
      x = 0
      y = y + scaleY
#END
```
for Python [grob](grob.py)
```
from hpprime import pixon, line, fillrect

def grob(trgtG, dx, dy, img, scaleX, scaleY):
  w = int(img[1][0]); h = int(img[1][1]); bpp = int(img[1][2])
  m = (1 << bpp) - 1; s = 64 / bpp
  x = 0; y = 0

  size = len(img[0])
  for i in range(size):
    d = int(img[0][i])
    for j in range(64 / bpp):
      c = img[2][d & m]
      if scaleX == 1 and scaleY == 1:
        pixon(trgtG, x+dx, y+dy, c),0,0
      elif scaleX == 1 and scaleY > 1:
        line(trgtG, x+dx, y+dy, x+dx, y+dy+scaleY - 1, c)
      elif scaleX > 1 and scaleY == 1:
        line(trgtG, x+dx, y+dy, x+dx+scaleX-1, y+dy, c)
      else:
        fillrect(trgtG, x+dx, y+dy, scaleX, scaleY, c, c)
      d = d >> bpp
      x = x + scaleX
      if x == w * scaleX:
        x = 0
        y = y + scaleY
```

> [!NOTE]
This utility currently supports three image formats: Bitmap (BMP), with 1-bit, 4-bit, 8-bit, 16-bit, and 32-bit colour depths; Portable Bitmap (PBM), with 1-bit colour depth; and PNG, with 8-bit and 32-bit colour depths.

