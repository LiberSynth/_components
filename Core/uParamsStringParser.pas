unit uParamsStringParser;

interface

uses
  { VCL }
  Generics.Collections, SysUtils,
  { vSoft }
  uConsts, uCustomStringParser, uParams, uStrUtils;

type

  TElement = (etName, etType, etValue);

  TKeyWordType = (

      ktNone, ktSourceEnd, ktLineEnd, ktSpace, ktSplitter, ktTypeIdent, ktAssigning, ktStringBorder, ktOpeningBracket,
      ktClosingBracket

  );
  TKeyWordTypes = set of TKeyWordType;

  TKeyWordHelper = record helper for TKeyWord

  private

    constructor Create(_KeyType: TKeyWordType; const _StrValue: String); overload;

    function GetKeyType: TKeyWordType;
    procedure SetKeyType(const _Value: TKeyWordType);

    function TypeInSet(const _Set: TKeyWordTypes): Boolean;

    property KeyType: TKeyWordType read GetKeyType write SetKeyType;

  end;

  TReadFunc = function (const KeyWord: TKeyWord): Boolean of object;

  TReadInfo = record

    Element: TElement;
    Terminator: TKeyWordType;
    Nested: Boolean;
    NextElement: TElement;
    ReadFunc: TReadFunc;

    constructor Create(

        _Element: TElement;
        _Terminator: TKeyWordType;
        _Nested: Boolean;
        _NextElement: TElement;
        _ReadFunc: TReadFunc

    );

  end;

  TReadInfoList = class(TList<TReadInfo>)

  private

    procedure Add(

        _Element: TElement;
        _Terminator: TKeyWordType;
        _Nested: Boolean;
        _NextElement: TElement;
        _ReadFunc: TReadFunc

    );

  end;

  TSyntaxInfo = record

    Element: TElement;
    Nested: Boolean;
    InvalidKeys: TKeyWordTypes;

    constructor Create(

        _Element: TElement;
        _Nested: Boolean;
        _InvalidKeys: TKeyWordTypes

    );

  end;

  TSyntaxInfoList = class(TList<TSyntaxInfo>)

  private

    procedure Add(

        _Element: TElement;
        _Nested: Boolean;
        _InvalidKeys: TKeyWordTypes

    );

  end;

  {

    ������ ��������� � ���� ������ �� ������:

      1. ������������ �����������.
      2. ����� ��������� �������� �� ���������, ����� ����� = ������ �� �������. ���������� - ��� ������.
      3. ����������� � �����������. �� ����� ������ ���� ���� �� UTF-8 � BOM.

    ��� ��� �������� ������ ������ �����-������� TUserParamsParser.

    �������� ����������: ���, ���, ��������. ��� ��� ����� ��������������, �� ����� ��� ���������� ���� ������� �������
    �������� � ������ �����. � ���� ��������� ��������.
    ��������� ��� �� ��������� ������ ����������. �������� - ���. ����� ������ ��� ';' - ��� ����� ���������.
    ����� ���������� ��� - ��� � ����� ����������� ����������� ����� ���������� ��������, ��������� � ��������� ��
    ��������� ������. ����� ��������� - ������ ������� � ���������.

  }
  { TODO 2 -oVasilyevSM -cTParamsStringParser: ��� ��� �������� ������������ ������ ��� ������������ ������ ������
    ���������������� � �������� ����������. }
  TParamsStringParser = class(TCustomStringParser)

  strict private

    FParams: TParams;

    FElement: TElement;
    FCurrentName: String;
    FCurrentType: TParamDataType;

    FReading: TReadInfoList;
    FSyntax: TSyntaxInfoList;

    FDoublingChar: Char;

    function ElementTerminating(

        const _KeyWord: TKeyWord;
        var _NextElement: TElement;
        var _ReadFunc: TReadFunc

    ): Boolean;
    procedure CheckSyntax(const _KeyWord: TKeyWord);
    procedure CompleteElement(const _KeyWord: TKeyWord);

    function ReadName(const _KeyWord: TKeyWord): Boolean;
    function ReadType(const _KeyWord: TKeyWord): Boolean;
    function ReadValue(const _KeyWord: TKeyWord): Boolean;

    procedure CheckPresetType;
    procedure CheckParams(_KeyWord: TKeyWord);
    procedure ReadParams(_KeyWord: TKeyWord);

    function UndoubleSymbols(const _Value: String): String;
    function TrimDigital(const _Value: String): String;

  private

    property Element: TElement read FElement;
    property CurrentType: TParamDataType read FCurrentType;

  protected

    procedure InitParser; override;
    { ��������� ������ ����� }
    procedure KeyEvent(const _KeyWord: TKeyWord); override;
    procedure SpecialRegionClosed(_Region: TSpecialRegion); override;

  public

    constructor Create(const _Source: String; _Params: TParams);
    constructor CreateNested(_Master: TCustomStringParser; _Params: TParams; _CursorShift: Int64);

    destructor Destroy; override;

  end;

  EParamsReadException = class(EStringParserException);

