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

{ TODO 2 -oVasilyevSM -cTuUserParams: Уборка }
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
          _First: Boolean;
          _Last: Boolean;
          _LastShort: Boolean;
          _Nested: Boolean

      );

    private

      procedure AddComment(

          const _Value: String;
          const _Opening: String;
          const _Closing: String;
          _Anchor: TCommentAnchor;
          _Short: Boolean

      );
      function GetBlock(_Anchor: TCommentAnchor; _SingleString, _First, _Last, _Nested: Boolean): String;

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
    function FormatParam1(_Param: TParam; _Value: String; _First, _Last: Boolean): String;

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
    procedure DetachBeforeParam;
    procedure SaveTail;
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

    procedure KeyEvent(const _KeyWord: TKeyWord); override;
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

function CommentAnchorToStr(Value: TCommentAnchor): String;
const

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

//  SA_StringValues: array[TCommentAnchor] of String = (
//
//      { caBeforeParam       } 'BeforeParam',
//      { caBeforeName        } 'BeforeName',
//      { caAfterName         } 'AfterName',
//      { caBeforeType        } 'BeforeType',
//      { caAfterType         } 'AfterType',
//      { caBeforeValue       } 'BeforeValue',
//      { caAfterValue        } 'AfterValue',
//      { caAfterParam        } 'AfterParam',
//      { caInsideEmptyParams } 'InsideEmptyParams'
//
//  );
//
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

{ TUserParam.TCommentList }

procedure TUserParam.TCommentList.AddComment;
begin
  inherited Add(TComment.Create(_Value, _Opening, _Closing, _Anchor, _Short));
end;

function TUserParam.TCommentList.GetBlock(_Anchor: TCommentAnchor; _SingleString, _First, _Last, _Nested: Boolean): String;
const

  LongSplitter = {$IFDEF FORMATCOMMENTDEBUG}'#'{$ELSE}' '{$ENDIF};

var
  Comment: TComment;
  Splitter: String;

  function _GetValue(_Short: Boolean): String;
  var
    Opn, Cls, RightField: String;
  begin

    with Comment do begin

      { TODO -oVasilyevSM -cuUserParams: Метод TComment.Get(var L, R), а потом только корректировать L и R. }
      if _Short and _SingleString then Opn := '(*'
      else Opn := Opening;

      if _Short then
        if _SingleString then Cls := '*)'
        else Cls := CRLF
      else Cls := Closing;

      if _Short and not _SingleString then Splitter := ''
      else Splitter := LongSplitter;

      { "Поля" вокруг текста одного комментария внутри его скобок. }
      if _Short then RightField := ''
      else RightField := ' ';


      Result := Format('%s %s%s%s%s', [

          Opn,
          {$IFDEF FORMATCOMMENTDEBUG}CommentAnchorToStr(_Anchor) + ':' + {$ENDIF}Text,
          RightField,
          Cls,
          Splitter

      ]);

    end;

  end;

var
  Search: TUserParam.TCommentList;
  LastShort: Boolean;
begin

  { TODO 1 -oVasilyevSM -cFormatParam: Нужен метод Search(StartAt, Anchor). Или привычно, Find(Anchor, var Comment):
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
    Long - да. А здесь только Offset в конце надо умно добавить и то не факт. Возможно, это дело функции Format. }

    { TODO 1 -oVasilyevSM -cFormatParam: В режиме Untyped комментарии типа должны складываться в BeforeValue... }

  Result    := '';
  Splitter  := '';
  LastShort := False;

  Search := Filter(_Anchor);
  try

    for Comment in Search do

      with Comment do begin

        Result := Result + _GetValue(Short);
        LastShort := Short;

      end;

  finally
    Search.Free;
  end;

  { Как раз последний разделитель значений нужно отрезать, неважно, какие были в цикле. }
  CutStr(Result, Length(Splitter));
  { Отступы справа и слева блока комментариев }
  ProcessOffsets(Result, _Anchor, _SingleString, _First, _Last, LastShort, _Nested);

end;

procedure TUserParam.TCommentList.ProcessOffsets;

  function _OffsetInfoKey: Byte;
  begin

    Result :=

        Integer(_Anchor) shl 3 or
        BooleanToInt(_SingleString) shl 2 or
        BooleanToInt(_First) shl 1 or
        BooleanToInt(_Last);

  end;

