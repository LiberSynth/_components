unit uParams;

interface

uses
  { vSoft }
  uCore;

type

  TParamsDataType = (dtUnknown, dtBoolean, dtInteger, dtFloat, dtDateTime, dtGUID, dtAnsiString, dtString, dtBLOB, dtParams);

  TParams = class;

  TParam = class(TNamedDataHolder)

  strict private

    FDataType: TParamsDataType;

  private

    function GetAsParams: RawByteString;
    procedure SetAsParams(const Value: RawByteString);

  public

    property DataType: TParamsDataType read FDataType write FDataType;
    property AsParams: RawByteString read GetAsParams write SetAsParams;

  end;

  TParams = class
  end;

implementation

{ TParam }

function TParam.GetAsParams: RawByteString;
begin
  CheckDataType(dtParams);
  Result := TParams(Data);
end;

procedure TParam.SetAsParams(const Value: RawByteString);
begin

end;

end.
