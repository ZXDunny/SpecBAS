unit SP_ListBoxUnit;

interface

Uses Types, SP_Util, SP_BaseComponentUnit, SP_ScrollBarUnit;

Type

SP_FLBSelectEvent = Procedure(Sender: SP_BaseComponent; Name: aString) of Object;

SPHeaderType = (spText, spNumeric, spFileSize, spDate);

SP_ListBoxHeader = Record

  Caption: aString;
  Width:   Integer;
  Justify: Integer; // -1 left, 0 centre, 1 right

End;

SP_ListBox = Class(SP_BaseComponent)

  Public

    fStrings:     Array of aString;
    fObjects:     Array of TObject;
    fHeaders:     Array of SP_ListBoxHeader;
    fSelected:    Array of Boolean;
    fCount:       Integer;
    fHCount:      Integer;
    fSelCount:    Integer;
    fHScroll,
    fVScroll:     SP_ScrollBar;
    fClientRgn:   TRect;
    fNeedPaint:   Boolean;
    fMultiSelect: Boolean;
    fSelectedIdx: Integer;
    fShowHeaders: Boolean;
    fSorted:      Boolean;
    fSortedBy:    Integer;
    fSortDir:     Integer;
    fCanUserSort: Boolean;
    fChosen:      Boolean;
    fSortByAlpha: Boolean;
    fLastSelected:Integer;
    fSortProc:    SP_SortEvent;
    fTextPrep:    SP_TextPrepare;
    fOnSelect:    SP_LBSelectEvent;
    fOnChoose:    SP_LBChooseEvent;
    fSelectAnchor:Integer;
    fSortIndClr,
    fSortedColumnClr,
    fHeaderClr:   Integer;
    fMouseMode:   Integer;
    fHeaderGrab:  Integer;
    fLastMouseX:  Integer;

    Procedure     Clear;
    Procedure     SetItem(Index: Integer; Value: aString);
    Function      GetItem(Index: Integer): aString;
    Procedure     SetObject(Index: Integer; Value: TObject);
    Function      GetObject(Index: Integer): TObject;
    Procedure     SetHeader(Index: Integer; Value: SP_ListBoxHeader);
    Procedure     SetFontClr(c: Byte); Override;
    Procedure     SetDisabledFontClr(c: Byte); Override;
    Function      GetHeader(Index: Integer): SP_ListBoxHeader;
    Procedure     SetColWidth(Index: Integer; Value: Integer);
    Function      GetColWidth(Index: Integer): Integer;
    Function      GetSelected(Index: Integer): Boolean;
    Procedure     SetUIElements;
    Procedure     vScroll(Delta, NewPos: Integer);
    Procedure     hScroll(Delta, NewPos: Integer);
    Procedure     SetShowHeaders(b: Boolean);
    Procedure     SortStrings(L, R: Integer);
    Function      GetString(Index: Integer): aString; Virtual;
    Function      GetOnDblClick: SP_MouseEvent;
    Procedure     SetOnDblClick(Event: SP_MouseEvent);
    Procedure     Select(Index: Integer); Virtual;
    Procedure     PerformKeyDown(Var Handled: Boolean); Override;
    Procedure     PerformKeyUp(Var Handled: Boolean); Override;
    Procedure     SetBackgroundClr(c: Byte); Override;
    Procedure     ScrollInView;
    Procedure     Draw; Override;
    Function      GetHeaderCount: Integer;
    Procedure     SetHeaderClr(c: Integer);
    Procedure     SetSortIndClr(c: Integer);
    Procedure     SetSortedColumnClr(c: Integer);

    Procedure     MouseWheel(X, Y, Btn, Delta: Integer); Override;
    Procedure     MouseDown(X, Y, Btn: Integer); Override;
    Procedure     MouseMove(X, Y, Btn: Integer); Override;
    Procedure     MouseUp(X, Y, Btn: Integer); Override;
    Procedure     DoubleClick(X, Y, Btn: Integer); Override;
    Procedure     Unlock; Override;
    Procedure     Add(Caption: aString);
    Procedure     Insert(Index: Integer; Caption: aString);
    Procedure     Delete(Index: Integer);
    Procedure     AddHeader(Value: SP_ListBoxHeader); Overload;
    Procedure     AddHeader(Caption: aString; Width: Integer); Overload;
    Procedure     InsertHeader(Index: Integer; Value: SP_ListBoxHeader); Overload;
    Procedure     InsertHeader(Index: Integer; Caption: aString; Width: Integer); Overload;
    Procedure     DeleteHeader(Index: Integer);
    Procedure     Sort(Index: Integer);

    Property      Items[Index: Integer]:     aString          read GetItem          write SetItem;
    Property      Objects[Index: Integer]:   TObject          read GetObject        write SetObject;
    Property      Selected[Index: Integer]:  Boolean          read GetSelected;
    Property      Headers[Index: Integer]:   SP_ListBoxHeader read GetHeader        write SetHeader;
    Property      ColWidths[Index: Integer]: Integer          read GetColWidth      write SetColWidth;
    Property      MultiSelect:               Boolean          read fMultiSelect     write fMultiSelect;
    Property      ShowHeaders:               Boolean          read fShowHeaders     write SetShowHeaders;
    Property      CanUserSort:               Boolean          read fCanUserSort     write fCanUserSort;
    Property      OnSelect:                  SP_LBSelectEvent read fOnSelect        write fOnSelect;
    Property      OnSort:                    SP_SortEvent     read fSortProc        write fSortProc;
    Property      OnTextPrep:                SP_TextPrepare   read fTextPrep        write fTextPrep;
    Property      OnDblClick:                SP_MouseEvent    read GetOnDblClick    write SetOnDblClick;
    Property      OnChoose:                  SP_LBChooseEvent read fOnChoose        Write fOnChoose;
    Property      HeaderCount:               Integer          read GetHeaderCount;
    Property      Count:                     Integer          read fCount;
    Property      SortByAlpha:               Boolean          read fSortByAlpha     write fSortByAlpha;
    Property      HeaderClr:                 Integer          read fHeaderClr       write SetHeaderClr;
    Property      SortIndClr:                Integer          read fSortIndClr      write SetSortIndClr;
    Property      SortedColumnClr:           Integer          read fSortedColumnClr write SetSortedColumnClr;
    Property      SelectedIndex:             Integer          read fSelectedIdx;

    Constructor   Create(Owner: SP_BaseComponent);
    Destructor    Destroy; Override;

