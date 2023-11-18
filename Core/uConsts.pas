unit uConsts;

interface

const

  CRLF = #13#10;
  CR = #13;
  LF = #10;
  TAB = #9;

  SC_HexCharSign = '#$';

  { TODO -oVasilyevSM -cComponents : Это не то же самое, что и BOM_UTF8? }
  Signature_UTF8: RawByteString = AnsiChar($EF) + AnsiChar($BB) + AnsiChar($BF);

  BOM_UTF8 = #$EF#$BB#$BF;
  BOM_UTF16BE = #$FF#$FF;
  BOM_UTF16LE = #$FF#$FE;

  IC_MaxDoubleScale = 9;

  NULLGUID: TGUID = '{00000000-0000-0000-0000-000000000000}';

implementation

end.
