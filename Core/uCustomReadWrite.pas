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

    function Clone: TCustomParser; virtual;
    procedure Accept(_Sender: TCustomParser); virtual;

  end;

  TCustomParserClass = class of TCustomParser;

  TCustomReader = class abstract (TIntfObject)

  public

    constructor Create; virtual;

    function Clone: TCustomReader; virtual;

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

function TCustomParser.Clone: TCustomParser;
begin
  Result := TCustomParserClass(ClassType).Create;
end;

procedure TCustomParser.Accept(_Sender: TCustomParser);
begin
end;

{ TCustomReader }

constructor TCustomReader.Create;
begin
  inherited Create;
end;

function TCustomReader.Clone: TCustomReader;
begin
  Result := TCustomReaderClass(ClassType).Create;
end;

{ TCustomWriter }

constructor TCustomWriter.Create;
begin
  inherited Create;
end;

end.
