unit uParamsReadWriteUtils;

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
  { LiberSynth }
  uTypes, uParams, uCustomReadWrite, uCustomStringParser, uLSNIStringParser, uLSNIDCStringParser, uParamsReader,
  uDCParamsReader, uStringWriter, uCustomParamsCompiler, uLSNIStringParamsCompiler, uLSNIDCStringParamsCompiler;

{ TODO 5 -oVasilyevSM -cuParamsReadWriteUtils: Можно сделать одну рабочую функцию. }
procedure LSNIStrToParams(

    const Source: String;
    Params: TParams;
    ErrorsAssists: TErrorsAssists = [eaLocating];
    ProgressEvent: TProgressEvent = nil

);
procedure LSNIDCStrToParams(

    const Source: String;
    Params: TParams;
    ErrorsAssists: TErrorsAssists = [eaLocating];
    ProgressEvent: TProgressEvent = nil

);
function ParamsToLSNIStr(Params: TParams; Options: TLSNISaveOptions = []): String;
function ParamsToLSNIDCStr(Params: TParams; Options: TLSNISaveOptions = []): String;

implementation

procedure LSNIStrToParams(const Source: String; Params: TParams; ErrorsAssists: TErrorsAssists; ProgressEvent: TProgressEvent);
var
  Reader: TParamsReader;
  Parser: TLSNIStringParser;
begin

  Reader := TParamsReader.Create;
  try

    Reader.RetrieveParams(Params);

    Parser := TLSNIStringParser.Create;
    try

      Parser.ErrorsAssists := ErrorsAssists;
      Parser.ProgressEvent := ProgressEvent;
      Parser.SetSource(Source);

      Reader.RetrieveParser(Parser);

      Parser.RetrieveTargerInterface(Reader);
      try

        Parser.Read;

      finally
        Parser.FreeTargerInterface;
      end;

    finally
      Parser.Free;
    end;

  finally
    Reader.Free;
  end;

end;

procedure LSNIDCStrToParams(const Source: String; Params: TParams; ErrorsAssists: TErrorsAssists; ProgressEvent: TProgressEvent);
var
  Reader: TDCParamsReader;
  Parser: TLSNIDCStringParser;
begin

  Reader := TDCParamsReader.Create;
  try

    Reader.RetrieveParams(Params);

    Parser := TLSNIDCStringParser.Create;
    try

      Parser.ErrorsAssists := ErrorsAssists;
      Parser.ProgressEvent := ProgressEvent;
      Parser.SetSource(Source);

      Reader.RetrieveParser(Parser);

      Parser.RetrieveTargerInterface(Reader);
      try

        Parser.Read;

      finally
        Parser.FreeTargerInterface;
      end;

    finally
      Parser.Free;
    end;

  finally
    Reader.Free;
  end;

end;

function ParamsToLSNIStr(Params: TParams; Options: TLSNISaveOptions): String;
var
  Writer: TStringWriter;
  Compiler: TLSNIStringParamsCompiler;
begin

  Writer := TStringWriter.Create;
  try

    Compiler := TLSNIStringParamsCompiler.Create;
    try

      Compiler.Options := Options;
      Compiler.RetrieveWriter(Writer);
      Compiler.RetrieveParams(Params);
      Compiler.Run;

    finally
      Compiler.Free;
    end;

    Result := Writer.Content;

  finally
    Writer.Free;
  end;

end;

function ParamsToLSNIDCStr(Params: TParams; Options: TLSNISaveOptions): String;
var
  Writer: TStringWriter;
  Compiler: TLSNIDCStringParamsCompiler;
begin

  Writer := TStringWriter.Create;
  try

    Compiler := TLSNIDCStringParamsCompiler.Create;
    try

      Compiler.Options := Options;
      Compiler.RetrieveWriter(Writer);
      Compiler.RetrieveParams(Params);
      Compiler.Run;

    finally
      Compiler.Free;
    end;

    Result := Writer.Content;

  finally
    Writer.Free;
  end;

end;

end.
