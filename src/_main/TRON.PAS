  Uses dos, crt, graph, grmouse;

type mat=array [1..5,1..5] of real;
	 vec=array [1..5] of byte;
	 ash=array [1..5] of real;

Var m,n,k,i,lol,xxpos,yypos,X,Y,divx,divy,Conta,Bluep,Yellowp:Integer;
	Xpos1,Ypos1,Xpos2,Ypos2,Npos1,Npos2,Winner,Vel,Ngames:Integer;
	hh,hh0,mi,se,ms:word; hhs,mis,ses,s0,m0,h0:string;
	_1p,out,esc,start,quest,questpad:boolean;
	s,txt,bl,ye:string;
	Exitgame,c:Char;
	
Procedure print(x0,y0:Integer; y5:byte; size:byte; s:string);
Var i:Integer;
Begin
	settextstyle(0,0,size);
	setcolor(y5);
	for i:=1 to length(s) do
	Begin
		outtextxy (x0+i*8*size,y0,copy(s,i,1));
		delay(10)
	End;
End;
{======menu======}

Procedure put3(Var xpos,ypos:Integer); {3x3 bar}
Begin
	bar(xpos,ypos,xpos+5,ypos+5)
End;

Procedure InitVar; {tvyalnei initsializatsum}
Begin
		Npos1:=1;
		Npos2:=3;
		Ypos1:=240;
		Ypos2:=240;
		Xpos1:=getmaxx-100;
		Xpos2:=101;
		out:=False;
