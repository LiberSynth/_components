unit uUtils;

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

interface

uses
  { LiberSynth }
  uTypes, uDataUtils;

function RangeValue(var Value: Integer; MinValue, MaxValue: Integer): Boolean;
function IntArrayMin(const _Array: TIntegerArray): Integer;
function IntArrayMax(const _Array: TIntegerArray): Integer;

function CheckRange(Index, Lo, Hi: Integer): Boolean;
function CheckListRange(Index, Count: Integer): Boolean;

implementation

function RangeValue(var Value: Integer; MinValue, MaxValue: Integer): Boolean;
begin

  if Value < MinValue then begin

    Value := MinValue;
    Exit(True);

  end;

  if Value > MaxValue then begin

    Value := MaxValue;
    Exit(True);

  end;

  Result := False;

end;

function IntArrayMin(const _Array: TIntegerArray): Integer;
var
  I: Integer;
begin
  Result := MaxInt;
  for I in _Array do
    Result := Min(Result, I);
end;

function IntArrayMax(const _Array: TIntegerArray): Integer;
var
  I: Integer;
begin
  Result := - MaxInt - 1;
  for I in _Array do
    Result := Max(Result, I);
end;

function CheckRange(Index, Lo, Hi: Integer): Boolean;
begin
  Result := (Index >= Lo) and (Index <= Hi);
end;

function CheckListRange(Index, Count: Integer): Boolean;
begin
  Result := CheckRange(Index, 0, Count - 1);
end;

end.
