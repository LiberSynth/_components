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

  { TODO 5 -oVasilyevSM -cuCustomStringParser: Section }
  { TODO 2 -oVasilyevSM -cuCustomStringParser: Проверить, не стал ли он тяжелее. }

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

    procedure CheckUnterminating;

    property Caption: String read FCaption;

  protected

    function CanOpen(_Parser: TCustomStringParser): Boolean; virtual;
    function CanClose(_Parser: TCustomStringParser): Boolean; virtual;
    procedure Opened(_Parser: TCustomStringParser); virtual;
    procedure Closed(_Parser: TCustomStringParser); virtual;
    procedure Execute(_Parser: TCustomStringParser; var _Handled: Boolean); virtual;

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
    function TryClose(_Parser: TCustomStringParser; var _ClosingKey: TKeyWord): Boolean;
    procedure CheckUnterminated;

    property Active: Boolean read FActive;
    property ActiveRegion: TRegion read FActiveRegion;

  end;

  TBlock = class(TRegion)
    { На данный момент повода здесь что-то добавить нет. }
  end;

  TCustomStringParser = class abstract

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

    function GetCursorKey(var _Value: TKeyWord): Boolean; inline;
    procedure ToggleStanding(_To: TStanding);
    function CheckRegions: Boolean;
    function RegionActive: Boolean; inline;
    procedure CheckUnterminated(_KeyType: TKeyType); inline;

    function GetRest: Int64; inline;

    property NestedLevel: Word read FNestedLevel;

  private

    function IsCursorKey(const _KeyWord: TKeyWord): Boolean;

    property Regions: TRegionList read FRegions;

  protected

    { События для потомков }
    procedure InitParser; virtual;
    procedure StepCommited; virtual;
    function ElementProcessingKey(_KeyWord: TKeyWord): Boolean; virtual;
    function ElementTerminatingKey(_KeyWord: TKeyWord): Boolean; virtual;
    procedure ProcessElement; virtual;
    function ExecuteRegion: Boolean;
    procedure ToggleElement(_KeyWord: TKeyWord); virtual;
    procedure CheckSyntax(const _KeyWord: TKeyWord); virtual;

  public

    constructor Create(const _Source: String); virtual;
    constructor CreateNested(_Master: TCustomStringParser); virtual;

    destructor Destroy; override;

    { События для потомков }
    procedure KeyEvent(const _KeyWord: TKeyWord); virtual;
    procedure MoveEvent; virtual;
    procedure ElementTerminatedEvent(_KeyWord: TKeyWord); virtual;

    { Методы и свойства для управления }
    procedure Move(_Incrementer: Int64 = 1); inline;
    function ReadElement(_Trim: Boolean): String; virtual;
    procedure AddRegion(

        const _RegionClass: TRegionClass;
        const _OpeningKey: TKeyWord;
        const _ClosingKey: TKeyWord;
        const _Caption: String

    );
    procedure Terminate;
    function Nested: Boolean;

    (*****************************)
    (*                           *)
    (*   Главный рабочий метод   *)
    (*                           *)
    (*****************************)
    procedure Read; virtual;

    property Source: String read FSource;
    property Cursor: Int64 read FCursor;
    property SrcLen: Int64 read FSrcLen;
    property Rest: Int64 read GetRest;
    property KeyWords: TKeyWordList read FKeyWords;
    property CursorStanding: TStanding read FCursorStanding;
    property ElementStart: Int64 read FElementStart;
    property RegionStart: Int64 read FRegionStart;
    property Terminated: Boolean read FTerminated;

  end;

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

  TLocatingStringParser = class abstract(TCustomStringParser)

  strict private

  const

    LOC_INITIAL: TLocation = (CurrentLine: 1; CurrentLineStart: 1; LastElementLine: 1; LastElementStart: 1; LastLineStart: 1);

  strict private

    FLocation: TLocation;

    procedure RefreshLocation;

    property Location: TLocation read FLocation write FLocation;

  protected

    procedure StepCommited; override;

  public

    constructor Create(const _Source: String); override;
    constructor CreateNested(_Master: TCustomStringParser); override;

    procedure Read; override;

  end;

  EStringParserException = class(ECoreException);

const

  KWR_EMPTY:         TKeyWord = (KeyTypeInternal: Integer(ktNone);      StrValue: '';   KeyLength: 0           );
  KWR_SOURCE_END:    TKeyWord = (KeyTypeInternal: Integer(ktSourceEnd); StrValue: '';   KeyLength: 0           );
  { TODO 3 -oVasilyevSM -cTCustomStringPaarser: Вообще-то эти ключи не используются, можно их убрать отсюда. }
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
procedure _ValidateRegions(_Regions: TRegionList);
var
  SSA, SSB: TRegion;
begin

  { TODO 4 -oVasilyevSM -cTCustomStringParser: Добавить еще одну проверку, что эти ключи не пересекаются с обычными. }

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

procedure TRegion.Execute(_Parser: TCustomStringParser; var _Handled: Boolean);
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

        Region.Opened(_Parser);
        FActiveRegion := Region;
        FActive := True;
        Exit(True);

      end;
      
  Result := False;
  
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
    FActiveRegion.CheckUnterminating;
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
  _ValidateRegions(Regions);
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

  FreeAndNil(FRegions);
  FreeAndNil(FKeyWords);

  inherited Destroy;

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

    { Move до переключения, потому что ключ не должен войти в регион. Начало после ключа. }
    Move(Regions.ActiveRegion.OpeningKey.KeyLength);
    ToggleStanding(stInside); { ТОЧКА ПЕРЕКЛЮЧЕНИЯ 1 (RegionOpened) }
    FRegionStart := Cursor;

  end;

