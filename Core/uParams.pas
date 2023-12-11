unit uParams;

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
  uConsts, uTypes, uCore, uDataUtils, uStrUtils, uCustomStringParser, uParamsStringParser;

type

  TParamDataType = (

      dtUnknown, dtBoolean, dtInteger, dtBigInt, dtFloat, dtExtended, dtDateTime, dtGUID, dtAnsiString, dtString,
      dtBLOB, dtData, dtParams

  );

  TParams = class;

  TParam = class

  const

    SC_SELF_ALLOCATED_TYPES = [dtAnsiString, dtString, dtBLOB, dtData, dtParams];

  strict private

    FName: String;
    FDataType: TParamDataType;
    FIsNull: Boolean;
    FPathSeparator: Char;
    FStrictDataType: Boolean;
    { TODO -oVasilyevSM -cTParam: Наверное, более современным способом было бы использовать дженерик здесь. Класс
      TValue<T>, и пересоздавать его при смене типа данных. А как он там будет с памятью орудовать - не наша проблема. }
    FData: Pointer;

    procedure SetIsNull(const _Value: Boolean);

    procedure AllocData;
    procedure FreeData;
    function DataSize: Cardinal;

    procedure CheckDataType(_DataType: TParamDataType);
    procedure PresetData(_DataType: TParamDataType);

  private

    procedure SetDataType(_Value: TParamDataType);

    { v Using FData methods v }
    function GetAsBoolean: Boolean;
    function GetAsInteger: Integer;
    function GetAsBigInt: Int64;
    function GetAsFloat: Double;
    function GetAsExtended: Extended;
    function GetAsDateTime: TDateTime;
    function GetAsGUID: TGUID;
    function GetAsAnsiString: AnsiString;
    function GetAsString: String;
    function GetAsBLOB: BLOB;
    function GetAsData: TData;
    function GetAsParams: TParams;

    procedure SetAsBoolean(_Value: Boolean);
    procedure SetAsInteger(_Value: Integer);
    procedure SetAsBigInt(_Value: Int64);
    procedure SetAsFloat(_Value: Double);
    procedure SetAsExtended(_Value: Extended);
    procedure SetAsDateTime(_Value: TDateTime);
    procedure SetAsGUID(const _Value: TGUID);
    procedure SetAsAnsiString(const _Value: AnsiString);
    procedure SetAsString(const _Value: String);
    procedure SetAsBLOB(const _Value: BLOB);
    procedure SetAsData(const _Value: TData);
    procedure SetAsParams(_Value: TParams);
    { ^ Using FData methods ^ }

    procedure Clear;
    class procedure ValidateName(const _Value, _PathSeparator: String);

    property StrictDataType: Boolean read FStrictDataType write FStrictDataType;

    { Если хэлпер надоест, чтобы далеко не лазить за этими свойствами. }
