// Copyright (C) 2024 By Paul Dunn
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

unit SP_PreRun;

interface

// Housekeeping and stuff performed before a command or program is started.

Uses SP_Util, SP_Errors, SP_SysVars;

Type

  TSP_Constant = Record
    Name: aString;
    Val: aFloat;
    Str: aString;
  End;

  TSP_GOSUB_Item = Packed Record
    Line, Statement, St, Source, Count: Integer;
  End;

  TSP_ProcItem = Packed Record
    Name: aString;
    NumVars: Integer;
    VarList: aString;
    VarTypes: aString;
    Line, Statement, St: Integer;
    EP_Line, EP_Statement, EP_St: Integer;
  End;

  TSP_ProcStackItem = Packed Record
    ProcIndex, NumVars, VarPosN, VarPosS, VarPosNA, VarPosSA, CALLType: Integer;
    StackPtr: Pointer;
  End;

Procedure SP_RESTORE;
Procedure SP_PreParse(ClearVars, Restore: Boolean; Var Error: TSP_ErrorCode; Var CmdTokens: aString);
Procedure SP_FixStatementList(Var Tokens: aString; Position, Displacement: Integer);
Procedure SP_TestConsts(Var Tokens: aString; lIdx: Integer; Var Error: TSP_ErrorCode; Preserve: Boolean);

Var

  Constants: Array of TSP_Constant;
  SP_DATA_Line: TSP_GOSUB_Item;
  SP_DATA_Tokens: paString;
  ProcListAvailable: Boolean;
  SP_ProcStack: Array [0 .. MAXDEPTH -1] of TSP_ProcStackItem;
  SP_ProcStackPtr: Integer;


implementation

Uses SyncObjs, SP_Interpret_PostFix, SP_Tokenise, SP_Variables, SP_Streams, SP_Menu, SP_Graphics, SP_Main, SP_FPEditor, SP_InfixToPostFix, SP_BankManager, SP_FileIO;

Function IsColourCommand(KW: LongWord): Boolean;
Begin

  Result := (KW = SP_KW_TEXT) or
            (KW = SP_KW_PRINT) or
            (KW = SP_KW_PLOT) or
            (KW = SP_KW_DRAW) or
            (KW = SP_KW_RECTANGLE) or
            (KW = SP_KW_FILL) or
            (KW = SP_KW_CIRCLE) or
            (KW = SP_KW_ELLIPSE) or
            (KW = SP_KW_CURVE) or
            (KW = SP_KW_POLYGON) or
            (KW = SP_KW_MULTIPLOT);

End;

Procedure SP_RESTORE;
Var
  Info: TSP_iInfo;
  pInfo: pSP_iInfo;
  Error: TSP_ErrorCode;
Begin

  Error.Code := SP_ERR_NO_ERROR;
  Info.Error := @Error;
  pInfo := @Info;

  SP_DATA_Line.Line := -1;

  SP_Interpret_DO_RESTORE(pInfo);

End;

Procedure SP_PreParse(ClearVars, Restore: Boolean; Var Error: TSP_ErrorCode; Var CmdTokens: aString);
Type
  VarType = Packed Record
    ID: Byte;
    Position: LongWord;
    StrLen: LongWord;
  End;
  pVarType = ^VarType;
Var
  Tkn, Tkn2: pToken;
  Idx, Idx2, Idx3, Idx4, sIdx, pStatement,
  LabelPos, LabelLen, ProcIdx, LastStrAt, LastStrLen, DATALine, DATAStatement: Integer;
  Tokens, Name, s: aString;
  Changed, Reference, NewStatement, IsVar: Boolean;
  TempLine, cLine: TSP_GOSUB_Item;
  xVar: pVarType;
  KeyWord, MaxLineNum, cKW, LastKW, CurLine: LongWord;
  ProcLines: aString;
  StrPtr: pByte;
  KwPtr: pLongWord;
  TknType, LastTknType: Byte;
Label
  NextLine;
