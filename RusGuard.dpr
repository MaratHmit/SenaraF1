program RusGuard;

uses
  Vcl.Forms,
  LNetworkService in 'LNetworkService.pas',
  Consts in 'Consts.pas',
  WSSE in 'WSSE.pas',
  Api in 'Api.pas',
  superobject in 'JSON\superobject.pas',
  Storage in 'Storage.pas',
  Forms.Config in 'Forms.Config.pas' {frmSettings},
  ServiceFunctions in 'ServiceFunctions.pas',
  Service.Handler in 'Service.Handler.pas',
  DataModule in 'DataModule.pas' {dmMain: TDataModule},
  Forms.CardPoint in 'Forms.CardPoint.pas' {frmCardPoint};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
//  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TdmMain, dmMain);
  Application.CreateForm(TfrmSettings, frmSettings);
  Application.CreateForm(TfrmCardPoint, frmCardPoint);
  Application.Run;
end.
