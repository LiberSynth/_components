unit uConsts;

(*********************************************************)
(*                                                       *)
(*                        Hello!)                        *)
(*                                                       *)
(*********************************************************)

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

  IC_MaxDoubleScale = 9;

  NULLGUID: TGUID = '{00000000-0000-0000-0000-000000000000}';

implementation

end.
