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
  SysUtils, Generics.Collections, Windows,
  { LiberSynth }
  uConsts, uTypes, uCore, uDataUtils;

type

  { TODO 5 -oVasilyevSM -cuCustomStringParser: Section }

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
    FExecuted: Boolean;
    FCancelToggling: Boolean;

  private

    constructor Create(

        const _OpeningKey: TKeyWord;
        const _ClosingKey: TKeyWord;
        const _Caption: String

    );

    property Caption: String read FCaption;

  protected

    function CanOpen(_Parser: TCustomStringParser): Boolean; virtual;
    function CanClose(_Parser: TCustomStringParser): Boolean; virtual;
    procedure Opened(_Parser: TCustomStringParser); virtual;
    procedure Closed(_Parser: TCustomStringParser); virtual;
    procedure Execute(_Parser: TCustomStringParser; var _Handled: Boolean); virtual;
    procedure CheckUnterminated; dynamic;

    property CancelToggling: Boolean read FCancelToggling write FCancelToggling;

  public

    property OpeningKey: TKeyWord read FOpeningKey write FClosingKey;
    property ClosingKey: TKeyWord read FClosingKey write FClosingKey;
    property Executed: Boolean read FExecuted write FExecuted;

  end;

  TRegionClass = class of TRegion;

  TRegionList = class(TObjectList<TRegion>)

  strict private

    FActive: Boolean;
    FActiveRegion: TRegion;

    function GetOpeningRegion(_Parser: TCustomStringParser; var _ActiveRegion: TRegion): Boolean;

  private

    function TryOpen(_Parser: TCustomStringParser): Boolean;
    function TryClose(_Parser: TCustomStringParser; var _ClosingKey: TKeyWord): Boolean;
    procedure CheckUnterminated;

    property Active: Boolean read FActive;
    property ActiveRegion: TRegion read FActiveRegion;

  end;

  TBlock = class(TRegion)
    { На данный момент повода здесь что-то добавить нет. }
  end;

  TCustomStringParser = class abstract (TIntfObject)

  strict private

  type

    TReadEvent = procedure (InternalRead: TObjProc; Nested: Boolean) of object;
    TCursorEvent = procedure (Cursor: Int64) of object;

  strict private

    FSource: String;
    FCursor: Int64;
    FSrcLen: Int64;
    FCursorStanding: TStanding;
    FElementStart: Int64;
    FRegionStart: Int64;

    FTerminated: Boolean;
    FNestedLevel: Word;
    FKeyWords: TKeyWordList;
    FRegions: TRegionList;

    FOnRead: TReadEvent;
    FOnCheckPoint: TCursorEvent;
    FOnDestroy: TObjProc;

    (*****************************)
    (*                           *)
    (*   Главный рабочий метод   *)
    (*                           *)
    (*****************************)
    procedure InternalRead;
    function GetCursorKey(var _Value: TKeyWord): Boolean; inline;
    procedure ToggleStanding(_To: TStanding);
    function CheckRegions: Boolean;
    function RegionActive: Boolean; inline;
    procedure CheckPoint(_Cursor: Int64);
    procedure DoSyntaxCheck(const _KeyWord: TKeyWord);
    procedure CheckUnterminated(_KeyType: TKeyType);
    procedure DoOnCheckPoint(_Cursor: Int64);
    procedure DoOnDestroy;

    function GetEof: Boolean;
    function GetRest: Int64; inline;

    procedure SetOnRead(const _Value: TReadEvent);
    procedure SetOnCheckPoint(const _Value: TCursorEvent);
    procedure SetOnDestroy(const _Value: TObjProc);

    property NestedLevel: Word read FNestedLevel;

  private

    function IsCursorKey(const _KeyWord: TKeyWord): Boolean;

    property Regions: TRegionList read FRegions;

  protected

    { События для потомков }
    procedure InitParser; virtual;
    procedure ToggleElement(_KeyWord: TKeyWord); virtual;
    function ElementProcessingKey(_KeyWord: TKeyWord): Boolean; virtual;
    function ElementTerminatingKey(_KeyWord: TKeyWord): Boolean; virtual;
    procedure ProcessElement; virtual;
    function ReadElement(_Trim: Boolean): String; virtual;
    procedure ElementTerminated(_KeyWord: TKeyWord); virtual;
    procedure AddRegion(const _RegionClass: TRegionClass; const _OpeningKey, _ClosingKey: TKeyWord; const _Caption: String);
    function ExecuteRegion: Boolean;
    procedure RetrieveControl(_Master: TCustomStringParser);
    procedure CheckSyntax(const _KeyWord: TKeyWord); virtual;

    property KeyWords: TKeyWordList read FKeyWords;
    property OnRead: TReadEvent read FOnRead write SetOnRead;
    property OnCheckPoint: TCursorEvent read FOnCheckPoint write SetOnCheckPoint;
    property OnDestroy: TObjProc read FOnDestroy write SetOnDestroy;

  public

    constructor Create(const _Source: String); virtual;
    constructor CreateNested(_Master: TCustomStringParser); virtual;

    destructor Destroy; override;

    { События для потомков }
    procedure KeyEvent(const _KeyWord: TKeyWord); virtual;
    procedure MoveEvent; virtual;

    { Методы и свойства для управления }
    procedure Move(_Incrementer: Int64 = 1); inline;
    procedure Terminate;
    function Nested: Boolean;

    (* Основной внешний рабочий метод *)
    procedure Read;

    property Source: String read FSource;
    property Cursor: Int64 read FCursor;
    property SrcLen: Int64 read FSrcLen;
    property Eof: Boolean read GetEof;
    property Rest: Int64 read GetRest;
    property CursorStanding: TStanding read FCursorStanding;
    property ElementStart: Int64 read FElementStart;
    property RegionStart: Int64 read FRegionStart;
    property Terminated: Boolean read FTerminated;

  end;

  TCustomStringParserClass = class of TCustomStringParser;

  TLocation = record

    Line: Int64;
    Column: Int64;
    Position: Int64;

    constructor Create(_Line, _Column, _Position: Int64);

  end;

  TLocator = class

  strict private

    FParser: TCustomStringParser;
    FNativeException: Boolean;
    FLastElementStart: Int64;

    procedure ParserOnRead(_InternalRead: TObjProc; _Nested: Boolean);
    procedure ParserOnCheckPoint(_Cursor: Int64);
    procedure ParserOnDestroy;

    function Location: TLocation;

  public

    constructor Create(_Parser: TCustomStringParser; _NativeException: Boolean = True);
    destructor Destroy; override;

  end;

  EStringParserException = class(ECoreException)

  strict private

    FCheckPoint: Boolean;

  private

    property CheckPoint: Boolean read FCheckPoint;

  public

    constructor Create(const _Message: String; _CheckPoint: Boolean = True);
    constructor CreateFmt(const _Message: String; const _Args: array of const; _CheckPoint: Boolean = True);

  end;

  ELocatedException = class(ECoreException)

  strict private

    FInitExceptionClass: ExceptClass;
    FInitMessage: String;
    FLocation: TLocation;

  private

    constructor Create(

        _InitExceptionClass: ExceptClass;
        const _InitMessage: String;
        _Location: TLocation

    );

  end;

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
procedure _ValidateRegions(_Regions: TRegionList; _KeyWords: TKeyWordList);
var
  SSA, SSB: TRegion;
  KW: TKeyWord;
  i, j: Integer;
