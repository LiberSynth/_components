unit uParamsStringParser;

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
  Generics.Collections, SysUtils,
  { LiberSynth }
  uConsts, uTypes, uCustomStringParser, uStrUtils;

{ TODO 2 -oVasilyevSM -cTParamsReader: Как потом будут читаться пустые вложенные A:Params = () }

type

  TItemType = (itName, itType, itValue);

  TKeyType = (
  { inherits from uCustomStringParser.TKeyType }

      ktNone, ktSourceEnd, ktLineEnd, ktSpace, ktSplitter, ktTypeIdent, ktAssigning, ktStringBorder, ktNestedOpening,
      ktNestedClosing

  );
  TKeyTypes = set of TKeyType;

  TOperation = (opProcessing, opTerminating);
  TNested    = (nsNested, nsNotNested, nsNoMatter);

  TReadInfo = record

    Operation: TOperation;
    ItemType: TItemType;
    Nested: TNested;
    KeyTypes: TKeyTypes;

    constructor Create(

        _Operation: TOperation;
        _ItemType: TItemType;
        _Nested: TNested;
        _KeyTypes: TKeyTypes

    );

  end;

  TReadInfoList = class(TList<TReadInfo>)

  public

    procedure Add(

        _Operation: TOperation;
        _ItemType: TItemType;
        _Nested: TNested;
        _KeyTypes: TKeyTypes

    );

  end;

  TSyntaxInfo = record

    ItemType: TItemType;
    ItemStanding: TStanding;
    Nested: TNested;
    Keys: TKeyTypes;

    constructor Create(

        _ItemType: TItemType;
        _ItemStanding: TStanding;
        _Nested: TNested;
        _Keys: TKeyTypes

    );

  end;

  TSyntaxInfoList = class(TList<TSyntaxInfo>)

  private

    procedure Add(

        _ItemType: TItemType;
        _ItemStanding: TStanding;
        _Nested: TNested;
        _Keys: TKeyTypes

    );

  end;

  { 1 TODO -oVasilyevSM -cTParamsStringParser: В хэлп. }
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
      5.  ; в конце последнего параметра в структуре допустима, но не является предпочтительной формой записи:
          A:Params=(B:Params=(C:Integer=123;););
          Перход на следующую строку означает конец элемента, поэтому ; в начале строки не допустима.
      6.  Пустая вложенная структура допустима

  }

  TParamsStringParser = class(TCustomStringParser)

  const

    TA_TypedNested: array[Boolean] of TNested = (nsNotNested, nsNested);

  strict private

    FItemType: TItemType;

    FReading: TReadInfoList;
    FExcludingSyntax: TSyntaxInfoList;
    FStrictSyntax: TSyntaxInfoList;

    FDoublingChar: Char;

  protected

    procedure InitParser; override;

    function ItemProcessingKey(_KeyWord: TKeyWord): Boolean; override;
    function ItemTerminatingKey(_KeyWord: TKeyWord): Boolean; override;
    procedure CheckSyntax(const _KeyWord: TKeyWord); override;
    procedure DoAfterKey(_KeyWord: TKeyWord); override;

    procedure ReadName; virtual; abstract;
    procedure ReadType; virtual; abstract;
    procedure ReadValue; virtual; abstract;
    procedure ReadParams(_CursorShift: Int64); virtual; abstract;
    function IsParamsType: Boolean; virtual; abstract;

    property ItemType: TItemType read FItemType write FItemType;
    property Reading: TReadInfoList read FReading;
    property DoublingChar: Char read FDoublingChar write FDoublingChar;

  public

    constructor Create(const _Source: String);
    constructor CreateNested(_Master: TCustomStringParser);

    destructor Destroy; override;

    procedure ProcessItem; override;
    procedure ToggleItem(_KeyWord: TKeyWord); override;

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
  KWR_OPENING_BRACKET:      TKeyWord = (KeyTypeInternal: Integer(ktNestedOpening);    StrValue: '(';   KeyLength: Length('(') );
  KWR_CLOSING_BRACKET:      TKeyWord = (KeyTypeInternal: Integer(ktNestedClosing);    StrValue: ')';   KeyLength: Length(')') );

