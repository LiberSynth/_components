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

{ TODO 3 -oVasilyevSM: В Save нужен еще один режим, явное указание типа параметра в ини-файле или без него. И тогда при
  считывании тип должен предварительно определяться в приложении примерно через вызов функций RegisterParam. Таким
  образом, имеем два формата ини-файла, полный и краткий. В Load также можно вызывать из пустого контейнера с готовой
  структурой. Тогда она просто заполняется данными, типы известны и не требуют хранения в строке. }
{ TODO 3 -oVasilyevSM: Режим "сохранять строки всегда в кавычках" }
{ TODO 3 -oVasilyevSM: Режим AutoSave. В каждом SetAs вызывать в нем SaveTo... Куда - зависит от типа оъекта,
  ToFile, ToStream, ToString, To Registry. Файл держать открытым, чтобы не перезаписывать целиком каждый раз. Итд. }
{ TODO 4 -oVasilyevSM -cuLSIni: Иконка }

{

  Парсер знает, из чего считывать, но не знает, во что.
  Ридер - знает во что, но не знает, из чего.
  Масштаб трагедии (без учета Typed и Untyped):

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
      CustomSingleParamRegistryParser -
        SingleStringParamRegistryParser -
        SingleBLOBParamRegistryParser -
  CustomReader
    ParamsReader +
    UserParamsReader +
    OFParamsReader -

  CustomWriter +
    CustomStringWriter -
      LSNIParamsWriter -
        LSNIDCParamsWriter -
        LSNIOFParamsWriter -
      INIParamsWriter -
        INIDCParamsWriter -
        INIOFParamsWriter -
    CustomBLOBWriter -
      NTVBLOBWriter -
    CustomRegistryWriter~
      CustomParamsRegistryWriter~
        ParamsStructuredRegistryWriter~
        CustomParamsSingleParamRegistryWriter~
          ParamsSingleStringParamRegistryWriter~
          ParamsSingleBLOBParamRegistryWriter~

}

interface

uses
  { VCL }
  SysUtils, Classes,
  { LiberSynth }
  uComponentTypes, uTypes, uCore, uFileUtils, uParams, uUserParams, uCustomReadWrite, uCustomStringParser,
  uLSNIStringParser, uLSNIDCStringParser, uParamsReader, uUserParamsReader, uStringWriter, uCustomParamsCompiler,
  uLSNIStringParamsCompiler;

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

  TGetCustomSourceProc = procedure (var _Value) of object;

  TLSIni = class(TComponent)

  strict private

    FStoreMethod: TStoreMethod;
    FSourceType: TSourceType;
    FAutoSave: Boolean;
    FAutoLoad: Boolean;
    FSourcePath: String;
    FErrorsLocating: Boolean;
    FNativeException: Boolean;
    FCommentSupport: TCommentSupport;
    FPathSeparator: Char;
    FStrictDataTypes: Boolean;
    FGetCustomSource: TGetCustomSourceProc;
    FProgress: TProgressEvent;

    FParams: TParams;

    procedure InitDefaultProperties;
    function ParamsClass: TParamsClass;
    function ReaderClass: TCustomReaderClass;
    function ParserClass: TCustomParserClass;
    function CompilerClass: TCustomCompilerClass;
    function WriterClass: TCustomWriterClass;
    function SourceFile: String;
    function GetSourceString: String;
    function DoGetCustomSourceString: String;

    procedure SetCommentSupport(const _Value: TCommentSupport);
    procedure SetSourceType(const _Value: TSourceType);
    procedure SetStoreMethod(const _Value: TStoreMethod);
    procedure SetErrorsLocating(const _Value: Boolean);
    procedure SetStrictDataTypes(const _Value: Boolean);

    procedure SetParserSource(_Parser: TCustomParser);

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
    property ErrorsLocating: Boolean read FErrorsLocating write SetErrorsLocating default True;
    property NativeException: Boolean read FNativeException write FNativeException default False;
    property CommentSupport: TCommentSupport read FCommentSupport write SetCommentSupport default csNone;
    property SourcePath: String read FSourcePath write FSourcePath;
    property PathSeparator: Char read FPathSeparator write FPathSeparator default '.';
    property StrictDataTypes: Boolean read FStrictDataTypes write SetStrictDataTypes default False;
    property GetCustomSource: TGetCustomSourceProc read FGetCustomSource write FGetCustomSource default nil;
    property Progress: TProgressEvent read FProgress write FProgress default nil;

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

  FStoreMethod    := smLSNIString;
  FSourceType     := stFile;
  FErrorsLocating := True;
  FPathSeparator  := '.';

end;

function TLSIni.ParamsClass: TParamsClass;
begin

  case CommentSupport of

    csNone:        Result := TParams;
    csStockFormat: Result := TUserParams;
//    csOriginalFormat:  Result := ;

  else
    raise EUncompletedMethod.Create;
  end;

end;

