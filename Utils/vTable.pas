unit vTable;

interface

uses
  SysUtils, Generics.Collections;

type

  { TODO -oVasilyevSM -cdeprecatred unit: The idea was примитивный движок для совсем простого однопоточного хранения данных. }
  { TODO -oVasilyevSM -cdeprecatred unit: Данные должны храниться одним общим массивом и считываться полями по значению сдвига, вычисляемомоу при изменении. }
  TDataType = (dtBoolean, dtInteger, dtFloat, dtDateTime, dtGUID, dtString, dtBLOB);

  TPointerList = class(TList<Pointer>)
  private
    FDataType: TDataType;
    function Add: Integer;
    procedure Insert(_Index: Integer);
    procedure Alloc(_Index: Integer);
    procedure FreeAndNilData(_Index: Integer);
    procedure FreeData(_Pointer: Pointer);
  protected
    procedure Notify(const _Item: Pointer; _Action: TCollectionNotification); override;
  public
    constructor Create(_DataType: TDataType);
  end;

  TTableField = class
  private

    FFieldName: String;
    FDataType: TDataType;
    FData: TPointerList;

    procedure CheckRecNo(_RecNo: Integer);
    procedure CheckDataType(_DataType: TDataType);

    function GetIsNull(_RecNo: Integer): Boolean;
    procedure SetIsNull(_RecNo: Integer; const _Value: Boolean);
    function GetAsBoolean(_RecNo: Integer): Boolean;
    procedure SetAsBoolean(_RecNo: Integer; const _Value: Boolean);
    function GetAsInteger(_RecNo: Integer): Integer;
    procedure SetAsInteger(_RecNo: Integer; const _Value: Integer);
    function GetAsFloat(_RecNo: Integer): Extended;
    procedure SetAsFloat(_RecNo: Integer; const _Value: Extended);
    function GetAsDateTime(_RecNo: Integer): TDateTime;
    procedure SetAsDateTime(_RecNo: Integer; const _Value: TDateTime);
    function GetAsGUID(_RecNo: Integer): TGUID;
    procedure SetAsGUID(_RecNo: Integer; const _Value: TGUID);
    function GetAsString(_RecNo: Integer): String;
    procedure SetAsString(_RecNo: Integer; const _Value: String);
    function GetAsBLOB(_RecNo: Integer): RawByteString;
    procedure SetAsBLOB(_RecNo: Integer; const _Value: RawByteString);

  public

    constructor Create(const _FieldName: String; _DataType: TDataType);
    destructor Destroy; override;

    procedure Clear(_RecNo: Integer);

    property FieldName: String read FFieldName;
    property IsNull[RecNo: Integer]: Boolean read GetIsNull write SetIsNull;
    property AsBoolean[RecNo: Integer]: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger[RecNo: Integer]: Integer read GetAsInteger write SetAsInteger;
    property AsFloat[RecNo: Integer]: Extended read GetAsFloat write SetAsFloat;
    property AsDateTime[RecNo: Integer]: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsString[RecNo: Integer]: String read GetAsString write SetAsString;
    property AsGUID[RecNo: Integer]: TGUID read GetAsGUID write SetAsGUID;
    property AsBLOB[RecNo: Integer]: RawByteString read GetAsBLOB write SetAsBLOB;

  end;

  TFieldList = class(TObjectList<TTableField>)
  public
    function Add(const _FieldName: String; _DataType: TDataType): Integer;
  end;

  TTable = class
  private

    FFields: TFieldList;
    FRecordCount: Integer;

    procedure CheckRecNo(_RecNo: Integer);
    function GetFieldCount: Integer;

  public

    constructor Create;
    { TODO -oVasilyevSM -cdeprecatred unit : Create by description }
    destructor Destroy; override;

    function FindField(const _FieldName: String): TTableField;
    function FieldByName(const _FieldName: String): TTableField;

    procedure Append;
    procedure Insert(_RecNo: Integer);
    procedure Delete(_RecNo: Integer = -1);

    property Fields: TFieldList read FFields;
    property RecordCount: Integer read FRecordCount;
    property FieldCount: Integer read GetFieldCount;

  end;

  ETableException = class(Exception);

