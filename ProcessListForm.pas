unit ProcessListForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, UList, ProcList, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Menus ;

type
  TProcListForm = class(TForm)
    ListView1: TListView;
    Button1: TButton;
    Button2: TButton;
    PopupMenu1: TPopupMenu;
    Kill1: TMenuItem;
    procedure FormShow(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Kill1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ListView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ProcListForm: TProcListForm;


implementation

{$R *.dfm}

procedure TProcListForm.FormShow(Sender: TObject);
var
 List: PListStruct;
 Process: PProcessRecord;
 Path: string;
begin
 ListView1.DoubleBuffered := true;
 List := nil;
 GetFullProcessesInfo(List);
 ListView1.Items.Clear;
 while List <> nil do
 begin
  with ListView1.Items.Add do
  begin
   Process := List^.pData;
   Caption := Process^.ProcessName;
   SubItems.Append(IntToStr(Process^.ProcessId));
   Path := Process^.Path;
   System.Delete(Path, 1, Pos(':', Path) - 2);
   //Path[1] := UpperCase(Path[1])[1];
   SubItems.Append(Path);
  end;
  List := List^.pNext;
 end;
 FreeListWidthData(List);
 Self.Resize;
end;

procedure TProcListForm.FormActivate(Sender: TObject);
begin
 ShowWindow(Application.Handle, SW_HIDE);
 Application.BringToFront;
end;

procedure TProcListForm.Kill1Click(Sender: TObject);
var
  Item: TListItem;
  hProcess: integer;
  Result: Boolean;
begin
  Result := False;
  Item := ListView1.Selected;
  if Item <> nil then
    begin
      hProcess := OpenProcess(PROCESS_TERMINATE, false, StrToInt(Item.SubItems.Strings[0]));
      if hProcess > 0 then
      begin
        Result := TerminateProcess(hProcess, 0);
        CloseHandle(hProcess);
      end
      else
        Result := False;
    end;
  if Result = True then
    ListView1.Selected.Delete
  else
    MessageDlg('Не удалось завершить процесс', mtWarning, [mbOk], 0);
  ListView1.SetFocus;
end;

procedure TProcListForm.Button2Click(Sender: TObject);
begin
 Self.Close;
end;

procedure TProcListForm.FormCreate(Sender: TObject);
begin
 Self.Font := Application.MainForm.Font;
end;

procedure TProcListForm.ListView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 46 then
    Kill1Click(nil);
end;

end.
