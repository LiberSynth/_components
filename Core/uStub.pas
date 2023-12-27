unit uStub;

interface

uses
  uParams, uCustomReadWrite, uCustomStringParser, uLSNIStringParser, uParamsReader;

procedure LSNIStrToParams(const Source: String; Params: TParams);

implementation

procedure LSNIStrToParams(const Source: String; Params: TParams);
var
  Parser: TCustomParser;
  Reader: TCustomReader;
  ParamsReader: IParamsReader;
  CustomStringParser: ICustomStringParser;
begin

  Reader := TParamsReader.Create;
  try

    if not Reader.GetInterface(IParamsReader, ParamsReader) then
      raise ECustomReadWriteException.Create('Reader does not support IParamsReader interface.');
    try

      ParamsReader.RetrieveParams(Params);

      Parser := TLSNIStringParser.Create;
      try

        if not Parser.GetInterface(ICustomStringParser, CustomStringParser) then
          raise ECustomReadWriteException.Create('Parser does not support ICustomStringParser interface.');
        try

          CustomStringParser.Located := True;
          CustomStringParser.NativeException := True;
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
