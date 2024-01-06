unit uCustomStringParamsCompiler;

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
  uCustomParamsCompiler, uParams, uCustomReadWrite, uStringWriter;

type

  TCustomStringParamsCompiler = class(TCustomParamsCompiler)

  strict private

    FStringWriter: IStringWriter;

    property StringWriter: IStringWriter read FStringWriter write FStringWriter;

  protected

    procedure CompileParam(_Param: TParam; _First, _Last: Boolean); override;
    function FormatParam(_Param: TParam; _First, _Last: Boolean): String; virtual; abstract;

  public

    destructor Destroy; override;

    procedure RetrieveWriter(_Writer: TCustomWriter); override;

  end;

implementation

{ TCustomParamsStringCompiler }

destructor TCustomStringParamsCompiler.Destroy;
begin
  FStringWriter := nil;
  inherited Destroy;
end;

procedure TCustomStringParamsCompiler.CompileParam(_Param: TParam; _First, _Last: Boolean);
begin
  inherited CompileParam(_Param, _First, _Last);
  StringWriter.Write(FormatParam(_Param, _First, _Last));
end;

procedure TCustomStringParamsCompiler.RetrieveWriter(_Writer: TCustomWriter);
begin
  if not _Writer.GetInterface(IStringWriter, FStringWriter) then
    raise EWriteException.Create('Writer does not support IStringWriter interface.');
end;

end.
