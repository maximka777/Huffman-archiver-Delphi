unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, XPMan, Vcl.Menus, System.Actions, Vcl.ActnList, Vcl.ImgList,
  Vcl.Buttons,unit3, Vcl.ExtCtrls;

type
tpnode=^node;
itemCode=record
  cod_symb:byte;
  code:string;
end;
node=record
  cod_symb:byte;
  frequence:integer;
  left,right:tpnode;
end;
    tTable=array[0..255] of node;  // таблица со встречаемостью байтов
    talphabet=array of node;         // таблица байтов, входящих в файл (без нулевой встречаемости)
    tCodes=array of itemCode;          // таблица Хаффмана-кодов байтов
    tBuf=array of byte;

type
  TmainForm = class(TForm)
    OpnDlg: TOpenDialog;
    SvDlg: TSaveDialog;
    XPManifest1: TXPManifest;
    imList: TImageList;
    Panel1: TPanel;
    bEncode: TButton;
    bDecode: TButton;
    bTree: TButton;
    bcodes: TButton;
    Label2: TLabel;
    babout: TButton;
    Panel2: TPanel;
    memoLog: TMemo;
    Label3: TLabel;
    Panel3: TPanel;
    moutseq: TMemo;
    Label1: TLabel;
    chb: TCheckBox;
    procedure bcodesClick(Sender: TObject);
    procedure bEncodeClick(Sender: TObject);
    procedure bTreeClick(Sender: TObject);
    procedure bDecodeClick(Sender: TObject);
    procedure baboutClick(Sender: TObject);
    function Error(x: byte):boolean;

  private
  public
  end;

var
  mainForm: TmainForm;
  forest: TTable;
  alphabet:talphabet;
  i:integer;
  Root:tpnode;
  InPutSize, OutPutSize:int64;
  pathInput,pathOutput: string;
  Codes:tCodes;
  buf, buf_out:tBuf;
  buf_size,buf_out_size,tek:integer;
  sequence:string;
  numb_zero:byte;

implementation

{$R *.dfm}

uses Unit2, Unit4, Unit5;
{$I-}


procedure Initial_Table(var table: TTable);
var i:byte;
begin
for i:=0 to 255 do
     with table[i] do begin
       cod_symb:=i;
       frequence:=0;
       left:=nil;
       right:=nil;
     end;
end;


function makeAlphabet(t: ttable): talphabet;
var
len,i:word;
begin
len:=0;
SetLength(result,len);
i:=0;
while (t[i].frequence<>0)and(i<length(t)) do begin
 inc(len);
 setlength(result,len);
 result[len-1]:=t[i];
 inc(i);
 end;
end;

function getSeqSymb(a: byte; c: tCodes): string;  //получение кода байта
var i:byte;
begin
while c[i].cod_symb<>a do inc(i);
result:=c[i].code;
end;

function makeOutSequence(c: tCodes): string;
var f:file of byte;
a:byte;
begin
result:='';
for i:=0 to buf_size-1 do begin
a:=buf[i];
result:=result+getSeqSymb(a,c);
end;
end;

 {
function makeSize(path:string): int64;
var f:file of byte;
a:byte;
begin
result:=0;
assignfile(f,path);
reset(f);
result:=filesize(f);
closefile(f);
end;
 }
procedure makeTable(var t:ttable);
var f:file of byte;
i:integer;
begin
 for I := 0 to buf_size-1 do
 inc(t[buf[i]].frequence);
end;

function IntToBin(B:integer):string;
var i, Mask:integer;
begin
   Result:='';
   Mask:=1;
   for i:=0 to 7 do
     begin
        if (B and Mask)<>0 then Result:='1'+Result
        else Result:='0'+Result;
        Mask:=Mask shl 1;
     end;
end;


procedure makeTableCode(t:tpnode;  s:string; var i:integer);
begin
if assigned(t) then
begin
if (t^.right=nil)and(t^.left=nil) then  begin
 codes[i].cod_symb:=t^.cod_symb;
 codes[i].code:=s;
 inc(i);
end;
makeTableCode(t^.left,s+'0',i);
makeTableCode(t^.right,s+'1',i);
end;
end;