//    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
//    property AsInteger: Integer read GetAsInteger write SetAsInteger;
//    property AsBigInt: Int64 read GetAsBigInt write SetAsBigInt;
//    property AsFloat: Double read GetAsFloat write SetAsFloat;
//    property AsExtended: Extended read GetAsExtended write SetAsExtended;
//    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
//    property AsGUID: TGUID read GetAsGUID write SetAsGUID;
//    property AsAnsiString: AnsiString read GetAsAnsiString write SetAsAnsiString;
//    property AsString: String read GetAsString write SetAsString;
//    property AsBLOB: BLOB read GetAsBLOB write SetAsBLOB;
//    property AsData: TData read GetAsData write SetAsData;

    property AsParams: TParams read GetAsParams;

  protected

    constructor Create(const _Name: String; const _PathSeparator: Char = '.'); virtual;

    { Для передачи без разбора типов }
    procedure AssignValue(_Source: TParam; _Host: TParams; _ForceAdding: Boolean); virtual;

  public

    destructor Destroy; override;

    property Name: String read FName;
    property DataType: TParamDataType read FDataType;
    property IsNull: Boolean read FIsNull write SetIsNull;

  end;

  TParamClass = class of TParam;

  TParamHelper = class helper for TParam

  strict private

    function _GetAsBoolean: Boolean;
    function _GetAsInteger: Integer;
    function _GetAsBigInt: Int64;
    function _GetAsFloat: Double;
    function _GetAsExtended: Extended;
    function _GetAsDateTime: TDateTime;
    function _GetAsGUID: TGUID;
    function _GetAsAnsiString: AnsiString;
    function _GetAsString: String;
    function _GetAsBLOB: BLOB;
    function _GetAsData: TData;

    procedure _SetAsBoolean(const _Value: Boolean);
    procedure _SetAsInteger(const _Value: Integer);
    procedure _SetAsBigInt(const _Value: Int64);
    procedure _SetAsFloat(const _Value: Double);
    procedure _SetAsExtended(const _Value: Extended);
    procedure _SetAsDateTime(const _Value: TDateTime);
    procedure _SetAsGUID(const _Value: TGUID);
    procedure _SetAsAnsiString(const _Value: AnsiString);
    procedure _SetAsString(const _Value: String);
    procedure _SetAsBLOB(const _Value: BLOB);
    procedure _SetAsData(const _Value: TData);

  private

    property AsBoolean: Boolean read _GetAsBoolean write _SetAsBoolean;
    property AsInteger: Integer read _GetAsInteger write _SetAsInteger;
    property AsBigInt: Int64 read _GetAsBigInt write _SetAsBigInt;
    property AsFloat: Double read _GetAsFloat write _SetAsFloat;
    property AsExtended: Extended read _GetAsExtended write _SetAsExtended;
    property AsDateTime: TDateTime read _GetAsDateTime write _SetAsDateTime;
    property AsGUID: TGUID read _GetAsGUID write _SetAsGUID;
    property AsAnsiString: AnsiString read _GetAsAnsiString write _SetAsAnsiString;
    property AsString: String read _GetAsString write _SetAsString;
    property AsBLOB: BLOB read _GetAsBLOB write _SetAsBLOB;
    property AsData: TData read _GetAsData write _SetAsData;

  end;

  TSaveToStringOption  = (soSingleString, soForceQuoteStrings, soTypesFree);
  TSaveToStringOptions = set of TSaveToStringOption;

  TParamsReader = class;
  TParamsReaderClass = class of TParamsReader;

  TParams = class

  strict private

  type

    TMultiParamList = class

    strict private

      FName: String;
      FParams: TParams;

      function CreateNewParam: TParam;

      function GetCount: Integer;
      function GetItems(_Index: Integer): TParam;

      function GetDataType(_Index: Integer): TParamDataType;
      function GetIsNull(_Index: Integer): Boolean;

      function GetAsBoolean(_Index: Integer): Boolean;
      function GetAsInteger(_Index: Integer): Integer;
      function GetAsBigInt(_Index: Integer): Int64;
      function GetAsFloat(_Index: Integer): Double;
      function GetAsExtended(_Index: Integer): Extended;
      function GetAsDateTime(_Index: Integer): TDateTime;
      function GetAsGUID(_Index: Integer): TGUID;
      function GetAsAnsiString(_Index: Integer): AnsiString;
      function GetAsString(_Index: Integer): String;
      function GetAsBLOB(_Index: Integer): BLOB;
      function GetAsData(_Index: Integer): TData;

      procedure SetIsNull(_Index: Integer; const _Value: Boolean);

      procedure SetAsBoolean(_Index: Integer; const _Value: Boolean);
      procedure SetAsInteger(_Index: Integer; const _Value: Integer);
      procedure SetAsBigInt(_Index: Integer; const _Value: Int64);
      procedure SetAsFloat(_Index: Integer; const _Value: Double);
      procedure SetAsExtended(_Index: Integer; const _Value: Extended);
      procedure SetAsDateTime(_Index: Integer; const _Value: TDateTime);
      procedure SetAsGUID(_Index: Integer; const _Value: TGUID);
      procedure SetAsAnsiString(_Index: Integer; const _Value: AnsiString);
      procedure SetAsString(_Index: Integer; const _Value: String);
      procedure SetAsBLOB(_Index: Integer; const _Value: BLOB);
      procedure SetAsData(_Index: Integer; const _Value: TData);

      function InternalIndex(_Index: Integer): Integer;
      function ExternalIndex(_InternalIndex: Integer): Integer;

    private

      constructor Create(const _Name: String; _Params: TParams);

      procedure SetDataType(_Index: Integer; const _Value: TParamDataType);

      property Name: String read FName;
      property Items[_Index: Integer]: TParam read GetItems; default;

    public

      function Insert(_Index: Integer): Integer;
      function Append: Integer;
      procedure Delete(_Index: Integer);

      property Count: Integer read GetCount;

      property DataType[_Index: Integer]: TParamDataType read GetDataType;
      property IsNull[_Index: Integer]: Boolean read GetIsNull write SetIsNull;

      property AsBoolean[_Index: Integer]: Boolean read GetAsBoolean write SetAsBoolean;
      property AsInteger[_Index: Integer]: Integer read GetAsInteger write SetAsInteger;
      property AsBigInt[_Index: Integer]: Int64 read GetAsBigInt write SetAsBigInt;
      property AsFloat[_Index: Integer]: Double read GetAsFloat write SetAsFloat;
      property AsExtended[_Index: Integer]: Extended read GetAsExtended write SetAsExtended;
      property AsDateTime[_Index: Integer]: TDateTime read GetAsDateTime write SetAsDateTime;
      property AsGUID[_Index: Integer]: TGUID read GetAsGUID write SetAsGUID;
      property AsAnsiString[_Index: Integer]: AnsiString read GetAsAnsiString write SetAsAnsiString;
      property AsString[_Index: Integer]: String read GetAsString write SetAsString;
      property AsBLOB[_Index: Integer]: BLOB read GetAsBLOB write SetAsBLOB;
      property AsData[_Index: Integer]: TData read GetAsData write SetAsData;


    end;

    TParamsListHolder = class(TObjectList<TMultiParamList>)

    private

      function Find(const _Name: String; var _ParamList: TMultiParamList): Boolean;
      function Add(const _Name: String; _Params: TParams): TMultiParamList;
      function Get(const _Name: String; _Params: TParams): TMultiParamList;

    end;

    TParamList = class(TObjectList<TParam>)

    protected

      procedure Notify(const _Item: TParam; _Action: Generics.Collections.TCollectionNotification); override;

    end;

  strict private

    FPathSeparator: Char;
    FSaveToStringOptions: TSaveToStringOptions;
    FItems: TParamList;
    FListHolder: TParamsListHolder;

    function Add(const _Name: String): TParam;

    function FindPath(var _Path: String; var _Params: TParams): Boolean;
    function GetPath(var _Path: String): TParams;
    function ParamByName(const _Path: String): TParam;

    function GetList(const _Path: String): TMultiParamList;
    function GetCount: Integer;

  private

    function CreateNewParam(const _Name: String): TParam;

    function GetIsNull(const _Path: String): Boolean;
    function GetAsBoolean(const _Path: String): Boolean;
    function GetAsInteger(const _Path: String): Integer;
    function GetAsBigInt(const _Path: String): Int64;
    function GetAsFloat(const _Path: String): Double;
    function GetAsExtended(const _Path: String): Extended;
    function GetAsDateTime(const _Path: String): TDateTime;
    function GetAsGUID(const _Path: String): TGUID;
    function GetAsAnsiString(const _Path: String): AnsiString;
    function GetAsString(const _Path: String): String;
    function GetAsBLOB(const _Path: String): BLOB;
    function GetAsData(const _Path: String): TData;
    function GetAsParams(const _Path: String): TParams;

    procedure SetIsNull(const _Path: String; const _Value: Boolean);
    procedure SetAsBoolean(const _Path: String; _Value: Boolean);
    procedure SetAsInteger(const _Path: String; _Value: Integer);
    procedure SetAsBigInt(const _Path: String; _Value: Int64);
    procedure SetAsFloat(const _Path: String; _Value: Double);
    procedure SetAsExtended(const _Path: String; _Value: Extended);
    procedure SetAsDateTime(const _Path: String; _Value: TDateTime);
    procedure SetAsGUID(const _Path: String; const _Value: TGUID);
    procedure SetAsAnsiString(const _Path: String; const _Value: AnsiString);
    procedure SetAsString(const _Path: String; const _Value: String);
    procedure SetAsBLOB(const _Path: String; const _Value: BLOB);
    procedure SetAsData(const _Path: String; const _Value: TData);

    function FindParam(_Path: String; _DataType: TParamDataType; var _Value: TParam): Boolean; overload;
    function FindParam(_Path: String; var _Value: TParam): Boolean; overload;
    function GetParam(_Path: String): TParam;

    property Items: TParamList read FItems; { TODO 5 -oVasilyevSM -cTParams: Сделать бы default, а то бесит это Items повсюду. }
    property ListHolder: TParamsListHolder read FListHolder;

  protected

    function ParamClass: TParamClass; virtual;
    function ParamsReaderClass: TParamsReaderClass; virtual;
    function FormatParam(_Param: TParam; _Value: String; _First, _Last: Boolean): String; virtual;

  public

    constructor Create(const _PathSeparator: Char = '.'; const _SaveToStringOptions: TSaveToStringOptions = []); overload;
    constructor Create(const _SaveToStringOptions: TSaveToStringOptions); overload;

    destructor Destroy; override;

    { v Функции и свойства для основной работы v }
    function FindBoolean(const _Path: String; var _Value: Boolean): Boolean;
    function FindInteger(const _Path: String; var _Value: Integer): Boolean;
    function FindBigInt(const _Path: String; var _Value: Int64): Boolean;
    function FindFloat(const _Path: String; var _Value: Double): Boolean;
    function FindExtended(const _Path: String; var _Value: Extended): Boolean;
    function FindDateTime(const _Path: String; var _Value: TDateTime): Boolean;
    function FindGUID(const _Path: String; var _Value: TGUID): Boolean;
    function FindAnsiString(const _Path: String; var _Value: AnsiString): Boolean;
    function FindString(const _Path: String; var _Value: String): Boolean;
    function FindBLOB(const _Path: String; var _Value: BLOB): Boolean;
    function FindData(const _Path: String; var _Value: TData): Boolean;
    function FindParams(const _Path: String; var _Value: TParams): Boolean;

    function AsBooleanDef(const _Path: String; _Default: Boolean): Boolean;
    function AsIntegerDef(const _Path: String; _Default: Integer): Integer;
    function AsBigIntDef(const _Path: String; _Default: Int64): Int64;
    function AsFloatDef(const _Path: String; _Default: Double): Double;
    function AsExtendedDef(const _Path: String; _Default: Extended): Extended;
    function AsDateTimeDef(const _Path: String; _Default: TDateTime): TDateTime;
    function AsGUIDDef(const _Path: String; _Default: TGUID): TGUID;
    function AsAnsiStringDef(const _Path: String; _Default: AnsiString): AnsiString;
    function AsStringDef(const _Path: String; _Default: String): String;
    function AsBLOBDef(const _Path: String; _Default: BLOB): BLOB;
    function AsDataDef(const _Path: String; _Default: TData): TData;
    { Параметры снаружи напрямую не берем с дефолтным значением, потому что объект не должен создаваться снаружи. }

    { Для передачи без разбора типов }
    procedure AssignValue(const _Name: String; _Source: TParam; _ForceAdding: Boolean);
    procedure Assign(_Source: TParams; _ForceAdding: Boolean = True);
    function AddList(const _Path: String): TMultiParamList;
    procedure DeleteValue(const _Path: String);
    procedure Clear;

    function SaveToString: String;
    procedure LoadFromString(const _Value: String);
    { TODO 5 -oVasilyevSM -cuParams: SaveToStream/LoadFromStream }

    property IsNull[const _Path: String]: Boolean read GetIsNull write SetIsNull;
    property AsBoolean[const _Path: String]: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger[const _Path: String]: Integer read GetAsInteger write SetAsInteger;
    property AsBigInt[const _Path: String]: Int64 read GetAsBigInt write SetAsBigInt;
    property AsFloat[const _Path: String]: Double read GetAsFloat write SetAsFloat;
    property AsExtended[const _Path: String]: Extended read GetAsExtended write SetAsExtended;
    property AsDateTime[const _Path: String]: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsGUID[const _Path: String]: TGUID read GetAsGUID write SetAsGUID;
    property AsAnsiString[const _Path: String]: AnsiString read GetAsAnsiString write SetAsAnsiString;
    property AsString[const _Path: String]: String read GetAsString write SetAsString;
    property AsBLOB[const _Path: String]: BLOB read GetAsBLOB write SetAsBLOB;
    property AsData[const _Path: String]: TData read GetAsData write SetAsData;
    property AsParams[const _Path: String]: TParams read GetAsParams;
    property List[const _Path: String]: TMultiParamList read GetList;

    property PathSeparator: Char read FPathSeparator;
    property SaveToStringOptions: TSaveToStringOptions read FSaveToStringOptions;
    property Count: Integer read GetCount;

  end;

  TParamsClass = class of TParams;

  { Этот класс нужен только для обращения к здешним объектам без циркулярной ссылки. Также, благодаря этому свойства
    и методы для изменения данных в обход установленного протокола (As... :=) остаются в прайват. }
  TParamsReader = class(TParamsStringParser)

  strict private

    FParams: TParams;
    FPresetTypes: Boolean;

    FCurrentName: String;
    FCurrentType: TParamDataType;

    procedure CheckPresetType(_Strict: Boolean);
    function TrimDigital(const _Value: String): String;
    function UndoubleSymbols(const _Value: String): String;

    property PresetTypes: Boolean read FPresetTypes;

  private

    constructor Create(const _Source: String; _Params: TParams);
    constructor CreateNested(_MasterParser: TParamsReader; _Params: TParams);

  protected

    procedure ReadName; override;
    procedure ReadType; override;
    procedure ReadValue; override;
    procedure ReadParams(_CursorShift: Int64); override;
    function IsParamsType: Boolean; override;
    procedure BeforeReadParam(_Param: TParam); virtual;
    procedure AfterReadParam(_Param: TParam); virtual;
    procedure AfterReadParams(_Param: TParam); virtual;

    property CurrentName: String read FCurrentName;
    property CurrentType: TParamDataType read FCurrentType;

  public

    property Params: TParams read FParams;

  end;

  EParamsException = class(ECoreException);