End;
procedure tronimage;
var	cp:array[1..368,1..2] of word;
begin
for i:=1 to 3 do cp[i,1]:=divx-222;
for i:=4 to 9 do cp[i,2]:=divy-96;
for i:=10 to 15 do cp[i,2]:=divy-120;
for i:=16 to 18 do cp[i,1]:=divx-180;
for i:=19 to 32 do cp[i,1]:=divx-168;
for i:=33 to 35 do cp[i,2]:=divy-18;
for i:=36 to 47 do cp[i,1]:=divx-144;
for i:=50 to 71 do cp[i,2]:=divy-120;
for i:=72 to 73 do cp[i,2]:=divy-114;
for i:=74 to 75 do cp[i,2]:=divy-108;
for i:=76 to 77 do cp[i,1]:=divx-18;
for i:=77 to 97 do cp[i,2]:=divy-96;
for i:=98 to 109 do cp[i,2]:=divy-84;
for i:=110 to 113 do cp[i,1]:=divx-84;
for i:=114 to 115 do cp[i,1]:=divx-78;
for i:=115 to 116 do cp[i,2]:=divy-54;
for i:=116 to 117 do cp[i,1]:=divx-72;
for i:=117 to 118 do cp[i,2]:=divy-48;
for i:=118 to 119 do cp[i,1]:=divx-66;
for i:=119 to 120 do cp[i,2]:=divy-42;
for i:=120 to 121 do cp[i,1]:=divx-60;
for i:=121 to 122 do cp[i,2]:=divy-36;
for i:=122 to 123 do cp[i,1]:=divx-54;
for i:=123 to 124 do cp[i,2]:=divy-30;
for i:=124 to 125 do cp[i,1]:=divx-48;
for i:=125 to 126 do cp[i,2]:=divy-24;
for i:=126 to 127 do cp[i,1]:=divx-42;
for i:=127 to 131 do cp[i,2]:=divy-18;
for i:=132 to 133 do cp[i,1]:=divx-18;
for i:=133 to 134 do cp[i,2]:=divy-30;
for i:=134 to 135 do cp[i,1]:=divx-24;
for i:=135 to 136 do cp[i,2]:=divy-36;
for i:=136 to 137 do cp[i,1]:=divx-30;
for i:=137 to 138 do cp[i,2]:=divy-42;
for i:=138 to 139 do cp[i,1]:=divx-36;
for i:=139 to 140 do cp[i,2]:=divy-48;
for i:=140 to 141 do cp[i,1]:=divx-42;
for i:=141 to 142 do cp[i,2]:=divy-54;
for i:=142 to 143 do cp[i,1]:=divx-48;
for i:=143 to 146 do cp[i,2]:=divy-60;
for i:=146 to 147 do cp[i,1]:=divx-30;
for i:=147 to 148 do cp[i,2]:=divy-66;
for i:=148 to 149 do cp[i,1]:=divx-24;
for i:=149 to 150 do cp[i,2]:=divy-72;
for i:=150 to 152 do cp[i,1]:=divx-18;
for i:=151 to 153 do cp[i,2]:=divy-78;
for i:=153 to 162 do cp[i,1]:=divx-96;
for i:=163 to 165 do cp[i,2]:=divy-18;
for i:=166 to 175 do cp[i,1]:=divx-120;
for i:=176 to 178 do cp[i,2]:=divy-84;
for i:=179 to 186 do cp[i,1]:=divx-6;
for i:=187 to 189 do cp[i,1]:=divx;
for i:=190 to 191 do cp[i,1]:=divx+6;
for i:=191 to 192 do cp[i,2]:=divy-30;
for i:=192 to 193 do cp[i,1]:=divx+12;
for i:=193 to 195 do cp[i,2]:=divy-24;
for i:=196 to 203 do cp[i,2]:=divy-18;
for i:=203 to 204 do cp[i,1]:=divx+66;
for i:=204 to 206 do cp[i,2]:=divy-24;
for i:=207 to 208 do cp[i,2]:=divy-30;
for i:=208 to 209 do cp[i,1]:=divx+84;
for i:=209 to 210 do cp[i,2]:=divy-36;
for i:=210 to 212 do cp[i,1]:=divx+90;
for i:=212 to 213 do cp[i,2]:=divy-48;
for i:=213 to 220 do cp[i,1]:=divx+96;
for i:=220 to 221 do cp[i,2]:=divy-90;
for i:=221 to 223 do cp[i,1]:=divx+90;
for i:=223 to 224 do cp[i,2]:=divy-102;
for i:=224 to 225 do cp[i,1]:=divx+84;
for i:=225 to 226 do cp[i,2]:=divy-108;
for i:=226 to 227 do cp[i,1]:=divx+78;
for i:=227 to 229 do cp[i,2]:=divy-114;
for i:=229 to 230 do cp[i,1]:=divx+66;
for i:=230 to 237 do cp[i,2]:=divy-120;
for i:=237 to 238 do cp[i,1]:=divx+24;
for i:=239 to 240 do cp[i,2]:=divy-114;
for i:=240 to 241 do cp[i,1]:=divx+12;
for i:=241 to 242 do cp[i,2]:=divy-108;
for i:=242 to 243 do cp[i,1]:=divx+6;
for i:=243 to 244 do cp[i,2]:=divy-102;
for i:=244 to 246 do cp[i,1]:=divx;
for i:=248 to 249 do cp[i,2]:=divy-90;
for i:=250 to 253 do cp[i,2]:=divy-96;
for i:=254 to 255 do cp[i,2]:=divy-90;
for i:=255 to 256 do cp[i,1]:=divx+66;
for i:=257 to 260 do cp[i,1]:=divx+72;
for i:=261 to 262 do cp[i,1]:=divx+66;
for i:=264 to 267 do cp[i,2]:=divy-42;
for i:=268 to 269 do cp[i,2]:=divy-48;
for i:=269 to 270 do cp[i,1]:=divx+24;
for i:=271 to 274 do cp[i,1]:=divx+18;
for i:=275 to 291 do cp[i,1]:=divx+108;
for i:=292 to 294 do cp[i,2]:=divy-18;
for i:=295 to 300 do cp[i,1]:=divx+132;
for i:=301 to 303 do cp[i,2]:=divy-54;
for i:=304 to 308 do cp[i,1]:=divx+156;
for i:=309 to 310 do cp[i,1]:=divx+150;
for i:=310 to 311 do cp[i,2]:=divy-90;
for i:=311 to 312 do cp[i,1]:=divx+144;
for i:=312 to 313 do cp[i,2]:=divy-96;
for i:=313 to 314 do cp[i,1]:=divx+138;
for i:=314 to 315 do cp[i,2]:=divy-102;
for i:=315 to 316 do cp[i,1]:=divx+132;
for i:=316 to 317 do cp[i,2]:=divy-108;
for i:=317 to 318 do cp[i,1]:=divx+126;
for i:=318 to 319 do cp[i,2]:=divy-114;
for i:=319 to 320 do cp[i,1]:=divx+120;
for i:=320 to 321 do cp[i,2]:=divy-120;
for i:=322 to 325 do cp[i,1]:=divx+168;
for i:=326 to 327 do cp[i,1]:=divx+174;
for i:=327 to 328 do cp[i,2]:=divy-48;
for i:=328 to 329 do cp[i,1]:=divx+180;
for i:=329 to 330 do cp[i,2]:=divy-42;
for i:=330 to 331 do cp[i,1]:=divx+186;
for i:=331 to 332 do cp[i,2]:=divy-36;
for i:=332 to 333 do cp[i,1]:=divx+192;
for i:=333 to 334 do cp[i,2]:=divy-30;
for i:=334 to 335 do cp[i,1]:=divx+198;
for i:=335 to 336 do cp[i,2]:=divy-24;
for i:=336 to 337 do cp[i,1]:=divx+204;
for i:=337 to 339 do cp[i,2]:=divy-18;
for i:=339 to 356 do cp[i,1]:=divx+216;
for i:=356 to 359 do cp[i,2]:=divy-120;
for i:=360 to 365 do cp[i,1]:=divx+192;
for i:=366 to 368 do cp[i,2]:=divy-78;
cp[1,2]:=divy-114;
cp[2,2]:=divy-108;
cp[3,2]:=divy-102;
cp[4,1]:=divx-216;
cp[5,1]:=divx-210;
cp[6,1]:=divx-204;
cp[7,1]:=divx-198;
cp[8,1]:=divx-192;
cp[9,1]:=divx-186;
cp[10,1]:=divx-216;
cp[11,1]:=divx-210;
cp[12,1]:=divx-204;
cp[13,1]:=divx-198;
cp[14,1]:=divx-192;
cp[15,1]:=divx-186;
cp[16,2]:=divy-114;
cp[17,2]:=divy-108;
cp[18,2]:=divy-102;
cp[19,2]:=divy-102;
cp[20,2]:=divy-96;
cp[21,2]:=divy-90;
cp[22,2]:=divy-84;
cp[23,2]:=divy-78;
cp[24,2]:=divy-72;
cp[25,2]:=divy-66;
cp[26,2]:=divy-60;
cp[27,2]:=divy-54;
cp[28,2]:=divy-48;
cp[29,2]:=divy-42;
cp[30,2]:=divy-36;
cp[31,2]:=divy-30;
cp[32,2]:=divy-24;
cp[33,1]:=divx-162;
cp[34,1]:=divx-156;
cp[35,1]:=divx-150;
cp[36,2]:=divy-24;
cp[37,2]:=divy-30;
cp[38,2]:=divy-36;
cp[39,2]:=divy-42;
cp[40,2]:=divy-48;
cp[41,2]:=divy-54;
cp[42,2]:=divy-60;
cp[43,2]:=divy-66;
cp[44,2]:=divy-72;
cp[45,2]:=divy-78;
cp[46,2]:=divy-84;
cp[47,2]:=divy-90;
cp[48,1]:=divx-168;
cp[48,2]:=divy-108;
cp[49,1]:=divx-162;
cp[49,2]:=divy-114;
cp[50,1]:=divx-156;
cp[51,1]:=divx-150;
cp[52,1]:=divx-144;
cp[53,1]:=divx-138;
cp[54,1]:=divx-132;
cp[55,1]:=divx-126;
cp[56,1]:=divx-120;
cp[57,1]:=divx-114;
cp[58,1]:=divx-108;
cp[59,1]:=divx-102;
cp[60,1]:=divx-96;
cp[61,1]:=divx-90;
cp[62,1]:=divx-84;
cp[63,1]:=divx-78;
cp[64,1]:=divx-72;
cp[65,1]:=divx-66;
cp[66,1]:=divx-60;
cp[67,1]:=divx-54;
cp[68,1]:=divx-48;
cp[69,1]:=divx-42;
cp[70,1]:=divx-36;
cp[71,1]:=divx-30;
cp[72,1]:=divx-30;
cp[73,1]:=divx-24;
cp[74,1]:=divx-24;
cp[75,1]:=divx-18;
cp[76,2]:=divy-102;
cp[78,1]:=divx-24;
cp[79,1]:=divx-30;
cp[80,1]:=divx-36;
cp[81,1]:=divx-42;
cp[82,1]:=divx-48;
cp[83,1]:=divx-54;
cp[84,1]:=divx-60;
cp[85,1]:=divx-66;
cp[86,1]:=divx-72;
cp[87,1]:=divx-78;
cp[88,1]:=divx-84;
cp[89,1]:=divx-90;
cp[90,1]:=divx-96;
cp[91,1]:=divx-102;
cp[92,1]:=divx-108;
cp[93,1]:=divx-114;
cp[94,1]:=divx-120;
cp[95,1]:=divx-126;
cp[96,1]:=divx-132;
cp[97,1]:=divx-138;
cp[98,1]:=divx-18;
cp[99,1]:=divx-24;
cp[100,1]:=divx-30;
cp[101,1]:=divx-36;
cp[102,1]:=divx-42;
cp[103,1]:=divx-42;
cp[104,1]:=divx-48;
cp[105,1]:=divx-54;
cp[106,1]:=divx-60;
cp[107,1]:=divx-66;
cp[108,1]:=divx-72;
cp[109,1]:=divx-78;
cp[110,2]:=divy-78;
cp[111,2]:=divy-72;
cp[112,2]:=divy-66;
cp[113,2]:=divy-60;
cp[114,2]:=divy-60;
cp[128,1]:=divx-36;
cp[129,1]:=divx-30;
cp[130,1]:=divx-24;
cp[131,1]:=divx-18;
cp[132,2]:=divy-24;
cp[144,1]:=divx-42;
cp[145,1]:=divx-36;
cp[154,2]:=divy-72;
cp[155,2]:=divy-66;
cp[156,2]:=divy-60;
cp[157,2]:=divy-54;
cp[158,2]:=divy-48;
cp[159,2]:=divy-42;
cp[160,2]:=divy-36;
cp[161,2]:=divy-30;
cp[162,2]:=divy-24;
cp[163,1]:=divx-102;
cp[164,1]:=divx-108;
cp[165,1]:=divx-114;
cp[166,2]:=divy-24;
cp[167,2]:=divy-30;
cp[168,2]:=divy-36;
cp[169,2]:=divy-42;
cp[170,2]:=divy-48;
cp[171,2]:=divy-54;
cp[172,2]:=divy-60;
cp[173,2]:=divy-66;
cp[174,2]:=divy-72;
cp[175,2]:=divy-78;
cp[176,1]:=divx-114;
cp[177,1]:=divx-108;
cp[178,1]:=divx-102;
cp[179,2]:=divy-90;
cp[180,2]:=divy-84;
cp[181,2]:=divy-78;
cp[182,2]:=divy-72;
cp[183,2]:=divy-66;
cp[184,2]:=divy-60;
cp[185,2]:=divy-54;
cp[186,2]:=divy-48;
cp[187,2]:=divy-48;
cp[188,2]:=divy-42;
cp[189,2]:=divy-36;
cp[190,2]:=divy-36;
cp[194,1]:=divx+18;
cp[195,1]:=divx+24;
cp[196,1]:=divx+24;
cp[197,1]:=divx+30;
cp[198,1]:=divx+36;
cp[199,1]:=divx+42;
cp[200,1]:=divx+48;
cp[201,1]:=divx+54;
cp[202,1]:=divx+60;
cp[205,1]:=divx+72;
cp[206,1]:=divx+78;
cp[207,1]:=divx+78;
cp[211,2]:=divy-42;
cp[214,2]:=divy-54;
cp[215,2]:=divy-60;
cp[216,2]:=divy-66;
cp[217,2]:=divy-72;
cp[218,2]:=divy-78;
cp[219,2]:=divy-84;
cp[222,2]:=divy-96;
cp[228,1]:=divx+72;
cp[231,1]:=divx+60;
cp[232,1]:=divx+54;
cp[233,1]:=divx+48;
cp[234,1]:=divx+42;
cp[235,1]:=divx+36;
cp[236,1]:=divx+30;
cp[238,2]:=divy-114;
cp[239,1]:=divx+18;
cp[245,2]:=divy-96;
cp[246,2]:=divy-90;
cp[247,1]:=divx+24;
cp[247,2]:=divy-84;
cp[248,1]:=divx+24;
cp[249,1]:=divx+30;
cp[250,1]:=divx+36;
cp[251,1]:=divx+42;
cp[252,1]:=divx+48;
cp[253,1]:=divx+54;
cp[254,1]:=divx+60;
cp[256,2]:=divy-84;
cp[257,2]:=divy-78;
cp[258,2]:=divy-72;
cp[259,2]:=divy-66;
cp[260,2]:=divy-60;
cp[261,2]:=divy-54;
cp[262,2]:=divy-48;
cp[263,1]:=divx+60;
cp[263,2]:=divy-48;
cp[264,1]:=divx+54;
cp[265,1]:=divx+48;
cp[266,1]:=divx+42;
cp[267,1]:=divx+36;
cp[268,1]:=divx+30;
cp[270,2]:=divy-54;
cp[271,2]:=divy-60;
cp[272,2]:=divy-66;
cp[273,2]:=divy-72;
cp[274,2]:=divy-78;
cp[275,2]:=divy-120;
cp[276,2]:=divy-114;
cp[277,2]:=divy-108;
cp[278,2]:=divy-102;
cp[279,2]:=divy-96;
cp[280,2]:=divy-90;
cp[281,2]:=divy-84;
cp[282,2]:=divy-78;
cp[283,2]:=divy-72;
cp[284,2]:=divy-66;
cp[285,2]:=divy-60;
cp[286,2]:=divy-54;
cp[287,2]:=divy-48;
cp[288,2]:=divy-42;
cp[289,2]:=divy-36;
cp[290,2]:=divy-30;
cp[291,2]:=divy-24;
cp[292,1]:=divx+114;
cp[293,1]:=divx+120;
cp[294,1]:=divx+126;
cp[295,2]:=divy-24;
cp[296,2]:=divy-30;
cp[297,2]:=divy-36;
cp[298,2]:=divy-42;
cp[299,2]:=divy-46;
cp[300,2]:=divy-48;
cp[301,1]:=divx+138;
cp[302,1]:=divx+144;
cp[303,1]:=divx+150;
cp[304,2]:=divy-60;
cp[305,2]:=divy-66;
cp[306,2]:=divy-72;
cp[307,2]:=divy-78;
cp[308,2]:=divy-84;
cp[309,2]:=divy-84;
cp[321,1]:=divx+114;
cp[322,2]:=divy-72;
cp[323,2]:=divy-66;
cp[324,2]:=divy-60;
cp[325,2]:=divy-54;
cp[326,2]:=divy-54;
cp[338,1]:=divx+210;
cp[340,2]:=divy-24;
cp[341,2]:=divy-30;
cp[342,2]:=divy-36;
cp[343,2]:=divy-42;
cp[344,2]:=divy-48;
cp[345,2]:=divy-54;
cp[346,2]:=divy-60;
cp[347,2]:=divy-66;
cp[348,2]:=divy-72;
cp[349,2]:=divy-78;
cp[350,2]:=divy-84;
cp[351,2]:=divy-90;
cp[352,2]:=divy-96;
cp[353,2]:=divy-102;
cp[354,2]:=divy-108;
cp[355,2]:=divy-114;
cp[357,1]:=divx+210;
cp[358,1]:=divx+204;
cp[359,1]:=divx+198;
cp[360,2]:=divy-114;
cp[361,2]:=divy-108;
cp[362,2]:=divy-102;
cp[363,2]:=divy-96;
cp[364,2]:=divy-90;
cp[365,2]:=divy-84;
cp[366,1]:=divx+186;
cp[367,1]:=divx+180;
cp[368,1]:=divx+174;

