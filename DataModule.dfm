object dmMain: TdmMain
  OldCreateOrder = False
  Height = 150
  Width = 215
  object conMain: TUniConnection
    ProviderName = 'SQL Server'
    Database = 'RusGuardDB'
    Username = 'sa'
    Server = 'DESKTOP-BELD6L9\SQLEXPRESS'
    LoginPrompt = False
    Left = 32
    Top = 16
    EncryptedPassword = 'B2FF8FFFC7FFCEFFC6FFCBFF9BFFC6FF85FF'
  end
  object provSQL: TSQLServerUniProvider
    Left = 120
    Top = 16
  end
end
