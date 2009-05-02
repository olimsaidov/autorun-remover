object ScanParametersForm: TScanParametersForm
  Left = 466
  Top = 373
  BorderStyle = bsDialog
  Caption = #1055#1072#1088#1072#1084#1077#1090#1088#1099' '#1089#1082#1072#1085#1080#1088#1086#1074#1072#1085#1080#1103
  ClientHeight = 239
  ClientWidth = 314
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 9
    Top = 8
    Width = 296
    Height = 177
    Caption = #1057#1087#1080#1089#1086#1082' '#1088#1072#1079#1076#1077#1083#1086#1074
    TabOrder = 0
    object DriveList: TCheckListBox
      Left = 16
      Top = 24
      Width = 265
      Height = 137
      Flat = False
      ItemHeight = 16
      Style = lbOwnerDrawFixed
      TabOrder = 0
    end
  end
  object CancelButton: TButton
    Left = 230
    Top = 200
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object OkButton: TButton
    Left = 143
    Top = 200
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 2
  end
end
