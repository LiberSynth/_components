unit uConsts;

(**********************************************************)
(*                                                        *)
(*                     Liber Sunth Co                     *)
(*                                                        *)
(**********************************************************)

interface

const

  CRLF = #13#10;
  CR = #13;
  LF = #10;
  TAB = #9;

  SC_HEX_CHAR_SIGN = '#$';

  WC_BOM_FWD = $FEFF;
  WC_BOM_BWD = $FFFE;

  BOM_UTF16BE = #$FF#$FF;
  BOM_UTF16LE = #$FF#$FE;
  BOM_UTF8    = #$EF#$BB#$BF;

  IC_MAX_DOUBLE_SCALE = 9;

  NULLGUID: TGUID = '{00000000-0000-0000-0000-000000000000}';

  AC_HEX_CHARS: array[0..15] of Char = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
  SC_HEX_CHARS     = ['0'..'9', 'A'..'F'];
  SC_INTEGER_CHARS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  SC_TYPED_CHARS   = [' '..'~', #128..#255];

implementation

end.