implementation

uses
  vTypes,
  vConsts, vDataUtils;

procedure CheckRecNo(RecNo, RecordCount: Integer);
begin
  if (RecNo < 0) or (RecNo > RecordCount - 1) then raise ETableException.CreateFmt(SC_RecNoOutOfRange, [RecNo, 0, RecordCount - 1]);
end;

function DataTypeToStr(DataType: TDataType): String;
begin
  { TODO -oVasilyevSM -cdeprecatred unit : можно как-то автоматом получить строку из сета через rtl }
  case DataType of
    dtBoolean : Result := 'Boolean';
    dtInteger : Result := 'Integer';
    dtFloat   : Result := 'Float';
    dtDateTime: Result := 'DateTime';
    dtGUID    : Result := 'GUID';
    dtString  : Result := 'String';
    dtBLOB    : Result := 'BLOB';
  else
    Result := '';
  end;
end;

function GetDataSize(DataType: TDataType): Cardinal;
begin
  case DataType of
    dtBoolean:  Result := SizeOf(Boolean);
    dtInteger:  Result := SizeOf(Integer);
    dtFloat:    Result := SizeOf(Extended);
    dtDateTime: Result := SizeOf(TDateTime);
    dtString:   Result := 0;
    dtGUID:     Result := SizeOf(TGUID);
    dtBLOB:     Result := 0;
  else
    Result := 0;
  end;
end;

{ TPointerList }

function TPointerList.Add: Integer;
begin
  Result := inherited Add(nil);
end;

procedure TPointerList.Alloc(_Index: Integer);
begin
  Items[_Index] := AllocMem(GetDataSize(FDataType));
end;

constructor TPointerList.Create(_DataType: TDataType);
begin
  inherited Create;
  FDataType := _DataType;
end;

procedure TPointerList.FreeData(_Pointer: Pointer);
begin
  case FDataType of
    dtString: String(_Pointer) := '';
    dtBLOB: RawByteString(_Pointer) := '';
  else
    FreeMemory(_Pointer);
  end;
end;

procedure TPointerList.FreeAndNilData(_Index: Integer);
begin
  Items[_Index] := nil;
end;

procedure TPointerList.Insert(_Index: Integer);
begin
  inherited Insert(_Index, nil);
end;

procedure TPointerList.Notify(const _Item: Pointer; _Action: TCollectionNotification);
begin
  inherited Notify(_Item, _Action);
  if _Action = cnRemoved then FreeData(_Item);
end;

{ TTableField }

constructor TTableField.Create(const _FieldName: String; _DataType: TDataType);
begin
  inherited Create;
  FFieldName := _FieldName;
  FDataType := _DataType;
  FData := TPointerList.Create(_DataType);
end;

destructor TTableField.Destroy;
var
  i: Integer;
begin
  for i := 0 to FData.Count - 1 do
    IsNull[i] := True;
  FData.Free;
  inherited Destroy;
end;

procedure TTableField.CheckDataType(_DataType: TDataType);
begin
  if FDataType <> _DataType then raise ETableException.CreateFmt(SC_WrongDataType, [FieldName, DataTypeToStr(_DataType)]);
end;

procedure TTableField.CheckRecNo(_RecNo: Integer);
begin
  vTable.CheckRecNo(_RecNo, FData.Count);
end;

procedure TTableField.Clear(_RecNo: Integer);
begin
  IsNull[_RecNo] := True;
end;

function TTableField.GetIsNull(_RecNo: Integer): Boolean;
begin
  CheckRecNo(_RecNo);
  Result := not Assigned(FData[_RecNo]);
end;

