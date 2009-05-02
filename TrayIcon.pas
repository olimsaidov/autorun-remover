unit TrayIcon;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, AppEvnts, Forms,
  ShellAPI, Graphics, Menus;

const
	TI_MESSAGE = WM_USER + 1;

type

	TWhatShow = (ShIcon, ShForm, ShApplication, ShTask);	//Task=Form+App

  TTrayIcon = class(TComponent)//TCustomApplicationEvents)
  private
    FWindow: HWnd;
    FForm: TForm;
    FIconVisible: Boolean;
    FDestroying: Boolean;
	  FIconData: TNotifyIconData;
    FNT351: Boolean;
    FTip: String;
    FIcon: TIcon;
    FPopupMenu: TPopupMenu;
    FShowIcon: Boolean;
    FShowTip: Boolean;
    FRespondMouse: Boolean;
    FOnClick: TMouseEvent;
    FOnDblClick: TNotifyEvent;
    FFormVisible: Boolean;
    FAppVisible: Boolean;
    FMinimiseToTray: Boolean;
    procedure IconChanged(Sender: TObject);
    procedure SendCancelMode;
    procedure SetTip(const Value: String);
    procedure SetIcon(const Value: TIcon);
    procedure SetFlags(const Index: Integer; const Value: Boolean);
    procedure SendTrayMessage(Msg: DWORD);
    procedure SetPopupMenu(const Value: TPopupMenu);//Процедура установки/удаления/модификации иконки
    function 	CheckMenuPopup(X, Y: Integer): Boolean;
    function 	CheckDefaultMenuItem: Boolean;
    procedure SetMinimiseToTray(const Value: Boolean);
  protected
    procedure WndProc(var Message: TMessage);
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoClick(Button: TMouseButton); virtual;
    procedure DoDblClick; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ShowX(const Index: TWhatShow; const Value: Boolean);
  published
    property Tip: String read FTip write SetTip;
    property Icon: TIcon read FIcon write SetIcon;
    property NIF_MESSAGE: Boolean index 0 read FRespondMouse write SetFlags default True;
    property NIF_ICON: Boolean index 1 read FShowIcon write SetFlags default True;
    property NIF_TIP: Boolean index 2 read FShowTip write SetFlags default True;
    property PopupMenu: TPopupMenu read FPopupMenu write SetPopupMenu;
    property OnClick: TMouseEvent read FOnClick write FOnClick;
    property OnDblClick: TNotifyEvent read FOnDblClick write FOnDblClick;
    property PForm: TForm read FForm;
    property IconVisible: Boolean index ShIcon read FIconVisible write ShowX;
    property FormVisible: Boolean index ShForm read FFormVisible write ShowX;
    property AppVisible: Boolean index ShApplication read FAppVisible write ShowX;
//    property MinimiseToTray: Boolean read FMinimiseToTray write SetMinimiseToTray;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TTrayIcon]);
end;

{ TTrayIcon }

function TTrayIcon.CheckDefaultMenuItem: Boolean;
Var
  i: Integer;
begin
  Result:=False;
  If not (csDesigning in ComponentState) and IconVisible and
    (PopupMenu <> nil) and (PopupMenu.Items <> nil) Then
   	For i:=0 to PopupMenu.Items.Count - 1 do
      If PopupMenu.Items[I].Default Then
       	begin
	        PopupMenu.Items[I].Click;
   		    Result:=True;
	        Break;
   		  end;
end;

function TTrayIcon.CheckMenuPopup(X, Y: Integer): Boolean;
begin
  Result:=False;
  If not (csDesigning in ComponentState) and IconVisible and
    (PopupMenu <> nil) and PopupMenu.AutoPopup Then
	  begin
  	  PopupMenu.PopupComponent:=Self;
	    SendCancelMode;
    	SetForegroundWindow(FWindow);
    	Try
	      PopupMenu.Popup(X, Y);
    	Finally
	      SetForegroundWindow(FWindow);
    	end;
    	Result:=True;
	  end;
end;

constructor TTrayIcon.Create(AOwner: TComponent);
	//Рекурсивная ф-ия поиска формы, на которой лежит компонент.
	function FindForm(Component: TComponent): TForm;
  Var
  	OwnerCmpt: TComponent;
  begin
  	OwnerCmpt:=Component.Owner;
    If (OwnerCmpt <> nil) Then
    	begin
      	If OwnerCmpt.ClassParent = TForm Then
          begin
          	(OwnerCmpt as TForm).HandleNeeded;
          	Result:=OwnerCmpt as TForm;
          end
        Else
		      Result:=FindForm(OwnerCmpt);
      end
    Else
    	Result:=nil;
  end;
begin
	Inherited;
  FNT351:=(Win32MajorVersion <= 3) and (Win32Platform = VER_PLATFORM_WIN32_NT);
  FIcon:=TIcon.Create;
  FIcon.OnChange:=IconChanged;
  FWindow:=Classes.AllocateHWnd(WndProc);
  FForm:=FindForm(Self);
  NIF_MESSAGE:=True;
  NIF_ICON:=True;
  NIF_TIP:=True;
  With FIconData do
  	begin
		  cbSize:=SizeOf(FIconData);
      Wnd:=FWindow;
      uID:=UINT(Self);
	    uCallbackMessage:=TI_MESSAGE;
    end;