End;

Const

  mmNone = 0;
  mmHeaderDrag = 1;

implementation

Uses Math, SP_Components, SP_SysVars, SP_Input, SP_Sound;

// SP_ListBox

Constructor SP_ListBox.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fCount := 0;

  fHScroll := SP_ScrollBar.Create(Self);
  fHScroll.Border := False;
  fHScroll.Kind := spHorizontal;
  fHScroll.OnScroll := hScroll;
  fHScroll.WheelStep := SP_ScrollWheelValue * iFW;

  fVScroll := SP_ScrollBar.Create(Self);
  fVScroll.Border := False;
  fVScroll.Kind := spVertical;
  fVScroll.OnScroll := vScroll;
  fVScroll.WheelStep := SP_ScrollWheelValue * iFH;

  fShowHeaders := True;
  fMultiSelect := True;
  SetUIElements;

  fSorted := True;
  fSortedBy := 1;
  fSortDir := 1;
  CanFocus := True;
  fChosen := False;
  fSortByAlpha := False;
  fHeaderClr := SP_UIHalfLight;
  fSortIndClr := SP_UITextDisabled;
  fSortedColumnClr := SP_UIHighlight;
  fMouseMode := 0;
  fCount := 0;

End;

Destructor SP_ListBox.Destroy;
Begin

  Inherited;

End;

Procedure SP_ListBox.SetBackgroundClr(c: Byte);
Begin

  Inherited;
  fVScroll.BackgroundClr := c;
  fHScroll.BackgroundClr := c;

End;

Procedure SP_ListBox.SetHeaderClr(c: Integer);
Begin

  If c <> fHeaderClr Then Begin
    fHeaderClr := c;
    Paint;
  End;

End;

Procedure SP_ListBox.SetSortIndClr(c: Integer);
Begin

  If c <> fSortIndClr Then Begin
    fSortIndClr := c;
    Paint;
  End;

End;

Procedure SP_ListBox.SetSortedColumnClr(c: Integer);
Begin

  If c <> fSortedColumnClr Then Begin
    fSortedColumnClr := c;
    Paint;
  End;

End;

Function SP_ListBox.GetOnDblClick: SP_MouseEvent;
Begin
  Result := fOnDblClick;
End;

Procedure SP_ListBox.SetOnDblClick(Event: SP_MouseEvent);
Begin
  fOnDblClick := Event;
End;

Procedure SP_ListBox.SetFontClr(c: Byte);
Begin

  fHScroll.FontClr := c;
  fVScroll.FontClr := c;
  Inherited;

End;

Procedure SP_ListBox.SetDisabledFontClr(c: Byte);
Begin

  fHScroll.DisabledFontClr := c;
  fVScroll.DisabledFontClr := c;
  Inherited;

