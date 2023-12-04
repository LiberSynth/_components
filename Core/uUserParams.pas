unit uUserParams;

interface

uses
  { Liber Synth }
  uParams, uCustomStringParser, uParamsStringParser;

type

  TKeyWordType = (
    { inherits from uParamsStringParser.TKeyWordType }

      ktNone, ktSourceEnd, ktLineEnd, ktSpace, ktSplitter, ktTypeIdent, ktAssigning, ktStringBorder, ktNestedOpening,
      ktNestedClosing, ktLongCommentOpening, ktLongCommentClosing

  );
  TKeyWordTypes = set of TKeyWordType;

  TKeyWordHelper = record helper for TKeyWord

  private

    constructor Create(_KeyType: TKeyWordType; const _StrValue: String); overload;

    function GetKeyType: TKeyWordType;
    procedure SetKeyType(const _Value: TKeyWordType);

    {$HINTS OFF}
    function TypeInSet(const _Set: TKeyWordTypes): Boolean;
    {$HINTS ON}

    property KeyType: TKeyWordType read GetKeyType write SetKeyType;

  end;

  TReadInfoListHelper = class helper for TReadInfoList

  public

    procedure Add(

        _Element: TElement;
        _Terminator: TKeyWordType;
        _Nested: Boolean;
        _NextElement: TElement;
        _ReadProc: TReadProc

    );

  end;

  TUserParams = class(TParams)

  private

    FComments: String;

  protected

    function ParamsReaderClass: TParamsReaderClass; override;

  public

    function SaveToString: String; override;
    property Comments: String read FComments write FComments;

  end;

implementation

const
                                                               { TODO 2 -oVasilyevSM -cTKeyWord: А тут совсем никак без Integer? }
  KWR_LONG_COMMENT_OPENING_KEY_A: TKeyWord = (KeyTypeInternal: Integer(ktLongCommentOpening); StrValue: '{'; KeyLength: Length('{') );
  KWR_LONG_COMMENT_CLOSING_KEY_A: TKeyWord = (KeyTypeInternal: Integer(ktLongCommentClosing); StrValue: '}'; KeyLength: Length('}') );

type

  TUserParamsReader = class(TParamsReader)

  protected

    procedure InitParser; override;

  end;

  TLongCommentRegion = class(TSpecialRegion)

  protected

    procedure SpecialRegionOpened(_Parser: TCustomStringParser); override;
    procedure SpecialRegionClosed(_Parser: TCustomStringParser); override;

  end;

{ TKeyWordHelper }

constructor TKeyWordHelper.Create(_KeyType: TKeyWordType; const _StrValue: String);
begin
  Create(Integer(_KeyType), _StrValue);
end;

function TKeyWordHelper.GetKeyType: TKeyWordType;
begin
  Result := TKeyWordType(KeyTypeInternal)
end;

procedure TKeyWordHelper.SetKeyType(const _Value: TKeyWordType);
begin
  if Integer(_Value) <> KeyTypeInternal then
    KeyTypeInternal := Integer(_Value)
end;

function TKeyWordHelper.TypeInSet(const _Set: TKeyWordTypes): Boolean;
begin
  Result := KeyType in _Set;
end;

{ TUserParams }

function TUserParams.ParamsReaderClass: TParamsReaderClass;
begin
  Result := TUserParamsReader;
end;

function TUserParams.SaveToString: String;
begin
  Result := inherited + #13#10 + FComments;
end;

{ TUserParamsReader }

procedure TUserParamsReader.InitParser;
begin

  inherited InitParser;

  with KeyWords do begin

    Add(KWR_LONG_COMMENT_OPENING_KEY_A);
    Add(KWR_LONG_COMMENT_CLOSING_KEY_A);

  end;

  with Reading do begin

    {   Element  Terminator            Nested NextElement ReadProc }
    Add(etName,  ktLongCommentOpening, False, etType,     ReadName );
    Add(etName,  ktLongCommentOpening, True,  etType,     ReadName );
    Add(etType,  ktLongCommentOpening, False, etValue,    ReadType );
    Add(etType,  ktLongCommentOpening, True,  etValue,    ReadType );
    Add(etValue, ktLongCommentOpening, False, etName,     ReadValue );
    Add(etValue, ktLongCommentOpening, True,  etName,     ReadValue );

  end;

  {                RegionClass         OpeningKey                      ClosingKey                      UnterminatedMessage   }
  AddSpecialRegion(TLongCommentRegion, KWR_LONG_COMMENT_OPENING_KEY_A, KWR_LONG_COMMENT_CLOSING_KEY_A, 'Unterminated comment');

end;

{ TLongCommentRegion }

procedure TLongCommentRegion.SpecialRegionClosed(_Parser: TCustomStringParser);
begin

  inherited SpecialRegionClosed(_Parser);

  with _Parser as TUserParamsReader do begin

    Move(- ClosingKey.KeyLength);
    try

      with Params as TUserParams do

        Comments :=

            Comments +
            OpeningKey.StrValue +
            ReadItem(False) +
            ClosingKey.StrValue +
            #13#10;

    finally
      Move(ClosingKey.KeyLength);
    end;

  end;

end;

procedure TLongCommentRegion.SpecialRegionOpened(_Parser: TCustomStringParser);
begin

  inherited SpecialRegionOpened(_Parser);

  with _Parser as TUserParamsReader do
    if ItemBody then
      CompleteElement(KWR_LONG_COMMENT_OPENING_KEY_A);

end;

{ TReadInfoListHelper }

procedure TReadInfoListHelper.Add;
begin
  inherited Add(_Element, Integer(_Terminator), _Nested, _NextElement, _ReadProc);
end;

end.