function ParamDataTypeToStr(Value: TParamDataType): String;
function StrToParamDataType(Value: String): TParamDataType;
function ParamsToStr(Params: TParams): String;
procedure StrToParams(const Value: String; Params: TParams);

implementation

function ParamDataTypeToStr(Value: TParamDataType): String;
const

  SA_StringValues: array[TParamDataType] of String = (

      { dtUnknown    } 'Unknown',
      { dtBoolean    } 'Boolean',
      { dtInteger    } 'Integer',
      { dtBigInt     } 'BigInt',
      { dtFloat      } 'Float',
      { dtExtended   } 'Extended',
      { dtDateTime   } 'DateTime',
      { dtGUID       } 'GUID',
      { dtAnsiString } 'AnsiString',
      { dtString     } 'String',
      { dtBLOB       } 'BLOB',
      { dtData       } 'Data',
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

function ParamsToStr(Params: TParams): String;
begin
  Result := Params.SaveToString;
end;

procedure StrToParams(const Value: String; Params: TParams);
begin
  Params.LoadFromString(Value);
end;

{ TParam }

constructor TParam.Create;
begin

  inherited Create;

  FIsNull        := True;
  FPathSeparator := _PathSeparator;

  ValidateName(_Name, FPathSeparator);
  FName := _Name;

end;

destructor TParam.Destroy;
begin
  FreeData;
  inherited Destroy;
end;

procedure TParam.SetIsNull(const _Value: Boolean);
begin

  if _Value <> FIsNull then begin

    FIsNull := _Value;
    FreeData;

  end;

end;

procedure TParam.AllocData;
begin
  if not (DataType in ([dtUnknown] + SC_SELF_ALLOCATED_TYPES)) then
    FData := AllocMem(DataSize);
end;

procedure TParam.FreeData;
begin

  { Объекту надо вызвать собственный деструктор }
  if DataType = dtParams then
    TParams(FData).Free;

  if not (DataType in ([dtUnknown] + SC_SELF_ALLOCATED_TYPES)) then
    FreeMemory(FData);

  { Память строк освобождается так. }
  case FDataType of

    dtAnsiString: AnsiString(FData) := '';
    dtString:     String(FData)     := '';
    dtBLOB:       BLOB(FData)       := '';
    dtData:       SetLength(TData(FData), 0);

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
    dtExtended:   Result := SizeOf(Extended);
    dtDateTime:   Result := SizeOf(TDateTime);
    dtAnsiString: Result := 0;
    dtString:     Result := 0;
    dtGUID:       Result := SizeOf(TGUID);
    dtBLOB:       Result := 0;
    dtData:       Result := 0;
    dtParams:     Result := SizeOf(TObject);

  else
    raise EUncompletedMethod.Create;
  end;

end;

procedure TParam.CheckDataType(_DataType: TParamDataType);
begin

  if FDataType <> _DataType then

    raise EParamsException.CreateFmt('Unable to read data type %s as %s', [

        ParamDataTypeToStr(FDataType),
        ParamDataTypeToStr(_DataType)

    ]);

end;

procedure TParam.PresetData(_DataType: TParamDataType);
begin

  FreeData;

  FDataType := _DataType;
  FIsNull := False;

  AllocData;

end;

procedure TParam.SetDataType(_Value: TParamDataType);
begin

  if _Value <> FDataType then begin

    if not IsNull then
      FreeData;
    FDataType := _Value;

  end;

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

function TParam.GetAsExtended: Extended;
begin


  CheckDataType(dtExtended);

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

  { Проверки типа данных нет, метод должен вернуть значение гарантированно. }

  if IsNull then Result := ''
  else

    case FDataType of

      dtUnknown:    Result := '';
      dtBoolean:    Result := BooleanToStr (AsBoolean   );
      dtInteger:    Result := IntToStr     (AsInteger   );
      dtBigInt:     Result := BigIntToStr  (AsBigInt    );
      dtFloat:      Result := FloatToStr   (AsFloat     );
      dtExtended:   Result := ExtendedToStr(AsExtended  );
      dtDateTime:   Result := DateTimeToStr(AsDateTime  );
      dtGUID:       Result := GUIDToStr    (AsGUID      );
      dtAnsiString: Result := AnsiStrToStr (AsAnsiString);
      dtString:     Result := String       (FData       );
      dtBLOB:       Result := BLOBToHexStr (AsBLOB      );
      dtData:       Result := DataToByteStr(AsData      );
      dtParams:     Result := TParams(FData).SaveToString;

    else
      raise EUncompletedMethod.Create;
    end;

end;

function TParam.GetAsBLOB: BLOB;
begin
  CheckDataType(dtBLOB);
  Result := BLOB(FData);
end;

function TParam.GetAsData: TData;
begin
  CheckDataType(dtData);
  Result := TData(FData);
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

procedure TParam.SetAsExtended(_Value: Extended);
begin
  PresetData(dtExtended);
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

procedure TParam.SetAsBLOB(const _Value: BLOB);
begin
  PresetData(dtBLOB);
  BLOB(FData) := _Value;
end;

procedure TParam.SetAsData(const _Value: TData);
begin
  PresetData(dtData);
  TData(FData) := _Value;
end;

procedure TParam.SetAsParams(_Value: TParams);
begin
  PresetData(dtParams);
  TParams(FData) := _Value;
end;

procedure TParam.Clear;
begin

  FreeData;
  FIsNull := True;
  FDataType := dtUnknown;

end;

class procedure TParam.ValidateName(const _Value, _PathSeparator: String);
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

  if Pos(_PathSeparator, _Value) > 0 then
    raise EParamsException.CreateFmt('Character ''%s'' is used as a path separator. So it is invalid in param name ''%s''.', [_PathSeparator, _Value]);

end;

procedure TParam.AssignValue(_Source: TParam; _Host: TParams; _ForceAdding: Boolean);
var
  P: TParams;
begin

  if _Source.IsNull then begin

    IsNull := True;
    SetDataType(_Source.DataType);

  end else

    case _Source.DataType of

      dtBoolean:    AsBoolean    := _Source.AsBoolean;
      dtInteger:    AsInteger    := _Source.AsInteger;
      dtBigInt:     AsBigInt     := _Source.AsBigInt;
      dtFloat:      AsFloat      := _Source.AsFloat;
      dtExtended:   AsExtended   := _Source.AsExtended;
      dtDateTime:   AsDateTime   := _Source.AsDateTime;
      dtGUID:       AsGUID       := _Source.AsGUID;
      dtAnsiString: AsAnsiString := _Source.AsAnsiString;
      dtString:     AsString     := _Source.AsString;
      dtBLOB:       AsBLOB       := _Source.AsBLOB;
      dtData:       AsData       := _Source.AsData;
      dtParams:

        begin

          P := TParamsClass(_Host.ClassType).Create(_Host.PathSeparator, _Host.SaveToStringOptions);
          SetAsParams(P);
          P.Assign(_Source.AsParams, _ForceAdding);

        end;

    else
      raise EUncompletedMethod.Create;
    end;

end;

{ TParamHelper }

function TParamHelper._GetAsBoolean: Boolean;
begin

  if StrictDataType then Result := GetAsBoolean
  else

    case DataType of

      dtInteger:    Result := IntToBoolean     (AsInteger   );
      dtBigInt:     Result := BigIntToBoolean  (AsBigInt    );
      dtFloat:      Result := FloatToBoolean   (AsFloat     );
      dtExtended:   Result := ExtendedToBoolean(AsExtended  );
      dtAnsiString: Result := AnsiStrToBoolean (AsAnsiString);
      dtString:     Result := StrToBoolean     (AsString    );
      dtBLOB:       Result := BLOBToBoolean    (AsBLOB      );
      dtData:       Result := DataToBoolean    (AsData      );

    else
      Result := GetAsBoolean;
    end;

end;

function TParamHelper._GetAsInteger: Integer;
begin

  if StrictDataType then Result := GetAsInteger
  else

    case DataType of

      dtBoolean:    Result := BooleanToInt (AsBoolean   );
      dtBigInt:     Result := BigIntToInt  (AsBigInt    );
      dtFloat:      Result := FloatToInt   (AsFloat     );
      dtExtended:   Result := ExtendedToInt(AsFloat     );
      dtAnsiString: Result := AnsiStrToInt (AsAnsiString);
      dtString:     Result := StrToInt     (AsString    );
      dtBLOB:       Result := BLOBToInt    (AsBLOB      );
      dtData:       Result := DataToInt    (AsData      );

    else
      Result := GetAsInteger;
    end;

end;

function TParamHelper._GetAsBigInt: Int64;
begin

  if StrictDataType then Result := GetAsBigInt
  else

    case DataType of

      dtBoolean:    Result := BooleanToBigInt (AsBoolean   );
      dtInteger:    Result := IntToBigInt     (AsInteger   );
      dtFloat:      Result := FloatToBigInt   (AsFloat     );
      dtExtended:   Result := ExtendedToBigInt(AsExtended  );
      dtAnsiString: Result := AnsiStrToBigInt (AsAnsiString);
      dtString:     Result := StrToBigInt     (AsString    );
      dtBLOB:       Result := BLOBToBigInt    (AsBLOB      );
      dtData:       Result := DataToBigInt    (AsData      );

    else
      Result := GetAsBigInt;
    end;

end;

function TParamHelper._GetAsFloat: Double;
begin

  if StrictDataType then Result := GetAsFloat
  else

    case DataType of

      dtBoolean:    Result := BooleanToFloat (AsBoolean   );
      dtInteger:    Result := IntToFloat     (AsInteger   );
      dtBigInt:     Result := BigIntToFloat  (AsBigInt    );
      dtExtended:   Result := ExtendedToFloat(AsExtended  );
      dtDateTime:   Result := DateTimeToFloat(AsDateTime  );
      dtAnsiString: Result := AnsiStrToFloat (AsAnsiString);
      dtString:     Result := StrToFloat     (AsString    );
      dtBLOB:       Result := BLOBToFloat    (AsBLOB      );
      dtData:       Result := DataToFloat    (AsData      );

    else
      Result := GetAsFloat;
    end;

end;

function TParamHelper._GetAsExtended: Extended;
begin

  if StrictDataType then Result := GetAsExtended
  else

    case DataType of

      dtBoolean:    Result := BooleanToExtended (AsBoolean   );
      dtInteger:    Result := IntToExtended     (AsInteger   );
      dtBigInt:     Result := BigIntToExtended  (AsBigInt    );
      dtFloat:      Result := ExtendedToFloat   (AsExtended  );
      dtDateTime:   Result := DateTimeToExtended(AsDateTime  );
      dtAnsiString: Result := AnsiStrToExtended (AsAnsiString);
      dtString:     Result := StrToExtended     (AsString    );
      dtBLOB:       Result := BLOBToExtended    (AsBLOB      );
      dtData:       Result := DataToExtended    (AsData      );

    else
      Result := GetAsExtended;
    end;

end;

function TParamHelper._GetAsDateTime: TDateTime;
begin

  if StrictDataType then Result := GetAsDateTime
  else

    case DataType of

      dtInteger:    Result := IntToDateTime     (AsInteger   );
      dtBigInt:     Result := BigIntToDateTime  (AsBigInt    );
      dtFloat:      Result := FloatToDateTime   (AsFloat     );
      dtExtended:   Result := ExtendedToDateTime(AsExtended  );
      dtAnsiString: Result := AnsiStrToDateTime (AsAnsiString);
      dtString:     Result := StrToDateTime     (AsString    );
      dtBLOB:       Result := BLOBToDateTime    (AsBLOB      );
      dtData:       Result := DataToDateTime    (AsData      );

    else
      Result := GetAsDateTime;
    end;

end;

function TParamHelper._GetAsGUID: TGUID;
begin

  if StrictDataType then Result := GetAsGUID
  else

    case DataType of

      dtAnsiString: Result := AnsiStrToGUID(AsAnsiString);
      dtString:     Result := StrToGUID    (AsString    );
      dtBLOB:       Result := BLOBToGUID   (AsBLOB      );
      dtData:       Result := DataToGUID   (AsData      );

    else
      Result := GetAsGUID;
    end;

end;

function TParamHelper._GetAsAnsiString: AnsiString;
begin

  if StrictDataType then Result := GetAsAnsiString
  else

    case DataType of

      dtBoolean:  Result := BooleanToAnsiStr (AsBoolean   );
      dtInteger:  Result := IntToAnsiStr     (AsInteger   );
      dtBigInt:   Result := BigIntToAnsiStr  (AsBigInt    );
      dtFloat:    Result := FloatToAnsiStr   (AsFloat     );
      dtExtended: Result := ExtendedToAnsiStr(AsExtended  );
      dtDateTime: Result := DateTimeToAnsiStr(AsDateTime  );
      dtGUID:     Result := GUIDToAnsiStr    (AsGUID      );
      dtString:   Result := StrToAnsiStr     (AsString    );
      dtBLOB:     Result := BLOBToHexAnsiStr (AsBLOB      );
      dtData:     Result := DataToByteAnsiStr(AsData      );

    else
      Result := GetAsAnsiString;
    end;

end;

function TParamHelper._GetAsString: String;
begin
  Result := GetAsString;
end;

function TParamHelper._GetAsBLOB: BLOB;
begin

  if StrictDataType then Result := GetAsBLOB
  else

    case DataType of

      dtBoolean:    Result := BooleanToBLOB   (AsBoolean   );
      dtInteger:    Result := IntToBLOB       (AsInteger   );
      dtBigInt:     Result := BigIntToBLOB    (AsBigInt    );
      dtFloat:      Result := FloatToBLOB     (AsFloat     );
      dtExtended:   Result := ExtendedToBLOB  (AsExtended  );
      dtDateTime:   Result := DateTimeToBLOB  (AsDateTime  );
      dtGUID:       Result := GUIDToBLOB      (AsGUID      );
      dtAnsiString: Result := HexAnsiStrToBLOB(AsAnsiString);
      dtString:     Result := HexStrToBLOB    (AsString    );
      dtData:       Result := DataToBLOB      (AsData      );

    else
      Result := GetAsBLOB;
    end;

end;

function TParamHelper._GetAsData: TData;
begin

  if StrictDataType then Result := GetAsData
  else

    case DataType of

      dtBoolean:    Result := BooleanToData    (AsBoolean   );
      dtInteger:    Result := IntToData        (AsInteger   );
      dtBigInt:     Result := BigIntToData     (AsBigInt    );
      dtFloat:      Result := FloatToData      (AsFloat     );
      dtExtended:   Result := ExtendedToData   (AsExtended  );
      dtDateTime:   Result := DateTimeToData   (AsDateTime  );
      dtGUID:       Result := GUIDToData       (AsGUID      );
      dtAnsiString: Result := ByteAnsiStrToData(AsAnsiString);
      dtString:     Result := ByteStrToData    (AsString    );
      dtBLOB:       Result := BLOBToData       (AsBLOB      );

    else
      Result := GetAsData;
    end;

end;

procedure TParamHelper._SetAsBoolean(const _Value: Boolean);
begin

  if StrictDataType then SetAsBoolean(_Value)
  else

    case DataType of

      dtInteger:    SetAsInteger   (BooleanToInt     (_Value));
      dtBigInt:     SetAsBigInt    (BooleanToBigInt  (_Value));
      dtFloat:      SetAsFloat     (BooleanToFloat   (_Value));
      dtExtended:   SetAsExtended  (BooleanToExtended(_Value));
      dtAnsiString: SetAsAnsiString(BooleanToAnsiStr (_Value));
      dtString:     SetAsString    (BooleanToStr     (_Value));
      dtBLOB:       SetAsBLOB      (BooleanToBLOB    (_Value));
      dtData:       SetAsData      (BooleanToData    (_Value));

    else
      SetAsBoolean(_Value);
    end;

end;

procedure TParamHelper._SetAsInteger(const _Value: Integer);
begin

  if StrictDataType then SetAsInteger(_Value)
  else

    case DataType of

      dtBoolean:    SetAsBoolean   (IntToBoolean (_Value));
      dtBigInt:     SetAsBigInt    (IntToBigInt  (_Value));
      dtFloat:      SetAsFloat     (IntToFloat   (_Value));
      dtExtended:   SetAsExtended  (IntToExtended(_Value));
      dtAnsiString: SetAsAnsiString(IntToAnsiStr (_Value));
      dtString:     SetAsString    (IntToStr     (_Value));
      dtBLOB:       SetAsBLOB      (IntToBLOB    (_Value));
      dtData:       SetAsData      (IntToData    (_Value));

    else
      SetAsInteger(_Value);
    end;

end;

procedure TParamHelper._SetAsBigInt(const _Value: Int64);
begin

  if StrictDataType then SetAsBigInt(_Value)
  else

    case DataType of

      dtBoolean:    SetAsBoolean   (BigIntToBoolean (_Value));
      dtInteger:    SetAsInteger   (BigIntToInt     (_Value));
      dtFloat:      SetAsFloat     (BigIntToFloat   (_Value));
      dtExtended:   SetAsExtended  (BigIntToExtended(_Value));
      dtAnsiString: SetAsAnsiString(BigIntToAnsiStr (_Value));
      dtString:     SetAsString    (BigIntToStr     (_Value));
      dtBLOB:       SetAsBLOB      (BigIntToBLOB    (_Value));
      dtData:       SetAsData      (BigIntToData    (_Value));

    else
      SetAsBigInt(_Value);
    end;

end;

procedure TParamHelper._SetAsFloat(const _Value: Double);
begin

  if StrictDataType then SetAsFloat(_Value)
  else

    case DataType of

      dtBoolean:    SetAsBoolean   (FloatToBoolean (_Value));
      dtInteger:    SetAsInteger   (FloatToInt     (_Value));
      dtBigInt:     SetAsFloat     (FloatToBigInt  (_Value));
      dtExtended:   SetAsExtended  (FloatToExtended(_Value));
      dtAnsiString: SetAsAnsiString(FloatToAnsiStr (_Value));
      dtString:     SetAsString    (FloatToStr     (_Value));
      dtBLOB:       SetAsBLOB      (FloatToBLOB    (_Value));
      dtData:       SetAsData      (FloatToData    (_Value));

    else
      SetAsFloat(_Value);
    end;

end;

procedure TParamHelper._SetAsExtended(const _Value: Extended);
begin

  if StrictDataType then SetAsExtended(_Value)
  else

    case DataType of

      dtBoolean:    SetAsBoolean    (ExtendedToBoolean (_Value));
      dtInteger:    SetAsInteger    (ExtendedToInt     (_Value));
      dtBigInt:     SetAsBigInt     (ExtendedToBigInt  (_Value));
      dtFloat:      SetAsFloat      (ExtendedToFloat   (_Value));
      dtDateTime:   SetAsDateTime   (ExtendedToDateTime(_Value));
      dtAnsiString: SetAsAnsiString (ExtendedToAnsiStr (_Value));
      dtString:     SetAsString     (ExtendedToStr     (_Value));
      dtBLOB:       SetAsBLOB       (ExtendedToBLOB    (_Value));
      dtData:       SetAsData       (ExtendedToData    (_Value));

    else
      SetAsExtended(_Value);
    end;

end;

procedure TParamHelper._SetAsDateTime(const _Value: TDateTime);
begin

  if StrictDataType then SetAsDateTime(_Value)
  else

    case DataType of

      dtInteger:    SetAsInteger   (DateTimeToInt     (_Value));
      dtBigInt:     SetAsBigInt    (DateTimeToBigInt  (_Value));
      dtFloat:      SetAsFloat     (DateTimeToFloat   (_Value));
      dtExtended:   SetAsExtended  (DateTimeToExtended(_Value));
      dtAnsiString: SetAsAnsiString(DateTimeToAnsiStr (_Value));
      dtString:     SetAsString    (DateTimeToStr     (_Value));
      dtBLOB:       SetAsBLOB      (DateTimeToBLOB    (_Value));
      dtData:       SetAsData      (DateTimeToData    (_Value));

    else
      SetAsDateTime(_Value);
    end;

end;

procedure TParamHelper._SetAsGUID(const _Value: TGUID);
begin

  if StrictDataType then SetAsGUID(_Value)
  else

    case DataType of

      dtAnsiString: SetAsAnsiString(GUIDToAnsiStr(_Value));
      dtString:     SetAsString    (GUIDToStr    (_Value));
      dtBLOB:       SetAsBLOB      (GUIDToBLOB   (_Value));
      dtData:       SetAsData      (GUIDToData   (_Value));

    else
      SetAsGUID(_Value);
    end;

end;

procedure TParamHelper._SetAsAnsiString(const _Value: AnsiString);
begin

  if StrictDataType then SetAsAnsiString(_Value)
  else

    case DataType of

      dtBoolean:   SetAsBoolean(AnsiStrToBoolean (_Value));
      dtInteger:  SetAsInteger (AnsiStrToInt     (_Value));
      dtBigInt:   SetAsBigInt  (AnsiStrToBigInt  (_Value));
      dtFloat:    SetAsFloat   (AnsiStrToFloat   (_Value));
      dtExtended: SetAsExtended(AnsiStrToExtended(_Value));
      dtDateTime: SetAsDateTime(AnsiStrToDateTime(_Value));
      dtGUID:     SetAsGUID    (AnsiStrToGUID    (_Value));
      dtString:   SetAsString  (AnsiStrToStr     (_Value));
      dtBLOB:     SetAsBLOB    (HexAnsiStrToBLOB (_Value));
      dtData:     SetAsData    (ByteAnsiStrToData(_Value));

    else
      SetAsAnsiString(_Value);
    end;

end;

procedure TParamHelper._SetAsString(const _Value: String);
begin

  if StrictDataType then SetAsString(_Value)
  else

    case DataType of

      dtBoolean:    SetAsBoolean   (StrToBoolean (_Value));
      dtInteger:    SetAsInteger   (StrToInt     (_Value));
      dtBigInt:     SetAsBigInt    (StrToBigInt  (_Value));
      dtFloat:      SetAsFloat     (StrToFloat   (_Value));
      dtExtended:   SetAsExtended  (StrToExtended(_Value));
      dtDateTime:   SetAsDateTime  (StrToDateTime(_Value));
      dtGUID:       SetAsGUID      (StrToGUID    (_Value));
      dtAnsiString: SetAsAnsiString(StrToAnsiStr (_Value));
      dtBLOB:       SetAsBLOB      (HexStrToBLOB (_Value));
      dtData:       SetAsData      (ByteStrToData(_Value));

    else
      SetAsString(_Value);
    end;

end;

procedure TParamHelper._SetAsBLOB(const _Value: BLOB);
begin

  if StrictDataType then SetAsBLOB(_Value)
  else

    case DataType of

      dtBoolean:    SetAsBoolean   (BLOBToBoolean   (_Value));
      dtInteger:    SetAsInteger   (BLOBToInt       (_Value));
      dtBigInt:     SetAsBigInt    (BLOBToBigInt    (_Value));
      dtFloat:      SetAsFloat     (BLOBToFloat     (_Value));
      dtExtended:   SetAsExtended  (BLOBToExtended  (_Value));
      dtDateTime:   SetAsDateTime  (BLOBToDateTime  (_Value));
      dtGUID:       SetAsGUID      (BLOBToGUID      (_Value));
      dtAnsiString: SetAsAnsiString(BLOBToHexAnsiStr(_Value));
      dtString:     SetAsString    (BLOBToHexStr    (_Value));
      dtData:       SetAsData      (BLOBToData      (_Value));

    else
      SetAsBLOB(_Value);
    end;

end;

procedure TParamHelper._SetAsData(const _Value: TData);
begin

  if StrictDataType then SetAsData(_Value)
  else

    case DataType of

      dtBoolean:    SetAsBoolean   (DataToBoolean    (_Value));
      dtInteger:    SetAsInteger   (DataToInt        (_Value));
      dtBigInt:     SetAsBigInt    (DataToBigInt     (_Value));
      dtFloat:      SetAsFloat     (DataToFloat      (_Value));
      dtExtended:   SetAsExtended  (DataToExtended   (_Value));
      dtDateTime:   SetAsDateTime  (DataToDateTime   (_Value));
      dtGUID:       SetAsGUID      (DataToGUID       (_Value));
      dtAnsiString: SetAsAnsiString(DataToByteAnsiStr(_Value));
      dtString:     SetAsString    (DataToByteStr    (_Value));
      dtBLOB:       SetAsBLOB      (DataToBLOB       (_Value));

    else
      SetAsData(_Value);
    end;

end;

{ TParams.TMultiParamList }

constructor TParams.TMultiParamList.Create;
begin

  inherited Create;

  FName   := _Name;
  FParams := _Params;

end;

function TParams.TMultiParamList.CreateNewParam: TParam;
begin
  Result := FParams.CreateNewParam(FName);
end;

function TParams.TMultiParamList.GetCount: Integer;
var
  Param: TParam;
begin

  Result := 0;

  for Param in FParams.Items do
    if SameText(Param.Name, FName) then
      Inc(Result);

end;

function TParams.TMultiParamList.GetItems(_Index: Integer): TParam;
begin
  Result := FParams.Items[InternalIndex(_Index)];
end;

function TParams.TMultiParamList.GetDataType(_Index: Integer): TParamDataType;
begin
  Result := Items[_Index].DataType;
end;

function TParams.TMultiParamList.GetIsNull(_Index: Integer): Boolean;
begin
  Result := Items[_Index].IsNull;
end;

function TParams.TMultiParamList.GetAsBoolean(_Index: Integer): Boolean;
begin
  Result := Items[_Index].AsBoolean;
end;

function TParams.TMultiParamList.GetAsInteger(_Index: Integer): Integer;
begin
  Result := Items[_Index].AsInteger;
end;

function TParams.TMultiParamList.GetAsBigInt(_Index: Integer): Int64;
begin
  Result := Items[_Index].AsBigInt;
end;

function TParams.TMultiParamList.GetAsFloat(_Index: Integer): Double;
begin
  Result := Items[_Index].AsFloat;
end;

function TParams.TMultiParamList.GetAsExtended(_Index: Integer): Extended;
begin
  Result := Items[_Index].AsExtended;
end;

function TParams.TMultiParamList.GetAsDateTime(_Index: Integer): TDateTime;
begin
  Result := Items[_Index].AsDateTime;
end;

function TParams.TMultiParamList.GetAsGUID(_Index: Integer): TGUID;
begin
  Result := Items[_Index].AsGUID;
end;

function TParams.TMultiParamList.GetAsAnsiString(_Index: Integer): AnsiString;
begin
  Result := Items[_Index].AsAnsiString;
end;

function TParams.TMultiParamList.GetAsString(_Index: Integer): String;
begin
  Result := Items[_Index].AsString;
end;

function TParams.TMultiParamList.GetAsBLOB(_Index: Integer): BLOB;
begin
  Result := Items[_Index].AsBLOB;
end;

function TParams.TMultiParamList.GetAsData(_Index: Integer): TData;
begin
  Result := Items[_Index].AsData;
end;

procedure TParams.TMultiParamList.SetIsNull(_Index: Integer; const _Value: Boolean);
begin
  Items[_Index].IsNull := _Value;
end;

procedure TParams.TMultiParamList.SetAsBoolean(_Index: Integer; const _Value: Boolean);
begin
  Items[_Index].AsBoolean := _Value;
end;

procedure TParams.TMultiParamList.SetAsInteger(_Index: Integer; const _Value: Integer);
begin
  Items[_Index].AsInteger := _Value;
end;

procedure TParams.TMultiParamList.SetAsBigInt(_Index: Integer; const _Value: Int64);
begin
  Items[_Index].AsBigInt := _Value;
end;

procedure TParams.TMultiParamList.SetAsFloat(_Index: Integer; const _Value: Double);
begin
  Items[_Index].AsFloat := _Value;
end;

procedure TParams.TMultiParamList.SetAsExtended(_Index: Integer; const _Value: Extended);
begin
  Items[_Index].AsExtended := _Value;
end;

procedure TParams.TMultiParamList.SetAsDateTime(_Index: Integer; const _Value: TDateTime);
begin
  Items[_Index].AsDateTime := _Value;
end;

procedure TParams.TMultiParamList.SetAsGUID(_Index: Integer; const _Value: TGUID);
begin
  Items[_Index].AsGUID := _Value;
end;

procedure TParams.TMultiParamList.SetAsAnsiString(_Index: Integer; const _Value: AnsiString);
begin
  Items[_Index].AsAnsiString := _Value;
end;

procedure TParams.TMultiParamList.SetAsString(_Index: Integer; const _Value: String);
begin
  Items[_Index].AsString := _Value;
end;

procedure TParams.TMultiParamList.SetAsBLOB(_Index: Integer; const _Value: BLOB);
begin
  Items[_Index].AsBLOB := _Value;
end;

procedure TParams.TMultiParamList.SetAsData(_Index: Integer; const _Value: TData);
begin
  Items[_Index].AsData := _Value;
end;

function TParams.TMultiParamList.InternalIndex(_Index: Integer): Integer;
var
  i: Integer;
begin

  Inc(_Index);
  for i := 0 to FParams.Items.Count - 1 do begin

    if SameText(FParams.Items[i].Name, FName) then
      Dec(_Index);

    if _Index = 0 then
      Exit(i);

  end;

  Result := -1;

end;

function TParams.TMultiParamList.ExternalIndex(_InternalIndex: Integer): Integer;
var
  i: Integer;
begin

  Result := -1;

  for i := 0 to _InternalIndex do
    if SameText(FParams.Items[i].Name, FName) then
      Inc(Result);

end;

procedure TParams.TMultiParamList.SetDataType(_Index: Integer; const _Value: TParamDataType);
begin
  Items[_Index].SetDataType(_Value);
end;

function TParams.TMultiParamList.Insert(_Index: Integer): Integer;
begin
  FParams.Items.Insert(InternalIndex(_Index), CreateNewParam);
  Result := _Index;
end;

function TParams.TMultiParamList.Append: Integer;
begin
  Result := ExternalIndex(FParams.Items.Add(CreateNewParam));
end;

procedure TParams.TMultiParamList.Delete(_Index: Integer);
begin
  FParams.Items.Delete(InternalIndex(_Index));
end;

{ TParams.TParamsListHolder }

function TParams.TParamsListHolder.Find(const _Name: String; var _ParamList: TMultiParamList): Boolean;
var
  Item: TMultiParamList;
begin

  for Item in Self do

    if SameText(Item.Name, _Name) then begin

      _ParamList := Item;
      Exit(True);

    end;

    Result := False;

end;

function TParams.TParamsListHolder.Add(const _Name: String; _Params: TParams): TMultiParamList;
begin
  Result := TMultiParamList.Create(_Name, _Params);
  inherited Add(Result);
end;

function TParams.TParamsListHolder.Get(const _Name: String; _Params: TParams): TMultiParamList;
begin
  if not Find(_Name, Result) then
    raise EParamsException.CreateFmt('Param list ''%s'' not found', [_Name]);
end;

{ TParams.TParamList }

procedure TParams.TParamList.Notify(const _Item: TParam; _Action: Generics.Collections.TCollectionNotification);
begin
  if (_Action = cnRemoved) and (_Item.DataType = dtParams) then
    _Item.Clear;
  inherited Notify(_Item, _Action);
end;

{ TParams }

constructor TParams.Create(const _PathSeparator: Char; const _SaveToStringOptions: TSaveToStringOptions);
begin

  inherited Create;

  FPathSeparator       := _PathSeparator;
  FSaveToStringOptions := _SaveToStringOptions;

  FItems      := TParamList.Create;
  FListHolder := TParamsListHolder.Create;

end;

constructor TParams.Create(const _SaveToStringOptions: TSaveToStringOptions);
begin
  Create('.', _SaveToStringOptions);
end;

destructor TParams.Destroy;
begin

  FreeAndNil(FListHolder);
  FreeAndNil(FItems     );

  inherited Destroy;

end;

function TParams.Add(const _Name: String): TParam;
begin
  Result := CreateNewParam(_Name);
  Items.Add(Result);
end;

function TParams.FindPath(var _Path: String; var _Params: TParams): Boolean;
var
  Param: TParam;
  SingleName: String;
begin

  _Params := Self;

  while Pos(FPathSeparator, _Path) > 0 do begin

    SingleName := ReadStrTo(_Path, FPathSeparator, False);

    if _Params.FindParam(SingleName, dtParams, Param) then

      _Params := Param.AsParams

    else Exit(False);

  end;

  Result := True;

end;

function TParams.GetPath(var _Path: String): TParams;
var
  SingleName: String;
  Param: TParam;
begin

  Result := Self;

  while Pos(FPathSeparator, _Path) > 0 do begin

    SingleName := ReadStrTo(_Path, FPathSeparator, False);

    if Result.FindParam(SingleName, dtParams, Param) then Result := Param.AsParams
    else

      with Result.Add(SingleName) do begin

        SetAsParams(TParams.Create(PathSeparator, SaveToStringOptions));
        Result := AsParams;

      end;

  end;

end;

function TParams.ParamByName(const _Path: String): TParam;
begin
  if not FindParam(_Path, Result) then
    raise EParamsException.CreateFmt('Param %s not found', [_Path]);
end;

function TParams.GetList(const _Path: String): TMultiParamList;
var
  PathRest: String;
  Params: TParams;
begin

  PathRest := _Path;

  if not FindPath(PathRest, Params) then
    raise EParamsException.CreateFmt('Param %s not found', [_Path]);

  Result := Params.ListHolder.Get(PathRest, Params);

end;

function TParams.GetCount: Integer;
begin
  Result := Items.Count;
end;

function TParams.CreateNewParam(const _Name: String): TParam;
begin
  Result := ParamClass.Create(_Name, PathSeparator);
end;

function TParams.GetIsNull(const _Path: String): Boolean;
begin
  Result := ParamByName(_Path).IsNull;
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

function TParams.GetAsFloat(const _Path: String): Double;
begin
  Result := ParamByName(_Path).AsFloat;
end;

function TParams.GetAsExtended(const _Path: String): Extended;
begin
  Result := ParamByName(_Path).AsExtended;
end;

function TParams.GetAsDateTime(const _Path: String): TDateTime;
begin
  Result := ParamByName(_Path).AsDateTime;
end;

function TParams.GetAsGUID(const _Path: String): TGUID;
begin
  Result := ParamByName(_Path).AsGUID;
end;

function TParams.GetAsAnsiString(const _Path: String): AnsiString;
begin
  Result := ParamByName(_Path).AsAnsiString;
end;

function TParams.GetAsString(const _Path: String): String;
begin
  Result := ParamByName(_Path).AsString;
end;

function TParams.GetAsBLOB(const _Path: String): BLOB;
begin
  Result := ParamByName(_Path).AsBLOB;
end;

function TParams.GetAsData(const _Path: String): TData;
begin
  Result := ParamByName(_Path).AsData;
end;

function TParams.GetAsParams(const _Path: String): TParams;
begin
  Result := ParamByName(_Path).AsParams;
end;

procedure TParams.SetIsNull(const _Path: String; const _Value: Boolean);
begin
  GetParam(_Path).IsNull := _Value;
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

procedure TParams.SetAsFloat(const _Path: String; _Value: Double);
begin
  GetParam(_Path).AsFloat := _Value;
end;

procedure TParams.SetAsExtended(const _Path: String; _Value: Extended);
begin
  GetParam(_Path).AsExtended := _Value;
end;

procedure TParams.SetAsDateTime(const _Path: String; _Value: TDateTime);
begin
  GetParam(_Path).AsDateTime := _Value;
end;

procedure TParams.SetAsGUID(const _Path: String; const _Value: TGUID);
begin
  GetParam(_Path).AsGUID := _Value;
end;

procedure TParams.SetAsAnsiString(const _Path: String; const _Value: AnsiString);
begin
  GetParam(_Path).AsAnsiString := _Value;
end;

procedure TParams.SetAsString(const _Path: String; const _Value: String);
begin
  GetParam(_Path).AsString := _Value;
end;

procedure TParams.SetAsBLOB(const _Path: String; const _Value: BLOB);
begin
  GetParam(_Path).AsBLOB := _Value;
end;

procedure TParams.SetAsData(const _Path: String; const _Value: TData);
begin
  GetParam(_Path).AsData := _Value;
end;

function TParams.FindParam(_Path: String; _DataType: TParamDataType; var _Value: TParam): Boolean;
var
  Params: TParams;
  Param: TParam;
begin

  Result := FindPath(_Path, Params);

  if Result then

    for Param in Params.Items do

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

function TParams.GetParam(_Path: String): TParam;
begin

  with GetPath(_Path) do
    if not FindParam(_Path, Result) then
      Result := Add(_Path);

end;

function TParams.ParamClass: TParamClass;
begin
  Result := TParam;
end;

function TParams.ParamsReaderClass: TParamsReaderClass;
begin
  Result := TParamsReader;
end;

function TParams.FormatParam(_Param: TParam; _Value: String; _First, _Last: Boolean): String;
const

  SC_VALUE_UNTYPED = '%0:s = %2:s%3:s';
  SC_VALUE_TYPED   = '%0:s: %1:s = %2:s%3:s';

var
  ParamFormat: String;
  Splitter: String;
begin

  if _Param.DataType = dtParams then begin

    if soSingleString in SaveToStringOptions then

      _Value := Format('(%s)', [_Value])

    else begin

      if Length(_Value) > 0 then _Value := _Value + CRLF;
      _Value := Format('(%s%s)', [CRLF, ShiftText(_Value, 1)]);

    end;

  end;

  if soTypesFree in SaveToStringOptions then ParamFormat := SC_VALUE_UNTYPED
  else ParamFormat := SC_VALUE_TYPED;

  if _Last then Splitter := ''
  else if soSingleString in SaveToStringOptions then Splitter := ';'
  else Splitter := CRLF;

  Result := Format(ParamFormat, [

      _Param.Name,
      ParamDataTypeToStr(_Param.DataType),
      _Value,
      Splitter

  ]);

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

function TParams.FindExtended(const _Path: String; var _Value: Extended): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, dtExtended, P);
  if Result then _Value := P.AsExtended;
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

