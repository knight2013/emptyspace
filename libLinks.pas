unit libLinks;

interface

uses Windows, SysUtils, FileUtil, ShlObj, ComObj, ActiveX, Registry, IniFiles, rxStrUtils;


function  CreateShortcut(const CmdLine, Args, WorkDir, LinkFile: string):IPersistFile;
function  CreateShortcuts(vPath: string): string;
function  CreateAppPath(vPath, vExeName: string): string;
function  GetTCPath(ASection: string): string;
procedure DeleteAppPath(vPath, vExeName: string);
procedure DeleteShortcuts(vPath: string);
procedure CreateAutoRunLoader;
procedure DeleteAutoRunLoader;
function CreateTotalCmdButton(vPath, vExeName, vCmd, vComment, ANumIcon: string): integer;
function DeleteTotalCmdButton(vNumButton: integer): integer;
function  GetWinCmdIniFileName: string;
function MyGetEnvironmentVariable(AString: string): string;

implementation

function CreateShortcut(const CmdLine, Args, WorkDir, LinkFile: string):IPersistFile;
var
  MyObject  : IUnknown;
  MySLink   : IShellLink;
  MyPFile   : IPersistFile;
  WideFile  : WideString;
begin
    MyObject := CreateComObject(CLSID_ShellLink);
    MySLink := MyObject as IShellLink;
    MyPFile := MyObject as IPersistFile;
    with MySLink do
    begin
      SetPath(PChar(CmdLine));
      SetArguments(PChar(Args));
      SetWorkingDirectory(PChar(WorkDir));
    end;
    WideFile := LinkFile;
    MyPFile.Save(PWChar(WideFile), False);
    Result := MyPFile;
end;

function MyGetEnvironmentVariable(AString: string): string;
type
  TLPCSTR = array [0..254] of Char;

var
    lpName : TLPCSTR;
    lpBuffer : TLPCSTR;
    nSize : DWORD;
    i: integer;
begin
  nSize := 255;

 for i := 0 to Length(AString) - 1 do
    lpName[i] := AString[i+1];
    lpName[i] := #0;

 GetEnvironmentVariable(lpName, lpBuffer, nSize);

 for i := 0 to nSize  do
  begin
    if lpBuffer[i] = #0 then Break;
    Result := Result + lpBuffer[i];
  end;
    Result := Trim(Result);
end;


function CreateShortcuts(vPath: string): string;
var Directory, ExecDir: String;
    MyReg: TRegIniFile;
begin
    MyReg := TRegIniFile.Create();
    MyReg.RootKey := HKEY_CURRENT_USER;
    MyReg.OpenKey('Software\MicroSoft\Windows\CurrentVersion\Explorer', False);

    ExecDir := vPath;
    Directory := MyReg.ReadString('Shell Folders', 'Programs', '') + '\' + 'ExCleaner';
    CreateDir(Directory);
    MyReg.Free;

//    CreateAutoRunLoader;

    CreateShortcut(ExecDir + '\ExCleaner.exe', '', ExecDir,
      Directory + '\ExCleaner.lnk');
    CreateShortcut(ExecDir + '\Readme.txt', '', ExecDir,
      Directory + '\Readme.lnk');
    CreateShortcut(ExecDir + '\Install.exe', '', ExecDir,
      Directory + '\Uninstall.lnk');

     Result := Directory;
end;

