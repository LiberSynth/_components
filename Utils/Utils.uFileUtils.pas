unit Utils.uFileUtils;

(*******************************************************************************************)
(*            _____          _____          _____          _____          _____            *)
(*           /\    \        /\    \        /\    \        /\    \        /\    \           *)
(*          /::\____\      /::\    \      /::\    \      /::\    \      /::\    \          *)
(*         /:::/    /      \:::\    \    /::::\    \    /::::\    \    /::::\    \         *)
(*        /:::/    /        \:::\    \  /::::::\    \  /::::::\    \  /::::::\    \        *)
(*       /:::/    /          \:::\    \ :::/\:::\    \ :::/\:::\    \ :::/\:::\    \       *)
(*      /:::/    /            \:::\    \ :/__\:::\    \ :/__\:::\    \ :/__\:::\    \      *)
(*     /:::/    /             /::::\    \ \   \:::\    \ \   \:::\    \ \   \:::\    \     *)
(*    /:::/    /     _____   /::::::\    \ \   \:::\    \ \   \:::\    \ \   \:::\    \    *)
(*   /:::/    /     /\    \ /:::/\:::\    \ \   \:::\ ___\ \   \:::\    \ \   \:::\____\   *)
(*  /:::/____/     /::\    /:::/  \:::\____\ \   \:::|    | \   \:::\____\ \   \:::|    |  *)
(*  \:::\    \     \:::\  /:::/    \::/    / :\  /:::|____| :\   \::/    / :\  /:::|____|  *)
(*   \:::\    \     \:::\/:::/    / \/____/ :::\/:::/    / :::\   \/____/ :::\/:::/    /   *)
(*    \:::\    \     \::::::/    /  \:::\   \::::::/    /  \:::\    \  |:::::::::/    /    *)
(*     \:::\    \     \::::/____/    \:::\   \::::/    /    \:::\____\ |::|\::::/    /     *)
(*      \:::\    \     \:::\    \     \:::\  /:::/    / :\   \::/    / |::| \::/____/      *)
(*       \:::\    \     \:::\    \     \:::\/:::/    / :::\   \/____/  |::|  ~|            *)
(*        \:::\    \     \:::\    \     \::::::/    /  \:::\    \      |::|   |            *)
(*         \:::\____\     \:::\____\     \::::/    /    \:::\____\     \::|   |            *)
(*          \::/    /      \::/    /      \::/____/      \::/    /      \:|   |            *)
(*           \/____/        \/____/        ~~             \/____/        \|___|            *)
(*                                                                                         *)
(*******************************************************************************************)

interface

uses
  { VCL }
  Windows, Controls, SysUtils, ShlObj, ActiveX, ShellAPI, Forms, Classes, IOUtils, System.AnsiStrings,
  { LeberSynth }
  uConsts, Core.uTypes, uStrUtils, uCore, uPathRunner;

type

  TFileAttribute = (

    ftArchive, ftHidden, ftNormal, ftNotContentIndexed, ftOffline, ftReadOnly, ftSystem, ftTemporary, ftDirectory,
    ftDevice, ftSparseFile, ftReparsePoint, ftCompressed, ftEncrypted

  );
  TFileAttributes = set of TFileAttribute;

  TFileInfoKey = (

      fkCompanyName, fkFileDescription, fkFileVersion, fkInternalName, fkLegalCopyright, fkLegalTradeMarks,
      fkOriginalFileName, fkProductName, fkProductVersion, fkComments

  );

  TSpecialFolder = (

      sfDesktop, sfInternet, sfPrograms, sfControls, sfPrinters, sfPersonal, sfFavorites, sfStartUp, sfRecent, sfSendto,
      sfBitBucket, sfStartMenu, sfMyDocuments, sfMyMusic, sfMyVideo, sfDesktopDirectory, sfDrivers, sfNetwork,
      sfNethood, sfFonts, sfTemplates, sfCommonStartMenu, sfCommonPrograms, sfCommonStartUp, sfCommonDesktopDirectory,
      sfAppData, sfPrinthood, sfLocalAppData, sfAltStartUp, sfCommonAltStartUp, sfCommonFavorites, sfInternetCache,
      sfCookies, sfHistory, sfCommonAppData, sfWindows, sfSystem, sfProgramFiles, sfMyPictures, sfPorfile, sfSystemX86,
      sfProgramFilesX86, sfProgramFilesCommon, sfProgramFilesCommonX86, sfCommonTemplates, sfCommonDocuments,
      sfCommonAdminTools, sfAdminTools, sfConnections, sfCommonMusic, sfCommonPictures, sfCommonVideo, sfResources,
      sfResourcesLocalized, sfCommonOEMLinks, sfCDBurnArea

  );

function CheckFileType(const FileName, Extension: String): Boolean;
function CheckDir(const Path: String): String;
procedure CheckDirExisting(Path: String);
procedure CheckFileExisting(Path: String);
function PureDir(const Path: String): String; { delete last \ }
procedure AddSlash(var Path: String); { SysUtils.IncludeTrailingBackslash }
function SubDir(const Dir, SubDir: String): String;
function LevelUp(const Path: String): String;
function PureFileName(const FileName: String): String; { without path and extension }
function ExeName: String;
function ExeDir: String;
function PackageFileName(Instance: LongWord): String;
function PackageName(Instance: LongWord): String;
function PackageDir(Instance: LongWord): String;