const

  {$IFDEF FORMATCOMMENTDEBUG}Offset = '_'{$ELSE}Offset = ' '{$ENDIF};

  RA_OffsetSetting: array [0..71] of TOffsetInfoReply = (

    { Anchor              Single First  Last  }
    { caBeforeParam       False  False  False } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       False  False  True  } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       False  True   False } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       False  True   True  } (LeftOffset: '';     RightOffset: CRLF  ),
    { caBeforeParam       True   False  False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeParam       True   False  True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeParam       True   True   False } (LeftOffset: Offset; RightOffset: Offset),
    { caBeforeParam       True   True   True  } (LeftOffset: Offset; RightOffset: Offset),

    { caBeforeName        False  False  False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        False  False  True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        False  True   False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        False  True   True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        True   False  False } (LeftOffset: Offset; RightOffset: Offset),
    { caBeforeName        True   False  True  } (LeftOffset: Offset; RightOffset: Offset),
    { caBeforeName        True   True   False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeName        True   True   True  } (LeftOffset: '';     RightOffset: Offset),

    { caAfterName         False  False  False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         False  False  True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         False  True   False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         False  True   True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True   False  False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True   False  True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True   True   False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterName         True   True   True  } (LeftOffset: Offset; RightOffset: ''    ),

    { caBeforeType        False  False  False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        False  False  True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        False  True   False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        False  True   True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True   False  False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True   False  True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True   True   False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeType        True   True   True  } (LeftOffset: '';     RightOffset: Offset),
    { caAfterType         False  False  False } (LeftOffset: '';     RightOffset: Offset),

    { caAfterType         False  False  True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         False  True   False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         False  True   True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True   False  False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True   False  True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True   True   False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterType         True   True   True  } (LeftOffset: Offset; RightOffset: ''    ),

    { caBeforeValue       False  False  False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       False  False  True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       False  True   False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       False  True   True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True   False  False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True   False  True  } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True   True   False } (LeftOffset: '';     RightOffset: Offset),
    { caBeforeValue       True   True   True  } (LeftOffset: '';     RightOffset: Offset),

    { caAfterValue        False  False  False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        False  False  True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        False  True   False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        False  True   True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True   False  False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True   False  True  } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True   True   False } (LeftOffset: Offset; RightOffset: ''    ),
    { caAfterValue        True   True   True  } (LeftOffset: Offset; RightOffset: ''    ),

    { caAfterParam        False  False  False } (LeftOffset: CRLF;   RightOffset: ''    ),
    { caAfterParam        False  False  True  } (LeftOffset: CRLF;   RightOffset: ''    ),
    { caAfterParam        False  True   False } (LeftOffset: CRLF;   RightOffset: ''    ),
    { caAfterParam        False  True   True  } (LeftOffset: CRLF;   RightOffset: ''    ),
    { caAfterParam        True   False  False } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterParam        True   False  True  } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterParam        True   True   False } (LeftOffset: Offset; RightOffset: Offset),
    { caAfterParam        True   True   True  } (LeftOffset: Offset; RightOffset: Offset),

    { caInsideEmptyParams False  False  False } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams False  False  True  } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams False  True   False } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams False  True   True  } (LeftOffset: CRLF;   RightOffset: CRLF  ),
    { caInsideEmptyParams True   False  False } (LeftOffset: Offset; RightOffset: Offset),
    { caInsideEmptyParams True   False  True  } (LeftOffset: Offset; RightOffset: Offset),
    { caInsideEmptyParams True   True   False } (LeftOffset: Offset; RightOffset: Offset),
    { caInsideEmptyParams True   True   True  } (LeftOffset: Offset; RightOffset: Offset)

  );

var
  LeftOffset, RightOffset: String;
begin

  if Length(_Value) > 0 then begin

    RA_OffsetSetting[_OffsetInfoKey].Get(LeftOffset, RightOffset);

    if not _Nested and (_Anchor in [caBeforeParam, caBeforeName]) then
      LeftOffset := '';

    if _LastShort and not _SingleString then
      RightOffset := '';

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

function TUserParams.ParamsReaderClass: TParamsReaderClass;
begin
  Result := TUserParamsReader;
end;

