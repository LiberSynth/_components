unit uCustomStringParser;

interface

uses
  { VCL }
  SysUtils, Generics.Collections,
  { vSoft }
  uConsts, uCore;

type

  TKeyWordType = (ktNone, ktSourceEnd, ktLineEnd);

  TKeyWord = record

    KeyTypeInternal: Integer;
    StrValue: String;
    KeyLength: Integer;
    QuotingSymbol: Boolean;

    constructor Create(_KeyType: Integer; const _StrValue: String; _QuotingSymbol: Boolean = False);

    function Equal(_Value: TKeyWord): Boolean;

  end;

  TKeyWordHelper = record helper for TKeyWord

  private

    constructor Create(_KeyType: TKeyWordType; const _StrValue: String; _QuotingSymbol: Boolean = False); overload;

    function GetKeyType: TKeyWordType;
    procedure SetKeyType(const _Value: TKeyWordType);

    property KeyType: TKeyWordType read GetKeyType write SetKeyType;

  end;

  TKeyWordList = class(TList<TKeyWord>)

  public

    function AddKey(_KeyType: TKeyWordType; const _StrValue: String; _QuotingSymbol: Boolean = False): TKeyWord;

  end;

  TCustomStringParser = class;

  {

    Объект, позволяющий НЕ считать ключевыми словами любые символы внутри особого сегента (строка, комментарий итд)
    кроме закрывающего этото сегент ключа или дополнительно заданных допустимых как ключи.
    Особые сегменты парсера настраиваются в потомках парсера добавлением в виртуальном методе InitSpecialSegments с
    помощью AddSpecialSegment.
    Для настройки специфицеской особой зоны нужно пронаследовать класс обработчика (от TSpecialSegment) и воспользовться
    тремя виртуальными методами:

    CanOpen  - условие открытия особого сегмента
    CanClose - условие закрытия особого сегмента
    KeyValid - условие пропуска ключа (как ключа, а не простого символа)

    Для строк и комментариев работает без наследования.

  }
  TSpecialSegment = class
  { TODO -oVasilyevSM -cTSpecialSegment: После отдадки даты проверить, не заработает ли мультистрока без кавычек }

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

    function Active(var _Value: TSpecialSegment): Boolean;
    procedure Refresh(_Parser: TCustomStringParser; const _KeyWord: TKeyWord; _ActiveSegment: TSpecialSegment);

  end;

  TCustomStringParser = class

  strict private

    FSource: String;
    FLength: Int64;
    FCursor: Int64;

    FTerminated: Boolean;
    FItemBody: Boolean;
    FItemBegin: Int64;

    FLine: Int64;
    FLinePos: Int64;

    FKeyWords: TKeyWordList;
    FSpecialSegments: TSpecialSegmentList;

    function CheckKeys(var _Value: TKeyWord): Boolean;
    procedure IncLine(const _KeyWord: TKeyWord);

  protected

    class procedure InitKeyWords(_KeyWords: TKeyWordList); virtual;
    procedure InitSpecialSegments; virtual;

    function CheckDoubling(_ActiveSegment: TSpecialSegment; _KeyWord: TKeyWord; var Doubling: Boolean): Boolean;
    procedure Move(_Incrementer: Int64 = 1);
    procedure KeyEvent(const _KeyWord: TKeyWord); virtual;
    procedure MoveEvent; virtual;
    procedure Terminate;
    function ReadItem: String;

    procedure AddSpecialSegment(const _SegmentClass: TSpecialSegmentClass; const _OpeningKey, _ClosingKey: TKeyWord);

    property KeyWords: TKeyWordList read FKeyWords;
    property ItemBody: Boolean read FItemBody write FItemBody;
    property ItemBegin: Int64 read FItemBegin write FItemBegin;
    property Terminated: Boolean read FTerminated;

  public

    constructor Create(

        const _Source: String;
        _Cursor: Int64 = 1;
        _Line: Int64 = 1;
        _LinePos: Int64 = 1

    );
    destructor Destroy; override;

    procedure Read;

    function CheckKey(const _KeyWord: TKeyWord): Boolean;

    property Source: String read FSource;
    property Length: Int64 read FLength;
    property Cursor: Int64 read FCursor;
    property Line: Int64 read FLine write FLine;
    property LinePos: Int64 read FLinePos write FLinePos;

  end;

  EStringParserException = class(ECoreException)

  public

    { TODO -oVasilyevSM -cTCustomStringParser: Line и Position почти всегда считаются неправильно }
    constructor Create(const _Message: String; _Line, _Position: Int64);
    constructor CreateFmt(const _Message: String; const _Args: array of const; _Line, _Position: Int64);
    constructor CreatePos(const _Message: String; _Line, _Position: Int64);

  end;

