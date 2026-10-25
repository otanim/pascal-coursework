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
  TMatrix = array[1..5, 1..5] of Real;
  TRow = array[1..5] of Real;
  TCounts = array[1..5] of Integer;
  TNumberText = string[11];          { a minus, 9 digits and a point }

  TStroke = record
    X, Y: Integer;                   { first square, in 6-pixel steps from the screen centre }
    Path: string[67];                { numpad moves: 8 up, 2 down, 4 left, 6 right, 7 9 1 3 diagonal,
                                       5 draws the same square again }
  end;

  TOption = record
    X1, Y1, X2, Y2: Integer;         { box }
    TX, TY: Integer;                 { caption position }
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
  MouseX, MouseY: Integer;
  MouseDown: Boolean;                { the left button was down at the previous check }
  MenuOpen, SubmenuOpen, TaskWindowOpen: Boolean;
  ClockText: string[8];

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
{ wait for a fresh key press: drop keys already typed or still held down }
var
  ch: Char;
  Ext: Boolean;
begin
  repeat
    while KeyPressed do
      ch := ReadKey;
    Delay(300)
  until not KeyPressed;
  GetKey(ch, Ext)
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

procedure OutCentered(y: Integer; s: string);
{ s centred on the screen in the current text style }
begin
  OutTextXY(divx - TextWidth(s) div 2, y, s)
end;

procedure TypeText(x0, y0: Integer; color: Word; size: Word; s: string);
{ write s one character at a time, like a typewriter }
var
  i: Integer;
begin
  SetTextStyle(DefaultFont, HorizDir, size);
  SetColor(color);
  for i := 1 to Length(s) do
  begin
    OutTextXY(x0 + i * 8 * size, y0, s[i]);
    Delay(10)
  end
end;

function InRect(x, y, x1, y1, x2, y2: Integer): Boolean;
begin
  InRect := (x >= x1) and (x <= x2) and (y >= y1) and (y <= y2)
end;

{ ===== menus ===== }

procedure SetOption(var o: TOption; x1, y1, x2, y2, tx, ty: Integer; caption: string);
begin
  o.X1 := x1;
  o.Y1 := y1;
  o.X2 := x2;
  o.Y2 := y2;
  o.TX := tx;
  o.TY := ty;
  o.Caption := caption
end;

procedure DrawMenu(var m: TMenu; selected: Integer);
{ selected = 0 draws every option grey, for a menu that is waiting behind another one }
var
  i: Integer;
begin
  SetTextStyle(DefaultFont, HorizDir, m.TextSize);
  for i := 1 to m.Count do
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
      OutTextXY(TX, TY, Caption)
    end
end;

function Choose(var m: TMenu): Integer;
{ pick an option with the arrow keys and Enter or Space; Esc gives 0 }
var
  k: Integer;
  ch, prevKey, nextKey: Char;
  Ext: Boolean;
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
  repeat
    DrawMenu(m, k);
    GetKey(ch, Ext);
    if Ext and (ch = nextKey) then
      k := k mod m.Count + 1
    else if Ext and (ch = prevKey) then
      k := (k + m.Count - 2) mod m.Count + 1
  until not Ext and ((ch = KeyEnter) or (ch = KeySpace) or (ch = KeyEsc));
  if ch = KeyEsc then
    Choose := 0
  else
    Choose := k
end;

procedure BuildTronMenu(var m: TMenu);
begin
  m.Count := 4;
  m.TextSize := 1;
  m.Vertical := False;
  SetOption(m.Items[1], 80, divy, 180, divy + 50, 90, divy + 20, '1 խաղացող');
  SetOption(m.Items[2], 205, divy, 305, divy + 50, 210, divy + 20, '2 խաղացող');
  SetOption(m.Items[3], 330, divy, 433, divy + 50, 340, divy + 20, 'Պայմաններ');
  SetOption(m.Items[4], 455, divy, 555, divy + 50, 470, divy + 20, 'Ելք')
end;

