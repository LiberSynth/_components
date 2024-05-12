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
  SysUtils, ToolsAPI, Generics.Collections,
  { LiberSynth }
  uCore, uTypes, uLog, uStrUtils,
  { LSDebug }
  uCustom, uCommon, uProjectConsts;

type

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

  public

    destructor Destroy; override;

  end;

  TCustomEvaluator = class

  strict private

  type

    TVariable = record

      Name: String;
      TypeName: String;
      Size: Integer;
      Address: NativeInt;

      constructor Create(const _Name, _TypeName: String; _Size: Integer; _Address: NativeInt);

      class function Expression(const _TypeName: String; _Address: NativeInt): String; overload; static;
      function Expression: String; overload;

    end;

    TVariableList = class(TList<TVariable>)

    private

      procedure Add(const _Name, _TypeName: String; _Size: Integer; _Address: NativeInt);
      function Get(const _Name: String): TVariable;
      function Find(const _Name: String; var _Variable: TVariable): Boolean;

    end;

  strict private

    FVariableList: TVariableList;
    FSingleFunctionCalling: Boolean;

    function AllocRemoteMemory(_Size: Cardinal): NativeInt;
    procedure FreeRemoteMemory(_Address: NativeInt);

    function VariableExpression(const _Name: String): String;
    function InsertVariables(const _Expression: String): String;
    procedure CheckUnknownVariables(const _Expression: String);

  public

    const SC_SINGLE_FUNCTION_CONTEXT = 'SingleFunctionContext';

    constructor Create;
    destructor Destroy; override;

    function Evaluate(const _Expression: String; var _EvaluateResult: TEvaluateResult): String; overload;
    function Evaluate(const _Expression: String): String; overload;
    function Evaluate(const _Expression: String; var _CanModify: Boolean): String; overload;
    function Modify(const _ValueStr: String; var _ModifyResult: TModifyResult): String; overload;
    function Modify(const _ValueStr: String): String; overload;

    procedure InitVariable(const _Name, _TypeName: String; _Size: Cardinal; const _Expression: String);
    procedure FinVariable(const _Name: String);
    function VariableAddress(const _Name: String): NativeInt;
    procedure ReadVariable(const _Name: String; var _Result);
    procedure ReadFunction(const _Function, _TypeName: String; _Size: Cardinal; var _Result);
    procedure ReadSingleContext(const _Expression, _TypeName: String; _Size: Cardinal; var _Result);
    procedure ReadSingleFunction(const _Expression, _Function, _ContextTypeName, _ResultTypeName: String; _ContextSize, _ResultSize: Cardinal; var _Result);

  end;

  TCustomEvaluatorClass = class of TCustomEvaluator;

  ECustomLSDebugException = class(ECoreException);
  ELSDebugException = class(ECustomLSDebugException);
  EEvaluateExceptopn = class(ECustomLSDebugException);
  EModifyException = class(ECustomLSDebugException);
  EModifyRemoteMemoryException = class(ECustomLSDebugException);

procedure GetDebuggerServices;

function DebuggerServices: IOTADebuggerServices;
function CurrentProcess: IOTAProcess;
function CurrentThread: IOTAThread;

implementation

var
  DbgrServices: IOTADebuggerServices;

procedure GetDebuggerServices;
begin
  DbgrServices := BorlandIDEServices as IOTADebuggerServices;
end;

function DebuggerServices: IOTADebuggerServices;
begin
  Result := DbgrServices;
  if not Assigned(Result) then
    raise ELSDebugException.Create('Interface IOTADebuggerServices not loaded.');
end;

function CurrentProcess: IOTAProcess;
begin
  Result := DebuggerServices.CurrentProcess;
  if not Assigned(Result) then
    raise ELSDebugException.Create('CurrentProcess not found.');
end;

function CurrentThread: IOTAThread;
begin
  Result := CurrentProcess.CurrentThread;
  if not Assigned(Result) then
    raise ELSDebugException.Create('CurrentThread not found.');
end;

function _OTAEvaluateResultToStr(Value: TOTAEvaluateResult): String;
begin

  case Value of

    erOK:       Result := 'OK';
    erError:    Result := 'Error';
    erDeferred: Result := 'Deferred';
    erBusy:     Result := 'Busy';

  else
    EUncompletedMethod.Create;
  end;


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

destructor TThreadNotifier.Destroy;
begin

  inherited;
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

{ TCustomEvaluator.TVariable }

constructor TCustomEvaluator.TVariable.Create;
begin

  Name     := _Name;
  TypeName := _TypeName;
  Size     := _Size;
  Address  := _Address;

end;

