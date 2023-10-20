unit vParams;

(******************************************************)
(*                                                    *)
(*  This is a params object. It is intended for work  *)
(*  with parameters of the main used types.           *)
(*                                                    *)
(******************************************************)

interface

uses
  { VCL }
  Generics.Collections, Classes;

const

  SC_DefaultListParamName = 'Value';

type

  TParamDataType = (dtUnknown, dtBoolean, dtInteger, dtFloat, dtDateTime, dtString, dtGUID, dtBLOB, dtParams);

  TParams = class;

  TParam = class

  private

    FData: Pointer;
    FDataType: TParamDataType;
    FName: String;

    function GetDataSize: Cardinal;
    procedure SetDataType(const _Value: TParamDataType);
    procedure FreeData;
    procedure CheckDataType(_DataType: TParamDataType);

    function GetAsBoolean: Boolean;
    procedure SetAsBoolean(const _Value: Boolean);
    function GetAsInteger: Integer;
    procedure SetAsInteger(const _Value: Integer);
    function GetAsFloat: Extended;
    procedure SetAsFloat(const _Value: Extended);
    function GetAsDateTime: TDateTime;
    procedure SetAsDateTime(const _Value: TDateTime);
    function GetAsString: String;
    procedure SetAsString(const _Value: String);
    function GetAsGUID: TGUID;
    procedure SetAsGUID(const _Value: TGUID);
    function GetAsBLOB: RawByteString;
    procedure SetAsBLOB(_Value: RawByteString);
    function GetAsParams: TParams;
    procedure SetAsParams(const _Value: TParams);
    function GetAsVariant: Variant;
    procedure SetAsVariant(const _Value: Variant);

  public

    constructor Create(const _Name: String);
    destructor Destroy; override;

    property Name: String read FName write FName;
    property DataType: TParamDataType read FDataType write SetDataType;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsFloat: Extended read GetAsFloat write SetAsFloat;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsString: String read GetAsString write SetAsString;
    property AsGUID: TGUID read GetAsGUID write SetAsGUID;
    property AsBLOB: RawByteString read GetAsBLOB write SetAsBLOB;
    property AsParams: TParams read GetAsParams write SetAsParams;
    property AsVariant: Variant read GetAsVariant write SetAsVariant;

  end;

  TParams = class(TList<TParam>)

  private

    FReadParamCount: Integer;

    function FindBySingleName(const _Name: String; _Create: Boolean): TParam;

  protected

    procedure Notify(const Item: TParam; Action: Generics.Collections.TCollectionNotification); override;

  public

    function Duplicate: TParams;

    function AddParam(const _Name: String): TParam;
    function FindParam(_Name: String; _Create: Boolean = False): TParam; overload;
    function FindParam(_Name: String; var _Value: TParam): Boolean; overload;
    function ParamByName(const _Name: String): TParam;
    function GetParam(const _Name: String): TParam;
    function CheckParam(const _Name: String; _Default: Boolean): TParam; overload;
    function CheckParam(const _Name: String; _Default: Integer): TParam; overload;
    function CheckParam(const _Name: String; _Default: Extended): TParam; overload;
    function CheckParam(const _Name: String; _Default: TDateTime): TParam; overload;
    function CheckParam(const _Name: String; _Default: String): TParam; overload;
    function CheckParam(const _Name: String; _Default: TGUID): TParam; overload;
    function CheckParam(const _Name: String; _Default: RawByteString): TParam; overload;
    function CheckParam(const _Name: String; _Default: TParams = nil): TParam; overload;
    function ReadParam(const _Name: String; var _Param: TParam): Boolean;
    procedure ClearList(const _Name: String);
    procedure SaveList(_List: TStrings; const _Name: String = SC_DefaultListParamName);
    procedure LoadList(_List: TStrings; const _Name: String = SC_DefaultListParamName); overload;
    function LoadList(const _Name: String = SC_DefaultListParamName): TStrings; overload;

    procedure SaveToFile(const _FileName: String);
    procedure LoadFromFile(const _FileName: String);
    function SaveToString: String;
    procedure LoadFromString(const _S: String);

    { TODO : SaveToStream and LoadFromStream }

  end;

