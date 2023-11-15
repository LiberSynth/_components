unit vRegistry;

interface

uses
  Registry,
  vParams;

const
  SC_RootPath = 'Software\vSoft\%s\Version %d';

type

  { Straight store type is reading in regedit. Binary can store any data type. }
  { Data type is writing in the first byte of binary data in the registry      }
  TRegistryStoreType = (stStraight, stBinary);

  TRegistryParams = class(TParams)
  private
    FRegistry: TRegistry;
    FAllUsers: Boolean;
    FRootPath: String;
    FStoreType: TRegistryStoreType;
    procedure CheckPath(const _Path: String);
    procedure ReadParam(const _Path, _Name: String; Registry: TRegistry);
    procedure ReadParamStraight(_Param: TParam);
    procedure ReadParamBinary(_Param: TParam);
    procedure WriteParam(const _Path, _Name: String; _Param: TParam);
    procedure WriteParamStraight(_Param: TParam);
    procedure WriteParamBinary(_Param: TParam);
    procedure Install;
  protected
    procedure InitRegistry;
    procedure SetDefaultParams; virtual;
  public
    constructor Create(_AllUsers: Boolean; const _RootPath: String; _StoreType: TRegistryStoreType = stStraight);
    destructor Destroy; override;
    procedure Read;
    procedure Write;
    procedure SetToDefault;
    procedure Uninstall;
  end;

function DefaultProjectRegistryPath: String;

implementation

uses
  Classes, Windows, SysUtils,
  vFileUtils, vDataUtils;

function DefaultProjectRegistryPath: String;
begin
  Result := Format(SC_RootPath, [ExeName, MajorVersion]);
end;

{ TRegistryParams }

constructor TRegistryParams.Create(_AllUsers: Boolean; const _RootPath: String; _StoreType: TRegistryStoreType);
begin
  inherited Create;
  FRegistry := TRegistry.Create;
  FAllUsers := _AllUsers;
  FRootPath := _RootPath;
  FStoreType := _StoreType;
  InitRegistry;
end;

destructor TRegistryParams.Destroy;
begin
  FRegistry.Free;
  inherited;
end;

procedure TRegistryParams.CheckPath(const _Path: String);
begin
  if not FRegistry.KeyExists(_Path) then begin
    FRegistry.OpenKey(_Path, True);
    FRegistry.CloseKey;
  end;
end;

procedure TRegistryParams.ReadParam(const _Path, _Name: String; Registry: TRegistry);
var
  PN: String;
begin
  PN := StringReplace(Copy(_Path, Length(FRootPath) + 2, Length(_Path)), '\', '.', [rfReplaceAll]);
  if PN = '' then PN := _Name else PN := PN + '.' + _Name;
  case FStoreType of
    stStraight: ReadParamStraight(GetParam(PN));
    stBinary:   ReadParamBinary(GetParam(PN));
  end;
end;

procedure TRegistryParams.ReadParamStraight(_Param: TParam);
begin

end;

procedure TRegistryParams.ReadParamBinary(_Param: TParam);
begin

end;

procedure TRegistryParams.WriteParam(const _Path, _Name: String; _Param: TParam);
begin
  if FRegistry.OpenKey(_Path, False) then
    try
      case FStoreType of
        stStraight: WriteParamStraight(_Param);
        stBinary:   WriteParamBinary(_Param);
      end;
    finally
      FRegistry.CloseKey;
    end;
end;

procedure TRegistryParams.WriteParamStraight(_Param: TParam);
begin

end;

procedure TRegistryParams.WriteParamBinary(_Param: TParam);
begin

end;

procedure TRegistryParams.Install;
begin
  CheckPath(FRootPath);
  SetDefaultParams;
  Write;
end;

procedure TRegistryParams.InitRegistry;
begin
  if FAllUsers then FRegistry.RootKey := HKEY_LOCAL_MACHINE
  else FRegistry.RootKey := HKEY_CURRENT_USER;
  if not FRegistry.KeyExists(FRootPath) then Install
  else Read;
end;

procedure TRegistryParams.SetDefaultParams;
begin

end;

procedure TRegistryParams.Read;

  procedure _ReadLevel(const _Path: String);
  var
    R: TRegistry;
    SL: TStringList;
    i: Integer;
  begin
    R := TRegistry.Create;
    try
      R.RootKey := FRegistry.RootKey;
      with R do
        if OpenKey(_Path, False) then
          try
            SL := TStringList.Create;
            try
              GetValueNames(SL);
              for i := 0 to SL.Count - 1 do
                ReadParam(_Path, SL[i], R);
              GetKeyNames(SL);
              for i := 0 to SL.Count - 1 do
                _ReadLevel(_Path + '\' + SL[i]);
            finally
              SL.Free;
            end;
          finally
            CloseKey;
          end;
    finally
      R.Free;
    end;
  end;

begin
  Clear;
  _ReadLevel(FRootPath);
end;

procedure TRegistryParams.Write;
var
  SubPath: String;

  procedure _WriteLevel(_Params: TParams);
  var
    i: Integer;
    Path: String;
  begin
    Path := SubPath;
    for i := 0 to _Params.Count - 1 do
      with _Params[i] do
        if DataType = dtParams then begin
          CheckPath(Path + '\' + Name);
          SubPath := SubPath + '\' + Name;
          _WriteLevel(AsParams);
          SubPath := Path;
        end else WriteParam(Path, Name, _Params[i]);
  end;

begin
  SubPath := FRootPath;
  _WriteLevel(Self);
end;

procedure TRegistryParams.SetToDefault;
begin
  Clear;
  SetDefaultParams;
end;

procedure TRegistryParams.Uninstall;
var
  S: String;
  V: TRegKeyInfo;
begin
  S := LevelUp(FRootPath);
  with FRegistry do begin
    CloseKey;
    DeleteKey(S);
    S := LevelUp(S);
    OpenKey(S, False);
    if GetKeyInfo(V) and (V.NumSubKeys = 0) and (V.NumValues = 0) then begin
      CloseKey;
      DeleteKey(S);
    end;
  end;
end;

end.
