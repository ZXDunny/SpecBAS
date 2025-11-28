unit SP_WindowMenuUnit;

{$INCLUDE SpecBAS.inc}

interface

Uses SP_Errors, SP_BaseComponentUnit, SP_PopUpMenuUnit, SP_SysVars, SP_Util;

Type

SP_WindowMenu = Class(SP_BaseComponent)

  Public

    fItems: Array of SP_MenuItem;
    fSelected: Integer;
    fMx, fMy: Integer;
    fActivated: Boolean;
    fHighlightClr: Byte;
    fPermanent: Boolean;
    fAutoOpen: Boolean;
    fAltDown: Boolean;
    fCapWidth: Integer;
    fSubMenuClr: Byte;
    fClicked: SP_MenuItem;

    Compiled_OnSelect,
    User_OnSelect: aString;

    Procedure CalculateSizes;
    Procedure Draw; Override;
    Procedure PerformKeyDown(Var Handled: Boolean); Override;
    Procedure PerformKeyUp(Var Handled: Boolean); Override;
    Procedure SetDisabledFontClr(c: Byte); Override;
    Procedure SetHighlightClr(c: Byte); Override;
    Procedure SetPermanent(b: Boolean);
    Procedure SetVisible(Value: Boolean); Override;
    Procedure MouseDown(Sender: SP_BaseComponent; X, Y, Btn: Integer); Override;
    Procedure MouseMove(Sender: SP_BaseComponent; X, Y, Btn: Integer); Override;
    Procedure MouseLeave; Override;
    Function  ItemAtPos(x, y: Integer): Integer;
    Procedure AddItem(Item: SP_MenuItem);
    Procedure InsertItem(Item: SP_MenuItem; Index: Integer);
    Procedure DeleteItem(Index: Integer);
    Procedure Clear;
    Procedure SetItem(Index: Integer; MenuItem: SP_MenuItem);
    Function  GetItem(Index: Integer): SP_MenuItem;
    Procedure SelectItem(i: Integer; ShowSubMenu: Boolean);
    Procedure CancelSelection;
    Procedure SetSubMenu(Index: Integer; SubMenu: SP_PopUpMenu);
    Function  GetCount: Integer;
    Function  IsAccelerator(Chr: aChar): Integer;
    Function  Find(text: aString): Integer;
    Procedure MoveItem(Item1, Item2: Integer);

    Property  MenuItems[Index: Integer]: SP_MenuItem read GetItem write SetItem;
    Property  HighlightColour: Byte read fHighlightClr write SetHighlightClr;
    Property  Permanent: Boolean read fPermanent write SetPermanent;
    Property  AutoOpen: Boolean read fAutoOpen write fAutoOpen;
    Property  Count: Integer read GetCount;
    Property  Activated: Boolean read fActivated write fActivated;
    Property  SubMenuClr: Byte read fSubMenuClr write fSubMenuClr;
    Property  LastClicked: SP_MenuItem read fClicked write fClicked;

    Constructor Create(Owner: SP_BaseComponent);
    Destructor  Destroy; Override;

    // User Properties

    Procedure RegisterProperties; Override;
    Procedure Set_Item(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Item: aString;
    Procedure Set_ItemEnabled(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_ItemEnabled: aString;
    Procedure Set_ItemVisible(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_ItemVisible: aString;
    Procedure Set_ItemSubMenu(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_ItemSubMenu: aString;
    Procedure Set_HiLightClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_HilightClr: aString;
    Procedure Set_SubMenuClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_SubMenuClr: aString;
    Procedure Set_Static(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Static: aString;
    Procedure Set_OnSelect(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_OnSelect: aString;
    Function  Get_Clicked: aString;
    Function  Get_Count: aString;
    Function  Get_IndexOf: aString;

    Procedure RegisterMethods; Override;
    Procedure Method_Clear(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Move(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Add(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Insert(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Delete(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Open(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Close(Params: Array of aString; Var Error: TSP_ErrorCode);

  Public

End;

pSP_WindowMenu = ^SP_WindowMenu;

implementation

Uses Classes, SysUtils, Types, Math, SP_Interpret_PostFix, SP_Input, SP_BankFiling, SP_BankManager, SP_Graphics, SP_Components, SP_Sound;

// SP_WindowMenu

Constructor SP_WindowMenu.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fTypeName := 'spMenu';

  fCanFocus := True;
  fSelected := -1;
  fActivated := False;
  fTransparent := False;
  fHighlightClr := 5;
  fPermanent := True;
  AddOverrideControl(Self);
  fAltDown := False;
  Height := Round(iFH * iSY) + 8;
  fMinHeight := Height;
  fMaxHeight := Height;
  fCapWidth := 0;
  fSubMenuClr := fBackgroundClr;

End;

Destructor SP_WindowMenu.Destroy;
Var
  i: Integer;
Begin

  For i := 0 To Length(fItems) -1 Do
    fItems[i].Free;

  Inherited;

End;

Procedure SP_WindowMenu.SetVisible(Value: Boolean);
Var
  i: integer;
Begin

  For i := 0 To Length(fItems) -1 Do
    if Assigned(fItems[i].SubMenu) And fItems[i].SubMenu.Visible Then
      fItems[i].SubMenu.Close;

  Inherited;

End;

Function SP_WindowMenu.GetCount: Integer;
begin

  Result := Length(fItems);

end;

Procedure SP_WindowMenu.SetPermanent(b: Boolean);
Begin

  If fPermanent <> b Then Begin
    fPermanent := b;
    Visible := fPermanent;
    fAutoOpen := not fPermanent;
    If fPermanent Then Begin
      fParentControl.fClientRect.Height := fParentControl.fClientRect.Height - Height;
      fParentControl.fCLientRect.Top := fParentControl.fClientRect.Top + Height;
    End Else Begin
      fParentControl.fClientRect.Height := fParentControl.fClientRect.Height + Height;
      fParentControl.fCLientRect.Top := fParentControl.fClientRect.Top - Height;
    End;
    Paint;
  End;

End;

Procedure SP_WindowMenu.SetDisabledFontClr(c: Byte);
Var
  i: Integer;
Begin

  fDisabledFontClr := c;
  For i := 0 To Length(fItems) -1 Do
    If Assigned(fItems[i].SubMenu) Then
      fItems[i].SubMenu.DisabledFontClr := c;

  Paint;

End;

Procedure SP_WindowMenu.SetHighlightClr(c: Byte);
Var
  i: Integer;
Begin

  fHighlightClr := c;
  For i := 0 To Length(fItems) -1 Do
    If Assigned(fItems[i].SubMenu) Then
      fItems[i].SubMenu.HighlightClr := c;

  Paint;

End;

Procedure SP_WindowMenu.CalculateSizes;
Var
  r: TRect;
  x, i, l, cFW, cFH: Integer;
  Win: pSP_Window_Info;
  Error: TSP_ErrorCode;
Begin

  Lock;

  cfW := Round(iFW * iSX);
  cfH := Round(iFH * iSY);

  x := cFW Div 2;
  SP_GetWindowDetails(fParentWindowID, Win, Error);

  For i := 0 To Length(fItems) -1 Do Begin

    l := StripLen(fItems[i].Caption)+2;
    if SP_Util.Pos('&', fItems[i].Caption) > 0 Then Dec(l);
    With r Do Begin
      Left := x;
      Right := x + (cFW * l);
      Top := 2;
      Bottom := cFH + 4;
    End;
    fItems[i].Extents := r;
    Inc(x, l * cFW);

  End;

  Align := SP_AlignTop;

  Unlock;

End;

Procedure SP_WindowMenu.Draw;
Var
  i, c, ic, cfW: Integer;
  MouseInSubMenu: Boolean;
  mp, rp: TPoint;
  e: TRect;
Begin

  cfW := Round(iFW * iSX);

  FillRect(0, 0, fWidth, fHeight, fBackgroundClr);
  DrawLine(0, fHeight -3, fWidth -1, fHeight -3, SP_UIHalfLight);
  DrawLine(0, fHeight -2, fWidth -1, fHeight -2, SP_UIShadow);
  DrawLine(0, fHeight -1, fWidth -1, fHeight -1, fBorderClr);

  mp := Point(MOUSEX, MOUSEY);
  rp := ScreenToClient(mp);

  For i := 0 To Length(fItems) -1 Do Begin

    With fItems[i] Do Begin

      If Enabled Then Begin
        c := fHighlightClr;
        ic := fFontClr;
      end else Begin
        c := fBackgroundClr;
        ic := fDisabledFontClr;
      End;
      e.Left := Extents.Left -2; e.Top := Extents.Top;
      e.Right := Extents.Right -3; e.Bottom := Extents.Bottom;
      If Selected Then Begin
        If Not Assigned(SubMenu) Or Not SubMenu.Visible Then Begin
          FillRect(e, c);
          MouseInSubMenu := Assigned(SubMenu) And SubMenu.Visible And PtInRect(Rect(0, 0, SubMenu.Width, SubMenu.Height), SubMenu.ScreenToClient(mp));
          If (Focused or PtInRect(Rect(0, 0, fWidth -1, fHeight -1), rp)) And Not MouseInSubMenu Then
            DrawRect(e, SP_UISelectionOutline);
        End Else Begin
          e.Left := e.Left +2;
          e.Top := e.Top -1;
          FillRect(e, SubMenu.fMenuClr);
          DrawLine(e.Left, e.Top, e.Left, e.Bottom, fBorderClr);
          DrawLine(e.Right, e.Top, e.Right, e.Bottom, fBorderClr);
          DrawLine(e.Left, e.Top, e.Right, e.Top, fBorderClr);
          DrawLine(e.Right +1, e.Top +1, e.Right +1, e.Bottom, fShadowClr);
        End;
      End;

      PRINT(Extents.Left + cFW -2, Extents.Top +1, Caption, ic, -1, iSX, iSY, False, False, True, fAltDown And fEnabled);

    End;

  End;

End;

Procedure SP_WindowMenu.SelectItem(i: Integer; ShowSubMenu: Boolean);
Var
  p: TPoint;
Begin
  If (fSelected <> i) and (fSelected <> -1) Then
    CancelSelection;
  fItems[i].Selected := True;
  fSelected := i;
  If fItems[i].Enabled And Assigned(fItems[i].SubMenu) And ShowSubMenu Then Begin
    p := Point(fLeft+fItems[i].Extents.Left, fTop+fItems[i].Extents.Bottom);
    fItems[i].SubMenu.fAltDown := fAltDown;
    fItems[i].SubMenu.PopUp(p.x, p.y);
    Paint;
  End;
  Paint;
End;

Procedure SP_WindowMenu.CancelSelection;
Begin
  If fSelected <> -1 Then Begin
    if Assigned(fItems[fSelected].SubMenu) And fItems[fSelected].SubMenu.Visible Then
      fItems[fSelected].SubMenu.Close;
    fItems[fSelected].Selected := False;
  End;
  fSelected := -1;
  Paint;
End;

Function SP_WindowMenu.ItemAtPos(x, y: Integer): Integer;
Var
  i: Integer;
  p: TPoint;
  e: TRect;
Begin

  Result := -1;
  p := Point(X, Y);
  if PtInRect(Rect(0, 0, fWidth, fHeight), p) then Begin
    For i := 0 to length(fItems) -1 Do Begin
      With fItems[i] Do Begin
        e := Extents;
        e.Top := 0;
        e.Bottom := fHeight;
        If i = 0 Then
          e.Left := 0;
        if i = Count -1 Then
          e.Right := e.Right + 8;
        If PtInRect(e, p) Then Begin
          Result := i;
          Exit;
        End;
      End;
    End;
  End;

End;

Procedure SP_WindowMenu.MouseLeave;
Begin

  if Not fActivated Then
    CancelSelection;

  Inherited;

End;

Procedure SP_WindowMenu.MouseMove(Sender: SP_BaseComponent; X, Y, Btn: Integer);
Var
  e: TRect;
  i: Integer;
Begin

  If (X = fMX) And (Y = fMY) Then Exit;

  If PtInRect(Rect(0, 0, fWidth, fHeight), Point(X, Y)) Then Begin
    i := ItemAtPos(X, Y);
    If i >= 0 Then Begin
      Lock;
      SelectItem(i, fActivated or not fPermanent);
      With fItems[i] Do Begin
        e.Left := Extents.Left -2; e.Top := Extents.Top;
        e.Right := Extents.Right -3; e.Bottom := Extents.Bottom;
        fCapWidth := e.Right - (e.Left + 2) -1;
      End;
      Unlock;
      Paint;
    End Else
      If Not fActivated Then
        CancelSelection;
  End;

  fMX := X;
  fMy := Y;

End;

Procedure SP_WindowMenu.AddItem(Item: SP_MenuItem);
Var
  l: Integer;
Begin

  l := Length(fItems);
  SetLength(fItems, l+1);
  fItems[l] := Item;
  CalculateSizes;
  fItems[l].Owner := Self;
  fItems[l].IsWindowMenu := True;
  Paint;

End;

Procedure SP_WindowMenu.InsertItem(Item: SP_MenuItem; Index: Integer);
Var
  l, i: Integer;
Begin

  l := Length(fItems);
  SetLength(fItems, l+1);
  For i := l DownTo Index +1 Do
    fItems[i] := fItems[i -1];
  fItems[Index] := Item;
  fItems[Index].Owner := Self;
  if fSelected >= Index then inc(fSelected);
  CalculateSizes;
  Paint;

End;

Procedure SP_WindowMenu.DeleteItem(Index: Integer);
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

Procedure SP_WindowMenu.SetItem(Index: Integer; MenuItem: SP_MenuItem);
Begin

  if fSelected = Index then
    fSelected := -1;
  fItems[Index] := MenuItem;
  fItems[Index].Owner := Self;
  CalculateSizes;

End;

Function  SP_WindowMenu.GetItem(Index: Integer): SP_MenuItem;
Begin

  Result := fItems[Index];

End;

Procedure SP_WindowMenu.SetSubMenu(Index: Integer; SubMenu: SP_PopUpMenu);
Begin

  fItems[Index].SubMenu := SubMenu;
  CalculateSizes;

End;

Procedure SP_WindowMenu.MouseDown(Sender: SP_BaseComponent; X, Y, Btn: Integer);
Var
  i: Integer;
  p: TPoint;
Begin

  SP_PlaySystem(CLICKCHAN, CLICKBANK);
  i := ItemAtPos(X, Y);
  If PtInRect(Rect(0, 0, fWidth, fHeight), Point(X, Y)) And (i >= 0) Then Begin
    If i >= 0 Then Begin
      fActivated := Assigned(fItems[i].SubMenu);
      SetFocus(True);
      If fItems[i].Enabled Then Begin
        LastClicked := fItems[i];
        If Assigned(fItems[i].SubMenu) Then Begin
          p := Point(fLeft+fItems[i].Extents.Left, fTop+fItems[i].Extents.Bottom);
          If Not fItems[i].SubMenu.Visible Then Begin
            fItems[i].SubMenu.fAltDown := fAltDown;
            fItems[i].SubMenu.PopUp(p.x, p.y);
            fItems[i].SubMenu.fIgnoreMouseUp := True;
          End Else Begin
            fItems[i].SubMenu.Close;
            fActivated := False;
          End;
          Paint;
        End;
        If Not Locked And (Compiled_OnSelect <> '') Then
          SP_AddOnEvent(Compiled_OnSelect);
      End;
    End;
  End Else Begin
    CaptureControl := nil;
    ForceCapture := False;
    CancelSelection;
    fActivated := False;
    FocusedControl := nil;
    SetFocus(False);
    If cKeyRepeat <> -1 Then
      RemoveTimer(cKeyRepeat);
  End;

End;

Function SP_WindowMenu.IsAccelerator(Chr: aChar): Integer;
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

Procedure SP_WindowMenu.PerformKeyDown(Var Handled: Boolean);
Var
  i, Item: Integer;
  NewChar: Byte;
  b: Boolean;
  p: TPoint;
Label
  AutoOpenSubMenu;
Begin

  If (cLastKey = K_ALT) And (KeyState[K_CONTROL] = 0) Then Begin
    fAltDown := True;
    Paint;
  End Else
    If fAltDown Then Begin
      Item := IsAccelerator(aChar(DecodeKey(cLastKey)));
      If Item >= 0 Then Begin
        Activated := True;
        SetFocus(True);
        SelectItem(Item, True);
        Handled := True;
        Exit;
      End;
    End;

  if Not fActivated Then Begin
    Handled := False;
    Exit;
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

      K_DOWN, K_HOME, K_END, K_LEFT, K_RIGHT:
        Begin
          b := False;
          i := fSelected;
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          Case cLastKey Of
            K_DOWN:
              Begin
                AutoOpenSubMenu:
                If fItems[i].Enabled Then Begin
                  LastClicked := fItems[i];
                  If (i >= 0) And Assigned(fItems[i].SubMenu) Then Begin
                    p := Point(fLeft+fItems[i].Extents.Left, fTop+fItems[i].Extents.Bottom);
                    If Not fItems[i].SubMenu.Visible Then Begin
                      fItems[i].SubMenu.fAltDown := fAltDown;
                      fItems[i].SubMenu.PopUp(p.x, p.y);
                    End;
                  End;
                  If Not Locked And (Compiled_OnSelect <> '') Then
                    SP_AddOnEvent(Compiled_OnSelect);
                  Exit;
                End;
              End;
            K_HOME:
              i := 0;
            K_END:
              i := Length(fItems) -1;
            K_RIGHT:
              Begin
                If i < Length(fItems) -1 Then
                  Inc(i);
                b := fAutoOpen;
              End;
            K_LEFT:
              Begin
                If i > 0 Then
                  Dec(i);
                b := fAutoOpen;
              End;
          End;
          i := Min(Max(0, i), Length(fItems) -1);
          SelectItem(i, False);
          If b Then Goto AutoOpenSubMenu;
        End;

      K_ESCAPE:
        Begin
          CancelSelection;
          SetFocus(False);
          fActivated := False;
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          Paint;
        End;

      K_RETURN:
        Begin
          If fSelected <> -1 Then Begin
            If fItems[fSelected].Checkable Then
              fItems[fSelected].Checked := Not fItems[fSelected].Checked;
            If fItems[fSelected].Enabled Then Begin
              LastClicked := fItems[fSelected];
              If Assigned(fItems[fSelected].OnClick) Then Begin
                fItems[fSelected].OnClick(Self, fSelected);
                CancelSelection;
                SetFocus(False);
                fActivated := False;
              End;
              If Not Locked And (Compiled_OnSelect <> '') Then
                SP_AddOnEvent(Compiled_OnSelect);
            End;
          End;
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          Paint;
        End;

    Else
      Inherited;
    End;

  End Else

    Case NewChar of

      K_SPACE:
        Begin
          if fSelected >= 0 Then Begin
            SP_PlaySystem(CLICKCHAN, CLICKBANK);
            If fItems[fSelected].Checkable Then
              fItems[fSelected].Checked := Not fItems[fSelected].Checked;
            Paint;
          End;
        End;

    End;

End;

Procedure SP_WindowMenu.PerformKeyUp(Var Handled: Boolean);
Begin

  If cLastKey = K_ALT Then Begin
    fAltDown := False;
    Paint;
  End;

  if Not fActivated Then
    Handled := True;

End;

Function SP_WindowMenu.Find(text: aString): Integer;
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

Procedure SP_WindowMenu.Clear;
Begin

  SetLength(fItems, 0);
  CalculateSizes;

End;

Procedure SP_WindowMenu.MoveItem(Item1, Item2: Integer);
Begin

  InsertItem(fItems[Item1], Item2);
  If Item1 > Item2 Then Inc(Item1);
  DeleteItem(Item1);

End;

// User Properties

Procedure SP_WindowMenu.RegisterProperties;
Begin

  Inherited;
  RegisterProperty('item', Get_Item, Set_Item, 'v:s|v:s');
  RegisterProperty('itemenabled', Get_ItemEnabled, Set_ItemEnabled, 'v:v|v:v');
  RegisterProperty('itemvisible', Get_ItemVisible, Set_ItemVisible, 'v:v|v:v');
  RegisterProperty('itemsubmenu', Get_ItemSubMenu, Set_ItemSubMenu, 'v:v|v:v');
  RegisterProperty('hilightclr', Get_HilightClr, Set_HilightClr, ':v|v');
  RegisterProperty('submenuclr', Get_SubMenuClr, Set_SubMenuClr, ':v|v');
  RegisterProperty('onselect', Get_OnSelect, Set_OnSelect, ':s|s');
  RegisterProperty('clicked', Get_Clicked, nil, ':v');
  RegisterProperty('static', Get_Static, Set_Static, ':v|v');
  RegisterProperty('count', Get_Count, nil, ':v');
  RegisterProperty('find', Get_IndexOf, nil, 's:v');

End;

Procedure SP_WindowMenu.Set_SubMenuClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  SubMenuClr := StringToInt(s, SubMenuClr);

End;

Function SP_WindowMenu.Get_SubMenuClr: aString;
Begin

  Result := IntToString(SubMenuClr);

End;

Procedure SP_WindowMenu.Set_Static(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Permanent := StringToInt(s, Ord(Permanent)) <> 0;

End;

Function SP_WindowMenu.Get_Static: aString;
Begin

  Result := IntToString(ord(Permanent));

End;

Procedure SP_WindowMenu.Set_Item(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
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

Function SP_WindowMenu.Get_Item: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam);
  If (Idx >= 0) And (Idx < Count) Then
    Result := MenuItems[Idx].Caption;

End;

Procedure SP_WindowMenu.Set_ItemEnabled(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
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

Function SP_WindowMenu.Get_ItemEnabled: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < Count) Then
    Result := IntToString(Ord(MenuItems[Idx].Enabled));

End;

Procedure SP_WindowMenu.Set_ItemVisible(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
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

Function SP_WindowMenu.Get_ItemVisible: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < Count) Then
    Result := IntToString(Ord(MenuItems[Idx].Visible));

End;

Procedure SP_WindowMenu.Set_ItemSubMenu(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
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
      If ControlRegistry.TryGetValue(ID, Control) And (Control Is SP_PopUpMenu) Then Begin
        MenuItems[idx].fSubMenu := SP_PopUpMenu(Control);
        SP_PopUpMenu(Control).fParentMenu := Self;
      End;
    End Else
      Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function SP_WindowMenu.Get_ItemSubMenu: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < Count) Then
    Result := IntToString(MenuItems[Idx].fSubMenu.fIDNumber);

End;

Procedure SP_WindowMenu.Set_HiLightClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Clr: Integer;
Begin

  Clr := StringToInt(s, fHighlightClr);
  HighlightClr := Clr;

End;

Function SP_WindowMenu.Get_HilightClr: aString;
Begin

  Result := IntToString(HighLightClr);

End;

Function SP_WindowMenu.Get_Count: aString;
Begin

  Result := IntToString(Count);

End;

Function SP_WindowMenu.Get_IndexOf: aString;
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

Function SP_WindowMenu.Get_Clicked: aString;
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

Procedure SP_WindowMenu.Set_OnSelect(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Compiled_OnSelect := SP_ConvertToTokens(s, Error);
  If Compiled_OnSelect <> '' Then
    User_OnSelect := s;

End;

Function SP_WindowMenu.Get_OnSelect: aString;
Begin

  Result := User_OnSelect;

End;

Procedure SP_WindowMenu.RegisterMethods;
Begin

  Inherited;
  RegisterMethod('add', 'S', Method_Add);
  RegisterMethod('insert', 'ns', Method_Insert);
  RegisterMethod('erase', 'n', Method_Delete);
  RegisterMethod('clear', '', Method_Clear);
  RegisterMethod('move', 'nn', Method_Move);
  RegisterMethod('open', 'nn', Method_Open);
  RegisterMethod('close', 'nn', Method_Close);

End;

Procedure SP_WindowMenu.Method_Clear(Params: Array of aString; Var Error: TSP_ErrorCode);
Begin

  Clear;

End;

Procedure SP_WindowMenu.Method_Move(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i, j: Integer;
Begin

  i := StringToInt(Params[0], 0) -1;
  j := StringToInt(Params[1], 0) -1;
  If (i >= 0) And (i < Count) And (j >= 0) And (j < Count) Then
    MoveItem(i, j);

End;

Procedure SP_WindowMenu.Method_Add(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
  Item: SP_MenuItem;
Begin

  For i := 0 To Length(Params) -1 do Begin
    Item := SP_MenuItem.Create;
    Item.Checked := False;
    Item.Checkable := True;
    Item.Visible := True;
    Item.Enabled := True;
    Item.Caption := Params[i];
    Item.OnClick := nil;
    AddItem(Item);
  End;

End;

Procedure SP_WindowMenu.Method_Insert(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
  Item: SP_MenuItem;
Begin

  i := StringToInt(Params[0], 0) -1;
  If (i >= 0) And (i < Count) then Begin
    Item := SP_MenuItem.Create;
    Item.Checked := False;
    Item.Checkable := True;
    Item.Visible := True;
    Item.Enabled := True;
    Item.Caption := Params[i];
    Item.OnClick := nil;
    InsertItem(Item, i);
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Procedure SP_WindowMenu.Method_Delete(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
Begin

  i := StringToInt(Params[0], 0) -1;
  If (i >= 0) And (i < Count) then
    DeleteItem(i)
  Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Procedure SP_WindowMenu.Method_Open(Params: Array of aString; Var Error: TSP_ErrorCode);
Begin

  Visible := True;
  SetFocus(True);

End;

Procedure SP_WindowMenu.Method_Close(Params: Array of aString; Var Error: TSP_ErrorCode);
Begin

  Visible := False;
  SetFocus(False);

End;

end.
