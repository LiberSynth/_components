unit uParams;

(*********************************************************)
(*                                                       *)
(*                        Hello!)                        *)
(*                                                       *)
(*********************************************************)

{ TODO -oVasilyevSM -cuParams: ����� �������� TIniParams, ������� ����� ����������� � ����, ��������� � ������������. }
{ TODO -oVasilyevSM -cuParams: ����� SaveToString/LoadFromString ����� SaveToStream/LoadFromStream }
{ TODO -oVasilyevSM -cuParams: ����� ����� AutoSave. � ������ SetAs �������� � ��� SaveTo... ���� to - ���������� ��� ����� ��������� ��� ��������� None, ToFile, ToStream }
{ TODO -oVasilyevSM -cuParams: ����� ����� ��������� TRegParams }
{ TODO -oVasilyevSM -cuParams: ������ � �������� ��� ���������. � ��������� ������� �������� �������� �������. }
{ TODO -oVasilyevSM -cuParams: ��� ������ � ���������������� ����������� ����� �����-�� ������� ��������. GetList ��� ��� ��������� ������. ������ ParamByName ������ ������ �� ������ � ���.  }

interface

uses
  { VCL }
  SysUtils, Generics.Collections,
  { vSoft }
  uConsts, uTypes, uCore, uDataUtils, uStrUtils, uCustomStringParser, uParamsStringParser;

type

  { TODO -oVasilyevSM -cTParam: ����������� �������. ������ Extended ����� ��� ��� �������� ���������� ����������� Float � ��������� }
  TParamDataType = (dtUnknown, dtBoolean, dtInteger, dtBigInt, dtFloat, {dtExtended, }dtDateTime, dtGUID, dtAnsiString, dtString, dtBLOB, {dtData (TData),}dtParams);

  TParams = class;

  TParam = class

  const

    SC_SELF_ALLOCATED_TYPES = [dtAnsiString, dtString, dtBLOB, {dtData,}dtParams];

  strict private

    FName: String;
    FDataType: TParamDataType;
    FIsNull: Boolean;
    FStrictDataType: Boolean;
    FData: Pointer;

    procedure SetIsNull(const _Value: Boolean);

    procedure AllocData;
    procedure FreeData;
    function DataSize: Cardinal;
    procedure PresetData(_DataType: TParamDataType);

  private

    { v Using FData methods v }
    function GetAsBoolean: Boolean;
    function GetAsInteger: Integer;
    function GetAsBigInt: Int64;
    function GetAsFloat: Double;
    function GetAsDateTime: TDateTime;
    function GetAsGUID: TGUID;
    function GetAsAnsiString: AnsiString;
    function GetAsString: String;
    function GetAsBLOB: RawByteString;
    function GetAsParams: TParams;

    procedure SetAsBoolean(_Value: Boolean);
    procedure SetAsInteger(_Value: Integer);
    procedure SetAsBigInt(_Value: Int64);
    procedure SetAsFloat(_Value: Double);
    procedure SetAsDateTime(_Value: TDateTime);
    procedure SetAsGUID(const _Value: TGUID);
    procedure SetAsAnsiString(const _Value: AnsiString);
    procedure SetAsString(const _Value: String);
    procedure SetAsBLOB(const _Value: RawByteString);
    procedure SetAsParams(_Value: TParams);
    { ^ Using FData methods ^ }

  protected

    procedure CheckDataType(_DataType: TParamDataType);

  public

    constructor Create(const _Name: String);
    destructor Destroy; override;

    procedure Clear;
    { ��� �������� ��� ������� ����� }
    procedure Assign(_Source: TParam);
    class procedure ValidateName(const _Value: String);

    property DataType: TParamDataType read FDataType;
    property IsNull: Boolean read FIsNull write SetIsNull;
    property StrictDataType: Boolean read FStrictDataType write FStrictDataType;
    { TODO -oVasilyevSM -cTParam: ��� ����������� ����� ���� �� ������ '.', �� � '/' ��� '\'. � ��� ������� ������ ����
      ����������� � ��������� ������. ��� � ������ ������ ����������. }
    property Name: String read FName;

    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsBigInt: Int64 read GetAsBigInt write SetAsBigInt;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsGUID: TGUID read GetAsGUID write SetAsGUID;
    property AsAnsiString: AnsiString read GetAsAnsiString write SetAsAnsiString;
    property AsString: String read GetAsString write SetAsString;
    property AsBLOB: RawByteString read GetAsBLOB write SetAsBLOB;
    {

      ��� �������� ������ ������������ ������ �� ������ TParams �� ������ As... � ��������� ����. ������ ��� AsParams,
      �������� ������� ������ ���������� � ������, ���� �� ����� ���������� ��� ������� � ������ ������������ ����
      ��������. ��� ���������, ������ ��� ������ ��������� ��� ����� �������. �� � ������, ���� ���������.

    }
    property AsParams: TParams read GetAsParams;

  end;

  TParamHelper = class helper for TParam

  strict private

    function _GetAsBoolean: Boolean;
    function _GetAsInteger: Integer;
    function _GetAsBigInt: Int64;

    procedure _SetAsBoolean(const _Value: Boolean);
    procedure _SetAsInteger(const _Value: Integer);
    procedure _SetAsBigInt(const _Value: Int64);

  public

    property AsBoolean: Boolean read _GetAsBoolean write _SetAsBoolean;
    property AsInteger: Integer read _GetAsInteger write _SetAsInteger;
    property AsBigInt: Int64 read _GetAsBigInt write _SetAsBigInt;
    { TODO -oVasilyevSM -cTParamHelper: ����������� ������� }
