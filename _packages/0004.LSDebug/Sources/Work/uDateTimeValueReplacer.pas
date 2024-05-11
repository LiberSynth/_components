unit uDateTimeValueReplacer;

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
  { VCL }
  SysUtils,
  { LSDebug }
  uCustomVizualizers, uCommon, uStrUtils, uDataUtils;

type

  TDateTimeValueReplacer = class(TCustomValueReplacer)

  protected

    function GetAllExpressionsReplacement: Boolean; override;

    { IOTADebuggerVisualizer }
    procedure GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean); override;
    function GetVisualizerName: String; override;
    function GetVisualizerDescription: String; override;

    function GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String; override;

  end;

implementation

{ TDateTimeValueReplacer }

function TDateTimeValueReplacer.GetAllExpressionsReplacement: Boolean;
begin
  Result := True;
end;

procedure TDateTimeValueReplacer.GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean);
begin
  _TypeName := 'TDateTime';
  _AllDescendants := True;
end;

function TDateTimeValueReplacer.GetVisualizerName: String;
begin
  Result := 'TDateTime value replacer for Delphi';
end;

function TDateTimeValueReplacer.GetVisualizerDescription: String;
begin

  Result :=

      'TDateTime value replacer for Delphi debugger. For expression with key ''d'', replaces the default date-time ' +
      'representation with its string representation in the specified format.';

end;

function TDateTimeValueReplacer.GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String;
var
  DateTime: TDateTime;
begin

  with Evaluator do begin

    InitVariable('Context', 'TDateTime', SizeOf(TDateTime), _Expression);
    try

      ReadVariable('Context', DateTime);
      Result := FormatDateTimeEx(PackageParams.AsString['Common.DateTimeFormat'], DateTime);

    finally
      FinVariable('Context');
    end;

  end;

end;

end.
