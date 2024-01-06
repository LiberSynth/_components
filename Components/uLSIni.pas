unit uLSIni;

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

{ TODO 3 -oVasilyevSM: Нужен формализованный способ выполнять преднастройку для нетипизованных параметров.Примерно через
  вызов функций RegisterParam или просто присвоением. Считывание уже поддерживает такой режим, ему просто нужны все
  параметры, назначенные перед загрузкой. Вот это назначение и надо сделать удобным. }
{ TODO 3 -oVasilyevSM: Режим AutoSave. В каждом SetAs вызывать в нем SaveTo... Куда - зависит от типа выходного
  контекста, ToFile, ToStream, ToString, To Registry. Файл держать открытым, чтобы не перезаписывать целиком каждый раз.
  Итд. }
{ TODO 4 -oVasilyevSM -cuLSIni: Иконка }

{

  Парсер знает, из чего считывать, но не знает, во что.
  Ридер - знает во что, но не знает, из чего.
  Райтер по команде компайлера складывает контекст и отдает.
  Компайлер проходит по объекту и кусками отдает райтеру результат нужного типа.

  CustomParser +
    CustomStringParser +
      LSNIStringParser +
        LSNIDCStringParser +
        LSNIOFStringParser -
      INIStringParser -
        INIDCStringParser -
        INIOFStringParser -
    CustomBLOBParser -
      NTVBLOBParser -
    CustomRegistryParser -
      StructuredRegistryParser -

  CustomReader +
    ParamsReader +
    UserParamsReader +
    OFParamsReader -

  CustomWriter +
    StringWriter +
    BLOBWriter -
    RegistryWriter -

  CustomCompiler +
    CustomParamsCompiler +
      CustomStringParamsCompiler +
        LSNIStringParamsCompiler +
          LSNIDCStringParamsCompiler +
          LSNIOFStringParamsCompiler -
        INIStringParamsCompiler -
          INIDCStringParamsCompiler -
          INIOFStringParamsCompiler -
      BLOBParamsCompiler -
      RegistryParamsCompiler -

}

interface

uses
  { VCL }
  SysUtils, Classes,
  { LiberSynth }
  uComponentTypes, uTypes, uCore, uFileUtils, uParams, uDCParams, uCustomReadWrite, uCustomStringParser,
  uLSNIStringParser, uLSNIDCStringParser, uParamsReader, uDCParamsReader, uStringWriter, uCustomParamsCompiler,
  uLSNIStringParamsCompiler, uLSNIDCStringParamsCompiler;

type

{
                                          Loading specifier Saving Specifier
  Storage:      File, Registry, Custom    LoadSource        SaveSource
  SourceType:   String, BLOB, Structured  Parser            Writer/Compiler
  SourceFormat: LSNI, Classic, Custom     Parser            Writer/Compiler
  Comments:     None, Strict, User        Parser            Writer/Compiler

}
  TSourceType     = (stFile, stRegistryStructured, stRegistrySingleParam, stCustom);
  TStoreMethod    = (smLSNIString, smClassicIni, smBLOB, smCustom);
  TCommentSupport = (csNone, csStockFormat, csOriginarFormat);

  TGetCustomContextProc = procedure (var _Data) of object;
  TSetCustomContextProc = procedure (const _Data) of object;

  TLSIni = class(TComponent)

  strict private

    FStoreMethod: TStoreMethod;
    FSourceType: TSourceType;
    FAutoSave: Boolean;
    FAutoLoad: Boolean;
    FSourcePath: String;
    FErrorsAssists: TErrorsAssists;
    FCommentSupport: TCommentSupport;
    FPathSeparator: Char;
    FStrictDataTypes: Boolean;
    FGetCustomContext: TGetCustomContextProc;
    FSetCustomContext: TSetCustomContextProc;
    FReadProgress: TProgressEvent;
    FWriteProgress: TProgressEvent;
    FLSNISaveOptions: TLSNISaveOptions;

    FParams: TParams;

    procedure InitDefaultProperties;
    function ParamsClass: TParamsClass;
    function ReaderClass: TCustomReaderClass;
    function ParserClass: TCustomParserClass;
    function CompilerClass: TCustomCompilerClass;
    function WriterClass: TCustomWriterClass;
    function SourceFile: String;
    function GetSource: Pointer;
    procedure DoGetCustomContext(var _Data);
    procedure DoSetCustomContext(const _Value);

    procedure SetCommentSupport(const _Value: TCommentSupport);
    procedure SetSourceType(const _Value: TSourceType);
    procedure SetStoreMethod(const _Value: TStoreMethod);
    procedure SetErrorsAssists(const _Value: TErrorsAssists);
    procedure SetStrictDataTypes(const _Value: Boolean);

    procedure SetParserContext(_Parser: TCustomParser);
    procedure SetCompilerFeatures(_Compiler: TCustomCompiler);
    procedure SaveContent(_Writer: TCustomWriter);

  protected

    procedure Loaded; override;

  public

    constructor Create(_Owner: TComponent); override;
    destructor Destroy; override;

    procedure Load;
    procedure Save;

    property Params: TParams read FParams write FParams;

  published

    property StoreMethod: TStoreMethod read FStoreMethod write SetStoreMethod default smLSNIString;
    property SourceType: TSourceType read FSourceType write SetSourceType default stFile;
    property AutoSave: Boolean read FAutoSave write FAutoSave default False;
    property AutoLoad: Boolean read FAutoLoad write FAutoLoad default False;
    property ErrorsAssists: TErrorsAssists read FErrorsAssists write SetErrorsAssists default [eaLocating];
    property CommentSupport: TCommentSupport read FCommentSupport write SetCommentSupport default csNone;
    property SourcePath: String read FSourcePath write FSourcePath;
    property PathSeparator: Char read FPathSeparator write FPathSeparator default '.';
    property StrictDataTypes: Boolean read FStrictDataTypes write SetStrictDataTypes default False;
    property GetCustomContext: TGetCustomContextProc read FGetCustomContext write FGetCustomContext default nil;
    property SetCustomContext: TSetCustomContextProc read FSetCustomContext write FSetCustomContext default nil;
    property ReadProgress: TProgressEvent read FReadProgress write FReadProgress default nil;
    property WriteProgress: TProgressEvent read FWriteProgress write FWriteProgress default nil;
    property LSNISaveOptions: TLSNISaveOptions read FLSNISaveOptions write FLSNISaveOptions;

  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('LiberSynth', [TLSIni]);
