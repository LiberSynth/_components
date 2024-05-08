unit uGUIDValueReplacer;

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
  { VDebugPackage }
  uClasses, uCustomVizualizers;

type

  TGUIDValueReplacer = class(TCustomValueReplacer)

  protected

    { IOTADebuggerVisualizer }
    procedure GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean); override;
    function GetVisualizerName: String; override;
    function GetVisualizerDescription: String; override;

    function GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String; override;

  end;

implementation

uses
  { Utils }
  uStrUtils,
  { VDebugPackage }
  uProjectConsts, uCommon;

{ TGUIDValueReplacer }

function TGUIDValueReplacer.GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String;
var
  Value: TGUID;
begin

  with Evaluator do begin

      ReadSingleContext(_Expression + '.D1',    'LongWord', SizeOf(LongWord), Value.D1   );
      ReadSingleContext(_Expression + '.D2',    'Word',     SizeOf(Word),     Value.D2   );
      ReadSingleContext(_Expression + '.D3',    'Word',     SizeOf(Word),     Value.D3   );
      ReadSingleContext(_Expression + '.D4[0]', 'Byte',     SizeOf(Byte),     Value.D4[0]);
      ReadSingleContext(_Expression + '.D4[1]', 'Byte',     SizeOf(Byte),     Value.D4[1]);
      ReadSingleContext(_Expression + '.D4[2]', 'Byte',     SizeOf(Byte),     Value.D4[2]);
      ReadSingleContext(_Expression + '.D4[3]', 'Byte',     SizeOf(Byte),     Value.D4[3]);
      ReadSingleContext(_Expression + '.D4[4]', 'Byte',     SizeOf(Byte),     Value.D4[4]);
      ReadSingleContext(_Expression + '.D4[5]', 'Byte',     SizeOf(Byte),     Value.D4[5]);
      ReadSingleContext(_Expression + '.D4[6]', 'Byte',     SizeOf(Byte),     Value.D4[6]);
      ReadSingleContext(_Expression + '.D4[7]', 'Byte',     SizeOf(Byte),     Value.D4[7]);

  end;

  Result := GUIDToStr(Value);

end;

procedure TGUIDValueReplacer.GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean);
begin
  _AllDescendants := False;
  _TypeName := 'TGUID';
end;

function TGUIDValueReplacer.GetVisualizerDescription: String;
begin
  Result := SC_GUIDValueReplacer_Description;
end;

function TGUIDValueReplacer.GetVisualizerName: String;
begin
  Result := SC_GUIDValueReplacer_Name;
end;

end.
