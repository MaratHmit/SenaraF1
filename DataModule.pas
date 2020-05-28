unit DataModule;

interface

uses
  System.SysUtils, System.Classes, UniProvider, SQLServerUniProvider, Data.DB,
  DBAccess, Uni, MemDS;

type
  TdmMain = class(TDataModule)
    conMain: TUniConnection;
    provSQL: TSQLServerUniProvider;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  dmMain: TdmMain;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

end.
