from hpprime import pixon, line, fillrect

def image(trgtG, dx, dy, img, scaleX, scaleY):
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