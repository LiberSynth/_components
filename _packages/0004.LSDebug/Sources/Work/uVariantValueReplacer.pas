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
  { VDebugPackage }
  uClasses, uCustomVizualizers, uFormatVariant, uStrUtils, uLog;

type

  TVariantValueReplacer = class(TCustomValueReplacer)

  strict private

    function FormatVariant(_VarType: TVarType; const _Expression, _Default: String): String;
    function FormatArray(_VarType, _ElementVarType: TVarType; const _Expression, _Default: String): String;

    function ReadDateTime: TDateTime;
    function FormatSimpleArray(_Address: NativeInt; _Count: Integer; const _PointerName: String; _TypeSize: Integer): String;
    function FormatSmallIntArray(_Address: NativeInt; _Count: Integer): String;
    function FormatIntegerArray(_Address: NativeInt; _Count: Integer): String;
    function FormatSingleArray(_Address: NativeInt; _Count: Integer): String;
    function FormatDoubleArray(_Address: NativeInt; _Count: Integer): String;
    function FormatCurrencyArray(_Address: NativeInt; _Count: Integer): String;
    function FormatDateTimeArray(_Address: NativeInt; _Count: Integer): String;
    function FormatBooleanArray(_Address: NativeInt; _Count: Integer): String;

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
    { TODO 1 -oVasilyevSM -cuVariantValueReplacer: ��������� ������ ���� �� ���. }
    varDate:  Result := FormatDateTime(ReadDateTime, True);

  else
    Result := _Default;
  end;

  { TODO 1 -oVasilyevSM -cuVariantValueReplacer: ������ ����� ��������� ������� � ���. }
  Result := Format('%s: %s', [VarTypeToStr(_VarType), Result]);

end;

function TVariantValueReplacer.FormatArray(_VarType, _ElementVarType: TVarType; const _Expression, _Default: String): String;
const

  SC_HEADER_FORMAT      = 'varArray [%d..%d] of %s = (%s)';
  SC_UNSUPPORTED_FORMAT = 'varArray [%d..%d] of %s with Dim = %d';

var
  VarArrayExpr: String;
  Dim: Word;
  Low, High, Count: Integer;
  StrType: String;
  Address: NativeInt;
begin

  { ��������� TVarData. }
  if (_VarType and varByRef) = 0 then VarArrayExpr := 'TVarData(<Context>).VArray^'
  else VarArrayExpr := 'PVarArray(TVarData(<Context>).VPointer^)^';

  with Evaluator do begin

    { ��������� �������������� �������. }
    ReadFunction(Format('%s.DimCount',               [VarArrayExpr]), 'Word',    SizeOf(Word),    Dim);
    ReadFunction(Format('%s.Bounds[0].LowBound',     [VarArrayExpr]), 'Integer', SizeOf(Integer), Low);
    ReadFunction(Format('%s.Bounds[0].ElementCount', [VarArrayExpr]), 'Integer', SizeOf(Integer), Count);
    High := Low + Count - 1;
    StrType := VarTypeToStr(_ElementVarType);

    if Dim = 1 then begin

      { ��������� ����� �������. }
      ReadFunction(Format('NativeInt(%s.Data)', [VarArrayExpr]), 'NativeInt', SizeOf(NativeInt), Address);

      case _ElementVarType of

        varSmallint: Exit(Format(SC_HEADER_FORMAT, [Low, High, StrType, FormatSimpleArray(Address, Count, 'PSmallInt', SizeOf(SmallInt))]));
        varInteger:  Exit(Format(SC_HEADER_FORMAT, [Low, High, StrType, FormatSimpleArray(Address, Count, 'PInteger',  SizeOf(Integer ))]));
        varSingle:   Exit(Format(SC_HEADER_FORMAT, [Low, High, StrType, FormatSimpleArray(Address, Count, 'PSingle',   SizeOf(Single  ))]));
        varDouble:   Exit(Format(SC_HEADER_FORMAT, [Low, High, StrType, FormatSimpleArray(Address, Count, 'PDouble',   SizeOf(Double  ))]));
        varCurrency: Exit(Format(SC_HEADER_FORMAT, [Low, High, StrType, FormatSimpleArray(Address, Count, 'PCurrency', SizeOf(Currency))]));
        varDate:     Exit(Format(SC_HEADER_FORMAT, [Low, High, StrType, FormatDateTimeArray(Address, Count)]));
//        varOleStr
//        varBoolean:  Exit(Format(SC_HEADER_FORMAT, [Low, High, StrType, FormatBooleanArray(Address, Count)]));
//        varVariant
        varShortInt: Exit(Format(SC_HEADER_FORMAT, [Low, High, StrType, FormatSimpleArray(Address, Count, 'PShortInt', SizeOf(ShortInt))]));
        varByte:     Exit(Format(SC_HEADER_FORMAT, [Low, High, StrType, FormatSimpleArray(Address, Count, 'PByte',     SizeOf(Byte    ))]));
        varWord:     Exit(Format(SC_HEADER_FORMAT, [Low, High, StrType, FormatSimpleArray(Address, Count, 'PWord',     SizeOf(Word    ))]));
        varLongWord: Exit(Format(SC_HEADER_FORMAT, [Low, High, StrType, FormatSimpleArray(Address, Count, 'PLongWord', SizeOf(LongWord))]));
        varInt64:    Exit(Format(SC_HEADER_FORMAT, [Low, High, StrType, FormatSimpleArray(Address, Count, 'PInt64',    SizeOf(Int64   ))]));
        varUInt64:   Exit(Format(SC_HEADER_FORMAT, [Low, High, StrType, FormatSimpleArray(Address, Count, 'PUInt64',   SizeOf(UInt64  ))]));
