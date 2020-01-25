// Copyright (C) 2010 By Paul Dunn
//
// This file is part of the SpecBAS BASIC Interpreter, which is in turn
// part of the SpecOS project.
//
// SpecBAS is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// SpecBAS is distributed in the hope that it will be entertaining,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with SpecBAS.  If not, see <http://www.gnu.org/licenses/>.

unit SP_FileIO;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}

interface

Uses {$IFNDEF FPC}Windows, {$ENDIF}Types, Classes, SysUtils, SyncObjs, SP_Util, SP_Errors, SP_Tokenise, SP_SysVars, SP_Variables, SP_InfixToPostFix{$IFDEF FPC}, FileUtil{$ENDIF}, SP_AnsiStringlist;

Type

  TSP_File = Packed Record
    ID: Integer;
    Stream: TFileStream;
    Filename: aString;
    NeedCreate: Boolean;
    PackageFile: Boolean;
  End;
  pSP_File = ^TSP_File;

Procedure SP_FindAll(Path: aString; var List: TAnsiStringList; Var Sizes: TAnsiStringList);
Function  WildComp(const mask: aString; const target: aString): Boolean;

Function  SP_ConvertFilenameToHost(const Filename: aString; var Error: TSP_ErrorCode): aString;
Function  SP_ConvertHostFilename(const Filename: aString; Var Error: TSP_ErrorCode): aString;
Function  SP_FileOpen(Filename: aString; Create: Boolean; Var Error: TSP_ErrorCode): Integer;
Function  SP_FileOpenDirty(Filename: aString; Var Error: TSP_ErrorCode): Integer;
Procedure SP_FileSeek(ID, Position: Integer; Var Error: TSP_ErrorCode);
Function  SP_FileSize(ID: Integer; Var Error: TSP_ErrorCode): Integer;
Function  SP_FilePosition(ID: Integer; Var Error: TSP_ErrorCode): Integer;
Function  SP_FileRead(ID: Integer; Buffer: Pointer; Count: Integer; Var Error: TSP_ErrorCode): Integer;
Function  SP_FileWrite(ID: Integer; Buffer: Pointer; Count: Integer; Var Error: TSP_ErrorCode): Integer;
Function  SP_FileReWrite(ID: Integer; Var Error: TSP_ErrorCode): Integer;
Procedure SP_FileClose(ID: Integer; Var Error: TSP_ErrorCode);
Function  SP_FileExists(Filename: aString): Boolean;
Procedure SP_SetCurrentDir(Dir: aString; Var Error: TSP_ErrorCode);
Function  SP_GetCurrentDir: aString;
Function  SP_IsDirectory(const Path: aString): Boolean;
Function  SP_GetParentDir(Const Dir: aString): aString;
Function  SP_DirectoryExists(Dir: aString): Boolean;
Procedure SP_DeleteFile(Filename: aString; var Error: TSP_ErrorCode);
Function  SP_GetFileListRecursive(Var FileSpec: aString; WantEXP: Boolean; Var Error: TSP_ErrorCode): aString;
Procedure SP_GetFileList(Var FileSpec: aString; Var Files, FileSizes: TAnsiStringList; Var Error: TSP_ErrorCode; PreserveDirs: Boolean);
Procedure SP_DeleteDirContents(DirString: aString; var Error: TSP_ErrorCode);
Procedure SP_RmDir(DirString: aString; var Error: TSP_ErrorCode);
Procedure SP_RmDirUnsafe(DirString: aString; Var Error: TSP_ErrorCode);
Procedure SP_CopyFiles(FileSpec, Dest: aString; Overwrite: Boolean; var Error: TSP_ErrorCode);
Procedure SP_MoveFiles(FileSpec, Dest: aString; Overwrite: Boolean; var Error: TSP_ErrorCode);
Procedure SP_MakeDir(Dir: aString; var Error: TSP_ErrorCode);
Procedure SP_FileRename(Src, Dst: aString; var Error: TSP_ErrorCode);
Procedure SP_RenameFiles(SrcFiles, DstFiles: aString; var Error: TSP_ErrorCode);
Function  SP_ExtractFileDir(Filename: aString): aString;
Function  SP_ExtractFilename(Filename: aString): aString;

Procedure SP_SetAssign(Ass, Path: aString; var Error: TSP_ErrorCode);
Function  SP_Decode_Assignment(Ass: aString; var Error: TSP_ErrorCode): aString;
Function  SP_ConvertPathToAssigns(Filename: aString): aString;
Function  SP_DecomposePathWithAssigns(Path: aString): aString;

Function  SP_FileFindID(ID: Integer): Integer;
Procedure SP_FileCloseAll;

Procedure SP_SaveProgram(Filename: aString; AutoStart: Integer; Var Error: TSP_ErrorCode);
Procedure SP_LoadProgram(Filename: aString; Merge: Boolean; DirtyFile: Boolean; Const pList: TAnsiStringList; Var Error: TSP_ErrorCode);
Procedure SP_IncludeFile(Filename: aString; Var Error: TSP_ErrorCode);
Procedure SP_DeleteIncludes;

Procedure CopyDirectoryRecursive(inDir: String; outDir: String);

Procedure SP_AddToRecentFiles(Filename: aString; Saving: Boolean);
Procedure SP_LoadRecentFiles;
Procedure SP_SaveRecentFiles;
Function  SP_GetProgName(s: aString; Display: Boolean = False): aString;

Var

  SP_FileList: Array of pSP_File;
  SP_Ass_List: Array of aString;
  SP_RecentFiles: Array of aString;

  FileSection: TCriticalSection;

implementation

Uses SP_Main, SP_Editor, SP_Package, SP_FPEditor, SP_Graphics;

Procedure CopyFiles(inDir: String; outDir: String);
Var
  s: TSearchRec;
  SrcName, DestName: String;
  sTime, dTime: TDateTime;
  cpy: Boolean;
  Err: TSP_ErrorCode;
Begin

  If FindFirst(IncludeTrailingPathDelimiter(inDir) + '*', $1FF - $10, s) = 0 Then Begin
     Repeat
       cpy := True;
       If s.Attr And faDirectory <> faDirectory Then Begin
         DestName := IncludeTrailingPathDelimiter(outDir) + s.Name;
         SrcName := IncludeTrailingPathDelimiter(inDir) + s.Name;
         If FileExists(DestName) Then Begin
           sTime := FileAge(SrcName);
           dTime := FileAge(DestName);
           cpy := sTime > dTime;
         end;
       End;
       SCROLLCNT := 0;
       If cpy Then Begin
         SP_PRINT(-1, Round(PRPOSX), Round(PRPOSY), -1, 'Copying '+DestName, 0, 8, Err);
         {$IFDEF FPC}
         FileUtil.CopyFile(SrcName, DestName, True);
         {$ENDIF}
       End Else
         SP_PRINT(-1, Round(PRPOSX), Round(PRPOSY), -1, 'Skipped '+DestName, 2, 8, Err);
       PRPOSX := 0;
       PRPOSY := PRPOSY + FONTHEIGHT;
     Until SysUtils.FindNext(s) <> 0;
  End;
  FindClose(s);
End;

procedure CopyDirectoryRecursive(inDir: String; outDir: String);
// Based on code by Matthew Hipkin ( http://www.matthewhipkin.co.uk/codelib/copy-directory-structure-in-delphi-and-lazarus/ )
var
  s: TSearchRec;
  nInDir, nOutDir: String;
begin
  CopyFiles(inDir, outDir);
  If Not DirectoryExists(outDir) Then
    mkDir(outDir);
  if FindFirst(IncludeTrailingPathDelimiter(inDir) + '*', faDirectory, s) = 0 then
  begin
    repeat
      if (s.Name <> '.') and (s.Name <> '..') and ((s.Attr and faDirectory) = faDirectory) then
      begin
        nInDir := IncludeTrailingPathDelimiter(inDir) + s.Name;
        nOutDir := IncludeTrailingPathDelimiter(outDir) + s.Name;
        // Create new subdirectory in outDir
        If Not DirectoryExists(nOutDir) Then
          mkdir(nOutDir);
        // Recurse into subdirectory in inDir
        copyDirectoryRecursive(nInDir, nOutDir);
      end;
    until SysUtils.FindNext(s) <> 0;
  end;
  FindClose(s);
end;

Procedure SP_FindAll(Path: aString; var List: TAnsiStringList; Var Sizes: TAnsiStringList);
Var
  Res: TSearchRec;
  EOFound: Boolean;
  Idx, Cnt, nIdx, sIdx: Integer;
  Size, Size2, AgeStr: aString;
  Age: Integer;
  Error: TSP_ErrorCode;
Begin

  If PackageIsOpen And (Pos(':', String(Path)) = 0) Then Begin

    SP_PackageFindAll(Path, List, Sizes, Error);

  End Else Begin

    If Pos(':', String(Path)) <> 0 Then
      Path := SP_ConvertFilenameToHost(Path, Error);
    EOFound:= False;
    If FindFirst(String(Path), faAnyFile, Res) < 0 Then
      Exit
    Else
      While Not EOFound Do Begin
        Idx := List.Add(Res.Name);
        If Res.Attr And faDirectory > 0 Then
          List.Objects[Idx] := Pointer(1)
        Else
          List.Objects[Idx] := Pointer(0);
        Size := aString(IntToStr(Int64(Res.Size)));
        Size2 := ''; Cnt := 0;
        nIdx := Length(Size);
        While nIdx > 0 Do Begin
          Size2 := Size[nIdx] + Size2;
          Inc(Cnt);
          If (Cnt = 3) And (nIdx > 1) Then Begin
            Size2 := ',' + Size2;
            Cnt := 0;
          End;
          Dec(nIdx);
        End;
        Age := Res.Time;
        If Age > -1 Then Begin
          AgeStr := aString(DateToStr(FileDateToDateTime(Age)));
          If Length(AgeStr) < 10 Then
            If AgeStr[2] = '/' Then
              AgeStr := '0' + AgeStr
            Else
              AgeStr := Copy(AgeStr, 1, 3) + '0' + Copy(AgeStr, 4, Length(AgeStr));
          If Length(AgeStr) < 10 Then
            AgeStr := Copy(AgeStr, 1, 3) + '0' + Copy(AgeStr, 4, Length(AgeStr));
          AgeStr := Copy(AgeStr, 1, 2) + '/' + Copy(AgeStr, 4, 2) + '/' + Copy(AgeStr, 7, 4);
          sIdx := Sizes.Add(String(Size2 + ' ' + aString(StringOfChar(' ', 10 - Length(AgeStr))) + AgeStr));
        End Else
          sIdx := Sizes.Add(String(Size2 + '            '));
        Sizes.Objects[sIdx] := Pointer(StringToLong(Size));
        EOFound:= SysUtils.FindNext(Res) <> 0;
      End;
    FindClose(Res);
  End;

