unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, TrayIcon, Menus, ImgList, ComCtrls, PopupWindow, ScanParametersUnit, ProcessListForm, uDriveEjector,
  PngImageList, CoolTrayIcon, uDiskEjectConst, RemLock, BlockedFileListFormUnit;

type
  TMainForm = class(TForm)
    PopupMenu1: TPopupMenu;
    Exit1: TMenuItem;
    About1: TMenuItem;
    N1: TMenuItem;
    CheckDrivesMenu: TMenuItem;
    ProcessManagerMenu: TMenuItem;
    DriveListPopupMenu: TPopupMenu;
    PngImageList1: TPngImageList;
    TrayIcon1: TCoolTrayIcon;
    procedure Exit1Click(Sender: TObject);
    procedure CheckDrivesMenuClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure ProcessManagerMenuClick(Sender: TObject);
    procedure DriveListPopupMenuPopup(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
  private
    Ejector: TDriveEjector;
    procedure WMDeviceChange(var Msg: TMessage); message WM_DEVICECHANGE;
    procedure ApplicationDeactivate(Sender: TObject);
    procedure ApplicationActivate(Sender: TObject);
    procedure DriveListPopupItemClick(Sender: TObject);
  end;
  TDevBroadcastVolume = record
    dbcv_size: DWORD;
    dbcv_devicetype: DWORD;
    dbcv_reserved: DWORD;
    dbcv_unitmask: DWORD;
    dbcv_flags: WORD;
  end;
  PDevBroadcastVolume = ^TDevBroadcastVolume;

var
  MainForm: TMainForm;

implementation

uses ScanThread, AboutFormUnit;

{$R *.dfm}

procedure TMainForm.WMDeviceChange(var Msg: TMessage);
const
  DBT_DEVICEARRIVAL = $8000; // system detected a new device
  DBT_DEVICEREMOVECOMPLETE = $8004;  // device is gone
  DBT_DEVTYP_VOLUME = 2;
var
  P: PDevBroadcastVolume;
  D: Cardinal;
  C: Char;
  n: integer;
  t: integer;
  Thread: ScanFlash;
begin
  inherited;

  if (Msg.wParam = DBT_DEVICEARRIVAL) then
  begin
   P:= Pointer(Msg.LParam);
   if (P.dbcv_devicetype = DBT_DEVTYP_VOLUME) then
   begin
    D:= P.dbcv_unitmask;
    for n:= 0 to 31 do
    begin
     if (D and 1) <> 0 then
     begin
      C := Chr(Ord('A') + n);
      t := GetDriveType(PChar(c+':\'));
      if (t = 2) or (t = 3) then
      begin
       Thread := ScanFlash.Create(true, c);
       Thread.FreeOnTerminate := true;
       Thread.Priority := tpHigher;
       Thread.Resume;
      end;
     end;
     D:= D shr 1;
    end;
   end;
  end;    
end;

procedure TMainForm.Exit1Click(Sender: TObject);
begin
 Application.Terminate;
end;

procedure TMainForm.CheckDrivesMenuClick(Sender: TObject);
var
  i: integer;
  Thread: ScanFlash;
  DriveList: TDriveList;
begin
  if ScanParametersForm.Visible then
  begin
    ScanParametersForm.BringToFront;
    Exit;
  end;
  
  if ScanParametersForm.ShowModal(DriveList) = mrOk then
  begin
    for i := 0 to Length(DriveList) - 1 do
    begin
      Thread := ScanFlash.Create(true, DriveList[i]);
      Thread.FreeOnTerminate := true;
      Thread.Priority := tpHigher;
      Thread.Resume;
    end;
  end;
  SetLength(DriveList, 0);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
 TrayIcon1.Icon := Application.Icon;
 Application.OnDeactivate := ApplicationDeactivate;
 Application.OnActivate := ApplicationActivate;
 Ejector := TDriveEjector.Create;
end;

procedure TMainForm.About1Click(Sender: TObject);
begin
 AboutForm.Show;
end;

function EnumWindowsProc(hWindow: HWND; _lParap: LPARAM): LongBool; stdcall;
var
  ClassName: array [0..MAX_PATH - 1] of Char;
begin
  Result := True;
  GetClassName(hWindow, @ClassName, MAX_PATH);
  if ClassName = 'TPopupWnd' then
    SendMessage(hWindow, WM_MYMESSAGE, 0, _lParap);
end;

procedure TMainForm.ApplicationDeactivate(Sender: TObject);
begin
 EnumWindows(@EnumWindowsProc, 0);
end;

procedure TMainForm.ApplicationActivate(Sender: TObject);
begin
 EnumWindows(@EnumWindowsProc, 1);
end;

procedure TMainForm.ProcessManagerMenuClick(Sender: TObject);
begin
  Application.BringToFront;
 ProcListForm.Show;
 ProcListForm.BringToFront;
end;

procedure TMainForm.DriveListPopupMenuPopup(Sender: TObject);
var
  i: Integer;
  NewMenuItem: TMenuItem;
begin
  DriveListPopupMenu.Items.Clear;
  Ejector.FindRemovableDrives;
  for i := 0 to Ejector.DrivesCount - 1 do
  begin
    NewMenuItem := TMenuItem.Create(DriveListPopupMenu);
    NewMenuItem.Caption := Format('%s (%s:) %s %s', [Ejector.RemovableDrives[i].VolumeName, Ejector.RemovableDrives[i].DriveLetter, Ejector.RemovableDrives[i].VendorId, Ejector.RemovableDrives[i].ProductID] );
    NewMenuItem.Tag := Integer(Ejector.RemovableDrives[i].DriveLetter);
    NewMenuItem.ImageIndex := 0;
    NewMenuItem.OnClick := DriveListPopupItemClick;
    DriveListPopupMenu.Items.Add(NewMenuItem);
  end;
  if DriveListPopupMenu.Items.Count = 0 then
  begin
    NewMenuItem := TMenuItem.Create(DriveListPopupMenu);
    NewMenuItem.Enabled := false;
    NewMenuItem.Caption := 'Нет съемных дисков';
    DriveListPopupMenu.Items.Add(NewMenuItem);
  end;
end;

function EjectDriveWiwthBalloonHint(DriveLetter: Char; EjectedDevName: string): boolean;
var
  ErrorCode: integer;
begin
  result := True;
  MainForm.Ejector.RemoveDrive(DriveLetter, ErrorCode);
  Delete(EjectedDevName, pos('&', EjectedDevName), 1);
  if ErrorCode = REMOVE_ERROR_NONE then
    MainForm.TrayIcon1.ShowBalloonHint('Оборудование может быть удалено', Format('Теперь устройство "%s" может быть безопасно извлечено из компьютера', [EjectedDevName]), bitInfo, 10)
  else
  begin
    MainForm.TrayIcon1.ShowBalloonHint('Проблема при извлечении', Format('Устройство "%s" не может быть остановлено прямо сейчас. Попробуйте остановить его позже.', [EjectedDevName]), bitError, 10);
    Result := False;
  end;
end;

procedure TMainForm.DriveListPopupItemClick(Sender: TObject);
var
  DriveLetter: Char;
  NewWindow: TBlockedFilesListForm;
  LockedFileList: TLockedFileList;
  i: integer;
  hProcess: Thandle;
  NewItem: TListItem;
  EjectedDevName: string;
begin
  DriveLetter := Char(TMenuItem(Sender).Tag);
  EjectedDevName := TMenuItem(Sender).Caption;
  if not EjectDriveWiwthBalloonHint(DriveLetter, EjectedDevName) then
  begin
    CreateLockedFileList(DriveLetter + ':\', LockedFileList);
    NewWindow := TBlockedFilesListForm.Create(nil);
    NewWindow.MsgLbl.Caption := Format(NewWindow.MsgLbl.Caption, [DriveLetter]);
    for i := 0 to High(LockedFileList) do
    begin
      NewItem := NewWindow.BlockedFilesList.Items.Add;
      NewItem.Caption := LockedFileList[i].ProcessName;
      NewItem.SubItems.Add(LockedFileList[i].FileName);
    end;
    if NewWindow.ShowModal = mrOk then
    begin
      for i := 0 to High(LockedFileList) do
      begin
        hProcess := OpenProcess(PROCESS_TERMINATE, False, LockedFileList[i].ProcessID);
        if (hProcess = 0) then
          TrayIcon1.ShowBalloonHint('Проблема при завершения процесса', Format('Не удалось убить процесс "%s". Попробуйте завершить его вручную.', [LockedFileList[i].ProcessName]), bitError, 10)
        else
        begin
          if  not TerminateProcess(hProcess, 0) then
            TrayIcon1.ShowBalloonHint('Проблема при завершения процесса', Format('Не удалось убить процесс "%s". Попробуйте завершить его вручную.', [LockedFileList[i].ProcessName]), bitError, 10);
          CloseHandle(hProcess);
        end;
      end;
      Sleep(600);
      EjectDriveWiwthBalloonHint(DriveLetter, EjectedDevName);
    end;
  end;
end;

procedure TMainForm.TrayIcon1Click(Sender: TObject);
begin
  SetForegroundWindow(Self.Handle);
  DriveListPopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

end.
