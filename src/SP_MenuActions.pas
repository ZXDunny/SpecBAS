unit SP_MenuActions;

interface

Uses SyncObjs, SysUtils, SP_Tokenise, SP_BaseComponentUnit, SP_WindowMenuUnit, SP_PopUpMenuUnit, SP_LabelUnit, SP_Interpret_PostFix;

Type

  SP_MenuActionProcs = Class

  Public

    Class Procedure FPMenu_NEW(Sender: SP_BaseComponent);
    Class Procedure FPMenu_LOADQQ(Sender: SP_BaseComponent);
    Class Procedure FPMenu_MERGEQQ(Sender: SP_BaseComponent);
    Class Procedure FPMenu_SAVE(Sender: SP_BaseComponent);
    Class Procedure FPMenu_SAVEQQ(Sender: SP_BaseComponent);
    Class Procedure FPMenu_QUIT(Sender: SP_BaseComponent);
    Class Procedure FPMenu_Recent(Sender: SP_BaseComponent);
    Class Procedure FPMenu_Undo(Sender: SP_BaseComponent);
    Class Procedure FPMenu_Redo(Sender: SP_BaseComponent);
    Class Procedure FPMenu_Cut(Sender: SP_BaseComponent);
    Class Procedure FPMenu_Copy(Sender: SP_BaseComponent);
    Class Procedure FPMenu_Paste(Sender: SP_BaseComponent);
    Class Procedure FPMenu_Delete(Sender: SP_BaseComponent);
    Class Procedure FPMenu_SelAll(Sender: SP_BaseComponent);
    Class Procedure FPMenu_SelNone(Sender: SP_BaseComponent);
    Class Procedure FPMenu_Find(Sender: SP_BaseComponent);
    Class Procedure FPMenu_FindNext(Sender: SP_BaseComponent);
    Class Procedure FPMenu_Replace(Sender: SP_BaseComponent);
    Class Procedure FPMenu_GOTOLine(Sender: SP_BaseComponent);
    Class Procedure FPMenu_GOTOError(Sender: SP_BaseComponent);
    Class Procedure FPMenu_Edit_PopUp(Sender: SP_BaseComponent);
    Class Procedure FPMenu_MarkerSetPopUp(Sender: SP_BaseComponent);
    Class Procedure FPMenu_MarkerJumpPopUp(Sender: SP_BaseComponent);
    Class Procedure FPMenu_SetMarker(Sender: SP_BaseComponent);
    Class Procedure FPMenu_JumpMarker(Sender: SP_BaseComponent);
    Class Procedure FPMenu_ClearMarkers(Sender: SP_BaseComponent);
    Class Procedure FPMenu_View_Popup(Sender: SP_BaseComponent);
    Class Procedure FPMenu_Switch(Sender: SP_BaseComponent);
    Class Procedure FPMenu_ShowScreen(Sender: SP_BaseComponent);
    Class Procedure FPMenu_RUN(Sender: SP_BaseComponent);
    Class Procedure FPMenu_CONTINUE(Sender: SP_BaseComponent);
    Class Procedure FPMenu_GOTO(Sender: SP_BaseComponent);
    Class Procedure FPMenu_SingleStep(Sender: SP_BaseComponent);
    Class Procedure FPMenu_StepOver(Sender: SP_BaseComponent);
    Class Procedure FPMenu_CONTINUE_Cursor(Sender: SP_BaseComponent);
    Class Procedure FPMenu_DebugPanel(Sender: SP_BaseComponent);
    Class Procedure FPMenu_BreakpointAdd(Sender: SP_BaseComponent);
    Class Procedure FPMenu_AddWatch(Sender: SP_BaseComponent);
    Class Procedure FPMenu_FullScreen(Sender: SP_BaseComponent);

    Class Procedure GrabberMouseDown(X, Y, Btn: Integer);
    Class Procedure GrabberMouseMove(X, Y, Btn: Integer);
    Class Procedure GrabberMouseUp(X, Y, Btn: Integer);

  End;

  Procedure SP_CreateEditorMenu;
  Procedure UpdateStatusLabel;

