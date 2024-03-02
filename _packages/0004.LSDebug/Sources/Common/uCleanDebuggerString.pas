unit uCleanDebuggerString;

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
  { LSL }
  uCore, uCustomReadWrite, uCustomStringParser, uStrUtils, uConsts, uFileUtils;

function CleanDebuggerString(const Value: String): String;

implementation

type

  TKeyType = ( { inherits from uCustomStringParser.TKeyType }

      ktNone, ktSourceEnd, ktLineEnd, ktStringBorder, ktDecimalPrefix, ktEndBreak

  );
  TKeyTypes = set of TKeyType;

const

  KWR_QUOTE_SINGLE:   TKeyWord = (KeyTypeInternal: Integer(ktStringBorder ); StrValue: '''';  KeyLength: Length('''' ));
  KWR_DECIMAL_PREFIX: TKeyWord = (KeyTypeInternal: Integer(ktDecimalPrefix); StrValue: '#';   KeyLength: Length('#'  ));
  KWR_END_BREAK:      TKeyWord = (KeyTypeInternal: Integer(ktEndBreak     ); StrValue: '...'; KeyLength: Length('...'));

type

  TKeyWordHelper = record helper for TKeyWord

  private

    constructor Create(_KeyType: TKeyType; const _StrValue: String); overload;

    function GetKeyType: TKeyType;
    procedure SetKeyType(const _Value: TKeyType);
    function TypeInSet(const _Set: TKeyTypes): Boolean;

    property KeyType: TKeyType read GetKeyType write SetKeyType;

  end;

  TElementType = (etString, etDecimal, etEndBreak);

  TDebuggerStringParser = class(TCustomStringParser)

  strict private

    FElementType: TElementType;
    FDoublingChar: Char;
    FResultValue: String;

    function ReadString: String;
    function ReadDecimal: String;
    procedure SendString(const _Value: String);

  private

    property ResultValue: String read FResultValue write FResultValue;

  protected

    procedure InitParser; override;

    function ElementProcessingKey(_KeyWord: TKeyWord): Boolean; override;
    function ElementTerminatingKey(_KeyWord: TKeyWord): Boolean; override;
    procedure ToggleElement(_KeyWord: TKeyWord); override;

    property ElementType: TElementType read FElementType write FElementType;
    property DoublingChar: Char read FDoublingChar write FDoublingChar;

  public

    procedure ProcessElement; override;

  end;

  TQoutedStringRegion = class(TRegion)

  strict private

    function Doubling(_Parser: TCustomStringParser): Boolean;

  protected

    function CanClose(_Parser: TCustomStringParser): Boolean; override;
    procedure Opened(_Parser: TCustomStringParser); override;
    procedure Closed(_Parser: TCustomStringParser); override;

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

{ TDebuggerStringParser }

function TDebuggerStringParser.ReadString: String;
begin
  Result := ReadElement;
  if DoublingChar > #0 then
    Result := UndoubleStr(Result, DoublingChar);
end;

function TDebuggerStringParser.ReadDecimal: String;
var
  Value: String;
begin

  Value := ReadElement;

  if (Length(Value) > 0) and (Value[1] = '$') then
    Result := HexCharStrToStr(SC_DECIMAL_CHAR_SIGN + ReadElement)
  else
    Result := Char(StrToInt(ReadElement));

end;

procedure TDebuggerStringParser.SendString(const _Value: String);
begin
  ResultValue := ResultValue + _Value;
end;

procedure TDebuggerStringParser.InitParser;
begin

  inherited InitParser;

  with KeyWords do begin

    Add(KWR_DECIMAL_PREFIX);
    Add(KWR_END_BREAK     );

  end;

  {         RegionClass          OpeningKey        ClosingKey        Caption  }
  AddRegion(TQoutedStringRegion, KWR_QUOTE_SINGLE, KWR_QUOTE_SINGLE, 'string' );

end;

function TDebuggerStringParser.ElementProcessingKey(_KeyWord: TKeyWord): Boolean;
begin
  Result := _KeyWord.TypeInSet([ktDecimalPrefix, ktSourceEnd]);
end;

function TDebuggerStringParser.ElementTerminatingKey(_KeyWord: TKeyWord): Boolean;
begin
  Result := _KeyWord.TypeInSet([ktDecimalPrefix, ktEndBreak, ktSourceEnd]);
end;

procedure TDebuggerStringParser.ToggleElement(_KeyWord: TKeyWord);
begin

  case _KeyWord.KeyType of

    ktStringBorder:  ElementType := etString;
    ktDecimalPrefix: ElementType := etDecimal;
    ktEndBreak:      ElementType := etEndBreak;

  end;

  inherited ToggleElement(_KeyWord);

end;

procedure TDebuggerStringParser.ProcessElement;
begin

  case ElementType of

    etString:   SendString(ReadString );
    etDecimal:  SendString(ReadDecimal);
    etEndBreak: SendString('...'      );

  end;

  inherited ProcessElement;

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

function TQoutedStringRegion.CanClose(_Parser: TCustomStringParser): Boolean;
begin
  Result := inherited and not Doubling(_Parser);
end;

procedure TQoutedStringRegion.Opened(_Parser: TCustomStringParser);
begin

  with _Parser as TDebuggerStringParser do
  begin

    ProcessElement;
    ToggleElement(OpeningKey);

  end;

  inherited Opened(_Parser);

end;

procedure TQoutedStringRegion.Closed(_Parser: TCustomStringParser);
begin

  with _Parser as TDebuggerStringParser do begin

    if ClosingKey.KeyLength = 1 then
      DoublingChar := ClosingKey.StrValue[1];

    ProcessElement;
    DoublingChar := #0;

  end;

  inherited Closed(_Parser);

end;

function CleanDebuggerString(const Value: String): String;
begin

  { Здесь ридер не нужен, поскольку сбор результата статичен. }
  with TDebuggerStringParser.Create do

    try

      SetSource(Value);
      Read;
      Result := ResultValue;

    finally
      Free;
    end;

end;

end.
