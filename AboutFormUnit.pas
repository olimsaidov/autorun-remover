unit AboutFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, JvExControls, JvScrollText, ExtCtrls;

type
  TAboutForm = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    Button1: TButton;
    Panel1: TPanel;
    JvScrollText1: TJvScrollText;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutForm: TAboutForm;

implementation

{$R *.dfm}

procedure TAboutForm.FormCreate(Sender: TObject);
begin
  Image1.Picture.Icon := Application.Icon;
  Self.Font := Application.MainForm.Font;
  Label1.Font.Style := [fsBold];
end;

procedure TAboutForm.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TAboutForm.FormActivate(Sender: TObject);
begin
 ShowWindow(Application.Handle, SW_HIDE);
 Application.BringToFront;
end;

end.                                                                                                                                                      D:

