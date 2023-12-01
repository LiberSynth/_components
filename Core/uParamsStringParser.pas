unit uParamsStringParser;

interface

uses
  { VCL }
  Generics.Collections, SysUtils,
  { vSoft }
  uConsts, uCustomStringParser, uStrUtils;

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
    ItemBody: Boolean;
    Nested: Boolean;
    InvalidKeys: TKeyWordTypes;

    constructor Create(

        _Element: TElement;
        _ItemBody: Boolean;
        _Nested: Boolean;
        _InvalidKeys: TKeyWordTypes

    );

  end;

  TSyntaxInfoList = class(TList<TSyntaxInfo>)

  private

    procedure Add(

        _Element: TElement;
        _ItemBody: Boolean;
        _Nested: Boolean;
        _InvalidKeys: TKeyWordTypes

    );

  end;

  TWriteValueProc  = procedure (const Value: String) of object;
  TWriteParamsProc = procedure (const _KeyWord: TKeyWord) of object;
  TBooleanFunc     = function: Boolean of object;

  TReaderWrapper = record

    ReadName: TWriteValueProc;
    ReadType: TWriteValueProc;
    ReadValue: TWriteValueProc;
    ReadParams: TWriteParamsProc;
    CurrentTypeIsParams: TBooleanFunc;

    constructor Create(

        _ReadName: TWriteValueProc;
        _ReadType: TWriteValueProc;
        _ReadValue: TWriteValueProc;
        _ReadParams: TWriteParamsProc;
        _CurrentTypeIsParams: TBooleanFunc

    );

  end;

  {

    Просто параметры и этот парсер НЕ ДОЛЖНЫ:

      1. Поддерживать комментарии.
      2. Уметь назначать значения по умолчанию, когда после = ничего не указано. Исключение - тип строка.
      3. Разбираться с кодировками. На входе должна быть хотя бы UTF-8 с BOM.

    Все эти проблемы должен решать класс-потомок TUserParamsParser.

    Элементы параметров: имя, тип, значение. Тип уже здесь необязательный, но тогда для считывания надо заранее создать
    параметр с нужным типом. В него считается значение.
    Указывать тип на следующей строке допустется. Значение, указанное после '=' на следующей строке нельзя. Конец
    строки или ';' - это конец параметра.
    Между элементами "имя" и "тип" и между параметрами допускается любое количество пробелов, табуляций и переходов на
    следующую строку. Перед значением - только пробелы и табуляция.
    Все что вызывает неадекватное чтение или неадекватную ошибку должно контролироваться в проверке синтаксиса.
    Настройка синтаксиса - InitParser - FSyntax.Add. Можно?пополнять по мере обнаружения.

  }
  TParamsStringParser = class(TCustomStringParser)

  strict private

    FElement: TElement;

    FReading: TReadInfoList;
    FSyntax: TSyntaxInfoList;
    FReaderWrapper: TReaderWrapper;

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

    procedure CheckParams(_KeyWord: TKeyWord);
    procedure ReadParams(const _KeyWord: TKeyWord);

  private

    property Element: TElement read FElement;

  protected

    procedure InitParser; override;
    { Осоновная работа здесь }
    procedure KeyEvent(const _KeyWord: TKeyWord); override;
    procedure SpecialRegionClosed(_Region: TSpecialRegion); override;

  public

    constructor Create(

        const _Source: String;
        _ReaderWrapper: TReaderWrapper

    );
    constructor CreateNested(

        _Master: TCustomStringParser;
        _CursorShift: Int64;
        _ReaderWrapper: TReaderWrapper

    );

    destructor Destroy; override;

    function UndoubleSymbols(const _Value: String): String;

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
  ItemBody    := _ItemBody;
  Nested      := _Nested;
  InvalidKeys := _InvalidKeys;

end;

{ TSyntaxInfoList }

procedure TSyntaxInfoList.Add;
begin
  inherited Add(TSyntaxInfo.Create(_Element, _ItemBody, _Nested, _InvalidKeys));
end;

{ TParamsStringParser }

constructor TParamsStringParser.Create;
begin

  FReading := TReadInfoList.Create;
  FSyntax  := TSyntaxInfoList.Create;

  inherited Create(_Source);

  FReaderWrapper := _ReaderWrapper;

end;

