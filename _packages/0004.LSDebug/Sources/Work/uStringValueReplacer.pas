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
  { LiberSynth }
  uClasses, uCustomVizualizers, uCleanDebuggerString, uDataUtils, uProjectConsts, uConsts,
  {$IFDEF DEBUG}
  uLog,
  {$ENDIF}
  { Project }
  uCommon;

type

  TStringValueReplacer = class(TCustomValueReplacer)

  strict private

    function ExpressionLength(const _Expression: String): Integer;

  protected

    { IOTADebuggerVisualizer }
    procedure GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean); override;
    function GetVisualizerName: String; override;
    function GetVisualizerDescription: String; override;

    function GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String; override;

  end;

implementation

{ TStringValueReplacer }

function TStringValueReplacer.GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String;
const

  SC_MESSAGE = '[To see more results increase the param %s: StringValueReplacer.ResultLengthLimit. But be ready to wait longer.]';

var
  S: String;
  ResultLengthLimit, MaxEvaluatingLength: Integer;
  Len, i, Steps: Integer;
  LogMessage, StepExpression: String;
begin

  try

    LogMessage := 'String replacing started.' + CRLF;

    Result := CleanDebuggerString(_EvalResult);
    Len := Length(Result);

    LogMessage := LogMessage + 'Default processing success.' + CRLF;

    { Если дефолтной длины не хватило фактически. }
    if (Len > 2) and (Copy(Result, Len - 2, Len) = '...') then begin

      LogMessage := LogMessage + 'Custom processing is reqiured.' + CRLF;

      Result := '';
      { Длина результата исследуемого выражения }
      Len := ExpressionLength(_Expression);
      { Ограничение длины результата для того, чтобы не было слишком большой задержки. }
      ResultLengthLimit := PackageParams.AsInteger['StringValueReplacer.ResultLengthLimit' ];
      { Максимальная дефолтная длина, можно задать в ини в случае, если это не 4096 в текущей версии Delphi. }
      MaxEvaluatingLength := PackageParams.AsInteger['StringValueReplacer.MaxEvaluatingLength'];
      { Количество необходимых вычислений по частям. }
      Steps := Min(Len, ResultLengthLimit) div MaxEvaluatingLength;

      LogMessage := Format('%s' + 'Len = %d; ResultLengthLimit = %d; MaxEvaluatingLength = %d; Steps = %d', [

          LogMessage,
          Len,
          ResultLengthLimit,
          MaxEvaluatingLength,
          Steps

      ]) + CRLF;

      for i := 0 to Steps do begin

        LogMessage := LogMessage + Format('Step %d started.', [i]) + CRLF;

        StepExpression := Format('Copy(%s, %d, %d)', [

            _Expression,
            i * MaxEvaluatingLength + 1,
            MaxEvaluatingLength

        ]);
        LogMessage := Format('%sExpression: %s', [LogMessage, StepExpression]);
        { Часть, которую эвалюэйтор сможет вернуть не олбрезая результат. }
        S := Evaluator.Evaluate(StepExpression);

        LogMessage := LogMessage + Format('Evaluating on step %d is completed.', [i]) + CRLF;

        Result := Result + CleanDebuggerString(S);

        LogMessage := LogMessage + Format('String transformation on step %d is completed.', [i]) + CRLF;

      end;

      { В случае превышении ограничения, заданного в ини, подсказка, что можно его увеличить. }
      if Len > ResultLengthLimit then
        Result := Result + '...' + CRLF + CRLF + Format(SC_MESSAGE, [PackageParamsFile]);

    end;

    LogMessage := LogMessage + 'String replacing completed.';

  except

    on E: Exception do begin

      WriteLog(LogMessage);
      raise;

    end;

  end;

end;

function TStringValueReplacer.ExpressionLength(const _Expression: String): Integer;
var
  S: String;
begin

  try

    S := Evaluator.Evaluate(Format('Length(%s)', [_Expression]));
    Result := StrToInt(S);

  except
    Result := -1;
  end;

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
