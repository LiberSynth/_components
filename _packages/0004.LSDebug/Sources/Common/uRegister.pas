unit uRegister;

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

procedure Register;

implementation

uses
  { VCL }
  ToolsAPI,
  { VDebugPackage }
  uClasses, uCustomVizualizers,
  { Visualizer units }
  uStringValueReplacer, uVariantValueReplacer, uGUIDValueReplacer;

var

  { TODO 1 -oVasilyevSM -cVDebug : Реплэйсер для типа Variant }
  { TODO 3 -oVasilyevSM -cVDebug : uses to trim }
  { TODO 2 -oVasilyevSM -cVDebug : Похоже, проблема была в том, что для TDateTime уже объявлен визуализатор }

  StringValueReplacer:  TStringValueReplacer;
  GUIDValueReplacer:    TGUIDValueReplacer;
  VariantValueReplacer: TVariantValueReplacer;

procedure Register;

  procedure _RegisterVizualizer(var _Value: TCustomDebuggerVisualizer; _Class: TCustomDebuggerVisualizerClass);
  begin
    _Value := _Class.Create;
    DebuggerServices.RegisterDebugVisualizer(_Value as IOTADebuggerVisualizer);
  end;

begin

  GetDebuggerServices;

  _RegisterVizualizer(TCustomDebuggerVisualizer(StringValueReplacer ), TStringValueReplacer );
  _RegisterVizualizer(TCustomDebuggerVisualizer(GUIDValueReplacer   ), TGUIDValueReplacer   );
  _RegisterVizualizer(TCustomDebuggerVisualizer(VariantValueReplacer), TVariantValueReplacer);

end;

procedure Unregister;

  procedure _UnregisterVizualizer(var _Value: TCustomDebuggerVisualizer);
  begin
    DebuggerServices.UnregisterDebugVisualizer(_Value as IOTADebuggerVisualizer);
  end;

begin

  _UnregisterVizualizer(TCustomDebuggerVisualizer(StringValueReplacer ));
  _UnregisterVizualizer(TCustomDebuggerVisualizer(GUIDValueReplacer   ));
  _UnregisterVizualizer(TCustomDebuggerVisualizer(VariantValueReplacer));

end;

initialization

finalization

  Unregister;

end.
