unit vLog;

interface

{TODO -oVasilyev -cComponents : -> ProjUtils }

uses
  { VCL }
  SysUtils;

procedure WriteLog(const Value: String);
procedure WriteLogFmt(const Value: String; const Args: array of const);
procedure WriteError(E: Exception);

implementation

uses
  { VCL }
  SyncObjs,
  { Utils }
  vFileUtils;

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

    constructor Create;
    destructor Destroy; override;

    procedure WriteLog(const Value: String);
    procedure WriteLogFmt(const Value: String; const Args: array of const);
    procedure WriteError(E: Exception);

  end;

{ TLog }

constructor TLog.Create;
begin

  inherited Create;

  FLogFileName :=Format('%s\%s.log', [PackageDir, PackageName]);
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

    WriteLogFmt('%s: ', [E.ClassName, E.Message]);

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

initialization

finalization

  FreeAndNil(Log);

end.