function ParamsToStr(Params: TParams): String;
procedure StrToParams(const S: String; Params: TParams);
function StrToParamDataType(const S: String): TParamDataType;
function ParamDataTypeToStr(DataType: TParamDataType): String;

implementation

uses
  { VCL }
  Variants, SysUtils,
  { Utils }
  vDataUtils, vStrUtils, vFileUtils, vTypes;

function ParamDataTypeToStr(DataType: TParamDataType): String;
begin

  case DataType of

    dtBoolean:  Result := SC_PDT_Boolean;
    dtInteger:  Result := SC_PDT_Integer;
    dtFloat:    Result := SC_PDT_Float;
    dtDateTime: Result := SC_PDT_DateTime;
    dtString:   Result := SC_PDT_String;
    dtGUID:     Result := SC_PDT_GUID;
    dtBLOB:     Result := SC_PDT_BLOB;
    dtParams:   Result := SC_PDT_Params;

  else
    Result := SC_PDT_Unknown;
  end;

end;

function ParamsToStr(Params: TParams): String;

  function _ParamsToStr(_Params: TParams; const _Offset: String): String;

    function _FormatString(const _Value, _Name: String): String;
    begin

      Result := StringReplace(_Value, '''', '''''', [rfReplaceAll]);
      Result := ''''  + Result + '''';

    end;

  const
    SC_OneStringParamFormat = '%s: %s = %s' + CRLF;
    SC_MultiStringParamFormat = '%s: %s = (' + CRLF + '%s)' + CRLF;
  var
    i: Integer;
  begin

    Result := '';
    for i := 0 to _Params.Count - 1 do

      with _Params[i] do

        case DataType of

          dtParams: Result := Result + _Offset + Format(SC_MultiStringParamFormat, [Name, ParamDataTypeToStr(DataType), _ParamsToStr(AsParams, _Offset + '  ') + _Offset]);
          dtString: Result := Result + _Offset + Format(SC_OneStringParamFormat, [Name, ParamDataTypeToStr(DataType), _FormatString(AsString, Name)]);

        else
          Result := Result + _Offset + Format(SC_OneStringParamFormat, [Name, ParamDataTypeToStr(DataType), AsString]);
        end;

  end;

begin
  Result := _ParamsToStr(Params, '');
end;

type
  TParamsReader = class(TCustomStringsReader)

  strict private

    FParams: TParams;

    function ReadParamName(var _TypeDesignated: Boolean): String;
    function ReadDataType: TParamDataType;
    function ExploreDataType: TParamDataType;
    procedure ReadBoolean(_Param: TParam);
    procedure ReadInteger(_Param: TParam);
    procedure ReadFloat(_Param: TParam);
    procedure ReadDateTime(_Param: TParam);
    procedure ReadString(_Param: TParam);
    procedure ReadGUID(_Param: TParam);
    procedure ReadBLOB(_Param: TParam);
    procedure ReadParams(_Param: TParam);

  private

    constructor CreateReader(const _String: String; _Params: TParams);

  protected

    procedure ReadInternal; override;
    function WordEnds: TSysCharSet; override;

  end;

procedure StrToParams(const S: String; Params: TParams);
begin

  with TParamsReader.CreateReader(S, Params) do
    try

      Read;

    finally
      Free;
    end;

end;

function StrToParamDataType(const S: String): TParamDataType;
begin

  if SameText(S, SC_PDT_Boolean ) then Exit(dtBoolean);
  if SameText(S, SC_PDT_Integer ) then Exit(dtInteger);
  if SameText(S, SC_PDT_Float   ) then Exit(dtFloat);
  if SameText(S, SC_PDT_DateTime) then Exit(dtDateTime);
  if SameText(S, SC_PDT_String  ) then Exit(dtString);
  if SameText(S, SC_PDT_GUID    ) then Exit(dtGUID);
  if SameText(S, SC_PDT_BLOB    ) then Exit(dtBLOB);
  if SameText(S, SC_PDT_Params  ) then Exit(dtParams);

  Result := dtUnknown;

end;

{ TParam }

function TParam.GetDataSize: Cardinal;
begin

  case FDataType of

    dtBoolean:  Result := SizeOf(Boolean);
    dtInteger:  Result := SizeOf(Integer);
    dtFloat:    Result := SizeOf(Extended);
    dtDateTime: Result := SizeOf(TDateTime);
    dtString:   Result := 0;
    dtGUID:     Result := SizeOf(TGUID);
    dtBLOB:     Result := 0;
    dtParams:   Result := 0;

  else
    Result := 0;
  end;

end;

procedure TParam.SetDataType(const _Value: TParamDataType);
begin

  if FDataType <> _Value then begin

    FreeData;
    FDataType := _Value;
    FData := AllocMem(GetDataSize);

  end;

end;

procedure TParam.CheckDataType(_DataType: TParamDataType);
begin
  if FDataType <> _DataType then raise EParamsException.CreateFmt(SC_ParamInvalidDataType, [ParamDataTypeToStr(_DataType)]);
end;

constructor TParam.Create(const _Name: String);
begin
  FName := _Name;
  inherited Create;
end;

destructor TParam.Destroy;
begin
  FreeData;
  inherited Destroy;
end;

procedure TParam.FreeData;
begin

  case FDataType of

    dtString: String(FData) := '';
    dtBLOB: RawByteString(FData) := '';
    dtParams: TParams(FData).Free;

  else
    FreeMemory(FData);
  end;

end;

function TParam.GetAsBoolean: Boolean;
begin
  CheckDataType(dtBoolean);
  Move(FData^, Result, GetDataSize);
end;

procedure TParam.SetAsBoolean(const _Value: Boolean);
begin
  DataType := dtBoolean;
  Move(_Value, FData^, GetDataSize);
end;

function TParam.GetAsInteger: Integer;
begin
  CheckDataType(dtInteger);
  Move(FData^, Result, GetDataSize);
end;

procedure TParam.SetAsInteger(const _Value: Integer);
begin
  DataType := dtInteger;
  Move(_Value, FData^, GetDataSize);
end;

function TParam.GetAsFloat: Extended;
begin
  CheckDataType(dtFloat);
  Move(FData^, Result, GetDataSize);
end;

procedure TParam.SetAsFloat(const _Value: Extended);
begin
  DataType := dtFloat;
  Move(_Value, FData^, GetDataSize);
end;

function TParam.GetAsDateTime: TDateTime;
begin
  CheckDataType(dtDateTime);
  Move(FData^, Result, GetDataSize);
end;

procedure TParam.SetAsDateTime(const _Value: TDateTime);
begin
  DataType := dtDateTime;
  Move(_Value, FData^, GetDataSize);
end;

function TParam.GetAsString: String;
begin

  case FDataType of

    dtBoolean:  Result := BooleanToStr(AsBoolean);
    dtInteger:  Result := IntToStr(AsInteger);
    dtFloat:    Result := StringReplace(FloatToStr(AsFloat), DecimalSeparator, '.', []);
    dtDateTime: Result := DateTimeToStr(AsDateTime);
    dtString:   Result := String(FData);
    dtGUID:     Result := GUIDToString(AsGUID);
    dtBLOB:     Result := RawByteStringToHex(RawByteString(FData));
    dtParams:   Result := AsParams.SaveToString;

  else
    Result := '';
  end;

end;

procedure TParam.SetAsString(const _Value: String);
begin
  DataType := dtString;
  String(FData) := _Value;
end;

function TParam.GetAsGUID: TGUID;
begin
  CheckDataType(dtGUID);
  Move(FData^, Result, GetDataSize);
end;

procedure TParam.SetAsGUID(const _Value: TGUID);
begin
  DataType := dtGUID;
  Move(_Value, FData^, GetDataSize);
end;

function TParam.GetAsBLOB: RawByteString;
begin
  CheckDataType(dtBLOB);
  Result := RawByteString(FData);
end;

procedure TParam.SetAsBLOB(_Value: RawByteString);
begin
  DataType := dtBLOB;
  RawByteString(FData) := _Value;
end;

function TParam.GetAsParams: TParams;
begin
  CheckDataType(dtParams);
  Result := TParams(FData);
end;

procedure TParam.SetAsParams(const _Value: TParams);
begin
  DataType := dtParams;
  if Assigned(AsParams) then AsParams.Free;
  TParams(FData) := _Value;
end;

function TParam.GetAsVariant: Variant;
begin

  case FDataType of

    dtBoolean:  Result := AsBoolean;
    dtInteger:  Result := AsInteger;
    dtFloat:    Result := AsFloat;
    dtDateTime: Result := AsDateTime;
    dtString:   Result := AsString;
    dtGUID:     Result := GUIDToString(AsGUID);
    dtBLOB:     Result := AsBLOB;
    dtParams: begin
      TVarData(Result).VType := varByRef;
      TVarData(Result).VPointer := FData;
    end

  else
    Result := Null;
  end;

end;

procedure TParam.SetAsVariant(const _Value: Variant);
begin

  case VarType(_Value) of

    varBoolean: AsBoolean := _Value;
    varShortInt, varByte, varWord, varLongWord, varSmallint, varInteger: AsInteger := _Value;
    varSingle, varDouble, varCurrency: AsFloat := _Value;
    varDate: AsDateTime := _Value;
    varOleStr, varString, varUString: AsString := _Value;

  else
    DataType := dtUnknown;
  end;

end;

{ TParams }

function TParams.CheckParam(const _Name: String; _Default: Boolean): TParam;
begin
  Result := GetParam(_Name);
  with Result do
    if DataType <> dtBoolean then AsBoolean := _Default;
end;

function TParams.CheckParam(const _Name: String; _Default: Integer): TParam;
begin
  Result := GetParam(_Name);
  with Result do
    if DataType <> dtInteger then AsInteger := _Default;
end;

function TParams.CheckParam(const _Name: String; _Default: Extended): TParam;
begin
  Result := GetParam(_Name);
  with Result do
    if DataType <> dtFloat then AsFloat := _Default;
end;

function TParams.CheckParam(const _Name: String; _Default: TDateTime): TParam;
begin
  Result := GetParam(_Name);
  with Result do
    if DataType <> dtDateTime then AsDateTime := _Default;
end;

function TParams.CheckParam(const _Name: String; _Default: String): TParam;
begin
  Result := GetParam(_Name);
  with Result do
    if DataType <> dtString then AsString := _Default;
end;

function TParams.CheckParam(const _Name: String; _Default: TGUID): TParam;
begin
  Result := GetParam(_Name);
  with Result do
    if DataType <> dtGUID then AsGUID := _Default;
end;

function TParams.CheckParam(const _Name: String; _Default: RawByteString): TParam;
begin
  Result := GetParam(_Name);
  with Result do
    if DataType <> dtBLOB then AsBLOB := _Default;
end;

function TParams.AddParam(const _Name: String): TParam;
begin
  Result := TParam.Create(_Name);
  Add(Result);
end;

function TParams.CheckParam(const _Name: String; _Default: TParams): TParam;
begin
  { Здесь параметр _Default служит основой для копирования в параметры свойства.
    Если снаружи мы что-то создали в него сюда, то и освобождать его нужно снаружи. }
  Result := GetParam(_Name);
  with Result do
    if DataType <> dtParams then AsParams := _Default.Duplicate;
end;

procedure TParams.ClearList(const _Name: String);
var
  P: TParam;

  function _Find: Boolean;
  begin
    P := FindParam(_Name);
    Result := Assigned(P);
  end;

begin
  while _Find do
    Delete(IndexOf(P));
end;

function TParams.Duplicate: TParams;
var
  P: TParam;
begin

  Result := TParams.Create;
  if Assigned(Self) then

    with Result do

      for P in Self do

        case P.DataType of

          dtBoolean:  AddParam(P.Name).AsBoolean  := P.AsBoolean;
          dtInteger:  AddParam(P.Name).AsInteger  := P.AsInteger;
          dtFloat:    AddParam(P.Name).AsFloat    := P.AsFloat;
          dtDateTime: AddParam(P.Name).AsDateTime := P.AsDateTime;
          dtString:   AddParam(P.Name).AsString   := P.AsString;
          dtGUID:     AddParam(P.Name).AsGUID     := P.AsGUID;
          dtBLOB:     AddParam(P.Name).AsBLOB     := P.AsBLOB;
          dtParams:   AddParam(P.Name).AsParams   := P.AsParams.Duplicate;

        end;

end;

function TParams.FindBySingleName(const _Name: String; _Create: Boolean): TParam;
var
  i: Integer;
begin

  for i := 0 to Count - 1 do
    if Items[i].Name = _Name then Exit(Items[i]);

  if _Create then begin

    Result := TParam.Create(_Name);
    Add(Result);

  end else Result := nil;

end;

function TParams.FindParam(_Name: String; var _Value: TParam): Boolean;
begin
  _Value := FindParam(_Name);
  Result := Assigned(_Value);
end;

function TParams.FindParam(_Name: String; _Create: Boolean): TParam;
var
  S: String;
  Param: TParam;
  Params: TParams;
begin

  Params := Self;
  while Pos('.', _Name) > 0 do begin

    S := ReadStrTo(_Name, '.', False);
    Param := Params.FindBySingleName(S, _Create);
    if not Assigned(Param) then Exit(nil)
    else
      if Param.DataType <> dtParams then Param.AsParams := TParams.Create;
    Params := Param.AsParams;

  end;

  S := _Name;
  Result := Params.FindBySingleName(S, _Create);

end;

function TParams.ParamByName(const _Name: String): TParam;
begin
  Result := FindParam(_Name);
  if not Assigned(Result) then raise EParamsException.CreateFmt(SC_ParamNotFound, [_Name]);
end;

function TParams.ReadParam(const _Name: String; var _Param: TParam): Boolean;
var
  i, Found: Integer;
begin

  _Param := nil;
  Found := 0;

  for i := 0 to Count - 1 do

    if _Name = Items[i].FName then

      if Found = FReadParamCount then begin

        _Param := Items[i];
        Break;

      end else Inc(Found);

  Result := Assigned(_Param);

  if Result then Inc(FReadParamCount)
  else FReadParamCount := 0;

end;

function TParams.GetParam(const _Name: String): TParam;
begin
  Result := FindParam(_Name, True);
end;

function TParams.SaveToString: String;
begin
  Result := ParamsToStr(Self);
end;

procedure TParams.LoadFromFile(const _FileName: String);
begin
  LoadFromString(FileToStr(_FileName));
end;

procedure TParams.LoadFromString(const _S: String);
begin
  StrToParams(_S, Self);
end;

procedure TParams.Notify(const Item: TParam; Action: Generics.Collections.TCollectionNotification);
begin
  inherited Notify(Item, Action);
  if Action = cnRemoved then Item.Free;
end;

procedure TParams.SaveToFile(const _FileName: String);
begin
  StrToFile(SaveToString, _FileName);
end;

procedure TParams.SaveList(_List: TStrings; const _Name: String);
var
  i: Integer;
  P: TParam;
begin

  ClearList(_Name);

  for i := 0 to _List.Count - 1 do begin

    P := TParam.Create(_Name);
    P.AsString := _List[i];
    Add(P);

  end;

end;

procedure TParams.LoadList(_List: TStrings; const _Name: String);
var
  P: TParam;
begin
  _List.Clear;
  while ReadParam(_Name, P) do
    _List.Add(P.AsString);
end;

function TParams.LoadList(const _Name: String): TStrings;
begin
  Result := TStringList.Create;
  LoadList(Result, _Name);
end;

{ TParamsReader }

constructor TParamsReader.CreateReader(const _String: String; _Params: TParams);
begin
  inherited CreateReader(_String);
  FParams := _Params;
end;

procedure TParamsReader.ReadInternal;
var
  TypeDesignated: Boolean;

  function _GetDataType: TParamDataType;
  begin
    if TypeDesignated then begin
      Result := ReadDataType;
      Discard;
    end else Result := ExploreDataType;
  end;

var
  P: TParam;
begin

  Discard;
  if EndOf then Exit;
  P := TParam.Create(ReadParamName(TypeDesignated));
  try

    Discard;
    case _GetDataType of

      dtBoolean:  ReadBoolean(P);
      dtInteger:  ReadInteger(P);
      dtFloat:    ReadFloat(P);
      dtDateTime: ReadDateTime(P);
      dtString:   ReadString(P);
      dtGUID:     ReadGUID(P);
      dtBLOB:     ReadBLOB(P);
      dtParams:   ReadParams(P);

    else
      ReadString(P);
    end;

    FParams.Add(P);

  except
    P.Free;
  end;

end;

function TParamsReader.ReadParamName(var _TypeDesignated: Boolean): String;

  procedure _RaiseUnterminated;
  begin
    raise EParamsReadException.CreateFmt(SC_ParamRead_UnterminatedParamName, [Result], Position);
  end;

  procedure _RaiseEmpty;
  begin
    raise EParamsReadException.Create(SC_ParamRead_EmptyParamName, Position);
  end;

  procedure _CheckInvalid(const _C: Char);
  const
    ValidChars = ['0'..'9', 'A'..'Z', 'a'..'z'];
  begin
    if not CharInSet(_C, ValidChars) then
      raise EParamsReadException.CreateFmt(SC_ParamRead_InvalidParamName, [Result + _C], Position);
  end;

const
  NameEnds = [':', '='];
var
  C: Char;
begin

  Result := '';
  repeat

    if EndOf then _RaiseUnterminated;
    C := Bite(1)[1];

    if CharInSet(C, NameEnds) then begin

      if Length(Result) = 0 then _RaiseEmpty;
      _TypeDesignated := C = ':';
      Exit;

    end;

    _CheckInvalid(C);
    Result := Result + C;

  until Discard;

  if EndOf then _RaiseUnterminated;
  C := Bite(1)[1];
  if CharInSet(C, NameEnds) then _TypeDesignated := C = ':'
  else _RaiseUnterminated;
  if Length(Result) = 0 then _RaiseEmpty;

end;

function TParamsReader.ReadDataType: TParamDataType;
var
  S: String;

  procedure _RaiseUnterminated;
  begin
    raise EParamsReadException.CreateFmt(SC_ParamRead_UnterminatedParamType, [S], Position);
  end;

  procedure _RaiseEmpty;
  begin
    raise EParamsReadException.Create(SC_ParamRead_EmptyParamType, Position);
  end;

var
  C: Char;
begin

  S := '';
  repeat

    if EndOf then _RaiseUnterminated;
    C := Bite(1)[1];

    if C = '=' then begin

      if Length(S) = 0 then _RaiseEmpty;
      Exit(StrToParamDataType(S));

    end;

    S := S + C;

  until Discard;

  if EndOf then _RaiseUnterminated
  else

    if Lick(1)[1] <> '=' then _RaiseUnterminated
    else Step(1);

  if Length(S) = 0 then _RaiseEmpty;

  Result := StrToParamDataType(S);

end;

function TParamsReader.ExploreDataType: TParamDataType;
var
  S: String;

  function _CheckForDataType(_DataType: TParamDataType): Boolean;

    function _IsBoolean: Boolean;
    begin
      Result := StrIsBoolean(S);
    end;

    function _IsInteger: Boolean;
    var
      i: Integer;
    begin
      for i := 1 to Length(S) do
        if not CharInSet(S[i], IntegerCharsSet) and not ((i = 1) and (S[i] = '-')) then Exit(False);
      Result := True;
    end;

    function _IsFloat: Boolean;
    var
      i: Integer;
      DelimFound: Boolean;
    begin

      DelimFound := False;

      for i := 1 to Length(S) do

        if not CharInSet(S[i], IntegerCharsSet) and not ((i = 1) and (S[i] = '-')) then

          { Only point is delim. Comma is unquoted param end token. }
          if S[i] = '.' then

            if DelimFound then Exit(False)
            else DelimFound := True

          else Exit(False);

      { If delim is not found then it is Integer. Float values must hold delim. }
      Result := DelimFound;

    end;

    function _IsDateTime: Boolean;
    begin

      try

        StrToDateTime(S);
        Result := True;

      except
        Result := False;
      end;

    end;

    function _IsString: Boolean;
    begin
      Result := S[1] = '''';
    end;

    function _IsGUID: Boolean;
    begin

      if Length(S) <> 38 then Exit(False);
      if S[1] <> '{' then Exit(False);
      if S[38] <> '}' then Exit(False);
      Result := StrIsGUID(S);

    end;

    function _IsBLOB: Boolean;

      function _CheckBLOBData: Boolean;
      var
        i: Integer;
      begin
        for i := 3 to Length(S) do
          if not CharInSet(UpperCase(S[i])[1], HexCharsSet) then Exit(False);
        Result := True;
      end;

    begin
      Result := SameText(Copy(S, 1, 2), '0x') and _CheckBLOBData;
    end;

    function _IsParams: Boolean;
    begin
      Result := S[1] = '(';
    end;

  begin

    case _DataType of

      dtBoolean:  Result := _IsBoolean;
      dtInteger:  Result := _IsInteger;
      dtFloat:    Result := _IsFloat;
      dtDateTime: Result := _IsDateTime;
      dtString :  Result := _IsString;
      dtGUID:     Result := _IsGUID;
      dtBLOB:     Result := _IsBLOB;
      dtParams:   Result := _IsParams;

    else
      Result := False;
    end;

  end;

begin

  S := LickWord;
  if Length(S) > 0 then begin

    if _CheckForDataType(dtParams)   then Exit(dtParams);
    if _CheckForDataType(dtGUID)     then Exit(dtGUID);
    if _CheckForDataType(dtBLOB)     then Exit(dtBLOB);
    if _CheckForDataType(dtString)   then Exit(dtString);
    if _CheckForDataType(dtBoolean)  then Exit(dtBoolean);
    if _CheckForDataType(dtFloat)    then Exit(dtFloat);
    if _CheckForDataType(dtInteger)  then Exit(dtInteger);
    if _CheckForDataType(dtDateTime) then Exit(dtDateTime);

  end;

  Result := dtUnknown;

end;

procedure TParamsReader.ReadBoolean(_Param: TParam);
begin
  _Param.AsBoolean := StrToBoolean(ReadWord);
end;

procedure TParamsReader.ReadInteger(_Param: TParam);
begin
  _Param.AsInteger := StrToInt(ReadWord);
end;

procedure TParamsReader.ReadFloat(_Param: TParam);
begin
  _Param.AsFloat := StrToFloat(ReduceStrToFloat(ReadWord));
end;

procedure TParamsReader.ReadDateTime(_Param: TParam);
var
  DP, TP: String;
  InitPos: Integer;
  T: TDateTime;
begin

  { DateTime param parameter must use the current locale's date/time format. }
  { In the US, this is commonly MM/DD/YY HH:MM:SS format.                    }
  DP := ReadWord;
  InitPos := Position;
  TP := ReadWord;

  try

    T := StrToDateTime(TP);

  except
    Restore(InitPos);
    T := 0;
  end;

  _Param.AsDateTime := StrToDateTime(DP) + T;

end;

procedure TParamsReader.ReadString(_Param: TParam);
begin
  _Param.AsString := inherited ReadString;
end;

function TParamsReader.WordEnds: TSysCharSet;
begin
  Result := inherited WordEnds + [';', ',', ')'];
end;

procedure TParamsReader.ReadGUID(_Param: TParam);
begin
  _Param.AsGUID := StringToGUID(ReadWord);
end;

procedure TParamsReader.ReadBLOB(_Param: TParam);
begin
  _Param.AsBLOB := HexToRawByteString(ReadWord);
end;

procedure TParamsReader.ReadParams(_Param: TParam);

  function _EndOf: Boolean;

    procedure _CheckEnd;
    begin
      if EndOf then raise EParamsReadException.CreateFmt(SC_ParamRead_UnterminatedParam, [_Param.Name], Position);
    end;

  var
    Pos: Integer;
  begin

    repeat

      Pos := Position;
      Discard;
      _CheckEnd;

      while CharInSet(Lick(1)[1], LineEnds) do begin

        Step(1);
        _CheckEnd;

      end;

    until Pos = Position;

    Result := Lick(1) = ')';

  end;

var
  InitParams: TParams;
begin

  StepToChar('(');
  _Param.AsParams := TParams.Create;

  while not _EndOf do begin

    InitParams := FParams;
    FParams := _Param.AsParams;

    try

      ReadInternal;

    finally
      FParams := InitParams;
    end;

  end;

  Step(1);

end;

end.
