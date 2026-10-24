from cas import*;from hpprime import*;from graphic import*;import grob;import glyth;bmp=[[0xFEDCBA9076543210],[16,1,4],[0x000000,0x0000BB,0xBB0000,0xBB00BB,0x00BB00,0x00BBBB,0xBBBB00,0xBBBBBB,0x000000,0x0000FF,0xFF0000,0xFF00FF,0x00FF00,0x00FFFF,0xFFFF00,0xFFFFFF]]
def apply_one_third_filter(p1,p2,p3):
 p2[0]=(p1[0]+p1[0]+p1[1])//3
 for i in range(1,p3-1):
  p2[i]=(p1[i-1]+p1[i]+p1[i+1])//3
 p2[p3-1]=(p1[p3-2]+p1[p3-1]+p1[p3-1])//3
def apply_one_ninth_filter(p1,p2,p3):
 for i in range(p3):
  s=0
  for j in(-1,0,1):
   v2=i+j
   if 0<=v2<p3:
    s+=p1[v2]
   else:
    s+=p1[i]
  p2[i]=s//3
def subpixels(p1,x,y,p4):
 v1=len(p4)*3;v2=bytearray(v1);v3=bytearray(v1);apply_one_third_filter(p4,v2,len(p4));apply_one_ninth_filter(v2,v3,len(p4))
 for i in range(0,v1,3):
  r=v3[i];g=v3[i+1];b=v3[i+2];v7=(0xff<<24)|(r<<16)|(g<<8)|b;v7=0xff00ffff;pixon(p1,x,y,v7);x+=1
def main()->Any:
 grob.image(0,0,0,bmp,20,240);fillrect(0,0,0,320,48,0xffffff,0xffffff);glyth.textout(0,"HP Prime micropython",4,0,glyth.Sans24,0,3);glyth.textout(0,"Python Example",4,24,glyth.Sys10,0x808080,2);glyth.textout(0,"Glyths & GROB",4,36,glyth.Sys8,0x808080)
 for y in range(32):
  v1=bytearray(320)
  for x in range(320):
   c=getpix(0,x,y)
   if c==0xff000000:
    v1[x]=0
   else:
    v1[x]=255
  subpixels(0,x,y,v1)
 try:
  while True:
   v3=get_key()
   if v3>0:
    if v3==4:
     break
    v4=0;v5=20;v6=20;v7=0;v8=40;v9=0;v10=60;v11=10;strblit2(v4,v5,v6,v10,v11,v7,v8,v9,v10,v11)
 except KeyboardInterrupt:
  pass
try:
 main()
except KeyboardInterrupt:
 pass
print("Program Terminated")
