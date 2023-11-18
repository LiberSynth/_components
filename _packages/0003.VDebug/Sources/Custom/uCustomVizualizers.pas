unit uCustomVizualizers;

interface

uses
  { VCL }
  ToolsAPI,
  { VDebugPackage }
  uClasses, uViewerFormHelper;

type

  TCustomDebuggerVisualizer = class(TInterfacedObject, IOTADebuggerVisualizer)

  private

    FEvaluator: TEvaluator;

    function GetEvaluator: TEvaluator;

  protected

    { IOTADebuggerVisualizer }
    function GetSupportedTypeCount: Integer; virtual;
    procedure GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean); virtual; abstract;
    function GetVisualizerIdentifier: String; virtual;
    function GetVisualizerName: String; virtual;
    function GetVisualizerDescription: String; virtual;

    function EvaluatorClass: TEvaluatorClass; virtual;
    property Evaluator: TEvaluator read GetEvaluator;

  public

    constructor Create;
    destructor Destroy; override;

  end;

  TCustomDebuggerVisualizerClass = class of TCustomDebuggerVisualizer;

  TCustomValueReplacer = class(TCustomDebuggerVisualizer, IOTADebuggerVisualizerValueReplacer)

  protected

    { IOTADebuggerVisualizerValueReplacer }
    function GetReplacementValue(const _Expression, _TypeName, _EvalResult: String): String;

    function GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String; virtual;

  end;

  TCustomExternalViewer = class(TCustomDebuggerVisualizer, IOTADebuggerVisualizerExternalViewer)

  private

    function GetFormCaption: String;

  protected

    { IOTADebuggerVisualizerExternalViewer }
    function GetMenuText: String; virtual;
    function Show(const _Expression, _TypeName, _EvalResult: String; _SuggestedLeft, _SuggestedTop: Integer): IOTADebuggerVisualizerExternalViewerUpdater;

    function ViewerFormHelperClass: TViewerFormHelperClass; virtual; abstract;

  end;

implementation

uses
  { VCL }
  SysUtils, Forms,
  { VDebugPackage }
  uVDebugConsts, uCommon, uCustom, uCustomViewerFrame;

{ TCustomDebuggerVisualizer }

constructor TCustomDebuggerVisualizer.Create;
var
  EC: TEvaluatorClass;
begin

  inherited Create;

  EC := EvaluatorClass;
  if Assigned(EC) then FEvaluator := EC.Create;

end;

destructor TCustomDebuggerVisualizer.Destroy;
begin
  FEvaluator.Free;
  inherited Destroy;
end;

function TCustomDebuggerVisualizer.GetEvaluator: TEvaluator;
begin
  if not Assigned(FEvaluator) then raise Exception.Create(SC_EvaluatorNotAssigned);
  Result := FEvaluator;
end;

function TCustomDebuggerVisualizer.EvaluatorClass: TEvaluatorClass;
begin
  Result := TEvaluator;
end;

function TCustomDebuggerVisualizer.GetSupportedTypeCount: Integer;
begin
  Result := 1;
end;

function TCustomDebuggerVisualizer.GetVisualizerDescription: String;
const
  SC_Description = 'Vizualizer for Delphi %s';
begin
  Result := Format(SC_Description, [ClassName]);
end;

function TCustomDebuggerVisualizer.GetVisualizerIdentifier: String;
begin
  Result := ClassName;
end;

function TCustomDebuggerVisualizer.GetVisualizerName: String;
begin
  Result := ClassName;
  if (Length(Result) > 0) and SameText(Result[1], 'T') then Result := Copy(Result, 2, Length(Result));
end;

{ TCustomValueReplacer }

function TCustomValueReplacer.GetReplacementValue(const _Expression, _TypeName, _EvalResult: String): String;
begin

  if CheckVDPExpressionKey(_Expression) then

    try

      Result := GetCustomReplacementValue(ClearExpressionKey(_Expression), _TypeName, _EvalResult)

    except
      on E: Exception do
        Result := FormatException(E);
    end

  else Result := _EvalResult;

end;

function TCustomValueReplacer.GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String;
begin
  Result := _EvalResult;
end;

{ TCustomExternalViewer }

function TCustomExternalViewer.GetFormCaption: String;
begin
  Result := Copy(ClassName, 2, Length(ClassName));
end;

function TCustomExternalViewer.GetMenuText: String;
begin
  Result := ClassName;
end;

function TCustomExternalViewer.Show(const _Expression, _TypeName, _EvalResult: String; _SuggestedLeft, _SuggestedTop: Integer): IOTADebuggerVisualizerExternalViewerUpdater;
var
  Form: TCustomForm;
  Frame: TCustomViewerFrame;
  ViewerFormHelper: TViewerFormHelper;
  VisDockForm: INTACustomDockableForm;
begin

  ViewerFormHelper := ViewerFormHelperClass.Create(_Expression, GetFormCaption, _SuggestedLeft, _SuggestedTop, ClassName);
  VisDockForm := ViewerFormHelper as INTACustomDockableForm;
  Form := (BorlandIDEServices as INTAServices).CreateDockableForm(VisDockForm);
  Form.Visible := False;
  (VisDockForm as IFrameFormHelper).SetForm(Form);

  Frame := (VisDockForm as IFrameFormHelper).GetFrame as TCustomViewerFrame;
  Result := Frame as IOTADebuggerVisualizerExternalViewerUpdater;
  Frame.SetProperties(Evaluator, ClassName);
  Frame.RefreshFrame(_Expression, _TypeName, _EvalResult);

  { Затычка для предотвращения AV в coreide140.@Debuggermgr@TDebuggerMgr@OnShowVisualizer после вызова этого метода для
    объекта, полученного из функции другого объекта. Похоже, отладчик как-то его запоминает, и потом пытается к нему
    обратиться скорее всего для сравнения. Можно вообще ничего здесь не делать, все равно будет AV. Поэтому ничего
    лучше пока не придумалось. Из-за этой затычки не вызывается метод
    IOTADebuggerVisualizerExternalViewerUpdater.RefreshVisualizer и viewer не обновляется. }

  Abort; // it's bad so bad(((((

end;

end.
