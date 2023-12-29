unit uUserParamsReader;

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
  uParamsReader, uParams, uUserParams, uReadWriteCommon;

type

  TUserParamsReader = class(TParamsReader, IUserParamsReader)

  strict private

    FCurrentParam: TUserParam;
    FCurrentComments: TUserParam.TCommentList;

    { IUserParamsReader }
    procedure AddNameComment(const _Value, _Opening, _Closing: String; _Short, _Before: Boolean);
    procedure AddTypeComment(const _Value, _Opening, _Closing: String; _Short, _Before: Boolean);
    procedure AddValueComment(const _Value, _Opening, _Closing: String; _Short, _Before: Boolean);
    procedure DetachBefore;
    procedure SourceEnd;
    procedure ElementTerminated;

    property CurrentParam: TUserParam read FCurrentParam write FCurrentParam;
    property CurrentComments: TUserParam.TCommentList read FCurrentComments;

  protected

    procedure RetrieveParams(_Value: TParams); override;

    procedure BeforeReadParam(_Param: TParam); override;
    procedure AfterReadParam(_Param: TParam); override;
    procedure AfterNestedReading(_Param: TParam; _NestedReader: TParamsReader); override;

  public

    constructor Create; override;
    destructor Destroy; override;

  end;

implementation

{ TUserParamsReader }

constructor TUserParamsReader.Create;
begin
  inherited Create;
  FCurrentComments := TUserParam.TCommentList.Create;
end;

destructor TUserParamsReader.Destroy;
begin
  FreeAndNil(FCurrentComments);
  inherited Destroy;
end;

procedure TUserParamsReader.AddNameComment(const _Value, _Opening, _Closing: String; _Short, _Before: Boolean);
begin
  if _Before then
    CurrentComments.AddComment(_Value, _Opening, _Closing, caBeforeName, _Short)
  else
    CurrentComments.AddComment(_Value, _Opening, _Closing, caAfterName, _Short);
end;

procedure TUserParamsReader.AddTypeComment(const _Value, _Opening, _Closing: String; _Short, _Before: Boolean);
begin
  if _Before then
    CurrentComments.AddComment(_Value, _Opening, _Closing, caBeforeType, _Short)
  else
    CurrentComments.AddComment(_Value, _Opening, _Closing, caAfterType, _Short);
end;

procedure TUserParamsReader.AddValueComment(const _Value, _Opening, _Closing: String; _Short, _Before: Boolean);
begin
  if _Before then
    CurrentComments.AddComment(_Value, _Opening, _Closing, caBeforeValue, _Short)
  else
    CurrentComments.AddComment(_Value, _Opening, _Closing, caAfterValue, _Short);
end;

procedure TUserParamsReader.DetachBefore;
var
  i: Integer;
begin

  { ���� ����� ������������ ����� ������� ���� ����� ������, ���� �� ��� ����������� �� BeforeName � BeforeParam. }
  for i := 0 to CurrentComments.Count - 1 do
    with CurrentComments[i] do
      if Anchor = caBeforeName then
        CurrentComments[i] := TUserParam.TComment.Create(Text, Opening, Closing, caBeforeParam, Short);

end;

procedure TUserParamsReader.SourceEnd;
var
  i: Integer;
begin

  { ��������� ����� ������������� � ��������� BeforeName � ��������� ������� ������ �� �����. ���������� ��� �������
    ����������� � AfterParam ���������� ���������� ���������. }
  for i := 0 to CurrentComments.Count - 1 do
    with CurrentComments[i] do
      CurrentComments[i] := TUserParam.TComment.Create(Text, Opening, Closing, caAfterParam, Short);

  if Assigned(CurrentParam) then begin

    CurrentParam.Comments.AddRange(CurrentComments);
    CurrentComments.Clear;

  end;

end;

procedure TUserParamsReader.ElementTerminated;
begin

  if Assigned(CurrentParam) then

    with CurrentParam do begin

      { ������� ���� "���������", ���� ��� ���� ������, ��� ����� ��������� ���� ������������ InsideEmptyParams,
        ���������� ���� � ����� ���������� ������ (AfterReadParams). �������, ����� ������ ������� � ������ ������. }
      Comments.InsertRange(0, CurrentComments);
      CurrentComments.Clear;

    end;

end;

procedure TUserParamsReader.RetrieveParams(_Value: TParams);
begin
  if not (_Value is TUserParams) then
    raise EParamsReadException.Create('Output params must be a class TUserParams object.');
  inherited RetrieveParams(_Value);
end;

procedure TUserParamsReader.BeforeReadParam(_Param: TParam);
begin
  inherited BeforeReadParam(_Param);
  (_Param as TUserParam).Comments.Clear;
end;

procedure TUserParamsReader.AfterReadParam(_Param: TParam);
begin
  inherited AfterReadParam(_Param);
  CurrentParam := _Param as TUserParam;
  CurrentParam.Comments.AddRange(CurrentComments);
  CurrentComments.Clear;
end;

procedure TUserParamsReader.AfterNestedReading(_Param: TParam; _NestedReader: TParamsReader);
var
  Comment: TUserParam.TComment;
  NestedComments: TUserParam.TCommentList;
begin

  inherited AfterNestedReading(_Param, _NestedReader);

  { ������ ���������� ����� ��������� � ������� ����������� ��� ������� ���������� ����������. ����� �������� ������
    "���������", ����� ��������� ���������� �� ���� ������. ������ �� ���������-������� ��� InsideEmptyParams. }

  NestedComments := (_NestedReader as TUserParamsReader).CurrentComments;

  for Comment in NestedComments do
    with Comment do
      CurrentComments.AddComment(Text, Opening, Closing, caInsideEmptyParams, Short);

  NestedComments.Clear;

end;

end.
