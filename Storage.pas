unit Storage;

interface

uses Vcl.SvcMgr, System.SysUtils, Generics.Collections, System.IniFiles,
  Winapi.Windows, ShlObj, Winapi.ShellAPI, Classes, Consts;


type


  TStorage = class(TObject)
  private
    FSynchroDateTime: TDateTime;
    FDateTimeSynchroVisits: Double;

    FEmployeeGroupName: string;

    FUrlTerminal: string;
    FLoginTerminal: string;
    FPasswordTerminal: string;

    FUrlRusGuard: string;
    FLoginRusGuard: string;
    FPasswordRusGuard: string;
    FDriverIdRusGuard: string;

    FTokenTerminal: string;

    FPathStorage: string;
    FPathFileConfig: string;
    FPathHashes: string;
    FIsCanRunSynchro: Boolean;

    FPathFileLog: string;
    FPathFileDebug: string;

    FLastVisit: Double;

    FExistUsers: TStringList;
    FExistUsersFullName: TStringList;

    // данные для подключения к БД
    FConnectionFromDB: Boolean;
    FDBServerRusGuard: string;
    FDBLoginRusGuard: string;
    FDBPasswordRusGuard: string;
    FDBNameRusGuard: string;
  private
    class procedure RegisterInstance(aInstance: TStorage);
    procedure UnRegisterInstance;
    class function FindInstance: TStorage;
    procedure InitDirProgram;
  protected
    constructor Create; virtual;
  public
    class function NewInstance: TObject; override;
    procedure BeforeDestruction; override;
    constructor GetInstance; // Точка доступа к экземпляру
    procedure ReadConfig;
    procedure SaveConfig;
    procedure SaveDateTimeSynhro;
    procedure Log(const MessageStr: string);
    procedure Debug(const MessageStr: string);
  public
    property UrlTerminal: string read FUrlTerminal write FUrlTerminal;
    property LoginTerminal: string read FLoginTerminal write FLoginTerminal;
    property PasswordTerminal: string read FPasswordTerminal write FPasswordTerminal;
    property TokenTerminal: string read FTokenTerminal write FTokenTerminal;
    property IsCanRunSynchro: Boolean read FIsCanRunSynchro write FIsCanRunSynchro;
    property UrlRusGuard: string read FUrlRusGuard write FUrlRusGuard;
    property LoginRusGuard: string read FLoginRusGuard write FLoginRusGuard;
    property PasswordRusGuard: string read FPasswordRusGuard write FPasswordRusGuard;

    property ExistUsers: TStringList read FExistUsers write FExistUsers;
    property ExistUsersFullName: TStringList read FExistUsersFullName write FExistUsersFullName;

    property PathHashes: string read FPathHashes write FPathHashes;

    property PathFileDebug: string read FPathFileDebug;
    property ConnectionFromDB: Boolean read FConnectionFromDB write FConnectionFromDB;
    property DBServerRusGuard: string read FDBServerRusGuard write FDBServerRusGuard;
    property DBLoginRusGuard: string read FDBLoginRusGuard write FDBLoginRusGuard;
    property DBPasswordRusguard: string read FDBPasswordRusGuard write FDBPasswordRusGuard;
    property DBNameRusGuard: string read FDBNameRusGuard write FDBNameRusGuard;
    property DriverIdRusGuard: string read FDriverIdRusGuard write FDBNameRusGuard;
    property LastVisit: Double read FLastVisit write FLastVisit;
    property SynchroDateTime: TDateTime read FSynchroDateTime write FSynchroDateTime;

    property EmployeeGroupName: string read FEmployeeGroupName write FEmployeeGroupName;

  end;

implementation

uses
  Contnrs;

var
  StorageList : TObjectList;

{ TStorage }

procedure TStorage.ReadConfig;
var
  IniFile: TIniFile;
begin
  if not FileExists(FPathFileConfig) then
    Exit;

  IniFile := TIniFile.Create(FPathFileConfig);
  try
    FUrlTerminal := IniFile.ReadString('Terminal', 'Url', EmptyStr);
    FLoginTerminal := IniFile.ReadString('Terminal', 'Login', EmptyStr);
    FPasswordTerminal := DecryptStr(IniFile.ReadString('Terminal', 'Password', EmptyStr), SALT);
    FUrlRusGuard := IniFile.ReadString('RusGuard', 'Url', DEF_URL_RUSGUARD);
    FLoginRusGuard := IniFile.ReadString('RusGuard', 'Login', DEF_LOGIN_RUSGUARD);
    FPasswordRusGuard := DecryptStr(IniFile.ReadString('RusGuard', 'Password', EmptyStr), SALT);
    FConnectionFromDB := IniFile.ReadBool('RusGuard', 'ConnectDB', False);
    FDBServerRusGuard := IniFile.ReadString('RusGuard', 'DBServer', DEF_DBSERVER_RUSGUARD);
    FDBLoginRusGuard := IniFile.ReadString('RusGuard', 'DBLogin', DEF_DBLOGIN_RUSGUARD);
    FDBPasswordRusGuard  := DecryptStr(IniFile.ReadString('RusGuard', 'DBPassword', EmptyStr), SALT);
    FDBNameRusGuard := IniFile.ReadString('RusGuard', 'DBName', EmptyStr);
    FDriverIdRusGuard := IniFile.ReadString('RusGuard', 'DriverId', EmptyStr);
    FEmployeeGroupName := IniFile.ReadString('RusGuard', 'EmployeeGroup', EmptyStr);
    FSynchroDateTime := IniFile.ReadDateTime('Terminal', 'SynchroDateTime', 0);

  finally
    IniFile.Free;
  end;
