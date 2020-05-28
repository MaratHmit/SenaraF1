object frmMain: TfrmMain
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'RusGuard'
  ClientHeight = 188
  ClientWidth = 257
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object btnEployesSynchro: TButton
    Left = 8
    Top = 21
    Width = 241
    Height = 44
    Caption = #1057#1080#1093#1088#1086#1085#1080#1079#1072#1094#1080#1103' '#1089#1086#1090#1088#1091#1076#1085#1080#1082#1086#1074
    TabOrder = 0
    OnClick = btnEployesSynchroClick
  end
  object Button1: TButton
    Left = 8
    Top = 80
    Width = 241
    Height = 41
    Caption = #1058#1077#1089#1090' '#1089#1077#1088#1074#1080#1089#1072
    TabOrder = 1
    OnClick = Button1Click
  end
  object btnTestTime: TButton
    Left = 8
    Top = 139
    Width = 241
    Height = 41
    Caption = #1058#1077#1089#1090' '#1074#1088#1077#1084#1077#1085#1080
    TabOrder = 2
    OnClick = btnTestTimeClick
  end
  object HTTPRIO: THTTPRIO
    OnAfterExecute = HTTPRIOAfterExecute
    OnBeforeExecute = HTTPRIOBeforeExecute
    Converter.Options = [soSendMultiRefObj, soTryAllSchema, soRootRefNodesToBody, soCacheMimeResponse, soUTF8EncodeXML]
    Left = 56
    Top = 8
  end
end
