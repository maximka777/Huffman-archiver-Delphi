program Huffman;

uses
  Forms,
  Unit1 in 'Unit1.pas' {mainForm},
  Unit2 in 'Unit2.pas' {treeForm},
  Unit3 in 'Unit3.pas' {formAbout},
  Unit4 in 'Unit4.pas' {formcodes},
  Unit5 in 'Unit5.pas' {Formpb},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TmainForm, mainForm);
  Application.CreateForm(TtreeForm, treeForm);
  Application.CreateForm(TformAbout, formAbout);
  Application.CreateForm(Tformcodes, formcodes);
  Application.CreateForm(TFormpb, Formpb);
  Application.Run;
end.
