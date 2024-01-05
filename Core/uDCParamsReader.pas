unit uDCParamsReader;

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
  uParamsReader, uParams, uDCParams, uReadWriteCommon;

type

  TDCParamsReader = class(TParamsReader, INTVCommentsReader)

  strict private

    FCurrentParam: TDCParam;
    FCurrentComments: TCommentList;

    { IUserParamsReader }
    procedure AddNameComment(const _Value, _Opening, _Closing: String; _Short, _Before: Boolean);
    procedure AddTypeComment(const _Value, _Opening, _Closing: String; _Short, _Before: Boolean);
    procedure AddValueComment(const _Value, _Opening, _Closing: String; _Short, _Before: Boolean);
    procedure DetachBefore;
    procedure SourceEnd;
    procedure ElementTerminated;

    property CurrentParam: TDCParam read FCurrentParam write FCurrentParam;
    property CurrentComments: TCommentList read FCurrentComments;

  protected

    procedure BeforeReadParam(_Param: TParam); override;
    procedure AfterReadParam(_Param: TParam); override;
    procedure AfterNestedReading(_Param: TParam; _NestedReader: TParamsReader); override;

  public

    constructor Create; override;
    destructor Destroy; override;

    procedure RetrieveParams(_Value: TParams); override;

  end;

implementation

{ TUserParamsReader }

constructor TDCParamsReader.Create;
begin
  inherited Create;
  FCurrentComments := TCommentList.Create;
end;

destructor TDCParamsReader.Destroy;
begin
  FreeAndNil(FCurrentComments);
  inherited Destroy;
end;

procedure TDCParamsReader.AddNameComment(const _Value, _Opening, _Closing: String; _Short, _Before: Boolean);
begin
  if _Before then
    CurrentComments.AddComment(_Value, _Opening, _Closing, caBeforeName, _Short)
  else
    CurrentComments.AddComment(_Value, _Opening, _Closing, caAfterName, _Short);
end;

procedure TDCParamsReader.AddTypeComment(const _Value, _Opening, _Closing: String; _Short, _Before: Boolean);
begin
  if _Before then
    CurrentComments.AddComment(_Value, _Opening, _Closing, caBeforeType, _Short)
  else
    CurrentComments.AddComment(_Value, _Opening, _Closing, caAfterType, _Short);
end;

procedure TDCParamsReader.AddValueComment(const _Value, _Opening, _Closing: String; _Short, _Before: Boolean);
begin
  if _Before then
    CurrentComments.AddComment(_Value, _Opening, _Closing, caBeforeValue, _Short)
  else
    CurrentComments.AddComment(_Value, _Opening, _Closing, caAfterValue, _Short);
end;

procedure TDCParamsReader.DetachBefore;
var
  i: Integer;
begin

  { ≈сли после комментариев перед имененм есть конец строки, надо их все переместить из BeforeName в BeforeParam. }
  for i := 0 to CurrentComments.Count - 1 do
    with CurrentComments[i] do
      if Anchor = caBeforeName then
        CurrentComments[i] := TComment.Create(Text, Opening, Closing, caBeforeParam, Short);

end;

procedure TDCParamsReader.SourceEnd;
var
  i: Integer;
begin

  { ќбработка блока заканчиваетс€ в положении BeforeName и параметра впереди больше не будет. ѕеремещаем все текущие
    комментарии в AfterParam последнего считанного параметра. }
  for i := 0 to CurrentComments.Count - 1 do
    with CurrentComments[i] do
      CurrentComments[i] := TComment.Create(Text, Opening, Closing, caAfterParam, Short);

  if Assigned(CurrentParam) then begin

    CurrentParam.Comments.AddRange(CurrentComments);
    CurrentComments.Clear;

  end;

end;

procedure TDCParamsReader.ElementTerminated;
begin

  if Assigned(CurrentParam) then

    with CurrentParam do begin

      { Ёлемент типа "параметры", если они были пустые, уже может содержать блок комментариев InsideEmptyParams,
        положенный туда в конце вложенного чтени€ (AfterReadParams). ѕоэтому, здесь делаем вставку в начало списка. }
      Comments.InsertRange(0, CurrentComments);
      CurrentComments.Clear;

    end;

end;

procedure TDCParamsReader.BeforeReadParam(_Param: TParam);
begin
  inherited BeforeReadParam(_Param);
  (_Param as TDCParam).Comments.Clear;
end;

procedure TDCParamsReader.AfterReadParam(_Param: TParam);
begin
  inherited AfterReadParam(_Param);
  CurrentParam := _Param as TDCParam;
  CurrentParam.Comments.AddRange(CurrentComments);
  CurrentComments.Clear;
end;

procedure TDCParamsReader.AfterNestedReading(_Param: TParam; _NestedReader: TParamsReader);
var
  Comment: TComment;
  NestedComments: TCommentList;
begin

  inherited AfterNestedReading(_Param, _NestedReader);

  { „тение вложенного блока завершено и обычные комментарии уже розданы внутренним параметрам. «десь остаютс€ только
    "бесхозные", когда вложенных параметров не было совсем. ќтдаем их параметру-мастеру как InsideEmptyParams. }

  NestedComments := (_NestedReader as TDCParamsReader).CurrentComments;

  for Comment in NestedComments do
    with Comment do
      CurrentComments.AddComment(Text, Opening, Closing, caInsideEmptyParams, Short);

  NestedComments.Clear;

end;

procedure TDCParamsReader.RetrieveParams(_Value: TParams);
begin
  if not (_Value is TDCParams) then
    raise EParamsReadException.Create('Output params must be a class TUserParams object.');
  inherited RetrieveParams(_Value);
end;

end.
