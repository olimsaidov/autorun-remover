program AutorunRemover;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  PopupWindow in 'PopupWindow.pas',
  InformWnd in 'InformWnd.pas',
  ScanThread in 'ScanThread.pas',
  ScanParametersUnit in 'ScanParametersUnit.pas',
  ProcessListForm in 'ProcessListForm.pas' {ProcListForm},
  AboutFormUnit in 'AboutFormUnit.pas' {AboutForm},
  BlockedFileListFormUnit in 'BlockedFileListFormUnit.pas' {BlockedFilesListForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TProcListForm, ProcListForm);
  Application.CreateForm(TAboutForm, AboutForm);
  Application.CreateForm(TScanParametersForm, ScanParametersForm);
  Application.ShowMainForm := False;
  Application.Run;
end.
