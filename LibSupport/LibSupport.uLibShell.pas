unit LibSupport.uLibShell;

{ Ётот модуль нельз€ подключать в библиотеках, потому что метаинтерфейс TTaskShell €вл€етс€ синглтоном. }

interface

uses
  { VCL }
  System.SysUtils, Generics.Collections, Winapi.Windows,
  { LiberSynth }
  Core.uTypes, Classes.uAnonymousThread, Utils.uFileUtils, LibSupport.uInterfaces;

{TODO 1 -oVasilevSM : To trim. }

type

  TLSLibrary = class(TInterfacedObject, ILSLibrary)

  strict private

    { ILSLibrary }
    procedure RegisterTask(const _Name: WideString); safecall;

  end;

  TLibrary = class

  strict private type

    TLibraryMarkerFunc = function: ILSLibraryMarker; safecall;
    TInitLibraryProc   = procedure(_LSLibrary: ILSLibrary); safecall;
    TFinLibraryProc    = procedure; safecall;

  strict private

    FActive: Boolean;
    FFileName: String;
    FHandle: THandle;
    FMarkerChecked: Boolean;
    FInitialized: Boolean;
    FFinProc: TFinLibraryProc;

    procedure Activate;
    procedure Deactivate;
    function CheckMarker: Boolean;

    property Active: Boolean read FActive;
    property FileName: String read FFileName;
    property Handle: THandle read FHandle;
    property MarkerChecked: Boolean read FMarkerChecked;
    property FinProc: TFinLibraryProc read FFinProc;

  private

    constructor Create(const _FileName: String); reintroduce;

    function Initialize: Boolean;
    procedure Finalize;

    property Initialized: Boolean read FInitialized;

  end;

  TLibraryListChanged = procedure of object;

  TLibraryList = class(TObjectList<TLibrary>)

  strict private

    FChanged: Boolean;
    FOnChanged: TLibraryListChanged;

    function GetChanged: Boolean;
    procedure SetChanged(const _Value: Boolean);

    procedure DoChanged;

  private

    procedure FinalizeLibraries;

    property Changed: Boolean read GetChanged write SetChanged;
    property OnChanged: TLibraryListChanged read FOnChanged write FOnChanged;

  end;

  TLibShell = class

  strict private

    class var FInstance: TLibShell;
    class var FFinalized: Boolean;

    class property Finalized: Boolean read FFinalized;

  strict private

    FPersistent: Boolean;
    FLibraries: TLibraryList;

    function GetOnLibraryListChanged: TLibraryListChanged;
    procedure SetOnLibraryListChanged(const _Value: TLibraryListChanged);

    procedure LoadLibrariesDefault;
    procedure CompleteLoadDefault;
    procedure LoadLibrary(const _FileName: String);

    property Libraries: TLibraryList read FLibraries;

    constructor Create; reintroduce;

  private

    procedure AddTask(const _Name: String);

    property Persistent: Boolean read FPersistent;

  public

    destructor Destroy; override;

    class function Instance: TLibShell;
    class procedure Finalize;

    procedure LoadLibraries(_Persistent: Boolean; _LoadMethod: TProc = nil; _CompleteLoadMethod: TProc = nil); overload;
    procedure LoadLibraries(_LoadMethod: TProc = nil; _CompleteLoadMethod: TProc = nil); overload;

    property OnLibraryListChanged: TLibraryListChanged read GetOnLibraryListChanged write SetOnLibraryListChanged;

  end;

function LibShell: TLibShell;

implementation

function LibShell: TLibShell;
begin
  Result := TLibShell.Instance;
end;

{ TLibShell }

class function TLibShell.Instance: TLibShell;
begin

  if Finalized then
    raise ELibSupportException.Create('Using after finalization.');

  if not Assigned(FInstance) then
    FInstance := Self.Create;

  Result := FInstance;

end;

procedure TLibShell.AddTask(const _Name: String);
begin

end;

procedure TLibShell.CompleteLoadDefault;
begin
  Libraries.Changed := True;
end;

constructor TLibShell.Create;
begin
  inherited Create;
  FLibraries := TLibraryList.Create;
end;

destructor TLibShell.Destroy;
begin
  FreeAndNil(FLibraries);
  inherited Destroy;
end;

class procedure TLibShell.Finalize;
begin

  FFinalized := True;
  FreeAndNil(FInstance);

end;

function TLibShell.GetOnLibraryListChanged: TLibraryListChanged;
begin
  Result := Libraries.OnChanged;
