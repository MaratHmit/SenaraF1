unit Service.Handler;

interface

uses
  Vcl.SvcMgr, Api, LNetworkService, Storage, Consts, superobject, WSSE, System.SysUtils,
  System.NetEncoding, DataModule, Uni, Soap.XSBuiltIns, System.Generics.Collections,
  DateUtils, Classes, Service.Types;

type

  TEmployee = class
    Id: Integer;
    Guid: string;
    FullName: string;
  end;

  THandler = class
  private
    FApi: TApi;
    FIsCanRunSynchro: Boolean;
    FStorage: TStorage;
    FNumRequest: Integer;
    FGuid: string;
    FDataUsersRusGuard: string;
    FDataUsersTerminal: string;
    FDataVisitsTerminal: string;
    FListEmployes: TList<TEmployee>;
    FLevelName: string;
    FLatestVisit: TDateTime;
  private
    function GetUsersFromRusGuard: Boolean;
    function GetUsersFromRusGuardDB: Boolean;
    function GetUsersFromRusGuardSOAP: Boolean;

    function GetVisitsFromTerminal: Boolean;
    procedure SetVisitsInRusGuard;
    procedure SetVisitsInRusGuardDB;

    function GetUsersFromTerminal: Boolean;
    procedure AddUsersInRusGuard;
    procedure AddUsersInRusGuardDB;
    procedure AddUsersInRusGuardSOAP;

    function GetGuid: string;
    function GetGuidNull: string;
    procedure SetUsesrInTerminal;
    procedure SetAuthForSoap(Service: IInvokable);

    procedure InitDBConnection;
    function CreateQuery(const SQL: string = ''): TUniQuery;

    function GetEmployesFromTerminal(const Page: Integer = 1): Boolean;
    procedure SetGuidsForEmployesTerminal;
    procedure SaveGuidsInTreminal;


  public
    property IsCanRunSynchro: Boolean read FIsCanRunSynchro write FIsCanRunSynchro;
    property Storage: TStorage read FStorage;
    constructor Create;
    destructor Destroy;
    procedure Run;
    procedure ReadConfig;
    procedure ApiConnect;
    procedure Debug(const MessageStr: string);
    procedure SynchroEmploees;
    procedure SynchroVisits;
    procedure CorrectTime;

  end;

implementation

{ Handler }

procedure THandler.ApiConnect;
var
  Api: TApi;
begin
  Api := TApi.Create;
  try
    Api.Auth;
  finally
    Api.Free
  end;
end;

constructor THandler.Create;
begin
  FStorage := TStorage.GetInstance;
  FApi := TApi.Create;
  FListEmployes := TList<TEmployee>.Create;
end;

