object AboutForm: TAboutForm
  Left = 338
  Top = 351
  BorderStyle = bsDialog
  Caption = #1054' '#1087#1088#1086#1075#1088#1072#1084#1084#1077
  ClientHeight = 252
  ClientWidth = 281
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 16
    Top = 16
    Width = 32
    Height = 32
  end
  object Label1: TLabel
    Left = 56
    Top = 16
    Width = 102
    Height = 13
    Caption = 'Autorun Remover Pro'
  end
  object Label2: TLabel
    Left = 56
    Top = 33
    Width = 96
    Height = 13
    Caption = 'ver 6.4 (26.04.2009)'
  end
  object Button1: TButton
    Left = 190
    Top = 216
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 0
    OnClick = Button1Click
  end
  object Panel1: TPanel
    Left = 16
    Top = 56
    Width = 249
    Height = 153
    BevelInner = bvLowered
    TabOrder = 1
    object JvScrollText1: TJvScrollText
      Left = 10
      Top = 2
      Width = 226
      Height = 149
      Alignment = taCenter
      Items.Strings = (
        'Autorun Remover Pro'
        'Version 6.4'
        'Created by Olim Saidov aka zax'
        'http://zax.ucoz.com'
        'zax_mail@mail.ru'
        ''
        
          'If you find any bugs or have suggestions and offers feel free to' +
          ' contact my e-mail shown above. Any comments are welcome.'
        ''
        'Special thanks to:'
        ''
        'Umed Qodirov aka Predator'
        ''
        'and others'
        'who helped me to develop this program.'
        ''
        'Credits:'
        ''
        'Ejection code based upon C code by Uwe_Sieber'
        'http://www.codeproject.com'
        '/system/RemoveDriveByLetter.asp'
        ''
        'JEDI Code Library'
        'http://sourceforge.net/projects/jcl'
        ''
        'JEDI Setup and Config Manager API'
        'http://www.delphi-jedi.org/'
        ''
        'PNG ImageList by Martijn Saly'
        'http://www.thany.org/pngcomponents')
      Active = True
      Delay = 10
      BackgroundColor = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      Align = alCustom
      WordWrap = True
    end
  end
end
