unit uCustomReadWrite;

interface

uses
  { LiberSynth }
  uCore;

type

  { Целиком абстрактные классы. Не знают, из чего считывать и во что. Нужны для запуска из объектов с переменной
    конкретикой. Взаимодействие исполняется через интерфейсы. При считывании Parser - ведущий, Reader - ведомый. При
    сохранении - наоборот, Renderer - ведущий, Writer - ведомый. }

  TCustomParser = class abstract (TIntfObject)

  public

    constructor Create; virtual;

    procedure RetrieveTargerInterface(_Receiver: TIntfObject); virtual; abstract;
    procedure FreeTargerInterface; virtual; abstract;
    procedure Read; virtual; abstract;

    function Clone: TCustomParser; virtual;
    procedure AcceptControl(_Sender: TCustomParser); virtual;

  end;

  TCustomParserClass = class of TCustomParser;

  TCustomReader = class abstract (TIntfObject)

  public

    constructor Create; virtual;

    function Clone: TCustomReader; virtual;

  end;

  TCustomReaderClass = class of TCustomReader;

  { renderer composer conductor }

  TCustomWriter = class abstract (TIntfObject)

  public

    constructor Create; virtual;

    procedure Write; virtual; abstract;

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

procedure TCustomParser.AcceptControl(_Sender: TCustomParser);
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