end;

procedure TLibShell.LoadLibraries(_Persistent: Boolean; _LoadMethod, _CompleteLoadMethod: TProc);
begin

  FPersistent := _Persistent;

  ThreadProcess(

    procedure
    begin

      if Assigned(_LoadMethod) then
        _LoadMethod
      else
        LoadLibrariesDefault;

    end,

    procedure
    begin

      if Assigned(_CompleteLoadMethod) then
        _CompleteLoadMethod
      else
        CompleteLoadDefault;

    end

  );

end;

procedure TLibShell.LoadLibraries(_LoadMethod, _CompleteLoadMethod: TProc);
begin
  LoadLibraries(False, _LoadMethod, _CompleteLoadMethod)
end;

procedure TLibShell.LoadLibrariesDefault;
const
  SC_DLL_FILE_MASK = '*.dll';
var
  RootPath: String;
begin

  RootPath := ExeDir;

  ExploreFiles(RootPath, SC_DLL_FILE_MASK, True,

      procedure (const _File: String; _MaskMatches: Boolean; var _Terminated: Boolean)
      begin

        if _MaskMatches then
          LoadLibrary(_File);

      end

  );

end;

procedure TLibShell.LoadLibrary(const _FileName: String);
var
  TheLibrary: TLibrary;
begin

  TheLibrary := TLibrary.Create(_FileName);
  try

    TheLibrary.Initialize;
    if TheLibrary.Initialized then
      Libraries.Add(TheLibrary);

  finally
    if not TheLibrary.Initialized then
      TheLibrary.Free;
  end;

end;

procedure TLibShell.SetOnLibraryListChanged(const _Value: TLibraryListChanged);
begin
  Libraries.OnChanged := _Value;
end;

{ TLSLibrary }

procedure TLSLibrary.RegisterTask(const _Name: WideString);
begin
  LibShell.AddTask(_Name);
end;

{ TLibrary }

constructor TLibrary.Create(const _FileName: String);
begin
  inherited Create;
  FFileName := _FileName;
end;

procedure TLibrary.Finalize;
begin
  if Assigned(FinProc) then
    FinProc;
end;

function TLibrary.CheckMarker: Boolean;
var
  Marker: TLibraryMarkerFunc;
  MarkerInstance: ILSLibraryMarker;
begin

  if MarkerChecked then
    Exit(True);

  Marker := GetProcAddress(Handle, PWideChar('LSLibraryMarker'));

  if Assigned(Marker) then
  begin

    MarkerInstance := Marker;
    if Assigned(MarkerInstance) then
    begin

      FMarkerChecked := True;
      Exit(True);

    end;

  end;

  Result := False;

end;

procedure TLibrary.Activate;
begin

  FHandle := LoadLibrary(PWideChar(FileName));
  FActive := (Handle <> 0) and CheckMarker;

  { FinProc может быть не назначен, если там нечего освобождать. }
  FFinProc := GetProcAddress(Handle, PWideChar('FinLibrary' ));

end;

procedure TLibrary.Deactivate;
begin

  if Assigned(FinProc) then
    FinProc;

  FreeLibrary(Handle);
  FHandle := 0;
  FFinProc := nil;
  FActive := False;

end;

function TLibrary.Initialize: Boolean;
var
  InitProc: TInitLibraryProc;
begin

  Activate;
  try

    if Active then
    begin

      InitProc := GetProcAddress(Handle, PWideChar('InitLibrary'));
      if not Assigned(InitProc) then
        raise ELibSupportException.CreateFmt('Procedure InitLibrary not found in library ''%s''.', [FileName]);

      InitProc(TLSLibrary.Create);
      FInitialized := True;

    end;

  finally
    if (not Initialized and (Handle <> 0)) or not LibShell.Persistent then
      Deactivate;
  end;

end;

{ TLibraryList }

procedure TLibraryList.DoChanged;
begin

  if Assigned(OnChanged) then
    OnChanged;

  Changed := False;

end;

procedure TLibraryList.FinalizeLibraries;
var
  Item: TLibrary;
begin

  for Item in Self do
    Item.Finalize;

end;

function TLibraryList.GetChanged: Boolean;
begin
  Result := FChanged;
end;

procedure TLibraryList.SetChanged(const _Value: Boolean);
begin

  if _Value <> FChanged then
  begin

    FChanged := _Value;
    if FChanged then
      DoChanged;

  end;

end;

initialization

finalization

  TLibShell.Finalize;

end.
