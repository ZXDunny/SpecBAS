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

unit SP_Menu;

interface

Uses SP_BankManager, SP_BankFiling, SP_Errors, SP_Util;

Type

  SP_MenuSelection = Record
    MenuID, ItemIdx: Integer;
  End;

  SP_Rect = Record
    x, y, w, h: Integer;
  End;

  SP_MenuItem = Record
    Caption:   aString;
    Checkable: Boolean;
    Checked:   Boolean;
    Enabled:   Boolean;
    Visible:   Boolean;
    Selected:  Boolean;
    SubMenu:   Integer;
    Extents:   SP_Rect;
    cV, cS:    Boolean;
    Parent:    Integer;
  End;
  pSP_MenuItem = ^SP_MenuItem;

  SP_MenuRecord = Record
    Id: Integer;
    Items: Array of SP_MenuItem;
    AlwaysVisible: Boolean;
    Visible: Boolean;
    Extents: SP_Rect;
    cV: Boolean;
    Parent: Integer;
    ParentItem: Integer;
    Font: Integer;
    ScaleX, ScaleY: aFloat;
  End;
  pSP_MenuRecord = ^SP_MenuRecord;

  Function  SP_FindMenuID(MenuID: Integer): Integer;
  Procedure SP_CopyMenu(Dst, Src: pSP_MenuRecord);
  Procedure SP_CopyMenuItem(Dst, Src: pSP_MenuItem);
  Function  SP_NewMenu(Var Items: Array of SP_MenuItem; Visible: Boolean): Integer;
  Procedure SP_InsertItem(mIdx, insIdx: Integer; Item: SP_MenuItem; Var Error: TSP_ErrorCode);
  Procedure SP_DeleteItem(mIdx, delIdx: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_AddItem(mIdx: Integer; Item: SP_MenuItem; Var Error: TSP_ErrorCode);
  Function  SP_GetItemAttrs(mIdx, iIdx: Integer; Var Error: TSP_ErrorCode): Integer;
  Procedure SP_SetItemAttrs(mIdx, iIdx, Attr: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_SetSubMenu(Mnu, Idx, nMnu: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_RemoveSubMenu(Mnu, Idx: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_DeleteAllMenus;
  Procedure SP_DeleteMenu(MenuID: Integer; DeleteSubs: Boolean; Var Error: TSP_ErrorCode);
  Procedure SP_SetMenuFont(mIdx, FontID: Integer; ScX, ScY: aFloat; Recurse: Boolean; Var Error: TSP_ErrorCode);
  Procedure SP_MenuToWindow(MenuId, WindowID: Integer; Var Error: TSP_ErrorCode);
  Function  SP_WhichItem(X, Y: Integer): SP_MenuSelection;
  Procedure SP_DisplayMainMenu;
  Procedure SP_SetMenuSelection(mX, mY, mIdx: Integer);
  Procedure SP_DrawMainMenu(Dst: pByte; dW, dH, mIdx: Integer);
  Procedure SP_DrawSubMenu(Dst: pByte; dW, dH, mIdx, sX, sY: Integer);

Var

  SP_MENUS: Array of SP_MenuRecord;

Const

  MI_TOGGLE  = 1;
  MI_CHECK   = 2;
  MI_ENABLE  = 4;
  MI_VISIBLE = 8;

implementation

Uses SP_SysVars, SP_Graphics, SP_Graphics32, SP_FPEditor;

Function SP_FindMenuID(MenuID: Integer): Integer;
Begin

  If MenuID = -1 Then
    Result := -1
  Else Begin
    Result := Length(SP_MENUS) -1;
    While Result >= 0 Do Begin
      If SP_MENUS[Result].Id = MenuID Then Exit;
      Dec(Result);
    End;
  End;

End;

Procedure SP_CopyMenu(Dst, Src: pSP_MenuRecord);
Var
  Idx: Integer;
Begin

  Dst^.Id := Src^.Id;
  SetLength(Dst^.Items, Length(Src^.Items));
  For Idx := 0 to Length(Src^.Items ) -1 Do
    SP_CopyMenuItem(@Dst^.Items[Idx], @Src^.Items[Idx]);
  Dst^.AlwaysVisible := Src^.AlwaysVisible;
  Dst^.Visible := Src^.Visible;
  CopyMem(@Dst^.Extents, @Src^.Extents, SizeOf(SP_Rect));
  Dst^.cV := Src^.cV;
  Dst^.Parent := Src^.Parent;
  Dst^.ParentItem := Src^.ParentItem;
  Dst^.Font := Src^.Font;
  Dst^.ScaleX := Src^.ScaleX;
  Dst^.ScaleY := Src^.ScaleY;

End;

Procedure SP_CopyMenuItem(Dst, Src: pSP_MenuItem);
Begin

  Dst^.Caption := Src^.Caption;
  CopyMem(@Dst^.Checked, @Src^.Checked, (SizeOf(Boolean) * 7) + (SizeOf(Integer) * 2) + SizeOf(SP_Rect));

End;

Function SP_NewMenu(Var Items: Array of SP_MenuItem; Visible: Boolean): Integer;
Var
  Id, Idx, iIdx: Integer;
Label
  NextID;
Begin

  // Create a new menu.

  Id := 0;
NextID:
  For Idx := 0 To Length(SP_MENUS) -1 Do
    If SP_MENUS[Idx].Id = Id Then Begin
      Inc(Id);
      Goto NextID;
    End;

  Idx := Length(SP_MENUS);
  SetLength(SP_MENUS, Idx +1);

  SP_MENUS[Idx].Id := Id;
  SP_MENUS[Idx].AlwaysVisible := Visible;
  SP_MENUS[Idx].Visible := Visible;
  SP_MENUS[Idx].Parent := -1;
  SP_MENUS[Idx].ParentItem := -1;
  SP_MENUS[Idx].Font := -1;
  SP_MENUS[Idx].ScaleX := 1;
  SP_MENUS[Idx].ScaleY := 1;

  SetLength(SP_MENUS[Idx].Items, Length(Items));
  For iIdx := 0 To Length(Items) -1 Do Begin
    SP_CopyMenuItem(@SP_MENUS[Idx].Items[iIdx], @Items[iIdx]);
    SP_MENUS[Idx].Items[iIdx].Parent := -1;
  End;


  Result := Id;

End;

Procedure SP_InsertItem(mIdx, insIdx: Integer; Item: SP_MenuItem; Var Error: TSP_ErrorCode);
Var
  l, Idx: Integer;
Begin

  mIdx := SP_FindMenuID(mIdx);
  If mIdx > -1 Then Begin

    If insIdx > 0 then Begin

      Dec(insIdx);

      If MENUSHOWING Then SP_DisplayMainMenu;

      l := Length(SP_MENUS[mIdx].Items);
      SetLength(SP_MENUS[mIdx].Items, l +1);

      If insIdx >= l Then

        SP_CopyMenuItem(@SP_MENUS[mIdx].Items[l], @Item)

      Else Begin

        For Idx := l DownTo insIdx +1 Do
          SP_CopyMenuItem(@SP_MENUS[mIdx].Items[Idx], @SP_MENUS[mIdx].Items[Idx -1]);
        SP_CopyMenuItem(@SP_MENUS[mIdx].Items[insIdx], @Item);

        For Idx := 0 To Length(SP_MENUS) -1 Do
          If SP_MENUS[Idx].Parent = mIdx Then
            If SP_MENUS[Idx].ParentItem >= insIdx Then
              Inc(SP_MENUS[Idx].ParentItem);

      End;

    End Else
      Error.Code := SP_ERR_INVALID_MENU_ITEM;

  End Else
    Error.Code := SP_ERR_MENU_NOT_FOUND;

End;

Procedure SP_DeleteItem(mIdx, delIdx: Integer; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
Begin

  mIdx := SP_FindMenuID(mIdx);
  If mIdx > -1 Then Begin

    If (delIdx > 0) And (delIdx <= Length(SP_MENUS[mIdx].Items)) Then Begin

      If MENUSHOWING Then SP_DisplayMainMenu;

      For Idx := delIdx To Length(SP_MENUS[mIdx].Items) -2 Do
        SP_CopyMenuItem(@SP_MENUS[mIdx].Items[Idx], @SP_MENUS[mIdx].Items[Idx +1]);

      SetLength(SP_MENUS[mIdx].Items, Length(SP_MENUS[mIdx].Items) -1);

    End Else
      Error.Code := SP_ERR_INVALID_MENU_ITEM;

  End Else
    Error.Code := SP_ERR_MENU_NOT_FOUND;

End;

Procedure SP_AddItem(mIdx: Integer; Item: SP_MenuItem; Var Error: TSP_ErrorCode);
Var
  l: Integer;
Begin

  mIdx := SP_FindMenuID(mIdx);
  If mIdx > -1 Then Begin

    If MENUSHOWING Then SP_DisplayMainMenu;

    l := Length(SP_MENUS[mIdx].Items);
    SetLength(SP_MENUS[mIdx].Items, l +1);

    SP_CopyMenuItem(@SP_MENUS[mIdx].Items[l], @Item);

  End Else
    Error.Code := SP_ERR_MENU_NOT_FOUND;

End;

Function  SP_GetItemAttrs(mIdx, iIdx: Integer; Var Error: TSP_ErrorCode): Integer;
Begin

  Result := 0;
  mIdx := SP_FindMenuID(mIdx);
  If mIdx > -1 Then Begin

    If (iIdx > 0) And (iIdx <= Length(SP_MENUS[mIdx].Items)) Then Begin
      Dec(iIdx);
      With SP_MENUS[mIdx].Items[iIdx] Do Begin
        If Checkable Then Result := Result or MI_TOGGLE;
        If Checked Then Result := Result or MI_CHECK;
        If Enabled Then Result := Result or MI_ENABLE;
        If Visible Then Result := Result or MI_VISIBLE;
      End;
    End Else
      Error.Code := SP_ERR_INVALID_MENU_ITEM;

  End Else
    Error.Code := SP_ERR_MENU_NOT_FOUND;

End;

Procedure SP_SetItemAttrs(mIdx, iIdx, Attr: Integer; Var Error: TSP_ErrorCode);
Begin

  mIdx := SP_FindMenuID(mIdx);
  If mIdx > -1 Then Begin

    If (iIdx > 0) And (iIdx <= Length(SP_MENUS[mIdx].Items)) Then Begin
      Dec(iIdx);
      With SP_MENUS[mIdx].Items[iIdx] Do Begin
        Checkable := (Attr And MI_TOGGLE) <> 0;
        Checked := (Attr And MI_CHECK) <> 0;
        Enabled := (Attr And MI_ENABLE) <> 0;
        Visible := (Attr And MI_VISIBLE) <> 0;
      End;
    End Else
      Error.Code := SP_ERR_INVALID_MENU_ITEM;

  End Else
    Error.Code := SP_ERR_MENU_NOT_FOUND;

End;

Procedure SP_SetSubMenu(Mnu, Idx, nMnu: Integer; Var Error: TSP_ErrorCode);
Var
  sm, m, pm: Integer;
  ms: Boolean;
Begin

  ms := MENUSHOWING;
  If MENUSHOWING Then SP_DisplayMainMenu;

  m := SP_FindMenuID(Mnu);
  sm := SP_FindMenuID(nMnu);
  If m > -1 Then Begin
    If sm > -1 Then Begin
      If sm <> m Then Begin
        pm := m;
        While SP_MENUS[pm].Parent <> -1 Do Begin
          pm := SP_FindMenuID(SP_MENUS[pm].Parent);
          If pm = sm Then Begin
            Error.Code := SP_ERR_INVALID_SUBMENU;
            Exit;
          End;
        End;
        If (Idx > 0) And (Idx <= Length(SP_MENUS[m].Items)) Then Begin
          Dec(Idx);
          SP_MENUS[m].Items[Idx].SubMenu := nMnu;
          SP_MENUS[sm].Parent := Mnu;
          SP_MENUS[sm].ParentItem := Idx;
        End Else
          Error.Code := SP_ERR_INVALID_MENU_ITEM;
      End Else
        Error.Code := SP_ERR_INVALID_SUBMENU;
    End Else
      Error.Code := SP_ERR_MENU_NOT_FOUND;
  End Else
    Error.Code := SP_ERR_MENU_NOT_FOUND;

  If Error.Code = SP_ERR_OK Then
    If ms Then SP_DisplayMainMenu;

End;

Procedure SP_RemoveSubMenu(Mnu, Idx: Integer; Var Error: TSP_ErrorCode);
Var
  m, sm: Integer;
Begin

  If MENUSHOWING Then SP_DisplayMainMenu;

  m := SP_FindMenuID(Mnu);
  If m > -1 Then Begin
      If (Idx > 0) And (Idx <= Length(SP_MENUS[m].Items)) Then Begin
        Dec(Idx);
        SP_MENUS[m].Items[Idx].SubMenu := -1;
        sm := SP_FindMenuID(SP_MENUS[m].Parent);
        If sm > -1 Then Begin
          SP_MENUS[sm].Parent := -1;
          SP_MENUS[sm].ParentItem := -1;
        End;
      End Else
        Error.Code := SP_ERR_INVALID_MENU_ITEM;
  End Else
    Error.Code := SP_ERR_MENU_NOT_FOUND;

End;

Procedure SP_DeleteAllMenus;
Var
  Err: TSP_ErrorCode;
Begin

  While Length(SP_MENUS) > 0 Do
    SP_DeleteMenu(SP_MENUS[0].Id, True, Err);

End;

Procedure SP_DeleteMenu(MenuID: Integer; DeleteSubs: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, i, sm: Integer;
Label
  Start;
Begin

Start:
  Idx := SP_FindMenuID(MenuID);
  If Idx <> -1 Then Begin

    If MENUSHOWING Then SP_DisplayMainMenu;

    If DeleteSubs Then
      For i := 0 To Length(SP_MENUS[idx].Items) -1 Do Begin
        sm := SP_MENUS[Idx].Items[i].SubMenu;
        If sm <> -1 Then Begin
          SP_MENUS[Idx].Items[i].SubMenu := -1;
          If SP_FindMenuID(sm) <> -1 Then
            SP_DeleteMenu(sm, True, Error);
          Goto Start;
        End;
      End;

    For Idx := Idx To Length(SP_MENUS) -2 Do
      SP_CopyMenu(@SP_MENUS[Idx], @SP_MENUS[Idx +1]);

    SetLength(SP_MENUS, Length(SP_MENUS) -1);

    LASTMENU := 0;
    LASTMENUITEM := 0;

  End Else
    Error.Code := SP_ERR_MENU_NOT_FOUND;

End;

Procedure SP_SetMenuFont(mIdx, FontID: Integer; ScX, ScY: aFloat; Recurse: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;

  Procedure SetFont(m, f: Integer);
  Var
    i: Integer;
  Begin
    m := SP_FindMenuID(m);
    If m > -1 Then Begin
      SP_MENUS[m].Font := f;
      SP_MENUS[m].ScaleX := ScX;
      SP_MENUS[m].ScaleY := ScY;
      For i := 0 To Length(SP_MENUS[m].Items) -1 Do
        If SP_MENUS[m].Items[i].SubMenu <> -1 Then
          SetFont(SP_MENUS[m].Items[i].SubMenu, f);
    End;
  End;

Begin

  mIdx := SP_FindMenuID(mIdx);
  If mIdx > -1 Then Begin

    FontID := SP_FindBankID(FontID);
    If FontID <> SP_ERR_BANK_ID_NOT_FOUND Then Begin

      If SP_BankList[FontID]^.DataType = SP_FONT_BANK Then Begin

        SP_MENUS[mIdx].Font := SP_BankList[FontID]^.ID;
        If ScX <= 0 Then Error.Code := SP_ERR_INVALID_SCALE Else SP_MENUS[mIdx].ScaleX := ScX;
        If ScY <= 0 Then Error.Code := SP_ERR_INVALID_SCALE Else SP_MENUS[mIdx].ScaleY := ScY;

        If Error.Code = SP_ERR_OK Then
          If Recurse Then Begin
            For Idx := 0 To Length(SP_MENUS[mIdx].Items) -1 Do Begin
              If SP_MENUS[mIdx].Items[Idx].SubMenu <> -1 Then
                SetFont(SP_MENUS[mIdx].Items[Idx].SubMenu, SP_MENUS[mIdx].Font);
            End;
          End;

      End Else
        Error.Code := SP_ERR_INVALID_BANK;

    End Else
      Error.Code := SP_ERR_BANK_NOT_FOUND;

  End Else
    Error.Code := SP_ERR_MENU_NOT_FOUND;

End;

Procedure SP_MenuToWindow(MenuId, WindowID: Integer; Var Error: TSP_ErrorCode);
Var
  WindowInfo: pSP_Window_Info;
Begin

  // Attach a menu to a window. This will result in a top-level menu (a bar style) being created in
  // the window specified.

  Error.Code := SP_ERR_OK;
  SP_GetWindowDetails(WindowID, WindowInfo, Error);

  If Error.Code = SP_ERR_OK Then Begin

    If SP_FindMenuID(MenuID) <> -1 Then
      WindowInfo^.Menu := MenuID
    Else
      Error.Code := SP_ERR_MENU_NOT_FOUND;

  End;

End;

Procedure SP_DisplayMainMenu;
Var
  mIdx, Idx: Integer;
Begin

  mIdx := SP_FindMenuID(CURMENU);
  If mIdx > -1 Then Begin

    If SP_MENUS[mIdx].Visible Then
      SP_MENUS[mIdx].Visible := False
    Else
      SP_MENUS[mIdx].Visible := True;

    MENUSHOWING := SP_MENUS[mIdx].Visible;

    If MENUSHOWING Then Begin
      For Idx := 0 To Length(SP_MENUS) -1 Do
        If Idx <> mIdx Then
          SP_MENUS[Idx].Visible := False;
      For Idx := 0 To Length(SP_MENUS[mIdx].Items) -1 Do
        SP_MENUS[mIdx].Items[Idx].Selected := False;
    End;

  End;

End;

Procedure SP_DrawMenu(Window: pSP_Window_Info);
Begin

  // Draw a window-specific menu

End;

Procedure SP_DrawHighlight(Dst: pLongWord; dw, x, y, w, h: Integer);
Var
  W2: Integer;
Begin

  // Render a rectangle filled with MENUHIGHILGHT colours

  Dec(w); Dec(h);

  Inc(Dst, (dw * y) + x);
  W2 := W;
  While W2 > -1 Do Begin
    Dst^ := MENUHLOUTLINE;
    Inc(Dst);
    Dec(W2);
  End;
  Inc(Dst, dw-w -1);
  Dec(h);
  While h >= 1 Do Begin
    Dst^ := MENUHLOUTLINE;
    Inc(Dst);
    W2 := w - 2;
    While W2 >= 0 Do Begin
      Dst^ := MENUHIGHLIGHT;
      Inc(Dst);
      Dec(W2);
    End;
    Dst^ := MENUHLOUTLINE;
    Inc(Dst, dw-w);
    Dec(h);
  End;
  W2 := W;
  While W2 > -1 Do Begin
    Dst^ := MENUHLOUTLINE;
    Inc(Dst);
    Dec(W2);
  End;

End;

Procedure SP_SetMenuSelection(mX, mY, mIdx: Integer);
Var
  m, n, sm, pm, Idx, Idx2, i, vPos: Integer;
  Hit: Boolean;
  VisList: Array[0..20] of Integer;

  Procedure UpdateVisList(m: Integer);
  Var
    vIdx, smIdx: Integer;
  Begin

    For vIdx := 0 To Length(SP_MENUS[m].Items) -1 Do Begin
      smIdx := SP_FindMenuID(SP_MENUS[m].Items[vIdx].SubMenu);
      If smIdx <> -1 Then
        If SP_MENUS[smIdx].Visible Then Begin
          Inc(vPos);
          VisList[vPos] := smIdx;
          UpdateVisList(smIdx);
        End;
    End;

  End;

Begin

  // Traverses a top-level (bar style) menu, and highlights items that are
  // under the coordinates specified, and makes submenus visible.

  // First, clear all menus to not-visible (except the one being worked on):

  m := SP_FindMenuID(mIdx);
  Idx := 0;
  While Idx < Length(SP_MENUS) Do Begin
    Idx2 := 0;
    While Idx2 < Length(SP_MENUS[Idx].Items) Do Begin
      SP_MENUS[Idx].Items[Idx2].cS := False;
      Inc(Idx2);
    End;
    If Idx <> m Then SP_MENUS[Idx].cV := False Else SP_MENUS[Idx].cV := True;
    Inc(Idx);
  End;

  // Next, build a list of all menus and submenus that are open

  Hit := False;
  vPos := 0;
  VisList[0] := m;
  UpdateVisList(m);

  // Now traverse the list *backwards* - if the cursor is inside a menu, then make sure all its parents are visible and highlighted,
  // then highlight any items in that menu (and open a submenu).

  For Idx := vPos DownTo 0 Do Begin

    m := VisList[Idx];

    With SP_MENUS[m].Extents Do
      If (mX >= x) and (mX < x + w) and (mY >= y) and (mY < y+ h) Then Begin

        Hit := True;
        SP_MENUS[m].cV := True;
        n := m;
        pm := SP_FindMenuID(SP_MENUS[n].Parent);

        While pm <> -1 Do Begin
          SP_MENUS[pm].cV := True;
          SP_MENUS[pm].Items[SP_MENUS[n].ParentItem].cS := True;
          n := pm;
          pm := SP_FindMenuID(SP_MENUS[n].Parent);
        End;

        // Pointing at any items in this menu?

        For i := 0 To Length(SP_MENUS[m].Items) -1 Do Begin

          If SP_MENUS[m].Items[i].Visible Then
            With SP_MENUS[m].Items[i].Extents Do
              If (mX >= x) and (mX < x + w) and (mY >= y) and (mY < y+ h) and SP_MENUS[m].Items[i].Enabled And (SP_MENUS[m].Items[i].Caption <> '-') Then Begin

                SP_MENUS[m].Items[i].cS := True;
                sm := SP_FindMenuID(SP_MENUS[m].Items[i].SubMenu);

                If sm <> -1 Then
                  SP_MENUS[sm].cV := True;

                LASTMENU := SP_MENUS[m].Id;
                LASTMENUITEM := i + 1;

              End;

        End;
        Break;

      End;

  End;

  // And now set the new menu states.

  If Hit Then Begin
    Idx := 0;
    While Idx < Length(SP_MENUS) Do Begin
      Idx2 := 0;
      While Idx2 < Length(SP_MENUS[Idx].Items) Do Begin
        SP_MENUS[Idx].Items[Idx2].Selected := SP_MENUS[Idx].Items[Idx2].cS;
        Inc(Idx2);
      End;
      SP_MENUS[Idx].Visible := SP_MENUS[Idx].cV;
      Inc(Idx);
    End;
  End;

End;

Function SP_WhichItem(X, Y: Integer): SP_MenuSelection;
Var
  m, iIdx, vPos: Integer;
  VisList: Array[0..20] of Integer;

  Procedure UpdateVisList(m: Integer);
  Var
    vIdx, smIdx: Integer;
  Begin

    For vIdx := 0 To Length(SP_MENUS[m].Items) -1 Do Begin
      smIdx := SP_FindMenuID(SP_MENUS[m].Items[vIdx].SubMenu);
      If smIdx <> -1 Then
        If SP_MENUS[smIdx].Visible Then Begin
          Inc(vPos);
          VisList[vPos] := smIdx;
          UpdateVisList(smIdx);
        End;
    End;

  End;

Begin

  Result.MenuID := -1;
  Result.ItemIdx := 0;

  m := SP_FindMenuID(CURMENU);
  If m > -1 Then Begin

    vPos := 0;
    VisList[0] := m;
    UpdateVisList(m);

    For m := vPos DownTo 0 Do
      With SP_MENUS[VisList[m]] Do
        If Visible and (x >= Extents.x) and (x < Extents.x + Extents.w) and (y >= Extents.y) and (y < Extents.y + Extents.h) Then
          For iIdx := 0 To Length(Items) -1 Do
            With Items[iIdx] Do
              If Enabled And Visible And (SubMenu = -1) And (Caption <> '-') And (x >= Extents.x) and (x < Extents.x + Extents.w) and (y >= Extents.y) and (y < Extents.y + Extents.h) Then Begin
                Result.MenuID := Id;
                Result.ItemIdx := iIdx + 1;
                Exit;
              End;

  End;

End;

Procedure SP_DrawMainMenu(Dst: pByte; dW, dH, mIdx: Integer);
Var
  m, mH, cW, il, Idx, fB, fW, fH, sW, tX, tY: Integer;
  SelectedItem, SelX, SelY: Integer;
  lClr: LongWord;
  FontBank: pSP_Font_Info;
  SclX, SclY: aFloat;
  pPtr: pByte;
Begin

  SelectedItem := -1;

  // Draw an Amiga-style menu that inhabits the top of the screen

  fW := 8; fH := 8; SelX := 0; SelY := 0;

  m := SP_FindMenuID(mIdx);
  If m > -1 Then Begin

    If CLISTWINDOW Then Begin
      fH := Trunc(fPFH);
      fW := Trunc(fPFW);
      SclX := EDFONTSCALEX;
      SclY := EDFONTSCALEY;
      fB := SP_FindBankID(EDITORFONT);
      If fB = SP_ERR_BANK_ID_NOT_FOUND Then
        fB := SP_FindBankID(SYSFONT);
    End Else Begin
      If SP_MENUS[m].Font <> -1 Then Begin
        fB := SP_FindBankID(SP_MENUS[m].Font);
        If fB <> SP_ERR_BANK_ID_NOT_FOUND Then Begin
          FontBank := @SP_BankList[fB]^.Info[0];
          fW := FontBank^.Width;
          fH := FontBank^.Height;
        End Else Begin
          fB := SP_FindBankID(EDITORFONT);
          If fB = SP_ERR_BANK_ID_NOT_FOUND Then
            fB := SP_FindBankID(SYSFONT);
        End;
        SclX := SP_MENUS[m].ScaleX;
        SclY := SP_MENUS[m].ScaleY;
      End Else Begin
        fB := SP_FindBankID(FONTBANKID);
        If fB = SP_ERR_BANK_ID_NOT_FOUND Then
          fB := SP_FindBankID(SYSFONT);
        fH := FONTHEIGHT;
        fW := FONTWIDTH;
        SclX := CSCALEX;
        SclY := CSCALEY;
      End;
      fW := Trunc(fW * SclX);
      fH := Trunc(fH * SclY);
    End;

    If SP_MENUS[m].Visible Then Begin

      // Calculate the menu's extents - larger menus wrap around onto multiple lines.

      cW := 0; mH := 1;
      sW := SCREENWIDTH - (7 * fW);
      For Idx := 0 To Length(SP_MENUS[m].Items) -1 Do Begin

        If SP_MENUS[m].Items[Idx].Visible Then Begin

          il := (StripLen(SP_MENUS[m].Items[Idx].Caption) +1) * fW;
          Inc(cW, il);
          If cW > sW Then Begin

            Inc(mH);     // Add a menu line
            Dec(sW, fW); // Offset the stripe as it moves down and left
            cW := il;

          End;

        End;

      End;

      With SP_MENUS[m].Extents Do Begin

        x := 0;
        y := 0;
        w := dW;
        h := 2 + (mH * fH);

      End;

      // Now draw the menu bar

      pPtr := Dst;
      lClr := MENUBARPAPER;
      sW := (4 + (mH * fH)) * dW * SizeOf(LongWord);
      While sW > 0 Do Begin
        pLongWord(pPtr)^ := lClr;
        Inc(pLongWord(pPtr));
        Dec(sW, SizeOf(LongWord));
      End;
      sW := dW;
      While sW > 0 Do Begin
        pLongWord(pPtr)^ := MENUBAROUTLINE;
        Inc(pLongWord(pPtr));
        Dec(sW);
      End;

      // And the menu items. Offset by 1 character to the right.

      tX := fw; tY := 1;
      sW := SCREENWIDTH - (7 * fW);
      For Idx := 0 To Length(SP_MENUS[m].Items) -1 Do Begin

        If SP_MENUS[m].Items[Idx].Visible Then Begin

          il := (StripLen(SP_MENUS[m].Items[Idx].Caption) +1) * fW;
          If tX + il > sW Then Begin

            Inc(tY, fH +1);
            tX := fW;
            Dec(sW, fW);

          End;

          With SP_MENUS[m].Items[Idx].Extents Do Begin

            x := tX;
            y := tY;
            w := il;
            h := fH;

            If SP_MENUS[m].Items[Idx].Selected And SP_MENUS[m].Items[Idx].Enabled Then Begin
              SelectedItem := Idx;
              SelX := x - ((fw Div 4) * 3); SelY := y + h;
              SP_DrawHighlight(pLongWord(Dst), dW, x - (fw Div 2), y, w, h);
            End;

          End;

          If SP_MENUS[m].Items[Idx].Enabled Then
            SP_RawTextOut(fB, pLongWord(Dst), dW, dH, tX, tY, SP_MENUS[m].Items[Idx].Caption, MENUBARINK, MENUBARPAPER, SclX, SclY, True, False)
          Else
            SP_RawTextOut(fB, pLongWord(Dst), dW, dH, tX, tY, SP_MENUS[m].Items[Idx].Caption, MENUDISABLEDINK, MENUBARPAPER, SclX, SclY, True, False);

          Inc(Tx, il);

        End;

      End;

      // Draw the stripe

      SP_DrawStripe32(pLongWord(Dst), dW, fW, (mH * fH) +2);

      // And finally head off and draw any selected item's submenu(s)

      If SelectedItem <> -1 Then
        If SP_MENUS[m].Items[SelectedItem].SubMenu <> -1 Then
          SP_DrawSubMenu(Dst, dW, dH, SP_MENUS[m].Items[SelectedItem].SubMenu, SelX, SelY);

    End;

  End;

End;

Procedure SP_DrawSubMenu(Dst: pByte; dW, dH, mIdx, sX, sY: Integer);
Var
  m, Idx, il, icl, mxW, mcl, mW, mH, tX, tY, SelectedItem, SelX, SelY: Integer;
  HasSubs, Checks: Boolean;
  FontBank: pSP_Font_Info;
  lClr: LongWord;
  fB, fW, fH: Integer;
  SclX, SclY: aFloat;
  Caption: aString;
  pPtr: pLongWord;
Begin

  // Draw a "box" menu, used as a submenu from the main bar or other menu item.
  // Very similar on the face of it to the above code, but items in these can change their appearance,
  // and selection/highlighting is slightly (and subtly) different.

  fW := 8; fH := 8; SelX := 0; SelY := 0;

  m := SP_FindMenuID(mIdx);
  If m > -1 Then Begin

    If SP_MENUS[m].Visible Then Begin

      If CLISTWINDOW Then Begin
        fH := Trunc(fpFH);
        fW := Trunc(fpFW);
        SclX := EDFONTSCALEX;
        SclY := EDFONTSCALEY;
        fB := SP_FindBankID(EDITORFONT);
        If fB = SP_ERR_BANK_ID_NOT_FOUND Then
          fB := SP_FindBankID(SYSFONT);
      End Else Begin
        If SP_MENUS[m].Font <> -1 Then Begin
          fB := SP_FindBankID(SP_MENUS[m].Font);
          If fB <> SP_ERR_BANK_ID_NOT_FOUND Then Begin
            FontBank := @SP_BankList[fB]^.Info[0];
            fW := FontBank^.Width;
            fH := FontBank^.Height;
          End Else Begin
            fB := SP_FindBankID(EDITORFONT);
            If fB = SP_ERR_BANK_ID_NOT_FOUND Then
              fB := SP_FindBankID(SYSFONT);
          End;
          SclX := SP_MENUS[m].ScaleX;
          SclY := SP_MENUS[m].ScaleY;
        End Else Begin
          fB := SP_FindBankID(FONTBANKID);
          If fB = SP_ERR_BANK_ID_NOT_FOUND Then
            fB := SP_FindBankID(SYSFONT);
          fH := FONTHEIGHT;
          fW := FONTWIDTH;
          SclX := CSCALEX;
          SclY := CSCALEY;
        End;
        fW := Trunc(fW * SclX);
        fH := Trunc(fH * SclY);
      End;

      // Calculate the menu's extents

      mcl := 0; mH := fH Div 2;
      HasSubs := False; Checks := False;
      For Idx := 0 To Length(SP_MENUS[m].Items) -1 Do Begin

        If SP_MENUS[m].Items[idx].Visible Then Begin
          Inc(mH, fH);
          icl := StripLen(SP_MENUS[m].Items[Idx].Caption);
          If icl > mcl then mcl := icl;
          If (SP_MENUS[m].Items[Idx].SubMenu <> -1) And SP_MENUS[m].Items[Idx].Enabled Then HasSubs := True;
          If SP_MENUS[m].Items[Idx].Checkable or SP_MENUS[m].Items[Idx].Checked Then Checks := True;
        End;

      End;

      Inc(mCl);
      If HasSubs then Inc(mcl, 2);
      If Checks Then Inc(mcl);
      mxW := mcl * fw;

      With SP_MENUS[m].Extents Do Begin

        x := sX;
        y := sY;
        w := mxW;
        h := (mH + fH Div 2) -1;

      End;

      // Now draw the menu - a white rectangle with a black border

      pPtr := pLongWord(Dst);
      Inc(pPtr, sX + (sY * dW));
      lClr := MENUPAPER;
      mH := SP_MENUS[m].Extents.h;
      For Idx := 0 To SP_MENUS[m].Extents.w -1 Do Begin
        pPtr^ := MENUOUTLINE;
        Inc(pPtr);
      End;
      Inc(pPtr, dW - SP_MENUS[m].Extents.w);
      While mH > 0 Do Begin
        mW := SP_MENUS[m].Extents.w -2;
        pPtr^ := MENUOUTLINE;
        Inc(pPtr);
        While mW > 0 Do Begin
          pPtr^ := lClr;
          Inc(pPtr);
          Dec(mW);
        End;
        pPtr^ := MENUOUTLINE;
        Inc(pPtr);
        pPtr^ := MENUOUTLINE;
        Inc(pPtr, dW - SP_MENUS[m].Extents.w );
        Dec(mH);
      End;
      For Idx := 0 To SP_MENUS[m].Extents.w Do Begin
        pPtr^ := MENUOUTLINE;
        Inc(pPtr);
      End;
      Inc(pPtr, dW - SP_MENUS[m].Extents.w);
      For Idx := 0 To SP_MENUS[m].Extents.w -1 Do Begin
        pPtr^ := MENUOUTLINE;
        Inc(pPtr);
      End;

      // And the menu items..

      SelectedItem := -1;
      tX := sX + (fW Div 2); tY := sY + (fH Div 2);
      For Idx := 0 To Length(SP_MENUS[m].Items) -1 Do Begin

        If SP_MENUS[m].Items[idx].Visible  Then Begin

          Caption := SP_MENUS[m].Items[Idx].Caption;

          If Checks Then
            If Caption <> '-' Then
              If SP_MENUS[m].Items[Idx].Checked Then
                Caption := #246 + Caption
              Else
                Caption := ' ' + Caption;

          If SP_MENUS[m].Items[Idx].Enabled Then Begin
            If SP_MENUS[m].Items[Idx].SubMenu <> -1 Then Begin
              While Length(Caption) < mCl-3 Do Caption := Caption + ' ';
              Caption := Caption + ' '#247;
            End;
            iCl := MENUINK;
          End Else
            iCl := MENUDISABLEDINK;

          il := StripLen(Caption) * fW;
          If il > mxW Then mxW := il;

          With SP_MENUS[m].Items[Idx].Extents Do Begin

            x := tX;
            y := tY;
            w := mxW;
            h := fH;

            If SP_MENUS[m].Items[Idx].Selected And (Caption <> '-') Then Begin
              SelectedItem := Idx;
              SelX := x + w - (fw * 4); SelY := y + (fh div 4);
              SP_DrawHighlight(pLongWord(Dst), dW, x, y, w - fW, h);
            End;

          End;

          If Caption = '-' Then Begin
            pPtr := pLongWord(Dst);
            Inc(pPtr, tX + (dw * (tY + (fH Div 2))));
            For il := 0 To mxW -fW Do Begin
              pPtr^ := MENUSEP;
              Inc(pPtr);
            End;
            Inc(tY, fH);
          End Else Begin
            SP_RawTextOut(fB, pLongWord(Dst), dW, dH, tX, tY, Caption, iCl, MENUPAPER, SclX, SclY, True, False);
            Inc(tY, fH);
          End;

        End;

      End;

      // And finally head off and draw any selected item's submenu(s)

      If SelectedItem <> -1 Then
        If SP_MENUS[m].Items[SelectedItem].SubMenu <> -1 Then
          SP_DrawSubMenu(Dst, dW, dH, SP_MENUS[m].Items[SelectedItem].SubMenu, SelX, SelY);

    End;

  End;

End;

Initialization

  CURMENU := -1;

end.
