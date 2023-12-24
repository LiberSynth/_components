unit uPathRunner;

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

interface

uses
  { VCL }
  Classes, SysUtils,
  { LiberSynth }
  uStrUtils;

type

  TRunnerProcessFunction = procedure (const _FilePath: String; _MaskMatch: Boolean) of object;
  TRunnerProcessMethod = procedure (const _FilePath: String) of object;
  TRunnerProcessExMethod = procedure (const _FilePath: String; var _Terminate: Boolean) of object;
  TRunnerProgressEvent = procedure (_Max, _Position: Integer; const _FilePath: String) of object;

  TRunnerOptions = class(TPersistent)

  private

    FFileMasks: String;
    FIncludeSubdirertories: Boolean;
    FSubdirDepth: Integer;

  protected

    procedure AssignTo(Dest: TPersistent); override;

  public

    constructor Create;

    property FileMasks: String read FFileMasks write FFileMasks;
    property IncludeSubdirertories: Boolean read FIncludeSubdirertories write FIncludeSubdirertories;
    property SubdirDepth: Integer read FSubdirDepth write FSubdirDepth;

  end;

  TPathRunner = class

  private

    FProcedure: TRunnerProcessMethod;
    FProcedureEx: TRunnerProcessExMethod;
    FProgress: TRunnerProgressEvent;
    FMax: Integer;
    FPosition: Integer;
    FRunnerOptions: TRunnerOptions;
    FCurrentSubdirDepth: Integer;
    FTerminated: Boolean;
    FCurrent: TSearchRec;

    procedure DoProcess(const _Path: String; _Procedure: TRunnerProcessFunction);
    procedure CountFile(const _FilePath: String; _MaskMatch: Boolean);
    procedure Process(const _FilePath: String; _MaskMatch: Boolean);
    procedure Progress(_Max, _Position: Integer; const _FilePath: String);

    constructor CreateRunner(_Progress: TRunnerProgressEvent);

  protected

    property Current: TSearchRec read FCurrent;

  public

    constructor Create(_Procedure: TRunnerProcessMethod; _Progress: TRunnerProgressEvent = nil); overload;
    constructor Create(_Procedure: TRunnerProcessExMethod; _Progress: TRunnerProgressEvent = nil); overload;
    destructor Destroy; override;

    procedure Execute(const _RootPath: String);
    property RunnerOptions: TRunnerOptions read FRunnerOptions write FRunnerOptions;

    property Terminated: Boolean read FTerminated write FTerminated;

  end;

implementation

{ TPathRunner }

constructor TPathRunner.CreateRunner(_Progress: TRunnerProgressEvent);
begin

  inherited Create;

  FProgress := _Progress;
  FRunnerOptions := TRunnerOptions.Create;

end;

constructor TPathRunner.Create(_Procedure: TRunnerProcessMethod; _Progress: TRunnerProgressEvent);
begin
  CreateRunner(_Progress);
  FProcedure := _Procedure;
end;

constructor TPathRunner.Create(_Procedure: TRunnerProcessExMethod; _Progress: TRunnerProgressEvent);
begin
  CreateRunner(_Progress);
  FProcedureEx := _Procedure;
end;

destructor TPathRunner.Destroy;
begin
  FRunnerOptions.Free;
  inherited;
end;

procedure TPathRunner.CountFile(const _FilePath: String; _MaskMatch: Boolean);
begin
  Inc(FMax);
end;

procedure TPathRunner.Process(const _FilePath: String; _MaskMatch: Boolean);
begin

  if _MaskMatch then begin

    if Assigned(FProcedure) then FProcedure(_FilePath);
    if Assigned(FProcedureEx) then FProcedureEx(_FilePath, FTerminated);

  end;

  Inc(FPosition);
  Progress(FMax, FPosition, _FilePath);

end;

procedure TPathRunner.Progress(_Max, _Position: Integer; const _FilePath: String);
begin
  if Assigned(FProgress) then FProgress(_Max, _Position, _FilePath);
end;

procedure TPathRunner.Execute(const _RootPath: String);
begin

  FMax := 0;
  if Assigned(FProgress) then DoProcess(_RootPath, CountFile);
  Progress(FMax, 0, '');
  FPosition := 0;
  DoProcess(_RootPath, Process);
  Progress(0, 0, '');

end;

procedure TPathRunner.DoProcess(const _Path: String; _Procedure: TRunnerProcessFunction);
var
  SR: TSearchRec;
begin

  if FindFirst(_Path + '*.*', faAnyFile, SR) = 0 then

    try

      repeat

        if (SR.Name <> '..') and (SR.Name <> '.') then

          with FRunnerOptions do

            if SR.Attr and faDirectory <> 0 then

              if IncludeSubdirertories and ((SubdirDepth = -1) or (FCurrentSubdirDepth < SubdirDepth)) then begin

                Inc(FCurrentSubdirDepth);
                try

                  DoProcess(_Path + SR.Name + '\', _Procedure)

                finally
                  Dec(FCurrentSubdirDepth);
                end;

              end else

            else begin

              FCurrent := SR;
              _Procedure(_Path + SR.Name, FileMasksMatch(SR.Name, FileMasks));

            end;

          if FTerminated then Exit;

      until FindNext(SR) <> 0;

    finally
      FindClose(SR);
    end;

end;

{ TRunnerOptions }

procedure TRunnerOptions.AssignTo(Dest: TPersistent);
begin
  TRunnerOptions(Dest).FileMasks := FileMasks;
  TRunnerOptions(Dest).IncludeSubdirertories := IncludeSubdirertories;
end;

constructor TRunnerOptions.Create;
begin

  inherited Create;

  FFileMasks := '*.*';
  FIncludeSubdirertories := True;
  FSubdirDepth := -1;

end;

end.