const

  KWR_EMPTY:         TKeyWord = (KeyTypeInternal: Integer(ktNone);      StrValue: '';   KeyLength: 0;            QuotingSymbol: False);
  KWR_SOURCE_END:    TKeyWord = (KeyTypeInternal: Integer(ktSourceEnd); StrValue: '';   KeyLength: 0;            QuotingSymbol: False);
  KWR_LINE_END_CR:   TKeyWord = (KeyTypeInternal: Integer(ktLineEnd);   StrValue: CR;   KeyLength: Length(CR);   QuotingSymbol: True );
  KWR_LINE_END_LF:   TKeyWord = (KeyTypeInternal: Integer(ktLineEnd);   StrValue: LF;   KeyLength: Length(LF);   QuotingSymbol: True );
  KWR_LINE_END_CRLF: TKeyWord = (KeyTypeInternal: Integer(ktLineEnd);   StrValue: CRLF; KeyLength: Length(CRLF); QuotingSymbol: True );

implementation

{ TKeyWord }

constructor TKeyWord.Create(_KeyType: Integer; const _StrValue: String; _QuotingSymbol: Boolean);
begin

  KeyTypeInternal := _KeyType;
  StrValue        := _StrValue;
  KeyLength       := Length(StrValue);
  QuotingSymbol   := _QuotingSymbol;

end;

function TKeyWord.Equal(_Value: TKeyWord): Boolean;
begin

  Result :=

      (_Value.KeyTypeInternal = KeyTypeInternal) and
      (_Value.StrValue        = StrValue       ) and
      (_Value.KeyLength       = KeyLength      );

end;

{ TKeyWordHelper }

constructor TKeyWordHelper.Create(_KeyType: TKeyWordType; const _StrValue: String; _QuotingSymbol: Boolean);
begin
  Create(Integer(_KeyType), _StrValue, _QuotingSymbol);
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

{ TKeyWordList }

function TKeyWordList.AddKey(_KeyType: TKeyWordType; const _StrValue: String; _QuotingSymbol: Boolean): TKeyWord;
begin
  Result := TKeyWord.Create(Integer(_KeyType), _StrValue, _QuotingSymbol);
  Add(Result);
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

function TSpecialSegmentList.Active(var _Value: TSpecialSegment): Boolean;
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

            SSA.OpeningKey.Equal(SSB.OpeningKey) or
            SSA.OpeningKey.Equal(SSB.ClosingKey) or
            SSA.ClosingKey.Equal(SSB.OpeningKey) or
            SSA.ClosingKey.Equal(SSB.ClosingKey)

        then raise ECoreException.Create('Special segments setting is wrong. Some keys are intersected.');

end;
{$ENDIF}

{ TCustomStringParser }

constructor TCustomStringParser.Create;
begin

  inherited Create;

  FSource  := _Source;
  FLength  := System.Length(_Source);
  FCursor  := _Cursor;
  FLine    := _Line;
  FLinePos := _LinePos;

  FKeyWords        := TKeyWordList.       Create;
  FSpecialSegments := TSpecialSegmentList.Create;

  InitKeyWords(KeyWords);
  InitSpecialSegments;

  {$IFDEF DEBUG}
  CheckSpecialSegments(FSpecialSegments);
  {$ENDIF}

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

procedure TCustomStringParser.IncLine(const _KeyWord: TKeyWord);
begin
  Inc(FLine);
  LinePos := Cursor + _KeyWord.KeyLength;
end;

class procedure TCustomStringParser.InitKeyWords(_KeyWords: TKeyWordList);
begin

  with _KeyWords do begin

    Add(KWR_LINE_END_CRLF);
    Add(KWR_LINE_END_LF  );
    Add(KWR_LINE_END_CR  );

  end;

end;

procedure TCustomStringParser.InitSpecialSegments;
begin
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

function TCustomStringParser.CheckDoubling(_ActiveSegment: TSpecialSegment; _KeyWord: TKeyWord; var Doubling: Boolean): Boolean;
begin

  with _KeyWord do

    Result :=

      (KeyLength = 1) and
      (Length - Cursor > 2) and
      (Copy(Source, Cursor, 2) = StrValue + StrValue);

  if Result then Doubling := True;

