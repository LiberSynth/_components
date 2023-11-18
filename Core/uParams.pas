unit uParams;

(*********************************************************)
(*                                                       *)
(*                        Hello!)                        *)
(*                                                       *)
(*********************************************************)

{ TODO -oVasilyevSM -cVCore: Нужна оболочка TIniParams, которая будет сохраняться в файл, указанный в конструкторе. }
{ TODO -oVasilyevSM -cVCore: Кроме SaveToFile нужны SaveToStream and LoadFromStream }
{ TODO -oVasilyevSM -cVCore: Нужен режим AutoSave. В каждом SetAs вызывать в нем SaveTo... Куда to - выставлять еще одним свойством или комбайном None, ToFile, ToStream }
{ TODO -oVasilyevSM -cVCore: Нужен также компонент TRegParams }

interface

uses
  { VCL }
  SysUtils, Generics.Collections,
  { vSoft }
  uConsts, uTypes, uCore, uGUID, uStrUtils;

type

  TParamDataType = (dtUnknown, dtBoolean, dtInteger, dtFloat, dtDateTime, dtGUID, dtAnsiString, dtString, dtBLOB, dtParams);

  TParams = class;

  TParam = class

  strict private

    FName: String;
    FDataType: TParamDataType;
    FIsNull: Boolean;
    FData: Pointer;

    { v Using FData methods v }
    function GetAsBoolean: Boolean;
    function GetAsInteger: Int64;
    function GetAsFloat: Double;
    function GetAsDateTime: TDateTime;
    function GetAsGUID: TGUID;
    function GetAsAnsiString: AnsiString;
    function GetAsString: String;
    function GetAsBLOB: RawByteString;
    function GetAsParams: TParams;

    procedure SetAsBoolean(_Value: Boolean);
    procedure SetAsInteger(_Value: Int64);
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
    { Для абстрактной по типу передачи }
    procedure Assign(_Source: TParam);

    property DataType: TParamDataType read FDataType;
    property IsNull: Boolean read FIsNull write SetIsNull;
    property Name: String read FName;

    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger: Int64 read GetAsInteger write SetAsInteger;
    { TODO -oVasilyevSM -cVCore : AsInt64 (AsBigInt) }
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
    function GetAsFloat(_Path: String): Double;
    function GetAsDateTime(_Path: String): TDateTime;
    function GetAsGUID(_Path: String): TGUID;
    function GetAsAnsiString(_Path: String): AnsiString;
    function GetAsString(_Path: String): String;
    function GetAsBLOB(_Path: String): BLOB;
    function GetAsParams(_Path: String): TParams;

    procedure SetAsBoolean(const _Path: String; _Value: Boolean);
    procedure SetAsInteger(const _Path: String; _Value: Integer);
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

    { Для основной работы }
    function FindBoolean(const _Path: String; var _Value: Boolean): Boolean;
    function FindInteger(const _Path: String; var _Value: Integer): Boolean;
    function FindFloat(const _Path: String; var _Value: Double): Boolean;
    function FindDateTime(const _Path: String; var _Value: TDateTime): Boolean;
    function FindGUID(const _Path: String; var _Value: TGUID): Boolean;
    function FindAnsiString(const _Path: String; var _Value: AnsiString): Boolean;
    function FindString(const _Path: String; var _Value: String): Boolean;
    function FindBLOB(const _Path: String; var _Value: BLOB): Boolean;
    function FindParams(const _Path: String; var _Value: TParams): Boolean;

    property AsBoolean[const _Path: String]: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger[const _Path: String]: Integer read GetAsInteger write SetAsInteger;
    property AsFloat[_Path: String]: Double read GetAsFloat write SetAsFloat;
    property AsDateTime[_Path: String]: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsGUID[_Path: String]: TGUID read GetAsGUID write SetAsGUID;
    property AsAnsiString[_Path: String]: AnsiString read GetAsAnsiString write SetAsAnsiString;
    property AsString[_Path: String]: String read GetAsString write SetAsString;
    property AsBLOB[_Path: String]: BLOB read GetAsBLOB write SetAsBLOB;
    property AsParams[_Path: String]: TParams read GetAsParams;

  end;

  EParamsException = class(ECoreException);

function ParamDataTypeToStr(DataType: TParamDataType): String;
{ TODO -oVasilyevSM -cVCore: В функции ParamsToStr нужен еще один режим, явное указание типа параметра в ини-файле или без него. И тогда тип должен определяться в приложении через предварительный вызов функций RegisterParam. Таким образом, имеем два формата ини-файла, полный и краткий. В StrToParams - или на входе пустой контейнер, куда добавляются параметры, или готовая структура, тогда она просто заполняется и типы данных известны и не требуют хранения в строке. }
function ParamsToString(Params: TParams): String;

implementation

function ParamDataTypeToStr(DataType: TParamDataType): String;
const

  SA_StringValues: array[TParamDataType] of String = (

      { dtUnknown    } 'Unknown',
      { dtBoolean    } 'Boolean',
      { dtInteger    } 'Integer',
      { dtFloat      } 'Float',
      { dtDateTime   } 'DateTime',
      { dtGUID       } 'GUID',
      { dtAnsiString } 'AnsiString',
      { dtString     } 'String',
      { dtBLOB       } 'BLOB',
      { dtParams     } 'Params'

  );

begin
  Result := SA_StringValues[DataType];
end;

function ParamsToString(Params: TParams): String;
const

  SC_SingleParamFormat = '%s = %s' + CRLF;

  SC_NestedParamsFormat =

      '%s = (' + CRLF +
      '%s' +
      ')' + CRLF;

