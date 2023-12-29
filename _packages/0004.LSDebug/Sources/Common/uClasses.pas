unit uClasses;

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
  SysUtils, ToolsAPI,
  { VDebugPackage }
  uCustom;

type

  EEvaluateError = class(Exception);
  EModifyError = class(Exception);
  EModifyRemoteMemoryError = class(Exception);

  TEvaluateResult = record

    ExprStr:       String;
    ResultStr:     String;
    CanModify:     Boolean;
    ResultAddress: LongWord;
    ResultSize:    LongWord;
    ReturnCode:    Integer;

    constructor Create(

        const _ExprStr: String;
        const _ResultStr: String;
        _CanModify: Boolean;
        _ResultAddress: LongWord;
        _ResultSize: LongWord;
        _ReturnCode: Integer

    );

  end;

  TModifyResult = record

    ExprStr:    String;
    ResultStr:  String;
    ReturnCode: Integer;

    constructor Create(

        const _ExprStr: String;
        const _ResultStr: String;
        _ReturnCode: Integer

    );

  end;

  TThreadNotifier = class(TCustomThreadNotifier)

  private

    FCompleted: Boolean;
    FDeferredEvaluateResult: TEvaluateResult;
    FDeferredModifyResult: TModifyResult;

    procedure StartDeferredEvaluate;
    procedure StartDeferredModify;

  protected

    procedure {$IF DEFINED(DELPHI2010) OR DEFINED(DELPHIXE)}EvaluteComplete{$ELSE}EvaluateComplete{$IFEND}(const _ExprStr, _ResultStr: String; _CanModify: Boolean; _ResultAddress, _ResultSize: LongWord; _ReturnCode: Integer); override;
    procedure ModifyComplete(const _ExprStr: String; const _ResultStr: String; _ReturnCode: Integer); override;

  end;

  TEvaluator = class

  protected

    function ExpressionToRemoteModify(_Address: Cardinal; const _TypeName: String): String; virtual;
    function DataTypePointerName(const _TypeName: String): String; virtual;
    function SuccessEmptyEvaluateResult: String; virtual;
    function RemoteAllocExpression(const _TypeName: String): String; virtual;
    function AllocRemoteMemory(const _TypeName: String): Cardinal;
    procedure FreeRemoteMemory(_Address: Cardinal);
    procedure ModifyRemoteMemory(_Address: Cardinal; const _ModifyExpression, _TypeName: String); virtual;
    function MemoryEvaluateValue(_ValueAddress: Cardinal; const _EvalResult: String): String; virtual;

  public

    function Evaluate(const _Expression: String; var _EvaluateResult: TEvaluateResult): String; overload;
    function Evaluate(const _Expression: String): String; overload;
    function Evaluate(const _Expression: String; var _CanModify: Boolean): String; overload;
    function Modify(const _ValueStr: String; var _ModifyResult: TModifyResult): String; overload;
    function Modify(const _ValueStr: String): String; overload;
    function MemoryEvaluate(const _Expression, _TypeName, _EvalResult: String): String;

  end;

  TEvaluatorClass = class of TEvaluator;

procedure GetDebuggerServices;

function DebuggerServices: IOTADebuggerServices;
function CurrentProcess: IOTAProcess;
function CurrentThread: IOTAThread;

implementation

uses
  { Utils }
  uLog,
  { VDebugPackage }
  uProjectConsts, uCommon;

var
  DbgrServices: IOTADebuggerServices;

procedure GetDebuggerServices;
begin
  DbgrServices := BorlandIDEServices as IOTADebuggerServices;
end;

function DebuggerServices: IOTADebuggerServices;
const
  SC_Message = 'Interface IOTADebuggerServices not loaded';
begin
  Result := DbgrServices;
  if not Assigned(Result) then raise Exception.Create(SC_Message);
end;

function CurrentProcess: IOTAProcess;
const
  SC_Message = 'CurrentProcess not found';
begin
  Result := DebuggerServices.CurrentProcess;
  if not Assigned(Result) then raise Exception.Create(SC_Message);
end;

function CurrentThread: IOTAThread;
const
  SC_Message = 'CurrentThread not found';
begin
  Result := CurrentProcess.CurrentThread;
  if not Assigned(Result) then raise Exception.Create(SC_Message);
end;

{ TEvaluateResult }

constructor TEvaluateResult.Create;
begin

  ExprStr       := _ExprStr;
  ResultStr     := _ResultStr;
  CanModify     := _CanModify;
  ResultAddress := _ResultAddress;
  ResultSize    := _ResultSize;
  ReturnCode    := _ReturnCode;

end;

{ TModifyResult }

constructor TModifyResult.Create;
begin

  ExprStr    := _ExprStr;
  ResultStr  := _ResultStr;
  ReturnCode := _ReturnCode;

