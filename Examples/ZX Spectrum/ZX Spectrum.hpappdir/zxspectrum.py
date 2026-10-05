from hpprime import pixon

def zx_addr(x, y):
    return (((y & 0xC0) << 5)
          | ((y & 0x07) << 8)
          | ((y & 0x38) << 2)
          | (x >> 3))

def attr_addr(x, y):
    return 0x1800 + (y >> 3) * 32 + (x >> 3)

def render_scr(filename):
  try:
    with open(filename, "rb") as f:
        data = bytearray(f.read())
        
  except OSError as e:
    return

  for y in range(192):
    for x in range(0, 256, 8):

      pix_i = zx_addr(x, y)
      attr_i = attr_addr(x, y)

      d = data[pix_i]
      a = data[attr_i]

      bright = (a >> 6) & 1

      ink = a & 7
      paper = (a >> 3) & 7

      ink_color = spectrum_color(ink, bright)
      paper_color = spectrum_color(paper, bright)

      for b in range(8):
        bit = 7 - b
        pixel = (d >> bit) & 1

        color = ink_color if pixel else paper_color
        pixon(0, x + b + 32, y + 24, color)
                
def spectrum_color(c, bright):
    normal = [
        0x000000, 0x0000D7, 0xD70000, 0xD700D7,
        0x00D700, 0x00D7D7, 0xD7D700, 0xD7D7D7
    ]

    bright_pal = [
        0x000000, 0x0000FF, 0xFF0000, 0xFF00FF,
        0x00FF00, 0x00FFFF, 0xFFFF00, 0xFFFFFF
    ]

    return bright_pal[c] if bright else normal[c]