setfillstyle(1,2);
for i:=1 to 368 do
if not keypressed then
begin
x:=cp[i,1];
y:=cp[i,2];
put3(x,y);
delay(10)
end;
readkey
end;

Procedure newgame(b1,b2,o1,o2:byte); {*Tron* nor khagh? Yes/No}
Begin
	setfillstyle(1,b1);
	bar(205,divy,305,divy + 50);
	setfillstyle(1,b2);
	bar(330,divy,433,divy + 50);

	settextstyle(0,0,2);
	setcolor(o1);
	outtextxy(230,divy+20,'€©―');
	setcolor(o2);
	outtextxy(360,divy+20,'®α');
End;

Procedure gamelvl1(b1,b2,b3,b4,o1,o2,o3,o4:byte);
var xc:integer;
Begin
if _1p then xc:=90 else xc:=215;
	setfillstyle(1,b1);
	bar(xc,divy+62,xc+80,divy + 92);
	setfillstyle(1,b2);
	bar(xc,divy+102,xc+80,divy + 132);
	setfillstyle(1,b3);
	bar(xc,divy+142,xc+80,divy + 172);
	setfillstyle(1,b4);
	bar(xc,divy+182,xc+80,divy + 212);
	
	settextstyle(0,0,1);
	setcolor(o1);
	outtextxy(xc+5,divy+77,'5  ™£');
	setcolor(o2);
	outtextxy(xc+5,divy+117,'10 ™£');
	setcolor(o3);
	outtextxy(xc+5,divy+157,'25 ™£');
	setcolor(o4);
	outtextxy(xc+5,divy+197,'50 ™£');
