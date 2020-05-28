unit Service.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.SvcMgr,
  Storage, Vcl.ExtCtrls, Service.Handler, Consts;

type
  TSenaraAdapterF1 = class(TService)
    tmrMain: TTimer;
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure tmrMainTimer(Sender: TObject);
  private

    FHandler: THandler;
    procedure SynchronizeTerminal;

  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  SenaraAdapterF1: TSenaraAdapterF1;

implementation

{$R *.dfm}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  SenaraAdapterF1.Controller(CtrlCode);
end;

function TSenaraAdapterF1.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TSenaraAdapterF1.ServicePause(Sender: TService; var Paused: Boolean);
begin
  tmrMain.Enabled := False;
end;

procedure TSenaraAdapterF1.ServiceStart(Sender: TService; var Started: Boolean);
begin
  FHandler := THandler.Create;

  if DEBUG_MODE then
    FHandler.Debug('ServiceStart');

  FHandler.ReadConfig;
  tmrMain.Enabled := True;
end;

procedure TSenaraAdapterF1.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  if DEBUG_MODE then
    FHandler.Debug('ServiceStop');

  tmrMain.Enabled := False;

  try
    FHandler.Free
  except
  end;
end;

procedure TSenaraAdapterF1.SynchronizeTerminal;
begin
  if DEBUG_MODE then
    FHandler.Debug('SynchronizeTerminal');

  FHandler.Run;
end;

procedure TSenaraAdapterF1.tmrMainTimer(Sender: TObject);
begin
  tmrMain.Enabled := False;
  SynchronizeTerminal;
  tmrMain.Enabled := True;
end;

end.
