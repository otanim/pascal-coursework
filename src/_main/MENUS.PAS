unit Menus;
{ Menus of boxes, chosen with the keys or the mouse: the Tron menu, its rounds and its question of a new game }

interface

type
  TOption = record
    X1, Y1, X2, Y2: Integer;         { box; the caption is centred in it }
    Caption: string[12];
  end;

  TMenu = record
    Count, TextSize: Integer;
    Vertical: Boolean;               { chosen with up/down instead of left/right }
    Current: Integer;                { the option picked out: Choose starts there, and leaves it on the last one }
    OpenDown: set of 1..4;           { options that open a list under them: Down chooses them too }
    UpLeaves: Boolean;               { a list under a menu: Up on its first option goes back to it, as Esc does }
    Items: array[1..4] of TOption;
  end;

procedure SetOption(var o: TOption; x1, y1, x2, y2: Integer; caption: string);
procedure DrawMenu(var m: TMenu; selected: Integer);
procedure DrawMenuOpen(var m: TMenu; open: Integer);
procedure EraseMenu(var m: TMenu);
function Choose(var m: TMenu): Integer;
procedure StartMenu(var m: TMenu; count, size: Integer; vertical: Boolean);

implementation

uses Crt, Graph, GrMouse, Shared;

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

procedure DrawMenuOpen(var m: TMenu; open: Integer);
{ m behind the list its option open opened: that option stays picked out, and the others wait in grey }
var
  i: Integer;
begin
  for i := 1 to m.Count do
    if i = open then
      DrawOption(m, i, i)
    else
      DrawOption(m, i, 0)
end;

procedure EraseMenu(var m: TMenu);
{ the options of m painted over with the black of the screen }
var
  i: Integer;
begin
  SetFillStyle(SolidFill, Black);
  for i := 1 to m.Count do
    with m.Items[i] do
      Bar(X1, Y1, X2, Y2)
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
  it out, and a click, or a tap, chooses it. Down chooses an option that opens a list under it, and Up on the first
  option of such a list gives 0, as Esc does. The menu starts on the option picked out last. The mouse cursor shows
  only while the menu waits }
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
  k := m.Current;
  if (k < 1) or (k > m.Count) then
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
      else if (way = prevKey) and m.UpLeaves and (k = 1) then
        chosen := 0
      else if way = prevKey then
        MoveSelection(m, k, (k + m.Count - 2) mod m.Count + 1)
      else if (way = ScanDown) and not m.Vertical and (k in m.OpenDown) then
        chosen := k;
      if not Ext and ((ch = KeyEnter) or (ch = KeySpace)) then
        chosen := k
      else if not Ext and (ch = KeyEsc) then
        chosen := 0
    end
  until chosen >= 0;
  HideGrCursor;
  if chosen > 0 then
    m.Current := chosen
  else
    m.Current := k;
  Choose := chosen
end;

procedure StartMenu(var m: TMenu; count, size: Integer; vertical: Boolean);
{ a menu of count options with captions at the given size, its first one picked out }
begin
  m.Count := count;
  m.TextSize := size;
  m.Vertical := vertical;
  m.Current := 1;
  m.OpenDown := [];
  m.UpLeaves := False
end;

end.