End;

Procedure gamemenu1(b1,b2,b3,b4,o1,o2,o3,o4:byte); {*Tron* 1 hogi / 2 hogi / paymanner / elq}
Begin
	setfillstyle(1,b1);
	bar(80,divy,180,divy + 50);
	setfillstyle(1,b2);
	bar(205,divy,305,divy + 50);
	setfillstyle(1,b3);
	bar(330,divy,433,divy + 50);
	setfillstyle(1,b4);
	bar(455,divy,555,divy + 50);

	settextstyle(0,0,1);
	setcolor(o1);
	outtextxy(90,divy+20,'1 ™£ρ―£');
	setcolor(o2);
	outtextxy(210,divy+20,'2 ™£ρ―£');
	setcolor(o3);
	outtextxy(340,divy+20,'β©§««‰ο');
	setcolor(o4);
	outtextxy(470,divy+20,'—χ');
End;

{======Tron======}


Procedure put(Var xpos,ypos:Integer; col:word); {2x2 putpixel}
Begin
	setfillstyle(1,col);
	bar(xpos,ypos,xpos+1,ypos+1);
End;


Procedure PressKey (Var Npos1,Npos2:Integer); {khaghatsoghneri ashkhatanqi kazmakerpum}
Var Ch:Char;
	Num:Integer;
Begin
	If Keypressed then
		Ch:=ReadKey;
		Num:=Ord(Ch);
		
		Case Num of
			75:If Npos1<>3 then Npos1:=1;
			72:If Npos1
      <>4 then Npos1:=2;
			77:If Npos1<>1 then Npos1:=3;
			80:If Npos1<>2 then Npos1:=4
		End;
    if _1p then
	Begin
		lol:=0;
		xxpos:=xpos2;
		yypos:=ypos2;
		repeat
			lol:=lol+1;
			Case Npos2 of
				1:xxpos:=xxpos-2;
				2:yypos:=yypos-2;
				3:xxpos:=xxpos+2;
				4:yypos:=yypos+2
			End
		until (getpixel(xxpos,yypos)<>0)or(lol=40);
		if random(lol) = 0 then
			Case random(4)+1 of
				1:If (Npos2<>1)and(Npos2<>3) then Npos2:=1;
				2:If (Npos2<>2)and(Npos2<>4) then Npos2:=2;
				3:If (Npos2<>3)and(Npos2<>1) then Npos2:=3;
				4:If (Npos2<>4)and(Npos2<>2) then Npos2:=4
			End;
			for i:=1 to 2 do
			begin
				case Npos2 of
					1:if getpixel(xpos2-2,ypos2)<>0 then Npos2:=4;
					2:if getpixel(xpos2,ypos2-2)<>0 then Npos2:=3;
					3:If getpixel(xpos2+2,ypos2)<>0 then Npos2:=2;
					4:If getpixel(xpos2,ypos2+2)<>0 then Npos2:=1
				End;
				Case Npos2 of
					1:if getpixel(xpos2-2,ypos2)<>0 then Npos2:=2;
					2:if getpixel(xpos2,ypos2-2)<>0 then Npos2:=1;
					3:If getpixel(xpos2+2,ypos2)<>0 then Npos2:=4;
					4:If getpixel(xpos2,ypos2+2)<>0 then Npos2:=3
				End
			end;
				
	End
	else
	Begin
		ch:=upcase(ch);
		Case Ch of
			'A':If Npos2<>3 then Npos2:=1;
			'W':If Npos2<>4 then Npos2:=2;
			'D':If Npos2<>1 then Npos2:=3;
			'S':If Npos2<>2 then Npos2:=4
		End
	End;
		if ord(ch)=27 then
	begin
	out:=true;
	esc:=true;
    end
	
End;

Procedure ScrnOutput; {haghtogh khakhatsoghi stugum ev nerkum}
Var Color:Word;
Begin
	Case Npos1 of
		1:Xpos1:=Xpos1-2;
		2:Ypos1:=Ypos1-2;
		3:Xpos1:=Xpos1+2;
		4:Ypos1:=Ypos1+2
	End;
		If getpixel(xpos1,ypos1)<>0 then
		If getpixel(xpos2,ypos2)<>0 then
		Begin
		out:=true;
		winner:=2
		End;
	Put(Xpos1,Ypos1,cyan);
	Case Npos2 of
		1:Xpos2:=Xpos2-2;
		2:Ypos2:=Ypos2-2;
		3:Xpos2:=Xpos2+2;
		4:Ypos2:=Ypos2+2
	End;
	If getpixel(xpos2,ypos2)<>0 then
		If getpixel(xpos1,ypos1)<>0 then
		Begin
		out:=true;
		out:=true;
		If winner=2 then
			winner:=0
		else
			winner:=1
		End;
	Put(Xpos2,Ypos2,yellow);
	delay(Vel)
End;