Begin

  DATALine := -1;
  DATAStatement := -1;
  LabelLen := 0;
  LabelPos := 0;
  SetLength(Constants, 0);
  INPROC := 0;

  If ClearVars Then Begin
    SVLen := 0;
    NVLen := 0;
    SetLength(NumVars, 0);
    SetLength(StrVars, 0);
    SP_ResizeNumVars(0);
    SP_ResizeStrVars(0);
    SP_ClearStructs;
    SP_TruncateNumArrays(-1);
    SP_TruncateStrArrays(-1);
    If Restore Then SP_DATA_Line.Line := -1;
    BASE := 1;
    MOUSEWHEEL := 0;
    SP_CaseListPtr := -1;
    SP_ProcsListPtr := -1;
    SP_ProcStackPtr := -1;
    SP_DeleteAllStreams(Error);
    SetLength(FillQueue, 0);
    SP_DeleteAllMenus;
    OSD := '';
  End;
  SP_ClearLabels;
  ProcLines := '';
  MaxLineNum := 0;
  NUMCONSTS := 0;
  LastKW := 0;
  LastStrAt := 0;
  LastStrLen := 0;
  SP_NextCount := 0;
  SetLength(LineLUT, 0);

  If Not PAYLOADPRESENT Then
    SP_ForceCompile;

  sIdx := -1;
  if CmdTokens <> '' then
    Idx := -2
  else
    Idx := -1;

  LastTknType := $FF;
  CurLine := 0;

  While True Do Begin

    NextLine:

    Inc(Idx);
    If Idx = SP_Program_Count Then Break;

    if Idx = -1 then
      Tokens := CmdTokens
    else
      Tokens := SP_Program[Idx];

    Changed := False;
    Idx3 := 1;
    Idx2 := 1;
    TknType := 0;
    If Byte(Tokens[Idx3]) = SP_LINE_NUM Then Begin
      CurLine := pLongWord(@Tokens[Idx3 +1])^;
      If CurLine > MaxLineNum Then
        MaxLineNum := CurLine;
      Inc(Idx3, 1 + SizeOf(LongWord));
    End;
    If Byte(Tokens[Idx3]) = SP_STATEMENTS Then Inc(Idx3, 1+((1 + pLongWord(@Tokens[Idx3+1])^) * SizeOf(LongWord)));

    If Tokens <> '' Then Begin

      If Tokens[Idx2] = aChar(SP_LINE_NUM) Then Inc(Idx2, 1 + SizeOf(LongWord));
      If Tokens[Idx2] = aChar(SP_STATEMENTS) Then Idx2 := pLongWord(@Tokens[1 + Idx2 + SizeOf(LongWord)])^;
      NewStatement := False;
      pStatement := 1;

      // Check the textual code for procedures and functions
      // Idx3 has been set up to point to the first token.

      While Idx3 < Length(Tokens) Do Begin

        TknType := Byte(Tokens[Idx3]);

        Case TknType of
          SP_SYMBOL:
            Begin
              Inc(Idx3);
              If (Tokens[Idx3] in [SP_CHAR_SEMICOLON, ':']) And Not NewStatement Then Begin
                If (Tokens[Idx3] <> SP_CHAR_SEMICOLON) Or Not IsColourCommand(LastKW) Then Begin
                  NewStatement := True;
                  Inc(pStatement);
                End;
              End;
              Inc(Idx3);
            End;
          SP_VALUE:
            Begin
              Inc(Idx3, 1 + SizeOf(aFloat));
              NewStatement := False;
            End;
          SP_STRING, SP_LABEL, SP_COMMENT, SP_TEXT, SP_STRUCT_MEMBER_N, SP_STRUCT_MEMBER_S:
            Begin
              Inc(Idx3, 1 + SizeOf(LongWord) + pLongWord(@Tokens[Idx3 +1])^);
              NewStatement := False;
            End;
          SP_STRINGCHAR:
            Begin
              Inc(Idx3, 1 + SizeOf(aFloat));
              Inc(Idx3, 1 + SizeOf(LongWord) + pLongWord(@Tokens[Idx3 +1])^);
              NewStatement := False;
            End;
          SP_KEYWORD, SP_FUNCTION:
            Begin
              KwPtr := @Tokens[Idx3 +1];
              KeyWord := KwPtr^;
              LastKW := KeyWord;
              Case KeyWord Of
                SP_KW_ELSE, SP_KW_THEN:
                  Begin
                    If (KeyWord = SP_KW_ELSE) And Not NewStatement Then
                      Inc(pStatement);
                    Inc(pStatement);
                    Inc(Idx3, 1 + SizeOf(LongWord));
                  End;
                SP_KW_DEF_PROC:
                  Begin
                    Inc(Idx3, 1 + SizeOf(LongWord));
                    Inc(SP_ProcsListPtr);
                    With SP_ProcsList[SP_ProcsListPtr] Do Begin
                      TempLine := SP_ConvertLineStatement(Idx, pStatement);
                      xVar := @Tokens[Idx3];
                      Inc(Idx3, SizeOf(VarType));
                      Name := LowerNoSpaces(Copy(Tokens, Idx3, xVar^.StrLen));
                      If xVar^.ID = SP_STRVAR Then
                        Name := Name + '$';

                      Line := TempLine.Line;
                      Statement := TempLine.Statement;
                      St := TempLine.St;
                      EP_Line := -1;
                      NumVars := 0;

                      VarList := '';
                      VarTypes := '';
                      Inc(Idx3, xVar.StrLen);
                      If (Byte(Tokens[Idx3]) = SP_SYMBOL) And (Tokens[Idx3 +1] = '(') Then Begin
                        Inc(Idx3, 2);
                        Reference := False;
                        While True Do Begin
                          xVar := @Tokens[Idx3];
                          If xVar.ID = SP_KEYWORD Then Begin
                            If pLongWord(@Tokens[idx3 + 1])^ = SP_KW_REF then Begin
                              Inc(Idx3, SizeOf(LongWord) +1);
                              Reference := True;
                            End;
                          End Else
                            If xVar^.ID = SP_NUMVAR Then Begin
                              Inc(NumVars);
                              Inc(Idx3, SizeOf(VarType));
                              If Reference Then
                                VarTypes := VarTypes + '!'
                              Else
                                VarTypes := VarTypes + '*';
                              VarList := VarList + aChar(0) + LongWordToString(xVar^.StrLen) + Copy(Tokens, Idx3, xVar^.StrLen);
                              Inc(Idx3, xVar^.StrLen);
                              Reference := False;
                            End Else
                              If xVar^.ID = SP_STRVAR Then Begin
                                Inc(NumVars);
                                Inc(Idx3, SizeOf(VarType));
                                If Reference Then
                                  VarTypes := VarTypes + '!'
                                Else
                                  VarTypes := VarTypes + '*';
                                VarList := VarList + aChar(1) + LongWordToString(xVar^.StrLen) + Copy(Tokens, Idx3, xVar^.StrLen);
                                Inc(Idx3, xVar^.StrLen);
                                Reference := False;
                              End Else
                                If xVar^.ID = SP_SYMBOL Then Begin
                                  If Tokens[Idx3 +1] = ')' Then Begin
                                    Inc(Idx3, 2);
                                    Break;
                                  End Else
                                    Inc(Idx3, 2);
                                End;
                        End;
                      End Else
                        NumVars := 0;
                    End;
                  End;
                SP_KW_ENDPROC:
                  Begin
                    ProcIDX := SP_ProcsListPtr;
                    If ProcIDX = -1 Then Begin
                      Error.Code := SP_ERR_ENDPROC_WITHOUT_PROC;
                      Error.Line := Idx;
                      Goto NextLine;
                    End;
                    While SP_ProcsList[ProcIDX].EP_Line > -1 Do Begin
                      Dec(ProcIDX);
                      If ProcIDX = -1 Then Begin
                        Error.Code := SP_ERR_ENDPROC_WITHOUT_PROC;
                        Error.Line := Idx;
                        Goto NextLine;
                      End;
                    End;
                    TempLine := SP_ConvertLineStatement(Idx, pStatement);
                    With SP_ProcsList[ProcIDX] Do Begin
                      EP_Line := TempLine.Line;
                      EP_Statement := TempLine.Statement;
                      EP_St := TempLine.St;
                    End;
                    Inc(Idx3, SizeOf(LongWord) +1);
                  End;
                SP_KW_PROC, SP_FN_CALL:
                  Begin
                    ProcLines := ProcLines + LongWordToString(Idx);
                    Inc(Idx3, SizeOf(LongWord) +1);
                  End;
              Else
                Inc(Idx3, 1 + SizeOf(LongWord));
              End;
              NewStatement := False;
            End;
          SP_NUMVAR, SP_STRVAR:
            Begin
              Idx4 := Idx3;
              xVar := @Tokens[Idx4];
              Inc(Idx4, SizeOf(VarType));
              Name := LowerNoSpaces(Copy(Tokens, Idx4, xVar^.StrLen));
              If xVar^.ID = SP_STRVAR Then Name := Name + '$';
              Inc(Idx3, 1 + (SizeOf(LongWord) * 2) + pLongWord(@Tokens[Idx3 + 1 + SizeOf(LongWord)])^);
              If (LastTknType = SP_KEYWORD) And (LastKW = SP_KW_NEXT) Then Begin
                With SP_NextEntries[SP_NextCount] Do Begin
                  VarName := Name;
                  Line := CurLine;
                  Statement := pStatement +1;
                End;
                Inc(SP_NextCount);
              End;
              NewStatement := False;
            End;
          255:
            Break;
        End;

        LastTknType := TknType;

      End;

      If (TknType = $FF) and (Idx2 = 1) Then Begin // Is this a direct command with no statement list table?
        Idx2 := Idx3;
        While Tokens[Idx2] = #$FF Do
          Inc(Idx2);
        sIdx := Idx2;
      End;

      pStatement := 1;

      // Check through the tokenised code now

      While Idx2 <= Length(Tokens) Do Begin

        StrPtr := @Tokens[Idx2];
        Tkn := pToken(StrPtr);
        If Tkn^.Token = SP_TERMINAL Then Break;
        If ClearVars then Tkn^.Cache := 0;
        Inc(Idx2, SizeOf(TToken)); // Idx2 now points to content
        Case Tkn^.Token of
          SP_NUMVAR, SP_STRVAR:
            Begin
              If ClearVars Then Begin
                Tkn^.Cache := 0;
                Inc(Idx2, Tkn^.TokenLen);
                Changed := True;
              End Else
                Inc(Idx2, Tkn^.TokenLen);
            End;
          SP_NUMVAR_LET, SP_STRVARPTR, SP_STRVAR_LET, SP_STRVAR_EVAL, SP_NUMVAR_EVAL,
          SP_POINTER, SP_NUMVAR_LET_VALID, SP_STRVAR_LET_VALID, SP_INCVAR, SP_DECVAR, SP_MULVAR, SP_DIVVAR,
          SP_POWVAR, SP_MODVAR, SP_ANDVAR, SP_ORVAR, SP_NOTVAR, SP_XORVAR, SP_SHLVAR, SP_SHRVAR:
            Begin
              IsVar := True;
              If Tkn^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then Begin
                Name := StringFromPtrB(@Tokens[Idx2 + SizeOf(LongWord)], Tkn^.TokenLen - SizeOf(LongWord));
                If Name[1] > #127 Then Begin
                  // A high bit set on the first char of the var name indicates a hybrid function -
                  // a function that can be written to. Convert to that token type now.
                  Tkn^.Token := SP_HYBRID_LET;
                  SP_AddHandlers(Tokens);
                  Changed := True;
                  IsVar := False;
                End;
              End;
              If IsVar Then
                If ClearVars Then Begin
                  pLongWord(@Tokens[Idx2])^ := 0;
                  Changed := True;
                End;
              Inc(Idx2, Tkn^.TokenLen);
            End;
          SP_KEYWORD:
            Begin
              KwPtr := pLongWord(@Tokens[Idx2]);
              cKW := kwPtr^;
              Case cKW of

                SP_KW_CONST:
                  Begin
                    // A constant has been declared. Get the value (or string) and insert it into the list of live
                    // constants. First the varname, then the value. Add a "$" mark and lowercase for the list.
                    Inc(Idx2, Tkn^.TokenLen); // Skip keyword
                    Tkn2 := @Tokens[Idx2];
                    Inc(Idx2, SizeOf(TToken)); // Pointing at next token's content - the name.
                    Name := Lower(Copy(Tokens, Idx2 + SizeOf(LongWord), Tkn2^.TokenLen - SizeOf(LongWord)));
                    Inc(Idx2, Tkn2^.TokenLen);
                    Idx3 := 0;
                    While (Idx3 < Length(Constants)) And (Constants[Idx3].Name <> Name) Do Inc(Idx3);
                    If Idx3 = Length(Constants) Then SetLength(Constants, Idx3 +1);
                    Inc(NUMCONSTS);
                    Tkn2 := @Tokens[Idx2];
                    Inc(Idx2, SizeOf(TToken));
                    Case Tkn2^.Token Of
                      SP_VALUE:
                        Begin
                          Constants[Idx3].Name := Name;
                          Constants[Idx3].Val := gaFloat(@Tokens[Idx2]);
                        End;
                      SP_STRING:
                        Begin
                          Constants[Idx3].Name := Name + '$';
                          Constants[Idx3].Str := Copy(Tokens, Idx2, Tkn2^.TokenLen);
                        End;
                    End;
                    Tkn := Tkn2;
                  End;
                SP_KW_DATA: // if this is the first time we find DATA then store the location for later
                  If DATALine = -1 Then Begin
                    DATALine := Idx;
                    DATAStatement := Tkn^.TokenPos;
                  End;
                SP_KW_LABEL:
                  Begin
                    TempLine := SP_ConvertLineStatement(Idx, pStatement +1);
                    cLine := SP_ConvertLineStatement(Idx, pStatement);
                    SP_AddLabel(Copy(Tokens, LabelPos, LabelLen), TempLine.Line, TempLine.Statement, TempLine.St, cLine.Line, cLine.Statement, cLine.St);
                  End;
                SP_KW_DEF_FN:
                  Begin
                    s := Copy(Tokens, LastStrAt, LastStrLen);
                    SP_TestConsts(s, 1, Error, False);
                    SP_AddHandlers(s);
                    pToken(@Tokens[LastStrAt])^.TokenLen := Length(s);
                    //pLongWord(@Tokens[LastStrAt - (SizeOf(LongWord) * 2)])^ := Length(s);
                    Tokens := Copy(Tokens, 1, LastStrAt -1)+s+Copy(Tokens, LastStrAt + LastStrLen);
                    Inc(Idx2, Length(s) - LastStrLen);
                    If Length(s) <> LastStrLen Then
                      SP_FixStatementList(Tokens, LastStrAt, Length(s) - LastStrLen);
                  End;
              End;
              Inc(Idx2, Tkn^.TokenLen);
            End;
          SP_LABEL:
            Begin
              LabelPos := Idx2;
              LabelLen := Tkn^.TokenLen;
              Inc(Idx2, Tkn^.TokenLen);
            End;
          SP_SYMBOL:
            Begin
              If (Tokens[Idx2] = ':') or (Tokens[Idx2] = SP_CHAR_SEMICOLON) or (Tokens[Idx2] = ';') Then
                Inc(pStatement);
              Inc(Idx2, Tkn^.TokenLen);
            End;
          SP_STRING:
            Begin
              LastStrAt := Idx2;
              LastStrLen := Tkn^.TokenLen;
              Inc(Idx2, LastStrLen);
            End;
        Else
          Inc(Idx2, Tkn^.TokenLen);
        End;

      End;

      If Changed Then Begin
        if Idx = -1 then Begin
          SetLength(CmdTokens, Length(Tokens));
          CopyMem(@CmdTokens[1], @Tokens[1], Length(Tokens));
        End Else Begin
          SetLength(SP_Program[Idx], Length(Tokens));
          CopyMem(@SP_Program[Idx][1], @Tokens[1], Length(Tokens));
        End;
      End;

      If idx = -1 then Begin
        If sIdx = -1 Then
          SP_TestConsts(CmdTokens, Idx, Error, False)
        Else Begin
          s := Copy(CmdTokens, sIdx);
          SP_TestConsts(s, Idx, Error, False);
          CmdTokens := Copy(CmdTokens, 1, sIdx -1) + s;
        End;
      End Else
        SP_TestConsts(SP_Program[Idx], Idx, Error, False);
      If Error.Code <> SP_ERR_OK Then Begin
        Error.Line := Idx;
        Exit;
      End;
    End;

  End;

  Idx3 := 0;
  SetLength(LineLUT, MaxLineNum +1);
  For Idx := 0 To SP_Program_Count -1 Do Begin
    Idx2 := pLongWord(@SP_Program[Idx][2])^;
    While Idx3 < Idx2 Do Begin
      Inc(Idx3);
      LineLUT[Idx3] := Idx;
    End;
  End;
  LineLUT[MaxLineNum] := SP_Program_Count -1;

  For Idx3 := 0 To SP_ProcsListPtr Do Begin
    If SP_ProcsList[Idx3].EP_Line = -1 Then Begin
      ERRStr := SP_ProcsList[Idx3].Name;
      Error.Code := SP_ERR_PROC_NOT_CLOSED;
      Error.Line := SP_ProcsList[Idx3].Line;
      Error.Statement := SP_ProcsList[Idx3].St;
      Exit;
    End;
  End;

  // Process lines of PROC/CALL calls by retokenising them.

  ProcListAvailable := True;
  Idx3 := -1;
  Idx := 1;
  While Idx < Length(ProcLines) Do Begin
    Idx2 := pLongWord(@ProcLines[Idx])^;
    SP_Program[Idx2] := SP_TokeniseLine(SP_Detokenise(SP_Program[Idx2], Idx3, False, False), False, True) + SP_TERMINAL_SEQUENCE;
    Idx3 := 1;
    SP_Convert_ToPostFix(SP_Program[Idx2], Idx3, Error);
    SP_TestConsts(SP_Program[Idx2], Idx2, Error, True);
    If Error.Code <> SP_ERR_OK Then Begin
      Error.Line := Idx2;
      Exit;
    End;
    Inc(Idx, SizeOf(LongWord));
  End;

  If ClearVars Then Begin

    T_OVER := 0;
    COVER := 0;

    If SP_Interpreter_Ready Then Begin
      DisplaySection.Enter;
      SP_SetSystemFont(SYSFONT, Error);
      SP_DeleteAllWindows;
      SP_DeleteAllStreams(Error);
      SP_DeleteAllBanks(False);
      SP_FileCloseAll;
      SP_CLS(CPAPER);
      NUMSPRITES := 0;
      DisplaySection.Leave;
    End;

    SP_ClearEvery;
    SP_ResetConditionalBreakPoints;
    EveryEnabled := True;
    ResetErrorFlags;
    ERROR_LineNum := -1;
    MOUSEDOWN_LineNum := -1;
    MOUSEUP_LineNum := -1;
    MOUSEMOVE_LineNum := -1;
    KEYUP_LineNum := -1;
    KEYDOWN_LineNum := -1;
    WHEELUP_LineNum := -1;
    WHEELDOWN_LineNum := -1;
    MENUSHOW_LineNum := -1;
    MENUHIDE_LineNum := -1;
    MENUITEM_LineNum := -1;
    COLLIDE_LineNum := -1;
    COLLIDE_FLAG := False;
    T_USINGMASK := '';
    OnActive := 0;

    FPWindowID := -1;
    DWWindowID := -1;

    If INCLUDEFROM > -1 Then
      SP_DeleteIncludes;

    If Restore Then
      If (SP_DATA_Line.Line = -1) and (DATALine >= 0) Then Begin
        SP_DATA_Line := SP_ConvertLineStatement(DATALine, DATAStatement);
        Inc(SP_DATA_Line.Statement, SizeOf(TToken) + SizeOf(LongWord));
        SP_DATA_Tokens := @SP_Program[DATALine];
      End;

  End;

  // Convert the NEXT jump table to offsets

  For Idx := 0 To SP_NextCount -1 Do Begin
    TempLine := SP_ConvertLineStatement(SP_FindLine(SP_NextEntries[Idx].Line, False), SP_NextEntries[Idx].Statement);
    If TempLine.Line = -1 Then // Off the end of the program?
      TempLine.Line := SP_FindLine(SP_NextEntries[Idx].Line, False);
    SP_NextEntries[Idx].Line := TempLine.Line;
    SP_NextEntries[Idx].Statement := TempLine.Statement;
  End;

  // Finally, insert breakpoint flags if necessary

  SP_PrepareBreakpoints(True);
  FN_Recursion_Count := 0;

