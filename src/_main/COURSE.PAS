program Course;
{ Coursework for SEUA (2012-2014), rebuilt with Turbo Pascal 5.5.
  A small DOS "desktop" in 640x480 VGA with a Start menu: a fake Blue Screen,
  the Tron light-cycle game and Problem 547 (the matrix row with the most equal elements).
  The Armenian texts use the AK Yerevan DOS encoding of FONT.COM, whose glyphs
  ARMFONT.INC carries, and the EGA/VGA driver is linked in: COURSE.EXE runs on its own.
  This is the program: it starts the graphics, the fonts and the mouse, and runs the desktop. Its parts are units:
  SHARED, what they all use, MENUS, TRON, P547 and DESKTOP, each using only those before it. }

uses Dos, Crt, Graph, GrMouse, Shared, Tron, P547, Desktop;

var
  MouseDown: Boolean;                { the left button was down at the previous check }
  ByKey: Boolean;                    { the desktop's action came from a key, not the mouse }
  GraphDriver, GraphMode, Action, Buttons: Integer;
  Colours: PaletteType;
  ch: Char;
  Ext: Boolean;

begin
  Randomize;                         { the computer player turns differently every time }
  UseArmenianFont;
  GraphDriver := Detect;
  if RegisterBGIdriver(@EgaVgaDriverProc) >= 0 then
    InitGraph(GraphDriver, GraphMode, '');
  Action := GraphResult;             { reading GraphResult clears it }
  if Action <> grOk then
  begin
    WriteLn('Graphics could not start: ', GraphErrorMsg(Action));
    WriteLn('COURSE.EXE needs an EGA or VGA display.');
    Halt(1)
  end;
  divx := GetMaxX div 2;
  divy := GetMaxY div 2;
  if InitGraphMouse = 0 then
  begin
    SetTextStyle(DefaultFont, HorizDir, 1);
    SetColor(White);
    OutCentered(divy, 'Մկնիկը չի գտնվել: Ծրագիրն առանց մկնիկի չի աշխատում:');
    WaitKey;
    CloseGraph;
    Halt(1)
  end;
  MouseThere := True;
  GetMem(MenuBack, ImageSize(0, GetMaxY - 253, 153, GetMaxY - 39));
  GetMem(SubmenuBack, ImageSize(153, GetMaxY - 181, 305, GetMaxY - 132));
  GetMem(MenuImage, ImageSize(0, GetMaxY - 253, 153, GetMaxY - 39));
  GetMem(SubmenuImage, ImageSize(153, GetMaxY - 181, 305, GetMaxY - 132));
  { the menus' pictures, painted while every colour of the palette is black, so they never show being drawn }
  GetPalette(Colours);
  for Action := 0 to Colours.Size - 1 do
    SetPalette(Action, Black);
  PaintStartMenu;
  GetImage(0, GetMaxY - 253, 153, GetMaxY - 39, MenuImage^);
  PaintProblemMenu;
  GetImage(153, GetMaxY - 181, 305, GetMaxY - 132, SubmenuImage^);
  ClearDevice;
  SetAllPalette(Colours);
  SetGrCursor(divx, divy - 60);
  DrawDesktop;
  KeyMode := True;                   { no cursor until the mouse moves }
  MoveCount := 0;
  Buttons := ReadGrCursor(KeyX, KeyY);
  repeat
    ShowCursor;
    repeat
      DrawClock;
      Buttons := ReadMouse;
      Action := actNone;
      ByKey := False;
      if (Buttons = 1) and not MouseDown then   { react when the button goes down, not while it is held }
        Action := DesktopAction(MouseX, MouseY)
      else if KeyPressed then
      begin
        KeysInUse;
        GetKey(ch, Ext);
        Action := DesktopKey(ch, Ext);
        ByKey := True
      end;
      MouseDown := Buttons <> 0
    until Action <> actNone;
    HideGrCursor;                    { every action draws; the cursor comes back once it has }
    case Action of
      actOpenMenu:
        begin
          DrawStartMenu;
          if ByKey then                { the keys go on from the first item }
            SelectItem(1)
        end;
      actClose:
        if TaskWindowOpen then         { too big to keep what it covers: the wallpaper is drawn again }
          DrawWallpaper
        else
          CloseMenus;
      actBlueScreen:
        begin
          BlueScreen;
          DrawDesktop
        end;
      actTron:
        begin
          TronMenu;
          DrawDesktop
        end;
      actProblemMenu:
        if not SubmenuOpen then
        begin
          DrawProblemMenu;
          if ByKey then
            SelectSubitem(1)
        end;
      actCloseSubmenu: CloseSubmenu;   { the mark stays on Problem 547 }
      actTaskText: ShowTaskText;
      actSolve:
        begin
          CloseMenus;                  { what the Start menu covered goes back before the window opens over it }
          SolveProblem;
          DrawDesktop
        end
    end;
    if KeyMode then                  { an action may have moved the cursor itself, as the task window does }
      Buttons := ReadGrCursor(KeyX, KeyY)
  until Action = actExit;
  CloseGraph
end.
