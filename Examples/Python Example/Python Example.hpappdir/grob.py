from hpprime import pixon,line,fillrect
def image(p1,dx,dy,p4,p5,p6):
 w=int(p4[1][0]);h=int(p4[1][1]);v3=int(p4[1][2]);m=(1<<v3)-1;s=64/v3;x=0;y=0;v8=len(p4[0])
 for i in range(v8):
  d=int(p4[0][i])
  for j in range(64/v3):
   c=p4[2][d&m]
   if p5==1 and p6==1:
    pixon(p1,x+dx,y+dy,c),0,0
   elif p5==1 and p6>1:
    line(p1,x+dx,y+dy,x+dx,y+dy+p6-1,c)
   elif p5>1 and p6==1:
    line(p1,x+dx,y+dy,x+dx+p5-1,y+dy,c)
   else:
    fillrect(p1,x+dx,y+dy,p5,p6,c,c)
   d=d>>v3;x=x+p5
   if x==w*p5:
    x=0;y=y+p6