//    property AsFloat: Double read GetAsFloat write SetAsFloat;
//    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
//    property AsGUID: TGUID read GetAsGUID write SetAsGUID;
//    property AsAnsiString: AnsiString read GetAsAnsiString write SetAsAnsiString;
//    property AsString: String read GetAsString write SetAsString;
//    property AsBLOB: RawByteString read GetAsBLOB write SetAsBLOB;

  end;

  TParams = class(TObjectList<TParam>)

    {

      _Name - ������ ������ ��� ��������� ��� ����. ���� ����� "." ��� _Path, ������, ������ � ������ �� ���������.
      �����.
      ������ SetAs... ������� ���� � �������� ��������, ��������� GetParam, ���� �� ���.
      ����� FindParam ������ �� �������, ������ ���� ������������.
      ����� ParamByName ����� ���������� ����������, ���� ����-�� �� �������.
      ������� ������ ��� ���������� � ����������������� ������ ����� �� ��������������. ����� ��������� �� � ��������.

    }

  strict private

    function GetParam(_Path: String): TParam;

  private

    function GetAsBoolean(const _Path: String): Boolean;
    function GetAsInteger(const _Path: String): Integer;
    function GetAsBigInt(const _Path: String): Int64;
    function GetAsFloat(_Path: String): Double;
    function GetAsDateTime(_Path: String): TDateTime;
    function GetAsGUID(_Path: String): TGUID;
    function GetAsAnsiString(_Path: String): AnsiString;
    function GetAsString(_Path: String): String;
    function GetAsBLOB(_Path: String): BLOB;
    function GetAsParams(_Path: String): TParams;

    procedure SetAsBoolean(const _Path: String; _Value: Boolean);
    procedure SetAsInteger(const _Path: String; _Value: Integer);
    procedure SetAsBigInt(const _Path: String; _Value: Int64);
    procedure SetAsFloat(_Path: String; _Value: Double);
    procedure SetAsDateTime(_Path: String; _Value: TDateTime);
    procedure SetAsGUID(_Path: String; const _Value: TGUID);
    procedure SetAsAnsiString(_Path: String; const _Value: AnsiString);
    procedure SetAsString(_Path: String; const _Value: String);
    procedure SetAsBLOB(_Path: String; const _Value: BLOB);
    procedure SetAsParams(_Path: String; _Value: TParams);

  protected

    procedure Notify(const _Item: TParam; _Action: Generics.Collections.TCollectionNotification); override;

  public

    function Add(const _Name: String): TParam;
    function Insert(_Index: Integer; const _Name: String): TParam;

    function FindParam(_Path: String; _DataType: TParamDataType; var _Value: TParam): Boolean; overload;
    function FindParam(_Path: String; var _Value: TParam): Boolean; overload;
    function ParamByName(const _Path: String): TParam;

    { ��� �������� ��� ������� ����� }
    procedure Assign(_Source: TParams);

    { v ������� � �������� ��� �������� ������ v }
    function FindBoolean(const _Path: String; var _Value: Boolean): Boolean;
    function FindInteger(const _Path: String; var _Value: Integer): Boolean;
    function FindBigInt(const _Path: String; var _Value: Int64): Boolean;
    function FindFloat(const _Path: String; var _Value: Double): Boolean;
    function FindDateTime(const _Path: String; var _Value: TDateTime): Boolean;
    function FindGUID(const _Path: String; var _Value: TGUID): Boolean;
    function FindAnsiString(const _Path: String; var _Value: AnsiString): Boolean;
    function FindString(const _Path: String; var _Value: String): Boolean;
    function FindBLOB(const _Path: String; var _Value: BLOB): Boolean;
    function FindParams(const _Path: String; var _Value: TParams): Boolean;

    function AsBooleanDef(const _Path: String; _Default: Boolean): Boolean;
    function AsIntegerDef(const _Path: String; _Default: Integer): Integer;
    function AsBigIntDef(const _Path: String; _Default: Int64): Int64;
    function AsFloatDef(const _Path: String; _Default: Double): Double;
    function AsDateTimeDef(const _Path: String; _Default: TDateTime): TDateTime;
    function AsGUIDDef(const _Path: String; _Default: TGUID): TGUID;
    function AsAnsiStringDef(const _Path: String; _Default: AnsiString): AnsiString;
    function AsStringDef(const _Path: String; _Default: String): String;
    function AsBLOBDef(const _Path: String; _Default: BLOB): BLOB;

    property AsBoolean[const _Path: String]: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger[const _Path: String]: Integer read GetAsInteger write SetAsInteger;
    property AsBigInt[const _Path: String]: Int64 read GetAsBigInt write SetAsBigInt;
    property AsFloat[_Path: String]: Double read GetAsFloat write SetAsFloat;
    property AsDateTime[_Path: String]: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsGUID[_Path: String]: TGUID read GetAsGUID write SetAsGUID;
    property AsAnsiString[_Path: String]: AnsiString read GetAsAnsiString write SetAsAnsiString;
    property AsString[_Path: String]: String read GetAsString write SetAsString;
    property AsBLOB[_Path: String]: BLOB read GetAsBLOB write SetAsBLOB;
    property AsParams[_Path: String]: TParams read GetAsParams;
    { v ������� � �������� ��� �������� ������ v }

  end;

  EParamsException = class(ECoreException);

