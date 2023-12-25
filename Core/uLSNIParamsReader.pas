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
  SysUtils,
  { LiberSynth }
  uLSNIStringParser, uParams, uStrUtils;

type

  TLSNIParamsReader = class(TLSNIStringParser, IParamsReader)

  strict private

    FParams: TParams;
    FPresetTypes: Boolean;

    FCurrentName: String;
    FCurrentType: TParamDataType;

    procedure CheckPresetType(_Strict: Boolean);
    function TrimDigital(const _Value: String): String;
    function UndoubleSymbols(const _Value: String): String;

  private

    constructor CreateNested(_MasterParser: TLSNIParamsReader); reintroduce;

    property PresetTypes: Boolean read FPresetTypes write FPresetTypes;

  protected

    procedure ReadName; override;
    procedure ReadType; override;
    procedure ReadValue; override;
    procedure ReadParams; override;
    function IsParamsType: Boolean; override;
    procedure BeforeReadParam(_Param: TParam); virtual;
    procedure AfterReadParam(_Param: TParam); virtual;
    procedure AfterReadParams(_Param: TParam); virtual;

    property CurrentName: String read FCurrentName;
    property CurrentType: TParamDataType read FCurrentType;

  public

    { IParamsReader }
    procedure SetParams(_Value: TParams);

    property Params: TParams read FParams;

  end;

  TParamsLSNIReaderClass = class of TLSNIParamsReader;

procedure LSNIStrToParams(const Source: String; Params: TParams);

implementation

procedure LSNIStrToParams(const Source: String; Params: TParams);
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

{ TLSNIParamsReader }

constructor TLSNIParamsReader.CreateNested;
begin

  inherited CreateNested(_MasterParser);

  FPresetTypes := _MasterParser.PresetTypes;
  Located := _MasterParser.Located;
  Locator := _MasterParser.Locator;

end;

procedure TLSNIParamsReader.SetParams(_Value: TParams);
begin
  FParams := _Value;
end;

procedure TLSNIParamsReader.CheckPresetType(_Strict: Boolean);
var
  P: TParam;
begin

  { Определенный заранее тип данных }
  if

      (CurrentType = dtUnknown) and
      Params.FindParam(CurrentName, P) and
      (P.DataType <> dtUnknown)

  then FCurrentType := P.DataType;

  if _Strict and (CurrentType = dtUnknown) then
    raise EParamsReadException.Create('Unknown param data type');

end;

function TLSNIParamsReader.TrimDigital(const _Value: String): String;
begin
  Result := StringReplace(_Value, ' ', '', [rfReplaceAll]);
end;

function TLSNIParamsReader.UndoubleSymbols(const _Value: String): String;
begin

  { Дублировать нужно только одиночный закрывающий регион символ, поэтому и раздублировать только его надо при
    условии, что значение считывается регионом. Поэтому, символ задается событием региона. Но! Здесь будет нужна отмена,
    потому что дублирование не нужно в комментариях совсем. }

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

  { TODO 3 -oVasilyevSM -cuLSNIParamsReader: При попытке чтения нетипизованных параметров не выламывается и читает неправильно. }
  if PresetTypes then
    CheckPresetType(True);

  { Считывание с зарегистрированными типами должно исполнятся в потомках с помощью отдельных свойств (Registered итд). }
  { TODO 3 -oVasilyevSM -cuLSNIParamsReader: Использование не по назначению. Нужно сформировать явную схему. }
  with Params.AddList(CurrentName) do begin

    if PresetTypes and (Count > 0) then Index := 0
    else Index := Append;

    BeforeReadParam(Items[Index]);

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

    AfterReadParam(Items[Index]);

  end;

  FCurrentName := '';
  FCurrentType := dtUnknown;

end;

procedure TLSNIParamsReader.ReadParams;
var
  Param: TParam;
  NestedParams: TParams;
begin

  if PresetTypes then begin

    Params.FindParam(CurrentName, dtParams, Param);
    NestedParams := Params.AsParams[CurrentName]

  end else begin

    NestedParams := TParamsClass(Params.ClassType).Create(Params.PathSeparator);
    NestedParams.SaveToStringOptions := Params.SaveToStringOptions;
    { TODO 3 -oVasilyevSM -cuLSNIParamsReader: Использование не по назначению. Нужно сформировать явную схему. }
    with Params.AddList(CurrentName) do
      Param := Items[Append];

    BeforeReadParam(Param);

    Params.AsParams[CurrentName] := NestedParams;

  end;

  with TParamsLSNIReaderClass(ClassType).CreateNested(Self) do

    try

      SetSource(Source);
      SetParams(NestedParams);
      Read;
      AfterReadParams(Param);
      { Возврат управления мастеру. Если помощник выломался, не возвращать, иначе локация вернется в начало помощника. }
      RetrieveControl(Self);

    finally
      Free;
    end;

  AfterReadParam(Param);

  FCurrentName := '';
  FCurrentType := dtUnknown;

end;

function TLSNIParamsReader.IsParamsType: Boolean;
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

end.
