unit uStackTracing;

interface

uses
  SysUtils, Windows;

{ TODO 5 -oVasilyevSM -cuStackTracing: Трейсинг стека. }

implementation

const
  DBG_STACK_LENGTH = 32;
type
  TDbgInfoStack = array[0..DBG_STACK_LENGTH - 1] of Pointer;
  PDbgInfoStack = ^TDbgInfoStack;

{$IFDEF MSWINDOWS}
function RtlCaptureStackBackTrace(FramesToSkip: ULONG; FramesToCapture: ULONG; BackTrace: Pointer;
  BackTraceHash: PULONG): USHORT; stdcall; external 'kernel32.dll';
{$ENDIF}

{$IFDEF MSWINDOWS}
procedure GetCallStackOS(var Stack: TDbgInfoStack; FramesToSkip: Integer);
begin
  ZeroMemory(@Stack, SizeOf(Stack));

  RtlCaptureStackBackTrace(FramesToSkip, Length(Stack), @Stack, nil);
end;
{$ENDIF}

function CallStackToStr(const Stack: TDbgInfoStack): String;
var Ptr: Pointer;
begin
  Result := '';
  for Ptr in Stack do
    if Ptr <> nil then
      Result := Result + Format('$%p', [Ptr]) + sLineBreak
    else
      Break;
end;

function GetExceptionStackInfo(P: SysUtils.PExceptionRecord): Pointer;
begin
  Result := AllocMem(SizeOf(TDbgInfoStack));
  GetCallStackOS(PDbgInfoStack(Result)^, 1); // исключаем саму функцию GetCallStackOS
end;

function GetStackInfoStringProc(Info: Pointer): String;
begin
  Result := CallStackToStr(PDbgInfoStack(Info)^);
end;

procedure CleanUpStackInfoProc(Info: Pointer);
begin
  Dispose(PDbgInfoStack(Info));
end;

procedure InstallExceptionCallStack;
begin
  SysUtils.Exception.GetExceptionStackInfoProc := GetExceptionStackInfo;
  SysUtils.Exception.GetStackInfoStringProc := GetStackInfoStringProc;
  SysUtils.Exception.CleanUpStackInfoProc := CleanUpStackInfoProc;
end;

procedure UninstallExceptionCallStack;
begin
  SysUtils.Exception.GetExceptionStackInfoProc := nil;
  SysUtils.Exception.GetStackInfoStringProc := nil;
  SysUtils.Exception.CleanUpStackInfoProc := nil;
end;

initialization

  InstallExceptionCallStack;

finalization

  UninstallExceptionCallStack;

end.
