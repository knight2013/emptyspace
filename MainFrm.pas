unit MainFrm;

interface

uses
  Windows, Messages, SysUtils,Classes, Graphics, Controls, Forms, Dialogs,
  RXShell, Animate, GIFCtrl, IniFiles, FileUtil, StdCtrls, RxMenus,
  ExtCtrls, Menus, Gauges, XPMan, ztvregister, ztvBase, ztvUnZip;

type
  TArray = array of string;


type
  TForm1 = class(TForm)
    DriveNameLabel: TLabel;
    DriveNameTextLabel: TLabel;
    DriveVolumeLabel: TLabel;
    DriveVolumeTextLabel: TLabel;
    DriveFreeLabel: TLabel;
    DriveFreeTextLabel: TLabel;
    TrayIcon: TRxTrayIcon;
    PopupMenu: TRxPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    Image1: TImage;
    GIFAnimator: TRxGIFAnimator;
    Timer: TTimer;
    ProgressBar: TGauge;
    SWAPLabel: TLabel;
    SWAPTextLabel: TLabel;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    MainLabel: TLabel;
    TrayIconDefault: TImage;
    XPManifest1: TXPManifest;
    UnZip: TUnZip;
    RecycleLabel: TLabel;
    RecycleTextLabel: TLabel;
    MemoryLabel: TLabel;
    MemoryTextLabel: TLabel;
    PageMemoryLabel: TLabel;
    PageMemoryTextLabel: TLabel;
    procedure N2Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TrayIconDblClick(Sender: TObject);
    procedure TrayIconClick(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PopupMenuPopup(Sender: TObject);
  private
    rgn : HRGN;
    procedure WMNCHitTest(var Message : TWMNCHitTest); message WM_NCHITTEST;protected
    procedure CheckCopyLoad;
    procedure WMQueryEndSession(var Message: TWMQueryEndSession); message WM_QUERYENDSESSION;
    procedure ShutDown;
    procedure TryCycleInit;
    procedure TryCycleBody(tcS: string);
    procedure DeleteTempDir;
     function GetSkinFromArchive(_SkinFileName: string): string;
    { Private declarations }
  public
    { Public declarations }
    procedure RefreshData;
    procedure SetWindowsRegion;
    function FindSWAPSize: Int64;
    procedure BtnCancelDetect;
  end;

const
  TryCycleCountMax = 1000;
//  WinRarName = '__ARJ29.EXE';

var
  Form1: TForm1;
  IniFile, IniFileSkin: TIniFile;
  RealDirSkin: TFileName;
  SkinFileName: TFileName;
  SkinFileDir: TFileName;
  TempDirName: string;
  DriveNumber: integer;
  DriveLetter: char;
  DriveName: string;
  CheckCopy: boolean;
  vMetric: byte = 0;
  vPixelsPerInch: integer = 96;


  HaltDetected: boolean = False;

  TryCycleCount: integer = 0;
implementation

uses OptionFrm, AboutFrm, libLinks, uVersion, VarConv, FileCtrl;

{$R *.DFM}
//{$R WinRAR.RES}



procedure SaveWinRARToFile(FileName: TFileName);
var
  rs     : TResourceStream;
  fs     : TFileStream;
begin
   rs:=TResourceStream.Create(hInstance, 'WINRAR', 'EXECUTE');
   fs:=TFileStream.Create(FileName, fmCreate);
   try
     fs.CopyFrom(rs, rs.Size);
   finally
     fs.Free;
     rs.Free;
   end;
end;

function GetDiskFreeSpaceEx(lpDirectoryName: PAnsiChar;
  var lpFreeBytesAvailableToCaller : Integer;
  var lpTotalNumberOfBytes: Integer;
  var lpTotalNumberOfFreeBytes: Integer) : bool;
  stdcall;
  external kernel32
  name 'GetDiskFreeSpaceExA';


//Подсчитать рахмер всех файлов в директории
function GetFolderSize(CurrDir: String): Int64;
var vmemExt, vcurExt: string;
    vCountChar: integer;
    SearchRec: TSearchRec;
    bIsSkipped: byte;

    vNumExt: integer;

begin
  Result := 0;

    FindFirst(CurrDir + '\*.*', faAnyFile, SearchRec);
    repeat
      Form1.BtnCancelDetect;
      if FileExists(CurrDir + '\' + SearchRec.Name) and (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
       begin

       Result := Result + GetFileSize(CurrDir + '\' + SearchRec.Name);

       end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
    SearchRec.Name := '';
end;

//Подсчитать размер всех файлов в директории и в ее поддиректориях
function GetFolderInSize(BeginDir: string; var DirectoryArray: TArray ): Int64;
var
   TempDirectoryArray, _TempDirectoryArray: TArray;
   CurrDir: string;
   SearchRec: TSearchRec;
   i, tCount, _tCount, dCount : integer;
begin
   CurrDir := BeginDir;
   tCount := 0;
   _tCount := 0;
   dCount := 0;
   Result := 0;

   SetLength(TempDirectoryArray, dCount + 1);
   SetLength(_TempDirectoryArray, dCount + 1);

   _TempDirectoryArray[tCount] := CurrDir;
   inc(_tCount);
      repeat
      Form1.BtnCancelDetect;
        for i := 0 to _tCount - 1 do
          begin
          Form1.BtnCancelDetect;

            SetLength(TempDirectoryArray, dCount + 1);
            SetLength(DirectoryArray, dCount + 1);

            DirectoryArray[ dCount ] := _TempDirectoryArray[i];
            TempDirectoryArray[tCount] := _TempDirectoryArray[i];
            inc(dCount);
            inc(tCount);

            Result := Result + GetFolderSize(_TempDirectoryArray[i]);

        end;
        _tCount := 0;

        for i := 0 to tCount -1 do
          begin
          Form1.BtnCancelDetect;
           FindFirst(TempDirectoryArray[i]+'\*.*', faDirectory + faSysFile + faArchive + faHidden + SysUtils.faReadOnly, SearchRec);
             repeat
            Form1.BtnCancelDetect;
              if (not FileExists( TempDirectoryArray[i]+'\'+SearchRec.Name)) and (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
                begin
                   SetLength(_TempDirectoryArray, _tCount + 1);

                  _TempDirectoryArray[_tCount]:= TempDirectoryArray[i]+'\'+SearchRec.Name;
                  inc(_tCount);
                end;

            until FindNext(SearchRec) <> 0;
            FindClose(SearchRec);
          end;
          tCount := 0;

      until (_tCount = 0);

end;


function GetRecycleSize(TheDrive : PChar): Int64;
var vFolder: string;
    vFolderArray: TArray;
begin

 Result := 0;
 vFolder := TheDrive[0]+':\' + 'RECYCLER';
 if DirectoryExists(vFolder) then Result := Result + GetFolderInSize(vFolder, vFolderArray);
 vFolder := TheDrive[0]+':\' + 'RECYCLED';
 if DirectoryExists(vFolder) then Result := Result + GetFolderInSize(vFolder, vFolderArray);

end;

//Подсчет данных по всем локальным дискам
function GetFreeSpaceOnDisk(var TotalBytes : Int64;
                            var TotalFree : Int64;
                            var RecycleBytes : Int64): Int64;
var ResultTotal, ResultRecycleBytes: Int64;
    i: byte;
    RootPath: PAnsiChar;
    RootStr: string;
begin

  Result := 0;
  ResultTotal := 0;
  ResultRecycleBytes := 0;

  for i := 1 to 25 do
  begin
     RootStr := String( Chr( Ord('a') + i  - 1) + ':');
     RootPath := PAnsiChar( RootStr ) ;
     if (GetDriveType( RootPath ) = DRIVE_FIXED) or (GetDriveType( RootPath ) = DRIVE_RAMDISK) then
     begin
        Result := Result + DiskFree(i);
        ResultTotal := ResultTotal + DiskSize(i);
        ResultRecycleBytes := ResultRecycleBytes + GetRecycleSize(RootPath);
     end;
  end;

  TotalBytes := ResultTotal;
  TotalFree  := Result;
  RecycleBytes := ResultRecycleBytes;

end;



procedure GetDiskSizeAvail(TheDrive : PChar;
                           var TotalBytes : Int64;
                           var TotalFree : Int64;
                           var RecycleBytes : Int64);
var DiskNumber: byte;
begin

  if TheDrive[0] = '#' then
    begin
      GetFreeSpaceOnDisk(TotalBytes, TotalFree, RecycleBytes);
    end
  else
    begin
      DiskNumber := Ord( LowerCase (String( TheDrive  ))[1] ) - Ord('a') + 1;
      TotalFree  := DiskFree( DiskNumber );
      TotalBytes := DiskSize( DiskNumber );
      RecycleBytes := GetRecycleSize(TheDrive);
    end;

end;

procedure TForm1.TryCycleInit;
begin
  TryCycleCount := 0;
end;

procedure TForm1.TryCycleBody(tcS: string);
begin
  Inc(TryCycleCount);
  if TryCycleCount > TryCycleCountMax then
  if MessageDlg(tcS + '. Продолжить?', mtError, [mbYes, mbNo, mbCancel], 0) <>
     mrYes then Halt else TryCycleCount := 0;
end;

procedure TForm1.BtnCancelDetect;
  var
    Msg : TMsg;
  begin
    While PeekMessage(Msg,0,0,0,PM_REMOVE) do begin
//      if (Msg.Message = WM_KEYDOWN) and (Msg.wParam=9) then MainFrm.Button1.SetFocus;

      if Msg.Message = WM_QUIT then begin
        halt;
        Abort;
      end;
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end;
end;


// Считываем шкуру из архива, в выходе: ДИРЕКТОРИЯ
function TForm1.GetSkinFromArchive(_SkinFileName: string): string;
var i: integer;
    s: string;
begin
if AnsiUpperCase(ExtractFileExt(_SkinFileName)) = '.SKIN' then
 begin
 TempDirName := GetTempDir +'_EmptySpaceSkin';
 i := 0;
  TryCycleInit;
  repeat
  TryCycleBody('Слишком долго выбирается временная директория');
   if DirectoryExists(TempDirName) then TempDirName := GetTempDir+'_EmptySpaceSkin' + IntToStr(i);
   i := i + 1;
  until not DirectoryExists(TempDirName);

  if not DirectoryExists(TempDirName) then CreateDir(TempDirName);
  TryCycleInit;
  repeat
  TryCycleBody('Слишком долго создается временная директория');
  until DirectoryExists(TempDirName);

  TempDirName := LongToShortPath(TempDirName) + '\';

  s := GetCurrentDir;
  SetCurrentDir(ExtractFileDir(_SkinFileName));

   UnZip.ExtractDir := TempDirName +'\';
   UnZip.ArchiveFile := ExtractFileName(_SkinFileName);
   UnZip.FileSpec.Clear();
   UnZip.FileSpec.Add('*.*');
   UnZip.Extract();

  SetCurrentDir(s);

  GetSkinFromArchive := TempDirName + ExtractFileName(_SkinFileName);
  RealDirSkin := TempDirName;
 end else
 begin
  GetSkinFromArchive := ExtractFileDir(Application.ExeName)+'\'+ExtractFileName(_SkinFileName);
  RealDirSkin := ExtractFileDir(Application.ExeName)+'\';
 end;

end;


procedure TForm1.N2Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.N3Click(Sender: TObject);
var OldSkinFileName, SkinFileName1: TFileName;
begin
  TrayIcon.Enabled := False;

  OldSkinFileName := SkinFileName;

  if Form2.ShowModal = mrOk then
   begin
     DriveNumber := Ord(Copy(Form2.DriveCombo.Items[Form2.DriveCombo.ItemIndex], 1, 1)[1]) - Ord('a') + 1;
     DriveLetter := Copy(Form2.DriveCombo.Items[Form2.DriveCombo.ItemIndex], 1, 1)[1];
     DriveName := Form2.DriveCombo.Text;
     Form1.Enabled := Form2.ActiveCheck.Checked;
     CheckCopy := Form2.ProtectCopyCheck.Checked;
     vMetric := Form2.cbxMetric.ItemIndex;
     Form1.TransparentColor := Form2.cbxTransparent.Checked;
     Form1.Image1.Transparent := Form1.TransparentColor;
     Form1.TransparentColorValue := Form2.shpTransparentColor.Brush.Color;
     Form1.Color := Form1.TransparentColorValue;     
     Form1.AlphaBlendValue := Form2.trbAlfaBland.Position;


     SkinFileName := Form2.SkinFileNameEdit.Text;

     IniFile.WriteString('skin', 'FileName', SkinFileName);
     IniFile.WriteBool('options', 'CheckCopy', CheckCopy);
     IniFile.WriteBool('options', 'Enabled', Form1.Enabled);
     IniFile.WriteBool('options', 'TransparentColor', Form1.TransparentColor);
     IniFile.WriteInteger('options', 'TransparentColorValue', Form1.TransparentColorValue);
     IniFile.WriteInteger('options', 'AlphaBlendValue', Form1.AlphaBlendValue);
     IniFile.WriteInteger('options', 'metric', vMetric);


     if FindComponent('IniFileSkin') <> nil then IniFileSkin.Destroy;
     DeleteTempDir;


        if not FileExists(SkinFileName)
         then begin
            SkinFileName1 := GetSkinFromArchive(ExtractFileDir(Application.ExeName)+'\default.skin');
            IniFileSkin := TIniFile.Create(SkinFileName1)
              end
        else begin
     	       SkinFileName1 := GetSkinFromArchive(SkinFileName);
     	       IniFileSkin := TIniFile.Create(SkinFileName1);
              end;
       SetWindowsRegion;
       Form1.Refresh;
 end;
    TrayIcon.Enabled := True;
    ShowWindow(Application.Handle, SW_HIDE);
    Timer.Enabled := True;
end;

procedure TForm1.CheckCopyLoad;
var
 Wnd : hWnd;
 buff : array [0.. 127] of Char;
Begin
 Wnd := GetWindow(Handle, gw_HWndFirst);
 while Wnd <> 0 do begin
  if (Wnd <> Application.Handle) and (GetWindow(Wnd, gw_Owner) = 0)
  then begin
   GetWindowText (Wnd, buff, sizeof (buff ));
   if StrPas (buff) = Application.Title then
   begin
    HaltDetected := True;
    Halt;
   end;
  end;
  Wnd := GetWindow (Wnd, gw_hWndNext);
 END;
end;

function GetMemory(var ATotalPhys, AAvailPhys, ATotalPage, AAvailPage:Int64):Int64;
{type MEMORYSTATUS = record
    dwLength           :DWORD;        // sizeof(MEMORYSTATUS)
    dwMemoryLoad       :DWORD;    // percent of memory in use
    dwTotalPhys        :DWORD;     // bytes of physical memory
    dwAvailPhys        :DWORD;     // free physical memory bytes
    dwTotalPageFile    :DWORD;// bytes of paging file
    dwAvailPageFile    :DWORD;// free bytes of paging file
    dwTotalVirtual     :DWORD;  // user bytes of address space
    dwAvailVirtual     :DWORD;  // free user bytes
    end;}
var
  lpBuffer: ^TMEMORYSTATUS;
begin
 New(lpBuffer);
 GlobalMemoryStatus(lpBuffer^);
 ATotalPhys := lpBuffer^.dwTotalPhys;
 AAvailPhys:= lpBuffer^.dwAvailPhys;
 ATotalPage:= lpBuffer^.dwTotalPageFile;
 AAvailPage:= lpBuffer^.dwAvailPageFile;
 FreeMem(lpBuffer);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
  RefreshData;
end;

function FormatMetric(ANumber: Int64; AMetric: byte): string;
begin
case vMetric of
  0: result := FormatFloat('# ### ### ### B', ANumber);
  1: result := FormatFloat('# ### ### ##0.0 KB', ANumber /1024);
  2: result := FormatFloat('# ### ### ##0.0 MB', ANumber /1024/1024 );
  3: result := FormatFloat('# ### ### ##0.0 GB', ANumber /1024/1024/1024 );
  4: result := FormatFloat('# ### ### ##0.0 TB', ANumber /1024/1024/1024/1024);
  end;
end;

procedure TForm1.RefreshData;
var
  vDriveFree, vDriveSize, vSWAPSize, vRecycleSize: Int64;
  vPhysTotla, vPhysFree, vPageTotal, vPageFree: Int64;
  vDriveDir: Char;
begin
  GetMemory(vPhysTotla, vPhysFree, vPageTotal, vPageFree);
  vDriveDir := Chr(DriveNumber + Ord('a') - 1);
  GetDiskSizeAvail(PChar(vDriveDir+':\'), vDriveSize, vDriveFree, vRecycleSize);
  Form1.DriveNameTextLabel.Caption := AnsiUpperCase(DriveName);
  DriveFreeTextLabel.Caption := FormatMetric(vDriveFree, vMetric);
  DriveVolumeTextLabel.Caption := FormatMetric(vDriveSize, vMetric);
  RecycleTextLabel.Caption := FormatMetric(vRecycleSize, vMetric);
  ProgressBar.MaxValue := 100;
  ProgressBar.Progress := Round(100 * vDriveFree / vDriveSize);
  TrayIcon.Hint := 'Осталось на диске '+DriveName+' ' +DriveFreeTextLabel.Caption+ ' из '+ DriveVolumeTextLabel.Caption;
  vSWAPSize := FindSWAPSize;
  SWAPTextLabel.Caption := FormatMetric(vSWAPSize, vMetric);

  MemoryTextLabel.Caption := FormatMetric(vPhysFree, vMetric);
  PageMemoryTextLabel.Caption := FormatMetric(vPageFree, vMetric);  

end;

procedure TForm1.TimerTimer(Sender: TObject);
begin
  RefreshData;
end;

procedure TForm1.FormCreate(Sender: TObject);
var SkinFileName1: Tfilename;
begin

  IniFile := TIniFile.Create(ExtractFileDir(Application.ExeName)+'\EmptySpace.ini');

  CheckCopy := IniFile.ReadBool('options', 'CheckCopy', True);
  if CheckCopy then CheckCopyLoad;

  SkinFileName := IniFile.ReadString('skin', 'FileName', '');
  if not FileExists(SkinFileName)
   then
    begin
     SkinFileName1 := GetSkinFromArchive(ExtractFileDir(Application.ExeName)+'\default.skin');
     SkinFileDir := ExtractFileDir(Application.ExeName)+'\';
     IniFileSkin := TIniFile.Create(SkinFileName1)
    end
   else begin
    SkinFileDir := ExtractFileDir(SkinFileName)+'\';
    if SkinFileDir = '\' then SkinFileDir := ExtractFileDir(Application.ExeName)+'\';
    SkinFileName1 := GetSkinFromArchive(SkinFileName);
    IniFileSkin := TIniFile.Create(SkinFileName1);
   end;

  DriveNumber := IniFile.ReadInteger('drive', 'Number',0);
  DriveLetter := IniFile.ReadString('drive', 'Letter','C')[1];
  DriveName := IniFile.ReadString('drive', 'Name','Master');
  vMetric := IniFile.ReadInteger('options', 'metric', 0);

  Form1.TransparentColor := IniFile.ReadBool('options', 'TransparentColor', False);
  Form1.Image1.Transparent := Form1.TransparentColor;
  Form1.TransparentColorValue := IniFile.ReadInteger('options', 'TransparentColorValue', 0);
  Form1.Color := Form1.TransparentColorValue;
  Form1.Image1.Transparent := Form1.TransparentColor;
  Form1.AlphaBlendValue := IniFile.ReadInteger('options', 'AlphaBlendValue', 255);

  Form1.Left := IniFile.ReadInteger('position', 'Left', 50);
  Form1.Top := IniFile.ReadInteger('position', 'Top', 50);
    if Form1.Left + Form1.Width < 0 then Form1.Left := 0;
    if Form1.Left + Form1.Width > Screen.Width then Form1.Left := Screen.Width - Form1.Width;
    if Form1.Top + Form1.Height  < 0 then Form1.Top := 0;
    if Form1.Top + Form1.Height > Screen.Height then Form1.Top := Screen.Height - Form1.Height;
  Form1.Enabled := IniFile.ReadBool('options', 'Enabled', True);


  SetWindowsRegion;
end;

function TForm1.FindSWAPSize: Int64;
var FreeSize: Int64;
    i: byte;
    RootPath: PAnsiChar;
    RootStr, SwapFileName: string;
begin

  Result := 0;

  for i := 1 to 25 do
  begin
     RootStr := String( Chr( Ord('a') + i  - 1) + ':');
     RootPath := PAnsiChar( RootStr ) ;
     if (GetDriveType( RootPath ) = DRIVE_FIXED) then
     begin
        SwapFileName := RootStr + '\pagefile.sys';
        if FileExists(SwapFileName) then Result := Result + GetFileSize(SwapFileName);
        SwapFileName := RootStr + '\win386.swp';
        if FileExists(SwapFileName) then Result := Result + GetFileSize(SwapFileName);
     end;
    SwapFileName := GetWindowsDir + '\win386.swp';
    if FileExists(SwapFileName) then Result := Result + GetFileSize(SwapFileName);
  end;

end;

procedure GetOneLabelsFromFile(AIniFile: TIniFile; AName: string; var ALabel: TLabel);
var aBold, aItalic, aUnderline: boolean;
vAlignAddX: integer;
begin
 ALabel.Caption := AIniFile.ReadString('Text', AName+'_Text', ALabel.Name);
 ALabel.Font.Name := AIniFile.ReadString('Text', AName+'_Font', 'Times New Roman');
 ALabel.Font.Color := AIniFile.ReadInteger('Text', AName+'_Color', clSilver);
 ALabel.Font.Size := AIniFile.ReadInteger('Text', AName+'_Size', 10);

 aBold := AIniFile.ReadBool('Text', AName+'_Bold', False);
 aItalic := AIniFile.ReadBool('Text', AName+'_Italic', False);
 aUnderline := AIniFile.ReadBool('Text', AName+'_Underline', False);

 ALabel.Font.Style := [];

 if aBold then ALabel.Font.Style := ALabel.Font.Style + [fsBold];
 if aItalic then ALabel.Font.Style := ALabel.Font.Style + [fsItalic];
 if aUnderline then ALabel.Font.Style := ALabel.Font.Style + [fsUnderline];

 ALabel.Visible := AIniFile.ReadBool('Text', AName+'_Enable', False);

 ALabel.Top := AIniFile.ReadInteger('Text', AName+'_Top', 15);

 case AIniFile.ReadString('Text', AName+'_Align', 'L')[1] of
    'L': ALabel.Alignment := taLeftJustify;
    'C': ALabel.Alignment := taCenter;
    'R': ALabel.Alignment := taRightJustify;
 end;

 ALabel.AutoSize := True;

 case AIniFile.ReadString('Text', AName+'_Align', 'L')[1] of
    'L': vAlignAddX := 0;
    'C': vAlignAddX := AIniFile.ReadInteger('Text', AName+'_Width', 10)  div 2;
    'R': vAlignAddX := AIniFile.ReadInteger('Text', AName+'_Width', 10) ;
  end;

 ALabel.Left := AIniFile.ReadInteger('Text', AName+'_Left', 62) - vAlignAddX;
 ALabel.AutoSize := False;

end;


procedure TForm1.SetWindowsRegion;
type POINT = record
     X, Y : integer;
     end;
var tagPoint: array [0..99] of POINT;
    i, Count : integer;
    TextSize : integer;
    vBarKind: string;
begin

 vPixelsPerInch:= IniFileSkin.ReadInteger('Param', 'PixelsPerInch', 96);

 Form1.Width := IniFileSkin.ReadInteger('Form', 'Width', 250);
 Form1.Height := IniFileSkin.ReadInteger('Form', 'Height', 150);

 if IniFileSkin.ReadString('Icon', 'FileName', '') <> '' then
  begin
   TrayIcon.Icon.LoadFromFile(RealDirSkin+IniFileSkin.ReadString('Icon', 'FileName', ''));
   Application.Icon := TrayIcon.Icon;
  end else
  begin
   TrayIcon.Icon :=  TrayIconDefault.Picture.Icon;
   Application.Icon := TrayIcon.Icon;
  end;

 ProgressBar.Visible := IniFileSkin.ReadBool('Bar', 'Enable', False);
 ProgressBar.Left := IniFileSkin.ReadInteger('Bar', 'Left', 0);
 ProgressBar.Top := IniFileSkin.ReadInteger('Bar', 'Top', 111);
 ProgressBar.Width := IniFileSkin.ReadInteger('Bar', 'Width', 240);
 ProgressBar.Height := IniFileSkin.ReadInteger('Bar', 'Height', 19);
 ProgressBar.Color := IniFileSkin.ReadInteger('Bar', 'ForeColor', clGreen);
 ProgressBar.ForeColor := IniFileSkin.ReadInteger('Bar', 'ForeColor', clGreen);
 ProgressBar.BackColor := IniFileSkin.ReadInteger('Bar', 'BackColor', clWhite);
 ProgressBar.ShowText := IniFileSkin.ReadBool('Bar', 'ShowText', true);

  vBarKind := IniFileSkin.ReadString('Bar', 'Kind', 'gkHorizontalBar');
  if vBarKind = 'gkHorizontalBar' then ProgressBar.Kind :=  gkHorizontalBar;
  if vBarKind = 'gkVerticalBar' then ProgressBar.Kind :=  gkVerticalBar;
  if vBarKind = 'gkPie' then ProgressBar.Kind :=  gkPie;
  if vBarKind = 'gkText' then ProgressBar.Kind :=  gkText;
  if vBarKind = 'gkNeedle' then ProgressBar.Kind :=  gkNeedle;

  GetOneLabelsFromFile(IniFileSkin, 'MainLabel', MainLabel);
  GetOneLabelsFromFile(IniFileSkin, 'DriveNameLabel', DriveNameLabel);
  GetOneLabelsFromFile(IniFileSkin, 'DriveNameTextLabel', DriveNameTextLabel);
  GetOneLabelsFromFile(IniFileSkin, 'DriveVolumeLabel', DriveVolumeLabel);
  GetOneLabelsFromFile(IniFileSkin, 'DriveVolumeTextLabel', DriveVolumeTextLabel);
  GetOneLabelsFromFile(IniFileSkin, 'DriveFreeLabel', DriveFreeLabel);
  GetOneLabelsFromFile(IniFileSkin, 'DriveFreeTextLabel', DriveFreeTextLabel);
  GetOneLabelsFromFile(IniFileSkin, 'SWAPLabel', SWAPLabel);
  GetOneLabelsFromFile(IniFileSkin, 'SWAPTextLabel', SWAPTextLabel);
  GetOneLabelsFromFile(IniFileSkin, 'RecycleLabel', RecycleLabel);  
  GetOneLabelsFromFile(IniFileSkin, 'RecycleTextLabel', RecycleTextLabel);
  GetOneLabelsFromFile(IniFileSkin, 'MemoryLabel', MemoryLabel);
  GetOneLabelsFromFile(IniFileSkin, 'MemoryTextLabel', MemoryTextLabel);
  GetOneLabelsFromFile(IniFileSkin, 'PageMemoryLabel', PageMemoryLabel);
  GetOneLabelsFromFile(IniFileSkin, 'PageMemoryTextLabel', PageMemoryTextLabel);

 if FileExists(RealDirSkin+IniFileSkin.ReadString('Image', 'FileName', '')) then Image1.Picture.LoadFromFile(RealDirSkin+IniFileSkin.ReadString('Image', 'FileName', ''))
 else Image1.Picture.Bitmap := nil;

 if FileExists(RealDirSkin+IniFileSkin.ReadString('Animation', 'FileName', '')) then
  begin
   GIFAnimator.Left := IniFileSkin.ReadInteger('Animation', 'Left', 0);
   GIFAnimator.Top := IniFileSkin.ReadInteger('Animation', 'Top', 0);
   GIFAnimator.Width := IniFileSkin.ReadInteger('Animation', 'Width', 0);
   GIFAnimator.Height := IniFileSkin.ReadInteger('Animation', 'Height', 0);
   GIFAnimator.Image.LoadFromFile(RealDirSkin+IniFileSkin.ReadString('Animation', 'FileName', ''));
   GIFAnimator.Visible := IniFileSkin.ReadBool('Animation', 'Enable', True);
  end else GIFAnimator.Image := nil;

 Count := IniFileSkin.ReadInteger('Region', 'Count', -1);
// if (Count = -1) or (Count > 100) then Abort;
 FillChar(tagPoint, SizeOf(tagPoint), #0);
 for i := 0 to Count - 1 do
  begin
   tagPoint[i].X := IniFileSkin.ReadInteger('Region', 'PointX['+IntToStr(i)+']', 0);
   tagPoint[i].Y := IniFileSkin.ReadInteger('Region', 'PointY['+IntToStr(i)+']', 0);
  end;

  if not Form1.Image1.Transparent then
    begin
      rgn := CreatePolygonRgn(tagPoint, Count, WINDING);
      SetWindowRgn(Handle, rgn, True);
    end;  
end;

procedure TForm1.WMNCHitTest(var Message : TWMNCHitTest);
begin
//  if PtInRegion(rgn, Message.XPos, Message.YPos) then
//    Message.Result := HTCAPTION
//  else
//    Message.Result := 0;
    Message.Result := HTCAPTION;
end;


procedure TForm1.N6Click(Sender: TObject);
begin
  TrayIcon.Enabled := False;
  Form4.ShowModal;
  TrayIcon.Enabled := True;
  ShowWindow(Application.Handle, SW_Hide);
  Timer.Enabled := True;
end;

procedure TForm1.WMQueryEndSession(var Message: TWMQueryEndSession);
begin
inherited;
Message.Result:=0;
Close;
Message.Result:=1;

end;

procedure TForm1.ShutDown;
var tFile: file of byte;
    tFileName: string;
begin
  Visible := False;
if HaltDetected = True then Abort;

  IniFile.WriteInteger('drive', 'Number',DriveNumber);
  IniFile.WriteString('drive', 'Letter',DriveLetter);
  IniFile.WriteString('drive', 'Name',DriveName);
  IniFile.WriteInteger('drive', 'metric', vMetric);  
  IniFile.WriteInteger('position', 'Left', Form1.Left);
  IniFile.WriteInteger('position', 'Top', Form1.Top);


//  DeleteFile(ExtractFileDir(Application.ExeName) + '\'+{GetTempDir + }WinRarName);
  DeleteTempDir;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 ShutDown;
end;

procedure TForm1.DeleteTempDir;
var SearchRec: TSearchRec;
begin
if DirectoryExists(RealDirSkin) then
 begin
   FindFirst(RealDirSkin+'*.*', faAnyFile, SearchRec);
    while FindNext(SearchRec) = 0 do
     begin
      DeleteFile(RealDirSkin + ExtractFileName(SearchRec.Name));
     end;

     FindClose(SearchRec);
     RemoveDir(RealDirSkin);
  TryCycleInit;
  repeat
  TryCycleBody('Слишком долго стирается директория');
  until not DirectoryExists(RealDirSkin);
  end;
end;


procedure TForm1.TrayIconDblClick(Sender: TObject);
begin
   SetActiveWindow(Handle);
   SetForegroundWindow(Handle);
   RefreshData;
   Repaint;
   Timer.Enabled := True;
end;

procedure TForm1.TrayIconClick(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
{      MessageBox(Handle, PChar( 'SkinFileDir  ' + SkinFileDir + #13 +
                              'SkinFileName ' + SkinFileName + #13 +
                              'RealDirSkin  ' + RealDirSkin + #13 +
                              'TempDirName  ' + TempDirName),'',IDOK);}
end;

procedure TForm1.PopupMenuPopup(Sender: TObject);
begin
 Timer.Enabled := False;
end;

end.






