unit vStrUtils;

interface

uses
  { VCL }
  SysUtils,
  { Utils }
  vTypes;

const

  LineEnds = [CR, LF];

type

  TCustomParamsReader = class

  strict private

    FData: String;
    FPosition: Integer;

  protected

    procedure Step(_N: Integer = 1);
    function Lick(_Count: Integer): String;
    function Bite(_Count: Integer): String;
    function EndOf: Boolean;
    procedure Restore(_Position: Integer);

    function Discard(_WithoutEnds: Boolean = False): Boolean;
    function WordEnds: TSysCharSet; virtual;
    function Untouchables: TSysCharSet; virtual;
    function ReadWord: String;
    function LickWord: String;
    procedure StepToChar(_C: Char);

    procedure ReadInternal; virtual; abstract;

    property Data: String read FData;
    property Position: Integer read FPosition;

  public

    constructor CreateReader(const _String: String);

    procedure Read;

  end;

  TCustomStringsReader = class(TCustomParamsReader)

  protected

    function ReadString: String;

  end;

function PosOf(Patterns: String; const S: String; Start: Integer = 1): Integer;
function ReadStrTo(var S: String; const Pattern: String; WithPattern: Boolean = False): String;
function LastPos(const Pattern, S: String): Integer;
function StringReplicate(const Pattern: String; Count: Cardinal): String;
function CompleteStr(const Value: String; Completer: Char; Count: Integer): String;
function StrCount(const S: String; Pattern: String): Integer;
function QuoteStr(const S: String): String;
function UnquoteStr(const S: String): String;
function SameText(const S: String; Patterns: array of String): Boolean; overload;

function StrMaskMatch(Value, Mask: String): Boolean;
function FileMaskMatch(const FileName, Mask: String): Boolean;
function FileMasksMatch(const FileName, Masks: String): Boolean;

function StrToArray(S: String; const Delim: String = ';'; DelimBehind: Boolean = True): TStringArray;
function ArrayToStr(const SA: TStringArray; const Delim: String = ';'; DelimBehind: Boolean = False): String;

function GUIDToStr(const Value: TGUID) : String;
function StrToGUID(const Value: String): TGUID;

implementation

uses
  { VCL }
  Math;

{ TCustomParamsReader }

procedure TCustomParamsReader.Step(_N: Integer);
begin
  Inc(FPosition, _N);
end;

function TCustomParamsReader.Lick(_Count: Integer): String;
begin
  Result := Copy(FData, FPosition, _Count);
end;

function TCustomParamsReader.Bite(_Count: Integer): String;
begin
  Result := Lick(_Count);
  Step(_Count);
end;

function TCustomParamsReader.EndOf: Boolean;
begin
  Result := FPosition > Length(FData);
end;

procedure TCustomParamsReader.Restore(_Position: Integer);
begin
  FPosition := _Position;
end;

constructor TCustomParamsReader.CreateReader(const _String: String);
begin

  inherited Create;

  FData := _String;
  FPosition := 1;

end;

