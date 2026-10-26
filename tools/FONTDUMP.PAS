program FontDump;
{ save the 8x16 characters of 640x480 graphics, which interrupt vector 43h points at once the mode is set: run after
  FONT /A, so they are its Armenian ones (INT43.BIN). The VGA's own table, from INT 10h, goes to ROM16.BIN }
uses Dos;
var
  r: Registers;
  p: Pointer;

procedure Save(name: string; p: Pointer);
var
  f: file;
begin
  Assign(f, name);
  Rewrite(f, 1);
  BlockWrite(f, p^, 4096);
  Close(f)
end;

begin
  r.AX := $0012;
  Intr($10, r);
  GetIntVec($43, p);
  Save('INT43.BIN', p);
  r.AX := $1130;
  r.BH := 6;
  Intr($10, r);
  Save('ROM16.BIN', Ptr(r.ES, r.BP));
  r.AX := $0003;
  Intr($10, r)
end.
