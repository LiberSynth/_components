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

{ TODO 4 -oVasilyevSM -cuLSIni: Иконка }

interface

uses
  { VCL }
  SysUtils, Classes,
  { LiberSynth }
  uCore, uParams, uFileUtils, uUserParams, uCustomParser, uCustomStringParser, uComponentTypes;

type

  TIniStoreMethod = (smLSNIString, smClassicIni, smBLOB);
  TIniSourceType  = (stFile, stRegistryStructured, stRegistrySingleParam, stCustom);

  TLSIni = class(TComponent)

  strict private

    FStoreMethod: TIniStoreMethod;
    FSourceType: TIniSourceType;
    FAutoSave: Boolean;
    FAutoLoad: Boolean;
    FSourcePath: String;
    FErrorsLocating: Boolean;
    FCommentSupport: Boolean;

    FParams: TParams;

    procedure InitProperties;
    function ParamsClass: TParamsClass;
    function ReaderClass: TCustomParserClass;
    function SourceFile: String;
    procedure SetReaderLocated(_Reader: TCustomParser);
    procedure SetReaderSource(_Reader: TCustomParser);
    procedure RetrieveReaderSource(_Reader: TCustomParser; const _Source: String);
    procedure SetReaderParams(_Reader: TCustomParser);

    procedure SetCommentSupport(const _Value: Boolean);
    procedure SetSourceType(const _Value: TIniSourceType);
    procedure SetStoreMethod(const _Value: TIniStoreMethod);
    procedure SetErrorsLocating(const _Value: Boolean);

  protected

    procedure Loaded; override;
  published

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
    property CommentSupport: Boolean read FCommentSupport write SetCommentSupport;
    property SourcePath: String read FSourcePath write FSourcePath;

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
  StrToFile(Params.SaveToString, SourceFile);
end;

procedure TLSIni.SetCommentSupport(const _Value: Boolean);
begin

  if _Value <> FCommentSupport then begin

    if _Value and (StoreMethod = smBLOB) then
      raise EComponentException.Create('Invalid combination of properties. Comments are only supported for the string sources.');
    if _Value and (SourceType in [stRegistryStructured, stRegistrySingleParam] ) then
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

procedure TLSIni.SetReaderLocated;
var
  CustomStringParser: ICustomStringParser;
begin

  if ErrorsLocating then

    if _Reader.GetInterface(ICustomStringParser, CustomStringParser) then

      CustomStringParser.SetLocated

    else raise EParamsException.CreateFmt('Reader class %s does not support string reading.', [_Reader.ClassName]);

end;

procedure TLSIni.SetReaderParams(_Reader: TCustomParser);
var
  ParamsReader: IParamsReader;
begin

  if _Reader.GetInterface(IParamsReader, ParamsReader) then

    ParamsReader.SetParams(Params)

  else raise EParamsException.CreateFmt('Reader class %s does not support params reading.', [_Reader.ClassName]);

end;

procedure TLSIni.SetReaderSource(_Reader: TCustomParser);
var
  StringSource: String;
begin

  StringSource := '';

  case SourceType of

    { TODO 2 -oVasilyevSM -cuLSIni: Если путь не указан - это ини рядом с экзешником. Или раздел реестра приложения из
      неких общих параметров проекта (где-то вычислялось). }
    stFile: StringSource := FileToStr(SourceFile);
//    stRegistryStructured: ;
//    stRegistrySingleParam: ;
//    stCustom: DoGetCustomSource(что именно?);

  else
    raise EUncompletedMethod.Create;
  end;

  case StoreMethod of

    smLSNIString: RetrieveReaderSource(_Reader, StringSource);
//    smClassicIni: RetrieveReaderSource(_Reader, StringSource);
//    smBLOB: RetrieveReaderSource(_Reader, BLOBSource);

  else
    raise EUncompletedMethod.Create;
  end;

end;

procedure TLSIni.SetSourceType(const _Value: TIniSourceType);
begin

  if _Value <> FSourceType then begin

    if (_Value in [stRegistryStructured, stRegistrySingleParam]) and CommentSupport then
      raise EComponentException.Create('Invalid combination of properties. Comments are not supported when saving to the registry.');

    FSourceType := _Value;

  end;

end;

procedure TLSIni.SetStoreMethod(const _Value: TIniStoreMethod);
begin

  if _Value <> FStoreMethod then begin

    if (_Value = smBLOB) and CommentSupport then
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

function TLSIni.ParamsClass: TParamsClass;
begin
  if CommentSupport then Result := TUserParams
  else Result := TParams;
end;

function TLSIni.ReaderClass: TCustomParserClass;
const

  MapA: array [TIniStoreMethod] of TCustomParserClass = (

      { smLSNIString } TParamsReader,
      { smClassicIni } nil,
      { smBLOB       } nil

  );

  MapB: array [TIniStoreMethod] of TCustomParserClass = (

      { smLSNIString } TUserParamsReader,
      { smClassicIni } nil,
      { smBLOB       } nil

  );

begin

  { TODO 2 -oVasilyevSM -cuLSIni: Поддержка комментариев должна включать формат их сохранения - канонический / исходный.
    2 потому что лучше сразу задать свойство с тройным типом. И тогда здесь будет матрица. }
  if CommentSupport then Result := MapB[StoreMethod]
  else Result := MapA[StoreMethod];

  if not Assigned(Result) then
    raise EUncompletedMethod.Create;

end;

procedure TLSIni.RetrieveReaderSource(_Reader: TCustomParser; const _Source: String);
var
  CustomStringParser: ICustomStringParser;
begin

  if _Reader.GetInterface(ICustomStringParser, CustomStringParser) then

    CustomStringParser.SetSource(_Source)

  else raise EParamsException.CreateFmt('Reader class %s does not support string reading.', [_Reader.ClassName]);

end;

procedure TLSIni.InitProperties;
begin

  FStoreMethod    := smLSNIString;
  FSourceType     := stFile;
  FAutoLoad       := True;
  FCommentSupport := True;
  FErrorsLocating := True;

end;

procedure TLSIni.Load;
var
  Reader: TCustomParser;
begin

  Reader := ReaderClass.Create;
  try

    SetReaderLocated(Reader);
    SetReaderSource (Reader);
    SetReaderParams (Reader);
    Reader.Read;

  finally
    Reader.Free;
  end;

end;

procedure TLSIni.Loaded;
begin

  inherited Loaded;

  if not (csDesigning in ComponentState) then begin

    FParams := ParamsClass.Create;
    if AutoLoad then Load;

  end;

end;

end.
