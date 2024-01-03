unit uLSNIDCStringParamsCompiler;

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

{ TODO 1 -oVasilyevSM -cuLSNIDCStringParamsCompiler: Уборка }

interface

uses
  { VCL }
  SysUtils,
  { LiberSynth }
  uLSNIStringParamsCompiler, uConsts, uParams, uUserParams, uStrUtils, uDataUtils;

type

  TLSNIDCStringParamsCompiler = class(TLSNIStringParamsCompiler)

  strict private

    FTyped: Boolean;
    FSingleString: Boolean;

    function CheckLastCRLF(const _Value: String): Boolean;
    function FormatParamsValue(const _Value, _InsideEmptyParams: String; _SingleString, _LastIsShort: Boolean): String;
    property Typed: Boolean read FTyped write FTyped;
    property SingleString: Boolean read FSingleString write FSingleString;

  protected

    procedure Prepare; override;
    function FormatParam(_Param: TParam; _First, _Last: Boolean): String; override;

  end;

implementation

type

  TOffsetInfoReply = record

    LeftOffset: String;
    RightOffset: String;

    procedure Get(var _LeftOffset, _RightOffset: String);

  end;

  TCommentListHelper = class helper for TCommentList

  private

    function TypedAnchors(_Typed: Boolean; _Anchor: TCommentAnchor): TCommentAnchors;
    function Filter(_Anchors: TCommentAnchors): TCommentList;
    function FirstIsShort(_Typed: Boolean; _Anchor: TCommentAnchor): Boolean;
    function LastIsShort: Boolean; overload;
    function LastIsShort(_Typed: Boolean; _Anchor: TCommentAnchor): Boolean; overload;

    procedure ProcessOffsets(

        var _Value: String;
        _Anchor: TCommentAnchor;
        _Typed: Boolean;
        _SingleString: Boolean;
        _FirstParam: Boolean;
        _LastParam: Boolean;
        _Nested: Boolean

    );
    function GetBlock(

        _Anchor: TCommentAnchor;
        _Typed: Boolean;
        _SingleString: Boolean;
        _FirstParam: Boolean;
        _LastParam: Boolean;
        _Nested: Boolean

    ): String;

  end;

{ TLSNIDCStringParamsCompiler }

procedure TLSNIDCStringParamsCompiler.Prepare;
const

  SC_VALUE_TYPED   = '%5:s%6:s%0:s%7:s: %8:s%1:s%9:s%3:s= %10:s%2:s%11:s%4:s%12:s';
  SC_VALUE_UNTYPED = '%5:s%6:s%0:s%7:s%3:s= %10:s%2:s%11:s%4:s%12:s';

begin

  Typed        := not (soTypesFree in Options);
  SingleString := soSingleString in Options;

  if Typed then ParamFormat := SC_VALUE_TYPED
  else ParamFormat := SC_VALUE_UNTYPED;

  if SingleString then ParamSplitter := '; '
  else ParamSplitter := CRLF;

end;

function TLSNIDCStringParamsCompiler.CheckLastCRLF(const _Value: String): Boolean;
var
  L: Integer;
begin
  { Это совсем подбор, конечно, но оно за гранью всей логики. В том месте, где должна заканчиваться строка просто
    может быть уже есть CRLF от короткого комментария. Это и проверяем, чтобы пустая строка не добавилась лишняя. }
  L := Length(_Value);
  Result := (L > 1) and (Copy(_Value, L - 1, 2) = CRLF);
end;

function TLSNIDCStringParamsCompiler.FormatParamsValue(const _Value, _InsideEmptyParams: String; _SingleString, _LastIsShort: Boolean): String;
begin

  Result := _Value;

  if Length(Result) = 0 then begin

    if _SingleString then Result := Format('(%s)', [_InsideEmptyParams])
    else Result := Format('(%s)', [ShiftText(_InsideEmptyParams, 1)])

  end else

    if _SingleString then Result := Format('(%s)', [Result])
    else if CheckLastCRLF(Result) then Result := Format('(%s)', [CRLF + ShiftText(Result, 1)])
    else Result := Format('(%s)', [CRLF + ShiftText(Result, 1) + CRLF]);

end;

function TLSNIDCStringParamsCompiler.FormatParam(_Param: TParam; _First, _Last: Boolean): String;
var
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

