unit uGUID;

(*********************************************************)
(*                                                       *)
(*                        Hello!)                        *)
(*                                                       *)
(*********************************************************)

{ TODO -oVasilyevSM -cVCore : ���� ������� ����� �� �����, ����� � uDataUtils ��������� }
interface

function NullGUID: TGUID;

implementation

function NullGUID: TGUID;
begin
  FillChar(Result, SizeOf(TGUID), #0);
end;

end.
