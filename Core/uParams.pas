unit uParams;

interface

uses
  { VCL }
  Generics.Collections,
  { vSoft }
  uCore;

type

  TParams = class;

  TParam = class(TNamedDataHolder)

  private

    function GetAsParams: TParams;
    procedure SetAsParams(const _Value: TParams);

  public

    property AsParams: TParams read GetAsParams write SetAsParams;

  end;

  TParams = class(TObjectList<TParam>)
  end;

implementation

{ TParam }

function TParam.GetAsParams: TParams;
begin
  CheckDataType(dtParams);
  Result := TParams(GetAbstractObject);
end;

procedure TParam.SetAsParams(const _Value: TParams);
begin

  CheckDataType(dtParams);
  if Assigned(AsParams) then AsParams.Free;
  SetAbstractObject(_Value);

end;

end.
