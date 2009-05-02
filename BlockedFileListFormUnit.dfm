object BlockedFilesListForm: TBlockedFilesListForm
  Left = 542
  Top = 156
  BorderStyle = bsDialog
  Caption = #1047#1072#1085#1103#1090#1099#1077' '#1092#1072#1081#1083#1099
  ClientHeight = 295
  ClientWidth = 419
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesktopCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object MsgLbl: TLabel
    Left = 16
    Top = 16
    Width = 393
    Height = 39
    Caption = 
      #1047#1076#1077#1089#1100' '#1087#1077#1088#1077#1095#1080#1089#1083#1077#1085#1099' '#1074#1089#1077' '#1086#1090#1082#1088#1099#1090#1080#1077' '#1092#1072#1081#1083#1099' '#1080' '#1087#1088#1086#1094#1077#1089#1089#1099' '#1074' '#1090#1086#1084#1077' (%s:). '#1053#1072 +
      #1078#1084#1080#1090#1077' '#1054#1050' '#1095#1090#1086#1073#1099' '#1087#1088#1080#1085#1091#1076#1080#1090#1077#1083#1100#1085#1086' '#1079#1072#1082#1088#1099#1090#1100' '#1080#1093' '#1080' '#1077#1097#1077' '#1088#1072#1079' '#1087#1086#1087#1099#1090#1072#1090#1100#1089#1103' '#1080#1079#1074 +
      #1083#1077#1095#1100' '#1091#1089#1090#1088#1086#1081#1089#1090#1074#1086'.'
    WordWrap = True
  end
  object BlockedFilesList: TListView
    Left = 11
    Top = 72
    Width = 395
    Height = 169
    Columns = <
      item
        Caption = #1048#1084#1103' '#1087#1088#1086#1094#1077#1089#1089#1072
        Width = 150
      end
      item
        AutoSize = True
        Caption = #1048#1084#1103' '#1092#1072#1081#1083#1072'/'#1087#1072#1087#1082#1080
      end>
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
  end
  object CancelBtn: TButton
    Left = 330
    Top = 255
    Width = 75
    Height = 25
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 1
  end
  object OkBtn: TButton
    Left = 242
    Top = 255
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 2
  end
end
