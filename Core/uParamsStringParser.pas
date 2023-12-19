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

{ TODO 4 -oVasilyevSM -cuCustomStringParser: ƒл€ многострочных строковых параметров нужно экранирование. }

interface

uses
  { VCL }
  Generics.Collections, SysUtils,
  { LiberSynth }
  uConsts, uTypes, uCustomStringParser, uStrUtils;

type

  TElementType = (etName, etType, etValue);

  TKeyType = ( { inherits from uCustomStringParser.TKeyType }

      ktNone, ktSourceEnd, ktLineEnd, ktSpace, ktSplitter, ktTypeIdent, ktAssigning, ktStringBorder, ktNestedOpening,
      ktNestedClosing

  );
  TKeyTypes = set of TKeyType;

  TOperation = (opProcessing, opTerminating);
  TNested    = (nsNested, nsNotNested, nsNoMatter);

  TParamsStringParser = class(TCustomStringParser)

  strict private

  type

    TReadInfo = record

      Operation: TOperation;
      ElementType: TElementType;
      Nested: TNested;
      KeyTypes: TKeyTypes;

      constructor Create(

          _Operation: TOperation;
          _ElementType: TElementType;
          _Nested: TNested;
          _KeyTypes: TKeyTypes

      );

    end;

    TReadInfoList = class(TList<TReadInfo>)

    public

      procedure Add(

          _Operation: TOperation;
          _ElementType: TElementType;
          _Nested: TNested;
          _KeyTypes: TKeyTypes

      );

    end;

    TSyntaxInfo = record

      ElementType: TElementType;
      CursorStanding: TStanding;
      Nested: TNested;
      Keys: TKeyTypes;

      constructor Create(

          _ElementType: TElementType;
          _CursorStanding: TStanding;
          _Nested: TNested;
          _Keys: TKeyTypes

      );

    end;

    TSyntaxInfoList = class(TList<TSyntaxInfo>)

    private

      procedure Add(

          _ElementType: TElementType;
          _CursorStanding: TStanding;
          _Nested: TNested;
          _Keys: TKeyTypes

      );

    end;

  const

    TA_TypedNested: array[Boolean] of TNested = (nsNotNested, nsNested);

  strict private

    FElementType: TElementType;

    FReading: TReadInfoList;
    FExcludingSyntax: TSyntaxInfoList;
    FStrictSyntax: TSyntaxInfoList;

    FDoublingChar: Char;

  protected

    procedure InitParser; override;

    function ElementProcessingKey(_KeyWord: TKeyWord): Boolean; override;
    function ElementTerminatingKey(_KeyWord: TKeyWord): Boolean; override;
    procedure CheckSyntax(const _KeyWord: TKeyWord); override;

    procedure ReadName; virtual; abstract;
    procedure ReadType; virtual; abstract;
    procedure ReadValue; virtual; abstract;
    procedure ReadParams; virtual; abstract;
    function IsParamsType: Boolean; virtual; abstract;

    property Reading: TReadInfoList read FReading;
    property DoublingChar: Char read FDoublingChar write FDoublingChar;

  public

    constructor Create(const _Source: String); override;
    constructor CreateNested(_Master: TCustomStringParser); override;

    destructor Destroy; override;

    procedure KeyEvent(const _KeyWord: TKeyWord); override;
    procedure ProcessElement; override;
    procedure ToggleElement(_KeyWord: TKeyWord); override;

    property ElementType: TElementType read FElementType write FElementType;

  end;

  EParamsReadException = class(EStringParserException);

implementation

