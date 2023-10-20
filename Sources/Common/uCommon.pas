unit uCommon;

interface

uses
  { VCL }
  SysUtils,
  { Utils }
  vParams;

{ Сохраняемые параметры пакета }
function PackageParams: TParams;

function FormatException(E: Exception): String;
function WrapMessage(const Wrapper, ErrorMessage: String): String;

{ Возвращает ключ выражения ('Obj,r' -> 'r') }
function GetExpressionKey(const Expression: String): String;
{ Проверяет ключ выражения на заданное значение }
function CheckExpressionKey(const Expression, Key: String): Boolean;
{ Проверяет ключ выражения на значение SC_ExpressionKey_VDP }
function CheckVDPExpressionKey(const Expression: String): Boolean;
{ Удаляет ключ из выражения }
function ClearExpressionKey(const Expression: String): String;

{ Преобразует строку из вида эвалюатора в обычный вид }
function PureValueText(const Value: String): String;
function Max(const Args: array of Integer): Integer; overload;

implementation

uses
  { VCL }
  Math,
  { Utils }
  vFileUtils, vLog,
  { VDebugPackage }
  uConsts;

{ Сохраняемые параметры пакета }

var
  Params: TParams;

function ParamsFilePath: String;
var
  Folder: String;
begin

  if GetSpecialFolder(Folder, sfAppData) then

    Result := Format('%0:s\%1:s\%2:s\%2:s.ini', [Folder, 'VDP', PackageName])

  else Result := '';

end;

procedure LoadParams;
begin

  Params := TParams.Create;
  try

    Params.LoadFromFile(ParamsFilePath);

  except
    on E: Exception do
      WriteError(E);
  end;

end;

procedure SaveParams;
var
  FN: String;
begin

  try

    FN := ParamsFilePath;
    CheckDirExisting(ExtractFileDir(FN));
    if FileExists(FN) then DeleteFile(FN);
    Params.SaveToFile(FN);

  except
    on E: Exception do
      WriteError(E);
  end;

  Params.Free;

end;

function PackageParams: TParams;
const
  SC_Message = 'Package parameters not loaded';
begin
  if not Assigned(Params) then raise Exception.Create(SC_Message);
  Result := Params;
end;

function FormatException(E: Exception): String;
begin
  Result := Format(SC_ExceptionFormat, [E.ClassName, E.Message]);
end;

function WrapMessage(const Wrapper, ErrorMessage: String): String;
begin
  Result := Format(SC_WrapperFormat, [Wrapper, ErrorMessage]);
end;

function GetExpressionKey(const Expression: String): String;
var
  i: Integer;
begin

  for i := Length(Expression) downto 1 do
    if Expression[i] = ',' then Exit(Trim(Copy(Expression, i + 1, Length(Expression))));

  Result := '';

end;

function CheckExpressionKey(const Expression, Key: String): Boolean;
begin
  Result := SameText(Key, GetExpressionKey(Expression));
end;

function CheckVDPExpressionKey(const Expression: String): Boolean;
begin
  Result := CheckExpressionKey(Expression, SC_ExpressionKey_VDP);
end;

function ClearExpressionKey(const Expression: String): String;
var
  i: Integer;
begin

  for i := Length(Expression) downto 1 do
    if Expression[i] = ',' then Exit(Trim(Copy(Expression, 1, i - 1)));

  Result := Expression;

end;

function PureValueText(const Value: String): String;
var
  i, l: Integer;
  InStr, DblQuote: Boolean;
  CRLF: Byte;
begin

  Result := '';
  InStr := False;
  DblQuote := False;
  CRLF := 0;
  l := Length(Value);

  for i := 1 to l do begin

    if Value[i] = '''' then

      if DblQuote then begin

        DblQuote := False;
        Continue;

      end else

        if i < l then begin

          DblQuote := InStr and (Value[i + 1] = '''');
          if not DblQuote then begin

            InStr := not InStr;
            if InStr then Continue;

          end;

        end else Continue; { чтобы не отправлялась последняя кавычка }

    if InStr then Result := Result + Value[i]
    else

      if (CRLF = 0) and (Value[i] = '#') and (i < l - 6) and SameText(Copy(Value, i, 6), '#$D#$A') then begin

        Result := Result + #$D#$A;
        CRLF := 5;

      end else

        if CRLF > 0 then Dec(CRLF);

  end;

  if (l > 3) and (Value[l] = '.') and (Value[l - 1] = '.') and (Value[l - 2] = '.') and (Value[l - 3] = '''') then begin

    l := Length(Result);
    if (l > 1) and ((Result[l - 1] <> #$D) or (Result[l] <> #$A)) then Result := Result + #$D#$A;
    Result := Result + '...';

  end;

end;

function Max(const Args: array of Integer): Integer;
var
  I: Integer;
begin

  Result := - MaxInt;
  for I in Args do
    Result := Max(I, Result);

end;

initialization

  LoadParams;

finalization

  SaveParams;

end.
