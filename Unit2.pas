unit Unit2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,unit1;

type
  TtreeForm = class(TForm)
    ScrollBox1: TScrollBox;
    imTree: TImage;
    procedure FormShow(Sender: TObject);
  private
  procedure draw_node(root:tpnode; x,y:integer);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  treeForm: TtreeForm;
  l_count:integer;
implementation

{$R *.dfm}


procedure leaf_count(node:tpnode);
begin
if node<> nil  then
begin
if (node^.right=nil) and (node^.left=nil) then inc(l_count);
if node^.left<>nil then leaf_count(node^.left);
if node^.right<>nil then leaf_count(node^.right);
end;
end;


procedure TtreeForm.draw_node(root: tpnode; x,y:integer);
const x_dist=40;
y_dist=60;
var count:integer;
c_child:integer;


procedure children_count(node:tpnode);
begin
if node<> nil  then
begin
if (node^.right<>nil) then begin inc(c_child);children_count(node^.right); end;
if (node^.left<>nil) then begin inc(c_child);children_count(node^.left); end;
end;
end;

procedure draw_right(node:tpnode; p_x,p_y:integer); forward;
procedure draw_left(node:tpnode; p_x,p_y:integer);
var x,y:integer;
begin
c_child:=0;
children_count(node^.right);
if node^.right<>nil then  count:=1+c_child
else count:=0;
x:= p_x-x_dist-(count*x_dist);
y:=p_y+y_dist;
  with imTree.Canvas do begin

     moveto(p_x,p_y);
     lineto(x,y);
     brush.color:=clwhite;
     textout(p_x-(abs(x-p_x))div 2,p_y+(abs(y-p_y))div 2,'0');
     brush.Color:=clblue;
     ellipse(x-18,y-15,x+18,y+18);
     if (node^.left=nil)and(node^.right=nil) then  begin
     textout(x-8,y-13,inttostr(node^.cod_symb));
     brush.Color:=clyellow;
     textout(x-5,y+3,chr(node^.cod_symb));
     end;
  end;
 if node^.left<> nil then draw_left(node^.left,x,y);
 if node^.right<> nil then draw_right(node^.right,x,y);
end;

procedure draw_right(node:tpnode; p_x,p_y:integer);
var x,y:integer;
begin
c_child:=0;
children_count(node^.left);
if node^.left<>nil then  count:=1+c_child
else count:=0;
x:= p_x+x_dist+(count*x_dist);
y:=p_y+y_dist;
  with imTree.Canvas do begin

     moveto(p_x,p_y);
     lineto(x,y);
     brush.color:=clwhite;
     textout(p_x+(abs(x-p_x))div 2,p_y+(abs(y-p_y))div 2,'1');
     brush.Color:=clblue;
     ellipse(x-18,y-15,x+18,y+18);
     if (node^.left=nil)and(node^.right=nil) then begin
     textout(x-8,y-13,inttostr(node^.cod_symb));
     brush.Color:=clyellow;
     textout(x-5,y+3,chr(node^.cod_symb));
     end;
  end;
 if node^.left<> nil then draw_left(node^.left,x,y);
 if node^.right<> nil then draw_right(node^.right,x,y);
end;

begin
if root<>nil then begin
  with imTree.Canvas do begin
     brush.Color:=clblue;
     ellipse(x-18,y-15,x+18,y+18);
     if (root^.left=nil)and(root^.right=nil) then begin
     textout(x-8,y-13,inttostr(root^.cod_symb));
     brush.Color:=clyellow;
     textout(x-5,y+3,chr(root^.cod_symb));
     end;
  end;
  draw_left(root^.left,x,y);
  draw_right(root^.right,x,y);
end;

end;

procedure TtreeForm.FormShow(Sender: TObject);
var q:tpnode;
width:integer;
begin
imtree.canvas.font.Name:='timesnewroman';
imtree.canvas.brush.Color:=clwhite;
imtree.canvas.fillrect(recT(0,0,25000,1000));
q:=root;
l_count:=0;
leaf_count(q);
scrollbox1.HorzScrollBar.Position:=12500;
if l_count=0 then exit;
draw_node(q,12500,20);
end;

end.
