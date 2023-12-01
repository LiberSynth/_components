unit uTypes;

(**********************************************************)
(*                                                        *)
(*                     Liber Sunth Co                     *)
(*                                                        *)
(**********************************************************)

interface

type

  TData = array of Byte;

  TIntegerArray = array of Integer;
  TStringArray = array of String;

  BLOB = RawByteString; // RawByteString is too long to write everywhere)

  TBOM = (bomForward, bomBackward);

  TProc = procedure;
  TProcedure = procedure () of object;

implementation

end.
