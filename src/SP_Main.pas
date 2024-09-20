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

unit SP_Main;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}

{

  The main loop of the interpreter and editor. This should be run as a low-priority
  thread separate from the main app (vcl) thread. This is to allow a 50hz (20ms)
  keyboard poll via the message queue.

}

interface

Uses

  Math, Classes, SysUtils, SP_Graphics32,
  SP_Graphics, SP_SysVars, SP_Input, SP_Errors, SP_Util, SP_Tokenise,
  SP_InfixToPostFix, SP_Interpret_PostFix, SP_Variables, SP_BankManager,
  SP_FileIO, SP_Sound, SP_Editor, SP_PreRun, SyncObjs;

Type

  TCB_YieldProc = Procedure;
  TCB_MsgProc = Procedure;
  TCB_QuitProc = Procedure;
  TCB_GetTicks = Function: aFloat;
  TCB_GetAxis = Function(NubID, Axis: Integer): Integer;
  TCB_InitSticks = Procedure;
  TCB_ReleaseSticks = Procedure;
  TCB_MouseMove = Procedure(ToX, ToY: integer);
  TCB_CAPTIONPROC = Procedure;
  TCB_GeneralProc = Procedure;

Function  SP_FrameUpdate: Boolean;
Procedure DoAutoSave(SaveOLD: Boolean = False);
Procedure SP_MainLoop;
Procedure SP_CleanUp;
Function  SP_TestScroll(Height: Integer; var Error: TSP_ErrorCode): Boolean;
Function  SP_FindLine(LineNum: Integer; Exact: Boolean): Integer;
Function  SP_FindStatement(Tokens: paString; Statement: Integer): Integer;
Function  SP_GetStatementFromOffset(Line, Offset: Integer): Integer;
Procedure SP_StackLine(Line, Statement, St, Source: Integer; Var Error: TSP_ErrorCode);
Function  SP_ConvertLineStatement(Line, Statement: Integer): TSP_GOSUB_Item;
Procedure SP_AddLabel(const LabelText: aString; Line, Statement, St, DLine, DStatement, Dst: Integer);
Function  SP_FindLabel(const LabelText: aString; Var Error: TSP_ErrorCode): TSP_Label;
Procedure SP_ClearLabels;
Function  SP_LIST(Start, Finish: Integer): aString;
Procedure SP_SetFPS(Value: aFloat);
Function  SP_GetLineNumber(Index: Integer): Integer;

Var

  CB_SETWINDOWCAPTION: TCB_CAPTIONPROC;
  CB_Messages: TCB_MsgProc;
  CB_Yield: TCB_YieldProc;
  CB_Quit: TCB_QuitProc;
  CB_GetTicks: TCB_GetTicks;
  CB_GetAxis: TCB_GetAxis;
  CB_InitSticks: TCB_InitSticks;
  CB_ReleaseSticks: TCB_ReleaseSticks;
  CB_MouseMove: TCB_MouseMove;
  CB_PauseDisplay, CB_ResumeDisplay: TCB_GeneralProc;
  SP_GOSUB_Stack: Array of TSP_GOSUB_Item;
  SP_GOSUB_StackPtr,
  SP_GOSUB_StackLen,
  AutoFrameCount: Integer;
  SP_LabelList: Array of TSP_Label;
  SP_Interpreter_Ready: Boolean = False;
  CauseUpdate: Boolean = False;
  FrameElapsed: Boolean = False;
  TerminateInterpreter: Boolean = False;
  SP_KeyWordID: LongWord;
  DisplaySection: TCriticalSection;

implementation

Uses SP_Package;

Procedure SP_SetFPS(Value: aFloat);
Begin

  FPS := Value;
  FRAME_MS := 1000/FPS;
  AUTOSAVETIME := Round(FPS * 30);
  FLASHINTERVAL := Max(2, Trunc(0.32*FPS));
  REPDEL := Max(5, Trunc((20/50)*FPS));
  REPPER := Max(1, Trunc((2/50)*FPS));
  FCM := Ceil(FPS/2);
  FC := FCM;

End;

Function SP_FrameUpdate: Boolean;
Var
  OldFlashState: Integer;
