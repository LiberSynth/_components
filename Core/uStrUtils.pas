unit uStrUtils;

(*********************************************************)
(*                                                       *)
(*                        Hello!)                        *)
(*                                                       *)
(*********************************************************)

{ TODO -oVasilyevSM -cuStrUtils: Проискать на лишние функции }

interface

uses
  { VCL }
  SysUtils,
  { vSoft }
  uConsts, uTypes, uDataUtils;

{ v Преобразование основных типов данных в строку и обратно v }
function StrIsBoolean(const S: String): Boolean;
function StrIsGUID(const Value: String): Boolean;

{ TODO -oVasilyevSM -cuStrUtils: Продолжение следует: Extended, AnsiString, BLOB }
function BooleanToStr(Value: Boolean): String;
function StrToBoolean(const S: String): Boolean;
function IntToStr(Value: Integer): String;
function StrToInt(const Value: String): Integer;
function BigIntToStr(Value: Int64): String;
function StrToBigInt(const Value: String): Int64;
function DoubleToStr(Value: Double): String;
function StrToDouble(const Value: String): Double;
function DateTimeToStr(Value: TDateTime): String;
function StrToDateTime(const Value: String): TDateTime;
function GUIDToStr(const Value: TGUID) : String;
function StrToGUID(const Value: String): TGUID;
function BLOBToHexStr(const Value: BLOB): String;
function HexStrToBLOB(const Value: String): BLOB;
function DataToStr(const Value: TData): String;
function DataToGUID(const Value: TData): TGUID;
{ ^ Преобразование основных типов данных в строку и обратно ^ }

