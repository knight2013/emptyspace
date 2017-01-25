unit AboutFrm;

interface

uses
  Windows, SysUtils, Classes, Forms,
  Graphics, Controls, ExtCtrls, StdCtrls, ShellApi;

type
  TForm4 = class(TForm)
    OKBtn: TButton;
    Memo1: TMemo;
    Image1: TImage;
    Label1: TLabel;
    procedure OKBtnClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form4: TForm4;

implementation

uses uVersion;

{$R *.DFM}

procedure TForm4.OKBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TForm4.Image1Click(Sender: TObject);
begin
 ShellExecute(Handle, 'open', 'mailto:soa_project@mail.ru', nil, nil, SW_SHOWNA);
end;

procedure TForm4.FormCreate(Sender: TObject);
begin
  Label1.Caption := 'v.'+ GetVersionStr(1);
end;

end.
