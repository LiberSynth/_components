unit uVariantValueReplacer;

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
  SysUtils, Variants, Types,
  { VDebug }
  uClasses, uCommon, uCustomVizualizers, uFormatVariant, uStrUtils, uLog;

type

  TVariantValueReplacer = class(TCustomValueReplacer)

  strict private

    function FormatVariant(_VarType: TVarType; const _Expression, _Default: String): String;
    function FormatArray(_VarType, _ElementVarType: TVarType; const _Expression, _Default: String): String;

    function ReadDateTime: TDateTime;
    function FormatSimpleArray(_Address: NativeInt; _Count: Integer; const _PointerName: String; _TypeSize: Integer): String;
    function FormatDateTimeArray(_Address: NativeInt; _Count: Integer): String;

  protected

    { IOTADebuggerVisualizer }
    procedure GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean); override;
    function GetVisualizerName: String; override;
    function GetVisualizerDescription: String; override;

    function GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String; override;

  end;

implementation

{ TVariantValueReplacer }

function TVariantValueReplacer.FormatVariant(_VarType: TVarType; const _Expression, _Default: String): String;
begin

  case _VarType of

    varEmpty: Result := 'Unassigned';
    varNull:  Result := 'Null';
    varDate:  Result := FormatDateTimeEx(PackageParams.AsString['Common.DateTimeFormat'], ReadDateTime);

  else
    Result := _Default;
  end;

  Result := Format(PackageParams.AsString['VariantValueReplacer.SingleVariantFormat'], [VarTypeToStr(_VarType), Result]);

end;

function TVariantValueReplacer.FormatArray(_VarType, _ElementVarType: TVarType; const _Expression, _Default: String): String;
const

  SC_UNSUPPORTED_FORMAT = 'varArray [%0:d..%1:d] of %2:s with Dim = %3:d';

var
  VarArrayExpr: String;
  Dim: Word;
  Low, High, Count: Integer;
  StrType: String;
  Address: NativeInt;
  ArrayFormat: String;
begin

  ArrayFormat := PackageParams.AsString['VariantValueReplacer.ArrayVariantFormat'];

  { Считываем TVarData. }
  if (_VarType and varByRef) = 0 then VarArrayExpr := 'TVarData(<Context>).VArray^'
  else VarArrayExpr := 'PVarArray(TVarData(<Context>).VPointer)^';

  with Evaluator do begin

    { Считываем характеристики массива. }
    ReadFunction(Format('%s.DimCount',               [VarArrayExpr]), 'Word',    SizeOf(Word),    Dim);
    ReadFunction(Format('%s.Bounds[0].LowBound',     [VarArrayExpr]), 'Integer', SizeOf(Integer), Low);
    ReadFunction(Format('%s.Bounds[0].ElementCount', [VarArrayExpr]), 'Integer', SizeOf(Integer), Count);
    High := Low + Count - 1;
    StrType := VarTypeToStr(_ElementVarType);

    if Dim = 1 then begin

      { Считываем адрес массива. }
      ReadFunction(Format('NativeInt(%s.Data)', [VarArrayExpr]), 'NativeInt', SizeOf(NativeInt), Address);

      case _ElementVarType of

        varSmallint: Exit(Format(ArrayFormat, [Low, High, Dim, StrType, FormatSimpleArray(Address, Count, 'PSmallInt', SizeOf(SmallInt))]));
        varInteger:  Exit(Format(ArrayFormat, [Low, High, Dim, StrType, FormatSimpleArray(Address, Count, 'PInteger',  SizeOf(Integer ))]));
        varSingle:   Exit(Format(ArrayFormat, [Low, High, Dim, StrType, FormatSimpleArray(Address, Count, 'PSingle',   SizeOf(Single  ))]));
        varDouble:   Exit(Format(ArrayFormat, [Low, High, Dim, StrType, FormatSimpleArray(Address, Count, 'PDouble',   SizeOf(Double  ))]));
        varCurrency: Exit(Format(ArrayFormat, [Low, High, Dim, StrType, FormatSimpleArray(Address, Count, 'PCurrency', SizeOf(Currency))]));
        varDate:     Exit(Format(ArrayFormat, [Low, High, Dim, StrType, FormatDateTimeArray(Address, Count)]));
        varOleStr:   Exit('Complete this method.');
        varBoolean:  Exit('Complete this method.');
        varVariant:  Exit('Complete this method.');
        varShortInt: Exit(Format(ArrayFormat, [Low, High, Dim, StrType, FormatSimpleArray(Address, Count, 'PShortInt', SizeOf(ShortInt))]));
        varByte:     Exit(Format(ArrayFormat, [Low, High, Dim, StrType, FormatSimpleArray(Address, Count, 'PByte',     SizeOf(Byte    ))]));
        varWord:     Exit(Format(ArrayFormat, [Low, High, Dim, StrType, FormatSimpleArray(Address, Count, 'PWord',     SizeOf(Word    ))]));
        varLongWord: Exit(Format(ArrayFormat, [Low, High, Dim, StrType, FormatSimpleArray(Address, Count, 'PLongWord', SizeOf(LongWord))]));
        varInt64:    Exit(Format(ArrayFormat, [Low, High, Dim, StrType, FormatSimpleArray(Address, Count, 'PInt64',    SizeOf(Int64   ))]));
        varUInt64:   Exit(Format(ArrayFormat, [Low, High, Dim, StrType, FormatSimpleArray(Address, Count, 'PUInt64',   SizeOf(UInt64  ))]));
        varString:   Exit('Complete this method.');
        varUString:  Exit('Complete this method.');

      end;

    end;

  end;

  Result := Format(ArrayFormat, [Low, High, Dim, StrType, '']);

