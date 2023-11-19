unit uParams;

(*********************************************************)
(*                                                       *)
(*                        Hello!)                        *)
(*                                                       *)
(*********************************************************)

{ TODO -oVasilyevSM -cParams: Нужна оболочка TIniParams, которая будет сохраняться в файл, указанный в конструкторе. }
{ TODO -oVasilyevSM -cParams: Кроме SaveToFile нужны SaveToStream and LoadFromStream }
{ TODO -oVasilyevSM -cParams: Нужен режим AutoSave. В каждом SetAs вызывать в нем SaveTo... Куда to - выставлять еще одним свойством или комбайном None, ToFile, ToStream }
{ TODO -oVasilyevSM -cParams: Нужен также компонент TRegParams }
{ TODO -oVasilyevSM -cParams : Идея хорошая, преобразовывать все во все в методах TParam.GetAs..., но это нужен режим отдельный Hard/Soft и код засрется. Если понадобится, можно потом сделать. }

interface

uses
  { VCL }
  SysUtils, Generics.Collections,
  { vSoft }
  uConsts, uTypes, uCore, uDataUtils, uStrUtils;

type

  { TODO -oVasilyevSM -cParams : Насчет Extended нужно еще раз сравнить датабазные возможности Float и дельфевые }
  TParamDataType = (dtUnknown, dtBoolean, dtInteger, dtBigInt, dtFloat, {dtExtended, }dtDateTime, dtGUID, dtAnsiString, dtString, dtBLOB, {dtData (TData),}dtParams);

  TParams = class;

  TParam = class

  const

    SC_SELF_ALLOCATED_TYPES = [dtAnsiString, dtString, dtBLOB, dtParams];

  strict private

    FName: String;
    FDataType: TParamDataType;
    FIsNull: Boolean;
    FData: Pointer;

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
    private procedure SetAsParams(_Value: TParams);
    { ^ Using FData methods ^ }

    strict private procedure SetIsNull(const _Value: Boolean);

    procedure AllocData;
    procedure FreeData;
    function DataSize: Cardinal;
    procedure PresetData(_DataType: TParamDataType);

  protected

    procedure CheckDataType(_DataType: TParamDataType);

  public

    constructor Create(const _Name: String);
    destructor Destroy; override;

    procedure Clear;
    { Для абстрактной типу передачи }
    procedure Assign(_Source: TParam);

    property DataType: TParamDataType read FDataType;
    property IsNull: Boolean read FIsNull write SetIsNull;
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

      Это свойство должно записываться только из класса TParams по вызову As... с указанием пути. Потому что AsParams,
      заданный снаружи должен оставаться в памяти, пока он нужен создавшему его объекту и должен освободиться этим
      объектом. Это ненадежно, потому что утечки случаются при таком подходе. Да и вообще, каша получится.

    }
    property AsParams: TParams read GetAsParams;

  end;

  TParams = class(TObjectList<TParam>)

    {

      _Name - всегда чистое имя параметра без пути. Путь через "." это _Path, причем, вместе с именем на последнем
      месте.
      Методы SetAs... создают путь и конечный параметр, используя GetParam, если их нет.
      Метод FindParam ничего не создает, только ищет существующий.
      Метод ParamByName вовсе генерирует исключение, если чего-то не хватает.

    }

  strict private

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

    function GetParam(_Path: String): TParam;

  protected

    procedure Notify(const _Item: TParam; _Action: Generics.Collections.TCollectionNotification); override;

  public

    function Add(const _Name: String): TParam;
    function Insert(_Index: Integer; const _Name: String): TParam;

    function FindParam(_Path: String; _DataType: TParamDataType; var _Value: TParam): Boolean; overload;
    function FindParam(_Path: String; var _Value: TParam): Boolean; overload;
    function ParamByName(const _Path: String): TParam;

    { Для абстрактной по типу передачи }
    procedure Assign(_Source: TParams);

    { v Функции и свойства для основной работы v }
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
    { v Функции и свойства для основной работы v }

  end;

  EParamsException = class(ECoreException);

function ParamDataTypeToStr(Value: TParamDataType): String;
function StrToParamDataType(Value: String): TParamDataType;
{ TODO -oVasilyevSM -cParams: В функции ParamsToStr нужен еще один режим, явное указание типа параметра в ини-файле или без него. И тогда тип должен определяться в приложении через предварительный вызов функций RegisterParam. Таким образом, имеем два формата ини-файла, полный и краткий. В StrToParams - или на входе пустой контейнер, куда добавляются параметры, или готовая структура, тогда она просто заполняется и типы данных известны и не требуют хранения в строке. }
function ParamsToStr(Params: TParams): String;

implementation

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

function ParamsToStr(Params: TParams): String;
const

  SC_SingleParamFormat = '%s = %s' + CRLF;

  SC_NestedParamsFormat =

      '%s = (' + CRLF +
      '%s' +
      ')' + CRLF;

var
  Param: TParam;
begin

  { TODO -oVasilyevSM -cParams : Пока так }

  Result := '';
  for Param in Params do

    if Param.DataType = dtParams then

      Result := Result + Format(SC_NestedParamsFormat, [

          Param.Name,
          ShiftText(Param.AsString, 1)

      ])

    else

      Result := Result + Format(SC_SingleParamFormat, [

          Param.Name,
          Param.AsString

      ]);

end;

{ TParam }

constructor TParam.Create;
begin

  inherited Create;

  FIsNull := True;
  FName   := _Name;

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

    Этот метод особый. Он нужен как для прикладных визуальных задач, посколку возвращает отображаемый текст в самом
    корневом виде, так и для отладочных. Можно в виде строки увидеть в отладчике что-то, имеющее непотребный вид.
    Например, дату или GUID. Поэтому здесь проверку типа делать не надо. Пусть возвращает абсолютно все.

  }

  if IsNull then Result := ''
  else

    case FDataType of

      dtUnknown:    Result := '';
      dtBoolean:    Result := BooleanToStr(AsBoolean);
      dtInteger:    Result := IntToStr(AsInteger);
      dtBigInt:     Result := IntToStr(AsBigInt);
      dtFloat:      Result := DoubleToStr(AsFloat);
      dtDateTime:   Result := DateTimeToStr(AsDateTime);
      dtGUID:       Result := GUIDToStr(AsGUID);
      dtAnsiString: Result := String(AnsiString(FData));
      dtString:     Result := String(FData);
      dtBLOB:       Result := BLOBToStr(AsBLOB);
      dtParams:     Result := ParamsToStr(TParams(FData));

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

    raise EParamsException.CreateFmt('This param can not read data type %s as %s', [

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

{ TParams }

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

  if Params.FindParam(_Path, Param) then Result := Param
  else Result := Params.Add(_Path);

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

end.
