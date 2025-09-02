unit Classes.uAnonymousThread;

interface

uses
  { VCL }
  System.SysUtils, System.Classes;

type

  TAnonymousThread = class(TThread)

  strict private

    FExecProc: TThreadProcedure;
    FCompleteProc: TThreadProcedure;

    property ExecProc: TThreadProcedure read FExecProc;
    property CompleteProc: TThreadProcedure read FCompleteProc;

  protected

    procedure Execute; override;

  public

    constructor Create(_ExecProc: TThreadProcedure; _CompleteProc: TThreadProcedure = nil); reintroduce;

  end;

procedure ThreadProcess(_ExecProc: TThreadProcedure; _CompleteProc: TThreadProcedure = nil);

implementation

procedure ThreadProcess(_ExecProc: TThreadProcedure; _CompleteProc: TThreadProcedure = nil);
begin
  TAnonymousThread.Create(_ExecProc, _CompleteProc);
end;

{ TAnonymousThread }

constructor TAnonymousThread.Create(_ExecProc, _CompleteProc: TThreadProcedure);
begin

  inherited Create(False);

  FExecProc     := _ExecProc;
  FCompleteProc := _CompleteProc;

  FreeOnTerminate := True;

end;

procedure TAnonymousThread.Execute;
begin

  ExecProc;

  if Assigned(CompleteProc) then
    Synchronize(CompleteProc);

end;

end.
