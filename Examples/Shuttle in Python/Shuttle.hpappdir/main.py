from cas import *
from hpprime import *
from graphic import *
from sys import argv
import shuttle
# Main function
def main() -> Any:
 fillrect(0, 0, 0, 320, 240, 0, 0)
 shuttle.draw()
 try:
  while True:
   k = get_key()
   if k > 0:
    if k == 4: # ESC
     break
 except KeyboardInterrupt:
  pass
try:
 main()
except KeyboardInterrupt:
 pass
print("Program Terminated")