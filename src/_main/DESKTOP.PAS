unit Desktop;
{ The desktop: its wallpaper, taskbar, Start menu and submenu, the task window, what keys and clicks do on it,
  and the fake Blue Screen }

interface

const
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

var
  MenuOpen, SubmenuOpen, TaskWindowOpen: Boolean;
  MenuBack, SubmenuBack: Pointer;    { the desktop under the Start menu and under its submenu, put back as they close }
  MenuImage, SubmenuImage: Pointer;  { the pictures of the Start menu and its submenu, drawn once at the start }

procedure CloseSubmenu;
procedure CloseMenus;
procedure BlueScreen;
procedure DrawWallpaper;
procedure PaintStartMenu;
procedure DrawStartMenu;
procedure PaintProblemMenu;
procedure DrawProblemMenu;
procedure DrawDesktop;
procedure ShowTaskText;
procedure SelectItem(item: Integer);
procedure SelectSubitem(item: Integer);
function DesktopKey(ch: Char; Ext: Boolean): Integer;
function DesktopAction(x, y: Integer): Integer;

implementation

uses Dos, Crt, Graph, GrMouse, Shared, P547;

var
  Selected, SubSelected: Integer;    { the Start menu item and the submenu item the keys marked; 0 for none }

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

end.
