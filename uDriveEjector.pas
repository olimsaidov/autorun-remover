unit uDriveEjector;

interface

uses
  Classes, Windows, SysUtils, extctrls,
  CfgMgr32, SetupApi, JwaWinBase, Cfg, JwaWinIoctl, jclsysinfo,
  uProcessAndWindowUtils, uDiskEjectConst;

type
  TRemovableDrive = packed record
    DriveLetter: char;
    VolumeName: string;
    VendorId: string;
    ProductID: string;
    ProductRevision: string;
    BusType: integer;
    ParentDevInst: integer;
  end;

  TDriveEjector = class
  private
    function GetDrivesCount: integer;
    function GetDrivesDevInstByDeviceNumber(DeviceNumber: Integer; DriveType: UINT; szDosDeviceName: PCHAR): DEVINST;
    function GetParentDriveDevInst(DriveLetter: string; var ParentInstNum: integer): boolean;
    //function EjectDevice(DriveLetter: string; var EjectErrorCode: integer; ShowEjectMessage: boolean = false): boolean;
    procedure ScanDrive(DriveLetter: Char);
    procedure DeleteArrayItem(const Index: Integer);
  public
    RemovableDrives: array of TRemovableDrive;
    constructor Create;
    destructor Destroy; override;
    function RemoveDrive(DriveLetter: string; var EjectErrorCode: integer; ShowEjectMessage: boolean = false): boolean;
    procedure FindRemovableDrives;
    property DrivesCount: integer read GetDrivesCount;
  end;

implementation

procedure TDriveEjector.DeleteArrayItem(const Index: Integer);
begin
   if Index > High(RemovableDrives) then Exit;
   if Index < Low(RemovableDrives) then Exit;
   if Index = High(RemovableDrives) then
   begin
     SetLength(RemovableDrives, Length(RemovableDrives) - 1);
     Exit;
   end;
   Finalize(RemovableDrives[Index]);
   System.Move(RemovableDrives[Index +1], RemovableDrives[Index],(Length(RemovableDrives) - Index - 1) * SizeOf(string) + 1);
   SetLength(RemovableDrives, Length(RemovableDrives) - 1);
end;

constructor TDriveEjector.Create;
begin
  LoadSetupApi;
  LoadConfigManagerApi;
end;

destructor TDriveEjector.Destroy;
begin
  SetLength(RemovableDrives, 0);
  UnloadConfigManagerApi;
  UnloadSetupApi;
  inherited;
end;

procedure TDriveEjector.FindRemovableDrives;
const
  MAX_DRIVES = 26;
var
  dwDriveMask: Cardinal;
  DriveName: string;
  i: integer;
begin
  SetLength(RemovableDrives, 0);
  dwDriveMask := GetLogicalDrives;
  DriveName := 'A:\';
  for i := 0 to MAX_DRIVES - 1 do
    if (dwDriveMask and (1 shl I)) <> 0 then
    begin
      DriveName[1] := 'A';
      Inc(DriveName[1], I);
      if GetDriveType(PChar(DriveName)) > 1 then
        ScanDrive(DriveName[1]);
    end;
end;

procedure TDriveEjector.ScanDrive(DriveLetter: Char);
type
  PCharArray = ^TCharArray;
  TCharArray = array[0..32767] of Char;

  STORAGE_PROPERTY_QUERY = packed record
    PropertyId: Cardinal;
    QueryType: Cardinal;
    AdditionalParameters: array[0..3] of Byte;
  end;

  STORAGE_DEVICE_DESCRIPTOR = packed record
    Version: ULONG;
    Size: ULONG;
    DeviceType: Byte;
    DeviceTypeModifier: Byte;
    RemovableMedia: Boolean;
    CommandQueueing: Boolean;
    VendorIdOffset: ULONG;
    ProductIdOffset: ULONG;
    ProductRevisionOffset: ULONG;
    SerialNumberOffset: ULONG;
    STORAGE_BUS_TYPE: Cardinal;
    RawPropertiesLength: ULONG;
    RawDeviceProperties: array[0..511] of Byte;
  end;

const
  IOCTL_STORAGE_QUERY_PROPERTY = $2D1400;

var
  Returned, FFileHandle: Cardinal;
  PropQuery: STORAGE_PROPERTY_QUERY;
  DeviceDescriptor: STORAGE_DEVICE_DESCRIPTOR;
  PCh: PChar;
  Inst: integer;

