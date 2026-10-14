from cas import*;from graphic import*;import hpprime as m1;import zxspectrum as m2
def main()->Any:
 m1.fillrect(0,0,0,320,240,0,0);m2.render_scr("47.scr")
 try:
  while True:
   v1=get_key()
   if v1>0:
    if v1==4:
     break
    m2.render_scr(str(int(v1))+".scr")
 except KeyboardInterrupt:
  pass
try:
 main()
except KeyboardInterrupt:
 pass
print("Program Terminated")
