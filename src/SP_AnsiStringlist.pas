unit SP_AnsiStringlist;

interface

Uses Types, Classes, SyncObjs;

Type

  TStringlistChangeProc = Procedure(Index, Operation: Integer); // Operation = 0 - changed, 1 removed, 2 added

  TLineFlags = Packed Record
    State: Integer;
    ReturnType: Integer;
    Indent: Integer;
    GutterSize: Integer;
    Break, NeedWrap, PoI: Boolean;
    Line, Statement: Integer;
  End;
  pLineFlags = ^TLineFlags;

  TUndoEntry = Packed Record
    opType: Integer;
    GroupIndex: Integer;
    CLine, CPos, SLine, SPos: Integer;
    Operation: AnsiString;
    LineIndex: Integer;
    Flags: TLineFlags;
    Obj: TObject;
  End;

  TAnsiStringlist = Class
  Private
    fUndoLock: TCriticalSection;
    fStrings: Array of AnsiString;
    fFlags: Array of TLineFlags;
    fObjects: Array of TObject;
    fOnChange: TStringListChangeProc;
    fUndoList, fRedoList: Array of TUndoEntry;
    fUndoInProgress, fRedoInProgress: Boolean;
    fCurGroupIndex, fCurRedoGroupIndex: Integer;
    fBufferSize, fRedoBufferSize: Integer;
    fBufferPtr, fRedoBufferPtr: Integer;
    fCount: Integer;
  Public
    Delimiter: AnsiChar;
    StrictDelimiter: Boolean;
    FPCLine, fFPCPos, FPSelLine, FPSelPos: Integer;
    Procedure Clear;
    Function  Add(s: AnsiString): Integer;
    Procedure Delete(Index: Integer);
    Procedure Insert(Index: Integer; s: AnsiString);
    Procedure SetObject(Index: Integer; o: TObject);
    Function  GetObject(Index: Integer): TObject;
    Procedure SetString(Index: Integer; s: AnsiString);
    Function  GetString(Index: Integer): AnsiString;
    Procedure SetDelimitedText(s: AnsiString);
    Function  GetDelimitedText: AnsiString;
    Procedure SetText(s: AnsiString);
    Function  GetText: AnsiString;
    Procedure Sort;
    Function  GetFlags(Index: Integer): pLineFlags;
    Procedure SetFlags(Index: Integer; FlagItem: pLineFlags);
    Procedure ResetUndoBufferPtrs;
    Function  GetCanUndo: Boolean;
    Procedure NewUndoEntry;
    Procedure CommenceUndo;
    Procedure AddUndoItem(nopType, Index: Integer);
    Procedure CompleteUndo;
    Function  PerformUndo: AnsiString;
    Function  GetCanRedo: Boolean;
    Procedure NewRedoEntry;
    Procedure CommenceRedo;
    Procedure AddRedoItem(nopType, Index: Integer);
    Procedure CompleteRedo;
    Function  PerformRedo: AnsiString;
    Procedure AddStrings(s: TAnsiStringlist);
    Procedure SetFPCPos(i: Integer);
    Function  IndexOf(s: AnsiString): Integer;
    Procedure SetCapacity(v: Integer);
    Procedure LoadFromHost(Filename: String);
    Procedure LoadFromFile(Filename: AnsiString);
    Procedure SaveToFile(Filename: AnsiString);
    Procedure Resize(NewSize: Integer);
    Property  Strings[Index: Integer]: AnsiString read GetString write SetString; default;
    Property  Flags[Index: Integer]: pLineFlags read GetFlags write SetFlags;
    Property  Objects[Index: Integer]: TObject read GetObject write SetObject;
    Property  Text: AnsiString read GetText write SetText;
    Property  DelimitedText: AnsiString read GetDelimitedText write SetDelimitedText;
    Property  OnChange: TStringlistChangeProc read fOnChange write fOnChange;
    Property  UndoInProgress: Boolean read fUndoInProgress;
    Property  RedoInProgress: Boolean read fRedoInProgress;
    Property  FPCPos: Integer read fFPCPos write SetFPCPos;
    Property  CanUndo: Boolean read GetCanUndo;
    Property  CanRedo: Boolean read GetCanRedo;
    Property  Count: Integer read fCount;
    Constructor Create;
    Destructor Destroy; override;
  end;