procedure BuildRoundsMenu(var m: TMenu; x: Integer);
{ the number of rounds, as a column under the chosen mode at x }
begin
  m.Count := 4;
  m.TextSize := 1;
  m.Vertical := True;
  SetOption(m.Items[1], x, divy + 62, x + 80, divy + 92, x + 5, divy + 77, '5  խաղ');
  SetOption(m.Items[2], x, divy + 102, x + 80, divy + 132, x + 5, divy + 117, '10 խաղ');
  SetOption(m.Items[3], x, divy + 142, x + 80, divy + 172, x + 5, divy + 157, '25 խաղ');
  SetOption(m.Items[4], x, divy + 182, x + 80, divy + 212, x + 5, divy + 197, '50 խաղ')
end;

procedure BuildYesNoMenu(var m: TMenu);
begin
  m.Count := 2;
  m.TextSize := 2;
  m.Vertical := False;
  SetOption(m.Items[1], 205, divy, 305, divy + 50, 230, divy + 20, 'Այո');
  SetOption(m.Items[2], 330, divy, 433, divy + 50, 360, divy + 20, 'Ոչ')
end;

{ ===== Tron ===== }

procedure DrawLogo;
{ trace the TRON logo; a key press skips the rest }
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
      if not KeyPressed then
      begin
        Bar(divx + x * 6, divy + y * 6, divx + x * 6 + 5, divy + y * 6 + 5);
        Delay(10)
      end
    end
  end
end;

procedure ShowRules;
{ every control line leaves room at its start for the colour name drawn over it }
var
  s: string;
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
  s := '        խաղացող` վերեւ` ^, ներքեւ` v, աջ` >, ձախ` <:';
  SetColor(LightGray);
  OutCentered(195, s);
  SetColor(Cyan);
  OutTextXY(divx - Length(s) * 4, 195, 'Կապույտ');
  s := '      խաղացող` վերեւ` W, ներքեւ` S, աջ` D, ձախ` A:';
  SetColor(LightGray);
  OutCentered(210, s);
  SetColor(Yellow);
  OutTextXY(divx - Length(s) * 4, 210, 'Դեղին');
  SetColor(LightBlue);
  OutCentered(260, 'Ռեժիմներ');
  s := 'Խաղացողն ընդդեմ համակարգչի: Խաղացողի գույնը`        , համակարգչինը`      :';
  SetColor(LightGray);
  OutCentered(275, s);
  SetColor(Cyan);
  OutTextXY(divx - Length(s) * 4 + 360, 275, 'կապույտ');
  SetColor(Yellow);
  OutTextXY(divx - Length(s) * 4 + 544, 275, 'դեղին');
  s := 'Խաղացողն ընդդեմ խաղացողի: Խաղացողների գույները`       եւ        :';
  SetColor(LightGray);
  OutCentered(290, s);
  SetColor(Yellow);
  OutTextXY(divx - Length(s) * 4 + 385, 290, 'դեղին');
  SetColor(Cyan);
  OutTextXY(divx - Length(s) * 4 + 456, 290, 'կապույտ');
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
        OutTextXY(divx - 250, divy - 20, 'Կապույտը հաղթեց!')
      end
      else if blueScore < yellowScore then
      begin
        SetColor(Yellow);
        OutTextXY(divx - 225, divy - 20, 'Դեղինը հաղթեց!')
      end;
      WaitKey;
      ClearDevice;
      SetTextStyle(DefaultFont, HorizDir, 3);
      SetColor(Red);
      OutTextXY(divx - 95, divy - 50, 'Նոր խա՞ղ');
      BuildYesNoMenu(yesNo);
      again := Choose(yesNo) = 1;
      ClearDevice
    end
  until not again;
  ClearDevice
end;

procedure TronMenu;
{ the logo, then the Tron menu until Exit or Esc }
var
  modes, rounds: TMenu;
  choice: Integer;
  ch: Char;
  Ext: Boolean;
