object ProcListForm: TProcListForm
  Left = 351
  Top = 186
  Width = 475
  Height = 468
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = #1044#1080#1089#1087#1077#1090#1095#1077#1088' '#1087#1088#1086#1094#1077#1089#1089#1086#1074
  Color = clBtnFace
  Constraints.MinHeight = 200
  Constraints.MinWidth = 475
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    467
    434)
  PixelsPerInch = 96
  TextHeight = 13
  object ListView1: TListView
    Left = 11
    Top = 16
    Width = 443
    Height = 363
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <
      item
        Caption = #1048#1084#1103' '#1087#1088#1086#1094#1077#1089#1089
        Width = 120
      end
      item
        Caption = 'PID'
        Width = 70
      end
      item
        AutoSize = True
        Caption = #1055#1091#1090#1100
      end>
    ReadOnly = True
    RowSelect = True
    PopupMenu = PopupMenu1
    SortType = stBoth
    TabOrder = 0
    ViewStyle = vsReport
    OnKeyDown = ListView1KeyDown
  end
  object Button1: TButton
    Left = 290
    Top = 393
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = #1054#1073#1085#1086#1074#1080#1090#1100
    TabOrder = 1
    OnClick = FormShow
  end
  object Button2: TButton
    Left = 379
    Top = 393
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = #1047#1072#1082#1088#1099#1090#1100
    TabOrder = 2
    OnClick = Button2Click
  end
  object PopupMenu1: TPopupMenu
    Left = 512
    Top = 80
    object Kill1: TMenuItem
      Caption = #1059#1073#1080#1090#1100' '#1087#1088#1086#1094#1077#1089#1089
      OnClick = Kill1Click
    end
  end
end