procedure swap(var a, b: node);
var temp:node;
begin
temp:=a;
a:=b;
b:=temp;
end;

procedure sortDyn(var t: talphabet);
var i,j,len: integer;
f:boolean;
begin
f:=true;
len:=length(t);
for i:=len-1 downto 0 do begin
   if f then begin
   f:=false;
    for j:=1 to i do
           if t[j-1].frequence < t[j].frequence then begin
               swap(t[j],t[j-1]);
               f:=true;
           end;
           end else
           break;

end;
end;

procedure deleteTree(var root: tpnode);
begin
if root<> nil then begin
     deletetree(root^.left);
     deletetree(root^.right);
     dispose(root);
  end;
end;


procedure makeTree(table: talphabet;var root: tpnode);
var
len:word;
q,l,r:tpnode;
begin
len:=length(table);
while len>1 do begin
new(l);
new(r);
l^.frequence:=table[len-1].frequence;
r^.frequence:=table[len-2].frequence;
l^.left:=table[len-1].left;
r^.left:=table[len-2].left;
l^.right:=table[len-1].right;
r^.right:=table[len-2].right;
l^.cod_symb:=table[len-1].cod_symb;
r^.cod_symb:=table[len-2].cod_symb;
new(q);
q^.left:=l;
q^.right:=r;
q^.cod_symb:=0;
q^.frequence:=r^.frequence+l^.frequence;
len:=len-1;
setlength(table,len);
table[len-1]:=q^;
sortDyn(table);
end;
root:=q;
end;


procedure sort(var t: ttable);
var i,j: integer;
begin
for i:=254 downto 0 do
for j:=0 to i do
  if t[j].frequence<t[j+1].frequence then swap(t[j],t[j+1]);

end;

procedure makebuf(path:string);
var f:file of byte;
begin
assignfile(f,path);
reset(f);
buf_size:=filesize(f);
setlength(buf,buf_size);
blockread(f,buf[0],buf_size);
close(F);
end;

procedure TmainForm.bcodesClick(Sender: TObject);
begin
formcodes.showmodal;
end;


procedure write_buf_in_outfile(path:string);
var f:file of byte;
begin
assignfile(f,path);
rewrite(f);
blockwrite(f,buf_out[0],buf_out_size);
outputsize:=filesize(f);
closefile(F);
end;

function BinToInt(S:String):integer;
var i,Mask:integer;
begin
   Result:=0;
   Mask:=1;
   for i:=Length(S) downto 1 do
     begin
        if S[i]='1' then
           Result:=Result or Mask;
        Mask:=Mask shl 1;
     end;
end;

procedure bufAddInfo();
type
  TMyInteger = array[0..3] of byte;
var i,j,len:integer;
a:byte;
MyInteger:TMyInteger;

function IntOnFourByte(int:integer):tmyinteger;
begin
  Pointer(result):=Pointer(int);
end;

begin
i:=1;
len:=length(alphabet);
setlength(buf_out,1);
buf_out[0]:=len-1;
i:=1;
for j:=0  to len-1 do begin
i:=i+5;
setlength(buf_out,i);
  a:=alphabet[j].cod_symb;
  buf_out[i-5]:=a;
  myinteger:=IntOnFourByte(alphabet[j].frequence);
  buf_out[i-4]:=myinteger[0];
  buf_out[i-3]:=myinteger[1];
  buf_out[i-2]:=myinteger[2];
  buf_out[i-1]:=myinteger[3];
end;
inc(i);
setlength(buf_out,i);
numb_zero:=8-(length(sequence) mod 8);
if numb_zero=8 then numb_zero:=0;

a:=numb_zero;
buf_out[i-1]:=a;
buf_out_size:=i;
end;

procedure bufOutfile(seq:string);
type
tmas=array of string;
var i,j,len:integer;
mas:tmas;
lenSeq,lenMas:integer;
a,B:byte;
begin
len:=length(buf_out);
i:=len;   //i is size of buf_out
lenSeq:=length(seq);
lenMas:=lenSeq div 8;
if numb_zero <>0  then  inc(lenMas);
setlength(mas,lenMas);
for j := 0 to lenMas-2 do
begin
  mas[j]:=Copy(seq, j*8+1, 8);
