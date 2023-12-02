unit uUtils;

(**********************************************************)
(*                                                        *)
(*                     Liber Synth Co                     *)
(*                                                        *)
(**********************************************************)

interface

uses
  { vSoft }
  uTypes, uDataUtils;

function IntArrayMin(const _Array: TIntegerArray): Integer;

function CheckRange(Index, Lo, Hi: Integer): Boolean;
function CheckListRange(Index, Count: Integer): Boolean;

implementation

function IntArrayMin(const _Array: TIntegerArray): Integer;
var
  i: Integer;
begin
  Result := MaxInt;
  for i in _Array do
    Result := Min(Result, i);
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
