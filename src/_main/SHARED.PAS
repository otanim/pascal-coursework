unit Shared;
{ What the parts of COURSE.EXE share: the keys, the centre of the screen, the mouse and its cursor, which keys and
  taps leave hidden, the graphics driver and the Armenian fonts linked in, centred text, the clock of the taskbar,
  and waiting for a key or a click }

interface

const
  KeyBackspace = #8;
  KeyEnter = #13;
  KeyEsc = #27;
  KeySpace = ' ';
  { scan codes that GetKey returns for the arrow keys }
  ScanUp = #72;
  ScanLeft = #75;
  ScanRight = #77;
  ScanDown = #80;

var
  divx, divy: Integer;               { centre of the screen }
  MouseX, MouseY: Integer;
  KeyMode: Boolean;                  { the mouse cursor is hidden until the mouse moves: at the start, once the keys
                                       work the desktop, and through clicks, as a tap on a touch screen is one }
  KeyX, KeyY: Integer;               { where the mouse was at the last check while its cursor was away }
  MoveCount: Integer;                { the moves of the mouse without a button since MoveTick }
  ClockText: string[8];
  MouseThere: Boolean;               { a mouse driver answered at the start; without one, only keys count }

procedure EgaVgaDriverProc;   { EGAVGA.BGI, linked in }
procedure UseArmenianFont;
procedure GetKey(var ch: Char; var Ext: Boolean);
function ButtonDown: Boolean;
procedure DropInput;
procedure WaitFor(var ch: Char);
procedure WaitKey;
function KeyWay(ch: Char; Ext: Boolean): Char;
procedure ShowCursor;
function ReadMouse: Word;
procedure KeysInUse;
function HomeFile(name: string): string;
function InkStart(x1, x2: Integer; s: string; tall: Boolean; size: Integer): Integer;
function InkX(x1, x2: Integer; s: string): Integer;
procedure OutTall(x, y: Integer; s: string; color: Word);
procedure OutCentered(y: Integer; s: string);
procedure OutPrompt(y: Integer; s: string);
procedure TypeText(x0, y0: Integer; color: Word; size: Word; s: string);
function InRect(x, y, x1, y1, x2, y2: Integer): Boolean;
procedure DrawClock;

implementation

uses Dos, Crt, Graph, GrMouse;

const
  AnyKey = 'ցանկացած ստեղն';         { "any key" in a prompt, drawn in AnyKeyColor }
  AnyKeyColor = LightGreen;

{$I ARMFONT.INC}
{$I FONT16.INC}