begin

  for SSA in _Regions do
    for SSB in _Regions do
      if SSA <> SSB then
        if

            (not SSA.OpeningKey.Equal(KWR_EMPTY) and SSA.OpeningKey.Equal(SSB.OpeningKey)) or
            (not SSA.OpeningKey.Equal(KWR_EMPTY) and SSA.OpeningKey.Equal(SSB.ClosingKey)) or
            (not SSA.ClosingKey.Equal(KWR_EMPTY) and SSA.ClosingKey.Equal(SSB.OpeningKey)) or
            (not SSA.ClosingKey.Equal(KWR_EMPTY) and SSA.ClosingKey.Equal(SSB.ClosingKey))

        then raise ECoreException.Create('Setting is wrong. Some block''s or region''s keys are intersected.');

  for i := 0 to _KeyWords.Count - 1 do
    for j := 0 to _KeyWords.Count - 1 do
      if i <> j then
        if _KeyWords[i].Equal(_KeyWords[j]) then
          raise ECoreException.Create('Setting is wrong. Some keys are intersected.');

  for SSA in _Regions do
    for KW in _KeyWords do
      if KW.Equal(SSA.OpeningKey) then
        raise ECoreException.Create('Setting is wrong. Some keys are intersected with region''s opening key.');

  { Закрывающие ключи блоков будут пересекаться с обычными, потому что блок закрывается мастером и вложенную обработку
    надо прекращать по отдельному ключу. }

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

