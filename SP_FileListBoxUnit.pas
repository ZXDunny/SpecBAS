unit SP_FileListBoxUnit;

interface

Uses SP_BaseComponentUnit, SP_ListBoxUnit, SP_Util;

Type

SP_FileListBox = Class(SP_ListBox)

  Private

    fDirectory, fSearchStr: aString;
    fOnChooseFile,
    fOnChooseDir: SP_FLBSelectEvent;
    fLastKeyDownTime: LongWord;
    Procedure Populate;
    Procedure SetDirectory(s: aString);
    Function  SortProc(Val1, Val2: aString): Integer;
    Function  TextPrep(s: aString; c, i: Integer): aString;
    Function  GetString(Index: Integer): aString; Override;
    Procedure Select(Index: Integer); Override;
    Procedure PerformKeyDown(Var Handled: Boolean); Override;
    Procedure PerformKeyUp(Var Handled: Boolean); Override;

  Public

    Procedure Find(Filename: aString);
    Procedure GoParent;
    Property  Directory: aString read fDirectory write SetDirectory;
    Property  OnChooseFile: SP_FLBSelectEvent read fOnChooseFile write fOnChooseFile;
    Property  OnChooseDir: SP_FLBSelectEvent read fOnChooseDir write fOnChooseDir;
    Procedure DoDoubleClick(X, Y, Btn: Integer);

    Constructor Create(Owner: SP_BaseComponent);
    Destructor Destroy; Override;

End;

implementation

Uses Types, SysUtils, SP_Errors, SP_FileIO, SP_Components, SP_Input, SP_Sound, SP_SysVars, SP_Main;

// SP_FileListBox

Constructor SP_FileListBox.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  OnSort := SortProc;
  OnTextPrep := TextPrep;
  fCanUserSort := True;
  fSortedBy := 0;
  fSortDir := 1;
  fSorted := True;
  fOnDblClick := DoDoubleClick;

End;

Destructor SP_FileListBox.Destroy;
Begin

  Inherited;

End;

Procedure SP_FileListBox.Populate;
Var
  Files, FileSizes: TStringlist;
  Error: TSP_ErrorCode;
  i: Integer;
  s: aString;
Begin

  Lock;
  s := fDirectory;
  Error.Code := SP_ERR_OK;
  Files := TStringlist.Create;
  FileSizes := TStringlist.Create;
  SP_GetFileList(s, Files, FileSizes, Error, False);

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

    AddHeader(' Filename', 20 * iFW);
    AddHeader(' Size', 12 * iFW);
    AddHeader(' Date', 12 * iFW);
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
        v1 := StrToInt(s1);
        v2 := StrToInt(s2);
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
        y1 := StrToInt(Copy(s1, 7, 4)); m1 := StrToInt(Copy(s1, 4, 2)); d1 := StrToInt(Copy(s1, 1, 2));
        y2 := StrToInt(Copy(s2, 7, 4)); m2 := StrToInt(Copy(s2, 4, 2)); d2 := StrToInt(Copy(s2, 1, 2));
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

Procedure SP_FileListBox.DoDoubleClick(X, Y, Btn: Integer);
Var
  i: Integer;
Begin

  If Y >= iFH then Begin
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

  If fStrings[Index][1] = #0 Then
    If Assigned(OnSelect) Then
      OnSelect(Self, Index);

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

    Time := CB_GETTICKS;
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
      If Not Focused Then fOnSelect := nil;
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