end;

{ TLSIni }

constructor TLSIni.Create(_Owner: TComponent);
begin
  inherited Create(_Owner);
  InitDefaultProperties;
end;

destructor TLSIni.Destroy;
begin
  FreeAndNil(FParams);
  inherited Destroy;
end;

procedure TLSIni.InitDefaultProperties;
begin

  FStoreMethod   := smLSNIString;
  FSourceType    := stFile;
  FErrorsAssists := [eaLocating];
  FPathSeparator := '.';

end;

function TLSIni.ParamsClass: TParamsClass;
begin

  case CommentSupport of

    csNone:        Result := TParams;
    csStockFormat: Result := TDCParams;
//    csOriginalFormat:  Result := ;

  else
    raise EUncompletedMethod.Create;
  end;

end;

function TLSIni.ReaderClass: TCustomReaderClass;
const

  Map: array [TCommentSupport] of TCustomReaderClass = (

      { csNone           } TParamsReader,
      { csStockFormat    } TDCParamsReader,
      { csOriginarFormat } TCustomReader

  );

begin

  Result := Map[CommentSupport];

  if Result = TCustomReader then
    raise EUncompletedMethod.Create;

end;

function TLSIni.ParserClass: TCustomParserClass;
const

  Map: array [TStoreMethod, TCommentSupport] of TCustomParserClass = (

                       { csNone,            csStockFormat,       csOriginarFormat }
      { smLSNIString } ( TLSNIStringParser, TLSNIDCStringParser, TCustomParser    ),
      { smClassicIni } ( TCustomParser,     TCustomParser,       TCustomParser    ),
      { smBLOB       } ( TCustomParser,     nil,                 nil              ),
      { smCustom     } ( TCustomParser,     nil,                 nil              )

  );

begin

  Result := Map[StoreMethod, CommentSupport];

  if Result = TCustomParser then
    raise EUncompletedMethod.Create;
  if not Assigned(Result) then
    raise EComponentException.Create('Impossible combination of properties. There are no blobs with comments.');

end;

function TLSIni.CompilerClass: TCustomCompilerClass;
const

  Map: array [TStoreMethod, TCommentSupport] of TCustomCompilerClass = (

                       { csNone                    csStockFormat                csOriginarFormat }
      { smLSNIString } (TLSNIStringParamsCompiler, TLSNIDCStringParamsCompiler, TCustomCompiler  ),
      { smClassicIni } (TCustomCompiler,           TCustomCompiler,             TCustomCompiler  ),
      { smBLOB       } (TCustomCompiler,           nil,                         nil              ),
      { smCustom     } (TCustomCompiler,           nil,                         nil              )

  );

begin

  Result := Map[StoreMethod, CommentSupport];

  if Result = TCustomCompiler then
    raise EUncompletedMethod.Create;
  if not Assigned(Result) then
    raise EComponentException.Create('Impossible combination of properties. There are no blobs with comments.');

end;

