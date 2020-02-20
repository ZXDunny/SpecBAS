unit SP_DebugPanel;

interface

uses Math, Classes, SP_Util, SP_BaseComponentUnit, SP_ListBoxUnit, SP_ComboBoxUnit, SP_ControlMsgs, SP_ButtonUnit, SP_Input, SP_ContainerUnit;

Type

  SP_DebugPanelActionProcs = Class

  Public

    Class Procedure PanelSwitch(Sender: SP_BaseComponent; Text: aString);
    Class Procedure DblClick(Sender: SP_BaseComponent; Index: Integer; Text: aString);
    Class Procedure PanelSelect(Sender: SP_BaseComponent; Index: Integer);
    Class Procedure ButtonClick(Sender: SP_BaseComponent);

  End;

Procedure SP_OpenDebugPanel;
Procedure SP_CloseDebugPanel;
Procedure SP_FillDebugPanel;
Procedure SP_ResizeDebugPanel(X: Integer);

var

  FPDebugPanel: SP_ListBox;
  FPDebugCombo: SP_ComboBox;
  FPSizeGrabber: SP_Container;
  FPResizingDebugPanel: Boolean;
  FPDebugPanelVisible: Boolean;
  FPDebugPanelWidth: Integer;
  FPDebugLastMouseX: Integer;
  FPDebugPanelMode: Integer;
  FPDebugBPAdd,
  FPDebugBPDel,
  FPDebugBPEdt: SP_Button;

implementation

Uses SP_FPEditor, SP_Errors, SP_Graphics, SP_BankManager, SP_BankFiling, SP_SysVars, SP_Components, SP_Variables, SP_AnsiStringList,
     SP_Interpret_PostFix, SP_FileIO, SP_Main, SP_MenuActions;

Procedure SP_UpdateAfterDebug;
Begin

  FPPaperWidth := FPClientWidth - (BSize * 3) - Fw - ((FPDebugPanelWidth + BSize) * Ord(FPDebugPanelVisible));
  SP_FPWrapProgram;
  SP_AddFPScrollBars(False);
  SP_Decorate_Window(FPWindowID, 'Program listing - ' + SP_GetProgName(PROGNAME, True), True, False, FocusedWindow = fwEditor);
  SP_DisplayFPListing(-1);

End;

Procedure SP_ResizeDebugPanel(X: Integer);
Var
  Delta: Integer;
  Win: pSP_Window_Info;
  Error: TSP_ErrorCode;
Begin

  Delta := FPDebugLastMouseX - X;
  If Delta <> 0 Then Begin
    Inc(FPDebugPanelWidth, Delta);
    If (FPDebugPanelWidth >= 100) And (FPDebugPanelWidth < FPClientWidth - (FPClientWidth Div 4)) Then
      FPDebugLastMouseX := X
    Else
      If FPDebugPanelWidth < 100 Then Begin
        Delta := 0;
        FPDebugPanelWidth := 100
      End Else Begin
        FPDebugPanelWidth := FPClientWidth - (FPClientWidth Div 4);
        Delta := 0;
      End;

    If Delta <> 0 Then Begin
      SP_GetWindowDetails(FPWindowID, Win, Error);
      FPDebugCombo.SetBounds(Win^.Width - BSize - FPDebugPanelWidth, FPClientTop + BSize, Trunc(FPDebugPanelWidth * EDFONTSCALEX), FH);
      FPDebugPanel.SetBounds(FPDebugCombo.Left, FPDebugPanel.Top, FPDebugPanelWidth, FPDebugPanel.Height);
      FPSizeGrabber.SetBounds(FPDebugCombo.Left - BSize, FPDebugCombo.Top, BSize, FPDebugPanel.Height + BSize + FPDebugCombo.Height);
      SP_UpdateAfterDebug;
    End;

  End;

End;

Procedure SP_OpenDebugPanel;
Var
  Error: TSP_ErrorCode;
  Win: pSP_Window_Info;
  FW, FH: Integer;