end;

procedure TCustomStringParser.Move(_Incrementer: Int64);
begin
  Inc(FCursor, _Incrementer);
end;

procedure TCustomStringParser.KeyEvent(const _KeyWord: TKeyWord);
begin
  if _KeyWord.KeyType = ktLineEnd then
    IncLine(_KeyWord);
end;

procedure TCustomStringParser.MoveEvent;
begin

  if not ItemBody then begin

    ItemBegin := Cursor;
    ItemBody := True;

  end;

end;

procedure TCustomStringParser.Read;

  function _IsKeyEvent(var _ActiveSegment: TSpecialSegment; var _CursorKey: TKeyWord): Boolean;
  { TODO 1 -oVasilyevSM -cTCustomStringParser: -> в класс ^ }
  var
    Active, KeyFound, Doubling, Valid: Boolean;
  begin

    _ActiveSegment := nil;
    _CursorKey     := KWR_EMPTY;
    Doubling       := False;
    Valid          := False;

    Active := FSpecialSegments.Active(_ActiveSegment);
    if Active then begin

      KeyFound := CheckKey(_ActiveSegment.ClosingKey) and not CheckDoubling(_ActiveSegment, _ActiveSegment.ClosingKey, Doubling);
      if KeyFound then begin

        { Активная зона закончилась, перед нами ее закрывающий ключ - KeyEvent }
        Active := False;
        _CursorKey := _ActiveSegment.ClosingKey;

      end else begin

        { Кастомные приблуды. Пробуем взять ключ из контекста }
        KeyFound := CheckKeys(_CursorKey) and not CheckDoubling(_ActiveSegment, _CursorKey, Doubling);
        if KeyFound then begin

          { Если взялся, проверяем, не закрывается ли этим ключом активный сегмент }
          Active := not _ActiveSegment.CanClose(Self, _CursorKey);

          { Если не закрывается, спрашиваем у него, пропускает он такой ключ или блокирует }
          if Active then
            Valid := _ActiveSegment.KeyValid(Self, _CursorKey) and not CheckDoubling(_ActiveSegment, _CursorKey, Doubling);

          { Активный сегмент пропускает такой ключ }
          if Active and not Valid then begin

            KeyFound := False;
            _CursorKey := KWR_EMPTY;

          end;

        end;

      end

    end else begin

      _ActiveSegment := nil;
      { Активной зоны не было - проверяем, что перед нами, не ключ ли }
      KeyFound := CheckKeys(_CursorKey);

    end;

    if Doubling then Move;

    Result := KeyFound and (not Active or Valid);

  end;

var
  ActiveSegment: TSpecialSegment;
  CursorKey: TKeyWord;
begin

  while (Cursor <= Length) and not FTerminated do begin

    if _IsKeyEvent(ActiveSegment, CursorKey) then begin

      KeyEvent(CursorKey);
      { И обновляем состояние всех особых зон по текущему ключу }
      FSpecialSegments.Refresh(Self, CursorKey, ActiveSegment);
      Move(CursorKey.KeyLength);

    end else begin

      { Иначе - простой шаг вперед }
      MoveEvent;
      Move;

    end;

  end;

  KeyEvent(KWR_SOURCE_END);

  { Оборачивать этот метод в try except чревато. В on E do получается уничтоженный объект E. }
  { TODO -oVasilyevSM -ctry_except_end: Нужен эксперимент, откуда вызовется E.Free, если тут обернуть таки. }

end;

procedure TCustomStringParser.Terminate;
begin
  FTerminated := True;
end;

function TCustomStringParser.ReadItem: String;
begin

  Result := Trim(Copy(Source, ItemBegin, Cursor - ItemBegin));

  ItemBody := False;
  ItemBegin := 0;

end;

{ EStringParserError }

constructor EStringParserException.Create(const _Message: String; _Line, _Position: Int64);
begin
 inherited CreateFmt('%s [Line = %d, before position = %d]', [_Message, _Line, _Position]);
end;

constructor EStringParserException.CreateFmt(const _Message: String; const _Args: array of const; _Line, _Position: Int64);
begin
  Create(Format(_Message, _Args), _Line, _Position);
end;

constructor EStringParserException.CreatePos(const _Message: String; _Line, _Position: Int64);
begin
 inherited CreateFmt('%s [Line = %d, position = %d]', [_Message, _Line, _Position]);
end;

end.
