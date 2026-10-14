import hpprime as hp
with open("drawing.dat")as f:
 data=[int(x)for x in f.read().split(",")]
def getColor(v1):
 if v1==1:
  return 0xffff00
 if v1==2:
  return 0x00ffff
 if v1==3:
  return 0x00ff00
 if v1==4:
  return 0xff0000
 if v1==5:
  return 0x0000ff
 if v1==6:
  return 0xffffff
 if v1==7:
  return 0xff00ff
 return 0x000000
def getPoint(i):
 return[data[i]/9.375,data[i+1]/9.375]
def draw():
 i=0
 while i<len(data):
  n=data[i]
  if n==0:
   break
  i+=1
  if n<0:
   n= -n
   if i>=len(data):
    break
   v4=getColor(data[i]);i+=1
  if n>0:
   v5=getPoint(i);i+=2;n-=1
   while n>0:
    v6=getPoint(i);i+=2;n-=1;hp.line(0,v5[0],v5[1],v6[0],v6[1],v4);v5=v6
