from hpprime import pixon,line,fillrect
def image(v1,dx,dy,v4,v5,v6):
 w=int(v4[1][0]);h=int(v4[1][1]);v9=int(v4[1][2]);m=(1<<v9)-1;s=64/v9;x=0;y=0;v14=len(v4[0])
 for i in range(v14):
  d=int(v4[0][i])
  for j in range(64/v9):
   c=v4[2][d&m]
   if v5==1 and v6==1:
    pixon(v1,x+dx,y+dy,c),0,0
   elif v5==1 and v6>1:
    line(v1,x+dx,y+dy,x+dx,y+dy+v6-1,c)
   elif v5>1 and v6==1:
    line(v1,x+dx,y+dy,x+dx+v5-1,y+dy,c)
   else:
    fillrect(v1,x+dx,y+dy,v5,v6,c,c)
   d=d>>v9;x=x+v5
   if x==w*v5:
    x=0;y=y+v6