Const

  opNone            = 0;
  opChange          = 1;
  opAdd             = 2;
  opDelete          = 3;
  opInsert          = 4;
  opAll             = 5;
  opFlags           = 6;

implementation

Uses SysUtils, SP_Util, SP_FileIO, SP_Errors;

{ TAnsiStringList }

Constructor TAnsiStringlist.Create;
Begin
  fUndoLock := TCriticalSection.Create;
  fBufferSize := 1000;
  fRedoBufferSize := 1000;
  fCount := 0;
  Clear;
End;

Destructor TAnsiStringlist.Destroy;
Begin
  OnChange := nil;
  Clear;
  fUndoLock.Free;
  Inherited;
End;

Procedure TAnsiStringlist.Resize(NewSize: Integer);
Var
  l: Integer;
begin

  l := Length(fStrings);
  If NewSize > l Then Begin
    SetLength(fStrings, l + fBufferSize);
    SetLength(fObjects, l + fBufferSize);
    SetLength(fFlags, l + fBufferSize);
  End;

end;

Procedure TAnsiStringlist.Clear;
Var
  i: Integer;
Begin
  For i := 0 to Count -1 Do
    If Assigned(OnChange) Then
      OnChange(i, 1);
  Resize(0);
  SetLength(fUndoList, 0);
  ResetUndoBufferPtrs;
  fCount := 0;
End;

Function TAnsiStringlist.Add(s: AnsiString): Integer;
Var
  l: Integer;
Begin
  l := Count;
  Resize(l +1);
  AddUndoItem(opAdd, l);
  fStrings[l] := s;
  fObjects[l] := nil;
  Result := l;
  If Assigned(OnChange) Then
    OnChange(l, 2);
  Inc(fCount);
End;

Procedure TAnsiStringlist.Delete(Index: Integer);
Var
  i, l: Integer;
Begin
  AddUndoItem(opDelete, Index);
  l := Count;
  If Index < l Then Begin
    For i := Index to l -2 do Begin
      fStrings[i] := fStrings[i+1];
      fObjects[i] := fObjects[i+1];
      fFlags[i] := fFlags[i+1];
    End;
    Resize(l -1);
    If Assigned(OnChange) Then
      OnChange(Index, 1);
    Dec(fCount);
  End;
End;

Procedure TAnsiStringlist.Insert(Index: Integer; s: AnsiString);
Var
  l, i: Integer;
Begin
  AddUndoItem(opInsert, Index);
  l := Count;
  If l = 0 Then
    Add(s)
  Else Begin
    Resize(l +1);
    for i := l DownTo Index +1 Do Begin
      fStrings[i] := fStrings[i -1];
      fObjects[i] := fObjects[i -1];
      fFlags[i] := fFlags[i -1];
    end;
    fStrings[Index] := s;
    fObjects[Index] := nil;
    If Assigned(OnChange) Then
      OnChange(Index, 2);
    Inc(fCount);
  End;
End;

Procedure TAnsiStringlist.SetString(Index: Integer; s: AnsiString);
Var
  os: AnsiString;
Begin
  AddUndoItem(opChange, Index);
  os := fStrings[Index];
  fStrings[Index] := s;
  If Assigned(OnChange) Then
    OnChange(Index, 0);
End;

Function  TAnsiStringlist.GetString(Index: Integer): AnsiString;
Begin
  Result := fStrings[Index];
End;

