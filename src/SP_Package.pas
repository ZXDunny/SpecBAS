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

unit SP_Package;

interface

Uses Math, SP_Util, SP_Errors, Classes, SysUtils, SP_SysVars, SP_AnsiStringlist;

Const

  SP_ChunkSize = 1024;      // Every file takes at least one chunk, so every file is at least 1024 bytes on disk.

Type

  SP_FileChunk = Packed Record
    ChunkData: Array[0..SP_ChunkSize -1] of Byte;
    Allocated: Boolean;     // Allocated chunks belong to files. Unallocated chunks can be removed when the package is closed.
    PrevChunk: Integer;
    NextChunk: Integer;
    ChunkSize: LongWord;    // Number of bytes occupied by the file's data in this chunk. Should be 1024, but the last chunk
  End;                      // may be shorter.

  SP_Filename = Array[0..63] of aChar;

  SP_FileEntry = Packed Record
    Filename: SP_Filename;  // Filename, ascii
    FileSize: LongWord;     // Size in bytes
    FileDate: Integer;      // Date last modified
    NumChunks: LongWord;    // Number of chunks used
    LastChunk: Integer;    // The last chunk in the file
    DirectoryID: Integer;   // Directory index number
    FirstChunk: Integer;    // Offset in chunk array of first chunk.
    CurrentChunk: Integer;  // For read/write access - the current chunk pointed to by the SEEK param
    SEEKPos: LongWord;      // position of the SEEK param in the current chunk.
  End;
  pSP_FileEntry = ^SP_FileEntry;

  SP_DirectoryEntry = Packed Record
    DirName: SP_Filename;
    ParentDirectoryID: Integer;
  End;
  pSP_DirectoryEntry = ^SP_DirectoryEntry;

  SP_FileTable = Packed Record
    IDSTRING: Array[0..5] of aChar;
    PackageName: SP_Filename;
    FileCount: LongWord;
    DirCount: LongWord;
    Files: Array[0..255] of SP_FileEntry;
    Directories: Array[0..255] of SP_DirectoryEntry;
    CurDirectory: Integer;
    WriteProtect: Boolean;
  End;

  SP_FileFindRec = Packed Record
    Filename: SP_FileName;
    FoundFileIndex,
    FoundDirIndex: Integer;
  End;

  Procedure SP_CreatePackage(Filename: aString; var Error: TSP_ErrorCode);
  Procedure SP_CreateChunkMap;
  Procedure SP_ClosePackage;

  Procedure SP_CreatePackageFile(Filename: aString; var Error: TSP_ErrorCode);
  Procedure SP_FindPackageFile(Filename: aString; var Found: SP_FileFindRec; var Error: TSP_ErrorCode);
  Function  SP_GetNextChunk: Integer;
  Function  SP_WriteToPackageFile(Filename: aString; BuffPtr: pByte; Size: LongWord; var Error: TSP_ErrorCode): LongWord;
  Function  SP_ReadFromPackageFile(Filename: aString; BuffPtr: pByte; Size: LongWord; var Error: TSP_ErrorCode): LongWord;
  Function SP_ReadLnFromPackageFile(Filename: aString; var Error: TSP_ErrorCode): aString;
  Function  SP_SeekToPackageFile(Filename: aString; SeekPos: LongWord; var Error: TSP_ErrorCode): LongWord;
  Function  SP_GetSeekPosFromPackageFile(Filename: aString; var Error: TSP_ErrorCode): LongWord;
  Function  SP_GetSizeFromPackageFile(Filename: aString; var Error: TSP_ErrorCode): LongWord;
  Function  SP_PackageFileExists(Filename: aString; Var Error: TSP_ErrorCode): Boolean;
  Function  SP_PackageDirExists(Path: aString; Var Error: TSP_ErrorCode): Boolean;
  Procedure SP_DeletePackageFile(Filename: aString; var Error: TSP_ErrorCode);
  Function  SP_PackageGetName(Addr: pByte): aString;
  Function  SP_GetPackageDir: aString;
  Procedure SP_SetPackageDir(Directory: aString; Var Error: TSP_ErrorCode);
  Procedure SP_PackageFindAll(Path: aString; var List, Sizes: TAnsiStringList; var Error: TSP_ErrorCode);
  Procedure SP_TestPackageFile(var Filename: aString; var Error: TSP_ErrorCode);
  Procedure SP_PackageUnpackFile(var Src: aString; var Error: TSP_ErrorCode);
  Procedure SP_DeleteTempFiles;
  Procedure SP_PackageCreateDir(DirString: aString; var Error: TSP_ErrorCode);
  Procedure SP_PackageDeleteDir(DirString: aString; var Error: TSP_ErrorCode);
  Function  SP_PackageFindDir(Path: aString; var Error: TSP_ErrorCode): Integer;
  Procedure SP_PackageFileRename(Src, Dst: aString; var Error: TSP_ErrorCode);
  Procedure SP_PackageAddFile(Filename: aString; var Error: TSP_ErrorCode);
  Procedure SP_ProtectPackage;
  Procedure SP_UnProtectPackage;
  Procedure SP_CleanPackage;

Var

  CurrentPackage: SP_FileTable;
  Package: TFileStream;
  PackageIsOpen: Boolean;
  SP_PackageFiles: Array of LongWord;
  SP_ChunkMap: Array of Boolean;
  PackageNativeName, LastDIR: aString;

implementation

Uses SP_Main, SP_FileIO;

Function CompStr(var Text: SP_Filename; var Filename: aString): Boolean;
Var
  Idx: Integer;