type

  TKeyWordHelper = record helper for TKeyWord

  private

    constructor Create(_KeyType: TKeyType; const _StrValue: String); overload;

    function GetKeyType: TKeyType;
    procedure SetKeyType(const _Value: TKeyType);

    {$HINTS OFF}
    function TypeInSet(const _Set: TKeyTypes): Boolean;
    {$HINTS ON}

    property KeyType: TKeyType read GetKeyType write SetKeyType;

  end;

  TQoutedStringRegion = class(TRegion)

  strict private

    function Doubling(_Parser: TCustomStringParser): Boolean;

  protected

    function CanOpen(_Parser: TCustomStringParser): Boolean; override;
    function CanClose(_Parser: TCustomStringParser): Boolean; override;
    procedure RegionOpened(_Parser: TCustomStringParser); override;
    procedure RegionClosed(_Parser: TCustomStringParser); override;

  end;

  TNestedParamsRegion = class(TRegion)

    function CanOpen(_Parser: TCustomStringParser): Boolean; override;
    procedure RegionOpened(_Parser: TCustomStringParser); override;
    procedure RegionClosed(_Parser: TCustomStringParser); override;

  end;

function KeyTypeToStr(Value: TKeyType): String;
const

  SA_StringValues: array[TKeyType] of String = (

      { ktNone           } 'None',
      { ktSourceEnd      } 'SourceEnd',
      { ktLineEnd        } 'LineEnd',
      { ktSpace          } 'Space',
      { ktSplitter       } 'Splitter',
      { ktTypeIdent      } 'TypeIdent',
      { ktAssigning      } 'Assigning',
      { ktStringBorder   } 'StringBorder',
      { ktNestedOpening  } 'OpeningBracket',
      { ktNestedClosing  } 'ClosingBracket'

  );

begin
  Result := SA_StringValues[Value];
end;

function StrToKeyType(const Value: String): TKeyType;
var
  Item: TKeyType;
begin

  for Item := Low(TKeyType) to High(TKeyType) do
    if SameText(KeyTypeToStr(Item), Value) then
      Exit(Item);

  raise EConvertError.CreateFmt('%s is not a TKeyType value', [Value]);

end;

{ TReadInfo }

constructor TReadInfo.Create;
begin

  Operation := _Operation;
  ItemType  := _ItemType;
  KeyTypes  := _KeyTypes;
  Nested    := _Nested;

end;

{ TReadInfoList }

procedure TReadInfoList.Add;
begin
  inherited Add(TReadInfo.Create(_Operation, _ItemType, _Nested, _KeyTypes));
end;

{ TSyntaxInfo }

constructor TSyntaxInfo.Create;
begin

  ItemType     := _ItemType;
  ItemStanding := _ItemStanding;
  Nested       := _Nested;
  Keys         := _Keys;

end;

{ TSyntaxInfoList }

procedure TSyntaxInfoList.Add;
begin
  inherited Add(TSyntaxInfo.Create(_ItemType, _ItemStanding, _Nested, _Keys));
end;

{ TParamsStringParser }

constructor TParamsStringParser.Create;
begin

  FReading         := TReadInfoList.Create;
  FExcludingSyntax := TSyntaxInfoList.Create;
  FStrictSyntax    := TSyntaxInfoList.Create;

  inherited Create(_Source);

end;

constructor TParamsStringParser.CreateNested;
begin

  FReading := TReadInfoList.Create;
  FExcludingSyntax := TSyntaxInfoList.Create;
  FStrictSyntax    := TSyntaxInfoList.Create;

  inherited CreateNested(_Master);

end;

destructor TParamsStringParser.Destroy;
begin

  FreeAndNil(FStrictSyntax );
  FreeAndNil(FExcludingSyntax);
  FreeAndNil(FReading);

  inherited Destroy;

end;

function TParamsStringParser.ItemProcessingKey(_KeyWord: TKeyWord): Boolean;
var
  RI: TReadInfo;
begin

  for RI in FReading do

    if

        (RI.Operation = opProcessing) and
        (RI.ItemType  = ItemType) and
        (RI.Nested in [TA_TypedNested[Nested], nsNoMatter]) and
        _KeyWord.TypeInSet(RI.KeyTypes)

    then Exit(True);

  Result := False;

end;

function TParamsStringParser.ItemTerminatingKey(_KeyWord: TKeyWord): Boolean;
var
  RI: TReadInfo;
