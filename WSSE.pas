unit WSSE;

interface

uses
  System.SysUtils,
  Soap.InvokeRegistry,
  Soap.SOAPHTTPClient,
  System.Types,
  Soap.XSBuiltIns,
  Xml.XMLIntf;

const
  IS_OPTN=$0001;
  IS_ATTR=$0010;
  IS_TEXT=$0020;
  IS_REF =$0080;
  IS_QUAL=$0100;

  NS_SECEXT = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd';
  NS_UTILITY = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd';

type
  tTimestampFault=(wsu_MessageExpired);

  Id = type WideString;

  Created=class(TXSDateTime)
  end;

  Expires=class(TXSDateTime)
  end;

  Timestamp=class(TRemotable)
  private
    FCreated:Created;
    FExpires:Expires;
    FId: Id;
  public
    destructor Destroy; override;
  published
    property Created:Created Index (IS_OPTN) read FCreated write FCreated;
    property Expires:Expires Index (IS_OPTN) read FExpires write FExpires;
    property Id:Id Index (IS_ATTR or IS_QUAL) read FId write FId;
  end;

  AttributedString=class(TRemotable)
  private
    FText:WideString;
    FId:Id;
    FId_Specified:boolean;
    procedure SetId(Index:Integer; const AId:Id);
    function Id_Specified(Index:Integer):boolean;
  published
    property Text:WideString Index (IS_TEXT) read FText write FText;
    property Id:Id Index (IS_ATTR or IS_OPTN or IS_QUAL) read FId write SetId stored Id_Specified;
  end;

  Nonce=class(AttributedString)
  private
    FEncodingType: WideString;
    FEncodingType_Specified:boolean;
    procedure SetEncodingType(Index:Integer; const AWideString:WideString);
    function EncodingType_Specified(Index:Integer):boolean;
  published
    property EncodingType:WideString Index (IS_ATTR or IS_OPTN) read FEncodingType write SetEncodingType stored EncodingType_Specified;
  end;

  Password=class(AttributedString)
  private
    FType_:WideString;
    FType__Specified:boolean;
    procedure SetType_(Index:Integer; const AWideString:WideString);
    function Type__Specified(Index:Integer):boolean;
  published
    property Type_:WideString Index (IS_ATTR or IS_OPTN) read FType_ write SetType_ stored Type__Specified;
  end;

  UsernameToken=class(TRemotable)
  private
    FUserName:string;
    FCreated:Created;
    FPassword:Password;
    FNonce: Nonce;
    FId: Id;
  public
    destructor Destroy; override;
    function   ObjectToSOAP(RootNode, ParentNode: IXMLNode;
                            const ObjConverter: IObjConverter;
                            const NodeName, NodeNamespace, ChildNamespace: InvString; ObjConvOpts: TObjectConvertOptions;
                            out RefID: InvString): IXMLNode; override;
    property Id:Id Index (IS_ATTR or IS_QUAL) read FId write FId;
  published
    property Username:String read FUsername write FUsername;
    property Password:Password read FPassword write FPassword;
//    property Nonce: Nonce read FNonce write FNonce;
//    property Created:Created index (IS_REF) read FCreated write FCreated;
  end;

  Security=class(TSOAPHeader)
  private
    FTimestamp:Timestamp;
    FUserNameToken:UserNameToken;
  public
    destructor Destroy; override;
  published
    property Timestamp:TimeStamp index (IS_REF) read FTimestamp write FTimestamp;
    property UsernameToken:UsernameToken index (IS_REF) read FUserNameToken write FUserNameToken;
  end;

procedure PrepareSoapHeader(Service: IInvokable; Guid: string; UserName, APassword: string);


implementation


procedure PrepareSoapHeader(Service: IInvokable; Guid: string; UserName, APassword: string);
var
  Wsse: Security;
  Headers: ISOAPHeaders;