Begin

  // Changes the FLASH sysvar once every 16 frames.

  SP_NeedDisplayUpdate := (SCMINX < SCMAXX) or SP_NeedDisplayUpdate;
  OldFlashState := FLASHSTATE;
  FLASHSTATE := Ord((FRAMES Mod (FLASHINTERVAL * 2)) > FLASHINTERVAL);
  FLASHFRAME := OldFlashState <> FLASHSTATE;
  If (SYSTEMSTATE in [SS_EDITOR, SS_DIRECT, SS_INPUT]) And FLASHFRAME Then
    SP_NeedDisplayUpdate := True;
  Result := (NUMSPRITES > 0) or SP_NeedDisplayUpdate;

End;

Procedure DoAutoSave(SaveOLD: Boolean = False);
Var
  Error: TSP_ERRORCODE;
Begin
  If AUTOSAVE And Not PAYLOADPRESENT Then Begin
    FileSection.Enter;
    Error.Code := SP_ERR_OK;
    SP_SaveProgram('s:autosave', -1, Error);
    If SaveOld Then
      SP_SaveProgram('s:oldprog', -1, Error);
    FileSection.Leave;
  End;
End;

Procedure SP_MainLoop;
Var
  Error: TSP_ErrorCode;
  tStr: aString;
Begin

  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);

  HARDWARE := 'PC Windows/x86';

  {$IFDEF FPC}
  HARDWARE := 'PC Linux/x86';
  {$ENDIF}

  {$IFDEF PANDORA}
  HARDWARE := 'Pandora Linux/ARM';
  {$ENDIF}

  {$IFDEF RASPI}
  HARDWARE := 'Pi Linux/ARM';
  {$ENDIF}

  NEWPROGNAME := 'New program';

  SetLength(SP_Program, 0);
  SP_Program_Count := 0;
  SetLength(SP_GOSUB_Stack, 0);
  SP_GOSUB_STACKPTR := 0;
  SP_GOSUB_STACKLEN := 1024;
  SetLength(SP_GOSUB_STACK, SP_GOSUB_STACKLEN);
  tStr := '';
  SP_PreParse(True, True, Error, tStr);

  MATHMODE := 0;
  AutoFramecount := 0;

  Randomize;

  BREAKSIGNAL := False;
  BPSIGNAL := False;
  INTSCALING := False;
  ANIMSPEED := 150;
  FLASHSTATE := 0;
  FRAMES := 0;
  LASTFRAME := FRAMES;
  INSERT := True;
  CURSORX := -FONTWIDTH;
  CURSORCHAR := 32;
  PRPOSX := 0;
  PRPOSY := 0;
  DRPOSX := 0;
  DRPOSY := 0;
  DRHEADING := 0;
  EDTABSIZE := 3;
  SHOWLINE := 0;
  PROGLINE := 0;
  QUITMSG := FALSE;
  LISTWINDOW := -1;
  COMMANDWINDOW := -1;
  PROGNAME := NEWPROGNAME;
  FILENAMED := False;
  FDIST := 300;
  EDFONTSCALEX := 1;
  EDFONTSCALEY := 1;
  LASTMENU := -1;
  LASTMENUITEM := -1;

  ERROR_LineNum := -1;

  // Set up the initial copyright message.

  SP_CLS(CPAPER);

  If Not PAYLOADPRESENT Then Begin
    SP_MakeDir('SYS:s', Error);
    SP_MakeDir('SYS:fonts', Error);
    SP_MakeDir('SYS:keyboards', Error);
    SP_MakeDir('SYS:include', Error);
  End;

  SetLength(SP_Ass_List, 6);
  SP_Ass_List[0] := 'SYS'#255'/';
  SP_Ass_List[1] := 'TEMP'#255'/temp/';

  If Not PAYLOADPRESENT Then Begin
    SP_ASS_LIST[2] := 'S'#255'/s/';
    SP_ASS_LIST[3] := 'FONTS'#255'/fonts/';
    SP_ASS_LIST[4] := 'KEYBOARDS'#255'/keyboards/';
    SP_ASS_LIST[5] := 'INCLUDE'#255'/include/';
  End;

  SP_MakeSystemSounds;
  SIGSAMPLEBANK := -1;
  SP_SetCurrentDir('SYS:', Error);

  SP_ConvertToOrigin_d(PRPOSX, PRPOSY);
  SP_ConvertToOrigin_d(DRPOSX, DRPOSY);

  SP_EditLoop(Error);

  AUTOSAVE := False;
  SP_CleanUp;
  SP_DeleteAllBanks(True);

