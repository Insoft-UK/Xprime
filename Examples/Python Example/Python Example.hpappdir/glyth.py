from hpprime import pixon,line;from fonts import Sans24,Sys10,Sys8
def glyph(v1,v2,x,y,v5,v6,v7):
 g=int(v5[1][v2]);v9=(g>>32)&255
 if g&0xFFFFFFFF==0:
  return v9;
 v10=v5[4];w=(g>>16)&255;h=(g>>24)&255;dX=(g>>40)&255;dY=((g>>48)&255)-256;x=x+dX;y=y+v10+dY;v17=g&65535;v18=(v17&7)*8;v17=v17>>3;v19=v5[0][v17];v19>>=v18
 while 1:
  for xx in range(w):
   if v18==64:
    v18=0;v17+=1;v19=v5[0][v17]
   if v19&1:
    if v7>1:
     line(v1,x+xx,y,x+xx+v7-1,y,v6)
    else:
     pixon(v1,x+xx,y,v6)
   v18+=1;v19>>=1
  y+=1;h-=1
  if h==0:
   break
 return v9+v7-1
def textout(v1,v2,x,y,v5,v6=0,v7=1,v8=0):
 for c in v2:
  if c=='\n':
   y+=v5[4];continue
  elif c=='\r':
   x=0;continue
  elif c=='\t':
   x+=((v5[1][32-v5[2]]>>32)&255)*4;continue
  n=ord(c)-v5[2]
  if n<0:
   continue
  x+=glyph(v1,n,x,y,v5,v6,v7);x+=v8
