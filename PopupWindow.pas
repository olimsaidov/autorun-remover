unit PopupWindow;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ImgList, Buttons, ComCtrls, XPMan, InformWnd;

const
 WM_MYMESSAGE = WM_USER + $7769;

type
  TPopupWnd = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    CloseImage: TImage;
    Label3: TLabel;
    Image2: TImage;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    AdditionalInfoLabel: TLabel;
    DetectedLabel: TLabel;
    RemovedLabel: TLabel;
    LabelName: TLabel;
    CloseTimer: TTimer;
    procedure AdditionalInfoLabelClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CloseImageClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormHide(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CloseTimerTimer(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure LabelNameClick(Sender: TObject);
    procedure LabelNameMouseEnter(Sender: TObject);
    procedure LabelNameMouseLeave(Sender: TObject);
  public
    AdditionInfoForm: TForm3;
    ParentThread: TThread;
  protected
    procedure HandleMessage(var Msg: TMessage); message WM_MYMESSAGE;
  end;

implementation

{$R *.dfm}

var
 FormFreeTopPosition: array [0..255] of boolean;
 FormLeftPosition: integer;
 FormInitialBasePosition: integer;

procedure TPopupWnd.AdditionalInfoLabelClick(Sender: TObject);
begin
 AdditionalInfoLabel.Enabled := false;
 AdditionInfoForm.Show;
end;

procedure TPopupWnd.FormActivate(Sender: TObject);
begin
 ShowWindow(Application.Handle, SW_HIDE);
 CloseTimer.Enabled := false;
 Application.BringToFront;
end;

procedure TPopupWnd.FormCreate(Sender: TObject);
begin
 AdditionInfoForm := TForm3.Create(Self);
 AdditionInfoForm.Tag := Integer(Self);
 Self.Font := Application.MainForm.Font;
end;

procedure InitFormPosition;
var
 hWindow: HWND;
 WindowRect: TRect;
begin
 hWindow := FindWindow('Progman', nil);
 GetWindowRect(hWindow, WindowRect);
 FormLeftPosition := WindowRect.Right - 315;
 hWindow := FindWindow('Shell_TrayWnd', nil);
 GetWindowRect(hWindow, WindowRect);
 FormInitialBasePosition := WindowRect.Top;
 FillChar(FormFreeTopPosition, 256, True); 
end;

procedure TPopupWnd.FormShow(Sender: TObject);
const
 VertSpace = 10;
var
 i: integer;
begin
 for i := 0 to 255 do
  if FormFreeTopPosition[i] then
  begin
   Self.Tag := i;
   break;
  end;
 FormFreeTopPosition[Self.Tag] := false;
 Self.Left := FormLeftPosition;
 i := FormInitialBasePosition - (Self.Tag + 1) * (Self.Height + VertSpace);
 Self.Top := i;
end;

procedure TPopupWnd.CloseImageClick(Sender: TObject);
begin
 Close;
end;

procedure TPopupWnd.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Hide;
 FormFreeTopPosition[Self.Tag] := true;
 AdditionInfoForm.Free;
 Release;
end;

procedure TPopupWnd.FormHide(Sender: TObject);
var
 i: integer;
begin
 i := 255;
 while i > 0 do
 begin
  Self.AlphaBlendValue := i;
  Sleep(1);
  Application.ProcessMessages;
  Dec(i, 16);
 end;
end;

procedure TPopupWnd.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
 if Assigned(ParentThread) then
 begin
  if (MessageDlg('Проверка еще продолжается. Хотите отменить проверку?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
   ParentThread.Terminate
  else
   CanClose := false;
 end;
end;

procedure TPopupWnd.CloseTimerTimer(Sender: TObject);
begin
 Close;
end;

procedure TPopupWnd.HandleMessage(var Msg: TMessage);
begin
 if Msg.LParam = 0 then
 begin
  if (ParentThread = nil) and AdditionalInfoLabel.Enabled then
   CloseTimer.Enabled := true;
 end
 else
 begin
  if Self.Active then
   CloseTimer.Enabled := false;
 end;
end;

procedure TPopupWnd.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
const
 SC_DRAGMOVE : Longint = $F012;
begin
 if Button <> mbRight then
 begin
   ReleaseCapture;
   SendMessage(Handle, WM_SYSCOMMAND, SC_DRAGMOVE, 0);
 end;
end;

procedure TPopupWnd.LabelNameClick(Sender: TObject);
var
 s: char;
begin
 s := LabelName.Caption[Pos(':)', LabelName.Caption) - 1];
 WinExec(PChar('explorer.exe ' + s + ':\'), SW_SHOW);
end;

procedure TPopupWnd.LabelNameMouseEnter(Sender: TObject);
begin
 if (Sender as TLabel).Enabled then
 (Sender as TLabel).Font.Style := [fsUnderline];
end;

procedure TPopupWnd.LabelNameMouseLeave(Sender: TObject);
begin
 (Sender as TLabel).Font.Style := [];
end;

initialization

InitFormPosition;

end.
