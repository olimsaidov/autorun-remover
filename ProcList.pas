unit ProcList;

interface

uses
 windows,  NativeAPI, UList, SysUtils, TlHelp32;

type
  PProcessRecord = ^TProcessRecord;
  TProcessRecord = packed record
    Visible: boolean;
    SignalState: dword;
    Present: boolean;
    ProcessId: dword;
    ParrentPID: dword;
    pEPROCESS: dword;
    ProcessName: array [0..255] of Char;
    Path: array [0..255] of Char;
  end;    


procedure GetFullProcessesInfo(var List: PListStruct);

var
 hDriver: dword = 0;
 
implementation

type
 JOBOBJECTINFOCLASS  =
 (
    JobObjectBasicAccountingInformation = 1,
    JobObjectBasicLimitInformation,
    JobObjectBasicProcessIdList,
    JobObjectBasicUIRestrictions,
    JobObjectSecurityLimitInformation,
    JobObjectEndOfJobTimeInformation,
    JobObjectAssociateCompletionPortInformation,
    MaxJobObjectInfoClass
 );

 PJOBOBJECT_BASIC_PROCESS_ID_LIST = ^JOBOBJECT_BASIC_PROCESS_ID_LIST;
 JOBOBJECT_BASIC_PROCESS_ID_LIST  = packed record
    NumberOfAssignedProcesses,
    NumberOfProcessIdsInList: dword;
    ProcessIdList: array [0..0] of dword;
 end;


function QueryInformationJobObject(hJob: dword; JobObjectInfoClass: JOBOBJECTINFOCLASS;
                                   lpJobObjectInfo: pointer;
                                   bJobObjectInfoLength: dword;
                                   lpReturnLength: pdword): bool; stdcall; external 'kernel32.dll';


const
 MSG_BUFF_SIZE = 4096;
 
 BASE_IOCTL = (FILE_DEVICE_UNKNOWN shl 16) or (FILE_READ_ACCESS shl 14) or METHOD_BUFFERED;
 IOCTL_SET_SWAPCONTEXT_HOOK  = BASE_IOCTL  or (1 shl 2);
 IOCTL_SWAPCONTEXT_UNHOOK    = BASE_IOCTL  or (2 shl 2);
 IOCTL_SET_SYSCALL_HOOK      = BASE_IOCTL  or (3 shl 2);
 IOCTL_SYSCALL_UNHOOK        = BASE_IOCTL  or (4 shl 2);
 IOCTL_GET_EXTEND_PSLIST     = BASE_IOCTL  or (5 shl 2);
 IOCTL_GET_NATIVE_PSLIST     = BASE_IOCTL  or (6 shl 2);
 IOCTL_GET_EPROCESS_PSLIST   = BASE_IOCTL  or (7 shl 2);
 IOCTL_SCAN_THREADS          = BASE_IOCTL  or (8 shl 2);
 IOCTL_SCAN_PSP_CID_TABLE    = BASE_IOCTL  or (9 shl 2);
 IOCTL_HANDLETABLES_LIST     = BASE_IOCTL  or (10 shl 2);
 IOCTL_GET_MESSAGES          = BASE_IOCTL  or (11 shl 2);

function IsPidAdded(List: PListStruct; Pid: dword): boolean;
begin
  Result := false;
  while (List <> nil) do
    begin
      if PProcessRecord(List^.pData)^.ProcessId = Pid then
        begin
          Result := true;
          Exit;
        end;
      List := List^.pNext;
    end;
end;

function IsEprocessAdded(List: PListStruct; pEPROCESS: dword): boolean;
begin
  Result := false;
  while (List <> nil) do
    begin
      if PProcessRecord(List^.pData)^.pEPROCESS = pEPROCESS then
        begin
          Result := true;
          Exit;
        end;
      List := List^.pNext;
    end;
end;

{
 Получение списка процессов через ToolHelp API.
}
procedure GetToolHelpProcessList(var List: PListStruct);
var
 Snap: dword;
 Process: TPROCESSENTRY32;
 NewItem: PProcessRecord;
