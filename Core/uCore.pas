unit uCore;

(*********************************************************)
(*                                                       *)
(*                        Hello!)                        *)
(*                                                       *)
(*********************************************************)

interface

uses
  { VCL }
  SysUtils;

type

  ECoreException = class(Exception);

  EUncomplitedMethod = class(ECoreException)

  public

    constructor Create;

  end;

implementation

{ EUncomplitedMethod }

constructor EUncomplitedMethod.Create;
begin
  inherited Create('Complete this method');
end;

end.
