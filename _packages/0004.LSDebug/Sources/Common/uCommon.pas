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
  SysUtils, AppEvnts, Classes,
  { LiberSynth }
  {$IFDEF DEBUG}
  uLog,
  {$ENDIF}
  uFileUtils, uParams, uLSIni, uLSNIStringParamsCompiler,
  { LSDebug }
  uProjectConsts;

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
function CheckCustomExpressionKey(const Expression: String): Boolean;
{ Удаляет ключ из выражения }
function ClearExpressionKey(const Expression: String): String;

implementation

type

  TAppEventsHolder = class(TComponent)

  strict private

    FAppEvents: TApplicationEvents;

    procedure AppException(_Sender: TObject; _E: Exception);

  public

    constructor Create; reintroduce;

  end;

var
  AppEventsHolder: TAppEventsHolder = nil;
  LSIni: TLSIni = nil;
  DefaultParams: TParams = nil;

procedure _InitDefaultParams(Params: TParams);
begin

  Params.AsString['Common.DateTimeFormat'] := 'yyyy-mm-dd hh:nn:ss.zzz';

  Params.AsString ['StringValueReplacer.Method'             ] := 'DirectMemoryValue';
  Params.AsInteger['StringValueReplacer.ResultLengthLimit'  ] := 102400;
  Params.AsInteger['StringValueReplacer.MaxEvaluatingLength'] :=   4096;

  Params.AsString['VariantValueReplacer.SingleVariantFormat'] := '%0:s: %1:s';
  Params.AsString['VariantValueReplacer.ArrayVariantFormat' ] := 'varArray [%0:d..%1:d] of %3:s = (%4:s)';

end;

procedure _InitAppEvents;
begin
  AppEventsHolder := TAppEventsHolder.Create;
end;

procedure _FinAppEvents;
begin
  FreeAndNil(AppEventsHolder);
end;

procedure _InitParams;
begin

  try

    LSIni := TLSIni.Create(nil);
    with LSIni do begin

      SourcePath := PackageParamsFile;
      LSNISaveOptions := LSNISaveOptions + [soTypesFree, soForceQuoteStrings];
      _InitDefaultParams(Params);
      Load;

    end;

  except

    on E: Exception do begin

      DefaultParams := TParams.Create;
      _InitDefaultParams(DefaultParams);

    end;

  end;

end;

procedure _FinParams;
begin
  LSIni.Save;
  FreeAndNil(LSIni);
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

function CheckCustomExpressionKey(const Expression: String): Boolean;
begin
  Result := CheckExpressionKey(Expression, SC_CustomDebuggingExpressionKey);
end;

function ClearExpressionKey(const Expression: String): String;
var
  i: Integer;
begin

  for i := Length(Expression) downto 1 do
    if Expression[i] = ',' then Exit(Trim(Copy(Expression, 1, i - 1)));

  Result := Expression;

end;

{ TAppEventsHolder }

constructor TAppEventsHolder.Create;
begin

  inherited Create(nil);

  FAppEvents := TApplicationEvents.Create(Self);
  FAppEvents.OnException := AppException;

end;

procedure TAppEventsHolder.AppException(_Sender: TObject; _E: Exception);
begin
  {$IFDEF DEBUG}
  WriteException(_E);
  {$ENDIF}
end;

initialization

  _InitAppEvents;
  _InitParams;
  {$IFDEF DEBUG}
  ForceLogInit(HInstance);
  {$ENDIF}

finalization

  _FinAppEvents;
  _FinParams;
  FreeAndNil(DefaultParams);

end.
