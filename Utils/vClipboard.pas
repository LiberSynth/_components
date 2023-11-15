unit vClipboard;

interface

{ TODO -oVasilyev : -> vUtils }
procedure StrToClipboard(const Value: String);
//procedure BitmapToClipboard..

implementation

uses
  Windows, Clipbrd;

procedure StrToClipboard(const Value: String);
var
  Size: Integer;
  Data: THandle;
  DataPtr: Pointer;
  Str: String;
begin
  if Length(Value) > 0 then begin
    Str := String(Value);
    if not IsClipboardFormatAvailable(CF_UNICODETEXT) then
      { �������� ������� ����� }
      Clipboard.AsText:= Str
    else begin
      Size := Length(Str) shl 1 + 2;
      Data := GlobalAlloc(GMEM_MOVEABLE + GMEM_DDESHARE, Size);
      try
        DataPtr := GlobalLock(Data);
        try
          Move(Pointer(Str)^, DataPtr^, Size);
          { ������� ������� �������� }
          Clipboard.Open;
          { ������� Unicode ������ }
          Clipboard.SetAsHandle(CF_UNICODETEXT, Data);
          { ������� ������� �������� }
          Clipboard.Close;
        finally
          GlobalUnlock(Data);
        end;
      except
        GlobalFree(Data);
      end;
    end;
  end;
end;

end.
