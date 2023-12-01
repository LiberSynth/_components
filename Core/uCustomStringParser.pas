unit uCustomStringParser;

interface

uses
  { VCL }
  SysUtils, Generics.Collections,
  { vSoft }
  uConsts, uCore;

type

  TKeyWordType = (ktNone, ktSourceEnd, ktLineEnd);
  TKeyWordTypes = set of TKeyWordType;

  TKeyWord = record

    KeyTypeInternal: Integer;
    StrValue: String;
    KeyLength: Integer;

    constructor Create(_KeyType: Integer; const _StrValue: String);

    function Equal(_Value: TKeyWord): Boolean;

  end;

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

  TKeyWordList = class(TList<TKeyWord>)
  end;

  TCustomStringParser = class;

  {

    Объект, позволяющий НЕ считать ключевыми словами любые символы внутри особого региона (строка, комментарий итд)
    кроме закрывающего этото регион ключа.
    Особые регионы настраиваются в потомках парсера добавлением в виртуальном методе InitParser с помощью
    AddSpecialRegion.
    Для настройки специфического региона нужно пронаследовать класс обработчика (от TSpecialRegion) и воспользовться
    двумя виртуальными методами:

    CanOpen  - условие открытия особого региона
    CanClose - условие закрытия особого региона

    Для строк в кавычках работает без наследования.

  }
  TSpecialRegion = class
  strict private

    FOpeningKey: TKeyWord;
    FClosingKey: TKeyWord;
    FUnterminatedMessage: String;

    function Doubling(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean;

  private

    constructor Create(

        const _OpeningKey: TKeyWord;
        const _ClosingKey: TKeyWord;
        const _UnterminatedMessage: String

    );

    procedure Open(_Parser: TCustomStringParser);
    procedure Close(_Parser: TCustomStringParser);

    procedure CheckUnterminating;

  protected

    function CanOpen(_Parser: TCustomStringParser): Boolean; virtual;
    function CanClose(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean; virtual;

  public

    property OpeningKey: TKeyWord read FOpeningKey;
    property ClosingKey: TKeyWord read FClosingKey;

  end;

  TSpecialRegionClass = class of TSpecialRegion;

  TSpecialRegionList = class(TObjectList<TSpecialRegion>)

  strict private

    FActive: Boolean;
    FActiveRegion: TSpecialRegion;

  private

    procedure Refresh(_Parser: TCustomStringParser; var _Handled: Boolean);
    procedure CheckCompleted;

    property Active: Boolean read FActive;

  end;

  TLocation = record

    Line: Int64;
    LineStart: Int64;
    LastItemBegin: Int64;

    function Column: Int64;
    function Position: Int64;

  end;

  TCustomStringParser = class
  { TODO 5 -oVasilyevSM -cTCustomStringParser: Этот класс надо "заморозить". Отладить и больше не изменять его. }

  strict private

    FSource: String;
    FSrcLen: Int64;
    FCursor: Int64;
    FNestedLevel: Word;

    FTerminated: Boolean;
    FItemBody: Boolean;
    FItemStart: Int64;

    FLocation: TLocation;

    FKeyWords: TKeyWordList;
    FSpecialRegions: TSpecialRegionList;

    function GetCursorKey(var _Value: TKeyWord): Boolean;
    procedure UpdateLocation;

    property NestedLevel: Word read FNestedLevel;

  private

    function IsCursorKey(const _KeyWord: TKeyWord): Boolean;

  protected

    { События для потомков }
    procedure InitParser; virtual;
    procedure KeyEvent(const _KeyWord: TKeyWord); virtual;
    procedure MoveEvent; virtual;
    procedure SpecialRegionOpened(_Region: TSpecialRegion); virtual;
    procedure SpecialRegionClosed(_Region: TSpecialRegion); virtual;

  public

    constructor Create(const _Source: String);
    constructor CreateNested(_Master: TCustomStringParser; _CursorShift: Int64);

    destructor Destroy; override;

    { Методы и свойства для управления }
    function Nested: Boolean;
    procedure Move(_Incrementer: Int64 = 1);
    procedure Terminate;
    function ReadItem(_Trim: Boolean): String;
    procedure CompleteItem;
    procedure AddSpecialRegion(

        const _RegionClass: TSpecialRegionClass;
        const _OpeningKey: TKeyWord;
        const _ClosingKey: TKeyWord;
        const _UnterminatedMessage: String

    );

    { Главный рабочий метод }
    procedure Read;

    property Source: String read FSource;
    property SrcLen: Int64 read FSrcLen;
    property Cursor: Int64 read FCursor;
    property Location: TLocation read FLocation write FLocation;
    property ItemBody: Boolean read FItemBody write FItemBody;
    property ItemStart: Int64 read FItemStart write FItemStart;
    property Terminated: Boolean read FTerminated;
    property KeyWords: TKeyWordList read FKeyWords;

  end;

  EStringParserException = class(ECoreException);

const

  KWR_EMPTY:         TKeyWord = (KeyTypeInternal: Integer(ktNone);      StrValue: '';   KeyLength: 0           );
  KWR_SOURCE_END:    TKeyWord = (KeyTypeInternal: Integer(ktSourceEnd); StrValue: '';   KeyLength: 0           );
  KWR_LINE_END_CR:   TKeyWord = (KeyTypeInternal: Integer(ktLineEnd);   StrValue: CR;   KeyLength: Length(CR)  );
  KWR_LINE_END_LF:   TKeyWord = (KeyTypeInternal: Integer(ktLineEnd);   StrValue: LF;   KeyLength: Length(LF)  );
  KWR_LINE_END_CRLF: TKeyWord = (KeyTypeInternal: Integer(ktLineEnd);   StrValue: CRLF; KeyLength: Length(CRLF));

  LOC_INITIAL: TLocation = (Line: 1; LineStart: 1; LastItemBegin: 1);

implementation

{ TKeyWord }

constructor TKeyWord.Create(_KeyType: Integer; const _StrValue: String);
begin

  KeyTypeInternal := _KeyType;
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
    KeyTypeInternal := Integer(_Value);
end;

function TKeyWordHelper.TypeInSet(const _Set: TKeyWordTypes): Boolean;
begin
  Result := KeyType in _Set;
end;

{ TSpecialRegion }

constructor TSpecialRegion.Create;
begin

  inherited Create;

  FOpeningKey          := _OpeningKey;
  FClosingKey          := _ClosingKey;
  FUnterminatedMessage := _UnterminatedMessage;

end;

function TSpecialRegion.Doubling(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean;
begin

  Result :=

    (ClosingKey.KeyLength = 1) and
    (_Parser.SrcLen - _Parser.Cursor + 1 >= 2) and
    (Copy(_Parser.Source, _Parser.Cursor, 2) = ClosingKey.StrValue + ClosingKey.StrValue);

  if Result then begin

    _Parser.MoveEvent;
    _Parser.Move(2);
    _Handled := True;

  end;

end;

procedure TSpecialRegion.Open(_Parser: TCustomStringParser);
begin
  _Parser.Move(OpeningKey.KeyLength);
end;

procedure TSpecialRegion.Close(_Parser: TCustomStringParser);
begin
  _Parser.Move(ClosingKey.KeyLength);
end;

procedure TSpecialRegion.CheckUnterminating;
begin
  if not ClosingKey.Equal(KWR_EMPTY) then
    raise EStringParserException.Create(FUnterminatedMessage);
end;

function TSpecialRegion.CanOpen(_Parser: TCustomStringParser): Boolean;
begin
  Result := _Parser.IsCursorKey(OpeningKey);
end;

function TSpecialRegion.CanClose(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean;
begin
  Result := _Parser.IsCursorKey(ClosingKey) and not Doubling(_Parser, _Handled);
end;

{ TSpecialRegionList }

procedure TSpecialRegionList.Refresh(_Parser: TCustomStringParser; var _Handled: Boolean);
var
  Region: TSpecialRegion;
begin

  _Handled:= False;

  if FActive then

    if FActiveRegion.CanClose(_Parser, _Handled) then begin

      FActiveRegion.Close(_Parser);
      _Parser.SpecialRegionClosed(FActiveRegion);

      FActiveRegion := nil;
      FActive := False;
      _Handled:= True;

    end else

  else

    for Region in Self do

      if Region.CanOpen(_Parser) then begin

        Region.Open(_Parser);
        _Parser.SpecialRegionOpened(Region);

        FActiveRegion := Region;
        FActive       := True;
        _Handled      := True;

        Break;

      end;

end;

procedure TSpecialRegionList.CheckCompleted;
begin
  if Active then
    FActiveRegion.CheckUnterminating;
end;

{$IFDEF DEBUG}
procedure CheckSpecialRegions(_SpecialRegions: TSpecialRegionList);
var
  SSA, SSB: TSpecialRegion;
begin

  for SSA in _SpecialRegions do
    for SSB in _SpecialRegions do
      if SSA <> SSB then
        if

            (not SSA.OpeningKey.Equal(KWR_EMPTY) and SSA.OpeningKey.Equal(SSB.OpeningKey)) or
            (not SSA.OpeningKey.Equal(KWR_EMPTY) and SSA.OpeningKey.Equal(SSB.ClosingKey)) or
            (not SSA.ClosingKey.Equal(KWR_EMPTY) and SSA.ClosingKey.Equal(SSB.OpeningKey)) or
            (not SSA.ClosingKey.Equal(KWR_EMPTY) and SSA.ClosingKey.Equal(SSB.ClosingKey))

        then raise ECoreException.Create('Special regions setting is wrong. Some keys are intersected.');

end;
{$ENDIF}

{ TLocation }

function TLocation.Column: Int64;
begin
  Result := LastItemBegin - LineStart + 1;
end;

function TLocation.Position: Int64;
begin
  Result := LastItemBegin;
end;

{ TCustomStringParser }

constructor TCustomStringParser.Create(const _Source: String);
begin

  inherited Create;

  FSource := _Source;
  FSrcLen := Length(_Source);

  FCursor   := 1;
  FLocation := LOC_INITIAL;

  FKeyWords       := TKeyWordList.       Create;
  FSpecialRegions := TSpecialRegionList.Create;

  InitParser;

  {$IFDEF DEBUG}
  CheckSpecialRegions(FSpecialRegions);
  {$ENDIF}

end;

constructor TCustomStringParser.CreateNested(_Master: TCustomStringParser; _CursorShift: Int64);
begin

  inherited Create;

  FSource := _Master.Source;
  FSrcLen := Length(Source);

  FCursor      := _Master.Cursor + _CursorShift;
  FLocation    := _Master.Location;
  FNestedLevel := _Master.NestedLevel + 1;

  FKeyWords       := TKeyWordList.      Create;
  FSpecialRegions := TSpecialRegionList.Create;

  InitParser;

end;

destructor TCustomStringParser.Destroy;
begin

  FreeAndNil(FSpecialRegions);
  FreeAndNil(FKeyWords      );

  inherited Destroy;

end;

function TCustomStringParser.IsCursorKey(const _KeyWord: TKeyWord): Boolean;
begin
  with _KeyWord do
    Result := (KeyType <> ktNone) and (StrValue = Copy(Source, Cursor, KeyLength));
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

      (Copy(Source, Cursor - 2, 2) = CRLF) or
      CharInSet(Source[Cursor - 1], [CR, LF])

  then begin

    Inc(FLocation.Line);
    FLocation.LineStart := Cursor;

  end;

end;

procedure TCustomStringParser.InitParser;
begin

  with KeyWords do begin

    Add(KWR_LINE_END_CRLF);
    Add(KWR_LINE_END_LF  );
    Add(KWR_LINE_END_CR  );

  end;

end;

procedure TCustomStringParser.KeyEvent(const _KeyWord: TKeyWord);
begin
  if (_KeyWord.KeyType = ktSourceEnd) then
    FSpecialRegions.CheckCompleted;
end;

procedure TCustomStringParser.MoveEvent;
begin

  if not ItemBody then begin

    ItemBody := True;
    ItemStart := Cursor;
    FLocation.LastItemBegin := Cursor;

  end;

end;

procedure TCustomStringParser.SpecialRegionClosed(_Region: TSpecialRegion);
begin
end;

procedure TCustomStringParser.SpecialRegionOpened(_Region: TSpecialRegion);
begin
end;

procedure TCustomStringParser.AddSpecialRegion;
begin
  FSpecialRegions.Add(_RegionClass.Create(_OpeningKey, _ClosingKey, _UnterminatedMessage));
end;

function TCustomStringParser.Nested: Boolean;
begin
  Result := NestedLevel > 0;
end;

procedure TCustomStringParser.Move(_Incrementer: Int64);
begin
  Inc(FCursor, _Incrementer);
end;

procedure TCustomStringParser.Read;
var
  CursorKey: TKeyWord;
  Handled: Boolean;
begin

  try

    while (Cursor <= SrcLen) and not FTerminated do begin

      FSpecialRegions.Refresh(Self, Handled);
      if not Handled then

        if not FSpecialRegions.Active and GetCursorKey(CursorKey) then begin

          KeyEvent(CursorKey);
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

      if Nested then

        raise

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

  CompleteItem;

end;

procedure TCustomStringParser.CompleteItem;
begin
  ItemBody  := False;
  ItemStart := 0;
end;

end.
