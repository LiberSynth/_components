unit uParamsReader;

(*******************************************************************************************)
(*            _____          _____          _____          _____          _____            *)
(*           /\    \        /\    \        /\    \        /\    \        /\    \           *)
(*          /::\____\      /::\    \      /::\    \      /::\    \      /::\    \          *)
(*         /:::/    /      \:::\    \    /::::\    \    /::::\    \    /::::\    \         *)
(*        /:::/    /        \:::\    \  /::::::\    \  /::::::\    \  /::::::\    \        *)
(*       /:::/    /          \:::\    \ :::/\:::\    \ :::/\:::\    \ :::/\:::\    \       *)
(*      /:::/    /            \:::\    \ :/__\:::\    \ :/__\:::\    \ :/__\:::\    \      *)
(*     /:::/    /             /::::\    \ \   \:::\    \ \   \:::\    \ \   \:::\    \     *)
(*    /:::/    /     _____   /::::::\    \ \   \:::\    \ \   \:::\    \ \   \:::\    \    *)
(*   /:::/    /     /\    \ /:::/\:::\    \ \   \:::\ ___\ \   \:::\    \ \   \:::\____\   *)
(*  /:::/____/     /::\    /:::/  \:::\____\ \   \:::|    | \   \:::\____\ \   \:::|    |  *)
(*  \:::\    \     \:::\  /:::/    \::/    / :\  /:::|____| :\   \::/    / :\  /:::|____|  *)
(*   \:::\    \     \:::\/:::/    / \/____/ :::\/:::/    / :::\   \/____/ :::\/:::/    /   *)
(*    \:::\    \     \::::::/    /  \:::\   \::::::/    /  \:::\    \  |:::::::::/    /    *)
(*     \:::\    \     \::::/____/    \:::\   \::::/    /    \:::\____\ |::|\::::/    /     *)
(*      \:::\    \     \:::\    \     \:::\  /:::/    / :\   \::/    / |::| \::/____/      *)
(*       \:::\    \     \:::\    \     \:::\/:::/    / :::\   \/____/  |::|  ~|            *)
(*        \:::\    \     \:::\    \     \::::::/    /  \:::\    \      |::|   |            *)
(*         \:::\____\     \:::\____\     \::::/    /    \:::\____\     \::|   |            *)
(*          \::/    /      \::/    /      \::/____/      \::/    /      \:|   |            *)
(*           \/____/        \/____/        ~~             \/____/        \|___|            *)
(*                                                                                         *)
(*******************************************************************************************)

interface

uses
  { VCL }
  SysUtils, Generics.Collections,
  { LiberSynth }
  uCustomReadWrite, uReadWriteCommon, uParams, uStrUtils;

type

  TListStarter = class(TList<String>)

  private

    function Started(const _Name: String): Boolean;

  end;

  IParamsReader = interface ['{5324B88D-A724-4E0B-9797-5004FE975287}']

    procedure SetParams(_Value: TParams);

  end;

  TParamsReader = class(TCustomReader, IParamsReader, INTVParser)

  strict private

    FParams: TParams;

    FCurrentName: String;
    FCurrentType: TParamDataType;

    FListStarter: TListStarter;

    procedure CheckPresetType(_Strict: Boolean);
    function TrimDigital(const _Value: String): String;

    { INTVParser }
    procedure ReadName(const _Element: String);
    procedure ReadType(const _Element: String);
    procedure ReadValue(const _Element: String);
    function IsNestedValue: Boolean;
    procedure ReadNestedBlock;

    { IParamsReader }
    procedure SetParams(_Value: TParams);

  private

    property ListStarter: TListStarter read FListStarter;

  protected

    procedure ReadParams;
    procedure BeforeReadParam(_Param: TParam); virtual;
    procedure AfterReadParam(_Param: TParam); virtual;
    procedure AfterReadParams(_Param: TParam); virtual;

    property CurrentName: String read FCurrentName;
    property CurrentType: TParamDataType read FCurrentType;

  public

    constructor Create; override;

    destructor Destroy; override;

    property Params: TParams read FParams;

  end;

  EParamsReadException = class(ECustomReadWriteException);

implementation

{ TListStarter }

function TListStarter.Started(const _Name: String): Boolean;
var
  S: String;
begin

  for S in Self do
    if SameText(S, _Name) then
      Exit(True);

  Add(_Name);
  Result := False;

end;

{ TParamsReader }

constructor TParamsReader.Create;
begin
  inherited Create;
  FListStarter := TListStarter.Create;
end;

