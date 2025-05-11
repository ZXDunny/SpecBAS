unit SP_FileListBoxUnit;

interface

Uses SP_BaseComponentUnit, SP_ListBoxUnit, SP_Util, SP_AnsiStringlist;

Type

SP_FileListBox = Class(SP_ListBox)

  Private

    fDirectory, fSearchStr: aString;
    fOnChooseFile,
    fOnChooseDir: SP_FLBSelectEvent;
    fLastKeyDownTime: LongWord;
    fFilterList: TAnsiStringlist;
    fHasContentFilter: Boolean;
    fMaxContentLen: Integer;
    Procedure Populate;
    Procedure SetDirectory(s: aString);
    Function  SortProc(Val1, Val2: aString): Integer;
    Function  TextPrep(s: aString; c, i: Integer): aString;
    Function  GetFilters: aString;
    Procedure SetFilters(s: aString);

  Public

    Procedure Find(Filename: aString);
    Procedure GoParent;
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

End;

implementation

Uses Types, SysUtils, SP_Errors, SP_FileIO, SP_Components, SP_Input, SP_Sound, SP_SysVars, SP_Main;

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

End;

Destructor SP_FileListBox.Destroy;
Begin

  Inherited;
  fFilterList.Free;

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

Procedure SP_FileListBox.Populate;
Var
  Files, FileSizes: TStringlist;
  s, t, Buffer: aString;
  i, j, f, cfW: Integer;
  Error: TSP_ErrorCode;
  Match, b: Boolean;
Begin

  Lock;
  Match := False;
  s := fDirectory;
  Error.Code := SP_ERR_OK;
  Files := TStringlist.Create;
  FileSizes := TStringlist.Create;
  SP_GetFileList(s, Files, FileSizes, Error, False);

  cfW:= Round(iFW * iSX);

  // Apply filters to the file list

  If fFilterList.Count > 0 Then Begin

    If fHasContentFilter Then
      SetLength(Buffer, fMaxContentLen);

    i := 0;
    While i < Files.Count Do Begin
      b := False;
      If Integer(Files.Objects[i]) = 1 Then Begin
        Inc(i);
        Continue;
      End Else
        For j := 0 To fFilterList.Count -1 Do Begin
          s := fFilterList[j];
          If s[1] = #0 Then // Mask
            Match := WildComp(Copy(s, 2), Files[i])
          Else
            If s[1] = #1 Then Begin // File content
              If Not b Then Begin
                f := SP_FileOpen(fDirectory + Files[i], False, Error);
                SP_FileRead(f, @Buffer[1], fMaxContentLen, Error);
                SP_FileClose(f, Error);
                b := True;
              End;
              t := Copy(s, 6);
              Match := Copy(Buffer, pLongWord(@s[2])^, Length(t)) = t;
            End;
          If Match Then Break;
        End;
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

    AddHeader(' Filename', ((Width Div cfw) - 26) * cFW);
    AddHeader(' Size', 12 * cFW);
    AddHeader(' Date', 12 * cFW);
    fHeaders[1].Justify := 1;

    For i := 0 To Files.Count -1 Do
      If Not ((Files[i][1] = '.') And (Integer(Files.Objects[i]) = 1)) Then
        Add(aChar(Files.Objects[i]) +                             // Directory flag
            Files[i] + #255 +                                     // File name
            IntToString(Int64(FileSizes.Objects[i])) + #255 +     // File size
            Copy(FileSizes[i], Length(FileSizes[i]) - 9, 10));    // File date

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
      Find(fSearchStr);
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
      ScrollInView;
    End;
  End;

  If Assigned(OnChooseDir) Then
    OnChooseDir(Self, fDirectory);

End;

Procedure SP_FileListBox.Find(Filename: aString);
Var
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
    if Lower(Copy(fStrings[i], 2, Length(Filename))) = Filename Then Begin
      fLastSelected := i;
      fSelected[i] := True;
      fSelectedIdx := i;
      ScrollInView;
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

end.
