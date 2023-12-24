unit uCustomReadWrite;

interface

uses
  { LiberSynth }
  uCore;

type

  { Целиком абстрактные классы. Не знают, из чего и во что считывать. Нужны для объектов с переменной конкретикой,
    обрабатываемой через интерфейсы. }
  TCustomReader = class abstract (TIntfObject)

  public

    constructor Create; virtual;

    procedure Read; virtual; abstract;

  end;

  TCustomParserClass = class of TCustomReader;

  TCustomWriter = class abstract (TIntfObject)

  public

    constructor Create; virtual;

    procedure Read; virtual; abstract;

  end;

  TCustomWriterClass = class of TCustomReader;

implementation

{ TCustomReader }

constructor TCustomReader.Create;
begin
  inherited Create;
end;

{ TCustomWriter }

constructor TCustomWriter.Create;
begin
  inherited Create;
end;

end.
