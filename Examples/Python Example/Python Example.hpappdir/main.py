from cas import*;from hpprime import*;from graphic import*;import grob;import glyth;bmp=[[0xFEDCBA9076543210],[16,1,4],[0x000000,0x0000BB,0xBB0000,0xBB00BB,0x00BB00,0x00BBBB,0xBBBB00,0xBBBBBB,0x000000,0x0000FF,0xFF0000,0xFF00FF,0x00FF00,0x00FFFF,0xFFFF00,0xFFFFFF]]
def apply_one_third_filter(v1,v2,v3):
 v2[0]=(v1[0]+v1[0]+v1[1])//3
 for i in range(1,v3-1):
  v2[i]=(v1[i-1]+v1[i]+v1[i+1])//3
 v2[v3-1]=(v1[v3-2]+v1[v3-1]+v1[v3-1])//3
def apply_one_ninth_filter(v1,v2,v3):
 for i in range(v3):
  s=0
  for j in(-1,0,1):
   v5=i+j
   if 0<=v5<v3:
    s+=v1[v5]
   else:
    s+=v1[i]
  v2[i]=s//3
def subpixels(v1,x,y,v4):
 v5=len(v4)*3;v6=bytearray(v5);v7=bytearray(v5);apply_one_third_filter(v4,v6,len(v4));apply_one_ninth_filter(v6,v7,len(v4))
 for i in range(0,v5,3):
  r=v7[i];g=v7[i+1];b=v7[i+2];v11=(0xff<<24)|(r<<16)|(g<<8)|b;v11=0xff00ffff;pixon(v1,x,y,v11);x+=1
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
