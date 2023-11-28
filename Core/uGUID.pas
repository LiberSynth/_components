unit uGUID;

(*********************************************************)
(*                                                       *)
(*                        Hello!)                        *)
(*                                                       *)
(*********************************************************)

{ TODO -oVasilyevSM -cuGUID : Если функций будет не много, можно в uDataUtils перенести }

interface

function NullGUID: TGUID;

implementation

function NullGUID: TGUID;
begin
  FillChar(Result, SizeOf(TGUID), 0);
end;

end.
