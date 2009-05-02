unit ScanParametersUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, CheckLst;

type
  TDriveList = array of char;

  TScanParametersForm = class(TForm)
    DriveList: TCheckListBox;
    GroupBox1: TGroupBox;
    CancelButton: TButton;
    OkButton: TButton;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private

  public
    function ShowModal(var DriveCharList: TDriveList): integer; reintroduce;
  end;

var
  ScanParametersForm: TScanParametersForm;

implementation

{$R *.dfm}

procedure TScanParametersForm.FormShow(Sender: TObject);
const
  MAX_DRIVES = 26;
var
  i: Integer;
  VolumeName: array [0..MAX_PATH-1] of Char;
  Temp: Cardinal;
  DrivesMask: Cardinal;
  DriveName: string;
begin
  DriveList.Clear;
  DrivesMask := GetLogicalDrives();
  DriveName := '*:\';
  for i := 0 to MAX_DRIVES - 1 do
    if (DrivesMask and (1 shl i)) <> 0 then
    begin
      DriveName[1] := 'A';
      Inc(DriveName[1], i);

      if GetDriveType(PChar(DriveName)) in [2, 3] then
      begin
        GetVolumeInformation(PChar(DriveName), VolumeName, MAX_PATH, nil, Temp, Temp, nil, 0);
        if VolumeName = '' then
          VolumeName := 'Безымянный';
        DriveList.Checked[DriveList.Items.Add(VolumeName + ' (' + DriveName + ')')] := true;
      end;
    end;
end;

function TScanParametersForm.ShowModal(var DriveCharList: TDriveList): integer;
var
 i: integer;
begin
 result :=  TForm(Self).ShowModal;
 SetLength(DriveCharList, 0);
 for i := 0 to DriveList.Items.Count - 1 do
  if DriveList.Checked[i] then
  begin
   SetLength(DriveCharList, Length(DriveCharList) + 1);
   DriveCharList[High(DriveCharList)] := DriveList.Items[i][Pos(':\)', DriveList.Items[i]) - 1];
  end;
end;

procedure TScanParametersForm.FormCreate(Sender: TObject);
begin
  Self.Font := Application.MainForm.Font;
end;

procedure TScanParametersForm.FormActivate(Sender: TObject);
begin
 ShowWindow(Application.Handle, SW_HIDE);
 Application.BringToFront;
end;

end.