function ParamDataTypeToStr(Value: TParamDataType): String;
function StrToParamDataType(Value: String): TParamDataType;
{ TODO -oVasilyevSM -cParamsToStr: � ������� ParamsToStr ����� ��� ���� �����, ����� �������� ���� ��������� � ���-�����
  ��� ��� ����. � ����� ��� ���������� ��� ������ �������������� ������������ � ���������� ����� ����� �������
  RegisterParam. ����� �������, ����� ��� ������� ���-�����, ������ � �������. � StrToParams ����� ����� ������ �� ����
  �������� ������ ��������� � ������� ����������. ����� ��� ������ ����������� �������, ���� �������� � �� �������
  �������� � ������. }
function ParamsToStr(Params: TParams; SingleString: Boolean = False): String;
procedure StrToParams(const Value: String; Params: TParams);

implementation

type

  TParamsReader = class

  strict private

    FParams: TParams;
    FParser: TParamsStringParser;

    FCurrentName: String;
    FCurrentType: TParamDataType;

    procedure WriteName(const _Value: String);
    procedure WriteType(const _Value: String);
    procedure WriteValue(const _Value: String);
    procedure WriteParams(const _KeyWord: TKeyWord);
    function CurrentTypeIsParams: Boolean;

    procedure CheckPresetType;
    function TrimDigital(const _Value: String): String;
    function UndoubleSymbols(const _Value: String): String;

  private

    constructor Create(const _Source: String; _Params: TParams);
    constructor CreateNested(

        _MasterParser: TParamsStringParser;
        _Params: TParams;
        _CursorShift: Int64

    );

    destructor Destroy; override;

    procedure Read;

    property Parser: TParamsStringParser read FParser;

  end;

function ParamDataTypeToStr(Value: TParamDataType): String;
const

  SA_StringValues: array[TParamDataType] of String = (

      { dtUnknown    } 'Unknown',
      { dtBoolean    } 'Boolean',
      { dtInteger    } 'Integer',
      { dtBigInt     } 'BigInt',
      { dtFloat      } 'Float',
      { dtDateTime   } 'DateTime',
      { dtGUID       } 'GUID',
      { dtAnsiString } 'AnsiString',
      { dtString     } 'String',
      { dtBLOB       } 'BLOB',
      { dtParams     } 'Params'

  );

begin
  Result := SA_StringValues[Value];
end;

function StrToParamDataType(Value: String): TParamDataType;
var
  Item: TParamDataType;
begin

  for Item := Low(TParamDataType) to High(TParamDataType) do
    if SameText(ParamDataTypeToStr(Item), Value) then
      Exit(Item);

  raise EConvertError.CreateFmt('%s is not a TParamDataType value', [Value]);

end;

