program Course;
{ Coursework for SEUA (2012-2014), rebuilt with Turbo Pascal 5.5.
  A small DOS "desktop" in 640x480 VGA with a Start menu: a fake Blue Screen,
  the Tron light-cycle game and Problem 547 (the matrix row with the most equal elements).
  The Armenian texts use the AK Yerevan DOS encoding of FONT.COM, whose glyphs
  ARMFONT.INC carries, and the EGA/VGA driver is linked in: COURSE.EXE runs on its own. }

uses Dos, Crt, Graph, GrMouse;

const
  { Tron directions }
  DirLeft = 1;
  DirUp = 2;
  DirRight = 3;
  DirDown = 4;

  StepDelay = 10;      { milliseconds between two moves of the light cycles }
  LogoRaise = 30;      { pixels the logo is drawn higher than its strokes say, leaving room for the menu under it }

  { what a click on the desktop does }
  actNone = 0;
  actOpenMenu = 1;
  actClose = 2;
  actBlueScreen = 3;
  actTron = 4;
  actProblemMenu = 5;
  actTaskText = 6;
  actSolve = 7;
  actExit = 8;
  actCloseSubmenu = 9;

  KeyBackspace = #8;
  KeyEnter = #13;
  KeyEsc = #27;
  KeySpace = ' ';
  { scan codes that GetKey returns for the arrow keys }
  ScanUp = #72;
  ScanLeft = #75;
  ScanRight = #77;
  ScanDown = #80;

type
  TMatrix = array[1..12, 1..6] of Real;  { up to 12 rows and 6 columns }
  TRow = array[1..6] of Real;
  TCounts = array[1..12] of Integer;
  TNumberText = string[11];          { a minus, 9 digits and a point }

  TStroke = record
    X, Y: Integer;                   { first square, in 6-pixel steps from the screen centre }
    Path: string[67];                { numpad moves: 8 up, 2 down, 4 left, 6 right, 7 9 1 3 diagonal,
                                       5 draws the same square again }
  end;

  TOption = record
    X1, Y1, X2, Y2: Integer;         { box; the caption is centred in it }
    Caption: string[12];
  end;

  TMenu = record
    Count, TextSize: Integer;
    Vertical: Boolean;               { chosen with up/down instead of left/right }
    Items: array[1..4] of TOption;
  end;

const
  { the TRON logo, traced square by square }
  LogoStrokes: array[1..10] of TStroke = (
    (X: -37; Y: -19; Path: '22366666'),
    (X: -36; Y: -20; Path: '66666322'),
    (X: -28; Y: -17; Path: '2222222222222366988888888888'),
    (X: -28; Y: -18; Path: '9966666666666666666666626262244444444444444444444'),
    (X: -3; Y: -14; Path: '444454444441222626262626262626666884848484848666868685'),
    (X: -16; Y: -13; Path: '2222222221447888888888966'),
    (X: -1; Y: -15; Path: '2222222622626266266666668668686886888888848848484484444444244242422'),
    (X: 4; Y: -14; Path: '869666362322212414447487888'),
    (X: 18; Y: -20; Path: '2222222222222222366988858966988884848484848484'),
    (X: 28; Y: -12; Path: '2226262626262626688888888888888888444122222144')
  );

{$I ARMFONT.INC}

