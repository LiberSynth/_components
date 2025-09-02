unit Parsing.uParsers;

interface

type

  TCustomParser = class

  strict private

    FParseEvent: TParseEvent;

    function GetEof: Boolean;

  public

    procedure Parse; overload;
    procedure Parse(_OnParseProc: TOnParseProc); overload;
    procedure Terminate;

    property Eof: Boolean read GetEof;
    property OnParseEvent: TParseEvent read FParseEvent write FParseEvent;

  end;

implementation

{ TCustomParser }

function TCustomParser.GetEof: Boolean;
begin

end;

procedure TCustomParser.Parse;
begin

end;

procedure TCustomParser.Parse(_OnParseProc: TOnParseProc);
begin

end;

procedure TCustomParser.Terminate;
begin

end;

end.
