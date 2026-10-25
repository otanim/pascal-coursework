unit GrMouse;
{ The mouse in graphics mode, through the DOS mouse driver (interrupt 33h):
  an arrow-shaped cursor, showing and hiding it, its position and the buttons. }

interface

function InitGraphMouse: Integer;               { 1 when a mouse driver answers, 0 otherwise }
procedure ShowGrCursor;
procedure HideGrCursor;
function ReadGrCursor(var x, y: Integer): Word; { buttons held down: 1 left, 2 right, 4 middle }
procedure SetGrCursor(x, y: Integer);

implementation

uses Dos, Graph;

const
  { 16 x 16 arrow pointing to the upper left: 16 screen-mask rows, then 16 cursor rows;
    bit 15 is the leftmost pixel }
  Cursor: array[1..32] of Word = (
    $3FFF, $1FFF, $07FF, $81FF, $807F, $C01F, $C007, $E001,
    $E000, $F001, $F003, $F801, $F840, $FFE0, $FFF0, $FFF8,
    $8000, $4000, $7000, $3C00, $3F00, $1FC0, $1FF0, $0FFC,
    $0F0F, $070C, $0708, $03FC, $031E, $000F, $0007, $0003);

var
  Shown: Boolean;   { the driver counts hide calls, so show and hide only call it when the state changes }

function InitGraphMouse: Integer;
var
  r: Registers;
  vec: Pointer;
begin
  InitGraphMouse := 0;
  Shown := False;
  if GetGraphMode < 0 then
    Exit;
  GetIntVec($33, vec);              { without a driver the vector is empty or points at a bare IRET }
  if vec = nil then
    Exit;
  if Mem[Seg(vec^):Ofs(vec^)] = $CF then
    Exit;
  FillChar(r, SizeOf(r), 0);
  r.AX := 0;                        { reset: answers $FFFF when a mouse is attached; the cursor starts hidden }
  Intr($33, r);
  if r.AX = 0 then
    Exit;
  FillChar(r, SizeOf(r), 0);
  r.AX := 9;                        { cursor shape, with the hotspot on the tip at (0, 0) }
  r.ES := Seg(Cursor);
  r.DX := Ofs(Cursor);
  Intr($33, r);
  InitGraphMouse := 1
end;

procedure ShowGrCursor;
var
  r: Registers;
begin
  if Shown then
    Exit;
  FillChar(r, SizeOf(r), 0);
  r.AX := 1;
  Intr($33, r);
  Shown := True
end;

procedure HideGrCursor;
var
  r: Registers;
begin
  if not Shown then
    Exit;
  FillChar(r, SizeOf(r), 0);
  r.AX := 2;
  Intr($33, r);
  Shown := False
end;

function ReadGrCursor(var x, y: Integer): Word;
var
  r: Registers;
begin
  FillChar(r, SizeOf(r), 0);
  r.AX := 3;
  Intr($33, r);
  x := r.CX;
  y := r.DX;
  ReadGrCursor := r.BL
end;

procedure SetGrCursor(x, y: Integer);
var
  r: Registers;
begin
  FillChar(r, SizeOf(r), 0);
  r.AX := 4;
  r.CX := x;
  r.DX := y;
  Intr($33, r)
end;

begin
  Shown := False
end.
