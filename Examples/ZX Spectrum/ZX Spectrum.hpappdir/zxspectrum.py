from hpprime import pixon
def zx_addr(x,y):
 return(((y&0xC0)<<5)|((y&0x07)<<8)|((y&0x38)<<2)|(x>>3))
def attr_addr(x,y):
 return 0x1800+(y>>3)*32+(x>>3)
def render_scr(v1):
 try:
  with open(v1,"rb")as f:
   v1=bytearray(f.read())
 except OSError as e:
  return
 for y in range(192):
  for x in range(0,256,8):
   v2=zx_addr(x,y);v3=attr_addr(x,y);d=v1[v2];a=v1[v3];v7=(a>>6)&1;v4=a&7;v5=(a>>3)&7;v6=spectrum_color(v4,v7);v7=spectrum_color(v5,v7)
   for b in range(8):
    v8=7-b;v9=(d>>v8)&1;v10=v6 if v9 else v7;pixon(0,x+b+32,y+24,v10)
def spectrum_color(c,v2):
 v3=[0x000000,0x0000D7,0xD70000,0xD700D7,0x00D700,0x00D7D7,0xD7D700,0xD7D7D7];v4=[0x000000,0x0000FF,0xFF0000,0xFF00FF,0x00FF00,0x00FFFF,0xFFFF00,0xFFFFFF];return v4[c]if v2 else v3[c]
