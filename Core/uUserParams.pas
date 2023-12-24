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

{ TODO 2 -oVasilyevSM -cTuUserParams: Уборка. Господи, как теперь убираться - ваще хз. Надо uses чистить... }
{ TODO 3 -oVasilyevSM -cTuUserParams: Есть еще один кейс - пустой файл только с комментариями }
{ TODO 5 -oVasilyevSM -cTUserFormatParams: Нужны параметры, хранящие исходное форматирование. Всю строку между
  элементами запоминать в объект и потом выбрасывать в обратно строку в исходном виде, что бы там ни было. }

interface

uses
  { VCL }
  Generics.Collections, SysUtils,
  { Liber Synth }
  uConsts, uTypes, uDataUtils, uStrUtils, uParams;

type

  TCommentAnchor = (

      caBeforeParam, caBeforeName, caAfterName, caBeforeType, caAfterType,
      caBeforeValue, caAfterValue, caAfterParam, caInsideEmptyParams

  );

  TUserParam = class(TParam)

  public

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
      procedure GetMargins(_SingleString: Boolean; var _Opening, _Closing: String);

    end;

    TCommentList = class(TList<TComment>)

    strict private

    type

      TOffsetInfoReply = record

        LeftOffset: String;
        RightOffset: String;

        procedure Get(var _LeftOffset, _RightOffset: String);

      end;

    strict private

      function Filter(_Anchor: TCommentAnchor): TCommentList;
      procedure ProcessOffsets(

          var _Value: String;
          _Anchor: TCommentAnchor;
          _SingleString: Boolean;
          _FirstParam: Boolean;
          _LastParam: Boolean;
          _Nested: Boolean

      );

    public

      procedure AddComment(

          const _Text: String;
          const _Opening: String;
          const _Closing: String;
          _Anchor: TCommentAnchor;
          _Short: Boolean

      );
      function GetBlock(_Anchor: TCommentAnchor; _SingleString, _FirstParam, _LastParam, _Nested: Boolean): String;

      function LastIsShort: Boolean; overload;
      function FirstIsShort(_Anchor: TCommentAnchor): Boolean;
      function LastIsShort(_Anchor: TCommentAnchor): Boolean; overload;

    end;

  strict private

    FComments: TCommentList;

  protected

    constructor Create(const _Name: String; const _PathSeparator: Char = '.'); override;

    procedure AssignValue(_Source: TParam; _Host: TParams; _ForceAdding: Boolean); override;

  public

    property Comments: TCommentList read FComments;

    destructor Destroy; override;

  end;

  { Этот класс НЕ никому должен: уметь быстро обрабатывать большие хранилища. Если формат LSNI используется как
    мини-база, не нужно там держать комментарии никому. }
  TUserParams = class(TParams)

  protected

    function ParamClass: TParamClass; override;
    function FormatParam(_Param: TParam; _Value: String; _FirstParam, _LastParam: Boolean): String; override;

  end;

implementation

function CommentAnchorToStr(Value: TCommentAnchor): String;
const

  {$IFDEF FORMATCOMMENTDEBUG}
  SA_StringValues: array[TCommentAnchor] of String = (

      { caBeforeParam       } 'BP',
      { caBeforeName        } 'BN',
      { caAfterName         } 'AN',
      { caBeforeType        } 'BT',
      { caAfterType         } 'AT',
      { caBeforeValue       } 'BV',
      { caAfterValue        } 'AV',
      { caAfterParam        } 'AP',
      { caInsideEmptyParams } 'IP'

  );
  {$ELSE}
  SA_StringValues: array[TCommentAnchor] of String = (

      { caBeforeParam       } 'BeforeParam',
      { caBeforeName        } 'BeforeName',
      { caAfterName         } 'AfterName',
      { caBeforeType        } 'BeforeType',
      { caAfterType         } 'AfterType',
      { caBeforeValue       } 'BeforeValue',
      { caAfterValue        } 'AfterValue',
      { caAfterParam        } 'AfterParam',
      { caInsideEmptyParams } 'InsideEmptyParams'

  );
  {$ENDIF}

begin
  Result := SA_StringValues[Value];
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