procedure TTableField.SetIsNull(_RecNo: Integer; const _Value: Boolean);
begin
  CheckRecNo(_RecNo);
  if _Value <> IsNull[_RecNo] then
    with FData do
      if _Value then FreeAndNilData(_RecNo)
      else Alloc(_RecNo);
end;

function TTableField.GetAsBoolean(_RecNo: Integer): Boolean;
begin
  CheckRecNo(_RecNo);
  CheckDataType(dtBoolean);
  if IsNull[_RecNo] then Result := False
  else Move(FData[_RecNo]^, Result, GetDataSize(FDataType));
end;

procedure TTableField.SetAsBoolean(_RecNo: Integer; const _Value: Boolean);
begin
  CheckRecNo(_RecNo);
  CheckDataType(dtBoolean);
  if (_Value <> AsBoolean[_RecNo]) or IsNull[_RecNo] then begin
    IsNull[_RecNo] := False;
    Move(_Value, FData[_RecNo]^, GetDataSize(FDataType));
  end;
end;

function TTableField.GetAsInteger(_RecNo: Integer): Integer;
begin
  CheckRecNo(_RecNo);
  CheckDataType(dtInteger);
  if IsNull[_RecNo] then Result := 0
  else Move(FData[_RecNo]^, Result, GetDataSize(FDataType));
end;

procedure TTableField.SetAsInteger(_RecNo: Integer; const _Value: Integer);
begin
  CheckRecNo(_RecNo);
  CheckDataType(dtInteger);
  if (_Value <> AsInteger[_RecNo]) or IsNull[_RecNo] then begin
    IsNull[_RecNo] := False;
    Move(_Value, FData[_RecNo]^, GetDataSize(FDataType));
  end;
end;

function TTableField.GetAsFloat(_RecNo: Integer): Extended;
begin
  CheckRecNo(_RecNo);
  CheckDataType(dtFloat);
  if IsNull[_RecNo] then Result := 0
  else Move(FData[_RecNo]^, Result, GetDataSize(FDataType));
end;

procedure TTableField.SetAsFloat(_RecNo: Integer; const _Value: Extended);
begin
  CheckRecNo(_RecNo);
  CheckDataType(dtFloat);
  if (_Value <> AsFloat[_RecNo]) or IsNull[_RecNo] then begin
    IsNull[_RecNo] := False;
    Move(_Value, FData[_RecNo]^, GetDataSize(FDataType));
  end;
end;

function TTableField.GetAsDateTime(_RecNo: Integer): TDateTime;
begin
  CheckRecNo(_RecNo);
  CheckDataType(dtDateTime);
  if IsNull[_RecNo] then Result := 0
  else Move(FData[_RecNo]^, Result, GetDataSize(FDataType));
end;

procedure TTableField.SetAsDateTime(_RecNo: Integer; const _Value: TDateTime);
begin
  CheckRecNo(_RecNo);
  CheckDataType(dtDateTime);
  if (_Value <> AsDateTime[_RecNo]) or IsNull[_RecNo] then begin
    IsNull[_RecNo] := False;
    Move(_Value, FData[_RecNo]^, GetDataSize(FDataType));
  end;
end;

function TTableField.GetAsGUID(_RecNo: Integer): TGUID;
begin
  CheckRecNo(_RecNo);
  CheckDataType(dtGUID);
  if IsNull[_RecNo] then Result := GUID_NULL
  else Move(FData[_RecNo]^, Result, GetDataSize(FDataType));
end;

procedure TTableField.SetAsGUID(_RecNo: Integer; const _Value: TGUID);
begin
  CheckRecNo(_RecNo);
  CheckDataType(dtGUID);
  if not IsEqualGUID(_Value, AsGUID[_RecNo]) or IsNull[_RecNo] then begin
    IsNull[_RecNo] := False;
    Move(_Value, FData[_RecNo]^, GetDataSize(FDataType));
  end;
end;