var
  RomFont: array[0..1023] of Byte absolute $F000:$FA6E;  { the BIOS's 8x8 characters $00..$7F, which graphics text uses }
  MoveTick: Word;                    { the BIOS timer tick, 18.2 a second, of the first of them }
  OldFontTable, OldExitProc: Pointer;

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

procedure GetKey(var ch: Char; var Ext: Boolean);
{ read one key; an arrow or F-key arrives as #0 + scan code and comes back as the scan code with Ext set }
begin
  ch := ReadKey;
  Ext := ch = #0;
  if Ext then
    ch := ReadKey
end;

function ButtonDown: Boolean;
{ a mouse button is held down: a click, or a tap on a touch screen, under way }
var
  x, y: Integer;
begin
  ButtonDown := MouseThere and (ReadGrCursor(x, y) <> 0)
end;

procedure DropInput;
{ drop keys already typed or still held down, and wait for a button still held to be let go, so they don't also act
  on what the screen shows next }
var
  ch: Char;
begin
  repeat
    while KeyPressed do
      ch := ReadKey;
    Delay(300)
  until not KeyPressed;
  while ButtonDown do
    Delay(10)
end;

procedure WaitFor(var ch: Char);
{ wait for a fresh key press or click, and give the key, or #0 for a click or an arrow. A tap on a touch screen is a
  click, so a phone without pads gets on too. A click counts once its button is let go }
var
  Ext: Boolean;
begin
  ch := #0;
  DropInput;
  if MouseThere then
  begin
    repeat
      Delay(10)
    until KeyPressed or ButtonDown;
    if not KeyPressed then
    begin
      while ButtonDown do
        Delay(10);
      Exit
    end
  end;
  GetKey(ch, Ext);
  if Ext then
    ch := #0
end;

procedure WaitKey;
{ wait for a fresh key press or click, whichever it is }
var
  ch: Char;
begin
  WaitFor(ch)
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

function GlyphInk(c: Char; tall: Boolean): Byte;
{ the columns of c that show anything, as the bits of one row: of its 8x16 character in Font16 when tall, else of its
  8x8 one in graphics text, $80..$FF the Armenian table's and the rest the BIOS's own }
var
  r: Integer;
  b: Byte;
begin
  b := 0;
  if tall then
    for r := 0 to 15 do
      b := b or Font16[Ord(c) * 16 + r]
  else
    for r := 0 to 7 do
      if Ord(c) >= $80 then
        b := b or ArmenianFont[(Ord(c) - $80) * 8 + r]
      else
        b := b or RomFont[Ord(c) * 8 + r];
  GlyphInk := b
end;

function InkStart(x1, x2: Integer; s: string; tall: Boolean; size: Integer): Integer;
{ where s starts for what it shows, not its characters' boxes, to be centred between x1 and x2: in the 8x16
  characters when tall, else in graphics text at the given size. Most characters leave their last columns blank,
  some their first }
var
  first, last, left, right: Integer;
  bits: Byte;
begin
  first := 1;
  while (first <= Length(s)) and (GlyphInk(s[first], tall) = 0) do
    Inc(first);
  if first > Length(s) then
  begin
    InkStart := (x1 + x2 + 1) div 2 - Length(s) * 4 * size;
    Exit
  end;
  last := Length(s);
  while GlyphInk(s[last], tall) = 0 do
    Dec(last);
  bits := GlyphInk(s[first], tall);
  left := 0;
  while bits and ($80 shr left) = 0 do
    Inc(left);
  bits := GlyphInk(s[last], tall);
  right := 7;
  while bits and ($80 shr right) = 0 do
    Dec(right);
  InkStart := (x1 + x2 - ((first - 1) * 8 + left) * size - ((last - 1) * 8 + right + 1) * size + 1) div 2
end;

function InkX(x1, x2: Integer; s: string): Integer;
{ where s starts to be centred by what it shows between x1 and x2, in graphics text at the current size }
var
  ts: TextSettingsType;
begin
  GetTextSettings(ts);
  InkX := InkStart(x1, x2, s, False, ts.CharSize)
end;

procedure OutTall(x, y: Integer; s: string; color: Word);
{ s in the 8x16 characters of Font16, its top left at (x, y), in color, over what is there: written straight into
  the VGA's memory, a row of dots at a time, as graphics text has no size between 8x8 and 16x16 and drawing dot by
  dot through it would be slow at DOSBox's pace }
var
  i, r: Integer;
  cx, row, offs, bits: Word;
  latch: Byte;
begin
  Port[$3CE] := 0;                   { set/reset: the color, }
  Port[$3CF] := color;
  Port[$3CE] := 1;                   { into all four planes }
  Port[$3CF] := $0F;
  Port[$3CE] := 3;                   { no rotation, no logic }
  Port[$3CF] := 0;
  Port[$3CE] := 5;                   { write mode 0 }
  Port[$3CF] := 0;
  Port[$3CE] := 8;                   { the bit mask from here on }
  for i := 1 to Length(s) do
  begin
    cx := x + (i - 1) * 8;
    for r := 0 to 15 do
    begin
      bits := Font16[Ord(s[i]) * 16 + r];
      if bits <> 0 then
      begin
        { the row's 8 dots as 16 bits, the high byte at the screen's byte cx div 8 and the low byte the next }
        bits := bits shl (8 - cx and 7);
        row := y + r;
        offs := row * 80 + cx shr 3;
        Port[$3CF] := Hi(bits);
        latch := Mem[$A000:offs];
        Mem[$A000:offs] := $FF;
        if Lo(bits) <> 0 then
        begin
          Port[$3CF] := Lo(bits);
          latch := Mem[$A000:offs + 1];
          Mem[$A000:offs + 1] := $FF
        end
      end
    end
  end;
  { the registers as graphics expects them }
  Port[$3CF] := $FF;
  Port[$3CE] := 1;
  Port[$3CF] := 0;
  Port[$3CE] := 0;
  Port[$3CF] := 0
end;

procedure OutCentered(y: Integer; s: string);
{ s centred on the screen by what it shows, in the current text style }
begin
  OutTextXY(InkX(0, GetMaxX, s), y, s)
end;

procedure OutPrompt(y: Integer; s: string);
{ a prompt centred on the screen in the current text style and color, its "any key" in AnyKeyColor, so it stands out }
var
  x: Integer;
  color: Word;
begin
  x := InkX(0, GetMaxX, s);
  OutTextXY(x, y, s);
  if Pos(AnyKey, s) > 0 then
  begin
    color := GetColor;
    SetColor(AnyKeyColor);
    OutTextXY(x + TextWidth(Copy(s, 1, Pos(AnyKey, s) - 1)), y, AnyKey);
    SetColor(color)
  end
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

end.
