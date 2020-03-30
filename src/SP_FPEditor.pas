// Copyright (C) 2016 By Paul Dunn
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

Unit SP_FPEditor;

// todo:

// High Priority:

//    Upgrade INPUT line editor to respond like the current DW (if no FORMAT specified!)
//    UI Toolkit:
//      Windows with decoration, moveable, resizeable
//      Buttons, Edit box, Memo, Scrollbar, graphic, checkbox, radiogroup, listbox, combobox, menu
//      Trackbar, progress bar, tabcontrol bar, icon bar, treeview

// Medium Priority:

//    STEP [OVER], RUN [TO n], CONTINUE [TO n] commands to facilitate debugging
//    BREAK AT <line,statement>, BREAK ON <condition>
//    Hot keys -
//      F9  - RUN (Shift = CONTINUE)
//      F4  - RUN TO current line (or PROGLINE)
//      F7  - STEP
//      F8  - STEP OVER
//      F10 - RUN (Shift = GO TO) current line (or PROGLINE)
//      F5  - Set breakpoint at current line (or PROGLINE)
//    Menu strip for command operations
//    New dialogs:
//      *File (load/save)
//      *Find/Replace
//      GO TO (line number, proc/fn, label)
//      Debug window - Tabs for Virtual CPU, Variables, Machine Stack, GOSUB Stack, Watches, Breakpoints
//      Preferences
//      Tool management (add/remove to/from tools menu)
//        Character map
//        Paintbox for sprites
//        Font Editor
//        User tools submenu
//      Help
//        Contents
//        Quick Keyword Help

// Low Priority:

interface

Uses Types, Classes, Clipbrd, SyncObjs, SysUtils, Math{$IFNDEF FPC}, Windows{$ENDIF},
     SP_Graphics, SP_BankManager, SP_SysVars, SP_Errors, SP_Main, SP_Tokenise, SP_Util, SP_BankFiling, SP_UITools,
     SP_Input, SP_Sound, SP_InfixToPostFix, SP_Interpret_PostFix, SP_FileIO, SP_Package, SP_Variables, SP_Components, SP_Menu, SP_AnsiStringlist,
     SP_WindowMenuUnit, SP_PopUpMenuUnit, SP_CheckListUnit, SP_MenuActions;

Type

  pSP_EditorEvent = Pointer;
  SP_SearchOptions = Set Of (soStart, soCursorPos, soForward, soBackwards, soInREM, soInString, soMatchCase, soLoop, soInSelection, soCondenseSpaces, soInEditLine, soWholeWords, soExpression, soAll);
  SP_EventData = Record Pos, Key, Button, X, Y, tsData: Integer; ObjectPtr: Pointer; End;
  SP_EventHandler = Procedure(Var Data: SP_EventData);
  SP_EventOnLaunch = Procedure(Event: pSP_EditorEvent);
  SP_SelectionInfo = Record Active, Multiline: Boolean; StartL, EndL, StartP, EndP, Dir: Integer; End;
  SP_SearchInfo = Record Line, Position, Length: Integer; Split: Boolean; End;

  SP_ScrollBar = Record
    ID: Integer;
    Kind: Integer;
    UpEnabled,
    DownEnabled,
    ThumbEnabled,
    ThumbGrabbed: Boolean;
    ThumbGrabPos: TPoint;
    SmoothMove: Boolean;
    UpRect, DownRect, TrackRect, BoundsRect, ThumbRect: TRect;
    Position, TargetPos: aFloat;
    PageSize, TotalSize: Integer;
    WindowIdx, StepSize, GrabPosition: Integer;
    OnChange: SP_EventHandler;
  End;
  pSP_ScrollBar = ^SP_ScrollBar;

  SP_EditorEvent = Record
    ID: Integer;
    EvType: Integer;              // Type of event
    TargetFrame: Integer;         // The framecount needed for this event to trigger
    Delay1, Delay2: Integer;      // After being triggered, this is the number of frames to wait before triggering again. 0 = one-shot.
    Data: SP_EventData;           // the data for the event (mouse position/button, key)
    OnLaunch: SP_EventOnLaunch;   // The address of the procedure to call
    OneShot: Boolean;             // If set, event is removed from the event list once executed.
    Tag: NativeUInt;              // Anything using the event can set a value here
  End;

  TCompilerThread = Class(TThread)
    Finish, CompilerBusy: Boolean;
    Procedure Execute; Override;
  End;

Procedure SP_InitFPEditor;
Procedure SP_ForceCompile;
Procedure SP_StopCompiler;
Procedure SP_AddLine(Const l, s, c: aString);
Procedure SP_InsertLine(Index: Integer; Const l, s, c: aString; MarkDirty: Boolean = True);
Procedure SP_DeleteLine(Index: Integer; MarkDirty: Boolean = True);
Procedure SP_ClearListing;
Function  SP_WasPrevSoft(Idx: Integer): Boolean; Inline;
Procedure SP_CompiledListingAdd(const s: aString);
Procedure SP_CompiledListingDelete(Idx: Integer);
Procedure SP_CompiledListingInsert(Idx: Integer; const s: aString);
Procedure SP_CompiledListingClear;
Function  SP_GetLineExtents(Idx: Integer; FindStart: Boolean = False): TPoint;
Function  SP_LineFlags(Index: Integer): pLineFlags;
Procedure SP_FPEditorError(Var Error: TSP_ErrorCode; LineNum: Integer = -1);
Procedure SP_CreateMetrics;
Procedure SP_CreateFPWindow;
Procedure SP_CreateDirectWindow;
Procedure SP_FPCycleEditorWindows(HideMode: Integer);
Procedure SP_AddFPScrollBars(AutoScroll: Boolean = True);
Procedure SP_FPResizeWindow(NewH: Integer);
Procedure SP_Decorate_Window(WindowID: Integer; Title: aString; Clear, SizeGrip, Focused: Boolean);
Procedure SP_DrawStripe(Dst: pByte; Width, StripeWidth, StripeHeight: Integer; Focused: Boolean);
Procedure SP_DrawBatteryStatus;
Function  SP_SetFPEditorFont: Integer;
Procedure SP_SwitchFocus(FocusMode: Integer);
Procedure SP_FPNewProgram;
Procedure SP_FPRethinkScrollBars;
Procedure SP_FPApplyHighlighting(Line: Integer);
Procedure SP_MarkAsDirty(Idx: Integer);
Procedure SP_MarkWholeProgramDirty;
Procedure SP_FPEditorLoop;
Function  SP_CheckForConflict(LineIndex: Integer): Boolean;
Function  SP_GetLineIndex(LineNum: Integer): Integer;
Function  SP_GetLineNumberFromText(Const Txt: aString): Integer;
Function  SP_GetFPLineNumber(Idx: Integer): Integer;
Procedure SP_FillFlags;
Procedure ScanForStatements(Const s: String; Var St: Integer; Var InString, InREM, InClr: Boolean);
Procedure SP_DisplayFPListing(Line: Integer);
Procedure SP_FPScrollToLine(Line, Statement: Integer);
Procedure SP_CalculateFPCursorPos;
Function  SP_ScrollInView(Force: Boolean = False): Boolean;
Procedure SP_DrawGraphicsID;
Procedure SP_DisplayFPCursor;
Procedure SP_DisplayDWCursor;
Procedure SP_SetEditorClipping;
Procedure SP_ClearEditorClipping;
Procedure SP_GetFPUserInput;
Procedure SP_CreateScrollBar(ScrollBarID, scKind, WinID, Step: Integer; Bounds: TRect; ChangeProc: SP_EventHandler);
Procedure SP_UpdateScrollBar(ScrollBarID, pSize, tSize, Pos: Integer);
Procedure SP_DrawScrollBar(ScrollBarID: Integer);
Procedure SP_FPScrollEvent(Event: pSP_EditorEvent);
Procedure SP_FPEditorHandleMouseUp(X, Y: Integer);
Procedure SP_FPEditorHandleMouseDown(X, Y: Integer);
Procedure SP_FPEditorHandleMouseMove(X, Y: Integer);
Procedure SP_FPEditorHandleMouseWheel(WheelUp: Boolean; X, Y: Integer);
Procedure SP_FPScrollBarMouseDown(Event: pSP_EditorEvent);
Procedure SP_FPVertScrollbarChange(Var Data: SP_EventData);
Procedure SP_FPHorzScrollbarChange(Var Data: SP_EventData);
Function  SP_GetLineNumberFromIndex(Var Idx: Integer): Integer;
Function  SP_LineNumberSize(Idx: Integer): Integer;
Function  SP_LineHasNumber(Idx: Integer): Integer;
Function  SP_LineHasNumber_Fast(Idx: Integer): Boolean;
Procedure SP_AddEvent(Var Event: SP_EditorEvent);
Function  SP_FindEvent(ID: Integer): Integer;
Procedure SP_DeleteEvent(ID: Integer);
Procedure SP_DeleteAllEvents(eventType: Integer);
Procedure SP_LaunchEvent(Event: pSP_EditorEvent);
Procedure SP_CheckEvents;
Procedure SP_SelectWord;
Procedure SP_FPClearSelection(Var Sel: SP_SelectionInfo);
Procedure SP_FPDeleteSelection(Var Sel: SP_SelectionInfo);
Procedure SP_FPEditorPerformEdit(Key: Byte);
Procedure SP_FPBringToEditor(LineNum, Statement: Integer; Var Error: TSP_ErrorCode; DoEdit: Boolean = True);
Procedure SP_FindAll(Text: aString; Const Options: SP_SearchOptions; Var Error: TSP_ErrorCode);
Function  SP_FindText(Text: aString; StartAtL, StartAtP: Integer; const Options: SP_SearchOptions): TPoint;
Procedure SP_DWPerformEdit(Char: Byte);
Procedure SP_DWStoreLine(Line: aString);
Procedure SP_EditorDisplayEditLine;
Procedure SP_CompileProgram;
Procedure SP_FPExecuteEditLine(Var Line: aString);
Function  SP_FPExecuteNumericExpression(Const Expr: aString; var Error: TSP_ErrorCode): aFloat;
Function  SP_FPExecuteStringExpression(Const Expr: aString; var Error: TSP_ErrorCode): aString;
Function  SP_FPExecuteAnyExpression(Const Expr: aString; var Error: TSP_ErrorCode): aString;
Procedure SP_FPExecuteExpression(Const Expr: aString; var Error: TSP_ErrorCode);
Function  SP_FPCheckExpression(Const Expr: aString; var Error: TSP_ErrorCode): Boolean;
Procedure SP_Interpreter(Var Tokens: paString; Var Position: Integer; Var Error: TSP_ErrorCode; PreParseErrorCode: Integer; Continue: Boolean = False);
Procedure SP_Execute(Line: aString; Var Error: TSP_ErrorCode);
Procedure SP_FPMakeListWindowVisible;
Procedure SP_CloseEditorWindows;
Procedure SP_CreateEditorWindows;
Function  SP_ReOrderListing(Var Error: TSP_ErrorCode): Boolean;
Procedure SP_FPRenumberListing(Start, Finish, Line, Step: Integer; Var Error: TSP_ErrorCode);
Procedure SP_FPDeleteLines(Start, Finish: Integer; var Error: TSP_ErrorCode);
Procedure SP_FPUnWrapLine(Line: Integer);
Function  SP_FPGetUnwrappedLine(Var Line: Integer): aString;
Procedure SP_FPWordWrapLine(Line: Integer; FromHere: Boolean = False);
Procedure SP_FPWrapProgram;
Procedure SP_FPMergeLines(Start, Finish: Integer; var Error: TSP_ErrorCode);
Procedure SP_SetBracketPositions(c: aChar; Line, CPos: Integer);
Procedure SP_CursorPosChanged;
Procedure SP_RefreshCursorLineAfterChange(OldLine: Integer);
Function  SP_FindScrollBar(ScrollBarID: Integer): Integer;
Procedure AddDirtyLine(Line: Integer);
Procedure RemoveDirtyLine(Line: Integer);
Procedure ClearDirtyLines;
Procedure RefreshDirtyLines;
Procedure ListingChange(Index, Operation: Integer);
Procedure AddCompileLine(Line: Integer);
Procedure RemoveCompileLine(Line: Integer);
Procedure LaunchScrollEvent;
Function  IsSelActive: Boolean;
Procedure SP_HideFindResults(Clear: Boolean);
Procedure SP_ShowFindResults;
Procedure SP_GetSelectionInfo(Var Sel: SP_SelectionInfo);
Procedure StartWatchOp(Index: Integer);
Procedure StartBPEditOp(BPIndex: Integer; Bp: pSP_BreakPointInfo);
Procedure StartGotoOp;
Procedure StartFindOp(Find: Boolean);
Procedure StartFileOp(Operation: Integer; Filename: aString);
Procedure FindNext(jumpNext: Boolean);
Procedure PerformReplace(Var Idx: Integer);
Procedure HideSearchResults;
Procedure DWNewUndoEntry;
Procedure DWStoreEditorState;
Procedure DWCommenceUndo;
Procedure DWCompleteUndo;
Procedure DWPerformUndo;
Procedure DWNewRedoEntry;
Procedure DWStoreRedoEditorState;
Procedure DWCommenceRedo;
Procedure DWCompleteRedo;
Procedure DWPerformRedo;
Function  SP_CheckProgram: Boolean;
Procedure SP_ShowError(Code, Line, Pos: Integer);
Procedure SP_FPSetDisplayColours;
Procedure SP_ToggleBreakPoint(Hidden: Boolean);
Procedure SP_FPGotoLine(line, statement: Integer);
Procedure SP_ToggleEditorMark(i: Integer);
Procedure SP_JumpToMark(i: Integer);
Procedure SP_ResetConditionalBreakPoints;
Procedure SP_PrepareBreakpoints(Create: Boolean);
Function  SP_IsSourceBreakPoint(Line, Statement: Integer): Boolean;
Procedure SP_SingleStep;
Function  SP_StepOver: Boolean;
Procedure SP_ClearBreakPoints;
Procedure SP_GetDebugStatus;


Var
  // Editor window
  FPWindowID, FPFw, FPFh, Fw, Fh, FPWindowWidth, FPWindowHeight, FPWindowTop, FPWindowLeft: Integer;
  FPClientWidth, FPClientHeight, FPClientLeft, FPClientTop, FPPaperLeft, FPPaperTop, FPPaperWidth, FPPaperHeight: Integer;
  FPPageHeight, FPTotalHeight, FPPageWidth, FPTotalWidth, FPVertScrollPos, FPHorzScrollPos, FPLongestLineLen: Integer;
  FPListTopIndex, FPGutterWidth, FPCaptionHeight, FPStripePos: Integer;
  Listing, SyntaxListing, CompiledListing: TAnsiStringlist;
  LineLens: Array Of Integer;
  EdSc, EdCSc: aString;
  FPScrollBars: Array of SP_ScrollBar;
  Events: Array of SP_EditorEvent;
  FPCDes, FPCDesLine, FPMDFramesTarget, FPClickX, FPClickY: Integer;
  FPCDragging, FPDebugging, FPScrolling, FPGutterChangedSize: Boolean;
  FPEditorMarkers: Array[0..9] of TPoint;
  FPShowingSearchResults, FPShowingBraces: Boolean;
  FPSearchTerm, FPReplaceTerm, FPGotoText: aString;
  FPBracket1Pos, FPBracket2Pos, FPBracket1Line, FPBracket2Line: Integer;
  DirtyLines: Array of Integer;
  MaxDirtyLines: Integer;
  // Direct command window
  DWWindowID, DWWindowWidth, DWWindowHeight, DWWIndowTop, DWWindowLeft, DWClientWidth, DWClientHeight,
  DWTextLeft, DWTextWidth, DWClientLeft, DWClientTop, DWPaperLeft, DWPaperTop, DWPaperWidth, DWPaperHeight, DWSelP: Integer;
  FPEditorDefaultWindow: Integer;
  FPEditorDRPOSX, FPEditorDRPOSY, FPEditorSaveFPS: aFloat;
  FPEditorPRPOSX, FPEditorPRPOSY: aFloat;
  FPEditorOVER, FPEditorFRAME_MS: Integer;
  FPEditorMouseStatus, DWCDragging: Boolean;
  FPClickTime: LongWord;
  // Compiler
  CompilerLock: TCriticalSection;
  CompilerThread: TCompilerThread;
  CompilerRunning: Boolean;
  CompileList: Array of Integer;
  MaxCompileLines: Integer;
  // Editor system
  FocusedWindow: Integer;
  EditorMarks: Array[0..9] of LongWord;
  EditorHistory: Array of aString;
  HistoryPos: Integer;
  FPWIndowMode: Integer;
  FPEditorOutSet: Boolean;
  // Tools
  ToolWindowDone: Boolean;
  ToolStrResult: aString;
  ToolIntResult: NativeInt;
  ToolFloatResult: aFloat;
  ToolMode: NativeInt;

  // Direct command window
  DWUndoCount, DWRedoCount: Integer;
  DWUndoGroup, DwRedoGroup: Integer;
  DWUndoBufferPtr, DWRedoBufferPtr: Integer;
  DWUndoBufferSize, DWRedoBufferSize: Integer;
  DWUndoInProgress, DWRedoInProgress: Boolean;
  DWUndoList, DWRedoList: TAnsiStringlist;

  // Search system
  LastFindwasReplace: Boolean;
  FindWindow: SP_FindReplace;
  FPShowingFindResults: Boolean;
  FPFindResults: Array of SP_SearchInfo;
  FPSearchOptions: SP_SearchOptions;

  // Go to and Watch edit dialog
  GotoWindow: SP_TextRequester;

Const

  FPMarginSize = 2; // Gap between buttons and track in scrollbars
  FPMinGutterWidth = 2;

  scVertical = 0;
  scHorizontal = 1;

  FPVertSc = 0;
  FPHorzSc = 1;

  evtMouseDown = 1;
  evtMouseUp = 2;
  evtMouseMove = 3;
  evtKeyDown = 4;
  evtKeyUp = 5;
  evtScrollUpdate = 6;
  evtRefreshLine = 7;
  evtClearStatus = 8;

  evtLeftButton = 1;
  evtRightButton = 2;
  evtMiddleButton = 4;

  spLineNull= 0;
  spLineOk = 1;
  spLineDirty = 2;
  spLineDuplicate = 3;
  spLineError = 4;

  spHardReturn = 1;
  spSoftReturn = 2;

  fwDirect = 0;
  fwEditor = 1;

  Seps = [' ', '(', ')', ',', ';', '"', #39, '=', '+', '-', '/', '*', '^', '%', '$', '|', '&', ':', '>', '<'];

implementation

Uses SP_ControlMsgs, SP_DebugPanel;

Procedure SetAllToCompile;
Var
  i: Integer;
Begin
  MaxCompileLines := -1;
  for i := 0 To Listing.Count -1 do
    If SP_LineHasNumber(i) <> 0 Then
      AddCompileLine(i);
End;

Procedure ListingChange(Index, Operation: Integer);
Var
  c: Boolean;
Begin

  If Index > -1 Then
    Listing.Flags[Index].PoI := Pos('label', lower(Listing[Index])) > 0;
  If FPDebugPanelVisible And (FPDebugCombo.ItemIndex = 3) Then Begin
    SP_DisplayFPListing(Index);
    SP_FPUpdateLabelList;
  End;

  Case Operation of
    0: // Changed line
      AddCompileLine(Index);
    1: // Removed line
      if Index > -1 Then
        RemoveCompileLine(Index);
    2: // Added line
      AddCompileLine(Index);
  End;
  c := FILECHANGED;
  FILECHANGED := True;
  If Not c And (FPWindowID > -1) Then
    SP_Decorate_Window(FPWindowID, 'Program listing - ' + SP_GetProgName(PROGNAME, True), False, False, FocusedWindow = fwEditor);
End;

Procedure AddCompileLine(Line: Integer);
Var
  i: Integer;
Begin
  i := Line;
  While (i > 0) And (SP_lineHasNumber(i) = 0) Do Dec(i);
  if i >= 0 Then Begin
    Line := i;
    Listing.Flags[Line].State := spLineDirty;
    if MaxCompileLines >= 0 Then
      For i := 0 to MaxCompileLines Do
        If CompileList[i] = Line Then
          Exit;
    Inc(MaxCompileLines);
    If MaxCompileLines >= Length(CompileList) Then
      SetLength(CompileList, Length(CompileList) + 1000);
    CompileList[MaxCompileLines] := Line;
  End;
End;

Procedure RemoveCompileLine(Line: Integer);
Var
  i, j: Integer;
Begin
  For i := 0 To MaxCompileLines Do
    If CompileList[i] = Line Then Begin
      For j := i To MaxCompileLines -1 Do
        CompileList[j] := CompileList[j +1];
      Dec(MaxCompileLines);
    End;
End;

Procedure SP_StopCompiler;
Begin

  CompilerThread.Finish := True;
  Repeat
    CB_YIELD;
  Until Not CompilerRunning;
  FreeAndNil(CompilerThread);

End;

Procedure TCompilerThread.Execute;
Var
  s, t, Compiled: aString;
  Idx, lIdx, i: Integer;
  Error: TSP_ErrorCode;
  InString: Boolean;
  Extents: TPoint;
Begin

  NameThreadForDebugging('Compiler Thread');
  Priority := tpIdle;
  Idx := Listing.Count;
  CompilerRunning := True;
  CompilerBusy := False;
  Finish := False;

  While Not (QUITMSG or Finish) Do Begin

    CompilerBusy := False;
    If MaxCompileLines > -1 Then Begin
      If CompilerLock.TryEnter Then Begin
        If Listing.Flags[CompileList[0]].State in [spLineError, spLineDirty, spLineduplicate] Then Begin
          CompilerBusy := True;
          Idx := CompileList[0]
        End;
        RemoveCompileLine(CompileList[0]);
        CompilerLock.Leave;
      End;
    End Else
      Sleep(20);

    While Not (Finish or QUITMSG) And CompilerBusy Do Begin

      // Get the line we want to compile.

      If CompilerLock.TryEnter Then Begin

        If Listing.Flags[Idx].State = spLineDirty Then Begin

          lIdx := Idx;
          InString := False;
          While (Idx > 0) And (SP_LineHasNumber(Idx) = 0) Do Dec(Idx);
          s := Listing[Idx];
          For i := 1 To Length(s) Do
            If s[i] = '"' Then
              InString := not InString;
          Inc(Idx);

          While (Idx < Listing.Count) And (SP_LineHasNumber(Idx) = 0) Do Begin
            t := Listing[Idx];
            For i := 1 To Length(t) Do
              If t[i] = '"' Then
                InString := not InString;
            If Not SP_WasPrevSoft(Idx) And Not InString Then
              t := ' ' + t;
            s := s + t;
            Inc(Idx);
          End;

          If s <> '' Then Begin

            // Check its syntax and compile it.

            Compiled := SP_TokeniseLine(s, False, True) + SP_TERMINAL_SEQUENCE;
            SP_Convert_ToPostFix(Compiled, Error.Position, Error);

            If Compiled <> SP_TERMINAL_SEQUENCE Then
              If Byte(Compiled[1]) <> SP_LINE_NUM Then
                Error.Code := SP_ERR_SYNTAX_ERROR;

            Extents := SP_GetLineExtents(lIdx);
            If Error.Code = SP_ERR_OK Then Begin

              If (lIdx < Listing.Count) Then Begin
                CompiledListing[lIdx] := Compiled;
                If SP_CheckForConflict(lIdx) Then
                  Listing.Flags[lIdx].State := spLineDuplicate
                Else
                  Listing.Flags[lIdx].State := spLineOk;
                If Extents.X < Extents.Y Then
                  For i := Extents.X +1 To Extents.Y Do
                    Listing.Flags[i].State := spLineNull;

              End;

            End Else Begin

              // An error in compilation. Set this listing line's flags as containing an error - the listing display routines
              // will pick it up.

              If lIdx < Listing.Count Then
                Listing.Flags[lIdx].State := spLineError;

            End;

            // Now flag the editor that this line needs to be refreshed to display the info

            For i := Extents.X To Extents.Y Do
              AddDirtyLine(i);

          End Else Begin

            Idx := lIdx;
            While (Idx < Listing.Count) And (SP_LineHasNumber(Idx) = 0) Do Begin
              If Listing.Flags[Idx].State = spLineDirty Then Begin
                Listing.Flags[Idx].State := spLineNull;
                AddDirtyLine(Idx);
              End;
              Inc(Idx);
            End;

          End;

        End;

        CompilerBusy := False;
        CompilerLock.Leave;

      End;

    End;

  End;

  CompilerRunning := False;

End;

Procedure SP_InitFPEditor;
Begin

  CompilerLock := TCriticalSection.Create;
  Listing := TStringList.Create;
  SyntaxListing := TStringList.Create;
  CompiledListing := TStringList.Create;
  Listing.OnChange := ListingChange;
  DWUndoList := TStringList.Create;
  DWRedoList := TStringlist.Create;

End;

Procedure SP_FPEditorLoop;
Var
  c: Boolean;
  Error: TSP_ErrorCode;
Begin

  c := FILECHANGED; // Preserve here so we don't corrupt it while initialising
  FPShowingSearchResults := False;
  FPSearchOptions := [soForward, soCursorPos];
  FPSearchTerm := '';
  LastFindwasReplace := False;

  // Startup sequence

  MaxCompileLines := -1;
  FPGutterWidth := FPMinGutterWidth;

  HistoryPos := 0;
  SP_CreateMetrics;
  SP_SetFPEditorFont;
  EDITORMENU := CURMENU;

  Error.Line := -2;
  Error.Statement := 0;
  Error.Code := -1;
  NXTLINE := -1;
  Error.Position := 1;

  SP_FPEditorError(Error);

  FPDebugPanelVisible := False;
  FPResizingDebugPanel := False;
  FPDebugPanelWidth := 200;
  FPCDragging := False;
  DWCDragging := False;
  FPWindowMode := 2;

  If Listing.Count = 0 Then Begin
    Listing.FPCLine := 0;
    Listing.FPCPos := 1;
    Listing.FPSelLine := 0;
    Listing.FPSelPos := 1;
    FPCDes := 1;
    FPCDesLine := 0;
    SP_AddLine('', '', '');
    CURSORCHAR := 32;
  End;

  FILECHANGED := c; // Previous AddLine() will cause a change, we don't want that.

  SP_CreateDirectWindow;
  SP_CreateFPWindow;

  FPGutterWidth := 0; // Trigger a re-wrap in MarkAsDirty
  SP_MarkAsDirty(0);
  SP_FPWrapProgram;
  EDITORREADY := True;

  SP_FPRethinkScrollbars;

  SP_DisplayFPListing(-1);

  FocusedWindow := fwDirect;
  SP_SwitchFocus(FocusedWindow);
  SP_FPCycleEditorWindows(2);

  SetAllToCompile;
  CompilerThread := TCompilerThread.Create(False);

  DWUndoBufferPtr := -1;
  DWRedoBufferPtr := -1;
  DWUndoBufferSize := 1000;
  DWRedoBufferSize := 1000;
  DWCommenceUndo;
  DWCompleteUndo;
  Listing.CommenceUndo;
  Listing.CompleteUndo;

  PROGSTATE := SP_PR_STOP;

  SP_GetFPUserInput;

  CompilerLock.Free;
  Listing.Free;
  SyntaxListing.Free;
  CompiledListing.Free;
  DWUndoList.Free;
  DWRedoList.Free;

End;

Procedure SP_AddLine(Const l, s, c: aString);
Var
  nl: Integer;
Begin
  CompilerLock.Enter;
  Listing.Add(l);
  SyntaxListing.Add(l);
  SP_CompiledListingAdd(c);
  nl := SP_LineHasNumber(Listing.Count -1);
  If (nl > 0) And Not SP_WasPrevSoft(Listing.Count -1) Then Begin
    Listing.Flags[Listing.Count -1].State := spLineDirty;
    Listing.Flags[Listing.Count -1].GutterSize := SP_LineNumberSize(Listing.Count -1);
  End Else Begin
    Listing.Flags[Listing.Count -1].State := spLineNull;
    Listing.Flags[Listing.Count -1].GutterSize := 0;
  End;
  Listing.Flags[Listing.Count -1].Indent := 0;
  AddDirtyLine(Listing.Count -1);
  CompilerLock.Leave;
End;

Procedure SP_InsertLine(Index: Integer; Const l, s, c: aString; MarkDirty: Boolean = True);
Var
  i: Integer;
Begin
  CompilerLock.Enter;
  Listing.Insert(Index, l);
  SyntaxListing.Insert(Index, s);
  SP_CompiledListingInsert(Index, c);
  i := SP_LineHasNumber(Index);
  Listing.Flags[Index].ReturnType := 0;
  Listing.Flags[Index].Indent := 0;
  Listing.Flags[Index].GutterSize := 0;
  If (i > 0) And Not SP_WasPrevSoft(Index) Then Begin
    Listing.Flags[Index].State := spLineDirty;
    Listing.Flags[Index].GutterSize := SP_LineNumberSize(Index);
    If MarkDirty Then AddDirtyLine(Index);
  End Else
    Listing.Flags[Index].State := spLineNull;
  CompilerLock.Leave;
End;

Procedure SP_DeleteLine(Index: Integer; MarkDirty: Boolean = True);
Var
  i: Integer;
Begin
  CompilerLock.Enter;
  Listing.Delete(Index);
  SP_CompiledListingDelete(Index);
  SyntaxListing.Delete(Index);
  If MarkDirty Then Begin
    For i := Index To Listing.Count -1 Do Begin
      AddDirtyLine(i);
    End;
    AddDirtyLine(Listing.Count);
  End;
  CompilerLock.Leave;
End;

Procedure SP_ClearListing;
Begin
  Listing.Clear;
  SP_CompiledListingClear;
  SyntaxListing.Clear;
  ClearDirtyLines;
End;

Function  SP_LineFlags(Index: Integer): pLineFlags;
Begin
  Result := Listing.Flags[Index];
End;

Function SP_SetFPEditorFont: Integer;
Var
  Err: TSP_ErrorCode;
Begin

  Result := FONTBANKID;
  SP_SetSystemFont(EDITORFONT, Err);
  EdSc := #25 + aFloatToString(EDFONTSCALEX) + aFloatToString(EDFONTSCALEY);
  EdCSc := #25 + aFloatToString(1) + aFloatToString(1);
  SP_CreateMetrics;

End;

Procedure SP_CreateMetrics;
Begin

  FPFw := Trunc(FONTWIDTH * EDFONTSCALEX);
  FPFh := Trunc(FONTHEIGHT * EDFONTSCALEY);
  Fw := FONTWIDTH;
  Fh := FONTHEIGHT;

End;

Procedure SP_CreateDirectWindow;
Var
  Idx: LongWord;
  Error: TSP_ErrorCode;
  Win: pSP_Window_Info;
  sz: Integer;
Begin

  FPEditorDefaultWindow := SCREENBANK;
  FPEditorDRPOSX := DRPOSX;
  FPEditorDRPOSY := DRPOSY;
  FPEditorPRPOSX := PRPOSX;
  FPEditorPRPOSY := PRPOSY;
  FPEditorOVER := COVER;
  FPEditorSaveFPS := FPS;
  FPEditorFRAME_MS := FRAME_MS;
  FPEditorMouseStatus := MOUSEVISIBLE;
  MOUSEVISIBLE := True;

  COVER := 0;
  T_OVER := COVER;

  SP_SetFPS(EDITORFPS);
  FPCaptionHeight := FPFh + 2;

  DWWindowWidth := DISPLAYWIDTH - (BSize * 2);
  DWWindowHeight := FPFh + (BSize * 2) + 1 + FPCaptionHeight;
  DWWindowTop := DISPLAYHEIGHT - BSize - DWWindowHeight;
  DWWindowLeft := BSize;

  DWClientWidth := DWWindowWidth - 2;
  DWClientHeight := DWWindowHeight - FPCaptionHeight - 1;
  DWClientLeft := Bsize;
  DWClientTop := FPCaptionHeight + BSize;

  DWWindowID := SP_Add_Window(DWWindowLeft, DISPLAYHEIGHT, DWWindowWidth, DWWindowHeight, -1, 8, 0, Error);
  SP_SetDrawingWindow(DWWindowID);
  COVER := 0;
  CINVERSE := 0;
  CITALIC := 0;
  CBOLD := 0;
  SP_GetWindowDetails(DWWindowID, Win, Error);
  For Idx := 0 To 255 Do Win^.Palette[Idx] := DefaultPalette[Idx];

  DWPaperLeft := 1 + BSize;
  DWPaperTop := FPCaptionHeight + BSize;
  DWPaperWidth := DWClientWidth - (BSize * 2);
  DWPaperHeight := DWClientHeight - (BSize * 2);
  sz := Trunc(Max(EDFONTSCALEX * FONTWIDTH, EDFONTSCALEY * FONTHEIGHT));
  DWTextLeft := DWPaperLeft + sz + FPFw;
  DWTextWidth := (DWPaperWidth - DWTextLeft) Div FPFw;

  SP_FillRect(0, 0, DWWindowWidth -1, DWWindowHeight -1, 7);
  SP_Decorate_Window(DWWindowID, 'Direct Command', True, False, False);

  SP_SetDrawingWindow(FPEditorDefaultWindow);

End;

Procedure SP_Decorate_Window(WindowID: Integer; Title: aString; Clear, SizeGrip, Focused: Boolean);
Var
  Win: pSP_Window_Info;
  Err: TSP_ErrorCode;
  Idx, Font, Window, sp: Integer;
  tTitleBar: aString;
Begin

  Window := SCREENBANK;
  Font := SP_SetFPEditorFont;

  SP_GetWindowDetails(WindowID, Win, Err);
  If Not Assigned(Win) Then Exit;

  SP_SetDrawingWindow(WindowID);

  T_INK := capBack;
  T_OVER := 0;
  T_BOLD := 0;
  T_CLIPX1 := 0;
  T_CLIPX2 := Win^.Width;
  T_CLIPY1 := 0;
  T_CLIPY2 := Win^.Height;

  If Clear Then SP_FillRect(0, 0, Win^.Width, Win^.Height, winBack);
  SP_FillRect(0, FPFh + 2, Win^.Width, 4, winBack); // 4 pixel border at the top
  SP_FillRect(0, FPFh + 6, 4, Win^.Height, winBack); // And to the left
  SP_FillRect(4, Win^.Height - (FPFh + 6), Win^.Width, FPFw + 6, winBack);
  SP_FillRect(Win^.Width - (FPFw + 7), FPFh + 6, FPFw + 7, Win^.Height - (FPFh + 6), winBack);
  SP_FillRect(0, 0, Win^.Width, FPFh +2, capBack);

  Sp := (Win^.Width - ((FPFw * 4)) - FPFh *2) - FPFw;
  If FPFw * Length(Title) > Sp Then
    Title := Copy(Title, 1, Sp Div FPFw);

  SP_DrawRectangle(0, 0, Win^.Width -1, Win^.Height -1);
  If Focused Then
    SP_TextOut(-1, FPFw Div 2, 1, EdSc + Title, capText, capBack, True)
  Else
    SP_TextOut(-1, FPFw Div 2, 1, EdSc + Title, capInactive, CapBack, True);

  SP_DrawStripe(Win^.Surface, Win^.Width, FPFw, FPFh, Focused);
  If WindowID = DWWindowID Then SP_DrawBatteryStatus;

  If SizeGrip Then
    SP_TextOut(FONTBANKID, Win^.Width -(Fw + 6), Win^.Height - (Fh + 6), EdCSc + #250, gripClr, winBack, True);

  SP_SetDirtyRect(Win^.Left, Win^.Top, Win^.Left + Win^.Width -1, Win^.Top + Win^.Height);
  SP_SetDrawingWindow(Window);
  SP_SetSystemFont(Font, Err);

End;

Procedure SP_DrawStripe(Dst: pByte; Width, StripeWidth, StripeHeight: Integer; Focused: Boolean);
Var
  X, Y, X2, i: Integer;
  Ptr, oPtr: pByte;
Const
  ClrsFocused: Array[0..3] of Byte   = (2, 6, 4, 5);
  ClrsUnFocused: Array[0..3] of Byte = (238, 252, 246, 243); //(231, 245, 238, 241);
Begin

  If Width < 160 Then Exit;

  X := Width - ((StripeWidth * 4)) - StripeHeight *2;
  FPStripePos := X;
  oPtr := pByte(NativeUInt(Dst) + (Width * StripeHeight) + X);

  For Y := StripeHeight DownTo 1 Do Begin
    For X2 := X to X + (StripeWidth * 4) -1 Do Begin
      i := (X2 - X) Div StripeWidth;
      If Focused Then
        oPtr^ := ClrsFocused[i] + (8 * Ord(i < 3))
      Else
        oPtr^ := ClrsUnFocused[i];
      inc(oPtr);
    End;
    Dec(oPtr, Width + (StripeWidth * 4) -1);
  End;

End;

Procedure SP_DrawBatteryStatus;
Var
  Idx, X, Y, BattW, pW, PixW, Font, Window: Integer;
  PixPtr: pByte;
  Win: pSP_Window_Info;
  Err: TSP_ErrorCode;
  {$IFNDEF FPC}
  SysPowerStatus: TSystemPowerStatus;
  {$ENDIF}
Const
  Clrs: Array[0..6] of Byte = (0, 0, 232, 0, 238, 240, 245);
Begin

  {$IFDEF PANDORA}
  BATTLEVEL := StrToInt(ReadLinuxFile('/sys/class/power_supply/bq27500-0/capacity'));
  {$ELSE}
    {$IFNDEF FPC}
      // Windows
      GetSystemPowerStatus(SysPowerStatus);
      Case SysPowerStatus.ACLineStatus of
        1: BATTLEVEL := 100;
        0: BATTLEVEL := SysPowerStatus.BatteryLifePercent;
      end;
    {$ELSE}
      // put Darwin here
    {$ENDIF}
  {$ENDIF}

  // Draws the battery status in the current window. Assumes the current window is a "system" window, and has a stripe.
  // First, find the stripe so we know what to do!

  If DWWindowID > -1 Then Begin

    Window := SCREENBANK;
    Font := SP_SetFPEditorFont;

    SP_GetWindowDetails(DWWindowID, Win, Err);
    SP_SetDrawingWindow(DWWindowID);

    T_INK := 0;
    T_OVER := 0;

    X := Win^.Width - FPFh -2;
    Y := 0;

    // Now calculate how much we need to remove for the battery meter.
    // There are four stripes.

    BattW := Round((((FPFw * 4))) * ((100-BATTLEVEL)/100)) -2;
    SP_DrawStripe(@SP_BankList[SP_FindBankID(SCREENBANK)]^.Memory[0], Win^.Width, FPFw, FPFh, FocusedWindow = fwDirect);

    For Idx := 2 To FPFh -1 Do Begin
      PixPtr := @SP_BankList[SP_FindBankID(SCREENBANK)]^.Memory[X + (Idx * Win^.Width) - Idx];
      PixW := BattW;
      While PixW > 0 Do Begin
        PixPtr^ := 0;
        Dec(PixW);
        Dec(PixPtr);
        Inc(y);
      End;
    End;

    SP_SetDirtyRect(Win^.Left, Win^.Top, Win^.Left + Win^.Width, Win^.Top + Win^.Height);
    SP_SetDrawingWindow(Window);
    SP_SetSystemFont(Font, Err);

  End;

End;

Procedure SP_AddFPScrollBars(AutoScroll: Boolean = True);
Begin

  // This will only create them if they don't exist.

  SP_CreateScrollBar(FPVertSc, scVertical, FPWindowID, FPFh,
                     Rect(FPPaperLeft + FPPaperWidth + BSize,
                          FPPaperTop,
                          FPPaperLeft + FPPaperWidth + BSize + Fw,
                          FPPaperTop + FPPaperHeight),
                     SP_FPVertScrollBarChange);

  If Not EDITORWRAP then
    SP_CreateScrollBar(FPHorzSc, scHorizontal, FPWindowID, FPFw,
                       Rect(FPPaperLeft + (FPGutterWidth * FPFw) +BSize,
                            FPPaperTop + FPPaperHeight + BSize,
                            FPPaperLeft + FPPaperWidth,
                            FPPaperTop + FPPaperHeight + BSize + Fh),
                       SP_FPHorzScrollBarChange);

  SP_FPReThinkScrollBars;

  If AutoScroll Then SP_ScrollInView;

End;

Procedure SP_FPUpdateHorzScrollBar;
Var
  ScrollBar: pSP_ScrollBar;
Begin

  // Called when the gutter size changes - the scrollbar should move its left coordinate to match.

  SP_CreateScrollBar(FPHorzSc, scHorizontal, FPWindowID, FPFw,
                     Rect(FPPaperLeft + (FPGutterWidth * FPFw) + BSize,
                          FPPaperTop + FPPaperHeight + BSize,
                          FPPaperLeft + FPPaperWidth,
                          FPPaperTop + FPPaperHeight + BSize + Fh),
                     SP_FPHorzScrollBarChange);

  SP_UpdateScrollBar(FPHorzSc, -1, -1, MAXINT);

End;

Procedure SP_CreateFPWindow;
Var
  Idx: Integer;
  Event: SP_EditorEvent;
  Error: TSP_ErrorCode;
  Win: pSP_Window_Info;
  i: SP_CheckList;
Begin

  // Create the main editor window - fullscreen (with margin/border)

  FPWindowWidth := DISPLAYWIDTH - (BSize * 2);
  FPWindowHeight := DISPLAYHEIGHT - (BSize * 2) - (DWWindowHeight + BSize);
  FPWindowTop := BSize;
  FPWindowLeft := BSize;

  FPWindowID := SP_Add_Window(FPWindowLeft, -FPWindowHeight, FPWindowWidth, FPWindowHeight, -1, 8, 0, Error);
  SP_GetWindowDetails(FPWindowID, Win, Error);
  Win^.CaptionHeight := FPCaptionHeight;
  SP_CreateEditorMenu;

  // Dimensions. Client area is the inner part of the window excluding border ( 1 pixel ) and caption.
  // Page area is the area that the text is rendered to.

  FPCaptionHeight := FPFh + 2;
  FPClientWidth := FPWindowWidth - 2;
  FPClientHeight := FPWindowHeight - FPCaptionHeight - 1;
  FPClientLeft := 1;
  FPClientTop := FPCaptionHeight;

  If Assigned(FPMenu) Then Begin
    Dec(FPClientHeight, FPMenu.Height);
    Inc(FPClientTop, FPMenu.Height);
  End;

  FPPaperLeft := BSize + FPClientLeft;
  FPPaperTop := BSize + FPClientTop;
  FPPaperWidth := FPClientWidth - (BSize * 3) - Fw - ((FPDebugPanelWidth + BSize) * Ord(FPDebugPanelVisible));
  FPPaperHeight := FPClientHeight - (BSize * 2) - (Ord(Not EDITORWRAP) * (BSize + Fh));

  SP_SetDrawingWindow(FPWindowID);
  For Idx := 0 To 255 Do Win^.Palette[Idx] := DefaultPalette[Idx];
  COVER := 0;
  CINVERSE := 0;
  CITALIC := 0;
  CBOLD := 0;

  SP_FillRect(0, 0, FPWindowWidth -1, FPWindowHeight -1, 7);
  SP_Decorate_Window(FPWindowID, 'Program listing - ' + SP_GetProgName(PROGNAME, True), True, False, False);

  If FPDebugPanelVisible Then
    SP_OpenDebugPanel;

  SP_AddFPScrollBars;
  SP_FPWrapProgram;

  SetLength(Events, 0);

End;

Function SP_GetWindowFromID(Id: Integer): Integer;
Begin

  If Id = FPWindowID Then
    Result := fwEditor
  Else
    If Id = DWWindowID Then
      Result := fwDirect
    Else
      Result := -1;

End;

Procedure SP_SwitchFocus(FocusMode: Integer);
Var
  OldFocus, Ln: Integer;
Begin

  // Remove the focus from the current window

  OldFocus := FocusedWindow;
  FocusedWindow := FocusMode;
  Case OldFocus of
    fwDirect:
      Begin
        SP_Decorate_Window(DWWindowID, 'Direct command', True, False, False);
        SP_EditorDisplayEditLine;
      End;
    fwEditor:
      Begin
        SP_Decorate_Window(FPWindowID, 'Program listing - ' + SP_GetProgName(PROGNAME, True), True, False, False);
        Ln := Listing.FPCLine;
        PROGLINE := SP_GetLineNumberFromIndex(Ln);
      End;
  End;

  // Now set focus.

  Case FocusMode of
    fwDirect:
      Begin
        SP_ClearEditorClipping;
        SP_Decorate_Window(DWWindowID, 'Direct command', True, False, True);
        SP_DisplayDWCursor;
        SP_EditorDisplayEditLine;
      End;
    fwEditor:
      Begin
        If FPWIndowMode = 0 Then Begin
          FPWindowMode := 2;
          SP_FPCycleEditorWindows(2);
        End;
        SP_Decorate_Window(FPWindowID, 'Program listing - ' + SP_GetProgName(PROGNAME, True), True, False, True);
        If Listing.FPCLine >= Listing.Count Then Begin
          Listing.FPCLine := Listing.Count -1;
          Listing.FPCPos := 1;
          FPCDes := Listing.FPCPos;
          FPCDesLine := Listing.FPCLine;
        End;
      End;
  End;

  SP_CalculateFPCursorPos;
  SP_CursorPosChanged;
  If FocusMode = fwEditor Then SP_ScrollInView;
  Listing.FPSelLine := Listing.FPCLine;
  Listing.FPSelPos := Listing.FPCPos;
  SP_DisplayFPListing(-1);

End;

Procedure SP_FPNewProgram;
Var
  Error: TSP_ErrorCode;
Begin

  SP_ClearListing;
  SP_AddLine('', '', '');
  SP_ClearBreakpoints;
  Listing.Flags[0].ReturnType := spHardReturn;
  SP_PreParse(True, Error);
  CURSORCHAR := 32;
  SP_FPRethinkScrollBars;
  Listing.FPCLine := 0;
  Listing.FPCPos := 1;
  Listing.FPSelLine := Listing.FPCLine;
  Listing.FPSelPos := Listing.FPCPos;
  FPCDes := Listing.FPCPos;
  FPCDesLine := Listing.FPCLine;
  FPGutterWidth := FPMinGutterWidth;
  CURSORPOS := 1;
  DWSelP := 1;
  EDITERROR := False;
  Listing.CommenceUndo;
  Listing.CompleteUndo;
  DWCommenceUndo;
  DWCompleteUndo;
  FILECHANGED := False;

End;

Function SP_WasPrevSoft(Idx: Integer): Boolean; Inline;
Begin

  Result := (Idx > 0) And (Listing.Flags[Idx -1].ReturnType = spSoftReturn);

End;

Procedure SP_ForceCompile;
Var
  Idx, cIdx: Integer;
  s: aString;
  Error: TSP_ErrorCode;
Begin

  Idx := 0;
  SP_Program_Clear;

  While Idx < Listing.Count Do Begin
    cIdx := Idx;
    s := Listing[Idx];
    Inc(Idx);
    While (Idx < Listing.Count) And (SP_LineHasNumber(Idx) = 0) Do Begin
      s := s + Listing[Idx];
      Inc(Idx);
    End;
    s := SP_TokeniseLine(s, False, True) + SP_TERMINAL_SEQUENCE;
    If s <> SP_TERMINAL_SEQUENCE Then Begin
      SP_Convert_ToPostFix(s, Error.Position, Error);
      If Error.Code = SP_ERR_OK Then Begin
        SP_Store_Line(s);
        CompiledListing[cIdx] := s;
      End;
    End;
  End;

End;

Procedure SP_MarkAsDirty(Idx: Integer);
Var
  cIdx, lIdx, Mxg: Integer;
  s, s2: aString;
Begin

  // Marks a line in the text editor as dirty - i.e, changed and needing to be syntax checked and compiled.
  // The compiler thread will pick this up.

  While (Idx > 0) And (SP_LineHasNumber(Idx) = 0) Do Dec(Idx);
  Listing.Flags[Idx].GutterSize := SP_LineNumberSize(Idx);
  Listing.Flags[Idx].State := spLineDirty;
  AddCompileLine(Idx);

  // Also just run a quick check to see if the guttersize has changed

  Mxg := 0;
  For Idx := 0 To Listing.Count -1 Do
    Mxg := Max(Listing.Flags[Idx].GutterSize, Mxg);
  If Mxg + FPMinGutterWidth <> FPGutterWidth Then Begin
    FPGutterWidth := Mxg + FPMinGutterWidth;
    FPGutterChangedSize := True;
    If EDITORREADY Then SP_FPWrapProgram;
  End;

End;

Procedure SP_MarkWholeProgramDirty;
Var
  Idx: Integer;
Begin

  Idx := 0;
  While Idx < Listing.Count Do Begin
    If SP_LineHasNumber(Idx) > 0 Then
      SP_MarkAsDirty(Idx);
    Inc(Idx);
  End;

End;

Procedure SP_CompiledListingAdd(const s: aString);
Begin

  CompilerLock.Enter;
  CompiledListing.Add(s);
  CompilerLock.Leave;

End;

Procedure SP_CompiledListingDelete(Idx: Integer);
Begin

  CompilerLock.Enter;
  CompiledListing.Delete(Idx);
  CompilerLock.Leave;

End;

Procedure SP_CompiledListingInsert(Idx: Integer; const s: aString);
Begin

  CompilerLock.Enter;
  CompiledListing.Insert(Idx, s);
  CompilerLock.Leave;

End;

Procedure SP_CompiledListingClear;
Begin

  CompilerLock.Enter;
  CompiledListing.Clear;
  CompilerLock.Leave;

End;

Function SP_GetLineExtents(Idx: Integer; FindStart: Boolean = False): TPoint;
Var
  nIdx: Integer;

  Function SP_GetLineNumberFromIndex(I: Integer): Integer;
  Begin
    Result := -1;
    If i > -1 Then
      If i < Listing.Count Then Begin
        If SP_LineHasNumber(i) > 0 Then
          Result := SP_GetFPLineNumber(i);
      End Else
        Result := MAXINT;
  End;

Begin

  // Returns the extents of the line that *must* start at Idx.

  If FindStart Then
    While (Idx > 0) And (SP_GetLineNumberFromIndex(Idx) < 0) Do
      Dec(Idx);

  Result.X := Idx;
  Inc(Idx);
  If Idx < Listing.Count Then Begin
    nIdx := Idx;
    While (SP_GetLineNumberFromIndex(nIdx) < 0) Do Begin
      Inc(Idx);
      nIdx := Idx;
    End;
  End;
  Result.Y := Idx -1;

End;

Procedure SP_CompiledListingChange(Idx: Integer; const s: aString);
Begin

  // Should only ever be called by the compiler.

  CompilerLock.Enter;
  CompiledListing[Idx] := s;
  Listing.Flags[Idx].State := spLineOk;
  CompilerLock.Leave;

End;

Function SP_FindScrollBar(ScrollBarID: Integer): Integer;
Begin

  Result := Length(FPScrollBars) -1;
  While Result >= 0 Do
    If FPScrollBars[Result].ID = ScrollBarID Then
      Break
    Else
      Dec(Result);

End;

Procedure SP_CreateScrollBar(ScrollBarID, scKind, WinID, Step: Integer; Bounds: TRect; ChangeProc: SP_EventHandler);
Var
  ScrollBar: pSP_ScrollBar;
  Idx: Integer;
Begin

  Idx := SP_FindScrollBar(ScrollBarID);

  If Idx < 0 Then Begin
    SetLength(FPScrollBars, Length(FPScrollBars) +1);
    ScrollBar := @FPScrollBars[Length(FPScrollBars) -1];
  End Else
    ScrollBar := @FPScrollBars[Idx];

  With ScrollBar^ Do Begin
    ID := ScrollBarID;
    Kind := scKind;
    With Bounds Do Begin
      BoundsRect := Rect(Left, Top, Right, Bottom);
      If Kind = scVertical Then Begin
        UpRect := Rect(Left, Top, Right, Top + Fh);
        DownRect := Rect(Left, Bottom - Fh, Right, Bottom);
        TrackRect := Rect(Left, UpRect.Bottom + FPMarginSize, Right, DownRect.Top - FPMarginSize);
      End Else Begin
        UpRect := Rect(Left, Top, Left + Fw, Bottom);
        DownRect := Rect(Right - Fw, Top, Right, Bottom);
        TrackRect := Rect(UpRect.Right + FPMarginSize, Top, DownRect.Left - FPMarginSize, Bottom);
      End;
    End;
    OnChange := ChangeProc;
    WindowIdx := WinID;
    StepSize := Step;
  End;

End;

Procedure SP_ScrollEditor(d: Integer);
Var
  i, w, h, ltm, WinW, WinH, Window, Font: Integer;
  sPtr, dPtr: pByte;
  Win: pSP_Window_Info;
  Err: TSP_ErrorCode;
  VertSB: pSP_Scrollbar;
Begin

  // Scroll the editor by d pixels - copy the entire surface up or down and then
  // render the lines that are exposed by the move.

  Window := SCREENBANK;
  Font := SP_SetFPEditorFont;
  SP_GetWindowDetails(FPWindowID, Win, Err);
  SP_SetDrawingWindow(FPWindowID);

  w := FPPaperWidth;
  h := FPPaperHeight;
  WinW := Win^.Width;
  WinH := Win^.Height;
  ltm := h - Abs(d);
  VertSB := @FPScrollBars[SP_FindScrollBar(FPVertSc)];

  If d > 0 Then Begin // Down, so scroll up

    dPtr := pByte(NativeUInt(SCREENPOINTER) + (FPPaperTop  * WinW) + FPPaperLeft);
    sPtr := pByte(NativeUInt(dPtr) + (d * WinW));

    For i := 1 to ltm Do Begin
      CopyMem(dPtr, sPtr, w);
      Inc(sPtr, WinW);
      Inc(dPtr, WinW);
    End;

    // Now draw the bottom lines.

    i := (Trunc(VertSB^.Position + FPFh) Div FPFh) + (h Div FPFh);
    While d >= -FPFh*(2) Do Begin
      SP_DisplayFPListing(i);
      Dec(i);
      Dec(d, FPFh);
    End;

  End Else Begin // Up - scroll down

    dPtr := pByte(NativeInt(SCREENPOINTER) + ((h + FPPaperTop -1) * WinW) + FPPaperLeft);
    sPtr := pByte(NativeInt(dPtr) + (d * WinW));

    For i := 1 to ltm Do Begin
      CopyMem(dPtr, sPtr, w);
      Dec(sPtr, WinW);
      Dec(dPtr, WinW);
    End;

    // Now draw the top lines

    i := (Trunc(VertSB^.Position) Div FPFh);
    While d <= FPFh Do Begin
      SP_DisplayFPListing(i);
      Inc(i);
      Inc(d, FPFh);
    End;

  End;

  SP_DrawScrollBar(FPVertSc);
  If Not EDITORWRAP Then SP_DrawScrollBar(FPHorzSc);

  SP_SetDrawingWindow(Window);
  SP_SetSystemFont(Font, Err);
  SP_InvalidateWholeDisplay;

End;

Procedure LaunchScrollEvent;
Var
  Idx: Integer;
  scEvent: SP_EditorEvent;
Begin

  Idx := 0;
  While Idx < Length(Events) Do
    If Events[Idx].EvType = evtScrollUpdate Then Begin
      Events[Idx].TargetFrame := FRAMES;
      Exit;
    End Else
      Inc(Idx);

  scEvent.evType := evtScrollUpdate;
  scEvent.OnLaunch := SP_FPScrollEvent;
  scEvent.Delay1 := 1;
  scEvent.Delay2 := 1;
  scEvent.TargetFrame := FRAMES;
  scEvent.OneShot := False;
  SP_AddEvent(scEvent);

End;

Procedure SP_FPScrollEvent(Event: pSP_EditorEvent);
Var
  Idx, nPos, Delta: Integer;
  NewPosition, OldPosition: aFloat;
  Updated: Boolean;
  Data: SP_EventData;
Begin

  // Trigger an update.

  Updated := False;
  For Idx := 0 To Length(FPScrollBars) -1 Do
    With FPScrollBars[Idx] Do Begin
      If TargetPos <> Position Then Begin
        NewPosition := Position;
        OldPosition := NewPosition;
        NewPosition := NewPosition + ((TargetPos - NewPosition)/4);
        If TargetPos < 0 Then
          TargetPos := 0
        Else
          If TargetPos + PageSize > TotalSize Then
            TargetPos := TotalSize - PageSize;
        If TargetPos < OldPosition Then
          nPos := Trunc(NewPosition)
        Else
          nPos := Ceil(NewPosition);
        nPos := Max(0, nPos);
        SP_UpdateScrollBar(ID, -1, -1, nPos);
        Delta := Round(nPos - OldPosition);
        SP_DrawScrollBar(ID);
        If Kind = FPVertSc Then Begin // Optimisation for vertical scrolling
          If Delta <> 0 Then
            SP_ScrollEditor(Delta)
          Else
            SmoothMove := False;
        End Else
          SP_DisplayFPListing(-1);
        OnChange(Data);
        Updated := True;
      End Else
        SmoothMove := False;
      Updated := Updated Or SmoothMove;
    End;

  If Updated Then Begin
    SP_EditorEvent(Event^).TargetFrame := FRAMES + 1;
  End Else
    If SP_EditorEvent(Event^).Tag <> 1 Then
      SP_DeleteAllEvents(evtScrollUpdate);

End;

Procedure SP_UpdateScrollBar(ScrollBarID, pSize, tSize, Pos: Integer);
Var
  Idx: Integer;
  ThumbSize, ThumbTop, TrackSize: aFloat;
  ScrollBar: pSP_ScrollBar;
Begin

  Idx := SP_FindScrollBar(ScrollBarID);
  If Idx >= 0 Then ScrollBar := @FPScrollBars[Idx] Else ScrollBar := nil;

  If Assigned(ScrollBar) Then With ScrollBar^ Do Begin

    If pSize > -1 Then PageSize := pSize else pSize := PageSize;
    If tSize > -1 Then TotalSize := tSize else tSize := TotalSize;
    If Pos <> MAXINT Then Position := Pos;

    Case Kind of

      scVertical:
        Begin
          TrackSize := TrackRect.Bottom - TrackRect.Top;
          ThumbSize := TrackSize * (pSize / tSize);
          if Position = 0 Then
            ThumbTop := TrackRect.Top
          Else
            ThumbTop := ((TrackSize - ThumbSize) * (Position / (tSize - pSize))) + TrackRect.Top;
          ThumbRect := Rect(TrackRect.Left, Trunc(ThumbTop), TrackRect.Right, Trunc(ThumbTop + ThumbSize));
        End;

      scHorizontal:
        Begin
          TrackSize := TrackRect.Right - TrackRect.Left;
          ThumbSize := TrackSize * (pSize / tSize);
          if Position = 0 Then
            ThumbTop := TrackRect.Left
          Else
            ThumbTop := ((TrackSize - ThumbSize) * (Position / (tSize - pSize))) + TrackRect.Left;
          ThumbRect := Rect(Trunc(ThumbTop), TrackRect.Top, Trunc(ThumbTop + ThumbSize), TrackRect.Bottom);
        End;

    End;

    UpEnabled := Position > 0;
    DownEnabled := Position + PageSize < TotalSize;
    ThumbEnabled := PageSize < TotalSize;
    If FPWindowID > 0 Then SP_DrawScrollBar(ScrollBar^.ID);

  End;

End;

Procedure SP_DrawScrollBar(ScrollBarID: Integer);
Var
  Idx, Font, Window: Integer;
  UpChar, DownChar: aChar;
  ScrollBar: pSP_ScrollBar;
  Err: TSP_ErrorCode;
Begin

  Font := SP_SetFPEditorFont;
  Idx := SP_FindScrollBar(ScrollBarID);
  If Idx >= 0 Then ScrollBar := @FPScrollBars[Idx] Else ScrollBar := nil;

  Window := SCREENBANK;

  SP_SetDrawingWindow(ScrollBar^.WindowIdx);

  With ScrollBar^ Do Begin

    If Kind = scVertical Then Begin
      UpChar := #251;
      DownChar := #252;
      With BoundsRect Do
        SP_FillRect(Left, Top, Right - Left, Bottom - Top, scrollBack);
    End Else Begin
      UpChar := #254;
      DownChar := #253;
      With BoundsRect Do Begin
        SP_FillRect(Left, Top, Right - Left, Bottom - Top, scrollBack);
      End;
    End;

    // Up arrow

    If UpEnabled Then
      SP_TextOut(-1, UpRect.Left, UpRect.Top, EdCSc + UpChar, scrollActive, -1, True)
    Else
      SP_TextOut(-1, UpRect.Left, UpRect.Top, EdCSc + UpChar, scrollInactive, -1, True);

    // Down Arrow

    If DownEnabled Then
      SP_TextOut(-1, DownRect.Left, DownRect.Top, EdCSc + DownChar, scrollActive, -1, True)
    Else
      SP_TextOut(-1, DownRect.Left, DownRect.Top, EdCSc + DownChar, scrollInactive, -1, True);

    // Track

    With TrackRect Do
      SP_FillRect(Left, Top, Right - Left, Bottom - Top, scrollTrack);

    // Thumb

    If ThumbEnabled Then
      With ThumbRect Do
        SP_FillRect(Left, Top, Right - Left, Bottom - Top, scrollThumb);

  End;

  With ScrollBar^.BoundsRect Do
    SP_SetDirtyRect(Left, Top, Right, Bottom);
  SP_SetDrawingWindow(Window);
  SP_SetSystemFont(Font, Err);

End;

Procedure SP_FPReThinkScrollBars;
Var
  scIdx, Idx, Font: Integer;
  Err: TSP_ErrorCode;
Begin

  Font := SP_SetFPEditorFont;

  FPLongestLineLen := 0;
  For Idx := 0 To Listing.Count -1 Do
    FPLongestLineLen := Max(FPLongestLineLen, Length(Listing[Idx]) + Listing.Flags[Idx].Indent +2);

  FPPageHeight := FPPaperHeight;
  FPPageWidth := FPPaperWidth - (FPGutterWidth * FPFw);
  FPTotalHeight := Listing.Count * FPFh;
  FPTotalWidth := FPLongestLineLen * FPFw;
  scIdx := SP_FindScrollBar(FPVertSc);
  If scIdx > -1 Then
    SP_UpdateScrollBar(FPVertSc, FPPageHeight, FPTotalHeight, Trunc(FPScrollBars[scIdx].Position));
  If Not EDITORWRAP Then Begin
    scIdx := SP_FindScrollBar(FPHorzSc);
    If scIdx > -1 Then
      SP_UpdateScrollBar(FPHorzSc, FPPageWidth, FPTotalWidth, Trunc(FPScrollBars[scIdx].Position));
  End;

  SP_SetSystemFont(Font, Err);

End;

Procedure SP_SetEditorClipping;
Begin

  T_ClipX1 := FPPaperLeft;
  T_ClipY1 := FPPaperTop;
  T_ClipX2 := FPPaperLeft + FPPaperWidth;
  T_ClipY2 := FPPaperTop + FPPaperHeight;

End;

Procedure SP_ClearEditorClipping;
Begin

  T_ClipX1 := CCLIPX1;
  T_ClipY1 := CCLIPY1;
  T_ClipX2 := CCLIPX2 -1;
  T_ClipY2 := CCLIPY2 -1;

End;

Procedure SP_FPApplyHighlighting(Line: Integer);
Var
  CodeLine, SynLine, LastSyntax, AddedEndChars, AddedStartChars, t, s, s2, s3: aString;
  Idx, Idx2, Added, l, m, FindIdx, Ink, Paper, oPaper, Bold, Italic, i, j, k, bp1, bp2: Integer;
  fLine, fPos, fLen: Integer;
  NeedUpdate, GoAgain, CanShowBraces, Done, Found: Boolean;
Begin

  // Applies syntax highlighting to the specified line, and
  // cursor position updated if new characters are inserted
  // (usually an extra space for certain keywords).

  CanShowBraces := (FPBracket1Pos > 0) and (FPBracket2Pos > 0);
  GoAgain := True;
  While GoAgain Do Begin

    Added := 0;
    CodeLine := Listing[Line];
    NeedUpdate := False;

    // If this line has a line number, then strip the preceding spaces out.

    Idx := 1;
    While (Idx <= Length(CodeLine)) And (CodeLine[Idx] <= ' ') Do Inc(Idx);
    If (Idx <= Length(CodeLine)) and (Idx > 1) Then
      If (CodeLine[Idx] in ['0'..'9']) And Not SP_WasPrevSoft(Line) Then Begin
        CodeLine := Copy(CodeLine, Idx);
        If Listing.FPCLine = Line Then
          If Listing.FPCPos >= Idx Then Listing.FPCPos := Listing.FPCPos - (Idx -1)
        Else
          Listing.FPCPos := 1;
          Listing.FPSelLine := Listing.FPCLine;
          Listing.FPSelPos := Listing.FPCPos;
          FPCDes := Listing.FPCPos;
          FPCDesLine := Listing.FPCPos;
        NeedUpdate := True;
      End;

    l := Length(CodeLine);
    Inc(l, Listing.Flags[Line].Indent);
    FPLongestLineLen := Max(l, FPLongestLineLen);

    // Check if this line (and the next line) contain alphanumeric/$ chars at the end/beginning respectively.
    // If so, add them to this line so keywords get highlighted properly.

    AddedEndChars := '';
    If CanShowBraces Then Begin
      i := Line +1;
      While (i < Listing.Count) And Not SP_LineHasNumber_Fast(i) Do Begin
        AddedEndChars := AddedEndChars + Listing[i];
        Inc(i);
      End;
    End Else
      If (Line < Listing.Count -1) And (CodeLine <> '') And
         (CodeLine[Length(CodeLine)] in ['a'..'z', 'A'..'Z', '$']) And
         Not SP_LineHasNumber_Fast(Listing.FPCLine -1) And (Listing.Flags[Line].ReturnType = spSoftReturn) Then Begin
        AddedEndChars := '';
        t := Listing[Line +1];
        While (t <> '') And (t[1] <= ' ') Do Begin
          AddedEndChars := AddedEndChars + ' ';
          t := Copy(t, 2);
        End;
        While (t <> '') And (t[1] in ['a'..'z', 'A'..'Z', '$']) Do Begin
          AddedEndChars := AddedEndChars + t[1];
          t := Copy(t, 2);
        End;
      End;
    CodeLine := CodeLine + AddedEndChars;

    // And the same for chars from the previous line

    AddedStartChars := '';
    If CanShowBraces and (Line > 0) Then Begin
      i := Line;
      If (i > 0) And Not SP_LineHasNumber_Fast(i) Then
        Repeat
          Dec(i);
          AddedStartChars := Listing[i] + AddedStartChars;
        Until (i = 0) Or SP_LineHasNumber_Fast(i);
    End Else
      If (Line > 0) And (CodeLine <> '') And (CodeLine[1] in ['a'..'z', 'A'..'Z', '$', '0'..'9']) And (Listing.Flags[Line -1].ReturnType = spSoftReturn) Then Begin
        t := Listing[Line -1];
        AddedStartChars := '';
        While (t <> '') And (t[Length(t)] in ['a'..'z', 'A'..'Z', '$', '@']) Do Begin
          AddedStartChars := t[Length(t)] + AddedStartChars;
          t := Copy(t, 1, Length(t) -1);
        End;
      End;
    CodeLine := AddedStartChars + CodeLine;

    If CodeLine <> '' Then Begin
      // Start the highlighting with the last highlight applied to the previous line - so get that now.
      LastSyntax := '';
      If Not CanShowBraces Then
        If Not ((CodeLine[1] in ['0'..'9']) And Not SP_WasPrevSoft(Line)) Then Begin
          Ink := -1; Paper := -1; Italic := -1; Bold := -1;
          If Line > 0 Then
            s := SyntaxListing[Line -1]
          else
            s := '';
          i := 1;
          While i < Length(s) Do Begin
            If s[i] < ' ' Then Begin
              Case s[i] of
                #16: // Ink
                  Ink := pLongWord(@s[i+1])^;
                #17: // Paper
                  Paper := pLongWord(@s[i+1])^;
                #26: // Italic
                  Italic := pLongWord(@s[i+1])^;
                #27: // Bold
                  Bold := pLongWord(@s[i+1])^;
                #28: // Reset
                  Begin
                    Ink := -1;
                    Paper := -1;
                  End;
              End;
              Inc(i, 5);
            End Else
              Inc(i);
          End;
          If Ink >= 0 Then s := #16 + LongWordToString(Ink) Else s := '';
          If Paper >= 0 Then s := s + #17 + LongWordToString(Paper);
          If Italic >= 0 Then s := s + #26 + LongWordToString(Italic);
          If Bold >= 0 Then s := s + #27 + LongWordToString(Bold);
          LastSyntax := s;
        End;
      SynLine := SP_SyntaxHighlight(CodeLine, LastSyntax, (CodeLine[1] in ['0'..'9']) And Not SP_WasPrevSoft(Line), Added);

      // Now, if we're showing search results (or hilighting braces), insert the highlight codes. Do this by finding them manually.

      If CanShowBraces and Not IsSelActive Then Begin

        bp1 := -1; bp2 := -1;
        If Line = FPBracket1Line Then Begin
          bp1 := FPBracket1Pos;
          If Line = FPBracket2Line Then
            bp2 := FPBracket2Pos;
        End Else
          If Line = FPBracket2Line Then
            bp2 := FPBracket2Pos;

        if (bp1 >= 0) or (bp2 >= 0) Then Begin
          i := 1;
          j := 1;
          Paper := -1;
          While j < FPBracket1Pos Do Begin
            If SynLine[i] < ' ' Then Begin
              If SynLine[i] = #17 Then
                Paper := pLongWord(@SynLine[i+1])^;
              Inc(i, 5);
            End Else Begin
              Inc(i);
              Inc(j);
            End;
          End;
          While (i < Length(SynLine)) And (SynLine[i] < ' ') Do
            Inc(i, 5);
          If Paper > -1 Then
            t := #17 + LongWordToString(paper)
          Else
            t := NoSearchClr;
          SynLine := Copy(SynLine, 1, i -1) + BraceHltClr + Copy(SynLine, i, 1) + t + Copy(SynLine, i +1);
          If bp2 > 0 Then Begin
            m := Length(t) + Length(BraceHltClr);
            Inc(i, m +1);
            While j < bp2 Do Begin
              If SynLine[i] < ' ' Then Begin
                If SynLine[i] = #17 Then
                  Paper := pLongWord(@SynLine[i+1])^;
                Inc(i, 5);
              End Else Begin
                Inc(i);
                Inc(j);
              End;
            End;
            Dec(i);
            If Paper > -1 Then
              t := #17 + LongWordToString(paper)
            Else
              t := NoSearchClr;
            SynLine := Copy(SynLine, 1, i -1) + BraceHltClr + Copy(SynLine, i, 1) + t + Copy(SynLine, i +1);
          End;
        End;
      End;

      If FPShowingSearchResults Then Begin
        j := 0;
        l := Length(FPFindResults);
        While (j < l) And (FPFindResults[j].Line <= Line) Do Begin
          If FPFindResults[j].Line = Line Then Begin
            fLine := FPFindResults[j].Line;
            fPos := FPFindResults[j].Position + Length(AddedStartChars);
            fLen := FPFindResults[j].Length;
            i := 1; k := 0;
            oPaper := -1;
            Paper := -1;
            Repeat
              If SynLine[i] < ' ' Then Begin
                Case SynLine[i] of
                  #16: // Ink
                    Ink := pLongWord(@SynLine[i+1])^;
                  #17: // Paper
                    If pLongWord(@SynLine[i+1])^ <> pLongWord(@SearchClr[2])^ Then
                      Paper := pLongWord(@SynLine[i+1])^;
                  #26: // Italic
                    Italic := pLongWord(@SynLine[i+1])^;
                  #27: // Bold
                    Bold := pLongWord(@SynLine[i+1])^;
                  #28: // Reset
                    Begin
                      Ink := -1;
                      Paper := -1;
                    End;
                End;
                Inc(i, 5);
              End Else Begin
                Inc(i);
                Inc(k);
              End;
            Until k = fPos;
            Dec(k); Dec(i);
            If Ink >= 0 Then t := #16 + LongWordToString(Ink) Else t := '';
            If Paper >= 0 Then t := t + #17 + LongWordToString(Paper);
            If Italic >= 0 Then t := t + #26 + LongWordToString(Italic);
            If Bold >= 0 Then t := t + #27 + LongWordToString(Bold);
            SynLine := Copy(SynLine, 1, i -1) + SearchClr + Copy(SynLine, i, fLen) + NoSearchClr + t + Copy(SynLine, i + fLen);
          End;
          Inc(j);
        End;
      End;

    End Else
      SynLine := '';

    // Highlighting done, check for new characters - spaces added by expanding a compound keyword.

    If Added > 0 Then Begin
      Idx := 1;
      Idx2 := 1;
      While Idx < Length(CodeLine) - Length(AddedEndChars) Do Begin
        If SynLine[Idx2] < ' ' Then
          Inc(Idx2, 4)
        Else Begin
          If (SynLine[Idx2] = ' ') And (CodeLine[Idx] <> ' ') Then Begin
            CodeLine := Copy(CodeLine, 1, Idx -1) + ' ' + Copy(CodeLine, Idx);
            If (Listing.FPCPos >= Idx) And (Listing.FPCLine = Line) Then Begin
              Listing.FPCPos := Listing.FPCPos + 1;
              If Listing.FPSelLine = Listing.FPCLine Then
                Inc(Listing.FPSelPos);
            End;
            NeedUpdate := True;
          End Else
            If CodeLine[Idx] <> SynLine[Idx2] Then
              CodeLine[Idx] := SynLine[Idx2];
          Inc(Idx);
        End;
        Inc(Idx2);
      End;
    End;

    // Remove the added characters from previous/next lines
    // SynLine contains all the same characters, but interspersed with escape sequences for ink/paper/italic/bold

    // First, remove the characters added to the start, but preserve any colours.

    If AddedStartChars <> '' Then Begin
      Ink := -1; Paper := -1; Italic := -1; Bold := -1;
      i := 1;
      s := '';
      s2 := Lower(AddedStartChars);
      s3 := Lower(SynLine);
      Done := False;
      While Not Done Do Begin
        If s3[i] < ' ' Then Begin
          Case s3[i] of
            #16: // Ink
              Ink := pLongWord(@s3[i+1])^;
            #17: // Paper
              Paper := pLongWord(@s3[i+1])^;
            #26: // Italic
              Italic := pLongWord(@s3[i+1])^;
            #27: // Bold
              Bold := pLongWord(@s3[i+1])^;
            #28: // Reset
              Begin
                Ink := -1;
                Paper := -1;
              End;
          End;
          Inc(i, 5);
        End Else Begin
          s := s + s3[i];
          Inc(i);
        End;
        Done := s = s2;
      End;
      If Ink >= 0 Then s := #16 + LongWordToString(Ink) Else s := '';
      If Paper >= 0 Then s := s + #17 + LongWordToString(Paper);
      If Italic >= 0 Then s := s + #26 + LongWordToString(Italic);
      If Bold >= 0 Then s := s + #27 + LongWordToString(Bold);
      SynLine := s + Copy(SynLine, i);
      CodeLine := Copy(CodeLine, Length(AddedStartChars) +1);
    End;

    // Now get everything that belongs to CodeLine, so the added characters at the end get chopped off.
    // No need to track colours for this.

    If AddedEndChars <> '' Then Begin
      CodeLine := Copy(CodeLine, 1, Length(CodeLine) - Length(AddedEndChars));
      i := 1; m := 1; l := Length(Codeline);
      s := Lower(SynLine);
      s2 := Lower(CodeLine);
      While i < Length(SynLine) Do Begin
        If s[i] < ' ' Then
          Inc(i, 5)
        Else
          If s[i] = s2[m] Then Begin
            Inc(i);
            Inc(m);
            If m > l Then
              Break;
          End Else
            Break;
      End;
      SynLine := Copy(SynLine, 1, i -1);
    End;

    // Set the original in the listing to the new version with added spaces if necessary.

    If NeedUpdate Then
      Listing[Line] := CodeLine;

    // Go around again with the next line if this one changed.

    GoAgain := (Line < Listing.Count -1) And (SynLine <> SyntaxListing[Line]) And not (CanShowBraces or FPShowingSearchResults);
    SyntaxListing[Line] := SynLine;
    Inc(Line);

  End;

End;

Function SP_GetCharPos(Const Txt: aString; Ps: Integer): Integer;
Var
  Ln: Integer;
Begin

  Result := 1;
  Ln := Length(Txt);
  While (Result <= Ln) And (Txt[Result] < ' ') Do Inc(Result, 5);
  While (Ps > 1) And (Result <= Ln) Do Begin
    Dec(Ps);
    Inc(Result);
    While (Result <= Ln) And (Txt[Result] < ' ') Do Inc(Result, 5);
  End;

End;

Procedure SP_GetSelectionInfo(Var Sel: SP_SelectionInfo);
Begin

  If (Listing.FPCLine <> Listing.FPSelLine) or (Listing.FPCPos <> Listing.FPSelPos) Then Begin

    Sel.Active := True;
    Sel.StartL := Min(Listing.FPCLine, Listing.FPSelLine);
    Sel.EndL := Max(Listing.FPCLine, Listing.FPSelLine);
    If Sel.StartL = Listing.FPCLine Then Begin
      If Sel.EndL = Sel.StartL Then Begin
        Sel.StartP := Min(Listing.FPCPos, Listing.FPSelPos);
        Sel.EndP := Max(Listing.FPCPos, Listing.FPSelPos);
      End Else Begin
        Sel.StartP := Listing.FPCPos;
        Sel.EndP := Listing.FPSelPos;
      End;
    End Else Begin
      Sel.StartP := Listing.FPSelPos;
      Sel.EndP := Listing.FPCPos;
    End;
    Sel.Multiline := Sel.StartL <> Sel.EndL;

    Sel.Dir := -1;
    If Listing.FPCLine < Listing.FPSelLine Then
      Sel.Dir := 1
    Else
      If Listing.FPCLine = Listing.FPSelLine Then
        If Listing.FPCPos < Listing.FPSelPos Then
          Sel.Dir := 1;
    If Sel.Dir = 1 Then
      Sel.EndP := Max(Sel.EndP -1, 1);

  End Else Begin

    Sel.Active := False;
    Sel.StartL := -1;
    Sel.EndL := -1;
    Sel.StartP := -1;
    Sel.EndP := -1;
    Sel.Dir := 0;
    Sel.Multiline := False;

  End;

End;

Function SP_LineIsMarked(Idx: Integer): Integer;
Var
  i: Integer;
Begin

  Result := -1;
  Idx := (Idx +1) Shl 16;
  For i := 0 To 9 Do
    If (EditorMarks[i] And $FFFF0000) = Idx Then
      Exit(i+1);

End;

Function SP_GetLineNumberFromIndex(Var Idx: Integer): Integer;
Begin

  // Returns the line number of the line Idx occupies.

  Result := -1;
  While (Idx >= 0) And (SP_LineHasNumber(Idx) = 0) Do Dec(Idx);
  If Idx > -1 Then
    If SP_LineHasNumber(Idx) > 0 Then
      Result := SP_GetFPLineNumber(Idx);

End;

Function SP_FindFPLine(LineNum: Integer): Integer;
Begin

 // Returns the index in the listing of the line with the specified line number.

  Result := 0;
  While Result < Listing.Count Do Begin
    If (SP_GetFPLineNumber(Result) = LineNum) And Not SP_WasPrevSoft(Result) Then
      Exit;
    Inc(Result);
  End;

  // We didn't find it, so find the next-larger line number.

  Result := 0;
  While Result < Listing.Count Do Begin
    If (SP_GetFPLineNumber(Result) >= LineNum) And Not SP_WasPrevSoft(Result) Then
      Exit;
    Inc(Result);
  End;
  Result := -1;

End;

Function SP_FindFPLineStatement(LineNum, Statement: Integer): TPoint;
var
  Idx, cIdx, St, Org: Integer;
  Done, InString: Boolean;
  s: aString;
Begin

  Result := Point(-1, -1);
  St := 1;
  Idx := SP_FindFPLine(LineNum);
  InString := False;

  If Idx > -1 Then Begin
    While (Idx < Listing.Count) And (Listing.Flags[idx].Statement < Statement) And (Listing.Flags[idx].Line = LineNum) Do
      Inc(idx);
    If Idx = Listing.Count Then
      Dec(Idx)
    Else
      If (Listing.Flags[Idx].Statement > Statement) And (Listing.Flags[idx].Line = LineNum) Then
        Dec(Idx);
    Result.Y := 1;
    While Listing[Idx][Result.Y] in ['0'..'9', ' '] Do
      Inc(Result.Y);
    Result.X := Idx;
  End;

End;

Function  SP_CheckForConflict(LineIndex: Integer): Boolean;
Var
  Idx, Line: Integer;
  Found: Boolean;
Begin

  // Counts instances of a given line number. If more than one, then a conflict.

  Idx := 0;
  Found := False;
  Result := False;
  Line := SP_GetLineNumberFromIndex(LineIndex);
  While (Idx < Listing.Count) And (Idx <> LineIndex) Do Begin
    If SP_LineHasNumber(Idx) > 0 Then
      If SP_GetLineNumberFromText(Listing[Idx]) = Line Then Begin
        Result := True;
        Break;
      End;
    Inc(Idx);
  End;

End;

Function  SP_GetLineIndex(LineNum: Integer): Integer;
Begin

  // Result holds the index of the line desired, or the index of the line after it if it doesn't exist.
  // Result will be out of bounds is not existing at all.

  Result := 0;
  While (Result < Listing.Count) And ((SP_GetLineNumberFromText(Listing[Result]) < LineNum) Or SP_WasPrevSoft(Result)) Do
    Inc(Result);

End;

Function SP_GetExactLineIndex(LineNum: Integer): Integer;
Begin

  Result := 0;
  While (Result < Listing.Count) And ((SP_GetLineNumberFromText(Listing[Result]) < LineNum) Or SP_WasPrevSoft(Result)) Do
    Inc(Result);
  If Result < Listing.Count Then
    If (SP_GetLineNumberFromText(Listing[Result]) <> LineNum) or (SP_WasPrevSoft(Result)) Then
      Result := Listing.Count;

End;

Function SP_GetLineNumberFromText(Const Txt: aString): Integer;
Var
  i: Integer;
Begin

  i := 1;
  Result := 0;
  While (i <= Length(Txt)) And (Txt[i] <= ' ') Do Inc(i);
  While (i <= Length(Txt)) And (Txt[i] in ['0'..'9']) Do Begin
    Result := (Result * 10) + Ord(Txt[i]) - 48;
    Inc(i);
  End;

End;

Function SP_GetFPLineNumber(Idx: Integer): Integer;
Var
  s: aString;
Begin

  s := Listing[Idx];
  If SP_WasPrevSoft(Idx) Then
    Result := -1
  Else
    Result := SP_GetLineNumberFromText(s);

End;

Function SP_GetLineTextFromNumber(Num: Integer): aString;
Var
  Idx: Integer;
Begin

  // Grabs the text of a line including all statements.

  Result := '';
  Idx := SP_FindFPLine(Num);
  If Idx > -1 Then Begin
    Result := Listing[Idx];
    Inc(Idx);
    While (Idx < Listing.Count) And ((SP_LineHasNumber(Idx) = 0) Or SP_WasPrevSoft(Idx)) Do Begin
      Result := Result + Listing[Idx];
      Inc(Idx);
    End;
  End;

End;

Function SP_GetRightText(Const s, p: aString): Boolean;
Var
  l,m: Integer;

Begin

  // Checks for the presence of string p at the end of string s, ignoring whitespace.

  l := Length(p);
  m := Length(s);
  If s <> '' Then
    While (m >= 1) And (s[m] <= ' ') Do Dec(m);
  Dec(m, l -1);
  Result := Copy(s, m, l) = p;

End;

Function SP_GetLeftText(Const s, p: aString): Boolean;
Var
  l,m: Integer;

Begin

  // Checks for the presence of string p at the start of string s, ignoring whitespace.

  l := Length(s);
  m := 1;
  While (m < l) And (s[m] <= ' ') Do
    Inc(m);

  l := Length(p);
  Result := Copy(s, m, l) = p;

End;

Function SP_StriphighlightedTrailingSpaces(Const Line: aString): aString;
Var
  i, LastCharAt: Integer;
Begin

  i := 1;
  LastCharAt := -1;
  While i <= Length(Line) Do Begin
    If Line[i] < ' ' Then
      Inc(i, 5)
    Else Begin
      LastCharAt := i;
      Inc(i);
    End;
  End;

  If (LastCharAt > 0) And (Line[LastCharAt] <= ' ') Then
    Result := Copy(Line, 1, LastCharAt -1)
  Else
    Result := Line;

End;

Procedure SP_FillFlags;
Var
  s: aString;
  Idx, St, LineNum: Integer;
  InString, InREM, InClr: Boolean;
Begin

  For Idx := 0 To Listing.Count -1 Do Begin

    s := Listing[Idx];
    LineNum := SP_GetLineNumberFromText(s);
    If LineNum > 0 Then Begin
      St := 1;
      InString := False;
      InREM := False;
      InClr := False;
    End;

    Listing.Flags[Idx].Line := LineNum;
    Listing.Flags[Idx].Statement := St;

    ScanForStatements(s, St, InString, InREM, InClr);

  End;

End;

Procedure ScanForStatements(Const s: String; Var St: Integer; Var InString, InREM, InClr: Boolean);
Var
  i: Integer;
  NewWord: aString;
Begin

  // Scan a line of code. If we encounter a ":", "THEN" or "ELSE" then increment the statement number supplied.
  // Only in non-strings though!
  // THIS IS SLOW :)

  If InREM then Exit;
  i := 1;
  While i <= Length(s) Do Begin
    If s[i] = '"' Then Begin
      InString := Not InString;
      Inc(i);
    End Else
      If Not Instring Then Begin
        If s[i] = ':' Then Begin
          Inc(St);
          InClr := False;
          Inc(i);
        End Else
          If (s[i] = ';') And Not InClr Then Begin
            Inc(St);
            Inc(i);
          End Else Begin
            NewWord := '';
            While (i <= Length(s)) and (s[i] in ['A'..'Z']) Do Begin
              NewWord := NewWord + s[i];
              Inc(i);
            End;
            If (NewWord = 'THEN') or (NewWord = 'ELSE') Then
              Inc(St)
            Else
              If NewWord = 'REM' Then Begin
                InREM := True;
                Exit;
              End Else
                If (NewWord = 'CIRCLE') or (NewWord = 'INPUT') or (NewWord = 'PRINT') or (NewWord = 'TEXT') or
                   (NewWord = 'PLOT') or (NewWord = 'DRAW') or (NewWord = 'ELLIPSE') or (NewWord = 'CURVE') or
                   (NewWord = 'RECTANGLE') or (NewWord = 'POLYGON') or (NewWord = 'FILL') or (NewWord = 'MULTIPLOT') Then
                    InClr := True;
            If NewWord = '' Then
              Inc(i);
          End;
      End Else
        Inc(i);
  End;

End;

// Does the whole editor displaying thing. Formats to the required state - line numbers in the gutter, line breaks etc.

Procedure SP_DisplayFPListing(Line: Integer);
Var
  Idx, cIdx, dIdx, Cpx, OfsY, OfsX, Digits, Ps, st, LineNum, Window, cursLineNum, MinY, MaxY, yPartTop, yPartBottom, ty, i, j: Integer;
  vScTrackTop, vScTrackHeight, SelectionStartsAt, Font, pClr, gClr, l, OldSt, x, y, ContIdx, llbpx, llbpy: Integer;
  HasNumber, ContainsSelection, Editing, DoneProgline, DontDoProgLine, IsProgLine, Highlight, DoDraw, DoDrawSt, InString,
  InREM, InClr, DrawnCONTLocation: Boolean;
  CodeLine, NumberLine, EmptyGutter, s, IndStr, tempS: aString;
  VertSB, HorzSB: pSP_ScrollBar;
  Sel: SP_SelectionInfo;
  Win: pSP_Window_Info;
  Err: TSP_ErrorCode;
  fx, fy: aFloat;
Label
  Finished;
Begin

  If Line >= 0 Then RemoveDirtyLine(Line);

  DisplaySection.Enter;

  UpdateStatusLabel;
  DrawnCONTLocation := False;

  If FPGutterChangedSize Then Begin
    Line := -1;
    If Not EDITORWRAP Then SP_FPUpdateHorzScrollBar;
    FPGutterChangedSize := False;
  End;

  Window := SCREENBANK;
  Font := SP_SetFPEditorFont;
  SP_GetWindowDetails(FPWindowID, Win, Err);
  SP_SetDrawingWindow(FPWindowID);
  Editing := FocusedWindow <> fwDirect;
  If Editing Then Begin
    dIdx := Listing.FPCLine;
    cursLineNum := SP_GetLineNumberFromIndex(dIdx);
  End;
  VertSB := @FPScrollBars[SP_FindScrollBar(FPVertSc)];
  If Not EDITORWRAP Then
    HorzSB := @FPScrollBars[SP_FindScrollBar(FPHorzSc)]
  Else
    HorzSB := nil;

  SP_ClearEditorClipping;

  // Display the current editor's page - start point determined by scrollbar position.
  // Formats numbers into the gutter and highlights keywords/numbers/symbols/strings

  If Line < 0 Then Begin

    ClearDirtyLines; // We're going to draw all the visible lines, so no need for buffered rendering

    // Fill the window - note: using the client region for this!

    SP_FillRect(FPClientLeft, FPClientTop, FPClientWidth, FPClientHeight, paperClr);

    // Draw the Gutter

    SP_FillRect(FPClientLeft, FPClientTop, FPPaperLeft + (FPFw * FPGutterWidth), FPClientHeight, gutterClr);

  End;

  EmptyGutter := StringOfChar(aChar(' '), FPGutterWidth);

  // Start drawing lines of code

  DoneProgLine := False;
  DontDoProgLine := False;
  SP_SetEditorClipping;
  If Listing.Count > 0 Then Begin

    // Because the scrollbars can be mid-line (smooth scrolling) we need to determine which line we're starting at and its Y-Coord.

    Idx := 0;
    If CONTLINE >= 0 Then
      ContIdx := SP_GetLineNumber(CONTLINE)
    Else
      ContIdx := -10;
    OfsY := FPPaperTop - Trunc(VertSB^.Position);
    MinY := -(Trunc(VertSB^.Position) Mod FPFh) + FPPaperTop;
    MaxY := FPPaperHeight + FPPaperTop;
    If EDITORWRAP Then
      Ofsx := FPGutterWidth * FPFw
    Else
      OfsX := -Trunc(HorzSB^.Position) + (FPGutterWidth * FPFw);
    yPartTop := MinY - FPPaperTop;
    yPartBottom := (MaxY - OfsY) Mod FPFh;

    SP_GetSelectionInfo(Sel);

    // If this is a line beyond the listing's bounds then we might be erasing the last line in the program due
    // to a deleted line further up so draw the blank editor paper.

    ty := OfsY + (Line * FPFh);
    If (Line >= Listing.Count) And (ty <= MaxY) Then Begin
      SP_FillRect(FPPaperLeft, ty, (FPFw * FPGutterWidth) +1, FPFh, gutterClr);
      SP_FillRect((FPGutterWidth * FPFw) + FPPaperLeft +1, ty, FPPaperWidth - (FPGutterWidth * FPFw), FPFh, paperClr);
      Goto Finished;
    End;

    // Determine which statement we start at.

    If Line < 0 Then st := Idx Else St := Line;
    While (St > 0) And (SP_LineHasNumber(St) = 0) Do Dec(St);
    LineNum := SP_GetFPLineNumber(St);
    If Line < 0 Then St := (Idx - St) +1 Else St := Line - St;
    InString := False;
    InREM := False;
    InClr := False;
    OldSt := St;

    While (Idx < Listing.Count) And (OfsY <= MaxY) Do Begin

      DoDraw := OfsY >= MinY;

      tempS := Upper(Listing[Idx]) + ' ';
      If SP_LineHasNumber(Idx) <> 0 Then Begin
        St := 1;
        OldSt := 1;
        InString := False;
        InREM := False;
        InClr := False;
      End Else
        If SP_GetLeftText(tempS, 'ELSE') Then
          Inc(St);
      DoDrawSt := OldSt <> St;

      If (Line < 0) or (Idx = Line) Then Begin
        // Draw the gutter and paper for a single line
        cIdx := LineNum;
        If SP_WasPrevSoft(Idx) Then LineNum := 0 Else LineNum := SP_GetFPLineNumber(Idx);
        If (LineNum <> 0) And (DoneProgLine) Then DontDoProgLine := True;
        If LineNum <= 0 Then LineNum := cIdx;
        IsProgLine := Not Editing And (LineNum = PROGLINE) And Not DontDoProgLine;
        If IsProgLine Then Begin
          cIdx := Idx;
          pClr := proglineClr;
          gClr := proglineGtr;
          DoneProgLine := True;
          If StripSpaces(Listing[Idx]) = '' Then Begin
            While (cIdx < Listing.Count) And (StripLeadingSpaces(Listing[cIdx]) = '') Do Inc(cIdx);
            If (cIdx = Listing.Count) or ((cIdx < Listing.Count) And (SP_LineHasNumber(cIdx) > 0)) Then Begin
              pClr := paperClr;
              gClr := gutterClr;
            End;
          End;
        End Else Begin
          pClr := paperClr;
          gClr := gutterClr;
        End;
        If DoDraw Then Begin
          SP_FillRect(FPPaperLeft, OfsY, (FPFw * FPGutterWidth) +1, FPFh, gClr);
          SP_FillRect((FPGutterWidth * FPFw) + FPPaperLeft +1, OfsY, FPPaperWidth - (FPGutterWidth * FPFw), FPFh, pClr);
        End;
        // Current line highlight
        dIdx := Idx;
        If DoDraw Then Begin
          Highlight := (FocusedWindow = fwEditor) And Editing And (SP_GetLineNumberFromIndex(dIdx) = cursLineNum) And Not Sel.Multiline;
          If Highlight Then Begin
            SP_FillRect(FPPaperLeft, OfsY, (FPFw * FPGutterWidth) +1, FPFh, gClr +1);
            SP_FillRect((FPGutterWidth * FPFw) + FPPaperLeft +1, OfsY, FPPaperWidth - (FPGutterWidth * FPFw), FPFh, lineClr);
          End;
        End;
        If SyntaxListing[Idx] = '' Then SP_FPApplyHighlighting(Idx);
        CodeLine := SyntaxListing[Idx];
        // If this line is part of a selection then insert the necessary colour commands now
        ContainsSelection := False;
        If (Sel.Active) And Editing Then
          If (Idx >= Sel.StartL) And (Idx <= Sel.EndL) Then Begin
            If (Idx <> Sel.StartL) And (Idx <> Sel.EndL) Then Begin
              CodeLine := SelClr + CodeLine;
              SelectionStartsAt := 1;
              ContainsSelection := True;
            End Else Begin
              If Idx = Sel.StartL Then Begin // Line containing Selection start?
                Ps := SP_GetCharPos(CodeLine, Sel.StartP);
                CodeLine := Copy(CodeLine, 1, Ps -1) + SelClr + Copy(CodeLine, Ps);
                SelectionStartsAt := Ps;
                ContainsSelection := True;
              End;
              If Idx = Sel.EndL Then Begin // Line ends the selection?
                Ps := SP_GetCharPos(CodeLine, Sel.EndP) +1;
                If Not Sel.Multiline And (Idx = Listing.FPCLine) Then
                  CodeLine := Copy(CodeLine, 1, Ps -1) + #17 + aChar(lineClr) + #0#0#0 + Copy(CodeLine, Ps)
                Else
                  CodeLine := Copy(CodeLine, 1, Ps -1) + BackClr + Copy(CodeLine, Ps);
                If Idx <> Sel.StartL Then Begin
                  CodeLine := SelClr + CodeLine;
                  SelectionStartsAt := 1;
                  ContainsSelection := True;
                End;
              End;
            End;
          End;
        // As you can see, selections make things really complex.
        // Pad the line number to align with the gutter if it exists
        dIdx := 1;
        l := Length(CodeLine);
        If StripSpaces(CodeLine) <> '' Then Begin
          HasNumber := False;
          Cpx := 0;
          While CodeLine[dIdx] < ' ' Do Inc(dIdx, 5);
          cIdx := dIdx;
          If Not SP_WasPrevSoft(Idx) Then
            While (cIdx < l) And (CodeLine[cIdx] in ['0'..'9']) Do Begin
              HasNumber := True;
              Inc(Cpx);
              Inc(cIdx);
              While (cIdx < l) And (CodeLine[cIdx] < ' ') Do
                Inc(cIdx, 5);
            End;
          // If the line has a number, then draw it in the gutter.
          If HasNumber Then Begin
            St := 1;
            NumberLine := StringOfChar(aChar(' '), FPGutterWidth - Cpx) + Copy(CodeLine, 1, cIdx -1);
            If DoDraw Then
              If ContainsSelection Then
                SP_TextOut(-1, FPPaperLeft +1, OfsY, EDSc + NumberLine, 0, gutterClr, True)
              Else
                SP_TextOut(-1, FPPaperLeft +1, OfsY, EDSc + NumberLine, 0, -1, True);
            DoDrawSt := False;
            Listing.Flags[Idx].Line := LineNum;
            Listing.Flags[Idx].Statement := 1;
          End Else Begin
            cIdx := 1;
          End;
          T_CLIPX1 := FPGutterWidth * FPFw + FPPaperLeft;
          // More selection compensations - if this line contains the end of the selection, then
          // prefix it with selection paper commands. Maybe. Depending on if the selection starts
          // in the gutter or not.
          If ContainsSelection Then Begin
            If (Idx = Sel.EndL) And (Sel.EndP > Cpx) And Sel.Multiline Then
              NumberLine := SelClr
            Else
              If (Idx = Sel.EndL) And (SelectionStartsAt <= cIdx) And (Ps >= cIdx) Then
                NumberLine := SelClr
              Else
                If (Idx >= Sel.StartL) And (Idx < Sel.EndL) And (SelectionStartsAt <= cIdx) Then
                  NumberLine := SelClr
                Else
                  NumberLine := '';
          End Else
            NumberLine := '';
          // And now draw the rest of the line.
          IndStr := StringOfChar(' ', Listing.Flags[Idx].Indent);
          If DoDraw Then
            If Highlight Then Begin
              s := SP_StriphighlightedTrailingSpaces(Copy(CodeLine, cIdx));
              SP_TextOut(-1, OfsX + FPPaperLeft +1, OfsY, Edsc + NumberLine + IndStr + s, 0, LineClr, True);
            End Else
              SP_TextOut(-1, OfsX + FPPaperLeft +1, OfsY, Edsc + NumberLine + IndStr + Copy(CodeLine, cIdx), 0, pClr, True);
          T_CLIPX1 := FPClientLeft;
        End;
        // Clear scaling for drawing small font items
        If DoDraw Then Begin
          fy := T_SCALEY;
          fx := T_SCALEX;
          T_SCALEY := 1;
          T_SCALEX := 1;
          T_ITALIC := 0;
          T_BOLD := 0;
        End;

        // Draw the breakpoint if one exists here
        If (HasNumber or doDrawSt) and SP_IsSourceBreakPoint(LineNum, St) Then Begin
          llbpx := FPPaperLeft +2; llbpy := OfsY + ((FPFh - 8) Div 2);
          For i := -1 to 1 Do
            For j := -1 to 1 Do
              SP_TextOut(-1, llbpx +i, llbpy +j, #243, 2, -1, True);
          SP_FillRect(llbpx +1, llbpy + (fH Div 2) -1, fW -2, 2, 15);

        End;

        // Draw the CONTINUE statement position indicator if we're there
        If (HasNumber or DoDrawSt) And (CONTIdx = LineNum) And
           ((St = CONTSTATEMENT) or ((St < CONTSTATEMENT) and
           ((Listing.Flags[Idx+1].Statement > CONTSTATEMENT) or {(Listing.Flags[Idx +1].Statement = 1) or} (Idx +1 = Listing.Count)))) and Not DrawnCONTLocation Then Begin
          For i := -1 to 1 Do
            For j := -1 to 1 Do
              SP_TextOut(-1, FPPaperLeft +12 +i, OfsY + ((FPFh - 8) Div 2) +j, #253, 0, -1, True);
          If PROGSTATE = SP_PR_RUN Then
            i := 2
          Else
            i := 6;
          SP_TextOut(-1, FPPaperLeft + 12, OfsY + ((FPFh - 8) Div 2), #253, i, -1, True);
          DrawnCONTlocation := True;
        End;

        // Draw the statement number - only if there's no line number
        If Not HasNumber And (StripSpaces(CodeLine) <> '') And (Idx > 0) And Not (Listing.Flags[Idx -1].ReturnType = spSoftReturn) Then Begin
          NumberLine := IntToString(St);
          If IsProgLine Then
            Ps := 4
          Else
            If (Idx = Listing.FPCLine) And Not Sel.MultiLine Then
              Ps := gClr +1
            Else
              Ps := gClr;
          If DoDraw And DoDrawSt Then Begin
            SP_TextOut(-1, FPPaperLeft + (FPGutterWidth * FPFw) - (Length(NumberLine) * 8) - ((FPFw - 8) Div 2), OfsY + ((FPFh - 8) Div 2), IntToString(St), Ps -4, -1, True);
            DoDrawSt := False;
          End;
          Listing.Flags[Idx].Line := LineNum;
          Listing.Flags[Idx].Statement := St;
        End;

        cIdx := Listing.Flags[Idx].State;
        If DoDraw And (StripSpaces(Listing[Idx]) <> '') And (HasNumber Or (cIdx in [spLineError, spLineDirty])) Then
          Case cIdx of
            spLineNull:
              Begin
                SP_TextOut(-1, FPPaperLeft +2, OfsY + ((FPFh - 8) Div 2), #245, gclr -1, -1, True);
                SP_TextOut(-1, FPPaperLeft +2, OfsY + ((FPFh - 8) Div 2), #244, gclr +1, -1, True);
              End;
            spLineOk:
              Begin
                SP_TextOut(-1, FPPaperLeft +2, OfsY + ((FPFh - 8) Div 2), #245, 0, -1, True);
                SP_TextOut(-1, FPPaperLeft +2, OfsY + ((FPFh - 8) Div 2), #244, 4, -1, True);
              End;
            spLineError:
              Begin
                SP_TextOut(-1, FPPaperLeft +2, OfsY + ((FPFh - 8) Div 2), #243, 0, -1, True);
                SP_TextOut(-1, FPPaperLeft +2, OfsY + ((FPFh - 8) Div 2), #245, 2, -1, True);
              End;
            spLineDirty:
              Begin
                SP_TextOut(-1, FPPaperLeft +2, OfsY + ((FPFh - 8) Div 2), #245, 0, -1, True);
                SP_TextOut(-1, FPPaperLeft +2, OfsY + ((FPFh - 8) Div 2), #244, 1, -1, True);
              End;
            spLineDuplicate:
              Begin
                SP_TextOut(-1, FPPaperLeft +2, OfsY + ((FPFh - 8) Div 2), #243, 0, -1, True);
                SP_TextOut(-1, FPPaperLeft +2, OfsY + ((FPFh - 8) Div 2), #245, 6, -1, True);
              End;
          End;
        // Draw bookmarks if necessary
        cIdx := SP_LineIsMarked(Idx);
        If DoDraw And (cIdx > 0) Then
          SP_TextOut(-1, FPPaperLeft + 12, OfsY + ((FPFh - 8) Div 2), IntToString(cIdx), 0, 4, True);
        // Restore scaling
        If DoDraw Then Begin
          T_SCALEX := fx;
          T_SCALEY := fy;
        End;
      End;
      OldSt := St;
      ScanForStatements(tempS, St, InString, InREM, InClr);
      Inc(Idx);
      Inc(OfsY, FPFh);
    End;

  End;

  // Now draw the scrollbars. Vertical first:

  Finished:

  SP_ClearEditorClipping;
  SP_DrawScrollBar(FPVertSc);
  If Not EDITORWRAP Then SP_DrawScrollBar(FPHorzSc);
  If FocusedWindow = fwEditor Then SP_DisplayFPCursor;
  SP_SetDrawingWindow(Window);
  SP_SetSystemFont(Font, Err);
  SP_InvalidateWholeDisplay;

  DisplaySection.Leave;

End;

Function SP_ScrollInView(Force: Boolean = False): Boolean;
Var
  Extents: TPoint;
  VertSB, HorzSB: pSP_ScrollBar;
  TenPercentW, TenPercentH, Cx, Cy, OfsX, OfsY, Idx, mn, mx, tpx, tpy: Integer;
  Direct: Boolean;
Label
  Skip;
Begin

  // The "View" is a rectangle inside the main display, about 10% from the edge, not including the gutter.
  // If the cursor is outside this area then adjust the scrollbars until it's back inside.

  SP_FPRethinkScrollBars;

  VertSB := @FPScrollBars[SP_FindScrollBar(FPVertSc)];
  If Not EDITORWRAP Then
    HorzSB := @FPScrollBars[SP_FindScrollBar(FPHorzSc)]
  Else
    HorzSB := nil;

  TenPercentH := VertSB.PageSize Div 4;
  If Not EditorWrap Then
    TenPercentW := HorzSB.PageSize Div 4;

  SP_CalculateFPCursorPos;

  mn := Round(VertSB.TargetPos + TenPercentH);
  mx := Round(VertSB.TargetPos + VertSB.PageSize - TenPercentH);
  Direct := False;

  If FocusedWindow = fwEditor Then Begin
    If Not EDITORWRAP Then Begin
      OfsX := -Trunc(HorzSB^.Position) + (FPGutterWidth * FPFw) + FPPaperLeft;
      Cx := CURSORX - OfsX;
    End;
    Cy := Listing.FPCLine * FPFh;
  End Else Begin
    Extents := SP_GetLineExtents(SP_GetLineIndex(PROGLINE));
    Cy := Extents.X * FPFh;
    Cx := (Extents.Y * FPFh) + FPFh -1;
    Direct := True;
  End;

  // First, sort out the Y position.

  tpy := Trunc(VertSB.Position);
  If Not EDITORWRAP then
    tpx := Trunc(HorzSB.Position);

  If Direct Then Begin
    Dec(mn, TenPercentH - FPFh);
    Inc(mx, TenPercentH - FPFh);
    TenPercentH := FPFh;
    // Showing a highlighted line, so try to fit it in. If it's larger than the page, then scroll to the first line, at the top.
    // If it fits, then - if the bottom is not visible then scroll to make the bottom visible. If the top is not visible then scroll to make
    // the top visible.
    If (Cx - Cy) >= (mx - mn) Then Begin
      VertSB.TargetPos := Cy;
      Goto Skip;
    End Else
      If Cx > mx Then
        Cy := Cx;
  End;

  If Cy < mn Then
    VertSB.TargetPos := Max(Cy - TenPercentH, 0)
  Else
    If Cy > mx Then
      VertSB.TargetPos := Min(Max(0, Cy - VertSB.PageSize + TenPercentH), VertSB.TotalSize - VertSB.PageSize);


  // Then sort out the X position if editor wrapping is disabled.

  Skip:

  If Not EDITORWRAP Then Begin

    mn := Round(HorzSB.TargetPos + TenPercentW);
    mx := Round(HorzSB.TargetPos + HorzSB.PageSize - TenPercentW);

    If not Direct Then Begin
      If Cx < mn Then
        HorzSB.TargetPos := Max(0, Cx - TenPercentW)
      Else
        If Cx > mx Then
          HorzSB.TargetPos := Min(Max(0, Cx - HorzSB.PageSize + TenPercentW), HorzSB.TotalSize - HorzSB.PageSize);
    End Else
      HorzSB.TargetPos := 0;

  End;

  Result := (Trunc(VertSB.TargetPos) <> tpy) or (Assigned(HorzSB) And (Trunc(HorzSB.TargetPos) <> tpx));
  If Result or Force Then Begin
    VertSB.SmoothMove := True;
    If Assigned(HorzSB) Then
      HorzSB.SmoothMove := True;
    LaunchScrollEvent;
  End;

End;

Procedure SP_CalculateFPCursorPos;
Var
  Idx, Cpx, OfsX, OfsY, Fg, Bg, Lc, LL, sl: Integer;
  VertSB, HorzSB: pSP_ScrollBar;
  s: aString;
Begin

  VertSB := @FPScrollBars[SP_FindScrollBar(FPVertSc)];
  Idx := Trunc(VertSB^.Position/FPFh);
  OfsY := -(Trunc(VertSB^.Position) Mod FPFh) + FPPaperTop;
  CURSORY := OfsY + ((Listing.FPCLine - Idx) * FPFh);
  If Not EDITORWRAP Then Begin
    HorzSB := @FPScrollBars[SP_FindScrollBar(FPHorzSc)];
    Cpx := Trunc(HorzSB^.Position/FPFw);
    OfsX := -Trunc(HorzSB^.Position) + (FPGutterWidth * FPFw) + FPPaperLeft;
  End Else Begin
    Cpx := 0;
    OfsX := (FPGutterWidth * FPFw) + FPPaperLeft;
  End;
  Lc := Listing.Count;
  If Listing.FPCLine >= Lc Then Begin
    Listing.FPCLine := Lc -1;
    Listing.FPSelLine := Listing.FPCLine;
    FPCDesLine := Listing.FPCLine;
  End;
  If (Lc = 0) or (Listing.FPCLine >= Lc) or (Listing.FPCPos > Length(Listing[Listing.FPCLine])) Then
    CURSORCHAR := 32
  Else Begin
    s := SyntaxListing[Listing.FPCLine];
    If s <> '' Then Begin
      Idx := 1;
      Cpx := 1;
      While s[Idx] < ' ' Do Begin
        If s[Idx] = #26 Then Begin
          If Ord(s[Idx +1]) <> 8 Then
            T_ITALIC := Ord(s[Idx +1])
        End Else
          If s[Idx] = #27 Then
            If Ord(s[Idx +1]) <> 8 Then
              T_BOLD := Ord(s[Idx +1]);
        Inc(Idx, 5);
      End;
      While Cpx < Listing.FPCPos Do Begin
        If s[Idx] < ' ' Then Begin
          While s[Idx] < ' ' Do Begin
            If s[Idx] = #26 Then Begin
              If Ord(s[Idx +1]) <> 8 Then
                T_ITALIC := Ord(s[Idx +1])
            End Else
              If s[Idx] = #27 Then
                If Ord(s[Idx +1]) <> 8 Then
                  T_BOLD := Ord(s[Idx +1]);
            Inc(Idx, 5);
          End;
        End Else Begin
          Inc(Cpx);
          Inc(Idx);
        End;
      End;
      While s[Idx] < ' ' Do Begin
        If s[Idx] = #26 Then Begin
          If Ord(s[Idx +1]) <> 8 Then
            T_ITALIC := Ord(s[Idx +1])
        End Else
          If s[Idx] = #27 Then
            If Ord(s[Idx +1]) <> 8 Then
              T_BOLD := Ord(s[Idx +1]);
        Inc(Idx, 5);
      End;
      CURSORCHAR := Ord(s[Idx]);
    End Else
      CURSORCHAR := 32;
  End;
  If Lc > 0 Then Begin
    s := Listing[Listing.FPCLine];
    sl := Length(s);
    If (S <> '') And (s[1] in ['0'..'9']) And Not SP_WasPrevSoft(Listing.FPCLine) Then Begin
      LL := 1;
      While (LL <= sl) And (s[LL] in ['0'..'9']) Do
        Inc(LL);
      If Listing.FPCPos < LL Then
        CURSORX := ((FPGutterWidth - (LL-Listing.FPCPos)) * FPFw) + FPPaperLeft + 1
      Else Begin
        CURSORX := OfsX + ((Listing.FPCPos - LL) * FPFw) + 1;
        T_CLIPX1 := FPGutterWidth * FPFw;
      End;
    End Else Begin
      CURSORX := OfsX + ((Listing.FPCPos -1) * FPFw) + 1;
      Inc(CURSORX, Listing.Flags[Listing.FPCLine].Indent * FPFw);
      T_CLIPX1 := FPGutterWidth * FPFw;
    End;
  End Else Begin
    CURSORX := OfsX + ((Listing.FPCPos - (Cpx +1)) * FPFw) + 1;
    Inc(CURSORX, Listing.Flags[Listing.FPCLine].Indent * FPFw);
  End;
End;

Procedure SP_CursorPosChanged;
Begin
  If (FPBracket1Pos > 0) or (FPBracket2Pos > 0) Then Begin
    FPBracket1Pos := -1;
    FPBracket2Pos := -1;
    SP_FPApplyHighlighting(FPBracket1Line);
    AddDirtyLine(FPBracket1Line);
    If FPBracket1Line <> FPBracket2Line Then Begin
      SP_FPApplyHighlighting(FPBracket2Line);
      AddDirtyLine(FPBracket2Line);
    End;
  End;
  If (FocusedWindow = fwEditor) Then Begin
    If Pos(aChar(CursorChar), '()[]{}') > 0 Then Begin
      SP_SetBracketPositions(aChar(CursorChar), Listing.FPCLine, Listing.FPCPos);
      SP_FPApplyHighlighting(FPBracket1Line);
      AddDirtyLine(FPBracket1Line);
      If FPBracket1Line <> FPBracket2Line Then Begin
        SP_FPApplyHighlighting(FPBracket2Line);
        AddDirtyLine(FPBracket2Line);
      End;
    End;
  End;
End;

Procedure SP_DrawGraphicsID;
Var
  WindowID, Font, Mode, Fg, Bg: Integer;
  Ch: aString;
  Err: TSP_ErrorCode;
  sz: aFloat;
Begin

  // Draws the G,L,C cursor. Assumes that the current window is the Direct command window.

  WindowID := SCREENBANK;
  Font := FONTBANKID;

  SP_SetSystemFont(EDITORFONT, Err);
  SP_SetDrawingWindow(DWWindowID);

  Mode := GFXLOCK;
  If (KEYSTATE[K_CONTROL] + KEYSTATE[K_ALT] = 2) or (KEYSTATE[K_ALTGR] = 1) Then Mode := 1-Mode;
  If Mode = 1 Then Begin
    Ch := 'G';
    Fg := 15;
    Bg := 0;
  End Else Begin
    If EDITERROR Then Begin
      If CURSORBG <> 4 Then Begin
        Ch := 'E';
        Fg := 15;
        Bg := 2;
      End Else Begin
        Fg := 4;
        Bg := 0;
        Ch := 'R';
      End;
    End Else Begin
      Fg := 15;
      Bg := 0;
      If CAPSLOCK > 0 Then
        Ch := 'C'
      Else
        If FocusedWindow = fwEditor Then
          Ch := 'L'
        Else
          If EDITLINE = '' Then
            Ch := 'K'
          Else
            Ch := 'L';
    End;
  End;

  sz := Max(EDFONTSCALEX, EDFONTSCALEY);
  SP_TEXTOUT(-1, DWPaperLeft, DWPaperTop, #25 + aFloatToString(sz) + aFloatToString(sz) + Ch, Fg, Bg, True);

  SP_SetSystemFont(Font, Err);
  SP_SetDrawingWindow(WindowID);

End;

Procedure SP_DisplayFPCursor;
Var
  Idx, Cpx, OfsX, OfsY, Fg, Bg, Lc, LL, It, Bl, Font: Integer;
  Err: TSP_ErrorCode;
  s: aString;
Begin

  Font := SP_SetFPEditorFont;

  If SCREENBANK <> FPWindowID Then
    SP_SetDrawingWindow(FPWIndowID);

  SP_SetEditorClipping;

  If FLASHSTATE = 0 Then Begin
    Fg := CURSORFG;
    Bg := CURSORBG;
  End Else Begin
    Fg := CURSORBG;
    Bg := CURSORFG;
  End;
  It := T_ITALIC;
  Bl := T_BOLD;

  SP_CalculateFPCursorPos;

  SP_TEXTOUT(-1, CURSORX, CURSORY, EdSc + aChar(Max(CURSORCHAR, 32)), Fg, Bg, True);

  SP_ClearEditorClipping;
  SP_SetSystemFont(Font, Err);
  T_BOLD := Bl;
  T_ITALIC := It;

  SP_DrawGraphicsID;
  SP_SetDirtyRect(CURSORX + FPWindowLeft, CURSORY + FPWIndowTop, CURSORX + (FPFw * 2) + FPWindowLeft, CURSORY + FPFh + FPWindowTop);
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_DisplayDWCursor;
Var
  Fg, Bg: Byte;
  PosX, PosY: aFloat;
  WindowId, Font, Over, Cp: Integer;
  Err: TSP_ErrorCode;
Begin

  Over := T_OVER;
  T_OVER := 0;

  CURSORPOS := Max(CURSORPOS, 1);

  Cp := CURSORPOS -1;
  CURSORX := DWTextLeft + ((Cp Mod DWTextWidth) * FPFw);
  CURSORY := DWPaperTop + ((Cp Div DWTextWidth) * FPFh);
  If (CURSORPOS <= Length(EDITLINE)) And (EDITLINE <> '') Then
    CURSORCHAR := Ord(EDITLINE[CURSORPOS])
  Else
    CURSORCHAR := 32;
  If FlashState = 1 Then Begin
    Fg := CURSORFG; Bg := CURSORBG;
  End Else Begin
    Fg := CURSORBG; Bg := CURSORFG;
  End;

  PosX := PRPOSX; PosY := PRPOSY;

  WindowID := SCREENBANK;
  Font := FONTBANKID;

  SP_SetSystemFont(EDITORFONT, Err);
  SP_SetDrawingWindow(DWWindowID);

  SP_DrawGraphicsID;
  SP_TEXTOUT(-1, CURSORX, CURSORY, EdSc + aChar(CURSORCHAR), Fg, Bg, True);

  SP_SetSystemFont(Font, Err);

  PRPOSX := PosX;
  PRPOSY := PosY;

  T_OVER := Over;

  SP_SetDirtyRect(CURSORX + DWWindowLeft, CURSORY + DWWIndowTop, CURSORX + FPFw + DWWindowLeft, CURSORY + FPFh + DWWindowTop);
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_SetCursorColours;
Var
  Sel: SP_SelectionInfo;
Begin
  CURSORFG := 15;
  CURSORBG := 9;
  If IsSelActive Then Begin
    If FocusedWindow = fwEditor Then Begin
      SP_GetSelectionInfo(Sel);
      If Sel.Dir = 1 Then Begin
        CURSORFG := 13;
        CURSORBG := 0;
      End;
    End Else
      If DWSelP > CURSORPOS Then Begin
        CURSORFG := 13;
        CURSORBG := 9;
      End;
  End;
End;

Procedure SP_SetGraphicsMode;
Var
  Mode: Integer;
Begin

  Mode := GFXLOCK;
  If (KEYSTATE[K_CONTROL] + KEYSTATE[K_ALT] = 2) or (KEYSTATE[K_ALTGR] = 1) Then Mode := 1-Mode;
  If Not EDITERROR Then
    If Mode = 1 Then Begin
      CURSORFG := 0;
      CURSORBG := 6;
    End Else
      SP_SetCursorColours;

End;

Procedure SP_FPWaitForUserEvent(Var keyChar: Byte; Var LocalFlashState: Integer);
Begin

  Repeat
    SP_WaitForSync;
    ProcessNextControlMsg;
    If SP_KeyEventWaiting Then
      SP_UnBufferKey;
    DoTimerEvents;
    If LocalFlashState <> FLASHSTATE Then Begin
      If FocusedWindow = fwEditor Then
        SP_DisplayFPCursor
      Else
        SP_DisplayDWCursor;
      SP_DrawBatteryStatus;
      LocalFlashState := FLASHSTATE;
    End;
    If LASTKEY = 0 Then KeyChar := 0;
    If QUITMSG Then Exit;
    SP_CheckEvents;
    SP_SetGraphicsMode;
    If K_UPFLAG Then Begin
      SP_DrawGraphicsID;
      K_UPFLAG := False;
    End;
    If MaxDirtyLines >= 0 Then RefreshDirtyLines;
  Until M_DOWNFLAG or M_UPFLAG or M_MOVEFLAG or M_WHEELUPFLAG or M_WHEELDNFLAG or (KEYSTATE[LASTKEY] <> 0);

End;

Procedure SP_GetFPUserInput;
Var
  Finished, Changed: Boolean;
  KeyChar: Byte;
  RepeatLen: LongWord;
  LocalFlashState: Integer;
Begin

  SYSTEMSTATE := SS_EDITOR;
  Finished := False;
  Changed := True;
  KeyChar := 0;
  RepeatLen := REPDEL;
  LocalFlashState := FLASHSTATE;

  While Not (Finished or QUITMSG) Do Begin

    If EDITERROR Then Begin
      If not (CURSORBG in [4, 6]) Then Begin
        CURSORBG := 10;
        CURSORFG := 15;
      End;
      CURSORPOS := Max(1, EDITERRORPOS);
      DWSelP := CURSORPOS;
    End;

    // Wait for a key - alphanumeric, of course. Shift doesn't count.
    // Also handle mouse events

    SP_FPWaitForUserEvent(KeyChar, LocalFlashState);

    If LastKey <> 0 Then Begin

      // Is this key the same as the last one?

      If KeyChar = LASTKEY Then Begin

        // Yes - make it repeat if necessary.

        If Not (LASTKEY in [16, 17, 18]) Then // Not the modifiers
          If FRAMES - REPCOUNT >= RepeatLen Then Begin
            RepeatLen := REPPER;
            REPCOUNT := FRAMES;
            If FocusedWindow = fwEditor Then
              SP_FPEditorPerformEdit(LASTKEY)
            Else
              SP_DWPerformEdit(LASTKEY);
            Changed := True;
          End;

      End Else Begin

        // No - This is a new key

        If FocusedWindow = fwEditor Then
          SP_FPEditorPerformEdit(LASTKEY)
        Else
          SP_DWPerformEdit(LASTKEY);
        RepeatLen := REPDEL;
        REPCOUNT := FRAMES;
        KeyChar := LASTKEY;
        Changed := True;

      End;

    End;

    If M_DOWNFLAG Then SP_FPEditorHandleMouseDown(MOUSEX, MOUSEY);
    If M_UPFLAG Then SP_FPEditorHandleMouseUp(MOUSEX, MOUSEY);
    If M_MOVEFLAG Then SP_FPEditorHandleMouseMove(MOUSEX, MOUSEY);
    If M_WHEELUPFLAG Then SP_FPEditorHandleMouseWheel(True, MOUSEX, MOUSEY);
    If M_WHEELDNFLAG Then SP_FPEditorHandleMouseWheel(False, MOUSEX, MOUSEY);

    M_DOWNFLAG := False;
    M_UPFLAG := False;
    M_MOVEFLAG := False;
    M_WHEELUPFLAG := False;
    M_WHEELDNFLAG := False;

  End;

End;

Procedure SP_FPEditorHandleMouseUp(X, Y: Integer);
Var
  Idx: Integer;
Begin

  M_DOWNFLAG := False;
  M_UPFLAG := False;
  FPCDragging := False;
  DWCDragging := False;

  Idx := 0;
  While Idx < Length(Events) Do
    If Events[Idx].evType in [evtMouseDown, evtMouseUp] Then
      SP_DeleteEvent(Events[Idx].ID)
    Else
      Inc(Idx);

  For Idx := 0 To Length(FPScrollBars) -1 Do
    If FPScrollBars[Idx].ThumbGrabbed Then
      FPScrollBars[Idx].ThumbGrabbed := False;
  FPScrolling := False;

End;

Function SP_FPCharAtPos(X, Y: Integer): TPoint;
Var
  Idx, Cpx, OfsX, OfsY: Integer;
  VertSB, HorzSB: pSP_ScrollBar;
  s: aString;
Begin

  // Gets the Line (result.x) and character position (result.y) of a given coordinate in the editor window.

  VertSB := @FPScrollBars[SP_FindScrollBar(FPVertSc)];
  If X >= VertSB^.BoundsRect.Left Then Begin
    Result.Y := -1;
    Exit;
  End Else Begin
    Idx := Trunc(VertSB^.Position/FPFh);
    OfsY := -(Trunc(VertSB^.Position) Mod FPFh) + FPPaperTop;
  End;

  If Not EDITORWRAP Then Begin
    HorzSB := @FPScrollBars[SP_FindScrollBar(FPHorzSc)];
    Cpx := Trunc(HorzSB^.Position/FPFw);
    OfsX := -Trunc(HorzSB^.Position) + (FPGutterWidth * FPFw) + FPPaperLeft;
  End Else Begin
    Cpx := 0;
    OfsX := (FPGutterWidth * FPFw) + FPPaperLeft;
  End;
  Inc(OfsX);

  Dec(Y, OfsY);
  Result.Y := (Y Div FPFh) + Idx;

  If (Result.Y >= 0) And (Result.Y < Listing.Count) Then Begin
    s := Listing[Result.Y];
    Idx := 1;
    While (Idx < Length(s)) And (s[Idx] in ['0'..'9']) And Not SP_WasPrevSoft(Result.Y) Do
      Inc(Idx);
    If X < FPGutterWidth * FPFw Then Begin
      If Idx = 1 Then
        Result.X := 1
      Else
        Result.X := Max(1, (Idx - 1) - ((((FPGutterWidth * FPFw) + FPPaperLeft) - X) Div FPFw));
    End Else Begin
      If Idx = 1 Then
        Result.X := ((X - OfsX) Div FPFw) +1
      Else
        Result.X := Idx + ((X - OfsX) Div FPFw);
      Dec(Result.X, Listing.Flags[Result.Y].Indent);
    End;

    Result.X := Max(1, Min(Length(s) +1, Result.X));
    Result.Y := Max(0, Min(Listing.Count -1, Result.Y));

  End Else
    Result := Point(Length(Listing[Listing.Count -1])+1, Listing.Count -1);

End;

Procedure SP_FPEditorHandleMouseDown(X, Y: Integer);
Var
  CharPos: TPoint;
  Idx, wIdx, OldLine: Integer;
  Window: pSP_Window_Info;
  Event: SP_EditorEvent;
  Sel: SP_SelectionInfo;
  Focus: Integer;
  IsDouble: Boolean;
Begin

  M_DOWNFLAG := False;
  SP_GetSelectionInfo(Sel);

  If (CB_GETTICKS - FPClickTime < 250) and (Abs(FPClickX - X) < 4) and (Abs(FPClickY - Y) < 4) Then Begin
    IsDouble := True;
    FPClickTime := 0;
  End Else Begin
    FPClickX := X;
    FPClickY := Y;
    FPClickTime := CB_GETTICKS;
    IsDouble := False;
  End;

  // Which window is the mouse pointer in? Windows are stored in back to front order, so work backwards.

  Idx := NUMBANKS -1;
  While Idx >= 0 Do Begin
    Window := @SP_BANKLIST[Idx]^.Info[0];
    If SP_BankList[Idx]^.DataType = SP_WINDOW_BANK Then
    With Window^ Do
      If PtInRect(Rect(Left, Top, Left + Width, Top + Height), Point(X, Y)) And Visible Then Begin
        Dec(X, Left);
        Dec(Y, Top);
        Break;
      End;
    Dec(Idx);
  End;

  If Idx >= 0 Then Begin

    // Run through all our scrollbars for that window.

    For Idx := 0 To Length(FPScrollBars) -1 Do Begin

      If FPScrollBars[Idx].WindowIdx = Window^.ID Then
        If PtInRect(FPScrollBars[Idx].BoundsRect, Point(X, Y)) Then Begin
          Event.evType := evtMouseDown;
          Event.Data.X := X;
          Event.Data.Y := Y;
          Event.Data.Button := evtLeftButton;
          Event.Data.ObjectPtr := @FPScrollBars[Idx];
          Event.OnLaunch := SP_FPScrollBarMouseDown;
          Event.Delay1 := REPDEL;
          Event.Delay2 := REPPER;
          Event.OneShot := True;
          SP_LaunchEvent(@Event);
          Exit;
        End;

    End;

    // Not in a Scroll bar. Now handle the windows on a case-by-case basis - check their ID for the editor,
    // Direct command window, debugger etc.

    If Window^.ID = FPWindowID Then Begin

      // We clicked in the editor. If we're in the text area, then move the cursor.

      OldLine := Listing.FPCLine;
      CharPos := SP_FPCharAtPos(X, Y);
      If CharPos.Y >= 0 Then Begin
        Listing.FPCLine := CharPos.Y;
        Listing.FPCPos := CharPos.X;
        FPCDes := Listing.FPCPos;
        FPCDesLine := Listing.FPCLine;
        If KEYSTATE[K_SHIFT] = 0 Then SP_FPClearSelection(Sel);
        If IsDouble Then SP_SelectWord;
        FPCDragging := True;
        FPMDFramesTarget := FRAMES + 10;
        SP_CalculateFPCursorPos;
        SP_CursorPosChanged;
        SP_RefreshCursorLineAfterChange(OldLine);
        SP_PlaySystem(CLICKCHAN, CLICKBANK);
      End;

    End Else

      If Window^.ID = DWWindowID Then Begin

        // Clicked in the Direct command window.

        If PtInRect(Rect(DWPaperLeft, DWPaperTop, DWPaperLeft + DWPaperWidth -1, DWPaperTop + DWPaperHeight -1), Point(X, Y)) Then Begin

          CURSORPOS := Min(Length(EDITLINE) +1, ((X - DWTextLeft) Div FPFw) + 1 + (((Y - DWPaperTop) Div FPFh) * DWTextWidth));
          If KEYSTATE[K_SHIFT] = 0 Then
            DWSelP := CURSORPOS;
          DWCDragging := True;
          If IsDouble Then SP_SelectWord;
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          SP_EditorDisplayEditLine;
          SP_DisplayDWCursor;

        End;

      End;

    Focus := SP_GetWindowFromID(Window^.ID);
    If (Focus >= 0) And (Focus <> FocusedWindow) Then
      SP_SwitchFocus(Focus);

  End;

End;

Procedure SP_FPEditorHandleMouseMove(X, Y: Integer);
Var
  Idx, wIdx, Delta: Integer;
  CharPos: TPoint;
  Mult: aFloat;
  NewPosition: Integer;
  Window: pSP_Window_Info;
Begin

  M_MOVEFLAG := False;
  If (MOUSEBTN = 0) And (FPCDragging or DWCDragging or FPScrolling) Then Begin
    SP_FPEditorHandleMouseUp(MOUSEX, MOUSEY);
    Exit;
  End;

  // This really only needs to be responded to for scrollbar purposes, and for selections in the editor.

  // Any scrollbars with a thumb grabbed?

  For Idx := 0 To Length(FPScrollBars) -1 Do With FPScrollBars[Idx] Do
    If ThumbGrabbed Then Begin
      If Kind = scVertical Then Begin
        Delta := Y - ThumbGrabPos.Y;
        NewPosition := GrabPosition + Trunc(Delta/(PageSize/TotalSize));
      End Else Begin
        Delta := X - ThumbGrabPos.X;
        NewPosition := GrabPosition + Trunc(Delta/(PageSize/TotalSize));
      End;
      If NewPosition + PageSize > TotalSize Then
        NewPosition := TotalSize - PageSize
      Else
        If NewPosition < 0 Then
          NewPosition := 0;
      SmoothMove := True;
      TargetPos := NewPosition;
      SP_UpdateScrollBar(ID, -1, -1, NewPosition);
      SP_DisplayFPListing(-1);
      Exit;
    End;

  // Nope, so check if we're in a window that can respond to a mouse move.
  // We can shortcut this check if we're already mousedown in an editor window.

  Idx := 1;
  Window := Nil;
  If FPCDragging Then Begin
    wIdx := FPWindowID;
    Dec(X, FPWindowLeft);
    Dec(Y, FPWindowTop);
  End Else
    If DWCDragging Then Begin
      wIdx := DWWindowID;
      Dec(X, DWWindowLeft);
      Dec(Y, DWWindowTop);
    End Else Begin
      Idx := NUMBANKS -1;
      While Idx >= 0 Do Begin
        If SP_BankList[Idx]^.DataType = SP_WINDOW_BANK Then Begin
          Window := @SP_BankList[Idx]^.Info[0];
          With Window^ Do
            If PtInRect(Rect(Left, Top, Left + Width, Top + Height), Point(X, Y)) Then Begin
              Dec(X, Left);
              Dec(Y, Top);
              Break;
            End;
        End;
        Dec(Idx);
      End;
    End;

  If Assigned(Window) Then
    wIdx := Window^.ID;

  If Idx >= 0 Then

    If wIdx = FPWindowID Then Begin

      // We're inside the editor. Get the position of the mouse in cursor coordinates.

      If FPCDragging Then Begin

        CharPos := SP_FPCharAtPos(X, Y);
        If CharPos.Y >= 0 Then Begin

          // Move the cursor, and extend the selection.

          Listing.FPCLine := CharPos.Y;
          Listing.FPCPos := CharPos.X;
          FPCDes := Listing.FPCPos;
          FPCDesLine := Listing.FPCLine;
          SP_CalculateFPCursorPos;
          SP_CursorPosChanged;
          SP_DisplayFPListing(-1);
          SP_ScrollInView;

        End;

      End;

    End Else

      If wIdx = DWWindowID Then Begin

        // Inside the Direct command window. As above, get the new cursorpos and extend the selection accordingly.

        If DWCDragging Then Begin

          CURSORPOS := Max(0, Min(Length(EDITLINE) +1, ((X - DWTextLeft) Div FPFw) + 1 + (((Y - DWPaperTop) Div FPFh) * DWTextWidth)));
          SP_EditorDisplayEditLine;
          SP_DisplayDWCursor;

        End;

      End;

End;

Procedure SP_FPEditorHandleMouseWheel(WheelUp: Boolean; X, Y: Integer);
Var
  c, Idx, wIdx, NewPosition: Integer;
  Window: pSP_Window_Info;
Begin

  Idx := NUMBANKS -1;
  While Idx >= 0 Do Begin
    If SP_BankList[Idx]^.DataType = SP_WINDOW_BANK Then Begin
      Window := @SP_BankList[Idx]^.Info[0];
      With Window^ Do
        If PtInRect(Rect(Left, Top, Left + Width, Top + Height), Point(X, Y)) Then Begin
          Dec(X, Left);
          Dec(Y, Top);
          Break;
        End;
    End;
    Dec(Idx);
  End;

  If Idx >= 0 Then
    For Idx := 0 To Length(FPScrollBars) -1 Do
      With FPScrollBars[Idx] Do
        If WindowIdx = Window^.ID Then Begin
          NewPosition := Trunc(TargetPos);
          If WheelUp Then Begin
            M_WHEELUPFLAG := False;
            If NewPosition = Position Then Begin
              If NewPosition Mod StepSize > 0 Then
                Dec(NewPosition, NewPosition Mod StepSize)
              Else
                Dec(NewPosition, StepSize);
            End Else
              Dec(NewPosition, StepSize + (NewPosition Mod StepSize));
            Dec(NewPosition, StepSize * 2);
          End Else Begin
            M_WHEELDNFLAG := False;
            If NewPosition = Position Then Begin
              c := (NewPosition + PageSize) Mod StepSize;
              If c > 0 Then
                Inc(NewPosition, StepSize - c)
              Else
                Inc(NewPosition, StepSize);
            End Else
              Inc(NewPosition, StepSize + (StepSize - (NewPosition Mod StepSize)));
            Inc(NewPosition, StepSize * 2);
          End;
          If NewPosition + PageSize > Min(TotalSize, Listing.Count * FPFh) Then
            NewPosition := Min(TotalSize, Listing.Count * FPFh) - PageSize;
          If NewPosition < 0 Then
            NewPosition := 0;
          TargetPos := NewPosition;
          SmoothMove := True;
          LaunchScrollEvent;
          Exit;
        End;

End;

Procedure SP_FPScrollBarMouseDown(Event: pSP_EditorEvent);
Var
  Pt: TPoint;
  NewPosition, c: Integer;
  evt, repEvent: SP_EditorEvent;
  Data: SP_EventData;
  CanRepeat: Boolean;
  Window: pSP_Window_Info;
  Error: TSP_ErrorCode;
Begin

  // Mouse went down in a scrollbar. Check which part it went down in and
  // perform accordingly.

  evt := SP_EditorEvent(Event^);
  repEvent.evType := evtMouseDown;
  repEvent.Data.X := evt.Data.X;
  repEvent.Data.Y := evt.Data.Y;
  repEvent.Data.ObjectPtr := evt.Data.ObjectPtr;
  repEvent.OnLaunch := SP_FPScrollBarMouseDown;
  repEvent.TargetFrame := FRAMES + evt.Delay1;
  repEvent.Delay1 := REPPER;
  repEvent.Delay2 := REPPER;
  repEvent.OneShot := False;
  repEvent.Tag := 1;

  CanRepeat := False;

  With pSP_ScrollBar(evt.Data.ObjectPtr)^ Do Begin
    SmoothMove := True;
    Pt := Point(evt.Data.X, evt.Data.Y);
    ThumbGrabbed := False;
    FPScrolling := False;
    NewPosition := Trunc(TargetPos);
    If PtInRect(UpRect, Pt) Then Begin
      // One line up
      If NewPosition Mod StepSize > 0 Then
        Dec(NewPosition, NewPosition Mod StepSize)
      Else
        Dec(NewPosition, StepSize);
      CanRepeat := True;
    End Else
      If PtInRect(DownRect, Pt) Then Begin
        // One line down
        c := (NewPosition + PageSize) Mod StepSize;
        If c > 0 Then
          Inc(NewPosition, StepSize - c)
        Else
          Inc(NewPosition, StepSize);
        CanRepeat := True;
      End Else
        If ThumbEnabled Then
          If PtInRect(ThumbRect, Pt) Then Begin
            // Grab and hold thumb ready for dragging
            ThumbGrabbed := True;
            FPScrolling := True;
            SP_GetWindowDetails(WindowIdx, Window, Error);
            ThumbGrabPos.X := Pt.X + Window^.Left;
            ThumbGrabPos.Y := Pt.Y + Window^.Top;
            GrabPosition := Trunc(Position);
          End Else
            If PtInRect(TrackRect, Pt) Then Begin
              // Clicked above or below thumb
              Case Kind of
                scVertical:
                  Begin
                    If evt.Data.Y < ThumbRect.Top Then
                      // Page up
                      Dec(NewPosition, PageSize - StepSize)
                    Else
                      // Page down
                      Inc(NewPosition, PageSize - StepSize);
                  End;
                scHorizontal:
                  Begin
                    If evt.Data.X < ThumbRect.Left Then
                      // Page up
                      Dec(NewPosition, PageSize - StepSize)
                    Else
                      // Page down
                      Inc(NewPosition, PageSize - StepSize);
                  End;
              End;
              CanRepeat := True;
            End Else
              Exit;
    // Fall through and cause the scrollbar to update itself.
    If NewPosition + PageSize > TotalSize Then
      NewPosition := TotalSize - PageSize
    Else
      If NewPosition < 0 Then
        NewPosition := 0;

    TargetPos := NewPosition;
    LaunchScrollEvent;

  End;

  If CanRepeat Then
    SP_AddEvent(repEvent);

End;

Procedure SP_FPVertScrollBarChange(Var Data: SP_EventData);
Begin

  // Editor vertical scrollbar changed position.
  If FPCDragging And (FRAMES >= FPMDFramesTarget) Then
    SP_FPEditorHandleMouseMove(MOUSEX, MOUSEY);

End;

Procedure SP_FPHorzScrollBarChange(Var Data: SP_EventData);
Begin

  // Editor horizontal scrollbar changed position.
  If FPCDragging And (FRAMES >= FPMDFramesTarget) Then
    SP_FPEditorHandleMouseMove(MOUSEX, MOUSEY);

End;

Procedure SP_AddEvent(Var Event: SP_EditorEvent);
Var
  Cnt, NewID, Idx: Integer;
  Done, Found: Boolean;
Begin

  Case Event.evType of
    evtMouseDown, evtMouseUp, evtMouseMove:
      Begin
        Idx := 0;
        While Idx < Length(Events) Do
          If Events[Idx].evType = Event.evType Then
            SP_DeleteEvent(Events[Idx].ID)
          Else
            Inc(Idx);
      End;
  End;

  Cnt := Length(Events);
  SetLength(Events, Cnt +1);
  CopyMem(@Events[Cnt].ID, @Event.ID, SizeOf(SP_EditorEvent));
  NewID := 0;
  Done := Length(SP_BankList) = 0;
  While Not Done Do Begin
    Found := False;
    For Idx := 0 To Length(Events) -1 Do Begin
      If Events[Idx].ID = NewID Then Begin
        Inc(NewID);
        Found := True;
        Break;
      End;
    End;
    If Not Found Then
      Done := True;
  End;
  Events[Cnt].ID := NewID;

End;

Function  SP_FindEvent(ID: Integer): Integer;
Begin
  Result := Length(Events) -1;
  While Result >= 0 Do
    If Events[Result].ID = ID Then Exit Else Dec(Result);
End;

Procedure SP_DeleteEvent(ID: Integer);
Begin
  ID := SP_FindEvent(ID);
  While ID < Length(Events) -1 Do Begin
    CopyMem(@Events[ID].ID, @Events[ID+1].ID, SizeOf(SP_EditorEvent));
    Inc(ID);
  End;
  If ID >= 0 Then
    SetLength(Events, ID);
End;

Procedure SP_DeleteEventByIndex(Idx: Integer);
Begin
  If Idx >= 0 Then Begin
    While Idx < Length(Events) -1 Do Begin
      CopyMem(@Events[Idx].ID, @Events[Idx+1].ID, SizeOf(SP_EditorEvent));
      Inc(Idx);
    End;
    SetLength(Events, Length(Events) -1);
  End;
End;

Procedure SP_DeleteAllEvents(eventType: Integer);
Var
  Idx: Integer;
Begin
  Idx := 0;
  While Idx < Length(Events) Do Begin
    If Events[Idx].evType = eventType Then
      SP_DeleteEventByIndex(Idx)
    Else
      Inc(Idx);
  End;
End;

Procedure SP_LaunchEvent(Event: pSP_EditorEvent);
Begin

  SP_EditorEvent(Event^).OnLaunch(Event);

End;

Procedure SP_CheckEvents;
Var
  Idx: Integer;
Begin

  Idx := 0;
  If Length(Events) > 0 Then Begin
    While Idx < Length(Events) Do
      With Events[Idx] Do Begin
        Case evType of
          evtRefreshLine:
            SP_DisplayFPListing(Tag);
        Else
          If FRAMES >= TargetFrame Then
            If Assigned(Events[Idx].OnLaunch) Then
              SP_LaunchEvent(@Events[Idx]);
        End;
        If OneShot Then
          SP_DeleteEventByIndex(Idx)
        Else
          Inc(Idx);
      End;
  End;

End;

Procedure SP_FPClearSelection(Var Sel: SP_SelectionInfo);
Var
  Idx, St, Ed: Integer;
Begin

  St := Sel.StartL;
  Ed := Sel.EndL;
  If Sel.Active Then
    For Idx := St to Ed Do
      AddDirtyLine(Idx);
  Listing.FPSelLine := Listing.FPCLine;
  Listing.FPSelPos := Listing.FPCPos;

End;

Procedure SP_FPDeleteSelection(Var Sel: SP_SelectionInfo);
Var
  Idx,SelS, SelE, Flag: Integer;
  CodeLine: aString;
Begin

  Case FocusedWindow of
    fwEditor:
      Begin
        SP_GetSelectionInfo(Sel);
        If Sel.Active Then Begin

          If Sel.StartL = Sel.EndL Then Begin

            CodeLine := Listing[Sel.StartL];
            If Sel.Dir = 1 Then
              CodeLine := Copy(CodeLine, 1, Sel.StartP -1) + Copy(CodeLine, Sel.EndP +1)
            Else
              CodeLine := Copy(CodeLine, 1, Sel.StartP -1) + Copy(CodeLine, Sel.EndP);
            Listing[Sel.StartL] := CodeLine;
            SP_FPWordWrapLine(Sel.StartL);
            SP_MarkAsDirty(Sel.StartL);
            SP_FPApplyHighlighting(Sel.StartL);

          End Else Begin

            Flag := Listing.Flags[Sel.EndL].ReturnType;
            If Sel.Dir = 1 Then
              Listing[Sel.StartL] := Copy(Listing[Sel.StartL], 1, Sel.StartP -1) + Copy(Listing[Sel.EndL], Sel.EndP +1)
            Else
              Listing[Sel.StartL] := Copy(Listing[Sel.StartL], 1, Sel.StartP -1) + Copy(Listing[Sel.EndL], Sel.EndP);
            SP_FPApplyHighlighting(Sel.StartL);

            Idx := Sel.StartL +1;
            While Sel.EndL >= Idx Do Begin
              SP_DeleteLine(Idx);
              Dec(Sel.EndL);
            End;
            Listing.Flags[Sel.StartL].ReturnType := Flag;
            SP_FPWordWrapLine(Sel.StartL);
            SP_MarkAsDirty(Sel.StartL);

          End;

          Listing.FPCLine := Sel.StartL;
          Listing.FPCPos := Sel.StartP;
          SP_CursorPosChanged;

        End;

        SP_FPClearSelection(Sel);
        If Not SP_ScrollInView Then SP_DisplayFPListing(-1);
      End;
    fwDirect:
      Begin
        If DWSelP <> CURSORPOS Then Begin
          SelS := Min(DWSelP, CURSORPOS);
          SelE := Max(DWSelP, CURSORPOS);
          DWStoreEditorState;
          EDITLINE := Copy(EDITLINE, 1, SelS -1) + Copy(EDITLINE, SelE);
          CURSORPOS := SelS;
          DWSelP := CURSORPOS;
          SP_EditorDisplayEditLine;
        End;
      End;
  End;
End;

Function  IsSelActive: Boolean;
Begin
  If FocusedWindow = fwEditor Then
    Result := (Listing.FPCLine <> Listing.FPSelLine) or (Listing.FPCPos <> Listing.FPSelPos)
  Else
    Result := DWSelP <> CURSORPOS;
End;

Procedure SP_CopySelection;
Var
  Idx, SelS, SelE: Integer;
  s: aString;
  Sel: SP_SelectionInfo;
Begin

  Case FocusedWindow of
    fwEditor:
      Begin
        SP_GetSelectionInfo(Sel);
        If Sel.Active Then
          If Sel.Multiline Then Begin
            If Listing.Flags[Sel.StartL].ReturnType = spHardReturn Then
              s := Copy(Listing[Sel.StartL], Sel.StartP) + #13#10
            Else
              s := Copy(Listing[Sel.StartL], Sel.StartP);
            If Sel.EndL > Sel.StartL Then Begin
              Idx := Sel.StartL +1;
              While Idx <> Sel.EndL Do Begin
                If Listing.Flags[Idx].ReturnType = spHardReturn Then
                  s := s + Listing[Idx] + #13#10
                Else
                  s := s + Listing[Idx];
                Inc(Idx);
              End;
            End;
            If Sel.Dir = 1 Then
              s := s + Copy(Listing[Sel.EndL], 1, Sel.EndP)
            Else
              s := s + Copy(Listing[Sel.EndL], 1, Sel.EndP -1);
          End Else
            If Sel.Dir = 1 Then
              s := Copy(Listing[Sel.StartL], Sel.StartP, (Sel.EndP - Sel.StartP) +1)
            Else
              s := Copy(Listing[Sel.StartL], Sel.StartP, (Sel.EndP - Sel.StartP));
      End;
    fwDirect:
      Begin
        If DWSelP <> CURSORPOS Then Begin
          SelS := Min(DWSelP, CURSORPOS);
          SelE := Max(DWSelP, CURSORPOS);
          s := Copy(EDITLINE, SelS, (SelE - SelS));
        End;
      End;
  End;

  Clipboard.AsText := s;

End;

Procedure SP_CutSelection;
Var
  Sel: SP_SelectionInfo;
Begin

  Case FocusedWindow Of
    fwEditor:
      Begin
        SP_GetSelectionInfo(Sel);
        SP_CopySelection;
        SP_FPDeleteSelection(Sel);
        FPCDes := Listing.FPCPos;
        FPCDesLine := Listing.FPCLine;
        SP_FPClearSelection(Sel);
      End;
    fwDirect:
      Begin
        SP_CopySelection;
        SP_FPDeleteSelection(Sel);
      End;
  End;
End;

Procedure SP_PasteSelection;
Var
  Idx, nCPos, SelS, SelE: Integer;
  txt, t: aString;
  Strings: TStringList;
  Sel: SP_SelectionInfo;

  Procedure ProcessTabs(var s: aString);
  Var
    i: Integer;
  Begin
    Repeat
      i := Pos(#9, s);
      if i > 0 then
        s := Copy(s, 1, i -1) + StringOfChar(' ', EDTABSIZE) + Copy(s, i +1);
    Until i = 0;
  End;

Begin

  Case FocusedWindow of
    fwEditor:
      Begin

        SP_GetSelectionInfo(Sel);

        If Sel.Active Then
          SP_FPDeleteSelection(Sel);

        Strings := TStringlist.Create;
        Strings.Text := Clipboard.AsText;

        If Strings.Count > 0 Then Begin
          nCPos := Length(Strings[Strings.Count -1]);
          If Strings.Count = 1 Then Begin
            txt := Listing[Listing.FPCLine];
            t := Strings[0];
            ProcessTabs(t);
            txt := Copy(txt, 1, Listing.FPCPos -1) + t + Copy(Txt, Listing.FPCPos);
            Listing[Listing.FPCLine] := txt;
            Listing.FPCPos := Listing.FPCPos + nCPos;
            SP_FPWordWrapLine(Listing.FPCLine);
            If not EDITORWRAP Then Begin
              SP_MarkAsDirty(Listing.FPCLine);
              SP_FPApplyHighlighting(Listing.FPCLine);
            End;
          End Else Begin
            CompilerLock.Enter;
            txt := Listing[Listing.FPCLine];
            Strings[Strings.Count -1] := Strings[Strings.Count -1] + Copy(txt, Listing.FPCPos);
            t := Strings[0];
            ProcessTabs(t);
            txt := Copy(txt, 1, Listing.FPCPos -1) + t;
            Listing[Listing.FPCLine] := txt;
            For Idx := Strings.Count -1 DownTo 1 Do Begin
              t := Strings[Idx];
              ProcessTabs(t);
              SP_InsertLine(Listing.FPCLine +1, t, '', '');
              Listing.Flags[Listing.FPCLine +1].ReturnType := spHardReturn;
            End;
            For Idx := Listing.FPCLine To Listing.FPCLine + Strings.Count -1 Do Begin
              SP_FPWordWrapLine(Idx);
              If Not EDITORWRAP Then Begin
                SP_MarkAsDirty(Idx);
                SP_FPApplyHighlighting(Idx);
              End;
            End;
            Inc(Listing.FPCLine, Strings.Count);
            Listing.FPCPos := nCPos +1;
            CompilerLock.Leave;
          End;
          SP_FPClearSelection(Sel);
        End;
        SP_CursorPosChanged;
        If Not SP_ScrollInView Then SP_DisplayFPListing(-1);
        Strings.Free;
      End;
    fwDirect:
      Begin
        If DWSelP <> CURSORPOS Then Begin
          SelS := Min(DWSelP, CURSORPOS);
          SelE := Max(DWSelP, CURSORPOS);
          SP_FPDeleteSelection(Sel);
        End;
        Strings := TAnsiStringlist.Create;
        Strings.Text := Clipboard.AsText;
        If Strings.Count > 0 Then Begin
          t := Strings[0];
          ProcessTabs(t);
          DWStoreEditorState;
          EditLine := Copy(EDITLINE, 1, CURSORPOS -1) + t + Copy(EDITLINE, CURSORPOS);
          Inc(CURSORPOS, Length(Strings[0]));
          DWSelP := CURSORPOS;
        End;
        Strings.Free;
      End;
  End;

End;

Procedure SP_SelectAll;
Begin

  Case FocusedWindow of
    fwEditor:
      Begin
        Listing.FPSelLine := 0;
        Listing.FPSelPos := 1;
        Listing.FPCLine := Listing.Count -1;
        Listing.FPCPos := Length(Listing[Listing.FPCLine]) +1;
        SP_CursorPosChanged;
        SP_ScrollInView;
        SP_DisplayFPListing(-1);
      End;
    fwDirect:
      Begin
        DWSelP := 1;
        CURSORPOS := Length(EDITLINE) +1;
        SP_EditorDisplayEditLine;
      End;
  End;

End;

Procedure SP_SelectNone;
Var
  Sel: SP_SelectionInfo;
Begin

  Case FocusedWindow of
    fwEditor:
      Begin
        SP_GetSelectionInfo(Sel);
        If Sel.StartL > -1 Then Begin
          Listing.FPCLine := Sel.EndL;
          Listing.FPCPos := Sel.EndP;
          Listing.FPSelLine := Sel.EndL;
          Listing.FPSelPos := Sel.EndP;
          SP_CursorPosChanged;
          SP_ScrollInView;
          SP_DisplayFPListing(-1);
        End;
      End;
    fwDirect:
      Begin
        DWSelP := CURSORPOS;
        SP_EditorDisplayEditLine;
      End;
  End;

End;

Procedure SP_SelectWord;
Var
  Sel: SP_SelectionInfo;
  s: aString;
  t: Integer;
Begin

  Case FocusedWindow Of
    fwEditor:
      Begin
        s := Listing[Listing.FPCLine];
        // Find the start of the word:
        While (Listing.FPCPos > 1) And (s[Listing.FPCPos] in Seps) Do Listing.FPCPos := Listing.FPCPos -1;
        While (Listing.FPCPos > 1) And Not (s[Listing.FPCPos] in Seps) Do Listing.FPCPos := Listing.FPCPos -1;
        If s[Listing.FPCPos] in Seps Then Listing.FPCPos := Listing.FPCPos +1;
        // Find the end of the Word:
        Listing.FPSelLine := Listing.FPCLine;
        Listing.FPSelPos := Listing.FPCPos;
        While (Listing.FPSelPos < Length(s)) And Not (s[Listing.FPSelPos] in Seps) Do Inc(Listing.FPSelPos);
        t := Listing.FPSelPos; Listing.FPSelPos := Listing.FPCPos; Listing.FPCPos := t;
        SP_CursorPosChanged;
        If Not SP_ScrollInView Then SP_DisplayFPListing(-1);
      End;
    fwDirect:
      Begin
        While (CURSORPOS > 1) And (EDITLINE[CURSORPOS] in Seps) Do Dec(CURSORPOS);
        While (CURSORPOS > 1) And Not (EDITLINE[CURSORPOS] in Seps) Do Dec(CURSORPOS);
        If (CURSORPOS < Length(EDITLINE)) and (EDITLINE[CURSORPOS] in Seps) Then Inc(CURSORPOS);
        // Find the end of the Word:
        DWSelP := CURSORPOS;
        While (DWSelP < Length(EDITLINE)) And Not (EDITLINE[DWSelP] in Seps) Do Inc(DWSelP);
        t := DWSelP; DWSelP := CURSORPOS; CURSORPOS := t;
        SP_EditorDisplayEditLine;
      End;
  End;

End;

Procedure SP_DeleteWord(Backwards: Boolean);
Var
  s: aString;
  p1, p2, t: Integer;
Begin

  Case FocusedWindow Of
    fwEditor:
      Begin
        s := Listing[Listing.FPCLine] + ' ';
        p1 := Listing.FPCPos;
      End;
    fwDirect:
      Begin
        s := EDITLINE + ' ';
        p1 := CURSORPOS;
      End;
  End;

  p2 := p1;
  If Backwards Then Begin
    If (p1 > 1) And Not (s[p1] in Seps) And (s[p1 -1] in Seps) Then Dec(p1);
    While (p1 > 1) And Not (Not (s[p1] in Seps) And (s[p1 -1] in Seps)) Do Dec(p1);
    If (p1 = 2) And Not (s[1] in Seps) Then p1 := 1;
  End Else Begin
    If (p1 > 1) And (s[p1 -1] in Seps) And Not (s[p1] in Seps) Then Inc(p1);
    While (p1 < Length(s)) And Not (Not (s[p1] in Seps) And (s[p1 -1] in Seps)) Do Inc(p1);
  End;

  If p1 > p2 Then Begin
    t := p1; p1 := p2; p2 := t;
  End;
  s := Copy(s, 1, Length(s) -1);
  s := Copy(s, 1, p1-1) + Copy(S, p2);

  Case FocusedWindow Of
    fwEditor:
      Begin
        Listing[Listing.FPCLine] := s;
        SP_FPWordWrapLine(Listing.FPCLine);
        Listing.FPCPos := p1;
        SP_CursorPosChanged;
        Listing.FPSelPos := Listing.FPCPos;
      End;
    fwDirect:
      Begin
        DWStoreEditorState;
        EDITLINE := s;
        CURSORPOS := p1;
        DWSelP := CURSORPOS;
      End;
  End;

End;

Function SP_LineNumberSize(Idx: Integer): Integer;
Var
  CodeLine: aString;
Begin

  Result := 0;
  If Idx < Listing.Count Then Begin
    CodeLine := Listing[Idx];
    If CodeLine <> '' Then Begin
      If Not SP_WasPrevSoft(Idx) Then Begin
        Result := 1;
        While (Result <= Length(CodeLine)) And (CodeLine[Result] in ['0'..'9']) Do
          Inc(Result);
      End;
    End;
  End;

End;

Function SP_LineHasNumber_Fast(Idx: Integer): Boolean;
Begin
  Result := False;
  If (Idx < 0) or (Idx >= Listing.Count) Then Exit;
  Result := (Listing[Idx] <> '') and (Listing[Idx][1] in ['0'..'9']) And Not SP_WasPrevSoft(Idx);
End;

Function SP_LineHasNumber(Idx: Integer): Integer;
Var
  CodeLine: aString;
Begin

  Result := 0;
  If (Idx >= 0) And (Idx < Listing.Count) Then Begin
    CodeLine := Listing[Idx];
    If CodeLine <> '' Then Begin
      Result := 1;
      If Not SP_WasPrevSoft(Idx) Then
        While (Result <= Length(CodeLine)) And (CodeLine[Result] in ['0'..'9']) Do
          Inc(Result);
      If Result <= Length(CodeLine) Then Dec(Result);
    End;
  End;

End;

Function SP_GetDesired: Integer;
Var
  Has1, Has2, Id1, Id2: Integer;
Begin

  // Adjusts the "desired cursor x-position" depending on if there's a line number or not.
  // This is called by any routine that changes the cursor's Y position only (Up, Down, PgUp, PgDown).
  // Which allows us to move to the user's *desired* position if the line is long enough, but if not then
  // the desired position is stored away until it can be used.

  Has1 := SP_LineHasNumber(FPCDesLine);
  Has2 := SP_LineHasNumber(Listing.FPCLine);
  Id1 := Listing.Flags[FPCDesLine].Indent;
  Id2 := Listing.Flags[Listing.FPCLine].Indent;

  If Has1 > 0 Then Begin
    If Has2 > 0 Then Begin
      // Both lines have numbers
      If Has1 < Has2 Then
        Result := FPCDes + (Has2 - Has1)
      Else
        Result := FPCDes - (Has2 - Has1);
    End Else
      // Old line has number, new line does not
      Result := FPCDes - Has1;
  End Else
    If Has2 > 0 Then
      // Old Line has no number, new line has number
      Result := FPCDes + Has2
    Else
      // Neither have numbers
      Result := FPCDes;

  // Figure out the right offset for indentation

  If Id1 > 0 Then Begin
    If Id2 > 0 Then Begin
      If Id1 < Id2 Then
        Inc(Result, (Id1 - Id2))
      Else
        Dec(Result, (Id2 - Id1));
    End Else
      Inc(Result, Id1);
  End Else
    If Id2 > 0 Then
      Dec(Result, Id2);

  Result := Max(Min(Result, Length(Listing[Listing.FPCLine]) +1), 1);

End;

Procedure SP_FPCycleEditorWindows(HideMode: Integer);
Var
  t, t3: LongWord;
  DTop, LTop, LHeight, DMove, LMove, LSize, t2: aFloat;
  EditorTargetY, EditorTargetHeight, CmdTargetY: Integer;
  SizeEditor, MoveEditor, MoveCmd: Boolean;
  ListWin, ComWin: pSP_Window_Info;
  Error: TSP_ErrorCode;
Begin

  // Switch between Editor, Editor+Cmd, Cmd and none

  SizeEditor := False;
  MoveEditor := False;
  MoveCmd := False;

  If HideMode = -1 Then Begin

    Case FPWindowMode of
      0: // Command window only - bring in the editor, full size
        Begin
          // Resize the Editor to fill the screen and remove the command window
          SP_SwitchFocus(fwEditor);
          EditorTargetHeight := DISPLAYHEIGHT - (BSize * 2) +1;
          SizeEditor := True;
          MoveEditor := True;
          EditorTargetY := BSize -1;
          CmdTargetY := DISPLAYHEIGHT;
          MoveCmd := True;
          FPWindowMode := 1;
        End;
      1: // Editor only - bring in the command window and resize the Editor
        Begin
          SP_SwitchFocus(fwDirect);
          EditorTargetHeight := DISPLAYHEIGHT - (BSize * 3) - DWWindowHeight;
          CmdTargetY := DISPLAYHEIGHT - BSize - DWWindowHeight;
          MoveCmd := True;
          SizeEditor := True;
          FPWindowMode := 2;
        End;
      2: // Editor + Cmd - Move the editor off-screen
        Begin
          SP_SwitchFocus(fwDirect);
          EditorTargetY := - FPWindowHeight;
          MoveEditor := True;
          FPWindowMode := 0;
        End;
      3: // Command window only - bring in Editor.
        Begin
          SP_SwitchFocus(fwDirect);
          EditorTargetHeight := DISPLAYHEIGHT - (BSize * 3) - DWWindowHeight +1;
          EditorTargetY := BSize -1;
          MoveEditor := True;
          SizeEditor := True;
          FPWindowMode := 2;
        End;
    End;

  End Else Begin

    // A hide/show operation

    If HideMode = 1 Then Begin

      EditorTargetY := -FPWindowHeight;
      CmdTargetY := DISPLAYHEIGHT;
      MoveCmd := True;
      MoveEditor := True;

    End Else Begin

      If FPWindowMode in [1, 2] Then Begin
        If FPWindowMode = 1 Then Begin
          SizeEditor := True;
          EditorTargetHeight := DISPLAYHEIGHT - (BSize * 2) +1;
        End;
        EditorTargetY := FPWindowTop;
        MoveEditor := True;
      End;

      If FPWIndowMode in [0, 2] Then Begin
        CmdTargetY := DWWindowTop;
        MoveCmd := True;
      End;

    End;

  End;

  // Now do the animation.

  SP_GetWindowDetails(FPWindowID, ListWin, Error);
  SP_GetWindowDetails(DWWindowID, ComWin, Error);

  t := CB_GETTICKS;
  DMove := CmdTargetY - ComWin^.Top;
  LMove := EditorTargetY - ListWin.Top;
  LSize := EditorTargetHeight - ListWin^.Height;
  LTop := ListWin^.Top;
  DTop := ComWin^.Top;
  LHeight := ListWin^.Height;

  Repeat
    t3 := CB_GETTICKS;
    t2 := (t3 - t)/ANIMSPEED;
    DisplaySection.Enter;
    If MoveEditor Then Begin
      ListWin^.Top := Trunc(LTop + (LMove * t2));
      If ((LMove > 0) And (ListWin^.Top > EditorTargetY)) or ((LMove < 0) And (ListWin^.Top < EditorTargetY)) Then
        ListWin^.Top := EditorTargetY;
    End;
    If MoveCmd Then Begin
      ComWin^.Top := Trunc(DTop + (DMove * t2));
      If ((DMove > 0) And (ComWin^.Top > CmdTargetY)) or ((DMove < 0) And (ComWin^.Top < CmdTargetY)) Then
        ComWin^.Top := CmdTargetY;
    End;
    If SizeEditor Then Begin
      ListWin^.Height := Trunc(LHeight + (LSize * t2));
      If ((LSize > 0) And (ListWin^.Height > EditorTargetHeight)) or ((LSize < 0) And (ListWin^.Height < EditorTargetHeight)) Then
        ListWin^.Height := EditorTargetHeight;
    End;
    DisplaySection.Leave;
    If SizeEditor Then Begin
      SP_FPResizeWindow(ListWin^.Height);
    End;
    SP_InvalidateWholeDisplay;
    SP_WaitForSync;
  Until (t3 - t) >= ANIMSPEED;

  If SizeEditor Then
    SP_FPResizeWindow(ListWin^.Height)
  Else
    SP_DisplayFPListing(-1);
  SP_InvalidateWholeDisplay;

End;

Procedure AddDirtyLine(Line: Integer);
Var
  i: Integer;
Begin
  If Line = -1 Then
    Line := 0;
  if MaxDirtyLines >= 0 Then Begin
    i := 0;
    While i <= MaxDirtyLines Do Begin
      If DirtyLines[i] = Line Then
        Exit
      Else
        Inc(i);
    End;
  End;
  Inc(MaxDirtyLines);
  If MaxDirtyLines >= Length(DirtyLines) Then
    SetLength(DirtyLines, Length(DirtyLines) + 10);
  DirtyLines[MaxDirtyLines] := Line;
End;

Procedure AddVisibleDirty;
Var
  n, m, Idx: Integer;
Begin
  n := Trunc(FPScrollBars[SP_FindScrollBar(FPVertSc)].Position / FPFh);
  m := n + FPPageHeight Div FPFh;
  For Idx := n To m Do
    AddDirtyLine(Idx);
End;

Procedure RemoveDirtyLine(Line: Integer);
Var
  i, j: Integer;
Begin
  For i := 0 To MaxDirtyLines Do
    If DirtyLines[i] = Line Then Begin
      For j := i To MaxDirtyLines -1 Do
        DirtyLines[j] := DirtyLines[j +1];
      Dec(maxDirtyLines);
    End;
End;

Procedure ClearDirtyLines;
Begin
  MaxDirtyLines := -1;
  SetLength(DirtyLines, 0);
End;

Procedure RefreshDirtyLines;
Var
  i: Integer;
Begin
  While MaxDirtyLines >= 0 Do Begin
    i := DirtyLines[0];
    SP_DisplayFPListing(i);
  End;
End;

Procedure SP_ToggleEditorMark(i: Integer);
Begin
  If EditorMarks[i] And $FFFF0000 = (Listing.FPCLine +1) Shl 16 Then
    EditorMarks[i] := 0
  Else
    EditorMarks[i] := LongWord(((Listing.FPCLine +1) Shl 16) or Listing.FPCPos);
  AddDirtyLine(EditorMarks[i]);
End;

Procedure SP_JumpToMark(i: Integer);
Var
  Sel: SP_SelectionInfo;
Begin
  If (EditorMarks[i] And $FFFF0000) Shr 16 > 0 Then Begin
    SP_GetSelectionInfo(Sel);
    Listing.FPCLine := ((EditorMarks[i] And $FFFF0000) Shr 16 ) -1;
    Listing.FPCPos := EditorMarks[i] And $FFFF;
    FPCDes := Listing.FPCPos;
    FPCDesLine := Listing.FPCLine;
    SP_FPClearSelection(Sel);
  End;
End;

Procedure SP_FPEditorPerformEdit(Key: Byte);
Var
  NewChar: Byte;
  s, prev: aString;
  Idx, DesiredPos, OldLine, c, i, n, nl, m, p, fp, GfxMode, Flag, l, cx, cy: Integer;
  OldPt, NewPt: TPoint;
  SB: pSP_ScrollBar;
  Sel: SP_SelectionInfo;
  Changed, SelWasActive, b: Boolean;
  Error: TSP_ErrorCode;
  Flags: TLineFlags;

  Procedure PlayClick;
  Begin
    If LASTKEYFLAG And KF_NOCLICK = 0 Then SP_PlaySystem(CLICKCHAN, CLICKBANK);
  End;

Begin

  // Test for control keys, then convert to ASCII using the
  // KEYBOARDSTATE sysvar.

  GfxMode := GFXLOCK;
  If ((KEYSTATE[K_CONTROL] = 1) And (KEYSTATE[K_ALT] = 1)) or (KEYSTATE[K_ALTGR] = 1) Then Begin
    GfxMode := 1 - GfxMode;
    If Key >= 32 Then
      LASTKEYCHAR := Ord(CharStr[Key][KEYSTATE[K_SHIFT] + 1]);
  End;
  NewChar := SP_DecodeKey(Key, False);
  {$IFDEF DARWIN}
  If ((NewChar = 97) And (Key = 40)) Or    // cmd+up
     ((NewChar = 109) And (Key = 13)) Or   // cmd+Enter
     ((NewChar = 98) And (Key = 37)) Or    // cmd+right
     ((NewChar = 56) And (Key = 8)) Or     // cmd+backspace
     ((NewChar = 99) And (Key = 39)) And   // cmd+left
     (KEYSTATE[K_CONTROL] = 1) Then
     NewChar := 0;
  If ((NewChar = 77) And (Key = 13)) Or    // Shift+Enter
     ((NewChar = 40) And (Key = 46)) Or    // Fn+Backspace
     ((NewChar = 44) And (Key = 33)) Or    // PgUp
     ((NewChar = 45) And (Key = 34)) Or    // PgDn
     ((NewChar = 41) And (Key = 36)) Or    // Home
     ((NewChar = 43) And (Key = 35)) Then  // End
     NewChar := 0;
  If (NewChar = 0) And (Key = 81) Then
    NewChar := 113;
  If (NewChar = 0) And (Key in [65..90]) Then
    NewChar := Key;
  {$ENDIF}
  DesiredPos := FPCDes;
  Dec(DesiredPos, Listing.Flags[Listing.FPCLine].Indent);

  {$IFDEF SPECCYKEYS}
  If (Key = K_1) And (KEYSTATE[K_SHIFT] = 1) Then Begin
    Key := K_TAB;
    NewChar := 0;
  End;
  {$ENDIF}

  Changed := False;
  SP_GetSelectionInfo(Sel);
  SelWasActive := Sel.Active;

  If Not (Key in [K_F3, K_ESCAPE]) Then
    HideSearchResults;

  If (aChar(NewChar) in ['a'..'z', 'A'..'Z', '0'..'9']) And Not Listing.UndoInProgress Then
    Listing.CommenceUndo;

  cx := Listing.FPCPos;
  cy := Listing.FPCLine;

  If (NewChar = 0) {$IFNDEF FPC} And (LASTKEYCHAR <> 1) {$ENDIF} Then Begin

    Case Key of
      K_F1..K_F10:
        Begin // F1 to F9 set markers (CTRL+Shift) and jump to markers (CTRL)
          {$IFNDEF DARWIN}
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            If KEYSTATE[K_SHIFT] = 1 Then Begin
              SP_ToggleEditorMark(Key - K_F1);
            End Else Begin
              SP_JumpToMark(Key - K_F1);
            End;
            SP_FPClearSelection(Sel);
          End Else
          {$ENDIF}
            Case Key of
              K_F1:
                Begin
                  // Help
                End;
              K_F3:
                Begin
                  // Repeat find/replace
                  FindNext(True);
                End;
              K_F4:
                Begin
                  // RUN to current line/statement - SHIFT to CONTINUE
                  If SP_CheckProgram Then Begin
                    SP_ToggleBreakPoint(True);
                    s := EDITLINE;
                    If KEYSTATE[K_SHIFT] = 0 Then
                      EDITLINE := 'RUN'
                    Else
                      EDITLINE := 'CONTINUE';
                    Listing.CompleteUndo;
                    SP_FPExecuteEditLine(EDITLINE);
                    EDITLINE := s;
                    SP_EditorDisplayEditLine;
                    SP_SwitchFocus(fwEditor);
                    SP_ClearKeyBuffer(True);
                  End Else Begin
                    FPCDes := Listing.FPCPos;
                    FPCDesLine := Listing.FPCLine;
                    SP_FPClearSelection(Sel);
                    SP_DisplayFPListing(-1);
                    SP_PlaySystem(ERRORCHAN, ERRSNDBANK);
                    CURSORFG := 10;
                    CURSORBG := 15;
                  End;
                End;
              K_F5:
                Begin
                  // Insert breakpoint here
                  SP_ToggleBreakpoint(False);
                End;
              K_F7:
                Begin
                  // Single step
                  If SP_CheckProgram Then
                    SP_SingleStep
                  Else Begin
                    FPCDes := Listing.FPCPos;
                    FPCDesLine := Listing.FPCLine;
                    SP_FPClearSelection(Sel);
                    SP_DisplayFPListing(-1);
                    SP_PlaySystem(ERRORCHAN, ERRSNDBANK);
                    CURSORFG := 10;
                    CURSORBG := 15;
                  End;
                  Exit;
                End;
              K_F8:
                Begin
                  // Step Over
                  If SP_CheckProgram Then Begin
                    If SP_StepOver Then Begin
                      s := EDITLINE;
                      EDITLINE := 'CONTINUE';
                      Listing.CompleteUndo;
                      SP_FPExecuteEditLine(EDITLINE);
                      EDITLINE := s;
                      SCREENLOCK := False;
                      SP_EditorDisplayEditLine;
                      SP_SwitchFocus(fwEditor);
                      SP_ClearKeyBuffer(True);
                    End;
                  End Else Begin
                    FPCDes := Listing.FPCPos;
                    FPCDesLine := Listing.FPCLine;
                    SP_FPClearSelection(Sel);
                    SP_DisplayFPListing(-1);
                    SP_PlaySystem(ERRORCHAN, ERRSNDBANK);
                    CURSORFG := 10;
                    CURSORBG := 15;
                  End;
                End;
              K_F9:
                Begin
                  // RUN (Shift = CONTINUE)
                  If SP_CheckProgram Then Begin
                    s := EDITLINE;
                    If KEYSTATE[K_SHIFT] = 0 Then
                      EDITLINE := 'RUN'
                    Else
                      EDITLINE := 'CONTINUE';
                    Listing.CompleteUndo;
                    SP_FPExecuteEditLine(EDITLINE);
                    EDITLINE := s;
                    SP_EditorDisplayEditLine;
                    SP_SwitchFocus(fwEditor);
                    SP_ClearKeyBuffer(True);
                  End Else Begin
                    FPCDes := Listing.FPCPos;
                    FPCDesLine := Listing.FPCLine;
                    SP_FPClearSelection(Sel);
                    SP_DisplayFPListing(-1);
                    SP_PlaySystem(ERRORCHAN, ERRSNDBANK);
                    CURSORFG := 10;
                    CURSORBG := 15;
                  End;
                  Exit;
                End;
              K_F10:
                Begin
                  // GO TO (Shift = RUN) current line
                  c := SP_GetLineNumberFromIndex(Listing.FPCLine);
                  If (c > 0) And SP_CheckProgram Then Begin
                    s := EDITLINE;
                    If KEYSTATE[K_SHIFT] = 0 Then
                      EDITLINE := 'GO TO ' + IntToString(c)
                    Else
                      EDITLINE := 'RUN ' + IntToString(c);
                    Listing.CompleteUndo;
                    SP_FPExecuteEditLine(EDITLINE);
                    EDITLINE := s;
                    SP_EditorDisplayEditLine;
                    SP_SwitchFocus(fwEditor);
                  End Else Begin
                    FPCDes := Listing.FPCPos;
                    FPCDesLine := Listing.FPCLine;
                    SP_FPClearSelection(Sel);
                    SP_DisplayFPListing(-1);
                    SP_PlaySystem(ERRORCHAN, ERRSNDBANK);
                    CURSORFG := 10;
                    CURSORBG := 15;
                  End;
                  Exit;
                End;
          End;
          PlayClick;
        End;

      K_ALT, K_ALTGR:
        Begin
          If KEYSTATE[K_SHIFT] = 1 Then Begin
            GFXLOCK := 1-GFXLOCK;
            PlayClick;
          End;
        End;

      K_RETURN:
        Begin
          Listing.CommenceUndo;
          PlayClick;
          If KEYSTATE[K_CONTROL] = 0 Then Begin // Regular ENTER key pressed.
            SP_FPDeleteSelection(Sel);
            CompilerLock.Enter;
            If Listing.FPCLine >= 0 Then Begin
              prev := Listing[Listing.FPCLine];
              If Prev <> '' Then Begin
                c := 1; n := 0;
                If Not SP_WasPrevSoft(Listing.FPCLine) Then
                  While (c < Length(Prev)) And (Prev[c] in ['0'..'9']) Do Inc(c);
                n := c;
                If StripSpaces(Prev) = '' Then
                  c := Length(Prev) +1
                Else Begin
                  While (c < Length(Prev)) And (Prev[c] <= ' ') Do Inc(c);
                  Inc(c, Listing.Flags[Listing.FPCLine].Indent);
                End;
                Dec(c, n);
                If Listing.FPCPos = 1 Then
                  c := 0;
              End Else
                c := 0;
            End Else
              c := 0;
            s := Copy(Listing[Listing.FPCLine], Listing.FPCPos);
            Flag := Listing.Flags[Listing.FPCLine].ReturnType;
            Listing[Listing.FPCLine] := Copy(Listing[Listing.FPCLine], 1, Listing.FPCPos -1);
            Listing.Flags[Listing.FPCLine].ReturnType := spHardReturn;
            If Listing.FPCLine <= Listing.Count -1 Then Begin
              SP_InsertLine(Listing.FPCLine +1, s, '', '');
              Listing.Flags[Listing.FPCLine +1].ReturnType := Flag;
            End Else Begin
              SP_AddLine(s, '', '');
              Listing.Flags[Listing.Count -1].ReturnType := spHardReturn;
            End;
            Listing.FPCPos := 1;
            n := Listing.FPCLine +1;
            SP_FPUnWrapLine(n);
            Listing.Flags[Listing.FPCLine +1].Indent := c;
            Changed := True;
            FPCDes := Listing.FPCPos;
            Inc(Listing.FPCLine);
            FPCDesLine := Listing.FPCLine;
            SP_FPClearSelection(Sel);
            SP_FPWordWrapLine(Listing.FPCLine -1);
            SP_FPWordWrapLine(Listing.FPCLine);
            SP_FPApplyHighlighting(Listing.FPCLine -1);
            SP_FPApplyHighlighting(Listing.FPCLine);
            AddVisibleDirty;
            Listing.CompleteUndo;
            CompilerLock.Leave;
          End Else Begin
            // Ctrl-Enter will cycle editor windows, CTRL+Shift+Enter will hide them.
            If KEYSTATE[K_SHIFT] = 0 Then
              SP_FPCycleEditorWindows(-1)
            Else
              Begin
                SP_FPCycleEditorWindows(1);
                SYSTEMSTATE := ss_IDLE;
                K_DOWNFLAG := False;
                LASTKEY := 0;
                Repeat
                  CB_YIELD;
                  If K_UPFLAG Then Begin
                    K_UPFLAG := False;
                    LASTKEY := 0;
                  End;
                Until Not (LASTKEY in [0, K_SHIFT]) or K_DOWNFLAG or M_DOWNFLAG;
                LASTKEY := 0;
                M_DOWNFLAG := False;
                SYSTEMSTATE := ss_EDITOR;
                SP_FPCycleEditorWindows(2);
              End;
          End;
        End;

      K_TAB:
        Begin
          If KEYSTATE[K_SHIFT] = 1 Then Begin
            // Back-tabulate
            If Sel.Active Then Begin
              Listing.CommenceUndo;
              Idx := Sel.StartL;
              While Idx <= Sel.EndL Do Begin
                SP_FPUnWrapLine(Idx);
                Inc(Idx);
              End;
              SP_GetSelectionInfo(Sel);
              For Idx := Sel.StartL To Sel.EndL Do Begin
                c := EDTABSIZE; m := Idx;
                s := Listing[Idx];
                n := SP_LineHasNumber(Idx);
                While (c > 0) and (Copy(s, n+1, 1) <= ' ') Do Begin
                  Dec(c);
                  s := Copy(s, 1, n) + Copy(s, n+2);
                  If Idx = Listing.FPCLine Then Listing.FPCPos := Listing.FPCPos -1 Else If Idx = Listing.FPSelLine Then Dec(Listing.FPSelPos);
                End;
                While (c > 0) and (Listing.Flags[Idx].Indent > 0) Do Begin
                  Dec(Listing.Flags[Idx].Indent);
                  Dec(c);
                End;
                Listing[Idx] := s;
                SP_MarkAsDirty(Idx);
                SP_FPApplyHighlighting(Idx);
                AddDirtyLine(Idx);
              End;
              Changed := True;
              SP_FPWrapProgram;
              AddDirtyLine(Sel.EndL);
              AddDirtyLine(Sel.StartL);
              Listing.CompleteUndo;
            End Else Begin
              // If we can remove tab spaces from the start of the line, do so.
              // Otherwise, just move the cursor back to the nearest tabstop.
              If Not Listing.UndoInProgress Then Listing.CommenceUndo;
              SP_FPUnWrapLine(Listing.FPCLine);
              s := Listing[Listing.FPCLine];
              n := SP_LineHasNumber(Listing.FPCLine);
              Idx := n+1;
              While Idx < Listing.FPCPos Do
                If s[Idx] > ' ' Then
                  Break
                Else
                  Inc(Idx);
              If Idx <> Listing.FPCPos Then Begin // If the cursor is in the middle of the text, then just move it back by tabsize.
                Listing.FPCPos := Max(Idx, ((Listing.FPCPos - EDTABSIZE) Div EDTABSIZE) * EDTABSIZE);
                AddDirtyLine(Listing.FPCLine);
              End Else Begin // Otherwise, start moving the text back to the next tabstop.
                c := Listing.FPCPos - (Listing.FPCPos - EDTABSIZE Div EDTABSIZE * EDTABSIZE);
                While (c > 0) and (Listing.FPCPos > n+2) and (Copy(s, n+1, 1) <= ' ') Do Begin
                  Dec(c);
                  Listing.FPCPos := Listing.FPCPos -1;
                  s := Copy(s, 1, n) + Copy(s, n+2);
                End;
                While (c > 0) and (Listing.Flags[Listing.FPCLine].Indent > 0) Do Begin
                  Dec(c);
                  Dec(Listing.Flags[Listing.FPCLine].Indent);
                End;
                Listing[Listing.FPCLine] := s;
                SP_FPWordWrapLine(Listing.FPCLine);
                SP_MarkAsDirty(Listing.FPCLine);
                Changed := True;
                SP_FPApplyHighlighting(Listing.FPCLine);
                AddDirtyLine(Listing.FPCLine);
              End;
              SP_FPClearSelection(Sel);
            End;
          End Else Begin
            // Tabulate
            If Sel.Active Then Begin
              Listing.CommenceUndo;
              If (Sel.StartL = Sel.EndL) And ((Sel.StartP > 1) or (Sel.EndP < Length(Listing[Sel.StartL]))) Then Begin
                SP_FPDeleteSelection(Sel);
                s := Listing[Listing.FPCLine];
                s := Copy(s, 1, Listing.FPCPos -1) + StringOfChar(' ', EDTABSIZE) + Copy(s, Listing.FPCPos);
                Listing[Listing.FPCLine] := s;
                SP_FPWordWrapLine(Listing.FPCLine);
                SP_MarkAsDirty(Listing.FPCLine);
                Changed := True;
              End Else Begin
                Idx := Sel.StartL;
                While Idx <= Sel.EndL Do Begin
                  SP_FPUnWrapLine(Idx);
                  Inc(Idx);
                End;
                SP_GetSelectionInfo(Sel);
                For Idx := Sel.StartL To Sel.EndL Do Begin
                  s := Listing[Idx];
                  n := SP_LineHasNumber(Idx);
                  s := Copy(s, 1, n) + StringOfChar(' ', EDTABSIZE) + Copy(s, n+1);
                  Listing[Idx] := s;
                  SP_MarkAsDirty(Idx);
                  SP_FPApplyHighlighting(Idx);
                  AddDirtyLine(Idx);
                End;
                SP_FPWrapProgram;
                Changed := True;
                Inc(Listing.FPSelPos, EDTABSIZE);
                Listing.FPCPos := Listing.FPCPos + EDTABSIZE;
                AddDirtyLine(Sel.EndL);
                AddDirtyLine(Sel.StartL);
              End;
              Listing.CompleteUndo;
            End Else Begin
              If Not Listing.UndoInProgress Then Listing.CommenceUndo;
              i := Listing.Flags[Listing.FPCLine].Indent;
              s := Listing[Listing.FPCLine];
              c := (Listing.FPCPos - (SP_LineHasNumber(Listing.FPCLine)) + 1) + i;
              c := (((c + EDTABSIZE) Div EDTABSIZE) * EDTABSIZE) - c;
              s := Copy(s, 1, Listing.FPCPos -1) + StringOfChar(' ', c) + Copy(s, Listing.FPCPos);
              Listing[Listing.FPCLine] := s;
              Listing.Flags[Listing.FPCLine].Indent := i;
              Listing.FPCPos := Listing.FPCPos + c;
              SP_FPWordWrapLine(Listing.FPCLine);
              SP_MarkAsDirty(Listing.FPCLine);
              SP_FPClearSelection(Sel);
              SP_FPApplyHighlighting(Listing.FPCLine);
              AddDirtyLine(Listing.FPCLine);
            End;
          End;
          FPCDes := Listing.FPCPos;
          FPCDesLine := Listing.FPCLine;
          PlayClick;
        End;

      K_LEFT:
        Begin  // CTRL - word jump. Shift - extend selection.
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            s := Listing[Listing.FPCLine];
            If (s <> '') And (Listing.FPCPos > 1) Then Begin
              If s[Listing.FPCPos -1] in Seps Then Listing.FPCPos := Listing.FPCPos -1;
              While (Listing.FPCPos > 1) And ((Listing.FPCPos > Length(s)) Or (s[Listing.FPCPos] in Seps)) Do Listing.FPCPos := Listing.FPCPos -1;
              While (Listing.FPCPos > 1) and (Not (s[Listing.FPCPos] in Seps)) Do Listing.FPCPos := Listing.FPCPos -1;
              If Listing.FPCPos > 1 Then
                Listing.FPCPos := Listing.FPCPos +1;
            End;
          End Else Begin
            If Listing.FPCPos > 1 Then
              Listing.FPCPos := Listing.FPCPos -1
            Else
              If Listing.FPCLine > 0 Then Begin
                Dec(Listing.FPCLine);
                Listing.FPCPos := Length(Listing[Listing.FPCLine]) + Ord(Listing.Flags[Listing.FPCLine].ReturnType <> spSoftReturn);
              End;
          End;
          If KEYSTATE[K_SHIFT] = 0 Then SP_FPClearSelection(Sel);
          FPCDes := Listing.FPCPos;
          FPCDesLine := Listing.FPCLine;
          PlayClick;
        End;

      K_RIGHT: // CTRL - word jump. Shift - extend selection
        Begin
          s := Listing[Listing.FPCLine];
          If Listing.Flags[Listing.FPCLine].ReturnType <> spSoftReturn Then s := s + ' ';
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            Idx := Listing.FPCPos;
            If s[Idx] in Seps Then Begin
              While (Idx < Length(s)) And (s[Idx] in Seps) Do
                Inc(Idx);
            End Else Begin
              While (Idx < Length(s)) And Not (s[Idx] in Seps) Do
                Inc(Idx);
              While (Idx < Length(s)) And (s[Idx] in Seps) Do
                Inc(Idx);
            End;
            Listing.FPCPos := Idx;
          End Else Begin
            If Listing.FPCPos < Length(s) Then
              Listing.FPCPos := Listing.FPCPos +1
            Else
              If Listing.FPCLine < Listing.Count -1 Then Begin
                Inc(Listing.FPCLine);
                Listing.FPCPos := 1;
              End;
          End;
          If KEYSTATE[K_SHIFT] = 0 Then SP_FPClearSelection(Sel);
          FPCDes := Listing.FPCPos;
          FPCDesLine := Listing.FPCLine;
          PlayClick;
        End;

      K_UP: // CTRL - Line up, jump to start of current line, or previous line. Shift - extend selection
        Begin
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            If Listing.FPCLine > 0 Then Begin
              If SP_LineHasNumber(Listing.FPCLine) > 0 Then
                Dec(Listing.FPCLine);
              While (Listing.FPCLine > 0) And (SP_LineHasNumber(Listing.FPCLine) = 0) Do
                Dec(Listing.FPCLine);
            End;
          End Else
            If Listing.FPCLine > 0 Then Begin
              Dec(Listing.FPCLine);
            End;
          Listing.FPCPos := SP_GetDesired;
          s := Listing[Listing.FPCLine];
          If Listing.Flags[Listing.FPCLine].ReturnType <> spSoftReturn Then s := s + ' ';
          If Listing.FPCPos > Length(s) Then
            Listing.FPCPos := Length(s);
          If KEYSTATE[K_SHIFT] = 0 Then SP_FPClearSelection(Sel);
          PlayClick;
        End;

      K_DOWN:
        Begin // CTRL - Jump to start of next line's number line. Shift - Extend selection.
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            If Listing.FPCLine < Listing.Count -1 Then
              Inc(Listing.FPCLine);
            While (Listing.FPCLine < Listing.Count -1) And (SP_LineHasNumber(Listing.FPCLine) = 0) Do
              Inc(Listing.FPCLine);
          End Else
            If Listing.FPCLine < Listing.Count -1 Then Begin
              Inc(Listing.FPCLine);
            End;
          Listing.FPCPos := SP_GetDesired;
          s := Listing[Listing.FPCLine];
          If Listing.Flags[Listing.FPCLine].ReturnType <> spSoftReturn Then s := s + ' ';
          If Listing.FPCPos > Length(s) Then
            Listing.FPCPos := Length(s);
          If KEYSTATE[K_SHIFT] = 0 Then SP_FPClearSelection(Sel);
          PlayClick;
        End;

      K_HOME:
        Begin // jump to first char after gutter, then start of line number if possible. CTRL - top of listing. Shift - extend selection.
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            Listing.FPCLine := 0;
            Listing.FPCPos := Length(Listing[Listing.FPCLine]);
          End;
          Idx := 1;
          If Listing[Listing.FPCLine] <> '' Then
            If Not SP_WasPrevSoft(Listing.FPCLine) Then
              While (Idx < Length(Listing[Listing.FPCLine])) And (Listing[Listing.FPCLine][Idx] in ['0'..'9', ' ']) Do
                Inc(Idx);
          If Listing.FPCPos > Idx Then
            Listing.FPCPos := Idx
          Else
            Listing.FPCPos := 1;
          If KEYSTATE[K_SHIFT] = 0 Then SP_FPClearSelection(Sel);
          FPCDes := Listing.FPCPos;
          FPCDesLine := Listing.FPCLine;
          PlayClick;
        End;

      K_END:
        Begin // Jump to end of line. CTRL - end of listing. Shift - extend selection
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            Listing.FPCLine := Listing.Count -1;
          End;
          s := Listing[Listing.FPCLine];
          If Listing.Flags[Listing.FPCLine].ReturnType <> spSoftReturn Then s := s + ' ';
          Listing.FPCPos := Length(s);
          FPCDes := Listing.FPCPos;
          FPCDesLine := Listing.FPCLine;
          If KEYSTATE[K_SHIFT] = 0 Then SP_FPClearSelection(Sel);
          PlayClick;
        End;

      K_PRIOR:
        Begin // Ctrl - Jump to first line on this page. Shift - extend selection
          SB := @FPScrollBars[SP_FindScrollBar(FPVertSc)];
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            Listing.FPCLine := Max(Trunc(SB^.Position/FPFh), 0);
          End Else Begin
            Listing.FPCLine := Max(0, (Listing.FPCLine - (SB^.PageSize Div FPFh)) +1);
          End;
          Listing.FPCPos := SP_GetDesired;
          SP_CalculateFPCursorPos;
          FPCDes := Listing.FPCPos;
          If KEYSTATE[K_SHIFT] = 0 Then SP_FPClearSelection(Sel);
          PlayClick;
        End;

      K_NEXT:
        Begin // CTRL - jump to last line on this page. Shift - extend selection
          SB := @FPScrollBars[SP_FindScrollBar(FPVertSc)];
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            Listing.FPCLine := Min(Trunc(SB^.Position/FPFh) + (SB^.PageSize Div FPFh), Listing.Count -1);
            AddDirtyLine(Idx);
          End Else Begin
            Listing.FPCLine := Min(Listing.Count -1, Listing.FPCLine + (SB^.PageSize Div FPFh) -1);
          End;
          Listing.FPCPos := SP_GetDesired;
          SP_CalculateFPCursorPos;
          FPCDes := Listing.FPCPos;
          If KEYSTATE[K_SHIFT] = 0 Then SP_FPClearSelection(Sel);
          PlayClick;
        End;

      K_BACK:
        Begin
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            Listing.CommenceUndo;
            c := Listing.Flags[Listing.FPCLine].Indent;
            SP_FPUnwrapLine(Listing.FPCLine);
            SP_DeleteWord(True);
            Listing.Flags[Listing.FPCLine].Indent := c;
            SP_FPWordWrapLine(Listing.FPCLine);
            SP_FPApplyHighlighting(Listing.FPCLine);
            SP_MarkAsDirty(Listing.FPCLine);
            Listing.CompleteUndo;
          End Else Begin
            If Not Sel.Active Then Begin
              If Not Listing.UndoInProgress Then Listing.CommenceUndo;
              // figure out the amount of whitespace at the start of this line, and
              // at the start of the next line up that's got less whitespace than this one.
              // m = this line, n = previous. p = position of first character after the space.
              m := 1; p := 0;
              c := Listing.Flags[Listing.FPCLine].Indent;
              If SP_LineHasNumber(Listing.FPCLine) > 0 Then Begin
                While (m < Length(Listing[Listing.FPCLine])) And (Listing[Listing.FPCLine][m] in ['0'..'9']) Do
                  Inc(m);
              End;
              nl := m -1;
              While (m < Length(Listing[Listing.FPCLine])) And (m < Listing.FPCPos) And (Listing[Listing.FPCLine][m] <= ' ') Do Begin
                p := Min(m, p+1);
                Inc(c);
                Inc(m);
              End;
              m := c;
              fp := Listing.FPCLine;
              c := $FFFF;
              While (c >= m) And (fp >= 0) Do Begin
                n := 1;
                Dec(fp);
                If fp < 0 Then Begin
                  c := 0;
                  Break;
                End;
                If SP_LineHasNumber(fp) > 0 Then
                  While Listing[fp][n] in ['0'..'9'] Do
                    Inc(n);
                c := Listing.Flags[fp].Indent;
                If n < Length(listing[fp]) Then
                  If Listing[fp] <> '' Then
                    While Listing[fp][n] <= ' ' Do Begin
                      Inc(n);
                      Inc(c);
                    End;
              End;
              n := c;
              // Is the cursor at this position?
              If (Listing.FPCPos > p +1) or ((nl > 0) And (Listing.FPCPos <= nl +1)) And (Listing.FPCPos > 1) Then Begin
                // Nope - just delete a character
                Listing[Listing.FPCLine] := Copy(Listing[Listing.FPCLine], 1, Listing.FPCPos -2) + Copy(Listing[Listing.FPCLine], Listing.FPCPos);
                Listing.FPCPos := Listing.FPCPos -1;
              End Else Begin
                // At the very start of the line (Listing.FPCPos = 1 and Indent is zero) ?
                //If (Listing.FPCPos = 1) And ((Listing.Flags[Listing.FPCLine].Indent = 0) or Not SP_WasPrevSoft(Listing.FPCLine)) Then Begin
                b := SP_WasPrevSoft(Listing.FPCLine) or (Listing.Flags[Listing.FPCLine].Indent = 0);
                If (Listing.FPCPos = 1) And b Then Begin
                  If Listing.FPCLine > 0 Then Begin
                    Dec(Listing.FPCLine);
                    If Listing.Flags[Listing.FPCLine].ReturnType = spSoftReturn Then Begin
                      Listing.FPCPos := Length(Listing[Listing.FPCLine]);
                      Listing[Listing.FPCLine] := Copy(Listing[Listing.FPCLine], 1, Length(Listing[Listing.FPCLine]) -1) + Listing[Listing.FPCLine +1];
                    End Else Begin
                      Listing.FPCPos := Length(Listing[Listing.FPCLine]) +1;
                      Listing[Listing.FPCLine] := Listing[Listing.FPCLine] + Listing[Listing.FPCLine +1];
                    End;
                    Listing.Flags[Listing.FPCLine].ReturnType := Listing.Flags[Listing.FPCLine +1].ReturnType;
                    SP_DeleteLine(Listing.FPCLine +1);
                    SP_FPWordWrapLine(Listing.FPCLine);
                    SP_FPApplyHighlighting(Listing.FPCLine);
                    SP_MarkAsDirty(Listing.FPCLine);
                  End Else Begin
                    SP_FPWordWrapLine(Listing.FPCLine);
                    SP_FPApplyHighlighting(Listing.FPCLine);
                  End;
                End Else Begin
                  // After all that, we're backspacing through whitespace.
                  // We need to make the current line's whitespace (including indent) the same as the line above:
                  c := 1;
                  s := Listing[Listing.FPCLine];
                  If (s <> '') And (Listing.FPCPos > 1) Then Begin
                    While (c <= Length(s)) And (s[c] in ['0'..'9']) Do Inc(c);
                    While (s <> '') And (n < m) And (s[1] <= ' ') Do Begin
                      s := Copy(s, c+1);
                      Dec(m);
                      Listing.FPCPos := Listing.FPCPos -1;
                    End;
                    Listing[Listing.FPCLine] := s;
                    If n < m Then
                      Dec(Listing.Flags[Listing.FPCLine].Indent, m-n);
                  End Else
                    If (Listing.FPCPos = 1) And (Listing.Flags[Listing.FPCLine].Indent > 0) Then
                      Dec(Listing.Flags[Listing.FPCLine].Indent, m-n);
                End;
              End;
              FPCDes := Listing.FPCPos;
              FPCDesLine := Listing.FPCLine;
              SP_FPClearSelection(Sel);
              SP_FPWordWrapLine(Listing.FPCLine, True);
              SP_FPApplyHighlighting(Listing.FPCLine);
              SP_MarkAsDirty(Listing.FPCLine);
            End Else Begin
              Listing.CommenceUndo;
              SP_FPDeleteSelection(Sel);
              Listing.CompleteUndo;
            End;
          End;
          Changed := True;
          FPCDes := Listing.FPCPos;
          FPCDesLine := Listing.FPCLine;
          SP_FPClearSelection(Sel);
          PlayClick;
        End;

      K_DELETE:
        Begin
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            Listing.CommenceUndo;
            SP_FPUnwrapLine(Listing.FPCLine);
            SP_DeleteWord(False);
            SP_FPWordWrapLine(Listing.FPCLine);
            SP_MarkAsDirty(Listing.FPCLine);
            SP_FPApplyHighlighting(Listing.FPCLine);
            Listing.CompleteUndo;
          End Else Begin
            If Not Sel.Active Then Begin
              If Not Listing.UndoInProgress Then Listing.CommenceUndo;
              s := Listing[Listing.FPCLine];
              If s <> '' Then Begin
                If (Listing.FPCPos <= Length(s)) And (StripSpaces(Copy(s, Listing.FPCPos)) <> '') Then Begin
                  If Listing.FPCPos > 1 Then
                    s := Copy(s, 1, Listing.FPCPos -1) + Copy(s, Listing.FPCPos +1, Length(s))
                  Else
                    S := Copy(s, Listing.FPCPos +1);
                  Listing[Listing.FPCLine] := s;
                  SP_FPWordWrapLine(Listing.FPCLine);
                  SP_MarkAsDirty(Listing.FPCLine);
                  SP_FPApplyHighlighting(Listing.FPCLine);
                End Else Begin
                  If Listing.FPCLine < Listing.Count -1 Then Begin
                    Listing[Listing.FPCLine] := Copy(Listing[Listing.FPCLine], 1, Listing.FPCPos -1);
                    Listing[Listing.FPCLine] := Listing[Listing.FPCLine] + Listing[Listing.FPCLine +1];
                    Listing.Flags[Listing.FPCLine].ReturnType := Listing.Flags[Listing.FPCLine +1].ReturnType;
                    SP_DeleteLine(Listing.FPCLine +1);
                    SP_FPWordWrapLine(Listing.FPCLine);
                    SP_MarkAsDirty(Listing.FPCLine);
                    SP_FPApplyHighlighting(Listing.FPCLine);
                  End Else Begin
                    SP_FPWordWrapLine(Listing.FPCLine);
                    SP_FPApplyHighlighting(Listing.FPCLine);
                  End;
                End;
              End Else Begin
                If Listing.FPCLine < Listing.Count -1 Then Begin
                  Listing.Flags[Listing.FPCLine].ReturnType := Listing.Flags[Listing.FPCLine +1].ReturnType;
                  SP_DeleteLine(Listing.FPCLine);
                  SP_MarkAsDirty(Listing.FPCLine);
                End;
              End;
            End Else Begin
              Listing.CommenceUndo;
              SP_FPDeleteSelection(Sel);
              Listing.CompleteUndo;
            End;
          End;
          FPCDes := Listing.FPCPos;
          FPCDesLine := Listing.FPCLine;
          SP_FPClearSelection(Sel);
          Changed := True;
          PlayClick;
        End;

      K_INSERT:
        Begin
          INSERT := Not INSERT;
          PlayClick;
        End;

      K_ESCAPE:
        Begin // No idea. Switch to Direct command?
          SP_SwitchFocus(fwDirect);
          PlayClick;
        End;

    End;

  End Else Begin

    // CTRL+SHIFT (AltGr) - UDG.

    PlayClick;
    If (KEYSTATE[K_CONTROL] = 0) or ((KEYSTATE[K_CONTROL] = 1) And (KEYSTATE[K_ALT] = 1)) Then Begin
      {$IFDEF DARWIN}
      If (NewChar in [65..90]) And (((KEYSTATE[K_SHIFT] = 0) And (CAPSLOCK = 0)) or ((KEYSTATE[K_SHIFT] = 1) And (CAPSLOCK = 1))) Then Begin
        NewChar := NewChar + 32;
      End;
      {$ENDIF}
      If Sel.Active or Not (aChar(NewChar) in ['a'..'z', 'A'..'Z', '0'..'9']) or Not Listing.UndoInProgress Then Listing.CommenceUndo;
      If Sel.Active Then Begin
        SP_FPDeleteSelection(Sel);
        Listing.CompleteUndo;
        Listing.CommenceUndo;
      End;
      s := Listing[Listing.FPCLine];
      If GfxMode = 1 Then Begin
        If INSERT Then Begin
          s := Copy(s, 1, Listing.FPCPos -1) + aChar(Byte(NewChar)+128) + Copy(s, Listing.FPCPos, Length(s));
          Listing.FPCPos := Listing.FPCPos +1;
        End Else Begin
          s := Copy(s, 1, Listing.FPCPos -1) + aChar(Byte(NewChar)+128) + Copy(s, Listing.FPCPos +1, LENGTH(s));
          Listing.FPCPos := Listing.FPCPos +1;
        End;
        Changed := True;
        SP_FPClearSelection(Sel);
        PlayClick;
      End Else Begin
        If KEYSTATE[K_CONTROL] = 0 Then Begin
          If INSERT Then
            s := Copy(s, 1, Listing.FPCPos -1) + aChar(NewChar) + Copy(s, Listing.FPCPos, Length(s))
          Else Begin
            s := Copy(s, 1, Listing.FPCPos -1) + aChar(NewChar) + Copy(s, Listing.FPCPos +1, LENGTH(s));
          End;
          Listing.FPCPos := Listing.FPCPos +1;
          Changed := True;
          SP_FPClearSelection(Sel);
        End;
      End;
      If Changed And (s <> Listing[Listing.FPCLine]) Then Begin
        Listing[Listing.FPCLine] := s;
        // If we have a hard return and then a number, it's a new line of code so remove any indentation.
        If Not SP_WasPrevSoft(Listing.FPCLine) And (s[1] in ['0'..'9']) Then Begin
          Listing.Flags[Listing.FPCLine].Indent := 0;
          If Listing.FPCLine > 0 Then
            SP_MarkAsDirty(Listing.FPCLine -1);
        End;
        SP_FPWordWrapLine(Listing.FPCLine);
        FPCDes := Listing.FPCPos;
        FPCDesLine := Listing.FPCLine;
        SP_MarkAsDirty(Listing.FPCLine);
        SP_FPApplyHighlighting(Listing.FPCLine);
        SP_FPRethinkScrollBars;
      End;

    End Else Begin

      // CTRL+key combo - cut, copy, paste, save, undo etc
      Case Lower(aChar(NewChar))[1] of
          {$IFDEF DARWIN}
          '1'..'9':
            Begin
              If KEYSTATE[K_SHIFT] = 1 Then Begin
                SP_ToggleEditorMark(Key - K_1);
              End Else Begin
                SP_JumpToMark(Key - K_1);
                Idx := Listing.FPCLine;
                While (Idx >= 0) And (SP_GetLineNumberFromText(Listing[Idx]) <= 0) Do Dec(Idx);
                PROGLINE := SP_GetLineNumberFromText(Listing[Idx]);
                If PROGLINE <= 0 Then Begin
                  While (Idx < Listing.Count) And (SP_GetLineNumberFromText(Listing[Idx]) <= 0) Do Inc(Idx);
                  PROGLINE := SP_GetLineNumberFromText(Listing[Idx]);
                End;
                SP_CalculateFPCursorPos;
              End;
              SP_FPClearSelection(Sel);
            End;
        'q':
            Begin
              // Quit
              TerminateInterpreter := True;
              CB_Quit;
            End;
            {$ENDIF}
        'z':
          Begin
            // Undo
            CompilerLock.Enter;
            If KEYSTATE[K_SHIFT] = 0 Then
              s := Listing.PerformUndo
            Else
              s := Listing.PerformRedo;
            While SyntaxListing.Count < Listing.Count Do
              SyntaxListing.Add('');
            While CompiledListing.Count < Listing.Count Do
              CompiledListing.Add('');
            While s <> '' Do Begin
              Idx := pLongWord(@s[1])^;
              SP_MarkAsDirty(Idx);
              SP_FPApplyHighlighting(Idx);
              s := Copy(s, SizeOf(LongWord) +1);
            End;
            AddVisibleDirty;
            CompilerLock.Leave;
          End;
        'c':
          Begin
            // Copy
            SP_CopySelection;
          End;
        'x':
          Begin
            // Cut
            Listing.CommenceUndo;
            SP_CutSelection;
            Listing.CompleteUndo;
          End;
        'v':
          Begin
            // Paste
            Listing.CommenceUndo;
            SP_PasteSelection;
            Listing.CompleteUndo;
          End;
        'a':
          Begin
            // Select All
            SP_SelectAll;
          End;
        'd':
          Begin
            // Select None
            SP_SelectNone;
          End;
        'r':
          Begin
            // Replace
            StartFindOp(False);
          End;
        'f':
          Begin
            // Find
            StartFindOp(True);
          End;
        'g':
          Begin
            // Go to line/label
            // Shift - go to last error
            If KEYSTATE[K_SHIFT] = 0 Then
              StartGotoOp
            Else
              SP_FPGotoLine(LASTERRORLINE, LASTERRORSTATEMENT);
          End;
        'o':
          Begin
            // Re-order listing
            Listing.CommenceUndo;
            SP_ReOrderListing(Error);
            Listing.CompleteUndo;
          End;
        'l':
          Begin
            // LOAD ""
            StartFileOp(SP_KW_LOAD, '');
          End;
        'm':
          Begin
            // Merge ""
            StartFileOp(SP_KW_MERGE, '');
          End;
        'n':
          Begin
            // Add new breakpoint
            StartBPEditOp(-1, nil);
          End;
        's':
          Begin
            // Save
            StartFileOp(SP_KW_SAVE, PROGNAME);
          End;
        'w':
          Begin
            StartWatchOp(-1);
          End;
        'b':
          Begin
            If FPDebugPanelVisible Then
              SP_CloseDebugPanel
            Else
              SP_OpenDebugPanel;
          End;
      End;
    End;
    SP_CursorPosChanged;
  End;

  // When a key is pressed, clear the error state and set the cursor back to
  // the correct colours.

  EDITERROR := False;
  If GfxMode = 1 Then Begin
    CURSORFG := 0;
    CURSORBG := 6;
  End Else
    SP_SetCursorColours;

  // Work through any updates.

  SP_CalculateFPCursorPos;
  SP_CursorPosChanged;
  SP_DrawGraphicsID;
  SP_RefreshCursorLineAfterChange(Cy);
  UpdateStatusLabel;

  SP_ScrollInView;

End;

Procedure SP_FPUnWrapLine(Line: Integer);
Var
  s: aString;
  lMin, lMax, Idx, l, OldIndent: Integer;
  c: Boolean;
  Flag: Integer;
Begin

  // Unwraps soft carriage returns into one line, for easier editing

  c := FILECHANGED;
  Listing.OnChange := nil;

  s := '';
  lMin := Line;
  While (lMin > 0) And SP_WasPrevSoft(lMin) Do Dec(lMin);
  lMax := lMin;
  While (lMax < Listing.Count -1) And (Listing.Flags[lMax].ReturnType = spSoftReturn) Do Inc(lMax);

  If lMin = lMax Then Begin
    Listing.OnChange := ListingChange;
    FILECHANGED := c;
    Exit; // No need to unwrap this line
  End;

  // Fix the cursor position

  oldIndent := Listing.Flags[lMin].Indent;
  l := 0;
  Flag := spLineNull;
  For Idx := lMin To lMax Do Begin
    s := s + Listing[Idx];
    Flag := Max(Flag, Listing.Flags[Idx].State);
    If Listing.FPCLine = Idx Then Begin
      Listing.FPCLine := lMin;
      Listing.FPCPos := Listing.FPCPos +l;
    End;
    If Listing.FPSelLine = Idx Then Begin
      Listing.FPSelLine := lMin;
      Inc(Listing.FPSelPos, l);
    End;
    Inc(l, Length(Listing[Idx]));
  End;

  CompilerLock.Enter;
  For Idx := lMin To lMax Do SP_DeleteLine(lMin, False);
  SP_InsertLine(lMin, s, '', '', False);
  Listing.Flags[lMin].ReturnType := spHardReturn;
  Listing.Flags[lMin].Indent := oldIndent;
  Listing.Flags[lMin].State := Flag;
  CompilerLock.Leave;

  FILECHANGED := c;
  Listing.OnChange := ListingChange;

End;

Function SP_FPGetUnwrappedLine(Var Line: Integer): aString;
Var
  lMin, lMax, Idx: Integer;
Begin

  Result := '';
  If Line < Listing.Count Then Begin
    lMin := Line;
    While (lMin > 0) And SP_WasPrevSoft(lMin) Do Dec(lMin);
    lMax := lMin;
    While (lMax < Listing.Count -1) And (Listing.Flags[lMax].ReturnType = spSoftReturn) Do Inc(lMax);

    For Idx := lMin To lMax Do
      Result := Result + Listing[Idx];

    Line := lMax +1;
  End;

End;

Procedure SP_FPWordWrapLine(Line: Integer; FromHere: Boolean);
Var
  Idx, lIdx, MaxW, Min, Max, tx, cp, sp, ns, l, indent, state: Integer;
  s, s2, s3, os, nl: aString;
  HasNumber, c: Boolean;
Begin

  If (Line >= Listing.Count) Or Not EDITORWRAP Then Exit;

  // Check a line for word wrapping.
  // Step back until we find a line that does not have a soft-return flag in the flags array.
  // Then gather all subsequent lines together (exclusive of that discovered line) and split them with
  // soft-return flags as they are added.

  c := FILECHANGED;
  Listing.OnChange := nil;

  s := '';
  Min := Line;
  If Not FromHere Then
    While (Min > 0) And SP_WasPrevSoft(Min) Do Dec(Min);
  Max := Min;
  While (Max < Listing.Count -1) And (Listing.Flags[Max].ReturnType <> spHardReturn) Do Inc(Max);
  MaxW := ((FPPaperWidth - (FPGutterWidth * FPFw)) Div FPFw) -2;
  indent := Listing.Flags[Min].Indent;

  ns := 0;
  nl := Listing[Min];
  state := Listing.Flags[Min].State;
  For Idx := Min To Max Do
    ns := ns + Length(Listing[Idx]);

  If ns < MaxW-indent Then Begin
    FILECHANGED := c;
    AddCompileLine(Min);
    Listing.OnChange := ListingChange;
    Exit;
  End;

  cp := -1; sp := -1;
  For Idx := Min To Max Do Begin
    If Listing.FPSelLine = Idx Then sp := Length(s) + Listing.FPSelPos;
    If Listing.FPCLine = Idx Then cp := Length(s) + Listing.FPCPos;
    s := s + Listing[Min];
    SP_DeleteLine(Min, False);
  End;

  HasNumber := s[1] in ['0'..'9'];

  s2 := '';
  l := Length(nl);
  ns := SP_GetLineNumberFromText(s);
  If ns > 0 Then Begin
    s2 := IntToString(ns);
    s := Copy(s, Pos(s2, s) + Length(s2));
    Dec(cp, Length(s2));
    Dec(sp, Length(s2));
    Idx := 1; ns := 0;
    While (Idx < l) And (nl[Idx] <= ' ') Do Inc(Idx);
  End Else Begin
    Idx := 1;
    ns := 0;
  End;
  While (Idx < l) And (nl[Idx] in ['0'..'9']) Do Inc(Idx);
  While (Idx < l) And (nl[Idx] <= ' ') Do Begin
    Inc(Idx);
    Inc(ns);
  End;

  Dec(MaxW, Indent);

  Idx := Min;
  Repeat
    If Length(s) > MaxW Then Begin
      s3 := Copy(s, 1, MaxW);
      s := Copy(s, MaxW +1);
      If cp >= 0 Then
        If cp <= MaxW Then Begin
          Listing.FPCLine := Idx;
          Listing.FPCPos := cp + Length(s2);
          cp := -1;
        End Else
          Dec(cp, MaxW);
      If sp >= 0 Then
        If sp <= MaxW Then Begin
          Listing.FPSelLine := Idx;
          Listing.FPSelPos := sp + Length(s2);
          sp := -1;
        End Else
          Dec(sp, MaxW);
      If s2 <> '' Then Begin
        s3 := s2 + s3;
        s2 := '';
      End;
      If s3 <> '' Then Begin
        SP_InsertLine(Idx, s3, '', '', False);
        Listing.Flags[Idx].ReturnType := spSoftReturn;
        Listing.Flags[Idx].Indent := indent;
        Listing.Flags[Idx].State := state;
        If Idx = Min Then Inc(indent, ns);
      End Else Begin
        SP_InsertLine(Idx, s, '', '', False);
        Listing.Flags[Idx].Indent := indent;
        Listing.Flags[Idx].State := state;
        If Idx = Min Then Inc(indent, ns);
        s := '';
      End;
      If Idx = Min Then Dec(MaxW, ns);
      Inc(Idx);
    End Else Begin
      If s2 <> '' Then s := s2 + s;
      SP_InsertLine(Idx, s, '', '', False);
      s := '';
      If cp >= 0 Then Begin
        Listing.FPCLine := Idx;
        Listing.FPCPos := cp + Length(s2);
      End;
      If sp >= 0 Then Begin
        Listing.FPSelLine := Idx;
        Listing.FPSelPos := sp + Length(s2);
      End;
      Listing.Flags[Idx].ReturnType := spHardReturn;
      Listing.Flags[Idx].Indent := indent;
      Listing.Flags[Idx].State := state;
      If Idx = Min Then Inc(indent, ns);
      If Idx = Min Then Dec(MaxW, ns);
      Inc(Idx);
    End;
  Until s = '';

  AddCompileLine(Min);
  Dec(Idx);
  Listing.Flags[Idx].ReturnType := spHardReturn;
  FILECHANGED := c;
  Listing.OnChange := ListingChange;

End;

Procedure SP_FPWrapProgram;
Var
  Idx, Idx2: Integer;
Begin

  If Not EDITORWRAP Then Exit;

  // Runs through the whole program, wraps all lines

  Idx := 0;
  While Idx < Listing.Count Do Begin
    SP_FPUnWrapLine(Idx);
    SP_FPWordWrapLine(Idx);
    While (Idx < Listing.Count) And (Listing.Flags[Idx].ReturnType = spSoftReturn) Do
      Inc(Idx);
    Inc(Idx);
  End;
  AddVisibleDirty;
  SP_CursorPosChanged;

End;

Procedure SP_FPResizeWindow(NewH: Integer);
Var
  WindowID: Integer;
  Err: TSP_ErrorCode;
Begin

  NewH := Max(NewH, 0);

  WindowID := SCREENBANK;
  SP_SetDrawingWindow(FPWindowID);

  FPWindowWidth := DISPLAYWIDTH - BSize * 2;
  FPWindowHeight := NewH;

  FPCaptionHeight := FPFh + 2;
  FPClientWidth := FPWindowWidth - 2;
  FPClientHeight := FPWindowHeight - FPCaptionHeight - 1;
  FPClientLeft := 1;
  FPClientTop := FPCaptionHeight;

  If Assigned(FPMenu) Then Begin
    Dec(FPClientHeight, FPMenu.Height);
    Inc(FPClientTop, FPMenu.Height);
  End;

  FPPaperLeft := BSize + FPClientLeft;
  FPPaperTop := BSize + FPClientTop;
  FPPaperWidth := FPClientWidth - (BSize * 3) - Fw - ((FPDebugPanelWidth + BSize) * Ord(FPDebugPanelVisible));
  FPPaperHeight := FPClientHeight - (BSize * 2) - (Ord(Not EDITORWRAP) * (BSize + Fh));

  SP_ResizeWindow(FPWindowID, FPWindowWidth, FPWindowHeight, 8, False, Err);
  SP_Decorate_Window(FPWindowID, 'Program listing - ' + SP_GetProgName(PROGNAME, True), True, False, FocusedWindow = fwEditor);
  SP_AddFPScrollBars(False);
  SP_FPRethinkScrollBars;
  SP_DisplayFPListing(-1);

  SP_SetDrawingWindow(WindowID);

End;

Procedure SP_DWResizeWindow(NewW, NewH: Integer; Redraw: Boolean);
Var
  Font, WindowID: Integer;
  Win: pSP_Window_Info;
  Err: TSP_ErrorCode;
Begin

  Font := SP_SetFPEditorFont;
  WindowID := SCREENBANK;
  SP_SetDrawingWindow(DWWindowID);

  If SP_WindowVisible(FPWindowID, Err) And (FPWindowMode in [1, 2]) Then
    SP_FPResizeWindow(DISPLAYHEIGHT - BSize * 2 - (NewH + BSize));

  DWWindowTop := DISPLAYHEIGHT - NewH - BSize;
  SP_MoveWindow(DWWindowID, DWWindowLeft, DWWindowTop, Err);
  SP_ResizeWindow(DWWindowID, NewW, NewH, -1, False, Err);
  SP_GetWindowDetails(DWWindowID, Win, Err);

  DWWindowLeft := Win^.Left;
  DWWindowTop := Win^.Top;
  DWWindowWidth := Win^.Width;
  DWWindowHeight := Win^.Height;

  DWClientWidth := DWWindowWidth - 2;
  DWClientHeight := DWWindowHeight - FPCaptionHeight - 1;
  DWClientLeft := Bsize;
  DWClientTop := FPCaptionHeight + BSize;

  DWPaperLeft := 1 + BSize;
  DWPaperTop := FPCaptionHeight + BSize;
  DWPaperWidth := DWClientWidth - (BSize * 2) - 2;
  DWPaperHeight := DWClientHeight - (BSize * 2);

  Font := SP_SetFPEditorFont;
  SP_SetSystemFont(Font, Err);

  SP_Decorate_Window(DWWindowID, 'Direct command', True, False, True);

  If Redraw Then
    SP_EditorDisplayEditLine;

  SP_SetDrawingWindow(WindowID);

End;

Procedure SP_EditorDisplayEditLine;
Var
  Idx, WorkW, WorkH, NewW, NewH, NewX, NewY, TLen, SelS, SelE: Integer;
  EditLen, X, Y, WindowID, Font: Integer;
  CText, EL_Text: aString;
  StartWithSel: Boolean;
  Err: TSP_ErrorCode;
Begin

  If DWSelP <> CURSORPOS Then Begin
    SelS := Min(DWSelP, CURSORPOS);
    SelE := Max(DWSelP, CURSORPOS);
    If DWSelP > CURSORPOS Then
      SelE := Max(1, SelE -1);
  End;

  Font := SP_SetFPEditorFont;
  WindowID := SCREENBANK;
  SCREENBANK := -1;
  SP_SetDrawingWindow(DWWindowID);

  // Get the edit line length

  Idx := 1;
  EditLen := 0;
  While Idx <= Length(EditLine) Do Begin
    If EDITLINE[Idx] >= ' ' Then Inc(EditLen);
    Inc(Idx);
  End;
  EditLen := Max(EditLen, 1);
  If CURSORPOS >= EditLen Then Inc(EditLen);

  // Figure out how much screen real estate we have to play with.

  NewX := DWWindowLeft;
  NewY := DWWindowTop;
  NewW := DWWindowWidth;
  WorkW := DWPaperWidth - DWTextLeft;
  WorkH := DWPaperHeight;

  // Extend the window downwards, and if necessary move it upwards.

  NewH := (Ceil(EditLen/(WorkW Div FPFw)) * FPFh) + FPCaptionHeight + (BSize * 2) + 1;

  If NewY + NewH > DISPLAYHEIGHT - 4 Then
    NewY := (DISPLAYHEIGHT - 4) - NewH;

  If NewH <> DWWindowHeight Then
    SP_DWResizeWindow(NewW, NewH, False);

  SP_FillRect(DWPaperLeft, DWPaperTop, DWPaperWidth, DWPaperHeight, 7);
  Y := DWPaperTop;

  If DWSelP <> CURSORPOS Then
    EL_Text := Copy(EDITLINE, 1, SelS -1) + selClr + Copy(EDITLINE, SelS, (SelE - SelS) +1) + backClr + Copy(EDITLINE, SelE +1)
  Else Begin
    EL_Text := EDITLINE;
    If EL_Text = '' Then Begin
      EL_Text := ' ';
      CURSORPOS := 1;
      DWSelP := 1;
    End;
  End;

  StartWithSel := False;
  While EL_Text <> '' Do Begin
    Idx := 1;
    TLen := DWTextWidth;
    X := DWTextLeft;
    If StartWithSel Then CText := selClr Else CText := '';
    While (TLen > 0) and (Idx <= Length(EL_Text)) Do Begin
      CText := CText + EL_Text[Idx];
      If EL_Text[Idx] = #17 Then
        StartWithSel := Not StartWithSel;
      If EL_Text[Idx] >= ' ' Then
        Dec(TLen);
      Inc(Idx);
    End;
    SP_PRINT(-1, X, Y, -1, EdSc + CText, 0 + (8 * Ord(FocusedWindow <> fwDirect)), 7, Err);
    EL_Text := Copy(EL_Text, Length(CText) - (5 * Ord((CText[1] = #17) And (EL_Text[1] <> #17))) +1);
    Inc(Y, FPFh);
  End;

  SP_DrawGraphicsID;
  SP_SetSystemFont(Font, Err);
  SP_SetDrawingWindow(WindowID);

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_HideFindResults(Clear: Boolean);
Var
  i, l: Integer;
Begin

  FPShowingFindResults := False;
  l := Length(FPFindResults);
  If l > 0 Then Begin
    For i := 0 To l -1 Do
      If (i = 0) or (FPFindResults[i].Line <> FPFindResults[i-1].Line) Then
        SP_FPApplyHighlighting(FPFindResults[i].Line);
    If Clear Then
      SetLength(FPFindResults, 0);
  End;
  SP_DisplayFPListing(-1);

End;

Procedure SP_ShowFindResults;
Var
  i, l: Integer;
  Error: TSP_ErrorCode;
Begin

  If Not FPShowingFindResults Then Begin
    FPShowingFindResults := True;
    l := Length(FPFindResults);
    If l > 0 Then Begin
      For i := 0 To l -1 Do
        If (i = 0) or (FPFindResults[i].Line <> FPFindResults[i-1].Line) Then
          SP_FPApplyHighlighting(FPFindResults[i].Line);
      SP_DisplayFPListing(-1);
    End Else Begin
      SP_FindAll(FPSearchTerm, FPSearchOptions, Error);
      If Length(FPFindResults) > 0 Then
        SP_ShowFindResults;
    End;
  End;

End;

Procedure SP_FindAll(Text: aString; Const Options: SP_SearchOptions; Var Error: TSP_ErrorCode);
Var
  e, i, j, k, l, fl, tl, rs, StartL, FinishL, StartP, FinishP: Integer;
  InString, InREM, Match: Boolean;
  Sel: SP_SelectionInfo;
  ps, pd: pByte;
  s: aString;
Begin

  // Search for and find all occurrences of "text" in the program and fill the search results array with them.

  Error.Code := SP_ERR_OK;

  If Length(FPFindResults) > 0 Then Begin
    For i := 0 to Length(FPFindResults) -1 Do Begin
      l := FPFindResults[i].Line;
      FPFindResults[i].Line := -1;
      SP_FPApplyHighlighting(l);
      AddDirtyLine(l);
    End;
    SetLength(FPFindResults, 0);
  End;

  If soExpression in Options Then Begin
    Text := SP_FPExecuteAnyExpression(Text, Error);
    If Error.Code <> SP_ERR_OK Then Exit;
  End;

  If Not (soMatchCase in Options) Then
    Text := Lower(Text);

  tl := Length(Text);

  SP_GetSelectionInfo(Sel);

  // Limit our search to either the current selection or the whole program

  If soInSelection In Options Then Begin
    StartL := Sel.StartL;
    StartP := Sel.StartP;
    FinishL := Sel.EndL;
    FinishP := Sel.EndP
  End Else Begin
    StartL := 0;
    StartP := 1;
    FinishL := Listing.Count -1;
    FinishP := Length(Listing[Listing.Count -1]);
  End;

  // Now determine the initial state of InString and InREM.
  // Start by stepping back to the actual start of the BASIC line.

  i := StartL;
  While (i > 0) And Not SP_LineHasNumber_Fast(i) Do
    Dec(i);

  InString := False;
  InREM := False;

  j := i; k := 1;
  s := Listing[j]; l := Length(s);
  If j < Listing.Count -1 Then
    s := s + Listing[j +1];
  While (j <= StartL) And (k <= StartP) Do Begin
    If (j = StartL) And (k >= StartP) Then Break;
    If Lower(Copy(s, k, 3)) = 'rem ' Then
      InREM := True;
    If s[k] = '"' Then
      InString := Not InString;
    Inc(k);
    If k > l Then Begin
      Inc(j);
      k := 1;
      s := Listing[j]; l := Length(s);
      If j < Listing.Count -1 Then
        s := s + Listing[j +1];
    End;
  End;

  rs := 1;
  For i := StartL To FinishL Do Begin
    s := Listing[i];
    l := Length(s);
    If i < Listing.Count -1 Then
      s := s + Listing[i +1];
    If Not (soMatchCase in Options) Then
      s := Lower(s);
    If i = StartL Then
      k := StartP
    Else
      k := rs;
    If i = FinishL Then
      e := FinishP
    Else
      e := l;
    rs := 1;
    ps := pByte(pNativeUInt(@s)^);
    Inc(ps, k -1);
    pd := pByte(pNativeUInt(@Text)^);
    While k <= e Do Begin
      If SP_PartialMatchPtrs(ps, pd, tl) Then Begin
        Match := True;
        If (soInREM in Options) Then Match := Match And InREM;
        If (soInString in Options) Then Match := Match And InString;
        If (soWholeWords in Options) Then Match := Match And ((k = 1) or Not (s[k -1] in ['a'..'z', 'A'..'Z', '0'..'9'])) And ((k = l) or Not (s[k +1] in ['a'..'z', 'A'..'Z', '0'..'9']));
        If Match Then Begin
          fl := Length(FPFindResults);
          SetLength(FPFindResults, fl +1);
          FPFindResults[fl].Line := i;
          FPFindResults[fl].Position := k;
          If k + tl -1 > e Then Begin
            FPFindResults[fl].Length := (e - k) + 1;
            FPFindResults[fl].Split := True;
            Inc(fl);
            SetLength(FPFindResults, fl +1);
            FPFindResults[fl].Line := i +1;
            FPFindResults[fl].Position := 1;
            FPFindResults[fl].Length := tl - ((e - k) +1);
            rs := FPFindResults[fl].Length + 1;
            Break;
          End Else Begin
            FPFindResults[fl].Length := tl;
            FPFindResults[fl].Split := False;
          End;
          Inc(k, tl);
          Inc(ps, tl);
        End Else Begin
          Inc(l);
          Inc(ps);
        End;
      End Else Begin
        Inc(k);
        Inc(ps);
      End;
      If k <= e Then Begin
        If s[k] = '"' Then
          InString := Not InString;
        If Lower(Copy(s, k, 4)) = 'rem ' Then
          InREM := True;
      End;
    End;
    InREM := False;
    InString := False;
  End;

End;

Function SP_FindText(Text: aString; StartAtL, StartAtP: Integer; Const Options: SP_SearchOptions): TPoint;
Var
  Origin, Limit, Dir, Idx, fp, fp2, cIdx, Cnt: Integer;
  Sel: SP_SelectionInfo;
  Error: TSP_ErrorCode;
  s, s2: aString;
  Done: Boolean;
Begin

  // SP_SearchOptions = Set Of (soForward, soBackwards, soInREM, soInString, soMatchCase, soLoop, soInSelection, soWholeWords, soExpression);
  // Finds a given text, with options. soCondenseSpaces and soWholeWords cannot be used together.

  If soExpression in Options Then Begin
    Text := SP_FPExecuteAnyExpression(Text, Error);
    If Error.Code <> SP_ERR_OK Then Begin
      Result := Point(-2, -2);
      Exit;
    End;
  End;

  SP_GetSelectionInfo(Sel);

  If Not (soMatchCase in Options) Then
    Text := Lower(Text);

  Result := Point(-1, -1);
  Origin := StartAtL;
  Idx := StartAtL;
  Done := False;

  If soBackwards in Options Then Begin
    Dir := -1;
    Limit := -1;
  End Else Begin
    Dir := 1;
    Limit := Listing.Count;
  End;

  If soCondenseSpaces in Options Then
    Text := StripSpaces(Text);

  While Not Done Do Begin

    If Idx = Limit Then
      If soLoop in Options Then Begin
        If soBackwards in Options Then
          Idx := Listing.Count -1
        Else
          Idx := 0;
      End Else
        If fp2 = 0 Then
          Exit
        Else
          Done := True;

    If soInEditLine in Options Then
      s := EDITLINE
    Else
      Begin
        s := Listing[Idx];
        If soBackwards in Options Then Begin
          If (Idx > 0) And (Listing.Flags[Idx -1].ReturnType = spSoftReturn) Then
            s := Copy(Listing[Idx -1], (Length(Listing[Idx -1]) - Length(Text)) +1) + s;
        End Else
          If Listing.Flags[Idx].ReturnType = spSoftReturn Then
            s := s + Copy(Listing[Idx +1], 1, Length(Text));
      End;

    If Not (soMatchCase in Options) Then
      s := Lower(s);
    If soCondenseSpaces in Options Then
      s := StripSpaces(s);

    fp := Pos(Text, s);
    If fp > 0 Then Begin
      If Not (soInEditLine in Options) Then Begin
        If soBackwards in Options Then
          Done := (Idx <> StartAtL) or ((Idx = StartAtL) And (fp < StartAtP))
        Else
          Done := (Idx <> StartAtL) or ((Idx = StartAtL) And (fp > StartAtP));
        If Not Done Then Break;
        If soInSelection in Options Then Begin
          Done := ((Idx > Sel.StartL) And (Idx < Sel.EndL)) or ((fp >= Sel.StartP) And (Idx = Sel.StartL)) or ((fp <= Sel.EndP) And (Idx = Sel.EndL));
          If Not Done Then Break;
        End;
      End;
      fp2 := fp;
      If Not ((soInREM In Options) or (soInString in Options)) Then Begin
        If soInEditLine in Options Then
          s2 := EDITLINE
        Else Begin
          cIdx := Idx;
          While (cIdx >= 0) And (SP_LineHasNumber(cIdx) = 0) Do
            Dec(cIdx);
          s2 := Listing[cIdx];
          Inc(cIdx);
          While (cIdx < Listing.Count) And (SP_LineHasNumber(cIdx) = 0) Do Begin
            s2 := s2 + Listing[cIdx];
            If cIdx < Idx Then Inc(fp2, Length(Listing[cIdx]));
            Inc(cIdx);
          End;
        End;
        cIdx := 1;
        Cnt := 0;
        While cIdx <= fp2 Do Begin
          While s2[cIdx] <= ' ' Do Begin
            Inc(fp2);
            Inc(cIdx);
          End;
          If (Copy(s2, cIdx, 3) = 'REM') And (Not Odd(Cnt)) Then Begin
            Done := soInREM in Options;
            If Not Done Then Break;
          End;
          If s2[cIdx] = '"' Then
            Inc(Cnt);
          Inc(cIdx);
        End;
        If Done And (soWholeWords in Options) Then
          Done := Done And ((fp2 = 1) or (Not (s[fp2 -1] in ['A'..'Z', 'a'..'z', '0'..'9'])) And ((fp2 + Length(Text) -1 = Length(s)) or (Not (s[fp2 +1] in ['A'..'Z', 'a'..'z', '0'..'9']))));
        Done := Done And ((Odd(Cnt) And (Not (soInString in Options))) or Not Odd(Cnt));
      End Else Begin
        // Re-synchronise if we lost spaces.
        cIdx := 1;
        Cnt := 0;
        While cIdx <= fp2 Do Begin
          While s2[cIdx] <= ' ' Do Begin
            Inc(fp2);
            Inc(cIdx);
          End;
          Inc(cIdx);
        End;
      End;
    End;

    Inc(Idx, Dir);
    If (Idx = Origin) or (soInEditLine in Options) Then Break;

  End;

  If soInEditLine in Options Then
    Result := Point(fp2, 0)
  Else
    If Done Then
      Result := Point(fp2, Max(0, Idx - Dir));

End;

Function SP_FindLineNum(LineNum: Integer): Integer;
Var
  Idx, n, d, di: Integer;
Begin

  Result := 1;
  d := 99999999;
  di := -1;
  For Idx := 0 To Listing.Count -1 Do Begin
    If SP_LineHasNumber(Idx) > 0 Then Begin
      n := SP_GetLineNumberFromText(Listing[Idx]);
      If n >= LineNum Then Begin
        if n - LineNum < d Then Begin
          d := n - LineNum;
          di := Idx;
        end;
      End;
    End;
  End;
  Result := di;

End;

Procedure SP_FPBringToEditor(LineNum, Statement: Integer; Var Error: TSP_ErrorCode; DoEdit: Boolean = True);
Var
  Idx, St, cPos: Integer;
  uLabel: aString;
  tLabel: TSP_Label;
  Found, lFound: TPoint;
  LabelSearch: Boolean;
  searchOpt: SP_SearchOptions;
Begin

  // Brings a line into the editor. If linenum and statement are zero, then inspect the
  // edit line - a number (10, say) will bring that line to the editor. Optionally specifying
  // a statement number (10:3) will bring that line in, and move the cursor to the statement.
  // if the first non-whitespace character is @, then get a label name and find its first declared
  // usage and bring that in.

  // If linenum (and optionally Statement) are non-zero then get that line and bring it into
  // editline.

  cPos := -1;
  LabelSearch := False;
  lFound := Point(0, 0);
  If (LineNum = 0) And (Statement = 0) Then Begin
    If EDITLINE <> '' Then Begin
      Idx := CURSORPOS;
      While Idx > Length(EDITLINE) Do Dec(Idx);
      While (Idx > 1) And (EDITLINE[Idx] <= ' ') Do Dec(Idx);
      While (Idx > 1) And (EDITLINE[Idx] in ['0'..'9', 'A'..'Z', 'a'..'z', '_', ':']) Do Dec(Idx);
      If Not (EDITLINE[Idx] in ['0'..'9', 'A'..'Z', 'a'..'z', '@']) And (Idx < Length(EDITLINE)) Then Inc(Idx);
      If EDITLINE[Idx] = '@' Then Begin
        // Label search
        Inc(Idx);
        uLabel := '@';
        LabelSearch := True;
        While (Idx <= Length(EDITLINE)) And (EDITLINE[Idx] in ['0'..'9', 'A'..'Z', 'a'..'z', '_']) Do Begin
          uLabel := uLabel + EDITLINE[Idx];
          Inc(Idx);
        End;
        searchOpt := [soForward, soCondenseSpaces];
        Found := SP_FindText('LABEL '+uLabel, 0, 1, searchOpt);
        If Found.y >= 0 Then Begin
          Listing.FPCLine := Found.y;
          Listing.FPCPos := Found.x;
          Listing.FPSelLine := Listing.FPCLine;
          Listing.FPSelPos := Listing.FPCPos;
          FPCDes := Listing.FPCPos;
          FPCDesLine := Listing.FPCLine;
          SP_CursorPosChanged;
          PROGLINE := SP_GetLineNumberFromText(EDITLINE);
          LineNum := Found.y;
          If SYSTEMSTATE <> SS_ERROR Then Begin
            SP_DisplayFPListing(-1);
            SP_CalculateFPCursorPos;
            SP_ScrollInView;
          End;
        End Else Begin
          EDITERRORPOS := CURSORPOS;
          EDITERROR := True;
          SP_PlaySystem(ERRORCHAN, ERRSNDBANK);
          Exit;
        End;
      End Else Begin
        // Line number (optional statement after ":") search
        Idx := 1;
        LineNum := 0;
        Statement := 0;
        While (Idx <= Length(EDITLINE)) And (EDITLINE[Idx] in ['0'..'9']) Do Begin
          LineNum := (LineNum * 10) + Ord(EDITLINE[Idx]) - 48;
          Inc(Idx);
        End;
        SP_SkipSpaces(EDITLINE, Idx);
        If EDITLINE[Idx] = ':' Then Begin
          Inc(Idx);
          SP_SkipSpaces(EDITLINE, Idx);
          While (Idx <= Length(EDITLINE)) and (EDITLINE[Idx] in ['0'..'9']) Do Begin
            Statement := (Statement * 10) + Ord(EDITLINE[Idx]) - 48;
            Inc(Idx);
          End;
        End;
        If Idx > Length(EDITLINE) Then Begin
          If Statement = 0 Then Inc(Statement);
          LineNum := SP_FindLineNum(LineNum);
        End Else Begin
          LineNum := SP_FindLineNum(PROGLINE);
          Statement := 1;
        End;
      End;
    End Else Begin
      // Empty edit line, pull in the currently highlighted line.
      LineNum := SP_FindLineNum(PROGLINE);
      Statement := 1;
    End;
  End Else Begin
    Linenum := SP_FindLineNum(LineNum);
  End;
  // Set the current edit line into the history. At this point,
  // Linenum is the INDEX of the line we want to pull, and st is the statement number. CURSORPOS may
  // also be set.
  If DoEdit and (StripSpaces(EDITLINE) <> '') Then
    If HistoryPos = Length(EditorHistory) Then Begin
      SetLength(EditorHistory, Length(EditorHistory) +1);
      EditorHistory[Length(EditorHistory) -1] := EDITLINE;
    End;
  If LineNum >= 0 Then Begin
    If Statement = 0 Then Inc(Statement);
    St := Statement;
    DWStoreEditorState;
    PROGLINE := SP_GetLineNumberFromText(Listing[LineNum]);
    If DoEdit Then Begin
      EDITLINE := SP_DeTokenise(SP_TokeniseLine(SP_GetLineTextFromNumber(PROGLINE), False, True), CPos, False, False);
      If LabelSearch Then Begin
        searchOpt := [soForward, soCondenseSpaces, soInEditLine];
        lFound := SP_FindText('LABEL '+uLabel, 0, 1, searchOpt);
      End;
      If lFound.X > 0 Then Begin
        CURSORPOS := lFound.X
      End Else
        If Statement > 1 Then Begin
          Idx := CURSORPOS;
          While (Idx <= Length(EDITLINE)) Do Begin
            If EDITLINE[Idx] = ':' Then Begin
              Dec(Statement);
              If Statement = 1 Then Break;
            End;
            Inc(Idx);
          End;
          If Idx < Length(EDITLINE) Then Begin
            Inc(Idx);
            While (Idx < Length(EDITLINE)) And (EDITLINE[Idx] <= ' ') Do
              Inc(Idx);
            CURSORPOS := Idx;
          End;
        End Else Begin
          Statement := 1;
          CURSORPOS := 1;
          While (CURSORPOS <= Length(EDITLINE)) And ((EDITLINE[CURSORPOS] in ['0'..'9']) Or (EDITLINE[CURSORPOS] <= ' ')) Do
            Inc(CURSORPOS);
        End;
    End;
    Found := SP_FindFPLineStatement(SP_GetLineNumberFromText(Listing[LineNum]), St);
    Listing.FPCLine := Found.X;
    Listing.FPCPos := Found.Y;
    While Listing[Listing.FPCLine][Listing.FPCPos] <= ' ' Do Listing.FPCPos := Listing.FPCPos +1;
    Listing.FPSelLine := Listing.FPCLine;
    Listing.FPSelPos := Listing.FPCPos;
    FPCDes := Listing.FPCPos;
    FPCDesLine := Listing.FPCLine;
    SP_CursorPosChanged;
    If FPWindowID >= 0 Then Begin
      SP_DisplayFPListing(-1);
      SP_CalculateFPCursorPos;
      SP_ScrollInView;
    End;
    If DoEdit Then Begin
      DWSelP := CURSORPOS;
      If DWWindowID >= 0 Then
        SP_EditorDisplayEditLine;
    End;
  End;
End;

Procedure SP_DWPerformEdit(Char: Byte);
Var
  NewChar: Byte;
  LineIdx, Idx, Cnt, LineNum, Statement, SelS, SelE, GfxMode, c: Integer;
  Sel: SP_SelectionInfo;
  Error: TSP_ErrorCode;
  SB: pSP_ScrollBar;
  s: aString;

  Procedure PlayClick;
  Begin
    If LASTKEYFLAG And KF_NOCLICK = 0 Then SP_PlaySystem(CLICKCHAN, CLICKBANK);
  End;

Begin

  // Direct command window. It's easier to have a clone of the editor's handler as there are so
  // many differences in how the keyboard is handled. Not that you'd know it by using it.

  // Test for control keys, then convert to ASCII using the
  // KEYBOARDSTATE sysvar.

  Error.Code := SP_ERR_OK;
  If DWSelP <> CURSORPOS Then Begin
    SelS := Min(DWSelP, CURSORPOS);
    SelE := Max(DWSelP, CURSORPOS);
  End;

  GfxMode := GFXLOCK;
  If ((KEYSTATE[K_CONTROL] = 1) And (KEYSTATE[K_ALT] = 1)) or (KEYSTATE[K_ALTGR] = 1) Then Begin
    GfxMode := 1 - GfxMode;
    If Char >= 32 Then
      If CharStr[Char] <> '' Then
        LASTKEYCHAR := Ord(CharStr[Char][KEYSTATE[K_SHIFT] + 1]);
  End;

  K_DOWNFLAG := False;
  NewChar := SP_DecodeKey(Char, False);
  {$IFDEF DARWIN}
  If ((NewChar = 97) And (Char = 40)) Or    // cmd+up
     ((NewChar = 109) And (Char = 13)) Or   // cmd+Enter
     ((NewChar = 98) And (Char = 37)) Or    // cmd+right
     ((NewChar = 56) And (Char = 8)) Or     // cmd+backspace
     ((NewChar = 99) And (Char = 39)) And   // cmd+left
     (KEYSTATE[K_CONTROL] = 1) Then
     NewChar := 0;
  If ((NewChar = 77) And (Char = 13)) Or    // Shift+Enter
     ((NewChar = 40) And (Char = 46)) Or    // Fn+Backspace
     ((NewChar = 44) And (Char = 33)) Or    // PgUp
     ((NewChar = 45) And (Char = 34)) Or    // PgDn
     ((NewChar = 41) And (Char = 36)) Or    // Home
     ((NewChar = 43) And (Char = 35)) Then  // End
     NewChar := 0;
  If (NewChar = 0) And (Char = 81) Then
    NewChar := 113;
  If (NewChar = 0) And (Char in [65..90]) Then
    NewChar := Char;
  {$ENDIF}

  {$IFDEF SPECCYKEYS}
  If (Char = K_1) And (KEYSTATE[K_SHIFT] = 1) Then Begin
    Char := K_TAB;
    NewChar := 0;
  End;
  {$ENDIF}

  If (aChar(NewChar) in ['a'..'z', 'A'..'Z', '0'..'9']) And Not DWUndoInProgress Then
    DWCommenceUndo;

  If (NewChar = 0) {$IFNDEF FPC} And (LASTKEYCHAR <> 1) {$ENDIF} Then Begin

    DWCompleteUndo;
    DWCommenceUndo;

    Case Char of

      K_F1..K_F10:
        Begin // F1 to F9 set markers (CTRL+Shift) and jump to markers (CTRL)
          {$IFNDEF DARWIN}
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            If KEYSTATE[K_SHIFT] = 1 Then Begin
              SP_ToggleEditorMark(Char - K_F1);
            End Else Begin
              SP_JumpToMark(Char - K_1);
              Idx := Listing.FPCLine;
              While (Idx >= 0) And (SP_GetLineNumberFromText(Listing[Idx]) <= 0) Do Dec(Idx);
              PROGLINE := SP_GetLineNumberFromText(Listing[Idx]);
              If PROGLINE <= 0 Then Begin
                While (Idx < Listing.Count) And (SP_GetLineNumberFromText(Listing[Idx]) <= 0) Do Inc(Idx);
                PROGLINE := SP_GetLineNumberFromText(Listing[Idx]);
              End;
              SP_CalculateFPCursorPos;
              SP_CursorPosChanged;
              SP_ScrollInView;
              SP_FPClearSelection(Sel);
            End;
            SP_DisplayFPListing(-1);
          End Else
          {$ENDIF}
            Case Char of
              K_F1:
                Begin
                  // Help
                End;
              K_F3:
                Begin
                  // Repeat find/replace
                  FindNext(True);
                End;
              K_F4:
                Begin
                  // RUN to current line/statement, SHIFT to CONTINUE
                  If SP_CheckProgram Then Begin
                    SP_ToggleBreakPoint(True);
                    Listing.CompleteUndo;
                    s := EDITLINE;
                    If KEYSTATE[K_SHIFT] = 0 Then
                      EDITLINE := 'RUN'
                    Else
                      EDITLINE := 'CONTINUE';
                    SP_FPExecuteEditLine(EDITLINE);
                    EDITLINE := s;
                    SP_EditorDisplayEditLine;
                    SP_SwitchFocus(fwDirect);
                  End Else
                    SP_ShowError(SP_ERR_SYNTAX_ERROR, Listing.FPCLine, Listing.FPCPos);
                End;
              K_F5:
                Begin
                  // Add a breakpoint at PROGLINE:1
                  SP_ToggleBreakPoint(False);
                End;
              K_F7:
                Begin
                  // Single step
                  If SP_CheckProgram Then
                    SP_SingleStep
                  Else
                    SP_ShowError(SP_ERR_SYNTAX_ERROR, Listing.FPCLine, Listing.FPCPos);
                  Exit;
                End;
              K_F8:
                Begin
                  // Step Over
                  If SP_CheckProgram Then
                    If SP_StepOver Then Begin
                      Listing.CompleteUndo;
                      s := EDITLINE;
                      EDITLINE := 'CONTINUE';
                      SP_FPExecuteEditLine(EDITLINE);
                      EDITLINE := s;
                      SCREENLOCK := False;
                      SP_EditorDisplayEditLine;
                      SP_SwitchFocus(fwDirect);
                      SP_ClearKeyBuffer(True);
                    End Else
                      SP_ShowError(SP_ERR_STATEMENT_LOST, Listing.FPCLine, Listing.FPCPos);
                  Exit;
                End;
              K_F9:
                Begin
                  // RUN (Shift = CONTINUE)
                  If SP_CheckProgram Then Begin
                    Listing.CompleteUndo;
                    s := EDITLINE;
                    If KEYSTATE[K_SHIFT] = 0 Then
                      EDITLINE := 'RUN'
                    Else
                      EDITLINE := 'CONTINUE';
                    SP_FPExecuteEditLine(EDITLINE);
                    EDITLINE := s;
                    SP_EditorDisplayEditLine;
                    SP_SwitchFocus(fwDirect);
                  End Else
                    SP_ShowError(SP_ERR_SYNTAX_ERROR, Listing.FPCLine, Listing.FPCPos);
                End;
              K_F10:
                Begin
                  // RUN (Shift = GO TO) current line
                  If SP_CheckProgram Then Begin
                    Listing.CompleteUndo;
                    c := CURSORPOS;
                    If PROGLINE > 0 Then Begin
                      s := EDITLINE;
                      If KEYSTATE[K_SHIFT] = 0 Then
                        EDITLINE := 'RUN ' + IntToString(PROGLINE)
                      Else
                        EDITLINE := 'GO TO ' + IntToString(PROGLINE);
                      SP_FPExecuteEditLine(EDITLINE);
                      EDITLINE := s;
                      CURSORPOS := c;
                      SP_EditorDisplayEditLine;
                      SP_SwitchFocus(fwDirect);
                    End Else
                      SP_ShowError(SP_ERR_SYNTAX_ERROR, Listing.FPCLine, Listing.FPCPos);
                  End;
                End;
          End;
          PlayClick;
        End;


      K_RETURN:
        Begin
          PlayClick;
          If KEYSTATE[K_CONTROL] = 0 Then Begin
            If EDITLINE = '' Then Begin
              // Hide or show the editor
              If FPWindowMode = 0 Then
                FPWindowMode := 3
              Else
                FPWindowMode := 2;
              SP_FPCycleEditorWindows(-1);
            End Else Begin
              // Do the magic here
              SP_FPExecuteEditLine(EDITLINE);
              Exit;
            End;
          End Else Begin
            // Ctrl-Enter will cycle editor windows.
            If KEYSTATE[K_SHIFT] = 0 Then
              SP_FPCycleEditorWindows(-1)
            Else
              Begin
                SP_FPCycleEditorWindows(1);
                SYSTEMSTATE := ss_IDLE;
                LASTKEY := 0;
                Repeat
                  CB_YIELD;
                  If K_UPFLAG Then Begin
                    LASTKEY := 0;
                    K_UPFLAG := False;
                  End;
                Until Not (LASTKEY in [0, K_SHIFT]) or K_DOWNFLAG or M_DOWNFLAG;
                LASTKEY := 0;
                SYSTEMSTATE := ss_EDITOR;
                SP_FPCycleEditorWindows(2);
              End;
          End;
        End;

      K_ALT, K_ALTGR:
        Begin
          If KEYSTATE[K_SHIFT] = 1 Then Begin
            GFXLOCK := 1-GFXLOCK;
            PlayClick;
          End;
        End;

      K_TAB:
        Begin
          // Bring the current PROGLINE down into the editline
          SP_FPBringToEditor(0, 0, Error);
          If Error.Code <> SP_ERR_OK Then Begin
            CURSORPOS := 1;
            DWSelP := 1;
            CURSORFG := 15;
            CURSORBG := 10;
            Exit;
          End;
          PlayClick;
          DWSelP := CURSORPOS;
        End;

      K_LEFT:
        Begin
          If CURSORPOS > 1 Then
            If KEYSTATE[K_CONTROL] = 1 Then Begin
              If EDITLINE <> '' Then Begin
                If EDITLINE[CURSORPOS -1] in Seps Then Dec(CURSORPOS);
                While (CURSORPOS > 1) And ((CURSORPOS > Length(EDITLINE)) or (EDITLINE[CURSORPOS] in Seps)) Do Dec(CURSORPOS);
                While (CURSORPOS > 1) and (Not (EDITLINE[CURSORPOS] in Seps)) Do Dec(CURSORPOS);
                If CURSORPOS > 1 Then
                  Inc(CURSORPOS);
              End;
            End Else Begin
              Dec(CURSORPOS);
            End;
          If KEYSTATE[K_SHIFT] = 0 Then
            DWSelP := CURSORPOS;
          PlayClick;
        End;

      K_RIGHT:
        Begin
          If CURSORPOS <= Length(EDITLINE) Then
            If KEYSTATE[K_CONTROL] = 1 Then Begin
              While (CURSORPOS < Length(EDITLINE)+1) and (EDITLINE[CURSORPOS] in Seps) Do Inc(CURSORPOS);
              While (CURSORPOS < Length(EDITLINE)+1) and (Not (EDITLINE[CURSORPOS] in Seps)) Do Inc(CURSORPOS);
              If (CURSORPOS < Length(EDITLINE)) and (EDITLINE[CURSORPOS] in Seps) Then Inc(CURSORPOS);
            End Else Begin
              Inc(CURSORPOS);
            End;
          If KEYSTATE[K_SHIFT] = 0 Then
            DWSelP := CURSORPOS;
          PlayClick;
        End;

      K_UP:
        Begin
          If KEYSTATE[K_CONTROL] = 0 Then Begin
            Cnt := (DWWindowWidth - (10+FPFw) - FPFh - Max(FPFw Div 2, FPFh Div 2)) Div FPFw;
            While (Cnt > -1) And (CURSORPOS > 1) Do Begin
              Dec(CURSORPOS);
              Dec(Cnt);
            End;
            If KEYSTATE[K_SHIFT] = 0 Then
              DWSelP := CURSORPOS;
          End Else Begin
            If KEYSTATE[K_SHIFT] = 1 Then Begin
              If Length(EditorHistory) > 0 Then Begin
                If HistoryPos = Length(EditorHistory) Then Begin
                  SetLength(EditorHistory, Length(EditorHistory) +1);
                  EditorHistory[Length(EditorHistory) -1] := EDITLINE;
                End;
                If HistoryPos > 0 Then Begin
                  Dec(HistoryPos);
                  DWStoreEditorState;
                  EDITLINE := EditorHistory[HistoryPos];
                  CURSORPOS := Length(EDITLINE)+1;
                  DWSelP := CURSORPOS;
                  SP_EditorDisplayEditLine;
                End;
              End;
            End Else Begin
              Idx := Max(SP_FindFPLine(PROGLINE), 0);
              While Idx > 0 Do Begin
                Dec(Idx);
                If (SP_GetFPLineNumber(Idx) > 0) And Not SP_WasPrevSoft(Idx) Then Break;
              End;
              LineNum := SP_GetFPLineNumber(Idx);
              If LineNum > 0 Then Begin
                PROGLINE := LineNum;
                Listing.FPCLine := Idx;
                Listing.FPSelLine := Idx;
                Listing.FPCPos := SP_LineHasNumber(Idx) +1;
                Listing.FPSelPos := Listing.FPCPos;
                FPCDesLine := Idx;
                FPCDes := Listing.FPCPos;
                SP_DisplayFPListing(-1);
                SP_CalculateFPCursorPos;
                SP_ScrollInView;
              End;
            End;
          End;
          PlayClick;
        End;

      K_DOWN:
        Begin
          If KEYSTATE[K_CONTROL] = 0 Then Begin
            Cnt := (DWWindowWidth - (10+FPFw) - FPFh - Max(FPFw Div 2, FPFh Div 2)) Div FPFw;
            While (Cnt > -1) And (CURSORPOS < Length(EDITLINE)+1) Do Begin
              Inc(CURSORPOS);
              Dec(Cnt);
            End;
            If KEYSTATE[K_SHIFT] = 0 Then
              DWSelP := CURSORPOS;
          End Else Begin
            If KEYSTATE[K_SHIFT] = 1 Then Begin
              If Length(EditorHistory) > 0 Then Begin
                If HistoryPos < Length(EditorHistory) -1 Then Begin
                  Inc(HistoryPos);
                  DWStoreEditorState;
                  EDITLINE := EditorHistory[HistoryPos];
                  CURSORPOS := Length(EDITLINE)+1;
                  DWSelP := CURSORPOS;
                  SP_EditorDisplayEditLine;
                  If HistoryPos = Length(EditorHistory) -1 Then
                    SetLength(EditorHistory, Length(EditorHistory) -1);
                End;
              End;
            End Else Begin
              Idx := Max(0, SP_FindFPLine(PROGLINE));
              While Idx < Listing.Count -1 Do Begin
                Inc(Idx);
                If (SP_GetFPLineNumber(Idx) > 0) And Not SP_WasPrevSoft(Idx) Then Break;
              End;
              If Idx < Listing.Count Then Begin
                LineNum := SP_GetFPLineNumber(Idx);
                If LineNum > 0 Then Begin
                  PROGLINE := LineNum;
                  Listing.FPCLine := Idx;
                  Listing.FPSelLine := Idx;
                  Listing.FPCPos := SP_LineHasNumber(Idx) +1;
                  Listing.FPSelPos := Listing.FPCPos;
                  FPCDesLine := Idx;
                  FPCDes := Listing.FPCPos;
                  SP_DisplayFPListing(-1);
                  SP_CalculateFPCursorPos;
                  SP_CursorPosChanged;
                  SP_ScrollInView;
                End;
              End;
            End;
          End;
          PlayClick;
        End;

      K_HOME:
        Begin
          If KEYSTATE[K_CONTROL] = 1 Then
            CURSORPOS := 1
          Else
            Dec(CURSORPOS, (CURSORX -2) Div FPFw);
          If CURSORPOS < 1 Then
            CURSORPOS := 1;
          If KEYSTATE[K_SHIFT] = 0 Then
            DWSelP := CURSORPOS;
          PlayClick;
        End;

      K_END:
        Begin
          If KEYSTATE[K_CONTROL] = 1 Then
            CURSORPOS := Length(EDITLINE)+1
          Else Begin
            Cnt := CURSORX;
            Idx := CURSORPOS;
            While Cnt < DWWindowWidth -18 Do Begin
              If Idx <= Length(EDITLINE) Then Begin
                If EDITLINE[Idx] >= ' ' Then Begin
                  Inc(Idx);
                  Inc(Cnt, FPFw);
                End Else
                  Inc(Idx);
              End Else Begin
                Inc(Idx, 2);
                Break;
              End;
            End;
            CURSORPOS := Idx -2;
            If CURSORPOS > Length(EDITLINE) Then
              CURSORPOS := Length(EDITLINE)+1;
          End;
          If KEYSTATE[K_SHIFT] = 0 Then
            DWSelP := CURSORPOS;
          PlayClick;
        End;

      K_PRIOR:
        Begin
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            SB := @FPScrollBars[SP_FindScrollBar(FPVertSc)];
            Idx := Max(Trunc(SB^.Position/FPFh) - 1, 0);
            PROGLINE := SP_GetLineNumberFromIndex(Idx);
            SP_DisplayFPListing(-1);
            SP_ScrollInView;
          End;
          PlayClick;
        End;

      K_NEXT:
        Begin
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            SB := @FPScrollBars[SP_FindScrollBar(FPVertSc)];
            Idx := Min(Trunc(SB^.Position/FPFh) + Trunc(SB^.PageSize/FPFh), Listing.Count -1);
            PROGLINE := SP_GetLineNumberFromIndex(Idx);
            SP_DisplayFPListing(-1);
            SP_ScrollInView;
          End;
          PlayClick;
        End;

      K_BACK:
        Begin
          If KEYSTATE[K_CONTROL] = 1 Then Begin
            DWCommenceUndo;
            SP_DeleteWord(True);
            DWCompleteUndo;
          End Else
            If DWSelP <> CURSORPOS Then Begin
              DWCommenceUndo;
              SP_FPDeleteSelection(Sel);
              DWCompleteUndo;
            End Else
              If CURSORPOS > 1 Then Begin
                If Not DWUndoInProgress Then DWCommenceUndo;
                DWStoreEditorState;
                EDITLINE := Copy(EDITLINE, 1, CURSORPOS -2) + Copy(EDITLINE, CURSORPOS, Length(EDITLINE));
                Dec(CURSORPOS);
              End;
          DWSelP := CURSORPOS;
          PlayClick;
        End;

      K_DELETE:
        Begin
          If EDITLINE <> '' Then Begin
            If KEYSTATE[K_CONTROL] = 1 Then Begin
              DWCommenceUndo;
              SP_DeleteWord(False);
              DWCompleteUndo;
            End Else
              If DWSelP <> CURSORPOS Then Begin
                DWCommenceUndo;
                SP_FPDeleteSelection(Sel);
                DWCompleteUndo;
              End Else
                If CURSORPOS <= Length(EDITLINE) Then Begin
                  If Not DWUndoInProgress Then DWCommenceUndo;
                  DWStoreEditorState;
                  EDITLINE := Copy(EDITLINE, 1, CURSORPOS -1) + Copy(EDITLINE, CURSORPOS +1, Length(EDITLINE));
                End;
          End;
          DWSelP := CURSORPOS;
          PlayClick;
        End;

      K_INSERT:
        Begin
          INSERT := Not INSERT;
          PlayClick;
        End;

      K_ESCAPE:
        Begin
          // Switch? Clear the edit line? I dunno yet.
          If EDITLINE <> '' Then Begin
            DWStoreEditorState;
            EDITLINE := ''
          End Else
            SP_SwitchFocus(fwEditor);
          PlayClick;
        End;

    End;

    If (CURSORPOS <= 0) or (CURSORPOS > Length(EDITLINE)) Then
      CURSORCHAR := 32
    Else
      CURSORCHAR := Ord(EDITLINE[CURSORPOS]);

  End Else Begin
    PlayClick;
    {$IFDEF DARWIN}
    If (NewChar in [65..90]) And (((KEYSTATE[K_SHIFT] = 0) And (CAPSLOCK = 0)) or ((KEYSTATE[K_SHIFT] = 1) And (CAPSLOCK = 1))) Then Begin
      NewChar := NewChar + 32;
    End;
    {$ENDIF}
    If (KEYSTATE[K_CONTROL] = 0) Or (GfxMode = 1) Then Begin
      If (DWSelP <> CURSORPOS) or Not (aChar(NewChar) in ['a'..'z', 'A'..'Z', '0'..'9']) or Not DWUndoInProgress Then DWCommenceUndo;
      If DWSelP <> CURSORPOS Then Begin
        SP_FPDeleteSelection(Sel);
        DWCompleteUndo;
        DWCommenceUndo;
      End;
      DWStoreEditorState;
      If INSERT Then
        If GfxMode = 1 Then
          EDITLINE := Copy(EDITLINE, 1, CURSORPOS -1) + aChar(Byte(NewChar)+128) + Copy(EDITLINE, CURSORPOS, Length(EDITLINE))
        Else
          EDITLINE := Copy(EDITLINE, 1, CURSORPOS -1) + aChar(NewChar) + Copy(EDITLINE, CURSORPOS, Length(EDITLINE))
      Else Begin
        If GfxMode = 1 Then
          EDITLINE := Copy(EDITLINE, 1, CURSORPOS -1) + aChar(Byte(NewChar)+128) + Copy(EDITLINE, CURSORPOS +1, LENGTH(EDITLINE))
        Else
          EDITLINE := Copy(EDITLINE, 1, CURSORPOS -1) + aChar(NewChar) + Copy(EDITLINE, CURSORPOS +1, LENGTH(EDITLINE));
      End;
      Inc(CURSORPOS);
      DWSelP := CURSORPOS;
    End Else Begin
      Case Lower(aChar(NewChar))[1] of
        {$IFDEF DARWIN}
        '1'..'9':
          Begin
            Key := StrToInt(NewChar[1]);
            If KEYSTATE[K_SHIFT] = 1 Then Begin
              SP_ToggleEditorMark(Key - 1);
            End Else Begin
              SP_JumpToMark(Key - 1);
              Idx := Listing.FPCLine;
              While (Idx >= 0) And (SP_GetLineNumberFromText(Listing[Idx]) <= 0) Do Dec(Idx);
              PROGLINE := SP_GetLineNumberFromText(Listing[Idx]);
              If PROGLINE <= 0 Then Begin
                While (Idx < Listing.Count) And (SP_GetLineNumberFromText(Listing[Idx]) <= 0) Do Inc(Idx);
                PROGLINE := SP_GetLineNumberFromText(Listing[Idx]);
              End;
              SP_CalculateFPCursorPos;
            End;
            SP_FPClearSelection(Sel);
          End;
        'q':
            Begin
              // Quit
              TerminateInterpreter := True;
              CB_Quit;
            End;
        {$ENDIF}
        'z':
          Begin
            // Undo
            If KEYSTATE[K_SHIFT] = 0 Then
              DWPerformUndo
            Else
              DWPerformRedo;
          End;
        'c':
          Begin
            // Copy
            SP_CopySelection;
          End;
        'x':
          Begin
            // Cut
            DWCommenceUndo;
            SP_CutSelection;
            DWCompleteUndo;
          End;
        'v':
          Begin
            // Paste
            DWCommenceUndo;
            SP_PasteSelection;
            DWCompleteUndo;
          End;
        'a':
          Begin
            // Select All
            SP_SelectAll;
          End;
        'd':
          Begin
            // Select None
            SP_SelectNone;
          End;
        'r':
          Begin
            // Replace
            StartFindOp(False);
          End;
        'f':
          Begin
            // Find
            StartFindOp(True);
          End;
        'g':
          Begin
            // Go to line/label
            // Shift - go to last error
            If KEYSTATE[K_SHIFT] = 0 Then
              StartGotoOp
            Else
              SP_FPGotoLine(LASTERRORLINE, LASTERRORSTATEMENT);
          End;
        'o':
          Begin
            // Re-order listing
            Listing.CommenceUndo;
            SP_ReOrderListing(Error);
            Listing.CompleteUndo;
            SP_DisplayFPListing(-1);
          End;
        'l':
          Begin
            // LOAD ""
            StartFileOp(SP_KW_LOAD, '');
          End;
        'm':
          Begin
            // Merge ""
            StartFileOp(SP_KW_MERGE, '');
          End;
        'n':
          Begin
            // Add new breakpoint
            StartBPEditOp(-1, nil);
          End;
        's':
          Begin
            // Save
            StartFileOp(SP_KW_SAVE, PROGNAME);
          End;
        'w':
          Begin
            StartWatchOp(-1);
          End;
        'b':
          Begin
            // Show or hide the debug panel
            If FPDebugPanelVisible Then
              SP_CloseDebugPanel
            Else
              SP_OpenDebugPanel;
          End;
      End;
    End;
  End;

  SP_EditorDisplayEditLine;
  If FocusedWindow = fwDirect Then SP_DisplayDWCursor;

  // When a key is pressed, clear the error state and set the cursor back to
  // the correct colours.

  EDITERROR := False;
  If GfxMode = 1 Then Begin
    CURSORFG := 0;
    CURSORBG := 6;
  End Else
    SP_SetCursorColours;

  UpdateStatusLabel;
  SP_DrawGraphicsID;

End;

Procedure SP_FPEditorError(Var Error: TSP_ErrorCode; LineNum: Integer = -1);
Var
  Err: TSP_ErrorCode;
  ErrWin: pSP_Window_Info;
  ErrorText, Text, Title, StripeText: aString;
  ErrorFPS, t2, EMove, ETop: aFloat;
  ERRORWINDOW, WinW, WinH, WinX, WinY, MaxW, Lines, Cnt, Idx, MaxLen, bInk, bOver,
  Font, Window, ErrorDRPOSX, ErrorDRPOSY, ErrorPRPOSX, ErrorPRPOSY, ofs, x, sz, ErrDy, MoveFrames: Integer;
  CurrentTicks, TargetTicks, t, t3: LongWord;
  IsNew: Boolean;
  Key: Word;
  fp: TPoint;
Const
  stClrRed = #10;
  stClrYellow = #14;
  stClrGreen = #12;
  stClrCyan = #5;
Begin

  Window := SCREENBANK;
  ErrorFPS := FPS;
  REPCOUNT := FRAMES;

  SP_SetFPS(EDITORFPS);

  Font := SP_SetFPEditorFont;

  // Turn off ON ERROR - we don't want this to trigger now, it should have done it before if at all.
  // The EVERY system is also turned off, as the system should halt completely here.

  ERROR_LineNum := -1;
  SP_ClearEvery;

  SCREENLOCK := False;
  FPEditorOutSet := OUTSET;
  OUTSET := False;

  // Get the error Text

  IsNew := Error.Line < -1;

  If IsNew Then SystemState := SS_NEW Else SystemState := SS_ERROR;

  If Not IsNew Then Begin
    If LineNum = -1 Then Begin
      If Error.Line = -1 Then
        Error.Line := 0
      Else
        Error.Line := pLongWord(@SP_Program[Error.Line][2])^;
    End Else
      Error.Line := SP_GetLineNumberFromText(Listing[LineNum]);
    If Error.Code = 51 Then Begin
      If SP_KeyWordID < 4000 Then
        Text := IntToString(Error.Code)+' '+ErrorMessages[Error.Code] + SP_KEYWORDS[SP_KeyWordID - SP_KeyWord_Base] + ', ' + IntToString(Error.Line)+':'+IntToString(Error.Statement)
      Else
        Text := IntToString(Error.Code)+' '+ErrorMessages[Error.Code] + IntToString(SP_KeyWordID) + ', ' + IntToString(Error.Line)+':'+IntToString(Error.Statement);
    End Else
      Text := IntToString(Error.Code)+' '+ErrorMessages[Error.Code] + ', ' + IntToString(Error.Line)+':'+IntToString(Error.Statement);
  End Else Begin
    Text := #32#32#32#32#32#32#32#32#32#32#32#32#32#32#32#32#32#32#32#235#13+
            #32#32#236#228#228#228#230#228#228#228#235#236#228#228#232#230#228#228#228#227#236#228#228#232#226#228#228#228#235#236#228#228#228#13+
            #32#32#228#228#228#232#230#228#228#228#227#236#228#228#228#230#32#32#32#32#235#32#32#230#230#228#228#228#235#228#228#228#232#13+
            #32#32#228#228#228#228#226#32#32#32#32#228#228#228#228#226#228#228#228#227#228#228#228#228#226#228#228#228#227#228#228#228#228;
    StripeText := #16+stClrRed+#0#0#0#255#16+stClrYellow+#0#0#0#17+stClrRed+#0#0#0#255#16+stClrGreen+#0#0#0#17+stClrYellow+#0#0#0#255#16+stClrCyan+#0#0#0#17+stClrGreen+#0#0#0#255#16#0#0#0#0#17+stClrCyan+#0#0#0#255;
  End;

  If Error.Code <> SP_ERR_BREAKPOINT Then Begin

    // Create a window.

    If Not IsNew Then Begin
      Idx := 1;
      Cnt := 0;
      ErrorText := '';
      MaxW := DISPLAYWIDTH - (2 + FPFw + FPFw);
      While Idx <= Length(Text) Do Begin
        ErrorText := ErrorText + Text[Idx];
        If Text[Idx] >= ' ' Then
          Inc(Cnt);
        If Cnt > MaxW Div FPFw Then Begin
          If Text[Idx] = ' ' Then
            ErrorText[Length(ErrorText)] := #13
          Else Begin
            While (Idx > 1) and (Text[Idx] > ' ') Do Begin
              Dec(Idx);
              ErrorText := Copy(ErrorText, 1, Length(ErrorText) -1);
            End;
            ErrorText := ErrorText + #13;
          End;
          Cnt := 0;
        End;
        If Text[Idx] = #13 Then
          Cnt := 0;
        Inc(Idx);
      End;

      Idx := 1;
      Cnt := 0;
      Lines := 1;
      MaxLen := 0;
      While Idx < Length(ErrorText) Do Begin
        If ErrorText[Idx] >= ' ' Then
          Inc(Cnt);
        If ErrorText[Idx] = #13 Then Begin
          Inc(Lines);
          If Cnt > MaxLen Then
            MaxLen := Cnt;
          Cnt := 0;
        End;
        Inc(Idx);
      End;
      If Cnt > MaxLen Then
        MaxLen := Cnt;
      WinW := (MaxLen * FPFw) + 2 + 8;
      WinH := FPCaptionHeight + (BSize * 2) + 1 + (FPFh * Lines);
    End Else Begin
      WinW := Min(Fw * 48, DISPLAYWIDTH);
      WinH := Fh * 14;
    End;

    SHOWLIST := False;
    If IsNew Then
      Title := ' '
    Else
      If (Error.Code <> SP_ERR_OK) And (Error.Code <> SP_ERR_BREAK) And (Error.Code <> SP_ERR_STOP) Then Begin
        Title := 'SpecBAS error';
        WinW := DISPLAYWIDTH - BSize * 2;
      End Else Begin
        Title := 'SpecBAS message';
        WinW := DISPLAYWIDTH - BSize * 2;
      End;

    WinX := (DISPLAYWIDTH - WinW) Div 2;
    If Error.Line < -1 Then
      WinY := (DISPLAYHEIGHT - WinH) Div 2
    Else
      WinY := (DISPLAYHEIGHT - WinH) - BSize;

    SP_SetCurrentWindowSettings;
    ERRORWINDOW := SP_Add_Window(WinX, WinY, WinW, WinH, -1, 8, 0, Error);
    SP_SetDrawingWindow(ERRORWINDOW);
    For Idx := 0 To 255 Do pSP_Window_Info(WINDOWPOINTER)^.Palette[Idx] := DefaultPalette[Idx];
    SP_GetWindowDetails(ERRORWINDOW, ErrWin, Error);

    If Not IsNew Then Begin
      SP_FillRect(0, 0, WinW, WinH, 7);
      SP_Decorate_Window(ERRORWINDOW, Title, True, False, True);
      COVER := 0;
      T_INK := 0;
      T_OVER := 0;
      SP_TextOut(-1, 1 + BSize, BSize + FPCaptionHeight, EdSc + ErrorText, 0, 7, True);
      SP_DrawRectangle(0, 0, WinW -1, WinH -1);
      SP_SetWindowVisible(ERRORWINDOW, False, Error);
    End Else Begin
      SP_FillRect(0, 0, WinW, WinH, 0);
      SP_TextOut(FONTBANKID, 8, 8, Text, 2, 0, True);
      SP_TextOut(FONTBANKID, 16, 40, 'Version ' + BuildStr, 7,0,True);
    End;

    SP_InvalidateWholeDisplay;
    SP_NeedDisplayUpdate := True;
    CauseUpdate := True;

    If IsNew Then Begin

      If ParamCount = 0 Then Begin

        TargetTicks := CB_GetTicks + LongWord(250);
        SP_NeedDisplayUpdate := True;
        While CB_GetTicks < TargetTicks Do Begin
          SP_WaitForSync;
        End;

        SP_PlaySignature;

        // If the sample bank is playing, draw loading stripes

        If SIGSAMPLEBANK >-1 Then Begin
          // Cyan border
          SP_FillRect(16, WinH - 32, WinW - 32, 16, 5);
          TargetTicks := CB_GetTicks + LongWord(35);
          SP_NeedDisplayUpdate := True;
          While CB_GetTicks < TargetTicks Do Begin
            SP_WaitForSync;
          End;
          // Red border
          SP_FillRect(16, WinH - 32, WinW - 32, 16, 2);
          TargetTicks := CB_GetTicks + LongWord(65);
          SP_NeedDisplayUpdate := True;
          While CB_GetTicks < TargetTicks Do Begin
            SP_WaitForSync;
          End;
          // Red/Cyan pilot tone
          TargetTicks := CB_GetTicks + LongWord(500);
          ofs := 65536; sz := 16;
          While CB_GetTicks < TargetTicks Do Begin
            For x := 16 To WinW -16 Do Begin
              If (x+ofs) mod 16 < 8 + (Random(4) -2) Then T_INK := 5 Else T_Ink := 2;
              SP_DrawLineEx(x, WinH - 32, x, WinH -16);
              Dec(Ofs, 2);
            End;
            SP_NeedDisplayUpdate := True;
            SP_WaitForSync;
          End;
          // Yellow/Blue data burst
          TargetTicks := CB_GetTicks + LongWord(160);
          While CB_GetTicks < TargetTicks Do Begin
            x := 16; Sz := 0; Ofs := 0;
            While x < WinW - 16 Do Begin
              If Sz = 0 Then Begin
                If Ofs = 0 Then Begin
                  If Random(32)>16 Then
                    Sz := 4
                  Else
                    Sz := 8;
                  Inc(Sz, Random(4) -2);
                  Cnt := Sz;
                  Ofs := 1;
                End Else Begin
                  Ofs := 0;
                  Sz := Cnt;
                End;
              End;
              If Ofs = 0 Then T_INK := 1 Else T_INK := 6;
              SP_DrawLineEx(x, WinH - 32, x, WinH -16);
              Inc(x);
              Dec(Sz);
            End;
            SP_NeedDisplayUpdate := True;
            SP_WaitForSync;
          End;
        End;
        SP_FillRect(16, WinH - 32, WinW - 16, WinH - 16, 0);
      End;

      // Show (C) info and stripes after load

      T_SCALEY := 2;
      T_INK := 8;
      Cnt := WinH - 4;
      x := 48;
      While x > 0 Do Begin
        SP_TextOut(FONTBANKID, WinW - x, Cnt, StripeText, 0, 0, True);
        Dec(Cnt, 16);
        Dec(x, 8);
      End;
      T_SCALEY := 1;
      SP_TextOut(FONTBANKID, 16, WinH - 22, #127' 2020 ZX Development Ltd.'{#13'        ZXDunny    Windows/Pandora/OSX'#13'        Piez       Linux'#13'        Chris      Pi'}, 232, 0, True);
      SP_InvalidateWholeDisplay;
      SP_NeedDisplayUpdate := True;
      SP_WaitForSync;

    End Else Begin

      ErrWin^.Top := DISPLAYHEIGHT +1;
      SP_SetWindowVisible(ERRORWINDOW, True, Error);

      t := CB_GetTicks;
      EMove := WinY - ErrWin^.Top;
      ETop := ErrWin^.Top;

      Repeat
        t3 := CB_GetTicks;
        t2 := (t3 - t)/ANIMSPEED;
        DisplaySection.Enter;
        ErrWin^.Top := Trunc(ETop + (EMove * t2));
        If ((EMove > 0) And (ErrWin^.Top > WinY)) or ((EMove < 0) And (ErrWin^.Top < WinY)) Then
          ErrWin^.Top := WinY;
        DisplaySection.Leave;
        SP_InvalidateWholeDisplay;
        SP_WaitForSync;
      Until (t3 - t) >= ANIMSPEED;

    End;

    // Wait for any key - also clear the ESCAPE key's status as it might be left set down.

    SP_ClearKeyBuffer(True);
    MOUSEBTN := 0;

    Repeat
      Key := LASTKEY;
      SP_WaitForSync;
      // If a key UP event happens, ignore it - it's likely left over from before the
      // error message was displayed, and we're only interested in keydown.
      If SP_KeyEventWaiting And (KeyBuffer[0].Event = 1) Then SP_UnBufferKey;
    Until (Key <> 0) or (MOUSEBTN <> 0) Or QUITMSG or SP_KeyEventWaiting;
    SP_PlaySystem(CLICKCHAN, CLICKBANK);
    M_DOWNFLAG := False;

    If QUITMSG Then Exit;

    If Not IsNew Then Begin

      t := CB_GetTicks;
      WinY := DisplayHeight +1;
      EMove := WinY - ErrWin^.Top;
      ETop := ErrWin^.Top;

      Repeat
        t3 := CB_GetTicks;
        t2 := (t3 - t)/ANIMSPEED;
        DisplaySection.Enter;
        ErrWin^.Top := Trunc(ETop + (EMove * t2));
        If ((EMove > 0) And (ErrWin^.Top > WinY)) or ((EMove < 0) And (ErrWin^.Top < WinY)) Then
          ErrWin^.Top := WinY;
        DisplaySection.Leave;
        SP_InvalidateWholeDisplay;
        SP_WaitForSync;
      Until (t3 - t) >= ANIMSPEED;

    End;

    SP_SetWindowVisible(ERRORWINDOW, False, Err);
    SP_NeedDisplayUpdate := True;
    SP_WaitForSync;

    Err.Code := SP_ERR_OK;
    SP_DeleteWindow(ERRORWINDOW, Err);

  End;

  SP_Stop_Sound;

  If SIGSAMPLEBANK > -1 Then Begin
    SP_DeleteBank(SIGSAMPLEBANK, Error);
    SIGSAMPLEBANK := -2;
  End;

  SP_SetFPS(ErrorFPS);

  SP_SetSystemFont(Font, Err);
  SP_SetDrawingWindow(Window);

  // Move the editor highlight to the error line

  If (Error.Code <> SP_ERR_OK) And (Error.Code <> SP_ERR_BREAK) Then
    If Error.Line > 0 Then Begin
      fp := SP_FindFPLineStatement(Error.Line, Error.Statement);
      If fp.x > -1 Then Begin
        Listing.FPCLine := fp.x;
        Listing.FPCPos := fp.y;
        Listing.FPSelLine := Listing.FPCLine;
        Listing.FPSelPos := Listing.FPCPos;
        FPCDes := Listing.FPCPos;
      End Else Begin
        Listing.FPCLine := 0;
        Listing.FPCPos := 1;
        Listing.FPSelLine := Listing.FPCLine;
        Listing.FPSelPos := Listing.FPCPos;
        FPCDes := Listing.FPCPos;
      End;
      FPCDesLine := Listing.FPCLine;
      PROGLINE := Error.Line;
      SHOWLIST := True;
    End;

  If Error.Code <> SP_ERR_BREAKPOINT Then
    If KeyBuffer[0].Key = K_TAB Then Begin
      // TAB is special - bring the error line to the command window for editing
      If Error.Line > 0 Then
        If Error.Code > 0 Then Begin
          SP_UnBufferKey;
          LASTKEY := 0;
          SP_FPBringToEditor(Error.Line, Error.Statement, Error);
          SP_ScrollInView;
          DWSelP := CURSORPOS;
        End;
    End Else
      If KeyBuffer[0].Key = K_RETURN Then Begin
        // Discard any ENTER key events, as they will just cause the
        // editor to try and re-enter the line again
        SP_UnBufferKey;
        LASTKEY := 0;
      End;

  If IsNew or (KeyBuffer[0].Key in [K_F7, K_F8, K_F9]) Then Begin
    SP_ClearKeyBuffer(True);
    LASTKEY := 0;
  End;

  If IsNew And (ParamCount = 0) Then
    SP_CLS(CPAPER);

  OUTSET := FPEditorOutSet;
  SP_NeedDisplayUpdate := True;
  CauseUpdate := True;

End;

Procedure SP_FPMakeListWindowVisible;
Begin

End;

Procedure SP_CloseEditorWindows;
Var
  Error: TSP_ErrorCode;
Begin

  Error.Code := SP_ERR_OK;
  SP_FPCycleEditorWindows(1);
  SP_DeleteWindow(FPWindowID, Error);
  SP_DeleteWindow(DWWindowID, Error);
  FPWIndowID := -1;
  DWWindowID := -1;

  SP_SetFPS(FPEditorSaveFPS);

  SetLength(Events, 0);
  FPDebugPanel := nil;
  FPDebugCombo := nil;
  DRPOSX := FPEditorDRPOSX;
  DRPOSY := FPEditorDRPOSY;
  PRPOSX := FPEditorPRPOSX;
  PRPOSY := FPEditorPRPOSY;
  COVER := FPEditorOVER;
  T_OVER := COVER;
  SP_SetDrawingWindow(FPEditorDefaultWindow);
  SP_Reset_Temp_Colours;
  SP_NeedDisplayUpdate := True;
  CauseUpdate := True;
  MOUSEVISIBLE := FPEditorMouseStatus;

  CURMENU := EDITORMENU;

End;

Procedure SP_CreateEditorWindows;
Begin

  SP_CreateDirectWindow;
  SP_CreateFPWindow;
  SP_DisplayFPListing(-1);
  FocusedWindow := fwDirect;
  SP_SwitchFocus(FocusedWindow);
  SP_FPCycleEditorWindows(2);

End;

Procedure SP_AddToHistory(Text: aString);
Var
  Idx, Idx2: Integer;
Begin

  While (Length(EditorHistory) > 0) And (EditorHistory[Length(EditorHistory) -1] = '') Do
    SetLength(EditorHistory, Length(EditorHistory) -1);
  While Text[1] <= ' ' Do
    Text := Copy(Text, 2, Length(Text));
  While Text[Length(Text)] <= ' ' Do
    Text := Copy(Text, 1, Length(Text) -1);
  For Idx := 0 To Length(EditorHistory) -1 Do Begin
    If Text = EditorHistory[Idx] Then Begin
      For Idx2 := Idx To Length(EditorHistory) -2 Do
        EditorHistory[Idx2] := EditorHistory[Idx2 +1];
      SetLength(EditorHistory, Length(EditorHistory) -1);
      Break;
    End;
  End;
  If (Length(EditorHistory) > 0) and (EditorHistory[Length(EditorHistory) -1] = Text) Then Exit;
  SetLength(EditorHistory, Length(EditorHistory) +1);
  EditorHistory[Length(EditorHistory) -1] := Text;
  HistoryPos := Length(EditorHistory);

End;

Function SP_FPExecuteNumericExpression(Const Expr: aString; var Error: TSP_ErrorCode): aFloat;
Var
  Backup: Pointer;
Begin

  Backup := SP_StackPtr;
  Error.Code := SP_ERR_OK;
  SP_FPExecuteExpression(Expr, Error);
  If Error.Code = SP_ERR_OK Then
    If SP_StackPtr^.OpType = SP_VALUE Then
      Result := SP_StackPtr^.Val
    Else
      Error.Code := SP_ERR_SYNTAX_ERROR;
  SP_StackPtr := pSP_StackItem(Backup);

End;

Function SP_FPExecuteStringExpression(Const Expr: aString; var Error: TSP_ErrorCode): aString;
Var
  Backup: Pointer;
Begin

  Backup := SP_StackPtr;
  SP_FPExecuteExpression(Expr, Error);
  If Error.Code = SP_ERR_OK Then
    If SP_StackPtr^.OpType = SP_STRING Then
      Result := SP_StackPtr^.Str
    Else
      Error.Code := SP_ERR_SYNTAX_ERROR;
  SP_StackPtr := pSP_StackItem(Backup);

End;

Function SP_FPCheckExpression(Const Expr: aString; var Error: TSP_ErrorCode): Boolean;
Var
  Position: Integer;
  s, t: aString;
Begin

  Position := 1;
  s := SP_TokeniseLine(Expr, True, False) + #255;
  t := SP_Convert_Expr(s, Position, Error, -1);
  Result := (Error.Code = SP_ERR_OK) And (Position >= Length(s));

End;

Function SP_FPExecuteAnyExpression(Const Expr: aString; var Error: TSP_ErrorCode): aString;
Var
  Backup: Pointer;
Begin

  Backup := SP_StackPtr;
  SP_FPExecuteExpression(Expr, Error);
  If Error.Code = SP_ERR_OK Then
    If SP_StackPtr^.OpType = SP_VALUE Then
      Result := aFloatToStr(SP_StackPtr^.Val)
    Else
      Result := SP_StackPtr^.Str;
  SP_StackPtr := pSP_StackItem(Backup);

End;

Procedure SP_FPExecuteExpression(Const Expr: aString; var Error: TSP_ErrorCode);
Var
  CC: Boolean;
  Position: Integer;
  ValTkn: paString;
  Str1, ValTokens: aString;
Begin


  // Executes a line of BASIC as an expression. Calling functions can deal with the result and any errors.

  Position := 1;
  If Expr[1] <> #$F Then Begin
    Str1 := SP_TokeniseLine(Expr, True, False) + #255;
    ValTokens := SP_Convert_Expr(Str1, Position, Error, -1) + #255;
    SP_RemoveBlocks(ValTokens);
    SP_TestConsts(ValTokens, 1, Error, False);
    SP_AddHandlers(ValTokens);
  End Else
    ValTokens := Copy(Expr, 2);

  If ValTokens = #255 Then Begin
    Error.Code := SP_ERR_SYNTAX_ERROR;
    Exit;
  End;

  If Error.Code = SP_ERR_OK Then Begin
    Position := 1;
    ValTkn := @ValTokens;
    SP_InterpretCONTSafe(ValTkn, Position, Error);
  End;

End;

Procedure SP_FPExecuteEditLine(Var Line: aString);
Var
  aSave, b: Boolean;
  TokensStr, Expr, s: aString;
  Tokens: paString;
  PreParseErrorCode, PreParseErrorLine, PreParseErrorStatement, CurLine, Idx, LocalFlashState,
  saveCONTLINE, saveCONTSTATEMENT: Integer;
  pInfo: pSP_iInfo;
  Info: TSP_iInfo;
  Error: TSP_ErrorCode;
  KeyChar: Byte;
Label
  ExitProc;
Begin

  SP_HideFindResults(False);
  If StripLeadingSpaces(Line) <> '' Then Begin

    SP_ClearKeyBuffer(True);

    TokensStr := SP_TokeniseLine(Line, False, True) + SP_TERMINAL_SEQUENCE;
    SP_Convert_ToPostFix(TokensStr, Error.Position, Error);
    DWStoreEditorState;
    Line := SP_DeTokenise(TokensStr, Error.Position, False, False);
    BREAKSIGNAL := False;

    If Error.Code = SP_ERR_OK Then Begin

      EDITERROR := False;
      If TokensStr[1] = aChar(SP_LINE_NUM) Then Begin
        // A line to be stored in the listing.
        SP_DeleteIncludes;
        SP_FPMakeListWindowVisible;
        DoAutoSave(Error);
        PROGLINE := dLongWord(@TokensStr[2]);
        ProcListAvailable := False;
        SP_DWStoreLine(TokensStr);
        DWStoreEditorState;
        Line := '';
        Error.Code := SP_ERR_NO_ERROR;
        SP_PlaySystem(OKCHAN, OKSNDBANK);
      End Else Begin
        // Can't store it, so try executing it!
        If STEPMODE = 0 then Begin
          BPSIGNAL := False;
          SP_CloseEditorWindows;
          If @Line = @EDITLINE Then
            SP_AddToHistory(Line);
        End Else Begin
          SP_SetDrawingWindow(FPEditorDefaultWindow);
          SP_Reset_Temp_Colours;
        End;
        DWStoreEditorState;
        Line := '';
        Error.Line := -1;
        Error.Statement := 1;
        Error.Position := SP_FindStatement(@TokensStr, 1);
        COMMAND_TOKENS := TokensStr;
        NXTSTATEMENT := -1;
        NXTLINE := -1;
        SP_StackPtr := SP_StackStart;
        Tokens := @TokensStr;
        SP_DeleteIncludes;
        SP_PreParse(False, Error);
        PreParseErrorCode := Error.Code;
        PreParseErrorLine := Error.Line;
        PreParseErrorStatement := Error.Statement;
        Error.Code := SP_ERR_OK;
        Error.ReturnType := 0;
        PROGSTATE := SP_PR_RUN;
        ClearFlags;
        OUTSET := FPEditorOutSet;
        SystemState := SS_DIRECT;
        saveCONTLINE := CONTLINE;
        saveCONTSTATEMENT := CONTSTATEMENT;
        // Run it!
        SP_Interpreter(Tokens, Error.Position, Error, PreParseErrorCode);
        // And back to the editor.
        If STEPMODE <> 0 Then Begin
          SP_ClearKeyBuffer(True);
          LASTKEY := 0;
        End;
        SP_PrepareBreakpoints(False);
        While (Round((FPWindowWidth - FPFw) - (FPGutterWidth * (EDFONTSCALEX * Fw))) Div (Round(EDFONTSCALEX * Fw))) -2 < FPGutterWidth Do Begin
          EDFONTSCALEX := EDFONTSCALEX -1;
          EDFONTSCALEY := EDFONTSCALEY -1;
        End;
        If (Error.Code <> SP_ERR_OK) And (Error.Code = PreParseErrorCode) Then Begin
          Error.Line := PreParseErrorLine;
          Error.Statement := PreParseErrorStatement;
        End Else
          If Error.Code = SP_ERR_EDITOR Then Begin
            Listing.FPCLine := Error.Line;
            Listing.FPCPos := SP_LineHasNumber(Listing.FPCLine) +1;
            Listing.FPSelLine := Listing.FPCLine;
            Listing.FPSelPos := Listing.FPCPos;
            FPCDes := Listing.FPCPos;
            FPCDesLine := Listing.FPCLine;
            SP_PlaySystem(ERRORCHAN, ERRSNDBANK);
            Error.Code := SP_ERR_NO_ERROR;
            If STEPMODE = 0 Then SP_CreateEditorWindows;
            SP_SwitchFocus(fwEditor);
            CURSORFG := 10;
            CURSORBG := 15;
          End;
        SP_ClearKeyBuffer(True);
      End;
    End Else Begin
      // Ok, not a proper line - is it an expression?
      // Expressions will return error 7 every time - invalid keyword. Of course, it could actually be
      // an invalid keyword...
      If Error.Code = SP_ERR_INVALID_KEYWORD Then Begin
        Error.Code := SP_ERR_OK;
        Error.Position := 1;
        DWStoreEditorState;
        TokensStr := SP_TokeniseLine(EDITLINE, True, False) + SP_TERMINAL_SEQUENCE;
        EDITLINE := SP_DeTokenise(TokensStr, Error.Position, False, False);
        Idx := Length(TokensStr) +1;
        If (Ord(TokensStr[Error.Position]) = SP_SYMBOL) And (TokensStr[Error.Position +1] = '?') Then
          Inc(Error.Position, 2);
        Expr := SP_Convert_Expr(TokensStr, Error.Position, Error, -1) + SP_TERMINAL_SEQUENCE;
        SP_RemoveBlocks(Expr);
        TokensStr := TokensStr + Expr;
        If (Error.Code = SP_ERR_OK) And (Expr <> SP_TERMINAL_SEQUENCE) Then Begin
          Error.Position := Idx;
          COMMAND_TOKENS := TokensStr;
          NXTSTATEMENT := -1;
          NXTLINE := -1;
          SP_StackPtr := SP_StackStart;
          Tokens := @TokensStr;
          SP_DeleteIncludes;
          SP_PreParse(False, Error);
          PreParseErrorCode := Error.Code;
          Error.Code := SP_ERR_OK;
          PROGSTATE := SP_PR_RUN;
          SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
          ClearFlags;
          OUTSET := FPEditorOutSet;
          SP_SetDrawingWindow(FPEditorDefaultWindow);
          saveCONTLINE := CONTLINE;
          saveCONTSTATEMENT := CONTSTATEMENT;
          SP_Interpreter(Tokens, Error.Position, Error, PreParseErrorCode);
          CONTLINE := saveCONTLINE;
          CONTSTATEMENT := saveCONTSTATEMENT;
          If (Error.Code = SP_ERR_OK) And (LongWord(SP_StackPtr) = LongWord(SP_StackStart) + SizeOf(SP_StackItem)) Then Begin
            Error.Code := SP_ERR_NO_ERROR;
            SP_AddToHistory(EDITLINE);
            If SP_StackPtr^.OpType = SP_VALUE Then
              Expr := aFloatToStr(SP_StackPtr^.Val) + ' '
            Else Begin
              Expr := SP_StackPtr^.Str;
              Idx := 1;
              b := False;
              If Expr = '' Then
                Expr := '""'
              Else Begin
                s := '';
                While Idx <= Length(Expr) Do Begin
                  If Expr[Idx] >= ' ' Then Begin
                    If Not b Then Begin
                      s := s + '"';
                      b := True;
                    End;
                    s := s + Expr[Idx];
                  End Else Begin
                    If b Then Begin
                      s := s + '"';
                      b := False;
                    End;
                    s := s + '#' + IntToString(Ord(Expr[Idx]));
                  End;
                  Inc(Idx);
                End;
                If b Then
                  s := s + '"';
                Expr := s;
              End;
              Expr := Expr + ' ';
              If Length(Expr) > 256 Then
                Expr := Copy(Expr, 1, 256);
            End;
            EDITLINE := '';
            CURSORFG := 0;
            CURSORBG := 4;
            CURSORCHAR := 32;
            EDITERROR := True;
            SP_DrawGraphicsID;
            SP_PlaySystem(OKCHAN, OKSNDBANK);
            SP_AddToHistory(Expr);
            For Idx := 1 To Length(Expr) Do Begin
              EDITLINE := Copy(Expr, 1, Idx);
              CURSORPOS := Length(EDITLINE);
              DWSelP := CURSORPOS;
              CURSORCHAR := 32;
              SP_EditorDisplayEditLine;
              SP_DisplayDWCursor;
              SP_WaitForSync;
            End;
            KeyChar := 0;
            M_MOVEFLAG := False;
            Repeat
              SP_FPWaitForUserEvent(KeyChar, LocalFlashState);
            Until M_DOWNFLAG or (LASTKEY <> 0);
            EDITLINE := '';
            SP_SetCursorColours;
            CURSORPOS := 1;
            DWSelP := CURSORPOS;
            EDITERROR := False;
            CURSORCHAR := 32;
            SP_EditorDisplayEditLine;
            SP_WaitForSync;
          End Else Begin
            If (Error.Code = SP_ERR_OK) And (SP_StackPtr = SP_StackStart) Then Begin
              Error.Code := SP_ERR_SYNTAX_ERROR;
              EDITERRORPOS := Min(Error.Position, Length(EDITLINE));
              EDITERROR := True;
              SP_PlaySystem(ERRORCHAN, ERRSNDBANK);
            End;
            SP_CloseEditorWindows;
            Error.Line := -1;
            Error.Statement := 1;
            Goto ExitProc;
          End;
        End Else Begin
          EDITLINE := SP_DeTokenise(TokensStr, Error.Position, False, False);
          EDITERROR := True;
          SP_EditorDisplayEditLine;
          SP_PlaySystem(ERRORCHAN, ERRSNDBANK);
          CURSORFG := 10;
          CURSORBG := 15;
        End;
      End;
      If (Error.Code <> SP_ERR_OK) And (Error.Code <> SP_ERR_NO_ERROR) Then Begin
        EDITERRORPOS := Error.Position;
        EDITERROR := True;
        SP_EditorDisplayEditLine;
        SP_PlaySystem(ERRORCHAN, ERRSNDBANK);
      End;
    End;

  ExitProc:

    PROGSTATE := SP_PR_STOP;
    If Not QUITMSG Then Begin
      If Not Assigned(CompilerThread) Then
        CompilerThread := TCompilerThread.Create(False);
      If Error.Code <> SP_ERR_NO_ERROR Then Begin
        If Not EDITERROR Then Begin
          If STEPMODE < SM_Single Then Begin
            If STEPMODE = SM_None Then
              SP_FPEditorError(Error);
            SP_CreateEditorWindows;
            If SHOWLIST Then Begin
              SP_DisplayFPListing(-1);
              SP_CalculateFPCursorPos;
              SP_CursorPosChanged;
              SP_ScrollInView;
              SHOWLIST := FALSE;
            End;
          End Else
            If STEPMODE = SM_StepOver Then Begin
              FPEditorDefaultWindow := SCREENBANK;
              FPEditorDRPOSX := DRPOSX;
              FPEditorDRPOSY := DRPOSY;
              FPEditorPRPOSX := PRPOSX;
              FPEditorPRPOSY := PRPOSY;
              FPEditorOVER := COVER;
              FPEditorSaveFPS := FPS;
              FPEditorFRAME_MS := FRAME_MS;
              FPEditorMouseStatus := MOUSEVISIBLE;
              If Not((CONTLINE = -1) or (CONTLINE >= SP_Program_Count) or (SP_Program[CONTLINE] = '')) Then
                PROGLINE := pLongWord(@SP_Program[CONTLINE][2])^;
                If FPWindowID = -1 Then SP_CreateEditorWindows;
                SP_FPScrollToLine(pLongWord(@SP_Program[CONTLINE][2])^, CONTSTATEMENT);
              End;
          PreparseErrorCode := SP_ERR_OK;
          COVER := 0;
          T_OVER := 0;
        End Else
          If CURSORBG = 4 Then // Ugh, this is horrid.
            EDITERROR := False;
      End Else
        If CURSORBG = 4 Then // And so is this, but I'm lazy.
          EDITERROR := False;
    End;

  End;

  SP_FillDebugPanel;
  If FocusedWindow = FWEditor Then
    SYSTEMSTATE := SS_EDITOR
  Else
    SYSTEMSTATE := SS_DIRECT;

  STEPMODE := SM_None;
  SP_GetDebugStatus;

End;

Function SP_FindLineInListing(LineNum: Integer): Integer;
Var
  Idx: Integer;
Begin
  Result := -1;
  Idx := 0;
  While Idx < Listing.Count Do Begin
    If SP_GetLineNumberFromText(Listing[Idx]) = LineNum Then Begin
      Result := Idx;
      Exit;
    End Else
      Inc(Idx);
  End;
End;

Procedure SP_CompileProgram;
Var
  CurLine, Idx: Integer;
  s: aString;
Begin

  // Gathers up all the compiled code and builds a program from it

  If Assigned(CompiledListing) Then Begin
    SP_Program_Clear;
    For Idx := 0 To CompiledListing.Count -1 Do Begin
      s := CompiledListing[Idx];
      If s <> '' Then Begin
        CurLine := pLongWord(@s[2])^;
        If SP_FindLineInListing(CurLine) > -1 Then
          SP_Store_Line(s);
      End;
    End;
  End;

End;

Procedure SP_DWStoreLine(Line: aString);
Var
  s: aString;
  LineNum, Idx: Integer;
  Extents: TPoint;

  Procedure SP_nDeleteLine;
  Var
    Cnt: Integer;
  Begin
    Cnt := (Extents.y - Extents.x) +1;
    CompilerLock.Enter;
    While Cnt > 0 Do Begin
      SP_DeleteLine(Extents.x);
      Dec(Cnt);
    End;
    If Listing.Count = 0 Then Begin
      SP_AddLine('', '', '');
      Listing.Flags[Listing.Count -1].ReturnType := spHardReturn;
    End;
    CompilerLock.Leave;
  End;

Begin

  // Takes the compiled text of the editline, EDITLINE contains the detokenised code,
  // which is stored in the listing.

  s := StripSpaces(EDITLINE);
  LineNum := SP_GetLineNumberFromText(s);
  If StrToIntDef(s, -1) <> -1 Then Begin
    // A single line number, so a line delete operation
    Idx := SP_GetExactLineIndex(LineNum);
    If Idx < Listing.Count Then Begin
      Extents := SP_GetLineExtents(Idx);
      Listing.CommenceUndo;
      SP_nDeleteLine;
      Listing.CompleteUndo;
    End;
    If Listing.FPCLine >= Idx Then
      If Idx > 0 Then
        Listing.FPCLine := Idx -1
      Else
        Listing.FPCLine := 0;
  End Else Begin
    // Store this line. Find either the next larger line and insert there,
    // or an existing line and replace that.
    Idx := SP_GetLineIndex(LineNum);
    If Idx = Listing.Count Then Begin
      // Line is non-existing or has a line number greater than that of the last line
      CompilerLock.Enter;
      Listing.CommenceUndo;
      If (Listing.Count = 1) And (StripSpaces(Listing[0]) = '') Then Begin
        Listing[0] := EDITLINE
      End Else Begin
        SP_AddLine(EDITLINE, '', '');
        Listing.Flags[Listing.Count -1].ReturnType := spHardReturn;
      End;
      CompilerLock.Leave;
      PROGLINE := LineNum;
      Listing.FPCLine := Listing.Count -1;
      Listing.CompleteUndo;
    End Else Begin
      // Line can either be inserted or needs to replace a line.
      Listing.CommenceUndo;
      If SP_GetLineNumberFromText(Listing[Idx]) = LineNum Then Begin
        // A replace operation. Get the extents of the line to be replaced.
        Extents := SP_GetLineExtents(Idx);
        SP_nDeleteLine;
      End;
      // Insert the new line
      CompilerLock.Enter;
      SP_InsertLine(Idx, EDITLINE, '', '');
      Listing.Flags[Idx].ReturnType := spHardReturn;
      CompilerLock.Leave;
      PROGLINE := LineNum;
      Listing.FPCLine := Idx;
      Listing.CompleteUndo;
    End;

  End;

  DWStoreEditorState;
  EDITLINE := '';
  Listing.FPCPos := 1;
  Listing.FPSelLine := Listing.FPCLine;
  Listing.FPSelPos := Listing.FPCPos;
  FPCDes := Listing.FPCPos;
  FPCDesLine := Listing.FPCPos;
  SP_FPWordWrapLine(Listing.FPCLine);
  SP_CalculateFPCursorPos;
  SP_MarkAsDirty(Listing.FPCLine);
  SP_CursorPosChanged;
  SP_FPApplyHighlighting(Listing.FPCLine);
  SP_FPRethinkScrollBars;
  SP_DisplayFPListing(-1);
  SP_ScrollInView;
  SP_EditorDisplayEditLine;

End;

Procedure SP_Interpreter(Var Tokens: paString; Var Position: Integer; Var Error: TSP_ErrorCode; PreParseErrorCode: Integer; Continue: Boolean);
Var
  CurLine, ProgLen, Idx, ErrLine, ErrStatement, OldEC: Integer;
  HasErrors, BreakNow: Boolean;
  res: aString;
Begin

  // If there are errors in the listing, or lines that have yet to be compiled, then
  // flag them up now. Errors will not stop the _command line_ from running, but will
  // prevent entry to the program.

  HasErrors := False;

  If Not Continue Then Begin

    HasErrors := Not SP_CheckProgram;
    If Assigned(CompilerThread) Then SP_StopCompiler;
    SP_Interpret(Tokens, Error.Position, Error);

  End;

  If Error.ReturnType >= SP_JUMP Then
    If PreParseErrorCode <> SP_ERR_OK Then Begin
      Error.Code := PreParseErrorCode;
      Error.ReturnType := 0;
      Exit;
    End;

  If INCLUDEFROM > -1 Then Begin
    If NXTLINE >= INCLUDEFROM Then NXTLINE := -1;
  End Else
    If NXTLINE >= SP_Program_Count Then NXTLINE := -1;

  While NXTLINE <> -1 Do Begin

    If NXTLINE = -2 Then Begin
      CurLine := -1;
      SYSTEMSTATE := SS_DIRECT;
      Tokens := @COMMAND_TOKENS;
      If NXTSTATEMENT = -1 Then Begin Dec(Error.Statement); Exit; End;
      If Byte(Tokens^[NXTSTATEMENT]) = SP_TERMINAL Then
        Dec(Error.Statement);
    End Else Begin
      If HasErrors Then Begin
        Error.Code := SP_ERR_EDITOR;
        Error.Line := Idx;
        Error.Statement := 1;
        EDITERROR := True;
        Exit;
      End Else Begin
        CurLine := NXTLINE;
        SYSTEMSTATE := SS_INTERPRET;
        Tokens := @SP_Program[CurLine];
      End;
    End;

    If NXTSTATEMENT <> -1 Then
      Error.Position := NXTSTATEMENT
    Else Begin
      Error.Statement := 1;
      Error.Position := SP_FindStatement(Tokens, 1);
    End;

    NXTSTATEMENT := -1;
    Inc(NXTLINE);
    If NXTLINE <> 0 Then Begin
      Error.Line := CurLine;
      SP_StackPtr := SP_StackStart;
      SP_Interpret(Tokens, Error.Position, Error);
      If DEBUGGING Then Begin
        If STEPMODE = SM_Single Then
          Exit;

        If Error.Code = SP_ERR_OK Then
          For Idx := 0 To Length(SP_ConditionalBreakPointList) -1 Do
            With SP_ConditionalBreakPointList[Idx] Do Begin
              OldEC := Error.Code;
              BreakNow := PassCount = 0;
              If bpType = BP_Conditional Then
                BreakNow := (SP_FPExecuteNumericExpression(Compiled_Condition, Error) <> 0) And BreakNow
              Else Begin
                res := SP_FPExecuteAnyExpression(Compiled_Condition, Error);
                BreakNow := ((HasResult And (res <> CurResult)) or (Not HasResult)) and BreakNow and (Error.Code = SP_ERR_OK);
                If Error.Code = SP_ERR_OK Then Begin
                  CurResult := res;
                  HasResult := True;
                End;
              End;
              Error.Code := OldEC;
              If BreakNow Then Begin
                CONTLINE := NXTLINE;
                If NXTSTATEMENT = -1 Then
                  CONTSTATEMENT := 1
                Else
                  CONTSTATEMENT := SP_GetStatementFromOffset(NXTLINE, NXTSTATEMENT);
                Error.Code := SP_ERR_BREAKPOINT;
                Error.Line := CONTLINE;
                Error.Statement := CONTSTATEMENT;
                Exit;
              End Else
                If PassCount > 0 Then
                  Dec(PassCount);
            End;
      End;
    End;

    If NXTLINE = SP_Program_Count Then NXTLINE := -1;

    If Error.Code <> SP_ERR_OK Then Begin
      NXTLINE := -1;
    End Else Begin
      If NXTLINE <> -1 Then Begin
        If NXTLINE >= SP_Program_Count Then
          NXTLINE := -1;
      End;

    End;

  End;

End;

Procedure SP_Execute(Line: aString; Var Error: TSP_ErrorCode);
Var
  Tokens: paString;
  aSave: Boolean;
Begin

  aSave := AUTOSAVE;
  AUTOSAVE := False;

  Error.Line := -1;
  Error.Statement := 1;
  Error.Position := 1;
  Line := SP_TokeniseLine(Line, False, False) + #255#255#255#255;
  SP_Convert_ToPostFix(Line, Error.Position, Error);
  Tokens := @Line;
  Error.Position := SP_FindStatement(@Line, 1);
  Error.Code := SP_ERR_OK;
  COMMAND_TOKENS := Line;
  NXTSTATEMENT := -1;
  NXTLINE := -1;
  SP_StackPtr := SP_StackStart;
  SP_PreParse(False, Error);
  PROGSTATE := SP_PR_RUN;
  SP_Interpreter(Tokens, Error.Position, Error, Error.Code);

  AUTOSAVE := aSave;

End;

Procedure SP_FormatLine(LineNum: Integer);
Begin

  // Formats a line. Splits statements (:, THEN, ELSE) and splits words at nearest-lower non-numeric boundary to screen edge.

End;

Function SP_ReOrderListing(Var Error: TSP_ErrorCode): Boolean;
Var
  Idx, nIdx, nl, LineNum, rt: Integer;
  NewList: TStringlist;
  Extents: TPoint;
  s: aString;
Begin

  CompilerLock.Enter;

  // Orders the listing in line number order.
  // Can't be done while there's duplicate lines or errors in the code.

  Result := True;
  For Idx := 0 To Listing.Count -1 Do Begin
    Result := Listing.Flags[Idx].State in [spLineOk, spLineNull];
    If Not Result Then Begin
      Error.Code := SP_ERR_EDITOR;
      Error.Line := Idx;
      Error.Statement := 1;
      EDITERROR := True;
      CompilerLock.Leave;
      Exit;
    End;
  End;

  // Now create a new listing that will hold the re-ordered lines.

  s := '';
  For Idx := 0 To Listing.Count -1 Do
    s := s + LongWordToString(Length(Listing[Idx])) + LongWordToString(Listing.Flags[Idx].ReturnType) + Listing[Idx];
  NewList := TStringlist.Create;

  While Listing.Count > 0 Do Begin

    // I think this part is to preserve lines that might not have a line number at the start, but
    // as it won't get this far if there are errors, it's hard to see why. I dunno, I was very
    // drunk when I wrote this.

    LineNum := 0;
    While (Listing.Count > 0) And (LineNum = 0) Do Begin
      LineNum := SP_LineHasNumber(0);
      If LineNum <= 0 Then Begin
        S := LongWordToString(Listing.Flags[0].ReturnType) +
             LongWordToString(Length(Listing[0])) + Listing[0] +
             LongWordToString(Length(SyntaxListing[0])) + SyntaxListing[0] +
             LongWordToString(Length(CompiledListing[0])) + CompiledListing[0];
        NewList.Add(s);
        SP_DeleteLine(0);
      End Else
        LineNum := SP_GetLineNumberFromText(Listing[0]);
    End;

    If Listing.Count > 0 Then Begin

      Extents := SP_GetLineExtents(0);

      // Find where we need to insert this one

      Idx := 0;
      While Idx < NewList.Count Do Begin
        nl := SP_GetLineNumberFromText(Copy(NewList[Idx], 9));
        If nl >= LineNum Then Break;
        Inc(Idx);
      End;

      // Now either add to the end of the list or insert at this position.

      For nIdx := Extents.Y DownTo Extents.X Do Begin
        S := LongWordToString(Listing.Flags[nIdx].ReturnType) +
             LongWordToString(Length(Listing[nIdx])) + Listing[nIdx] +
             LongWordToString(Length(SyntaxListing[nIdx])) + SyntaxListing[nIdx] +
             LongWordToString(Length(CompiledListing[nIdx])) + CompiledListing[nIdx] +
             LongWordToString(Listing.Flags[nIdx].Indent);
        If Idx = NewList.Count Then
          NewList.Add(s)
        Else
          NewList.Insert(Idx, s);
        SP_DeleteLine(nIdx);
      End;

    End;

  End;

  // Now rebuild from the new listing back into the current listing

  For Idx := 0 To NewList.Count -1 Do Begin

    s := NewList[Idx];
    rt := pLongWord(@s[1])^;
    s := Copy(s, 5);

    nl := pLongWord(@s[1])^;
    Listing.Add(Copy(s, 5, nl));
    Listing.Flags[Idx].ReturnType := rt;
    s := copy(s, nl + 5);

    nl := pLongWord(@s[1])^;
    SyntaxListing.Add(Copy(s, 5, nl));
    s := copy(s, nl + 5);

    nl := pLongWord(@s[1])^;
    SP_CompiledListingAdd(Copy(s, 5, nl));
    s := copy(s, nl + 5);

    Listing.Flags[Idx].Indent := pLongWord(@s[1])^;
    s := Copy(s, 5);

    SP_FPApplyHighlighting(Listing.Count -1);

  End;

  NewList.Free;
  CompilerLock.Leave;

End;

Procedure SP_FPRenumberListing(Start, Finish, Line, Step: Integer; Var Error: TSP_ErrorCode);
Type
  TLineRec = Record Org, New, Flag, Indent: Integer; End;
Var
  Idx, sIdx, fIdx, nIdx, LineNum, curLineNum, kw, f, i: Integer;
  NewList, OutList: TStringlist;
  ChangeList: Array of TLineRec;
  InString, InREM: Boolean;
  s, w, e: aString;
  Extents: TPoint;
Begin

  CompilerLock.Enter;

  // Renumber the listing. Start and Finish indicate the line number range to renumber.
  // Line and step are the lines to start renumber to, and the step to increment.

  If Start < 0 Then Start := 0;
  If Finish < 0 Then Finish := 9999999;

  If Step < 1 Then Begin
    Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    CompilerLock.Leave;
    Exit;
  End;

  // First, re-order the listing - we have to do this so the lines can be picked up and
  // their increments done correctly.

  Listing.CommenceUndo;
  SP_ReOrderListing(Error);
  If Error.Code <> SP_ERR_OK Then Begin
    CompilerLock.Leave;
    Exit;
  End;

  // Now start renumbering. First grab the lines out to a temporary listing and remove them from the program.

  NewList := TStringList.Create;
  Idx := 0;
  sIdx := -1;
  fIdx := -1;
  While Idx < Listing.Count Do Begin
    If Not SP_WasPrevSoft(Idx) Then
      LineNum := SP_GetLineNumberFromText(Listing[Idx])
    Else
      LineNum := 0;
    If (LineNum >= Start) And (LineNum <= Finish) Then Begin
      If sIdx = -1 Then
        sIdx := Idx;
      Extents := SP_GetLineExtents(Idx);
      s := '';
      For nIdx := Extents.x To Extents.y Do
        s := s + LongWordToString(Listing.Flags[nIdx].ReturnType) + LongWordToString(Listing.Flags[nIdx].Indent) + LongWordToString(Length(Listing[nIdx])) + Listing[nIdx];
      NewList.Add(s);
      Idx := Extents.y;
    End Else
      If (LineNum > Finish) And (fIdx = -1) Then
        fIdx := Idx;
    Inc(Idx);
  End;
  If fIdx = -1 Then fIdx := Listing.Count;

  For Idx := sIdx To fIdx -1 Do SP_DeleteLine(sIdx);

  // Take the remaining lines into a temporary storage ready to have the new lines merged in.

  OutList := TStringList.Create;

  Idx := 0;
  While Idx < Listing.Count Do Begin
    If (Not SP_WasPrevSoft(Idx)) And (SP_GetLineNumberFromText(Listing[Idx]) > 0) Then Begin
      Extents := SP_GetLineExtents(Idx);
      s := '';
      For nIdx := Extents.x To Extents.y Do Begin
        s := s + LongWordToString(Listing.Flags[nIdx].ReturnType) + LongWordToString(Listing.Flags[nIdx].Indent) + LongWordToString(Length(Listing[Extents.x])) + Listing[Extents.x];
        SP_DeleteLine(Extents.x);
      End;
      OutList.Add(s);
    End Else
      Inc(Idx);
  End;

  // Then we renumber them and make a note of their old and new line numbers for later on.

  SetLength(ChangeList, NewList.Count);
  CurLineNum := Line;

  For Idx := 0 To NewList.Count -1 Do Begin
    nIdx := 1;
    s := NewList[Idx];
    f := pLongWord(@s[1])^; // Returntype
    s := Copy(s, 5);
    i := pLongWord(@s[1])^; // Indent
    s := Copy(s, 5);
    kw := pLongWord(@s[1])^; // Length
    e := Copy(s, kw + 5);
    s := Copy(s, 5, kw);
    While s[nIdx] in ['0'..'9'] Do Inc(nIdx);
    ChangeList[Idx].Org := StringToLong(Copy(s, 1, nIdx -1));
    ChangeList[Idx].New := CurLineNum;
    ChangeList[Idx].Flag := f;
    ChangeList[Idx].Indent := i;
    s := IntToString(CurLineNum) + Copy(s, nIdx);
    NewList[Idx] := LongWordToString(f) + LongWordToString(i) + LongWordToString(Length(s)) + s + e;
    Inc(CurLineNum, Step);
  End;

  // Now, re-add the new lines back into the listing in order. This may overwrite other lines outside of the renumbering range,
  // but them's the breaks. First merge into the OutList, then expand them back into the main listing.

  For Idx := 0 To NewList.Count -1 Do Begin
    If (Idx = 0) or (pLongWord(@NewList[Idx -1][1])^ = spHardReturn) Then
      LineNum := SP_GetLineNumberFromText(Copy(NewList[Idx], 13))
    Else
      LineNum := 0;
    nIdx := 0;
    While nIdx < OutList.Count Do Begin
      If (Idx = 0) or (pLongWord(@NewList[Idx -1][1])^ = spHardReturn) Then
        CurLineNum := SP_GetLineNumberFromText(Copy(OutList[nIdx], 13))
      Else
        CurLineNum := 0;
      If CurLineNum > 0 Then
        If CurLineNum = LineNum Then Begin
          OutList[nIdx] := NewList[Idx];
          Break;
        End Else
          If CurLineNum > LineNum Then Begin
            OutList.Insert(nIdx, NewList[Idx]);
            Break;
          End;
      Inc(nIdx);
    End;
    If nIdx = OutList.Count Then
      OutList.Add(NewList[Idx]);
  End;

  // Now rebuild the main listing from the OutList.

  For Idx := 0 To OutList.Count -1 Do Begin
    s := OutList[Idx];
    While s <> '' Do Begin
      f := pLongWord(@s[1])^;
      s := Copy(s, 5);
      i := pLongWord(@s[1])^;
      s := Copy(s, 5);
      nl := pLongWord(@s[1])^;
      SP_AddLine(Copy(s, 5, nl), '', '');
      Listing.Flags[Listing.Count -1].ReturnType := f;
      Listing.Flags[Listing.Count -1].Indent := i;
      s := Copy(s, nl + 5);
    End;
  End;

  // Finally run through the remaining listing looking for keywords that reference lines - GO TO, GO SUB, RUN, RESTORE, LIST.

  InREM := False; InString := False;
  For Idx := 0 To Listing.Count -1 Do Begin
    nIdx := 1;
    s := Upper(Listing[Idx]);
    If Not SP_WasPrevSoft(Idx) And (SP_GetLineNumberFromText(s) > 0) Then Begin
      InREM := False;
      InString := False;
    End;
    While (nIdx < Length(s)) And Not InREM Do Begin
      While (nIdx < Length(s)) And (Not (s[nIdx] in ['A'..'Z']) or InString) Do Begin
        If s[nIdx] = '"' Then
          InString := Not InString;
        Inc(nIdx);
      End;
      w := '';
      While (nIdx < Length(s)) And (s[nIdx] in ['A'..'Z', ' ']) Do Begin
        If s[nIdx] = ' ' Then
          If w <> 'GO' Then Begin
            SP_SkipSpaces(s, nIdx);
            Break;
          End;
        w := w + s[nIdx];
        Inc(nIdx);
      End;
      w := StripSpaces(w);
      If (w = 'GOTO') or (w = 'GOSUB') or (w = 'RUN') or (w = 'RESTORE') or (w = 'LIST') Then Begin
        LineNum := 0;
        While (nIdx <= Length(s)) And (s[nIdx] <= ' ') Do Inc(nIdx); fIdx := nIdx;
        While (nIdx <= Length(s)) And (s[nIdx] in ['0'..'9']) Do Begin
          LineNum := (LineNum * 10) + Ord(s[nIdx]) - 48;
          Inc(nIdx);
        End;
        If LineNum > 0 Then Begin
          e := IntToString(LineNum);
          sIdx := 0;
          While sIdx < Length(ChangeList) Do Begin
            If ChangeList[sIdx].Org >= LineNum Then Begin
              LineNum := ChangeList[sIdx].New;
              Break;
            End;
            Inc(sIdx);
          End;
          If sIdx < Length(ChangeList) Then Begin
            w := IntToString(LineNum);
            s := Listing[Idx];
            s := Copy(s, 1, fIdx -1) + w + Copy(s, nIdx);
            Listing[Idx] := s;
            s := Upper(s);
            Inc(nIdx, Length(w) - Length(e));
          End;
        End;
      End Else
        If w = 'REM' Then
          InREM := True;
    End;
  End;

  // Finally, recreate all the syntax highlighting and flag the whole listing to be re-compiled.

  For Idx := 0 To Listing.Count -1 Do Begin
    SP_FPApplyHighlighting(Idx);
    SP_MarkAsDirty(Idx);
  End;

  Listing.CompleteUndo;
  CompilerLock.Leave;

  // All done!

  SetLength(ChangeList, 0);
  NewList.Free;
  OutList.Free;

End;

Procedure SP_FPDeleteLines(Start, Finish: Integer; var Error: TSP_ErrorCode);
Var
  LineNum, Idx, ProgLen: Integer;
  NeedStart, NeedFinish: Boolean;
Begin

  CompilerLock.Enter;
  SP_DeleteIncludes;

  If (Start > Finish) Then Begin
    Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    Exit;
  End;

  SP_ReOrderListing(Error);
  If Error.Code <> SP_ERR_OK Then Begin
    CompilerLock.Leave;
    Exit;
  End;

  NeedStart := True;
  NeedFinish := True;

  For Idx := 0 To Listing.Count -1 Do Begin

    If Not SP_WasPrevSoft(Idx) Then
      LineNum := SP_GetLineNumberFromText(Listing[Idx])
    Else
      LineNum := 0;
    If LineNum > 0 Then Begin
      If NeedStart Then
        If LineNum >= Start then Begin
          Start := LineNum;
          NeedStart := False;
        End;
      If NeedFinish Then
        If LineNum >= Finish Then Begin
          Finish := LineNum;
          NeedFinish := False;
        End;
    End;

  End;

  If NeedFinish Then
    Finish := LineNum;

  Idx := 0;
  Listing.CommenceUndo;
  While Idx < Listing.Count Do Begin
    If Not SP_WasPrevSoft(Idx) Then
      LineNum := SP_GetLineNumberFromText(Listing[Idx])
    Else
      LineNum := 0;
    If (LineNum >= Start) And (LineNum <= Finish) Then Begin
      SP_DeleteLine(Idx);
      While (Idx < Listing.Count) And (SP_LineHasNumber(Idx) = 0) Do
        SP_DeleteLine(Idx);
    End Else
      Inc(Idx);
  End;
  Listing.CompleteUndo;

  CompilerLock.Leave;

End;

Procedure SP_FPMergeLines(Start, Finish: Integer; var Error: TSP_ErrorCode);
Var
  LineNum, Idx, ProgLen, sIdx, nIdx: Integer;
  NeedStart, NeedFinish: Boolean;
  s: aString;
Begin

  CompilerLock.Enter;
  Listing.CommenceUndo;
  SP_DeleteIncludes;

  If (Start > Finish) Then Begin
    Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    Exit;
  End;

  SP_ReOrderListing(Error);
  If Error.Code <> SP_ERR_OK Then Begin
    CompilerLock.Leave;
    Exit;
  End;

  NeedStart := True;
  NeedFinish := True;

  For Idx := 0 To Listing.Count -1 Do Begin

    If Not SP_WasPrevSoft(Idx) Then
      LineNum := SP_GetLineNumberFromText(Listing[Idx])
    Else
      LineNum := 0;
    If LineNum > 0 Then Begin
      If NeedStart Then
        If LineNum >= Start then Begin
          Start := LineNum;
          NeedStart := False;
        End;
      If NeedFinish Then
        If LineNum >= Finish Then Begin
          Finish := LineNum;
          NeedFinish := False;
        End;
    End;

  End;

  If NeedFinish Then
    Finish := LineNum;

  s := '';
  Idx := 0;
  sIdx := -1;
  While Idx < Listing.Count Do Begin
    If Not SP_WasPrevSoft(Idx) Then
      LineNum := SP_GetLineNumberFromText(Listing[Idx])
    Else
      LineNum := 0;
    If (LineNum >= Start) And (LineNum <= Finish) Then Begin
      If sIdx = -1 Then sIdx := Idx;
      If (Idx <> sIdx) And Not SP_WasPrevSoft(Idx) Then Begin
        Listing[Idx -1] := Listing[Idx -1] + ':';
        s := Listing[Idx];
        nIdx := 1;
        While s[nIdx] in ['0'..'9'] Do
          Inc(nIdx);
        s := Copy(s, nIdx);
        Listing[Idx] := s;
      End Else
        Inc(Idx);
    End Else
      If LineNum > Finish Then
        Break
      Else
        Inc(Idx);
  End;

  SP_MarkWholeProgramDirty;
  Listing.CompleteUndo;
  CompilerLock.Leave;

End;

Procedure SP_SetBracketPositions(c: aChar; Line, CPos: Integer);
Var
  s: aString;
  srch: aChar;
  LineMin, mn, cnt, ocp, offset, i, j, b1, b2, bl1, bl2: Integer;
  Done, InString, InREM: Boolean;
Const
  searches: array[0..5] of aChar = (')', '(', ']', '[', '}', '{');
Begin

  srch := searches[Pos(c, '()[]{}') -1];
  Done := False;

  s := '';
  mn := Line;
  While (mn > 0) And (SP_LineHasNumber(mn) = 0) Do Dec(mn);
  LineMin := mn;
  Repeat
    s := s + Listing[mn];
    If mn < Line Then
      CPos := CPos + Length(Listing[mn]);
    Inc(mn);
  Until (mn = Listing.Count) or (SP_LineHasNumber(mn) > 0);

  offset := CPos - oCP;

  b1 := CPos;
  bl1 := Line;
  b2 := -1;

  If srch in ['(', '[', '{'] Then Begin // Search backwards

    cnt := 0;
    i := CPos -1;
    While i > 0 Do Begin
      If s[i] = c Then
        Inc(cnt)
      Else
        If s[i] = srch Then Begin
          Dec(cnt);
          If cnt = -1 Then Begin
            b2 := i;
            Break;
          End;
        End;
      Dec(i);
    End;

  End Else Begin // ...Or forwards

    Cnt := 0;
    i := CPos +1;
    While i <= Length(s) Do Begin
      If s[i] = c Then
        Inc(cnt)
      Else
        If s[i] = srch Then Begin
          Dec(cnt);
          If cnt = -1 Then Begin
            b2 := i;
            Break;
          End;
        End;
      Inc(i);
    End;

  End;

  if b2 > -1 Then Begin
    i := LineMin;
    j := 0;
    While j < b2 Do Begin
      Inc(j, Length(Listing[i]));
      Inc(i);
    End;
    bl2 := i - 1;
  End Else Begin
    b1 := -1; b2 := -1;
    bl1 := 0; bl2 := 0;
  End;

  FPBracket1Pos := Min(b1, b2);
  FPBracket2Pos := Max(b1, b2);
  FPBracket1Line := Min(bl1, bl2);
  FPBracket2Line := Max(bl1, bl2);

End;

Procedure SP_RefreshCursorLineAfterChange(OldLine: Integer);
Var
  OldPt, NewPt: TPoint;
  Idx: Integer;
Begin
  If OldLine <> Listing.FPCLine Then Begin
    OldPt := SP_GetLineExtents(OldLine, True);
    NewPt := SP_GetLineExtents(Listing.FPCLine, true);
    If OldPt.x <> NewPt.x Then Begin
      For Idx := OldPt.x To OldPt.Y Do
        AddDirtyLine(Idx);
      For Idx := NewPt.X To NewPt.Y Do
        AddDirtyLine(Idx);
    End;
    AddDirtyLine(OldLine);
  End;
  AddDirtyLine(Listing.FPCLine);
End;

Procedure SP_FPGotoLine(line, statement: Integer);
Var
  Found: TPoint;
  Error: TSP_ErrorCode;
Begin

  If FocusedWindow = fwDirect Then Begin
    SP_FPBringToEditor(line, statement, Error);
    SP_ScrollInView;
    DWSelP := CURSORPOS;
  End Else Begin
    Found := SP_FindFPLineStatement(line, statement);
    Listing.FPCLine := Found.Y;
    Listing.FPCPos := Found.X;
    While Listing[Listing.FPCLine][Listing.FPCPos] <= ' ' Do Listing.FPCPos := Listing.FPCPos +1;
    Listing.FPSelLine := Listing.FPCLine;
    Listing.FPSelPos := Listing.FPCPos;
    FPCDes := Listing.FPCPos;
    FPCDesLine := Listing.FPCLine;
    SP_CursorPosChanged;
    If FPWindowID >= 0 Then Begin
      SP_DisplayFPListing(-1);
      SP_CalculateFPCursorPos;
      SP_ScrollInView;
    End;
  End;

End;

Procedure StartFileOp(Operation: Integer; Filename: aString);
Var
  Error: TSP_ErrorCode;
Begin

  Case Operation of
    SP_KW_LOAD:
      Begin
        Filename := OpenFileReq('Load program', PROGNAME, False, Error);
        If Filename <> '' Then
          AddControlMsg(clInterpretCommand, 'LOAD "'+Filename+'"');
      End;
    SP_KW_SAVE:
      Begin
        If FILENAMED Then Begin
          // Save the file
          AddControlMsg(clInterpretCommand, 'SAVE "'+Filename+'"');
        End Else Begin
          // Save using the File requester
          Filename := OpenFileReq('Save program', PROGNAME, True, Error);
          If Filename <> '' Then
            AddControlMsg(clInterpretCommand, 'SAVE "'+Filename+'"');
        End;
      End;
    SP_KW_MERGE:
      Begin
        Filename := OpenFileReq('Merge program', PROGNAME, False, Error);
        If Filename <> '' Then
          AddControlMsg(clInterpretCommand, 'MERGE "'+Filename+'"');
      End;
  End;

  SP_InvalidateWholeDisplay;

End;

Procedure StartBPEditOp(BPIndex: Integer; Bp: pSP_BreakPointInfo);
Var
  BPWindow: SP_BreakpointWindow;
Begin

  BPWindow := SP_BreakpointWindow.Create;
  If BPIndex = -1 Then Begin
    // New breakpoint
    If FocusedWindow = FWDirect Then
      BPWindow.Open(BpIndex, BP_Stop, PROGLINE, 1, 0, 'Add breakpoint', '')
    Else
      BPWindow.Open(BpIndex, BP_Stop, Listing.Flags[Listing.FPCLine].Line, Listing.Flags[Listing.FPCLine].Statement, 0, 'Add breakpoint', '');
  End Else Begin
    // Edit current breakpoint
    With Bp^ Do
      BPWindow.Open(BpIndex, bpType, Line, Statement, PassCount, 'Edit breakpoint', Condition);
  End;

End;

Procedure StartWatchOp(Index: Integer);
Var
  Error: TSP_ErrorCode;
  t: aString;
Begin

  If Index = -1 Then
    t := ''
  Else
    t := SP_WatchList[Index].Expression;

  Error.Code := SP_ERR_OK;
  GotoWindow := SP_TextRequester.Create;
  GotoWindow.Open('Create new watch', t, tkAnyExpression, False, Error);

  If FPGotoText <> '' Then Begin
    SP_AddWatch(Index, FPGotoText);
    SP_FillDebugPanel;
  End;

End;

Procedure StartGotoOp;
Var
  Error: TSP_ErrorCode;
  b: Boolean;
  l, s, Linetxt, StatementTxt: aString;
  line, statement: aFloat;
  i: Integer;
  Found: TPoint;
  searchOpt: SP_SearchOptions;
Begin

  GotoWindow := SP_TextRequester.Create;
  GotoWindow.Open('GO TO line or label', '', tkLineStatement, True, Error);

  i := 1;
  Found.y := -1;

  If Pos(':', FPGotoText) > 0 Then Begin
    LineTxt := Copy(FPGotoText, 1, Pos(':', FPGotoText) -1);
    StatementTxt := Copy(FPGotoText, Pos(':', FPGotoText) +1);
  End Else Begin
    LineTxt := FPGotoText;
    StatementTxt := '1';
  End;

  If LineTxt <> '' Then Begin

    l := SP_FPExecuteAnyExpression(LineTxt, Error);
    If Error.Code = SP_ERR_OK Then
      s := SP_FPExecuteAnyExpression(StatementTxt, Error);

    b := (Error.Code = SP_ERR_OK) and SP_GetNumber(l, i, line, True);
    i := 1;
    b := b And SP_GetNumber(s, i, statement, True);

    If Not b Then Begin
      searchOpt := [soForward, soCondenseSpaces];
      Found := SP_FindText('LABEL @'+FPGotoText, 0, 1, searchOpt);
      b := Found.y >= 0;
      If b Then Begin
        Line := Found.Y;
        Statement := Found.X;
      End;
    End;

    If b Then
      SP_FPGotoLine(Trunc(line), Trunc(Statement));

  End;

End;

Procedure StartFindOp(Find: Boolean);
Begin

  LastFindwasReplace := not Find;
  FindWindow := SP_FindReplace.Create;
  FindWindow.Open(Find);
  FindWindow.Free;

  If FPSearchTerm <> '' Then FindNext(True);

End;

Procedure FindNext(jumpNext: Boolean);
Var
  i, j, l, p, op: Integer;
  Sel: SP_SelectionInfo;
  Error: TSP_ErrorCode;
Label
  Wrap, LastOne;
Begin

  If Assigned(FindWindow) Then Begin

    SP_FindAll(FPSearchTerm, FPSearchOptions, Error);
    FPShowingSearchResults := True;

    j := -1;
    For i := 0 To Length(FPFindResults) -1 Do Begin
      If FPFindResults[i].Line <> j Then Begin
        SP_FPApplyHighlighting(FPFindResults[i].Line);
        AddDirtyLine(FPFindResults[i].Line);
      End;
      j := FPFindResults[i].Line;
    End;

    If soStart in FPSearchOptions Then Begin
      Listing.FPCLine := 0;
      Listing.FPCPos := 1;
    End;

    If Length(FPFindResults) > 0 Then Begin

      If jumpNext Then Begin
        op := PROGLINE;
        If soForward in FPSearchOptions Then Begin
          Wrap:
          For i := 0 To Length(FPFindResults) -1 Do
            If (FPFindResults[i].Line > Listing.FPCLine) or ((FPFindResults[i].Line = Listing.FPCLine) and (FPFindResults[i].Position > Listing.FPCPos)) Then Begin
              If ((FocusedWindow = fwDirect) And (SP_GetLineNumberFromIndex(FPFindResults[i].Line) = PROGLINE)) or
                 ((i > 0) and FPFindResults[i -1].Split) Then
                  Continue;
              SP_GetSelectionInfo(Sel);
              Listing.FPCLine := FPFindResults[i].Line;
              Listing.FPCPos := FPFindResults[i].Position;
              SP_FPClearSelection(Sel);
              FPCDes := Listing.FPCPos;
              FPCDesLine := Listing.FPCLine;
              Break;
            End;
          If Length(FPFindResults) > 0 Then
            If i = Length(FPFindResults) Then Begin
              Listing.FPCLine := 0;
              Listing.FPCPos := 1;
              Goto Wrap;
            End;
        End Else Begin
          i := 0;
          If (FPFindResults[i].Line > Listing.FPCLine) or ((FPFindResults[i].Line = Listing.FPCLine) and (FPFindResults[i].Position >= Listing.FPCPos)) Then
            Goto LastOne;
          While i < Length(FPFindResults) Do
            If (FPFindResults[i].Line >= Listing.FPCLine) or ((FPFindResults[i].Line = Listing.FPCLine) and (FPFindResults[i].Position >= Listing.FPCPos)) Then Begin
              If (i > 0) And FPFindResults[i -1].Split Then Continue;
              LastOne:
              SP_GetSelectionInfo(Sel);
              If i > 0 Then
                j := i -1
              Else
                j := Length(FPFindResults) -1;
              If (FocusedWindow = fwDirect) And (SP_GetLineNumberFromIndex(FPFindResults[j].Line) = PROGLINE) Then
                Inc(i)
              Else Begin
                Listing.FPCLine := FPFindResults[j].Line;
                Listing.FPCPos := FPFindResults[j].Position;
                SP_FPClearSelection(Sel);
                FPCDes := Listing.FPCPos;
                FPCDesLine := Listing.FPCLine;
                i := j;
                Break;
              End;
            End Else
              Inc(i);
          If i = Length(FPFindResults) Then Goto LastOne;
        End;
      End;

      // Do we need to replace? Current highlight is in i.

      If LastFindWasReplace Then Begin
        Listing.CommenceUndo;
        If soAll in FPSearchOptions Then Begin
          FPShowingSearchResults := False;
          i := 0;
          While i < Length(FPFindResults) Do
            PerformReplace(i);
        End Else
          PerformReplace(i);
        Listing.CompleteUndo;
      End;

      If FocusedWindow = fwDirect Then Begin
        i := Listing.FPCLine;
        PROGLINE := SP_GetLineNumberFromIndex(i);
        SP_ScrollInView(True);
        SP_DisplayFPListing(-1);
      End;

    End;

  End;

End;

Procedure PerformReplace(Var Idx: Integer);
Var
  j, p, l, l2, sl, diff, line, posn: Integer;
  old_opt: SP_SearchOptions;
  Error: TSP_ErrorCode;
  s: aString;
Begin

  diff := Length(FPReplaceTerm) - Length(FPSearchTerm);

  j := FPFindResults[idx].Line;
  p := FPFindResults[idx].Position;
  l := FPFindResults[idx].Length;
  If FPFindResults[idx].Split Then Begin
    l2 := FPFindResults[idx +1].Length;
    s := listing[j] + Listing[j +1];
    sl := Length(Listing[j]);
    s := Copy(s, 1, p -1) + FPReplaceTerm + Copy(s, p + l + l2);
    Listing[j] := Copy(s, 1, sl);
    Listing[j +1] := Copy(s, sl +1);
    SP_FPWordWrapLine(j);
  End Else Begin
    If (Idx > 0) And FPFindResults[Idx -1].Split Then Exit;
    Listing[j] := Copy(Listing[j], 1, p -1) + FPReplaceTerm + Copy(Listing[j], p + l);
    SP_FPWordWrapLine(j);
  End;

  // Need to re-do all the search results due to possible line length changes.

  old_opt := FPSearchOptions;
  FPSearchOptions := FPSearchOptions - [soStart] + [soCursorPos];
  line := Listing.FPCLine; Listing.FPCLine := j;
  Posn := Listing.FPCPos; Listing.FPCPos := FPFindResults[Idx].Position + Length(FPReplaceTerm);

  SP_FindAll(FPSearchTerm, FPSearchOptions, Error);

  FPSearchOptions := old_opt;
  Listing.FPCLine := line;
  Listing.FPCPos := posn;

  idx := 0;

End;

Procedure HideSearchResults;
Var
  i, j: Integer;
Begin

  If FPShowingSearchResults Then Begin

    j := -1;
    FPShowingSearchResults := False;
    For i := 0 To Length(FPFindResults) -1 Do Begin
      If FPFindResults[i].Line <> j Then Begin
        SP_FPApplyHighlighting(FPFindResults[i].Line);
        AddDirtyLine(FPFindResults[i].Line);
      End;
      j := FPFindResults[i].Line;
    End;

    SP_DisplayFPListing(-1);

  End;

End;

Procedure DWNewUndoEntry;
Begin

  Inc(DWUndoBufferPtr);
  If DWUndoBufferPtr >= DWUndoList.Count Then
    DWUndoList.SetCapacity(DWUndoList.Count + DWUndoBufferSize);

End;

Procedure DWStoreEditorState;
Var
  s: aString;
Begin

  If not DWUndoInProgress Then Exit;

  DWNewUndoEntry;
  DWUndoList[DWUndoBufferPtr] := LongWordToString(DWUndoGroup) + LongWordToString(CURSORPOS) + LongWordToString(DWSelP) + EDITLINE;

End;

Procedure DWCommenceUndo;
Begin

  If DWUndoInProgress Then DWCompleteUndo;

  Inc(DWUndoGroup);
  DWUndoInProgress := True;

End;

Procedure DWCompleteUndo;
Begin

  DWUndoInProgress := False;

End;

Procedure DWPerformUndo;
Var
  i, l, l2, j, sl: Integer;
  Ptr: pByte;
Begin

  If DWUndoBufferPtr >= 0 Then Begin

    j := DWUndoBufferPtr;
    i := pLongWord(@DWUndoList[j][1])^;

    DWCommenceRedo;
    DWStoreRedoEditorState;

    While (j >= 0) And (pLongWord(@DWUndoList[j][1])^ = i) Do Begin

      CURSORPOS := pLongWord(@DWUndoList[j][5])^;
      DWSelP := pLongWord(@DWUndoList[j][9])^;
      EDITLINE := Copy(DWUndoList[j], 13);
      Dec(j);

    End;

    DWUndoBufferPtr := j;
    DWCompleteRedo;

  End;

End;

Procedure DWNewRedoEntry;
Begin

  Inc(DWRedoBufferPtr);
  If DWRedoBufferPtr >= DWRedoList.Count Then
    DWRedoList.SetCapacity(DWRedoList.Count + DWRedoBufferSize);

End;

Procedure DWStoreRedoEditorState;
Var
  s: aString;
Begin

  If not DWRedoInProgress Then Exit;

  DWNewRedoEntry;
  DWRedoList[DWRedoBufferPtr] := LongWordToString(DWRedoGroup) + LongWordToString(CURSORPOS) + LongWordToString(DWSelP) + EDITLINE;

End;

Procedure DWCommenceRedo;
Begin

  If DWRedoInProgress Then DWCompleteRedo;

  Inc(DWRedoGroup);
  DWRedoInProgress := True;

End;

Procedure DWCompleteRedo;
Begin

  DWRedoInProgress := False;

End;

Procedure DWPerformRedo;
Var
  i, l, l2, j, sl: Integer;
  Ptr: pByte;
Begin

  If DWRedoBufferPtr >= 0 Then Begin

    j := DWRedoBufferPtr;
    i := pLongWord(@DWRedoList[j][1])^;

    DWCommenceUndo;
    DWStoreEditorState;

    While (j >= 0) And (pLongWord(@DWRedoList[j][1])^ = i) Do Begin

      CURSORPOS := pLongWord(@DWRedoList[j][5])^;
      DWSelP := pLongWord(@DWRedoList[j][9])^;
      EDITLINE := Copy(DWRedoList[j], 13);
      Dec(j);

    End;

    DWRedoBufferPtr := j;
    DWCompleteUndo;

  End;

End;


Function SP_CheckProgram: Boolean;
Var
  Idx, i: Integer;
  HasDirty, HasErrors: Boolean;
Label
  ErrorCheck;
Begin

  ErrorCheck:

  HasErrors := False;
  HasDirty := False;
  For Idx := 0 To Listing.Count -1 Do Begin

    HasErrors := HasErrors or (Listing.Flags[Idx].State in [spLineError, spLineDuplicate]);

    If Listing.Flags[Idx].State in [spLineDirty] Then Begin
      AddCompileLine(Idx);
      HasDirty := True;
    End;

    If HasErrors Then Begin
      Listing.FPCLine := Idx;
      i := 1;
      If Listing[Listing.FPCLine] <> '' Then
      While (i < Length(Listing[Listing.FPCLine])) And (Listing[Listing.FPCLine][i] in ['0'..'9', ' ']) Do
        Inc(i);
      Listing.FPCPos := i;
      Break;
    End;
  End;

  If HasDirty Then Begin
    CB_YIELD;
    Goto ErrorCheck;
  End;

  Result := Not HasErrors;

End;

Procedure SP_ShowError(Code, Line, Pos: Integer);
Var
  Error: TSP_ErrorCode;
Begin

  If FPWindowID >= 0 Then
    SP_CloseEditorWindows;

  Error.Code := Code;
  Error.Line := Line;
  Error.Statement := 1;
  PROGSTATE := SP_PR_STOP;
  SP_FPEditorError(Error, Line);
  SP_CreateEditorWindows;
  COVER := 0;
  T_OVER := 0;

End;

Procedure SP_FPSetDisplayColours;
Begin

  // Editor syntax highlighting colours.
  // IMPORTANT: The following are STRINGS, and are 3 (or more) sets of 5 BYTES. No more, no less.

  // #16 - INK
  // #17 - PAPER
  // #26 - ITALIC 0/1
  // #27 - BOLD 0/1

  // The four bytes following are a 32bit integer -
  // #7#0#0#0 is 7 - The first byte is the one you want to change.
  // In these examples, #26#0#0#0#0 will turn off ITALIC, #27#0#0#0#0 will turn off BOLD.
  // #26#1#0#0#0 will turn ITALIC on. etc.

  // #16#1#0#0#0 will make blue INK. #17#4#0#0#0 will make green PAPER.

  BackClr     := #17#7#0#0#0#26#0#0#0#0#27#0#0#0#0;    // Background colour
  noClr       := #16#0#0#0#0#27#0#0#0#0#26#0#0#0#0;    // No highlight - black ink, no bold, no italic
  kwdClr      := #16#0#0#0#0#27#1#0#0#0#26#0#0#0#0;    // Keyword
  fnClr       := #16#0#0#0#0#27#1#0#0#0#26#0#0#0#0;    // Function
  numClr      := #16#1#0#0#0#26#0#0#0#0#27#0#0#0#0;    // Decimal number
  hexClr      := #16#1#0#0#0#26#0#0#0#0#27#0#0#0#0;    // Hex value
  binClr      := #16#1#0#0#0#26#0#0#0#0#27#0#0#0#0;    // Binary number
  baseClr     := #16#1#0#0#0#26#0#0#0#0#27#0#0#0#0;    // Arbitrary base number
  strClr      := #16#32#0#0#0#26#0#0#0#0#27#0#0#0#0;   // String literal
  nvClr       := #16#2#0#0#0#26#0#0#0#0#27#0#0#0#0;    // Numeric variable
  svClr       := #16#3#0#0#0#26#0#0#0#0#27#0#0#0#0;    // String variable
  remClr      := #16#32#0#0#0#26#1#0#0#0#27#0#0#0#0;   // remark or comment
  constClr    := #16#3#0#0#0#26#0#0#0#0#27#0#0#0#0;    // Constant
  symClr      := #16#0#0#0#0#26#0#0#0#0#27#0#0#0#0;    // Symbol (: , ; ' etc)
  LinClr      := #16#0#0#0#0#26#0#0#0#0#27#0#0#0#0;    // Line number
  relClr      := #16#0#0#0#0#26#0#0#0#0#27#0#0#0#0;    // Rel-op
  mathClr     := #16#0#0#0#0#26#0#0#0#0#27#0#0#0#0;    // Math op
  labClr      := #16#1#0#0#0#26#1#0#0#0#27#0#0#0#0;    // Label
  SelClr      := #17#5#0#0#0#26#8#0#0#0#27#8#0#0#0;    // Selected text colour
  SearchClr   := #17#208#0#0#0#26#8#0#0#0#27#8#0#0#0;  // Search term highlight
  NoSearchClr := #28#0#0#0#0#26#8#0#0#0#27#8#0#0#0;    // End of search term
  BraceHltClr := #17#6#0#0#0#26#8#0#0#0#27#8#0#0#0;    // Bracket highlight - applies to ()[]
  BraceClr    := #16#1#0#0#0#26#0#0#0#0#27#1#0#0#0;    // Bracket colour, no highlight

  // These are just numbers, corresponding to entries in the default palette

  lineClr     := 249;                                  // Line highlight colour
  gutterClr   := 246;                                  // Gutter background colour
  paperClr    := 7;                                    // Editor background colour
  proglineClr := 5;                                    // PROGLINE colour for highlighted lines
  proglineGtr := 35;                                   // Colour for PROGLINE's gutter

  winBack     := 7;                                    // Default window background colour for dialogs etc
  capBack     := 228;                                  // Caption bar colour
  winBorder   := 0;                                    // Window border colour
  capText     := 15;                                   // Caption active text
  capInactive := 240;                                  // Caption inactive text
  gripClr     := 0;                                    // Text colour of the sizegrip for resizeable windows

  scrollback  := 7;                                    // Background colour of the scrollbar. Should be the same as the editor window background
  scrolltrack := 8;                                    // Colour of the "track" where the thumb sits
  scrollActive := 0;                                   // Colour of an active button
  scrollInactive := 8;                                 // Colour of a disabled button
  scrollThumb := 0;                                    // Colour of the scrollbar's "thumb" - the part you grab and move.

  debugPanel := 246;                                   // Colour of the debug panel's main list box
  debugCombo := 251;                                   // Colour of the debug panel's combobox
  debugNew   := 32;                                    // New variable in the debug panel
  debugChg   := 2;                                     // Changed variable in the debug panel

End;

// Debugging

Procedure SP_ToggleBreakPoint(Hidden: Boolean);
Var
  bpLine, bpSt, idx: Integer;
Begin

  // If editing, this toggles a breakpoint at the start of the current statement.
  // If in Direct mode, toggles a breakpoint at the first statement of PROGLINE

  If FocusedWindow = fwEditor Then Begin

    bpLine := Listing.Flags[Listing.FPCLine].Line;
    bpSt := Listing.Flags[Listing.FPCLine].Statement;
    idx := SP_GetLineIndex(bpLine);
    While Listing.Flags[idx].Statement < bpSt Do
      Inc(idx);

  End Else Begin

    bpLine := PROGLINE;
    bpSt := 1;
    idx := SP_GetLineIndex(bpLine);
    Idx := -1;

  End;

  SP_AddSourceBreakpoint(Hidden, bpLine, bpSt, 0, '');
  SP_DisplayFPListing(Idx);

End;

Function SP_IsSourceBreakPoint(Line, Statement: Integer): Boolean;
Var
  Idx: Integer;
Begin

  Idx := 0;
  Result := False;
  While Idx < Length(SP_SourceBreakpointList) Do
    If (SP_SourceBreakpointList[Idx].Line = Line) And (SP_SourceBreakpointList[Idx].Statement = Statement) And (SP_SourceBreakpointList[Idx].bpType <> BP_IsHidden) Then Begin
      Result := True;
      Exit;
    End Else
      Inc(Idx);

End;

Procedure SP_ResetConditionalBreakPoints;
Var
  i: Integer;
  res: aString;
  Error: TSP_ErrorCode;
Begin

  For i := 0 To Length(SP_ConditionalBreakPointList) -1 Do Begin
    SP_ConditionalBreakPointList[i].PassCount := SP_ConditionalBreakPointList[i].PassNum;
    res := SP_FPExecuteAnyExpression(SP_ConditionalBreakPointList[i].Compiled_Condition, Error);
    If Error.Code = SP_ERR_OK Then Begin
      SP_ConditionalBreakPointList[i].HasResult := True;
      SP_ConditionalBreakPointList[i].CurResult := res;
    End Else
      SP_ConditionalBreakPointList[i].HasResult := False;
  End;

End;

Procedure SP_PrepareBreakpoints(Create: Boolean);
Var
  i, j, l, Idx, stIdx, LineNum, Statement, StatementListPos, numStatements: Integer;
  Error: TSP_ErrorCode;
  Tokens: paString;
  Token: pToken;
  res: aString;
Begin

  If Create Then Begin

    For i := 0 To Length(SP_SourceBreakpointList) -1 Do Begin

      LineNum := SP_SourceBreakpointList[i].Line;
      Statement := SP_SourceBreakpointList[i].Statement;

      Idx := SP_FindLine(LineNum, True);
      Tokens := @SP_Program[Idx];
      stIdx := SP_FindStatement(Tokens, Statement);
      Token := @Tokens^[stIdx];
      Token^.BPIndex := i;
      SP_SourceBreakpointList[i].PassCount := SP_SourceBreakpointList[i].PassNum;

    End;

  End Else Begin

    For i := 0 To SP_Program_Count -1 Do Begin

      Tokens := @SP_Program[i];

      Idx := 1;
      If Tokens^[Idx] = aChar(SP_LINE_NUM) Then Begin
        Inc(Idx);
        LineNum := pLongWord(@Tokens^[Idx])^;
        Inc(Idx, SizeOf(LongWord));
      End;
      If Tokens^[Idx] = aChar(SP_STATEMENTS) Then Begin
        StatementListPos := Idx + 1 + SizeOf(LongWord);
        numStatements := pLongWord(@Tokens^[Idx +1])^;
      End;

      For Statement := 1 To numStatements Do Begin

        stIdx := pLongWord(@Tokens^[StatementListPos + ((Statement -1) * SizeOf(LongWord))])^;
        Token := pToken(@Tokens^[stIdx]);

      End;

    End;

    // Also remove hidden breakpoints from the list.

    l := Length(SP_SourceBreakpointList);
    i := 0;
    While i < l Do Begin
      If SP_SourceBreakpointList[i].bpType = BP_IsHidden Then Begin
        For j := i To l -2 Do
          SP_SourceBreakpointList[j] := SP_SourceBreakpointList[j +1];
        Dec(l);
        SetLength(SP_SourceBreakpointList, l);
      End Else
        Inc(i);
    End;

  End;

  SP_GetDebugStatus;

End;

Procedure SP_SingleStep;
Var
  Info: TSP_iInfo;
  Inf: pSP_iInfo;
  Tokens: paString;
  Position, Line, Statement: Integer;
  Error: TSP_ErrorCode;
  Token: pToken;
Label
  WasActuallyAnError;
Begin

  // Set the BPSIGNAL to true, so the first statement will be executed and then terminate back to the
  // editor. Also set STEPMODE so the interpreter knows not to stop with an error.          after step/step over/bp triggered, show continue statement as gray text in direct window

  SP_SwitchFocus(fwDirect);
  STEPMODE := SM_Single;
  SP_GetDebugStatus;

  Listing.CompleteUndo;
  If Assigned(CompilerThread) Then SP_StopCompiler;
  inf := @Info;
  Error.Code := SP_ERR_OK;
  Error.ReturnType := 0;
  Info.Error := @Error;

  PROGSTATE := SP_PR_RUN;
  SP_DisplayFPListing(-1);
  SP_WaitForSync;

  SP_Preparse(False, Error);
  SP_Interpret_CONTINUE(Inf);
  If Error.Code = SP_ERR_OK Then Begin
    Tokens := nil;
    Position := 0;
    BPSIGNAL := True;
    Error.ReturnType := 0;
    Error.Code := SP_ERR_OK;
    SP_SetDrawingWindow(FPEditorDefaultWindow);
    LASTKEY := 0;
    SP_ClearKeyBuffer(True);
    SP_Interpreter(Tokens, Position, Info.Error^, 0, True);
    SP_ClearKeyBuffer(True);
    FPEditorDefaultWindow := SCREENBANK;
    FPEditorDRPOSX := DRPOSX;
    FPEditorDRPOSY := DRPOSY;
    FPEditorPRPOSX := PRPOSX;
    FPEditorPRPOSY := PRPOSY;
    FPEditorOVER := COVER;
    FPEditorSaveFPS := FPS;
    FPEditorFRAME_MS := FRAME_MS;
    FPEditorMouseStatus := MOUSEVISIBLE;
    LASTKEY := 0;
    If STEPMODE > 0 Then
      If FocusedWindow = fwEditor then
        SP_SetDrawingWindow(FPWindowID)
      else
        SP_SetDrawingWindow(DWWindowID);
    SP_PrepareBreakpoints(False);
  End;
  STEPMODE := 0;
  SP_GetDebugStatus;
  SCREENLOCK := False;
  PROGSTATE := SP_PR_STOP;
  SYSTEMSTATE := SS_DIRECT;
  If CONTSTATEMENT = 0 Then
    Inc(CONTSTATEMENT);
  If (Error.Code <> SP_ERR_BREAKPOINT) And (Error.Code <> SP_ERR_OK) Then Begin
    WasActuallyAnError:
    If Error.Code = SP_ERR_STATEMENT_LOST Then Begin
      Error.Line := -1;
      Error.Statement := 0;
    End;
    If FPWindowID >= 0 Then SP_CloseEditorWindows;
    SP_FPEditorError(Error);
    SP_CreateEditorWindows;
  End Else Begin
    If (CONTLINE = -1) or (CONTLINE >= SP_Program_Count) or (SP_Program[CONTLINE] = '') Then
      Goto WasActuallyAnError;
    PROGLINE := pLongWord(@SP_Program[CONTLINE][2])^;
    If FPWindowID = -1 Then SP_CreateEditorWindows;
    SP_FPScrollToLine(pLongWord(@SP_Program[CONTLINE][2])^, CONTSTATEMENT);
  End;

  SP_Reset_Temp_Colours;
  SP_FillDebugPanel;

  If Not Assigned(CompilerThread) Then
    CompilerThread := TCompilerThread.Create(False);

End;

Function SP_StepOver: Boolean;
Var
  line: TSP_GOSUB_Item;
Begin

  SP_SwitchFocus(fwDirect);
  STEPMODE := SM_StepOver;
  PROGSTATE := SP_PR_RUN;
  SP_DisplayFPListing(-1);
  SP_WaitForSync;

  line := SP_ConvertLineStatement(CONTLINE, CONTSTATEMENT +1);
  If Line.Line >= 0 Then Begin
    SP_AddSourceBreakpoint(True, pLongWord(@SP_Program[line.Line][2])^, Line.St, 0, '');
    Result := True;
  End Else
    Result := False;
  SP_ClearKeyBuffer(True);
  LASTKEY := 0;
  SP_GetDebugStatus;

End;

Procedure SP_FPScrollToLine(Line, Statement: Integer);
Var
  fp: TPoint;
Begin
  fp := SP_FindFPLineStatement(Line, Statement);
  If fp.x > -1 Then Begin
    Listing.FPCLine := fp.x;
    Listing.FPCPos := fp.y;
    Listing.FPSelLine := Listing.FPCLine;
    Listing.FPSelPos := Listing.FPCPos;
    FPCDes := Listing.FPCPos;
  End Else Begin
    Listing.FPCLine := 0;
    Listing.FPCPos := 1;
    Listing.FPSelLine := Listing.FPCLine;
    Listing.FPSelPos := Listing.FPCPos;
    FPCDes := Listing.FPCPos;
  End;
  FPCDesLine := Listing.FPCLine;
  SP_CursorPosChanged;
  SP_DisplayFPListing(-1);
  SP_ScrollInView;
  PROGLINE := Line;
  SHOWLIST := True;
End;

Procedure SP_ClearBreakPoints;
Begin

  SP_PrepareBreakPoints(False);
  SetLength(SP_SourceBreakpointList, 0);
  SetLength(SP_ConditionalBreakpointList, 0);
  BPSIGNAL := False;
  STEPMODE := 0;
  SP_GetDebugStatus;

End;

Procedure SP_GetDebugStatus;
Begin

  DEBUGGING := (Length(SP_SourceBreakpointList) > 0) or (Length(SP_ConditionalBreakpointList) > 0) or (STEPMODE > 0);
  SP_FillDebugPanel;

End;

Initialization

  BSize := 8;

end.
