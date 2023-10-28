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

unit SP_InfixToPostFix;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}

// A syntax checker and "compiler" which produces a String of tokens from an
// input stream of BASIC code.

// When adding new code:

// 1. Create a new token for it in SP_Tokenise.pas. If the keyword is to have more than one function, create those too.
// 2. Keywords, Add an entry to SP_Convert_Keyword. If the keyword spawns other keywords, override KeyWordID.
// 3. For functions, add them to both SP_TestExpr and SP_Convert_Expr.
// 4. New operators are hard. Ask Dunny to do it.

interface

Uses SP_SysVars, SP_Tokenise, SP_Errors, SP_Util, Classes, SP_Variables;

Type

  TSP_Operand = Packed Record
    Content: aString;
    OpType: Integer;
    StrPos: Integer;
  End;

  TSP_Operator = Packed Record
    Content: aString;
    Priority: Integer;
    StrPos: Integer;
  End;

Function  CreateToken(tType: Byte; tVarious, tLength: LongWord): aString;
Procedure SP_Convert_ToPostFix(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode);
Procedure SP_FixOnReturns(Var Tokens, stList: aString; Position: Integer);
Function  SP_Convert_KeyWord(Var Tokens: aString; Var Position: Integer; Var KeyWordID: LongWord; Var Error: TSP_ErrorCode; Var StList: aString): aString;
Function  SP_GetPriority(Symbol: aChar): Integer;
Procedure SP_UnStackOperator;
Procedure SP_DeleteStackItem(Index: Integer);
Procedure SP_StackExpression(Expr: aString);
Function  SP_ExtractArray(Var Tokens: aString; Var Position: Integer; Preserve: Boolean; Var Error: TSP_ErrorCode): aString;
Function  SP_Test_Expr(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode; Var Optimise: Boolean): Integer;
Function  SP_Convert_Expr(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode; StartPri: Integer): aString;
Function  SP_Process_IN(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Procedure SP_OptimiseStack(Var Tokens: aString; Var tPos: Integer; Var Error: TSP_ErrorCode);
Procedure SP_PeepholeOptimiser(Var Tokens: aString; Var tPos: Integer; Var Error: TSP_ErrorCode);
Procedure SP_RemoveFunctionMarkers(Var Tokens: aString);
Procedure SP_RemoveBlocks(var s: aString);

Procedure SP_AlphaCheck(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer);
Function  SP_Convert_ENUM(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_PRINT(Var inKeyword: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode; Var KID: LongWord): aString;
Function  SP_Convert_CLIP(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_ITALIC(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_BOLD(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_INK(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_PAPER(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_INVERSE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_OVER(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_TRANSPARENT(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_Var_Assign(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_LET(Var Tokens: aString; Var KeyWordID: LongWord; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_CLS(Var Tokens: aString; Var Position: Integer; Var KeyWordID: LongWord; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_DIM(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_RUN(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_GO(Var KeyWordID, InitialKWID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_RETURN(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_STOP(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_FOR(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_NEXT(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_IF(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode; Var StList: aString): aString;
Function  SP_Convert_Embedded_Colours(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_PLOT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_PARTICLE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_PAUSE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_DRAW(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_CIRCLE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_ELLIPSE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_CURVE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_RANDOMIZE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_OLD(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_SAVE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_LOAD(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_MERGE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_INC(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_DEC(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_SWAP(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_PALETTE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_DO(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_LOOP(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_DATA(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_READ(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_RESTORE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_EXIT(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_QUIT(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_REM(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_SCREEN(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_WINDOW(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_POKE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_NEW(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_ON(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode; Var StList: aString): aString;
Function  SP_Convert_CLEAR(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_YIELD(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_FILL(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_RECTANGLE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_POLYGON(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_DEGREES(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_RADIANS(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_TURNS(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_GRADIANS(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_RECOVER(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_FONT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_BANK(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_WAIT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_STREAM(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_SETDIR(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_COMPILE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_LABEL(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_EXECUTE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_ROTATE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_FACE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_MOVE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_SAMPLE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_CHANNEL(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_MUSIC(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_PLAY(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_ELSE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode; Var StList: aString): aString;
Function  SP_Convert_ENDIF: aString;
Function  SP_Convert_DEF_STRUCT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_DEF_PROC(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_PROC(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_END_PROC(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_GLOBAL(Var Tokens: aString; Var Position: Integer; Var KeyWordID: LongWord; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_DEF_FN(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_EXIT_PROC(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_POKES(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_CAT(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_ERASE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_SPRITE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_GRAPHIC(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_RENUMBER(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_CONTINUE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_LIST(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_DELETE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_PACKAGE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_ASSIGN(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_COPY(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_MAKEDIR(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_RENAME(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_TILEMAP(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_STRUCT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_INPUT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_MENU(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_MOUSE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_DEBUG(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_FPS(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_PUSH(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_POP(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_VOLUME(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_OPTION(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_SETNUB(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_SETCPU(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_MULTIPLOT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_TRANSFORM3D(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_TRANSFORM2D(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_PROJECT3D(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_RAINBOW(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_KEYBOARD(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_ORIGIN(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_BEEP(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_OUT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_SHOWGUIDE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_HELP(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_CASE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_WHEN(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_OTHERWISE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_END_CASE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_INCLUDE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_HALT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_SORT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_KEY(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_MAT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_CONST(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_SCALE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_ZONE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_UNDIM(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_FILTER(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_MEMWRITE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_MEMWRITES(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_FORCE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Function  SP_Convert_INSTALL(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;

Var

  SP_OperandStack: Array[0..1024] of TSP_Operand;
  SP_OperatorStack: Array[0..1024] of TSP_Operator;
  SP_OperandPtr, SP_OperatorPtr, IFCount: Integer;
  DoingRepeatParams, CanNewStatement: Boolean;

implementation

Uses SP_Interpret_PostFix, {$IFDEF FPC}LclIntf{$ELSE}Windows{$ENDIF};

Function CreateToken(tType: Byte; tVarious, tLength: LongWord): aString;
Begin

  // Set the token type

  Result := '';
  SetLength(Result, SizeOf(TToken));

  With pToken(@Result[1])^ Do Begin

    Token := tType;
    Handler := @SP_Interpret_UNHANDLED;
    TokenPos := tVarious;
    TokenLen := tLength;
    Cache := 0;
    BPIndex := -1;

  End;

End;

Procedure SP_RemoveBlocks(var s: aString);
Var
  Token: pToken;
  Idx: Integer;
Begin
  Idx := 1;
  While Idx <= Length(s) Do Begin
    Token := pToken(@s[Idx]);
    If Token^.Token = SP_BLOCK_OPT Then
      s := Copy(s, 1, Idx -1) + Copy(s, Idx + SizeOf(TToken), Length(s))
    Else
      If Token^.Token = 255 Then
        Break
      Else
        Inc(Idx, Token^.TokenLen + SizeOf(TToken));
  End;
End;

Procedure SP_Convert_ToPostFix(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode);
Var
  Token: pToken;
  i: Integer;
  IsDirect, doJump, gotKeyword: Boolean;
  Converted, Statement_RPN, StList: aString;
  KeyWordID, OldKeyWordID, KeyWordPos, StatementListPos, Idx, Val, StListLen,
  Statement, NextStatement, stIdx, LineNum: LongWord;
Label
  RepeatParams, Finish;
Begin

  // Creates "code" which will be executed by the interpreter. Takes tokenised code, and spits out:
  // <statementlist><tokenised code>$FF<interpreter p-code>

  Error.Code := SP_ERR_OK;
  Position := 1;
  IsDirect := False;

  Converted := '';
  SP_OperandPtr := -1;
  SP_OperatorPtr := -1;
  KeyWordPos := 0;
  IFCount := 0;

  // Skip the line number, if there is one - if there isn't, then this is a direct command and so
  // needs to be made line 0.

  GotKeyWord := False;
  If Ord(Tokens[Position]) = SP_LINE_NUM Then Begin
    LineNum := pLongWord(@Tokens[Position +1])^;
    If (LineNum < 1) or (LineNum > 999999) Then Begin
      Error.Code := SP_ERR_INVALID_KEYWORD;
      Exit;
    End;
    Inc(Position, 1 + SizeOf(LongWord));
  End Else
    IsDirect := True;

  If Ord(Tokens[Position]) = SP_LINE_LEN Then
    Inc(Position, 1 + SizeOf(LongWord));

  StList := '';
  StatementListPos := Position;

  While True Do Begin

    While (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ':') Do Begin
      IsDirect := False;
      Inc(Position, 2);
    End;

    // Check for a Keyword... If none found and there's a variable to follow, then insert LET.
    // Note that sometimes a function (such as CLIP$) can be assigned to, the LET will pick it up.

    KeyWordID := 0;
    If (Ord(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR]) or ((Ord(Tokens[Position]) = SP_FUNCTION) and SP_IsHybridFn(pLongWord(@Tokens[Position +1])^)) Then
      KeyWordID := SP_KW_IMPLICIT_LET
    Else
      If (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '?') Then Begin
        Inc(Position, 2);
        If Not IsDirect Then
          KeyWordID := SP_KW_PRINT;
      End;

    RepeatParams:

    If (Tokens[Position] = SP_TERMINAL_CHAR) And (KeyWordPos <> 0) Then Goto Finish; // jeez what a hack. This covers the IF c THEN <nothing> case that's valid in Sinclair BASIC.

    If (KeyWordID <> 0) or (Ord(Tokens[Position]) = SP_KEYWORD) Then Begin

      KeyWordPos := Position;

      // Pick up the keyword, so we know which proc to use to grab params.

      If KeyWordID = 0 Then Begin
        Inc(Position);
        KeyWordID := pLongWord(@Tokens[Position])^;
        Inc(Position, SizeOf(LongWord));
      End;
      OldKeyWordID := KeyWordID;

      // Now branch out to get the parameters.

      Statement_RPN := '';
      Statement_RPN := SP_Convert_KeyWord(Tokens, Position, KeyWordID, Error, StList);
      If Error.Code = SP_ERR_OK Then GotKeyWord := True;

      // Remove any optimisation blocking tokens from use of IIF/IIF$

      If Error.Code <> SP_ERR_OK Then Begin
        If GotKeyWord And (Error.Code = SP_ERR_INVALID_KEYWORD) Then
          Error.Code := SP_ERR_SYNTAX_ERROR;
        Error.Position := Position;
        Exit;
      End;

      // Now append the RPN's statement to the end of the statement.

      // If during conversion the KeyWordID becomes zero, then the conversion has inserted its own keywordID values into the stream - so just ignore it.
      If KeyWordID <> 0 Then Statement_RPN := Statement_RPN + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);

      i := 1;
      SP_PeepholeOptimiser(Statement_RPN, i, Error);
      If Error.Code = SP_ERR_OK Then
        SP_RemoveBlocks(Statement_RPN);
      Tokens := Tokens + Statement_RPN;

      // Ok, now we're almost done. If the next symbol is a ':' then we're going to have to loop back around and do another keyword (possibly!).
      // If we encounter a ; here then we're going back around to get some more params for a repeated keyword.
      // Otherwise, tidy things up and exit.

      If (Ord(Tokens[Position]) = SP_SYMBOL) And ((Tokens[Position +1] = ':') or (Tokens[Position +1] = ';')) Then Begin
        Tokens := Tokens + CreateToken(SP_SYMBOL, Position, 1) + aChar(':');
        Inc(Position, 2);
        If Tokens[Position -1] = ';' Then Begin
          Tokens[Position -1] := SP_CHAR_SEMICOLON;
          KeyWordID := OldKeyWordID;
          Goto RepeatParams;
        End;
      End Else
        If (Ord(Tokens[Position]) = SP_KEYWORD) And ((pLongWord(@Tokens[Position +1])^ = SP_KW_THEN) or
                                                     (pLongWord(@Tokens[Position +1])^ = SP_KW_ELSE) or
                                                     (pLongWord(@Tokens[Position +1])^ = SP_KW_ENDIF) or
                                                     (KeyWordID = SP_KW_ELSE)) Then Begin
          If pLongWord(@Tokens[Position +1])^ = SP_KW_THEN Then
            Inc(Position, 1 + SizeOf(LongWord));
          KeyWordID := 0;
        End Else

          If Tokens[Position] = SP_TERMINAL_CHAR Then Begin

            Finish:

            Tokens := Tokens + SP_TERMINAL_CHAR;
            SP_FixOnReturns(Tokens, stList, Position);

            // Fix up the statement list - Statement list ID byte, then a length in 4 bytes, followed by each statement's position
            // as a list of longwords. Inserting the ID byte and the length will cause the tokens in the final code to shift to the right
            // so we anticipate this now and increment the statement positions according to the new length of the statement list.

            Idx := 2 + SizeOf(LongWord);
            StList := aChar(SP_STATEMENTS) + LongWordToString(Length(StList) Div SizeOf(LongWord)) + StList;
            StListLen := Length(StList);
            While integer(Idx) < Length(StList) Do Begin
              Val := pLongWord(@StList[Idx])^;
              Inc(Val, StListLen);
              pLongWord(@StList[Idx])^ := Val;
              Inc(Idx, SizeOf(LongWord));
            End;

            // Now insert the Statement list

            Tokens := Copy(Tokens, 1, StatementListPos -1) + StList + Copy(Tokens, StatementListPos, Length(Tokens));

            // And fix up displacements.
            Statement := 0;
            stIdx := 2 + SizeOf(LongWord);
            NextStatement := pLongWord(@stList[stIdx])^;
            Idx := pLongWord(@StList[2 + SizeOf(LongWord)])^;
            While integer(Idx) < Length(Tokens) Do Begin
              // We keep track of the next statement's position in the string, and when we move past it we
              // increment the current statement number and get the info on the next statement (if it exists).
              If Idx >= NextStatement Then Begin
                Inc(Statement);
                Inc(stIdx, SizeOf(LongWord));
                If Integer(stIdx) > Length(stList) Then
                  nextStatement := Length(Tokens) +1
                Else
                  NextStatement := pLongWord(@StList[stIdx])^;
              End;
              doJump := True;
              Token := @Tokens[Idx];
              Case Token^.Token of
                SP_DISPLACEMENT:
                  Begin
                    // Move the displacement by the size of the new list
                    Token^.TokenPos := Idx + SizeOf(TToken);
                  End;
                SP_KEYWORD, SP_FUNCTION:
                  Begin
                    // The TokenPos member for KEYWORDs and FUNCTIONs is the statement number that they inhabit.
                    Token^.TokenPos := Statement;
                  End;
                SP_IJMP:
                  Begin
                    // This is a special case - jump forward to the expression list so we can parse the keywords.
                    Inc(Idx, SizeOf(TToken));
                    i := pLongWord(@Tokens[Idx])^ + 2; // number of exprs
                    Inc(Idx, i * SizeOf(LongWord)); // now after the next line, Idx will point to the first expression.
                    doJump := False;
                  End;
              End;
              If doJump Then
                Inc(Idx, Token^.TokenLen + SizeOf(TToken));
            End;
            // And *finally* exit with some nicely encoded... code :)
            SP_AddHandlers(Tokens);
            Exit;
          End Else Begin
            If (((Ord(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ELSE)) And (IFCount > 0)) or
                ((Ord(Tokens[Position]) = SP_NUMVAR) or (Ord(Tokens[Position]) = SP_STRVAR)) or
                ((Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '?')) Then Begin
            End Else Begin
              Error.Code := SP_ERR_ILLEGAL_CHAR;
              Exit;
            End;
          End;

    End Else Begin

      // No valid keyword found - is it a value (line delete)?

      If Tokens = #255#255#255#255 Then Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End;

      If Byte(Tokens[Position]) = SP_TERMINAL Then Begin

        // This was likely just a line number, so insert the (invalid) statement list to keep old legacy code happy and exit now.

        Tokens := Copy(Tokens, 1, Position) + aChar(SP_TERMINAL);
        StList := aChar(SP_STATEMENTS) + LongWordToString(Length(StList) Div SizeOf(LongWord)) + StList;
        Tokens := Copy(Tokens, 1, StatementListPos -1) + StList + Copy(Tokens, StatementListPos, Length(Tokens));
        Exit;

      End;

      Error.Code := SP_ERR_INVALID_KEYWORD;
      Exit;

    End;

  End;

End;

Procedure SP_FixOnReturns(Var Tokens, stList: aString; Position: Integer);
Var
  Idx, PosTkn: Integer;
  Token: pToken;
  TestFlag: Boolean;
Begin

  // If this line contains any of the ON... keywords, then the last statement should be
  // RETURN. If this is not so, add it. This will not show up in the listing, but will
  // make the program look a little less unbalanced.

  Idx := Position;
  TestFlag := False;
  PosTkn := Position;
  Token := @Tokens[Position];
  While Tokens[Idx] = SP_TERMINAL_CHAR Do Inc(Idx);

  While (Idx < Length(Tokens)) And (Tokens[Idx] <> SP_TERMINAL_CHAR) Do Begin
    PosTkn := Idx;
    Token := @Tokens[Idx];
    Inc(Idx, SizeOf(TToken));
    If Token^.Token = SP_KEYWORD Then
      Case pLongWord(@Tokens[Idx])^ Of
        SP_KW_ON, SP_KW_ON_ERR, SP_KW_ON_MOUSEDOWN, SP_KW_ON_MOUSEUP,
        SP_KW_ON_MOUSEMOVE, SP_KW_ON_KEYDOWN, SP_KW_ON_KEYUP, SP_KW_ON_WHEELUP,
        SP_KW_ON_WHEELDOWN, SP_KW_ON_COLLIDE, SP_KW_ON_MENU_HIDE, SP_KW_ON_MENU_SHOW,
        SP_KW_ON_MENUITEM:
          Begin
            TestFlag := True;
          End;
      End;
    Inc(Idx, Token^.TokenLen);
  End;
  If TestFlag Then
    If Not((Token^.Token = SP_KEYWORD) And (pLongWord(@Tokens[PosTkn + SizeOf(TToken)])^ = SP_KW_RETURN)) Then Begin
      Tokens := Copy(Tokens, 1, Length(Tokens) -1); // Strip the trailing terminal byte
      StList := StList + LongWordToString(Length(Tokens) +1);
      Tokens := Tokens + CreateToken(SP_SYMBOL, 0, 1) + aChar(':') + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_RETURN) + SP_TERMINAL_CHAR;
    End;

End;

Function SP_Convert_KeyWord(Var Tokens: aString; Var Position: Integer; Var KeyWordID: LongWord; Var Error: TSP_ErrorCode; Var StList: aString): aString;
Var
  i: Integer;
  KeyWordPos, InitialKW: LongWord;
Label
  NextKeyword;
Begin

  DoingRepeatParams := False;
  InitialKW := KeyWordID;
  Result := '';

  // Add a statement entry to the statement list

  StList := StList + LongWordToString(Length(Tokens) +1);

  // And now decode the keyword.

  NextKeyWord:

  KeyWordPos := Position;
  CanNewStatement := True;
  i := Length(Result);

  Case KeyWordID of

    SP_KW_TEXT, SP_KW_PRINT: Result := Result + SP_Convert_PRINT(KeyWordID, Tokens, Position, Error, KeyWordID);
    SP_KW_INK: Result := Result + SP_Convert_INK(Tokens, Position, Error);
    SP_KW_TRANSPARENT, SP_KW_TRANS: Result := Result + SP_Convert_TRANSPARENT(Tokens, Position, Error);
    SP_KW_CLIP: Result := Result + SP_Convert_CLIP(KeyWordID, Tokens, Position, Error);
    SP_KW_PAPER: Result := Result + SP_Convert_PAPER(Tokens, Position, Error);
    SP_KW_INVERSE: Result := Result + SP_Convert_INVERSE(Tokens, Position, Error);
    SP_KW_ITALIC: Result := Result + SP_Convert_INVERSE(Tokens, Position, Error);
    SP_KW_BOLD: Result := Result + SP_Convert_INVERSE(Tokens, Position, Error);
    SP_KW_OVER: Result := Result + SP_Convert_OVER(Tokens, Position, Error);
    SP_KW_SCALE: Result := Result + SP_Convert_SCALE(KeywordID, Tokens, Position, Error);
    SP_KW_LET, SP_KW_IMPLICIT_LET: Result := Result + SP_Convert_LET(Tokens, KeyWordID, Position, Error);
    SP_KW_ENUM: Result := Result + SP_Convert_ENUM(KeywordID, Tokens, Position, Error);
    SP_KW_CLS: Result := Result + SP_Convert_CLS(Tokens, Position, KeyWordID, Error);
    SP_KW_DIM: Result := Result + SP_Convert_DIM(KeyWordID, Tokens, Position, Error);
    SP_KW_RUN: Result := Result + SP_Convert_RUN(Tokens, Position, Error);
    SP_KW_GO, SP_KW_GOTO, SP_KW_GOSUB: Result := Result + SP_Convert_GO(KeyWordID, InitialKW, Tokens, Position, Error);
    SP_KW_RETURN: Result := Result + SP_Convert_RETURN(Tokens, Position, Error);
    SP_KW_STOP: Result := Result + SP_Convert_STOP(Tokens, Position, Error);
    SP_KW_FOR: Result := Result + SP_Convert_FOR(KeyWordID, Tokens, Position, Error);
    SP_KW_NEXT: Result := Result + SP_Convert_NEXT(Tokens, Position, Error);
    SP_KW_IF: Result := Result + SP_Convert_IF(KeyWordID, Tokens, Position, Error, StList);
    SP_KW_PLOT: Result := Result + SP_Convert_PLOT(KeyWordID, Tokens, Position, Error);
    SP_KW_FORCE: Result := Result + SP_Convert_FORCE(KeyWordID, Tokens, Position, Error);
    SP_KW_PARTICLE: Result := Result + SP_Convert_PARTICLE(KeyWordID, Tokens, Position, Error);
    SP_KW_PAUSE: Result := Result + SP_Convert_PAUSE(Tokens, Position, Error);
    SP_KW_DRAW: Result := Result + SP_Convert_DRAW(KeyWordID, Tokens, Position, Error);
    SP_KW_CIRCLE: Result := Result + SP_Convert_CIRCLE(KeyWordID, Tokens, Position, Error);
    SP_KW_ELLIPSE: Result := Result + SP_Convert_ELLIPSE(KeyWordID, Tokens, Position, Error);
    SP_KW_CURVE: Result := Result + SP_Convert_CURVE(KeyWordID, Tokens, Position, Error);
    SP_KW_RANDOMIZE: Result := Result + SP_Convert_RANDOMIZE(Tokens, Position, Error);
    SP_KW_OLD: Result := Result + SP_Convert_OLD(Tokens, Position, Error);
    SP_KW_SAVE: Result := Result + SP_Convert_SAVE(KeyWordID, Tokens, Position, Error);
    SP_KW_LOAD: Result := Result + SP_Convert_LOAD(KeyWordID, Tokens, Position, Error);
    SP_KW_MERGE: Result := Result + SP_Convert_MERGE(KeyWordID, Tokens, Position, Error);
    SP_KW_INC: Result := Result + SP_Convert_INC(KeyWordID, Tokens, Position, Error);
    SP_KW_DEC: Result := Result + SP_Convert_DEC(KeyWordID, Tokens, Position, Error);
    SP_KW_SWAP: Result := Result + SP_Convert_SWAP(KeyWordID, Tokens, Position, Error);
    SP_KW_PALETTE: Result := Result + SP_Convert_PALETTE(KeyWordID, Tokens, Position, Error);
    SP_KW_DO: Result := Result + SP_Convert_DO(KeyWordID, Tokens, Position, Error);
    SP_KW_LOOP: Result := Result + SP_Convert_LOOP(KeyWordID, Tokens, Position, Error);
    SP_KW_READ: Result := Result + SP_Convert_READ(KeyWordID, Tokens, Position, Error);
    SP_KW_DATA: Result := Result + SP_Convert_DATA(Tokens, Position, Error);
    SP_KW_RESTORE: Result := Result + SP_Convert_RESTORE(Tokens, Position, Error);
    SP_KW_EXIT: Result := Result + SP_Convert_EXIT(Tokens, Position, Error);
    SP_KW_QUIT: Result := Result + SP_Convert_QUIT(Tokens, Position, Error);
    SP_KW_REM: Result := Result + SP_Convert_REM(Tokens, Position, Error);
    SP_KW_SCREEN: Result := Result + SP_Convert_SCREEN(KeyWordID, Tokens, Position, Error);
    SP_KW_WINDOW: Result := Result + SP_Convert_WINDOW(KeyWordID, Tokens, Position, Error);
    SP_KW_POKE, SP_KW_DPOKE, SP_KW_QPOKE, SP_KW_FPOKE: Result := Result + SP_Convert_POKE(Tokens, Position, Error);
    SP_KW_NEW: Result := Result + SP_Convert_NEW(Tokens, Position, Error);
    SP_KW_ON: Result := Result + SP_Convert_ON(KeyWordID, Tokens, Position, Error, StList);
    SP_KW_CLEAR: Result := Result + SP_Convert_CLEAR(KeyWordID, Tokens, Position, Error);
    SP_KW_YIELD: Result := Result + SP_Convert_YIELD(Tokens, Position, Error);
    SP_KW_FILL: Result := Result + SP_Convert_FILL(KeyWordID, Tokens, Position, Error);
    SP_KW_RECTANGLE: Result := Result + SP_Convert_RECTANGLE(KeyWordID, Tokens, Position, Error);
    SP_KW_POLYGON: Result := Result + SP_Convert_POLYGON(KeyWordID, Tokens, Position, Error);
    SP_KW_DEGREES: Result := Result + SP_Convert_DEGREES(Tokens, Position, Error);
    SP_KW_RADIANS: Result := Result + SP_Convert_RADIANS(Tokens, Position, Error);
    SP_KW_TURNS: Result := Result + SP_Convert_TURNS(Tokens, Position, Error);
    SP_KW_GRADIANS: Result := Result + SP_Convert_GRADIANS(Tokens, Position, Error);
    SP_KW_RECOVER: Result := Result + SP_Convert_RECOVER(Tokens, Position, Error);
    SP_KW_FONT: Result := Result + SP_Convert_FONT(KeyWordID, Tokens, Position, Error);
    SP_KW_BANK: Result := Result + SP_Convert_BANK(KeyWordID, Tokens, Position, Error);
    SP_KW_WAIT: Result := Result + SP_Convert_WAIT(KeyWordID, Tokens, Position, Error);
    SP_KW_STREAM: Result := Result + SP_Convert_STREAM(KeyWordID, Tokens, Position, Error);
    SP_KW_SETDIR, SP_KW_CD: Result := Result + SP_Convert_SETDIR(Tokens, Position, Error);
    SP_KW_COMPILE: Result := Result + SP_Convert_COMPILE(Tokens, Position, Error);
    SP_KW_LABEL: Result := Result + SP_Convert_LABEL(Tokens, Position, Error);
    SP_KW_EXECUTE: Result := Result + SP_Convert_EXECUTE(Tokens, Position, Error);
    SP_KW_ROTATE: Result := Result + SP_Convert_ROTATE(KeyWordID, Tokens, Position, Error);
    SP_KW_MOVE: Result := Result + SP_Convert_MOVE(KeyWordID, Tokens, Position, Error);
    SP_KW_FACE: Result := Result + SP_Convert_FACE(Tokens, Position, Error);
    SP_KW_SAMPLE: Result := Result + SP_Convert_SAMPLE(KeyWordID, Tokens, Position, Error);
    SP_KW_CHANNEL: Result := Result + SP_Convert_CHANNEL(KeyWordID, Tokens, Position, Error);
    SP_KW_MUSIC: Result := Result + SP_Convert_MUSIC(KeyWordID, Tokens, Position, Error);
    SP_KW_PLAY: Result := Result + SP_Convert_PLAY(KeyWordID, Tokens, Position, Error);
    SP_KW_ELSE: Result := Result + SP_Convert_ELSE(KeyWordID, Tokens, Position, Error, StList);
    SP_KW_ENDIF: Result := Result + SP_Convert_ENDIF;
    SP_KW_DEF_STRUCT: Result := Result + SP_Convert_DEF_STRUCT(KeyWordID, Tokens, Position, Error);
    SP_KW_DEF_PROC: Result := Result + SP_Convert_DEF_PROC(KeyWordID, Tokens, Position, Error);
    SP_KW_PROC: Result := Result + SP_Convert_PROC(Tokens, Position, Error);
    SP_KW_ENDPROC: Result := Result + SP_Convert_END_PROC(Tokens, Position, Error);
    SP_KW_GLOBAL: Result := Result + SP_Convert_GLOBAL(Tokens, Position, KeywordID, Error);
    SP_KW_LOCAL: Result := Result + SP_Convert_GLOBAL(Tokens, Position, KeyWordID, Error);
    SP_KW_DEF_FN: Result := Result + SP_Convert_DEF_FN(Tokens, Position, Error);
    SP_KW_EXIT_PROC: Result := Result + SP_Convert_EXIT_PROC(Tokens, Position, Error);
    SP_KW_POKES: Result := Result + SP_Convert_POKES(Tokens, Position, Error);
    SP_KW_CAT: Result := Result + SP_Convert_CAT(Tokens, Position, Error);
    SP_KW_ERASE: Result := Result + SP_Convert_ERASE(KeyWordID, Tokens, Position, Error);
    SP_KW_DELETE: Result := Result + SP_Convert_DELETE(KeyWordID, Tokens, Position, Error);
    SP_KW_SPRITE: Result := Result + SP_Convert_SPRITE(KeyWordID, Tokens, Position, Error);
    SP_KW_GRAPHIC: Result := Result + SP_Convert_GRAPHIC(KeyWordID, Tokens, Position, Error);
    SP_KW_RENUMBER: Result := Result + SP_Convert_RENUMBER(KeyWordID, Tokens, Position, Error);
    SP_KW_CONTINUE: Result := Result + SP_Convert_CONTINUE(Tokens, Position, Error);
    SP_KW_LIST: Result := Result + SP_Convert_LIST(KeyWordID, Tokens, Position, Error);
    SP_KW_PACKAGE: Result := Result + SP_Convert_PACKAGE(KeyWordID, Tokens, Position, Error);
    SP_KW_ASSIGN: Result := Result + SP_Convert_ASSIGN(Tokens, Position, Error);
    SP_KW_COPY: Result := Result + SP_Convert_COPY(Tokens, Position, Error);
    SP_KW_MAKEDIR: Result := Result + SP_Convert_MAKEDIR(Tokens, Position, Error);
    SP_KW_RENAME: Result := Result + SP_Convert_RENAME(Tokens, Position, Error);
    SP_KW_TILEMAP: Result := Result + SP_Convert_TILEMAP(KeyWordID, Tokens, Position, Error);
    SP_KW_STRUCT: Result := Result + SP_Convert_STRUCT(KeyWordID, Tokens, Position, Error);
    SP_KW_INPUT: Result := Result + SP_Convert_INPUT(KeyWordID, Tokens, Position, Error);
    SP_KW_MOUSE: Result := Result + SP_Convert_MOUSE(KeyWordID, Tokens, Position, Error);
    SP_KW_DEBUG: Result := Result + SP_Convert_DEBUG(KeyWordID, Tokens, Position, Error);
    SP_KW_FPS: Result := Result + SP_Convert_FPS(Tokens, Position, Error);
    SP_KW_PUSH: Result := Result + SP_Convert_PUSH(Tokens, Position, Error);
    SP_KW_POP: Result := Result + SP_Convert_POP(KeyWordID, Tokens, Position, Error);
    SP_KW_VOLUME: Result := Result + SP_Convert_VOLUME(Tokens, Position, Error);
    SP_KW_OPTION: Result := Result + SP_Convert_OPTION(Tokens, Position, Error);
    SP_KW_SETNUB: Result := Result + SP_Convert_SETNUB(Tokens, Position, Error);
    SP_KW_SETCPU: Result := Result + SP_Convert_SETCPU(Tokens, Position, Error);
    SP_KW_MULTIPLOT: Result := Result + SP_Convert_MULTIPLOT(KeyWordID, Tokens, Position, Error);
    SP_KW_TRANSFORM3D: Result := Result + SP_Convert_TRANSFORM3D(Tokens, Position, Error);
    SP_KW_TRANSFORM2D: Result := Result + SP_Convert_TRANSFORM2D(Tokens, Position, Error);
    SP_KW_PROJECT3D: Result := Result + SP_Convert_PROJECT3D(Tokens, Position, Error);
    SP_KW_RAINBOW: Result := Result + SP_Convert_RAINBOW(Tokens, Position, Error);
    SP_KW_KEYBOARD: Result := Result + SP_Convert_KEYBOARD(Tokens, Position, Error);
    SP_KW_ORIGIN: Result := Result + SP_Convert_ORIGIN(KeyWordID, Tokens, Position, Error);
    SP_KW_BEEP: Result := Result + SP_Convert_BEEP(KeywordID, Tokens, Position, Error);
    SP_KW_OUT: Result := Result + SP_Convert_OUT(KeyWordID, Tokens, Position, Error);
    SP_KW_HELP: Result := Result + SP_Convert_HELP(KeyWordID, Tokens, Position, Error);
    SP_KW_CASE: Result := Result + SP_Convert_CASE(KeyWordID, Tokens, Position, Error);
    SP_KW_WHEN: Result := Result + SP_Convert_WHEN(KeyWordID, Tokens, Position, Error);
    SP_KW_OTHERWISE: Result := Result + SP_Convert_OTHERWISE(KeyWordID, Tokens, Position, Error);
    SP_KW_END_CASE: Result := Result + SP_Convert_END_CASE(KeyWordID, Tokens, Position, Error);
    SP_KW_INCLUDE: Result := Result + SP_Convert_INCLUDE(KeywordID, Tokens, Position, Error);
    SP_KW_HALT: Result := Result + SP_Convert_HALT(KeyWordID, Tokens, Position, Error);
    SP_KW_SORT: Result := Result + SP_Convert_SORT(KeyWordID, Tokens, Position, Error);
    SP_KW_KEY: Result := Result + SP_Convert_KEY(KeyWordID, Tokens, Position, Error);
    SP_KW_MAT: Result := Result + SP_Convert_MAT(KeyWordID, Tokens, Position, Error);
    SP_KW_CONST: Result := Result + SP_Convert_CONST(KeyWordID, Tokens, Position, Error);
    SP_KW_ZONE: Result := Result + SP_Convert_ZONE(KeyWordID, Tokens, Position, Error);
    SP_KW_UNDIM: Result := Result + SP_Convert_UNDIM(KeyWordID, Tokens, Position, Error);
    SP_KW_FILTER: Result := Result + SP_Convert_FILTER(KeyWordID, Tokens, Position, Error);
    SP_KW_MENU: Result := Result + SP_Convert_MENU(KeyWordID, Tokens, Position, Error);
    SP_KW_MEMWRITE, SP_KW_MEMWRITED, SP_KW_MEMWRITEQ, SP_KW_MEMWRITEF: Result := Result + SP_Convert_MEMWRITE(KeyWordID, Tokens, Position, Error);
    SP_KW_MEMWRITES: Result := Result + SP_Convert_MEMWRITES(KeyWordID, Tokens, Position, Error);
    SP_KW_INSTALL: Result := Result + SP_Convert_INSTALL(KeywordID, Tokens, Position, Error);

  Else

    Error.Code := SP_ERR_INVALID_KEYWORD;

  End;

  If (Error.Code = SP_ERR_OK) And (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] in [';', SP_CHAR_SEMICOLON]) Then Begin
    If KeyWordID <> 0 Then Result := Result + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);
    SP_PeepholeOptimiser(Result, i, Error);
    If CanNewStatement Then
      StList := StList + LongWordToString(Length(Tokens) + Length(Result) + 1);
    Tokens[Position +1] := SP_CHAR_SEMICOLON;
    KeyWordID := InitialKW;
    DoingRepeatParams := True;
    Inc(Position, 2);
    Goto NextKeyWord;
  End;

End;

Function SP_GetPriority(Symbol: aChar): Integer; Inline;
Begin

  // Returns the priority (BODMAS) of an operator.

  Case Symbol Of
    '(':
      Result := 14;
    '^':
      Result := 13;
    SP_CHAR_UNARYM, SP_CHAR_UNARYP, SP_CHAR_BITWISE_NOT, '!':
      Result := 12;
    '*', '/', SP_CHAR_MOD, SP_CHAR_MUL, SP_CHAR_DIV:
      Result := 11;
    '+', '-', SP_CHAR_NUM_PLUS, SP_CHAR_STR_PLUS, SP_CHAR_ADD, SP_CHAR_SUB:
      Result := 10;
    SP_CHAR_SHL, SP_CHAR_SHR:
      Result := 9;
    '&':
      Result := 8;
    SP_CHAR_XOR:
      Result := 7;
    '|':
      Result := 6;
    '<', '>', SP_CHAR_GTE, SP_CHAR_LTE, SP_CHAR_NUM_GTE, SP_CHAR_STR_GTE, SP_CHAR_NUM_LES, SP_CHAR_STR_LES, SP_CHAR_NUM_GTR, SP_CHAR_STR_GTR:
      Result := 5;
    '=', SP_CHAR_DNE, SP_CHAR_NUM_EQU, SP_CHAR_STR_EQU, SP_CHAR_NUM_DNE, SP_CHAR_STR_DNE:
      Result := 4;
    SP_CHAR_NOT:
      Result := 3;
    SP_CHAR_AND, SP_CHAR_NUM_AND, SP_CHAR_STR_AND, SP_CHAR_EQV, SP_CHAR_IMP:
      Result := 2;
    SP_CHAR_OR:
      Result := 1;
  Else
    Result := 0;
  End;

End;


Function SP_Test_Expr(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode; Var Optimise: Boolean): Integer;
Var
  Symbol: aChar;
  SliceFlags: Byte;
  Idx, NumIndices, nIdx, NumParams, FnToken: LongWord;
  Stack: Array [0..1024] of Integer;
  StackPtr, FnType, NumTerms, tIdx, INType: Integer;
  PrevStruct: Boolean;
  LastValue, nIdxDbl: aFloat;
  Token: pToken;
  Tkn: TToken;
Begin

  // This performs a "dummy" evaluation of the expression passed, and returns the type of expression encountered
  // and any errors if there are any. It basically interprets the expression in the same way that a real run-through
  // would.

  // The optimise flag is set to true on entry by the parent proc. During testing, if certain functions and ops are
  // encountered that rely on a particular user-created state then it's set false.

  Token := @Tkn;
  Token^.Token := 0;

  StackPtr := -1;
  Idx := 1;
  LastValue := 0;
  Result := 0;

  While Integer(Idx) <= Length(Tokens) Do Begin

    PrevStruct := Token^.Token in [SP_STRUCT_MEMBER_N, SP_STRUCT_MEMBER_S];

    Token := @Tokens[Idx];
    Inc(Idx, SizeOf(TToken));

    Case Token^.Token of

      SP_JZ, SP_JNZ:
        Begin
          // Do Nothing - we're not interested in these
        End;

      SP_INTEGER:
        Begin
          Stack[StackPtr] := SP_VALUE;
        End;

      SP_LABEL:
        Begin
          Inc(StackPtr);
          Stack[StackPtr] := SP_LABEL;
          Optimise := False;
        End;

      SP_RANGE, SP_RANGE_LESS, SP_RANGE_GREATER, SP_RANGE_ARRAYNUM, SP_RANGE_ARRAYSTR:
        Begin
          Inc(StackPtr);
          Stack[StackPtr] := Token^.Token;
        End;

      SP_STRUCT_MEMBER_N, SP_STRUCT_MEMBER_S:
        Begin
          If StackPtr >= 0 Then Begin
            If Not (Stack[StackPtr] in [SP_STRVAR, SP_STRVAR_EVAL]) or PrevStruct Then Begin
              Error.Code := SP_ERR_INVALID_STRUCT_MEMBER;
              Result := SP_UNKNOWN;
              Position := Token^.TokenPos;
              Exit;
            End Else Begin
              If Token^.Token = SP_STRUCT_MEMBER_N Then
                Stack[StackPtr] := SP_VALUE
              Else
                Stack[StackPtr] := SP_STRING;
            End;
            Optimise := False;
          End;
        End;

      SP_SLICER:
        Begin
          SliceFlags := pByte(@Tokens[Idx])^; // Value in content
          If SliceFlags And 8 = 0 Then
            If SliceFlags And 1 = 1 Then Begin
              If Stack[StackPtr] <> SP_VALUE Then Begin
                Error.Code := SP_ERR_INVALID_NUMEXPR;
                Result := SP_UNKNOWN;
                Position := Token^.TokenPos;
                Exit;
              End;
              Dec(StackPtr);
            End;
            If SliceFlags And 2 = 2 Then Begin
              If Stack[StackPtr] <> SP_VALUE Then Begin
                Error.Code := SP_ERR_INVALID_NUMEXPR;
                Position := Token^.TokenPos;
                Result := SP_UNKNOWN;
                Exit;
              End;
              Dec(StackPtr);
            End;
          If Not (Stack[StackPtr] in [SP_STRING, SP_STRVAR]) Then Begin
            Error.Code := SP_ERR_MISSING_STREXPR;
            Position := Token^.TokenPos;
            Result := SP_UNKNOWN;
            Exit;
          End Else
            Stack[StackPtr] := SP_STRING;
        End;

      SP_ARRAY, SP_NUM_ARRAY_PTR:
        Begin
          Optimise := False;
          NumIndices := pLongWord(@Tokens[Idx])^; // Value in content
          While NumIndices > 0 Do Begin
            If Stack[StackPtr] = SP_VALUE Then Begin
              Dec(StackPtr);
              Dec(NumIndices);
            End Else Begin
              If (Stack[StackPtr] = SP_STRING) And (NumIndices = 1) Then Begin
                Dec(StackPtr);
                Dec(NumIndices);
              End Else Begin
                Error.Code := SP_ERR_INVALID_NUMEXPR;
                Position := Token^.TokenPos;
                Exit;
              End;
            End;
          End;

          If Token^.Token = SP_NUM_ARRAY_PTR Then
            If Stack[StackPtr] = SP_STRVAR Then Begin
              Error.Code := SP_ERR_SYNTAX_ERROR;
              Position := Token^.TokenPos;
              Exit;
            End Else Begin
              Inc(Idx, Token^.TokenLen);
              Continue;
            End;

          // If numindices (the longword pointer) is 0, then current stack item must be a string/strvar and the previous must be a strvar/numvar.
          // If numindices is >1, then the current stack item must be a numvar/strvar and not a string.

          If pLongWord(@Tokens[Idx])^ = 0 Then
            If (Stack[StackPtr] in [SP_STRING, SP_STRVAR]) Then Begin
              If Not (Stack[StackPtr -1] in [SP_STRVAR, SP_NUMVAR]) Then Begin
                Error.Code := SP_ERR_ARRAY_NOT_FOUND;
                Position := Token^.TokenPos;
                Exit;
              End;
            End Else Begin
              Error.Code := SP_ERR_ARRAY_NOT_FOUND;
              Position := Token^.TokenPos;
              Exit;
            End;

          If pLongWord(@Tokens[Idx])^ > 1 Then
            If Not (Stack[StackPtr] in [SP_STRVAR, SP_NUMVAR]) Then Begin
              Error.Code := SP_ERR_ARRAY_NOT_FOUND;
              Position := Token^.TokenPos;
              Exit;
            End;

          If (Stack[StackPtr] = SP_STRING) and (pLongWord(@Tokens[Idx])^ = 0) Then // Value still in content
            Dec(StackPtr);
          If StackPtr >= 0 Then
            If Stack[StackPtr] = SP_NUMVAR Then
              Stack[StackPtr] := SP_VALUE
            Else
              If (Integer(Idx + Token^.TokenLen) > Length(Tokens)) or (Not (pToken(@Tokens[Idx + Token^.TokenLen])^.Token in [SP_STRUCT_MEMBER_N, SP_STRUCT_MEMBER_S])) Then
                Stack[StackPtr] := SP_STRING;
        End;

      SP_NUMVAR:
        Begin
          Inc(StackPtr);
          Stack[StackPtr] := SP_NUMVAR;
          Optimise := False;
        End;

      SP_STRVAR, SP_STRVARPTR:
        Begin
          Inc(StackPtr);
          Stack[StackPtr] := SP_STRVAR;
          Optimise := False;
        End;

      SP_ARRAY_ASSIGN:
        Begin
          Inc(StackPtr);
          Stack[StackPtr] := SP_VALUE;
          NumIndices := pLongWord(@Tokens[Idx +1])^; // Value in content
          Inc(Idx, NumIndices * (SizeOf(TToken) + SizeOf(aFloat))); // Each index is a VALUE token
        End;

      SP_SLICE_ASSIGN:
        Begin
          Inc(StackPtr);
          Stack[StackPtr] := SP_STRING;
          NumIndices := pLongWord(@Tokens[Idx +1])^;
          Inc(Idx, NumIndices * (SizeOf(TToken) + SizeOf(aFloat)));
        End;

      SP_VALUE, SP_NUMVAR_EVAL, SP_NUMVARSQ, SP_DISPLACEMENT:
        Begin
          Inc(StackPtr);
          Stack[StackPtr] := SP_VALUE;
          If Token^.Token in [SP_NUMVAR_EVAL, SP_NUMVARSQ, SP_DISPLACEMENT] Then
            Optimise := False;
          If Token^.Token = SP_VALUE Then LastValue := gaFloat(@Tokens[Idx]); // Value in content
        End;

      SP_STRING, SP_STRVAR_EVAL:
        Begin
          Inc(StackPtr);
          Stack[StackPtr] := SP_STRING;
          If Token^.Token = SP_STRVAR_EVAL Then Optimise := False;
        End;

      SP_SYMBOL:
        Begin
          Symbol := Tokens[Idx]; // Value in content
          Case Symbol of
            SP_CHAR_UNARYM, SP_CHAR_UNARYP, SP_CHAR_NOT, SP_CHAR_BITWISE_NOT, '!':
              Begin
                if (StackPtr > 0) and (Stack[StackPtr] <> SP_VALUE) Then
                  If Not ((Stack[StackPtr] = SP_STRING) And (Symbol = SP_CHAR_BITWISE_NOT)) Then Begin
                    Position := Token^.TokenPos;
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End Else
                    Tokens[Idx] := SP_CHAR_STRING_NOT;
              End;
            SP_CHAR_NUM_PLUS, SP_CHAR_INT_PLUS, SP_CHAR_NUM_EQU, SP_CHAR_STR_EQU, SP_CHAR_NUM_LES, SP_CHAR_STR_LES, SP_CHAR_NUM_LTE,
            SP_CHAR_STR_LTE, SP_CHAR_NUM_DNE, SP_CHAR_STR_DNE, SP_CHAR_NUM_GTE, SP_CHAR_STR_GTE, SP_CHAR_NUM_GTR, SP_CHAR_STR_GTR:
              Begin
                Dec(StackPtr);
                If StackPtr >= 0 Then
                  Stack[StackPtr] := SP_VALUE;
              End;
            SP_CHAR_INCVAR, SP_CHAR_DECVAR, SP_CHAR_MULVAR, SP_CHAR_DIVVAR, SP_CHAR_POWVAR, SP_CHAR_MODVAR, SP_CHAR_ANDVAR, SP_CHAR_XORVAR, SP_CHAR_ORVAR, SP_CHAR_NOTVAR:
              Begin
                Dec(StackPtr);
                If (StackPtr >= 0) And (Stack[StackPtr] = SP_NUMVAR) Then
                  Stack[StackPtr] := SP_VALUE
                Else Begin
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;
            SP_CHAR_STR_PLUS:
              Begin
                Dec(StackPtr);
                If StackPtr >= 0 Then
                  Stack[StackPtr] := SP_STRING;
              End;
            '+', SP_CHAR_ADD:
              Begin
                If StackPtr > 0 Then Begin
                  If (Stack[StackPtr] = SP_VALUE) and (Stack[StackPtr -1] = SP_VALUE) Then Begin
                    Dec(StackPtr);
                    If StackPtr >= 0 Then
                      Stack[StackPtr] := SP_VALUE;
                    If Symbol = '+' Then
                      Tokens[Idx] := aChar(SP_CHAR_NUM_PLUS)
                    Else
                      Tokens[Idx] := aChar(SP_CHAR_INT_PLUS);
                  End Else
                    If (Stack[StackPtr] = SP_STRING) and (Stack[StackPtr -1] = SP_STRING) Then Begin
                      Dec(StackPtr);
                      If StackPtr >= 0 Then
                        Stack[StackPtr] := SP_STRING;
                      Tokens[Idx] := aChar(SP_CHAR_STR_PLUS); // Value in content
                    End Else Begin
                      Position := Token^.TokenPos;
                      Error.Code := SP_ERR_MIXED_TYPES;
                      Exit;
                    End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;
            '>', '<', '=', SP_CHAR_GTE, SP_CHAR_LTE, SP_CHAR_DNE:
              Begin
                If StackPtr > 0 Then Begin
                  If (Stack[StackPtr] = SP_VALUE) and (Stack[StackPtr -1] = SP_VALUE) Then Begin
                    Dec(StackPtr);
                    If StackPtr >= 0 Then
                      Stack[StackPtr] := SP_VALUE;
                    Case Symbol of // All values in content
                      '=': Tokens[Idx] := SP_CHAR_NUM_EQU;
                      '<': Tokens[Idx] := SP_CHAR_NUM_LES;
                      '>': Tokens[Idx] := SP_CHAR_NUM_GTR;
                      SP_CHAR_GTE: Tokens[Idx] := SP_CHAR_NUM_GTE;
                      SP_CHAR_LTE: Tokens[Idx] := SP_CHAR_NUM_LTE;
                      SP_CHAR_DNE: Tokens[Idx] := SP_CHAR_NUM_DNE;
                    End;
                  End Else
                    If (Stack[StackPtr] = SP_STRING) and (Stack[StackPtr -1] = SP_STRING) Then Begin
                      Dec(StackPtr);
                      If StackPtr >= 0 Then
                        Stack[StackPtr] := SP_VALUE;
                      Case Symbol of // All values in content
                        '=': Tokens[Idx] := SP_CHAR_STR_EQU;
                        '<': Tokens[Idx] := SP_CHAR_STR_LES;
                        '>': Tokens[Idx] := SP_CHAR_STR_GTR;
                        SP_CHAR_GTE: Tokens[Idx] := SP_CHAR_STR_GTE;
                        SP_CHAR_LTE: Tokens[Idx] := SP_CHAR_STR_LTE;
                        SP_CHAR_DNE: Tokens[Idx] := SP_CHAR_STR_DNE;
                      End;
                    End Else Begin
                      Position := Token^.TokenPos;
                      Error.Code := SP_ERR_MIXED_TYPES;
                      Exit;
                    End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;
            '*', SP_CHAR_MUL, SP_CHAR_STR_MUL1, SP_CHAR_STR_MUL2:
              Begin
                If StackPtr > 0 Then Begin
                  If (Stack[StackPtr] = SP_VALUE) and (Stack[StackPtr -1] = SP_VALUE) Then Begin
                    Dec(StackPtr);
                    If StackPtr >= 0 Then
                      Stack[StackPtr] := SP_VALUE;
                  End Else
                    If ((Stack[StackPtr] = SP_STRING) and (Stack[StackPtr -1] = SP_VALUE)) Then Begin
                      Dec(StackPtr);
                      If StackPtr >= 0 Then
                        Stack[StackPtr] := SP_STRING;
                      Tokens[Idx] := aChar(SP_CHAR_STR_MUL1);
                    End Else
                      If ((Stack[StackPtr] = SP_VALUE) and (Stack[StackPtr -1] = SP_STRING)) Then Begin
                        Dec(StackPtr);
                        If StackPtr >= 0 Then
                          Stack[StackPtr] := SP_STRING;
                        Tokens[Idx] := aChar(SP_CHAR_STR_MUL2); // Value in content
                      End Else Begin
                        Position := Token^.TokenPos;
                        Error.Code := SP_ERR_MIXED_TYPES;
                        Exit;
                      End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;
            '-', '/', '^', SP_CHAR_DIV, SP_CHAR_SUB, SP_CHAR_OR, SP_CHAR_MOD, SP_CHAR_XOR, SP_CHAR_SHL, SP_CHAR_SHR, '|', '&', SP_CHAR_EQV, SP_CHAR_IMP:
              Begin
                If StackPtr > 0 Then Begin
                  If (Stack[StackPtr] = SP_VALUE) and (Stack[StackPtr -1] = SP_VALUE) Then Begin
                    Dec(StackPtr);
                    If StackPtr >= 0 Then
                      Stack[StackPtr] := SP_VALUE;
                  End Else Begin
                    Position := Token^.TokenPos;
                    Error.Code := SP_ERR_MIXED_TYPES;
                    Exit;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;
            SP_CHAR_AND, SP_CHAR_NUM_AND, SP_CHAR_STR_AND:
              Begin
                If StackPtr > 0 Then Begin
                  If Stack[StackPtr] = SP_VALUE Then Begin
                    Dec(StackPtr);
                    If StackPtr >= 0 Then
                      If Stack[StackPtr] = SP_VALUE Then Begin
                        Tokens[Idx] := SP_CHAR_NUM_AND;
                      End Else Begin
                        If Stack[StackPtr] = SP_STRING Then Begin
                          Tokens[Idx] := SP_CHAR_STR_AND;
                        End Else Begin
                          Position := Token^.TokenPos;
                          Error.Code := SP_ERR_SYNTAX_ERROR;
                          Exit;
                        End;
                      End;
                  End Else Begin
                    Position := Token^.TokenPos;
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;
          Else
            Error.Code := SP_ERR_ILLEGAL_CHAR;
            Position := Token^.TokenPos;
            Exit;
          End;
        End;

      SP_FUNCTION:

        // Due to the nature of the dummy interpreter, any parameters that are passed to functions will have had their
        // expressions resolved by the time the function is actually called (for the most part - see FN and CALL below for
        // an example of an exception). The majority of functions are part of the first few classes, and after that
        // special cases follow.

        Begin

          FnToken := pLongWord(@Tokens[Idx])^; // Value in content

          // Check if this function can be optimised - if its parameters don't rely on user or state defined values
          // then it can usually be optimised. Functions know if they can or not. The exception here is IN, as it
          // inherits the current optimisation state.

          If FnToken >= SP_META_BASE Then Begin
            If SP_OPTIMISE_META_FLAGS[FnToken - SP_META_BASE] = False Then
              Optimise := False;
          End Else
            If SP_OPTIMISE_FLAGS[FnToken - SP_FUNCTION_BASE] = False Then
              If FnToken <> SP_FN_IN Then
                Optimise := False;

          Case FnToken of

            // Functions that take no parameters, and return a number:

            SP_FN_RND, SP_FN_PI, SP_FN_TAU, SP_FN_SCRW, SP_FN_SCRH, SP_FN_CWIN, SP_FN_MOUSEX, SP_FN_MSECS,
            SP_FN_MOUSEY, SP_FN_MOUSEBTN, SP_FN_ERROR_NUM, SP_FN_ERROR_LIN, SP_FN_ERROR_STA, SP_FN_FONTBANK,
            SP_FN_FONTWIDTH, SP_FN_FONTHEIGHT, SP_FN_FONTMODE, SP_FN_FONTTRANSPARENT, SP_FN_MOUSEDX, SP_FN_MOUSEDY,
            SP_FN_HEADING, SP_FN_DRPOSX, SP_FN_DRPOSY, SP_FN_LASTK, SP_FN_FRAMES, SP_FN_TIME, SP_FN_MOUSEWHEEL,
            SP_FN_ITEM, SP_FN_POPLINE, SP_FN_POPST, SP_FN_VOL, SP_FN_LOGW, SP_FN_LOGH, SP_FN_ORGX, SP_FN_ORGY,
            SP_FN_MUSICPOS, SP_FN_MUSICLEN, SP_FN_LASTM, SP_FN_LASTMI, SP_FN_TXTW, SP_FN_TXTH, SP_FN_STK:
              Begin
                Inc(StackPtr);
                Stack[StackPtr] := SP_VALUE;
              End;

            // Functions that take one numeric parameter and return a numeric:

            SP_FN_SIN, SP_FN_COS, SP_FN_TAN, SP_FN_ASN, SP_FN_ACS, SP_FN_ATN, SP_FN_LN, SP_FN_EXP, SP_FN_iRGBtoHSV, SP_FN_iHSVtoRGB,
            SP_FN_INT, SP_FN_SQR, SP_FN_SGN, SP_FN_ABS, SP_FN_USR, SP_FN_NOT, SP_FN_WINW, SP_FN_WINH, SP_FN_WINX, SP_FN_WINY,
            SP_FN_FRAC, SP_FN_CEIL, SP_FN_FLOOR, SP_FN_ODD, SP_FN_EVEN, SP_FN_TRUNC, SP_FN_RED,
            SP_FN_GREEN, SP_FN_BLUE, SP_FN_RGB, SP_FN_KEY, SP_FN_iRGBF, SP_FN_iRGBN, SP_FN_HSV, SP_FN_RGBC,
            SP_FN_HUE, SP_FN_SAT, SP_FN_VALUE, SP_FN_DEGTORAD, SP_FN_RADTODEG, SP_FN_SLEN, SP_FN_SPOS,
            SP_FN_BSIZE, SP_FN_CHPOS, SP_FN_WINOFF, SP_FN_SPRITEX, SP_FN_SPRITEY, SP_FN_SPFCOUNT,
            SP_FN_SPVISIBLE, SP_FN_SPROT, SP_FN_SPSCALE, SP_FN_YEAR, SP_FN_HOUR, SP_FN_MINUTES,
            SP_FN_SECONDS, SP_FN_MILLISECONDS, SP_FN_DAY, SP_FN_MONTH, SP_FN_GFXW, SP_FN_GFXH, SP_FN_GFXT, SP_FN_POWERTWO, SP_FN_INV,
            SP_FN_LOGTWO, SP_FN_WORDSWAP, SP_FN_BYTESWAP, SP_FN_NYBBLESWAP, SP_FN_HIWORD, SP_FN_LOWORD, SP_FN_HIBYTE,
            SP_FN_LOBYTE, SP_FN_NUBMODE, SP_FN_NUBX, SP_FN_NUBY, SP_FN_LTOPX, SP_FN_LTOPY, SP_FN_PTOLX, SP_FN_PTOLY,
            SP_FN_SPFRAME, SP_FN_SPCOLL, SP_FN_MEMRD, SP_FN_DMEMRD, SP_FN_QMEMRD, SP_FN_FMEMRD, SP_FN_DATADDR, SP_FN_WINADDR, SP_FN_PAR,
            SP_FN_SINH, SP_FN_COSH, SP_FN_TANH, SP_FN_ASNH, SP_FN_ACSH, SP_FN_ATNH:

              Begin
                If (StackPtr < 0) or (Stack[StackPtr] <> SP_VALUE) Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Position := Token^.TokenPos;
                  Exit;
                End;
              End;

            // Functions that take a stringvar pointer (which exists on this stack as a STRVAR) and return a numeric:

            SP_FN_STRADDR:
              Begin
                If (StackPtr < 0) Or (Stack[StackPtr] <> SP_STRVAR) Then Begin
                  Error.Code := SP_ERR_MISSING_VAR;
                  Position := Token^.TokenPos;
                  Exit;
                End Else
                  Stack[StackPtr] := SP_VALUE;
              End;

            // Functions that take one String parameter and return a numeric:

            SP_FN_CODE, SP_FN_DCODE, SP_FN_QCODE, SP_FN_FCODE, SP_FN_VAL, SP_FN_LEN, SP_FN_GETOPT, SP_FN_FEXISTS, SP_FN_IVAL:
              Begin
                If (StackPtr < 0) Or (Stack[StackPtr] <> SP_STRING) Then Begin
                  Error.Code := SP_ERR_MISSING_STREXPR;
                  Position := Token^.TokenPos;
                  Exit;
                End Else
                  Stack[StackPtr] := SP_VALUE;
              End;

            // Functions that take a numeric /or/ a string, and return a numeric:

            SP_FN_UDG:
              Begin
                If (StackPtr >= 0) And ((Stack[StackPtr] = SP_STRING) or (Stack[StackPtr] = SP_VALUE)) then
                  Stack[StackPtr] := SP_VALUE
                Else Begin
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Position := Token^.TokenPos;
                  Exit;
                End;
              End;

            // Functions that take a numeric /or/ a string, and return a string:

            SP_FN_UDGS:
              Begin
                If (StackPtr >= 0) And ((Stack[StackPtr] = SP_STRING) or (Stack[StackPtr] = SP_VALUE)) then
                  Stack[StackPtr] := SP_STRING
                Else Begin
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Position := Token^.TokenPos;
                  Exit;
                End;
              End;

            // Functions that take no parameters and return a String:

            SP_FN_INKEYS, SP_FN_GETDIR, SP_FN_DIR, SP_FN_ERRORS, SP_FN_STKS, SP_FN_CLIPS:
              Begin
                Inc(StackPtr);
                Stack[StackPtr] := SP_STRING;
              End;

            // Functions that take one numeric parameter and return a String:

            SP_FN_STRS, SP_FN_CHRS, SP_FN_HEXS, SP_FN_BINS, SP_FN_DCHRS, SP_FN_QCHRS, SP_FN_DAYS, SP_FN_MONTHS, SP_FN_GFXS,
            SP_FN_FCHRS, SP_FN_PARAMS:
              Begin
                If (StackPtr < 0) Or (Stack[StackPtr] <> SP_VALUE) Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Position := Token^.TokenPos;
                  Exit;
                End Else
                  Stack[StackPtr] := SP_STRING;
              End;

            // Functions that take two numeric parameters and return a string:

            SP_FN_BASES, SP_FN_SCREENS, SP_FN_MEMRDS:
              Begin
                If StackPtr > 0 Then Begin
                  If Stack[StackPtr] <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else
                      Stack[StackPtr] := SP_STRING;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            // Functions that take one String parameter and return a String:

            SP_FN_VALS, SP_FN_UPS, SP_FN_LOWS, SP_FN_TRIMS, SP_FN_LTRIMS, SP_FN_RTRIMS, SP_FN_TOKENS, SP_FN_GETOPTS, SP_FN_FPATH, SP_FN_TEXTURES,
            SP_FN_FNAME, SP_FN_REVS:
              Begin
                If (StackPtr < 0) Or (Stack[StackPtr] <> SP_STRING) Then Begin
                  Error.Code := SP_ERR_MISSING_STREXPR;
                  Position := Token^.TokenPos;
                  Exit;
                End;
              End;

            // Complex functions:

            SP_FN_KEYS:
              Begin

                // Takes either a single string, or n,n,n...

                Dec(StackPtr);
                If (StackPtr < 0) Or (Not (Stack[StackPtr] in [SP_STRVAR, SP_NUMVAR])) Then Begin
                  Error.Code := SP_ERR_SUBSCRIPT_WRONG;
                  Position := Token^.TokenPos;
                  Exit;
                End Else Begin
                  Dec(StackPtr);
                  If Stack[StackPtr] = SP_VALUE Then Begin
                    While LastValue > 0 Do Begin
                      If Stack[StackPtr] <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_SUBSCRIPT_WRONG;
                        Position := Token^.TokenPos;
                        Exit;
                      End Else Begin
                        LastValue := LastValue -1;
                        Dec(StackPtr);
                      End;
                    End;
                  End Else
                    If Stack[StackPtr] = SP_STRING Then
                      Dec(StackPtr);
                  Inc(StackPtr);
                  Stack[StackPtr] := SP_STRING;
                End;

              End;

            SP_FN_FN, SP_FN_CALL:
              Begin
                // A *nasty* pair of functions to check. First, step back to the value before the FN/CALL token:
                nIdx := Idx - SizeOf(TToken) - SizeOf(aFloat);
                nIdxDbl := gaFloat(@Tokens[nIdx]); // Value in content
                NumParams := Trunc(nIdxDbl);
                // The current stack Item is the parameter count, the one below that is the function type or the PROCID expression
                Dec(StackPtr);
                FnType := Stack[StackPtr];
                If FnType = SP_STRVAR Then FnType := SP_STRING Else If FnType = SP_NUMVAR Then FnType := SP_VALUE;
                Dec(StackPtr);
                // Remove the Parameters from the stack - they don't count here.
                While NumParams > 0 Do Begin
                  Dec(StackPtr);
                  Dec(NumParams);
                End;
                // And add the function type to the stack
                Inc(StackPtr);
                Stack[StackPtr] := FnType;
              End;

            SP_FN_PROCID, SP_FN_PROCIDS:
              Begin
                // Only one parameter - a numeric or string variable, returns a numeric.
                If (StackPtr < 0) Or (Not (Stack[StackPtr] in [SP_NUMVAR, SP_STRVAR])) Then Begin
                  Error.Code := SP_ERR_INVALID_PROCEDURE_NAME;
                  Position := Token^.TokenPos;
                  Exit;
                End Else
                  Stack[StackPtr] := SP_VALUE;
              End;

            SP_FN_INRANGE, SP_FN_CLAMP: // (num,num TO num) = num
              Begin
                If StackPtr > 0 Then Begin
                  If Stack[StackPtr] <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else
                      Dec(StackPtr);
                      If Stack[StackPtr] <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Position := Token^.TokenPos;
                        Exit;
                      End Else
                        Stack[StackPtr] := SP_VALUE;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            SP_FN_POSN: // (str,str,num) = num
              Begin
                If StackPtr > 0 Then Begin
                  If Stack[StackPtr] <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else
                      Dec(StackPtr);
                      If Stack[StackPtr] <> SP_STRING Then Begin
                        Error.Code := SP_ERR_MISSING_STREXPR;
                        Position := Token^.TokenPos;
                        Exit;
                      End Else
                        Stack[StackPtr] := SP_VALUE;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;


            SP_FN_INSERTS, SP_FN_LPADS, SP_FN_RPADS: // (str,str,num) = str
              Begin
                If StackPtr > 0 Then Begin
                  If Stack[StackPtr] <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else
                      Dec(StackPtr);
                      If Stack[StackPtr] <> SP_STRING Then Begin
                        Error.Code := SP_ERR_MISSING_STREXPR;
                        Position := Token^.TokenPos;
                        Exit;
                      End Else
                        Stack[StackPtr] := SP_STRING;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            SP_FN_ITEMS: // (str,num[,str]) = str
              Begin
                If StackPtr > 0 Then Begin
                  If Stack[StackPtr] <> SP_STRING Then Begin
                    Error.Code := SP_ERR_MISSING_STREXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else
                      Dec(StackPtr);
                      If Stack[StackPtr] <> SP_STRING Then Begin
                        Error.Code := SP_ERR_MISSING_STREXPR;
                        Position := Token^.TokenPos;
                        Exit;
                      End Else
                        Stack[StackPtr] := SP_STRING;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            // Functions that take two string parameters and return a numeric

            SP_FN_POS, SP_FN_MATCH, SP_FN_MINS, SP_FN_MAXS:
              Begin
                If StackPtr > 0 Then Begin
                  If Stack[StackPtr] <> SP_STRING Then Begin
                    Error.Code := SP_ERR_MISSING_STREXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else
                      Stack[StackPtr] := SP_VALUE;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            // Functions that take one string, two numerics and return a string.

            SP_FN_MIDS:
              Begin
                If StackPtr > 1 Then Begin
                  If Stack[StackPtr] <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else Begin
                      Dec(StackPtr);
                      If Stack[StackPtr] <> SP_STRING Then Begin
                        Error.Code := SP_ERR_MISSING_STREXPR;
                        Position := Token^.TokenPos;
                        Exit;
                      End;
                    End;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            // Functions that take one numeric, one string and returns a string.
            SP_FN_DATES, SP_FN_TIMES:
              Begin
                If StackPtr > 0 Then Begin
                  If Stack[StackPtr] <> SP_STRING Then Begin
                    Error.Code := SP_ERR_MISSING_STREXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else
                      Stack[StackPtr] := SP_STRING;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            // Functions that take one string, one numeric, and return a string.

            SP_FN_LEFTS, SP_FN_RIGHTS, SP_FN_REPS:
              Begin
                If StackPtr > 0 Then Begin
                  If Stack[StackPtr] <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            // Functions that take one string, one numeric and return a numeric

            SP_FN_DECIMAL:
              Begin
                If StackPtr > 0 Then Begin
                  If Stack[StackPtr] <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else
                      Stack[StackPtr] := SP_VALUE;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            // Functions that take two numeric parameters and return a numeric

            SP_FN_MAX, SP_FN_MIN, SP_FN_POINT, SP_FN_ROUND, SP_FN_PEEK, SP_FN_DPEEK, SP_FN_QPEEK, SP_FN_SPFRADDR,
            SP_FN_SPRITEW, SP_FN_SPRITEH, SP_FN_GRGB, SP_FN_GHSV, SP_FN_FPEEK, SP_FN_POWER, SP_FN_POLAR, SP_FN_BIT,
            SP_FN_POLARDIST, SP_FN_BTSET, SP_FN_BTCLR, SP_FN_PYTH, SP_FN_GCD, SP_FN_LCM, SP_FN_INZONE, SP_FN_MIATTR,
            SP_FN_SPCLX, SP_FN_SPCLY, SP_FN_BINV, SP_FN_BREV:
              Begin
                If StackPtr > 0 Then Begin
                  If Stack[StackPtr] <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            // Functions that take three numeric parameters and return a numeric

            SP_FN_RGBtoINT, SP_FN_HSVtoINT, SP_FN_RGBtoHSV, SP_FN_HSVtoRGB, SP_FN_RGBn, SP_FN_RGBf, SP_FN_GPOINT, SP_FN_GETTILE, SP_FN_MANDEL, SP_FN_INTERP, SP_FN_NOISE,
            SP_FN_MID:
              Begin
                If StackPtr > 1 Then Begin
                  If Stack[StackPtr] <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else Begin
                      Dec(StackPtr);
                      If Stack[StackPtr] <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Position := Token^.TokenPos;
                        Exit;
                      End;
                    End;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            // Functions that take five numeric parameters and return a numeric

            SP_FN_POLYTERM, SP_FN_UNDER, SP_FN_NOISEOCT, SP_FN_MAP:
              Begin
                If StackPtr > 3 Then Begin
                  If Stack[StackPtr] <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else Begin
                      Dec(StackPtr);
                      If Stack[StackPtr] <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Position := Token^.TokenPos;
                        Exit;
                      End Else Begin
                        Dec(StackPtr);
                        If Stack[StackPtr] <> SP_VALUE Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Position := Token^.TokenPos;
                          Exit;
                        End Else Begin
                          Dec(StackPtr);
                          If Stack[StackPtr] <> SP_VALUE Then Begin
                            Error.Code := SP_ERR_MISSING_NUMEXPR;
                            Position := Token^.TokenPos;
                            Exit;
                          End;
                        End;
                      End;
                    End;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            // Functions that take three numeric parameters and return a string

            SP_FN_PEEKS:
              Begin
                If StackPtr > 1 Then Begin
                  If Stack[StackPtr] <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else Begin
                      Dec(StackPtr);
                      If Stack[StackPtr] <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Position := Token^.TokenPos;
                        Exit;
                      End Else
                        Stack[StackPtr] := SP_STRING;
                    End;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            // Takes a numeric FN as first param, followed by three numerics and returns a numeric.

            SP_FN_COMPSIMPSON:
              Begin
                If StackPtr > 2 Then Begin
                  If Stack[StackPtr] <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else Begin
                      Dec(StackPtr);
                      If Stack[StackPtr] <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Position := Token^.TokenPos;
                        Exit;
                      End Else Begin
                        Dec(StackPtr);
                        If Stack[StackPtr] <> SP_NUMVAR Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Position := Token^.TokenPos;
                          Exit;
                        End;
                      End;
                    End;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            // IIF/IIF$ changes execution based on the value on the stack. Two values are present - the condition, and the
            // distance to jump ahead if it's false. We know that the "true" expression is a valid numeric, so automatically
            // jump to the "false" expression and continue checking.

            SP_FN_IIF, SP_FN_IIFS:
              Begin
                If StackPtr >= 0 Then Begin
                  If Stack[StackPtr] <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else Begin
                      Dec(StackPtr);
                      Inc(Idx, Trunc(LastValue));
                    End;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End;

            SP_FN_JOINS:
              Begin

                // Takes an array$ as a parameter, then a string

                If (StackPtr < 1) Or (Stack[StackPtr -1] = SP_STRVAR) Then Begin
                  If Stack[StackPtr] <> SP_STRING Then Begin
                    Error.Code := SP_ERR_MISSING_STREXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else
                    Dec(StackPtr);
                End Else Begin
                  Error.Code := SP_ERR_INVALID_ARRAY_VAR;
                  Position := Token^.TokenPos;
                  Exit;
                End;

                Stack[StackPtr] := SP_STRING;

              End;

            SP_FN_ARSIZE:
              Begin

                // Takes an array as a parameter

                If (StackPtr < 0) Or ((StackPtr > 0) And (Stack[StackPtr -1] in [SP_NUMVAR, SP_STRVAR])) Then Begin
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Position := Token^.TokenPos;
                  Exit;
                End Else
                  Stack[StackPtr] := SP_VALUE;

              End;

            SP_FN_LBOUND, SP_FN_UBOUND:
              Begin

                // Takes an array as a parameter, then one numeric

                If StackPtr >= 1 Then Begin
                  If Stack[StackPtr -1] = SP_NUMVAR Then Begin
                    If Stack[StackPtr] <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else
                      Dec(StackPtr);
                  End Else
                    If Stack[StackPtr -1] = SP_STRVAR Then Begin
                      If Stack[StackPtr] <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Position := Token^.TokenPos;
                        Exit;
                      End Else
                        Dec(StackPtr);
                    End Else Begin
                      Error.Code := SP_ERR_INVALID_ARRAY_VAR;
                      Position := Token^.TokenPos;
                      Exit;
                    End;

                  Stack[StackPtr] := SP_VALUE;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;

              End;

            SP_FN_SEARCH:
              Begin

                // Takes an array as a parameter, then a string or numeric search term

                If StackPtr >= 1 Then Begin
                  If Stack[StackPtr -1] = SP_NUMVAR Then Begin
                    If Stack[StackPtr] <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else
                      Dec(StackPtr);
                  End Else
                    If Stack[StackPtr -1] = SP_STRVAR Then Begin
                      If Stack[StackPtr] <> SP_STRING Then Begin
                        Error.Code := SP_ERR_MISSING_STREXPR;
                        Position := Token^.TokenPos;
                        Exit;
                      End Else
                        Dec(StackPtr);
                    End Else Begin
                      Error.Code := SP_ERR_INVALID_ARRAY_VAR;
                      Position := Token^.TokenPos;
                      Exit;
                    End;

                  Stack[StackPtr] := SP_VALUE;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;

              End;

            SP_FN_SEARCH_NEXT:
              Begin

                // One parameter - the array to search

                If (StackPtr < 0) Or (Not (Stack[StackPtr] in [SP_NUMVAR, SP_STRVAR])) Then Begin
                  Error.Code := SP_ERR_INVALID_ARRAY_VAR;
                  Position := Token^.TokenPos;
                  Exit;
                End Else
                  Stack[StackPtr] := SP_VALUE;

              End;

            SP_FN_DET:
              Begin

                If (StackPtr < 0) Or (Stack[StackPtr] <> SP_NUMVAR) Then Begin
                  Error.Code := SP_ERR_INVALID_ARRAY_VAR;
                  Position := Token^.TokenPos;
                  Exit;
                End Else
                  Stack[StackPtr] := SP_VALUE;

              End;

            // "IN" - an operator that acts like a function.
            // Takes parameters from the stack - number of terms first. A range token counts as a term, so we can calculate stack offset to the
            // value to be checked.

            SP_FN_IN:
              Begin

                // Because the stack only contains types, the value in "LastValue" will be the last value stacked - ie, the number of terms.
                // This includes RANGE stack items, so it's a breeze to subtract that from the current position and get the type of the item we're
                // comparing for IN. Ranges have already been handled, so we're just checking type compatibility here.

                Dec(StackPtr);
                NumTerms := Trunc(LastValue);
                INType := Stack[StackPtr - NumTerms];

                For tIdx := 1 To NumTerms Do Begin
                  Case Stack[StackPtr] of
                    SP_VALUE, SP_NUMVAR:
                      If INType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MIXED_IN_TERMS;
                        Position := Token^.TokenPos;
                        Exit;
                      End Else
                        Dec(StackPtr);
                    SP_STRING, SP_STRVAR:
                      If Not(INType in [SP_STRING, SP_STRVAR]) Then Begin
                        Error.Code := SP_ERR_MIXED_IN_TERMS;
                        Position := Token^.TokenPos;
                        Exit;
                      End Else
                        Dec(StackPtr);
                    SP_RANGE, SP_RANGE_LESS, SP_RANGE_GREATER,
                    SP_RANGE_ARRAYNUM, SP_RANGE_ARRAYSTR:
                      Dec(StackPtr);
                  End;
                End;

                Stack[StackPtr] := SP_VALUE;

              End;

            SP_FN_MENUBOX_EX:
              Begin

                // Accepts one string (the title), followed by an array() which holds the menu items.

                If (StackPtr < 0) Or (Stack[StackPtr] = SP_STRVAR) Then Begin

                  Dec(StackPtr);
                  If Stack[StackPtr] <> SP_STRING Then Begin
                    Error.Code := SP_ERR_MISSING_STREXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End;

                  Stack[StackPtr] := SP_VALUE;

                End Else Begin
                  Error.Code := SP_ERR_INVALID_ARRAY_VAR;
                  Position := Token^.TokenPos;
                  Exit;
                End;

              End;

            SP_FN_MENUBOX:
              Begin

                // Similar to the function above, this one accepts 3 or more parameters in string form, to make a menu.

                If StackPtr > 0 Then Begin

                  Dec(StackPtr);
                  NumTerms := Trunc(LastValue);

                  If NumTerms > 2 Then Begin

                    While NumTerms > 0 Do Begin

                      If Stack[StackPtr] <> SP_STRING Then Begin

                        Error.Code := SP_ERR_MISSING_STREXPR;
                        Position := Token^.TokenPos;
                        Exit;

                      End Else Begin

                        Dec(StackPtr);
                        Dec(NumTerms);

                      End;

                    End;

                    Inc(StackPtr);
                    Stack[StackPtr] := SP_VALUE;

                  End Else Begin

                    Error.Code := SP_ERR_INSUFFICIENT_PARAMETERS;
                    Position := Token^.TokenPos;
                    Exit;

                  End;

                End Else Begin

                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;

                End;

              End;

            SP_FN_REPLACES, SP_FN_REPLACEMATCHS:
              Begin

                // Takes three string parameters, returns a string

                If StackPtr > 1 Then Begin
                  If Stack[StackPtr] <> SP_STRING Then Begin
                    Error.Code := SP_ERR_MISSING_STREXPR;
                    Position := Token^.TokenPos;
                    Exit;
                  End Else Begin
                    Dec(StackPtr);
                    If Stack[StackPtr] <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End Else Begin
                      Dec(StackPtr);
                      If Stack[StackPtr] <> SP_STRING Then Begin
                        Error.Code := SP_ERR_MISSING_STREXPR;
                        Position := Token^.TokenPos;
                        Exit;
                      End Else
                        Stack[StackPtr] := SP_STRING;
                    End;
                  End;
                End Else Begin
                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;

              End;

            SP_FN_CHOOSE:
              Begin

              End;

            SP_FN_CHOOSES:
              Begin

              End;

            SP_FN_USINGS:
              Begin

                // Takes one string, followed by not less than one string or numeric argument.

                If StackPtr > 0 Then Begin

                  Dec(StackPtr);
                  NumTerms := Trunc(LastValue);

                  If (NumTerms > 0) And (StackPtr >= NumTerms) Then Begin

                    Dec(StackPtr, NumTerms);
                    If Stack[StackPtr] <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Position := Token^.TokenPos;
                      Exit;
                    End;

                  End Else Begin

                    Error.Code := SP_ERR_INSUFFICIENT_PARAMETERS;
                    Position := Token^.TokenPos;
                    Exit;

                  End;

                End Else Begin

                  Position := Token^.TokenPos;
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;

                End;

              End;

          End;

        End;

    End;

    Inc(Idx, Token^.TokenLen);

  End;

  If (StackPtr > 0) or (StackPtr < 0) Then
    Error.Code := SP_ERR_SYNTAX_ERROR
  Else
    Result := Stack[StackPtr];


End;

Procedure SP_UnStackOperator; Inline;
Begin

  // Swaps an operator off the operator stack, and onto the operand stack.

  Inc(SP_OperandPtr);
  With SP_OperandStack[SP_OperandPtr] Do Begin
    If SP_OperatorStack[SP_OperatorPtr].Content[1]  = SP_CHAR_NOT Then
      OpType := SP_SPECIAL_SYMBOL;
    If SP_OperatorStack[SP_OperatorPtr].Content[1] in [SP_CHAR_UNARYM, SP_CHAR_UNARYP] Then
      OpType := SP_SPECIAL_SYMBOL
    Else
      OpType := SP_SYMBOL;
    Content := SP_OperatorStack[SP_OperatorPtr].Content;
    StrPos := SP_OperatorStack[SP_OperatorPtr].StrPos;
  End;
  Dec(SP_OperatorPtr);

End;

Procedure SP_StackExpression(Expr: aString); Inline;
Var
  Idx: Integer;
  Token: pToken;
Begin

  // Takes a string containing a processed expression, breaks it up into component tokens
  // and stacks each in turn onto the operand stack.

  Idx := 1;
  While Idx <= Length(Expr) Do Begin
    Inc(SP_OperandPtr);
    With SP_OperandStack[SP_OperandPtr] Do Begin
      Token := @Expr[Idx];
      Inc(Idx, SizeOf(TToken));
      OpType := Token^.Token;
      StrPos := Token^.TokenPos;
      Content := Copy(Expr, Idx, Token^.TokenLen);
      Inc(Idx, Token^.TokenLen);
    End;
  End;

End;

Procedure SP_DeleteStackItem(Index: Integer);
Var
  Idx: Integer;
Begin

  For Idx := Index To SP_OperandPtr -1 Do Begin
    SP_OperandStack[Idx].Content := SP_OperandStack[Idx +1].Content;
    SP_OperandStack[Idx].OpType := SP_OperandStack[Idx +1].OpType;
    SP_OperandStack[Idx].StrPos := SP_OperandStack[Idx +1].StrPos
  End;
  Dec(SP_OperandPtr);

End;

Function  SP_ConcatenateStrings(Var Tokens: aString; Var Position: Integer): aString;
Begin

  // Scans the supplied string of tokens from the position specified, and concatenates
  // string items (string-chars such as #32 as well as literal strings) together to form
  // one string. A small optimisation, but means that the user doesn't need to do it themselves
  // to maintain maximum processing speed.

  // Works on tokenised code, not p-code

  Result := '';

  While True Do Begin

    Case Byte(Tokens[Position]) Of

      SP_STRING:
        Begin
          Inc(Position);
          Result := Result + Copy(Tokens, Position + SizeOf(LongWord), pLongWord(@Tokens[Position])^);
          Inc(Position, SizeOf(LongWord) + pLongWord(@Tokens[Position])^);
        End;

      SP_STRINGCHAR:
        Begin
          Inc(Position);
          Result := Result + aChar(Trunc(gaFloat(@Tokens[Position])) And $FF);
          Inc(Position, SizeOf(aFloat));
          Inc(Position, 1 + SizeOf(LongWord) + pLongWord(@Tokens[Position +1])^);
        End;

    Else
      Exit;
    End;

  End;

End;

Function SP_ExtractArray(Var Tokens: aString; Var Position: Integer; Preserve: Boolean; Var Error: TSP_ErrorCode): aString;
Var
  NumIndices, PosBeforeSlice: Integer;
  SlicerFlags: Byte;
  FnResult: aString;
  FirstRun, IsArray, IsSlicer, FirstParam: Boolean;
Label
  Slicer, Again;
Begin

  // (numexpr[,numexpr|[[,numexpr] TO [numexpr]]])
  // Also, (key$[,[numexpr] TO [numexpr]])

  NumIndices := 0;
  Result := '';
  IsArray := False;
  IsSlicer := False;
  FirstParam := True;
  FirstRun := True;
  SlicerFlags := 0;

  While True Do Begin

    // Gather indices until we encounter a ")" or " TO ". If the former, then
    // this is an array, str or num. If the latter, then this is either a String array
    // (if more than one index) or a slicer (if one or less indices).

    // We allow a string as the first parameter - after that there (optionally) MUST be a ",", then TO or a ")"

    Again:

    FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit;
    If FirstParam And (Error.ReturnType = SP_STRING) Then Begin
      FirstParam := False;

      // Either a comma (only on first run) or a close-brace here. If comma, jump to the slicer processing section.
      // BUT! If another bracket is forth-coming, then there's another index (possibly a single number) for a slice.

      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
        IsArray := True;
        PosBeforeSlice := Length(Result);
        If (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] in [SP_CHAR_INCVAR, SP_CHAR_DECVAR, SP_CHAR_MULVAR, SP_CHAR_DIVVAR, SP_CHAR_POWVAR, SP_CHAR_MODVAR, SP_CHAR_ANDVAR, SP_CHAR_XORVAR, SP_CHAR_ORVAR, SP_CHAR_NOTVAR]) Then
          Result := Result + FnResult + CreateToken(SP_NUM_ARRAY_PTR, Position, SizeOf(LongWord)) + LongWordToString(0)
        Else
          Result := Result + FnResult + CreateToken(SP_ARRAY, Position, SizeOf(LongWord)) + LongWordToString(0);
        Inc(Position, 2);
        Break;
      End Else
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') And FirstRun Then Begin
          Inc(Position, 2);
          Goto Slicer;
        End;

    End Else
      If (FnResult <> '') And (Error.ReturnType <> SP_VALUE) Then Begin
        Error.Code := SP_ERR_INVALID_NUMEXPR;
        Exit;
      End Else
        FirstParam := False;

    // If the next token is not " TO " then this is an array parameter, so add it, otherwise store it for
    // later.

    If FnResult <> '' Then
      If Not((Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO)) Then Begin
        Result := Result + FnResult;
        SlicerFlags := 1;
        Inc(NumIndices);
        FnResult := '';
      End;

    // Now check what's happening next! Close-bracket will set this as a num/str array.

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
      If (Result = '') And (FnResult = '') Then Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End Else Begin
        If (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = '(') Then Begin
          Inc(Position, 4);
        End Else Begin
          IsArray := True;
          PosBeforeSlice := Length(Result);
          If FirstRun Then Begin
            If (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] in [SP_CHAR_INCVAR, SP_CHAR_DECVAR, SP_CHAR_MULVAR, SP_CHAR_DIVVAR, SP_CHAR_POWVAR, SP_CHAR_MODVAR, SP_CHAR_ANDVAR, SP_CHAR_XORVAR, SP_CHAR_ORVAR, SP_CHAR_NOTVAR]) Then
              Result := Result + FnResult + CreateToken(SP_NUM_ARRAY_PTR, Position, SizeOf(LongWord)) + LongWordToString(NumIndices)
            Else
              Result := Result + FnResult + CreateToken(SP_ARRAY, Position, SizeOf(LongWord)) + LongWordToString(NumIndices);
          End Else Begin
            Result := Result + CreateToken(SP_SLICE_ASSIGN, Position, 1 + SizeOf(LongWord)) + aChar(4) + LongWordToString(0);
          End;
          Inc(Position, 2);
          Break;
        End;
      End;
    End Else
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        // A comma separates indices, so skip over and loop.
        Inc(Position, 2);
        IsArray := True;
        SlicerFlags := 0;
      End Else
        Slicer:
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
          // A " TO " keyword indicates we're halfway through a slicer. From here we can either have a numexpr,
          // or a close-bracket. First, we need to stack any array parameters we may have found.
          If NumIndices > 0 Then Begin
            If Not Preserve Then
              If (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] in [SP_CHAR_INCVAR, SP_CHAR_DECVAR, SP_CHAR_MULVAR, SP_CHAR_DIVVAR, SP_CHAR_POWVAR, SP_CHAR_MODVAR, SP_CHAR_ANDVAR, SP_CHAR_XORVAR, SP_CHAR_ORVAR, SP_CHAR_NOTVAR]) Then
                Result := Result + FnResult + CreateToken(SP_NUM_ARRAY_PTR, Position, SizeOf(LongWord)) + LongWordToString(NumIndices)
              Else
                Result := Result + CreateToken(SP_ARRAY, Position, SizeOf(LongWord)) + LongWordToString(NumIndices);
            Error.ReturnType := SP_ARRAY;
          End;{ Else
            If Error.ReturnType <> SP_ARRAY Then
              Error.ReturnType := SP_SLICER;}
          // Back to slicing. The flags will indicate which parameter is specified - initially both.
          If FnResult <> '' Then Begin
            // " TO " with initial slice parameter, so set the flag (2)
            SlicerFlags := SlicerFlags or 2;
            Result := Result + FnResult;
          End;
          // Skip the " TO " token.
          Inc(Position, 1 + SizeOf(LongWord));
          // Now either a numexpr or a close-bracket.
          If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = ')') Then Begin
            // This indicates that there is no second parameter, so set the flags accordingly.
            If SlicerFlags = 0 Then
              SlicerFlags := 8; // Indicate that this is a slice-assign with no indices
            PosBeforeSlice := Length(Result);
            Result := Result + CreateToken(SP_SLICER, Position, SizeOf(LongWord)) + LongWordToString(SlicerFlags);
            IsSlicer := True;
            Inc(Position, 2);
            Break;
          End Else Begin
            FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then Exit;
            If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_INVALID_NUMEXPR;
              Exit;
            End;
            Result := Result + FnResult;
            SlicerFlags := SlicerFlags or 1;
            // Now check for a bracket to close the slicer.
            If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = ')') Then Begin
              // Add a slicer to the result.
              PosBeforeSlice := Length(Result);
              If Not Preserve or (NumIndices = 0) Then
                Result := Result + CreateToken(SP_SLICER, Position, SizeOf(LongWord)) + LongWordToString(SlicerFlags)
              Else
                Result := Result + CreateToken(SP_SLICE_ARRAY, Position, SizeOf(LongWord) * 2) + LongWordToString(SlicerFlags) + LongWordToString(numIndices);
              IsSlicer := True;
              Inc(Position, 2);
              Break;
            End Else
              Begin
                Error.Code := SP_ERR_BAD_SLICER;
                Exit;
              End;
          End;
        End Else Begin
          Error.Code := SP_ERR_SYNTAX_ERROR;
          Exit;
        End;
  End;

  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And IsSlicer Then Begin
    Inc(Position, 2);
    Result := Copy(Result, 1, PosBeforeSlice) + CreateToken(SP_SLICE_ASSIGN, Position, 1 + SizeOf(LongWord)) + aChar(SlicerFlags) + LongWordToString(NumIndices);
    FirstRun := False;
    Goto Again;
  End;

  If IsArray Then
    Error.ReturnType := SP_ARRAY
  Else
    If IsSlicer Then
      Error.ReturnType := SP_SLICE_VAR;

End;

Function SP_Convert_Var_Assign(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarType, SlicerFlags: Byte;
  VarPos, VarIdx, VarSize, Idx, Idx2, NumIndices: Integer;
  VarName, FnResult: aString;
  IsHybridFn: Boolean;
  Token: Byte;
  TokenNameLen: Integer;
  TokenName: aString;
  Tkn: pToken;
Begin

  // Var[(array/slicer)][.member]

  Result := '';
  IsHybridFn := False;
  VarPos := 0;
  VarIdx := 0;

  If Not (Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR]) Then Begin
    If Byte(Tokens[Position]) <> SP_FUNCTION Then Begin
      Error.Code := SP_ERR_MISSING_VARIABLE;
      Exit;
    End;
  End;

  VarType := Byte(Tokens[Position]);
  If VarType in [SP_NUMVAR, SP_STRVAR] Then Begin
    Inc(Position);
    VarPos := Position;
    VarIdx := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
  End Else
    If VarType = SP_FUNCTION Then Begin
      // If we have a function, get its name and convert to a var assign,
      // and flag that we cannot use a slicer/struct/array here.
      Inc(Position);
      Idx := pLongWord(@Tokens[Position])^;
      If SP_IsHybridFn(Idx) Then Begin
        VarName := StripSpaces(Copy(SP_FUNCTIONS_EXTRA[Idx - SP_FUNCTION_BASE], 2));
        Inc(Position, SizeOf(LongWord));
        IsHybridFn := True;
        If Copy(VarName, Length(VarName), 1) = '$' Then
          VarType := SP_STRVAR
        Else
          VarType := SP_NUMVAR;
        VarName := aChar(Ord(VarName[1]) + 128) + Copy(VarName, 2);
      End Else Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End;
    End;

  // Test for an array here.

  NumIndices := 0;
  SlicerFlags := 0;
  If Not IsHybridFn And ((Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(')) Then Begin
    Inc(Position, 2);
    FnResult := SP_ExtractArray(Tokens, Position, True, Error); // Returns p-code! Beware!
    If FnResult = '' Then Error.Code := SP_ERR_MISSING_NUMEXPR;
    If Error.Code <> SP_ERR_OK Then Exit;

    // Remove the last token (should be SP_ARRAY, SP_SLICER or SP_SLICE_ARRAY) from the pre-processed result,
    // but store the info for later.

    Idx := 1;
    Idx2 := 1;
    While Idx <= Length(FnResult) Do Begin
      Tkn := @FnResult[Idx];
      Idx2 := Idx;
      Inc(Idx, SizeOf(TToken) + Tkn^.TokenLen);
    End;

    Idx := Idx2;
    While Idx <= Length(FnResult) Do Begin
      Tkn := @FnResult[Idx];
      If Tkn^.Token in [SP_ARRAY, SP_NUM_ARRAY_PTR] Then Begin
        NumIndices := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
        FnResult := Copy(FnResult, 1, Idx -1) + Copy(FnResult, Idx + SizeOf(LongWord) + SizeOf(TToken), Length(FnResult));
      End Else
        If Tkn^.Token = SP_SLICER Then Begin
          SlicerFlags := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
          FnResult := Copy(FnResult, 1, Idx -1) + Copy(FnResult, Idx + SizeOf(LongWord) + SizeOf(TToken), Length(FnResult));
        End Else
          If Tkn^.Token = SP_SLICE_ARRAY Then Begin
            SlicerFlags := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
            NumIndices := pLongWord(@FnResult[Idx + SizeOf(TToken) + SizeOf(LongWord)])^;
            FnResult := Copy(FnResult, 1, Idx -1);
          End Else
            Inc(Idx, SizeOf(TToken) + Tkn^.TokenLen);
    End;

  End Else
    FnResult := '';

  Case VarType Of

    SP_NUMVAR:
      Begin

        Error.ReturnType := SP_NUMVAR;
        Result := CreateToken(SP_NUMVAR_LET, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName;
        If FnResult <> '' Then
          If SlicerFlags <> 0 Then Begin
            Error.Code := SP_ERR_SUBSCRIPT_WRONG;
            Exit;
          End Else Begin
            Error.ReturnType := SP_ARRAY_ASSIGN;
            Tkn := @Result[1];
            Tkn^.Token := SP_NUMVAR;
            Result := Result + FnResult + CreateToken(SP_ARRAY_ASSIGN, Position, 1 + SizeOf(LongWord)) + aChar(SlicerFlags) + LongWordToString(NumIndices);
          End;
      End;

    SP_STRVAR:
      Begin

        // String vars can have structure elements assigned to them, so test for that and insert the necessary tokens. Change the returntype if necessary
        // to allow commands like WINDOW NEW <var> to work. This is all a bit of a hack, I'm afraid, with duplicated code a couple of times. But what the hell,
        // it works and doesn't need to be fast.

        Token := Byte(Tokens[Position]);
        If Not IsHybridFn And (Token in [SP_STRUCT_MEMBER_N, SP_STRUCT_MEMBER_S]) Then Begin
          Inc(Position);
          TokenNameLen := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
          TokenName := LowerNoSpaces(Copy(Tokens, Position, TokenNameLen));
          Inc(Position, TokenNameLen);
          If Token = SP_STRUCT_MEMBER_N Then
            Error.ReturnType := SP_NUMVAR
          Else
            Error.ReturnType := SP_STRVAR;
          Result := CreateToken(SP_STRVARPTR, Position, SizeOf(longWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName;
          Result := CreateToken(SP_STRUCT_MEMBER_ASS, Position, TokenNameLen) + TokenName + Result;
          If FnResult <> '' Then Begin
            Error.ReturnType := SP_SLICE_ASSIGN;
            Result := CreateToken(SP_STRVAR, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName;
            Result := CreateToken(SP_STRUCT_MEMBER_ASS, Position, TokenNameLen) + TokenName + Result;
            Result := Result + FnResult + CreateToken(SP_SLICE_ASSIGN, Position, 1 + SizeOf(LongWord)) + aChar(SlicerFlags) + LongWordToString(NumIndices);
            // There may be a slicer here - is it?
            FnResult := '';
            If (Error.ReturnType = SP_SLICE_ASSIGN) And (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
              Inc(Position, 2);
              FnResult := SP_ExtractArray(Tokens, Position, True, Error);
              If FnResult = '' Then Error.Code := SP_ERR_MISSING_NUMEXPR;
              If Error.Code <> SP_ERR_OK Then Exit;
              Idx := 1;
              While Idx <= Length(FnResult) Do Begin
                Tkn := @FnResult[Idx];
                If Tkn^.Token in [SP_ARRAY, SP_NUM_ARRAY_PTR] Then Begin
                  NumIndices := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
                  FnResult := Copy(FnResult, 1, Idx -1) + Copy(FnResult, Idx + SizeOf(TToken) + SizeOf(LongWord), Length(FnResult));
                End Else
                  If Byte(FnResult[Idx]) = SP_SLICER Then Begin
                    SlicerFlags := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
                    FnResult := Copy(FnResult, 1, Idx -1) + Copy(FnResult, Idx + SizeOf(TToken) + SizeOf(LongWord), Length(FnResult));
                  End Else
                    If Byte(FnResult[Idx]) = SP_SLICE_ARRAY Then Begin
                      SlicerFlags := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
                      NumIndices := pLongWord(@FnResult[Idx + SizeOf(TToken) + SizeOf(LongWord)])^;
                      FnResult := Copy(FnResult, 1, Idx -1);
                    End Else
                      Inc(Idx, SizeOf(TToken) + Tkn^.TokenLen);
              End;
              If FnResult <> '' Then
                Result := Result + FnResult + CreateToken(SP_SLICE_ASSIGN, Position, 1 + SizeOf(LongWord)) + aChar(SlicerFlags) + LongWordToString(NumIndices);
            End Else
              If Token = SP_STRUCT_MEMBER_N Then
                Error.ReturnType := SP_NUMVAR
              Else
                Error.ReturnType := SP_STRVAR;
          End Else Begin
            // Test for a slicer - it's valid here.
            NumIndices := 0;
            SlicerFlags := 0;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
              Inc(Position, 2);
              FnResult := SP_ExtractArray(Tokens, Position, False, Error);
              If FnResult = '' Then Error.Code := SP_ERR_MISSING_NUMEXPR;
              If Error.Code <> SP_ERR_OK Then Exit;
              Idx := 1;
              While Idx <= Length(FnResult) Do Begin
                Tkn := @FnResult[Idx];
                If Tkn^.Token in [SP_ARRAY, SP_NUM_ARRAY_PTR] Then Begin
                  NumIndices := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
                  FnResult := Copy(FnResult, 1, Idx -1) + Copy(FnResult, Idx + SizeOf(TToken) + SizeOf(LongWord), Length(FnResult));
                  If NumIndices <> 1 Then Begin
                    // Cannot allow an array here
                    Error.Code := SP_ERR_SUBSCRIPT_WRONG;
                    Exit;
                  End;
                End Else
                  If Tkn^.Token = SP_SLICER Then Begin
                    SlicerFlags := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
                    FnResult := Copy(FnResult, 1, Idx -1) + Copy(FnResult, Idx + SizeOf(TToken) + SizeOf(LongWord), Length(FnResult));
                  End Else Begin
                    Inc(Idx, Tkn^.TokenLen + SizeOf(TToken));
                  End;
              End;
            End;
            If FnResult <> '' Then
              Result := Result + FnResult + CreateToken(SP_SLICE_ASSIGN, Position, 1 + SizeOf(LongWord)) + aChar(SlicerFlags) + LongWordToString(NumIndices);
          End;
        End Else Begin
          Error.ReturnType := SP_STRVAR;
          Result := CreateToken(SP_STRVAR_LET, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName;
          If (FnResult <> '') Or (SlicerFlags And 8 = 8) Then Begin
            Error.ReturnType := SP_SLICE_ASSIGN;
            Tkn := @Result[1];
            Tkn^.Token := SP_STRVAR;
            Result := Result + FnResult + CreateToken(SP_SLICE_ASSIGN, Position, 1 + SizeOf(LongWord)) + aChar(SlicerFlags) + LongWordToString(NumIndices);
          End;
        End;
      End;

  End;

End;

Function  SP_Convert_Expr(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode; StartPri: Integer): aString;
Var
  Symbol, FnType: aChar;
  FnResult, Expr, Name, VarList, tExpr, fExpr, VarName: aString;
  Token: Byte;
  ExpectOperand, CanOptimise, Done: Boolean;
  OpPriority, Idx, fType, FunctionId, NumIndices, LabelLen, ParamCount: Integer;
  SP_OperatorMin, SP_OperandMin, NameLen, NamePos, MaxOperand,
  VarType, VarPos, VarSize, VarIdx, l, m: Integer;
  oPosition, numTerms, ReturnType: Integer;
  Tkn: pToken;
Label
  Finish;

  Function SP_CreateFromStack(min, Max: Integer; Var c: Integer): aString;
  var
    i, l: Integer;
    Ptr{$IFDEF FPC}, t{$ENDIF}: pByte;
  begin

    l := 0;
    c := (max - min) + 1;
    for i := min to max do
      l := l + SizeOf(TToken) + Length(SP_OperandStack[i].Content);

    SetLength(Result, l);
    ptr := pByte(pNativeUInt(@Result)^);

    for i := min to max do
      With pToken(ptr)^, SP_OperandStack[i] Do Begin
        Token := OpType;
        Handler := @SP_Interpret_UNHANDLED;
        TokenPos := StrPos;
        TokenLen := Length(Content);
        Cache := 0;
        BPIndex := -1;
        Inc(ptr, SizeOf(TToken));
        {$IFNDEF FPC}
        MoveMemory(ptr, pByte(pNativeUInt(@Content)^), TokenLen);
        {$ELSE}
        t := pByte(pNativeUInt(@Content)^);
        Move(t, ptr, TokenLen);
        {$ENDIF}
        Inc(Ptr, TokenLen);
      End;

  End;

Begin

  // Use the classic infix->postfix conversion - stack values on an operand stack, stack operators on
  // an operator stack. Precedence determines which operators get unstacked first. When unstacking
  // operators, check the top stack items for validity, and if they fail - bail out.

  // Each stack item contains one byte (the OpType) which determines what it holds, and one
  // string item, which contains the information about that item. This information varies from one item to
  // the next, and is used to build the final output string.

  Result := '';
  oPosition := Position;
  ExpectOperand := True;
  SP_OperatorMin := SP_OperatorPtr;
  Sp_OperandMin := SP_OperandPtr;

  While True Do Begin

    Token := Byte(Tokens[Position]);
    Case Token of

      SP_LABEL:
        Begin

          // A Label contains text, and nothing else - so stack it as-is.

          Inc(Position);
          LabelLen := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
          Inc(SP_OperandPtr);
          With SP_OperandStack[SP_OperandPtr] Do Begin
            OpType := SP_LABEL;
            Content := LowerNoSpaces(Copy(Tokens, Position, LabelLen));
          End;
          Inc(Position, LabelLen);
          Error.ReturnType := SP_LABEL;
          Goto Finish;
        End;

      SP_COMMENT:
        Begin

          // A Comment is to be ignored, but is stored with the same structure as a label.

          Inc(Position, 1 + SizeOf(LongWord) + pLongWord(@Tokens[Position +1])^);

        End;

      SP_VALUE:
        Begin

          // With a value, we only need to store its extended form, not the actual
          // text of the value itself.

          Inc(SP_OperandPtr);
          SP_OperandStack[SP_OperandPtr].StrPos := Position;

          Inc(Position);
          With SP_OperandStack[SP_OperandPtr] Do Begin
            OpType := SP_VALUE;
            Content := aFloatToString(gaFloat(@Tokens[Position]));
            Inc(Position, SizeOf(aFloat) +1);
            Inc(Position, SizeOf(LongWord) + pLongWord(@Tokens[Position])^);
          End;
          ExpectOperand := False;
          Error.ReturnType := SP_VALUE;

        End;

      SP_STRING, SP_STRINGCHAR:
        Begin

          // Store the whole aString.
          // The Stringchar is a "#" symbol followed by a number, and represents a single character.

          Inc(SP_OperandPtr);
          SP_OperandStack[SP_OperandPtr].StrPos := Position;

          With SP_OperandStack[SP_OperandPtr] Do Begin
            OpType := SP_STRING;
            Content := SP_ConcatenateStrings(Tokens, Position);
          End;
          ExpectOperand := False;
          Error.ReturnType := SP_STRING;

        End;

      SP_NUMVAR:
        Begin

          // We have to store the whole numvar entry for this, as it has to be evaluated
          // at runtime.

          Inc(SP_OperandPtr);
          SP_OperandStack[SP_OperandPtr].StrPos := Position;

          With SP_OperandStack[SP_OperandPtr] Do Begin
            Inc(Position, 1 + SizeOf(LongWord));
            NameLen := pLongWord(@Tokens[Position])^;
            Inc(Position, SizeOf(LongWord));
            Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
            Content := LongWordToString(Length(Name)) + Name;
            Inc(Position, NameLen);
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] in ['(', SP_CHAR_INCVAR, SP_CHAR_DECVAR, SP_CHAR_MULVAR, SP_CHAR_DIVVAR, SP_CHAR_POWVAR, SP_CHAR_MODVAR, SP_CHAR_ANDVAR, SP_CHAR_XORVAR, SP_CHAR_ORVAR, SP_CHAR_NOTVAR]) Then Begin
              If Tokens[Position +1] = '(' Then
                Content := LongWordToString(0) + Content;
              OpType := SP_NUMVAR
            End Else Begin
              OpType := SP_NUMVAR_EVAL;
              Content := LongWordToString(0) + Content;
            End;
          End;
          ExpectOperand := False;
          Error.ReturnType := SP_VALUE;

        End;

      SP_STRVAR:
        Begin

          // And Ditto for the String variable.

          Inc(SP_OperandPtr);
          SP_OperandStack[SP_OperandPtr].StrPos := Position;

          With SP_OperandStack[SP_OperandPtr] Do Begin
            Inc(Position, 1 + SizeOf(LongWord));
            NameLen := pLongWord(@Tokens[Position])^;
            Inc(Position, SizeOf(LongWord));
            Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
            Content := LongWordToString(0) + LongWordToString(Length(Name)) + Name;
            Inc(Position, NameLen);

            // Having gotten information about the variable, check for either a '(' which denotes an array/slicer
            // or a structure member - which requires us to stack a string var *pointer* instead of the actual var.
            // Bear in mind this isn't the actual pointer (hence the $00000000 value at the start).

            // If it's neither of these types, then stack a type which evaluates a stringvar.

            If ((Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(')) Then
              OpType := SP_STRVAR
            Else
              If Byte(Tokens[Position]) in [SP_STRUCT_MEMBER_N, SP_STRUCT_MEMBER_S] Then Begin
                OpType := SP_STRVARPTR;
                Content := LongWordToString(0) + Name;
              End Else
                OpType := SP_STRVAR_EVAL;
          End;
          ExpectOperand := False;
          Error.ReturnType := SP_STRING;

        End;

      SP_STRUCT_MEMBER_N, SP_STRUCT_MEMBER_S:
        Begin

          // MUST follow a stringvar or string-array.

          If SP_OperandPtr >= 0 Then Begin
            Inc(SP_OperandPtr);
            SP_OperandStack[SP_OperandPtr].StrPos := Position;

            With SP_OperandStack[SP_OperandPtr] Do Begin
              OpType := Byte(Tokens[Position]);
              Inc(Position);
              Content := LowerNoSpaces(Copy(Tokens, Position + SizeOf(LongWord), pLongWord(@Tokens[Position])^));
              Inc(Position, SizeOf(LongWord) + pLongWord(@Tokens[Position])^);
            End;
            ExpectOperand := False;
            If Token = SP_STRUCT_MEMBER_N Then
              Error.ReturnType := SP_VALUE
            Else
              Error.ReturnType := SP_STRING;
          End Else
            Error.Code := SP_ERR_SYNTAX_ERROR;
          If Error.Code <> SP_ERR_OK Then Exit;

        End;

      SP_FUNCTION:
        Begin

          // Function processing. Most functions take at least one parameter, which we call ourselves in this procedure
          // to handle, and stack the result if no errors have occurred. We should be expecting an operand here, unless
          // function is IN.

          // After the parameters have been stacked, we stack the function itself.

          If (pLongWord(@Tokens[Position +1])^ <> SP_FN_IN) And Not ExpectOperand Then Goto Finish;

          Inc(Position);
          FunctionId := pLongWord(@Tokens[Position])^;
          Case FunctionId of

            // Functions that take no parameters

            SP_FN_RND, SP_FN_PI, SP_FN_TAU, SP_FN_INKEYS, SP_FN_SCRW, SP_FN_SCRH, SP_FN_CWIN, SP_FN_MOUSEX, SP_FN_ITEM, SP_FN_DIR,
            SP_FN_MOUSEY, SP_FN_MOUSEBTN, SP_FN_ERROR_NUM, SP_FN_ERROR_LIN, SP_FN_ERROR_STA, SP_FN_FONTBANK, SP_FN_FONTWIDTH,
            SP_FN_FONTHEIGHT, SP_FN_FONTMODE, SP_FN_FONTTRANSPARENT,SP_FN_MOUSEDX, SP_FN_MOUSEDY, SP_FN_HEADING, SP_FN_DRPOSX,
            SP_FN_DRPOSY, SP_FN_LASTK, SP_FN_FRAMES, SP_FN_TIME, SP_FN_MOUSEWHEEL, SP_FN_ERRORS, SP_FN_POPLINE, SP_FN_POPST,
            SP_FN_VOL, SP_FN_LOGW, SP_FN_LOGH, SP_FN_ORGX, SP_FN_ORGY, SP_FN_MSECS, SP_FN_MUSICPOS, SP_FN_MUSICLEN, SP_FN_LASTM,
            SP_FN_LASTMI, SP_FN_TXTW, SP_FN_TXTH, SP_FN_STK, SP_FN_STKS, SP_FN_CLIPS:
              Begin
                Inc(Position, SizeOf(LongWord));
                FnResult := '';
              End;

            // Functions that take one Parameter:

            SP_FN_SIN, SP_FN_COS, SP_FN_TAN, SP_FN_ASN, SP_FN_ACS, SP_FN_ATN, SP_FN_LN, SP_FN_EXP, SP_FN_INT, SP_FN_SQR,
            SP_FN_SGN, SP_FN_ABS, SP_FN_USR, SP_FN_NOT, SP_FN_CODE, SP_FN_VAL, SP_FN_LEN, SP_FN_VALS, SP_FN_WINX, SP_FN_WINY,
            SP_FN_STRS, SP_FN_CHRS, SP_FN_FRAC, SP_FN_CEIL, SP_FN_FLOOR, SP_FN_ODD, SP_FN_EVEN, SP_FN_TRUNC, SP_FN_LOWS,
            SP_FN_UPS, SP_FN_RED, SP_FN_GREEN, SP_FN_BLUE, SP_FN_RGB, SP_FN_HEXS, SP_FN_BINS, SP_FN_KEY, SP_FN_HSV, SP_FN_RGBC,
            SP_FN_HUE, SP_FN_SAT, SP_FN_VALUE, SP_FN_TRIMS, SP_FN_LTRIMS, SP_FN_RTRIMS, SP_FN_UDG, SP_FN_UDGS, SP_FN_DEGTORAD,
            SP_FN_RADTODEG, SP_FN_SLEN, SP_FN_SPOS, SP_FN_BSIZE, SP_FN_GETDIR, SP_FN_DCHRS, SP_FN_QCHRS, SP_FN_DCODE, SP_FN_QCODE,
            SP_FN_TOKENS, SP_FN_CHPOS, SP_FN_WINOFF, SP_FN_SPRITEX, SP_FN_SPRITEY, SP_FN_SPFCOUNT, SP_FN_SPVISIBLE, SP_FN_SPROT,
            SP_FN_SPSCALE, SP_FN_DAYS, SP_FN_MONTHS, SP_FN_YEAR, SP_FN_HOUR, SP_FN_MINUTES, SP_FN_SECONDS, SP_FN_DAY, SP_FN_MONTH,
            SP_FN_GFXS, SP_FN_GFXW, SP_FN_GFXH, SP_FN_GFXT, SP_FN_WINW, SP_FN_WINH, SP_FN_FCODE, SP_FN_FCHRS, SP_FN_POWERTWO,
            SP_FN_LOGTWO, SP_FN_WORDSWAP, SP_FN_BYTESWAP, SP_FN_NYBBLESWAP, SP_FN_HIWORD, SP_FN_LOWORD, SP_FN_HIBYTE, SP_FN_LOBYTE,
            SP_FN_GETOPT, SP_FN_GETOPTS, SP_FN_NUBMODE, SP_FN_NUBX, SP_FN_NUBY, SP_FN_FEXISTS, SP_FN_FPATH, SP_FN_FNAME, SP_FN_LTOPX,
            SP_FN_LTOPY, SP_FN_PTOLX, SP_FN_PTOLY, SP_FN_INV, SP_FN_SPFRAME, SP_FN_SPCOLL, SP_FN_TEXTURES, SP_FN_IVAL, SP_FN_MEMRD,
            SP_FN_DMEMRD, SP_FN_QMEMRD, SP_FN_FMEMRD, SP_FN_DATADDR, SP_FN_WINADDR, SP_FN_MILLISECONDS, SP_FN_PAR, SP_FN_SINH,
            SP_FN_COSH, SP_FN_TANH, SP_FN_ASNH, SP_FN_ACSH, SP_FN_ATNH, SP_FN_PARAMS, SP_FN_REVS:
              Begin
                Inc(Position, SizeOf(LongWord));
                FnResult := SP_Convert_Expr(Tokens, Position, Error, 14);
                If Error.Code <> SP_ERR_OK Then Exit;
              End;

            // These functions require a string variable (NOT a string array var):

            SP_FN_STRADDR:
              Begin
                Inc(Position, SizeOf(LongWord));
                If Byte(Tokens[Position]) <> SP_STRVAR Then Begin
                  Error.Code := SP_ERR_MISSING_VAR;
                  Exit;
                End Else Begin
                  VarType := Byte(Tokens[Position]);
                  Inc(Position);
                  VarPos := Position;
                  VarIdx := pLongWord(@Tokens[Position])^;
                  Inc(Position, SizeOf(LongWord));
                  VarSize := pLongWord(@Tokens[Position])^;
                  Inc(Position, SizeOf(LongWord));
                  VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
                  Inc(Position, VarSize);
                  FnResult := CreateToken(SP_STRVARPTR, Position, SizeOf(longWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName;
                End;
              End;

            // These functions take either one numeric parameter or three.

            SP_FN_RGBtoHSV, SP_FN_HSVtoRGB, SP_FN_RGBf, SP_FN_RGBn:
              Begin
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then Exit;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                    Inc(Position, 2);
                    Case FunctionID of
                      SP_FN_RGBtoHSV:
                        FunctionID := SP_FN_iRGBtoHSV;
                      SP_FN_HSVtoRGB:
                        FunctionID := SP_FN_iHSVtoRGB;
                      SP_FN_RGBf:
                        FunctionID := SP_FN_iRGBf;
                      SP_FN_RGBn:
                        FunctionID := SP_FN_iRGBn;
                    End;
                  End Else
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code <> SP_ERR_OK Then Exit;
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                        Inc(Position, 2);
                        FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                        If Error.Code <> SP_ERR_OK Then Exit;
                        If Not ((Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')')) Then Begin
                          Error.Code := SP_ERR_MISSING_BRACKET;
                          Exit;
                        End Else
                          Inc(Position, 2);
                      End Else Begin
                        Error.Code := SP_ERR_SYNTAX_ERROR;
                        Exit;
                      End;
                    End Else Begin
                      Error.Code := SP_ERR_SYNTAX_ERROR;
                      Exit;
                    End;
                End Else Begin
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then Exit;
                  Case FunctionID of
                    SP_FN_RGBtoHSV:
                      FunctionID := SP_FN_iRGBtoHSV;
                    SP_FN_HSVtoRGB:
                      FunctionID := SP_FN_iHSVtoRGB;
                    SP_FN_RGBf:
                      FunctionID := SP_FN_iRGBf;
                    SP_FN_RGBn:
                      FunctionID := SP_FN_iRGBn;
                  End;
                End;
              End;

            // BIN is a special case - takes 1s and 0s *only*

            SP_FN_BIN:
              Begin

                Inc(Position, SizeOf(LongWord));
                // $1E + 8number + 4length + string
                If Byte(Tokens[Position]) = $1E Then Begin // Number, skip
                  Inc(Position, 1 + SizeOf(aFloat));
                  If Byte(Tokens[Position]) = $5 Then Begin // Textual representation - we want this
                    Inc(Position);
                    NameLen := pLongWord(@Tokens[Position])^;
                    Inc(Position, SizeOf(LongWord));
                    Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
                    Inc(Position, NameLen);
                    fType := 1;
                    NameLen := 0;
                    For Idx := Length(Name) DownTo 1 Do Begin
                      If Name[Idx] = '1' Then
                        Inc(NameLen, fType)
                      Else
                        If Name[Idx] <> '0' Then Begin
                          Error.Code := SP_ERR_SYNTAX_ERROR;
                          Exit;
                        End;
                      Inc(fType, fType);
                    End;
                    FnResult := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(NameLen);
                    SP_StackExpression(FnResult);
                    ExpectOperand := False;
                    FunctionID := 0;
                  End;
                End Else Begin
                  FnResult := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);
                  SP_StackExpression(FnResult);
                  ExpectOperand := False;
                  FunctionID := 0;
                End;

              End;

            SP_FN_HEX:
              Begin

                Inc(Position, SizeOf(LongWord));
                // $03 + Longword + Length + VarName$
                If Byte(Tokens[Position]) = $03 Then Begin // Start variable descriptor
                  Inc(Position, 1 + SizeOf(LongWord));
                  NameLen := pLongWord(@Tokens[Position])^;
                  Inc(Position, SizeOf(LongWord));
                  Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
                  Inc(Position, NameLen);
                  fType := 0;
                  For Idx := 1 To NameLen Do Begin
                    If Name[Idx] in ['0'..'9'] Then
                      fType := (fType Shl 4) + Ord(Name[Idx]) - Ord('0')
                    Else
                      If Name[Idx] in ['a'..'f'] Then
                        fType := (fType Shl 4) + Ord(Name[Idx]) - Ord('a') + 10
                      Else Begin
                        Error.Code := SP_ERR_SYNTAX_ERROR;
                        Exit;
                      End;
                  End;
                  FnResult := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(fType);
                  SP_StackExpression(FnResult);
                  ExpectOperand := False;
                  FunctionID := 0;
                End Else Begin
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;

              End;

            // Complex functions:

            SP_FN_PROCID, SP_FN_PROCIDS:
              Begin
                Inc(Position, SizeOf(LongWord));
                If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
                  FnType := Tokens[Position];
                  Inc(Position, SizeOf(LongWord)+1);
                  NameLen := pLongWord(@Tokens[Position])^;
                  Inc(Position, SizeOf(LongWord));
                  Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
                  Inc(Position, NameLen);
                  FnResult := CreateToken(Ord(FnType), Position, Length(Name) + SizeOf(LongWord)) + LongWordToString(0) + Name;
                End Else Begin
                  Error.Code := SP_ERR_INVALID_FUNCTION_NAME;
                  Exit;
                End;
              End;

            SP_FN_FN:
              Begin
                Inc(Position, SizeOf(LongWord));
                If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin

                  // Pick up the name of the function

                  FnType := Tokens[Position];
                  Inc(Position, SizeOf(LongWord)+1);
                  NameLen := pLongWord(@Tokens[Position])^;
                  Inc(Position, SizeOf(LongWord));
                  Name := Copy(Tokens, Position, NameLen);
                  Inc(Position, NameLen);
                  FnResult := CreateToken(Byte(FnType), Position, NameLen + SizeOf(LongWord)) + LongWordToString(0) + Name;

                  ParamCount := 0;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = '(') Then Begin
                    Inc(Position, 2);
                    if (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = ')') Then
                      Inc(Position, 2)
                    Else
                      While True Do Begin
                          FnResult := SP_Convert_Expr(Tokens, Position, Error, -1) + FnResult;
                          If Error.Code <> SP_ERR_OK Then Exit;
                          If Error.ReturnType = SP_UNKNOWN Then Begin
                            Error.Code := SP_ERR_SYNTAX_ERROR;
                            Exit;
                          End;
                          Inc(ParamCount);
                          If Byte(Tokens[Position]) = SP_SYMBOL Then
                            If Tokens[Position +1] = ')' Then Begin
                              Inc(Position, 2);
                              Break;
                            End Else
                              If Tokens[Position +1] <> ',' Then Begin
                                Error.Code := SP_ERR_MISSING_COMMA;
                                Exit;
                              End Else
                                Inc(Position, 2);
                      End;
                  End;

                  FnResult := FnResult + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(ParamCount);

                End Else Begin
                  Error.Code := SP_ERR_INVALID_FUNCTION_NAME;
                  Exit;
                End;

              End;

            // takes two numerics, TO, then numeric - returns numeric

            SP_FN_INRANGE, SP_FN_CLAMP:
              Begin
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
                      Inc(Position, SizeOf(LongWord) +1);
                      FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code <> SP_ERR_OK Then
                        Exit
                      Else
                        If Error.ReturnType <> SP_VALUE Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Exit;
                        End;
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                        Inc(Position, 2);
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_BRACKET;
                        Exit;
                      End;
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_TO;
                      Exit;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;
                End;
              End;

            SP_FN_CALL:
              Begin

                // This is a *horrible* function to convert to a stack.
                // CALL must be followed either by a string/numvar OR a PROCID/PROCID$ function, then parameters in braces.
                // Parameters

                Inc(Position, SizeOf(LongWord));
                Symbol := #0;
                If (Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR]) or ((Byte(Tokens[Position]) = SP_FUNCTION) And
                   ((pLongWord(@Tokens[Position +1])^ = SP_FN_PROCID) or (pLongWord(@Tokens[Position +1])^ = SP_FN_PROCIDS))) Then Begin
                  If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
                    FnType := Tokens[Position];
                    Inc(Position);
                    NamePos := pLongWord(@Tokens[Position])^;
                    Inc(Position, SizeOf(LongWord));
                    NameLen := pLongWord(@Tokens[Position])^;
                    Inc(Position, SizeOf(LongWord));
                    Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
                    Inc(Position, NameLen);
                    FnResult := CreateToken(Byte(FnType), NamePos, Length(Name) + SizeOf(LongWord)) + LongWordToString(0) + Name;

                    // We set up the next symbol to be looked for as an open-brace, as if this was a CALL PROCID setup then we'd be searching instead
                    // for a ;.

                    Symbol := '(';
                    ParamCount := 0;
                    If Byte(FnType) = SP_STRVAR Then
                      Name := Name + '$';
                    If ProcListAvailable then Begin
                      Idx := 0;
                      While Idx <= SP_ProcsListPtr Do Begin
                        If SP_ProcsList[Idx].Name = Name Then
                          Break
                        Else
                          Inc(Idx);
                      End;
                      If Idx = SP_ProcsListPtr +1 Then
                        ProcListAvailable := False
                      Else
                        VarList := SP_ProcsList[Idx].VarTypes;
                    End;

                  End Else Begin

                    // CALL has been executed with a PROCID/PROCID$ instead of a function name. MUST be followed by open-brace, then
                    // the function index (numeric), then either a semicolon to start the parameter list, or a close-brace for no
                    // parameters.

                    If pLongWord(@Tokens[Position +1])^ = SP_FN_PROCID Then
                      FnResult := CreateToken(SP_NUMVAR, 0, SizeOf(LongWord)) + LongWordToString(0)
                    Else
                      FnResult := CreateToken(SP_STRVAR, 0, SizeOf(LongWord)) + LongWordToString(0);
                    Inc(Position, 1 + SizeOf(LongWord));
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                      Inc(Position, 2);
                      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code <> SP_ERR_OK Then Exit;
                      FnResult := Expr + FnResult;

                      // Set up for a parameter list to be checked next, in case the close-brace test here fails and we move on to accept
                      // parameters.

                      Symbol := ';';
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                        Inc(Position, 2);
                        ParamCount := 1;
                        FnResult := FnResult + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(ParamCount);
                        Break;
                      End;
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_BRACKET;
                      Exit;
                    End;
                    ParamCount := 1;
                  End;

                  // We now insist on the symbol we set up earlier being present if a parameter list is desired. If that symbol
                  // isn't here, we declare the function as having no parameters and exit.

                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = Symbol) Then Begin
                    Inc(Position, 2);
                    if (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = ')') Then Begin
                      FnResult := FnResult + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(ParamCount);
                      Inc(Position, 2)
                    End Else
                      While True Do Begin

                        // No upper limit on the number of parameters, so we loop until we encounter a closing-brace (or end of line, which
                        // would be an error).

                        If Byte(Tokens[Position]) = SP_KEYWORD Then Begin
                          If pLongWord(@Tokens[Position +1])^ = SP_KW_REF Then Begin

                            // We've got a "REF" command here, so a variable or structure member name must follow.
                            // This will pass the variable or structure member as a reference, so it can be altered by
                            // the function or procedure.

                            Inc(Position, 1 + SizeOf(LongWord));
                            If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
                              FnResult := SP_Convert_Var_Assign(Tokens, Position, Error) + FnResult;
                              If Error.Code = SP_ERR_OK Then Begin
                                Tkn := @FnResult[1];
                                If Tkn^.Token in [SP_NUMVAR_LET, SP_STRVAR_LET] Then
                                  Dec(Tkn^.Token, 30)
                                Else
                                  If Tkn^.Token = SP_STRUCT_MEMBER_ASS Then
                                    Error.Code := SP_ERR_STRUCT_NOT_REF;
                                If Error.Code <> SP_ERR_OK Then Exit;
                                Inc(ParamCount);
                                If Byte(Tokens[Position]) = SP_SYMBOL Then Begin
                                  Inc(Position);
                                  If Tokens[Position] = ')' Then Begin
                                    Inc(Position);
                                    FnResult := FnResult + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(ParamCount);
                                    Break;
                                  End Else
                                    If Tokens[Position] <> ',' Then Begin
                                      Error.Code := SP_ERR_SYNTAX_ERROR;
                                      Exit;
                                    End;
                                  Inc(Position);
                                End;
                              End Else
                                Exit;
                            End Else Begin
                              Error.Code := SP_ERR_MISSING_VARIABLE;
                              Exit;
                            End;
                          End Else Begin
                            Error.Code := SP_ERR_SYNTAX_ERROR;
                            Exit;
                          End;
                        End Else Begin

                          // The VarList is set up when the pre-parser is called (in SP_Variables.pas).
                          // It contains a list of parameters which is used to make sure that a parameter that should be
                          // a reference is passed as such.

                          If (VarList <> '') And (VarList[ParamCount +1] = '!') Then Begin
                            If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
                              FnResult := SP_Convert_Var_Assign(Tokens, Position, Error) + FnResult;
                              If Error.Code = SP_ERR_OK Then Begin
                                Tkn := @FnResult[1];
                                If Tkn^.Token in [SP_NUMVAR_LET, SP_STRVAR_LET] Then
                                  Dec(Tkn^.Token, 30)
                                Else
                                  If Tkn^.Token = SP_STRUCT_MEMBER_ASS Then
                                    Error.Code := SP_ERR_STRUCT_NOT_REF;
                                If Error.Code <> SP_ERR_OK Then Exit;
                                Inc(ParamCount);
                                If Byte(Tokens[Position]) = SP_SYMBOL Then Begin
                                  Inc(Position);
                                  If Tokens[Position] = ')' Then Begin
                                    Inc(Position);
                                    FnResult := FnResult + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(ParamCount);
                                    Break;
                                  End Else
                                    If Tokens[Position] <> ',' Then Begin
                                      Error.Code := SP_ERR_SYNTAX_ERROR;
                                      Exit;
                                    End;
                                  Inc(Position);
                                End;
                              End Else
                                Exit;
                            End Else Begin
                              Error.Code := SP_ERR_MISSING_VARIABLE;
                              Exit;
                            End;
                          End Else Begin

                            // The Var list doesn't exist (so it hasn't been pre-parsed yet) - so just process the parameters as normal.

                            Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                            If ((Expr = '') And (Error.ReturnType = SP_UNKNOWN)) or (Error.Code <> SP_ERR_OK) Then Exit;
                            FnResult := Expr + FnResult;
                            Inc(ParamCount);
                            If Byte(Tokens[Position]) = SP_SYMBOL Then Begin
                              Inc(Position);
                              If Tokens[Position] = ')' Then Begin
                                Inc(Position);
                                FnResult := FnResult + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(ParamCount);
                                Break;
                              End Else
                                If Tokens[Position] <> ',' Then Begin
                                  Error.Code := SP_ERR_SYNTAX_ERROR;
                                  Exit;
                                End;
                              Inc(Position);
                            End;
                          End;
                        End;
                      End;
                  End Else
                    FnResult := FnResult + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(ParamCount);
                End Else Begin
                  Error.Code := SP_ERR_INVALID_PROCEDURE_NAME;
                  Exit;
                End;
              End;

            // Two Parameters - one numeric, one string.

            SP_FN_DATES, SP_FN_TIMES:
              Begin
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_STRING Then Begin
                        Error.Code := SP_ERR_MISSING_STREXPR;
                        Exit;
                      End;
                    If Error.Code <> SP_ERR_OK Then Exit;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                      Inc(Position, 2);
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_BRACKET;
                      Exit;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;
                End;
              End;

            // Two Parameters - one string, one numeric.

            SP_FN_LEFTS, SP_FN_RIGHTS, SP_FN_REPS, SP_FN_DECIMAL:
              Begin
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    If Error.Code <> SP_ERR_OK Then Exit;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                      Inc(Position, 2);
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_BRACKET;
                      Exit;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;
                End;
              End;

            // Two strings, with optional third numeric

            SP_FN_POS, SP_FN_INSTR:
              Begin
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_STRING Then Begin
                        Error.Code := SP_ERR_MISSING_STREXPR;
                        Exit;
                      End;
                    If Error.Code <> SP_ERR_OK Then Exit;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                      Inc(Position, 2);
                    End Else Begin
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                        Inc(Position, 2);
                        FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                        If Error.Code <> SP_ERR_OK Then
                          Exit
                        Else
                          If Error.ReturnType <> SP_VALUE Then Begin
                            Error.Code := SP_ERR_MISSING_NUMEXPR;
                            Exit;
                          End;
                        If Error.Code <> SP_ERR_OK Then Exit;
                        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                          Inc(Position, 2);
                          Case FunctionID Of
                            SP_FN_POS: FunctionID := SP_FN_POSN;
                            SP_FN_INSTR: FunctionID := SP_FN_INSTRN;
                          End;
                        End Else Begin
                          Error.Code := SP_ERR_MISSING_BRACKET;
                          Exit;
                        End;
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_BRACKET;
                        Exit;
                      End;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;
                End;
              End;

            // Two parameters - two strings.

            SP_FN_MATCH, SP_FN_MINS, SP_FN_MAXS:
              Begin
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_STRING Then Begin
                        Error.Code := SP_ERR_MISSING_STREXPR;
                        Exit;
                      End;
                    If Error.Code <> SP_ERR_OK Then Exit;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                      Inc(Position, 2);
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_BRACKET;
                      Exit;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;
                End;
              End;

            // Two numeric parameters in brackets.

            SP_FN_POINT, SP_FN_MIN, SP_FN_MAX, SP_FN_ROUND, SP_FN_PEEK, SP_FN_DPEEK, SP_FN_QPEEK, SP_FN_SPFRADDR,
            SP_FN_SPRITEW, SP_FN_SPRITEH, SP_FN_GRGB, SP_FN_GHSV, SP_FN_FPEEK, SP_FN_POWER, SP_FN_POLAR, SP_FN_BIT,
            SP_FN_POLARDIST, SP_FN_BTSET, SP_FN_BTCLR, SP_FN_PYTH, SP_FN_BASES, SP_FN_GCD, SP_FN_LCM, SP_FN_INZONE,
            SP_FN_SCREENS, SP_FN_MIATTR, SP_FN_SPCLX, SP_FN_SPCLY, SP_FN_MEMRDS, SP_FN_BINV, SP_FN_BREV:
              Begin
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                      Inc(Position, 2);
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_BRACKET;
                      Exit;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;
                End;
              End;

            // Two parameters - string, numeric with optional string

            SP_FN_ITEMS:
              Begin
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code <> SP_ERR_OK Then
                        Exit
                      Else
                        If Error.ReturnType <> SP_STRING Then Begin
                          Error.Code := SP_ERR_MISSING_STREXPR;
                          Exit;
                        End;
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                        Inc(Position, 2);
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_BRACKET;
                        Exit;
                      End;
                    End Else Begin
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                        Inc(Position, 2);
                        FnResult := FnResult + CreateToken(SP_STRING, Position, 1) + '|';
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_BRACKET;
                        Exit;
                      End;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;
                End;
              End;

            // Three Parameters - two strings, one numeric

            SP_FN_INSERTS, SP_FN_LPADS, SP_FN_RPADS:
              Begin
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_STRING Then Begin
                        Error.Code := SP_ERR_MISSING_STREXPR;
                        Exit;
                      End;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code <> SP_ERR_OK Then
                        Exit
                      Else
                        If Error.ReturnType <> SP_VALUE Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Exit;
                        End;
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                        Inc(Position, 2);
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_BRACKET;
                        Exit;
                      End;
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_COMMA;
                      Exit;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;
                End;
              End;

            // Three Parameters - one string, two numerics.

            SP_FN_MIDS:
              Begin
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code <> SP_ERR_OK Then
                        Exit
                      Else
                        If Error.ReturnType <> SP_VALUE Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Exit;
                        End;
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                        Inc(Position, 2);
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_BRACKET;
                        Exit;
                      End;
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_COMMA;
                      Exit;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;
                End;
              End;

            // Three Parameters - three numerics.
            // SP_FN_IIF is a special case, despite having the same number of numeric arguments.

            SP_FN_IIF, SP_FN_IIFS:
              Begin
                fType := 0;
                Case FunctionID of
                  SP_FN_IIF:
                    fType := SP_VALUE;
                  SP_FN_IIFS:
                    fType := SP_STRING;
                End;
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  // First, pick up the condition. Nothing special about this one.
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    // Now for the "true" expression.
                    tExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> fType Then Begin
                        If fType = SP_VALUE Then Error.Code := SP_ERR_MISSING_NUMEXPR Else Error.Code := SP_ERR_MISSING_STREXPR;
                        Exit;
                      End;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      // And the "false" expression.
                      fExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code <> SP_ERR_OK Then
                        Exit
                      Else
                        If Error.ReturnType <> fType Then Begin
                          If fType = SP_VALUE Then Error.Code := SP_ERR_MISSING_NUMEXPR Else Error.Code := SP_ERR_MISSING_STREXPR;
                          Exit;
                        End;
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                        Inc(Position, 2);
                        // Now form the interpreter sequence with the true/false expressions stored as strings.
                        l := Length(fExpr);
                        tkn := @fExpr[1];
                        m := NativeUint(tkn) + l;
                        While NativeUint(tkn) < m Do Begin
                          If tkn^.Token = SP_BLOCK_OPT Then
                            Dec(l, SizeOf(TToken));
                          Inc(NativeUInt(tkn), SizeOf(TToken) + Tkn^.TokenLen);
                        End;
                        tExpr := tExpr + CreateToken(SP_JUMP, 0, SizeOf(LongWord)) + LongWordToString(l);
                        l := Length(tExpr);
                        tkn := @tExpr[1];
                        m := NativeUint(tkn) + l;
                        While NativeUint(tkn) < m Do Begin
                          If tkn^.Token = SP_BLOCK_OPT Then
                            Dec(l, SizeOf(TToken));
                          Inc(NativeUInt(tkn), SizeOf(TToken) + Tkn^.TokenLen);
                        End;
                        FnResult := CreateToken(SP_FUNCTION_MARKER, 0, 0) + FnResult + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(l);
                        SP_StackExpression(FnResult);
                        Inc(SP_OperandPtr);
                        With SP_OperandStack[SP_OperandPtr] Do Begin
                          StrPos := Position -1;
                          OpType := SP_FUNCTION;
                          Content := LongWordToString(FunctionID);
                        End;
                        ExpectOperand := False;
                        SP_StackExpression(tExpr);
                        SP_StackExpression(fExpr);
                        // IIF is weird tho. For example, IIF(n>0,1,0)+n will result in the sequence "0 n +" which will be optimised
                        // to a compound op. So place a marker at the end to prevent that.
                        SP_StackExpression(CreateToken(SP_BLOCK_OPT, 0, 0));
                        FunctionID := 0;
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_BRACKET;
                        Exit;
                      End;
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_COMMA;
                      Exit;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;
                End;
              End;

            SP_FN_RGBtoINT, SP_FN_HSVtoINT, SP_FN_PEEKS, SP_FN_GPOINT, SP_FN_GETTILE, SP_FN_MANDEL, SP_FN_INTERP, SP_FN_NOISE, SP_FN_MID:
              Begin
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code <> SP_ERR_OK Then
                        Exit
                      Else
                        If Error.ReturnType <> SP_VALUE Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Exit;
                        End;
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                        Inc(Position, 2);
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_BRACKET;
                        Exit;
                      End;
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_COMMA;
                      Exit;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;
                End;
              End;

            // three string parameters, optional EXP on second parameter

            SP_FN_REPLACES:

              Begin
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_EXP) Then Begin
                      Inc(Position, SizeOf(LongWord) +1);
                      FunctionID := SP_FN_REPLACEMATCHS;
                    End;
                    FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_STRING Then Begin
                        Error.Code := SP_ERR_MISSING_STREXPR;
                        Exit;
                      End;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code <> SP_ERR_OK Then
                        Exit
                      Else
                        If Error.ReturnType <> SP_STRING Then Begin
                          Error.Code := SP_ERR_MISSING_STREXPR;
                          Exit;
                        End;
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                        Inc(Position, 2);
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_BRACKET;
                        Exit;
                      End;
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_COMMA;
                      Exit;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;
                End;

              End;

            // Five Parameters - five numerics.

            SP_FN_POLYTERM, SP_FN_UNDER, SP_FN_NOISEOCT:
              Begin
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1); // param 1
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1); // param 2
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1); // param 3
                      If Error.Code <> SP_ERR_OK Then
                        Exit
                      Else
                        If Error.ReturnType <> SP_VALUE Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Exit;
                        End;
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                        Inc(Position, 2);
                        FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1); // param 4
                        If Error.Code <> SP_ERR_OK Then
                          Exit
                        Else
                          If Error.ReturnType <> SP_VALUE Then Begin
                            Error.Code := SP_ERR_MISSING_NUMEXPR;
                            Exit;
                          End;
                        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                          Inc(Position, 2);
                          FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1); // param 5
                          If Error.Code <> SP_ERR_OK Then
                            Exit
                          Else
                            If Error.ReturnType <> SP_VALUE Then Begin
                              Error.Code := SP_ERR_MISSING_NUMEXPR;
                              Exit;
                            End;
                          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                            Inc(Position, 2);
                          End Else Begin
                            Error.Code := SP_ERR_MISSING_BRACKET;
                            Exit;
                          End;
                        End Else Begin
                          Error.Code := SP_ERR_MISSING_COMMA;
                          Exit;
                        End;
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_COMMA;
                        Exit;
                      End;
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_COMMA;
                      Exit;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;
                End;
              End;

            SP_FN_COMPSIMPSON:
              Begin

                // Takes (FN <numvar>,a,b, n)

                FnResult := '';
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin

                  Inc(Position, 2);
                  If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_FN) Then Begin

                    Inc(Position, SizeOf(LongWord) +1);
                    If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

                      FnType := Tokens[Position];
                      Inc(Position, SizeOf(LongWord)+1);
                      NameLen := pLongWord(@Tokens[Position])^;
                      Inc(Position, SizeOf(LongWord));
                      Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
                      Inc(Position, NameLen);
                      FnResult := CreateToken(Byte(FnType), Position, Length(Name) + SizeOf(LongWord)) + LongWordToString(0) + Name;

                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                        Inc(Position, 2);
                        FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1); // param a
                        If Error.Code <> SP_ERR_OK Then
                          Exit
                        Else
                          If Error.ReturnType <> SP_VALUE Then Begin
                            Error.Code := SP_ERR_MISSING_NUMEXPR;
                            Exit;
                          End;
                        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                          Inc(Position, 2);
                          FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1); // param b
                          If Error.Code <> SP_ERR_OK Then
                            Exit
                          Else
                            If Error.ReturnType <> SP_VALUE Then Begin
                              Error.Code := SP_ERR_MISSING_NUMEXPR;
                              Exit;
                            End;
                          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                            Inc(Position, 2);
                            FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1); // param n
                            If Error.Code <> SP_ERR_OK Then
                              Exit
                            Else
                              If Error.ReturnType <> SP_VALUE Then Begin
                                Error.Code := SP_ERR_MISSING_NUMEXPR;
                                Exit;
                              End;
                            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                              Inc(Position, 2);
                            End Else Begin
                              Error.Code := SP_ERR_MISSING_BRACKET;
                              Exit;
                            End;
                          End Else Begin
                            Error.Code := SP_ERR_MISSING_COMMA;
                            Exit;
                          End;
                        End Else Begin
                          Error.Code := SP_ERR_MISSING_COMMA;
                          Exit;
                        End;
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_COMMA;
                        Exit;
                      End;

                    End Else

                      Error.Code := SP_ERR_SYNTAX_ERROR;

                  End Else

                    Error.Code := SP_ERR_SYNTAX_ERROR;

                End Else

                  Error.Code := SP_ERR_SYNTAX_ERROR;

              End;

            SP_FN_DET:
              Begin

                // Takes an array descriptor

                Inc(Position, SizeOf(LongWord));
                If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
                  FnType := Tokens[Position];
                  Inc(Position, SizeOf(LongWord)+1);
                  NameLen := pLongWord(@Tokens[Position])^;
                  Inc(Position, SizeOf(LongWord));
                  Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
                  Inc(Position, NameLen);
                  FnResult := CreateToken(Byte(FnType), Position, Length(Name) + SizeOf(LongWord)) + LongWordToString(0) + Name;
                  If Copy(Tokens, Position, 4) <> aChar(SP_SYMBOL) + '(' + aChar(SP_SYMBOL) + ')' Then Begin
                    Error.Code := SP_ERR_MISSING_BRACKET;
                    Exit;
                  End Else
                    Inc(Position, 4);
                End;
              End;

            SP_FN_ARSIZE:
              Begin

                // Takes an array descriptor

                Inc(Position, SizeOf(LongWord));
                If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin

                  FnType := Tokens[Position];
                  Inc(Position, SizeOf(LongWord)+1);
                  NameLen := pLongWord(@Tokens[Position])^;
                  Inc(Position, SizeOf(LongWord));
                  Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
                  Inc(Position, NameLen);
                  FnResult := CreateToken(Byte(FnType), Position, Length(Name) + SizeOf(LongWord)) + LongWordToString(0) + Name;

                  If Copy(Tokens, Position, 4) = aChar(SP_SYMBOL) + '(' + aChar(SP_SYMBOL) + ')' Then Begin

                    Inc(Position, 4);

                  End Else Begin

                    Error.Code := SP_ERR_MISSING_BRACKET;
                    Exit;

                  End;

                End Else Begin

                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;

                End;

              End;

            SP_FN_LBOUND, SP_FN_UBOUND:
              Begin

                // Takes an array descriptor followed by an index

                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin

                  Inc(Position, 2);
                  If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin

                    FnType := Tokens[Position];
                    Inc(Position, SizeOf(LongWord)+1);
                    NameLen := pLongWord(@Tokens[Position])^;
                    Inc(Position, SizeOf(LongWord));
                    Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
                    Inc(Position, NameLen);
                    FnResult := CreateToken(Byte(FnType), Position, Length(Name) + SizeOf(LongWord)) + LongWordToString(0) + Name;

                    If Copy(Tokens, Position, 4) = aChar(SP_SYMBOL) + '(' + aChar(SP_SYMBOL) + ')' Then Begin

                      Inc(Position, 4);

                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin

                        Inc(Position, 2);
                        tExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                        If Error.ReturnType <> SP_VALUE Then Begin

                          Error.Code := SP_ERR_SYNTAX_ERROR;
                          Exit;

                        End Else

                          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin

                            Inc(Position, 2);
                            FnResult := FnResult + tExpr;

                          End Else Begin

                            Error.Code := SP_ERR_MISSING_BRACKET;
                            Exit;

                          End;

                      End Else Begin

                        Error.Code := SP_ERR_MISSING_COMMA;
                        Exit;

                      End;

                    End Else Begin

                      Error.Code := SP_ERR_MISSING_BRACKET;
                      Exit;

                    End;

                  End Else Begin

                    Error.Code := SP_ERR_SYNTAX_ERROR;
                    Exit;

                  End;

                End Else Begin

                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;

                End;

              End;

            SP_FN_KEYS:
              Begin

                // Takes an array with opening brace, then either a single string, or a set of indices.

                Inc(Position, SizeOf(LongWord));
                If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin

                  FnType := Tokens[Position];
                  Inc(Position, SizeOf(LongWord)+1);
                  NameLen := pLongWord(@Tokens[Position])^;
                  Inc(Position, SizeOf(LongWord));
                  Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
                  Inc(Position, NameLen);
                  FnResult := CreateToken(Byte(FnType), Position, Length(Name) + SizeOf(LongWord)) + LongWordToString(0) + Name;

                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin

                    Inc(Position, 2);
                    Result := Result + SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType = SP_VALUE Then Begin
                        Done := False;
                        NumIndices := 1;
                        While Not Done Do Begin
                          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                            Inc(Position, 2);
                            Result := Result + SP_Convert_Expr(Tokens, Position, Error, -1);
                            If Error.Code <> SP_ERR_OK Then
                              Exit
                            Else
                              If Error.ReturnType <> SP_VALUE Then Begin
                                Error.Code := SP_ERR_MISSING_NUMEXPR;
                                Exit;
                              End Else
                                Inc(NumIndices);
                          End Else
                            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                              Inc(Position, 2);
                              Done := True;
                            End Else Begin
                              Error.Code := SP_ERR_SYNTAX_ERROR;
                              Exit;
                            End;
                        End;
                        FnResult := FnResult + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(NumIndices);
                      End Else
                        If Error.ReturnType = SP_STRING Then Begin
                          If Not ((Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')')) Then Begin
                            Error.Code := SP_ERR_SYNTAX_ERROR;
                            Exit;
                          End Else Begin
                            FnResult := FnResult + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);
                            Inc(Position, 2);
                          End;
                        End;

                  End Else Begin

                    Error.Code := SP_ERR_MISSING_BRACKET;
                    Exit;

                  End;

                End Else Begin
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;

              End;

            SP_FN_SEARCH:
              Begin

                // Takes a numeric or string array, then either:
                // FOR and a term (num/str based on array type) or NEXT on its own

                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin

                  Inc(Position, 2);
                  If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin

                    FnType := Tokens[Position];
                    Inc(Position, SizeOf(LongWord)+1);
                    NameLen := pLongWord(@Tokens[Position])^;
                    Inc(Position, SizeOf(LongWord));
                    Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
                    Inc(Position, NameLen);
                    FnResult := CreateToken(Byte(FnType), Position, Length(Name) + SizeOf(LongWord)) + LongWordToString(0) + Name;

                    If Copy(Tokens, Position, 4) = aChar(SP_SYMBOL) + '(' + aChar(SP_SYMBOL) + ')' Then Begin

                      Inc(Position, 4);

                      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FOR) Then Begin

                        Inc(Position, 1 + SizeOf(LongWord));

                        tExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                        If Error.Code = SP_ERR_OK Then Begin

                          If ((Error.ReturnType = SP_VALUE) And (Ord(FnType) = SP_STRVAR)) or (( Error.ReturnType = SP_STRING) And (Ord(FnType) = SP_NUMVAR)) Then Begin

                            Error.Code := SP_ERR_INVALID_ARGUMENT;
                            Exit;

                          End Else Begin

                            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                              Inc(Position, 2);
                              FnResult := FnResult + tExpr;
                            End Else Begin
                              Error.Code := SP_ERR_MISSING_BRACKET;
                              Exit;
                            End;

                          End;

                        End Else

                          Exit;

                      End Else

                        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_NEXT) Then Begin

                          Inc(Position, 1 + SizeOf(LongWord));
                          FunctionID := SP_FN_SEARCH_NEXT;
                          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then
                            Inc(Position, 2)
                          Else Begin
                            Error.Code := SP_ERR_MISSING_BRACKET;
                            Exit;
                          End;

                        End Else Begin

                          Error.Code := SP_ERR_SYNTAX_ERROR;
                          Exit;

                        End;

                    End Else Begin

                      Error.Code := SP_ERR_MISSING_BRACKET;
                      Exit;

                    End;

                  End Else Begin

                    Error.Code := SP_ERR_SYNTAX_ERROR;
                    Exit;

                  End;

                End Else Begin

                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;

                End;

              End;

            SP_FN_JOINS:
              Begin

                // Takes a string array, then a separator string

                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin

                  Inc(Position, 2);
                  If Byte(Tokens[Position]) = SP_STRVAR Then Begin

                    FnType := Tokens[Position];
                    Inc(Position, SizeOf(LongWord)+1);
                    NameLen := pLongWord(@Tokens[Position])^;
                    Inc(Position, SizeOf(LongWord));
                    Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
                    Inc(Position, NameLen);
                    FnResult := CreateToken(Byte(FnType), Position, Length(Name) + SizeOf(LongWord)) + LongWordToString(0) + Name;

                    If Copy(Tokens, Position, 4) = aChar(SP_SYMBOL) + '(' + aChar(SP_SYMBOL) + ')' Then Begin

                      Inc(Position, 4);

                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
                        Inc(Position, 2)
                      Else Begin
                        Error.Code := SP_ERR_MISSING_COMMA;
                        Exit;
                      End;

                      tExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code = SP_ERR_OK Then Begin

                        If Error.ReturnType <> SP_STRING Then Begin

                          Error.Code := SP_ERR_MISSING_STREXPR;
                          Exit;

                        End Else Begin

                          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                            Inc(Position, 2);
                            FnResult := FnResult + tExpr;
                          End Else Begin
                            Error.Code := SP_ERR_MISSING_BRACKET;
                            Exit;
                          End;

                        End;

                      End;

                    End Else Begin

                      Error.Code := SP_ERR_MISSING_BRACKET;
                      Exit;

                    End;

                  End Else Begin

                    Error.Code := SP_ERR_SYNTAX_ERROR;
                    Exit;

                  End;

                End Else Begin

                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;

                End;

              End;

            SP_FN_MENUBOX:
              Begin

                // Takes 3 or more parameters in string form.

                NumTerms := 0;
                FnResult := '';

                Inc(Position, SizeOf(LongWord));

                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin

                  Inc(Position, 2);
                  Done := False;

                  Repeat

                    If (Byte(Tokens[Position]) = SP_STRVAR) And (NumTerms = 1) Then Begin

                      FnType := Tokens[Position];
                      Inc(Position, SizeOf(LongWord)+1);
                      NameLen := pLongWord(@Tokens[Position])^;
                      Inc(Position, SizeOf(LongWord));
                      Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
                      Inc(Position, NameLen);
                      FnResult := FnResult + CreateToken(Byte(FnType), Position, Length(Name) + SizeOf(LongWord)) + LongWordToString(0) + Name;
                      If Copy(Tokens, Position, 6) = aChar(SP_SYMBOL) + '(' + aChar(SP_SYMBOL) + ')' + aChar(SP_SYMBOL) + ')' Then Begin
                        Inc(Position, 6);
                        Done := True;
                        FunctionID := SP_FN_MENUBOX_EX;
                      End Else Begin
                        Error.Code := SP_ERR_SYNTAX_ERROR;
                        Exit;
                      End;

                    End Else Begin

                      FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code <> SP_ERR_OK Then
                        Exit
                      Else
                        If Error.ReturnType <> SP_STRING Then Begin
                          Error.Code := SP_ERR_MISSING_STREXPR;
                          Exit;
                        End Else Begin
                          Inc(NumTerms);
                          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                            Inc(Position, 2);
                            If NumTerms < 3 Then Begin
                              Error.Code := SP_ERR_INSUFFICIENT_PARAMETERS;
                              Exit;
                            End;
                            Done := True;
                          End Else
                            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
                              Inc(Position, 2)
                            Else Begin
                              Error.Code := SP_ERR_MISSING_COMMA;
                              Exit;
                            End;
                        End;

                    End;

                  Until Done;

                  If FunctionID <> SP_FN_MENUBOX_EX Then
                    FnResult := FnResult + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(NumTerms);

                End Else

                  Error.Code := SP_ERR_SYNTAX_ERROR;

              End;

            SP_FN_USINGS:
              Begin

                // Accepts a format string, then any number (not less than one) of expressions.

                NumTerms := 0;
                FnResult := '';
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_STRING Then Begin
                      Error.Code := SP_ERR_MISSING_STREXPR;
                      Exit;
                    End Else Begin
                      Done := False;
                      Repeat
                        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                          Inc(Position, 2);
                          Done := True;
                          If NumTerms = 0 Then Begin
                            Error.Code := SP_ERR_INSUFFICIENT_PARAMETERS;
                            Exit;
                          End;
                        End Else Begin
                          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
                            Inc(Position, 2)
                          Else Begin
                            Error.Code := SP_ERR_MISSING_COMMA;
                            Exit;
                          End;
                          FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1);
                          If Error.Code <> SP_ERR_OK Then Exit;
                          Inc(NumTerms);
                        End;
                      Until Done;
                      FnResult := FnResult + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(NumTerms);
                    End;
                End Else
                  Error.Code := SP_ERR_SYNTAX_ERROR;

              End;

            SP_FN_CHOOSE:
              Begin

              End;

            SP_FN_CHOOSES:
              Begin

              End;

            SP_FN_MAP:
              Begin
                // Value, rMin TO rMax, mMin TO mMax
                Inc(Position, SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1); // Value
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1); // rMin
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
                      Inc(Position, SizeOf(LongWord) +1);
                      FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1); // rMax
                      If Error.Code <> SP_ERR_OK Then
                        Exit
                      Else
                        If Error.ReturnType <> SP_VALUE Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Exit;
                        End;
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                        Inc(Position, 2);
                        FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1); // mMin
                        If Error.Code <> SP_ERR_OK Then
                          Exit
                        Else
                          If Error.ReturnType <> SP_VALUE Then Begin
                            Error.Code := SP_ERR_MISSING_NUMEXPR;
                            Exit;
                          End;
                        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
                          Inc(Position, SizeOf(LongWord) +1);
                          FnResult := FnResult + SP_Convert_Expr(Tokens, Position, Error, -1); // mMax
                          If Error.Code <> SP_ERR_OK Then
                            Exit
                          Else
                            If Error.ReturnType <> SP_VALUE Then Begin
                              Error.Code := SP_ERR_MISSING_NUMEXPR;
                              Exit;
                            End;
                          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                            Inc(Position, 2);
                          End Else Begin
                            Error.Code := SP_ERR_MISSING_BRACKET;
                            Exit;
                          End;
                        End Else Begin
                          Error.Code := SP_ERR_MISSING_COMMA;
                          Exit;
                        End;
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_COMMA;
                        Exit;
                      End;
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_COMMA;
                      Exit;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_BRACKET;
                  Exit;
                End;
              End;

            SP_FN_IN:
              Begin

                // A special function, because it's actually an operator, so test that we want an operator now.

                If Not ExpectOperand Then Begin

                  If -1 < StartPri Then Begin
                    Dec(Position);
                    Goto Finish;
                  End;

                  Inc(Position, SizeOf(LongWord));

                  // Because this is an operator, it has to unstack any waiting operators. It has lower priority than
                  // anything, because you obviously want to do 2+1 IN [0 TO 5] by evaluating the 2+1 first. You can change this
                  // with brackets such as 2+(1 IN [0 TO 5]) if desired, as that is more readable.

                  While (SP_OperatorPtr > SP_OperatorMin) And (3 <= SP_OperatorStack[SP_OperatorPtr].Priority) Do
                    SP_UnstackOperator;

                  // Now process the actual IN function.

                  FnResult := SP_Process_IN(Tokens, Position, Error);
                  If Error.Code <> SP_ERR_OK Then Exit;

                End Else
                  Goto Finish;

              End;

          End;

          // Take the resulting stack from the function parameters, and "decode" them
          // onto our results stack. Insert a "Function parameter marker" for later use - will be removed before runtime.

          If FunctionID <> 0 Then Begin
            FnResult := CreateToken(SP_FUNCTION_MARKER, 0, 0) + FnResult;
            SP_StackExpression(FnResult);

            // And finally add the Function itself.

            Inc(SP_OperandPtr);
            With SP_OperandStack[SP_OperandPtr] Do Begin
              StrPos := Position -1;
              OpType := SP_FUNCTION;
              Content := LongWordToString(FunctionID);
            End;
            ExpectOperand := False;
          End;

        End;

      SP_SYMBOL:
        Begin

          Symbol := Tokens[Position +1];
          Case Symbol of

            '(':
              Begin

                // An opening brace is either a slicer or a maths operator.
                // As a maths operator, we recurse and ask ourselves for the contents of the brackets.

                If ExpectOperand Then Begin

                  // Math op

                  Inc(Position, 2);
                  tExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If (Error.Code = SP_ERR_OK) and (Copy(Tokens, Position +1, 1) = ')') Then Begin
                    ExpectOperand := False;
                    SP_StackExpression(tExpr);
                  End Else Begin
                    If Error.Code = SP_ERR_OK Then
                      Error.Code := SP_ERR_SYNTAX_ERROR;
                    Exit;
                  End;

                End Else Begin

                  // Array/Slicer descriptor - lower priority than a function and its arguments!
                  // Hence LET a$=STR$ a(2 TO) is invalid, STR$(a)(2 TO) is also invalid.
                  // LET a$=(STR$ a)(2 TO ) is valid.

                  Inc(Position, 2);
                  FnResult := SP_ExtractArray(Tokens, Position, False, Error);
                  If Error.Code <> SP_ERR_OK Then Exit;
                  If Error.ReturnType = SP_SLICE_VAR Then
                    If SP_OperandStack[SP_OperandPtr].OpType = SP_STRVAR Then
                      SP_OperandStack[SP_OperandPtr].OpType := SP_STRVAR_EVAL;
                  SP_StackExpression(FnResult);
                  Dec(Position, 2);

                End;

              End;

            ')':
              Begin

                // On a closing bracket, just bounce out and let the calling proc handle
                // the rest.

                Goto Finish;

              End;

            '!', '+', '-', '/', '*', '^', '<', '>', '=', SP_CHAR_SHL, SP_CHAR_ADD, SP_CHAR_SUB,
            SP_CHAR_GTE, SP_CHAR_LTE, SP_CHAR_DNE, '&', '|', SP_CHAR_SHR, SP_CHAR_STR_PLUS,
            SP_CHAR_AND, SP_CHAR_OR, SP_CHAR_MOD, SP_CHAR_XOR, SP_CHAR_NUM_PLUS, SP_CHAR_NUM_EQU,
            SP_CHAR_STR_EQU, SP_CHAR_NUM_LES, SP_CHAR_STR_LES, SP_CHAR_NUM_LTE, SP_CHAR_STR_LTE,
            SP_CHAR_NUM_DNE, SP_CHAR_STR_DNE, SP_CHAR_NUM_GTE, SP_CHAR_STR_GTE, SP_CHAR_NUM_GTR,
            SP_CHAR_STR_GTR, SP_CHAR_NUM_AND, SP_CHAR_STR_AND, SP_CHAR_MUL, SP_CHAR_DIV, SP_CHAR_INCVAR,
            SP_CHAR_DECVAR, SP_CHAR_MULVAR, SP_CHAR_DIVVAR, SP_CHAR_POWVAR, SP_CHAR_MODVAR, SP_CHAR_ANDVAR,
            SP_CHAR_XORVAR, SP_CHAR_ORVAR, SP_CHAR_NOT, SP_CHAR_NOTVAR, SP_CHAR_EQV, SP_CHAR_IMP:
              Begin

                // Operators - basically, pop old operators off the stack until the priority of the current
                // operator is higher than the one at the top of the stack. This is subtly different for
                // left-associative and right-associative operators.

                If ExpectOperand And (Symbol in [SP_CHAR_NOT, '-', '+']) Then Begin

                  // Convert to unary plus/minus

                  If Symbol = '-' Then
                    Symbol := SP_CHAR_UNARYM
                  Else
                    If Symbol = '+' Then
                      Symbol := SP_CHAR_UNARYP;

                  OpPriority := SP_GetPriority(Symbol);

                End Else Begin

                  If ExpectOperand And Not (Symbol in ['!']) Then Goto Finish;

                  // Check - if the start priority is higher, then bail out to the calling proc. This is for
                  // function evaluation.

                  OpPriority := SP_GetPriority(Symbol);
                  If OpPriority < StartPri Then
                    Goto Finish;

                  If ((Not ExpectOperand) And (Symbol = '!')) or (Symbol in ['+', '-', '/', '*', '^', SP_CHAR_NUM_PLUS, SP_CHAR_STR_PLUS, SP_CHAR_MUL, SP_CHAR_DIV, SP_CHAR_ADD, SP_CHAR_SUB]) Then Begin

                    // Left-associativity

                    While (SP_OperatorPtr > SP_OperatorMin) And (OpPriority <= SP_OperatorStack[SP_OperatorPtr].Priority) Do
                      SP_UnstackOperator;

                  End Else Begin

                    // Right-associativity
                    // If this is AND or OR then insert the relevant JUMP opcode onto the operand stack

                    While (SP_OperatorPtr > SP_OperatorMin) And (OpPriority < SP_OperatorStack[SP_OperatorPtr].Priority) Do
                      SP_UnstackOperator;

                    If Symbol = SP_CHAR_AND Then Begin
                      {Inc(SP_OperandPtr);
                      With SP_OperandStack[SP_OperandPtr] Do Begin
                        OpType := SP_JZ; // If the preceding expression is false (0) then jump past the next expression
                        Content := LongWordToString(0);
                      End;}
                    End Else
                      If Symbol = SP_CHAR_OR Then Begin
                        Inc(SP_OperandPtr);
                        With SP_OperandStack[SP_OperandPtr] Do Begin
                          OpType := SP_JNZ; // If the preceding expression is TRUE (!0) then jump past the next expression
                          Content := LongWordToString(0);
                        End;
                      End Else
                        If ExpectOperand And (Symbol = '!') Then
                          Symbol := SP_CHAR_BITWISE_NOT;

                  End;

                End;

                // Now just stack the current operator.

                Inc(SP_OperatorPtr);
                With SP_OperatorStack[SP_OperatorPtr] Do Begin
                  Content := Symbol;
                  StrPos := Position;
                  Priority := OpPriority;
                End;
                ExpectOperand := Symbol <> '!';

              End;

          Else

            // An unknown symbol - let the calling procedure handle it, as it could be
            // a function separator, a print separator or whatever, and not necessarily an
            // error.

            Goto Finish;

          End;

          Inc(Position, 2);

        End;

    Else

      // We've come up against a type we can't handle - exit now.

      Goto Finish;

    End;

  End;

Finish:

  // We've finished. Unstack any operators that are left, and we have our expression in RPN form.

  MaxOperand := SP_OperandPtr;
  While SP_OperatorPtr > SP_OperatorMin Do
    SP_UnstackOperator;

  // Run through and convert any orphaned SP_STRINGCHARs to strings

  For Idx := SP_OperandMin +1 To MaxOperand Do
    If SP_OperandStack[Idx].OpType = SP_STRINGCHAR Then Begin
      SP_OperandStack[Idx].OpType := SP_STRING;
      SP_OperandStack[Idx].Content := aChar(Trunc(gaFloat(@SP_OperandStack[Idx].Content[1])) And $FF);
    End;

  // End of post-processing. Unstack any operands left over. Unlikely, but there are a couple of cases
  // where this could happen.

  Result := SP_CreateFromStack(SP_OperandMin +1, SP_OperandPtr, numTerms);

  // Now, if there are no errors, test the expression string by feeding it to a stripped-down interpreter.
  // This will tell us what the expression evaluates to. Once that is done with no errors, we can call
  // the optimiser.

  If Error.Code = SP_ERR_OK Then
    If Result <> '' Then Begin
      CanOptimise := True;
      ReturnType := SP_Test_Expr(Result, Position, Error, CanOptimise);
      If Error.Code = SP_ERR_OK Then Begin
        If CanOptimise And (numTerms > 1) Then Begin
          m := Position; // Position may be corrupted here, thanks Delphi.
          SP_OptimiseStack(Result, oPosition, Error);
          Position := m;
        End;
        If Error.Code = SP_ERR_OK Then
          SP_PeepholeOptimiser(Result, oPosition, Error)
        Else
          Error.Code := SP_ERR_OK;
        Error.ReturnType := ReturnType;
      End;
    End Else
      Error.ReturnType := SP_UNKNOWN;

  // Finally restore our stacks to how they were before we entered. Remember that this procedure can be called
  // recursively.

  SP_OperandPtr := SP_OperandMin;
  SP_OperatorPtr := SP_OperatorMin;

  // Now add handlers to the finished code

  SP_AddHandlers(Result);

End;

Function SP_Process_IN(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  NumTerms, TermPos, VarType, NameLen: Integer;
  Name, Expr: aString;
  Done: Boolean;
Label
  NotArray;
Begin

  // Can take many parameters. More than one will require brackets around the list. The list is
  // converted to either types or ranges. Types can be numeric or strings (checked for compatibility later),
  // Ranges must be numeric values min TO max, or characters such as "0" TO "9", "a" TO "z", minimum to maximum
  // as for numerics. Values and Ranges will be in reverse order on the stack. Note - Min TO Max is not enforced,
  // and will be untangled at runtime.

  NumTerms := 0;
  Result := '';
  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '[') Then Begin
    // More than one value/range expected.
    Inc(Position, 2);
    Done := False;
    Repeat
      TermPos := Position;
      // First test for an array - it can be a range all by itself.
      If (Byte(Tokens[Position]) in [SP_STRVAR, SP_NUMVAR]) Then Begin
        VarType := Ord(Tokens[Position]);
        Inc(Position, SizeOf(LongWord)+1);
        NameLen := pLongWord(@Tokens[Position])^;
        Inc(Position, SizeOf(LongWord));
        Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
        Inc(Position, NameLen);
        If Copy(Tokens, Position, 4) = aChar(SP_SYMBOL) + '(' + aChar(SP_SYMBOL) + ')' Then Begin
          Result := Result + CreateToken(Byte(VarType), Position, Length(Name) + SizeOf(LongWord)) + LongWordToString(0) + Name;
          Inc(Position, 4);
          If VarType = SP_STRVAR Then
            Result := Result + CreateToken(SP_RANGE_ARRAYSTR, TermPos, 0)
          Else
            Result := Result + CreateToken(SP_RANGE_ARRAYNUM, TermPos, 0);
          Inc(NumTerms, 2);
        End Else Begin
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
            Position := TermPos;
            Goto NotArray;
          End Else Begin
            Position := TermPos;
            Goto NotArray;
          End;
        End;
      End Else Begin
        NotArray:
        // Check for TO - you can actually use " TO 240" as a range, and the value will be tested for lesser.
        // Conversely you can specify "100 TO " to test for greater.
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
          // Range, test for lesser when interpreted
          Inc(Position, SizeOf(LongWord) +1);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Expr = '' Then
            Error.Code := SP_ERR_SYNTAX_ERROR
          Else
            Result := Result + Expr;
          If Error.Code <> SP_ERR_OK Then Exit;
          If Error.ReturnType = SP_UNKNOWN Then Begin
            Error.Code := SP_ERR_SYNTAX_ERROR;
            Exit;
          End;
          Result := Result + CreateToken(SP_RANGE_LESS, TermPos, 0);
          Inc(NumTerms, 2);
        End Else Begin
          // Require a term here.
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Expr = '' Then
            Error.Code := SP_ERR_SYNTAX_ERROR
          Else
            Result := Result + Expr;
          If Error.Code <> SP_ERR_OK Then Exit;
          Inc(NumTerms);
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
            Inc(Position, SizeOf(LongWord) +1);
            // Got a TO, so this is either a range, or a greater-than-range.
            If Not((Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] in [',', ']'])) Then Begin
              // Need a value here.
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
              If Expr = '' Then
                Error.Code := SP_ERR_SYNTAX_ERROR
              Else
                Result := Result + Expr;
              If Error.Code <> SP_ERR_OK Then Exit;
              Result := Result + CreateToken(SP_RANGE, TermPos, 0);
              Inc(NumTerms, 2);
            End Else Begin
              Result := Result + CreateToken(SP_RANGE_GREATER, TermPos, 0);
              Inc(NumTerms);
            End;
          End;
        End;
      End;
      // Now test for comma or close-brace "]"
      If Byte(Tokens[Position]) = SP_SYMBOL Then Begin
        If Tokens[Position +1] = ']' Then Begin
          Done := True;
          Inc(Position, 2);
        End Else
          If Tokens[Position +1] = ',' Then
            Inc(Position, 2)
          Else Begin
            Error.Code := SP_ERR_SYNTAX_ERROR;
            Exit;
          End;
      End;
    Until Done;
  End Else Begin
    // No []s indicates that we're testing to see if the value is inside an array or a string.
    // Any array will do.
    If (Byte(Tokens[Position]) in [SP_STRVAR, SP_NUMVAR]) Then Begin
      TermPos := Position;
      VarType := Ord(Tokens[Position]);
      Inc(Position, SizeOf(LongWord)+1);
      NameLen := pLongWord(@Tokens[Position])^;
      Inc(Position, SizeOf(LongWord));
      Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
      Inc(Position, NameLen);
      If Copy(Tokens, Position, 4) = aChar(SP_SYMBOL) + '(' + aChar(SP_SYMBOL) + ')' Then Begin
        Result := Result + CreateToken(Byte(VarType), Position, Length(Name) + SizeOf(LongWord)) + LongWordToString(0) + Name;
        Inc(Position, 4);
        If VarType = SP_STRVAR Then
          Result := Result + CreateToken(SP_RANGE_ARRAYSTR, TermPos, 0)
        Else
          Result := Result + CreateToken(SP_RANGE_ARRAYNUM, TermPos, 0);
        Inc(NumTerms, 2);
      End Else Begin
        // Stringvar
        If VarType = SP_STRVAR Then Begin
          Result := Result + SP_Convert_Expr(Tokens, TermPos, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit;
          Inc(NumTerms);
        End Else Begin
          Error.Code := SP_ERR_SYNTAX_ERROR;
          Exit;
        End;
      End;
    End Else Begin
      // Literal string?
      Result := Result + SP_Convert_Expr(Tokens, Position, Error, -1);
      If (Error.Code <> SP_ERR_OK) or (Error.ReturnType <> SP_STRING) Then Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End;
      Inc(NumTerms);
    End;
  End;
  If NumTerms = 0 Then Begin
    Error.Code := SP_ERR_SYNTAX_ERROR;
    Exit;
  End Else
    Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(NumTerms);

End;

Procedure SP_OptimiseStack(Var Tokens: aString; Var tPos: Integer; Var Error: TSP_ErrorCode);
Var
  Position, oPosition: Integer;
  TokensPtr: paString;
  newTokens: aString;
  SaveStack: pSP_StackItem;
Begin

  // If we end up here, it's because the string passed (a stack) can be evaluated down to just one value or string.
  // So evaluate it and then condense into just one token!

  Position := 1;
  newTokens := Tokens;
  SP_RemoveFunctionMarkers(newTokens);
  newTokens := newTokens + #255#255#255#255;
  TokensPtr := @newTokens;
  SaveStack := SP_StackPtr;

  SP_AddHandlers(NewTokens);

  // Use the current stack - should condense down to just one token, which when pulled off will leave the stack in
  // the state it was in when we entered. If there's an error, then just restore the stack pointer.

  BREAKSIGNAL := False;
  oPosition := Error.Position;
  SP_InterpretCONTSafe(TokensPtr, Position, Error);
  Error.Position := oPosition;

  If Error.Code = SP_ERR_OK Then Begin
    Case SP_StackPtr^.OpType of
      SP_VALUE:
        Tokens := CreateToken(SP_VALUE, tPos, SizeOf(aFloat)) + aFloatToString(SP_StackPtr^.Val);
      SP_STRING:
        Tokens := CreateToken(SP_STRING, tPos, Length(SP_StackPtr^.Str)) + SP_StackPtr^.Str;
    Else
      Error.Code := SP_ERR_SYNTAX_ERROR;
    End;
    Dec(SP_StackPtr);
  End;

  SP_StackPtr := saveStack;

End;

Procedure SP_PeepholeOptimiser(Var Tokens: aString; Var tPos: Integer; Var Error: TSP_ErrorCode);
Var
  TypeString, SearchString, TestTokens, VarTokens, NumTokens, Var1, Var2: aString;
  Idx, Idx2, Idx3, tStart, tLen, tIdx, szValueToken, szSymbolToken, Count, i, j, FnID: Integer;
  Done, CanOptimise, Replaced: Boolean;
  StrPtr, StrStart, StrEnd: pByte;
  s: LongWord;
  Token: pToken;
  Val: aFloat;
  Searches, TypePositions: Array of aString;
Label
  Cont1, Cont2, Cont3, Cont4, Start;
Begin

  // A simple peephole optimiser. Look for common patterns of tokens that can be condensed in a similar manner to
  // that above. This is more aggressive (and more complex) than the previous procedure. Create string out of the
  // tokens passed - N for number, S for string, ? for symbol etc. Then match patterns of strings - NN? would
  // be a candidate for condensing, for example.

  // Optimisations are:

  // NV,N,O = convert to NNO operation
  // SV,S,O = convert to SSO operation
  // N,-/+ = unary minus/plus convert to literal number
  // Convert divides to multiplies by 1/value
  // Condense runs of multiplies to one multiplication
  // Condense runs of +,- to one addition
  // Re-order expressions to maximise runs of multiplies and additions/subtractions
  // Condense number,number,operator sequences to one value
  // Convert functions that don't rely on state information (such as variables etc) into their results
  // Convert absolute jumps (GOTO n, GOSUB n) to cached versions

  // It all adds up, I suppose.

  szValueToken := SizeOf(TToken) + SizeOf(aFloat);
  szSymbolToken := SizeOf(TToken) + 1;

  Repeat

    Start:

    Replaced := False;
    TypeString := '';
    SetLength(TypePositions, 0);

    // Create a "map" of tokens and their positions in the string.
    Done := False;
    StrStart := @Tokens[1];
    StrPtr := StrStart;
    StrEnd := StrStart + Length(Tokens);

    While Not Done Do Begin

      If StrPtr >= StrEnd Then
        Done := True
      Else Begin
        Token := pToken(StrPtr);
        SetLength(TypePositions, Length(TypePositions) +1);
        TypePositions[Length(TypePositions) -1] := LongWordToString((StrPtr - StrStart) +1)+LongWordToString(SizeOf(TToken) + Token^.TokenLen);
        Inc(StrPtr, SizeOf(TToken) + Token^.TokenLen);
        TypeString := TypeString + aChar(Token^.Token);
      End;

    End;

    // Now look for strings of bytes which represent common operations.
    // The first two are simple constant substitutions. Later we'll mess with more complex types.

    SearchString := aChar(SP_VALUE) + aChar(SP_SYMBOL);
    Idx := 1;
    While Idx < Length(TypeString) Do Begin

      If Copy(TypeString, Idx, Length(SearchString)) = SearchString Then Begin

        // Looking for any literal divides here - replace with a multiply of 1/value instead.

        tStart := Idx -1;
        tLen := pLongWord(@TypePositions[tStart][5])^ + pLongWord(@TypePositions[tStart +1][5])^;
        tStart := pLongWord(@TypePositions[tStart][1])^;
        TestTokens := Copy(Tokens, tStart, tLen);

        If TestTokens[szValueToken + szSymbolToken] = '/' Then Begin

          Val := gaFloat(@TestTokens[SizeOf(TToken)+1]);
          if val <> 0 then Begin
            val := 1/val;
            WriteaFloat(@TestTokens[SizeOf(TToken)+1], Val);
            TestTokens[szValueToken + szSymbolToken] := '*';
            Tokens := Copy(Tokens, 1, tStart -1) + TestTokens + Copy(Tokens, tStart + tLen, Length(Tokens));
            Goto Start;
          end;

        End;

        Inc(Idx, Length(SearchString));

      End Else
        Inc(Idx);

    End;

    // Look and see if we get values followed by jumps, and replace them with cached versions

    SearchString := aChar(SP_VALUE) + aChar(SP_KEYWORD);
    Idx := 1;

    While Idx < Length(TypeString) Do Begin

      If Copy(TypeString, Idx, Length(SearchString)) = SearchString Then Begin

        // Looking for Value, GOTO or Value, GOSUB - if found, grab the value and replace the whole thing
        // with the special cached GOTO (GOTOC, GOSUBC)

        tStart := Idx -1;
        tLen := pLongWord(@TypePositions[tStart][5])^ + pLongWord(@TypePositions[tStart +1][5])^;
        tStart := pLongWord(@TypePositions[tStart][1])^;
        TestTokens := Copy(Tokens, tStart, tLen);

        Idx2 := pLongWord(@TestTokens[szValueToken + SizeOf(TToken) +1])^;
        If  (Idx2 = SP_KW_GOTO) or (Idx2 = SP_KW_GOSUB) Then Begin
          Idx3 := Round(gaFloat(@TestTokens[SizeOf(TToken)+1]));
          Case Idx2 of
            SP_KW_GOTO:
              Idx2 := SP_KW_GOTOC;
            SP_KW_GOSUB:
              Idx2 := SP_KW_GOSUBC;
          End;
          TestTokens := Copy(TestTokens, szValueToken +1, SizeOf(TToken)) + LongWordToString(Idx2) + LongWordToString($80808080) + LongWordToString(Idx3);
          pToken(@TestTokens[1])^.TokenLen := (SizeOf(LongWord) * 3);
          Tokens := Copy(Tokens, 1, tStart -1) + TestTokens + Copy(Tokens, tStart + tLen, Length(Tokens));
          Goto Start;
        End;

        Inc(Idx, Length(SearchString));

      End Else
        Inc(Idx);

    End;

    // Now search for repeated strings of multiplications or adds/subtracts and work out what they actually come to.
    // There will be no constant-divides now, just multiplications which can be merged. Adds and subtracts can be
    // merged due to their nature.

    Idx := 1;
    While Idx < Length(TypeString) -1 Do Begin

      If (Ord(TypeString[Idx]) in [SP_VALUE, SP_NUMVAR_EVAL]) And (TypeString[Idx +1] = aChar(SP_SYMBOL)) Then Begin

        tStart := Idx -1;
        tLen := pLongWord(@TypePositions[tStart][5])^ + pLongWord(@TypePositions[tStart +1][5])^;
        tStart := pLongWord(@TypePositions[tStart][1])^;
        TestTokens := Copy(Tokens, tStart, tLen);
        NumTokens := '';
        VarTokens := '';

        If TestTokens[Length(TestTokens)] = '*' Then Begin

          // Found an occurrence of a multiply. This will be the first, and we must now look for others.
          // If it's just one, then move on. Otherwise gather up all the subsequent concatenated multiplies and interpret them.
          // They can be either values or numeric variables - gather them all up and separate them into two strings of tokens.

          Done := False;
          Inc(Idx, 2);
          If Idx <= Length(TypeString) -1 Then Begin

            While (Idx < Length(TypeString) -1) And (TypeString[Idx] in [aChar(SP_VALUE), aChar(SP_NUMVAR_EVAL)]) And (TypeString[Idx +1] = aChar(SP_SYMBOL)) And (Tokens[pLongWord(@TypePositions[Idx][1])^ + SizeOf(TToken)] = '*') Do Begin

              Done := True;
              Inc(tLen, pLongWord(@TypePositions[Idx -1][5])^ + pLongWord(@TypePositions[Idx][5])^);
              Inc(Idx, 2);

            End;

            If Done Then Begin

              TestTokens := Copy(Tokens, tStart, tLen);

              // Now look for (and extract) numeric variables into their own string, and remove them from TestTokens.

              Idx3 := 1;
              Count := 0;

              While Idx3 <= Length(TestTokens) Do Begin

                Token := @TestTokens[Idx3];
                Case Token^.Token of

                  SP_VALUE:
                    Begin
                      NumTokens := NumTokens + Copy(TestTokens, Idx3, SizeOf(TToken) + Token^.TokenLen) + CreateToken(SP_SYMBOL, 0, 1) + '*';
                      Inc(Count);
                    End;

                  SP_NUMVAR_EVAL:
                    Begin
                      VarTokens := VarTokens + Copy(TestTokens, Idx3, SizeOf(TToken) + Token^.TokenLen) + CreateToken(SP_SYMBOL, 0, 1) + '*';
                    End;

                End;

                Inc(Idx3, SizeOf(TToken) + Token^.TokenLen);

              End;

              // If we found a list of values to be operated on, process them - only if we have enough to make a difference though.

              If (NumTokens <> '') And (Count > 1) Then Begin

                NumTokens := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1) + NumTokens;
                SP_OptimiseStack(NumTokens, tStart, Error);

                // And now insert them back into the token stream, along with the variables we gathered earlier.

                Tokens := Copy(Tokens, 1, tStart -1) + VarTokens + NumTokens + CreateToken(SP_SYMBOL, 0, 1) + '*' + Copy(Tokens, tStart + tLen, Length(Tokens));
                Replaced := Error.Code = SP_ERR_OK;
                Error.Code := SP_ERR_OK;
                If Replaced Then Goto Start;

                // And now it's all done. There *is* a leftover num,num,multiply sequence, but later optimisations will catch that.

              End;

            End;

          End;

        End Else

          If TestTokens[Length(TestTokens)] in [SP_CHAR_NUM_PLUS, '-'] Then Begin

            // Found a + or -
            // Unlike multiplies and divides, these can be combined into one calculation. Won't work on strings though.
            Done := False;
            Inc(Idx, 2);
            If Idx <= Length(TypeString) -1 Then Begin

              While (Idx <= Length(TypeString) -1) And
                    (TypeString[Idx] in [aChar(SP_VALUE), aChar(SP_NUMVAR_EVAL)]) And
                    (TypeString[Idx +1] = aChar(SP_SYMBOL)) And
                    (Tokens[pLongWord(@TypePositions[Idx][1])^ + SizeOf(TToken)] in [SP_CHAR_NUM_PLUS, '-']) Do Begin

                Done := True;
                Inc(tLen, pLongWord(@TypePositions[Idx -1][5])^ + pLongWord(@TypePositions[Idx][5])^);
                Inc(Idx, 2);

              End;

              If Done Then Begin

                TestTokens := Copy(Tokens, tStart, tLen);

                // Now look for (and extract) numeric variables into their own string, and remove them from TestTokens.
                // Because the operator is important (+ or -) we also preserve those.

                Idx3 := 1;
                Count := 0;

                While Idx3 <= Length(TestTokens) Do Begin

                  Token := @TestTokens[Idx3];
                  Case Token^.Token of

                    SP_VALUE:
                      Begin
                        NumTokens := NumTokens + Copy(TestTokens, Idx3, SizeOf(TToken) + Token^.TokenLen);
                        Inc(Count);
                        Done := True;
                      End;

                    SP_NUMVAR_EVAL:
                      Begin
                        VarTokens := VarTokens + Copy(TestTokens, Idx3, SizeOf(TToken) + Token^.TokenLen);
                        Done := False;
                      End;

                    SP_SYMBOL:
                      Begin
                        Case Done Of
                          True:
                            NumTokens := NumTokens + Copy(TestTokens, Idx3, SizeOf(TToken) + Token^.TokenLen);
                          False:
                            VarTokens := VarTokens + Copy(TestTokens, Idx3, SizeOf(TToken) + Token^.TokenLen);
                        End;
                      End;

                  End;

                  Inc(Idx3, SizeOf(TToken) + Token^.TokenLen);

                End;

                // If we found a list of values to be operated on, process them

                If (NumTokens <> '') And (Count > 1) Then Begin

                  NumTokens := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0) + NumTokens;
                  SP_OptimiseStack(NumTokens, tStart, Error);

                  // And now insert them back into the token stream, along with the variables we gathered earlier.

                  Tokens := Copy(Tokens, 1, tStart -1) + VarTokens + NumTokens + CreateToken(SP_SYMBOL, 0, 1) + '+' + Copy(Tokens, tStart + tLen, Length(Tokens));
                  Replaced := Error.Code = SP_ERR_OK;
                  Error.Code := SP_ERR_OK;
                  If Replaced Then Goto Start;

                End;

              End;

            End;
          End Else
            Inc(Idx);

      End Else
        Inc(Idx);

    End;

    If Replaced Then Goto Start;

    // The following two classes optimise simple cases of what should be constants - 1+1, 2/4 etc.

    SearchString := aChar(SP_VALUE) + aChar(SP_VALUE) + aChar(SP_SYMBOL);
    Idx := Pos(SearchString, TypeString);
    If Idx <> 0 Then Begin

      // Number, Number, Operator - can be optimised!
      tStart := Idx -1;
      tLen := pLongWord(@TypePositions[tStart][5])^ + pLongWord(@TypePositions[tStart +1][5])^ + pLongWord(@TypePositions[tStart +2][5])^;
      tStart := pLongWord(@TypePositions[tStart][1])^;
      TestTokens := Copy(Tokens, tStart, tLen);

      SP_OptimiseStack(TestTokens, tStart, Error);

      Tokens := Copy(Tokens, 1, tStart -1) + TestTokens + Copy(Tokens, tStart + tLen, Length(Tokens));
      Replaced := Error.Code = SP_ERR_OK;
      Error.Code := SP_ERR_OK;

    End Else Begin

      SearchString := aChar(SP_NUMVAR_EVAL) + aChar(SP_NUMVAR_EVAL) + aChar(SP_SYMBOL);
      Idx := Pos(SearchString, TypeString);
      If Idx <> 0 Then Begin

        // Numvar, same numvar, Operation -
        // If multiply, A square operation. Popular in fractals, so let's optimise it to one operation.
        // If divide, it's 1.

        tStart := Idx -1;
        tLen := pLongWord(@TypePositions[tStart][5])^ + pLongWord(@TypePositions[tStart +1][5])^ + pLongWord(@TypePositions[tStart +2][5])^;
        tStart := pLongWord(@TypePositions[tStart][1])^;
        TestTokens := Copy(Tokens, tStart, tLen);

        i := SizeOf(TToken) + (SizeOf(LongWord) * 2) +1;
        s := pToken(@TestTokens[1])^.TokenLen - (SizeOf(LongWord)*2);
        Var1 := Copy(TestTokens, i, s);
        Inc(i, s); j := i;
        s := pToken(@TestTokens[i])^.TokenLen - (SizeOf(LongWord) *2);
        Inc(i, SizeOf(TToken) + SizeOf(LongWord) * 2);
        Var2 := Copy(TestTokens, i, s);
        Inc(i, s + SizeOf(TToken));
        If Lower(Var1) = Lower(Var2) Then
          If TestTokens[i] = '*' Then Begin
            pToken(@TestTokens[1])^.Token := SP_NUMVARSQ;
            TestTokens := Copy(TestTokens, 1, j-1);
            Replaced := True;
          End Else
            If TestTokens[i] = '/' Then Begin
              TestTokens := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1);
              Replaced := True;
            End Else
              If TestTokens[i] = '-' Then Begin
                TestTokens := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);
                Replaced := True;
              End;

        Tokens := Copy(Tokens, 1, tStart -1) + TestTokens + Copy(Tokens, tStart + tLen, Length(Tokens));
        Error.Code := SP_ERR_OK;
        If Replaced Then Goto Start Else Goto Cont1;

      End Else Begin

        Cont1:

        // Let's also look and see if we have a variable raised by power 2. If so,
        // optimise out as a square.

        SearchString := aChar(SP_NUMVAR_EVAL) + aChar(SP_VALUE) + aChar(SP_SYMBOL);
        Idx := Pos(SearchString, TypeString);
        If Idx <> 0 Then Begin

          tStart := Idx -1;
          tLen := pLongWord(@TypePositions[tStart][5])^ + pLongWord(@TypePositions[tStart +1][5])^ + pLongWord(@TypePositions[tStart +2][5])^;
          tStart := pLongWord(@TypePositions[tStart][1])^;
          TestTokens := Copy(Tokens, tStart, tLen);

          i := SizeOf(TToken) + (SizeOf(LongWord) * 2) +1;
          s := pToken(@TestTokens[1])^.TokenLen - (SizeOf(LongWord)*2);
          Var1 := Copy(TestTokens, i, s);
          Inc(i, s); j := i;
          Inc(i, SizeOf(TToken));
          Val := gaFloat(@TestTokens[i]);
          Inc(i, SizeOf(TToken) + SizeOf(aFloat));
          If Val = 2 Then
            If TestTokens[i] = '^' Then Begin
              pToken(@TestTokens[1])^.Token := SP_NUMVARSQ;
              TestTokens := Copy(TestTokens, 1, j-1);
              Replaced := True;
            End;

          Tokens := Copy(Tokens, 1, tStart -1) + TestTokens + Copy(Tokens, tStart + tLen, Length(Tokens));
          Error.Code := SP_ERR_OK;
          If Replaced Then Goto Start Else Goto Cont2;

        End Else Begin

          Cont2:

          SearchString := aChar(SP_STRING) + aChar(SP_STRING) + aChar(SP_SYMBOL);
          Idx := Pos(SearchString, TypeString);
          If Idx <> 0 Then Begin

            // String, String, Operator - again, can be optimised!

            tStart := Idx -1;
            tLen := pLongWord(@TypePositions[tStart][5])^ + pLongWord(@TypePositions[tStart +1][5])^ + pLongWord(@TypePositions[tStart +2][5])^;
            tStart := pLongWord(@TypePositions[tStart][1])^;
            TestTokens := Copy(Tokens, tStart, tLen);

            SP_OptimiseStack(TestTokens, tStart, Error);

            Tokens := Copy(Tokens, 1, tStart -1) + TestTokens + Copy(Tokens, tStart + tLen, Length(Tokens));
            Replaced := Error.Code = SP_ERR_OK;
            Error.Code := SP_ERR_OK;
            If Replaced Then Goto Start Else Goto Cont3;

          End Else Begin

            Cont3:

            SearchString := aChar(SP_VALUE) + aChar(SP_SPECIAL_SYMBOL);
            Idx := Pos(SearchString, TypeString);
            If Idx <> 0 Then Begin

              // Number, NOT or Unary Minus/Plus. Converts down to a number.

              tStart := Idx -1;
              tLen := pLongWord(@TypePositions[tStart][5])^ + pLongWord(@TypePositions[tStart +1][5])^;
              tStart := pLongWord(@TypePositions[tStart][1])^;
              TestTokens := Copy(Tokens, tStart, tLen);

              SP_OptimiseStack(TestTokens, tStart, Error);

              Tokens := Copy(Tokens, 1, tStart -1) + TestTokens + Copy(Tokens, tStart + tLen, Length(Tokens));
              Replaced := Error.Code = SP_ERR_OK;
              Error.Code := SP_ERR_OK;
              If Replaced Then Goto Start Else Goto Cont4;

            End Else Begin

              Cont4:

              // Now for more complex types, as promised.

              // These look for VAR OP VAR or VAR OP VAL types - and there's a LOT of them, one for each var type
              // and each operator that can be applied. Insert the relevant SP_COMPOUND_* type before it in the stream,
              // and when the interpreter picks this up it will perform the op on the info in the input stream rather than
              // stacking operands and then performing the op.

              SetLength(Searches, 3);
              Searches[0] := aChar(SP_COMPOUND_NNO) + aChar(SP_NUMVAR_EVAL) + aChar(SP_NUMVAR_EVAL) + aChar(SP_SYMBOL);
              Searches[1] := aChar(SP_COMPOUND_NVO) + aChar(SP_NUMVAR_EVAL) + aChar(SP_VALUE) + aChar(SP_SYMBOL);
              Searches[2] := aChar(SP_COMPOUND_VNO) + aChar(SP_VALUE) + aChar(SP_NUMVAR_EVAL) + aChar(SP_SYMBOL);

              Idx2 := -1;
              For tIdx := 0 To Length(Searches) -1 Do Begin
                Idx := 1;
                SearchString := Copy(Searches[tIdx], 2, 3);
                While Idx <= Length(TypeString) Do Begin
                  If Byte(TypeString[Idx]) in [SP_COMPOUND_NNO..SP_COMPOUND_VNO] Then
                    Inc(Idx, 4)
                  Else
                    If Copy(TypeString, Idx, 3) = SearchString Then Begin
                      If Tokens[pLongWord(@TypePositions[Idx +1][1])^ + SizeOf(TToken)] in [aChar(SP_CHAR_UNARYM), aChar(SP_CHAR_UNARYP), ':', aChar(SP_CHAR_NOT)] Then
                        Inc(Idx)
                      Else
                        If Idx > 1 Then Begin
                          If Byte(TypeString[Idx -1]) in [SP_COMPOUND_NNO..SP_COMPOUND_VNO] Then
                            Inc(Idx)
                          Else
                            Break;
                        End Else
                          Break;
                    End Else
                      Inc(Idx);
                End;
                If Idx < Length(TypeString) Then Begin
                  Idx2 := Byte(Searches[tIdx][1]);
                  Break;
                End;
              End;

              // Idx2 holds the ID char of the operation detected, idx (if non-zero) holds the position in the stream of the first operand.
              // Insert the appropriate compound operation marker. Note that this does not remove or condense any tokens, but should produce
              // a noticeable speed boost.

              If Idx < Length(TypeString) Then Begin
                tStart := pLongWord(@TypePositions[Idx -1][1])^;
                Tokens := Copy(Tokens, 1, tStart -1) + CreateToken(Idx2, tStart + SizeOf(TToken), 0) + Copy(Tokens, tStart, Length(Tokens));
                Replaced := True;
              End Else Begin

                // Second, look for Functions - if these are all numbers or strings then the function (if it doesn't rely on
                // state information, such as RND or INKEY$) can be Optimised. We know if it can be optimised, from the
                // Flags array we built earlier.

                Idx := 1;
                While Not Replaced And (Idx <= Length(TypeString)) Do Begin
                  If TypeString[Idx] = aChar(SP_FUNCTION) Then Begin
                    // Found a function, so get the position of the ID longword in the token stream.
                    tStart := pLongWord(@TypePositions[Idx -1][1])^ + SizeOf(TToken);
                    FnID := pLongWord(@Tokens[tStart])^;
                    If ((FnID < SP_META_BASE) And SP_OPTIMISE_FLAGS[FnID - SP_FUNCTION_BASE]) Or ((FnID >= SP_META_BASE) And SP_OPTIMISE_META_FLAGS[FnID - SP_META_BASE]) Then Begin
                      Idx2 := Idx -1;
                      CanOptimise := True;
                      // Work backwards from here. If we find only optimisable types right up to the function marker,
                      // then we're good to go. If we find a function, then it's a previous attempt that couldn't be done, so bail and
                      // look for the next one.
                      While (Idx2 > 0) And (TypeString[Idx2] <> aChar(SP_FUNCTION_MARKER)) Do Begin
                        If Byte(TypeString[Idx2]) in [SP_FUNCTION, SP_LABEL, SP_COMMENT, SP_STRUCT_MEMBER_N, SP_STRUCT_MEMBER_S, SP_ARRAY, SP_NUMVAR, SP_STRVAR, SP_STRVARPTR, SP_NUMVAR_EVAL, SP_NUMVARSQ, SP_DISPLACEMENT, SP_STRVAR_EVAL] Then Begin
                          CanOptimise := False;
                          Break;
                        End;
                        Dec(Idx2);
                      End;
                      If CanOptimise and (Idx2 > 0) Then Begin
                        // By all accounts, this function does not rely on state information, and contains no parameters that cannot be optimised...
                        // So let's see if we can optimise it!
                        tStart := Idx2;
                        tLen := 0;
                        For Idx3 := Idx2 To Idx Do
                          tLen := tLen + integer(pLongWord(@TypePositions[Idx3 -1][5])^);
                        tStart := pLongWord(@TypePositions[Idx2 -1][1])^;
                        TestTokens := Copy(Tokens, tStart + SizeOf(TToken), tLen - SizeOf(TToken));
                        SP_OptimiseStack(TestTokens, tStart, Error);
                        If Error.Code = SP_ERR_OK Then Begin
                          Tokens := Copy(Tokens, 1, tStart -1) + TestTokens + Copy(Tokens, tStart + tLen, Length(Tokens));
                          Replaced := True;
                        End;
                        Error.Code := SP_ERR_OK;
                      End;
                    End;
                  End;

                  Inc(Idx);

                End;

              End;

            End;

          End;

        End;

      End;

    End;

  Until Not Replaced;

  // Finally, clean up any left-over function markers

  SP_RemoveFunctionMarkers(Tokens);
  SetLength(TypePositions, 0);

End;

Procedure SP_RemoveFunctionMarkers(Var Tokens: aString);
Var
  Idx: Integer;
  Token: pToken;
Begin

  Idx := 1;
  While Idx <= Length(Tokens) Do Begin
    Token := pToken(@Tokens[Idx]);
    If Token^.Token = SP_FUNCTION_MARKER Then
      Tokens := Copy(Tokens, 1, Idx -1) + Copy(Tokens, Idx + SizeOf(TToken), Length(Tokens))
    Else
      Inc(Idx, Token^.TokenLen + SizeOf(TToken));
  End;

End;

// ***********************************
// * Start of the keyword processing *
// ***********************************

Function  SP_Convert_PRINT(Var inKeyword: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode; Var KID: LongWord): aString;
Var
  KeywordID, InitialKID, Psn: LongWord;
  KeyWordPos: LongWord;
  Expr, VarExpr, nExpr: aString;
  TransFlag, CentreFlag: Boolean;
Label
  Expression, Finalise;
Begin

  // PRINT [ALPHA] [print-item|print-sep]...
  // print-item = INK numexpr ; PAPER numexpr ; INVERSE numexpr ; TRANSPARENT numexpr ; SCALE sx,sy ;
  //              AT numexpr,numexpr ; MOVE numexpr,numexpr ; TAB numexpr ; CLIP [x1,y1 TO x2,y2|OFF] ;
  //              USING strexpr ; numexpr ; strexpr ;
  // print-sep = ;',

  InitialKID := InKeyWord;
  TransFlag := False;
  CentreFlag := False;
  Result := CreateToken(SP_RESTORECOLOURS, 0, 0);
  Expr := '';

  SP_AlphaCheck(inKeyWord, Tokens, Position);

  While True Do Begin

    Case Ord(Tokens[Position]) of

      SP_TERMINAL:
        Goto Finalise;

      SP_KEYWORD:
        Begin

          KeyWordID := pLongWord(@Tokens[Position +1])^;
          KeyWordPos := Position;

          // Flush the current list of items

          If Expr <> '' Then Begin
            If KeyWordID = SP_KW_OUT Then Begin
                If Expr[Length(Expr)] <> ';' Then
                  Expr := CreateToken(SP_SYMBOL, 0, 1) + ';' + Expr;
            End;
            if KeyWordID = SP_KW_ELSE Then
              Goto Finalise;
            Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KID);
            Expr := '';
            KID := 0;
          End;

          Case KeyWordID of
            SP_KW_TRANSPARENT, SP_KW_TRANS:
              Begin
                Inc(Position, 1+SizeOf(LongWord));
                Expr := Expr + SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code <> SP_ERR_OK Then Exit;
                If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                KeyWordID := SP_KW_PR_TRANSPARENT;
                TransFlag := True;
                Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);
                Expr := '';
              End;
            SP_KW_CENTRE:
              Begin
                Inc(Position, 1+SizeOf(LongWord));
                Expr := Expr + SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code <> SP_ERR_OK Then Exit;
                If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                KeyWordID := SP_KW_PR_CENTRE;
                CentreFlag := True;
                Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);
                Expr := '';
              End;
            SP_KW_INK, SP_KW_PAPER, SP_KW_INVERSE, SP_KW_TAB, SP_KW_OVER, SP_KW_ITALIC, SP_KW_BOLD:
              Begin
                Inc(Position, 1+SizeOf(LongWord));
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code <> SP_ERR_OK Then Exit;
                If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                Case KeyWordID Of
                  SP_KW_ITALIC: KeyWordID := SP_KW_PR_ITALIC;
                  SP_KW_BOLD: KeyWordID := SP_KW_PR_BOLD;
                  SP_KW_INK: KeyWordID := SP_KW_PR_INK;
                  SP_KW_PAPER: KeyWordID := SP_KW_PR_PAPER;
                  SP_KW_INVERSE: KeyWordID := SP_KW_PR_INVERSE;
                  SP_KW_TAB: KeywordID := SP_KW_PR_TAB;
                  SP_KW_OVER: KeyWordID := SP_KW_PR_OVER;
                End;
                Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);
                Expr := '';
              End;
            SP_KW_AT, SP_KW_MOVE, SP_KW_SCALE:
              Begin
                Inc(Position, 1+SizeOf(LongWord));
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code <> SP_ERR_OK Then Exit;
                If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                If (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
                  Inc(Position, 2)
                Else Begin
                  Error.Code := SP_ERR_ILLEGAL_CHAR;
                  Exit;
                End;
                Expr := Expr + SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code <> SP_ERR_OK Then Exit;
                If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                Case KeyWordID Of
                  SP_KW_AT: KeyWordID := SP_KW_PR_AT;
                  SP_KW_MOVE: KeyWordID := SP_KW_PR_MOVE;
                  SP_KW_SCALE: KeyWordID := SP_KW_PR_SCALE;
                End;
                Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);
                Expr := '';
              End;
            SP_KW_CLIP:
              Begin
                Inc(Position, 1+SizeOf(LongWord));

                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OFF) Then Begin

                  Inc(Position, SizeOf(LongWord)+1);
                  KeyWordID := SP_KW_PR_CLIP_OFF;
                  Result := Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID) + Result;
                  Expr := '';

                End Else Begin

                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // x1
                  If Error.Code <> SP_ERR_OK Then Exit;
                  If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;

                  If (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
                    Inc(Position, 2)
                  Else Begin
                    Error.Code := SP_ERR_ILLEGAL_CHAR;
                    Exit;
                  End;

                  Expr := Expr + SP_Convert_Expr(Tokens, Position, Error, -1); // y1
                  If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;

                  If (Ord(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then
                    Inc(Position, 1+SizeOf(LongWord))
                  Else Begin
                    Error.Code := SP_ERR_ILLEGAL_CHAR;
                    Exit;
                  End;

                  Expr := Expr + SP_Convert_Expr(Tokens, Position, Error, -1); // x2
                  If Error.Code <> SP_ERR_OK Then Exit;
                  If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;

                  If (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
                    Inc(Position, 2)
                  Else Begin
                    Error.Code := SP_ERR_ILLEGAL_CHAR;
                    Exit;
                  End;

                  Expr := Expr + SP_Convert_Expr(Tokens, Position, Error, -1); // y2
                  If Error.Code <> SP_ERR_OK Then Exit;
                  If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;

                  KeyWordID := SP_KW_PR_CLIP;
                  Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);
                  Expr := '';

                End;

              End;
            SP_KW_OUT:
              Begin
                // OUT streamid|var$|SCREEN

                // This requires that the PRINT buffer be flushed before it's executed. Append a ";" to the current
                // items so a carriage return isn't executed:

                Inc(Position, 1+SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SCREEN) Then Begin
                  Inc(Position, SizeOf(LongWord) +1);
                  KeyWordID := SP_KW_PR_OUT_SCREEN;
                  Expr := '';
                End Else
                  If (Byte(Tokens[Position]) = SP_STRVAR) Then Begin
                    KeyWordID := SP_KW_PR_OUT_VAR;
                    Psn := Position;
                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + CreateToken(SP_Symbol, Psn, 1) + '~';
                    Position := Psn;
                    VarExpr := SP_Convert_Var_Assign(Tokens, Position, Error);
                    If Error.Code = SP_ERR_OK Then Begin
                      Expr := Expr + VarExpr;
                      Expr := CreateToken(SP_STRING, Psn, Length(Expr)) + Expr;
                      Expr := CreateToken(SP_STRING, Psn, Length(VarExpr)) + VarExpr + Expr;
                    End Else
                      Exit;
                  End Else Begin
                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType = SP_VALUE Then
                        KeyWordID := SP_KW_PR_OUT_STREAM
                      Else Begin
                        Error.Code := SP_ERR_SYNTAX_ERROR;
                        Exit;
                      End;
                  End;

                Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);
                Expr := '';

              End;
            SP_KW_USING:
              Begin
                Inc(Position, 1+SizeOf(LongWord));
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code <> SP_ERR_OK Then Exit;
                If Error.ReturnType <> SP_STRING Then Begin
                  Error.Code := SP_ERR_MISSING_STREXPR;
                  Exit;
                End;
                KeyWordID := SP_KW_PR_USING;
                Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);
                Expr := '';
              End;
            SP_KW_ELSE, SP_KW_ENDIF:
              Goto Finalise;
          Else
            Error.Code := SP_ERR_SYNTAX_ERROR;
            Exit;
          End;
        End;

      SP_SYMBOL:
        Begin
          If Tokens[Position +1] in [#39, ',', ';'] Then Begin
            Inc(Position);
            Expr := CreateToken(SP_SYMBOL, Position -1, 1) + Tokens[Position] + Expr;
            KID := InitialKID;
            Inc(Position);
          End Else
            If Tokens[Position +1] = ':' Then
              Goto Finalise
            Else
              Goto Expression;
        End;

    Else

      Expression:
      nExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then Exit;
      If nExpr <> '' Then
        Expr := nExpr + Expr
      Else Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End;

    End;

  End;

Finalise:

  Result := Result + Expr + CreateToken(SP_SYMBOL, 0, 1) + #255 + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(InitialKID); // #255 to signal end of PRINT sequence
  KID := 0;

  If TransFlag Then
    Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0) + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_PR_TRANSPARENT);

  If CentreFlag Then
    Result := Result + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_PR_CENTRE_OFF);

End;

Function  SP_Convert_ITALIC(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // ITALIC numexpr

  Result := '';
  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK then Exit;
  If Error.ReturnType <> SP_VALUE Then Error.Code := SP_ERR_MISSING_NUMEXPR;

End;

Function  SP_Convert_BOLD(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // BOLD numexpr

  Result := '';
  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK then Exit;
  If Error.ReturnType <> SP_VALUE Then Error.Code := SP_ERR_MISSING_NUMEXPR;

End;

Function  SP_Convert_INK(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // INK numexpr

  Result := '';
  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK then Exit;
  If Error.ReturnType <> SP_VALUE Then Error.Code := SP_ERR_MISSING_NUMEXPR;

End;

Function  SP_Convert_TRANSPARENT(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // TRANSPARENT numexpr

  Result := '';
  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK then Exit;
  If Error.ReturnType <> SP_VALUE Then Error.Code := SP_ERR_MISSING_NUMEXPR;

End;

Function  SP_Convert_CLIP(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
Begin

  // CLIP [OFF|x1,y1 TO x2,y2]

  Result := '';
  If (Byte(Tokens[Position]) = SP_KEYWORD) and (pLongWord(@Tokens[Position +1])^ = SP_KW_OFF) Then Begin

    Inc(Position, SizeOf(LongWord) +1);
    Result := '';
    KeyWordID := SP_KW_CLIP_OFF;

  End Else Begin

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // x1
    If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
    Result := Expr;

    If (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
      Inc(Position, 2)
    Else Begin
      Error.Code := SP_ERR_ILLEGAL_CHAR;
      Exit;
    End;

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // y1
    If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
    Result := Result + Expr;

    If (Ord(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then
      Inc(Position, 1+SizeOf(LongWord))
    Else Begin
      Error.Code := SP_ERR_ILLEGAL_CHAR;
      Exit;
    End;

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // x2
    If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
    Result := Result + Expr;

    If (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
      Inc(Position, 2)
    Else Begin
      Error.Code := SP_ERR_ILLEGAL_CHAR;
      Exit;
    End;

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // y2
    If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;

    Result := Result + Expr;

  End;

End;

Function  SP_Convert_PAPER(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // PAPER numexpr

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK then Exit;
  If Error.ReturnType <> SP_VALUE Then Error.Code := SP_ERR_MISSING_NUMEXPR;

End;

Function  SP_Convert_INVERSE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // INVERSE numexpr

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK then Exit;
  If Error.ReturnType <> SP_VALUE Then Error.Code := SP_ERR_MISSING_NUMEXPR;

End;

Function  SP_Convert_OVER(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // OVER numexpr

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK then Exit;
  If Error.ReturnType <> SP_VALUE Then Error.Code := SP_ERR_MISSING_NUMEXPR;

End;

Function  SP_Convert_ENUM(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Done: Boolean;
  VarExpr: aString;
  VarType: Byte;
  Count: Integer;
Begin

  // ENUM var[,var...] [BASE n]

  Count := 1;
  Result := '';
  Done := False;
  While Not Done Do Begin
    VarType := Byte(Tokens[Position]);
    VarExpr := SP_Convert_Var_Assign(Tokens, Position, Error);
    If (Error.ReturnType = SP_ARRAY_ASSIGN) or (Error.ReturnType = SP_SLICE_ASSIGN) Then VarExpr := VarExpr + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_LET);
    VarExpr := CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_ENUM) + VarExpr;
    Case VarType Of
      SP_NUMVAR:
        Begin
          Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(Count) + VarExpr;
        End;
      SP_STRVAR:
        Begin
          Result := Result + CreateToken(SP_STRING, 0, 1) + aChar(Count) + VarExpr;
        End;
    Else
      Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End;
    End;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Inc(Count);
    End Else
      Done := True;
  End;

  If (Byte(Tokens[Position]) = SP_KEYWORD) and (pLongWord(@Tokens[Position +1])^ = SP_KW_BASE) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    Result := SP_Convert_Expr(Tokens, Position, Error, -1) + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_ENUM_BASE) + Result;
    If Error.Code <> SP_ERR_OK Then
      Exit
    Else
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End;
  End Else
    Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1) + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_ENUM_BASE) + Result;

  KeyWordID := 0;

End;

Function SP_Convert_LET(Var Tokens: aString; Var KeyWordID: LongWord; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarExpr: Array of aString;
  RTs: Array of Integer;
  VarType, RT, VarPos, VarIdx, VarSize, Idx, sPos: Integer;
  VarName, Expr, stExpr, arExpr, arTokens, TempStr: aString;
  Done: Boolean;
  Token: pToken;
  EquateType: aChar;
Label
  Next_Assign;
Begin

  // LET var[,var...] = value

  // LET numvar[(index[,index...])]=numexpr
  // LET strvar[(index[,index...][ TO numexpr])]=strexpr
  // LET strvar[(index[,index...])]=STRUCT structure[(member1=value[,member2=value...])]

  // Stack the variable, then the expression
  // If there's some default values, then specify those also.

  // Supports in-line increments et al with +=, -=, *=, /=
  // For arrays, these are "multiplied out" so a(1)+=1 becomes a(1)=a(1)+1 - for regular numeric vars, they're handled by
  // special handlers for extra speed.

  Result := '';

Next_Assign:

  EquateType := #0;
  sPos := Position;
  If Not ((Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR]) or (Byte(Tokens[Position]) = SP_FUNCTION)) Then Begin
    Error.Code := SP_ERR_MISSING_VAR;
    Exit;
  End Else
    VarType := Byte(Tokens[Position]);

  Done := False;
  RT := -1;
  While Not Done Do Begin
    SetLength(VarExpr, Length(VarExpr) +1);
    SetLength(RTs, Length(VarExpr));
    VarExpr[Length(VarExpr) -1] := SP_Convert_Var_Assign(Tokens, Position, Error);
    If VarType = SP_FUNCTION Then
      VarType := Error.ReturnType; // Will always be strvar or numvar.
    If Error.Code <> SP_ERR_OK Then
      Exit
    Else
      If RT <> -1 Then Begin
        If Error.ReturnType <> RT Then Begin
          Error.Code := SP_ERR_MIXED_TYPES;
          Exit;
        End;
      End Else
        RT := Error.ReturnType;
    RTs[Length(RTs) -1] := RT;

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] in ['=', SP_CHAR_INCVAR, SP_CHAR_DECVAR, SP_CHAR_MULVAR, SP_CHAR_DIVVAR, SP_CHAR_POWVAR, SP_CHAR_MODVAR, SP_CHAR_ANDVAR, SP_CHAR_ORVAR, SP_CHAR_NOTVAR, SP_CHAR_XORVAR]) Then Begin
      EquateType := Tokens[Position +1];
      Done := True;
    End Else
      If Not ((Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',')) Then Begin
        If KeyWordID = SP_KW_IMPLICIT_LET Then
          Error.Code := SP_ERR_INVALID_KEYWORD
        Else
          Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End Else
        Inc(Position, 2);
  End;

  KeyWordID := SP_KW_LET;

  If Not ((Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] in ['=', SP_CHAR_INCVAR, SP_CHAR_DECVAR, SP_CHAR_MULVAR, SP_CHAR_DIVVAR, SP_CHAR_POWVAR, SP_CHAR_MODVAR, SP_CHAR_ANDVAR, SP_CHAR_ORVAR, SP_CHAR_NOTVAR, SP_CHAR_XORVAR])) Then Begin
    Error.Code := SP_ERR_MISSING_EQU;
    Exit;
  End Else
    Inc(Position, 2);

  Case VarType Of

    SP_NUMVAR:
      Begin
        Idx := 1;
        TempStr := Copy(Tokens, sPos, (Position - sPos)-2);
        Case EquateType of
          '=': ArTokens := '';
          SP_CHAR_INCVAR: ArTokens := TempStr + aChar(SP_SYMBOL) + '+' + Copy(Tokens, Position, 999999);
          SP_CHAR_DECVAR: ArTokens := TempStr + aChar(SP_SYMBOL) + '-' + Copy(Tokens, Position, 999999);
          SP_CHAR_MULVAR: ArTokens := TempStr + aChar(SP_SYMBOL) + '*' + Copy(Tokens, Position, 999999);
          SP_CHAR_DIVVAR: ArTokens := TempStr + aChar(SP_SYMBOL) + '/' + Copy(Tokens, Position, 999999);
          SP_CHAR_POWVAR: ArTokens := TempStr + aChar(SP_SYMBOL) + '^' + Copy(Tokens, Position, 999999);
          SP_CHAR_MODVAR: ArTokens := TempStr + aChar(SP_SYMBOL) + SP_CHAR_MOD + Copy(Tokens, Position, 999999);
          SP_CHAR_ANDVAR: ArTokens := TempStr + aChar(SP_SYMBOL) + '&' + Copy(Tokens, Position, 999999);
          SP_CHAR_ORVAR:  ArTokens := TempStr + aChar(SP_SYMBOL) + '|' + Copy(Tokens, Position, 999999);
          SP_CHAR_NOTVAR: ArTokens := TempStr + aChar(SP_SYMBOL) + SP_CHAR_NOTVAR + Copy(Tokens, Position, 999999);
          SP_CHAR_XORVAR: ArTokens := TempStr + aChar(SP_SYMBOL) + SP_CHAR_XOR + Copy(Tokens, Position, 999999);
        End;
        If ArTokens <> '' Then
          arExpr := SP_Convert_Expr(arTokens, Idx, Error, -1);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
        If Error.Code <> SP_ERR_OK Then
          Exit
        Else
          If (Error.ReturnType <> SP_VALUE) And (Error.ReturnType <> SP_NUMVAR) Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
        For Idx := 0 To Length(VarExpr) -1 Do Begin
          KeyWordID := 0;
          If RTs[Idx] = SP_NUMVAR Then Begin
            Case EquateType of
              '=':
                pToken(@VarExpr[Idx][1])^.Token := SP_NUMVAR_LET;
              SP_CHAR_INCVAR:
                pToken(@VarExpr[Idx][1])^.Token := SP_INCVAR;
              SP_CHAR_DECVAR:
                pToken(@VarExpr[Idx][1])^.Token := SP_DECVAR;
              SP_CHAR_MULVAR:
                pToken(@VarExpr[Idx][1])^.Token := SP_MULVAR;
              SP_CHAR_DIVVAR:
                pToken(@VarExpr[Idx][1])^.Token := SP_DIVVAR;
              SP_CHAR_POWVAR:
                pToken(@VarExpr[Idx][1])^.Token := SP_POWVAR;
              SP_CHAR_MODVAR:
                pToken(@VarExpr[Idx][1])^.Token := SP_MODVAR;
              SP_CHAR_ANDVAR:
                pToken(@VarExpr[Idx][1])^.Token := SP_ANDVAR;
              SP_CHAR_ORVAR:
                pToken(@VarExpr[Idx][1])^.Token := SP_ORVAR;
              SP_CHAR_NOTVAR:
                pToken(@VarExpr[Idx][1])^.Token := SP_NOTVAR;
              SP_CHAR_XORVAR:
                pToken(@VarExpr[Idx][1])^.Token := SP_XORVAR;
            End;
            Result := Result + Expr + VarExpr[Idx];
          End Else
            If RTs[Idx] = SP_ARRAY_ASSIGN Then Begin
              VarExpr[Idx] := VarExpr[Idx] + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_LET);
              If arTokens <> '' Then
                Result := Result + arExpr + VarExpr[Idx]
              Else
                Result := Result + Expr + VarExpr[Idx];
            End Else Begin
              VarExpr[Idx] := VarExpr[Idx] + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_LET);
              Result := Result + Expr + VarExpr[Idx];
            End;
        End;

      End;

    SP_STRVAR:
      Begin

        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_STRUCT) and (Error.ReturnType in [SP_STRING, SP_STRVAR]) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
            Inc(Position);
            VarPos := Position;
            VarIdx := pLongWord(@Tokens[Position])^;
            Inc(Position, SizeOf(LongWord));
            VarSize := pLongWord(@Tokens[Position])^;
            Inc(Position, SizeOf(LongWord));
            VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
            Inc(Position, VarSize);
            Token := @VarExpr[0][1];
            If Token^.Token = SP_STRVAR_LET Then Token^.Token := SP_STRVAR;
            Result := CreateToken(SP_NUMVAR, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
              Inc(Position, 2);
              Done := False;
              While Not Done Do Begin
                If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
                  VarType := Byte(Tokens[Position]);
                  Inc(Position);
                  VarPos := Position;
                  VarIdx := pLongWord(@Tokens[Position])^;
                  Inc(Position, SizeOf(LongWord));
                  VarSize := pLongWord(@Tokens[Position])^;
                  Inc(Position, SizeOf(LongWord));
                  VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
                  Inc(Position, VarSize);
                  Result := CreateToken(VarType, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName + Result;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '=') Then Begin
                    Inc(Position, 2);
                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If (Error.ReturnType = SP_VALUE) And (VarType <> SP_NUMVAR) Then Begin
                        Error.Code := SP_ERR_SYNTAX_ERROR;
                        Exit;
                      End Else
                        If (Error.ReturnType = SP_STRING) And (VarType <> SP_STRVAR) Then Begin
                          Error.Code := SP_ERR_SYNTAX_ERROR;
                          Exit;
                        End Else Begin
                          Result := Expr + Result;
                          If Byte(Tokens[Position]) = SP_SYMBOL Then Begin
                             Inc(Position);
                             If Tokens[Position] = ')' Then Begin
                              Dec(Position);
                              Done := True;
                             End Else
                              If Tokens[Position] <> ',' Then Begin
                                Error.Code := SP_ERR_SYNTAX_ERROR;
                                Exit;
                              End Else
                                Inc(Position);
                          End Else Begin
                            Error.Code := SP_ERR_SYNTAX_ERROR;
                            Exit;
                          End;
                        End;
                  End Else Begin
                    Error.Code := SP_ERR_SYNTAX_ERROR;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_INVALID_STRUCT_MEMBER;
                  Exit;
                End;
              End;
              If Not((Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')')) Then Begin
                Error.Code := SP_ERR_MISSING_BRACKET;
                Exit;
              End Else
                Inc(Position, 2);
            End;
            stExpr := Result;
            Result := '';
            KeyWordID := 0;
            For Idx := 0 To Length(VarExpr) -1 Do
              Result := stExpr + VarExpr[Idx] + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_LET) + Result;
          End Else Begin
            Error.Code := SP_ERR_INVALID_STRUCTURE_NAME;
            Exit;
          End;
        End Else Begin

          Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then
            Exit
          Else
            If ((RT = SP_NUMVAR) And Not (Error.ReturnType in [SP_NUMVAR, SP_VALUE])) or ((RT in [SP_STRVAR, SP_SLICE_ASSIGN]) And (Error.ReturnType <> SP_STRING)) Then Begin
              Error.Code := SP_ERR_MISSING_STREXPR;
              Exit;
            End;
          For Idx := 0 To Length(VarExpr) -1 Do Begin
            KeyWordID := 0;
            If (RTs[Idx] = SP_STRVAR) And (Byte(VarExpr[Idx][1]) <> SP_STRUCT_MEMBER_ASS) Then
              pToken(@VarExpr[Idx][1])^.Token := SP_STRVAR_LET
            Else
              VarExpr[Idx] := VarExpr[Idx] + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_LET);
            Result := Result + Expr + VarExpr[Idx];
          End;

        End;
      End;

  Else

    Error.Code := SP_ERR_MISSING_VAR;

  End;

  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
    Inc(Position, 2);
    SetLength(VarExpr, 0);
    Goto Next_Assign;
  End;

End;

Function SP_Convert_CLS(Var Tokens: aString; Var Position: Integer; Var KeyWordID: LongWord; Var Error: TSP_ErrorCode): aString;
Begin

  // CLS [[ALPHA] numexpr]

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ALPHA) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));
    KeyWordID := SP_KW_CLS_ALPHA;

  End;

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);

  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Result <> '' Then
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;

End;

Function SP_Convert_DIM(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  DimVarPos, DimVarIdx, DimVarSize, VarPos, VarIdx, VarSize, NumIndices, nSplits: LongWord;
  DimVarName, VarName, BaseExpr, Expr, AutoExpr, LenExpr, SplitExpr, DIMString: aString;
  VarType, DimVarType: Byte;
  Done, AutoArray, IsDynamic, IsSplit, SplitNot: Boolean;
  iArr, cArr: Array of Integer;
  CurIndex, lArr: Integer;
Label
  Test_Len, Next_DIM;
Begin

  // DIM variable{(numexpr[,numexpr...])|()=n,n,n...} [BASE n]
  // DIM variable${(numexpr[,numexpr...])|()=n$,n$,n$...} [LEN numexpr] [BASE n]
  // DIM variable$(numexpr[,numexpr...]) STRUCT structure[(member1=value[,member2=value...])] [BASE n]
  // DIM variable$(SPLIT s$, [NOT] delimiter$[,delimiter$...])

  // Also dynamic arrays - declare as:

  // DIM variable()
  // DIM variable$() [LEN numexpr]

  // Dynamic arrays, as they have no real support for indices (subscripts are dealt with as keys) cannot use
  // the BASE argument, as it has no meaning. Structures are supported, but default values are not - non-existent
  // elements cannot be read, and there is nowhere (and no efficient method for) to storing the default values that
  // will be needed when a new element is created.

  Result := '';

Next_DIM:

  LenExpr := '';
  DIMString := '';
  DimVarType := Byte(Tokens[Position]);
  If Not (DimVarType in [SP_NUMVAR, SP_STRVAR]) Then Begin
    Error.Code := SP_ERR_MISSING_VAR;
    Exit;
  End;

  Inc(Position);
  DimVarPos := Position;
  DimVarIdx := pLongWord(@Tokens[Position])^;
  Inc(Position, SizeOf(LongWord));
  DimVarSize := pLongWord(@Tokens[Position])^;
  Inc(Position, SizeOf(LongWord));
  DimVarName := LowerNoSpaces(Copy(Tokens, Position, DimVarSize));
  Inc(Position, DimVarSize);

  // Gather indices - start with a bracket, numexpr for each, separated by commas, end with a bracket.
  // If the next token is an "=" symbol then this is an auto-array, one dimensional. Empty brackets denote
  // a dynamic array.

  NumIndices := 0;
  IsSplit := False;
  SplitNOT := False;
  AutoArray := False;
  IsDynamic := False;
  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
    Inc(Position, 2);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
      Inc(Position, 2);
      IsDynamic := True;
      Goto Test_LEN;
    End Else
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SPLIT) Then Begin
        // A split array - supply a string to be split, and a character that you want to split with (optionally with NOT)
        IsSplit := True;
        IsDynamic := True;
        Inc(Position, 1 + SizeOf(LongWord));
        SplitExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
        If Error.Code <> SP_ERR_OK Then
          Exit
        Else
          If Error.ReturnType <> SP_STRING Then Begin
            Error.Code := SP_ERR_MISSING_STREXPR;
            Exit;
          End;
        If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = SP_CHAR_NOT) Then begin
            Inc(Position, 2);
            SplitNOT := True;
          End;
          nSplits := 0;
          Done := False;
          While Not Done Do Begin
            SplitExpr := SplitExpr + SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then
              Exit
            Else
              If Error.ReturnType <> SP_STRING Then Begin
                Error.Code := SP_ERR_MISSING_STREXPR;
                Exit;
              End;
            Inc(nSplits);
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
              Inc(Position, 2);
              SplitExpr := SplitExpr + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(nSplits);
              Done := True;
            End Else Begin
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
                Inc(Position, 2)
              Else Begin
                Error.Code := SP_ERR_MISSING_BRACKET;
                Exit;
              End;
            End;
          End;
        End Else Begin
          Error.Code := SP_ERR_MISSING_COMMA;
          Exit;
        End;
      End Else Begin
        NumIndices := 0; // Process indices - DIM a(4,2) for example
        While True Do Begin
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then
            Exit
          Else
            If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End Else Begin
              Inc(NumIndices);
              DIMString := Expr + DIMString;
              If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = ')') Then Begin
                DIMString := DIMString + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(NumIndices);
                Inc(Position, 2);
                Break;
              End Else
                If Not ((Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',')) Then Begin
                  Error.Code := SP_ERR_MISSING_COMMA;
                  Exit;
                End Else Begin
                  Inc(Position, 2);
                End;
            End;
        End;
      End;
  End Else Begin
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '=') Then Begin
      // Now gather values - comma separated numerics or strings depending on vartype.
      // Brackets used to indicate more indices - such as ((1,2),(3,4)) will result in a (2,2) array
      Done := False;
      Inc(Position, 2);
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin // starts a multi-dim declaration
        SetLength(iArr, 0);
        SetLength(cArr, 0);
        CurIndex := -1;
        lArr := 0;
        While Not Done Do Begin
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin // Open bracket advances to next dimension
            Inc(Position, 2);
            Inc(CurIndex);
            If CurIndex >= lArr Then Begin
              Inc(lArr);
              SetLength(iArr, lArr);
              SetLength(cArr, lArr);
              iArr[lArr -1] := -1;
              cArr[lArr -1] := 0;
            End;
          End Else
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
              Inc(Position, 2);
              Inc(cArr[CurIndex]);
              If iArr[CurIndex] = -1 Then
                iArr[CurIndex] := cArr[CurIndex]
              Else
                If iArr[CurIndex] <> cArr[CurIndex] Then Begin
                  Error.Code := SP_ERR_SUBSCRIPT_WRONG;
                  Exit;
                End;
              cArr[CurIndex] := 0;
              Dec(CurIndex);
              If CurIndex = -1 Then
                Done := True;
            End Else
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Inc(cArr[CurIndex]);
              End Else Begin
                DIMString := SP_Convert_Expr(Tokens, Position, Error, -1) + DIMString;
                If Error.Code <> SP_ERR_OK Then
                  Exit
                Else
                  If ((DimVarType = SP_NUMVAR) And (Error.ReturnType <> SP_VALUE)) or ((DimVarType = SP_STRVAR) And (Error.ReturnType <> SP_STRING)) Then Begin
                    Error.Code := SP_ERR_SYNTAX_ERROR;
                    Exit;
                  End;
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                  Inc(Position, 2);
                  if CurIndex = -1 Then CurIndex := 0;
                  Inc(cArr[CurIndex]);
                End;
              End;
        End;
        // now put what we have into a form the interpreter can understand.
        If Length(iArr) = 0 Then Begin
          Error.Code := SP_ERR_SYNTAX_ERROR;
          Exit;
        End Else Begin
          AutoArray := True;
          AutoExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(Length(iArr));
          For CurIndex := 0 To Length(iArr) -1 Do
            AutoExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(iArr[CurIndex]) + AutoExpr;
        End;
      End Else Begin // fall back to the single-dimension legacy parsing.
        While Not Done Do Begin
          DIMString := SP_Convert_Expr(Tokens, Position, Error, -1) + DIMString;
          If Error.Code <> SP_ERR_OK Then
            Done := True
          Else
            If ((DimVarType = SP_NUMVAR) And (Error.ReturnType <> SP_VALUE)) or ((DimVarType = SP_STRVAR) And (Error.ReturnType <> SP_STRING)) Then Begin
              Error.Code := SP_ERR_SYNTAX_ERROR;
              Exit;
            End;
          Inc(NumIndices);
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
            Inc(Position, 2)
          Else
            Done := True;
        End;
        If NumIndices = 0 Then Begin
          Error.Code := SP_ERR_SYNTAX_ERROR;
          Exit;
        End Else Begin
          AutoArray := True;
          AutoExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
          AutoExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(NumIndices) + AutoExpr;
        End;
      End;
    End Else Begin
      Error.Code := SP_ERR_MISSING_BRACKET;
      Exit;
    End;
  End;

  // Now check for options: LEN, STRUCT and BASE. LEN and STRUCT are mutually exclusive.
  // An auto-array can use BASE and LEN (for string arrays) but not STRUCT.

  BaseExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1);
  If (Byte(Tokens[Position]) = SP_KEYWORD) and (pLongWord(@Tokens[Position +1])^ = SP_KW_BASE) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    BaseExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then
      Exit
    Else
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End;
  End;

  Test_Len:

  If DimVarType = SP_STRVAR Then
    If (Byte(Tokens[Position]) = SP_FUNCTION) and (pLongWord(@Tokens[Position +1])^ = SP_FN_LEN) Then Begin
      Inc(Position, 1+SizeOf(LongWord));
      LenExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then
        Exit
      Else
        If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
    End Else Begin
      // Add a length of 0 if no LEN specified
      LenExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);
      If (Byte(Tokens[Position]) = SP_KEYWORD) and (pLongWord(@Tokens[Position +1])^ = SP_KW_STRUCT) And Not (AutoArray or IsDynamic) Then Begin
        Inc(Position, 1 + SizeOf(LongWord));
        If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
          Inc(Position);
          VarPos := Position;
          VarIdx := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
          VarSize := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
          VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
          Inc(Position, VarSize);
          DIMString := CreateToken(SP_NUMVAR, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName + DIMString;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
            Inc(Position, 2);
            Done := False;
            While Not Done Do Begin
              If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
                VarType := Byte(Tokens[Position]);
                Inc(Position);
                VarPos := Position;
                VarIdx := pLongWord(@Tokens[Position])^;
                Inc(Position, SizeOf(LongWord));
                VarSize := pLongWord(@Tokens[Position])^;
                Inc(Position, SizeOf(LongWord));
                VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
                Inc(Position, VarSize);
                DIMString := CreateToken(VarType, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName + DIMString;
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '=') Then Begin
                  Inc(Position, 2);
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then
                    Exit
                  Else
                    If (Error.ReturnType = SP_VALUE) And (VarType <> SP_NUMVAR) Then Begin
                      Error.Code := SP_ERR_SYNTAX_ERROR;
                      Exit;
                    End Else
                      If (Error.ReturnType = SP_STRING) And (VarType <> SP_STRVAR) Then Begin
                        Error.Code := SP_ERR_SYNTAX_ERROR;
                        Exit;
                      End Else Begin
                        DIMString := Expr + DIMString;
                        If Byte(Tokens[Position]) = SP_SYMBOL Then Begin
                           Inc(Position);
                           If Tokens[Position] = ')' Then Begin
                            Dec(Position);
                            Done := True;
                           End Else
                            If Tokens[Position] <> ',' Then Begin
                              Error.Code := SP_ERR_SYNTAX_ERROR;
                              Exit;
                            End Else
                              Inc(Position);
                        End Else Begin
                          Error.Code := SP_ERR_SYNTAX_ERROR;
                          Exit;
                        End;
                      End;
                End Else Begin
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              End Else Begin
                Error.Code := SP_ERR_INVALID_STRUCT_MEMBER;
                Exit;
              End;
            End;
            If Not((Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')')) Then Begin
              Error.Code := SP_ERR_MISSING_BRACKET;
              Exit;
            End Else
              Inc(Position, 2);
          End;
        End Else Begin
          Error.Code := SP_ERR_INVALID_STRUCTURE_NAME;
          Exit;
        End;
      End;
    End;

  If (Not IsDynamic) And (Byte(Tokens[Position]) = SP_KEYWORD) and (pLongWord(@Tokens[Position +1])^ = SP_KW_BASE) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    BaseExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then
      Exit
    Else
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End;
  End;

  If AutoArray Then Begin
    DIMString := DIMString + AutoExpr;
    KeyWordID := SP_KW_AUTODIM;
  End Else
    If IsDynamic Then
      KeyWordID := SP_KW_DYNAMIC_DIM;

  If IsSplit Then Begin
    DIMString := DIMString + SplitExpr;
    KeyWordID := SP_KW_DIM_SPLIT;
    If SplitNOT Then
      DIMString := DIMString + CreateToken(SP_VALUE, 0, SizeOf(aFloat))+aFloatToString(-1)
    Else
      DIMString := DIMString + CreateToken(SP_VALUE, 0, SizeOf(aFloat))+aFloatToString(1)
  End;

  DIMString := DIMString + LenExpr + BaseExpr;
  Result := Result + DIMString + CreateToken(DimVarType, DimVarPos, SizeOf(LongWord)+Length(DimVarName)) + LongWordToString(DimVarIdx) + DimVarName;

  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
    Result := Result + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(KeyWordID);
    Inc(Position, 2);
    Goto Next_DIM;
  End;

End;

Function SP_Convert_RUN(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // RUN [numexpr|Label]

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);

  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Result <> '' Then
      If Not (Error.ReturnType in [SP_VALUE, SP_LABEL]) Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;

End;

Function SP_Convert_GO(Var KeyWordID, InitialKWID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // GO <TO|SUB> <numexpr|Label>

  Result := '';

  If (Byte(Tokens[Position]) in [SP_KEYWORD, SP_SYMBOL]) or DoingRepeatParams Then Begin
    If Not DoingRepeatParams Then
      If Byte(Tokens[Position]) = SP_KEYWORD Then Begin
        KeyWordID := pLongWord(@Tokens[Position +1])^;
        Inc(Position, 1 + SizeOf(LongWord));
      End Else Begin
        KeyWordID := Byte(Tokens[Position +1]);
        Inc(Position, 2);
      End;
    If (KeyWordID = SP_KW_TO) Or (KeyWordID = Ord(SP_CHAR_SUB)) or DoingRepeatParams Then Begin
      Result := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then
        Exit
      Else
        If Result <> '' Then
          If Not(Error.ReturnType in [SP_VALUE, SP_LABEL]) Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
      If Not DoingRepeatParams Then Begin
        If KeyWordID = SP_KW_TO Then
          KeyWordID := SP_KW_GOTO
        Else
          If KeyWordID = Ord(SP_CHAR_SUB) Then
            KeyWordID := SP_KW_GOSUB;
        InitialKWID := KeyWordID;
      End;
    End Else
      Error.Code := SP_ERR_SYNTAX_ERROR;
  End;

End;

Function SP_Convert_RETURN(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // RETURN

  Result := '';

End;

Function SP_Convert_STOP(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // STOP

  Result := '';

End;

Function SP_Convert_OLD(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // OLD

  Result := ''

End;

Function SP_Convert_CONTINUE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // CONTINUE

  Result := '';

End;

Function SP_Convert_FOR(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarExpr, ExprFrom, ExprTo, ExprStep, VarName, RangeExpr, TempExpr: aString;
  VarPos, VarSize, EachType, NumRanges, bkPos: Integer;
  VarType: aChar;
  Token: pToken;
Label
  IsExpr;
Begin

  // FOR numvar = numexpr TO numexpr [STEP numexpr]
  // FOR EACH num/strvar IN {array()|[sequence]}
  // FOR EACH strvar IN strexpr

  Result := '';
  EachType := -1;

  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

    KeyWordID := SP_KW_FOR;

    VarExpr := SP_Convert_Var_Assign(Tokens, Position, Error);
    If Error.Code = SP_ERR_OK Then Begin
      Token := @VarExpr[1];
      If Token^.Token = SP_NUMVAR_LET Then Token^.Token := SP_NUMVAR;
      If Error.Code <> SP_ERR_OK Then
        Exit
      Else
        If Byte(VarExpr[Length(VarExpr) - (SizeOf(LongWord)+1) - SizeOf(TToken) +1]) = SP_ARRAY_ASSIGN Then Begin
          Error.Code := SP_ERR_SYNTAX_ERROR;
          Exit;
        End;

      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '=') Then Begin

        Inc(Position, 2);
        ExprFrom := SP_Convert_Expr(Tokens, Position, Error, -1);
        If Error.Code <> SP_ERR_OK Then
          Exit
        Else
          If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;

        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin

          Inc(Position, SizeOf(LongWord) + 1);
          ExprTo := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then
            Exit
          Else
            If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;

          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_STEP) Then Begin
            Inc(Position, SizeOf(LongWord) +1);
            ExprStep := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then
              Exit
            Else
              If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
          End Else
            ExprStep := '';

          If ExprStep <> '' Then
            Result := ExprStep + ExprTo + ExprFrom
          Else
            Result := ExprTo + ExprFrom;

          Result := VarExpr + Result;

        End Else
          Error.Code := SP_ERR_MISSING_TO;

      End Else
        Error.Code := SP_ERR_MISSING_EQU;
    End Else
      Exit;

  End Else

    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_EACH) Then Begin

      Inc(Position, 1 + SizeOf(LongWord));
      KeyWordID := SP_KW_FOR_EACH;

      // Need a variable, of any type here. Not a structure member or array value though!

      VarExpr := SP_Convert_Var_Assign(Tokens, Position, Error);

      If (Error.Code <> SP_ERR_OK) Or (VarExpr = '') Then Exit;

      Token := @VarExpr[1];
      Case Token^.Token of
        SP_NUMVAR_LET:
          Begin
            Token^.Token := SP_NUMVAR;
            EachType := SP_VALUE;
          End;
        SP_STRVAR_LET:
          Begin
            Token^.Token := SP_STRVAR;
            EachType := SP_STRING;
          End;
        SP_STRUCT_MEMBER_ASS:
          Error.Code := SP_ERR_INVALID_EACH_VAR;
      End;
      If Error.Code <> SP_ERR_OK Then
        Exit
      Else
        If Byte(VarExpr[Length(VarExpr) - (SizeOf(LongWord) +1) - SizeOf(TToken) +1]) = SP_ARRAY_ASSIGN Then Begin
          Error.Code := SP_ERR_SYNTAX_ERROR;
          Exit;
        End;

      If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_IN) Then Begin

        Inc(Position, 1 + SizeOf(LongWord));

        If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin

          bkPos := Position;
          VarPos := Position;
          VarType := Tokens[Position];
          Inc(Position, 1 + SizeOf(LongWord));
          VarSize := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
          VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
          Inc(Position, VarSize);
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
             (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
            If Byte(Tokens[bkPos]) <> Token^.Token Then Begin
              Error.Code := SP_ERR_MIXED_TYPES;
              Exit;
            End;
            Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName + VarExpr;
            Inc(Position, 4);
          End Else Begin
            Position := bkPos;
            Goto IsExpr;
          End;
        End Else
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '[') Then Begin
            // Expecting a range here.
            // a TO b [STEP c], or a$ TO b$, or a$,b$,c$ or a,b,c
            // Gather up each one, comma separated, and prepend a marker to each.
            RangeExpr := '';
            NumRanges := 0;
            Inc(Position, 2);
            While True Do Begin
              // Must be a term here, of the same type (value or string) as the variable.
              TempExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
              If Error.ReturnType <> EachType Then Begin
                Error.Code := SP_ERR_MIXED_TYPES;
                Break;
              End;
              Inc(NumRanges);
              // Now either a comma, a TO or a ']' may follow.
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ']') Then Begin
                Inc(Position, 2);
                RangeExpr := RangeExpr + CreateToken(SP_EACHSINGLE, 0, 0) + TempExpr + CreateToken($FF, 0, 0);
                Break;
              End Else
                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
                  // A term MUST follow the TO, and it must be of the correct type.
                  Inc(Position, SizeOf(LongWord) +1);
                  TempExpr := TempExpr + SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.ReturnType <> EachType Then Begin
                    Error.Code := SP_ERR_MIXED_TYPES;
                    Break;
                  End;
                  // Now, check for a STEP, a comma or a ']'
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    // Finished this RANGE type - finalise it, move to the next.
                    RangeExpr := RangeExpr + CreateToken(SP_EACHRANGE, 0, 0) + TempExpr + CreateToken($FF, 0, 0);
                    Inc(Position, 2);
                  End Else
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ']') Then Begin
                      RangeExpr := RangeExpr + CreateToken(SP_EACHRANGE, 0, 0) + TempExpr + CreateToken($FF, 0, 0);
                      Inc(Position, 2);
                      Break;
                    End Else
                      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_STEP) Then Begin
                        // a STEP indicates that the FOR EACH loop should step through the range. This also finalises the range.
                        // Must be a numeric.
                        Inc(Position, SizeOf(LongWord) +1);
                        TempExpr := TempExpr + SP_Convert_Expr(Tokens, Position, Error, -1);
                        If Error.ReturnType <> SP_VALUE Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Break;
                        End;
                        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                          // Finished this RANGE type - finalise it, move to the next.
                          RangeExpr := RangeExpr + CreateToken(SP_EACHSTEP, 0, 0) + TempExpr + CreateToken($FF, 0, 0);
                          Inc(Position, 2);
                        End Else
                          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ']') Then Begin
                            RangeExpr := RangeExpr + CreateToken(SP_EACHSTEP, 0, 0) + TempExpr + CreateToken($FF, 0, 0);
                            Inc(Position, 2);
                            Break;
                          End Else Begin
                            Error.Code := SP_ERR_SYNTAX_ERROR;
                            Break;
                          End;
                      End Else Begin
                        Error.Code := SP_ERR_SYNTAX_ERROR;
                        Break;
                      End;
                End Else
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] <> ',') Then Begin
                    Error.Code := SP_ERR_SYNTAX_ERROR;
                    Break;
                  End Else Begin
                    Inc(Position, 2);
                    RangeExpr := RangeExpr + CreateToken(SP_EACHSINGLE, 0, 0) + TempExpr + CreateToken($FF, 0, 0);
                  End;
            End;
            If (Error.Code = SP_ERR_OK) And (RangeExpr <> '') Then Begin
              // Now the RangeExpr string variable contains interpretable text, of the type:
              // {EACH type + term [ + term [ + term ]]...}
              // Which we now store as a parameter of the token.
              Result := Result + CreateToken(SP_STRING, Position, Length(RangeExpr)) + RangeExpr;
              Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(NumRanges);
              Result := Result + VarExpr;
              KeyWordID := SP_KW_FOR_EACH_RANGE;
            End Else
              Error.Code := SP_ERR_SYNTAX_ERROR;
          End Else Begin
            IsExpr:
            // This could be a string expression in the case of FOR n$ IN m$
            TempExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.ReturnType <> EachType Then Begin
              Error.Code := SP_ERR_MIXED_TYPES;
              Exit;
            End Else
              if Error.Code <> SP_ERR_OK Then
                Exit
              else Begin
                Result := TempExpr + VarExpr;
                KeyWordID := SP_KW_FOR_EACH_STRING;
              End;
          End;

      End Else
        Error.Code := SP_ERR_SYNTAX_ERROR;

    End Else
      Error.Code := SP_ERR_MISSING_VARIABLE;

End;

Function SP_Convert_NEXT(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Token: pToken;
Begin

  // NEXT numvar|strvar

  Result := '';
  If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin

    Result := SP_Convert_Var_Assign(Tokens, Position, Error);
    If Error.Code = SP_ERR_OK Then Begin
      Token := @Result[1];
      Case Token^.Token of
        SP_NUMVAR_LET:
          Token^.Token := SP_NUMVAR;
        SP_STRVAR_LET:
          Token^.Token := SP_STRVAR;
        SP_STRUCT_MEMBER_ASS:
          Error.Code := SP_ERR_INVALID_EACH_VAR;
      End;
    End;
    If Error.Code <> SP_ERR_OK Then
      Exit
    Else
      If Byte(Result[Length(Result) - (SizeOf(LongWord) +1) - SizeOf(TToken) +1]) = SP_ARRAY_ASSIGN Then Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End;

  End Else

    Error.Code := SP_ERR_MISSING_VARIABLE;

End;

Function SP_Convert_IF(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode; Var StList: aString): aString;
Begin

  // IF numexpr THEN

  Result := '';
  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End Else Begin
      Result := CreateToken(SP_DISPLACEMENT, Position, SizeOf(aFloat)) + aFloatToString(0) + Result;
    End;

End;

Function SP_Convert_ELSE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode; Var StList: aString): aString;
Begin

  // ELSE - no parameters, just a displacement to jump forward by

  Result := CreateToken(SP_DISPLACEMENT, Position, SizeOf(aFloat)) + aFloatToString(0);

End;

{
Function SP_Convert_IF(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode; Var StList: aString): aString;
Var
  FnResult, dummyStList: aString;
  KeyWordPos, KeyWord: LongWord;
  PositionSave, IFCounter: Integer;
  HasELSE: Boolean;
Begin

  // IF numexpr THEN statement|jump [ELSE statement|jump] [ENDIF]

  Result := '';
  KeyWordPos := Position - SizeOf(LongWord) -1;
  FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Error.ReturnType <> SP_VALUE then
      Error.Code := SP_ERR_MISSING_NUMEXPR
    Else Begin
      Result := FnResult + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_IF);
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_THEN) Then Begin
        Inc(Position, SizeOf(LongWord) +1);
        If (Byte(Tokens[Position]) = SP_KEYWORD) or ((Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = '?')) or (Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR]) Then Begin
          If (Byte(Tokens[Position]) = SP_KEYWORD) Then Begin
            KeyWordID := pLongWord(@Tokens[Position +1])^;
            KeyWordPos := Position;
            Inc(Position, 1 + SizeOf(LongWord));
          End Else Begin
            If Byte(Tokens[Position]) = SP_SYMBOL Then Begin
              KeyWordPos := Position;
              KeyWordID := SP_KW_PRINT;
              Inc(Position, 2);
            End Else Begin
              KeyWordPos := Position;
              KeyWordID := SP_KW_LET;
            End;
          End;
          If KeyWordID = SP_KW_IF Then IFCounter := 1 Else IFCounter := 0;
          FnResult := SP_Convert_KeyWord(Tokens, Position, KeyWordID, Error, DummyStList);
          StList := StList + LongWordToString(Length(Tokens) + Length(Result) +1);
          If Error.Code <> SP_ERR_OK Then
            Exit
          Else Begin
            // Test for an ELSE or ENDIF
            HasELSE := False;
            PositionSave := Position;
            While Position < Length(Tokens) Do Begin
              Case Byte(Tokens[Position]) of
                SP_STRINGCHAR:
                  Inc(Position, SizeOf(aFloat) +1);
                SP_SYMBOL:
                  Begin
                    Inc(Position, 2);
                  End;
                SP_VALUE:
                  Begin
                    Inc(Position, 1 + SizeOf(aFloat));
                  End;
                SP_STRING, SP_LABEL, SP_TEXT, SP_COMMENT:
                  Begin
                    Inc(Position, 1 + SizeOf(LongWord) + pLongWord(@Tokens[Position +1])^);
                  End;
                SP_KEYWORD, SP_FUNCTION:
                  Begin
                    KeyWord := pLongWord(@Tokens[Position +1])^;
                    Case KeyWord Of
                      SP_KW_IF:
                        Begin
                          Inc(IFCounter);
                        End;
                      SP_KW_ELSE, SP_KW_ENDIF:
                        Begin
                          If IFCounter = 0 Then Begin
                            HasELSE := True;
                            Break;
                          End Else
                            Dec(IFCounter);
                        End;
                    End;
                    Inc(Position, 1 + SizeOf(LongWord));
                  End;
                SP_NUMVAR, SP_STRVAR:
                  Begin
                    Inc(Position, 1 + (SizeOf(LongWord)*2) + pLongWord(@Tokens[Position +1 + SizeOf(LongWord)])^);
                  End;
                255:
                  Break;
              End;
            End;
            Position := PositionSave;
            Inc(IFCount);
            If HasELSE Then Begin
              Result := CreateToken(SP_DISPLACEMENT, Position, SizeOf(aFloat)) + aFloatToString(0) + Result;
            End;
            If KeyWordID <> 0 Then Begin
              Result := Result + FnResult + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);
              KeyWordID := 0;
            End Else
              Result := Result + FnResult;
          End;
        End Else Begin
          // Can have a line number here (a numeric expression), in accordance with the 1964 Dartmouth Spec.
          FnResult := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.ReturnType = SP_VALUE Then Begin
            Result := Result + FnResult + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_GOTO);
            KeyWordID := 0;
          End Else
            Error.Code := SP_ERR_SYNTAX_ERROR;
        End;
      End Else
        Error.Code := SP_ERR_MISSING_THEN;
    End;

End;


Function SP_Convert_ELSE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode; Var StList: aString): aString;
Var
  KeyWordPos: LongWord;
  HasENDIF: Boolean;
  IFCounter, PositionSave, KeyWord, LenSave: Integer;
  Expr: aString;
Begin

  Result := '';
  KeyWordPos := Position - SizeOf(LongWord) -1;
  LenSave := Length(Tokens);
  Tokens := Tokens + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_ELSE);
  If (Byte(Tokens[Position]) = SP_KEYWORD) or (Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR]) or ((Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '?')) Then Begin
    If (Byte(Tokens[Position]) = SP_KEYWORD) Then Begin
      KeyWordID := pLongWord(@Tokens[Position +1])^;
      KeyWordPos := Position;
      Inc(Position, 1 + SizeOf(LongWord));
    End Else Begin
      If Byte(Tokens[Position]) = SP_SYMBOL Then Begin
        KeyWordPos := Position;
        KeyWordID := SP_KW_PRINT;
        Inc(Position, 2);
      End Else Begin
        KeyWordPos := Position;
        KeyWordID := SP_KW_LET;
      End;
    End;
    Result := SP_Convert_KeyWord(Tokens, Position, KeyWordID, Error, StList);
    If Error.Code <> SP_ERR_OK Then Exit;

    // Test for an ELSE or ENDIF

    PositionSave := Position;
    HasENDIF := False;
    IFCounter := 0;
    While Position < Length(Tokens) Do Begin
      Case Byte(Tokens[Position]) of
        SP_STRINGCHAR:
          Inc(Position, SizeOf(aFloat) +1);
        SP_SYMBOL:
          Begin
            Inc(Position, 2);
          End;
        SP_VALUE:
          Begin
            Inc(Position, 1 + SizeOf(aFloat));
          End;
        SP_STRING, SP_LABEL, SP_TEXT, SP_COMMENT:
          Begin
            Inc(Position, 1 + SizeOf(LongWord) + pLongWord(@Tokens[Position +1])^);
          End;
        SP_KEYWORD, SP_FUNCTION:
          Begin
            KeyWord := pLongWord(@Tokens[Position +1])^;
            Case KeyWord Of
              SP_KW_IF:
                Begin
                  Inc(IFCounter);
                End;
              SP_KW_ELSE:
                Begin
                  Dec(IFCounter);
                End;
              SP_KW_ENDIF:
                Begin
                  If IFCounter = 0 Then Begin
                    HasENDIF := True;
                    Break;
                  End Else
                    Dec(IFCounter);
                End;
            End;
            Inc(Position, 1 + SizeOf(LongWord));
          End;
        SP_NUMVAR, SP_STRVAR:
          Begin
            Inc(Position, 1 + (SizeOf(LongWord)*2) + pLongWord(@Tokens[Position +1 + SizeOf(LongWord)])^);
          End;
        255:
          Break;
      End;
    End;
    Position := PositionSave;
    Inc(IFCount);
    If HasENDIF Then Begin
      Tokens := Copy(Tokens, 1, LenSave);
      Result := CreateToken(SP_DISPLACEMENT, Position, SizeOf(aFloat)) + aFloatToString(0) +
                CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_ELSE) +
                Result;
      If KeyWordID <> 0 Then Result := Result + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);
      KeyWordID := 0;
    End;
  End Else Begin
    // Can have a line number here (a numeric expression), in accordance with the 1964 Dartmouth Spec.
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.ReturnType = SP_VALUE Then Begin
      Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_GOTO);
      KeyWordID := 0;
    End Else
      Error.Code := SP_ERR_SYNTAX_ERROR;
  End;

End;
}
Function SP_Convert_ENDIF: aString;
Begin

  // ENDIF - takes no parameters, ignored by interpreter.

  Result := '';

End;

Function SP_Convert_Embedded_Colours(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  KeyWordID: LongWord;
  InkPos: Integer;
  Expr: aString;
Begin
  If DoingRepeatParams Then
    Result := ''
  Else
    Result := CreateToken(SP_RESTORECOLOURS, 0, 0);
  While True Do Begin
    If Ord(Tokens[Position]) = SP_KEYWORD Then Begin
      If (pLongWord(@Tokens[Position +1])^ = SP_KW_INK) or (pLongWord(@Tokens[Position +1])^ = SP_KW_OVER) or
         (pLongWord(@Tokens[Position +1])^ = SP_KW_PAPER) or (pLongWord(@Tokens[Position +1])^ = SP_KW_INVERSE) or
         (pLongWord(@Tokens[Position +1])^ = SP_KW_CLIP) or (pLongWord(@Tokens[Position +1])^ = SP_KW_TRANS) or
         (pLongWord(@Tokens[Position +1])^ = SP_KW_TRANSPARENT) Then Begin
        KeyWordID := pLongWord(@Tokens[Position +1])^;
        If KeyWordID = SP_KW_TRANS Then KeyWordID := SP_KW_TRANSPARENT;
        InkPos := Position;
        Inc(Position, 1+SizeOf(LongWord));
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
        If Error.Code <> SP_ERR_OK Then Exit;
        If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        If KeyWordID = SP_KW_CLIP Then Begin
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Expr := Expr + SP_Convert_Expr(Tokens, Position, Error, -1); // y1, already picked up x1
            If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
              Inc(Position, 1 + SizeOf(LongWord));
              Expr := Expr + SP_Convert_Expr(Tokens, Position, Error, -1); // x2
              If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Expr := Expr + SP_Convert_Expr(Tokens, Position, Error, -1); // y2
                If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
              End Else Begin
                Error.Code := SP_ERR_MISSING_COMMA;
                Exit;
              End;
            End Else Begin
              Error.Code := SP_ERR_SYNTAX_ERROR;
              Exit;
            End;
          End Else Begin
            Error.Code := SP_ERR_MISSING_COMMA;
            Exit;
          End;
        End;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ';') Then Begin
          Inc(Position, 2);
          Case KeyWordID of
            SP_KW_INK:
              KeyWordID := SP_KW_PR_INK;
            SP_KW_PAPER:
              KeyWordID := SP_KW_PR_PAPER;
            SP_KW_INVERSE:
              KeyWordID := SP_KW_PR_INVERSE;
            SP_KW_OVER:
              KeyWordID := SP_KW_PR_OVER;
            SP_KW_CLIP:
              KeyWordID := SP_KW_PR_CLIP;
            SP_KW_TRANS:
              KeyWordID := SP_KW_PR_TRANSPARENT;
          End;
          Result := Result + Expr + CreateToken(SP_KEYWORD, InkPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);
        End Else Begin
          Error.Code := SP_ERR_ILLEGAL_CHAR;
          Exit;
        End;
      End Else
        Exit;
    End Else
      Exit;
  End;
End;

Procedure SP_AlphaCheck(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer);
Begin

  CanNewStatement := False;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ALPHA) Then Begin

    Case KeyWordID Of

      SP_KW_CIRCLE: KeyWordID := SP_KW_ACIRCLE;
      SP_KW_PLOT: KeyWordID := SP_KW_APLOT;
      SP_KW_DRAW: KeyWordID := SP_KW_ADRAW;
      SP_KW_ELLIPSE: KeyWordID := SP_KW_AELLIPSE;
      SP_KW_CURVE: KeyWordID := SP_KW_ACURVE;
      SP_KW_FILL: KeyWordID := SP_KW_AFILL;
      SP_KW_RECTANGLE: KeyWordID := SP_KW_ARECTANGLE;
      SP_KW_POLYGON: KeyWordID := SP_KW_APOLYGON;
      SP_KW_MULTIPLOT: KeyWordID := SP_KW_AMULTIPLOT;
      SP_KW_PRINT: KeyWordID := SP_KW_APRINT;
      SP_KW_TEXT: KeyWordID := SP_KW_ATEXT;

    End;

    Inc(Position, SizeOf(LongWord) +1);

  End Else Begin

    Case KeyWordID Of

      SP_KW_ACIRCLE: KeyWordID := SP_KW_CIRCLE;
      SP_KW_APLOT: KeyWordID := SP_KW_PLOT;
      SP_KW_ADRAW: KeyWordID := SP_KW_DRAW;
      SP_KW_AELLIPSE: KeyWordID := SP_KW_ELLIPSE;
      SP_KW_ACURVE: KeyWordID := SP_KW_CURVE;
      SP_KW_AFILL: KeyWordID := SP_KW_FILL;
      SP_KW_ARECTANGLE: KeyWordID := SP_KW_RECTANGLE;
      SP_KW_APOLYGON: KeyWordID := SP_KW_POLYGON;
      SP_KW_AMULTIPLOT: KeyWordID := SP_KW_MULTIPLOT;
      SP_KW_APRINT: KeyWordID := SP_KW_PRINT;
      SP_KW_ATEXT: KeyWordID := SP_KW_TEXT;

    End;

  End;

End;

Function SP_Convert_PARTICLE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr, FrExpr, GrExpr: aString;
  VarPos, VarSize: Integer;
  VarType: aChar;
  VarName: aString;
  Done: Boolean;
Begin

  // PARTICLE array() [FRICTION f [GRAVITY gd,gm]]

  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
      Inc(Position, 4);
      Done := False;
      Expr := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
      FrExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
      GrExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0) + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);
      While Not Done Do Begin
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FRICTION) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          FrExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit;
          If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
        End Else
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAVITY) Then Begin
            Inc(Position, 1 + SizeOf(LongWord));
            GrExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then Exit;
            If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              GrExpr := SP_Convert_Expr(Tokens, Position, Error, -1) + GrExpr;
              If Error.Code <> SP_ERR_OK Then Exit;
              If Error.ReturnType <> SP_VALUE Then Begin
               Error.Code := SP_ERR_MISSING_NUMEXPR;
               Exit;
              End;
            End Else Begin
              Error.Code := SP_ERR_SYNTAX_ERROR;
              Exit;
            End;
          End Else
            Done := True;
      End;
      Result := grExpr + FrExpr + Expr;
    End Else Begin
      Error.Code := SP_ERR_SYNTAX_ERROR;
      Exit;
    End;
  End Else Begin
    Error.Code := SP_ERR_INVALID_ARRAY_VAR;
  End;

End;

Function SP_Convert_FORCE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
  VarPos, VarSize: Integer;
  VarType: aChar;
  VarName: aString;
Begin

  // FORCE array(),fd,fm

  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
      Inc(Position, 4);
      Expr := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr;
        If Error.Code <> SP_ERR_OK Then Exit;
        If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr;
          If Error.Code <> SP_ERR_OK Then Exit;
          If Error.ReturnType <> SP_VALUE Then Begin
           Error.Code := SP_ERR_MISSING_NUMEXPR;
           Exit;
          End;
          Result := Expr;
        End Else Begin
          Error.Code := SP_ERR_SYNTAX_ERROR;
          Exit;
        End;
      End Else Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End;
    End Else Begin
      Error.Code := SP_ERR_SYNTAX_ERROR;
      Exit;
    End;
  End Else Begin
    Error.Code := SP_ERR_INVALID_ARRAY_VAR;
  End;

End;

Function SP_Convert_PLOT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
  VarPos, VarSize: Integer;
  VarType: aChar;
  VarName: aString;
Label
  NotVar;
Begin

  // PLOT [INK|OVER numexpr;]{numxpr,numexpr|array()};

  Result := '';

  SP_AlphaCheck(KeyWordID, Tokens, Position);
  Result := Result + SP_Convert_Embedded_Colours(Tokens, Position, Error);
  If Error.Code <> SP_ERR_OK Then Exit;

  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
       Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
       Inc(Position, 4);
    End Else Begin
      Position := VarPos;
      GoTo NotVar;
    End;
  End Else Begin
    NotVar:
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Result := Result + Expr;
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then Exit;
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      Result := Result + Expr;
    End;
  End;

End;

Function SP_Convert_PAUSE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // PAUSE numexpr

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK then Exit;
  If Error.ReturnType <> SP_VALUE Then Error.Code := SP_ERR_MISSING_NUMEXPR;

End;

Function SP_Convert_DRAW(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarPos, VarSize: Integer;
  VarName: aString;
  Expr: aString;
  AllResult: aString;
  VarType: aChar;
Label
  NotVar;
Begin

  // DRAW [INK|OVER numexpr;][ TO ]x[,y[,a]]
  // DRAW [INK|OVER numexpr;] [TO] Array()
  // DRAW [INK|OVER numexpr;] x1,y1 TO x2,y2
  // DRAW [INK|OVER numexpr;] x1,y1,x2,y2[,a]
  // DRAW [INK|OVER numexpr;] strexpr$

  Result := '';
  AllResult := '';

  SP_AlphaCheck(KeyWordID, Tokens, Position);

  Result := SP_Convert_Embedded_Colours(Tokens, Position, Error) + Result;
  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
    If KeyWordID = SP_KW_DRAW Then
      KeyWordID := SP_KW_DRAWTO
    Else
      KeyWordID := SP_KW_ADRAWTO;
    Inc(Position, 1 + SizeOf(LongWord));
  End;

  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
      Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
      Inc(Position, 4);
      Case KeyWordID Of
        SP_KW_DRAW:     KeyWordID := SP_KW_MULTIDRAW;
        SP_KW_DRAWTO:   KeyWordID := SP_KW_MULTIDRAW_TO;
        SP_KW_ADRAW:    KeyWordID := SP_KW_AMULTIDRAW;
        SP_KW_ADRAWTO:  KeyWordID := SP_KW_AMULTIDRAW_TO;
      End;
      Result := Result + AllResult;
      Exit;
    End Else Begin
      Position := VarPos;
      GoTo NotVar;
    End;
  End Else Begin
    NotVar:
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // x or styexpr
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      If (Error.ReturnType = SP_STRING) And ((KeyWordID = SP_KW_DRAW) or (KeyWordID = SP_KW_ADRAW)) Then
      Begin
        Result := Result + Expr;
        KeyWordID := SP_KW_DRAW_GW;
        Exit;
      End Else Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
    End;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Result := Result + Expr;
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // y
      If Error.Code <> SP_ERR_OK Then Exit;
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      Result := Result + Expr;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // angle
        If Error.Code <> SP_ERR_OK Then Exit;
        If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        Result := Result + Expr + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(3);
      End Else
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) And ((KeyWordID = SP_KW_DRAW) Or (KeyWordID = SP_KW_ADRAW)) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          // Got x,y TO - now expecting x,y[,a]
          If KeyWordID = SP_KW_DRAW Then
            KeyWordID := SP_KW_DRAW_CTO
          Else
            KeyWordID := SP_KW_ADRAW_CTO;
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // x
          If Error.Code <> SP_ERR_OK Then Exit;
          If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Result := Result + Expr;
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // y
            If Error.Code <> SP_ERR_OK Then Exit;
            If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            Result := Result + Expr;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // angle
              If Error.Code <> SP_ERR_OK Then Exit;
              If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              Result := Result + Expr + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(3);
            End Else
              Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(2);
          End Else Begin
            Error.Code := SP_ERR_MISSING_COMMA;
            Exit;
          End;
        End Else
          Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(2);
      Result := Result + AllResult;
      Exit;
    End Else
      If (KeyWordID = SP_KW_DRAW) or (KeyWordID = SP_KW_ADRAW) Then Begin
        Result := Result + Expr;
        If KeyWordID = SP_KW_ADRAW Then
          KeyWordID := SP_KW_ADRAWTURTLE
        Else
          KeyWordID := SP_KW_DRAWTURTLE;
        Result := Result + AllResult;
        Exit;
      End;
  End;

End;

Function  SP_Convert_CIRCLE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
Begin

  // CIRCLE [INK|OVER numexpr;]x,y,r[FILL {fill$|GRAPHIC n}]

  SP_AlphaCheck(KeyWordID, Tokens, Position);

  Result := SP_Convert_Embedded_Colours(Tokens, Position, Error);
  If Error.Code <> SP_ERR_OK Then Exit;

  Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then Exit;
  If Error.ReturnType <> SP_VALUE Then Begin
    Error.Code := SP_ERR_MISSING_NUMEXPR;
    Exit;
  End;
  Result := Result + Expr;
  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
    Inc(Position, 2);
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    Result := Result + Expr;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then Exit;
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      Result := Result + Expr;
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FILL) Then Begin
        Inc(Position, SizeOf(LongWord)+1);
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Graphic ID
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
        End Else Begin
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // strexpr | GRAPHIC gfx-id | Nothing
          If Error.Code <> SP_ERR_OK Then
            Exit
          Else Begin
            If Error.ReturnType <> SP_STRING Then Begin
              If Expr = '' Then
                Expr := CreateToken(SP_STRING, 0, 0)
              Else Begin
                Error.Code := SP_ERR_MISSING_STREXPR;
                Exit;
              End;
            End;
          End;
        End;
        Result := Result + Expr;
        If KeyWordID = SP_KW_ACIRCLE Then
          KeyWordID := SP_KW_ACIRCLEFILL
        Else
          KeyWordID := SP_KW_CIRCLEFILL;
      End;
      Exit;
    End Else
      Error.Code := SP_ERR_ILLEGAL_CHAR;
  End Else
    Error.Code := SP_ERR_ILLEGAL_CHAR;

End;

Function SP_Convert_ELLIPSE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
Begin

  // ELLIPSE [INK numexpr;]x,y,rx,ry[FILL {fill$|GRAPHIC n}]

  SP_AlphaCheck(KeyWordID, Tokens, Position);

  Result := SP_Convert_Embedded_Colours(Tokens, Position, Error);
  If Error.Code <> SP_ERR_OK Then Exit;

  Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then Exit;
  If Error.ReturnType <> SP_VALUE Then Begin
    Error.Code := SP_ERR_MISSING_NUMEXPR;
    Exit;
  End;
  Result := Result + Expr;
  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
    Inc(Position, 2);
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    Result := Result + Expr;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then Exit;
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      Result := Result + Expr;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
        If Error.Code <> SP_ERR_OK Then Exit;
        If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        Result := Result + Expr;
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FILL) Then Begin
          Inc(Position, SizeOf(LongWord)+1);
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
            Inc(Position, 1 + SizeOf(LongWord));
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Graphic ID
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
          End Else Begin
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // strexpr
            If Error.Code <> SP_ERR_OK Then
              Exit
            Else Begin
              If Error.ReturnType <> SP_STRING Then Begin
                If Expr = '' Then
                  Expr := CreateToken(SP_STRING, 0, 0)
                Else Begin
                  Error.Code := SP_ERR_MISSING_STREXPR;
                  Exit;
                End;
              End;
            End;
          End;
          Result := Result + Expr;
          If KeyWordID = SP_KW_AELLIPSE Then
            KeyWordID := SP_KW_AELLIPSEFILL
          Else
            KeyWordID := SP_KW_ELLIPSEFILL;
        End;
        Exit;
      End Else
        Error.Code := SP_ERR_ILLEGAL_CHAR;
    End Else
      Error.Code := SP_ERR_ILLEGAL_CHAR;
  End Else
    Error.Code := SP_ERR_ILLEGAL_CHAR;

End;

Function SP_Convert_CURVE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
Begin

  // CURVE [INK|OVER numexpr;]x1,y1 TO x2,y2[,x3 TO y3,]n

  SP_AlphaCheck(KeyWordID, Tokens, Position);

  Result := SP_Convert_Embedded_Colours(Tokens, Position, Error);
  If Error.Code <> SP_ERR_OK Then Exit;

  Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then Exit;
  If Error.ReturnType <> SP_VALUE Then Begin
    Error.Code := SP_ERR_MISSING_NUMEXPR;
    Exit;
  End;
  Result := Result + Expr;
  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
    Inc(Position, 2);
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    Result := Result + Expr;
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then Exit;
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      Result := Result + Expr;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
        If Error.Code <> SP_ERR_OK Then Exit;
        If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        Result := Result + Expr;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit;
          If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          Result := Result + Expr;
          Exit;
        End Else
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
            Inc(Position, 1 + SizeOf(LongWord));
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then Exit;
            If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            Result := Result + Expr;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
              If Error.Code <> SP_ERR_OK Then Exit;
              If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              Result := Result + Expr;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code <> SP_ERR_OK Then Exit;
                If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                Result := Result + Expr;
                Case KeyWordID of
                  SP_KW_CURVE: KeyWordID := SP_KW_CURVE_EX;
                  SP_KW_ACURVE: KeyWordID := SP_KW_ACURVE_EX;
                End;
                Exit;
              End Else
                Error.Code := SP_ERR_ILLEGAL_CHAR;
            End Else
              Error.Code := SP_ERR_ILLEGAL_CHAR;
          End Else
            Error.Code := SP_ERR_ILLEGAL_CHAR;
      End Else
        Error.Code := SP_ERR_ILLEGAL_CHAR;
    End Else
      Error.Code := SP_ERR_ILLEGAL_CHAR;
  End Else
    Error.Code := SP_ERR_ILLEGAL_CHAR;

End;

Function SP_Convert_RANDOMIZE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // RANDOMIZE [seed]

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);

  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Result <> '' Then
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;

End;

Function SP_Convert_SAVE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarType, VarPos, VarIdx, VarSize: Integer;
  VarName: aString;
Begin

  // SAVE strexpr [[ASCII] LINE numexpr|BANK numexpr [DATA]|PALETTE|DATA var/array|SCREEN$|GRAPHIC numexpr]

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);

  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Error.ReturnType <> SP_STRING Then Begin
      Error.Code := SP_ERR_MISSING_STREXPR;
      Exit;
    End Else
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_LINE) Then Begin
        Inc(Position, 1+SizeOf(LongWord));
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
        If Error.Code <> SP_ERR_OK Then
          Exit
        Else
          If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
      End Else
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ASCII) Then Begin
          Inc(Position, 1+SizeOf(LongWord));
          KeyWordID := SP_KW_SAVEASCII;
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_LINE) Then Begin
            Inc(Position, 1+SizeOf(LongWord));
            Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
            If Error.Code <> SP_ERR_OK Then
              Exit
            Else
              If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
          End;
        End Else
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_BANK) Then Begin
            Inc(Position, 1+SizeOf(LongWord));
            Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
            If Error.Code <> SP_ERR_OK Then
              Exit
            Else
              If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End Else
                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_DATA) Then Begin
                  Inc(Position, 1 + SizeOf(LongWord));
                  KeyWordID := SP_KW_SAVE_BANK_DATA
                End Else
                  KeyWordID := SP_KW_SAVE_BANK;
          End Else
            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_PALETTE) Then Begin
              KeyWordID := SP_KW_PAL_SAVE;
              Inc(Position, SizeOf(LongWord) +1);
            End Else
              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_DATA) Then Begin
                KeyWordID := SP_KW_DATA_SAVE;
                Inc(Position, SizeOf(LongWord) +1);
                If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
                  VarType := Byte(Tokens[Position]);
                  Inc(Position);
                  VarPos := Position;
                  VarIdx := pLongWord(@Tokens[Position])^;
                  Inc(Position, SizeOf(LongWord));
                  VarSize := pLongWord(@Tokens[Position])^;
                  Inc(Position, SizeOf(LongWord));
                  VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
                  Inc(Position, VarSize);
                  Result := CreateToken(VarType, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName + Result;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                      Inc(Position, 2);
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
                        Inc(Position, 2);
                        Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1) + Result;
                      End Else
                        Error.Code := SP_ERR_SYNTAX_ERROR;
                  End Else
                    Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0) + Result;
                End Else
                  Error.Code := SP_ERR_MISSING_VARIABLE;
              End Else
                If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_SCREENS) Then Begin
                  Inc(Position, SizeOf(Longword)+1);
                  KeyWordID := SP_KW_SCREEN_SAVE;
                End Else
                  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
                    Inc(Position, 1+SizeOf(LongWord));
                    Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End Else
                        KeyWordID := SP_KW_GRAPHIC_SAVE;
                  End;
End;

Function  SP_Convert_LOAD(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
  KeyWordPos: LongWord;
  VarType, VarPos, VarIdx, VarSize: Integer;
  VarName, VarResult: aString;
Begin

  // LOAD strexpr [BANK [{NEW numvar|n}]|PALETTE|DATA [var[()]]

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code = SP_ERR_OK Then
    If Error.ReturnType <> SP_STRING Then Begin
      Error.Code := SP_ERR_MISSING_STREXPR;
      Exit;
    End;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_BANK) Then Begin
    KeyWordID := SP_KW_LOAD_BANK;
    Inc(Position, 1+SizeOf(LongWord));
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_NEW) Then Begin
      KeyWordID := SP_KW_NEW_BANK;
      Inc(Position, 1 + SizeOf(LongWord));
      If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
        VarResult := SP_Convert_Var_Assign(Tokens, Position, Error); // BankID
        If Error.Code <> SP_ERR_OK Then Exit;
        KeyWordPos := Position -1;
        Result := Result + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID)+ VarResult;
        If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
        Exit;
      End Else
        Error.Code := SP_ERR_MISSING_VARIABLE;
    End Else Begin
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then
        Exit
      Else
        If Expr <> '' Then
          If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End Else
            Result := Expr + Result;
    End;
  End Else
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_PALETTE) Then Begin
      KeyWordID := SP_KW_PAL_LOAD;
      Inc(Position, SizeOf(LongWord) +1);
    End Else
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_DATA) Then Begin
        KeyWordID := SP_KW_DATA_LOAD;
        Inc(Position, SizeOf(LongWord) +1);
        If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
          VarType := Byte(Tokens[Position]);
          Inc(Position);
          VarPos := Position;
          VarIdx := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
          VarSize := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
          VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
          Inc(Position, VarSize);
          Result := CreateToken(VarType, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName + Result;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then
            Inc(Position, 4);
        End Else
          Result := CreateToken(SP_NUMVAR, 0, SizeOf(LongWord)) + LongWordToString(0) + Result;
      End;


End;

Function  SP_Convert_MERGE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // MERGE strexpr
  // MERGE start TO finish

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);

  If Error.Code = SP_ERR_OK Then
    If Error.ReturnType <> SP_STRING Then
      If Error.ReturnType = SP_VALUE Then Begin
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
          Inc(Position, 1 + SizeOf(longWord));
          Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
          If Error.Code <> SP_ERR_OK Then
            Exit
          Else
            If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End Else
              KeyWordID := SP_KW_MERGE_LINES;
        End;
      End Else
        Error.Code := SP_ERR_MISSING_STREXPR;

End;

Function  SP_Convert_INC(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarExpr, IncExpr, StartExpr, FinishExpr: aString;
  Token: pToken;
Begin

  // INC var[,amount][,start TO finish]

  Result := '';
  VarExpr := '';
  IncExpr := '';

  StartExpr := '';
  FinishExpr := '';

  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
    VarExpr := SP_Convert_Var_Assign(Tokens, Position, Error);
    If Error.Code = SP_ERR_OK Then Begin
      Token := @VarExpr[1];
      If Token^.Token = SP_NUMVAR_LET Then Token^.Token := SP_NUMVAR;
      If Error.Code <> SP_ERR_OK Then Exit;
      If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position+1] = ',') Then Begin
        Inc(Position, 2);
        IncExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
          StartExpr := IncExpr;
          IncExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
          Inc(Position, 1 + SizeOf(LongWord));
          FinishExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
          Result := VarExpr + FinishExpr + StartExpr + IncExpr;
          KeyWordID := SP_KW_INCRANGE;
        End Else
          If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position+1] = ',') Then Begin
            Inc(Position, 2);
            StartExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
              Inc(Position, 1 + SizeOf(LongWord));
              FinishExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
              Result := VarExpr + FinishExpr + StartExpr + IncExpr;
              KeyWordID := SP_KW_INCRANGE;
            End Else
              Error.Code := SP_ERR_MISSING_TO;
          End Else
            Result := VarExpr + IncExpr;
      End Else
        Result := VarExpr;
    End;
  End Else
    Error.Code := SP_ERR_MISSING_VARIABLE;

End;

Function  SP_Convert_DEC(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarExpr, DecExpr, StartExpr, FinishExpr: aString;
  Token: pToken;
Begin

  // DEC var[,amount][,start TO finish]

  Result := '';
  VarExpr := '';
  DecExpr := '';
  StartExpr := '';
  FinishExpr := '';

  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
    VarExpr := SP_Convert_Var_Assign(Tokens, Position, Error);
    If Error.Code = SP_ERR_OK Then Begin
      Token := @VarExpr[1];
      If Token^.Token = SP_NUMVAR_LET Then Token^.Token := SP_NUMVAR;
      If Error.Code <> SP_ERR_OK Then Exit;
      If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position+1] = ',') Then Begin
        Inc(Position, 2);
        DecExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
          StartExpr := DecExpr;
          DecExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
          Inc(Position, 1 + SizeOf(LongWord));
          FinishExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
          Result := VarExpr + FinishExpr + StartExpr + DecExpr;
          KeyWordID := SP_KW_DECRANGE;
        End Else
          If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position+1] = ',') Then Begin
            Inc(Position, 2);
            StartExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
              Inc(Position, 1 + SizeOf(LongWord));
              FinishExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
              Result := VarExpr + FinishExpr + StartExpr + DecExpr;
              KeyWordID := SP_KW_DECRANGE;
            End Else
              Error.Code := SP_ERR_MISSING_TO;
          End Else
            Result := VarExpr + DecExpr;
      End Else
        Result := VarExpr;
    End;
  End Else
    Error.Code := SP_ERR_MISSING_VARIABLE;

End;

Function  SP_Convert_SWAP(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarExpr1, VarExpr2, Expr1, Expr2: aString;
  ExprType1, ExprType2: Integer;
  OldPos: Integer;
Begin
  OldPos := Position;
  Expr1 := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    ExprType1 := Error.ReturnType;
  If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position+1] = ',') Then Begin
    Inc(Position, 2);
    Expr2 := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then
      Exit
    Else
      ExprType2 := Error.ReturnType;
    If ExprType1 <> ExprType2 Then Begin
      Error.Code := SP_ERR_MIXED_TYPES;
      Exit;
    End Else Begin
      Position := OldPos;
      VarExpr1 := SP_Convert_Var_Assign(Tokens, Position, Error);
      If Not (pToken(@VarExpr1[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET]) Then
        VarExpr1 := VarExpr1 + CreateToken(SP_KEYWORD, Position, SizeOf(LongWord)) + LongWordToString(SP_KW_LET);
      Inc(Position, 2);
      VarExpr2 := SP_Convert_Var_Assign(Tokens, Position, Error);
      Result := Expr1 + Expr2 + VarExpr1 + VarExpr2;
      If pToken(@VarExpr1[2])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
    End;
  End;
End;

Function  SP_Convert_PALETTE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
  Token: aChar;
  SrcGfx, DstGfx: Integer;
  GotDest: Boolean;
Begin

  // PALETTE <SHL|SHR n, n TO n>|<<HSV>index,<r,g,b|RGB>|<DEFAULT|EGA|CGA|APPLEHGR|APPLELGR|CPC>>
  // PALETTE COPY <[GRAPHIC|WINDOW]> id,start,count TO [WINDOW|GRAPHIC] id, index

  Result := '';

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_COPY) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    SrcGfx := 1;
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_WINDOW) Then Begin
      SrcGfx := -1;
      Inc(Position, 1 + SizeOf(LongWord));
    End;
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      If (SrcGfx = -1) Then Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End;
    End;

    Result := SP_Convert_Expr(Tokens, Position, Error, -1); // SourceID (make negative for a WINDOW)
    If SrcGfx = -1 Then
      Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(-1) + CreateToken(SP_SYMBOL, 0, 1) + '*';
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Start
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Count
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          DstGfx := 1;
          GotDest := False;
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_WINDOW) Then Begin
            DstGfx := -1;
            GotDest := True;
            Inc(Position, 1 + SizeOf(LongWord));
          End;
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then
            If DstGfx = -1 Then Begin
              Error.Code := SP_ERR_SYNTAX_ERROR;
              Exit;
            End Else Begin
              GotDest := True;
              Inc(Position, 1 + SizeOf(LongWord));
          End;
          Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(Ord(GotDest)) + Result;
          If GotDest Then Begin
            Result := SP_Convert_Expr(Tokens, Position, Error, -1) + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(DstGfx) + CreateToken(SP_SYMBOL, 0, 1) + '*' + Result;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
              Inc(Position, 2)
            Else Begin
              Error.Code := SP_ERR_MISSING_COMMA;
              Exit;
            End;
          End;
          Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Destination index
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
          KeyWordID := SP_KW_PAL_COPY;
          Exit;
        End Else Begin
          Error.Code := SP_ERR_MISSING_TO;
          Exit;
        End;
      End Else Begin
        Error.Code := SP_ERR_MISSING_COMMA;
        Exit;
      End;
    End Else Begin
      Error.Code := SP_ERR_MISSING_COMMA;
      Exit;
    End;
  End Else Begin
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_DEFAULT) Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      KeyWordID := SP_KW_PAL_DEFAULT;
    End Else
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_EGA) Then Begin
        Inc(Position, 1 + SizeOf(LongWord));
        KeyWordID := SP_KW_PAL_EGA;
      End Else
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CGA) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          KeyWordID := SP_KW_PAL_CGA;
        End Else
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_APPLELGR) Then Begin
            Inc(Position, 1 + SizeOf(LongWord));
            KeyWordID := SP_KW_PAL_APPLELGR;
          End Else
            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_APPLEHGR) Then Begin
              Inc(Position, 1 + SizeOf(LongWord));
              KeyWordID := SP_KW_PAL_APPLEHGR;
            End Else
              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CPC) Then Begin
                Inc(Position, 1 + SizeOf(LongWord));
                KeyWordID := SP_KW_PAL_CPC;
              End Else Begin
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] in [SP_CHAR_SHL, SP_CHAR_SHR]) Then Begin
                  KeyWordID := SP_KW_PALSHIFT;
                  Token := Tokens[Position +1];
                  Inc(Position, 2);
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Amount to move
                  If Error.Code <> SP_ERR_OK Then Exit;
                  If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  If Token = SP_CHAR_SHL Then
                    Result := Result + Expr + CreateToken(SP_SPECIAL_SYMBOL, Position, 1) + SP_CHAR_UNARYM // Shifts left are negative
                  Else
                    Result := Result + Expr;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Shift FROM
                    If Error.Code <> SP_ERR_OK Then Exit;
                    If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                    Result := Result + Expr;
                    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
                      Inc(Position, 1 + SizeOf(LongWord));
                      Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Shift TO
                      If Error.Code <> SP_ERR_OK Then Exit;
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                      Result := Result + Expr;
                      Exit;
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_TO;
                      Exit;
                    End;
                  End Else
                    Exit;
                End Else
                  If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_HSV) Then Begin
                    KeyWordID := SP_KW_PAL_HSV;
                    Inc(Position, 1 + SizeOf(LongWord));
                  End;
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
                  If Error.Code <> SP_ERR_OK Then Exit;
                  If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  Result := Result + Expr;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Red, H, RGB or HSV
                    If Error.Code <> SP_ERR_OK Then Exit;
                    If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                    Result := Result + Expr;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Green
                      If Error.Code <> SP_ERR_OK Then Exit;
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                      Result := Result + Expr;
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                        Inc(Position, 2);
                        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Blue
                        If Error.Code <> SP_ERR_OK Then Exit;
                        If Error.ReturnType <> SP_VALUE Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Exit;
                        End;
                        Result := Result + Expr;
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_COMMA;
                        Exit;
                      End;
                    End Else
                      Exit;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
              End;
  End;
End;

Function SP_Convert_DO(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  KW: LongWord;
  Expr: aString;
Begin

  // DO [numexpr|WHILE numexpr|UNTIL numexpr]

  // DO is a bit special, and in its DO WHILE form, needs to know where it's gonna jump to if the condition returns
  // false. Only problem is, that line might not be tokenised yet :(

  // So we stack a small string which will contain two values - line/statement - after interpretation.

  Result := '';
  KW := pLongWord(@Tokens[Position +1])^;
  If (Byte(Tokens[Position]) = SP_KEYWORD) And ((KW = SP_KW_WHILE) or (KW = SP_KW_UNTIL))Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then
      Exit
    Else
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
    KeyWordID := SP_KW_WHILE;
    If KW = SP_KW_UNTIL Then
      Expr := Expr + CreateToken(SP_FUNCTION, Position, SizeOf(longWord)) + LongWordToString(SP_FN_NOT);
    Result := Expr + CreateToken(SP_POINTER, 0, SizeOf(LongWord)) + LongWordToString(0)+
                     CreateToken(SP_POINTER, 0, SizeOf(LongWord)) + LongWordToString(0)+
                     CreateToken(SP_POINTER, 0, SizeOf(LongWord)) + LongWordToString(0);

  End Else Begin

    // Optional numexpr for the number of loops to execute

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Expr <> '' Then
      If Error.Code <> SP_ERR_OK Then
        Exit
      Else
        If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_SYNTAX_ERROR;
          Exit;
        End Else Begin
          KeyWordID := SP_KW_DO_COUNT;
          Result := Result + Expr;
        End;

  End;

End;

Function  SP_Convert_LOOP(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  KW: LongWord;
  Expr: aString;
Begin

  // LOOP [UNTIL numexpr|WHILE numexpr]

  // Because LOOP only happens after a DO has been executed, it just unstacks the return address from the GOSUB stack.
  // Thus, no need for the shenanigans we see in the WHILE pre-processor.

  Result := '';

  KW := pLongWord(@Tokens[Position +1])^;
  If (Byte(Tokens[Position]) = SP_KEYWORD) And ((KW = SP_KW_WHILE) or (KW = SP_KW_UNTIL))Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then
      Exit
    Else
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;

    KeyWordID := SP_KW_UNTIL;
    If KW = SP_KW_WHILE Then
      Expr := Expr + CreateToken(SP_FUNCTION, Position, SizeOf(longWord)) + LongWordToString(SP_FN_NOT);
    Result := Expr;

  End;

End;

Function  SP_Convert_DATA(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  FnExpr: aString;
Begin

  // DATA item_1,item_2...item_n

  // DATA Lines cannot be executed at runtime, so we just push a "Skip this statement" token at the front of the
  // converted expression. The actual data items do have to be converted to RPN though, and in the correct order,
  // so they should be pushed to the start of the stack as they are processed, with a DATA separator between them.

  Result := '';

  While True Do Begin

    FnExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit;

    Result := Result + FnExpr + CreateToken(SP_DATA_ITEM, 0, SizeOf(LongWord)) + LongWordToString(0);

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
      Inc(Position, 2)
    Else Begin
      Result := CreateToken(SP_SKIP_DATA, 0, SizeOf(LongWord)) + LongWordToString(Length(Result) + SizeOf(TToken) + SizeOf(LongWord)) + Result;
      Exit;
    End;

  End;

End;

Function SP_Convert_READ(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Idx, VarType, VarPos, VarIdx, VarSize, NumIndices, KeyWordPos, TokenNameLen, lPos: LongWord;
  VarName, FnResult, VarResult, TempResult, TokenName: aString;
  SlicerFlags, Token: Byte;
  LineFlag: Boolean;
  Tkn: pToken;
Begin

  // READ [LINE] var1[,var2...]

  lPos := 0;
  KeyWordPos := Position -1;
  Result := '';

  While True Do Begin

    LineFlag := False;
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_LINE) Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      LineFlag := True;
    End;

    VarType := Byte(Tokens[Position]);

    If Not (VarType in [SP_NUMVAR, SP_STRVAR]) Then Begin
      Error.Code := SP_ERR_MISSING_VAR;
      Exit;
    End Else
      If LineFlag And (VarType = SP_NUMVAR) Then Begin
        Error.Code := SP_ERR_LINE_WITHOUT_STR;
        Exit;
      End;

    Inc(Position);
    VarPos := Position;
    VarIdx := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);

    // Test for an array here.

    NumIndices := 0;
    SlicerFlags := 0;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin

      Inc(Position, 2);
      FnResult := SP_ExtractArray(Tokens, Position, False, Error);
      If FnResult = '' Then Error.Code := SP_ERR_MISSING_NUMEXPR;
      If Error.Code <> SP_ERR_OK Then Exit;

      // Remove the last token (should be SP_ARRAY or SP_SLICER) from the pre-processed result,
      // but store the info for later.

      Idx := 1;
      While Idx <= LongWord(Length(FnResult)) Do Begin
        Tkn := @FnResult[Idx];
        If tkn^.Token in [SP_ARRAY, SP_NUM_ARRAY_PTR] Then Begin
          NumIndices := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
          FnResult := Copy(FnResult, 1, Idx -1) + Copy(FnResult, Idx + SizeOf(TToken) + SizeOf(LongWord), Length(FnResult));
        End Else
          If Byte(FnResult[Idx]) = SP_SLICER Then Begin
            SlicerFlags := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
            FnResult := Copy(FnResult, 1, Idx -1) + Copy(FnResult, Idx + SizeOf(TToken) + SizeOf(LongWord), Length(FnResult));
          End Else
            If Byte(FnResult[Idx]) = SP_SLICE_ASSIGN Then Begin
              SlicerFlags := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
              NumIndices := pLongWord(@FnResult[Idx + SizeOf(TToken) + SizeOf(LongWord)])^;
              FnResult := Copy(FnResult, 1, Idx -1) + Copy(FnResult, Idx + SizeOf(TToken) + (SizeOf(LongWord) * 2), Length(FnResult));
            End Else
              Inc(Idx, SizeOf(TToken) + Tkn.TokenLen);
      End;

    End Else
      FnResult := '';

    If LineFlag Then
      VarResult := CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_READLINE)
    Else
      VarResult := CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_READ);

    Case VarType Of

      SP_NUMVAR:
        Begin

          Error.ReturnType := SP_NUMVAR;
          lPos := Length(VarResult) +1;
          VarResult := VarResult + CreateToken(SP_NUMVAR_LET_VALID, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName;
          If FnResult <> '' Then
            If SlicerFlags <> 0 Then Begin
              Error.Code := SP_ERR_SUBSCRIPT_WRONG;
              Exit;
            End Else Begin
              Error.ReturnType := SP_ARRAY_ASSIGN;
              Tkn := @VarResult[lPos];
              Tkn^.Token := SP_NUMVAR;
              lPos := 1;
              VarResult := VarResult + FnResult + CreateToken(SP_ARRAY_ASSIGN, Position, 1 + SizeOf(LongWord)) + aChar(SlicerFlags) + LongWordToString(NumIndices);
            End;
        End;

      SP_STRVAR:
        Begin

          // String vars can have structure elements assigned to them, so test for that and insert the necessary tokens. Change the returntype if necessary
          // to allow commands like WINDOW NEW <var> to work. This is all a bit of a hack, I'm afraid, with duplicated code a couple of times. But what the hell,
          // it works and doesn't need to be fast.

          Token := Byte(Tokens[Position]);
          If Token in [SP_STRUCT_MEMBER_N, SP_STRUCT_MEMBER_S] Then Begin
            Inc(Position);
            TokenNameLen := pLongWord(@Tokens[Position])^;
            Inc(Position, SizeOf(LongWord));
            TokenName := LowerNoSpaces(Copy(Tokens, Position, TokenNameLen));
            Inc(Position, TokenNameLen);
            If Token = SP_STRUCT_MEMBER_N Then
              Error.ReturnType := SP_NUMVAR
            Else
              Error.ReturnType := SP_STRVAR;
            TempResult := CreateToken(SP_STRVARPTR, Position, SizeOf(longWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName;
            TempResult := CreateToken(SP_STRUCT_MEMBER_ASS, Position, Length(TokenName)) + TokenName + TempResult;
            If FnResult <> '' Then Begin
              Error.ReturnType := SP_SLICE_ASSIGN;
              TempResult := CreateToken(SP_STRVAR, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName;
              TempResult := CreateToken(SP_STRUCT_MEMBER_ASS, Position, Length(TokenName)) + TokenName + TempResult;
              TempResult := TempResult + FnResult + CreateToken(SP_SLICE_ASSIGN, Position, 1 + SizeOf(LongWord)) + aChar(SlicerFlags) + LongWordToString(NumIndices);
              // There may be a slicer here - is it?
              FnResult := '';
              If (Error.ReturnType = SP_SLICE_ASSIGN) And (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                Inc(Position, 2);
                FnResult := SP_ExtractArray(Tokens, Position, False, Error);
                If FnResult = '' Then Error.Code := SP_ERR_MISSING_NUMEXPR;
                If Error.Code <> SP_ERR_OK Then Exit;
                Idx := 1;
                While integer(Idx) <= Length(FnResult) Do Begin
                  Tkn := @FnResult[Idx];
                  If Tkn^.Token in [SP_ARRAY, SP_NUM_ARRAY_PTR] Then Begin
                    NumIndices := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
                    FnResult := Copy(FnResult, 1, Idx -1) + Copy(FnResult, Idx + SizeOf(TToken) + SizeOf(LongWord), Length(FnResult));
                  End Else
                    If Tkn^.Token = SP_SLICER Then Begin
                      SlicerFlags := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
                      FnResult := Copy(FnResult, 1, Idx -1) + Copy(FnResult, Idx + SizeOf(TToken) + SizeOf(LongWord), Length(FnResult));
                    End Else Begin
                      Inc(Idx, SizeOf(TToken) + Tkn^.TokenLen);
                    End;
                End;
                If FnResult <> '' Then
                  TempResult := TempResult + FnResult + CreateToken(SP_SLICE_ASSIGN, Position, 1 + SizeOf(LongWord)) + aChar(SlicerFlags) + LongWordToString(NumIndices);
              End;
            End Else Begin
              // Test for a slicer - it's valid here.
              NumIndices := 0;
              SlicerFlags := 0;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                Inc(Position, 2);
                FnResult := SP_ExtractArray(Tokens, Position, False, Error);
                If FnResult = '' Then Error.Code := SP_ERR_MISSING_NUMEXPR;
                If Error.Code <> SP_ERR_OK Then Exit;
                Idx := 1;
                While integer(Idx) <= Length(FnResult) Do Begin
                  Tkn := @FnResult[Idx];
                  If Tkn^.Token in [SP_ARRAY, SP_NUM_ARRAY_PTR] Then Begin
                    NumIndices := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
                    FnResult := Copy(FnResult, 1, Idx -1) + Copy(FnResult, Idx + SizeOf(TToken) + SizeOf(LongWord), Length(FnResult));
                    If NumIndices <> 1 Then Begin
                      // Cannot allow an array here
                      Error.Code := SP_ERR_SUBSCRIPT_WRONG;
                      Exit;
                    End;
                  End Else
                    If Tkn^.Token = SP_SLICER Then Begin
                      SlicerFlags := pLongWord(@FnResult[Idx + SizeOf(TToken)])^;
                      FnResult := Copy(FnResult, 1, Idx -1) + Copy(FnResult, Idx + SizeOf(TToken) + SizeOf(LongWord), Length(FnResult));
                    End Else Begin
                      Inc(Idx, SizeOf(TToken) + Tkn^.TokenLen);
                    End;
                End;
              End;
              If FnResult <> '' Then
                TempResult := TempResult + FnResult + CreateToken(SP_SLICE_ASSIGN, Position, 1 + SizeOf(LongWord)) + aChar(SlicerFlags) + LongWordToString(NumIndices);
            End;
          End Else Begin
            Error.ReturnType := SP_STRVAR;
            TempResult := CreateToken(SP_STRVAR_LET_VALID, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName;
            If FnResult <> '' Then Begin
              Error.ReturnType := SP_SLICE_ASSIGN;
              pToken(@TempResult[1])^.Token := SP_STRVAR;
              TempResult := TempResult + FnResult + CreateToken(SP_SLICE_ASSIGN, Position, 1 + SizeOf(LongWord)) + aChar(SlicerFlags) + LongWordToString(NumIndices) + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_LET);
            End;
          End;
          VarResult := VarResult + TempResult;
          lPos := Length(VarResult) +1;
        End;

    End;

    If (Integer(lPos) <= Length(VarResult)) And Not (pToken(@VarResult[lPos])^.Token in [SP_NUMVAR_LET_VALID, SP_STRVAR_LET_VALID]) Then
      Result := Result + VarResult + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_LET)
    Else
      Result := Result + VarResult;

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
      Inc(Position, 2)
    Else Begin
      KeyWordID := 0;
      Exit;
    End;

  End;

End;

Function SP_Convert_RESTORE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // RESTORE [Linenum|Label]

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);

  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Result <> '' Then Begin
      If Not(Error.ReturnType in [SP_VALUE, SP_LABEL]) Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
    End Else
      Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);

End;

Function SP_Convert_NEW(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // NEW (no params)

  Result := '';

End;

Function SP_Convert_INSTALL(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // INSTALL (no params)

  Result := '';

End;

Function SP_Convert_EXIT(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // EXIT (no params)

  Result := '';

End;

Function SP_Convert_QUIT(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // QUIT (No params)

  Result := '';

End;

Function  SP_Convert_REM(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // REM remark.

  // The entire line is skipped.

  Result := CreateToken(SP_SKIP_LINE, 0, SizeOf(LongWord)) + LongWordToString(0);
  While Tokens[Position] <> #255 Do
    Inc(Position);

End;

Function  SP_Convert_SCREEN(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarResult, Expr: aString;
  KeyWordPos, KeyWord: LongWord;
Begin

  // SCREEN <WINDOW width,Height [SCALE width,Height]|FULL|LOCK|UNLOCK|UPDATE|Width,Height [SCALE width,height]|GRAB var$,x,y,w,h[ TRANSPARENT t]>

  Result := '';

  If Byte(Tokens[Position]) = SP_KEYWORD Then Begin
    Inc(Position);
    Case pLongWord(@Tokens[Position])^ of
      SP_KW_LOCK:   KeyWordID := SP_KW_SCR_LOCK;
      SP_KW_UNLOCK: KeyWordID := SP_KW_SCR_UNLOCK;
      SP_KW_UPDATE: KeyWordID := SP_KW_SCR_UPDATE;
      SP_KW_GRAB:
        Begin
          Inc(Position, SizeOf(LongWord));
          If Byte(Tokens[Position]) = SP_STRVAR Then Begin

            VarResult := SP_Convert_Var_Assign(Tokens, Position, Error);
            If Error.Code <> SP_ERR_OK Then Exit;
            KeyWordPos := Position -(1 + SizeOf(LongWord));

            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // X
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                  Inc(Position, 2);
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // W
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // H
                    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                    If (Byte(Tokens[Position]) = SP_KEYWORD) And ((pLongWord(@Tokens[Position +1])^ = SP_KW_TRANSPARENT) or (pLongWord(@Tokens[Position +1])^ = SP_KW_TRANS)) Then Begin
                      Inc(Position, 1 + SizeOf(LongWord));
                      Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Transparent Index
                      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    End Else
                      Expr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1) + Expr;
                    Result := Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_SCR_GRAB)+ VarResult;
                    If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
                    Exit;
                  End Else
                    Error.Code := SP_ERR_MISSING_COMMA;
                End Else
                  Error.Code := SP_ERR_MISSING_COMMA;
              End Else
                Error.Code := SP_ERR_MISSING_COMMA;
            End Else
              Error.Code := SP_ERR_MISSING_COMMA;
          End Else
            Error.Code := SP_ERR_MISSING_VAR;
        End;
      SP_KW_FULL, SP_KW_WINDOW:
        Begin
          KeyWord := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
          If (Tokens[Position] = #255) or ((Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ':')) Then Begin
            Case KeyWord of
              SP_KW_FULL: KeyWordID := SP_KW_FULLSCREEN;
              SP_KW_WINDOW: KeyWordID := SP_KW_WINDOWED;
            End;
            Exit;
          End Else Begin
            If KeyWord = SP_KW_FULL Then Begin
              Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
            End Else
              If KeyWord = SP_KW_WINDOW Then Begin
                Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);
              End Else Begin
                Error.Code := SP_ERR_SYNTAX_ERROR;
                Exit;
              End;
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then Exit;
            If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Result := Result + Expr;
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
              If Error.Code <> SP_ERR_OK Then Exit;
              If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              Result := Result + Expr;
              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SCALE) Then Begin
                Inc(Position, 1 + SizeOf(Longword));
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code <> SP_ERR_OK Then Exit;
                If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                  Inc(Position, 2);
                  Result := Result + Expr;
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then Exit;
                  If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  Result := Result + Expr;
                End Else Begin
                  Error.Code := SP_ERR_ILLEGAL_CHAR;
                  Exit;
                End;
              End Else Begin
                Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1) +
                                   CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1);
              End;
              KeyWordID := SP_KW_SCR_RES;
              Exit;
            End Else Begin
              Error.Code := SP_ERR_ILLEGAL_CHAR;
              Exit;
            End;
          End;
        End;
    Else
      Error.Code := SP_ERR_SYNTAX_ERROR;
    End;
    Inc(Position, SizeOf(LongWord));
  End Else
    Error.Code := SP_ERR_SYNTAX_ERROR;

End;

Function  SP_Convert_WINDOW(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr, FlipExpr, VarResult, RotateExpr, ScaleExpr, propExpr: aString;
  KeyWordPos: LongWord;
  GotRotate, GotScale, IsGraphic: Boolean;
Begin

  // WINDOW [numexpr|
  //         NEW var,x,y,w,h [TRANSPARENT t] [BPP n [ALPHA]][LOAD filename]|
  //         ERASE <numexpr>|
  //         MERGE {<numexpr>|ALL}|
  //         MOVE <numexpr,>x,y|
  //         SIZE <numexpr,>x,y|
  //         FRONT <numexpr>|
  //         BACK <numexpr>|
  //         SHOW <numexpr>|
  //         HIDE <numexpr>|
  //         GRAB strvar,n,x,y,w,h [TRANSPARENT n]|
  //         PUT {strvar|GRAPHIC n},n,x,y[,ROTATE a][,SCALE n][MIRROR][FLIP]|
  //         SCROLL n,x,y|
  //         ROLL n,x,y|
  //         COPY [GRAPHIC]numexpr,x1,y1,x2,y2 TO numexpr,x3,y3]
  //         ORIGIN numexpr,x1,y1[,w,h| TO x2,y2][FLIP]|OFF
  //         ORIGIN FLIP
  //         CLIP id,x1,y1 TO x2,y2|OFF
  //         TRANSPARENT id{,t|OFF}
  //         ALPHA id ON|OFF
  //         DEPTH id,depth
  //         FLIP id
  //         MIRROR id
  //         id ADDCTRL ctrl-id,ctrl-type <PROP [Property-name$=value$,...]

  Result := '';
  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_NEW) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

      VarResult := SP_Convert_Var_Assign(Tokens, Position, Error);
      If Error.Code <> SP_ERR_OK Then Exit;
      KeyWordPos := Position -1;

      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // X
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // W
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // H
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              If (Byte(Tokens[Position]) = SP_KEYWORD) And ((pLongWord(@Tokens[Position +1])^ = SP_KW_TRANSPARENT) or (pLongWord(@Tokens[Position +1])^ = SP_KW_TRANS)) Then Begin
                Inc(Position, 1 + SizeOf(LongWord));
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Transparent Index
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
              End Else
                Expr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1) + Expr;
              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_BPP) Then Begin
                Inc(Position, 1 + SizeOf(LongWord));
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Bit depth - default 8bpp
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
              End Else
                Expr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(8) + Expr;
              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ALPHA) Then Begin
                Inc(Position, 1 + SizeOf(LongWord));
                Expr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1) + Expr; // Enable per-pixel alpha blending
              End Else
                Expr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0) + Expr;
              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_LOAD) Then Begin
                Inc(Position, 1 + SizeOf(LongWord));
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Filename
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_STRING Then Begin
                  Error.Code := SP_ERR_MISSING_STREXPR;
                  Exit;
                End;
              End Else
                Expr := CreateToken(SP_STRING, Position, 0) + '' + Expr;
              Result := Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_WIN_NEW) + VarResult;
              If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
              Exit;
            End Else
              Error.Code := SP_ERR_MISSING_COMMA;
          End Else
            Error.Code := SP_ERR_MISSING_COMMA;
        End Else
          Error.Code := SP_ERR_MISSING_COMMA;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;
    End Else
      Error.Code := SP_ERR_MISSING_VARIABLE;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_PUT) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));
    KeyWordID := SP_KW_WIN_PUT;
    GotRotate := False;
    GotScale := False;
    ScaleExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
    RotateExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);

    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      VarResult := SP_Convert_Expr(Tokens, Position, Error, -1); // Graphic ID
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
    End Else Begin
      VarResult := SP_Convert_Expr(Tokens, Position, Error, -1); // strexpr | GRAPHIC gfx-id
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_STRING Then Begin
        Error.Code := SP_ERR_MISSING_STREXPR;
        Exit;
      End;
    End;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // N
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // X
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          While True Do Begin
            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ROTATE) Then Begin
              Inc(Position, SizeOf(LongWord) +1);
              RotateExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              GotRotate := True;
            End Else
              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SCALE) Then Begin
                Inc(Position, SizeOf(LongWord) +1);
                ScaleExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                GotScale := True;
              End Else
                Break;
          End;
          If GotScale or GotRotate Then Begin
            Expr := ScaleExpr + RotateExpr + Expr;
            KeyWordID := SP_KW_WIN_PUT_EX;
          End;
          Result := VarResult + Expr;
          Exit;
        End Else
          Error.Code := SP_ERR_MISSING_COMMA;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;
    End Else
      Error.Code := SP_ERR_MISSING_COMMA;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAB) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    If Byte(Tokens[Position]) = SP_STRVAR Then Begin

      VarResult := SP_Convert_Var_Assign(Tokens, Position, Error);
      If Error.Code <> SP_ERR_OK Then Exit;
      KeyWordPos := Position -1;

      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // N
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // X
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // W
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // H
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                If (Byte(Tokens[Position]) = SP_KEYWORD) And ((pLongWord(@Tokens[Position +1])^ = SP_KW_TRANSPARENT) or (pLongWord(@Tokens[Position +1])^ = SP_KW_TRANS)) Then Begin
                  Inc(Position, 1 + SizeOf(LongWord));
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Transparent Index
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                End Else
                  Expr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1) + Expr;
                Result := Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_WIN_GRAB)+ VarResult;
                If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
                Exit;
              End Else
                Error.Code := SP_ERR_MISSING_COMMA;
            End Else
              Error.Code := SP_ERR_MISSING_COMMA;
          End Else
            Error.Code := SP_ERR_MISSING_COMMA;
        End Else
          Error.Code := SP_ERR_MISSING_COMMA;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;
    End Else
      Error.Code := SP_ERR_MISSING_VARIABLE;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And
     ((pLongWord(@Tokens[Position +1])^ = SP_KW_MOVE) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_SIZE) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_SCROLL) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_ROLL)) Then Begin

    KeyWordID := pLongWord(@Tokens[Position +1])^;
    Inc(Position, 1 + SizeOf(LongWord));

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // X
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        Result := Expr;
        Case KeyWordID of
          SP_KW_MOVE:
            KeyWordID := SP_KW_WIN_MOVE;
          SP_KW_SIZE:
            KeyWordID := SP_KW_WIN_SIZE;
          SP_KW_SCROLL:
            KeyWordID := SP_KW_WIN_SCROLL;
          SP_KW_ROLL:
            KeyWordID := SP_KW_WIN_ROLL;
        End;
        Exit;
      End Else Begin
        Error.Code := SP_ERR_MISSING_COMMA;
      End;
    End Else Begin
      Error.Code := SP_ERR_MISSING_COMMA;
    End;

  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_MERGE) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ALL) Then Begin

      Inc(Position, 1 + SizeOf(LongWord));
      KeyWordID := SP_KW_WIN_MERGEALL;

    End Else Begin

      KeyWordID := SP_KW_WIN_MERGE;
      Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Error.Code := SP_ERR_MISSING_NUMEXPR;

    End;

    Exit;

  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And
     ((pLongWord(@Tokens[Position +1])^ = SP_KW_ERASE) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_SHOW) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_HIDE) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_FRONT) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_BACK)) Then Begin

    KeyWordID := pLongWord(@Tokens[Position +1])^;
    Inc(Position, 1 + SizeOf(LongWord));

    Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;

    Case KeyWordID of
      SP_KW_ERASE:
        KeyWordID := SP_KW_WIN_DEL;
      SP_KW_SHOW:
        KeyWordID := SP_KW_WIN_SHOW;
      SP_KW_HIDE:
        KeyWordID := SP_KW_WIN_HIDE;
      SP_KW_FRONT:
        KeyWordID := SP_KW_WIN_FRONT;
      SP_KW_BACK:
        KeyWordID := SP_KW_WIN_BACK;
    End;

    Exit;

  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_COPY) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));

    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      IsGraphic := True;
    End Else
      IsGraphic := False;

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End Else
      If IsGraphic Then
        Expr := Expr + CreateToken(SP_SPECIAL_SYMBOL, Position, 1) + aChar(SP_CHAR_UNARYM);

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // X
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // W
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // H
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
              Inc(Position, 1 + SizeOf(LongWord));
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1)+ Expr; // Index
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // X
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                  Inc(Position, 2);
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // W
                    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // H
                      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    End Else
                      Error.Code := SP_ERR_MISSING_COMMA;
                  End Else Begin
                    Expr := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0) + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0) + Expr;
                  End;
                  KeyWordID := SP_KW_SCRCOPY;
                  Result := Expr;
                  Exit;
                End Else
                  Error.Code := SP_ERR_MISSING_COMMA;
              End Else
                Error.Code := SP_ERR_MISSING_COMMA;
            End Else
              Error.Code := SP_ERR_MISSING_TO;
          End Else
            Error.Code := SP_ERR_MISSING_COMMA;
        End Else
          Error.Code := SP_ERR_MISSING_COMMA;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;
    End Else
      Error.Code := SP_ERR_MISSING_COMMA;

  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));

    Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Graphic Bank ID
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    KeyWordID := SP_KW_WINDOW_GFX;
    Exit;

  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ORIGIN) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FLIP) Then Begin
      Inc(Position, SizeOf(LongWord) +1);
      KeyWordID := SP_KW_WIN_ORG_FLIP;
      Result := Expr;
      Exit;
    End;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // X1
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y1
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          KeyWordID := SP_KW_WIN_ORIGIN;
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // x2
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // y2
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
          End Else Begin
            Error.Code := SP_ERR_MISSING_COMMA;
            Exit;
          End;
        End Else Begin
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // W
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // H
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              KeyWordID := SP_KW_WIN_ORG_DIM;
            End Else Begin
              Error.Code := SP_ERR_MISSING_COMMA;
              Exit;
            End;
          End Else Begin
            // no x2,y2 specified - specify ?? for them instead.
            KeyWordID := SP_KW_WIN_ORG_NO_EXT;
          End;
        End;
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FLIP) Then Begin
          Inc(Position, SizeOf(LongWord) +1);
          FlipExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
        End Else
          FlipExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);
        Result := FlipExpr + Expr;
        Exit;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;
    End Else
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OFF) Then Begin
        Inc(Position, SizeOf(LongWord) +1);
        KeyWordID := SP_KW_WIN_ORG_OFF;
        Result := Expr;
        Exit;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And ((pLongWord(@Tokens[Position +1])^ = SP_KW_TRANSPARENT) or (pLongWord(@Tokens[Position +1])^ = SP_KW_TRANSPARENT)) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OFF) Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      Expr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1) + Expr;
    End Else Begin
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Transparent index - or - alpha transparency
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;
    End;
    KeyWordID := SP_KW_WIN_TRANS;
    Result := Expr;
    Exit;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ALPHA) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ON) Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      Expr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1) + Expr;
    End Else
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OFF) Then Begin
        Inc(Position, 1 + SizeOf(LongWord));
        Expr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0) + Expr;
      End;
    KeyWordID := SP_KW_WIN_ALPHA;
    Result := Expr;
    Exit;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_DEPTH) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End Else
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // New bit depth
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;
    KeyWordID := SP_KW_WIN_DEPTH;
    Result := Expr;
    Exit;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CLIP) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;

    Result := Result + Expr;

    If (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
      Inc(Position, 2)
    Else Begin
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OFF) Then Begin
        Inc(Position, SizeOf(LongWord) +1);
        KeyWordID := SP_KW_WIN_CLIP_OFF;
        Result := Expr;
        Exit;
      End Else Begin
        Error.Code := SP_ERR_MISSING_COMMA;
        Exit;
      End;
    End;

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // x1
    If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
    Result := Result + Expr;

    If (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
      Inc(Position, 2)
    Else Begin
      Error.Code := SP_ERR_ILLEGAL_CHAR;
      Exit;
    End;

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // y1
    If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
    Result := Result + Expr;

    If (Ord(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then
      Inc(Position, 1+SizeOf(LongWord))
    Else Begin
      Error.Code := SP_ERR_ILLEGAL_CHAR;
      Exit;
    End;

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // x2
    If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
    Result := Result + Expr;

    If (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
      Inc(Position, 2)
    Else Begin
      Error.Code := SP_ERR_ILLEGAL_CHAR;
      Exit;
    End;

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // y2
    If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;

    Result := Result + Expr;
    KeyWordID := SP_KW_WIN_CLIP;
    Exit;

  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FLIP) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;

    Result := Result + Expr;
    KeyWordID := SP_KW_WINDOW_FLIP;
    Exit;

  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_MIRROR) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;

    Result := Result + Expr;
    KeyWordID := SP_KW_WINDOW_MIRROR;
    Exit;

  End;

  Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
  Result := Expr;

  //         id ADDCTRL ctrl-id,ctrl-type <PROP [Property-name$=value$,...]
  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ADDCTRL) Then Begin
    Inc(Position, 1 + SizeOf(Longword));
    If Byte(Tokens[Position]) = SP_NUMVAR Then Begin // ctrl-id
      VarResult := SP_Convert_Var_Assign(Tokens, Position, Error);
      If Error.Code <> SP_ERR_OK Then Exit;
      KeyWordPos := Position -1;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Control type
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;
      Result := VarResult + Expr;
      If Error.Code = SP_ERR_OK Then Begin
        // Check for a property string
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_PROPS) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          propExpr := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_STRING Then Begin
            Error.Code := SP_ERR_MISSING_STREXPR;
            Exit;
          End;
          Result := Result + propExpr;
          KeyWordID := SP_KW_WINDOW_ADDCTRL;
          Exit;
        End;
      End;
    End Else
      Error.Code := SP_ERR_MISSING_VARIABLE;
  End;

End;

Function SP_Convert_POKE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
Begin

  // POKE banknum,offset,value

  Result := '';

  Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then Exit;
  If Error.ReturnType <> SP_VALUE Then Begin
    Error.Code := SP_ERR_MISSING_NUMEXPR;
    Exit;
  End;
  Result := Result + Expr;
  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
    Inc(Position, 2);
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    Result := Result + Expr;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then Exit;
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      Result := Result + Expr;
    End Else
      Error.Code := SP_ERR_ILLEGAL_CHAR;
  End Else
    Error.Code := SP_ERR_ILLEGAL_CHAR;

End;

Function SP_Convert_POKES(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
Begin

  // POKE$ banknum,offset,strexpr

  Result := '';

  Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then Exit;
  If Error.ReturnType <> SP_VALUE Then Begin
    Error.Code := SP_ERR_MISSING_NUMEXPR;
    Exit;
  End;
  Result := Result + Expr;
  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
    Inc(Position, 2);
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    Result := Result + Expr;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then Exit;
      If Error.ReturnType <> SP_STRING Then Begin
        Error.Code := SP_ERR_MISSING_STREXPR;
        Exit;
      End;
      Result := Result + Expr;
    End Else
      Error.Code := SP_ERR_ILLEGAL_CHAR;
  End Else
    Error.Code := SP_ERR_ILLEGAL_CHAR;

End;

Function  SP_Convert_ON(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode; Var StList: aString): aString;
Var
  Vals: Array of Longword;
  Exprs: Array of aString;
  Condition, Every, FnResult, GotoExpr: aString;
  Condition_Pos, KeyWord, KeyWordPos: LongWord;
  GotCondition, OffFlag, b, HasElse: Boolean;
  n, i, j, KW, ot: Integer;
Begin

  // ON <[numexpr|EVERY numexpr] statement[:statement...]]|OFF|numexpr [GOTO|RESTORE|GOSUB] numexpr,numexpr...[ELSE statement...]> // Also EXECUTE
  // ON EVERY numexpr statement[:statement...]
  // ON EVERY OFF
  // ON numexpr
  // ON <ERROR|MOUSEDOWN|MOUSEUP|MOUSEMOVE|KEYUP|KEYDOWN|WHEELUP|WHEELDOWN|COLLIDE|MENU SHOW|MENU HIDE|MENUITEM> <Statement|OFF>

  // When executed, this will set up an (optionally timed) event, or error handler. The condition that follows the ON
  // must be TRUE when evaluated, and if EVERY is specified, a frame interval must follow before the
  // start of the code that is executed when cond is true.

  // To this end: The "cond" expression will be stored in tokenised form as a string, then the EVERY (which
  // will be zero if missing - to occur after every statement), followed by two numbers which denote line and
  // statement number.

  Result := '';

  If (Byte(Tokens[Position]) = SP_KEYWORD) And
     ((pLongWord(@Tokens[Position +1])^ = SP_KW_ERROR) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_MOUSEDOWN) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_MOUSEUP) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_MOUSEMOVE) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_KEYDOWN) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_KEYUP) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_WHEELUP) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_WHEELDOWN) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_MENU) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_MENUITEM) or
      (pLongWord(@Tokens[Position +1])^ = SP_KW_COLLIDE)) Then Begin

    KeyWord := pLongWord(@Tokens[Position +1])^; // Pick up one of the above tokens
    If Keyword = SP_KW_MENU Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      If (Byte(Tokens[Position]) = SP_KEYWORD) And ((pLongWord(@Tokens[Position +1])^ = SP_KW_SHOW)  or (pLongWord(@Tokens[Position +1])^ = SP_KW_HIDE)) Then
        KeyWord := pLongWord(@Tokens[Position +1])^
      Else Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End;
    End;
    KeyWordPos := Position;
    Inc(Position, 1 +SizeOf(LongWord));
    If (Byte(Tokens[Position]) = SP_KEYWORD) Then Begin // If it's "OFF" then pick that up here
      If pLongWord(@Tokens[Position +1])^ = SP_KW_OFF Then Begin
        Case KeyWord of
          SP_KW_MENUITEM:
            KeyWordID := SP_KW_MENUITEM_OFF;
          SP_KW_SHOW:
            KeyWordID := SP_KW_MENU_SHOW_OFF;
          SP_KW_HIDE:
            KeyWordID := SP_KW_MENU_HIDE_OFF;
          SP_KW_ERROR:
            KeyWordID := SP_KW_ON_ERR_OFF;
          SP_KW_MOUSEDOWN:
            KeyWordID := SP_KW_MOUSEDOWN_OFF;
          SP_KW_MOUSEUP:
            KeyWordID := SP_KW_MOUSEUP_OFF;
          SP_KW_MOUSEMOVE:
            KeyWordID := SP_KW_MOUSEMOVE_OFF;
          SP_KW_KEYDOWN:
            KeyWordID := SP_KW_KEYDOWN_OFF;
          SP_KW_KEYUP:
            KeyWordID := SP_KW_KEYUP_OFF;
          SP_KW_WHEELUP:
            KeyWordID := SP_KW_WHEELUP_OFF;
          SP_KW_WHEELDOWN:
            KeyWordID := SP_KW_WHEELDOWN_OFF;
          SP_KW_COLLIDE:
            KeyWordID := SP_KW_COLLIDE_OFF;
        End;
        Inc(Position, SizeOf(LongWord)+1);
      End Else Begin
        Case KeyWord of
          SP_KW_SHOW:
            KeyWordID := SP_KW_ON_MENU_SHOW;
          SP_KW_HIDE:
            KeyWordID := SP_KW_ON_MENU_HIDE;
          SP_KW_MENUITEM:
            KeyWordID := SP_KW_ON_MENUITEM;
          SP_KW_ERROR:
            KeyWordID := SP_KW_ON_ERR;
          SP_KW_MOUSEDOWN:
            KeyWordID := SP_KW_ON_MOUSEDOWN;
          SP_KW_MOUSEUP:
            KeyWordID := SP_KW_ON_MOUSEUP;
          SP_KW_MOUSEMOVE:
            KeyWordID := SP_KW_ON_MOUSEMOVE;
          SP_KW_KEYDOWN:
            KeyWordID := SP_KW_ON_KEYDOWN;
          SP_KW_KEYUP:
            KeyWordID := SP_KW_ON_KEYUP;
          SP_KW_WHEELUP:
            KeyWordID := SP_KW_ON_WHEELUP;
          SP_KW_WHEELDOWN:
            KeyWordID := SP_KW_ON_WHEELDOWN;
          SP_KW_COLLIDE:
            KeyWordID := SP_KW_ON_COLLIDE;
        End;
        Result := CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);
        If (Byte(Tokens[Position]) = SP_KEYWORD) or (Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR]) Then Begin
          If (Byte(Tokens[Position]) = SP_KEYWORD) Then Begin
            KeyWordID := pLongWord(@Tokens[Position +1])^;
            KeyWordPos := Position;
            Inc(Position, 1 + SizeOf(LongWord));
          End Else Begin
            KeyWordPos := Position;
            KeyWordID := SP_KW_LET;
          End;
          FnResult := SP_Convert_KeyWord(Tokens, Position, KeyWordID, Error, StList);
          If Error.Code <> SP_ERR_OK Then
            Exit
          Else Begin
            If KeyWordID = 0 Then
              Result := Result + FnResult
            Else Begin
              Result := Result + FnResult + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);
              KeyWordID := 0;
            End;
          End;
        End Else
          Error.Code := SP_ERR_SYNTAX_ERROR;
      End;
    End;

  End Else Begin

    // The condition is optional if EVERY is used

    KeyWordPos := Position;
    GotCondition := False;
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_EVERY) Then
      Condition := CreateToken(SP_STRING, Position, 0)
    Else Begin
      Condition_Pos := Position;
      Condition := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
      Condition := CreateToken(SP_STRING, Condition_Pos, Length(Condition)) + Condition;
      GotCondition := True;
    End;

    OffFlag := False;
    KW := pLongWord(@Tokens[Position +1])^;
    If (Byte(Tokens[Position]) = SP_KEYWORD) And ((KW = SP_KW_GO) or (KW = SP_KW_EXECUTE) or (KW = SP_KW_RESTORE)) And GotCondition Then Begin
      Inc(Position, 1 + SizeOf(LongWord));

      If KW = SP_KW_GO Then Begin // Sort out which one we're gonna get
        KW := -1;
        If Byte(Tokens[Position]) = SP_KEYWORD Then Begin
          KW := pLongWord(@Tokens[Position +1])^;
          Inc(Position, 1 + SizeOf(LongWord));
        End Else
          If Byte(Tokens[Position]) = SP_SYMBOL Then Begin
            KW := Ord(Tokens[Position +1]);
            Inc(Position, 2);
          End;
      End;

      If KW >= 0 Then Begin
        Case KW Of
          Ord(SP_CHAR_SUB): Begin KW := SP_KW_GOSUB;    ot := SP_VALUE; End;
             SP_KW_RESTORE: Begin KW := SP_KW_RESTORE;  ot := SP_VALUE; End;
                  SP_KW_TO: Begin KW := SP_KW_GOTO;     ot := SP_VALUE; End;
             SP_KW_EXECUTE: Begin KW := SP_KW_EXECUTE;  ot := SP_STRING; End;
        Else
          Begin
            Error.Code := SP_ERR_SYNTAX_ERROR;
            Exit;
          End;
        End;
        Condition := Copy(Condition, SizeOf(TToken) +1);
        // Followed by at least one numexpr, subsequent exprs separated by commas.
        // Store as an expression, then SP_IJMP followed by count (n) and n * longwords pointing at the expressions, then the expressions themselves.
        // Expressions followed by the GOTO/GOSUB/RESTORE/EXECUTE keyword token.
        SetLength(Exprs, 0);
        n := 0;
        Repeat
          SetLength(Exprs, Length(Exprs) +1);
          Exprs[n] := SP_Convert_Expr(Tokens, Position, Error, -1) + CreateToken(SP_KEYWORD, KeywordPos, SizeOf(LongWord)) + LongWordToString(KW);
          If Error.ReturnType = SP_LABEL then Error.ReturnType := SP_VALUE;
          If Error.ReturnType <> ot Then Error.Code := SP_ERR_SYNTAX_ERROR;
          If Error.Code <> SP_ERR_OK Then Exit;
          SP_AddHandlers(Exprs[n]);
          Inc(n);
          b := (Error.Code = SP_ERR_OK) and (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',');
          if b then Inc(Position, 2);
        Until (Position > Length(Tokens)) or Not b;
        If Error.Code <> SP_ERR_OK then Exit;

        HasElse := (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ELSE);

        // SP_IJMP, Count, else-skip, Skip0, Skip1, Skip2, Skip3, expr0, expr1, expr2, expr3

        SetLength(vals, n);
        For i := 0 To n -1 Do Begin
          vals[i] := (n - i) * SizeOf(LongWord);
          if i > 0 then
            for j := 0 to i-1 do
              Inc(vals[i], Length(Exprs[j]));
        End;

        // Got the lengths, now build the result string.
        GotoExpr := '';
        For i := 0 to n-1 Do
          GotoExpr := GotoExpr + LongWordToString(vals[i]); // Jump table

        For i := 0 to n-1 Do
          GotoExpr := GotoExpr + Exprs[i];

        If HasElse Then Begin // In order to actually jump past the ELSE, we need to skip the displacement *and* the keyword.
          GotoExpr := LongWordToString(Length(GotoExpr) + SizeOf(aFloat) + (2 * SizeOf(TToken)) + (2 * SizeOf(LongWord))) + GotoExpr;
        End Else
          GotoExpr := LongWordToString(0) + GotoExpr;
        GotoExpr := LongWordToString(n) + GotoExpr; // Number of expressions

        Result := Condition + CreateToken(SP_IJMP, 0, Length(GotoExpr)) + GotoExpr;

        KeyWordID := 0;

      End Else
        Error.Code := SP_ERR_SYNTAX_ERROR;
    End Else Begin
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_EVERY) Then Begin
        Inc(Position, 1 + SizeOf(LongWord));
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OFF) Then Begin
          Every := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1);
          Inc(Position, 1 + SizeOf(LongWord));
          OffFlag := True;
        End Else Begin
          Every := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
        End;
      End Else Begin
        If GotCondition Then
          Every := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0)
        Else Begin
          Error.Code := SP_ERR_SYNTAX_ERROR;
          Exit;
        End;
      End;

      KeyWordID := SP_KW_ON;
      Result := Every + Condition + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);

      If (Byte(Tokens[Position]) = SP_KEYWORD) or (Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR]) Then Begin
        If (Byte(Tokens[Position]) = SP_KEYWORD) Then Begin
          KeyWordID := pLongWord(@Tokens[Position +1])^;
          KeyWordPos := Position;
          Inc(Position, 1 + SizeOf(LongWord));
        End Else Begin
          KeyWordPos := Position;
          KeyWordID := SP_KW_LET;
        End;
        FnResult := SP_Convert_KeyWord(Tokens, Position, KeyWordID, Error, StList);
        If Error.Code <> SP_ERR_OK Then
          Exit
        Else Begin
          Result := Result + FnResult;
          If KeyWordID <> 0 Then Result := Result + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID);
          KeyWordID := 0;
        End;
      End Else
        If Not OffFlag Then
          Error.Code := SP_ERR_SYNTAX_ERROR;
    End;

  End;

End;

Function SP_Convert_CLEAR(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarType, VarPos, VarIdx, VarSize: LongWord;
  VarName: aString;
Begin

  // CLEAR [Var|ERROR]

  Result := '';
  If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
    VarType := Byte(Tokens[Position]);
    Inc(Position);
    VarPos := Position;
    VarIdx := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    Result := CreateToken(VarType, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(VarIdx) + VarName;
    KeyWordID := SP_KW_CLEAR_VAR;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
      // Clearing an array
      Inc(Position, 2);
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
        Inc(Position, 2);
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
          If (VarType = SP_NUMVAR) And (Error.ReturnType <> SP_VALUE) then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End Else
            If (VarType = SP_STRVAR) And (Error.ReturnType <> SP_STRING) then Begin
              Error.Code := SP_ERR_MISSING_STREXPR;
              Exit;
            End;
        End Else
          If VarType = SP_NUMVAR Then
            Result := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0) + Result
          Else
            Result := CreateToken(SP_STRING, Position, 0) + Result;
        Exit;
      End Else Begin
        Error.Code := SP_ERR_MISSING_BRACKET;
        Exit;
      End;
    End;
  End Else
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ERROR) Then Begin
      KeyWordID := SP_KW_CLEAR_ERR;
      Inc(Position, SizeOf(LongWord) +1);
    End Else
      KeyWordID := SP_KW_CLEAR;

End;

Function SP_Convert_YIELD(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // YIELD (No params)

  Result := '';

End;

Function  SP_Convert_FILL(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
Begin

  // FILL [ALPHA] [colour items;]x,y[,{fill$|GRAPHIC n}]

  SP_AlphaCheck(KeyWordID, Tokens, Position);

  Expr := '';
  Result := SP_Convert_Embedded_Colours(Tokens, Position, Error);
  If Error.Code <> SP_ERR_OK Then Exit;

  Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then Exit;
  If Error.ReturnType <> SP_VALUE Then Begin
    Error.Code := SP_ERR_MISSING_NUMEXPR;
    Exit;
  End;
  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
    Inc(Position, 2);
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr;
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
        Inc(Position, 1 + SizeOf(LongWord));
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Graphic ID
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
      End Else Begin
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // strexpr
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_STRING Then Begin
          Error.Code := SP_ERR_MISSING_STREXPR;
          Exit;
        End;
      End;
      If KeyWordID = SP_KW_AFILL Then
        KeyWordID := SP_KW_AFILLTEX
      Else
        KeyWordID := SP_KW_FILLTEX;
    End;
    Result := Result + Expr;
    Exit;
  End Else Begin
    Error.Code := SP_ERR_ILLEGAL_CHAR;
    Exit;
  End;

End;

Function SP_Convert_RECTANGLE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
  GotA, GotB: Boolean;
label
  gotTO, CheckFill;
Begin

  // RECTANGLE [ALPHA] [INK numexpr;]x1,y1{,| TO }x2,y2[FILL {fill$|GRAPHIC n}]

  SP_AlphaCheck(KeyWordID, Tokens, Position);

  GotA := False; GotB := False;
  Result := SP_Convert_Embedded_Colours(Tokens, Position, Error);
  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
    If KeywordID = SP_KW_RECTANGLE Then
      KeyWordID := SP_KW_RECTANGLE_TO
    Else
      If KeywordID = SP_KW_ARECTANGLE Then
        KeyWordID := SP_KW_ARECTANGLE_TO;
    goto GotTo;
  End;

  Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then Exit;
  If Error.ReturnType <> SP_VALUE Then Begin
    Error.Code := SP_ERR_MISSING_NUMEXPR;
    Exit;
  End Else
    GotA := True;
  Result := Result + Expr;
  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
    Inc(Position, 2);
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End Else
      GotB := True;
    Result := Result + Expr;
  GotTO:
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO)  Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then Exit;
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      Result := Result + Expr;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
        If Error.Code <> SP_ERR_OK Then Exit;
        If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        Result := Result + Expr;
      CheckFill:
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FILL) Then Begin
          Inc(Position, SizeOf(LongWord)+1);
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
            Inc(Position, 1 + SizeOf(LongWord));
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Graphic ID
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
          End Else Begin
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // strexpr
            If Error.Code <> SP_ERR_OK Then
              Exit
            Else Begin
              If Error.ReturnType <> SP_STRING Then Begin
                If Expr = '' Then
                  Expr := CreateToken(SP_STRING, 0, 0)
                Else Begin
                  Error.Code := SP_ERR_MISSING_STREXPR;
                  Exit;
                End;
              End;
            End;
          End;
          Result := Result + Expr;
          If KeyWordID = SP_KW_ARECTANGLE Then
            KeyWordID := SP_KW_ARECTFILL
          Else
            If KeyWordID = SP_KW_RECTANGLE Then
              KeyWordID := SP_KW_RECTFILL
            Else
              If KeyWordID = SP_KW_ARECTANGLE_TO Then
                KeyWordID := SP_KW_ARECTFILL_TO
              Else
                If KeyWordID = SP_KW_RECTANGLE_TO Then
                  KeyWordID := SP_KW_RECTFILL_TO;
        End;
        Exit;
      End Else
        Error.Code := SP_ERR_ILLEGAL_CHAR;
    End Else
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',')  Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
        If Error.Code <> SP_ERR_OK Then Exit;
        If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        Result := Result + Expr;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit;
          If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          Result := Result + Expr;
          If KeyWordID = SP_KW_RECTANGLE Then
            KeyWordID := SP_KW_RECTANGLE2
          Else
            KeyWordID := SP_KW_ARECTANGLE2;
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FILL) Then Begin
            Inc(Position, SizeOf(LongWord)+1);
            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
              Inc(Position, 1 + SizeOf(LongWord));
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Graphic ID
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
            End Else Begin
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // strexpr
              If Error.Code <> SP_ERR_OK Then
                Exit
              Else Begin
                If Error.ReturnType <> SP_STRING Then Begin
                  If Expr = '' Then
                    Expr := CreateToken(SP_STRING, 0, 0)
                  Else Begin
                    Error.Code := SP_ERR_MISSING_STREXPR;
                    Exit;
                  End;
                End;
              End;
            End;
            Result := Result + Expr;
            If KeyWordID = SP_KW_ARECTANGLE2 Then
              KeyWordID := SP_KW_ARECTFILL2
            Else
              KeyWordID := SP_KW_RECTFILL2;
          End;
          Exit;
        End Else
          Error.Code := SP_ERR_ILLEGAL_CHAR;
      End Else
        If GotA And GotB Then
          Goto CheckFill
        Else
          Exit;
  End Else
    Error.Code := SP_ERR_ILLEGAL_CHAR;

End;

Function SP_Convert_POLYGON(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarPos, VarSize: Integer;
  VarType: aChar;
  VarName: aString;
  NumPoints: Integer;
  Expr: aString;
  ArrayParam: Boolean;
Label
  NotVar;
Begin

  // POLYGON|POLYLINE [ALPHA] [INK numexpr;]{Array()|x1,y1 TO x2,y2 TO x3,y3 [ TO xN,yN]}[FILL {fill$|GRAPHIC n}|OPEN]

  SP_AlphaCheck(KeyWordID, Tokens, Position);

  Result := SP_Convert_Embedded_Colours(Tokens, Position, Error);
  If Error.Code <> SP_ERR_OK Then Exit;

  ArrayParam := False;
  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
       Result := Result + CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
       Inc(Position, 4);
       ArrayParam := True;
    End Else Begin
      Position := VarPos;
      GoTo NotVar;
    End;
  End Else Begin
    NotVar:
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
    Result := Result + Expr;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
      Result := Result + Expr;
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
        Inc(Position, 1 + SizeOf(LongWord));
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
        Result := Result + Expr;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
          Result := Result + Expr;
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
            Inc(Position, 1 + SizeOf(LongWord));
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
            Result := Result + Expr;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
              Result := Result + Expr;
            End;
          End Else
            Error.Code := SP_ERR_ILLEGAL_CHAR;
        End Else
          Error.Code := SP_ERR_ILLEGAL_CHAR;
      End Else
        Error.Code := SP_ERR_ILLEGAL_CHAR;
    End Else
      Error.Code := SP_ERR_ILLEGAL_CHAR;

    If Error.Code <> SP_ERR_OK Then Begin
      Error.Position := Position;
      Exit;
    End;
  End;

  NumPoints := 3;
  While True Do Begin

    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) And Not ArrayParam Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
      Result := Result + Expr;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
        Result := Result + Expr;
        Inc(NumPoints);
      End Else Begin
        Error.Code := SP_ERR_ILLEGAL_CHAR;
        Exit;
      End;
    End Else
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FILL) Then Begin
        Inc(Position, SizeOf(LongWord)+1);
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Graphic ID
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
        End Else Begin
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // strexpr
          If Error.Code <> SP_ERR_OK Then
            Exit
          Else Begin
            If Error.ReturnType <> SP_STRING Then Begin
              If Expr = '' Then
                Expr := CreateToken(SP_STRING, 0, 0)
              Else Begin
                Error.Code := SP_ERR_MISSING_STREXPR;
                Exit;
              End;
            End;
          End;
        End;
        If ArrayParam Then
          Result := Result + Expr
        Else
          Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(NumPoints) + Expr;
        If KeyWordID = SP_KW_APOLYGON Then
          KeyWordID := SP_KW_APOLYFILL
        Else
          KeyWordID := SP_KW_POLYFILL;
        Exit;
      End Else Begin
        If Not ArrayParam Then
          Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(NumPoints);
        If KeyWordID = SP_KW_APOLYGON Then
          KeyWordID := SP_KW_APOLYLINE
        Else
          KeyWordID := SP_KW_POLYLINE;
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OPEN) Then Begin
          Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
          Inc(Position, 1 + SizeOf(LongWord));
        End Else
          Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);
        Exit;
      End;

  End;

End;

Function SP_Convert_DEGREES(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // DEGREES (no params)

  Result := '';

End;

Function SP_Convert_RADIANS(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // RADIANS (no params)

  Result := '';

End;

Function SP_Convert_TURNS(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // TURNS (no params)

  Result := '';

End;

Function SP_Convert_GRADIANS(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // GRADIANS (no params)

  Result := '';

End;

Function SP_Convert_RECOVER(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // RECOVER (no params)

  Result := '';

End;

Function SP_Convert_FONT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  KeyWordPos: LongWord;
  VarResult, Expr: aString;
Begin

  // FONT [id|NEW id,w,h,mode[ TRANSPARENT n][LOAD f$[,MinChar]]|TRANSPARENT id,n|ERASE n]

  Result := '';
  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_NEW) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

      VarResult := SP_Convert_Var_Assign(Tokens, Position, Error); // FontID
      If Error.Code <> SP_ERR_OK Then Exit;
      KeyWordPos := Position -1;

      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Width
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Height
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Mode
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            If (Byte(Tokens[Position]) = SP_KEYWORD) And ((pLongWord(@Tokens[Position +1])^ = SP_KW_TRANSPARENT) or (pLongWord(@Tokens[Position +1])^ = SP_KW_TRANS)) Then Begin
              Inc(Position, 1 + SizeOf(LongWord));
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Transparent Index
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
            End Else
              Expr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1) + Expr;
            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_LOAD) Then Begin
              Inc(Position, 1 + SizeOf(LongWord));
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Filename for LOAD
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_STRING Then Begin
                Error.Code := SP_ERR_MISSING_STREXPR;
                Exit;
              End;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // MinChar
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
              End Else
                Expr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(32) + Expr;
            End Else
              Expr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(32) + CreateToken(SP_STRING, Position, 0) + Expr;
            Result := Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_FONT_NEW) + VarResult;
            If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
            Exit;
          End Else
            Error.Code := SP_ERR_MISSING_COMMA;
        End Else
          Error.Code := SP_ERR_MISSING_COMMA;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;
    End Else
      Error.Code := SP_ERR_MISSING_VARIABLE;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And ((pLongWord(@Tokens[Position +1])^ = SP_KW_TRANSPARENT) or (pLongWord(@Tokens[Position +1])^ = SP_KW_TRANS)) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // FontID
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    Result := Expr;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Transparent Index
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      Result := Expr + Result;
      KeyWordID := SP_KW_FONT_TRANS;
      Exit;
    End Else
      Error.Code := SP_ERR_MISSING_COMMA;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ERASE) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // FontID
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    Result := Expr;
    KeyWordID := SP_KW_FONT_ERASE;
    Exit;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // FontID
  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
    Error.Code := SP_ERR_MISSING_NUMEXPR;
    Exit;
  End;
  Result := Expr;

End;

Function SP_Convert_BANK(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarResult, Expr: aString;
  KeyWordPos: LongWord;
Begin

  // BANK NEW numvar[,size]
  // BANK SIZE id,size
  // BANK ERASE id
  // BANK ERASE ALL
  // BANK GRAB strvar,SrcID,offset,length
  // BANK PUT StrExpr,DstID,Offset
  // BANK COPY SrcID[,start,len] TO DstID[,offset]
  // BANK PROTECT n
  // BANK UNPROTECT n

  Result := '';

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_NEW) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

      VarResult := SP_Convert_Var_Assign(Tokens, Position, Error); // BankID
      If Error.Code <> SP_ERR_OK Then Exit;
      KeyWordPos := Position -1;

      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Size
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
      End Else
        Expr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);
      Result := Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID)+ VarResult;
      If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
      Exit;

    End Else
      Error.Code := SP_ERR_MISSING_VARIABLE;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SIZE) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // BankID
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    Result := Expr;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // New size
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      Result := Expr + Result;
      KeyWordID := SP_KW_BANK_SIZE;
      Exit;
    End Else
      Error.Code := SP_ERR_MISSING_COMMA;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ERASE) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (plOngWord(@Tokens[Position +1])^ = SP_KW_ALL) Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      KeyWordID := SP_KW_BANK_ERASE_ALL;
      Exit;
    End Else Begin
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // BankID
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      Result := Expr;
      KeyWordID := SP_KW_BANK_ERASE;
      Exit;
    End;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_PROTECT) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // BankID
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    Result := Expr;
    KeyWordID := SP_KW_BANK_PROTECT;
    Exit;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_DEPROTECT) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // BankID
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    Result := Expr;
    KeyWordID := SP_KW_BANK_DEPROTECT;
    Exit;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_COPY) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // SrcID
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    Result := Expr;
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // DstID
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      Result := Expr + Result;
      KeyWordID := SP_KW_BANK_COPY;
      Exit;
    End Else Begin
      // BANK COPY SrcID,start,len TO DstID,offset
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Start
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        Result := Expr + Result;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Length
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          Result := Expr + Result;
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
            Inc(Position, 1 + SizeOf(LongWord));
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // DstID
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            Result := Expr + Result;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Offset
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              Result := Expr + Result;
              KeyWordID := SP_KW_BANK_COPY_EX;
              Exit;
            End Else
              Error.Code := SP_ERR_SYNTAX_ERROR;
          End Else
            Error.Code := SP_ERR_MISSING_TO;
        End Else
          Error.Code := SP_ERR_SYNTAX_ERROR;
      End Else
        Error.Code := SP_ERR_SYNTAX_ERROR;
    End;
  End;

End;

Function SP_Convert_WAIT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // WAIT <numexpr|SCREEN [frames]|KEY|KEYDOWN|KEYUP>

  Result := '';
  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SCREEN) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    Result := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Result = '' Then
      Result := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0)
    Else
      Result := Result + CreateToken(SP_SPECIAL_SYMBOL, Position, 1) + aChar(SP_CHAR_UNARYM);
  End Else Begin
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_KEY) Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      KeyWordID := SP_KW_WAIT_KEY;
    End Else
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_KEYDOWN) Then Begin
        Inc(Position, 1 + SizeOf(LongWord));
        KeyWordID := SP_KW_WAIT_KEY_PRESS;
      End Else
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_KEYUP) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          KeyWordID := SP_KW_WAIT_KEY_UP;
        End Else Begin
          Result := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
        End;
  End;
End;

Function SP_Convert_STREAM(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarResult, Expr: aString;
  KeyWordPos: LongWord;
Begin

  // STREAM [NEW numvar,[BankID|Filename$]|READ id,strvar,count|READ LINE id,strvar|WRITE id,strexpr|SEEK id,Position|CLOSE id]

  Result := '';

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_NEW) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

      VarResult := SP_Convert_Var_Assign(Tokens, Position, Error); // Stream ID
      If Error.Code <> SP_ERR_OK Then Exit;
      KeyWordPos := Position -1;

      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // BankID or Filename
        If Expr = '' Then
          Error.Code := SP_ERR_SYNTAX_ERROR;
        If Error.Code <> SP_ERR_OK Then Exit;
        Result := Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_STREAM_NEW) + VarResult;
        If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
        Exit;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;
    End Else
      Error.Code := SP_ERR_MISSING_VARIABLE;
  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_READ) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_LINE) Then Begin //

      Inc(Position, SizeOf(LongWord) +1);
      Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Stream ID
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);

        If Byte(Tokens[Position]) = SP_STRVAR Then Begin

          VarResult := SP_Convert_Var_Assign(Tokens, Position, Error); // Destination string variable
          If Error.Code <> SP_ERR_OK Then Exit;
          KeyWordPos := Position -1;
          Result := Result + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_STREAM_READLN)+ VarResult;
          If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
          Exit;

        End Else
          Error.Code := SP_ERR_MISSING_VARIABLE;
      End;

    End Else Begin
      Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Stream ID
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);

        If Byte(Tokens[Position]) = SP_STRVAR Then Begin

          VarResult := SP_Convert_Var_Assign(Tokens, Position, Error); // Destination string variable
          If Error.Code <> SP_ERR_OK Then Exit;
          KeyWordPos := Position -1;

          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Count
            If Error.Code <> SP_ERR_OK then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
            Result := Result + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_STREAM_READ)+ VarResult;
            If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
            Exit;
          End Else
            Error.Code := SP_ERR_MISSING_COMMA;
        End Else
          Error.Code := SP_ERR_MISSING_VARIABLE;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;
    End;

  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_WRITE) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Stream ID
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // String expression
      If Error.Code <> SP_ERR_OK then Exit Else If Error.ReturnType <> SP_STRING Then Begin Error.Code := SP_ERR_MISSING_STREXPR; Exit; End;
      KeyWordID := SP_KW_STREAM_WRITE;
      Exit;
    End Else
      Error.Code := SP_ERR_MISSING_COMMA;

  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SEEK) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Stream ID
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Position
      If Error.Code <> SP_ERR_OK then Exit Else If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
      KeyWordID := SP_KW_STREAM_SEEK;
      Exit;
    End Else
      Error.Code := SP_ERR_MISSING_COMMA;

  End;

  If Error.Code <> SP_ERR_OK Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CLOSE) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Stream ID
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    KeyWordID := SP_KW_STREAM_CLOSE;

  End;

End;

Function  SP_Convert_SETDIR(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // SETDIR strexpr

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);

  If Error.Code = SP_ERR_OK Then
    If Error.ReturnType <> SP_STRING Then
      Error.Code := SP_ERR_MISSING_STREXPR;

End;

Function  SP_Convert_COMPILE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
var
  done: Boolean;
  BankCount: Integer;
  BankExpr: aString;
Begin

  // COMPILE strexpr[,strexpr] [LINE numexpr] [BANK id[,id..]]

  Result := SP_Convert_Expr(Tokens, Position, Error, -1); // filename
  If Error.Code = SP_ERR_OK Then
    If Error.ReturnType <> SP_STRING Then
      Error.Code := SP_ERR_MISSING_STREXPR;

  If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = ',') Then Begin // window caption
    Inc(Position, 2);
    Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
  End Else
    Result := CreateToken(SP_STRING, Position, 0) + Result;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_LINE) Then Begin
    Inc(Position, 1 + SizeOf(Longword));
    Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
    If (Error.Code <> SP_ERR_OK) or (Error.ReturnType <> SP_VALUE) Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
  End Else
    Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0) + Result;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_BANK) Then Begin
    Inc(Position, 1 + SizeOf(Longword));
    Done := False;
    BankExpr := '';
    BankCount := 0;
    While Not Done Do Begin
      BankExpr := SP_Convert_Expr(Tokens, Position, Error, -1) + BankExpr;
      If (Error.Code <> SP_ERR_OK) or (Error.ReturnType <> SP_VALUE) Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End Else
        Inc(BankCount);
      If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = ',') Then
        Inc(Position, 2)
      Else
        Done := True;
    End;
    Result := BankExpr + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(BankCount) + Result;
  End Else
    Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0) + Result; // Otherwise, zero banks

End;

Function  SP_Convert_LABEL(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  LabelLen: Integer;
  LabelText: aString;
Begin

  // LABEL labelname

  If Tokens[Position] <> SP_TERMINAL_CHAR Then Begin
    Inc(Position);
    LabelLen := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    LabelText := Copy(Tokens, Position, LabelLen);
    Inc(Position, LabelLen);

    Result := CreateToken(SP_LABEL, 0, LabelLen) + LabelText;
    Result := CreateToken(SP_SKIP_STATEMENT, 0, SizeOf(LongWord)) + LongWordToString(Length(Result) + SizeOf(TToken) + SizeOf(LongWord)) + Result;
  End Else
    Error.Code := SP_ERR_SYNTAX_ERROR;

End;

Function  SP_Convert_EXECUTE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // EXECUTE strexpr

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code = SP_ERR_OK Then
    If Error.ReturnType <> SP_STRING Then
      Error.Code := SP_ERR_MISSING_STREXPR;

End;

Function  SP_Convert_ROTATE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // ROTATE [TO] numexpr

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    KeyWordID := SP_KW_ROTATETO;
  End;

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code = SP_ERR_OK Then
    If Error.ReturnType <> SP_VALUE Then
      Error.Code := SP_ERR_MISSING_NUMEXPR;

End;

Function  SP_Convert_FACE(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
Begin

  // FACE numexpr,numexpr

  Result := '';

  Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then Exit;
  If Error.ReturnType <> SP_VALUE Then Begin
    Error.Code := SP_ERR_MISSING_NUMEXPR;
    Exit;
  End;
  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
    Inc(Position, 2);
    Result := Result + Expr;
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    Result := Result + Expr;
    Exit;
  End Else Begin
    Error.Code := SP_ERR_ILLEGAL_CHAR;
    Exit;
  End;

End;

Function  SP_Convert_MOVE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
Begin

  // MOVE [TO numexpr,] numexpr [,numexpr]
  // MOVE filespec$ TO dest-dir$ [OVER]

  Result := '';

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Result := Result + Expr;
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then Exit;
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      Result := Result + Expr;
      KeyWordID := SP_KW_DRMOVETO;
      Exit;
    End Else Begin
      Error.Code := SP_ERR_ILLEGAL_CHAR;
      Exit;
    End;
  End Else Begin

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      If Error.ReturnType = SP_STRING Then Begin
        Result := Expr; // filespec$
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // dest-dir$
          If Error.Code <> SP_ERR_OK Then
            Exit
          Else
            If Error.ReturnType <> SP_STRING Then Begin
              Error.Code := SP_ERR_MISSING_STREXPR;
              Exit;
            End Else Begin
              KeyWordID := SP_KW_MOVE_FILES;
              Exit;
            End;
        End Else Begin
          Error.Code := SP_ERR_MISSING_TO;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OVER) Then Begin
          Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1) + Result;
          Inc(Position, 1 + SizeOf(LongWord));
        End Else
          Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0) + Result;
      End Else Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
    End;
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Result := Result + Expr;
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then Exit;
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      Result := Result + Expr;
      KeyWordID := SP_KW_DRMOVEXY;
      Exit;
    End Else
      Result := Expr;

  End;

End;

Function  SP_Convert_SAMPLE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr, VarResult: aString;
  LoopExpr, RateExpr, VolumeExpr, PanningExpr, ChanExpr, ChanVarExpr, BitsExpr, SizeExpr: aString;
  KeyWordPos, KeyWord: LongWord;
  ChanAssign: Boolean;
Begin

  // SAMPLE NEW numvar {, filename$| [RATE numexpr] [BITS numexpr] [SIZE numexpr] [STEREO]}
  // SAMPLE PLAY numexpr [LOOP] [RATE numexpr|strexpr] [VOLUME numexpr] [PAN numexpr] [CHANNEL numvar]
  // SAMPLE RATE numexpr,numexpr
  // SAMPLE PAN numexpr,numexpr
  // SAMPLE BITS numexpr,numexpr
  // SAMPLE STEREO numexpr,numexpr
  // SAMPLE VOLUME numexpr,numexpr
  // SAMPLE ERASE numexpr

  Result := '';
  KeyWordPos := Position;

  If Byte(Tokens[Position]) = SP_KEYWORD Then Begin

    KeyWord := pLongWord(@Tokens[Position +1])^;
    Inc(Position, 1 + SizeOf(LongWord));

    Case KeyWord Of

      SP_KW_NEW:
        Begin
          If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
            VarResult := SP_Convert_Var_Assign(Tokens, Position, Error); // Var to hold Sample ID number (Bank number)
            If Error.Code <> SP_ERR_OK Then Exit;
            KeyWordPos := Position -1;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Filename
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_STRING Then Begin
                Error.Code := SP_ERR_MISSING_STREXPR;
                Exit;
              End;
              KeyWordID := SP_KW_SAMPLE_LOAD;
              Result := Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID)+ VarResult;
              If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
            End Else Begin
              SizeExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);
              RateExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(44100);
              BitsExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(16);
              ChanExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
              While Byte(Tokens[Position]) = SP_KEYWORD Do Begin

                Case pLongWord(@Tokens[Position +1])^ of

                  SP_KW_SIZE:
                    Begin
                      Inc(Position, SizeOf(LongWord) +1);
                      SizeExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    End;

                  SP_KW_RATE:
                    Begin
                      Inc(Position, SizeOf(LongWord) +1);
                      RateExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    End;

                  SP_KW_BITS:
                    Begin
                      Inc(Position, SizeOf(LongWord) +1);
                      BitsExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    End;

                  SP_KW_STEREO:
                    Begin
                      Inc(Position, SizeOf(LongWord) +1);
                      ChanExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(2);
                    End;
                Else
                  Break;
                End;
              End;
              KeyWordID := SP_KW_SAMPLE_NEW;
              Result := RateExpr + BitsExpr + ChanExpr + SizeExpr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID)+ VarResult;
              If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
            End;
          End Else Begin
            Error.Code := SP_ERR_MISSING_VARIABLE;
          End;
        End;

      SP_KW_PLAY:
        Begin
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;

          LoopExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);
          RateExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1);
          VolumeExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1);
          PanningExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-9);
          ChanExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);
          ChanAssign := False;

          While Byte(Tokens[Position]) = SP_KEYWORD Do Begin

            Case pLongWord(@Tokens[Position +1])^ of

              SP_KW_LOOP:
                Begin
                  LoopExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
                  Inc(Position, SizeOf(LongWord) +1);
                End;

              SP_KW_RATE:
                Begin
                  Inc(Position, SizeOf(LongWord) +1);
                  RateExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then Exit;
                End;

              SP_KW_VOLUME:
                Begin
                  Inc(Position, SizeOf(LongWord) +1);
                  VolumeExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                End;

              SP_KW_PAN:
                Begin
                  Inc(Position, SizeOf(LongWord) +1);
                  PanningExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                End;

              SP_KW_CHANNEL:
                Begin
                  ChanAssign := True;
                  ChanExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
                  Inc(Position, SizeOf(LongWord) +1);
                  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
                    ChanVarExpr := SP_Convert_Var_Assign(Tokens, Position, Error);
                    If Error.Code <> SP_ERR_OK Then Exit;
                    KeyWordPos := Position -1;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_VARIABLE;
                    Exit;
                  End;

                End;
            Else
              Break;
            End;
          End;
          KeyWordID := SP_KW_SAMPLE_PLAY;
          Result := PanningExpr + VolumeExpr + RateExpr + LoopExpr + Expr + ChanExpr;
          If ChanAssign Then Begin
            Result := Result + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID)+ ChanVarExpr;
            If pToken(@ChanVarExpr[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
          End;

        End;
      SP_KW_RATE, SP_KW_BITS, SP_KW_STEREO, SP_KW_VOLUME, SP_KW_PAN:
        Begin
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
             Error.Code := SP_ERR_MISSING_NUMEXPR;
             Exit;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Expr := Expr + SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            Case KeyWord of
              SP_KW_RATE: KeyWordID := SP_KW_SAMPLE_RATE;
              SP_KW_BITS: KeyWordID := SP_KW_SAMPLE_DEPTH;
              SP_KW_STEREO: KeyWordID := SP_KW_SAMPLE_STEREO;
              SP_KW_VOLUME: KeyWordID := SP_KW_SAMPLE_VOLUME;
              SP_KW_PAN: KeyWordID := SP_KW_SAMPLE_PAN;
            End;
            Result := Expr;
          End Else Begin
            Error.Code := SP_ERR_ILLEGAL_CHAR;
          End;
        End;
      SP_KW_ERASE:
        Begin
          Result := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
             Error.Code := SP_ERR_MISSING_NUMEXPR;
             Exit;
          End;
          KeyWordID := SP_KW_SAMPLE_ERASE;
        End;

    Else

      Begin

        Error.Code := SP_ERR_SYNTAX_ERROR;

      End;

    End;

  End Else
    Error.Code := SP_ERR_SYNTAX_ERROR;

End;

Function SP_Convert_VOLUME(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // VOLUME numexpr

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK then Exit;
  If Error.ReturnType <> SP_VALUE Then Error.Code := SP_ERR_MISSING_NUMEXPR;

End;

Function SP_Convert_CHANNEL(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  KeyWord: LongWord;
Begin

  // CHANNEL PAUSE numexpr
  // CHANNEL RESUME numexpr
  // CHANNEL STOP numexpr
  // CHANNEL SEEK numexpr,numexpr
  // CHANNEL RATE numexpr,[numexpr|strexpr]
  // CHANNEL PAN numexpr,numexpr
  // CHANNEL VOLUME numexpr,numexpr

  Result := '';

  If Byte(Tokens[Position]) = SP_KEYWORD Then Begin

    KeyWord := pLongWord(@Tokens[Position +1])^;
    Inc(Position, 1 + SizeOf(LongWord));

    Case KeyWord Of

      SP_KW_PAUSE, SP_KW_RESUME, SP_KW_STOP:
        Begin

          Result := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
             Error.Code := SP_ERR_MISSING_NUMEXPR;
             Exit;
          End;
          Case KeyWord Of
            SP_KW_PAUSE: KeyWordID := SP_KW_CHANNEL_PAUSE;
            SP_KW_RESUME: KeyWordID := SP_KW_CHANNEL_RESUME;
            SP_KW_STOP: KeyWordID := SP_KW_CHANNEL_STOP;
          End;

        End;

      SP_KW_RATE:
        Begin
          Result := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
             Error.Code := SP_ERR_MISSING_NUMEXPR;
             Exit;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Result := Result + SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then
              Exit
            Else
              If Error.ReturnType = SP_VALUE Then
                KeyWordID := SP_KW_CHANNEL_RATE_VAL
              Else
                If Error.ReturnType = SP_STRING Then
                  KeyWordID := SP_KW_CHANNEL_RATE_STR
                Else Begin
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
          End Else Begin
            Error.Code := SP_ERR_ILLEGAL_CHAR;
          End;
        End;

      SP_KW_SEEK, SP_KW_PAN, SP_KW_VOLUME:
        Begin

          Result := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
             Error.Code := SP_ERR_MISSING_NUMEXPR;
             Exit;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Result := Result + SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            Case KeyWord of
              SP_KW_VOLUME: KeyWordID := SP_KW_CHANNEL_VOLUME;
              SP_KW_PAN: KeyWordID := SP_KW_CHANNEL_PAN;
              SP_KW_SEEK: KeyWordID := SP_KW_CHANNEL_SEEK;
            End;
          End Else Begin
            Error.Code := SP_ERR_ILLEGAL_CHAR;
          End;

        End;

    End;

  End;

End;

Function  SP_Convert_PLAY(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Done: Boolean;
  Cnt: Integer;
Begin

  // PLAY str1[,str2...] ASYNC
  // PLAY STOP

  Result := '';
  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_STOP) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    KeyWordID := SP_KW_PLAY_STOP;
  End Else Begin
    Cnt := 0;
    Done := False;
    While Not Done Do Begin
      Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
      If Error.Code = SP_ERR_OK Then Begin
        If Error.ReturnType <> SP_STRING Then Begin
          Error.Code := SP_ERR_MISSING_STREXPR;
          Exit;
        End Else
          Inc(Cnt);
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
          Inc(Position, 2)
        Else
          Done := True;
      End Else
        Exit;
    End;

    Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(Cnt);

    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ASYNC) Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1);
    End Else
      Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);
  End;

End;

Function SP_Convert_MUSIC(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  KeyWord: LongWord;
  PauseExpr, VolumeExpr, LoopExpr: aString;
Begin

  // MUSIC PLAY {strexpr|BankID} [VOLUME numexpr] [PAUSE]
  // MUSIC PAUSE
  // MUSIC RESUME
  // MUSIC STOP
  // MUSIC SEEK numexpr
  // MUSIC VOLUME numexpr

  Result := '';

  If Byte(Tokens[Position]) = SP_KEYWORD Then Begin

    KeyWord := pLongWord(@Tokens[Position +1])^;
    Inc(Position, 1 + SizeOf(LongWord));

    Case KeyWord Of

      SP_KW_PAUSE:  KeyWordID := SP_KW_MUSIC_PAUSE;
      SP_KW_RESUME: KeyWordID := SP_KW_MUSIC_RESUME;
      SP_KW_STOP:   KeyWordID := SP_KW_MUSIC_STOP;

      SP_KW_PLAY:
        Begin

          Result := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit;

          LoopExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);
          PauseExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);
          VolumeExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1);

          While Byte(Tokens[Position]) = SP_KEYWORD Do Begin

            Case pLongWord(@Tokens[Position +1])^ of

              SP_KW_PAUSE:
                Begin
                  PauseExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
                  Inc(Position, SizeOf(LongWord) +1);
                End;

              SP_KW_LOOP:
                Begin
                  LoopExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
                  Inc(Position, SizeOf(LongWord) +1);
                End;

              SP_KW_VOLUME:
                Begin
                  Inc(Position, SizeOf(LongWord) +1);
                  VolumeExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                End;
            Else
              Break;
            End;
          End;

          KeyWordID := SP_KW_MUSIC_PLAY;
          Result := Result + VolumeExpr + PauseExpr + LoopExpr;

        End;

      SP_KW_SEEK, SP_KW_VOLUME:
        Begin

          Result := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
             Error.Code := SP_ERR_MISSING_NUMEXPR;
             Exit;
          End;
          Case KeyWord of
            SP_KW_VOLUME: KeyWordID := SP_KW_MUSIC_VOLUME;
            SP_KW_SEEK: KeyWordID := SP_KW_MUSIC_SEEK;
          End;

        End;

    End;

  End;

End;

Function  SP_Convert_PROC(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Name, Expr, VarList: aString;
  Idx: Integer;
  NamePos, NameLen, NumParams: LongWord;
  ProcType: Byte;
  Symbol: aChar;
  Token: pToken;
Begin

  // PROC {name[(|PROCID(id;[} [([REF] var1[, var2...])]

  Result := '';
  If (Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR]) or ((Byte(Tokens[Position]) = SP_FUNCTION) And
     ((pLongWord(@Tokens[Position +1])^ = SP_FN_PROCID) or (pLongWord(@Tokens[Position +1])^ = SP_FN_PROCIDS))) Then Begin

    // Push the name first.
    If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
      ProcType := Byte(Tokens[Position]);
      Inc(Position);
      NamePos := pLongWord(@Tokens[Position])^;
      Inc(Position, SizeOf(LongWord));
      NameLen := pLongWord(@Tokens[Position])^;
      Inc(Position, SizeOf(LongWord));
      Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
      Inc(Position, NameLen);
      Result := CreateToken(ProcType, NamePos, Length(Name) + SizeOf(LongWord)) + LongWordToString(ProcType) + Name;
      Symbol := '(';
      NumParams := 0;
      If ProcType = SP_STRVAR Then
        Name := Name + '$';
    End Else Begin
      If pLongWord(@Tokens[Position +1])^ = SP_FN_PROCID Then
        Result := CreateToken(SP_NUMVAR, 0, SizeOf(LongWord)) + LongWordToString(0)
      Else
        Result := CreateToken(SP_STRVAR, 0, SizeOf(LongWord)) + LongWordToString(0);
      Inc(Position, 1 + SizeOf(LongWord));
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
        If Error.Code <> SP_ERR_OK Then Exit;
        Result := Expr + Result;
        Symbol := ';';
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
          Inc(Position, 2);
          NumParams := 1;
          Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(NumParams);
          Exit;
        End;
      End Else Begin
        Error.Code := SP_ERR_MISSING_BRACKET;
        Exit;
      End;
      NumParams := 1;
    End;

    // If we're processing for the referenced vars (called by the pre-parser) then set up the varlist for this proc now.

    If ProcListAvailable then Begin
      Idx := 0;
      While Idx <= SP_ProcsListPtr Do Begin
        If SP_ProcsList[Idx].Name = Name Then
          Break
        Else
          Inc(Idx);
      End;
      If Idx = SP_ProcsListPtr +1 Then
        ProcListAvailable := False
      Else
        VarList := SP_ProcsList[Idx].VarTypes;
    End;

    // Now get the parameters, if they exist.

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = Symbol) Then Begin

      Inc(Position, 2);

      While True Do Begin

        If Byte(Tokens[Position]) = SP_KEYWORD Then Begin

          If pLongWord(@Tokens[Position +1])^ = SP_KW_REF Then Begin

            Inc(Position, 1 + SizeOf(LongWord));

            // This is a variable to be passed by reference. Basically, just add it
            // as a variable, and let the interpreter set it up.

            If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin

              Result := SP_Convert_Var_Assign(Tokens, Position, Error) + Result;
              If Error.Code = SP_ERR_OK Then Begin
                Token := @Result[1];
                If Token^.Token in [SP_NUMVAR_LET, SP_STRVAR_LET] Then
                  Dec(Token^.Token, 30)
                Else
                  If Token^.Token = SP_STRUCT_MEMBER_ASS Then
                    Error.Code := SP_ERR_STRUCT_NOT_REF;
                If Error.Code <> SP_ERR_OK Then Exit;
                Inc(NumParams);

                If Byte(Tokens[Position]) = SP_SYMBOL Then Begin
                  Inc(Position);
                  If Tokens[Position] = ')' Then Begin
                    Inc(Position);
                    Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(NumParams);
                    Exit;
                  End Else
                    If Tokens[Position] <> ',' Then Begin
                      Error.Code := SP_ERR_SYNTAX_ERROR;
                      Exit;
                    End;
                  Inc(Position);
                End;
              End Else
                Exit;

            End Else Begin
              Error.Code := SP_ERR_MISSING_VARIABLE;
              Exit;
            End;

          End Else Begin
            Error.Code := SP_ERR_SYNTAX_ERROR;
            Exit;
          End;

        End Else Begin

          If (VarList <> '') And (VarList[NumParams +1] = '!') Then Begin

            // This is a variable to be passed by reference, but as defined by the DEF PROC, not the user.
            // Handle as above.

            If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin

              Result := SP_Convert_Var_Assign(Tokens, Position, Error) + Result;
              If Error.Code = SP_ERR_OK Then Begin
                Token := @Result[1];
                If Token^.Token in [SP_NUMVAR_LET, SP_STRVAR_LET] Then
                  Dec(Token^.Token, 30)
                Else
                  If Token^.Token = SP_STRUCT_MEMBER_ASS Then
                    Error.Code := SP_ERR_STRUCT_NOT_REF;
                If Error.Code <> SP_ERR_OK Then Exit;
                Inc(NumParams);

                If Byte(Tokens[Position]) = SP_SYMBOL Then Begin
                  Inc(Position);
                  If Tokens[Position] = ')' Then Begin
                    Inc(Position);
                    Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(NumParams);
                    Exit;
                  End Else
                    If Tokens[Position] <> ',' Then Begin
                      Error.Code := SP_ERR_SYNTAX_ERROR;
                      Exit;
                    End;
                  Inc(Position);
                End;
              End Else
                Exit;
            End Else Begin
              Error.Code := SP_ERR_MISSING_VARIABLE;
              Exit;
            End;

          End Else Begin

            Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Expr = '' Then Error.Code := SP_ERR_SYNTAX_ERROR;
            If Error.Code <> SP_ERR_OK Then Exit;
            Result := Expr + Result;
            Inc(NumParams);

            If Byte(Tokens[Position]) = SP_SYMBOL Then Begin
              Inc(Position);
              If Tokens[Position] = ')' Then Begin
                Inc(Position);
                Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(NumParams);
                Exit;
              End Else
                If Tokens[Position] <> ',' Then Begin
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
              Inc(Position);
            End;

          End;

        End;

      End;

    End Else

      Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(NumParams);

  End Else Begin

    Error.Code := SP_ERR_INVALID_PROCEDURE_NAME;

  End;

End;

Function SP_Convert_DEF_STRUCT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  LastType, NamePos, NameLen, VarPos: Integer;
  Name, Expr: aString;
Begin

  // DEF STRUCT name(param1[=value],param2,param3$[length]=value$) etc

  Result := '';

  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

    KeyWordID := SP_KW_DEF_STRUCT;
    Inc(Position);
    NamePos := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    NameLen := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
    Inc(Position, NameLen);

    Result := CreateToken(SP_NUMVAR, NamePos, SizeOf(longWord) + Length(Name)) + LongWordToString(0) + Name;

    // Parse the member list.
    // Valid members are:
    // Numeric variable, String variable with optional fixed length in []s.

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin

      Inc(Position, 2);

      While Ord(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Do Begin

        Case Ord(Tokens[Position]) Of

          SP_NUMVAR:
            Begin
              Inc(Position);
              VarPos := pLongWord(@Tokens[Position])^;
              Inc(Position, SizeOf(LongWord));
              NameLen := pLongWord(@Tokens[Position])^;
              Inc(Position, SizeOf(LongWord));
              Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
              Inc(Position, NameLen);
              Result := CreateToken(SP_NUMVAR, VarPos, SizeOf(LongWord)+Length(Name)) + LongWordToString(0) + Name + Result;
              LastType := SP_VALUE;
            End;
          SP_STRVAR:
            Begin
              Inc(Position);
              VarPos := pLongWord(@Tokens[Position])^;
              Inc(Position, SizeOf(LongWord));
              NameLen := pLongWord(@Tokens[Position])^;
              Inc(Position, SizeOf(LongWord));
              Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
              Inc(Position, NameLen);
              Result := CreateToken(SP_STRVAR, VarPos, SizeOf(LongWord)+Length(Name)) + LongWordToString(0) + Name + Result;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '[') Then Begin
                Inc(Position, 2);
                Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
                If Error.Code <> SP_ERR_OK Then
                  Exit;
                If Not (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ']') Then Begin
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End Else
                  Inc(Position, 2);
              End;
              LastType := SP_STRING;
            End;

        Else
          Begin
            Error.Code := SP_ERR_SYNTAX_ERROR;
            Exit;
          End;
        End;

        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '=') Then Begin
            Inc(Position, 2);
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then
              Exit
            Else
              If Error.ReturnType <> LastType Then Begin
                Error.Code := SP_ERR_SYNTAX_ERROR;
                Exit;
              End Else
                Result := Expr + Result;
        End;

        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
          Inc(Position, 2)
        Else Begin
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin
            Inc(Position, 2);
            Exit;
          End Else
            Error.Code := SP_ERR_MISSING_BRACKET;
          Exit;
        End;

      End;

    End Else

      Error.Code := SP_ERR_SYNTAX_ERROR;

  End Else

    Error.Code := SP_ERR_INVALID_STRUCTURE_NAME;

End;

Function  SP_Convert_DEF_PROC(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  NameLen, NamePos: LongWord;
  Name: aString;
  ProcType: aChar;
Begin

  // DEF PROC name [([REF] var1[, var 2...])]

  Result := '';

  // Pick up the name - will appear as a numvar/strvar in the tokenised BASIC

  If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin

    // Skip the numvar (name of the procedure). Because we're only tokenising to p-code for
    // runtime evaluation, there is none to be done here - we just want to skip it. Hence,
    // We check possible parameters for validity, but only tell the interpreter to jump to the
    // statement after the ENDPROC.

    KeyWordID := SP_KW_DEF_PROC;
    ProcType := Tokens[Position];
    Inc(Position);
    NamePos := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    NameLen := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
    Inc(Position, NameLen);

    Result := CreateToken(Byte(ProcType), NamePos, Length(Name) + SizeOf(LongWord)) + LongWordToString(Ord(ProcType)) + Name;

    // Now check for and parse the parameter list if it exists.

    If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = '(') Then Begin

      Inc(Position, 2);
      if (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = ')') Then
        Inc(Position, 2)
      Else
        While True Do Begin

          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_REF) Then Begin
            Inc(Position, 1 + SizeOf(longWord));
          End;

          If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
            Inc(Position, 1 + (SizeOf(LongWord)*2) + pLongWord(@Tokens[Position +1 + SizeOf(LongWord)])^);
            If Byte(Tokens[Position]) = SP_SYMBOL Then
              If Tokens[Position +1] = ')' Then Begin
                Inc(Position, 2);
                Exit
              End Else
                If Tokens[Position +1] <> ',' Then Begin
                  Error.Code := SP_ERR_MISSING_COMMA;
                  Exit;
                End Else
                  Inc(Position, 2);
          End Else Begin
            Error.Code := SP_ERR_MISSING_VARIABLE;
            Exit;
          End;

        End;

    End;

  End Else

    Error.Code := SP_ERR_INVALID_PROCEDURE_NAME;

End;

Function  SP_Convert_END_PROC(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // END PROC - no parameters.

  Result := '';

End;

Function  SP_Convert_EXIT_PROC(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // EXIT PROC - no parameters.

  Result := '';

End;

Function  SP_Convert_GLOBAL(Var Tokens: aString; Var Position: Integer; Var KeyWordID: LongWord; Var Error: TSP_ErrorCode): aString;
Var
  VarType: Byte;
  VarLen, VarCount: LongWord;
  VarName, Expr, VarExpr: aString;
  Done: Boolean;
Begin

  // LOCAL numvar[=value]|strvar[=value$][,...]
  // GLOBAL numvar[=value]|strvar[=value$][,...]

  Result := '';
  Done := False;
  VarCount := 0;

  While Not Done Do Begin

    VarExpr := '';
    VarType := Byte(Tokens[Position]);

    If VarType in [SP_NUMVAR, SP_STRVAR] Then Begin

      If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

        Inc(Position, 1 + SizeOf(LongWord));
        VarLen := pLongWord(@Tokens[Position])^;
        Inc(Position, SizeOf(LongWord));
        VarName := LowerNoSpaces(Copy(Tokens, Position, VarLen));
        Inc(Position, VarLen);
        Inc(VarCount);

        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '=') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then
            Exit
          Else
            If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
          VarExpr := VarExpr + Expr;
        End;

        VarExpr := VarExpr + CreateToken(SP_NUMVAR, 0, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;

      End Else

        If Byte(Tokens[Position]) = SP_STRVAR Then Begin

          Inc(Position, 1 + SizeOf(LongWord));
          VarLen := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
          VarName := LowerNoSpaces(Copy(Tokens, Position, VarLen));
          Inc(Position, VarLen);
          Inc(VarCount);

          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '=') Then Begin
            Inc(Position, 2);
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then
              Exit
            Else
              If Error.ReturnType <> SP_STRING Then Begin
                Error.Code := SP_ERR_MISSING_STREXPR;
                Exit;
              End;
            VarExpr := VarExpr + Expr;
          End;

          VarExpr := VarExpr + CreateToken(SP_STRVAR, 0, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;

        End;

      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        VarType := Byte(Tokens[Position]);
        If Not (VarType in [SP_NUMVAR, SP_STRVAR]) Then Begin
          Error.Code := SP_ERR_MISSING_VARIABLE;
          Exit;
        End;
      End Else
        Done := True;

    End Else Begin

      If VarCount = 0 Then
        Error.Code := SP_ERR_MISSING_VARIABLE;
      Done := True;

    End;

    Result := Result + VarExpr + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(KeywordID);

  End;

  KeyWordID := 0;

End;

Function SP_Convert_DEF_FN(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  FnType, VarType: aChar;
  Name, FnExpr: aString;
  NameLen, VarCount: LongWord;
Begin

  // DEF FN numvar[(num/strvar[,num/strvar...])] = Expr

  Result := '';
  If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin

    // Pick up the name of the function

    FnType := Tokens[Position];
    Inc(Position, SizeOf(LongWord)+1);
    NameLen := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
    Inc(Position, NameLen);
    Result := CreateToken(Byte(FnType), Position, Length(Name) + SizeOf(LongWord)) + LongWordToString(0) + Name;

    // Now check for and parse the parameter list if it exists.

    VarCount := 0;
    If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = '(') Then Begin

      Inc(Position, 2);
      if (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = ')') Then
        Inc(Position, 2)
      Else
        While True Do Begin

          If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
            VarType := Tokens[Position];
            Inc(Position, SizeOf(LongWord)+1);
            NameLen := pLongWord(@Tokens[Position])^;
            Inc(Position, SizeOf(LongWord));
            Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
            Inc(Position, NameLen);
            Result := CreateToken(Byte(VarType), Position, Length(Name) + SizeOf(LongWord)) + LongWordToString(0) + Name + Result;
            Inc(VarCount);
            If Byte(Tokens[Position]) = SP_SYMBOL Then
              If Tokens[Position +1] = ')' Then Begin
                Inc(Position, 2);
                Break;
              End Else
                If Tokens[Position +1] <> ',' Then Begin
                  Error.Code := SP_ERR_MISSING_COMMA;
                  Exit;
                End Else
                  Inc(Position, 2);
          End Else Begin
            Error.Code := SP_ERR_MISSING_VARIABLE;
            Exit;
          End;

        End;

    End;

    Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(VarCount);

    // Now parse and convert the expression.

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '=') Then Begin

      Inc(Position, 2);
      FnExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then
        Exit
      Else
        If ((Error.ReturnType = SP_VALUE) And (Byte(FnType) <> SP_NUMVAR)) or ((Error.ReturnType = SP_STRING) And (Byte(FnType) <> SP_STRVAR)) Then Begin
          Error.Code := SP_ERR_INVALID_FUNCTION_TYPE;
          Exit;
        End Else Begin
          SP_RemoveBlocks(FnExpr);
          SP_TestConsts(FnExpr, 1, Error, False);
          SP_AddHandlers(FnExpr);
          Result := Result + CreateToken(SP_STRING, 0, Length(FnExpr)) + FnExpr;
        End;

    End Else
      Error.Code := SP_ERR_MISSING_EQU;

  End Else
    Error.Code := SP_ERR_INVALID_FUNCTION_NAME;

End;

Function  SP_Convert_CAT(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // CAT [strexpr] [EXP] [ALL]

  Result := '';
  If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_EXP) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));
    Result := CreateToken(SP_STRING, 0, 0) + '' + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1);

  End Else Begin

    Result := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code = SP_ERR_OK Then Begin
      If Result = '' Then
        Result := CreateToken(SP_STRING, 0, 0)
      Else
        If Error.ReturnType <> SP_STRING Then Begin
          Error.Code := SP_ERR_MISSING_STREXPR;
          Exit;
        End;
    End Else
      Exit;

    If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_EXP) Then Begin
      Inc(Position, 1+SizeOf(LongWord));
      Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1);
    End Else
      Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);

  End;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ALL) Then Begin
    Inc(Position, 1+SizeOf(LongWord));
    Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1);
  End Else
    Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);

End;

Function  SP_Convert_ERASE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // ERASE [DIR] [pathstr]/filespec [ALL]

  Result := '';
  If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_DIR) Then Begin
    Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1);
    Inc(Position, 1 + SizeOf(LongWord));
  End Else
    Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);

  Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // File or Dir spec
  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Error.ReturnType <> SP_STRING Then Begin
      Error.Code := SP_ERR_MISSING_STREXPR;
      Exit;
    End;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ALL) Then Begin
    Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1) + Result;
    Inc(Position, 1 + SizeOf(LongWord));
  End Else
    Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0) + Result;

End;

Function  SP_Convert_SPRITE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr, VarResult, ColExpr, CopyExpr: aString;
  KeyWordPos: LongWord;
Begin

  // SPRITE NEW numvar,x,y [COPY id] [COLLIDE] [OVER mode] [WRAP [TO CLIP]]}
  // SPRITE COLLIDE CLEAR
  // SPRITE ADDFRAME id,{gfx$|GRAPHIC n}
  // SPRITE SHOW id
  // SPRITE HIDE id
  // SPRITE MOVE id {,dx,dy|TO dx,dy} [STEP px|FRAMES n]
  // SPRITE MOVE id TO WINDOW n
  // SPRITE STOP id
  // SPRITE ROTATE id{,a| TO angle} [FRAMES t]
  // SPRITE SCALE id,factor [FRAMES t]
  // SPRITE CLONE id,x,y
  // SPRITE CLONE MOVE id,index TO x,y
  // SPRITE CLONE ERASE id,index
  // SPRITE POINT id,x,y
  // SPRITE ANIM PLAY id[,n[ TO m]] [OPTION p]
	// SPRITE ANIM STOP id
	// SPRITE FRAME id,n [PAUSE m]
	// SPRITE MIRROR id
	// SPRITE FLIP id
  // SPRITE PUT id
  // SPRITE OVER id,mode
  // SPRITE FRONT id[,add]
  // SPRITE BACK id[,dec]

  Result := '';

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_NEW) Then Begin

    KeyWordPos := Position;
    Inc(Position, 1 + SizeOf(LongWord));

    If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

      VarResult := SP_Convert_Var_Assign(Tokens, Position, Error);
      If Error.Code <> SP_ERR_OK Then Exit;

      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // X
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End Else Begin

            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_COPY) Then Begin
              Inc(Position, SizeOf(LongWord) +1);
              CopyExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
            End Else
              CopyExpr := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(-1);

            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_COLLIDE) Then Begin
              Inc(Position, SizeOf(LongWord) +1);
              ColExpr := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1);
            End Else
              ColExpr := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);

            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OVER) Then Begin
              Inc(Position, SizeOf(LongWord) +1);
              ColExpr := SP_Convert_Expr(Tokens, Position, Error, -1) + ColExpr;
            End Else
              ColExpr := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(-1) + ColExpr;

            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_WRAP) Then Begin
              Inc(Position, 1 + SizeOf(LongWord));
              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_WINDOW) Then Begin
                Inc(Position, 1 + SizeOf(LongWord));
                ColExpr := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1) + ColExpr;
              End Else
                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CLIP) Then Begin
                  Inc(Position, 1 + SizeOf(LongWord));
                  ColExpr := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(2) + ColExpr;
                End Else Begin
                  Error.Code := SP_ERR_SYNTAX_ERROR;
                  Exit;
                End;
            End Else
              ColExpr := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(-1) + ColExpr;

            Result := CopyExpr + ColExpr + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_NEW_SPRITE) + VarResult;
            If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;

          End;
        End Else
          Error.Code := SP_ERR_MISSING_COMMA;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;
    End Else
      Error.Code := SP_ERR_MISSING_VARIABLE;

  End Else

    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ADDFRAME) Then Begin

      Inc(Position, 1 + SizeOf(LongWord));

      Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // id
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);

        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Graphic ID
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
        End Else Begin
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // strexpr | GRAPHIC gfx-id
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_STRING Then Begin
            Error.Code := SP_ERR_MISSING_STREXPR;
            Exit;
          End;
        End;

        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_PAUSE) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Delay
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
        End Else
          Expr := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1) + Expr;
        KeyWordID := SP_KW_SPRITE_ADDFR;
        Result := Expr;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;

    End Else

      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SHOW) Then Begin

        Inc(Position, 1 + SizeOf(LongWord));

        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // id
        If Error.Code <> SP_ERR_OK Then Exit Else
          If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
        KeyWordID := SP_KW_SPRITE_SHOW;
        Result := Expr;

      End Else

        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_HIDE) Then Begin

          Inc(Position, 1 + SizeOf(LongWord));

          Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // id
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          KeyWordID := SP_KW_SPRITE_HIDE;
          Result := Expr;

        End Else

          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_MOVE) Then Begin

            Inc(Position, 1 + SizeOf(LongWord));
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // id
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;

            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
              Inc(Position, 1 + SizeOf(LongWord));
              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_WINDOW) Then Begin
                Inc(Position, 1 + SizeOf(LongWord));
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // WindowID
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                KeyWordID := SP_KW_SPRITE_MOVE_WIN;
              End Else Begin
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // dstx
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                  Inc(Position, 2);
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // dsty
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  KeyWordID := SP_KW_SPRITE_MOVED;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_COMMA;
                  Exit;
                End;
              End;
            End Else Begin
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // dx
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                  Inc(Position, 2);
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // dy
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  KeyWordID := SP_KW_SPRITE_MOVE;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_COMMA;
                  Exit;
                End;
              End Else Begin
                Error.Code := SP_ERR_MISSING_COMMA;
                Exit;
              End;
            End;
            If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_FRAMES) Then Begin
              Inc(Position, SizeOf(LongWord) +1);
              Inc(KeyWordID, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Frames-time
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
            End Else
              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_STEP) Then Begin
                Inc(Position, SizeOf(LongWord) +1);
                Inc(KeyWordID, 4);
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Step value in pixels
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
              End;
            Result := Expr;

          End Else

            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_STOP) Then Begin

              Inc(Position, 1 + SizeOf(LongWord));
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Sprite ID
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              KeyWordID := SP_KW_SPRITE_STOP;
              Result := Expr;

            End Else

              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ROTATE) Then Begin

                Inc(Position, 1 + SizeOf(LongWord));
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Sprite ID
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                  Inc(Position, 2);
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // angle delta
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  KeyWordID := SP_KW_SPRITE_ROT;
                End Else Begin
                  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
                    Inc(Position, SizeOf(LongWord)+1);
                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // dest angle
                    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                    KeyWordID := SP_KW_SPRITE_ROT_TO;
                  End Else Begin
                    Error.Code := SP_ERR_SYNTAX_ERROR;
                    Exit;
                  End;
                End;
                If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_FRAMES) Then Begin
                  Inc(Position, SizeOf(LongWord)+1);
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Frame-time value
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  If KeyWordID = SP_KW_SPRITE_ROT_TO Then Begin
                    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CW) Then Begin
                      Inc(Position, SizeOf(LongWord)+1);
                      Expr := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1) + Expr;
                    End Else
                      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CCW) Then Begin
                        Inc(Position, SizeOf(LongWord)+1);
                        Expr := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(-1) + Expr;
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_DIRECTION;
                        Exit;
                      End;
                  End;
                  Inc(KeyWordID, 2);
                End;
                Result := Expr;

              End Else

                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SCALE) Then Begin

                  Inc(Position, 1 + SizeOf(LongWord));
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Sprite ID
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Scale value
                    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                    KeyWordID := SP_KW_SPRITE_SCALE;
                    If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_FRAMES) Then Begin
                      Inc(Position, 1 + SizeOf(LongWord));
                      Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Frame count
                      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                      KeyWordID := SP_KW_SPRITE_SCALE_T;
                    End;
                    Result := Expr;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;

                End Else

                  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ERASE) Then Begin

                    Inc(Position, 1 + SizeOf(LongWord));
                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Sprite ID
                    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                    KeyWordID := SP_KW_SPRITE_ERASE;
                    Result := Expr;

                  End Else

                    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CLEAR) Then Begin

                      Inc(Position, 1 + SizeOf(LongWord));
                      Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Sprite ID
                      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                      KeyWordID := SP_KW_SPRITE_CLEAR;
                      Result := Expr;

                    End Else

                      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CLONE) Then Begin
                        Inc(Position, 1 + SizeOf(LongWord));

                        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ERASE) Then Begin

                          Inc(Position, 1 + SizeOf(LongWord));
                          Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Sprite ID
                          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                            Error.Code := SP_ERR_MISSING_NUMEXPR;
                            Exit;
                          End;
                          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                            Inc(Position, 2);
                            Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Index
                            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                              Error.Code := SP_ERR_MISSING_NUMEXPR;
                              Exit;
                            End;
                            Result := Expr;
                            KeyWordID := SP_KW_SPRITE_CLONE_ERASE;
                          End Else Begin
                            Error.Code := SP_ERR_MISSING_COMMA;
                            Exit;
                          End;

                        End Else

                          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_MOVE) Then Begin

                            Inc(Position, 1 + SizeOf(LongWord));
                            Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Sprite ID
                            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                              Error.Code := SP_ERR_MISSING_NUMEXPR;
                              Exit;
                            End;
                            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                              Inc(Position, 2);
                              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Index
                              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                Error.Code := SP_ERR_MISSING_NUMEXPR;
                                Exit;
                              End;
                              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
                                Inc(Position, 1 + SizeOf(LongWord));
                                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // X
                                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                                  Exit;
                                End;
                                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                  Inc(Position, 2);
                                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y
                                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                                    Exit;
                                  End;
                                  Result := Expr;
                                  KeyWordID := SP_KW_SPRITE_CLONE_MOVE;
                                End Else Begin
                                  Error.Code := SP_ERR_MISSING_COMMA;
                                  Exit;
                                End;
                              End Else Begin
                                Error.Code := SP_ERR_MISSING_TO;
                                Exit;
                              End;
                            End Else Begin
                              Error.Code := SP_ERR_MISSING_COMMA;
                              Exit;
                            End;

                          End Else Begin

                            Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Sprite ID
                            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                              Error.Code := SP_ERR_MISSING_NUMEXPR;
                              Exit;
                            End;
                            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                              Inc(Position, 2);
                              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // X
                              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                Error.Code := SP_ERR_MISSING_NUMEXPR;
                                Exit;
                              End;
                              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                Inc(Position, 2);
                                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y
                                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                                  Exit;
                                End;
                                Result := Expr;
                                KeyWordID := SP_KW_SPRITE_CLONE;
                              End Else Begin
                                Error.Code := SP_ERR_MISSING_COMMA;
                                Exit;
                              End;
                            End Else Begin
                              Error.Code := SP_ERR_MISSING_COMMA;
                              Exit;
                            End;
                        End;

                      End Else

                        If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_POINT) Then Begin

                          Inc(Position, 1 + SizeOf(LongWord));
                          Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Sprite ID
                          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                            Error.Code := SP_ERR_MISSING_NUMEXPR;
                            Exit;
                          End;
                          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                            Inc(Position, 2);
                            Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // X
                            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                              Error.Code := SP_ERR_MISSING_NUMEXPR;
                              Exit;
                            End;
                            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                              Inc(Position, 2);
                              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y
                              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                Error.Code := SP_ERR_MISSING_NUMEXPR;
                                Exit;
                              End;
                              Result := Expr;
                              KeyWordID := SP_KW_SPRITE_POINT;
                              Exit;
                            End Else Begin
                              Error.Code := SP_ERR_MISSING_COMMA;
                              Exit;
                            End;
                          End Else Begin
                            Error.Code := SP_ERR_MISSING_COMMA;
                            Exit;
                          End;

                        End Else

                          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ANIM) Then Begin

                            Inc(Position, SizeOf(LongWord) +1);
                            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_PLAY) Then Begin

                              Inc(Position, 1 + SizeOf(LongWord));
                              Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Sprite ID
                              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                Error.Code := SP_ERR_MISSING_NUMEXPR;
                                Exit;
                              End;

                              If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = ',') Then Begin
                                Inc(Position, 2);
                                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // n
                                If Error.Code <> SP_ERR_OK Then
                                  Exit
                                Else
                                  If Error.ReturnType <> SP_VALUE Then Begin
                                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                                    Exit;
                                  End;
                                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
                                  Inc(Position, SizeOf(LongWord) +1);
                                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // TO m
                                  If Error.Code <> SP_ERR_OK Then
                                    Exit
                                  Else
                                    If Error.ReturnType <> SP_VALUE Then Begin
                                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                                      Exit;
                                    End;
                                  End;
                              End;

                              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OPTION) Then Begin
                                Inc(Position, SizeOf(LongWord) +1);
                                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // OPTION p
                                If Error.Code <> SP_ERR_OK Then
                                  Exit
                                Else
                                  If Error.ReturnType <> SP_VALUE Then Begin
                                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                                    Exit;
                                  End;
                              End;

                              KeyWordID := SP_KW_SPRITE_SET_ANIM;
                              Result := Expr;
                              Exit;

                            End Else

                              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_STOP) Then Begin

                                Inc(Position, 1 + SizeOf(LongWord));
                                Result := SP_Convert_Expr(Tokens, Position, Error, -1); // id
                                If Error.Code <> SP_ERR_OK Then
                                  Exit
                                Else
                                  If Error.ReturnType <> SP_VALUE Then Begin
                                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                                    Exit;
                                  End;

                                KeyWordID := SP_KW_SPRITE_ANIM_STOP;
                                Exit;

                              End;

                          End Else

                            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FRAME) Then Begin

                              Inc(Position, 1 + SizeOf(LongWord));
                              Result := SP_Convert_Expr(Tokens, Position, Error, -1); // id
                              If Error.Code <> SP_ERR_OK Then
                                Exit
                              Else
                                If Error.ReturnType <> SP_VALUE Then Begin
                                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                                  Exit;
                                End Else
                                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                    Inc(Position, 2);
                                    Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // frame number
                                    If Error.Code <> SP_ERR_OK Then
                                      Exit
                                    Else
                                      If Error.ReturnType <> SP_VALUE Then Begin
                                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                                        Exit;
                                      End Else
                                        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_PAUSE) Then Begin
                                          Inc(Position, 1 + SizeOf(LongWord));
                                          Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Delay in frames
                                          If Error.Code <> SP_ERR_OK Then
                                            Exit
                                          Else
                                            If Error.ReturnType <> SP_VALUE Then Begin
                                              Error.Code := SP_ERR_MISSING_NUMEXPR;
                                              Exit;
                                            End;
                                        End;
                                  End Else Begin
                                    Error.Code := SP_ERR_MISSING_COMMA;
                                    Exit;
                                  End;

                              KeyWordID := SP_KW_SPRITE_FRAME;
                              Exit;

                            End Else

                              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_MIRROR) Then Begin

                                Inc(Position, 1 + SizeOf(LongWord));
                                Result := SP_Convert_Expr(Tokens, Position, Error, -1); // id
                                If Error.Code <> SP_ERR_OK Then
                                  Exit
                                Else
                                  If Error.ReturnType <> SP_VALUE Then Begin
                                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                                    Exit;
                                  End;

                                KeyWordID := SP_KW_SPRITE_MIRROR;
                                Exit;

                              End Else

                                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FLIP) Then Begin

                                  Inc(Position, 1 + SizeOf(LongWord));
                                  Result := SP_Convert_Expr(Tokens, Position, Error, -1); // id
                                  If Error.Code <> SP_ERR_OK Then
                                    Exit
                                  Else
                                    If Error.ReturnType <> SP_VALUE Then Begin
                                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                                      Exit;
                                    End;

                                  KeyWordID := SP_KW_SPRITE_FLIP;
                                  Exit;

                                End Else

                                  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_PUT) Then Begin

                                    Inc(Position, 1 + SizeOf(LongWord));
                                    Result := SP_Convert_Expr(Tokens, Position, Error, -1); // id.
                                    If Error.Code <> SP_ERR_OK Then
                                      Exit
                                    Else
                                      If Error.ReturnType <> SP_VALUE Then Begin
                                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                                        Exit;
                                      End;

                                    KeyWordID := SP_KW_SPRITE_PUT;
                                    Exit;

                                  End Else

                                    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_COLLIDE) Then Begin

                                      Inc(Position, 1 + SizeOf(LongWord));

                                      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CLEAR) Then Begin

                                        Inc(Position, 1 + SizeOf(LongWord));

                                        Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Id.
                                        If Result <> '' Then Begin
                                          If Error.Code <> SP_ERR_OK Then
                                            Exit
                                          Else
                                            If Error.ReturnType <> SP_VALUE Then Begin
                                              Error.Code := SP_ERR_MISSING_NUMEXPR;
                                              Exit;
                                            End Else
                                              KeyWordID := SP_KW_SPRITE_COLL_CLR_ID;
                                        End Else
                                          KeyWordID := SP_KW_SPRITE_COLLIDE_CLEAR;

                                        Exit;

                                      End Else Begin
                                        Error.Code := SP_ERR_SYNTAX_ERROR;
                                        Exit;
                                      End;

                                    End Else

                                      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OVER) Then Begin

                                        Inc(Position, 1 + SizeOf(LongWord));
                                        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Sprite ID
                                        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                                          Exit;
                                        End;
                                        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                          Inc(Position, 2);
                                          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Over mode
                                          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                            Error.Code := SP_ERR_MISSING_NUMEXPR;
                                            Exit;
                                          End;
                                          Result := Expr;
                                          KeyWordID := SP_KW_SPRITE_OVER;
                                          Exit;
                                        End Else Begin
                                          Error.Code := SP_ERR_MISSING_COMMA;
                                          Exit;
                                        End;

                                      End Else

                                        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FRONT) Then Begin

                                          Inc(Position, 1 + SizeOf(LongWord));
                                          Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Sprite ID
                                          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                            Error.Code := SP_ERR_MISSING_NUMEXPR;
                                            Exit;
                                          End;
                                          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                            // Possible movement amount
                                            Inc(Position, 2);
                                            Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr;
                                            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                              Error.Code := SP_ERR_MISSING_NUMEXPR;
                                              Exit;
                                            End;
                                            Result := Expr;
                                            KeyWordID := SP_KW_SPRITE_FRONT_ADD;
                                          End Else Begin
                                            Result := Expr;
                                            KeyWordID := SP_KW_SPRITE_FRONT;
                                          End;
                                          Exit;

                                        End Else

                                          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_BACK) Then Begin

                                            Inc(Position, 1 + SizeOf(LongWord));
                                            Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Sprite ID
                                            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                              Error.Code := SP_ERR_MISSING_NUMEXPR;
                                              Exit;
                                            End;
                                            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                              // Possible movement amount
                                              Inc(Position, 2);
                                              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr;
                                              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                                Error.Code := SP_ERR_MISSING_NUMEXPR;
                                                Exit;
                                              End;
                                              Result := Expr;
                                              KeyWordID := SP_KW_SPRITE_BACK_DEC;
                                            End Else Begin
                                              Result := Expr;
                                              KeyWordID := SP_KW_SPRITE_BACK;
                                            End;

                                          End;

End;

Function  SP_Convert_GRAPHIC(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  KeyWordPos, PosSave: LongWord;
  VarResult, Expr, ScaleExpr, RotateExpr: aString;
  GotScale, GotRotate: Boolean;
Begin

  // GRAPHIC NEW numvar{,Width,Height|LOAD filename$|,gfx$} [TRANSPARENT index]
  // GRAPHIC LOAD id,filename$ [TRANSPARENT index]
  // GRAPHIC GRAB str$,id,x,y,w,h [TRANSPARENT index]
  // GRAPHIC PUT {strvar|GRAPHIC n},n,x,y[,ROTATE a][,SCALE n]
  // GRAPHIC ROTATE n,rot
  // GRAPHIC SCALE n{,sx[,sy]| TO sx,sy}
  // GRAPHIC ROLL id,dx,dy
  // GRAPHIC SCROLL id,dx,dy
  // GRAPHIC PALETTE [HSV] <n,index,<r,g,b|RGB>|DEFAULT>
  // GRAPHIC REMAP n
  // GRAPHIC ORIGIN id{,x1,y1 TO x2,y2|OFF}
  // GRAPHIC CLIP id{,x1,y1 TO x2,y2|OFF}
  // GRAPHIC FLIP id|gfx$
  // GRAPHIC MIRROR id|gfx$

  Result := '';
  Expr := '';

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_NEW) Then Begin

    KeyWordPos := Position;
    Inc(Position, 1 + SizeOf(LongWord));

    If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

      VarResult := SP_Convert_Var_Assign(Tokens, Position, Error);
      If Error.Code <> SP_ERR_OK Then Exit;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Width or Gfx$
        If Error.Code <> SP_ERR_OK Then
          Exit
        Else
          If Error.ReturnType = SP_VALUE Then Begin
            // Was Width - check for ",Height"
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr;
              If Error.Code <> SP_ERR_OK Then Exit;
              If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End Else Begin
                KeyWordID := SP_KW_GFX_NEW_SIZE;
              End;
            End Else Begin
              Error.Code := SP_ERR_MISSING_COMMA;
              Exit;
            End;
          End Else Begin
            KeyWordID := SP_KW_GFX_NEW_GFXS;
          End;
      End Else
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_LOAD) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr;
          If Error.Code <> SP_ERR_OK Then Exit;
          If Error.ReturnType <> SP_STRING Then Begin
            Error.Code := SP_ERR_MISSING_STREXPR;
            Exit;
          End Else Begin
            KeyWordID := SP_KW_GFX_NEW_LOAD;
          End;
        End Else
          Error.Code := SP_ERR_SYNTAX_ERROR;
      If KeyWordID <> SP_KW_GFX_NEW_GFXS Then
        If (Byte(Tokens[Position]) = SP_KEYWORD) And ((pLongWord(@Tokens[Position +1])^ = SP_KW_TRANSPARENT) or (pLongWord(@Tokens[Position +1])^ = SP_KW_TRANS)) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr;
          If Error.Code <> SP_ERR_OK Then Exit;
          If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
        End Else
          Expr := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(-1) + Expr;
      Result := Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWordID) + VarResult;
      If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
    End Else
      Error.Code := SP_ERR_MISSING_VARIABLE;

  End Else

    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_LOAD) Then Begin

      Inc(Position, 1 + SizeOf(LongWord));
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Id
      If Error.Code <> SP_ERR_OK Then Exit;
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // filename$
        If Error.Code <> SP_ERR_OK Then Exit;
        If Error.ReturnType <> SP_STRING Then Begin
          Error.Code := SP_ERR_MISSING_STREXPR;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_KEYWORD) And ((pLongWord(@Tokens[Position +1])^ = SP_KW_TRANSPARENT) or (pLongWord(@Tokens[Position +1])^ = SP_KW_TRANS)) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr;
          If Error.Code <> SP_ERR_OK Then Exit;
          If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
        End Else
          Expr := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(-1) + Expr;
        Result := Expr;
        KeyWordID := SP_KW_GFX_LOAD;
      End Else Begin
        Error.Code := SP_ERR_MISSING_COMMA;
        Exit;
      End;

    End Else

      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAB) Then Begin

        Inc(Position, 1 + SizeOf(LongWord));

        If Byte(Tokens[Position]) = SP_STRVAR Then Begin

          VarResult := SP_Convert_Var_Assign(Tokens, Position, Error);
          If Error.Code <> SP_ERR_OK Then Exit;
          KeyWordPos := Position -1;

          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Id
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // X
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                  Inc(Position, 2);
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // W
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // H
                    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                    If (Byte(Tokens[Position]) = SP_KEYWORD) And ((pLongWord(@Tokens[Position +1])^ = SP_KW_TRANSPARENT) or (pLongWord(@Tokens[Position +1])^ = SP_KW_TRANS)) Then Begin
                      Inc(Position, 1 + SizeOf(LongWord));
                      Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Transparent Index
                      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    End Else
                      Expr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1) + Expr;
                    Result := Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_GFX_GRAB)+ VarResult;
                    If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
                    Exit;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_COMMA;
                  Exit;
                End;
              End Else Begin
                Error.Code := SP_ERR_MISSING_COMMA;
                Exit;
              End;
            End Else Begin
              Error.Code := SP_ERR_MISSING_COMMA;
              Exit;
            End;
          End Else Begin
            Error.Code := SP_ERR_MISSING_COMMA;
            Exit;
          End;
        End Else Begin
          Error.Code := SP_ERR_MISSING_VARIABLE;
          Exit;
        End;

      End Else

        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_PUT) Then Begin

          Inc(Position, 1 + SizeOf(LongWord));
          KeyWordID := SP_KW_GFX_PUT;
          GotRotate := False;
          GotScale := False;
          ScaleExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
          RotateExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
            Inc(Position, 1 + SizeOf(LongWord));
            VarResult := SP_Convert_Expr(Tokens, Position, Error, -1); // Graphic ID
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
          End Else Begin
            VarResult := SP_Convert_Expr(Tokens, Position, Error, -1); // strexpr | GRAPHIC gfx-id
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_STRING Then Begin
              Error.Code := SP_ERR_MISSING_STREXPR;
              Exit;
            End;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // N
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // X
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                While True Do Begin
                  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ROTATE) Then Begin
                    Inc(Position, SizeOf(LongWord) +1);
                    RotateExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                    GotRotate := True;
                  End Else
                    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SCALE) Then Begin
                      Inc(Position, SizeOf(LongWord) +1);
                      ScaleExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                      GotScale := True;
                    End Else
                      Break;
                End;
                If GotScale or GotRotate Then Begin
                  Expr := ScaleExpr + RotateExpr + Expr;
                  KeyWordID := SP_KW_GFX_PUT_EX;
                End;
                Result := VarResult + Expr;
                Exit;
              End Else Begin
                Error.Code := SP_ERR_MISSING_COMMA;
                Exit;
              End;
            End Else Begin
              Error.Code := SP_ERR_MISSING_COMMA;
              Exit;
            End;
          End Else Begin
            Error.Code := SP_ERR_MISSING_COMMA;
            Exit;
          End;

        End Else

          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ROTATE) Then Begin

            Inc(Position, SizeOf(LongWord) +1);
            Result := SP_Convert_Expr(Tokens, Position, Error, -1); // ID
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Angle
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              KeyWordID := SP_KW_GFX_ROTATE;
            End Else Begin
              Error.Code := SP_ERR_MISSING_COMMA;
              Exit;
            End;

          End Else

            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SCALE) Then Begin

              Inc(Position, SizeOf(LongWord) +1);
              Result := SP_Convert_Expr(Tokens, Position, Error, -1); // ID
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Factor (x)
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                  Inc(Position, 2);
                  Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Factor y
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  KeyWordID := SP_KW_GFX_SCALE_XY;
                End Else Begin
                  KeyWordID := SP_KW_GFX_SCALE;
                  Exit;
                End;
              End Else
                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
                  Inc(Position, SizeOf(LongWord) +1);
                  Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Factor (x)
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Factor y
                    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                    KeyWordID := SP_KW_GFX_SCALE_TO;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End;
            End Else

              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FLIP) Then Begin

                KeyWordPos := Position;
                Inc(Position, SizeOf(LongWord) +1);
                If Byte(Tokens[Position]) = SP_STRVAR Then Begin
                  PosSave := Position;
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_STRING Then Begin
                    Error.Code := SP_ERR_SYNTAX_ERROR;
                    Exit;
                  End;
                  Position := PosSave;
                  VarResult := SP_Convert_Var_Assign(Tokens, Position, Error);
                  If Error.Code = SP_ERR_OK Then Begin
                    Result := Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_GFX_FLIP_STR) + VarResult;
                    If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
                  End Else
                    Exit;
                End Else Begin
                  Result := SP_Convert_Expr(Tokens, Position, Error, -1); // ID
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  KeyWordID := SP_KW_GFX_FLIP;
                End;

              End Else

                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_MIRROR) Then Begin

                  Inc(Position, SizeOf(LongWord) +1);
                  If Byte(Tokens[Position]) = SP_STRVAR Then Begin
                    PosSave := Position;
                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_STRING Then Begin
                      Error.Code := SP_ERR_SYNTAX_ERROR;
                      Exit;
                    End;
                    Position := PosSave;
                    VarResult := SP_Convert_Var_Assign(Tokens, Position, Error);
                    If Error.Code = SP_ERR_OK Then Begin
                      Result := Expr + CreateToken(SP_KEYWORD, PosSave, SizeOf(LongWord)) + LongWordToString(SP_KW_GFX_MIRROR_STR) + VarResult;
                      If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
                    End Else
                      Exit;
                  End Else Begin
                    Result := SP_Convert_Expr(Tokens, Position, Error, -1); // ID
                    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                    KeyWordID := SP_KW_GFX_MIRROR;
                  End;

                End Else

                  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ERASE) Then Begin

                    Inc(Position, SizeOf(LongWord) +1);
                    Result := SP_Convert_Expr(Tokens, Position, Error, -1); // ID
                    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                    KeyWordID := SP_KW_GFX_ERASE;

                  End Else

                    If (Byte(Tokens[Position]) = SP_KEYWORD) And ((pLongWord(@Tokens[Position +1])^ = SP_KW_TRANSPARENT) or (pLongWord(@Tokens[Position +1])^ = SP_KW_TRANS)) Then Begin

                      Inc(Position, SizeOf(LongWord) +1);
                      Result := SP_Convert_Expr(Tokens, Position, Error, -1); // ID
                      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                        Inc(Position, 2);
                        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Transparent index
                        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Exit;
                        End;
                        KeyWordID := SP_KW_GFX_TRANSPARENT;
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_COMMA;
                        Exit;
                      End;

                    End Else

                      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_REMAP) Then Begin

                        Inc(Position, SizeOf(LongWord) +1);
                        Result := SP_Convert_Expr(Tokens, Position, Error, -1); // ID
                        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Exit;
                        End;
                        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_DITHER) Then Begin
                          Inc(Position, SizeOf(LongWord) +1);
                          Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Dither type
                          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                            Error.Code := SP_ERR_MISSING_NUMEXPR;
                            Exit;
                          End;
                        End Else
                          Result := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0) + Result;
                        KeyWordID := SP_KW_GFX_REMAP;

                      End Else

                        // GRAPHIC PALETTE id <,index,<r,g,b|,longwordval>[HSV]|DEFAULT>

                        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_PALETTE) Then Begin
                          Inc(Position, 1 + SizeOf(LongWord));
                          Result := SP_Convert_Expr(Tokens, Position, Error, -1); // ID
                          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                            Error.Code := SP_ERR_MISSING_NUMEXPR;
                            Exit;
                          End;
                          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_DEFAULT) Then Begin
                            Inc(Position, 1 + SizeOf(LongWord));
                            KeyWordID := SP_KW_GFX_PAL_DEFAULT;
                          End Else Begin
                            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                              Inc(Position, 2);
                              Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Palette Index
                              If Error.Code <> SP_ERR_OK Then Exit;
                              If Error.ReturnType <> SP_VALUE Then Begin
                                Error.Code := SP_ERR_MISSING_NUMEXPR;
                                Exit;
                              End;
                              Result := Result + Expr;
                              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                Inc(Position, 2);
                                Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Red, H, RGB or HSV
                                If Error.Code <> SP_ERR_OK Then Exit;
                                If Error.ReturnType <> SP_VALUE Then Begin
                                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                                  Exit;
                                End;
                                Result := Result + Expr;
                                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                  Inc(Position, 2);
                                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Green
                                  If Error.Code <> SP_ERR_OK Then Exit;
                                  If Error.ReturnType <> SP_VALUE Then Begin
                                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                                    Exit;
                                  End;
                                  Result := Result + Expr;
                                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                    Inc(Position, 2);
                                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Blue
                                    If Error.Code <> SP_ERR_OK Then Exit;
                                    If Error.ReturnType <> SP_VALUE Then Begin
                                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                                      Exit;
                                    End;
                                    Result := Result + Expr;
                                  End Else Begin
                                    Error.Code := SP_ERR_MISSING_COMMA;
                                    Exit;
                                  End;
                                End;
                                If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_HSV) Then Begin
                                  KeyWordID := SP_KW_GFX_PAL_HSV;
                                  Inc(Position, 1 + SizeOf(LongWord));
                                End Else
                                  KeyWordID := SP_KW_GFX_PALETTE;
                              End Else Begin
                                Error.Code := SP_ERR_MISSING_COMMA;
                                Exit;
                              End;
                            End Else Begin
                              Error.Code := SP_ERR_MISSING_COMMA;
                              Exit;
                            End;
                          End;

                        End Else

                          // GRAPHIC ROLL id,dx,dy

                          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ROLL) Then Begin

                            Inc(Position, 1 + SizeOf(LongWord));
                            Result := SP_Convert_Expr(Tokens, Position, Error, -1); // ID
                            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                              Error.Code := SP_ERR_MISSING_NUMEXPR;
                              Exit;
                            End;
                            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                              Inc(Position, 2);
                              Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // dx
                              If Error.Code <> SP_ERR_OK Then Exit;
                              If Error.ReturnType <> SP_VALUE Then Begin
                                Error.Code := SP_ERR_MISSING_NUMEXPR;
                                Exit;
                              End;
                              Result := Result + Expr;
                              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                Inc(Position, 2);
                                Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // dy
                                If Error.Code <> SP_ERR_OK Then Exit;
                                If Error.ReturnType <> SP_VALUE Then Begin
                                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                                  Exit;
                                End;
                                Result := Result + Expr;
                                KeyWordID := SP_KW_GFX_ROLL;
                              End Else Begin
                                Error.Code := SP_ERR_MISSING_COMMA;
                                Exit;
                              End;
                            End Else Begin
                              Error.Code := SP_ERR_MISSING_COMMA;
                              Exit;
                            End;

                          End Else

                            // GRAPHIC SCROLL id,dx,dy

                            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SCROLL) Then Begin

                              Inc(Position, 1 + SizeOf(LongWord));
                              Result := SP_Convert_Expr(Tokens, Position, Error, -1); // ID
                              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                Error.Code := SP_ERR_MISSING_NUMEXPR;
                                Exit;
                              End;
                              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                Inc(Position, 2);
                                Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // dx
                                If Error.Code <> SP_ERR_OK Then Exit;
                                If Error.ReturnType <> SP_VALUE Then Begin
                                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                                  Exit;
                                End;
                                Result := Result + Expr;
                                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                  Inc(Position, 2);
                                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // dy
                                  If Error.Code <> SP_ERR_OK Then Exit;
                                  If Error.ReturnType <> SP_VALUE Then Begin
                                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                                    Exit;
                                  End;
                                  Result := Result + Expr;
                                  KeyWordID := SP_KW_GFX_SCROLL;
                                End Else Begin
                                  Error.Code := SP_ERR_MISSING_COMMA;
                                  Exit;
                                End;
                              End Else Begin
                                Error.Code := SP_ERR_MISSING_COMMA;
                                Exit;
                              End;

                            End Else

                              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ORIGIN) Then Begin
                                Inc(Position, 1 + SizeOf(LongWord));
                                KeyWordID := SP_KW_GFX_ORIGIN;
                                Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
                                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                                  Exit;
                                End;
                                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                  Inc(Position, 2);
                                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // X1
                                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                                    Exit;
                                  End;
                                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                    Inc(Position, 2);
                                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y1
                                    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                                      Exit;
                                    End;
                                    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
                                      Inc(Position, 1 + SizeOf(LongWord));
                                      Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // x2
                                      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                                        Exit;
                                      End;
                                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                        Inc(Position, 2);
                                        Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // y2
                                        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                                          Exit;
                                        End;
                                      End Else Begin
                                        Error.Code := SP_ERR_MISSING_COMMA;
                                        Exit;
                                      End;
                                    End Else Begin
                                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                        Inc(Position, 2);
                                        Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // W
                                        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                                          Exit;
                                        End;
                                        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                          Inc(Position, 2);
                                          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // H
                                          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                            Error.Code := SP_ERR_MISSING_NUMEXPR;
                                            Exit;
                                          End;
                                          KeyWordID := SP_KW_GFX_ORG_DIM;
                                        End Else Begin
                                          Error.Code := SP_ERR_MISSING_COMMA;
                                          Exit;
                                        End;
                                      End Else Begin
                                        // no x2,y2 specified - specify 0 for them instead.
                                        KeyWordID := SP_KW_GFX_ORG_NO_EXT;
                                      End;
                                    End;
                                    Result := Expr;
                                    Exit;
                                  End Else
                                    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OFF) Then Begin
                                      Inc(Position, SizeOf(LongWord) +1);
                                      KeyWordID := SP_KW_GFX_ORG_OFF;
                                      Result := Expr;
                                      Exit;
                                    End Else
                                      Error.Code := SP_ERR_MISSING_COMMA;
                                End Else
                                  Error.Code := SP_ERR_MISSING_COMMA;

                              End Else

                                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CLIP) Then Begin
                                  Inc(Position, 1 + SizeOf(LongWord));

                                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Index
                                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                                    Exit;
                                  End;

                                  Result := Result + Expr;

                                  If (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
                                    Inc(Position, 2)
                                  Else Begin
                                    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OFF) Then Begin
                                      Inc(Position, SizeOf(LongWord) +1);
                                      KeyWordID := SP_KW_GFX_CLIP_OFF;
                                      Result := Expr;
                                      Exit;
                                    End Else Begin
                                      Error.Code := SP_ERR_MISSING_COMMA;
                                      Exit;
                                    End;
                                  End;

                                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // x1
                                  If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
                                  Result := Result + Expr;

                                  If (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
                                    Inc(Position, 2)
                                  Else Begin
                                    Error.Code := SP_ERR_ILLEGAL_CHAR;
                                    Exit;
                                  End;

                                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // y1
                                  If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
                                  Result := Result + Expr;

                                  If (Ord(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then
                                    Inc(Position, 1+SizeOf(LongWord))
                                  Else Begin
                                    Error.Code := SP_ERR_ILLEGAL_CHAR;
                                    Exit;
                                  End;

                                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // x2
                                  If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;
                                  Result := Result + Expr;

                                  If (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
                                    Inc(Position, 2)
                                  Else Begin
                                    Error.Code := SP_ERR_ILLEGAL_CHAR;
                                    Exit;
                                  End;

                                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // y2
                                  If Error.Code <> SP_ERR_OK Then Exit; If Error.ReturnType <> SP_VALUE Then Begin Error.Code := SP_ERR_MISSING_NUMEXPR; Exit; End;

                                  Result := Result + Expr;
                                  KeyWordID := SP_KW_GFX_CLIP;
                                  Exit;

                                End;


End;

Function  SP_Convert_RENUMBER(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr, LineExpr, StepExpr: aString;
Begin

  // RENUMBER [start TO finish] [LINE start] [STEP step]

  Result := '';

  If (Byte(Tokens[Position]) = SP_TERMINAL) or ((Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = ':')) Then Begin

    Result := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1);
    Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1);
    Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(10);
    Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(10);
    Exit;

  End;

  If Not((Byte(Tokens[Position]) = SP_KEYWORD) And ((pLongWord(@Tokens[Position +1])^ = SP_KW_LINE) or (pLongWord(@Tokens[Position +1])^ = SP_KW_STEP))) Then Begin

    Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Start
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    Result := Result + Expr;

    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin

      Inc(Position, 1 + SizeOf(LongWord));
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Finish
      If Error.Code <> SP_ERR_OK Then Exit;
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      Result := Result + Expr;

    End Else Begin
      Error.Code := SP_ERR_MISSING_TO;
      Exit;
    End;


  End Else Begin

    // Set start and finish to -1 to indicate the entire program.

    Result := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1);
    Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1);

  End;

  LineExpr := '';
  StepExpr := '';

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_LINE) Then Begin

    Inc(Position, 1+SizeOf(LongWord));
    LineExpr := SP_Convert_Expr(Tokens, Position, Error, -1); // Line start
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;

  End;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_STEP) Then Begin

    Inc(Position, 1+SizeOf(LongWord));
    StepExpr := SP_Convert_Expr(Tokens, Position, Error, -1); // Step
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;

  End;

  If LineExpr <> '' Then Result := Result + LineExpr Else Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(10);
  If StepExpr <> '' Then Result := Result + StepExpr Else Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(10);

End;

Function  SP_Convert_LIST(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarType: aChar;
  VarSize: LongWord;
  VarName, Expr: aString;
  VarPos, NumIndices: LongWord;
Begin

  // LIST [numexpr [TO numexpr]|BANK [num [DATA]]|VAR [array()]|ASSIGN|STRUCT [var$]|WINDOW]

  Result := '';

  If Byte(Tokens[Position]) = SP_TERMINAL Then Exit;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_WINDOW) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    KeyWordID := SP_KW_LIST_WINDOW;
    Result := SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then
      Exit
    Else
      If Result <> '' Then Begin
        If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
      End Else
        Result := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1);
  End Else
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_BANK) Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      KeyWordID := SP_KW_LIST_BANK;
      Result := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then
        Exit
      Else
        If Result <> '' Then Begin
          If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End Else
            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_DATA) Then Begin
              KeyWordID := SP_KW_LIST_BANK_EX;
              Inc(Position, SizeOf(LongWord) +1);
              Exit;
            End;
        End Else
          Result := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1);

    End Else
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_VAR) Then Begin
        Inc(Position, 1 + SizeOf(LongWord));
        KeyWordID := SP_KW_LIST_VAR;
        If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
          VarPos := Position;
          VarType := Tokens[Position];
          Inc(Position, 1 + SizeOf(LongWord));
          VarSize := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
          VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
          Inc(Position, VarSize);
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
             (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
             KeyWordID := SP_KW_LIST_ARRAY;
             Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
             Inc(Position, 4);
          End Else
            Error.Code := SP_ERR_ARRAY_NOT_FOUND;
          If Error.Code <> SP_ERR_OK Then Exit;
        End Else
          Result := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1);
      End Else
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ASSIGN) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          KeyWordID := SP_KW_LIST_ASSIGN;
        End Else
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_STRUCT) Then Begin
            Inc(Position, SizeOf(LongWord) +1);
            KeyWordID := SP_KW_LIST_STRUCT;
            If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
              VarPos := Position;
              VarType := Tokens[Position];
              Inc(Position, 1 + SizeOf(LongWord));
              VarSize := pLongWord(@Tokens[Position])^;
              Inc(Position, SizeOf(LongWord));
              VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
              Inc(Position, VarSize);
              Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
            End Else
              If Byte(Tokens[Position]) = SP_STRVAR Then Begin
                VarPos := Position;
                VarType := Tokens[Position];
                Inc(Position, 1 + SizeOf(LongWord));
                VarSize := pLongWord(@Tokens[Position])^;
                Inc(Position, SizeOf(LongWord));
                VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
                Inc(Position, VarSize);
                Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin
                  Inc(Position, 2);
                  NumIndices := 0;
                  Result := '';
                  While True Do Begin
                    Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End Else Begin
                        Inc(NumIndices);
                        Result := Expr + Result;
                        If (Byte(Tokens[Position]) = SP_SYMBOL) and (Tokens[Position +1] = ')') Then Begin
                          Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(NumIndices);
                          Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName + Result;
                          Inc(Position, 2);
                          Break;
                        End Else
                          If Not ((Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',')) Then Begin
                            Error.Code := SP_ERR_MISSING_COMMA;
                            Exit;
                          End Else Begin
                            Inc(Position, 2);
                          End;
                      End;
                  End;
                End;
              End;
          End Else Begin
            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
              Inc(Position, 1 + SizeOf(LongWord));
              Result := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);
              Result := Result + SP_Convert_Expr(Tokens, Position, Error, -1);
              If Error.Code <> SP_ERR_OK Then
                Exit
              Else
                If Result <> '' Then
                  If Error.ReturnType = SP_VALUE Then
                    KeyWordID := SP_KW_LIST_LINES
                  Else
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
            End Else Begin
              Result := SP_Convert_Expr(Tokens, Position, Error, -1);
              If Error.Code <> SP_ERR_OK Then
                Exit
              Else
                If Result <> '' Then
                  If Error.ReturnType = SP_VALUE Then Begin
                    KeyWordID := SP_KW_LIST_LINES;
                    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
                      Inc(Position, 1 + SizeOf(LongWord));
                      Result := Result + SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    End Else Begin
                      Result := Result + CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(-1);
                      Exit;
                    End;
                  End Else
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
            End;
          End;

End;

Function SP_Convert_DELETE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // DELETE [numexpr] TO [numexpr]

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
    Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);
    Inc(Position, 1 + SizeOf(LongWord));
    KeyWordID := SP_KW_ERASE_LINES;
    Result := Result + SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
    Exit;
  End Else
    Result := SP_Convert_Expr(Tokens, Position, Error, -1);

  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Result <> '' Then
      If Error.ReturnType = SP_VALUE Then Begin
        KeyWordID := SP_KW_ERASE_LINES;
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          Result := Result + SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.ReturnType = SP_UNKNOWN Then Begin
            Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(-1);
            Exit;
          End Else
            If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
        End Else Begin
          If (Byte(Tokens[Position]) = SP_TERMINAL) or ((Byte(Tokens[Position]) = SP_SYMBOL) and ((Tokens[Position +1] = ':')) or (Tokens[Position +1] in [';', SP_CHAR_SEMICOLON])) Then
            Result := Result + Result
          Else
            Error.Code := SP_ERR_MISSING_TO;
          Exit;
        End;
      End Else
        Error.Code := SP_ERR_MISSING_NUMEXPR;

End;

Function  SP_Convert_THREAD(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr, VarResult: aString;
Begin

  // THREAD NEW numvar,token$ [PRIORITY pri]

  Result := '';

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_NEW) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

      VarResult := SP_Convert_Var_Assign(Tokens, Position, Error);
      If Error.Code <> SP_ERR_OK Then Exit;

      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // token$
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_STRING Then Begin
          Error.Code := SP_ERR_MISSING_STREXPR;
          Exit;
        End;

        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_PRIORITY) Then Begin

        End Else Begin

        End;

      End;

    End;

  End;

End;

Function  SP_Convert_PACKAGE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: integer; Var Error: TSP_ErrorCode): aString;
Begin

  // PACKAGE filename$
	// PACKAGE NEW filename$
	// PACKAGE ADD filename$
	// PACKAGE CLOSE
  // PACKAGE PROTECT
  // PACKAGE UNPROTECT

  Result := '';

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_NEW) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));
    Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Filename
    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_STRING Then Begin
      Error.Code := SP_ERR_MISSING_STREXPR;
      Exit;
    End;
    KeyWordID := SP_KW_PACK_NEW;

  End Else

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = SP_CHAR_ADD) Then Begin

      Inc(Position, 2);
      Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Filename
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_STRING Then Begin
        Error.Code := SP_ERR_MISSING_STREXPR;
        Exit;
      End;
      KeyWordID := SP_KW_PACK_ADD;

    End Else

      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CLOSE) Then Begin

        Inc(Position, 1 + SizeOf(LongWord));
        KeyWordID := SP_KW_PACK_CLOSE;

      End Else

        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_PROTECT) Then Begin

          Inc(Position, 1 + SizeOf(LongWord));
          KeyWordID := SP_KW_PACK_PROTECT;

        End Else

          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_DEPROTECT) Then Begin

            Inc(Position, 1 + SizeOf(LongWord));
            KeyWordID := SP_KW_PACK_UNPROTECT;

          End Else Begin

            Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Filename
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_STRING Then Begin
              Error.Code := SP_ERR_MISSING_STREXPR;
              Exit;
            End;
            KeyWordID := SP_KW_PACKAGE;

          End;

End;

Function  SP_Convert_ASSIGN(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // ASSIGN str-expr TO str-expr

  Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Assignment
  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Error.ReturnType <> SP_STRING Then Begin
      Error.Code := SP_ERR_MISSING_STREXPR;
      Exit;
    End Else
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
        Inc(Position, 1 + SizeOf(LongWord));
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Path
        If Error.Code <> SP_ERR_OK Then
          Exit
        Else
          If Error.ReturnType <> SP_STRING Then Begin
            Error.Code := SP_ERR_MISSING_STREXPR;
            Exit;
          End;
      End Else
        Error.Code := SP_ERR_MISSING_TO;

End;

Function  SP_Convert_COPY(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // COPY filespec$ TO dest-dir$ [OVER]

  Result := SP_Convert_Expr(Tokens, Position, Error, -1); // filespec$
  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Error.ReturnType <> SP_STRING Then Begin
      Error.Code := SP_ERR_MISSING_STREXPR;
      Exit;
    End Else Begin
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
        Inc(Position, 1 + SizeOf(LongWord));
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // dest-dir$
        If Error.Code <> SP_ERR_OK Then
          Exit
        Else
          If Error.ReturnType <> SP_STRING Then Begin
            Error.Code := SP_ERR_MISSING_STREXPR;
            Exit;
          End;
      End Else Begin
        Error.Code := SP_ERR_MISSING_TO;
        Exit;
      End;
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OVER) Then Begin
        Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1) + Result;
        Inc(Position, 1 + SizeOf(LongWord));
      End Else
        Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0) + Result;
    End;

End;

Function SP_Convert_MAKEDIR(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code = SP_ERR_OK Then Begin
    If Result = '' Then
      Result := CreateToken(SP_STRING, 0, 0)
    Else
      If Error.ReturnType <> SP_STRING Then Begin
        Error.Code := SP_ERR_MISSING_STREXPR;
        Exit;
      End;
  End Else
    Exit;

End;

Function  SP_Convert_RENAME(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // RENAME filespec$ TO filespec$

  Result := SP_Convert_Expr(Tokens, Position, Error, -1); // filespec$
  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Error.ReturnType <> SP_STRING Then Begin
      Error.Code := SP_ERR_MISSING_STREXPR;
      Exit;
    End Else Begin
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
        Inc(Position, 1 + SizeOf(LongWord));
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // filespec$
        If Error.Code <> SP_ERR_OK Then
          Exit
        Else
          If Error.ReturnType <> SP_STRING Then Begin
            Error.Code := SP_ERR_MISSING_STREXPR;
            Exit;
          End;
      End Else Begin
        Error.Code := SP_ERR_MISSING_TO;
        Exit;
      End;
    End;

End;

Function SP_Convert_TILEMAP(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarResult, RotResult, SclResult, ToResult: aString;
  KeyWordPos: LongWord;
Begin

  // TILEMAP NEW numvar,w,h [GRAPHIC gfx-id|gfx$],tilew,tileh
  // TILEMAP DRAW id,offx,offy [ROTATE angle] [SCALE size] [TO x,y,w,h]
  // TILEMAP SET id,x,y,tile
  // TILEMAP GRAPHIC id,gfx-id|gfx$,tilew,tileh
  // TILEMAP CLEAR id

  Result := '';
  RotResult := '';
  SclResult := '';
  ToResult := '';

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_NEW) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

      VarResult := SP_Convert_Var_Assign(Tokens, Position, Error);
      If Error.Code <> SP_ERR_OK Then Exit;

      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // width
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Height
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
            KeyWordPos := Position;
            Inc(Position, 1 + SizeOf(LongWord));
            Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Graphic-ID or GFX$
            If Error.Code <> SP_ERR_OK Then Exit;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // tile width
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // tile Height
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End Else
                Result := Result + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_TILEMAP_NEW)+ VarResult;
                If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
                Exit;
              End Else Begin
                Error.Code := SP_ERR_MISSING_COMMA;
                Exit;
              End;
            End Else Begin
              Error.Code := SP_ERR_MISSING_COMMA;
              Exit;
            End;
          End Else Begin
            Error.Code := SP_ERR_SYNTAX_ERROR;
            Exit;
          End;
        End Else Begin
          Error.Code := SP_ERR_MISSING_COMMA;
          Exit;
        End;
      End Else Begin
        Error.Code := SP_ERR_MISSING_COMMA;
        Exit;
      End;
    End Else Begin
      Error.Code := SP_ERR_MISSING_VARIABLE;
      Exit;
    End;

  End Else

    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_DRAW) Then Begin

      // id,offx,offy [ROTATE angle] [SCALE size] [TO x,y,w,h]

      Inc(Position, 1 + SizeOf(LongWord));
      Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // id
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // offx
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // offy
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          KeyWordID := SP_KW_TILEMAP_DRAW;
          RotResult := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);
          RotResult := RotResult + RotResult + RotResult;
          SclResult := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1);
          ToResult  := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(-1) + // x
                       CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(-1) + // y
                       CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(-1) + // w
                       CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(-1);  // h
          Repeat
            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ROTATE) Then Begin
              Inc(Position, SizeOf(LongWord) +1);
              RotResult := SP_Convert_Expr(Tokens, Position, Error, -1); // RX
              If Error.Code <> SP_ERR_OK Then
                Exit
              Else
                If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End Else Begin
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    RotResult := SP_Convert_Expr(Tokens, Position, Error, -1) + RotResult; // RY
                    If Error.Code <> SP_ERR_OK Then
                      Exit
                    Else
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End Else Begin
                        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                          Inc(Position, 2);
                          RotResult := SP_Convert_Expr(Tokens, Position, Error, -1) + RotResult; // Angle
                          If Error.Code <> SP_ERR_OK Then
                            Exit
                          Else
                            If Error.ReturnType <> SP_VALUE Then Begin
                              Error.Code := SP_ERR_MISSING_NUMEXPR;
                              Exit;
                            End;
                        End Else Begin
                          Error.Code := SP_ERR_MISSING_COMMA;
                          Exit;
                        End;
                      End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End;
            End Else
              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SCALE) Then Begin
                Inc(Position, SizeOf(LongWord) +1);
                SclResult := SP_Convert_Expr(Tokens, Position, Error, -1); // Scale
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
              End Else
                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
                  Inc(Position, SizeOf(LongWord) +1);
                  ToResult := SP_Convert_Expr(Tokens, Position, Error, -1); // x
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    ToResult := SP_Convert_Expr(Tokens, Position, Error, -1) + ToResult; // y
                    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      ToResult := SP_Convert_Expr(Tokens, Position, Error, -1) + ToResult; // w
                      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                        Inc(Position, 2);
                        ToResult := SP_Convert_Expr(Tokens, Position, Error, -1) + ToResult; // h
                        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Exit;
                        End;
                      End Else Begin
                        Error.Code := SP_ERR_MISSING_COMMA;
                        Exit;
                      End;
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_COMMA;
                      Exit;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_MISSING_COMMA;
                    Exit;
                  End;
                End Else Begin
                  Result := ToResult + SclResult + RotResult + Result;
                  Exit;
                End;
          Until False;
        End Else Begin
          Error.Code := SP_ERR_MISSING_COMMA;
          Exit;
        End;
      End Else Begin
        Error.Code := SP_ERR_MISSING_COMMA;
        Exit;
      End;

    End Else

      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SET) Then Begin
        Inc(Position, SizeOf(LongWord) +1);
        Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Id
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // x
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // y
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // tile
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              KeyWordID := SP_KW_TILEMAP_SET;
            End Else Begin
              Error.Code := SP_ERR_MISSING_COMMA;
              Exit;
            End;
          End Else Begin
            Error.Code := SP_ERR_MISSING_COMMA;
            Exit;
          End;
        End Else Begin
          Error.Code := SP_ERR_MISSING_COMMA;
          Exit;
        End;
      End Else

        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_GRAPHIC) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Id
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Graphic-ID or GFX$
            If Error.Code <> SP_ERR_OK Then Exit;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // tile width
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // tile Height
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End Else
                KeyWordID := SP_KW_TILEMAP_GRAPHIC;
                Exit;
              End Else Begin
                Error.Code := SP_ERR_MISSING_COMMA;
                Exit;
              End;
            End Else Begin
              Error.Code := SP_ERR_MISSING_COMMA;
              Exit;
            End;
          End Else Begin
            Error.Code := SP_ERR_MISSING_COMMA;
            Exit;
          End;
        End Else

          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CLEAR) Then Begin
            Inc(Position, 1 + SizeOf(LongWord));
            Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Id
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            KeyWordID := SP_KW_TILEMAP_CLEAR;
          End Else

            Error.Code := SP_ERR_SYNTAX_ERROR;

End;

Function  SP_Convert_STRUCT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  NamePos, NameLen: Integer;
  Name: aString;
Begin

  // STRUCT ERASE numvar

  Result := '';

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ERASE) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

      KeyWordID := SP_KW_STRUCT_ERASE;
      Inc(Position);
      NamePos := pLongWord(@Tokens[Position])^;
      Inc(Position, SizeOf(LongWord));
      NameLen := pLongWord(@Tokens[Position])^;
      Inc(Position, SizeOf(LongWord));
      Name := LowerNoSpaces(Copy(Tokens, Position, NameLen));
      Inc(Position, NameLen);

      Result := CreateToken(SP_NUMVAR, NamePos, SizeOf(longWord) + Length(Name)) + LongWordToString(0) + Name;

    End Else

      Error.Code := SP_ERR_INVALID_STRUCTURE_NAME;

  End;

End;

Function  SP_Convert_INPUT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  nExpr, Expr: aString;
  KeyWordPos, RT, VarCount: Integer;
  KeyWord, KW: LongWord;
  VarType: Byte;
  VarExpr: aString;
  TransFlag, CentreFlag: Boolean;
Label
  Expression, Finalise;
Begin

  // INPUT [[colour-item | strexpr | FORMAT strexpr | ERROR [val|REPEAT]] print-sep] strvar/numvar...

  VarCount := 0;
  KeyWordID := 0;
  TransFlag := False;
  CentreFlag := False;
  KeyWordPos := Position;
  KW := SP_KW_PRINT;
  Expr := '';
  Result := CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_INIT_INPUT);

  While True Do Begin

    Case Ord(Tokens[Position]) of

      SP_TERMINAL:
        If VarCount = 0 Then Begin
          Error.Code := SP_ERR_INPUT_WITHOUT_VAR;
          Exit;
        End Else Begin
          Goto Finalise;
        End;

      SP_KEYWORD:
        Begin
          KeyWord := pLongWord(@Tokens[Position +1])^;
          KeyWordPos := Position;

          If Expr <> '' Then Begin
            Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KW);
            Expr := '';
          End;

          Case KeyWord of
            SP_KW_INK, SP_KW_PAPER, SP_KW_INVERSE, SP_KW_TAB, SP_KW_OVER, SP_KW_TRANSPARENT, SP_KW_TRANS, SP_KW_CENTRE:
              Begin
                Inc(Position, 1+SizeOf(LongWord));
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code <> SP_ERR_OK Then Exit;
                If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                Case KeyWord Of
                  SP_KW_INK: KeyWord := SP_KW_PR_INK;
                  SP_KW_PAPER: KeyWord := SP_KW_PR_PAPER;
                  SP_KW_INVERSE: KeyWord := SP_KW_PR_INVERSE;
                  SP_KW_TAB: Keyword := SP_KW_PR_TAB;
                  SP_KW_OVER: KeyWord := SP_KW_PR_OVER;
                  SP_KW_TRANSPARENT, SP_KW_TRANS:
                    Begin
                      KeyWord := SP_KW_PR_TRANSPARENT;
                      TransFlag := True;
                    End;
                  SP_KW_CENTRE:
                    Begin
                      KeyWord := SP_KW_PR_CENTRE;
                      CentreFlag := True;
                    End;
                End;
                Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWord);
                Expr := '';
              End;
            SP_KW_AT, SP_KW_MOVE, SP_KW_CURSOR, SP_KW_SCALE:
              Begin
                Inc(Position, 1+SizeOf(LongWord));
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code <> SP_ERR_OK Then Exit;
                If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                Result := Result + Expr;
                If (Ord(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
                  Inc(Position, 2)
                Else Begin
                  Error.Code := SP_ERR_ILLEGAL_CHAR;
                  Exit;
                End;
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code <> SP_ERR_OK Then Exit;
                If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                Case KeyWord Of
                  SP_KW_AT: KeyWord := SP_KW_PR_AT;
                  SP_KW_MOVE: KeyWord := SP_KW_PR_MOVE;
                  SP_KW_CURSOR: KeyWord := SP_KW_CURSOR;
                  SP_KW_SCALE: KeyWord := SP_KW_PR_SCALE;
                End;
                Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KeyWord);
                Expr := '';
              End;
            SP_KW_ELSE, SP_KW_ENDIF:
              Goto Finalise;
            SP_KW_FORMAT:
              Begin
                Inc(Position, 1+SizeOf(LongWord));
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code <> SP_ERR_OK Then Exit;
                If Error.ReturnType <> SP_STRING Then Begin
                  Error.Code := SP_ERR_MISSING_STREXPR;
                  Exit;
                End;
                Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_INPUT_FORMAT);
                Expr := '';
              End;
            SP_KW_ERROR:
              Begin
                Inc(Position, 1+SizeOf(LongWord));
                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_REPEAT) Then Begin
                  Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_INPUT_ERR_RPT);
                  Inc(Position, 1+SizeOf(LongWord));
                End Else Begin
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                  If Error.Code <> SP_ERR_OK Then Exit;
                  If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                  Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_INPUT_ERROR);
                  Expr := '';
                End;
              End;
          Else
            Error.Code := SP_ERR_SYNTAX_ERROR;
            Exit;
          End;
        End;

      SP_SYMBOL:
        Begin
          If Tokens[Position +1] in [#39, ',', ';'] Then Begin
            Inc(Position);
            Expr := CreateToken(SP_SYMBOL, Position -1, 1) + Tokens[Position] + Expr;
            Inc(Position);
          End Else
            If Tokens[Position +1] = ':' Then
              Goto Finalise
            Else
              Goto Expression;
        End;

      SP_NUMVAR, SP_STRVAR, SP_FUNCTION:
        Begin
          If Expr <> '' Then Begin
            Result := Result + Expr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(KW);
            Expr := '';
          End;
          VarType := Byte(Tokens[Position]);
          VarExpr := SP_Convert_Var_Assign(Tokens, Position, Error);
          If VarType = SP_FUNCTION Then
            VarType := Error.ReturnType;
          If Error.Code <> SP_ERR_OK Then Exit;
          RT := Error.ReturnType;
          Inc(VarCount);
          Case VarType Of
            SP_NUMVAR:
              Begin
                If RT = SP_NUMVAR Then
                  pToken(@VarExpr[1])^.Token := SP_NUMVAR_LET
                Else
                  VarExpr := VarExpr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_LET);
                Result := Result + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_INPUT_NUM) + VarExpr;
              End;
            SP_STRVAR:
              Begin
                If (RT = SP_STRVAR) And (Byte(VarExpr[1]) <> SP_STRUCT_MEMBER_ASS) Then
                  pToken(@VarExpr[1])^.Token := SP_STRVAR_LET
                Else
                  VarExpr := VarExpr + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_LET);
                // If we're actually assigning to a numeric structure member then we'd best be prepared for it!
                If Error.ReturnType = SP_NUMVAR Then
                  Result := Result + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_INPUT_NUM) + VarExpr
                Else
                  Result := Result + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_INPUT_STR) + VarExpr;
              End;
          End;
          Expr := '';
        End;

    Else

      Expression:
      nExpr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then Exit;
      If nExpr <> '' Then
        Expr := nExpr + Expr
      Else Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End;

    End;

  End;

Finalise:

  If Expr <> '' Then
    Result := Result + Expr;

  If TransFlag or CentreFlag Then Begin
    Result := Result + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(KW);
    KeyWordID := 0;
  End;

  If TransFlag Then
    Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0) + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_PR_TRANSPARENT);

  If CentreFlag Then
    Result := Result + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_PR_CENTRE_OFF);

  Result := Result + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_INPUT_FINAL);

End;

Function SP_Convert_MENU(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  ItemCount, KeyWordPos: Integer;
  VarResult: aString;
Begin

  // MENU NEW ID,item$,item$,item$...

  // MENU ADD ID,item$
  // MENU INSERT menuID,item$,pos
  // MENU DELETE menuID,pos

  // MENU ADD MENU ID,pos,sub-id.
  // MENU DELETE MENU ID,pos

  // MENU SHOW ID.
  // MENU HIDE.
  // MENU ERASE ID [ALL]

  // MENU FONT ID,font-id [SCALE x,y] [ALL]
  // MENU ATTR ID,itempos,attributes
  // MENU ATTR ID,attributes

  Result := '';

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_NEW) Then Begin

    KeyWordPos := Position;
    Inc(Position, 1+SizeOf(LongWord));

    If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

      VarResult := SP_Convert_Var_Assign(Tokens, Position, Error);
      If Error.Code <> SP_ERR_OK Then Exit;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin

        Inc(Position, 2);
        ItemCount := 0;
        While True Do Begin

          Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
          If Error.Code <> SP_ERR_OK Then
            Exit
          Else
            If Error.ReturnType <> SP_STRING Then Begin
              Error.Code := SP_ERR_MISSING_STREXPR;
              Exit;
            End Else Begin
              Inc(ItemCount);
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
                Inc(Position, 2)
              Else Begin
                If ItemCount = 0 Then
                  Error.Code := SP_ERR_SYNTAX_ERROR
                Else
                  Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(ItemCount);
                Result := Result + CreateToken(SP_KEYWORD, KeyWordPos, SizeOf(LongWord)) + LongWordToString(SP_KW_MENU_NEW) + VarResult;
                KeyWordID := 0;
                Exit;
              End;
            End;

        End;

      End Else
        Error.Code := SP_ERR_SYNTAX_ERROR;
    End Else
      Error.Code := SP_ERR_MISSING_VARIABLE;

  End Else

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = SP_CHAR_ADD) And (Byte(Tokens[Position +2]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +3])^ = SP_KW_MENU) Then Begin

      Inc(Position, 3 + SizeOf(LongWord));
      Result := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code = SP_ERR_OK Then
        If Error.ReturnType = SP_VALUE Then Begin
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
            If Error.Code = SP_ERR_OK Then
              If Error.ReturnType = SP_VALUE Then Begin
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                  Inc(Position, 2);
                  Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
                  If Error.Code = SP_ERR_OK Then
                    If Error.ReturnType = SP_VALUE Then Begin
                      KeyWordID := SP_KW_MENU_ADDSUB;
                      Exit;
                    End Else
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                End Else
                  Error.Code := SP_ERR_MISSING_COMMA;
              End Else
                Error.Code := SP_ERR_MISSING_NUMEXPR;
          End Else
            Error.Code := SP_ERR_MISSING_COMMA;
        End Else
          Error.Code := SP_ERR_MISSING_NUMEXPR;

    End Else

      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = SP_CHAR_ADD) Then Begin

        Inc(Position, 2);
        Result := SP_Convert_Expr(Tokens, Position, Error, -1);
        If Error.Code = SP_ERR_OK Then
          If Error.ReturnType = SP_VALUE Then Begin
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
              If Error.Code = SP_ERR_OK Then
                If Error.ReturnType = SP_STRING Then Begin
                  KeyWordID := SP_KW_MENU_ADD_ITEM;
                  Exit;
                End Else
                  Error.Code := SP_ERR_MISSING_STREXPR;
            End Else
              Error.Code := SP_ERR_MISSING_COMMA;

          End Else
            Error.Code := SP_ERR_MISSING_NUMEXPR;

      End Else

        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_INSERT) Then Begin

          Inc(Position, 1+SizeOf(LongWord));
          Result := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code = SP_ERR_OK Then
            If Error.ReturnType = SP_VALUE Then Begin
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
                If Error.Code = SP_ERR_OK Then
                  If Error.ReturnType = SP_STRING Then Begin
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
                      If Error.Code = SP_ERR_OK Then
                        If Error.ReturnType = SP_VALUE Then Begin
                          KeyWordID := SP_KW_MENU_INSITEM;
                          Exit;
                        End Else
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                    End Else
                      Error.Code := SP_ERR_MISSING_COMMA;
                  End Else
                    Error.Code := SP_ERR_MISSING_STREXPR;
              End Else
                Error.Code := SP_ERR_MISSING_COMMA;
            End Else
              Error.Code := SP_ERR_MISSING_NUMEXPR;

        End Else

          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_DELETE) Then Begin

            Inc(Position, 1 + SizeOf(LongWord));
            Result := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code = SP_ERR_OK Then
              If Error.ReturnType = SP_VALUE Then Begin
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                  Inc(Position, 2);
                  Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
                  If Error.Code = SP_ERR_OK Then
                    If Error.ReturnType = SP_VALUE Then Begin
                      KeyWordID := SP_KW_MENU_DELITEM;
                      Exit;
                    End Else
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                End Else
                  Error.Code := SP_ERR_MISSING_COMMA;

              End Else
                Error.Code := SP_ERR_MISSING_NUMEXPR;

          End Else

            If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_DELETE) And (Byte(Tokens[Position + 1 + SizeOf(LongWord)]) = SP_KEYWORD) And (pLongWord(@Tokens[Position + 2 + SizeOf(LongWord)])^ = SP_KW_MENU) Then Begin

              Inc(Position, 2 * (1 + SizeOf(LongWord)));
              Result := SP_Convert_Expr(Tokens, Position, Error, -1);
              If Error.Code = SP_ERR_OK Then
                If Error.ReturnType = SP_VALUE Then Begin
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
                    If Error.Code = SP_ERR_OK Then
                      If Error.ReturnType = SP_VALUE Then Begin
                        KeyWordID := SP_KW_MENU_DELSUB;
                        Exit;
                      End Else
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                  End Else
                    Error.Code := SP_ERR_MISSING_COMMA;

                End Else
                  Error.Code := SP_ERR_MISSING_NUMEXPR;

            End Else

              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SHOW) Then Begin

                Inc(Position, 1 + SizeOf(LongWord));
                Result := SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code = SP_ERR_OK Then
                  If Error.ReturnType = SP_VALUE Then Begin
                    KeyWordID := SP_KW_MENU_SHOW;
                    Exit;
                  End Else
                    Error.Code := SP_ERR_MISSING_NUMEXPR;

              End Else

                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_HIDE) Then Begin

                  Inc(Position, 1 + SizeOf(LongWord));
                  KeyWordID := SP_KW_MENU_HIDE;
                  Exit;

                End Else

                  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ERASE) Then Begin

                    Inc(Position, 1 + SizeOf(LongWord));
                    Result := SP_Convert_Expr(Tokens, Position, Error, -1);
                    If Error.Code = SP_ERR_OK Then
                      If Error.ReturnType = SP_VALUE Then Begin
                        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ALL) Then Begin
                          Inc(Position, 1 + SizeOf(LongWord));
                          KeyWordID := SP_KW_MENU_ERASE_ALL;
                          Exit;
                        End Else Begin
                          KeyWordID := SP_KW_MENU_ERASE;
                          Exit;
                        End;
                      End Else
                        Error.Code := SP_ERR_MISSING_NUMEXPR;

                  End Else

                    If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_ATTR) Then Begin

                      Result := SP_Convert_Expr(Tokens, Position, Error, -1);
                      If Error.Code = SP_ERR_OK Then
                        If Error.ReturnType = SP_VALUE Then Begin
                          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                            Inc(Position, 2);
                            Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
                            If Error.Code = SP_ERR_OK Then
                              If Error.ReturnType = SP_VALUE Then Begin
                                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                  Inc(Position, 2);
                                  Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
                                  If Error.Code = SP_ERR_OK Then
                                    If Error.ReturnType = SP_VALUE Then Begin
                                      KeyWordID := SP_KW_MENUITEM_ATTR;
                                      Exit;
                                    End Else
                                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                                End Else Begin
                                  KeyWordID := SP_KW_MENU_ATTR;
                                  Exit;
                                End;
                              End Else
                                Error.Code := SP_ERR_MISSING_NUMEXPR;
                          End Else
                            Error.Code := SP_ERR_MISSING_COMMA;
                        End Else
                          Error.Code := SP_ERR_MISSING_NUMEXPR;

                    End Else

                      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FONT) Then Begin

                        Inc(Position, 1 + SizeOf(LongWord));
                        Result := SP_Convert_Expr(Tokens, Position, Error, -1);
                        If Error.Code = SP_ERR_OK Then
                          If Error.ReturnType = SP_VALUE Then Begin
                            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                              Inc(Position, 2);
                              Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
                              If Error.Code = SP_ERR_OK Then
                                If Error.ReturnType = SP_VALUE Then Begin
                                  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SCALE) Then Begin
                                    Inc(Position, 1 + SizeOf(LongWord));
                                    Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
                                    If Error.Code = SP_ERR_OK Then
                                      If Error.ReturnType = SP_VALUE Then Begin
                                        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                                          Inc(Position, 2);
                                          Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
                                          If Error.Code = SP_ERR_OK Then
                                            If Error.ReturnType = SP_VALUE Then Begin
                                              KeyWordID := SP_KW_MENU_FONT;
                                              If (Byte(Tokens[Position]) = SP_KEYWORD) and (pLongWord(@Tokens[Position +1])^ = SP_KW_ALL) Then Begin
                                                Inc(Position, 1 + SizeOf(LongWord));
                                                Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1) + Result;
                                              End Else
                                                Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0) + Result;
                                              Exit;
                                            End Else
                                              Error.Code := SP_ERR_MISSING_NUMEXPR;
                                        End Else
                                          Error.Code := SP_ERR_MISSING_COMMA;
                                      End Else
                                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                                  End Else Begin
                                    Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1) + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1) + Result;
                                    KeyWordID := SP_KW_MENU_FONT;
                                    If (Byte(Tokens[Position]) = SP_KEYWORD) and (pLongWord(@Tokens[Position +1])^ = SP_KW_ALL) Then Begin
                                      Inc(Position, SizeOf(LongWord) +1);
                                      Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1) + Result;
                                    End Else
                                      Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0) + Result;
                                    Exit;
                                  End;
                                End Else
                                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                            End Else
                              Error.Code := SP_ERR_MISSING_COMMA;
                          End Else
                            Error.Code := SP_ERR_MISSING_NUMEXPR;

                      End Else Begin

                        Result := SP_Convert_Expr(Tokens, Position, Error, -1);
                        If Error.Code = SP_ERR_OK Then
                          If Error.ReturnType = SP_VALUE Then Begin
                            KeyWordID := SP_KW_MENU_SHOW;
                            Exit;
                          End Else
                            Error.Code := SP_ERR_MISSING_NUMEXPR;

                      End;

End;

Function  SP_Convert_MOUSE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
Begin

  // MOUSE SHOW
  // MOUSE HIDE
  // MOUSE GRAPHIC gfx$|bank-id|DEFAULT {POINT x,y}
  // MOUSE TO x,y

  Result := '';

  If Byte(Tokens[Position]) = SP_KEYWORD Then Begin
    Inc(Position);
    Case pLongWord(@Tokens[Position])^ of
      SP_KW_SHOW:
        Begin
          Inc(Position, SizeOf(LongWord));
          KeyWordID := SP_KW_MOUSE_SHOW;
        End;
      SP_KW_HIDE:
        Begin
          Inc(Position, SizeOf(LongWord));
          KeyWordID := SP_KW_MOUSE_HIDE;
        End;
      SP_KW_TO:
        Begin
          Inc(Position, SizeOf(LongWord));
          KeyWordID := SP_KW_MOUSE_TO;
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.Code <> SP_ERR_OK Then Exit;
          If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Result := Expr + Result;
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code <> SP_ERR_OK Then Exit;
            If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            Result := Expr + Result;
          End Else Begin
            Error.Code := SP_ERR_ILLEGAL_CHAR;
            Exit;
          End;
        End;
      SP_KW_GRAPHIC:
        Begin
          Inc(Position, SizeOf(LongWord));
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_DEFAULT) Then Begin
            Inc(Position, SizeOf(LongWord) +1);
            KeyWordID := SP_KW_MOUSE_DEFAULT;
          End Else Begin
            Result := SP_Convert_Expr(Tokens, Position, Error, -1);
            If Error.Code = SP_ERR_OK Then Begin
              If Error.ReturnType = SP_VALUE Then
                KeyWordID := SP_KW_MOUSE_GRAPHIC
              Else
                KeyWordID := SP_KW_MOUSE_GFXS;
            End;
            If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_POINT) Then Begin
              Inc(Position, 1 + SizeOf(LongWord));
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
              If Error.Code <> SP_ERR_OK Then Exit;
              If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Result := Expr + Result;
                Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
                If Error.Code <> SP_ERR_OK Then Exit;
                If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End;
                Result := Expr + Result;
              End Else Begin
                Error.Code := SP_ERR_ILLEGAL_CHAR;
                Exit;
              End;
            End;
          End;
        End;
    End;
  End;

End;

Function  SP_Convert_DEBUG(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // DEBUG linenum[,statementnum]

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End Else
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
        If Error.Code <> SP_ERR_OK Then Exit;
        If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
      End;

End;

Function  SP_Convert_FPS(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // FPS numexpr

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK then Exit;
  If Error.ReturnType <> SP_VALUE Then Error.Code := SP_ERR_MISSING_NUMEXPR;

End;

Function  SP_Convert_PUSH(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // PUSH line[,statement]

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End Else
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
        If Error.Code <> SP_ERR_OK Then Exit;
        If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
      End;

End;

Function SP_Convert_SCALE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // SCALE x,y

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End Else
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
        If Error.Code <> SP_ERR_OK Then Exit;
        If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;

End;

Function  SP_Convert_POP(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarResult1, VarResult2: aString;
Begin

  // POP numvar[,numvar]

  // Constructs a line which consists of LET var2=POPST: LET var1=POPLINE, which will have the intended effect.

  Result := '';
  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

    VarResult1 := SP_Convert_Var_Assign(Tokens, Position, Error);
    If Error.Code <> SP_ERR_OK Then Exit;

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin

      Inc(Position, 2);

      If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

        VarResult2 := SP_Convert_Var_Assign(Tokens, Position, Error);
        If Error.Code <> SP_ERR_OK Then Exit;
        KeyWordID := 0;
        Result := CreateToken(SP_FUNCTION, Position, SizeOf(longWord)) + LongWordToString(SP_FN_POPST) +
                  CreateToken(SP_FUNCTION, Position, SizeOf(longWord)) + LongWordToString(SP_FN_POPLINE) + VarResult1 + VarResult2;

      End Else

        Error.Code := SP_ERR_MISSING_VARIABLE;

    End Else Begin

      KeyWordID := 0;
      Result := CreateToken(SP_FUNCTION, Position, SizeOf(longWord)) + LongWordToString(SP_FN_POPLINE) + VarResult1;

    End;

  End Else

    Error.Code := SP_ERR_MISSING_VARIABLE;


End;

Function  SP_Convert_OPTION(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // OPTION strexpr,expr

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code = SP_ERR_OK Then
    If Error.ReturnType = SP_STRING Then Begin
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
      End Else
        Error.Code := SP_ERR_SYNTAX_ERROR;
    End Else
      Error.Code := SP_ERR_MISSING_STREXPR;

End;

Function  SP_Convert_SETNUB(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // SETNUB n,mode

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code = SP_ERR_OK Then
    If Error.ReturnType = SP_VALUE Then Begin
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
        If Error.ReturnType <> SP_VALUE Then
          Error.Code := SP_ERR_MISSING_NUMEXPR;
      End Else
        Error.Code := SP_ERR_SYNTAX_ERROR;
    End Else
      Error.Code := SP_ERR_MISSING_NUMEXPR;

End;

Function  SP_Convert_SETCPU(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // SETCPU speed

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code = SP_ERR_OK Then
    If Error.ReturnType <> SP_VALUE Then
      Error.Code := SP_ERR_MISSING_NUMEXPR;

End;

Function  SP_Convert_MULTIPLOT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarPos, VarSize: Integer;
  VarType: aChar;
  VarName: aString;
Begin

  // MULTIPLOT [ALPHA] [colour items;]array()

  SP_AlphaCheck(KeyWordID, Tokens, Position);

  Result := SP_Convert_Embedded_Colours(Tokens, Position, Error);

  If Byte(Tokens[Position]) in [SP_NUMVAR] Then Begin
    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
       Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
       Inc(Position, 4);
    End Else
      Error.Code := SP_ERR_ARRAY_NOT_FOUND;
  End Else
    Error.Code := SP_ERR_INVALID_ARRAY_VAR;

End;

Function  SP_Convert_TRANSFORM3D(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  KeyWordID: LongWord;
  VarPos, VarSize, NumTransforms: Integer;
  VarType: aChar;
  VarName, Expr, SrcExpr, DstExpr, ParamExpr: aString;
Begin

  // TRANSFORM3D src() [TO dst()] {[MOVE dx,dy,dz|ROTATE dx,dy,dz|SCALE sx,sy,sz]...}
  // Destination optional - changes applied to src if not present.
  // transformations executed in order of syntax.

  Result := '';
  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

    // Source array

    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
      SrcExpr := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
      Inc(Position, 4);
    End Else
      Error.Code := SP_ERR_SYNTAX_ERROR;
  End Else
    Error.Code := SP_ERR_INVALID_ARRAY_VAR;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) And (Byte(Tokens[Position + 1 + SizeOf(LongWord)]) = SP_NUMVAR) Then Begin

    // Optional Destination array

    Inc(Position, 1 + SizeOf(LongWord));

    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
      DstExpr := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
      Inc(Position, 4);
    End Else
      Error.Code := SP_ERR_SYNTAX_ERROR;
  End;

  // Now check for MOVE/ROTATE/SCALE - may be more than one or none.

  ParamExpr := '';
  NumTransforms := 0;

  While True Do Begin

    If (Byte(Tokens[Position]) = SP_KEYWORD) Then Begin

      KeyWordID := pLongWord(@Tokens[Position +1])^;
      If (KeyWordID = SP_KW_ROTATE) or (KeyWordID = SP_KW_MOVE) or (KeyWordID = SP_KW_SCALE) Then Begin
        Inc(NumTransforms);
        Inc(Position, 1 + SizeOf(LongWord));
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // rX
        If Error.Code <> SP_ERR_OK Then Exit Else
          If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // rY
          If Error.Code <> SP_ERR_OK Then Exit Else
            If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // rZ
            If Error.Code <> SP_ERR_OK Then Exit Else
              If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
            ParamExpr := Expr + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(KeyWordID) + ParamExpr;
          End Else
            Error.Code := SP_ERR_SYNTAX_ERROR;
        End Else
          Error.Code := SP_ERR_SYNTAX_ERROR;
      End Else
        Break;
    End Else
      Break;
  End;

  If Error.Code = SP_ERR_OK Then
    Result := ParamExpr + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(NumTransforms) + DstExpr + SrcExpr;

End;

Function  SP_Convert_TRANSFORM2D(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  KeyWordID: LongWord;
  VarPos, VarSize, NumTransforms: Integer;
  VarType: aChar;
  VarName, Expr, SrcExpr, DstExpr, ParamExpr: aString;
Begin

  // TRANSFORM2D src() [TO dst()] {[MOVE dx,dy|ROTATE dx,dy|SCALE sx,sy]...}
  // Destination optional - changes applied to src if not present.
  // transformations executed in order of syntax.

  Result := '';
  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

    // Source array

    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
      SrcExpr := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
      Inc(Position, 4);
    End Else
      Error.Code := SP_ERR_SYNTAX_ERROR;
  End Else
    Error.Code := SP_ERR_INVALID_ARRAY_VAR;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) And (Byte(Tokens[Position + 1 + SizeOf(LongWord)]) = SP_NUMVAR) Then Begin

    // Optional Destination array

    Inc(Position, 1 + SizeOf(LongWord));

    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
      DstExpr := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
      Inc(Position, 4);
    End Else
      Error.Code := SP_ERR_SYNTAX_ERROR;
  End;

  // Now check for MOVE/ROTATE/SCALE - may be more than one or none.

  ParamExpr := '';
  NumTransforms := 0;

  While True Do Begin

    If (Byte(Tokens[Position]) = SP_KEYWORD) Then Begin

      KeyWordID := pLongWord(@Tokens[Position +1])^;
      If (KeyWordID = SP_KW_ROTATE) or (KeyWordID = SP_KW_MOVE) or (KeyWordID = SP_KW_SCALE) Then Begin
        Inc(NumTransforms);
        Inc(Position, 1 + SizeOf(LongWord));
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // rX
        If Error.Code <> SP_ERR_OK Then Exit Else
          If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
        If (KeyWordID <> SP_KW_ROTATE) And (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // rY
          If Error.Code <> SP_ERR_OK Then Exit Else
            If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
          ParamExpr := Expr + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(KeyWordID) + ParamExpr;
        End Else
          If KeyWordID <> SP_KW_ROTATE Then Begin
            Error.Code := SP_ERR_SYNTAX_ERROR;
            Exit;
          End Else
            ParamExpr := Expr + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(KeyWordID) + ParamExpr;
      End Else
        Break;
    End Else
      Break;
  End;

  If Error.Code = SP_ERR_OK Then
    Result := ParamExpr + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(NumTransforms) + DstExpr + SrcExpr;

End;

Function  SP_Convert_PROJECT3D(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarPos, VarSize: Integer;
  VarType: aChar;
  VarName, MoveStr, RotateStr, ScaleStr: aString;
  GotRotate, GotMove, GotScale: Boolean;
  ParamFlags: Byte;
Begin

  // PROJECT3D src() TO dst() [MOVE dx,dy,dz] [ROTATE rx,ry,rz|POINT px,py,pz] [SCALE sx,sy,sz]

  GotRotate := False;
  GotMove := False;
  GotScale := False;
  Result := '';
  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
      Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
      Inc(Position, 4);
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
        Inc(Position, 1 + SizeOf(LongWord));
        If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
          VarPos := Position;
          VarType := Tokens[Position];
          Inc(Position, 1 + SizeOf(LongWord));
          VarSize := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
          VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
          Inc(Position, VarSize);
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
             (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
            Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName + Result;
            Inc(Position, 4);
            ParamFlags := 0;
            While True Do Begin
              If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ROTATE) Then Begin
                Inc(Position, SizeOf(LongWord) +1);
                RotateStr := SP_Convert_Expr(Tokens, Position, Error, -1); // rX
                If Error.Code <> SP_ERR_OK Then Exit Else
                  If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End;
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                  Inc(Position, 2);
                  RotateStr := SP_Convert_Expr(Tokens, Position, Error, -1) + RotateStr; // rY
                  If Error.Code <> SP_ERR_OK Then Exit Else
                    If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    RotateStr := SP_Convert_Expr(Tokens, Position, Error, -1) + RotateStr; // rZ
                    If Error.Code <> SP_ERR_OK Then Exit Else
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    GotRotate := True;
                  End Else
                    Error.Code := SP_ERR_SYNTAX_ERROR;
                End Else
                  Error.Code := SP_ERR_SYNTAX_ERROR;
              End Else
                If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SCALE) Then Begin
                  Inc(Position, SizeOf(LongWord) +1);
                  ScaleStr := SP_Convert_Expr(Tokens, Position, Error, -1); // sX
                  If Error.Code <> SP_ERR_OK Then Exit Else
                    If Error.ReturnType <> SP_VALUE Then Begin
                      Error.Code := SP_ERR_MISSING_NUMEXPR;
                      Exit;
                    End;
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                    Inc(Position, 2);
                    ScaleStr := SP_Convert_Expr(Tokens, Position, Error, -1) + ScaleStr; // sY
                    If Error.Code <> SP_ERR_OK Then Exit Else
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      ScaleStr := SP_Convert_Expr(Tokens, Position, Error, -1) + ScaleStr; // sZ
                      If Error.Code <> SP_ERR_OK Then Exit Else
                        If Error.ReturnType <> SP_VALUE Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Exit;
                        End;
                      GotScale := True;
                    End Else
                      Error.Code := SP_ERR_SYNTAX_ERROR;
                  End Else
                    Error.Code := SP_ERR_SYNTAX_ERROR;
                End Else
                  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_MOVE) Then Begin
                    Inc(Position, SizeOf(LongWord) +1);
                    MoveStr := SP_Convert_Expr(Tokens, Position, Error, -1); // mX
                    If Error.Code <> SP_ERR_OK Then Exit Else
                      If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End;
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      MoveStr := SP_Convert_Expr(Tokens, Position, Error, -1) + MoveStr; // mY
                      If Error.Code <> SP_ERR_OK Then Exit Else
                        If Error.ReturnType <> SP_VALUE Then Begin
                          Error.Code := SP_ERR_MISSING_NUMEXPR;
                          Exit;
                        End;
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                        Inc(Position, 2);
                        MoveStr := SP_Convert_Expr(Tokens, Position, Error, -1) + MoveStr; // mZ
                        If Error.Code <> SP_ERR_OK Then Exit Else
                          If Error.ReturnType <> SP_VALUE Then Begin
                            Error.Code := SP_ERR_MISSING_NUMEXPR;
                            Exit;
                          End;
                        GotMove := True;
                      End Else
                        Error.Code := SP_ERR_SYNTAX_ERROR;
                    End Else
                      Error.Code := SP_ERR_SYNTAX_ERROR;
                  End Else
                    Break;
            End;
            If GotRotate Then Begin
              Inc(ParamFlags);
              Result := Result + RotateStr;
            End;
            If GotScale Then Begin
              Inc(ParamFlags, 2);
              Result := Result + ScaleStr;
            End;
            If GotMove Then Begin
              Inc(ParamFlags, 4);
              Result := Result + MoveStr;
            End;
            Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(ParamFlags);
          End Else
            Error.Code := SP_ERR_ARRAY_NOT_FOUND;
        End Else
          Error.Code := SP_ERR_ARRAY_NOT_FOUND;
      End Else
        Error.Code := SP_ERR_SYNTAX_ERROR;
    End Else
      Error.Code := SP_ERR_ARRAY_NOT_FOUND;
  End Else
    Error.Code := SP_ERR_INVALID_ARRAY_VAR;

End;

Function SP_Convert_RAINBOW(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // RAINBOW index1 TO index2

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then
    Exit
  Else
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin

    Inc(Position, SizeOf(LongWord) + 1);
    Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
    If Error.Code <> SP_ERR_OK Then
      Exit
    Else
      If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;

  End;

End;

Function  SP_Convert_KEYBOARD(Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // KEYBOARD name$

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code = SP_ERR_OK Then
    If Error.ReturnType <> SP_STRING Then
      Error.Code := SP_ERR_MISSING_STREXPR;

End;

Function  SP_Convert_ORIGIN(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr, FlipExpr: aString;
Begin

  // ORIGIN [OFF|x1,y1[,w,h| TO x2,y2][FLIP]]
  // ORIGIN FLIP

  Expr := '';
  Result := '';
  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FLIP) Then Begin
    Inc(Position, SizeOf(LongWord) +1);
    KeyWordID := SP_KW_ORIGIN_FLIP;
    Result := Expr;
    Exit;
  End Else Begin
    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_OFF) Then Begin
      Inc(Position, SizeOf(LongWord) +1);
      KeyWordID := SP_KW_ORG_OFF;
      Result := Expr;
      Exit;
    End Else Begin
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // X1
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Y1
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
          Inc(Position, 1 + SizeOf(LongWord));
          KeyWordID := SP_KW_ORIGIN;
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // x2
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // y2
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
          End Else Begin
            Error.Code := SP_ERR_MISSING_COMMA;
            Exit;
          End;
        End Else Begin
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // W
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // H
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              KeyWordID := SP_KW_ORG_DIM;
            End Else Begin
              Error.Code := SP_ERR_MISSING_COMMA;
              Exit;
            End;
          End;
          // no x2,y2 specified - specify ?? for them instead.
          KeyWordID := SP_KW_ORG_NO_EXT;
        End;
        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FLIP) Then Begin
          Inc(Position, SizeOf(LongWord) +1);
          FlipExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(1);
        End Else
          FlipExpr := CreateToken(SP_VALUE, Position, SizeOf(aFloat)) + aFloatToString(0);
        Result := FlipExpr + Expr;
        Exit;
      End Else
        Error.Code := SP_ERR_MISSING_COMMA;
    End;
  End;

End;

Function  SP_Convert_BEEP(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr: aString;
Begin

  // BEEP duration,{pitch|pitch$} [FORMAT WaveType,Attack,Decay,Sustain,Release,Noise,Roughness] [ASYNC]

  Result := '';
  Expr := SP_Convert_Expr(Tokens, Position, Error, -1); // Duration
  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
    Error.Code := SP_ERR_MISSING_NUMEXPR;
    Exit;
  End;

  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin

    Inc(Position, 2);
    Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Pitch or String-Pitch
    If Error.Code <> SP_ERR_OK Then Exit;

    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_FORMAT) Then Begin

      Inc(Position, 1 + SizeOf(LongWord));

      Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Wavetype
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End Else
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Attack
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End Else
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Decay
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End Else
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                  Inc(Position, 2);
                  Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Sustain
                  If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                    Error.Code := SP_ERR_MISSING_NUMEXPR;
                    Exit;
                  End Else
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Release
                      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                        Error.Code := SP_ERR_MISSING_NUMEXPR;
                        Exit;
                      End Else
                        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                          Inc(Position, 2);
                          Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Noise
                          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                            Error.Code := SP_ERR_MISSING_NUMEXPR;
                            Exit;
                          End Else
                            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                              Inc(Position, 2);
                              Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + Expr; // Roughness
                              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                                Error.Code := SP_ERR_MISSING_NUMEXPR;
                                Exit;
                              End;
                            End Else Begin
                              Error.Code := SP_ERR_MISSING_COMMA;
                              Exit;
                            End;
                        End Else Begin
                          Error.Code := SP_ERR_MISSING_COMMA;
                          Exit;
                        End;
                    End Else Begin
                      Error.Code := SP_ERR_MISSING_COMMA;
                      Exit;
                    End;
                End Else Begin
                  Error.Code := SP_ERR_MISSING_COMMA;
                  Exit;
                End;
            End Else Begin
              Error.Code := SP_ERR_MISSING_COMMA;
              Exit;
            End;
        End Else Begin
          Error.Code := SP_ERR_MISSING_COMMA;
          Exit;
        End;

    End;

    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ASYNC) Then Begin
      Inc(Position, 1 + SizeOf(LongWord));
      Expr := Expr + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1);
    End Else
      Expr := Expr + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);

    Result := Expr;

  End Else
    Error.Code := SP_ERR_MISSING_COMMA;

End;

Function  SP_Convert_OUT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Expr, VarExpr: aString;
  Psn: Integer;
Begin

  // OUT stream-id|var$|SCREEN

  Result := '';
  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_SCREEN) Then Begin
    Inc(Position, SizeOf(LongWord) +1);
    KeyWordID := SP_KW_OUT_SCREEN;
    Expr := '';
  End Else
    If (Byte(Tokens[Position]) = SP_STRVAR) Then Begin
      KeyWordID := SP_KW_OUT_VAR;
      Psn := Position;
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1) + CreateToken(SP_SYMBOL, Psn, 1) + '~';
      Position := Psn;
      VarExpr := SP_Convert_Var_Assign(Tokens, Position, Error);
      If Error.Code = SP_ERR_OK Then Begin
        Expr := Expr + VarExpr;
        Expr := CreateToken(SP_STRING, Psn, Length(Expr)) + Expr;
        Expr := CreateToken(SP_STRING, Psn, Length(VarExpr)) + VarExpr + Expr;
      End Else
        Exit;
    End Else Begin
      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code <> SP_ERR_OK Then
        Exit
      Else
        If Error.ReturnType = SP_VALUE Then
          KeyWordID := SP_KW_OUT_STREAM
        Else Begin
          Error.Code := SP_ERR_SYNTAX_ERROR;
          Exit;
        End;
    End;

  Result := Expr;

End;

Function  SP_Convert_SHOWGUIDE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // SHOWGUIDE filename$,topic$
  // SHOWGUIDE bank-id,nodeID$

End;

Function  SP_Convert_HELP(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // HELP (opens at TOC)
  // HELP keyword$

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code = SP_ERR_OK Then
    If Result = '' Then
      Result := CreateToken(SP_STRING, 0, 0)
    Else
      If Error.ReturnType <> SP_STRING Then Begin
        Error.Code := SP_ERR_MISSING_STREXPR;
        Exit;
      End;

End;

Function  SP_Convert_BORDER(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // BORDER {colour|tex$|GRAPHIC id} [SIZE pixels]

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code = SP_ERR_OK Then
    If Result = '' Then
      Result := CreateToken(SP_STRING, 0, 0)
    Else
      If Error.ReturnType <> SP_STRING Then Begin
        Error.Code := SP_ERR_MISSING_STREXPR;
        Exit;
      End;

End;

Function  SP_Convert_CASE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // CASE expression [ALL]
  // Store the expression and the line/statement number (picked up during pre-processing) of the END CASE

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ALL) Then Begin
    Inc(Position, 1 + SizeOf(LongWord));
    Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1); // Flag ALL
  End Else
    Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0); // Flag only one WHEN
  Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);   // Line number
  Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);   // Statement number

End;

Function  SP_Convert_WHEN(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // WHEN expression|IN [ranges...]
  // AS for CASE, store the expression to be compared and the line/statement number - again, picked up during pre-processing
  // of the next WHEN statement

  Result := '';
  If (Byte(Tokens[Position]) = SP_FUNCTION) And (pLongWord(@Tokens[Position +1])^ = SP_FN_IN) Then Begin

    Inc(Position, 1 + SizeOf(Integer));
    Result := SP_Process_IN(Tokens, Position, Error);
    KeyWordID := SP_KW_WHEN_IN;

  End Else

    Result := SP_Convert_Expr(Tokens, Position, Error, -1);

  If Error.Code <> SP_ERR_OK Then Exit;

  Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0); // Line number
  Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0); // Statement number

End;

Function  SP_Convert_OTHERWISE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // OTHERWISE
  // Takes no expression or parameters - execution continues and the CASE is closed

  Result := '';

End;

Function  SP_Convert_END_CASE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // END CASE
  // Takes no expression or parameters. Removes the CASE from the stack, and continues operation.

  Result := '';

End;

Function  SP_Convert_INCLUDE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  FileCount: Integer;
Begin

  // INCLUDE filename$[,filename$]

  Result := '';

  FileCount := 0;
  While True Do Begin

    Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
    If (Error.Code <> SP_ERR_OK) or (Error.ReturnType <> SP_STRING) Then
      Exit
    Else Begin
      Inc(FileCount);
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
        Inc(Position, 2)
      Else
        Break;
    End;

  End;

  Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(FileCount);

End;

Function  SP_Convert_HALT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // Do nothing, this command has no parameters.

  Result := '';

End;

Function  SP_Convert_SORT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarPos, VarSize, Key: Integer;
  VarType: aChar;
  VarName: aString;
Begin

  // SORT [KEY] array$()|Array() [INVERSE]

  Result := '';
  Key := -1;
  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_KEY) Then Begin
    Key := 1;
    Inc(Position, 1 + SizeOf(LongWord));
  End;

  If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
      Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
      Inc(Position, 4);
      Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(Key);
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_INVERSE) Then Begin
        Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(-1);
        Inc(Position, SizeOf(LongWord) +1);
      End Else
        Result := Result + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1);
    End Else
      Error.Code := SP_ERR_ARRAY_NOT_FOUND;
  End Else
    Error.Code := SP_ERR_INVALID_ARRAY_VAR;

End;

Function SP_Convert_KEY(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarType: Byte;
  VarPos, Idx, NumIndices: Integer;
  VarSize: LongWord;
  VarName, VarExpr, IndexExpr: aString;
Begin

  // KEY array$(index|key$)=key$
  // KEY array$([index|key$]) CLEAR

  Result := '';

  If Not (Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR]) Then Begin
    Error.Code := SP_ERR_MISSING_VARIABLE;
    Exit;
  End;

  // Get info about the array name

  VarType := Byte(Tokens[Position]);
  Inc(Position);
  VarPos := Position;
  Inc(Position, SizeOf(LongWord));
  VarSize := pLongWord(@Tokens[Position])^;
  Inc(Position, SizeOf(LongWord));
  VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
  Inc(Position, VarSize);

  VarExpr := CreateToken(VarType, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;

  // Now pull out the index

  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') Then Begin

    Inc(Position, 2);

    // If a close-bracket follows, then CLEAR must follow.

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ')') Then Begin

      Inc(Position, 2);
      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CLEAR) Then Begin

        Inc(Position, 1 + SizeOf(LongWord));
        Result := VarExpr;
        KeyWordID := SP_KW_KEY_CLEAR_ALL;

      End Else
        Error.Code := SP_ERR_SYNTAX_ERROR;

      Exit;

    End;

    IndexExpr := SP_ExtractArray(Tokens, Position, False, Error);

    // Convert the array assign token to a simple number so it doesn't get evaluated at runtime until
    // we need it.

    Idx := Length(IndexExpr) - (SizeOf(TToken) + SizeOf(LongWord) -1);
    NumIndices := pLongWord(@IndexExpr[Length(IndexExpr) - SizeOf(LongWord) +1])^;
    IndexExpr := Copy(IndexExpr, 1, Idx -1) + CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(NumIndices);

    if Error.ReturnType = SP_ARRAY Then Begin

      Result := IndexExpr + VarExpr;
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '=') Then Begin

        Inc(Position, 2);
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
        If Error.ReturnType <> SP_STRING Then
          Error.Code := SP_ERR_MISSING_STREXPR;

      End Else

        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_CLEAR) Then Begin

          Inc(Position, SizeOf(LongWord) +1);
          KeyWordID := SP_KW_KEY_CLEAR;

        End Else

          Error.Code := SP_ERR_SYNTAX_ERROR;

    End Else

      Error.Code := SP_ERR_SYNTAX_ERROR;

  End Else

   Error.Code := SP_ERR_SYNTAX_ERROR;

End;

Function  SP_Convert_MAT(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarPos, VarSize: Integer;
  VarName, Expr: aString;
  VarType: aChar;
  Done: Boolean;
Begin

  // Matrix maths with arrays. One or two dimensional only.

  // MAT A()=B()                    Substitution
  // MAT A()=B()+C()                Matrix operation (addition)
  // MAT A()=B()-C()                Matrix operation (subtraction)
  // MAT A()=B()*C()                Matrix operation (product)
  // MAT A()=B()*x                  Scalar multiplication
  // MAT A()=ZER                    The zero matrix
  // MAT A()=IDN                    The Identity matrix
  // MAT A()=CON                    The matrix all of whose elements are a constant (one)
  // MAT A()=INV B()                The inverse matrix
  // MAT A()=TRN B()                The transposed matrix
  // MAT A()=INTERP B(),C(),Amount  Interpolates between two arrays into a third by amount (0 to 1)

  // First, we expect the destination matrix which should be a numeric variable followed by closed braces:

  Result := '';
  If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
      Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
      Inc(Position, 4);
    End Else
      Error.Code := SP_ERR_ARRAY_NOT_FOUND;
  End Else
    Error.Code := SP_ERR_INVALID_ARRAY_VAR;

  // Now an = symbol

  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] <> '=') Then Begin
    Error.Code := SP_ERR_SYNTAX_ERROR;
    Exit;
  End Else
    Inc(Position, 2);

  // Now either one of the keyword ZER, IDN, CON, INV or TRN
  // or another array var. Let's deal with the keywords first.

  If (Byte(Tokens[Position]) in [SP_KEYWORD, SP_FUNCTION]) Then Begin

    Inc(Position);
    Case pLongWord(@Tokens[Position])^ of
      SP_FN_INTERP:
        Begin
          Inc(Position, SizeOf(LongWord));
          If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
            VarPos := Position;
            VarType := Tokens[Position];
            Inc(Position, 1 + SizeOf(LongWord));
            VarSize := pLongWord(@Tokens[Position])^;
            Inc(Position, SizeOf(LongWord));
            VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
            Inc(Position, VarSize);
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
               (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
              Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName + Result;
              Inc(Position, 4);
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
                  VarPos := Position;
                  VarType := Tokens[Position];
                  Inc(Position, 1 + SizeOf(LongWord));
                  VarSize := pLongWord(@Tokens[Position])^;
                  Inc(Position, SizeOf(LongWord));
                  VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
                  Inc(Position, VarSize);
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
                     (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
                    Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName + Result;
                    Inc(Position, 4);
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
                      KeyWordID := SP_KW_MAT_INTERP;
                    End Else Begin
                      Error.Code := SP_ERR_SYNTAX_ERROR;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_ARRAY_NOT_FOUND;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_INVALID_ARRAY_VAR;
                End;
              End Else Begin
                Error.Code := SP_ERR_SYNTAX_ERROR;
              End;
            End Else Begin
              Error.Code := SP_ERR_ARRAY_NOT_FOUND;
            End;
          End Else Begin
            Error.Code := SP_ERR_INVALID_ARRAY_VAR;
          End;
        End;
      SP_KW_MAT_IDN:
        Begin
          KeyWordID := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If (Error.Code = SP_ERR_OK) And (Expr <> '') Then KeyWordID := SP_KW_MAT_IDN_PARAM;
          Result := Result + Expr;
        End;
      SP_KW_MAT_CON:
        Begin
          KeyWordID := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
          Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
          If (Error.Code = SP_ERR_OK) And (Expr <> '') Then KeyWordID := SP_KW_MAT_CON_PARAM;
          Result := Result + Expr;
        End;
      SP_KW_MAT_ZER:
        Begin
          KeyWordID := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
        End;
      SP_KW_MAT_INV, SP_KW_MAT_TRN:
        Begin
          // Expect another array descriptor here
          KeyWordID := pLongWord(@Tokens[Position])^;
          Inc(Position, SizeOf(LongWord));
          If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
            VarPos := Position;
            VarType := Tokens[Position];
            Inc(Position, 1 + SizeOf(LongWord));
            VarSize := pLongWord(@Tokens[Position])^;
            Inc(Position, SizeOf(LongWord));
            VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
            Inc(Position, VarSize);
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
               (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
              Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName + Result;
              Inc(Position, 4);
            End Else Begin
              Error.Code := SP_ERR_ARRAY_NOT_FOUND;
            End;
          End Else Begin
            Error.Code := SP_ERR_INVALID_ARRAY_VAR;
          End;
        End;
    Else
      Error.Code := SP_ERR_SYNTAX_ERROR;
    End;

  End Else Begin

    // If we find an array var here, we're looking at matrix math ops.

    If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
      VarPos := Position;
      VarType := Tokens[Position];
      Inc(Position, 1 + SizeOf(LongWord));
      VarSize := pLongWord(@Tokens[Position])^;
      Inc(Position, SizeOf(LongWord));
      VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
      Inc(Position, VarSize);
      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
         (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
        Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName + Result;
        Inc(Position, 4);

        // Now check for the matrix math operation.

        If Byte(Tokens[Position]) = SP_SYMBOL Then Begin

          Inc(Position);

          Case Tokens[Position] of

            '+', '-':
              Begin
                Case Tokens[Position] of
                  '+': KeyWordID := SP_KW_MAT_ADD;
                  '-': KeyWordID := SP_KW_MAT_SUB;
                End;
                Inc(Position);
                VarPos := Position;
                VarType := Tokens[Position];
                Inc(Position, 1 + SizeOf(LongWord));
                VarSize := pLongWord(@Tokens[Position])^;
                Inc(Position, SizeOf(LongWord));
                VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
                Inc(Position, VarSize);
                If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
                   (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
                  Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName + Result;
                  Inc(Position, 4);
                End;
              End;

            '*':
              Begin
                Inc(Position);
                Done := False;
                If Byte(Tokens[Position]) = SP_NUMVAR Then Begin
                  VarPos := Position;
                  VarType := Tokens[Position];
                  Inc(Position, 1 + SizeOf(LongWord));
                  VarSize := pLongWord(@Tokens[Position])^;
                  Inc(Position, SizeOf(LongWord));
                  VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
                  Inc(Position, VarSize);
                  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
                     (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
                    Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName + Result;
                    Inc(Position, 4);
                    KeyWordID := SP_KW_MAT_PROD;
                    Done := True;
                  End Else
                    Position := VarPos;
                End;

                If Not Done Then Begin

                  Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result;
                  KeyWordID := SP_KW_MAT_SCALE;

                End;

              End;

          Else
            Dec(Position);
            Exit;
          End;

        End;

      End Else
        Error.Code := SP_ERR_ARRAY_NOT_FOUND;

    End Else
      Error.Code := SP_ERR_INVALID_ARRAY_VAR;

  End;

End;

Function  SP_Convert_CONST(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarType: Byte;
  VarPos, Idx, vIdx, LastType: Integer;
  VarSize: LongWord;
  VarName, Expr, tResult: aString;
  VarExpr: Array of aString;
  Token: pToken;
Label
  Next_Const;
Begin

  // CONST var[$][,var[$]]=Value[$][,...]

  // Const sets a constant. At pre-parse time, constants are identified when attached to the CONST keyword, and their usage is
  // replaced throughout - from a variable into an actual string or numeric value. Hence they are faster than variables.

  // Expressions can be used as the values, but cannot rely on any state information that is not available at pre-parsing, so
  // CONST a=1+2*4 is fine, but CONST a=mSECS+500 is not.

  // To check this, the expression - once converted to postfix - should be a single value or string.

  Result := '';
  vIdx := -1;
  LastType := -1;

Next_Const:

  If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin

    VarType := Byte(Tokens[Position]);
    Inc(Position);

    If LastType <> -1 Then
      If LastType <> VarType Then Begin
        Error.Code := SP_ERR_SYNTAX_ERROR;
        Exit;
      End;

    VarPos := Position;
    Inc(Position, SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);

    Inc(vIdx);
    SetLength(VarExpr, vIdx +1);
    VarExpr[vIdx] := CreateToken(VarType, VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
    LastType := VarType;

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
      Inc(Position, 2);
      Goto Next_Const;
    End;

    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '=') Then Begin

      Inc(Position, 2);

      Expr := SP_Convert_Expr(Tokens, Position, Error, -1);
      If Error.Code = SP_ERR_OK Then
        If Expr <> '' Then Begin
          Idx := 1;
          Token := @Expr[Idx];
          Inc(Idx, SizeOf(TToken));
          If Token^.Token in [SP_VALUE, SP_STRING] Then Begin

            Inc(Idx, Token^.TokenLen);
            If Idx <= Length(Expr) Then
              Error.Code := SP_ERR_SYNTAX_ERROR
            Else Begin

              For vIdx := 0 To Length(VarExpr) -1 Do Begin
                tResult := CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_CONST);
                tResult := tResult + VarExpr[vIdx] + Expr;
                Result := Result + tResult;
              End;
              KeyWordID := 0;

              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                vIdx := -1;
                LastType := -1;
                Goto Next_Const;
              End;

              Result := CreateToken(SP_SKIP_STATEMENT, 0, SizeOf(LongWord)) + LongWordToString(Length(Result)) + Result;

            End;

          End Else
            Error.Code := SP_ERR_SYNTAX_ERROR;

        End Else
          Error.Code := SP_ERR_SYNTAX_ERROR;

    End Else

      Error.Code := SP_ERR_SYNTAX_ERROR;

  End Else

    Error.Code := SP_ERR_MISSING_VARIABLE;


End;

Function  SP_Convert_ZONE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarResult: aString;
Begin

  // ZONE NEW var,x1,y1[,x2,y2| TO x2,y2]
  // ZONE MOVE id[,dx,dy| TO dstx,dsty]
  // ZONE UPDATE id,x1,y1 TO x2,y2
  // ZONE UPDATE id,x,y,w,h
  // ZONE ERASE id

  Result := '';

  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_NEW) Then Begin

    Inc(Position, 1 + SizeOf(LongWord));

    If Byte(Tokens[Position]) = SP_NUMVAR Then Begin

      VarResult := SP_Convert_Var_Assign(Tokens, Position, Error);
      If Error.Code <> SP_ERR_OK Then Exit;

      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
        Inc(Position, 2);
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // x1
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
          Error.Code := SP_ERR_MISSING_NUMEXPR;
          Exit;
        End;
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // y1
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
            Inc(Position, 1 + SizeOf(LongWord));
            Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // x2
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // y2
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End Else
                Result := Result + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_ZONE_NEW) + VarResult;
                If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
            End Else
              Error.Code := SP_ERR_SYNTAX_ERROR;
          End Else
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // x2
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End;
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // y2
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                  Error.Code := SP_ERR_MISSING_NUMEXPR;
                  Exit;
                End Else
                  Result := Result + CreateToken(SP_KEYWORD, 0, SizeOf(LongWord)) + LongWordToString(SP_KW_ZONE_NEW_B) + VarResult;
                  If pToken(@VarResult[1])^.Token in [SP_STRVAR_LET, SP_NUMVAR_LET] Then KeyWordID := 0 Else KeyWordID := SP_KW_LET;
              End Else
                Error.Code := SP_ERR_SYNTAX_ERROR;
            End Else
              Error.Code := SP_ERR_SYNTAX_ERROR;
        End Else
          Error.Code := SP_ERR_SYNTAX_ERROR;
      End Else
        Error.Code := SP_ERR_SYNTAX_ERROR;
    End Else
      Error.Code := SP_ERR_MISSING_VAR;

  End Else

    If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_MOVE) Then Begin

      Inc(Position, 1 + SizeOf(LongWord));
      Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Id
      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
        Error.Code := SP_ERR_MISSING_NUMEXPR;
        Exit;
      End Else
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
          Inc(Position, 2);
          Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // deltax
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
            Error.Code := SP_ERR_MISSING_NUMEXPR;
            Exit;
          End;
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // deltay
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End Else
              KeyWordID := SP_KW_ZONE_MOVE;
          End Else
            Error.Code := SP_ERR_SYNTAX_ERROR;
        End Else
          If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
            Inc(Position, 1 + SizeOf(LongWord));
            Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // destx
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
              Error.Code := SP_ERR_MISSING_NUMEXPR;
              Exit;
            End;
            If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
              Inc(Position, 2);
              Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // desty
              If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then Begin
                Error.Code := SP_ERR_MISSING_NUMEXPR;
                Exit;
              End Else
                KeyWordID := SP_KW_ZONE_MOVETO;
            End Else
              Error.Code := SP_ERR_SYNTAX_ERROR;
          End Else
            Error.Code := SP_ERR_SYNTAX_ERROR;

    End Else

      If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_UPDATE) Then Begin
        Inc(Position, SizeOf(LongWord) +1);
        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // Index
        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then
          Error.Code := SP_ERR_MISSING_NUMEXPR
        Else
          If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
            Inc(Position, 2);
            Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // x1
            If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then
              Error.Code := SP_ERR_MISSING_NUMEXPR
            Else
              If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                Inc(Position, 2);
                Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // y1
                If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then
                  Error.Code := SP_ERR_MISSING_NUMEXPR
                Else
                  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_TO) Then Begin
                    Inc(Position, 1 + SizeOf(LongWord));
                    Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // x2
                    If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then
                      Error.Code := SP_ERR_MISSING_NUMEXPR
                    Else
                      If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                        Inc(Position, 2);
                        Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // y2
                        If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then
                          Error.Code := SP_ERR_MISSING_NUMEXPR
                        Else
                          KeyWordID := SP_KW_ZONE_UPDATE;
                      End Else
                        Error.Code := SP_ERR_SYNTAX_ERROR;
                  End Else
                    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                      Inc(Position, 2);
                      Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // x2
                      If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then
                        Error.Code := SP_ERR_MISSING_NUMEXPR
                      Else
                        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
                          Inc(Position, 2);
                          Result := SP_Convert_Expr(Tokens, Position, Error, -1) + Result; // y2
                          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then
                            Error.Code := SP_ERR_MISSING_NUMEXPR
                          Else
                            KeyWordID := SP_KW_ZONE_UPDATE_B;
                        End Else
                          Error.Code := SP_ERR_SYNTAX_ERROR;
                    End Else
                      Error.Code := SP_ERR_SYNTAX_ERROR;
              End Else
                Error.Code := SP_ERR_SYNTAX_ERROR;
          End Else
            Error.Code := SP_ERR_SYNTAX_ERROR;

      End Else

        If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ERASE) Then Begin

          Inc(Position, SizeOf(LongWord) +1);
          Result := SP_Convert_Expr(Tokens, Position, Error, -1); // Id
          If Error.Code <> SP_ERR_OK Then Exit Else If Error.ReturnType <> SP_VALUE Then
            Error.Code := SP_ERR_MISSING_NUMEXPR
          Else
            KeyWordID := SP_KW_ZONE_ERASE;

        End;


End;

Function SP_Convert_UNDIM(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarPos, VarSize: Integer;
  VarType: aChar;
  VarName: aString;
Begin

  // UNDIM array$()|Array()

  Result := '';
  If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
      Result := CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
      Inc(Position, 4);
    End Else
      Error.Code := SP_ERR_ARRAY_NOT_FOUND;
  End Else
    Error.Code := SP_ERR_INVALID_ARRAY_VAR;

End;

Function  SP_Convert_FILTER(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Var
  VarPos, VarSize: Integer;
  VarType: aChar;
  VarName: aString;
Begin

  // FILTER [ERASE] a$(), MATCH$
  // FILTER [ERASE] a(), [RANGEs]

  Result := '';
  If (Byte(Tokens[Position]) = SP_KEYWORD) And (pLongWord(@Tokens[Position +1])^ = SP_KW_ERASE) Then Begin
    Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(1);
    Inc(Position, SizeOf(LongWord) +1);
  End Else
    Result := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0);

  // Check for an array - string or numeric determines future syntax.

  If Byte(Tokens[Position]) in [SP_NUMVAR, SP_STRVAR] Then Begin
    VarPos := Position;
    VarType := Tokens[Position];
    Inc(Position, 1 + SizeOf(LongWord));
    VarSize := pLongWord(@Tokens[Position])^;
    Inc(Position, SizeOf(LongWord));
    VarName := LowerNoSpaces(Copy(Tokens, Position, VarSize));
    Inc(Position, VarSize);
    If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '(') And
       (Byte(Tokens[Position +2]) = SP_SYMBOL) And (Tokens[Position +3] = ')') Then Begin
      Result := Result + CreateToken(Byte(VarType), VarPos, SizeOf(LongWord)+Length(VarName)) + LongWordToString(0) + VarName;
      Inc(Position, 4);
    End Else Begin
      Error.Code := SP_ERR_ARRAY_NOT_FOUND;
      Exit;
    End;
  End Else Begin
    Error.Code := SP_ERR_INVALID_ARRAY_VAR;
    Exit;
  End;

  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then
    Inc(Position, 2)
  Else Begin
    Error.Code := SP_ERR_SYNTAX_ERROR;
    Exit;
  End;

  // For a string array, there follows a string expr to match.
  // For a numeric array, there is either a value to match, or a range in []s.

  Case Ord(VarType) of

    SP_NUMVAR:
      Begin
        If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = '[') Then Begin
          Result := Result + SP_Process_IN(Tokens, Position, Error);
          KeyWordID := SP_KW_FILTER_NUM_R;
        End Else Begin
          Result := Result + SP_Convert_Expr(Tokens, Position, Error, -1);
          If Error.ReturnType <> SP_VALUE Then
            Error.Code := SP_ERR_MISSING_NUMEXPR;
          KeyWordID := SP_KW_FILTER_NUM;
        End;
      End;

    SP_STRVAR:
      Begin
        Result := Result + SP_Convert_expr(Tokens, Position, Error, -1);
        If Error.ReturnType <> SP_STRING Then
          Error.Code := SP_ERR_MISSING_STREXPR;
        KeyWordID := SP_KW_FILTER_STR;
      End;

  End;

End;

Function SP_Convert_MEMWRITE(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // MEMWRT[DQF] Addr, byte/word/longword/float value

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then Exit;
  If Error.ReturnType <> SP_VALUE Then Begin
    Error.Code := SP_ERR_MISSING_NUMEXPR;
    Exit;
  End;
  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
    Inc(Position, 2);
    Result := Result + SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_VALUE Then Begin
      Error.Code := SP_ERR_MISSING_NUMEXPR;
      Exit;
    End;
  End Else
    Error.Code := SP_ERR_ILLEGAL_CHAR;

End;

Function SP_Convert_MEMWRITES(Var KeyWordID: LongWord; Var Tokens: aString; Var Position: Integer; Var Error: TSP_ErrorCode): aString;
Begin

  // MEMWRT$ Addr, String

  Result := SP_Convert_Expr(Tokens, Position, Error, -1);
  If Error.Code <> SP_ERR_OK Then Exit;
  If Error.ReturnType <> SP_VALUE Then Begin
    Error.Code := SP_ERR_MISSING_NUMEXPR;
    Exit;
  End;
  If (Byte(Tokens[Position]) = SP_SYMBOL) And (Tokens[Position +1] = ',') Then Begin
    Inc(Position, 2);
    Result := Result + SP_Convert_Expr(Tokens, Position, Error, -1);
    If Error.Code <> SP_ERR_OK Then Exit;
    If Error.ReturnType <> SP_STRING Then Begin
      Error.Code := SP_ERR_MISSING_STREXPR;
      Exit;
    End;
  End Else
    Error.Code := SP_ERR_ILLEGAL_CHAR;

End;

end.



