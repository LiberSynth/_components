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
    function GetKey(const _StrValue: String): TKeyWord;

  end;

  {

    Объект, позволяющий НЕ считать ключевыми словами любые символы внутри особого сегента (строка, комментарий итд)
    кроме закрывающего этото сегент ключа. Сегменты парсера настраиваются в потомках добавлением в виртуальном методе
    InitSpecialSegments с помощью AddSpecialSegment. Класс обработчика можно пронаследовать (от TSpecialSegment), чтобы
    расширить его поведение. Для строк работает без наследования.

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

  end;

  TSpecialSegmentClass = class of TSpecialSegment;

  TSpecialSegmentList = class(TObjectList<TSpecialSegment>)

  public

    function Active(var _Value: TSpecialSegment): Boolean;
    procedure Refresh(const _KeyWord: TKeyWord; _ActiveHandler: TSpecialSegment);

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

    function CheckKey(const _KeyWord: TKeyWord): Boolean;
    procedure Move(_Incrementer: Int64 = 1);
    procedure KeyEvent(const _KeyWord: TKeyWord); virtual;
    procedure MoveEvent; virtual;
    procedure Terminate;
    function ReadItem: String;

    procedure AddSpecialSegment(const _HandlerClass: TSpecialSegmentClass; const _OpeningKey, _ClosingKey: TKeyWord);

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

function TKeyWordList.GetKey(const _StrValue: String): TKeyWord;
var
  Item: TKeyWord;
begin

  for Item in Self do
    if Item.StrValue = _StrValue then
      Exit(Item);

  raise ECoreException.CreateFmt('KeyWord not found by StrValue ''%s''', [_StrValue]);

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

{ TSpecialSegmentList }

function TSpecialSegmentList.Active(var _Value: TSpecialSegment): Boolean;
var
  Handler: TSpecialSegment;
begin

  for Handler in Self do

    if Handler.Active then begin

      _Value := Handler;
      Exit(True);

    end;

  Result := False;

end;

procedure TSpecialSegmentList.Refresh(const _KeyWord: TKeyWord; _ActiveHandler: TSpecialSegment);
var
  Handler: TSpecialSegment;
begin

  { TODO -oVasilyevSM -cTSpecialSegmentList: Нужно проверять всю настройку где-то в дебаге. Ключи не должны
    повторяться никак. То есть, открывающий ключ каждой зоны не должен быть закрывающим для другой. и наоборот. }

  if Assigned(_ActiveHandler) then begin

    with _ActiveHandler do
      if ClosingKey.Equal(_KeyWord) then
        Close;

  end else begin

    for Handler in Self do

      with Handler do

        if not Active and OpeningKey.Equal(_KeyWord) then begin

          Open;
          Break;

        end;

  end;

end;

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

    AddKey(ktLineEnd, CRLF, True);
    AddKey(ktLineEnd, CR,   True);
    AddKey(ktLineEnd, LF,   True);

  end;

end;

procedure TCustomStringParser.InitSpecialSegments;
begin
end;

procedure TCustomStringParser.AddSpecialSegment;
begin
  FSpecialSegments.Add(_HandlerClass.Create(_OpeningKey, _ClosingKey));
end;

function TCustomStringParser.CheckKey(const _KeyWord: TKeyWord): Boolean;
begin
  with _KeyWord do
    Result := StrValue = Copy(Source, Cursor, KeyLength);
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

  if not ItemBody then
    ItemBegin := Cursor;

  ItemBody := True;

end;

procedure TCustomStringParser.Read;
var
  ActiveHandler: TSpecialSegment;
  CursorKey: TKeyWord;

  function _KeyDoubling: Boolean;
  begin

    with ActiveHandler.ClosingKey do

      Result :=

        (KeyLength = 1) and
        (Length - Cursor > 2) and
        (Copy(Source, Cursor, 2) = StrValue + StrValue);

    { Если KeyDoubling, то это сразу MoveEvent. Никто больше ключи проверять не будет. }
    if Result then
      Move;

  end;

  function _IsKeyEvent: Boolean;
  var
    ActiveSegment, KeyFound: Boolean;
  begin

    ActiveSegment := FSpecialSegments.Active(ActiveHandler);
    if ActiveSegment then begin

      KeyFound := CheckKey(ActiveHandler.ClosingKey) and not _KeyDoubling;
      if KeyFound then begin

        { Активная зона закончилась, перед нами ее закрывающий ключ - KeyEvent }
        ActiveSegment := False;
        CursorKey := ActiveHandler.ClosingKey;

      end; { Это MoveEvent, CursorKey не понадобится }

    end else begin

      ActiveHandler := nil;
      { Активной зоны не было - проверяем, что перед нами, не ключ ли }
      KeyFound := CheckKeys(CursorKey);

    end;

    Result := not ActiveSegment and KeyFound;

  end;

begin

  while (Cursor <= Length) and not FTerminated do begin

    if _IsKeyEvent then begin

      KeyEvent(CursorKey);
      Move(CursorKey.KeyLength);

      { И обновляем состояние всех особых зон по текущему ключу }
      FSpecialSegments.Refresh(CursorKey, ActiveHandler);

    end else begin

      { Иначе - простой шаг вперед }
      MoveEvent;
      Move;

    end;

  end;

  KeyEvent(TKeyWord.Create(ktSourceEnd, ''));

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
