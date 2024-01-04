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

function TLSNIDCStringParamsCompiler.CheckLastCRLF(const _Value: String): Boolean;
var
  L: Integer;
begin
  { Ёто совсем подбор, конечно, но оно за гранью всей логики. ¬ том месте, где должна заканчиватьс€ строка просто
    может быть уже есть CRLF от короткого комментари€. Ёто и провер€ем, чтобы пуста€ строка не добавилась лишн€€. }
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

function TLSNIDCStringParamsCompiler.FormatParam(_Param: TParam; _First, _Last: Boolean): String;
var
  BeforeParam, BeforeName, AfterName, BeforeType, AfterType, BeforeValue, AfterValue, AfterParam, InsideEmptyParams: String;

  function _BeforeAssigningSpace: String;
  var
    L: Integer;
  begin

    { ≈сли перед '=' был короткий комментарий, то это '=' оказываетс€ на следующей строке. ѕоэтому только в этом случае
      перед '=' пробел не нужен. » это два варианта, дл€ выгрузки с типами - после типа, без типов - после имени. }
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

var
  Splitter: String;
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

    if CheckLastCRLF(AfterValue) then Splitter := ''
    else Splitter := ParamSplitter;

    Result := Format(ParamFormat, [

        {  0 } _Param.Name,
        {  1 } ParamDataTypeToStr(_Param.DataType),
        {  2 } Result,
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

        Integer(_Anchor)            shl 4 or
        BooleanToInt(_Nested)       shl 3 or
        BooleanToInt(_SingleString) shl 2 or
        BooleanToInt(_FirstParam)   shl 1 or
        BooleanToInt(_LastParam);

  end;

const

  {$IFDEF FORMATCOMMENTDEBUG}Offset = '_'{$ELSE}Offset = ' '{$ENDIF};

  RA_OffsetSetting: array [0..143] of TOffsetInfoReply = (

    { Anchor              Nested         SingleString   FirstParam     LastParam         LeftOffset          RightOffset        }
    { caBeforeParam       False          False          False          False          } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       False          False          False          True           } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       False          False          True           False          } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       False          False          True           True           } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       False          True           False          False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeParam       False          True           False          True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeParam       False          True           True           False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeParam       False          True           True           True           } (LeftOffset: '';     RightOffset: ''    ),
    { caBeforeParam       True           False          False          False          } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       True           False          False          True           } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       True           False          True           False          } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       True           False          True           True           } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       True           True           False          False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeParam       True           True           False          True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeParam       True           True           True           False          } (LeftOffset: Offset; RightOffset: Offset),
    { caBeforeParam       True           True           True           True           } (LeftOffset: Offset; RightOffset: ''    ),
    { Anchor              Nested         SingleString   FirstParam     LastParam         LeftOffset          RightOffset        }
    { caBeforeName        False          False          False          False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        False          False          False          True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        False          False          True           False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        False          False          True           True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        False          True           False          False          } (LeftOffset: Offset; RightOffset: Offset),
    { caBeforeName        False          True           False          True           } (LeftOffset: Offset; RightOffset: Offset),
    { caBeforeName        False          True           True           False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        False          True           True           True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        True           False          False          False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        True           False          False          True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        True           False          True           False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        True           False          True           True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        True           True           False          False          } (LeftOffset: Offset; RightOffset: Offset),
    { caBeforeName        True           True           False          True           } (LeftOffset: Offset; RightOffset: Offset),
    { caBeforeName        True           True           True           False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        True           True           True           True           } (LeftOffset: Offset; RightOffset: Offset),
    { Anchor              Nested         SingleString   FirstParam     LastParam         LeftOffset          RightOffset        }
    { caAfterName         False          False          False          False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         False          False          False          True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         False          False          True           False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         False          False          True           True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         False          True           False          False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         False          True           False          True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         False          True           True           False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         False          True           True           True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True           False          False          False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True           False          False          True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True           False          True           False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True           False          True           True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True           True           False          False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True           True           False          True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True           True           True           False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True           True           True           True           } (LeftOffset: Offset; RightOffset: ''    ),
    { Anchor              Nested         SingleString   FirstParam     LastParam         LeftOffset          RightOffset        }
    { caBeforeType        False          False          False          False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        False          False          False          True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        False          False          True           False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        False          False          True           True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        False          True           False          False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        False          True           False          True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        False          True           True           False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        False          True           True           True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True           False          False          False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True           False          False          True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True           False          True           False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True           False          True           True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True           True           False          False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True           True           False          True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True           True           True           False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True           True           True           True           } (LeftOffset: '';     RightOffset: Offset),
    { Anchor              Nested         SingleString   FirstParam     LastParam         LeftOffset          RightOffset        }
    { caAfterType         False          False          False          False          } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterType         False          False          False          True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         False          False          True           False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         False          False          True           True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         False          True           False          False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         False          True           False          True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         False          True           True           False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         False          True           True           True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True           False          False          False          } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterType         True           False          False          True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True           False          True           False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True           False          True           True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True           True           False          False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True           True           False          True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True           True           True           False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True           True           True           True           } (LeftOffset: Offset; RightOffset: ''    ),
    { Anchor              Nested         SingleString   FirstParam     LastParam         LeftOffset          RightOffset        }
    { caBeforeValue       False          False          False          False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       False          False          False          True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       False          False          True           False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       False          False          True           True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       False          True           False          False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       False          True           False          True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       False          True           True           False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       False          True           True           True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True           False          False          False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True           False          False          True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True           False          True           False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True           False          True           True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True           True           False          False          } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True           True           False          True           } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True           True           True           False          } (LeftOffset: '';     RightOffset: Offset),
    { Anchor              Nested         SingleString   FirstParam     LastParam         LeftOffset          RightOffset        }
    { caBeforeValue       True           True           True           True           } (LeftOffset: '';     RightOffset: Offset),
    { caAfterValue        False          False          False          False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        False          False          False          True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        False          False          True           False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        False          False          True           True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        False          True           False          False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        False          True           False          True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        False          True           True           False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        False          True           True           True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True           False          False          False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True           False          False          True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True           False          True           False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True           False          True           True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True           True           False          False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True           True           False          True           } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True           True           True           False          } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True           True           True           True           } (LeftOffset: Offset; RightOffset: ''    ),
    { Anchor              Nested         SingleString   FirstParam     LastParam         LeftOffset          RightOffset        }
    { caAfterParam        False          False          False          False          } (LeftOffset: CRLF;   RightOffset: ''    ),
    { caAfterParam        False          False          False          True           } (LeftOffset: '';     RightOffset: ''    ),
    { caAfterParam        False          False          True           False          } (LeftOffset: CRLF;   RightOffset: ''    ),
    { caAfterParam        False          False          True           True           } (LeftOffset: '';     RightOffset: ''    ),
    { caAfterParam        False          True           False          False          } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterParam        False          True           False          True           } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterParam        False          True           True           False          } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterParam        False          True           True           True           } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterParam        True           False          False          False          } (LeftOffset: CRLF;   RightOffset: ''    ),
    { caAfterParam        True           False          False          True           } (LeftOffset: '';     RightOffset: ''    ),
    { caAfterParam        True           False          True           False          } (LeftOffset: CRLF;   RightOffset: ''    ),
    { caAfterParam        True           False          True           True           } (LeftOffset: '';     RightOffset: ''    ),
    { caAfterParam        True           True           False          False          } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterParam        True           True           False          True           } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterParam        True           True           True           False          } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterParam        True           True           True           True           } (LeftOffset: Offset; RightOffset: Offset),
    { Anchor              Nested         SingleString   FirstParam     LastParam         LeftOffset          RightOffset        }
    { caInsideEmptyParams False          False          False          False          } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams False          False          False          True           } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams False          False          True           False          } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams False          False          True           True           } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams False          True           False          False          } (LeftOffset: Offset; RightOffset: Offset),
    { caInsideEmptyParams False          True           False          True           } (LeftOffset: Offset; RightOffset: Offset),
    { caInsideEmptyParams False          True           True           False          } (LeftOffset: Offset; RightOffset: Offset),
    { caInsideEmptyParams False          True           True           True           } (LeftOffset: Offset; RightOffset: Offset),
    { caInsideEmptyParams True           False          False          False          } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams True           False          False          True           } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams True           False          True           False          } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams True           False          True           True           } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams True           True           False          False          } (LeftOffset: Offset; RightOffset: Offset),
    { caInsideEmptyParams True           True           False          True           } (LeftOffset: Offset; RightOffset: Offset),
    { caInsideEmptyParams True           True           True           False          } (LeftOffset: Offset; RightOffset: Offset),
    { caInsideEmptyParams True           True           True           True           } (LeftOffset: Offset; RightOffset: Offset)
    { Anchor              Nested         SingleString   FirstParam     LastParam      }

  );

var
  LeftOffset, RightOffset: String;
begin

  if Length(_Value) > 0 then begin

    RA_OffsetSetting[_OffsetInfoKey].Get(LeftOffset, RightOffset);

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

      { –азделитель комментариев в блоке }
      if _Short and not _SingleString then Splitter := ''
      else Splitter := LongSplitter;

      { "ѕол€" вокруг текста одного комментари€ внутри его границ. }
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

  { ¬ режиме без типа комментарии типа складываютс€ в AfterName. }
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

    {  ак раз последний разделитель значений нужно отрезать, неважно, какие были в цикле. }
    CutStr(Result, Length(Splitter));
    { ќтступы справа и слева всего блока комментариев }
    ProcessOffsets(Result, _Anchor, _Typed, _SingleString, _FirstParam, _LastParam, _Nested);

  end;

end;

end.