begin
  HideGrCursor;
  ClearDevice;
  DrawLogo;
  GetKey(ch, Ext);                   { takes the key that skipped the logo, or waits for one }
  ClearDevice;
  BuildTronMenu(modes);
  repeat
    choice := Choose(modes);
    if (choice = 1) or (choice = 2) then
    begin
      OnePlayer := choice = 1;
      DrawMenu(modes, 0);
      if OnePlayer then
        BuildRoundsMenu(rounds, 90)
      else
        BuildRoundsMenu(rounds, 215);
      case Choose(rounds) of
        1: PlayMatch(5);
        2: PlayMatch(10);
        3: PlayMatch(25);
        4: PlayMatch(50)
      end;
      ClearDevice
    end
    else if choice = 3 then
      ShowRules
  until (choice = 4) or (choice = 0);
  ClearDevice
end;

{ ===== Problem 547 ===== }

procedure FlashError(s: string);
{ a short red hint under the matrix }
begin
  SetColor(Red);
  OutCentered(450, s);
  Delay(200);
  SetColor(Black);
  OutCentered(450, s)
end;

procedure FileError(s: string);
{ why 547.TXT failed; waits for a key }
begin
  SetTextStyle(DefaultFont, HorizDir, 1);
  SetColor(Red);
  OutCentered(GetMaxY - 60, s);
  WaitKey
end;

procedure Eraser(x1, y1, x2, h: Integer; color: Word);
{ paint x1..x2 by y1..y1+h in color, one vertical line at a time }
var
  x: Integer;
begin
  SetColor(color);
  for x := x1 to x2 do
  begin
    Line(x, y1, x, y1 + h);
    Delay(3)
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

function ReadDimension(y: Integer; prompt: string): Integer;
{ a number of rows or columns from 2 to 5, typed after prompt; 0 when Esc cancels }
var
  ch: Char;
  Ext: Boolean;
  typed: string[1];
  x: Integer;
begin
  ReadDimension := 0;
  x := divx + Length(prompt) * 4;
  SetColor(Red);
  OutTextXY(divx - Length(prompt) * 4 - 16, y, prompt);
  SetColor(LightBlue);
  OutTextXY(x, y, '_');
  typed := '';
  repeat
    GetKey(ch, Ext);
    if Ext then
      ch := #0;
    SetColor(Black);
    OutTextXY(x, y, '_');
    if ch = KeyEsc then
      Exit
    else if (ch >= '2') and (ch <= '5') and (typed = '') then
    begin
      typed := ch;
      SetColor(LightBlue);
      OutTextXY(x, y, typed)
    end
    else if ch = KeyBackspace then
    begin
      SetColor(Black);
      OutTextXY(x, y, typed);
      typed := ''
    end
    else if (ch = KeyEnter) and (typed = '') then
    begin
      FlashError('գրեք թիվ');
      ch := #0
    end
  until ch = KeyEnter;
  ReadDimension := Ord(typed[1]) - Ord('0')
end;

function ReadCell(rows, cols, i, j: Integer; var txt: TNumberText): Boolean;
{ the number in cell (i, j), counted from 0; False when Esc cancels }
var
  x, y, k, digits, t: Integer;
  dot, Ext: Boolean;
  ch: Char;