Begin

  Idx := 0;
  Result := False;
  While (Text[Idx] <> #0) Do Begin
    If Text[Idx] <> Filename[Idx +1] Then
      Exit
    Else
      Inc(Idx);
  End;
  Result := True;

End;

Procedure SP_CreatePackage(Filename: aString; var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  fName: aString;
Begin

  // Creates a new package. Filename is a specbas filename, needs converting.

  fName := SP_ConvertFilenameToHost(Filename, Error);
  Filename := SP_ExtractFilename(fName);

  // Only one package can be "open" at once, so close the last package before
  // Continuing.

  If PackageIsOpen Then SP_ClosePackage;

  // Create a new package if it doesn't exist. If it does exist, set the current package ID.

  Try
    If FileExists(String(fName)) Then
      Package := TFileStream.Create(String(fName), fmOpenReadWrite or fmShareDenyNone)
    Else
      Package := TFileStream.Create(String(fName), fmCreate or fmShareDenyNone);
  Except
    On E: Exception Do Begin
      Error.Code := SP_ERR_PACKAGE_CREATE_ERROR;
      Exit;
    End;
  End;

  PackageNativeName := fName;

  If Package.Size = 0 Then Begin
    // Package doesn't already exist, so populate the empty file table
    CurrentPackage.IDSTRING := 'ZXPACK';
    FillMem(@CurrentPackage.PackageName[0], 64, 0);
    CopyMem(@CurrentPackage.PackageName[0], @Filename[1], Length(Filename));
    CurrentPackage.FileCount := 0;
    CurrentPackage.DirCount := 0;
    For Idx := 0 To 255 Do Begin
      FillMem(@CurrentPackage.Files[Idx].Filename[0], 64, 0);
      FillMem(@CurrentPackage.Directories[Idx].DirName[0], 64, 0);
    End;
    CurrentPackage.CurDirectory := -1;
    Package.Write(CurrentPackage, SizeOf(SP_FileTable));
  End Else Begin
    // Package exists, populate the file table from the opened package if possible.
    Package.Seek(0, soFromBeginning);
    Package.Read(CurrentPackage, SizeOf(SP_FileTable));
    CurrentPackage.CurDirectory := -1;
  End;

  If CurrentPackage.IDSTRING <> 'ZXPACK' Then Begin
    Error.Code := SP_ERR_INVALID_PACKAGE;
    PackageIsOpen := False;
    Package.Free;
    Exit;
  End Else Begin
    LastDIR := SP_GetCurrentDir;
    PackageIsOpen := True;
    SP_CreateChunkMap;
  End;

End;

Procedure SP_ClosePackage;
Var
  Err: TSP_ErrorCode;
  tFile: File Of Byte;
Begin

  If PackageIsOpen Then Begin

    // Close all open file handles, finalise the package by
    // iterating through and removing empty chunks.

    SP_CleanPackage;

    Package.Seek(0, soFromBeginning);
    Package.Write(CurrentPackage, SizeOf(SP_FileTable));
    Package.Free;

    // Now truncate the file to the size of the chunktable.

    AssignFile(tFile, String(PackageNativeName));
    Reset(tFile);
    FileMode := 2;
    Seek(tFile, SizeOf(SP_FileTable) + (Length(SP_ChunkMap) * SizeOf(SP_FileChunk)));
    Truncate(tFile);
    CloseFile(tFile);

    PackageIsOpen := False;
    SP_DeleteTempFiles;

    SP_SetCurrentDir(LastDIR, Err);

  End;

End;

Procedure SP_CreateChunkMap;
Var
  Idx: Integer;
  Chunk: SP_FileChunk;
Begin

  SetLength(SP_ChunkMap, (Package.Size - SizeOf(SP_FileTable)) Div SizeOf(SP_FileChunk));

  If Length(SP_ChunkMap) > 0 Then Begin

    For Idx := 0 To Length(SP_ChunkMap) -1 Do
      SP_ChunkMap[Idx] := False;

    Idx := 0;
    Package.Seek(SizeOf(SP_FileTable), soFromBeginning);
    While Package.Position < Package.Size Do Begin
      Package.Read(Chunk, SizeOf(SP_FileChunk));
      SP_ChunkMap[Idx] := Chunk.Allocated;
      Inc(Idx);
    End;

  End;

End;

Procedure SP_CreatePackageFile(Filename: aString; var Error: TSP_ErrorCode);
Var
  Found: SP_FileFindRec;
  NewFile: SP_FileEntry;
  Idx, CurChunk, ChunkPos: Integer;
  NewChunk: SP_FileChunk;
Begin

  If CurrentPackage.WriteProtect Then Begin
    Error.Code := SP_ERR_WRITE_PROTECT;
    Exit;
  End;

  // Add a new file to the package.
  // This is only for overwriting files, not appending to them.

  // Find the file.

  SP_FindPackageFile(Filename, Found, Error);

  If Found.FoundFileIndex <> -1 Then Begin

    // The file exists - erase it's data and set it to zero length.

    CopyMem(@NewFile.Filename[0], @CurrentPackage.Files[Found.FoundFileIndex].Filename[0], SizeOf(SP_FileEntry));

    CurChunk := NewFile.FirstChunk;
    For Idx := 0 To NewFile.NumChunks -1 Do Begin
      ChunkPos := SizeOf(SP_FileTable) + (CurChunk * SizeOf(SP_FileChunk));
      Package.Seek(ChunkPos, soFromBeginning);
      Package.Read(NewChunk, SizeOf(SP_FileChunk));
      SP_ChunkMap[CurChunk] := False;
      NewChunk.Allocated := False;
      NewChunk.ChunkSize := 0;
      CurChunk := NewChunk.NextChunk;
      NewChunk.NextChunk := -1;
      NewChunk.PrevChunk := -1;
      Package.Seek(ChunkPos, soFromBeginning);
      Package.Write(NewChunk, SizeOf(SP_FileChunk));
    End;

    NewFile.FileSize := 0;
    NewFile.NumChunks := 1;
    NewFile.CurrentChunk := NewFile.FirstChunk;
    NewFile.SEEKPos := 0;
    CopyMem(@CurrentPackage.Files[Found.FoundFileIndex].Filename[0], @NewFile.Filename[0], SizeOf(SP_FileEntry));

  End Else Begin

    // If filename contains a directory, then find it and create the file there.
    // If it's just a filename then create it in the current directory.

    If Error.Code = SP_ERR_DIR_NOT_FOUND Then
      Exit
    Else Begin

      // Clear the "file not found" error

      Error.Code := SP_ERR_OK;

      Filename := SP_ExtractFilename(Filename);
      FillMem(@NewFile.Filename[0], SizeOf(SP_FileName), 0);
      CopyMem(@NewFile.Filename[0], @Filename[1], Length(Filename));
      NewFile.NumChunks := 0;
      NewFile.FileSize := 0;
      NewFile.DirectoryID := Found.FoundDirIndex;
      NewFile.SEEKPos := 0;
      NewFile.FirstChunk := SP_GetNextChunk;
      NewFile.CurrentChunk := NewFile.FirstChunk;
      NewFile.LastChunk := NewFile.FirstChunk;
      Inc(CurrentPackage.FileCount);
      CopyMem(@CurrentPackage.Files[CurrentPackage.FileCount -1].Filename[0], @NewFile.Filename[0], SizeOf(SP_FileEntry));

    End;

  End;

  NewFile.FileDate := DateTimeToFileDate(Now);

End;

Function SP_GetNextChunk: Integer; inline;
Var
  Idx: Integer;
  NewChunk: SP_FileChunk;
Begin

  // Searches the current package for the next available chunk.

  For Idx := 0 To Length(SP_ChunkMap) -1 Do Begin
    If SP_ChunkMap[Idx] = False Then Begin
      Result := Idx;
      Exit;
    End;
  End;

  // Did not find an unallocated chunk, so make a new one.

  SetLength(SP_ChunkMap, Length(SP_ChunkMap) +1);
  Result := Length(SP_ChunkMap) -1;

  Package.Seek(0, soFromEnd);
  NewChunk.Allocated := False;
  NewChunk.ChunkSize := 0;
  NewChunk.NextChunk := -1;
  Package.Write(NewChunk, SizeOf(SP_FileChunk));

End;

Procedure SP_FindPackageFile(Filename: aString; var Found: SP_FileFindRec; var Error: TSP_ErrorCode);
Var
  FilePart, DirPart, DirFragment: aString;
  CurDir, SepPos, Idx: Integer;
Begin

  // Begin by indicating that the file cannot be found.

  Found.FoundFileIndex := -1;
  Found.FoundDirIndex := -1;

  // Find a file. First, see if there's a directory specified:

  CurDir := CurrentPackage.CurDirectory;
  DirPart := Lower(SP_ExtractFileDir(Filename));
  If DirPart <> '' Then Begin

    // Find that directory.
    // Start with all dirs that have no parent (are in root)

    ERRStr := DirPart;
    If DirPart = '/' Then Begin

      // Specified the root directory, which always exists.
      CurDir := -1;
      Found.FoundDirIndex := -1;

    End Else Begin

      CurDir := -1;
      Repeat

        SepPos := Pos('/', DirPart);
        If SepPos > 0 Then Begin
          DirFragment := Copy(DirPart, 1, SepPos -1);
          DirPart := Copy(DirPart, SepPos +1, Length(DirPart));
        End Else Begin
          DirFragment := DirPart;
          DirPart := '';
        End;

        If DirFragment = '..' Then Begin

          If CurDir > -1 Then
            CurDir := CurrentPackage.Directories[CurDir].ParentDirectoryID
          Else
            Exit;

        End Else If DirFragment <> '.' Then Begin

          Idx := 0;

          While Idx < integer(CurrentPackage.DirCount) Do Begin

            If CurrentPackage.Directories[Idx].ParentDirectoryID = CurDir Then
              If CompStr(CurrentPackage.Directories[Idx].DirName, DirFragment) Then Begin
                Found.FoundDirIndex := Idx;
                CurDir := Idx;
                Break;
              End;
            Inc(Idx);

          End;

          If Idx = integer(CurrentPackage.DirCount) Then Begin

            // Not Found - Signal an error, and exit.

            Error.Code := SP_ERR_DIR_NOT_FOUND;
            Exit;

          End;

        End;

      Until DirPart = '';

    End;

    // Now CurDir points to the correct directory. If no directory path was specified then CurDir still
    // points to the current directory.

  End;

  // Now, find the file that's attached to CurDir.

  FilePart := Lower(SP_ExtractFilename(Filename));
  For Idx := 0 To CurrentPackage.FileCount -1 Do Begin

    If (CompStr(CurrentPackage.Files[Idx].Filename, FilePart)) And (CurrentPackage.Files[Idx].DirectoryID = CurDir) Then Begin
      FillMem(@Found.Filename[0], Length(FilePart), 0);
      CopyMem(@Found.Filename[0], @FilePart[1], Length(FilePart));
      Found.FoundFileIndex := Idx;
      Found.FoundDirIndex := CurDir;
      Exit;
    End;

  End;

  // On exit, the FoundFileIndex will be -1 if the file does not exist, or the index if it does.

End;

Function SP_WriteToPackageFile(Filename: aString; BuffPtr: pByte; Size: LongWord; var Error: TSP_ErrorCode): LongWord; inline;
Var
  Found: SP_FileFindRec;
  NewFile: SP_FileEntry;
  Chunk: SP_FileChunk;
  PackagePos, BytesWritten, NewChunkID: LongWord;
Begin

  ERRStr := Filename;
  Result := 0;
  If CurrentPackage.WriteProtect Then Begin
    Error.Code := SP_ERR_WRITE_PROTECT;
    Exit;
  End;

  Result := 0;

  // Write bytes from Buffer^ out to the file specified.
  // First, find the file - MUST exist:

  SP_FindPackageFile(Filename, Found, Error);

  If Found.FoundFileIndex <> -1 Then Begin

    // Now start streaming bytes into chunks.

    CopyMem(@NewFile.Filename[0], @CurrentPackage.Files[Found.FoundFileIndex].Filename[0], SizeOf(SP_FileEntry));

    // While there are bytes to be written...

    While Size > 0 Do Begin

      // Pull in the current chunk - might be in the middle of the file. Who knows?

      PackagePos := (NewFile.CurrentChunk * SizeOf(SP_FileChunk)) + SizeOf(SP_FileTable);
      Package.Seek(PackagePos, soBeginning);
      Package.Read(Chunk, SizeOf(SP_FileChunk));

      // First check - are we at the final chunk, with a seekpos >= maximum chunksize?
      // If so, we need a new chunk.

      If (NewFile.CurrentChunk = integer(NewFile.LastChunk)) And (NewFile.SEEKPos >= SP_ChunkSize) Then Begin

        NewFile.CurrentChunk := SP_GetNextChunk;
        NewFile.SEEKPos := 0;
        Chunk.NextChunk := NewFile.CurrentChunk;
        Package.Seek(PackagePos, soBeginning);
        Package.Write(Chunk, SizeOf(SP_FileChunk));
        PackagePos := (NewFile.CurrentChunk * SizeOf(SP_FileChunk)) + SizeOf(SP_FileTable);
        Package.Seek(PackagePos, soBeginning);
        Package.Read(Chunk, SizeOf(SP_FileChunk));
        Inc(NewFile.NumChunks);
        NewFile.LastChunk := NewFile.CurrentChunk;

      End;

      // And write at most a chunk's worth of data.

      BytesWritten := Min(SP_ChunkSize - NewFile.SEEKPos, Size);
      CopyMem(@Chunk.ChunkData[NewFile.SEEKPos], BuffPtr, BytesWritten);
      Inc(BuffPtr, BytesWritten);
      Chunk.Allocated := True;
      SP_ChunkMap[NewFile.CurrentChunk] := True;

      // Are we writing to the last chunk?
      // If so, we might be extending the file.

      If NewFile.LastChunk = NewFile.CurrentChunk Then
        If NewFile.SEEKPos >= Chunk.ChunkSize Then
          NewFile.FileSize := (NewFile.NumChunks * SP_ChunkSize) + NewFile.SEEKPos + BytesWritten;

      Inc(Result, BytesWritten);
      Dec(Size, BytesWritten);
      If Size > 0 Then Begin

        // We didn't write out all the data, so it must be because we ran out of chunk space.
        // Get a new ChunkID

        NewChunkID := SP_GetNextChunk;

        // If we're at the last chunk in the file, then update the last chunk pointer
        // to this new chunk.

        If NewFile.LastChunk = NewFile.CurrentChunk Then Begin
          Inc(NewFile.NumChunks);
          NewFile.LastChunk := NewChunkID;
        End;

        Chunk.ChunkSize := SP_ChunkSize;
        NewFile.CurrentChunk := NewChunkID;
        Chunk.NextChunk := NewFile.CurrentChunk;
        NewFile.SEEKPos := 0;

      End Else Begin

        Inc(NewFile.SEEKPos, BytesWritten);
        If NewFile.LastChunk = NewFile.CurrentChunk Then
          If Chunk.ChunkSize < NewFile.SEEKPos Then
            Chunk.ChunkSize := NewFile.SEEKPos;

      End;

      // Write out the completed chunk.

      Package.Seek(PackagePos, soBeginning);
      Package.Write(Chunk, SizeOf(SP_FileChunk));

    End;

    // Finally write out the modified File entry

    NewFile.FileDate := DateTimeToFileDate(Now);
    CopyMem(@CurrentPackage.Files[Found.FoundFileIndex].Filename[0], @NewFile.Filename[0], SizeOf(SP_FileEntry));

  End Else

    Error.Code := SP_ERR_FILE_MISSING;

End;

Function SP_ReadLnFromPackageFile(Filename: aString; var Error: TSP_ErrorCode): aString;
Begin

End;

Function SP_ReadFromPackageFile(Filename: aString; BuffPtr: pByte; Size: LongWord; var Error: TSP_ErrorCode): LongWord;
Var
  Found: SP_FileFindRec;
  NewFile: SP_FileEntry;
  Chunk: SP_FileChunk;
  PackagePos, BytesRead: LongWord;
Begin

  ERRStr := Filename;
  Result := 0;

  // Write bytes from Buffer^ out to the file specified.
  // First, find the file - MUST exist:

  SP_FindPackageFile(Filename, Found, Error);

  If Found.FoundFileIndex <> -1 Then Begin

    // Now start streaming bytes from chunks into the buffer.

    CopyMem(@NewFile.Filename[0], @CurrentPackage.Files[Found.FoundFileIndex].Filename[0], SizeOf(SP_FileEntry));

    // While there are bytes to be read...

    While Size > 0 Do Begin

      // Pull in the current chunk - might be in the middle of the file. Who knows?

      PackagePos := (NewFile.CurrentChunk * SizeOf(SP_FileChunk)) + SizeOf(SP_FileTable);
      Package.Seek(PackagePos, soBeginning);
      Package.Read(Chunk, SizeOf(SP_FileChunk));

      // And write at most a chunk's worth of data.

      BytesRead := Min(Chunk.ChunkSize - NewFile.SEEKPos, Size);
      CopyMem(BuffPtr, @Chunk.ChunkData[NewFile.SEEKPos], BytesRead);
      Inc(Result, BytesRead);
      Inc(BuffPtr, BytesRead);
      Dec(Size, BytesRead);

      // Advance the file's seek position by the bytes read

      Inc(NewFile.SEEKPos, BytesRead);

      // Have we exhausted the final chunk?

      If NewFile.CurrentChunk = integer(NewFile.LastChunk) Then Begin

        // No more data?

        If NewFile.SEEKPos >= Chunk.ChunkSize Then Begin
          CopyMem(@CurrentPackage.Files[Found.FoundFileIndex].Filename[0], @NewFile.Filename[0], SizeOf(SP_FileEntry));
          Exit;
        End;

      End Else

        // Are we at the end of the chunk?

        If NewFile.SEEKPos >= SP_ChunkSize Then Begin

          Dec(NewFile.SEEKPos, SP_ChunkSize);
          NewFile.CurrentChunk := Chunk.NextChunk;

        End;

    End;

  End Else

    Error.Code := SP_ERR_FILE_MISSING;

  CopyMem(@CurrentPackage.Files[Found.FoundFileIndex].Filename[0], @NewFile.Filename[0], SizeOf(SP_FileEntry));

End;

Function SP_SeekToPackageFile(Filename: aString; SeekPos: LongWord; var Error: TSP_ErrorCode): LongWord;
Var
  Found: SP_FileFindRec;
  NewFile: pSP_FileEntry;
  Chunk: SP_FileChunk;
  NextChunk, PackagePos, ChunkCount: Integer;
Begin

  // Finds the file and sets the CurrentChunk and SEEKPos member to match the intended seek position.

  ERRStr := Filename;
  Result := 0;
  SP_FindPackageFile(Filename, Found, Error);

  If Found.FoundFileIndex <> -1 Then Begin

    NewFile := @CurrentPackage.Files[Found.FoundFileIndex];
    NextChunk := NewFile^.FirstChunk;
    PackagePos := (NextChunk * SizeOf(SP_FileChunk)) + SizeOf(SP_FileTable);
    Package.Seek(PackagePos, soFromBeginning);
    Package.Read(Chunk, SizeOf(SP_FileChunk));

    If SeekPos > SP_ChunkSize Then Begin

      ChunkCount := 0;

      While (ChunkCount < integer(SeekPos) Div SP_ChunkSize) And (Chunk.NextChunk >= 0) Do Begin

        PackagePos := (NextChunk * SizeOf(SP_FileChunk)) + SizeOf(SP_FileTable);
        Package.Seek(PackagePos, soFromBeginning);
        Package.Read(Chunk, SizeOf(SP_FileChunk));

        NextChunk := Chunk.NextChunk;
        Inc(ChunkCount);

      End;

    End;

    NewFile^.CurrentChunk := NextChunk;
    NewFile^.SEEKPos := Min(Chunk.ChunkSize, SeekPos Mod SP_ChunkSize);

  End Else

    Error.Code := SP_ERR_FILE_MISSING;

End;

Function SP_GetSeekPosFromPackageFile(Filename: aString; var Error: TSP_ErrorCode): LongWord;
Var
  Found: SP_FileFindRec;
  NewFile: pSP_FileEntry;
  Chunk: SP_FileChunk;
  packagePos, NextChunk, ChunkCount: Integer;
Begin

  // Returns the seek position based on the current Chunk ID and the file/chunk's SEEKPos member.
  // means we have to walk through the chunks one by one until we find the current chunk though :(

  Result := 0;
  ERRStr := Filename;
  SP_FindPackageFile(Filename, Found, Error);

  If Found.FoundFileIndex <> -1 Then Begin

    NewFile := @CurrentPackage.Files[Found.FoundFileIndex];
    NextChunk := NewFile^.FirstChunk;
    ChunkCount := 0;

    While NextChunk <> NewFile^.CurrentChunk Do Begin
      PackagePos := (NextChunk * SizeOf(SP_FileChunk)) + SizeOf(SP_FileTable);
      Package.Seek(PackagePos, soFromBeginning);
      Package.Read(Chunk, SizeOf(SP_FileChunk));
      NextChunk := Chunk.NextChunk;
      Inc(ChunkCount);
    End;

    Result := NewFile^.SEEKPos + LongWord(ChunkCount * SP_ChunkSize);

  End Else

    Error.Code := SP_ERR_FILE_MISSING;

End;

Function SP_GetSizeFromPackageFile(Filename: aString; var Error: TSP_ErrorCode): LongWord;
Var
  Found: SP_FileFindRec;
  NewFile: pSP_FileEntry;
Begin

  Result := 0;
  ERRStr := Filename;
  SP_FindPackageFile(Filename, Found, Error);

  If Found.FoundFileIndex <> -1 Then Begin

    NewFile := @CurrentPackage.Files[Found.FoundFileIndex];
    Result := NewFile^.FileSize;

  End Else

    Error.Code := SP_ERR_FILE_MISSING;

End;

Function SP_PackageFileExists(Filename: aString; Var Error: TSP_ErrorCode): Boolean;
Var
  Found: SP_FileFindRec;
Begin

  SP_FindPackageFile(Filename, Found, Error);
  Result := Found.FoundFileIndex <> -1;

End;

Procedure SP_DeletePackageFile(Filename: aString; var Error: TSP_ErrorCode);
Var
  Found: SP_FileFindRec;
  NewFile: pSP_FileEntry;
  CurChunk, Idx, ChunkPos: Integer;
  NewChunk: SP_FileChunk;
Begin

  If CurrentPackage.WriteProtect Then Begin
    Error.Code := SP_ERR_WRITE_PROTECT;
    Exit;
  End;

  // Find the file.

  ERRStr := Filename;
  SP_FindPackageFile(Filename, Found, Error);

  If Found.FoundFileIndex <> -1 Then Begin

    // The file exists - erase its data and set it to zero length.

    NewFile := @CurrentPackage.Files[Found.FoundFileIndex];

    CurChunk := NewFile^.FirstChunk;
    For Idx := 0 To NewFile^.NumChunks -1 Do Begin
      ChunkPos := SizeOf(SP_FileTable) + (CurChunk * SizeOf(SP_FileChunk));
      Package.Seek(ChunkPos, soFromBeginning);
      Package.Read(NewChunk, SizeOf(SP_FileChunk));
      SP_ChunkMap[CurChunk] := False;
      NewChunk.Allocated := False;
      NewChunk.ChunkSize := 0;
      CurChunk := NewChunk.NextChunk;
      NewChunk.NextChunk := -1;
      NewChunk.PrevChunk := -1;
      Package.Seek(ChunkPos, soFromBeginning);
      Package.Write(NewChunk, SizeOf(SP_FileChunk));
    End;

    NewFile^.FileSize := 0;
    NewFile^.NumChunks := 0;
    NewFile^.CurrentChunk := NewFile.FirstChunk;
    NewFile^.SEEKPos := 0;

    If Found.FoundFileIndex < integer(CurrentPackage.FileCount) -1 Then Begin
      For Idx := Found.FoundFileIndex To CurrentPackage.FileCount -1 Do
        CopyMem(@CurrentPackage.Files[Idx].Filename[0], @CurrentPackage.Files[Idx +1].Filename[0], SizeOf(SP_FileEntry));
    End;
    Dec(CurrentPackage.FileCount);

  End Else

    Error.Code := SP_ERR_FILE_MISSING;

End;

Function SP_PackageGetName(Addr: pByte): aString;
Begin

  Result := '';
  While Addr^ > 0 Do Begin
    Result := Result + aChar(Addr^);
    Inc(Addr);
  End;

End;

Function SP_GetPackageDir: aString;
Var
  Dir: SP_DirectoryEntry;
Begin

  Result := '';

  If CurrentPackage.CurDirectory >= 0 Then Begin

    CopyMem(@Dir.DirName[0], @CurrentPackage.Directories[CurrentPackage.CurDirectory].DirName[0], SizeOf(SP_DirectoryEntry));
    Result := SP_PackageGetName(@Dir.DirName[0]);

    While Dir.ParentDirectoryID >= 0 Do Begin
      CopyMem(@Dir.DirName[0], @CurrentPackage.Directories[Dir.ParentDirectoryID].DirName[0], SizeOf(SP_DirectoryEntry));
      Result := SP_PackageGetName(@Dir.DirName[0]) + '/' + Result;
    End;

  End;

  Result := '/' + Result;

End;

Procedure SP_SetPackageDir(Directory: aString; Var Error: TSP_ErrorCode);
Var
  Idx, OldDir: Integer;
  DirPart: aString;
Begin

  ERRStr := Directory;
  If Directory <> '' Then Begin

    OldDir := CurrentPackage.CurDirectory;

    If Directory[1] = '/' Then Begin
      CurrentPackage.CurDirectory := -1;
      Directory := Copy(Directory, 2, Length(Directory));
    End;

    While Directory <> '' Do Begin

      If Pos('/', Directory) <> 0 Then Begin
        DirPart := Lower(Copy(Directory, 1, Pos('/', Directory) -1));
        Directory := Copy(Directory, Pos('/', Directory) +1, Length(Directory));
      End Else Begin
        DirPart := Lower(Directory);
        Directory := '';
      End;

      If DirPart <> '.' Then Begin

        If DirPart = '..' Then Begin

          If CurrentPackage.CurDirectory > -1 Then
            CurrentPackage.CurDirectory := CurrentPackage.Directories[CurrentPackage.CurDirectory].ParentDirectoryID
          Else Begin
            Error.Code := SP_ERR_DIR_NOT_FOUND;
            CurrentPackage.CurDirectory := OldDir;
            Exit;
          End;

        End Else Begin

          Idx := 0;
          While Idx < integer(CurrentPackage.DirCount) Do Begin
            If CurrentPackage.Directories[Idx].ParentDirectoryID = CurrentPackage.CurDirectory Then
              If CompStr(CurrentPackage.Directories[Idx].DirName, DirPart) Then Begin
                CurrentPackage.CurDirectory := Idx;
                Break;
              End;
            Inc(Idx);
          End;

          If Idx = integer(CurrentPackage.DirCount) Then Begin
            Error.Code := SP_ERR_DIR_NOT_FOUND;
            CurrentPackage.CurDirectory := OldDir;
            Exit;
          End;

        End;

      End;

    End;

  End;

End;

Procedure SP_PackageFindAll(Path: aString; var List, Sizes: TAnsiStringList; var Error: TSP_ErrorCode);
Var
  Dir, Idx, Cnt, nIdx, Idx2, sIdx, Age: Integer;
  DirPart, Size, Size2, AgeStr: aString;
Begin

  Dir := -1;

  // Returns a list of files in the specified path. First, process the path so we
  // know where to get the file list from!

  If Path <> '' Then Begin

    If Path[1] = '/' Then Begin
      Dir := -1;
      Path := Copy(Path, 2, Length(Path));
    End;

    While Path <> '' Do Begin

      If Pos('/', Path) <> 0 Then Begin
        DirPart := Lower(Copy(Path, 1, Pos('/', Path) -1));
        Path := Copy(Path, Pos('/', Path) +1, Length(Path));
      End Else Begin
        Break;
        Path := '';
      End;

      ERRStr := DirPart;
      If DirPart <> '.' Then Begin

        If DirPart = '..' Then Begin

          If Dir > -1 Then
            Dir := CurrentPackage.Directories[Dir].ParentDirectoryID
          Else Begin
            Error.Code := SP_ERR_DIR_NOT_FOUND;
            Exit;
          End;

        End Else Begin

          Idx := 0;
          While Idx < integer(CurrentPackage.DirCount) Do Begin
            If CurrentPackage.Directories[Idx].ParentDirectoryID = Dir Then
              If CompStr(CurrentPackage.Directories[Idx].DirName, DirPart) Then Begin
                Dir := Idx;
                Break;
              End;
            Inc(Idx);
          End;

          If Idx = integer(CurrentPackage.DirCount) Then Begin
            Error.Code := SP_ERR_DIR_NOT_FOUND;
            Exit;
          End;

        End;

      End;

    End;

  End Else

    Dir := CurrentPackage.CurDirectory;

  // Now Dir points to the correct directory, anything else in the path is a filespec, probably a "*".
  // now just fill the lists with info.

  If CurrentPackage.DirCount > 0 Then
    For Idx := 0 To CurrentPackage.DirCount -1 Do Begin

      If CurrentPackage.Directories[Idx].ParentDirectoryID = Dir then Begin

        Idx2 := List.Add(SP_PackageGetName(@CurrentPackage.Directories[Idx].DirName[0]));
        List.Objects[Idx2] := Pointer(1);

      End;

    End;

  If CurrentPackage.FileCount > 0 Then
    For Idx := 0 To CurrentPackage.FileCount -1 Do Begin

      If CurrentPackage.Files[Idx].DirectoryID = Dir then Begin

        Idx2 := List.Add(SP_PackageGetName(@CurrentPackage.Files[Idx].Filename[0]));
        List.Objects[Idx2] := Pointer(0);

        Size := aString(IntToStr(CurrentPackage.Files[Idx].FileSize));
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

        Age := CurrentPackage.Files[Idx].FileDate;
        If Age > -1 Then Begin
          AgeStr := aString(DateToStr(FileDateToDateTime(Age)));
          If Length(AgeStr) < 10 Then
            If AgeStr[2] = '/' Then
              AgeStr := '0' + AgeStr
            Else
              AgeStr := Copy(AgeStr, 1, 3) + '0' + Copy(AgeStr, 4, Length(AgeStr));
          If Length(AgeStr) < 10 Then
            AgeStr := Copy(AgeStr, 1, 3) + '0' + Copy(AgeStr, 4, Length(AgeStr));
          AgeStr := Copy(AgeStr, 4, 2) + '/' + Copy(AgeStr, 1, 2) + '/' + Copy(AgeStr, 7, 4);
          sIdx := Sizes.Add(Size2 + ' ' + aString(StringOfChar(' ', 10 - Length(AgeStr))) + AgeStr);
        End Else
          sIdx := Sizes.Add(Size2 + '            ');
        Sizes.Objects[sIdx] := Pointer(StringToLong(Size));

      End;

    End;

End;

Function SP_PackageDirExists(Path: aString; Var Error: TSP_ErrorCode): Boolean;
Var
  Dir, Idx: Integer;
  DirPart: aString;
Begin

  Result := False;
  Dir := -1;

  If Path <> '' Then Begin

    If Path[Length(Path)] <> '/' Then
      Path := Path + '/';

    If Path[1] = '/' Then Begin
      Dir := -1;
      Path := Copy(Path, 2, Length(Path));
    End;

    While Path <> '' Do Begin

      If Pos('/', Path) <> 0 Then Begin
        DirPart := Lower(Copy(Path, 1, Pos('/', Path) -1));
        Path := Copy(Path, Pos('/', Path) +1, Length(Path));
      End;

      If DirPart <> '.' Then Begin

        If DirPart = '..' Then Begin

          If Dir > -1 Then
            Dir := CurrentPackage.Directories[Dir].ParentDirectoryID
          Else
            Exit;

        End Else Begin

          Idx := 0;
          While Idx < integer(CurrentPackage.DirCount) Do Begin
            If CurrentPackage.Directories[Idx].ParentDirectoryID = Dir Then
              If CompStr(CurrentPackage.Directories[Idx].DirName, DirPart) Then Begin
                Dir := Idx;
                Break;
              End;
            Inc(Idx);
          End;

          If Idx = Integer(CurrentPackage.DirCount) Then
            Exit;

        End;

      End;

    End;

    Result := True;

  End;

End;

Procedure SP_TestPackageFile(var Filename: aString; var Error: TSP_ErrorCode);
Begin

  // Finds a file in the package if it's open, and extracts it to the TEMPDIR folder,
  // then modifies the filename so the calling proc opens the newly unpacked file.

  If PackageIsOpen And (Pos(':', Filename) = 0) Then Begin

    If SP_FileExists(Filename) Then
      SP_PackageUnpackFile(Filename, Error);

  End Else
    Filename := SP_ConvertFilenameToHost(Filename, Error);

End;

Procedure SP_PackageUnpackFile(var Src: aString; var Error: TSP_ErrorCode);
Var
  Dst, BuffSize, BytesRead: Integer;
  Buffer: Array of Byte;
Begin

  // Unpacks a file from the current package to the destination supplied in the host filesystem.
  // Check for SYS: and TEMP: and make them if they don't exist.

  SP_Decode_Assignment('SYS:', Error);
  If Error.Code <> SP_ERR_OK Then
    SP_SetAssign('SYS:', '/', Error);

  If Not SP_DirectoryExists('SYS:temp') Then
    SP_MakeDir('SYS:temp', Error);

  SP_Decode_Assignment('TEMP:', Error);
  If Error.Code <> SP_ERR_OK Then
    SP_SetAssign('TEMP:', 'SYS:temp/', Error);

  PackageIsOpen := False;
  Dst := SP_FileOpen('TEMP:'+SP_ExtractFilename(Src), True, Error);
  PackageIsOpen := True;
  BuffSize := 1024*1024-1;
  SetLength(Buffer, BuffSize);

  SP_SeekToPackageFile(Src, 0, Error);
  Repeat
    BytesRead := SP_ReadFromPackageFile(Src, @Buffer[0], BuffSize, Error);
    If BytesRead > 0 Then
      SP_FileWrite(Dst, @Buffer[0], BytesRead, Error);
  Until BytesRead = 0;

  SP_FileClose(Dst, Error);

  Src := SP_ConvertFilenameToHost('TEMP:'+SP_ExtractFilename(Src), Error);

End;

Procedure SP_DeleteTempFiles;
Var
  List, Sizes: TAnsiStringList;
  Idx: Integer;
  Error: TSP_ErrorCode;
Begin

  List := TAnsiStringList.Create;
  Sizes := TAnsiStringList.Create;
  SP_FindAll('TEMP:*', List, Sizes);

  For Idx := 0 To List.Count -1 Do Begin
    If NativeUInt(List.Objects[Idx]) = 0 Then
      SP_DeleteFile('TEMP:'+aString(List[Idx]), Error);
  End;

  List.Free;
  Sizes.Free;

End;

Function SP_PackageFindDir(Path: aString; var Error: TSP_ErrorCode): Integer;
Var
  Dir, Idx: Integer;
  DirPart: aString;
Begin

  Result := -1;
  Dir := -1;

  If Path[1] = '/' Then Begin
    Dir := -1;
    Path := Copy(Path, 2, Length(Path));
  End;

  While Path <> '' Do Begin

    If Pos('/', Path) <> 0 Then Begin
      DirPart := Lower(Copy(Path, 1, Pos('/', Path) -1));
      Path := Copy(Path, Pos('/', Path) +1, Length(Path));
    End Else Begin
      Break;
      Path := '';
    End;

    ERRStr := DirPart;
    If DirPart <> '.' Then Begin

      If DirPart = '..' Then Begin

        If Dir > -1 Then
          Dir := CurrentPackage.Directories[Dir].ParentDirectoryID
        Else Begin
          Error.Code := SP_ERR_DIR_NOT_FOUND;
          Exit;
        End;

      End Else Begin

        Idx := 0;
        While Idx < Integer(CurrentPackage.DirCount) Do Begin
          If CurrentPackage.Directories[Idx].ParentDirectoryID = Dir Then
            If CompStr(CurrentPackage.Directories[Idx].DirName, DirPart) Then Begin
              Dir := Idx;
              Break;
            End;
          Inc(Idx);
        End;

        If Longword(Idx) = CurrentPackage.DirCount Then Begin
          Error.Code := SP_ERR_DIR_NOT_FOUND;
          Exit;
        End;

      End;

    End;

  End;

  Result := Dir;

End;

Procedure SP_PackageCreateDir(DirString: aString; var Error: TSP_ErrorCode);
Var
  Path, NewDir: aString;
  DirIndex: Integer;
  CreatedDir: pSP_DirectoryEntry;
Begin

  If CurrentPackage.WriteProtect Then Begin
    Error.Code := SP_ERR_WRITE_PROTECT;
    Exit;
  End;

  // Create a directory. Check if the parent exists.

  Path := SP_ExtractFileDir(DirString);
  NewDir := SP_ExtractFileName(DirString);
  ERRStr := DirString;

  If Path <> '' Then
    DirIndex := SP_PackageFindDir(Path, Error)
  Else
    DirIndex := CurrentPackage.CurDirectory;

  If Error.Code = SP_ERR_OK Then Begin

    If NewDir <> '' Then Begin
      CreatedDir := @CurrentPackage.Directories[CurrentPackage.DirCount];
      FillMem(@CreatedDir^.DirName[0], SizeOf(SP_FileName), 0);
      CopyMem(@CreatedDir^.DirName[0], @NewDir[1], Length(NewDir));
      CreatedDir^.ParentDirectoryID := DirIndex;
      Inc(CurrentPackage.DirCount);
    End Else
      Error.Code := SP_ERR_DIR_CREATE_FAILED;

  End;

End;

Procedure SP_PackageDeleteDir(DirString: aString; var Error: TSP_ErrorCode);
Var
  DirIdx, Idx: Integer;
Begin

  // Delete a directory.
  // Run through the files list - any files which have a directoryID > this dir
  // must be decremented by one.

  If CurrentPackage.WriteProtect Then Begin
    Error.Code := SP_ERR_WRITE_PROTECT;
    Exit;
  End;

  DirIdx := SP_PackageFindDir(DirString, Error);

  If (Error.Code = SP_ERR_OK) And (DirIdx > -1) Then Begin

    For Idx := 0 To CurrentPackage.FileCount -1 Do
      If CurrentPackage.Files[Idx].DirectoryID > DirIdx Then
        Dec(CurrentPackage.Files[Idx].DirectoryID);

    For Idx := DirIdx To CurrentPackage.DirCount -1 Do
      CurrentPackage.Directories[Idx] := CurrentPackage.Directories[Idx +1];

    Dec(CurrentPackage.DirCount);

  End;

End;

Procedure SP_PackageFileRename(Src, Dst: aString; var Error: TSP_ErrorCode);
Var
  SrcIdx, DstIdx: Integer;
  SrcEntry: SP_FileFindRec;
  NewName, NewDir: aString;
  Dir: pSP_DirectoryEntry;
  SrcFile: pSP_FileEntry;
Begin

  SrcIdx := -1;

  // Filenames must be package format (no assigns), package must be open.
  // First, is the source a file or directory?

  SP_FindPackageFile(Src, SrcEntry, Error);

  If SrcEntry.FoundFileIndex = -1 Then Begin

    Error.Code := SP_ERR_OK;
    SrcIdx := SP_PackageFindDir(Src, Error);
    If Error.Code = SP_ERR_OK Then Begin

      // Rename a directory

      NewName := SP_ExtractFilename(Dst);
      NewDir := SP_ExtractFileDir(Dst);

      Dir := @CurrentPackage.Directories[SrcIdx];
      FillMem(@Dir^.DirName[0], SizeOf(SP_FileName), 0);
      CopyMem(@Dir^.DirName[0], @NewName[1], Length(NewName));

      // Set the directory if necessary.

      If NewDir <> '' Then Begin

        DstIdx := SP_PackageFindDir(NewDir, Error);

        If Error.Code = SP_ERR_OK Then

          Dir^.ParentDirectoryID := DstIdx

        Else

          Exit;

      End;

    End Else

      Exit;

  End Else Begin

    // Rename a file!

    SrcFile := @CurrentPackage.Files[SrcIdx];
    NewName := SP_ExtractFilename(Dst);
    NewDir := SP_ExtractFileDir(Dst);

    FillMem(@SrcFile^.Filename[0], SizeOf(SP_FileName), 0);
    CopyMem(@SrcFile^.FileName[0], @NewName[1], Length(NewName));

      // Set the directory if necessary.

    If NewDir <> '' Then Begin

      DstIdx := SP_PackageFindDir(NewDir, Error);

      If Error.Code = SP_ERR_OK Then

        SrcFile^.DirectoryID := DstIdx

      Else

        Exit;

    End;

  End;

End;

Procedure SP_PackageAddFile(Filename: aString; var Error: TSP_ErrorCode);
Var
  SrcFile, DstFile, BytesRead, BuffSize: Integer;
  Buffer: Array of Byte;
  HostFilename: aString;
Begin

  ERRStr := Filename;
  BuffSize := 1024*1024-1;
  SetLength(Buffer, BuffSize);

  If PackageIsOpen Then Begin

    PackageIsOpen := False;
    HostFilename := SP_ConvertFilenameToHost(Filename, Error);

    If SP_FileExists(HostFilename) Then Begin

      SrcFile := SP_FileOpen(HostFilename, False, Error);
      SP_FileSeek(SrcFile, 0, Error);

      PackageIsOpen := True;
      Filename := SP_ExtractFilename(Filename);
      If Not SP_FileExists(Filename) Then begin

        DstFile := SP_FileOpen(Filename, True, Error);

        Repeat

          BytesRead := SP_FileRead(SrcFile, @Buffer[0], BuffSize, Error);
          If BytesRead > 0 Then
            SP_FileWrite(DstFile, @Buffer[0], BytesRead, Error);

        Until BytesRead = 0;

        SP_FileClose(DstFile, Error);

      End Else

        Error.Code := SP_ERR_FILE_ALREADY_EXISTS;

      SP_FileClose(SrcFile, Error);

    End Else

      Error.Code := SP_ERR_FILE_MISSING;

    PackageIsOpen := True;

  End Else

    Error.Code := SP_ERR_PACKAGE_NOT_OPEN;

End;

Procedure SP_ProtectPackage;
Begin

  CurrentPackage.WriteProtect := True;

End;

Procedure SP_UnProtectPackage;
Begin

  CurrentPackage.WriteProtect := False;

End;

Procedure SP_CleanPackage;
Var
  Idx, Idx2, chStart, chEnd, chModify, Dest: Integer;
  NewChunk: SP_FileChunk;
Begin

  // Runs through the package and removes unused chunks.

  Idx := 0;

  While Idx < Length(SP_ChunkMap) Do Begin

    If Not SP_ChunkMap[Idx] Then Begin

      // Found an unused chunk. Run through and find how many chunks adjacent
      // to this one are also unused.

      Idx2 := Idx +1;
      chStart := Idx;

      While Not SP_ChunkMap[Idx2] Do Inc(Idx2);

      chModify := Idx2 - chStart;
      chEnd := Idx2 -1;

      // Now move all the chunks from chEnd back to chStart. As we do so, check -
      // do any of the chunks reference a chunk greater than chEnd? If so, we need to
      // decrement their reference accordingly.

      Idx2 := chEnd +1;
      Dest := chStart;

      While Idx2 <= Length(SP_ChunkMap) Do Begin
        Package.Seek(SizeOf(SP_FileTable) + (Idx2 * SizeOf(SP_FileChunk)), soFromBeginning);
        Package.Read(NewChunk, SizeOf(SP_FileChunk));
        If NewChunk.Allocated Then Begin
          If NewChunk.PrevChunk > chEnd Then Dec(NewChunk.PrevChunk, chModify);
          If NewChunk.NextChunk > chEnd Then Dec(NewChunk.NextChunk, chModify);
        End;
        Package.Seek(SizeOf(SP_FileTable) + (Dest * SizeOf(SP_FileChunk)), soFromBeginning);
        Package.Write(NewChunk, SizeOf(SP_FileChunk));
        Inc(Idx2);
        Inc(Dest);
      End;

      // Update the chunkmap.

      For Idx2 := Dest To Length(SP_ChunkMap) Do SP_ChunkMap[Idx2] := True;
      SetLength(SP_ChunkMap, Length(SP_ChunkMap) - chModify);

      // And update the package file's info record.

      For Idx2 := 0 To CurrentPackage.FileCount -1 Do Begin
        If CurrentPackage.Files[Idx2].LastChunk > chEnd Then Dec(CurrentPackage.Files[Idx2].LastChunk, chModify);
        If CurrentPackage.Files[Idx2].FirstChunk > chEnd Then Dec(CurrentPackage.Files[Idx2].FirstChunk, chModify);
        If CurrentPackage.Files[Idx2].CurrentChunk > chEnd Then Dec(CurrentPackage.Files[Idx2].CurrentChunk, chModify);
      End;

    End;

    Inc(Idx);

  End;

  // Now the length of the chunkmap tells us how many chunks are allocated, so we can truncate the
  // package file accordingly, which will be done on file close.

End;

end.