constructor TParamsStringParser.CreateNested;
begin

  FReading := TReadInfoList.Create;
  FSyntax  := TSyntaxInfoList.Create;

  inherited CreateNested(_Master, _CursorShift);

  FReaderWrapper := _ReaderWrapper;

end;

destructor TParamsStringParser.Destroy;
begin

  FreeAndNil(FReading);
  FreeAndNil(FSyntax );

  inherited Destroy;

end;

function TParamsStringParser.UndoubleSymbols(const _Value: String): String;
begin

  { Дублировать нужно только одиночный закрывающий регион символ, поэтому и раздублировать только его надо при
    условии, что значение считывается регионом. Поэтому, символ задается событием региона. Но! Здесь будет нужна отмена,
    потому что дублирование не нужно в комментариях. }

  if FDoublingChar > #0 then Result := UndoubleStr(_Value, FDoublingChar)
  else Result := _Value;

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

  for SI in FSyntax do

    if

        (SI.Element = Element) and
        (SI.ItemBody = ItemBody) and
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
  FReaderWrapper.ReadName(ReadItem(True));
  Result := True;
end;

function TParamsStringParser.ReadType(const _KeyWord: TKeyWord): Boolean;
begin
  FReaderWrapper.ReadType(ReadItem(True));
  Result := True;
end;

function TParamsStringParser.ReadValue(const _KeyWord: TKeyWord): Boolean;
begin
  FReaderWrapper.ReadValue(ReadItem(False));
  Result := True;
end;

procedure TParamsStringParser.CheckParams(_KeyWord: TKeyWord);
begin

  if (Element = etValue) and FReaderWrapper.CurrentTypeIsParams then begin

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

procedure TParamsStringParser.ReadParams(const _KeyWord: TKeyWord);
begin
  FReaderWrapper.ReadParams(_KeyWord);
  FElement := etName;
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

    {   Element  Terminator        Nested NextElement ReadFunc }
    Add(etName,  ktTypeIdent,      False, etType,     ReadName );
    Add(etName,  ktTypeIdent,      True,  etType,     ReadName );
    Add(etName,  ktAssigning,      False, etValue,    ReadName );
    Add(etName,  ktAssigning,      True,  etValue,    ReadName );
    Add(etType,  ktAssigning,      False, etValue,    ReadType );
    Add(etType,  ktAssigning,      True,  etValue,    ReadType );
    Add(etValue, ktLineEnd,        False, etName,     ReadValue);
    Add(etValue, ktLineEnd,        True,  etName,     ReadValue);
    Add(etValue, ktSplitter,       False, etName,     ReadValue);
    Add(etValue, ktSplitter,       True,  etName,     ReadValue);
    Add(etValue, ktClosingBracket, True,  etName,     ReadValue);
    Add(etValue, ktSourceEnd,      False, etName,     ReadValue);
    Add(etValue, ktSourceEnd,      True,  etName,     ReadValue);
    Add(etValue, ktStringBorder,   True,  etName,     ReadValue);
    Add(etValue, ktStringBorder,   False, etName,     ReadValue);

  end;

  with FSyntax do begin

    {   Element ItemBody Nested InvalidKeys                               }
    Add(etName, False,   False, [ktOpeningBracket, ktClosingBracket]      );
    Add(etName, False,   True,  [ktOpeningBracket]                        );
    Add(etName, True,    True,  [ktClosingBracket]                        );
    Add(etName, True,    False, [ktClosingBracket, ktSourceEnd]           );
    Add(etType, True,    False, [ktClosingBracket, ktLineEnd, ktSourceEnd]);
    Add(etType, True,    True,  [ktClosingBracket, ktLineEnd, ktSourceEnd]);
    { TODO 3 -oVasilyevSM -cSyntax: Extreme: String = ''' }

  end;

  {                RegionClass     OpeningKey        ClosingKey      }
  AddSpecialRegion(TSpecialRegion, KWR_QUOTE_SINGLE, KWR_QUOTE_SINGLE, 'Unterminated string');
  AddSpecialRegion(TSpecialRegion, KWR_QUOTE_DOBLE,  KWR_QUOTE_DOBLE,  'Unterminated string');

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

{ TReaderWrapper }

constructor TReaderWrapper.Create;
begin

  ReadName            := _ReadName;
  ReadType            := _ReadType;
  ReadValue           := _ReadValue;
  ReadParams          := _ReadParams;
  CurrentTypeIsParams := _CurrentTypeIsParams;

end;

end.