class function TCustomEvaluator.TVariable.Expression(const _TypeName: String; _Address: NativeInt): String;
const
  SC_VARIABLE_EXPRESSION = '%s(Pointer(%d)^)';
begin
  Result := Format(SC_VARIABLE_EXPRESSION, [_TypeName, _Address]);
end;

function TCustomEvaluator.TVariable.Expression: String;
begin
  Result := Expression(TypeName, Address);
end;

{ TCustomEvaluator.TVariableList }

procedure TCustomEvaluator.TVariableList.Add;
begin
  inherited Add(TVariable.Create(_Name, _TypeName, _Size, _Address));
end;

function TCustomEvaluator.TVariableList.Get(const _Name: String): TVariable;
begin
  if not Find(_Name, Result) then
    raise ELSDebugException.CreateFmt('Variable %s has not been initialized.', [_Name]);
end;

function TCustomEvaluator.TVariableList.Find(const _Name: String; var _Variable: TVariable): Boolean;
var
  Item: TVariable;
begin

  for Item in Self do

    if SameText(Item.Name, _Name) then
    begin

      _Variable := Item;
      Exit(True);

    end;

  Result := False;

end;

{ TCustomEvaluator }

constructor TCustomEvaluator.Create;
begin
  inherited Create;
  FVariableList := TVariableList.Create;
end;

destructor TCustomEvaluator.Destroy;
begin
  FreeAndNil(FVariableList);
  inherited Destroy;
end;

function TCustomEvaluator.AllocRemoteMemory(_Size: Cardinal): NativeInt;
const

  { AllocMem, потому что она заполняет память нулями. }
  SC_ALLOCATE_EXPRESSION = 'NativeInt(AllocMem(%d))';
  SC_ALLOC_ERROR         = 'Allocate remote memory error (%s)';

var
  StrResult: String;
begin

  StrResult := Evaluate(Format(SC_ALLOCATE_EXPRESSION, [_Size]));
  try

    Result := StrToInt(StrResult);

  except
    raise EModifyRemoteMemoryException.CreateFmt(SC_ALLOC_ERROR, [StrResult]);
  end;

end;

procedure TCustomEvaluator.FreeRemoteMemory(_Address: NativeInt);
const

  SC_FREE_EXPRESSION  = 'FreeMem(Pointer(%d))';
  SC_SUCCESS_EVAL_RES = '(no value)';
  SC_FREE_ERROR       = 'Free remote memory error (%s)';

var
  StrResult: String;
begin

  StrResult := Evaluate(Format(SC_FREE_EXPRESSION, [_Address]));
  if not SameText(StrResult, SC_SUCCESS_EVAL_RES) then
    raise EModifyRemoteMemoryException.CreateFmt(SC_FREE_ERROR, [StrResult]);

end;

function TCustomEvaluator.VariableExpression(const _Name: String): String;
begin
  Result := FVariableList.Get(_Name).Expression;
end;

function TCustomEvaluator.InsertVariables(const _Expression: String): String;
var
  Item: TVariable;
begin

  Result := _Expression;
  for Item in FVariableList do begin

    Result := StringReplace(

        Result,
        Format('<%s>', [Item.Name]),
        Item.Expression,
        [rfReplaceAll, rfIgnoreCase]

    );

    {$IFDEF DEBUG}
    WriteLogFmt('_Expression = %s; Item.Name = %s; Item.Expression = %s; ', [_Expression, Item.Name, Item.Expression]);
    {$ENDIF}

  end;

  CheckUnknownVariables(Result);

end;

procedure TCustomEvaluator.CheckUnknownVariables(const _Expression: String);
var
  VStart, VFinish: Integer;
  SA: TStringArray;
begin

  SetLength(SA, 0);
  VFinish := 0;
  repeat

    VStart := Pos('<', _Expression, VFinish);
    if VStart > 0 then begin

      VFinish := Pos('>', _Expression, VStart);
      if VFinish > 0 then
        AddToStrArray(SA, Copy(_Expression, VStart + 1, VFinish - VStart - 1), False, True);

    end;

  until VStart = 0;

  if Length(SA) > 0 then
    raise ELSDebugException.CreateFmt('Context variables: %s are not initialized.', [ArrayToStr(SA, ', ')]);

end;

function TCustomEvaluator.Evaluate(const _Expression: String; var _EvaluateResult: TEvaluateResult): String;
var
  EvaluateResult: TOTAEvaluateResult;
  ResVal: LongWord;
  TN: TThreadNotifier;
  TNIndex: Integer;
