unit uCustomStringParser;

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
  uConsts, uCore;

type

  { TODO 5 -oVasilyevSM -cTCustomStringParser: Section }

  TStanding = (stBefore, stInside, stAfter);

  TKeyType = (ktNone, ktSourceEnd, ktLineEnd);
  TKeyTypes = set of TKeyType;

  TKeyWord = record

    KeyTypeInternal: Integer;
    StrValue: String;
    KeyLength: Integer;

    constructor Create(_KeyTypeInternal: Integer; const _StrValue: String);

    function Equal(_Value: TKeyWord): Boolean;

  end;

  TKeyWordList = class(TList<TKeyWord>)
  end;

  TCustomStringParser = class;

  TRegion = class

  strict private

    FOpeningKey: TKeyWord;
    FClosingKey: TKeyWord;
    FCaption: String;

  private

    constructor Create(

        const _OpeningKey: TKeyWord;
        const _ClosingKey: TKeyWord;
        const _Caption: String

    );

    procedure Open(_Parser: TCustomStringParser);
    procedure Close(_Parser: TCustomStringParser);

    procedure CheckUnterminating;

    property Caption: String read FCaption;

  protected

    function CanOpen(_Parser: TCustomStringParser): Boolean; virtual;
    function CanClose(_Parser: TCustomStringParser): Boolean; virtual;
    procedure Opened(_Parser: TCustomStringParser); virtual;
    procedure Closed(_Parser: TCustomStringParser); virtual;

  public

    property OpeningKey: TKeyWord read FOpeningKey;
    property ClosingKey: TKeyWord read FClosingKey;

  end;

  TRegionClass = class of TRegion;

  TRegionList = class(TObjectList<TRegion>)

  strict private

    FActive: Boolean;
    FActiveRegion: TRegion;

  private

    function TryOpen(_Parser: TCustomStringParser): Boolean;
    function TryClose(_Parser: TCustomStringParser): Boolean;
    procedure OpenRegion(_Parser: TCustomStringParser; _Region: TRegion);
    procedure CloseRegion(_Parser: TCustomStringParser);
    procedure CheckUnterminated;

    property Active: Boolean read FActive;
    property ActiveRegion: TRegion read FActiveRegion;

  end;

  TBlock = class(TRegion)

  protected

    procedure Opened(_Parser: TCustomStringParser); override;
    procedure Closed(_Parser: TCustomStringParser); override;

  end;

  TCustomStringParser = class

  strict private

  type

    TLocation = record

      CurrentLine: Int64;
      CurrentLineStart: Int64;

      LastElementLine: Int64;
      LastElementStart: Int64;
      LastLineStart: Int64;

      procedure Remember(_Cursor: Int64);

      function Line: Int64;
      function Column: Int64;
      function Position: Int64;

    end;

  const

    LOC_INITIAL: TLocation = (CurrentLine: 1; CurrentLineStart: 1; LastElementLine: 1; LastElementStart: 1; LastLineStart: 1);

  strict private

    FSource: String;
    FSrcLen: Int64;
    FCursor: Int64;
    FCursorStanding: TStanding;
    FElementStart: Int64;
    FRegionStart: Int64;

    FTerminated: Boolean;
    FNestedLevel: Word;
    FKeyWords: TKeyWordList;
    FRegions: TRegionList;

    FLocation: TLocation;

    function GetCursorKey(var _Value: TKeyWord): Boolean;
    function RegionActive: Boolean;

    procedure CheckUnterminated(_KeyType: TKeyType);
    procedure UpdateLocation;

    function GetRest: Int64;

    property NestedLevel: Word read FNestedLevel;

  private

    function IsCursorKey(const _KeyWord: TKeyWord): Boolean;

    property Regions: TRegionList read FRegions;

  protected

    { События для потомков }
    procedure InitParser; virtual;
    function ProcessRegions: Boolean;
    function ElementProcessingKey(_KeyWord: TKeyWord): Boolean; virtual;
    function ElementTerminatingKey(_KeyWord: TKeyWord): Boolean; virtual;
    procedure ProcessElement; virtual;
    procedure CheckSyntax(const _KeyWord: TKeyWord); virtual;
    procedure DoAfterKey(_KeyWord: TKeyWord); virtual;

  public

    constructor Create(const _Source: String);
    constructor CreateNested(_Master: TCustomStringParser);

    destructor Destroy; override;

    { События для потомков }
    procedure KeyEvent(const _KeyWord: TKeyWord); virtual;
    procedure MoveEvent; virtual;
    procedure ToggleElement(_KeyWord: TKeyWord); virtual;
    procedure ElementTerminatedEvent(_KeyWord: TKeyWord); virtual;

    { Методы и свойства для управления }
    procedure Move(_Incrementer: Int64 = 1);
    procedure Terminate;
    function ReadElement(_Trim: Boolean): String; virtual;
    procedure AddRegion(

        const _RegionClass: TRegionClass;
        const _OpeningKey: TKeyWord;
        const _ClosingKey: TKeyWord;
        const _Caption: String

    );
    function Nested: Boolean;

    (*****************************)
    (*                           *)
    (*   Главный рабочий метод   *)
    (*                           *)
    (*****************************)
    procedure Read;

    property Source: String read FSource;
    property SrcLen: Int64 read FSrcLen;
    property Cursor: Int64 read FCursor;
    property Rest: Int64 read GetRest;
    property CursorStanding: TStanding read FCursorStanding write FCursorStanding;
    property ElementStart: Int64 read FElementStart write FElementStart;
    property RegionStart: Int64 read FRegionStart write FRegionStart;
    property Terminated: Boolean read FTerminated;
    property Location: TLocation read FLocation write FLocation;
    property KeyWords: TKeyWordList read FKeyWords;

  end;

  EStringParserException = class(ECoreException);