var
  divx, divy: Integer;               { centre of the screen }
  RomFont: array[0..1023] of Byte absolute $F000:$FA6E;  { the BIOS's 8x8 characters $00..$7F, which graphics text uses }
  MouseX, MouseY: Integer;
  MouseDown: Boolean;                { the left button was down at the previous check }
  MenuOpen, SubmenuOpen, TaskWindowOpen: Boolean;
  Selected, SubSelected: Integer;    { the Start menu item and the submenu item the keys marked; 0 for none }
  MenuBack, SubmenuBack: Pointer;    { the desktop under the Start menu and under its submenu, put back as they close }
  MenuImage, SubmenuImage: Pointer;  { the pictures of the Start menu and its submenu, drawn once at the start }
  ByKey: Boolean;                    { the desktop's action came from a key, not the mouse }
  KeyMode: Boolean;                  { the mouse cursor is hidden until the mouse moves: at the start, once the keys
                                       work the desktop, and through clicks, as a tap on a touch screen is one }
  KeyX, KeyY: Integer;               { where the mouse was at the last check while its cursor was away }
  MoveCount: Integer;                { the moves of the mouse without a button since MoveTick }
  MoveTick: Word;                    { the BIOS timer tick, 18.2 a second, of the first of them }
  ClockText: string[8];
  MouseThere: Boolean;               { a mouse driver answered at the start; without one, only keys count }

  { Tron: cycle 1 is cyan (arrow keys), cycle 2 is yellow (WASD or the computer) }
  Xpos1, Ypos1, Npos1: Integer;
  Xpos2, Ypos2, Npos2: Integer;
  OnePlayer, RoundOver, Quit: Boolean;
  Winner: Integer;                   { 1 cyan, 2 yellow, 0 nobody }

  OldFontTable, OldExitProc: Pointer;

{ ===== built-in graphics driver and font ===== }

procedure EgaVgaDriverProc; external;   { EGAVGA.BGI, turned into EGAVGA.OBJ by BINOBJ when building }
{$L EGAVGA.OBJ}

{$F+}
procedure RestoreFont;
{ give the system its own font table back, however the program ends }
begin
  SetIntVec($1F, OldFontTable);
  ExitProc := OldExitProc
end;
{$F-}

procedure UseArmenianFont;
{ graphics text takes characters $80..$FF from the table at interrupt vector 1Fh }
begin
  GetIntVec($1F, OldFontTable);
  SetIntVec($1F, @ArmenianFont);
  OldExitProc := ExitProc;
  ExitProc := @RestoreFont
end;

{ ===== keyboard, files and text ===== }

procedure GetKey(var ch: Char; var Ext: Boolean);
{ read one key; an arrow or F-key arrives as #0 + scan code and comes back as the scan code with Ext set }
begin
  ch := ReadKey;
  Ext := ch = #0;
  if Ext then
    ch := ReadKey
end;

procedure WaitKey;
{ wait for a fresh key press or click: drop keys already typed or still held down, and a button still held. A tap on
  a touch screen is a click, so a phone without pads gets on too. A click counts once its button is let go, so it
  doesn't also click what the screen shows next }
var
  ch: Char;
  Ext: Boolean;
  x, y: Integer;
begin
  repeat
    while KeyPressed do
      ch := ReadKey;
    Delay(300)
  until not KeyPressed;
  if MouseThere then
  begin
    while ReadGrCursor(x, y) <> 0 do
      Delay(10);
    repeat
      Delay(10)
    until KeyPressed or (ReadGrCursor(x, y) <> 0);
    if not KeyPressed then
    begin
      while ReadGrCursor(x, y) <> 0 do
        Delay(10);
      Exit
    end
  end;
  GetKey(ch, Ext)
end;

function KeyWay(ch: Char; Ext: Boolean): Char;
{ the arrow a key from GetKey stands for, as its scan code: an arrow key, or W A S D; #0 for any other key }
begin
  KeyWay := #0;
  if Ext then
  begin
    if ch in [ScanUp, ScanLeft, ScanRight, ScanDown] then
      KeyWay := ch
  end
  else
    case UpCase(ch) of
      'W': KeyWay := ScanUp;
      'A': KeyWay := ScanLeft;
      'S': KeyWay := ScanDown;
      'D': KeyWay := ScanRight
    end
end;

{ ===== the mouse cursor, which keys and taps leave hidden ===== }

procedure ShowCursor;
{ the mouse cursor, unless the keys are in use: then it stays hidden until the mouse moves }
begin
  if not KeyMode then
    ShowGrCursor
end;

function ReadMouse: Word;
{ the mouse's buttons, with MouseX and MouseY where it is. While its cursor is away, only a mouse that moves brings it
  back: three moves without a button within about a fifth of a second. A click doesn't, nor a tap on a touch screen,
  which jumps the mouse there and presses at once }
var
  b: Word;
begin
  b := ReadGrCursor(MouseX, MouseY);
  if KeyMode then
  begin
    if b <> 0 then
      MoveCount := 0
    else if (MouseX <> KeyX) or (MouseY <> KeyY) then
    begin
      if (MoveCount = 0) or (MemW[$40:$6C] - MoveTick > 4) then
      begin
        MoveCount := 1;
        MoveTick := MemW[$40:$6C]
      end
      else
        MoveCount := MoveCount + 1;
      if MoveCount >= 3 then
      begin
        KeyMode := False;
        ShowGrCursor
      end
    end;
    KeyX := MouseX;
    KeyY := MouseY
  end;
  ReadMouse := b
end;

procedure KeysInUse;
{ the keys are in use: the mouse cursor goes until the mouse moves }
begin
  if not KeyMode then
  begin
    KeyMode := True;
    KeyX := MouseX;
    KeyY := MouseY;
    MoveCount := 0;
    HideGrCursor
  end
end;

function HomeFile(name: string): string;
{ the file called name in the folder COURSE.EXE was started from }
var
  p: string;
  i: Integer;
begin
  p := ParamStr(0);
  i := Length(p);
  while (i > 0) and (p[i] <> '\') do
    i := i - 1;
  HomeFile := Copy(p, 1, i) + name
end;

function TwoDigits(n: Word): string;
var
  s: string;
begin
  Str(n, s);
  if Length(s) = 1 then
    s := '0' + s;
  TwoDigits := s
end;

function InkX(x1, x2: Integer; s: string): Integer;
{ where s starts for what it shows, not its characters' boxes, to be centred between x1 and x2, in the default font
  at the current size: most characters leave their last columns blank, some their first }
var
  ts: TextSettingsType;
  first, last, left, right: Integer;
  bits: Byte;

  function Ink(c: Char): Byte;
  { the columns of c that show anything, as the bits of one row; $80..$FF are the Armenian table's, the rest the
    BIOS's own }
  var
    r: Integer;
    b: Byte;
  begin
    b := 0;
    for r := 0 to 7 do
      if Ord(c) >= $80 then
        b := b or ArmenianFont[(Ord(c) - $80) * 8 + r]
      else
        b := b or RomFont[Ord(c) * 8 + r];
    Ink := b
  end;

begin
  first := 1;
  while (first <= Length(s)) and (Ink(s[first]) = 0) do
    Inc(first);
  if first > Length(s) then
  begin
    InkX := (x1 + x2 + 1) div 2 - TextWidth(s) div 2;
    Exit
  end;
  last := Length(s);
  while Ink(s[last]) = 0 do
    Dec(last);
  bits := Ink(s[first]);
  left := 0;
  while bits and ($80 shr left) = 0 do
    Inc(left);
  bits := Ink(s[last]);
  right := 7;
  while bits and ($80 shr right) = 0 do
    Dec(right);
  GetTextSettings(ts);
  InkX := (x1 + x2 - ((first - 1) * 8 + left) * ts.CharSize - ((last - 1) * 8 + right + 1) * ts.CharSize + 1) div 2
end;

procedure OutCentered(y: Integer; s: string);
{ s centred on the screen by what it shows, in the current text style }
begin
  OutTextXY(InkX(0, GetMaxX, s), y, s)
end;

procedure TypeText(x0, y0: Integer; color: Word; size: Word; s: string);
{ write s one character at a time, like a typewriter. A mouse cursor on the screen stays there and moves as the mouse
  does: it is hidden only for a moment, when a character is drawn under it, which would otherwise leave marks }
var
  i, x, mx, my: Integer;
  buttons: Word;
  covers: Boolean;
begin
  SetTextStyle(DefaultFont, HorizDir, size);
  SetColor(color);
  for i := 1 to Length(s) do
  begin
    x := x0 + i * 8 * size;
    covers := False;
    if GrCursorShown then
    begin
      buttons := ReadGrCursor(mx, my);
      { the cursor is 16 x 16 pixels from its tip }
      covers := (mx + 16 > x) and (mx < x + 8 * size) and (my + 16 > y0) and (my < y0 + 8 * size);
      if covers then
        HideGrCursor
    end;
    OutTextXY(x, y0, s[i]);
    if covers then
      ShowGrCursor;
    Delay(10)
  end
end;

function InRect(x, y, x1, y1, x2, y2: Integer): Boolean;
begin
  InRect := (x >= x1) and (x <= x2) and (y >= y1) and (y <= y2)
end;

{ ===== menus ===== }

procedure SetOption(var o: TOption; x1, y1, x2, y2: Integer; caption: string);
begin
  o.X1 := x1;
  o.Y1 := y1;
  o.X2 := x2;
  o.Y2 := y2;
  o.Caption := caption
end;

procedure DrawOption(var m: TMenu; i, selected: Integer);
{ option i of m, with its caption centred: green when it is the selected one, blue otherwise, and grey when selected
  is 0, for a menu that is waiting behind another one }
begin
  SetTextStyle(DefaultFont, HorizDir, m.TextSize);
  with m.Items[i] do
  begin
    if selected = 0 then
    begin
      SetFillStyle(SolidFill, LightGray);
      SetColor(DarkGray)
    end
    else if i = selected then
    begin
      SetFillStyle(SolidFill, LightGreen);
      SetColor(Green)
    end
    else
    begin
      SetFillStyle(SolidFill, LightBlue);
      SetColor(Blue)
    end;
    Bar(X1, Y1, X2, Y2);
    OutTextXY(InkX(X1, X2, Caption), (Y1 + Y2 + 1) div 2 - TextHeight(Caption) div 2, Caption)
  end
end;

procedure DrawMenu(var m: TMenu; selected: Integer);
{ every option of m; selected = 0 draws them all grey }
var
  i: Integer;
begin
  for i := 1 to m.Count do
    DrawOption(m, i, selected)
end;

procedure MoveSelection(var m: TMenu; var k: Integer; next: Integer);
{ the selection from option k to option next: only those two are drawn again, so the others don't flicker }
var
  old: Integer;
begin
  if next = k then
    Exit;
  old := k;
  k := next;
  DrawOption(m, old, k);
  DrawOption(m, k, k)
end;

function OptionAt(var m: TMenu; x, y: Integer): Integer;
{ the option of m under (x, y), or 0 }
var
  i: Integer;
begin
  OptionAt := 0;
  for i := 1 to m.Count do
    if InRect(x, y, m.Items[i].X1, m.Items[i].Y1, m.Items[i].X2, m.Items[i].Y2) then
      OptionAt := i
end;

function Choose(var m: TMenu): Integer;
{ pick an option with the arrow keys or W A S D, and Enter or Space, or with the mouse: moving over an option picks
  it out, and a click, or a tap, chooses it. Esc gives 0. The mouse cursor shows only while the menu waits }
var
  k, over, chosen, lastX, lastY: Integer;
  ch, way, prevKey, nextKey: Char;
  Ext, down: Boolean;
  buttons: Word;
begin
  if m.Vertical then
  begin
    prevKey := ScanUp;
    nextKey := ScanDown
  end
  else
  begin
    prevKey := ScanLeft;
    nextKey := ScanRight
  end;
  k := 1;
  chosen := -1;
  DrawMenu(m, k);
  buttons := ReadMouse;
  down := buttons <> 0;              { a button still held from before is no click }
  lastX := MouseX;
  lastY := MouseY;
  ShowCursor;
  repeat
    buttons := ReadMouse;
    over := OptionAt(m, MouseX, MouseY);
    { only a mouse that moves or clicks picks out the option under it: one resting there leaves the keys' choice }
    if (over > 0) and (over <> k) and ((MouseX <> lastX) or (MouseY <> lastY) or (buttons <> 0)) then
    begin
      HideGrCursor;
      MoveSelection(m, k, over);
      ShowCursor
    end;
    if (buttons = 1) and not down and (over > 0) then
      chosen := over;
    down := buttons <> 0;
    lastX := MouseX;
    lastY := MouseY;
    if KeyPressed then
    begin
      KeysInUse;
      GetKey(ch, Ext);
      way := KeyWay(ch, Ext);
      if way = nextKey then
        MoveSelection(m, k, k mod m.Count + 1)
      else if way = prevKey then
        MoveSelection(m, k, (k + m.Count - 2) mod m.Count + 1);
      if not Ext and ((ch = KeyEnter) or (ch = KeySpace)) then
        chosen := k
      else if not Ext and (ch = KeyEsc) then
        chosen := 0
    end
  until chosen >= 0;
  HideGrCursor;
  Choose := chosen
end;

procedure BuildTronMenu(var m: TMenu);
begin
  m.Count := 4;
  m.TextSize := 1;
  m.Vertical := False;
  SetOption(m.Items[1], 82, divy, 182, divy + 50, '1 խաղացող');
  SetOption(m.Items[2], 207, divy, 307, divy + 50, '2 խաղացող');
  SetOption(m.Items[3], 332, divy, 432, divy + 50, 'Պայմաններ');
  SetOption(m.Items[4], 457, divy, 557, divy + 50, 'Ելք')
end;

procedure BuildRoundsMenu(var m: TMenu; centre: Integer);
{ the number of rounds, as a column 80 pixels wide under the chosen mode, whose middle is at centre }
var
  x: Integer;
begin
  x := centre - 40;
  m.Count := 4;
  m.TextSize := 1;
  m.Vertical := True;
  SetOption(m.Items[1], x, divy + 62, x + 80, divy + 92, '5 խաղ');
  SetOption(m.Items[2], x, divy + 102, x + 80, divy + 132, '10 խաղ');
  SetOption(m.Items[3], x, divy + 142, x + 80, divy + 172, '25 խաղ');
  SetOption(m.Items[4], x, divy + 182, x + 80, divy + 212, '50 խաղ')
end;

procedure BuildYesNoMenu(var m: TMenu);
begin
  m.Count := 2;
  m.TextSize := 2;
  m.Vertical := False;
  SetOption(m.Items[1], 207, divy, 307, divy + 50, 'Այո');
  SetOption(m.Items[2], 332, divy, 432, divy + 50, 'Ոչ')
end;

{ ===== Tron ===== }

procedure DrawLogo(traced: Boolean);
{ the TRON logo: traced square by square, where a key press draws the rest of it at once, or drawn at once }
var
  s, i, x, y: Integer;
begin
  SetFillStyle(SolidFill, Green);
  for s := 1 to 10 do
  begin
    x := LogoStrokes[s].X;
    y := LogoStrokes[s].Y;
    for i := 0 to Length(LogoStrokes[s].Path) do
    begin
      if i > 0 then
        case LogoStrokes[s].Path[i] of
          '1': begin x := x - 1; y := y + 1 end;
          '2': y := y + 1;
          '3': begin x := x + 1; y := y + 1 end;
          '4': x := x - 1;
          '6': x := x + 1;
          '7': begin x := x - 1; y := y - 1 end;
          '8': y := y - 1;
          '9': begin x := x + 1; y := y - 1 end
        end;
      { a pixel right of divx: its squares run from -37 to 36, so that puts its middle in the screen's }
      Bar(divx + 1 + x * 6, divy - LogoRaise + y * 6, divx + 1 + x * 6 + 5, divy - LogoRaise + y * 6 + 5);
      if traced and not KeyPressed then
        Delay(10)
    end
  end
end;

procedure ShowRules;
{ every line centred whole; a colour's name in a line is drawn over again in that colour }
var
  s: string;
  x, y: Integer;

  procedure Line(at: Integer; text: string);
  begin
    s := text;
    y := at;
    x := InkX(0, GetMaxX, s);
    SetColor(LightGray);
    OutTextXY(x, y, s)
  end;

  procedure Paint(name: string; color: Word);
  begin
    SetColor(color);
    OutTextXY(x + (Pos(name, s) - 1) * 8, y, name)
  end;

begin
  ClearDevice;
  SetTextStyle(DefaultFont, HorizDir, 1);
  SetColor(Green);
  OutCentered(100, 'Բովանդակություն');
  SetColor(LightGray);
  OutCentered(115, 'Խաղի նպատակն է դուրս բերել հակառակորդին կառավարումից:');
  OutCentered(130, 'Խաղացողը համարվում է հաղթող, եթե հակառակորդը բախվել է ինչ-որ խոչընդոտի:');
  SetColor(Brown);
  OutCentered(180, 'Կառավարում');
  { the arrows are the font's own, characters 24 to 27 }
  Line(195, 'Կապույտ խաղացող` վերեւ` '#24', ներքեւ` '#25', աջ` '#26', ձախ` '#27':');
  Paint('Կապույտ', Cyan);
  Line(210, 'Դեղին խաղացող` վերեւ` W, ներքեւ` S, աջ` D, ձախ` A:');
  Paint('Դեղին', Yellow);
  SetColor(LightBlue);
  OutCentered(260, 'Ռեժիմներ');
  Line(275, 'Խաղացողն ընդդեմ համակարգչի: Խաղացողի գույնը` կապույտ, համակարգչինը` դեղին:');
  Paint('կապույտ', Cyan);
  Paint('դեղին', Yellow);
  Line(290, 'Խաղացողն ընդդեմ խաղացողի: Խաղացողների գույները` դեղին եւ կապույտ:');
  Paint('դեղին', Yellow);
  Paint('կապույտ', Cyan);
  WaitKey;
  ClearDevice
end;

procedure StartRound;
begin
  Npos1 := DirLeft;
  Npos2 := DirRight;
  Xpos1 := GetMaxX - 100;
  Ypos1 := 240;
  Xpos2 := 101;
  Ypos2 := 240;
  RoundOver := False
end;

procedure ReadControls;
{ steer cyan with the arrows; yellow with WASD, or let the computer steer it }
var
  ch: Char;
  Ext: Boolean;
  steps, aheadX, aheadY, i: Integer;
begin
  ch := #0;
  Ext := False;
  if KeyPressed then
    GetKey(ch, Ext);
  if Ext then
    case ch of
      ScanLeft: if Npos1 <> DirRight then Npos1 := DirLeft;
      ScanUp: if Npos1 <> DirDown then Npos1 := DirUp;
      ScanRight: if Npos1 <> DirLeft then Npos1 := DirRight;
      ScanDown: if Npos1 <> DirUp then Npos1 := DirDown
    end;
  if OnePlayer then
  begin
    { look up to 40 moves ahead; the nearer something is, the likelier a random turn }
    steps := 0;
    aheadX := Xpos2;
    aheadY := Ypos2;
    repeat
      steps := steps + 1;
      case Npos2 of
        DirLeft: aheadX := aheadX - 2;
        DirUp: aheadY := aheadY - 2;
        DirRight: aheadX := aheadX + 2;
        DirDown: aheadY := aheadY + 2
      end
    until (GetPixel(aheadX, aheadY) <> 0) or (steps = 40);
    if Random(steps) = 0 then
      case Random(4) + 1 of
        DirLeft: if (Npos2 <> DirLeft) and (Npos2 <> DirRight) then Npos2 := DirLeft;
        DirUp: if (Npos2 <> DirUp) and (Npos2 <> DirDown) then Npos2 := DirUp;
        DirRight: if (Npos2 <> DirRight) and (Npos2 <> DirLeft) then Npos2 := DirRight;
        DirDown: if (Npos2 <> DirDown) and (Npos2 <> DirUp) then Npos2 := DirDown
      end;
    { something right ahead: turn to one side, and if that is blocked too, to the other }
    for i := 1 to 2 do
    begin
      case Npos2 of
        DirLeft: if GetPixel(Xpos2 - 2, Ypos2) <> 0 then Npos2 := DirDown;
        DirUp: if GetPixel(Xpos2, Ypos2 - 2) <> 0 then Npos2 := DirRight;
        DirRight: if GetPixel(Xpos2 + 2, Ypos2) <> 0 then Npos2 := DirUp;
        DirDown: if GetPixel(Xpos2, Ypos2 + 2) <> 0 then Npos2 := DirLeft
      end;
      case Npos2 of
        DirLeft: if GetPixel(Xpos2 - 2, Ypos2) <> 0 then Npos2 := DirUp;
        DirUp: if GetPixel(Xpos2, Ypos2 - 2) <> 0 then Npos2 := DirLeft;
        DirRight: if GetPixel(Xpos2 + 2, Ypos2) <> 0 then Npos2 := DirDown;
        DirDown: if GetPixel(Xpos2, Ypos2 + 2) <> 0 then Npos2 := DirRight
      end
    end
  end
  else if not Ext then
    case UpCase(ch) of
      'A': if Npos2 <> DirRight then Npos2 := DirLeft;
      'W': if Npos2 <> DirDown then Npos2 := DirUp;
      'D': if Npos2 <> DirLeft then Npos2 := DirRight;
      'S': if Npos2 <> DirUp then Npos2 := DirDown
    end;
  if not Ext and (ch = KeyEsc) then
  begin
    RoundOver := True;
    Quit := True
  end
end;

procedure Advance(var x, y: Integer; dir: Integer);
begin
  case dir of
    DirLeft: x := x - 2;
    DirUp: y := y - 2;
    DirRight: x := x + 2;
    DirDown: y := y + 2
  end
end;

procedure DrawHead(x, y: Integer; color: Word);
begin
  SetFillStyle(SolidFill, color);
  Bar(x, y, x + 1, y + 1)
end;

procedure MoveCycles;
{ move both cycles one step at the same time; a cycle crashes when it lands on anything but black.
  When both crash, or they meet on the same spot, nobody wins the round. }
var
  crash1, crash2, meet: Boolean;
begin
  Advance(Xpos1, Ypos1, Npos1);
  Advance(Xpos2, Ypos2, Npos2);
  meet := (Xpos1 = Xpos2) and (Ypos1 = Ypos2);
  crash1 := meet or (GetPixel(Xpos1, Ypos1) <> 0);
  crash2 := meet or (GetPixel(Xpos2, Ypos2) <> 0);
  if crash1 or crash2 then
  begin
    RoundOver := True;
    if crash1 and crash2 then
      Winner := 0
    else if crash1 then
      Winner := 2
    else
      Winner := 1
  end;
  DrawHead(Xpos1, Ypos1, Cyan);
  DrawHead(Xpos2, Ypos2, Yellow);
  Delay(StepDelay)
end;

procedure DrawScore(yellowScore, blueScore: Integer; visible: Boolean);
{ "Դեղին  y:b  Կապույտ" across the top; visible = False paints it out in black }
var
  s, a, b: string;
begin
  Str(yellowScore, a);
  Str(blueScore, b);
  s := '        ' + a + ':' + b + '          ';
  SetTextStyle(DefaultFont, HorizDir, 2);
  if visible then
    SetColor(Green)
  else
    SetColor(Black);
  OutTextXY(divx - Length(s) * 8, 2, s);
  if visible then
    SetColor(Yellow);
  OutTextXY(divx - Length(s) * 8, 2, 'Դեղին');
  if visible then
    SetColor(Cyan);
  OutTextXY(divx + Length(s) * 8 - 112, 2, 'Կապույտ')
end;

procedure PlayMatch(rounds: Integer);
{ rounds until one colour has won the given number of them, then offer a new match }
var
  blueScore, yellowScore: Integer;
  again: Boolean;
  yesNo: TMenu;
begin
  repeat
    blueScore := 0;
    yellowScore := 0;
    Quit := False;
    ClearDevice;
    while (blueScore < rounds) and (yellowScore < rounds) and not Quit do
    begin
      StartRound;
      SetColor(LightBlue);
      SetLineStyle(SolidLn, 0, ThickWidth);
      Rectangle(0, 20, GetMaxX, GetMaxY);
      DrawScore(yellowScore, blueScore, True);
      Winner := 0;
      while not RoundOver do
      begin
        ReadControls;
        MoveCycles
      end;
      if not Quit then
      begin
        DrawScore(yellowScore, blueScore, False);
        if Winner = 1 then
          blueScore := blueScore + 1
        else if Winner = 2 then
          yellowScore := yellowScore + 1;
        DrawScore(yellowScore, blueScore, True);
        WaitKey
      end;
      ClearDevice
    end;
    again := False;
    if not Quit then
    begin
      SetTextStyle(DefaultFont, HorizDir, 4);
      if blueScore > yellowScore then
      begin
        SetColor(LightBlue);
        OutCentered(divy - 20, 'Կապույտը հաղթե՛ց')
      end
      else if blueScore < yellowScore then
      begin
        SetColor(Yellow);
        OutCentered(divy - 20, 'Դեղինը հաղթե՛ց')
      end;
      WaitKey;
      ClearDevice;
      SetTextStyle(DefaultFont, HorizDir, 3);
      SetColor(Red);
      OutCentered(divy - 50, 'Նոր խա՞ղ');
      BuildYesNoMenu(yesNo);
      again := Choose(yesNo) = 1;
      ClearDevice
    end
  until not again;
  ClearDevice
end;

procedure TronMenu;
{ one screen: the logo traced, the prompt at the foot of the screen, then the Tron menu under the logo, until Exit or Esc.
  Back from a match or the rules, the logo is there again at once, with the menu under it }
const
  LogoPause = 2000;                  { milliseconds a logo traced to its end stays alone before the prompt }
  Prompt = 'Սեղմեք ցանկացած ստեղն խաղը սկսելու համար';
var
  modes, rounds: TMenu;
  choice, waited: Integer;
begin
  HideGrCursor;
  ClearDevice;
  DrawLogo(True);
  { the logo alone a moment, to be seen whole; a key, the one that hurried it or a new one, ends that at once }
  waited := 0;
  while (waited < LogoPause) and not KeyPressed do
  begin
    Delay(50);
    waited := waited + 50
  end;
  { the prompt at the foot of the screen; a key takes it away and brings the menu under the logo }
  SetTextStyle(DefaultFont, HorizDir, 1);
  SetColor(LightGray);
  OutCentered(GetMaxY - 60, Prompt);
  WaitKey;                           { a fresh key: not the one that hurried the logo, nor one still held }
  SetColor(Black);
  OutCentered(GetMaxY - 60, Prompt);
  BuildTronMenu(modes);
  repeat
    choice := Choose(modes);
    if (choice = 1) or (choice = 2) then
    begin
      OnePlayer := choice = 1;
      DrawMenu(modes, 0);
      if OnePlayer then
        BuildRoundsMenu(rounds, (modes.Items[1].X1 + modes.Items[1].X2) div 2)
      else
        BuildRoundsMenu(rounds, (modes.Items[2].X1 + modes.Items[2].X2) div 2);
      case Choose(rounds) of
        1: PlayMatch(5);
        2: PlayMatch(10);
        3: PlayMatch(25);
        4: PlayMatch(50)
      end;
      ClearDevice;
      DrawLogo(False)
    end
    else if choice = 3 then
    begin
      ShowRules;
      ClearDevice;
      DrawLogo(False)
    end
  until (choice = 4) or (choice = 0);
  ClearDevice
end;

procedure DrawClock;
{ redraw the clock in the taskbar when the time has changed: only the characters that changed, each over its own
  piece of the bar, so the rest of it never goes blank }
var
  h, m, s, hundredths: Word;
  t: string[8];
  nearCursor: Boolean;
  i, x: Integer;
begin
  GetTime(h, m, s, hundredths);
  t := TwoDigits(h) + ':' + TwoDigits(m) + ':' + TwoDigits(s);
  if t <> ClockText then
  begin
    nearCursor := (MouseX >= GetMaxX - 90) and (MouseY >= GetMaxY - 40);
    if nearCursor then
      HideGrCursor;
    SetTextStyle(DefaultFont, HorizDir, 1);
    SetFillStyle(SolidFill, DarkGray);
    SetColor(White);
    for i := 1 to Length(t) do
      if (i > Length(ClockText)) or (t[i] <> ClockText[i]) then
      begin
        x := GetMaxX - 70 + (i - 1) * 8;
        Bar(x, GetMaxY - 20, x + 7, GetMaxY - 13);
        OutTextXY(x, GetMaxY - 20, t[i])
      end;
    if nearCursor then
      ShowCursor;
    ClockText := t
  end
end;

procedure CloseSubmenu;
{ put back what the submenu of Problem 547 covered }
begin
  if SubmenuOpen then
    PutImage(153, GetMaxY - 181, SubmenuBack^, NormalPut);
  SubmenuOpen := False;
  SubSelected := 0
end;

procedure CloseMenus;
{ put back what the Start menu and its submenu covered, the submenu first, as it overlaps the menu's edge }
begin
  CloseSubmenu;
  if MenuOpen then
    PutImage(0, GetMaxY - 253, MenuBack^, NormalPut);
  MenuOpen := False;
  Selected := 0
end;

{ ===== Problem 547 ===== }

const
  GridTop = 96;                      { the matrix is drawn centred in GridTop..GridTop + GridHeight }
  GridHeight = 256;
  GridWidth = 564;
  HintY = 362;                       { the line of the short red hints }
  NoteY = 388;                       { the line of what to press next }

procedure DrawWindow;
{ the window of Problem 547, for its task and its solution: a grey frame, its title and a red x in its header, and
  white inside }
begin
  SetFillStyle(SolidFill, DarkGray);
  Bar(20, 20, GetMaxX - 20, GetMaxY - 58);
  SetFillStyle(SolidFill, White);
  Bar(30, 50, GetMaxX - 30, GetMaxY - 68);
  { the header is 30 pixels tall, 20 to 49: the title and the red x in its middle }
  SetFillStyle(SolidFill, Red);
  Bar(GetMaxX - 65, 27, GetMaxX - 30, 42);
  SetTextStyle(DefaultFont, HorizDir, 1);
  SetColor(White);
  OutTextXY(GetMaxX - 51, 31, 'x');
  OutTextXY(36, 31, 'Խնդիր 547')         { the title, as the red x, in the text of the program's windows }
end;

function OnClose(x, y: Integer): Boolean;
{ (x, y) is on the window's red x }
begin
  OnClose := InRect(x, y, GetMaxX - 65, 27, GetMaxX - 30, 42)
end;

function WaitInput(var ch: Char; var Ext: Boolean; var x, y: Integer): Boolean;
{ wait for a key, True with it in ch and Ext, or for a click of the left button, False with where it was in x and y.
  The mouse cursor shows while it waits, unless the keys are in use, and the taskbar's clock goes on }
var
  buttons: Word;
  down, done: Boolean;
begin
  down := ReadMouse <> 0;            { a button still held from before is no click }
  ShowCursor;
  done := False;
  repeat
    DrawClock;
    buttons := ReadMouse;
    if (buttons = 1) and not down then
    begin
      x := MouseX;
      y := MouseY;
      WaitInput := False;
      done := True
    end
    else if KeyPressed then
    begin
      KeysInUse;
      GetKey(ch, Ext);
      WaitInput := True;
      done := True
    end;
    down := buttons <> 0
  until done;
  HideGrCursor
end;

procedure FlashError(s: string);
{ a short red hint under the matrix }
begin
  SetTextStyle(DefaultFont, HorizDir, 1);
  SetColor(Red);
  OutCentered(HintY, s);
  Delay(200);
  SetColor(White);
  OutCentered(HintY, s)
end;

procedure FileError(s: string);
{ why 547.TXT failed; waits for a key or a click }
var
  ch: Char;
  Ext: Boolean;
  x, y: Integer;
begin
  SetTextStyle(DefaultFont, HorizDir, 1);
  SetColor(Red);
  OutCentered(NoteY, s);
  if WaitInput(ch, Ext, x, y) then
    ;
end;

procedure Eraser(x1, y1, x2, h: Integer; color: Word; pause: Word);
{ paint x1..x2 by y1..y1+h in color, one vertical line at a time, pause milliseconds apart }
var
  x: Integer;
begin
  SetColor(color);
  for x := x1 to x2 do
  begin
    Line(x, y1, x, y1 + h);
    Delay(pause)
  end
end;

function CountEqual(var r: TRow; n: Integer; a: Real): Integer;
{ subprogram 1 of the task: how many of the first n elements of r equal a }
var
  j, q: Integer;
begin
  q := 0;
  for j := 1 to n do
    if r[j] = a then
      q := q + 1;
  CountEqual := q
end;

function MaxElement(var v: TCounts; n: Integer): Integer;
{ subprogram 2 of the task: the largest of the first n elements of v }
var
  i, mx: Integer;
begin
  mx := v[1];
  for i := 2 to n do
    if v[i] > mx then
      mx := v[i];
  MaxElement := mx
end;

function ReadDimension(y: Integer; prompt: string; most: Integer): Integer;
{ a number of rows or columns from 1 to most, one or two digits typed after prompt; 0 when Esc or the window's x
  cancels }
var
  ch: Char;
  Ext: Boolean;
  typed: string[2];
  x, mx, my, n, code: Integer;
begin
  ReadDimension := 0;
  SetTextStyle(DefaultFont, HorizDir, 1);
  x := divx + Length(prompt) * 4;
  SetColor(Red);
  OutTextXY(divx - Length(prompt) * 4 - 16, y, prompt);
  typed := '';
  repeat
    SetColor(Blue);
    OutTextXY(x, y, typed + '_');
    if not WaitInput(ch, Ext, mx, my) then
    begin
      if OnClose(mx, my) then
        Exit;
      ch := #0
    end
    else if Ext then
      ch := #0;
    SetColor(White);
    OutTextXY(x, y, typed + '_');
    if ch = KeyEsc then
      Exit
    else if ch in ['0'..'9'] then
    begin
      Val(typed + ch, n, code);      { a digit only while the number stays from 1 to most }
      if (Length(typed) < 2) and (n >= 1) and (n <= most) then
        typed := typed + ch
    end
    else if (ch = KeyBackspace) and (typed <> '') then
      Delete(typed, Length(typed), 1)
    else if (ch = KeyEnter) and (typed = '') then
      FlashError('գրեք թիվ')
  until (ch = KeyEnter) and (typed <> '');
  SetColor(Blue);
  OutTextXY(x, y, typed);
  Val(typed, n, code);
  ReadDimension := n
end;

function NumberProblem(txt: TNumberText): string;
{ why txt is no whole number, or '' when it is one }
begin
  if (txt = '') or (txt = '-') then
    NumberProblem := 'խնդրո՛ւմ ենք ավարտել թվի մուտքագրում, դուք դեռ չեք վերջացրել'
  else if (Pos('.', txt) <> 0) and (txt[Length(txt)] = '0') then
    NumberProblem := 'խնդրո՛ւմ ենք կոտորակային թվից հետո չգրել ավելորդ զրոներ'
  else if txt[Length(txt)] = '.' then
    NumberProblem := 'խնդրո՛ւմ ենք մուտքագրեք ճիշտ թիվ'
  else
    NumberProblem := ''
end;

function AddToNumber(var txt: TNumberText; ch: Char): string;
{ ch added to the number being typed in txt, or why it can't be: a minus only first, one point, after a digit, no
  digit after a leading zero but a point, at most 9 digits }
var
  digits, t: Integer;
begin
  AddToNumber := '';
  digits := 0;                       { the minus and the point do not count }
  for t := 1 to Length(txt) do
    if txt[t] in ['0'..'9'] then
      digits := digits + 1;
  if (ch = '-') and (txt <> '') then
    AddToNumber := 'մինուսի նշանը դնում են թվի սկզբում'
  else if (txt = '') and (ch = '.') then
    AddToNumber := 'Նախքան կետի նշան դնելը, թիվ գրեք'
  else if (txt = '-') and (ch = '.') then
    AddToNumber := 'մինուս նշանից հետո գրեք թիվ, այլ ոչ կետ...'
  else if (ch = '.') and (Pos('.', txt) <> 0) then
    AddToNumber := 'կրկնակի մի դրեք կետի նշան'
  else if ((txt = '0') or (txt = '-0')) and (ch <> '.') then
    AddToNumber := 'զրոյից հետո չմոռանաք դնել կետի նշանը'
  else if not (ch in ['0'..'9', '-', '.']) then
    AddToNumber := 'թիվ, ասեցինք թի՛վ գրեք'
  else if (ch in ['0'..'9']) and (digits >= 9) then
    AddToNumber := 'Թվանշանների քանակը չպե՛տք է գերազանցի 9-ը'
  else
    txt := txt + ch
end;

procedure SolveProblem;
{ in the window of Problem 547: the size of a matrix, then its numbers, typed cell by cell in any order: a click on a
  cell, or the arrows, pick the cell, Enter goes on to the next empty one. Space saves the matrix to 547.TXT, which is
  read back to show the last row with the most equal elements. Esc or the window's x closes it at any time }
const
  RowsPrompt = 'մուտքագրեք տողերի քանակը 1-ից 12 միջակայքում`';
  ColsPrompt = 'մուտքագրեք սյուների քանակը 1-ից 6 միջակայքում`';
var
  cells: array[1..12, 1..6] of TNumberText;
  values: TMatrix;
  row: TRow;
  counts: TCounts;
  rows, cols, fileRows, fileCols, i, j, ci, cj, best, answerRow, code, left, top, w, h, tx, mx, my, pause: Integer;
  f: Text;
  textLine, s, o, p, msg: string;
  ch: Char;
  Ext, cancel, done, noted: Boolean;

  function CellLeft(j: Integer): Integer;
  begin
    CellLeft := left + (j - 1) * w
  end;

  function CellTop(i: Integer): Integer;
  begin
    CellTop := top + (i - 1) * h
  end;

  function TextTop(i: Integer): Integer;
  begin
    TextTop := CellTop(i) + (h - 8) div 2
  end;

  procedure DrawCell(i, j: Integer; active: Boolean);
  { a cell and its number: white, with the typing cursor, while it is the one typed in, yellow otherwise }
  begin
    if active then
      SetFillStyle(SolidFill, White)
    else
      SetFillStyle(SolidFill, Yellow);
    Bar(CellLeft(j) + 1, CellTop(i) + 1, CellLeft(j) + w - 1, CellTop(i) + h - 1);
    SetTextStyle(DefaultFont, HorizDir, 1);
    SetColor(Brown);
    OutTextXY(CellLeft(j) + tx, TextTop(i), cells[i, j]);
    if active and (Length(cells[i, j]) <= 10) then   { a full cell has no room for the cursor }
      OutTextXY(CellLeft(j) + tx + Length(cells[i, j]) * 8, TextTop(i), '_')
  end;

  function Filled: Boolean;
  { every cell holds a whole number }
  var
    a, b: Integer;
  begin
    Filled := True;
    for a := 1 to rows do
      for b := 1 to cols do
        if NumberProblem(cells[a, b]) <> '' then
          Filled := False
  end;

  procedure Note(shown: Boolean);
  { what to press once every cell is filled, shown or taken away }
  begin
    if shown <> noted then
    begin
      SetTextStyle(DefaultFont, HorizDir, 1);
      if shown then
        SetColor(Red)
      else
        SetColor(White);
      OutCentered(NoteY, 'Սեղմեք Space տվյալները ֆայլում տպելու համար');
      noted := shown
    end
  end;

  procedure SelectCell(i, j: Integer);
  { the typing moves to cell (i, j), when it is in the matrix and the number of the cell it leaves is whole or empty }
  begin
    if (i < 1) or (i > rows) or (j < 1) or (j > cols) or ((i = ci) and (j = cj)) then
      Exit;
    if cells[ci, cj] <> '' then
    begin
      msg := NumberProblem(cells[ci, cj]);
      if msg <> '' then
      begin
        FlashError(msg);
        Exit
      end
    end;
    DrawCell(ci, cj, False);
    ci := i;
    cj := j;
    DrawCell(ci, cj, True)
  end;

  procedure NextCell;
  { after Enter: the first empty cell after this one, row by row; when none is empty, the typing stays }
  var
    n, here, step, k: Integer;
  begin
    n := rows * cols;
    here := (ci - 1) * cols + (cj - 1);
    for step := 1 to n - 1 do
    begin
      k := (here + step) mod n;
      if cells[k div cols + 1, k mod cols + 1] = '' then
      begin
        SelectCell(k div cols + 1, k mod cols + 1);
        Exit
      end
    end
  end;

begin
  CloseMenus;
  DrawWindow;
  rows := ReadDimension(64, RowsPrompt, 12);
  if rows = 0 then
    Exit;
  cols := ReadDimension(78, ColsPrompt, 6);
  if cols = 0 then
    Exit;
  Eraser(35, 62, GetMaxX - 35, 26, White, 3);

  Str(rows, o);
  Str(cols, p);
  SetColor(Red);
  SetTextStyle(DefaultFont, HorizDir, 2);
  OutCentered(64, 'լրացրեք ' + o + 'x' + p + ' չափանի մատրիցը');

  { the grid: cells up to 100 wide and 40 tall, as many as fit; a cell's 11 characters are 88 pixels wide }
  w := GridWidth div cols;
  if w > 100 then
    w := 100;
  tx := (w - 88) div 2;
  h := GridHeight div rows;
  if h > 40 then
    h := 40;
  left := divx - cols * w div 2;
  top := GridTop + (GridHeight - rows * h) div 2;
  SetColor(Green);
  SetLineStyle(SolidLn, 0, ThickWidth);
  Rectangle(left - 2, top - 2, left + cols * w + 2, top + rows * h + 2);
  SetFillStyle(SolidFill, Yellow);
  Bar(left, top, left + cols * w, top + rows * h);
  SetLineStyle(SolidLn, 0, NormWidth);
  SetColor(LightRed);
  for i := 1 to rows - 1 do
    Line(left, top + i * h, left + cols * w, top + i * h);
  for i := 1 to cols - 1 do
    Line(left + i * w, top, left + i * w, top + rows * h);

  for i := 1 to rows do
    for j := 1 to cols do
      cells[i, j] := '';
  ci := 1;
  cj := 1;
  noted := False;
  DrawCell(1, 1, True);
  cancel := False;
  done := False;
  repeat
    if WaitInput(ch, Ext, mx, my) then
    begin
      if Ext then
        case ch of
          ScanUp: SelectCell(ci - 1, cj);
          ScanDown: SelectCell(ci + 1, cj);
          ScanLeft: SelectCell(ci, cj - 1);
          ScanRight: SelectCell(ci, cj + 1)
        end
      else if ch = KeyEsc then
        cancel := True
      else if ch = KeyEnter then
      begin
        msg := NumberProblem(cells[ci, cj]);
        if msg <> '' then
          FlashError(msg)
        else
          NextCell
      end
      else if ch = KeySpace then
      begin
        if Filled then
          done := True
        else
          FlashError('լրացրեք մատրիցի բոլոր վանդակները')
      end
      else if ch = KeyBackspace then
      begin
        if cells[ci, cj] <> '' then
        begin
          Delete(cells[ci, cj], Length(cells[ci, cj]), 1);
          DrawCell(ci, cj, True)
        end
      end
      else
      begin
        msg := AddToNumber(cells[ci, cj], ch);
        if msg <> '' then
          FlashError(msg)
        else
          DrawCell(ci, cj, True)
      end
    end
    else if OnClose(mx, my) then
      cancel := True
    else
      for i := 1 to rows do
        for j := 1 to cols do
          if InRect(mx, my, CellLeft(j), CellTop(i), CellLeft(j) + w, CellTop(i) + h) then
            SelectCell(i, j);
    Note(Filled)
  until cancel or done;
  if cancel then
    Exit;
  Note(False);
  DrawCell(ci, cj, False);

  { save the matrix, wiping each cell as it is written; the more cells, the quicker }
  pause := 75 div (rows * cols);
  if pause > 3 then
    pause := 3;
  Assign(f, HomeFile('547.TXT'));
  {$I-}
  Rewrite(f);
  WriteLn(f, o + ' ' + p);
  for i := 1 to rows do
  begin
    textLine := '';
    for j := 1 to cols do
    begin
      Eraser(CellLeft(j) + 2, TextTop(i), CellLeft(j) + w - 2, 8, Yellow, pause);
      textLine := textLine + cells[i, j] + ' '
    end;
    WriteLn(f, textLine)
  end;
  Close(f);
  {$I+}
  if IOResult <> 0 then
  begin
    FileError('Չհաջողվեց պահպանել 547.TXT ֆայլը');
    Exit
  end;

  { read it back and show each number again }
  {$I-}
  Reset(f);
  ReadLn(f, textLine);
  {$I+}
  fileRows := 0;
  fileCols := 0;
  if IOResult = 0 then
  begin
    Val(Copy(textLine, 1, Pos(' ', textLine) - 1), fileRows, code);
    Delete(textLine, 1, Pos(' ', textLine));
    Val(textLine, fileCols, code)
  end;
  if (fileRows <> rows) or (fileCols <> cols) then
  begin
    {$I-}
    Close(f);
    {$I+}
    code := IOResult;                { a file that never opened cannot be closed either }
    FileError('Չհաջողվեց կարդալ 547.TXT ֆայլը');
    Exit
  end;
  SetColor(Brown);
  SetTextStyle(DefaultFont, HorizDir, 1);
  {$I-}
  for i := 1 to rows do
  begin
    ReadLn(f, textLine);
    for j := 1 to cols do
    begin
      s := Copy(textLine, 1, Pos(' ', textLine) - 1);
      Val(s, values[i, j], code);
      OutTextXY(CellLeft(j) + tx, TextTop(i), s);
      Delete(textLine, 1, Pos(' ', textLine));
      if rows * cols <= 15 then
        Delay(200)
      else
        Delay(3000 div (rows * cols))
    end
  end;
  Close(f);
  {$I+}
  if IOResult <> 0 then
  begin
    FileError('Չհաջողվեց կարդալ 547.TXT ֆայլը');
    Exit
  end;

  { for each row, count the equal pairs: every element is compared with the whole row }
  for i := 1 to rows do
  begin
    for j := 1 to cols do
      row[j] := values[i, j];
    counts[i] := 0;
    for j := 1 to cols do
      counts[i] := counts[i] + CountEqual(row, cols, row[j])
  end;
  best := MaxElement(counts, rows);
  answerRow := rows;
  while counts[answerRow] <> best do
    answerRow := answerRow - 1;
  if best = cols then                { each element only matched itself }
    s := 'այդպիսի տող չկա'
  else
    Str(answerRow, s);
  SetColor(Green);
  SetTextStyle(DefaultFont, HorizDir, 2);
  OutCentered(HintY - 2, 'Պատասխան` ' + s);

  SetColor(Red);
  SetTextStyle(DefaultFont, HorizDir, 1);
  OutCentered(NoteY, 'Սեղմեք Space դուրս գալու համար');
  repeat
    if WaitInput(ch, Ext, mx, my) then
      done := not Ext and ((ch = KeySpace) or (ch = KeyEsc) or (ch = KeyEnter))
    else
      done := OnClose(mx, my)
  until done
end;

{ ===== the fake Blue Screen ===== }

procedure BlueScreen;
{ a Windows XP crash screen; three key presses, then a winking smiley }
var
  i: Integer;
begin
  HideGrCursor;
  ClearDevice;
  SetBkColor(Blue);
  SetColor(White);
  SetTextStyle(DefaultFont, HorizDir, 1);
  OutTextXY(0, 10, 'A problem has been detected and windows has been shut down to prevent damage');
  OutTextXY(0, 25, 'to your computer.');
  OutTextXY(0, 50, 'DRIVER_IRQL_NOT_LESS_OR_EQUAL');
  OutTextXY(0, 75, 'If this is the first time you' + #39 + 've seen this stop error screen,');
  OutTextXY(0, 90, 'restart your computer, If this screen appears again, follow');
  OutTextXY(0, 105, 'these steps:');
  OutTextXY(0, 130, 'Check to make sure any new hardware or software is properly installed.');
  OutTextXY(0, 145, 'If this is a new installation, ask your hardware or software manufacturer');
  OutTextXY(0, 160, 'for any windows updates you might need.');
  OutTextXY(0, 185, 'If problems continue, disable or remove any newly installed hardware');
  OutTextXY(0, 200, 'or software. Disable BIOS memory options such as caching or shadowing.');
  OutTextXY(0, 215, 'If you need to use Safe Mode to remove or disable components, restart');
  OutTextXY(0, 230, 'your computer, press F8 to select Advanced Startup Options, and then');
  OutTextXY(0, 245, 'select Safe Mode.');
  OutTextXY(0, 270, 'Technical information:');
  OutTextXY(0, 285, '*** Stop: 0x000000D1 (0x00000000C,0x00000002,0x00000000,0xF86B5A89)');
  OutTextXY(0, 335, '***       gv3.sys - Address F86B5A89 base at F86B50000, DateStamp 3dd991eb');
  OutTextXY(0, 360, 'Beginning dump of physical memory');
  OutTextXY(0, 375, 'Physical memory dump complete.');
  OutTextXY(0, 390, 'Contact your system administrator or technical support group for further');
  OutTextXY(0, 405, 'assistance.');
  WaitKey;
  WaitKey;
  WaitKey;
  SetBkColor(Black);
  ClearDevice;
  SetTextStyle(DefaultFont, HorizDir, 10);
  for i := 15 downto 0 do
  begin
    SetColor(i);
    OutTextXY(divx - 60, divy - 40, ';');
    OutTextXY(divx - 20, divy - 35, ']');
    Delay(200)
  end;
  ClearDevice
end;

{ ===== the desktop ===== }

procedure DrawWallpaper;
{ also closes the Start menu, its submenu and the task window }
begin
  MenuOpen := False;
  SubmenuOpen := False;
  TaskWindowOpen := False;
  Selected := 0;
  SubSelected := 0;
  SetFillStyle(SolidFill, White);
  Bar(0, 0, GetMaxX, GetMaxY - 38);
  SetTextStyle(DefaultFont, HorizDir, 9);
  SetColor(Green);
  OutCentered(divy - 50, 'Մթ-240')
end;

procedure DrawTaskbar;
begin
  SetFillStyle(SolidFill, DarkGray);
  SetLineStyle(SolidLn, 0, NormWidth);
  Bar(0, GetMaxY - 37, GetMaxX, GetMaxY);
  { the round Start button with four coloured squares }
  SetFillStyle(SolidFill, Cyan);
  SetColor(Black);
  FillEllipse(26, GetMaxY - 18, 18, 18);
  SetFillStyle(SolidFill, DarkGray);
  Bar(16, GetMaxY - 28, 36, GetMaxY - 8);
  SetFillStyle(SolidFill, Red);
  Bar(17, GetMaxY - 27, 25, GetMaxY - 19);
  SetFillStyle(SolidFill, Blue);
  Bar(17, GetMaxY - 17, 25, GetMaxY - 9);
  SetFillStyle(SolidFill, Green);
  Bar(27, GetMaxY - 27, 35, GetMaxY - 19);
  SetFillStyle(SolidFill, LightRed);
  Bar(27, GetMaxY - 17, 35, GetMaxY - 9);
  ClockText := ''                    { the bar painted over the clock }
end;

procedure PaintStartMenu;
{ the picture of the Start menu, painted once at the start, as it takes a while to draw }
begin
  SetFillStyle(SolidFill, DarkGray);
  Bar(0, GetMaxY - 253, 153, GetMaxY - 39);
  SetFillStyle(SolidFill, White);
  Bar(3, GetMaxY - 250, 150, GetMaxY - 41);

  { Turbo Pascal icon }
  SetFillStyle(SolidFill, Black);
  Bar(10, GetMaxY - 243, 42, GetMaxY - 211);
  SetFillStyle(InterleaveFill, Red);
  Bar(15, GetMaxY - 240, 40, GetMaxY - 215);
  SetColor(Yellow);
  SetTextStyle(DefaultFont, HorizDir, 2);
  OutTextXY(12, GetMaxY - 233, 'TP');

  { Tron icon }
  SetColor(Blue);
  SetLineStyle(SolidLn, 0, ThickWidth);
  SetFillStyle(SolidFill, Black);
  FillEllipse(26, GetMaxY - 190, 16, 16);
  SetColor(White);
  OutTextXY(20, GetMaxY - 195, 'T');

  { Problem 547 icon, and the arrow that opens its submenu }
  Bar(10, GetMaxY - 161, 42, GetMaxY - 145);
  SetColor(Black);
  OutTextXY(12, GetMaxY - 165, '?');
  SetColor(Red);
  OutTextXY(14, GetMaxY - 163, '?');
  SetColor(Black);
  OutTextXY(28, GetMaxY - 165, '!');
  SetColor(Green);
  OutTextXY(30, GetMaxY - 163, '!');
  SetColor(Black);
  SetLineStyle(SolidLn, 0, NormWidth);
  Line(133, GetMaxY - 160, 133, GetMaxY - 152);
  Line(134, GetMaxY - 159, 137, GetMaxY - 156);
  Line(134, GetMaxY - 153, 136, GetMaxY - 155);

  { separator and the Exit icon }
  SetLineStyle(SolidLn, 0, 2);
  SetColor(DarkGray);
  Line(3, GetMaxY - 90, 150, GetMaxY - 90);
  SetFillStyle(SolidFill, Red);
  Bar(10, GetMaxY - 80, 42, GetMaxY - 48);
  SetColor(White);
  SetLineStyle(SolidLn, 0, ThickWidth);
  FillEllipse(27, GetMaxY - 64, 12, 12);
  Line(26, GetMaxY - 68, 26, GetMaxY - 60);

  SetColor(Black);
  SetTextStyle(DefaultFont, HorizDir, 1);
  OutTextXY(50, GetMaxY - 230, 'Turbo Pascal');
  OutTextXY(50, GetMaxY - 192, 'Tron');
  OutTextXY(50, GetMaxY - 160, 'Խնդիր 547');
  OutTextXY(50, GetMaxY - 65, 'Ելք')
end;

procedure DrawStartMenu;
{ the Start menu, put up at once from its picture, keeping the desktop under it to put back when it closes }
begin
  GetImage(0, GetMaxY - 253, 153, GetMaxY - 39, MenuBack^);
  PutImage(0, GetMaxY - 253, MenuImage^, NormalPut);
  MenuOpen := True;
  Selected := 0
end;

procedure PaintProblemMenu;
{ the picture of the submenu next to Problem 547, the task and its solution, painted once at the start }
begin
  SetColor(DarkGray);
  SetLineStyle(SolidLn, 0, NormWidth);
  Rectangle(153, GetMaxY - 181, 305, GetMaxY - 132);
  SetFillStyle(SolidFill, White);
  Bar(154, GetMaxY - 180, 304, GetMaxY - 133);
  SetFillStyle(SolidFill, Black);    { the icons on black, like Problem 547's in the Start menu }
  SetTextStyle(DefaultFont, HorizDir, 2);
  Bar(159, GetMaxY - 175, 175, GetMaxY - 159);
  SetColor(Red);
  OutTextXY(161, GetMaxY - 174, '?');
  Bar(159, GetMaxY - 154, 175, GetMaxY - 138);
  SetColor(Green);
  OutTextXY(161, GetMaxY - 153, '!');
  SetColor(Black);
  SetTextStyle(DefaultFont, HorizDir, 1);
  OutTextXY(181, GetMaxY - 170, 'Պահանջ');
  OutTextXY(181, GetMaxY - 149, 'Լուծում')
end;

procedure DrawProblemMenu;
{ the submenu, put up at once from its picture, keeping what it covers to put back when it closes }
begin
  GetImage(153, GetMaxY - 181, 305, GetMaxY - 132, SubmenuBack^);
  PutImage(153, GetMaxY - 181, SubmenuImage^, NormalPut);
  SubmenuOpen := True;
  SubSelected := 0
end;

procedure DrawDesktop;
{ the whole desktop again, after something that filled the screen }
begin
  DrawWallpaper;
  DrawTaskbar
end;

procedure ShowTaskText;
{ the window with the task statement; its red x closes it }
begin
  CloseMenus;
  TaskWindowOpen := True;
  DrawWindow;
  ShowCursor;                        { where it was: the text types around it }
  TypeText(30, 70, Green, 1, 'Պահանջ`');
  TypeText(30, 85, Blue, 1, 'Տրված է MxN չափանի մատրիցը: Արտածել մատրիցի այն վերջին տողի համարը,');
  TypeText(30, 100, Blue, 1, 'որը պարունակում է մեծագույն քանակությամբ իրար հավասար տարրեր:');
  TypeText(30, 140, Green, 1, 'Ենթածրագրեր`');
  TypeText(30, 155, Blue, 1, '1.Հաշվել վեկտորի a-ին հավասար տարրերի քանակը:');
  TypeText(30, 170, Blue, 1, '2.Հաշվել վեկտորի մեծագույն տարրը:')
end;

procedure MarkItem(item: Integer; color: Word);
{ frame Start menu item 1-4, or submenu item 5-6, in color; white takes the frame away again }
var
  b, x1, y1, x2, y2: Integer;
begin
  b := GetMaxY;
  x1 := 6;
  x2 := 148;
  case item of
    1: begin y1 := b - 245; y2 := b - 209 end;
    2: begin y1 := b - 207; y2 := b - 171 end;
    3: begin y1 := b - 168; y2 := b - 140 end;
    4: begin y1 := b - 83; y2 := b - 45 end;
    5: begin x1 := 156; x2 := 302; y1 := b - 178; y2 := b - 157 end;
    6: begin x1 := 156; x2 := 302; y1 := b - 156; y2 := b - 135 end
  end;
  SetColor(color);
  SetLineStyle(SolidLn, 0, NormWidth);
  Rectangle(x1, y1, x2, y2);
  Rectangle(x1 + 1, y1 + 1, x2 - 1, y2 - 1)
end;

procedure SelectItem(item: Integer);
{ move the keys' mark in the Start menu to item }
begin
  if Selected > 0 then
    MarkItem(Selected, White);
  Selected := item;
  MarkItem(Selected, Blue)
end;

procedure SelectSubitem(item: Integer);
{ move the keys' mark in the submenu of Problem 547 to item }
begin
  if SubSelected > 0 then
    MarkItem(SubSelected + 4, White);
  SubSelected := item;
  MarkItem(SubSelected + 4, Blue)
end;

function DesktopKey(ch: Char; Ext: Boolean): Integer;
{ what a key does on the desktop. Esc, Space, Enter, an arrow or W A S D opens the Start menu; Esc, Space or Enter
  closes the task window. In the menu,
  up and down (or W and S) move the mark, Enter or Space opens the item marked, right (or D) opens the submenu of
  Problem 547 and Esc closes the menu; in the submenu, left (or A) and Esc close it. Moving the mark gives actNone }
var
  way: Char;
  enter, esc: Boolean;
begin
  DesktopKey := actNone;
  way := KeyWay(ch, Ext);
  enter := not Ext and ((ch = KeyEnter) or (ch = KeySpace));
  esc := not Ext and (ch = KeyEsc);
  if TaskWindowOpen then
  begin
    if enter or esc then
      DesktopKey := actClose
  end
  else if not MenuOpen then
  begin
    if enter or esc or (way <> #0) then
      DesktopKey := actOpenMenu
  end
  else if SubmenuOpen then
  begin
    if esc or (way = ScanLeft) then
      DesktopKey := actCloseSubmenu
    else if enter and (SubSelected = 1) then
      DesktopKey := actTaskText
    else if enter and (SubSelected = 2) then
      DesktopKey := actSolve
    else if enter or (way = ScanUp) or (way = ScanDown) then
    begin
      HideGrCursor;
      if SubSelected = 1 then
        SelectSubitem(2)
      else
        SelectSubitem(1);
      ShowCursor
    end
  end
  else if esc then
    DesktopKey := actClose
  else if (way = ScanRight) and (Selected = 3) then
    DesktopKey := actProblemMenu
  else if enter and (Selected > 0) then
    case Selected of
      1: DesktopKey := actBlueScreen;
      2: DesktopKey := actTron;
      3: DesktopKey := actProblemMenu;
      4: DesktopKey := actExit
    end
  else if enter or (way = ScanUp) or (way = ScanDown) then
  begin
    HideGrCursor;
    if (way = ScanUp) and (Selected <= 1) then
      SelectItem(4)
    else if way = ScanUp then
      SelectItem(Selected - 1)
    else
      SelectItem(Selected mod 4 + 1);
    ShowCursor
  end
end;

function DesktopAction(x, y: Integer): Integer;
{ what a left click at (x, y) does }
var
  b: Integer;
begin
  b := GetMaxY;
  if not MenuOpen and InRect(x, y, 8, b - 36, 44, b) then
    DesktopAction := actOpenMenu
  else if SubmenuOpen and InRect(x, y, 159, b - 175, 304, b - 159) then
    DesktopAction := actTaskText
  else if SubmenuOpen and InRect(x, y, 159, b - 154, 304, b - 138) then
    DesktopAction := actSolve
  else if MenuOpen and not InRect(x, y, 0, b - 253, 153, b - 41) then
    DesktopAction := actClose
  else if TaskWindowOpen and OnClose(x, y) then
    DesktopAction := actClose
  else if MenuOpen and InRect(x, y, 10, b - 243, 150, b - 211) then
    DesktopAction := actBlueScreen
  else if MenuOpen and InRect(x, y, 10, b - 206, 150, b - 174) then
    DesktopAction := actTron
  else if MenuOpen and InRect(x, y, 10, b - 161, 150, b - 145) then
  begin
    if SubmenuOpen then              { a second click on Problem 547 closes its submenu again }
      DesktopAction := actCloseSubmenu
    else
      DesktopAction := actProblemMenu
  end
  else if MenuOpen and InRect(x, y, 10, b - 80, 150, b - 48) then
    DesktopAction := actExit
  else if SubmenuOpen then           { a click elsewhere in the Start menu closes the submenu }
    DesktopAction := actCloseSubmenu
  else
    DesktopAction := actNone
end;

var
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
          SolveProblem;
          DrawDesktop
        end
    end;
    if KeyMode then                  { an action may have moved the cursor itself, as the task window does }
      Buttons := ReadGrCursor(KeyX, KeyY)
  until Action = actExit;
  CloseGraph
end.
