unit uLSNIParamsReader;

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
  uLSNIStringParser, uParams, uStrUtils;

type

  TListStarter = class(TList<String>)

  private

    function Started(const _Name: String): Boolean;

  end;

  TLSNIParamsReader = class(TLSNIStringParser, IParamsReader)

  strict private

    FParams: TParams;

    FCurrentName: String;
    FCurrentType: TParamDataType;

    FListStarter: TListStarter;

    procedure CheckPresetType(_Strict: Boolean);
    function TrimDigital(const _Value: String): String;
    function UndoubleSymbols(const _Value: String): String;

  private

    constructor CreateNested(_MasterParser: TLSNIParamsReader); reintroduce;

    property ListStarter: TListStarter read FListStarter;

  protected

    procedure ReadName; override;
    procedure ReadType; override;
    procedure ReadValue; override;
    procedure ReadParams; override;
    function IsNestedParams: Boolean; override;
    procedure BeforeReadParam(_Param: TParam); virtual;
    procedure AfterReadParam(_Param: TParam); virtual;
    procedure AfterReadParams(_Param: TParam); virtual;

    property CurrentName: String read FCurrentName;
    property CurrentType: TParamDataType read FCurrentType;

  public

    constructor Create; override;

    destructor Destroy; override;

    { IParamsReader }
    procedure SetParams(_Value: TParams);

    property Params: TParams read FParams;

  end;

  TParamsLSNIReaderClass = class of TLSNIParamsReader;

procedure LSNIStrToParams(const Source: String; Params: TParams; PresetTypes: Boolean = False);

implementation

procedure LSNIStrToParams(const Source: String; Params: TParams; PresetTypes: Boolean);
var
  Reader: TLSNIParamsReader;
begin

  Reader := TLSNIParamsReader.Create;
  try

    Reader.Located := True;
    Reader.NativeException := True;
    Reader.SetSource(Source);
    Reader.SetParams(Params);
    Reader.Read;

  finally
    Reader.Free;
  end;

end;

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

{ TLSNIParamsReader }

constructor TLSNIParamsReader.Create;
begin
  inherited Create;
  FListStarter := TListStarter.Create;
end;

constructor TLSNIParamsReader.CreateNested;
begin

  inherited CreateNested(_MasterParser);

  Located := _MasterParser.Located;
  Locator := _MasterParser.Locator;

end;

destructor TLSNIParamsReader.Destroy;
begin
  FreeAndNil(FListStarter);
  inherited Destroy;
end;

procedure TLSNIParamsReader.CheckPresetType(_Strict: Boolean);
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

function TLSNIParamsReader.TrimDigital(const _Value: String): String;
begin
  Result := StringReplace(_Value, ' ', '', [rfReplaceAll]);
end;

function TLSNIParamsReader.UndoubleSymbols(const _Value: String): String;
begin

  { ƒублировать нужно только одиночный закрывающий регион символ, поэтому и раздублировать только его надо при
    условии, что значение считываетс€ регионом. ѕоэтому, символ задаетс€ событием региона. Ќо! «десь будет нужна отмена,
    потому что дублирование не нужно в комментари€х совсем. }

  if DoublingChar > #0 then Result := UndoubleStr(_Value, DoublingChar)
  else Result := _Value;

end;

procedure TLSNIParamsReader.ReadName;
var
  Value: String;
begin

  Value := ReadElement(True);

  TParam.ValidateName(Value, Params.PathSeparator);
  FCurrentName := Value;

end;

procedure TLSNIParamsReader.ReadType;
begin
  FCurrentType := StrToParamDataType(ReadElement(True));
  CheckPresetType(True);
end;

procedure TLSNIParamsReader.ReadValue;
var
  Value: String;
  Index: Integer;
begin

  Value := ReadElement(False);

  CheckPresetType(True);

  { „тобы предопределить структуру листа дл€ нетипизованного хранени€, достаточно создать одну его строку в параметрах
    до считывани€. }
  with Params.AddList(CurrentName) do begin

    if ListStarter.Started(CurrentName) or (Count = 0) then Index := Append
    else Index := 0;

//    BeforeReadParam(Items[Index]);

    if Length(Value) > 0 then

      case CurrentType of

        dtBoolean:    AsBoolean   [Index] := StrToBoolean(Value);
        dtInteger:    AsInteger   [Index] := StrToInt(TrimDigital(Value));
        dtBigInt:     AsBigInt    [Index] := StrToBigInt(TrimDigital(Value));
        dtFloat:      AsFloat     [Index] := StrToFloat (TrimDigital(Value));
        dtExtended:   AsExtended  [Index] := StrToExtended(TrimDigital(Value));
        dtDateTime:   AsDateTime  [Index] := StrToDateTime(Value);
        dtGUID:       AsGUID      [Index] := StrToGUID(Value);
        dtAnsiString: AsAnsiString[Index] := StrToAnsiStr(Value);
        dtString:     AsString    [Index] := UndoubleSymbols(Value);
        dtBLOB:       AsBLOB      [Index] := HexStrToBLOB(Value);
        dtData:       AsData      [Index] := ByteStrToData(Value);

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

procedure TLSNIParamsReader.ReadParams;
var
//  Param: TParam;
  NestedParams: TParams;
begin

//  if PresetTypes then begin

//    Params.FindParam(CurrentName, dtParams, Param);
//    NestedParams := Params.AsParams[CurrentName]

//  end else begin

    NestedParams := TParamsClass(Params.ClassType).Create(Params.PathSeparator);
    NestedParams.SaveToStringOptions := Params.SaveToStringOptions;
//    with Params.AddList(CurrentName) do
//      Param := Items[Append];

//    BeforeReadParam(Param);

    Params.AsParams[CurrentName] := NestedParams;

//  end;

  with TParamsLSNIReaderClass(ClassType).CreateNested(Self) do

    try

      SetSource(Source);
      SetParams(NestedParams);
      Read;
//      AfterReadParams(Param);
      { ¬озврат управлени€ мастеру. ≈сли помощник выломалс€, не возвращать, иначе локаци€ вернетс€ в начало помощника. }
      RetrieveControl(Self);

    finally
      Free;
    end;

//  AfterReadParam(Param);

  FCurrentName := '';
  FCurrentType := dtUnknown;

end;

function TLSNIParamsReader.IsNestedParams: Boolean;
begin
  CheckPresetType(False);
  Result := FCurrentType = dtParams;
end;

procedure TLSNIParamsReader.BeforeReadParam(_Param: TParam);
begin
end;

procedure TLSNIParamsReader.AfterReadParam(_Param: TParam);
begin
end;

procedure TLSNIParamsReader.AfterReadParams(_Param: TParam);
begin
end;

procedure TLSNIParamsReader.SetParams(_Value: TParams);
begin
  FParams := _Value;
end;

end.
