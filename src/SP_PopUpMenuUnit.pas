unit SP_PopUpMenuUnit;

interface

Uses Types, SP_Util, SP_BaseComponentUnit;

Type

SP_PopUpMenu = Class;

SP_MenuItem = Class

  fCaption: aString;
  fOnClick: SP_MenuClickEvent;
  fEnabled: Boolean;
  fVisible: Boolean;
  fCheckable: Boolean;
  fChecked: Boolean;
  fSelected: Boolean;
  fExtents: TRect;
  fSubMenu: SP_PopupMenu;
  fTag: Integer;
  Owner: SP_BaseComponent;
  IsWindowMenu: Boolean;

  Procedure SetCaption(s: aString);

  Property Caption: aString read fCaption write SetCaption;
  Property OnClick: SP_MenuClickEvent read fOnClick write fOnClick;
  Property Enabled: Boolean read fEnabled write fEnabled;
  Property Visible: Boolean read fVisible write fVisible;
  Property Checkable: Boolean read fCheckable write fCheckable;
  Property Checked: Boolean read fChecked write fChecked;
  Property Selected: Boolean read fSelected write fSelected;
  Property Extents: TRect read fExtents write fExtents;
  Property SubMenu: SP_PopupMenu read fSubMenu write fSubMenu;
  Property Tag: Integer read fTag write fTag;

End;
pSP_MenuItem = ^SP_MenuItem;

SP_PopupMenu = Class(SP_BaseComponent)

  Public

    fOnPopUp: SP_PopUpEvent;
    fIgnoreMouseUp: Boolean;
    fParentMenu: SP_BaseComponent;
    fItems: Array of SP_MenuItem;
    fCount: Integer;
    fSelected: Integer;
    fMx, fMy: Integer;
    fSepClr: Byte;
    fClicked: SP_MenuItem;
    PrevFocusedControl: SP_BaseComponent;
    Procedure CalculateSizes;
    Procedure Draw; Override;
    Procedure PerformKeyDown(Var Handled: Boolean); Override;
    Procedure PerformKeyUp(Var Handled: Boolean); Override;
    Procedure SetDisabledFontClr(c: Byte); Override;
    Procedure SetHighlightClr(c: Byte);
    Procedure SetSeparatorClr(c: Byte);

    Procedure MouseDown(X, Y, Btn: Integer); Override;
    Procedure MouseUp(X, Y, Btn: Integer); Override;
    Procedure MouseMove(X, Y, Btn: Integer); Override;
    Procedure MouseExit; Override;
    Function  ItemAtPos(x, y: Integer): Integer;
    Function  AddItem(Item: SP_MenuItem): pSP_MenuItem;
    Function  InsertItem(Item: SP_MenuItem; Index: Integer): pSP_MenuItem;
    Procedure DeleteItem(Index: Integer);
    Procedure SetItem(Index: Integer; MenuItem: SP_MenuItem);
    Function  GetItem(Index: Integer): SP_MenuItem;
    Procedure SelectItem(i: Integer; ShowSubMenu: Boolean);
    Procedure CancelSelection;
    Procedure PopUp(x, y: Integer);
    Procedure SetSubMenu(Index: Integer; SubMenu: SP_PopUpMenu);
    Procedure Close;
    Procedure CloseAll;

    Property  Count: Integer read fCount;
    Property  MenuItems[Index: Integer]: SP_MenuItem read GetItem write SetItem;
    Property  IgnoreMouseUp: Boolean read fIgnoreMouseUp write fIgnoreMouseUp;
    Property  OnPopUp: SP_PopupEvent read fOnPopUp write fOnPopUp;
    Property  HightlightClr: Byte read fHighlightClr write SetHighlightClr;
    Property  SeparatorClr: Byte read fSepClr write SetSeparatorClr;
    Property  LastClicked: SP_MenuItem read fClicked write fClicked;

    Constructor Create(Owner: SP_BaseComponent; ParentMenu: SP_BaseComponent);
    Destructor  Destroy; Override;

