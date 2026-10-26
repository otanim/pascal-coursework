unit Tron;
{ Tron: its logo, its menu, its rules and its light-cycle matches, for one player against the computer or two }

interface

procedure TronMenu;

implementation

uses Crt, Graph, GrMouse, Shared, Menus;

const
  { Tron directions }
  DirLeft = 1;
  DirUp = 2;
  DirRight = 3;
  DirDown = 4;

  StepDelay = 10;      { milliseconds between two moves of the light cycles }
  LogoRaise = 30;      { pixels the logo is drawn higher than its strokes say, leaving room for the menu under it }

type
  TStroke = record
    X, Y: Integer;                   { first square, in 6-pixel steps from the screen centre }
    Path: string[67];                { numpad moves: 8 up, 2 down, 4 left, 6 right, 7 9 1 3 diagonal,
                                       5 draws the same square again }
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

var
  Hurried: Boolean;                  { a key or a click cut the Tron logo's tracing, or its pause, short }

  { cycle 1 is cyan (arrow keys), cycle 2 is yellow (WASD or the computer) }
  Xpos1, Ypos1, Npos1: Integer;
  Xpos2, Ypos2, Npos2: Integer;
  OnePlayer, RoundOver, Quit: Boolean;
  Winner: Integer;                   { 1 cyan, 2 yellow, 0 nobody }

procedure BuildTronMenu(var m: TMenu);
{ the modes, which open the number of rounds under them, the rules and Exit }
begin
  StartMenu(m, 4, 1, False);
  m.OpenDown := [1, 2];
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
  StartMenu(m, 4, 1, True);
  m.UpLeaves := True;
  SetOption(m.Items[1], x, divy + 62, x + 80, divy + 92, '5 խաղ');
  SetOption(m.Items[2], x, divy + 102, x + 80, divy + 132, '10 խաղ');
  SetOption(m.Items[3], x, divy + 142, x + 80, divy + 172, '25 խաղ');
  SetOption(m.Items[4], x, divy + 182, x + 80, divy + 212, '50 խաղ')
end;

procedure BuildYesNoMenu(var m: TMenu);
begin
  StartMenu(m, 2, 2, False);
  SetOption(m.Items[1], 207, divy, 307, divy + 50, 'Այո');
  SetOption(m.Items[2], 332, divy, 432, divy + 50, 'Ոչ')
end;

procedure DrawLogo(traced: Boolean);
{ the TRON logo: traced square by square, where a key press or a click draws the rest of it at once and sets Hurried,
  or drawn at once }
var
  s, i, x, y: Integer;
begin
  Hurried := False;
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
      if traced and not Hurried then
      begin
        Hurried := KeyPressed or ButtonDown;
        if not Hurried then
          Delay(10)
      end
    end
  end
end;

procedure ShowRules;
{ the rules in the 8x16 characters, taller than graphics text's 8x8 and narrower than its 16x16, a line under
  another, each centred whole; a colour's name in a line is drawn over again in that colour. Under them, where the
  logo's screen has its prompt, how to go back }
const
  Pitch = 20;                        { from one line to the next; a section has a blank line before it }
  Rows = 14;                         { the 12 lines, and the blank ones before the two later sections }
var
  s: string;
  x, y, lineY: Integer;

  procedure Line(text: string; color: Word);
  { the next line, centred, in color }
  begin
    s := text;
    x := InkStart(0, GetMaxX, s, True, 1);
    lineY := y;
    OutTall(x, lineY, s, color);
    y := y + Pitch
  end;

  procedure Paint(name: string; color: Word);
  { name, where it is in the last line, in color }
  begin
    OutTall(x + (Pos(name, s) - 1) * 8, lineY, name, color)
  end;

begin
  ClearDevice;
  { the rules in the middle of the room over the prompt; the last line is 16 dots tall }
  y := (GetMaxY - 60 - (Rows * Pitch - (Pitch - 16))) div 2;
  Line('Բովանդակություն', Green);
  Line('Խաղի նպատակն է դուրս բերել հակառակորդին կառավարումից:', LightGray);
  Line('Խաղացողը համարվում է հաղթող,', LightGray);
  Line('եթե հակառակորդը բախվել է ինչ-որ խոչընդոտի:', LightGray);
  y := y + Pitch;
  Line('Կառավարում', Brown);
  { the arrows are the font's own, characters 24 to 27 }
  Line('Կապույտ խաղացող` վերեւ` '#24', ներքեւ` '#25', աջ` '#26', ձախ` '#27':', LightGray);
  Paint('Կապույտ', Cyan);
  Line('Դեղին խաղացող` վերեւ` W, ներքեւ` S, աջ` D, ձախ` A:', LightGray);
  Paint('Դեղին', Yellow);
  y := y + Pitch;
  Line('Տարբերակներ', LightBlue);
  Line('Խաղացողն ընդդեմ համակարգչի.', LightGray);
  Line('Խաղացողի գույնը` կապույտ, համակարգչինը` դեղին:', LightGray);
  Paint('կապույտ', Cyan);
  Paint('դեղին', Yellow);
  Line('Խաղացողն ընդդեմ խաղացողի.', LightGray);
  Line('Խաղացողների գույները` դեղին եւ կապույտ:', LightGray);
  Paint('դեղին', Yellow);
  Paint('կապույտ', Cyan);
  SetTextStyle(DefaultFont, HorizDir, 1);
  SetColor(LightGray);
  OutPrompt(GetMaxY - 60, 'Սեղմեք ցանկացած ստեղն գլխավոր ընտրացանկ վերադառնալու համար');
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
  ch: Char;
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
        { the next round on a key or a click; Esc leaves the match, as it does in a round }
        WaitFor(ch);
        Quit := ch = KeyEsc
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
  MatchRounds: array[1..4] of Integer = (5, 10, 25, 50);
  Prompt = 'Սեղմեք ցանկացած ստեղն խաղը սկսելու համար';
var
  modes, rounds: TMenu;
  choice, picked, waited: Integer;
begin
  HideGrCursor;
  ClearDevice;
  DrawLogo(True);
  { the logo alone a moment, to be seen whole }
  waited := 0;
  while not Hurried and (waited < LogoPause) do
  begin
    Delay(10);
    waited := waited + 10;
    Hurried := KeyPressed or ButtonDown
  end;
  BuildTronMenu(modes);
  if Hurried then
  begin
    { a key or a click while the logo was traced or paused: the menu at once, without the prompt. That key or
      click doesn't also choose in it }
    DrawMenu(modes, modes.Current);
    DropInput
  end
  else
  begin
    { the prompt at the foot of the screen; a key or a click takes it away and brings the menu under the logo }
    SetTextStyle(DefaultFont, HorizDir, 1);
    SetColor(LightGray);
    OutPrompt(GetMaxY - 60, Prompt);
    WaitKey;
    SetColor(Black);
    OutCentered(GetMaxY - 60, Prompt)
  end;
  repeat
    choice := Choose(modes);
    if (choice = 1) or (choice = 2) then
    begin
      OnePlayer := choice = 1;
      DrawMenuOpen(modes, choice);
      BuildRoundsMenu(rounds, (modes.Items[choice].X1 + modes.Items[choice].X2) div 2);
      picked := Choose(rounds);
      if picked = 0 then
        { back: the list goes, and the menu takes the keys again on the same mode }
        EraseMenu(rounds)
      else
      begin
        PlayMatch(MatchRounds[picked]);
        ClearDevice;
        DrawLogo(False)
      end
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

end.
