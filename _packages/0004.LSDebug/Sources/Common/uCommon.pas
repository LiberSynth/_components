unit uCommon;

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
  { VCL }
  SysUtils,
  { LiberSynth }
  {$IFDEF DEBUG}
  uLog,
  {$ENDIF}
  uParams, uLSIni, uClasses, uLSNIStringParamsCompiler;

{ Сохраняемые параметры пакета }
function PackageParams: TParams;
function PackageParamsFile: String;

function FormatException(E: Exception): String;
function WrapMessage(const Wrapper, ErrorMessage: String): String;

{ Возвращает ключ выражения ('Obj,r' -> 'r') }
function GetExpressionKey(const Expression: String): String;
{ Проверяет ключ выражения на заданное значение }
function CheckExpressionKey(const Expression, Key: String): Boolean;
{ Проверяет ключ выражения на значение SC_ExpressionKey_VDP }
function CheckVDPExpressionKey(const Expression: String): Boolean;
{ Удаляет ключ из выражения }
function ClearExpressionKey(const Expression: String): String;

implementation

uses
  { Utils }
  uFileUtils,
  { VDebugPackage }
  uProjectConsts;

{ Сохраняемые параметры пакета }

var
  LSIni: TLSIni = nil;
  DefaultParams: TParams = nil;

procedure _InitDefaultParams(Params: TParams);
begin

  Params.AsInteger['StringValueReplacer.ResultLengthLimit'  ] := 102400;
  Params.AsInteger['StringValueReplacer.MaxEvaluatingLength'] :=   4096;

end;

procedure _InitParams;
begin

  try

    LSIni := TLSIni.Create(nil);
    with LSIni do begin

      SourcePath := PackageParamsFile;
      LSNISaveOptions := LSNISaveOptions + [soTypesFree];
      _InitDefaultParams(Params);
      Load;

    end;

  except

    on E: Exception do begin

      DefaultParams := TParams.Create;
      _InitDefaultParams(DefaultParams);

      {$IFDEF DEBUG}
      WriteError(E);
      {$ENDIF}

    end;

  end;

end;

procedure _FinParams;
begin

  try

    LSIni.Save;
    FreeAndNil(LSIni);

  except
    {$IFDEF DEBUG}
    on E: Exception do
      WriteError(E);
    {$ENDIF}
  end;

end;

function PackageParams: TParams;
begin
  if Assigned(LSIni) then Result := LSIni.Params
  else Result := DefaultParams;
end;

function PackageParamsFile: String;
var
  Folder: String;
begin

  if GetSpecialFolder(Folder, sfAppData) then

    Result := Format('%0:s\%1:s\%2:s\%2:s.ini', [Folder, 'LiberSynth', PackageName(HInstance)])

  else Result := '';

end;

function FormatException(E: Exception): String;
begin
  Result := Format(SC_ExceptionFormat, [E.ClassName, E.Message]);
end;

function WrapMessage(const Wrapper, ErrorMessage: String): String;
begin
  Result := Format(SC_WrapperFormat, [Wrapper, ErrorMessage]);
end;

function GetExpressionKey(const Expression: String): String;
var
  i: Integer;
begin

  for i := Length(Expression) downto 1 do
    if Expression[i] = ',' then Exit(Trim(Copy(Expression, i + 1, Length(Expression))));

  Result := '';

end;

function CheckExpressionKey(const Expression, Key: String): Boolean;
begin
  Result := SameText(Key, GetExpressionKey(Expression));
end;

function CheckVDPExpressionKey(const Expression: String): Boolean;
begin
  Result := CheckExpressionKey(Expression, SC_ExpressionKey_VDP);
end;

function ClearExpressionKey(const Expression: String): String;
var
  i: Integer;
begin

  for i := Length(Expression) downto 1 do
    if Expression[i] = ',' then Exit(Trim(Copy(Expression, 1, i - 1)));

  Result := Expression;

end;

initialization

  _InitParams;
  {$IFDEF DEBUG}
  ForceLogInit(HInstance);
  {$ENDIF}

finalization

  _FinParams;
  FreeAndNil(DefaultParams);

end.
