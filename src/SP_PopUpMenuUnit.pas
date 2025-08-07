unit SP_PopUpMenuUnit;

{$INCLUDE SpecBAS.inc}

interface

Uses Types, SP_Errors, SP_Util, SP_BaseComponentUnit;

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
  fShortcut: Longword;
  Owner: SP_BaseComponent;
  IsWindowMenu: Boolean;
  fGroupID: Integer;

  Procedure SetCaption(s: aString);
  Procedure SetChecked(b: Boolean);

  Property Caption: aString read fCaption write SetCaption;
  Property OnClick: SP_MenuClickEvent read fOnClick write fOnClick;
  Property Enabled: Boolean read fEnabled write fEnabled;
  Property Visible: Boolean read fVisible write fVisible;
  Property Checkable: Boolean read fCheckable write fCheckable;
  Property Checked: Boolean read fChecked write SetChecked;
  Property Selected: Boolean read fSelected write fSelected;
  Property Extents: TRect read fExtents write fExtents;
  Property SubMenu: SP_PopupMenu read fSubMenu write fSubMenu;
  Property Shortcut: Longword read fShortcut write fShortcut;
  Property GroupID: Integer read fGroupID write fGroupID;
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
    fAltDown: Boolean;
    fShortcutLen: Integer;
    fCapOfs: Integer;

    Compiled_OnSelect,
    User_OnSelect: aString;

    Procedure CalculateSizes;
    Procedure Draw; Override;
    Procedure PerformKeyDown(Var Handled: Boolean); Override;
    Procedure PerformKeyUp(Var Handled: Boolean); Override;
    Procedure SetDisabledFontClr(c: Byte); Override;
    Procedure SetHighlightClr(c: Byte); Override;
    Procedure SetSeparatorClr(c: Byte);

    Procedure MouseDown(Sender: SP_BaseComponent; X, Y, Btn: Integer); Override;
    Procedure MouseUp(Sender: SP_BaseComponent; X, Y, Btn: Integer); Override;
    Procedure MouseMove(Sender: SP_BaseComponent; X, Y, Btn: Integer); Override;
    Procedure MouseLeave; Override;
    Function  ItemAtPos(x, y: Integer): Integer;
    Procedure SetItemCaption(Index: Integer; Caption: aString);
    Function  GetItemCaption(Index: Integer): aString;

    Function  AddItem(Item: SP_MenuItem): pSP_MenuItem;
    Function  InsertItem(Item: SP_MenuItem; Index: Integer): pSP_MenuItem;
    Procedure DeleteItem(Index: Integer);
    Procedure MoveItem(Item1, Item2: Integer);
    Procedure Clear;
    Procedure SetItem(Index: Integer; MenuItem: SP_MenuItem);
    Function  GetItem(Index: Integer): SP_MenuItem;
    Procedure SelectItem(i: Integer; ShowSubMenu: Boolean);
    Function  Find(text: aString): Integer;
    Procedure CancelSelection;
    Procedure PopUp(x, y: Integer);
    Procedure SetSubMenu(Index: Integer; SubMenu: SP_PopUpMenu);
    Procedure Close;
    Procedure CloseAll;
    Procedure ExecuteItem(Item: Integer);
    Function  IsAccelerator(Chr: aChar): Integer;
    Function  CheckShortcuts: Boolean;

    Property  Count: Integer read fCount;
    Property  MenuItems[Index: Integer]: SP_MenuItem read GetItem write SetItem;
    Property  IgnoreMouseUp: Boolean read fIgnoreMouseUp write fIgnoreMouseUp;
    Property  OnPopUp: SP_PopupEvent read fOnPopUp write fOnPopUp;
    Property  HighlightClr: Byte read fHighlightClr write SetHighlightClr;
    Property  SeparatorClr: Byte read fSepClr write SetSeparatorClr;
    Property  LastClicked: SP_MenuItem read fClicked write fClicked;

    Constructor Create(Owner: SP_BaseComponent; ParentMenu: SP_BaseComponent);
    Destructor  Destroy; Override;

    // User Properties

    Procedure RegisterProperties; Override;
    Procedure Set_Item(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Item: aString;
    Procedure Set_ItemEnabled(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_ItemEnabled: aString;
    Procedure Set_ItemChecked(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_ItemChecked: aString;
    Procedure Set_ItemCheckable(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_ItemCheckable: aString;
    Procedure Set_ItemVisible(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_ItemVisible: aString;
    Procedure Set_ItemSubMenu(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_ItemSubMenu: aString;
    Procedure Set_OnSelect(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_OnSelect: aString;
    Procedure Set_HiLightClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_HilightClr: aString;
    Procedure Set_SepClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_SepClr: aString;
    Function  Get_Count: aString;
    Function  Get_IndexOf: aString;
    Function  Get_Clicked: aString;

    Procedure RegisterMethods; Override;
    Procedure Method_Clear(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Move(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Add(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Insert(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Delete(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_PopUp(Params: Array of aString; Var Error: TSP_ErrorCode);

End;

Function CreateItem(Caption: aString; Enabled, Visible, Checkable, Checked: Boolean; Shortcut: aString; SubMenu: SP_PopUpMenu; OnClick: SP_MenuClickEvent): SP_MenuItem;
Function ShortcutStrToInt(Shortcut: aString): LongWord;
Function ShortCutToString(i: Integer): aString;

implementation

Uses Math, SP_WindowMenuUnit, SP_BankFiling, SP_Components, SP_Graphics, SP_Input, SP_SysVars, SP_Sound, SP_FPEditor, SP_Tokenise, SP_Interpret_PostFix;

// SP_PopupMenu

Function CreateItem(Caption: aString; Enabled, Visible, Checkable, Checked: Boolean; Shortcut: aString; SubMenu: SP_PopUpMenu; OnClick: SP_MenuClickEvent): SP_MenuItem;
Begin

  Result := SP_MenuItem.Create;
  Result.Caption := Caption;
  Result.Enabled := Enabled;
  Result.Visible := Visible;
  Result.Checkable := Checkable;
  Result.Checked := Checked;
  Result.OnClick := OnClick;
  Result.SubMenu := SubMenu;
  Result.Shortcut := ShortcutStrToInt(Shortcut);

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

Procedure SP_MenuItem.SetChecked(b: Boolean);
Var
  i, gi: Integer;
Begin
  // Handles group IDs. If checked and the group ID is > 0 then all other items WITH THAT GROUP ID will
  // uncheck. You cannot uncheck a groupID'd item - you have to check another in the same group.
  gi := fGroupID;
  if (Not IsWindowMenu) and (gi > 0) Then Begin
    if b And Assigned(Owner) Then Begin
      fChecked := b;
      With SP_PopUpMenu(Owner) Do Begin
        for i := 0 To Count -1 Do
          if MenuItems[i] <> Self Then
            if (MenuItems[i].GroupID = gi) and MenuItems[i].fChecked Then Begin
              MenuItems[i].fChecked := False;
              If MenuItems[i].Enabled And Assigned(MenuItems[i].OnClick) Then
                MenuItems[i].OnClick(Self.Owner, i);
            End;
      End;
    End;
  End Else
    fChecked := b;
End;

Constructor SP_PopUpMenu.Create(Owner: SP_BaseComponent; ParentMenu: SP_BaseComponent);
Begin

  Inherited Create(Owner);

  fTypeName := 'spSubMenu';

  fTransparentClr := 3;
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
    fBackgroundClr := SP_WindowMenu(ParentMenu).fSubMenuClr;
  End Else Begin
    fDisabledFontClr := SP_UITextDisabled;
    fHighlightClr := SP_UISelection;
    fBackgroundClr := SP_UIBackground;
  End;
  AddOverrideControl(Self);
  fAltDown := False;

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
      fItems[i].SubMenu.HighlightClr := c;

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
  x, y, w, h, mw, mx, i, ol, l, t, bs, cfW, cfH: Integer;
  SubsPresent: Boolean;
  Win: pSP_Window_Info;
  r: TRect;
Begin

  Lock;

  // Iterate through this menu's items. Not submenus.

  cfW := Round(iFW * iSX);
  cfH := Round(iFH * iSY);

  y := 2;
  mw := 0;
  mx := 3;
  fShortcutLen := 0;
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
            Inc(w, cFW + 4);
            Inc(x, cFW + 4);
          End Else Begin
            Inc(w, cFW);
            Inc(x, cFW);
          End;
        Inc(w, StripLen(Caption) * cFW);
        If Shortcut <> 0 Then Begin
          l := Length(ShortcutToString(ShortCut));
          fShortcutLen := Max(fShortcutLen, l);
        End;
        if SP_Util.Pos('&', Caption) > 0 Then Dec(w, cFW);
        If x > mx Then mx := x;
        If w > mw Then mw := w;
      End;
    End;
  End;
  if fShortcutLen > 0 then
    mw := mw + ((fShortcutLen +2) * cFW);
  For i := 0 To Length(fItems) -1 Do Begin
    With r do Begin
      Left := mx;
      Top := y;
      If fItems[i].Caption <> '-' Then Begin
        right := mx + mw;
        Bottom := y + cFH;
        inc(y, cFH + 2)
      End Else Begin
        right := mx + mw - (cFW * 2);
        Bottom := y + cFH;
        inc(y, cFH + 2);
      End;
      If SubsPresent Then
        Inc(Right, cFW * 2)
      Else
        Inc(Right, cFW);
    End;
    fItems[i].Extents := r;
  End;

  bs := Ord(fBorder);

  l := Left; ol := l;
  t := Top;
  w := mw + mx + cFW + (Ord(SubsPresent) * cFW) + bs;
  h := y + 2 + bs;

  Win := GetWindowDetails;
  If l + w > Win^.Width - BSize Then l := Win^.Width - w - BSize;
  If l < 0 Then l := 0;
  If t < 0 Then t := 0;
  If t + h > Win^.Height - BSize Then t := Win^.Height - h - BSize;

  if ol <> l Then
    fCapOfs := ol - l;

  SetBounds(l, t, w, h);
  Unlock;

  fCount := Length(fItems);

End;

Procedure SP_PopUpMenu.Draw;
Var
  y, i, c, ic, cfW: Integer;
  MouseInSubMenu: Boolean;
  mp, rp: TPoint;
  cChar: aChar;
  s: aString;
  e: TRect;
Begin

  cfW := Round(iFW * iSX);

  FillRect(0, 0, fWidth, fHeight, fBackgroundClr);
  if fBorder Then Begin
    DrawRect(0, 0, fWidth -1, fHeight -1, fBorderClr);
    DrawRect(0, 0, fWidth -2, fHeight -2, fBorderClr);
    SetPixel(fWidth -1, 0, 3);
    SetPixel(0, fHeight -1, 3);
    If Assigned(fParentMenu) and (fParentMenu is SP_WindowMenu) Then Begin
      i := SP_WindowMenu(fParentMenu).fCapWidth;
      if i > 0 Then
        DrawLine(1 + fCapOfs, 0, i + fCapOfs, 0, fBackgroundClr);
    End;
  End;

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
        e := Rect(2, Extents.Top, fWidth -4, Extents.Bottom +1);
        FillRect(e, c);
        MouseInSubMenu := Assigned(SubMenu) And SubMenu.Visible And PtInRect(Rect(0, 0, SubMenu.Width, SubMenu.Height), SubMenu.ScreenToClient(mp));
        If (Focused or PtInRect(Rect(0, 0, fWidth -1, fHeight -1), rp)) And Not MouseInSubMenu Then Begin
          If Focused Then
            c := SP_UISelectionOutline
          Else
            c := SP_UISelectionUnfocusedOutline;
          DrawRect(e, c);
        End;
      End;
      If Checked Then Begin
        If fGroupID = 0 Then cChar := #246 else cChar := #244;
        PRINT(5, Extents.Top +1, cChar, ic, -1, iSX, iSY, False, False, False, False);
      End;
      If Caption <> '-' Then Begin
        PRINT(Extents.Left, Extents.Top +1, Caption, ic, -1, iSX, iSY, False, False, True, fAltDown And fEnabled);
        If Shortcut <> 0 Then Begin
          s := ShortcutToString(Shortcut) + '  ';
          PRINT(Extents.Right - cFW * Length(s), Extents.Top +1, s, fSepClr, -1, iSX, iSY, False, False, False, False);
        End;
      End Else Begin
        y := Trunc(((Extents.Bottom - Extents.Top)/2) + Extents.Top);
        DrawLine(Extents.Left, y, Extents.Right, y, fSepClr);
      End;
      If Assigned(SubMenu) Then
        PRINT(Extents.Right - cFW * 2, Extents.Top +1, #247, ic, -1, iSX, iSY, False, False, False, False);

    End;

  End;

End;

Procedure SP_PopUpMenu.SelectItem(i: Integer; ShowSubMenu: Boolean);
Var
  j, cfW: Integer;
  p: TPoint;
Begin
  If fSelected <> i Then
    CancelSelection;

  cfW := Round(iFW * iSX);

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
      p := Point(fLeft + fItems[i].Extents.right - cFW * 2, fTop + fItems[i].Extents.Top + 4);
      fItems[i].SubMenu.fParentMenu := Self;
      fItems[i].SubMenu.fAltDown := fAltDown;
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
    fSelected := -1;
    Paint;
  End;
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
        if Selected then
          r.Bottom := r.Bottom + 2;
        If PtInRect(r, p) Then Begin
          Result := i;
          Exit;
        End;
      End;
    End;
  End;

End;

Procedure SP_PopUpMenu.MouseMove(Sender: SP_BaseComponent; X, Y, Btn: Integer);
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
        fParentMenu.MouseMove(fParentMenu, p.x, p.y, Btn);
      End Else Begin
        p := SP_WindowMenu(fParentMenu).ScreenToClient(ClientToScreen(Point(X, Y)));
        SP_WindowMenu(fParentMenu).MouseMove(fParentMenu, p.x, p.y, Btn);
      End;
    End;

  fMX := X;
  fMy := Y;

End;

Procedure SP_PopUpMenu.MouseLeave;
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
  Result^.Owner := Self;
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
  Result^.Owner := Self;
  if fSelected >= Index then inc(fSelected);
  CalculateSizes;
  Paint;

End;

Procedure SP_PopUpMenu.DeleteItem(Index: Integer);
Var
  i: Integer;
Begin

  fItems[Index].Free;
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

Procedure SP_PopUpMenu.Clear;
Var
  i: Integer;
Begin

  For i := 0 To Length(fItems) -1 Do
    fItems[i].Free;
  SetLength(fItems, 0);
  CalculateSizes;

End;

Procedure SP_PopUpMenu.SetItemCaption(Index: Integer; Caption: aString);
Begin

  If (Index >= 0) And (Index < fCount) Then Begin
    fItems[Index].Caption := Caption;
    CalculateSizes;
    Paint;
  End;

End;

Function SP_PopUpMenu.GetItemCaption(Index: Integer): aString;
Begin

  Result := '';
  If (Index >= 0) And (Index < fCount) Then
    Result := fItems[Index].Caption;

End;

Procedure SP_PopUpMenu.SetItem(Index: Integer; MenuItem: SP_MenuItem);
Begin

  If (Index >= 0) And (Index < fCount) Then Begin
    if fSelected = Index then
      fSelected := -1;
    fItems[Index] := MenuItem;
    fItems[Index].Owner := Self;
    CalculateSizes;
  End;

End;

Function  SP_PopUpMenu.GetItem(Index: Integer): SP_MenuItem;
Begin

  If (Index >= 0) And (Index < fCount) Then
    Result := fItems[Index]
  Else
    Result := nil;

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
      fBackgroundClr := SP_WindowMenu(fParentMenu).fSubMenuClr;
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
  fCapOfs := 0;
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

  If MouseControl = Self Then
    MouseControl := nil;

  For i := 0 To Length(fItems) -1 Do
    if Assigned(fItems[i].SubMenu) And fItems[i].SubMenu.Visible Then
      fItems[i].SubMenu.Close;
  Visible := False;
  ForceCapture := False;
  If Assigned(fParentMenu) Then Begin
    fParentMenu.SetFocus(True)
  End Else
    If Assigned(PrevFocusedControl) Then
      PrevFocusedControl.SetFocus(True);

End;

Procedure SP_PopUpMenu.MouseDown(Sender: SP_BaseComponent; X, Y, Btn: Integer);
Var
  p: TPoint;
  Item: Integer;
Begin

  // Outside the menu, close it if we're not in the parent submenu chain
  // inside, do nothing but flag which item we're clicked on.

  SP_PlaySystem(CLICKCHAN, CLICKBANK);
  If Not PtInRect(Rect(0, 0, fWidth, fHeight), Point(X, Y)) Then Begin
    If Assigned(fParentMenu) Then Begin
      p := fParentMenu.ScreenToClient(ClientToScreen(Point(X, Y)));
      if PtInRect(fParentMenu.BoundsRect, p) Then Begin
        If fParentMenu is SP_WindowMenu Then Begin
          Item := SP_WindowMenu(fParentMenu).ItemAtPos(p.X, p.Y);
          If (item >= 0) And ((SP_WindowMenu(fParentMenu).fItems[Item].SubMenu = Self) or Not (SP_WindowMenu(fParentMenu).fItems[Item].Enabled)) Then Begin
            fIgnoreMouseUp := True;
            Exit;
          End;
        End Else Begin
          Item := SP_PopUpMenu(fParentMenu).ItemAtPos(p.X, p.Y);
          If (item >= 0) And ((SP_PopUpMenu(fParentMenu).fItems[Item].SubMenu = Self) or Not (SP_PopUpMenu(fParentMenu).fItems[Item].Enabled)) Then Begin
            fIgnoreMouseUp := True;
            Exit;
          End;
        End;
      End Else
        If Not (SP_BaseComponent(fParentMenu) is SP_WindowMenu) Then
          Close;
      CaptureControl := fParentMenu;
      ForceCapture := True;
      p := CaptureControl.ScreenToClient(ClientToScreen(Point(X, Y)));
      CaptureControl.MouseDown(CaptureControl, p.x, p.y, Btn);
    End Else Begin
      SetFocus(False);
      Close;
    End;
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
      If Not Permanent Then Visible := False;
    End;

  SetFocus(False);

End;

Procedure SP_PopUpMenu.MouseUp(Sender: SP_BaseComponent; X, Y, Btn: Integer);
Var
  i: Integer;
  item: Integer;
  mnu: SP_PopUpMenu;
Begin

  // Complete the menu item click if we're still on the same menu item.

  Item := ItemAtPos(X, Y);
  If Not fIgnoreMouseUp Then Begin
    If fSelected <> -1 Then Begin
      i := fSelected;
      LastClicked := fItems[i];
      If (Item <> -1) and (fItems[Item].Caption <> '-') Then Begin
        CloseAll;
        If fItems[i].Enabled Then Begin
          If Assigned(fItems[i].OnClick) Then
            fItems[i].OnClick(Self, i);
          If Not Locked And (Compiled_OnSelect <> '') Then
            SP_AddOnEvent(Compiled_OnSelect);
        End;
      End;
    End Else
      If ((Item <> -1) and (fItems[Item].Caption <> '-')) or (Item = -1) Then
        CloseAll;
  End Else Begin
    fIgnoreMouseUp := False;
    // Are we part of a WindowMenu that's set to non-permanent? If so, and Btn=0 then close the menu.
    mnu := Self;
    While Assigned(mnu.fParentMenu) And Not (SP_BaseComponent(mnu.fParentMenu) is SP_WindowMenu) Do mnu := SP_PopupMenu(mnu.fParentMenu);
    If (SP_BaseComponent(mnu.fParentMenu) is SP_WindowMenu) And (Not SP_WindowMenu(mnu.fParentMenu).Permanent) And (Btn = 0) Then
      SP_WindowMenu(mnu).Visible := False;
  End;

End;

Function SP_PopupMenu.IsAccelerator(Chr: aChar): Integer;
Var
  i, p: Integer;
  s: aString;
Begin
  i := 0;
  Result := -1;
  While i < Length(fItems) do Begin
    s := Lower(fItems[i].Caption);
    p := Pos('&', s);
    if (p > 0) and (p < Length(s)) and (s[p +1] = Chr) Then Begin
      Result := i;
      Exit;
    End Else
      Inc(i);
  End;
End;

Procedure SP_PopUpMenu.ExecuteItem(Item: Integer);
Var
  oPW, wID: Integer;
Begin
  If fItems[Item].Checkable Then
    fItems[Item].Checked := Not fItems[Item].Checked;
  CloseAll;
  If Assigned(fItems[Item].OnClick) And fItems[Item].Enabled Then Begin
    wID := GetParentWindowID;
    If PROGSTATE <> SP_PR_RUN Then Begin
      If (wID = fwEditor) or (wID = fwDirect) Then
        if FocusedWindow <> fwNone Then
          wID := FocusedWindow;
    End;
    oPW := fParentWindowID;
    fParentWindowID := wID;
    fItems[Item].OnClick(Self, Item);
    fParentWindowID := oPW;
  End;
  If Not Locked And (Compiled_OnSelect <> '') Then
    SP_AddOnEvent(Compiled_OnSelect);
  Paint;
End;

Procedure SP_PopUpMenu.PerformKeyDown(Var Handled: Boolean);
Var
  i, j, Item: Integer;
  NewChar: Byte;
Begin

  If cLastKey = K_ALT Then Begin
    fAltDown := True;
    Paint;
  End Else
    If fAltDown Then Begin
      Item := IsAccelerator(aChar(DecodeKey(cLastKey)));
      If Item >= 0 Then Begin
        SetFocus(True);
        SelectItem(Item, True);
        Handled := True;
        Exit;
      End;
    End;

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
          If fSelected <> -1 Then
            ExecuteItem(fSelected);
        End;

    Else
      Handled := False;
      Inherited;
    End;

  End Else Begin

    Handled := False;

    Case NewChar of

      K_SPACE:
        Begin
          If fSelected >= 0 Then Begin
            SP_PlaySystem(CLICKCHAN, CLICKBANK);
            If fItems[fSelected].Checkable And fItems[fSelected].Enabled Then
              fItems[fSelected].Checked := Not fItems[fSelected].Checked;
            Paint;
            Handled := True;
          End;
        End;

    End;

  End;

End;

Procedure SP_PopUpMenu.PerformKeyUp(Var Handled: Boolean);
Var
  Item: Integer;
Begin

  If cLastKey = K_ALT Then Begin
    fAltDown := False;
    Paint;
  End;

  Item := IsAccelerator(aChar(DecodeKey(cLastKey)));
  If (Item >= 0) And (Item = fSelected) And fAltDown Then
    If Not Assigned(fItems[Item].SubMenu) Then
      ExecuteItem(Item);

  Handled := True;

End;

Function ShortcutStrToInt(Shortcut: aString): LongWord;
Var
  p: Integer;
  i: Longword;
  s: aString;
Begin
  // Converts a string of chars into a shortcut longword. K_CTRL,K_Z for undo for example.
  // Hi Word = modifier status - 01 = Ctrl, 02 = Shift, 04 = Alt
  // Lo word = Key code (K_Whatever)
  Result := 0;
  Shortcut := Shortcut + ',';
  p := Pos(',', Shortcut);
  While p > 0 Do Begin
    s := Upper(Copy(Shortcut, 1, p -1));
    Shortcut := Copy(Shortcut, p+1);
    p := Pos(',', Shortcut);
    i := 0;
    While i <= High(VKStr) Do
      If VKStr[i] = s Then
        Break
      Else
        Inc(i);
    If i > High(VKStr) Then
      Exit
    Else Begin
      If s = 'K_CTRL' Then
        Result := Result or (1 Shl 16)
      Else
        If s = 'K_SHIFT' Then
          Result := Result or (2 Shl 16)
        Else
          If (s = 'K_ALT') or (s = 'K_ALTGR') Then
            Result := Result or (4 Shl 16)
          Else
            Result := (Result And $FFFF0000) or i;
    End;
  End;

End;

Function ShortCutToString(i: Integer): aString;
Var
  j: Integer;
Begin

  Result := '';
  j := i Shr 16;
  If j And 1 = 1 Then
    Result := 'CTRL+';
  If j And 2 = 2 Then
    Result := Result + 'SHIFT+';
  If j And 4 = 4 Then
    Result := Result + 'ALT+';
  Result := Result + Copy(VKSTR[i And $FFFF], 3);

End;

Function SP_PopupMenu.CheckShortcuts: Boolean;
Var
  c, a, s: Boolean;
  i: Integer;
  v: LongWord;
Begin
  Result := False;
  c := cKEYSTATE[K_CONTROL] =1;
  s := cKEYSTATE[K_SHIFT] = 1;
  a := (cKEYSTATE[K_ALT] = 1) or (cKEYSTATE[K_ALTGR] = 1);
  For i := 0 To Length(fItems) -1 Do
    With fItems[i] Do Begin
      if (fShortcut > 0) And (fItems[i].Enabled) Then Begin
        Result := True;
        v := fShortcut Shr 16;
        if v and 1 = 1 Then Result := Result And c Else Result := Result And Not c;
        if v and 2 = 2 Then Result := Result And s Else Result := Result And Not s;
        if v and 4 = 4 Then Result := Result And a Else Result := Result And Not a;
        Result := Result And (cKEYSTATE[fShortcut And $FFFF] = 1);
        If Result Then Begin
          ExecuteItem(i);
          Exit;
        End;
      End;
    End;
End;

Function SP_PopUpMenu.Find(text: aString): Integer;
Var
  i: integer;
Begin

  Result := -1;
  text := Lower(text);
  For i := 0 To Count -1 Do
    If Lower(fItems[i].Caption) = text Then Begin
      Result := i;
      Break;
    End;

End;

Procedure SP_PopUpMenu.MoveItem(Item1, Item2: Integer);
Begin

  InsertItem(fItems[Item1], Item2);
  If Item1 > Item2 Then Inc(Item1);
  DeleteItem(Item1);

End;

// User Properties

Procedure SP_PopUpMenu.RegisterProperties;
Begin

  Inherited;
  RegisterProperty('item', Get_Item, Set_Item, 'v:s|v:s');
  RegisterProperty('itemenabled', Get_ItemEnabled, Set_ItemEnabled, 'v:v|v:v');
  RegisterProperty('itemchecked', Get_ItemChecked, Set_ItemChecked, 'v:v|v:v');
  RegisterProperty('itemcancheck', Get_ItemCheckable, Set_ItemCheckable, 'v:v|v:v');
  RegisterProperty('itemvisible', Get_ItemVisible, Set_ItemVisible, 'v:v|v:v');
  RegisterProperty('itemsubmenu', Get_ItemSubMenu, Set_ItemSubMenu, 'v:v|v:v');
  RegisterProperty('onselect', Get_OnSelect, Set_OnSelect, ':s|s');
  RegisterProperty('hilightclr', Get_HilightClr, Set_HilightClr, ':v|v');
  RegisterProperty('sepclr', Get_SepClr, Set_SepClr, ':v|v');
  RegisterProperty('count', Get_Count, nil, ':v');
  RegisterProperty('clicked', Get_Clicked, nil, ':v');
  RegisterProperty('find', Get_IndexOf, nil, 's:v');

End;

Procedure SP_PopUpMenu.Set_Item(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, p: Integer;
Begin

  p := Pos(':', s);
  If p >= 0 Then Begin
    Idx := StringToInt(Copy(s, 1, p -1)) -1;
    s := Copy(s, p +1);
    If (Idx >= 0) And (Idx < Count) Then
      MenuItems[idx].Caption := s;
    Paint;
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function SP_PopUpMenu.Get_Item: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < Count) Then
    Result := MenuItems[Idx].Caption;

End;

Procedure SP_PopUpMenu.Set_ItemCheckable(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, p: Integer;
Begin

  p := Pos(':', s);
  If p >= 0 Then Begin
    Idx := StringToInt(Copy(s, 1, p -1)) -1;
    s := Copy(s, p +1);
    If (Idx >= 0) And (Idx < Count) Then
      MenuItems[idx].Checkable := StringToInt(s, Ord(MenuItems[Idx].Checkable)) <> 0;
    Paint;
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function SP_PopUpMenu.Get_ItemCheckable: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < Count) Then
    Result := IntToString(Ord(MenuItems[Idx].Checkable));

End;

Procedure SP_PopUpMenu.Set_ItemEnabled(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, p: Integer;
Begin

  p := Pos(':', s);
  If p >= 0 Then Begin
    Idx := StringToInt(Copy(s, 1, p -1)) -1;
    s := Copy(s, p +1);
    If (Idx >= 0) And (Idx < Count) Then
      MenuItems[idx].Enabled := StringToInt(s, Ord(MenuItems[Idx].Enabled)) <> 0;
    Paint;
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function SP_PopUpMenu.Get_ItemEnabled: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < Count) Then
    Result := IntToString(Ord(MenuItems[Idx].Enabled));

End;

Procedure SP_PopUpMenu.Set_ItemChecked(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, p: Integer;
Begin

  p := Pos(':', s);
  If p >= 0 Then Begin
    Idx := StringToInt(Copy(s, 1, p -1)) -1;
    s := Copy(s, p +1);
    If (Idx >= 0) And (Idx < Count) Then
      MenuItems[idx].Checked := StringToInt(s, Ord(MenuItems[Idx].Checked)) <> 0;
    Paint;
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function SP_PopUpMenu.Get_ItemChecked: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < Count) Then
    Result := IntToString(Ord(MenuItems[Idx].Checked));

End;

Procedure SP_PopUpMenu.Set_ItemVisible(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, p: Integer;
Begin

  p := Pos(':', s);
  If p >= 0 Then Begin
    Idx := StringToInt(Copy(s, 1, p -1)) -1;
    s := Copy(s, p +1);
    If (Idx >= 0) And (Idx < Count) Then
      MenuItems[idx].Visible := StringToInt(s, Ord(MenuItems[Idx].Visible)) <> 0;
    Paint;
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function SP_PopUpMenu.Get_ItemVisible: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < Count) Then
    Result := IntToString(Ord(MenuItems[Idx].Visible));

End;

Procedure SP_PopUpMenu.Set_ItemSubMenu(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  ID, Idx, p: Integer;
  Control: SP_BaseComponent;
Begin

  p := Pos(':', s);
  If p >= 0 Then Begin
    Idx := StringToInt(Copy(s, 1, p -1)) -1;
    s := Copy(s, p +1);
    If (Idx >= 0) And (Idx < Count) Then Begin
      ID := StringToInt(s, -1);
      If ControlRegistry.TryGetValue(ID, Control) And (Control Is SP_PopUpMenu) Then
        MenuItems[idx].fSubMenu := SP_PopUpMenu(Control);
    End Else
      Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function SP_PopUpMenu.Get_ItemSubMenu: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < Count) Then
    Result := IntToString(MenuItems[Idx].fSubMenu.fIDNumber);

End;

Procedure SP_PopUpMenu.Set_OnSelect(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Compiled_OnSelect := SP_ConvertToTokens(s, Error);
  If Compiled_OnSelect <> '' Then
    User_OnSelect := s;

End;

Function SP_PopUpMenu.Get_OnSelect: aString;
Begin

  Result := User_OnSelect;

End;

Procedure SP_PopUpMenu.Set_HiLightClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Clr: Integer;
Begin

  Clr := StringToInt(s, fHighlightClr);
  HighlightClr := Clr;

End;

Function SP_PopUpMenu.Get_HilightClr: aString;
Begin

  Result := IntToString(HighLightClr);

End;

Procedure SP_PopUpMenu.Set_SepClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Clr: Integer;
Begin

  Clr := StringToInt(s, fSepClr);
  SeparatorClr := Clr;

End;

Function SP_PopUpMenu.Get_SepClr: aString;
Begin

  Result := IntToString(fSepClr);

End;

Function SP_PopUpMenu.Get_Count: aString;
Begin

  Result := IntToString(Count);

End;

Function SP_PopUpMenu.Get_IndexOf: aString;
Var
  Idx: integer;
Begin

  Idx := 0;
  Result := '-1';
  While Idx < Count Do
    If MenuItems[Idx].Caption = fUserParam Then Begin
      Result := IntToString(Idx +1);
      Exit;
    End Else
      Inc(Idx);

End;

Function SP_PopUpMenu.Get_Clicked: aString;
Var
  Idx: integer;
Begin

  Idx := 0;
  Result := '-1';
  While Idx < Count Do
    If MenuItems[Idx].Caption = LastClicked.Caption Then Begin
      Result := IntToString(Idx +1);
      Exit;
    End Else
      Inc(Idx);

End;

Procedure SP_PopUpMenu.RegisterMethods;
Begin

  Inherited;
  RegisterMethod('add', 'S', Method_Add);
  RegisterMethod('insert', 'ns', Method_Insert);
  RegisterMethod('erase', 'n', Method_Delete);
  RegisterMethod('clear', '', Method_Clear);
  RegisterMethod('move', 'nn', Method_Move);
  RegisterMethod('popup', 'nn', Method_PopUp);

End;

Procedure SP_PopUpMenu.Method_Clear(Params: Array of aString; Var Error: TSP_ErrorCode);
Begin

  Clear;

End;

Procedure SP_PopUpMenu.Method_Move(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i, j: Integer;
Begin

  i := StringToInt(Params[0], 0) -1;
  j := StringToInt(Params[1], 0) -1;
  If (i >= 0) And (i < Count) And (j >= 0) And (j < Count) Then
    MoveItem(i, j);

End;

Procedure SP_PopUpMenu.Method_Add(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
  Item: SP_MenuItem;
Begin

  For i := 0 To Length(Params) -1 do Begin
    Item := SP_MenuItem.Create;
    Item.Checked := False;
    Item.Checkable := False;
    Item.Visible := True;
    Item.Enabled := True;
    Item.Caption := Params[i];
    Item.OnClick := nil;
    AddItem(Item);
  End;

End;

Procedure SP_PopUpMenu.Method_Insert(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
  Item: SP_MenuItem;
Begin

  i := StringToInt(Params[0], 0) -1;
  If (i >= 0) And (i < Count) then Begin
    Item := SP_MenuItem.Create;
    Item.Checked := False;
    Item.Checkable := False;
    Item.Visible := True;
    Item.Enabled := True;
    Item.Caption := Params[i];
    Item.OnClick := nil;
    InsertItem(Item, i);
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Procedure SP_PopUpMenu.Method_Delete(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
Begin

  i := StringToInt(Params[0], 0) -1;
  If (i >= 0) And (i < Count) then
    DeleteItem(i)
  Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Procedure SP_PopUpMenu.Method_PopUp(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  x, y: Integer;
Begin

  x := StringToInt(Params[0], 0);
  y := StringToInt(Params[1], 0);
  PopUp(x, y);

End;

end.