begin

  for RI in FReading do

    if

        (RI.Operation = opTerminating) and
        (RI.ItemType  = FItemType) and
        (RI.Nested in [TA_TypedNested[Nested], nsNoMatter]) and
        _KeyWord.TypeInSet(RI.KeyTypes)

    then Exit(True);

  Result := False;

end;

procedure TParamsStringParser.CheckSyntax(const _KeyWord: TKeyWord);

  function _GetMessage: String;
  begin

    if _KeyWord.KeyType = ktSourceEnd then Result := 'Unexpected source end'
    else if Length(_KeyWord.StrValue) > 0 then Result := Format('Unexpected keyword ''%s''', [_KeyWord.StrValue])
    else Result := Format('Unexpected key ''%s''', [Copy(Source, Cursor, 1)])

  end;

var
  SI: TSyntaxInfo;
begin


  inherited CheckSyntax(_KeyWord);

  for SI in FExcludingSyntax do

    if

        (SI.ItemType = ItemType) and
        (SI.ItemStanding = ItemStanding) and
        (SI.Nested in [TA_TypedNested[Nested], nsNoMatter]) and
        _KeyWord.TypeInSet(SI.Keys)

    then begin

      raise EParamsReadException.Create(_GetMessage);

    end;

  for SI in FStrictSyntax do

    if

        (SI.ItemType = ItemType) and
        (SI.ItemStanding = ItemStanding) and
        (SI.Nested in [TA_TypedNested[Nested], nsNoMatter]) and
        not _KeyWord.TypeInSet(SI.Keys)

    then begin

      raise EParamsReadException.Create(_GetMessage);

    end;

end;

procedure TParamsStringParser.DoAfterKey(_KeyWord: TKeyWord);
begin
  if Nested and (_KeyWord.KeyType = ktNestedClosing) then
    Terminate;
end;

procedure TParamsStringParser.ToggleItem(_KeyWord: TKeyWord);
begin

  case ItemType of

    itName:

      case _KeyWord.KeyType of

        ktTypeIdent: ItemType := itType;
        ktAssigning: ItemType := itValue;

      else
        Exit;
      end;

    itType:  ItemType := itValue;
    itValue: ItemType := itName;

  else
    Exit;
  end;

  inherited ToggleItem(_KeyWord);

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

  with Reading do begin

// ktSourceEnd, ktLineEnd, ktSpace, ktSplitter, ktTypeIdent, ktAssigning, ktStringBorder, ktNestedOpening, ktNestedClosing
    {   Operation      ItemType  Nested      KeyTypes                                      }
    Add(opProcessing,  itName,   nsNoMatter, [ktLineEnd, ktSpace, ktTypeIdent, ktAssigning]);
    Add(opTerminating, itName,   nsNoMatter, [ktTypeIdent, ktAssigning]                    );

    Add(opProcessing,  itType,   nsNoMatter, [ktLineEnd, ktSpace, ktAssigning]);
    Add(opTerminating, itType,   nsNoMatter, [ktAssigning]                    );

    Add(opProcessing,  itValue,  nsNotNested, [ktLineEnd, ktSplitter, ktSourceEnd]);
    Add(opTerminating, itValue,  nsNotNested, [ktLineEnd, ktSplitter, ktSourceEnd]);

    Add(opProcessing,  itValue,  nsNested,    [ktLineEnd, ktSplitter, ktSourceEnd, ktNestedClosing]);
    Add(opTerminating, itValue,  nsNested,    [ktLineEnd, ktSplitter, ktSourceEnd, ktNestedClosing]);

  end;

  with FExcludingSyntax do begin

    {   ItemType  ItemStanding  Nested      Keys            }
    Add(itName,   stInside,     nsNoMatter, [ktSourceEnd]);
    Add(itName,   stAfter,      nsNoMatter, [ktSourceEnd]);
    Add(itType,   stInside,     nsNoMatter, [ktSourceEnd]);
    Add(itType,   stAfter,      nsNoMatter, [ktSourceEnd]);

  end;

  with FStrictSyntax do begin

    {   ItemType  ItemStanding Nested       Keys                                                          }
    Add(itName,   stBefore,    nsNotNested, [ktSpace, ktLineEnd, ktSourceEnd]                             );
    Add(itName,   stBefore,    nsNested,    [ktSpace, ktLineEnd, ktSourceEnd, ktNestedClosing]            );
    Add(itValue,  stBefore,    nsNoMatter,  [ktSpace, ktLineEnd, ktSourceEnd, ktNestedOpening, ktSplitter]);
    Add(itValue,  stAfter,     nsNotNested, [ktSpace, ktLineEnd, ktSourceEnd, ktSplitter]                 );
    Add(itValue,  stAfter,     nsNested,    [ktSpace, ktLineEnd, ktSourceEnd, ktNestedClosing, ktSplitter]);

  end;

  {         RegionClass          OpeningKey           ClosingKey           Caption }
  AddRegion(TQoutedStringRegion, KWR_QUOTE_SINGLE,    KWR_QUOTE_SINGLE,    'string'    );
  AddRegion(TQoutedStringRegion, KWR_QUOTE_DOBLE,     KWR_QUOTE_DOBLE,     'string'    );
  AddRegion(TNestedParamsRegion, KWR_OPENING_BRACKET, KWR_CLOSING_BRACKET, 'parameters');

