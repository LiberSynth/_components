unit uCore;

interface

uses
  { VCL }
  SysUtils,
  { vSoft }
  uGUID;

type

  TCoreDataType = (dtUnknown, dtBoolean, dtInteger, dtFloat, dtDateTime, dtGUID, dtAnsiString, dtString, dtBLOB);

  ECoreException = class(Exception);

  TDataHolder = class

  strict private

    FData: Pointer;
    FDataType: TCoreDataType;
    FPersistentDataType: Boolean;

    function GetIsNull: Boolean;
    function GetAsBoolean: Boolean;
    procedure SetAsBoolean(const _Value: Boolean);
    function GetAsInteger: Int64;
    procedure SetAsInteger(const _Value: Int64);
    function GetAsFloat: Double;
    procedure SetAsFloat(const _Value: Double);
    function GetAsDateTime: TDateTime;
    procedure SetAsDateTime(const _Value: TDateTime);
    function GetAsGUID: TGUID;
    procedure SetAsGUID(const _Value: TGUID);
    function GetAsAnsiString: AnsiString;
    procedure SetAsAnsiString(const _Value: AnsiString);
    function GetAsString: String;
    procedure SetAsString(const _Value: String);
    function GetAsBLOB: RawByteString;
    procedure SetAsBLOB(const _Value: RawByteString);

    procedure AllocData;
    procedure FreeData;
    function DataSize: Cardinal;

  protected

    procedure CheckDataType(_DataType: TCoreDataType);

    property Data: Pointer read FData write FData;

  public

    constructor Create(_DataType: TCoreDataType); overload;
    destructor Destroy; override;

    procedure Assign(_Source: TDataHolder);
    procedure Clear;

    property DataType: TCoreDataType read FDataType;
    property IsNull: Boolean read GetIsNull;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger: Int64 read GetAsInteger write SetAsInteger;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsGUID: TGUID read GetAsGUID write SetAsGUID;
    property AsAnsiString: AnsiString read GetAsAnsiString write SetAsAnsiString;
    property AsString: String read GetAsString write SetAsString;
    property AsBLOB: RawByteString read GetAsBLOB write SetAsBLOB;

  end;

  TNamedDataHolder = class(TDataHolder)

  strict private

    FName: String;

  public

    constructor Create(const _Name: String); overload;
    constructor Create(_DataType: TCoreDataType; const _Name: String); overload;

    property Name: String read FName write FName;

  end;

function CoreDataTypeToStr(DataType: TCoreDataType): String;

function BooleanToStr(Value: Boolean): String;
function StrToBoolean(const S: String): Boolean;

function RawByteStringToHex(const Value: RawByteString): String;
function HexToRawByteString(const Value: String): RawByteString;

implementation

function CoreDataTypeToStr(DataType: TCoreDataType): String;
const

  AC_StringValues: array [TCoreDataType] of String = (

      { dtUnknown    } 'Unknown',
      { dtBoolean    } 'Boolean',
      { dtInteger    } 'Integer',
      { dtFloat      } 'Float',
      { dtDateTime   } 'DateTime',
      { dtGUID       } 'GUID',
      { dtAnsiString } 'AnsiString',
      { dtString     } 'String',
      { dtBLOB       } 'BLOB'

  );

begin
  Result := AC_StringValues[DataType];
end;

function BooleanToStr(Value: Boolean): String;
begin
  if Value then Result := 'True'
  else Result := 'False';
end;

function StrToBoolean(const S: String): Boolean;
begin

  if SameText(S, 'FALSE') then Exit(False);
  if SameText(S, 'TRUE' ) then Exit(True );

  raise EConvertError.CreateFmt('%s is not a boolean value', [S]);

end;

function RawByteStringToHex(const Value: RawByteString): String;
const

  HexChars: array[0..15] of Char = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');

var
  P: Pointer;
  i: Integer;
  B: Byte;
begin

  SetLength(Result, Length(Value) * 2 + 2);
  Result[1] := '0';
  Result[2] := 'x';
  P := Pointer(Value);

  for i := 1 to Length(Value) do begin

    B := Byte(Pointer(Integer(P) + i - 1)^);
    Result[i * 2 + 1] := HexChars[B div 16];
    Result[i * 2 + 2] := HexChars[B mod 16];

  end;

end;

function HexToRawByteString(const Value: String): RawByteString;
var
  i: Integer;
  B: Byte;
begin

  SetLength(Result, (Length(Value) - 2) div 2);

  for i := 1 to Length(Result) do begin

    B := StrToInt('$' + Value[i * 2 + 1] + Value[i * 2 + 2]);
    Byte(Result[i]) := B;

  end;

end;

{ TDataHolder }

procedure TDataHolder.AllocData;
begin
  FData := AllocMem(DataSize);
end;

procedure TDataHolder.Assign(_Source: TDataHolder);
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

  end;

end;

procedure TDataHolder.CheckDataType(_DataType: TCoreDataType);
begin

  if FDataType <> _DataType then

    if FPersistentDataType then

      raise ECoreException.CreateFmt('Holder data type is not %s', [CoreDataTypeToStr(_DataType)])

    else begin

      FreeData;
      FDataType := _DataType;

    end;

