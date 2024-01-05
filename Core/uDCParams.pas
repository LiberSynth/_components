unit uDCParams;

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

{ TODO 5 -oVasilyevSM -cuUserParams: Есть еще один кейс - пустой файл только с комментариями }
{ TODO 5 -oVasilyevSM -cuUserParams: Задача: Нужны параметры, хранящие исходное форматирование. Всю строку между
  элементами запоминать в объект и потом выбрасывать обратно в строку в исходном виде, что бы там ни было. }

{ Direct commented params }

interface

uses
  { VCL }
  Generics.Collections, SysUtils,
  { Liber Synth }
  uConsts, uDataUtils, uStrUtils, uParams;

type

  TCommentAnchor = (

      caBeforeParam, caBeforeName, caAfterName, caBeforeType, caAfterType,
      caBeforeValue, caAfterValue, caAfterParam, caInsideEmptyParams

  );
  TCommentAnchors = set of TCommentAnchor;

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

  public

    procedure AddComment(

        const _Text: String;
        const _Opening: String;
        const _Closing: String;
        _Anchor: TCommentAnchor;
        _Short: Boolean

    );

  end;

  TDCParam = class(TParam)

  strict private

    FComments: TCommentList;

  protected

    constructor Create(const _Name: String; const _PathSeparator: Char = '.'); override;

    procedure AssignValue(_Source: TParam; _Host: TParams; _ForceAdding: Boolean); override;

  public

    destructor Destroy; override;

    property Comments: TCommentList read FComments;

  end;

  { Этот класс никому НЕ должен: уметь быстро обрабатывать большие хранилища. Если формат LSNI используется как
    мини-база, не нужно там держать комментарии никому. }
  TDCParams = class(TParams)

  protected

    function ParamClass: TParamClass; override;

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

{ TComment }

constructor TComment.Create;
begin

  Text    := _Text;
  Opening := _Opening;
  Closing := _Closing;
  Anchor  := _Anchor;
  Short   := _Short;

end;

procedure TComment.GetMargins(_SingleString: Boolean; var _Opening, _Closing: String);
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

{ TCommentList }

procedure TCommentList.AddComment;
begin
  inherited Add(TComment.Create(_Text, _Opening, _Closing, _Anchor, _Short));
end;

{ TDCParam }

constructor TDCParam.Create;
begin
  inherited Create(_Name, _PathSeparator);
  FComments := TCommentList.Create;
end;

destructor TDCParam.Destroy;
begin
  FreeAndNil(FComments);
  inherited Destroy;
end;

procedure TDCParam.AssignValue(_Source: TParam; _Host: TParams; _ForceAdding: Boolean);
begin

  inherited AssignValue(_Source, _Host, _ForceAdding);

  Comments.Clear;
  if _Source is TDCParam then
    Comments.AddRange(TDCParam(_Source).Comments);

end;

{ TDCParams }

function TDCParams.ParamClass: TParamClass;
begin
  Result := TDCParam;
end;

end.