End;

Procedure SP_ListBox.SetItem(Index: Integer; Value: aString);
Begin

  If (Index >= 0) And (Index < Length(fStrings)) Then
    fStrings[Index] := Value;
  If fLockCount = 0 Then Paint Else fNeedPaint := True;

End;

Function SP_ListBox.GetItem(Index: Integer): aString;
Begin

  If (Index >= 0) And (Index < Length(fStrings)) Then
    Result := fStrings[Index]
  Else
    Result := '';

End;

Procedure SP_ListBox.SetObject(Index: Integer; Value: TObject);
Begin

  If (Index >= 0) And (Index < Length(fStrings)) Then
    fObjects[Index] := Value;

End;

Function SP_ListBox.GetObject(Index: Integer): TObject;
Begin

  If (Index >= 0) And (Index < Length(fStrings)) Then
    Result := fObjects[Index]
  Else
    Result := Nil;

End;

Procedure SP_ListBox.AddHeader(Value: SP_ListBoxHeader);
Begin

  SetLength(fHeaders, fHCount +1);
  fHeaders[fHCount].Caption := Value.Caption;
  fHeaders[fHCount].Width := Value.Width;
  fHeaders[fHCount].Justify := Value.Justify;
  Inc(fHCount);
  SetUIElements;

End;

Procedure SP_ListBox.AddHeader(Caption: aString; Width: Integer);
Begin

  SetLength(fHeaders, fHCount +1);
  fHeaders[fHCount].Caption := Caption;
  fHeaders[fHCount].Width := Width;
  fHeaders[fHCount].Justify := -1;
  Inc(fHCount);
  SetUIElements;

End;

Procedure SP_ListBox.InsertHeader(Index: Integer; Value: SP_ListBoxHeader);
Var
  i: Integer;
Begin

  SetLength(fHeaders, fHCount +1);
  For i := fHCount DownTo Index +1 Do Begin
    fHeaders[i].Caption := fHeaders[i -1].Caption;
    fHeaders[i].Width := fHeaders[i -1].Width;
  End;
  fHeaders[Index].Caption := Value.Caption;
  fHeaders[Index].Width := Value.Width;
  fHeaders[Index].Justify := Value.Justify;
  Inc(fHCount);
  SetUIElements;

End;

Procedure SP_ListBox.InsertHeader(Index: Integer; Caption: aString; Width: Integer);
Var
  i: Integer;
Begin

  SetLength(fHeaders, fHCount +1);
  For i := fHCount DownTo Index +1 Do Begin
    fHeaders[i].Caption := fHeaders[i -1].Caption;
    fHeaders[i].Width := fHeaders[i -1].Width;
  End;
  fHeaders[Index].Caption := Caption;
  fHeaders[Index].Width := Width;
  fHeaders[Index].Justify := -1;
  Inc(fHCount);
  SetUIElements;

End;

Procedure SP_ListBox.DeleteHeader(Index: Integer);
Var
  i: Integer;
Begin

  Dec(fHCount);
  For i := Index To fHCount -1 Do Begin
    fHeaders[i].Caption := fHeaders[i+1].Caption;
    fHeaders[i].Width := fHeaders[i+1].Width;
    fHeaders[i].Justify := fHeaders[i+1].Justify;
  End;
  SetLength(fHeaders, fHCount);

  SetUIElements;

End;

Procedure SP_ListBox.SetHeader(Index: Integer; Value: SP_ListBoxHeader);
Begin

  If (Index >= 0) And (Index < fHCount) Then Begin
    fHeaders[Index].Caption := Value.Caption;
    fHeaders[Index].Width := Value.Width;
    fHeaders[Index].Justify := Value.Justify;
    SetUIElements;
  End;

End;

Function SP_ListBox.GetHeader(Index: Integer): SP_ListBoxHeader;
Begin

  Result.Caption := '';
  Result.Width := 0;
  If (Index >= 0) And (Index < fHCount) Then Begin
    Result.Caption := fHeaders[Index].Caption;
    Result.Width := fHeaders[Index].Width;
    Result.Justify := fHeaders[Index].Justify;
  End;

End;

Procedure SP_ListBox.SetColWidth(Index: Integer; Value: Integer);
Begin

  If (Index >= 0) And (Index < fHCount) Then
    fHeaders[Index].Width := Value;

End;

Function SP_ListBox.GetColWidth(Index: Integer): Integer;
Begin

  Result := 0;
  If (Index >= 0) And (Index < fHCount) Then
    Result := fHeaders[Index].Width;

End;

