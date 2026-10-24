from hpprime import pixon,line;from fonts import Sans24,Sys10,Sys8
def glyph(p1,p2,x,y,p5,p6,p7):
 g=int(p5[1][p2]);v2=(g>>32)&255
 if g&0xFFFFFFFF==0:
  return v2;
 v3=p5[4];w=(g>>16)&255;h=(g>>24)&255;dX=(g>>40)&255;dY=((g>>48)&255)-256;x=x+dX;y=y+v3+dY;v10=g&65535;v11=(v10&7)*8;v10=v10>>3;v12=p5[0][v10];v12>>=v11
 while 1:
  for xx in range(w):
   if v11==64:
    v11=0;v10+=1;v12=p5[0][v10]
   if v12&1:
    if p7>1:
     line(p1,x+xx,y,x+xx+p7-1,y,p6)
    else:
     pixon(p1,x+xx,y,p6)
   v11+=1;v12>>=1
  y+=1;h-=1
  if h==0:
   break
 return v2+p7-1
def textout(p1,p2,x,y,p5,p6=0,p7=1,p8=0):
 for c in p2:
  if c=='\n':
   y+=p5[4];continue
  elif c=='\r':
   x=0;continue
  elif c=='\t':
   x+=((p5[1][32-p5[2]]>>32)&255)*4;continue
  n=ord(c)-p5[2]
  if n<0:
   continue
  x+=glyph(p1,n,x,y,p5,p6,p7);x+=p8