function GetFileAttributes_(const FileName: String): TFileAttributes;
procedure SetFileAttributes_(const FileName: String; FileAttributes: TFileAttributes);

function FileInfo(const FileName: String; FileInfoKey: TFileInfoKey): String; overload;
function FileInfo(FileInfoKey: TFileInfoKey): String; overload;
procedure FileVersionParts(FileVersionStr: String; var MajorVersion, MinorVersion, Release, Build: SmallInt); overload;
procedure FileVersionParts(var MajorVersion, MinorVersion, Release, Build: SmallInt); overload;
function FileVersionStr(MajorVersion, MinorVersion, Release, Build: SmallInt): String;
function MajorVersion: SmallInt;
function MinorVersion: SmallInt;
function Release: SmallInt;
function Build: SmallInt;

function FileSize(const FilePath: String): Int64;
function DirSize(Dir: String): Int64;
function DiskSpace(const Path: String; var TotalSpace, FreeAvailable: Int64): Boolean;
function DiskSize(const Path: String): Int64;
function DiskTotalSize(const Path: String): Int64;
function DiskFreeSpace(const Path: String): Int64;

type

  TStorageItemType = (siDisk, siDirectory, siFile);

  TStorageItem = record

    Name: String;
    ItemType: TStorageItemType;

  end;

  TStorageItemArray = array of TStorageItem;

  EFileException = class(ECoreException);

function GetLogicalDrives: TStringArray;
function Dir(const _Root: String): TStringArray;
function DirEx(const _Root: String): TStorageItemArray;

function FileTimeToDateTime(FileTime: TFileTime): TDateTime;
function GetLastWriteFileTime(const FileName: String): TFileTime;
function GetLastWriteDateTime(const FileName: String): TDateTime;

function GetSpecialFolder(var Folder: String; FolderType: TSpecialFolder): Boolean;
function OpenFolderDlg(Owner: TWinControl; const Text: String; var Folder: String; Root: TSpecialFolder = sfDesktop): Boolean; deprecated; { use TFileOpenDialog }

function FindTopNearest(const InitPath: String): String;

function DeleteFileToRecycle(const FileName: String): Boolean;
function DeleteFileToTemp(const FileName, TempDir: String): Boolean;

procedure DataToFile(const FilePath: String; const Data: TData);
function FileToData(const FilePath: String): TData;

procedure StrToFile(const Value, FileName: String);
function FileToStr(const FileName: String): String;

type

  TFileProc = reference to procedure(const FileName: String; MaskMatches: Boolean; var Terminated: Boolean);

procedure ExploreFiles(const Path, Masks: String; Recursive: Boolean; Handler: TFileProc); overload;
procedure ExploreFiles(const Path, Masks: String; Handler: TFileProc); overload;
procedure ExploreFiles(const Path: String; Recursive: Boolean; Handler: TFileProc); overload;
procedure ExploreFiles(const Path: String; Handler: TFileProc); overload;

implementation

type

  TFileExplorer = class

  strict private

    FPath: String;
    FMasks: String;
    FRecursive: Boolean;
    FInitialized: Boolean;
    FTerminated: Boolean;
    FMaskList: TArray<TArray<String>>;

    procedure Init;

    function CheckMasks(const _Value: String): Boolean;
    function CheckMask(const _Value: String; const _Mask: TArray<String>): Boolean;
    function CheckSingleMask(const _Value, _Mask: String): Boolean;
    procedure RaiseInvalidMaskError(const _Mask: String);

    property Terminated: Boolean read FTerminated;
    property Initialized: Boolean read FInitialized;
    property MaskList: TArray<TArray<String>> read FMaskList;

  public

    procedure Run(_Handler: TFileProc);

    property Path: String read FPath write FPath;
    property Masks: String read FMasks write FMasks;
    property Recursive: Boolean read FRecursive write FRecursive;

  end;

function CheckFileType(const FileName, Extension: String): Boolean;
var
  p: Integer;
begin
  p := LastPos('.', FileName);
  Result := (p > 0) and SameText(Copy(FileName, p, Length(FileName)), '.' + Extension);
end;

function CheckDir(const Path: String): String;
begin

  if Length(Path) = 0 then raise EFileException.Create('Specify folder');
  Result := Path;
  AddSlash(Result);
  if not DirectoryExists(Result) then raise EFileException.CreateFmt('Folder ''%s'' not found', [Result]);

end;

procedure CheckDirExisting(Path: String);
var
  Pth: String;