Var

  // Editor menu strip
  FPMenu: SP_WindowMenu;
  FPFileMenu, FPRecentMenu, FPEditMenu, FPMarkerMenu, FPViewMenu, FPRunMenu, FPToolsMenu, FPHelpMenu,
  FPSetMarkerMenu, FPJumpMarkerMenu: SP_PopupMenu;

  // Editor status label that sits to the right of the menu
  FPEditorStatusLabel, FPDirectStatusLabel: SP_Label;

implementation

Uses SP_BankManager, SP_BankFiling, SP_Errors, SP_Graphics, SP_FileIO, SP_Input,
     SP_FPEditor, SP_SysVars, SP_Util, SP_ControlMsgs, SP_DebugPanel, SP_Main,
     SP_Variables;

Var

  SP_FindNextItem, SP_SwitchMenuItem, SP_DebugPanelItem, SP_FullScreenMenuItem, SP_GotoErrorItem: SP_MenuItem;

Procedure SP_CreateEditorMenu;
Var
  Win: pSP_Window_Info;
  Error: TSP_ErrorCode;
  Item: SP_MenuItem;
  i: Integer;
Begin

  SP_GetWindowDetails(FPWindowID, Win, Error);

  FPMenu := SP_WindowMenu.Create(Win^.Component);

  FPFileMenu := SP_PopUpMenu.Create(Win^.Component, FPMenu);
  FPRecentMenu := SP_PopUpMenu.Create(Win^.Component, FPFileMenu);
  FPEditMenu := SP_PopUpMenu.Create(Win^.Component, FPMenu);
  FPMarkerMenu := SP_PopUpMenu.Create(Win^.Component, FPEditMenu);
  FPSetMarkerMenu := SP_PopUpMenu.Create(Win^.Component, FPMarkerMenu);
  FPJumpMarkerMenu := SP_PopUpMenu.Create(Win^.Component, FPMarkerMenu);
  FPViewMenu := SP_PopUpMenu.Create(Win^.Component, FPMenu);
  FPRunMenu := SP_PopUpMenu.Create(Win^.Component, FPMenu);
  FPToolsMenu := SP_PopUpMenu.Create(Win^.Component, FPMenu);
  FPHelpMenu := SP_PopUpMenu.Create(Win^.Component, FPMenu);

  FPFileMenu.name := 'filemenu';
  FPFileMenu.BackgroundClr := 253;
  FPRecentMenu.name := 'recentmenu';
  FPRecentMenu.BackgroundClr := 253;
  FPEditMenu.name := 'editmenu';
  FPEditMenu.BackgroundClr := 253;
  FPMarkerMenu.name := 'markermenu';
  FPMarkerMenu.BackgroundClr := 253;
  FPSetMarkerMenu.name := 'setmarkermenu';
  FPSetMarkerMenu.BackgroundClr := 253;
  FPJumpMarkerMenu.name := 'jumpmarkermenu';
  FPJumpMarkerMenu.BackgroundClr := 253;
  FPViewMenu.name := 'viewmenu';
  FPViewMenu.BackgroundClr := 253;
  FPRunMenu.name := 'runmenu';
  FPRunMenu.BackgroundClr := 253;
  FPToolsMenu.name := 'toolsmenu';
  FPToolsMenu.BackgroundClr := 253;
  FPHelpMenu.name := 'helpmenu';
  FPHelpMenu.BackgroundClr := 253;
  FPMenu.Name := 'windowmenu';
  FPMenu.BackgroundClr := 251;

  FPMenu.AddItem(CreateItem('&File', True, True, False, False, '', FPFileMenu, Nil));
  FPMenu.AddItem(CreateItem('&Edit', True, True, False, False, '', FPEditMenu, Nil));
  FPMenu.AddItem(CreateItem('&View', True, True, False, False, '', FPViewMenu, Nil));
  FPMenu.AddItem(CreateItem('&Run', True, True, False, False, '', FPRunMenu, Nil));
  FPMenu.AddItem(CreateItem('&Tools', True, True, False, False, '', FPToolsMenu, Nil));
  FPMenu.AddItem(CreateItem('&Help', True, True, False, False, '', FPHelpMenu, Nil));

  // File menu

  FPFileMenu.AddItem(CreateItem('&New', True, True, False, False, '', Nil, SP_MenuActionProcs.FPMenu_NEW));
  FPFileMenu.AddItem(CreateItem('&LOAD ""', True, True, False, False, 'K_CTRL,K_L', Nil, SP_MenuActionProcs.FPMenu_LOADQQ));
  FPFileMenu.AddItem(CreateItem('&MERGE ""', True, True, False, False, '', Nil, SP_MenuActionProcs.FPMenu_MERGEQQ));
  FPFileMenu.AddItem(CreateItem('Recent Files', Length(SP_RecentFiles) > 0, True, False, False, '', FPRecentMenu, Nil));
  FPFileMenu.AddItem(CreateItem('-', True, True, False, False, '', Nil, Nil));
  If FILENAMED Then Begin
    FPFileMenu.AddItem(CreateItem('&SAVE "' + SP_ExtractFileName(PROGNAME) + '"', True, True, False, False, 'K_CTRL,K_S', Nil, SP_MenuActionProcs.FPMenu_SAVE));
    FPFileMenu.AddItem(CreateItem('S&ave as...', True, True, False, False, '', Nil, SP_MenuActionProcs.FPMenu_SAVEQQ));
  End Else Begin
    FPFileMenu.AddItem(CreateItem('&SAVE "' + SP_ExtractFileName(PROGNAME) + '"', False, True, False, False, '', Nil, SP_MenuActionProcs.FPMenu_SAVE));
    FPFileMenu.AddItem(CreateItem('S&ave as...', True, True, False, False, 'K_CTRL,K_S', Nil, SP_MenuActionProcs.FPMenu_SAVEQQ));
  End;
  FPFileMenu.AddItem(CreateItem('-', True, True, False, False, '', Nil, Nil));
  FPFileMenu.AddItem(CreateItem('&Quit', True, True, False, False, '', Nil, SP_MenuActionProcs.FPMenu_QUIT));

  // Recent Files

  For i := 0 To Length(SP_RecentFiles) -1 Do Begin
    Item := CreateItem(SP_RecentFiles[i], True, True, False, False, '', nil, SP_MenuActionProcs.FPMenu_Recent);
    Item.Tag := i;
    FPRecentMenu.AddItem(Item);
  End;

  // Edit menu

  FPEditMenu.AddItem(CreateItem('&Undo', True, True, False, False, 'K_CTRL,K_Z', Nil, SP_MenuActionProcs.FPMenu_Undo));
  FPEditMenu.AddItem(CreateItem('R&edo', True, True, False, False, 'K_CTRL,K_SHIFT,K_Z', Nil, SP_MenuActionProcs.FPMenu_Redo));
  FPEditMenu.AddItem(CreateItem('-', True, True, False, False, '', Nil, Nil));
  FPEditMenu.AddItem(CreateItem('&Cut', True, True, False, False, 'K_CTRL,K_X', Nil, SP_MenuActionProcs.FPMenu_Cut));
  FPEditMenu.AddItem(CreateItem('C&opy', True, True, False, False, 'K_CTRL,K_C', Nil, SP_MenuActionProcs.FPMenu_Copy));
  FPEditMenu.AddItem(CreateItem('&Paste', True, True, False, False, 'K_CTRL,K_V', Nil, SP_MenuActionProcs.FPMenu_Paste));
  FPEditMenu.AddItem(CreateItem('&Delete', True, True, False, False, '', Nil, SP_MenuActionProcs.FPMenu_Delete));
  FPEditMenu.AddItem(CreateItem('Select &all', True, True, False, False, 'K_CTRL,K_A', Nil, SP_MenuActionProcs.FPMenu_SelAll));
  FPEditMenu.AddItem(CreateItem('Select &none', True, True, False, False, 'K_CTRL,K_D', Nil, SP_MenuActionProcs.FPMenu_SelNone));
  FPEditMenu.AddItem(CreateItem('-', True, True, False, False, '', Nil, Nil));
  FPEditMenu.AddItem(CreateItem('&Find...', True, True, False, False, 'K_CTRL,K_F', Nil, SP_MenuActionProcs.FPMenu_Find));
  FPEditMenu.AddItem(CreateItem('&Replace...', True, True, False, False, 'K_CTRL,K_R', Nil, SP_MenuActionProcs.FPMenu_Replace));
  SP_FindNextItem := CreateItem('Find ne&xt', True, True, False, False, 'K_F3', Nil, SP_MenuActionProcs.FPMenu_FindNext);
  FPEditMenu.AddItem(SP_FindNextItem);
  FPEditMenu.AddItem(CreateItem('&Markers', True, True, False, False, '', FPMarkerMenu, Nil));
  FPEditMenu.AddItem(CreateItem('-', True, True, False, False, '', Nil, Nil));
  SP_GotoErrorItem := CreateItem('GO TO last error', True, True, False, False, 'K_CTRL,K_SHIFT,K_G', Nil, SP_MenuActionProcs.FPMenu_GOTOError);
  FPEditMenu.AddItem(SP_GotoErrorItem);
  FPEditMenu.AddItem(CreateItem('&GO TO Line...', True, True, False, False, 'K_CTRL,K_G', Nil, SP_MenuActionProcs.FPMenu_GOTOLine));
  FPEditMenu.OnPopUp := SP_MenuActionProcs.FPMenu_Edit_PopUp;

  // Markers submenu

  FPMarkerMenu.AddItem(CreateItem('&Set', True, True, False, False, '', FPSetMarkerMenu, Nil));
  FPMarkerMenu.AddItem(CreateItem('&Jump', True, True, False, False, '', FPJumpMarkerMenu, Nil));
  FPMarkerMenu.AddItem(CreateItem('Clear &all', True, True, False, False, '', Nil, SP_MenuActionProcs.FPMenu_ClearMarkers));
  FPSetMarkerMenu.OnPopUp := SP_MenuActionProcs.FPMenu_MarkerSetPopUp;
  FPJumpMarkerMenu.OnPopUp := SP_MenuActionProcs.FPMenu_MarkerJumpPopUp;

  For i := 0 To 9 Do Begin
    Item := CreateItem('Marker &' + IntToString(i+1), True, True, True, False, 'K_CTRL,K_SHIFT,K_F'+IntToString(i+1), Nil, SP_MenuActionProcs.FPMenu_SetMarker);
    Item.Tag := i;
    FPSetMarkerMenu.AddItem(Item);
    Item := CreateItem('Marker &' + IntToString(i+1), True, True, False, False, 'K_CTRL,K_F'+IntToString(i+1), Nil, SP_MenuActionProcs.FPMenu_JumpMarker);
    Item.Tag := i;
    FPJumpMarkerMenu.AddItem(Item);
  End;

  // View menu

  SP_FullScreenMenuItem := CreateItem('&Full Screen', True, True, False, False, 'K_ALT,K_ENTER', Nil, SP_MenuActionProcs.FPMenu_FullScreen);
  SP_SwitchMenuItem := CreateItem('&Switch to Direct Mode', True, True, False, False, 'K_ESC', Nil, SP_MenuActionProcs.FPMenu_Switch);
  FPViewMenu.AddItem(SP_SwitchMenuItem);
  FPViewMenu.AddItem(CreateItem('-', True, True, False, False, '', Nil, Nil));
  FPViewMenu.AddItem(SP_FullScreenMenuItem);
  FPViewMenu.AddItem(CreateItem('Show s&creen', True, True, False, False, 'K_CTRL,K_SHIFT,K_ENTER', Nil, SP_MenuActionProcs.FPMenu_ShowScreen));
  SP_DebugPanelItem := CreateItem('Show &debug panel', True, True, False, False, 'K_CTRL,K_B', Nil, SP_MenuActionProcs.FPMenu_DebugPanel);
  FPViewMenu.AddItem(SP_DebugPanelItem);
  FPViewMenu.OnPopUp := SP_MenuActionProcs.FPMenu_View_Popup;

  // RUN menu

  FPRunMenu.AddItem(CreateItem('&RUN', True, True, False, False, 'K_F9', Nil, SP_MenuActionProcs.FPMenu_RUN));
  FPRunMenu.AddItem(CreateItem('&CONTINUE', True, True, False, False, 'K_SHIFT,K_F9', Nil, SP_MenuActionProcs.FPMenu_CONTINUE));
  FPRunMenu.AddItem(CreateItem('&GO TO cursor', True, True, False, False, 'K_SHIFT,K_F10', Nil, SP_MenuActionProcs.FPMenu_GOTO));
  FPRunMenu.AddItem(CreateItem('-', True, True, False, False, '', Nil, Nil));
  FPRunMenu.AddItem(CreateItem('&Single step', True, True, False, False, 'K_F7', Nil, SP_MenuActionProcs.FPMenu_SingleStep));
  FPRunMenu.AddItem(CreateItem('S&tep over', True, True, False, False, 'K_F8', Nil, SP_MenuActionProcs.FPMenu_StepOver));
  FPRunMenu.AddItem(CreateItem('C&ONTINUE to cursor', True, True, False, False, 'K_SHIFT,K_F4', Nil, SP_MenuActionProcs.FPMenu_CONTINUE_Cursor));
  FPRunMenu.AddItem(CreateItem('Add &breakpoint...', True, True, False, False, 'K_CTRL,K_N', Nil, SP_MenuActionProcs.FPMenu_BreakpointAdd));
  FPRunMenu.AddItem(CreateItem('Add &watch...', True, True, False, False, 'K_CTRL,K_W', Nil, SP_MenuActionProcs.FPMenu_AddWatch));

  // Tools menu

  FPToolsMenu.AddItem(CreateItem('&Dialog creator', False, True, False, False, '', Nil, Nil));
  FPToolsMenu.AddItem(CreateItem('&Palette editor', False, True, False, False, '', Nil, Nil));
  FPToolsMenu.AddItem(CreateItem('&Sprite editor', False, True, False, False, '', Nil, Nil));
  FPToolsMenu.AddItem(CreateItem('&Font editor', False, True, False, False, '', Nil, Nil));
  FPToolsMenu.AddItem(CreateItem('&ASCII Table', False, True, False, False, '', Nil, Nil));
  FPToolsMenu.AddItem(CreateItem('&Renumber...', False, True, False, False, '', Nil, Nil));

  // Help menu

  FPHelpMenu.AddItem(CreateItem('&Contents', False, True, False, False, 'K_F1', Nil, Nil));
  FPHelpMenu.AddItem(CreateItem('&Keyword help', False, True, False, False, 'K_CTRL,K_F1', Nil, Nil));
  FPHelpMenu.AddItem(CreateItem('-', True, True, False, False, '', Nil, Nil));
  FPHelpMenu.AddItem(CreateItem('&About', False, True, False, False, '', Nil, Nil));

  FPEditorStatusLabel := SP_Label.Create(FPMenu);
  FPEditorStatusLabel.SetBounds(FPMenu.Width - Integer(BSize), 3, 0, 0);
  FPEditorStatusLabel.Anchors := [aTop, aRight];
  FPEditorStatusLabel.AutoSize := True;
  FPEditorStatusLabel.TextAlign := 0;
  FPEditorStatusLabel.TextJustify := 1;

  SP_GetWindowDetails(DWWindowID, Win, Error);
  FPDirectStatusLabel := SP_Label.Create(Win^.Component);
  FPDirectStatusLabel.SetBounds(FPStripePos - FPFw, 1, 0, 0);
  FPDirectStatusLabel.Anchors := [aTop, aRight];
  FPDirectStatusLabel.AutoSize := True;
  FPDirectStatusLabel.TextAlign := 0;
  FPDirectStatusLabel.TextJustify := 1;

