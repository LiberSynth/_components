unit vFormModel;

interface

uses
  Classes;

type

  TFormModel = class(TComponent)
  private
    FFormName: String;
    FInitFormOnDestroy: TNotifyEvent;
    procedure FormOnDestroy(_Sender: TObject);
    function FormatParamName(const _ParamName: String): String;
  public
    constructor Create(_Owner: TComponent); override;
  end;

implementation

uses
  Forms, SysUtils, Windows,
  vParams, vProjUtils;

{ TFormModel }

constructor TFormModel.Create(_Owner: TComponent);

  function _DefaultWidth: Integer;
  begin
    Result := Screen.WorkAreaWidth * 2 div 3;
  end;

  function _DefaultHeight: Integer;
  begin
    Result := Screen.WorkAreaHeight * 2 div 3;
  end;

begin
  inherited Create(_Owner);
  if Owner is TForm then
    with TForm(Owner) do begin
      with TParams.Create do
        try
          FInitFormOnDestroy := OnDestroy;
          OnDestroy := FormOnDestroy;
          LoadFromFile(IniFilePath);
          FFormName := Name;
          Width := CheckParam(FormatParamName('Width'), _DefaultWidth).AsInteger;
          Height := CheckParam(FormatParamName('Height'), _DefaultHeight).AsInteger;
          if CheckParam(FormatParamName('Maximized'), False).AsBoolean then WindowState := wsMaximized;
        finally
          Free;
        end;
    end;
end;

procedure TFormModel.FormOnDestroy(_Sender: TObject);
var
  WP: TWindowPlacement;
begin
  if Owner is TForm then
    with TForm(Owner) do begin
      if Assigned(FInitFormOnDestroy) then FInitFormOnDestroy(_Sender);
      OnDestroy := FInitFormOnDestroy;
      with TParams.Create do
        try
          LoadFromFile(IniFilePath);
          GetWindowPlacement(Handle, WP);
          GetParam(FormatParamName('Maximized')).AsBoolean := WindowState = wsMaximized;
          with WP.rcNormalPosition do begin
            GetParam(FormatParamName('Width')).AsInteger := Right - Left;
            GetParam(FormatParamName('Height')).AsInteger := Bottom - Top;
          end;
          SaveToFile(IniFilePath);
        finally
          Free;
        end;
  end;
end;

function TFormModel.FormatParamName(const _ParamName: String): String;
begin
  Result := Format('Common.%s.%s', [FFormName, _ParamName]);
end;

end.
