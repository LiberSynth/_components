unit uLSNIDCStringParser;

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

{ LSNI Direct Commented Parser }

interface

uses
  { VCL }
  SysUtils,
  { LiberSynth }
  uConsts, uCore, uCustomStringParser, uLSNIStringParser, uReadWriteCommon, uDataUtils, uStrUtils;

type

  TKeyType = ( { inherits from uParamsStringParser.TKeyType }

      ktNone, ktSourceEnd, ktLineEnd, ktSpace, ktSplitter, ktTypeIdent, ktAssigning, ktStringBorder, ktNestedOpening,
      ktNestedClosing, ktLongCommentOpening, ktLongCommentClosing, ktShortCommentOpening

  );
  TKeyTypes = set of TKeyType;

  TLSNIDCStringParser = class(TLSNIStringParser)

  strict private

    FCommentTerminatedValue: Boolean;
    FUserParamsReader: INTVCommentsReader;

    procedure LineEnd;

  private

    procedure AddComment(

        const _Value: String;
        const _Opening: String;
        const _Closing: String;
        _Short: Boolean

    );
    function ReadComment: String;

    property CommentTerminatedValue: Boolean read FCommentTerminatedValue write FCommentTerminatedValue;
    property UserParamsReader: INTVCommentsReader read FUserParamsReader write FUserParamsReader;

  protected

    procedure InitParser; override;
    procedure ElementTerminated(_KeyWord: TKeyWord); override;
    function ReadValue: String; override;

  public

    procedure KeyEvent(const _KeyWord: TKeyWord); override;
    procedure RetrieveTargerInterface(_Receiver: TIntfObject); override;
    procedure FreeTargerInterface; override;

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

{ TLSNIDCStringParser }

procedure TLSNIDCStringParser.LineEnd;
begin

  { Которые на предыдущих строках от имени, премещаем в BeforeParam оттуда. }
  if

      Assigned(UserParamsReader) and
      (ElementType = etName) and
      (CursorStanding = csBefore)

  then UserParamsReader.DetachBefore;

end;

procedure TLSNIDCStringParser.AddComment(const _Value, _Opening, _Closing: String; _Short: Boolean);
begin

  if Assigned(UserParamsReader) then

    case ElementType of

      etName:  UserParamsReader.AddNameComment (_Value, _Opening, _Closing, _Short, CursorStanding = csBefore);
      etType:  UserParamsReader.AddTypeComment (_Value, _Opening, _Closing, _Short, CursorStanding = csBefore);
      etValue: UserParamsReader.AddValueComment(_Value, _Opening, _Closing, _Short, CursorStanding = csBefore);

    else
      raise EStringParserException.Create('Unexpected content element');
    end;

end;

function TLSNIDCStringParser.ReadComment: String;
begin
  Result := Trim(Copy(Source, RegionStart, Cursor - RegionStart));
end;

procedure TLSNIDCStringParser.InitParser;
begin

  inherited InitParser;

  {         RegionClass          OpeningKey                       ClosingKey                      Caption  }
  AddRegion(TLongCommentRegion,  KWR_LONG_COMMENT_OPENING_KEY_A,  KWR_LONG_COMMENT_CLOSING_KEY_A, 'comment');
  AddRegion(TLongCommentRegion,  KWR_LONG_COMMENT_OPENING_KEY_B,  KWR_LONG_COMMENT_CLOSING_KEY_B, 'comment');
  AddRegion(TLongCommentRegion,  KWR_LONG_COMMENT_OPENING_KEY_C,  KWR_LONG_COMMENT_CLOSING_KEY_C, 'comment');
  AddRegion(TShortCommentRegion, KWR_SHORT_COMMENT_OPENING_KEY_A, KWR_EMPTY,                      'comment');
  AddRegion(TShortCommentRegion, KWR_SHORT_COMMENT_OPENING_KEY_B, KWR_EMPTY,                      'comment');

end;

procedure TLSNIDCStringParser.ElementTerminated(_KeyWord: TKeyWord);
begin

  inherited ElementTerminated(_KeyWord);

  if

      Assigned(UserParamsReader) and
      ((ElementType = etName) or (_KeyWord.KeyType = ktSourceEnd))

  then UserParamsReader.ElementTerminated;

end;

function TLSNIDCStringParser.ReadValue: String;
begin
  Result := inherited ReadValue;
  if CommentTerminatedValue then
    Result := TrimRight(Result);
end;

procedure TLSNIDCStringParser.KeyEvent(const _KeyWord: TKeyWord);
begin

  inherited KeyEvent(_KeyWord);

  if Assigned(UserParamsReader) then

    case _KeyWord.KeyType of

      ktLineEnd:   LineEnd;
      ktSourceEnd: UserParamsReader.SourceEnd;

    end;

end;

procedure TLSNIDCStringParser.RetrieveTargerInterface(_Receiver: TIntfObject);
begin
  inherited RetrieveTargerInterface(_Receiver);
  { Здесь запрашиваем интерфейс мягко, потом проверяем его присутствие по месту вызова и, в результате, получаем
    возможность чтения с отбросом комментариев простым созданием парсера соответствующего класса. }
  _Receiver.GetInterface(INTVCommentsReader, FUserParamsReader);
end;

procedure TLSNIDCStringParser.FreeTargerInterface;
begin
  inherited FreeTargerInterface;
  UserParamsReader := nil;
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

{ TCustomCommentRegion }

function TCustomCommentRegion.CanClose(_Parser: TCustomStringParser): Boolean;
begin
  Result := Executed;
end;

procedure TCustomCommentRegion.Opened(_Parser: TCustomStringParser);
begin

  CancelToggling := True;

  inherited Opened(_Parser);

  with _Parser as TLSNIDCStringParser do

    if CursorStanding = scInside then begin

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

  with _Parser as TLSNIDCStringParser do begin

    { Перемещаемся сразу на конец комментария, чтобы не бежать туда циклом. Этот Pos найдет его быстрее. }
    p := Pos(ClosingKey.StrValue, Source, Cursor);
    if p = 0 then Move(SrcLen - Cursor + 1)
    else Move(p - Cursor);

    { Считываем, потому что уже можем. Так меньше лишней нагрузки, поскольку CanClose уже просто True. }
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
    else raise EStringParserException.Create('Impossible case of comment reading.');

end;

procedure TShortCommentRegion.Execute(_Parser: TCustomStringParser; var _Handled: Boolean);
var
  p: Int64;
begin

  with _Parser as TLSNIDCStringParser do begin

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

procedure TShortCommentRegion.Closed(_Parser: TCustomStringParser);
begin

  inherited Closed(_Parser);

  with _Parser as TLSNIDCStringParser do
    if (ElementType = etValue) and (CursorStanding = csAfter) then
      KeyEvent(KWR_LINE_END_CRLF);

end;

procedure TShortCommentRegion.CheckUnterminated;
begin
end;

end.
