import hpprime as hp

with open("drawing.dat") as f:
  data = [int(x) for x in f.read().split(",")]

def getColor(pen):
  if pen == 1:
    return 0xffff00
  if pen == 2:
    return 0x00ffff
  if pen == 3:
    return 0x00ff00
  if pen == 4:
    return 0xff0000
  if pen == 5:
    return 0x0000ff
  if pen == 6:
    return 0xffffff
  if pen == 7:
    return 0xff00ff
    
  return 0x000000

def getPoint(i):
  return [data[i] / 9.375, data[i+1] / 9.375]
  
def draw():
  i = 0
  
  while i < len(data):
    n = data[i]
    
    if n == 0:
      break
      
    i += 1
    
    if n < 0:
      n = -n
      
      if i >= len(data):
        break
        
      color = getColor(data[i])
      i += 1
      
    if n > 0:
      pt1 = getPoint(i)
      i += 2
      n -= 1
      
      while n > 0:
        pt2 = getPoint(i)
        i += 2
        n -= 1
        hp.line(0, pt1[0], pt1[1], pt2[0], pt2[1], color)
        pt1 = pt2
    
 
    
