unit uUserParams;

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

{ TODO 3 -oVasilyevSM -cTuUserParams: Есть еще один кейс - пустой файл только с комментариями }
{ TODO 5 -oVasilyevSM -cTUserFormatParams: Нужны параметры, хранящие исходное форматирование. Всю строку между элементами
  запоминать там и потом выбрасывать в строку. }

{

TLSIni.StoreFormat -> LSNI format    ( reading location support yes/no )
                   -> Classic format ( reading location support yes/no )
                   -> BLOB

TLSIni.Destination -> File
                   -> Abstract (saving and loading implement by event)

TLSReg -> Registry (without format / single BLOB)

}

interface

uses
  { VCL }
  Generics.Collections, SysUtils,
  { Liber Synth }
  uConsts, uTypes, uDataUtils, uStrUtils, uParams, uCustomStringParser, uParamsStringParser;

type

  TKeyType = ( { inherits from uParamsStringParser.TKeyType }

      ktNone, ktSourceEnd, ktLineEnd, ktSpace, ktSplitter, ktTypeIdent, ktAssigning, ktStringBorder, ktNestedOpening,
      ktNestedClosing, ktLongCommentOpening, ktLongCommentClosing, ktShortCommentOpening

  );
  TKeyTypes = set of TKeyType;

  TCommentAnchor = (

      caBeforeParam, caBeforeName, caAfterName, caBeforeType, caAfterType,
      caBeforeValue, caAfterValue, caAfterParam, caInsideEmptyParams

  );

  TUserParam = class(TParam)

  private

  type

    TComment = record

      Text: String;
      Opening: String;
      Closing: String;
      Anchor: TCommentAnchor;
      Short: Boolean;

      constructor Create(

        const _Text: String;
        const _Opening: String;
        const _Closing: String;
        _Anchor: TCommentAnchor;
        _Short: Boolean

      );

    end;

    TCommentList = class(TList<TComment>)

    private

      procedure Add(

        const _Value: String;
        const _Opening: String;
        const _Closing: String;
        _Anchor: TCommentAnchor;
        _Short: Boolean

      );
      function Get(_Anchor: TCommentAnchor; _SingleString, _Typed: Boolean): String;

    end;

  strict private

    FComments: TCommentList;

  private

    property Comments: TCommentList read FComments;

  protected

    constructor Create(const _Name: String; const _PathSeparator: Char = '.'); override;

    procedure AssignValue(_Source: TParam; _Host: TParams; _ForceAdding: Boolean); override;

  public

    destructor Destroy; override;

  end;

  { Этот класс НЕ никому должен: уметь быстро обрабатывать большие хранилища. Если формат LSNI используется как
    мини-база, не нужно там держать комментарии никому. }
  TUserParams = class(TParams)

  protected

    function ParamClass: TParamClass; override;
    function ParamsReaderClass: TParamsReaderClass; override;
    function FormatParam(_Param: TParam; _Value: String; _First, _Last: Boolean): String; override;

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

  TUserParamsReader = class(TParamsReader)

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
    procedure BeforeReadParam(_Param: TParam); override;
    procedure AfterReadParam(_Param: TParam); override;
    procedure AfterReadParams(_Param: TParam); override;

    property CurrentParam: TUserParam read FCurrentParam write FCurrentParam;
    property CurrentComments: TUserParam.TCommentList read FCurrentComments;
    property CommentTerminatedValue: Boolean read FCommentTerminatedValue write FCommentTerminatedValue;

  protected

    procedure InitParser; override;

  public

    destructor Destroy; override;

    function ReadElement(_Trim: Boolean): String; override;
    procedure ElementTerminated(_KeyWord: TKeyWord); override;

  end;

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

{ TUserParam.TComment }

constructor TUserParam.TComment.Create;
begin

  Text    := _Text;
  Opening := _Opening;
  Closing := _Closing;
  Anchor  := _Anchor;
  Short   := _Short;
  
end;

{ TUserParam.TCommentList }

procedure TUserParam.TCommentList.Add;
begin
  inherited Add(TComment.Create(_Value, _Opening, _Closing, _Anchor, _Short));
end;

function TUserParam.TCommentList.Get(_Anchor: TCommentAnchor; _SingleString, _Typed: Boolean): String;
var
  Comment: TComment;
  Value: String;
  Splitter: String;
  Index: Word;
