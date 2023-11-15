unit uGUIDValueReplacer;

interface

uses
  { VDebugPackage }
  uClasses, uCustomVizualizers;

type

  TGUIDValueReplacer = class(TCustomValueReplacer)

  protected

    { IOTADebuggerVisualizer }
    procedure GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean); override;
    function GetVisualizerName: String; override;
    function GetVisualizerDescription: String; override;

    function GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String; override;
    function EvaluatorClass: TEvaluatorClass; override;

  end;

implementation

uses
  { Utils }
  vDataUtils,
  { VDebugPackage }
  uConsts, uCommon;

type

  TGUIDEvaluator = class(TEvaluator)

  private

    FGUIDPart: String;

  protected

    function ExpressionToRemoteModify(_Address: Cardinal; const _TypeName: String): String; override;
    function SuccessEmptyEvaluateResult: String; override;
    procedure ModifyRemoteMemory(_Address: Cardinal; const _ModifyExpression: String; const _TypeName: String); override;
    function MemoryEvaluateValue(_ValueAddress: Cardinal; const _EvalResult: String): String; override;

  end;

{ TGUIDEvaluator }

function TGUIDEvaluator.ExpressionToRemoteModify(_Address: Cardinal; const _TypeName: String): String;
begin
  Result := inherited ExpressionToRemoteModify(_Address, _TypeName) + FGUIDPart;
end;

function TGUIDEvaluator.SuccessEmptyEvaluateResult: String;
begin
  Result := '0';
end;

procedure TGUIDEvaluator.ModifyRemoteMemory(_Address: Cardinal; const _ModifyExpression, _TypeName: String);

  procedure _ModifyGUIDPart(const _PartName: String);
  begin

    FGUIDPart := '.' + _PartName;
    inherited ModifyRemoteMemory(_Address, _ModifyExpression + FGUIDPart, _TypeName);

  end;

begin

  _ModifyGUIDPart('D1'   );
  _ModifyGUIDPart('D2'   );
  _ModifyGUIDPart('D3'   );
  _ModifyGUIDPart('D4[0]');
  _ModifyGUIDPart('D4[1]');
  _ModifyGUIDPart('D4[2]');
  _ModifyGUIDPart('D4[3]');
  _ModifyGUIDPart('D4[4]');
  _ModifyGUIDPart('D4[5]');
  _ModifyGUIDPart('D4[6]');
  _ModifyGUIDPart('D4[7]');

end;

function TGUIDEvaluator.MemoryEvaluateValue(_ValueAddress: Cardinal; const _EvalResult: String): String;
var
  G: TGUID;
begin
  CurrentProcess.ReadProcessMemory(_ValueAddress, SizeOf(TGUID), G);
  Result := GUIDToStr(G);
end;

{ TGUIDValueReplacer }

function TGUIDValueReplacer.EvaluatorClass: TEvaluatorClass;
begin
  Result := TGUIDEvaluator;
end;

function TGUIDValueReplacer.GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String;
begin
  Result := Evaluator.MemoryEvaluate(_Expression, _TypeName, _EvalResult)
end;

procedure TGUIDValueReplacer.GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean);
begin
  _AllDescendants := False;
  _TypeName := 'TGUID';
end;

function TGUIDValueReplacer.GetVisualizerDescription: String;
begin
  Result := SC_GUIDValueReplacer_Description;
end;

function TGUIDValueReplacer.GetVisualizerName: String;
begin
  Result := SC_GUIDValueReplacer_Name;
end;

end.