begin

  with _Param as TUserParam do begin

    BeforeParam       := Comments.GetBlock(caBeforeParam,       Typed, SingleString, _First, _Last, Nested);
    BeforeName        := Comments.GetBlock(caBeforeName,        Typed, SingleString, _First, _Last, Nested);
    AfterName         := Comments.GetBlock(caAfterName,         Typed, SingleString, _First, _Last, Nested);
    BeforeType        := Comments.GetBlock(caBeforeType,        Typed, SingleString, _First, _Last, Nested);
    AfterType         := Comments.GetBlock(caAfterType,         Typed, SingleString, _First, _Last, Nested);
    BeforeValue       := Comments.GetBlock(caBeforeValue,       Typed, SingleString, _First, _Last, Nested);
    AfterValue        := Comments.GetBlock(caAfterValue,        Typed, SingleString, _First, _Last, Nested);
    AfterParam        := Comments.GetBlock(caAfterParam,        Typed, SingleString, _First, _Last, Nested);
    InsideEmptyParams := Comments.GetBlock(caInsideEmptyParams, Typed, SingleString, _First, _Last, Nested);

    case _Param.DataType of

      dtAnsiString: Result := FormatStringValue(_Param.AsString);
      dtString:     Result := FormatStringValue(_Param.AsString);
      dtParams:     Result := FormatParamsValue(CompileNestedParams(_Param.AsParams), InsideEmptyParams, SingleString, Comments.LastIsShort);

    else
      Result := _Param.AsString;
    end;

    if CheckLastCRLF(AfterValue) then ParamSplitter := '';

    Result := Format(ParamFormat, [

        {  0 } _Param.Name,
        {  1 } ParamDataTypeToStr(_Param.DataType),
        {  2 } Result,
        {  3 } _BeforeAssigningSpace,
        {  4 } ParamSplitter,
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

{ TLSNIDCStringParamsCompiler.TOffsetInfoReply }

procedure TOffsetInfoReply.Get(var _LeftOffset, _RightOffset: String);
begin
  _LeftOffset  := LeftOffset;
  _RightOffset := RightOffset;
end;

{ TCommentListHelper }

function TCommentListHelper.TypedAnchors(_Typed: Boolean; _Anchor: TCommentAnchor): TCommentAnchors;
begin

  if _Typed then Result := [_Anchor]
  else if _Anchor = caAfterName then Result := [caAfterName, caBeforeType, caAfterType]
  else if _Anchor in [caBeforeType, caAfterType] then Result := []
  else Result := [_Anchor];

end;

function TCommentListHelper.Filter(_Anchors: TCommentAnchors): TCommentList;
var
  Comment: TComment;
begin

  Result := TCommentList.Create;

  for Comment in Self do
    if Comment.Anchor in _Anchors then
      Result.Add(Comment);

end;

function TCommentListHelper.FirstIsShort(_Typed: Boolean; _Anchor: TCommentAnchor): Boolean;
begin

  with Filter(TypedAnchors(_Typed, _Anchor)) do

    try

      Result := (Count > 0) and First.Short;

    finally
      Free;
    end;

end;

function TCommentListHelper.LastIsShort: Boolean;
begin
  Result := (Count > 0) and Last.Short;
end;

function TCommentListHelper.LastIsShort(_Typed: Boolean; _Anchor: TCommentAnchor): Boolean;
begin

  with Filter(TypedAnchors(_Typed, _Anchor)) do

    try

      Result := (Count > 0) and Last.Short;

    finally
      Free;
    end;

end;

procedure TCommentListHelper.ProcessOffsets;

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
    { caAfterParam        False        False       True  } (LeftOffset: '';     RightOffset: ''    ),
    { caAfterParam        False        True        False } (LeftOffset: CRLF;   RightOffset: ''    ),
    { caAfterParam        False        True        True  } (LeftOffset: '';     RightOffset: ''    ),
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

  { TODO 1 -oVasilyevSM -cuUserParams: Карта требует расширения. }
  if Length(_Value) > 0 then begin

    RA_OffsetSetting[_OffsetInfoKey].Get(LeftOffset, RightOffset);

    if (_Anchor in [caBeforeParam, caBeforeName]) and not _Nested and (not _SingleString or _FirstParam) then
      LeftOffset := '';

    if not _SingleString then begin

      if FirstIsShort(_Typed, _Anchor) and not (_Anchor in [caAfterName, caAfterType, caAfterValue, caInsideEmptyParams]) then
        LeftOffset := '';
      if LastIsShort(_Typed, _Anchor) then
        RightOffset := '';

    end;

    _Value := LeftOffset + _Value + RightOffset;

  end;

end;

function TCommentListHelper.GetBlock(_Anchor: TCommentAnchor; _Typed, _SingleString, _FirstParam, _LastParam, _Nested: Boolean): String;
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
  Search: TCommentList;
  Anchors: TCommentAnchors;
begin

  Result   := '';
  Splitter := '';

  { В режиме без типа комментарии типа складываются в AfterName. }
  Anchors := TypedAnchors(_Typed, _Anchor);
  if Anchors <> [] then begin

    Search := Filter(Anchors);
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
    ProcessOffsets(Result, _Anchor, _Typed, _SingleString, _FirstParam, _LastParam, _Nested);

  end;

end;

end.