Begin

  DisplaySection.Enter;

  SP_GetWindowDetails(FPWindowID, Win, Error);
  If Not Assigned(FPDebugPanel) Then Begin
    FPDebugPanel := SP_ListBox.Create(Win^.Component);
    FPDebugCombo := SP_ComboBox.Create(Win^.Component);
    FPSizeGrabber := SP_Container.Create(Win^.Component);
  End;
  FPDebugPanelVisible := True;
  FW := Trunc(FONTWIDTH * EDFONTSCALEX);
  FH := Trunc(FONTHEIGHT * EDFONTSCALEY);

  With FPDebugCombo Do Begin
    BackgroundClr := debugCombo;
    Transparent := False;
    SetBounds(Win^.Width - BSize - FPDebugPanelWidth, FPClientTop + BSize, Trunc(FPDebugPanelWidth * EDFONTSCALEX), FH);
    AddItem('Variables');
    AddItem('Watches');
    AddItem('Breakpoints');
    AddItem('Labels');
    AddItem('Procedures/Functions');
    AddItem('Disassembly');
    AddItem('Program Map');
    CanFocus := False;
    FPDebugPanel.SetBounds(Left, Top + Height + BSize, Width, FPPaperHeight - (Height + BSize));
    FPDebugPanel.BackgroundClr := debugPanel;
    FPDebugPanel.HeaderClr := BackgroundClr;
    FPDebugPanel.Transparent := False;
    FPDebugPanel.CanFocus := False;
    FPDebugPanel.SortByAlpha := True;
    FPDebugPanel.OnChoose := SP_DebugPanelActionProcs.DblClick;
    FPDebugPanel.OnSelect := SP_DebugPanelActionProcs.PanelSelect;
    FPDebugPanel.MultiSelect := False;
    OnChange := SP_DebugPanelActionProcs.PanelSwitch;
    FPDebugBPEdt := SP_Button.Create(Win^.Component);
    FPDebugBPEdt.OnClick := SP_DebugPanelActionProcs.ButtonClick;
    FPDebugBPDel := SP_Button.Create(Win^.Component);
    FPDebugBPDel.OnClick := SP_DebugPanelActionProcs.ButtonClick;
    FPDebugBPAdd := SP_Button.Create(Win^.Component);
    FPDebugBPAdd.OnClick := SP_DebugPanelActionProcs.ButtonClick;
    FPSizeGrabber.SetBounds(Left - BSize, Top, BSize, FPDebugPanel.Height + BSize + Height);
    FPSizeGRabber.Border := False;
    FPSizeGrabber.Caption := '';
    FPSizeGrabber.Erase := True;
    FPSizeGrabber.Transparent := False;
    FPSizeGrabber.OnMouseDown := SP_MenuActionProcs.GrabberMouseDown;
    FPSizeGrabber.OnMouseMove := SP_MenuActionProcs.GrabberMouseMove;
    FPSizeGrabber.OnMouseUp := SP_MenuActionProcs.GrabberMouseUp;

  End;
  FocusedControl := Nil;

  SP_FillDebugPanel;
  SP_UpdateAfterDebug;

  DisplaySection.Leave;

End;

Procedure SP_CloseDebugPanel;
Var
  Error: TSP_ErrorCode;
  Win: pSP_Window_Info;
Begin

  SP_GetWindowDetails(FPWindowID, Win, Error);
  FPDebugPanelVisible := False;
  FPDebugPanel.Free;
  FPDebugPanel := nil;
  FPDebugCombo.Free;
  FPDebugCombo := nil;
  FPDebugBPAdd.Free;
  FPDebugBPDel.Free;
  FPDebugBPEdt.Free;
  FPSizeGrabber.Free;
  FPPaperWidth := FPClientWidth - (BSize * 3) - Fw - ((FPDebugPanelWidth + BSize) * Ord(FPDebugPanelVisible));
  SP_UpdateAfterDebug;

End;

Procedure SP_MakeBreakPointList(var List: TAnsiStringlist);
Var
  i: Integer;

  Function GetBreakPointInfo(Var Bp: TSP_BreakPointInfo): aString;
  Var
    s: aString;
  Begin
    With Bp Do Begin
      Case bpType Of
        BP_Stop:
          Begin
            s := 'S' + #255 + IntToString(Line) + ':' + IntToString(Statement);
            s := s + #255 + IntToString(PassCount) + '/' + IntToString(PassNum);
            If Condition <> '' Then
              s := s + #255 + Condition;
          End;
        BP_Conditional:
          Begin
            s := 'C' + #255 + '-:--';
            s := s + #255 + IntToString(PassCount) + '/' + IntToString(PassNum) + #255 + Condition;
          End;
        BP_Data:
          Begin
            s := 'D' + #255 + '-:--';
            s := s + #255 + IntToString(PassCount) + '/' + IntToString(PassNum) + #255 + Condition;
          End;
      End;
    End;
    Result := s;
  End;

