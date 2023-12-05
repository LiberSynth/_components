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
  uConsts, uCustomStringParser, uStrUtils;

type

  TElement = (etName, etType, etValue);

  TKeyWordType = (
  { inherits from uCustomStringParser.TKeyWordType }

      ktNone, ktSourceEnd, ktLineEnd, ktSpace, ktSplitter, ktTypeIdent, ktAssigning, ktStringBorder, ktNestedOpening,
      ktNestedClosing

  );
  TKeyWordTypes = set of TKeyWordType;

  TKeyWordHelper = record helper for TKeyWord

  private

    constructor Create(_KeyType: TKeyWordType; const _StrValue: String); overload;

    function GetKeyType: TKeyWordType;
    procedure SetKeyType(const _Value: TKeyWordType);

    {$HINTS OFF}
    function TypeInSet(const _Set: TKeyWordTypes): Boolean;
    {$HINTS ON}

    property KeyType: TKeyWordType read GetKeyType write SetKeyType;

  end;

  TReadProc = procedure of object;

  TReadInfo = record

    Element: TElement;
    TerminatorInternal: Integer;
    Nested: Boolean;
    NextElement: TElement;
    ReadProc: TReadProc;

    constructor Create(

        _Element: TElement;
        _TerminatorInternal: Integer;
        _Nested: Boolean;
        _NextElement: TElement;
        _ReadProc: TReadProc

    );

  end;

  TReadInfoHelper = record helper for TReadInfo

  private

    function GetTerminator: TKeyWordType;
    procedure SetTerminator(const _Value: TKeyWordType);

    constructor Create(

        _Element: TElement;
        _Terminator: TKeyWordType;
        _Nested: Boolean;
        _NextElement: TElement;
        _ReadProc: TReadProc

    ); overload;

    property Terminator: TKeyWordType read GetTerminator write SetTerminator;

  end;

  TReadInfoList = class(TList<TReadInfo>)

  public

    procedure Add(

        _Element: TElement;
        _TerminatorInternal: Integer;
        _Nested: Boolean;
        _NextElement: TElement;
        _ReadProc: TReadProc

    ); overload;

    procedure Add(

        _Element: TElement;
        _Terminator: TKeyWordType;
        _Nested: Boolean;
        _NextElement: TElement;
        _ReadProc: TReadProc

    ); overload;

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

  { 1 TODO -oVasilyevSM -cTParamsStringParser: � ����. }
  {

    ������ ��������� � ���� ������ �� ������:

      1.  ������������ �����������.
      2.  ��������� ������������������ ��������� �� ��������������� ���������. ���� �� ����, ���� ������������ �
          ������������ �������� � ����� �� ������, ���� ������������ ������������� ���������. ��� ������ ����� ������� �
          ��������� ��������� Registered (����������������). ��� �������� ����� ���������, ��� �� ��������������� ���
          ������ ������. � ����� ���������� TParams.GetParam ������ �� ������ ��������� �����, � ������ ���� �� ��
          Registered.
      3.  ����� ��������� �������� �� ���������, ����� ����� = ������ �� �������.
      4.  ����������� � �����������. �� ����� ������ ���� ���� �� UTF-8 � BOM.

    ��� ��� �������� ������ ������ �����-������� TUserParamsParser.

      1.  �������� ����������: ���, ���, ��������. ��� ��� ����� ��������������, �� ����� ��� ���������� ���� �������
          ������� �������� � ������ �����. � ���� ��������� ��������.
      2.  ��������� ��� �� ��������� ������ ����������. �������� ����� '=' ��������� �� ��������� ������ ������. �����
          ������ ����� "=" ��� �� ���  ';' - ��� ����� ���������. � ��� �������� Null ��� ����. ����� �������� �������
          ������ �����������, ����� ������, ��� ��� � ��������� ������, ��� ���������� ��������� ��� �������� ��������.
      3.  �� ���� �����������, ����� ����������� � �� ���������� ����������� ����� ���������� ��������, ���������,
          ��������� �� ��������� ������ � �������������. ����� ��������� - ������ �������, ��������� � �����������.
      4.  ��� ��� �������� ������������ ������ ��� ������������ ������ ������ ���������������� � �������� ����������.
          ��������� ���������� - InitParser - FSyntax.Add. �����?��������� �� ���� �����������.

  }

  TParamsStringParser = class(TCustomStringParser)

  strict private

    FElement: TElement;

    FReading: TReadInfoList;
    FSyntax: TSyntaxInfoList;

    FDoublingChar: Char;

    function ElementTerminating(

        _KeyType: TKeyWordType;
        var _NextElement: TElement;
        var _ReadProc: TReadProc

    ): Boolean;
    procedure CheckSyntax(const _KeyWord: TKeyWord);
    procedure CheckParams(_KeyWord: TKeyWord);

  protected

    procedure InitParser; override;

    procedure ReadName; virtual; abstract;
    procedure ReadType; virtual; abstract;
    procedure ReadValue; virtual; abstract;
    procedure ReadParams(const _KeyWord: TKeyWord); virtual;
    function IsParamsType: Boolean; virtual; abstract;

    property Reading: TReadInfoList read FReading;
    property DoublingChar: Char read FDoublingChar write FDoublingChar;

  public

    constructor Create(const _Source: String);
    constructor CreateNested(_Master: TCustomStringParser; _CursorShift: Int64);

    destructor Destroy; override;

    (*****************************)
    (*                           *)
    (*   ������� ������� �����   *)
    (*                           *)
    (*****************************)
    procedure KeyEvent(const _KeyWord: TKeyWord); override;
    procedure CompleteElement(const _KeyWord: TKeyWord);

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

  TQoutedStringRegion = class(TSpecialRegion)

  strict private

    function Doubling(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean;

  protected

    function CanClose(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean; override;
    procedure SpecialRegionClosed(_Parser: TCustomStringParser); override;

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
      { ktNestedOpening  } 'OpeningBracket',
      { ktNestedClosing  } 'ClosingBracket'

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

  Element            := _Element;
  TerminatorInternal := _TerminatorInternal;
  Nested             := _Nested;
  NextElement        := _NextElement;
  ReadProc           := _ReadProc;

end;

{ TReadInfoHelper }

constructor TReadInfoHelper.Create(_Element: TElement; _Terminator: TKeyWordType; _Nested: Boolean; _NextElement: TElement; _ReadProc: TReadProc);
begin
  Create(_Element, Integer(_Terminator), _Nested, _NextElement, _ReadProc);
end;

function TReadInfoHelper.GetTerminator: TKeyWordType;
begin
  Result := TKeyWordType(TerminatorInternal);
end;

procedure TReadInfoHelper.SetTerminator(const _Value: TKeyWordType);
begin
  TerminatorInternal := Integer(_Value);
end;

{ TReadInfoList }

procedure TReadInfoList.Add(_Element: TElement; _TerminatorInternal: Integer; _Nested: Boolean; _NextElement: TElement; _ReadProc: TReadProc);
begin
  inherited Add(TReadInfo.Create(_Element, _TerminatorInternal, _Nested, _NextElement,_ReadProc));
end;

procedure TReadInfoList.Add(_Element: TElement; _Terminator: TKeyWordType; _Nested: Boolean; _NextElement: TElement; _ReadProc: TReadProc);
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

function TParamsStringParser.ElementTerminating(_KeyType: TKeyWordType; var _NextElement: TElement; var _ReadProc: TReadProc): Boolean;
var
  RI: TReadInfo;
begin

  Result := ItemBody or (FElement = etValue);

  if Result then

    for RI in FReading do

      if

          (RI.Element    = FElement) and
          (RI.Terminator = _KeyType) and
          (RI.Nested     = Nested  )

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

    { ���������. �������� ����������. }
    if not _KeyWord.TypeInSet([ktSpace, ktLineEnd, ktNestedOpening]) then
      raise EParamsReadException.CreateFmt('''('' expected but ''%s'' found', [_KeyWord.StrValue]);

    { ���������. ���� �� ��������� ���������. }
    if _KeyWord.KeyType = ktNestedOpening then
      ReadParams(_KeyWord);

  end;

  { ��������� ������. ����������. }
  if Nested then begin

    if _KeyWord.KeyType = ktNestedClosing then
      Terminate;

    { ��������� ������. �������� ����������. }
    if (_KeyWord.KeyType = ktSourceEnd) and not Terminated then
      raise EParamsReadException.Create('Unterminated nested params');

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

  with Reading do begin

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
    Add(etValue, ktNestedClosing,  True,  etName,     ReadValue);
    Add(etValue, ktSourceEnd,      False, etName,     ReadValue);
    Add(etValue, ktSourceEnd,      True,  etName,     ReadValue);
    Add(etValue, ktStringBorder,   True,  etName,     ReadValue);
    Add(etValue, ktStringBorder,   False, etName,     ReadValue);

  end;

  with FSyntax do begin

    {   Element ItemBody Nested InvalidKeys                              }
    Add(etName, False,   False, [ktNestedOpening, ktNestedClosing]       );
    Add(etName, False,   True,  [ktNestedOpening]                        );
    Add(etName, True,    True,  [ktNestedClosing]                        );
    Add(etName, True,    False, [ktNestedClosing, ktSourceEnd]           );
    Add(etType, True,    False, [ktNestedClosing, ktLineEnd, ktSourceEnd]);
    Add(etType, True,    True,  [ktNestedClosing, ktLineEnd, ktSourceEnd]);

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

procedure TParamsStringParser.CompleteElement(const _KeyWord: TKeyWord);
var
  ReadProc: TReadProc;
  Next: TElement;
begin

  if ElementTerminating(_KeyWord.KeyType, Next, ReadProc) then begin

    ReadProc;
    FElement := Next;

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

  end else _Handled := False;

end;

function TQoutedStringRegion.CanClose(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean;
begin
  Result := inherited and not Doubling(_Parser, _Handled);
end;

procedure TQoutedStringRegion.SpecialRegionClosed(_Parser: TCustomStringParser);
begin

  inherited SpecialRegionClosed(_Parser);

  with _Parser as TParamsStringParser do begin

    if ClosingKey.KeyLength = 1 then
      DoublingChar := ClosingKey.StrValue[1];

    Move(- ClosingKey.KeyLength);
    try

      CompleteElement(ClosingKey);

    finally

      Move(ClosingKey.KeyLength);
      DoublingChar := #0;

    end;

  end;

end;

end.