begin
  Wsse := Security.Create;
  Wsse.MustUnderstand := True;
  Wsse.UsernameToken := UsernameToken.Create;
  Wsse.UsernameToken.Id := Guid;
  Wsse.UsernameToken.Username := UserName;
  Wsse.UsernameToken.Password := Password.Create;
  Wsse.UsernameToken.Password.Type_ := 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText';
  Wsse.UsernameToken.Password.Text := APassword;
  Wsse.Timestamp := Timestamp.Create;
  Wsse.Timestamp.Created := Created.Create;
  Wsse.Timestamp.Created.AsDateTime := Now - 1/24/60;
  Wsse.Timestamp.Expires := Expires.Create;
  Wsse.Timestamp.Expires.AsDateTime := Now + 5/24/60;

  Headers:=Service as ISOAPHeaders;
  Headers.OwnsSentHeaders:=True;
  Headers.Send(Wsse);
end;

destructor Timestamp.Destroy;
begin
  FreeAndNIL(FCreated);
  FreeAndNIL(FExpires);
  inherited Destroy;
end;

destructor UsernameToken.Destroy;
begin
  FreeAndNil(FCreated);
  FreeAndNil(FPassword);
  FreeAndNil(FNonce);
  inherited Destroy;
end;

function UsernameToken.ObjectToSOAP(RootNode, ParentNode: IXMLNode;
  const ObjConverter: IObjConverter; const NodeName, NodeNamespace,
  ChildNamespace: InvString; ObjConvOpts: TObjectConvertOptions;
  out RefID: InvString): IXMLNode;
begin
  Result := inherited;
  if (Result <> nil) and (Length(FId) > 0) then
  begin
    Result.DeclareNamespace('wsu', NS_UTILITY);
    Result.SetAttributeNS('Id', NS_UTILITY, FId);
  end;
end;

procedure AttributedString.SetId(Index:Integer; const AId:Id);
begin
  FId:=AId;
  FId_Specified:=True;
end;

function AttributedString.Id_Specified(Index:Integer):boolean;
begin
  Result:=FId_Specified;
end;

procedure Password.SetType_(Index:Integer; const AWideString:WideString);
begin
  FType_:=AWideString;
  FType__Specified:=True;
end;

function Password.Type__Specified(Index:Integer):boolean;
begin
  Result:=FType__Specified;
end;

procedure Nonce.SetEncodingType(Index:Integer; const AWideString:WideString);
begin
  FEncodingType:=AWideString;
  FEncodingType_Specified:=True;
end;

function Nonce.EncodingType_Specified(Index:Integer):boolean;
begin
  Result:=FEncodingType_Specified;
end;

destructor Security.Destroy;
begin
  FreeAndNIL(FTimestamp);
  FreeAndNIL(FUserNameToken);
  inherited Destroy;
end;

initialization
  RemClassRegistry.RegisterXSClass(Security, NS_SECEXT, 'Security');
  RemClassRegistry.RegisterXSClass(Timestamp, NS_UTILITY, 'Timestamp');
  RemClassRegistry.RegisterXSClass(Created, NS_UTILITY, 'Created');
  RemClassRegistry.RegisterXSClass(Expires, NS_UTILITY, 'Expires');
  RemClassRegistry.RegisterXSClass(UsernameToken, NS_SECEXT, 'UsernameToken');
  RemClassRegistry.RegisterXSClass(Password, NS_SECEXT, 'Password');
  RemClassRegistry.RegisterXSInfo(TypeInfo(Nonce), NS_SECEXT, 'Nonce');
  RemClassRegistry.RegisterXSInfo(TypeInfo(tTimestampFault), NS_UTILITY, 'tTimestampFault');
  RemClassRegistry.RegisterExternalPropName(TypeInfo(tTimestampFault), 'wsu_MessageExpired', 'wsu:MessageExpired');
  RemClassRegistry.RegisterXSInfo(TypeInfo(Id), NS_UTILITY, 'Id');
  RemClassRegistry.RegisterXSClass(AttributedString, NS_SECEXT, 'AttributedString');
  RemClassRegistry.RegisterExternalPropName(TypeInfo(Password), 'Type_', 'Type');
end.