Begin

  List.Clear;

  For i := 0 To Length(SP_SourceBreakPointList) -1 Do Begin
    List.Add(GetBreakPointInfo(SP_SourceBreakPointList[i]));
    List.Objects[List.Count -1] := TObject(@SP_SourceBreakPointList[i]);
  End;

  For i := 0 To Length(SP_ConditionalBreakPointList) -1 Do Begin
    List.Add(GetBreakPointInfo(SP_ConditionalBreakPointList[i]));
    List.Objects[List.Count -1] := TObject(@SP_ConditionalBreakPointList[i]);
  End;

  If List.Count = 0 Then Begin
    List.Add('');
    List.Objects[0] := TObject(-1);
  End;

End;

Procedure SP_FillDebugPanel;
Var
  Changed: Boolean;
  i, MaxW, MaxWC, MaxP, p, j: Integer;
  s, vType, vName, vContent, vExtra, vPass: aString;
  List, OldVars, OldContents, OldWatches, OldExprs: TAnsiStringlist;
  Error: TSP_ErrorCode;
  Hdr: SP_ListBoxHeader;

  Procedure SetButtons;
  Var
    xPos, i: Integer;
    Btn: SP_Button;
    ShowBtns: Boolean;
  Const
    Caps: Array[0..2] of aChar = (#240, '-', '+');
  Begin
    ShowBtns := False;
    FPDebugBPAdd.Visible := False;
    FPDebugBPDel.Visible := False;
    FPDebugBPEdt.Visible := False;
    Case FPDebugCombo.ItemIndex of
      0: // Vars - Hide add/delete button, show edit button.
        Begin
          If FPDebugPanel.Enabled Then Begin
            FPDebugBPEdt.Visible := True;
            ShowBtns := True;
          End;
        End;
      1, 2: // Watches and breakpoints
        Begin
          FPDebugBPAdd.Visible := True;
          If FPDebugPanel.Enabled Then Begin
            FPDebugBPEdt.Visible := True;
            FPDebugBPDel.Visible := True;
          End;
          ShowBtns := True;
        End;
    End;
    If ShowBtns Then
      FPDebugPanel.Height := FPPaperHeight - (FPDebugCombo.Height + BSize) - (FH + BSize * 3)
    Else
      FPDebugPanel.Height := FPPaperHeight - (FPDebugCombo.Height + BSize);
    xPos := FPDebugPanel.Left + FPDebugPanel.Width + BSize;
    For i := 0 to 2 Do Begin
      Case i of
        0: Btn := FPDebugBPEdt;
        1: Btn := FPDebugBPDel;
        2: Btn := FPDebugBPAdd;
      End;
      If Btn.Visible Then Begin
        Dec(xPos, FW + (BSize * 3));
        Btn.SetBounds(xPos, FPDebugPanel.Top + FPDebugPanel.Height + BSize, FW + (BSize * 2), FH + (BSize * 2));
        Btn.Caption := Caps[i];
        Btn.CentreCaption;
      End;
    End;
    FPDebugBPDel.Enabled := FPDebugPanel.fSelCount > 0;
    FPDebugBPEdt.Enabled := FPDebugPanel.fSelCount > 0;
  End;

Begin

  If FPDebugPanelVisible And not QUITMSG And (FPWIndowID >= 0) Then Begin

    List := TAnsiStringlist.Create;

    With FPDebugPanel Do Begin
      Lock;
      Case FPDebugCombo.ItemIndex of
        0: // Variables
          Begin
            SP_MakeListVarOutput(List);
            If Integer(List.Objects[0]) = -1 Then Begin
              Clear;
              Add(' No variables defined');
              Enabled := False;
            End Else Begin
              OldVars := TAnsiStringlist.Create;
              OldContents := TAnsiStringlist.Create;
              For i := 0 To Count -1 Do Begin
                s := Copy(Items[i], 7);
                OldVars.Add(Copy(s, 1, Pos(#255, s) -1));
                OldContents.Add(Copy(s, Pos(#255, s) +7));
              End;
              Clear;
              MaxW := 0;
              MaxP := 0;
              For i := 0 To List.Count -1 Do Begin
                s := List[i];
                vName := Copy(s, 1, Pos('=', s) -1);
                MaxP := Max(MaxP, Length(vName));
                If OldVars.IndexOf(vName) >= 0 Then
                  vName := #16#0#0#0#0 + vName
                Else
                  vName := #16 + LongWordToString(debugNew) + vName;
                vContent := Copy(s, Pos('=', s) +1);
                MaxW := Max(MaxW, Length(vContent));
                If OldContents.IndexOf(vContent) >= 0 Then
                  vContent := #16#0#0#0#0 + vContent
                Else
                  If Ord(vName[2]) = debugNew and $FF Then
                    vContent := #16 + LongWordToString(debugNew) + vContent
                  Else Begin
                    vContent := #16 + LongWordToString(debugChg) + vContent;
                    vName[2] := LongWordToString(debugChg)[1];
                  End;
                Add(' ' + vName + #255 + ' ' + vContent);
              End;
              MaxW := Max(10, MaxW);
              MaxP := Max(6, MaxP);
              AddHeader(' Name', MaxP * iFW);
              AddHeader(' Contents', MaxW * iFW);
              //SortByAlpha := True;
              Sort(0);
              Enabled := True;
              OldVars.Free;
              OldContents.Free;
            End;
          End;
        1: // Watches
          Begin
            If Length(SP_WatchList) = 0 then Begin
              Clear;
              Add(' No watches defined');
              Enabled := False;
            End Else Begin
              Clear;
              MaxW := 0;
              MaxP := 0;
              OldExprs := TAnsiStringList.Create;
              OldWatches := TAnsiStringlist.Create;
              For i := 0 To Count -1 Do Begin
                s := Items[i];
                If s[1] = #16 Then
                  s := Copy(s, 6);
                p := Pos(#255, s) +1;
                OldWatches.Add(Copy(s, p));
                s := Copy(s, 1, p -2);
                If s[1] = #16 Then
                  s := Copy(s, 6);
                OldExprs.Add(s);
              End;
              For i := 0 To Length(SP_WatchList) -1 Do Begin
                Error.Code := SP_ERR_OK;
                s := ' ' + SP_WatchList[i].Expression;
                MaxW := Max(Length(s), MaxW);
                vContent := ' ' + SP_FPExecuteAnyExpression(SP_WatchList[i].Compiled_Expression, Error);
                If Error.Code <> SP_ERR_OK Then Begin
                  vContent := ' ' + ErrorMessages[Error.Code];
                  MaxP := Max(Length(vContent), MaxP);
                  vContent := #16#2#0#0#0 + vContent;
                End Else Begin
                  j := OldExprs.IndexOf(s);
                  Changed := (j >= 0) And (OldWatches[j] <> vContent);
                  MaxP := Max(Length(vContent), MaxP);
                  If Changed Then Begin
                    s := #16 + LongWordToString(debugNew) + s;
                    vContent := #16 + LongWordToString(debugNew) + vContent;
                  End;
                End;
                Add(s + #255 + vContent);
              End;
              AddHeader(' Expr', Max(5, MaxW) * iFW);
              AddHeader(' Result', Max(7, MaxP) * iFW);
              Sort(0);
              Enabled := True;
            End;
          End;
        2: // Breakpoints
          Begin
            SP_MakeBreakpointList(List);
            If Integer(List.Objects[0]) = -1 Then Begin
              Clear;
              Add(' No breakpoints defined');
              Enabled := False;
            End Else Begin
              Clear;
              MaxW := 0;
              MaxP := 0;
              MaxWC := 0;
              For i := 0 To List.Count -1 Do Begin
                s := List[i];
                vType := s[1];
                s := Copy(s, 3);
                p := Pos(#255, s);
                vContent := ' ' + Copy(s, 1, p -1);
                s := Copy(s, p +1);
                p := Pos(#255, s);
                If p > 0 Then Begin
                  vPass := ' ' + Copy(s, 1, p -1);
                  vExtra := ' ' + Copy(s, p +1);
                  Add(vType + #255 + vContent + #255 + vPass + #255 + vExtra);
                  MaxWC := Max(MaxWC, Length(vExtra) +1);
                End Else Begin
                  vPass := ' ' + s;
                  Add(vType + #255 + vContent + #255 + vPass);
                End;
                Objects[Count -1] := List.Objects[i];
                MaxW := Max(MaxW, Length(vContent) +1);
                MaxP := Max(MaxP, Length(vPass) +1);
              End;
              MaxW := Max(5, MaxW);
              MaxP := Max(6, MaxP);
              MaxWC := Max(10, MaxWC);
              Hdr.Caption := ' ';
              Hdr.Width := 2 * iFW;
              Hdr.Justify := 0;
              AddHeader(Hdr);
              AddHeader(' Line', MaxW * iFW);
              AddHeader(' Pass', MaxP * iFW);
              If MaxWC > 0 Then
                AddHeader(' Condition', MaxWC * iFW);
              Sort(0);
              Enabled := True;
            End;
          End;
        3: // Disassembly
          Begin
          End;
      End;
      SetButtons;
      Unlock;
    End;

    List.Free;

  End;

End;

Class Procedure SP_DebugPanelActionProcs.PanelSwitch(Sender: SP_BaseComponent; Text: aString);
Begin

  SP_FillDebugPanel;

End;

Class Procedure SP_DebugPanelActionProcs.PanelSelect(Sender: SP_BaseComponent; Index: Integer);
Begin

  // Toggle the edit and delete buttons if there's a selection

  FPDebugBPDel.Enabled := FPDebugPanel.fSelCount > 0;
  FPDebugBPEdt.Enabled := FPDebugPanel.fSelCount > 0;

End;

Procedure SP_EditBreakpoint(Index: Integer; Delete: Boolean);
Var
  i: Integer;
  s: aString;
  Bp: pSP_BreakPointInfo;
Begin

  // Edit or delete a breakpoint. If editing, we send a custom message to the interpreter thread
  // to open the BP editor dialog. If deleting, do it here.

  SetLength(s, SizeOf(LongWord) + SizeOf(pSP_BreakPointInfo));
  Bp := pSP_BreakPointInfo(FPDebugPanel.Objects[Index]);
  Index := -1;
  If Bp^.bpType = BP_STOP Then Begin
    For i := 0 To Length(SP_SourceBreakPointList) -1 Do
      If @SP_SourceBreakPointList[i] = Bp Then Begin
        Index := i;
        Break;
      End;
  End Else Begin
    For i := 0 To Length(SP_ConditionalBreakPointList) -1 Do
      If @SP_ConditionalBreakPointList[i] = Bp Then Begin
        Index := i;
        Break;
      End;
  End;

  If Delete Then Begin
    If Bp^.bpType = BP_STOP Then Begin
      For i := Index To Length(SP_SourceBreakPointList) -2 Do
        SP_SourceBreakPointList[i] := SP_SourceBreakPointList[i +1];
      SetLength(SP_SourceBreakPointList, Length(SP_SourceBreakPointList) -1);
    End Else Begin
      For i := Index To Length(SP_ConditionalBreakPointList) -2 Do
        SP_ConditionalBreakPointList[i] := SP_ConditionalBreakPointList[i +1];
      SetLength(SP_ConditionalBreakPointList, Length(SP_ConditionalBreakPointList) -1);
    End;
    SP_GetDebugStatus;
    SP_DisplayFPListing(-1);
  End Else Begin
    pLongWord(@s[1])^ := Index;
    pNativeUInt(@s[1 + SizeOf(LongWord)])^ := NativeUInt(Bp);
    AddControlMsg(clBPEdit, s);
  End;

End;

Class Procedure SP_DebugPanelActionProcs.DblClick(Sender: SP_BaseComponent; Index: Integer; Text: aString);
Begin

  // User double clicked (or used the enter key) on a breakpoint so open it and edit it.

  SP_EditBreakpoint(Index, False);

End;

Class Procedure SP_DebugPanelActionProcs.ButtonClick(Sender: SP_BaseComponent);
Begin

  Case FPDebugCombo.ItemIndex of
    0: // Variables
      Begin
      End;
    1: // Watches
      Begin
        If Sender = FPDebugBPEdt Then Begin
          AddControlMsg(clEditWatch, LongWordToString(FPDebugPanel.SelectedIndex));
        End Else
          If Sender = FPDebugBPAdd Then Begin
            AddControlMsg(clKeypress, aChar(K_CONTROL) + aChar(K_W));
          End Else
            If Sender = FPDebugBPDel Then Begin
              SP_DeleteWatch(FPDebugPanel.SelectedIndex);
            End;
      End;
    2: // Breakpoints
      Begin
        If Sender = FPDebugBPEdt Then Begin
          SP_EditBreakPoint(FPDebugPanel.SelectedIndex, False);
        End Else
          If Sender = FPDebugBPAdd Then Begin
            AddControlMsg(clKeypress, aChar(K_CONTROL) + aChar(K_N));
          End Else
            If Sender = FPDebugBPDel Then Begin
              SP_EditBreakPoint(FPDebugPanel.SelectedIndex, True);
            End;
      End;
    3: // Labels
      Begin
      End;
    4: // Procs and Fns
      Begin
      End;
    5: // Disassembly
      Begin
      End;
    6: // Program map
      Begin
      End;
  End;

End;

end.