{ v Для парсинга и автоскриптов v }
function PosOf(Patterns: String; const Value: String; Start: Integer = 1): Integer; overload;
function PosOf(const Patterns: TStringArray; const Value: String): Integer; overload;
function ReadStrTo(var S: String; const Pattern: String; WithPattern: Boolean = False): String;
function LastPos(const Pattern, Value: String): Integer;
function StringReplicate(const Pattern: String; Count: Cardinal): String;
function SpaceReplicate(Count: Cardinal): String;
function CompleteStr(const Value: String; Completer: Char; Count: Integer; Before: Boolean = False; Cut: Boolean = True): String; overload;
function CompleteStr(const Value: String; Count: Integer; Before: Boolean = False; Cut: Boolean = True): String; overload;
function StrCount(const Value: String; Pattern: String): Integer;
function QuoteStr(const Value: String; const Quote: Char = ''''): String;
function UnquoteStr(const Value: String; const Quote: Char = ''''): String;
function DoubleStr(const Value: String; const Quote: Char = ''''): String;
function UndoubleStr(const Value: String; const Quote: Char = ''''): String;
function CutStr(var Value: String; Count: Integer): Boolean;
function SameText(const Value: String; Patterns: TStringArray): Boolean; overload;

function StrMaskMatch(Value, Mask: String): Boolean;
function FileMaskMatch(const FileName, Mask: String): Boolean;
function FileMasksMatch(const FileName, Masks: String): Boolean;

function ShiftText(const Value: String; Level: ShortInt; Interval: Byte = 2): String; overload;
procedure ShiftText(Level: ShortInt; Interval: Byte; var Value: String); overload;
procedure ShiftText(Level: ShortInt; var Value: String); overload;
{ ^ Для парсинга и автоскриптов  ^ }

{ v Стандартное форматирование дат v }
{ v !!! Эти форматы строго зашиты в алгоритм функции StrToDateTime !!! v }
function FormatDateTime(Value: TDateTime; Milliseconds: Boolean = False; EmptyZero: Boolean = True; ShowZeroDate: Boolean = False; ShowZeroTime: Boolean = False): String; overload;
function FormatDateTimeSorted(Value: TDateTime; Milliseconds: Boolean = False; EmptyZero: Boolean = True): String;
function FormatDateTimeToFileName(Value: TDateTime; EmptyZero: Boolean = True): String;
function FormatTime(Value: TDateTime; Milliseconds: Boolean = False; EmptyZero: Boolean = True): String;

function FormatNow(Milliseconds: Boolean = False; EmptyZero: Boolean = True): String;
function FormatNowSorted(Milliseconds: Boolean = False; EmptyZero: Boolean = True): String;
function FormatNowToFileName(EmptyZero: Boolean = True): String;
{ ^ Стандартное форматирование дат ^ }

function StrToArray(S: String; const Delim: String = ';'; DelimBehind: Boolean = True): TStringArray;
function ArrayToStr(const SA: TStringArray; const Delim: String = ';'; DelimBehind: Boolean = False): String; overload;
function ArrayToStr(const IA: TIntegerArray; const Delim: String = ';'; DelimBehind: Boolean = False): String; overload;
function ExistsInArray(const SA: TStringArray; const Value: String): Boolean;
procedure AddToStringArray(var SA: TStringArray; const Value: String; IgnoreEmpty: Boolean = False; Distinct: Boolean = False);

procedure CleanUpAnsiString(var Value: AnsiString);
procedure CleanUpString(var Value: String);

function WordToBOM(Value: Word): TBOM;
function BOMToStr(Value: TBOM): String;
function UTF16DataToStr(const Data: TData; BOM: TBOM): String;

function DecodeUTF8(Value: RawByteString): String;

function IsHexChar(const Value: String): Boolean;
function IsHexCharStr(const Value: String): Boolean;
function HexCharStrToStr(const Value: String): String;

function WrapGUIDStr(var Value: String): Boolean;

function GetFloatStr(const S: String): String;

implementation

function StrIsBoolean(const S: String): Boolean;
begin

  Result :=

      SameText(S, 'FALSE') or
      SameText(S, 'TRUE') or
      SameText(S, '0') or
      SameText(S, '1');

end;

function StrIsGUID(const Value: String): Boolean;

  function _CheckStr(const S: String): Boolean;
  const
    C_DashPositions = [9, 14, 19, 24];
  var
    i: Integer;
  begin

    for i := 1 to 36 do

      if i in C_DashPositions then

        if S[i] <> '-' then Exit(False)
        else

      else if not CharInSet(S[i], SC_HEX_CHARS) then Exit(False);

    Result := True;

  end;

var
  L: Integer;
begin

  L := Length(Value);
  Result := L in [36, 38];
  if Result then
    if L = 38 then Result := (Value[1] = '{') and (Value[38] = '}') and _CheckStr(Copy(Value, 2, 36))
    else Result := _CheckStr(Value);

end;

function BooleanToStr(Value: Boolean): String;
begin
  if Value then Result := 'True'
  else Result := 'False';
end;

function StrToBoolean(const S: String): Boolean;
begin

  if SameText(S, 'FALSE') or SameText(S, '0') then Exit(False);
  if SameText(S, 'TRUE' ) or SameText(S, '1') then Exit(True );

  raise EConvertError.CreateFmt('%s is not a Boolean value', [S]);

end;

function IntToStr(Value: Integer): String;
begin
  Result := SysUtils.IntToStr(Value);
end;

function StrToInt(const Value: String): Integer;
begin
  Result := SysUtils.StrToInt(Value);
end;

function BigIntToStr(Value: Int64): String;
begin
  Result := SysUtils.IntToStr(Value);
end;

function StrToBigInt(const Value: String): Int64;
begin
  Result := SysUtils.StrToInt64(Value);
end;

function DoubleToStr(Value: Double): String;
begin
  Result := SysUtils.FloatToStr(Value);
end;

function StrToDouble(const Value: String): Double;
begin
  { TODO -oVasilyevSM -cStrToDouble: Дельфина округляет до 6 знаков после запятой. }
  Result := SysUtils.StrToFloat(GetFloatStr(Value));
end;

function DateTimeToStr(Value: TDateTime): String;
begin
  Result := FormatDateTime(Value, True);
end;

function StrToDateTime(const Value: String): TDateTime;

  procedure _RaiseConvertDateTimeError;
  begin
    raise EConvertError.CreateFmt('%s is not a DateTime value', [Value]);
  end;

var
  V: String;

  function _CheckStrictDate: Boolean;
  begin

    Result :=

        CharInSet(V[ 1], SC_INTEGER_CHARS) and
        CharInSet(V[ 2], SC_INTEGER_CHARS) and
        (V[ 3] = '.') and
        CharInSet(V[ 4], SC_INTEGER_CHARS) and
        CharInSet(V[ 5], SC_INTEGER_CHARS) and
        (V[ 6] = '.') and
        CharInSet(V[ 7], SC_INTEGER_CHARS) and
        CharInSet(V[ 8], SC_INTEGER_CHARS) and
        CharInSet(V[ 9], SC_INTEGER_CHARS) and
        CharInSet(V[10], SC_INTEGER_CHARS);

  end;

  function _CheckSortedDate: Boolean;
  begin

    Result :=

        CharInSet(V[ 1], SC_INTEGER_CHARS) and
        CharInSet(V[ 2], SC_INTEGER_CHARS) and
        CharInSet(V[ 3], SC_INTEGER_CHARS) and
        CharInSet(V[ 4], SC_INTEGER_CHARS) and
        (V[ 5] = '-') and
        CharInSet(V[ 6], SC_INTEGER_CHARS) and
        CharInSet(V[ 7], SC_INTEGER_CHARS) and
        (V[ 8] = '-') and
        CharInSet(V[ 9], SC_INTEGER_CHARS) and
        CharInSet(V[10], SC_INTEGER_CHARS);

  end;

var
  TimePart: String;
  TimePartLength: Integer;

  function _CheckInt: Boolean;
  var
    i: Integer;
  begin

    for i := 1 to TimePartLength do
      if not CharInSet(TimePart[1], SC_INTEGER_CHARS) then
        Exit(False);

    Result := True;

  end;

var
  D, M, Y, H, N, S, Z: Word;
  L: Integer;
begin

  Result := 0; H := 0; N := 0; S := 0; Z := 0;
  L := Length(Value);

  { Одна дата это точно 10 символов }
  if (Pos(':', Value) = 0) and (L < 10) then
    _RaiseConvertDateTimeError;

  { ДАТА это 10 символов }
  if L >= 10 then begin

    V := Copy(Value, 1, 10);
    { Среди них должны быть 2 разделителя, иначе это отдельно время или бог знает что }
    if (StrCount(V, '.') = 2) or (StrCount(V, '-') = 2) then begin

      { Дата (может быть извлечена и без наличия времени в строке) }
      if _CheckStrictDate then begin

        D := StrToInt(Copy(V, 1, 2));
        M := StrToInt(Copy(V, 4, 2));
        Y := StrToInt(Copy(V, 7, 4));

        Result := EncodeDate(Y, M, D);
        V := Copy(Value, 11, L);

      end else if _CheckSortedDate then begin

        Y := StrToInt(Copy(V, 1, 4));
        M := StrToInt(Copy(V, 6, 2));
        D := StrToInt(Copy(V, 9, 2));

        Result := EncodeDate(Y, M, D);
        V := Copy(Value, 11, L);

      end else _RaiseConvertDateTimeError;

    end else V := Value; // это L >= 10, но в первой части не дата по разделителям

  end else V := Value; // это L <= 10, то есть, там или время или неизвестно что

  { И здесь уже в V точно лежит остаток строки без даты, была она там иил нет. Проверияем. }

  { Есть что-то кроме даты }
  if Length(V) > 0 then begin

    if V[1] = ' ' then V := Copy(V, 2, L);
    { Минимальное время это 3:5, иначе там не время }
    if (Length(V) < 3) or (Pos(':', V) = 0) then
      _RaiseConvertDateTimeError;

    { ВРЕМЯ (все составляющие могут быть без упреждающих нулей) }

    { Часы }
    TimePart := ReadStrTo(V, ':');
    TimePartLength := Length(TimePart);
    { Длина строки часов 1 или 2 и это только цифры }
    if (TimePartLength in [1, 2]) and _CheckInt then begin

      H := StrToInt(TimePart);
      if H > 24 then _RaiseConvertDateTimeError;

    end else _RaiseConvertDateTimeError;

    { Минуты }
    TimePart := ReadStrTo(V, ':');
    TimePartLength := Length(TimePart);
    { Длина строки минут 1 или 2 и это только цифры }
    if (TimePartLength in [1, 2]) and _CheckInt then begin

      N := StrToInt(TimePart);
      if N > 60 then _RaiseConvertDateTimeError;

    end else _RaiseConvertDateTimeError;

    { Секунды }
    TimePart := ReadStrTo(V, '.');
    TimePartLength := Length(TimePart);
    { Секунд может не быть }
    if TimePartLength > 0 then

      { Длина строки секунд, если уж они есть,  1 или 2 и это только цифры }
      if (TimePartLength in [1, 2]) and _CheckInt then begin

        S := StrToInt(TimePart);
        if S > 60 then _RaiseConvertDateTimeError;

      end else _RaiseConvertDateTimeError;

    { Миллисекунды }
    TimePart := V;
    TimePartLength := Length(TimePart);
    { Их тоже может не быть }
    if TimePartLength > 0 then begin

      { Дробная часть секунды не больше трех знаков, иначе EncodeTime выламывается. }
      if TimePartLength > 3 then
        _RaiseConvertDateTimeError;

      { Длина строки миллисекунд, если уж они есть, 1, 2 или 3 и это только цифры }
      if (TimePartLength in [1..3]) and _CheckInt then
        Z := StrToInt(TimePart);

    end;

  end;

  Result := Result + EncodeTime(H, N, S, Z);

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
var
  S: String;
begin

  if StrIsGUID(Value) then begin

    if Length(Value) = 38 then S := Copy(S, 2, 36)
    else S := Value;

    Result.D1    := Cardinal(SysUtils.StrToInt('$' + Copy(S,  1, 8)));
    Result.D2    :=          SysUtils.StrToInt('$' + Copy(S, 10, 4));
    Result.D3    :=          SysUtils.StrToInt('$' + Copy(S, 15, 4));
    Result.D4[0] :=          SysUtils.StrToInt('$' + Copy(S, 20, 2));
    Result.D4[1] :=          SysUtils.StrToInt('$' + Copy(S, 22, 2));
    Result.D4[2] :=          SysUtils.StrToInt('$' + Copy(S, 25, 2));
    Result.D4[3] :=          SysUtils.StrToInt('$' + Copy(S, 27, 2));
    Result.D4[4] :=          SysUtils.StrToInt('$' + Copy(S, 29, 2));
    Result.D4[5] :=          SysUtils.StrToInt('$' + Copy(S, 31, 2));
    Result.D4[6] :=          SysUtils.StrToInt('$' + Copy(S, 33, 2));
    Result.D4[7] :=          SysUtils.StrToInt('$' + Copy(S, 35, 2));

  end else raise EConvertError.CreateFmt('Error converting String ''%s'' to GUID', [Value]);

end;

function BLOBToHexStr(const Value: BLOB): String;
var
  P: Pointer;
  i: Integer;
  B: Byte;
begin

  SetLength(Result, Length(Value) * 2 + 2);
  Result[1] := '0';
  Result[2] := 'x';
  P := Pointer(Value);

  for i := 1 to Length(Value) do begin

    B := Byte(Pointer(Integer(P) + i - 1)^);
    Result[i * 2 + 1] := AC_HEX_CHARS[B div 16];
    Result[i * 2 + 2] := AC_HEX_CHARS[B mod 16];

  end;

end;

function HexStrToBLOB(const Value: String): BLOB;
var
  i: Integer;
  B: Byte;
begin

  SetLength(Result, (Length(Value) - 2) div 2);

  for i := 1 to Length(Result) do begin

    B := StrToInt('$' + Value[i * 2 + 1] + Value[i * 2 + 2]);
    Byte(Result[i]) := B;

  end;

end;

function DataToStr(const Value: TData): String;
var
  L: Integer;
begin
  L := Length(Value);
  SetLength(Result, L div 2);
  Move(Value[0], Result[1], L);
end;

function DataToGUID(const Value: TData): TGUID;
begin
  Move(Value[0], Result, 16);
end;

function PosOf(Patterns: String; const Value: String; Start: Integer): Integer;
var
  Pt: String;

  function _Pos: Integer;
  var
    i, L, LP: Integer;
    Token: String;
  begin

    LP := Length(Pt);
    L := Length(Value) - LP + 1;

    for i := Start to L do begin

      Token := Copy(Value, i, LP);
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

function PosOf(const Patterns: TStringArray; const Value: String): Integer;
var
  S: String;
  p: Integer;
begin

  Result := MaxInt;
  for S in Patterns do begin

    p := Pos(S, Value);
    if p > 0 then
      Result := Min(Result, p);

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

function LastPos(const Pattern, Value: String): Integer;
var
  i, pl: Integer;
begin

  pl := Length(Pattern);
  for i := Length(Value) - pl + 1 downto 1 do
    if Copy(Value, i, pl) = Pattern then Exit(i);

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
  if Cut and (L > Count) then

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

function StrCount(const Value: String; Pattern: String): Integer;
var
  i, p: Integer;
begin

  Result := 0;
  i := 1;
  repeat

    p := Pos(Pattern, Copy(Value, i, Length(Value)));
    if p = 0 then Exit;
    Inc(Result);
    Inc(i, p);

  until i > Length(Value) - Length(Pattern) + 1;

end;

function QuoteStr(const Value: String; const Quote: Char): String;
begin
  Result := Quote + StringReplace(Value, Quote, Quote + Quote, [rfReplaceAll]) + Quote;
end;

function UnquoteStr(const Value: String; const Quote: Char): String;
var
  L: Integer;
begin

  L := Length(Value);
  if

      (L > 1) and
      (Value[1] = Quote) and
      (Value[L] = Quote)

  then begin

    Result := Copy(Value, 2, L - 2);
    Result := StringReplace(Result, Quote + Quote, Quote, [rfReplaceAll]);

  end else Result := Value;

end;

function DoubleStr(const Value: String; const Quote: Char = ''''): String;
begin
  Result := StringReplace(Value, Quote, Quote + Quote, [rfReplaceAll]);
end;

function UndoubleStr(const Value: String; const Quote: Char = ''''): String;
begin
  Result := StringReplace(Value, Quote + Quote, Quote, [rfReplaceAll]);
end;

function CutStr(var Value: String; Count: Integer): Boolean;
var
  L: Integer;
begin
  L := Length(Value);
  Result := L >= Count;
  if Result then Value := Copy(Value, 1, L - Count);
end;

function SameText(const Value: String; Patterns: TStringArray): Boolean;
var
  i: Integer;
begin

  for i := Low(Patterns) to High(Patterns) do
    if SameText(Value, Patterns[i]) then Exit(True);

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

    if

        (FP = 0) and
        (Length(ExtMask) = 0)

    then

      Result := StrMaskMatch(FileName, NameMask)

    else

      Result := StrMaskMatch(Copy(FileName, 1, FP - 1), NameMask) and StrMaskMatch(Copy(FileName, FP + 1), ExtMask);

  end;

end;

function FileMasksMatch(const FileName, Masks: String): Boolean;
var
  SA: TStringArray;
  S: String;
begin

  SA := StrToArray(Masks, '|');

  for S in SA do
    if FileMaskMatch(FileName, S) then
      Exit(True);

  Result := False;

end;

function ShiftText(const Value: String; Level: ShortInt; Interval: Byte): String;
var
  L: Integer;
  Indent: String;
  CRLFTerminated: Boolean;
begin

  L := Length(Value);
  if L > 0 then begin

    CRLFTerminated := Value[L - 1] + Value[L] = CRLF;
    Indent := SpaceReplicate(Abs(Level) * Interval);

    if Level > 0 then begin { Right }

      Result := Indent + StringReplace(Value, CRLF, CRLF + Indent, [rfReplaceAll]);
      if CRLFTerminated then
        Result := Copy(Result, 1, Length(Result) - Length(Indent));

    end else if Level < 0 then begin { Left }

      Result := Copy(Value, Length(Indent) + 1, L);
      Result := StringReplace(Result, CRLF + Indent, CRLF, [rfReplaceAll]);

    end else Result := Value; { Nowhere }

  end else Result := '';

end;

procedure ShiftText(Level: ShortInt; Interval: Byte; var Value: String);
begin
  Value := ShiftText(Value, Level, Interval);
end;

procedure ShiftText(Level: ShortInt; var Value: String);
begin
  ShiftText(Level, 2, Value);
end;

const

  { v !!! Эти форматы строго зашиты в алгоритм функции StrToDateTime !!! v }
  { Поэтому, они должны лежать именно здесь, а не в uConsts. Это одно целое. }
  SC_STRICT_DATE_FORMAT     = 'dd.mm.yyyy hh:nn:ss';
  SC_STRICT_DATE_FORMAT_MS  = 'dd.mm.yyyy hh:nn:ss.zzz';
  SC_STRICT_DATE_FORMAT_WT  = 'dd.mm.yyyy';
  SC_STRICT_TIME_FORMAT     = 'hh:nn:ss';
  SC_STRICT_TIME_FORMAT_MS  = 'hh:nn:ss.zzz';
  SC_SORTING_DATE_FORMAT    = 'yyyy-mm-dd hh:nn:ss';
  SC_SORTING_DATE_FORMAT_MS = 'yyyy-mm-dd hh:nn:ss.zzz';
  { ^ !!! Эти форматы строго зашиты в алгоритм функции StrToDateTime !!! ^ }
  SC_FILENAME_DATE_FORMAT   = 'yyyymmdd_hhnnss_zzz';

function FormatDateTime(Value: TDateTime; Milliseconds, EmptyZero, ShowZeroDate, ShowZeroTime: Boolean): String;
begin

  if EmptyZero and DoubleEqual(Value, 0) then
    Result := ''
  else if not ShowZeroDate and (Trunc(Value) = 0) then
    Result := FormatTime(Value, Milliseconds, EmptyZero)
  else if not ShowZeroTime and DoubleEqual(Trunc(Value), Value) then
    Result := FormatDateTime(SC_STRICT_DATE_FORMAT_WT, Value)
  else if Milliseconds then
    Result := FormatDateTime(SC_STRICT_DATE_FORMAT_MS, Value)
  else
    Result := FormatDateTime(SC_STRICT_DATE_FORMAT, Value);

end;

function FormatDateTimeSorted(Value: TDateTime; Milliseconds, EmptyZero: Boolean): String;
begin

  if EmptyZero and DoubleEqual(Value, 0) then
    Result := ''
  else if Milliseconds then
    Result := FormatDateTime(SC_SORTING_DATE_FORMAT_MS, Value)
  else
    Result := FormatDateTime(SC_SORTING_DATE_FORMAT, Value);

end;

function FormatDateTimeToFileName(Value: TDateTime; EmptyZero: Boolean): String;
begin

  if EmptyZero and DoubleEqual(Value, 0) then
    Result := ''
  else
    Result := FormatDateTime(SC_FILENAME_DATE_FORMAT, Value);

end;

function FormatTime(Value: TDateTime; Milliseconds, EmptyZero: Boolean): String;
begin

  if EmptyZero and DoubleEqual(Value, 0) then
    Result := ''
  else if Milliseconds then
    Result := FormatDateTime(SC_STRICT_TIME_FORMAT_MS, Value)
  else
    Result := FormatDateTime(SC_STRICT_TIME_FORMAT, Value)

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

function ExistsInArray(const SA: TStringArray; const Value: String): Boolean;
var
  S: String;
begin

  for S in SA do
    if SameText(S, Value) then
      Exit(True);

  Result := False;

end;

procedure AddToStringArray(var SA: TStringArray; const Value: String; IgnoreEmpty: Boolean; Distinct: Boolean);
begin

  if

      (not IgnoreEmpty or (Length(Value) > 0)) and
      (not Distinct or not ExistsInArray(SA, Value))

  then begin

    SetLength(SA, Length(SA) + 1);
    SA[High(SA)] := Value;

  end;

end;

procedure CleanUpAnsiString(var Value: AnsiString);
var
  i: Integer;
begin

  for i := Length(Value) downto 1 do
    if Value[i] = #0 then
      Value := Copy(Value, 1, i - 1) + Copy(Value, i + 1, Length(Value));

end;

procedure CleanUpString(var Value: String);
var
  i: Integer;
begin

  for i := Length(Value) downto 1 do
    if Value[i] = #0 then
      Value := Copy(Value, 1, i - 1) + Copy(Value, i + 1, Length(Value));

end;

function WordToBOM(Value: Word): TBOM;
begin

  case Value of

    WC_BOM_FWD: Result := bomForward;
    WC_BOM_BWD: Result := bomBackward;

  else
    raise Exception.CreateFmt('Invalid BOM value %x', [Value]);
  end;

end;

function BOMToStr(Value: TBOM): String;
begin

  case Value of

    bomForward:  Result := 'FWD';
    bomBackward: Result := 'BWD';

  else
    Result := '?WD';
  end;

end;

function UTF16DataToStr(const Data: TData; BOM: TBOM): String;

    function _InvertData: TData;
    var
      i: Integer;
    begin

      SetLength(Result, Length(Data));
      for i := Low(Data) to High(Data) do
        if i mod 2 = 0 then Result[i] := Data[i + 1]
        else Result[i] := Data[i - 1];

    end;

begin
  if BOM = bomBackward then _InvertData;
  Result := DataToStr(Data);
end;

function DecodeUTF8(Value: RawByteString): String;
begin
  if Copy(Value, 1, Length(BOM_UTF8)) = BOM_UTF8 then Value := Copy(Value, Length(BOM_UTF8) + 1, MaxInt);
  Result := UTF8ToString(Value);
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
      if not CharInSet(S[i], SC_HEX_CHARS) then Exit(False);

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
      if not CharInSet(S[i], SC_HEX_CHARS) then _Raise;
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

function WrapGUIDStr(var Value: String): Boolean;
begin
  Result := StrIsGUID(Value);
  if Result and (Length(Value) = 36) then
    Value := Format('{%s}', [Value]);
end;

function GetFloatStr(const S: String): String;
begin
  Result := StringReplace(S,      '.', {$IFNDEF DELPHI2010}FormatSettings.{$ENDIF}DecimalSeparator, []);
  Result := StringReplace(Result, ',', {$IFNDEF DELPHI2010}FormatSettings.{$ENDIF}DecimalSeparator, []);
end;

end.
