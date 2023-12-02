unit uCustomViewerFrame;

(**********************************************************)
(*                                                        *)
(*                     Liber Synth Co                     *)
(*                                                        *)
(**********************************************************)

interface

uses
  { VCL }
  Forms, ToolsAPI, Controls,
  { VDebugPackage }
  uClasses;

type

  TAvailableState = (asAvailable, asProcRunning, asOutOfScope);

  TCustomViewerFrame = class(TFrame, IOTADebuggerVisualizerExternalViewerUpdater)

  private

    FEvaluator: TEvaluator;
    FOwningForm: TCustomForm;
    FAvailableState: TAvailableState;
    FClosedProc: TOTAVisualizerClosedProcedure;

    { IOTADebuggerVisualizerExternalViewerUpdater }
    procedure CloseVisualizer;
    procedure MarkUnavailable(Reason: TOTAVisualizerUnavailableReason);
    procedure RefreshVisualizer(const Expression, TypeName, EvalResult: String);
    procedure SetClosedCallBack(ClosedProc: TOTAVisualizerClosedProcedure);

    function GetEvaluator: TEvaluator;

  protected

    procedure SetParent(_Parent: TWinControl); override;
    procedure ShowData(const _Expression, _TypeName, _EvalResult: String); virtual; abstract;

    property Evaluator: TEvaluator read GetEvaluator;
    property OwningForm: TCustomForm read FOwningForm;

  public

    procedure SetForm(_Form: TCustomForm);
    procedure SetProperties(_Evaluator: TEvaluator; const _ParamsSectionName: String); virtual;
    procedure RefreshFrame(const _Expression, _TypeName, _EvalResult: String);
    procedure SaveParams(const _ParamsSectionName: String); virtual;

  end;

implementation

uses
  { VCL }
  SysUtils,
  { VDebugPackage }
  uProjectConsts;

{$R *.dfm}

{ TCustomViewerFrame }

procedure TCustomViewerFrame.CloseVisualizer;
begin
  if Assigned(FOwningForm) then FOwningForm.Close;
end;

function TCustomViewerFrame.GetEvaluator: TEvaluator;
begin
  if not Assigned(FEvaluator) then raise Exception.Create(SC_EvaluatorNotAssigned);
  Result := FEvaluator;
end;

procedure TCustomViewerFrame.SaveParams(const _ParamsSectionName: String);
begin
end;

procedure TCustomViewerFrame.MarkUnavailable(Reason: TOTAVisualizerUnavailableReason);
begin

  case Reason of

    ovurProcessRunning: FAvailableState := asProcRunning;
    ovurOutOfScope: FAvailableState := asOutOfScope;

  end;

end;

procedure TCustomViewerFrame.RefreshFrame(const _Expression, _TypeName, _EvalResult: String);
begin
  FAvailableState := asAvailable;
  ShowData(_Expression, _TypeName, _EvalResult);
end;

procedure TCustomViewerFrame.RefreshVisualizer(const Expression, TypeName, EvalResult: String);
begin
  RefreshFrame(Expression, TypeName, EvalResult);
end;

procedure TCustomViewerFrame.SetClosedCallBack(ClosedProc: TOTAVisualizerClosedProcedure);
begin
  FClosedProc := ClosedProc;
end;

procedure TCustomViewerFrame.SetProperties(_Evaluator: TEvaluator; const _ParamsSectionName: String);
begin
  FEvaluator := _Evaluator;
end;

procedure TCustomViewerFrame.SetForm(_Form: TCustomForm);
begin
  FOwningForm := _Form;
end;

procedure TCustomViewerFrame.SetParent(_Parent: TWinControl);
begin
  if not Assigned(_Parent) and Assigned(FClosedProc) then FClosedProc;
  inherited SetParent(_Parent);
end;

end.
