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
  { TODO 3 -oVasilyevSM -cTCustomStringParser: Block (Nested structure) }
  // Element (Item)
  // Region

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
    procedure RegionOpened(_Parser: TCustomStringParser); virtual;
    procedure RegionClosed(_Parser: TCustomStringParser); virtual;

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

    procedure OpenRegion(_Parser: TCustomStringParser; _Region: TRegion);
    procedure CloseRegion(_Parser: TCustomStringParser);
    procedure CheckTerminated;

    property Active: Boolean read FActive;
    property ActiveRegion: TRegion read FActiveRegion;

  end;

  TLocation = record

    CurrentLine: Int64;
    CurrentLineStart: Int64;

    LastItemLine: Int64;
    LastLineStart: Int64;
    LastItemStart: Int64;

    procedure Remember(_Cursor: Int64);

    function Line: Int64;
    function Column: Int64;
    function Position: Int64;

  end;

  {

    НЕ проверяет синтаксис. Дело потомков.

  }
  TCustomStringParser = class

  strict private

    FSource: String;
    FSrcLen: Int64;
    FCursor: Int64;
    FItemStanding: TStanding;
    FItemStart: Int64;
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
    function ItemProcessingKey(_KeyWord: TKeyWord): Boolean; virtual;
    function ItemTerminatingKey(_KeyWord: TKeyWord): Boolean; virtual;
    procedure ProcessItem; virtual;
    procedure CheckSyntax(const _KeyWord: TKeyWord); virtual;
    procedure DoAfterKey(_KeyWord: TKeyWord); virtual;

  public

    constructor Create(const _Source: String);
    constructor CreateNested(_Master: TCustomStringParser);

    destructor Destroy; override;

    { События для потомков }
    procedure KeyEvent(const _KeyWord: TKeyWord); virtual;
    procedure MoveEvent; virtual;
    procedure ToggleItem(_KeyWord: TKeyWord); virtual;

    { Методы и свойства для управления }
    function Nested: Boolean;
    procedure Move(_Incrementer: Int64 = 1);
    procedure Terminate;
    function ReadItem(_Trim: Boolean): String; virtual;
    procedure AddRegion(

        const _RegionClass: TRegionClass;
        const _OpeningKey: TKeyWord;
        const _ClosingKey: TKeyWord;
        const _Caption: String

    );

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
    property ItemStanding: TStanding read FItemStanding write FItemStanding;
    property ItemStart: Int64 read FItemStart write FItemStart;
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

  LOC_INITIAL: TLocation = (CurrentLine: 1; CurrentLineStart: 1; LastItemLine: 1; LastLineStart: 1; LastItemStart: 1);

implementation

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

function TKeyWordHelper.TypeInSet(const _Set: TKeyTypes): Boolean;
begin
  Result := KeyType in _Set;
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

  RegionOpened(_Parser);

  with _Parser do begin

    Move(OpeningKey.KeyLength);
    RegionStart := _Parser.Cursor;

  end;

end;

procedure TRegion.Close(_Parser: TCustomStringParser);
begin

  with _Parser do begin

    Move(ClosingKey.KeyLength);
    RegionClosed(_Parser);
    RegionStart := 0;

  end;

end;

procedure TRegion.CheckUnterminating;
begin
  if not ClosingKey.Equal(KWR_EMPTY) then
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

procedure TRegion.RegionOpened(_Parser: TCustomStringParser);
begin
end;

procedure TRegion.RegionClosed(_Parser: TCustomStringParser);
begin
end;

{ TRegionList }

procedure TRegionList.CheckTerminated;
begin
  if Active then
    FActiveRegion.CheckUnterminating;
end;

procedure TRegionList.CloseRegion(_Parser: TCustomStringParser);
begin

  ActiveRegion.Close(_Parser);
  FActiveRegion := nil;
  FActive       := False;

end;

procedure TRegionList.OpenRegion(_Parser: TCustomStringParser; _Region: TRegion);
begin

  _Region.Open(_Parser);
  FActiveRegion := _Region;
  FActive       := True;

end;

{ TLocation }

procedure TLocation.Remember(_Cursor: Int64);
begin

  LastItemLine  := CurrentLine;
  LastLineStart := CurrentLineStart;
  LastItemStart := _Cursor;

end;

function TLocation.Line: Int64;
begin
  Result := LastItemLine;
end;

function TLocation.Column: Int64;
begin
  Result := LastItemStart - LastLineStart + 1;
end;

function TLocation.Position: Int64;
begin
  Result := LastItemStart;