function TLSIni.WriterClass: TCustomWriterClass;
const

  Map: array [TSourceType, TStoreMethod, TCommentSupport] of TCustomWriterClass = (

                                             { csNone           csStockFormat    csOriginarFormat }
      { stFile                smLSNIString } ((TStringWriter,   TStringWriter,   TStringWriter    ),
      { stFile                smClassicIni }  (TStringWriter,   TStringWriter,   TStringWriter    ),
      { stFile                smBLOB       }  (TCustomWriter,   nil,             nil              ),
      { stFile                smCustom     }  (TCustomWriter,   nil,             nil              )),
      { stRegistryStructured  smLSNIString } ((TCustomWriter,   nil,             nil              ),
      { stRegistryStructured  smClassicIni }  (TCustomWriter,   nil,             nil              ),
      { stRegistryStructured  smBLOB       }  (TCustomWriter,   nil,             nil              ),
      { stRegistryStructured  smCustom     }  (TCustomWriter,   nil,             nil              )),
      { stRegistrySingleParam smLSNIString } ((TStringWriter,   TStringWriter,   TStringWriter    ),
      { stRegistrySingleParam smClassicIni }  (TStringWriter,   TStringWriter,   TStringWriter    ),
      { stRegistrySingleParam smBLOB       }  (TCustomWriter,   nil,             nil              ),
      { stRegistrySingleParam smCustom     }  (TCustomWriter,   nil,             nil              )),
      { stCustom              smLSNIString } ((TStringWriter,   TStringWriter,   TStringWriter    ),
      { stCustom              smClassicIni }  (TStringWriter,   TStringWriter,   TStringWriter    ),
      { stCustom              smBLOB       }  (TCustomWriter,   nil,             nil              ),
      { stCustom              smCustom     }  (TCustomWriter,   nil,             nil              ))

  );

begin

  Result := Map[SourceType, StoreMethod, CommentSupport];

  if Result = TCustomWriter then
    raise EUncompletedMethod.Create;
  if not Assigned(Result) then
    raise EComponentException.Create('Impossible combination of properties. There are no blobs with comments.');

end;

function TLSIni.SourceFile: String;
begin
  if Length(SourcePath) = 0 then Result := Format('%s\%s.ini', [ExeDir, ExeName])
  else Result := SourcePath;
end;

function TLSIni.GetSource: Pointer;
begin

  Result := nil;
  case SourceType of

    stFile:

      case StoreMethod of

        smLSNIString: String(Result) := FileToStr(SourceFile);
        smClassicIni: String(Result) := FileToStr(SourceFile);
//        smBLOB: ;
//        smCustom: ;

      else
        raise EUncompletedMethod.Create;
      end;

//    stRegistryStructured: ;
//    stRegistrySingleParam: ;
    stCustom: DoGetCustomContext(Result);

  else
    raise EUncompletedMethod.Create;
  end;

end;

procedure TLSIni.DoGetCustomContext(var _Data);
begin
  if Assigned(FGetCustomContext) then
    FGetCustomContext(_Data);
end;

procedure TLSIni.DoSetCustomContext(const _Value);
begin
  if Assigned(FSetCustomContext) then
    FSetCustomContext(_Value);
end;

procedure TLSIni.SetCommentSupport(const _Value: TCommentSupport);
begin

  if _Value <> FCommentSupport then begin

    if (_Value > csNone) and (StoreMethod = smBLOB) then
      raise EComponentException.Create('Invalid combination of properties. Comments are only supported for the string sources.');
    if (_Value > csNone) and (SourceType in [stRegistryStructured, stRegistrySingleParam] ) then
      raise EComponentException.Create('Invalid combination of properties. Comments are not supported for the registry stored source.');

    FCommentSupport := _Value;

  end;

end;

procedure TLSIni.SetCompilerFeatures(_Compiler: TCustomCompiler);
var
  LSNIStringParamsCompiler: ILSNIStringParamsCompiler;
begin
  if _Compiler.GetInterface(ILSNIStringParamsCompiler, LSNIStringParamsCompiler) then
    LSNIStringParamsCompiler.Options := LSNISaveOptions;
end;

procedure TLSIni.SetSourceType(const _Value: TSourceType);
begin

  if _Value <> FSourceType then begin

    if (_Value in [stRegistryStructured, stRegistrySingleParam]) and (CommentSupport > csNone) then
      raise EComponentException.Create('Invalid combination of properties. Comments are not supported when saving to the registry.');

    FSourceType := _Value;

  end;

end;

procedure TLSIni.SetStoreMethod(const _Value: TStoreMethod);
begin

  if _Value <> FStoreMethod then begin

    if (_Value = smBLOB) and (CommentSupport > csNone) then
      raise EComponentException.Create('Invalid combination of properties. Comments are only supported when saving to a string.');

    FStoreMethod := _Value;

  end;

end;