procedure rules;
begin
cleardevice;
setcolor(2);
s:='‚―λ«‡―σ‘©―σ«';
outtextxy(divx-length(s)*4,100,s);
s:='£• «γν«  ‡―σοι ƒ‰ο‰— η―ο‡•« ηλο―σ§•ρ:';
setcolor(7);
outtextxy(divx-length(s)*4,115,s);
s:='£ρ―£ §ολ―σ§  £‘―£, ‰‘‰ η―ο‡ ƒ™λ‰—  •«α-―ο ™―α«‡―ν•:';
outtextxy(divx-length(s)*4,130,s);
setcolor(6);
s:='ηλο―σ§';
outtextxy(divx-length(s)*4,180,s);
s:='        ™£ρ―£` λ‰ο‰σ` W, «‰οχ‰σ` S, ε` D, ΅™` A:';
setcolor(7);
outtextxy(divx-length(s)*4,195,s);
setcolor(3);
outtextxy(divx-length(s)*4,195,'γ―σ©ν');
s:='      ™£ρ―£` λ‰ο‰σ` ^, «‰οχ‰σ` v, ε` >, ΅™` <:';
setcolor(7);
outtextxy(divx-length(s)*4,210,s);
setcolor(14);
outtextxy(divx-length(s)*4,210,'†‰£•«');
s:='ζ‰“•§«‰ο';
setcolor(9);
outtextxy(divx-length(s)*4,260,s);
s:='£ρ―£« «‡‡‰§ §ο…α•: £ρ―£• …―σ©«`        , §ο…α•«`      :';
setcolor(7);
outtextxy(divx-length(s)*4,275,s);
setcolor(3);
outtextxy(divx-length(s)*4+360,275,'γ―σ©ν');
setcolor(14);
outtextxy(divx-length(s)*4+544,275,'‡‰£•«');
s:='£ρ―£« «‡‡‰§ ™£ρ―£•: £ρ―£«‰ο• …―σ©«‰ο`       ‰σ        :';
setcolor(7);
outtextxy(divx-length(s)*4,290,s);
setcolor(14);
outtextxy(divx-length(s)*4+385,290,'‡‰£•«');
setcolor(3);
outtextxy(divx-length(s)*4+456,290,'γ―σ©ν');
readkey;
cleardevice
end;


Procedure the_game; {Tron}
var s:string;
 Begin

	exitgame:='Y';
	While exitgame='Y' do
	Begin
		yellowp:=0;
		bluep:=0;
		vel:=10;
		cleardevice;
		esc:=false;
		while (bluep<ngames) and (yellowp<ngames) and (not esc) do
		Begin
		initvar;
		SetColor(9);

			setlinestyle(0,0,3);
			Rectangle(0,20,getmaxx,getmaxy);

			str(bluep,bl);
			str(yellowp,ye);
			s:='        '+ye+':'+bl+'          ';
			settextstyle(0,0,2);
			setcolor(green);
				outtextxy(divx - length(s)*8,2,s);
				setcolor(14);
				outtextxy(divx - length(s)*8,2,'†‰£•«');
				setcolor(3);
				outtextxy(divx + length(s)*8-112,2,'γ―σ©ν');


			winner:=0;

			While out=False do
			Begin
				Presskey(Npos1,Npos2);
				ScrnOutput;
			End;
			if not esc then
			begin
				If winner=1 then
					bluep:=bluep+1
				Else If winner=2 then
					yellowp:=yellowp+1;
				s:='        '+ye+':'+bl+'          ';
				setcolor(black);
				outtextxy(divx - length(s)*8,2,s);
				outtextxy(divx - length(s)*8,2,'†‰£•«');
				outtextxy(divx + length(s)*8-112,2,'γ―σ©ν');

				str(bluep,bl);
				str(yellowp,ye);
				s:='        '+ye+':'+bl+'          ';

				setcolor(green);
				outtextxy(divx - length(s)*8,2,s);
				setcolor(14);
				outtextxy(divx - length(s)*8,2,'†‰£•«');
				setcolor(3);
				outtextxy(divx + length(s)*8-112,2,'γ―σ©ν');
				readkey
			end;
			cleardevice
		End;
		if not esc then
		begin
		settextstyle(0,0,4);
		If bluep>yellowp then
		Begin
			setcolor(lightblue);
			outtextxy(divx-250,divy - 20,'γ―σ©ν £‘‰ρ!')
		End
		Else if bluep<yellowp then
		Begin
			setcolor(yellow);
			outtextxy(divx-225,divy - 20,'†‰£•« £‘‰ρ!')
		End;
		readkey;
		cleardevice;
		k:=1;
		settextstyle(0,0,3);
		setcolor (red);
		outtextxy(divx-95,divy-50,'ª―ο ™ό£');
			Repeat
					case k of
						1:newgame(10,9,2,1);
						2:newgame(9,10,1,2)
					End;
				c:=readkey;

				case ord(c) of
					77: k:=k+1;
					75: k:=k-1
				End;

				case k of
					3:k:=1;
					0:k:=2
				End

			Until (ord(c)=13)or(ord(c)=32);
		cleardevice;
		case k of
			1:exitgame:='Y';
			2:exitgame:='N'
		End
		end else exitgame:='N';
	End;
	cleardevice
 End;

Procedure gamelvl; {*Tron* 1 hogi / 2 hogi / paymanner / elq}
Begin
	gamemenu1(7,7,7,7,8,8,8,8);
	k:=1;
	Repeat
		case k of
			1:gamelvl1(10,9,9,9,2,1,1,1);
			2:gamelvl1(9,10,9,9,1,2,1,1);
			3:gamelvl1(9,9,10,9,1,1,2,1);
			4:gamelvl1(9,9,9,10,1,1,1,2)
		End;
		c:=readkey;

		case ord(c) of
			80: k:=k+1;
			72: k:=k-1
		End;

		case k of
			5:k:=1;
			0:k:=4
		End;

	Until (ord(c)=13)or(ord(c)=32);

	case k of
	1: ngames:=5;
	2: ngames:=10;
	3: ngames:=25;
	4: ngames:=50
	End;
	the_game;
	cleardevice
End;

 procedure gamemenu;
begin
	hidegrcursor;
	cleardevice;
	tronimage;
	cleardevice;
	repeat
	k:=1;
	Repeat
		case k of
			1:gamemenu1(10,9,9,9,2,1,1,1);
			2:gamemenu1(9,10,9,9,1,2,1,1);
			3:gamemenu1(9,9,10,9,1,1,2,1);
			4:gamemenu1(9,9,9,10,1,1,1,2)
		End;
		c:=readkey;

		case ord(c) of
			77: k:=k+1;
			75: k:=k-1
		End;

		case k of
			5:k:=1;
			0:k:=4
		End;

	Until (ord(c)=13)or(ord(c)=32);
	case k of
	1:
	begin
	_1p:=true;
	gamelvl
	end;
	2:
	begin
	_1p:=false;
	gamelvl
	end;
	3: rules
	End;
	until k=4;
	cleardevice;
end;
{======Tron======}

{======khndir======}

Procedure err(s:string); {tveri pashtpanutyun *skali tpum*}
Begin
	setcolor(red);
	outtextxy(divx-length(s)*4,450,s);
	delay(200);

	setcolor(0);
	outtextxy(divx-length(s)*4,450,s);
	setcolor(12)
End;

{kndirs}

procedure dub(z1:ash;n1:byte;a:real; var q1: byte);
var j1:byte;
begin
	q1:=0;
	for j1:=1 to n1 do
			if a=z1[j1] then 
					q1:=q1+1;
end;

procedure max(y2:vec;m2:byte; var mx:real);
var i2:byte;
begin
	mx:=y2[1];
	for i2:=2 to m2 do
			if mx<=y2[i2] then
			mx:=y2[i2];
end;

