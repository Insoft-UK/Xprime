import hpprime as hp
with open("drawing.dat") as f:
 d = [int(x) for x in f.read().split(",")]
def getColor(p):
 if p == 1:
  return 0xffff00
 if p == 2:
  return 0x00ffff
 if p == 3:
  return 0x00ff00
 if p == 4:
  return 0xff0000
 if p == 5:
  return 0x0000ff
 if p == 6:
  return 0xffffff
 if p == 7:
  return 0xff00ff
 return 0x000000
def getPoint(i):
 return [d[i] / 9.375, d[i+1] / 9.375]
def draw():
 i = 0
 while i < len(d):
  n = d[i]
  if n == 0:
   break
  i += 1
  if n < 0:
   n = -n
   if i >= len(d):
    break
   c = getColor(d[i])
   i += 1
  if n > 0:
   pt1 = getPoint(i)
   i += 2
   n -= 1
   while n > 0:
    pt2 = getPoint(i)
    i += 2
    n -= 1
    hp.line(0, pt1[0], pt1[1], pt2[0], pt2[1], c)
    pt1 = pt2