end;

{ TCustomStringParser }

procedure TCustomStringParser.CheckSyntax(const _KeyWord: TKeyWord);
begin
  CheckUnterminated(_KeyWord.KeyType);
end;

procedure TCustomStringParser.CheckUnterminated(_KeyType: TKeyType);
begin

  if (_KeyType = ktSourceEnd) then begin

    // Sections.CheckTerminated;
    // Blocks.CheckTerminated;
    Regions.CheckTerminated;

  end;

end;

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

procedure TCustomStringParser.DoAfterKey(_KeyWord: TKeyWord);
begin
end;

function TCustomStringParser.GetRest: Int64;
begin
  Result := SrcLen - Cursor + 1;
end;

procedure TCustomStringParser.ToggleItem(_KeyWord: TKeyWord);
begin
  ItemStanding := stBefore;
  ItemStart := 0;
  Location.Remember(Cursor + _KeyWord.KeyLength);
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

  if ItemStanding = stBefore then
    Location.Remember(Cursor);

end;

function TCustomStringParser.IsCursorKey(const _KeyWord: TKeyWord): Boolean;
begin
  with _KeyWord do
    Result := (KeyType <> ktNone) and (StrValue = Copy(Source, Cursor, KeyLength));
end;

function TCustomStringParser.ItemProcessingKey(_KeyWord: TKeyWord): Boolean;
begin
  Result := False;
end;

function TCustomStringParser.ItemTerminatingKey(_KeyWord: TKeyWord): Boolean;
begin
  Result := False;
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

procedure TCustomStringParser.KeyEvent(const _KeyWord: TKeyWord);
begin

  CheckSyntax(_KeyWord);

  { Имеем четыре события:                              }
  (*  ItemBefore   ItemInside   ItemAfter    NexItem  *)
  (*  X____________X____________X____________X        *)
  (*     spc comm       body       spc comm           *)

  { Пустое значение допустимо для некоторых }
  if

      (ItemStanding = stInside) and
      ItemProcessingKey(_KeyWord)

  then begin

    ProcessItem;

  end;

  if ItemTerminatingKey(_KeyWord) then begin

    if ItemStanding < stAfter then
      ProcessItem;

    ToggleItem(_KeyWord);

  end;

end;

procedure TCustomStringParser.MoveEvent;
begin

  if not RegionActive then begin

    if ItemStanding = stBefore then begin

      ItemStanding := stInside;
      ItemStart := Cursor;
      FLocation.Remember(Cursor);

    end;

    CheckSyntax(KWR_EMPTY);

  end;

end;

function TCustomStringParser.Nested: Boolean;
begin
  Result := NestedLevel > 0;
end;

procedure TCustomStringParser.ProcessItem;
begin

  ItemStanding := stAfter;
  ItemStart    := 0;
  FLocation.Remember(Cursor);

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

function TCustomStringParser.ReadItem(_Trim: Boolean): String;
begin

  if ItemStart > 0 then

    if _Trim then
      Result := Trim(Copy(Source, ItemStart, Cursor - ItemStart))
    else
      Result := Copy(Source, ItemStart, Cursor - ItemStart)

  else Result := '';

end;

function TCustomStringParser.RegionActive: Boolean;
begin
  Result := Regions.Active;
end;

procedure TCustomStringParser.AddRegion;
begin
  Regions.Add(_RegionClass.Create(_OpeningKey, _ClosingKey, _Caption));
end;

procedure TCustomStringParser.Read;

  function  _ProcessRegions: Boolean;
  var
    Region: TRegion;
  begin

    { TODO 1 -oVasilyevSM -cGeneral: В класс }
    Result := False;

    with Regions do

      if Active then

        if ActiveRegion.CanClose(Self) then begin

          CloseRegion(Self);
          Result := True;

        end else

      else

        for Region in Regions do

          if Region.CanOpen(Self) then begin

            OpenRegion(Self, Region);
            Result := True;
            Break;

          end;

  end;

var
  CursorKey: TKeyWord;
begin

  { Имеем четыре события:                              }
  (*  ItemBefore   ItemInside   ItemAfter    NexItem  *)
  (*  X____________X____________X____________X        *)
  (*     spc comm       body       spc comm           *)

  try

    while (Cursor <= SrcLen) and not FTerminated do begin

      if not _ProcessRegions then

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
            { Совпадает с Блокнотом и Notepad++ }
            Location.Line,
            Location.Column,
            Location.Position

        ]);

  end;

end;

end.
