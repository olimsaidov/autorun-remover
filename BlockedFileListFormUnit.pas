unit BlockedFileListFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TBlockedFilesListForm = class(TForm)
    BlockedFilesList: TListView;
    MsgLbl: TLabel;
    CancelBtn: TButton;
    OkBtn: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BlockedFilesListForm: TBlockedFilesListForm;

implementation

{$R *.dfm}

procedure TBlockedFilesListForm.FormCreate(Sender: TObject);
begin
  Self.Font := Application.MainForm.Font;
end;

procedure TBlockedFilesListForm.FormActivate(Sender: TObject);
begin
  Application.BringToFront;
  Self.BringToFront;
  SetForegroundWindow(Self.Handle);
end;

end.
