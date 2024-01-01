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
  uParams, uCustomReadWrite, uCustomStringParser, uLSNIStringParser, uLSNIDCStringParser, uParamsReader;

procedure LSNIStrToParams(const Source: String; Params: TParams; Located: Boolean = True; NativeException: Boolean = False);
procedure LSNIDCStrToParams(const Source: String; Params: TParams; Located: Boolean = True; NativeException: Boolean = False);

implementation

procedure LSNIStrToParams(const Source: String; Params: TParams; Located, NativeException: Boolean);
var
  Reader: TCustomReader;
  ParamsReader: IParamsReader;
  Parser: TCustomParser;
  CustomStringParser: ICustomStringParser;
begin

  Reader := TParamsReader.Create;
  try

    if not Reader.GetInterface(IParamsReader, ParamsReader) then
      raise EReadException.Create('Reader does not support IParamsReader interface.');
    try

      ParamsReader.RetrieveParams(Params);

      Parser := TLSNIStringParser.Create;
      try

        if not Parser.GetInterface(ICustomStringParser, CustomStringParser) then
          raise EReadException.Create('Parser does not support ICustomStringParser interface.');
        try

          CustomStringParser.Located := Located;
          CustomStringParser.NativeException := NativeException;
          CustomStringParser.SetSource(Source);

          ParamsReader.RetrieveParser(Parser);

          Parser.RetrieveTargerInterface(Reader);
          try

            Parser.Read;

          finally
            Parser.FreeTargerInterface;
          end;

        finally
          CustomStringParser := nil;
        end;

      finally
        Parser.Free;
      end;

    finally
      ParamsReader := nil;
    end;

  finally
    Reader.Free;
  end;

end;

procedure LSNIDCStrToParams(const Source: String; Params: TParams; Located, NativeException: Boolean);
var
  Parser: TCustomParser;
  Reader: TCustomReader;
  ParamsReader: IParamsReader;
  CustomStringParser: ICustomStringParser;
begin

  Reader := TParamsReader.Create;
  try

    if not Reader.GetInterface(IParamsReader, ParamsReader) then
      raise EReadException.Create('Reader does not support IParamsReader interface.');
    try

      ParamsReader.RetrieveParams(Params);

      Parser := TLSNIDCStringParser.Create;
      try

        if not Parser.GetInterface(ICustomStringParser, CustomStringParser) then
          raise EReadException.Create('Parser does not support ICustomStringParser interface.');
        try

          CustomStringParser.Located := Located;
          CustomStringParser.NativeException := NativeException;
          CustomStringParser.SetSource(Source);

          ParamsReader.RetrieveParser(Parser);

          Parser.RetrieveTargerInterface(Reader);
          try

            Parser.Read;

          finally
            Parser.FreeTargerInterface;
          end;

        finally
          CustomStringParser := nil;
        end;

      finally
        Parser.Free;
      end;

    finally
      ParamsReader := nil;
    end;

  finally
    Reader.Free;
  end;

end;

end.
