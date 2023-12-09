unit uUserParams;

interface

uses
  { VCL }
  Generics.Collections, SysUtils,
  { Liber Synth }
  uConsts, uTypes, uStrUtils, uParams, uCustomStringParser, uParamsStringParser;

type

  TKeyType = ( { inherits from uParamsStringParser.TKeyType }

      ktNone, ktSourceEnd, ktLineEnd, ktSpace, ktSplitter, ktTypeIdent, ktAssigning, ktStringBorder, ktNestedOpening,
      ktNestedClosing, ktLongCommentOpening, ktLongCommentClosing, ktShortCommentOpening

  );
  TKeyTypes = set of TKeyType;

  TCommentAnchor = (

      caBeforeParam, caBeforeName, caAfterName, caBeforeType, caAfterType, caBeforeValue, caAfterValue, caAfterParam

  );

  TComment = record

  strict private

    FValue: String;
    FAnchor: TCommentAnchor;
    FShort: Boolean;

  private

    constructor Create(

      const _Value: String; 
      _Anchor: TCommentAnchor;
      _Short: Boolean

    );
    procedure SetAnchor(const _Value: TCommentAnchor);
    procedure SetShort(const _Value: Boolean);

    property Value: String read FValue write FValue;
    property Anchor: TCommentAnchor read FAnchor write SetAnchor;
    property Short: Boolean read FShort write SetShort;

  end;

  TCommentList = class(TList<TComment>)

  private

    procedure Add(

      const _Value: String; 
      _Anchor: TCommentAnchor;
      _Short: Boolean

    );
    function Get(_Anchor: TCommentAnchor; _SingleString: Boolean): String;

  end;

  TUserParam = class(TParam)

  strict private

    FComments: TCommentList;

  private

    property Comments: TCommentList read FComments;

  protected

    constructor Create(const _Name: String; const _PathSeparator: Char = '.'); override;

    procedure AssignValue(_Source: TParam; _ForceAdding: Boolean); override;

  public

    destructor Destroy; override;

  end;

  TUserParams = class(TParams)

  protected

    function ParamClass: TParamClass; override;
    function ParamsReaderClass: TParamsReaderClass; override;
    function FormatParam(_Param: TParam; const _Name: String; const _Type: String; const _Value: String; _First: Boolean): String; override;

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

  TUserParamsReader = class(TParamsReader)

  strict private

    FCurrentParam: TUserParam;
    FCurrentComments: TCommentList;
    FCommentTerminatedValue: Boolean;

    procedure CheckBeforeNameComments;
    procedure SaveLastComments;

  private

    function ReadComment(_Shift: Byte): String;
    procedure AddComment(const _Value: String; _Short: Boolean);
    procedure ParamReadEvent(_Param: TParam); override;

    property CurrentParam: TUserParam read FCurrentParam write FCurrentParam;
    property CurrentComments: TCommentList read FCurrentComments;
    property CommentTerminatedValue: Boolean read FCommentTerminatedValue write FCommentTerminatedValue;

  protected

    procedure InitParser; override;

  public

    destructor Destroy; override;

    procedure KeyEvent(const _KeyWord: TKeyWord); override;
    function ReadElement(_Trim: Boolean): String; override;
    procedure ElementTerminatedEvent(_KeyWord: TKeyWord); override;

  end;

  TCustomCommentRegion = class(TRegion)

  protected

    procedure RegionOpened(_Parser: TCustomStringParser); override;

  end;

  TLongCommentRegion = class(TCustomCommentRegion)

  protected

    procedure RegionClosed(_Parser: TCustomStringParser); override;

  end;

  TShortCommentRegion = class(TCustomCommentRegion)

  strict private

    FTerminator: String;

  protected

    function CanClose(_Parser: TCustomStringParser): Boolean; override;
    procedure RegionClosed(_Parser: TCustomStringParser); override;

  end;

{ TComment }

constructor TComment.Create;
begin

  Value  := _Value;
  Anchor := _Anchor;
  Short  := _Short;
  
end;

procedure TComment.SetAnchor(const _Value: TCommentAnchor);
begin
  FAnchor := _Value;