procedure TRegion.CheckUnterminated;
begin
  raise EStringParserException.CreateFmt('Unterminated %s', [Caption], False);
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
  Executed := False;
end;

procedure TRegion.Closed(_Parser: TCustomStringParser);
begin
  Executed := False;
end;

procedure TRegion.Execute(_Parser: TCustomStringParser; var _Handled: Boolean);
begin
  _Handled := False;
  Executed := True;
end;

{ TRegionList }

function TRegionList.GetOpeningRegion(_Parser: TCustomStringParser; var _ActiveRegion: TRegion): Boolean;
var
  i, L: Integer;
  IA: TIntegerarray;
begin

  { Тут такая история. Есть два региона, один открывается по '(*', другой - по '('. При пробежке простым циклом, когда
    впереди '(*' выиграет первый попавшийся из них - с ключом '('. Но он - не тот, кто должен открыться по '(*'. }

  SetLength(IA, 0);
  for i := 0 to Count - 1 do
    if Items[i].CanOpen(_Parser) then
      AddToIntArray(IA, i);

  Result := Length(IA) > 0;
  if Result then begin

    L := 0;
    for i := Low(IA) to High(IA) do
      if Items[IA[i]].OpeningKey.KeyLength > L then
        _ActiveRegion := Items[IA[i]];

  end;

end;

function TRegionList.TryOpen(_Parser: TCustomStringParser): Boolean;
var
  Region: TRegion;
begin

  Result := not Active and GetOpeningRegion(_Parser, Region);
  if Result then begin

    Region.Opened(_Parser);
    FActiveRegion := Region;
    FActive := True;

  end;

end;

function TRegionList.TryClose(_Parser: TCustomStringParser; var _ClosingKey: TKeyWord): Boolean;
begin

  Result := Active and ActiveRegion.CanClose(_Parser);

  if Result then begin

    _ClosingKey := ActiveRegion.ClosingKey;
    ActiveRegion.Closed(_Parser);
    FActiveRegion := nil;
    FActive := False;

  end;

end;

procedure TRegionList.CheckUnterminated;
begin
  if Active then
    FActiveRegion.CheckUnterminated;
end;

{ TCustomStringParser }

constructor TCustomStringParser.Create(const _Source: String);
begin

  inherited Create;

  FSource := _Source;
  FSrcLen := Length(_Source);
  FCursor   := 1;

  InitParser;

  {$IFDEF DEBUG}
  _ValidateRegions(Regions, KeyWords);
  {$ENDIF}

end;

constructor TCustomStringParser.CreateNested(_Master: TCustomStringParser);
begin

  inherited Create;

  FSource := _Master.Source;
  FSrcLen := Length(Source);

  FCursor      := _Master.Cursor;
  FNestedLevel := _Master.NestedLevel + 1;

  InitParser;

