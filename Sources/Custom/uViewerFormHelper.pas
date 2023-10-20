unit uViewerFormHelper;

interface

uses
  { VCL }
  Forms, Classes,
  { VDebugPackage }
  uCustom, uCustomViewerFrame;

type

  TViewerFormHelper = class(TCustomViewerFormHelper)

  private

    FForm: TCustomForm;
    FFrame: TCustomViewerFrame;
    FExpression: String;
    FFormCaption: String;
    FSuggestedLeft: Integer;
    FSuggestedTop: Integer;
    FParamsSectionName: String;
    FInitFormOnDestroy: TNotifyEvent;

  private

    procedure FormOnDestroy(_Sender: TObject);

  protected

    function GetForm: TCustomForm; override;
    function GetFrame: TCustomFrame; override;
    procedure SetForm(_Form: TCustomForm); override;
    procedure SetFrame(_Frame: TCustomFrame); override;
    function GetCaption: String; override;
    function GetIdentifier: String; override;
    procedure FrameCreated(_Frame: TCustomFrame); override;
    procedure SetFormProperties(_Form: TCustomForm); virtual;
    property Frame: TCustomViewerFrame read FFrame;
    property ParamsSectionName: String read FParamsSectionName;

  public

    constructor Create(const _Expression, _FormCaption: String; _SuggestedLeft, _SuggestedTop: Integer; const _ParamsSectionName: String);

  end;

  TViewerFormHelperClass = class of TViewerFormHelper;

implementation

uses
  { VCL }
  SysUtils, Math, Controls,
  { VDebugPackage }
  uConsts, uCommon;

{ TCustomViewerForm }

constructor TViewerFormHelper.Create(const _Expression, _FormCaption: String; _SuggestedLeft, _SuggestedTop: Integer; const _ParamsSectionName: String);
begin

  inherited Create;

  FExpression := _Expression;
  FFormCaption := _FormCaption;
  FSuggestedLeft := _SuggestedLeft;
  FSuggestedTop := _SuggestedTop;
  FParamsSectionName := _ParamsSectionName;

end;

procedure TViewerFormHelper.FormOnDestroy(_Sender: TObject);

  procedure _SaveParams;

    procedure _SaveFrame;
    var
      i: Integer;
    begin

      with _Sender as TWinControl do
        for i := 0 to ControlCount - 1 do
          if Controls[i] is TCustomViewerFrame then TCustomViewerFrame(Controls[i]).SaveParams(FParamsSectionName);

    end;

  begin

    with _Sender as TForm, PackageParams do begin

      GetParam(FParamsSectionName + '.Form.Width').AsInteger := Width;
      GetParam(FParamsSectionName + '.Form.Height').AsInteger := Height;
      GetParam(FParamsSectionName + '.Form.Left').AsInteger := Left;
      GetParam(FParamsSectionName + '.Form.Top').AsInteger := Top;
      _SaveFrame;

    end;

  end;

begin

  _SaveParams;
  if Assigned(FInitFormOnDestroy) then FInitFormOnDestroy(_Sender);
  (_Sender as TForm).OnDestroy := FInitFormOnDestroy;

end;

procedure TViewerFormHelper.FrameCreated(_Frame: TCustomFrame);
begin
  FFrame := _Frame as TCustomViewerFrame;
end;

function TViewerFormHelper.GetCaption: String;
begin
  Result := Format(SC_FormCaption, [FFormCaption, FExpression]);
end;

function TViewerFormHelper.GetForm: TCustomForm;
begin
  Result := FForm;
end;

function TViewerFormHelper.GetFrame: TCustomFrame;
begin
  Result := FFrame;
end;

function TViewerFormHelper.GetIdentifier: String;
begin
  Result := ClassName;
end;

procedure TViewerFormHelper.SetForm(_Form: TCustomForm);
begin

  FForm := _Form;
  SetFormProperties(FForm);
  if Assigned(FFrame) then FFrame.SetForm(FForm);

end;

procedure TViewerFormHelper.SetFormProperties(_Form: TCustomForm);
begin

  with _Form as TForm do begin

    with PackageParams do begin

      Width := CheckParam(FParamsSectionName + '.Form.Width', Screen.WorkAreaWidth div 3).AsInteger;
      Height := CheckParam(FParamsSectionName + '.Form.Height', Screen.WorkAreaHeight div 2).AsInteger;
      Left := Max(0, CheckParam(FParamsSectionName + '.Form.Left', Screen.WorkAreaWidth div 3).AsInteger);
      Top := Max(0, CheckParam(FParamsSectionName + '.Form.Top', Screen.WorkAreaHeight div 4).AsInteger);

    end;

    Visible := True;
    KeyPreview := True;
    FInitFormOnDestroy := OnDestroy;
    OnDestroy := FormOnDestroy;

  end;

end;

procedure TViewerFormHelper.SetFrame(_Frame: TCustomFrame);
begin
  FFrame := _Frame as TCustomViewerFrame;
end;

end.