End;

Procedure SP_FixStatementList(Var Tokens: aString; Position, Displacement: Integer);
Var
  Idx, StatementListPos: Integer;
  Ptr: pLongWord;
  n: LongWord;
Begin

  // Fixes the statement list jump table at the start of the line - if any statements
  // have been displaced after the given position, update the table by incrementing their
  // entries by the displacement amount.

  Idx := 1;
  StatementListPos := -1;
  If Tokens <> '' Then Begin
    If Tokens[Idx] = aChar(SP_LINE_NUM) Then
      Inc(Idx, 1 + SizeOf(LongWord));
    If Tokens[Idx] = aChar(SP_STATEMENTS) Then
      StatementListPos := Idx;
    If StatementListPos >= 0 Then Begin
      Ptr := @Tokens[StatementListPos +1];
      n := Ptr^;
      While n > 0 Do Begin
        Inc(Ptr);
        If Ptr^ >= LongWord(Position) Then
          If Displacement > 0 Then
            Inc(Ptr^, Displacement)
          Else
            Dec(Ptr^, -Displacement);
        Dec(n);
      End;
    End;
  End;

End;

Procedure SP_TestConsts(Var Tokens: aString; lIdx: Integer; Var Error: TSP_ErrorCode; Preserve: Boolean);
Var
  cKw, LineNum: LongWord;
  Idx, Idx2, Idx3, TokenPos, TokenLen, TLen, TknLen2, TknType2, pStatement, StartPos, SkipCnt: Integer;
  Name: aString;
  LastRefWasConst, Changed: Boolean;
  Tkn, Tkn2: pToken;
  TknType: Byte;
  kwPtr: pLongWord;

  cFound: Boolean;
  CaseCount, cStatement, cIdx, cIdx2: Integer;
  cTokens: aString;
  Dbl: aFloat;
  cLine: TSP_GOSUB_Item;

  Procedure FixStatements(Position, Displacement: Integer);
  Var
    n, Idx, Idx2, Value: LongWord;
    NewVal: aFloat;
    Jump: Integer;
    Kwd: LongWord;
    Token: pToken;
  Begin

    SP_FixStatementList(Tokens, Position, Displacement);

    // While we're here, check the line for IIF functions - they utilise a displacement to shortcut
    // to the False expression, and to skip the false expression if true. So search for the value preceding
    // an IIF, and the jump after:
    // If Position falls between the IIF and the JUMP, then increment the preceding value
    // If Position falls between the JUMP and the jump's target, increment the JUMP.
    // Also check for other jumps, and if their target is beyond the position, increment them also.
    // *AND* check the labels list for their positions in a similar manner.
    // NEW! Now also check the list of offsets after am SP_IJMP opcode (indexed jump)

    If Length(SP_LabelList) > 0 Then
      For Idx := 0 To Length(SP_LabelList) -1 Do Begin
        If (SP_LabelList[Idx].Dline >= lIdx) and (SP_LabelList[Idx].DStatement >= Position) Then
          Inc(SP_LabelList[Idx].DStatement, Displacement);
        If (SP_LabelList[Idx].Line >= lIdx) and (SP_LabelList[Idx].Statement >= Position) Then
          Inc(SP_LabelList[Idx].Statement, Displacement);
      End;

    Idx := 1;
    If Tokens[Idx] = aChar(SP_LINE_NUM) Then Inc(Idx, 1 + SizeOf(LongWord));
    If Tokens[Idx] = aChar(SP_STATEMENTS) Then Idx := pLongWord(@Tokens[1 + Idx + SizeOf(LongWord)])^;
    While Integer(Idx) < Length(Tokens) Do Begin
      Token := @Tokens[Idx];
      Inc(Idx, SizeOf(TToken));
      Case Token^.Token of
        SP_JZ, SP_JNZ:
          Begin
            Jump := pLongWord(@Tokens[Idx])^;
            If (Integer(Idx) + Jump >= Position - Displacement) And (Jump > 0) Then
              If Displacement >= 0 Then
                Inc(pLongWord(@Tokens[Idx])^, Displacement)
              Else
                Dec(pLongWord(@Tokens[Idx])^, -Displacement);
            Inc(Idx, Token^.TokenLen);
          End;
        SP_DISPLACEMENT:
          Begin
            Token^.TokenPos := Idx;
            Inc(Idx, Token^.TokenLen);
          End;
        SP_VALUE:
          Begin
            If (Idx + Token^.TokenLen < LongWord(Length(Tokens))) and (pToken(@Tokens[Idx + Token^.TokenLen])^.Token = SP_FUNCTION) Then Begin
              Kwd := pLongWord(@Tokens[Idx + Token^.TokenLen + SizeOf(TToken)])^;
              If (Kwd = SP_FN_IIF) or (Kwd = SP_FN_IIFS) Then Begin
                // Found a value followed by an IIF or IIF$.
                Idx2 := Idx + Token^.TokenLen + SizeOf(TToken) + SizeOf(LongWord);
                Value := Trunc(gaFloat(@Tokens[Idx]));
                If (Position > Integer(Idx2)) And (Position < Integer(Idx2 + Value)) Then Begin
                  If Displacement >= 0 Then
                    Inc(Value, Displacement)
                  Else
                    Dec(Value, -Displacement);
                  NewVal := Value;
                  WriteaFloat(@Tokens[Idx], NewVal);
                End;
                // Now find the SP_JUMP token. Idx2 points at the first token after the IIF, so
                // Adding Value to that should get us there.
                Inc(Idx2, Value);
                // Now get the jump and see if the displacement counts.
                Jump := pInteger(@Tokens[Idx2 - SizeOf(Integer)])^;
                If (Position >= Integer(Idx2)) And (Position < Integer(Idx2) + Jump) Then
                  pLongWord(@Tokens[Idx2 - SizeOf(Integer)])^ := Jump + Displacement;
                Inc(Idx, Token^.TokenLen);
              End Else
                Inc(Idx, Token^.TokenLen);
            End Else
              Inc(Idx, Token^.TokenLen);
          End;
        SP_IJMP: // Indexed jump. Basically a count (n) then n longwords indicating a distance into the code.
                 // Used by ON <a> GOTO <m,n,o,p...>
          Begin
            n := pLongWord(@Tokens[Idx])^;
            Inc(Idx, SizeOf(LongWord));
            While n > 0 Do Begin
              Jump := pLongWord(@Tokens[Idx])^;
              If (Integer(Idx) + Jump >= Position - Displacement) And (Jump > 0) Then
                If Displacement >= 0 Then
                  Inc(pLongWord(@Tokens[Idx])^, Displacement)
                Else
                  Dec(pLongWord(@Tokens[Idx])^, -Displacement);
              Inc(Idx, SizeOf(LongWord));
              Dec(n);
            End;
          End;
      Else
        Inc(Idx, Token^.TokenLen);
      End;
    End;

  End;