begin
  ReadCell := False;
  x := divx - cols * 50 + j * 100 + 10;
  y := divy - rows * 25 - 50 + i * 50 + 20;
  k := 0;
  txt := '';
  dot := False;
  repeat
    SetTextStyle(DefaultFont, HorizDir, 1);
    SetColor(Brown);
    if k <= 10 then                  { a full cell has no room for the cursor before the grid line }
      OutTextXY(x + k * 8, y, '_');
    GetKey(ch, Ext);
    if Ext then
      ch := #0;
    SetColor(Yellow);
    if k <= 10 then
      OutTextXY(x + k * 8, y, '_');
    digits := 0;                     { the minus and the point do not count }
    for t := 1 to Length(txt) do
      if txt[t] in ['0'..'9'] then
        digits := digits + 1;

    if ch = KeyEsc then
      Exit
    else if ch = KeyEnter then
    begin
      if (txt = '') or (txt = '-') then
      begin
        FlashError('խնդրո՛ւմ ենք ավարտել թվի մուտքագրում, դուք դեռ չեք վերջացրել');
        ch := #0
      end
      else if (Pos('.', txt) <> 0) and (txt[Length(txt)] = '0') then
      begin
        FlashError('խնդրո՛ւմ ենք կոտորակային թվից հետո չգրել ավելորդ զրոներ');
        ch := #0
      end
      else if txt[Length(txt)] = '.' then
      begin
        FlashError('խնդրո՛ւմ ենք մուտքագրեք ճիշտ թիվ');
        ch := #0
      end
    end
    else if ch = KeyBackspace then
    begin
      if k <> 0 then
      begin
        k := k - 1;
        if txt[Length(txt)] = '.' then
          dot := False;
        SetColor(Yellow);
        OutTextXY(x + k * 8, y, txt[Length(txt)]);
        Delete(txt, Length(txt), 1);
        SetColor(Brown);
        OutTextXY(x, y, txt)
      end
    end
    else if (ch = '-') and (txt <> '') then
      FlashError('մինուսի նշանը դնում են թվի սկզբում ;)')
    else if (txt = '') and (ch = '.') then
      FlashError('Նախքան կետի նշան դնելը, թիվ գրեք')
    else if (txt = '-') and (ch = '.') then
      FlashError('մինուս նշանից հետո գրեք թիվ, այլ ոչ կետ...')
    else if (ch = '.') and dot then
      FlashError('կրկնակի մի դրեք կետի նշան')
    else if ((txt = '0') or (txt = '-0')) and (ch <> '.') then
      FlashError('զրոյից հետո չմոռանաք դնել կետի նշանը')
    else if not (ch in ['0'..'9', '-', '.']) then
      FlashError('թիվ, ասեցինք թի՛վ գրեք')
    else if (ch in ['0'..'9']) and (digits >= 9) then
      FlashError('Թվանշանների քանակը չպե՛տք է գերազանցի 9-ը')
    else
    begin
      if ch = '.' then
        dot := True;
      txt := txt + ch;
      SetColor(Brown);
      OutTextXY(x + k * 8, y, ch);
      k := k + 1
    end
  until ch = KeyEnter;
  ReadCell := True
end;

procedure SolveProblem;
{ type a matrix, save it to 547.TXT, read it back and show the last row with the most equal elements }
const
  RowsPrompt = 'մուտքագրեք տողերի քանակը 2-ից 5 միջակայքում`';
  ColsPrompt = 'մուտքագրեք սյուների քանակը 2-ից 5 միջակայքում`';
var
  cells: array[1..5, 1..5] of TNumberText;
  values: TMatrix;
  row: TRow;
  counts: TCounts;
  rows, cols, fileRows, fileCols, i, j, best, answerRow, code, left, top: Integer;
  f: Text;
  textLine, s, o, p: string;
  ch: Char;
  Ext: Boolean;