Function SP_ListBox.GetHeaderCount: Integer;
Begin

  Result := Length(fHeaders);

End;

Function SP_ListBox.GetSelected(Index: Integer): Boolean;
Begin

  Result := False;
  If (Index >= 0) And (Index < fCount) Then
    Result := fSelected[Index];

End;

Procedure SP_ListBox.SetShowHeaders(b: Boolean);
Begin

  fShowHeaders := b;
  SetUIElements;

End;

Procedure SP_ListBox.Unlock;
Begin

  fLockCount := Math.Max(fLockCount -1, 0);
  If fLockCount = 0 Then
    If fNeedPaint Then
      SetUIElements;

End;

Procedure SP_ListBox.Clear;
Begin

  SetLength(fStrings, 0);
  SetLength(fObjects, 0);
  SetLength(fSelected, 0);
  SetLength(fHeaders, 0);
  fHCount := 0;
  fCount := 0;
  SetUIElements;

End;

Procedure SP_ListBox.Add(Caption: aString);
Begin

  SetLength(fStrings, fCount +1);
  SetLength(fObjects, fCount +1);
  SetLength(fSelected, fCount +1);
  fStrings[fCount] := Caption;
  fObjects[fCount] := nil;
  fSelected[fCount] := False;
  Inc(fCount);

  SetUIElements;

End;

Procedure SP_ListBox.Insert(Index: Integer; Caption: aString);
Var
  i: Integer;
Begin

  SetLength(fStrings, fCount +1);
  SetLength(fSelected, fCount +1);
  For i := fCount DownTo Index +1 Do Begin
    fStrings[i] := fStrings[i -1];
    fSelected[i] := fSelected[i -1];
    fObjects[i] := fObjects[i -1];
  End;
  fStrings[Index] := Caption;
  fSelected[Index] := False;
  fObjects[Index] := Nil;
  Inc(fCount);
  If Index <= fSelectedIdx Then
    Inc(fSelectedIdx);

  SetUIElements;

End;

Procedure SP_ListBox.Delete(Index: Integer);
Var
  i: Integer;
Begin

  Dec(fCount);
  For i := Index To fCount -1 Do Begin
    fStrings[i] := fStrings[i+1];
    fSelected[i] := fSelected[i+1];
    fObjects[i] := fObjects[i+1];
  End;
  SetLength(fStrings, fCount);
  SetLength(fSelected, fCount);

  SetUIElements;

End;

Procedure SP_ListBox.Sort(Index: Integer);
Var
  i, j, r: Integer;
  s: aString;
  b: Boolean;
Begin

  If (Index >= 0) And (Index < fHCount) Then
    fSortedBy := Index
  Else
    fSortedBy := 0;

  SortStrings(0, fCount -1);

  fSorted := fCanUserSort;
  SetUIElements;

End;

Function SP_ListBox.GetString(Index: Integer): aString;
Var
  c, ps, p, l: Integer;
