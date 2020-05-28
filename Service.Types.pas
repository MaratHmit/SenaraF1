unit Service.Types;

interface

uses
  IdHashMessageDigest, SysUtils;

type
  IAdapter = interface
    function EmployeesToTerminal: Boolean;     // перенести сотрудников в Терминал
    function EmployeesFromTerminal: Boolean;   // перенести сотрудников из Терминала
  end;

  function md5(s: string): string;

implementation

function md5(s: string): string;
begin
  Result := '';
  with TIdHashMessageDigest5.Create do
  try
    Result := AnsiLowerCase(HashStringAsHex(s));
  finally
    Free;
  end;
end;

end.
