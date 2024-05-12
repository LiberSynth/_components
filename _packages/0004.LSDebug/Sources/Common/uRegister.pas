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
  { LSDebug }
  uClasses, uCustomVizualizers,
  { Visualizer units }
  uStringValueReplacer, uVariantValueReplacer, uGUIDValueReplacer, uDateTimeValueReplacer;

var

  StringValueReplacer:  TStringValueReplacer;
  GUIDValueReplacer:    TGUIDValueReplacer;
  VariantValueReplacer: TVariantValueReplacer;
  DateTimeValueReplacer: TDateTimeValueReplacer;

procedure Register;

  procedure _RegisterVizualizer(var _Value: TCustomDebuggerVisualizer; _Class: TCustomDebuggerVisualizerClass);
  begin
    _Value := _Class.Create;
    DebuggerServices.RegisterDebugVisualizer(_Value as IOTADebuggerVisualizer);
  end;

begin

  GetDebuggerServices;

  _RegisterVizualizer(TCustomDebuggerVisualizer(StringValueReplacer  ), TStringValueReplacer  );
  _RegisterVizualizer(TCustomDebuggerVisualizer(GUIDValueReplacer    ), TGUIDValueReplacer    );
  _RegisterVizualizer(TCustomDebuggerVisualizer(VariantValueReplacer ), TVariantValueReplacer );
  _RegisterVizualizer(TCustomDebuggerVisualizer(DateTimeValueReplacer), TDateTimeValueReplacer);

end;

procedure Unregister;

  procedure _UnregisterVizualizer(var _Value: TCustomDebuggerVisualizer);
  begin
    DebuggerServices.UnregisterDebugVisualizer(_Value as IOTADebuggerVisualizer);
  end;

begin

  _UnregisterVizualizer(TCustomDebuggerVisualizer(StringValueReplacer  ));
  _UnregisterVizualizer(TCustomDebuggerVisualizer(GUIDValueReplacer    ));
  _UnregisterVizualizer(TCustomDebuggerVisualizer(VariantValueReplacer ));
  _UnregisterVizualizer(TCustomDebuggerVisualizer(DateTimeValueReplacer));

end;

initialization

finalization

  Unregister;

end.
