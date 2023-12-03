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
(*   \:::\    \     \:::\/:::/    / \/____/ :::\/:::/    / :::\   \/____/_:::\/:::/    /   *)
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

{ TODO 10 -oVasilyevSM -cuParams: Для работы с мультистроковыми параметрами нужно какое-то удобное средство. GetList или
  как табличные записи. Сейчас ParamByName вернет первый из списка и все.  }

interface

uses
  { VCL }
  SysUtils, Generics.Collections,
  { LiberSynth }
  uConsts, uTypes, uCore, uDataUtils, uStrUtils, uCustomStringParser, uParamsStringParser;

type

  { Похоже, что Double это действительно псевдоним Extended. Значения с большим количеством знаков урезаются одинаково.
    Странно только что в Win64 SizeOf(Extended) = 10, а не 16, как утверждает справка по RADStudio. }
  TParamDataType = (dtUnknown, dtBoolean, dtInteger, dtBigInt, dtFloat, dtExtended, dtDateTime, dtGUID, dtAnsiString, dtString, dtBLOB, dtData, dtParams);

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
    FData: Pointer;

    procedure SetIsNull(const _Value: Boolean);

    procedure AllocData;
    procedure FreeData;
    function DataSize: Cardinal;
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

  protected

    procedure CheckDataType(_DataType: TParamDataType);

  public

    constructor Create(const _Name: String; const _PathSeparator: Char = '.');
    destructor Destroy; override;

    procedure Clear;
    { Для передачи без разбора типов }
    procedure AssignValue(_Source: TParam);
    class procedure ValidateName(const _Value, _PathSeparator: String);

    property DataType: TParamDataType read FDataType;
    property IsNull: Boolean read FIsNull write SetIsNull;
    property StrictDataType: Boolean read FStrictDataType write FStrictDataType;
    property Name: String read FName;

    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsBigInt: Int64 read GetAsBigInt write SetAsBigInt;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsExtended: Extended read GetAsExtended write SetAsExtended;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsGUID: TGUID read GetAsGUID write SetAsGUID;
    property AsAnsiString: AnsiString read GetAsAnsiString write SetAsAnsiString;
    property AsString: String read GetAsString write SetAsString;
    property AsBLOB: BLOB read GetAsBLOB write SetAsBLOB;
    property AsData: TData read GetAsData write SetAsData;
    {

      Это свойство должно записываться только из класса TParams по вызову As... с указанием пути. В смысле, в конце
      параметр, но с путем, который создается в виде вложенных параметров. И только так, потому что AsParams, заданный
      снаружи должен оставаться в памяти, пока он нужен создавшему его объекту и должен освобождатсья этим объектом.
      Это ненадежно, потому что допускает вероятность ошибок, влекущих утечки. Да и вообще, каша получится.

    }
    property AsParams: TParams read GetAsParams;

  end;

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

  public

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

  {

    _Name - всегда чистое имя параметра без пути. Путь через "." это _Path, причем, вместе с именем на последнем.
    месте.
    Методы SetAs... создают путь и конечный параметр, используя GetParam, если их нет.
    Метод FindParam ничего не создает, только ищет существующий.
    Метод ParamByName вовсе генерирует исключение, если чего-то не хватает.
    Краткая запись при сохранении с предопределенными типами здесь не поддерживается. Нужно исполнять ее в потомках.

  }

  TSaveToStringOption  = (soSingleString, soForceQuoteStrings, soTypesFree);
  TSaveToStringOptions = set of TSaveToStringOption;

  { Некоторые корневые свойства намеренно задаются один раз при создании объекта. Не нужно их менять на ходу. }
  TParams = class(TObjectList<TParam>)

  strict private

    FPathSeparator: Char;
    FSaveToStringOptions: TSaveToStringOptions;

  private

    function GetIsNull(const _Path: String): Boolean;
    function GetAsBoolean(const _Path: String): Boolean;
    function GetAsInteger(const _Path: String): Integer;
    function GetAsBigInt(const _Path: String): Int64;
    function GetAsFloat(_Path: String): Double;
    function GetAsExtended(_Path: String): Extended;
    function GetAsDateTime(_Path: String): TDateTime;
    function GetAsGUID(_Path: String): TGUID;
    function GetAsAnsiString(_Path: String): AnsiString;
    function GetAsString(_Path: String): String;
    function GetAsBLOB(_Path: String): BLOB;
    function GetAsData(_Path: String): TData;
    function GetAsParams(_Path: String): TParams;

    procedure SetIsNull(const _Path: String; const _Value: Boolean);
    procedure SetAsBoolean(const _Path: String; _Value: Boolean);
    procedure SetAsInteger(const _Path: String; _Value: Integer);
    procedure SetAsBigInt(const _Path: String; _Value: Int64);
    procedure SetAsFloat(_Path: String; _Value: Double);
    procedure SetAsExtended(_Path: String; _Value: Extended);
    procedure SetAsDateTime(_Path: String; _Value: TDateTime);
    procedure SetAsGUID(_Path: String; const _Value: TGUID);
    procedure SetAsAnsiString(_Path: String; const _Value: AnsiString);
    procedure SetAsString(_Path: String; const _Value: String);
    procedure SetAsBLOB(_Path: String; const _Value: BLOB);
    procedure SetAsData(_Path: String; const _Value: TData);
    procedure SetAsParams(_Path: String; _Value: TParams);

    function GetParam(_Path: String): TParam;

  protected

    procedure Notify(const _Item: TParam; _Action: Generics.Collections.TCollectionNotification); override;

  public

    constructor Create(const _PathSeparator: Char = '.'; const _SaveToStringOptions: TSaveToStringOptions = []); overload;
    constructor Create(const _SaveToStringOptions: TSaveToStringOptions); overload;

    function Add(const _Name: String): TParam;
    function Insert(_Index: Integer; const _Name: String): TParam;

    function FindParam(_Path: String; _DataType: TParamDataType; var _Value: TParam): Boolean; overload;
    function FindParam(_Path: String; var _Value: TParam): Boolean; overload;
    function ParamByName(const _Path: String): TParam;

    { Для передачи без разбора типов }
    procedure Assign(_Source: TParams);

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
    // Параметры снаружи не берем

    function SaveToString: String;
    procedure LoadFromString(const _Value: String);
    { TODO 10 -oVasilyevSM -cuParams: SaveToStream/LoadFromStream }

    property IsNull[const _Path: String]: Boolean read GetIsNull write SetIsNull;
    property AsBoolean[const _Path: String]: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger[const _Path: String]: Integer read GetAsInteger write SetAsInteger;
    property AsBigInt[const _Path: String]: Int64 read GetAsBigInt write SetAsBigInt;
    property AsFloat[_Path: String]: Double read GetAsFloat write SetAsFloat;
    property AsExtended[_Path: String]: Extended read GetAsExtended write SetAsExtended;
    property AsDateTime[_Path: String]: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsGUID[_Path: String]: TGUID read GetAsGUID write SetAsGUID;
    property AsAnsiString[_Path: String]: AnsiString read GetAsAnsiString write SetAsAnsiString;
    property AsString[_Path: String]: String read GetAsString write SetAsString;
    property AsBLOB[_Path: String]: BLOB read GetAsBLOB write SetAsBLOB;
    property AsData[_Path: String]: TData read GetAsData write SetAsData;
    property AsParams[_Path: String]: TParams read GetAsParams;

    property PathSeparator: Char read FPathSeparator;
    property SaveToStringOptions: TSaveToStringOptions read FSaveToStringOptions;

    { v Функции и свойства для основной работы v }

  end;

  EParamsException = class(ECoreException);

