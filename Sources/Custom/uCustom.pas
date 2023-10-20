unit uCustom;

interface

uses
  { VCL }
  ToolsAPI, Forms, ActnList, ImgList, Menus, ComCtrls, IniFiles, DesignIntf;

type

  TCustomThreadNotifier = class(TInterfacedObject, IOTAThreadNotifier)

  protected

    { IOTAThreadNotifier }
    procedure AfterSave; virtual;
    procedure BeforeSave; virtual;
    procedure Destroyed; virtual;
    procedure Modified; virtual;
    procedure ThreadNotify(_Reason: TOTANotifyReason); virtual;
    procedure {$IFDEF DELPHI2010}EvaluteComplete{$ELSE}EvaluateComplete{$ENDIF}(const _ExprStr, _ResultStr: String; _CanModify: Boolean; _ResultAddress, _ResultSize: LongWord; _ReturnCode: Integer); virtual;
    procedure ModifyComplete(const _ExprStr, _ResultStr: String; _ReturnCode: Integer); virtual;

  end;

  IFrameFormHelper = interface ['{0FD4A98F-CE6B-422A-BF13-14E59707D3B2}']

    function GetForm: TCustomForm;
    function GetFrame: TCustomFrame;
    procedure SetForm(_Form: TCustomForm);
    procedure SetFrame(_Frame: TCustomFrame);

  end;

  TCustomViewerFormHelper = class(TInterfacedObject, INTACustomDockableForm, IFrameFormHelper)

  protected

    { IFrameFormHelper }
    function GetForm: TCustomForm; virtual; abstract;
    function GetFrame: TCustomFrame; virtual; abstract;
    procedure SetForm(_Form: TCustomForm); virtual; abstract;
    procedure SetFrame(_Frame: TCustomFrame); virtual; abstract;

    { INTACustomDockableForm }
    function GetCaption: String; virtual; abstract;
    function GetIdentifier: String; virtual; abstract;
    function GetFrameClass: TCustomFrameClass; virtual; abstract;
    procedure FrameCreated(_Frame: TCustomFrame); virtual; abstract;
    function GetMenuActionList: TCustomActionList; virtual;
    function GetMenuImageList: TCustomImageList; virtual;
    procedure CustomizePopupMenu(_PopupMenu: TPopupMenu); virtual;
    function GetToolBarActionList: TCustomActionList; virtual;
    function GetToolBarImageList: TCustomImageList; virtual;
    procedure CustomizeToolBar(_ToolBar: TToolBar); virtual;
    procedure LoadWindowState(_Desktop: TCustomIniFile; const _Section: String); virtual;
    procedure SaveWindowState(_Desktop: TCustomIniFile; const _Section: String; _IsProject: Boolean); virtual;
    function GetEditState: TEditState; virtual;
    function EditAction(_Action: TEditAction): Boolean; virtual;

  end;

implementation

{ TCustomThreadNotifier }

procedure TCustomThreadNotifier.AfterSave;
begin
end;

procedure TCustomThreadNotifier.BeforeSave;
begin
end;

procedure TCustomThreadNotifier.Destroyed;
begin
end;

procedure TCustomThreadNotifier.{$IFDEF DELPHI2010}EvaluteComplete{$ELSE}EvaluateComplete{$ENDIF}(const _ExprStr, _ResultStr: String; _CanModify: Boolean; _ResultAddress, _ResultSize: LongWord; _ReturnCode: Integer);
begin
end;

procedure TCustomThreadNotifier.Modified;
begin
end;

procedure TCustomThreadNotifier.ModifyComplete(const _ExprStr, _ResultStr: String; _ReturnCode: Integer);
begin
end;

procedure TCustomThreadNotifier.ThreadNotify(_Reason: TOTANotifyReason);
begin
end;

{ TCustomViewerFormHelper }

procedure TCustomViewerFormHelper.CustomizePopupMenu(_PopupMenu: TPopupMenu);
begin
end;

procedure TCustomViewerFormHelper.CustomizeToolBar(_ToolBar: TToolBar);
begin
end;

function TCustomViewerFormHelper.EditAction(_Action: TEditAction): Boolean;
begin
  Result := False;
end;

function TCustomViewerFormHelper.GetEditState: TEditState;
begin
  Result := [];
end;

function TCustomViewerFormHelper.GetMenuActionList: TCustomActionList;
begin
  Result := nil;
end;

function TCustomViewerFormHelper.GetMenuImageList: TCustomImageList;
begin
  Result := nil;
end;

function TCustomViewerFormHelper.GetToolBarActionList: TCustomActionList;
begin
  Result := nil;
end;

function TCustomViewerFormHelper.GetToolBarImageList: TCustomImageList;
begin
  Result := nil;
end;

procedure TCustomViewerFormHelper.LoadWindowState(_Desktop: TCustomIniFile; const _Section: String);
begin
end;

procedure TCustomViewerFormHelper.SaveWindowState(_Desktop: TCustomIniFile; const _Section: String; _IsProject: Boolean);
begin
end;

end.