const

  KWR_SPACE:           TKeyWord = (KeyTypeInternal: Integer(ktSpace);         StrValue: ' ';  KeyLength: Length(' ' ));
  KWR_TAB:             TKeyWord = (KeyTypeInternal: Integer(ktSpace);         StrValue: TAB;  KeyLength: Length(TAB ));
  KWR_SPLITTER:        TKeyWord = (KeyTypeInternal: Integer(ktSplitter);      StrValue: ';';  KeyLength: Length(';' ));
  KWR_TYPE_IDENT:      TKeyWord = (KeyTypeInternal: Integer(ktTypeIdent);     StrValue: ':';  KeyLength: Length(':' ));
  KWR_ASSIGNING:       TKeyWord = (KeyTypeInternal: Integer(ktAssigning);     StrValue: '=';  KeyLength: Length('=' ));
  KWR_QUOTE_SINGLE:    TKeyWord = (KeyTypeInternal: Integer(ktStringBorder);  StrValue: ''''; KeyLength: Length(''''));
  KWR_QUOTE_DOBLE:     TKeyWord = (KeyTypeInternal: Integer(ktStringBorder);  StrValue: '"';  KeyLength: Length('"' ));
  KWR_OPENING_BRACKET: TKeyWord = (KeyTypeInternal: Integer(ktNestedOpening); StrValue: '(';  KeyLength: Length('(' ));
  KWR_CLOSING_BRACKET: TKeyWord = (KeyTypeInternal: Integer(ktNestedClosing); StrValue: ')';  KeyLength: Length(')' ));

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
    procedure Closed(_Parser: TCustomStringParser); override;

  end;

  TNestedParamsBlock = class(TBlock)

  protected

    function CanOpen(_Parser: TCustomStringParser): Boolean; override;
    procedure Execute(_Parser: TCustomStringParser; var _Handled: Boolean); override;

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

{ TParamsStringParser.TReadInfo }

constructor TParamsStringParser.TReadInfo.Create;
begin

  Operation   := _Operation;
  ElementType := _ElementType;
  KeyTypes    := _KeyTypes;
  Nested      := _Nested;

end;

{ TParamsStringParser.TReadInfoList }

procedure TParamsStringParser.TReadInfoList.Add;
begin
  inherited Add(TReadInfo.Create(_Operation, _ElementType, _Nested, _KeyTypes));
end;

{ TParamsStringParser.TSyntaxInfo }

constructor TParamsStringParser.TSyntaxInfo.Create;
begin

  ElementType    := _ElementType;
  CursorStanding := _CursorStanding;
  Nested         := _Nested;
  Keys           := _Keys;

end;

{ TParamsStringParser.TSyntaxInfoList }

procedure TParamsStringParser.TSyntaxInfoList.Add;
begin
  inherited Add(TSyntaxInfo.Create(_ElementType, _CursorStanding, _Nested, _Keys));
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

procedure TParamsStringParser.InitParser;
begin

  inherited InitParser;

  with KeyWords do begin

    Add(KWR_SPACE          );
    Add(KWR_TAB            );
    Add(KWR_SPLITTER       );
    Add(KWR_TYPE_IDENT     );
    Add(KWR_ASSIGNING      );
    { ¬от тут как раз нужен только закрывающий ключ, который укажет вложенному ридеру, что надо завершать текущее
      (последнее во вложенной структуре) значение. ј дл€ внешнего блока вообще ключи здесь не нужны.}
    Add(KWR_CLOSING_BRACKET);

  end;

  with Reading do begin

    {   Operation      ElementType Nested       KeyTypes                                             }
    Add(opProcessing,  etName,     nsNoMatter,  [ktLineEnd, ktSpace, ktTypeIdent, ktAssigning]       );
    Add(opTerminating, etName,     nsNoMatter,  [ktTypeIdent, ktAssigning]                           );

    Add(opProcessing,  etType,     nsNoMatter,  [ktLineEnd, ktSpace, ktAssigning]                    );
    Add(opTerminating, etType,     nsNoMatter,  [ktAssigning]                                        );

    Add(opProcessing,  etValue,    nsNotNested, [ktLineEnd, ktSplitter, ktSourceEnd]                 );
    Add(opTerminating, etValue,    nsNotNested, [ktLineEnd, ktSplitter, ktSourceEnd]                 );
    Add(opProcessing,  etValue,    nsNested,    [ktLineEnd, ktSplitter, ktSourceEnd, ktNestedClosing]);
    Add(opTerminating, etValue,    nsNested,    [ktLineEnd, ktSplitter, ktSourceEnd, ktNestedClosing]);

  end;

  with FExcludingSyntax do begin

    {   ElementType  CursorStanding  Nested      Keys         }
    Add(etName,      stInside,       nsNoMatter, [ktSourceEnd]);
    Add(etName,      stAfter,        nsNoMatter, [ktSourceEnd]);
    Add(etType,      stInside,       nsNoMatter, [ktSourceEnd]);
    Add(etType,      stAfter,        nsNoMatter, [ktSourceEnd]);

  end;

  with FStrictSyntax do begin

    {   ElementType  CursorStanding Nested       Keys                                                                           }
    Add(etName,      stBefore,      nsNotNested, [ktSpace, ktLineEnd, ktSourceEnd]                                              );
    Add(etName,      stBefore,      nsNested,    [ktSpace, ktLineEnd, ktSourceEnd, ktNestedClosing]                             );
    Add(etName,      stAfter,       nsNoMatter,  [ktSpace, ktLineEnd, ktTypeIdent, ktAssigning]                                 );
    Add(etType,      stAfter,       nsNoMatter,  [ktSpace, ktLineEnd, ktAssigning]                                              );
    Add(etValue,     stBefore,      nsNotNested, [ktSpace, ktLineEnd, ktSourceEnd, ktNestedOpening, ktSplitter]                 );
    Add(etValue,     stBefore,      nsNested,    [ktSpace, ktLineEnd, ktSourceEnd, ktNestedOpening, ktNestedClosing, ktSplitter]);
    Add(etValue,     stAfter,       nsNotNested, [ktSpace, ktLineEnd, ktSourceEnd, ktSplitter]                                  );
    Add(etValue,     stAfter,       nsNested,    [ktSpace, ktLineEnd, ktSourceEnd, ktNestedClosing, ktSplitter]);

  end;

  {         RegionClass          OpeningKey           ClosingKey           Caption     }
  AddRegion(TQoutedStringRegion, KWR_QUOTE_SINGLE,    KWR_QUOTE_SINGLE,    'string'    );
  AddRegion(TQoutedStringRegion, KWR_QUOTE_DOBLE,     KWR_QUOTE_DOBLE,     'string'    );
  AddRegion(TNestedParamsBlock,  KWR_OPENING_BRACKET, KWR_CLOSING_BRACKET, 'parameters');

end;

procedure TParamsStringParser.KeyEvent(const _KeyWord: TKeyWord);
begin
  inherited KeyEvent(_KeyWord);
  if Nested and (_KeyWord.KeyType = ktNestedClosing) then
    Terminate;
end;

function TParamsStringParser.ElementProcessingKey(_KeyWord: TKeyWord): Boolean;
var
  RI: TReadInfo;
begin

  for RI in FReading do

    if

        (RI.Operation = opProcessing) and
        (RI.ElementType = ElementType) and
        (RI.Nested in [TA_TypedNested[Nested], nsNoMatter]) and
        _KeyWord.TypeInSet(RI.KeyTypes)

    then Exit(True);

  Result := False;

end;

function TParamsStringParser.ElementTerminatingKey(_KeyWord: TKeyWord): Boolean;
var
  RI: TReadInfo;
begin

  for RI in Reading do

    if

        (RI.Operation = opTerminating) and
        (RI.ElementType = FElementType) and
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

        (SI.ElementType = ElementType) and
        (SI.CursorStanding = CursorStanding) and
        (SI.Nested in [TA_TypedNested[Nested], nsNoMatter]) and
        _KeyWord.TypeInSet(SI.Keys)

    then begin

      raise EParamsReadException.Create(_GetMessage);

    end;

  for SI in FStrictSyntax do

    if

        (SI.ElementType = ElementType) and
        (SI.CursorStanding = CursorStanding) and
        (SI.Nested in [TA_TypedNested[Nested], nsNoMatter]) and
        not _KeyWord.TypeInSet(SI.Keys)

    then begin

      raise EParamsReadException.Create(_GetMessage);

    end;

  if

      (ElementType = etValue) and
      (CursorStanding = stInside) and
      IsParamsType and
      (Source[Cursor] <> '(')

  then raise EParamsReadException.Create(_GetMessage);

end;

procedure TParamsStringParser.ProcessElement;
begin

  case ElementType of

    etName:  ReadName;
    etType:  ReadType;
    etValue: ReadValue;

  end;

  inherited ProcessElement;

end;

procedure TParamsStringParser.ToggleElement(_KeyWord: TKeyWord);
begin

  case ElementType of

    etName:

      case _KeyWord.KeyType of

        ktTypeIdent: ElementType := etType;
        ktAssigning: ElementType := etValue;

      else
        Exit;
      end;

    etType:  ElementType := etValue;
    etValue: ElementType := etName;

  else
    Exit;
  end;

  inherited ToggleElement(_KeyWord);

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

        (CursorStanding = stBefore) and
        (ElementType = etValue) and
        inherited;

end;

function TQoutedStringRegion.CanClose(_Parser: TCustomStringParser): Boolean;
begin
  Result := inherited and not Doubling(_Parser);
end;

procedure TQoutedStringRegion.Closed(_Parser: TCustomStringParser);
begin

  with _Parser as TParamsStringParser do begin

    if ClosingKey.KeyLength = 1 then
      DoublingChar := ClosingKey.StrValue[1];

    ProcessElement;
    DoublingChar := #0;

  end;

  inherited Closed(_Parser);

end;

{ TNestedParamsBlock }

function TNestedParamsBlock.CanOpen(_Parser: TCustomStringParser): Boolean;
begin

  with _Parser as TParamsStringParser do

    Result :=

        (ElementType = etValue) and
        (CursorStanding = stBefore) and
        inherited and
        IsParamsType;

end;

procedure TNestedParamsBlock.Execute(_Parser: TCustomStringParser; var _Handled: Boolean);
begin

  with _Parser as TParamsStringParser do
    ReadParams;

  inherited Execute(_Parser, _Handled);
  _Handled := True;

end;

end.
