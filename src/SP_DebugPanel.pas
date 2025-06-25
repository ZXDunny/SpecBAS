unit SP_DebugPanel;

interface

uses Math, Classes, SyncObjs, SysUtils, SP_Util, SP_BaseComponentUnit, SP_ListBoxUnit, SP_ComboBoxUnit, SP_ControlMsgs, SP_ButtonUnit, SP_Input, SP_ContainerUnit;

Type

  SP_PoIInfo = Record PoI_Type, Line, Statement: Integer; Name: aString; End;

  SP_DebugPanelActionProcs = Class

  Public

    Class Procedure PanelSwitch(Sender: SP_BaseComponent; Text: aString);
    Class Procedure DblClick(Sender: SP_BaseComponent; Index: Integer; Text: aString);
    Class Procedure PanelSelect(Sender: SP_BaseComponent; Index: Integer);
    Class Procedure ButtonClick(Sender: SP_BaseComponent);
    Class Procedure SelectItem(Sender: SP_BaseComponent; Index: Integer);
    Class Procedure SetFocus(Sender: SP_BaseComponent; WillFocus: Boolean);
    Class Procedure PaintGrabber(Control: SP_BaseComponent);

  End;

Procedure SP_OpenDebugPanel;
Procedure SP_CloseDebugPanel;
Procedure SP_User_OpenDebugPanel;
Procedure SP_User_CloseDebugPanel;
Procedure SP_FillDebugPanel;
Procedure SP_ResizeDebugPanel(X: Integer);
Procedure SP_FPUpdatePoIList;

var

  FPDebugPanel: SP_ListBox;
  FPDebugCombo: SP_ComboBox;
  FPSizeGrabber: SP_Container;
  FPResizingDebugPanel: Boolean;
  FPUserOpenedDebugPanel: Boolean;
  FPDebugPanelVisible: Boolean;
  FPDebugPanelWidth: Integer;
  FPDebugLastMouseX: Integer;
  FPDebugPanelMode: Integer;
  FPDebugBPAdd,
  FPDebugBPDel,
  FPDebugBPEdt: SP_Button;
  FPPoIList: Array of SP_PoIInfo;
  DebugCurWindow: Integer;
  LastDebugPanelIndex: Integer;

Const

  PoI_Label = 0;
  PoI_Proc = 1;
  PoI_Fn = 2;

  dbgVariables = 1;
  dbgWatches = 2;
  dbgBreakpoints = 4;
  dbgLabels = 8;
  dbgProcs = 16;
  dgbCharset = 32;
  dbgDisassembly = 64;
  dbgProgMap = 128;

implementation

Uses Vcl.ClipBrd, SP_FPEditor, SP_Errors, SP_Graphics, SP_BankManager, SP_BankFiling, SP_SysVars, SP_Components, SP_Variables, SP_AnsiStringList,
     SP_Interpret_PostFix, SP_FileIO, SP_Main, SP_MenuActions;

Procedure SP_UpdateAfterDebug;
Var
  NewPW: Integer;
  b: Boolean;
Begin

  NewPW := (FPClientWidth - (BSize * 3) - Fw - ((FPDebugPanelWidth + BSize) * Ord(FPDebugPanelVisible))) Div FPFw;
  b := Abs((FPPaperWidth Div FPFw) - NewPW) > 0;
  FPPaperWidth := FPClientWidth - (BSize * 3) - Fw - ((FPDebugPanelWidth + BSize) * Ord(FPDebugPanelVisible));
  If b Then SP_FPWrapProgram;
  If FPShowingSearchResults Then
    SP_DebugPanelActionProcs.SelectItem(Nil, FPDebugPanel.SelectedIndex);
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
      DisplaySection.Enter;
      SP_GetWindowDetails(FPWindowID, Win, Error);
      FPDebugCombo.SetBounds(Win^.Width - BSize - FPDebugPanelWidth, FPClientTop + BSize, Trunc(FPDebugPanelWidth * EDFONTSCALEX), FH);
      FPDebugPanel.SetBounds(FPDebugCombo.Left, FPDebugPanel.Top, FPDebugPanelWidth, FPDebugPanel.Height);
      FPSizeGrabber.SetBounds(FPDebugCombo.Left - BSize, FPDebugCombo.Top, BSize, FPPaperHeight);

      SP_UpdateAfterDebug;
      DisplaySection.Leave;
    End;

  End;

