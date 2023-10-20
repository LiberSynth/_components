unit uStringValueReplacer;

interface

uses
  { VDebugPackage }
  uCustomVizualizers;

type

  TStringValueReplacer = class(TCustomValueReplacer)

  protected

    { IOTADebuggerVisualizer }
    procedure GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean); override;
    function GetVisualizerName: String; override;
    function GetVisualizerDescription: String; override;

    function GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String; override;

  end;

implementation

uses
  { VDebugPackage }
  uConsts, uCommon;

{ TStringValueReplacer }

function TStringValueReplacer.GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String;
begin
  Result := PureValueText(_EvalResult);
end;

procedure TStringValueReplacer.GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean);
begin
  _TypeName := 'string';
  _AllDescendants := False;
end;

function TStringValueReplacer.GetVisualizerDescription: String;
begin
  Result := SC_StringValueReplacer_Description;
end;

function TStringValueReplacer.GetVisualizerName: String;
begin
  Result := SC_StringValueReplacer_Name;
end;

end.
