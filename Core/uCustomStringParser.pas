unit uCustomStringParser;

interface

uses
  { VCL }
  SysUtils, Generics.Collections;

type

  TKeyWord = record

    KeyType: Integer;
    StrValue: String;
    KeyLength: Integer;

    constructor Create(_KeyType: Integer; const _StrValue: String);

  end;

  TKeyWordList = class(TList<TKeyWord>)
  end;

  TKeyWordType = (ktSourceEnd);

  TCustomStringParser = class

  strict private

    FSource: String;
    FLength: Int64;
    FCursor: Int64;
    FKeyWords: TKeyWordList;

    function CheckKeys: Boolean;
    function CheckKey(const _KeyWord: TKeyWord): Boolean;
    procedure KeyFound(const _KeyWord: TKeyWord);

  protected

    procedure AddKeyWord(_KeyType: Integer; const _StrValue: String);
    procedure Move(_Incrementer: Int64 = 1);
    procedure KeyEvent(const _KeyWord: TKeyWord); virtual;
    procedure MoveEvent; virtual;

  public

    constructor Create(const _Source: String);
    destructor Destroy; override;

    procedure Read;

    property Source: String read FSource;
    property Length: Int64 read FLength;
    property Cursor: Int64 read FCursor;

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

constructor TCustomStringParser.Create(const _Source: String);
begin

  inherited Create;

  FSource := _Source;
  FLength := System.Length(_Source);

  FKeyWords := TKeyWordList.Create;
  FCursor := 1;

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

    ((FCursor + _KeyWord.KeyLength) < FLength) and
    SameText(_KeyWord.StrValue, Copy(FSource, FCursor, _KeyWord.KeyLength));

end;

procedure TCustomStringParser.KeyFound(const _KeyWord: TKeyWord);
begin
  KeyEvent(_KeyWord);
  Move(_KeyWord.KeyLength);
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
end;

procedure TCustomStringParser.MoveEvent;
begin
end;

procedure TCustomStringParser.Read;
begin

  while FCursor <= FLength do

    if not CheckKeys then begin

      MoveEvent;
      Move;

    end;

  KeyEvent(TKeyWord.Create(Integer(ktSourceEnd), ''));

end;

end.