function TParams.FindData(const _Path: String; var _Value: TData): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, dtData, P);
  if Result then _Value := P.AsData;
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

function TParams.AsExtendedDef(const _Path: String; _Default: Extended): Extended;
begin
  if not FindExtended(_Path, Result) then AsExtended[_Path] := _Default;
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

function TParams.AsDataDef(const _Path: String; _Default: TData): TData;
begin
  if not FindData(_Path, Result) then AsData[_Path] := _Default;
  Result := _Default;
end;

procedure TParams.AssignValue(const _Name: String; _Source: TParam; _ForceAdding: Boolean);
var
  Dst: TParam;
begin

  if _ForceAdding then Dst := Add(_Name)
  else Dst := GetParam(_Name);

  Dst.AssignValue(_Source, Self, _ForceAdding);

end;

procedure TParams.Assign(_Source: TParams; _ForceAdding: Boolean);
var
  Src: TParam;
begin
  for Src in _Source.Items do
    AssignValue(Src.Name, Src, _ForceAdding);
end;

function TParams.AddList(const _Path: String): TMultiParamList;
var
  PathRest: String;
  Params: TParams;
begin

  PathRest := _Path;
  Params := GetPath(PathRest);

  with Params.ListHolder do
    if not Find(PathRest, Result) then
      Result:= Add(PathRest, Params);