end;

function TCustomStringParser.RegionActive: Boolean;
begin
  Result := Regions.Active;
end;

procedure TCustomStringParser.CheckUnterminated(_KeyType: TKeyType);
begin

  if (_KeyType = ktSourceEnd) then begin

    { Sections.CheckUnterminated; }
    Regions.CheckUnterminated;

  end;

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

procedure TCustomStringParser.InitParser;
begin

  FKeyWords := TKeyWordList.Create;
  FRegions  := TRegionList. Create;

  with KeyWords do begin

    { TODO 3 -oVasilyevSM -cTCustomStringPaarser: Вообще-то эти ключи не используются, можно их убрать отсюда. }
    Add(KWR_LINE_END_CRLF);
    Add(KWR_LINE_END_LF  );
    Add(KWR_LINE_END_CR  );

  end;

end;

procedure TCustomStringParser.StepCommited;
begin
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

function TCustomStringParser.ExecuteRegion: Boolean;
begin

  Result := False;
  Regions.ActiveRegion.Execute(Self, Result);

  if Result then begin

    ToggleStanding(stAfter); { ТОЧКА ПЕРЕКЛЮЧЕНИЯ 2 (after RegionExecute) }
    FRegionStart := 0;

  end;

end;

procedure TCustomStringParser.ToggleElement(_KeyWord: TKeyWord);
begin
  ToggleStanding(stBefore); { ТОЧКА ПЕРЕКЛЮЧЕНИЯ 3 (ToggleElement) }
end;

procedure TCustomStringParser.CheckSyntax(const _KeyWord: TKeyWord);
begin
  CheckUnterminated(_KeyWord.KeyType);
end;

procedure TCustomStringParser.KeyEvent(const _KeyWord: TKeyWord);
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

  if not RegionActive then begin

    if CursorStanding = stBefore then
      ToggleStanding(stInside); { ТОЧКА ПЕРЕКЛЮЧЕНИЯ 1 (MoveEvent) }

    CheckSyntax(KWR_EMPTY);

  end;

end;

procedure TCustomStringParser.ElementTerminatedEvent(_KeyWord: TKeyWord);
begin
end;

procedure TCustomStringParser.Move(_Incrementer: Int64);
begin

  if _Incrementer < 1 then
    raise EStringParserException.Create('Back moving.');

  if not Terminated then
    Inc(FCursor, _Incrementer);

end;

function TCustomStringParser.ReadElement(_Trim: Boolean): String;
begin

  if ElementStart > 0 then

    if _Trim then
      { TODO 5 -oVasilyevSM -cTCustomStringParser: Разобрать, я вроде видел, что очищаются не только пробелы, но и табы,
        и что-то еще. Но как? SysUtils.Trim по коду только на пробел значение проверяет. }
      Result := Trim(Copy(Source, ElementStart, Cursor - ElementStart))
    else
      Result := Copy(Source, ElementStart, Cursor - ElementStart)

  else Result := '';

end;

procedure TCustomStringParser.AddRegion;
begin
  Regions.Add(_RegionClass.Create(_OpeningKey, _ClosingKey, _Caption));
end;

procedure TCustomStringParser.Terminate;
begin
  FTerminated := True;
end;

function TCustomStringParser.Nested: Boolean;
begin
  Result := NestedLevel > 0;
end;

procedure TCustomStringParser.Read;

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

  while (Rest > 0) and not FTerminated do begin

    if not CheckRegions then

      if RegionActive then begin

        if not ExecuteRegion then { TODO -oVasilyevSM -cUCustomStringParser: Может, Execute нужно вызвать один раз? А то много работы получается. }
          Move;

      end else if not RegionActive and GetCursorKey(CursorKey) then begin

        KeyEvent(CursorKey);
        Move(CursorKey.KeyLength);

      end else begin

        MoveEvent;
        Move;

      end;

    StepCommited;

  end;

  KeyEvent(KWR_SOURCE_END);

end;

{ TLocation }

procedure TLocation.Remember(_Cursor: Int64);
begin

  LastElementLine  := CurrentLine;
  LastLineStart    := CurrentLineStart;
  LastElementStart := _Cursor;

end;

function TLocation.Line: Int64;
begin
  Result := LastElementLine;
end;

function TLocation.Column: Int64;
begin
  Result := LastElementStart - LastLineStart + 1;
end;

function TLocation.Position: Int64;
begin
  Result := LastElementStart;
end;

{ TLocatingStringParser }

constructor TLocatingStringParser.Create(const _Source: String);
begin
  inherited Create(_Source);
  FLocation := LOC_INITIAL;
end;

constructor TLocatingStringParser.CreateNested(_Master: TCustomStringParser);
begin
  inherited CreateNested(_Master);
  FLocation := (_Master as TLocatingStringParser).Location;
end;

procedure TLocatingStringParser.Read;
begin

  try

    inherited Read;

  except

    on E: Exception do

      if Nested then raise
      else

        { TODO 4 -oVasilyevSM -cTLocatingStringParser: Перегенерация на выбор, Native/Parametrized. Это Native, а тип
          Parametrized должен генерировать исключение другого класса с параметрами: ссылка на класс исходного
          исключения, его Message и набор локации, Line, Column, Position. }
        raise ExceptClass(E.ClassType).CreateFmt('%s. Line: %d, Column: %d, Position: %d', [

            E.Message,
            { Локация должна полностью совпадать с Notepad и Notepad++. }
            Location.Line,
            Location.Column,
            Location.Position

        ]);

  end;

end;

procedure TLocatingStringParser.RefreshLocation;
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

procedure TLocatingStringParser.StepCommited;
begin
  RefreshLocation;
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