End;

Procedure UpdateStatusLabel;
Var
  i, j, Ink, CLINE, CSTATEMENT: Integer;
  cap: aString;
  li: TSP_GOSUB_Item;
Begin

  If INSERT then cap := 'INS' else cap := 'OVR';

  If FocusedWindow = fwEditor Then
    cap := 'L' + IntToString(Listing.FPCLine +1) + ',C' + IntToString(Listing.FPCPos) + ' ' + cap
  Else
    cap := 'C' + IntToString(CURSORPOS) + ' ' + cap;

  Ink := 7;// * Ord(FocusedWindow <> fwEditor);
  If PROGSTATE = SP_PR_RUN Then i := 12 Else i := Ink;

  Li := SP_ConvertLineStatement(CONTLINE, CONTSTATEMENT);
  CLINE := Li.Line;
  CSTATEMENT := Li.St;

  If CLINE = -1 Then
    j := 0
  Else
    j := pLongWord(@SP_Program[CLINE][2])^;

  If j = 0 Then
    cap := #16 + LongWordToString(Ink) + '[-:-] ' + cap
  Else
    cap := #16 + LongWordToString(Ink) + '[' + #16 + LongWordToString(i) + IntToString(j) + ':' + IntToString(CSTATEMENT) + #16 + LongWordToString(Ink) + '] ' + cap;

  If FocusedWindow = fwEditor Then Begin
    FPDirectStatusLabel.Caption := cap;
    FPEditorStatusLabel.Caption := ''
  End Else Begin
    FPDirectStatusLabel.Caption := cap;
    FPEditorStatusLabel.Caption := '';
  End;

