unit uTypes;

(*********************************************************)
(*                                                       *)
(*                        Hello!)                        *)
(*                                                       *)
(*********************************************************)

interface

type

  TData = array of Byte;

  TIntegerArray = array of Integer;
  TStringArray = array of String;

  BLOB = RawByteString; // too long)

  TBOM = (bomForward, bomBackward);

implementation

end.
