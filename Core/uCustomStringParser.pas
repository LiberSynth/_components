unit uCustomStringParser;

interface

uses
  { VCL }
  SysUtils, Generics.Collections,
  { vSoft }
  uConsts, uCore;

type

  TKeyWordType = (ktSourceEnd, ktLineEnd);

  TKeyWord = record

    KeyType: Integer;
    StrValue: String;
    KeyLength: Integer;

    constructor Create(_KeyType: Integer; const _StrValue: String);

  end;

  TKeyWordRelations = class(TDictionary<TKeyWord, TKeyWord>)

  private

    procedure Add(_KeyWordA, _KeyWordB: TKeyWord);

  end;

  TKeyWordList = class(TList<TKeyWord>)

  strict private

    FRelations: TKeyWordRelations;

  public

    constructor Create;
    destructor Destroy; override;

    function Add(_KeyType: Integer; const _StrValue: String): TKeyWord;
    procedure Relate(_KeyWordA, _KeyWordB: TKeyWord);
    function GetRelated(_KeyWord: TKeyWord): TKeyWord;

  end;

  TCustomStringParser = class

  strict private

    FSource: String;
    FLength: Int64;
    FCursor: Int64;
    FKeyWords: TKeyWordList;
    FTerminated: Boolean;

    FItemBody: Boolean;
    FItemBegin: Int64;

    FLine: Int64;
    FLinePos: Int64;

    function CheckKeys: Boolean;
    procedure KeyFound(const _KeyWord: TKeyWord);
    procedure IncLine(const _KeyWord: TKeyWord);

  protected

    function CheckKey(const _KeyWord: TKeyWord): Boolean;
    procedure Move(_Incrementer: Int64 = 1);
    procedure KeyEvent(const _KeyWord: TKeyWord); virtual;
    procedure MoveEvent; virtual;
    procedure Terminate;
    function ReadItem: String;
    { Функция, позволяющая НЕ считать ключевыми словами любые символы внутри какого-либо пространства (строки, комментарии итд) }
    function SpecialSpace: Boolean; virtual;

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

    { TODO -oVasilyevSM -cTCustomStringParser: В случае отрицательной позиции здесь нужно в принципе по-другому
      отсчитывать строки, чтобы нормально спозиционироваться. И ItemBegin на момент генерации исключения может быть
      сброшен, поэтому надо хранить последний актуальный ItemBegin и его возвращать здесь. }
    constructor Create(const _Message: String; _Line, _Position: Int64);
    constructor CreateFmt(const _Message: String; const _Args: array of const; _Line, _Position: Int64);
    constructor CreatePos(const _Message: String; _Line, _Position: Int64);

  end;

implementation

{ TKeyWord }

constructor TKeyWord.Create(_KeyType: Integer; const _StrValue: String);
begin

  KeyType := _KeyType;
  StrValue := _StrValue;
  KeyLength := Length(StrValue);

end;

{ TKeyWordRelations }

procedure TKeyWordRelations.Add(_KeyWordA, _KeyWordB: TKeyWord);
begin

  if ContainsKey(_KeyWordA) then
    raise ECoreException.Create('Key value is not unique');

  inherited Add(_KeyWordA, _KeyWordB);

end;

{ TKeyWordList }

constructor TKeyWordList.Create;
begin
  inherited Create;
  FRelations := TKeyWordRelations.Create;
end;

destructor TKeyWordList.Destroy;
begin
  FreeAndNil(FRelations);
  inherited Destroy;
end;

function TKeyWordList.Add(_KeyType: Integer; const _StrValue: String): TKeyWord;
begin
  Result := TKeyWord.Create(_KeyType, _StrValue);
  inherited Add(Result);
end;

procedure TKeyWordList.Relate(_KeyWordA, _KeyWordB: TKeyWord);
begin
  FRelations.Add(_KeyWordA, _KeyWordB);
end;

function TKeyWordList.GetRelated(_KeyWord: TKeyWord): TKeyWord;
begin
  FRelations.TryGetValue(_KeyWord, Result);
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

  FKeyWords := TKeyWordList.Create;

  with FKeyWords do begin

    Add(Integer(ktLineEnd), CRLF);
    Add(Integer(ktLineEnd), CR  );
    Add(Integer(ktLineEnd), LF  );

  end;

end;

destructor TCustomStringParser.Destroy;
begin
  FreeAndNil(FKeyWords);
  inherited Destroy;
end;

function TCustomStringParser.CheckKeys: Boolean;
var
  KW: TKeyWord;
begin

  if not SpecialSpace then

    for KW in FKeyWords do

      if CheckKey(KW) then begin

        KeyFound(KW);
        Exit(True);

      end;

  Result := False;

end;

procedure TCustomStringParser.KeyFound(const _KeyWord: TKeyWord);
begin
  KeyEvent(_KeyWord);
  Move(_KeyWord.KeyLength);
end;

procedure TCustomStringParser.IncLine(const _KeyWord: TKeyWord);
begin
  Inc(FLine);
  LinePos := Cursor + _KeyWord.KeyLength;
end;

function TCustomStringParser.CheckKey(const _KeyWord: TKeyWord): Boolean;
begin
  Result := SameText(_KeyWord.StrValue, Copy(Source, Cursor, _KeyWord.KeyLength));
end;

procedure TCustomStringParser.Move(_Incrementer: Int64);
begin
  Inc(FCursor, _Incrementer);
end;

procedure TCustomStringParser.KeyEvent(const _KeyWord: TKeyWord);
begin
  if TKeyWordType(_KeyWord.KeyType) = ktLineEnd then
    IncLine(_KeyWord);
end;

procedure TCustomStringParser.MoveEvent;
begin

  if not ItemBody then
    ItemBegin := Cursor;

  ItemBody := True;

end;

procedure TCustomStringParser.Read;
begin

  while (Cursor <= Length) and not FTerminated do

    if not CheckKeys then begin

      MoveEvent;
      Move;

    end;

  KeyEvent(TKeyWord.Create(Integer(ktSourceEnd), ''));

  { Оборачивать этот метод в try except чревато. В on E do получается уничтоженный объект E. }

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

function TCustomStringParser.SpecialSpace: Boolean;
begin
  Result := False;
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
