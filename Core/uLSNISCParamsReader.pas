unit uLSNISCParamsReader;

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

{ LSNI Strong Commented Params Reader }

interface

uses
  { VCL }
  SysUtils,
  { LiberSynth }
  uConsts, uCustomStringParser, uLSNIStringParser, uLSNIParamsReader, uParams, uUserParams, uDataUtils, uStrUtils;

type

  TKeyType = ( { inherits from uParamsStringParser.TKeyType }

      ktNone, ktSourceEnd, ktLineEnd, ktSpace, ktSplitter, ktTypeIdent, ktAssigning, ktStringBorder, ktNestedOpening,
      ktNestedClosing, ktLongCommentOpening, ktLongCommentClosing, ktShortCommentOpening

  );
  TKeyTypes = set of TKeyType;

  { LSNI Strong Commented Params Reader }
  TLSNISCParamsReader = class(TLSNIParamsReader)

  strict private

    FCurrentParam: TUserParam;
    FCurrentComments: TUserParam.TCommentList;
    FCommentTerminatedValue: Boolean;

  private

    function ReadComment: String;
    procedure AddComment(

        const _Value: String;
        const _Opening: String;
        const _Closing: String;
        _Short: Boolean

    );
    procedure DetachBeforeParam;
    procedure SaveTail;

    property CurrentParam: TUserParam read FCurrentParam write FCurrentParam;
    property CurrentComments: TUserParam.TCommentList read FCurrentComments;
    property CommentTerminatedValue: Boolean read FCommentTerminatedValue write FCommentTerminatedValue;

  protected

    procedure InitParser; override;

    procedure BeforeReadParam(_Param: TParam); override;
    procedure AfterReadParam(_Param: TParam); override;
    procedure AfterReadParams(_Param: TParam); override;

  public

    destructor Destroy; override;

    procedure KeyEvent(const _KeyWord: TKeyWord); override;
    function ReadElement(_Trim: Boolean): String; override;
    procedure ElementTerminated(_KeyWord: TKeyWord); override;

  end;

implementation

const

  KWR_LONG_COMMENT_OPENING_KEY_A:  TKeyWord = (KeyTypeInternal: Integer(ktLongCommentOpening);  StrValue: '{';  KeyLength: Length('{'));
  KWR_LONG_COMMENT_CLOSING_KEY_A:  TKeyWord = (KeyTypeInternal: Integer(ktLongCommentClosing);  StrValue: '}';  KeyLength: Length('}'));
  KWR_LONG_COMMENT_OPENING_KEY_B:  TKeyWord = (KeyTypeInternal: Integer(ktLongCommentOpening);  StrValue: '(*'; KeyLength: Length('(*'));
  KWR_LONG_COMMENT_CLOSING_KEY_B:  TKeyWord = (KeyTypeInternal: Integer(ktLongCommentClosing);  StrValue: '*)'; KeyLength: Length('*)'));
  KWR_LONG_COMMENT_OPENING_KEY_C:  TKeyWord = (KeyTypeInternal: Integer(ktLongCommentOpening);  StrValue: '/*'; KeyLength: Length('/*'));
  KWR_LONG_COMMENT_CLOSING_KEY_C:  TKeyWord = (KeyTypeInternal: Integer(ktLongCommentClosing);  StrValue: '*/'; KeyLength: Length('*/'));
  KWR_SHORT_COMMENT_OPENING_KEY_A: TKeyWord = (KeyTypeInternal: Integer(ktShortCommentOpening); StrValue: '//'; KeyLength: Length('//'));
  KWR_SHORT_COMMENT_OPENING_KEY_B: TKeyWord = (KeyTypeInternal: Integer(ktShortCommentOpening); StrValue: '--'; KeyLength: Length('--'));

type

  TCustomCommentRegion = class(TRegion)

  protected

    function CanClose(_Parser: TCustomStringParser): Boolean; override;
    procedure Opened(_Parser: TCustomStringParser); override;

  end;

  TLongCommentRegion = class(TCustomCommentRegion)

  protected

    procedure Execute(_Parser: TCustomStringParser; var _Handled: Boolean); override;

  end;

  TShortCommentRegion = class(TCustomCommentRegion)

  strict private

    procedure DetermineClosingKey(_Parser: TCustomStringParser);

  protected

    procedure Execute(_Parser: TCustomStringParser; var _Handled: Boolean); override;
    procedure Closed(_Parser: TCustomStringParser); override;
    procedure CheckUnterminated; override;

  end;

  TKeyWordHelper = record helper for TKeyWord

  private

    constructor Create(_KeyType: TKeyType; const _StrValue: String); overload;

    function GetKeyType: TKeyType;
    procedure SetKeyType(const _Value: TKeyType);

    {$HINTS OFF}
    function TypeInSet(const _Set: TKeyTypes): Boolean;
    {$HINTS ON}

    property KeyType: TKeyType read GetKeyType write SetKeyType;

  end;

