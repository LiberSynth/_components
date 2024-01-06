unit uCustomParamsCompiler;

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
  { LiberSynth }
  uCustomReadWrite, uParams, uTypes;

type

  TDoProgressEvent = procedure (const _Text: String = '') of object;

  ICustomParamsCompiler = interface ['{59076600-E1FD-4DFA-A5AE-0318D4BEA634}']

    procedure RetrieveParams(_Value: TParams);
    procedure RetrieveProgressEvent(_ProgressEvent: TProgressEvent);
    procedure RetrieveProgressProcess(_DoProgressEvent: TDoProgressEvent; _TotalCount, _CurrentStep: Integer);

  end;

  TCustomParamsCompiler = class(TCustomCompiler, ICustomParamsCompiler)

  strict private

    FParams: TParams;
    FNested: Boolean;
    FProgressEvent: TProgressEvent;
    FDoProgressEvent: TDoProgressEvent;
    FTotalCount: Integer;
    FCurrentStep: Integer;

    procedure PrepareProgress;

    property Params: TParams read FParams;

  protected

    procedure CompileParam(_Param: TParam; _First, _Last: Boolean); virtual;
    procedure DoProgressEvent(const _Text: String = '');

    property Nested: Boolean read FNested write FNested;
    property TotalCount: Integer read FTotalCount write FTotalCount;
    property CurrentStep: Integer read FCurrentStep write FCurrentStep;

  public

    { ICustomParamsCompiler }
    procedure RetrieveParams(_Value: TParams);
    procedure RetrieveProgressEvent(_ProgressEvent: TProgressEvent);
    procedure RetrieveProgressProcess(_DoProgressEvent: TDoProgressEvent; _TotalCount, _CurrentStep: Integer);

    procedure Run; override;

    property ProgressEvent: TProgressEvent read FProgressEvent write FProgressEvent;

  end;

implementation

{ TCustomParamsCompiler }

procedure TCustomParamsCompiler.PrepareProgress;

  procedure _IncByParams(_Params: TParams);
  var
    Param: TParam;
  begin

    for Param in _Params.Items do begin

      Inc(FTotalCount);
      if Param.DataType = dtParams then
        _IncByParams(Param.AsParams);

    end;

  end;

begin
  FTotalCount := 0;
  _IncByParams(Params);
end;

procedure TCustomParamsCompiler.DoProgressEvent(const _Text: String);
begin

  if Assigned(FDoProgressEvent) then

    FDoProgressEvent(_Text)

  else if Assigned(FProgressEvent) then begin

    FProgressEvent(TotalCount, CurrentStep, _Text);
    Inc(FCurrentStep);

  end;

end;

procedure TCustomParamsCompiler.CompileParam(_Param: TParam; _First, _Last: Boolean);
begin
  DoProgressEvent(_Param.Name);
end;

procedure TCustomParamsCompiler.RetrieveParams(_Value: TParams);
begin
  FParams := _Value;
end;

procedure TCustomParamsCompiler.RetrieveProgressEvent(_ProgressEvent: TProgressEvent);
begin
  FProgressEvent := _ProgressEvent;
end;

procedure TCustomParamsCompiler.RetrieveProgressProcess(_DoProgressEvent: TDoProgressEvent; _TotalCount, _CurrentStep: Integer);
begin

  FDoProgressEvent := _DoProgressEvent;
  TotalCount       := _TotalCount;
  CurrentStep      := _CurrentStep;

end;

procedure TCustomParamsCompiler.Run;
var
  i, Count: Integer;
  First, Last: Boolean;
begin

  if Assigned(FProgressEvent) then
    PrepareProgress;

  Count := Params.Items.Count;
  for i := 0 to Count - 1 do begin

    First := i = 0;
    Last  := i = Count - 1;
    CompileParam(Params.Items[i], First, Last);

  end;

  if not Nested then
    DoProgressEvent;

end;

end.
