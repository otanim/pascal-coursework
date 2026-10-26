unit P547;
{ Problem 547: a matrix typed in, saved to 547.TXT and read back, and the last row with the most equal
  elements; and its window, which the desktop's task window shares }

interface

procedure DrawWindow;
function OnClose(x, y: Integer): Boolean;
procedure SolveProblem;

implementation

uses Crt, Graph, GrMouse, Shared;

type
  TMatrix = array[1..12, 1..6] of Real;  { up to 12 rows and 6 columns }
  TRow = array[1..6] of Real;
  TCounts = array[1..12] of Integer;
  TNumberText = string[11];          { a minus, 9 digits and a point }

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

end.