function THandler.CreateQuery(const SQL: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := dmMain.conMain;
  Result.SQL.Text := SQL;
end;

procedure THandler.Debug(const MessageStr: string);
begin
  FStorage.Debug(MessageStr);
end;

destructor THandler.Destroy;
begin
  FApi.Free;
end;

function THandler.GetEmployesFromTerminal(const Page: Integer): Boolean;
var
  Data: string;
  Json: ISuperObject;
  UserId: string;
  JsonAnswer: ISuperObject;
  FullName: string;
  I: Integer;
  Employee: TEmployee;
begin
  Data := FApi.Exec('GET', API_GET_USERS, 'page=' + IntToStr(Page) + '&limit=100');
  if FApi.LastError = '' then
  begin
    Json := SO(Data);
    JsonAnswer := TSuperObject.Create;
    FDataUsersTerminal := EmptyStr;
    if (Json.O['success'] <> nil) and (Json.O['success'].A['data'] <> nil) then
    begin
      Json := Json.O['success'];
      JsonAnswer.O['users'] := SO('[]');
    end;
      if Json.A['data'].Length = 0 then
      begin
        Result := True;
        Exit;
      end;


      for I := 0 to Json.A['data'].Length - 1 do
      begin
        UserId := Json.A['data'][I].S['1c_id'];
        if UserId = 'null' then
          UserId := EmptyStr;
        if UserId <> EmptyStr then
          Continue;

        FullName := Json.A['data'][I].S['surname'] + ' ' +
          Json.A['data'][I].S['first_name'] + ' ' + Json.A['data'][I].S['middle_name'];

        Employee := TEmployee.Create;
        Employee.Id := Json.A['data'][I].I['id'];
        Employee.FullName := FullName;
        FListEmployes.Add(Employee);

      end;
      GetEmployesFromTerminal(Page + 1);
      Result := True;
  end;
end;

function THandler.GetGuid: string;
begin

  if FGuid = EmptyStr then
  begin
    FNumRequest := 0;
    FGuid := TGUID.NewGuid.ToString;
    FGuid := StringReplace(FGuid, '{', '', []);
    FGuid := StringReplace(FGuid, '}', '', []);
    FGuid := 'uuid-' + LowerCase(FGuid);
  end;
  Inc(FNumRequest);
  Result := FGuid + '-' + IntToStr(FNumRequest);
end;

function THandler.GetGuidNull: string;
begin
  Result := TGUID.Empty.ToString;
end;

function THandler.GetUsersFromRusGuard: Boolean;
begin
  if FStorage.ConnectionFromDB then
    Result := GetUsersFromRusGuardDB
  else
    Result := GetUsersFromRusGuardSOAP;
end;

function THandler.GetUsersFromRusGuardDB: Boolean;
const
  SQL_SELECT_USERS = 'SELECT * FROM Employee';
  SQL_SELECT_PHOTO = 'SELECT Photo FROM EmployeePhoto WHERE EmployeeID = :EmployeeID';
  SQL_SELECT_CARDS = 'SELECT ak.Name, ae.AcsKeyId FROM AcsKey2EmployeeAssignment ae ' +
    'INNER JOIN AcsKeys ak ON ae.AcsKeyId = ak.KeyNumber WHERE ae.EmployeeId = :EmployeeID';
var
  QueryUsers: TUniQuery;
  QueryPhoto: TUniQuery;
  QueryCards: TUniQuery;
  Json: ISuperObject;
  User: ISuperObject;
  Card: ISuperObject;
  UserIdOrigin: string;
  UserId: string;
  IndexUser: Integer;
  Photo: TArray<System.Byte>;
  FullName: string;
  CountAdd: Integer;
begin
  Result := False;
  CountAdd := 0;

  InitDBConnection;

  QueryUsers := CreateQuery(SQL_SELECT_USERS);
  QueryPhoto := CreateQuery(SQL_SELECT_PHOTO);
  QueryCards := CreateQuery(SQL_SELECT_CARDS);

  try
    try
      Json := SO;
      Json.O['users'] := SO('[]');
      QueryUsers.Open;
      while not QueryUsers.Eof do
      begin
        UserIdOrigin := QueryUsers.FieldByName('_id').AsString;
        UserIdOrigin := StringReplace(UserIdOrigin, '{', '', []);
        UserIdOrigin := StringReplace(UserIdOrigin, '}', '', []);

        UserId := ID_PREFIX_RUSGUARD + UserIdOrigin;

        FullName := Trim(QueryUsers.FieldByName('LastName').AsString) + ' ' +
            Trim(QueryUsers.FieldByName('FirstName').AsString) + ' ' + Trim(QueryUsers.FieldByName('SecondName').AsString);

        if QueryUsers.FieldByName('ModificationDateTime').AsDateTime < FStorage.SynchroDateTime then
        begin
          QueryUsers.Next;
          Continue;
        end;

        QueryPhoto.ParamByName('EmployeeID').AsString := UserIdOrigin;
        QueryPhoto.Open;
        if QueryPhoto.Eof then
        begin
          QueryUsers.Next;
          QueryPhoto.Close;
          Continue;
        end;

        User := SO;
        Photo := QueryPhoto.Fields[0].AsBytes;
        QueryPhoto.Close;

        User.S['1c_id'] := UserId;
        User.S['first_name'] := QueryUsers.FieldByName('FirstName').AsString;
        User.S['surname'] := QueryUsers.FieldByName('LastName').AsString;
        User.S['middle_name'] := QueryUsers.FieldByName('SecondName').AsString;
        User.S['company_name'] := '';
        User.S['photo'] := TNetEncoding.Base64.EncodeBytesToString(Photo);
        if QueryUsers.FieldByName('IsLocked').AsBoolean then
          User.I['blocked'] := 1
        else
          User.I['blocked'] := 0;

        QueryCards.ParamByName('EmployeeID').AsString := QueryUsers.FieldByName('_id').AsString;
        QueryCards.Open;
        if QueryCards.RecordCount > 0 then
          Json.O['cards'] := SO('[]');

        while not QueryCards.Eof do
        begin

          Card := TSuperObject.Create;
          Card.S['name'] := QueryCards.FieldByName('Name').AsString;
          Card.S['number'] := QueryCards.FieldByName('AcsKeyId').AsString;
          Json.A['cards'].Add(Card);

          QueryCards.Next
        end;
        QueryCards.Close;

        Json.A['users'].Add(User);
        Inc(CountAdd);
        if CountAdd > 49 then
          Break;

        QueryUsers.Next
      end;

      FDataUsersRusGuard := Json.AsJSon;


      Result := True;
    except
      on E: Exception do
      begin
        FStorage.Log(E.Message);
      end;
    end;

  finally
    QueryUsers.Free;
    QueryPhoto.Free;
    QueryCards.Free;
    try
      dmMain.conMain.Close;
    except

    end;
  end;
end;

function THandler.GetUsersFromRusGuardSOAP: Boolean;
var
  IdConnect: string;
  I, J: Integer;
  Service: ILNetworkService;
  Data: EmployeesInfoData22;
  Employee: AcsEmployeeFull2;
  Groups: ArrayOfAcsEmployeeGroup;
  GUIDs: ArrayOfguid;
  Photo: TArray<System.Byte>;
  CardKeys: ArrayOfAcsKeyInfo;
  Json: ISuperObject;
  User: ISuperObject;
  Card: ISuperObject;
  UserId: string;
  IndexUser: Integer;
  MDateTime: TXSDateTime;
begin
  try
    Service := GetILNetworkService(True, FStorage.UrlRusGuard);

    // подключение
    FGuid := EmptyStr;
    SetAuthForSoap(Service);
    IdConnect := Service.Connect;

    SetAuthForSoap(Service);
    Groups := Service.GetAcsEmployeeGroupsFull(False);
    SetLength(GUIDs, Length(Groups));
    for I := 0 to Length(Groups) - 1 do
      GUIDs[I] := Groups[I].ID;

    SetAuthForSoap(Service);
    Data := Service.GetAcsEmployees(0, 10000, EmployeeSortedColumn.FullName, SortOrder.Ascending,
      True, nil, True);

    if DEBUG_MODE then
      Debug('GetAcsEmployees');

    Json := SO;
    Json.O['users'] := SO('[]');
    for I := 0 to Data.Count - 1 do
    begin
      UserId := 'RusGuard-' + Data.Employees[I].ID;
      UserId := StringReplace(UserId, '{', '', []);
      UserId := StringReplace(UserId, '}', '', []);
      if not FStorage.ExistUsers.Find(UserId, IndexUser) then
        FStorage.ExistUsers.Add(UserId);

      SetAuthForSoap(Service);
      Employee := Service.GetAcsEmployee(Data.Employees[I].ID);
      MDateTime := Employee.ModificationDateTime;
      if MDateTime.AsDateTime < FStorage.SynchroDateTime then
        Continue;

      User := SO;

      SetAuthForSoap(Service);
      CardKeys := Service.GetAcsKeysForEmployee(Data.Employees[I].ID);
      SetAuthForSoap(Service);
      Photo := Service.GetAcsEmployeePhoto(Data.Employees[I].ID, 1);
      if Length(Photo) = 0 then
        Continue;

      User.S['1c_id'] := UserId;
      User.S['first_name'] := Data.Employees[I].FirstName;
      User.S['surname'] := Data.Employees[I].LastName;
      User.S['middle_name'] := Data.Employees[I].SecondName;
      User.S['company_name'] := '';
      User.S['photo'] := TNetEncoding.Base64.EncodeBytesToString(Photo);

      if Length(CardKeys) > 0 then
      begin
        Json.O['cards'] := SO('[]');
        for J := 0 to Length(CardKeys) - 1 do
        begin
          Card := TSuperObject.Create;
          Card.S['name'] := CardKeys[J].Name_;
          Card.S['number'] := IntToStr(CardKeys[J].KeyNumber);
          Json.A['cards'].Add(Card);
        end;
      end;

      Json.A['users'].Add(User);
    end;

    FDataUsersRusGuard := Json.AsJSon;

    // отключение
    SetAuthForSoap(Service);
    Service.Disconnect(IdConnect);


    Result := True;
  except
    on E: Exception do
    begin
      FStorage.Log(E.Message);
      Result := False;
    end;
  end;
end;

function THandler.GetUsersFromTerminal: Boolean;
var
  Data: string;
  I: Integer;
  Json: ISuperObject;
  UserId: string;
  JsonAnswer: ISuperObject;
  User: ISuperObject;
begin
  Result := False;

  try
    ApiConnect;
    Data := FApi.Exec('GET', API_GET_USERS, 'page=1&limit=10000');
    if FApi.LastError = '' then
    begin
      Json := SO(Data);
      JsonAnswer := TSuperObject.Create;
      FDataUsersTerminal := EmptyStr;
      if (Json.O['success'] <> nil) and (Json.O['success'].A['data'] <> nil) then
      begin
        Json := Json.O['success'];
        JsonAnswer.O['users'] := SO('[]');

        for I := 0 to Json.A['data'].Length - 1 do
        begin
          UserId := Json.A['data'][I].S['1c_id'];
          if Pos('RusGuard', UserId) = 0 then
          begin
            Data := FApi.Exec('GET', API_GET_USER + '/' + Json.A['data'][I].S['id'], EmptyStr);
            User := SO(Data);
            if User.O['success'] <> nil then
              JsonAnswer.A['users'].Add(User.O['success']);
          end;
        end;

        FDataUsersTerminal := JsonAnswer.AsJSon;
        Result := True;
      end;
      FIsCanRunSynchro := True;
    end;
  except
    on E: Exception do
      FStorage.Log(E.Message);
  end;
end;

function THandler.GetVisitsFromTerminal: Boolean;
var
  Answer: string;
  LatestVisit: string;
  FS: TFormatSettings;
  Json: ISuperObject;
begin
  Result := False;
  try
    FS.DateSeparator := '-';
    FS.TimeSeparator := ':';
    FS.ShortDateFormat := 'yyyy-mm-dd';

    LatestVisit := 'latestVisit=';
    if FLatestVisit = 0 then
      LatestVisit := LatestVisit + DateToStr(Date, FS);

    FDataVisitsTerminal := EmptyStr;

    Answer := FApi.Exec('GET', API_GET_VISITS, LatestVisit);
    if FApi.LastError = EmptyStr then
    begin
       Json := SO(Answer);
       if Json.O['success'] <> nil then
       begin
         FStorage.LastVisit := StrToDateTimeDef(Json.O['success'].S['latestVisit'],
           FStorage.LastVisit, FS);

         FDataVisitsTerminal := Json.O['success'].AsJSon;
       end;
    end;

    Result := True;
  except
    on E: Exception do
      FStorage.Log(E.Message);
  end;
end;

procedure THandler.InitDBConnection;
begin
  dmMain.conMain.Server := FStorage.DBServerRusGuard;
  dmMain.conMain.Username := FStorage.DBLoginRusGuard;
  dmMain.conMain.Password := FStorage.DBPasswordRusguard;
  dmMain.conMain.Database := FStorage.DBNameRusGuard;
end;

procedure THandler.ReadConfig;
begin
  try
    FStorage.ReadConfig;

    if DEBUG_MODE then
      Debug('ReadConfig');

  except
    on E: Exception do
      FStorage.Log(E.Message);
  end;
end;

procedure THandler.Run;
begin
  try
    ApiConnect;
    CorrectTime;
    SynchroEmploees;
    SynchroVisits;
    FStorage.SaveDateTimeSynhro;
  except
    on E: Exception do
      FStorage.Log(E.Message);
  end;
end;

procedure THandler.SaveGuidsInTreminal;
var
  I: Integer;
  User: ISuperObject;
begin
  ApiConnect;

  for I := 0 to FListEmployes.Count - 1 do
  begin
     if FListEmployes[I].Guid = EmptyStr then
       Continue;

    User := TSuperObject.Create;
    User.S['id'] := IntToStr(FListEmployes[I].Id);
    User.S['1c_id'] := FListEmployes[I].Guid;
    FApi.Exec('POST', API_UPDATE_USER + '/' + User.S['id'], User.AsJSon());
  end;

end;

procedure THandler.SetAuthForSoap(Service: IInvokable);
begin
  PrepareSoapHeader(Service, GetGuid, FStorage.LoginRusGuard, FStorage.PasswordRusGuard);
end;

procedure THandler.SetGuidsForEmployesTerminal;
const
  SQL_SELECT_USERS = 'SELECT * FROM Employee';

var
  QueryUsers: TUniQuery;
  UserIdOrigin: string;
  UserId: string;
  FullName: string;
  I: Integer;
begin
  InitDBConnection;
  QueryUsers := CreateQuery(SQL_SELECT_USERS);

  try
    try
      QueryUsers.Open;
      while not QueryUsers.Eof do
      begin
        UserIdOrigin := QueryUsers.FieldByName('_id').AsString;
        UserIdOrigin := StringReplace(UserIdOrigin, '{', '', []);
        UserIdOrigin := StringReplace(UserIdOrigin, '}', '', []);

        UserId := ID_PREFIX_RUSGUARD + UserIdOrigin;
        FullName := Trim(QueryUsers.FieldByName('LastName').AsString) + ' ' +
            Trim(QueryUsers.FieldByName('FirstName').AsString) + ' ' + Trim(QueryUsers.FieldByName('SecondName').AsString);

        for I := 0 to FListEmployes.Count - 1 do
        begin
          if FListEmployes[I].FullName = FullName then
          begin
            FListEmployes[I].Guid := UserId;
          end;
        end;
        QueryUsers.Next
      end;

    except
      on E: Exception do
      begin
        FStorage.Log(E.Message);
      end;
    end;

  finally
    QueryUsers.Free;
  end;
end;

procedure THandler.AddUsersInRusGuard;
begin
  if FStorage.ConnectionFromDB then
    AddUsersInRusGuardDB
  else
    AddUsersInRusGuardSOAP;
end;

procedure THandler.AddUsersInRusGuardDB;
begin

end;

procedure THandler.AddUsersInRusGuardSOAP;
var
  IdConnect: string;
  I, J: Integer;
  Service: ILNetworkService;
  ServiceConfig: ILNetworkConfigurationService;
  Data: AcsEmployeeSaveData2;
  Employee: AcsEmployeeFull2;
  Groups: ArrayOfAcsEmployeeGroup;
  GUIDs: ArrayOfguid;
  Photo: TArray<System.Byte>;
  CardKeys: ArrayOfAcsKeyInfo;
  Json: ISuperObject;
  User: ISuperObject;
  UserU: ISuperObject;
  Card: ISuperObject;
  UserId: string;
  IndexUser: Integer;
  MDateTime: TXSDateTime;
  IsExistGroup: Boolean;
  GroupId: string;
begin
  try
    Service := GetILNetworkService(True, FStorage.UrlRusGuard);
    ServiceConfig := GetILNetworkConfigurationService(True, FStorage.UrlRusGuard);
    ApiConnect;

    // подключение
    FGuid := EmptyStr;
    SetAuthForSoap(Service);
    IdConnect := Service.Connect;

    SetAuthForSoap(Service);
    IsExistGroup := False;
    Groups := Service.GetAcsEmployeeGroupsFull(False);

    for I := 0 to Length(Groups) - 1 do
    begin
      if Groups[I].Name_ = FStorage.EmployeeGroupName then
      begin
        IsExistGroup := True;
        GroupId := Groups[I].ID;
        Break
      end;
    end;

    if not IsExistGroup then
      Exit;

    Json := SO(FDataUsersTerminal);
    if Json.A['users'] <> nil then
    begin
      for I := 0 to Json.A['users'].Length - 1 do
      begin
        User := Json.A['users'][I];
        Data := AcsEmployeeSaveData2.Create;

        Data.FirstName := User.S['first_name'];
        Data.LastName := User.S['surname'];
        Data.SecondName := User.S['middle_name'];

        UserU := SO;

        SetAuthForSoap(ServiceConfig);
        UserU.S['1c_id'] := ID_PREFIX_RUSGUARD + ServiceConfig.AddAcsEmployee(GroupId, Data).ID;
        FApi.Exec('POST', API_UPDATE_USER + '/' + User.S['id'], UserU.AsJSon);

      end;

    end;

    FDataUsersTerminal := EmptyStr;

    // отключение
    SetAuthForSoap(Service);
    Service.Disconnect(IdConnect);

  except
    on E: Exception do
      FStorage.Log(E.Message);
  end;
end;

procedure THandler.SetUsesrInTerminal;
var
  I: Integer;
  Json: ISuperOBject;
  Users: TSuperArray;
  User: ISuperOBject;
  UserR: ISuperOBject;
  Answer: string;
begin
  if (FDataUsersRusGuard = EmptyStr) then
    Exit;

  try
    Json := SO(FDataUsersRusGuard);
    if (Json.A['users'] = nil) or (Json.A['users'].Length = 0) then
      Exit;

  except
    on E: Exception do
    begin
      FStorage.Log(E.Message);
      Exit;
    end;
  end;


  try

    ApiConnect;
    for I := 0 to Json.A['users'].Length - 1 do
    begin
      User := Json.A['users'][I];
      Answer := FApi.Exec('POST', API_ADD_USER, User.AsJSon());
      if FApi.LastError = EmptyStr then
      begin
        UserR := SO(Answer);
        if (UserR.O['success'] <> nil) and (UserR.O['success'].I['id'] > 0) then
        begin
          FStorage.ExistUsers.Add(User.S['1c_id']);
        end;
      end;
    end;

  except
    on E: Exception do
      FStorage.Log(E.Message);
  end;
end;

procedure THandler.SetVisitsInRusGuard;
begin

end;

procedure THandler.SetVisitsInRusGuardDB;
const
  SQL_MAX = 'SELECT MAX(DateTime) FROM Log';
  SQL_INSERT = 'INSERT INTO Log ' +
    '(DateTime, LogMessageType, LogMessageSubType, Message, Details, DriverID, ' +
    'EmployeeID) ' +
    'VALUES ' +
    '(:DateTime, :LogMessageType, :LogMessageSubType, :Message, :Details, :DriverID, ' +
    ':EmployeeID)' ;
  SQL_EXIST = 'SELECT _id FROM Log WHERE DateTime = :DateTime AND EmployeeID = :EmployeeID';
var
  I: Integer;
  Json: ISuperObject;
  Query: TUniQuery;
  QueryMax: TUniQuery;
  QueryExist: TUniQuery;
  Visit: ISuperObject;
  FS: TFormatSettings;
  MaxDateTime: TDateTime;
  VisitDateTime: TDateTime;
begin
  FS.DateSeparator := '-';
  FS.TimeSeparator := ':';
  FS.ShortDateFormat := 'yyyy-mm-dd hh:nn:ss';

  InitDBConnection;
  Query := CreateQuery(SQL_INSERT);
  QueryMax := CreateQuery(SQL_MAX);
  QueryExist := CreateQuery(SQL_EXIST);

  try
    try
      QueryMAx.Open;
      MaxDateTime := QueryMax.Fields[0].AsDateTime;

      Json := SO(FDataVisitsTerminal);
      if Json.A['visits'] = nil then
        Exit;

      for I := 0 to Json.A['visits'].Length - 1 do
      begin
        Visit := Json.A['visits'][I];
        VisitDateTime := StrToDateTimeDef(Visit.S['created_at'], Now, FS);
        if VisitDateTime < MaxDateTime then
          Continue;

        if Visit.S['1c_id'] = 'null' then
          Visit.S['1c_id'] := EmptyStr;
        if Visit.S['1c_id'] = EmptyStr then
          Continue;

        QueryExist.Close;
        QueryExist.ParamByName('DateTime').AsDateTime := VisitDateTime;
        QueryExist.ParamByName('EmployeeID').AsString := StringReplace(Visit.S['1c_id'],
            ID_PREFIX_RUSGUARD, '', []);
        QueryExist.Open;
        if QueryExist.RecordCount > 0 then
          Continue;

        Query.ParamByName('DateTime').AsDateTime :=
          StrToDateTimeDef(Visit.S['created_at'], Now, FS);
        Query.ParamByName('LogMessageType').AsInteger := DEF_LOG_MESSAGE_TYPE;
        if Visit.S['device_name'] = ': Вход' then
          Query.ParamByName('LogMessageSubType').AsInteger := DEF_LOG_MESSAGE_SUBTYPE_ENTER
        else
          Query.ParamByName('LogMessageSubType').AsInteger := DEF_LOG_MESSAGE_SUBTYPE_EXIT;
        Query.ParamByName('Message').AsString := StringReplace(Visit.S['device_name'], ': ', '', []);

        // временно
        Query.ParamByName('Details').AsString := 'Биометрия: ' +
        Visit.S['full_name'];
        if Visit.S['1c_id'] <> EmptyStr then
          Query.ParamByName('EmployeeID').AsString := StringReplace(Visit.S['1c_id'],
            ID_PREFIX_RUSGUARD, '', []);
         Query.ParamByName('DriverId').AsString := FStorage.DriverIdRusGuard;

        Query.Execute;
      end;

    except
      on E: Exception do
        FStorage.Log(E.Message);
    end;

  finally
    Query.Free;
    QueryMax.Free;
    QueryExist.Free;
  end;

end;

procedure THandler.SynchroEmploees;
const
  SQL_SELECT_PHOTO = 'SELECT Photo FROM EmployeePhoto WHERE EmployeeID = :EmployeeID';
  SQL_SELECT_CARDS = 'SELECT ak.Name, ae.AcsKeyId, ak.StartDate, ak.EndDate FROM AcsKey2EmployeeAssignment ae ' +
    'INNER JOIN AcsKeys ak ON ae.AcsKeyId = ak.KeyNumber WHERE ae.EmployeeId = :EmployeeID';
  SQL_UPDTAE = 'UPDATE Employee SET ExtId1 = :ExtId WHERE _id = :Id';
var
  QueryEmploees: TUniQuery;
  QueryPhoto: TUniQuery;
  QueryCards: TUniQuery;
  QueryUpdate: TUniQuery;
  User: ISuperObject;
  Card: ISuperObject;
  UserIdOrigin: string;
  UserId: string;
  Photo: TArray<System.Byte>;
  Answer: string;
  CountCards: Integer;
  StartDateAsc: TDate;
  EndDateAsc: TDate;
  IsRemoved: Boolean;
  IsBlocked: Boolean;
  ExtId: Integer;
  IsStorePhoto: Boolean;
  FileHash: string;
  FileStream: TFileStream;
  IsStoreSuccess: Boolean;
  PhotoS: string;
  IsNew: Boolean;
begin
  QueryEmploees := TUniQuery.Create(nil);
  QueryEmploees.Connection := dmMain.conMain;
  QueryPhoto := CreateQuery(SQL_SELECT_PHOTO);
  QueryCards := CreateQuery(SQL_SELECT_CARDS);
  QueryUpdate := CreateQuery(SQL_UPDTAE);
  try
    try
      QueryEmploees.SQL.Text := 'SELECT e.* FROM Employee e ' +
        'LEFT JOIN AcsKey2EmployeeAssignment k ON e._id = k.EmployeeId ' +
        'INNER JOIN EmployeePhoto p ON e._id = p.EmployeeID ' +
        'WHERE (e.ModificationDateTime > :dtSynchro OR k.AssignmentModificationDateTime > :dtSynchro) ' +
        'AND IsSynchro = 1';

      QueryEmploees.ParamByName('dtSynchro').AsDateTime := FStorage.SynchroDateTime;
      QueryEmploees.Open;
      while not QueryEmploees.Eof do
      begin
        IsBlocked := False;
        UserIdOrigin := QueryEmploees.FieldByName('_id').AsString;
        UserIdOrigin := StringReplace(UserIdOrigin, '{', '', []);
        UserIdOrigin := StringReplace(UserIdOrigin, '}', '', []);

        UserId := ID_PREFIX_RUSGUARD + UserIdOrigin;

        QueryPhoto.ParamByName('EmployeeID').AsString := UserIdOrigin;
        QueryPhoto.Open;
        if QueryPhoto.Eof then
        begin
          QueryEmploees.Next;
          QueryPhoto.Close;
          Continue;
        end;

        User := SO;
        IsNew := True;
        ExtId := 0;
        if not QueryEmploees.FieldByName('ExtId1').IsNull then
        begin
          ExtId := QueryEmploees.FieldByName('ExtId1').AsInteger;
          IsNew := False;
        end;

        Photo := QueryPhoto.Fields[0].AsBytes;

        User.S['1c_id'] := UserId;
        User.S['first_name'] := QueryEmploees.FieldByName('FirstName').AsString;
        User.S['surname'] := QueryEmploees.FieldByName('LastName').AsString;
        User.S['middle_name'] := QueryEmploees.FieldByName('SecondName').AsString;
        User.S['company_name'] := '';

        PhotoS := EmptyStr;
        IsStorePhoto := False;
        if Length(Photo) > 0 then
        begin
          PhotoS := UserId + '-' + QueryPhoto.Fields[0].AsString;
          FileHash := md5(PhotoS);
          FileHash := FStorage.PathHashes + '\' + FileHash;
          if not FileExists(FileHash) or IsNew then
          begin
            User.S['photo'] := TNetEncoding.Base64.EncodeBytesToString(Photo);
            IsStorePhoto := True;
          end;
        end;

        QueryPhoto.Close;

        if QueryEmploees.FieldByName('IsLocked').AsBoolean or QueryEmploees.FieldByName('IsRemoved').AsBoolean then
          IsBlocked := True;

        IsRemoved := QueryEmploees.FieldByName('IsRemoved').AsBoolean;

        CountCards := 0;
        QueryCards.ParamByName('EmployeeID').AsString := QueryEmploees.FieldByName('_id').AsString;
        QueryCards.Open;
        if QueryCards.RecordCount > 0 then
          User.O['cards'] := SO('[]');

        while not QueryCards.Eof do
        begin
          StartDateAsc := Date;
          EndDateAsc := Date;
          if not QueryCards.FieldByName('StartDate').IsNull then
            StartDateAsc := QueryCards.FieldByName('StartDate').AsDateTime;
          if not QueryCards.FieldByName('EndDate').IsNull then
            EndDateAsc := QueryCards.FieldByName('EndDate').AsDateTime;

          if (Date >= StartDateAsc) and (Date <= EndDateAsc) or not IS_CHECKED_DATE_CARDS then
          begin
            Card := TSuperObject.Create;
            Card.S['name'] := QueryCards.FieldByName('Name').AsString;
            Card.S['number'] := QueryCards.FieldByName('AcsKeyId').AsString;
            User.A['cards'].Add(Card);
            Inc(CountCards);
          end;

          QueryCards.Next
        end;
        QueryCards.Close;

        if IsRemoved then
        begin
          if FileExists(FileHash) then
            DeleteFile(FileHash);
        end;
        User.I['blocked'] := 0;
        if IsBlocked then
          User.I['blocked'] := 1;

        if IsNew and (IsRemoved or IsBlocked) then
        begin
          Continue;
          QueryEmploees.Next;
          QueryPhoto.Close;
        end;

        IsStoreSuccess := False;
        if ExtId > 0 then
        begin
          Answer := FApi.Exec('POST', API_UPDATE_USER + '/' + IntToStr(ExtId), User.AsJSon);
          if IsRemoved then
            FApi.Exec('DELETE', API_UPDATE_USER + '/' + IntToStr(ExtId), EmptyStr);
          if FApi.LastError = EmptyStr then
            IsStoreSuccess := True;
        end;

        if not IsStoreSuccess and not IsRemoved then
        begin
          if (ExtId > 0) and not IsStorePhoto then
          begin
            User.S['photo'] := TNetEncoding.Base64.EncodeBytesToString(Photo);
            IsStorePhoto := True;
          end;
          Answer := FApi.Exec('POST', API_ADD_USER, User.AsJSon);
          if FApi.LastError = EmptyStr then
          begin
            User := SO(Answer);
            QueryUpdate.ParamByName('ExtId').AsInteger := User.O['success'].I['id'];
            QueryUpdate.ParamByName('Id').AsString := UserIdOrigin;
            QueryUpdate.ExecSQL;
            FStorage.SynchroDateTime := Now;
            IsStoreSuccess := True;
          end;
        end;

        if IsStoreSuccess then
        begin
          if QueryEmploees.FieldByName('ModificationDateTime').AsDateTime > FStorage.SynchroDateTime then
            FStorage.SynchroDateTime := QueryEmploees.FieldByName('ModificationDateTime').AsDateTime;
          if IsStorePhoto then
          begin
            try
              try
                FileStream := TFileStream.Create(FileHash, fmCreate);
              except
              end;
            finally
              FileStream.Free;
            end;
          end;
        end;

        if IsStorePhoto then
          Sleep(200);

        QueryEmploees.Next

      end;
    except

    end;
  finally
    QueryEmploees.Free;
    QueryPhoto.Free;
    QueryCards.Free;
    QueryUpdate.Free;
  end;

end;

procedure THandler.SynchroVisits;
const
  SQL_MAX = 'SELECT MAX(DateTime) FROM Log';
  SQL_INSERT = 'INSERT INTO Log ' +
    '(DateTime, LogMessageType, LogMessageSubType, Message, Details, DriverID, ' +
    'EmployeeID, ExtId1) ' +
    'VALUES ' +
    '(:DateTime, :LogMessageType, :LogMessageSubType, :Message, :Details, :DriverID, ' +
    ':EmployeeID, :ExtId1)' ;
  SQL_EXIST = 'SELECT _id FROM Log WHERE ExtId1 = :ExtId';
var
  I: Integer;
  VisitId: Integer;
  Json: ISuperObject;
  Query: TUniQuery;
  QueryMax: TUniQuery;
  QueryExist: TUniQuery;
  Visit: ISuperObject;
  FS: TFormatSettings;
  MaxDateTime: TDateTime;
  VisitDateTime: TDateTime;
begin
  GetVisitsFromTerminal;

  FS.DateSeparator := '-';
  FS.TimeSeparator := ':';
  FS.ShortDateFormat := 'yyyy-mm-dd hh:nn:ss';

  InitDBConnection;
  Query := CreateQuery(SQL_INSERT);
  QueryMax := CreateQuery(SQL_MAX);
  QueryExist := CreateQuery(SQL_EXIST);

  try
    try
      QueryMax.Open;
      MaxDateTime := QueryMax.Fields[0].AsDateTime;

      Json := SO(FDataVisitsTerminal);
      if Json.A['visits'] = nil then
        Exit;

      for I := 0 to Json.A['visits'].Length - 1 do
      begin
        Visit := Json.A['visits'][I];
        VisitId := Visit.I['id'];
        if VisitId = 0 then
          Continue;
        VisitDateTime := StrToDateTimeDef(Visit.S['created_at'], Now, FS);

        if Visit.S['1c_id'] = 'null' then
          Visit.S['1c_id'] := EmptyStr;
        if Visit.S['1c_id'] = EmptyStr then
          Continue;

        QueryExist.Close;
        QueryExist.ParamByName('ExtId').AsInteger := VisitId;
        QueryExist.Open;
        if QueryExist.RecordCount > 0 then
          Continue;

        Query.ParamByName('DateTime').AsDateTime :=
          StrToDateTimeDef(Visit.S['created_at'], Now, FS);
        Query.ParamByName('LogMessageType').AsInteger := DEF_LOG_MESSAGE_TYPE;
        if Visit.S['device_name'] = ': Вход' then
          Query.ParamByName('LogMessageSubType').AsInteger := DEF_LOG_MESSAGE_SUBTYPE_ENTER
        else
          Query.ParamByName('LogMessageSubType').AsInteger := DEF_LOG_MESSAGE_SUBTYPE_EXIT;
        Query.ParamByName('Message').AsString := StringReplace(Visit.S['device_name'], ': ', '', []);

        // временно
        Query.ParamByName('Details').AsString := 'СРЛ O.Vision - 1 этаж';
        if Visit.S['1c_id'] <> EmptyStr then
          Query.ParamByName('EmployeeID').AsString := StringReplace(Visit.S['1c_id'],
            ID_PREFIX_RUSGUARD, '', []);
        Query.ParamByName('DriverId').AsString := FStorage.DriverIdRusGuard;
        Query.ParamByName('ExtId1').AsInteger := VisitId;

        Query.Execute;
      end;

    except
      on E: Exception do
        FStorage.Log(E.Message);
    end;

  finally
    Query.Free;
    QueryMax.Free;
    QueryExist.Free;
  end;

end;

procedure THandler.CorrectTime;
var
  Answer: string;
  ResultT: ISuperObject;
  CurTimestamp: Int64;
  ResTimestamp: Int64;
begin
  try
    Answer := FApi.Exec('GET', API_CHECKTIME, EmptyStr);
    if FApi.LastError = EmptyStr then
    begin
      ResultT := SO(Answer);
      if ResultT.S['timestamp'] <> EmptyStr then
      begin
        CurTimestamp := DateTimeToUnix(Now, False);
        ResTimestamp := StrToUInt64Def(ResultT.S['timestamp'], 0);
        if Abs(CurTimestamp - ResTimestamp) > 1 then
        begin
          ResultT.S['timestamp'] := IntToStr(CurTimestamp);
          FApi.Exec('POST', API_CORRECTTIME, ResultT.AsJSon);
        end;
     end;
    end;

  except

  end;
end;

end.
