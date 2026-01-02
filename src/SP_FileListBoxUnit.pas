unit SP_FileListBoxUnit;

{$INCLUDE SpecBAS.inc}

interface

Uses Windows, Classes, Math, System.Generics.Collections,
     SP_BaseComponentUnit, SP_Components, SP_ListBoxUnit, SP_Util, SP_AnsiStringlist, SP_Errors;

Type

SP_FileListBox = Class(SP_ListBox)

  Private

    fGotFileList: Boolean;
    fCacheFiles, fCacheFileSizes: TStringlist;
    fDirectory, fSearchStr: aString;
    fOnChooseFile,
    fOnChooseDir: SP_FLBSelectEvent;
    fLastKeyDownTime: LongWord;
    fFilterList: TAnsiStringlist;
    fHasContentFilter: Boolean;
    fMaxContentLen: Integer;
    fChangeTimer: pSP_TimerEvent;
    Procedure Populate;
    Procedure AddEntry(Filename: aString; Obj: Pointer; SizeInfo: aString; Size: Int64);
    Procedure SetDirectory(s: aString);
    Function  SortProc(Val1, Val2: aString): Integer;
    Function  TextPrep(s: aString; c, i: Integer): aString;
    Function  GetFilters: aString;
    Function  IsFileSuitable(fName, Buffer: aString): Boolean;
    Procedure SetFilters(s: aString);

  Public

    Procedure ChangeTimer(p: Pointer);
    Procedure Find(Filename: aString; Exact: Boolean);
    Procedure GoParent;
    Function  IndexOf(Filename: aString): Integer;
    Function  GetString(Index: Integer): aString; Override;
    Procedure Select(Index: Integer); Override;
    Procedure PerformKeyDown(Var Handled: Boolean); Override;
    Procedure PerformKeyUp(Var Handled: Boolean); Override;

    Property  Directory: aString read fDirectory write SetDirectory;
    Property  OnChooseFile: SP_FLBSelectEvent read fOnChooseFile write fOnChooseFile;
    Property  OnChooseDir: SP_FLBSelectEvent read fOnChooseDir write fOnChooseDir;
    Property  Filters: aString read GetFilters write SetFilters;

    Procedure DoDoubleClick(Sender: SP_BaseComponent; X, Y, Btn: Integer);

    Constructor Create(Owner: SP_BaseComponent);
    Destructor Destroy; Override;

    // User Properties

    Procedure RegisterProperties; Override;
    Procedure Set_Directory(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Directory: aString;
    Procedure Set_Mask(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Mask: aString;

    Procedure RegisterMethods; Override;
    Procedure Method_Refresh(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Parent(Params: Array of aString; Var Error: TSP_ErrorCode);

End;

implementation

Uses Types, SysUtils, SP_FileIO, SP_Input, SP_Sound, SP_SysVars, SP_Main;

// SP_FileListBox

Constructor SP_FileListBox.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fTypeName := 'spFileList';

  OnSort := SortProc;
  OnTextPrep := TextPrep;
  fCanUserSort := True;
  fSortedBy := 0;
  fSortDir := 1;
  fSorted := True;
  fFilterList := TAnsiStringList.Create;
  fOnDblClick := DoDoubleClick;

  fGotFileList := False;
  fCacheFiles := TStringList.Create;
  fCacheFileSizes := TStringList.Create;
  fChangeTimer := AddTimer(Self, Round(FPS), ChangeTimer, False, False);

End;

Destructor SP_FileListBox.Destroy;
Begin

  fFilterList.Free;
  fCacheFiles.Free;
  fCacheFileSizes.Free;
  RemoveTimer(fChangeTimer^.ID);

  Inherited;

End;

Function SP_FileListBox.GetFilters: aString;
Var
  s: aString;
  i: Integer;
Begin

  Result := '';

  For i := 0 To fFilterList.Count -1 Do Begin
    s := fFilterList[i];
    If s[1] = #0 Then // File mask
      Result := Result + Copy(s, 2) + ';'
    Else
      If s[1] = #1 Then // File contents
        Result := Result + IntToString(pLongWord(@s[2])^) + ':' + Copy(s, 6) + ';';
  End;
  Result := Copy(Result, 1, Length(Result) -1);

End;

Procedure SP_FileListBox.SetFilters(s: aString);
Var
  ps, ps2, i: Integer;
  Filter, s2: aString;
Begin

  fHasContentFilter := False;
  fMaxContentLen := 0;
  fFilterList.Clear;

  If s <> '' Then Repeat
    ps := Pos(';', s);
    If ps = 0 Then ps := Length(s) + 2;
    Case s[1] of
      '0':
        Begin // File mask
          Filter := #0 + Copy(s, 2, ps - 2);
          fFilterList.Add(Filter);
        End;
      '1':
        Begin // File contents
          s2 := Copy(s, 2, ps -2);
          ps2 := Pos(':', s2);
          If ps2 = 0 Then
            Exit
          Else Begin
            i := StringToLong(Copy(s2, 1, ps2 - 1));
            s2 := Copy(s2, ps2 + 1);
            Filter := #1 + LongwordToString(i) + s2;
            fHasContentFilter := True;
            fMaxContentLen := SP_Max(i + Length(s2), fMaxContentLen);
            fFilterList.Add(Filter);
          End;
        End;
    Else
      Begin
        Filter := #0 + s;
        fFilterList.Add(Filter);
      End;
    End;
    s := Copy(s, ps + 1);

  Until s = '';

End;

Function SP_FileListBox.IndexOf(Filename: aString): Integer;
Var
  i: Integer;
  s: aString;
Begin

  i := 0;
  Result := -1;
  FileName := Lower(Filename);
  While i < fCount Do Begin
    s := Lower(Copy(fStrings[i], 2));
    if Pos(#255, s) > 0 Then
      s := Copy(s, 1, Pos(#255, s) - 1);
    If s = Filename Then Begin
      Result := i;
      Break;
    End;
    Inc(i);
  End;

End;

Function SP_FileListBox.IsFileSuitable(fName, Buffer: aString): Boolean;
Var
  f, j: Integer;
  s, t: aString;
  b: Boolean;
  Error: TSP_ErrorCode;
Begin
  b := False;
  Result := False;
  For j := 0 To fFilterList.Count -1 Do Begin
    s := fFilterList[j];
    If s[1] = #0 Then // Mask
      Result := WildComp(Copy(s, 2), fName)
    Else
      If s[1] = #1 Then Begin // File content
        If Not b Then Begin
          f := SP_FileOpen(fDirectory + fName, False, Error);
          SP_FileRead(f, @Buffer[1], fMaxContentLen, Error);
          SP_FileClose(f, Error);
          b := True;
        End;
        t := Copy(s, 6);
        Result := Copy(Buffer, pLongWord(@s[2])^, Length(t)) = t;
      End;
    If Result Then Exit;
  End;
End;

Procedure SP_FileListBox.ChangeTimer(p: Pointer);
Var
  i, idx: Integer;
  Changed: Boolean;
  s, Buffer: aString;
  Error: TSP_ErrorCode;
  Files, FileSizes, Changes: TStringlist;
  Map: TDictionary<AnsiString, Integer>;

  Function Entry(idx: Integer): aString;
  Begin
    Result := aChar(Files.Objects[idx]) + Files[idx] + #255 + IntToString(Int64(FileSizes.Objects[idx])) + #255 + Copy(FileSizes[idx], Length(FileSizes[idx]) - 9, 10);
  End;

Begin

  If fGotFileList And (pSP_TimerEvent(p)^.Sender = Self) Then Begin

    If fHasContentFilter Then
      SetLength(Buffer, fMaxContentLen);

    s := fDirectory;
    Files := TStringlist.Create;
    FileSizes := TStringlist.Create;
    Changes := TStringlist.Create;
    Map := TDictionary<AnsiString, Integer>.Create;

    SP_GetFileList(s, Files, FileSizes, Error, False);

    For i := 0 To fCacheFiles.Count -1 Do
      If fCacheFiles[i][1] <> '.' Then
        Map.Add(fCacheFiles[i], i);

    Lock;

    For i := 0 To Files.Count -1 Do Begin
      Changed := False;
      If Files[i][1] = '.' Then Continue;
      If Map.ContainsKey(Files[i]) Then Begin
        // Contained in both. Remove it from the map, check sizes array to see if it changed
        Map.Remove(Files[i]);
        If fCacheFileSizes[i] <> FileSizes[i] Then Begin
          idx := IndexOf(Files[i]);
          if (idx >= 0) And (idx < Count) Then
            fStrings[idx] := Entry(i);
          Continue;
        End;
      End Else Begin
        // Not in the cache, so is a new file - test it for validity and add it in.
        If Integer(Files.Objects[i]) = 1 Then // is Dir?
          Changed := True
        Else
          If IsFileSuitable(Files[i], Buffer) Then
            Changed := True;
        If Changed Then Begin
          // Add it to the current list
          AddEntry(Files[i], Files.Objects[i], FileSizes[i], Int64(FileSizes.Objects[i]));
          Continue;
        End;
      End;
    End;

    // Now any files or folders left in the map have been deleted, so remove them.

    If Map.Count > 0 Then
      For s in Map.Keys Do Begin
        i := IndexOf(s);
        If (i >= 0) And (i < Count) Then
          Delete(i);
      End;

    Sort(fSortedBy);
    Unlock;

    fCacheFiles.Clear;
    fCacheFileSizes.Clear;
    fCacheFiles.AddStrings(Files);
    fCacheFileSizes.AddStrings(FileSizes);
    fGotFileList := True;

    Map.Free;
    Files.Free;
    Changes.Free;
    FileSizes.Free;

  End;

End;

Procedure SP_FileListBox.AddEntry(Filename: aString; Obj: Pointer; SizeInfo: aString; Size: Int64);
Begin

  Add(aChar(Obj) +                               // Directory flag
      FileName + #255 +                          // File name
      IntToString(Size) + #255 +                 // File size
      Copy(SizeInfo, Length(SizeInfo) - 9, 10)); // File date

End;

Procedure SP_FileListBox.Populate;
Var
  Files, FileSizes: TStringlist;
  s, Buffer: aString;
  i, cfW: Integer;
  Error: TSP_ErrorCode;
  Match: Boolean;
Begin

  Lock;
  s := fDirectory;
  Error.Code := SP_ERR_OK;
  cfW:= Round(iFW * iSX);

  fGotFileList := False; // Prevent monitoring
  Files := TStringlist.Create;
  FileSizes := TStringlist.Create;
  SP_GetFileList(s, Files, FileSizes, Error, False);

  // Store in the cache and add a watcher

  fCacheFiles.Clear;
  fCacheFileSizes.Clear;
  fCacheFiles.AddStrings(Files);
  fCacheFileSizes.AddStrings(FileSizes);
  fGotFileList := True; // We can start monitor now

  // Apply filters to the file list

  If fFilterList.Count > 0 Then Begin

    If fHasContentFilter Then
      SetLength(Buffer, fMaxContentLen);

    i := 0;
    While i < Files.Count Do Begin
      If Integer(Files.Objects[i]) = 1 Then Begin
        Inc(i);
        Continue;
      End Else
        Match := IsFileSuitable(Files[i], Buffer);
      If Match Then
        Inc(i)
      Else Begin
        Files.Delete(i);
        FileSizes.Delete(i);
      End;
    End;

  End;

  // Files.Objects contains 1 or 0 (directory or file)
  // Sizes.Objects contains numeric file size in bytes
  // Sizes[i] is textual representation of size in bytes, final 10 chars is file date

  Clear;

  If Files.Count = 0 Then Begin

    If Not SP_DirectoryExists(fDirectory) Then
      Add(' Directory not found')
    Else
      Add(' No Files Found');

    Enabled := False;

  End Else Begin

    Enabled := True;

    AddHeader(' Filename', ((Width Div cfw) - 21) * cFW);
    AddHeader(' Size', 7 * cFW);
    AddHeader(' Date', 12 * cFW);
    fHeaders[1].Justify := 1;
    fHeaders[1].Proportional := True;
    fHeaders[2].Proportional := False;

    For i := 0 To Files.Count -1 Do
      If Not ((Files[i][1] = '.') And (Integer(Files.Objects[i]) = 1)) Then
        AddEntry(Files[i], Files.Objects[i], FileSizes[i], Int64(FileSizes.Objects[i]));

  End;

  Files.Free;
  FileSizes.Free;

  For i := 0 To fCount -1 Do
    fSelected[i] := False;

  Sort(fSortedBy);
  Unlock;

End;

Procedure SP_FileListBox.SetDirectory(s: aString);
Begin

  SetLength(fDirectory, Length(s));
  CopyMem(@fDirectory[1], @s[1], Length(s));
  If Copy(fDirectory, Length(fDirectory), 1) <> '/' Then
    fDirectory := fDirectory + '/';
  Populate;
  If fCount > 0 Then Begin
    fLastSelected := 0;
    fSelected[fLastSelected] := True;
    fSelectedIdx := 0;
    fVScroll.Pos := 0;
    Paint;
  End;

End;

Function  SP_FileListBox.GetString(Index: Integer): aString;
Var
  ps: Integer;
Begin

  // Override to include dir/file tag byte and the filename for deadlock comparisons

  Result := Inherited;
  If fSortedBy <> 0 Then
    Result := fStrings[Index][1] + Result;
  ps := Pos(#255, fStrings[Index]);
  Result := Result + #255 + Copy(fStrings[Index], 2, ps -2);

End;

Function  SP_FileListBox.SortProc(Val1, Val2: aString): Integer;
Var
  s1, s2, f1, f2: aString;
  v1, v2: Integer;
  dir1, dir2: Boolean;
  t, y1, m1, d1, y2, m2, d2: Integer;
Begin

  Result := 0;
  If Val1 = Val2 Then Exit;

  t := Pos(#255, Val1);
  f1 := Lower(Copy(Val1, t+1));
  s1 := Lower(Copy(Val1, 2, t-2));
  t := Pos(#255, Val2);
  f2 := Lower(Copy(Val2, t+1));
  s2 := Lower(Copy(Val2, 2, t-2));
  dir1 := Boolean(Val1[1]);
  dir2 := Boolean(Val2[1]);

  If dir1 or dir2 Then Begin
    If dir1 And dir2 Then Begin
      If f1 > f2 Then
        Result := 1
      Else
        If f1 < f2 Then
          Result := -1
        Else
          Result := 0;
    End Else
      If dir1 Then
        Result := -1
      Else
        Result := 1;
    Exit;
  End;

  Case fSortedBy of
    0: // Filename
      Begin
        If s1 > s2 Then
          Result := 1
        Else
          If s1 < s2 Then
            Result := -1
          Else
            Result := 0;
      End;
    1: // File size
      Begin
        v1 := StringToInt(s1);
        v2 := StringToInt(s2);
        If v1 > v2 Then
          Result := 1
        Else
          If v1 < v2 Then
            Result := -1
          Else // Deadlock - test filenames
            If f1 > f2 Then
              Result := 1
            Else
              If f1 < f2 Then
                Result := -1
              Else
                Result := 0;
      End;
    2: // File date
      Begin
        y1 := StringToInt(Copy(s1, 7, 4)); m1 := StringToInt(Copy(s1, 4, 2)); d1 := StringToInt(Copy(s1, 1, 2));
        y2 := StringToInt(Copy(s2, 7, 4)); m2 := StringToInt(Copy(s2, 4, 2)); d2 := StringToInt(Copy(s2, 1, 2));
        If y1 > y2 Then
          Result := 1
        Else
          If y1 < y2 Then
            Result := -1
          Else
            If m1 > m2 Then
              Result := 1
            Else
              If m1 < m2 Then
                Result := -1
              Else
                If d1 > d2 Then
                  Result := 1
                Else
                  If d1 < d2 Then
                    Result := -1
                  Else // deadlock - test filenames
                    If f1 > f2 Then
                      Result := 1
                    Else
                      If f1 < f2 Then
                        Result := -1
                      Else
                        Result := 0;
      End;
  End;

End;

Function  SP_FileListBox.TextPrep(s: aString; c, i: Integer): aString;
Var
  v, l: Integer;
Begin

  If c = 0 Then Begin
    If s[1] = #1 Then
      Result := #16#1#0#0#0+Copy(s, 2)
    Else
      Result := Copy(s, 2);
  End Else
    If c = 1 Then Begin
      If fStrings[i][1] = #1 Then
        Result := '<Dir> '
      Else Begin
        v := 0;
        result := ' ';
        l := Length(s);
        While v < l Do Begin
          Result := s[l - v] + Result;
          Inc(v);
          If (v < l) And (v Mod 3 = 0) Then Result := ',' + Result;
        End;
      End;
    End Else
      If fStrings[i][1] = #1 Then
        Result := ''
      Else
        Result := s;

   Result := ' ' + Result;

End;

Procedure SP_FileListBox.DoDoubleClick(Sender: SP_BaseComponent; X, Y, Btn: Integer);
Var
  i, cfH: Integer;
Begin

  cfH := Round(iFH * iSY);
  If Y >= cFH then Begin
    i := fLastSelected;
    If fStrings[i][1] = #1 Then Begin
      If Copy(fDirectory, Length(fDirectory), 1) <> '/' Then
        fDirectory := fDirectory + '/';
      Directory := fDirectory + Copy(fStrings[i], 2, Pos(#255, fStrings[i]) -2);
      If Assigned(OnChooseDir) Then
        OnChooseDir(Self, fDirectory);
    End Else
      If Assigned(OnChooseFile) Then
        OnChooseFile(Self, Copy(fStrings[i], 2, Pos(#255, fStrings[i]) -2));
  End;

End;

Procedure SP_FileListBox.Select(Index: Integer);
Begin

  // Don't trigger select for directories

  If (Index >= 0) And (Index < Count) Then Begin
    If fStrings[Index][1] = #0 Then
      If Assigned(OnSelect) Then
        OnSelect(Self, Index);
  End Else
    ClearSelected;

End;

Procedure SP_FileListBox.PerformKeyDown(Var Handled: Boolean);
Var
  i: Integer;
  Time: LongWord;
  NewChar: Byte;
Begin

  If not (fEnabled and fFocused) Then Exit;

  NewChar := DecodeKey(cLastKey);
  Handled := False;

  If (NewChar = 0) {$IFNDEF FPC} And (cLastKeyChar <> 1) {$ENDIF} Then Begin

    Case cLastKey of

      K_ESCAPE:
        Begin
          fChosen := True;
          SP_PlaySystem(ClickChan, ClickBank);
          Handled := True;
        End;

      K_BACK:
        Begin
          GoParent;
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          Handled := True;
        End;

      K_RETURN:
        Begin
          i := fLastSelected;
          If fStrings[i][1] = #1 Then Begin
            If Copy(fDirectory, Length(fDirectory), 1) <> '/' Then
              fDirectory := fDirectory + '/';
            Directory := fDirectory + Copy(fStrings[i], 2, Pos(#255, fStrings[i]) -2);
            If Assigned(OnChooseDir) Then
              OnChooseDir(Self, fDirectory);
          End Else
            fChosen := True;
          Handled := True;
        End;
    Else
      Inherited;

    End;

  End Else Begin

    Time := Round(CB_GETTICKS);
    If Time - fLastKeyDownTime > 1000 Then
      fSearchStr := '';

    fLastKeyDownTime := Time;
    If NewChar in [32..127] Then Begin
      fSearchStr := fSearchStr + aChar(NewChar);
      Find(fSearchStr, False);
      SP_PlaySystem(CLICKCHAN, CLICKBANK);
      Handled := True;
    End;

  End;

End;

Procedure SP_FileListBox.PerformKeyUp(Var Handled: Boolean);
Var
  i: Integer;
Begin

  Case cLastKey Of

    K_RETURN:
      Begin
        If fChosen Then Begin
          i := fLastSelected;
          If fStrings[i][1] = #1 Then Begin
            If Copy(fDirectory, Length(fDirectory), 1) <> '/' Then
              fDirectory := fDirectory + '/';
            Directory := fDirectory + Copy(fStrings[i], 2, Pos(#255, fStrings[i]) -2);
            If Assigned(OnChooseDir) Then
              OnChooseDir(Self, fDirectory);
          End Else
            If Assigned(OnChooseFile) Then
              OnChooseFile(Self, Copy(fStrings[i], 2, Pos(#255, fStrings[i]) -2));
          Handled := True;
        End;
      End;

    K_ESCAPE:
      Begin
        if fChosen Then Begin
          Abort;
          Handled := True;
        End;
      End;

  End;

End;

Procedure SP_FileListBox.GoParent;
Var
  i: Integer;
  s: aString;
Begin

  s := fDirectory;
  Directory := SP_GetParentDir(fDirectory);

  For i := 0 To fCount -1 Do Begin
    fSelected[i] := False;
    If fDirectory + Copy(fStrings[i], 2, Pos(#255, fStrings[i]) -2) + '/' = s Then Begin
      fLastSelected := i;
      fSelected[i] := True;
      fSelectedIdx := i;
      fSearchStr := '';
      ScrollInView(False);
    End;
  End;

  If Assigned(OnChooseDir) Then
    OnChooseDir(Self, fDirectory);

End;

Procedure SP_FileListBox.Find(Filename: aString; Exact: Boolean);
Var
  s: aString;
  i, l: Integer;
  oSel: Array of Boolean;
  OnSel: SP_LBSelectEvent;
Begin

  l := fLastSelected;
  SetLength(oSel, fCount);
  for i := 0 to fCount -1 Do Begin
    oSel[i] := fSelected[i];
    fSelected[i] := False;
  End;

  i := 0;
  fLastSelected := -1;
  FileName := Lower(Filename);
  While i < fCount Do Begin
    fSelected[i] := False;
    s := Lower(Copy(fStrings[i], 2));
    if Pos(#255, s) > 0 Then
      s := Copy(s, 1, Pos(#255, s) - 1);
    If (Exact And (s = Filename)) or (Not Exact And (Copy(s, Length(Filename)) = Filename)) Then Begin
      fLastSelected := i;
      fSelected[i] := True;
      fSelectedIdx := i;
      ScrollInView(False);
      OnSel := fOnSelect;
      Select(i);
      fOnSelect := OnSel;
      Paint;
      Break;
    End;
    Inc(i);
  End;

  If fLastSelected = -1 Then Begin
    fLastSelected := l;
    for i := 0 to fCount -1 Do
      fSelected[i] := oSel[i];
  End;

  Paint;

End;

// User properties and methods

Procedure SP_FileListBox.RegisterProperties;
Begin

  Inherited;

  RegisterProperty('dir', Get_Directory, Set_Directory, ':s|s');
  RegisterProperty('mask', Get_Mask, Set_Mask, ':s|s');

End;

Procedure SP_FileListBox.Set_Directory(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Directory := s;

End;

Function SP_FileListBox.Get_Directory: aString;
Begin

  Result := Directory;

End;

Procedure SP_FileListBox.Set_Mask(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Filters := s;

End;

Function SP_FileListBox.Get_Mask: aString;
Begin

  Result := Filters;

End;

Procedure SP_FileListBox.RegisterMethods;
Begin

  Inherited;
  RegisterMethod('refresh', '', Method_Refresh);
  RegisterMethod('parent', '', Method_Parent);

End;

Procedure SP_FileListBox.Method_Refresh(Params: Array of aString; Var Error: TSP_ErrorCode);
Begin

  Populate;

End;

Procedure SP_FileListBox.Method_Parent(Params: Array of aString; Var Error: TSP_ErrorCode);
Begin

  GoParent;

End;

end.