function TLSIni.ReaderClass: TCustomReaderClass;
const

  Map: array [TCommentSupport] of TCustomReaderClass = (

      { csNone           } TParamsReader,
      { csStockFormat    } TUserParamsReader,
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

                       { csNone                    csStockFormat        csOriginarFormat }
      { smLSNIString } (TLSNIStringParamsCompiler, TCustomCompiler,     TCustomCompiler  ),
      { smClassicIni } (TCustomCompiler,           TCustomCompiler,     TCustomCompiler  ),
      { smBLOB       } (TCustomCompiler,           nil,                 nil              ),
      { smCustom     } (TCustomCompiler,           nil,                 nil              )

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
      { stFile                smLSNIString } ((TStringWriter,   TCustomWriter,   TCustomWriter    ),
      { stFile                smClassicIni }  (TCustomWriter,   TCustomWriter,   TCustomWriter    ),
      { stFile                smBLOB       }  (TCustomWriter,   nil,             nil              ),
      { stFile                smCustom     }  (TCustomWriter,   nil,             nil              )),
      { stRegistryStructured  smLSNIString } ((TCustomWriter,   nil,             nil              ),
      { stRegistryStructured  smClassicIni }  (TCustomWriter,   nil,             nil              ),
      { stRegistryStructured  smBLOB       }  (TCustomWriter,   nil,             nil              ),
      { stRegistryStructured  smCustom     }  (TCustomWriter,   nil,             nil              )),
      { stRegistrySingleParam smLSNIString } ((TCustomWriter,   TCustomWriter,   TCustomWriter    ),
      { stRegistrySingleParam smClassicIni }  (TCustomWriter,   TCustomWriter,   TCustomWriter    ),
      { stRegistrySingleParam smBLOB       }  (TCustomWriter,   nil,             nil              ),
      { stRegistrySingleParam smCustom     }  (TCustomWriter,   nil,             nil              )),
      { stCustom              smLSNIString } ((TCustomWriter,   TCustomWriter,   TCustomWriter    ),
      { stCustom              smClassicIni }  (TCustomWriter,   TCustomWriter,   TCustomWriter    ),
      { stCustom              smBLOB       }  (TCustomWriter,   nil,             nil              ),
      { stCustom              smCustom     }  (TCustomWriter,   nil,             nil              ))

  );

begin

  Result := Map[SourceType, StoreMethod, CommentSupport];

//  if Result = TCustomWriter then
//    raise EUncompletedMethod.Create;
//  if not Assigned(Result) then
//    raise EComponentException.Create('Impossible combination of properties. There are no blobs with comments.');

end;

function TLSIni.SourceFile: String;
begin
  if Length(SourcePath) = 0 then Result := Format('%s\%s.ini', [ExeDir, ExeName])
  else Result := SourcePath;
end;

function TLSIni.GetSourceString: String;
begin

  if StoreMethod = smBLOB then
    raise EComponentException.Create('Impossible combination: blob reading and string source.');

  Result := '';
  case SourceType of

    stFile:                Result := FileToStr(SourceFile);
    stRegistryStructured:  raise EComponentException.Create('Impossible combination: registry reading and string source.');
//    stRegistrySingleParam: ;
    stCustom: Result := DoGetCustomSourceString; { Именно здесь - строка. GetSourceBLOB - BLOB. }

  else
    raise EUncompletedMethod.Create;
  end;

end;

function TLSIni.DoGetCustomSourceString: String;
begin
  if Assigned(FGetCustomSource) then
    FGetCustomSource(Result);
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

procedure TLSIni.SetStrictDataTypes(const _Value: Boolean);
begin

  if _Value <> FStrictDataTypes then begin

    FStrictDataTypes := _Value;
    if Assigned(Params) then
      Params.StrictDataTypes := _Value;

  end;

end;

procedure TLSIni.SetErrorsLocating(const _Value: Boolean);
begin

  if _Value <> FErrorsLocating then begin

    if _Value and (SourceType = stRegistryStructured) then
      raise EComponentException.Create('Invalid combination of properties. Error locating are not supported for the registry structured source.');

    FErrorsLocating := _Value;

  end;

end;

procedure TLSIni.SetParserSource(_Parser: TCustomParser);
var
  CustomStringParser: ICustomStringParser;
begin

  if _Parser.GetInterface(ICustomStringParser, CustomStringParser) then

    try

      CustomStringParser.Located         := ErrorsLocating;
      CustomStringParser.NativeException := NativeException;
      CustomStringParser.ProgressEvent   := Progress;

      CustomStringParser.SetSource(GetSourceString);
      Exit;

    finally
      CustomStringParser := nil;
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
begin

  if not _Writer.GetInterface(IStringWriter, StringWriter) then
    raise EWriteException.Create('Writer does not support IStringWriter interface.');

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

    CheckDirExisting(ExtractFileDir(SourceFile));
    StrToFile(StringWriter.Content, SourceFile);

  end else raise EUncompletedMethod.Create;

//  if SourceType = stCustom then begin
//    event
//  end;

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
        SetParserSource(Parser);

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
        Compiler.Run;

      finally
        CustomParamsCompiler := nil;
      end;

    finally
      Compiler.Free;
    end;

    SaveContent(Writer);

  finally
    Writer.Free;
  end;

end;

end.