function ParamsToStr(Params: TParams; SingleString: Boolean): String;
const

  SC_SingleParamMultiStringFormat = '%s: %s = %s' + CRLF;
  SC_SingleParamSingleStringFormat = '%s: %s = %s;';

  SC_NestedParamsMultiStringFormat =

      '%s: %s = (' + CRLF +
      '%s' +
      ')' + CRLF;

  SC_NestedParamsSingleStringFormat =

      '%s: %s = (%s);';

  function _NestedParamsFormat: String;
  begin
    if SingleString then Result := SC_NestedParamsSingleStringFormat
    else Result := SC_NestedParamsMultiStringFormat;
  end;

  function _SingleParamFormat: String;
  begin
    if SingleString then Result := SC_SingleParamSingleStringFormat
    else Result := SC_SingleParamMultiStringFormat;
  end;

  function _GetNested(_Param: TParam): String;
  begin
    Result := ParamsToStr(_Param.AsParams, SingleString);
    if not SingleString then ShiftText(1, Result);
  end;

  function _QuoteString(_Param: TParam): String;
  begin

    Result := _Param.AsString;

    if

        (_Param.DataType = dtString) and
        { ��������� � ������� �� �������������. ��� ������ ������ � ����� ���������: }
        (
            (Pos(CR,   Result) > 0) or
            (Pos(LF,   Result) > 0) or
            (Pos(';',  Result) > 0) or
            (Pos('''', Result) > 0) or
            (Pos('"',  Result) > 0)

        )

    then Result := QuoteStr(Result);

  end;

var
  Param: TParam;
begin

  Result := '';
  for Param in Params do

    if Param.DataType = dtParams then

      Result := Result + Format(_NestedParamsFormat, [

          Param.Name,
          ParamDataTypeToStr(Param.DataType),
          _GetNested(Param)

      ])

    else

      Result := Result + Format(_SingleParamFormat, [

          Param.Name,
          ParamDataTypeToStr(Param.DataType),
          _QuoteString(Param)

      ]);

  if SingleString then CutStr(Result, 1);

end;

procedure StrToParams(const Value: String; Params: TParams);
begin

  with TParamsReader.Create(Value, Params) do

    try

      Read;

    finally
      Free;
    end;

end;

{ TParam }

constructor TParam.Create;
begin

  inherited Create;

  FIsNull := True;
  ValidateName(_Name);
  FName := _Name;

end;

destructor TParam.Destroy;
begin
  FreeData;
  inherited Destroy;
end;

function TParam.GetAsBoolean: Boolean;
begin

  CheckDataType(dtBoolean);

  if IsNull then Result := False
  else Move(FData^, Result, DataSize);

end;

function TParam.GetAsInteger: Integer;
begin

  CheckDataType(dtInteger);

  if IsNull then Result := 0
  else Move(FData^, Result, DataSize);

end;

function TParam.GetAsBigInt: Int64;
begin

  CheckDataType(dtBigInt);

  if IsNull then Result := 0
  else Move(FData^, Result, DataSize);

end;

function TParam.GetAsFloat: Double;
begin

  CheckDataType(dtFloat);

  if IsNull then Result := 0
  else Move(FData^, Result, DataSize);

end;

function TParam.GetAsDateTime: TDateTime;
begin

  CheckDataType(dtDateTime);

  if IsNull then Result := 0
  else Move(FData^, Result, DataSize);

end;

function TParam.GetAsGUID: TGUID;
begin

  CheckDataType(dtGUID);

  if IsNull then Result := NullGUID
  else Move(FData^, Result, DataSize);

end;

function TParam.GetAsAnsiString: AnsiString;
begin
  CheckDataType(dtAnsiString);
  Result := AnsiString(FData);
end;

function TParam.GetAsString: String;
begin

  {

    ���� ����� ������. �� ����� ��� ��� ���������� ���������� �����, �������� ���������� ������������ ����� � �����
    �������� ����, ��� � ��� ����������. ����� � ���� ������ ������� � ��������� ���-��, ������� ����������� ���.
    ��������, ���� ��� GUID. ������� ����� �������� ���� ������ �� ����. ����� ���������� ��������� ���.

  }

  if IsNull then Result := ''
  else

    case FDataType of

      dtUnknown:    Result := '';
      dtBoolean:    Result := BooleanToStr       (AsBoolean  );
      dtInteger:    Result := IntToStr           (AsInteger  );
      dtBigInt:     Result := BigIntToStr        (AsBigInt   );
      dtFloat:      Result := DoubleToStr        (AsFloat    );
      dtDateTime:   Result := DateTimeToStr      (AsDateTime );
      dtGUID:       Result := GUIDToStr          (AsGUID     );
      dtAnsiString: Result := String(AnsiString  (FData     ));
      dtString:     Result := String             (FData      );
      dtBLOB:       Result := BLOBToHexStr       (AsBLOB     );
      dtParams:     Result := ParamsToStr(TParams(FData     ));

    else
      raise EUncomplitedMethod.Create;
    end;

end;

function TParam.GetAsBLOB: RawByteString;
begin
  CheckDataType(dtBLOB);
  Result := RawByteString(FData);
end;

function TParam.GetAsParams: TParams;
begin
  CheckDataType(dtParams);
  Result := TParams(FData);
end;

procedure TParam.SetAsBoolean(_Value: Boolean);
begin
  PresetData(dtBoolean);
  Move(_Value, FData^, DataSize);
end;

procedure TParam.SetAsInteger(_Value: Integer);
begin
  PresetData(dtInteger);
  Move(_Value, FData^, DataSize);
end;

procedure TParam.SetAsBigInt(_Value: Int64);
begin
  PresetData(dtBigInt);
  Move(_Value, FData^, DataSize);
end;

procedure TParam.SetAsFloat(_Value: Double);
begin
  PresetData(dtFloat);
  Move(_Value, FData^, DataSize);
end;

procedure TParam.SetAsDateTime(_Value: TDateTime);
begin
  PresetData(dtDateTime);
  Move(_Value, FData^, DataSize);
end;

procedure TParam.SetAsGUID(const _Value: TGUID);
begin
  PresetData(dtGUID);
  Move(_Value, FData^, DataSize);
end;

procedure TParam.SetAsAnsiString(const _Value: AnsiString);
begin
  PresetData(dtAnsiString);
  AnsiString(FData) := _Value;
end;

procedure TParam.SetAsString(const _Value: String);
begin
  PresetData(dtString);
  String(FData) := _Value;
end;

procedure TParam.SetAsBLOB(const _Value: RawByteString);
begin
  PresetData(dtBLOB);
  RawByteString(FData) := _Value;
end;

procedure TParam.SetAsParams(_Value: TParams);
begin
  PresetData(dtParams);
  TParams(FData) := _Value;
end;

procedure TParam.SetIsNull(const _Value: Boolean);
begin

  if _Value <> FIsNull then begin

    FIsNull := _Value;
    FreeData;

  end;

end;

class procedure TParam.ValidateName(const _Value: String);
const
  SC_PARAM_NAME_FORBIDDEN_CHARS = [' '];
var
  i: Integer;
begin

  if Length(_Value) = 0 then
    raise EParamsReadException.Create('Empty param name');

  for i := 1 to Length(_Value) do
    if not CharInSet(_Value[i], SC_TYPED_CHARS) then
      raise EParamsException.CreateFmt('Character #%d in invalid in param name ''%s''', [Ord(_Value[i]), _Value]);

  for i := 1 to Length(_Value) do
    if CharInSet(_Value[i], SC_PARAM_NAME_FORBIDDEN_CHARS) then
      raise EParamsException.CreateFmt('Character ''%s'' in invalid in param name ''%s''', [_Value[i], _Value]);

end;

procedure TParam.AllocData;
begin
  if not (DataType in ([dtUnknown] + SC_SELF_ALLOCATED_TYPES)) then
    FData := AllocMem(DataSize);
end;

procedure TParam.FreeData;
begin

  { ������� ���� ������� ����������� ���������� }
  if DataType = dtParams then
    TParams(FData).Free;

  if not (DataType in ([dtUnknown] + SC_SELF_ALLOCATED_TYPES)) then
    FreeMemory(FData);

  { ������ ����� ������������� ���. }
  case FDataType of

    dtAnsiString: AnsiString(FData)    := '';
    dtString:     String(FData)        := '';
    dtBLOB:       RawByteString(FData) := '';

  end;

  FData := nil;

end;

function TParam.DataSize: Cardinal;
begin

  case FDataType of

    dtUnknown:    Result := 0;
    dtBoolean:    Result := SizeOf(Boolean);
    dtInteger:    Result := SizeOf(Integer);
    dtBigInt:     Result := SizeOf(Int64);
    dtFloat:      Result := SizeOf(Double);
    dtDateTime:   Result := SizeOf(TDateTime);
    dtAnsiString: Result := 0;
    dtString:     Result := 0;
    dtGUID:       Result := SizeOf(TGUID);
    dtBLOB:       Result := 0;
    dtParams:     Result := SizeOf(TObject);

  else
    raise EUncomplitedMethod.Create;
  end;

end;

procedure TParam.PresetData(_DataType: TParamDataType);
begin

  FreeData;

  FDataType := _DataType;
  FIsNull := False;

  AllocData;

end;

procedure TParam.CheckDataType(_DataType: TParamDataType);
begin

  if FDataType <> _DataType then

    raise EParamsException.CreateFmt('Unable to read data type %s as %s', [

        ParamDataTypeToStr(FDataType),
        ParamDataTypeToStr(_DataType)

    ]);

end;

procedure TParam.Assign(_Source: TParam);
begin

  case _Source.DataType of

    dtBoolean:    AsBoolean    := _Source.AsBoolean;
    dtInteger:    AsInteger    := _Source.AsInteger;
    dtBigInt:     AsBigInt     := _Source.AsBigInt;
    dtFloat:      AsFloat      := _Source.AsFloat;
    dtDateTime:   AsDateTime   := _Source.AsDateTime;
    dtGUID:       AsGUID       := _Source.AsGUID;
    dtAnsiString: AsAnsiString := _Source.AsAnsiString;
    dtString:     AsString     := _Source.AsString;
    dtBLOB:       AsBLOB       := _Source.AsBLOB;
    dtParams:     AsParams.Assign(_Source.AsParams);

  else
    raise EUncomplitedMethod.Create;
  end;

end;

procedure TParam.Clear;
begin

  FreeData;
  FIsNull := True;
  FDataType := dtUnknown;

end;

{ TParamHelper }

function TParamHelper._GetAsBoolean: Boolean;
begin

  if StrictDataType then Result := GetAsBoolean
  else

    case DataType of

      dtInteger:    Result := IntToBoolean(AsInteger);
      dtBigInt:     Result := IntToBoolean(AsBigInt);
      dtAnsiString: Result := StrToBoolean(String(AsAnsiString));
      dtString:     Result := StrToBoolean(AsString);
      dtBLOB:       Result := BLOBToBoolean(AsBLOB);

    else
      Result := GetAsBoolean;
    end;

end;

function TParamHelper._GetAsInteger: Integer;
begin

  if StrictDataType then Result := GetAsInteger
  else

    case DataType of

      dtBoolean:    Result := BooleanToInt(AsBoolean);
      dtBigInt:     Result := AsBigInt;
      dtAnsiString: Result := StrToInt(String(AsAnsiString));
      dtString:     Result := StrToInt(AsString);
      dtBLOB:       raise EUncomplitedMethod.Create;

    else
      Result := GetAsInteger;
    end;

end;

function TParamHelper._GetAsBigInt: Int64;
begin

  if StrictDataType then Result := GetAsBigInt
  else

    case DataType of

      dtBoolean:    Result := BooleanToInt(AsBoolean);
      dtInteger:    Result := AsInteger;
      dtAnsiString: Result := StrToBigInt(String(AsAnsiString));
      dtString:     Result := StrToBigInt(AsString);
      dtBLOB:       raise EUncomplitedMethod.Create;

    else
      Result := GetAsBigInt;
    end;

end;

procedure TParamHelper._SetAsBoolean(const _Value: Boolean);
begin
  SetAsBoolean(_Value);
end;

procedure TParamHelper._SetAsInteger(const _Value: Integer);
begin
  SetAsInteger(_Value);
end;

procedure TParamHelper._SetAsBigInt(const _Value: Int64);
begin
  SetAsBigInt(_Value);
end;

{ TParams }

function TParams.GetParam(_Path: String): TParam;
var
  SingleName: String;
  Params: TParams;
  Param: TParam;
begin

  Params := Self;

  while Pos('.', _Path) > 0 do begin

    SingleName := ReadStrTo(_Path, '.', False);

    if Params.FindParam(SingleName, dtParams, Param) then Params := Param.AsParams
    else

      with Params.Add(SingleName) do begin

        SetAsParams(TParams.Create);
        Params := AsParams;

      end;

  end;

  {

    ��� ����������� ������������� �������� ������ ��������� �� ������������ ������ ��� �����. ���������� �
    ������������������� ������ ������ ���������� � ��������. �������, ������ Add.

  }
  Result := Params.Add(_Path);

end;

function TParams.GetAsBoolean(const _Path: String): Boolean;
begin
  Result := ParamByName(_Path).AsBoolean;
end;

function TParams.GetAsInteger(const _Path: String): Integer;
begin
  Result := ParamByName(_Path).AsInteger;
end;

function TParams.GetAsBigInt(const _Path: String): Int64;
begin
  Result := ParamByName(_Path).AsBigInt;
end;

function TParams.GetAsFloat(_Path: String): Double;
begin
  Result := ParamByName(_Path).AsFloat;
end;

function TParams.GetAsDateTime(_Path: String): TDateTime;
begin
  Result := ParamByName(_Path).AsDateTime;
end;

function TParams.GetAsGUID(_Path: String): TGUID;
begin
  Result := ParamByName(_Path).AsGUID;
end;

function TParams.GetAsAnsiString(_Path: String): AnsiString;
begin
  Result := ParamByName(_Path).AsAnsiString;
end;

function TParams.GetAsString(_Path: String): String;
begin
  Result := ParamByName(_Path).AsString;
end;

function TParams.GetAsBLOB(_Path: String): BLOB;
begin
  Result := ParamByName(_Path).AsBLOB;
end;

function TParams.GetAsParams(_Path: String): TParams;
begin
  Result := ParamByName(_Path).AsParams;
end;

procedure TParams.SetAsBoolean(const _Path: String; _Value: Boolean);
begin
  GetParam(_Path).AsBoolean := _Value;
end;

procedure TParams.SetAsInteger(const _Path: String; _Value: Integer);
begin
  GetParam(_Path).AsInteger := _Value;
end;

procedure TParams.SetAsBigInt(const _Path: String; _Value: Int64);
begin
  GetParam(_Path).AsBigInt := _Value;
end;

procedure TParams.SetAsFloat(_Path: String; _Value: Double);
begin
  GetParam(_Path).AsFloat := _Value;
end;

procedure TParams.SetAsDateTime(_Path: String; _Value: TDateTime);
begin
  GetParam(_Path).AsDateTime := _Value;
end;

procedure TParams.SetAsGUID(_Path: String; const _Value: TGUID);
begin
  GetParam(_Path).AsGUID := _Value;
end;

procedure TParams.SetAsAnsiString(_Path: String; const _Value: AnsiString);
begin
  GetParam(_Path).AsAnsiString := _Value;
end;

procedure TParams.SetAsString(_Path: String; const _Value: String);
begin
  GetParam(_Path).AsString := _Value;
end;

procedure TParams.SetAsBLOB(_Path: String; const _Value: BLOB);
begin
  GetParam(_Path).AsBLOB := _Value;
end;

procedure TParams.SetAsParams(_Path: String; _Value: TParams);
begin
  GetParam(_Path).SetAsParams(_Value);
end;

procedure TParams.Notify(const _Item: TParam; _Action: Generics.Collections.TCollectionNotification);
begin

  if (_Action = cnRemoved) and (_Item.DataType = dtParams) then
    _Item.Clear;

  inherited Notify(_Item, _Action);

end;

procedure TParams.Assign(_Source: TParams);
var
  Src, Dst: TParam;
begin

  for Src in _Source do begin

    if not FindParam(Src.Name, Src.DataType, Dst) then begin

      Dst := Add(Src.Name);
      if Src.DataType = dtParams then
        Dst.SetAsParams(TParams.Create);

    end;

    Dst.Assign(Src);

  end;

end;

function TParams.Add(const _Name: String): TParam;
begin
  Result := TParam.Create(_Name);
  inherited Add(Result);
end;

function TParams.Insert(_Index: Integer; const _Name: String): TParam;
begin
  Result := TParam.Create(_Name);
  inherited Insert(_Index, Result);
end;

function TParams.FindParam(_Path: String; _DataType: TParamDataType; var _Value: TParam): Boolean;
var
  SingleName: String;
  Params: TParams;
  Param: TParam;
begin

  Params := Self;

  while Pos('.', _Path) > 0 do begin

    SingleName := ReadStrTo(_Path, '.', False);

    if Params.FindParam(SingleName, dtParams, Param) then

      Params := Param.AsParams

    else Exit(False);

  end;

  for Param in Params do

    if

        SameText(Param.Name, _Path) and
        ((_DataType = dtUnknown) or (Param.DataType = _DataType))

    then begin

      _Value := Param;
      Exit(True);

    end;

  Result := False;

end;

function TParams.FindParam(_Path: String; var _Value: TParam): Boolean;
begin
  Result := FindParam(_Path, dtUnknown, _Value);
end;

function TParams.ParamByName(const _Path: String): TParam;
begin
  if not FindParam(_Path, Result) then
    raise EParamsException.CreateFmt('Param %s not found', [_Path]);
end;

function TParams.FindBoolean(const _Path: String; var _Value: Boolean): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, dtBoolean, P);
  if Result then _Value := P.AsBoolean;
end;

function TParams.FindInteger(const _Path: String; var _Value: Integer): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, dtInteger, P);
  if Result then _Value := P.AsInteger;
