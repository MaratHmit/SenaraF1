unit Forms.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, LNetworkService, Vcl.StdCtrls,
  Soap.InvokeRegistry, System.Net.URLClient, Soap.Rio, Soap.SOAPHTTPClient,
  Soap.XSBuiltIns, XMLIntf, XMLDoc, WSSE, REST.Types, Data.Bind.Components, System.NetEncoding,
  Data.Bind.ObjectScope, REST.Client, Api, Storage, SuperObject, Service.Handler;

type
  TfrmMain = class(TForm)
    btnEployesSynchro: TButton;
    HTTPRIO: THTTPRIO;
    Button1: TButton;
    btnTestTime: TButton;
    procedure HTTPRIOBeforeExecute(const MethodName: string;
      SOAPRequest: TStream);
    procedure btnTestClick(Sender: TObject);
    procedure HTTPRIOAfterExecute(const MethodName: string;
      SOAPResponse: TStream);
    procedure FormCreate(Sender: TObject);

    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure btnEployesSynchroClick(Sender: TObject);
    procedure btnTestTimeClick(Sender: TObject);
  private
    FHandler: THandler;
    FStorage: TStorage;
    FNumRequest: Integer;
    FGuid: string;
    function GetGuid: string;
    procedure ApiConnect;
    procedure SetParameters;
    procedure SaveUser(const User: AcsEmployeeInfo2; Photo: TArray<System.Byte>;
      CardKeys: ArrayOfAcsKeyInfo);
    function GetBase64Photo(Photo: TArray<System.Byte>): string;
    procedure GetVisits;

  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.ApiConnect;
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

procedure TfrmMain.btnEployesSynchroClick(Sender: TObject);
begin
  FHandler.ReadConfig;
  FHandler.SynchroEmploees;
end;

procedure TfrmMain.btnTestClick(Sender: TObject);
const
  SQL_SELECT = 'SELECT * FROM Employee';
var
  I: Integer;
  Service: ILNetworkService;
  Data: EmployeesInfoData22;
  Groups: ArrayOfAcsEmployeeGroup;
  GUIDs: ArrayOfguid;
  IdConnect: string;
  Photo: TArray<System.Byte>;
  CardKeys: ArrayOfAcsKeyInfo;
  Drivers: ArrayOfAcsAccessPointDriverInfo;
begin

  SetParameters;
  ApiConnect;

  Service := GetILNetworkService(True, '', HTTPRIO);
  FStorage.ReadConfig;

  // подключение
  PrepareSoapHeader(Service, GetGuid, FStorage.LoginRusGuard, FStorage.PasswordRusGuard);
  IdConnect := Service.Connect;

  PrepareSoapHeader(Service, GetGuid, FStorage.LoginRusGuard, FStorage.PasswordRusGuard);
  Drivers := Service.GetAcsAccessPointDrivers;

  // запрос группы контактов

  PrepareSoapHeader(Service, GetGuid, FStorage.LoginRusGuard, FStorage.PasswordRusGuard);
  Groups := Service.GetAcsEmployeeGroupsFull(False);
  SetLength(GUIDs, Length(Groups));
  for I := 0 to Length(Groups) - 1 do
  begin

    GUIDs[I] := Groups[I].ID;
  end;

  PrepareSoapHeader(Service, GetGuid, 'admin', '');
  Data := Service.GetAcsEmployees(0, 10000, EmployeeSortedColumn.FullName, SortOrder.Ascending,
    True, nil, True);

  for I := 0 to Data.Count - 1 do
  begin


    PrepareSoapHeader(Service, GetGuid, 'admin', '');
    CardKeys := Service.GetAcsKeysForEmployee(Data.Employees[I].ID);

    PrepareSoapHeader(Service, GetGuid, 'admin', '');
    Photo := Service.GetAcsEmployeePhoto(Data.Employees[I].ID, 1);

    SaveUser(Data.Employees[I], Photo, CardKeys);
  end;

  // отключение
  PrepareSoapHeader(Service, GetGuid, 'admin', '');
  Service.Disconnect(IdConnect);
end;


procedure TfrmMain.btnTestTimeClick(Sender: TObject);
begin
  FHandler.ReadConfig;
  FHandler.CorrectTime;
end;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  FHandler.ReadConfig;
  FHandler.Run;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FStorage := TStorage.GetInstance;
  FHandler := THandler.Create;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FHandler.Free
end;

function TfrmMain.GetBase64Photo(Photo: TArray<System.Byte>): string;
begin
  Result := TNetEncoding.Base64.EncodeBytesToString(Photo);
end;

