unit uDataUtils;

(*******************************************************************************************)
(*            _____          _____          _____          _____          _____            *)
(*           /\    \        /\    \        /\    \        /\    \        /\    \           *)
(*          /::\____\      /::\    \      /::\    \      /::\    \      /::\    \          *)
(*         /:::/    /      \:::\    \    /::::\    \    /::::\    \    /::::\    \         *)
(*        /:::/    /        \:::\    \  /::::::\    \  /::::::\    \  /::::::\    \        *)
(*       /:::/    /          \:::\    \ :::/\:::\    \ :::/\:::\    \ :::/\:::\    \       *)
(*      /:::/    /            \:::\    \ :/__\:::\    \ :/__\:::\    \ :/__\:::\    \      *)
(*     /:::/    /             /::::\    \ \   \:::\    \ \   \:::\    \ \   \:::\    \     *)
(*    /:::/    /     _____   /::::::\    \ \   \:::\    \ \   \:::\    \ \   \:::\    \    *)
(*   /:::/    /     /\    \ /:::/\:::\    \ \   \:::\ ___\ \   \:::\    \ \   \:::\____\   *)
(*  /:::/____/     /::\    /:::/  \:::\____\ \   \:::|    | \   \:::\____\ \   \:::|    |  *)
(*  \:::\    \     \:::\  /:::/    \::/    / :\  /:::|____| :\   \::/    / :\  /:::|____|  *)
(*   \:::\    \     \:::\/:::/    / \/____/ :::\/:::/    / :::\   \/____/ :::\/:::/    /   *)
(*    \:::\    \     \::::::/    /  \:::\   \::::::/    /  \:::\    \  |:::::::::/    /    *)
(*     \:::\    \     \::::/____/    \:::\   \::::/    /    \:::\____\ |::|\::::/    /     *)
(*      \:::\    \     \:::\    \     \:::\  /:::/    / :\   \::/    / |::| \::/____/      *)
(*       \:::\    \     \:::\    \     \:::\/:::/    / :::\   \/____/  |::|  ~|            *)
(*        \:::\    \     \:::\    \     \::::::/    /  \:::\    \      |::|   |            *)
(*         \:::\____\     \:::\____\     \::::/    /    \:::\____\     \::|   |            *)
(*          \::/    /      \::/    /      \::/____/      \::/    /      \:|   |            *)
(*           \/____/        \/____/        ~~             \/____/        \|___|            *)
(*                                                                                         *)
(*******************************************************************************************)

{ TODO 5 -oVasilyevSM -cuDataUtils: Где '//' - добавлять исполнение и отлаживать. Осталось: и Data/Extended. }
{ TODO 5 -oVasilyevSM -cuDataUtils: Похоже, что Double это действительно псевдоним Extended. Значения с большим
  количеством знаков урезаются одинаково. Странно только что в Win64 SizeOf(Extended) = 10, а не 16, как утверждает
  справка по RADStudio. }
{ TODO 5 -oVasilyevSM -cuDataUtils: Функции типа FloatToInt, которые могу округлять значение. Можно завести глобальный
  режим - округлять/не округлять и если не округлять, то возвращать исключение }
{ TODO 5 -oVasilyevSM -cCommon: Попробовать использовать дженерик для хранения широко-типизованных данных. Класс
  TValue<T>, и пересоздавать его при смене типа данных. А как он там будет с памятью орудовать - не наша проблема. }

interface

uses
  { VCL }
  SysUtils,
  { LiberSynth }
  uConsts, uTypes, uCore;

{ v Преобразование основных типов данных друг в друга. v }
{ Представлен полный набор, чтобы голову не ломать, как это делать в каждом отдельном сочетании. Логика простая,
  <Тип A>To<Тип B>. Типы перечислены в uParams, что не до конца правильно, поскольку он зависимый от uDataUtils. Это
  на подумать. <Тип> это любой элемент TParamDataType без префикса. Исключения: Int[eger], Str[ing], AnsiStr[ing]. }
function BooleanToInt(Value: Boolean): Integer;
function BooleanToBigInt(Value: Boolean): Int64;
function BooleanToFloat(Value: Boolean): Double;
function BooleanToExtended(Value: Boolean): Extended;
function BooleanToBLOB(Value: Boolean): BLOB;
function BooleanToData(Value: Boolean): TData;

