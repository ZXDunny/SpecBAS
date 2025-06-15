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

unit SP_Components;

interface

Uses Types, SysUtils, System.Generics.Collections, Classes, SyncObjs, Math, ClipBrd, SP_SysVars, SP_FileIO, SP_Util,
     SP_ButtonUnit, SP_BaseComponentUnit, SP_Errors;

// A collection of UI elements for building UI apps. Based on Windows controls.

// *SP_Edit - descendent of SP_Memo, inherits its abilities such as clipboard support etc
// *SP_CheckBox
// *SP_Listbox - can contain headers for multiple columns
// *SP_Scrollbar
// *SP_Button
// *SP_PopUpMenu - right-click on a control and if a popupmenu is assigned it will show.
// *SP_WindowMenu - always present bar menu at the top of a window
// *SP_Label - multiline text capable
// *SP_Container - visually a box with a caption, border and then components inside
// *SP_RadioGroup
// *SP_CheckList - a list of checkboxes
// *SP_Slider - user manipulable scrollbar that fills as the value increases. Vertical or horizontal.
// *SP_Combobox - SP_EditBox with SP_PopupMenu attached. Can be read-only, or editable
// *SP_ProgressBar - non-interactive slider type with customisable fill graphic (character?)
// SP_Memo - a memo control, can be a single line (an Edit box), optional BASIC editor
// SP_TreeView
// SP_TabBar - A tab list (bottom or top of window) with an SP_Container for each tab

// Components can be added to windows or other components. If added to another component, they will render to that component's
// canvas. No need to free components, deleting their window will handle it.

Type

// Base component events and variables


SP_TimerEvent = Record

  ID: Integer;
  Sender: TObject;
  OneShot: Boolean;
  Interval: Integer;
  NextFrameTime: Integer;
  ObjectProc: SP_TimerProc;

End;
pSP_TimerEvent = ^SP_TimerEvent;

Procedure AddOverrideControl(c: SP_BaseComponent);
Procedure DeleteOverrideControl(c: SP_BaseComponent);
Function  ControlsAreInUse: Boolean;
Function  ControlKeyEvent(aStr: aString; Key: Integer; Down, IsKey: Boolean): Boolean;

Function  WindowAtPoint(Var x, y, ID: Integer): Pointer;
Function  ControlAtPoint(Window: Pointer; Var x, y: Integer): pSP_BaseComponent;
Function  TestForWindowMenu(Win: Pointer; Var Shift: TShiftState): Boolean;

Procedure DoTimerEvents;
Procedure ClearTimerEvents(InRegistry: Boolean = False);
Function  AddTimer(Sender: TObject; Interval: Integer; ObjProc: SP_TimerProc; DoNow, OneShot: Boolean): pSP_TimerEvent;
Procedure RemoveTimer(Sender: TObject); Overload;
Procedure RemoveTimer(Var ID: Integer); Overload;

Function  SP_CreateControl(ParentID, cClass, X, Y, W, H: Integer; Var Error: TSP_ErrorCode): Integer;
Procedure SP_HaltAllControls;
Function  SP_IsInRegistry(C: SP_BaseComponent): Boolean;
Function  SP_CanInteract(C: SP_BaseComponent): Boolean;

