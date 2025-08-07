unit SP_ListBoxUnit;

{$INCLUDE SpecBAS.inc}

interface

Uses Types, SP_Util, SP_Errors, SP_BaseComponentUnit, SP_ScrollBarUnit;

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

    fStrings:       Array of aString;
    fObjects:       Array of TObject;
    fHeaders:       Array of SP_ListBoxHeader;
    fSelected:      Array of Boolean;
    fCount:         Integer;
    fHCount:        Integer;
    fSelCount:      Integer;
    fHScroll,
    fVScroll:       SP_ScrollBar;
    fClientRgn:     TRect;
    fMultiSelect:   Boolean;
    fSelectedIdx:   Integer;
    fShowHeaders:   Boolean;
    fSorted:        Boolean;
    fSortedBy:      Integer;
    fSortDir:       Integer;
    fCanUserSort:   Boolean;
    fChosen:        Boolean;
    fSortByAlpha:   Boolean;
    fLastSelected:  Integer;
    fSortProc:      SP_SortEvent;
    fTextPrep:      SP_TextPrepare;
    fOnSelect:      SP_LBSelectEvent;
    fOnChoose:      SP_LBChooseEvent;
    fSelectAnchor:  Integer;
    fSortIndClr,
    fSortedColumnClr,
    fHeaderClr:     Integer;
    fMouseMode:     Integer;
    fHeaderGrab:    Integer;
    fLastMouseX:    Integer;
    fAllowLiterals: Boolean;
    fNeedScroll:    Integer;

    Compiled_OnChoose,
    User_OnChoose,
    Compiled_OnSelect,
    User_OnSelect: aString;

    Procedure     Clear;
    Procedure     ClearSelected;
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
    Procedure     vScroll(Delta, NewPos: aFloat);
    Procedure     hScroll(Delta, NewPos: aFloat);
    Procedure     SetShowHeaders(b: Boolean);
    Procedure     SortStrings(L, R: Integer);
    Function      GetString(Index: Integer): aString; Virtual;
    Function      GetOnDblClick: SP_MouseEvent;
    Procedure     SetOnDblClick(Event: SP_MouseEvent);
    Procedure     Select(Index: Integer); Virtual;
    Procedure     PerformKeyDown(Var Handled: Boolean); Override;
    Procedure     PerformKeyUp(Var Handled: Boolean); Override;
    Procedure     SetBackgroundClr(c: Byte); Override;
    Procedure     ScrollInView(OnlyObscured: Boolean);
    Procedure     Draw; Override;
    Function      GetHeaderCount: Integer;
    Procedure     SetHeaderClr(c: Integer);
    Procedure     SetSortIndClr(c: Integer);
    Procedure     SetSortedColumnClr(c: Integer);
    Procedure     HasSized; Override;
    Procedure     MoveItem(Item1, Item2: Integer);

    Procedure     MouseWheel(Sender: SP_BaseComponent; X, Y, Btn, Delta: Integer); Override;
    Procedure     MouseDown(Sender: SP_BaseComponent; X, Y, Btn: Integer); Override;
    Procedure     MouseMove(Sender: SP_BaseComponent; X, Y, Btn: Integer); Override;
    Procedure     MouseUp(Sender: SP_BaseComponent; X, Y, Btn: Integer); Override;
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
    Property      AllowLiterals:             Boolean          read fAllowLiterals   write fAllowLiterals;

    Constructor   Create(Owner: SP_BaseComponent);
    Destructor    Destroy; Override;

    // User Properties

    Procedure RegisterProperties; Override;
    Procedure Set_Item(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Item: aString;
    Procedure Set_Column(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Column: aString;
    Function  Get_ColCount: aString; Function  Get_Count: aString; Function  Get_SelIndex: aString;
    Procedure Set_ColColor(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_ColColor: aString;
    Procedure Set_ColWidth(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_ColWidth: aString;
    Procedure Set_ColJustify(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_ColJustify: aString;
    Procedure Set_Selected(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Selected: aString;
    Procedure Set_MultiSel(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_MultiSel: aString;
    Procedure Set_Sorted(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Sorted: aString;
    Procedure Set_SortCol(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_SortCol: aString;
    Procedure Set_SortColor(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_SortColor: aString;
    Procedure Set_SortDir(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_SortDir: aString;
    Procedure Set_OnSelect(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_OnSelect: aString;
    Procedure Set_OnChoose(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_OnChoose: aString;
    Procedure Set_ShowCols(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_ShowCols: aString;
    Function  Get_IndexOf: aString;

    Procedure RegisterMethods; Override;
    Procedure Method_ClearSelected(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Clear(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Move(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Add(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Insert(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Delete(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_AddCol(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_InsertCol(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_DeleteCol(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Sort(Params: Array of aString; Var Error: TSP_ErrorCode);

End;

Const

  mmNone = 0;
  mmHeaderDrag = 1;

implementation

Uses Math, SP_Components, SP_SysVars, SP_Input, SP_Sound, SP_Interpret_PostFix;

// SP_ListBox

Constructor SP_ListBox.Create(Owner: SP_BaseComponent);
Var
  cfW, cFH: Integer;
Begin

  Inherited;

  cfW := Round(iFW * iSX);
  cfH := Round(iFH * iSY);

  fTypeName := 'spList';

  fCount := 0;

  fHScroll := SP_ScrollBar.Create(Self);
  fHScroll.Border := False;
  fHScroll.Kind := spHorizontal;
  fHScroll.OnScroll := hScroll;
  fHScroll.WheelStep := SP_ScrollWheelValue * cFW;

  fVScroll := SP_ScrollBar.Create(Self);
  fVScroll.Border := False;
  fVScroll.Kind := spVertical;
  fVScroll.OnScroll := vScroll;
  fVScroll.WheelStep := SP_ScrollWheelValue * cFH;

  fTransparent := False;
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
  Paint;

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
  If fLockCount = 0 Then Begin
    If fNeedPaint Then
      SetUIElements;
    If fNeedScroll <> -1 Then
      fVScroll.ScrollInView(fNeedScroll);
  End;

End;

Procedure SP_ListBox.Clear;
Begin

  SetLength(fStrings, 0);
  SetLength(fObjects, 0);
  SetLength(fSelected, 0);
  SetLength(fHeaders, 0);
  fHCount := 0;
  fCount := 0;
  fSelectedIdx := -1;
  SetUIElements;

End;

Procedure SP_ListBox.ClearSelected;
Var
  i: Integer;
Begin

  For i := 0 To Count -1 Do
    fSelected[i] := False;
  If Assigned(fOnSelect) Then
    fOnSelect(Self, -1);
  If Not Locked And (Compiled_OnSelect <> '') Then
    SP_AddOnEvent(Compiled_OnSelect);

End;

Procedure SP_ListBox.MoveItem(Item1, Item2: Integer);
Begin

  Insert(item2, fStrings[Item1]);
  If Item1 > Item2 Then Inc(Item1);
  Delete(Item1);

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
        15, 16, 17, 18, 19, 20, 23, 24, 26, 27:
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

Procedure SP_ListBox.HasSized;
Begin
  SetUIElements;
End;

Procedure SP_ListBox.SetUIElements;
Var
  w, h, rh, i, t, cFW, cFH: Integer;
  ScrollBarsDone: Boolean;
Begin

  If (Width = 0) or (Height = 0) Then Begin
    fNeedPaint := True;
    Exit;
  End;

  cfW := Round(iFW * iSX);
  cfH := Round(iFH * iSY);

  w := fWidth - (4 * Ord(fBorder)) - 2;
  rh := fClientRgn.Bottom - fClientRgn.Top;
  h := rh - (Ord(fShowHeaders And (Length(fHeaders) > 0)) * cFH);

  If fShowHeaders And (Length(fHeaders) > 0) Then Begin

    t := 0;
    For i := 0 To Length(fHeaders) -1 Do
      Inc(t, fHeaders[i].Width);

  End Else Begin

    t := 0;
    For i := 0 To Length(fStrings) -1 Do
      t := Max(t, Length(fStrings[i]));
    t := t * cFW;

  End;

  fHScroll.Visible := False;
  fHScroll.Max := t;
  fHScroll.Step := cFW;

  fVScroll.Visible := False;
  fVScroll.Max := fCount * cFH;
  fVScroll.Step := cFH;

  ScrollBarsDone := False;
  While Not ScrollBarsDone Do Begin

    If h < fCount * cFH Then Begin
      fVScroll.SetBounds(Width - cfW - (Ord(fBorder) * 2), Ord(fBorder) * 2, cfW, rh + (cfH * Ord(fHScroll.Visible)));
      fVScroll.Visible := True;
      Dec(w, cfW + 2);
    End;

    ScrollBarsDone := fHScroll.Visible;
    If w < t Then Begin
      fHScroll.SetBounds(Ord(fBorder) * 2, fHeight - cfH - (Ord(fBorder) * 2), w + (Ord(fBorder) * 2) + (Ord(fVScroll.Visible) * (cfW + 2)), cfH);
      fHScroll.Visible := True;
      Dec(h, cFh);
      fVScroll.SetBounds(Width - cfW - (Ord(fBorder) * 2), Ord(fBorder) * 2, cfW, rh + (cfH * Ord(fHScroll.Visible)));
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
  c1, c2, c3: Byte;
  r: TRect;
  yp, i, j, py, hx, ps, sx1, sx2, cfW, cfH: Integer;
  s, s2, pr: aString;

  Procedure DrawSelectionRect;
  Begin
    If Focused Then
      c3 := SP_UISelectionOutline
    Else
      c3 := SP_UISelectionUnfocusedOutline;
    r.Left := Ord(fBorder) * 2;
    r.Right := (Width - (Ord(fBorder) * 4)) - ((fVScroll.Width + 1) * Ord(fVScroll.Visible)) + 1;
    DrawLine(r.left, r.top, r.left, r.bottom, c3);
    DrawLine(r.Right, r.top, r.right, r.bottom, c3);
    If (i = 0) or not fSelected[i -1] Then
      DrawLine(r.left, r.top, r.right, r.top, c3);
    If (i = Count -1) or not fSelected[i +1] Then
      DrawLine(r.Left, r.bottom, r.right, r.bottom, c3);
  End;

Begin

  sx2 := 0; sx1 := 0;
  If fVScroll.Visible Then
    yp := fVScroll.Pos
  Else
    yp := 0;

  cfW := Round(iFW * iSX);
  cfH := Round(iFH * iSY);

  i := yp Div cfH;
  py := (i * cfH - yp) + fClientRgn.Top + Ord(fShowHeaders And (HeaderCount > 0));
  If fShowHeaders And (HeaderCount > 0) Then Inc(py, cfH);
  If not fTransparent Then FillRect(Rect(0, 0, Width, Height), fBackgroundClr);

  While (i < fCount) And (py - cFH < fClientRgn.Bottom) Do Begin

    // Draw items

    If fShowHeaders And (fHCount > 0) Then Begin

      hx := -fHScroll.Pos;
      s := fStrings[i] + #255;
      For j := 0 To fHCount -1 Do Begin
        ps := Pos(#255, s);
        If fSorted And (fSortedBy = j) And fCanUserSort Then Begin
          If fSelected[i] Then
            c1 := fHighlightClr
          Else
            c1 := fSortedColumnClr; // sorted column
          sx1 := hx -1; sx2 := hx + fHeaders[j].Width -1;
        End Else
          If fSelected[i] Then
            c1 := fHighlightClr
          Else
            c1 := fBackgroundClr; // non-sorted column
        If fSelected[i] Then
          If Not Focused Then
            c1 := fUnfocusedHighlightClr;
        If j = fHCount -1 Then
          r := Rect(hx -1 + fClientRgn.Left, py, Width - 1, py + cFH -1)
        Else
          r := Rect(hx -1 + fClientRgn.Left, py, hx + fHeaders[j].Width - 1 + fClientRgn.Left, py + cFH -1);

        If not fTransparent Then
          FillRect(r, c1);

        If fEnabled then
          c1 := fFontClr
        Else
          c1 := fDisabledFontClr;

        SP_ReplaceAll(Copy(s, 1, ps-1), '\$FF', #255, s2);
        If Assigned(OnTextPrep) Then s2 := OnTextPrep(s2, j, i);
        Case fHeaders[j].Justify of
         -1: Print(hx + fClientRgn.Left, py, s2, c1, -1, iSX, iSY, False, False, False, False);
          0: Print(hx + fClientRgn.Left + (fHeaders[j].Width - (Length(s2)*cFW)) Div 2, py, s2, c1, -1, iSX, iSY, False, False, False, False);
          1: Print(hx + fClientRgn.Left + (fHeaders[j].Width - (Length(s2)*cFW)), py, s2, c1, -1, iSX, iSY, False, False, False, False);
        End;
        If ps > 0 Then
          s := Copy(s, ps +1)
        Else
          s := '';
        Inc(hx, fHeaders[j].Width);
      End;

      If fSelected[i] Then
        DrawSelectionRect;

    End Else Begin

      If fSelected[i] And fEnabled Then
        c1 := fHighlightClr
      Else
        c1 := fBackgroundClr;
      s2 := fStrings[i];
      If Assigned(OnTextPrep) Then s2 := OnTextPrep(s2, 0, i);
      If fEnabled then
        c2 := fFontClr
      Else
        c2 := fDisabledFontClr;

      r := Rect(-fHScroll.Pos -1 + (Ord(fBorder) * 2), py, fWidth +1, py + cFH -1);
      If (Not fTransparent) or (fSelected[i]) Then
        FillRect(r, c1);
      Print(-fHScroll.Pos + (Ord(fBorder) * 2), py, s2, c2, -1, iSX, iSY, False, False, False, False);
      If fSelected[i] Then
        DrawSelectionRect;

    End;

    Inc(i);
    Inc(py, cFH);

  End;

  If fSorted And fCanUserSort and fEnabled and not fTransparent Then
    If py < fClientRgn.Bottom Then
      If fSortedBy = fHCount -1 Then
        FillRect(sx1 + (Ord(fBorder) * 2), py, Width -1, fHeight, fSortedColumnClr)
      Else
        FillRect(sx1 + (Ord(fBorder) * 2), py, sx2 +1, fHeight, fSortedColumnClr);

  If fShowHeaders And (HeaderCount > 0) Then Begin

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
          FillRect(hx + (Ord(fBorder) * 2), Ord(fBorder) * 2, Width + (Ord(fBorder) * 2), cFH -1 + (Ord(fBorder) * 2), fHeaderClr)
        Else
          FillRect(hx + (Ord(fBorder) * 2), Ord(fBorder) * 2, hx + fHeaders[j].Width -2 + (Ord(fBorder) * 2), cFH -1 + (Ord(fBorder) * 2), fHeaderClr);
      If fEnabled then
        c1 := fFontClr
      Else
        c1 := fDisabledFontClr;
      Print(hx + (Ord(fBorder) * 2), Ord(fBorder) * 2, fHeaders[j].Caption, c1, -1, iSX, iSY, False, False, False, False);
      Print(hx + (Ord(fBorder) * 2) + ((Length(fHeaders[j].Caption) +1) * cFW), ((cFH - fH) Div 2) + (Ord(fBorder) * 2), pr, fSortIndClr, -1, 1, 1, False, False, False, False);
      Inc(hx, fHeaders[j].Width);

    End;

  End;

  If not fTransparent Then Begin
    FillRect(fWidth - cfW, fHeight - cfH, fWidth, fHeight, fBackgroundClr);
    If fHScroll.Visible Then
      FillRect(0, Height - (cfH + 2), Width, Height, fBackgroundClr);
    If fVScroll.Visible Then
      FillRect(Width - (cfW +3), 0, Width, Height, fBackgroundClr);
  End;

  If fBorder Then Begin
    DrawRect(0, 0, Width -1, Height -1, fBorderClr);
    DrawRect(1, 1, Width -2, Height -2, fBackgroundClr);
  End;

End;

Procedure SP_ListBox.vScroll(Delta, NewPos: aFloat);
Begin

  Paint;

End;

Procedure SP_ListBox.hScroll(Delta, NewPos: aFloat);
Begin

  Paint;

End;

Procedure SP_ListBox.MouseWheel(Sender: SP_BaseComponent; X, Y, Btn, Delta: Integer);
Begin

  Inherited;

  If fVScroll.Visible Then
    fVScroll.Pos := fVScroll.TargetPos + (Delta * fVScroll.WheelStep);

End;

Procedure SP_ListBox.MouseMove(Sender: SP_BaseComponent; X, Y, Btn: Integer);
begin

  Inherited;

  If fMouseMode = mmHeaderDrag Then Begin
    Inc(X, fHScroll.Pos);
    Inc(fHeaders[fHeaderGrab].Width, X - fLastMouseX);
    If fHeaders[fHeaderGrab].Width >= BSize Then Begin
      fLastMouseX := X;
      SetUIElements;
    End Else
      fHeaders[fHeaderGrab].Width := BSize;
  End;

end;

Procedure SP_ListBox.MouseUp(Sender: SP_BaseComponent; X, Y, Btn: Integer);
Begin

  Inherited;

  If fMouseMode = mmHeaderDrag Then
    fMouseMode := mmNone;

End;

Procedure SP_ListBox.MouseDown(Sender: SP_BaseComponent; X, Y, Btn: Integer);
Var
  i, j, oj, cFH: Integer;
Begin

  Inherited;

  cfH := Round(iFH * iSY);

  if fEnabled then Begin

    Dec(Y, 2);
    If fBorder Then Begin
      Dec(X, 2);
      Dec(Y, 2);
    End;

    If Btn = 1 Then Begin

      If fShowHeaders And (fHCount > 0) Then Begin

        Inc(X, fHScroll.Pos);
        If Y < cFH then Begin
          i := 0; oj := 0;
          j := fHeaders[i].Width;
          While (X >= j) And (i < Length(fHeaders) -1) Do Begin
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
            ScrollInView(True);
            Exit;
          End;

        End;

      End;

      i := ((fVScroll.Pos + Y) Div cFH) - Ord(fShowHeaders And (fHCount > 0));

      If (i >= 0) And (i < fCount) Then Begin

        If fMultiSelect Then Begin

          If (cKEYSTATE[K_CONTROL] = 1) Then Begin

            fSelected[i] := Not fSelected[i];
            If fSelected[i] Then
              fLastSelected := i;

          End Else

            If cKEYSTATE[K_SHIFT] = 1 Then Begin

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
        ScrollInView(True);

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
  If Not Locked And (Compiled_OnSelect <> '') Then
    SP_AddOnEvent(Compiled_OnSelect);

End;

Procedure SP_ListBox.PerformKeyDown(Var Handled: Boolean);
Var
  i, j, k, cFH: Integer;
  NewChar: Byte;
Begin

  If not (fEnabled and fFocused) Then Exit;

  cfH := Round(iFH * iSY);

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
              K_PRIOR: i := -(fVScroll.PageSize Div cFH);
              K_NEXT: i := fVScroll.PageSize Div cFH;
              K_HOME: i := -fLastSelected;
              K_END: i := fCount;
            Else
              i := fSelectedIdx;
            End;
            If Not fSelected[fLastSelected] Then i := 0;
            For j := 0 To fCount -1 Do fSelected[j] := False;
            k := fSelectAnchor;
            fLastSelected := Max(Min(fLastSelected + i, fCount -1), 0);
            If fMultiSelect and (cKEYSTATE[K_SHIFT] = 1) Then Begin
              For j := Min(k, fLastSelected) To Max(k, fLastSelected) Do
                fSelected[j] := True;
            End Else Begin
              fSelected[fLastSelected] := True;
              fSelectAnchor := fLastSelected;
            End;
            fSelectedIdx := fLastSelected;
            SP_PlaySystem(CLICKCHAN, CLICKBANK);
            ScrollInView(False);
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
          If Assigned(OnChoose) Then Begin
            i := fSelectedIdx;
            OnChoose(Self, fLastSelected, Copy(fStrings[i], 1, Pos(#255, fStrings[i]) -1));
            If Not Locked And (Compiled_OnChoose <> '') Then
              SP_AddOnEvent(Compiled_OnChoose);
          End;
          Handled := True;
        End;
      End;

  End;

End;

Procedure SP_ListBox.ScrollInView(OnlyObscured: Boolean);
Var
  p: Integer;
  CanScroll: Boolean;
Begin

  fNeedScroll := -1;
  CanScroll := True;
  p := fLastSelected * Round(iFH * iSY);

  If OnlyObscured Then
    CanScroll := (p < fVScroll.Pos) or (p > fVScroll.Pos + fVScroll.PageSize - iFH);

  If CanScroll Then
    If Not Locked Then Begin
      fVScroll.ScrollInView(p, OnlyObscured);
    End Else
      fNeedScroll := p;
  Paint;

End;

Procedure SP_ListBox.DoubleClick(X, Y, Btn: Integer);
Begin

  If (Y < Round(iFH * iSY)) And fShowHeaders Then Exit;
  If Assigned(OnDblClick) and (fLastSelected <> -1) Then
    OnDblClick(Self, X, Y, Btn)
  Else Begin
    If Assigned(OnChoose) and (fLastSelected <> -1) Then
      OnChoose(Self, fLastSelected, Copy(fStrings[fLastSelected], 1, Pos(#255, fStrings[fLastSelected]) -1));
    If Not Locked And (Compiled_OnChoose <> '') Then
      SP_AddOnEvent(Compiled_OnChoose);
  End;

End;

// User Stuff

Procedure SP_ListBox.RegisterProperties;
Begin

  Inherited;

  RegisterProperty('item', Get_Item, Set_Item, 'v:s|v:s');
  RegisterProperty('count', Get_Count, nil, ':v');
  RegisterProperty('column', Get_Column, Set_Column, 'v:s|v:s[,v,v]');
  RegisterProperty('colcount', Get_Count, nil, ':v');
  RegisterProperty('colclr', Get_ColColor, Set_ColColor, 'v:v|v:v');
  RegisterProperty('colwidth', Get_ColWidth, Set_ColWidth, 'v:v|v:v');
  RegisterProperty('coljustify', Get_ColWidth, Set_ColJustify, 'v:v|v:v');
  RegisterProperty('selidx', Get_SelIndex, nil, ':v');
  RegisterProperty('selected', Get_Selected, Set_Selected, 'v:v|v:v');
  RegisterProperty('multisel', Get_MultiSel, Set_MultiSel, ':v|v');
  RegisterProperty('sorted', Get_Sorted, Set_Sorted, ':v|v');
  RegisterProperty('showcols', Get_ShowCols, Set_ShowCols, ':v|v');
  RegisterProperty('sortcol', Get_SortCol, Set_SortCol, ':v|v');
  RegisterProperty('sortclr', Get_SortColor, Set_SortColor, ':v|v');
  RegisterProperty('sortdir', Get_SortDir, Set_SortDir, ':v|v');
  RegisterProperty('onselect', Get_OnSelect, Set_OnSelect, ':s|s');
  RegisterProperty('onchoose', Get_OnChoose, Set_OnChoose, ':s|s');
  RegisterProperty('find', Get_IndexOf, nil, 's:v');

End;

Procedure SP_ListBox.Set_Item(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, p: Integer;
Begin

  p := Pos(':', s);
  If p >= 0 Then Begin
    Idx := StringToInt(Copy(s, 1, p -1)) -1;
    s := Copy(s, p +1);
    If (Idx >= 0) And (Idx < Count) Then
      SP_ReplaceAll(s, '|', #255, fStrings[Idx]);
    Paint;
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function SP_ListBox.Get_Item: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < Count) Then
    SP_ReplaceAll(fStrings[Idx], #255, '|', Result);

End;

Procedure SP_ListBox.Set_Column(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, cp, p: Integer;
  cap, s2, s3: aString;
Begin

  p := Pos(':', s);
  If p >= 0 Then Begin
    Idx := StringToInt(Copy(s, 1, p -1)) -1;
    s := Copy(s, p +1);

    If (Idx >= 0) And (Idx < fHCount) Then Begin
      cp := Pos(',', s);
      If cp > 0 Then Begin
        cap := Copy(s, 1, cp -1);
        s2 := Copy(s, cp +1);
        cp := Pos(',', s2);
        If cp > 0 Then Begin
          s3 := Copy(s2, cp +1);
          s2 := Copy(s2, 1, cp -1);
          fHeaders[Idx].Justify := StringToInt(s3, fHeaders[Idx].Justify);
        End;
        fHeaders[Idx].Width := StringToInt(s2, fHeaders[Idx].Width);
      End Else
        cap := s;
      fHeaders[Idx].Caption := Cap;
    End;
    Paint;
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function SP_ListBox.Get_Column: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < fHCount) Then
    Result := fHeaders[Idx].Caption;

End;

Function SP_ListBox.Get_ColCount: aString;
Begin

  Result := IntToString(fHCount);

End;

Function SP_ListBox.Get_Count: aString;
Begin

  Result := IntToString(Count);

End;

Function SP_ListBox.Get_SelIndex: aString;
Begin

  Result := IntToString(fSelectedIdx);

End;

Procedure SP_ListBox.Set_ColColor(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  fHeaderClr := StringToInt(s, fHeaderClr);
  Paint;

End;

Function SP_ListBox.Get_ColColor: aString;
Begin

  Result := IntToString(fHeaderClr);

End;

Procedure SP_ListBox.Set_ColWidth(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, p: integer;
Begin

  p := Pos(':', s);
  If p >= 0 Then Begin
    Idx := StringToInt(Copy(s, 1, p -1)) -1;
    s := Copy(s, p +1);
    fHeaders[Idx].Width := StringToInt(s, fHeaders[Idx].Width);
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function SP_ListBox.Get_ColWidth: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < fHCount) Then
    Result := IntToString(fHeaders[Idx].Width);

End;

Procedure SP_ListBox.Set_ColJustify(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, p: integer;
Begin

  p := Pos(':', s);
  If p >= 0 Then Begin
    Idx := StringToInt(Copy(s, 1, p -1)) -1;
    s := Copy(s, p +1);
    fHeaders[Idx].Justify := StringToInt(s, fHeaders[Idx].Justify);
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function SP_ListBox.Get_ColJustify: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < fHCount) Then
    Result := IntToString(fHeaders[Idx].Justify);

End;

Procedure SP_ListBox.Set_Selected(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, p: integer;
  b: Boolean;
Begin

  p := Pos(':', s);
  If p >= 0 Then Begin
    Idx := StringToInt(Copy(s, 1, p -1)) -1;
    If (Idx >= 0) and (Idx < Count) Then Begin
      s := Copy(s, p +1);
      b := StringToInt(s, Ord(fSelected[Idx])) <> 0;
      fSelected[Idx] := b;
      If b Then Begin
        fSelectedIdx := Idx;
        fLastSelected := Idx;
        ScrollInView(False);
        Paint;
      End;
    End Else
      Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function SP_ListBox.Get_Selected: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam, -1) -1;
  If (Idx >= 0) And (Idx < Count) Then
    Result := IntToString(Ord(fSelected[Idx]));

End;

Procedure SP_ListBox.Set_MultiSel(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  fMultiSelect := StringToInt(s, 0) <> 0;

End;

Function SP_ListBox.Get_MultiSel: aString;
Begin

  Result := IntToString(Ord(fMultiSelect));

End;

Procedure SP_ListBox.Set_Sorted(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  fSorted := StringToInt(s, 0) <> 0;

End;

Function SP_ListBox.Get_Sorted: aString;
Begin

  Result := IntToString(Ord(fSorted));

End;

Procedure SP_ListBox.Set_ShowCols(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  SetShowHeaders(StringToInt(s, 0) <> 0);

End;

Function SP_ListBox.Get_ShowCols: aString;
Begin

  Result := IntToString(Ord(fShowHeaders));

End;

Procedure SP_ListBox.Set_SortCol(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  fSortedBy := StringToInt(s, 0) -1;

End;

Function SP_ListBox.Get_SortCol : aString;
Begin

  Result := IntToString(fSortedBy +1);

End;

Procedure SP_ListBox.Set_SortColor(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Clr: Integer;
Begin

  Clr := StringToInt(s, SortedColumnClr);
  SortedColumnClr := Clr;

End;

Function SP_ListBox.Get_SortColor: aString;
Begin

  Result := IntToString(SortedColumnClr);

End;

Procedure SP_ListBox.Set_SortDir(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  fSortDir := StringToInt(s, fSortDir);
  If fSorted Then
    Sort(fSortedBy);

End;

Function SP_ListBox.Get_SortDir: aString;
Begin

  Result := IntToString(fSortDir);

End;

Procedure SP_ListBox.Set_OnSelect(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Compiled_OnSelect := SP_ConvertToTokens(s, Error);
  If Compiled_OnSelect <> '' Then
    User_OnSelect := s;

End;

Function SP_ListBox.Get_OnSelect: aString;
Begin

  Result := User_OnSelect;

End;

Procedure SP_ListBox.Set_OnChoose(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Compiled_OnChoose := SP_ConvertToTokens(s, Error);
  If Compiled_OnChoose <> '' Then
    User_OnChoose := s;

End;

Function SP_ListBox.Get_OnChoose: aString;
Begin

  Result := User_OnChoose;

End;

Function SP_ListBox.Get_IndexOf: aString;
Var
  Idx: integer;
Begin

  Idx := 0;
  Result := '-1';
  While Idx < Count Do
    If Items[Idx] = fUserParam Then Begin
      Result := IntToString(Idx +1);
      Exit;
    End Else
      Inc(Idx);

End;

// User Methods

Procedure SP_ListBox.RegisterMethods;
Begin

  Inherited;
  RegisterMethod('add', 'S', Method_Add);
  RegisterMethod('insert', 'ns', Method_Insert);
  RegisterMethod('erase', 'n', Method_Delete);
  RegisterMethod('clear', '', Method_Clear);
  RegisterMethod('move', 'nn', Method_Move);
  RegisterMethod('clearsel', '', Method_ClearSelected);
  RegisterMethod('addcol', 'sn', Method_AddCol);
  RegisterMethod('insertcol', 'nsn', Method_AddCol);
  RegisterMethod('erasecol', 'n', Method_DeleteCol);
  RegisterMethod('sort', '', Method_Sort);

End;

Procedure SP_ListBox.Method_Move(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i, j: Integer;
Begin

  i := StringToInt(Params[0], 0) -1;
  j := StringToInt(Params[1], 0) -1;
  If (i >= 0) And (i < Count) And (j >= 0) And (j < Count) Then
    MoveItem(i, j);

End;

Procedure SP_ListBox.Method_Clear(Params: Array of aString; Var Error: TSP_ErrorCode);
Begin

  Clear;

End;

Procedure SP_ListBox.Method_ClearSelected(Params: Array of aString; Var Error: TSP_ErrorCode);
Begin

  ClearSelected;

End;

Procedure SP_ListBox.Method_Add(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
Begin

  For i := 0 To Length(Params) -1 do
    Add(Params[i]);

End;

Procedure SP_ListBox.Method_Insert(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
Begin

  i := StringToInt(Params[0], 0) -1;
  If (i >= 0) And (i < Count) then
    Insert(i, Params[1])
  Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Procedure SP_ListBox.Method_Delete(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
Begin

  i := StringToInt(Params[0], 0) -1;
  If (i >= 0) And (i < Count) then
    Delete(i)
  Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Procedure SP_ListBox.Method_AddCol(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  w: Integer;
  s: aString;
Begin

  s := Params[0];
  If Length(Params) > 1 Then Begin
    w := StringToInt(Params[1], 4 * Round(iFH * iSY));
    AddHeader(s, w);
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Procedure SP_ListBox.Method_InsertCol(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i, w: Integer;
  s: aString;
Begin

  i := StringToInt(Params[0], 0) -1;
  If (Length(Params) > 2) And (i >= 0) And (i <= Count) Then Begin
    s := Params[1];
    w := StringToInt(Params[2], 4 * Round(iFH * iSY));
    InsertHeader(i, s, w);
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Procedure SP_ListBox.Method_DeleteCol(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
Begin

  i := StringToInt(Params[0], 0) -1;
  If (i >= 0) And (i < Count) then
    DeleteHeader(i)
  Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Procedure SP_ListBox.Method_Sort(Params: Array of aString; Var Error: TSP_ErrorCode);
Begin

  Sort(fSortedBy);

End;

end.
