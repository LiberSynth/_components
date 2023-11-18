unit uDataUtils;

{TODO -oVasilyev -cComponents : -> Core }

interface

uses
  { VCL }
  Classes, SysUtils, Math,
  { vSoft }
  uConsts, uTypes;

type

  { Byte Order Mark }
  TBOM = (bomForward, bomBackward);

const

  WC_BOM_FWD = $FEFF;
  WC_BOM_BWD = $FFFE;

function DataToAnsiStr(const Data: TData; Offset: Integer = 0): AnsiString;
function DataToStr(const Data: TData; Offset: Integer = 0): String;
procedure CleanUpAnsiString(var Value: AnsiString);
procedure CleanUpString(var Value: String);

function WordToBOM(Value: Word): TBOM;
function BOMToStr(Value: TBOM): String;
function UTF16DataToStr(const Data: TData; BOM: TBOM): String;

function DataToGUID(const Data: TData): TGUID;
function TryStrToGUID(const S: String; var Value: TGUID): Boolean;
function StrToGUID(const Value: String): TGUID;
function GUIDToStr(const Value: TGUID) : String;
function StrIsGUID(const Value: String): Boolean;
function NormalizeGUID(var Value: String): Boolean;

function _ByteArrayToStr(const _Data: TData): String;
function _ByteArrayToAnsiStr(const _Data: TData): String;

function ReduceStrToFloat(const S: String): String;
function BooleanToStr(Value: Boolean): String;
function StrToBoolean(const S: String): Boolean;
function StrIsBoolean(const S: String): Boolean;
function RawByteStringToHex(const Value: RawByteString): String;
function HexToRawByteString(const Value: String): RawByteString;

{ Cравнение действительных чисел с отбросом "мусорной" части }
function DoubleEqual(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Boolean;
function SameDouble(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Boolean;
function DoubleLess(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Boolean;
function DoubleMore(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Boolean;
function DoubleLessEqual(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Boolean;
function DoubleMoreEqual(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Boolean;
function DoubleMax(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Double;
function DoubleMin(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Double;

function DivideSecurely(Dividend, Divider: Double): Double; overload;
function DivideSecurely(Dividend, Divider: Integer): Double; overload;
function DivSecurely(Dividend, Divider: Integer): Integer;

function IAMin(const _Array: TIntegerArray): Integer;

function CheckListRange(Index, Count: Integer): Boolean;

const

  HexChars: array[0..15] of Char = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
  HexCharsSet = ['0'..'9', 'A'..'F'];
  IntegerCharsSet = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

implementation

{ Data movement functions }

function GetNewLength(Length, Offset: Integer): Integer;
begin
  if Length > Offset then Result := Length - Offset
  else Result := 0;
end;

function DataToAnsiStr(const Data: TData; Offset: Integer = 0): AnsiString;
var
  L: Integer;
begin
  L := GetNewLength(Length(Data), Offset);
  SetLength(Result, L);
  Move(Data[Offset], Result[1], L);
end;

function DataToStr(const Data: TData; Offset: Integer = 0): String;
var
  L: Integer;
begin
  L := GetNewLength(Length(Data), Offset);
  SetLength(Result, L div 2);
  Move(Data[Offset], Result[1], L);
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

function DataToGUID(const Data: TData): TGUID;
begin
  Move(Data[0], Result, 16);
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
    raise EConvertError.CreateFmt('Error converting String ''%s'' to GUID', [Value]);
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

      else if not CharInSet(S[i], HexCharsSet) then Exit(False);

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

function NormalizeGUID(var Value: String): Boolean;
begin
  Result := StrIsGUID(Value);
  if Result and (Length(Value) = 36) then Value := '{' + Value + '}';
end;

function _ByteArrayToStr(const _Data: TData): String;
var
  i: Integer;
begin

  Result := '(';
  for i := Low(_Data) to High(_Data) do begin

    Result := Result + IntToStr(_Data[i]);
    if i < High(_Data) then Result := Result + ', ';

  end;

  Result := Result + ')';

end;

function _ByteArrayToAnsiStr(const _Data: TData): String;

  function _ToStr(_Ord: Integer): String;
  const
    IC_Letters = [32..255];
  begin
    if _Ord in IC_Letters then Result := String(AnsiChar(_Ord))
    else Result := '#' + IntToStr(_Ord);
  end;

var
  i: Integer;
begin
  Result := '';
  for i := Low(_Data) to High(_Data) do
    Result := Result + _ToStr(_Data[i]);
end;

function ReduceStrToFloat(const S: String): String;
begin
  Result := StringReplace(S,      '.', {$IFNDEF DELPHI2010}FormatSettings.{$ENDIF}DecimalSeparator, []);
  Result := StringReplace(Result, ',', {$IFNDEF DELPHI2010}FormatSettings.{$ENDIF}DecimalSeparator, []);
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

function StrIsBoolean(const S: String): Boolean;
begin
  Result := SameText(S, 'FALSE') or SameText(S, 'TRUE');
end;

function RawByteStringToHex(const Value: RawByteString): String;
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
    Result[i * 2 + 1] := HexChars[B div 16];
    Result[i * 2 + 2] := HexChars[B mod 16];

  end;

end;

function HexToRawByteString(const Value: String): RawByteString;
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

function DoubleEqual(D1, D2: Double; Scale: Integer): Boolean;
begin
  Result := Abs(D1 - D2) < Power(10, - Scale);
end;

function SameDouble(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Boolean;
begin
  Result := DoubleEqual(D1, D2, Scale);
end;

function DoubleLess(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Boolean;
begin
  Result := not DoubleEqual(D1, D2, Scale) and (D1 < D2);
end;

function DoubleMore(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Boolean;
begin
  Result := not DoubleEqual(D1, D2, Scale) and (D1 > D2);
end;

function DoubleLessEqual(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Boolean;
begin
  Result := DoubleLess(D1, D2, Scale) or DoubleEqual(D1, D2, Scale);
end;

function DoubleMoreEqual(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Boolean;
begin
  Result := DoubleMore(D1, D2, Scale) or DoubleEqual(D1, D2, Scale);
end;

function DoubleMax(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Double;
begin
  if DoubleMore(D1, D2) then Result := D1
  else Result := D2;
end;

function DoubleMin(D1, D2: Double; Scale: Integer = IC_MaxDoubleScale): Double;
begin
  if DoubleLess(D1, D2) then Result := D1
  else Result := D2;
end;

function IAMin(const _Array: TIntegerArray): Integer;
var
  i: Integer;
begin
  { Минимальное значение из массива }
  Result := MaxInt;
  for i in _Array do
    Result := Math.Min(Result, i);
end;

function CheckListRange(Index, Count: Integer): Boolean;
begin
  Result := (Index > -1) and (Index < Count);
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

end.