end;

{ TThreadNotifier }

procedure TThreadNotifier.StartDeferredEvaluate;
begin
  FillChar(FDeferredEvaluateResult, SizeOf(TEvaluateResult), 0);
  FCompleted := False;
end;

procedure TThreadNotifier.StartDeferredModify;
begin
  FillChar(FDeferredModifyResult, SizeOf(TEvaluateResult), 0);
  FCompleted := False;
end;

procedure TThreadNotifier.{$IF DEFINED(DELPHI2010) OR DEFINED(DELPHIXE)}EvaluteComplete{$ELSE}EvaluateComplete{$IFEND}(const _ExprStr, _ResultStr: String; _CanModify: Boolean; _ResultAddress, _ResultSize: LongWord; _ReturnCode: Integer);
begin
  FDeferredEvaluateResult := TEvaluateResult.Create(_ExprStr, _ResultStr, _CanModify, _ResultAddress, _ResultSize, _ReturnCode);
  FCompleted := True;
end;

procedure TThreadNotifier.ModifyComplete(const _ExprStr, _ResultStr: String; _ReturnCode: Integer);
begin
  FDeferredModifyResult := TModifyResult.Create(_ExprStr, _ResultStr, _ReturnCode);
  FCompleted := True;
end;

{ TEvaluator }

const
  IC_EvalResultStrLength = 16384;

function TEvaluator.Evaluate(const _Expression: String; var _EvaluateResult: TEvaluateResult): String;
var
  EvaluateResult: TOTAEvaluateResult;
  ResVal: LongWord;
  TN: TThreadNotifier;
  TNIndex: Integer;
begin

  Result := '';
  FillChar(_EvaluateResult, SizeOf(TEvaluateResult), 0);

  with _EvaluateResult do begin

    SetLength(ResultStr, IC_EvalResultStrLength);
    ExprStr := _Expression;
    EvaluateResult := CurrentThread.Evaluate(_Expression, PChar(ResultStr), Length(ResultStr) - 1, CanModify, True, '', ResultAddress, ResultSize, ResVal);
    {$IFDEF DEBUG}
    WriteLogFmt('EvaluateResult: %d; ResVal: %d', [Integer(EvaluateResult), ResVal]);
    {$ENDIF}
    SetLength(ResultStr, StrLen(PChar(ResultStr)));

  end;

  case EvaluateResult of

    erOK: Result := _EvaluateResult.ResultStr;
    erDeferred:

      with CurrentThread do begin

        TN := TThreadNotifier.Create;
        TNIndex := AddNotifier(TN);
        try

          TN.StartDeferredEvaluate;
          while not TN.FCompleted do
            DebuggerServices.ProcessDebugEvents;
          if TN.FDeferredEvaluateResult.ReturnCode <> 0 then raise EEvaluateError.Create(TN.FDeferredEvaluateResult.ResultStr);
          _EvaluateResult := TN.FDeferredEvaluateResult;
          Result := TN.FDeferredEvaluateResult.ResultStr;

        finally
          RemoveNotifier(TNIndex);
        end;

      end;

    erBusy:

      begin
        DebuggerServices.ProcessDebugEvents;
        Result := Evaluate(_Expression, _EvaluateResult);
      end;

    erError: raise EEvaluateError.Create(_EvaluateResult.ResultStr);

  end;

end;

function TEvaluator.Evaluate(const _Expression: String): String;
var
  ER: TEvaluateResult;
begin
  Result := Evaluate(_Expression, ER);
end;

function TEvaluator.RemoteAllocExpression(const _TypeName: String): String;
const
  { AllocMem, потому что она заполняет память нулями }
  SC_AllocExpr = 'Cardinal(AllocMem(SizeOf(%s)))';
begin
  Result := Format(SC_AllocExpr, [_TypeName]);
end;

function TEvaluator.AllocRemoteMemory(const _TypeName: String): Cardinal;
const
  SC_AllocError = 'Remote allocate memory error (%s)';
var
  StrResult: String;
begin

  StrResult := Evaluate(RemoteAllocExpression(_TypeName));
  try

    Result := StrToInt(StrResult);

  except
    raise EModifyRemoteMemoryError.CreateFmt(SC_AllocError, [StrResult]);
  end;

end;

function TEvaluator.DataTypePointerName(const _TypeName: String): String;
var
  L: Integer;
begin

  L := Length(_TypeName);

  if L > 0 then

    if _TypeName[1] = 'T' then Result := 'P' + Copy(_TypeName, 2, L)
    else Result := 'P' + _TypeName

  else Result := '';

end;

function TEvaluator.Evaluate(const _Expression: String; var _CanModify: Boolean): String;
var
  ER: TEvaluateResult;