function ParamDataTypeToStr(Value: TParamDataType): String;
function StrToParamDataType(Value: String): TParamDataType;
function ParamsToStr(Params: TParams): String;
procedure StrToParams(const Value: String; Params: TParams);

implementation

type

  { Этот класс нужен только для обращения к здешним объектам без циркулярной ссылки. Также, благодаря этому свойство
    TParams.AsParams остается только для чтения и метод TParams.SetAsParams private. }
  TParamsReader = class(TParamsStringParser)

  strict private

    FParams: TParams;

    FCurrentName: String;
    FCurrentType: TParamDataType;

    procedure CheckPresetType;
    function TrimDigital(const _Value: String): String;
    function UndoubleSymbols(const _Value: String): String;

  private

    constructor Create(const _Source: String; _Params: TParams);
    constructor CreateNested(

        _MasterParser: TParamsReader;
        _Params: TParams;
        _CursorShift: Int64

    );

  protected

    procedure ReadName(const _KeyWord: TKeyWord); override;
    procedure ReadType(const _KeyWord: TKeyWord); override;
    procedure ReadValue(const _KeyWord: TKeyWord); override;
    procedure ReadParams(const _KeyWord: TKeyWord); override;
    function IsParamsType: Boolean; override;

  end;

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

  {

    Этот метод особый. Он нужен как для прикладных визуальных задач, посколку возвращает отображаемый текст в самом
    корневом виде, так и для отладочных. Можно в виде строки увидеть в отладчике что-то, имеющее непотребный вид.
    Например, дату или GUID. Поэтому здесь проверку типа делать не надо. Пусть возвращает абсолютно все.

  }

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

