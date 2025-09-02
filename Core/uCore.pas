unit uCore;

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

{ TODO 3 -oVasilyevSM -cAllLibraries: Избавиться от нижних uses и синхронизировать заголовок Liber Synth в uses. }

interface

uses
  { VCL }
  SysUtils, Rtti,
  { LiberSynth }
  Core.uTypes;

type

  TIntfObject = class(TObject, IInterface)

  protected

    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;

  end;

  TIntfObjectClass = class of TIntfObject;

  { TODO 3 -oVasilyevSM -cuCore: Точно нельзя без класса никак? }
  { TODO 3 -oVasilyevSM -cuCore: Еще похимичить. Не вполне универсально. }
  Matrix<TKey, TReply> = class abstract

  public

    class function PackKey(_Index: TKey): Integer; virtual;
    class function Get(_Index: TKey; const _Map: array of TReply): TReply;

  end;

  MatrixR<TReply> = class abstract

  public

    class function Get<TKey>(_Index: TKey; const _Map: array of TReply): TReply;

  end;

  StrMatrix = class abstract

  public

    class function Get<T>(Index: T; const _Map: array of String): String;

  end;

  ArrayConverter<T> = record

  public

    class function Encode(const _Value: TArray<T>): TConstArray; static;
    class function Decode(const _Value: array of const): TArray<T>; static;

  end;

  ECoreException = class(Exception);

  EUncompletedMethod = class(ECoreException)

  public

    constructor Create;

  end;

implementation

{ TIntfObject }

function TIntfObject.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then Result := S_OK
  else Result := E_NOINTERFACE
end;

function TIntfObject._AddRef: Integer;
begin
  Result := -1;
end;

function TIntfObject._Release: Integer;
begin
  Result := -1;
end;

{ Matrix<TReply, TKey> }

class function Matrix<TKey, TReply>.PackKey(_Index: TKey): Integer;
begin
  Move(_Index, Result, 4);
end;

class function Matrix<TKey, TReply>.Get(_Index: TKey; const _Map: array of TReply): TReply;
var
  I: Integer;
begin

  I := PackKey(_Index);

  if I > High(_Map) then
    raise ECoreException.CreateFmt('Matrix error. Index %d is out of range %d..%d.', [I, Low(_Map), High(_Map)]);

  Result := _Map[I];

end;

{ MatrixR<TReply> }

class function MatrixR<TReply>.Get<TKey>(_Index: TKey; const _Map: array of TReply): TReply;
var
  B: Byte;
begin

  Move(_Index, B, 1);

  if B > High(_Map) then
    raise ECoreException.CreateFmt('Matrix error. Index %d is out of range %d..%d.', [B, Low(_Map), High(_Map)]);

  Result := _Map[B];

end;

{ StrMatrix }

class function StrMatrix.Get<T>(Index: T; const _Map: array of String): String;
var
  B: Byte;
begin

  Move(Index, B, 1);

  if B > High(_Map) then
    raise ECoreException.CreateFmt('Matrix error. Index %d is out of range %d..%d.', [B, Low(_Map), High(_Map)]);

  Result := _Map[B];

end;

{ ArrayConverter }

class function ArrayConverter<T>.Encode(const _Value: TArray<T>): TConstArray;
//var
//  i: Integer;
begin

  SetLength(Result, Length(_Value));

//  for i := Low(Result) to High(Result) do
//    Result[i] := TValue.From<T>(_Value[i]).AsVarRec;

end;

class function ArrayConverter<T>.Decode(const _Value: array of const): TArray<T>;
//var
//  i: Integer;
begin

  SetLength(Result, Length(_Value));

//  for i := Low(Result) to High(Result) do
//    Result[i] := TValue(_Value[i]).AsType<T>;

end;

{ EUncompletedMethod }

constructor EUncompletedMethod.Create;
begin
  inherited Create('Complete this method');
end;

end.