end;

destructor TCustomStringParser.Destroy;
begin

  DoOnDestroy;

  FreeAndNil(FRegions);
  FreeAndNil(FKeyWords);

  FOnRead       := nil;
  FOnCheckPoint := nil;
  FOnDestroy    := nil;

  inherited Destroy;

end;

procedure TCustomStringParser.InternalRead;

(*                   Имеем три точки переключения CursorStanding:                   *)
(*                                                                                  *)
(* Before              Inside              After               Before (NextElement) *)
(* 3___________________1___________________2___________________3___________________ *)
(*   spaces, comments          body          spaces, comments          body         *)
(*                                                                                  *)
(* ToggleElement       MoveEvent           ProcessElement      ToggleElement        *)
(* ToggleElement       RegionOpened        after RegionExecute ToggleElement        *)
(*                                                                                  *)
(*        Но! Регион - комментарий переключает только After в Before на Close       *)

var
  CursorKey: TKeyWord;
begin

  while not Eof and not FTerminated do begin

    if not CheckRegions then

      if RegionActive then begin

        if not ExecuteRegion then
          Move;

      end else if not RegionActive and GetCursorKey(CursorKey) then begin

        KeyEvent(CursorKey);
        Move(CursorKey.KeyLength);

      end else begin

        MoveEvent;
        Move;

      end;

  end;

  KeyEvent(KWR_SOURCE_END);
  Terminate;

end;

function TCustomStringParser.GetCursorKey(var _Value: TKeyWord): Boolean;
var
  KeyWord: TKeyWord;
begin

  for KeyWord in KeyWords do

    if IsCursorKey(KeyWord) then begin

      _Value := KeyWord;
      Exit(True);

    end;

  Result := False;

end;

procedure TCustomStringParser.ToggleStanding(_To: TStanding);
begin

  FCursorStanding := _To;

  if _To = stInside then FElementStart := Cursor
  else FElementStart := 0;

  if (CursorStanding > stBefore) and not Eof then
    CheckPoint(Cursor);

end;

function TCustomStringParser.CheckRegions: Boolean;
var
  ClosingKey: TKeyWord;
begin

  Result := Regions.TryClose(Self, ClosingKey);
  if Result then begin

    { Move после переключения, потому что ключ не должен войти в регион. Конец перед ключом. }
    Move(ClosingKey.KeyLength);
    FRegionStart := 0;
    Exit;

  end;

  Result := Regions.TryOpen(Self);
  if Result then begin

    with Regions.ActiveRegion do begin

      { Move до переключения, потому что ключ не должен войти в регион. Начало после ключа. }
      Move(OpeningKey.KeyLength);
      if not CancelToggling then
        ToggleStanding(stInside); { ТОЧКА ПЕРЕКЛЮЧЕНИЯ 1 (RegionOpened) }

    end;

    FRegionStart := Cursor;

  end;

end;

function TCustomStringParser.RegionActive: Boolean;
begin
  Result := Regions.Active;
end;

procedure TCustomStringParser.CheckPoint(_Cursor: Int64);
begin
  DoOnCheckPoint(_Cursor);
end;

procedure TCustomStringParser.DoSyntaxCheck(const _KeyWord: TKeyWord);
begin

  try

    CheckSyntax(_KeyWord);

  except

    on E: EStringParserException do begin

      if E.CheckPoint then
        CheckPoint(Cursor);
       raise;

    end;

  else
    CheckPoint(Cursor);
    raise;
  end;

end;

procedure TCustomStringParser.CheckUnterminated(_KeyType: TKeyType);
begin

  if (_KeyType = ktSourceEnd) then begin

    { Sections.CheckUnterminated; }
    Regions.CheckUnterminated;

  end;

end;

