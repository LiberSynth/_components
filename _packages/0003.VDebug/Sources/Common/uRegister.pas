unit uRegister;

(**********************************************************)
(*                                                        *)
(*                     Liber Sunth Co                     *)
(*                                                        *)
(**********************************************************)

interface

procedure Register;

implementation

uses
  { VCL }
  ToolsAPI,
  { VDebugPackage }
  uClasses, uCustomVizualizers,
  { Visualizer units }
  uStringValueReplacer, uGUIDValueReplacer;

var

  { �� ����� �������� ���������� TDateTime. ����� �� �������� ������ ���������� ��� ����� ���� �� ����������� ��������. }
  { TODO -oVasilyevSM -cVDebug : ������, �������� ���� � ���, ��� ��� TDateTime ��� �������� ������������ }

  StringValueReplacer: TStringValueReplacer;
  GUIDValueReplacer:   TGUIDValueReplacer;

procedure Register;

  procedure _RegisterVizualizer(var _Value: TCustomDebuggerVisualizer; _Class: TCustomDebuggerVisualizerClass);
  begin
    _Value := _Class.Create;
    DebuggerServices.RegisterDebugVisualizer(_Value as IOTADebuggerVisualizer);
  end;

begin

  GetDebuggerServices;

  _RegisterVizualizer(TCustomDebuggerVisualizer(StringValueReplacer),       TStringValueReplacer       );
  _RegisterVizualizer(TCustomDebuggerVisualizer(GUIDValueReplacer),         TGUIDValueReplacer         );

end;

procedure Unregister;

  procedure _UnregisterVizualizer(var _Value: TCustomDebuggerVisualizer);
  begin
    DebuggerServices.UnregisterDebugVisualizer(_Value as IOTADebuggerVisualizer);
  end;

begin

  _UnregisterVizualizer(TCustomDebuggerVisualizer(StringValueReplacer       ));
  _UnregisterVizualizer(TCustomDebuggerVisualizer(GUIDValueReplacer         ));

end;

initialization

finalization

  Unregister;

end.
