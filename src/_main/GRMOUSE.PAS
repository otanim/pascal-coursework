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
cursor:array [1..32] of word=($FFFC,$FFF8,$FFE0,$FF81,$FE01,$F803,$E003,$8007,
                              $0007,$800F,$C00F,$801F,$021F,$07FF,$0FFF,$1FFF,
                              $0001,$0002,$000E,$003C,$00FC,$03F8,$0FF8,$3FF0,
                              $F0F0,$30E0,$10E0,$3FC0,$78C0,$F000,$E000,$C000);
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
    mov BX,16
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