End;

Procedure SP_User_OpenDebugPanel;
Begin
  FPUserOpenedDebugPanel := True;
  SP_OpenDebugPanel;
End;

Procedure SP_User_CloseDebugPanel;
Begin
  FPUserOpenedDebugPanel := False;
  SP_CloseDebugPanel;
End;

Procedure SP_OpenDebugPanel;
Var
  Error: TSP_ErrorCode;
  Win: pSP_Window_Info;
Begin

  DisplaySection.Enter;

  SP_GetWindowDetails(FPWindowID, Win, Error);
  If Not Assigned(FPDebugPanel) Then Begin
    FPDebugPanel := SP_ListBox.Create(Win^.Component);
    FPDebugCombo := SP_ComboBox.Create(Win^.Component);
    FPSizeGrabber := SP_Container.Create(Win^.Component);
  End;
  FPDebugPanelVisible := True;
  FPDebugPanel.AllowLiterals := True;

  With FPDebugCombo Do Begin
    BackgroundClr := debugCombo;
    Transparent := False;
    SetBounds(Win^.Width - BSize - FPDebugPanelWidth, FPClientTop + BSize, Trunc(FPDebugPanelWidth * EDFONTSCALEX), FH);
    AddItem('Variables');
    AddItem('Watches');
    AddItem('Breakpoints');
    AddItem('Labels');
    AddItem('Procedures/Functions');
    AddItem('Character Set');
    ItemIndex := LastDebugPanelIndex;
    CanFocus := False;
    FPDebugPanel.SetBounds(Left, Top + Height + BSize, Width, FPPaperHeight - (Height + BSize));
    FPDebugPanel.BackgroundClr := debugPanel;
    FPDebugPanel.HeaderClr := BackgroundClr;
    FPDebugPanel.Transparent := False;
    FPDebugPanel.OnFocus := SP_DebugPanelActionProcs.SetFocus;
    FPDebugPanel.SortByAlpha := True;
    FPDebugPanel.OnChoose := SP_DebugPanelActionProcs.DblClick;
    FPDebugPanel.OnSelect := SP_DebugPanelActionProcs.PanelSelect;
    FPDebugPanel.MultiSelect := False;
    FPDebugPanel.OnSelect := SP_DebugPanelActionProcs.SelectItem;
    OnChange := SP_DebugPanelActionProcs.PanelSwitch;
    FPDebugBPEdt := SP_Button.Create(Win^.Component);
    FPDebugBPEdt.OnClick := SP_DebugPanelActionProcs.ButtonClick;
    FPDebugBPDel := SP_Button.Create(Win^.Component);
    FPDebugBPDel.OnClick := SP_DebugPanelActionProcs.ButtonClick;
    FPDebugBPAdd := SP_Button.Create(Win^.Component);
    FPDebugBPAdd.OnClick := SP_DebugPanelActionProcs.ButtonClick;
    FPSizeGrabber.SetBounds(Left - BSize, Top, BSize, FPPaperHeight);
    FPSizeGRabber.Border := False;
    FPSizeGrabber.Caption := '';
    FPSizeGrabber.Erase := True;
    FPSizeGrabber.Transparent := False;
    FPSizeGrabber.OnMouseDown := SP_MenuActionProcs.GrabberMouseDown;
    FPSizeGrabber.OnMouseMove := SP_MenuActionProcs.GrabberMouseMove;
    FPSizeGrabber.OnMouseUp := SP_MenuActionProcs.GrabberMouseUp;
    FPSizeGrabber.OnFocus := SP_DebugPanelActionProcs.SetFocus;
    FPSizeGrabber.OnPaintAfter := SP_DebugPanelActionProcs.PaintGrabber;
    FPSizeGrabber.Paint;
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
  i, MaxW, MaxWC, MaxP, p, j, OldP: Integer;
  s, vType, vName, vContent, vExtra, vPass: aString;
  List, OldVars, OldContents, OldWatches, OldExprs: TAnsiStringlist;
  Error: TSP_ErrorCode;
  Hdr: SP_ListBoxHeader;

