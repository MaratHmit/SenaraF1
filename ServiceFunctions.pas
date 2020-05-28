unit ServiceFunctions;

interface
uses
  SvcMgr, Forms, SysUtils, Windows, Types, WinSvc;

  function CreateNTService(ExecutablePath, ServiceName: string): boolean;
  function DeleteNTService(ServiceName: string): boolean;
  function StartService(const ServiceName: string): Boolean;
  function StopService(const ServiceName: string): Boolean;

implementation

function CreateNTService(ExecutablePath, ServiceName: string): boolean;
var
  hNewService, hSCMgr: SC_HANDLE;
  FuncRetVal: Boolean;
begin
  FuncRetVal := False;
  hSCMgr := OpenSCManager(nil, nil, SC_MANAGER_CREATE_SERVICE);
  if (hSCMgr <> 0) then begin
    hNewService := CreateService(hSCMgr, PChar(ServiceName), PChar(ServiceName),
      STANDARD_RIGHTS_REQUIRED, SERVICE_WIN32_OWN_PROCESS,
      SERVICE_DEMAND_START, SERVICE_ERROR_NORMAL,
      PChar(ExecutablePath), nil, nil, nil, nil, nil);
    CloseServiceHandle(hSCMgr);
    if (hNewService <> 0) then
      FuncRetVal := true
    else
      FuncRetVal := false;
  end;
  CreateNTService := FuncRetVal;
end;

function DeleteNTService(ServiceName: string): boolean;
var
  hServiceToDelete, hSCMgr: SC_HANDLE;
  RetVal: LongBool;
  FunctRetVal: Boolean;
begin
  FunctRetVal := false;
  hSCMgr := OpenSCManager(nil, nil, SC_MANAGER_CREATE_SERVICE);
  if (hSCMgr <> 0) then begin
    hServiceToDelete := OpenService(hSCMgr, PChar(ServiceName),
      SERVICE_ALL_ACCESS);
    RetVal := DeleteService(hServiceToDelete);
    CloseServiceHandle(hSCMgr);
    FunctRetVal := RetVal;
  end;
  DeleteNTService := FunctRetVal;
end;

function StartService(const ServiceName: string): Boolean;
var
  schService,
    schSCManager: Dword;
  p: PChar;
begin
  p := nil;
  schSCManager := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if schSCManager = 0 then
    RaiseLastWin32Error;
  try
    schService := OpenService(schSCManager, PChar(ServiceName),
      SERVICE_ALL_ACCESS);
    if schService = 0 then
      RaiseLastWin32Error;
    try
      if not Winsvc.startService(schService, 0, p) then
        RaiseLastWin32Error;
    finally
      CloseServiceHandle(schService);
    end;
  finally
    CloseServiceHandle(schSCManager);
  end;
end;

function StopService(const ServiceName: string): Boolean;
var
  schService,
    schSCManager: DWORD;
  p: PChar;
  ss: _SERVICE_STATUS;
begin
  p := nil;
  schSCManager := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if schSCManager = 0 then
    RaiseLastWin32Error;
  try
    schService := OpenService(schSCManager, PChar(ServiceName),
      SERVICE_ALL_ACCESS);
    if schService = 0 then
      RaiseLastWin32Error;
    try
      if not ControlService(schService, SERVICE_CONTROL_STOP, SS) then
        RaiseLastWin32Error;
    finally
      CloseServiceHandle(schService);
    end;
  finally
    CloseServiceHandle(schSCManager);
  end;
end;

end.
