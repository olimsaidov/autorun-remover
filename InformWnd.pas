unit InformWnd;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TForm3 = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ProcessingFileList: TListView;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Button1: TButton;
    Label9: TLabel;
    Label11: TLabel;
    SerialNumberLabel: TLabel;
    FileSystemLabel: TLabel;
    UsedSizeLabel: TLabel;
    FreeSizeLabel: TLabel;
    DriveSizeLabel: TLabel;
    DriveNameLabel: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  end;

implementation

uses
 PopupWindow;

{$R *.dfm}

procedure TForm3.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 TPopupWnd(Tag).AdditionalInfoLabel.Enabled := true;
end;

procedure TForm3.Button1Click(Sender: TObject);
begin
 Close;
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  Self.Font := Application.MainForm.Font;
end;

end.
