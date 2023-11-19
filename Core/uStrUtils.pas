unit uStrUtils;

(*********************************************************)
(*                                                       *)
(*                        Hello!)                        *)
(*                                                       *)
(*********************************************************)

{ TODO -oVasilyevSM -cVCore : ”пор€дочить и подписать все группы функций }
interface

uses
  { VCL }
  SysUtils, Math,
  { vSoft }
  uConsts, uTypes, uDataUtils;

function PosOf(Patterns: String; const S: String; Start: Integer = 1): Integer;
function ReadStrTo(var S: String; const Pattern: String; WithPattern: Boolean = False): String;
function LastPos(const Pattern, S: String): Integer;
function StringReplicate(const Pattern: String; Count: Cardinal): String;
function SpaceReplicate(Count: Cardinal): String;
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

function ShiftText(const Value: String; Level: ShortInt; Interval: Byte = 2): String; overload;
procedure ShiftText(Level: ShortInt; Interval: Byte; var Value: String); overload;
procedure ShiftText(Level: ShortInt; var Value: String); overload;

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

function IsHexChar(const Value: String): Boolean;
function IsHexCharStr(const Value: String): Boolean;
function HexCharStrToStr(const Value: String): String;

{ v Simple types - string conversions v  - должны жить здесь, иначе будет циркул€рна€ ссылка }
function BooleanToStr(Value: Boolean): String;
function StrToBoolean(const S: String): Boolean;
function DoubleToStr(Value: Double): String;
function StrToDouble(const S: String): Double;
function DateTimeToStr(Value: TDateTime): String;
function GUIDToStr(const Value: TGUID) : String;
function StrToGUID(const Value: String): TGUID;
function StrToDateTime(const S: String): TDateTime;
function BLOBToStr(const Value: BLOB): String;
function StrToBLOB(const S: String): BLOB;
{ ^ Simple types - string conversions ^ }

implementation

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

function SpaceReplicate(Count: Cardinal): String;
begin
  Result := StringReplicate(' ', Count);
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

function ShiftText(const Value: String; Level: ShortInt; Interval: Byte): String;
var
  L: Integer;
  Indent: String;
  CRLFTerminated: Boolean;
begin

  if Level = 0 then Exit(Value);

  L := Length(Value);
  CRLFTerminated := Value[L - 1] + Value[L] = CRLF;
  Indent := SpaceReplicate(Abs(Level) * Interval);

  if Level > 0 then begin { Right }

    Result := Indent + StringReplace(Value, CRLF, CRLF + Indent, [rfReplaceAll]);
    if CRLFTerminated then
      Result := Copy(Result, 1, Length(Result) - Length(Indent));

  end else begin { Left }

    Result := Copy(Value, Length(Indent) + 1, L);
    Result := StringReplace(Result, CRLF + Indent, CRLF, [rfReplaceAll]);

  end;

end;

procedure ShiftText(Level: ShortInt; Interval: Byte; var Value: String);
begin
  Value := ShiftText(Value, Level, Interval);
end;

procedure ShiftText(Level: ShortInt; var Value: String);
begin
  ShiftText(Level, 2, Value);
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
  if Copy(Value, 1, Length(BOM_UTF8)) = BOM_UTF8 then Value := Copy(Value, Length(BOM_UTF8) + 1, MaxInt);
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

function IsHexChar(const Value: String): Boolean;
var
  S: String;
  i: Integer;
begin

  Result := (Length(Value) > 2) and (Length(Value) <= 4);

  if Result then begin

    S := Copy(Value, 3, 2);
    for i := 1 to Length(S) do
      if not CharInSet(S[i], HexCharsSet) then Exit(False);

  end;

end;

function IsHexCharStr(const Value: String): Boolean;
var
  i: Integer;
  SA: TStringArray;
begin

  SA := StrToArray(Value, SC_HEX_CHAR_SIGN, False);
  Result := Length(SA) > 0;
  for i := Low(SA) to High(SA) do
    if not IsHexChar(SC_HEX_CHAR_SIGN + SA[i]) then
      Exit(False);

end;

function HexCharStrToStr(const Value: String): String;

  procedure _Raise;
  const
    SC_Format = '''%s'' is not a hex';
  begin
    raise Exception.CreateFmt(SC_Format, [Value]);
  end;

  procedure _Check(const S: String);
  var
    i: Integer;
  begin
    for i := 1 to Length(S) do
      if not CharInSet(S[i], HexCharsSet) then _Raise;
  end;

var
  i: Integer;
  SA: TStringArray;
begin

  SA := StrToArray(Value, SC_HEX_CHAR_SIGN, False);
  if Length(SA) = 0 then _Raise;
  SetLength(Result, Length(SA));
  for i := Low(SA) to High(SA) do begin

    _Check(SA[i]);
    Result[i + 1] := Char(StrToInt('$' + SA[i]));
  end;
end;

function BooleanToStr(Value: Boolean): String;
begin
  if Value then Result := 'True'
  else Result := 'False';
end;

function StrToBoolean(const S: String): Boolean;
begin

  if SameText(S, 'FALSE') then Exit(False);
  if SameText(S, 'TRUE') then Exit(True);

  raise EConvertError.CreateFmt('%s is not a Boolean value', [S]);

end;

function DoubleToStr(Value: Double): String;
begin
  Result := StringReplace(FloatToStr(Value), {$IFNDEF DELPHI2010}FormatSettings.{$ENDIF}DecimalSeparator, '.', []);
end;

function StrToDouble(const S: String): Double;
begin
  Result := StrToFloat(S);
end;

function DateTimeToStr(Value: TDateTime): String;
begin
  FormatDateTime(Value, True);
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

function StrToGUID(const Value: String): TGUID;
begin
  if not TryStrToGUID(Value, Result) then
    raise EConvertError.CreateFmt('Error converting String ''%s'' to GUID', [Value]);
end;

function StrToDateTime(const S: String): TDateTime;
begin
  Result := SysUtils.StrToDateTime(S);
end;

function BLOBToStr(const Value: BLOB): String;
begin
  Result := RawByteStringToHex(Value);
end;

function StrToBLOB(const S: String): BLOB;
begin
  Result := HexToRawByteString(S);
end;

end.