end;

function TParams.FindBigInt(const _Path: String; var _Value: Int64): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, dtBigInt, P);
  if Result then _Value := P.AsBigInt;
end;

function TParams.FindFloat(const _Path: String; var _Value: Double): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, dtFloat, P);
  if Result then _Value := P.AsFloat;
end;

function TParams.FindDateTime(const _Path: String; var _Value: TDateTime): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, dtDateTime, P);
  if Result then _Value := P.AsDateTime;
end;

function TParams.FindGUID(const _Path: String; var _Value: TGUID): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, dtGUID, P);
  if Result then _Value := P.AsGUID;
end;

function TParams.FindAnsiString(const _Path: String; var _Value: AnsiString): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, dtAnsiString, P);
  if Result then _Value := P.AsAnsiString;
end;

function TParams.FindString(const _Path: String; var _Value: String): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, dtString, P);
  if Result then _Value := P.AsString;
end;

function TParams.FindBLOB(const _Path: String; var _Value: BLOB): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, dtBLOB, P);
  if Result then _Value := P.AsBLOB;
end;

function TParams.FindParams(const _Path: String; var _Value: TParams): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, dtParams, P);
  if Result then _Value := P.AsParams;
end;

function TParams.AsBooleanDef(const _Path: String; _Default: Boolean): Boolean;
begin
  if not FindBoolean(_Path, Result) then AsBoolean[_Path] := _Default;
  Result := _Default;
