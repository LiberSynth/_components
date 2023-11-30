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

    FActive: Boolean;
    FOpeningKey: TKeyWord;
    FClosingKey: TKeyWord;

  private

    constructor Create(_OpeningKey, _ClosingKey: TKeyWord);

    procedure Open;
    procedure Close;

    property Active: Boolean read FActive;
    property OpeningKey: TKeyWord read FOpeningKey;
    property ClosingKey: TKeyWord read FClosingKey;

  protected

    function CanOpen(_Parser: TCustomStringParser; _KeyWord: TKeyWord): Boolean; virtual;
    function CanClose(_Parser: TCustomStringParser; _KeyWord: TKeyWord): Boolean; virtual;
    function KeyValid(_Parser: TCustomStringParser; _KeyWord: TKeyWord): Boolean; virtual;

  end;

  TSpecialSegmentClass = class of TSpecialSegment;

  TSpecialSegmentList = class(TObjectList<TSpecialSegment>)

  public

    function GetActiveSegment(var _Value: TSpecialSegment): Boolean;
    procedure Refresh(_Parser: TCustomStringParser; const _KeyWord: TKeyWord; _ActiveSegment: TSpecialSegment);

  end;

  TLocation = record

    Line: Int64;
    LineStart: Int64;
    LastItemBegin: Int64;

    function Position: Int64;

  end;

  TCustomStringParser = class
  { TODO 2 -oVasilyevSM -cTCustomStringParser: Этот класс надо "заморозить". Отладить и больше не изменять его. }

  strict private

    FSource: String;
    FSrcLen: Int64;
    FCursor: Int64;
    FNestedLevel: Word;

    FTerminated: Boolean;
    FItemBody: Boolean;
    FItemBegin: Int64;

    FLocation: TLocation;

    FKeyWords: TKeyWordList;
    FSpecialSegments: TSpecialSegmentList;

    function CheckKeys(var _Value: TKeyWord): Boolean;
    procedure IncLine;

  protected

    procedure InitParser; virtual;
    procedure KeyEvent(const _KeyWord: TKeyWord); virtual;
    procedure MoveEvent; virtual;

    function Nested: Boolean;
    function CheckDoubling(_ActiveSegment: TSpecialSegment; _KeyWord: TKeyWord; var Doubling: Boolean): Boolean;
    procedure Move(_Incrementer: Int64 = 1);
    procedure Terminate;
    function ReadItem: String;

    procedure AddSpecialSegment(const _SegmentClass: TSpecialSegmentClass; const _OpeningKey, _ClosingKey: TKeyWord);

    property NestedLevel: Word read FNestedLevel;
    property KeyWords: TKeyWordList read FKeyWords;
    property ItemBody: Boolean read FItemBody write FItemBody;
    property ItemBegin: Int64 read FItemBegin write FItemBegin;
    property Terminated: Boolean read FTerminated;

  public

    constructor Create(

        const _Source: String;
        _Cursor: Int64;
        _NestedLevel: Word;
        const _Location: TLocation

    ); overload;
    constructor Create(const _Source: String); overload;
    destructor Destroy; override;

    procedure Read;

    function CheckKey(const _KeyWord: TKeyWord): Boolean;

    property Source: String read FSource;
    property SrcLen: Int64 read FSrcLen;
    property Cursor: Int64 read FCursor;
    property Location: TLocation read FLocation write FLocation;

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

procedure TSpecialSegment.Open;
begin
  FActive := True;
end;

procedure TSpecialSegment.Close;
begin
  FActive := False;
end;

function TSpecialSegment.CanOpen(_Parser: TCustomStringParser; _KeyWord: TKeyWord): Boolean;
begin
  Result := OpeningKey.Equal(_KeyWord);
end;

function TSpecialSegment.CanClose(_Parser: TCustomStringParser; _KeyWord: TKeyWord): Boolean;
begin
  Result := ClosingKey.Equal(_KeyWord);
end;

function TSpecialSegment.KeyValid(_Parser: TCustomStringParser; _KeyWord: TKeyWord): Boolean;
begin

  Result :=

      _KeyWord.Equal(OpeningKey) or
      _KeyWord.Equal(ClosingKey);

end;

{ TSpecialSegmentList }

function TSpecialSegmentList.GetActiveSegment(var _Value: TSpecialSegment): Boolean;
var
  Segment: TSpecialSegment;
begin

  for Segment in Self do

    if Segment.Active then begin

      _Value := Segment;
      Exit(True);

    end;

  Result := False;

end;

procedure TSpecialSegmentList.Refresh(_Parser: TCustomStringParser; const _KeyWord: TKeyWord; _ActiveSegment: TSpecialSegment);
var
  Segment: TSpecialSegment;
begin

  if Assigned(_ActiveSegment) then begin

    with _ActiveSegment do
      if CanClose(_Parser, _KeyWord) then
        Close;

  end else begin

    for Segment in Self do

      with Segment do

        if CanOpen(_Parser, _KeyWord) then begin

          Open;
          Break;

        end;

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

constructor TCustomStringParser.Create(const _Source: String; _Cursor: Int64; _NestedLevel: Word; const _Location: TLocation);
begin

  inherited Create;

  FSource      := _Source;
  FSrcLen      := Length(_Source);
  FCursor      := _Cursor;
  FNestedLevel := _NestedLevel;
  FLocation    := _Location;

  FKeyWords        := TKeyWordList.       Create;
  FSpecialSegments := TSpecialSegmentList.Create;

  InitParser;

  {$IFDEF DEBUG}
  CheckSpecialSegments(FSpecialSegments);
  {$ENDIF}