begin
  HideGrCursor;
  ClearDevice;
  SetTextStyle(DefaultFont, HorizDir, 1);
  SetLineStyle(SolidLn, 0, NormWidth);
  rows := ReadDimension(25, RowsPrompt);
  if rows = 0 then
    Exit;
  cols := ReadDimension(40, ColsPrompt);
  if cols = 0 then
    Exit;
  Eraser(divx - Length(ColsPrompt) * 4 - 16, 25, divx + Length(ColsPrompt) * 4 + 16, 40, Black);

  Str(rows, o);
  Str(cols, p);
  SetColor(Red);
  SetTextStyle(DefaultFont, HorizDir, 2);
  OutCentered(25, 'լրացրեք ' + o + 'x' + p + ' չափանի մատրիցը');

  { the grid: cells are 100 x 50 }
  left := divx - cols * 50;
  top := divy - rows * 25 - 50;
  SetColor(Green);
  SetLineStyle(SolidLn, 0, ThickWidth);
  Rectangle(left - 2, top - 2, divx + cols * 50 + 2, divy + rows * 25 - 50 + 2);
  SetFillStyle(SolidFill, Yellow);
  Bar(left, top, divx + cols * 50, divy + rows * 25 - 50);
  SetLineStyle(SolidLn, 0, NormWidth);
  SetColor(LightRed);
  for i := 1 to rows - 1 do
    Line(left, top + i * 50, divx + cols * 50, top + i * 50);
  for i := 1 to cols - 1 do
    Line(left + i * 100, top, left + i * 100, divy + rows * 25 - 50);

  for i := 0 to rows - 1 do
    for j := 0 to cols - 1 do
      if not ReadCell(rows, cols, i, j, cells[i + 1, j + 1]) then
        Exit;

  SetTextStyle(DefaultFont, HorizDir, 1);
  SetColor(Red);
  s := 'Սեղմեք Space տվյալները ֆայլում տպելու համար';
  OutCentered(GetMaxY - 60, s);
  repeat
    GetKey(ch, Ext)
  until not Ext and ((ch = KeySpace) or (ch = KeyEsc));
  if ch = KeyEsc then
    Exit;
  SetColor(Black);
  OutCentered(GetMaxY - 60, s);

  { save the matrix, wiping each cell as it is written }
  Assign(f, HomeFile('547.TXT'));
  {$I-}
  Rewrite(f);
  WriteLn(f, o + ' ' + p);
  for i := 1 to rows do
  begin
    textLine := '';
    for j := 1 to cols do
    begin
      Eraser(left + (j - 1) * 100 + 10, top + (i - 1) * 50 + 20, left + (j - 1) * 100 + 90, 16, Yellow);
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
      OutTextXY(left + (j - 1) * 100 + 10, top + (i - 1) * 50 + 20, s);
      Delete(textLine, 1, Pos(' ', textLine));
      Delay(200)
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
  OutCentered(divy + 120, 'Պատասխան` ' + s);

  SetColor(Red);
  SetTextStyle(DefaultFont, HorizDir, 1);
  OutCentered(GetMaxY - 60, 'Սեղմեք Space դուրս գալու համար');
  repeat
    GetKey(ch, Ext)
  until not Ext and ((ch = KeySpace) or (ch = KeyEsc));
  ClearDevice
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
  SetFillStyle(SolidFill, White);
  Bar(0, 0, GetMaxX, GetMaxY - 37);
  SetTextStyle(DefaultFont, HorizDir, 9);
  SetColor(Green);
  OutTextXY(divx - 225, divy - 50, 'Մթ-240')
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

procedure DrawClock;
{ redraw the clock in the taskbar when the time has changed }
var
  h, m, s, hundredths: Word;
  t: string[8];
  nearCursor: Boolean;
begin
  GetTime(h, m, s, hundredths);
  t := TwoDigits(h) + ':' + TwoDigits(m) + ':' + TwoDigits(s);
  if t <> ClockText then
  begin
    nearCursor := (MouseX >= GetMaxX - 90) and (MouseY >= GetMaxY - 40);
    if nearCursor then
      HideGrCursor;
    SetTextStyle(DefaultFont, HorizDir, 1);
    SetColor(DarkGray);
    OutTextXY(GetMaxX - 70, GetMaxY - 20, ClockText);
    SetColor(White);
    OutTextXY(GetMaxX - 70, GetMaxY - 20, t);
    if nearCursor then
      ShowGrCursor;
    ClockText := t
  end
end;

procedure DrawStartMenu;
begin
  MenuOpen := True;
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
  SetColor(Yellow);
  OutTextXY(14, GetMaxY - 163, '?');
  SetColor(Black);
  OutTextXY(28, GetMaxY - 165, '!');
  SetColor(Red);
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