End;

Procedure SP_CleanUp;
Begin

  DisplaySection.Enter;
  SP_DeleteIncludes;
  If PackageIsOpen Then SP_ClosePackage;
  SetLength(SP_Program, 0);
  SP_Program_Count := 0;
  SP_DeleteTempFiles;
  SP_DeleteAllWindows;
  SP_DeleteAllBanks(True);
  DisplaySection.Leave;

End;

Function SP_TestScroll(Height: Integer; var Error: TSP_ErrorCode): Boolean;
Var
  Key: pSP_KeyInfo;
Begin

  Result := False;
  If SCREENBANK < 0 Then Exit; // Don't do this if the surface is a graphic.

  Dec(SCROLLCNT);
  Result := True;
  CONTLINE := Error.Line;
  CONTSTATEMENT := Error.Statement;

  If SCROLLCNT <= 0 Then Begin

    SCROLLCNT := (SCREENHEIGHT Div Height) -1;
    SP_CLS_Lower(CPAPER);
    If SCREENBPP = 8 Then
      SP_TextOut(-1, 2, SCREENHEIGHT - 2 - Height, 'Scroll?', CINK, CPAPER, True)
    Else
      SP_TextOut32(-1, 2, SCREENHEIGHT - 2 - Height, 'Scroll?', CINK, CPAPER, True);
    SP_ForceScreenUpdate; // Make sure the message is shown

    Key := Nil;
    LASTKEYFLAG := 0;
    While Not Assigned(Key) And not QUITMSG Do Begin
      key := SP_GetNextKey(FRAMES);
      SP_WaitForSync;
    End;

    If QUITMSG Then Exit;
    SP_Restore_Lower;

    If Key^.KeyCode in [K_N, K_Space, K_Escape] Then
      Result := False
    Else Begin
      Result := True;
      SP_Scroll(Height);
      SP_WaitForSync;
    End;

  End Else Begin
    SP_Scroll(Height);
    SP_WaitForSync;
  End;

  SP_NeedDisplayUpdate := True;

End;

Function SP_GetLineNumber(Index: Integer): Integer;
Begin

  If (Index < SP_Program_Count) And (SP_Program[Index] <> '') Then
    Result := pInteger(@SP_Program[Index][2])^
  Else
    Result := -10;

End;

Function SP_FindLine(LineNum: Integer; Exact: Boolean): Integer;
Begin

  If PROGCHANGED Then Begin
    Result := 0;
    While Result < SP_Program_Count Do Begin
      If Exact Then Begin
        If pInteger(@SP_Program[Result][2])^ = LineNum Then
          Break;
      End Else
        If pInteger(@SP_Program[Result][2])^ >= LineNum Then
          Break;
      Inc(Result);
    End;
    If Result = SP_Program_Count Then
      Result := -1;
  End Else Begin
    If LineNum < Length(LineLUT) Then
      Result := LineLUT[LineNum]
    Else
      Result := -1;
  End;

End;

Function SP_FindStatement(Tokens: paString; Statement: Integer): Integer; Inline;
Var
  NumStatements: Integer;
  Idx: pByte;
Begin

  Idx := pByte(pNativeUInt(Tokens)^);

  If pByte(Idx)^ = SP_LINE_NUM Then
    Inc(Idx, 1 + SizeOf(LongWord));

  If pByte(Idx)^ = SP_STATEMENTS Then
    Inc(Idx);

  NumStatements := pLongWord(Idx)^;

  If Statement > NumStatements Then Begin
    Result := -1
  End Else Begin
    Inc(Idx, (Statement * SizeOf(LongWord)));
    Result := pLongWord(Idx)^;
  End;

End;

Function SP_GetStatementFromOffset(Line, Offset: Integer): Integer;
Var
  numStatements: Integer;
  ofs1, ofs2: LongWord;
  Tokens: paString;
  Idx: pByte;
