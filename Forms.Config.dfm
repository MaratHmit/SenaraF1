object frmSettings: TfrmSettings
  Left = 0
  Top = 0
  ActiveControl = btnTestVisits
  BorderStyle = bsDialog
  Caption = #1048#1085#1090#1077#1075#1088#1072#1094#1080#1103' Senara - 1 '#1101#1090#1072#1078
  ClientHeight = 350
  ClientWidth = 508
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    508
    350)
  PixelsPerInch = 96
  TextHeight = 13
  object btnOk: TButton
    Left = 190
    Top = 317
    Width = 100
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'OK'
    TabOrder = 0
    OnClick = btnOkClick
    ExplicitLeft = 340
  end
  object btnCancel: TButton
    Left = 296
    Top = 317
    Width = 100
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 1
    OnClick = btnCancelClick
    ExplicitLeft = 446
  end
  object pgMain: TPageControl
    Left = 0
    Top = 0
    Width = 508
    Height = 305
    ActivePage = tsTests
    Align = alTop
    TabOrder = 2
    ExplicitWidth = 658
    object tsRusGuard: TTabSheet
      Caption = 'RusGuard '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1077
      ExplicitWidth = 650
      object pnlRusGuard: TPanel
        Left = 0
        Top = 0
        Width = 500
        Height = 277
        Align = alClient
        BevelOuter = bvNone
        Caption = 'pnlRusGuard'
        ParentBackground = False
        ShowCaption = False
        TabOrder = 0
        ExplicitWidth = 650
        object Label2: TLabel
          Left = 16
          Top = 11
          Width = 99
          Height = 13
          Caption = 'URL SOAP RusGuard'
        end
        object Label1: TLabel
          Left = 16
          Top = 59
          Width = 93
          Height = 13
          Caption = #1048#1084#1103' '#1087#1086#1083#1100#1079#1086#1074#1072#1090#1077#1083#1103
        end
        object Label3: TLabel
          Left = 184
          Top = 59
          Width = 37
          Height = 13
          Caption = #1055#1072#1088#1086#1083#1100
        end
        object Label7: TLabel
          Left = 16
          Top = 110
          Width = 54
          Height = 13
          Caption = #1057#1077#1088#1074#1077#1088' '#1041#1044
        end
        object Label8: TLabel
          Left = 16
          Top = 158
          Width = 90
          Height = 13
          Caption = #1053#1072#1080#1084#1077#1085#1086#1074#1072#1085#1080#1077' '#1041#1044
        end
        object Label9: TLabel
          Left = 16
          Top = 203
          Width = 93
          Height = 13
          Caption = #1048#1084#1103' '#1087#1086#1083#1100#1079#1086#1074#1072#1090#1077#1083#1103
        end
        object Label10: TLabel
          Left = 184
          Top = 203
          Width = 37
          Height = 13
          Caption = #1055#1072#1088#1086#1083#1100
        end
        object edtURLRusGuard: TEdit
          Left = 16
          Top = 30
          Width = 321
          Height = 21
          TabOrder = 0
        end
        object edtLoginRusGuard: TEdit
          Left = 16
          Top = 78
          Width = 162
          Height = 21
          TabOrder = 1
        end
        object edtPasswordRusGuard: TEdit
          Left = 184
          Top = 78
          Width = 153
          Height = 21
          PasswordChar = '*'
          TabOrder = 2
        end
        object btnTestRusGuard: TButton
          Left = 352
          Top = 28
          Width = 125
          Height = 25
          Caption = #1058#1077#1089#1090' '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1103
          TabOrder = 3
          OnClick = btnTestRusGuardClick
        end
        object edtDBServer: TEdit
          Left = 16
          Top = 129
          Width = 321
          Height = 21
          TabOrder = 4
        end
        object edtDBName: TEdit
          Left = 16
          Top = 177
          Width = 321
          Height = 21
          TabOrder = 5
        end
        object edtDBLogin: TEdit
          Left = 16
          Top = 222
          Width = 162
          Height = 21
          TabOrder = 6
        end
        object edtDBPassword: TEdit
          Left = 184
          Top = 222
          Width = 153
          Height = 21
          PasswordChar = '*'
          TabOrder = 7
        end
        object cbConnectDB: TCheckBox
          Left = 16
          Top = 255
          Width = 321
          Height = 17
          Caption = #1055#1086#1076#1082#1083#1102#1095#1077#1085#1080#1077' '#1095#1077#1088#1077#1079' '#1041#1044
          TabOrder = 8
        end
      end
    end
    object tsTerminal: TTabSheet
      Caption = 'Terminal '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1077
      ImageIndex = 1
      ExplicitWidth = 650
      object pnlTerminal: TPanel
        Left = 0
        Top = 0
        Width = 500
        Height = 277
        Align = alClient
        BevelOuter = bvNone
        ParentBackground = False
        ShowCaption = False
        TabOrder = 0
        ExplicitWidth = 650
        object Label5: TLabel
          Left = 10
          Top = 62
          Width = 93
          Height = 13
          Caption = #1048#1084#1103' '#1087#1086#1083#1100#1079#1086#1074#1072#1090#1077#1083#1103
        end
        object Label6: TLabel
          Left = 12
          Top = 116
          Width = 37
          Height = 13
          Caption = #1055#1072#1088#1086#1083#1100
        end
        object Label4: TLabel
          Left = 10
          Top = 14
          Width = 62
          Height = 13
          Caption = 'URL Terminal'
        end
        object edtLoginTerminal: TEdit
          Left = 10
          Top = 81
          Width = 273
          Height = 21
          TabOrder = 0
        end
        object edtPasswordTerminal: TEdit
          Left = 12
          Top = 135
          Width = 271
          Height = 21
          PasswordChar = '*'
          TabOrder = 1
        end
        object edtUrlTerminal: TEdit
          Left = 10
          Top = 33
          Width = 273
          Height = 21
          TabOrder = 2
        end
      end
    end
    object tsRusGuardImport: TTabSheet
      Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080' '#1080#1085#1090#1077#1075#1088#1072#1094#1080#1080
      ImageIndex = 2
      ExplicitWidth = 650
      object Panel1: TPanel
        Left = 0
        Top = 0
        Width = 500
        Height = 277
        Align = alClient
        ParentBackground = False
        ShowCaption = False
        TabOrder = 0
        ExplicitWidth = 650
        object Label11: TLabel
          Left = 8
          Top = 19
          Width = 105
          Height = 13
          Caption = #1043#1088#1091#1087#1087#1072' '#1089#1086#1090#1088#1091#1076#1085#1080#1082#1086#1074
        end
        object edtEmployeeGroup: TEdit
          Left = 8
          Top = 38
          Width = 321
          Height = 21
          TabOrder = 0
        end
      end
    end
    object tsTests: TTabSheet
      Caption = #1058#1077#1089#1090#1080#1088#1086#1074#1072#1085#1080#1077
      ImageIndex = 3
      ExplicitWidth = 650
      object Panel2: TPanel
        Left = 0
        Top = 0
        Width = 500
        Height = 277
        Align = alClient
        BevelOuter = bvNone
        Caption = 'pnlRusGuard'
        ParentBackground = False
        ShowCaption = False
        TabOrder = 0
        ExplicitWidth = 650
        object btnTestVisits: TButton
          Left = 8
          Top = 60
          Width = 249
          Height = 25
          Caption = #1057#1080#1085#1093#1088#1086#1085#1080#1079#1072#1094#1080#1103' '#1087#1088#1086#1093#1086#1076#1086#1074
          TabOrder = 0
          OnClick = btnTestVisitsClick
        end
        object btnTestEmployes: TButton
          Left = 8
          Top = 20
          Width = 249
          Height = 25
          Caption = #1057#1080#1085#1093#1088#1086#1085#1080#1079#1072#1094#1080#1103' '#1089#1086#1090#1088#1091#1076#1085#1080#1082#1086#1074
          TabOrder = 1
          OnClick = btnTestEmployesClick
        end
        object btnTestAll: TButton
          Left = 8
          Top = 100
          Width = 249
          Height = 25
          Caption = #1055#1086#1083#1085#1072#1103' '#1089#1080#1085#1093#1088#1086#1085#1080#1079#1072#1094#1080#1103
          TabOrder = 2
          OnClick = btnTestAllClick
        end
      end
    end
  end
  object btnSave: TButton
    Left = 400
    Top = 317
    Width = 100
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100
    TabOrder = 3
    OnClick = btnSaveClick
    ExplicitLeft = 550
  end
end