begin

  Pth := '';

  repeat

    Pth := Pth + ReadStrTo(Path, '\') + '\';
    if not DirectoryExists(Pth) then
      CreateDir(Pth);

  until Path = '';

end;

procedure CheckFileExisting(Path: String);
begin
  CheckDirExisting(ExtractFilePath(Path));
  if not FileExists(Path) then
    TFileStream.Create(Path, fmCreate).Free;
end;

function PureDir(const Path: String): String;
begin
  if (Length(Path) > 0) and (Path[Length(Path)] = '\') then Result := Copy(Path, 1, Length(Path) - 1)
  else Result := Path;
end;

procedure AddSlash(var Path: String);
begin
  if (Length(Path) > 0) and (Path[Length(Path)] <> '\') then Path := Path + '\';
end;

function SubDir(const Dir, SubDir: String): String;
begin
  Result := PureDir(Dir) + '\' + PureDir(SubDir);
end;

function LevelUp(const Path: String): String;
begin

  Result := PureDir(Path);
  while (Length(Result) > 0) and (Result[Length(Result)] <> '\') do
    Result := Copy(Result, 1, Length(Result) - 1);
  Result := PureDir(Result);

end;

function PureFileName(const FileName: String): String;
begin
  Result := ExtractFileName(FileName);
  Result := Copy(Result, 1, LastDelimiter('.', Result) - 1);
end;

function ExeName: String;
begin
  Result := PureFileName(ParamStr(0));
end;

function ExeDir: String;
begin
  Result := ExtractFileDir(ParamStr(0));
end;

function PackageFileName(Instance: LongWord): String;
begin

  SetLength(Result, MAX_PATH);
  GetModuleFileName(Instance, PChar(Result), MAX_PATH);
  SetLength(Result, StrLen(PChar(Result)));

end;

function PackageName(Instance: LongWord): String;
begin
  Result := PureFileName(PackageFileName(Instance));
end;

function PackageDir(Instance: LongWord): String;
begin
  Result := ExtractFileDir(PackageFileName(Instance));
end;

function FileInfo(const FileName: String; FileInfoKey: TFileInfoKey): String;
const

  CA_FileInfoStr: array[TFileInfoKey] of String = (

      'CompanyName', 'FileDescription', 'FileVersion', 'InternalName', 'LegalCopyright', 'LegalTradeMarks',
      'OriginalFileName', 'ProductName', 'ProductVersion', 'Comments'

  );

var
  Dump: DWORD;
  Size: Integer;
  Buffer: PAnsiChar;
  TransBuffer: PAnsiChar;
  VersionPointer: PChar;
  Temp: Integer;
  CalcLangCharSet: AnsiString;
begin

  Size := GetFileVersionInfoSize(PChar(FileName), Dump);
  Buffer := AnsiStrAlloc(Size + 1);
  try

    GetFileVersionInfo(PChar(FileName), 0, Size, Buffer);
    VerQueryValue(Buffer, '\VarFileInfo\Translation', Pointer(TransBuffer), Dump);

    if Dump >= 4 then begin

      Temp := 0;
      System.AnsiStrings.StrLCopy(@Temp, TransBuffer, 2);
      CalcLangCharSet := AnsiString(IntToHex(Temp, 4));
      System.AnsiStrings.StrLCopy(@Temp, TransBuffer + 2, 2);
      CalcLangCharSet := CalcLangCharSet + AnsiString(IntToHex(Temp, 4));

    end;

    VerQueryValue(Buffer, PChar('\StringFileInfo\' + String(CalcLangCharSet) + '\' + CA_FileInfoStr[FileInfoKey]),
        Pointer(VersionPointer), Dump);

    if Dump > 1 then begin

      SetLength(Result, Dump);
      Result := VersionPointer;

    end  else Result := '';

  finally
    System.AnsiStrings.StrDispose(Buffer);
  end;

end;

function FileInfo(FileInfoKey: TFileInfoKey): String;
begin
  Result := FileInfo(ParamStr(0), FileInfoKey);
end;

procedure FileVersionParts(FileVersionStr: String; var MajorVersion, MinorVersion, Release, Build: SmallInt);
begin

  { TODO -oVasilyevSM -cdeprecatred unit : maybe faster by SysUtils.GetFileVersion }
  MajorVersion := StrToInt(ReadStrTo(FileVersionStr, '.'));
  MinorVersion := StrToInt(ReadStrTo(FileVersionStr, '.'));
  Release := StrToInt(ReadStrTo(FileVersionStr, '.'));
  Build := StrToInt(FileVersionStr);

end;

procedure FileVersionParts(var MajorVersion, MinorVersion, Release, Build: SmallInt);
begin
  FileVersionParts(FileInfo(ParamStr(0), fkFileVersion), MajorVersion, MinorVersion, Release, Build);
end;

function FileVersionStr(MajorVersion, MinorVersion, Release, Build: SmallInt): String;
begin
  Result := Format('%d.%d.%d.%d', [MajorVersion, MinorVersion, Release, Build]);
end;

function MajorVersion: SmallInt;
var
  i: SmallInt;
begin
  FileVersionParts(Result, i, i, i);
end;

function MinorVersion: SmallInt;
var
  i: SmallInt;
begin
  FileVersionParts(i, Result, i, i);
end;

function Release: SmallInt;
var
  i: SmallInt;
begin
  FileVersionParts(i, i, Result, i);
end;

function Build: SmallInt;
var
  i: SmallInt;
begin
  FileVersionParts(i, i, i, Result);
end;

function FileSize(const FilePath: String): Int64;
var
  SR: TSearchRec;
  LE: Integer;
begin

  Result := 0;
  LE := FindFirst(FilePath, faAnyFile, SR);
  try

    if LE = 0 then Result := SR.Size
    else RaiseLastOSError(LE);

  finally
    FindClose(SR);
  end;

end;

type

  TDirSize = class(TPathRunner)

  private

    FSize: Int64;

    constructor Create(const _Dir: String);

    procedure Proc(const _FilePath: String);

  end;

{ TDirSize }

constructor TDirSize.Create(const _Dir: String);
begin
  inherited Create(Proc);
  Execute(_Dir);
end;

procedure TDirSize.Proc(const _FilePath: String);
begin
  Inc(FSize, Current.Size);
end;

function DirSize(Dir: String): Int64;
begin

  AddSlash(Dir);
  with TDirSize.Create(Dir) do
    try

      Result := FSize;

    finally
      Free;
    end;

end;

function DiskSpace(const Path: String; var TotalSpace, FreeAvailable: Int64): Boolean;
var
  DiskPath: array[0..4] of Char;
  Ptr: PChar;
begin

  DiskPath[0] := Path[1];
  DiskPath[1] := ':';
  DiskPath[2] := '\';
  DiskPath[3] := #0;
  Ptr := DiskPath;
  Result := GetDiskFreeSpaceEx(Ptr, FreeAvailable, TotalSpace, nil);

end;

function DiskSize(const Path: String): Int64;
var
  FreeAvailable, TotalSpace: Int64;
begin
  if DiskSpace(Path, TotalSpace, FreeAvailable) then Result := TotalSpace - FreeAvailable
  else Result := -1;
end;

function DiskTotalSize(const Path: String): Int64;
var
  FreeAvailable, TotalSpace: Int64;
begin
  if DiskSpace(Path, TotalSpace, FreeAvailable) then Result := TotalSpace
  else Result := -1;
end;

function DiskFreeSpace(const Path: String): Int64;
var
  FreeAvailable, TotalSpace: Int64;
begin
  if DiskSpace(Path, TotalSpace, FreeAvailable) then Result := FreeAvailable
  else Result := -1;
end;

function GetLogicalDrives: TStringArray;
begin
  Result := TStringArray(TDirectory.GetLogicalDrives);
end;

function Dir(const _Root: String): TStringArray;
var
  SR: TSearchRec;
  L: Integer;
begin

  SetLength(Result, 0);
  if FindFirst(_Root + '*.*', faAnyFile, SR) = 0 then
    try

      repeat

        if (SR.Name <> '..') and (SR.Name <> '.') then begin
          L := Length(Result);
          SetLength(Result, L + 1);
          Result[L] := SR.Name;
        end;

      until FindNext(SR) <> 0;

    finally
      FindClose(SR);
    end;

end;

function DirEx(const _Root: String): TStorageItemArray;
var
  SA: TStringArray;
  i: Integer;
  SR: TSearchRec;
  L: Integer;
begin

  if Length(_Root) = 0 then begin

    SA := TStringArray(TDirectory.GetLogicalDrives);
    SetLength(Result, Length(SA));
    for i := Low(SA) to High(SA) do

      with Result[i] do begin

        Name := SA[i];
        ItemType := siDisk;

      end;

  end else begin

    SetLength(Result, 0);

    if FindFirst(_Root + '*.*', faAnyFile, SR) = 0 then
      try

        repeat

          if (SR.Name <> '..') and (SR.Name <> '.') then begin

            L := Length(Result);
            SetLength(Result, L + 1);

            with Result[L] do begin

              Name := SR.Name;
              if SR.Attr and faDirectory <> 0 then ItemType := siDirectory
              else ItemType := siFile;

            end;

          end;

        until FindNext(SR) <> 0;

      finally
        FindClose(SR);
      end;

  end;

end;

function FileTimeToDateTime(FileTime: TFileTime): TDateTime;
var
  LFT: TFileTime;
  ST: TSystemTime;
begin

  FileTimeToLocalFileTime(FileTime, LFT);
  FileTimeToSystemTime(LFT, ST);
  Result := EncodeDate(ST.wYear, ST.wMonth, ST.wDay) + EncodeTime(ST.wHour, ST.wMinute, ST.wSecond, ST.wMilliseconds);

end;

function GetLastWriteFileTime(const FileName: String): TFileTime;
var
  H: THandle;
begin
  H := FileOpen(FileName, fmOpenRead);
  if (H = INVALID_HANDLE_VALUE) or not GetFileTime(H, nil, nil, @Result) then
    RaiseLastOSError;
end;

function GetLastWriteDateTime(const FileName: String): TDateTime;
begin
  Result := FileTimeToDateTime(GetLastWriteFileTime(FileName));
end;

function FileAttributeToFlag(FileAttribute: TFileAttribute): Integer;
begin

  case FileAttribute of

    ftArchive:           Result := FILE_ATTRIBUTE_ARCHIVE;
    ftHidden:            Result := FILE_ATTRIBUTE_HIDDEN;
    ftNormal:            Result := FILE_ATTRIBUTE_NORMAL;
    ftNotContentIndexed: Result := FILE_ATTRIBUTE_NOT_CONTENT_INDEXED;
    ftOffline:           Result := FILE_ATTRIBUTE_OFFLINE;
    ftReadonly:          Result := FILE_ATTRIBUTE_READONLY;
    ftSystem:            Result := FILE_ATTRIBUTE_SYSTEM;
    ftTemporary:         Result := FILE_ATTRIBUTE_TEMPORARY;
    ftDirectory:         Result := FILE_ATTRIBUTE_DIRECTORY;
    ftDevice:            Result := FILE_ATTRIBUTE_DEVICE;
    ftSparseFile:        Result := FILE_ATTRIBUTE_SPARSE_FILE;
    ftReparsePoint:      Result := FILE_ATTRIBUTE_REPARSE_POINT;
    ftCompressed:        Result := FILE_ATTRIBUTE_COMPRESSED;
    ftEncrypted:         Result := FILE_ATTRIBUTE_ENCRYPTED;

  else
    Result := 0;
  end;

end;

function FlagsToFileAttributes(FileAttributeFlags: Integer): TFileAttributes;
var
  FA: TFileAttribute;
begin
  Result := [];
  for FA := Low(TFileAttribute) to High(TFileAttribute) do
    if FileAttributeFlags and FileAttributeToFlag(FA) <> 0 then Include(Result, FA);
end;

function FileAttributesToFlags(FileAttributes: TFileAttributes): Integer;
var
  FA: TFileAttribute;
begin
  Result := 0;
  for FA := Low(TFileAttribute) to High(TFileAttribute) do
    if FA in FileAttributes then Result := Result or FileAttributeToFlag(FA);
end;

function GetFileAttributes_(const FileName: String): TFileAttributes;
var
  FA: Integer;
begin
  FA := GetFileAttributes(PWideChar(FileName));
  if FA and INVALID_FILE_ATTRIBUTES = 0 then
    raise Exception.Create(SysErrorMessage(GetLastError));
  Result := FlagsToFileAttributes(FA);
end;

procedure SetFileAttributes_(const FileName: String; FileAttributes: TFileAttributes);
begin
  if not SetFileAttributes(PWideChar(FileName), FileAttributesToFlags(FileAttributes)) then
    raise Exception.Create(SysErrorMessage(GetLastError));
end;

function GetSpecialFolderFlag(RootFlag: TSpecialFolder): Integer;
begin

  case RootFlag of

    sfDesktop:                Result := CSIDL_DESKTOP;                  { ������� ���� (Desktop) ��� ������� ������������; ����������� �����, ���������� ������ ��������� ������������ ��� �������� }
    sfInternet:               Result := CSIDL_INTERNET;                 { �������� (Internet); ����������� �����, �������������� ������������ Internet }
    sfPrograms:               Result := CSIDL_PROGRAMS;                 { ��������� (Programs) ��� ������� ������������; ������� �������� �������, ���������� � ���� ������ �������� ������������, ����� ���������� ���������� �������� ������� }
    sfControls:               Result := CSIDL_CONTROLS;                 { ������ ���������� (Control Panel); ����������� �����, ���������� � ���� ����� ������ ������ ���������� }
    sfPrinters:               Result := CSIDL_PRINTERS;                 { �������� (Printers); ����������� �����, ���������� � ���� ���������������� �������� }
    sfPersonal:               Result := CSIDL_PERSONAL;                 { ��� ��������� (My Documents); ������� �������� �������, �������� ����� ������������ ��� ���������� }
    sfFavorites:              Result := CSIDL_FAVORITES;                { ��������� (Favorites) ��� ������� ������������; ������� �������� �������, �������� ����� ������������ ��������� ������������� ��������� }
    sfStartUp:                Result := CSIDL_STARTUP;                  { ������������ (Startup) ��� ������� ������������; ������� �������� �������, ������� �������� ���������������� ������ �������� "������������". ������� ��������� ��� ��������� ������ ���, ����� ������ ������������ ������ � Windows NT, ��� ����� �������� Windows 95/98 }
    sfRecent:                 Result := CSIDL_RECENT;                   { ��������� (Documents); ������� �������� �������, ���������� � ���� ������ �� ����� ��������� ���������, � �������� ������� ������� ������������ }
    sfSendto:                 Result := CSIDL_SENDTO;                   { ��������� (Send To); ������� �������� �������, ���������� � ���� ������ ���� Send To }
    sfBitBucket:              Result := CSIDL_BITBUCKET;                { ������� (Recycle Bin); }
    sfStartMenu:              Result := CSIDL_STARTMENU;                { ������� ���� (Start menu) ��� ������� ������������; ������� �������� �������, ���������� � ���� ������ ���� Start }
    sfMyDocuments:            Result := CSIDL_MYDOCUMENTS;              { Personal was just a silly name for My Documents }
    sfMyMusic:                Result := CSIDL_MYMUSIC;                  { "My Music" folder }
    sfMyVideo:                Result := CSIDL_MYVIDEO;                  { "My Videos" folder }
    sfDesktopDirectory:       Result := CSIDL_DESKTOPDIRECTORY;         { ������� �������� �������, �������� �������� ������� �������� ����� (Desktop directory) ��� ������� ������������; }
    sfDrivers:                Result := CSIDL_DRIVES;                   { ��� ��������� (My computer); ����������� �����, ���������� � ���� ��, ��� ��������� �� ��������� ����������: ���������� ��������, �������� � ������ ����������. ��� ����� ����� ����� ��������� � ���� ��������������� ������� ����� }
    sfNetwork:                Result := CSIDL_NETWORK;                  { ������� ��������� (Network Neighborhood); ����������� �����, �������������� ������� ������� �������� ���� }
    sfNethood:                Result := CSIDL_NETHOOD;                  { ������� �������� �������, �������� �������� ������� �������� ��������� (Network Neighborhood); }
    sfFonts:                  Result := CSIDL_FONTS;                    { ������ (Fonts); ����������� �����, ���������� ������ }
    sfTemplates:              Result := CSIDL_TEMPLATES;                { ������� (Templates); ������� �������� �������, �������� ����� ������������ �������� ���������� (����� ������������ ���� �������� "�������") }
    sfCommonStartMenu:        Result := CSIDL_COMMON_STARTMENU;         { ������� �������� �������, ���������� � ���� ����� ������ ���� Start, ������� ���������� � ���� �������������; }
    sfCommonPrograms:         Result := CSIDL_COMMON_PROGRAMS;          { ������� �������� �������, ���������� � ���� ����� ������ �������� ������������, ������� ���������� � ���� �������������; }
    sfCommonStartUp:          Result := CSIDL_COMMON_STARTUP;           { ������� �������� �������, ���������� � ���� ����� ���������, ������� ���������� � ����� Startup ��� ���� �������������; }
    sfCommonDesktopDirectory: Result := CSIDL_COMMON_DESKTOPDIRECTORY;  { ������� �������� �������, �������� ����� �������� ������� �������� ����� (Desktop directory), ������� ���������� �� ������� ������ ���� �������������; }
    sfAppData:                Result := CSIDL_APPDATA;                  { ������� �������� �������, �������� ����� ������������ ������, ����������� ��� ����������; }
    sfPrinthood:              Result := CSIDL_PRINTHOOD;                { ������� �������� �������, �������� ����� ������������ ������ �� ��������; }
    sfLocalAppData:           Result := CSIDL_LOCAL_APPDATA;            { <user name>\Local Settings\Applicaiton Data (non roaming) }
    sfAltStartUp:             Result := CSIDL_ALTSTARTUP;               { ������� �������� �������, ������� �������� ���������������� ���������������� ������ �������� "������������". }
    sfCommonAltStartUp:       Result := CSIDL_COMMON_ALTSTARTUP;        { ������� �������� �������, ���������� � ���� ����� ���������, ������� ���������� � ���������������� ����� Startup ��� ���� �������������; }
    sfCommonFavorites:        Result := CSIDL_COMMON_FAVORITES;         { ������� �������� �������, ���������� � ���� ����� ��������� ��������, ������� ���������� � ����� "���������" � ���� �������������; }
    sfInternetCache:          Result := CSIDL_INTERNET_CACHE;           { ������� �������� �������, �������� ����� ������������ ��� ���������� �������� ������, ���������� ��� ������ � Internet; }
    sfCookies:                Result := CSIDL_COOKIES;                  { ������� �������� �������, �������� ����� ������������ ��� Internet Cookies; }
    sfHistory:                Result := CSIDL_HISTORY;                  { ������� �������� �������, �������� ����� ������������ ��� �������� ������� ������ � Internet. }
    sfCommonAppData:          Result := CSIDL_COMMON_APPDATA;           { All Users\Application Data }
    sfWindows:                Result := CSIDL_WINDOWS;                  { GetWindowsDirectory() }
    sfSystem:                 Result := CSIDL_SYSTEM;                   { GetSystemDirectory() }
    sfProgramFiles:           Result := CSIDL_PROGRAM_FILES;            { C:\Program Files }
    sfMyPictures:             Result := CSIDL_MYPICTURES;               { C:\Program Files\My Pictures }
    sfPorfile:                Result := CSIDL_PROFILE;                  { USERPROFILE }
    sfSystemX86:              Result := CSIDL_SYSTEMX86;                { x86 system directory on RISC }
    sfProgramFilesX86:        Result := CSIDL_PROGRAM_FILESX86;         { x86 C:\Program Files on RISC }
    sfProgramFilesCommon:     Result := CSIDL_PROGRAM_FILES_COMMON;     { C:\Program Files\Common }
    sfProgramFilesCommonX86:  Result := CSIDL_PROGRAM_FILES_COMMONX86;  { x86 Program Files\Common on RISC }
    sfCommonTemplates:        Result := CSIDL_COMMON_TEMPLATES;         { All Users\Templates }
    sfCommonDocuments:        Result := CSIDL_COMMON_DOCUMENTS;         { All Users\Documents }
    sfCommonAdminTools:       Result := CSIDL_COMMON_ADMINTOOLS;        { All Users\Start Menu\Programs\Administrative Tools }
    sfAdminTools:             Result := CSIDL_ADMINTOOLS;               { <user name>\Start Menu\Programs\Administrative Tools }
    sfConnections:            Result := CSIDL_CONNECTIONS;              { Network and Dial-up Connections }
    sfCommonMusic:            Result := CSIDL_COMMON_MUSIC;             { All Users\My Music }
    sfCommonPictures:         Result := CSIDL_COMMON_PICTURES;          { All Users\My Pictures }
    sfCommonVideo:            Result := CSIDL_COMMON_VIDEO;             { All Users\My Video }
    sfResources:              Result := CSIDL_RESOURCES;                { Resource Direcotry }
    sfResourcesLocalized:     Result := CSIDL_RESOURCES_LOCALIZED;      { Localized Resource Direcotry }
    sfCommonOEMLinks:         Result := CSIDL_COMMON_OEM_LINKS;         { Links to All Users OEM specific apps }
    sfCDBurnArea:             Result := CSIDL_CDBURN_AREA;              { USERPROFILE\Local Settings\Application Data\Microsoft\CD Burning }

  else
    Result := 0;
  end;

end;

var
  pidlInitialFolder: PItemIDList;

function BrowseCallbackProc(hWnd: HWND; uMsg: UINT; lParam: LPARAM; lpData: LPARAM): Integer; stdcall;
begin

  Result := 0;
  case uMsg of
    BFFM_INITIALIZED: PostMessage(hWnd, BFFM_SETSELECTION, 0, Integer(pidlInitialFolder));
  end;

end;

function GetSpecialFolder(var Folder: String; FolderType: TSpecialFolder): Boolean;
var
  Malloc: IMalloc;
  pidlResult: PItemIDList;
  NullPos: Integer;
begin

  Result := Succeeded(SHGetMalloc(Malloc));
  try

    if Result then begin

      Result := Succeeded(SHGetSpecialFolderLocation(0, GetSpecialFolderFlag(FolderType), pidlResult));

      if Assigned(pidlResult) then

        try

          if Result then begin

            SetLength(Folder, MAX_PATH);
            Result := SHGetPathFromIDList(pidlResult, PChar(Folder));
            NullPos := Pos(#0, Folder);
            if NullPos > 0 then Folder := Copy(Folder, 1, NullPos - 1);

          end;

        finally
          Malloc.Free(pidlResult);
        end

    end;

  finally
    Malloc := nil;
  end;

end;

function OpenFolderDlg(Owner: TWinControl; const Text: String; var Folder: String; Root: TSpecialFolder): Boolean;
var
  BrowseInfo: TBrowseInfo;
  Malloc: IMalloc;
  InitFolder: String;
  Desktop: IShellFolder;
  pidlRoot, pidlResult: PItemIDList;
  DisplayName: String;
  CharsDone: ULONG;
  Attributes: DWORD;
begin

  Result := False;
  if Succeeded(SHGetMalloc(Malloc)) then

    try

      if (Folder <> '') and DirectoryExists(Folder) then InitFolder := Folder
      else InitFolder := '';

      if Succeeded(SHGetDesktopFolder(Desktop)) then
        try

          if Succeeded(SHGetSpecialFolderLocation(0, GetSpecialFolderFlag(Root), pidlRoot)) then
            try

              if Succeeded(Desktop.ParseDisplayName(0, nil, PChar(InitFolder), CharsDone, pidlInitialFolder, Attributes)) then
                try

                  SetLength(DisplayName, MAX_PATH);
                  FillChar(BrowseInfo, SizeOf(BrowseInfo), 0);

                  with BrowseInfo do begin

                    hwndOwner := Owner.Handle;
                    pidlRoot := pidlRoot;
                    pszDisplayName := PChar(DisplayName);
                    lpszTitle := PChar(Text);
                    ulFlags := BIF_STATUSTEXT;
                    lpfn := BrowseCallbackProc;
                    pidlResult := SHBrowseForFolder(BrowseInfo);

                  end;

                  if Assigned(pidlResult) then
                    try

                      SetLength(Folder, MAX_PATH);
                      if SHGetPathFromIDList(pidlResult, PChar(Folder)) then
                        Result := True;

                    finally
                      Malloc.Free(pidlResult);
                    end

                finally
                  Malloc.Free(pidlInitialFolder);
                end;

            finally
              Malloc.Free(pidlRoot);
            end;

        finally
          Desktop := nil;
        end;

    finally
      Malloc := nil;
    end;

end;

function FindTopNearest(const InitPath: String): String;

  function _LastSlashPos: Integer;
  var
    i: Integer;
  begin

    for i := Length(InitPath) - 1 downto 1 do
      if (i = 1) or (InitPath[i] = '\') then Exit(i);
    Result := 0;

  end;

begin

  if (Length(InitPath) = 0) or DirectoryExists(InitPath) then Result := InitPath
  else begin

    Result := FindTopNearest(Copy(InitPath, 1, _LastSlashPos));
    if Length(Result) = 0 then Result := ExeDir;

  end;

end;

function DeleteFileToRecycle(const FileName: String): Boolean;
var
  SHFileOpStruct: TSHFileOpStruct;
  Aborted: Bool;
begin

  Aborted := False;
  with SHFileOpStruct do begin

    Wnd := Application.Handle;
    wFunc := FO_DELETE;
    fFlags := FOF_SIMPLEPROGRESS + FOF_ALLOWUNDO + FOF_NOCONFIRMATION;
    pFrom := PWideChar(FileName);
    pTo := nil;
    fAnyOperationsAborted := Aborted;
    hNameMappings := nil;
    lpszProgressTitle := PChar('delete in progress');

  end;
  try

    SHFileOperation(SHFileOpStruct);
    Result := not Aborted;

  except
    Result := False;
  end;

end;

function DeleteFileToTemp(const FileName, TempDir: String): Boolean;
var
  FN: String;
begin

  CheckDirExisting(TempDir);
  FN := TempDir + '\' + FormatDateTime('yyyymmddhhnnssms', Now) + '_' + ExtractFileName(FileName);
  SetLastError(0);
  MoveFile(PWideChar(FileName), PWideChar(FN));
  Result := GetLastError = 0;

end;

function GetStreamMode(const FileName: String; Mode: Word): Word;
begin
  Result := Mode;
  if FileExists(FileName) then Result := Result or fmOpenWrite
  else Result := Result or fmCreate;
end;

procedure DataToFile(const FilePath: String; const Data: TData);
begin

  with TBytesStream.Create(Data) do

    try

      SaveToFile(FilePath);

    finally
      Free;
    end;

end;

function FileToData(const FilePath: String): TData;
begin

  with TBytesStream.Create(nil) do

    try

      LoadFromFile(FilePath);
      Result := Copy(Bytes, 0, Size);

    finally
      Free;
    end;

end;

procedure StrToFile(const Value, FileName: String);
var
  B: BLOB;
begin

  with TFileStream.Create(FileName, GetStreamMode(FileName, fmShareDenyWrite)) do

    try

      B := BOM_UTF8 + UTF8Encode(Value);
      Size := Length(B);
      Position := 0;

      Write(Pointer(B)^, Length(B));

    finally
      Free;
    end;

end;

function FileToStr(const FileName: String): String;
var
  Buffer: TBytes;
  Encoding: TEncoding;
  ESize: Integer;
begin

  { TODO 5 -oVasilyevSM -cFileUtils: ��� �����, ��� �� ���� ������ �� ���������� ��� �����. ��� ����� ����� ������, ���
    ���������. ����� ������������ �����, ������������ ��� ���. }
  if FileExists(FileName) then

    with TFileStream.Create(FileName, fmOpenRead) do

      try

        SetLength(Buffer, Size);
        Read(Buffer[0], Size);
        Encoding := nil;
        ESize := TEncoding.GetBufferEncoding(Buffer, Encoding);
        Result := Encoding.GetString(Buffer, ESize, Length(Buffer) - ESize);

      finally
        Free;
      end

  else Result := '';

end;

procedure ExploreFiles(const Path, Masks: String; Recursive: Boolean; Handler: TFileProc);
var
  FileExplorer: TFileExplorer;
begin

  FileExplorer := TFileExplorer.Create;
  try

    FileExplorer.Path := Path;
    FileExplorer.Masks := Masks;
    FileExplorer.Recursive := Recursive;
    FileExplorer.Run(Handler);

  finally
    FileExplorer.Free;
  end;

end;

procedure ExploreFiles(const Path, Masks: String; Handler: TFileProc);
begin
  ExploreFiles(Path, Masks, False, Handler);
end;

procedure ExploreFiles(const Path: String; Recursive: Boolean; Handler: TFileProc);
begin
  ExploreFiles(Path, Recursive, Handler);
end;

procedure ExploreFiles(const Path: String; Handler: TFileProc);
begin
  ExploreFiles(Path, '', False, Handler);
end;

{ TFileExplorer }

procedure TFileExplorer.Init;
var
  SA: TArray<String>;
  i, L: Integer;
begin

  if not Initialized then
  begin

    {TODO 2 -oVasilevSM : ����� ����� ������. �, ������� ����������� ��� �����, ������������ ������, ��� ����� ���� ���� ����� � ��� ���. }
    SA := Masks.Split(['|']);
    L := Length(SA);
    SetLength(FMaskList, L);

    for i := 0 to L - 1 do
    begin

      MaskList[i] := SA[i].Split(['.']);

      if Length(MaskList[i]) <> 2 then
        RaiseInvalidMaskError(SA[i]);

    end;

    FInitialized := True;

  end;

end;

function TFileExplorer.CheckMasks(const _Value: String): Boolean;
var
  SA: TArray<String>;
begin

  if Length(MaskList) = 0 then
    Exit(True);

  for SA in MaskList do
    if CheckMask(_Value, SA) then
      Exit(True);

  Result := False;

end;

function TFileExplorer.CheckMask(const _Value: String; const _Mask: TArray<String>): Boolean;
var
  NameMask, ExtMask: String;
  PointPos: Integer;
  FileName, FileExt: String;
begin

  NameMask := _Mask[0];
  ExtMask := _Mask[1];

  PointPos := _Value.LastIndexOf('.');

  if PointPos = 0 then
  begin

    FileName := _Value;
    FileExt := '';

  end
  else
  begin

    FileName := Copy(_Value, 1, PointPos);
    FileExt := _Value.Substring(PointPos + 1);

  end;

  Result :=

    CheckSingleMask(FileName, NameMask) and
    CheckSingleMask(FileExt, ExtMask);

end;

function TFileExplorer.CheckSingleMask(const _Value, _Mask: String): Boolean;
var
  AsterikPos, LLenght, RLength, VLength: Integer;
  LeftMask, RightMask: String;
begin

  if _Mask.CountChar('*') > 1 then
    RaiseInvalidMaskError(_Mask);

  if _Mask = '*' then
    Exit(True);

  AsterikPos := Pos('*', _Mask);
  if AsterikPos = 0 then
    Exit(AnsiSameText(_Value, _Mask));

  LeftMask := Copy(_Mask, 1, AsterikPos - 1);
  RightMask := _Mask.Substring(AsterikPos);

  LLenght := LeftMask.Length;
  RLength := RightMask.Length;
  VLength := _Value.Length;

  Result :=

      ((LLenght = 0) or AnsiSameText(LeftMask, Copy(_Value, 1, LLenght))) and
      ((RLength = 0) or ((VLength >= RLength) and AnsiSameText(RightMask, _Value.Substring(VLength - RLength))));

end;

procedure TFileExplorer.RaiseInvalidMaskError(const _Mask: String);
begin
  raise Exception.CreateFmt('File mask ''%s'' is not valid.', [_Mask]);
end;

procedure TFileExplorer.Run(_Handler: TFileProc);
var
  SR: TSearchRec;
  TempPath: String;
begin

  Init;

  if FindFirst(Path + '\*.*', faAnyFile, SR) = 0 then

    try

      repeat

        if

            (SR.Name <> '..') and
            (SR.Name <> '.')

        then

          if SR.Attr and faDirectory <> 0 then
          begin

            if Recursive then
            begin

              TempPath := Path;
              try

                Path := Path + '\' + SR.Name;
                Run(_Handler);

              finally
                Path := TempPath;
              end;

            end;

          end
          else

            _Handler(Path + '\' + SR.Name, CheckMasks(SR.Name), FTerminated);

      until Terminated or (FindNext(SR) <> 0);

    finally
      FindClose(SR);
    end;

end;

end.