end;

procedure TParams.DeleteValue(const _Path: String);
var
  PathRest: String;
  Params: TParams;
  Param: TParam;
begin

  PathRest := _Path;
  if FindPath(PathRest, Params) then

    with Params, Items do begin

      Param := ParamByName(PathRest);
      Delete(IndexOf(Param));

    end

  else raise EParamsException.CreateFmt('Param %s not found', [_Path]);

end;

procedure TParams.Clear;
begin
  Items.Clear;
end;

function TParams.SaveToString: String;

  function _QuoteString(_Param: TParam): String;
  begin

    Result := _Param.AsString;

    if _Param.DataType in [dtAnsiString, dtString] then

      if

          (soForceQuoteStrings in SaveToStringOptions) or
          { Заключаем в кавычки по необходимости. Это только строки с этими символами: }
          (Pos(CR,   Result) > 0) or
          (Pos(LF,   Result) > 0) or
          (Pos(';',  Result) > 0) or
          (Pos('=',  Result) > 0) or
          (Pos(':',  Result) > 0)

      then Result := QuoteStr(Result);

  end;

var
  Param: TParam;
  Value: String;
  Index: Integer;
  First, Last: Boolean;
begin

  Result := '';
  for Param in Items do begin

    if Param.DataType = dtParams then Value := Param.AsParams.SaveToString
    else Value := _QuoteString(Param);

    Index := Items.IndexOf(Param);
    First := Index = 0;
    Last  := Index = Items.Count - 1;

    Result := Result + FormatParam(Param, Value, First, Last);

  end;

