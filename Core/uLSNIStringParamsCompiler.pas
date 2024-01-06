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

  TLSNISaveOption  = (soSingleString, soForceQuoteStrings, soTypesFree);
  TLSNISaveOptions = set of TLSNISaveOption;

  ILSNIStringParamsCompiler = interface ['{C30F5C20-3F3B-4B17-9EA8-644415751CE9}']

    function GetOptions: TLSNISaveOptions;
    procedure SetOptions(_Value: TLSNISaveOptions);

    property Options: TLSNISaveOptions read GetOptions write SetOptions;

  end;

  TLSNIStringParamsCompiler = class(TCustomStringParamsCompiler, ILSNIStringParamsCompiler)

  strict private

    FOptions: TLSNISaveOptions;
    FParamFormat: String;
    FParamSplitter: String;

    { ILSNIStringParamsCompiler }
    function GetOptions: TLSNISaveOptions;
    procedure SetOptions(_Value: TLSNISaveOptions);

    function FormatParamsValue(const _Value: String): String;

  protected

    procedure Prepare; virtual;
    function FormatParam(_Param: TParam; _First, _Last: Boolean): String; override;
    function FormatStringValue(const _Value: String): String;
    function CompileNestedParams(_NestedParams: TParams): String;

    property ParamFormat: String read FParamFormat write FParamFormat;
    property ParamSplitter: String read FParamSplitter write FParamSplitter;

  public

    function Clone: TCustomCompiler; override;
    procedure Run; override;

    property Options: TLSNISaveOptions read GetOptions write SetOptions;

  end;

implementation

{ TLSNIStringParamsCompiler }

function TLSNIStringParamsCompiler.GetOptions: TLSNISaveOptions;
begin
  Result := FOptions;
end;

procedure TLSNIStringParamsCompiler.SetOptions(_Value: TLSNISaveOptions);
begin
  FOptions := _Value;
end;

function TLSNIStringParamsCompiler.FormatParamsValue(const _Value: String): String;
begin

  Result := _Value;
  if not (soSingleString in Options) then begin

    if (Length(_Value) > 0) then
      Result := Result + CRLF;

    Result := CRLF + ShiftText(Result, 1);

  end;

  Result := Format('(%s)', [Result]);

end;

procedure TLSNIStringParamsCompiler.Prepare;
const

  SC_VALUE_UNTYPED = '%0:s = %2:s%3:s';
  SC_VALUE_TYPED   = '%0:s: %1:s = %2:s%3:s';

begin

  if soTypesFree in Options then ParamFormat := SC_VALUE_UNTYPED
  else ParamFormat := SC_VALUE_TYPED;
  if soSingleString in Options then ParamSplitter := '; '
  else ParamSplitter := CRLF;

end;

function TLSNIStringParamsCompiler.FormatParam(_Param: TParam; _First, _Last: Boolean): String;
begin

  if _Last then ParamSplitter := '';

  case _Param.DataType of

    dtAnsiString: Result := FormatStringValue(_Param.AsString);
    dtString:     Result := FormatStringValue(_Param.AsString);
    dtParams:     Result := FormatParamsValue(CompileNestedParams(_Param.AsParams));

  else
    Result := _Param.AsString;
  end;

  Result := Format(ParamFormat, [

      _Param.Name,
      ParamDataTypeToStr(_Param.DataType),
      Result,
      ParamSplitter

  ]);

end;

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
  Compiler: TLSNIStringParamsCompiler;
  CustomParamsCompiler: ICustomParamsCompiler;
  StringWriter: IStringWriter;
begin

  Writer := TStringWriter.Create;
  try

    Compiler := Clone as TLSNIStringParamsCompiler;
    try

      Compiler.Nested := True;
      Compiler.RetrieveWriter(Writer);

      if not Compiler.GetInterface(ICustomParamsCompiler, CustomParamsCompiler) then
        raise EWriteException.Create('Compiler does not support ICustomParamsCompiler interface.');
      try

        CustomParamsCompiler.RetrieveParams(_NestedParams);
        CustomParamsCompiler.RetrieveProgressProcess(DoProgressEvent, TotalCount, CurrentStep);

      finally
        CustomParamsCompiler := nil;
      end;

      Compiler.Run;

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

function TLSNIStringParamsCompiler.Clone: TCustomCompiler;
begin
  Result := inherited Clone;
  TLSNIStringParamsCompiler(Result).Options := Options;
end;

procedure TLSNIStringParamsCompiler.Run;
begin
  Prepare;
  inherited Run;
end;

end.
