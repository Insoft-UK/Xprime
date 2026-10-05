from cas import *
from graphic import *
import hpprime as hp
import zxspectrum as zx

# Main function
def main() -> Any:
  hp.fillrect(0,0,0,320,240,0,0)
  zx.render_scr("47.scr")
  
  try:
    while True:
      key = get_key()
      if key > 0:
        if key == 4: # ESC
          break
          
        zx.render_scr(str(int(key))+".scr")
      
  except KeyboardInterrupt:
    pass

try:
  main()
except KeyboardInterrupt:
  pass
  
print("Program Terminated")
