unit OptionFrm;

interface

uses
  Windows, SysUtils, Classes, Graphics, Forms,
  FileCtrl, Controls, Mask, StdCtrls, ToolEdit, Dialogs, ComCtrls, ExtCtrls;


type
  TForm2 = class(TForm)
    DriveComboDialog: TDriveComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    Button2: TButton;
    ActiveCheck: TCheckBox;
    ProtectCopyCheck: TCheckBox;
    SkinFileNameEdit: TEdit;
    Button3: TButton;
    OpenDialog: TOpenDialog;
    DriveCombo: TComboBox;
    Label3: TLabel;
    cbxMetric: TComboBox;
    cbxTransparent: TCheckBox;
    ColorDialog: TColorDialog;
    btnTransparentColor: TButton;
    shpTransparentColor: TShape;
    trbAlfaBland: TTrackBar;
    procedure FormShow(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure btnTransparentColorClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

uses MainFrm;

{$R *.DFM}

procedure TForm2.FormShow(Sender: TObject);
var i: integer;
begin
 DriveCombo.Items.Clear;
 for i := 0 to DriveComboDialog.Items.Count - 1 do
     DriveCombo.Items.Add(
          UpperCase( Copy(DriveComboDialog.Items[i], 1, 1) + ': ')
        + UpperCase( Copy(DriveComboDialog.Items[i], 5, Length(Trim(DriveComboDialog.Items[i]))-5 ) ));
    DriveCombo.Items.Add('#: ALL FIXED');

for i := 0 to  DriveCombo.Items.Count - 1 do
   if UpperCase( Copy(DriveCombo.Items[i], 1, 1))[1] = DriveLetter then
      DriveCombo.ItemIndex := i;

    Form2.ActiveCheck.Checked := Form1.Enabled;
    Form2.OpenDialog.InitialDir := SkinFileDir;
    Form2.SkinFileNameEdit.Text := SkinFileName;
    Form2.ProtectCopyCheck.Checked := CheckCopy;
    cbxMetric.ItemIndex := vMetric;
    Form2.cbxTransparent.Checked := Form1.TransparentColor;
    Form2.trbAlfaBland.Position := Form1.AlphaBlendValue;
    Form2.shpTransparentColor.Brush.Color := Form1.TransparentColorValue;


end;


procedure TForm2.Button3Click(Sender: TObject);
begin
  if OpenDialog.Execute then
    begin
      SkinFileNameEdit.Text := OpenDialog.FileName;
    end;
end;

procedure TForm2.btnTransparentColorClick(Sender: TObject);
begin
  if ColorDialog.Execute then
    shpTransparentColor.Brush.Color := ColorDialog.Color;
end;

end.
