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

{

TLSIni.StoreFormat -> LSNI format ( reading location support yes/no )
                   -> Classic     ( reading location support yes/no )
                   -> BLOB

TLSIni.Destination -> File
                   -> Registry ( structured / single param <- StoreFormat )
                   -> Custom   ( saving and loading implement by event <- StoreFormat )

}

interface

uses
  { VCL }
  SysUtils, Classes,
  { LiberSynth }
  uParams, uUserParams, uComponentTypes;

type

  TIniStoreMethod = (smLSNIString, smClassicIni, smBLOB);
  TIniSourceType  = (stFile, stRegistryStructured, stRegistrySingleParam, stCustom);

  TLSIni = class(TComponent)

  strict private

    FStoreMethod: TIniStoreMethod;
    FSourceType: TIniSourceType;
    FAutoSave: Boolean;
    FAutoLoad: Boolean;
    FCommentSupport: Boolean;
    FErrorLocation: Boolean;

    FParams: TParams;

    procedure InitComponent;
    procedure InitProperties;
    function ParamsClass: TParamsClass;

    procedure SetCommentSupport(const _Value: Boolean);
    procedure SetSourceType(const _Value: TIniSourceType);
    procedure SetStoreMethod(const _Value: TIniStoreMethod);

  public

    constructor Create(_Owner: TComponent); override;

    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure Save;
    procedure Load;

  published

    property StoreMethod: TIniStoreMethod read FStoreMethod write SetStoreMethod;
    property SourceType: TIniSourceType read FSourceType write SetSourceType;
    property AutoSave: Boolean read FAutoSave write FAutoSave;
    property AutoLoad: Boolean read FAutoLoad write FAutoLoad;
    property CommentSupport: Boolean read FCommentSupport write SetCommentSupport;
    property ErrorLocation: Boolean read FErrorLocation write FErrorLocation;

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

end;

procedure TLSIni.SetCommentSupport(const _Value: Boolean);
begin

  if _Value <> FCommentSupport then begin

    if _Value and (StoreMethod = smBLOB) then
      raise EComponentException.Create('Invalid combination of properties. Comments are only supported when saving to a string.');
    if _Value and (SourceType in [stRegistryStructured, stRegistrySingleParam] ) then
      raise EComponentException.Create('Invalid combination of properties. Comments are not supported when saving to the registry.');

    FCommentSupport := _Value;

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

procedure TLSIni.AfterConstruction;
begin
  inherited AfterConstruction;
  InitComponent;
end;

procedure TLSIni.BeforeDestruction;
begin
  FreeAndNil(FParams);
  inherited BeforeDestruction;
end;

constructor TLSIni.Create(_Owner: TComponent);
begin
  inherited Create(_Owner);
  if csDesigning in ComponentState then
    InitProperties;
end;

function TLSIni.ParamsClass: TParamsClass;
begin
  if CommentSupport then Result := TUserParams
  else Result := TParams;
end;

procedure TLSIni.InitComponent;
begin

  if not (csDesigning in ComponentState) then begin

    FParams := ParamsClass.Create;
    if AutoLoad then Load;

  end;

end;

procedure TLSIni.InitProperties;
begin

  FStoreMethod    := smLSNIString;
  FSourceType     := stFile;
  FAutoLoad       := True;
  FCommentSupport := True;
  FErrorLocation  := True;

end;

procedure TLSIni.Load;
begin

end;

end.