end;

constructor TDataHolder.Create(_DataType: TCoreDataType);
begin

  inherited Create;

  FDataType           := _DataType;
  FPersistentDataType := True;

end;

procedure TDataHolder.Clear;
begin
  FreeData;
end;

function TDataHolder.DataSize: Cardinal;
begin

  case FDataType of

    dtBoolean:    Result := SizeOf(Boolean);
    dtInteger:    Result := SizeOf(Int64);
    dtFloat:      Result := SizeOf(Double);
    dtDateTime:   Result := SizeOf(TDateTime);
    dtAnsiString: Result := 0;
    dtString:     Result := 0;
    dtGUID:       Result := SizeOf(TGUID);
    dtBLOB:       Result := 0;

  else
    Result := 0;
  end;

end;

destructor TDataHolder.Destroy;
begin
  FreeData;
  inherited Destroy;
end;

procedure TDataHolder.FreeData;
begin

  case FDataType of

    dtAnsiString: AnsiString(FData)    := '';
    dtString:     String(FData)        := '';
    dtBLOB:       RawByteString(FData) := '';

  else
    FreeMemory(FData);
    FData := nil;
  end;

end;

function TDataHolder.GetAsAnsiString: AnsiString;
begin
  CheckDataType(dtAnsiString);
  Result := AnsiString(FData);
end;

function TDataHolder.GetAsBLOB: RawByteString;
begin
  CheckDataType(dtBLOB);
  Result := RawByteString(FData);
end;

function TDataHolder.GetAsBoolean: Boolean;
begin

  CheckDataType(dtBoolean);

  if IsNull then Result := False
  else Move(FData^, Result, DataSize);

end;

function TDataHolder.GetAsDateTime: TDateTime;
begin

  CheckDataType(dtDateTime);

  if IsNull then Result := 0
  else Move(FData^, Result, DataSize);

end;

function TDataHolder.GetAsFloat: Double;
begin

  CheckDataType(dtFloat);

  if IsNull then Result := 0
  else Move(FData^, Result, DataSize);

end;

function TDataHolder.GetAsGUID: TGUID;
begin

  CheckDataType(dtGUID);

  if IsNull then Result := NullGUID
  else Move(FData^, Result, DataSize);

end;

function TDataHolder.GetAsInteger: Int64;
begin

  CheckDataType(dtInteger);

  if IsNull then Result := 0
  else Move(FData^, Result, DataSize);

end;

function TDataHolder.GetAsString: String;
begin

  if IsNull then Result := ''
  else

    case FDataType of

      dtBoolean:    Result := BooleanToStr(AsBoolean);
      dtInteger:    Result := IntToStr(AsInteger);
      dtFloat:      Result := StringReplace(FloatToStr(AsFloat), {$IFNDEF DELPHI2010}FormatSettings.{$ENDIF}DecimalSeparator, '.', []);
  //    dtDateTime:   Result := FormatDateTime(AsDateTime, True);
      dtGUID:       Result := GUIDToString(AsGUID);
      dtAnsiString: Result := String(AnsiString(FData));
      dtString:     Result := String(FData);
      dtBLOB:       Result := RawByteStringToHex(RawByteString(FData));

    else
      Result := '';
    end;

end;

function TDataHolder.GetIsNull: Boolean;
begin
  Result := FData = nil;
end;

procedure TDataHolder.SetAsAnsiString(const _Value: AnsiString);
begin
  CheckDataType(dtAnsiString);
  AllocData;
  AnsiString(FData) := _Value;
end;

procedure TDataHolder.SetAsBLOB(const _Value: RawByteString);
begin
  CheckDataType(dtBLOB);
  AllocData;
  RawByteString(FData) := _Value;
end;

procedure TDataHolder.SetAsBoolean(const _Value: Boolean);
begin
  CheckDataType(dtBoolean);
  AllocData;
  Move(_Value, FData^, DataSize);
end;

procedure TDataHolder.SetAsDateTime(const _Value: TDateTime);
begin
  CheckDataType(dtDateTime);
  AllocData;
  Move(_Value, FData^, DataSize);
end;

procedure TDataHolder.SetAsFloat(const _Value: Double);
begin
  CheckDataType(dtFloat);
  AllocData;
  Move(_Value, FData^, DataSize);
end;

procedure TDataHolder.SetAsGUID(const _Value: TGUID);
begin
  CheckDataType(dtGUID);
  AllocData;
  Move(_Value, FData^, DataSize);
end;

procedure TDataHolder.SetAsInteger(const _Value: Int64);
begin
  CheckDataType(dtInteger);
  AllocData;
  Move(_Value, FData^, DataSize);
end;

procedure TDataHolder.SetAsString(const _Value: String);
begin
  CheckDataType(dtString);
  AllocData;
  String(FData) := _Value;
end;

{ TNamedDataHolder }

constructor TNamedDataHolder.Create(const _Name: String);
begin
  FName := _Name;
  inherited Create;
end;

constructor TNamedDataHolder.Create(_DataType: TCoreDataType; const _Name: String);
begin
  FName := _Name;
  inherited Create(_DataType);
end;

end.