//        varString
//        varUString

      end;

    end;

  end;

  Result := Format(SC_UNSUPPORTED_FORMAT, [Low, High, StrType, Dim]);

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

function TVariantValueReplacer.FormatSmallIntArray(_Address: NativeInt; _Count: Integer): String;
var
  i: Integer;
  Item: SmallInt;
begin

  Result := '';
  for i := 0 to _Count - 1 do begin

    Evaluator.ReadFunction(Format('TSmallIntDynArray(%d)[%d]', [_Address, i]), 'SmallInt', SizeOf(SmallInt), Item);
    Result := Format('%s%d, ', [Result, Item]);

  end;

  CutStr(Result, 2);

end;

function TVariantValueReplacer.FormatIntegerArray(_Address: NativeInt; _Count: Integer): String;
var
  i: Integer;
  Item: Integer;
begin

  Result := '';
  for i := 0 to _Count - 1 do begin

    Evaluator.ReadFunction(Format('TIntegerDynArray(%d)[%d]', [_Address, i]), 'Integer', SizeOf(Integer), Item);
    Result := Format('%s%d, ', [Result, Item]);

  end;

  CutStr(Result, 2);

end;

function TVariantValueReplacer.FormatSingleArray(_Address: NativeInt; _Count: Integer): String;
var
  i: Integer;
  Item: Single;
begin

  Result := '';
  for i := 0 to _Count - 1 do begin

    Evaluator.ReadFunction(Format('TSingleDynArray(%d)[%d]', [_Address, i]), 'Single', SizeOf(Single), Item);
    Result := Format('%s%n, ', [Result, Item]);

  end;

  CutStr(Result, 2);

end;

function TVariantValueReplacer.FormatDoubleArray(_Address: NativeInt; _Count: Integer): String;
var
  i: Integer;
  Item: Double;
begin

  Result := '';
  for i := 0 to _Count - 1 do begin

    Evaluator.ReadFunction(Format('TDoubleDynArray(%d)[%d]', [_Address, i]), 'Double', SizeOf(Double), Item);
    Result := Format('%s%n, ', [Result, Item]);

  end;

  CutStr(Result, 2);

end;

function TVariantValueReplacer.FormatCurrencyArray(_Address: NativeInt; _Count: Integer): String;
var
  i: Integer;
begin

  Result := '';
  for i := 0 to _Count - 1 do

    Result := Format('%s%s, ', [

        Result,
        Evaluator.Evaluate(Format('PCurrency(%d + %d)^', [_Address, i * SizeOf(Currency)]))

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

function TVariantValueReplacer.FormatBooleanArray(_Address: NativeInt; _Count: Integer): String;
var
  i: Integer;
  Item: Boolean;
begin

  Result := '';
  for i := 0 to _Count - 1 do begin

    Evaluator.ReadFunction(Format('TBooleanDynArray(%d)[%d]', [_Address, i]), 'Boolean', SizeOf(Boolean), Item);
    Result := Format('%s%s, ', [Result, BooleanToStr(Item)]);

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

  { TODO 1 -oVasilyevSM -cuVariantValueReplacer:

    ����� ���������� ����� ��������� ��������� � ������ � ������������ ���
    ��� ����� ����������� ���������� (����, InititializeContext). ��� ��� ���-�� �������� ContextVariable. � ������,
    ������� ����� �������, ������� ����� ���������� ������ ������ ��� ���������. � ����� �� ������������� ����� �
    �������� ���� ����������� ���������� � ����� �������, ������������ � ReadContext. � ��� ������������ ��� �� %s, �
    ���-�� ���� <Context>. � � ����� ���������� ������, ������� ���� ���������� (FinalizeContext). ������, �
    ReadContext ����� ���������� ������� ����������, ���� �������� �� ��� ������������� (������� ����).

    ��� ���������� ��������� � ��������� ������� EvaluateVariant � ���� �� ����������� (_Expression, _TypeName,
    _EvalResult). ����� ����� ����� �� �� �������� ��� ��������� ������� ���������. � ��� ��� ��������� � �����
    try-finally ������� ��������� ������������� � ����������� ���������.

    TypeName ��� TVariantEvaluator-� ������������ �� �����������, � ���������� ��� ������ �� ��������� _TypeName.
    ������, �� ������ �������, ��� ��������� TypeSize � ������ ��������� ��������. �� ��� ������ ����� ������ ����� ��
    ����������, ��������� ������� ��������� ����� ������ �������� � �������� ��� ������������ ��� ��� ������ ����������,
    ������� ������ ��� ������ ���� � _TypeName �����. ������, ��� ����� ������� ���������, ������� ������� ����� ������
    �� ���� �� �����������. ��������, ��� ���������� ������������� �������� ��� ������-������ ������� ������������
    �������.

    ��� ������ ������� ������� � � �������� ������� ����� �������� � ������ ������� ReadSingleContext, ������� �����
    ���������������� � �������������� ��������. ��������, ��� ���������� ��� ���������� ������. ���-����, ���� �������,
    ��� ������ ����� ������������ � ������ ���������. ����� �������� � ��������������� ��� ������� �������� ��������.

  }

  try

    WriteLog('');
    with Evaluator do begin

      InitVariable('Context', 'Variant', SizeOf(Variant), _Expression);
      try

        { Variants.VarType ����� �� ������������, ��������� Variants ����� ���� �� ��������� � ������������ �������. �
          TVarData ����� � System. }
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

      {$IFDEF DEBUG}
      WriteException(E);
      {$ENDIF}

    end;

  end;

end;

end.