Begin
  // Only use by Sort algorithms
  Result := fStrings[Index];
  c := 0;
  p := 1;
  l := Length(Result);
  While (p <= l) And (c < fSortedBy) Do Begin
    If Result[p] = #255 Then Inc(c);
    Inc(p);
  End;
  If c = fSortedBy Then
    Result := Copy(Result, p)
  Else
    Result := '';
  ps := Pos(#255, Result);
  If ps > 0 Then
    Result := Copy(Result, 1, ps -1);
  If fSortByAlpha Then Begin
    While Copy(Result, 1, 1) <= #32 Do Begin
      Case Ord(Result[1]) of
        16, 17, 18, 19, 20, 23, 24, 26, 27:
          Begin // INK/PAPER/OVER/TRANSPARENT/INVERSE/TAB/ITALIC/BOLD control
            Result := Copy(Result, 1 + SizeOf(LongWord) + 1)
          End;
        21, 22:
          Begin // MOVE, AT control
            Result := Copy(Result, 1 + (SizeOf(LongWord) * 2) + 1);
          End;
        25:
          Begin // SCALE control
            Result := Copy(Result, 1 + (SizeOf(aFloat) * 2) + 1);
          End;
        Else
          Begin
            Result := Copy(Result, 2);
          End;
      End;
    End;
  End;
End;

Procedure SP_ListBox.SortStrings(L, R: Integer);
Var
  I, J: Integer;
  Ps, T: aString;
  b: Boolean;
  o: TObject;
Begin

  If fCount <= 1 Then Exit; // Already sorted.

  I := L;
  J := R;
  Ps := GetString((L + R) Shr 1);

  Repeat

    If fSortDir = 1 Then Begin

      If Assigned(OnSort) Then Begin
        While OnSort(GetString(I), Ps) = -1 Do Inc(I);
        While OnSort(GetString(J), Ps) = 1  Do Dec(J);
      End Else Begin
        While GetString(I) < Ps Do Inc(I);
        while GetString(J) > Ps Do Dec(J);
      End;

    End Else Begin

      If Assigned(OnSort) Then Begin
        While OnSort(GetString(I), Ps) = 1  Do Inc(I);
        While OnSort(GetString(J), Ps) = -1 Do Dec(J);
      End Else Begin
        While GetString(I) > Ps Do Inc(I);
        while GetString(J) < Ps Do Dec(J);
      End;

    End;

    If I <= J Then Begin
      T := fStrings[I];
      fStrings[I] := fStrings[J];
      fStrings[J] := T;
      b := fSelected[I];
      fSelected[I] := fSelected[J];
      fSelected[J] := b;
      o := fObjects[I];
      fObjects[I] := fObjects[J];
      fObjects[J] := o;
      Inc(I);
      Dec(J);
    End;

  Until I > J;

  If J > L then SortStrings(L, J);
  If I < R then SortStrings(I, R);

End;

Procedure SP_ListBox.SetUIElements;
Var
  w, h, i, t: Integer;
  ScrollBarsDone: Boolean;
Begin

  If (Width = 0) or (Height = 0) Then Begin
    fNeedPaint := True;
    Exit;
  End;

  w := fWidth - (4 * Ord(fBorder)) - 2;
  h := fHeight - (4 * Ord(fBorder)) - 2;

  If Length(fHeaders) > 0 Then Begin

    t := 0;
    For i := 0 To Length(fHeaders) -1 Do
      Inc(t, fHeaders[i].Width);

    If fShowHeaders Then
      Dec(h, iFH);

  End Else Begin

    t := 0;
    For i := 0 To Length(fStrings) -1 Do
      t := Max(t, Length(fStrings[i]));
    t := t * iFW;

  End;

  fHScroll.Visible := False;
  fHScroll.Max := t;
  fHScroll.Step := iFW;

  fVScroll.Visible := False;
  fVScroll.Max := fCount * iFH;
  fVScroll.Step := iFH;

  ScrollBarsDone := False;
  While Not ScrollBarsDone Do Begin

    If h < (fCount * iFH) Then Begin
      fVScroll.SetBounds(Width - FONTWIDTH - (Ord(fBorder) * 2), Ord(fBorder) * 2, FONTWIDTH, h + (iFH * Ord(fShowHeaders)) + (FONTHEIGHT * Ord(fHScroll.Visible)));
      fVScroll.Visible := True;
      Dec(w, FONTWIDTH + 2);
      ScrollBarsDone := True;
    End;

    ScrollBarsDone := fHScroll.Visible;
    If w < t Then Begin
      fHScroll.SetBounds(Ord(fBorder) * 2, fHeight - FONTHEIGHT - (Ord(fBorder) * 2), w + (Ord(fBorder) * 2) + (Ord(fVScroll.Visible) * (FONTWIDTH + 2)), FONTHEIGHT);
      fHScroll.Visible := True;
      Dec(h, FONTHEIGHT);
      fVScroll.SetBounds(Width - FONTWIDTH - (Ord(fBorder) * 2), Ord(fBorder) * 2, FONTWIDTH, h + (iFH * Ord(fShowHeaders)) + (FONTHEIGHT * Ord(fHScroll.Visible)));
    End Else
      ScrollBarsDone := True;

  End;

  fHScroll.PageSize := w;
  fVScroll.PageSize := h;
  If fHScroll.Visible Then
    fClientRgn := Rect(Ord(fBorder) * 2, Ord(fBorder) * 2, w, fHScroll.Top)
  Else Begin
    fClientRgn := Rect(Ord(fBorder) * 2, Ord(fBorder) * 2, w, fHeight - (Ord(fBorder) * 2));
  End;

  Paint;

End;

Procedure SP_ListBox.Draw;
Var
  c: Byte;
  r: TRect;
  yp, i, j, py, hx, ps, sx1, sx2: Integer;
  s, s2, pr: aString;
Begin

  If fVScroll.Visible Then
    yp := fVScroll.Pos
  Else
    yp := 0;

  i := yp Div iFH;
  py := (i * iFH - yp) + fClientRgn.Top;
  If fShowHeaders And (HeaderCount > 0) Then Inc(py, iFH);

  While (i < fCount) And (py - iFH < fClientRgn.Bottom) Do Begin

    // Draw items

    If fShowHeaders And (fHCount > 0) Then Begin

      ps := 1;
      hx := -fHScroll.Pos;
      s := fStrings[i] + #255;
      For j := 0 To fHCount -1 Do Begin
        ps := Pos(#255, s);
        If fSorted And (fSortedBy = j) And fCanUserSort Then Begin
          If fSelected[i] Then
            c := fHighlightClr
          Else
            c := fSortedColumnClr; // sorted column
          sx1 := hx -1; sx2 := hx + fHeaders[j].Width -1;
        End Else
          If fSelected[i] Then
            c := fHighlightClr
          Else
            c := fBackgroundClr; // non-sorted column
        If fSelected[i] Then
          If Not fFocused Then
            c := fUnfocusedHighlightClr;
        If j = fHCount -1 Then
          r := Rect(hx -1 + (Ord(fBorder) * 2), py + (Ord(fBorder) * 2), Width - 1, py + iFH -1 + (Ord(fBorder) * 2))
        Else
          r := Rect(hx -1 + (Ord(fBorder) * 2), py + (Ord(fBorder) * 2), hx + fHeaders[j].Width - 1 + (Ord(fBorder) * 2), py + iFH -1 + (Ord(fBorder) * 2));

        If not fTransparent Then
          FillRect(r, c);

        If fEnabled then
          c := fFontClr
        Else
          c := fDisabledFontClr;

        s2 := Copy(s, 1, ps-1);
        If Assigned(OnTextPrep) Then s2 := OnTextPrep(s2, j, i);
        Case fHeaders[j].Justify of
         -1: Print(hx + (Ord(fBorder) * 2), py + (Ord(fBorder) * 2), s2, c, -1, iSX, iSY, False, False);
          0: Print(hx + (Ord(fBorder) * 2) + (fHeaders[j].Width - (Length(s2)*iFW)) Div 2, py + (Ord(fBorder) * 2), s2, c, -1, iSX, iSY, False, False);
          1: Print(hx + (Ord(fBorder) * 2) + (fHeaders[j].Width - (Length(s2)*iFW)), py + (Ord(fBorder) * 2), s2, c, -1, iSX, iSY, False, False);
        End;
        If ps > 0 Then
          s := Copy(s, ps +1)
        Else
          s := '';
        Inc(hx, fHeaders[j].Width);
      End;

      If fSelected[i] Then Begin
        If fFocused Then
          c := SP_UISelectionOutline
        Else
          c := SP_UISelectionUnfocusedOutline;
        r.Left := Ord(fBorder) * 2;
        r.Right := (Width - (Ord(fBorder) * 4)) - (fVScroll.Width * Ord(fVScroll.Visible));
        DrawRect(r, c);
      End;

    End Else Begin

      If fSelected[i] and fEnabled Then
        FillRect(Ord(fBorder) * 2, py + (Ord(fBorder) * 2), fWidth, py + iFH -1 + (Ord(fBorder) * 2), fHighlightClr);
      s2 := fStrings[i];
      If Assigned(OnTextPrep) Then s2 := OnTextPrep(s2, 0, i);
      If fEnabled then
        c := fFontClr
      Else
        c := fDisabledFontClr;
      Print(-fHScroll.Pos + (Ord(fBorder) * 2), py + (Ord(fBorder) * 2), s2, c, -1, iSX, iSY, False, False);
      If fEnabled Then Begin
        If fFocused Then
          c := SP_UISelectionOutline
        Else
          c := SP_UISelectionUnfocusedOutline;
        r.Left := Ord(fBorder) * 2;
        r.Right := (Width - (Ord(fBorder) * 4)) - (fVScroll.Width * Ord(fVScroll.Visible));
        DrawRect(r, c);
      End;

    End;

    Inc(i);
    Inc(py, iFH);

  End;

  If fSorted And fCanUserSort and fEnabled and not fTransparent Then
    If py < fClientRgn.Bottom Then
      FillRect(sx1 + (Ord(fBorder) * 2), py + (Ord(fBorder) * 2), sx2 +1, fHeight, fSortedColumnClr);

  If fShowHeaders Then Begin

    hx := -fHScroll.Pos;
    For j := 0 To fHCount -1 Do Begin
      pr := '';
      If fSorted And (fSortedBy = j) And fCanUserSort Then Begin
        If fSortDir = 1 Then
          pr := #251
        Else
          pr := #252;
      End;
      If not fTransparent Then
        If j = fHCount -1 Then
          FillRect(hx + (Ord(fBorder) * 2), Ord(fBorder) * 2, Width + (Ord(fBorder) * 2), iFH -1 + (Ord(fBorder) * 2), fHeaderClr)
        Else
          FillRect(hx + (Ord(fBorder) * 2), Ord(fBorder) * 2, hx + fHeaders[j].Width -2 + (Ord(fBorder) * 2), iFH -1 + (Ord(fBorder) * 2), fHeaderClr);
      If fEnabled then
        c := fFontClr
      Else
        c := fDisabledFontClr;
      Print(hx + (Ord(fBorder) * 2), Ord(fBorder) * 2, fHeaders[j].Caption, c, -1, iSX, iSY, False, False);
      Print(hx + (Ord(fBorder) * 2) + ((Length(fHeaders[j].Caption) +1) * iFW), ((iFH - FONTHEIGHT) Div 2) + (Ord(fBorder) * 2), pr, fSortIndClr, -1, 1, 1, False, False);
      Inc(hx, fHeaders[j].Width);

    End;

  End;

  If not fTransparent Then Begin
    FillRect(fWidth - FONTWIDTH, fHeight - FONTHEIGHT, fWidth, fHeight, fBackgroundClr);
    If fHScroll.Visible Then
      FillRect(0, Height - (FONTHEIGHT + 2), Width, Height, fBackgroundClr);
    If fVScroll.Visible Then
      FillRect(Width - (FONTWIDTH +3), 0, Width, Height, fBackgroundClr);
  End;

  If fBorder Then Begin
    DrawRect(0, 0, Width -1, Height -1, fBorderClr);
    DrawRect(1, 1, Width -2, Height -2, fBackgroundClr);
  End;

End;

Procedure SP_ListBox.vScroll(Delta, NewPos: Integer);
Begin

  Paint;

End;

Procedure SP_ListBox.hScroll(Delta, NewPos: Integer);
Begin

  Paint;

End;

Procedure SP_ListBox.MouseWheel(X, Y, Btn, Delta: Integer);
Begin

  Inherited;

  If fVScroll.Visible Then
    fVScroll.Pos := fVScroll.TargetPos + (Delta * fVScroll.WheelStep);

End;

Procedure SP_ListBox.MouseMove(X, Y, Btn: Integer);
begin

  Inherited;

  If fMouseMode = mmHeaderDrag Then Begin
    Inc(fHeaders[fHeaderGrab].Width, X - fLastMouseX);
    If fHeaders[fHeaderGrab].Width >= BSize Then Begin
      fLastMouseX := X;
      SetUIElements;
    End Else
      fHeaders[fHeaderGrab].Width := BSize;
  End;

end;

Procedure SP_ListBox.MouseUp(X, Y, Btn: Integer);
Begin

  Inherited;

  If fMouseMode = mmHeaderDrag Then
    fMouseMode := mmNone;

End;

Procedure SP_ListBox.MouseDown(X, Y, Btn: Integer);
Var
  i, j, oj: Integer;
Begin

  Inherited;

  if fEnabled And not Dbl then Begin

    Dec(Y, 2);
    If fBorder Then Begin
      Dec(X, 2);
      Dec(Y, 2);
    End;

    If Btn = 1 Then Begin

      If fShowHeaders And (fHCount > 0) Then Begin

        Inc(X, fHScroll.Pos);
        If Y < iFH then Begin
          i := 0; oj := 0;
          j := fHeaders[i].Width;
          While X >= j Do Begin
            Inc(i);
            oj := j;
            Inc(j, fHeaders[i].Width);
          End;

          If (x < oj + BSize) and (i > 0) Then Begin // Grabbed a header separator
            fMouseMode := mmHeaderDrag;
            fHeaderGrab := i - 1;
            fLastMouseX := X;
            Exit;
          End Else
            If x > j - BSize Then Begin
              fMouseMode := mmHeaderDrag;
              fHeaderGrab := i;
              fLastMouseX := X;
              Exit;
            End;

          If fCanUserSort Then Begin
            if fSortedBy = i Then
              fSortDir := 1 - fSortDir
            Else
              fSortedBy := i;
            Sort(fSortedBy);
            SP_PlaySystem(CLICKCHAN, CLICKBANK);
            ScrollInView;
            Exit;
          End;

        End;

      End;

      i := ((fVScroll.Pos + Y) Div iFH) - Ord(fShowHeaders And (fHCount > 0));

      If (i >= 0) And (i < fCount) Then Begin

        If fMultiSelect Then Begin

          If (KEYSTATE[K_CONTROL] = 1) Then Begin

            fSelected[i] := Not fSelected[i];
            If fSelected[i] Then
              fLastSelected := i;

          End Else

            If KEYSTATE[K_SHIFT] = 1 Then Begin

              For j := 0 To fCount -1 Do fSelected[j] := False;
              For j := Min(fLastSelected, i) To Max(fLastSelected, i) Do
                fSelected[j] := True;

            End Else Begin

              For j := 0 To fCount -1 Do
                fSelected[j] := False;

              fSelected[i] := True;
              fSelectedIdx := i;
              fLastSelected := i;

            End;

        End Else Begin

          If fSelectedIdx <> -1 Then
            fSelected[fSelectedIdx] := False;

          fSelected[i] := True;
          fSelectedIdx := i;
          fLastSelected := i;

        End;

        fSelCount := 0;
        For i := 0 To Length(fSelected) -1 Do
          If fSelected[i] Then
            Inc(fSelCount);

        fSelectAnchor := i;
        ScrollInView;

        Select(fLastSelected);
        SP_PlaySystem(CLICKCHAN, CLICKBANK);

      End Else Begin

        // Clicked outside the list bounds, so select none and fire an OnSelect event

        SP_PlaySystem(CLICKCHAN, CLICKBANK);
        fSelectedIdx := -1;
        For i := 0 to Length(fSelected) -1 Do
          fSelected[i] := False;
        fLastSelected := -1;
        fSelectAnchor := -1;
        fSelCount := 0;

        fSelCount := 0;
        For i := 0 To Length(fSelected) -1 Do
          If fSelected[i] Then
            Inc(fSelCount);

        Select(-1);
        Paint;

      End;

    End;

  End;

End;

Procedure SP_ListBox.Select(Index: Integer);
Begin

  If Assigned(OnSelect) Then OnSelect(Self, Index);

End;

Procedure SP_ListBox.PerformKeyDown(Var Handled: Boolean);
Var
  i, j, k: Integer;
  NewChar: Byte;
Begin

  NewChar := DecodeKey(cLastKey);
  Handled := False;

  If (NewChar = 0) {$IFNDEF FPC} And (cLastKeyChar <> 1) {$ENDIF} Then Begin

    Case cLastKey of

      K_UP, K_DOWN, K_PRIOR, K_NEXT, K_HOME, K_END:
        Begin
          if fEnabled then Begin
            Case cLastKey Of
              K_UP: i := -1;
              K_DOWN: i := 1;
              K_PRIOR: i := -(fVScroll.PageSize Div iFH);
              K_NEXT: i := fVScroll.PageSize Div iFH;
              K_HOME: i := -fLastSelected;
              K_END: i := fCount;
            End;
            If Not fSelected[fLastSelected] Then i := 0;
            For j := 0 To fCount -1 Do fSelected[j] := False;
            k := fSelectAnchor;
            fLastSelected := Max(Min(fLastSelected + i, fCount -1), 0);
            If fMultiSelect and (KEYSTATE[K_SHIFT] = 1) Then Begin
              For j := Min(k, fLastSelected) To Max(k, fLastSelected) Do
                fSelected[j] := True;
            End Else Begin
              fSelected[fLastSelected] := True;
              fSelectAnchor := fLastSelected;
            End;
            fSelectedIdx := fLastSelected;
            SP_PlaySystem(CLICKCHAN, CLICKBANK);
            ScrollInView;
            Select(fLastSelected);
            Handled := True;
          End;
        End;

      K_RETURN:
        Begin
          if fEnabled then Begin
            fChosen := True;
            Handled := True;
          End;
        End;

    Else
      Inherited;
    End;

  End;

End;

Procedure SP_ListBox.PerformKeyUp(Var Handled: Boolean);
Var
  i: Integer;
Begin

  Case cLastKey Of

    K_RETURN:
      Begin
        If fChosen Then Begin
          If Assigned(OnChoose) Then
            OnChoose(Self, fLastSelected, Copy(fStrings[i], 1, Pos(#255, fStrings[i]) -1));
          Handled := True;
        End;
      End;

  End;

End;

Procedure SP_ListBox.ScrollInView;
Begin

  fVScroll.ScrollInView(fLastSelected * iFH);
  Paint;

End;

Procedure SP_ListBox.DoubleClick(X, Y, Btn: Integer);
Begin

  If (Y < iFH) And fShowHeaders Then Exit;
  If Assigned(OnDblClick) and (fLastSelected <> -1) Then
    OnDblClick(X, Y, Btn)
  Else
    If Assigned(OnChoose) and (fLastSelected <> -1) Then
      OnChoose(Self, fLastSelected, Copy(fStrings[fLastSelected], 1, Pos(#255, fStrings[fLastSelected]) -1));

End;

end.
