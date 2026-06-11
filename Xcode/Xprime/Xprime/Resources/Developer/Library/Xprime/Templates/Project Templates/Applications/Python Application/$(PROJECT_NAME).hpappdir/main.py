from cas import *
from hpprime import *
from graphic import *

# Main function
def main() -> Any:
  fillrect(0,0,0,320,240,0,0)
  
  try:
    while True:
      key = get_key()
      if key > 0:
        if key == 4: # ESC
          break
      
  except KeyboardInterrupt:
    pass

try:
  main()
except KeyboardInterrupt:
  pass
  
print("Program Terminated")
