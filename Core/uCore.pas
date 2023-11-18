unit uCore;

(*********************************************************)
(*                                                       *)
(*                        Hello!)                        *)
(*                                                       *)
(*********************************************************)

interface

uses
  { VCL }
  SysUtils;

type

  ECoreException = class(Exception);

function BooleanToStr(Value: Boolean): String;
function StrToBoolean(const S: String): Boolean;

function RawByteStringToHex(const Value: RawByteString): String;
function HexToRawByteString(const Value: String): RawByteString;

implementation

function BooleanToStr(Value: Boolean): String;
begin
  if Value then Result := 'True'
  else Result := 'False';
end;

function StrToBoolean(const S: String): Boolean;
begin

  if SameText(S, 'FALSE') then Exit(False);
  if SameText(S, 'TRUE' ) then Exit(True );

  raise EConvertError.CreateFmt('%s is not a boolean value', [S]);

end;

function RawByteStringToHex(const Value: RawByteString): String;
const

  HexChars: array[0..15] of Char = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');

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

end.