end;

function TVariantValueReplacer.ReadDateTime: TDateTime;
begin
  Evaluator.ReadFunction('TVarData(<Context>).VDate', 'TDateTime', SizeOf(TDateTime), Result);
end;

function TVariantValueReplacer.FormatSimpleArray(_Address: NativeInt; _Count: Integer; const _PointerName: String; _TypeSize: Integer): String;
var
  i: Integer;
begin

  Result := '';
  for i := 0 to _Count - 1 do

    Result := Format('%s%s, ', [

        Result,
        Evaluator.Evaluate(Format('%s(%d + %d)^', [_PointerName, _Address, i * _TypeSize]))

    ]);

  CutStr(Result, 2);

end;

function TVariantValueReplacer.FormatDateTimeArray(_Address: NativeInt; _Count: Integer): String;
var
  i: Integer;
  Item: Double;
begin

  Result := '';
  for i := 0 to _Count - 1 do begin

    Evaluator.ReadFunction(Format('TDoubleDynArray(%d)[%d]', [_Address, i]), 'Double', SizeOf(Double), Item);
    Result := Format('%s%s, ', [Result, FormatDateTime(TDateTime(Item), True)]);

  end;

  CutStr(Result, 2);

end;

procedure TVariantValueReplacer.GetSupportedType(_Index: Integer; var _TypeName: String; var _AllDescendants: Boolean);
begin
  _TypeName := 'Variant';
  _AllDescendants := True;
end;

function TVariantValueReplacer.GetVisualizerName: String;
begin
  Result := 'Variant value replacer for Delphi';
end;

function TVariantValueReplacer.GetVisualizerDescription: String;
begin

  Result :=

      'Variant value replacer for the Delphi debugger. For expression with key ''d'' replaces the default ' +
      'representation of the Variant with its expanded content.';

end;

function TVariantValueReplacer.GetCustomReplacementValue(const _Expression, _TypeName, _EvalResult: String): String;
var
  VarType, ElementVarType: TVarType;
  IsArray: Boolean;
begin

  try

    with Evaluator do begin

      InitVariable('Context', 'Variant', SizeOf(Variant), _Expression);
      try

        { Variants может быть не подключен в отлаживаемом проекте. А TVarData лежит в System. }
        ReadFunction('TVarData(<Context>).VType', 'TVarType', SizeOf(TVarType), VarType);

        IsArray := VarTypeIsArray(VarType);
        ElementVarType := VarType and varTypeMask;

        if IsArray then
          Result := FormatArray(VarType, ElementVarType, _Expression, _EvalResult)
        else
          Result := FormatVariant(VarType, _Expression, _EvalResult);

      finally
        FinVariable('Context');
      end;

    end;

  except

    on E: Exception do begin

      WriteException(E);
      Result := FormatException(E);

    end;

  end;

end;

end.