begin

  try

    Result := '';
    FillChar(_EvaluateResult, SizeOf(TEvaluateResult), 0);

    with _EvaluateResult do begin

      { TODO 3 -oVasilyevSM -cLSDebug: Это нормально вообще? А если там больше? }
      SetLength(ResultStr, IC_EvalResultStrLength);
      ExprStr := _Expression;
      EvaluateResult := CurrentThread.Evaluate(_Expression, PChar(ResultStr), Length(ResultStr) - 1, CanModify, True, '', ResultAddress, ResultSize, ResVal);
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

            if TN.FDeferredEvaluateResult.ReturnCode <> 0 then
              raise EEvaluateExceptopn.Create(TN.FDeferredEvaluateResult.ResultStr);
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

      erError: raise EEvaluateExceptopn.Create(_EvaluateResult.ResultStr);

    end;

  finally
    {$IFDEF DEBUG}
    WriteLogFmt('TCustomEvaluator.Evaluate: _Expression = %s; Result = %s', [_Expression, Result]);
    {$ENDIF}
  end;

end;

function TCustomEvaluator.Evaluate(const _Expression: String): String;
var
  ER: TEvaluateResult;
begin
  Result := Evaluate(_Expression, ER);
end;

function TCustomEvaluator.Evaluate(const _Expression: String; var _CanModify: Boolean): String;
var
  ER: TEvaluateResult;
begin
  Result := Evaluate(_Expression, ER);
  _CanModify := ER.CanModify;
end;

function TCustomEvaluator.Modify(const _ValueStr: String; var _ModifyResult: TModifyResult): String;
var
  EvaluateResult: TOTAEvaluateResult;
  ResVal: Integer;
  TN: TThreadNotifier;
  TNIndex: Integer;
begin

  try

    Result := '';
    FillChar(_ModifyResult, SizeOf(TModifyResult), 0);
    FillChar(EvaluateResult, SizeOf(TOTAEvaluateResult), 0);

    with _ModifyResult do begin

      { TODO 3 -oVasilyevSM -cLSDebug: Это нормально вообще? А если там больше? }
      SetLength(ResultStr, IC_EvalResultStrLength);
      ExprStr := _ValueStr;
      EvaluateResult := CurrentThread.Modify(_ValueStr, PChar(ResultStr), Length(ResultStr) - 1, ResVal);
      SetLength(ResultStr, StrLen(PChar(ResultStr)));

    end;

    case EvaluateResult of

      erOK: Result := _ModifyResult.ResultStr;
      erDeferred:

        with CurrentThread do begin

          TN := TThreadNotifier.Create;
          TNIndex := AddNotifier(TN);
          try

            TN.StartDeferredModify;
            while not TN.FCompleted do
              DebuggerServices.ProcessDebugEvents;
            if TN.FDeferredModifyResult.ReturnCode <> 0 then
              raise EEvaluateExceptopn.Create(TN.FDeferredModifyResult.ResultStr);
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

  finally
    {$IFDEF DEBUG}
    WriteLogFmt('TCustomEvaluator.Modify: _ValueStr = %s; Result = %s; EvaluateResult = %s; ResVal = %d', [_ValueStr, Result, _OTAEvaluateResultToStr(EvaluateResult), ResVal]);
    {$ENDIF}
  end;

end;

function TCustomEvaluator.Modify(const _ValueStr: String): String;
var
  MR: TModifyResult;
begin
  Result := Modify(_ValueStr, MR);
end;

procedure TCustomEvaluator.InitVariable(const _Name, _TypeName: String; _Size: Cardinal; const _Expression: String);
var
  Address: NativeInt;
  ModifyResult: TModifyResult;
begin

  { TODO 1 -oVasilyevSM -cLSDebug: Вопрос к этому фрэймворку: что делать с переменными типов, которые хранятся по ссылке? }

  { Для лога. }
  {$IFDEF DEBUG}Address := -1;{$ENDIF}

  try

    if not FSingleFunctionCalling and SameText(_Name, SC_SINGLE_FUNCTION_CONTEXT) then
      raise EEvaluateExceptopn.CreateFmt('Variable name %s is reserved.', [SC_SINGLE_FUNCTION_CONTEXT]);

    Address := AllocRemoteMemory(_Size);
    try

      { Заполнение переменной. }
      FVariableList.Add(_Name, _TypeName, _Size, Address);
      Evaluate(VariableExpression(_Name));
      Modify(InsertVariables(_Expression), ModifyResult);
      if SameText(Copy(ModifyResult.ResultStr, 1, 5), 'E2453') then
        raise EEvaluateExceptopn.CreateFmt('Type %s is not supported for evaluating variables.', [_TypeName]);

    except
      FreeRemoteMemory(Address);
      raise;
    end;

  finally
    {$IFDEF DEBUG}
    WriteLogFmt('TCustomEvaluator.InitVariable: _Name = %s; _TypeName = %s; _Size = %d; _Expression = %s; Address = %d', [_Name, _TypeName, _Size, _Expression, Address]);
    WriteLogFmt('TCustomEvaluator.InitVariable: ModifyResult.ExprStr = %s; ModifyResult.ResultStr = %s; ModifyResult.ReturnCode = %d', [ModifyResult.ExprStr, ModifyResult.ResultStr, ModifyResult.ReturnCode]);
    {$ENDIF}
  end;

