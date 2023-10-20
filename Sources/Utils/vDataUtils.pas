unit vDataUtils;

interface

uses
  { Utils }
  vTypes;

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
function IsHexChar(const Value: String): Boolean;
function IsHexCharStr(const Value: String): Boolean;
function HexCharStrToStr(const Value: String): String;

const

  HexChars: array[0..15] of Char = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
  HexCharsSet = ['0'..'9', 'A'..'F'];
  IntegerCharsSet = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

implementation

uses
  { VCL }
  Classes, SysUtils,
  { Utils }
  vStrUtils;

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
  Result := StringReplace(StringReplace(S, '.', {$IFNDEF DELPHI2010}FormatSettings.{$ENDIF}DecimalSeparator, []), ',', {$IFNDEF DELPHI2010}FormatSettings.{$ENDIF}DecimalSeparator, []);
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

  raise EConvertError.CreateFmt(SC_BooleanConvertError, [S]);

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

const

  SC_HexCharSign = '#$';

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

  SA := StrToArray(Value, SC_HexCharSign, False);
  Result := Length(SA) > 0;
  for i := Low(SA) to High(SA) do
    if not IsHexChar(SC_HexCharSign + SA[i]) then
      Exit(False);

end;

function HexCharStrToStr(const Value: String): String;

  procedure _Raise;
  const
    SC_NotHexCharStrFormat = '''%s'' is not a hex';
  begin
    raise Exception.CreateFmt(SC_NotHexCharStrFormat, [Value]);
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

  SA := StrToArray(Value, SC_HexCharSign, False);
  if Length(SA) = 0 then _Raise;
  SetLength(Result, Length(SA));
  for i := Low(SA) to High(SA) do begin

    _Check(SA[i]);
    Result[i + 1] := Char(StrToInt('$' + SA[i]));

  end;

end;

end.