function  CreateAppPath(vPath, vExeName: string): string;
var MyReg: TRegIniFile;
begin
    MyReg := TRegIniFile.Create('');
    MyReg.RootKey := HKEY_LOCAL_MACHINE;
    MyReg.WriteString('Software\MicroSoft\Windows\CurrentVersion\App Paths\'+vExeName, '', vPath+'\'+vExeName);
    MyReg.WriteString('Software\MicroSoft\Windows\CurrentVersion\App Paths\'+vExeName, 'Path', vPath);
    MyReg.Free;
end;

procedure DeleteShortcuts(vPath: string);
var Directory, ExecDir: String;
    MyReg: TRegIniFile;
    sa : string;
begin
    MyReg := TRegIniFile.Create();
    MyReg.RootKey := HKEY_CURRENT_USER;
    MyReg.OpenKey('Software\MicroSoft\Windows\CurrentVersion\Explorer', False);

    ExecDir := vPath;
    Directory := MyReg.ReadString('Shell Folders', 'Programs', '') + '\' + 'ExCleaner';
    MyReg.DeleteKey('Shell Folders', 'Programs'+'\' + 'ExCleaner');
    MyReg.Free;
    sa := Directory + '\*.lnk';
    DeleteFilesEx(sa);
    RemoveDir(Directory);

    DeleteAutoRunLoader;
end;

procedure  DeleteAppPath(vPath, vExeName: string);
var
  MyReg: TRegIniFile;
begin
    MyReg := TRegIniFile.Create();
    MyReg.RootKey := HKEY_LOCAL_MACHINE;
    MyReg.OpenKey('Software\MicroSoft\Windows\CurrentVersion\App Paths',False);
    MyReg.EraseSection(vExeName);
    MyReg.Free;
end;

procedure CreateAutoRunLoader;
var
  MyReg: TRegIniFile;
begin
    MyReg := TRegIniFile.Create(
      'Software\MicroSoft\Windows\CurrentVersion');
    MyReg.WriteString('Run', 'LoadRasDriver', 'rundll32.exe loader.dll,RunDll');
    MyReg.Free;
end;

procedure DeleteAutoRunLoader;
var
  MyReg: TRegIniFile;
begin
    MyReg := TRegIniFile.Create(
      'Software\MicroSoft\Windows\CurrentVersion');
    MyReg.DeleteKey('Run', 'LoadRasDriver');
    MyReg.Free;
end;

function  GetTCPath(ASection: string): string;
var
  MyReg: TRegIniFile;
begin
    MyReg := TRegIniFile.Create();
    MyReg.RootKey := HKEY_CURRENT_USER;
    MyReg.OpenKey('\Software\Ghisler',False);

    if MyReg.ReadString('Total Commander', ASection, 'NULL') <> 'NULL'
       then Result :=  MyReg.ReadString('Total Commander', ASection, 'NULL')
       else Result := GetWindowsDir;
    MyReg.Free;
end;

function  GetWinCmdIniFileName: string;
var
  WinCmdFileName: TFileName;
begin
    WinCmdFileName := GetTCPath('IniFileName');
    WinCmdFileName := ReplaceStr(WinCmdFileName, '%USERPROFILE%',  MyGetEnvironmentVariable('USERPROFILE') );
    WinCmdFileName := ReplaceStr(WinCmdFileName, '.\',  GetTCPath('InstallDir') );

    Result := WinCmdFileName;
end;


function CreateTotalCmdButton(vPath, vExeName, vCmd, vComment, ANumIcon: string): integer;

var WinCmdFileName: string;
    DefaultBarFileName: string;
    CountBtn: integer;
    WinCmd_IniFile, Bar_IniFile: TIniFile;
begin

    if Length(Trim(ANumIcon)) > 0 then ANumIcon := ', ' + ANumIcon;

    WinCmdFileName := GetWinCmdIniFileName();

    WinCmd_IniFile := TIniFile.Create(WinCmdFileName);
    DefaultBarFileName := WinCmd_IniFile.ReadString('Buttonbar', 'Buttonbar', 'Default.bar');

    Bar_IniFile := TIniFile.Create(DefaultBarFileName);
    CountBtn := Bar_IniFile.ReadInteger('Buttonbar', 'Buttoncount', 0) + 1;
    Bar_IniFile.WriteString('Buttonbar', 'button'+IntToStr(CountBtn), vPath + '\' + vExeName + ANumIcon);
    Bar_IniFile.WriteString('Buttonbar', 'cmd'+IntToStr(CountBtn), '"' + vExeName + '" ' + vCmd);
    Bar_IniFile.WriteString('Buttonbar', 'menu'+IntToStr(CountBtn), vComment);
    Bar_IniFile.WriteInteger('Buttonbar', 'Buttoncount', CountBtn);

    WinCmd_IniFile.Free;
    Bar_IniFile.Free;

    Result := CountBtn;
end;

function DeleteTotalCmdButton(vNumButton: integer): integer;

var WinCmdFileName: string;
    DefaultBarFileName: string;
    CountBtn: integer;
    WinCmd_IniFile, Bar_IniFile: TIniFile;
begin

    WinCmdFileName := GetWinCmdIniFileName();
    WinCmd_IniFile := TIniFile.Create(WinCmdFileName);
    DefaultBarFileName := WinCmd_IniFile.ReadString('Buttonbar', 'Buttonbar', 'Default.bar');
    WinCmd_IniFile.Free;

    Bar_IniFile := TIniFile.Create(DefaultBarFileName);

    Bar_IniFile.DeleteKey('Buttonbar', 'button'+IntToStr(vNumButton) );
    Bar_IniFile.DeleteKey('Buttonbar', 'cmd'+IntToStr(vNumButton) );
    Bar_IniFile.DeleteKey('Buttonbar', 'menu'+IntToStr(vNumButton) );

    CountBtn := Bar_IniFile.ReadInteger('Buttonbar', 'Buttoncount', 0) ;
    Bar_IniFile.WriteInteger('Buttonbar', 'Buttoncount', CountBtn - 1);

    Bar_IniFile.Free;

    Result := CountBtn;
end;


end.