End;

Function CreateItem(Caption: aString; Enabled, Visible, Checkable, Checked: Boolean; SubMenu: SP_PopUpMenu; OnClick: SP_MenuClickEvent): SP_MenuItem;

implementation

Uses Math, SP_WindowMenuUnit, SP_BankFiling, SP_Components, SP_Graphics, SP_Input, SP_SysVars, SP_Sound;

// SP_PopupMenu

Function CreateItem(Caption: aString; Enabled, Visible, Checkable, Checked: Boolean; SubMenu: SP_PopUpMenu; OnClick: SP_MenuClickEvent): SP_MenuItem;
Begin

  Result := SP_MenuItem.Create;
  Result.Caption := Caption;
  Result.Enabled := Enabled;
  Result.Visible := Visible;
  Result.Checkable := Checkable;
  Result.Checked := Checked;
  Result.OnClick := OnClick;
  Result.SubMenu := SubMenu;

End;

Procedure SP_MenuItem.SetCaption(s: aString);
Begin

  fCaption := s;
  If Assigned(Owner) Then Begin
    If IsWindowMenu Then
      SP_WindowMenu(Owner).CalculateSizes
    Else
      SP_PopUpMenu(Owner).CalculateSizes;
    Owner.Paint;
  End;

End;

Constructor SP_PopUpMenu.Create(Owner: SP_BaseComponent; ParentMenu: SP_BaseComponent);
Begin

  Inherited Create(Owner);

  PrevFocusedControl := FocusedControl;
  fParentMenu := SP_PopupMenu(ParentMenu);
  fTransparent := False;
  fCanFocus := True;
  Visible := False;
  fSelected := -1;
  fCount := 0;
  fSepClr := SP_UIMenuSeparator;
  If Assigned(ParentMenu) Then Begin
    fDisabledFontClr := SP_WindowMenu(ParentMenu).fDisabledFontClr;
    fHighlightClr := SP_WindowMenu(ParentMenu).fHighlightClr;
    fBackgroundClr := SP_WindowMenu(ParentMenu).fBackgroundClr;
  End Else Begin
    fDisabledFontClr := SP_UITextDisabled;
    fHighlightClr := SP_UISelection;
    fBackgroundClr := SP_UIBackground;
  End;

End;

Destructor SP_PopupMenu.Destroy;
Var
  i: Integer;
Begin

  For i := 0 To Length(fItems) -1 Do
    fItems[i].Free;

  Inherited;

End;

Procedure SP_PopupMenu.SetDisabledFontClr(c: Byte);
Var
  i: Integer;
Begin

  fDisabledFontClr := c;
  For i := 0 To Length(fItems) -1 Do
    If Assigned(fItems[i].SubMenu) Then
      fItems[i].SubMenu.DisabledFontClr := c;

  Paint;

End;

Procedure SP_PopupMenu.SetHighlightClr(c: Byte);
Var
  i: Integer;
Begin

  fHighlightClr := c;
  For i := 0 To Length(fItems) -1 Do
    If Assigned(fItems[i].SubMenu) Then
      fItems[i].SubMenu.HightlightClr := c;

  Paint;

End;

Procedure SP_PopupMenu.SetSeparatorClr(c: Byte);
Var
  i: Integer;
Begin

  fSepClr := c;
  For i := 0 To Length(fItems) -1 Do
    If Assigned(fItems[i].SubMenu) Then
      fItems[i].SubMenu.SeparatorClr := c;

  Paint;

End;

Procedure SP_PopUpMenu.CalculateSizes;
Var
  x, y, w, h, mw, mx, i, l, t: Integer;
  SubsPresent: Boolean;
  Win: pSP_Window_Info;
  r: TRect;