procedure eraser(x1,y1,x2,y3,col:integer); {x1,y1- line-i 1 coos; x2-verj x dirq, y3 line-i erk.}
var i:integer;
begin
	setcolor (col);
	for i:=x1 to x2 do
	begin
		line(i,y1,i,y1+y3);
		delay(3)
	end
end;

Procedure answer; {khndri lutsum}
var xmat:mat; yvec:vec; z:ash; {khndri pop.}
	smat: array [1..5,1..5] of string;
    j,l,m,n,q:byte;
	mets,m1,n1:real;
	f:text;

Var txt,txt1:string;
	dot:boolean;
	i,k:Integer;
	o,p:string;
Begin
	hidegrcursor;
	cleardevice;
	txt:='';

setcolor(red);
s:='§―σνχ…ο‰χ ν―£‰ο• χ« 2-•ρ 5 §•ε©χ―σ§`';
outtextxy(divx-length(s)*4-16,25,s);
	setcolor(9);
	outtextxy(divx+length(s)*4,25,'_');
	repeat
   	c:=readkey;
		setcolor(0);
		outtextxy(divx+length(s)*4,25,'_');
if (ord(c)>=48)and(ord(c)<=57)and(txt='') then
	begin
	val(c,m,k);
	if (m>=2)and(m<=5) then
		begin
		txt:=c;
		setcolor(9);
		outtextxy(divx+length(s)*4,25,txt)
		end
	end
else if ord(c)=8 then
	begin
	setcolor(0);
	outtextxy(divx+length(s)*4,25,txt);
	txt:=''
	end
	else if ord(c)=13 then
	If txt='' then
	Begin
		err('…ο‰χ ‘•λ');
		c:=#0
	End
until ord(c)=13;

txt:='';

setcolor(red);
s:='§―σνχ…ο‰χ ι©―σ«‰ο• χ« 2-•ρ 5 §•ε©χ―σ§`';
outtextxy(divx-length(s)*4-16,40,s);
	setcolor(9);
	outtextxy(divx+length(s)*4,40,'_');
	repeat
   	c:=readkey;
		setcolor(0);
		outtextxy(divx+length(s)*4,40,'_');
 if (ord(c)>=48)and(ord(c)<=57)and(txt='') then
	begin
	val(c,n,k);
	if (n>=2)and(n<=5) then
		begin
		txt:=c;
		setcolor(9);
		outtextxy(divx+length(s)*4,40,txt)
		end
	end
else if ord(c)=8 then
	begin
	setcolor(0);
	outtextxy(divx+length(s)*4,40,txt);
	txt:=''
	end
	else if ord(c)=13 then
	If txt='' then
	Begin
		err('…ο‰χ ‘•λ');
		c:=#0
	End
until ord(c)=13;

eraser(divx-length(s)*4-16,25,divx+length(s)*4+16,40,0);
str(m,o);
str(n,p);
setcolor(red);
s:='—ορο‰χ '+o+'x'+p+' αυ«• §νο•ρ';
settextstyle(0,0,2);
outtextxy(divx-length(s)*8,25,s);

setcolor(2);
setlinestyle(0,0,3);
rectangle(divx-n*50-2,divy-m*25-50-2,divx+n*50+2,divy+m*25-50+2);
setfillstyle(1,14);
bar(divx-n*50,divy-m*25-50,divx+n*50,divy+m*25-50);

setlinestyle(0,0,1);
setcolor(12);
for i:=1 to m-1 do
line(divx-n*50,divy-m*25-50+i*50,divx+n*50,divy-m*25-50+i*50);

for i:=1 to n-1 do
line(divx-n*50+i*100,divy-m*25-50,divx-n*50+i*100,divy+m*25-50);


for i:=0 to m-1 do
for j:=0 to n-1 do
begin
k:=0;
txt:='';
dot:=false;

Repeat
    settextstyle(0,0,1);
		setcolor(6);
		outtextxy(divx-n*50+j*100+10+k*8, divy-m*25-50+i*50+20,'_');
		c:=readkey;
		setcolor(14);
		outtextxy(divx-n*50+j*100+10+k*8, divy-m*25-50+i*50+20,'_');

		If (ord(c)=45)and(txt<>'') then
			err('§•«―σι• «­« ‡«―σ§ ‰« ‘λ• ι‹ƒ―σ§ ;)')
		Else If (txt='')and(c='.') then
			err('ª™χ« ‰ν• «­« ‡«‰—, ‘•λ …ο‰χ')
		Else If (txt='-')and(c='.') then
			err('§•«―σι «­«•ρ ‰ν― …ο‰χ ‘•λ, ©— ―α ‰ν...')
		Else If (ord(c)=46)and(dot) then
			err('ο«• §• ‡ο‰χ ‰ν• «­«')
		Else If (txt='0')and(ord(c)<>46)and(ord(c)<>8) then
			err('‹ο―©•ρ ‰ν― α§―η«χ ‡«‰— ‰ν• «­«')
		Else If ((ord(c)>57)or(ord(c)<48))and((ord(c)<>27)and(ord(c)<>13)and(ord(c)<>8)and(ord(c)<>45)and(ord(c)<>46)) then
			err('‘•λ, ι‰ρ•«χ ‘•ύλ …ο‰χ')
		Else If (ord(c)=8)and(k<>0) then
		Begin
			k:=k-1;
			If(ord(txt[length(txt)])=46) then dot:=false;
			setcolor(14);
			outtextxy(divx-n*50+j*100+10+k*8, divy-m*25-50+i*50+20,txt[length(txt)]);
			txt:=copy(txt,0,length(txt)-1);
			setcolor(6);
			outtextxy(divx-n*50+j*100+10,divy-m*25-50+i*50+20,txt)
		End
		Else If (length(txt)>9)then
			err('λ«­««‰ο• χ« αγ‰ύνχ  …‰ο‹«ρ• 9-')
		Else If (ord(c)>47)and(ord(c)<58)or(ord(c)=45)or(ord(c)=46) then
		Begin
			If ord(c)=46 then
				dot:=true;
			txt:=txt+c;
			setcolor(6);
			outtextxy(divx-n*50+j*100+10+k*8, divy-m*25-50+i*50+20, c);
			k:=k+1
		End
		Else If ord(c)=13 then

			If (txt='')or(txt='-') then
			Begin
				err('™«‡ο―ύσ§ ‰«χ λον‰— ‘λ• §―σνχ…ο―σ§, ‡―σ ‡‰η α‰χ λ‰οερο‰—');
				c:=#0
			End
			Else If (pos('.',txt)<>0)and(copy(txt,length(txt),1)='0') then
			Begin
				err('™«‡ο―ύσ§ ‰«χ ―ν―ο©•« ‘λ•ρ ‰ν― α…ο‰— λ‰—«―ο‡ ‹ο―«‰ο');
				c:=#0
			End
			Else If (copy(txt,length(txt),1)='.') then
			Begin
				err('™«‡ο―ύσ§ ‰«χ §―σνχ…ο‰χ ›•­ν ‘•λ');
				c:=#0
			End
	Until (ord(c)=13)or(ord(c)=27);
		smat[i+1,j+1]:=txt;