end;

  mas[j]:=copy(seq,j*8+1,8-numb_zero);
 // numb_zero:=0;
while length(mas[j])<8 do begin
mas[j]:=mas[j]+'0';
//inc(numb_zero);
end; //ELSE INC(I);

FOR J:=0 TO LENMAS-1 do begin
a:=bintoint(mas[j]);
   inc(i);
   setlength(buf_out,i);
   buf_out[i-1]:=a;
end;
buf_out_size:=i;
end;

procedure makefile(p:tpnode; var buf:tBuf);
var b:char;
j:integer;
begin
j:=1;
i:=0;
setlength(buf,0);
formpb.pb.Max:=length(sequence);
formpb.pb.position:=j;
repeat
  b:=sequence[j];
  inc(j);
  formpb.pb.position:=j;
  if b='0' then if p^.left<>nil then  p:=p^.left;
  if b='1' then if p^.right<>nil then  p:=p^.right;
if (p^.left=nil)and(p^.RIGHt=nil) then begin
    inc(i);
    setlength(buf,i);
    buf[i-1]:=p^.cod_symb;
    p:=root;
end;
until j> length(sequence);
end;

procedure TmainForm.bDecodeClick(Sender: TObject);
type
  TMyInteger = array[0..3] of byte;
var f:file of byte;
i,j,k,lenSeqPrev,len_alphabet,myint:integer;
numb_zero,a:byte;
MyInteger:TMyInteger;
s:string;
temp:char;
flag,fexit:boolean;

function FourByteONInt(a:TMyInteger):integer;
begin
Pointer(result):=Pointer(a);
end;

begin
Opndlg.Filter := 'Huf-архивы (.huf)|*.huf|';
if  OpnDlg.Execute then
if svdlg.execute then
begin
btree.Enabled:=true;
bcodes.Enabled:=true;
   deleteTree(root);
   root:=nil;
   pathinput:=opndlg.FileName;
   pathoutput:=svdlg.FileName;
   //проверка на ошибки ввода и заполнение buf
   assignfile(f,pathinput);
   reset(f);
   Error(IOResult);
   if Error(IOResult) then exit;
   buf_size:=filesize(f);
   setlength(buf,buf_size);
   blockread(f,buf[0],buf_size);
   closefile(f);
   //проверка на ошибки ввода и заполнение buf
   formpb.Show;
   //считывание алфавита
   len_alphabet:=buf[0]+1;
   setlength(alphabet,len_alphabet);
   i:=0;
   j:=1;
   while i<len_alphabet do begin
    alphabet[i].cod_symb:=buf[j];
     myinteger[0]:=buf[j+1];
      myinteger[1]:=buf[j+2];
      myinteger[2]:=buf[j+3];
       myinteger[3]:=buf[j+4];
       MyInt:=FourByteOnInt(myinteger);
        alphabet[I].frequence:=myint;
        inc(i);
        j:=j+5;
          end;
   //считывание алфавита
   //if numb_zero=buf[j] then showmessage('ravny')
   // else  showmessage('ne ravny');

   numb_zero:=buf[j];
   root:=nil;
   makeTree(alphabet,root);
   //создание по дереву таблицы кодов
   setlength(codes,len_alphabet);
   i:=0;
   s:='';
   makeTableCode(root,s,i);
   //создание по дереву таблицы кодов
   //формрование последовательности бит
   sequence:='';
   for j:=j+1 to buf_size-1 do
   sequence:=sequence+IntToBin(buf[j]);
   delete(sequence,length(sequence)-numb_zero+1,numb_zero);
   //формрование последовательности бит

   //формирование buf_out
     setlength(buf_out,0);
     makefile(root,buf_out);
     buf_out_size:=length(buf_out);
   //формирование buf_out
   //запись buf_out  в файл
   assignfile(f,pathoutput);
   rewrite(f);
   blockwrite(f,buf_out[0],buf_out_size);
   closefile(F);
   MessageBox(Handle,PChar('Распаковка закончена'),PChar('Уведомление'),MB_ICONINFORMATION+MB_OK);
   formpb.close;
   formpb.pb.Position:=0;
   memolog.lines.add('=============================================');
   memolog.Lines.Add('Файл: "'+pathinput+'" распакован и сохранён в: "'+pathoutput+'"');
   memolog.lines.add('=============================================');
   //запись buf_out  в файл



   end;
