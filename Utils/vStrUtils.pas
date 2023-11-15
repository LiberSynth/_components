unit vStrUtils;

{TODO -oVasilyev -cComponents : -> Core }

interface

uses
  { VCL }
  SysUtils,
  { Utils }
  vTypes;

const

  LineEnds = [CR, LF];
  Signature_UTF8: RawByteString = AnsiChar($EF) + AnsiChar($BB) + AnsiChar($BF);

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
function CompleteStr(const Value: String; Completer: Char; Count: Integer; Before: Boolean = False; Cut: Boolean = True): String; overload;
function CompleteStr(const Value: String; Count: Integer; Before: Boolean = False; Cut: Boolean = True): String; overload;
function StrCount(const S: String; Pattern: String): Integer;
function QuoteStr(const S: String): String;
function UnquoteStr(const S: String): String;
function CutStr(var Value: String; CutCount: Integer): Boolean;
function SameText(const S: String; Patterns: array of String): Boolean; overload;

function StrMaskMatch(Value, Mask: String): Boolean;
function FileMaskMatch(const FileName, Mask: String): Boolean;
function FileMasksMatch(const FileName, Masks: String): Boolean;

function StrToArray(S: String; const Delim: String = ';'; DelimBehind: Boolean = True): TStringArray;
function ArrayToStr(const SA: TStringArray; const Delim: String = ';'; DelimBehind: Boolean = False): String; overload;
function ArrayToStr(const IA: TIntegerArray; const Delim: String = ';'; DelimBehind: Boolean = False): String; overload;

function DecodeUTF8(Value: RawByteString): String;

function FormatDateTime(Value: TDateTime; Milliseconds: Boolean = False; EmptyZero: Boolean = True): String; overload;
function FormatDateTimeSorted(Value: TDateTime; Milliseconds: Boolean = False; EmptyZero: Boolean = True): String;
function FormatDateTimeToFileName(Value: TDateTime; EmptyZero: Boolean = True): String;
function FormatTime(Value: TDateTime; Milliseconds: Boolean = False; EmptyZero: Boolean = True): String;

function FormatNow(Milliseconds: Boolean = False; EmptyZero: Boolean = True): String;
function FormatNowSorted(Milliseconds: Boolean = False; EmptyZero: Boolean = True): String;
function FormatNowToFileName(EmptyZero: Boolean = True): String;

implementation

uses
  { VCL }
  Math,
  { Utils }
  vDataUtils;

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
      { TODO -oVasilyev : все ошибки здесь должы быть формализованы по генерации. Ќужен диалог или лог с параметром, на котором это произошло, иначе т€жело разбиратьс€ }
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

function CompleteStr(const Value: String; Completer: Char; Count: Integer; Before, Cut: Boolean): String;
var
  L: Integer;
begin

  L := Length(Value);
  if Cut and (L >= Count) then
    if Before then Result := Copy(Value, Count - 1, Count)
    else Result := Copy(Value, 1, Count)
  else
    if Before then Result := StringReplicate(Completer, Count - L) + Value
    else Result := Value + StringReplicate(Completer, Count - L);
end;

function CompleteStr(const Value: String; Count: Integer; Before: Boolean = False; Cut: Boolean = True): String;
begin
  Result := CompleteStr(Value, ' ', Count, Before, Cut);
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

function CutStr(var Value: String; CutCount: Integer): Boolean;
var
  L: Integer;
begin
  L := Length(Value);
  Result := L >= CutCount;
  if Result then Value := Copy(Value, 1, L - CutCount);
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
  S: String;
begin

  Result := '';
  for S in SA do
    Result := Format('%s%s%s', [Result, S, Delim]);

  if not DelimBehind then
    CutStr(Result, Length(Delim));

end;

function ArrayToStr(const IA: TIntegerArray; const Delim: String = ';'; DelimBehind: Boolean = False): String;
var
  i: Integer;
begin

  Result := '';
  for i in IA do
    Result := Format('%s%d%s', [Result, i, Delim]);

  if not DelimBehind then
    CutStr(Result, Length(Delim));

end;

function DecodeUTF8(Value: RawByteString): String;
begin
  if Copy(Value, 1, Length(Signature_UTF8)) = Signature_UTF8 then Value := Copy(Value, Length(Signature_UTF8) + 1, MaxInt);
  Result := UTF8ToString(Value);
end;

function FormatDateTime(Value: TDateTime; Milliseconds, EmptyZero: Boolean): String;
begin
  if EmptyZero and DoubleEqual(Value, 0) then Result := ''
  else if Milliseconds then Result := FormatDateTime('dd.mm.yyyy hh:nn:ss.zzz', Value)
  else Result := FormatDateTime('dd.mm.yyyy hh:nn:ss', Value);
end;

function FormatDateTimeSorted(Value: TDateTime; Milliseconds, EmptyZero: Boolean): String;
begin
  if EmptyZero and DoubleEqual(Value, 0) then Result := ''
  else if Milliseconds then Result := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Value)
  else Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', Value);
end;

function FormatDateTimeToFileName(Value: TDateTime; EmptyZero: Boolean): String;
begin
  if EmptyZero and DoubleEqual(Value, 0) then Result := ''
  else Result := FormatDateTime('yyyymmdd_hhnnss_zzz', Value);
end;

function FormatTime(Value: TDateTime; Milliseconds, EmptyZero: Boolean): String;
var
  D: Integer;
  H, N, S, Z: Word;
begin

  if EmptyZero and DoubleEqual(Value, 0) then Result := ''
  else begin

    D := Trunc(Value);
    DecodeTime(Value, H, N, S, Z);
    H := H + D * 24;

    Result := Format('%s:%s:%s', [

        CompleteStr(IntToStr(H), '0', 2, True),
        CompleteStr(IntToStr(N), '0', 2, True),
        CompleteStr(IntToStr(S), '0', 2, True)

    ]);

    if Milliseconds then

      Result := Format('%s.%s', [

          Result,
          CompleteStr(IntToStr(Z), '0', 3, True)

      ]);

  end;

end;

function FormatNow(Milliseconds, EmptyZero: Boolean): String;
begin
  Result := FormatDateTime(Now, Milliseconds, EmptyZero);
end;

function FormatNowSorted(Milliseconds, EmptyZero: Boolean): String;
begin
  Result := FormatDateTimeSorted(Now, Milliseconds, EmptyZero);
end;

function FormatNowToFileName(EmptyZero: Boolean): String;
begin
  Result := FormatDateTimeToFileName(Now, EmptyZero);
end;

end.
