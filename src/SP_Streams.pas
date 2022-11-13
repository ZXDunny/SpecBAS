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

unit SP_Streams;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}

interface

Uses SysUtils, SP_SysVars, SP_BankManager, SP_BankFiling, SP_FileIO, SP_Errors, Math, SP_Util;

Type

  SP_Stream = Packed Record
    ID, BankID, FileID, Position: Integer;
    Filename: aString;
    PackageStream: Boolean;
  End;
  pSP_Stream = ^SP_Stream;

  Function SP_NewStream(BankID: Integer; Filename: aString; Var Error: TSP_ErrorCode): Integer;
  Function SP_FindStreamID(StreamID: Integer; Var Error: TSP_ErrorCode): Integer;
  Function SP_StreamRead(StreamID: Integer; Buffer: Pointer; Count: Integer; Var Error: TSP_ErrorCode): Integer;
  Function SP_StreamReadLine(StreamID: Integer; Var Error: TSP_ErrorCode): aString;
  Function SP_StreamWrite(StreamID: Integer; Buffer: Pointer; Count: Integer; Var Error: TSP_ErrorCode): Integer;
  Function SP_StreamSeek(StreamID: Integer; Position: Integer; Var Error: TSP_ErrorCode): Integer;
  Function SP_StreamClose(StreamID: Integer; Var Error: TSP_ErrorCode): Integer;
  Function SP_DeleteAllStreams(Var Error: TSP_ErrorCode): Integer;
  Function SP_StreamPos(StreamID: Integer; Var Error: TSP_ErrorCode): Integer;
  Function SP_StreamLen(StreamID: Integer; Var Error: TSP_ErrorCode): Integer;

Var

  SP_StreamList: Array of pSP_Stream;

implementation

Uses SP_Graphics;

Function SP_NewStream(BankID: Integer; Filename: aString; Var Error: TSP_ErrorCode): Integer;
Var
  NewID, Idx, fID: Integer;
  Done, Found: Boolean;
  Stream: pSP_Stream;
Begin

  NewID := 0;
  Result := -1;
  Done := Length(SP_StreamList) = 0;
  While Not Done Do Begin
    Found := False;
    For Idx := 0 To Length(SP_StreamList) -1 Do Begin
      If SP_StreamList[Idx]^.ID = NewID Then Begin
        Inc(NewID);
        Found := True;
        Break;
      End;
    End;
    If Not Found Then
      Done := True;
  End;

  Stream := New(pSP_Stream);
  Stream^.PackageStream := False;
  SetLength(SP_StreamList, Length(SP_StreamList) +1);
  SP_StreamList[Length(SP_StreamList) -1] := Stream;

  // Set the Stream info

  Stream^.ID := NewID;
  If BankID > -1 Then Begin
    Stream^.BankID := BankID;
    Stream^.FileID := -1;
  End Else Begin
    fID := SP_FileOpen(Filename, True, Error);
    If fID > -1 Then Begin
      Stream^.Filename := Filename;
      Stream^.FileID := fID;
      Stream^.BankID := -1;
    End Else Begin
      ERRStr := Filename;
      Error.Code := SP_ERR_SAVE_OPEN_ERROR;
      Exit;
    End;
  End;

  Stream^.Position := 0;

  // And return the ID.

  Result := NewID;
  Inc(NUMSTREAMS);

End;

