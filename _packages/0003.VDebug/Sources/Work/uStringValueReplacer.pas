unit uStringValueReplacer;

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
(*   \:::\    \     \:::\/:::/    / \/____/ :::\/:::/    / :::\   \/____/_:::\/:::/    /   *)
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

  TStringValueReplacer = class(TCustomValueReplacer)

  protected

    { IOTADebuggerVisualizer }
    procedure GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean); override;
    function GetVisualizerName: String; override;
    function GetVisualizerDescription: String; override;

    function GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String; override;

  end;

implementation

uses
  { VCL }
  SysUtils,
  { Utils }
  vTypes, vLog,
  { VDebugPackage }
  uProjectConsts, uCommon;

{ TStringValueReplacer }

function TStringValueReplacer.GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String;
var
  S: String;

  procedure _CheckTerminated;
  var
    L: Integer;
    Term: String;
  begin

    L := Length(S);
    Term := Copy(S, L - 5, 6);
    if (Pos('#$D', Term) > 0) or (Pos('#$A', Term) > 0) then
      Result := Result + CRLF;

  end;

var
  L: Integer;
  i: Integer;
begin

  { TODO -oVasilyevSM -cVDebug : 4000 и RealMax читать из ини }

  Result := Evaluator.Evaluate(Format('Length(%s)', [_Expression]));

  if TryStrToInt(Result, L) then begin

    Result := '';
    i := 0;

    while (i < L) and (i < 400{RealMax}) do begin

      if i mod 40 = 0 then begin

        S := Evaluator.Evaluate(Format('Copy(%s, %d, 40)', [_Expression, i + 1]));

        Result := Result + PureValueText(S);
        _CheckTerminated;

      end;

      Inc(i);

    end;

  end else Result := PureValueText(_EvalResult);

end;

procedure TStringValueReplacer.GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean);
begin
  _TypeName := 'string';
  _AllDescendants := False;
end;

function TStringValueReplacer.GetVisualizerDescription: String;
begin
  Result := SC_StringValueReplacer_Description;
end;

function TStringValueReplacer.GetVisualizerName: String;
begin
  Result := SC_StringValueReplacer_Name;
end;

end.