Begin

  Lock;

  // Iterate through this menu's items. Not submenus.

  y := 2;
  x := 3;
  mw := 0;
  mx := 3;
  w := 0;
  SubsPresent := False;
  For i := 0 To Length(fItems) -1 Do Begin
    x := 3;
    w := 0;
    With fItems[i] Do Begin
      If Visible Then Begin
        If Assigned(SubMenu) Then
          SubsPresent := True
        Else
          If Checkable Then Begin
            Inc(w, iFW + 4);
            Inc(x, iFW + 4);
          End Else Begin
            Inc(w, iFW);
            Inc(x, iFW);
          End;
        Inc(w, StripLen(Caption) * iFW);
        If x > mx Then mx := x;
        If w > mw Then mw := w;
      End;
    End;
  End;
  For i := 0 To Length(fItems) -1 Do Begin
    With r do Begin
      Left := mx;
      Top := y;
      If fItems[i].Caption <> '-' Then Begin
        right := mx + mw;
        Bottom := y + iFH;
        inc(y, iFH + 2)
      End Else Begin
        right := mx + mw - (iFW * 2);
        Bottom := y + iFH;
        inc(y, iFH + 2);
      End;
      If SubsPresent Then
        Inc(Right, iFW * 2)
      Else
        Inc(Right, iFW);
    End;
    fItems[i].Extents := r;
  End;

  l := Left;
  t := Top;
  w := mw + mx + iFW + (Ord(SubsPresent)*iFW);
  h := y + 2;

  Win := GetWindowDetails;
  If l + w > Win^.Width - BSize Then l := Win^.Width - w - BSize;
  If l < 0 Then l := 0;
  If t < 0 Then t := 0;
  If t + h > Win^.Height - BSize Then t := Win^.Height - h - BSize;

  SetBounds(l, t, w, h);
  Unlock;

  fCount := Length(fItems);

End;

Procedure SP_PopUpMenu.Draw;
Var
  x, y, i, j, c, ic: Integer;
  MouseInSubMenu: Boolean;
  mp, rp: TPoint;
  e: TRect;