Function  SP_StreamPos(StreamID: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  StreamIdx: Integer;
  Stream: pSP_Stream;
Begin

  StreamIdx := SP_FindStreamID(StreamID, Error);
  If StreamIdx > -1 Then Begin
    Stream := SP_StreamList[StreamIdx];
    Result := Stream^.Position;
  End Else
    Result := -1;

End;

Function  SP_StreamLen(StreamID: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  StreamIdx: Integer;
  Stream: pSP_Stream;
  Bank: pSP_Bank;
Begin

  StreamIdx := SP_FindStreamID(StreamID, Error);
  If StreamIdx > -1 Then Begin
    Stream := SP_StreamList[StreamIdx];
    If Stream^.BankID > -1 Then Begin
      Bank := SP_BankList[SP_FindBankID(Stream^.BankID)];
      Result := Length(Bank^.Memory);
    End Else
      Result := SP_FileSize(Stream^.FileID, Error);
  End Else
    Result := -1;

End;

Function  SP_FindStreamID(StreamID: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Idx: Integer;
Begin

  Result := SP_ERR_STREAM_ID_NOT_FOUND;
  Idx := 0;
  While Idx < Length(SP_StreamList) Do Begin
    If SP_StreamList[Idx]^.ID = StreamID Then Begin
      Result := Idx;
      Exit;
    End;
    Inc(Idx);
  End;

End;

Function  SP_StreamRead(StreamID: Integer; Buffer: Pointer; Count: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  StreamIdx, Idx: Integer;
  Stream: pSP_Stream;
  Bank: pSP_Bank;
Begin

  Result := 0;
  StreamIdx := SP_FindStreamID(StreamID, Error);
  If StreamIdx > -1 Then Begin
    Stream := SP_StreamList[StreamIdx];
    If Stream^.BankID > -1 Then Begin
      Bank := SP_BankList[SP_FindBankID(Stream^.BankID)];
      If Stream^.Position < Length(Bank^.Memory) Then Begin
        If Stream^.Position + Count -1 >= Length(Bank^.Memory) Then
          Count := Length(Bank^.Memory) - Stream^.Position -1;
        If Count > 0 Then
          For Idx := Stream^.Position To Stream^.Position + Count -1 Do Begin
            pByte(Buffer)^ := Bank^.Memory[Idx];
            Inc(pByte(Buffer));
          End;
        Inc(Stream^.Position, Count);
        Result := Count;
      End Else
        Result := 0;
    End Else Begin
      Result := SP_FileRead(Stream^.FileID, Buffer, Count, Error);
      Stream^.Position := SP_FilePosition(Stream^.FileID, Error);
    End;
  End;

End;

Function SP_StreamReadLine(StreamID: Integer; Var Error: TSP_ErrorCode): aString;
Var
  StreamIdx, Idx: Integer;
  Buffer: Array of Byte;
  Stream: pSP_Stream;
  Bank: pSP_Bank;
  Ptr: pByte;
Begin

  SetLength(Buffer, 1024);
  StreamIdx := SP_FindStreamID(StreamID, Error);
  If StreamIdx > -1 Then Begin
    Stream := SP_StreamList[StreamIdx];
    If Stream^.BankID > -1 Then Begin
      Bank := SP_BankList[SP_FindBankID(Stream^.BankID)];
      If Stream^.Position < Length(Bank^.Memory) Then Begin
        Idx := 0;
        ptr := @Buffer[0];
        While (Ptr^ <> 13) and (Idx < Length(Bank^.Memory)) Do Begin
          Ptr^ := Bank^.Memory[Idx];
          Inc(Ptr);
          Inc(Idx);
          if Idx >= Length(Buffer) then
            SetLength(Buffer, Length(Buffer) + 1024);
        End;
        if Ptr^ = 13 Then Begin Inc(Ptr); Inc(Idx); End;
        if Ptr^ = 10 Then Inc(Idx);
        Inc(Stream^.Position, Idx);
        SetLength(Buffer, Idx);
        SetLength(Result, Idx);
        CopyMem(@Result[1], @Buffer[0], Idx);
      End Else
        Result := '';
    End Else Begin
      Result := SP_FileReadLn(Stream^.FileID, Error);
      Stream^.Position := SP_FilePosition(Stream^.FileID, Error);
    End;
  End;

End;

Function  SP_StreamWrite(StreamID: Integer; Buffer: Pointer; Count: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  StreamIdx, Idx: Integer;
  Stream: pSP_Stream;
  Bank: pSP_Bank;
Begin

  Result := 0;
  StreamIdx := SP_FindStreamID(StreamID, Error);
  If StreamIdx > -1 Then Begin
    Stream := SP_StreamList[StreamIdx];
    If Stream^.BankID > -1 Then Begin
      Bank := SP_BankList[SP_FindBankID(Stream^.BankID)];
      If Stream^.Position + Count -1 >= Length(Bank^.Memory) Then
        SetLength(Bank^.Memory, Stream^.Position + Count -1);
      For Idx := 1 to Count Do Begin
        Bank^.Memory[Stream^.Position] := pByte(Buffer)^;
        Inc(pByte(Buffer));
        Inc(Stream^.Position);
      End;
      If Stream^.BankID = SCREENBANK Then
          SP_InvalidateWholeDisplay;
    End Else Begin
      SP_FileWrite(Stream^.FileID, Buffer, Count, Error);
      Stream^.Position := SP_FilePosition(Stream^.FileID, Error);
    End;
  End;

End;

Function SP_StreamSeek(StreamID: Integer; Position: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  StreamIdx: Integer;
  Stream: pSP_Stream;
  Bank: pSP_Bank;
Begin

  Result := 0;
  StreamIdx := SP_FindStreamID(StreamID, Error);
  If StreamIdx > -1 Then Begin
    Stream := SP_StreamList[StreamIdx];
    If Stream^.BankID > -1 Then Begin
      Bank := SP_BankList[SP_FindBankID(Stream^.BankID)];
      Stream^.Position := Max(0, Min(Position, Length(Bank^.Memory)));
    End Else Begin
      SP_FileSeek(Stream^.FileID, Position, Error);
      Stream^.Position := SP_FilePosition(Stream^.FileID, Error);
    End;
  End;

End;

Function SP_StreamClose(StreamID: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  StreamIdx, Idx: Integer;
  Stream: pSP_Stream;
Begin

  Result := 0;
  StreamIdx := SP_FindStreamID(StreamID, Error);
  If StreamIdx > -1 Then Begin
    Stream := SP_StreamList[StreamIdx];
    If Assigned(Stream) Then Begin
      If Stream^.FileID > -1 Then
        SP_FileClose(Stream^.FileID, Error);
      For Idx := StreamIdx To Length(SP_StreamList) -2 Do
        SP_StreamList[Idx] := SP_StreamList[Idx +1];
      Dispose(Stream);
    End;
    SetLength(SP_StreamList, Length(SP_StreamList) -1);
    Dec(NUMSTREAMS);
  End Else
    Result := -1;

End;

Function SP_DeleteAllStreams(Var Error: TSP_ErrorCode): Integer;
Begin

  Result := 0;
  While Length(SP_StreamList) > 0 Do
    SP_StreamClose(SP_StreamList[0]^.ID, Error);

End;

end.