end;

function TParams.AsIntegerDef(const _Path: String; _Default: Integer): Integer;
begin
  if not FindInteger(_Path, Result) then AsInteger[_Path] := _Default;
  Result := _Default;
end;

function TParams.AsBigIntDef(const _Path: String; _Default: Int64): Int64;
begin
  if not FindBigInt(_Path, Result) then AsBigInt[_Path] := _Default;
  Result := _Default;
end;

function TParams.AsFloatDef(const _Path: String; _Default: Double): Double;
begin
  if not FindFloat(_Path, Result) then AsFloat[_Path] := _Default;
  Result := _Default;
end;

function TParams.AsDateTimeDef(const _Path: String; _Default: TDateTime): TDateTime;
begin
  if not FindDateTime(_Path, Result) then AsDateTime[_Path] := _Default;
  Result := _Default;
end;

function TParams.AsGUIDDef(const _Path: String; _Default: TGUID): TGUID;
begin
  if not FindGUID(_Path, Result) then AsGUID[_Path] := _Default;
  Result := _Default;
end;

function TParams.AsAnsiStringDef(const _Path: String; _Default: AnsiString): AnsiString;
begin
  if not FindAnsiString(_Path, Result) then AsAnsiString[_Path] := _Default;
  Result := _Default;
end;

