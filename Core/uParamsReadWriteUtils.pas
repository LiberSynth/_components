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
  uUserParamsReader, uStringWriter, uCustomParamsCompiler, uLSNIStringParamsCompiler, uLSNIDCStringParamsCompiler;

{ TODO 5 -oVasilyevSM -cuParamsReadWriteUtils: Можно сделать одну рабочую функцию. }
procedure LSNIStrToParams(

    const Source: String;
    Params: TParams;
    Located: Boolean = True;
    NativeException: Boolean = False;
    ProgressEvent: TProgressEvent = nil

);
procedure LSNIDCStrToParams(

    const Source: String;
    Params: TParams;
    Located: Boolean = True;
    NativeException: Boolean = False;
    ProgressEvent: TProgressEvent = nil

);
function ParamsToLSNIStr(Params: TParams; Options: TSaveToStringOptions = []): String;
function ParamsToLSNIDCStr(Params: TParams; Options: TSaveToStringOptions = []): String;

implementation

procedure LSNIStrToParams(const Source: String; Params: TParams; Located, NativeException: Boolean; ProgressEvent: TProgressEvent);
var
  Reader: TParamsReader;
  Parser: TLSNIStringParser;
begin

  Reader := TParamsReader.Create;
  try

    Reader.RetrieveParams(Params);

    Parser := TLSNIStringParser.Create;
    try

      Parser.Located         := Located;
      Parser.NativeException := NativeException;
      Parser.ProgressEvent   := ProgressEvent;
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

procedure LSNIDCStrToParams(const Source: String; Params: TParams; Located, NativeException: Boolean; ProgressEvent: TProgressEvent);
var
  Reader: TUserParamsReader;
  Parser: TLSNIDCStringParser;
begin

  Reader := TUserParamsReader.Create;
  try

    Reader.RetrieveParams(Params);

    Parser := TLSNIDCStringParser.Create;
    try

      Parser.Located := Located;
      Parser.NativeException := NativeException;
      Parser.ProgressEvent   := ProgressEvent;
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

function ParamsToLSNIStr(Params: TParams; Options: TSaveToStringOptions): String;
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

function ParamsToLSNIDCStr(Params: TParams; Options: TSaveToStringOptions): String;
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
