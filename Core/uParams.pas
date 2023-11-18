unit uParams;

(*********************************************************)
(*                                                       *)
(*                        Hello!)                        *)
(*                                                       *)
(*********************************************************)

interface

uses
  { VCL }
  SysUtils, Generics.Collections,
  { vSoft }
  uCore, uGUID, uStrUtils;

type

  TParamDataType = (dtUnknown, dtBoolean, dtInteger, dtFloat, dtDateTime, dtGUID, dtAnsiString, dtString, dtBLOB, dtParams);

  TParams = class;

  TParam = class

  strict private

    FData: Pointer;

    FDataType: TParamDataType;
    FIsNull: Boolean;
    FName: String;

    { v Changing data methods v }
    function GetAsBoolean: Boolean;
    function GetAsInteger: Int64;
    function GetAsFloat: Double;
    function GetAsDateTime: TDateTime;
    function GetAsGUID: TGUID;
    function GetAsAnsiString: AnsiString;
    function GetAsString: String;
    function GetAsBLOB: RawByteString;
    function GetAsParams: TParams;

    procedure SetAsBoolean(const _Value: Boolean);
    procedure SetAsInteger(const _Value: Int64);
    procedure SetAsFloat(const _Value: Double);
    procedure SetAsDateTime(const _Value: TDateTime);
    procedure SetAsGUID(const _Value: TGUID);
    procedure SetAsAnsiString(const _Value: AnsiString);
    procedure SetAsString(const _Value: String);
    procedure SetAsBLOB(const _Value: RawByteString);
    procedure SetAsParams(const _Value: TParams);
    { ^ Changing data methods ^ }

    procedure SetIsNull(const _Value: Boolean);

    procedure AllocData;
    procedure FreeData;
    function DataSize: Cardinal;
    procedure PresetData(_DataType: TParamDataType);

  protected

    procedure CheckDataType(_DataType: TParamDataType);
    function GetAbstractObject: TObject;
    procedure SetAbstractObject(_Value: TObject);

  public

    constructor Create(const _Name: String);
    destructor Destroy; override;

    procedure Assign(_Source: TParam);
    procedure Clear;

    property DataType: TParamDataType read FDataType;
    property IsNull: Boolean read FIsNull write SetIsNull;
    property Name: String read FName;

    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger: Int64 read GetAsInteger write SetAsInteger;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsGUID: TGUID read GetAsGUID write SetAsGUID;
    property AsAnsiString: AnsiString read GetAsAnsiString write SetAsAnsiString;
    property AsString: String read GetAsString write SetAsString;
    property AsBLOB: RawByteString read GetAsBLOB write SetAsBLOB;
    property AsParams: TParams read GetAsParams write SetAsParams;

  end;

  TParams = class(TObjectList<TParam>)

  end;

function ParamDataTypeToStr(DataType: TParamDataType): String;

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
      { TODO -oVasilyevSM -cVCore : ParamsToStr } 
      dtParams:     Result := '<Params>';

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

procedure TParam.SetAsBoolean(const _Value: Boolean);
begin
  PresetData(dtBoolean);
  Move(_Value, FData^, DataSize);
end;

procedure TParam.SetAsInteger(const _Value: Int64);
begin
  PresetData(dtInteger);
  Move(_Value, FData^, DataSize);
end;

procedure TParam.SetAsFloat(const _Value: Double);
begin
  PresetData(dtFloat);
  Move(_Value, FData^, DataSize);
end;

procedure TParam.SetAsDateTime(const _Value: TDateTime);
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

procedure TParam.SetAsParams(const _Value: TParams);
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
    FData := nil;
  end;

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
    raise ECoreException.Create('Complete this method');
  end;

end;

procedure TParam.PresetData(_DataType: TParamDataType);
begin

  FDataType := _DataType;
  FIsNull := False;

  FreeData;
  AllocData;

end;

procedure TParam.CheckDataType(_DataType: TParamDataType);
begin
  if _DataType <> FDataType then
    raise ECoreException.CreateFmt('Param data type is not %s', [ParamDataTypeToStr(_DataType)])
end;

function TParam.GetAbstractObject: TObject;
begin
  Result := TObject(FData);
end;

procedure TParam.SetAbstractObject(_Value: TObject);
begin
  TObject(FData) :=_Value;
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
    { TODO -oVasilyevSM -cVCore : dtParams }

  else
    raise ECoreException.Create('Complete this method');
  end;

end;

procedure TParam.Clear;
begin

  FreeData;
  FIsNull := True;
  FDataType := dtUnknown;

end;

end.