function TUserParams.FormatParam(_Param: TParam; _Value: String; _First, _Last: Boolean): String;
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

  procedure _FormatParams;
  begin
    if SingleString then _Value := Format('(%s)', [_Value])
    else _Value := Format('(%s)', [CRLF + ShiftText(_Value, 1)+ CRLF]);
  end;

var
  ParamFormat, Splitter: String;
begin

  Typed        := not (soTypesFree in SaveToStringOptions);
  SingleString := soSingleString in SaveToStringOptions;

  if Typed then ParamFormat := SC_VALUE_TYPED
  else ParamFormat := SC_VALUE_UNTYPED;

  (* Splitter *)
  if _Last then Splitter := ''
  else if SingleString then Splitter := ';'
  else Splitter := CRLF;

  if _Param.DataType = dtParams then
    _FormatParams;

  with _Param as TUserParam do begin

    BeforeParam       := Comments.GetBlock(caBeforeParam,       SingleString, _First, _Last, Nested);
    BeforeName        := Comments.GetBlock(caBeforeName,        SingleString, _First, _Last, Nested);
    AfterName         := Comments.GetBlock(caAfterName,         SingleString, _First, _Last, Nested);
    BeforeType        := Comments.GetBlock(caBeforeType,        SingleString, _First, _Last, Nested);
    AfterType         := Comments.GetBlock(caAfterType,         SingleString, _First, _Last, Nested);
    BeforeValue       := Comments.GetBlock(caBeforeValue,       SingleString, _First, _Last, Nested);
    AfterValue        := Comments.GetBlock(caAfterValue,        SingleString, _First, _Last, Nested);
    AfterParam        := Comments.GetBlock(caAfterParam,        SingleString, _First, _Last, Nested);
    InsideEmptyParams := Comments.GetBlock(caInsideEmptyParams, SingleString, _First, _Last, Nested);

    { TODO 3 -oVasilyevSM -cFormatParam: После значения типа Параметры добавляется лишний CRLF в конец блока
      комментариев. Это делается здесь и он есть Splitter. Но выключать это нужно только если последний комментарий в
      блоке AfterValue короткий. (* Splitter *) сюда и анализировать в нем новую переменную типа LastWasShort. }
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

function TUserParams.FormatParam1(_Param: TParam; _Value: String; _First, _Last: Boolean): String;
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

//    BeforeParam       := Comments.Get(caBeforeParam,       SingleString, Typed);
//    BeforeName        := Comments.Get(caBeforeName,        SingleString, Typed);
//    AfterName         := Comments.Get(caAfterName,         SingleString, Typed);
//    BeforeType        := Comments.Get(caBeforeType,        SingleString, Typed);
//    AfterType         := Comments.Get(caAfterType,         SingleString, Typed);
//    BeforeValue       := Comments.Get(caBeforeValue,       SingleString, Typed);
//    AfterValue        := Comments.Get(caAfterValue,        SingleString, Typed);
//    AfterParam        := Comments.Get(caAfterParam,        SingleString, Typed);
//    InsideEmptyParams := Comments.Get(caInsideEmptyParams, SingleString, Typed);

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

  CurrentComments.AddComment(_Value, _Opening, _Closing, Anchor, _Short);

end;

procedure TUserParamsReader.DetachBeforeParam;
var
  i: Integer;
begin

  if (ElementType = etName) and (CursorStanding = stBefore) then
    for i := 0 to CurrentComments.Count - 1 do
      with CurrentComments[i] do
        if Anchor = caBeforeName then
          CurrentComments[i] := TUserParam.TComment.Create(Text, Opening, Closing, caBeforeParam, Short);

end;

procedure TUserParamsReader.SaveTail;
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
      ParamComments.AddComment(Text, Opening, Closing, caInsideEmptyParams, Short);

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

procedure TUserParamsReader.KeyEvent(const _KeyWord: TKeyWord);
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

      Comments.AddRange(CurrentComments);
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
    AddComment(ReadComment, OpeningKey.StrValue, ClosingKey.StrValue, False);

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

{ TUserParam.TCommentList.TOffsetInfoReply }

procedure TUserParam.TCommentList.TOffsetInfoReply.Get(var _LeftOffset, _RightOffset: String);
begin
  _LeftOffset  := LeftOffset;
  _RightOffset := RightOffset;
end;

end.
