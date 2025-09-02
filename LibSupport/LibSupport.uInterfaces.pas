unit LibSupport.uInterfaces;

interface

type

  ILSLibraryMarker = interface

    ['{56F5A32B-9889-4766-A635-7360DDC9762D}']

  end;

  ILSLibrary = interface

    ['{5EC0A5E8-F06D-4A6F-A1CD-512E40600AD2}']

    procedure RegisterTask(const _Name: WideString); safecall;

  end;

implementation

end.
