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

{ TODO 3 -oVasilyevSM -cuLSIni: Нужен будет еще один контроль - после завершения считывания нельзя менять свойства
  считывателя, экспортера и параметров. Это не адаптер. Если нужен адаптер, можно написать его, используя имеющиеся в
  паблике классы. }
{ TODO 4 -oVasilyevSM -cuLSIni: Иконка }

(*

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

*)

interface

uses
  { VCL }
  SysUtils, Classes,
  { LiberSynth }
  uCore, uFileUtils, uParams, uUserParams, uCustomReadWrite, uCustomStringParser, uLSNIStringParser, uLSNIDCStringParser,
  uParamsReader, uUserParamsReader, uComponentTypes;

type

  TIniStoreMethod = (smLSNIString, smClassicIni, smBLOB);
  TIniSourceType  = (stFile, stRegistryStructured, stRegistrySingleParam, stCustom);
  TCommentSupport = (csNone, csStockFormat, csOriginarFormat);

  TGetCustomSourceProc = procedure (var _Value) of object;

  TLSIni = class(TComponent)

  strict private

    FStoreMethod: TIniStoreMethod;
    FSourceType: TIniSourceType;
    FAutoSave: Boolean;
    FAutoLoad: Boolean;
    FSourcePath: String;
    FErrorsLocating: Boolean;
    FNativeException: Boolean;
    FCommentSupport: TCommentSupport;
    FGetCustomSource: TGetCustomSourceProc;

    FParams: TParams;

    procedure InitProperties;
    function ParamsClass: TParamsClass;
    function ReaderClass: TCustomReaderClass;
    function ParserClass: TCustomParserClass;
    function SourceFile: String;
    function GetSourceString: String;
    function DoGetCustomSourceString: String;

    procedure SetCommentSupport(const _Value: TCommentSupport);
    procedure SetSourceType(const _Value: TIniSourceType);
    procedure SetStoreMethod(const _Value: TIniStoreMethod);
    procedure SetErrorsLocating(const _Value: Boolean);

  protected

    procedure Loaded; override;

  public

    constructor Create(_Owner: TComponent); override;
    destructor Destroy; override;

    procedure Save;
    procedure Load;

    property Params: TParams read FParams write FParams;

  published

    property StoreMethod: TIniStoreMethod read FStoreMethod write SetStoreMethod;
    property SourceType: TIniSourceType read FSourceType write SetSourceType;
    property AutoSave: Boolean read FAutoSave write FAutoSave;
    property AutoLoad: Boolean read FAutoLoad write FAutoLoad;
    property ErrorsLocating: Boolean read FErrorsLocating write SetErrorsLocating;
    property NativeException: Boolean read FNativeException write FNativeException;
    property CommentSupport: TCommentSupport read FCommentSupport write SetCommentSupport;
    property SourcePath: String read FSourcePath write FSourcePath;
    property GetCustomSource: TGetCustomSourceProc read FGetCustomSource write FGetCustomSource;

  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('LiberSynth', [TLSIni]);
end;

{ TLSIni }

procedure TLSIni.Save;
begin
  CheckDirExisting(ExtractFileDir(SourceFile));
  StrToFile(Params.SaveToString, SourceFile);
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

procedure TLSIni.SetErrorsLocating(const _Value: Boolean);
begin

  if _Value <> FErrorsLocating then begin

    if _Value and (SourceType = stRegistryStructured) then
      raise EComponentException.Create('Invalid combination of properties. Error locating are not supported for the registry structured source.');

    FErrorsLocating := _Value;

  end;

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

procedure TLSIni.SetSourceType(const _Value: TIniSourceType);
begin

  if _Value <> FSourceType then begin

    if (_Value in [stRegistryStructured, stRegistrySingleParam]) and (CommentSupport > csNone) then
      raise EComponentException.Create('Invalid combination of properties. Comments are not supported when saving to the registry.');

    FSourceType := _Value;

  end;

end;

procedure TLSIni.SetStoreMethod(const _Value: TIniStoreMethod);
begin

  if _Value <> FStoreMethod then begin

    if (_Value = smBLOB) and (CommentSupport > csNone) then
      raise EComponentException.Create('Invalid combination of properties. Comments are only supported when saving to a string.');

    FStoreMethod := _Value;

  end;

end;

function TLSIni.SourceFile: String;
begin
  if Length(SourcePath) = 0 then Result := Format('%s\%s.ini', [ExeDir, ExeName])
  else Result := SourcePath;
end;

constructor TLSIni.Create(_Owner: TComponent);
begin

  inherited Create(_Owner);

  if csDesigning in ComponentState then
    InitProperties;

end;

destructor TLSIni.Destroy;
begin
  FreeAndNil(FParams);
  inherited Destroy;
end;

function TLSIni.DoGetCustomSourceString: String;
begin
  if Assigned(FGetCustomSource) then
    FGetCustomSource(Result);
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

  Map: array [TIniStoreMethod, TCommentSupport] of TCustomParserClass = (

                       { csNone,            csStockFormat,       csOriginarFormat }
      { smLSNIString } ( TLSNIStringParser, TLSNIDCStringParser, TCustomParser    ),
      { smClassicIni } ( TCustomParser,     TCustomParser,       TCustomParser    ),
      { smBLOB       } ( TCustomParser,     nil,                 nil              )

  );

begin

  Result := Map[StoreMethod, CommentSupport];

  if Result = TCustomParser then
    raise EUncompletedMethod.Create;
  if not Assigned(Result) then
    raise EComponentException.Create('Impossible combination of properties. There are no blobs with comments.');

end;

procedure TLSIni.InitProperties;
begin

  FStoreMethod    := smLSNIString;
  FSourceType     := stFile;
  FErrorsLocating := True;

end;

procedure TLSIni.Load;
var
  Parser: TCustomParser;
  Reader: TCustomReader;
  ParamsReader: IParamsReader;
  CustomStringParser: ICustomStringParser;
begin

  Reader := ReaderClass.Create;
  try

    if not Reader.GetInterface(IParamsReader, ParamsReader) then
      raise EComponentException.Create('Reader does not support IParamsReader interface.');
    try

      ParamsReader.RetrieveParams(Params);

      Parser := ParserClass.Create;
      try

        if Parser.GetInterface(ICustomStringParser, CustomStringParser) then

          try

            CustomStringParser.Located         := ErrorsLocating;
            CustomStringParser.NativeException := NativeException;
            CustomStringParser.SetSource(GetSourceString);

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

procedure TLSIni.Loaded;
begin

  inherited Loaded;

  if not (csDesigning in ComponentState) then begin

    FParams := ParamsClass.Create;
    if AutoLoad then
      Load;

  end;

end;

end.
