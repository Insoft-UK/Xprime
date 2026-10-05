from cas import *
from hpprime import *
from graphic import *

import grob
import glyth

bmp = [
    [0xFEDCBA9076543210],
    [16, 1, 4],
    [
        0x000000, 0x0000BB, 0xBB0000, 0xBB00BB,
        0x00BB00, 0x00BBBB, 0xBBBB00, 0xBBBBBB,
        0x000000, 0x0000FF, 0xFF0000, 0xFF00FF,
        0x00FF00, 0x00FFFF, 0xFFFF00, 0xFFFFFF
    ]
]

def apply_one_third_filter(input_data, output_data, width):
  # Handle the first pixel separately
  output_data[0] = (input_data[0] +
                    input_data[0] +
                    input_data[1]) // 3

  # Process middle pixels
  for i in range(1, width - 1):
    output_data[i] = (input_data[i - 1] +
                      input_data[i] +
                      input_data[i + 1]) // 3

  # Handle the last pixel separately
  output_data[width - 1] = (input_data[width - 2] +
                            input_data[width - 1] +
                            input_data[width - 1]) // 3
                              
                              
def apply_one_ninth_filter(input_data, output_data, width):
  for i in range(width):
    s = 0

    for j in (-1, 0, 1):
      idx = i + j

      if 0 <= idx < width:
        s += input_data[idx]
      else:
        s += input_data[i]  # replicate borders

    output_data[i] = s // 3
    
def subpixels(trg, x, y, inp):
  width = len(inp) * 3
  
  filteredOneThird = bytearray(width)
  filteredOneNinth = bytearray(width)
  
  # 1/3 Filtering
  apply_one_third_filter(inp, filteredOneThird, len(inp))
  
  # 1/9 Filtering
  apply_one_ninth_filter(filteredOneThird, filteredOneNinth, len(inp))
  
  for i in range(0, width, 3):
    r = filteredOneNinth[i]
    g = filteredOneNinth[i + 1]
    b = filteredOneNinth[i + 2]
    
    color = (0xff << 24) | (r << 16) | (g<< 8) | b
    color = 0xff00ffff
    pixon(trg, x, y, color)
    x += 1
        
# Main function
def main() -> Any:
  grob.image(0,0,0,bmp,20,240)
  fillrect(0, 0, 0, 320, 48, 0xffffff,0xffffff)

  glyth.textout(0, "HP Prime micropython", 4, 0, glyth.Sans24, 0, 3)
  glyth.textout(0, "Python Example", 4, 24, glyth.Sys10, 0x808080, 2)
  glyth.textout(0, "Glyths & GROB", 4, 36, glyth.Sys8, 0x808080)
    
  
  for y in range(32):
    inp = bytearray(320)
    for x in range(320):
      c = getpix(0, x, y)
      if c == 0xff000000:
        inp[x] = 0
      else:
        inp[x] = 255
    subpixels(0, x, y, inp)
    

  try:
    while True:
      key = get_key()
      if key > 0:
        if key == 4: # ESC
          break
        target_graphic = 0; target_x = 20; target_y = 20
        source_graphic = 0; source_x = 40; source_y = 0; source_width = 60; source_height = 10
        strblit2(
          target_graphic, target_x, target_y, source_width, source_height,
          source_graphic, source_x, source_y, source_width, source_height
        )
      
  except KeyboardInterrupt:
    pass

try:
  main()
except KeyboardInterrupt:
  pass
  
print("Program Terminated")