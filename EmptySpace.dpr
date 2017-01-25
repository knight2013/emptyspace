program EmptySpace;

uses
  Forms,
  MainFrm in 'MainFrm.pas' {Form1},
  OptionFrm in 'OptionFrm.pas' {Form2},
  AboutFrm in 'AboutFrm.pas' {Form4},
  libLinks in 'libLinks.pas',
  uVersion in 'uVersion.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'EmptySpace';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm4, Form4);
  Application.Run;
end.
