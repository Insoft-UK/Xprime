from cas import*;from hpprime import*;from graphic import*;from sys import argv;import shuttle as m1
def main()->Any:
 fillrect(0,0,0,320,240,0,0);m1.draw()
 try:
  while True:
   v1=get_key()
   if v1>0:
    if v1==4:
     break
 except KeyboardInterrupt:
  pass
try:
 main()
except KeyboardInterrupt:
 pass
print("Program Terminated")