End;

Class Procedure SP_MenuActionProcs.FPMenu_Edit_PopUp(Sender: SP_BaseComponent);
Begin
  With SP_FindNextItem Do Begin
    Enabled := FPSearchTerm <> '';
    If Enabled Then Begin
      If LastFindwasReplace Then
        Caption := 'Replace ne&xt'
      Else
        Caption := 'Find ne&xt';
    End Else
      Caption := 'Find ne&xt';
  End;
  SP_GotoErrorItem.Enabled := LASTERRORLINE >= 0;
End;

Class Procedure SP_MenuActionProcs.FPMenu_NEW(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clInterpretCommand, 'NEW');
End;

Class Procedure SP_MenuActionProcs.FPMenu_LOADQQ(Sender: SP_BaseComponent);
begin
  AddControlMsg(clInterpretCommand, 'LOAD ""');
end;

Class Procedure SP_MenuActionProcs.FPMenu_MERGEQQ(Sender: SP_BaseComponent);
begin
  AddControlMsg(clInterpretCommand, 'MERGE ""');
end;

Class Procedure SP_MenuActionProcs.FPMenu_SAVE(Sender: SP_BaseComponent);
begin
  AddControlMsg(clInterpretCommand, 'SAVE "' + PROGNAME + '"');
end;

