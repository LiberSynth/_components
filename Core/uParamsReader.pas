unit uParamsReader;

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
    Просто параметры НЕ ДОЛЖНЫ поддерживать комментарии. Комментарии должны обрабатываться пронаследованным классом
    TIniParamsReader.
  }
  TParamsReader = class(TCustomStringParser)

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
    { Осоновная работа здесь }
    procedure KeyEvent(const _KeyWord: TKeyWord); override;
    procedure SpecialSegmentClosed(_Segment: TSpecialSegment); override;

  public

    constructor Create(const _Source: String; _Params: TParams);
    constructor CreateNested(_Master: TCustomStringParser; _Params: TParams; _CursorShift: Int64);

    destructor Destroy; override;

  end;

  EParamsReadException = class(EStringParserException);

function ParamsToStr(Params: TParams; SingleString: Boolean = False): String;
procedure StrToParams(const Value: String; Params: TParams);

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

function ParamsToStr(Params: TParams; SingleString: Boolean): String;
const

  SC_SingleParamMultiStringFormat = '%s: %s = %s' + CRLF;
  SC_SingleParamSingleStringFormat = '%s: %s = %s;';

  SC_NestedParamsMultiStringFormat =

      '%s: %s = (' + CRLF +
      '%s' +
      ')' + CRLF;

  SC_NestedParamsSingleStringFormat =

      '%s: %s = (%s);';

  function _NestedParamsFormat: String;
  begin
    if SingleString then Result := SC_NestedParamsSingleStringFormat
    else Result := SC_NestedParamsMultiStringFormat;
  end;

  function _SingleParamFormat: String;
  begin
    if SingleString then Result := SC_SingleParamSingleStringFormat
    else Result := SC_SingleParamMultiStringFormat;
  end;

  function _GetNested(_Param: TParam): String;
  begin
    Result := ParamsToStr(_Param.AsParams, SingleString);
    if not SingleString then ShiftText(1, Result);
  end;

  function _QuoteString(_Param: TParam): String;
  begin

    Result := _Param.AsString;

    if

        (_Param.DataType = dtString) and
        { Заключаем в кавычки по необходимости. Это только строки с этими символами: }
        (
            (Pos(CR,   Result) > 0) or
            (Pos(LF,   Result) > 0) or
            (Pos(';',  Result) > 0) or
            (Pos('''', Result) > 0) or
            (Pos('"',  Result) > 0)

        )

    then Result := QuoteStr(Result);

  end;

var
  Param: TParam;
begin

  Result := '';
  for Param in Params do

    if Param.DataType = dtParams then

      Result := Result + Format(_NestedParamsFormat, [

          Param.Name,
          ParamDataTypeToStr(Param.DataType),
          _GetNested(Param)

      ])

    else

      Result := Result + Format(_SingleParamFormat, [

          Param.Name,
          ParamDataTypeToStr(Param.DataType),
          _QuoteString(Param)

      ]);

  if SingleString then CutStr(Result, 1);

end;

procedure StrToParams(const Value: String; Params: TParams);
begin

  with TParamsReader.Create(Value, Params) do

    try

      Read;

    finally
      Free;
    end;

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

{ TParamsReader }

constructor TParamsReader.Create(const _Source: String; _Params: TParams);
begin

  FReading := TReadInfoList.Create;
  FSyntax  := TSyntaxInfoList.Create;

  inherited Create(_Source);

  FParams := _Params;

end;

constructor TParamsReader.CreateNested(_Master: TCustomStringParser; _Params: TParams; _CursorShift: Int64);
begin

  FReading := TReadInfoList.Create;
  FSyntax  := TSyntaxInfoList.Create;

  inherited CreateNested(_Master);

  FParams := _Params;

end;

destructor TParamsReader.Destroy;
begin

  FreeAndNil(FReading);
  FreeAndNil(FSyntax );

  inherited Destroy;

end;

function TParamsReader.ElementTerminating(const _KeyWord: TKeyWord; var _NextElement: TElement; var _ReadFunc: TReadFunc): Boolean;
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

procedure TParamsReader.CheckSyntax(const _KeyWord: TKeyWord);
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

procedure TParamsReader.CompleteElement(const _KeyWord: TKeyWord);
var
  ReadFunc: TReadFunc;
  Next: TElement;
begin

  if

      ElementTerminating(_KeyWord, Next, ReadFunc) and
      ReadFunc(_KeyWord)

  then

    FElement := Next;

end;

function TParamsReader.ReadName(const _KeyWord: TKeyWord): Boolean;
begin

  FCurrentName := ReadItem;
  TParam.ValidateName(FCurrentName);

  Result := True;

end;

function TParamsReader.ReadType(const _KeyWord: TKeyWord): Boolean;
begin

  FCurrentType := StrToParamDataType(ReadItem);
  CheckPresetType;

  Result := True;

end;

function TParamsReader.ReadValue(const _KeyWord: TKeyWord): Boolean;
begin

  { Здесь нужно это вызывать. Тип может не храниться в строке и его чтения не будет. Тогда вытаскиваем его здесь. }
  CheckPresetType;

  case CurrentType of

    dtBoolean:    FParams.AsBoolean   [FCurrentName] := StrToBoolean(ReadItem);
    dtInteger:    FParams.AsInteger   [FCurrentName] := StrToInt(TrimDigital(ReadItem));
    dtBigInt:     FParams.AsBigInt    [FCurrentName] := StrToBigInt(TrimDigital(ReadItem));
    dtFloat:      FParams.AsFloat     [FCurrentName] := StrToDouble(TrimDigital(ReadItem));
    dtDateTime:   FParams.AsDateTime  [FCurrentName] := StrToDateTime(ReadItem);
    dtGUID:       FParams.AsGUID      [FCurrentName] := StrToGUID(ReadItem);
    dtAnsiString: FParams.AsAnsiString[FCurrentName] := AnsiString(ReadItem);
    dtString:     FParams.AsString    [FCurrentName] := UndoubleSymbols(ReadItem);
    dtBLOB:       FParams.AsBLOB      [FCurrentName] := HexStrToBLOB(ReadItem);

  end;

  FCurrentName := '';
  FCurrentType := dtUnknown;

  Result := True;

end;

procedure TParamsReader.CheckPresetType;
var
  P: TParam;
begin

  { Определенный заранее тип данных }
  if

      (CurrentType = dtUnknown) and
      FParams.FindParam(FCurrentName, P) and
      (P.DataType <> dtUnknown)

  then FCurrentType := P.DataType;

  if CurrentType = dtUnknown then
    raise EParamsReadException.Create('Unknown data type');

end;

procedure TParamsReader.CheckParams(_KeyWord: TKeyWord);
begin

  if (Element = etValue) and (CurrentType = dtParams) then begin

    { Контейнер. Проверка синтаксиса. }
    if not _KeyWord.TypeInSet([ktSpace, ktLineEnd, ktOpeningBracket]) then
      raise EParamsReadException.CreateFmt('''('' expected but ''%s'' found', [_KeyWord.StrValue]);

    { Контейнер. Вход во вложенную структуру. }
    if _KeyWord.KeyType = ktOpeningBracket then
      ReadParams(_KeyWord);

  end;

  { Вложенный объект. Завершение. }
  if Nested then begin

    if _KeyWord.KeyType = ktClosingBracket then
      Terminate;

    { Вложенный объект. Проверка синтаксиса. }
    if (_KeyWord.KeyType = ktSourceEnd) and not Terminated then
      raise EParamsReadException.Create('Unterminated nested params');

  end;

end;

procedure TParamsReader.ReadParams(_KeyWord: TKeyWord);
var
  P: TParams;
begin

  P := TParams.Create;
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

    { TODO 2 -oVasilyevSM -cTParamsReader: Вот из-за чего этот класс не вынесен в отдельный модуль. SetAsParams надо держать в private. }
    FParams.SetAsParams(FCurrentName, P);

    CompleteItem;
    FCurrentName := '';
    FCurrentType := dtUnknown;
    FElement := etName;

  end;

end;

function TParamsReader.UndoubleSymbols(const _Value: String): String;
begin
  { Дублировать нужно только закрывающую строковый сегмент кавычку, поэтому и раздублировать только ее надо при
    условии, что значение считывается сегментом. Поэтому, символ задается событием сегмента. }
  if FDoublingChar > #0 then Result := UndoubleStr(_Value, FDoublingChar)
  else Result := _Value;
end;

function TParamsReader.TrimDigital(const _Value: String): String;
begin
  Result := StringReplace(_Value, ' ', '', [rfReplaceAll]);
end;

procedure TParamsReader.InitParser;
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

  AddSpecialSegment(TSpecialSegment, KWR_QUOTE_SINGLE, KWR_QUOTE_SINGLE);
  AddSpecialSegment(TSpecialSegment, KWR_QUOTE_DOBLE,  KWR_QUOTE_DOBLE );

end;

procedure TParamsReader.KeyEvent(const _KeyWord: TKeyWord);
begin

  inherited KeyEvent(_KeyWord);

  CheckSyntax(_KeyWord);
  CheckParams(_KeyWord);

  CompleteElement(_KeyWord);

end;

procedure TParamsReader.SpecialSegmentClosed(_Segment: TSpecialSegment);
begin

  with _Segment do begin

    if ClosingKey.KeyLength = 1 then
      FDoublingChar := ClosingKey.StrValue[1];

    Move(- ClosingKey.KeyLength);
    try

      CompleteElement(_Segment.ClosingKey);

    finally
      Move(_Segment.ClosingKey.KeyLength);
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