procedure TUserParam.TComment.GetMargins(_SingleString: Boolean; var _Opening, _Closing: String);
begin

  if Short and _SingleString then begin

    _Opening := '(*';
    _Closing := '*)';

  end else begin

    _Opening := Opening;
    if Short then _Closing := CRLF
    else _Closing := Closing;

  end;

end;

{ TUserParam.TCommentList }

procedure TUserParam.TCommentList.AddComment;
begin
  inherited Add(TComment.Create(_Text, _Opening, _Closing, _Anchor, _Short));
end;

function TUserParam.TCommentList.GetBlock(_Anchor: TCommentAnchor; _SingleString, _FirstParam, _LastParam, _Nested: Boolean): String;
const

  LongSplitter = {$IFDEF FORMATCOMMENTDEBUG}'#'{$ELSE}' '{$ENDIF};

var
  Comment: TComment;
  Splitter: String;

  function _GetValue(_Short: Boolean): String;
  var
    LeftMargin, RightMargin, RightField: String;
  begin

    with Comment do begin

      GetMargins(_SingleString, LeftMargin, RightMargin);

      { Разделитель комментариев в блоке }
      if _Short and not _SingleString then Splitter := ''
      else Splitter := LongSplitter;

      { "Поля" вокруг текста одного комментария внутри его границ. }
      if _Short and not _SingleString then RightField := ''
      else RightField := ' ';

      Result := Format('%s %s%s%s%s', [

          LeftMargin,
          {$IFDEF FORMATCOMMENTDEBUG}CommentAnchorToStr(_Anchor) + ':' + {$ENDIF}Text,
          RightField,
          RightMargin,
          Splitter

      ]);

    end;

  end;

var
  Search: TUserParam.TCommentList;
begin

  { TODO 5 -oVasilyevSM -cFormatParam: В режиме Untyped комментарии типа должны складываться в BeforeValue. }

  Result        := '';
  Splitter      := '';

  Search := Filter(_Anchor);
  try

    for Comment in Search do
      with Comment do
        Result := Result + _GetValue(Short);

  finally
    Search.Free;
  end;

  { Как раз последний разделитель значений нужно отрезать, неважно, какие были в цикле. }
  CutStr(Result, Length(Splitter));
  { Отступы справа и слева всего блока комментариев }
  ProcessOffsets(Result, _Anchor, _SingleString, _FirstParam, _LastParam, _Nested);

end;

function TUserParam.TCommentList.LastIsShort(_Anchor: TCommentAnchor): Boolean;
begin

  with Filter(_Anchor) do

    try

      Result := (Count > 0) and Last.Short;

    finally
      Free;
    end;

end;

function TUserParam.TCommentList.LastIsShort: Boolean;
begin
  Result := (Count > 0) and Last.Short;
end;

{ TUserParam.TCommentList.TOffsetInfoReply }

procedure TUserParam.TCommentList.TOffsetInfoReply.Get(var _LeftOffset, _RightOffset: String);
begin
  _LeftOffset  := LeftOffset;
  _RightOffset := RightOffset;
end;

procedure TUserParam.TCommentList.ProcessOffsets;

  function _OffsetInfoKey: Byte;
  begin

    Result :=

        Integer(_Anchor) shl 3 or
        BooleanToInt(_SingleString) shl 2 or
        BooleanToInt(_FirstParam) shl 1 or
        BooleanToInt(_LastParam);

  end;

