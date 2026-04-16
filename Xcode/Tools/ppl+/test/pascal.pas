program TestLoop;
  var x,y: integer;
  
  interface
  procedure Loop(x,y:integer);
  
  implementation
  
  procedure Loop(x,y:integer);
    var i: integer;
    begin
      for i := x to y do
      begin
        WRITELN('i = ', i);
      end;
    end;

  begin
    x := 4;
    y := 7;
    Loop(x,y);
    case x of
      0: WriteLn(x);
      else
      WriteLn();
    end;
  end.