function TParams.AsStringDef(const _Path: String; _Default: String): String;
begin
  if not FindString(_Path, Result) then AsString[_Path] := _Default;
  Result := _Default;
end;

function TParams.AsBLOBDef(const _Path: String; _Default: BLOB): BLOB;
begin
  if not FindBLOB(_Path, Result) then AsBLOB[_Path] := _Default;
  Result := _Default;
end;

{ TParamsReader }

procedure TParamsReader.CheckPresetType;
var
  P: TParam;
begin

  { ������������ ������� ��� ������ }
  if

      (FCurrentType = dtUnknown) and
      FParams.FindParam(FCurrentName, P) and
      (P.DataType <> dtUnknown)

  then FCurrentType := P.DataType;

  if FCurrentType = dtUnknown then
    raise EParamsReadException.Create('Unknown param data type');

end;

constructor TParamsReader.Create(const _Source: String; _Params: TParams);
begin

  inherited Create;

  FParams := _Params;
  FParser := TParamsStringParser.Create(

      _Source,
      TReaderWrapper.Create(

          WriteName,
          WriteType,
          WriteValue,
          WriteParams,
          CurrentTypeIsParams

      )

  );

end;

constructor TParamsReader.CreateNested;
begin

  inherited Create;

  FParams       := _Params;
  FParser       := TParamsStringParser.CreateNested(

      _MasterParser,
      _CursorShift,
      TReaderWrapper.Create(

          WriteName,
          WriteType,
          WriteValue,
          WriteParams,
          CurrentTypeIsParams

      )

  );