end;

procedure TParams.LoadFromString(const _Value: String);
begin

  with ParamsReaderClass.Create(_Value, Self) do

    try

      Read;

    finally
      Free;
    end;

end;

{ TParamsReader }

constructor TParamsReader.Create(const _Source: String; _Params: TParams);
begin
  inherited Create(_Source);
  FParams := _Params;
end;

constructor TParamsReader.CreateNested;
begin
  inherited CreateNested(_MasterParser);
  FParams := _Params;
end;

procedure TParamsReader.CheckPresetType(_Strict: Boolean);
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

function TParamsReader.TrimDigital(const _Value: String): String;
begin
  Result := StringReplace(_Value, ' ', '', [rfReplaceAll]);
end;

function TParamsReader.UndoubleSymbols(const _Value: String): String;
begin

  { Дублировать нужно только одиночный закрывающий регион символ, поэтому и раздублировать только его надо при
    условии, что значение считывается регионом. Поэтому, символ задается событием региона. Но! Здесь будет нужна отмена,
    потому что дублирование не нужно в комментариях совсем. }

  if DoublingChar > #0 then Result := UndoubleStr(_Value, DoublingChar)
  else Result := _Value;

end;

procedure TParamsReader.ReadName;
var
  Value: String;
begin

  Value := ReadElement(True);

  TParam.ValidateName(Value, Params.PathSeparator);
  FCurrentName := Value;

