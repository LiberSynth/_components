unit uParamsStringParser;

(**********************************************************)
(*                                                        *)
(*                     Liber Synth Co                     *)
(*                                                        *)
(**********************************************************)

{ TODO 5 -oVasilyevSM -cTCustomStringParser: Этот юнит надо отладить и "заморозить". }

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

  TReadProc = procedure (const KeyWord: TKeyWord) of object;

  TReadInfo = record

    Element: TElement;
    Terminator: TKeyWordType;
    Nested: Boolean;
    NextElement: TElement;
    ReadProc: TReadProc;

    constructor Create(

        _Element: TElement;
        _Terminator: TKeyWordType;
        _Nested: Boolean;
        _NextElement: TElement;
        _ReadProc: TReadProc

    );

  end;

  TReadInfoList = class(TList<TReadInfo>)

  private

    procedure Add(

        _Element: TElement;
        _Terminator: TKeyWordType;
        _Nested: Boolean;
        _NextElement: TElement;
        _ReadProc: TReadProc

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

  {

    Просто параметры и этот парсер НЕ ДОЛЖНЫ:

      1.  Поддерживать комментарии.
      2.  Считывать зарегистрированные параметры из нетипизованного источника. Одно из двух, либо записываться в
          существующий параметр с таким же именем, либо поддерживать многострочные структуры. Это должен уметь потомок с
          свойством параметра Registered (предопределенный). Это свойство будет указывать, что он зарегистрирован для
          такого чтения. И тогда раширенный TParams.GetParam должен не жестко добавлять новый, а только если он не
          Registered.
      3.  Уметь назначать значения по умолчанию, когда после = ничего не указано.
      4.  Разбираться с кодировками. На входе должна быть хотя бы UTF-8 с BOM.

    Все эти проблемы должен решать класс-потомок TUserParamsParser.

      1.  Элементы параметров: имя, тип, значение. Тип уже здесь необязательный, но тогда для считывания надо заранее
          создать параметр с нужным типом. В него считается значение.
      2.  Указывать тип на следующей строке допустется. Значение после '=' указывать на следующей строке нельзя. Конец
          строки после "=" так же как  ';' - это конец параметра. И это значение Null для него. Иначе придется слишком
          сильно потрудиться, чтобы понять, что там в следующей строке, имя следующего параметра или значение текущего.
      3.  За этим исключением, между параметрами и их элементами допускается любое количество пробелов, табуляций,
          переходов на следующую строку и комментрариев. Перед значением - только пробелы, табуляция и комментарии.
      4.  Все что вызывает неадекватное чтение или неадекватную ошибку должно контролироваться в проверке синтаксиса.
          Настройка синтаксиса - InitParser - FSyntax.Add. Можно?пополнять по мере обнаружения.

  }

  TParamsStringParser = class(TCustomStringParser)

  strict private

    FElement: TElement;

    FReading: TReadInfoList;
    FSyntax: TSyntaxInfoList;

    FDoublingChar: Char;

    function ElementTerminating(

        const _KeyWord: TKeyWord;
        var _NextElement: TElement;
        var _ReadProc: TReadProc

    ): Boolean;
    procedure CheckSyntax(const _KeyWord: TKeyWord);
    procedure CheckParams(_KeyWord: TKeyWord);
    procedure CompleteElement(const _KeyWord: TKeyWord);

  protected

    procedure InitParser; override;

    procedure ReadName(const _KeyWord: TKeyWord); virtual; abstract;
    procedure ReadType(const _KeyWord: TKeyWord); virtual; abstract;
    procedure ReadValue(const _KeyWord: TKeyWord); virtual; abstract;
    procedure ReadParams(const _KeyWord: TKeyWord); virtual;
    function IsParamsType: Boolean; virtual; abstract;

    property DoublingChar: Char read FDoublingChar;

  public

    constructor Create(const _Source: String);
    constructor CreateNested(_Master: TCustomStringParser; _CursorShift: Int64);

    destructor Destroy; override;

    { Осоновная работа здесь }
    procedure KeyEvent(const _KeyWord: TKeyWord); override;
    procedure SpecialRegionClosed(_Region: TSpecialRegion); override;

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

  TQoutedStringRegion = class(TSpecialRegion)

  strict private

    function Doubling(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean;

  protected

    function CanClose(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean; override;

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
  ReadProc    := _ReadProc;

end;

{ TReadInfoList }

procedure TReadInfoList.Add;
begin
  inherited Add(TReadInfo.Create(_Element, _Terminator, _Nested, _NextElement,_ReadProc));
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

end;

constructor TParamsStringParser.CreateNested;
begin

  FReading := TReadInfoList.Create;
  FSyntax  := TSyntaxInfoList.Create;

  inherited CreateNested(_Master, _CursorShift);

end;

destructor TParamsStringParser.Destroy;
begin

  FreeAndNil(FReading);
  FreeAndNil(FSyntax );

  inherited Destroy;

end;

function TParamsStringParser.ElementTerminating(const _KeyWord: TKeyWord; var _NextElement: TElement; var _ReadProc: TReadProc): Boolean;
var
  RI: TReadInfo;
begin

  Result := ItemBody or (FElement = etValue);

  if Result then

    for RI in FReading do

      if

          (RI.Element    = FElement         ) and
          (RI.Terminator = _KeyWord.KeyType) and
          (RI.Nested     = Nested          )

      then begin

        _NextElement := RI.NextElement;
        _ReadProc    := RI.ReadProc;

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

        (SI.Element = FElement) and
        (SI.ItemBody = ItemBody) and
        (SI.Nested = Nested) and
        _KeyWord.TypeInSet(SI.InvalidKeys)

    then

      raise EParamsReadException.CreateFmt('Unexcpected keyword ''%s''', [_KeyWord.StrValue]);

end;

procedure TParamsStringParser.CheckParams(_KeyWord: TKeyWord);
begin

  if (FElement = etValue) and IsParamsType then begin

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

procedure TParamsStringParser.CompleteElement(const _KeyWord: TKeyWord);
var
  ReadProc: TReadProc;
  Next: TElement;
begin

  if ElementTerminating(_KeyWord, Next, ReadProc) then begin

    ReadProc(_KeyWord);
    FElement := Next;

  end;

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

    {   Element  Terminator        Nested NextElement ReadProc }
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

  end;

  {                RegionClass           OpeningKey        ClosingKey        UnterminatedMessage  }
  AddSpecialRegion(TQoutedStringRegion, KWR_QUOTE_SINGLE, KWR_QUOTE_SINGLE, 'Unterminated string');
  AddSpecialRegion(TQoutedStringRegion, KWR_QUOTE_DOBLE,  KWR_QUOTE_DOBLE,  'Unterminated string');

end;

procedure TParamsStringParser.ReadParams(const _KeyWord: TKeyWord);
begin
  FElement := etName;
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

{ TQoutedStringRegion }

function TQoutedStringRegion.Doubling(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean;
begin

  Result :=

    (ClosingKey.KeyLength = 1) and
    (Copy(_Parser.Source, _Parser.Cursor, 2) = ClosingKey.StrValue + ClosingKey.StrValue);

  if Result then begin

    _Parser.MoveEvent;
    _Parser.Move(2);
    _Handled := True;

  end;

end;

function TQoutedStringRegion.CanClose(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean;
begin
  Result := inherited and not Doubling(_Parser, _Handled);
end;

end.
