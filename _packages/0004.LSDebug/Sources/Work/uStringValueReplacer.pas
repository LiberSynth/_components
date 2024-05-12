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
  SysUtils, Windows,
  { LiberSynth }
  uClasses, uCustomVizualizers, uCleanDebuggerString, uDataUtils, uConsts, uLog,
  { Project }
  uCommon;

type

  TStringValueReplacer = class(TCustomValueReplacer)

  strict private

    function ExpressionLength(const _Expression: String): Integer;
    function DirectMemoryValue(const _Expression: String): String;
    function IteratedResearch(const _Expression, _EvalResult: String): String;

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
var
  Method: String;
begin

  Method := PackageParams.AsString['StringValueReplacer.Method'];

  if SameText(Method, 'DirectMemoryValue') then

    Result := DirectMemoryValue(_Expression)

  else if SameText(Method, 'IteratedResearch') then

    Result := IteratedResearch(_Expression, _EvalResult)

  else Result := inherited GetCustomReplacementValue(_Expression, _TypeName, _EvalResult);

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

function TStringValueReplacer.DirectMemoryValue(const _Expression: String): String;
var
  Len: Integer;
  Address: NativeInt;
  Data: PWideChar;
  LogMessage: String;
begin

  try

    LogMessage := 'String replacing started.' + CRLF;

    with Evaluator do begin

      Len := ExpressionLength(_Expression);

      LogMessage := LogMessage + Format('Value length = %d' + CRLF, [Len]);

      { Инициализация переменной в памяти отлаживаемого процесса. }
      InitVariable('Context', 'String', Len * 2, _Expression);
      try

        LogMessage := LogMessage + 'Context initialized in debugging process memory.' + CRLF;

        { Получение адреса первого символа строки }
        ReadFunction(

            'NativeInt(@(<Context>[1]))',
            'NativeInt',
            SizeOf(NativeInt),
            Address

        );

        LogMessage := LogMessage + Format('Address of first character is %d.' + CRLF, [Address]);

        Data := AllocMem(Len * 2);
        try

          LogMessage := LogMessage + 'Local value memory allocated.' + CRLF;

          { Считывание строки из памяти отлаживаемого процесса }
          CurrentProcess.ReadProcessMemory(Address, Len * 2, Data^);
          LogMessage := LogMessage + 'Value read from debugging process memory.' + CRLF;

          Result := Copy(Data, 1, Len);
          LogMessage := LogMessage + 'Result is retrieved.' + CRLF;

        finally
          FreeMem(Data, Len * 2);
          LogMessage := LogMessage + 'Local memory freed.' + CRLF;
        end;

      finally
        FinVariable('<Context>');
        LogMessage := LogMessage + 'Context finalized in debugging process memory.' + CRLF;
      end;

    end;

    LogMessage := LogMessage + 'String replacing completed.' + CRLF;

  except

    on E: Exception do begin

      WriteLog(LogMessage);
      Result := FormatException(E);

    end;

  end;

end;

function TStringValueReplacer.IteratedResearch(const _Expression, _EvalResult: String): String;
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

    LogMessage := LogMessage + 'String replacing completed.' + CRLF;

  except

    on E: Exception do begin

      WriteLog(LogMessage);
      Result := FormatException(E);

    end;

  end;

end;

procedure TStringValueReplacer.GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean);
begin
  _TypeName := 'string';
  _AllDescendants := True;
end;

function TStringValueReplacer.GetVisualizerName: String;
begin
  Result := 'String value replacer for Delphi';
end;

function TStringValueReplacer.GetVisualizerDescription: String;
begin

  Result :=

      'String value replacer for Delphi debugger. For expression with key ''d'' it replaces the default hexadecimal ' +
      'representation of the special characters to the regular string as it is.';

end;

end.
