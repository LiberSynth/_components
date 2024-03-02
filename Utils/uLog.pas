unit uLog;

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

{ TODO 5 -oVasilyevSM -cuPathRunner: Переехало в исходном виде пока. }
{ TODO 5 -oVasilyevSM -cuPathRunner: -> Отдельный пакет ProjUtils? }

interface

uses
  { VCL }
  SysUtils;

procedure WriteLog(const Value: String);
procedure WriteLogFmt(const Value: String; const Args: array of const);
procedure WriteError(E: Exception);
{

  Если лог вызывается из библиотеки, надо принудительно проинициализировать его в этой библиотеки со ссылкой на
  экземпляр этот пакета, чтобы файл лога создавался с именем библиотеки, которая вызывает лог, а не с именем библиотеки,
  возвращающей пути. Причем, для каждого модуля создается свой экземпляр лога, поэтому можно не беспокоиться, о том, что
  он будет какой-то один для всей связки. Каждый модуль сохраняет сообщения в свой файл <имя модуля>.log рядом с
  модулем. Просто вызывайте этот метод где-нибудь в инициализации каждого модуля кроме хоста и все.

}
procedure ForceLogInit(Instance: LongWord);
function LogFileName(Instance: LongWord): String;

implementation

uses
  { VCL }
  SyncObjs,
  { LiberSynth }
  uFileUtils;

type

  TLog = class

  strict private

    FLock: TCriticalSection;
    FLogFileName: String;

    procedure Lock;
    procedure Unlock;

    function FormatNow: String;
    procedure CreateLogFile;

    procedure WriteLogInternal(const _Value: String);

    property LogFileName: String read FLogFileName;

  private

    constructor Create(Instance: LongWord = 0);
    destructor Destroy; override;

    procedure WriteLog(const Value: String);
    procedure WriteLogFmt(const Value: String; const Args: array of const);
    procedure WriteError(E: Exception);

  end;

{ TLog }

constructor TLog.Create;
begin

  inherited Create;

  if Instance = 0 then
    Instance := HInstance;

  FLogFileName := uLog.LogFileName(Instance);
  FLock := TCriticalSection.Create;

end;

destructor TLog.Destroy;
begin
  FreeAndNil(FLock);
  inherited Destroy;
end;

procedure TLog.Lock;
begin
  FLock.Acquire;
end;

procedure TLog.Unlock;
begin
  FLock.Release;
end;

function TLog.FormatNow: String;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now);
end;

procedure TLog.CreateLogFile;
var
  TF: Text;
begin

  if not FileExists(LogFileName) then begin

    CheckDirExisting(ExtractFileDir(LogFileName));

    AssignFile(TF, LogFileName);
    try

      Rewrite(TF);

    finally
      CloseFile(TF);
    end;

  end;

end;

procedure TLog.WriteLogInternal(const _Value: String);
var
  TF: Text;
begin

  Lock;
  try

    CreateLogFile;

    AssignFile(TF, LogFileName);
    try

      Append(TF);
      Writeln(TF, Format('%s: %s', [FormatNow, _Value]));

    finally
      CloseFile(TF);
    end;

  finally
    Unlock;
  end;

end;

procedure TLog.WriteLog(const Value: String);
begin

  try

    WriteLogInternal(Value);

  except
  end;

end;

procedure TLog.WriteLogFmt(const Value: String; const Args: array of const);
begin

  try

    WriteLog(Format(Value, Args));

  except
  end;

end;

procedure TLog.WriteError(E: Exception);
begin

  try

    WriteLogFmt('%s: %s', [E.ClassName, E.Message]);

  except
  end;

end;

var
  Log: TLog;

procedure _CheckLogVar;
begin
  if not Assigned(Log) then
    Log := TLog.Create;
end;

procedure WriteLog(const Value: String);
begin
  _CheckLogVar;
  Log.WriteLog(Value);
end;

procedure WriteLogFmt(const Value: String; const Args: array of const);
begin
  _CheckLogVar;
  Log.WriteLogFmt(Value, Args);
end;

procedure WriteError(E: Exception);
begin
  _CheckLogVar;
  Log.WriteError(E);
end;

procedure ForceLogInit(Instance: LongWord);
begin
  Log := TLog.Create(Instance);
end;

function LogFileName(Instance: LongWord): String;
begin
  Result := Format('%s\%s.log', [PackageDir(Instance), PackageName(Instance)]);
end;

initialization

finalization

  FreeAndNil(Log);

end.
