object Form3: TForm3
  Left = 713
  Top = 82
  BorderStyle = bsDialog
  Caption = #1044#1086#1087#1086#1083#1085#1080#1090#1077#1083#1100#1085#1072#1103' '#1080#1085#1092#1086#1088#1084#1072#1094#1080#1103
  ClientHeight = 424
  ClientWidth = 395
  Color = clBtnFace
  Font.Charset = RUSSIAN_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  DesignSize = (
    395
    424)
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 10
    Top = 8
    Width = 376
    Height = 153
    Anchors = [akLeft, akTop, akRight]
    Caption = #1054#1073#1097#1072#1103' '#1080#1085#1092#1086#1088#1084#1072#1094#1080#1103
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 20
      Width = 70
      Height = 13
      Caption = #1052#1077#1090#1082#1072' '#1090#1086#1084#1072
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 16
      Top = 78
      Width = 42
      Height = 13
      Caption = #1047#1072#1085#1103#1090#1086
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 16
      Top = 59
      Width = 58
      Height = 13
      Caption = #1057#1074#1086#1073#1086#1076#1085#1086
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 16
      Top = 39
      Width = 48
      Height = 13
      Caption = #1045#1084#1082#1086#1089#1090#1100
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label9: TLabel
      Left = 16
      Top = 98
      Width = 107
      Height = 13
      Caption = #1060#1072#1081#1083#1086#1074#1072#1103' '#1089#1080#1089#1090#1077#1084#1072
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label11: TLabel
      Left = 16
      Top = 118
      Width = 95
      Height = 13
      Caption = #1057#1077#1088#1080#1081#1085#1099#1081' '#1085#1086#1084#1077#1088
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object SerialNumberLabel: TLabel
      Left = 168
      Top = 118
      Width = 6
      Height = 13
      Caption = '_'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object FileSystemLabel: TLabel
      Left = 168
      Top = 98
      Width = 6
      Height = 13
      Caption = '_'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object UsedSizeLabel: TLabel
      Left = 168
      Top = 78
      Width = 6
      Height = 13
      Caption = '_'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object FreeSizeLabel: TLabel
      Left = 168
      Top = 59
      Width = 6
      Height = 13
      Caption = '_'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object DriveSizeLabel: TLabel
      Left = 168
      Top = 39
      Width = 6
      Height = 13
      Caption = '_'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object DriveNameLabel: TLabel
      Left = 168
      Top = 20
      Width = 6
      Height = 13
      Caption = '_'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
  end
  object GroupBox2: TGroupBox
    Left = 10
    Top = 168
    Width = 376
    Height = 209
    Anchors = [akLeft, akTop, akRight]
    Caption = #1057#1087#1080#1089#1086#1082' '#1086#1073#1088#1072#1073#1086#1090#1072#1085#1085#1099#1093' '#1092#1072#1081#1083#1086#1074' '#1080' '#1082#1072#1090#1072#1083#1086#1075#1086#1074' '#1074' '#1101#1090#1086#1084' '#1088#1072#1079#1076#1077#1083#1077
    TabOrder = 1
    DesignSize = (
      376
      209)
    object ProcessingFileList: TListView
      Left = 11
      Top = 22
      Width = 351
      Height = 171
      Anchors = [akLeft, akTop, akRight, akBottom]
      Columns = <
        item
          Caption = #1048#1084#1103' '#1092#1072#1081#1083#1072
          Width = 150
        end
        item
          Caption = #1056#1072#1079#1084#1077#1088
          Width = 70
        end
        item
          AutoSize = True
          Caption = #1057#1086#1089#1090#1086#1103#1085#1080#1077
        end>
      MultiSelect = True
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
    end
  end
  object Button1: TButton
    Left = 310
    Top = 388
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 2
    OnClick = Button1Click
  end
end