end;

procedure TComment.SetShort(const _Value: Boolean);
begin
  FShort := _Value;
end;

{ TCommentList }

procedure TCommentList.Add;
begin
  inherited Add(TComment.Create(_Value, _Anchor, _Short));
end;

function TCommentList.Get(_Anchor: TCommentAnchor; _SingleString: Boolean): String;
var
  Comment: TComment;
  Splitter: String;
begin

  Result := '';

  if not _SingleString and (_Anchor in [caBeforeParam, caAfterParam]) then Splitter := CRLF
  else Splitter := ' ';

  for Comment in Self do

    with Comment do

      if Anchor = _Anchor then begin

        if Short then Splitter := '';

        if Anchor in [caAfterName, caAfterType, caAfterValue] then Result := Result + Splitter + Value
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

procedure TUserParam.AssignValue(_Source: TParam; _ForceAdding: Boolean);
begin

  inherited AssignValue(_Source, _ForceAdding);

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

function TUserParams.FormatParam(_Param: TParam; const _Name, _Type, _Value: String; _First: Boolean): String;
const

  SC_VALUE_UNTYPED = '%4:s%5:s%0:s%6:s = %9:s%2:s%10:s%3:s%11:s';
  SC_VALUE_TYPED   = '%4:s%5:s%0:s%6:s: %7:s%1:s%8:s = %9:s%2:s%10:s%3:s%11:s';

var
  ParamFormat: String;
  Splitter: String;
  SingleString: Boolean;
begin

  if soTypesFree in SaveToStringOptions then ParamFormat := SC_VALUE_UNTYPED
  else ParamFormat := SC_VALUE_TYPED;

  SingleString := soSingleString in SaveToStringOptions;

  if SingleString then Splitter := ';'
  else Splitter := CRLF;

  with _Param as TUserParam do

    Result := Format(ParamFormat, [

        _Name,
        _Type,
        _Value,
        Splitter,
        Comments.Get(caBeforeParam, SingleString),
        Comments.Get(caBeforeName,  SingleString),
        Comments.Get(caAfterName,   SingleString),
        Comments.Get(caBeforeType,  SingleString),
        Comments.Get(caAfterType,   SingleString),
        Comments.Get(caBeforeValue, SingleString),
        Comments.Get(caAfterValue,  SingleString),
        Comments.Get(caAfterParam,  SingleString)

    ]);

  if SingleString and not _First then
    Result := ' ' + Result;

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

{ TUserParamsReader }

destructor TUserParamsReader.Destroy;
begin
  FreeAndNil(FCurrentComments);
  inherited Destroy;
end;

procedure TUserParamsReader.CheckBeforeNameComments;
var
  i: Integer;
begin

  for i := 0 to CurrentComments.Count - 1 do
    with CurrentComments[i] do
      if Anchor = caBeforeName then
        CurrentComments[i] := TComment.Create(Value, caBeforeParam, Short);

end;

procedure TUserParamsReader.SaveLastComments;
var
  i: Integer;
begin

  if Assigned(CurrentParam) then begin

    for i := 0 to CurrentComments.Count - 1 do
      with CurrentComments[i] do
        CurrentComments[i] := TComment.Create(Value, caAfterParam, Short);

    CurrentParam.Comments.AddRange(CurrentComments.ToArray);

  end;

end;

function TUserParamsReader.ReadComment(_Shift: Byte): String;
begin
  Result := Copy(Source, RegionStart, Cursor - RegionStart - _Shift);
end;

procedure TUserParamsReader.AddComment(const _Value: String; _Short: Boolean);
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

  CurrentComments.Add(_Value, Anchor, _Short);

end;

procedure TUserParamsReader.ParamReadEvent(_Param: TParam);
begin
  inherited ParamReadEvent(_Param);
  CurrentParam := _Param as TUserParam;
end;

