unit vProjUtils;

interface

uses
  Forms, Registry, Variants;

function IniFilePath: String;
function LogFilePath: String;

procedure RegisterApplication(Registry: TRegistry);

procedure SaveFormModel(Form: TForm);
procedure LoadFormModel(Form: TForm);
procedure SaveParamToIni(const Name: String; const Value: Variant);
function LoadParamFormIni(const Name: String): Variant;

implementation

uses
  SysUtils, Windows,
  vFileUtils, vParams;

function _ServiceFilePath(const Extention: String): String;
const
  SC_IniFormat = '%s\%s.%s';
begin
  Result := Format(SC_IniFormat, [ExeDir, ExeName, Extention]);
end;

function IniFilePath: String;
begin
  Result := _ServiceFilePath('ini');
end;

function LogFilePath: String;
begin
  Result := _ServiceFilePath('log');
end;

procedure RegisterApplication(Registry: TRegistry);

  function _Version: String;
  begin
    Result := Copy(FileInfo(ParamStr(0), fkFileVersion), 1, Pos('.', FileInfo(ParamStr(0), fkFileVersion)) - 1);
  end;

const
  SC_RegKeyFormat = 'Software\LiberSynth\%s\Version %s';
var
  FN: String;
begin
  Registry.RootKey := HKEY_CURRENT_USER;
  FN := PureFileName(ParamStr(0));
  Registry.OpenKey(Format(SC_RegKeyFormat, [FN, _Version]), True);
end;

procedure SaveFormModel(Form: TForm);
var
  Params: TParams;

  procedure _Save;
  var
    WP: TWindowPlacement;
  begin
    with Form do begin
      GetWindowPlacement(Handle, WP);
      with Params do begin
        GetParam('Common.MainMaximized').AsBoolean := WindowState = wsMaximized;
        with WP.rcNormalPosition do begin
          GetParam('Common.MainWidth').AsInteger := Right - Left;
          GetParam('Common.MainHeight').AsInteger := Bottom - Top;
        end;
      end;
    end;
  end;

begin
  Params := TParams.Create;
  try
    _Save;
    if FileExists(IniFilePath) then SysUtils.DeleteFile(IniFilePath);
    Params.SaveToFile(IniFilePath);
  finally
    Params.Free;
  end;
end;

procedure LoadFormModel(Form: TForm);
var
  Params: TParams;

  procedure _Load;
  begin
    with Form, Params do begin
      Width := CheckParam('Common.MainWidth', Width).AsInteger;
      Height := CheckParam('Common.MainHeight', Height).AsInteger;
      if CheckParam('Common.MainMaximized', False).AsBoolean then WindowState := wsMaximized;
    end;
  end;

begin
  Params := TParams.Create;
  try
    Params.LoadFromFile(IniFilePath);
    _Load;
  finally
    Params.Free;
  end;
end;

procedure SaveParamToIni(const Name: String; const Value: Variant);
begin
  with TParams.Create do
    try
      LoadFromFile(IniFilePath);
      GetParam(Name).AsVariant := Value;
      SaveToFile(IniFilePath);
    finally
      Free;
    end;
end;

function LoadParamFormIni(const Name: String): Variant;
begin
  with TParams.Create do
    try
      LoadFromFile(IniFilePath);
      Result := GetParam(Name).AsVariant;
    finally
      Free;
    end;
end;

end.