End;

Function WildComp(const mask: aString; const target: aString): Boolean;

  // This function was retrieved from http://www.delphifaq.com/faq/delphi/strings/f112.shtml
  // And was posted by thomas_kelsey@techie.com under the GPL License, and
  // as such can be included in SpecBAS. Modified to remove the "." issue, as SpecBAS
  // doesn't use file extensions for anything but music.

  // '*' matches greedy & ungreedy
  // simple recursive descent parser - not fast but easy to understand
  function WComp(const maskI: Integer; const targetI: Integer): Boolean;
  begin
    if maskI > Length(mask) then begin
      Result := targetI = Length(target) + 1;
      Exit;
    end;
    if targetI > Length(target) then begin
      // unread chars in filter or would have read '#0'
      // Only exception is a trailing "*" in the mask - that matches everything else including
      // the empty string. A trailing "?" MUST match a character.
      Result := (maskI = Length(Mask)) and (mask[maskI] = '*');
      Exit;
    end;
    case mask[maskI] of
      '*':
        // try with and without ending match - but always matches at least one char
        Result := WComp(succ(maskI), Succ(targetI)) or WComp(maskI, Succ(targetI)) or WComp(succ(MaskI), targetI);
      '?':
        Result := WComp(succ(maskI), Succ(targetI));
    else
      // includes '.' which only matches itself
      if mask[maskI] = target[targetI] then
        Result := WComp(succ(maskI), Succ(targetI))
      else
        Result := False;
    end;// case
  end;
begin
  WildComp := WComp(1, 1);
end;

Function SP_ConvertFilenameToHost(const Filename: aString; var Error: TSP_ErrorCode): aString;
Var
  fName, fName2: aString;
Begin

  // Converts a specbas file/folder to the host architecture's file/folder

  If Pos(':', String(Filename)) <> 0 Then Begin
    fName := SP_Decode_Assignment(Copy(Filename, 1, Pos(':', String(Filename)) -1), Error);
    fName2 := Copy(Filename, Pos(':', String(Filename)) +1, Length(Filename));
    While Copy(fName2, 1, 1) = '/' Do
      fName2 := Copy(fName2, 2, Length(fName2));
    fName2 := fName + fName2;
  End Else
    fName2 := Filename;

  If fName2 <> '' Then Begin
    If fName2[1] = '/' Then
      If Lower(Copy(fName2, 1, Length(HOMEFOLDER))) <> Lower(HOMEFOLDER) Then
        fName2 := HOMEFOLDER + Copy(fName2, 2, Length(fName2));

    fName := aString(ExpandFileName(String(fName2)));

    If Lower(Copy(fName, 1, Length(HOMEFOLDER) -1)) <> Lower(Copy(Homefolder, 1, Length(HomeFolder) -1)) Then Begin
      Result := #255;
      Error.Code := SP_ERR_DIR_NOT_FOUND;
      Exit;
    End;

  End Else

    fName := '';

  Result := fName;

End;

Function SP_ConvertHostFilename(const Filename: aString; Var Error: TSP_ErrorCode): aString;
Var
  fName: aString;
  Idx: Integer;
Begin

  // Converts a host-friendly filename to a specbas style filename.

  fName := aString(ExpandFileName(String(Filename)));
  If fName[Length(fName)] <> PathDelim Then fName := fName + PathDelim;

  If Lower(Copy(fName, 1, Length(HOMEFOLDER))) <> Lower(Homefolder) Then Begin
    Result := '';
    Error.Code := SP_ERR_INVALID_FILENAME;
    Exit;
  End Else Begin
    If fName <> '' Then Begin
      For Idx := 1 to Length(fName) Do
        If fName[Idx] = '\' Then fName[Idx] := '/';
    End;
    fName := '/' + Copy(fName, Length(HOMEFOLDER) +1, Length(fName));
    Result := fName;
  End;

End;

Function SP_FileOpen(Filename: aString; Create: Boolean; Var Error: TSP_ErrorCode): Integer;
Var
  fName: aString;
  Idx, FoundIdx, NewID: Integer;
  NewFile: pSP_File;
  Done, Found, System: Boolean;
Begin

  Result := -1;

  // Filename is in SpecBAS format.

  System := Pos(':', String(Filename)) > 0;

  If System or Not PackageIsOpen Then Begin

    fName := SP_ConvertFilenameToHost(Filename, Error);

    If Lower(Copy(fName, 1, Length(HOMEFOLDER))) <> Lower(Homefolder) Then Begin
      Result := -1;
      Error.Code := SP_ERR_INVALID_FILENAME;
      Exit;
    End;

  End Else

    fName := Filename;

  // Check if the file is already open in the file list

  FoundIdx := -1;
  For Idx := 0 To Length(SP_FileList) -1 Do Begin
    If SP_FileList[Idx]^.Filename = fName Then Begin
      FoundIdx := Idx;
      Break;
    End;
  End;

  // Not open, so create a new file list entry.

  If FoundIdx = -1 Then Begin

    If (SP_ExtractFileDir(Filename) = '') Or (SP_DirectoryExists(SP_ExtractFileDir(FileName))) Then Begin

      New(NewFile);
      NewID := 0;
      Done := Length(SP_FileList) = 0;
      While Not Done Do Begin
        Found := False;
        For Idx := 0 To Length(SP_FileList) -1 Do Begin
          If SP_FileList[Idx]^.ID = NewID Then Begin
            Inc(NewID);
            Found := True;
            Break;
          End;
        End;
        If Not Found Then
          Done := True;
      End;

      NewFile^.ID := NewID;
      NewFile^.Filename := fName;
      NewFile^.PackageFile := False;
      NewFile^.NeedCreate := False;

      // Create the new file.

      If Not SP_FileExists(fName) Then Begin
        If Create Then Begin
          NewFile^.NeedCreate := True;
          NewFile^.Stream := Nil;
        End Else Begin
          Error.Code := SP_ERR_FILE_ALREADY_EXISTS;
          Dispose(NewFile);
          Result := -1;
          Exit;
        End;
      End Else Begin

        Try
          If System or Not PackageIsOpen Then Begin
            NewFile^.Stream := TFileStream.Create(String(fName), fmOpenReadWrite or fmShareDenyNone)
          End Else
            NewFile^.PackageFile := True;
        Except
          On Exception Do Begin
            Dispose(NewFile);
            Error.Code := SP_ERR_COULD_NOT_OPEN_FILE;
            Result := -1;
            Exit;
          End;
        End;

      End;

      SetLength(SP_FileList, Length(SP_FileList) +1);
      SP_FileList[Length(SP_FileList) -1] := NewFile;
      FoundIdx := Length(SP_FileList) -1;
      If Not System Then
        NewFile^.PackageFile := PackageIsOpen;

      Result := SP_FileList[FoundIdx]^.ID;
      If System or Not PackageIsOpen Then Begin
        If SP_FileList[FoundIdx]^.Stream <> Nil Then Begin
          SP_FileList[FoundIdx]^.Stream.Seek(0, soFromBeginning);
        End;
      End Else
        If Not NewFile^.NeedCreate Then
          SP_SeekToPackageFile(fName, 0, Error);

    End Else Begin

      Error.Code := SP_ERR_DIRECTORYNOTFOUND;
      Result := -1;

    End;

  End;

End;

Function  SP_FileOpenDirty(Filename: aString; Var Error: TSP_ErrorCode): Integer;
Var
  fName: aString;
  Idx, FoundIdx, NewID: Integer;
  NewFile: pSP_File;
  Done, Found, System: Boolean;
Begin

  Result := -1;

  // Filename might be in SpecBAS format, but may also be a host-format filename.

  System := Pos(':', String(Filename)) > 0;

  If System or Not PackageIsOpen Then Begin
    If System Then Begin
      fName := SP_ConvertFilenameToHost(Filename, Error);
      If Lower(Copy(fName, 1, Length(HOMEFOLDER))) <> Lower(Homefolder) Then Begin
        Error.Code := SP_ERR_INVALID_FILENAME;
        Result := -1;
        Exit;
      End;
    End Else
      fName := Filename;

  End Else

    fName := Filename;

  // Check if the file is already open in the file list

  FoundIdx := -1;
  For Idx := 0 To Length(SP_FileList) -1 Do Begin
    If SP_FileList[Idx]^.Filename = fName Then Begin
      FoundIdx := Idx;
      Break;
    End;
  End;

  // Not open, so create a new file list entry.

  If FoundIdx = -1 Then Begin

    New(NewFile);
    NewID := 0;
    Done := Length(SP_FileList) = 0;
    While Not Done Do Begin
      Found := False;
      For Idx := 0 To Length(SP_FileList) -1 Do Begin
        If SP_FileList[Idx]^.ID = NewID Then Begin
          Inc(NewID);
          Found := True;
          Break;
        End;
      End;
      If Not Found Then
        Done := True;
    End;

    NewFile^.ID := NewID;
    NewFile^.Filename := fName;
    NewFile^.PackageFile := False;
    NewFile^.NeedCreate := False;
    // Create the new file.

    Try
      If System or Not PackageIsOpen Then Begin
        NewFile^.Stream := TFileStream.Create(String(fName), fmOpenReadWrite or fmShareDenyNone)
      End Else
        NewFile^.PackageFile := True;
    Except
      On Exception Do Begin
        Error.Code := SP_ERR_COULD_NOT_OPEN_FILE;
        Dispose(NewFile);
        Result := -1;
        Exit;
      End;
    End;

    SetLength(SP_FileList, Length(SP_FileList) +1);
    SP_FileList[Length(SP_FileList) -1] := NewFile;
    FoundIdx := Length(SP_FileList) -1;
    If Not System Then
      NewFile^.PackageFile := PackageIsOpen;

    Result := SP_FileList[FoundIdx]^.ID;
    If System or Not PackageIsOpen Then Begin
      If SP_FileList[FoundIdx]^.Stream <> Nil Then Begin
        SP_FileList[FoundIdx]^.Stream.Seek(0, soFromBeginning);
      End;
    End Else
      SP_SeekToPackageFile(fName, 0, Error);

  End;

