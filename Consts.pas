unit Consts;

interface

uses
  SysUtils;

const

  DEBUG_MODE = False;

  ID_PREFIX_RUSGUARD = 'RusGuard-';

  APP_DISPLAY = 'O.Vision адаптер';
  SERVICE_NAME = 'OVisionAdapter';

  DEF_URL_RUSGUARD = 'https://localhost/LNetworkServer/LNetworkService.svc?wsdl';
  DEF_LOGIN_RUSGUARD = 'admin';
  DEF_DBSERVER_RUSGUARD = '\SQLEXPRESS';
  DEF_DBLOGIN_RUSGUARD = 'sa';

  FILE_EMPLOYES = 'employes.json';
  FILE_CONFIG = 'config.ini';
  DEVELOPER = 'O.Vision';
  DIR_CACHE = 'RusGuard';
  CKEY1 = 53761;
  CKEY2 = 32618;
  SALT = 1406;

  FILE_NAME_LOG = 'log.txt';
  FILE_NAME_DEBUG = 'debug.txt';

  IS_CHECKED_DATE_CARDS = False;
  PATH_HASHES = 'Hashes';

  API_GET_USERS = 'api/users';
  API_ADD_USER = 'api/user/add';
  API_GET_VISITS = 'api/visits';
  API_GET_USER = 'api/user';
  API_UPDATE_USER = 'api/user';
  API_CHECKTIME = 'checktime';
  API_CORRECTTIME = 'correcttime';

  DEF_LOG_MESSAGE_TYPE = 1;
  DEF_LOG_MESSAGE_SUBTYPE_ENTER = 26;
  DEF_LOG_MESSAGE_SUBTYPE_EXIT = 27;
  DEF_LOG_MESSAGE_ENTER = 'Вход';
  DEF_LOG_MESSAGE_EXIT = 'Выход';

  CHECK_EXISTING_USERS = False;

  function EncryptStr(const S :WideString; Key: Word): String;
  function DecryptStr(const S: String; Key: Word): String;

implementation

function EncryptStr(const S :WideString; Key: Word): String;
var   i          :Integer;
      RStr       :RawByteString;
      RStrB      :TBytes Absolute RStr;
begin
  Result:= '';
  RStr:= UTF8Encode(S);
  for i := 0 to Length(RStr)-1 do begin
    RStrB[i] := RStrB[i] xor (Key shr 8);
    Key := (RStrB[i] + Key) * CKEY1 + CKEY2;
  end;
  for i := 0 to Length(RStr)-1 do begin
    Result:= Result + IntToHex(RStrB[i], 2);
  end;
end;

function DecryptStr(const S: String; Key: Word): String;
var   i, tmpKey  :Integer;
      RStr       :RawByteString;
      RStrB      :TBytes Absolute RStr;
      tmpStr     :string;
begin
  tmpStr:= UpperCase(S);
  SetLength(RStr, Length(tmpStr) div 2);
  i:= 1;
  try
    while (i < Length(tmpStr)) do begin
      RStrB[i div 2]:= StrToInt('$' + tmpStr[i] + tmpStr[i+1]);
      Inc(i, 2);
    end;
  except
    Result:= '';
    Exit;
  end;
  for i := 0 to Length(RStr)-1 do begin
    tmpKey:= RStrB[i];
    RStrB[i] := RStrB[i] xor (Key shr 8);
    Key := (tmpKey + Key) * CKEY1 + CKEY2;
  end;
  Result:= UTF8Decode(RStr);
end;

end.
