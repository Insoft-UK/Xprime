from hpprime import pixon, line
from fonts import Sans24, Sys10, Sys8

def glyph(trgtG, ascii, x, y, font, color, weight):
  g = int(font[1][ascii])
  xAdvance = (g >> 32) & 255
  if g & 0xFFFFFFFF == 0:
    return xAdvance;
  
  yAdvance = font[4]

  w = (g >> 16) & 255
  h = (g >> 24) & 255
 
  dX = (g >> 40) & 255
  dY = ((g >> 48) & 255) - 256
 
  x = x + dX
  y = y + yAdvance + dY

  offset = g & 65535
  bitPosition = (offset & 7) * 8
  offset = offset >> 3
  bits = font[0][offset]
  bits >>= bitPosition
  
  while 1:
    for xx in range(w):
      if bitPosition == 64:
        bitPosition = 0
        offset += 1
        bits = font[0][offset]
     
      if bits & 1:
        if weight > 1:
          line(trgtG, x + xx, y, x + xx + weight - 1, y, color)
        else:
          pixon(trgtG, x + xx, y, color)
      
      bitPosition += 1
      bits >>= 1
   
    y += 1
    h -= 1
    if h == 0:
      break
  
  return xAdvance + weight - 1
    
def textout(trgtG, text, x, y, font = Sans24, color = 0, weight = 1, kerning = 0):
  for c in text:
    if c == '\n':
      y += font[4]
      continue
    elif c == '\r':
      x = 0
      continue
    elif c == '\t':
      x += ((font[1][32 - font[2]] >> 32) & 255) * 4
      continue

    n = ord(c) - font[2]
    if n < 0:
      continue
    x += glyph(trgtG, n, x, y, font, color, weight)
    x += kerning