End;

Procedure SP_FileSeek(ID, Position: Integer; Var Error: TSP_ErrorCode); inline;
Var
  Idx: Integer;
Begin

  Idx := SP_FileFindID(ID);
  If Idx > -1 Then Begin
    If SP_FileList[Idx]^.PackageFile Then
      SP_SeekToPackageFile(SP_FileList[Idx]^.Filename, Position, Error)
    Else
      If SP_FileList[Idx]^.Stream <> nil Then
        SP_FileList[Idx]^.Stream.Seek(Position, soFromBeginning);
  End Else
    Error.Code := SP_ERR_FILE_NOT_OPEN;

End;

Function  SP_FileSize(ID: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Idx: Integer;
Begin

  Result := -1;
  Idx := SP_FileFindID(ID);
  If Idx > -1 Then Begin
    If SP_FileList[Idx]^.PackageFile Then
      Result := SP_GetSizeFromPackageFile(SP_FileList[Idx]^.Filename, Error)
    Else
      If SP_FileList[Idx]^.Stream <> nil Then
        Result := SP_FileList[Idx]^.Stream.Size
      Else
        Result := 0;
  End Else
    Error.Code := SP_ERR_FILE_NOT_OPEN;

End;

Function  SP_FilePosition(ID: Integer; Var Error: TSP_ErrorCode): Integer; inline;
Var
  Idx: Integer;
Begin

  Result := -1;
  Idx := SP_FileFindID(ID);
  If Idx > -1 Then Begin
    If SP_FileList[Idx]^.PackageFile Then
      Result := SP_GetSeekPosFromPackageFile(SP_FileList[Idx]^.Filename, Error)
    Else
      If SP_FileList[Idx]^.Stream <> nil Then
        Result := SP_FileList[Idx]^.Stream.Position
      Else
        Result := 0;
  End Else
    Error.Code := SP_ERR_FILE_NOT_OPEN;

End;

Function SP_FileRead(ID: Integer; Buffer: Pointer; Count: Integer; Var Error: TSP_ErrorCode): Integer; inline;
Var
  Idx: Integer;
Begin

  Result := 0;
  Idx := SP_FileFindID(ID);
  If Idx > -1 Then Begin
    If SP_FileList[Idx]^.PackageFile Then
      Result := SP_ReadFromPackageFile(SP_FileList[Idx]^.Filename, pByte(Buffer), Count, Error)
    Else
      If SP_FileList[Idx]^.Stream <> nil Then Begin
        Result := SP_FileList[Idx]^.Stream.Read(Buffer^, Count);
      End Else Begin
        Result := -1;
        Exit;
      End;
  End Else
    Error.Code := SP_ERR_FILE_NOT_OPEN;

End;

Function SP_FileWrite(ID: Integer; Buffer: Pointer; Count: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Idx: Integer;
Begin

  Result := -1;
  Idx := SP_FileFindID(ID);
  If Idx > -1 Then Begin
    If SP_FileList[Idx]^.PackageFile Then Begin
      If SP_FileList[Idx]^.NeedCreate Then Begin
         SP_CreatePackageFile(SP_FileList[Idx]^.Filename, Error);
         SP_FileList[Idx]^.NeedCreate := False;
      End;
      Result := SP_WriteToPackageFile(SP_FileList[Idx]^.Filename, pByte(Buffer), Count, Error);
    End Else Begin
      Try
        If SP_FileList[Idx]^.NeedCreate Then Begin
           SP_FileList[Idx]^.Stream := TFileStream.Create(String(SP_FileList[Idx]^.Filename), fmCreate or fmShareDenyNone);
           SP_FileList[Idx]^.NeedCreate := False;
        End;
        Result := SP_FileList[Idx]^.Stream.Write(Buffer^, Count);
      Except
        Error.Code := SP_ERR_SAVE_OPEN_ERROR;
      End;
    End;
  End Else
    Error.Code := SP_ERR_FILE_NOT_OPEN;

End;

Function SP_FileReWrite(ID: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Filename: aString;
  NewID, OldID, Idx: Integer;
Begin

  Result := -1;
  Idx := SP_FileFindID(ID);
  If Idx > -1 Then Begin
    OldID := ID;
    Filename := SP_FileList[Idx]^.Filename;
    SP_FileClose(OldID, Error);
    If DeleteFile(String(Filename)) Then Begin
      NewID := SP_FileOpen(Filename, True, Error);
      Idx := SP_FileFindID(NewID);
      SP_FileList[Idx]^.ID := OldID;
      Result := OldID;
    End Else Begin
      Result := -1;
      Error.Code := SP_ERR_FILE_LOCKED;
    End;
  End Else
    Error.Code := SP_ERR_FILE_NOT_OPEN;

End;

Procedure SP_FileClose(ID: Integer; Var Error: TSP_ErrorCode);
Var
  Index, Idx: Integer;
Begin

  Idx := SP_FileFindID(ID);
  If (Idx > -1) And Assigned(SP_FileList[Idx]) Then Begin
    If Not SP_FileList[Idx]^.PackageFile Then
      If SP_FileList[Idx]^.Stream <> nil Then
        SP_FileList[Idx]^.Stream.Free;
    Dispose(SP_FileList[Idx]);
    For Index := Idx To Length(SP_FileList) -2 Do
      SP_FileList[Index] := SP_FileList[Index +1];
    SetLength(SP_FileList, Length(SP_FileList) -1);
  End Else
    Error.Code := SP_ERR_FILE_NOT_OPEN;

End;

Function SP_FileFindID(ID: Integer): Integer;
Var
  Idx: Integer;
Begin

  Result := -1;
  Idx := 0;
  While Idx < Length(SP_FileList) Do Begin
    If SP_FileList[Idx]^.ID = ID Then Begin
      Result := Idx;
      Exit;
    End;
    Inc(Idx);
  End;

End;

Function SP_FileExists(Filename: aString): Boolean;
Var
  HostName: aString;
  Error: TSP_ErrorCode;
  System: Boolean;
Begin

  System := Pos(':', String(Filename)) > 0;
  If PackageIsOpen And Not System Then
    Result := SP_PackageFileExists(Filename, Error)
  Else Begin
    HostName := SP_ConvertFilenameToHost(Filename, Error);
    Result := FileExists(HostName);
  End;

End;

Procedure SP_FileCloseAll;
Var
  Idx: Integer;
Begin

  FileSection.Enter;

  For Idx := 0 To Length(SP_FileList) -1 Do
    If Assigned(SP_FileList[Idx]) Then Begin
      If Not SP_FileList[Idx]^.PackageFile Then
        If Assigned(SP_FileList[Idx]^.Stream) Then
          SP_FileList[Idx]^.Stream.Free;
      Dispose(SP_FileList[Idx]);
    End;

  SetLength(SP_FileList, 0);

  FileSection.Leave;

End;

Function SP_GetProgName(s: aString; Display: Boolean = False): aString;
Var
  cl_changed, cl_normal: Longword;
Begin

  If Not FILENAMED Then
    Result := NEWPROGNAME
  Else
    Result := s;

  If Display Then Begin
    If FocusedWindow = fwDirect Then Begin
      cl_changed := 120;
      cl_normal := 26;
    End Else Begin
      cl_changed := 10;
      cl_normal := 12;
    End;
    If FILECHANGED Then
      Result := Result + aChar(#16)+LongWordToString(cl_changed)+' '+#244
    Else
      Result := Result + aChar(#16)+LongWordToString(cl_normal)+' '+#244;
  End;

End;

Procedure SP_SaveProgram(Filename: aString; AutoStart: Integer; Var Error: TSP_ErrorCode);
Var
  FileID, Idx, cPos, ProgLen: Integer;
  ProgLine, SaveBuffer, Backup: aString;
  LineLen, CheckSum: LongWord;
  System, BackBool: Boolean;
Const
  ASCIITAG: aString = 'ZXASCII'#13#10;
  TrueFalse: Array[0..1] of aString = ('FALSE', 'TRUE');
Begin

  BackBool := FILENAMED;
  Backup := PROGNAME;

  If Filename = '' Then
    If FILENAMED Then
      Filename := PROGNAME
    Else Begin
      Error.Code := SP_ERR_INVALID_FILENAME;
      CompilerLock.Leave;
      Exit;
    End;

  If SP_FileExists(Filename) Then Begin
    System := Pos(':', String(Filename)) > 0;
    If PackageIsOpen And Not System Then Begin
      SP_DeletePackageFile(Filename, Error);
      If Error.Code <> SP_ERR_OK Then Begin
        Exit;
      End;
    End Else
      SP_DeleteFile(Filename, Error);
      If Error.Code <> SP_ERR_OK Then Begin
        Exit;
      End;
  End;

  FileID := SP_FileOpen(Filename, True, Error);
  SaveBuffer := '';

  If FileID > -1 Then Begin

    ProgLen := Listing.Count;

    If Lower(Filename) <> 's:autosave' Then Begin
      PROGNAME := SP_ExtractFileDir(Filename);
      If Copy(PROGNAME, Length(PROGNAME), 1) <> '/' Then
        PROGNAME := PROGNAME + '/';
       PROGNAME := PROGNAME + SP_ExtractFileName(Filename);
      FILENAMED := True;
      FILECHANGED := False;
      SP_AddToRecentFiles(Filename, True);
    End;

    SaveBuffer := ASCIITAG + 'AUTO '+IntToString(AutoStart)+#13+#10;
    SaveBuffer := SaveBuffer + 'PROG ' + PROGNAME+#13#10;
    SaveBuffer := SaveBuffer + 'CHANGED '+TrueFalse[Ord(FILECHANGED)]+#13#10;

    Idx := 0;
    While Idx < ProgLen Do Begin
      ProgLine := StringOfChar(#9, Listing.Flags[Idx].Indent) + SP_FPGetUnwrappedLine(Idx) + #13+#10;
      SaveBuffer := SaveBuffer + ProgLine;
    End;
    SP_FileWrite(FileID, @SaveBuffer[1], Length(SaveBuffer), Error);
    SP_FileClose(FileID, Error);

    If Error.Code <> SP_ERR_OK Then Begin
      PROGNAME := Backup;
      FILENAMED := BackBool;
    End;

  End Else Begin

    If Error.Code = SP_ERR_OK Then
      Error.Code := SP_ERR_SAVE_OPEN_ERROR;

  End;

End;

Procedure SP_IncludeFile(Filename: aString; Var Error: TSP_ErrorCode);
Var
  Tokens: aString;
  NewProg: TAnsiStringList;
  BaseLineNum, CurLastLine, Idx, Idx2, cPos, Token, LineNumber: Integer;
  CanTest, Changed, ChangeFlag: Boolean;
Begin

  // Loads a program into a temporary memory area, and then appends it to the current program.
  // If the program doesn't exist in the current directory, try prepending INCLUDE: to it.

  NewProg := TAnsiStringList.Create;

  If Not SP_FileExists(Filename) Then
    If SP_FileExists('include:'+Filename) Then
      Filename := 'include:'+Filename
    Else
      If SP_FileExists('include:'+SP_ExtractFilename(Filename)) Then
        Filename := 'include:'+SP_ExtractFilename(Filename);

  SP_LoadProgram(Filename, False, False, NewProg, Error);
  If Error.Code <> SP_ERR_OK Then Begin
    NewProg.Free;
    Exit;
  End;

  For Idx := 0 To NewProg.Count -1 Do Begin
    Tokens := SP_TokeniseLine(NewProg[Idx], False, True) + SP_TERMINAL_SEQUENCE;
    If Tokens <> SP_TERMINAL_SEQUENCE Then
      SP_Convert_ToPostFix(Tokens, Error.Position, Error);
    NewProg[Idx] := Tokens;
  End;

  // Ok, got the program into our stringlist. Now grab the initial line number (for later) and start to process
  // the code.

  If Byte(NewProg[0][1]) = SP_LINE_NUM Then Begin

    BaseLineNum := pLongWord(@NewProg[0][2])^;
    CurLastLine := pLongWord(@SP_Program[SP_Program_Count -1][2])^ + 10;

    For Idx := 0 To NewProg.Count -1 Do Begin

      Idx2 := 1; cPos := 1;
      Tokens := SP_Detokenise(NewProg[Idx], cPos, False, False);
      Tokens := SP_TokeniseLine(Tokens, False, True) + SP_TERMINAL_SEQUENCE;
      Changed := False;
      CanTest := False;
      ChangeFlag := False;

      // Now search the text for the trigger keywords. If found, determine if a label is present - if not,
      // then (if there is a parameter present) insert the "baseaddr+(" + ")" expression.

      If Tokens[Idx2] = aChar(SP_LINE_NUM) Then Begin
        // Increment the line number by the base amount
        Inc(Idx2);
        LineNumber := pLongWord(@Tokens[Idx2])^;
        Inc(LineNumber, CurLastLine);
        pLongWord(@Tokens[Idx2])^ := LineNumber;
        Inc(Idx2, SizeOf(LongWord));
        ChangeFlag := True;
      End;

      If Tokens[Idx2] = aChar(SP_LINE_LEN) Then Inc(Idx2, SizeOf(LongWord) +1);
      If Tokens[Idx2] = aChar(SP_STATEMENTS) Then Inc(Idx2, 1 +((1 + pLongWord(@Tokens[Idx2 +1])^) * SizeOf(LongWord)));

      While Idx2 <= Length(Tokens) Do Begin

        Token := Byte(Tokens[Idx2]);
        Inc(Idx2);

        Case Token of

          SP_KEYWORD:
            Begin
              Case pLongWord(@Tokens[Idx2])^ of
                SP_KW_GO:
                  Begin
                    Inc(Idx2, SizeOf(LongWord));
                    If Byte(Tokens[Idx2]) = SP_KEYWORD Then Begin
                      Inc(Idx2);
                      Case pLongWord(@Tokens[Idx2])^ of
                        SP_KW_TO, SP_KW_SUB:
                          Begin
                            Inc(Idx2, SizeOf(LongWord));
                            CanTest := True;
                          End;
                      Else
                        Begin
                          Inc(Idx2, SizeOf(LongWord));
                        End;
                      End;
                    End;
                  End;
                SP_KW_RESTORE, SP_KW_RUN:
                  Begin
                    CanTest := True;
                    Inc(Idx2, SizeOf(LongWord));
                  End;
                SP_KW_ELSE:
                  Begin
                    If Changed Then Begin
                      Tokens := Copy(Tokens, 1, Idx2 -2) + aChar(SP_SYMBOL) + ')' + Copy(Tokens, Idx2 -1, Length(Tokens));
                      Changed := False;
                      ChangeFlag := True;
                    End;
                    Inc(Idx2, SizeOf(LongWord));
                  End;
              Else
                Begin
                  Inc(Idx2, SizeOf(LongWord));
                End;
              End;
            End;
          SP_LABEL, SP_COMMENT, SP_STRING, SP_STRUCT_MEMBER_N, SP_STRUCT_MEMBER_S:
            Inc(Idx2, SizeOf(LongWord) + pLongWord(@Tokens[Idx2])^);
          SP_VALUE, SP_STRINGCHAR:
            Inc(Idx2, SizeOf(aFloat));
          SP_VALUE10:
            Inc(Idx2, 10);
          SP_NUMVAR, SP_STRVAR:
            Inc(Idx2, (SizeOf(LongWord)*2) + pLongWord(@Tokens[Idx2 + SizeOf(LongWord)])^);
          SP_TEXT:
            Inc(Idx2, SizeOf(LongWord) + pLongWord(@Tokens[Idx2])^);
          SP_SYMBOL:
            Begin
              If Tokens[Idx2] = ':' Then
                If Changed Then Begin
                  Tokens := Copy(Tokens, 1, Idx2 -2) + aChar(SP_SYMBOL) + ')' + Copy(Tokens, Idx2 -1, Length(Tokens));
                  Changed := False;
                  ChangeFlag := True;
                End;
              Inc(Idx2);
            End;
          SP_TERMINAL:
            Begin
              If Changed Then Begin
                Tokens := Copy(Tokens, 1, Idx2 -2) + aChar(SP_SYMBOL) + ')' + Copy(Tokens, Idx2 -1, Length(Tokens));
                Changed := False;
                ChangeFlag := True;
              End;
              Break;
            End;
        End;

        If CanTest Then Begin
          Token := Byte(Tokens[Idx2]);
          If Not(((Token = SP_SYMBOL) And (Tokens[Idx2 + 1] = ':')) or (Token = SP_LABEL) or (Token = SP_COMMENT) or (Token = SP_TERMINAL) or ((Token = SP_KEYWORD) And (pLongWord(@Tokens[Idx2 + 1])^ = SP_KW_ELSE))) Then Begin
            // Found a valid place to insert our code snippet
            Tokens := Copy(Tokens, 1, Idx2 -1) +
                      aChar(SP_VALUE) + aFloatToString(CurLastLine) + aChar(SP_TEXT) + LongWordToString(Length(IntToString(CurLastLine))) + IntToString(CurLastLine) +
                      aChar(SP_SYMBOL) + '+' +
                      aChar(SP_SYMBOL) + '(' + Copy(Tokens, Idx2, Length(Tokens));
            Changed := True;
            ChangeFlag := True;
          End;
          CanTest := False;
        End;

      End;

      If ChangeFlag Then Begin
        Error.Position := 1;
        SP_Convert_ToPostFix(Tokens, Error.Position, Error);
        NewProg[Idx] := Tokens;
        ChangeFlag := False;
      End;

    End;

    // Now the code is all ready to be added to the current program!

    If Error.Code = SP_ERR_OK Then Begin
      Tokens := SP_TokeniseLine(IntToString(CurLastLine -1) + ' HALT', False, True) + SP_TERMINAL_SEQUENCE;
      SP_Convert_ToPostFix(Tokens, Error.Position, Error);
      NewProg.Insert(0, Tokens);
      SP_Program_AddStrings(NewProg);
    End Else
      Exit;

  End Else

    Error.Code := SP_ERR_FILE_CORRUPT;

  NewProg.Free;

End;

Procedure SP_DeleteIncludes;
Begin

  // Remove all included procedures from the current program

  If INCLUDEFROM > -1 Then Begin

    SetLength(SP_Program, INCLUDEFROM);
    SP_Program_Count := Length(SP_Program);
    INCLUDEFROM := -1;

  End;

End;

Procedure SP_LoadProgram(Filename: aString; Merge, DirtyFile: Boolean; Const pList: TAnsiStringList; Var Error: TSP_ErrorCode);
Var
  cPos, FileID, FileSize, LineCount, AutoStart, NameLen, Idx, lIdx, LineLen, Posn, LineNum, LineNum2, i: Integer;
  pName, ProgLine, Tokens, PlainCode, s, Dir: aString;
  Done, InString, changed: Boolean;
  Buffer: Array of Byte;
  NewProg: array of aString;
  CheckSum: LongWord;
Label
  Finish, DoneLoad;

  Function StrCopy(Ptr: pByte; Length: Integer): aString;
  Var
    Idx: Integer;
  Begin

    Idx := 1;
    SetLength(Result, Length);
    While Length > 0 Do Begin
      pByte(@Result[Idx])^ := Ptr^;
      Inc(Idx);
      Inc(Ptr);
      Dec(Length);
    End;

  End;

Begin

  cPos := -1;
  FileID := -1;
  changed := False;
  Dir := SP_ExtractFileDir(Filename);
  SP_SetCurrentDir(Dir, Error);

  If pList = Nil Then Begin

    // Load a program from a file or package.

    PROGCHANGED := True;
    pName := Filename;
    AutoStart := -1;

  End;

  If DirtyFile Then Begin
    Filename := SP_ConvertHostFilename(Filename, Error);
    If Filename <> '' Then
      If Filename[Length(Filename)] in ['/','\'] Then
        FileName := Copy(FileName, 1, Length(Filename) -1);
  End;

  If Not SP_FileExists(Filename) Then Begin
    // Might be a "dirty" filename - specified on the command line. We allow those for loading ONLY.
    If DirtyFile Then Begin
      If FileExists(String(Filename)) Then
        FileID := SP_FileOpenDirty(Filename, Error);
      If Error.Code <> SP_ERR_OK Then Goto Finish;
    End Else Begin
      Error.Code := SP_ERR_FILE_NOT_FOUND;
      Goto DoneLoad;
    End;
  End;

  If FileID = -1 Then
    FileID := SP_FileOpen(Filename, False, Error);

  If FileID > -1 Then Begin

    // File opened, suck it into the buffer. Programs never get very big, so just load it all in one go.

    FileSize := SP_FileSize(FileID, Error);

    If Error.Code = SP_ERR_OK Then Begin

      SetLength(Buffer, 6);
      SP_FileRead(FileID, @Buffer[0], 6, Error);
      If Error.Code = SP_ERR_OK Then Begin

        If StrCopy(@Buffer[0], 6) = 'ZXPACK' Then Begin

          // This file is a package, so open it as such and try again with the "/autorun" file

          SP_FileClose(FileID, Error);
          FileID := -1;

          SP_CreatePackage(Filename, Error);
          If Error.Code = SP_ERR_OK Then Begin
            If SP_FileExists('/autorun') Then Begin
              SP_LoadProgram('/autorun', False, False, pList, Error);
              If pList = nil Then Begin
                NXTLINE := SP_FindLine(0, False);
                Error.ReturnType := SP_JUMP;
                SP_PreParse(True, Error);
              End;
            End;
          End;
          Goto DoneLoad;

        End Else Begin

          SetLength(Buffer, FileSize);
          SP_FileSeek(FileID, 0, Error);
          If (Error.Code = SP_ERR_OK) And (FileSize > 7) Then Begin

            SP_FileRead(FileID, @Buffer[0], FileSize, Error);
            If Error.Code = SP_ERR_OK Then Begin

              // Loaded the file - determine it's type (Tokenised BASIC or plain text) and load it.

              If Error.Code <> SP_ERR_OK Then Goto Finish;

              If StrCopy(@Buffer[0], 7) = 'ZXBASIC' Then Begin

                // File is tokenised BASIC. Pull file info:

                Idx := 7;

                If Not Merge Then
                  AutoStart := pInteger(@Buffer[Idx])^;
                Inc(Idx, SizeOf(LongWord));

                LineCount := pLongWord(@Buffer[Idx])^;
                Inc(Idx, SizeOf(LongWord));
                If LineCount < 1 Then Goto DoneLoad;

                If StrCopy(@Buffer[Idx], 4) = 'PROG' Then Begin

                  // Program name here

                  Inc(Idx, 4);
                  NameLen := pLongWord(@Buffer[Idx])^;
                  Inc(Idx, SizeOf(LongWord));

                  pName := StrCopy(@Buffer[Idx], NameLen);
                  Inc(Idx, NameLen);

                End;

                SetLength(NewProg, LineCount);

                For lIdx := 1 To LineCount Do Begin

                  LineLen := pLongWord(@Buffer[Idx])^;
                  Inc(Idx, SizeOf(LongWord));

                  ProgLine := StrCopy(@Buffer[Idx], LineLen);
                  Inc(Idx, LineLen);

                  CheckSum := pLongWord(@Buffer[Idx])^;
                  Inc(Idx, SizeOf(LongWord));

                  // Got the tokens, now strip off the p-code and re-tokenise to test for errors.

                  If CheckSum = GetCRC32FromString(ProgLine) Then Begin

                    Posn := 1;
                    PlainCode := SP_Detokenise(ProgLine, cPos, false, True);
                    NewProg[lIdx -1] := PlainCode;

                  End Else Begin
                    Error.Code := SP_ERR_FILE_CORRUPT;
                    Goto Finish;
                  End;

                End;

                Goto Finish;

              End Else

                If StrCopy(@Buffer[0], 7) = 'ZXASCII' Then Begin

                  // ASCII text file - start grabbing lines!

                  SetLength(NewProg, 0);
                  LineCount := 0;
                  Idx := 7;

                  // Now start pulling in lines.

                  While Idx < FileSize Do Begin

                    lIdx := Idx;
                    Done := False;
                    InString := False;
                    While not Done Do Begin
                      If (Buffer[lIdx] in [13, 10]) or (lIdx >= FileSize) Then
                        Done := True
                      Else
                        Inc(lIdx);
                    End;

                    // Now grab the characters from Idx up to (but not including) lIdx, and process.

                    ProgLine := StrCopy(@Buffer[Idx], lIdx - Idx);
                    PlainCode := StripLeadingSpaces(ProgLine);
                    Idx := lIdx;
                    While (Idx < Length(Buffer)) And (Buffer[Idx] in [13, 10]) Do Inc(Idx);

                    // Strip trailing spaces
                    While (ProgLine <> '') And (ProgLine[Length(ProgLine)] <= ' ') Do
                      ProgLine := Copy(ProgLine, 1, Length(ProgLine) -1);

                    // Now figure out what it is and what to do with it.
                    If ProgLine <> '' Then Begin
                      If Lower(Copy(PlainCode, 1, 4)) = 'auto' Then Begin
                        PlainCode := Copy(PlainCode, 5, Length(PlainCode));
                        While Copy(PlainCode, 1, 1) <= ' ' Do
                          PlainCode := Copy(PlainCode, 2, Length(PlainCode));
                        If Not Merge Then
                          AutoStart := StrToIntDef(String(PlainCode), 0);
                        ProgLine := '';
                      End Else Begin
                        If Lower(Copy(PlainCode, 1, 4)) = 'prog' Then Begin
                          PlainCode := Copy(PlainCode, 5, Length(PlainCode));
                          While Copy(PlainCode, 1, 1) <= ' ' Do
                            PlainCode := Copy(PlainCode, 2, Length(PlainCode));
                          pName := PlainCode;
                          If SP_ExtractFileDir(pName) = '' Then
                            pName := SP_ConvertHostFilename(SP_GetCurrentDir + '/', Error) + SP_ExtractFilename(pName);
                          ProgLine := '';
                        End Else Begin
                          If Lower(Copy(PlainCode, 1, 7)) = 'changed' Then Begin
                            PlainCode := Copy(PlainCode, 8, Length(PlainCode));
                            While Copy(PlainCode, 1, 1) <= ' ' Do
                              PlainCode := Copy(PlainCode, 2, Length(PlainCode));
                            If Filename <> 's:autosave' Then
                              changed := False
                            else
                              If Lower(Copy(Plaincode, 1, 4)) = 'true' Then
                                changed := True
                              Else
                                changed := False;
                            ProgLine := '';
                          End Else Begin

                            Inc(LineCount);
                            SetLength(NewProg, LineCount);
                            NewProg[LineCount -1] := ProgLine;
                            ProgLine := '';

                          End;
                        End;
                      End;
                    End;

                  End;

                  // Check if the final line had no carriage-return - if so, the line would not have been tokenised.

                  If ProgLine <> '' Then Begin
                    Inc(LineCount);
                    SetLength(NewProg, LineCount);
                    NewProg[LineCount -1] := ProgLine;
                  End;

                  Goto Finish;

                End Else Begin
                  Error.Code := SP_ERR_FILE_CORRUPT;
                  Goto Finish;
                End;

            End Else
              Goto Finish;

          End Else
            Goto Finish;

        End;

      End Else
        Goto Finish;

    End Else
      Goto Finish;

  End Else
    Error.Code := SP_ERR_COULD_NOT_OPEN_FILE;

Finish:

  If pList = nil Then Begin

    If Error.Code = SP_ERR_OK Then Begin

      SP_DeleteIncludes;
      DoAutoSave(Error);

      If Not Merge Then Begin

        CompilerLock.Enter;
        Listing.Clear;
        SyntaxListing.Clear;
        CompiledListing.Clear;
        For Idx := 0 To Length(NewProg) -1 Do Begin
          s := NewProg[Idx]; i := 1;
          While (i < Length(s)) And (s[i] = #9) Do Inc(i);
          SP_AddLine(Copy(s, i), '', '');
          If i > 1 Then Listing.Flags[Listing.Count -1].Indent := i -1;
          Listing.Flags[Listing.Count -1].ReturnType := spHardReturn;
          SP_MarkAsDirty(Idx);
          SP_FPApplyHighlighting(Listing.Count -1);
        End;
        FILECHANGED := changed;
        CompilerLock.Leave;

        SP_ForceCompile;

      End Else Begin

        For Idx := 0 To Length(NewProg) -1 Do Begin

        End;

      End;

      SP_FillFlags;

      If (AutoStart <> -1) And Not Merge Then Begin
        NXTLINE := SP_FindLine(AutoStart, False);
        Error.ReturnType := SP_JUMP;
        SP_PreParse(True, Error);
        FileID := -1;
      End;
      If Not Merge Then Begin
        If SP_FileExists(pName) Then Begin
          SP_SetCurrentDir(SP_ExtractFileDir(pName), Error);
          PROGNAME := Lower(SP_ConvertPathToAssigns(pName));
          If Not INSTARTUP Then
            SP_AddToRecentFiles(PROGNAME, False);
          FILENAMED := True;
        End Else Begin
          PROGNAME := SP_ExtractFilename(pName);
          FILENAMED := False;
        End;
      End;
      If SP_Program_Count > 0 Then
        SP_SysVars.PROGLINE := SP_GetFPLineNumber(0);
    End;

  End Else Begin

    pList.Clear;
    For Idx := 0 To Length(NewProg) -1 Do
      pList.Add(NewProg[Idx]);

  End;

DoneLoad:

  SetLength(NewProg, 0);

  If FileID > -1 Then SP_FileClose(FileID, Error);

  CONTLINE := 0;
  CONTSTATEMENT := 1;

End;

Procedure SP_SetAssign(Ass, Path: aString; var Error: TSP_ErrorCode);
Var
  Idx, ListPos: Integer;
Begin

  Error.Code := SP_ERR_OK;

  // First determine if the Assignment is valid - the name doesn't contain any
  // illegal characters.

  If Ass[Length(Ass)] = ':' Then
    Ass := Copy(Ass, 1, Length(Ass) -1);

  Idx := 1;
  While Idx < Length(Ass) Do Begin
    If Ass[Idx] in ['0'..'9', 'a'..'z', '_'] Then
      Inc(Idx)
    Else Begin
      Error.Code := SP_ERR_INVALID_ASSIGNMENT;
      Exit;
    End;
  End;

  // Now find the Assignment, if it exists.

  Idx := 0;
  ListPos := -1;
  While Idx < Length(SP_Ass_List) Do Begin
    If Copy(SP_Ass_List[Idx], 1, Pos(#255, SP_Ass_List[Idx]) -1) = Ass Then Begin
      ListPos := Idx;
      Break;
    End Else
      Inc(Idx);
  End;

  // If the path is empty, then remove the Assignment, if it exists.

  If Path = '' Then Begin

    If ListPos >= 0 then Begin

      For Idx := ListPos To Length(SP_Ass_List) -2 Do
        SP_Ass_List[Idx] := SP_Ass_List[Idx +1];
      SetLength(SP_Ass_List, Length(SP_Ass_List) -1);

    End;

  End Else Begin

    // Otherwise, check the path - does it exist in the host filesystem?

    Path := SP_ConvertFilenameToHost(Path, Error);
    If DirectoryExists(String(Path)) Then Begin

      // Path exists, so add/update the assignment.

      Path := SP_ConvertHostFilename(Path, Error);

      If ListPos <> -1 Then Begin

        SP_Ass_List[ListPos] := Ass + #255 + Path;

      End Else Begin

        SetLength(SP_Ass_List, Length(SP_Ass_List) +1);
        SP_Ass_List[Length(SP_Ass_List) -1] := Ass + #255 + Path;

      End;

    End Else

      Error.Code := SP_ERR_DIR_NOT_FOUND;

  End;

End;

Function SP_Decode_Assignment(Ass: aString; var Error: TSP_ErrorCode): aString;
Var
  Idx, ListPos: Integer;
Begin

  Result := '';
  Error.Code := SP_ERR_OK;

  If Ass[Length(Ass)] = ':' Then
    Ass := Copy(Ass, 1, Length(Ass) -1);

  // Now find the Assignment, if it exists.

  Idx := 0;
  ListPos := -1;
  While Idx < Length(SP_Ass_List) Do Begin
    If Lower(Copy(SP_Ass_List[Idx], 1, Pos(#255, SP_Ass_List[Idx]) -1)) = Lower(Ass) Then Begin
      ListPos := Idx;
      Break;
    End Else
      Inc(Idx);
  End;

  If ListPos = -1 Then Begin
    If Ass = '$' Then
      Result := SP_ConvertHostFilename(aString(GetCurrentDir+PathDelim), Error)
    Else
      Error.Code := SP_ERR_ASSIGNMENT_NOT_FOUND;
  End Else Begin
    Result := Copy(SP_Ass_List[ListPos], Pos(#255, SP_Ass_List[ListPos]) +1, Length(SP_Ass_List[ListPos]));
    If Copy(Result, Length(Result), 1) <> '/' Then
      Result := Result + '/';
  End;

End;

Function SP_ConvertPathToAssigns(Filename: aString): aString;
Var
  i, j, alen, pLen, aIdx: Integer;
  fName, Ass, Path, s: aString;
Begin

  alen := 0; aIdx := -1;
  fName := Lower(Filename);
  For i := 1 To Length(SP_Ass_List) -1 Do Begin
    s := SP_Ass_List[i];
    j := Pos(#255, s);
    Ass := Copy(s, 1, j -1);
    Path := Copy(s, j +1);
    pLen := Length(Path);
    If Lower(Path) = Copy(fName, 1, pLen) Then
      If aLen < pLen Then Begin
        aLen := pLen;
        aIdx := i;
      End;
  End;

  If aIdx > -1 Then Begin
    s := SP_Ass_List[aIdx];
    j := Pos(#255, s);
    Ass := Copy(s, 1, j -1);
    Path := Copy(s, j +1);
    pLen := Length(Path);
    Filename := Copy(Filename, pLen +1);
    While Filename[1] = '/' Do
      Filename := Copy(Filename, 2);
    Filename := Ass + ':' + Filename;
  End;

  Result := Filename;

End;

Function SP_DecomposePathWithAssigns(Path: aString): aString;
Var
  i, l: Integer;
  s: aString;
Begin

  For i := 0 To Length(SP_Ass_List) -1 Do Begin
    s := SP_Ass_List[i];
    s := Copy(s, 1, Pos(#255, s) -1) + ':';
    l := Length(s);
    If Copy(Path, 1, l) = s Then Begin
      Result := Copy(SP_Ass_List[i], Pos(#255, SP_Ass_List[i]) +1) + Copy(Path, l +1);
      Exit;
    End;
  End;

  Result := Path;

End;

Function SP_GetCurrentDir: aString;
Begin

  If Not PackageIsOpen Then
    Result := aString(GetCurrentDir)
  Else
    Result := SP_GetPackageDir;

End;

Function SP_DirectoryExists(Dir: aString): Boolean;
Var
  Error: TSP_ErrorCode;
Begin

  If PackageIsOpen And (Pos(':', String(Dir)) = 0) then
    Result := SP_PackageDirExists(Dir, Error)
  Else
    Result := DirectoryExists(String(SP_ConvertFilenameToHost(Dir, Error)));

End;

Procedure SP_DeleteFile(Filename: aString; var Error: TSP_ErrorCode);
Begin

  If PackageIsOpen And (Pos(':', String(Filename)) = 0) Then
    SP_DeletePackageFile(Filename, Error)
  Else Begin
    Filename := SP_ConvertFilenameToHost(Filename, Error);
    If Error.Code = SP_ERR_OK Then
      If FileExists(String(Filename)) Then
        DeleteFile(String(Filename))
      Else
        Error.Code := SP_ERR_FILE_MISSING;
  End;

End;

Procedure SP_SetCurrentDir(Dir: aString; Var Error: TSP_ErrorCode);
Begin

  If Dir <> '' Then
    If Not PackageIsOpen or (Pos(':', String(Dir)) > 0) Then Begin
      Dir := SP_ConvertFilenameToHost(Dir, Error);
      If Not SetCurrentDir(String(Dir)) Then
        Error.Code := SP_ERR_DIR_NOT_FOUND;
    End Else
      SP_SetPackageDir(Dir, Error);

End;

Function SP_FixMask(Var FileSpec: aString): aString;
Var
  MinPos, MQ, MS, Idx: Integer;
Begin

  Result := SP_ExtractFileDir(FileSpec);
  FileSpec  := SP_ExtractFileName(FileSpec);

  // If there are '*' or '?' in the path string, then they should be in the filespec.

  MinPos := 0;
  MQ := Pos('?', String(Result));
  MS := Pos('*', String(Result));
  If (MQ > 0) or (MS > 0) Then Begin
    If MQ <> 0 Then
      If MS <> 0 Then Begin
        If MQ < MS Then
          MinPos := MQ
        Else
          MinPos := MS;
      End Else
        MinPos := MQ;
    If MS <> 0 Then
      If MQ <> 0 Then Begin
        If MS < MQ Then
          MinPos := MS
        Else
          MinPos := MQ;
      End Else
        MinPos := MS;
    Idx := MinPos;
    While Idx > 0 Do
      If Result[Idx] = PathDelim Then
        Break
      Else
        Dec(Idx);
    If Idx > 0 Then
      MinPos := Idx +1;
    FileSpec := Copy(Result, MinPos, Length(Result)) + FileSpec;
    Result := Copy(Result, 1, MinPos -1);
  End;

End;

Function SP_GetFileListRecursive(Var FileSpec: aString; WantEXP: Boolean; Var Error: TSP_ErrorCode): aString;
Var
  Files, FileSizes, Dirs: TAnsiStringList;
  TempStr, ResultStr, PadStr, fSpec, pSpec: aString;
  Idx, FileCount, DirIns, MaxSize, SizeCount: Integer;
Begin

  Result := '';

  Files := TAnsiStringList.Create;
  FileSizes := TAnsiStringList.Create;

  fSpec := FileSpec;
  pSpec := SP_FixMask(fSpec);

  SP_GetFileList(FileSpec, Files, FileSizes, Error, True);

  Idx := 0;
  Dirs := TAnsiStringList.Create;

  While Idx < Files.Count Do Begin

    If LongWord(Files.Objects[Idx]) = 1 Then Begin
      Dirs.Add(Files[Idx]);
      Files.Delete(Idx)
    End Else
      Inc(Idx);

  End;

  If Files.Count > 0 Then Begin

    ResultStr := 'File list for ' + FileSpec + #13#13;

    FileCount := 0;
    Files.Sort;

    MaxSize := 0;
    SizeCount := 0;
    For Idx := 0 To FileSizes.Count -1 Do Begin
      Inc(SizeCount, LongWord(FileSizes.Objects[Idx]));
      If Length(FileSizes[Idx]) > MaxSize Then
        MaxSize := Length(FileSizes[Idx]);
    End;

    If WantEXP Then Begin
      PadStr := aString(StringOfChar(' ', MaxSize +1));
      For Idx := 0 To Files.Count -1 Do Begin
        ResultStr := ResultStr + aString(StringOfChar(' ', MaxSize - Length(FileSizes[Idx])) + FileSizes[Idx] + ' ' + Files[Idx])+#13;
        Inc(FileCount);
      End;
    End Else Begin
      PadStr := '';
      For Idx := 0 To Files.Count -1 Do Begin
        ResultStr := ResultStr + aString(Files[Idx])+#13;
        Inc(FileCount);
      End;
    End;

    ResultStr := ResultStr + #13#13;

  End;

  If pSpec <> '' Then
    SP_SetCurrentDir(pSpec, Error);

  For Idx := 0 To Dirs.Count -1 Do Begin

    SP_SetCurrentDir(Dirs[Idx], Error);
    FileSpec := fSpec;
    ResultStr := ResultStr + SP_GetFileListRecursive(FileSpec, WantEXP, Error);
    FileSpec := fSpec;
    SP_SetCurrentDir('..', Error);

  End;

  Result := ResultStr;

  FileSizes.Free;
  Files.Free;
  Dirs.Free;

End;

Procedure SP_GetFileList(Var FileSpec: aString; Var Files, FileSizes: TAnsiStringList; Var Error: TSP_ErrorCode; PreserveDirs: Boolean);
Var
  PathStr: aString;
  Idx: Integer;
  HostPath: Boolean;
Begin

  HostPath := Pos(':', String(FileSpec)) > 0;
  If HostPath or Not PackageIsOpen then
    FileSpec := SP_ConvertFilenameToHost(FileSpec, Error);

  If Error.Code <> SP_ERR_OK Then Exit;

  PathStr := SP_FixMask(FileSpec);

  // If no path was specified, then use the current folder, in host format.

  If PathStr = '' Then
    PathStr := SP_GetCurrentDir;

  If Not PackageIsOpen or HostPath Then Begin
    If Copy(PathStr, Length(PathStr), 1) <> PathDelim Then
      PathStr := PathStr + PathDelim;
  End Else
    If PackageIsOpen Then
      If Copy(PathStr, Length(PathStr), 1) <> '/' Then
        PathStr := PathStr + '/';

  If SP_DirectoryExists(PathStr) Then Begin

    // Get all the files in the folder.

    SP_FindAll(PathStr + '*', Files, FileSizes);

    // Was the only file matching, actually the filespec? If so, is the filespec a folder?

    If (FileSpec <> '') And (Files.Count > 0) Then Begin
      Idx := 0;
      While Idx < Files.Count Do Begin
        If SP_DirectoryExists(PathStr + aString(Files[Idx])) Then Begin
          If PreserveDirs Then
            Inc(Idx)
          Else
            If Not (WildComp(Lower(FileSpec), Lower(aString(Files[Idx]))) or WildComp(Lower(FileSpec), Lower(aString(Files[Idx]+PathDelim)))) Then Begin
              Files.Delete(Idx);
              FileSizes.Delete(Idx);
            End Else
              Inc(Idx);
        End Else
          If Not WildComp(Lower(FileSpec), Lower(aString(Files[Idx]))) Then Begin
            Files.Delete(Idx);
            FileSizes.Delete(Idx);
          End Else
            Inc(Idx);
      End;
    End;

    If (Files.Count = 1) And (Lower(aString(Files[0])) = Lower(FileSpec)) And (SP_IsDirectory(PathStr + FileSpec)) Then Begin

      // If the filespec is a directory, and it's the only entry, then get all the files in that directory

      Files.Clear;
      FileSizes.Clear;
      SP_FindAll(PathStr + FileSpec + aString(PathDelim) + '*', Files, FileSizes);

    End;

    If (Files.Count > 0) And (Files[0] = '.') Then Begin Files.Delete(0); FileSizes.Delete(0); End;
    If (Files.Count > 0) And (Files[0] = '..') Then Begin Files.Delete(0); FileSizes.Delete(0); End;

    If PackageIsOpen And Not HostPath Then
      FileSpec := PathStr
    Else
      FileSpec := SP_ConvertHostFilename(PathStr, Error);

  End Else

    Error.Code := SP_ERR_DIR_NOT_FOUND;

End;

Function SP_IsDirectory(const Path: aString): Boolean;
var
  Attr: Integer;
  Error: TSP_ErrorCode;
begin
  If PackageIsOpen And (Pos(':', String(Path)) = 0) Then
    Result := SP_PackageDirExists(Path, Error)
  Else Begin
    Attr := SysUtils.FileGetAttr(String(Path));
    Result := (Attr <> -1) and (Attr And SysUtils.faDirectory <> 0);
  End;
end;

Function SP_GetParentDir(Const Dir: aString): aString;
Var
  c: aChar;
  i: Integer;
Begin

  i := Length(Dir);
  While (i > 1) And (Dir[i] = '/') Do Dec(i);
  c := Dir[i];
  If c = ':' Then Begin
    Result := '/';
    Exit;
  End;

  While (i > 0) And Not (Dir[i] in [':', '/']) Do
    Dec(i);

  If i = 0 Then
    Result := '/'
  Else
    Result := Copy(Dir, 1, i);

End;

Procedure SP_RmDir(DirString: aString; var Error: TSP_ErrorCode);
Begin

  If PackageIsOpen And (Pos(':', String(DirString)) = 0) Then
    SP_PackageDeleteDir(DirString, Error)
  Else Begin
    DirString := SP_ConvertFilenameToHost(DirString, Error);
    If Lower(DirString) <> lower(HOMEFOLDER) Then
      RmDir(String(Sp_ConvertFilenameToHost(DirString, Error)));
  End;

End;

Procedure SP_RmDirUnsafe(DirString: aString; Var Error: TSP_ErrorCode);
var
  Path: string;
  Search: TSearchRec;
begin
  Error.Code := SP_ERR_OK;
  Path := IncludeTrailingBackslash(SP_ConvertFilenameToHost(DirString, Error));
  If Error.Code = SP_ERR_OK Then Begin
    If FindFirst(Path + '*.*', faAnyFile, Search) = 0 then
    try
      repeat
        if (Search.Attr and faDirectory) <> 0 then
          SP_RmDirUnSafe(Path + Search.Name, Error)
        else
          DeleteFile(Path + Search.Name);
      until SysUtils.FindNext(Search) <> 0;
    finally
      FindClose(Search);
    end;
    RmDir(Path);
  End;
end;

Procedure SP_DeleteDirContents(DirString: aString; var Error: TSP_ErrorCode);
Var
  Dir: aString;
  Idx: Integer;
  Files, FileSizes: TAnsiStringList;
Begin

  Dir := DirString;
  Files := TAnsiStringList.Create;
  FileSizes := TAnsiStringList.Create;
  SP_GetFileList(DirString, Files, FileSizes, Error, False);

  If Files.Count > 0 Then Begin

    For Idx := 0 To Files.Count -1 Do Begin

      If LongWord(Files.Objects[Idx]) = 0 Then
        SP_DeleteFile(aString(Files[Idx]), Error)
      Else Begin
        If Copy(DirString, Length(DirString), 1) = '/' Then
          SP_DeleteDirContents(DirString + aString(Files[Idx]), Error)
        Else
          SP_DeleteDirContents(DirString + '/' + aString(Files[Idx]), Error);

        SP_RmDir(DirString, Error);

      End;

    End;

  End;

End;

Procedure SP_CopyFiles(FileSpec, Dest: aString; Overwrite: Boolean; var Error: TSP_ErrorCode);
Var
  Idx, FileID_Src, FileID_Dst, BytesRead, BuffSize: Integer;
  Buffer: Array of Byte;
  Files, FileSizes: TAnsiStringList;
  OrgFileSpecDir: aString;
Begin

  Files := TAnsiStringList.Create;
  FileSizes := TAnsiStringList.Create;
  BuffSize := 1024*1024-1;
  SetLength(Buffer, BuffSize);

  OrgFileSpecDir := SP_ExtractFileDir(FileSpec);

  SP_GetFileList(FileSpec, Files, FileSizes, Error, False);

  If Files.Count > 0 Then Begin

    If SP_DirectoryExists(Dest) Then Begin

      If Copy(Dest, Length(Dest), 1) <> '/' Then
        Dest := Dest + '/';

      For Idx := 0 To Files.Count -1 Do Begin

        If SP_FileExists(Dest + aString(Files[Idx])) Then
          If Overwrite Then
            SP_DeleteFile(Dest + aString(Files[Idx]), Error);

        If Not (SP_FileExists(Dest + aString(Files[Idx]))) And SP_DirectoryExists(Dest) Then Begin

          FileID_Src := SP_FileOpen(OrgFileSpecDir + aString(Files[Idx]), False, Error);
          FileID_Dst := SP_FileOpen(Dest + aString(Files[Idx]), True, Error);

          SP_FileSeek(FileID_Src, 0, Error);

          Repeat

            BytesRead := SP_FileRead(FileID_Src, @Buffer[0], BuffSize, Error);
            SP_FileWrite(FileID_Dst, @Buffer[0], BytesRead, Error);

          Until BytesRead = 0;

          SP_FileClose(FileID_Src, Error);
          SP_FileClose(FileID_Dst, Error);

        End Else Begin

          Error.Code := SP_ERR_FILE_ALREADY_EXISTS;
          Break;

        End;

      End;

    End Else

      Error.Code := SP_ERR_DIR_NOT_FOUND;

  End Else

    Error.Code := SP_ERR_FILE_MISSING;

  Files.Free;
  FileSizes.Free;

End;

Procedure SP_MoveFiles(FileSpec, Dest: aString; Overwrite: Boolean; var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Files, FileSizes: TAnsiStringList;
Begin

  // Moves the specified filespec to the directory specified. Dest must exist,
  // Filespec must reference at least one valid file.

  SP_CopyFiles(FileSpec, Dest, Overwrite, Error);

  If Error.Code = SP_ERR_OK Then Begin

    Files := TAnsiStringList.Create;
    FileSizes := TAnsiStringList.Create;

    SP_GetFileList(FileSpec, Files, FileSizes, Error, False);

    If Files.Count > 0 Then Begin

      For Idx := 0 To Files.Count -1 Do Begin

        SP_DeleteFile(FileSpec + aString(Files[Idx]), Error);
        If Error.Code <> SP_ERR_OK Then Break;

      End;

    End;

    Files.Free;
    FileSizes.Free;

  End;

End;

Procedure SP_MakeDir(Dir: aString; var Error: TSP_ErrorCode);
Begin

  If PackageIsOpen And (Pos(':', String(Dir)) = 0) Then Begin

    SP_PackageCreateDir(Dir, Error);

  End Else Begin

    Dir := SP_ConvertFilenameToHost(Dir, Error);

    If SP_DirectoryExists(Dir) Then
      Error.Code := SP_ERR_DIR_ALREADY_EXISTS
    Else Begin
      {$IOChecks off}
      MkDir(String(Dir));
      If IOResult <> 0 Then
        Error.Code := SP_ERR_DIR_CREATE_FAILED;
      {$IOChecks on}
    End;

  End;

End;

Procedure SP_FileRename(Src, Dst: aString; var Error: TSP_ErrorCode);
Begin

  // Rename a host-filesystem file. Filename must be in host format.

  If FileExists(String(Src)) Then begin

    {$IOChecks off}
    RenameFile(String(Src), String(Dst));
    If IOResult <> 0 Then
      Error.Code := SP_ERR_RENAME_FAILED;
    {$IOChecks on}

  End Else

    Error.Code := SP_ERR_FILE_MISSING;

End;

Procedure SP_RenameFiles(SrcFiles, DstFiles: aString; var Error: TSP_ErrorCode);
Var
  Idx, SrcPtr, DstPtr, FilePtr, pS, oSP: Integer;
  FileSpec, chkMask, SrcMask, DstMask, OrgFilename, NewFilename, nTerm: aString;
  Files, FileSizes: TAnsiStringList;
  SrcHost, DstHost, HostFS: Boolean;
Begin

  // Renames a Single file, a directory or a Wildcard-spec in *both* src and dst.

  SrcFiles := Lower(SrcFiles);
  DstFiles := Lower(DstFiles);

  SrcHost := Pos(':', String(SrcFiles)) > 0;
  DstHost := Pos(':', String(DstFiles)) > 0;

  If SrcHost <> DstHost Then Begin
    Error.Code := SP_ERR_PACKAGE_RENAME_HOST;
    Exit;
  End Else
    HostFS := SrcHost;

  If (Pos('?', String(SrcFiles)) = 0) And (Pos('*', String(SrcFiles)) = 0) And (Pos('?', String(DstFiles)) = 0) And (Pos('*', String(DstFiles)) = 0) Then Begin

    If HostFS Then
      SP_FileRename(SP_ConvertFilenameToHost(SrcFiles, Error), SP_ConvertFilenameToHost(DstFiles, Error), Error)
    Else
      SP_PackageFileRename(SrcFiles, DstFiles, Error);

  End Else Begin

    // Check masks for matches and validity.

    SrcMask := ''; Idx := Length(SrcFiles); While (Idx > 0) And (Not (SrcFiles[Idx] in ['/', ':'])) Do Begin SrcMask := SrcFiles[Idx] + SrcMask; Dec(Idx); End;
    DstMask := ''; Idx := Length(DstFiles); While (Idx > 0) And (Not (DstFiles[Idx] in ['/', ':'])) Do Begin DstMask := DstFiles[Idx] + DstMask; Dec(Idx); End;
    chkMask := ''; Idx := 1; While Idx < Length(SrcMask) Do Begin If SrcMask[Idx] in ['?', '*'] Then chkMask := chkMask + SrcMask[Idx]; Inc(Idx); End;

    DstPtr := 1;
    For Idx := 1 To Length(DstMask) Do
      If DstMask[Idx] in ['?', '*'] Then
        If DstPtr > Length(chkMask) then Begin
          Error.Code := SP_ERR_MISMATCHED_MASK;
          Exit;
        End Else
          If chkMask[DstPtr] = DstMask[Idx] Then
            Inc(DstPtr)
          Else Begin
            Error.Code := SP_ERR_MISMATCHED_MASK;
            Exit;
          End;

    // Masks appear fine - gather a list of files that match the source filespec.

    Files := TAnsiStringList.Create;
    FileSizes := TAnsiStringList.Create;

    FileSpec := SrcFiles;
    SP_GetFileList(FileSpec, Files, FileSizes, Error, False);

    If Files.Count > 0 Then Begin

      For Idx := 0 To Files.Count -1 Do Begin

        OrgFilename := Lower(aString(Files[Idx]));
        NewFilename := '';

        SrcPtr := 1;
        DstPtr := 1;
        FilePtr := 1;

        While SrcPtr <= Length(SrcMask) Do Begin

          If SrcMask[SrcPtr] = '*' Then Begin
            oSP := SrcPtr +1;
            nTerm := '';
            Inc(SrcPtr);
            Inc(DstPtr);
            While (SrcPtr <= Length(SrcMask)) And (SrcMask[SrcPtr] <> '*') Do Begin
              nTerm := nTerm + SrcMask[SrcPtr];
              Inc(SrcPtr);
            End;
            If nTerm = '' Then Begin
              If SrcPtr > Length(SrcMask) Then
                NewFilename := NewFilename + Copy(OrgFilename, FilePtr, Length(OrgFilename));
            End Else Begin
              pS := Pos(nTerm, Copy(OrgFilename, FilePtr, Length(OrgFilename)));
              If pS > 0 Then Begin
                NewFilename := NewFilename + Copy(Copy(OrgFilename, FilePtr, Length(OrgFilename)), 1, pS -1);
                Inc(FilePtr, pS);
              End;
              SrcPtr := oSP;
            End;
          End Else
            If SrcMask[SrcPtr] = '?' Then Begin
              Inc(SrcPtr);
              Inc(DstPtr);
              NewFilename := NewFileName + OrgFilename[FilePtr];
              Inc(FilePtr);
            End Else Begin
              While (SrcPtr <= Length(SrcMask)) And Not (SrcMask[SrcPtr] in ['?', '*']) Do Begin
                Inc(SrcPtr);
                Inc(FilePtr);
              End;
              While (DstPtr <= Length(DstMask)) And Not (DstMask[DstPtr] in ['?', '*']) Do Begin
                NewFilename := NewFilename + DstMask[DstPtr];
                Inc(DstPtr);
              End;
            End;

        End;

        If HostFS Then
          SP_FileRename(SP_ConvertFilenameToHost(FileSpec + OrgFilename, Error), SP_ConvertFilenameToHost(NewFilename, Error), Error)
        Else
          SP_PackageFileRename(FileSpec + OrgFilename, NewFilename, Error);

      End;

    End Else

      Error.Code := SP_ERR_FILE_MISSING;

  End;

End;

Function SP_ExtractFilename(Filename: aString): aString;
Var
  Idx: Integer;
Begin

  Result := '';

  If Filename <> '' Then Begin

    Idx :=  Length(Filename);
    While (Idx > 0) And not (Filename[Idx] in ['/', '\', ':']) Do Begin
      Result := Filename[Idx] + Result;
      Dec(Idx);
    End;

  End;

End;

Function SP_ExtractFileDir(Filename: aString): aString;
Var
  Idx: Integer;
Begin

  Result := '';

  If Filename <> '' Then Begin

    Idx := Length(Filename);
    While (Idx > 0) And not (Filename[Idx] in [':', '/', '\']) Do
      Dec(Idx);

    Result := Copy(Filename, 1, Idx);

  End;

End;

Procedure SP_AddToRecentFiles(Filename: aString; Saving: Boolean);
Var
  i, j, l: Integer;
  Exists: Boolean;
Begin

  If (Lower(Filename) = 's:startup-sequence') or
     (Lower(Filename) = 's:autosave') or
     (Lower(Filename) = '/s/startup-sequence') or
     (Lower(Filename) = '/s/autosave') Then Exit;

  If Not Saving And Not SP_FileExists(Filename) then Exit;

  Filename := SP_ConvertPathToAssigns(Filename);

  // Check if the filename already exists in the recents list.

  i := 0;
  Exists := False;
  l := Length(SP_RecentFiles);
  While i < Length(SP_RecentFiles) Do
    If Lower(SP_RecentFiles[i]) = Lower(Filename) Then Begin
      Exists := True;
      Break;
    End Else
      Inc(i);

  If Exists Then Begin

    // Already exists - move it to the top of the list.
    // First, delete it. The rest of the routine will handle insertion at position 0
    For j := i To l -2 Do
      SP_RecentFiles[j] := SP_RecentFiles[j +1];

  End Else Begin

    If Length(SP_RecentFiles) < 10 Then Begin
      SetLength(SP_RecentFiles, l +1);
      Inc(l);
    End;

  End;

  // Now insert at position 0.

  For j := l -1 DownTo 1 Do
    SP_RecentFiles[j] := SP_RecentFiles[j -1];

  SP_RecentFiles[0] := Filename;
  SP_SaveRecentFiles;

End;

Procedure SP_LoadRecentFiles;
Var
  i: Integer;
  list: TAnsiStringlist;
Begin

  SetLength(SP_RecentFiles, 0);
  If SP_FileExists('s:recent_files') Then Begin

    list := TAnsiStringList.Create;
    list.LoadFromFile('s:recent_files');
    For i := list.Count -1 DownTo 0 Do
      If SP_FileExists(list[i]) Then
        SP_AddToRecentFiles(list[i], False);
    list.Free;

  End;

End;

Procedure SP_SaveRecentFiles;
Var
  i: Integer;
  list: TAnsiStringlist;
Begin

  list := TAnsiStringlist.Create;
  For i := 0 To Length(SP_RecentFiles) -1 Do
    list.Add(SP_RecentFiles[i]);
  list.SaveToFile('s:recent_files');
  list.Free;

End;

Initialization

  FileSection := TCriticalSection.Create;

Finalization

  FileSection.Free;

end.