procedure TUserParamsReader.InitParser;
begin

  inherited InitParser;

  FCurrentComments := TCommentList.Create;

  with KeyWords do begin

    Add(KWR_LONG_COMMENT_OPENING_KEY_A);
    Add(KWR_LONG_COMMENT_CLOSING_KEY_A);

  end;

  {         RegionClass          OpeningKey                       ClosingKey                      UnterminatedMessage   }
  AddRegion(TLongCommentRegion,  KWR_LONG_COMMENT_OPENING_KEY_A,  KWR_LONG_COMMENT_CLOSING_KEY_A, 'Unterminated comment');
  AddRegion(TLongCommentRegion,  KWR_LONG_COMMENT_OPENING_KEY_B,  KWR_LONG_COMMENT_CLOSING_KEY_B, 'Unterminated comment');
  AddRegion(TLongCommentRegion,  KWR_LONG_COMMENT_OPENING_KEY_C,  KWR_LONG_COMMENT_CLOSING_KEY_C, 'Unterminated comment');
  AddRegion(TShortCommentRegion, KWR_SHORT_COMMENT_OPENING_KEY_A, KWR_EMPTY,                      'Unterminated comment');
  AddRegion(TShortCommentRegion, KWR_SHORT_COMMENT_OPENING_KEY_B, KWR_EMPTY,                      'Unterminated comment');

end;

procedure TUserParamsReader.KeyEvent(const _KeyWord: TKeyWord);
begin

  inherited KeyEvent(_KeyWord);

  case _KeyWord.KeyType of

    ktLineEnd:   if ElementType = etName then CheckBeforeNameComments;
    ktSourceEnd: SaveLastComments;

  end;

end;

function TUserParamsReader.ReadElement(_Trim: Boolean): String;
begin
  Result := inherited ReadElement(_Trim);
  if CommentTerminatedValue then
    Result := TrimRight(Result);
end;

procedure TUserParamsReader.ElementTerminatedEvent(_KeyWord: TKeyWord);
begin

  inherited ElementTerminatedEvent(_KeyWord);

  if

      ((ElementType = etName) or (_KeyWord.KeyType = ktSourceEnd)) and
      Assigned(CurrentParam)

  then

    with CurrentParam do begin

      Comments.Clear;
      Comments.AddRange(CurrentComments.ToArray);
      CurrentComments.Clear;

    end;

end;

{ TCustomCommentRegion }

procedure TCustomCommentRegion.RegionOpened(_Parser: TCustomStringParser);
begin

  inherited RegionOpened(_Parser);

  with _Parser as TUserParamsReader do

    if (CursorStanding > stBefore) and (ElementStart > 0) then begin

      CommentTerminatedValue := True;
      try

        ProcessElement;

      finally
        CommentTerminatedValue := False;
      end;

    end;

end;

{ TLongCommentRegion }

procedure TLongCommentRegion.RegionClosed(_Parser: TCustomStringParser);
begin

  inherited RegionClosed(_Parser);

  with _Parser as TUserParamsReader do begin

    AddComment(Format('%s%s%s', [

        OpeningKey.StrValue,
        ReadComment(ClosingKey.KeyLength),
        ClosingKey.StrValue

    ]), False);

  end;

end;

{ TShortCommentRegion }

function TShortCommentRegion.CanClose(_Parser: TCustomStringParser): Boolean;

  function _Check(const _Value: String): Boolean;
  begin

    with _Parser do
      Result := Copy(Source, Cursor, 2) = _Value;

    if Result then FTerminator := _Value;
      
  end;
  
begin
  Result := _Check(CRLF) or _Check(CR) or _Check(LF);
end;

procedure TShortCommentRegion.RegionClosed(_Parser: TCustomStringParser);
var
  Prefix, Suffix: String;
  Short: Boolean;
begin

  inherited RegionClosed(_Parser);

  with _Parser as TUserParamsReader do begin

    Short := not (soSingleString in Params.SaveToStringOptions);
    if Short then begin

      Prefix := OpeningKey.StrValue;
      Suffix := FTerminator;
        
    end else begin
     
      Prefix := '{';
      Suffix := '}';
      
    end;
    
    AddComment(Format('%s%s%s', [

        Prefix,
        ReadComment(0),
        Suffix

    ]), Short);

    Move(Length(FTerminator));

  end;

end;

end.