{ TLSNISCParamsReader }

destructor TLSNISCParamsReader.Destroy;
begin
  FreeAndNil(FCurrentComments);
  inherited Destroy;
end;

function TLSNISCParamsReader.ReadComment: String;
begin
  Result := Trim(Copy(Source, RegionStart, Cursor - RegionStart));
end;

procedure TLSNISCParamsReader.AddComment;
var
  Anchor: TCommentAnchor;
begin

  case ElementType of

    etName:  if Length(CurrentName) > 0   then Anchor := caAfterName  else Anchor := caBeforeName;
    etType:  if (CurrentType > dtUnknown) then Anchor := caAfterType  else Anchor := caBeforeType;
    etValue: if Length(CurrentName) = 0   then Anchor := caAfterValue else Anchor := caBeforeValue;

  else
    raise EParamsReadException.Create('Unexpected content element');
  end;

  CurrentComments.AddComment(_Value, _Opening, _Closing, Anchor, _Short);

end;

procedure TLSNISCParamsReader.DetachBeforeParam;
var
  i: Integer;
begin

  if (ElementType = etName) and (CursorStanding = stBefore) then
    for i := 0 to CurrentComments.Count - 1 do
      with CurrentComments[i] do
        if Anchor = caBeforeName then
          CurrentComments[i] := TUserParam.TComment.Create(Text, Opening, Closing, caBeforeParam, Short);

end;

procedure TLSNISCParamsReader.SaveTail;
var
  i: Integer;
begin

  if Assigned(CurrentParam) then begin

    for i := 0 to CurrentComments.Count - 1 do
      with CurrentComments[i] do
        CurrentComments[i] := TUserParam.TComment.Create(Text, Opening, Closing, caAfterParam, Short);

    CurrentParam.Comments.AddRange(CurrentComments);
    CurrentComments.Clear;

  end;

end;

procedure TLSNISCParamsReader.InitParser;
begin

  inherited InitParser;

  FCurrentComments := TUserParam.TCommentList.Create;

  {         RegionClass          OpeningKey                       ClosingKey                      Caption  }
  AddRegion(TLongCommentRegion,  KWR_LONG_COMMENT_OPENING_KEY_A,  KWR_LONG_COMMENT_CLOSING_KEY_A, 'comment');
  AddRegion(TLongCommentRegion,  KWR_LONG_COMMENT_OPENING_KEY_B,  KWR_LONG_COMMENT_CLOSING_KEY_B, 'comment');
  AddRegion(TLongCommentRegion,  KWR_LONG_COMMENT_OPENING_KEY_C,  KWR_LONG_COMMENT_CLOSING_KEY_C, 'comment');
  AddRegion(TShortCommentRegion, KWR_SHORT_COMMENT_OPENING_KEY_A, KWR_EMPTY,                      'comment');
  AddRegion(TShortCommentRegion, KWR_SHORT_COMMENT_OPENING_KEY_B, KWR_EMPTY,                      'comment');

end;

procedure TLSNISCParamsReader.BeforeReadParam(_Param: TParam);
begin
  inherited BeforeReadParam(_Param);
  (_Param as TUserParam).Comments.Clear;
end;

procedure TLSNISCParamsReader.AfterReadParam(_Param: TParam);
begin
  inherited AfterReadParam(_Param);
  CurrentParam := _Param as TUserParam;
end;

procedure TLSNISCParamsReader.AfterReadParams(_Param: TParam);
var
  Comment: TUserParam.TComment;
  ParamComments: TUserParam.TCommentList;
begin

  inherited AfterReadParams(_Param);

  ParamComments := (_Param as TUserParam).Comments;

  { Чтение вложенного блока завершено и обычные комментарии уже розданы внутренним параметрам. Здесь остаются только
    "бесхозные" в случае, когда вложенных параметров не было. Отдаем их параметру-мастеру как InsideEmptyParams. }
  for Comment in CurrentComments do
    with Comment do
      ParamComments.AddComment(Text, Opening, Closing, caInsideEmptyParams, Short);

  CurrentComments.Clear;

end;

procedure TLSNISCParamsReader.KeyEvent(const _KeyWord: TKeyWord);
begin

  inherited KeyEvent(_KeyWord);

  case _KeyWord.KeyType of

    { Которые на предыдущих строках от имени премещаем в BeforeParam оттуда. }
    ktLineEnd:   DetachBeforeParam;
    { Обработка блока заканчивается в положении BeforeName. Но паарметра больше не будет. Перемещаем в AfterParam
      последнего считанного параметра. }
    ktSourceEnd: SaveTail;

  end;

end;

function TLSNISCParamsReader.ReadElement(_Trim: Boolean): String;
begin
  Result := inherited ReadElement(_Trim);
  if CommentTerminatedValue then
    Result := TrimRight(Result);
end;