Begin

  Tokens := @SP_Program[Line];
  if Assigned(Tokens) Then Begin
    Idx := pByte(pNativeUInt(Tokens)^);

    If pByte(Idx)^ = SP_LINE_NUM Then
      Inc(Idx, 1 + SizeOf(LongWord));

    If pByte(Idx)^ = SP_STATEMENTS Then
      Inc(Idx);

    NumStatements := pLongWord(Idx)^;
    Inc(Idx, SizeOf(LongWord));

    If NumStatements >= 1 Then Begin
      For Result := 1 To numStatements Do Begin
        ofs1 := pLongWord(Idx)^;
        If Result = numStatements Then
          ofs2 := Length(Tokens^)
        Else
          ofs2 := pLongWord(LongWord(Idx) + SizeOf(LongWord))^;
        If (LongWord(Offset) >= Ofs1) And (LongWord(Offset) < Ofs2) Then
          Exit;
        Inc(Idx, SizeOf(LongWord));
      End;
    End Else
      Result := 1;
  End Else
    Result := -1;

End;

Procedure SP_StackLine(Line, Statement, St, Source: Integer; Var Error: TSP_ErrorCode);
Begin

  Inc(SP_GOSUB_STACKPTR);
  If SP_GOSUB_STACKPTR >= SP_GOSUB_STACKLEN Then Begin
    If SP_GOSUB_STACKLEN < 131072 Then Begin
      Inc(SP_GOSUB_STACKLEN);
      SetLength(SP_GOSUB_STACK, SP_GOSUB_STACKLEN);
    End Else Begin
      Error.Code := SP_ERR_OUT_OF_MEMORY;
      SP_GOSUB_STACKPTR := 0;
      SP_GOSUB_STACKLEN := 1024;
      SetLength(SP_GOSUB_STACK, SP_GOSUB_STACKLEN);
      NXTLINE := -1;
      Exit;
    End;
  End;

  SP_GOSUB_STACK[SP_GOSUB_STACKPTR -1].Line := Line;
  SP_GOSUB_STACK[SP_GOSUB_STACKPTR -1].Statement := Statement;
  SP_GOSUB_STACK[SP_GOSUB_STACKPTR -1].St := St;
  SP_GOSUB_STACK[SP_GOSUB_STACKPTR -1].Source := Source;

End;

Function SP_ConvertLineStatement(Line, Statement: Integer): TSP_GOSUB_Item;
Begin

  If Line > -1 Then Begin
    If Line < SP_Program_Count Then Begin
      Result.Line := Line;
      Result.Statement := SP_FindStatement(@SP_Program[Line], Statement);
      If Result.Statement = -1 Then Begin
        Inc(Result.Line);
        If Result.Line >= SP_Program_Count Then
          Result.Line := -1
        Else Begin
          Result.Statement := SP_FindStatement(@SP_Program[Result.Line], 1);
          Statement := 1;
          If Result.Line = SP_Program_Count Then
            Result.Line := -1;
        End;
      End;
    End Else Begin
      Result.Line := -1;
      Result.Statement := -1;
    End;
  End Else Begin
    Result.Line := -1;
    Result.Statement := -1;
  End;
  Result.St := Statement;

End;

Procedure SP_AddLabel(const LabelText: aString; Line, Statement, St, DLine, DStatement, Dst: Integer);
Var
  Idx: Integer;
Begin

  Idx := 0;
  While Idx < Length(SP_LabelList) Do Begin
    If SP_LabelList[Idx].Name = Lower(LabelText) Then
      Break;
    Inc(Idx);
  End;

  If Idx = Length(SP_LabelList) Then
    SetLength(SP_LabelList, Length(SP_LabelList)+1);

  If Line = -1 Then Begin
    Line := DLine;
    St := DSt;
    Statement := DStatement;
  End;

  SP_LabelList[Idx].Name := Lower(LabelText);
  SP_LabelList[Idx].Line := Line;
  SP_LabelList[Idx].Statement := Statement;
  SP_LabelList[Idx].St := St;

  SP_LabelList[Idx].DLine := DLine;
  SP_LabelList[Idx].DStatement := DStatement;
  SP_LabelList[Idx].DSt := DSt;

End;

Function SP_FindLabel(const LabelText: aString; Var Error: TSP_ErrorCode): TSP_Label;
Var
  Idx: Integer;
  Token: pToken;
  Statement, LabelPos, LabelLen: Integer;
  nLabelText: aString;