const

  KWR_EMPTY:         TKeyWord = (KeyTypeInternal: Integer(ktNone);      StrValue: '';   KeyLength: 0           );
  KWR_SOURCE_END:    TKeyWord = (KeyTypeInternal: Integer(ktSourceEnd); StrValue: '';   KeyLength: 0           );
  KWR_LINE_END_CR:   TKeyWord = (KeyTypeInternal: Integer(ktLineEnd);   StrValue: CR;   KeyLength: Length(CR)  );
  KWR_LINE_END_LF:   TKeyWord = (KeyTypeInternal: Integer(ktLineEnd);   StrValue: LF;   KeyLength: Length(LF)  );
  KWR_LINE_END_CRLF: TKeyWord = (KeyTypeInternal: Integer(ktLineEnd);   StrValue: CRLF; KeyLength: Length(CRLF));

implementation

type

  TKeyWordHelper = record helper for TKeyWord

  private

    constructor Create(_KeyType: TKeyType; const _StrValue: String); overload;

    function GetKeyType: TKeyType;
    procedure SetKeyType(const _Value: TKeyType);

    property KeyType: TKeyType read GetKeyType write SetKeyType;

  end;

{$IFDEF DEBUG}
procedure CheckRegions(_Regions: TRegionList);
var
  SSA, SSB: TRegion;
begin

  for SSA in _Regions do
    for SSB in _Regions do
      if SSA <> SSB then
        if

            (not SSA.OpeningKey.Equal(KWR_EMPTY) and SSA.OpeningKey.Equal(SSB.OpeningKey)) or
            (not SSA.OpeningKey.Equal(KWR_EMPTY) and SSA.OpeningKey.Equal(SSB.ClosingKey)) or
            (not SSA.ClosingKey.Equal(KWR_EMPTY) and SSA.ClosingKey.Equal(SSB.OpeningKey)) or
            (not SSA.ClosingKey.Equal(KWR_EMPTY) and SSA.ClosingKey.Equal(SSB.ClosingKey))

        then raise ECoreException.Create(' regions setting is wrong. Some keys are intersected.');