begin
  Snap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snap <> INVALID_HANDLE_VALUE then
     begin
      Process.dwSize := SizeOf(TPROCESSENTRY32);
      if Process32First(Snap, Process) then
         repeat
          GetMem(NewItem, SizeOf(TProcessRecord));
          ZeroMemory(NewItem, SizeOf(TProcessRecord));
          NewItem^.ProcessId  := Process.th32ProcessID;
          NewItem^.ParrentPID := Process.th32ParentProcessID;
          lstrcpy(@NewItem^.ProcessName, Process.szExeFile);
          AddItem(List, NewItem);
         until not Process32Next(Snap, Process);
      CloseHandle(Snap);
     end;
end;

Procedure CopyListWithData(var NewList: PListStruct; List: PListStruct);
var
 NewItem: PProcessRecord;
begin
  while (List <> nil) do
    begin
      GetMem(NewItem, SizeOf(TProcessRecord));
      ZeroMemory(NewItem, SizeOf(TProcessRecord));
      NewItem^ := PProcessRecord(List^.pData)^;
      NewItem^.Visible := false;
      AddItem(NewList, NewItem);
      List := List^.pNext;
    end;
end;

{
  Системный вызов ZwQuerySystemInformation для Windows XP.
}
Function XpZwQuerySystemInfoCall(ASystemInformationClass: dword;
                                 ASystemInformation: Pointer;
                                 ASystemInformationLength: dword;
                                 AReturnLength: pdword): dword; stdcall;
asm
 pop ebp
 mov eax, $AD
 call @SystemCall
 ret $10
 @SystemCall:
 mov edx, esp
 sysenter
end;

{
  Получение списка процессов через системный вызов
  ZwQuerySystemInformation.
}
procedure GetSyscallProcessList(var List: PListStruct);
var
 Info: PSYSTEM_PROCESSES;
 NewItem: PProcessRecord;
 mPtr: pointer;
 mSize: dword;
 St: NTStatus;
begin
 mSize := $4000;
 repeat
  GetMem(mPtr, mSize);
  St := XpZwQuerySystemInfoCall(SystemProcessesAndThreadsInformation,
                              mPtr, mSize, nil);
  if St = STATUS_INFO_LENGTH_MISMATCH then
    begin
      FreeMem(mPtr);
      mSize := mSize * 2;
    end;
 until St <> STATUS_INFO_LENGTH_MISMATCH;
 if St = STATUS_SUCCESS then
  begin
    Info := mPtr;
    repeat
     GetMem(NewItem, SizeOf(TProcessRecord));
     ZeroMemory(NewItem, SizeOf(TProcessRecord));
     lstrcpy(@NewItem^.ProcessName,
             PChar(WideCharToString(Info^.ProcessName.Buffer)));
     NewItem^.ProcessId  := Info^.ProcessId;
     NewItem^.ParrentPID := Info^.InheritedFromProcessId;
     Info := pointer(dword(info) + info^.NextEntryDelta);
     AddItem(List, NewItem);
    until Info^.NextEntryDelta = 0;
  end;
 FreeMem(mPtr);
end;

function GetNameByPid(Pid: dword): string;
var
 hProcess, Bytes: dword;
 Info: PROCESS_BASIC_INFORMATION;
 ProcessParametres: pointer;
 ImagePath: TUnicodeString;
 ImgPath: array[0..MAX_PATH] of WideChar;
begin
 Result := '';
 ZeroMemory(@ImgPath, MAX_PATH * SizeOf(WideChar));
 hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, false, Pid);
 if ZwQueryInformationProcess(hProcess, ProcessBasicInformation, @Info,
                              SizeOf(PROCESS_BASIC_INFORMATION), nil) = STATUS_SUCCESS then
  begin
   if ReadProcessMemory(hProcess, pointer(dword(Info.PebBaseAddress) + $10),
                        @ProcessParametres, SizeOf(pointer), Bytes) and
      ReadProcessMemory(hProcess, pointer(dword(ProcessParametres) + $38),
                        @ImagePath, SizeOf(TUnicodeString), Bytes)  and
      ReadProcessMemory(hProcess, ImagePath.Buffer, @ImgPath,
                        ImagePath.Length, Bytes) then
        begin
          Result := ExtractFilePath(WideCharToString(ImgPath));
        end;
   end;
 CloseHandle(hProcess);
 {if Result = '' then
  Result := 'N/A';}
end;

procedure LookupProcNames(List: PListStruct);
var
 Process: PProcessRecord;