procedure DrawProblemMenu;
{ the submenu next to Problem 547: the task and its solution }
begin
  SubmenuOpen := True;
  SetColor(DarkGray);
  SetLineStyle(SolidLn, 0, NormWidth);
  Rectangle(153, GetMaxY - 181, 305, GetMaxY - 132);
  SetFillStyle(SolidFill, White);
  Bar(154, GetMaxY - 180, 304, GetMaxY - 133);
  SetFillStyle(SolidFill, LightBlue);
  SetTextStyle(DefaultFont, HorizDir, 2);
  Bar(159, GetMaxY - 175, 175, GetMaxY - 159);
  SetColor(Yellow);
  OutTextXY(161, GetMaxY - 174, '?');
  Bar(159, GetMaxY - 154, 175, GetMaxY - 138);
  SetColor(Red);
  OutTextXY(161, GetMaxY - 153, '!');
  SetColor(Black);
  SetTextStyle(DefaultFont, HorizDir, 1);
  OutTextXY(181, GetMaxY - 170, 'Պահանջ');
  OutTextXY(181, GetMaxY - 149, 'Լուծում')
end;

procedure ShowTaskText;
{ the window with the task statement; its red x closes it }
begin
  DrawWallpaper;
  TaskWindowOpen := True;
  SetFillStyle(SolidFill, DarkGray);
  Bar(40, 40, GetMaxX - 40, GetMaxY - 80);
  SetFillStyle(SolidFill, White);
  Bar(50, 70, GetMaxX - 50, GetMaxY - 90);
  SetFillStyle(SolidFill, Red);
  Bar(GetMaxX - 85, 45, GetMaxX - 50, 60);
  SetTextStyle(DefaultFont, HorizDir, 1);
  SetColor(White);
  OutTextXY(GetMaxX - 71, 49, 'x');
  SetGrCursor(20, 20);
  TypeText(divx - 100, 100, Red, 2, 'Խնդիր 547');
  TypeText(45, 130, Green, 1, 'Պահանջ`');
  TypeText(45, 145, Blue, 1, 'Տրված է MxN չափանի մատրիցը: Արտածել մատրիցի այն վերջին տողի համարը,');
  TypeText(45, 160, Blue, 1, 'որը պարունակում է մեծագույն քանակությամբ իրար հավասար տարրեր:');
  TypeText(45, 225, Green, 1, 'Ենթածրագրեր`');
  TypeText(45, 240, Blue, 1, '1.Հաշվել վեկտորի a-ին հավասար տարրերի քանակը:');
  TypeText(45, 255, Blue, 1, '2.Հաշվել վեկտորի մեծագույն տարրը:')
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
  else if TaskWindowOpen and InRect(x, y, GetMaxX - 85, 45, GetMaxX - 50, 60) then
    DesktopAction := actClose
  else if MenuOpen and InRect(x, y, 10, b - 243, 150, b - 211) then
    DesktopAction := actBlueScreen
  else if MenuOpen and InRect(x, y, 10, b - 206, 150, b - 174) then
    DesktopAction := actTron
  else if MenuOpen and InRect(x, y, 10, b - 161, 150, b - 145) then
    DesktopAction := actProblemMenu
  else if MenuOpen and InRect(x, y, 10, b - 80, 150, b - 48) then
    DesktopAction := actExit
  else
    DesktopAction := actNone
end;

var
  GraphDriver, GraphMode, Action, Buttons: Integer;

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
  SetGrCursor(divx, divy - 60);
  DrawWallpaper;
  repeat
    DrawTaskbar;
    ShowGrCursor;
    repeat
      DrawClock;
      Buttons := ReadGrCursor(MouseX, MouseY);
      Action := actNone;
      if (Buttons = 1) and not MouseDown then   { react when the button goes down, not while it is held }
        Action := DesktopAction(MouseX, MouseY);
      MouseDown := Buttons <> 0
    until Action <> actNone;
    HideGrCursor;                    { every action draws; the cursor comes back with the taskbar }
    case Action of
      actOpenMenu: DrawStartMenu;
      actClose: DrawWallpaper;
      actBlueScreen:
        begin
          BlueScreen;
          DrawWallpaper
        end;
      actTron:
        begin
          TronMenu;
          DrawWallpaper
        end;
      actProblemMenu: DrawProblemMenu;
      actTaskText: ShowTaskText;
      actSolve:
        begin
          SolveProblem;
          DrawWallpaper
        end
    end
  until Action = actExit;
  CloseGraph
end.