var
  Param: TParam;
begin

  { TODO -oVasilyevSM -cVCore : Пока так }

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

function TParam.GetAsInteger: Int64;
begin

  CheckDataType(dtInteger);

  { TODO -oVasilyevSM -cVCore : Boolean AsInteger это 0 и 1. 0 и 1 AsBoolean это False и True. Это может быть удобно, когда отправляешь куда-то значения, где boolean это Integer. Других типов тоже касается. Нужен режим строгой и "нестрого типизации". По-умолчанию - нестрогая и тогда все преобразуется во все по возможности. }
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

  if IsNull then Result := ''
  else

    case FDataType of

      dtBoolean:    Result := BooleanToStr(AsBoolean);
      dtInteger:    Result := IntToStr(AsInteger);
      dtFloat:      Result := StringReplace(FloatToStr(AsFloat), {$IFNDEF DELPHI2010}FormatSettings.{$ENDIF}DecimalSeparator, '.', []);
      dtDateTime:   Result := FormatDateTime(AsDateTime, True);
      dtGUID:       Result := GUIDToString(AsGUID);
      dtAnsiString: Result := String(AnsiString(FData));
      dtString:     Result := String(FData);
      dtBLOB:       Result := RawByteStringToHex(AsBLOB);
      dtParams:     Result := ParamsToString(TParams(FData));

    else
      Result := '';
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

procedure TParam.SetAsInteger(_Value: Int64);
begin
  PresetData(dtInteger);
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
  FData := AllocMem(DataSize);
end;

procedure TParam.FreeData;
begin

  case FDataType of

    dtAnsiString: AnsiString(FData)    := '';
    dtString:     String(FData)        := '';
    dtBLOB:       RawByteString(FData) := '';
    dtParams:     FData := nil;

  else
    FreeMemory(FData);
  end;

  FData := nil;

end;

function TParam.DataSize: Cardinal;
begin

  case FDataType of

    dtUnknown:    Result := 0;
    dtBoolean:    Result := SizeOf(Boolean);
    dtInteger:    Result := SizeOf(Int64);
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
  if _DataType <> FDataType then
    raise EParamsException.CreateFmt('Param data type is not %s', [ParamDataTypeToStr(_DataType)])
end;

procedure TParam.Assign(_Source: TParam);
begin

  case _Source.DataType of

    dtBoolean:    AsBoolean    := _Source.AsBoolean;
    dtInteger:    AsInteger    := _Source.AsInteger;
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
  if not FindBoolean(_Path, Result) then
    Result := False;
end;

function TParams.GetAsInteger(const _Path: String): Integer;
begin
  if not FindInteger(_Path, Result) then
    Result := 0;
end;

function TParams.GetAsFloat(_Path: String): Double;
begin
  if not FindFloat(_Path, Result) then
    Result := 0;
end;

function TParams.GetAsDateTime(_Path: String): TDateTime;
begin
  if not FindDateTime(_Path, Result) then
    Result := 0;
end;

function TParams.GetAsGUID(_Path: String): TGUID;
begin
  if not FindGUID(_Path, Result) then
    Result := NULLGUID;
end;

function TParams.GetAsAnsiString(_Path: String): AnsiString;
begin
  if not FindAnsiString(_Path, Result) then
    Result := '';
end;

function TParams.GetAsString(_Path: String): String;
begin
  if not FindString(_Path, Result) then
    Result := '';
end;

function TParams.GetAsBLOB(_Path: String): BLOB;
begin
  if not FindBLOB(_Path, Result) then
    Result := '';
end;

function TParams.GetAsParams(_Path: String): TParams;
begin
  if not FindParams(_Path, Result) then
    Result := nil;
end;

procedure TParams.SetAsBoolean(const _Path: String; _Value: Boolean);
begin
  GetParam(_Path).AsBoolean := _Value;
end;

procedure TParams.SetAsInteger(const _Path: String; _Value: Integer);
begin
  GetParam(_Path).AsInteger := _Value;
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
    _Item.AsParams.Free;

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
    raise EParamsException.CreateFmt('Param ''%s'' not found', [_Path]);
end;

function TParams.FindBoolean(const _Path: String; var _Value: Boolean): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, P);
  if Result then _Value := P.AsBoolean;
end;

function TParams.FindInteger(const _Path: String; var _Value: Integer): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, P);
  if Result then _Value := P.AsInteger;
end;

function TParams.FindFloat(const _Path: String; var _Value: Double): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, P);
  if Result then _Value := P.AsFloat;
end;

function TParams.FindDateTime(const _Path: String; var _Value: TDateTime): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, P);
  if Result then _Value := P.AsDateTime;
end;

function TParams.FindGUID(const _Path: String; var _Value: TGUID): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, P);
  if Result then _Value := P.AsGUID;
end;

function TParams.FindAnsiString(const _Path: String; var _Value: AnsiString): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, P);
  if Result then _Value := P.AsAnsiString;
end;

function TParams.FindString(const _Path: String; var _Value: String): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, P);
  if Result then _Value := P.AsString;
end;

function TParams.FindBLOB(const _Path: String; var _Value: BLOB): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, P);
  if Result then _Value := P.AsBLOB;
end;

function TParams.FindParams(const _Path: String; var _Value: TParams): Boolean;
var
  P: TParam;
begin
  Result := FindParam(_Path, P);
  if Result then _Value := P.AsParams;
end;

end.