end;
{$ENDIF}

{ TKeyWord }

constructor TKeyWord.Create(_KeyTypeInternal: Integer; const _StrValue: String);
begin

  KeyTypeInternal := _KeyTypeInternal;
  StrValue        := _StrValue;
  KeyLength       := Length(StrValue);

end;

function TKeyWord.Equal(_Value: TKeyWord): Boolean;
begin

  Result :=

      (_Value.KeyTypeInternal = KeyTypeInternal) and
      (_Value.StrValue        = StrValue       ) and
      (_Value.KeyLength       = KeyLength      );

end;

{ TRegion }

constructor TRegion.Create;
begin

  inherited Create;

  FOpeningKey := _OpeningKey;
  FClosingKey := _ClosingKey;
  FCaption    := _Caption;

end;

procedure TRegion.Open(_Parser: TCustomStringParser);
begin

  Opened(_Parser);

  with _Parser do begin

    Move(OpeningKey.KeyLength);
    RegionStart := _Parser.Cursor;

  end;

end;

procedure TRegion.Close(_Parser: TCustomStringParser);
begin

  with _Parser do begin

    Move(ClosingKey.KeyLength);
    Closed(_Parser);
    RegionStart := 0;
    Location.Remember(Cursor);

  end;

end;

procedure TRegion.CheckUnterminating;
begin
  raise EStringParserException.CreateFmt('Unterminated %s', [Caption]);
end;

function TRegion.CanOpen(_Parser: TCustomStringParser): Boolean;
begin
  Result := _Parser.IsCursorKey(OpeningKey);
end;

function TRegion.CanClose(_Parser: TCustomStringParser): Boolean;
begin
  Result := _Parser.IsCursorKey(ClosingKey);
end;

procedure TRegion.Opened(_Parser: TCustomStringParser);
begin
end;

procedure TRegion.Closed(_Parser: TCustomStringParser);
begin
end;

{ TRegionList }

function TRegionList.TryOpen(_Parser: TCustomStringParser): Boolean;
var
  Region: TRegion;
begin

  if not Active then

    for Region in Self do

      if Region.CanOpen(_Parser) then begin

        OpenRegion(_Parser, Region);
        Exit(True);

      end;
      
  Result := False;
  
end;

function TRegionList.TryClose(_Parser: TCustomStringParser): Boolean;
begin
  Result := Active and ActiveRegion.CanClose(_Parser);
  if Result then
    CloseRegion(_Parser);
end;

procedure TRegionList.OpenRegion(_Parser: TCustomStringParser; _Region: TRegion);
begin

  _Region.Open(_Parser);
  FActiveRegion := _Region;
  FActive       := True;

end;

procedure TRegionList.CloseRegion(_Parser: TCustomStringParser);
begin

  ActiveRegion.Close(_Parser);
  FActiveRegion := nil;
  FActive       := False;

end;

procedure TRegionList.CheckUnterminated;
begin
  if Active then
    FActiveRegion.CheckUnterminating;
end;

{ TBlock }

procedure TBlock.Opened(_Parser: TCustomStringParser);
begin
  inherited Opened(_Parser);
  _Parser.Move(OpeningKey.KeyLength);
end;

procedure TBlock.Closed(_Parser: TCustomStringParser);
begin

  inherited Closed(_Parser);

  with _Parser do begin

    CursorStanding := stAfter;
    ElementStart := 0;
    Location.Remember(Cursor + ClosingKey.KeyLength);

  end;

end;

{ TCustomStringParser.TLocation }

procedure TCustomStringParser.TLocation.Remember(_Cursor: Int64);
begin

  LastElementLine  := CurrentLine;
  LastLineStart    := CurrentLineStart;
  LastElementStart := _Cursor;

end;

function TCustomStringParser.TLocation.Line: Int64;
begin
  Result := LastElementLine;
end;

function TCustomStringParser.TLocation.Column: Int64;
begin
  Result := LastElementStart - LastLineStart + 1;