implementation

const

  KWR_SPACE:                TKeyWord = (KeyTypeInternal: Integer(ktSpace);            StrValue: ' ';   KeyLength: Length(' ') );
  KWR_TAB:                  TKeyWord = (KeyTypeInternal: Integer(ktSpace);            StrValue: TAB;   KeyLength: Length(TAB) );
  KWR_SPLITTER:             TKeyWord = (KeyTypeInternal: Integer(ktSplitter);         StrValue: ';';   KeyLength: Length(';') );
  KWR_TYPE_IDENT:           TKeyWord = (KeyTypeInternal: Integer(ktTypeIdent);        StrValue: ':';   KeyLength: Length(':') );
  KWR_ASSIGNING:            TKeyWord = (KeyTypeInternal: Integer(ktAssigning);        StrValue: '=';   KeyLength: Length('=') );
  KWR_QUOTE_SINGLE:         TKeyWord = (KeyTypeInternal: Integer(ktStringBorder);     StrValue: '''';  KeyLength: Length(''''));
  KWR_QUOTE_DOBLE:          TKeyWord = (KeyTypeInternal: Integer(ktStringBorder);     StrValue: '"';   KeyLength: Length('"') );
  KWR_OPENING_BRACKET:      TKeyWord = (KeyTypeInternal: Integer(ktOpeningBracket);   StrValue: '(';   KeyLength: Length('(') );
  KWR_CLOSING_BRACKET:      TKeyWord = (KeyTypeInternal: Integer(ktClosingBracket);   StrValue: ')';   KeyLength: Length(')') );

type

  TParamsHelper = class helper for TParams

  private

    procedure SetAsParams(const _Path: String; _Value: TParams);

  end;

function KeyWordTypeToStr(Value: TKeyWordType): String;
const

  SA_StringValues: array[TKeyWordType] of String = (

      { ktNone           } 'None',
      { ktSourceEnd      } 'SourceEnd',
      { ktLineEnd        } 'LineEnd',
      { ktSpace          } 'Space',
      { ktSplitter       } 'Splitter',
      { ktTypeIdent      } 'TypeIdent',
      { ktAssigning      } 'Assigning',
      { ktStringBorder   } 'StringBorder',
      { ktOpeningBracket } 'OpeningBracket',
      { ktClosingBracket } 'ClosingBracket'

  );

begin
  Result := SA_StringValues[Value];
end;

function StrToKeyWordType(const Value: String): TKeyWordType;
var
  Item: TKeyWordType;
begin

  for Item := Low(TKeyWordType) to High(TKeyWordType) do
    if SameText(KeyWordTypeToStr(Item), Value) then
      Exit(Item);

  raise EConvertError.CreateFmt('%s is not a TKeyWordType value', [Value]);

end;

{ TKeyWordHelper }

constructor TKeyWordHelper.Create(_KeyType: TKeyWordType; const _StrValue: String);
begin
  Create(Integer(_KeyType), _StrValue);
end;

function TKeyWordHelper.GetKeyType: TKeyWordType;
begin
  Result := TKeyWordType(KeyTypeInternal)
end;

procedure TKeyWordHelper.SetKeyType(const _Value: TKeyWordType);
begin
  if Integer(_Value) <> KeyTypeInternal then
    KeyTypeInternal := Integer(_Value)
end;

function TKeyWordHelper.TypeInSet(const _Set: TKeyWordTypes): Boolean;
begin
  Result := KeyType in _Set;
end;

{ TReadInfo }

constructor TReadInfo.Create;
begin

  Element     := _Element;
  Terminator  := _Terminator;
  Nested      := _Nested;
  NextElement := _NextElement;
  ReadFunc    := _ReadFunc;

end;

{ TReadInfoList }

procedure TReadInfoList.Add;
begin
  inherited Add(TReadInfo.Create(_Element, _Terminator, _Nested, _NextElement,_ReadFunc));
end;

{ TSyntaxInfo }

constructor TSyntaxInfo.Create;
begin
  Element     := _Element;
  Nested      := _Nested;
  InvalidKeys := _InvalidKeys;
end;

{ TSyntaxInfoList }

procedure TSyntaxInfoList.Add;
begin
  inherited Add(TSyntaxInfo.Create(_Element, _Nested, _InvalidKeys));
end;

{ TParamsStringParser }

constructor TParamsStringParser.Create(const _Source: String; _Params: TParams);
begin

  FReading := TReadInfoList.Create;
  FSyntax  := TSyntaxInfoList.Create;

  inherited Create(_Source);

  FParams := _Params;

end;

constructor TParamsStringParser.CreateNested(_Master: TCustomStringParser; _Params: TParams; _CursorShift: Int64);
begin

  FReading := TReadInfoList.Create;
  FSyntax  := TSyntaxInfoList.Create;

  inherited CreateNested(_Master);

  FParams := _Params;

end;

destructor TParamsStringParser.Destroy;
begin

  FreeAndNil(FReading);
  FreeAndNil(FSyntax );

  inherited Destroy;

end;

function TParamsStringParser.ElementTerminating(const _KeyWord: TKeyWord; var _NextElement: TElement; var _ReadFunc: TReadFunc): Boolean;
var
  RI: TReadInfo;
begin

  Result := ItemBody or (Element = etValue);

  if Result then

    for RI in FReading do

      if

          (RI.Element    = Element         ) and
          (RI.Terminator = _KeyWord.KeyType) and
          (RI.Nested     = Nested          )

      then begin

        _NextElement := RI.NextElement;
        _ReadFunc    := RI.ReadFunc;

        Exit;

      end;

  Result := False;

end;

procedure TParamsStringParser.CheckSyntax(const _KeyWord: TKeyWord);
var
  SI: TSyntaxInfo;
begin

  if ItemBody then

    for SI in FSyntax do

      if

          (SI.Element = Element) and
          (SI.Nested = Nested) and
          _KeyWord.TypeInSet(SI.InvalidKeys)

      then

        raise EParamsReadException.CreateFmt('Unexcpected keyword ''%s''', [_KeyWord.StrValue]);

end;

procedure TParamsStringParser.CompleteElement(const _KeyWord: TKeyWord);
var
  ReadFunc: TReadFunc;
  Next: TElement;
begin

  if ElementTerminating(_KeyWord, Next, ReadFunc) then
    if ReadFunc(_KeyWord) then
      FElement := Next;

end;

function TParamsStringParser.ReadName(const _KeyWord: TKeyWord): Boolean;
begin

  FCurrentName := ReadItem(True);
  TParam.ValidateName(FCurrentName);

  Result := True;

end;

function TParamsStringParser.ReadType(const _KeyWord: TKeyWord): Boolean;
begin

  FCurrentType := StrToParamDataType(ReadItem(True));
  CheckPresetType;

  Result := True;

end;

function TParamsStringParser.ReadValue(const _KeyWord: TKeyWord): Boolean;
begin

  { ����� ����� ��� ��������. ��� ����� �� ��������� � ������ � ��� ������ �� �����. ����� ����������� ��� �����. }
  CheckPresetType;

  case CurrentType of

    dtBoolean:    FParams.AsBoolean   [FCurrentName] := StrToBoolean(           ReadItem(False) );
    dtInteger:    FParams.AsInteger   [FCurrentName] := StrToInt(   TrimDigital(ReadItem(False)));
    dtBigInt:     FParams.AsBigInt    [FCurrentName] := StrToBigInt(TrimDigital(ReadItem(False)));
    dtFloat:      FParams.AsFloat     [FCurrentName] := StrToDouble(TrimDigital(ReadItem(False)));
    dtDateTime:   FParams.AsDateTime  [FCurrentName] := StrToDateTime(          ReadItem(False) );
    dtGUID:       FParams.AsGUID      [FCurrentName] := StrToGUID(              ReadItem(False) );
    dtAnsiString: FParams.AsAnsiString[FCurrentName] := AnsiString(             ReadItem(False) );
    dtString:     FParams.AsString    [FCurrentName] := UndoubleSymbols(        ReadItem(False) );
    dtBLOB:       FParams.AsBLOB      [FCurrentName] := HexStrToBLOB(           ReadItem(False) );

  end;

  FCurrentName := '';
  FCurrentType := dtUnknown;

  Result := True;

end;

procedure TParamsStringParser.CheckPresetType;
var
  P: TParam;
begin

  { ������������ ������� ��� ������ }
  if

      (CurrentType = dtUnknown) and
      FParams.FindParam(FCurrentName, P) and
      (P.DataType <> dtUnknown)

  then FCurrentType := P.DataType;

  if CurrentType = dtUnknown then
    raise EParamsReadException.Create('Unknown data type');

end;

procedure TParamsStringParser.CheckParams(_KeyWord: TKeyWord);
begin

  if (Element = etValue) and (CurrentType = dtParams) then begin

    { ���������. �������� ����������. }
    if not _KeyWord.TypeInSet([ktSpace, ktLineEnd, ktOpeningBracket]) then
      raise EParamsReadException.CreateFmt('''('' expected but ''%s'' found', [_KeyWord.StrValue]);

    { ���������. ���� �� ��������� ���������. }
    if _KeyWord.KeyType = ktOpeningBracket then
      ReadParams(_KeyWord);

  end;

  { ��������� ������. ����������. }
  if Nested then begin

    if _KeyWord.KeyType = ktClosingBracket then
      Terminate;

    { ��������� ������. �������� ����������. }
    if (_KeyWord.KeyType = ktSourceEnd) and not Terminated then
      raise EParamsReadException.Create('Unterminated nested params');

  end;

end;

procedure TParamsStringParser.ReadParams(_KeyWord: TKeyWord);
var
  P: TParams;
begin

  P := TParams.Create;
  try

    with TParamsStringParser.CreateNested(Self, P, _KeyWord.KeyLength) do

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
    FElement := etName;

  end;

end;

function TParamsStringParser.UndoubleSymbols(const _Value: String): String;
begin
  { ����������� ����� ������ ��������� ����������� ������ ������, ������� � �������������� ������ ��� ���� ���
    �������, ��� �������� ����������� ��������. �������, ������ �������� �������� �������. ��! ����� ����� ����� ������,
    ������ ��� ������������ �� ����� � ������������. }
  if FDoublingChar > #0 then Result := UndoubleStr(_Value, FDoublingChar)
  else Result := _Value;
end;

function TParamsStringParser.TrimDigital(const _Value: String): String;
begin
  Result := StringReplace(_Value, ' ', '', [rfReplaceAll]);
end;

procedure TParamsStringParser.InitParser;
begin

  inherited InitParser;

  with KeyWords do begin

    Add(KWR_SPACE          );
    Add(KWR_TAB            );
    Add(KWR_SPLITTER       );
    Add(KWR_TYPE_IDENT     );
    Add(KWR_ASSIGNING      );
    Add(KWR_QUOTE_SINGLE   );
    Add(KWR_QUOTE_DOBLE    );
    Add(KWR_OPENING_BRACKET);
    Add(KWR_CLOSING_BRACKET);

  end;

  with FReading do begin

    Add(etName,  ktTypeIdent,      False, etType,  ReadName );
    Add(etName,  ktTypeIdent,      True,  etType,  ReadName );
    Add(etName,  ktAssigning,      False, etValue, ReadName );
    Add(etName,  ktAssigning,      True,  etValue, ReadName );
    Add(etType,  ktAssigning,      False, etValue, ReadType );
    Add(etType,  ktAssigning,      True,  etValue, ReadType );
    Add(etValue, ktLineEnd,        False, etName,  ReadValue);
    Add(etValue, ktLineEnd,        True,  etName,  ReadValue);
    Add(etValue, ktSplitter,       False, etName,  ReadValue);
    Add(etValue, ktSplitter,       True,  etName,  ReadValue);
    Add(etValue, ktClosingBracket, True,  etName,  ReadValue);
    Add(etValue, ktSourceEnd,      False, etName,  ReadValue);
    Add(etValue, ktSourceEnd,      True,  etName,  ReadValue);
    Add(etValue, ktStringBorder,   True,  etName,  ReadValue);
    Add(etValue, ktStringBorder,   False, etName,  ReadValue);

  end;

  with FSyntax do begin

    Add(etName,  False, [ktClosingBracket, ktSourceEnd]);
    Add(etType,  False, [ktClosingBracket, ktLineEnd, ktSourceEnd]);
    Add(etType,  True,  [ktClosingBracket, ktLineEnd, ktSourceEnd]);

  end;

  AddSpecialRegion(TSpecialRegion, KWR_QUOTE_SINGLE, KWR_QUOTE_SINGLE);
  AddSpecialRegion(TSpecialRegion, KWR_QUOTE_DOBLE,  KWR_QUOTE_DOBLE );

end;

procedure TParamsStringParser.KeyEvent(const _KeyWord: TKeyWord);
begin

  inherited KeyEvent(_KeyWord);

  CheckSyntax(_KeyWord);
  CheckParams(_KeyWord);

  CompleteElement(_KeyWord);

end;

procedure TParamsStringParser.SpecialRegionClosed(_Region: TSpecialRegion);
begin

  with _Region do begin

    if ClosingKey.KeyLength = 1 then
      FDoublingChar := ClosingKey.StrValue[1];

    Move(- ClosingKey.KeyLength);
    try

      CompleteElement(_Region.ClosingKey);

    finally
      Move(_Region.ClosingKey.KeyLength);
      FDoublingChar := #0;
    end;

  end;

end;

{ TParamsHelper }

procedure TParamsHelper.SetAsParams(const _Path: String; _Value: TParams);
begin
  inherited SetAsParams(_Path, _Value);
end;

end.