begin

  Result := '';
  Splitter := ' ';
  Index := 0;

  { TODO 3 -oVasilyevSM -cFormatParam: Нужен метод Search(StartAt, Anchor). Или привычно, Find(Anchor, var Comment):
    Boolean, которым можно пробежать по списку с учетом признака Anchor. Будет удобнее здесь орудовать. Цикл может быть
    какой-нибудь while и тогда еще можно будет First и Last контролировать.

    Нужно избавиться от смены порядка Value + Splitter / Splitter + Value. Постараться управлять начальным и конечным
    разделителем после обработки цикла.

    Splitter сбрасывается один раз, в Short SingleString. И там он, получается, играет роль отступа. Именно поэтому там
    не меняется порядок Splitter + Value, причем, он обратный. Следовательно, в остальных обработках он играет двойную
    роль, разделителя и отступа одновременно. В этом-то вся и проблема. Трудно форматировать по шаблону снаружи, не
    зная, что вернется изнутри. Должен быть отдельный Offset и добавляться перед перед циклом всегда и после цикла
    только в режиме SingleString. А сплиттер - только в конце и в не SingleString - кроме последнего. В режиме
    MultiString Short просто использовать Closing для отделения кмментариев друг от друга. Похоже, придется в
    некоторых случаях делать Cut после цикла, чтобы сбросить последний сплиттер. *** - и тогда Search не нужен, а только
    функция GetAll(Anchor), которая вернет их правильно разделенными без указания отсюда. Сама разберется, Short - нет,
    Long - да. А здесь только Offset в конце надо умно добавить и то не факт. Возможно, это дело функции Format.

    И есть еще одно. В режиме Untyped комментарии типа должны складываться в BeforeValue... }

    { TODO 3 -oVasilyevSM -cFormatParam: После значения иногда добавляет лишний CRLF в короткий комментарий:
      = 'asd' -- 13.1

      -- 13.2
    }
  if _SingleString then

    for Comment in Self do
      with Comment do
        if Anchor = _Anchor then

          if Short then begin

            { Short SingleString }

            Value := '(* ' + Text + ' *)';

            if _Anchor in [caAfterName, caAfterType, caAfterValue] then Result := Result + Splitter + Value
            else Result := Result + Value + Splitter;

          end else begin

            { Long SingleString }

            Value := Opening + ' ' + Text + ' ' + Closing;

            if _Anchor in [caAfterName, caAfterType, caAfterValue] then Result := Result + Splitter + Value
            else Result := Result + Value + Splitter;

          end

        else

  else

    for Comment in Self do
      with Comment do
        if Anchor = _Anchor then

          if Short then begin

            { Short MultiString }

            if _Anchor in [caAfterParam] then Value := Opening + ' ' + Text
            else Value := Opening + ' ' + Text + Closing;

            if (Index > 0) or (_Anchor in [caBeforeParam, caBeforeType, caAfterParam, caInsideEmptyParams]) then
              Splitter := '';
            Inc(Index);

            Result := Result + Splitter + Value;

          end else begin

            { Long MultiString }

            if _Anchor in [caBeforeParam, caAfterParam, caInsideEmptyParams] then Splitter := CRLF;

            Value := Opening + ' ' + Text + ' ' + Closing;

            if _Anchor in [caAfterName, caAfterType, caAfterValue, caAfterParam] then Result := Result + Splitter + Value
            else Result := Result + Value + Splitter;

          end;

end;

{ TUserParam }

constructor TUserParam.Create(const _Name: String; const _PathSeparator: Char);
begin
  inherited Create(_Name, _PathSeparator);
  FComments := TCommentList.Create;
end;

destructor TUserParam.Destroy;
begin
  FreeAndNil(FComments);
  inherited Destroy;
end;

procedure TUserParam.AssignValue(_Source: TParam; _Host: TParams; _ForceAdding: Boolean);
begin

  inherited AssignValue(_Source, _Host, _ForceAdding);

  Comments.Clear;
  if _Source is TUserParam then
    Comments.AddRange(TUserParam(_Source).Comments.ToArray);

end;

{ TUserParam }

function TUserParams.ParamClass: TParamClass;
begin
  Result := TUserParam;
end;

function TUserParams.ParamsReaderClass: TParamsReaderClass;
begin
  Result := TUserParamsReader;
end;

function TUserParams.FormatParam(_Param: TParam; _Value: String; _First, _Last: Boolean): String;
const

  SC_VALUE_TYPED   = '%5:s%6:s%0:s%7:s: %8:s%1:s%9:s%3:s= %10:s%2:s%11:s%4:s%12:s';
  SC_VALUE_UNTYPED = '%5:s%6:s%0:s%7:s%3:s= %10:s%2:s%11:s%4:s%12:s';

var
  ParamFormat: String;
  BeforeParam, BeforeName, AfterName, BeforeType, AfterType, BeforeValue, AfterValue, AfterParam, InsideEmptyParams: String;
  Splitter, BeforeAssigningSpace: String;
  SingleString, Typed: Boolean;
  L: Integer;
