unit vTypes;

{TODO -oVasilyevSM -cdeprecatred unit : -> Core }

interface

uses
  { VCL }
  SysUtils;

const

  { TODO -oVasilyevSM -cdeprecatred unit : -> to new unit vConsts.pas }
  GUID_NULL: TGUID = '{00000000-0000-0000-0000-000000000000}';

  CRLF = #13#10;
  CR = #13;
  LF = #10;
  TAB = #9;

  BOM_UTF8 = #$EF#$BB#$BF;
  BOM_UTF16BE = #$FF#$FF;
  BOM_UTF16LE = #$FF#$FE;

  {TODO -oVasilyevSM -cdeprecatred unit : использовать только для часто используемых текстов }
  {TODO -oVasilyevSM -cdeprecatred unit : -> vConsts }

  SC_BooleanConvertError = '%s is not a valid Boolean value';
  SC_UnterminatedString = 'Unterminated String';

  SC_ParamInvalidDataType = 'Param data type is not %s';
  SC_ParamNotFound = 'Param ''%s'' not found';

  SC_FileError_SpecifyDirectory = 'Specify folder';
  SC_FileError_DirectoryNotFound = 'Folder ''%s'' not found';

  SC_ParamRead_UnterminatedLongComment = 'Unterminated long comment';
  SC_ParamRead_UnterminatedParamName = 'Unterminated param name: %s; LastParam: %s';
  SC_ParamRead_EmptyParamName = 'Empty param name, LastParam: %s';
  SC_ParamRead_InvalidParamName = 'Param name ''%s'' is invalid';
  SC_ParamRead_UnterminatedParamType = 'Unterminated param type: %s';
  SC_ParamRead_EmptyParamType = 'Empty param type';
  SC_ParamRead_UnterminatedParam = 'Unterminated param ''%s''';

  SC_PDT_Unknown  = 'Unknown';
  SC_PDT_Boolean  = 'Boolean';
  SC_PDT_Integer  = 'Integer';
  SC_PDT_Float    = 'Float';
  SC_PDT_DateTime = 'DateTime';
  SC_PDT_String   = 'String';
  SC_PDT_GUID     = 'GUID';
  SC_PDT_BLOB     = 'BLOB';
  SC_PDT_Params   = 'Params';

  IC_MaxDoubleScale = 9;

type

  EStringsReadException = class(Exception)

  private

    FPosition: Integer;

  public

    constructor Create(const _Msg: String; _Position: Integer);
    constructor CreateFmt(const _Msg: String; const _Args: array of const; _Position: Integer);

    property Position: Integer read FPosition;

  end;

  EParamsReadException = class(EStringsReadException);

  EParamsException = class(Exception);

  EFileError = class(Exception);

  TData = array of Byte;

  TIntegerArray = array of Integer;
  TStringArray = array of String;

function GetStringArray(const Source: array of String): TStringArray;

procedure AddToArray(var SA: TStringArray; const Value: String); overload;
procedure AddToArray(var IA: TIntegerArray; const Value: Integer); overload;

function CopyArray(const Source: TStringArray): TStringArray; overload;
function CopyArray(const Source: TIntegerArray): TIntegerArray; overload;

function ArrayIndexOf(const Value: String; const SA: TStringArray; CaseSensitive: Boolean = False): Integer; overload;
function ArrayIndexOf(const Value: Integer; const IA: TIntegerArray): Integer; overload;

function ExistsInArray(const Value: String; const SA: TStringArray): Boolean; overload;
function ExistsInArray(const Value: Integer; const IA: TIntegerArray): Boolean; overload;

procedure DelimStrToArray(var SA: TStringArray; S: String; WordDelims: TSysCharSet = [';', ',']); overload;
function DelimStrToArray(S: String; WordDelims: TSysCharSet = [';', ',']): TStringArray; overload;

implementation

function GetStringArray(const Source: array of String): TStringArray;
var
  L: Integer;
begin

  L := Length(Source);
  SetLength(Result, L);
  if L > 0 then Move((@Source[0])^, Result[0], SizeOf(Source));

end;

procedure AddToArray(var SA: TStringArray; const Value: String);
var
  L: Integer;
begin

  L := Length(SA);
  SetLength(SA, L + 1);
  SA[L] := Value;

end;

procedure AddToArray(var IA: TIntegerArray; const Value: Integer);
var
  L: Integer;
begin

  L := Length(IA);
  SetLength(IA, L + 1);
  IA[L] := Value;

end;

