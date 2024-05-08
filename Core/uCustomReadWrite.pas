unit uCustomReadWrite;

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

interface

uses
  { LiberSynth }
  uCore;

type

  { ������� ����������� ������. �� �����, �� ���� ��������� � �� ���. ����� ��� ������� �� �������� � ����������
    �����������. �������������� ����������� ����� ����������. ��� ���������� Parser - �������, Reader - �������. ���
    ���������� - ��������, Renderer - �������, Writer - �������. }

  { �������������� � ������������� ������ }
  TCustomParser = class abstract (TIntfObject)

  strict private

    FTerminated: Boolean;

  public

    constructor Create; virtual;

    procedure RetrieveTargerInterface(_Receiver: TIntfObject); virtual;
    procedure FreeTargerInterface; virtual;
    procedure SetSource(const _Data); virtual; abstract;
    procedure FreeContext(var _Data); virtual; abstract;
    procedure Read; virtual; abstract;
    procedure Terminate;

    function Clone: TCustomParser; virtual;
    procedure AcceptControl(_Sender: TCustomParser); virtual;

    property Terminated: Boolean read FTerminated;

  end;

  TCustomParserClass = class of TCustomParser;

  { ������������� � ��������� �������� }
  TCustomReader = class abstract (TIntfObject)

  public

    constructor Create; virtual;

    function Clone: TCustomReader; virtual;

  end;

  TCustomReaderClass = class of TCustomReader;

  { ������ �������� ��������� }
  TCustomWriter = class abstract (TIntfObject)

  public

    constructor Create; virtual;

  end;

  TCustomWriterClass = class of TCustomWriter;

  { ���������� �������� ��������� }
  TCustomCompiler = class abstract (TIntfObject)

  public

    constructor Create; virtual;

    function Clone: TCustomCompiler; virtual;

    procedure RetrieveWriter(_Writer: TCustomWriter); virtual; abstract;
    procedure Run; virtual; abstract;

  end;

  TCustomCompilerClass = class of TCustomCompiler;

  ECustomReadWriteException = class(ECoreException);
  EReadException = class(ECustomReadWriteException);
  EWriteException = class(ECustomReadWriteException);

implementation

{ TCustomParser }

constructor TCustomParser.Create;
begin
  inherited Create;
end;

procedure TCustomParser.RetrieveTargerInterface(_Receiver: TIntfObject);
begin
  raise ECustomReadWriteException.Create('Override this method.');
end;

procedure TCustomParser.FreeTargerInterface;
begin
  raise ECustomReadWriteException.Create('Override this method.');
end;

procedure TCustomParser.Terminate;
begin
  FTerminated := True;
end;

function TCustomParser.Clone: TCustomParser;
begin
  { TODO 1 -oVasilyevSM -cClone: ������, ����� ������� ����������� ������������ Assign ������� TPersistent. ��������� ��. }
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

{ TCustomCompiler }

constructor TCustomCompiler.Create;
begin
  inherited Create;
end;

function TCustomCompiler.Clone: TCustomCompiler;
begin
  Result := TCustomCompilerClass(ClassType).Create;
end;

end.