begin
  Result := Evaluate(_Expression, ER);
  _CanModify := ER.CanModify;
end;

function TEvaluator.ExpressionToRemoteModify(_Address: Cardinal; const _TypeName: String): String;
const
  SC_ExpressionToModify = '%s(%d)^';
begin
  Result := Format(SC_ExpressionToModify, [DataTypePointerName(_TypeName), _Address]);
end;

procedure TEvaluator.FreeRemoteMemory(_Address: Cardinal);
const

  SC_FreeExpr = 'FreeMem(Pointer(%d))';
  SC_SuccessEvalRes = '(no value)';
  SC_FreeError = 'Remote free memory error (%s)';

var
  StrResult: String;
begin

  StrResult := Evaluate(Format(SC_FreeExpr, [_Address]));
  if not SameText(StrResult, SC_SuccessEvalRes) then
    raise EModifyRemoteMemoryError.CreateFmt(SC_FreeError, [StrResult]);

end;

function TEvaluator.Modify(const _ValueStr: String; var _ModifyResult: TModifyResult): String;
var
  ModifyResult: TOTAEvaluateResult;
  ResVal: Integer;
  TN: TThreadNotifier;
  TNIndex: Integer;
begin

  Result := '';
  FillChar(_ModifyResult, SizeOf(TModifyResult), 0);

  with _ModifyResult do begin

    SetLength(ResultStr, IC_EvalResultStrLength);
    ExprStr := _ValueStr;
    ModifyResult := CurrentThread.Modify(_ValueStr, PChar(ResultStr), Length(ResultStr) - 1, ResVal);
    {$IFDEF DEBUG}
    WriteLogFmt('EvaluateResult: %d; ResVal: %d', [Integer(ModifyResult), ResVal]);
    {$ENDIF}
    SetLength(ResultStr, StrLen(PChar(ResultStr)));

  end;

  case ModifyResult of

    erOK: Result := _ModifyResult.ResultStr;
    erDeferred:

      with CurrentThread do begin

        TN := TThreadNotifier.Create;
        TNIndex := AddNotifier(TN);
        try

          TN.StartDeferredModify;
          while not TN.FCompleted do
            DebuggerServices.ProcessDebugEvents;
          if TN.FDeferredModifyResult.ReturnCode <> 0 then raise EEvaluateError.Create(TN.FDeferredModifyResult.ResultStr);
          _ModifyResult := TN.FDeferredModifyResult;
          Result := TN.FDeferredModifyResult.ResultStr;

        finally
          RemoveNotifier(TNIndex);
        end;

      end;

    erBusy:

      begin
        DebuggerServices.ProcessDebugEvents;
        Result := Modify(_ValueStr, _ModifyResult);
      end;

    erError: Result := Format(SC_ErrorFormat, [_ModifyResult.ResultStr]);

  end;

end;

function TEvaluator.MemoryEvaluate(const _Expression, _TypeName, _EvalResult: String): String;
var
  ValueAddress: Cardinal;
begin

  try

    ValueAddress := AllocRemoteMemory(_TypeName);
    try

      ModifyRemoteMemory(ValueAddress, _Expression, _TypeName);
      Result := MemoryEvaluateValue(ValueAddress, _EvalResult);

    finally
      FreeRemoteMemory(ValueAddress);
    end;

  except
    on E: Exception do
      Result := FormatException(E);
  end;

end;

function TEvaluator.MemoryEvaluateValue(_ValueAddress: Cardinal; const _EvalResult: String): String;
begin
  Result := _EvalResult;
end;

function TEvaluator.Modify(const _ValueStr: String): String;
var
  MR: TModifyResult;
begin
  Result := Modify(_ValueStr, MR);
end;

procedure TEvaluator.ModifyRemoteMemory(_Address: Cardinal; const _ModifyExpression, _TypeName: String);
const

  SC_ModifyError = 'Modify remote memory error (%s)';
  SC_CanNotModifyError = 'Can not modify value ''%s''';

var
  Expr, StrResult, SuccessRes: String;
  CanModify: Boolean;
begin

  Expr := ExpressionToRemoteModify(_Address, _TypeName);
  StrResult := Evaluate(Expr, CanModify);
  if not CanModify then raise EModifyRemoteMemoryError.CreateFmt(SC_CanNotModifyError, [Expr]);
  SuccessRes := SuccessEmptyEvaluateResult;

  if (Length(SuccessRes) > 0) and not SameText(StrResult, SuccessRes) then
    raise EModifyRemoteMemoryError.CreateFmt(SC_ModifyError, [StrResult]);

  Modify(_ModifyExpression);

end;

function TEvaluator.SuccessEmptyEvaluateResult: String;
begin
  Result := '';
end;

end.
