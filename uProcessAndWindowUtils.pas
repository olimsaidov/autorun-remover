 {
******************************************************
  USB Disk Ejector
  Copyright (c) 2006, 2007, 2008 Ben Gorman
  Http://quick.mixnmojo.com
******************************************************
}
{
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}

unit uProcessAndWindowUtils;

interface

uses Windows, Messages, sysutils, JCLSysInfo, PsAPI, TlHelp32;

function EnumWindowsAndCloseFunc (Handle: THandle; DriveLetter: char): BOOL; stdcall;
function EnumChildWindowsAndCloseFunc (Handle: THandle; DriveString: string): BOOL; stdcall;
function CloseAppsRunningFrom(DriveLetter: Char; ForceClose: Boolean): boolean;

implementation

var
  TopWindow: hwnd;


{******************Close Explorer Windows For A Specified Drive****************}

function EnumChildWindowsAndCloseFunc(Handle: THandle;
  DriveString: string): BOOL;
var
  WindowText : array[0.. MAX_PATH - 1] of Char;
  FoundPos: integer;
begin
  SendMessage(Handle, WM_GETTEXT, sizeof(WindowText), integer(@WindowText[0]));

  FoundPos:= pos(DriveString, WindowText);
  if FoundPos > 0 then
  begin
    PostMessage (TopWindow, WM_CLOSE, 0, 0);
  end;

  Result:=true;
end;

function EnumWindowsAndCloseFunc(Handle: THandle;
  DriveLetter: char): BOOL;
var
  WindowHandle: HWND;
  WindowName, WindowText: array[0..MAX_PATH - 1] of Char;
  FoundPos: integer;
  DriveString: string;
begin
  //Driveletter must be upper case
  DriveLetter:=UpCase(DriveLetter);

  //Build the search string
  DriveString:=DriveLetter + ':\';

  //Get the window caption
  SendMessage(Handle, WM_GETTEXT, SizeOf(WindowName), integer(@WindowName[0]));

  //Look for CabinetWClass in all windows
  WindowHandle := FindWindow('CabinetWClass', WindowName);
  if WindowHandle > 0 then //Found an explorer window
  begin
    //Get its caption and see if its got drive letter in it
    GetWindowText(WindowHandle, WindowText, SizeOf(WindowText));
    FoundPos:= pos(DriveString, WindowText);
    if Foundpos > 0 then
    begin
      PostMessage (WindowHandle, WM_CLOSE, 0, 0);
    end;

    //Search all its hidden child windows
    TopWindow:=WindowHandle;
    EnumChildWindows(WindowHandle, @EnumChildWindowsAndCloseFunc, LParam(DriveString));
  end;

  Result :=True;
end;




{*******************Close Apps Running From A Specified Drive******************}

Function InstanceToWnd( Const TgtPID:DWORD):HWND;
Var
  ThisHWnd :HWND;
  ThisPID :DWORD;
Begin
  Result := 0;
  ThisPID := 0;
  // Find the first Top Level Window
  ThisHWnd := FindWindow( Nil, Nil);
  ThisHWnd := GetWindow( ThisHWnd, GW_HWNDFIRST );
  While ThisHWnd <> 0 Do
  Begin
    //Check if the window isn't a child (redundant?)
    If GetParent( ThisHWnd ) = 0 Then
    Begin
      //Get the window's thread & ProcessId
      GetWindowThreadProcessId( ThisHWnd, Addr(ThisPID) );
      If ThisPID = TgtPID Then
      Begin
        Result := ThisHWnd;
        Break;
      End;
    End;
  // 'retrieve the next window
  ThisHWnd := GetWindow( ThisHWnd, GW_HWNDNEXT );
  End;
End;

procedure CloseWindowByID(ID: Cardinal);
var
  wind: hwnd;
begin
  wind:=InstanceToWnd(ID);
  if wind <> 0 then
  begin
    //postMessage (wind, WM_CLOSE, 0, 0);
    sendMessage (wind, WM_CLOSE, 0, 0); //wait to return
    sleep(3000);
  end;
end;

procedure TerminateProcessById(ID: Cardinal);
var
  HndProcess : THandle;
begin
  HndProcess := OpenProcess(PROCESS_TERMINATE,TRUE, ID);
  if HndProcess <> 0 then
  try
    TerminateProcess(HndProcess,0);
  finally
    CloseHandle(HndProcess);
  end;
end;

function GetProcessFileName(PID: DWORD): string;
var
  Handle: THandle;
begin
  Result := '';
  Handle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, PID);
  if Handle <> 0 then
    try
      SetLength(Result, MAX_PATH);
      begin
        if GetModuleFileNameEx(Handle, 0, PChar(Result), MAX_PATH) > 0 then
          SetLength(Result, StrLen(PChar(Result)))
        else
          Result := '';
      end
    finally
      CloseHandle(Handle);
    end;
end;

function KillAppsFromDrive_NT(DriveString: string; ForceClose: Boolean): Boolean;
const
  RsSystemIdleProcess = 'System Idle Process';
  RsSystemProcess = 'System Process';
var
  SnapProcHandle: THandle;
  ProcEntry: TProcessEntry32;
  NextProc: Boolean;
  FileName: string;
begin
  SnapProcHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  Result := (SnapProcHandle <> INVALID_HANDLE_VALUE);
  if Result then
    try
      ProcEntry.dwSize := SizeOf(ProcEntry);
      NextProc := Process32First(SnapProcHandle, ProcEntry);
      while NextProc do
      begin
        if ProcEntry.th32ProcessID = 0 then
        begin
          // PID 0 is always the "System Idle Process" but this name cannot be
          // retrieved from the system and has to be fabricated.
          FileName := RsSystemIdleProcess;
        end
        else
        begin
          if GetWindowsVersion >= wvWin2000 then //IsWin2k or IsWinXP then
          begin
            FileName := GetProcessFileName(ProcEntry.th32ProcessID);
            if FileName = '' then
              FileName := ProcEntry.szExeFile;
          end
          else
          begin
            FileName := ProcEntry.szExeFile;
          end;
        end;

        //If running from the drive - then close it
        if ExtractFileDrive(Filename) = DriveString then
          if ForceClose then  
            TerminateProcessById(ProcEntry.th32ProcessID)
          else
            CloseWindowById(ProcEntry.th32ProcessID);

        NextProc := Process32Next(SnapProcHandle, ProcEntry);
      end;
    finally
      CloseHandle(SnapProcHandle);
    end;
end;

function CloseAppsRunningFrom(DriveLetter: Char; ForceClose: Boolean): boolean;
var
  DriveString: string;
begin
  result:=false;
  if GetWindowsVersion < wvWin2000 then exit;

  //Driveletter must be upper case
  DriveLetter:=UpCase(DriveLetter);

  //Build the search string
  DriveString:=DriveLetter + ':';

  result:=KillAppsFromDrive_NT(DriveString, ForceClose);
end;


end.
