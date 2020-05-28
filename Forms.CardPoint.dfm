object frmCardPoint: TfrmCardPoint
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1059#1088#1086#1074#1085#1080' '#1076#1086#1089#1090#1091#1087#1072' RusGuard'
  ClientHeight = 558
  ClientWidth = 319
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnShow = FormShow
  DesignSize = (
    319
    558)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 64
    Width = 108
    Height = 13
    Caption = 'Access level RusGuard'
  end
  object Label2: TLabel
    Left = 8
    Top = 8
    Width = 94
    Height = 13
    Caption = 'IP address Terminal'
  end
  object btnOk: TButton
    Left = 105
    Top = 525
    Width = 100
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 0
    ExplicitTop = 127
  end
  object btnCancel: TButton
    Left = 211
    Top = 525
    Width = 100
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 1
    ExplicitTop = 127
  end
  object edtAddress: TEdit
    Left = 8
    Top = 27
    Width = 303
    Height = 21
    TabOrder = 2
    Text = '192.168.1.100'
  end
  object cbLevels: TCheckListBox
    Left = 8
    Top = 83
    Width = 303
    Height = 390
    ItemHeight = 13
    TabOrder = 3
  end
  object cbSendLog: TCheckBox
    Left = 8
    Top = 488
    Width = 289
    Height = 17
    Caption = #1054#1090#1087#1088#1072#1074#1083#1103#1090#1100' '#1087#1088#1086#1093#1086#1076#1099
    TabOrder = 4
  end
end
