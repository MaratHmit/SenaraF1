unit Forms.CardPoint;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Data.DB, MemDS, DBAccess,
  Uni, DataModule, Vcl.CheckLst;

type
  TfrmCardPoint = class(TForm)
    btnOk: TButton;
    btnCancel: TButton;
    Label1: TLabel;
    Label2: TLabel;
    edtAddress: TEdit;
    cbLevels: TCheckListBox;
    cbSendLog: TCheckBox;
    procedure FormShow(Sender: TObject);
  private
    procedure LoadAccessLevels;
  public
    { Public declarations }
  end;

var
  frmCardPoint: TfrmCardPoint;

implementation

{$R *.dfm}

procedure TfrmCardPoint.FormShow(Sender: TObject);
begin
  LoadAccessLevels;
end;

procedure TfrmCardPoint.LoadAccessLevels;
var
  Query: TUniQuery;
begin
  Query := TUniQuery.Create(nil);
  Query.Connection := dmMain.conMain;
  try
    try
      Query.SQL.Text := 'SELECT * FROM AcsAccessLevel';
      Query.Open;
      while not Query.Eof do
      begin
        cbLevels.Items.Add(Query.FieldByName('Name').AsString);
        Query.Next
      end;
    except

    end;
  finally
    Query.Free
  end;
end;

end.
