unit Api;

interface
  uses System.Classes, System.SysUtils, httpsend, ssl_openssl, Vcl.Dialogs,
  Storage, superobject, mimemess, mimepart, smtpsend, synachar, DateUtils;

type
  TApi = class
  private
    FLastError: string;
  public
    property LastError: string read FLastError;
  public

    function Auth: Boolean;
    function Exec(const Method, Target, Params: string): string;
    function Info(const Target: string; const Params: string): string;
    function Fetch(const Target: string; const Params: string = ''): string;
    function Save(const Target: string; const Params: string): string;
    function Sort(const Target: string; const Params: string): string;
    function Delete(const Target: string; const Params: string): string;
    procedure GetBinaryData(const Method, Target, Params: string; Stream: TStream);

  end;

  TSMTPClientHelper = class Helper for TSMTPSend
    function MailToEx(const AEmail:string; ANotifyString: string): Boolean;

end;

implementation

{ TApi }

function TApi.Auth: Boolean;
var
  HTTPSend: THTTPSend;
  Json: ISuperObject;
  FormData: TStringStream;
  Data: AnsiString;
  Url: string;
  Storage: TStorage;
  CurTimestamp: string;
begin
  Result := False;
  CurTimestamp := IntToStr(DateTimeToUnix(Now, False));

  Storage := TStorage.GetInstance;
  HTTPSend := THTTPSend.Create;
  HTTPSend.MimeType := 'application/x-www-form-urlencoded';
  HTTPSend.Headers.Add('CURTIMESTAMP ' + CurTimestamp);
  try
    FormData := TStringStream.Create;
    try
      Data := 'email=' + Trim(Storage.LoginTerminal) + '&';
      Data := Data + 'password=' + Trim(Storage.PasswordTerminal);
      HTTPSend.Document.Write(PAnsiChar(Data)^, Length(Data));
      Url := Storage.UrlTerminal + '/api/login';

      if HTTPSend.HTTPMethod('POST', Url) then
      begin
        FormData.Position := 0;
        FormData.LoadFromStream(HTTPSend.Document);
        Data := FormData.DataString;
        if HTTPSend.ResultCode = 200 then
        begin
          Storage := TStorage.GetInstance;
          Json := SO(Data);
          if Json.O['success'] <> nil then
            Storage.TokenTerminal := Json.O['success'].S['token'];
          Result := True
        end else FLastError := Data;
      end;
    except

    end;
  finally
    FormData.Free;
    HTTPSend.Free
  end;


end;

function TApi.Exec(const Method, Target, Params: string): string;
var
  HTTPSend: THTTPSend;
  Stream: TStringStream;
  Answer: string;
  Url: string;
  T: Cardinal;
  Storage: TStorage;
  CurTimestamp: string;
begin
  Result := EmptyStr;
  Storage := TStorage.GetInstance;

  CurTimestamp := IntToStr(DateTimeToUnix(Now, False));

  FLastError := EmptyStr;
  Url := Storage.UrlTerminal + '/' + Target;
  HTTPSend := THTTPSend.Create;
  HTTPSend.KeepAliveTimeout := 3;
  HTTPSend.KeepAlive := True;
  HTTPSend.Protocol := '1.1';
  HTTPSend.Timeout := 10000;
  if Method = 'POST' then
    HTTPSend.MimeType := 'application/json'
  else
    HTTPSend.MimeType := 'application/x-www-form-urlencoded';
  HTTPSend.Headers.Add('Authorization: Bearer ' + Storage.TokenTerminal);
  HTTPSend.Headers.Add('CURTIMESTAMP ' + CurTimestamp);

  try
    if Params <> EmptyStr then
    begin
      if Method = 'POST' then
      begin
        Stream := TStringStream.Create('', TEncoding.UTF8);
        try
          Stream.WriteString(Params);
          Stream.Position := 0;
          HTTPSend.Document.LoadFromStream(Stream);
          HTTPSend.Document.Position := 0;
        finally
          Stream.Free
        end;
      end;
      if Method = 'GET' then
      begin
        Url := Url + '?' + Params;
      end;
    end;
    if HTTPSend.HTTPMethod(Method, Url) then
    begin
      Answer := EmptyStr;
      if HTTPSend.Document.Size > 0 then
      begin
        try
          Stream := TStringStream.Create('', TEncoding.UTF8);
          Stream.LoadFromStream(HTTPSend.Document);
          Answer := Stream.DataString;
        finally
          Stream.Free;
        end;
      end;
      if HTTPSend.ResultCode = 200 then
        Result := Answer
      else FLastError := Answer;
    end else
    begin
      FLastError := 'Сервер не отвечает на запрос!';
    end;
  finally
    HTTPSend.Free;
  end;
end;

function TApi.Fetch(const Target: string; const Params: string = ''): string;
begin
  Result := Exec('FETCH', Target, Params);
end;

procedure TApi.GetBinaryData(const Method, Target, Params: string; Stream: TStream);
var
  HTTPSend: THTTPSend;
  Data: AnsiString;
  Url: string;
begin

//  FLastError := EmptyStr;
//  Url := Storage + Target + '/';
//  HTTPSend := THTTPSend.Create;
//  HTTPSend.MimeType := 'application/x-www-form-urlencoded';
//  HTTPSend.Headers.Add('Secookie:' + FIdSession);
//  if Params <> EmptyStr then
//  begin
//    Data := Params;
//    HTTPSend.Document.Write(PAnsiChar(Data)^, Length(Data));
//  end;
//  if HTTPSend.HTTPMethod(Method, Url) then
//  begin
//    if HTTPSend.ResultCode = 200 then
//      Stream.WriteData(HTTPSend.Document.Memory, HTTPSend.Document.Size)
//    else FLastError := 'Ошибка запроса данных!';
//  end else FLastError := 'Сервер не отвечает на запрос!';
end;

function TApi.Info(const Target, Params: string): string;
begin
  Result := Exec('INFO', Target, Params);
end;

function TApi.Save(const Target, Params: string): string;
begin
  Result := Exec('SAVE', Target, Params);
end;

function TApi.Sort(const Target, Params: string): string;
begin
  Result := Exec('SORT', Target, Params);
end;

function TApi.Delete(const Target, Params: string): string;
begin
  Result := Exec('DELETE', Target, Params);
end;

{ TSMTPClientHelper }

function TSMTPClientHelper.MailToEx(const AEmail: string;
  ANotifyString: string): Boolean;
var
  S: string;
begin
  Sock.SendString('RCPT TO:<' + AEmail + '> '  + ANotifyString + #13#10);
  repeat
    S := Sock.RecvString(FTimeout);
    if Sock.LastError <> 0 then
      Break;
  until Pos('-', S) <> 4;
  Result := StrToIntDef(Copy(S, 1, 3), 0) div 100 = 2;
end;

end.
