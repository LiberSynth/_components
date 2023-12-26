unit uCustomReadWrite;

interface

uses
  { LiberSynth }
  uCore;

type

  { Целиком абстрактные классы. Не знают, из чего считывать и во что. Нужны для запуска из объектов с переменной
    конкретикой. Взаимодействие обеспечивается через интерфейсы. }
  TCustomParser = class abstract (TIntfObject)

  public

    constructor Create; virtual;

    procedure RetrieveTargerInterface(_Receiver: TIntfObject); virtual; abstract;
    procedure FreeTargerInterface; virtual; abstract;
    procedure Read; virtual; abstract;

  end;

  TCustomParserClass = class of TCustomParser;

  TCustomReader = class abstract (TIntfObject)

  public

    constructor Create; virtual;

  end;

  TCustomReaderClass = class of TCustomReader;

  { renderer composer emiter generator }

  TCustomWriter = class abstract (TIntfObject)

  public

    constructor Create; virtual;

    procedure Read; virtual; abstract;

  end;

  TCustomWriterClass = class of TCustomParser;

  ECustomReadWriteException = class(ECoreException);

implementation

{ TCustomParser }

constructor TCustomParser.Create;
begin
  inherited Create;
end;

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