Class Procedure SP_MenuActionProcs.FPMenu_SAVEQQ(Sender: SP_BaseComponent);
begin
  AddControlMsg(clInterpretCommand, 'SAVE ""');
end;

Class Procedure SP_MenuActionProcs.FPMenu_QUIT(Sender: SP_BaseComponent);
begin
  AddControlMsg(clInterpretCommand, 'QUIT');
end;

Class Procedure SP_MenuActionProcs.FPMenu_Recent(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clInterpretCommand, 'LOAD "' + SP_RecentFiles[SP_MenuItem(Sender).Tag] + '"');
End;

Class Procedure SP_MenuActionProcs.FPMenu_Undo(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL)+'Z');
End;

Class Procedure SP_MenuActionProcs.FPMenu_Redo(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL)+aChar(K_SHIFT)+'Z');
End;

Class Procedure SP_MenuActionProcs.FPMenu_Cut(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL)+'X');
End;

Class Procedure SP_MenuActionProcs.FPMenu_Copy(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL)+'C');
End;

Class Procedure SP_MenuActionProcs.FPMenu_Paste(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL)+'V');
End;

Class Procedure SP_MenuActionProcs.FPMenu_Delete(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_DELETE));
End;

Class Procedure SP_MenuActionProcs.FPMenu_SelAll(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL)+'A');
End;