end;

function TCustomStringParser.TLocation.Position: Int64;
begin
  Result := LastElementStart;
end;

{ TCustomStringParser }

constructor TCustomStringParser.Create(const _Source: String);
begin

  inherited Create;

  FSource := _Source;
  FSrcLen := Length(_Source);

  FCursor   := 1;
  FLocation := LOC_INITIAL;

  InitParser;

  {$IFDEF DEBUG}
  CheckRegions(FRegions);
  {$ENDIF}

end;

constructor TCustomStringParser.CreateNested(_Master: TCustomStringParser);
begin

  inherited Create;

  FSource := _Master.Source;
  FSrcLen := Length(Source);

  FCursor      := _Master.Cursor;
  FLocation    := _Master.Location;
  FNestedLevel := _Master.NestedLevel + 1;

  InitParser;

end;

destructor TCustomStringParser.Destroy;
begin

  FreeAndNil(FRegions);
  FreeAndNil(FKeyWords);

  inherited Destroy;

end;

function TCustomStringParser.GetCursorKey(var _Value: TKeyWord): Boolean;
var
  KeyWord: TKeyWord;
begin

  for KeyWord in FKeyWords do

    if IsCursorKey(KeyWord) then begin

      _Value := KeyWord;
      Exit(True);

    end;

  Result := False;

end;

function TCustomStringParser.RegionActive: Boolean;
begin
  Result := Regions.Active;
end;

procedure TCustomStringParser.CheckUnterminated(_KeyType: TKeyType);
begin

  if (_KeyType = ktSourceEnd) then begin

    // Sections.CheckUnterminated;
    // Blocks.CheckUnterminated;
    Regions.CheckUnterminated;

  end;

end;

procedure TCustomStringParser.UpdateLocation;
begin

  if

      (Copy(Source, Cursor - 1, 2) <> CRLF) and (

        (Copy(Source, Cursor - 2, 2) = CRLF) or
        CharInSet(Source[Cursor - 1], [CR, LF])

      )

  then begin

    Inc(FLocation.CurrentLine);
    FLocation.CurrentLineStart := Cursor;

  end;

  if CursorStanding = stBefore then
    Location.Remember(Cursor);

end;

function TCustomStringParser.GetRest: Int64;
begin
  Result := SrcLen - Cursor + 1;
end;

function TCustomStringParser.IsCursorKey(const _KeyWord: TKeyWord): Boolean;
begin
  with _KeyWord do
    Result := (KeyType <> ktNone) and (StrValue = Copy(Source, Cursor, KeyLength));
end;

function TCustomStringParser.ProcessRegions: Boolean;
begin
  with Regions do 
    Result := TryClose(Self) or TryOpen(Self);    
end;

procedure TCustomStringParser.InitParser;
begin

  FKeyWords := TKeyWordList.Create;
  FRegions  := TRegionList. Create;

  with KeyWords do begin

    Add(KWR_LINE_END_CRLF);
    Add(KWR_LINE_END_LF  );
    Add(KWR_LINE_END_CR  );

  end;

end;

function TCustomStringParser.ElementProcessingKey(_KeyWord: TKeyWord): Boolean;
begin
  Result := False;
end;

function TCustomStringParser.ElementTerminatingKey(_KeyWord: TKeyWord): Boolean;
begin
  Result := False;
end;

procedure TCustomStringParser.ProcessElement;
begin

  CursorStanding := stAfter;
  ElementStart   := 0;
  Location.Remember(Cursor);

end;

procedure TCustomStringParser.CheckSyntax(const _KeyWord: TKeyWord);
begin

  if _KeyWord.Equal(KWR_EMPTY) then
    Location.Remember(Cursor);

  CheckUnterminated(_KeyWord.KeyType);

end;

procedure TCustomStringParser.DoAfterKey(_KeyWord: TKeyWord);
begin
end;

procedure TCustomStringParser.KeyEvent(const _KeyWord: TKeyWord);