end;
  settextstyle(0,0,1);
  setcolor(4);
  s:='θ‰£§‰χ Space νλ©—«‰ο ϋ©—―σ§ νγ‰—―σ §ο';
  outtextxy(divx-length(s)*4,getmaxy-60,s);
  repeat c:=readkey until ord(c)=32;
  setcolor(0);
  outtextxy(divx-length(s)*4,getmaxy-60,s);

	assign(f,'..\547.txt');
	rewrite(f);
	writeln(f,o+' '+p);
	for i:=1 to m do
	begin
		txt1:='';
		for j:=1 to n do
		begin
		eraser(divx-n*50+(j-1)*100+10, divy-m*25-50+(i-1)*50+20,divx-n*50+(j-1)*100+90,16,14);
		str(xmat[i,j],txt);
		txt1:=txt1+smat[i,j]{copy(txt,0,9)}+' ' {copy(txt,0,9)};
		end;
		writeln(f,txt1)
	end;
	close(f);

    Reset(f);
    Readln(f,txt);
	val(copy(txt,1,pos(' ',txt)-1),m,k);
	delete(txt,1,pos(' ',txt));
	val(copy(txt,1,length(txt)),n,k);

	setcolor(6);
	settextstyle(0,0,1);
  for i:=1 to m do
	begin
		readln(f,txt);
		for j:=1 to n do
		begin
			val(copy(txt,1,pos(' ',txt)-1),xmat[i,j],k);
			outtextxy(divx-n*50+(j-1)*100+10, divy-m*25-50+(i-1)*50+20,copy(txt,1,pos(' ',txt)-1));
			delete(txt,1,pos(' ',txt));
			str(xmat[i,j],s);
			delay(200);
		end
	end;
	for i:=1 to m do 
	begin
		yvec[i]:=0;
		for j:=1 to n do
			z[j]:=xmat[i,j];
		for j:=1 to n do
		begin
			dub(z,n,z[j],q);
			yvec[i]:=q+yvec[i]
		end;
	end;
	max(yvec,m,mets);
	for i:=m downto 1 do
		if mets=yvec[i] then
		begin
			l:=i;
			break
		end;
	if l<>0 then str(l,s) else s:='©‡γ•ι• ν―£ α';
	setcolor(2);
  settextstyle(0,0,2);

	s:='βνι™«` '+s;
	outtextxy(divx-length(s)*8,divy+120,s);

  setcolor(4);
  settextstyle(0,0,1);
  s:='θ‰£§‰χ Space ‡―σοι …—―σ §ο';
  outtextxy(divx-length(s)*4,getmaxy-60,s);
  repeat c:=readkey until ord(c)=32;
	cleardevice;
	setfillstyle(1,15);
	bar(0,0,getmaxx,getmaxy-37)
 End;


{======khndir======}