end;

destructor TTrayIcon.Destroy;
begin
  FDestroying:=True;
  If IconVisible Then
  	SendTrayMessage(NIM_DELETE);
  FIcon.Free;
  Classes.DeallocateHWnd(FWindow);
  Inherited;
end;

procedure TTrayIcon.DoClick(Button: TMouseButton);
var
  MousePos: TPoint;
begin
  GetCursorPos(MousePos);
  If (Button = mbRight) and CheckMenuPopup(MousePos.X, MousePos.Y) Then
  	Exit;
  If Assigned(FOnClick) Then
  	FOnClick(Self, Button, [], MousePos.X, MousePos.Y);
end;

procedure TTrayIcon.DoDblClick;
begin
  if (not CheckDefaultMenuItem) and Assigned(FOnDblClick) then
    FOnDblClick(Self); 
end;

procedure TTrayIcon.IconChanged(Sender: TObject);
begin
  FIconData.hIcon:=FIcon.Handle;
	If IconVisible Then
    SendTrayMessage(NIM_MODIFY);
end;

procedure TTrayIcon.Loaded;
begin
  Inherited Loaded;
  If FIcon.Empty then		//Если иконка не задана - берем иконку приложения
    FIcon.Assign(Application.Icon);
  FIconData.hIcon:=FIcon.Handle;
  If IconVisible then
    SendTrayMessage(NIM_MODIFY);
  If not (csDesigning in ComponentState) and (FForm <> nil) then
  	begin
			ShowWindow(Application.Handle, SW_SHOW*Integer(FAppVisible));
      ShowWindow(FForm.Handle, SW_SHOW*Integer(FFormVisible));
      Application.ShowMainForm:=FFormVisible;
      FForm.Visible:=FFormVisible;
    end;
end;

procedure TTrayIcon.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  Inherited Notification(AComponent, Operation);
  If (Operation = opRemove) and (AComponent = PopupMenu) then
    PopupMenu:=nil;
end;

procedure TTrayIcon.SendCancelMode;
var
  F: TForm;
begin
  If not ((csDestroying in ComponentState) or FDestroying) then
	  begin
  	  F:=Screen.ActiveForm;
    	If F = nil Then
      	F:=Application.MainForm;
    	If F <> nil Then
      	F.SendCancelMode(nil);
	  end;
end;

procedure TTrayIcon.SendTrayMessage(Msg: DWORD);
begin
  If not FNT351 and not (csDesigning in ComponentState) then
  	Shell_NotifyIcon(Msg, @FIconData);
end;

procedure TTrayIcon.SetFlags(const Index: Integer; const Value: Boolean);
begin
  Case Index of
  	0: FRespondMouse:=Value;
    1: FShowIcon:=Value;
    2: FShowTip:=Value;
  End;
  FIconData.uFlags:=Ord(FRespondMouse) or (Ord(FShowIcon)*2) or (Ord(FShowTip)*4);
  If IconVisible Then
  	begin	//NIM_MODIFY НЕ меняет флаги!!! (uFlags), т.е. нельзя убрать иконку или хинт если они уже есть!
	    SendTrayMessage(NIM_DELETE);
			SendTrayMessage(NIM_ADD);
    end
end;

procedure TTrayIcon.SetIcon(const Value: TIcon);
begin
  FIcon.Assign(Value);
end;

procedure TTrayIcon.SetMinimiseToTray(const Value: Boolean);
begin
  FMinimiseToTray:=Value;
end;

procedure TTrayIcon.SetPopupMenu(const Value: TPopupMenu);
begin
  FPopupMenu:=Value;
  If Value <> nil Then
  	Value.FreeNotification(Self);  
end;

procedure TTrayIcon.SetTip(const Value: String);
begin
  FTip:=Value;
  StrPLCopy(FIconData.szTip, GetShortHint(Value), SizeOf(FIconData.szTip) - 1);
	If IconVisible Then
    SendTrayMessage(NIM_MODIFY);
end;

procedure TTrayIcon.ShowX(const Index: TWhatShow; const Value: Boolean);
begin
	Case Index of
  	ShIcon:  				begin
						  				SendTrayMessage(NIM_DELETE*Integer(not Value));    
    				 					FIconVisible:=Value;
    								end;
  	ShForm:  				FFormVisible:=Value;
    ShApplication:  FAppVisible:=Value;
  End;
  If not (csDesigning in ComponentState) and (FForm <> nil) then
  	begin
      ShowWindow(FForm.Handle, SW_SHOW*Integer(FFormVisible));
      FForm.Visible:=FFormVisible;
			ShowWindow(Application.Handle, SW_SHOW*Integer(FAppVisible));
    	Application.ShowMainForm:=False;
    end;
end;

procedure TTrayIcon.WndProc(var Message: TMessage);
begin
  Try
    With Message do
      If Msg = TI_MESSAGE Then
        Case Message.lParam of
          WM_LBUTTONDBLCLK: DoDblClick;
          WM_LBUTTONUP: DoClick(mbLeft);
          WM_RBUTTONUP: DoClick(mbRight);
        end
      Else
      	Result:=DefWindowProc(FWindow, Msg, wParam, lParam);
  except
    Application.HandleException(Self);
  end;
end;

end.