Procedure TAnsiStringlist.SetObject(Index: Integer; o: TObject);
Begin
  AddUndoItem(opChange, Index);
  fObjects[Index] := o;
End;

Function  TAnsiStringlist.GetObject(Index: Integer): TObject;
Begin
  Result := fObjects[Index];
End;

Function TAnsiStringlist.GetText: AnsiString;
Var
  i: Integer;
Begin
  Result := '';
  For i := 0 To Count -1 Do
    Result := Result + fStrings[i] + #13#10;
End;

Procedure TAnsiStringlist.SetText(s: AnsiString);
Var
  p: Integer;
Begin
  Clear;
  While s <> '' Do Begin
    p := pos(#13, s);
    If p = 0 Then
      p := Pos(#10, s);
    If p > 0 Then Begin
      Add(Copy(s, 1, p -1));
      While (Copy(s, p, 1) = #13) or (Copy(s, p, 1) = #10) Do
        Inc(p);
      s := Copy(s, p);
    End Else
      If s <> '' Then Begin
        Add(s);
        S := '';
      End;
  End;
End;

Function TAnsiStringlist.GetDelimitedText: AnsiString;
Var
  i: Integer;
  c: AnsiString;
Begin
  If Delimiter = '' Then
    c := #13#10
  else
    c := Delimiter;

  Result := '';
  For i := 0 To Count -1 Do
    Result := Result + fStrings[i] + c;
End;

Procedure TAnsiStringlist.SetDelimitedText(s: AnsiString);
Var
  p: Integer;
Begin
  Clear;
  If Delimiter = '' then
    SetText(s)
  Else
    While s <> '' Do Begin
      p := pos(Delimiter, s);
      If p > 0 Then Begin
        Add(Copy(s, 1, p -1));
        While Copy(s, p, 1) = Delimiter Do
          Inc(p);
        s := Copy(s, p);
      End Else
        If s <> '' Then Begin
          Add(s);
          s := '';
        End;
    End;
End;

Procedure TAnsiStringlist.Sort;
  procedure QuickSort(iLo, iHi: Integer) ;
  var
    Lo, Hi: Integer;
    Pivot, T: AnsiString;
    oT: TObject;
  begin
    Lo := iLo;
    Hi := iHi;
    Pivot := fStrings[(Lo + Hi) div 2];
    repeat
      while fStrings[Lo] < Pivot do Inc(Lo) ;
      while fStrings[Hi] > Pivot do Dec(Hi) ;
      if Lo <= Hi then
      begin
        T := fStrings[Lo];
        oT := fObjects[Lo];
        fStrings[Lo] := fStrings[Hi];
        fObjects[Lo] := fObjects[Hi];
        fStrings[Hi] := T;
        fObjects[Hi] := oT;
        Inc(Lo) ;
        Dec(Hi) ;
      end;
    until Lo > Hi;
    if Hi > iLo then QuickSort(iLo, Hi) ;
    if Lo < iHi then QuickSort(Lo, iHi) ;
  end;
begin
  AddUndoItem(opAll, 0);
  QuickSort(0, Count -1);
  If Assigned(OnChange) Then
    OnChange(-1, 0);
end;

Procedure TAnsiStringlist.AddStrings(s: TAnsiStringlist);
Var
  i: Integer;
begin
  For i := 0 To s.Count -1 Do
    Add(s[i]);
end;

Function  TAnsiStringlist.GetFlags(Index: Integer): pLineFlags;
Begin
  Result := @fFlags[Index];
End;

Procedure TAnsiStringlist.SetFlags(Index: Integer; FlagItem: pLineFlags);
Begin

  fUndoLock.Enter;
  If (fBufferPtr >= 0) and (fUndoList[fBufferPtr].opType = opFlags) and (fUndoList[fBufferPtr].LineIndex = Index) Then
    Dec(fBufferPtr);
  AddUndoItem(opFlags, Index);
  fFlags[Index] := FlagItem^;
  fUndoLock.Leave;

End;

Procedure TAnsiStringlist.SetFPCPos(i: Integer);
begin
  AddUndoItem(opNone, 0);
  fFPCPos := i;
end;

Procedure TAnsiStringList.ResetUndoBufferPtrs;
Begin

  fUndoLock.Enter;
  fUndoInProgress := False;
  fBufferPtr := -1;
  fRedoBufferPtr := -1;
  fUndoLock.Leave;

End;

Function TAnsiStringlist.GetCanUndo: Boolean;
Begin

  fUndoLock.Enter;
  Result := fBufferPtr >= 0;
  fUndoLock.Leave;

End;

Procedure TAnsiStringlist.CommenceUndo;
Begin

  fUndoLock.Enter;
  If fUndoInProgress Then CompleteUndo;

  Inc(fCurGroupIndex);
  fUndoInProgress := True;
  fUndoLock.Leave;

End;

Procedure TAnsiStringlist.CompleteUndo;
Begin

  fUndoLock.Enter;
  fUndoInProgress := False;
  fUndoLock.Leave;

End;

Procedure TAnsiStringlist.NewUndoEntry;
Begin

  fUndoLock.Enter;
  Inc(fBufferPtr);
  If fBufferPtr >= Length(fUndoList) Then
    SetLength(fUndoList, Length(fUndoList) + fBufferSize);
  fUndoLock.Leave;

End;

Procedure TAnsiStringList.AddUndoItem(nopType, Index: Integer);
Var
  i: Integer;
  s, t: AnsiString;
Begin

  Assert(Index >= 0);

  fUndoLock.Enter;

  If not fUndoInProgress Then Begin
    fUndoLock.Leave;
    Exit;
  End;

  NewUndoEntry;

  With fUndoList[fBufferPtr] Do Begin

    opType := nopType;
    GroupIndex := fCurGroupIndex;
    CLine := FPCLine;
    CPos := fFPCPos;
    SLine := FPSelLine;
    SPos := FPSelPos;

    Case opType of

      opNone:
        Begin
          // Dummy for cursor moves etc
        End;

      opFlags:
        Begin
          LineIndex := Index;
          CopyMem(@Flags.State, @fFlags[Index].State, SizeOf(TLineFlags));
        End;

      opChange:
        Begin
          LineIndex := Index;
          Obj := fObjects[Index];
          CopyMem(@Flags.State, @fFlags[Index].State, SizeOf(TLineFlags));
          Operation := fStrings[Index];
        End;

      opAdd:
        Begin
          If Count = 0 Then
            LineIndex := Index
          Else
            LineIndex := Count -1;
        End;

      opInsert:
        Begin
          LineIndex := Index;
        End;

      opDelete:
        Begin
          LineIndex := Index;
          Obj := fObjects[Index];
          CopyMem(@Flags.State, @fFlags[Index].State, SizeOf(TLineFlags));
          Operation := fStrings[Index];
        End;

      opAll:
        Begin
          s := LongWordToString(Count);
          SetLength(t, SizeOf(TLineFlags) + SizeOf(NativeUInt) + SizeOf(LongWord));
          For i := 0 To Count -1 Do Begin
            pLongWord(@t[1])^ := Length(fStrings[i]);
            CopyMem(@t[5], @fFlags[i].State, SizeOf(TLineFlags));
            pNativeUInt(@t[SizeOf(LongWord) + SizeOf(TLineFlags)])^ := NativeUInt(fObjects[i]);
            s := s + t + fStrings[i];
          End;
          Operation := s;
        End;

    End;

  End;

  fUndoLock.Leave;

End;

Function TAnsiStringlist.PerformUndo: AnsiString;
Var
  i, l2, j: Integer;
  CanUndo: Boolean;
  Ptr: pByte;

  Procedure DeleteLine(Index: Integer);
  Var
    i, l: Integer;
  Begin
    l := Count;
    If Index < l Then Begin
      For i := Index to l -2 do Begin
        fStrings[i] := fStrings[i+1];
        fObjects[i] := fObjects[i+1];
        fFlags[i] := fFlags[i+1];
      End;
      Resize(l -1);
      Dec(fCount);
    End;
  End;

Begin

  fUndoLock.Enter;

  Result := '';
  CanUndo := False;

  If fBufferPtr >= 0 Then Begin

    i := fUndoList[fBufferPtr].GroupIndex;

    j := fBufferPtr;
    While (j >= 0) And (fUndoList[j].GroupIndex = i) Do Begin
      If fUndoList[j].opType <> opNone Then Begin
        CanUndo := True;
        Break;
      End;
      Dec(j);
    End;

    If Not CanUndo Then Begin
      fBufferPtr := j;
      fUndoLock.Leave;
      Exit;
    End;

    CommenceRedo;

    While (fBufferPtr >= 0) And (fUndoList[fBufferPtr].GroupIndex = i) Do Begin

      With fUndoList[fBufferPtr] Do Begin

        Result := Result + LongWordToString(FPCLine) + LongWordToString(CLine);

        Case opType of

          opNone:
            Begin
              // Do nothing.
            End;

          opFlags:
            Begin
              AddRedoItem(opFlags, LineIndex);
              CopyMem(@fFlags[LineIndex].State, @Flags.State, SizeOf(TLineFlags));
              Result := Result + LongWordToString(LineIndex);
            End;

          opChange:
            Begin
              AddRedoItem(opChange, LineIndex);
              fStrings[LineIndex] := Operation;
              fObjects[LineIndex] := Obj;
              CopyMem(@fFlags[LineIndex].State, @Flags.State, SizeOf(TLineFlags));
              Result := Result + LongWordToString(LineIndex);
            End;

          opAdd, opInsert:
            Begin
              AddRedoItem(opDelete, LineIndex);
              DeleteLine(LineIndex);
            End;

          opDelete:
            Begin
              l2 := Count;
              If l2 = 0 Then Begin
                AddRedoItem(opAdd, l2);
                Resize(l2 +1);
                fStrings[l2] := Operation;
                fObjects[l2] := Obj;
                CopyMem(@fFlags[l2].State, @Flags.State, SizeOf(TLineFlags));
                Result := Result + LongWordToString(0);
              End Else Begin
                AddRedoItem(opInsert, LineIndex);
                Resize(l2 +1);
                for j := l2 DownTo LineIndex +1 Do Begin
                  fStrings[j] := fStrings[j -1];
                  fObjects[j] := fObjects[j -1];
                  fFlags[j] := fFlags[j -1];
                end;
                fStrings[LineIndex] := Operation;
                fObjects[LineIndex] := Obj;
                CopyMem(@fFlags[LineIndex].State, @Flags.State, SizeOf(TLineFlags));
                Result := Result + LongWordToString(LineIndex);
              End;
              Inc(fCount);
            End;

          opAll:
            Begin
              AddRedoItem(opAll, 0);
              l2 := pLongWord(@Operation[1])^;
              If l2 <> Count Then Begin
                Resize(l2);
              End;
              fCount := l2;
              ptr := @Operation[5];
              For i := 0 to l2 -1 do Begin
                SetLength(fStrings[i], pLongWord(Ptr)^);
                Inc(Ptr, SizeOf(LongWord));
                CopyMem(@fFlags[i].State, Ptr, SizeOf(TLineFlags));
                Inc(Ptr, SizeOf(TLineFlags));
                fObjects[i] := TObject(pNativeUInt(Ptr)^);
                Inc(Ptr, SizeOf(NativeUInt));
                CopyMem(@fStrings[i][1], Ptr, Length(fStrings[i]));
                Inc(Ptr, Length(fStrings[i]));
                Result := Result + LongWordToString(i);
              End;
            End;

        End;

        fFPCPos := CPos;
        FPCLine := CLine;
        FPSelPos := SPos;
        FPSelLine := SLine;

      End;

      Dec(fBufferPtr);

    End;

    CompleteRedo;
    If Assigned(OnChange) Then
      OnChange(-1, 0);

  End;

  fUndoLock.Leave;

End;

Function TAnsiStringlist.GetCanRedo: Boolean;
Begin

  fUndoLock.Enter;
  Result := fRedoBufferPtr >= 0;
  fUndoLock.Leave;

End;

Procedure TAnsiStringlist.NewRedoEntry;
Begin

  fUndoLock.Enter;
  Inc(fRedoBufferPtr);
  If fRedoBufferPtr >= Length(fRedoList) Then
    SetLength(fRedoList, Length(fRedoList) + fRedoBufferSize);
  fUndoLock.Leave;

End;

Procedure TAnsiStringlist.CommenceRedo;
Begin

  fUndoLock.Enter;
  If fRedoInProgress Then CompleteRedo;

  Inc(fCurRedoGroupIndex);
  fRedoInProgress := True;
  fUndoLock.Leave;

End;

Procedure TAnsiStringlist.AddRedoItem(nopType, Index: Integer);
Var
  i: Integer;
  s, t: AnsiString;
Begin

  fUndoLock.Enter;

  If not fRedoInProgress Then Begin
    fUndoLock.Leave;
    Exit;
  End;

  NewRedoEntry;

  With fRedoList[fRedoBufferPtr] Do Begin

    opType := nopType;
    GroupIndex := fCurRedoGroupIndex;

    CLine := FPCLine;
    CPos := fFPCPos;
    SLine := FPSelLine;
    SPos := FPSelPos;

    Case opType of

      opNone:
        Begin
          // Dummy for cursor moves etc
        End;

      opFlags:
        Begin
          LineIndex := Index;
          CopyMem(@Flags.State, @fFlags[Index].State, SizeOf(TLineFlags));
        End;

      opChange:
        Begin
          LineIndex := Index;
          Obj := fObjects[Index];
          CopyMem(@Flags.State, @fFlags[Index].State, SizeOf(TLineFlags));
          Operation := fStrings[Index];
        End;

      opAdd:
        Begin
          LineIndex := Count -1;
        End;

      opInsert:
        Begin
          LineIndex := Index;
        End;

      opDelete:
        Begin
          LineIndex := Index;
          Obj := fObjects[Index];
          CopyMem(@Flags.State, @fFlags[Index].State, SizeOf(TLineFlags));
          Operation := fStrings[Index];
        End;

      opAll:
        Begin
          s := LongWordToString(Count);
          SetLength(t, SizeOf(TLineFlags) + SizeOf(NativeUInt) + SizeOf(LongWord));
          For i := 0 To Count -1 Do Begin
            pLongWord(@t[1])^ := Length(fStrings[i]);
            CopyMem(@t[5], @fFlags[i].State, SizeOf(TLineFlags));
            pNativeUInt(@t[SizeOf(LongWord) + SizeOf(TLineFlags)])^ := NativeUInt(fObjects[i]);
            s := s + t + fStrings[i];
          End;
          Operation := s;
        End;

    End;

  End;

  fUndoLock.Leave;

End;

Procedure TAnsiStringlist.CompleteRedo;
Begin

  fUndoLock.Enter;
  fRedoInProgress := False;
  fUndoLock.Leave;

End;

Function  TAnsiStringlist.PerformRedo: AnsiString;
Var
  i, l2, j: Integer;
  CanRedo: Boolean;
  Ptr: pByte;

  Procedure DeleteLine(Index: Integer);
  Var
    i, l: Integer;
  Begin
    l := Count;
    If Index < l Then Begin
      For i := Index to l -2 do Begin
        fStrings[i] := fStrings[i+1];
        fObjects[i] := fObjects[i+1];
        fFlags[i] := fFlags[i+1];
      End;
      Resize(l -1);
    End;
    Dec(fCount);
  End;

Begin

  fUndoLock.Enter;
  Result := '';
  CanRedo := False;

  If fRedoBufferPtr >= 0 Then Begin

    i := fRedoList[fRedoBufferPtr].GroupIndex;

    j := fRedoBufferPtr;
    While (j >= 0) And (fRedoList[j].GroupIndex = i) Do Begin
      If fRedoList[j].opType <> opNone Then Begin
        CanRedo := True;
        Break;
      End;
      Dec(j);
    End;

    If Not CanRedo Then Begin
      fRedoBufferPtr := j;
      fUndoLock.Leave;
      Exit;
    End;

    CommenceUndo;

    While (fRedoBufferPtr >= 0) And (fRedoList[fRedoBufferPtr].GroupIndex = i) Do Begin

      With fRedoList[fRedoBufferPtr] Do Begin

        Result := Result + LongWordToString(FPCLine) + LongWordToString(CLine);

        Case opType of

          opNone:
            Begin
              // Do nothing.
            End;

          opFlags:
            Begin
              AddUndoItem(opFlags, LineIndex);
              CopyMem(@fFlags[LineIndex].State, @Flags.State, SizeOf(TLineFlags));
              Result := Result + LongWordToString(LineIndex);
            End;

          opChange:
            Begin
              AddUndoItem(opChange, LineIndex);
              fStrings[LineIndex] := Operation;
              fObjects[LineIndex] := Obj;
              CopyMem(@fFlags[LineIndex].State, @Flags.State, SizeOf(TLineFlags));
              Result := Result + LongWordToString(LineIndex);
            End;

          opAdd, opInsert:
            Begin
              AddUndoItem(opDelete, LineIndex);
              DeleteLine(LineIndex);
            End;

          opDelete:
            Begin
              l2 := Count;
              If l2 = 0 Then Begin
                AddUndoItem(opAdd, l2);
                Resize(l2 +1);
                fStrings[l2] := Operation;
                fObjects[l2] := Obj;
                CopyMem(@fFlags[l2].State, @Flags.State, SizeOf(TLineFlags));
                Result := Result + LongWordToString(0);
              End Else Begin
                AddUndoItem(opInsert, LineIndex);
                Resize(l2 +1);
                for j := l2 DownTo LineIndex +1 Do Begin
                  fStrings[j] := fStrings[j -1];
                  fObjects[j] := fObjects[j -1];
                  fFlags[j] := fFlags[j -1];
                end;
                fStrings[LineIndex] := Operation;
                fObjects[LineIndex] := Obj;
                CopyMem(@fFlags[LineIndex].State, @Flags.State, SizeOf(TLineFlags));
                Result := Result + LongWordToString(LineIndex);
              End;
              Inc(fCount);
            End;

          opAll:
            Begin
              AddUndoItem(opAll, 0);
              l2 := pLongWord(@Operation[1])^;
              If l2 <> Count Then Begin
                Resize(l2);
              End;
              ptr := @Operation[5];
              For i := 0 to l2 -1 do Begin
                SetLength(fStrings[i], pLongWord(Ptr)^);
                Inc(Ptr, SizeOf(LongWord));
                CopyMem(@fFlags[i].State, Ptr, SizeOf(TLineFlags));
                Inc(Ptr, SizeOf(TLineFlags));
                fObjects[i] := TObject(pNativeUInt(Ptr)^);
                Inc(Ptr, SizeOf(NativeUInt));
                CopyMem(@fStrings[i][1], Ptr, Length(fStrings[i]));
                Inc(Ptr, Length(fStrings[i]));
                Result := Result + LongWordToString(i);
              End;
              fCount := l2;
            End;

        End;

        fFPCPos := CPos;
        FPCLine := CLine;
        FPSelPos := SPos;
        FPSelLine := SLine;

      End;

      Dec(fRedoBufferPtr);

    End;

    CompleteUndo;
    If Assigned(OnChange) Then
      OnChange(-1, 0);

  End;

  fUndoLock.Leave;

End;

Function TAnsiStringlist.IndexOf(s: AnsiString): Integer;
Begin

  Result := 0;
  While Result < Count Do
    If fStrings[Result] = s Then Exit Else Inc(Result);
  Result := -1;

End;

Procedure TAnsiStringList.SetCapacity(v: Integer);
Begin

  Resize(v);

End;

Procedure TAnsiStringList.LoadFromHost(Filename: String);
Var
  st: TFileStream;
  Idx, Size: Integer;
  FileBuffer: Array of Byte;
  s: aString;
Begin

  If FileExists(Filename) Then Begin

    st := TFileStream.Create(Filename, fmOpenRead or fmShareDenyNone);
    if Assigned(st) then Begin
      Clear;
      Size := st.Size;
      If Size > 0 Then Begin
        SetLength(FileBuffer, Size);
        st.Read(FileBuffer[0], Size);
        st.Free;
        Idx := 0;
        s := '';
        While Idx < Length(FileBuffer) Do Begin
          If FileBuffer[Idx] in [10, 13] Then Begin
            Add(s);
            s := '';
            While (Idx < Length(FileBuffer)) And (FileBuffer[Idx] in [10, 13]) Do
              Inc(Idx);
          End Else Begin
            s := s + AnsiChar(FileBuffer[Idx]);
            Inc(Idx);
          End;
        End;
        If (Count > 0) And (fStrings[Count -1] = '') Then
          Delete(Count -1);
      End;
    End;

  End;

End;

Procedure TAnsiStringList.LoadFromFile(Filename: AnsiString);
Var
  FileID, Idx, Size: Integer;
  s: AnsiString;
  Error: TSP_ErrorCode;
  FileBuffer: Array of Byte;
Begin

  If SP_FileExists(Filename) Then Begin

    FileID := SP_FileOpen(Filename, False, Error);
    If FileID <> -1 Then Begin
      Clear;
      Size := SP_FileSize(FileID, Error);
      If Size > 0 Then Begin
        SetLength(FileBuffer, Size);
        SP_FileRead(FileID, @FileBuffer[0], Length(FileBuffer), Error);
        SP_FileClose(FileID, Error);
        Idx := 0;
        s := '';
        While Idx < Length(FileBuffer) Do Begin
          If FileBuffer[Idx] in [10, 13] Then Begin
            Add(s);
            s := '';
            While (Idx < Length(FileBuffer)) And (FileBuffer[Idx] in [10, 13]) Do
              Inc(Idx);
          End Else Begin
            s := s + AnsiChar(FileBuffer[Idx]);
            Inc(Idx);
          End;
        End;
        If (Count > 0) And (fStrings[Count -1] = '') Then
          Delete(Count -1);
      End Else
        SP_FileClose(FileID, Error);
    End;

  End;

End;

Procedure TAnsiStringList.SaveToFile(Filename: AnsiString);
Var
  s: AnsiString;
  FileID, Idx: Integer;
  Error: TSP_ErrorCode;
Begin

  FileSection.Enter;

  If SP_FileExists(Filename) Then
    SP_DeleteFile(Filename, Error);

  FileID := SP_FileOpen(Filename, True, Error);
  If Count > 0 Then Begin
    For Idx := 0 To Count -1 Do Begin
      s := fStrings[Idx] + #13#10;
      SP_FileWrite(FileID, @s[1], Length(s), Error);
    End;
  End Else
    SP_FileWrite(FileID, nil, 0, Error);
  SP_FileClose(FileID, Error);

  FileSection.Leave;

End;

 {----------------------}

end.
