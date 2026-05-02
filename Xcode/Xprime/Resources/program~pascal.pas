program $(PRODUCT_NAME);
  var state: integer;
  
  interface
  Draw();
  GetSelectedMenu(evt: integer);
  
  implementation

  procedure Draw()
  begin
    RECT_P();  // Clear screen
    TEXTOUT_P("Title", G0, 5, 5, 2, #000000h, 310, #FFFFFFh);
    DRAWMENU("F1", "F2", "F3", "F4", "F5", "Exit");
  end;

  procedure GetSelectedMenu(evt: integer)
  begin
    if TYPE(evt) <> 6 then return 0; end;
    if evt(1) <> 3 then return 0; end;
    return IP((evt(2) / 53.3333) + 1);
  end;

  begin
    var evt: integer, key: integer, menu: integer;
    Draw();
    repeat
      evt := WAIT(-1);
      key := -1;
      menu := GetSelectedMenu(evt);
      if type(evt) == 0 then
        key := evt;
      end;
    until key == 4 or menu == 6;
    return 0;
  end.
