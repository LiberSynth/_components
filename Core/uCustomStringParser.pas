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

  TKeyWordList = class(TList<TKeyWord>)
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
    function CheckKey(const _KeyWord: TKeyWord): Boolean;
    procedure KeyFound(const _KeyWord: TKeyWord);
    procedure IncLine(const _KeyWord: TKeyWord);

  protected

    procedure AddKeyWord(_KeyType: Integer; const _StrValue: String);
    procedure Move(_Incrementer: Int64 = 1);
    procedure KeyEvent(const _KeyWord: TKeyWord); virtual;
    procedure MoveEvent; virtual;
    procedure Terminate;
    function ReadItem: String;

    property ItemBody: Boolean read FItemBody write FItemBody;
    property ItemBegin: Int64 read FItemBegin write FItemBegin;

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

    constructor Create(const _Message: String; _Line, _Position: Int64);
    constructor CreateFmt(const _Message: String; const _Args: array of const; _Line, _Position: Int64);

  end;

implementation

{ TKeyWord }

constructor TKeyWord.Create(_KeyType: Integer; const _StrValue: String);
begin

  KeyType := _KeyType;
  StrValue := _StrValue;
  KeyLength := Length(StrValue);

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

  AddKeyword(Integer(ktLineEnd), CRLF);
  AddKeyword(Integer(ktLineEnd), CR  );
  AddKeyword(Integer(ktLineEnd), LF  );

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

  for KW in FKeyWords do

    if CheckKey(KW) then begin

      KeyFound(KW);
      Exit(True);

    end;

  Result := False;

end;

function TCustomStringParser.CheckKey(const _KeyWord: TKeyWord): Boolean;
begin

  Result :=

    ((Cursor + _KeyWord.KeyLength) < Length) and
    SameText(_KeyWord.StrValue, Copy(Source, Cursor, _KeyWord.KeyLength));

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

procedure TCustomStringParser.AddKeyWord(_KeyType: Integer; const _StrValue: String);
begin
  FKeyWords.Add(TKeyWord.Create(_KeyType, _StrValue));
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

  try

    while (Cursor <= Length) and not FTerminated do

      {TODO -oVasilyevSM -cTCustomStringParser : Попробовать сделать мягкий цикл,
        не смог прочитать - пропустил. Хотя это и против идеи скрипта, типа есть
        синтаксис, если он нарушен, отменяем его целиком. Надо почитать в
        концепциях }
      if not CheckKeys then begin

        MoveEvent;
        Move;

      end;

    KeyEvent(TKeyWord.Create(Integer(ktSourceEnd), ''));

  except
    on E: Exception do
      raise EStringParserException.CreateFmt('%s: %s', [E.ClassName, E.Message], Line, Cursor - LinePos + 1);
  end;

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

end.