function TTableField.GetAsString(_RecNo: Integer): String;
begin
  CheckRecNo(_RecNo);
  if IsNull[_RecNo] then Result := ''
  else
    case FDataType of
      dtBoolean:  Result := BooleanToStr(AsBoolean[_RecNo]);
      dtInteger:  Result := IntToStr(AsInteger[_RecNo]);
      dtFloat:    Result := StringReplace(FloatToStr(AsFloat[_RecNo]), {$IFNDEF DELPHI2010}FormatSettings.{$ENDIF}DecimalSeparator, '.', []);
      dtDateTime: Result := DateTimeToStr(AsDateTime[_RecNo]);
      dtGUID:     Result := GUIDToString(AsGUID[_RecNo]);
      dtString:   Result := String(FData[_RecNo]);
      dtBLOB:     Result := RawByteStringToHex(RawByteString(FData[_RecNo]));
    else
      Result := '';
    end;
end;

procedure TTableField.SetAsString(_RecNo: Integer; const _Value: String);
var
  P: Pointer;
begin
  CheckRecNo(_RecNo);
  CheckDataType(dtString);
  if (_Value <> AsString[_RecNo]) or IsNull[_RecNo] then begin
    IsNull[_RecNo] := False;
    String(P) := _Value;
    FData[_RecNo] := P;
  end;
end;

function TTableField.GetAsBLOB(_RecNo: Integer): RawByteString;
begin
  CheckRecNo(_RecNo);
  CheckDataType(dtBLOB);
  if IsNull[_RecNo] then Result := ''
  else Result := RawByteString(FData);
end;

procedure TTableField.SetAsBLOB(_RecNo: Integer; const _Value: RawByteString);
begin
  CheckRecNo(_RecNo);
  CheckDataType(dtBLOB);
  if (_Value <> AsBLOB[_RecNo]) or IsNull[_RecNo] then begin
    { TODO -oVasilyevSM -cdeprecatred unit : SetAsBLOB }
//    IsNull[_RecNo] := False;
//    RawByteString(FData[_RecNo]) := _Value;
  end;
end;

{ TFieldList }

function TFieldList.Add(const _FieldName: String; _DataType: TDataType): Integer;
begin
  Result := inherited Add(TTableField.Create(_FieldName, _DataType));
end;

{ TTable }

constructor TTable.Create;
begin
  inherited Create;
  FFields := TFieldList.Create;
end;

destructor TTable.Destroy;
begin
  FFields.Free;
  inherited Destroy;
end;

procedure TTable.Append;
var
  F: TTableField;
begin
  for F in FFields do
    F.FData.Add;
  Inc(FRecordCount);
end;

procedure TTable.CheckRecNo(_RecNo: Integer);
begin
  vTable.CheckRecNo(_RecNo, FRecordCount);
end;

procedure TTable.Delete(_RecNo: Integer);
var
  F: TTableField;
begin
  if _RecNo = -1 then _RecNo := FRecordCount - 1;
  CheckRecNo(_RecNo);
  for F in FFields do begin
    F.IsNull[_RecNo] := True;
    F.FData.Delete(_RecNo);
  end;
  Dec(FRecordCount);
end;

function TTable.FindField(const _FieldName: String): TTableField;
var
  F: TTableField;
begin
  for F in FFields do
    if SameText(F.FieldName, _FieldName) then Exit(F);
  Result := nil;
end;

function TTable.GetFieldCount: Integer;
begin
  Result := FFields.Count;
end;

procedure TTable.Insert(_RecNo: Integer);
var
  F: TTableField;
begin
  for F in FFields do
    F.FData.Insert(_RecNo);
  Inc(FRecordCount);
end;

function TTable.FieldByName(const _FieldName: String): TTableField;
begin
  Result := FindField(_FieldName);
  if not Assigned(Result) then raise ETableException.CreateFmt(SC_FieldNotFound, [_FieldName]);
end;

end.
