unit uClipboard;

interface

{ TODO 5 -oVasilyevSM -cuClipboard: BitmapToClipboard etc }
procedure StrToClipboard(const Value: String);

implementation

uses
  Windows, Clipbrd;

procedure StrToClipboard(const Value: String);
var
  Size: Integer;
  Data: THandle;
  DataPtr: Pointer;
begin

  if Length(Value) > 0 then

    if not IsClipboardFormatAvailable(CF_UNICODETEXT) then

      Clipboard.AsText:= Value

    else begin

      Size := Length(Value) shl 1 + 2;
      Data := GlobalAlloc(GMEM_MOVEABLE + GMEM_DDESHARE, Size);
      try

        DataPtr := GlobalLock(Data);
        try

          Move(Pointer(Value)^, DataPtr^, Size);
          { Вставка кодовой страницы }
          Clipboard.Open;
          { Вставка Unicode текста }
          Clipboard.SetAsHandle(CF_UNICODETEXT, Data);
          { Вставка кодовой страницы }
          Clipboard.Close;

        finally
          GlobalUnlock(Data);
        end;

      except
        GlobalFree(Data);
      end;

    end;

end;

end.
