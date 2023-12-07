unit uUserParams;

interface

uses
  { VCL }
  Generics.Collections, SysUtils,
  { Liber Synth }
  uTypes, uParams, uCustomStringParser, uParamsStringParser;

type

  TKeyType = (
    { inherits from uParamsStringParser.TKeyType }

      ktNone, ktSourceEnd, ktLineEnd, ktSpace, ktSplitter, ktTypeIdent, ktAssigning, ktStringBorder, ktNestedOpening,
      ktNestedClosing, ktLongCommentOpening, ktLongCommentClosing

  );
  TKeyTypes = set of TKeyType;

  TCommentAnchor = (caBeforeParam, caBeforeName, caAfterName, caBeforeType, caAfterType, caBeforeValue, caAfterValue);

  TComment = record

  strict private

    FValue: String;
    FAnchor: TCommentAnchor;

  private

    constructor Create(const _Value: String; _Anchor: TCommentAnchor);
    procedure SetAnchor(const _Value: TCommentAnchor);

    property Value: String read FValue write FValue;
    property Anchor: TCommentAnchor read FAnchor write SetAnchor;

  end;

  TCommentList = class(TList<TComment>)

  private

    procedure Add(const _Value: String; _Anchor: TCommentAnchor);

  end;

  TUserParam = class(TParam)

  end;

  TUserParams = class(TParams)

  protected

    function ParamClass: TParamClass; override;
    function ParamsReaderClass: TParamsReaderClass; override;

  end;

implementation

const

  KWR_LONG_COMMENT_OPENING_KEY_A: TKeyWord = (KeyTypeInternal: Integer(ktLongCommentOpening); StrValue: '{'; KeyLength: Length('{') );
  KWR_LONG_COMMENT_CLOSING_KEY_A: TKeyWord = (KeyTypeInternal: Integer(ktLongCommentClosing); StrValue: '}'; KeyLength: Length('}') );

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

  TReadInfoListHelper = class helper for TReadInfoList

  public

    procedure Add(

        _Operation: TOperation;
        _ItemType: TItemType;
        _Nested: TNested;
        _KeyTypes: TKeyTypes

    );

  end;

  TUserParamsReader = class(TParamsReader)

  strict private

    FCurrentComments: TCommentList;

    procedure CheckBeforeNameComments;

  private

    procedure AddComment(const _Value: String);

  protected

    procedure InitParser; override;

  public

    destructor Destroy; override;

    procedure KeyEvent(const _KeyWord: TKeyWord); override;

  end;

  TLongCommentRegion = class(TRegion)

  protected

    procedure RegionOpened(_Parser: TCustomStringParser); override;
    procedure RegionClosed(_Parser: TCustomStringParser); override;

  end;

{ TComment }

constructor TComment.Create(const _Value: String; _Anchor: TCommentAnchor);
begin
  Value  := _Value;
  Anchor := _Anchor;
end;

procedure TComment.SetAnchor(const _Value: TCommentAnchor);
begin
  FAnchor := _Value;
end;

{ TCommentList }

procedure TCommentList.Add(const _Value: String; _Anchor: TCommentAnchor);
begin
  inherited Add(TComment.Create(_Value, _Anchor));
end;

{ TUserParam }

{ TUserParams }

function TUserParams.ParamClass: TParamClass;
begin
  Result := TUserParam;
end;

function TUserParams.ParamsReaderClass: TParamsReaderClass;
begin
  Result := TUserParamsReader;
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

{ TReadInfoListHelper }

procedure TReadInfoListHelper.Add;
begin
  inherited Add(_Operation, _ItemType, _Nested, uParamsStringParser.TKeyTypes(_KeyTypes));
end;

{ TUserParamsReader }

procedure TUserParamsReader.CheckBeforeNameComments;
var
  i: Integer;
begin

  for i := 0 to FCurrentComments.Count - 1 do
    with FCurrentComments[i] do
      if Anchor = caBeforeName then
        FCurrentComments[i] := TComment.Create(Value, caBeforeParam);

end;

destructor TUserParamsReader.Destroy;
begin
  FreeAndNil(FCurrentComments);
  inherited Destroy;
end;

procedure TUserParamsReader.AddComment(const _Value: String);
var
  Anchor: TCommentAnchor;
begin

  case ItemType of

    itName:  if Length(CurrentName) > 0   then Anchor := caAfterName  else Anchor := caBeforeName;
    itType:  if (CurrentType > dtUnknown) then Anchor := caAfterType  else Anchor := caBeforeType;
    itValue: if Length(CurrentName) = 0   then Anchor := caAfterValue else Anchor := caBeforeValue;

  else
    raise EParamsReadException.Create('Unexpected content ItemType');
  end;

  FCurrentComments.Add(_Value, Anchor);

end;

procedure TUserParamsReader.InitParser;
begin

  inherited InitParser;

  FCurrentComments := TCommentList.Create;

  with KeyWords do begin

    Add(KWR_LONG_COMMENT_OPENING_KEY_A);
    Add(KWR_LONG_COMMENT_CLOSING_KEY_A);

  end;

  with Reading do begin

    {   Operation     ItemType Nested KeyType             }
//    Add(opProcessing, itName,  False, ktLongCommentOpening);
//    Add(opProcessing, itName,  True,  ktLongCommentOpening);
//    Add(opProcessing, itType,  False, ktLongCommentOpening);
//    Add(opProcessing, itType,  True,  ktLongCommentOpening);
//    Add(opProcessing, itValue, False, ktLongCommentOpening);
//    Add(opProcessing, itValue, True,  ktLongCommentOpening);

  end;

  {                RegionClass         OpeningKey                      ClosingKey                      UnterminatedMessage   }
  AddRegion(TLongCommentRegion, KWR_LONG_COMMENT_OPENING_KEY_A, KWR_LONG_COMMENT_CLOSING_KEY_A, 'Unterminated comment');

end;

procedure TUserParamsReader.KeyEvent(const _KeyWord: TKeyWord);
begin

  if

      (ItemType = itName) and
      (ItemStanding > stBefore) and
      (_KeyWord.KeyType = ktLineEnd)

  then

    CheckBeforeNameComments;

  inherited KeyEvent(_KeyWord);

end;

{ TLongCommentRegion }

procedure TLongCommentRegion.RegionClosed(_Parser: TCustomStringParser);
begin

  inherited RegionClosed(_Parser);

  with _Parser as TUserParamsReader do begin

    Move(- ClosingKey.KeyLength);
    try

      AddComment(Format('%s%s%s', [

          OpeningKey.StrValue,
          ReadItem(False),
          ClosingKey.StrValue

      ]));

    finally
//      ItemStanding := stBefore;
      Move(ClosingKey.KeyLength);
    end;

  end;

end;

procedure TLongCommentRegion.RegionOpened(_Parser: TCustomStringParser);
begin

  inherited RegionOpened(_Parser);

  with _Parser as TUserParamsReader do
    if ItemStanding > stBefore then
      ProcessItem;

end;

end.