procedure TParam.SetIsNull(const _Value: Boolean);
begin

  if _Value <> FIsNull then begin

    FIsNull := _Value;
    FreeData;

  end;

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

procedure TParam.AssignValue(_Source: TParam);
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
      dtParams:     AsParams.Assign(_Source.AsParams);

    else
      raise EUncompletedMethod.Create;
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

{ TParams }

constructor TParams.Create(const _PathSeparator: Char; const _SaveToStringOptions: TSaveToStringOptions);
begin

  inherited Create;

  FPathSeparator       := _PathSeparator;
  FSaveToStringOptions := _SaveToStringOptions;

end;

constructor TParams.Create(const _SaveToStringOptions: TSaveToStringOptions);
begin
  Create('.', _SaveToStringOptions);
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

function TParams.GetAsFloat(_Path: String): Double;
begin
  Result := ParamByName(_Path).AsFloat;
end;

function TParams.GetAsExtended(_Path: String): Extended;
begin
  Result := ParamByName(_Path).AsExtended;
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

function TParams.GetAsData(_Path: String): TData;
begin
  Result := ParamByName(_Path).AsData;
end;

function TParams.GetAsParams(_Path: String): TParams;
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

procedure TParams.SetAsFloat(_Path: String; _Value: Double);
begin
  GetParam(_Path).AsFloat := _Value;
end;

procedure TParams.SetAsExtended(_Path: String; _Value: Extended);
begin
  GetParam(_Path).AsExtended := _Value;
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

procedure TParams.SetAsData(_Path: String; const _Value: TData);
begin
  GetParam(_Path).AsData := _Value;
end;

procedure TParams.SetAsParams(_Path: String; _Value: TParams);
begin
  GetParam(_Path).SetAsParams(_Value);
end;

function TParams.GetParam(_Path: String): TParam;
var
  SingleName: String;
  Params: TParams;
  Param: TParam;
begin

  Params := Self;

  { TODO 1 -oVasilyevSM -cTParams.GetParam: Параметрметр не переназначить. Херачит все в новый списком. }
  while Pos(FPathSeparator, _Path) > 0 do begin

    SingleName := ReadStrTo(_Path, FPathSeparator, False);

    if Params.FindParam(SingleName, dtParams, Param) then Params := Param.AsParams
    else

      with Params.Add(SingleName) do begin

        SetAsParams(TParams.Create(PathSeparator, SaveToStringOptions));
        Params := AsParams;

      end;

  end;

  { Для возможности многострочных структур просто параметры не поддерживают чтение без типов. Сохранение с
    зарегистрированными типами должно исполнятся в потомках. Поэтому, просто Add. }
  Result := Params.Add(_Path);

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

    Dst := Add(Src.Name);
    if Src.DataType = dtParams then
      Dst.SetAsParams(TParams.Create(PathSeparator, SaveToStringOptions));

    Dst.AssignValue(Src);

  end;