end;

procedure TCustomEvaluator.FinVariable(const _Name: String);
var
  Variable: TVariable;
  Address: NativeInt;
begin

  { Для лога. }
  {$IFDEF DEBUG}Address := -1;{$ENDIF}

  try

    if FVariableList.Find(_Name, Variable) then begin

      Address := Variable.Address;
      FVariableList.Remove(Variable);
      FreeRemoteMemory(Address);

    end;

  finally
    {$IFDEF DEBUG}
    WriteLogFmt('TCustomEvaluator.FinVariable: _Name = %s; Address = %d', [_Name, Address]);
    {$ENDIF}
  end;

end;

function TCustomEvaluator.VariableAddress(const _Name: String): NativeInt;
begin
  Result := FVariableList.Get(_Name).Address;
end;

procedure TCustomEvaluator.ReadVariable(const _Name: String; var _Result);
var
  Variable: TVariable;
  Address: NativeInt;
  Size: Integer;
begin

  { Для лога. }
  {$IFDEF DEBUG}
  Address := -1;
  Size    := -1;
  {$ENDIF}

  try

    Variable := FVariableList.Get(_Name);
    Address  := Variable.Address;
    Size     := Variable.Size;

    CurrentProcess.ReadProcessMemory(Address, Size, _Result);

  finally
    {$IFDEF DEBUG}
    WriteLogFmt('TCustomEvaluator.ReadVariable: _Name = %s; Address = %d; Size = %d', [_Name, Address, Size]);
    {$ENDIF}
  end;

end;

procedure TCustomEvaluator.ReadFunction(const _Function, _TypeName: String; _Size: Cardinal; var _Result);
var
  Address: NativeInt;
  ValueStr: String;
begin

  { Для лога. }
  {$IFDEF DEBUG}Address := -1;{$ENDIF}

  try

    Address := AllocRemoteMemory(_Size);
    try

      Evaluate(TVariable.Expression(_TypeName, Address));
      ValueStr := InsertVariables(_Function);
      Modify(ValueStr);

      CurrentProcess.ReadProcessMemory(Address, _Size, _Result);

    finally
      FreeRemoteMemory(Address);
    end;

  finally
    {$IFDEF DEBUG}
    WriteLogFmt('TCustomEvaluator.ReadFunction: _Function = %s; _TypeName = %s; _Size = %d; Address = %d; ValueStr = %s', [_Function, _TypeName, _Size, Address, ValueStr]);
    {$ENDIF}
  end;

end;

procedure TCustomEvaluator.ReadSingleContext(const _Expression, _TypeName: String; _Size: Cardinal; var _Result);
var
  Variable: String;
begin

  try

    Variable := UniqueName('Var');
    InitVariable(Variable, _TypeName, _Size, _Expression);
    try

      ReadVariable(Variable, _Result);

    finally
      FinVariable(Variable);
    end;

  finally
    {$IFDEF DEBUG}
    WriteLogFmt('TCustomEvaluator.ReadSingleContext: _Expression = %s; _TypeName = %s; _Size = %d; Variable = %s', [_Expression, _TypeName, _Size, Variable]);
    {$ENDIF}
  end;

end;

procedure TCustomEvaluator.ReadSingleFunction(const _Expression, _Function, _ContextTypeName, _ResultTypeName: String; _ContextSize, _ResultSize: Cardinal; var _Result);
begin

  try

    FSingleFunctionCalling := True;
    try

      InitVariable(SC_SINGLE_FUNCTION_CONTEXT, _ContextTypeName, _ContextSize, _Expression);
      try

        ReadFunction(_Function, _ResultTypeName, _ResultSize, _Result);

      finally
        FinVariable(SC_SINGLE_FUNCTION_CONTEXT);
      end;

    finally
      FSingleFunctionCalling := False;
    end;

  finally
    {$IFDEF DEBUG}
    WriteLogFmt('TCustomEvaluator.ReadSingleContext: _Expression = %s; _Function = %s; _ContextTypeName = %s; _ResultTypeName = %s; _ContextSize = %d; _ResultSize = %d', [_Expression, _Function, _ContextTypeName, _ResultTypeName, _ContextSize, _ResultSize]);
    {$ENDIF}
  end;

end;

end.