Begin

  FillRect(0, 0, fWidth, fHeight, fBackgroundClr);
  if fBorder Then
    DrawRect(0, 0, fWidth -1, fHeight -1, fBorderClr);

  mp := Point(MOUSEX, MOUSEY);
  rp := ScreenToClient(mp);

  For i := 0 To Length(fItems) -1 Do Begin

    With fItems[i] Do Begin

      If Enabled Then Begin
        c := fHighlightClr;
        ic := fFontClr;
      end else Begin
        c := fBackGroundClr;
        ic := fDisabledFontClr;
      End;
      If Selected Then Begin
        e := Rect(2, Extents.Top, Width -3, Extents.Bottom +1);
        FillRect(e, c);
        MouseInSubMenu := Assigned(SubMenu) And SubMenu.Visible And PtInRect(Rect(0, 0, SubMenu.Width, SubMenu.Height), SubMenu.ScreenToClient(mp));
        If PtInRect(e, rp) And Not MouseInSubMenu Then Begin
          If fFocused Then
            c := SP_UISelectionOutline
          Else
            c := SP_UISelectionUnfocusedOutline;
          DrawRect(e, c);
        End;
      End;
      If Checked Then PRINT(5, Extents.Top +1, #246, ic, -1, iSX, iSY, False, False);
      If Caption <> '-' Then
        PRINT(Extents.Left, Extents.Top +1, Caption, ic, -1, iSX, iSY, False, False)
      Else Begin
        y := Trunc(((Extents.Bottom - Extents.Top)/2) + Extents.Top);
        DrawLine(Extents.Left, y, Extents.Right, y, fSepClr);
      End;
      If Assigned(SubMenu) Then
        PRINT(Extents.Right - iFW * 2, Extents.Top +1, #247, ic, -1, iSX, iSY, False, False);

    End;

  End;

End;

Procedure SP_PopUpMenu.SelectItem(i: Integer; ShowSubMenu: Boolean);
Var
  j: Integer;
  p: TPoint;
Begin
  If fSelected <> i Then
    CancelSelection;

  If (fItems[i].Caption <> '-') And (fItems[i].Enabled) Then Begin
    fItems[i].Selected := True;
    fSelected := i;
    For j := 0 To Length(fItems) -1 Do
      If j <> i Then
        If (fItems[j].SubMenu <> nil) And fItems[j].SubMenu.Visible Then
          fItems[j].SubMenu.CloseAll;
    CaptureControl := Self;
    MouseControl := Self;
    If fItems[i].Enabled And Assigned(fItems[i].SubMenu) And ShowSubMenu Then Begin
      p := Point(fLeft + fItems[i].Extents.right - iFW * 2, fTop + fItems[i].Extents.Top + 4);
      fItems[i].SubMenu.fParentMenu := Self;
      fItems[i].SubMenu.PopUp(p.x, p.y);
    End;
  End;
  Paint;

End;

Procedure SP_PopUpMenu.CancelSelection;
Begin
  If fSelected <> -1 Then Begin
    if Assigned(fItems[fSelected].SubMenu) And fItems[fSelected].SubMenu.Visible Then
      fItems[fSelected].SubMenu.Close;
    fItems[fSelected].Selected := False;
  End;
  fSelected := -1;
  Paint;
End;

Function SP_PopUpMenu.ItemAtPos(x, y: Integer): Integer;
Var
  i: Integer;
  p: TPoint;
  r: TRect;
Begin

  Result := -1;
  p := Point(X, Y);
  if PtInRect(Rect(0, 0, fWidth, fHeight), p) then Begin
    For i := 0 to length(fItems) -1 Do Begin
      With fItems[i] Do Begin
        r := Extents;
        r.Left := 0;
        r.Right := fWidth;
        If PtInRect(r, p) Then Begin
          Result := i;
          Exit;
        End;
      End;
    End;
  End;

End;

Procedure SP_PopUpMenu.MouseMove(X, Y, Btn: Integer);
Var
  i, old: Integer;
  p: TPoint;
Begin

  If (X = fMX) And (Y = fMY) Then Exit;

  Old := fSelected;
  If PtInRect(Rect(0, 0, fWidth, fHeight), Point(X, Y)) Then Begin
    i := ItemAtPos(X, Y);
    If i >= 0 Then Begin // Hovering an item inside this menu
      Lock;
      If fItems[i].Enabled And (fItems[i].Caption <> '-') Then Begin
        If i <> fSelected Then
          SelectItem(i, True)
      End Else
        If fSelected > -1 Then
          If Not Assigned(fItems[fSelected].SubMenu) Or Not fItems[fSelected].SubMenu.Visible Then Begin
            fItems[fSelected].Selected := False;
            fSelected := -1;
          End;
      Unlock;
      If Assigned(fParentMenu) And (Old <> fSelected) Then
        fParentMenu.Paint;
      Paint;
    End;
  End Else
    If Assigned(fParentMenu) Then Begin
      If fParentMenu is SP_PopUpMenu Then Begin
        p := fParentMenu.ScreenToClient(ClientToScreen(Point(X, Y)));
        fParentMenu.MouseMove(p.x, p.y, Btn);
      End Else Begin
        p := SP_WindowMenu(fParentMenu).ScreenToClient(ClientToScreen(Point(X, Y)));
        SP_WindowMenu(fParentMenu).MouseMove(p.x, p.y, Btn);
      End;
    End;

  fMX := X;
  fMy := Y;

End;

Procedure SP_PopUpMenu.MouseExit;
Var
  i: Integer;
  SubOpen: Boolean;
Begin

  // Cancel the currently selected item

  SubOpen := False;
  For i := 0 To Length(fItems) -1 Do
    SubOpen := SubOpen or (Assigned(fItems[i].SubMenu) And fItems[i].SubMenu.Visible);
  If Not SubOpen Then
    CancelSelection;

End;

Function SP_PopUpMenu.AddItem(Item: SP_MenuItem): pSP_MenuItem;
Var
  l: Integer;
Begin

  l := Length(fItems);
  SetLength(fItems, l+1);
  fItems[l] := Item;
  Result := @fItems[l];
  Result.Owner := Self;
  Result.IsWindowMenu := False;
  CalculateSizes;
  Paint;

End;

Function SP_PopUpMenu.InsertItem(Item: SP_MenuItem; Index: Integer): pSP_MenuItem;
Var
  l, i: Integer;
Begin

  l := Length(fItems);
  SetLength(fItems, l+1);
  For i := l DownTo Index +1 Do
    fItems[i] := fItems[i -1];
  fItems[Index] := Item;
  Result := @fItems[Index];
  if fSelected >= Index then inc(fSelected);
  CalculateSizes;
  Paint;

End;

Procedure SP_PopUpMenu.DeleteItem(Index: Integer);
Var
  i: Integer;
Begin

  For i := Index To Length(fItems) -2 Do
    fItems[i] := fItems[i +1];
  SetLength(fItems, Length(fItems) -1);
  if fSelected = Index then
    fSelected := -1
  Else
    if fSelected > index Then
      inc(fSelected);
  CalculateSizes;

End;

Procedure SP_PopUpMenu.SetItem(Index: Integer; MenuItem: SP_MenuItem);
Begin

  If (Index >= 0) And (Index < fCount) Then Begin
    if fSelected = Index then
      fSelected := -1;
    fItems[Index] := MenuItem;
    CalculateSizes;
  End;

End;

Function  SP_PopUpMenu.GetItem(Index: Integer): SP_MenuItem;
Begin

  If (Index >= 0) And (Index < fCount) Then
    Result := fItems[Index];

End;

Procedure SP_PopUpMenu.SetSubMenu(Index: Integer; SubMenu: SP_PopUpMenu);
Begin

  fItems[Index].SubMenu := SubMenu;
  SubMenu.fDisabledFontClr := fDisabledFontClr;
  SubMenu.fHighlightClr := fHighlightClr;
  SubMenu.fSepClr := fSepClr;
  SubMenu.fBackgroundClr := fBackgroundClr;
  CalculateSizes;

End;

Procedure SP_PopUpMenu.PopUp(x, y: Integer);
Begin

  // Set mouse capture to the popup menu, and force it to remain there.

  If Assigned(fParentMenu) Then Begin
    If fParentMenu is SP_WindowMenu Then Begin
      fDisabledFontClr := SP_WindowMenu(fParentMenu).fDisabledFontClr;
      fHighlightClr := SP_WindowMenu(fParentMenu).fHighlightClr;
      fBackgroundClr := SP_WindowMenu(fParentMenu).fBackgroundClr;
    End Else Begin
      fDisabledFontClr := SP_PopUpMenu(fParentMenu).fDisabledFontClr;
      fHighlightClr := SP_PopUpMenu(fParentMenu).fHighlightClr;
      fBackgroundClr := SP_PopUpMenu(fParentMenu).fBackgroundClr;
    End;
  End;

  PrevFocusedControl := FocusedControl;
  CaptureControl := Self;
  MouseControl := Self;
  ForceCapture := True;
  SetPosition(x, y);
  CalculateSizes;

  If Assigned(OnPopUp) Then
    OnPopup(Self);

  CancelSelection;
  BringToFront;
  SetFocus(True);
  Visible := True;

End;

Procedure SP_PopUpMenu.Close;
Var
  i: Integer;
Begin

  For i := 0 To Length(fItems) -1 Do
    if Assigned(fItems[i].SubMenu) And fItems[i].SubMenu.Visible Then
      fItems[i].SubMenu.Close;
  Visible := False;
  ForceCapture := False;
  If Assigned(fParentMenu) Then
    fParentMenu.SetFocus(True)
  Else
    If Assigned(PrevFocusedControl) Then
      PrevFocusedControl.SetFocus(True);

End;

Procedure SP_PopUpMenu.MouseDown(X, Y, Btn: Integer);
Var
  p: TPoint;
Begin

  // Outside the menu, close it if we're not in the parent submenu chain
  // inside, do nothing but flag which item we're clicked on.

  SP_PlaySystem(CLICKCHAN, CLICKBANK);
  If Not PtInRect(Rect(0, 0, fWidth, fHeight), Point(X, Y)) Then Begin
    If Assigned(fParentMenu) Then Begin
      If Not (SP_BaseComponent(fParentMenu) is SP_WindowMenu) Then
        Close;
      CaptureControl := fParentMenu;
      ForceCapture := True;
      p := CaptureControl.ScreenToClient(ClientToScreen(Point(X, Y)));
      CaptureControl.MouseDown(p.x, p.y, Btn);
    End Else
      Close;
  End Else Begin
    If fSelected >= 0 Then
      If fItems[fSelected].Checkable Then Begin
        fItems[fSelected].Checked := Not fItems[fSelected].Checked;
        Paint;
      End;
  End;

End;

Procedure SP_PopUpMenu.CloseAll;
Var
  mnu: SP_PopUpMenu;
Begin

  mnu := Self;
  While Assigned(mnu.fParentMenu) And Not (SP_BaseComponent(mnu.fParentMenu) is SP_WindowMenu) Do Begin
    mnu.Visible := False;
    mnu := SP_PopupMenu(mnu.fParentMenu);
  End;
  mnu.Visible := False;
  ForceCapture := False;
  FocusedControl := nil;
  CaptureControl := nil;
  SP_InvalidateWholeDisplay;
  If cKeyRepeat <> -1 Then
    RemoveTimer(cKeyRepeat);

  If SP_BaseComponent(mnu.fParentMenu) is SP_WindowMenu Then
    With SP_WindowMenu(mnu.fParentMenu) Do Begin
      CancelSelection;
      fActivated := False;
    End;

  If Assigned(PrevFocusedControl) Then
    PrevFocusedControl.SetFocus(True);

End;

Procedure SP_PopUpMenu.MouseUp(X, Y, Btn: Integer);
Var
  i: Integer;
Begin

  // Complete the menu item click if we're still on the same menu item.

  If Not fIgnoreMouseUp Then Begin
    If fSelected <> -1 Then Begin
      i := fSelected;
      LastClicked := fItems[i];
      CloseAll;
      If fItems[i].Enabled And Assigned(fItems[i].OnClick) Then
        fItems[i].OnClick(SP_BaseComponent(fItems[i]));
    End;
  End Else
    fIgnoreMouseUp := False;

End;

Procedure SP_PopUpMenu.PerformKeyDown(Var Handled: Boolean);
Var
  i, j, k: Integer;
  NewChar: Byte;
  p: TPoint;
Begin

  If fSelected <> -1 Then Begin
    If Assigned(fItems[fSelected].SubMenu) And fItems[fSelected].SubMenu.Visible Then Begin
      fItems[fSelected].SubMenu.PerformKeyDown(Handled);
      Exit;
    End;
  End;

  NewChar := DecodeKey(cLastKey);
  Handled := True;

  If (NewChar = 0) {$IFNDEF FPC} And (cLastKeyChar <> 1) {$ENDIF} Then Begin

    Case cLastKey of

      K_UP, K_DOWN, K_HOME, K_END, K_LEFT, K_RIGHT:
        Begin
          i := fSelected;
          Case cLastKey Of
            K_UP:
              Begin
                If (i <= 0) And Assigned(fParentMenu) And (SP_BaseComponent(fParentMenu) is SP_WindowMenu) Then Begin
                  Close;
                  With SP_WindowMenu(fParentMenu) Do Begin
                    SetFocus(True);
                    AutoOpen := False;
                  End;
                End Else Begin
                  Dec(i);
                  While (i > 0) And ((fItems[i].Caption = '-') Or Not fItems[i].Enabled) Do
                    Dec(i);
                  If i = -1 Then Begin
                    i := 0;
                    If Assigned(fParentMenu) And (SP_BaseComponent(fParentMenu) is SP_WindowMenu) Then Begin
                      Close;
                      With SP_WindowMenu(fParentMenu) Do Begin
                        SetFocus(True);
                        AutoOpen := False;
                      End;
                    End;
                  End;
                End;
                SP_PlaySystem(CLICKCHAN, CLICKBANK);
              End;
            K_DOWN:
              Begin
                j := i;
                Inc(i);
                While (i < Length(fItems)) And ((fItems[i].Caption = '-') or Not fItems[i].Enabled) Do
                  Inc(i);
                If i = Length(fItems) Then i := j;
                SP_PlaySystem(CLICKCHAN, CLICKBANK);
              End;
            K_HOME:
              Begin
                i := 0;
                SP_PlaySystem(CLICKCHAN, CLICKBANK);
              End;
            K_END:
              Begin
                i := Length(fItems) -1;
                SP_PlaySystem(CLICKCHAN, CLICKBANK);
              End;
            K_RIGHT:
              If (i > -1) And Assigned(fItems[i].SubMenu) Then Begin
                SelectItem(i, True);
                fItems[i].SubMenu.SetFocus(True);
                fItems[i].SubMenu.SelectItem(0, False);
                SP_PlaySystem(CLICKCHAN, CLICKBANK);
                Exit;
              End Else
                If Assigned(fParentMenu) And (SP_BaseComponent(fParentMenu) is SP_WindowMenu) Then Begin
                  Close;
                  With SP_WindowMenu(fParentMenu) Do Begin
                    AutoOpen := True;
                    PerformKeyDown(Handled);
                  End;
                  SP_PlaySystem(CLICKCHAN, CLICKBANK);
                  Exit;
                End;
            K_LEFT:
              Begin
                SP_PlaySystem(CLICKCHAN, CLICKBANK);
                If Assigned(fParentMenu) And (SP_BaseComponent(fParentMenu) is SP_WindowMenu) Then Begin
                  Close;
                  With SP_WindowMenu(fParentMenu) Do Begin
                    AutoOpen := True;
                    PerformKeyDown(Handled);
                  End;
                  Exit;
                End Else
                  If Assigned(fParentMenu) Then Begin
                    Close;
                    ForceCapture := True;
                    CaptureControl := fParentMenu;
                    fParentMenu.SetFocus(True);
                    Exit;
                  End;
              End;
          End;
          i := Min(Max(0, i), Length(fItems) -1);
          SelectItem(i, False);
          Paint;
          Handled := True;
        End;

      K_ESCAPE:
        Begin
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          If Assigned(fParentMenu) And (SP_BaseComponent(fParentMenu) is SP_WindowMenu) Then
            SP_WindowMenu(fParentMenu).AutoOpen := False;
          CloseAll;
          Exit;
        End;

      K_RETURN:
        Begin
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          If fSelected <> -1 Then Begin
            If fItems[fSelected].Checkable Then
              fItems[fSelected].Checked := Not fItems[fSelected].Checked;
            CloseAll;
            If Assigned(fItems[fSelected].OnClick) And fItems[fSelected].Enabled Then
              fItems[fSelected].OnClick(Self);
            Paint;
          End;
        End;

    Else
      Inherited;
    End;

  End Else

    Case NewChar of

      K_SPACE:
        Begin
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          If fItems[fSelected].Checkable And fItems[fSelected].Enabled Then
            fItems[fSelected].Checked := Not fItems[fSelected].Checked;
          Paint;
        End;

    End;

End;

Procedure SP_PopUpMenu.PerformKeyUp(Var Handled: Boolean);
Begin

  Handled := True;

End;


end.