Begin

  // Search for and replace references to constants, process CASE lists and handle Short-circuit Booleans.
  // CONSTS will appear as NUMVAR or STRVAR entries - if they're newly created. If they've been
  // altered before, then they will be NUMCONST and STRCONST entries, which contain their values and names.

  // Be sure to obey SP_SKIPSTATEMENT tokens if they're followed by a CONST keyword.

  If Error.Code <> SP_ERR_OK then Exit; // This should not be called on badly formed code

  LastRefWasConst := False;
  Changed := False;
  pStatement := 1;

  Idx := 1;
  LineNum := 0;
  If Tokens <> '' Then Begin
    If Tokens[Idx] = aChar(SP_LINE_NUM) Then Begin
      Inc(Idx);
      LineNum := pLongWord(@Tokens[Idx])^;
      Inc(Idx, SizeOf(LongWord));
    End;
    If Tokens[Idx] = aChar(SP_STATEMENTS) Then Begin
      Idx := pLongWord(@Tokens[1 + Idx + SizeOf(LongWord)])^;
    End;

    StartPos := Idx;

    While Idx <= Length(Tokens) Do Begin

      Tkn := @Tokens[Idx];
      TknType := Tkn^.Token;
      TokenPos := Idx;
      If TknType = SP_TERMINAL Then Break;

      Inc(Idx, SizeOf(TToken));

      Case TknType of

        SP_KEYWORD:
          Begin

            // If we encounter a LET after a constant, it's an error.

            kwPtr := pLongWord(@Tokens[Idx]);
            cKw := kwPtr^;

            Case cKw of

              SP_KW_LET:
                Begin
                  If LastRefWasConst Then Begin
                    PROGCHANGED := True;
                    Error.Code := SP_ERR_CONST_IN_ASSIGNMENT;
                    Error.Line := SP_FindLine(LineNum, True);
                    Error.Statement := pStatement;
                    Exit;
                  End;
                End;

              SP_KW_CASE, SP_KW_WHEN, SP_KW_WHEN_IN:
                Begin

                  // Now head off into the code to find the END CASE (or additionally the next WHEN/OTHERWISE) statement.
                  // Ensure it matches this CASE statement.

                  cFound := False;
                  CASECount := 0;
                  cIdx := lIdx;
                  cTokens := SP_Program[cIdx];
                  cIdx2 := Idx + Integer(Tkn^.TokenLen);
                  cStatement := pStatement;

                  While Not cFound And (cIdx < SP_Program_Count) Do Begin

                    While cIdx2 < Length(cTokens) Do Begin

                      Tkn2 := @cTokens[cIdx2];
                      If Tkn2^.Token = SP_TERMINAL Then Break;
                      Inc(cIdx2, SizeOf(TToken));

                      If Tkn2^.Token = SP_KEYWORD Then Begin

                        Case pLongWord(@cTokens[cIdx2])^ Of
                          SP_KW_WHEN, SP_KW_WHEN_IN, SP_KW_OTHERWISE:
                            Begin
                              If (cKW = SP_KW_WHEN) or (cKW = SP_KW_WHEN_IN) Then
                                If CASECount = 0 Then Begin
                                  cFound := True;
                                  Break;
                                End;
                            End;
                          SP_KW_END_CASE:
                            If CASECount > 0 Then
                              Dec(CASECount)
                            Else Begin
                              cFound := True;
                              Break;
                            End;
                          SP_KW_CASE:
                            Inc(CASECount);
                        End;
                        Inc(cIdx2, Tkn2^.TokenLen);

                      End Else Begin

                        If Tkn2^.Token = SP_SYMBOL Then
                          If (pByte(@cTokens[cIdx2])^ = Ord(':')) or (pByte(@cTokens[cIdx2])^ = Ord(SP_CHAR_SEMICOLON)) Then
                            Inc(cStatement);

                        Inc(cIdx2, Tkn2^.TokenLen);

                      End;

                    End;

                    If Not cFound Then Begin

                      Inc(cIdx);
                      If cIdx = SP_Program_Count Then
                        Break
                      Else Begin
                        cTokens := SP_Program[cIdx];
                        cIdx2 := 1;
                        If cTokens[cIdx2] = aChar(SP_LINE_NUM) Then Inc(cIdx2, 1 + SizeOf(LongWord));
                        If cTokens[cIdx2] = aChar(SP_STATEMENTS) Then cIdx2 := pLongWord(@cTokens[1 + cIdx2 + SizeOf(LongWord)])^;
                        cStatement := 1;
                      End;

                    End;

                  End;

                  If Not cFound Then Begin

                    If cKW = SP_KW_CASE Then
                      Error.Code := SP_ERR_CASE_WITHOUT_END_CASE
                    Else
                      Error.Code := SP_ERR_OUT_OF_CASE;
                    Error.Line := lIdx;
                    Exit;

                  End Else Begin

                    // Found the right END CASE statement, so grab the line and statement number
                    // Note that for WHEN/WHEN IN and CASE, we store the statement that holds the END CASE, rather than the
                    // one after it - we want to jump to the END CASE in order to remove the CASE from the CASE-Stack.

                    If (cKW = SP_KW_WHEN) or (cKW = SP_KW_WHEN_IN) or (cKW = SP_KW_CASE) Then Dec(cStatement);
                    cLine := SP_ConvertLineStatement(cIdx, cStatement +1);

                    // Now convert to two aFloats and insert into the CASE line!

                    Changed := True;
                    cIdx2 := Idx;
                    Dec(cIdx2, SizeOf(TToken) + SizeOf(aFloat));
                    Dbl := cLine.Statement;
                    WriteaFloat(@Tokens[cIdx2], Dbl);
                    Dec(cIdx2, SizeOf(TToken) + SizeOf(aFloat));
                    Dbl := cLine.Line;
                    WriteaFloat(@Tokens[cIdx2], Dbl);

                  End;

                End;

              // We can be sneaky here and insert the "cached jump" keywords!

              SP_KW_GOTOC, SP_KW_GOSUBC:
                Begin
                  Inc(kwPtr);
                  kwPtr^ := $80808080;
                  Changed := True;
                End;

            End;

            Inc(Idx, Tkn^.TokenLen);

          End;

        SP_ARRAY_ASSIGN:
          Begin

            // If we don't clear const status here then assigning to arrays using consts as indices
            // will fail.

            LastRefWasConst := False;
            Inc(Idx, Tkn^.TokenLen);

          End;

        SP_STRVAR_LET, SP_NUMVAR_LET, SP_STRVAR_LET_VALID, SP_NUMVAR_LET_VALID, SP_INCVAR, SP_DECVAR, SP_MULVAR, SP_DIVVAR,
        SP_POWVAR, SP_MODVAR, SP_ANDVAR, SP_ORVAR, SP_NOTVAR, SP_XORVAR, SP_SHLVAR, SP_SHRVAR:
          Begin

            // Check if we're trying to assign to a constant - that's a no-no.

            Name := StringFromPtrB(@Tokens[Idx + SizeOf(LongWord)], Tkn^.TokenLen - SizeOf(LongWord));
            If Tkn^.Token in [SP_STRVAR_LET, SP_STRVAR_LET_VALID] Then Name := Name + '$';
            Idx2 := 0;
            While (Idx2 < NUMCONSTS) And (Constants[Idx2].Name <> Name) Do Inc(Idx2);
            If Idx2 < NUMCONSTS Then Begin
              PROGCHANGED := True;
              Error.Code := SP_ERR_CONST_IN_ASSIGNMENT;
              Error.Line := SP_FindLine(LineNum, True);
              Error.Statement := pStatement;
              Exit;
            End;
            Inc(Idx, Tkn^.TokenLen);

          End;

        SP_NUMVAR:
          Begin

            // I cannot think of anywhere that this should be able to be used. It basically stacks a variable name
            // for use later on, and the only uses would be assignment. Unlike stringvars, numvars cannot be sliced.

            Name := StringFromPtrB(@Tokens[Idx + SizeOf(LongWord)], Tkn^.TokenLen - SizeOf(LongWord));
            Idx2 := 0;
            While (Idx2 < NUMCONSTS) And (Constants[Idx2].Name <> Name) Do Inc(Idx2);
            If Idx2 < NUMCONSTS Then Begin
              PROGCHANGED := True;
              Error.Code := SP_ERR_CONST_IN_ASSIGNMENT;
              Error.Line := SP_FindLine(LineNum, True);
              Error.Statement := pStatement;
              Exit;
            End Else
              LastRefWasConst := False;
            Inc(Idx, Tkn^.TokenLen);

          End;

        SP_STRVAR:
          Begin

            // A stringvar reference might be a const. Grab the name of the variable, and flag it if it's a declared constant.
            // A possible slice operation can then pick it up later.

            Name := StringFromPtrB(@Tokens[Idx + SizeOf(LongWord)], Tkn^.TokenLen - SizeOf(LongWord)) + '$';
            Idx2 := 0;
            While (Idx2 < NUMCONSTS) And (Constants[Idx2].Name <> Name) Do Inc(Idx2);
            If Idx2 < NUMCONSTS Then
              Tkn^.TokenPos := Idx2
            Else Begin
              LastRefWasConst := False;
              Tkn^.TokenPos := LongWord(-1);
            End;
            Inc(Idx, Tkn^.TokenLen);

          End;

        SP_SKIP_STATEMENT:
          Begin

            // If this token is followed by an SP_KEYWORD that is CONST, we're in business - skip it completely.
            // Otherwise, it might be part of a DATA statement, and should be processed.

            Idx2 := Idx + Integer(Tkn^.TokenLen);
            Tkn2 := @Tokens[Idx2];
            If (Tkn2^.Token = SP_KEYWORD) And (pLongWord(@Tokens[Idx2 + SizeOf(TToken)])^ = SP_KW_CONST) Then
              Inc(Idx, Tkn^.TokenLen + pLongWord(@Tokens[Idx])^)
            Else
              Inc(Idx, Tkn^.TokenLen);

          End;

        SP_NUMVAR_EVAL:
          Begin
            Name := Lower(Copy(Tokens, Idx + (SizeOf(LongWord) * 2), Tkn^.TokenLen - (SizeOf(LongWord) * 2)));
            Idx2 := 0;
            While (Idx2 < NUMCONSTS) And (Constants[Idx2].Name <> Name) Do Inc(Idx2);
            If Idx2 < NUMCONSTS Then Begin
              LastRefWasConst := True;
              TLen := Tkn^.TokenLen;
              Tokens := Copy(Tokens, 1, TokenPos -1) +
                        CreateToken(SP_NUMCONST, 0, SizeOf(aFloat) + Length (Name)) + aFloatToString(Constants[Idx2].Val) + Name +
                        Copy(Tokens, Idx + Integer(Tkn^.TokenLen), Length(Tokens));
              TLen := (SizeOf(aFloat) + Length(Name)) - TLen;
              FixStatements(Idx, TLen);
              Changed := True;
              Inc(Idx, SizeOf(aFloat) + Length(Name));
            End Else Begin
              LastRefWasConst := False;
              Inc(Idx, Tkn^.TokenLen);
            End;
          End;

        SP_STRVAR_EVAL:
          Begin
            Name := Lower(Copy(Tokens, Idx + (SizeOf(LongWord) * 2), Tkn^.TokenLen - (SizeOf(LongWord) * 2))) + '$';
            Idx2 := 0;
            While (Idx2 < NUMCONSTS) And (Constants[Idx2].Name <> Name) Do Inc(Idx2);
            If Idx2 < NUMCONSTS Then Begin
              LastRefWasConst := True;
              TLen := Length(Tokens);
              Tokens := Copy(Tokens, 1, TokenPos -1) +
                        CreateToken(SP_STRCONST, Length(Constants[Idx2].Str), Length(Constants[Idx2].Str) + Length(Name)) + Constants[Idx2].Str + Name +
                        Copy(Tokens, Idx + Integer(Tkn^.TokenLen), Length(Tokens));
              FixStatements(Idx, Length(Tokens) - TLen);
              Changed := True;
              Inc(Idx, Length(Constants[Idx2].Str) + Length(Name));
            End Else Begin
              LastRefWasConst := False;
              Inc(Idx, Tkn^.TokenLen);
            End;
          End;

        SP_NUMCONST:
          Begin
            LastRefWasConst := True;
            // If this constant still exists, then update its value. Otherwise convert back to a NUMVAR.
            Name := Lower(Copy(Tokens, Idx + SizeOf(aFloat), Tkn^.TokenLen - SizeOf(aFloat)));
            Idx2 := 0;
            While (Idx2 < NUMCONSTS) And (Constants[Idx2].Name <> Name) Do Inc(Idx2);
            If Idx2 < NUMCONSTS Then Begin
              If Not Preserve Then Begin
                WriteaFloat(@Tokens[Idx], Constants[Idx2].Val);
                Changed := True;
              End;
              Inc(Idx, Tkn^.TokenLen);
            End Else Begin
              // No longer exists - probably been removed by the user. Convert back to a NUMVAR.
              Idx2 := Length(Tokens);
              Tokens := Copy(Tokens, 1, TokenPos -1) + CreateToken(SP_NUMVAR_EVAL, 0, (SizeOf(LongWord) * 2) + Length(Name)) + LongWordToString(0) + LongWordToString(Length(Name)) + Name + Copy(Tokens, Idx + Integer(Tkn^.TokenLen), Length(Tokens));
              FixStatements(Idx, Length(Tokens) - Idx2);
              Inc(Idx, SizeOf(LongWord) + Length(Name));
              LastRefWasConst := False;
              Changed := True;
            End;
          End;

        SP_STRCONST:
          Begin
            LastRefWasConst := True;
            Name := Lower(Copy(Tokens, Idx + Integer(Tkn^.TokenPos), Tkn^.TokenLen - Tkn^.TokenPos));
            Idx2 := 0;
            While (Idx2 < NUMCONSTS) And (Constants[Idx2].Name <> Name) Do Inc(Idx2);
            If Idx2 < NUMCONSTS Then Begin
              If Not Preserve Then Begin
                TLen := Length(Tokens);
                Tokens := Copy(Tokens, 1, TokenPos -1) + CreateToken(SP_STRCONST, Length(Constants[Idx2].Str), Length(Constants[Idx2].Str) + Length(Name)) + Constants[Idx2].Str + Name + Copy(Tokens, Idx + Integer(Tkn^.TokenLen), Length(Tokens));
                FixStatements(Idx, Length(Tokens) - TLen);
                Inc(Idx, Length(Constants[Idx2].Str) + Length(Name));
                Changed := True;
              End;
            End Else Begin
              Name := Copy(Name, 1, Length(Name) -1);
              Idx2 := Length(Tokens);
              Tokens := Copy(Tokens, 1, TokenPos -1) + CreateToken(SP_STRVAR_EVAL, 0, (SizeOf(LongWord) * 2) + Length(Name)) + LongWordToString(0) + LongWordToString(Length(Name)) + Name + Copy(Tokens, Idx + Integer(Tkn^.TokenLen), Length(Tokens));
              FixStatements(Idx, Length(Tokens) - Idx2);
              Inc(Idx, SizeOf(LongWord) + Length(Name));
              LastRefWasConst := False;
              Changed := True;
            End;
          End;

        SP_SYMBOL:
          Begin
            If (Tokens[Idx] = ':') or (Tokens[Idx] = SP_CHAR_SEMICOLON) Then Begin
              Inc(pStatement);
              LastRefWasConst := False;
            End;
            Inc(Idx, Tkn^.TokenLen);
          End;

      Else

        Begin
          Inc(Idx, Tkn^.TokenLen);
        End;

      End;

    End;

    // Now check for Jumps (JZ, JNZ) - They can be nested, so we need to keep a count of them.
    // Once done, remove their corresponding AND or OR, and update the statement list if necessary.

    Idx := StartPos;
    While Idx < Length(Tokens) Do Begin

      Tkn := @Tokens[Idx];
      TknType := Tkn^.Token;
      If TknType = SP_TERMINAL Then Break;

      TokenPos := Idx;
      TokenLen := Tkn^.TokenLen;

      Inc(Idx, SizeOf(TToken));

      Case TknType of

        SP_JZ, SP_JNZ:
          Begin

            // These will, at runtime, cause a jump further into the line to their matching AND/OR token
            // If the value is 0 for JZ, non-0 for JNZ. So count their types from here in, and when finished remove
            // The AND or OR token and fill their data value with the number of bytes to skip.

            SkipCnt := 0;
            Idx2 := Idx + TokenLen;
            While Idx2 < Length(Tokens) Do Begin

              Tkn2 := @Tokens[Idx2];
              TknLen2 := Tkn2^.TokenLen;
              TknType2 := Tkn2^.Token;
              Idx3 := Idx2;
              Inc(Idx2, SizeOf(TToken));

              Case TknType2 Of

                SP_JZ, SP_JNZ:
                  Begin
                    If TknType2 = TknType Then Inc(SkipCnt);
                    Inc(Idx2, TknLen2);
                  End;

                SP_SYMBOL:
                  Begin

                    Case Tokens[Idx2] Of
                      SP_CHAR_STR_AND:
                        Begin
                          If TknType = SP_JZ Then Begin
                            Dec(SkipCnt);
                            If SkipCnt = -1 Then Begin
                              // OMG, we can't use these with strings! Both sides have to be evaluated!
                              // It's OK, Just remove the token at Idx and bail.
                              Tokens := Copy(Tokens, 1, TokenPos -1) + Copy(Tokens, Idx + TokenLen);
                              FixStatements(TokenPos, -(((Idx + TokenLen)-TokenPos)));
                              Dec(Idx, SizeOf(TToken) + TokenLen);
                              Changed := True;
                              Break;
                            End Else
                              Inc(Idx2, TknLen2);
                          End Else
                            Inc(Idx2, TknLen2);
                        End;
                      SP_CHAR_NUM_AND:
                        Begin
                          If TknType = SP_JZ Then Begin
                            Dec(SkipCnt);
                            If SkipCnt = -1 Then Begin
                              // Remove the AND and fill the original token's value with the current position.
                              Tokens := Copy(Tokens, 1, Idx3 -1) + Copy(Tokens, Idx2 + TknLen2);
                              pLongWord(@Tokens[Idx])^ := Idx3 - Idx;
                              FixStatements(Idx3, -(SizeOf(TToken) + TknLen2));
                              Changed := True;
                              Break;
                            End Else
                              Inc(Idx2, TknLen2);
                          End Else
                            Inc(Idx2, TknLen2);
                        End;
                      SP_CHAR_OR:
                        Begin
                          If TknType = SP_JNZ Then Begin
                            Dec(SkipCnt);
                            If SkipCnt = -1 Then Begin
                              // Remove the OR and fill the original token's value with the current position.
                              Tokens := Copy(Tokens, 1, Idx3 -1) + Copy(Tokens, Idx2 + TknLen2);
                              pLongWord(@Tokens[Idx])^ := Idx3 - Idx;
                              FixStatements(Idx3, -(SizeOf(TToken) + TknLen2));
                              Changed := True;
                              Break;
                            End Else
                              Inc(Idx2, TknLen2);
                          End Else
                            Inc(Idx2, TknLen2);
                        End;
                    Else
                      Inc(Idx2, TknLen2);
                    End;

                  End;

              Else

                Inc(Idx2, TknLen2);

              End;

            End;

            Inc(Idx, TokenLen);

          End;

      Else

        Inc(Idx, TokenLen);

      End;

    End;

    If Changed Then SP_AddHandlers(Tokens);

  End;

End;

end.