procedure TLSNISCParamsReader.ElementTerminated(_KeyWord: TKeyWord);
begin

  inherited ElementTerminated(_KeyWord);

  if

      ((ElementType = etName) or (_KeyWord.KeyType = ktSourceEnd)) and
      Assigned(CurrentParam)

  then

    with CurrentParam do begin

      { Элемент типа "параметры", если они были пустые, уже может содержать блок комментариев InsideEmptyParams,
        положенный туда в конце исполнения региона (AfterReadParams). Поэтому, здесь делаем вставку в начало списка. }
      Comments.InsertRange(0, CurrentComments);
      CurrentComments.Clear;

    end;

end;

{ TCustomCommentRegion }

function TCustomCommentRegion.CanClose(_Parser: TCustomStringParser): Boolean;
begin
  Result := Executed;
end;

procedure TCustomCommentRegion.Opened(_Parser: TCustomStringParser);
begin

  CancelToggling := True;

  inherited Opened(_Parser);

  with _Parser as TLSNISCParamsReader do

    if CursorStanding = stInside then begin

      { Флаг нужен для обрезки пробелов справа от элемента при считывании. Они точно являюются отступом перед
        комментарием, а не частью значения. }
      CommentTerminatedValue := True;
      try

        { Обрабатываем текущий элемент. Начало комментария это всегда конец тела, что бы там ни было. }
        ProcessElement;

      finally
        CommentTerminatedValue := False;
      end;

    end;

end;

{ TLongCommentRegion }

procedure TLongCommentRegion.Execute(_Parser: TCustomStringParser; var _Handled: Boolean);
var
  p: Int64;
begin

  with _Parser as TLSNISCParamsReader do begin

    { Перемещаемся сразу на конец комментария, чтобы не бежать туда циклом. Этот Pos найдет его быстрее. }
    p := Pos(ClosingKey.StrValue, Source, Cursor);
    if p = 0 then Move(SrcLen - Cursor + 1)
    else Move(p - Cursor);

    { Считываем, потому что уже можем. Так меньше лишней нагрузки, так как CanClose уже просто True. }
    AddComment(ReadComment, OpeningKey.StrValue, ClosingKey.StrValue, False);

  end;

  inherited Execute(_Parser, _Handled);
  _Handled := True;

end;

{ TShortCommentRegion }

procedure TShortCommentRegion.Closed(_Parser: TCustomStringParser);
begin

  inherited Closed(_Parser);

  with _Parser as TLSNISCParamsReader do
    if (ElementType = etValue) and (CursorStanding = stAfter) then
      KeyEvent(KWR_LINE_END_CRLF);

end;

procedure TShortCommentRegion.DetermineClosingKey(_Parser: TCustomStringParser);
begin

  with _Parser do

    if      Eof                                                  then ClosingKey := KWR_EMPTY
    else if Copy(Source, Cursor, 2) = KWR_LINE_END_CRLF.StrValue then ClosingKey := KWR_LINE_END_CRLF
    else if Copy(Source, Cursor, 1) = KWR_LINE_END_CR.  StrValue then ClosingKey := KWR_LINE_END_CR
    else if Copy(Source, Cursor, 1) = KWR_LINE_END_LF.  StrValue then ClosingKey := KWR_LINE_END_LF
    else raise EParamsReadException.Create('Impossible case of comment reading.');

end;

procedure TShortCommentRegion.Execute(_Parser: TCustomStringParser; var _Handled: Boolean);
var
  p: Int64;
begin

  with _Parser as TLSNISCParamsReader do begin

    { Перемещаемся сразу на конец комментария, чтобы не бежать туда циклом. Этот Pos найдет его быстрее. }
    p := Min(Pos(CR, Source, Cursor), Pos(LF, Source, Cursor));
    if p = 0 then Move(SrcLen - Cursor + 1)
    else Move(p - Cursor);

    { Считываем, потому что уже можем. Так меньше лишней нагрузки, поскольку CanClose уже просто True. }
    DetermineClosingKey(_Parser);
    AddComment(ReadComment, OpeningKey.StrValue, ClosingKey.StrValue, True);

  end;

  inherited Execute(_Parser, _Handled);
  _Handled := True;

end;

procedure TShortCommentRegion.CheckUnterminated;
begin
end;

{ TKeyWordHelper }

constructor TKeyWordHelper.Create(_KeyType: TKeyType; const _StrValue: String);
begin
  Create(Integer(_KeyType), _StrValue);
end;

function TKeyWordHelper.GetKeyType: TKeyType;
begin
  Result := TKeyType(KeyTypeInternal)
end;

procedure TKeyWordHelper.SetKeyType(const _Value: TKeyType);
begin
  if Integer(_Value) <> KeyTypeInternal then
    KeyTypeInternal := Integer(_Value)
end;

function TKeyWordHelper.TypeInSet(const _Set: TKeyTypes): Boolean;
begin
  Result := KeyType in _Set;
end;

end.