function IntToBoolean(Value: Integer): Boolean;
function IntToBigInt(Value: Integer): Int64;
function IntToFloat(Value: Integer): Double;
function IntToExtended(Value: Integer): Extended;
function IntToDateTime(Value: Integer): TDateTime; // ~
function IntToBLOB(Value: Integer): BLOB;
function IntToData(Value: Integer): TData;

function BigIntToBoolean(Value: Int64): Boolean;
function BigIntToInt(Value: Int64): Integer;
function BigIntToFloat(Value: Int64): Double; // ~
function BigIntToExtended(Value: Int64): Extended; // ~
function BigIntToDateTime(Value: Int64): TDateTime; // ~
function BigIntToBLOB(Value: Int64): BLOB;
function BigIntToData(Value: Int64): TData;

function FloatToBoolean(Value: Double): Boolean;
function FloatToInt(Value: Double): Integer;
function FloatToBigInt(Value: Double): Int64; // ~
function FloatToExtended(Value: Double): Extended; // ~
function FloatToDateTime(Value: Double): TDateTime; // ~
function FloatToBLOB(Value: Double): BLOB;
function FloatToData(Value: Double): TData;

function ExtendedToBoolean(Value: Extended): Boolean;
function ExtendedToInt(Value: Extended): Integer;
function ExtendedToBigInt(Value: Extended): Int64; // ~
function ExtendedToFloat(Value: Extended): Double; // ~
function ExtendedToDateTime(Value: Extended): TDateTime; // ~
function ExtendedToBLOB(Value: Extended): BLOB;
function ExtendedToData(Value: Extended): TData; //

function DateTimeToInt(const Value: TDateTime): Integer; // ~
function DateTimeToBigInt(const Value: TDateTime): Int64; // ~
function DateTimeToFloat(const Value: TDateTime): Double;
function DateTimeToExtended(const Value: TDateTime): Extended;
function DateTimeToBLOB(const Value: TDateTime): BLOB;
function DateTimeToData(const Value: TDateTime): TData;

function GUIDToBLOB(const Value: TGUID): BLOB;
function GUIDToData(const Value: TGUID): TData;

function BLOBToBoolean(const Value: BLOB): Boolean;
function BLOBToInt(const Value: BLOB): Integer;
function BLOBToBigInt(const Value: BLOB): Int64;
function BLOBToFloat(const Value: BLOB): Double;
function BLOBToExtended(const Value: BLOB): Extended;
function BLOBToDateTime(const Value: BLOB): TDateTime;
function BLOBToGUID(const Value: BLOB): TGUID;
function BLOBToData(const Value: BLOB): TData;

function DataToBoolean(const Value: TData): Boolean;
function DataToInt(const Value: TData): Integer;
function DataToBigInt(const Value: TData): Int64;
function DataToFloat(const Value: TData): Double;
function DataToExtended(const Value: TData): Extended; //
function DataToDateTime(const Value: TData): TDateTime;
function DataToGUID(const Value: TData): TGUID;
function DataToBLOB(const Value: TData): BLOB;
{ ^ Преобразование основных типов данных друг в друга. Полный набор. ^ }

function DataToAnsiStr(const Value: TData): AnsiString;
function DataToStr(const Value: TData): String;