function TCustomParamsReader.Discard(_WithoutEnds: Boolean): Boolean;

  function _DiscardCharSet(_CharSet: TSysCharSet): Boolean;
  var
    C: Char;
  begin

    Result := False;
    while not EndOf do begin

      C := Lick(1)[1];
      if CharInSet(C, _CharSet) then begin

        Step;
        Result := True;

      end else Exit;

    end;

  end;

  function _DiscardBlanks: Boolean;
  const
    Blanks = [#0, ' ', TAB];
  begin
    Result := _DiscardCharSet(Blanks);
  end;

  function _DiscardLineEnds: Boolean;
  begin
    Result := not _WithoutEnds and _DiscardCharSet(LineEnds);
  end;

  function _DiscardSemi: Boolean;
  const
    Semi = [';', ','];
  begin
    Result := not _WithoutEnds and _DiscardCharSet(Semi);
  end;

  function _DiscardShortComments: Boolean;
  const
    ShortStarts = '--;//';
  begin

    Result := PosOf(ShortStarts, Lick(2)) = 1;
    if Result then
      while not EndOf do
        if CharInSet(Bite(1)[1], LineEnds) then Exit;

  end;

  function _DiscardLongComments: Boolean;
  const
    LongStarts  = '/*;(*';
    LongEnds: array[0..1] of String = ('*/', '*)');
  var
    Token: String;

    function _LongEnd: String;
    var
      i: Byte;
      LS: TStringArray;
    begin

      LS := StrToArray(LongStarts);
      for i := Low(LS) to High(LS) do
        if Token = LS[i] then Exit(LongEnds[i]);

      { We won't be here. It needs to synchronise LongStarts and LongEnds. }
      raise EParamsReadException.Create('Can not define long comment end sign', FPosition);

    end;

  var
    p: Integer;
    LE: String;
  begin

    Token := Lick(2);
    p := PosOf(LongStarts, Token);
    if p = 1 then begin

      LE := _LongEnd;
      p := PosOf(LE, FData, FPosition);
      if p = 0 then raise EParamsReadException.Create(SC_ParamRead_UnterminatedLongComment, FPosition);
      Step(p - FPosition + Length(LE));
      Exit(True);

    end;

    Result := False;

  end;

var
  Detected: Boolean;
begin

  Result := False;

  repeat

    Detected := _DiscardBlanks;
    Detected := _DiscardLineEnds or Detected;
    Detected := _DiscardSemi or Detected;
    Detected := _DiscardShortComments or Detected;
    Detected := _DiscardLongComments or Detected;
    Result := Result or Detected;

  until not Detected;

end;

procedure TCustomParamsReader.Read;
begin

  try

    while not EndOf do
      ReadInternal;

  finally
    FPosition := 1;
  end;

end;

function TCustomParamsReader.WordEnds: TSysCharSet;
begin
  Result := [CR, LF];
end;

function TCustomParamsReader.ReadWord: String;
var
  C: Char;
begin

  Result := '';
  repeat

    if EndOf then Exit;
    C := Bite(1)[1];

    if CharInSet(C, WordEnds) then begin

      if CharInSet(C, Untouchables) then Dec(FPosition);
      Exit;

    end;

    Result := Result + C;

  until Discard(True);

  if not EndOf then begin

    C := Lick(1)[1];
    if CharInSet(C, WordEnds) and (C <> ')') then Step;

  end;

end;

function TCustomParamsReader.LickWord: String;
var
  InitPos: Integer;
begin

  InitPos := FPosition;
  try

    Result := ReadWord;

  finally
    Restore(InitPos);
  end;

end;

procedure TCustomParamsReader.StepToChar(_C: Char);
begin

  while not (Lick(1) = _C) do begin

    Discard;
    while CharInSet(Lick(1)[1], LineEnds) do
      Step(1);

  end;

  Step(1);

end;

function TCustomParamsReader.Untouchables: TSysCharSet;
begin
  Result := [')'];
end;

function PosOf(Patterns: String; const S: String; Start: Integer): Integer;
var
  Pt: String;

  function _Pos: Integer;
  var
    i, L, LP: Integer;
    Token: String;
  begin

    LP := Length(Pt);
    L := Length(S) - LP + 1;

    for i := Start to L do begin

      Token := Copy(S, i, LP);
      if SameText(Token, Pt) then Exit(i);

    end;

    Result := 0;

  end;

var
  p: Integer;
begin

  Result := MaxInt;
  while Length(Patterns) > 0 do begin

    Pt := ReadStrTo(Patterns, ';');
    p := _Pos;
    if p > 0 then Result := Min(Result, p);

  end;

  if Result = MaxInt then Result := 0;

end;

function ReadStrTo(var S: String; const Pattern: String; WithPattern: Boolean): String;
var
  p: Integer;
begin

  p := Pos(Pattern, S);
  if p = 0 then begin

    Result := S;
    S := '';

  end else begin

    if WithPattern then Result := Copy(S, 1, p + Length(Pattern) - 1)
    else Result := Copy(S, 1, p - 1);
    p := p + Length(Pattern);
    S := Copy(S, p, Length(S));

  end;

end;

function LastPos(const Pattern, S: String): Integer;
var
  i, pl: Integer;
begin

  pl := Length(Pattern);
  for i := Length(S) - pl + 1 downto 1 do
    if Copy(S, i, pl) = Pattern then Exit(i);

  Result := 0;

end;

function StringReplicate(const Pattern: String; Count: Cardinal): String;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to Count - 1 do
    Result := Result + Pattern;
end;

function CompleteStr(const Value: String; Completer: Char; Count: Integer): String;
var
  L: Integer;
begin

  L := Length(Value);
  if L >= Count then Result := Copy(Value, 1, Count)
  else Result := Value + StringReplicate(Completer, Count - L);

end;

function StrCount(const S: String; Pattern: String): Integer;
var
  i, p: Integer;
begin

  Result := 0;
  i := 1;
  repeat

    p := Pos(Pattern, Copy(S, i, Length(S)));
    if p = 0 then Exit;
    Inc(Result);
    Inc(i, p);

  until i > Length(S) - Length(Pattern) + 1;

end;

function QuoteStr(const S: String): String;
begin
  Result := '''' + S + '''';
end;

function UnquoteStr(const S: String): String;
begin

  Result := S;
  if Length(Result) > 1 then begin

    if Result[1] = '''' then Result := Copy(Result, 2, Length(Result) - 1);
    if Result[Length(Result)] = '''' then Result := Copy(Result, 1, Length(Result) - 1);

  end;

end;

function SameText(const S: String; Patterns: array of String): Boolean;
var
  i: Integer;
begin

  for i := Low(Patterns) to High(Patterns) do
    if SameText(S, Patterns[i]) then Exit(True);

  Result := False;

end;

function StrMaskMatch(Value, Mask: String): Boolean;
var
  S: String;
  p: Integer;
begin

  if Mask = '*' then Exit(True);
  if Pos('*', Mask) = 0 then Exit(SameText(Value, Mask));
  if Pos('*', Mask) > 1 then begin

    S := ReadStrTo(Mask, '*');
    if SameText(S, Copy(Value, 1, Length(S))) then
      Value := Copy(Value, Length(S) + 1, Length(Value))
    else Exit(False);

  end;

  repeat

    if Pos('*', Mask) = 0 then begin

      S := ReadStrTo(Mask, '');
      p := PosOf(S, Value);
      Exit((p > 0) and (p = Length(Value) - Length(S) + 1))

    end else begin

      S := ReadStrTo(Mask, '*');
      if Length(S) > 0 then begin

        if PosOf(S, Value) = 0 then Exit(False)
        else ReadStrTo(Value, S);

      end;

    end;

  until Length(Mask) = 0;

  Result := True;

end;

function FileMaskMatch(const FileName, Mask: String): Boolean;
var
  MP, FP: Integer;
  NameMask, ExtMask: String;
begin

  MP := Pos('.', Mask);
  if MP = 0 then Result := StrMaskMatch(FileName, Mask)
  else begin

    NameMask := Copy(Mask, 1, MP - 1);
    ExtMask := Copy(Mask, MP + 1);
    FP := Pos('.', FileName);
    if (FP = 0) and (Length(ExtMask) = 0) then Result := StrMaskMatch(FileName, NameMask)
    else Result := StrMaskMatch(Copy(FileName, 1, FP - 1), NameMask) and StrMaskMatch(Copy(FileName, FP + 1), ExtMask);

  end;

end;

function FileMasksMatch(const FileName, Masks: String): Boolean;
var
  SA: TStringArray;
  i: Integer;
begin
  SA := StrToArray(Masks, '|');
  for i := Low(SA) to High(SA) do
    if FileMaskMatch(FileName, SA[i]) then Exit(True);
  Result := False;
end;

{ TCustomStringsReader }

function TCustomStringsReader.ReadString: String;

  function _ReadQuotedString: String;
  begin

    StepToChar('''');
    Result := '';
    while not EndOf do begin

      if Lick(1) = '''' then
        if Lick(2) = '''''' then Step(1)
        else Exit;

      Result := Result + Bite(1);

    end;

    if EndOf then raise EParamsReadException.Create(SC_UnterminatedString, Position);

  end;

var
  Quoted: Boolean;
  S: String;
begin

  S := LickWord;
  Quoted := (Length(S) > 0) and (S[1] = '''');
  if Quoted then S := _ReadQuotedString
  else S := ReadWord;
  Result := S;
  if Quoted then Step(1);

end;

function StrToArray(S: String; const Delim: String; DelimBehind: Boolean): TStringArray;
var
  i, L: Integer;
begin

  L := StrCount(S, Delim);
  if DelimBehind then Inc(L)
  else ReadStrTo(S, Delim);
  SetLength(Result, L);
  i := 0;

  while Length(S) > 0 do begin

    Result[i] := ReadStrTo(S, Delim);
    Inc(i);

  end;

end;

function ArrayToStr(const SA: TStringArray; const Delim: String; DelimBehind: Boolean): String;
var
  i: Integer;
begin

  Result := '';

  for i := Low(SA) to High(SA) do begin

    Result := Result + SA[i];
    if DelimBehind or (i < High(SA)) then Result := Result + Delim;

  end;

end;

function GUIDToStr(const Value: TGUID): String;
begin

  with Value do

    Result:= Format('%s-%s-%s-%s%s-%s%s%s%s%s%s', [

        IntToHex(D1, 8),
        IntToHex(D2, 4),
        IntToHex(D3, 4),
        IntToHex(D4[0], 2),
        IntToHex(D4[1], 2),
        IntToHex(D4[2], 2),
        IntToHex(D4[3], 2),
        IntToHex(D4[4], 2),
        IntToHex(D4[5], 2),
        IntToHex(D4[6], 2),
        IntToHex(D4[7], 2)

    ]);

end;

function TryStrToGUID(const S: String; var Value: TGUID): Boolean;

	function TryStrToGUID(Index: Integer): Boolean;

    function _CheckDelimiter(_Index: Integer): Boolean;
    begin
      Result := S[Index + _Index] = '-';
    end;

    function _TryStrToInt(_PartIndex, _PartLength: Integer; var _Value: Boolean): Integer;
    begin
      _Value := SysUtils.TryStrToInt('$' + Copy(S, Index + _PartIndex, _PartLength), Result);
    end;

    function _TryHexToLongword(_PartIndex, _PartLength: Integer; var _Value: Longword): Boolean;
    begin
      _Value := Longword(_TryStrToInt(_PartIndex, _PartLength, Result));
    end;

    function _TryHexToWord(_PartIndex, _PartLength: Integer; var _Value: Word): Boolean;
    begin
      _Value := _TryStrToInt(_PartIndex, _PartLength, Result);
    end;

    function _TryHexToByte(_PartIndex, _PartLength: Integer; var _Value: Byte): Boolean;
    begin
      _Value := _TryStrToInt(_PartIndex, _PartLength, Result);
    end;

	begin

    Result:=

        _CheckDelimiter(9 ) and
        _CheckDelimiter(14) and
        _CheckDelimiter(19) and
        _CheckDelimiter(24) and
        _TryHexToLongword(1, 8, Value.D1) and
        _TryHexToWord(10, 4, Value.D2) and
        _TryHexToWord(15, 4, Value.D3) and
        _TryHexToByte(20, 2, Value.D4[0]) and
        _TryHexToByte(22, 2, Value.D4[1]) and
        _TryHexToByte(25, 2, Value.D4[2]) and
        _TryHexToByte(27, 2, Value.D4[3]) and
        _TryHexToByte(29, 2, Value.D4[4]) and
        _TryHexToByte(31, 2, Value.D4[5]) and
        _TryHexToByte(33, 2, Value.D4[6]) and
        _TryHexToByte(35, 2, Value.D4[7]);

	end;

begin

  case Length(S) of

    36: Result := TryStrToGUID(0);
    38:

      if (S[1] = '{') and (S[38] = '}') then Result := TryStrToGUID(1)
      else Result := False;

  else
    Result := False;
  end;

end;

function StrToGUID(const Value: String): TGUID;
begin
  if not TryStrToGUID(Value, Result) then
    raise EConvertError.CreateFmt('Error converting String ''%s'' to GUID',[Value]);
end;

end.
