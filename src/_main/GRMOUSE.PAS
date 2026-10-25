Unit GRMouse;
interface
uses crt,graph;
var
XCursor,YCursor:integer;
MouseGrPresent,GrButton:word;

Function InitGraphMouse:integer;{инициализация граф. курсора}
Procedure ShowGrCursor;{курсор видимый}
Procedure HideGrCursor;{курсор невидим}
Function ReadGrCursor(var Xcursor,Ycursor:integer):word;{чтение X,Y и клавиш}
Procedure SetGrCursor(Xcursor,Ycursor:integer);{установить курсор в X,Y}

implementation

  Function InitGraphMouse:integer;{инициализация граф. курсора}
 const
cursor:array [1..32] of word=($3FFF,$1FFF,$07FF,$81FF,$807F,$C01F,$C007,$E001,
                              $E000,$F001,$F003,$F801,$F840,$FFE0,$FFF0,$FFF8,
                              $8000,$4000,$7000,$3C00,$3F00,$1FC0,$1FF0,$0FFC,
                              $0F0F,$070C,$0708,$03FC,$031E,$000F,$0007,$0003);
 var
  Res:integer;
  SC,OfC:word;
 begin
 Sc:=Seg(Cursor);
 Ofc:=Ofs(Cursor);
 MouseGrPresent:=0;initGraphMouse:=0;
 if GetGraphMode<0 then exit;
 asm
    mov    AX,0
    int    $33
    mov    AH,BL
    mov    Res,AX
 end;
 InitGraphMouse:=Res;
 if Res=0 then exit;
 MouseGrPresent:=1;
 asm
    mov AX,9
    mov BX,0
    mov CX,0
    mov ES,Sc
    mov DX,OfC
    int $33
    mov AX,15
    mov CX,36
    mov DX,36
    int $33
 end;
 end;{InitGraphMouse}

 Procedure ShowGrCursor;{курсор видимый}
 begin
{  if GetGraphMode<0 then exit;}
 asm
   mov  AX,1
   int  $33
 end;
 end;{ShovGrCursor}

 Procedure HideGrCursor;{курсор невидим}
 begin
{  if GetGraphMode<0 then exit;}
 asm
  mov   AX,2
  int   $33
 end
 end;{HideGrCursor}

 Function ReadGrCursor(var XCursor,Ycursor:integer):word;{чтение X,Y и клавиш}
 var
 Res:word;
 res1,res2:integer;
 begin
 Res:=0;XCursor:=0;YCursor:=0;
{  if GetGraphMode<0 then exit;}
 asm
  mov  AX,3
  int  $33
  mov  byte ptr Res,BL
  mov  res1,CX
  mov  res2,DX
 end;
  XCursor:=res1;Ycursor:=res2;
  ReadGrCursor:=Res;
 end;{ReadGrCursor}

 Procedure SetGrCursor(Xcursor,Ycursor:integer);{установить курсор в X,Y}
 begin
{  if GetGraphMode<0 then exit;}
 asm
    mov AX,4
    mov CX,Xcursor
    mov DX,Ycursor
    int $33
 end
 end;{SetGrCursor}

begin
MouseGrPresent:=0; XCursor:=0; YCursor:=0; GrButton:=0;
end.