Class Procedure SP_MenuActionProcs.FPMenu_SelNone(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL)+'N');
End;

Class Procedure SP_MenuActionProcs.FPMenu_Find(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL)+'F');
End;

Class Procedure SP_MenuActionProcs.FPMenu_FindNext(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_F3));
End;

Class Procedure SP_MenuActionProcs.FPMenu_Replace(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL)+'R');
End;

Class Procedure SP_MenuActionProcs.FPMenu_GOTOLine(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL)+'G');
End;

Class Procedure SP_MenuActionProcs.FPMenu_GOTOError(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL)+aChar(K_SHIFT)+'G');
End;

Class Procedure SP_MenuActionProcs.FPMenu_MarkerSetPopUp(Sender: SP_BaseComponent);
Var
  i: Integer;
Begin
  With (Sender as SP_PopUpMenu) Do
    For i := 0 To Count -1 Do
      MenuItems[i].Checked := EditorMarks[i] <> 0;
End;

Class Procedure SP_MenuActionProcs.FPMenu_MarkerJumpPopUp(Sender: SP_BaseComponent);
Var
  i: Integer;
Begin
  With (Sender as SP_PopUpMenu) Do
    For i := 0 To Count -1 Do
      MenuItems[i].Enabled := EditorMarks[i] <> 0;