end;

function TParamsReader.CurrentTypeIsParams: Boolean;
begin
  Result := FCurrentType = dtParams;
end;

destructor TParamsReader.Destroy;
begin
  FreeAndNil(FParser);
  inherited Destroy;
end;

procedure TParamsReader.Read;
begin
  FParser.Read;
end;

function TParamsReader.TrimDigital(const _Value: String): String;
begin
  Result := StringReplace(_Value, ' ', '', [rfReplaceAll]);
end;

function TParamsReader.UndoubleSymbols(const _Value: String): String;
begin
  if Assigned(FParser) then
    Result := FParser.UndoubleSymbols(_Value);
end;

procedure TParamsReader.WriteName(const _Value: String);
begin
  TParam.ValidateName(_Value);
  FCurrentName := _Value;
end;

procedure TParamsReader.WriteType(const _Value: String);
begin
  FCurrentType := StrToParamDataType(_Value);
  CheckPresetType;
end;

procedure TParamsReader.WriteValue(const _Value: String);
begin

  { ����� ����� ��� ��������. ��� ����� �� ��������� � ������ � ��� ������ �� �����. ����� ����������� ��� �����. }
  CheckPresetType;

  case FCurrentType of

    dtBoolean:    FParams.AsBoolean   [FCurrentName] := StrToBoolean(           _Value );
    dtInteger:    FParams.AsInteger   [FCurrentName] := StrToInt(   TrimDigital(_Value));
    dtBigInt:     FParams.AsBigInt    [FCurrentName] := StrToBigInt(TrimDigital(_Value));
    dtFloat:      FParams.AsFloat     [FCurrentName] := StrToDouble(TrimDigital(_Value));
    dtDateTime:   FParams.AsDateTime  [FCurrentName] := StrToDateTime(          _Value );
    dtGUID:       FParams.AsGUID      [FCurrentName] := StrToGUID(              _Value );
    dtAnsiString: FParams.AsAnsiString[FCurrentName] := AnsiString(             _Value );
    dtString:     FParams.AsString    [FCurrentName] := UndoubleSymbols(        _Value );
    dtBLOB:       FParams.AsBLOB      [FCurrentName] := HexStrToBLOB(           _Value );

  end;

  FCurrentName := '';
  FCurrentType := dtUnknown;

end;

procedure TParamsReader.WriteParams(const _KeyWord: TKeyWord);
var
  P: TParams;
  Nested: TParamsReader;
  NestedCursor: Int64;
begin

  P := TParams.Create;
  try

    Nested := TParamsReader.CreateNested(FParser, P, _KeyWord.KeyLength);

    try

      Nested.Read;

    finally

      NestedCursor := Nested.Parser.Cursor;

      FParser.Move(NestedCursor - _KeyWord.KeyLength - FParser.Cursor);
      FParser.Location := Nested.Parser.Location;

      Nested.Free;

    end;

  finally

    FParams.SetAsParams(FCurrentName, P);

    FParser.CompleteItem;
    FCurrentName := '';
    FCurrentType := dtUnknown;

  end;

end;

end.