begin
  while (List <> nil) do
    begin
      Process := List^.pData;
      //if (Process^.ProcessName = '') and (Process^.ProcessId <> 0) then
      lstrcpy(Process^.Path, PChar(GetNameByPid(Process^.ProcessId)));
      List := List^.pNext;
    end;
end;

function FindProcess(List: PListStruct; Pid, pEPROCESS: dword): PProcessRecord;
var
 Process: PProcessRecord;
begin
  Result := nil;
  while (List <> nil) do
    begin
      Process := List^.pData;
      if ( ((pEPROCESS <> 0) and (Process^.pEPROCESS = pEPROCESS)) or
           ((Pid <> 0) and (Process^.ProcessId = Pid)) or
           ((Pid = 0) and (pEPROCESS = 0) and (Process^.pEPROCESS = 0)
           and (Process^.ProcessId = 0))  ) then
        begin
          Result := Process;
          Exit;
        end;
      List := List^.pNext;
    end;  
end;

procedure MergeList(var List: PListStruct; List2: PListStruct);
var
 Process, Process2: PProcessRecord;
begin
  while (List2 <> nil) do
    begin
      Process := List2^.pData;
      Process2 := FindProcess(List, Process^.ProcessId, Process^.pEPROCESS);
      if Process2 = nil then AddItem(List, Process) else
        begin
         if Process2^.ProcessId   = 0  then Process2^.ProcessId   := Process^.ProcessId;
         if Process2^.pEPROCESS   = 0  then Process2^.pEPROCESS   := Process^.pEPROCESS;
         if Process2^.ParrentPID  = 0  then Process2^.ParrentPID  := Process^.ParrentPID;
         if Process2^.ProcessName = '' then Process2^.ProcessName := Process^.ProcessName;
         if Process2^.SignalState = 0  then Process2^.SignalState := Process^.SignalState;
        end;
      List2 := List2^.pNext;
    end;
end;

procedure GetFullProcessesInfo(var List: PListStruct);
var
 TLHelpList:        PListStruct;
 SyscallList:       PListStruct;
 AllProcesses:      PListStruct;
begin

 TLHelpList        := nil;
 SyscallList       := nil;
 AllProcesses      := nil;

 GetSyscallProcessList(SyscallList);
 GetToolHelpProcessList(TLHelpList);

 MergeList(AllProcesses, TLHelpList);
 MergeList(AllProcesses, SyscallList);

 CopyListWithData(List, AllProcesses);

 LookupProcNames(List);

 FreeListWidthData(TLHelpList);
 FreeListWidthData(SyscallList);
end;

{ Включение заданой привилегии для процесса }
function EnablePrivilegeEx(Process: dword; lpPrivilegeName: PChar):Boolean;
var
  hToken: dword;
  NameValue: Int64;
  tkp: TOKEN_PRIVILEGES;
  ReturnLength: dword;
begin                             
  Result:=false;
  //Получаем токен нашего процесса
  OpenProcessToken(Process, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken);
  //Получаем LUID привилегии
  if not LookupPrivilegeValue(nil, lpPrivilegeName, NameValue) then
    begin
     CloseHandle(hToken);
     exit;
    end;
  tkp.PrivilegeCount := 1;
  tkp.Privileges[0].Luid := NameValue;
  tkp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
  //Добавляем привилегию к процессу
  AdjustTokenPrivileges(hToken, false, tkp, SizeOf(TOKEN_PRIVILEGES), tkp, ReturnLength);
  if GetLastError() <> ERROR_SUCCESS then
     begin
      CloseHandle(hToken);
      exit;
     end;
  Result:=true;
  CloseHandle(hToken);
end;

{ включение заданной привилегии для текущего процесса }
function EnablePrivilege(lpPrivilegeName: PChar):Boolean;
begin
  Result := EnablePrivilegeEx(INVALID_HANDLE_VALUE, lpPrivilegeName);
end;


{ Включение привилегии SeDebugPrivilege для процесса }
function EnableDebugPrivilegeEx(Process: dword):Boolean;
begin
  Result := EnablePrivilegeEx(Process, 'SeDebugPrivilege');
end;

{ Включение привилегии SeDebugPrivilege для текущего процесса }
function EnableDebugPrivilege():Boolean;
begin
  Result := EnablePrivilegeEx(INVALID_HANDLE_VALUE, 'SeDebugPrivilege');
end;

initialization
 EnableDebugPrivilege();
end.
