unit uGUID;

(*********************************************************)
(*                                                       *)
(*                        Hello!)                        *)
(*                                                       *)
(*********************************************************)

interface

function NullGUID: TGUID;

implementation

function NullGUID: TGUID;
begin
  FillChar(Result, SizeOf(TGUID), #0);
end;

end.