function CopyArray(const Source: TStringArray): TStringArray;
begin
  Result := Copy(Source, 0, Length(Source));
end;

function CopyArray(const Source: TIntegerArray): TIntegerArray;
begin
  Result := Copy(Source, 0, Length(Source));
end;

function ArrayIndexOf(const Value: String; const SA: TStringArray; CaseSensitive: Boolean): Integer;

  function _Same(const S1, S2: String): Boolean;
  begin

    if CaseSensitive then Result := S1 = S2
    else Result := SameText(S1, S2);

  end;

var
  i: Integer;
begin

  for i := Low(SA) to High(SA) do
    if _Same(SA[i], Value) then Exit(i);

  Result := -1;

end;

function ArrayIndexOf(const Value: Integer; const IA: TIntegerArray): Integer;
var
  i: Integer;
begin

  for i := Low(IA) to High(IA) do
    if IA[i] = Value then Exit(i);

  Result := -1;

end;

function ExistsInArray(const Value: String; const SA: TStringArray): Boolean;
begin
  Result := ArrayIndexOf(Value, SA) > -1;
end;

function ExistsInArray(const Value: Integer; const IA: TIntegerArray): Boolean;
begin
  Result := ArrayIndexOf(Value, IA) > -1;
end;

function WordCount(const S: string; const WordDelims: TSysCharSet): Integer;
var
  i, L: Cardinal;
begin

  Result := 0;
  i := 1;
  L := Length(S);

  while i <= L do begin

    while (i <= L) and CharInSet(S[i],WordDelims) do Inc(i);

	  if i <= L then Inc(Result);

    while (i <= L) and not CharInSet(S[i],WordDelims) do Inc(i);

  end;

end;

const
  SpacesSet = [' ', #13, #10, #9];

function RemoveLeadingSpaces(S: String): String; overload;
var
	i: Integer;
begin

	for i := 1 to Length(S) do
		if not CharInSet(S[i], SpacesSet) then
			Exit(Copy(S, i, Length(S)));

	Result := '';

end;

function FindFirstDelimiter(S: String; Delim: TSysCharSet): Integer;
var
	i: Integer;
begin

  for i := 1 to Length(S) do
    if CharInSet(S[i], Delim) then
      Exit(i);

  Result := 0;

end;

function RemoveMultiSpaces(S: String): String;
var
  i, Index: Integer;
begin

	Index := 0;
	Result := '';
	for i := 1 to Length(S) do

		if CharInSet(S[i], SpacesSet) then

      if Index <> 0 then begin

        if Result = '' then
          Result := Copy(S, Index, i - Index)
        else
          Result := Result + ' ' + Copy(S, Index, i - Index);

        Index := 0;

      end else

    else if Index = 0 then

      Index := i;

  if Index <> 0 then

    if Result = '' then

      Result := Copy(S, Index, MaxInt)

    else Result := Result + ' ' + Copy(S, Index, MaxInt);

end;

function ReadToDelimiter(var S: String; Delim: TSysCharSet; LeaveDelimiter: Boolean = False) : String;
var
	Index: Integer;
begin

	S := RemoveLeadingSpaces(S);
	Index := FindFirstDelimiter(S, Delim);

	if Index = 0 then begin

		Result := RemoveMultiSpaces(S);
		S := '';

	end else begin

		Result := RemoveMultiSpaces(Copy(S, 1, Index - 1));
		if LeaveDelimiter then
      S := Copy(S, Index, Length(S))
		else
      S := Copy(S, Index + 1, Length(S));

	end;

end;

procedure DelimStrToArray(var SA: TStringArray; S: String; WordDelims: TSysCharSet);
var
  i: Integer;
  W: String;
begin

  SetLength(SA, WordCount(S, WordDelims));
  i := 0;

  while Length(S) > 0 do begin

    W := Trim(ReadToDelimiter(S, WordDelims));
    if Length(W) > 0 then begin

      SA[i] := W;
      Inc(i);

    end;

  end;

end;

function DelimStrToArray(S: String; WordDelims: TSysCharSet): TStringArray;
begin
  DelimStrToArray(Result, S, WordDelims);
end;

{ EStringsReadException }

constructor EStringsReadException.Create(const _Msg: String; _Position: Integer);
begin
  inherited Create(_Msg);
  FPosition := _Position;
end;

constructor EStringsReadException.CreateFmt(const _Msg: String; const _Args: array of const; _Position: Integer);
begin
  inherited CreateFmt(_Msg, _Args);
  FPosition := _Position;
end;

end.