procedure TCustomStringParser.DoOnCheckPoint(_Cursor: Int64);
begin
  if Assigned(FOnCheckPoint) then
    FOnCheckPoint(_Cursor);
end;

procedure TCustomStringParser.DoOnDestroy;
begin
  if Assigned(FOnDestroy) then
    FOnDestroy;
end;

function TCustomStringParser.GetEof: Boolean;
begin
  Result := Cursor > SrcLen;
end;

function TCustomStringParser.GetRest: Int64;
begin
  Result := SrcLen - Cursor + 1;
end;

procedure TCustomStringParser.SetOnRead(const _Value: TReadEvent);
begin
  if Assigned(FOnRead) and Assigned(_Value) then
    raise EStringParserException.Create('Multiple signing to an exclusive event.');
  FOnRead := _Value;
end;

procedure TCustomStringParser.SetOnCheckPoint(const _Value: TCursorEvent);
begin
  if Assigned(FOnCheckPoint) and Assigned(_Value) then
    raise EStringParserException.Create('Multiple signing to an exclusive event.');
  FOnCheckPoint := _Value;
end;

procedure TCustomStringParser.SetOnDestroy(const _Value: TObjProc);
begin
  if Assigned(FOnDestroy) and Assigned(_Value) then
    raise EStringParserException.Create('Multiple signing to an exclusive event.');
  FOnDestroy := _Value;
end;

function TCustomStringParser.IsCursorKey(const _KeyWord: TKeyWord): Boolean;
begin
  with _KeyWord do
    Result := (KeyType <> ktNone) and (StrValue = Copy(Source, Cursor, KeyLength));
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

procedure TCustomStringParser.ToggleElement(_KeyWord: TKeyWord);
begin
  ToggleStanding(stBefore); { ТОЧКА ПЕРЕКЛЮЧЕНИЯ 3 (ToggleElement) }
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
  ToggleStanding(stAfter); { ТОЧКА ПЕРЕКЛЮЧЕНИЯ 2 (ProcessElement) }
end;

function TCustomStringParser.ReadElement(_Trim: Boolean): String;
begin

  if ElementStart > 0 then

    if _Trim then
      { Все SysUtils.Trim обрезают все, что <= ' '. Все табы, ритерны итд. }
      Result := Trim(Copy(Source, ElementStart, Cursor - ElementStart))
    else
      Result := Copy(Source, ElementStart, Cursor - ElementStart)

  else Result := '';

end;

procedure TCustomStringParser.ElementTerminated(_KeyWord: TKeyWord);
begin
end;

procedure TCustomStringParser.AddRegion;
begin
  Regions.Add(_RegionClass.Create(_OpeningKey, _ClosingKey, _Caption));
end;

function TCustomStringParser.ExecuteRegion: Boolean;
begin

  with Regions.ActiveRegion do

    if not Executed then

      Regions.ActiveRegion.Execute(Self, Result)

    else Result := False;

  if Result and not Regions.ActiveRegion.CancelToggling then begin

    ToggleStanding(stAfter); { ТОЧКА ПЕРЕКЛЮЧЕНИЯ 2 (after RegionExecute) }
    FRegionStart := 0;

  end;

end;

procedure TCustomStringParser.RetrieveControl(_Master: TCustomStringParser);
begin
  CheckPoint(_Master.Cursor);
  _Master.Move(Cursor - _Master.Cursor);
end;

procedure TCustomStringParser.CheckSyntax(const _KeyWord: TKeyWord);
begin
  CheckUnterminated(_KeyWord.KeyType);
end;

procedure TCustomStringParser.KeyEvent(const _KeyWord: TKeyWord);
begin

  DoSyntaxCheck(_KeyWord);

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
    ElementTerminated(_KeyWord);

  end;

end;

procedure TCustomStringParser.MoveEvent;
begin

  if not RegionActive then begin

    if CursorStanding = stBefore then
      ToggleStanding(stInside); { ТОЧКА ПЕРЕКЛЮЧЕНИЯ 1 (MoveEvent) }

    DoSyntaxCheck(KWR_EMPTY);

  end;

