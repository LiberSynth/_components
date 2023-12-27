unit uParamsReader;

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
  uCore, uCustomReadWrite, uReadWriteCommon, uParams, uStrUtils;

type

  TListStarter = class(TList<String>)

  private

    function Started(const _Name: String): Boolean;

  end;

  IParamsReader = interface ['{5324B88D-A724-4E0B-9797-5004FE975287}']

    procedure RetrieveParams(_Value: TParams);
    procedure RetrieveParser(_Value: TCustomParser);

  end;

  TParamsReader = class(TCustomReader, IParamsReader, INTVParser)

  strict private

    FParams: TParams;
    FParser: TCustomParser;

    FCurrentName: String;
    FCurrentType: TParamDataType;
    FNested: Boolean;

    FListStarter: TListStarter;

    procedure CheckPresetType(_Strict: Boolean);
    function TrimDigital(const _Value: String): String;

    { INTVParser }
    procedure ReadName(const _Element: String);
    procedure ReadType(const _Element: String);
    procedure ReadValue(const _Element: String);
    function IsNestedValue: Boolean;
    procedure ReadNestedBlock;

    { IParamsReader }
    procedure RetrieveParams(_Value: TParams);
    procedure RetrieveParser(_Value: TCustomParser);

  private

    property CurrentName: String read FCurrentName;
    property CurrentType: TParamDataType read FCurrentType;
    property Nested: Boolean read FNested write FNested;
    property ListStarter: TListStarter read FListStarter;
    property Params: TParams read FParams write FParams;
    property Parser: TCustomParser read FParser write FParser;

  public

    constructor Create; override;
    destructor Destroy; override;

    function Clone: TCustomReader; override;

  end;

  EParamsReadException = class(ECustomReadWriteException);

implementation

{ TListStarter }

function TListStarter.Started(const _Name: String): Boolean;
var
  S: String;
begin

  for S in Self do
    if SameText(S, _Name) then
      Exit(True);

  Add(_Name);
  Result := False;

end;

{ TParamsReader }

function TParamsReader.Clone: TCustomReader;
begin

  Result := inherited Clone;

  TParamsReader(Result).Params     := Params;
  TParamsReader(Result).Nested     := True;

end;

constructor TParamsReader.Create;
begin
  inherited Create;
  FListStarter := TListStarter.Create;
end;

destructor TParamsReader.Destroy;
begin
  FreeAndNil(FListStarter);
  inherited Destroy;
end;

procedure TParamsReader.CheckPresetType(_Strict: Boolean);
var
  DataType: TParamDataType;
begin

  { ќпределенный заранее тип данных }
  if

      (CurrentType = dtUnknown) and
      Params.FindDataType(CurrentName, DataType) and
      (DataType <> dtUnknown)

  then FCurrentType := DataType;

  if _Strict and (CurrentType = dtUnknown) then
    raise EParamsReadException.Create('Unknown param data type');

end;

function TParamsReader.TrimDigital(const _Value: String): String;
begin
  Result := StringReplace(_Value, ' ', '', [rfReplaceAll]);
end;

procedure TParamsReader.ReadName(const _Element: String);
begin
  TParam.ValidateName(_Element, Params.PathSeparator);
  FCurrentName := _Element;
end;

procedure TParamsReader.ReadNestedBlock;
var
  NestedReader: TParamsReader;
  NestedParser: TCustomParser;
  Index: Integer;
begin

//  BeforeReadParam(Items[Index]);

  NestedParser := Parser.Clone;
  try

    NestedReader := TParamsReader(Clone);
    try

      NestedReader.Params := Params.Clone;
      NestedReader.Parser := NestedParser;

      NestedParser.RetrieveTargerInterface(NestedReader);
      try


        NestedParser.Read;

        with Params.AddList(CurrentName) do begin

          if Nested or ListStarter.Started(CurrentName) or (Count = 0) then Index := Append
          else Index := 0;

          AsParams[Index] := NestedReader.Params;
          //AfterReadParams(Param);

        end;

        { ¬озврат управлени€ мастеру. ≈сли помощник выломалс€, не возвращать, иначе локаци€ вернетс€ в начало помощника. }
        Parser.Accept(NestedParser);

      finally
        NestedParser.FreeTargerInterface;
      end;

    finally
      NestedReader.Free;
    end;

  finally
    NestedParser.Free;
  end;

//  AfterReadParam(Param);
  FCurrentName := '';
  FCurrentType := dtUnknown;

end;

procedure TParamsReader.ReadType(const _Element: String);
begin
  FCurrentType := StrToParamDataType(_Element);
  CheckPresetType(True);
end;

procedure TParamsReader.ReadValue(const _Element: String);
var
  Index: Integer;
begin

  CheckPresetType(True);

  { „тобы предопределить структуру листа дл€ нетипизованного хранени€, достаточно создать одну его строку в параметрах
    до считывани€. }
  with Params.AddList(CurrentName) do begin

    if ListStarter.Started(CurrentName) or (Count = 0) then Index := Append
    else Index := 0;

//    BeforeReadParam(Items[Index]);

    if Length(_Element) > 0 then

      case CurrentType of

        dtBoolean:    AsBoolean   [Index] := StrToBoolean(_Element);
        dtInteger:    AsInteger   [Index] := StrToInt(TrimDigital(_Element));
        dtBigInt:     AsBigInt    [Index] := StrToBigInt(TrimDigital(_Element));
        dtFloat:      AsFloat     [Index] := StrToFloat (TrimDigital(_Element));
        dtExtended:   AsExtended  [Index] := StrToExtended(TrimDigital(_Element));
        dtDateTime:   AsDateTime  [Index] := StrToDateTime(_Element);
        dtGUID:       AsGUID      [Index] := StrToGUID(_Element);
        dtAnsiString: AsAnsiString[Index] := StrToAnsiStr(_Element);
        dtString:     AsString    [Index] := _Element;
        dtBLOB:       AsBLOB      [Index] := HexStrToBLOB(_Element);
        dtData:       AsData      [Index] := ByteStrToData(_Element);

      end

    else begin

      IsNull  [Index] := True;
      DataType[Index] := CurrentType;

    end;

//    AfterReadParam(Items[Index]);

  end;

  FCurrentName := '';
  FCurrentType := dtUnknown;

end;

function TParamsReader.IsNestedValue: Boolean;
begin
  CheckPresetType(False);
  Result := FCurrentType = dtParams;
end;

procedure TParamsReader.RetrieveParams(_Value: TParams);
begin
  FParams := _Value;
end;

procedure TParamsReader.RetrieveParser(_Value: TCustomParser);
begin
  FParser := _Value;
end;

end.
