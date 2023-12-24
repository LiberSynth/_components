unit uCustomParser;

interface

uses
  { LiberSynth }
  uCore;

type

  TCustomParser = class abstract (TIntfObject)

  public

    constructor Create; virtual;

    procedure Read; virtual; abstract;

  end;

  TCustomParserClass = class of TCustomParser;

implementation

{ TCustomParser }

constructor TCustomParser.Create;
begin
  inherited Create;
end;

end.