function TfrmMain.GetGuid: string;
begin
  if FGuid = EmptyStr then
  begin
    FGuid := TGUID.NewGuid.ToString;
    FGuid := StringReplace(FGuid, '{', '', []);
    FGuid := StringReplace(FGuid, '}', '', []);
    FGuid := 'uuid-' + LowerCase(FGuid);
  end;
  Inc(FNumRequest);
  Result := FGuid + '-' + IntToStr(FNumRequest);
end;

procedure TfrmMain.GetVisits;
var
  Api: TApi;
begin
  Api := TApi.Create;
  try
    Api.Exec('GET', 'api/visits', '');

  finally
    Api.Free
  end;
end;

procedure TfrmMain.HTTPRIOAfterExecute(const MethodName: string;
  SOAPResponse: TStream);
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.Create;
  Stream.LoadFromStream(SOAPResponse);
  try
    Stream.SaveToFile('D:\Temp\SOAP\Answer.xml');
  finally
    Stream.Free;
  end;
end;

procedure TfrmMain.HTTPRIOBeforeExecute(const MethodName: string;
  SOAPRequest: TStream);
var
  SourceXML: string;
  Stream: TMemoryStream;
  SourceDoc: IXMLDocument;
  XMLNode: IXMLNode;
  SecurityNodeS: IXMLNode;
  SecurityNodeD: IXMLNode;
  FS: TStringList;
  S: string;
  InStr: string;
  CreatedS: string;
  ExpiresS: string;
  GuidS: string;
begin
  Exit;
  if MethodName <> 'AddLogMessageForAccessPoint' then
    Exit;

  Stream := TMemoryStream.Create;
  SOAPRequest.Position := 0;
  Stream.LoadFromFile('D:\Temp\SOAP\visits.xml');
  Stream.SaveToStream(SOAPRequest);
  SOAPRequest.Position := 0;
  Exit;

  SourceDoc := TXMLDocument.Create(nil);
  SourceDoc.Active := True;
  SourceDoc.LoadFromStream(SOAPRequest);
  SOAPRequest.Position := 0;

  FS := TStringList.Create;
  FS.LoadFromFile('D:\Temp\SOAP\emploeeN.xml');
  SOAPRequest.Position := 0;
  FS.SaveToStream(SOAPRequest);
  SOAPRequest.Position := 0;
  Exit;

  SourceXML := FS.Text;

  try

    XMLNode := SourceDoc.DocumentElement.ChildNodes.FindNode('Header');
    if XMLNode = nil then
      Exit;
    SecurityNodeS := XMLNode.ChildNodes[0];
    if SecurityNodeS = nil then
      Exit;

    CreatedS := SecurityNodeS.ChildNodes[0].ChildNodes[0].Text;
    ExpiresS := SecurityNodeS.ChildNodes[0].ChildNodes[1].Text;
    SourceXML := StringReplace(SourceXML, '#CREATED#', CreatedS, []);
    SourceXML := StringReplace(SourceXML, '#EXPIRES#', ExpiresS, []);

    FS.LoadFromStream(SOAPRequest);
    GuidS := FS.Text;
    Delete(GuidS, 1, Pos('wsu:Id="', GuidS) + 7);
    Delete(GuidS, Pos('"><Username', GuidS), Length(GuidS) - Pos('"><Username', GuidS) - 1);
    GuidS := Trim(GuidS);
    SourceXML := StringReplace(SourceXML, '#GUID#', GuidS, []);
    FS.Text := SourceXML;
    FS.SaveToStream(SOAPRequest);
    FS.SaveToFile('D:\Temp\SOAP\out.xml');
    SOAPRequest.Position := 0;

  finally
    Stream.Free;
    FS.Free;
  end;
end;

procedure TfrmMain.SaveUser(const User: AcsEmployeeInfo2; Photo: TArray<System.Byte>;
  CardKeys: ArrayOfAcsKeyInfo);
var
  UserJson: ISuperObject;
  Api: TApi;
  I: Integer;
  Card: ISuperObject;
begin
  if User.FirstName = EmptyStr then
    Exit;

  UserJson := SO;
  UserJson.S['1c_id'] := 'RusGuard-' + User.ID;
  UserJson.S['first_name'] := User.FirstName;
  UserJson.S['surname'] := User.LastName;
  UserJson.S['middle_name'] := User.SecondName;
  UserJson.S['company_name'] := '';
  UserJson.S['photo'] := GetBase64Photo(Photo);

  UserJson.O['cards'] := SO('[]');
  for I := 0 to Length(CardKeys) - 1 do
  begin
    Card := SO;
    Card.S['name'] := CardKeys[I].Name_;
    Card.S['number'] := IntToStr(CardKeys[I].KeyNumber);
    UserJson.A['cards'].Add(Card);
  end;

  Api := TApi.Create;
  try
    Api.Exec('POST', 'api/user/add', UserJson.AsJSon);
  finally
    Api.Free
  end;


end;

procedure TfrmMain.SetParameters;
begin
 
end;

end.