end;

procedure TParamsStringParser.ProcessItem;
begin

  case ItemType of

    itName:  ReadName;
    itType:  ReadType;
    itValue: ReadValue;

  end;

  inherited ProcessItem;

end;

{ TKeyWordHelper }

constructor TKeyWordHelper.Create(_KeyType: TKeyType; const _StrValue: String);
begin
  Create(Integer(_KeyType), _StrValue);
end;

function TKeyWordHelper.GetKeyType: TKeyType;
begin
  Result := TKeyType(KeyTypeInternal)
end;

procedure TKeyWordHelper.SetKeyType(const _Value: TKeyType);
begin
  if Integer(_Value) <> KeyTypeInternal then
    KeyTypeInternal := Integer(_Value)
end;

function TKeyWordHelper.TypeInSet(const _Set: TKeyTypes): Boolean;
begin
  Result := KeyType in _Set;
end;

{ TQoutedStringRegion }

function TQoutedStringRegion.Doubling(_Parser: TCustomStringParser): Boolean;
begin

  Result :=

    (ClosingKey.KeyLength = 1) and
    (Copy(_Parser.Source, _Parser.Cursor, 2) = ClosingKey.StrValue + ClosingKey.StrValue);

  if Result then begin

    _Parser.MoveEvent;
    _Parser.Move;

  end;

end;

function TQoutedStringRegion.CanOpen(_Parser: TCustomStringParser): Boolean;
begin

  with _Parser as TParamsStringParser do

    Result :=

        (ItemType = itValue) and
        (ItemStanding = stBefore) and
        inherited;

end;

function TQoutedStringRegion.CanClose(_Parser: TCustomStringParser): Boolean;
begin
  Result := inherited and not Doubling(_Parser);
end;

procedure TQoutedStringRegion.RegionOpened(_Parser: TCustomStringParser);
begin

  inherited RegionOpened(_Parser);

//  with _Parser as TParamsStringParser do begin
//
//    ItemStanding := stInside;
//    ItemStart := Cursor;
//    FLocation.Remember(Cursor);
//
//  end;

end;

procedure TQoutedStringRegion.RegionClosed(_Parser: TCustomStringParser);
begin

  inherited RegionClosed(_Parser);

  with _Parser as TParamsStringParser do begin

    if ClosingKey.KeyLength = 1 then
      DoublingChar := ClosingKey.StrValue[1];

    Move(- ClosingKey.KeyLength);
    try

      ProcessItem;

    finally

      Move(ClosingKey.KeyLength);
      DoublingChar := #0;
      Location.Remember(Cursor);


    end;

  end;

end;

{ TNestedParamsRegion }

function TNestedParamsRegion.CanOpen(_Parser: TCustomStringParser): Boolean;
begin
  Result := inherited and (_Parser as TParamsStringParser).IsParamsType;
end;

procedure TNestedParamsRegion.RegionOpened(_Parser: TCustomStringParser);
begin

  with _Parser as TParamsStringParser do begin

    Move(OpeningKey.KeyLength);
    ReadParams({}OpeningKey.KeyLength{});

  end;

end;

procedure TNestedParamsRegion.RegionClosed(_Parser: TCustomStringParser);
begin

  with _Parser as TParamsStringParser do begin

    ItemType := itValue;
    ItemStanding := stAfter;
    ItemStart := 0;
    Location.Remember(Cursor + ClosingKey.KeyLength);

  end;

end;

end.