Begin

  ERRStr := LabelText;
  Result.Line := -1;
  Result.Dline := -1;
  Result.Name := LabelText;

  LabelPos := 0;
  LabelLen := 0;
  nLabelText := LabelText;

  If Error.Line >= 0 Then Begin

    Idx := 0;
    While Idx < Length(SP_LabelList) Do Begin
      If SP_LabelList[Idx].Name = nLabelText Then
        Break;
      Inc(Idx);
    End;
    If Idx = Length(SP_LabelList) Then Begin
      Error.Code := SP_ERR_LABEL_NOT_FOUND;
      Result.Line := -1;
    End Else
      Result := SP_LabelList[Idx];

  End Else Begin

    Idx := 1;
    If COMMAND_TOKENS[Idx] = aChar(SP_LINE_NUM) Then Inc(Idx, 1 + SizeOf(LongWord));
    If COMMAND_TOKENS[Idx] = aChar(SP_STATEMENTS) Then Idx := pLongWord(@COMMAND_TOKENS[1 + Idx + SizeOf(LongWord)])^;
    Statement := 1;

    While Idx <= Length(COMMAND_TOKENS) Do Begin

      Token := @COMMAND_TOKENS[Idx];
      If Token^.Token = SP_TERMINAL Then Break;
      Inc(Idx, SizeOf(TToken));
      Case Token^.Token of
        SP_SYMBOL:
          Begin
            If COMMAND_TOKENS[Idx+1] = ':' Then
              Inc(Statement);
            Inc(Idx, Token^.TokenLen);
          End;
        SP_LABEL:
          Begin
            LabelPos := Idx;
            LabelLen := Token^.TokenLen;
            Inc(Idx, Token^.TokenLen);
          End;
        SP_KEYWORD:
          Begin
            If pLongWord(@COMMAND_TOKENS[Idx])^ = SP_KW_LABEL Then Begin
              If Lower(Copy(COMMAND_TOKENS, LabelPos, LabelLen)) = nLabelText Then Begin
                Result.Line := -2;
                Result.Statement := SP_FindStatement(@COMMAND_TOKENS, Statement +1);
                Result.St := Statement +1;
                Break;
              End;
            End;
            Inc(Idx, Token^.TokenLen);
          End;
      Else
        Inc(Idx, Token^.TokenLen);
      End;
    End;

    If Result.Line = -1 Then Begin

      Idx := 0;
      While Idx < Length(SP_LabelList) Do Begin
        If SP_LabelList[Idx].Name = nLabelText Then
          Break;
        Inc(Idx);
      End;
      If Idx = Length(SP_LabelList) Then
        Result.Line := -1
      Else
        Result := SP_LabelList[Idx];

    End;

  End;

End;

Procedure SP_ClearLabels;
Begin

  SetLength(SP_LabelList, 0);

End;

Function SP_LIST(Start, Finish: Integer): aString;
Var
  Idx, LineNum, cPos, ProgLen: Integer;
  LineNumStr, Tokens: aString;
Begin

  Result := '';
  If INCLUDEFROM = -1 Then
    ProgLen := Length(SP_Program) -1
  Else
    ProgLen := INCLUDEFROM -1;

  Idx := 0;
  While (Idx <= ProgLen) And (pLongWord(@SP_Program[Idx][2])^ < LongWord(Start)) Do Inc(Idx);

  While (Idx <= ProgLen) And (pLongWord(@SP_Program[Idx][2])^ <= LongWord(Finish)) Do Begin

    cPos := -1;
    Tokens := SP_Program[Idx];
    LineNum := pLongWord(@Tokens[2])^;
    LineNumStr := IntToString(LineNum);
    Tokens := SP_DeTokenise(Tokens, cPos, False, False);
    For cPos := 1 to 5 - Length(LineNumStr) Do Tokens := ' ' + Tokens;
    If LineNum = PROGLINE Then Tokens := Copy(Tokens, 1, 5)+'>'+Copy(Tokens, 7, Length(Tokens));

    Result := Result + Tokens + #13;
    Inc(Idx);

  End;

End;

Initialization

  AUTOSAVETIME := MAXINT;

end.