end;

procedure TCustomStringParser.Move(_Incrementer: Int64);
begin

  {$IFDEF DEBUG}
  { Помогает ошибки найти. }
  if (_Incrementer < 1) and not Eof then
    raise EStringParserException.Create('Back moving.');
  {$ENDIF}

  if not Terminated then
    Inc(FCursor, _Incrementer);

end;

procedure TCustomStringParser.Terminate;
begin

  FTerminated   := True;
  FOnRead       := nil;
  FOnCheckPoint := nil;

end;

function TCustomStringParser.Nested: Boolean;
begin
  Result := NestedLevel > 0;
end;

procedure TCustomStringParser.Read;
begin
  if Assigned(FOnRead) then FOnRead(InternalRead, Nested)
  else InternalRead;
end;

{ TLocation }

constructor TLocation.Create(_Line, _Column, _Position: Int64);
begin

  Line     := _Line;
  Column   := _Column;
  Position := _Position;

end;

{ TLocator }

constructor TLocator.Create(_Parser: TCustomStringParser; _NativeException: Boolean);
begin

  inherited Create;

  FParser           := _Parser;
  FNativeException  := _NativeException;
  FLastElementStart := 1;

  with FParser do begin

    OnRead       := ParserOnRead;
    OnCheckPoint := ParserOnCheckPoint;
    OnDestroy    := ParserOnDestroy;

  end;

end;

destructor TLocator.Destroy;
begin

  if Assigned(FParser) then begin

    if not FParser.Terminated then
      raise EStringParserException.Create('Unexpected events host destroying.');

    with FParser do begin

      OnRead       := nil;
      OnCheckPoint := nil;
      OnDestroy    := nil;

    end;

  end;

  inherited Destroy;

end;

procedure TLocator.ParserOnRead(_InternalRead: TObjProc; _Nested: Boolean);
begin

  try

    _InternalRead;

  except

    on E: Exception do begin

      if _Nested then raise
      else

        if FNativeException then

          { Локация должна полностью совпадать с Notepad и Notepad++. }
          with Location do
            raise ExceptClass(E.ClassType).CreateFmt('%s. Line: %d, Column: %d, Position: %d', [
                E.Message, Line, Column, Position])

        else raise ELocatedException.Create(ExceptClass(E.ClassType), E.Message, Location);

    end;

  end;

end;

procedure TLocator.ParserOnCheckPoint(_Cursor: Int64);
begin
  FLastElementStart := _Cursor;
end;

procedure TLocator.ParserOnDestroy;
begin
  FParser := nil;
end;

function TLocator.Location: TLocation;
var
  i, LineStart: Int64;
  Source: String;
begin

  Result.Position := FLastElementStart;
  Result.Line := 1;
  LineStart := 1;

  Source := FParser.Source;
  i := 2;
  while i <= Result.Position do begin

    if

        CharInSet(Source[i - 1], [CR, LF]) and
        (Copy(Source, i - 1, 2) <> CRLF)

    then begin

      Inc(Result.Line);
      LineStart := i;

    end;

    Inc(i);

  end;

  Result.Column := Result.Position - LineStart + 1;

end;

{ EStringParserException }

constructor EStringParserException.Create(const _Message: String; _CheckPoint: Boolean);
begin
  inherited Create(_Message);
  FCheckPoint := _CheckPoint;
end;

constructor EStringParserException.CreateFmt(const _Message: String; const _Args: array of const; _CheckPoint: Boolean);
begin
  Create(Format(_Message, _Args), _CheckPoint);
end;

{ ELocatedException }

constructor ELocatedException.Create;
begin

  inherited Create('Parser read exception was occured.');

  FInitExceptionClass := _InitExceptionClass;
  FInitMessage        := _InitMessage;
  FLocation           := _Location;

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