End;

Class Procedure SP_MenuActionProcs.FPMenu_SetMarker(Sender: SP_BaseComponent);
Begin
  SP_ToggleEditorMark(SP_MenuItem(Sender).Tag);
  SP_DisplayFPListing(-1);
End;

Class Procedure SP_MenuActionProcs.FPMenu_JumpMarker(Sender: SP_BaseComponent);
Var
  Cy: Integer;
Begin
  cy := Listing.FPCLine;
  SP_JumpToMark(SP_MenuItem(Sender).Tag);
  SP_CalculateFPCursorPos;
  SP_CursorPosChanged;
  SP_DrawGraphicsID;
  SP_RefreshCursorLineAfterChange(Cy);
  SP_ScrollInView;
End;

Class Procedure SP_MenuActionProcs.FPMenu_ClearMarkers(Sender: SP_BaseComponent);
Var
  i: Integer;
Begin
  For i := 0 To 9 Do
    EditorMarks[i] := 0;
  SP_DisplayFPListing(-1);
End;

Class Procedure SP_MenuActionProcs.FPMenu_View_Popup(Sender: SP_BaseComponent);
Begin
  If FocusedWindow = fwDirect then
    SP_SwitchMenuItem.Caption := '&Switch to Editor'
  Else
    SP_SwitchMenuItem.Caption := '&Switch to Direct command';
  If FPDebugPanelVisible Then
    SP_DebugPanelItem.Caption := 'Hide &debug panel'
  Else
    SP_DebugPanelItem.Caption := 'Show &debug panel';
End;

Class Procedure SP_MenuActionProcs.FPMenu_Switch(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_ESCAPE));
End;

Class Procedure SP_MenuActionProcs.FPMenu_ShowScreen(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL)+aChar(K_SHIFT)+aChar(K_RETURN));
End;

Class Procedure SP_MenuActionProcs.FPMenu_RUN(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_F9));
End;

Class Procedure SP_MenuActionProcs.FPMenu_CONTINUE(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_SHIFT)+aChar(K_F9));
End;

Class Procedure SP_MenuActionProcs.FPMenu_GOTO(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_SHIFT)+aChar(K_F10));
End;

Class Procedure SP_MenuActionProcs.FPMenu_SingleStep(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_F7));
End;

Class Procedure SP_MenuActionProcs.FPMenu_StepOver(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_F8));
End;

Class Procedure SP_MenuActionProcs.FPMenu_CONTINUE_Cursor(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_SHIFT) + aChar(K_F4));
End;

Class Procedure SP_MenuActionProcs.FPMenu_DebugPanel(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL) + aChar(K_B));
End;

Class Procedure SP_MenuActionProcs.FPMenu_BreakpointAdd(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL) + aChar(K_N));
End;

Class Procedure SP_MenuActionProcs.FPMenu_AddWatch(Sender: SP_BaseComponent);
Begin
  AddControlMsg(clKeyPress, aChar(K_CONTROL) + aChar(K_W));
End;

Class Procedure SP_MenuActionProcs.GrabberMouseDown(X, Y, Btn: Integer);
Begin
  DisplaySection.Leave;
  AddControlMsg(clGrabberMouseDown, LongWordToString(MOUSEX));
End;

Class Procedure SP_MenuActionProcs.GrabberMouseMove(X, Y, Btn: Integer);
Begin
  DisplaySection.Leave;
  AddControlMsg(clGrabberMouseMove, LongWordToString(MOUSEX));
End;

Class Procedure SP_MenuActionProcs.GrabberMouseUp(X, Y, Btn: Integer);
Begin
  DisplaySection.Leave;
  AddControlMsg(clGrabberMouseUp, '');
End;

Class Procedure SP_MenuActionProcs.FPMenu_FullScreen(Sender: SP_BaseComponent);
Begin
  If SPFULLSCREEN Then Begin
    SP_FullScreenMenuItem.Caption := 'Full screen';
    AddControlMsg(clInterpretCommand, 'SCREEN WINDOW');
  End Else Begin
    SP_FullScreenMenuItem.Caption := 'Windowed';
    AddControlMsg(clInterpretCommand, 'SCREEN FULL');
  End;
End;

end.
