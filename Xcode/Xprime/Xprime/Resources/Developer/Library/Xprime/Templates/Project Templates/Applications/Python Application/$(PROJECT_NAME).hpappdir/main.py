from sys import argv
from hpprime import *
from graphic import *

def get_key():
    if keyboard():
        return eval('GETKEY()')
    return 0

# Main function
def main() -> Any:
  clear_screen(0)
  try:
    while True:
      key = get_key()
      if key > 0:
        if key == 4: # ESC
          break
      
  except KeyboardInterrupt:
    pass

  clear_screen()

try:
    main()
except KeyboardInterrupt:
    clear_screen()
