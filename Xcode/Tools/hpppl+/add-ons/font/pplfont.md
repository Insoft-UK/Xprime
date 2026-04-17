The HP Prime stores its glyph data as a list of 64-bit unsigned integers. The bitmap, however, is stored in a specific bit order (little-endian) and where each byte of the 64-bit value is mirror-flipped.

e.g.
<img src="https://github.com/Insoft-UK/PrimeSDK/blob/main/assets/Hart.png" width="128" >
```
01101100 #6Ch to 00110110 #36h
11111110 #FEh to 01111111 #7Fh
11111110 #FEh to 01111111 #7Fh
11111110 #FEh to 01111111 #7Fh
01111110 #7Eh to 01111110 #7Eh
00111000 #38h to 00011100 #1Ch
00010000 #10h to 00001000 #08h
00000000 #00h to 00000000 #00h := #00081C7E7F7F7F36:64h
```

### Little-Endian
`#00081C7E7F7F7F36:64h`
#### Glyphs
`#--YYXXAAHHWWOOOO:64h = #--:8h #00:8h #00:8h #00:8h #00:8h #00:8h #0000:16h`
