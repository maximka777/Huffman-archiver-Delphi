unit Unit4;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, unit1;

type
  Tformcodes = class(TForm)
    ScrollBox1: TScrollBox;
    sg: TStringGrid;
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  formcodes: Tformcodes;
  len,i:integer;
implementation

{$R *.dfm}

procedure Tformcodes.FormShow(Sender: TObject);
begin
sg.Cells[0,0]:='Символ';
sg.Cells[1,0]:='ASCII';
sg.Cells[2,0]:='Код символа';
len:=length(codes);
sg.RowCount:=len+1;
for i := 0 to len-1 do begin
  sg.Cells[0,i+1]:=chr(codes[i].cod_symb);
  sg.Cells[1,i+1]:=inttostr(codes[i].cod_symb);
  sg.Cells[2,i+1]:=codes[i].code;
end;

end;

end.