const

  {$IFDEF FORMATCOMMENTDEBUG}Offset = '_'{$ELSE}Offset = ' '{$ENDIF};

  RA_OffsetSetting: array [0..71] of TOffsetInfoReply = (

    { Anchor              SingleString FirstParam  LastParam }
    { caBeforeParam       False        False       False } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       False        False       True  } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       False        True        False } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       False        True        True  } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       True         False       False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeParam       True         False       True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeParam       True         True        False } (LeftOffset: Offset; RightOffset: Offset),
    { caBeforeParam       True         True        True  } (LeftOffset: Offset; RightOffset: ''    ),

    { caBeforeName        False        False       False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        False        False       True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        False        True        False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        False        True        True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        True         False       False } (LeftOffset: Offset; RightOffset: Offset),
    { caBeforeName        True         False       True  } (LeftOffset: Offset; RightOffset: Offset),
    { caBeforeName        True         True        False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        True         True        True  } (LeftOffset: Offset; RightOffset: Offset),

    { caAfterName         False        False       False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         False        False       True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         False        True        False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         False        True        True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True         False       False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True         False       True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True         True        False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True         True        True  } (LeftOffset: Offset; RightOffset: ''    ),

    { caBeforeType        False        False       False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        False        False       True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        False        True        False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        False        True        True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True         False       False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True         False       True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True         True        False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True         True        True  } (LeftOffset: '';     RightOffset: Offset),

    { caAfterType         False        False       False } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterType         False        False       True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         False        True        False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         False        True        True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True         False       False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True         False       True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True         True        False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True         True        True  } (LeftOffset: Offset; RightOffset: ''    ),

    { caBeforeValue       False        False       False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       False        False       True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       False        True        False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       False        True        True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True         False       False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True         False       True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True         True        False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True         True        True  } (LeftOffset: '';     RightOffset: Offset),

    { caAfterValue        False        False       False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        False        False       True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        False        True        False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        False        True        True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True         False       False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True         False       True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True         True        False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True         True        True  } (LeftOffset: Offset; RightOffset: ''    ),

    { caAfterParam        False        False       False } (LeftOffset: CRLF;   RightOffset: ''    ),
    { caAfterParam        False        False       True  } (LeftOffset: CRLF;   RightOffset: ''    ),
    { caAfterParam        False        True        False } (LeftOffset: CRLF;   RightOffset: ''    ),
    { caAfterParam        False        True        True  } (LeftOffset: CRLF;   RightOffset: ''    ),
    { caAfterParam        True         False       False } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterParam        True         False       True  } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterParam        True         True        False } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterParam        True         True        True  } (LeftOffset: Offset; RightOffset: Offset),

    { caInsideEmptyParams False        False       False } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams False        False       True  } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams False        True        False } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams False        True        True  } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams True         False       False } (LeftOffset: Offset; RightOffset: Offset),
    { caInsideEmptyParams True         False       True  } (LeftOffset: Offset; RightOffset: Offset),
    { caInsideEmptyParams True         True        False } (LeftOffset: Offset; RightOffset: Offset),
    { caInsideEmptyParams True         True        True  } (LeftOffset: Offset; RightOffset: Offset)
    { Anchor              SingleString FirstParam  LastParam }

  );

var
  LeftOffset, RightOffset: String;
begin

  if Length(_Value) > 0 then begin

    RA_OffsetSetting[_OffsetInfoKey].Get(LeftOffset, RightOffset);

    if (_Anchor in [caBeforeParam, caBeforeName]) and not _Nested and (not _SingleString or _FirstParam) then
      LeftOffset := '';

    if not _SingleString then begin

      if FirstIsShort(_Anchor) and not (_Anchor in [caAfterName, caAfterType, caAfterValue, caInsideEmptyParams]) then
        LeftOffset := '';
      if LastIsShort (_Anchor) then RightOffset := '';

    end;

    _Value := LeftOffset + _Value + RightOffset;

  end;

end;

function TUserParam.TCommentList.Filter(_Anchor: TCommentAnchor): TCommentList;
var
  Comment: TComment;
begin

  Result := TUserParam.TCommentList.Create;

  for Comment in Self do
    if Comment.Anchor = _Anchor then
      Result.Add(Comment);

end;

function TUserParam.TCommentList.FirstIsShort(_Anchor: TCommentAnchor): Boolean;
begin

  with Filter(_Anchor) do

    try

      Result := (Count > 0) and First.Short;

    finally
      Free;
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
    Comments.AddRange(TUserParam(_Source).Comments);

end;

{ TUserParam }

function TUserParams.ParamClass: TParamClass;
begin
  Result := TUserParam;
end;