begin
  FFileHandle:=INVALID_HANDLE_VALUE;
  try
    FFileHandle := CreateFile(
                     PChar('\\.\' + DriveLetter + ':'),
                     0,
                     FILE_SHARE_READ or FILE_SHARE_WRITE,
                     nil,
                     OPEN_EXISTING,
                     0,
                     0
                   );

    if FFileHandle = INVALID_HANDLE_VALUE then exit;

    ZeroMemory(@PropQuery, SizeOf(PropQuery));
    ZeroMemory(@DeviceDescriptor, SizeOf(DeviceDescriptor));
    DeviceDescriptor.Size := SizeOf(DeviceDescriptor);

    if not DeviceIoControl(
                FFileHandle,
                IOCTL_STORAGE_QUERY_PROPERTY,
                @PropQuery,
                SizeOf(PropQuery),
                @DeviceDescriptor,
                DeviceDescriptor.Size,
                @Returned,
                nil
              ) then
      Exit;

    if not((DeviceDescriptor.STORAGE_BUS_TYPE = 7) or (DeviceDescriptor.STORAGE_BUS_TYPE = 4)) then
      Exit;

    SetLength(RemovableDrives, length(RemovableDrives) + 1);
    
    //Drive Letter
    RemovableDrives[high(RemovableDrives)].DriveLetter := DriveLetter;

    //Volume Name
    RemovableDrives[high(RemovableDrives)].VolumeName :=Trim(GetVolumeName(DriveLetter));

    if RemovableDrives[high(RemovableDrives)].VolumeName = '' then
      RemovableDrives[high(RemovableDrives)].VolumeName := 'Безымянный';

    //Vendor Id
    if DeviceDescriptor.VendorIdOffset <> 0 then
    begin
      PCh := @PCharArray(@DeviceDescriptor)^[DeviceDescriptor.VendorIdOffset];
      RemovableDrives[high(RemovableDrives)].VendorId := Trim(PCh);
    end;

    //Product Id
    if DeviceDescriptor.ProductIdOffset <> 0 then
    begin
      PCh := @PCharArray(@DeviceDescriptor)^[DeviceDescriptor.ProductIdOffset];
      RemovableDrives[high(RemovableDrives)].ProductID := Trim(PCh);
    end;

    //Product Revision
    if DeviceDescriptor.ProductRevisionOffset <> 0 then
    begin
      PCh := @PCharArray(@DeviceDescriptor)^[DeviceDescriptor.ProductRevisionOffset];
      RemovableDrives[high(RemovableDrives)].ProductRevision := Trim(PCh);
    end;

    //Bus Type
    RemovableDrives[high(RemovableDrives)].BusType:= DeviceDescriptor.STORAGE_BUS_TYPE;

    //Parents Device Instance
    if GetParentDriveDevInst(DriveLetter, Inst) then
      RemovableDrives[high(RemovableDrives)].ParentDevInst:=Inst;

  finally
    if FFileHandle <> INVALID_HANDLE_VALUE then CloseHandle(FFileHandle);
  end;
end;

function TDriveEjector.GetDrivesCount: integer;
begin
  result:=Length(RemovableDrives);
end;

function TDriveEjector.RemoveDrive(DriveLetter: string; var EjectErrorCode: integer; ShowEjectMessage: boolean): boolean;
var
  DriveIndex: Integer;
  i: Integer;
  FuncResult: Integer;
  VetoType: PNP_VETO_TYPE;
  VetoNameW: array[0..MAX_PATH-1] of WCHAR;
  DevInstParent: DEVINST;
  
begin
  result := false;
  EjectErrorCode := REMOVE_ERROR_NONE;
  DriveIndex:=-1;

  for i := 0 to DrivesCount - 1 do
  begin
    if RemovableDrives[i].DriveLetter = DriveLetter then
    begin
      DriveIndex := i;
      break;
    end;
  end;

  if DriveIndex <> -1 then
  begin
    DevInstParent := RemovableDrives[DriveIndex].ParentDevInst;
    for i := 1 to 1 do
    begin
		  VetoNameW[0] := #0;
      VetoType := PNP_VetoTypeUnknown;

      if ShowEjectMessage then
        funcResult := CM_Request_Device_EjectW(DevInstParent, nil, nil, 0, 0)
      else
		    funcResult := CM_Request_Device_EjectW(DevInstParent, @VetoType, VetoNameW, MAX_PATH, 0);

		  if (funcResult = CR_SUCCESS) and (VetoType = PNP_VetoTypeUnknown) then
      begin
        DeleteArrayItem(DriveIndex);
        Result := true;
			  break;
      end;

		  //Sleep(500);
	  end;
    if result=false then
      EjectErrorCode:=REMOVE_ERROR_DISK_IN_USE;
  end
  else
    EjectErrorCode:=REMOVE_ERROR_DRIVE_NOT_FOUND;
end;

(*function TDriveEjector.EjectDevice(DriveLetter: string; var EjectErrorCode: integer; ShowEjectMessage: boolean = false): boolean;
var
  szRootPath, szDevicePath, szVolumeAccessPath: string;
  DeviceNumber: longint;
  dwBytesReturned: Cardinal;
  DriveType: UINT;
  hVolume: THandle;
  SDN: STORAGE_DEVICE_NUMBER;
  funcResult, tries: integer;
  funcResultBool: boolean;
  DeviceInst, DevInstParent: DEVINST;
  szDosDeviceName: array[0..MAX_PATH-1] of Char;
  VetoType: PNP_VETO_TYPE;
  VetoNameW: array[0..MAX_PATH-1] of WCHAR;
begin
  Result:=false;
  szRootPath:=DriveLetter + ':';
  szDevicePath:=DriveLetter +  ':';
  szVolumeAccessPath:='\\.\' + DriveLetter + ':';
  DeviceNumber:=-1;

  hVolume:=INVALID_HANDLE_VALUE;
  try
    //Open the storage volume
    hVolume:=CreateFile(PChar(szVolumeAccessPath), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
    if hVolume = INVALID_HANDLE_VALUE then
    begin
      if GetLastError = 32 then
        EjectErrorCode:=REMOVE_ERROR_DISK_IN_USE
      else
        EjectErrorCode:=REMOVE_ERROR_UNKNOWN_ERROR;

      exit;
    end;


    //Get the volume's device number
    dwBytesReturned:=0;
    funcResultBool:=DeviceIoControl(hVolume, IOCTL_STORAGE_GET_DEVICE_NUMBER, nil, 0, @SDN, SizeOf(SDN), @dwBytesReturned, nil);
    if funcResultBool = true  then
      DeviceNumber:=SDN.DeviceNumber;

  finally
    CloseHandle(hVolume);
  end;

  if DeviceNumber = -1 then
  begin
    EjectErrorCode:=REMOVE_ERROR_WINAPI_ERROR;
    exit;
  end;


	//Get the drive type
	DriveType := GetDriveType(PChar(szRootPath));
  szDosDeviceName[0]:=#0;

	//Get the dos device name (like \deviceloppy0) to decide if it's a floppy or not
	funcResult := QueryDosDevice(PChar(szDevicePath), szDosDeviceName,  MAX_PATH);
	if funcResult = 0 then
  begin
    EjectErrorCode:=REMOVE_ERROR_WINAPI_ERROR;
    exit;
  end;


	//Get the device instance handle of the storage volume by means of a SetupDi enum and matching the device number
	DeviceInst:= GetDrivesDevInstByDeviceNumber(DeviceNumber, DriveType, szDosDeviceName);
	if ( DeviceInst = 0 ) then
  begin
    EjectErrorCode:=REMOVE_ERROR_WINAPI_ERROR;
    exit;
  end;


	VetoType := PNP_VetoTypeUnknown;
	VetoNameW[0] := #0;

	//Get drives's parent - this is what gets ejected
	DevInstParent := 0;
	CM_Get_Parent(DevInstParent, DeviceInst, 0);

  //Try and eject 3 times
  for tries := 0 to 2 do
  begin
		VetoNameW[0] := #0;

    if ShowEjectMessage then
      funcResult := CM_Request_Device_EjectW(DevInstParent, nil, nil, 0, 0) //With messagebox (W2K, Vista) or balloon (XP)
    else
		  funcResult := CM_Request_Device_EjectW(DevInstParent, @VetoType, VetoNameW, MAX_PATH, 0);

		if (funcResult=CR_SUCCESS) and (VetoType = PNP_VetoTypeUnknown) then
    begin
      Result := true;
			Break;
    end;

		Sleep(500); //Wait and then try again
	 end;

   if result=false then
   begin
    //if GetLastError = 32 then
      EjectErrorCode:=REMOVE_ERROR_DISK_IN_USE
    //else
   //   EjectErrorCode:=REMOVE_ERROR_UNKNOWN_ERROR;
   end;
end;*)

function TDriveEjector.GetDrivesDevInstByDeviceNumber(DeviceNumber: Integer; DriveType: UINT; szDosDeviceName: PCHAR): DEVINST;
var
  IsFloppy: Boolean;
  myGUID: TGUID;
  myhDevInfo: HDEVINFO;
  dwIndex, dwSize, dwBytesReturned: Cardinal;
  FunctionResult: boolean;
  pspdidd: PSPDeviceInterfaceDetailData;
	spdid: SP_DEVICE_INTERFACE_DATA;
	spdd: SP_DEVINFO_DATA;
  hDrive: THandle;
  SDN: STORAGE_DEVICE_NUMBER;
begin
  Result:=0;
  
  if StrPos(szDosDeviceName, '\Floppy') = nil then
    IsFloppy:=false
  else
    IsFloppy := true;

	case (DriveType)  of
    DRIVE_REMOVABLE:
		  if IsFloppy then
			  myguid := GUID_DEVINTERFACE_FLOPPY
      else
			  myguid := GUID_DEVINTERFACE_DISK;

    DRIVE_FIXED:
		  myguid := GUID_DEVINTERFACE_DISK;

    DRIVE_CDROM:
		  myguid := GUID_DEVINTERFACE_CDROM;

    else
      Exit;
  end;

	myhDevInfo := SetupDiGetClassDevs(@myguid, nil, 0, DIGCF_PRESENT or DIGCF_DEVICEINTERFACE);

	if (cardinal(myhDevInfo) = INVALID_HANDLE_VALUE) then
    Exit;

	dwIndex := 0;

  ZeroMemory(@spdd, SizeOf(spdd));
	spdid.cbSize := SizeOf(spdid);

	while True	do
  begin
		FunctionResult := SetupDiEnumDeviceInterfaces(myhDevInfo, nil, myGUID, dwIndex, spdid);
		if FunctionResult= false then
			break;

		dwSize := 0;
		SetupDiGetDeviceInterfaceDetail(myhDevInfo, @spdid, nil, 0, dwSize, nil);

		if ( dwSize <> 0)  and  (dwSize <= 1024) then
    begin
      GetMem(pspdidd, dwSize);
      try
			  pspdidd.cbSize := SizeOf(pspdidd^);
			  ZeroMemory(@spdd, SizeOf(spdd));
			  spdd.cbSize := SizeOf(spdd);

			  FunctionResult := SetupDiGetDeviceInterfaceDetail(myhDevInfo, @spdid, pspdidd, dwSize, dwSize, @spdd);
			  if FunctionResult then
        begin
          hDrive:=INVALID_HANDLE_VALUE;
          try
            hDrive := CreateFile(pspdidd.DevicePath, 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
				    if ( hDrive <> INVALID_HANDLE_VALUE ) then
            begin
					    dwBytesReturned := 0;
					    FunctionResult := DeviceIoControl(hDrive, IOCTL_STORAGE_GET_DEVICE_NUMBER, nil, 0, @sdn, SizeOf(sdn), @dwBytesReturned, nil);
					    if FunctionResult and (DeviceNumber = LongInt(sdn.DeviceNumber)) then
              begin
							  result:= spdd.DevInst;
                break;
				      end;
            end;
          finally
            CloseHandle(hDrive);
          end;
			  end;
      finally
        FreeMem(pspdidd);
      end;
	  end;
    dwIndex:= dwIndex + 1;
  end;
	SetupDiDestroyDeviceInfoList(myhDevInfo);
end;

function TDriveEjector.GetParentDriveDevInst(DriveLetter: string; var ParentInstNum: integer): boolean;
var
  szRootPath, szDevicePath, szVolumeAccessPath: string;
  DeviceNumber: longint;
  hVolume: THandle;
  dwBytesReturned: Cardinal;
  DriveType: UINT;
  SDN: STORAGE_DEVICE_NUMBER;
  FunctionResultInt: integer;
  FunctionResultBool: boolean;
  DeviceInst, DevInstParent: DEVINST;
  szDosDeviceName: array[0..MAX_PATH-1] of Char;
begin
  Result:=false;
  szRootPath:=DriveLetter + ':';
  szDevicePath:=DriveLetter +  ':';
  szVolumeAccessPath:='\\.\' + DriveLetter + ':';
  DeviceNumber:=-1;

  hVolume:= INVALID_HANDLE_VALUE;
  try
    hVolume:=CreateFile(PChar(szVolumeAccessPath), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
    if hVolume = INVALID_HANDLE_VALUE then
      exit;

    dwBytesReturned:=0;
    FunctionResultBool:=DeviceIoControl(hVolume, IOCTL_STORAGE_GET_DEVICE_NUMBER, nil, 0, @SDN, SizeOf(SDN), @dwBytesReturned, nil);
    if FunctionResultBool then
      DeviceNumber:=SDN.DeviceNumber;

  finally
    CloseHandle(hVolume);
  end;

  if DeviceNumber = -1 then
    exit;

	DriveType := GetDriveType(PChar(szRootPath));
  szDosDeviceName[0]:=#0;

	FunctionResultInt := QueryDosDevice(PChar(szDevicePath), szDosDeviceName,  MAX_PATH);
	if FunctionResultInt = 0 then
    exit;

	DeviceInst:= GetDrivesDevInstByDeviceNumber(DeviceNumber, DriveType, szDosDeviceName);

	if (DeviceInst = 0) then
    exit;

	DevInstParent:=0;
	CM_Get_Parent(DevInstParent, DeviceInst, 0);

  if DevInstParent > 0 then
  begin
    ParentInstNum:=DevInstParent;
    result:=true;
  end;
end;

end.