end;

constructor TCustomStringParser.Create(const _Source: String);
begin
  Create(_Source, 1, 0, LOC_INITIAL);
end;

destructor TCustomStringParser.Destroy;
begin

  FreeAndNil(FSpecialSegments);
  FreeAndNil(FKeyWords       );

  inherited Destroy;

end;

function TCustomStringParser.CheckKeys(var _Value: TKeyWord): Boolean;
var
  KeyWord: TKeyWord;
begin

  for KeyWord in FKeyWords do

    if CheckKey(KeyWord) then begin

      _Value := KeyWord;
      Exit(True);

    end;

  Result := False;

end;

procedure TCustomStringParser.IncLine;
begin

  if

      (Copy(Source, Cursor - 2, 2) = CRLF) or
      CharInSet(Source[Cursor - 1], [CR, LF])

  then begin

    Inc(FLocation.Line);
    { TODO 4 -oVasilyevSM -cTCustomStringParser: Проверить, как будет считаться по CR или LF. }
    FLocation.LineStart := Cursor;
    FLocation.LastItemBegin := Cursor;

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

    ItemBegin := Cursor;
    FLocation.LastItemBegin := Cursor;
    ItemBody := True;
//    FSpecialSegments.Refresh(Self, KWR_EMPTY, nil);

  end;

end;

procedure TCustomStringParser.AddSpecialSegment;
begin
  FSpecialSegments.Add(_SegmentClass.Create(_OpeningKey, _ClosingKey));
end;

function TCustomStringParser.CheckKey(const _KeyWord: TKeyWord): Boolean;
begin
  with _KeyWord do
    Result := (KeyType <> ktNone) and (StrValue = Copy(Source, Cursor, KeyLength));
end;

function TCustomStringParser.Nested: Boolean;
begin
  Result := NestedLevel > 0;
end;

function TCustomStringParser.CheckDoubling(_ActiveSegment: TSpecialSegment; _KeyWord: TKeyWord; var Doubling: Boolean): Boolean;
begin

  with _KeyWord do

    Result :=

      (KeyLength = 1) and
      (SrcLen - Cursor > 2) and
      (Copy(Source, Cursor, 2) = StrValue + StrValue);

  if Result then Doubling := True;

end;

procedure TCustomStringParser.Move(_Incrementer: Int64);
begin
  Inc(FCursor, _Incrementer);
end;

procedure TCustomStringParser.Read;

//  function _IsKeyEvent(var _ActiveSegment: TSpecialSegment; var _CursorKey: TKeyWord): Boolean;
//  var
//    Active, KeyFound, Doubling, Valid: Boolean;
//  begin
//
//    _ActiveSegment := nil;
//    _CursorKey     := KWR_EMPTY;
//    Doubling       := False;
//    Valid          := False;
//
//    Active := FSpecialSegments.GetActiveSegment(_ActiveSegment);
//    if Active then begin
//
//      KeyFound := CheckKey(_ActiveSegment.ClosingKey) and not CheckDoubling(_ActiveSegment, _ActiveSegment.ClosingKey, Doubling);
//      if KeyFound then begin
//
//        { Активная зона закончилась, перед нами ее закрывающий ключ - KeyEvent }
//        Active := False;
//        _CursorKey := _ActiveSegment.ClosingKey;
//
//      end else begin
//
//        { Кастомные приблуды. Пробуем взять ключ из контекста }
//        KeyFound := CheckKeys(_CursorKey) and not CheckDoubling(_ActiveSegment, _CursorKey, Doubling);
//        if KeyFound then begin
//
//          { Если взялся, проверяем, не закрывается ли этим ключом активный сегмент }
//          Active := not _ActiveSegment.CanClose(Self, _CursorKey);
//
//          { Если не закрывается, спрашиваем у него, пропускает он такой ключ или блокирует }
//          if Active then
//            Valid := _ActiveSegment.KeyValid(Self, _CursorKey) and not CheckDoubling(_ActiveSegment, _CursorKey, Doubling);
//
//          { Активный сегмент пропускает такой ключ }
//          if Active and not Valid then begin
//
//            KeyFound := False;
//            _CursorKey := KWR_EMPTY;
//
//          end;
//
//        end;
//
//      end
//
//    end else begin
//
//      _ActiveSegment := nil;
//      { Активной зоны не было - проверяем, что перед нами, не ключ ли }
//      KeyFound := CheckKeys(_CursorKey);
//
//    end;
//
//    if Doubling then Move;
//
//    Result := KeyFound and (not Active or Valid);
//
//  end;

var
//  ActiveSegment: TSpecialSegment;
  CursorKey: TKeyWord;
begin

  try

    while (Cursor <= SrcLen) and not FTerminated do begin

      { TODO 1 -oVasilyevSM -cTSpecialSegment: Сначала проверяем сегменты, если произошло переключение, вызываем
        отдельное событие. TSpecialSegmentList.Active - это его свойство и оно посто выставляется по переключению.
        Соответственно переключаем им же, а не напрямую. Тогда здесь все прозрачное будет. Так и быстрее будет. }
      if CheckKeys(CursorKey) then begin

        KeyEvent(CursorKey);
        Move(CursorKey.KeyLength);

      end else begin

        { Иначе - простой шаг вперед }
        MoveEvent;
        Move;

      end;

      IncLine;

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

  if ItemBegin > 0 then
    Result := Trim(Copy(Source, ItemBegin, Cursor - ItemBegin));

  ItemBody := False;
  ItemBegin := 0;

end;

end.