{ v Cравнение действительных чисел с отбросом "мусорной" части v }
function SameDouble(ValueA, ValueB: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
function DoubleEqual(ValueA, ValueB: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
function DoubleLess(ValueA, ValueB: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
function DoubleMore(ValueA, ValueB: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
function DoubleLessEqual(ValueA, ValueB: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
function DoubleMoreEqual(ValueA, ValueB: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
function DoubleMax(ValueA, ValueB: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Double;
function DoubleMin(ValueA, ValueB: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Double;

function SameExtended(ValueA, ValueB: Extended; Scale: Integer = IC_MAX_EXTENDED_SCALE): Boolean;
function ExtendedEqual(ValueA, ValueB: Extended; Scale: Integer = IC_MAX_EXTENDED_SCALE): Boolean;
function ExtendedLess(ValueA, ValueB: Extended; Scale: Integer = IC_MAX_EXTENDED_SCALE): Boolean;
function ExtendedMore(ValueA, ValueB: Extended; Scale: Integer = IC_MAX_EXTENDED_SCALE): Boolean;
function ExtendedLessEqual(ValueA, ValueB: Extended; Scale: Integer = IC_MAX_EXTENDED_SCALE): Boolean;
function ExtendedMoreEqual(ValueA, ValueB: Extended; Scale: Integer = IC_MAX_EXTENDED_SCALE): Boolean;
function ExtendedMax(ValueA, ValueB: Extended; Scale: Integer = IC_MAX_EXTENDED_SCALE): Extended;
function ExtendedMin(ValueA, ValueB: Extended; Scale: Integer = IC_MAX_EXTENDED_SCALE): Extended;
{ ^ Cравнение действительных чисел с отбросом "мусорной" части ^ }

{ v Безопасное деление. При попытке деления на 0 возвращает 0. v }
function DivideSecurely(Dividend, Divider: Double): Double; overload;
function DivideSecurely(Dividend, Divider: Integer): Double; overload;
function DivSecurely(Dividend, Divider: Integer): Integer;
{ ^ Безопасное деление. При попытке деления на 0 возвращает 0. ^ }

{ v Жизнь без Math в каждом юните)) v }
function Min(ValueA, ValueB: Int64): Int64; overload;
function Max(ValueA, ValueB: Int64): Int64; overload;
function Min(ValueA, ValueB: Double): Double; overload;
function Max(Value1, Value2: Double): Double; overload;
function Power(const Base, Exponent: Extended): Extended; overload;
function Power(const Base, Exponent: Double): Double; overload;
function Power(const Base, Exponent: Single): Single; overload;
{ ^ Жизнь без Math в каждом юните)) ^ }

function Min(const Values: array of Int64): Int64; overload;
function Max(const Values: array of Int64): Int64; overload;

procedure AddToIntArray(var IntArray: TIntegerArray; const Value: Integer; Sorted: Boolean = False);
function Contains(const IntArray: TIntegerArray; const Value: Integer): Boolean;

procedure Invert(var Value: Byte); overload;
procedure Invert(var Value: Word); overload;
procedure Invert(var Value: Integer); overload;

type

  { TODO 3 -oVasilyevSM -cuDataUtils: Точно нельзя без класса никак? }
  { TODO 3 -oVasilyevSM -cuDataUtils: Еще похимичить. Не вполне универсально. }
  Matrix<TKey, TReply> = class abstract

  public

    class function PackKey(Index: TKey): Integer; virtual;
    class function Get(Index: TKey; const Map: array of TReply): TReply;

  end;

  MatrixR<TReply> = class abstract

  public

    class function Get<TKey>(Index: TKey; const Map: array of TReply): TReply;

  end;

  StrMatrix = class abstract

  public

    class function Get<T>(Index: T; const Map: array of String): String;

  end;

implementation

function BooleanToInt(Value: Boolean): Integer;
begin
  Result := BooleanToBigInt(Value);
end;

function BooleanToBigInt(Value: Boolean): Int64;
const
  IA_MAP: array[Boolean] of Byte = (0, 1);
begin
  Result := IA_MAP[Value];
end;

function BooleanToFloat(Value: Boolean): Double;
const
  DA_MAP: array[Boolean] of Double = (0, 1);
begin
  Result := DA_MAP[Value];
end;

function BooleanToExtended(Value: Boolean): Extended;
const
  EA_MAP: array[Boolean] of Extended = (0, 1);
begin
  Result := EA_MAP[Value];
end;

function BooleanToBLOB(Value: Boolean): BLOB;
begin
  if Value then Result := BLOB(#1)
  else Result := BLOB(#0);
end;

function BooleanToData(Value: Boolean): TData;
begin
  SetLength(Result, 1);
  Result[0] := BooleanToBigInt(Value);
end;

function IntToBoolean(Value: Integer): Boolean;
begin

  case Value of

    0: Result := False;
    1: Result := True;

  else
    raise EConvertError.CreateFmt('%d is invalid boolean value', [Value]);
  end;

end;

function IntToBigInt(Value: Integer): Int64;
begin
  Result := Value;
end;

function IntToFloat(Value: Integer): Double;
begin
  Result := Value;
end;

function IntToExtended(Value: Integer): Extended;
begin
  Result := Value;
end;

function IntToDateTime(Value: Integer): TDateTime;
begin
  // Не весь диапазон
  Result := TDateTime(IntToFloat(Value));
end;

function IntToBLOB(Value: Integer): BLOB;
begin
  SetLength(Result, SizeOf(Value));
  Move(Value, Result[1], SizeOf(Value));
end;

function IntToData(Value: Integer): TData;
var
  i, L: Byte;
begin

  L := SizeOf(Value);
  SetLength(Result, L);

  for i := 0 to L - 1 do
    Result[i] := PByte(@Value)[L - i - 1];

end;

function BigIntToBoolean(Value: Int64): Boolean;
begin

  case Value of

    0: Result := False;
    1: Result := True;

  else
    raise EConvertError.CreateFmt('%d is invalid boolean value', [Value]);
  end;

end;

function BigIntToInt(Value: Int64): Integer;
begin
  Result := Value;
  if Result <> Value then
    raise EConvertError.CreateFmt('%d is invalid 32-bit integer value', [Value]);
end;

function BigIntToFloat(Value: Int64): Double;
begin
  // Значение округляется
  Result := Value;
end;

function BigIntToExtended(Value: Int64): Extended;
begin
  // Значение округляется
  Result := Value;
end;

function BigIntToDateTime(Value: Int64): TDateTime;
begin
  // Не весь диапазон
  Result := TDateTime(BigIntToFloat(Value));
end;

function BigIntToBLOB(Value: Int64): BLOB;
begin
  SetLength(Result, SizeOf(Value));
  Move(Value, Result[1], SizeOf(Value));
end;

function BigIntToData(Value: Int64): TData;
var
  i, L: Byte;
begin

  L := SizeOf(Value);
  SetLength(Result, L);

  for i := 0 to L - 1 do
    Result[i] := PByte(@Value)[L - i - 1];

end;

function FloatToBoolean(Value: Double): Boolean;
begin

  if      DoubleEqual(Value, 0) then Result := False
  else if DoubleEqual(Value, 1) then Result := True
  else raise EConvertError.CreateFmt('%n is invalid boolean value', [Value]);

end;

function FloatToInt(Value: Double): Integer;
begin

  Result := Trunc(Value);
  if not DoubleEqual(Result, Value) then
    raise EConvertError.CreateFmt('%n is invalid integer value', [Value]);

end;

function FloatToBigInt(Value: Double): Int64;
begin

  // большие значения теряют точность
  Result := Trunc(Value);
  if not DoubleEqual(Result, Value) then
    raise EConvertError.CreateFmt('%n is invalid integer value', [Value]);

end;

function FloatToExtended(Value: Double): Extended;
begin
  // большие значения теряют точность
  Result := Value;
end;

function FloatToBLOB(Value: Double): BLOB;
begin
  SetLength(Result, SizeOf(Value));
  Move(Value, Result[1], SizeOf(Value));
end;

function FloatToDateTime(Value: Double): TDateTime;
begin
  // диапазон не контролируется
  Result := Value;
end;

function FloatToData(Value: Double): TData;
begin
  SetLength(Result, SizeOf(Value));
  Move(Value, Result[0], SizeOf(Value));
end;

function ExtendedToBoolean(Value: Extended): Boolean;
begin

  if      ExtendedEqual(Value, 0) then Result := False
  else if ExtendedEqual(Value, 1) then Result := True
  else raise EConvertError.CreateFmt('%e is invalid boolean value', [Value]);

end;

function ExtendedToInt(Value: Extended): Integer;
begin

  Result := Trunc(Value);
  if not ExtendedEqual(Result, Value) then
    raise EConvertError.CreateFmt('%e is invalid integer value', [Value]);

end;

function ExtendedToBigInt(Value: Extended): Int64;
begin

  // большие значения теряют точность
  Result := Trunc(Value);
  if not DoubleEqual(Result, Value) then
    raise EConvertError.CreateFmt('%n is invalid integer value', [Value]);

end;

function ExtendedToFloat(Value: Extended): Double;
begin
  // большие значения теряют точность
  Result := Value;
end;

function ExtendedToDateTime(Value: Extended): TDateTime;
begin
  // диапазон не контролируется
  Result := Value;
end;

function ExtendedToBLOB(Value: Extended): BLOB;
begin
  SetLength(Result, SizeOf(Value));
  Move(Value, Result[1], SizeOf(Value));
end;

function ExtendedToData(Value: Extended): TData;
begin
  raise EUncompletedMethod.Create;
end;

function DateTimeToInt(const Value: TDateTime): Integer;
begin
  Result := Trunc(Value);
end;

function DateTimeToBigInt(const Value: TDateTime): Int64;
begin
  Result := Trunc(Value);
end;

function DateTimeToFloat(const Value: TDateTime): Double;
begin
  Result := Value;
end;

function DateTimeToExtended(const Value: TDateTime): Extended;
begin
  Result := Value;
end;

function DateTimeToBLOB(const Value: TDateTime): BLOB;
begin
  SetLength(Result, SizeOf(Value));
  Move(Value, Result[1], SizeOf(Value));
end;

function DateTimeToData(const Value: TDateTime): TData;
begin
  SetLength(Result, SizeOf(Value));
  Move(Value, Result[0], SizeOf(Value));
end;

function GUIDToBLOB(const Value: TGUID): BLOB;
begin
  SetLength(Result, SizeOf(Value));
  Move(Value, Result[1], SizeOf(Value));
end;

function GUIDToData(const Value: TGUID): TData;
begin
  SetLength(Result, SizeOf(Value));
  Move(Value, Result[0], SizeOf(Value));
end;

function BLOBToBoolean(const Value: BLOB): Boolean;
begin

  if (Length(Value) = 1) and (Value[1] in [#0, #1]) then

    Result := Value[1] = #1

  else raise EConvertError.CreateFmt('''0x%x...'' is not a boolean value', [BLOBToBigInt(Value)]);

end;

function BLOBToInt(const Value: BLOB): Integer;
begin
  Move(Value[1], Result, SizeOf(Result));
end;

function BLOBToBigInt(const Value: BLOB): Int64;
begin
  Move(Value[1], Result, SizeOf(Result));
end;

function BLOBToFloat(const Value: BLOB): Double;
begin
  Move(Value[1], Result, SizeOf(Result));
end;

function BLOBToExtended(const Value: BLOB): Extended;
begin
  Move(Value[1], Result, SizeOf(Result));
end;

function BLOBToDateTime(const Value: BLOB): TDateTime;
begin
  Move(Value[1], Result, SizeOf(Result));
end;

function BLOBToGUID(const Value: BLOB): TGUID;
begin
  Move(Value[1], Result, SizeOf(Result));
end;

function BLOBToData(const Value: BLOB): TData;
begin
  SetLength(Result, Length(Value));
  Move(Value[1], Result[0], Length(Value));
end;


function DataToBoolean(const Value: TData): Boolean;
begin

  if (Length(Value) = 1) and (Value[0] in [0, 1]) then

    Result := Value[0] = 1

  else raise EConvertError.CreateFmt('''0x%x...'' is not a boolean value', [DataToBigInt(Value)]);

end;

function DataToInt(const Value: TData): Integer;
var
  i, L: Byte;
begin

  L := Length(Value);

  for i := 0 to 3 do
    if i <= L - 1 then PByte(@Result)[i] := Value[L - i - 1]
    else PByte(@Result)[i] := 0;

end;

function DataToBigInt(const Value: TData): Int64;
var
  i, L: Byte;
begin

  L := Length(Value);

  for i := 0 to 7 do
    if i <= L - 1 then PByte(@Result)[i] := Value[L - i - 1]
    else PByte(@Result)[i] := 0;

end;

function DataToFloat(const Value: TData): Double;
begin
  Move(Value[0], Result, SizeOf(TDateTime));
end;

function DataToExtended(const Value: TData): Extended;
begin
  raise EUncompletedMethod.Create;
end;

function DataToDateTime(const Value: TData): TDateTime;
begin
  Move(Value[0], Result, SizeOf(TDateTime));
end;

function DataToGUID(const Value: TData): TGUID;
begin
  Move(Value[0], Result, SizeOf(Result));
end;

function DataToBLOB(const Value: TData): BLOB;
begin
  SetLength(Result, Length(Value));
  Move(Value[0], Result[1], Length(Value));
end;

function DataToAnsiStr(const Value: TData): AnsiString;
var
  L: Integer;
begin
  L := Length(Value);
  SetLength(Result, L);
  Move(Value[0], Result[1], L);
end;

function DataToStr(const Value: TData): String;
var
  L: Integer;
begin
  L := Length(Value);
  SetLength(Result, L div 2);
  Move(Value[0], Result[1], L);
end;

function SameDouble(ValueA, ValueB: Double; Scale: Integer): Boolean;
begin
  Result := DoubleEqual(ValueA, ValueB, Scale);
end;

function DoubleEqual(ValueA, ValueB: Double; Scale: Integer): Boolean;
begin
  Result := Abs(ValueA - ValueB) < Power(10, - Scale);
end;

function DoubleLess(ValueA, ValueB: Double; Scale: Integer): Boolean;
begin
  Result := not DoubleEqual(ValueA, ValueB, Scale) and (ValueA < ValueB);
end;

function DoubleMore(ValueA, ValueB: Double; Scale: Integer): Boolean;
begin
  Result := not DoubleEqual(ValueA, ValueB, Scale) and (ValueA > ValueB);
end;

function DoubleLessEqual(ValueA, ValueB: Double; Scale: Integer): Boolean;
begin
  Result := DoubleLess(ValueA, ValueB, Scale) or DoubleEqual(ValueA, ValueB, Scale);
end;

function DoubleMoreEqual(ValueA, ValueB: Double; Scale: Integer): Boolean;
begin
  Result := DoubleMore(ValueA, ValueB, Scale) or DoubleEqual(ValueA, ValueB, Scale);
end;

function DoubleMax(ValueA, ValueB: Double; Scale: Integer): Double;
begin
  if DoubleMore(ValueA, ValueB) then Result := ValueA
  else Result := ValueB;
end;

function DoubleMin(ValueA, ValueB: Double; Scale: Integer): Double;
begin
  if DoubleLess(ValueA, ValueB) then Result := ValueA
  else Result := ValueB;
end;

function SameExtended(ValueA, ValueB: Extended; Scale: Integer): Boolean;
begin
  Result := ExtendedEqual(ValueA, ValueB, Scale);
end;

function ExtendedEqual(ValueA, ValueB: Extended; Scale: Integer): Boolean;
begin
  Result := Abs(ValueA - ValueB) < Power(10, - Scale);
end;

function ExtendedLess(ValueA, ValueB: Extended; Scale: Integer): Boolean;
begin
  Result := not ExtendedEqual(ValueA, ValueB, Scale) and (ValueA < ValueB);
end;

function ExtendedMore(ValueA, ValueB: Extended; Scale: Integer): Boolean;
begin
  Result := not ExtendedEqual(ValueA, ValueB, Scale) and (ValueA > ValueB);
end;

function ExtendedLessEqual(ValueA, ValueB: Extended; Scale: Integer): Boolean;
begin
  Result := ExtendedLess(ValueA, ValueB, Scale) or ExtendedEqual(ValueA, ValueB, Scale);
end;

function ExtendedMoreEqual(ValueA, ValueB: Extended; Scale: Integer): Boolean;
begin
  Result := ExtendedMore(ValueA, ValueB, Scale) or ExtendedEqual(ValueA, ValueB, Scale);
end;

function ExtendedMax(ValueA, ValueB: Extended; Scale: Integer): Extended;
begin
  if ExtendedMore(ValueA, ValueB) then Result := ValueA
  else Result := ValueB;
end;

function ExtendedMin(ValueA, ValueB: Extended; Scale: Integer): Extended;
begin
  if DoubleLess(ValueA, ValueB) then Result := ValueA
  else Result := ValueB;
end;

function DivideSecurely(Dividend, Divider: Double): Double;
begin
  if DoubleEqual(Divider, 0) then Result := 0
  else Result := Dividend / Divider;
end;

function DivideSecurely(Dividend, Divider: Integer): Double;
begin
  if Divider = 0 then Result := 0
  else Result := Dividend / Divider;
end;

function DivSecurely(Dividend, Divider: Integer): Integer;
begin
  if Divider = 0 then Result := 0
  else Result := Dividend div Divider;
end;

function Min(ValueA, ValueB: Int64): Int64;
begin
  if ValueA <= ValueB then Result := ValueA else Result := ValueB;
end;

function Max(ValueA, ValueB: Int64): Int64;
begin
  if ValueA >= ValueB then Result := ValueA else Result := ValueB;
end;

function Min(ValueA, ValueB: Double): Double;
begin
  Result := DoubleMax(ValueA, ValueB);
end;

function Max(Value1, Value2: Double): Double;
begin
  Result := DoubleMax(Value1, Value2);
end;

function Power(const Base, Exponent: Extended): Extended;
const
  Max  : Double = MaxInt;
var
  IntExp : Integer;
asm // StackAlignSafe
  fld     Exponent
  fld     st             {copy to st(1)}
  fabs                   {abs(exp)}
  fld     Max
  fcompp                 {leave exp in st(0)}
  fstsw   ax
  sahf
  jb      @@RealPower    {exp > MaxInt}
  fld     st             {exp in st(0) and st(1)}
  frndint                {round(exp)}
  fcomp                  {compare exp and round(exp)}
  fstsw   ax
  sahf
  jne     @@RealPower
  fistp   IntExp
  mov     eax, IntExp    {eax=Trunc(Exponent)}
  mov     ecx, eax
  cdq
  fld1                   {Result=1}
  xor     eax, edx
  sub     eax, edx       {abs(exp)}
  jz      @@Exit
  fld     Base
  jmp     @@Entry
@@Loop:
  fmul    st, st         {Base * Base}
@@Entry:
  shr     eax, 1
  jnc     @@Loop
  fmul    st(1), st      {Result * X}
  jnz     @@Loop
  fstp    st
  cmp     ecx, 0
  jge     @@Exit
  fld1
  fdivrp                 {1/Result}
  jmp     @@Exit
@@RealPower:
  fld     Base
  ftst
  fstsw   ax
  sahf
  jz      @@Done
  fldln2
  fxch
  fyl2x
  fxch
  fmulp   st(1), st
  fldl2e
  fmulp   st(1), st
  fld     st(0)
  frndint
  fsub    st(1), st
  fxch    st(1)
  f2xm1
  fld1
  faddp   st(1), st
  fscale
@@Done:
  fstp    st(1)
@@Exit:
end;

function Power(const Base, Exponent: Double): Double; overload;
const
  Max  : Double = MaxInt;
var
  IntExp : Integer;
asm // StackAlignSafe
  fld     Exponent
  fld     st             {copy to st(1)}
  fabs                   {abs(exp)}
  fld     Max
  fcompp                 {leave exp in st(0)}
  fstsw   ax
  sahf
  jb      @@RealPower    {exp > MaxInt}
  fld     st             {exp in st(0) and st(1)}
  frndint                {round(exp)}
  fcomp                  {compare exp and round(exp)}
  fstsw   ax
  sahf
  jne     @@RealPower
  fistp   IntExp
  mov     eax, IntExp    {eax=Trunc(Exponent)}
  mov     ecx, eax
  cdq
  fld1                   {Result=1}
  xor     eax, edx
  sub     eax, edx       {abs(exp)}
  jz      @@Exit
  fld     Base
  jmp     @@Entry
@@Loop:
  fmul    st, st         {Base * Base}
@@Entry:
  shr     eax, 1
  jnc     @@Loop
  fmul    st(1), st      {Result * X}
  jnz     @@Loop
  fstp    st
  cmp     ecx, 0
  jge     @@Exit
  fld1
  fdivrp                 {1/Result}
  jmp     @@Exit
@@RealPower:
  fld     Base
  ftst
  fstsw   ax
  sahf
  jz      @@Done
  fldln2
  fxch
  fyl2x
  fxch
  fmulp   st(1), st
  fldl2e
  fmulp   st(1), st
  fld     st(0)
  frndint
  fsub    st(1), st
  fxch    st(1)
  f2xm1
  fld1
  faddp   st(1), st
  fscale
@@Done:
  fstp    st(1)
@@Exit:
end;

function Power(const Base, Exponent: Single): Single; overload;
const
  Max : Double = MaxInt;
var
  IntExp : Integer;
asm // StackAlignSafe
  fld     Exponent
  fld     st             {copy to st(1)}
  fabs                   {abs(exp)}
  fld     Max
  fcompp                 {leave exp in st(0)}
  fstsw   ax
  sahf
  jb      @@RealPower    {exp > MaxInt}
  fld     st             {exp in st(0) and st(1)}
  frndint                {round(exp)}
  fcomp                  {compare exp and round(exp)}
  fstsw   ax
  sahf
  jne     @@RealPower
  fistp   IntExp
  mov     eax, IntExp    {eax=Integer(Exponent)}
  mov     ecx, eax
  cdq
  fld1                   {Result=1}
  xor     eax, edx
  sub     eax, edx       {abs(exp)}
  jz      @@Exit
  fld     Base
  jmp     @@Entry
@@Loop:
  fmul    st, st         {Base * Base}
@@Entry:
  shr     eax, 1
  jnc     @@Loop
  fmul    st(1), st      {Result * X}
  jnz     @@Loop
  fstp    st
  cmp     ecx, 0
  jge     @@Exit
  fld1
  fdivrp                 {1/Result}
  jmp     @@Exit
@@RealPower:
  fld     Base
  ftst
  fstsw   ax
  sahf
  jz      @@Done
  fldln2
  fxch
  fyl2x
  fxch
  fmulp   st(1), st
  fldl2e
  fmulp   st(1), st
  fld     st(0)
  frndint
  fsub    st(1), st
  fxch    st(1)
  f2xm1
  fld1
  faddp   st(1), st
  fscale
@@Done:
  fstp    st(1)
@@Exit:
end;

function Min(const Values: array of Int64): Int64; overload;
var
  Value: Int64;
begin

  Result := Values[Low(Values)];
  for Value in Values do
    if Value < Result then
      Result := Value;

end;

function Max(const Values: array of Int64): Int64; overload;
var
  Value: Int64;
begin

  Result := Values[Low(Values)];
  for Value in Values do
    if Value > Result then
      Result := Value;

end;

procedure AddToIntArray(var IntArray: TIntegerArray; const Value: Integer; Sorted: Boolean);
var
  L, i, Index: Integer;
begin

  L := Length(IntArray);

  if Sorted then
  begin

    Index := -1;

    for i := Low(IntArray) to High(IntArray) do

      if IntArray[i] > Value then
      begin

        Index := i;
        Break;

      end;

    if Index = -1 then Index := L;

    SetLength(IntArray, L + 1);

    for i := High(IntArray) downto Index + 1 do
      IntArray[i] := IntArray[i - 1];

    IntArray[Index] := Value;

  end
  else
  begin

    SetLength(IntArray, L + 1);
    IntArray[L] := Value;

  end;

end;

function Contains(const IntArray: TIntegerArray; const Value: Integer): Boolean;
var
  Item: Integer;
begin

  for Item in IntArray do
    if Item = Value then
      Exit(True);

  Result := False;

end;

procedure Invert(var Value: Byte);
var
  i: Byte;
  Result: Byte;
begin
  Result := 0;
  for i := 0 to 7 do
    Result := Result xor (1 shl i);
  Value := Result;
end;

procedure Invert(var Value: Word);
var
  i: Byte;
  Result: Word;
begin
  Result := 0;
  for i := 0 to 15 do
    Result := Result xor (1 shl i);
  Value := Result;
end;

procedure Invert(var Value: Integer);
var
  i: Byte;
  Result: Integer;
begin
  Result := 0;
  for i := 0 to 31 do
    Result := Result xor (1 shl i);
  Value := Result;
end;

{ Matrix<TReply, TKey> }

class function Matrix<TKey, TReply>.PackKey(Index: TKey): Integer;
begin
  Move(Index, Result, 4);
end;

class function Matrix<TKey, TReply>.Get(Index: TKey; const Map: array of TReply): TReply;
var
  I: Integer;
begin

  I := PackKey(Index);

  if I > High(Map) then
    raise ECoreException.CreateFmt('Matrix error. Index %d is out of range %d..%d.', [I, Low(Map), High(Map)]);

  Result := Map[I];

end;

{ MatrixR<TReply> }

class function MatrixR<TReply>.Get<TKey>(Index: TKey; const Map: array of TReply): TReply;
var
  B: Byte;
begin

  Move(Index, B, 1);

  if B > High(Map) then
    raise ECoreException.CreateFmt('Matrix error. Index %d is out of range %d..%d.', [B, Low(Map), High(Map)]);

  Result := Map[B];

end;

{ StrMatrix }

class function StrMatrix.Get<T>(Index: T; const Map: array of String): String;
var
  B: Byte;
begin

  Move(Index, B, 1);

  if B > High(Map) then
    raise ECoreException.CreateFmt('Matrix error. Index %d is out of range %d..%d.', [B, Low(Map), High(Map)]);

  Result := Map[B];

end;

end.
