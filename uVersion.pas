unit uVersion;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
   TVersionInfo = record
    Major, Minor,
      Release, Build: integer;
    FileVersion,
      FileDescription,
      CompanyName,
      LegalCopyright: string;
    FileDate: TDateTime;
    SoftID: string;
  end;

   //Прочитать версию в строку ( 0: Х.Х, 1: Х.Х.Х.Х )
   //
   function GetVersionStr(n: byte): string;

   //Прочитать часть версии из файла
   //
   function GetVersionInfo(fn: string): TVersionInfo;

var
  VersionInfo :TVersionInfo;

implementation

function GetVersionStr(n: byte): string;
var sVersion: string;
begin
  sVersion := IntToStr(GetVersionInfo(Application.ExeName).Major);
  sVersion := sVersion + '.' + IntToStr(GetVersionInfo(Application.ExeName).Minor);
  if n>0 then
    begin
     sVersion := sVersion + '.' + IntToStr(GetVersionInfo(Application.ExeName).Release);
     sVersion := sVersion + '.' + IntToStr(GetVersionInfo(Application.ExeName).Build);
    end;
  Result := sVersion;
end;

function GetVersionInfo(fn: string): TVersionInfo;
var
  dump: DWORD;
  sz: integer;
  Buf, tBuf: PChar;
  tmp: integer;
  CalcLangCharSet: string;

  procedure GetVerValue(SVal: string; var Val: string);
  begin
    VerQueryValue(Buf, PChar(SVal), pointer(tBuf), dump);
    if dump > 1 then
    begin
      SetLength(Val, dump - 1);
      StrLCopy(PChar(Val), tBuf, dump - 1);
    end
    else
      Val := '';
  end;

  procedure ExtractFileVersionNumber(var aVI: TVersionInfo);
  var
    l, i, c, r: integer;
  begin
    l := Length(aVI.FileVersion);
    i := 1;
    c := 0;
    r := 0;
    while i <= l do
    begin
      if aVI.FileVersion[i] = '.' then
      begin
        case c of
          0: aVI.Major := r;
          1: aVI.Minor := r;
          2: aVI.Release := r;
        else
          raise Exception.Create('Неверный формат версии файла');
        end;
        c := c + 1;
        r := 0;
      end
      else
        r := 10 * r + ord(aVI.FileVersion[i]) - ord('0');
      if i = l then aVI.Build := r;
      i := i + 1;
    end;
  end;

begin
  if fn = '' then fn := Application.ExeName;
  sz := GetFileVersionInfoSize(PChar(fn), dump);
  Buf := StrAlloc(sz + 1);
  try
    GetFileVersionInfo(PChar(fn), 0, sz, Buf);
    VerQueryValue(Buf, '\VarFileInfo\Translation', pointer(tBuf), dump);
    if dump >= 4 then
    begin
      tmp := 0;
      StrLCopy(@tmp, tBuf, 2);
      CalcLangCharSet := IntToHex(tmp, 4);
      StrLCopy(@tmp, tBuf + 2, 2);
      CalcLangCharSet := CalcLangCharSet + IntToHex(tmp, 4);
    end;
    GetVerValue('\StringFileInfo\' + CalcLangCharSet + '\' + 'FileVersion', Result.FileVersion);
    ExtractFileVersionNumber(Result);
    Result.FileDate := FileDateToDateTime(FileAge(fn));
    GetVerValue('\StringFileInfo\' + CalcLangCharSet + '\' + 'FileDescription', Result.FileDescription);
    GetVerValue('\StringFileInfo\' + CalcLangCharSet + '\' + 'CompanyName', Result.CompanyName);
    GetVerValue('\StringFileInfo\' + CalcLangCharSet + '\' + 'LegalCopyright', Result.LegalCopyright);
    GetVerValue('\StringFileInfo\' + CalcLangCharSet + '\' + 'AlexisSoftID', Result.SoftID);
  finally
    StrDispose(Buf);
  end;
end;

end.
