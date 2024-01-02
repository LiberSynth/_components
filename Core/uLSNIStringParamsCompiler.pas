unit uLSNIStringParamsCompiler;

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
  uCustomStringParamsCompiler, uParams, uConsts, uStrUtils, uStringWriter, uCustomReadWrite, uCustomParamsCompiler;

type

  TSaveToStringOption  = (soSingleString, soForceQuoteStrings, soTypesFree);
  TSaveToStringOptions = set of TSaveToStringOption;

  TLSNIStringParamsCompiler = class(TCustomStringParamsCompiler)

  strict private

    FOptions: TSaveToStringOptions;

    function FormatStringValue(const _Value: String): String;
    function CompileNestedParams(_NestedParams: TParams): String;

  protected

    function FormatParam(_Param: TParam; _First, _Last: Boolean): String; override;

  public

    function Clone: TCustomCompiler; override;

    property Options: TSaveToStringOptions read FOptions write FOptions;

  end;

implementation

{ TLSNIStringParamsCompiler }

function TLSNIStringParamsCompiler.FormatStringValue(const _Value: String): String;
begin

  if

      (soForceQuoteStrings in Options) or
      { Заключаем в кавычки по необходимости. Это только строки с этими символами: }
      (Pos(CR,  Result) > 0) or
      (Pos(LF,  Result) > 0) or
      (Pos(';', Result) > 0) or
      (Pos('=', Result) > 0) or
      (Pos(':', Result) > 0) or
      { Интересный случай, пока они не вложенные, все работает. Но вложенные воспринимают ")" как конец свей
        вложенности, а остаток начинает мастер дочитывать. Поэтому, для порядку обе скобки суем в кавычки. }
      (Pos('(', Result) > 0) or
      (Pos(')', Result) > 0)

  then Result := QuoteStr(_Value)
  else Result := _Value;

end;

function TLSNIStringParamsCompiler.CompileNestedParams(_NestedParams: TParams): String;
var
  Writer: TStringWriter;
  Compiler: TCustomCompiler;
  CustomParamsCompiler: ICustomParamsCompiler;
  StringWriter: IStringWriter;
begin

  Writer := TStringWriter.Create;
  try

    Compiler := Clone;
    try

      Compiler.RetrieveWriter(Writer);

      if not Compiler.GetInterface(ICustomParamsCompiler, CustomParamsCompiler) then
        raise EWriteException.Create('Compiler does not support ICustomParamsCompiler interface.');
      try

        CustomParamsCompiler.RetrieveParams(_NestedParams);
        Compiler.Run;

      finally
        CustomParamsCompiler := nil;
      end;

    finally
      Compiler.Free;
    end;

    if not Writer.GetInterface(IStringWriter, StringWriter) then
      raise EWriteException.Create('Writer does not support IStringWriter interface.');
    try

      Result := StringWriter.Content;

    finally
      StringWriter := nil;
    end;

  finally
    Writer.Free;
  end;

end;

function TLSNIStringParamsCompiler.FormatParam(_Param: TParam; _First, _Last: Boolean): String;
const

  SC_VALUE_UNTYPED = '%0:s = %2:s%3:s';
  SC_VALUE_TYPED   = '%0:s: %1:s = %2:s%3:s';

var
  ParamFormat: String;
  Splitter: String;
  Value: String;
begin

  if _Param.DataType = dtParams then begin

    Value := CompileNestedParams(_Param.AsParams);

    if (soSingleString in Options) or (_Param.AsParams.Count = 0) then

      Value := Format('(%s)', [Value])

    else begin

      if Length(Value) > 0 then Value := Value + CRLF;
      Value := Format('(%s%s)', [CRLF, ShiftText(Value, 1)]);

    end;

  end else if _Param.DataType in [dtAnsiString, dtString] then

    Value := FormatStringValue(_Param.AsString)

  else Value := _Param.AsString;

  if soTypesFree in Options then ParamFormat := SC_VALUE_UNTYPED
  else ParamFormat := SC_VALUE_TYPED;

  if _Last then Splitter := ''
  { TODO 1 -oVasilyevSM -cuLSNIStringParamsCompiler: Ошибка: в однострочном режиме не хватает ' ' после ;. }
  else if soSingleString in Options then Splitter := ';'
  else Splitter := CRLF;

  Result := Format(ParamFormat, [

      _Param.Name,
      ParamDataTypeToStr(_Param.DataType),
      Value,
      Splitter

  ]);

end;

function TLSNIStringParamsCompiler.Clone: TCustomCompiler;
begin
  Result := inherited Clone;
  TLSNIStringParamsCompiler(Result).Options := Options;
end;

end.
