PROGRAM $(PRODUCT_NAME);
  VAR state: integer;
  
  INTERFACE
  Draw();
  GetSelectedMenu(evt: integer);
  
  IMPLEMENTATION

  PROCEDURE Draw()
  BEGIN
    RECT_P();  // Clear screen
    TEXTOUT_P("Title", G0, 5, 5, 2, #000000h, 310, #FFFFFFh);
    DRAWMENU("F1", "F2", "F3", "F4", "F5", "Exit");
  END;

  PROCEDURE GetSelectedMenu(evt: integer)
  BEGIN
    IF TYPE(evt) <> 6 THEN RETURN 0; END;
    IF evt(1) <> 3 THEN RETURN 0; END;
    RETURN IP((evt(2) / 53.3333) + 1);
  END;

  BEGIN
    VAR evt: integer, key: integer, menu: integer;
    Draw();
    REPEAT
      evt := WAIT(-1);
      key := -1;
      menu := GetSelectedMenu(evt);
      IF TYPE(evt) == 0 THEN
        key := evt;
      END;
    UNTIL key == 4 OR menu == 6;
    RETURN 0;
  END.
