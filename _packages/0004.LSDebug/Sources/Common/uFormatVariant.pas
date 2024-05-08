unit uFormatVariant;

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
  { VCL }
  SysUtils,
  { LiberSynth }
  uStrUtils;

function VarTypeIsArray(VarType: TVarType): Boolean;
function FormatVarData(const VarData: TVarData): String;
function VarTypeToStr(Value: TVarType): String;

implementation

function VarTypeIsArray(VarType: TVarType): Boolean;
begin
  Result := (VarType and varArray) = varArray
end;

function VarTypeToStr(Value: TVarType): String;
begin

  case Value of

    varEmpty:    Result := 'varEmpty';
    varNull:     Result := 'varNull';
    varSmallint: Result := 'varSmallint';
    varInteger:  Result := 'varInteger';
    varSingle:   Result := 'varSingle';
    varDouble:   Result := 'varDouble';
    varCurrency: Result := 'varCurrency';
    varDate:     Result := 'varDate';
    varOleStr:   Result := 'varOleStr';
    varDispatch: Result := 'varDispatch';
    varError:    Result := 'varError';
    varBoolean:  Result := 'varBoolean';
    varVariant:  Result := 'varVariant';
    varUnknown:  Result := 'varUnknown';
    varShortInt: Result := 'varShortInt';
    varByte:     Result := 'varByte';
    varWord:     Result := 'varWord';
    varLongWord: Result := 'varLongWord';
    varInt64:    Result := 'varInt64';
    varUInt64:   Result := 'varUInt64';
    varStrArg:   Result := 'varStrArg';
    varString:   Result := 'varString';
    varAny:      Result := 'varAny';
    varUString:  Result := 'varUString';
    varTypeMask: Result := 'varTypeMask';
    varArray:    Result := 'varArray';
    varByRef:    Result := 'varByRef';

  end;

end;

function FormatVarData(const VarData: TVarData): String;
begin

  with VarData do begin

    case VType of

      varSmallInt: Result := IntToStr(VSmallInt);
      varInteger:  Result := IntToStr(VInteger );
      varSingle:   Result := FloatToStr(VSingle);
      varDouble:   Result := FloatToStr(VDouble);
      varCurrency: Result := FloatToStr(VCurrency);
      varDate:     Result := DateTimeToStr(VDate);
      varOleStr:   Result := VOleStr^;
      varDispatch: Result := IntToStr(NativeInt(VDispatch));
      varError:    Result := IntToStr(VError);
      varBoolean:  Result := BooleanToStr(VBoolean);
//      varUnknown:  (VUnknown: Pointer);
      varShortInt: Result := IntToStr(VShortInt);
      varByte:     Result := IntToStr(VByte);
      varWord:     Result := IntToStr(VWord);
      varLongWord: Result := IntToStr(VLongWord);
      varInt64:    Result := IntToStr(VInt64);
      varUInt64:   Result := IntToStr(VUInt64);
//      varString:   (VString: Pointer);
//      varAny:      (VAny: Pointer);
//      varArray:    (VArray: PVarArray);
//      varByRef:    (VPointer: Pointer);
      varUString:  Result := String(VUString^);

    else
      Result := '';
    end;

    Result := Format('%s = %s', [VarTypeToStr(VType), Result]);

  end;

end;

end.
