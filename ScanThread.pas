unit ScanThread;

interface

uses
  Windows, SysUtils, Classes, ComCtrls, Forms, StdCtrls,
  PopupWindow, Graphics, ShellAPI, Controls, Registry;

type
  TRGB = record
   b, g, r:byte;
  end;
  ARGB = array [0..1] of TRGB;
  PARGB = ^ARGB;
  TChars = set of char;

  ScanFlash = class(TThread)
  private
   ResultWindow:TPopupWnd;
   detected, removed: integer;
   LastName, LastSize, LastDecr: string;
   VolumeChar: char;

   procedure AddToList;
   procedure PrepareVisualComponents;
   procedure UpdateVisualComponents;
   
   function IsExecutableFile(const FileName:string):boolean;
   function FormatDiskSize (const Value: TLargeInteger): string; overload;
   function FormatDiskSize (const FileName: string): string; overload;
   procedure ParseString(const Delimeter: TChars; StrToParse: string; List: TStrings);
   
   procedure RemoveAutorun;
   procedure FixRegistryMountPoints;
  protected
   procedure Execute; override;
  public
   constructor Create(CreateSuspended: boolean; pVolumeChar: char);
  end;

implementation

uses InformWnd;

{procedure ScanFlash.ScanDirectory(Path: string);
var
  SearchRec: TSearchRec;
begin
  if FindFirst(Path + '\*', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Name = '..') or (SearchRec.Name = '.') then
        continue;
      inc(detected);
      if (SearchRec.Attr and faDirectory) = faDirectory then
        ScanDirectory(Path + '\' + SearchRec.Name)
      else
        ;
      Synchronize(UpdateVisualComponents);
    until Self.Terminated or (FindNext(SearchRec) <> 0);
    FindClose(SearchRec);
  end;
end;}

procedure ScanFlash.Execute;
begin
  Synchronize(PrepareVisualComponents);
  RemoveAutorun;
  FixRegistryMountPoints;
  
  ResultWindow.ParentThread := nil;
  if (not ResultWindow.Active) and ResultWindow.AdditionalInfoLabel.Enabled then
   ResultWindow.CloseTimer.Enabled := true;
end;

procedure ScanFlash.UpdateVisualComponents;
begin
 with ResultWindow do
 begin
  DetectedLabel.Caption := IntToStr(detected);
  RemovedLabel.Caption := IntToStr(removed);
 end;
end;

constructor ScanFlash.Create(CreateSuspended: boolean; pVolumeChar: char);
begin
  VolumeChar := pVolumeChar;
  inherited Create(CreateSuspended);
end;

procedure ScanFlash.PrepareVisualComponents;
var
 VolumeName, FileSystemName: array [0..MAX_PATH-1] of Char;
 VolumeSerialNo, MaxComponentLength, FileSystemFlags: LongWord;
 TotalBytes, FreeBytes, TotalFree: TLargeInteger ;
begin
  ResultWindow := TPopupWnd.Create(nil);
  with ResultWindow, AdditionInfoForm do
  begin
    GetVolumeInformation(PChar(VolumeChar + ':\'),
                       VolumeName,
                       MAX_PATH,
                       @VolumeSerialNo,
                       MaxComponentLength,
                       FileSystemFlags,
                       FileSystemName,
                       MAX_PATH);
    if VolumeName = '' then
      VolumeName := 'Безымянный';

    LabelName.Caption := VolumeName + ' (' + VolumeChar + ':)';
    DetectedLabel.Caption := IntToStr(detected);
    RemovedLabel.Caption := IntToStr(removed);

    GetDiskFreeSpaceEx(PChar(VolumeChar + ':\'), FreeBytes, TotalBytes, @TotalFree);

    DriveNameLabel.Caption := VolumeName + ' (' + VolumeChar + ':)';
    DriveSizeLabel.Caption := FormatDiskSize(TotalBytes);
    FreeSizeLabel.Caption := FormatDiskSize(FreeBytes);
    UsedSizeLabel.Caption := FormatDiskSize(TotalBytes - FreeBytes);
    FileSystemLabel.Caption := FileSystemName;
    SerialNumberLabel.Caption := IntToHex(VolumeSerialNo,8);
 end;
 
 ResultWindow.ParentThread := Self;
 ResultWindow.Show;
 Application.BringToFront;
end;

function ScanFlash.IsExecutableFile(const FileName: string): boolean;
var
 ext:string;
begin
 result:=false;
 ext:=ExtractFileExt(FileName);
 ext:=LowerCase(ext);
 if (ext = '.exe') or (ext = '.com') or (ext = '.bat') or (ext = '.scr') or
    (ext = '.msc') or (ext = '.key') or (ext = '.dll') or (ext = '.vbs') or
    (ext = '.cmd') or (ext = '.vbe') or (ext = '.js' ) or (ext = '.jse') or
    (ext = '.wsf') or (ext = '.wsh') then
  result:=true;
end;

function ScanFlash.FormatDiskSize(const Value: TLargeInteger): string;
const
  SizeUnits: array[1..5] of string = (' Bytes', ' KBytes', ' MBytes', ' GBytes', 'TBytes');
var
  SizeUnit: Integer;
  Temp: TLargeInteger;
  Size: Integer;
begin
  SizeUnit := 1;
  if Value < 1024 then
    Result := IntToStr(Value)
  else begin
    Temp := Value;
    while (Temp >= 1000*1024) and (SizeUnit <= 5) do begin
      Temp := Temp shr 10;
      Inc(SizeUnit);
    end;
    Inc(SizeUnit);
    Size := (Temp shr 10);
    Temp := Temp - (Size shl 10);
    if Temp > 1000 then
      Temp := 999;
    if Size > 100 then
      Result := IntToStr(Size)
    else if Size > 10 then
      Result := Format('%d%s%.1d', [Size, DecimalSeparator, Temp div 100])
    else
      Result := Format('%d%s%.2d', [Size, DecimalSeparator,
        Temp div 10])
  end;
  Result := Result + SizeUnits[SizeUnit];
end;

procedure ScanFlash.AddToList;
begin
 with ResultWindow.AdditionInfoForm.ProcessingFileList.Items.Add do
 begin
  Caption := LastName;
  SubItems.Add(LastSize);
  SubItems.Add(LastDecr);
 end;
end;

procedure ScanFlash.RemoveAutorun;
var
 AutoRun: TStrings;
 TempString: string;
 i: integer;
begin
 if FileExists(VolumeChar + ':\autorun.inf') then
 begin
  AutoRun := TStringList.Create;
  AutoRun.LoadFromFile(VolumeChar + ':\autorun.inf');

  for i := AutoRun.Count - 1 downto 0 do
  begin
   TempString := Trim(AutoRun[i]);
   if ((TempString = '') or (TempString[1] = ';')) or (pos('=', TempString) = 0) then
    AutoRun.Delete(i)
   else
   begin
    Delete(TempString, 1, pos('=', AutoRun[i]));
    AutoRun[i] := Trim(TempString);
   end;
  end;

  AutoRun.Delimiter := ' ';
  AutoRun.QuoteChar := ' ';
  TempString := AutoRun.DelimitedText;

  AutoRun.Clear;
  AutoRun.Add('autorun.inf');
  ParseString([' ', ':', ','], TempString, AutoRun);

  {for i := AutoRun.Count - 1 downto 1 do
   if not  IsExecutableFile(AutoRun[i]) then
    AutoRun.Delete(i);}

  for i := 0 to AutoRun.Count - 1 do
  begin
    LastName := VolumeChar + ':\' + AutoRun[i];
    if not FileExists(LastName) then
      Continue;
    inc(detected);
    LastSize := FormatDiskSize(LastName);
    if SetFileAttributes(PChar(LastName), FILE_ATTRIBUTE_NORMAL) and DeleteFile(PChar(LastName)) then
    begin
      LastDecr := 'Файл успешно удален';
      inc(removed);
    end
    else
      LastDecr := 'Не удалось удалить файл';
    UpdateVisualComponents;
    Synchronize(AddToList);
  end;
 end;
end;

procedure ScanFlash.ParseString(const Delimeter: TChars;
  StrToParse: string; List: TStrings);
var
 PrevCharIsDelimeter: boolean;
 i: integer;
 CurrentItem: integer;
begin
 CurrentItem := List.Add('');

 while (StrToParse <> '') and (StrToParse[1] in Delimeter) do
  Delete(StrToParse, 1, 1);
 PrevCharIsDelimeter := false;
 
 for i := 1 to Length(StrToParse) do
 begin
  if not (StrToParse[i] in Delimeter) then
  begin
   List[CurrentItem] := List[CurrentItem] + StrToParse[i];
   PrevCharIsDelimeter := false;
  end
  else
  begin
   if not PrevCharIsDelimeter then
   begin
    CurrentItem := List.Add('');
    PrevCharIsDelimeter := true;
   end
   else
    continue;
  end;
 end;
 if List[CurrentItem] = '' then
  List.Delete(CurrentItem);
end;

function ScanFlash.FormatDiskSize(const FileName: string): string;
var
 SearchRec: TSearchRec;
 Size: TLargeInteger;
begin
 if FindFirst(FileName, faAnyFile, SearchRec) = 0 then
 begin
  Size := SearchRec.Size;
  FindClose(SearchRec);
 end
 else
  Size := 0;
 Result := FormatDiskSize(Size);
end;

procedure ScanFlash.FixRegistryMountPoints;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  Reg.DeleteKey('Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2');
  Reg.Free;
end;

end.
