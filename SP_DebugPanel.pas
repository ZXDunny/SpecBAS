unit SP_DebugPanel;

interface

uses Math, SP_Util, SP_BaseComponentUnit, SP_ListBoxUnit, SP_ComboBoxUnit;

Type

  SP_DebugPanelActionProcs = Class

  Public

    Class Procedure PanelSwitch(Sender: SP_BaseComponent; Text: aString);

  End;

Procedure SP_OpenDebugPanel;
Procedure SP_CloseDebugPanel;
Procedure SP_FillDebugPanel;

var

  FPDebugPanel: SP_ListBox;
  FPDebugCombo: SP_ComboBox;
  FPDebugPanelVisible: Boolean;
  FPDebugPanelWidth: Integer;
  FPDebugPanelMode: Integer;

Const

  SP_dbgMode_Vars = 0;
  SP_dbgMode_Watches = 1;
  SP_dbgMode_Breakpoints = 2;
  SP_dbgMode_Disassembly = 3;

implementation

Uses SP_FPEditor, SP_Errors, SP_Graphics, SP_BankManager, SP_BankFiling, SP_SysVars, SP_Components, SP_Variables, SP_AnsiStringList,
     SP_Interpret_PostFix, SP_FileIO, SP_Main;

Procedure SP_UpdateAfterDebug;
Begin

  SP_FPWrapProgram;
  SP_AddFPScrollBars(False);
  SP_Decorate_Window(FPWindowID, 'Program listing - ' + SP_GetProgName(PROGNAME, True), True, False, FocusedWindow = fwEditor);
  SP_DisplayFPListing(-1);

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
    CanFocus := False;
    FPDebugPanel.SetBounds(Left, Top + Height + BSize, Width, FPPaperHeight - (Height + BSize));
    FPDebugPanel.BackgroundClr := debugPanel;
    FPDebugPanel.HeaderClr := BackgroundClr;
    FPDebugPanel.Transparent := False;
    FPDebugPanel.CanFocus := False;
    FPDebugPanel.SortByAlpha := True;
    OnChange := SP_DebugPanelActionProcs.PanelSwitch;
  End;
  FocusedControl := Nil;

  FPPaperWidth := FPClientWidth - (BSize * 3) - Fw - ((FPDebugPanelWidth + BSize) * Ord(FPDebugPanelVisible));
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
  FPPaperWidth := FPClientWidth - (BSize * 3) - Fw - ((FPDebugPanelWidth + BSize) * Ord(FPDebugPanelVisible));
  SP_UpdateAfterDebug;

End;

Procedure SP_FillDebugPanel;
Var
  i, MaxW: Integer;
  s, vName, vContent: aString;
  List, OldVars, OldContents: TAnsiStringlist;
Begin

  List := TAnsiStringlist.Create;

  Case FPDebugCombo.ItemIndex of
    0: // Variables
      Begin
        With FPDebugPanel Do Begin
          Lock;
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
            For i := 0 To List.Count -1 Do Begin
              s := List[i];
              vName := Copy(s, 1, Pos('=', s) -1);
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
            AddHeader(' Name', 10 * iFW);
            AddHeader(' Contents', MaxW * iFW);
            //SortByAlpha := True;
            Sort(0);
            Enabled := True;
            OldVars.Free;
            OldContents.Free;
          End;
          Unlock;
        End;
      End;
    1: // Watches
      Begin
      End;
    2: // Breakpoints
      Begin
      End;
    3: // Disassembly
      Begin
      End;
  End;

  List.Free;

End;

Class Procedure SP_DebugPanelActionProcs.PanelSwitch(Sender: SP_BaseComponent; Text: aString);
Begin

  SP_FillDebugPanel;

End;

end.