destructor TParamsReader.Destroy;
begin
  FreeAndNil(FListStarter);
  inherited Destroy;
end;

procedure TParamsReader.CheckPresetType(_Strict: Boolean);
var
  DataType: TParamDataType;
begin

  { ќпределенный заранее тип данных }
  if

      (CurrentType = dtUnknown) and
      Params.FindDataType(CurrentName, DataType) and
      (DataType <> dtUnknown)

  then FCurrentType := DataType;

  if _Strict and (CurrentType = dtUnknown) then
    raise EParamsReadException.Create('Unknown param data type');

end;

function TParamsReader.TrimDigital(const _Value: String): String;
begin
  Result := StringReplace(_Value, ' ', '', [rfReplaceAll]);
end;

procedure TParamsReader.ReadName(const _Element: String);
begin
  TParam.ValidateName(_Element, Params.PathSeparator);
  FCurrentName := _Element;
end;

procedure TParamsReader.ReadNestedBlock;
{var
  Param: TParam;
  NestedParams: TParams;}
begin

  {if PresetTypes then begin

    Params.FindParam(CurrentName, dtParams, Param);
    NestedParams := Params.AsParams[CurrentName]

  end else begin

    NestedParams := TParamsClass(Params.ClassType).Create(Params.PathSeparator);
    NestedParams.SaveToStringOptions := Params.SaveToStringOptions;
    with Params.AddList(CurrentName) do
      Param := Items[Append];

    BeforeReadParam(Param);

    Params.AsParams[CurrentName] := NestedParams;

  end;}

//  with TParamsReaderClass(ClassType).CreateNested(Self) do
//
//    try
//
//      SetSource(Source);
//      SetParams(Params);
//      Read;
//{      AfterReadParams(Param);}
//      { ¬озврат управлени€ мастеру. ≈сли помощник выломалс€, не возвращать, иначе локаци€ вернетс€ в начало помощника. }
//      RetrieveControl(Self);
//
//    finally
//      Free;
//    end;

{  AfterReadParam(Param);}

//  FCurrentName := '';
//  FCurrentType := dtUnknown;

end;

procedure TParamsReader.ReadParams;
begin

end;

procedure TParamsReader.ReadType(const _Element: String);
begin
  FCurrentType := StrToParamDataType(_Element);
  CheckPresetType(True);
end;

procedure TParamsReader.ReadValue(const _Element: String);
var
  Index: Integer;
begin

  CheckPresetType(True);

  { „тобы предопределить структуру листа дл€ нетипизованного хранени€, достаточно создать одну его строку в параметрах
    до считывани€. }
  with Params.AddList(CurrentName) do begin

    if ListStarter.Started(CurrentName) or (Count = 0) then Index := Append
    else Index := 0;

//    BeforeReadParam(Items[Index]);

    if Length(_Element) > 0 then

      case CurrentType of

        dtBoolean:    AsBoolean   [Index] := StrToBoolean(_Element);
        dtInteger:    AsInteger   [Index] := StrToInt(TrimDigital(_Element));
        dtBigInt:     AsBigInt    [Index] := StrToBigInt(TrimDigital(_Element));
        dtFloat:      AsFloat     [Index] := StrToFloat (TrimDigital(_Element));
        dtExtended:   AsExtended  [Index] := StrToExtended(TrimDigital(_Element));
        dtDateTime:   AsDateTime  [Index] := StrToDateTime(_Element);
        dtGUID:       AsGUID      [Index] := StrToGUID(_Element);
        dtAnsiString: AsAnsiString[Index] := StrToAnsiStr(_Element);
        dtString:     AsString    [Index] := _Element;
        dtBLOB:       AsBLOB      [Index] := HexStrToBLOB(_Element);
        dtData:       AsData      [Index] := ByteStrToData(_Element);

      end

    else begin

      IsNull  [Index] := True;
      DataType[Index] := CurrentType;

    end;

//    AfterReadParam(Items[Index]);

  end;

  FCurrentName := '';
  FCurrentType := dtUnknown;

end;

function TParamsReader.IsNestedValue: Boolean;
begin
  CheckPresetType(False);
  Result := FCurrentType = dtParams;
end;

procedure TParamsReader.BeforeReadParam(_Param: TParam);
begin
end;

procedure TParamsReader.AfterReadParam(_Param: TParam);
begin
end;

procedure TParamsReader.AfterReadParams(_Param: TParam);
begin
end;

procedure TParamsReader.SetParams(_Value: TParams);
begin
  FParams := _Value;
end;

end.