Const

  SP_UIHighlight                  = 250;
  SP_UIHalfLight                  = 249;
  SP_UI_HalfShadow                = 234;
  SP_UIShadow                     = 240;
  SP_UIBtnBack                    = 248;
  SP_UIBtnBackFocus               = 248;
  SP_UIText                       = 0;
  SP_UITextDisabled               = 8;
  SP_UITrack                      = 244;
  SP_UISelection                  = 5;
  SP_UISelectionOutline           = 9;
  SP_UISelectionUnfocusedOutline  = 0;
  SP_UIUnfocusedSelection         = 8;
  SP_UIBorder                     = 0;
  SP_UIBackground                 = 7;
  SP_UIMenuSeparator              = 8;
  SP_UIScrollThumb                = 0;
  SP_UIScrollTrack                = 8;
  SP_UIScrollBtn                  = 0;
  SP_UIWindowBack                 = 244;
  SP_FocusTextClr                 = 0;

  SP_ScrollWheelValue             = 3;

  SP_LeftJustify                  = -1;
  SP_CentreJustify                = 0;
  SP_RightJustify                 = 1;

  Seps = [' ', '(', ')', ',', ';', #39, '=', '+', '-', '/', '*', '^', '%', '$', '|', '&', ':', '>', '<'];

Var

  ControlSection: TCriticalSection;
  CaptureControl: SP_BaseComponent;
  FocusedControl: SP_BaseComponent;
  MouseControl:   SP_BaseComponent;
  ForceCapture: Boolean;
  TimerSection: TCriticalSection;
  TimerList: Array of SP_TimerEvent;
  cKeyRepeat: Integer;
  cLastKey, cLastKeyChar: Byte;
  GlobalControlCount: Integer;
  OverrideControls: Array of SP_BaseComponent;
  cKEYSTATE: Array[0..255] of Byte;
  ControlRegistry: TDictionary<Cardinal, SP_BaseComponent>;
  NextControlID: LongWord;

implementation

Uses SP_Main, SP_Sound, SP_BankManager, SP_BankFiling, SP_Graphics, SP_Graphics32, SP_Input, SP_Tokenise, SP_Interpret_PostFix,
     SP_PopupMenuUnit, SP_WindowMenuUnit, SP_CheckBoxUnit, SP_ComboBoxUnit, SP_RadioGroupUnit, SP_CheckListUnit, SP_ContainerUnit, SP_EditUnit,
     SP_ListBoxUnit, SP_FileListBoxUnit, SP_LabelUnit, SP_ProgressBarUnit, SP_ScrollBarUnit, SP_SliderUnit;

// Timer Functions

Procedure ClearTimerEvents(InRegistry: Boolean);
Var
  i: Integer;
Begin

  TimerSection.Enter;
  If InRegistry Then Begin
    i := 0;
    While i < Length(TimerList) Do
      If Assigned(TimerList[i].Sender) And (TimerList[i].Sender is SP_BaseComponent) And
         SP_IsInRegistry(SP_BaseComponent(TimerList[i].Sender)) Then
        RemoveTimer(TimerList[i].Sender)
      Else
        Inc(i);
  End Else
    SetLength(TimerList, 0);
  TimerSection.Leave;

End;

Procedure DoTimerEvents;
Var
  i: Integer;
Begin

  TimerSection.Enter;

  i := 0;
  While i < Length(TimerList) Do Begin
    With TimerList[i] Do Begin
      If (NextFrameTime > 0) And (NextFrameTime <= Integer(FRAMES)) Then Begin
        If OneShot Then
          NextFrameTime := 0
        Else
          Inc(NextFrameTime, Interval);
        If Assigned(ObjectProc) Then Begin
          TimerSection.Leave;
          ObjectProc(@TimerList[i]);
          TimerSection.Enter;
        End;
      End;
    End;
    Inc(i);
  End;

  TimerSection.Leave;

End;

Function AddTimer(Sender: TObject; Interval: Integer; ObjProc: SP_TimerProc; DoNow, OneShot: Boolean): pSP_TimerEvent;
Var
  l, Id, i: Integer;
Begin

  TimerSection.Enter;

  l := Length(TimerList);
  SetLength(TimerList, l +1);
  TimerList[l].ID := -1;
  TimerList[l].Sender := Sender;
  TimerList[l].Interval := Interval;
  TimerList[l].NextFrameTime := Integer(FRAMES) + Interval;
  TimerList[l].OneShot := OneShot;
  TimerList[l].ObjectProc := ObjProc;

  Id := 0;
  i := 0;
  While i < Length(TimerList) Do Begin
    If TimerList[i].ID = Id Then Begin
      Inc(Id);
      i := 0;
    End Else
      Inc(i);
  End;
  TimerList[l].ID := Id;
  Result := @TimerList[l];

  TimerSection.Leave;

  If DoNow Then
    ObjProc(Result);

End;

Procedure RemoveTimer(Sender: TObject);
Var
  i, j: Integer;
Begin

  TimerSection.Enter;

  i := 0;
  While i < Length(TimerList) Do Begin
    If TimerList[i].Sender = Sender Then Begin
      For j := i To Length(TimerList) -2 Do
        TimerList[j] := TimerList[j +1];
      SetLength(TimerList, Length(TimerList) -1);
    End;
    Inc(i);
  End;

  TimerSection.Leave;

End;

Procedure RemoveTimer(Var ID: Integer);
Var
  i, j: Integer;
Begin

  TimerSection.Enter;

  i := 0;
  While i < Length(TimerList) Do Begin
    If TimerList[i].ID = ID Then Begin
      For j := i To Length(TimerList) -2 Do
        TimerList[j] := TimerList[j +1];
      SetLength(TimerList, Length(TimerList) -1);
    End;
    Inc(i);
  End;

  ID := -1;

  TimerSection.Leave;

End;

// Helper Procs for key events

Procedure DeleteOverrideControl(c: SP_BaseComponent);
Var
  i, l: Integer;
Begin
  i := 0;
  l := Length(OverrideControls);
  While i < l Do Begin
    If OverrideControls[i] = c Then Begin
      For i := i To l -2 Do
        OverrideControls[i] := OverrideControls[i +1];
      SetLength(OverrideControls, l -1);
      Exit;
    End Else
      Inc(i);
  End;
End;

Procedure AddOverrideControl(c: SP_BaseComponent);
var
  i, l: Integer;
Begin
  i := 0;
  l := Length(OverrideControls);
  While i < l Do Begin
    If OverrideControls[i] = c Then Begin
      DeleteOverrideControl(c);
      Dec(l);
      Break;
    End Else
      Inc(i);
  End;
  SetLength(OverrideControls, l +1);
  OverrideControls[l] := c;
End;

Function ControlsAreInUse: Boolean;
Begin

  Result := GlobalControlCount > 0;

End;

Function GetOwnerControl(c: SP_BaseComponent): SP_BaseComponent;
Begin

  Result := c;
  While Assigned(Result.fParentControl) And (Result.fParentType = spControl) Do
    Result := Result.fParentControl;

End;

Function IsVisible(Ctrl: SP_BaseComponent): Boolean;
Var
  Win: pSP_Window_Info;
  Error: TSP_ErrorCode;
Begin

  If not ctrl.Visible Then
    Result := False
  Else
    If ctrl.fParentType = spControl then
      Result := IsVisible(ctrl.fParentControl)
    Else Begin
      SP_GetWindowDetails(ctrl.fParentWindowID, Win, Error);
      Result := Win^.Visible;
    End;

End;

Function ControlKeyEvent(aStr: aString; Key: Integer; Down, IsKey: Boolean): Boolean;
Var
  i, j, w: Integer;
  c: SP_BaseComponent;
  cList: Array of SP_BaseComponent;
  windows: Array of Integer;

  Procedure AddComp(c: SP_BaseComponent);
  Var
    l: Integer;
  Begin

    l := Length(cList);
    SetLength(cList, l +1);
    clist[l] := c;

  End;

  Function IsCompInList(c: SP_BaseComponent): Boolean;
  Var
    i: Integer;
  Begin

    Result := False;
    i := 0;
    While i < Length(cList) Do Begin
      If cList[i] = c Then Begin
        Result := True;
        Exit;
      End Else
        Inc(i);
    End;

  End;

  Function SendKey(var ctrl: SP_BaseComponent): Boolean;
  Begin
    Result := False;
    If IsVisible(ctrl) And (ctrl = focusedcontrol) And SP_CanInteract(ctrl) then
      If Down Then Begin
        cLastKeyChar := Ord(aStr[1]);
        cLastKey := Key;
        If IsKey Then cKEYSTATE[Key] := 1;
        ctrl.KeyDown(Key, Result);
      End Else Begin
        cLastKey := Key;
        If IsKey then cKEYSTATE[Key] := 0;
        ctrl.KeyUp(Key, Result);
        If Result Then Begin
          cLastKeyChar := 0;
          cLastKey := 0;
        End;
      End;
  End;

Begin

  Result := False;

  // First handle overrides - controls that get first look at key messages. Currently these are
  // Window menus and popupmenus, for the ALT accelerators.

  If IsKey Then cKEYSTATE[Key] := Ord(Down);
  i := Length(OverrideControls) -1;
  if i >= 0 Then Begin
    If ModalWindow > -1 Then Begin
      SetLength(windows, 1);
      windows[0] := ModalWindow;
    End Else
      If SYSTEMSTATE in [SS_EDITOR, SS_DIRECT] Then Begin
        SetLength(windows, 2);
        Windows[0] := fwEditor;
        WIndows[1] := fwDirect;
      End Else Begin
        SetLength(windows, 1);
        windows[0] := FocusedWindow;
      End;

    While i >= 0 Do Begin
      c := OverrideControls[i];
      w := c.ParentWindowID;
      For j := 0 To High(windows) do
        If w = Windows[j] Then Begin
          if (c is SP_PopupMenu) And SP_CanInteract(c) Then
            Result := SP_PopUpMenu(c).CheckShortcuts;
          If Result Then
            Exit
          Else
            if c.Visible Then Begin
              Result := SendKey(c);
              If Result And (Key <> K_ALT) Then Exit;
            End;
        End;
      Dec(i);
    End;
    if Result Then Exit;
  End;

  // Now, if we didn't trigger any overrides, we hand the key message to the active control. If that doesn't handle it,
  // we drop down through the hierarchy.
  If Assigned(FocusedControl) Then Begin

    Result := SendKey(FocusedControl);

    If Not Result Then Begin

      c := GetOwnerControl(FocusedControl);

      While Not Result Do Begin

        AddComp(c);
{        If Down and c.Canfocus Then
          c.SetFocus(True);}

        Result := SendKey(c);
        If Not Result Then
          If Assigned(c.ChainControl) And Not IsCompInList(c.ChainControl) Then
            c := c.ChainControl
          Else
            Exit;

      End;

    End;

  end Else Begin

    // If there is no focused control then just set our lastkey variables so that
    // any controls that are idle processing can pick them up. This can be popupmenus or windowmenus currently as they
    // don't steal focus.

    If Down Then Begin
      cLastKeyChar := Ord(aStr[1]);
      cLastKey := Key;
      If IsKey Then cKEYSTATE[Key] := 1;
    End Else Begin
      If IsKey Then cKEYSTATE[Key] := 0;
      cLastKeyChar := 0;
      cLastKey := 0;
    End;
    Exit;
  End;

End;

// Helper procs for mouse work

Function TestForWindowMenu(Win: Pointer; Var Shift: TShiftState): Boolean;
Var
  i: Integer;
  cp: pSP_BaseComponent;

  Function CheckForMenu(Var c: pSP_BaseComponent): pSP_BaseComponent;
  Var
    i: Integer;
    ct: pSP_BaseComponent;
  Begin
    i := 0;
    Result := nil;
    While i < c^.ControlCount Do Begin
      ct := @c^.fComponentList[i];
      If Assigned(ct) then Begin
        If (ct^ Is SP_WindowMenu) And Not SP_WindowMenu(ct^).Permanent Then
          Result := ct
        Else
          If ct^.ControlCount > 0 Then
            Result := CheckForMenu(ct);
        If Assigned(Result) Then
          Exit
        Else
          Inc(i);
      End Else
        Inc(i);
    End;
  End;

Begin

  // if the right mouse button is down and this window has a non-permanent WindowMenu, show it now.

  Result := False;
  If Assigned(Win) Then Begin
    With pSP_Window_Info(Win)^ Do
      If Component.ControlCount > 0 Then Begin
        cp := @Component;
        cp := CheckForMenu(cp);
        If Assigned(cp) Then With pSP_WindowMenu(cp)^ Do Begin
          if ssRight in Shift Then Begin
            Visible := True;
            cp^.SetFocus(True);
          End Else
            If Not ((ssLeft in Shift) or (ssMiddle in Shift)) Then
              Visible := False;
        End;
      End;
  End Else Begin
    i := Length(SP_BankList) -1;
    While i >= 0 Do Begin
      If (Length(SP_BankList[i]^.Info) > 0) and (SP_BankList[i]^.DataType = SP_WINDOW_BANK) Then Begin
        Win := @SP_BankList[i]^.Info[0];
        Result := Result Or TestForWindowMenu(Win, Shift);
      End;
      Dec(i);
    End;
  End;

End;

Function WindowAtPoint(Var x, y, ID: Integer): Pointer;
Var
  Idx: Integer;
Label
  GotWindow;
Begin

  Result := nil;

  If MODALWINDOW > -1 Then Begin
    Idx := SP_FindBankID(MODALWINDOW);
    If Idx = -1 Then Exit;
    Result := @SP_BankList[Idx]^.Info[0];
    Goto GotWindow;
  End Else
    If (x >= 0) And (x < Integer(DISPLAYWIDTH)) And (y >= 0) And (y < Integer(DISPLAYHEIGHT)) Then Begin
      Idx := Length(SP_BankList) -1;
      While Idx >= 0 Do Begin
        If Length(SP_BankList[Idx]^.Info) > 0 Then Begin
          Result := @SP_BankList[Idx]^.Info[0];
          GotWindow:
          If SP_BankList[Idx]^.DataType = SP_WINDOW_BANK then With pSP_Window_Info(Result)^ Do
            If PtInRect(Rect(Left, Top, Left + Width, Top + Height), Point(X, Y)) Then Begin
              Dec(X, Left);
              Dec(Y, Top);
              ID := SP_BankList[Idx].ID;
              Exit;
            End;
        End;
        Dec(Idx);
      End;
    End;

End;

Function ControlAtPoint(Window: Pointer; Var x, y: Integer): pSP_BaseComponent;
Var
  cp: pSP_BaseComponent;
  Idx, lt, tp: Integer;

  Function CheckChildren(c: pSP_BaseComponent; Var x, y: Integer): pSP_BaseComponent;
  Var
    i, l, t: Integer;
    ct: pSP_BaseComponent;
  Begin
    i := 0;
    Result := c;
    While i < c^.ControlCount Do Begin
      ct := @c^.fComponentList[i];
      If Assigned(ct) then Begin
        l := ct^.Left;
        t := ct^.Top;
        If PtInRect(Rect(l, t, l+ct^.width, t+ct^.height), Point(x, y)) And ct^.Visible Then Begin
          Dec(x, l); Dec(y, t);
          Result := CheckChildren(ct, x, y);
          Exit;
        End Else
          Inc(i);
      End Else
        Inc(i);
    End;
  End;

Begin

  With pSP_Window_Info(Window)^ Do
    If Component.ControlCount > 0 Then Begin
      Idx := 0;
      While Idx < Component.ControlCount Do Begin
        cp := @Component.fComponentList[Idx];
        If Assigned(cp) Then Begin
          lt := cp^.Left;
          tp := cp^.Top;
          If PtInRect(Rect(Lt, Tp, lt+cp^.width, tp+cp^.height), Point(x, y)) And cp^.Visible Then Begin
            Dec(x, lt); Dec(y, tp);
            Result := CheckChildren(cp, x, y);
            Exit;
          End Else
            Inc(Idx);
        End Else
          Inc(Idx);
      End;
    End;

  Result := Nil;

End;

// User runtime control management

Function SP_GetNextControlID: LongWord;
Begin

  Result := NextControlID;
  Inc(NextControlID);

End;

Procedure SP_HaltAllControls;
Var
  i: Integer;
Begin

  SP_ClearOnEvents;
  ClearTimerEvents(True);
  For i := 0 To High(cKEYSTATE) Do
    cKEYSTATE[i] := 0;
  cLastKey := 0;
  cLastKeyChar := 0;

End;

Function SP_IsInRegistry(C: SP_BaseComponent): Boolean;
Var
  Control: SP_BaseComponent;
Begin

  Result := ControlRegistry.TryGetValue(c.fIDNumber, Control);
  If Not Result Then
    If C.fParentType = spControl then
      Result := SP_IsInRegistry(C.fParentControl);

End;

Function SP_CanInteract(C: SP_BaseComponent): Boolean;
Begin

  Result := True;

  If SP_IsInRegistry(C) Then
    Result := PROGSTATE = SP_PR_RUN;

End;

Function SP_CreateControl(ParentID, cClass, X, Y, W, H: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Control, Parent: SP_BaseComponent;
  Win: pSP_Window_Info;
Begin

  Result := -1;
  Control := nil;

  If ParentID <= 0 Then Begin
    // negative (or 0) parentID is a window, but negative
    If ParentID = -65535 Then
      SP_GetWindowDetails(SCREENBANK, Win, Error)
    Else
      SP_GetWindowDetails(-ParentID, Win, Error);
    Parent := Win^.Component;
  End Else
    // positive parentID is another control.
    If Not ControlRegistry.TryGetValue(ParentID, Parent) Then
      Error.Code := SP_ERR_INVALID_COMPONENT;

  If Error.Code = SP_ERR_OK Then Begin
    Case cClass of
      spButton:
        Begin
          Control := SP_Button.Create(Parent);
        End;
      spCheckBox:
        Begin
          Control := SP_CheckBox.Create(Parent);
        End;
      spComboBox:
        Begin
          Control := SP_ComboBox.Create(Parent);
        End;
      spRadioGroup:
        Begin
          Control := SP_RadioGroup.Create(Parent);
        End;
      spCheckList:
        Begin
          Control := SP_CheckList.Create(Parent);
        End;
      spContainer:
        Begin
          Control := SP_Container.Create(Parent);
        End;
      spEdit:
        Begin
          Control := SP_Edit.Create(Parent);
        End;
      spList:
        Begin
          Control := SP_ListBox.Create(Parent);
        End;
      spFileList:
        Begin
          Control := SP_FileListBox.Create(Parent);
        End;
      spLabel:
        Begin
          Control := SP_Label.Create(Parent);
        End;
      spProgress:
        Begin
          Control := SP_ProgressBar.Create(Parent);
        End;
      spScrollBar:
        Begin
          Control := SP_ScrollBar.Create(Parent);
        End;
      spWindowMenu:
        Begin
          Control := SP_WindowMenu.Create(Parent);
        End;
      spPopUpMenu:
        Begin
          Control := SP_PopUpMenu.Create(Parent, nil);
        End;
      spSlider:
        Begin
          Control := SP_Slider.Create(Parent);
        End;
    End;
    If Assigned(Control) Then Begin
      Control.fIDNumber := SP_GetNextControlID;
      Control.SetBounds(x, y, w, h);
      Result := Control.fIDNumber;
      ControlRegistry.Add(Result, Control);
    End;
  End;

End;

Initialization

  ControlSection := TCriticalSection.Create;
  TimerSection := TCriticalSection.Create;
  GlobalControlCount := 0;
  NextControlID := 1;
  ControlRegistry := TDictionary<Cardinal, SP_BaseComponent>.Create;

Finalization

  ControlSection.Free;
  TimerSection.Free;
  ControlRegistry.Free;

end.
