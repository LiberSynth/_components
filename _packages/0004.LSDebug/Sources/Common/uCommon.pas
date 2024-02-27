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
  { Liber Synth }
  uParams, uLSIni;

{ Сохраняемые параметры пакета }
function PackageParams: TParams;

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
  uFileUtils, uLog,
  { VDebugPackage }
  uProjectConsts;

{ Сохраняемые параметры пакета }

function ParamsFilePath: String;
var
  Folder: String;
begin

  if GetSpecialFolder(Folder, sfAppData) then

    Result := Format('%0:s\%1:s\%2:s\%2:s.ini', [Folder, 'LiberSynth', PackageName])

  else Result := '';

end;

//var
//  LSIni: TLSIni = nil;

procedure LoadParams;
begin

//  try
//
//    LSIni.SourcePath := FileToStr(ParamsFilePath);
//    LSIni.Load;
//
//  except
//    on E: Exception do
//      WriteError(E);
//  end;

end;

procedure SaveParams;
begin

  { TODO 5 -oVasilyevSM -cLSDebug: Поправить }

//  try
//
//    LSIni.Save;
//
//  except
//    on E: Exception do
//      WriteError(E);
//  end;

end;

function PackageParams: TParams;
begin
  Result := nil;
//  if not Assigned(LSIni) or not Assigned(LSIni.Params) then raise Exception.Create('Ini file is not loaded.');
//  Result := LSIni.Params;
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

//  try
//
//    LSIni := TLSIni.Create(nil);
//    LoadParams;
//
//  except
//  end;

finalization

//  try
//
//    if Assigned(LSIni) then begin
//
//      SaveParams;
//      FreeAndNil(LSIni);
//
//    end;
//
//  except
//  end;

end.