end;

function TParams.Add(const _Name: String): TParam;
begin
  Result := TParam.Create(_Name, FPathSeparator);
  inherited Add(Result);
end;

function TParams.Insert(_Index: Integer; const _Name: String): TParam;
begin
  Result := TParam.Create(_Name, FPathSeparator);
  inherited Insert(_Index, Result);
end;

function TParams.FindParam(_Path: String; _DataType: TParamDataType; var _Value: TParam): Boolean;
var
  SingleName: String;
  Params: TParams;
  Param: TParam;
begin

  Params := Self;

  while Pos(FPathSeparator, _Path) > 0 do begin

    SingleName := ReadStrTo(_Path, FPathSeparator, False);

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

function TParams.SaveToString: String;
const

  SC_SINGLE_PARAM_TYPED_MULTI_STRING     = '%0:s: %2:s = %1:s' + CRLF;
  SC_SINGLE_PARAM_UNTYPED_MULTI_STRING   = '%0:s = %1:s' + CRLF;
  SC_SINGLE_PARAM_TYPED_SINGLE_STRING    = '%0:s:%2:s=%1:s;';
  SC_SINGLE_PARAM_UNTYPED_SINGLE_STRING  = '%0:s=%1:s;';
  SC_NESTED_PARAMS_TYPED_MULTI_STRING    = '%0:s: %2:s = (' + CRLF + '%1:s' + ')' + CRLF;
  SC_NESTED_PARAMS_UNTYPED_MULTI_STRING  = '%0:s = (' + CRLF + '%1:s' + ')' + CRLF;
  SC_NESTED_PARAMS_TYPED_SINGLE_STRING   = '%0:s:%2:s=(%1:s);';
  SC_NESTED_PARAMS_UNTYPED_SINGLE_STRING = '%0:s=(%1:s);';

  function _GetNested(_Param: TParam): String;
  begin
    Result := _Param.AsParams.SaveToString;
    if not (soSingleString in SaveToStringOptions) then
      ShiftText(1, Result);
  end;

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
          (Pos('''', Result) > 0) or
          (Pos('"',  Result) > 0) or
          (Pos('(',  Result) > 0) or
          (Pos(')',  Result) > 0)

      then Result := QuoteStr(Result);

  end;

var
  SingleParamFormat: String;
  NestedParamsFormat: String;
  Param: TParam;
begin

  if soSingleString in SaveToStringOptions then

    if soTypesFree in SaveToStringOptions then begin

      SingleParamFormat  := SC_SINGLE_PARAM_UNTYPED_SINGLE_STRING;
      NestedParamsFormat := SC_NESTED_PARAMS_UNTYPED_SINGLE_STRING;

    end else begin

      SingleParamFormat  := SC_SINGLE_PARAM_TYPED_SINGLE_STRING;
      NestedParamsFormat := SC_NESTED_PARAMS_TYPED_SINGLE_STRING;

    end

  else

    if soTypesFree in SaveToStringOptions then begin

      SingleParamFormat  := SC_SINGLE_PARAM_UNTYPED_MULTI_STRING;
      NestedParamsFormat := SC_NESTED_PARAMS_UNTYPED_MULTI_STRING;

    end else begin

      SingleParamFormat  := SC_SINGLE_PARAM_TYPED_MULTI_STRING;
      NestedParamsFormat := SC_NESTED_PARAMS_TYPED_MULTI_STRING;

    end;

  Result := '';
  for Param in Self do

    if Param.DataType = dtParams then

      Result := Result + Format(NestedParamsFormat, [

          Param.Name,
          _GetNested(Param),
          ParamDataTypeToStr(Param.DataType)

      ])

    else

      Result := Result + Format(SingleParamFormat, [

          Param.Name,
          _QuoteString(Param),
          ParamDataTypeToStr(Param.DataType)

      ]);

  if soSingleString in SaveToStringOptions then
    CutStr(Result, 1);

end;

procedure TParams.LoadFromString(const _Value: String);
begin

  with TParamsReader.Create(_Value, Self) do

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
  inherited CreateNested(_MasterParser, _CursorShift);
  FParams := _Params;
end;

procedure TParamsReader.CheckPresetType;
var
  P: TParam;
begin

  { Определенный заранее тип данных }
  if

      (FCurrentType = dtUnknown) and
      FParams.FindParam(FCurrentName, P) and
      (P.DataType <> dtUnknown)

  then FCurrentType := P.DataType;

  if FCurrentType = dtUnknown then
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
    потому что дублирование не нужно в комментариях. }

  if DoublingChar > #0 then Result := UndoubleStr(_Value, DoublingChar)
  else Result := _Value;

end;

procedure TParamsReader.ReadName(const _KeyWord: TKeyWord);
var
  Value: String;
begin

  Value := ReadItem(True);

  TParam.ValidateName(Value, FParams.PathSeparator);
  FCurrentName := Value;

end;

procedure TParamsReader.ReadType(const _KeyWord: TKeyWord);
begin
  FCurrentType := StrToParamDataType(ReadItem(True));
  CheckPresetType;
end;

procedure TParamsReader.ReadValue(const _KeyWord: TKeyWord);
var
  Value: String;
begin

  Value := ReadItem(False);

  { Здесь нужно это вызывать. Тип может не храниться в строке и его чтения не будет. Тогда вытаскиваем его здесь. }
  CheckPresetType;

  if Length(Value) > 0 then

    case FCurrentType of

      dtBoolean:    FParams.AsBoolean   [FCurrentName] := StrToBoolean(             Value );
      dtInteger:    FParams.AsInteger   [FCurrentName] := StrToInt(     TrimDigital(Value));
      dtBigInt:     FParams.AsBigInt    [FCurrentName] := StrToBigInt(  TrimDigital(Value));
      dtFloat:      FParams.AsFloat     [FCurrentName] := StrToFloat (  TrimDigital(Value));
      dtExtended:   FParams.AsExtended  [FCurrentName] := StrToExtended(TrimDigital(Value));
      dtDateTime:   FParams.AsDateTime  [FCurrentName] := StrToDateTime(            Value );
      dtGUID:       FParams.AsGUID      [FCurrentName] := StrToGUID(                Value );
      dtAnsiString: FParams.AsAnsiString[FCurrentName] := StrToAnsiStr   (          Value );
      dtString:     FParams.AsString    [FCurrentName] := UndoubleSymbols(          Value );
      dtBLOB:       FParams.AsBLOB      [FCurrentName] := HexStrToBLOB(             Value );
      dtData:       FParams.AsData      [FCurrentName] := ByteStrToData(            Value );

    end

  else

    with FParams.GetParam(FCurrentName) do begin

      IsNull := True;
      SetDataType(FCurrentType);

    end;

  FCurrentName := '';
  FCurrentType := dtUnknown;

end;

procedure TParamsReader.ReadParams(const _KeyWord: TKeyWord);
var
  P: TParams;
begin

  P := TParams.Create(FParams.PathSeparator, FParams.SaveToStringOptions);
  try

    with TParamsReader.CreateNested(Self, P, _KeyWord.KeyLength) do

      try

        Read;

      finally

        Self.Move(Cursor - _KeyWord.KeyLength - Self.Cursor);
        Self.Location := Location;

        Free;

      end;

  finally

    FParams.SetAsParams(FCurrentName, P);

    CompleteItem;
    FCurrentName := '';
    FCurrentType := dtUnknown;

    inherited ReadParams(_KeyWord);

  end;

end;

function TParamsReader.IsParamsType: Boolean;
begin
  Result := FCurrentType = dtParams;
end;

end.