procedure TLSIni.SetErrorsAssists(const _Value: TErrorsAssists);
begin

  if _Value <> FErrorsAssists then begin

    if (eaLocating in _Value) and (SourceType = stRegistryStructured) then
      raise EComponentException.Create('Invalid combination of properties. Error locating are not supported for the registry structured source.');

    FErrorsAssists := _Value;

  end;

end;

procedure TLSIni.SetStrictDataTypes(const _Value: Boolean);
begin

  if _Value <> FStrictDataTypes then begin

    FStrictDataTypes := _Value;
    if Assigned(Params) then
      Params.StrictDataTypes := _Value;

  end;

end;

procedure TLSIni.SetParserContext(_Parser: TCustomParser);
var
  CustomStringParser: ICustomStringParser;
  Context: Pointer;
begin

  Context := GetSource;
  _Parser.SetSource(Context);
  _Parser.FreeContext(Context);

  if _Parser.GetInterface(ICustomStringParser, CustomStringParser) then begin

    CustomStringParser.ErrorsAssists := ErrorsAssists;
    CustomStringParser.ProgressEvent := ReadProgress;

    Exit;

  end;

//    if Parser.GetInterface(ICustomBLOBParser, CustomBLOBParser) then
//      _SetBLOBSource(CustomStringParser)
//    if Parser.GetInterface(ICustomRegistryParser, CustomStringParser) then
//      _SetRegistrySource(CustomRegistryParser)};

  raise EUncompletedMethod.Create;

end;

procedure TLSIni.SaveContent(_Writer: TCustomWriter);
var
  StringWriter: IStringWriter;
  Content: String;
begin

{
                                          Loading specifier Saving Specifier
  Storage:      File, Registry, Custom    LoadSource        SaveSource
  SourceType:   String, BLOB, Structured  Parser            Writer/Compiler
  SourceFormat: LSNI, Classic, Custom     Parser            Writer/Compiler
  Comments:     None, Strict, User        Parser            Writer/Compiler

  TSourceType     = (stFile, stRegistryStructured, stRegistrySingleParam, stCustom);
  TStoreMethod    = (smLSNIString, smClassicIni, smBLOB, smCustom);
  TCommentSupport = (csNone, csStockFormat, csOriginarFormat);

}

  if SourceType = stFile then begin

    if _Writer.GetInterface(IStringWriter, StringWriter) then begin

      CheckDirExisting(ExtractFileDir(SourceFile));
      StrToFile(StringWriter.Content, SourceFile);

    end else raise EUncompletedMethod.Create; { if _Writer.GetInterface(IBLOBWriter, BLOBWriter) then }

  end else if SourceType = stCustom then begin

    if _Writer.GetInterface(IStringWriter, StringWriter) then begin

      Content := StringWriter.Content;
      DoSetCustomContext(Content);

    end else raise EUncompletedMethod.Create; { if _Writer.GetInterface(IBLOBWriter, BLOBWriter) then }

  end else raise EUncompletedMethod.Create;

end;

procedure TLSIni.Loaded;
begin

  inherited Loaded;

  if not (csDesigning in ComponentState) then begin

    FParams := ParamsClass.Create(PathSeparator);
    FParams.StrictDataTypes := StrictDataTypes;

    if AutoLoad then
      Load;

  end;

end;

procedure TLSIni.Load;
var
  Parser: TCustomParser;
  Reader: TCustomReader;
  ParamsReader: IParamsReader;
begin

  Reader := ReaderClass.Create;
  try

    if not Reader.GetInterface(IParamsReader, ParamsReader) then
      raise EReadException.Create('Reader does not support IParamsReader interface.');
    try

      ParamsReader.RetrieveParams(Params);

      Parser := ParserClass.Create;
      try

        ParamsReader.RetrieveParser(Parser);
        SetParserContext(Parser);

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
      ParamsReader := nil;
    end;

  finally
    Reader.Free;
  end;

end;

procedure TLSIni.Save;
var
  Compiler: TCustomCompiler;
  Writer: TCustomWriter;
  CustomParamsCompiler: ICustomParamsCompiler;
begin

  Writer := WriterClass.Create;
  try

    Compiler := CompilerClass.Create;
    try

      Compiler.RetrieveWriter(Writer);

      if not Compiler.GetInterface(ICustomParamsCompiler, CustomParamsCompiler) then
        raise EWriteException.Create('Compiler does not support ICustomParamsCompiler interface.');
      try

        CustomParamsCompiler.RetrieveParams(Params);
        CustomParamsCompiler.RetrieveProgressEvent(WriteProgress);

      finally
        CustomParamsCompiler := nil;
      end;

      SetCompilerFeatures(Compiler);
      Compiler.Run;

    finally
      Compiler.Free;
    end;

    SaveContent(Writer);

  finally
    Writer.Free;
  end;

end;

end.
