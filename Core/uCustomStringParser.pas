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

  { TODO 2 -oVasilyevSM -cTCustomStringParser: Segment -> Area, сегмент -> область }
  {

    Объект, позволяющий НЕ считать ключевыми словами любые символы внутри особого сегмента (строка, комментарий итд)
    кроме закрывающего этото сегент ключа или дополнительно заданных допустимых как ключи.
    Особые сегменты парсера настраиваются в потомках парсера добавлением в виртуальном методе InitSpecialSegments с
    помощью AddSpecialSegment.
    Для настройки специфицеской особой зоны нужно пронаследовать класс обработчика (от TSpecialSegment) и воспользовться
    тремя виртуальными методами:

    CanOpen  - условие открытия особого сегмента
    CanClose - условие закрытия особого сегмента
    KeyValid - условие пропуска ключа (как ключа, а не простого символа)

    Для строк в кавычках работает без наследования.
    Сделан особый сегмент для строк без кавычек. Виртуозная штука, но оставил из интереса. Если проблем не создаст,
    пусть живет.

  }
  TSpecialSegment = class

  strict private

    FOpeningKey: TKeyWord;
    FClosingKey: TKeyWord;

    function Doubling(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean;

  private

    constructor Create(_OpeningKey, _ClosingKey: TKeyWord);

    procedure Open(_Parser: TCustomStringParser);
    procedure Close(_Parser: TCustomStringParser);

  protected

    function CanOpen(_Parser: TCustomStringParser): Boolean; virtual;
    function CanClose(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean; virtual;
    function KeyValid(_Parser: TCustomStringParser; _KeyWord: TKeyWord): Boolean; virtual;

  public

    property OpeningKey: TKeyWord read FOpeningKey;
    property ClosingKey: TKeyWord read FClosingKey;

  end;

  TSpecialSegmentClass = class of TSpecialSegment;

  TSpecialSegmentList = class(TObjectList<TSpecialSegment>)

  strict private

    FActive: Boolean;
    FActiveSegment: TSpecialSegment;

  private

    procedure Refresh(_Parser: TCustomStringParser; var _Handled: Boolean);

    property Active: Boolean read FActive;

  end;

  TLocation = record

    Line: Int64;
    LineStart: Int64;
    LastItemBegin: Int64;

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
    FSpecialSegments: TSpecialSegmentList;

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
    procedure SpecialSegmentOpened(_Segment: TSpecialSegment); virtual;
    procedure SpecialSegmentClosed(_Segment: TSpecialSegment); virtual;

    { Методы и свойства для потомков }
    function Nested: Boolean;
    procedure Move(_Incrementer: Int64 = 1);
    procedure Terminate;
    function ReadItem: String;
    procedure CompleteItem;
    procedure AddSpecialSegment(const _SegmentClass: TSpecialSegmentClass; const _OpeningKey, _ClosingKey: TKeyWord);

    property Source: String read FSource;
    property SrcLen: Int64 read FSrcLen;
    property Cursor: Int64 read FCursor;
    property Location: TLocation read FLocation write FLocation;
    property ItemBody: Boolean read FItemBody write FItemBody;
    property ItemStart: Int64 read FItemStart write FItemStart;
    property Terminated: Boolean read FTerminated;
    property KeyWords: TKeyWordList read FKeyWords;

  public

    constructor Create(const _Source: String);
    constructor CreateNested(_Master: TCustomStringParser);

    destructor Destroy; override;

    { Главный рабочий метод }
    procedure Read;

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

{ TSpecialSegment }

constructor TSpecialSegment.Create(_OpeningKey, _ClosingKey: TKeyWord);
begin

  inherited Create;

  FOpeningKey := _OpeningKey;
  FClosingKey := _ClosingKey;

end;

function TSpecialSegment.Doubling(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean;
begin

  Result :=

    (ClosingKey.KeyLength = 1) and
    (_Parser.SrcLen - _Parser.Cursor > 2) and
    (Copy(_Parser.Source, _Parser.Cursor, 2) = ClosingKey.StrValue + ClosingKey.StrValue);

  if Result then begin

    _Parser.Move(2);
    _Handled := True;

  end;

end;

procedure TSpecialSegment.Open(_Parser: TCustomStringParser);
begin
  _Parser.Move(OpeningKey.KeyLength);
end;

procedure TSpecialSegment.Close(_Parser: TCustomStringParser);
begin
  _Parser.Move(ClosingKey.KeyLength);
end;

function TSpecialSegment.CanOpen(_Parser: TCustomStringParser): Boolean;
begin
  Result := _Parser.IsCursorKey(OpeningKey);
end;

function TSpecialSegment.CanClose(_Parser: TCustomStringParser; var _Handled: Boolean): Boolean;
begin
  Result := _Parser.IsCursorKey(ClosingKey) and not Doubling(_Parser, _Handled);
end;

function TSpecialSegment.KeyValid(_Parser: TCustomStringParser; _KeyWord: TKeyWord): Boolean;
begin
  Result := _KeyWord.Equal(OpeningKey) or _KeyWord.Equal(ClosingKey);
end;

{ TSpecialSegmentList }

procedure TSpecialSegmentList.Refresh(_Parser: TCustomStringParser; var _Handled: Boolean);
var
  Segment: TSpecialSegment;
begin

  _Handled:= False;

  if FActive then

    if FActiveSegment.CanClose(_Parser, _Handled) then begin

      FActiveSegment.Close(_Parser);
      _Parser.SpecialSegmentClosed(FActiveSegment);

      FActiveSegment := nil;
      FActive := False;
      _Handled:= True;

    end else

  else

    for Segment in Self do

      if Segment.CanOpen(_Parser) then begin

        Segment.Open(_Parser);
      _Parser.SpecialSegmentOpened(Segment);

        FActiveSegment := Segment;
        FActive := True;
        _Handled:= True;

        Break;

      end;

end;

{$IFDEF DEBUG}
procedure CheckSpecialSegments(_SpecialSegments: TSpecialSegmentList);
var
  SSA, SSB: TSpecialSegment;
begin

  for SSA in _SpecialSegments do
    for SSB in _SpecialSegments do
      if SSA <> SSB then
        if

            (not SSA.OpeningKey.Equal(KWR_EMPTY) and SSA.OpeningKey.Equal(SSB.OpeningKey)) or
            (not SSA.OpeningKey.Equal(KWR_EMPTY) and SSA.OpeningKey.Equal(SSB.ClosingKey)) or
            (not SSA.ClosingKey.Equal(KWR_EMPTY) and SSA.ClosingKey.Equal(SSB.OpeningKey)) or
            (not SSA.ClosingKey.Equal(KWR_EMPTY) and SSA.ClosingKey.Equal(SSB.ClosingKey))

        then raise ECoreException.Create('Special segments setting is wrong. Some keys are intersected.');

end;
{$ENDIF}

{ TLocation }

function TLocation.Position: Int64;
begin
  Result := LastItemBegin - LineStart + 1;
end;

{ TCustomStringParser }

constructor TCustomStringParser.Create(const _Source: String);
begin

  inherited Create;

  FSource := _Source;
  FSrcLen := Length(_Source);

  FCursor   := 1;
  FLocation := LOC_INITIAL;

  FKeyWords        := TKeyWordList.       Create;
  FSpecialSegments := TSpecialSegmentList.Create;

  InitParser;

  {$IFDEF DEBUG}
  CheckSpecialSegments(FSpecialSegments);
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

  FKeyWords        := TKeyWordList.       Create;
  FSpecialSegments := TSpecialSegmentList.Create;

  InitParser;

end;

destructor TCustomStringParser.Destroy;
begin

  FreeAndNil(FSpecialSegments);
  FreeAndNil(FKeyWords       );

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
    { TODO 4 -oVasilyevSM -cTCustomStringParser: Проверить, как будет считаться по CR или LF. }
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
end;

procedure TCustomStringParser.MoveEvent;
begin

  if not ItemBody then begin

    ItemStart := Cursor;
    FLocation.LastItemBegin := Cursor;
    ItemBody := True;

  end;

end;

procedure TCustomStringParser.SpecialSegmentClosed(_Segment: TSpecialSegment);
begin
end;

procedure TCustomStringParser.SpecialSegmentOpened(_Segment: TSpecialSegment);
begin
end;

procedure TCustomStringParser.AddSpecialSegment;
begin
  FSpecialSegments.Add(_SegmentClass.Create(_OpeningKey, _ClosingKey));
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

      FSpecialSegments.Refresh(Self, Handled);
      if not Handled then

        if not FSpecialSegments.Active and GetCursorKey(CursorKey) then begin

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
        raise ExceptClass(E.ClassType).CreateFmt('%s. Line: %d, Position: %d', [E.Message, Location.Line, Location.Position]);

  end;

end;

procedure TCustomStringParser.Terminate;
begin
  FTerminated := True;
end;

function TCustomStringParser.ReadItem: String;
begin
  if ItemStart > 0 then
    Result := Trim(Copy(Source, ItemStart, Cursor - ItemStart));
  CompleteItem;
end;

procedure TCustomStringParser.CompleteItem;
begin
  ItemBody  := False;
  ItemStart := 0;
end;

end.