end;

class procedure TStorage.RegisterInstance(aInstance: TStorage);
begin
   StorageList.Add(aInstance);
end;

procedure TStorage.UnRegisterInstance;
begin
   StorageList.Extract(Self);
end;

constructor TStorage.Create;
begin
  inherited Create;
  FExistUsers := TStringList.Create;
  FExistUsers.Sorted := True;
  InitDirProgram;
end;

procedure TStorage.Debug(const MessageStr: string);
var
  F: TextFile;
begin
  AssignFile(F, FPathFileDebug);
  if FileExists(FPathFileDebug) then
    Append(F)
  else
    Rewrite(F);
  WriteLn(F, MessageStr + #13#10);
  CloseFile(F);
end;

procedure TStorage.SaveConfig;
var
  IniFile: TIniFile;
  I: Integer;
begin
  IniFile := TIniFile.Create(FPathFileConfig);
  try
    IniFile.WriteString('Terminal', 'Url', FUrlTerminal);
    IniFile.WriteString('Terminal', 'Login', FLoginTerminal);
    IniFile.WriteString('Terminal', 'Password', EncryptStr(FPasswordTerminal, SALT));
    IniFile.WriteString('RusGuard', 'Url', FUrlRusGuard);
    IniFile.WriteString('RusGuard', 'Login', FLoginRusGuard);
    IniFile.WriteString('RusGuard', 'Password', EncryptStr(FPasswordRusGuard, SALT));
    IniFile.WriteString('RusGuard', 'DBServer', FDBServerRusGuard);
    IniFile.WriteString('RusGuard', 'DBName', FDBNameRusGuard);
    IniFile.WriteString('RusGuard', 'DBLogin', FDBLoginRusGuard);
    IniFile.WriteString('RusGuard', 'DBPassword', EncryptStr(FDBPasswordRusGuard, SALT));
    IniFile.WriteString('RusGuard', 'EmployeeGroup', FEmployeeGroupName);
    IniFile.WriteBool('RusGuard', 'ConnectDB', FConnectionFromDB);
  finally
    IniFile.Free;
  end;
end;

procedure TStorage.SaveDateTimeSynhro;
var
  IniFile: TIniFile;
  I: Integer;
begin
  IniFile := TIniFile.Create(FPathFileConfig);
  try
    IniFile.WriteDateTime('Terminal', 'SynchroDateTime', FSynchroDateTime);

  finally
    IniFile.Free;
  end;
end;

class function TStorage.FindInstance: TStorage;
var
  I: integer;
begin
  Result := nil;
  for I := 0 to StorageList.Count - 1 do
    if StorageList[I].ClassType = Self then
  begin
    Result := TStorage(StorageList[I]);
    Break;
  end;
end;

class function TStorage.NewInstance: TObject;
begin
  Result := FindInstance;
  if Result = nil then
  begin
    Result := inherited NewInstance;
    TStorage(Result).Create;
    RegisterInstance(TStorage(Result));
  end;
end;

procedure TStorage.BeforeDestruction;
begin
   UnregisterInstance;
   inherited BeforeDestruction;
end;

constructor TStorage.GetInstance;
begin
   inherited Create;
end;

procedure TStorage.InitDirProgram;
var
  FileName: string;
  Path: string;
begin
  try
    Path := ExtractFileDir(ParamStr(0));
    FPathStorage := Path + '\' + DIR_CACHE;
    FPathFileConfig := FPathStorage + '\' + FILE_CONFIG;
    FPathFileLog := FPathStorage + '\' + FILE_NAME_LOG;
    FPathFileDebug := FPathStorage + '\' + FILE_NAME_DEBUG;
    FPathHashes := FPathStorage + '\' + PATH_HASHES;
    ForceDirectories(Path);
    ForceDirectories(FPathStorage);
    ForceDirectories(FPathHashes);
  except

  end;
end;

procedure TStorage.Log(const MessageStr: string);
var
  F: TextFile;
begin
  AssignFile(F, FPathFileLog);
  if FileExists(FPathFileLog) then
    Append(F)
  else
    Rewrite(F);
  WriteLn(F, FormatDateTime('hh:nn:ss dd.mm.yyyy', Now) + #13#10 + MessageStr + #13#10);
  CloseFile(F);
end;

initialization
   StorageList := TObjectList.Create(True);

finalization
   StorageList.Free;

end.