{  Имеем четыре события:                                                }
(* ElementBefore      ElementInside      ElementAfter       NexElement *)
(* X__________________X__________________X__________________X          *)
(*   spaces, comments         body         spaces, comments            *)

begin

  CheckSyntax(_KeyWord);

  { Обработка (считывание) по признаку завершения тела. Например, пробел для непрерывных элементов. }
  if (CursorStanding = stInside) and ElementProcessingKey(_KeyWord) then 
    ProcessElement;

  { Завершение. Элемент закончен вместе со последующим пространством. }
  if ElementTerminatingKey(_KeyWord) then begin

    { В случае пустого значения элемента мы окажемся здесь. Обработка пустого элемента. }
    if CursorStanding < stAfter then
      ProcessElement;

    { Переключение абстрактного типа элемента. }
    if _KeyWord.KeyType <> ktSourceEnd then
      ToggleElement(_KeyWord);

    { Событие полного завершения элемента. }
    ElementTerminatedEvent(_KeyWord);

  end;

end;

procedure TCustomStringParser.MoveEvent;
begin

  if CursorStanding = stBefore then begin

    CursorStanding := stInside;
    ElementStart := Cursor;
    Location.Remember(Cursor);

  end;

  if not RegionActive then
    CheckSyntax(KWR_EMPTY);

end;

procedure TCustomStringParser.ToggleElement(_KeyWord: TKeyWord);
begin

  CursorStanding := stBefore;
  ElementStart   := 0;
  Location.Remember(Cursor + _KeyWord.KeyLength);

end;

procedure TCustomStringParser.ElementTerminatedEvent(_KeyWord: TKeyWord);
begin
end;

function TCustomStringParser.Nested: Boolean;
begin
  Result := NestedLevel > 0;
end;

procedure TCustomStringParser.Move(_Incrementer: Int64);
begin
  if not Terminated then
    Inc(FCursor, _Incrementer);
end;

procedure TCustomStringParser.Terminate;
begin
  FTerminated := True;
end;

function TCustomStringParser.ReadElement(_Trim: Boolean): String;
begin

  if ElementStart > 0 then

    if _Trim then
      Result := Trim(Copy(Source, ElementStart, Cursor - ElementStart))
    else
      Result := Copy(Source, ElementStart, Cursor - ElementStart)

  else Result := '';

end;

procedure TCustomStringParser.AddRegion;
begin
  Regions.Add(_RegionClass.Create(_OpeningKey, _ClosingKey, _Caption));
end;

procedure TCustomStringParser.Read;
var
  CursorKey: TKeyWord;
begin

  try

    while (Rest > 0) and not FTerminated do begin

      if not ProcessRegions then

        if not RegionActive and GetCursorKey(CursorKey) then begin

          KeyEvent(CursorKey);
          DoAfterKey(CursorKey);
          Move(CursorKey.KeyLength);

        end else begin

          MoveEvent;
          Move;

        end;

      UpdateLocation;

    end;

    KeyEvent(KWR_SOURCE_END);

  except

    on E: Exception do

      if Nested then raise
      else

        raise ExceptClass(E.ClassType).CreateFmt('%s. Line: %d, Column: %d, Position: %d', [

            E.Message,
            { Локация должна полностью совпадать с Notepad и Notepad++. }
            Location.Line,
            Location.Column,
            Location.Position

        ]);

  end;

end;

{ TKeyWordHelper }

constructor TKeyWordHelper.Create(_KeyType: TKeyType; const _StrValue: String);
begin
  Create(Integer(_KeyType), _StrValue);
end;

function TKeyWordHelper.GetKeyType: TKeyType;
begin
  Result := TKeyType(KeyTypeInternal);
end;

procedure TKeyWordHelper.SetKeyType(const _Value: TKeyType);
begin
  if Integer(_Value) <> KeyTypeInternal then
    KeyTypeInternal := Integer(_Value);
end;

end.