end;

procedure TParamsReader.ReadType;
begin
  FCurrentType := StrToParamDataType(ReadElement(True));
  CheckPresetType(True);
end;

procedure TParamsReader.ReadValue;
var
  Value: String;
  Index: Integer;
begin

  Value := ReadElement(False);

  if PresetTypes then
    CheckPresetType(True);

  { Считывание с зарегистрированными типами должно исполнятся в потомках с помощью отдельных свойств (Registered итд). }
  with Params.AddList(CurrentName) do begin

    if PresetTypes and (Count > 0) then Index := 0
    else Index := Append;

    BeforeReadParam(Items[Index]);

    if Length(Value) > 0 then

      case CurrentType of

        dtBoolean:    AsBoolean   [Index] := StrToBoolean(             Value );
        dtInteger:    AsInteger   [Index] := StrToInt(     TrimDigital(Value));
        dtBigInt:     AsBigInt    [Index] := StrToBigInt(  TrimDigital(Value));
        dtFloat:      AsFloat     [Index] := StrToFloat (  TrimDigital(Value));
        dtExtended:   AsExtended  [Index] := StrToExtended(TrimDigital(Value));
        dtDateTime:   AsDateTime  [Index] := StrToDateTime(            Value );
        dtGUID:       AsGUID      [Index] := StrToGUID(                Value );
        dtAnsiString: AsAnsiString[Index] := StrToAnsiStr   (          Value );
        dtString:     AsString    [Index] := UndoubleSymbols(          Value );
        dtBLOB:       AsBLOB      [Index] := HexStrToBLOB(             Value );
        dtData:       AsData      [Index] := ByteStrToData(            Value );

      end

    else begin

      IsNull[Index] := True;
      SetDataType(Index, CurrentType);

    end;

    AfterReadParam(Items[Index]);

  end;

  FCurrentName := '';
  FCurrentType := dtUnknown;

end;

procedure TParamsReader.ReadParams(_CursorShift: Int64);
var
  P: TParam;
  NestedParams: TParams;
begin

  if PresetTypes and Params.FindParam(CurrentName, dtParams, P) then NestedParams := P.AsParams
  else begin

    NestedParams := TParamsClass(Params.ClassType).Create(Params.PathSeparator, Params.SaveToStringOptions);
    with Params.AddList(CurrentName) do
      P := Items[Append];

    BeforeReadParam(P);

    P.SetAsParams(NestedParams);

  end;

  with TParamsReaderClass(ClassType).CreateNested(Self, NestedParams) do

    try

      Read;
      AfterReadParams(P);
      Self.Move(Cursor - _CursorShift - Self.Cursor);
      Self.Location := Location;

    finally
      Free;
    end;

  AfterReadParam(P);
  FCurrentName := '';
  FCurrentType := dtUnknown;

end;

function TParamsReader.IsParamsType: Boolean;
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

end.