end;

procedure TmainForm.bEncodeClick(Sender: TObject);
var f:file of byte;
len:word;
s:string;
begin

//открыть
Opndlg.Filter := 'Все файлы|*.*|';
if OpnDlg.Execute then begin

deleteTree(root);
root:=nil;
pathinput:=opndlg.filename;
   //====проверка на ошибки=======
   assignfile(f,pathinput);
   reset(f);
   if Error(IOResult) then exit;
   inputSize:=filesize(f);
   closefile(f);
   //====проверка на ошибки=======
   btree.Enabled:=true;
   bcodes.Enabled:=true;

   //++++++++++++++Log++++++++++++++++++++++
   memolog.lines.add('=============================================');
   memolog.lines.add('Входной файл: "'+pathInPut+'"');
   memolog.lines.add('Размер входного файла: '+inttostr(inputSize)+' байт');
   memolog.lines.add('=============================================');
   //++++++++++++++Log++++++++++++++++++++++
   makebuf(pathInPut);
   initial_table(forest);
   makeTable(forest);
   sort(forest);
   formpb.show;
   alphabet:=makeAlphabet(forest);
   len:=length(alphabet);
   if len<2 then begin
     formpb.Close;
     formpb.pb.Position:=0;
     memolog.lines.add('=============================================');
   memolog.Lines.Add('Невозможно сжать файл: '+pathinput+'.');
   memolog.lines.add('=============================================');
   btree.Enabled:=false;
   bcodes.Enabled:=false;
   exit;
   end;
   formpb.pb.Position:=formpb.pb.Position+10;
   makeTree(alphabet,root);
   formpb.pb.Position:=formpb.pb.Position+10;
   setlength(codes,len);
   i:=0;
   s:='';
   makeTableCode(root,s,i);
   formpb.pb.Position:=formpb.pb.Position+10;
   pathOutput:=pathInPut+'.huf';
   sequence:=makeoutSequence(codes);
   formpb.pb.Position:=formpb.pb.Position+30;
if  chb.checked=true then  moutseq.text:=sequence;
   //sortSymb(codes);
   bufAddInfo();
   formpb.pb.Position:=formpb.pb.Position+10;
   bufOutfile(sequence);
   formpb.pb.Position:=formpb.pb.Position+30;
   write_buf_in_outfile(pathOutPut);
   MessageBox(Handle,PChar('Архивация закончена'),PChar('Уведомление'),MB_ICONINFORMATION+MB_OK);
   formpb.close;
//++++++++++++++Log++++++++++++++++++++++
   memolog.lines.add('=============================================');
   memolog.lines.add('Выходной файл: "'+pathInPut+'.huf'+'"');
   memolog.lines.add('Размер выходного файла: '+inttostr(outputSize)+' байт');
   memolog.Lines.Add('Степень сжатия: '+inttostr(round(100-100*outputsize/InPutSize))+'%');
   memolog.lines.add('=============================================');
   formpb.pb.Position:=0;
   //++++++++++++++Log++++++++++++++++++++++
end;
end;

procedure TmainForm.bTreeClick(Sender: TObject);
begin
treeForm.showmodal;
end;

function TmainForm.Error(x: byte):boolean;
begin
result:=false;
If x <> 0 then
 begin
 result:=true;
 showMessage('Ошибка №'+inttostr(x));
 memolog.lines.add('=============================================');
   memolog.Lines.Add('Ошибка Ввода/Вывода: №'+inttostr(x));
   memolog.lines.add('=============================================');
 exit;
 end;
end;

procedure TmainForm.baboutClick(Sender: TObject);
begin
formAbout.showmodal;
end;

end.