begin

  { TODO 2 -oVasilyevSM -cTUserParams.FormatParam: Ошибка: A: Params = ( B: Integer = 0; C: String = 'asd' ); }

  Typed := not (soTypesFree in SaveToStringOptions);
  SingleString := soSingleString in SaveToStringOptions;

  if Typed then ParamFormat := SC_VALUE_TYPED
  else ParamFormat := SC_VALUE_UNTYPED;

  if SingleString then
    if _Last then Splitter := ' '
    else Splitter := ';'
  else
    if _Last then Splitter := ''
    else Splitter := CRLF;

  with _Param as TUserParam do begin

    BeforeParam       := Comments.Get(caBeforeParam,       SingleString, Typed);
    BeforeName        := Comments.Get(caBeforeName,        SingleString, Typed);
    AfterName         := Comments.Get(caAfterName,         SingleString, Typed);
    BeforeType        := Comments.Get(caBeforeType,        SingleString, Typed);
    AfterType         := Comments.Get(caAfterType,         SingleString, Typed);
    BeforeValue       := Comments.Get(caBeforeValue,       SingleString, Typed);
    AfterValue        := Comments.Get(caAfterValue,        SingleString, Typed);
    AfterParam        := Comments.Get(caAfterParam,        SingleString, Typed);
    InsideEmptyParams := Comments.Get(caInsideEmptyParams, SingleString, Typed);

    { Если перед '=' был короткий комментарий, то это '=' оказывается на следующей строке. Поэтому только в этом случае
      перед '=' пробел не нужен. И это два варианта, для выгрузки с типами - после типа, без типов - после имени. }
    if Typed then begin

      L := Length(AfterType);
      if (L >= 2) and (Copy(AfterType, L - 1, 2) = CRLF) then BeforeAssigningSpace := ''
      else BeforeAssigningSpace := ' ';

    end else begin

      L := Length(AfterName);
      if (L >= 2) and (Copy(AfterName, L - 1, 2) = CRLF) then BeforeAssigningSpace := ''
      else BeforeAssigningSpace := ' ';

    end;

    if DataType = dtParams then begin

      if Length(_Value) = 0 then _Value := InsideEmptyParams
      else if not SingleString then _Value := _Value + CRLF;

      if SingleString then

        if Length(_Value) = 0  then _Value := '()'
        else _Value := Format('( %s)', [_Value])

      else begin

        _Value := Format('(%s%s)', [CRLF, ShiftText(_Value, 1)]);

        L := Length(AfterValue);
        if (L >= 2) and (Copy(AfterValue, L - 1, 2) = CRLF) then
          AfterValue := Copy(AfterValue, 1, L - 2);

      end;

    end;

    Result := Format(ParamFormat, [

        {  0 } Name,
        {  1 } ParamDataTypeToStr(DataType),
        {  2 } _Value,
        {  3 } BeforeAssigningSpace,
        {  4 } Splitter,
        {  5 } BeforeParam,
        {  6 } BeforeName,
        {  7 } AfterName,
        {  8 } BeforeType,
        {  9 } AfterType,
        { 10 } BeforeValue,
        { 11 } AfterValue,
        { 12 } AfterParam

    ]);

  end;

  if SingleString and not _First then
    Result := ' ' + Result;

end;

{ TUserParamsReader }

destructor TUserParamsReader.Destroy;
begin
  FreeAndNil(FCurrentComments);
  inherited Destroy;
end;

function TUserParamsReader.ReadComment: String;
begin
  Result := Trim(Copy(Source, RegionStart, Cursor - RegionStart));
end;

procedure TUserParamsReader.AddComment;
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

  CurrentComments.Add(_Value, _Opening, _Closing, Anchor, _Short);

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
end;

procedure TUserParamsReader.AfterReadParams(_Param: TParam);
var
  i: Integer;
  ParamComments: TUserParam.TCommentList;
begin

  inherited AfterReadParams(_Param);

  ParamComments := (_Param as TUserParam).Comments;

  for i := 0 to CurrentComments.Count - 1 do
    with CurrentComments[i] do
      ParamComments.Add(Text, Opening, Closing, caInsideEmptyParams, Short);

  CurrentComments.Clear;

end;

procedure TUserParamsReader.InitParser;
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

function TUserParamsReader.ReadElement(_Trim: Boolean): String;
begin
  Result := inherited ReadElement(_Trim);
  if CommentTerminatedValue then
    Result := TrimRight(Result);
end;

procedure TUserParamsReader.ElementTerminated(_KeyWord: TKeyWord);
begin

  inherited ElementTerminated(_KeyWord);

  if

      ((ElementType = etName) or (_KeyWord.KeyType = ktSourceEnd)) and
      Assigned(CurrentParam)

  then

    with CurrentParam do begin

      Comments.AddRange(CurrentComments.ToArray);
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

  with _Parser as TUserParamsReader do

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

  with _Parser as TUserParamsReader do begin

    { Перемещаемся сразу на конец комментария, чтобы не бежать туда циклом. Этот Pos найдет его быстрее. }
    p := Pos(ClosingKey.StrValue, Source, Cursor);
    if p = 0 then Move(SrcLen - Cursor + 1)
    else Move(p - Cursor);

    { Считываем, потому что уже можем. Так меньше лишней нагрузки, так как CanClose уже просто True. }
    AddComment(

        ReadComment,
        OpeningKey.StrValue,
        ClosingKey.StrValue,
        False

    );

  end;

  inherited Execute(_Parser, _Handled);
  _Handled := True;

end;

{ TShortCommentRegion }

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

  with _Parser as TUserParamsReader do begin

    { Перемещаемся сразу на конец комментария, чтобы не бежать туда циклом. Этот Pos найдет его быстрее. }
    p := Min(Pos(CR, Source, Cursor), Pos(LF, Source, Cursor));
    if p = 0 then Move(SrcLen - Cursor + 1)
    else Move(p - Cursor);

    { Считываем, потому что уже можем. Так меньше лишней нагрузки, так как CanClose уже просто True. }
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