Procedure errscr; {Blue Screen :]}
Begin
	hidegrcursor;
	cleardevice;
	setbkcolor(1);
	setcolor(15);
	settextstyle(0,0,1);
	outtextxy(0,10,'A problem has been detected and windows has been shut down to prevent damage');
	outtextxy(0,25,'to your computer.');
	outtextxy(0,50,'DRIVER_IRQL_NOT_LESS_OR_EQUAL');
	outtextxy(0,75,'If this is the first time you'+#39+'v seen this stop error screen,');
	outtextxy(0,90,'restart your computer, If this screen appears again, follow');
	outtextxy(0,105,'these steps:');
	outtextxy(0,130,'Check to make sure any new hardware or software is properly installed.');
	outtextxy(0,145,'If this is a new installation, ask your hardware or software manufacturer');
	outtextxy(0,160,'for any windows updates you might need.');
	outtextxy(0,185,'If problems continue, disable or remove any newly installed hardware');
	outtextxy(0,200,'or software. Disable BIOS memory options such as caching or shadowing.');
	outtextxy(0,215,'If you need to use Safe Mode to remove or disable components, restart');
	outtextxy(0,230,'your computer, press F8 to select Advanced Startup Options, and then');
	outtextxy(0,245,'select Safe Mode.');
	outtextxy(0,270,'Technical information:');
	outtextxy(0,285,'*** Stop: 0x000000D1 (0x00000000C,0x00000002,0x00000000,0xF86B5A89)');
	outtextxy(0,335,'***       gv3.sys - Address F86B5A89 base at F86B50000, DateStamp 3dd991eb');
	outtextxy(0,360,'Beginning dump of physical memory');
	outtextxy(0,375,'Physical memory dump complete.');
	outtextxy(0,390,'Contact your system administrator or technical support group for further');
	outtextxy(0,405,'assistance.');
 readkey;
 readkey;
 readkey;
	setbkcolor(0);
	cleardevice;
	settextstyle(0,0,10);

		for i:=15 downto 0 do
	Begin
		setcolor(i);
		outtextxy(divx-60,divy-40,';');
		outtextxy(divx-20,divy-35,']');
		delay(200)
	End;
	cleardevice;
	setfillstyle(1,15);
	bar(0,0,getmaxx,getmaxy-37)
End;

procedure time;
begin
	settextstyle(0,0,1);
	gettime(hh,mi,se,ms);
	str(hh,hhs);
	str(mi,mis);
	str(se,ses);
	if	length(hhs)=1 then hhs:='0'+hhs;
	if	hh=24 then hhs:='00';
	if	length(mis)=1 then mis:='0'+mis;
	if	length(ses)=1 then ses:='0'+ses;
	if (ses<>s0)or(mis<>m0)or(hhs<>h0) then
	begin
		setcolor(8);
		outtextxy(getmaxx-70,getmaxy-20,h0+':'+m0+':'+s0);
		setcolor(15);
		outtextxy(getmaxx-70,getmaxy-20,hhs+':'+mis+':'+ses);
		s0:=ses;
		m0:=mis;
		h0:=hhs;
	end;
end;

procedure wall;
begin
questpad:=false;
quest:=false;
start:=false;
setfillstyle(1,15);
bar(0,0,getmaxx,getmaxy-37);
settextstyle(0,0,9);
setcolor(2);
outtextxy(divx-225,divy-50,'¦‘-240');
end;

Begin
	initgraph(m,n,''); {grafikayi initsializatsum}
	initgraphmouse; {mkniki initsializatsum}

	divx:=getmaxx div 2;
	divy:=getmaxy div 2;
setgrcursor(divx,divy-60);
	wall;
	Repeat
		showgrcursor;
		setfillstyle(1,8);
		setlinestyle(0,0,1);
		bar(0,getmaxy-37,getmaxx,getmaxy);
		setfillstyle(1,3);
		setcolor(0);
		fillellipse(26,getmaxy-18,18,18);
		setfillstyle(1,8);
		bar(16,getmaxy-28,36,getmaxy-8);
		setfillstyle(1,4);

		bar(17,getmaxy-27,25,getmaxy-19);
		setfillstyle(1,1);
		bar(17,getmaxy-17,25,getmaxy-9);
		setfillstyle(1,2);
		bar(27,getmaxy-27,35,getmaxy-19);
		setfillstyle(1,12);
		bar(27,getmaxy-17,35,getmaxy-9);
		k:=0;
		repeat
			time;
			if readgrcursor(X,Y)=1 then
				If (X>=8)and(X<=44)and(Y<=getmaxy)and(Y>=getmaxy-36)and(start=false) then
					k:=1 {stugum start buttoni coords-i & krknoghutyan}
				Else If ((X<8)or(X>44)or(Y>getmaxy)or(Y<getmaxy-36)or(start))
						and	((start)and((X<0)or(X>153)or(Y>getmaxy-41)or(Y<getmaxy-253)))
						and (not((X>=159)and(X<=304)and(Y>=getmaxy-175)and(Y<=getmaxy-159)and(quest)))
						and (not((X>=159)and(X<=304)and(Y>=getmaxy-154)and(Y<=getmaxy-138)and(quest)))
						or (X>=getmaxx-85)and(X<=getmaxx-50)and(Y>=45)and(Y<=60)and(questpad) then
					k:=2
				else if (X>=10)and(X<=150)and(Y>=getmaxy-243)and(Y<=getmaxy-211)and(start) then
					k:=-1
				else if (X>=10)and(X<=150)and(Y>=getmaxy-206)and(Y<=getmaxy-174)and(start) then
					k:=-2
				else if (X>=10)and(X<=150)and(Y>=getmaxy-161)and(Y<=getmaxy-145)and(start) then
					k:=-3
				else if (X>=159)and(X<=304)and(Y>=getmaxy-175)and(Y<=getmaxy-159)and(quest) then
					k:=-4
				else if (X>=159)and(X<=304)and(Y>=getmaxy-154)and(Y<=getmaxy-138)and(quest) then
					k:=-5
				else if (X>=10)and(X<=150)and(Y>=getmaxy-80)and(Y<=getmaxy-48)and(start) then
					k:=-6
				else
					k:=0

		Until k<>0;

		case k of
			1:
			begin
				start:=true;
				setfillstyle(1,8);
				bar(0,getmaxy-253,153,getmaxy-39);
				setfillstyle(1,15);
				bar(3,getmaxy-250,150,getmaxy-41);

				setfillstyle(1,0);
				bar(10,getmaxy-243,42,getmaxy-211);
				setfillstyle(9,red);
				bar(15,getmaxy-240,40,getmaxy-215);
				setcolor(yellow);
				settextstyle(0,0,2);
				outtextxy(12,getmaxy-233,'TP');
				setfillstyle(1,0);

				setcolor(1);
				setlinestyle(0,0,3);
				setfillstyle(1,0);
				fillellipse(26,getmaxy-190,16,16);
				setcolor(15);
				settextstyle(0,0,2);
				outtextxy(20,getmaxy-195,'T');

				bar(10,getmaxy-161,42,getmaxy-145);
				settextstyle(0,0,2);
				setcolor(0);
				outtextxy(12,getmaxy-165,'?');
				setcolor(yellow);
				outtextxy(14,getmaxy-163,'?');
				setcolor(0);
				outtextxy(28,getmaxy-165,'!');
				setcolor(4);
				outtextxy(30,getmaxy-163,'!');

				setcolor(0);
				setlinestyle(0,0,1);
				line(133,getmaxy-160,133,getmaxy-152);
				line(134,getmaxy-159,137,getmaxy-156);
				line(134,getmaxy-153,136,getmaxy-155);

				setlinestyle(0,0,2);
				setcolor(8);
				line(3,getmaxy-90,150,getmaxy-90);

				setfillstyle(1,4);
				bar(10,getmaxy-80,42,getmaxy-48);
				setcolor(15);
				setlinestyle(0,0,3);
				fillellipse(27,getmaxy-64,12,12);
				setlinestyle(0,0,3);
				setcolor(15);
				line(26,getmaxy-68,26,getmaxy-60);


						setcolor(0);
				settextstyle(0,0,1);
				outtextxy(50,getmaxy-230,'Turbo Pascal');
				outtextxy(50,getmaxy-192,'Tron');
				outtextxy(50,getmaxy-160,'«‡•ο 547');
				{outtextxy(50,getmaxy-117,'–―σ›―σ§');}
				outtextxy(50,getmaxy-65,'—χ');
				delay(200)
			end;
			2: wall;
			-1:
			begin
				errscr;
        wall;
				start:=false
			end;
			-2:
			begin
				gamemenu;
        wall;
				start:=false
			end;
			-3:
			begin
			quest:=true;
			setcolor(8);
			setlinestyle(0,0,1);
			Rectangle(153,getmaxy-181,305,getmaxy-132);

			setfillstyle(1,15);
			bar(154,getmaxy-180,304,getmaxy-133);
			setfillstyle(1,9);
			settextstyle(0,0,2);
			bar(159,getmaxy-175,175,getmaxy-159);
			setcolor(14);
			outtextxy(161,getmaxy-174,'?');
			bar(159,getmaxy-154,175,getmaxy-138);
			setcolor(4);
			outtextxy(161,getmaxy-153,'!');

				setcolor(0);
				settextstyle(0,0,1);
				outtextxy(181,getmaxy-170,'β«ε');
				outtextxy(181,getmaxy-149,'–―σ›―σ§');
				end;
			-4:
				begin
				wall;
				questpad:=true;
				setfillstyle(1,8);
				bar(40,40,getmaxx-40,getmaxy-80);
				setfillstyle(1,15);
				bar(50,70,getmaxx-50,getmaxy-90);
				setfillstyle(1,4);
				bar(getmaxx-85,45,getmaxx-50,60);
				settextstyle(0,0,1);
				setcolor(15);
				outtextxy(getmaxx-71,49,'x');
				setgrcursor(20,20);
				print(divx-100,100,4,2,'«‡•ο 547');
				print(45,130,2,1,'β«ε`');
				print(45,145,1,1,'μολ›  MxN αυ«• §νο•ρ: €ον›‰— §νο•ρ• ©« λ‰οε•« ν―£• §ο,');
				print(45,160,1,1,'―ο γο―σ«―σ§  §‰›…―σ©« χ«―σ‘©§ƒ •οο λιο νοο‰ο:');
				print(45,225,2,1,'«‘›ο…ο‰ο`');
				print(45,240,1,1,'1.­λ‰— λ‰ν―ο• •« λιο νοο‰ο• χ«:');
				print(45,255,1,1,'2.­λ‰— λ‰ν―ο• λ‰ν―ο• §‰›…―σ©« νοο:');
				end;
			-5:
			begin
				answer;
        wall;
				start:=false
			end
		end;
	until k=-6;
Closegraph
End.