function TUserParams.FormatParam(_Param: TParam; _Value: String; _FirstParam, _LastParam: Boolean): String;
const

  SC_VALUE_TYPED   = '%5:s%6:s%0:s%7:s: %8:s%1:s%9:s%3:s= %10:s%2:s%11:s%4:s%12:s';
  SC_VALUE_UNTYPED = '%5:s%6:s%0:s%7:s%3:s= %10:s%2:s%11:s%4:s%12:s';

var
  Typed, SingleString: Boolean;
  BeforeParam, BeforeName, AfterName, BeforeType, AfterType, BeforeValue, AfterValue, AfterParam, InsideEmptyParams: String;

  function _BeforeAssigningSpace: String;
  var
    L: Integer;
  begin

    { Если перед '=' был короткий комментарий, то это '=' оказывается на следующей строке. Поэтому только в этом случае
      перед '=' пробел не нужен. И это два варианта, для выгрузки с типами - после типа, без типов - после имени. }
    if Typed then begin

      L := Length(AfterType);
      if (L >= 2) and (Copy(AfterType, L - 1, 2) = CRLF) then Result := ''
      else Result := ' ';

    end else begin

      L := Length(AfterName);
      if (L >= 2) and (Copy(AfterName, L - 1, 2) = CRLF) then Result := ''
      else Result := ' ';

    end;

  end;

  procedure _FormatParams(_LastIsShort: Boolean);
  begin

    if Length(_Value) = 0 then begin

      if SingleString then _Value := Format('(%s)', [InsideEmptyParams])
      else _Value := Format('(%s)', [ShiftText(InsideEmptyParams, 1)])

    end else

      if SingleString then _Value := Format('(%s)', [_Value])
      else if _LastIsShort then _Value := Format('(%s)', [CRLF + ShiftText(_Value, 1)])
      else _Value := Format('(%s)', [CRLF + ShiftText(_Value, 1) + CRLF]);

  end;

  function _CheckLastCRLF: Boolean;
  var
    L: Integer;
  begin
    { Это совсем подбор, конечно, но оно за гранью всей логики. В том месте, где должна заканчиваться строка просто
      может быть уже есть CRLF от короткого комментария. Это и проверяем, чтобы пустая строка не добавилась лишняя. }
    L := Length(AfterValue);
    Result := (L > 1) and ((Copy(AfterValue, L - 1, 2) = CRLF) or _LastParam);
  end;

var
  ParamFormat, Splitter: String;
begin

  Typed        := not (soTypesFree in SaveToStringOptions);
  SingleString := soSingleString in SaveToStringOptions;

  if Typed then ParamFormat := SC_VALUE_TYPED
  else ParamFormat := SC_VALUE_UNTYPED;

  with _Param as TUserParam do begin

    BeforeParam       := Comments.GetBlock(caBeforeParam,       SingleString, _FirstParam, _LastParam, Nested);
    BeforeName        := Comments.GetBlock(caBeforeName,        SingleString, _FirstParam, _LastParam, Nested);
    AfterName         := Comments.GetBlock(caAfterName,         SingleString, _FirstParam, _LastParam, Nested);
    BeforeType        := Comments.GetBlock(caBeforeType,        SingleString, _FirstParam, _LastParam, Nested);
    AfterType         := Comments.GetBlock(caAfterType,         SingleString, _FirstParam, _LastParam, Nested);
    BeforeValue       := Comments.GetBlock(caBeforeValue,       SingleString, _FirstParam, _LastParam, Nested);
    AfterValue        := Comments.GetBlock(caAfterValue,        SingleString, _FirstParam, _LastParam, Nested);
    AfterParam        := Comments.GetBlock(caAfterParam,        SingleString, _FirstParam, _LastParam, Nested);
    InsideEmptyParams := Comments.GetBlock(caInsideEmptyParams, SingleString, _FirstParam, _LastParam, Nested);

    if _Param.DataType = dtParams then
      _FormatParams(Comments.LastIsShort);

    if _CheckLastCRLF then Splitter := ''
    else if SingleString then Splitter := ';'
    else Splitter := CRLF;

    Result := Format(ParamFormat, [

        {  0 } Name,
        {  1 } ParamDataTypeToStr(DataType),
        {  2 } _Value,
        {  3 } _BeforeAssigningSpace,
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

end;

end.