Const

  PoINameT: Array[0..2] of aString = ('@', 'Proc', 'Fn');

  Procedure SetButtons;
  Var
    xPos, i, hMod: Integer;
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
    If not EDITORWRAP then Begin
      With FPScrollBars[SP_FindScrollBar(FPHorzSc)].BoundsRect do
        hMod := (Bottom - Top) + BSize;
    End Else
      hMod := 0;
    If ShowBtns Then
      FPDebugPanel.Height := hMod + FPPaperHeight - (FPDebugCombo.Height + BSize) - (FH + BSize * 3)
    Else
      FPDebugPanel.Height := hMod + FPPaperHeight - (FPDebugCombo.Height + BSize);
    xPos := FPDebugPanel.Left + FPDebugPanel.Width + BSize;
    Btn := nil;
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
            SP_MakeListVarOutput(List, True);
            If Integer(List.Objects[0]) = -1 Then Begin
              Clear;
              Add(' No variables defined');
              Enabled := False;
            End Else Begin
              OldVars := TAnsiStringlist.Create;
              OldContents := TAnsiStringlist.Create;

              For i := 0 To Count -1 Do Begin
                s := FPDebugPanel.Items[i];
                if s[1] = ' ' then s := Copy(s, 2);
                if s[1] < ' ' then s := Copy(s, 6);
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
                OldP := OldVars.IndexOf(vName);
                If OldP >= 0 Then Begin
                  // Variable already exists from previous update - check for changes
                  vContent := Copy(s, Pos('=', s) +1);
                  MaxW := Max(MaxW, Length(vContent));
                  If OldContents[OldP] <> vContent then
                    vContent := #16 + LongWordToString(debugChg) + vContent
                  Else
                    vContent := #16#0#0#0#0 + vContent;
                End Else Begin
                  vName := #16 + LongWordToString(debugNew) + vName;
                  vContent := Copy(s, Pos('=', s) +1);
                  MaxW := Max(MaxW, Length(vContent));
                  vContent := #16 + LongWordToString(debugNew) + vContent;
                End;
                Add(' ' + vName + #255 + ' ' + vContent);
              End;
              MaxW := Max(10, MaxW);
              MaxP := Max(6, MaxP +1);
              AddHeader(' Name', MaxP * iFW);
              AddHeader(' Contents', MaxW * iFW);
              //SortByAlpha := True;
              //Sort(0);
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
                  vContent := ' ' + ProcessErrorMessage(ErrorMessages[Error.Code]);
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
              AddHeader(' Expr', Max(6, MaxW) * iFW);
              AddHeader(' Result', Max(7, MaxP) * iFW);
              Sort(0);
              Enabled := True;
              OldExprs.Free;
              OldWatches.Free;
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
        3: // Labels - double click to jump
          Begin
            Clear;
            MaxW := 0;
            MaxP := 0;
            For i := 0 To Length(FPPoIList) -1 Do
              If FPPoIList[i].PoI_Type = PoI_Label Then Begin
                s := ' ' + FPPoIList[i].Name;
                j := FPPoIList[i].Line;
                vContent := ' ' + IntToString(Listing.Flags[j].Line) + ':' + IntToString(FPPoIList[i].Statement);
                MaxW := Max(MaxW, Length(vContent) +1);
                MaxP := Max(MaxP, Length(s) +1);
                Add(s + #255 + vContent);
                Objects[Count -1] := TObject(i);
              End;
            If Count > 0 Then Begin
              MaxW := Max(6, MaxW);
              MaxP := Max(16, MaxP);
              AddHeader(' Name', MaxP * iFW);
              AddHeader(' Line:Statement', MaxW * iFW);
              Enabled := True;
            End Else Begin
              Add(' No labels defined');
              Enabled := False;
            End;
          End;
        4: // Procedures/functions
          Begin
            Clear;
            MaxW := 0;
            MaxP := 0;
            For i := 0 To Length(FPPoIList) -1 Do
              If FPPoIList[i].PoI_Type in [PoI_Proc, PoI_Fn] Then Begin
                s := ' ' + PoINameT[FPPoIList[i].PoI_Type] + ' ' + FPPoIList[i].Name;
                j := FPPoIList[i].Line;
                vContent := ' ' + IntToString(SP_GetLineNumberFromIndex(j)) + ':' + IntToString(FPPoIList[i].Statement);
                MaxW := Max(MaxW, Length(vContent) +1);
                MaxP := Max(MaxP, Length(s) +1);
                Add(s + #255 + vContent);
                Objects[Count -1] := TObject(i);
              End;
            If Count > 0 Then Begin
              MaxW := Max(6, MaxW);
              MaxP := Max(16, MaxP);
              AddHeader(' Name', MaxP * iFW);
              AddHeader(' Line:Statement', MaxW * iFW);
              Enabled := True;
              Sort(0);
            End Else Begin
              Add(' No Fn/Procs defined');
              Enabled := False;
            End;
          End;
        5: // Character Set
          Begin
            Clear;
            MaxW := 5;
            MaxP := 13;
            AddHeader(' Hex ', MaxW * iFW);
            AddHeader(' Dec ', MaxW * IfW);
            AddHeader(' Character ', MaxP * iFW);
            For i := 0 to 255 Do Begin
              vName := IntToString(i);
              If i < 32 Then Begin
                Case i Of
                  6:  vContent := 'PRINT comma';
                  8:  vContent := 'Cursor left';
                  9:  vContent := 'Cursor right';
                  10: vContent := 'Cursor down';
                  11: vContent := 'Cursor up';
                  13: vContent := 'Return';
                  16: vContent := 'INK';
                  17: vContent := 'PAPER';
                  18: vContent := 'OVER';
                  19: vContent := 'TRANSPARENT';
                  20: vContent := 'INVERSE';
                  21: vContent := 'MOVE';
                  22: vContent := 'AT';
                  23: vContent := 'TAB';
                  24: vContent := 'CENTRE';
                  25: vContent := 'SCALE';
                  26: vContent := 'ITALIC';
                  27: vContent := 'BOLD';
                Else
                  Begin
                    vContent := aChar(5) + aChar(i And $FF);
                  End;
                End;
              End Else
                If i = 255 Then
                  vContent := '\$FF'
                Else
                  vContent := aChar(i);
              s := ' $' + IntToHex(i, 2) + #255 + ' ' + SP_Copy('000', 1, 3 - Length(vName)) + vName + #255 + ' ' + vContent;
              Add(s);
              Objects[Count -1] := TObject(i);
            End;
            Enabled := True;
            Sort(0);
          End;
        6: // Disassembly
          Begin

          End;
        7: // Map
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

  LastDebugPanelIndex := FPDebugCombo.ItemIndex;
  SP_FPUpdatePoIList;

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
    SP_GetDebugStatus(dbgBreakpoints);
    SP_DisplayFPListing(-1);
  End Else Begin
    pLongWord(@s[1])^ := Index;
    pNativeUInt(@s[1 + SizeOf(LongWord)])^ := NativeUInt(Bp);
    AddControlMsg(clBPEdit, s);
  End;

End;

Class Procedure SP_DebugPanelActionProcs.SelectItem(Sender: SP_BaseComponent; Index: Integer);
var
  s: aString;
  i, j, p, l: Integer;
  Error: TSP_ErrorCode;
Begin

  PanelSelect(Sender, Index);

  If Index < 0 Then Exit;
  Index := Integer(FPDebugPanel.Objects[Index]);

  Case FPDebugCombo.ItemIndex of
    3: // Labels - highlight all @Label instances
      Begin
        FPSearchTerm := '@' + FPPoIList[Index].Name;
        FPSearchOptions := [soForward, soStart, soClearBar];
        SP_FPEditor.SP_FindAll(FPSearchTerm, FPSearchOptions, Error);
        FPShowingSearchResults := True;
        j := -1;
        For i := 0 To Length(FPFindResults) -1 Do Begin
          If FPFindResults[i].Line <> j Then Begin
            SP_FPApplyHighlighting(FPFindResults[i].Line);
            AddDirtyLine(FPFindResults[i].Line);
          End;
          j := FPFindResults[i].Line;
        End;
        SP_DisplayFPListing(-1);
      End;
    4: // Procs and FNs - highlight all usages. Find "Fn x" and "Proc x", "DEF FN x" and "DEF PROC x" as well as "CALL x".
      Begin
        s := FPPoIList[Index].Name;
        if Pos('(', s) > 0 Then
          s := Copy(s, 1, Pos('(', s) -1);
        if FPPoIList[Index].PoI_Type = PoI_Fn then
          FPSearchTerm := 'fn ' + s
        else
          FPSearchTerm := 'proc ' + s;
        FPSearchOptions := [soForward, soStart, soClearBar];
        SP_FPEditor.SP_FindAll(FPSearchTerm, FPSearchOptions, Error);
        FPSearchTerm := 'def ' + FPSearchTerm;
        FPSearchOptions := FPSearchOptions + [soNoClear];
        SP_FPEditor.SP_FindAll(FPSearchTerm, FPSearchOptions, Error);
        if FPPoIList[Index].PoI_Type = PoI_Proc then Begin
          FPSearchTerm := 'call ' + s;
          SP_FPEditor.SP_FindAll(FPSearchTerm, FPSearchOptions, Error);
        End;
        FPShowingSearchResults := True;
        j := -1;
        i := 0;
        l := Length(FPFindResults);
        While i < l Do With FPFindResults[i] Do Begin
          If Not Split Then Begin
            // If any alphanumeric or "_" characters follow, then delete this find result.
            s := lower(Listing[Line]);
            p := Position + Length;
            If (p <= System.Length(s)) and (s[p] in ['a'..'z', '0'..'9', '_']) Then Begin
              For p := i to l -2 Do
                FPFindResults[p] := FPFindResults[p +1];
              SetLength(FPFindResults, l -1);
              Dec(l);
              Continue;
            End;
          End;
          If Line <> j Then Begin
            SP_FPApplyHighlighting(Line);
            AddDirtyLine(Line);
          End;
          j := Line;
          Inc(i);
        End;
        SP_DisplayFPListing(-1);
      End;
  End;

End;

Class Procedure SP_DebugPanelActionProcs.DblClick(Sender: SP_BaseComponent; Index: Integer; Text: aString);
Var
  s: aString;
  kInfo: SP_KeyInfo;
  Error: TSP_ErrorCode;
Begin

  // User double clicked (or used the enter key) on a breakpoint so open it and edit it.

  Index := Integer(FPDebugPanel.Objects[Index]);

  Case FPDebugCombo.ItemIndex of
    0: // Variables - edit the var
      Begin
      End;
    1: // Watches - edit the watch
      Begin
        AddControlMsg(clEditWatch, LongWordToString(FPDebugPanel.SelectedIndex));
      End;
    2: // Breakpoints - edit the breakpoint
      Begin
        SP_EditBreakpoint(Index, False);
      End;
    3: // Labels - double click to jump to that label declaration
      Begin
        s := EDITLINE;
        Index := Integer(FPDebugPanel.Objects[Index]);
        EDITLINE := '@' + FPPoIList[Index].Name;
        SP_FPBringToEditor(0, 0, Error, False);
        EDITLINE := s;
      End;
    4: // Procs and FNs - jump to declaration
      Begin
        PROGLINE := SP_GetLineNumberFromIndex(FPPoiList[Index].Line);
        SP_FPScrollToLine(PROGLINE, FPPoIList[Index].Statement);
      End;
    5: // Character set - paste character at cursor pos
      Begin
        kInfo.KeyCode := Integer(FPDebugPanel.Objects[Index]);
        kInfo.keyChar := aChar(kInfo.KeyCode);
        kInfo.CanRepeat := False;
        kInfo.IsKey := False;
        If DebugCurWindow = fwEditor Then Begin
          SP_FPEditorPerformEdit(@kInfo);
          SP_SwitchFocus(fwEditor);
        End Else
          If DebugCurWindow = fwDirect Then Begin
            SP_DWPerformEdit(@kInfo);
            SP_SwitchFocus(fwDirect);
          End;
      End;
  End;

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
            AddControlMsg(clKeypress, aChar(Sender.GetParentWindowID)+aChar(K_CONTROL) + aChar(K_W));
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
            AddControlMsg(clKeypress, aChar(Sender.GetParentWindowID)+aChar(K_CONTROL) + aChar(K_N));
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

Class Procedure SP_DebugPanelActionProcs.PaintGrabber(Control: SP_BaseComponent);
var
  i, y, x: Integer;
Begin

  With Control do Begin
    x := (Width Div 2) -2;
    y := (Height Div 2) - 5;
    for i := 0 to 2 do
      FillRect(x, y+(i * 4), x + 2, y+2+(i*4), fDisabledFontClr);
  end;

End;

Class Procedure SP_DebugPanelActionProcs.SetFocus(Sender: SP_BaseComponent; WillFocus: Boolean);
Begin

  If WillFocus Then Begin
    If FocusedWindow > fwNone then
      DebugCurWindow := FocusedWindow;
    SP_SwitchFocus(fwDebugPanel);
    If Not Sender.CanFocus Then
      FocusedControl := nil;
  End Else Begin
    SP_SwitchFocus(DebugCurWindow);
    FocusedControl := nil;
  End;

End;

Procedure SP_FPUpdatePoIList;
var
  i, j, l, ps, St, bc, ofs: Integer;
  inRem, inClr, inString: Boolean;
  s, lbl: aString;

  Procedure AddToList(iType: Integer; iName: aString; iLine, iStatement: Integer);
  Begin
    l := Length(FPPoIList);
    SetLength(FPPoIList, l +1);
    FPPoIList[l].Line := iLine;
    FPPoIList[l].Statement := iStatement;
    FPPoIList[l].Name := iName;
    FPPoIList[l].PoI_Type := iType;
  End;

Label
  Again;
Begin

  SetLength(FPPoIList, 0);
  For i := 0 To Listing.Count -1 Do
    If Listing.Flags[i].PoI Then Begin
      j := i; s := ''; InString := False; InClr := False; InREM := False;
      While (j > 0) And (SP_LineHasNumber(j) = 0) Do Dec(j);
      While j < i Do Begin
        s := s + Listing[j];
        Inc(j);
      End;
      s := lower(s + Listing[i]);
      St := 1;
      If (i < Listing.Count -2) And (SP_LineHasNumber(i + 1) = 0) Then
        s := s + Lower(Listing[i + 1]);
    Again:
      lbl := '';
      InString := False; InClr := False; InREM := False;
      ps := SP_Util.Pos('label', s); // Label search
      if ps > 0 Then Begin
        ScanForStatements(Copy(s, 1, ps -1), St, InString, InREM, InClr);
        If not InString then Begin
          Inc(ps, 5);
          while (ps < length(s)) and (s[ps] <= ' ') do inc(ps);
          if s[ps] = '@' Then begin
            Inc(ps);
            while (ps <= length(s)) and (s[ps] in ['0'..'9', 'a'..'z', '_']) do Begin
              lbl := lbl + s[ps];
              inc(ps);
            end;
          end;
          If lbl <> '' Then
            AddToList(PoI_Label, lbl, i, St);
          s := Copy(s, ps);
          Goto Again;
        End;
      End Else Begin
        ps := SP_Util.Pos('def proc', s); ofs := 8; // Procedure search
        If ps = 0 then begin
          ps := SP_Util.Pos('def fn', s); ofs := 6;// Look for a function if no procedures found
        end;
        if ps > 0 Then Begin
          ScanForStatements(Copy(s, 1, ps -1), St, InString, InREM, InClr);
          If Not InString Then Begin
            Inc(ps, ofs);
            while (ps < length(s)) and (s[ps] <= ' ') do inc(ps);
            while (ps <= length(s)) and (s[ps] in ['0'..'9', 'a'..'z', '_']) do Begin
              lbl := lbl + s[ps];
              inc(ps);
            end;
            while (ps < length(s)) and (s[ps] <= ' ') do inc(ps);
            if (ps <= Length(s)) and (s[ps] = '(') Then Begin // Optional parameter list. Let's hoover it up.
              lbl := lbl + '(';
              Inc(ps);
              bc := 0;
              while (ps <= Length(s)) and (s[ps] in ['_', '0'..'9', 'a'..'z', '(', ')', ',', ' ', '$']) Do Begin
                if s[ps] = '(' then Begin
                  Inc(ps);
                  lbl := lbl + '(';
                  Inc(bc);
                end else
                  if s[ps] = ')' then begin
                    Inc(ps);
                    lbl := lbl + ')';
                    if bc = 0 then
                      break
                    else
                      dec(bc);
                  end else begin
                    if s[ps] <> ' ' then
                      lbl := lbl + s[ps];
                    inc(ps);
                  end;
              end;
            end;
            if lbl <> '' Then
              if ofs = 8 then
                AddToList(PoI_Proc, lbl, i, St)
              else
                AddToList(PoI_Fn, lbl, i, St);
            s := Copy(s, ps);
            Goto Again;
          End;
        End;
      End;
    End;

  SP_FillDebugPanel;

end;

end.

