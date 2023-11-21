unit uDataUtils;

(*********************************************************)
(*                                                       *)
(*                        Hello!)                        *)
(*                                                       *)
(*********************************************************)

interface

uses
  { VCL }
  SysUtils,
  { vSoft }
  uConsts, uTypes;

{ v Преобразование основных типов данных v }
{ Можно продолжать evyj;tybtv: Boolean, Integer, BigInt, Float, Extended, TDateTime, TGUID, AnsiString, String, BLOB, TData }
function BooleanToInt(Value: Boolean): Int64;
function BooleanToBLOB(Value: Boolean): BLOB;
function IntToBoolean(Value: Int64): Boolean;
function BLOBToBoolean(const Value: BLOB): Boolean;
function DataToAnsiStr(const Data: TData; Offset: Integer = 0): AnsiString;
function DataToStr(const Data: TData; Offset: Integer = 0): String;
function DataToGUID(const Data: TData): TGUID;
{ ^ Преобразование основных типов данных ^ }

{ v Cравнение действительных чисел с отбросом "мусорной" части v }
function SameDouble(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
function DoubleEqual(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
function DoubleLess(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
function DoubleMore(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
function DoubleLessEqual(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
function DoubleMoreEqual(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
function DoubleMax(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Double;
function DoubleMin(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Double;
{ ^ Cравнение действительных чисел с отбросом "мусорной" части ^ }

{ v Безопасное деление. При попытке деления на 0 возвращает 0. v }
function DivideSecurely(Dividend, Divider: Double): Double; overload;
function DivideSecurely(Dividend, Divider: Integer): Double; overload;
function DivSecurely(Dividend, Divider: Integer): Integer;
{ ^ Безопасное деление. При попытке деления на 0 возвращает 0. ^ }

{ v Жизнь без Math в каждом юните)) v }
function Min(Value1, Value2: Int64): Int64; overload;
function Max(Value1, Value2: Int64): Int64; overload;
function Min(Value1, Value2: Double): Double; overload;
function Max(Value1, Value2: Double): Double; overload;
function Power(const Base, Exponent: Extended): Extended; overload;
function Power(const Base, Exponent: Double): Double; overload;
function Power(const Base, Exponent: Single): Single; overload;
{ ^ Жизнь без Math в каждом юните)) ^ }

implementation

function BooleanToInt(Value: Boolean): Int64;
const
  IA_MAP: array[Boolean] of Byte = (0, 1);
begin
  Result := IA_MAP[Value];
end;

function BooleanToBLOB(Value: Boolean): BLOB;
begin
  if Value then Result := BLOB(#1)
  else Result := BLOB(#0);
end;

function IntToBoolean(Value: Int64): Boolean;
begin
  case Value of

    0: Result := False;
    1: Result := True;

  else
    raise EConvertError.CreateFmt('%d is invalud Boolean value', [Value]);
  end;

end;

function BLOBToBoolean(const Value: BLOB): Boolean;
begin

  if (Length(Value) = 1) and (Value[1] in [#0, #1]) then

    Result := Value[1] = #1

  else raise EConvertError.Create('It is not a Boolean value');

end;

function _GetNewLength(Length, Offset: Integer): Integer;
begin
  if Length > Offset then Result := Length - Offset
  else Result := 0;
end;

function DataToAnsiStr(const Data: TData; Offset: Integer = 0): AnsiString;
var
  L: Integer;
begin
  L := _GetNewLength(Length(Data), Offset);
  SetLength(Result, L);
  Move(Data[Offset], Result[1], L);
end;

function DataToStr(const Data: TData; Offset: Integer = 0): String;
var
  L: Integer;
begin
  L := _GetNewLength(Length(Data), Offset);
  SetLength(Result, L div 2);
  Move(Data[Offset], Result[1], L);
end;

function DataToGUID(const Data: TData): TGUID;
begin
  Move(Data[0], Result, 16);
end;

function SameDouble(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
begin
  Result := DoubleEqual(D1, D2, Scale);
end;

function DoubleEqual(D1, D2: Double; Scale: Integer): Boolean;
begin
  Result := Abs(D1 - D2) < Power(10, - Scale);
end;

function DoubleLess(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
begin
  Result := not DoubleEqual(D1, D2, Scale) and (D1 < D2);
end;

function DoubleMore(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
begin
  Result := not DoubleEqual(D1, D2, Scale) and (D1 > D2);
end;

function DoubleLessEqual(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
begin
  Result := DoubleLess(D1, D2, Scale) or DoubleEqual(D1, D2, Scale);
end;

function DoubleMoreEqual(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Boolean;
begin
  Result := DoubleMore(D1, D2, Scale) or DoubleEqual(D1, D2, Scale);
end;

function DoubleMax(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Double;
begin
  if DoubleMore(D1, D2) then Result := D1
  else Result := D2;
end;

function DoubleMin(D1, D2: Double; Scale: Integer = IC_MAX_DOUBLE_SCALE): Double;
begin
  if DoubleLess(D1, D2) then Result := D1
  else Result := D2;
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

function Min(Value1, Value2: Int64): Int64;
begin
  if Value1 <= Value2 then Result := Value1 else Result := Value2;
end;

function Max(Value1, Value2: Int64): Int64;
begin
  if Value1 >= Value2 then Result := Value1 else Result := Value2;
end;

function Min(Value1, Value2: Double): Double;
begin
  Result := DoubleMax(Value1, Value2);
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

end.
