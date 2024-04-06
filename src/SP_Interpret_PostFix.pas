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
// SpecBAS is distributed in the hope that it will be entertaining
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with SpecBAS.  If not, see <http://www.gnu.org/licenses/>.

Unit SP_Interpret_PostFix;
{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}
{$FINITEFLOAT OFF}

interface

Uses SyncObjs, Forms, {$IFNDEF FPC}IOUtils,{$ELSE}FileUtil,{$ENDIF} SP_Util, SP_Graphics, SP_Graphics32, SP_SysVars, SP_Errors, SP_Components, SP_Tokenise, SP_InfixToPostFix, SP_FileIO,
     SP_Input, SP_BankManager, SP_BankFiling, SP_Streams, SP_Sound, SP_Package, Math, Classes, SysUtils, SP_Math, Clipbrd,
     {$IFDEF FPC}LclIntf{$ELSE}Windows{$ENDIF}, SP_Strings, SP_Menu, SP_UITools, SP_AnsiStringlist, SP_Variables;

Type

  TFnVar = Packed Record
    ID: Byte;
    Len: LongWord;
  End;
  pFnVar = ^TFnVar;

  SP_IncludedFile = Packed Record
    LineStart,
    LineEnd,
    JumpOffset: Integer;
  End;
  pSP_IncludedFile = ^SP_IncludedFile;

  SP_Function_Record = Packed Record
    Name: aString;
    Expr: aString;
    ParamCount: Integer;
    ParamList: aString;
  End;

  SP_StackItem = Record
    OpType: Byte;
    Ptr: pLongWord;
    Val: aFloat;
    Str: aString;
    tPos: NativeUInt;
  End;
  pSP_StackItem = ^SP_StackItem;

  TSP_Label = Packed Record
    Name: aString;
    Dline, DStatement, DSt: Integer;
    Line, Statement, St: Integer;
  End;

  TSP_EveryItem = Packed Record
    HasCondition: Boolean;
    Cond: aString;
    FrameStart, FrameCounter, JumpSt, JumpLine, JumpStatement: LongWord;
  End;

  TSP_CaseItem = Packed Record
    ExpressionType: Integer;
    Expression: aFloat;
    ExpressionStr: aString;
    Line, Statement: Integer;
    Completed: Boolean;
    AllFlag: Boolean;
  End;

  TSP_WatchInfo = Packed Record
    Expression,
    Compiled_Expression: aString;
  End;

  TSP_BreakpointInfo = Packed Record
    bpType: Integer;
    PassCount, PassNum: Integer;
    Condition: aString;
    Compiled_Condition: aString;
    CurResult: aString;
    HasResult: Boolean;
    Line, Statement: Integer;
  End;
  pSP_BreakPointInfo = ^TSP_BreakPointInfo;

  TSP_iInfo = Packed Record
    StrPtr: pByte;
    StrStart: pByte;
    Tokens: paString;
    SavePos: NativeUInt;
    Token: pToken;
    Position: Integer;
    Error: pSP_ErrorCode;
  End;
  pSP_iInfo = ^TSP_iInfo;

  TSP_InterpretProc = Procedure(Var Info: pSP_iInfo);
  pSP_InterpretProc = ^TSP_InterpretProc;

Procedure SP_Execute(Line: aString; InitInterpreter: Boolean; Var Error: TSP_ErrorCode);
Procedure SP_Interpreter(Var Tokens: paString; Var Position: Integer; Var Error: TSP_ErrorCode; PreParseErrorCode: Integer; Continue: Boolean = False);

Procedure DoPeriodicalEvents(var Error: TSP_ErrorCode);
Procedure SP_AddEvery(const Condition: aString; Every, LineNum, Statement, St: Integer; UsesError: Boolean);
Procedure ClearFlags;
Procedure SP_CheckONConditions(Var Error: TSP_ErrorCode);
Procedure SP_CheckEvery(FrameCheck: Boolean; Position: Integer; Var Error: TSP_ErrorCode);
Procedure SP_ClearEvery;
Procedure SP_StackToString(NumIndices: Integer); inline;
Procedure SP_SetHandler(Var Token: pToken; Var StrPtr: pByte);
Procedure SP_AddHandlers(Var Tokens: aString);
Procedure SP_AddWatch(Index: Integer; Expr: aString);
Procedure SP_DeleteWatch(Index: Integer);
Function  SP_BreakPointExists(Line, Statement: Integer): Boolean;
Procedure SP_AddSourceBreakPoint(Hidden: Boolean; Line, Statement, Passes: Integer; Condition: aString);
Procedure SP_AddConditionalBreakpoint(BpIndex, Passes: Integer; Condition: aString; IsData: Boolean);
Procedure SP_MakeListVarOutput(Var List: TAnsiStringlist; UseLiterals: Boolean);
Function  SP_ConvertToTokens(Const s: aString; Var Error: TSP_ErrorCode): aString;

Procedure SP_InterpretCONTSafe(Const Tokens: paString; Var nPosition: Integer; Var Error: TSP_ErrorCode);
Procedure SP_Interpret(Const Tokens: paString; Var nPosition: Integer; Var Error: TSP_ErrorCode);

Procedure SP_Interpret_COMPILE(Var Info: pSP_iInfo);
Procedure SP_Interpret_UNHANDLED(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_STK(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_STKS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_CLIPS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SCREENS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_JOINS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_TEXTURES(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MSECS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_NUBMODE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_NUBX(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_NUBY(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_BTSET(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_BTCLR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ITEM(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_GPOINT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_GRGB(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_GHSV(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_WINX(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_WINY(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_GFXW(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_GFXH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_GFXT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_GFXS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_TIME(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_DAYS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MONTHS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_DAY(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MONTH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_YEAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_HOUR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MINUTES(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SECONDS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MILLISECONDS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FRAMES(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SPFRADDR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SPRITEX(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SPRITEY(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SPRITEW(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SPRITEH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SPVISIBLE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SPFCOUNT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SPROT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SPSCALE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_CALL(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_GETDIR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_BSIZE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SLEN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SPOS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FONTBANK(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FONTWIDTH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FONTHEIGHT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FONTMODE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FONTTRANSPARENT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LASTK(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_RADTODEG(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_DEGTORAD(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ERROR_NUM(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ERROR_LIN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ERROR_STA(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MOUSEX(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MOUSEWHEEL(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_DRPOSX(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_DRPOSY(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MOUSEY(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MOUSEDX(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MOUSEDY(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MOUSEBTN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_RND(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_INKEYS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_KEY(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_PI(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_TAU(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_HEADING(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_POINT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_VALS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_UPS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LOWS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LEFTS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_WINOFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MIDS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MID(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_RIGHTS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_REPS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_CODE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_DCODE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_QCODE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FCODE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_VAL(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_IVAL(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LEN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SIN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_COS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_TAN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ASN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ACS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ATN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SINH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_COSH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_TANH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ASNH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ACSH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ATNH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_EXP(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_INT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SQR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SGN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ABS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_IN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_USR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_STRS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_CHRS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_DCHRS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_QCHRS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FCHRS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_PARAMS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_POWER(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_PEEK(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_PEEKS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_DPEEK(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_QPEEK(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FPEEK(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_NOT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FRAC(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_CEIL(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FLOOR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MAX(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MIN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MAXS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MINS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ROUND(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_CHPOS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ODD(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_EVEN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_POS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_POSN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_INSTR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_INSTRN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_TRUNC(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_RED(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_GREEN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_BLUE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_RGB(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_HEXS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_BINS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_WINW(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_WINH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SCRW(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SCRH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_TXTW(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_TXTH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_CWIN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_RGBF(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_RGBN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_HSV(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_RGBC(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_iRGBF(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_iRGBN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_HUE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SAT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_VALUE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_NOISE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_NOISEOCT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MAP(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_RGBtoINT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_HSVtoINT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_RGBToHSV(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_HSVtoRGB(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_TRIMS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LTRIMS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_RTRIMS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_TOKENS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_UDGS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_UDG(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_GETTILE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_POWERTWO(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LOGTWO(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_WORDSWAP(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_BYTESWAP(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_NYBBLESWAP(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_POLAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_CLAMP(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_INRANGE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_INSERTS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ITEMS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_BIT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_HIWORD(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LOWORD(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_HIBYTE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LOBYTE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_POLARDIST(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LPADS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_RPADS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_PROCID(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ERRORS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_POPLINE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_POPST(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_VOL(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_GETOPT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_GETOPTS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MENUBOX(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MENUBOX_EX(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FEXISTS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FPATH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FNAME(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_REVS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_DEXISTS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_PYTH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LOGW(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LOGH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ORGX(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ORGY(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LTOPX(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LTOPY(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_PTOLX(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_PTOLY(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_INV(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_POLYTERM(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_UNDER(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_COMPSIMPSON(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MUSICPOS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MUSICLEN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_BASES(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_DECIMAL(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_IIF(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SEARCH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SEARCH_NEXT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LCM(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_GCD(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_DET(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SPFRAME(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SPCOLL(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_INZONE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MATCH(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_USINGS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LBOUND(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_UBOUND(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_ARSIZE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_DATES(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_TIMES(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_REPLACES(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_REPLACEMATCHS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MIATTR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LASTM(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_LASTMI(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_KEYS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SPCLX(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_SPCLY(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_DATADDR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_WINADDR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_STRADDR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MEMRD(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_DMEMRD(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_QMEMRD(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_MEMRDS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_FMEMRD(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_CHOOSE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_CHOOSES(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_BINV(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_BREV(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_INTERP(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN_PAR(Var Info: pSP_iInfo);

Procedure SP_FlushCentreBuffer(Var Info: pSP_iInfo);
Procedure SP_FlushOUTBuffer(Var Info: pSP_iInfo);

Procedure SP_Interpret_ERROR(Var Info: pSP_iInfo);
Procedure SP_Interpret_PRINT(Var Info: pSP_iInfo);
Procedure SP_Interpret_TEXT(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_AT(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_TAB(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_MOVE(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_INK(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_PAPER(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_INVERSE(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_OVER(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_TRANSPARENT(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_CURSOR(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_CLIP(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_CLIP_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_OUT_VAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_OUT_SCREEN(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_OUT_STREAM(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_SCALE(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_USING(Var Info: pSP_iInfo);
Procedure SP_Interpret_INK(Var Info: pSP_iInfo);
Procedure SP_Interpret_PAPER(Var Info: pSP_iInfo);
Procedure SP_Interpret_INVERSE(Var Info: pSP_iInfo);
Procedure SP_Interpret_OVER(Var Info: pSP_iInfo);
Procedure SP_Interpret_TRANSPARENT(Var Info: pSP_iInfo);
Procedure SP_Interpret_SCALE(Var Info: pSP_iInfo);
Procedure SP_Interpret_LET(Var Info: pSP_iInfo);
Procedure SP_Interpret_ENUM(Var Info: pSP_iInfo);
Procedure SP_Interpret_ENUM_BASE(Var Info: pSP_iInfo);
Procedure SP_Interpret_CLS(Var Info: pSP_iInfo);
Procedure SP_Interpret_DIM(Var Info: pSP_iInfo);
Procedure SP_Interpret_AUTODIM(Var Info: pSP_iInfo);
Procedure SP_Interpret_DIM_SPLIT(Var Info: pSP_iInfo);
Procedure SP_Interpret_RUN(Var Info: pSP_iInfo);
Procedure SP_Interpret_GOTO(Var Info: pSP_iInfo);
Procedure SP_Interpret_CONTINUE(Var Info: pSP_iInfo);
Procedure SP_Interpret_GOSUB(Var Info: pSP_iInfo);
Procedure SP_Interpret_RETURN(Var Info: pSP_iInfo);
Procedure SP_Interpret_STOP(Var Info: pSP_iInfo);
Procedure SP_Interpret_FOR(Var Info: pSP_iInfo);
Procedure SP_Interpret_NEXT(Var Info: pSP_iInfo);
Procedure SP_Interpret_IF(Var Info: pSP_iInfo);
Procedure SP_Interpret_PLOT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FORCE(Var Info: pSP_iInfo);
Procedure SP_Interpret_PARTICLE(Var Info: pSP_iInfo);
Procedure SP_Interpret_PAUSE(Var Info: pSP_iInfo);
Procedure SP_Interpret_DRAW(Var Info: pSP_iInfo);
Procedure SP_Interpret_DRAWTO(Var Info: pSP_iInfo);
Procedure SP_Interpret_DRAW_CTO(Var Info: pSP_iInfo);
Procedure SP_Interpret_MULTIDRAW(Var Info: pSP_iInfo);
Procedure SP_Interpret_MULTIDRAW_TO(Var Info: pSP_iInfo);
Procedure SP_Interpret_AMULTIDRAW(Var Info: pSP_iInfo);
Procedure SP_Interpret_AMULTIDRAW_TO(Var Info: pSP_iInfo);
Procedure SP_Interpret_CIRCLE(Var Info: pSP_iInfo);
Procedure SP_Interpret_ELLIPSE(Var Info: pSP_iInfo);
Procedure SP_Interpret_CIRCLEFILL(Var Info: pSP_iInfo);
Procedure SP_Interpret_ELLIPSEFILL(Var Info: pSP_iInfo);
Procedure SP_Interpret_CURVE(Var Info: pSP_iInfo);
Procedure SP_Interpret_CURVE_EX(Var Info: pSP_iInfo);
Procedure SP_Interpret_RANDOMIZE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SAVE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SAVEASCII(Var Info: pSP_iInfo);
Procedure SP_Interpret_SCREEN_SAVE(Var Info: pSP_iInfo);
Procedure SP_Interpret_GRAPHIC_SAVE(Var Info: pSP_iInfo);
Procedure SP_Interpret_LOAD(Var Info: pSP_iInfo);
Procedure SP_Interpret_MERGE(Var Info: pSP_iInfo);
Procedure SP_Interpret_INC(Var Info: pSP_iInfo);
Procedure SP_Interpret_INCRANGE(Var Info: pSP_iInfo);
Procedure SP_Interpret_DEC(Var Info: pSP_iInfo);
Procedure SP_Interpret_DECRANGE(Var Info: pSP_iInfo);
Procedure SP_Interpret_PALETTE(Var Info: pSP_iInfo);
Procedure SP_Interpret_PALETTE_HSV(Var Info: pSP_iInfo);
Procedure SP_Interpret_PALETTESHIFT(Var Info: pSP_iInfo);
Procedure SP_Interpret_DO(Var Info: pSP_iInfo);
Procedure SP_Interpret_DO_COUNT(Var Info: pSP_iInfo);
Procedure SP_Interpret_LOOP(Var Info: pSP_iInfo);
Procedure SP_Interpret_UNTIL(Var Info: pSP_iInfo);
Procedure SP_Interpret_WHILE(Var Info: pSP_iInfo);
Procedure SP_Interpret_EXIT(Var Info: pSP_iInfo);
Procedure SP_Interpret_QUIT(Var Info: pSP_iInfo);
Procedure SP_Interpret_READ(Var Info: pSP_iInfo);
Procedure SP_Interpret_READ_LINE(Var Info: pSP_iInfo);
Procedure SP_Interpret_READ_ASSIGN(Var Info: pSP_iInfo);
Procedure SP_Interpret_RESTORE(Var Info: pSP_iInfo);
Procedure SP_Interpret_DO_RESTORE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SCR_LOCK(Var Info: pSP_iInfo);
Procedure SP_Interpret_SCR_UNLOCK(Var Info: pSP_iInfo);
Procedure SP_Interpret_SCR_UPDATE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SCR_FULL(Var Info: pSP_iInfo);
Procedure SP_Interpret_SCR_WIN(Var Info: pSP_iInfo);
Procedure SP_Interpret_SCR_RES(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_NEW(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_MOVE(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_SIZE(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_SCROLL(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_ROLL(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_ERASE(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_SHOW(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_HIDE(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_FRONT(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_BACK(Var Info: pSP_iInfo);
Procedure SP_Interpret_WINDOW(Var Info: pSP_iInfo);
Procedure SP_Interpret_WINDOW_GFX(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_GRAB(Var Info: pSP_iInfo);
Procedure SP_Interpret_SCR_GRAB(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_PUT(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_PUT_EX(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_ALPHA(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_TRANS(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_DEPTH(Var Info: pSP_iInfo);
Procedure SP_Interpret_POKE(Var Info: pSP_iInfo);
Procedure SP_Interpret_DPOKE(Var Info: pSP_iInfo);
Procedure SP_Interpret_QPOKE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FPOKE(Var Info: pSP_iInfo);
Procedure SP_Interpret_POKES(Var Info: pSP_iInfo);
Procedure SP_Interpret_NEW(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENU_SHOW_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENU_HIDE_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENUITEM_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON_MENU_SHOW(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON_MENU_HIDE(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON_MENUITEM(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON_ERR(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON_COLLIDE(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON_MOUSEDOWN(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON_MOUSEMOVE(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON_MOUSEUP(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON_KEYDOWN(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON_KEYUP(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON_WHEELUP(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON_WHEELDOWN(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON_ERR_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_ON_COLLIDE_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_MOUSEDOWN_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_MOUSEMOVE_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_MOUSEUP_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_KEYDOWN_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_KEYUP_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_WHEELUP_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_WHEELDOWN_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_CLEAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_CLEAR_VAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_CLEAR_ERR(Var Info: pSP_iInfo);
Procedure SP_Interpret_UNDIM(Var Info: pSP_iInfo);
Procedure SP_Interpret_YIELD(Var Info: pSP_iInfo);
Procedure SP_Interpret_FILL(Var Info: pSP_iInfo);
Procedure SP_Interpret_FILLTEX(Var Info: pSP_iInfo);
Procedure SP_Interpret_RECTANGLE(Var Info: pSP_iInfo);
Procedure SP_Interpret_RECTFILL(Var Info: pSP_iInfo);
Procedure SP_Interpret_POLYLINE(Var Info: pSP_iInfo);
Procedure SP_Interpret_POLYFILL(Var Info: pSP_iInfo);
Procedure SP_Interpret_SCRCOPY(Var Info: pSP_iInfo);
Procedure SP_Interpret_DEGREES(Var Info: pSP_iInfo);
Procedure SP_Interpret_RADIANS(Var Info: pSP_iInfo);
Procedure SP_Interpret_TURNS(Var Info: pSP_iInfo);
Procedure SP_Interpret_GRADIANS(Var Info: pSP_iInfo);
Procedure SP_Interpret_RECOVER(Var Info: pSP_iInfo);
Procedure SP_Interpret_FONT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FONT_NEW(Var Info: pSP_iInfo);
Procedure SP_Interpret_FONT_TRANS(Var Info: pSP_iInfo);
Procedure SP_Interpret_FONT_ERASE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SAVE_BANK(Var Info: pSP_iInfo);
Procedure SP_Interpret_LOAD_BANK(Var Info: pSP_iInfo);
Procedure SP_Interpret_NEW_BANK(Var Info: pSP_iInfo);
Procedure SP_Interpret_WAIT(Var Info: pSP_iInfo);
Procedure SP_Interpret_WAIT_KEY(Var Info: pSP_iInfo);
Procedure SP_Interpret_WAIT_KEY_PRESS(Var Info: pSP_iInfo);
Procedure SP_Interpret_BANK_NEW(Var Info: pSP_iInfo);
Procedure SP_Interpret_BANK_SIZE(Var Info: pSP_iInfo);
Procedure SP_Interpret_BANK_ERASE(Var Info: pSP_iInfo);
Procedure SP_Interpret_BANK_ERASE_ALL(Var Info: pSP_iInfo);
Procedure SP_Interpret_BANK_COPY(Var Info: pSP_iInfo);
Procedure SP_Interpret_STREAM_NEW(Var Info: pSP_iInfo);
Procedure SP_Interpret_STREAM_READ(Var Info: pSP_iInfo);
Procedure SP_Interpret_STREAM_READLN(Var Info: pSP_iInfo);
Procedure SP_Interpret_STREAM_READFILE(Var Info: pSP_iInfo);
Procedure SP_Interpret_STREAM_WRITE(Var Info: pSP_iInfo);
Procedure SP_Interpret_STREAM_SEEK(Var Info: pSP_iInfo);
Procedure SP_Interpret_STREAM_CLOSE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SETDIR(Var Info: pSP_iInfo);
Procedure SP_Interpret_PAL_LOAD(Var Info: pSP_iInfo);
Procedure SP_Interpret_PAL_SAVE(Var Info: pSP_iInfo);
Procedure SP_Interpret_PAL_DEFAULT(Var Info: pSP_iInfo);
Procedure SP_Interpret_PAL_EGA(Var Info: pSP_iInfo);
Procedure SP_Interpret_PAL_CGA(Var Info: pSP_iInfo);
Procedure SP_Interpret_PAL_APPLELGR(Var Info: pSP_iInfo);
Procedure SP_Interpret_PAL_APPLEHGR(Var Info: pSP_iInfo);
Procedure SP_Interpret_PAL_CPC(Var Info: pSP_iInfo);
Procedure SP_Interpret_EXECUTE(Var Info: pSP_iInfo);
Procedure SP_Interpret_ROTATE(Var Info: pSP_iInfo);
Procedure SP_Interpret_ROTATETO(Var Info: pSP_iInfo);
Procedure SP_Interpret_FACE(Var Info: pSP_iInfo);
Procedure SP_Interpret_MOVE(Var Info: pSP_iInfo);
Procedure SP_Interpret_MOVETO(Var Info: pSP_iInfo);
Procedure SP_Interpret_MOVEXY(Var Info: pSP_iInfo);
Procedure SP_Interpret_DRAWTURTLE(Var Info: pSP_iInfo);
Procedure SP_Interpret_VOLUME(Var Info: pSP_iInfo);
Procedure SP_Interpret_SAMPLE_LOAD(Var Info: pSP_iInfo);
Procedure SP_Interpret_SAMPLE_PLAY(Var Info: pSP_iInfo);
Procedure SP_Interpret_SAMPLE_ERASE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SAMPLE_RATE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SAMPLE_DEPTH(Var Info: pSP_iInfo);
Procedure SP_Interpret_SAMPLE_STEREO(Var Info: pSP_iInfo);
Procedure SP_Interpret_SAMPLE_VOLUME(Var Info: pSP_iInfo);
Procedure SP_Interpret_SAMPLE_PAN(Var Info: pSP_iInfo);
Procedure SP_Interpret_SAMPLE_NEW(Var Info: pSP_iInfo);
Procedure SP_Interpret_CHANNEL_STOP(Var Info: pSP_iInfo);
Procedure SP_Interpret_CHANNEL_PAUSE(Var Info: pSP_iInfo);
Procedure SP_Interpret_CHANNEL_RESUME(Var Info: pSP_iInfo);
Procedure SP_Interpret_CHANNEL_SEEK(Var Info: pSP_iInfo);
Procedure SP_Interpret_CHANNEL_RATE_VAL(Var Info: pSP_iInfo);
Procedure SP_Interpret_CHANNEL_RATE_STR(Var Info: pSP_iInfo);
Procedure SP_Interpret_CHANNEL_PAN(Var Info: pSP_iInfo);
Procedure SP_Interpret_CHANNEL_VOLUME(Var Info: pSP_iInfo);
Procedure SP_Interpret_PLAY(Var Info: pSP_iInfo);
Procedure SP_Interpret_PLAY_STOP(Var Info: pSP_iInfo);
Procedure SP_Interpret_MUSIC_PLAY(Var Info: pSP_iInfo);
Procedure SP_Interpret_MUSIC_STOP(Var Info: pSP_iInfo);
Procedure SP_Interpret_MUSIC_PAUSE(Var Info: pSP_iInfo);
Procedure SP_Interpret_MUSIC_RESUME(Var Info: pSP_iInfo);
Procedure SP_Interpret_MUSIC_SEEK(Var Info: pSP_iInfo);
Procedure SP_Interpret_MUSIC_VOLUME(Var Info: pSP_iInfo);
Procedure SP_Interpret_BANK_COPY_EX(Var Info: pSP_iInfo);
Procedure SP_Interpret_ELSE(Var Info: pSP_iInfo);
Procedure SP_Interpret_DEF_PROC(Var Info: pSP_iInfo);
Procedure SP_Interpret_PROC(Var Info: pSP_iInfo);
Procedure SP_Interpret_END_PROC(Var Info: pSP_iInfo);
Procedure SP_Interpret_EXIT_PROC(Var Info: pSP_iInfo);
Procedure SP_Interpret_GLOBAL(Var Info: pSP_iInfo);
Procedure SP_Interpret_LOCAL(Var Info: pSP_iInfo);
Procedure SP_Interpret_DEF_FN(Var Info: pSP_iInfo);
Procedure SP_Interpret_FN(Var Info: pSP_iInfo);
Procedure SP_Interpret_BANK_PROTECT(Var Info: pSP_iInfo);
Procedure SP_Interpret_BANK_DEPROTECT(Var Info: pSP_iInfo);
Procedure SP_Interpret_CALL(Var Info: pSP_iInfo);
Procedure SP_Interpret_CAT(Var Info: pSP_iInfo);
Procedure SP_Interpret_ERASE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_NEW(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_ADDFRAME(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_SHOW(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_HIDE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_MOVE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_MOVED(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_MOVE_T(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_MOVED_T(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_MOVE_S(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_MOVED_S(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_MOVE_WIN(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_STOP(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_ROTATE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_ROTATE_TO(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_ROTATE_T(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_ROTATE_TO_T(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_SCALE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_SCALE_T(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_ERASE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_CLEAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_CLONE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_CLONE_MOVE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_CLONE_ERASE(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_NEW_SIZE(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_NEW_LOAD(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_NEW_GFXS(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_LOAD(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_GRAB(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_PUT(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_PUT_EX(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_ROTATE(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_SCALE(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_SCALE_TO(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_SCALE_XY(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_FLIP(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_MIRROR(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_FLIP_STR(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_MIRROR_STR(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_ERASE(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_TRANSPARENT(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_REMAP(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_PALETTE(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_PAL_DEFAULT(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_PAL_HSV(Var Info: pSP_iInfo);
Procedure SP_Interpret_PAL_COPY(Var Info: pSP_iInfo);
Procedure SP_Interpret_RENUMBER(Var Info: pSP_iInfo);
Procedure SP_Interpret_ERASE_LINES(Var Info: pSP_iInfo);
Procedure SP_Interpret_LIST(Var Info: pSP_iInfo);
Procedure SP_Interpret_LIST_LINES(Var Info: pSP_iInfo);
Procedure SP_Interpret_PACKAGE_NEW(Var Info: pSP_iInfo);
Procedure SP_Interpret_ASSIGN(Var Info: pSP_iInfo);
Procedure SP_Interpret_COPY(Var Info: pSP_iInfo);
Procedure SP_Interpret_MOVE_FILES(Var Info: pSP_iInfo);
Procedure SP_Interpret_MAKEDIR(Var Info: pSP_iInfo);
Procedure SP_Interpret_RENAME(Var Info: pSP_iInfo);
Procedure SP_Interpret_PACK_ADD(Var Info: pSP_iInfo);
Procedure SP_Interpret_PACK_CLOSE(Var Info: pSP_iInfo);
Procedure SP_Interpret_PACK_PROTECT(Var Info: pSP_iInfo);
Procedure SP_Interpret_PACK_UNPROTECT(Var Info: pSP_iInfo);
Procedure SP_Interpret_PACKAGE(Var Info: pSP_iInfo);
Procedure SP_Interpret_DATA_SAVE(Var Info: pSP_iInfo);
Procedure SP_Interpret_DATA_LOAD(Var Info: pSP_iInfo);
Procedure SP_Interpret_MERGE_LINES(Var Info: pSP_iInfo);
Procedure SP_Interpret_GRAPHIC_ROLL(Var Info: pSP_iInfo);
Procedure SP_Interpret_GRAPHIC_SCROLL(Var Info: pSP_iInfo);
Procedure SP_Interpret_TILEMAP_NEW(Var Info: pSP_iInfo);
Procedure SP_Interpret_TILEMAP_DRAW(Var Info: pSP_iInfo);
Procedure SP_Interpret_TILEMAP_SET(Var Info: pSP_iInfo);
Procedure SP_Interpret_TILEMAP_GRAPHIC(Var Info: pSP_iInfo);
Procedure SP_Interpret_TILEMAP_CLEAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SAVE_BANK_DATA(Var Info: pSP_iInfo);
Procedure SP_Interpret_LIST_BANK(Var Info: pSP_iInfo);
Procedure SP_Interpret_LIST_WINDOW(Var Info: pSP_iInfo);
Procedure SP_Interpret_LIST_VAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_LIST_ARRAY(Var Info: pSP_iInfo);
Procedure SP_Interpret_LIST_ASSIGN(Var Info: pSP_iInfo);
Procedure SP_Interpret_LIST_BANK_EX(Var Info: pSP_iInfo);
Procedure SP_Interpret_DEF_STRUCT(Var Info: pSP_iInfo);
Procedure SP_Interpret_LIST_STRUCT(Var Info: pSP_iInfo);
Procedure SP_Interpret_STRUCT_ERASE(Var Info: pSP_iInfo);
Procedure SP_Interpret_INIT_INPUT(Var Info: pSP_iInfo);
Procedure SP_Interpret_INPUT_NUM(Var Info: pSP_iInfo);
Procedure SP_Interpret_INPUT_FORMAT(Var Info: pSP_iInfo);
Procedure SP_Interpret_INPUT_FINAL(Var Info: pSP_iInfo);
Procedure SP_Interpret_INPUT_ERROR(Var Info: pSP_iInfo);
Procedure SP_Interpret_INPUT_ERR_RPT(Var Info: pSP_iInfo);
Procedure SP_Interpret_FOR_EACH(Var Info: pSP_iInfo);
Procedure SP_Interpret_MOUSE_SHOW(Var Info: pSP_iInfo);
Procedure SP_Interpret_MOUSE_HIDE(Var Info: pSP_iInfo);
Procedure SP_Interpret_MOUSE_GRAPHIC(Var Info: pSP_iInfo);
Procedure SP_Interpret_MOUSE_GFXS(Var Info: pSP_iInfo);
Procedure SP_Interpret_MOUSE_DEFAULT(Var Info: pSP_iInfo);
Procedure SP_Interpret_MOUSE_TO(Var Info: pSP_iInfo);
Procedure SP_Interpret_DEBUG(Var Info: pSP_iInfo);
Procedure SP_Interpret_FPS(Var Info: pSP_iInfo);
Procedure SP_Interpret_PUSH(Var Info: pSP_iInfo);
Procedure SP_Interpret_OPTION(Var Info: pSP_iInfo);
Procedure SP_Interpret_SETNUB(Var Info: pSP_iInfo);
Procedure SP_Interpret_SETCPU(Var Info: pSP_iInfo);
Procedure SP_Interpret_MULTIPLOT(Var Info: pSP_iInfo);
Procedure SP_Interpret_PROJECT3D(Var Info: pSP_iInfo);
Procedure SP_Interpret_RAINBOW(Var Info: pSP_iInfo);
Procedure SP_Interpret_RAINBOW_HSV(Var Info: pSP_iInfo);
Procedure SP_Interpret_KEYBOARD(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_ORG_FLIP(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_ORIGIN(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_ORIGIN(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_ORG_NO_EXT(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_ORG_NO_EXT(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_ORG_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_ORG_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_CLIP(Var Info: pSP_iInfo);
Procedure SP_Interpret_CLIP_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_ORIGIN(Var Info: pSP_iInfo);
Procedure SP_Interpret_ORIGIN_FLIP(Var Info: pSP_iInfo);
Procedure SP_Interpret_ORG_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_ORG_NO_EXT(Var Info: pSP_iInfo);
Procedure SP_Interpret_ORG_DIM(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_ORG_DIM(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_ORG_DIM(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_CLIP(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_CLIP(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_CLIP_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_WINDOW_MIRROR(Var Info: pSP_iInfo);
Procedure SP_Interpret_WINDOW_FLIP(Var Info: pSP_iInfo);
Procedure SP_Interpret_GFX_CLIP_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_BEEP(Var Info: pSP_iInfo);
Procedure SP_Interpret_OUT_VAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_OUT_SCREEN(Var Info: pSP_iInfo);
Procedure SP_Interpret_OUT_STREAM(Var Info: pSP_iInfo);
Procedure SP_Interpret_FOR_EACH_RANGE(Var Info: pSP_iInfo);
Procedure SP_Interpret_FOR_EACH_STRING(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_MERGE(Var Info: pSP_iInfo);
Procedure SP_Interpret_WIN_MERGEALL(Var Info: pSP_iInfo);
Procedure SP_Interpret_CASE(Var Info: pSP_iInfo);
Procedure SP_Interpret_WHEN(Var Info: pSP_iInfo);
Procedure SP_Interpret_OTHERWISE(Var Info: pSP_iInfo);
Procedure SP_Interpret_END_CASE(Var Info: pSP_iInfo);
Procedure SP_Interpret_INCLUDE(Var Info: pSP_iInfo);
Procedure SP_Interpret_HALT(Var Info: pSP_iInfo);
Procedure SP_Interpret_SORT(Var Info: pSP_iInfo);
Procedure SP_Interpret_KEY(Var Info: pSP_iInfo);
Procedure SP_Interpret_KEY_CLEAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_KEY_CLEAR_ALL(Var Info: pSP_iInfo);
Procedure SP_Interpret_DYNAMIC_DIM(Var Info: pSP_iInfo);
Procedure SP_Interpret_MAT(Var Info: pSP_iInfo);
Procedure SP_Interpret_MAT_ZER(Var Info: pSP_iInfo);
Procedure SP_Interpret_MAT_IDN(Var Info: pSP_iInfo);
Procedure SP_Interpret_MAT_IDN_PARAM(Var Info: pSP_iInfo);
Procedure SP_Interpret_MAT_CON(Var Info: pSP_iInfo);
Procedure SP_Interpret_MAT_CON_PARAM(Var Info: pSP_iInfo);
Procedure SP_Interpret_MAT_INV(Var Info: pSP_iInfo);
Procedure SP_Interpret_MAT_TRN(Var Info: pSP_iInfo);
Procedure SP_Interpret_MAT_ADD(Var Info: pSP_iInfo);
Procedure SP_Interpret_MAT_SUB(Var Info: pSP_iInfo);
Procedure SP_Interpret_MAT_PROD(Var Info: pSP_iInfo);
Procedure SP_Interpret_MAT_SCALE(Var Info: pSP_iInfo);
Procedure SP_Interpret_MAT_INTERP(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_POINT(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_SET_ANIM(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_ANIM_STOP(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_FRAME(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_MIRROR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_FLIP(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_PUT(Var Info: pSP_iInfo);
Procedure SP_Interpret_SPRITE_OVER(Var Info: pSP_iInfo);
Procedure SP_Interpret_ENDIF(Var Info: pSP_iInfo);
Procedure SP_Interpret_ZONE_NEW(Var Info: pSP_iInfo);
Procedure SP_Interpret_ZONE_NEW_B(Var Info: pSP_iInfo);
Procedure SP_Interpret_ZONE_MOVE(Var Info: pSP_iInfo);
Procedure SP_Interpret_ZONE_MOVETO(Var Info: pSP_iInfo);
Procedure SP_Interpret_ZONE_UPDATE(Var Info: pSP_iInfo);
Procedure SP_Interpret_ZONE_UPDATE_B(Var Info: pSP_iInfo);
Procedure SP_Interpret_ZONE_ERASE(Var Info: pSP_iInfo);
Procedure SP_Interpret_RECTANGLE2(Var Info: pSP_iInfo);
Procedure SP_Interpret_RECTFILL2(Var Info: pSP_iInfo);
Procedure SP_Interpret_PR_CENTRE_OFF(Var Info: pSP_iInfo);
Procedure SP_Interpret_FILTER_STR(Var Info: pSP_iInfo);
Procedure SP_Interpret_FILTER_NUM(Var Info: pSP_iInfo);
Procedure SP_Interpret_FILTER_NUM_R(Var Info: pSP_iInfo);
Procedure SP_Interpret_GOTOC(Var Info: pSP_iInfo);
Procedure SP_Interpret_GOSUBC(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENU_NEW(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENU_ADD_ITEM(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENU_INSITEM(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENU_DELITEM(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENU_ADDSUB(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENU_DELSUB(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENU_SHOW(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENU_HIDE(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENU_ERASE_ALL(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENU_ERASE(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENUITEM_ATTR(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENU_ATTR(Var Info: pSP_iInfo);
Procedure SP_Interpret_MENU_FONT(Var Info: pSP_iInfo);
Procedure SP_Interpret_KW_MEMWRITE(Var Info: pSP_iInfo);
Procedure SP_Interpret_KW_MEMWRITED(Var Info: pSP_iInfo);
Procedure SP_Interpret_KW_MEMWRITEQ(Var Info: pSP_iInfo);
Procedure SP_Interpret_KW_MEMWRITEF(Var Info: pSP_iInfo);
Procedure SP_Interpret_KW_MEMWRITES(Var Info: pSP_iInfo);
Procedure SP_Interpret_KW_CLS_ALPHA(Var Info: pSP_iInfo);

Function  SP_SetUpPROC(CALLType: Byte; Var CacheVal: LongWord; Var Error: TSP_ErrorCode): Integer;

Procedure SP_Interpret_SP_KEYWORD(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_STRING(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_FUNCTION_MARKER(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_JZ(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_JNZ(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_NUMVAR(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_STRVAR(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_SYMBOL(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_FUNCTION(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_NUMVAR_EVAL(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_NUMVARSQ(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_STRVAR_EVAL(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_ARRAY(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_NUM_ARRAY_PTR(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_SLICER(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_ARRAY_ASSIGN(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_SLICE_ASSIGN(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_JUMP(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_POINTER(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_SKIP_STATEMENT(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_SKIP_LINE(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_DATA_ITEM(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_LABEL(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_DISPLACEMENT(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_IJMP(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_CAUSEERROR(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_VALUE(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_NUMVAR_LET(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_STRVAR_LET(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_HYBRID_LET(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_STRUCT_MEMBER_N(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_STRUCT_MEMBER_ASS(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_STRUCT_MEMBER_S(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_STRVARPTR(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_NUMVAR_LET_VALID(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_STRVAR_LET_VALID(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_SKIP_DATA(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_RANGE_LESS(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_RANGE_GREATER(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_RANGE_ARRAYSTR(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_RANGE_ARRAYNUM(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_RANGE(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_SPECIAL_SYMBOL(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_NUMCONST(Var iInfo: pSP_iInfo);
Procedure SP_Interpret_SP_STRCONST(Var iInfo: pSP_iInfo);

Procedure SP_Interpret_SP_INCVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_DECVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_MULVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_DIVVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_POWVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_MODVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_ANDVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_XORVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_ORVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_NOTVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_SHLVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_SHRVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_INT_PLUS(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_NUM_PLUS(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_STR_PLUS(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_BITWISE_NOT(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_STRING_NOT(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_MUL(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_DIV(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_ADD(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_SUB(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_STR_MUL1(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_STR_MUL2(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_NUM_EQU(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_STR_EQU(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_NUM_LES(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_STR_LES(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_NUM_LTE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_STR_LTE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_NUM_DNE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_STR_DNE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_NUM_GTE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_STR_GTE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_NUM_GTR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_STR_GTR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_GTE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_LTE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_DNE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_NUM_AND(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_STR_AND(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_AND(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_OR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_EQV(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_IMP(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_MOD(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_FMOD(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_XOR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_SHL(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_SHR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_PLUS(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_MINUS(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_MULTIPLY(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_DIVIDE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_POWER(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_COLON(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_EQUALS(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_GREATER(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_LESS(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_BIT_OR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_BIT_AND(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_EXCLAIM(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_TILDE(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_INCVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_DECVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_MULVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_DIVVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_POWVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_MODVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_ANDVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_XORVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_ORVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_NOTVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_SHLVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_CHAR_SHRVAR(Var Info: pSP_iInfo);
Procedure SP_Interpret_SP_RESTORECOLOURS(Var Info: pSP_iInfo);

Var

  SP_CaseList: Array[0..MAXDEPTH -1] of TSP_CaseItem;
  SP_CaseListPtr: Integer;
  SP_ProcsList: Array [0..MAXDEPTH -1] of TSP_ProcItem;
  SP_ProcsListPtr: Integer;
  SP_Stack: Array [0..MAXDEPTH -1] of SP_StackItem;
  SP_StackPtr, SP_StackStart: pSP_StackItem;
  SP_EveryItems: Array of TSP_EveryItem;
  SP_EveryCount: Integer = 0;
  SP_FnList: Array of SP_Function_Record;
  SP_IncludeList: Array of SP_IncludedFile;
  SP_SourceBreakpointList,
  SP_ConditionalBreakPointList: Array of TSP_BreakpointInfo;
  SP_WatchList: Array of TSP_WatchInfo;
  IgnoreEvery: Boolean = False;
  EveryEnabled: Boolean = True;
  ReEnableEvery: Boolean = False;
  IgnoreColours: Boolean = False;
  Il, Nl: LongWord;
  gbIndices, gbKey, Indices, Str1, Str2, ValTokens: aString;
  DummyToken: TToken;

  InterpretProcs: Array[0..9999] of pSP_InterpretProc;

  ERROR_LineNum, ERROR_Statement, ERROR_St: Integer;
  COLLIDE_LineNum, COLLIDE_Statement, COLLIDE_St: Integer;
  MOUSEDOWN_LineNum, MOUSEDOWN_Statement, MOUSEDOWN_St: Integer;
  MOUSEMOVE_LineNum, MOUSEMOVE_Statement, MOUSEMOVE_St: Integer;
  MOUSEUP_LineNum, MOUSEUP_Statement, MOUSEUP_St: Integer;
  KEYDOWN_LineNum, KEYDOWN_Statement, KEYDOWN_St: Integer;
  KEYUP_LineNum, KEYUP_Statement, KEYUP_St: Integer;
  WHEELUP_LineNum, WHEELUP_Statement, WHEELUP_St: Integer;
  WHEELDOWN_LineNum, WHEELDOWN_Statement, WHEELDOWN_St: Integer;
  MENUSHOW_lineNum, MENUSHOW_Statement, MENUSHOW_St: Integer;
  MENUHIDE_lineNum, MENUHIDE_Statement, MENUHIDE_St: Integer;
  MENUITEM_lineNum, MENUITEM_Statement, MENUITEM_St: Integer;
  OnActive: Word;
  LastRand: aFloat;
  FN_Recursion_Count: LongWord;

Const

  OnError:      Word = 1;
  OnEvery:      Word = 2;
  OnMouseDown:  Word = 4;
  OnMouseUp:    Word = 8;
  OnMouseMove:  Word = 16;
  OnKeyDown:    Word = 32;
  OnKeyUp:      Word = 64;
  OnWheelUp:    Word = 128;
  OnWheelDown:  Word = 256;
  OnCollide:    Word = 512;
  OnMenuShow:   Word = 1024;
  OnMenuHide:   Word = 2048;
  OnMenuItem:   Word = 4096;

  SM_None     = 0;
  SM_NoError  = 1;
  SM_Single   = 2;
  SM_StepOver = 3;

  BP_Stop         = 1; // The program will stop if a token has this in its flags member and return to the editor paused.
  BP_IsHidden     = 2; // When stopped, if this bit is set in the flags member then it won't show up in the editor (used for single step and run-to).
  BP_Conditional  = 3; // Will trigger when condition is true.
  BP_Data         = 4; // Will trigger if the stored expression result changes.

implementation

Uses SP_Main, SP_Editor, SP_FPEditor, SP_DebugPanel, RunTimeCompiler, SP_Util2;

Procedure SP_Execute(Line: aString; InitInterpreter: Boolean; Var Error: TSP_ErrorCode);
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
  SP_PreParse(InitInterpreter, InitInterpreter, Error, Tokens^);
  PROGSTATE := SP_PR_RUN;
  SP_Interpreter(Tokens, Error.Position, Error, Error.Code);

  AUTOSAVE := aSave;

End;

Procedure SP_Interpreter(Var Tokens: paString; Var Position: Integer; Var Error: TSP_ErrorCode; PreParseErrorCode: Integer; Continue: Boolean);
Var
  CurLine, Idx, OldEC: Integer;
  HasErrors, BreakNow: Boolean;
  res: aString;
Begin

  // If there are errors in the listing, or lines that have yet to be compiled, then
  // flag them up now. Errors will not stop the _command line_ from running, but will
  // prevent entry to the program.

  HasErrors := False;

  If Not Continue Then Begin

    If PAYLOADPRESENT Then
      HasErrors := False
    Else
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
        Error.Line := NXTLINE;
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

Procedure SP_Interpret_COMPILE(Var Info: pSP_iInfo);
var
  sFilename, dFilename, Dir: String;
  payLoadData, Caption: aString;
  payLoad: TPayLoad;
  Line, NumBanks: Integer;
  Banks: Array of Integer;
  {$IFDEF DEBUG}
  //s: TFileStream;
  {$ENDIF}
Begin

  // Create an executable with the current program as a payload.

  Dir := ExtractFilePath(EXENAME);
  sFilename := EXENAME;
  dFilename := String(SP_StackPtr^.Str);
  Dec(SP_StackPtr);

  Caption := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  Line := Trunc(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  NumBanks := Trunc(SP_StackPtr^.Val);
  SetLength(Banks, NumBanks);
  Dec(SP_StackPtr);

  While NumBanks > 0 Do Begin
    Banks[NumBanks -1] := Trunc(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    Dec(NumBanks);
  End;

  If FileExists(sFilename) Then Begin
    {$IFNDEF FPC}
    If FileExists(dFilename) Then
      TFile.Delete(dFilename);
    TFile.Copy(sFilename, dFilename);
    {$ELSE}
    If FileExists(dFilename) Then
      DeleteFile(dFilename);
    CopyFile(sFilename, dFilename);
    {$ENDIF}
    payLoadData := MakeDataPayload(Line, Caption, Banks);
    payLoad := TPayLoad.Create(dFilename);
    payload.SetPayload(payLoadData[1], Length(PayLoadData));
    payLoad.Free;
    {$IFDEF DEBUG}
{    sFilename := Dir + 'payload.bin';
    if FileExists(sFilename) then
      TFile.Delete(sFilename);
    s := TFileStream.Create(sFilename, fmCreate);
    s.Write(payLoadData[1], Length(payLoadData));
    s.Free; }
    {$ENDIF}
  End;

End;

Procedure SP_AddWatch(Index: Integer; Expr: aString);
Var
  s: aString;
  l: Integer;
  Error: TSP_ErrorCode;
Begin

  // Add a new watch (if Index is -1) or replace an existing watch.

  l := Length(SP_WatchList);
  If Index = -1 Then Begin
    SetLength(SP_WatchList, l+1);
    Index := l;
  End;

  With SP_WatchList[Index] Do Begin
    Expression := Expr;
    Error.Position := 1;
    Error.Code := SP_ERR_OK;
    s := SP_TokeniseLine(Expression, True, False) + #255;
    s := SP_Convert_Expr(s, Error.Position, Error, -1) + #255;
    SP_RemoveBlocks(s);
    SP_TestConsts(s, 1, Error, False);
    SP_AddHandlers(s);
    Compiled_Expression := #$F + s;
  End;

End;

Procedure SP_DeleteWatch(Index: Integer);
Var
  i, l: Integer;
Begin

  l := Length(SP_WatchList);
  For i := Index To l -2 Do
    SP_WatchList[i] := SP_WatchList[i +1];
  SetLength(SP_WatchList, l -1);

End;

Function  SP_BreakPointExists(Line, Statement: Integer): Boolean;
Var
  l, i: Integer;
Begin
  Result := False;
  l := Length(SP_SourceBreakPointList);
  For i := 0 To l -1 Do
    If (SP_SourceBreakPointList[i].Line = Line) And (SP_SourceBreakPointList[i].Statement = Statement) Then Begin
      Result := True;
      Break;
    End;
End;

Procedure SP_AddSourceBreakPoint(Hidden: Boolean; Line, Statement, Passes: Integer; Condition: aString);
Var
  s: aString;
  i, l: Integer;
  Error: TSP_ErrorCode;
  Found, isHidden: Boolean;
Begin

  // Toggles a breakpoint in the internal list used during pre-parsing.
  // If not in the list, it's added.
  // If it's in the list and the Hidden property is different, then the hidden property is flipped.
  // Otherwise, it's removed.

  Found := False;
  l := Length(SP_SourceBreakPointList);
  For i := 0 To l -1 Do
    If (SP_SourceBreakPointList[i].Line = Line) And (SP_SourceBreakPointList[i].Statement = Statement) Then Begin
      Found := True;
      Break;
    End;

  If not Found Then Begin
    SetLength(SP_SourceBreakPointList, l +1);
    SP_SourceBreakPointList[l].bpType := Ord(Hidden) +1;
    SP_SourceBreakPointList[l].Line := Line;
    SP_SourceBreakPointList[l].Statement := Statement;
    i := l;
  End Else Begin
    If Not Hidden Then Begin
      // User breakpoint. If there's a hidden BP here, make it Shown, otherwise delete it.
      isHidden := SP_SourceBreakPointList[i].bpType = BP_IsHidden;
      If isHidden Then
        SP_SourceBreakPointList[i].bpType := BP_Stop
      Else Begin
        For i := i To l -2 Do
          SP_SourceBreakPointList[i] := SP_SourceBreakPointList[i +1];
        SetLength(SP_SourceBreakPointList, l -1);
        SP_GetDebugStatus(dbgBreakpoints);
        Exit;
      End;
    End; // A breakpoint here should remain, so do nothing.
  End;

  // If we get here, the breakpoint is active. Set up the condition evaluation.

  Error.Position := 1;
  Error.Code := SP_ERR_OK;
  s := SP_TokeniseLine(Condition, True, False) + #255;
  s := SP_Convert_Expr(s, Error.Position, Error, -1) + #255;
  SP_RemoveBlocks(s);
  SP_TestConsts(s, 1, Error, False);
  SP_AddHandlers(s);

  SP_SourceBreakPointList[i].PassNum := Passes;
  SP_SourceBreakPointList[i].Condition := Condition;
  SP_SourceBreakPointList[i].Compiled_Condition := #$F + s;

  SP_GetDebugStatus(dbgBreakpoints);

End;

Procedure SP_AddConditionalBreakpoint(BpIndex, Passes: Integer; Condition: aString; IsData: Boolean);
Var
  l: Integer;
  s: aString;
  Error: TSP_ErrorCode;
Begin

  // Adds a conditional breakpoint to the current list of breakpoints.
  // No line or statement associated with this breakpoint, it's evaluated after every
  // statement.

  // VERY SLOW, use sparingly!

  If BpIndex = -1 Then Begin
    // New breakpoint, add to the list
    l := Length(SP_ConditionalBreakpointList);
    SetLength(SP_ConditionalBreakpointList, l +1);
  End Else Begin
    // Edit an existing breakpoint
    l := BPIndex;
  End;

  Error.Position := 1;
  Error.Code := SP_ERR_OK;
  s := SP_TokeniseLine(Condition, True, False) + #255;
  s := SP_Convert_Expr(s, Error.Position, Error, -1) + #255;
  SP_RemoveBlocks(s);
  SP_TestConsts(s, 1, Error, False);
  SP_AddHandlers(s);

  If IsData Then
    SP_ConditionalBreakPointList[l].bpType := BP_Data
  Else
    SP_ConditionalBreakPointList[l].bpType := BP_Conditional;
  SP_ConditionalBreakPointList[l].Condition := Condition;
  SP_ConditionalBreakPointList[l].PassNum := Passes;
  SP_ConditionalBreakPointList[l].Compiled_Condition := #$F + s;
  SP_ConditionalBreakPointList[l].CurResult := '';
  SP_ConditionalBreakPointList[l].HasResult := False;

  SP_GetDebugStatus(dbgBreakpoints);

End;

Procedure SP_AddEvery(const Condition: aString; Every, LineNum, Statement, St: Integer; UsesError: Boolean);
Begin

  SetLength(SP_EveryItems, SP_EveryCount + 1);
  With SP_EveryItems[SP_EveryCount] Do Begin
    HasCondition := Cond <> '';
    Cond := Condition + SP_TERMINAL_CHAR;
    FrameStart := Every;
    FrameCounter := Every;
    JumpStatement := Statement;
    JumpLine := LineNum;
    JumpSt := St;
  End;
  Inc(SP_EveryCount);
  OnActive := OnActive or OnEvery;

End;

Procedure SP_CheckEvery(FrameCheck: Boolean; Position: Integer; Var Error: TSP_ErrorCode);
Var
  Idx, Ps: Integer;
  Err: TSP_ErrorCode;
  LineItem: TSP_GOSUB_Item;
  Cnd: paString;
  Sp: pSP_StackItem;
Begin

  Sp := SP_StackPtr;
  For Idx := 0 To SP_EveryCount - 1 Do Begin

    With SP_EveryItems[Idx] Do Begin

      If FrameStart <> 0 Then
        If FrameElapsed Then Begin
          Dec(FrameCounter);
          FrameElapsed := False;
        End;

      If (FrameStart = 0) or ((FrameStart <> 0) And (FrameCounter = 0)) Then Begin
        FrameCounter := FrameStart;
        Ps := 1;
        Err.Code := SP_ERR_OK;
        If HasCondition Then Begin
          Cnd := @Cond;
          SP_InterpretCONTSafe(Cnd, Ps, Err);
          If Err.Code = SP_ERR_OK Then Begin
            If SP_StackPtr^.Val >= 1 Then Begin
              If Error.ReturnType >= SP_JUMP Then Begin
                SP_StackLine(NXTLINE, NXTSTATEMENT, Error.Statement, SP_KW_EVERY, Error);
              End Else Begin
                LineItem := SP_ConvertLineStatement(Error.Line, Error.Statement);
                SP_StackLine(LineItem.Line, Error.Position, LineItem.St, SP_KW_EVERY, Error);
              End;
              NXTLINE := JumpLine;
              NXTSTATEMENT := JumpStatement;
              Error.Statement := JumpSt;
              EveryEnabled := False;
              Error.ReturnType := SP_JUMP;
              Dec(SP_StackPtr);
            End;
          End Else Begin
            Error.Code := Err.Code;
            Error.Position := Ps;
          End;
        End Else Begin
          If Error.ReturnType >= SP_JUMP Then Begin
            SP_StackLine(NXTLINE, NXTSTATEMENT, Error.Statement, SP_KW_EVERY, Error);
          End Else Begin
            LineItem := SP_ConvertLineStatement(Error.Line, Error.Statement);
            SP_StackLine(LineItem.Line, Error.Position, LineItem.St, SP_KW_EVERY, Error);
          End;
          NXTLINE := JumpLine;
          NXTSTATEMENT := JumpStatement;
          Error.Statement := JumpSt;
          EveryEnabled := False;
          Error.ReturnType := SP_JUMP;
        End;
      End;
    End;
  End;

  SP_StackPtr := Sp;

End;

Procedure SP_ClearEvery;
Begin

  SetLength(SP_EveryItems, 0);
  SP_EveryCount := 0;
  OnActive := OnActive And (255 - OnEvery);

End;

Procedure SP_Interpret_UNHANDLED(Var Info: pSP_iInfo);
Begin

  Info^.Error^.Code := SP_ERR_UNHANDLED;

End;

Procedure SP_Interpret_SP_RESTORECOLOURS(Var Info: pSP_iInfo);
Begin

  SP_Reset_Temp_Colours;

End;

// These procedures "shortcut" common maths expressions - vars and values with an operator, such as 'F+1' or 'A$="H"'.
// StrPtr points directly to the next token, and we know exactly what types are coming.

Procedure SP_Interpret_NN_Symbol(Symbol: Byte; Var Val1, Val2: aFloat; Var Error: TSP_ErrorCode);
Begin

  SP_StackPtr^.OpType := SP_VALUE;

  Case aChar(Symbol) of
    SP_CHAR_NUM_PLUS, '+':
      SP_StackPtr^.Val := Val1 + Val2;
    SP_CHAR_INT_PLUS, SP_CHAR_ADD:
      SP_StackPtr^.Val := Round(Val1) + Round(Val2);
    SP_CHAR_MUL:
      SP_StackPtr^.Val := Round(Val1) * Round(Val2);
    SP_CHAR_DIV:
      If Round(Val2) <> 0 Then
        SP_StackPtr^.Val := Round(Val1) Div Round(Val2)
      Else
        if ErrorEnabled[SP_ERR_DIV_BY_ZERO] Then
          Error.Code := SP_ERR_DIV_BY_ZERO
        Else
          SP_StackPtr^.Val := 0;
    SP_CHAR_SUB:
      SP_StackPtr^.Val := Round(Val1) - Round(Val2);
    '-':
      SP_StackPtr^.Val := Val1 - Val2;
    '*':
      SP_StackPtr^.Val := Val1 * Val2;
    '/':
      If Val2 <> 0 Then
        SP_StackPtr^.Val := Val1 / Val2
      Else
        if ErrorEnabled[SP_ERR_DIV_BY_ZERO] Then
          Error.Code := SP_ERR_DIV_BY_ZERO
        Else
          SP_StackPtr^.Val := 0;
    '^':
      SP_StackPtr^.Val := SP_Power(Val1, Val2);
    SP_CHAR_NUM_EQU, '=':
      SP_StackPtr^.Val := Byte(Val1 = Val2);
    SP_CHAR_NUM_LES, '<':
      SP_StackPtr^.Val := Byte(Val1 < Val2);
    SP_CHAR_NUM_LTE, SP_CHAR_LTE:
      SP_StackPtr^.Val := Byte(Val1 <= Val2);
    SP_CHAR_NUM_DNE, SP_CHAR_DNE:
      SP_StackPtr^.Val := Byte(Val1 <> Val2);
    SP_CHAR_NUM_GTE, SP_CHAR_GTE:
      SP_StackPtr^.Val := Byte(Val1 >= Val2);
    SP_CHAR_NUM_GTR, '>':
      SP_StackPtr^.Val := Byte(Val1 > Val2);
    SP_CHAR_NUM_AND, SP_CHAR_AND:
      If Val2 = 0 Then SP_StackPtr^.Val := 0 Else SP_StackPtr^.Val := Val1;
    SP_CHAR_OR:
      If Val2 <> 0 Then SP_StackPtr^.Val := 1 Else SP_StackPtr^.Val := Val1;
    SP_CHAR_EQV:
      SP_StackPtr^.Val := 1-(Ord(Val1 <> 0) Xor Ord(Val2 <> 0));
    SP_CHAR_IMP:
      If Val1 <> 0 Then
        SP_StackPtr^.Val := Ord(Val2 <> 0)
      Else
        SP_StackPtr^.Val := 1;
    SP_CHAR_MOD:
      If Round(Val2) <> 0 Then
        SP_StackPtr^.Val := SP_ModCalc(Val1, Val2)
      Else
        if ErrorEnabled[SP_ERR_DIV_BY_ZERO] Then
          Error.Code := SP_ERR_DIV_BY_ZERO
        Else
          SP_StackPtr^.Val := 0;
    SP_CHAR_FMOD:
      If Val2 <> 0 Then
        SP_StackPtr^.Val := SP_FModCalc(Val1, Val2)
      Else
        if ErrorEnabled[SP_ERR_DIV_BY_ZERO] Then
          Error.Code := SP_ERR_DIV_BY_ZERO
        Else
          SP_StackPtr^.Val := 0;
    SP_CHAR_XOR:
      SP_StackPtr^.Val := Round(Val1) Xor Round(Val2);
    SP_CHAR_SHL:
      SP_StackPtr^.Val := Round(Val1) Shl Round(Val2);
    SP_CHAR_SHR:
      SP_StackPtr^.Val := Round(Val1) Shr Round(Val2);
    '|':
      SP_StackPtr^.Val := Round(Val1) Or Round(Val2);
    '&':
      SP_StackPtr^.Val := Round(Val1) And Round(Val2);
  Else
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_VALUE;
      Val := Val1;
    End;
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_VALUE;
      Val := Val2;
    End;
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_SYMBOL;
      Str := aChar(Symbol);
    End;
  End;

End;

Procedure SP_Interpret_NNO(Var iInfo: pSP_iInfo);
Var
  Idx, NameLen: Integer;
  Val1, Val2: aFloat;
  iPtr: pInteger;
Begin

  // Numvar eval, numvar eval, operator.
  // Extract the values of two numvars, then run the operator.

  // First Variable

  With iInfo^ Do Begin

    If pToken(StrPtr)^.Token <> SP_NUMCONST Then Begin

      NameLen := pToken(StrPtr)^.TokenLen - (SizeOf(LongWord) *2);
      Inc(StrPtr, SizeOf(TToken));
      iPtr := pInteger(StrPtr);
      Inc(StrPtr, SizeOf(LongWord) * 2);
      Idx := iPtr^;

      If Idx <> 0 Then Begin
        Dec(Idx);
        Inc(StrPtr, NameLen);
      End Else Begin
        Idx := SP_FindNumVar(StringFromPtr(StrPtr, NameLen));
        Inc(StrPtr, NameLen);
        If Idx <> -1 Then Begin
          If Not NumVars[Idx]^.ProcVar Then
            iPtr^ := Idx + 1;
        End Else Begin
          Error.Code := SP_ERR_MISSING_VAR;
          Exit;
        End;
      End;

      Val1 := NumVars[Idx]^.ContentPtr^.Value;

    End Else Begin

      Inc(StrPtr, SizeOf(TToken));
      Val1 := gaFloat(StrPtr);
      Inc(StrPtr, pToken(StrPtr - SizeOf(TToken))^.TokenLen);

    End;

    // Second Variable

    If pByte(StrPtr)^ <> SP_NUMCONST Then Begin

      NameLen := pToken(StrPtr)^.TokenLen - (SizeOf(LongWord) *2);
      Inc(StrPtr, SizeOf(TToken));
      iPtr := pInteger(StrPtr);
      Inc(StrPtr, SizeOf(LongWord) * 2);
      Idx := iPtr^;

      If Idx = 0 Then Begin
        Idx := SP_FindNumVar(StringFromPtr(StrPtr, NameLen));
        Inc(StrPtr, NameLen);
        If Idx <> -1 Then Begin
          If Not NumVars[Idx]^.ProcVar Then
            iPtr^ := Idx + 1;
        End Else Begin
          Error.Code := SP_ERR_MISSING_VAR;
          Exit;
        End;
      End Else Begin
        Dec(Idx);
        Inc(StrPtr, NameLen);
      End;

      Val2 := NumVars[Idx]^.ContentPtr^.Value;

    End Else Begin

      Inc(StrPtr, SizeOf(TToken));
      Val2 := gaFloat(StrPtr);
      Inc(StrPtr, pToken(StrPtr - SizeOf(TToken))^.TokenLen);

    End;

    // Now do the operator

    Token := pToken(StrPtr);
    Inc(SP_StackPtr);
    Inc(StrPtr, SizeOf(TToken));
    SP_Interpret_NN_Symbol(pByte(StrPtr)^, Val1, Val2, Error^);

    // Now pointing at the next "opcode" and ready to go!

  End;

End;

Procedure SP_Interpret_NVO(Var iInfo: pSP_iInfo);
Var
  Idx, NameLen: Integer;
  Val1, Val2: aFloat;
  iPtr: pInteger;
Begin

  // Numvar eval, value, operator.
  // Extract the values of one numvar, a value, and then run the operator.

  // First Variable

  With iInfo^ Do Begin

    If pByte(StrPtr)^ <> SP_NUMCONST Then Begin

      NameLen := pToken(StrPtr)^.TokenLen - (SizeOf(LongWord) *2);
      Inc(StrPtr, SizeOf(TToken));
      iPtr := pInteger(StrPtr);
      Inc(StrPtr, SizeOf(LongWord) * 2);
      Idx := iPtr^;

      If Idx <> 0 Then Begin
        Dec(Idx);
        Inc(StrPtr, NameLen);
      End Else Begin
        Idx := SP_FindNumVar(StringFromPtr(StrPtr, NameLen));
        Inc(StrPtr, NameLen);
        If Idx <> -1 Then Begin
          If Not NumVars[Idx]^.ProcVar Then
            iPtr^ := Idx + 1;
        End Else Begin
          Error.Code := SP_ERR_MISSING_VAR;
          Exit;
        End;
      End;

      Val1 := NumVars[Idx]^.ContentPtr^.Value;

    End Else Begin

      Inc(StrPtr, SizeOf(TToken));
      Val1 := gaFloat(StrPtr);
      Inc(StrPtr, pToken(StrPtr - SizeOf(TToken))^.TokenLen);

    End;

    // Second Number

    Inc(StrPtr, SizeOf(TToken));
    Val2 := paFloat(StrPtr)^;
    Inc(StrPtr, SizeOf(aFloat));

    // Now do the operator

    Inc(SP_StackPtr);
    Token := pToken(StrPtr);
    Inc(StrPtr, SizeOf(TToken));
    SP_Interpret_NN_Symbol(pByte(StrPtr)^, Val1, Val2, Error^);

    // Now pointing at the next "opcode" and ready to go!

  End;

End;

Procedure SP_Interpret_VNO(Var iInfo: pSP_iInfo);
Var
  Idx, NameLen: Integer;
  Val1, Val2: aFloat;
  iPtr: pInteger;
Begin

  // Numvar eval, value, operator.
  // Extract the values of one numvar, a value, and then run the operator.

  // First Number

  With iInfo^ Do Begin

    Inc(StrPtr, SizeOf(TToken));
    Val1 := paFloat(StrPtr)^;
    Inc(StrPtr, SizeOf(aFloat));

    // Second Variable

    If pByte(StrPtr)^ <> SP_NUMCONST Then Begin

      NameLen := pToken(StrPtr)^.TokenLen - (SizeOf(LongWord) *2);
      Inc(StrPtr, SizeOf(TToken));
      iPtr := pInteger(StrPtr);
      Inc(StrPtr, SizeOf(LongWord) * 2);
      Idx := iPtr^;

      If Idx <> 0 Then Begin
        Dec(Idx);
        Inc(StrPtr, NameLen);
      End Else Begin
        Idx := SP_FindNumVar(StringFromPtr(StrPtr, NameLen));
        Inc(StrPtr, NameLen);
        If Idx <> -1 Then Begin
          If Not NumVars[Idx]^.ProcVar Then
            iPtr^ := Idx + 1;
        End Else Begin
          Error.Code := SP_ERR_MISSING_VAR;
          Exit;
        End;
      End;

      Val2 := NumVars[Idx]^.ContentPtr^.Value;

    End Else Begin

      Inc(StrPtr, SizeOf(TToken));
      Val2 := gaFloat(StrPtr);
      Inc(StrPtr, pToken(StrPtr - SizeOf(TToken))^.TokenLen);

    End;

    // Now do the operator

    Inc(SP_StackPtr);
    Token := pToken(StrPtr);
    Inc(StrPtr, SizeOf(TToken));
    SP_Interpret_NN_Symbol(pByte(StrPtr)^, Val1, Val2, Error^);

    // Now pointing at the next "opcode" and ready to go!

  End;

End;

Procedure SP_Interpret_SP_TERMINAL(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(Error.Position, NativeUInt(StrPtr) - SavePos);
    Error^.Code := SP_EXIT;
  End;

End;

Procedure SP_Interpret_SP_KEYWORD(Var iInfo: pSP_iInfo);
Var
  iProc: pSP_InterpretProc;
  Begin

  With iInfo^ Do Begin
    Error.Position := Token^.TokenLen + 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart));
    Error.Statement := Token^.TokenPos;
    iProc := InterpretProcs[pLongWord(StrPtr)^];
    If iProc <> nil Then
      TSP_InterpretProc(iProc)(iInfo);
  End;

End;

Procedure SP_Interpret_SP_STRING(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_STRING;
      ERRStr := '!string expression';
      Str := StringFromPtr(StrPtr, Token^.TokenLen);
    End;
  End;

End;

Procedure SP_Interpret_SP_NUMVAR(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_NUMVAR;
      Ptr := @Token^.Cache;
      Val := Ptr^;
      Str := StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord));
    End;
  End;

End;

Procedure SP_Interpret_SP_STRVAR(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_STRVAR;
      Ptr := @Token^.Cache;
      Val := Ptr^;
      Str := StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord));
      tPos := Token^.TokenPos;
    End;
  End;

End;

Procedure SP_Interpret_SP_SYMBOL(Var iInfo: pSP_iInfo);
Begin
  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_SYMBOL;
      Str := aChar(StrPtr^);
    End;
  End;
End;

Procedure SP_Interpret_SP_FUNCTION(Var iInfo: pSP_iInfo);
Var
  iProc: pSP_InterpretProc;
Begin

  With iInfo^ Do Begin

    iProc := InterpretProcs[pLongWord(StrPtr)^];
    If iProc <> nil Then TSP_InterpretProc(iProc)(iInfo);

  End;

End;

Procedure SP_Interpret_SP_NUMVAR_EVAL(Var iInfo: pSP_iInfo);
Var
  Idx: Integer;
Begin

  With iInfo^ Do Begin
    Idx := pLongWord(StrPtr)^;
    If Idx <> 0 Then Begin
      Dec(Idx);
    End Else Begin
      Idx := SP_FindNumVar(StringFromPtrB(pByte(NativeUInt(StrPtr) + (SizeOf(LongWord) * 2)), pLongWord(StrPtr + SizeOf(LongWord))^));
      If Idx <> -1 Then Begin
        If Not NumVars[Idx]^.ProcVar Then
          pLongWord(StrPtr)^ := Idx + 1;
      End Else Begin
        Error.Code := SP_ERR_MISSING_VAR;
        Error.Position := Token^.TokenPos;
        Exit;
      End;
    End;
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_VALUE;
      Val := NumVars[Idx]^.ContentPtr^.Value;
    End;
  End;

End;

Procedure SP_Interpret_SP_NUMVARSQ(Var iInfo: pSP_iInfo);
Var
  Idx: Integer;
Begin

  With iInfo^ Do Begin
    Idx := pLongWord(StrPtr)^;
    If Idx <> 0 Then Begin
      Dec(Idx);
    End Else Begin
      Idx := SP_FindNumVar(StringFromPtrB(pByte(NativeUInt(StrPtr) + (SizeOf(LongWord) * 2)), pLongWord(StrPtr + SizeOf(LongWord))^));
      If Idx <> -1 Then Begin
        If Not NumVars[Idx]^.ProcVar Then
          pLongWord(StrPtr)^ := Idx + 1;
      End Else Begin
        Error.Code := SP_ERR_MISSING_VAR;
        Error.Position := Token^.TokenPos;
        Exit;
      End;
    End;
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_VALUE;
      Val := NumVars[Idx]^.ContentPtr^.Value;
      Val := Val * Val;
    End;
  End;

End;

Procedure SP_Interpret_SP_STRVAR_EVAL(Var iInfo: pSP_iInfo);
Var
  Idx: Integer;
Begin

  With iInfo^ Do Begin
    Idx := pLongWord(StrPtr)^;
    If Idx <> 0 Then Begin
      Dec(Idx);
    End Else Begin
      Idx := SP_FindStrVar(StringFromPtrB(StrPtr + (SizeOf(LongWord) * 2), pLongWord(StrPtr + SizeOf(LongWord))^));
      If Idx <> -1 Then Begin
        If Not StrVars[Idx]^.ProcVar Then
          pLongWord(StrPtr)^ := Idx + 1;
      End Else Begin
        Error.Code := SP_ERR_MISSING_VAR;
        Error.Position := Token^.TokenPos;
        Exit;
      End;
    End;
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_STRING;
      Str := StrVars[Idx].ContentPtr^.Value;
    End;
  End;

End;

Procedure SP_Interpret_SP_NUM_ARRAY_PTR(Var iInfo: pSP_iInfo);
Var
  NumIndices: LongWord;
  Idx: Integer;
Begin
  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    NumIndices := pLongWord(StrPtr)^;
    SP_StackToString(NumIndices);
    Idx := Round(SP_StackPtr^.Val);
    If Idx = 0 Then Begin
      Idx := SP_FindNumArray(StringFromPtrB(@SP_StackPtr^.Str[SizeOf(LongWord) + 1], pLongWord(@SP_StackPtr^.Str[1])^));
      If Idx <> -1 Then Begin
        Inc(Idx);
        SP_StackPtr^.Ptr^ := Idx;
      End Else Begin
        Error.Code := SP_ERR_ARRAY_NOT_FOUND;
        Error.Position := Token^.TokenPos;
        Exit;
      End;
    End;
    With SP_StackPtr^ Do Begin
      OpType := SP_NUM_ARRAY_PTR;
      Val := NativeUInt(SP_GetNumArrayPtr(Idx, '', gbIndices, gbKey, Error^));
    End;
  End;
End;

Procedure SP_Interpret_SP_ARRAY(Var iInfo: pSP_iInfo);
Var
  NumIndices: LongWord;
  Idx: Integer;
Begin

  // Evaluates an array element fetch.

  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    NumIndices := pLongWord(StrPtr)^;
    SP_StackToString(NumIndices);
    If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
      Idx := Round(SP_StackPtr^.Val);
      If Idx = 0 Then Begin
        Idx := SP_FindNumArray(StringFromPtrB(@SP_StackPtr^.Str[SizeOf(LongWord) + 1], pLongWord(@SP_StackPtr^.Str[1])^));
        If Idx <> -1 Then Begin
          SP_StackPtr^.Ptr^ := Idx + 1;
        End Else Begin
          Error.Code := SP_ERR_ARRAY_NOT_FOUND;
          Error.Position := Token^.TokenPos;
          Exit;
        End;
      End Else
        Dec(Idx);
      With SP_StackPtr^ Do Begin
        OpType := SP_VALUE;
        Val := SP_QueryNumArray(Idx, gbIndices, gbKey, Error^);
        ERRStr := NumArrays[Idx].Name;
        If Error.Code <> SP_ERR_OK Then Exit;
      End;
    End Else Begin
      // Could either be a string (or string array evaluation) or a stringvar/array with attached struct member, which will be along next.
      // If it's a structure with a member, then place the stringvarptr result on the stack ready for the member. If not, place the string
      // value.

      If (SP_StackPtr^.OpType <> SP_STRING) And (Round(SP_StackPtr^.Val) = 0) Then Begin
        // A Slicer attached to an array assign will have no name length, so test for that now
        If (Length(SP_StackPtr^.Str) - SizeOf(LongWord)) <> pInteger(@SP_StackPtr^.Str[1])^ Then
          Idx := SP_FindStrArray(SP_StackPtr^.Str)
        Else
          Idx := SP_FindStrArray(StringFromPtrB(@SP_StackPtr^.Str[SizeOf(LongWord) + 1], pLongWord(@SP_StackPtr^.Str[1])^));
        If Idx <> -1 Then Begin
          SP_StackPtr^.Ptr^ := Idx + 1;
          If pByte(StrPtr+Token^.TokenLen)^ in [SP_STRUCT_MEMBER_N, SP_STRUCT_MEMBER_S] Then Begin
            With SP_StackPtr^ Do Begin
              OpType := SP_STRVARPTR;
              Ptr := pLongWord(SP_GetStrArrayPtr(Idx +1, '', gbIndices, gbKey, Error^));
              If Error.Code <> SP_ERR_OK Then Exit;
            End;
          End Else
            With SP_StackPtr^ Do Begin
              OpType := SP_STRING;
              ERRStr := StrArrays[Idx].Name;
              Str := SP_QueryStrArray(Idx, gbIndices, gbKey, Error^);
            End;
        End Else Begin
          // could be a string var if numindices = 1. Cannot have a structure evaluation at this point.
          Idx := Integer(SP_StackPtr^.tPos);
          If (Idx <> -1) And (NUMCONSTS > 0) Then Begin
            If (NumIndices > 1) or (NumIndices = 0) Or (pLongWord(@gbIndices[1])^ > LongWord(Length(Constants[Idx].Str))) Then Begin
              Error.Code := SP_ERR_SUBSCRIPT_WRONG;
              Error.Position := Token^.TokenPos;
              Exit;
            End Else Begin
              With SP_StackPtr^ Do Begin
                OpType := SP_STRING;
                Str := Constants[Idx].Str[pLongWord(@gbIndices[1])^];
              End;
            End;
          End Else Begin
            Idx := SP_FindStrVar(StringFromPtrB(@SP_StackPtr^.Str[SizeOf(LongWord) + 1], pLongWord(@SP_StackPtr^.Str[1])^));
            If Idx > -1 Then Begin
              If (NumIndices > 1) or (NumIndices = 0) Or (pLongWord(@gbIndices[1])^ = 0) Or (pLongWord(@gbIndices[1])^ > LongWord(Length(StrVars[Idx]^.ContentPtr^.Value))) Then Begin
                Error.Code := SP_ERR_SUBSCRIPT_WRONG;
                Error.Position := Token^.TokenPos;
                Exit;
              End Else Begin
                With SP_StackPtr^ Do Begin
                  OpType := SP_STRING;
                  Str := StrVars[Idx]^.ContentPtr^.Value[pLongWord(@gbIndices[1])^];
                End;
              End;
            End Else Begin
              Error.Code := SP_ERR_MISSING_VAR;
              Error.Position := Token^.TokenPos;
              Exit;
            End;
          End;
        End;
      End Else Begin
        If SP_StackPtr^.OpType = SP_STRING Then Begin
          If (NumIndices > 1) or (NumIndices = 0) or (pLongWord(@gbIndices[1])^ > LongWord(Length(SP_StackPtr^.Str))) Then Begin
            Error.Code := SP_ERR_SUBSCRIPT_WRONG;
            Error.Position := Token^.TokenPos;
            Exit;
          End Else Begin
            With SP_StackPtr^ Do Begin
              OpType := SP_STRING;
              Idx := pLongWord(@gbIndices[1])^;
              if Idx > 0 then
                Str := SP_StackPtr^.Str[Idx]
              else
                Str := '';
            End;
          End;
        End Else Begin
          Idx := Round(SP_StackPtr^.Val);
          If pByte(StrPtr+Token^.TokenLen)^ in [SP_STRUCT_MEMBER_N, SP_STRUCT_MEMBER_S] Then Begin
            With SP_StackPtr^ Do Begin
              OpType := SP_STRVARPTR;
              Ptr := pLongWord(SP_GetStrArrayPtr(Idx, '', gbIndices, gbKey, Error^));
              If Error.Code <> SP_ERR_OK Then Exit;
            End;
          End Else Begin
            If Idx = 0 Then Begin
              Idx := SP_FindStrArray(StringFromPtrB(@SP_StackPtr^.Str[SizeOf(LongWord) + 1], pLongWord(@SP_StackPtr^.Str[1])^));
              If Idx <> -1 Then Begin
                SP_StackPtr^.Ptr^ := Idx + 1;
              End Else Begin
                Error.Code := SP_ERR_ARRAY_NOT_FOUND;
                Error.Position := Token^.TokenPos;
                Exit;
              End;
            End Else
              Dec(Idx);
            With SP_StackPtr^ Do Begin
              OpType := SP_STRING;
              Str := SP_QueryStrArray(Idx, gbIndices, gbKey, Error^);
            End;
          End;
        End;
      End;
    End;
  End;

End;

Procedure SP_Interpret_SP_SLICER(Var iInfo: pSP_iInfo);
Var
  SliceFlags: Byte;
  SliceFrom, SliceTo: Integer;
Begin

  With iInfo^ Do Begin
    SliceFlags := StrPtr^;
    If SliceFlags And 1 = 1 Then Begin
      SliceTo := Round(SP_StackPtr^.Val);
      Dec(SP_StackPtr);
    End Else
      SliceTo := -1;
    If SliceFlags And 2 = 2 Then Begin
      SliceFrom := Round(SP_StackPtr^.Val);
      Dec(SP_StackPtr);
    End Else
      SliceFrom := -1;
    SP_StackPtr^.Str := SP_SliceString(SP_StackPtr^.Str, SliceFrom, SliceTo);
  End;

End;

Procedure SP_Interpret_SP_ARRAY_ASSIGN(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_ARRAY_ASSIGN;
      Val := dLongWord(StrPtr + 1);
    End;
  End;

End;

Procedure SP_Interpret_SP_SLICE_ASSIGN(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_SLICE_ASSIGN;
      Str := aChar(StrPtr^);
      Val := dLongWord(StrPtr + 1);
    End;
  End;

End;

Procedure SP_Interpret_SP_JUMP(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(StrPtr, pInteger(StrPtr)^);
  End;

End;

Procedure SP_Interpret_SP_POINTER(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_POINTER;
      Ptr := pLongWord(StrPtr);
      tPos := Token^.TokenPos;
    End;
  End;

End;

Procedure SP_Interpret_SP_SKIP_STATEMENT(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    While True Do Begin
      Inc(StrPtr, pLongWord(StrPtr)^ + Token^.TokenLen);
      Token := pToken(StrPtr);
      Inc(StrPtr, SizeOf(TToken));
      If Token^.Token = SP_TERMINAL Then Begin
        Error.Code := SP_EXIT;
        Exit;
      End;
      If Token^.Token = SP_SKIP_LINE Then Begin
        Error.ReturnType := SP_JUMP;
        Exit;
      End;
      If (Token^.Token = SP_SYMBOL) And (aChar(StrPtr^) = ':') Then Begin
        Break;
      End;
    End;
  End;

End;

Procedure SP_Interpret_SP_SKIP_LINE(Var iInfo: pSP_iInfo);
Begin

  iInfo^.Error.ReturnType := SP_JUMP;

End;

Procedure SP_Interpret_FUNCTION_MARKER(Var iInfo: pSP_iInfo);
Begin

  // Do Nothing. NOTHING!

End;

Procedure SP_Interpret_SP_DATA_ITEM(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(StrPtr, Token^.TokenLen);
    Position := (NativeUInt(StrPtr) - NativeUInt(StrStart)) + 1;
    Error.Code := SP_EXIT;
  End;

End;

Procedure SP_Interpret_SP_LABEL(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_LABEL;
      Str := StringFromPtrB(StrPtr, Token^.TokenLen);
    End;
  End;

End;

Procedure SP_Interpret_SP_CAUSEERROR(Var iInfo: pSP_iInfo);
Begin
  ERRStr := '';
  With iInfo^ Do
    Error^.Code := pLongWord(StrPtr)^;
End;

Procedure SP_Interpret_SP_DISPLACEMENT(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := Token^.Token;
      tPos := Token^.TokenPos;
    End;
  End;

End;

Procedure SP_Interpret_SP_IJMP(Var iInfo: pSP_iInfo);
Var
  c, n: Integer;
  es: LongWord;
Begin
  With iInfo^ Do Begin
    // Read count
    c := pLongWord(StrPtr)^;
    Inc(StrPtr, SizeOf(LongWord));
    // Read the ELSE jump size
    es := pLongWord(StrPtr)^;
    n := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    If (n < 1) or (n > c) Then Begin
      If es > 0 Then
        Inc(StrPtr, es)
      Else
        Exit;
    End Else Begin
      Inc(StrPtr, n * SizeOf(LongWord));
      Inc(StrPtr, pLongWord(StrPtr)^);
    End;
    Token := @DummyToken;
  End;
End;

Procedure SP_Interpret_SP_JZ(Var iInfo: pSP_iInfo);
Begin
  // If current stack item is zero then jump, otherwise remove it.
  If SP_StackPtr^.Val = 0 Then Begin
    With iInfo^ Do
      If pLongWord(StrPtr)^ <> 0 Then // Zero here means that runtime pre-parsing hasn't happened yet.
        Inc(StrPtr, pLongWord(StrPtr)^ - Token.TokenLen);
  End Else
    If pLongWord(iInfo^.StrPtr)^ <> 0 Then
      Dec(SP_StackPtr);
End;

Procedure SP_Interpret_SP_JNZ(Var iInfo: pSP_iInfo);
Begin
  // If current stack item is non-zero then set it to 1 and jump.
  If SP_StackPtr^.Val <> 0 Then Begin
    With iInfo^ Do Begin
      SP_StackPtr^.Val := 1;
      If pLongWord(StrPtr)^ <> 0 Then // See SP_JZ
        Inc(StrPtr, pLongWord(StrPtr)^ - Token^.TokenLen);
    End;
  End Else
    If pLongWord(iInfo^.StrPtr)^ <> 0 Then
      Dec(SP_StackPtr);
End;

Procedure SP_Interpret_SP_VALUE(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_VALUE;
      Val := paFloat(StrPtr)^;
    End;
  End;

End;

Procedure SP_Interpret_SP_NUMVAR_LET(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    If pLongWord(StrPtr)^ <> 0 Then
      SP_UpdateNumVarIndex(pLongWord(StrPtr)^, SP_StackPtr^.Val)
    Else
      SP_UpdateNumVar(pLongWord(StrPtr)^,
                      StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                      SP_StackPtr^.Val, Error^, pLongWord(StrPtr));
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_INCVAR(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    If pLongWord(StrPtr)^ <> 0 Then
      SP_IncNumVarIndex(pLongWord(StrPtr)^, SP_StackPtr^.Val)
    Else
      SP_IncNumVar(pLongWord(StrPtr)^,
                   StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                   SP_StackPtr^.Val, Error^, pLongWord(StrPtr));
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_DECVAR(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    If pLongWord(StrPtr)^ <> 0 Then
      SP_DecNumVarIndex(pLongWord(StrPtr)^, SP_StackPtr^.Val)
    Else
      SP_DecNumVar(pLongWord(StrPtr)^,
                   StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                   SP_StackPtr^.Val, Error^, pLongWord(StrPtr));
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_MULVAR(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    If pLongWord(StrPtr)^ <> 0 Then
      SP_MulNumVarIndex(pLongWord(StrPtr)^, SP_StackPtr^.Val)
    Else
      SP_MulNumVar(pLongWord(StrPtr)^,
                   StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                   SP_StackPtr^.Val, Error^, pLongWord(StrPtr));
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_DIVVAR(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    If pLongWord(StrPtr)^ <> 0 Then
      SP_DivNumVarIndex(pLongWord(StrPtr)^, SP_StackPtr^.Val, Error^)
    Else
      SP_DivNumVar(pLongWord(StrPtr)^,
                   StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                   SP_StackPtr^.Val, Error^, pLongWord(StrPtr));
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_POWVAR(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    If pLongWord(StrPtr)^ <> 0 Then
      SP_PowNumVarIndex(pLongWord(StrPtr)^, SP_StackPtr^.Val)
    Else
      SP_PowNumVar(pLongWord(StrPtr)^,
                   StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                   SP_StackPtr^.Val, Error^, pLongWord(StrPtr));
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_MODVAR(Var Info: pSP_iInfo);
Var
  n: NativeUInt;
Begin

  With Info^ Do Begin
    n := Round(SP_StackPtr^.Val);
    If pLongWord(StrPtr)^ <> 0 Then
      SP_ModNumVarIndex(pLongWord(StrPtr)^, n, Error^)
    Else
      SP_ModNumVar(pLongWord(StrPtr)^,
                   StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                   n, Error^, pLongWord(StrPtr));
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_ANDVAR(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    If pLongWord(StrPtr)^ <> 0 Then
      SP_AndNumVarIndex(pLongWord(StrPtr)^, SP_StackPtr^.Val)
    Else
      SP_AndNumVar(pLongWord(StrPtr)^,
                   StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                   SP_StackPtr^.Val, Error^, pLongWord(StrPtr));
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_ORVAR(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    If pLongWord(StrPtr)^ <> 0 Then
      SP_OrNumVarIndex(pLongWord(StrPtr)^, SP_StackPtr^.Val)
    Else
      SP_OrNumVar(pLongWord(StrPtr)^,
                   StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                   SP_StackPtr^.Val, Error^, pLongWord(StrPtr));
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_NOTVAR(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    If pLongWord(StrPtr)^ <> 0 Then
      SP_NotNumVarIndex(pLongWord(StrPtr)^, SP_StackPtr^.Val)
    Else
      SP_NotNumVar(pLongWord(StrPtr)^,
                   StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                   SP_StackPtr^.Val, Error^, pLongWord(StrPtr));
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_XORVAR(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    If pLongWord(StrPtr)^ <> 0 Then
      SP_XorNumVarIndex(pLongWord(StrPtr)^, SP_StackPtr^.Val)
    Else
      SP_XorNumVar(pLongWord(StrPtr)^,
                   StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                   SP_StackPtr^.Val, Error^, pLongWord(StrPtr));
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_SHLVAR(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    If pLongWord(StrPtr)^ <> 0 Then
      SP_ShlNumVarIndex(pLongWord(StrPtr)^, SP_StackPtr^.Val)
    Else
      SP_ShlNumVar(pLongWord(StrPtr)^,
                   StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                   SP_StackPtr^.Val, Error^, pLongWord(StrPtr));
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_SHRVAR(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    If pLongWord(StrPtr)^ <> 0 Then
      SP_ShrNumVarIndex(pLongWord(StrPtr)^, SP_StackPtr^.Val)
    Else
      SP_ShrNumVar(pLongWord(StrPtr)^,
                   StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                   SP_StackPtr^.Val, Error^, pLongWord(StrPtr));
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_STRVAR_LET(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    If pLongWord(StrPtr)^ <> 0 Then
      SP_UpdateStrVarIndex(pLongWord(StrPtr)^, SP_StackPtr^.Str)
    Else
      SP_UpdateStrVar(pLongWord(StrPtr)^,
                      StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                      SP_StackPtr^.Str, -1, -1, Error^, pLongWord(StrPtr));
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_HYBRID_LET(Var iInfo: pSP_iInfo);
Var
  Name, ValueStr: aString;
  ValueNum: aFloat;
Begin

  With iInfo^ Do Begin
    Name := StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord));
    Name[1] := aChar(Ord(Name[1]) - 128);
    Case SP_StackPtr^.OpTYpe of
      SP_VALUE:
        ValueNum := SP_StackPtr^.Val;
      SP_STRING:
        ValueStr := SP_StackPtr^.Str;
    End;
    If Name = 'CLIP$' Then Begin
      Try
        ClipBoard.AsText := String(ValueStr);
      Except
        iInfo^.Error^.Code := SP_ERR_CLIPBOARD_ERROR;
      End;
    End;
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_STRUCT_MEMBER_N(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    With SP_StackPtr^ Do Begin
      OpType := SP_VALUE;
      Val := SP_GetStructMemberN(pSP_StrVarContent(Ptr), StringFromPtrB(StrPtr, Token^.TokenLen), Error^);
    End;
  End;

End;

Procedure SP_Interpret_SP_STRUCT_MEMBER_ASS(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_STRUCT_MEMBER_ASS;
      Str := StringFromPtrB(StrPtr, Token^.TokenLen);
    End;
  End;

End;

Procedure SP_Interpret_SP_STRUCT_MEMBER_S(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin

    With SP_StackPtr^ Do Begin
      OpType := SP_STRING;
      Str := SP_GetStructMemberS(pSP_StrVarContent(Ptr), StringFromPtrB(StrPtr, Token^.TokenLen), Error^);
    End;

  End;

End;

Procedure SP_Interpret_SP_STRVARPTR(Var iInfo: pSP_iInfo);
Var
  Idx: Integer;
Begin

  With iInfo^ Do Begin
    Idx := pLongWord(StrPtr)^;
    If Idx <> 0 Then Begin
      Dec(Idx);
    End Else Begin
      Idx := SP_FindStrVar(StringFromPtrB(StrPtr + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord)));
      If Idx <> -1 Then Begin
        If Not StrVars[Idx]^.ProcVar Then
          pLongWord(StrPtr)^ := Idx + 1;
      End Else Begin
        Error.Code := SP_ERR_MISSING_VAR;
        Error.Position := Token^.TokenPos;
        Exit;
      End;
    End;
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_STRVARPTR;
      Ptr := pLongWord(StrVars[Idx].ContentPtr);
    End;
  End;

End;

Procedure SP_Interpret_SP_NUMVAR_LET_VALID(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    If SP_StackPtr^.OpType = SP_VALUE Then Begin
      If pLongWord(StrPtr)^ = 0 Then
        SP_UpdateNumVar(dLongWord(StrPtr),
                        StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                        SP_StackPtr^.Val, Error^, pLongWord(StrPtr))
      Else
        SP_UpdateNumVarIndex(dLongWord(StrPtr), SP_StackPtr^.Val);
    End Else Begin
      Error.Code := SP_ERR_MIXED_TYPES;
      Exit;
    End;
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_STRVAR_LET_VALID(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    If SP_StackPtr^.OpType = SP_STRING Then Begin
      If pLongWord(StrPtr)^ = 0 Then
        SP_UpdateStrVar(dLongWord(StrPtr),
                        StringFromPtrB(pByte(StrPtr + SizeOf(LongWord)), Token^.TokenLen - SizeOf(LongWord)),
                        SP_StackPtr^.Str, -1, -1, Error^, pLongWord(StrPtr))
      Else
        SP_UpdateStrVarIndex(dLongWord(StrPtr), SP_StackPtr^.Str);
    End Else Begin
      Error.Code := SP_ERR_MIXED_TYPES;
      Exit;
    End;
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_SP_SKIP_DATA(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    While True Do Begin
      Inc(StrPtr, pLongWord(StrPtr)^ + Token^.TokenLen);
      Token := pToken(StrPtr);
      Inc(StrPtr, SizeOf(TToken));
      If Token^.Token = SP_TERMINAL Then Begin
        Error.Code := SP_EXIT;
        Exit;
      End;
      If Token^.Token = SP_SKIP_LINE Then Begin
        Error.ReturnType := SP_JUMP;
        Exit;
      End;
      If (Token^.Token = SP_SYMBOL) And (aChar(StrPtr^) = ':') Then Begin
        Break;
      End;
    End;
    Inc(iInfo^.Error.Statement);
  End;

End;

Procedure SP_Interpret_SP_RANGE_LESS(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin

    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := Token^.Token;
    End;

  End;

End;

Procedure SP_Interpret_SP_RANGE_GREATER(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin

    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := Token^.Token;
    End;

  End;

End;

Procedure SP_Interpret_SP_RANGE(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin

    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := Token^.Token;
    End;

  End;

End;

Procedure SP_Interpret_SP_RANGE_ARRAYSTR(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin

    Inc(SP_StackPtr);
    SP_StackPtr^.OpType := Token^.Token;

  End;

End;

Procedure SP_Interpret_SP_RANGE_ARRAYNUM(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin

    Inc(SP_StackPtr);
    SP_StackPtr^.OpType := Token^.Token;

  End;

End;

Procedure SP_Interpret_SP_SPECIAL_SYMBOL(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Case aChar(StrPtr^) Of
      SP_CHAR_UNARYM:
        Begin
          SP_StackPtr^.Val := -SP_StackPtr^.Val;
        End;
      SP_CHAR_UNARYP:
        Begin
          SP_StackPtr^.Val := SP_StackPtr^.Val;
        End;
    End;
  End;

End;

Procedure SP_Interpret_SP_NUMCONST(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_VALUE;
      Val := paFloat(iInfo^.StrPtr)^;
    End;
  End;

End;

Procedure SP_Interpret_SP_STRCONST(Var iInfo: pSP_iInfo);
Begin

  With iInfo^ Do Begin
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_STRING;
      Str := StringFromPtr(StrPtr, Token^.TokenPos);
      tPos := Token^.TokenPos;
    End;
  End;

End;

Procedure SP_Interpret_SP_CHAR_INT_PLUS(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Round(SP_StackPtr^.Val) + Round(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_NUM_PLUS(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := SP_StackPtr^.Val + pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val;
End;

Procedure SP_Interpret_SP_CHAR_STR_PLUS(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Str := SP_StackPtr^.Str + pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str;
End;

Procedure SP_Interpret_SP_CHAR_MUL(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Round(SP_StackPtr^.Val) * Round(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_BITWISE_NOT(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := LongWord(Round(SP_StackPtr^.Val)) xor $FFFFFFFF;
End;

Procedure SP_Interpret_SP_CHAR_STRING_NOT(Var Info: pSP_iInfo);
Var
  i: Integer;
  p: pByte;
Begin
  With SP_StackPtr^ Do
    i := Length(Str);
    p := pByte(pNativeUInt(@SP_StackPtr.Str)^);
    While i > 0 Do Begin
      p^ := p^ xor 255;
      Dec(i);
      Inc(p);
    End;
End;

Procedure SP_Interpret_SP_CHAR_DIV(Var Info: pSP_iInfo);
Var
  Val: Integer;
Begin
  Dec(SP_StackPtr);
  Val := Round(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
  If Val <> 0 Then
    SP_StackPtr^.Val := Round(SP_StackPtr^.Val) Div Val
  Else
    if ErrorEnabled[SP_ERR_DIV_BY_ZERO] Then
      Info^.Error^.Code := SP_ERR_DIV_BY_ZERO
    Else
      SP_StackPtr^.Val := 0;
End;

Procedure SP_Interpret_SP_CHAR_ADD(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Round(SP_StackPtr^.Val) + Round(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_SUB(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Round(SP_StackPtr^.Val) - Round(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_STR_MUL1(Var Info: pSP_iInfo);
Var
  Len, Idx, Lim: NativeUInt;
  PtrS, PtrD, Start: pByte;
Begin

  // Allows you to multiply strings - 2*a$ for example...

  Str1 := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  Len := Length(Str1);

  If (SP_StackPtr^.Val < 0) or (SP_StackPtr^.Val > MAXINT) Then Begin
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    Exit;
  End Else
    If Len = 0 Then Begin
      SP_StackPtr^.Str := '';
      SP_StackPtr^.OpType := SP_STRING;
      Exit;
    End;

  Lim := Round(SP_StackPtr^.Val) * Len;
  SetLength(SP_StackPtr^.Str, Lim);
  PtrS := pByte(pNativeUInt(@Str1)^);
  PtrD := pByte(pNativeUInt(@SP_StackPtr^.Str)^);
  If Len > 1 Then Begin
    Start := PtrS;
    Idx := 0;
    While Idx < Lim Do Begin
      PtrD^ := PtrS^;
      Inc(PtrD);
      Inc(PtrS);
      Inc(Idx);
      If Idx Mod Len = 0 Then PtrS := Start;
    End;
  End Else
    FillMem(PtrD, Lim, PtrS^);

  SP_StackPtr^.OpType := SP_STRING;

End;

Procedure SP_Interpret_SP_CHAR_STR_MUL2(Var Info: pSP_iInfo);
Var
  Len, Idx, Lim: NativeUInt;
  PtrS, PtrD, Start: pByte;
Begin

  // ... and the reverse - a$*2.

  if (SP_StackPtr^.Val < 0) or (SP_StackPtr^.Val > MAXINT) Then
    Info^.Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE
  Else Begin
    Lim := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);

    Len := Length(SP_StackPtr^.Str);
    If (Lim = 0) or (Len = 0) Then Begin
      SP_StackPtr^.Str := '';
      Exit;
    End;
      Lim := Lim * Len;
    SetLength(SP_StackPtr^.Str, Lim);
    PtrS := pByte(pNativeUInt(@SP_StackPtr^.Str)^);
    PtrD := PtrS;
    If Len > 1 Then Begin
      Inc(PtrD, Len);
      Start := PtrS;
      Idx := Len +1;
      While Idx <= Lim Do Begin
        PtrD^ := PtrS^;
        Inc(PtrD);
        Inc(PtrS);
        Inc(Idx);
        If Idx Mod Len = 1 Then PtrS := Start;
      End;
    End Else
      FillMem(PtrD, Lim, PtrS^);
  End;

End;

Procedure SP_Interpret_SP_CHAR_NUM_EQU(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Ord(SP_StackPtr^.Val = pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_STR_EQU(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Ord(SP_StackPtr^.Str = pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str);
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_SP_CHAR_NUM_LES(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Ord(SP_StackPtr^.Val < pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_STR_LES(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Ord(SP_StackPtr^.Str < pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str);
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_SP_CHAR_NUM_LTE(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Ord(SP_StackPtr^.Val <= pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_STR_LTE(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Ord(SP_StackPtr^.Str <= pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str);
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_SP_CHAR_NUM_DNE(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Ord(SP_StackPtr^.Val <> pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_STR_DNE(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Ord(SP_StackPtr^.Str <> pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str);
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_SP_CHAR_NUM_GTE(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Ord(SP_StackPtr^.Val >= pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_STR_GTE(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Ord(SP_StackPtr^.Str >= pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str);
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_SP_CHAR_NUM_GTR(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Ord(SP_StackPtr^.Val > pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_STR_GTR(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Ord(SP_StackPtr^.Str > pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str);
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_SP_CHAR_GTE(Var Info: pSP_iInfo);
Begin
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    Dec(SP_StackPtr);
    SP_StackPtr^.Val := Ord(SP_StackPtr^.Val >= pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
  End Else Begin
    Dec(SP_StackPtr);
    SP_StackPtr^.Val := Byte(SP_StackPtr^.Str >= pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str);
    SP_StackPtr^.OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_SP_CHAR_LTE(Var Info: pSP_iInfo);
Begin
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    Dec(SP_StackPtr);
    SP_StackPtr^.Val := Ord(SP_StackPtr^.Val <= pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
  End Else Begin
    Dec(SP_StackPtr);
    SP_StackPtr^.Val := Ord(SP_StackPtr^.Str <= pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str);
    SP_StackPtr^.OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_SP_CHAR_DNE(Var Info: pSP_iInfo);
Begin
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    Dec(SP_StackPtr);
    SP_StackPtr^.Val := Ord(SP_StackPtr^.Val <> pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
  End Else Begin
    Dec(SP_StackPtr);
    SP_StackPtr^.Val := Ord(SP_StackPtr^.Str <> pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str);
    SP_StackPtr^.OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_SP_CHAR_NUM_AND(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  If pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val = 0 Then
    SP_StackPtr^.Val := 0;
End;

Procedure SP_Interpret_SP_CHAR_STR_AND(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  If pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val = 0 Then
    SP_StackPtr^.Str := '';
End;

Procedure SP_Interpret_SP_CHAR_AND(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  If SP_StackPtr^.OpType = SP_STRING Then Begin
    If pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val = 0 Then
      SP_StackPtr^.Str := '';
  End Else
    If pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val = 0 Then
      SP_StackPtr^.Val := 0;
End;

Procedure SP_Interpret_SP_CHAR_OR(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  If pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val <> 0 Then
    SP_StackPtr^.Val := 1;
End;

Procedure SP_Interpret_SP_CHAR_EQV(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := 1 - (Ord(SP_StackPtr^.Val <> 0) Xor Ord(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val <> 0))
End;

Procedure SP_Interpret_SP_CHAR_IMP(Var Info: pSP_iInfo);
Begin
  If SP_StackPtr^.Val <> 0 Then
    SP_StackPtr^.Val := Ord(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val <> 0)
  Else
    SP_StackPtr^.Val := 1;
End;

Procedure SP_Interpret_SP_CHAR_MOD(Var Info: pSP_iInfo);
Var
  Val1, Val2: Integer;
Begin
  Dec(SP_StackPtr);
  Val1 := Round(SP_StackPtr^.Val);
  Val2 := Round(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
  if Val2 <> 0 Then
    SP_StackPtr^.Val := SP_ModCalc(Val1, Val2)
  Else
    if ErrorEnabled[SP_ERR_DIV_BY_ZERO] Then
      Info^.Error^.Code := SP_ERR_DIV_BY_ZERO
    Else
      SP_StackPtr^.Val := 0;
End;

Procedure SP_Interpret_SP_CHAR_FMOD(Var Info: pSP_iInfo);
Var
  Val1, Val2: aFloat;
Begin
  Dec(SP_StackPtr);
  Val1 := SP_StackPtr^.Val;
  Val2 := pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val;
  if Val2 <> 0 Then
    SP_StackPtr^.Val := SP_FModCalc(Val1, Val2)
  Else
    if ErrorEnabled[SP_ERR_DIV_BY_ZERO] Then
      Info^.Error^.Code := SP_ERR_DIV_BY_ZERO
    Else
      SP_StackPtr^.Val := 0;
End;

Procedure SP_Interpret_SP_CHAR_XOR(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Round(SP_StackPtr^.Val) Xor Round(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_SHL(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Round(SP_StackPtr^.Val) Shl Round(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_SHR(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Round(SP_StackPtr^.Val) Shr Round(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_PLUS(Var Info: pSP_iInfo);
Begin
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    Dec(SP_StackPtr);
    SP_StackPtr^.Val := SP_StackPtr^.Val + pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val;
  End Else Begin
    Dec(SP_StackPtr);
    SP_StackPtr^.Str := SP_StackPtr^.Str + pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str;
  End;
End;

Procedure SP_Interpret_SP_CHAR_MINUS(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := SP_StackPtr^.Val - pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val;
End;

Procedure SP_Interpret_SP_CHAR_MULTIPLY(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := SP_StackPtr^.Val * pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val;
End;

Procedure SP_Interpret_SP_CHAR_DIVIDE(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  If pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val = 0 Then Begin
    if ErrorEnabled[SP_ERR_DIV_BY_ZERO] Then
      Info^.Error^.Code := SP_ERR_DIV_BY_ZERO
    Else
      SP_StackPtr^.Val := 0;
  End Else
    SP_StackPtr^.Val := SP_StackPtr^.Val / pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val;
End;

Procedure SP_Interpret_SP_CHAR_POWER(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := SP_Power(SP_StackPtr^.Val, pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val)
End;

Procedure SP_Interpret_SP_CHAR_COLON(Var Info: pSP_iInfo);
Begin
  Inc(Info^.Error^.Statement);
  //SP_StackPtr := SP_StackStart;
  DoPeriodicalEvents(Info^.Error^);
End;

Procedure SP_Interpret_SP_CHAR_EQUALS(Var Info: pSP_iInfo);
Begin
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    Dec(SP_StackPtr);
    SP_StackPtr^.Val := Byte(SP_StackPtr^.Val = pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
  End Else Begin
    Dec(SP_StackPtr);
    SP_StackPtr^.Val := Byte(SP_StackPtr^.Str = pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str);
    SP_StackPtr^.OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_SP_CHAR_GREATER(Var Info: pSP_iInfo);
Begin
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    Dec(SP_StackPtr);
    SP_StackPtr^.Val := Byte(SP_StackPtr^.Val > pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
  End Else Begin
    Dec(SP_StackPtr);
    SP_StackPtr^.Val := Byte(SP_StackPtr^.Str > pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str);
    SP_StackPtr^.OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_SP_CHAR_LESS(Var Info: pSP_iInfo);
Begin
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    Dec(SP_StackPtr);
    SP_StackPtr^.Val := Byte(SP_StackPtr^.Val < pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
  End Else Begin
    Dec(SP_StackPtr);
    SP_StackPtr^.Val := Byte(SP_StackPtr^.Str < pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str);
    SP_StackPtr^.OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_SP_CHAR_BIT_OR(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Round(SP_StackPtr^.Val) Or Round(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_BIT_AND(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := Round(SP_StackPtr^.Val) And Round(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
End;

Procedure SP_Interpret_SP_CHAR_EXCLAIM(Var Info: pSP_iInfo);
Var
  Idx: LongWord;
Begin
  With Info^ Do Begin
    If SP_StackPtr^.Val > 0 Then Begin
      SavePos := 1;
      For Idx := 1 To Round(SP_StackPtr^.Val) Do
        SavePos := SavePos * Idx;
      SP_StackPtr^.Val := SavePos;
    End Else
      Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
  End;
End;

Procedure SP_Interpret_SP_CHAR_TILDE(Var Info: pSP_iInfo);
Begin
  // Inverted string concatenation, used by OUT.
  Dec(SP_StackPtr);
  SP_StackPtr^.Str := pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str + SP_StackPtr^.Str;
End;

Procedure SP_Interpret_SP_CHAR_INCVAR(Var Info: pSP_iInfo);
Var
  vl: NativeUInt;
  Idx: Integer;
  n: aFloat;
Begin

  n := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_NUM_ARRAY_PTR Then Begin
    vl := Round(SP_StackPtr^.Val);
    pSP_NumVarContent(vl)^.Value := pSP_NumVarContent(vl)^.Value + n;
    SP_StackPtr^.OpType := SP_VALUE;
    SP_StackPtr^.Val := pSP_NumVarContent(vl)^.Value;
  End Else Begin

    With Info^, SP_StackPtr^ Do Begin
      Idx := Trunc(Val);
      If Idx = 0 Then Begin
        Idx := SP_IncNumVar(Idx, Str, n, Error^, Ptr);
      End Else Begin
        SP_IncNumVarIndex(Idx, n);
        Dec(Idx);
      End;
      If Idx >= 0 Then Begin
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := NumVars[Idx]^.ContentPtr^.Value;
      End;
    End;

  End;

End;

Procedure SP_Interpret_SP_CHAR_DECVAR(Var Info: pSP_iInfo);
Var
  vl: NativeUInt;
  Idx: Integer;
  n: aFloat;
Begin

  n := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_NUM_ARRAY_PTR Then Begin
    vl := Round(SP_StackPtr^.Val);
    pSP_NumVarContent(vl)^.Value := pSP_NumVarContent(vl)^.Value - n;
    SP_StackPtr^.OpType := SP_VALUE;
    SP_StackPtr^.Val := pSP_NumVarContent(vl)^.Value;
  End Else Begin

    With Info^, SP_StackPtr^ Do Begin
      Idx := Ptr^;
      If Idx = 0 Then Begin
        Idx := SP_DecNumVar(Ptr^, Str, n, Error^, Ptr);
      End Else Begin
        SP_DecNumVarIndex(Ptr^, n);
        Dec(Idx);
      End;
      If Idx >= 0 Then Begin
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := NumVars[Idx]^.ContentPtr^.Value;
      End;
    End;

  End;

End;

Procedure SP_Interpret_SP_CHAR_MULVAR(Var Info: pSP_iInfo);
Var
  vl: NativeUInt;
  Idx: Integer;
  n: aFloat;
Begin

  n := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_NUM_ARRAY_PTR Then Begin
    vl := Round(SP_StackPtr^.Val);
    pSP_NumVarContent(vl)^.Value := pSP_NumVarContent(vl)^.Value * n;
    SP_StackPtr^.OpType := SP_VALUE;
    SP_StackPtr^.Val := pSP_NumVarContent(vl)^.Value;
  End Else Begin

    With Info^, SP_StackPtr^ Do Begin
      Idx := Ptr^;
      If Idx = 0 Then Begin
        Idx := SP_MulNumVar(Ptr^, Str, n, Error^, Ptr);
      End Else Begin
        SP_MulNumVarIndex(Ptr^, n);
        Dec(Idx);
      End;
      If Idx >= 0 Then Begin
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := NumVars[Idx]^.ContentPtr^.Value;
      End;
    End;

  End;

End;

Procedure SP_Interpret_SP_CHAR_DIVVAR(Var Info: pSP_iInfo);
Var
  vl: NativeUInt;
  Idx: Integer;
  n: aFloat;
Begin

  n := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_NUM_ARRAY_PTR Then Begin
    vl := Round(SP_StackPtr^.Val);
    If n = 0 Then Begin
      if ErrorEnabled[SP_ERR_DIV_BY_ZERO] Then Begin
        Info^.Error^.Code := SP_ERR_DIV_BY_ZERO;
        Exit;
      End Else Begin
        pSP_NumVarContent(vl)^.Value := 0;
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := pSP_NumVarContent(vl)^.Value;
        Exit;
      End;
    End;
    pSP_NumVarContent(vl)^.Value := pSP_NumVarContent(vl)^.Value / n;
    SP_StackPtr^.OpType := SP_VALUE;
    SP_StackPtr^.Val := pSP_NumVarContent(vl)^.Value;
  End Else Begin

    With Info^, SP_StackPtr^ Do Begin
      Idx := Ptr^;
      If Idx = 0 Then Begin
        Idx := SP_DivNumVar(Ptr^, Str, n, Error^, Ptr);
      End Else Begin
        SP_DivNumVarIndex(Ptr^, n, Error^);
        Dec(Idx);
      End;
      If Idx >= 0 Then Begin
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := NumVars[Idx]^.ContentPtr^.Value;
      End;
    End;

  End;

End;

Procedure SP_Interpret_SP_CHAR_POWVAR(Var Info: pSP_iInfo);
Var
  vl: NativeUInt;
  Idx: Integer;
  n: aFloat;
Begin

  n := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_NUM_ARRAY_PTR Then Begin
    vl := Round(SP_StackPtr^.Val);
    pSP_NumVarContent(vl)^.Value := SP_Power(pSP_NumVarContent(vl)^.Value, n);
    SP_StackPtr^.OpType := SP_VALUE;
    SP_StackPtr^.Val := pSP_NumVarContent(vl)^.Value;
  End Else Begin

    With Info^, SP_StackPtr^ Do Begin
      Idx := Ptr^;
      If Idx = 0 Then Begin
        Idx := SP_PowNumVar(Ptr^, Str, n, Error^, Ptr);
      End Else Begin
        SP_PowNumVarIndex(Ptr^, n);
        Dec(Idx);
      End;
      If Idx >= 0 Then Begin
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := NumVars[Idx]^.ContentPtr^.Value;
      End;
    End;

  End;

End;

Procedure SP_Interpret_SP_CHAR_MODVAR(Var Info: pSP_iInfo);
Var
  vl, val, n: NativeUInt;
  Idx: Integer;
Begin

  n := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_NUM_ARRAY_PTR Then Begin
    vl := Round(SP_StackPtr^.Val);
    If n = 0 Then Begin
      if ErrorEnabled[SP_ERR_DIV_BY_ZERO] Then Begin
        Info^.Error^.Code := SP_ERR_DIV_BY_ZERO;
        Exit;
      End Else Begin
        pSP_NumVarContent(vl)^.Value := 0;
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := pSP_NumVarContent(vl)^.Value;
        Exit;
      End;
    End;
    val := Round(pSP_NumVarContent(vl)^.Value);
    pSP_NumVarContent(vl)^.Value := SP_ModCalc(Val, n);
    SP_StackPtr^.OpType := SP_VALUE;
    SP_StackPtr^.Val := pSP_NumVarContent(vl)^.Value;
  End Else Begin

    With Info^, SP_StackPtr^ Do Begin
      Idx := Ptr^;
      If Idx = 0 Then Begin
        Idx := SP_ModNumVar(Ptr^, Str, n, Error^, Ptr);
      End Else Begin
        SP_ModNumVarIndex(Ptr^, n, Error^);
        Dec(Idx);
      End;
      If Idx >= 0 Then Begin
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := NumVars[Idx]^.ContentPtr^.Value;
      End;
    End;

  End;

End;

Procedure SP_Interpret_SP_CHAR_ANDVAR(Var Info: pSP_iInfo);
Var
  vl: NativeUInt;
  Idx: Integer;
  n: aFloat;
Begin

  n := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_NUM_ARRAY_PTR Then Begin
    vl := Round(SP_StackPtr^.Val);
    pSP_NumVarContent(vl)^.Value := Round(pSP_NumVarContent(vl)^.Value) And Round(n);
    SP_StackPtr^.OpType := SP_VALUE;
    SP_StackPtr^.Val := pSP_NumVarContent(vl)^.Value;
  End Else Begin

    With Info^, SP_StackPtr^ Do Begin
      Idx := Ptr^;
      If Idx = 0 Then Begin
        Idx := SP_AndNumVar(Ptr^, Str, n, Error^, Ptr);
      End Else Begin
        SP_AndNumVarIndex(Ptr^, n);
        Dec(Idx);
      End;
      If Idx >= 0 Then Begin
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := NumVars[Idx]^.ContentPtr^.Value;
      End;
    End;

  End;

End;

Procedure SP_Interpret_SP_CHAR_XORVAR(Var Info: pSP_iInfo);
Var
  vl: NativeUInt;
  Idx: Integer;
  n: aFloat;
Begin

  n := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_NUM_ARRAY_PTR Then Begin
    vl := Round(SP_StackPtr^.Val);
    pSP_NumVarContent(vl)^.Value := Round(pSP_NumVarContent(vl)^.Value) Xor Round(n);
    SP_StackPtr^.OpType := SP_VALUE;
    SP_StackPtr^.Val := pSP_NumVarContent(vl)^.Value;
  End Else Begin

    With Info^, SP_StackPtr^ Do Begin
      Idx := Ptr^;
      If Idx = 0 Then Begin
        Idx := SP_XorNumVar(Ptr^, Str, n, Error^, Ptr);
      End Else Begin
        SP_XorNumVarIndex(Ptr^, n);
        Dec(Idx);
      End;
      If Idx >= 0 Then Begin
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := NumVars[Idx]^.ContentPtr^.Value;
      End;
    End;

  End;

End;

Procedure SP_Interpret_SP_CHAR_ORVAR(Var Info: pSP_iInfo);
Var
  vl: NativeUInt;
  Idx: Integer;
  n: aFloat;
Begin

  n := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_NUM_ARRAY_PTR Then Begin
    vl := Round(SP_StackPtr^.Val);
    pSP_NumVarContent(vl)^.Value := Round(pSP_NumVarContent(vl)^.Value) Or Round(n);
    SP_StackPtr^.OpType := SP_VALUE;
    SP_StackPtr^.Val := pSP_NumVarContent(vl)^.Value;
  End Else Begin

    With Info^, SP_StackPtr^ Do Begin
      Idx := Ptr^;
      If Idx = 0 Then Begin
        Idx := SP_OrNumVar(Ptr^, Str, n, Error^, Ptr);
      End Else Begin
        SP_OrNumVarIndex(Ptr^, n);
        Dec(Idx);
      End;
      If Idx >= 0 Then Begin
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := NumVars[Idx]^.ContentPtr^.Value;
      End;
    End;

  End;

End;

Procedure SP_Interpret_SP_CHAR_NOTVAR(Var Info: pSP_iInfo);
Var
  vl: NativeUInt;
  Idx: Integer;
  n: aFloat;
Begin

  n := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_NUM_ARRAY_PTR Then Begin
    vl := Round(SP_StackPtr^.Val);
    if vl = 0 then
      pSP_NumVarContent(vl)^.Value := 1
    else
      pSP_NumVarContent(vl)^.Value := 0;
    SP_StackPtr^.OpType := SP_VALUE;
    SP_StackPtr^.Val := pSP_NumVarContent(vl)^.Value;
  End Else Begin

    With Info^, SP_StackPtr^ Do Begin
      Idx := Ptr^;
      If Idx = 0 Then Begin
        Idx := SP_NotNumVar(Ptr^, Str, n, Error^, Ptr);
      End Else Begin
        SP_NotNumVarIndex(Ptr^, n);
        Dec(Idx);
      End;
      If Idx >= 0 Then Begin
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := NumVars[Idx]^.ContentPtr^.Value;
      End;
    End;

  End;

End;

Procedure SP_Interpret_SP_CHAR_SHLVAR(Var Info: pSP_iInfo);
Var
  vl: NativeUInt;
  Idx: Integer;
  n: aFloat;
Begin

  n := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_NUM_ARRAY_PTR Then Begin
    vl := Round(SP_StackPtr^.Val);
    pSP_NumVarContent(vl)^.Value := Round(pSP_NumVarContent(vl)^.Value) Shl Round(n);
    SP_StackPtr^.OpType := SP_VALUE;
    SP_StackPtr^.Val := pSP_NumVarContent(vl)^.Value;
  End Else Begin

    With Info^, SP_StackPtr^ Do Begin
      Idx := Trunc(Val);
      If Idx = 0 Then Begin
        Idx := SP_ShlNumVar(Idx, Str, n, Error^, Ptr);
      End Else Begin
        SP_ShlNumVarIndex(Idx, n);
        Dec(Idx);
      End;
      If Idx >= 0 Then Begin
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := NumVars[Idx]^.ContentPtr^.Value;
      End;
    End;

  End;

End;

Procedure SP_Interpret_SP_CHAR_SHRVAR(Var Info: pSP_iInfo);
Var
  vl: NativeUInt;
  Idx: Integer;
  n: aFloat;
Begin

  n := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_NUM_ARRAY_PTR Then Begin
    vl := Round(SP_StackPtr^.Val);
    pSP_NumVarContent(vl)^.Value := Round(pSP_NumVarContent(vl)^.Value) Shr Round(n);
    SP_StackPtr^.OpType := SP_VALUE;
    SP_StackPtr^.Val := pSP_NumVarContent(vl)^.Value;
  End Else Begin

    With Info^, SP_StackPtr^ Do Begin
      Idx := Trunc(Val);
      If Idx = 0 Then Begin
        Idx := SP_ShrNumVar(Idx, Str, n, Error^, Ptr);
      End Else Begin
        SP_ShrNumVarIndex(Idx, n);
        Dec(Idx);
      End;
      If Idx >= 0 Then Begin
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := NumVars[Idx]^.ContentPtr^.Value;
      End;
    End;

  End;

End;

Procedure SP_SetHandler(Var Token: pToken; Var StrPtr: pByte);
Begin

  Case Token^.Token of
    SP_KEYWORD:
      Begin
        Token^.Handler := InterpretProcs[pLongWord(StrPtr)^];
      End;
    SP_FUNCTION:
      Begin
        Token^.Handler := InterpretProcs[pLongWord(StrPtr)^];
      End;
    SP_SYMBOL:
      Begin
        Token^.Handler := InterpretProcs[6000 + pByte(StrPtr)^];
      End;
  Else
    Begin
      Token^.Handler := InterpretProcs[Token^.Token];
    End;
  End;

End;

Procedure SP_AddHandlers(Var Tokens: aString);
Var
  Idx: Integer;
  StrPtr: pByte;
  Tkn: pToken;
Begin

  If Tokens <> '' Then Begin

    Idx := 1;
    If Tokens[Idx] = aChar(SP_LINE_NUM) Then Inc(Idx, 1 + SizeOf(LongWord));
    If Tokens[Idx] = aChar(SP_STATEMENTS) Then Idx := pLongWord(@Tokens[1 + Idx + SizeOf(LongWord)])^;

    While Idx < Length(Tokens) Do Begin

      Tkn := @Tokens[Idx];
      Inc(Idx, SizeOf(TToken));
      If Tkn^.Token = SP_TERMINAL Then
        Break
      Else Begin
        If Idx <= Length(Tokens)Then
          StrPtr := @Tokens[Idx]
        Else
          StrPtr := nil;
        SP_SetHandler(Tkn, StrPtr);
        Inc(Idx, Tkn^.TokenLen);
      End;

    End;

  End;
End;

Procedure DoPeriodicalEvents(var Error: TSP_ErrorCode);
Begin

  If OnActive > 0 Then SP_CheckONConditions(Error);
  If ControlsAreInUse Then DoTimerEvents;

End;

Function CheckForONERROR(Var Error: TSP_ERRORCODE): Boolean;
Var
  LineItem: TSP_GOSUB_Item;
Begin
  Result := False;
  If ERROR_LineNum <> -1 Then Begin
    If (Error.Code <> SP_ERR_OK) And Not IGNORE_ON_ERROR Then Begin
      Error.Code := SP_ERR_OK;
      If Error.ReturnType >= SP_JUMP Then Begin
        SP_StackLine(NXTLINE, NXTSTATEMENT, Error.Statement, SP_KW_ERROR, Error);
      End Else Begin
        LineItem := SP_ConvertLineStatement(Error.Line, Error.Statement +1);
        SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_ERROR, Error);
      End;
      NXTLINE := ERROR_LineNum;
      NXTSTATEMENT := ERROR_Statement;
      Error.Statement := ERROR_St;
      Error.ReturnType := SP_JUMP;
      IGNORE_ON_ERROR := True;
      Result := True;
    End;
  End;
End;

Procedure SP_InterpretCONTSafe(Const Tokens: paString; Var nPosition: Integer; Var Error: TSP_ErrorCode);
Var
  cLine, cStatement: Integer;
Begin
  Inc(INPROC);
  If INPROC >= MAXDEPTH Then
    Error.Code := SP_ERR_OUT_OF_MEMORY
  Else Begin
    cLine := CONTLINE;
    cStatement := CONTSTATEMENT;
    SP_Interpret(Tokens, nPosition, Error);
    if (CONTLINE = cLine) and (CONTSTATEMENT = cStatement) Then
      Inc(cStatement);
    CONTSTATEMENT := cStatement;
    CONTLINE := cLine;
  End;
  Dec(INPROC);
End;

Procedure SP_Interpret(Const Tokens: paString; Var nPosition: Integer; Var Error: TSP_ErrorCode);
Var
  Idx, CurST, OldST, OldEC: Integer;
  Info: TSP_iInfo;
  pInfo: pSP_iInfo;
  BreakNow: Boolean;
  Ls: TSP_GOSUB_Item;
  res: aString;
Label
  Next_Statement;
Begin

  pInfo := @Info;

  Info.Tokens := Tokens;
  Info.Error := @Error;
  Info.Error^.ReturnType := 0;
  Info.StrStart := pByte(pNativeUInt(Tokens)^);
  Info.StrPtr := Info.StrStart + nPosition - 1;
  Info.SavePos := NativeUInt(Info.StrPtr);
  Info.Position := nPosition;

  If Info.StrPtr^ = SP_LINE_NUM Then
    Inc(Info.StrPtr^, 1 + SizeOf(LongWord));

  If Info.StrPtr^ = SP_STATEMENTS Then
    Inc(Info.StrPtr, 1 + ((1 + pLongWord(Info.StrPtr + 1)^) * SizeOf(LongWord)));

  OldSt := Info.Error^.Statement;

  With Info Do Begin

    While Not QUITMSG Do Begin

      Next_Statement:

      // Pick up the first token, then address the content of that token.

      Token := pToken(StrPtr);

      If Token^.Token <> SP_TERMINAL Then Begin

        // Test for debugging - a source breakpoint triggered here is pre-execution so leave CONTINUE point as-is
        If DEBUGGING Then Begin

          If Token^.BPIndex >= 0 Then
            With SP_SourceBreakPointList[Token^.BPIndex] Do Begin
              BreakNow := PassCount = 0;
              If Condition <> '' Then
                BreakNow := (SP_FPExecuteNumericExpression(Compiled_Condition, Info.Error^) <> 0) And BreakNow;
              If BreakNow Then Begin
                BPSIGNAL := True;
                Break;
              End Else
                If PassCount > 0 Then
                  Dec(PassCount);
            End;

          If (OldSt <> Error^.Statement) Then Begin
            // Test for single step
            If STEPMODE = SM_Single Then Begin
              CurST := SP_GetStatementFromOffset(Error^.Line, (NativeUInt(StrPtr) - NativeUInt(StrStart)) +1);
              If CurST <> CONTSTATEMENT Then Begin
                BPSIGNAL := True;
                Break;
              End;
            End;
            // Test conditional and data breakpoints - this is post execution so alter CONTINUE.
            For Idx := 0 To Length(SP_ConditionalBreakPointList) -1 Do
              With SP_ConditionalBreakPointList[Idx] Do Begin
                OldEC := Info.Error^.Code;
                BreakNow := PassCount = 0;
                If bpType = BP_Conditional Then
                  BreakNow := (SP_FPExecuteNumericExpression(Compiled_Condition, Info.Error^) <> 0) And BreakNow
                Else Begin
                  res := SP_FPExecuteAnyExpression(Compiled_Condition, Info.Error^);
                  BreakNow := ((HasResult And (res <> CurResult)) or (Not HasResult)) and BreakNow and (Info.Error^.Code = SP_ERR_OK);
                  If Info.Error^.Code = SP_ERR_OK Then Begin
                    CurResult := res;
                    HasResult := True;
                  End;
                End;
                Info.Error^.Code := OldEC;
                If BreakNow Then Begin
                  BPSIGNAL := True;
                  BREAKSIGNAL := True;
                  CONTLINE := Info.Error^.Line;
                  CONTSTATEMENT := SP_GetStatementFromOffset(Info.Error^.Line, (NativeUInt(StrPtr) - NativeUInt(StrStart)) +1) +1;
                  Info.Error^.Code := SP_ERR_BREAKPOINT;
                  Info.Error^.Line := CONTLINE;
                  Info.Error^.Statement := CONTSTATEMENT;
                  Exit;
                End Else
                  If PassCount > 0 Then
                    Dec(PassCount);
              End;
          End;

        End;

        If BREAKSIGNAL Then
          Break;

        // Continue with execution

        Inc(StrPtr, SizeOf(TToken));

        If Token^.Token = SP_KEYWORD Then Begin
          Error^.Position := Token^.TokenLen + 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart));
          Error^.Statement := Token^.TokenPos; // TokenPos is STATEMENT NUMBER! IMPORTANT!
          INPUTERROR := False;
        End;
        TSP_InterpretProc(Token^.Handler)(pInfo);

        Inc(StrPtr, Token^.TokenLen);

        If (Error.ReturnType >= SP_JUMP) or (Error.Code <> SP_ERR_OK) Then Begin
          // A jump or an error (or a user BREAK event) has occurred.
          If Not CheckForONERROR(Error^) Then
            If (Error.ReturnType < SP_JUMP) and ((Error.Code = SP_ERR_STOP) or (Error.Code = SP_ERR_BREAK)) and (Error.Line >= 0) Then Begin
              Ls := SP_ConvertLineStatement(Error.Line, Error.Statement + 1);
              CONTLINE := Ls.Line;
              If CONTLINE >= 0 Then
                CONTSTATEMENT := SP_GetStatementFromOffset(CONTLINE, Ls.Statement);
            End;
          Break;
        End;

      End Else Begin

        // Terminal char - EOL!

        If NXTLINE = -1 Then Begin
          CONTLINE := Error.Line +1;
          CONTSTATEMENT := 1;
        End Else Begin
          CONTLINE := NXTLINE;
          If NXTSTATEMENT = -1 Then
            CONTSTATEMENT := 1
          Else
            CONTSTATEMENT := SP_GetStatementFromOffset(NXTLINE, NXTSTATEMENT);
        End;
        nPosition := NativeUInt(StrPtr) - NativeUInt(StrStart) + 1 + SizeOf(TToken);
        Exit;

      End;

    End;

    If Error.Code < 0 Then Begin // SP_EXIT or SP_NEW
      If NXTLINE = -1 Then Begin
        CONTLINE := Error.Line +1;
        CONTSTATEMENT := 1;
      End Else Begin
        CONTLINE := NXTLINE;
        CONTSTATEMENT := NXTST;
      End;
      nPosition := Info.Position;
      If Error.Code = SP_EXIT then
        Error.Code := SP_ERR_OK;
      Exit;
    End;

    // Test for BREAK

    If (STEPMODE = SM_Single) And (Error^.Code = SP_ERR_OK) And (Error^.ReturnType >= SP_JUMP) Then
      BPSIGNAL := True;

    If Error^.Code = SP_ERR_OK Then Begin
      If (KEYSTATE[K_ESCAPE] = 1) or BREAKSIGNAL or BPSIGNAL Then Begin
        If (Token^.BPIndex >= 0) or (STEPMODE = SM_Single) or BPSIGNAL Then Begin
          If Error.ReturnType >= SP_JUMP Then Begin
            If NXTLINE = -1 Then Begin
              CONTLINE := Error.Line +1;
              CONTSTATEMENT := 1;
            End Else
              If NXTSTATEMENT = -1 Then Begin
                CONTSTATEMENT := 1;
                CONTLINE := NXTLINE;
              End Else Begin
                CONTSTATEMENT := SP_GetStatementFromOffset(NXTLINE, NXTSTATEMENT);
                CONTLINE := NXTLINE;
              End;
          End Else Begin
            CONTSTATEMENT := SP_GetStatementFromOffset(Error^.Line, (NativeUInt(StrPtr) - NativeUInt(StrStart)) +1);
            CONTLINE := Error^.Line;
          End;
          Error^.Code := SP_ERR_BREAKPOINT;
          NXTLINE := -1;
          BREAKSIGNAL := False;
          BPSIGNAL := False;
          Exit;
        End Else Begin
          CONTSTATEMENT := Error^.Statement +1;
          CONTLINE := Error^.Line;
          Error^.Code := SP_ERR_BREAK;
        End;
        NXTLINE := -1;
        BREAKSIGNAL := False;
        BPSIGNAL := False;
      End;
    End;

    // Store error information in the sysvars for later - if an ON..ERROR..GO TO is used,
    // then we need to prevent the error handler from detecting it to give the user's code a chance to run.

    With Error^ Do Begin
      LASTERROR := Code;
      LASTERRORLINE := Line;
      LASTERRORSTATEMENT := Statement;
    End;

    If INPUTERROR Then Begin
      // If an error in INPUT occured, then we do not want the error handler (or the ON ERROR) handler to get to it.
      INPUTERROR := False;
      Error^.Code := SP_ERR_OK;
      DoPeriodicalEvents(Error^);
      Goto Next_Statement;
    End;

    Error^.Position := 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart));
    If QUITMSG Then Exit;

    If (Error^.Code <> SP_ERR_OK) or (Error^.ReturnType >= SP_JUMP) or TerminateInterpreter Then Begin
      // If we're jumping to a place in the same line as we're already executing (e.g, FOR..NEXT on the same line)
      // Then don't exit, just set up the jump. NOT FOR AFTER "RUN"
      If (Error^.ReturnType = SP_JUMP) And (NXTLINE = Error^.Line) And (NXTLINE <> -1) Then Begin
        If NXTSTATEMENT <> -1 Then
          Error.Position := NXTSTATEMENT
        Else Begin
          Error.Statement := 1;
          Error.Position := SP_FindStatement(Tokens, 1);
        End;
        Info.StrPtr := Info.StrStart + Error.Position -1;
{        if SP_StackPtr <> SP_StackStart Then
          Log('Unbalanced Stack!');}
        //SP_StackPtr := SP_StackStart;
        Error^.ReturnType := 0;
        Inc(NXTLINE);
        NXTSTATEMENT := -1;
        DoPeriodicalEvents(Error^);
        Goto Next_Statement;
      End;
      If Error^.Code = SP_ERR_OK Then
        Error^.ReturnType := 0
      Else
        If Not ErrorEnabled[Error^.Code] Then Begin
          Error.Code := SP_ERR_OK;
          Goto Next_Statement;
        End;
      Exit;
    End Else Begin
      DoPeriodicalEvents(Error^);
      Goto Next_Statement;
    End;

  End;

End;

Procedure ClearFlags;
Begin

  M_DOWNFLAG := False;
  M_MOVEFLAG := False;
  M_WHEELUPFLAG := False;
  M_WHEELDNFLAG := False;
  K_DOWNFLAG := False;
  K_UPFLAG := False;
  MENU_SHOWFLAG := False;
  MENU_HIDEFLAG := False;
  MENU_HIGHLIGHTFLAG := False;
  IGNORE_ON_ERROR := False;

End;

Procedure SP_CheckONConditions(Var Error: TSP_ErrorCode);
Var
  LineItem: TSP_GOSUB_Item;
Begin

  If Error.Code = SP_ERR_OK Then Begin

    If Not IgnoreEvery Then Begin
      If SP_EveryCount > 0 Then
        If EveryEnabled Then Begin
          SP_CheckEvery(False, Error.Position, Error);
        End Else
          If ReEnableEvery Then Begin
            EveryEnabled := True;
            ReEnableEvery := False;
          End;
    End Else
      IgnoreEvery := False;

  End;

  If MENUSHOW_LineNum <> -1 Then Begin
    If MENU_SHOWFLAG Then Begin
      If Error.ReturnType >= SP_JUMP Then Begin
        SP_StackLine(NXTLINE, NXTSTATEMENT, Error.Statement, SP_KW_EVERY, Error);
      End Else Begin
        LineItem := SP_ConvertLineStatement(Error.Line, Error.Statement +1);
        SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_EVERY, Error);
      End;
      MENU_SHOWFLAG := False;
      NXTLINE := MENUSHOW_LineNum;
      NXTSTATEMENT := MENUSHOW_Statement;
      Error.Statement := MENUSHOW_St;
      Error.ReturnType := SP_JUMP;
    End;
  End;

  If MENUHIDE_LineNum <> -1 Then Begin
    If MENU_HIDEFLAG Then Begin
      If Error.ReturnType >= SP_JUMP Then Begin
        SP_StackLine(NXTLINE, NXTSTATEMENT, Error.Statement, SP_KW_EVERY, Error);
      End Else Begin
        LineItem := SP_ConvertLineStatement(Error.Line, Error.Statement +1);
        SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_EVERY, Error);
      End;
      MENU_HIDEFLAG := False;
      NXTLINE := MENUHIDE_LineNum;
      NXTSTATEMENT := MENUHIDE_Statement;
      Error.Statement := MENUHIDE_St;
      Error.ReturnType := SP_JUMP;
    End;
  End;

  If MENUITEM_LineNum <> -1 Then Begin
    If MENU_HIGHLIGHTFLAG Then Begin
      If Error.ReturnType >= SP_JUMP Then Begin
        SP_StackLine(NXTLINE, NXTSTATEMENT, Error.Statement, SP_KW_EVERY, Error);
      End Else Begin
        LineItem := SP_ConvertLineStatement(Error.Line, Error.Statement +1);
        SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_EVERY, Error);
      End;
      MENU_HIGHLIGHTFLAG := False;
      NXTLINE := MENUITEM_LineNum;
      NXTSTATEMENT := MENUITEM_Statement;
      Error.Statement := MENUITEM_St;
      Error.ReturnType := SP_JUMP;
    End;
  End;

  If COLLIDE_LineNum <> -1 Then Begin
    If COLLIDE_FLAG Then Begin
      If Error.ReturnType >= SP_JUMP Then Begin
        SP_StackLine(NXTLINE, NXTSTATEMENT, Error.Statement, SP_KW_EVERY, Error);
      End Else Begin
        LineItem := SP_ConvertLineStatement(Error.Line, Error.Statement +1);
        SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_ERROR, Error);
      End;
      COLLIDE_FLAG := False;
      NXTLINE := COLLIDE_LineNum;
      NXTSTATEMENT := COLLIDE_Statement;
      Error.Statement := COLLIDE_St;
      Error.ReturnType := SP_JUMP;
    End;
  End;

  If MOUSEMOVE_LineNum <> -1 Then Begin
    If M_MOVEFLAG Then Begin
      If Error.ReturnType >= SP_JUMP Then Begin
        SP_StackLine(NXTLINE, NXTSTATEMENT, Error.Statement, SP_KW_EVERY, Error);
      End Else Begin
        LineItem := SP_ConvertLineStatement(Error.Line, Error.Statement +1);
        SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_EVERY, Error);
      End;
      M_MOVEFLAG := False;
      NXTLINE := MOUSEMOVE_LineNum;
      NXTSTATEMENT := MOUSEMOVE_Statement;
      Error.Statement := MOUSEMOVE_St;
      Error.ReturnType := SP_JUMP;
    End;
  End;

  If MOUSEDOWN_LineNum <> -1 Then Begin
    If M_DOWNFLAG Then Begin
      If Error.ReturnType >= SP_JUMP Then Begin
        SP_StackLine(NXTLINE, NXTSTATEMENT, Error.Statement, SP_KW_EVERY, Error);
      End Else Begin
        LineItem := SP_ConvertLineStatement(Error.Line, Error.Statement +1);
        SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_EVERY, Error);
      End;
      M_DOWNFLAG := False;
      NXTLINE := MOUSEDOWN_LineNum;
      NXTSTATEMENT := MOUSEDOWN_Statement;
      Error.Statement := MOUSEDOWN_St;
      Error.ReturnType := SP_JUMP;
    End;
  End;

  If MOUSEUP_LineNum <> -1 Then Begin
    If M_UPFLAG Then Begin
      If Error.ReturnType >= SP_JUMP Then Begin
        SP_StackLine(NXTLINE, NXTSTATEMENT, Error.Statement, SP_KW_EVERY, Error);
      End Else Begin
        LineItem := SP_ConvertLineStatement(Error.Line, Error.Statement +1);
        SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_EVERY, Error);
      End;
      M_UPFLAG := False;
      NXTLINE := MOUSEUP_LineNum;
      NXTSTATEMENT := MOUSEUP_Statement;
      Error.Statement := MOUSEUP_St;
      Error.ReturnType := SP_JUMP;
    End;
  End;

  If WHEELUP_LineNum <> -1 Then Begin
    If M_WHEELUPFLAG Then Begin
      If Error.ReturnType >= SP_JUMP Then Begin
        SP_StackLine(NXTLINE, NXTSTATEMENT, Error.Statement, SP_KW_EVERY, Error);
      End Else Begin
        LineItem := SP_ConvertLineStatement(Error.Line, Error.Statement +1);
        SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_EVERY, Error);
      End;
      M_WHEELUPFLAG := False;
      NXTLINE := WHEELUP_LineNum;
      NXTSTATEMENT := WHEELUP_Statement;
      Error.Statement := WHEELUP_St;
      Error.ReturnType := SP_JUMP;
    End;
  End;

  If WHEELDOWN_LineNum <> -1 Then Begin
    If M_WHEELDNFLAG Then Begin
      If Error.ReturnType >= SP_JUMP Then Begin
        SP_StackLine(NXTLINE, NXTSTATEMENT, Error.Statement, SP_KW_EVERY, Error);
      End Else Begin
        LineItem := SP_ConvertLineStatement(Error.Line, Error.Statement +1);
        SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_EVERY, Error);
      End;
      M_WHEELDNFLAG := False;
      NXTLINE := WHEELDOWN_LineNum;
      NXTSTATEMENT := WHEELDOWN_Statement;
      Error.Statement := WHEELDOWN_St;
      Error.ReturnType := SP_JUMP;
    End;
  End;

  If KEYDOWN_LineNum <> -1 Then Begin
    If K_DOWNFLAG Then Begin
      If Error.ReturnType >= SP_JUMP Then Begin
        SP_StackLine(NXTLINE, NXTSTATEMENT, Error.Statement, SP_KW_EVERY, Error);
      End Else Begin
        LineItem := SP_ConvertLineStatement(Error.Line, Error.Statement +1);
        SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_EVERY, Error);
      End;
      K_DOWNFLAG := False;
      NXTLINE := KEYDOWN_LineNum;
      NXTSTATEMENT := KEYDOWN_Statement;
      Error.Statement := KEYDOWN_St;
      Error.ReturnType := SP_JUMP;
    End;
  End;

  If KEYUP_LineNum <> -1 Then Begin
    If K_UPFLAG Then Begin
      If Error.ReturnType >= SP_JUMP Then Begin
        SP_StackLine(NXTLINE, NXTSTATEMENT, Error.Statement, SP_KW_EVERY, Error);
      End Else Begin
        LineItem := SP_ConvertLineStatement(Error.Line, Error.Statement +1);
        SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_EVERY, Error);
      End;
      K_UPFLAG := False;
      NXTLINE := KEYUP_LineNum;
      NXTSTATEMENT := KEYUP_Statement;
      Error.Statement := KEYUP_St;
      Error.ReturnType := SP_JUMP;
    End;
  End;

End;

// Token interpreters - Functions and keywords.

Procedure SP_Interpret_FN_PAR(Var Info: pSP_iInfo);
Var
  v: LongWord;
Begin

  v := Round(SP_StackPtr^.Val);
  v := v Xor (v Shr 1);
  v := v Xor (v Shr 2);
  v := (v And $11111111) * $11111111;
  SP_StackPtr^.Val := ((v Shr 28) And 1) xor 1;

End;

Procedure SP_Interpret_FN_DATADDR(Var Info: pSP_iInfo);
Var
  Id: Integer;
Begin

  Id := SP_FindBankID(Round(SP_StackPtr^.Val));
  If Id > -1 Then Begin
    SP_StackPtr^.Val := NativeUInt(@SP_BankList[Id]^.Memory[0]);
  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_FN_WINADDR(Var Info: pSP_iInfo);
Var
  WinInfo: pSP_Window_Info;
Begin

  SP_GetWindowDetails(Round(SP_StackPtr^.Val), WinInfo, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then
    SP_StackPtr^.Val := NativeUInt(WinInfo^.Surface);

End;

Procedure SP_Interpret_FN_STRADDR(Var Info: pSP_iInfo);
Begin

  SP_StackPtr^.OpType := SP_VALUE;
  SP_StackPtr^.Val := NativeUInt(@pSP_StrVarContent(Sp_StackPtr^.Ptr)^.Value[1]);

End;

Procedure SP_Interpret_FN_MEMRD(Var Info: pSP_iInfo);
Begin

  SP_StackPtr^.Val := pByte(Round(SP_StackPtr^.Val))^;

End;

Procedure SP_Interpret_FN_DMEMRD(Var Info: pSP_iInfo);
Begin

  SP_StackPtr^.Val := pWord(Round(SP_StackPtr^.Val))^;

End;

Procedure SP_Interpret_FN_QMEMRD(Var Info: pSP_iInfo);
Begin

  SP_StackPtr^.Val := pLongWord(Round(SP_StackPtr^.Val))^;

End;

Procedure SP_Interpret_FN_FMEMRD(Var Info: pSP_iInfo);
Begin

  SP_StackPtr^.Val := paFloat(Round(SP_StackPtr^.Val))^;

End;

Procedure SP_Interpret_FN_MEMRDS(Var Info: pSP_iInfo);
Var
  Len: Integer;
Begin

  Len := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_StackPtr^.Str := StringFromPtrB(pByte(Round(SP_StackPtr^.Val)), Len);
  SP_StackPtr^.OpType := SP_STRING;

End;

Procedure SP_Interpret_FN_SPCLX(Var Info: pSP_iInfo);
Var
  Idx: Integer;
Begin

  Idx := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_StackPtr^.Val := SP_GetClonePos(Round(SP_StackPtr^.Val), Idx, Info^.Error^).X;

End;

Procedure SP_Interpret_FN_SPCLY(Var Info: pSP_iInfo);
Var
  Idx: Integer;
Begin

  Idx := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_StackPtr^.Val := SP_GetClonePos(Round(SP_StackPtr^.Val), Idx, Info^.Error^).Y;

End;

Procedure SP_Interpret_FN_KEYS(Var Info: pSP_iInfo);
Var
  NumIndices, VarIdx, VarType: Integer;
  Indices, Key, VarName: aString;
Begin

  NumIndices := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If NumIndices = 0 Then Begin
    VarType := SP_StackPtr^.OpType;
    VarName := SP_StackPtr^.Str;
    Dec(SP_StackPtr);
    Key := SP_StackPtr^.Str;
    Dec(SP_StackPtr);
  End Else Begin
    Key := '';
    VarType := SP_StackPtr^.OpType;
    VarName := SP_StackPtr^.Str;
    Dec(SP_StackPtr);
    While NumIndices > 0 Do Begin
      Indices := LongWordToString(Round(SP_StackPtr^.Val)) + Indices;
      Dec(SP_StackPtr);
      Dec(NumIndices);
    End;
  End;

  If VarType = SP_NUMVAR Then Begin
    VarIdx := SP_FindNumArray(VarName);
    If VarIdx > -1 Then Begin
      Inc(SP_StackPtr);
      SP_StackPtr^.OpType := SP_STRING;
      SP_StackPtr^.Str := SP_GetKeyFromNumArray(VarIdx, Indices, Key, Info^.Error^);
    End Else
      Info^.Error^.Code := SP_ERR_MISSING_VAR;
  End Else Begin
    VarIdx := SP_FindStrArray(VarName);
    If VarIdx > -1 Then Begin
      Inc(SP_StackPtr);
      SP_StackPtr^.OpType := SP_STRING;
      SP_StackPtr^.Str := SP_GetKeyFromStrArray(VarIdx, Indices, Key, Info^.Error^);
    End Else
      Info^.Error^.Code := SP_ERR_MISSING_VAR;
  End;

End;

Procedure SP_Interpret_FN_LASTM(Var Info: pSP_iInfo);
Begin

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := LASTMENU;
  SP_StackPtr^.OpType := SP_Value;

End;

Procedure SP_Interpret_FN_LASTMI(Var Info: pSP_iInfo);
Begin

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := LASTMENUITEM;
  SP_StackPtr^.OpType := SP_Value;

End;

Procedure SP_Interpret_FN_IVAL(Var Info: pSP_iInfo);
Var
  Ps: Integer;
Begin

  With SP_StackPtr^ Do Begin

    OpType := SP_VALUE;
    Val := 0;
    Ps := 1;
    While (Ps <= Length(Str)) And (Not (Str[Ps] in ['0'..'9'])) Do Inc(Ps);
    While (Ps <= Length(Str)) And (Str[Ps] in ['0'..'9']) Do Begin
      Val := (Val * 10) + Ord(Str[Ps]) - 48;
      Inc(Ps);
    End;

  End;

End;

Procedure SP_Interpret_FN_SCREENS(Var Info: pSP_iInfo);
Var
  X, Y, BankID, Idx: Integer;
  Ptr, tPtr, CharAddr, tC: pByte;
  FontInfo: pSP_Font_Info;
Label
  NextChar, BailOut;
Begin

  Y := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  X := Round(SP_StackPtr^.Val);
  SP_StackPtr^.OpType := SP_STRING;
  SP_StackPtr^.Str := '';

  If ((X * FONTWIDTH) >= SCREENWIDTH) or ((Y * FONTHEIGHT) >= SCREENHEIGHT) or (X < 0) or (Y < 0) Then Begin
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    Exit;
  End;

  BankID := SP_FindBankID(FONTBANKID);
  Ptr := pByte(NativeUInt(SCREENPOINTER) + (Y * FONTHEIGHT * SCREENSTRIDE) + (X * FONTWIDTH));

  FontInfo := @SP_BankList[BankID]^.Info[0];

  If FontInfo^.FontType = SP_FONT_TYPE_MONO Then Begin

    CharAddr := @SP_BankList[BankID]^.Memory[FontInfo^.Font_Info[33].Data];
    Idx := 32;

    While True Do Begin

      NextChar:

      tC := CharAddr;
      tPtr := Ptr;

      For y := 1 to FONTHEIGHT Do Begin

        For x := 1 To FONTWIDTH Do Begin

          If ((tC^ = 1) And (tPtr^ <> T_INK)) or ((tC^ = 0) And (tPtr^ <> T_PAPER)) Then Begin

            Inc(CharAddr, FONTWIDTH * FONTHEIGHT);
            Inc(Idx);
            If Idx < 256 Then Goto NextChar Else Exit;

          End Else Begin

            Inc(tPtr);
            Inc(tC);

          End;

        End;

        Inc(tPtr, SCREENSTRIDE - FONTWIDTH);

      End;

      // If we get here then we have a match.

      SP_StackPtr^.Str := aChar(Idx);
      Exit;

    End;

  End;

End;

Procedure SP_ReplaceAll(Const Host, Find, Rep: aString; var OutStr: aString);
var
  hLen, rLen, fLen, cnt: Integer;
  src, dst, {$IFDEF FPC}t, {$ENDIF}dStart, rPtr, fPtr1, fPtr2, hostEnd: pByte;
begin

  hLen := Length(Host);
  rLen := Length(Rep);
  fLen := Length(Find);
  SetLength(OutStr, Max(hLen * rLen, hLen));
  dst := pByte(pNativeUInt(@OutStr)^);
  src := pByte(pNativeUInt(@Host)^);
  dStart := dst;
  rPtr := pByte(pNativeUint(@Rep)^);
  fPtr1 := pByte(pNativeUInt(@Find)^);
  fPtr2 := fPtr1;
  hostEnd := pByte(NativeUInt(src) + hLen);
  cnt := 0;

  While src < hostEnd do Begin
    dst^ := src^;
    If src^ = fPtr2^ Then Begin
      Inc(src);
      Inc(dst);
      Inc(cnt);
      Inc(fPtr2);
      if cnt = fLen then Begin
        {$IFNDEF FPC}
        MoveMemory(pByte(NativeUInt(dst) - cnt), rPtr, rLen);
        {$ELSE}
        t := pByte(NativeUInt(dst) - cnt);
        Move(rPtr, t, rLen);
        {$ENDIF}
        Inc(dst, rLen - fLen);
        cnt := 0;
        fPtr2 := fPtr1;
      End Else
        If src^ <> fPtr2^ then Begin
          cnt := 0;
          fPtr2 := fPtr1;
        End;
    End Else Begin
      Inc(src);
      Inc(dst);
    End;
  End;

  SetLength(OutStr, NativeUInt(dst) - NativeUint(dStart));

end;

Procedure SP_Interpret_FN_REPLACES(Var Info: pSP_iInfo);
Var
  StrB, StrC, tStr: aString;
Begin

  // In order - string to replace with, string to replace, host string
  // Replaces all occurrences.

  StrC := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  StrB := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  if (StrC = '') and (StrB = '') Then Exit;

  tStr := SP_StackPtr^.Str;
  SP_ReplaceAll(tStr, StrB, StrC, SP_StackPtr^.Str);

End;

Procedure SP_Interpret_FN_REPLACEMATCHS(Var Info: pSP_iInfo);
Var
  tStr, StrB, StrC: aString;
  nIdx, Idx: Integer;
Begin

  // In order - string to replace with, regexp to replace, host string
  // Replaces all occurences.

  StrC := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  StrB := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  nIdx := 1;
  tStr := SP_StackPtr^.Str;
  Idx := SP_RegExp(StrB, tStr, nIdx, Info^.Error^);

  If Info^.Error^.Code = SP_ERR_OK Then Begin

    While (Idx < Length(tStr)) and (Idx > 0) Do Begin

      tStr := Copy(tStr, 1, Idx -1) + StrC + Copy(tStr, nIdx, Length(tStr));
      nIdx := Idx + Length(StrC);
      Idx := SP_RegExp(StrB, tStr, nIdx, Info^.Error^);

    End;

    SP_StackPtr^.Str := tStr;

  End;

End;

Procedure SP_Interpret_FN_MANDEL(Var Info: pSP_iInfo);
Var
  Y: aFloat;
  MaxIters: Integer;
Begin

  MaxIters := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Y := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_StackPtr^.Val := Mandel(SP_StackPtr^.Val, Y, MaxIters);

End;

Procedure SP_Interpret_FN_ARSIZE(Var Info: pSP_iInfo);
Var
  VarName: aString;
  vIdx: Integer;
Begin

  VarName := SP_StackPtr^.Str;
  Case SP_StackPtr^.OpType of
    SP_NUMVAR:
      Begin
        vIdx := SP_FindNumArray(VarName);
        If vIdx > -1 Then Begin
          SP_StackPtr^.Val := NumArrays[vIdx].Size;
          SP_StackPtr^.OpType := SP_VALUE;
        End Else
          Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
      End;
    SP_STRVAR:
      Begin
        vIdx := SP_FindStrArray(VarName);
        If vIdx > -1 Then Begin
          SP_StackPtr^.Val := StrArrays[vIdx].Size;
          SP_StackPtr^.OpType := SP_VALUE;
        End Else
          Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
      End;
  End;

End;

Procedure SP_Interpret_FN_LBOUND(Var Info: pSP_iInfo);
Var
  VarName: aString;
  vIdx, Idx: Integer;
Begin

  Idx := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  VarName := SP_StackPtr^.Str;
  ERRStr := VarName;
  Case SP_StackPtr^.OpType of
    SP_NUMVAR:
      Begin
        vIdx := SP_FindNumArray(VarName);
        If vIdx > -1 Then Begin
          If NumArrays[vIdx].DynArray Then
            Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY
          Else
            If (Idx < 1) or (Idx > NumArrays[vIdx].NumIndices) Then
              Info^.Error^.Code := SP_ERR_SUBSCRIPT_WRONG
            Else
              SP_StackPtr^.Val := NumArrays[vIdx].Base;
          SP_StackPtr^.OpType := SP_VALUE;
        End Else
          Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
      End;
    SP_STRVAR:
      Begin
        vIdx := SP_FindStrArray(VarName);
        If vIdx > -1 Then Begin
          If StrArrays[vIdx].DynArray Then
            Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY
          Else
            If (Idx < 1) or (Idx > StrArrays[vIdx].NumIndices) Then
              Info^.Error^.Code := SP_ERR_SUBSCRIPT_WRONG
            Else
              SP_StackPtr^.Val := StrArrays[vIdx].Base;
          SP_StackPtr^.OpType := SP_VALUE;
        End Else
          Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
      End;
  End;

End;

Procedure SP_Interpret_FN_UBOUND(Var Info: pSP_iInfo);
Var
  VarName: aString;
  vIdx, Idx: Integer;
Begin

  Idx := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  VarName := SP_StackPtr^.Str;
  ERRStr := VarName;
  Case SP_StackPtr^.OpType of
    SP_NUMVAR:
      Begin
        vIdx := SP_FindNumArray(VarName);
        If vIdx > -1 Then Begin
          If NumArrays[vIdx].DynArray Then
            Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY
          Else
            If (Idx < 1) or (Idx > NumArrays[vIdx].NumIndices) Then
              Info^.Error^.Code := SP_ERR_SUBSCRIPT_WRONG
            Else
              SP_StackPtr^.Val := NumArrays[vIdx].Indices[Idx -1];
          SP_StackPtr^.OpType := SP_VALUE;
        End Else
          Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
      End;
    SP_STRVAR:
      Begin
        vIdx := SP_FindStrArray(VarName);
        If vIdx > -1 Then Begin
          If StrArrays[vIdx].DynArray Then
            Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY
          Else
            If (Idx < 1) or (Idx > StrArrays[vIdx].NumIndices) Then
              Info^.Error^.Code := SP_ERR_SUBSCRIPT_WRONG
            Else
              SP_StackPtr^.Val := StrArrays[vIdx].Indices[Idx -1];
          SP_StackPtr^.OpType := SP_VALUE;
        End Else
          Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
      End;
  End;

End;

Procedure SP_Interpret_FN_USINGS(Var Info: pSP_iInfo);
Var
  NumTerms: Integer;
  Items: Array of TUsingItem;
Begin

  NumTerms := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SetLength(Items, NumTerms);
  While NumTerms > 0 Do Begin
    With Items[NumTerms -1] Do Begin
      If SP_StackPtr^.OpType = SP_VALUE Then Begin
        Value := SP_StackPtr^.Val;
        Kind := SP_VALUE;
      End Else Begin
        Text := SP_StackPtr^.Str;
        Kind := SP_STRING;
      End;
      Dec(SP_StackPtr);
      Dec(NumTerms);
    End;
  End;

  NumTerms := 1;
  SP_StackPtr^.Str := SP_Using(SP_StackPtr^.Str, Items, NumTerms);

End;

Procedure SP_Interpret_FN_JOINS(Var Info: pSP_iInfo);
Var
  ArrayName, Separator, tStr: aString;
  aIdx, Idx: Integer;
Begin

  // Joins an array into a single string.

  Separator := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  ArrayName := SP_StackPtr^.Str;

  aIdx := SP_FindStrArray(ArrayName);
   If aIdx < 0 Then
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND
  Else Begin
    Idx := 0;
    tStr := '';
    While Idx < Length(StrArrays[aIdx].Strings) -1 Do Begin
      tStr := tStr + StrArrays[aIdx].Strings[Idx]^.Value + Separator;
      Inc(Idx);
    End;
    tStr := tStr + StrArrays[aIdx].Strings[Idx]^.Value;
    SP_StackPtr^.Str := tStr;
  End;

End;

Procedure SP_Interpret_FN_MATCH(Var Info: pSP_iInfo);
Var
  Idx: Integer;
  SearchStr: aString;
Begin

  // Regex matching. Match the string to the regular expression.

  SearchStr := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  Idx := 1;
  With SP_StackPtr^ Do Begin
    Val := SP_RegExp(Str, SearchStr, Idx, Info^.Error^);
    OpType := SP_VALUE;
  End;

End;

Procedure SP_Interpret_FN_INZONE(Var Info: pSP_iInfo);
Var
  y: Integer;
Begin

  y := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_StackPtr^.Val := SP_InZone(Round(SP_StackPtr^.Val), y, Info^.Error^);

End;

Procedure SP_Interpret_FN_TEXTURES(Var Info: pSP_iInfo);
Begin

  If SP_StackPtr^.Str = '' Then
    SP_DefaultFill(SP_StackPtr^.Str, T_INK)
  Else
    SP_StackPtr^.Str := SP_StringToTexture(SP_StackPtr^.Str);

End;

Procedure SP_Interpret_FN_SPFRAME(Var Info: pSP_iInfo);
Var
  SpID: Integer;
  Sprite: pSP_Sprite_Info;
Begin

  With Info^ Do Begin
    SpID := SP_FindSpriteID(Round(SP_StackPtr^.Val), Info^.Error^);
    If Error.Code = SP_ERR_OK Then Begin
      Sprite := pSP_Sprite_Info(@SP_BankList[SpId]^.Info[0]);
      If Sprite^.AnimDelta = 0 Then
        SP_StackPtr^.Val := -1
      Else
        SP_StackPtr^.Val := Sprite^.CurFrame +1;
    End;
  End;

End;

Procedure SP_Interpret_FN_SPCOLL(Var Info: pSP_iInfo);
Var
  SpID: Integer;
  Sprite: pSP_Sprite_Info;
Begin

  With Info^ Do Begin
    SpID := SP_FindSpriteID(Round(SP_StackPtr^.Val), Info^.Error^);
    If Error.Code = SP_ERR_OK Then Begin
      Sprite := pSP_Sprite_Info(@SP_BankList[SpId]^.Info[0]);
      If Sprite^.Collided Then
        SP_StackPtr^.Val := 1
      Else
        SP_StackPtr^.Val := 0;
    End;
  End;

End;

Procedure SP_Interpret_FN_SEARCH(Var Info: pSP_iInfo);
Var
  TermVal: aFloat;
  TermStr, ArrayName: aString;
  isValue: Boolean;
Begin

  // On entry, search term is top of the stack, the array name is next.

  isValue := False;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    TermVal := SP_StackPtr^.Val;
    TermStr := '';
    isValue := True;
  End Else Begin
    TermVal := 0;
    TermStr := SP_StackPtr^.Str;
  End;

  Dec(SP_StackPtr);

  ArrayName := SP_StackPtr^.Str;

  SP_StackPtr^.OpType := SP_VALUE;
  If isValue Then
    SP_StackPtr^.Val := SP_SearchNumArray(ArrayName, TermVal, Info^.Error^)
  Else
    SP_StackPtr^.Val := SP_SearchStrArray(ArrayName, TermStr, Info^.Error^);

End;

Procedure SP_Interpret_FN_SEARCH_NEXT(Var Info: pSP_iInfo);
Var
  ArrayName: aString;
  isValue: Boolean;
Begin

  ArrayName := SP_StackPtr^.Str;
  isValue := SP_StackPtr^.OpType = SP_NUMVAR;

  SP_StackPtr^.OpType := SP_VALUE;
  If isValue Then
    SP_StackPtr^.Val := SP_SearchNumArrayNext(ArrayName, Info^.Error^)
  Else
    SP_StackPtr^.Val := SP_SearchStrArrayNext(ArrayName, Info^.Error^);

End;

Procedure SP_Interpret_FN_IIF(Var Info: pSP_iInfo);
Begin

  // Handles both IIF and IIF$!

  // On entry, Error.Pointer points to the current token. We modify the TOKENLEN
  // member to change where we jump to after this has been evaluated. Top of the stack
  // is the condition. If it's true, we remove the diversion from the stack and continue to interpret.
  // If false, we add the diversion to TOKENLEN and exit.

  Dec(SP_StackPtr);
  If SP_StackPtr^.Val <> 0 Then Begin

    // True, restore the size of the jump, and continue.

    Dec(SP_StackPtr);
    Info^.Token^.TokenLen := 4;

  End Else Begin

    // False. Modify TOKENLEN accordingly to skip the "true" expression and
    // jump directly to the "false" expression.

    Info^.Token^.TokenLen := Round(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val) +4;
    Dec(SP_StackPtr);

  End;

End;

Function GCD(a, b: Integer): Integer;
Begin
  If b <= 0 Then
    Result := a
  Else
    Result := GCD(b, a mod b);
end;

Procedure SP_Interpret_FN_LCM(Var Info: pSP_iInfo);
Var
  b, a: Integer;
Begin

  b := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  a := Round(SP_StackPtr^.Val);

  SP_StackPtr^.Val := Abs(a * b) Div GCD(a, b);

End;

Procedure SP_Interpret_FN_GCD(Var Info: pSP_iInfo);
Var
  b, a: Integer;
Begin

  b := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  a := Round(SP_StackPtr^.Val);

  SP_StackPtr^.Val := GCD(a, b);

End;

Procedure SP_Interpret_FN_BASES(Var Info: pSP_iInfo);
Var
  dValue, Remainder: aFloat;
  Base, Divisor: Integer;
  ResultStr: aString;
Const
  Digits: aString = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
Begin

  Base := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  dValue := Round(SP_StackPtr^.Val);
  ResultStr := '';

  If (Base <= 1) or (Base > 36) Then Begin
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    Exit;
  End;

  While dValue > 0 Do Begin
    Divisor := Round(dValue) Div Base;
    Remainder := dValue - (Divisor * Base);
    ResultStr := Digits[Round(Remainder) +1] + ResultStr;
    dValue := Divisor;
  End;

  SP_StackPtr^.Str := ResultStr;
  SP_StackPtr^.OpType := SP_STRING;

End;

Procedure SP_Interpret_FN_DECIMAL(Var Info: pSP_iInfo);
Var
  Value: Integer;
Begin

  Value := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If (Value > 1) And (Value < 37) Then Begin
    With SP_StackPtr^ Do
      If DecodeBase(SP_StackPtr^.Str, Value) Then Begin
        Val := Value;
        OpType := SP_Value;
      End Else
        Info^.Error^.Code := SP_ERR_INVALID_Integer;
  End Else
    Info^.Error^.Code := SP_ERR_INVALID_RADIX;

End;

Procedure SP_Interpret_FN_MUSICPOS(Var Info: pSP_iInfo);
Begin

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := SP_GetMusicPos(Info^.Error^);

End;

Procedure SP_Interpret_FN_MUSICLEN(Var Info: pSP_iInfo);
Begin

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := SP_GetMusicLen(Info^.Error^);

End;

Procedure SP_Interpret_FN_INV(Var Info: pSP_iInfo);
Begin

  If SP_StackPtr^.Val <> 0 Then Begin
    SP_StackPtr^.Val := 1/SP_StackPtr^.Val;
  End Else Begin
    if ErrorEnabled[SP_ERR_DIV_BY_ZERO] Then
      Info^.Error^.Code := SP_ERR_DIV_BY_ZERO
    Else
      SP_StackPtr^.Val := 0;
  End;

End;

Procedure SP_Interpret_FN_POLYTERM(Var Info: pSP_iInfo);
Var
  x, p, q, r: aFloat;
  n: Integer;
Begin

  n := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  r := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  q := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  p := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  x := SP_StackPtr^.Val;

  SP_StackPtr^.Val := SP_Polyterm(x, p, q, r, n);

End;

Procedure SP_Interpret_FN_UNDER(Var Info: pSP_iInfo);
Var
  x, p, q, r: aFloat;
  n: Integer;
Begin

  n := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  r := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  q := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  p := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  x := SP_StackPtr^.Val;

  SP_StackPtr^.Val := SP_Under(x, p, q, r, n);

End;

Procedure SP_Interpret_FN_COMPSIMPSON(Var Info: pSP_iInfo);
Var
  FnName: aString;
  a,b: aFloat;
  n: Integer;
Begin

  n := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  b := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  a := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  FnName := SP_StackPtr^.Str;

  SP_StackPtr^.Val := SP_CompSimpson(FnName, a, b, n, Info^.Error^);
  SP_StackPtr^.OpType := SP_Value;

End;

Procedure SP_Interpret_FN_MSECS(Var Info: pSP_iInfo);
Begin

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := CB_GETTICKS;
  SP_StackPtr^.OpType := SP_Value;

End;

Procedure SP_Interpret_FN_LTOPX(Var Info: pSP_iInfo);
Var
  X, Y: aFloat;
Begin

  Inc(SP_StackPtr);
  X := SP_StackPtr^.Val;
  SP_ConvertToOrigin_d(X, Y);
  SP_StackPtr^.Val := X;
  SP_StackPtr^.OpType := SP_Value;

End;

Procedure SP_Interpret_FN_LTOPY(Var Info: pSP_iInfo);
Var
  X, Y: aFloat;
Begin

  Inc(SP_StackPtr);
  Y := SP_StackPtr^.Val;
  SP_ConvertToOrigin_d(X, Y);
  SP_StackPtr^.Val := Y;
  SP_StackPtr^.OpType := SP_Value;

End;

Procedure SP_Interpret_FN_PTOLX(Var Info: pSP_iInfo);
Begin

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := SP_ConvertToScreenX(Round(SP_StackPtr^.Val));
  SP_StackPtr^.OpType := SP_Value;

End;

Procedure SP_Interpret_FN_PTOLY(Var Info: pSP_iInfo);
Begin

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := SP_ConvertToScreenY(Round(SP_StackPtr^.Val));
  SP_StackPtr^.OpType := SP_Value;

End;

Procedure SP_Interpret_FN_LOGW(Var Info: pSP_iInfo);
Begin

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := pSP_Window_Info(WINDOWPOINTER)^.orgw - pSP_Window_Info(WINDOWPOINTER)^.orgx;
  SP_StackPtr^.OpType := SP_Value;

End;

Procedure SP_Interpret_FN_LOGH(Var Info: pSP_iInfo);
Begin

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := pSP_Window_Info(WINDOWPOINTER)^.orgh - pSP_Window_Info(WINDOWPOINTER)^.orgy;
  SP_StackPtr^.OpType := SP_Value;

End;

Procedure SP_Interpret_FN_ORGX(Var Info: pSP_iInfo);
Begin

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := pSP_Window_Info(WINDOWPOINTER)^.orgx;
  SP_StackPtr^.OpType := SP_Value;

End;

Procedure SP_Interpret_FN_ORGY(Var Info: pSP_iInfo);
Begin

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := pSP_Window_Info(WINDOWPOINTER)^.orgy;
  SP_StackPtr^.OpType := SP_Value;

End;

Procedure SP_Interpret_FN_PYTH(Var Info: pSP_iInfo);
Var
  Val1, Val2: aFloat;
Begin

  Val1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Val2 := SP_StackPtr^.Val;

  SP_StackPtr^.Val := Sqrt(Sqr(Val1)+Sqr(Val2));

End;

Procedure SP_Interpret_FN_FEXISTS(Var Info: pSP_iInfo);
Begin

  If SP_FileExists(SP_StackPtr^.Str) Then
    SP_StackPtr^.Val := 1
  Else
    SP_StackPtr^.Val := 0;
  SP_StackPtr^.OpType := SP_VALUE;

End;

Procedure SP_Interpret_FN_DEXISTS(Var Info: pSP_iInfo);
Begin

  If SP_DirectoryExists(SP_StackPtr^.Str) Then
    SP_StackPtr^.Val := 1
  Else
    SP_StackPtr^.Val := 0;
  SP_StackPtr^.OpType := SP_VALUE;

End;

Procedure SP_Interpret_FN_FPATH(Var Info: pSP_iInfo);
Begin

  SP_StackPtr^.Str := aString(ExtractFilePath(String(SP_StackPtr^.Str)));

End;

Procedure SP_Interpret_FN_FNAME(Var Info: pSP_iInfo);
Begin

  SP_StackPtr^.Str := aString(ExtractFileName(String(SP_StackPtr^.Str)));

End;

Procedure SP_Interpret_FN_REVS(Var Info: pSP_iInfo);
Begin

  UniqueString(SP_StackPtr^.Str);
  RevString(SP_StackPtr^.Str);

End;

Procedure SP_Interpret_FN_NUBMODE(Var Info: pSP_iInfo);
{$IFDEF PANDORA}
Var
  NubID: Integer;
  NubFile: THandle;
  Buffer: aString;
Const
  NubFiles: Array[0..1] of aString = ('/proc/pandora/nub0/mode', '/proc/pandora/nub1/mode');
{$ENDIF}
Begin

  {$IFDEF PANDORA}

    NubID := Round(SP_StackPtr^.Val);
    If (NubID > 0) And (NubID < 3) Then Begin
      NubFile := FileCreate(NubFiles[NubID -1], fmOpenRead);
      SetLength(Buffer, 5);
      FileRead(NubFile, Buffer[1], 5);
      FileClose(NubFile);
      If Buffer = 'mouse' Then SP_StackPtr^.Val := 0;
      If Buffer = 'absol' Then SP_StackPtr^.Val := 1;
      If Buffer = 'scrol' Then SP_StackPtr^.Val := 2;
      If Buffer = 'mbutt' Then SP_StackPtr^.Val := 3;
    End Else Begin
      Info^.Error^.Code := SP_ERR_INVALID_NUB;
    End;

  {$ELSE}

    SP_StackPtr^.Val := -1;

  {$ENDIF}

End;

Procedure SP_Interpret_FN_NUBX(Var Info: pSP_iInfo);
Begin

  {$IFDEF PANDORA}

    SP_StackPtr^.Val := CB_GetAxis(Round(SP_StackPtr^.Val), 0);

  {$ELSE}

    SP_StackPtr^.Val := 0;

  {$ENDIF}

End;

Procedure SP_Interpret_FN_NUBY(Var Info: pSP_iInfo);
Begin

  {$IFDEF PANDORA}

    SP_StackPtr^.Val := CB_GetAxis(Round(SP_StackPtr^.Val), 1);

  {$ELSE}

    SP_StackPtr^.Val := 0;

  {$ENDIF}

End;

Procedure SP_Interpret_FN_MENUBOX(Var Info: pSP_iInfo);
Var
  Options, newStr: aString;
  NumTerms: Integer;
Begin

  NumTerms := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  NewStr := '';
  Options := LongWordToString(NumTerms);
  While NumTerms > 0 Do Begin
    NewStr := LongWordToString(Length(SP_StackPtr^.Str)) + SP_StackPtr^.Str + NewStr;
    Dec(NumTerms);
    Dec(SP_StackPtr);
  End;
  Options := Options + NewStr;

  Inc(SP_StackPtr);
  SP_StackPtr^.OpType := SP_VALUE;
  SP_StackPtr^.Val := SP_ShowMenu(Options, SCREENWIDTH div 2, SCREENHEIGHT Div 2);

End;

Procedure SP_Interpret_FN_MENUBOX_EX(Var Info: pSP_iInfo);
Var
  ArrayName, Options, newStr: aString;
  Idx, Idx2, NumTerms: Integer;
Begin

  ArrayName := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  NumTerms := 1;
  Options := LongWordToString(Length(SP_StackPtr^.Str)) + SP_StackPtr^.Str;

  Idx := SP_FindStrArray(ArrayName);
  If Idx <> -1 Then Begin

    For Idx2 := 0 To StrArrays[Idx].Size -1 Do Begin
      Inc(NumTerms);
      NewStr := StrArrays[Idx].Strings[Idx2]^.Value;
      Options := Options + LongWordToString(Length(NewStr)) + NewStr;
    End;
    If NumTerms > 1 Then Begin
      Options := LongWordToString(NumTerms) + Options;
      SP_StackPtr^.OpType := SP_VALUE;
      SP_StackPtr^.Val := SP_ShowMenu(Options, SCREENWIDTH div 2, SCREENHEIGHT Div 2);
    End Else Begin
      Info^.Error^.Code := SP_ERR_INSUFFICIENT_PARAMETERS;
    End;

  End Else Begin
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
  End;

End;

Function SP_TestRanges(CheckVal: aFloat; Const CheckStr: aString; IsValue: Boolean; Var Error: TSP_ErrorCode): Boolean;
Var
  NumTerms: Integer;
  rMinNum, rMaxNum: aFloat;
  rMinStr, rMaxStr: aString;
  sPtr: pSP_StackItem;
Begin

  NumTerms := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  sPtr := SP_StackPtr;
  Dec(sPtr, NumTerms);
  Result := False;

  While SP_StackPtr <> sPtr Do Begin
    Case IsValue Of
      True:
        Begin
          Case SP_StackPtr^.OpType of
            SP_VALUE:
              Begin
                If CheckVal = SP_StackPtr^.Val Then Begin
                  SP_StackPtr := sPtr;
                  Result := True;
                  Exit;
                End;
                Dec(SP_StackPtr);
              End;
            SP_RANGE:
              Begin
                Dec(SP_StackPtr);
                rMinNum := SP_StackPtr^.Val;
                Dec(SP_StackPtr);
                rMaxNum := SP_StackPtr^.Val;
                Dec(SP_StackPtr);
                If rMinNum < rMaxNum Then Begin
                  If (CheckVal >= rMinNum) And (CheckVal <= rMaxNum) Then Begin
                    SP_StackPtr := sPtr;
                    Result := True;
                    Exit;
                  End;
                End Else Begin
                  If (CheckVal >= rMaxNum) And (CheckVal <= rMinNum) Then Begin
                    SP_StackPtr := sPtr;
                    Result := True;
                    Exit;
                  End;
                End;
              End;
            SP_RANGE_LESS:
              Begin
                Dec(SP_StackPtr);
                rMaxNum := SP_StackPtr^.Val;
                Dec(SP_StackPtr);
                If CheckVal <= rMaxNum Then Begin
                  SP_StackPtr := sPtr;
                  Result := True;
                  Exit;
                End;
              End;
            SP_RANGE_GREATER:
              Begin
                Dec(SP_StackPtr);
                rMinNum := SP_StackPtr^.Val;
                Dec(SP_StackPtr);
                If CheckVal >= rMinNum Then Begin
                  SP_StackPtr := sPtr;
                  Result := True;
                  Exit;
                End;
              End;
            SP_RANGE_ARRAYNUM:
              Begin
                Dec(SP_StackPtr);
                If SP_ValueInNumArray(SP_StackPtr^.Str, CheckVal, Error) Then Begin
                  SP_StackPtr := sPtr;
                  Result := True;
                  Exit;
                End Else
                  If Error.Code <> SP_ERR_OK Then
                    Exit;
                Dec(SP_StackPtr);
              End;
          End;
        End;
      False:
        Begin
          Case SP_StackPtr^.OpType of
            SP_STRING:
              Begin
                If Pos(CheckStr, SP_StackPtr^.Str) > 0 Then Begin
                  SP_StackPtr := sPtr;
                  Result := True;
                  Exit;
                End;
                Dec(SP_StackPtr);
              End;
            SP_RANGE:
              Begin
                Dec(SP_StackPtr);
                rMinStr := SP_StackPtr^.Str;
                Dec(SP_StackPtr);
                rMaxStr := SP_StackPtr^.Str;
                Dec(SP_StackPtr);
                If rMinStr < rMaxStr Then Begin
                  If (CheckStr >= rMinStr) And (CheckStr <= rMaxStr) Then Begin
                    SP_StackPtr := sPtr;
                    Result := True;
                    Exit;
                  End;
                End Else Begin
                  If (CheckStr >= rMaxStr) And (CheckStr <= rMinStr) Then Begin
                    SP_StackPtr := sPtr;
                    Result := True;
                    Exit;
                  End;
                End;
              End;
            SP_RANGE_LESS:
              Begin
                Dec(SP_StackPtr);
                rMaxStr := SP_StackPtr^.Str;
                Dec(SP_StackPtr);
                If CheckStr <= rMaxStr Then Begin
                  SP_StackPtr := sPtr;
                  Result := True;
                  Exit;
                End;
              End;
            SP_RANGE_GREATER:
              Begin
                Dec(SP_StackPtr);
                rMinStr := SP_StackPtr^.Str;
                Dec(SP_StackPtr);
                If CheckStr >= rMinStr Then Begin
                  SP_StackPtr := sPtr;
                  Result := True;
                  Exit;
                End;
              End;
            SP_RANGE_ARRAYSTR:
              Begin
                Dec(SP_StackPtr);
                If SP_StringInStrArray(SP_StackPtr^.Str, CheckStr, Error) Then Begin
                  SP_StackPtr := sPtr;
                  Result := True;
                  Exit;
                End Else
                  If Error.Code <> SP_ERR_OK Then
                    Exit;
                Dec(SP_StackPtr);
              End;
          End;
        End;
    End;
  End;

End;

Procedure SP_Interpret_FN_IN(Var Info: pSP_iInfo);
Var
  isValue: Boolean;
  NumTerms: Integer;
  CheckVal: aFloat;
  CheckStr: aString;
  Spn: pSP_StackItem;
Begin

  CheckVal := 0;

  NumTerms := Round(SP_StackPtr^.Val);

  isValue := False;
  Spn := SP_StackPtr;
  Dec(Spn, NumTerms +1);
  With Spn^ Do Begin
    If OpType = SP_VALUE Then Begin
      CheckVal := Val;
      isValue := True;
    End Else
      CheckStr := Str;
  End;

  If SP_TestRanges(CheckVal, CheckStr, IsValue, Info^.Error^) Then
    SP_StackPtr^.Val := 1
  Else
    SP_StackPtr^.Val := 0;

  SP_StackPtr^.OpType := SP_VALUE;

End;

Procedure SP_Interpret_FN_PROCID(Var Info: pSP_iInfo);
Var
  ProcName: aString;
  Idx: Integer;
Begin

  ProcName := Lower(SP_StackPtr^.Str);
  If SP_StackPtr^.OpType = SP_STRVAR Then
    ProcName := ProcName + '$';

  // Find the procedure.

  Idx := 0;
  While Idx <= SP_ProcsListPtr Do Begin
    If SP_ProcsList[Idx].Name = ProcName Then
      Break
    Else
      Inc(Idx);
  End;

  If Idx <= SP_ProcsListPtr Then Begin
    SP_StackPtr^.Val := Idx;
    SP_StackPtr^.OpType := SP_VALUE;
  End Else Begin
    Info^.Error^.Code := SP_ERR_PROC_NOT_FOUND;
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_FN_LPADS(Var Info: pSP_iInfo);
Var
  src, pad: aString;
  len: Integer;
Begin

  len := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  pad := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  src := SP_StackPtr^.Str;

  while Length(src) < len do
    src := pad + src;

  SP_StackPtr^.Str := src;

End;

Procedure SP_Interpret_FN_RPADS(Var Info: pSP_iInfo);
Var
  src, pad: aString;
  len: Integer;
Begin

  len := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  pad := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  src := SP_StackPtr^.Str;

  while Length(src) < len do
    src := src + pad;

  SP_StackPtr^.Str := src;

End;

Procedure SP_Interpret_FN_ITEM(Var Info: pSP_iInfo);
Var
  TempData_Line: TSP_GOSUB_Item;
  TempData_Tokens: paString;
Begin
  TempData_Line.Line := SP_Data_Line.Line;
  TempData_Line.Statement := SP_Data_Line.Statement;
  TempData_Line.St := SP_Data_Line.St;
  TempData_Line.Source := SP_Data_Line.Source;
  TempData_Tokens := SP_Data_Tokens;
  SP_Interpret_READ(Info);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    If SP_StackPtr^.OpType = SP_VALUE Then
      SP_StackPtr^.Val := 1
    Else
      If SP_StackPtr^.OpType = SP_STRING Then Begin
        SP_StackPtr^.OpType := SP_VALUE;
        SP_StackPtr^.Val := 2;
      End;
  End Else
    If Info^.Error^.Code <> SP_ERR_OUT_OF_DATA Then Begin
      Exit;
    End Else Begin
      Inc(SP_StackPtr);
      SP_StackPtr^.OpType := SP_VALUE;
      SP_StackPtr^.Val := 0;
      Info^.Error^.Code := SP_ERR_OK;
    End;
  SP_Data_Line.Line := TempData_Line.Line;
  SP_Data_Line.Statement := TempData_Line.Statement;
  SP_Data_Line.St := TempData_Line.St;
  SP_Data_Line.Source := TempData_Line.Source;
  SP_Data_Tokens := TempData_Tokens;
End;

Procedure SP_Interpret_FN_GPOINT(Var Info: pSP_iInfo);
Var
  R, G, B: aFloat;
Begin

  B := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  G := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  R := SP_StackPtr^.Val;
  SP_StackPtr^.Val := SP_GetGraphicPixel(Round(R), G, B, Info^.Error^);
  If Info^.Error^.Code <> SP_ERR_OK Then
    Dec(SP_StackPtr);
End;

Procedure SP_Interpret_FN_POLARDIST(Var Info: pSP_iInfo);
Var
  dX, dY: aFloat;
Begin

  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  SP_StackPtr^.Val := Sqrt((dx * dx) + (dy * dy));

End;

Procedure SP_Interpret_FN_BITCNT(Var Info: pSP_iInfo);
Var
  v, c: Integer;
Begin

  // Counts the number of set bits in a value

  c := 0;
  v := Round(SP_StackPtr^.Val);
  While v > 0 Do Begin
    Inc(c, v And 1);
    v := v shr 1;
  End;
  SP_StackPtr^.Val := c;

End;

Procedure SP_Interpret_FN_HIBIT(Var Info: pSP_iInfo);
Var
  v, c: Integer;
Begin

  // Returns the highest set bit in a value

  c := 0;
  v := Round(SP_StackPtr^.Val);
  If v = 0 Then
    SP_StackPtr^.Val := -1
  Else
    While v > 0 Do Begin
      if v and 1 = 1 then SP_StackPtr^.Val := c;
      v := v shr 1;
      Inc(c);
    End;

End;

Procedure SP_Interpret_FN_BIT(Var Info: pSP_iInfo);
Var
  Bit: Integer;
Begin

  Bit := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If (Bit > 31) or (Bit < 0) Then Begin
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    Exit;
  End Else
    SP_StackPtr^.Val := (Round(SP_StackPtr^.Val) And (1 Shl Bit)) Shr Bit;

End;

Procedure SP_Interpret_FN_BTSET(Var Info: pSP_iInfo);
Var
  Bit: Integer;
Begin

  Bit := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If (Bit > 31) or (Bit < 0) Then Begin
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    Exit;
  End Else
    SP_StackPtr^.Val := Round(SP_StackPtr^.Val) Or (1 Shl Bit);

End;

Procedure SP_Interpret_FN_BTCLR(Var Info: pSP_iInfo);
Var
  Bit: Integer;
Begin

  Bit := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If (Bit > 31) or (Bit < 0) Then Begin
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    Exit;
  End Else
    SP_StackPtr^.Val := Round(SP_StackPtr^.Val) And ($FFFFFFFF - (1 Shl Bit));

End;

Procedure SP_Interpret_FN_HIWORD(Var Info: pSP_iInfo);
Begin

  SP_StackPtr^.Val := (Round(SP_StackPtr^.Val) Shr 16) And $FFFF;

End;

Procedure SP_Interpret_FN_LOWORD(Var Info: pSP_iInfo);
Begin

  SP_StackPtr^.Val := Round(SP_StackPtr^.Val) And $FFFF;

End;

Procedure SP_Interpret_FN_HIBYTE(Var Info: pSP_iInfo);
Begin

  SP_StackPtr^.Val := (Round(SP_StackPtr^.Val) Shr 8) And $FF;

End;

Procedure SP_Interpret_FN_LOBYTE(Var Info: pSP_iInfo);
Begin

  SP_StackPtr^.Val := Round(SP_StackPtr^.Val) And $FF;

End;

Procedure SP_Interpret_FN_POWERTWO(Var Info: pSP_iInfo);
Var
  {$IF DEFINED(PANDORA) OR DEFINED(RASPI)}
    Dbl: aFloat;
  {$ELSE}
    Dbl: aFloat;
  {$ENDIF}
Begin

  {$IF DEFINED(PANDORA) OR DEFINED(RASPI)}
    Dbl := SP_StackPtr^.Val;
    SP_StackPtr^.Val := Sqr(Dbl);
  {$ELSE}
    Dbl := SP_StackPtr^.Val;
    SP_StackPtr^.Val := Dbl*Dbl;
  {$ENDIF}

End;

Procedure SP_Interpret_FN_LOGTWO(Var Info: pSP_iInfo);
Begin

  SP_StackPtr^.Val := Log2(SP_StackPtr^.Val);

End;

Procedure SP_Interpret_FN_WORDSWAP(Var Info: pSP_iInfo);
Var
  Wd: LongWord;
Begin

  If SP_StackPtr^.Val >= 0 Then Begin
    Wd := Round(SP_StackPtr^.Val);
    SP_StackPtr^.Val := ((Wd And $FFFF) Shl 16) + ((Wd Shr 16) And $FFFF);
  End Else Begin
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
  End;

End;

Procedure SP_Interpret_FN_BYTESWAP(Var Info: pSP_iInfo);
Var
  Wd: Word;
Begin

  If SP_StackPtr^.Val >= 0 Then Begin
    Wd := Round(SP_StackPtr^.Val);
    SP_StackPtr^.Val := ((Wd And $FF) Shl 8) + ((Wd Shr 8) And $FF);
  End Else Begin
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
  End;

End;

Procedure SP_Interpret_FN_NYBBLESWAP(Var Info: pSP_iInfo);
Var
  Bt: Byte;
Begin

  If SP_StackPtr^.Val >= 0 Then Begin
    Bt := Round(SP_StackPtr^.Val);
    SP_StackPtr^.Val := ((Bt And $0F) Shl 4) + ((Bt Shr 4) And $0F);
  End Else Begin
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
  End;

End;

Procedure SP_Interpret_FN_POLAR(Var Info: pSP_iInfo);
Begin

  Dec(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := ArcTan2(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val, Val);
    SP_RadToAngle(Val);
    Case MathMode of
      0: If Val < 0 Then Val := Val + (2 * Pi);
      1: If Val < 0 Then Val := Val + 360;
      2: If Val < 0 Then Val := Val + 1;
      3: If Val < 0 Then Val := Val + 400;
    End;
  End;

End;

Procedure SP_Interpret_FN_CLAMP(Var Info: pSP_iInfo);
Var
  Min, Max, t: aFloat;
Begin

  Max := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Min := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If Max < Min Then Begin
    t := Max; Max := Min; Min := t;
  End;

  If SP_StackPtr^.Val < Min Then
    SP_StackPtr^.Val := Min
  Else
    If SP_StackPtr^.Val > Max Then
      SP_StackPtr^.Val := Max;

End;

Procedure SP_Interpret_FN_INRANGE(Var Info: pSP_iInfo);
Var
  Min, Max, t: aFloat;
Begin

  Max := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Min := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If Max < Min Then Begin
    t := Max; Max := Min; Min := t;
  End;

  If (SP_StackPtr^.Val >= Min) And (SP_StackPtr^.Val <= Max) Then
    SP_StackPtr^.Val := 1
  Else
    SP_StackPtr^.Val := 0;

End;

Procedure SP_Interpret_FN_INSERTS(Var Info: pSP_iInfo);
Var
  src, ins: aString;
  Ps: Integer;
Begin

  Ps := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  ins := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  src := SP_StackPtr^.Str;

  If Ps < 0 then Ps := 0;
  SP_StackPtr^.OpType := SP_STRING;
  If Ps <= Length(Src) Then
    SP_StackPtr^.Str := StringFromPtrB(@Src[1], Ps-1) + ins + StringFromPtrB(@Src[Ps], Length(Src) -Ps +1)
  Else
    SP_StackPtr^.Str := Src + Ins;

End;

Procedure SP_Interpret_FN_ITEMS(Var Info: pSP_iInfo);
Var
  Item, Items, Separator: aString;
  Idx, Cnt: Integer;
  SepValid: Boolean;
Begin

  Separator := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  Cnt := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Items := SP_StackPtr^.Str;
  SepValid := False;

  While Cnt > 0 Do Begin

    Idx := Pos(Separator, Items);
    If Idx = 0 Then Begin
      Dec(SP_StackPtr);
      If Not SepValid Then
        Info^.Error^.Code := SP_ERR_INVALID_SEPARATOR
      Else
        Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
      Exit;
    End Else Begin
      SepValid := True;
      Dec(Cnt);
      Item := Copy(Items, 1, Idx -1);
      Items := Copy(Items, Idx + Length(Separator), Length(Items));
      If Cnt = 1 Then
        If Pos(Separator, Items) = 0 Then Begin
          Item := Items;
          Cnt := 0;
        End;
    End;

  End;

  SP_StackPtr^.OpType := SP_STRING;
  SP_StackPtr^.Str := Item;

End;

Procedure SP_Interpret_FN_GETTILE(Var Info: pSP_iInfo);
Var
  id, x, y: Integer;
Begin

  y := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  x := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Id := Round(SP_StackPtr^.Val);
  SP_StackPtr^.Val := SP_GetTile(id, x, y, Info^.Error^);
  If Info^.Error^.Code <> SP_ERR_OK Then
    Dec(SP_StackPtr);

End;

Procedure SP_Interpret_FN_GRGB(Var Info: pSP_iInfo);
Var
  Val1: Integer;
Begin
  Val1 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := SP_GetGraphicPalette(Round(Val), Val1, Info^.Error^);
    If Info^.Error^.Code <> SP_ERR_OK Then
      Dec(SP_StackPtr);
  End;
End;

Procedure SP_Interpret_FN_GHSV(Var Info: pSP_iInfo);
Var
  R, G, B, H, S, V: aFloat;
  RGB: LongWord;
  Val1: Integer;
Begin
  Val1 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    RGB := SP_GetGraphicPalette(Round(Val), Val1, Info^.Error^);
    If Info^.Error^.Code <> SP_ERR_OK Then Begin
      Dec(SP_StackPtr);
      Exit;
    End;
    R := (RGB Shr 16) And $FF;
    G := (RGB Shr 8) And $FF;
    B := RGB And $FF;
    SP_RGBToHSV(R, G, B, H, S, V);
    Val := (Round(H) Shl 16) + (Round(S) Shl 8) + Round(V);
  End;
End;

Procedure SP_Interpret_FN_WINX(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Val := SP_GetWindowLeft(Round(Val), Info^.Error^);
  End;
End;

Procedure SP_Interpret_FN_WINY(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Val := SP_GetWindowTop(Round(Val), Info^.Error^);
  End;
End;

Procedure SP_Interpret_FN_GFXW(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Val := SP_GetGraphicDetails(Round(Val), Info^.Error^)^.Width;
    If Info^.Error^.Code <> SP_ERR_OK Then
      Dec(SP_StackPtr);
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_GFXH(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Val := SP_GetGraphicDetails(Round(Val), Info^.Error^)^.Height;
    If Info^.Error^.Code <> SP_ERR_OK Then
      Dec(SP_StackPtr);
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_GFXT(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Val := SP_GetGraphicDetails(Round(Val), Info^.Error^)^.Transparent;
    If Info^.Error^.Code <> SP_ERR_OK Then
      Dec(SP_StackPtr);
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_GFXS(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    OpType := SP_String;
    Str := SP_GfxBankToString(Round(SP_StackPtr^.Val), Info^.Error^);
  End;
End;

Procedure SP_Interpret_FN_DATES(Var Info: pSP_iInfo);
Var
  CurTime: TDateTime;
  Idx, Tmp: Integer;
  FormatStr, ResultStr, TmpStr: aString;
Begin

  // Formats a string with the current date depending on the input.
  // Possible inputs:

  // dd - day in numeric format
  // ddd - day in three-letter format
  // d$ - full day of the week
  // e$ - textual numeric day
  // sf - suffix - "st", "nd", "rd", "th" suffix for numeric days
  // mm - month in numeric format
  // mmm - month in three-letter format
  // m$ - full name of the month
  // yy - two-number year
  // yyyy - four-number year
  // y$ - full english year (nineteen seventy-three etc)

  FormatStr := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  ResultStr := '';

  CurTime := SP_StackPtr^.Val;

  Idx := 1;
  While Idx <= Length(FormatStr) Do Begin

    If FormatStr[Idx] = '\' Then Begin
      Inc(Idx);
      ResultStr := ResultStr + FormatStr[Idx];
      Inc(Idx);
    End Else
      If Lower(Copy(FormatStr, Idx, 3)) = 'ddd' Then Begin
        Inc(Idx, 3);
        ResultStr := ResultStr + DayThree[DayOfWeek(CurTime) -2];
      End Else
        If Lower(Copy(FormatStr, Idx, 2)) = 'd$' Then Begin
          Inc(Idx, 2);
          ResultStr := ResultStr + Days[DayOfWeek(CurTime) -2];
        End Else
          If Lower(Copy(FormatStr, Idx, 2)) = 'dd' Then Begin
            Inc(Idx, 2);
            Tmp := GetDay(CurTime);
            If Tmp < 10 Then
              ResultStr := ResultStr + '0' + IntToString(Tmp)
            Else
              ResultStr := ResultStr + IntToString(Tmp);
          End Else
            If Lower(Copy(FormatStr, Idx, 2)) = 'sf' Then Begin
              Inc(Idx, 2);
              Tmp := GetDay(CurTime);
              Case Tmp of
                1, 21, 31:
                  ResultStr := ResultStr + 'st';
                2, 22:
                  ResultStr := ResultStr + 'nd';
                3, 23:
                  ResultStr := ResultStr + 'rd';
                4..20, 24..30:
                  ResultStr := ResultStr + 'th';
              End;
            End Else
              If Lower(Copy(FormatStr, Idx, 2)) = 'e$' Then Begin
                Inc(Idx, 2);
                Tmp := GetDay(CurTime);
                If Tmp in [11..19] Then Begin
                  If Tmp = 12 Then
                    ResultStr := ResultStr + 'twelfth'
                  Else
                    ResultStr := ResultStr + Teens[Tmp - 10] + 'th';
                End Else Begin
                  If Tmp >= 10 Then Begin
                    ResultStr := ResultStr + Tens[Tmp Div 10];
                    If Tmp Mod 10 > 0 Then
                      ResultStr := ResultStr + '-'
                    Else
                      If ResultStr[Length(ResultStr)] = 'y' Then
                        ResultStr := Copy(ResultStr, 1, Length(ResultStr) -1) + 'ie';
                  End;
                  Case Tmp Mod 10 Of
                    0: ResultStr := ResultStr + 'th';
                    1: ResultStr := ResultStr + 'first';
                    2: ResultStr := ResultStr + 'second';
                    3: ResultStr := ResultStr + 'third';
                    4: ResultStr := ResultStr + 'fourth';
                    5: ResultStr := ResultStr + 'fifth';
                    8: ResultStr := ResultStr + 'eighth';
                    6, 7, 9: ResultStr := ResultStr + NumToText(Tmp Mod 10) + 'th';
                  End;
                End;
              End Else
                If Lower(Copy(FormatStr, Idx, 3)) = 'mmm' Then Begin
                  Inc(Idx, 3);
                  ResultStr := ResultStr + MonThree[GetMonth(CurTime) -1];
                End Else
                  If Lower(Copy(FormatStr, Idx, 2)) = 'mm' Then Begin
                    Inc(Idx, 2);
                    Tmp := GetMonth(CurTime);
                    If Tmp < 10 Then ResultStr := ResultStr + '0';
                    ResultStr := ResultStr + IntToString(Tmp);
                  End Else
                    If Lower(Copy(FormatStr, Idx, 2)) = 'm$' Then Begin
                      Inc(Idx, 2);
                      ResultStr := ResultStr + Months[GetMonth(CurTime) -1];
                    End Else
                      If Lower(Copy(FormatStr, Idx, 4)) = 'yyyy' Then Begin
                        Inc(Idx, 4);
                        ResultStr := ResultStr + IntToString(GetYear(CurTime));
                      End Else
                        If Lower(Copy(FormatStr, Idx, 2)) = 'yy' Then Begin
                          Inc(Idx, 2);
                          TmpStr := IntToString(GetYear(CurTime));
                          ResultStr := ResultStr + Copy(TmpStr, Length(TmpStr) -1, 2);
                        End Else
                          If Lower(Copy(FormatStr, Idx, 2)) = 'y$' Then Begin
                            Inc(Idx, 2);
                            Tmp := GetYear(CurTime);
                            If Tmp < 2000 Then Begin
                              ResultStr := ResultStr + NumToText(Tmp Div 100);
                              If Tmp Mod 100 < 20 Then Begin
                                If Tmp Mod 100 = 0 Then
                                  ResultStr := ResultStr + ' hundred'
                                Else
                                  ResultStr := ResultStr + ' oh-' + NumToText(Tmp Mod 10);
                              End Else
                                ResultStr := ResultStr + ' ' + NumToText(Tmp Mod 100);
                            End Else
                              If (Tmp Mod 100) < 10 Then Begin
                                ResultStr := ResultStr + NumToText(Tmp Div 1000) + ' thousand';
                                If (Tmp Mod 100) > 0 Then
                                  ResultStr := ResultStr + ' and ' + NumToText(Tmp Mod 100);
                              End Else
                                ResultStr := ResultStr + NumToText(Tmp Div 100) + ' ' + NumToText(Tmp Mod 100);
                          End Else Begin
                            ResultStr := ResultStr + FormatStr[Idx];
                            Inc(Idx);
                          End;


  End;

  SP_StackPtr^.OpType := SP_STRING;
  SP_StackPtr^.Str := ResultStr;

End;

Procedure SP_Interpret_FN_TIMES(Var Info: pSP_iInfo);
Var
  CurTime: TDateTime;
  Idx, Tmp: Integer;
  FormatStr, ResultStr: aString;
Begin

  // hh - two-number hour (24-hour clock).
  // h - one number hour (12-hour clock), with two if necessary.
  // h$ - full hour name.
  // t$ - hour in text (12 hour clock)
  // mm, m, m$ - as above but for minutes
  // ss, s, s$ - as above but for seconds
  // p$ - AM or PM

  FormatStr := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  ResultStr := '';

  CurTime := SP_StackPtr^.Val;

  Idx := 1;
  While Idx <= Length(FormatStr) Do Begin

    If FormatStr[Idx] = '\' Then Begin
      Inc(Idx);
      ResultStr := ResultStr + FormatStr[Idx];
      Inc(Idx);
    End Else
      If Lower(Copy(FormatStr, Idx, 2)) = 'hh' Then Begin
        Inc(Idx, 2);
        TempStr := IntToString(GetHour(CurTime));
        If Length(TempStr) < 2 Then TempStr := '0' + TempStr;
        ResultStr := ResultStr + TempStr;
      End Else
        If Lower(Copy(FormatStr, Idx, 2)) = 't$' Then Begin
          Inc(Idx, 2);
          Tmp := GetHour(CurTime);
          If Tmp > 12 Then Dec(Tmp, 12);
          If Tmp = 0 Then Tmp := 12;
          ResultStr := ResultStr + NumToText(Tmp);
        End Else
          If Lower(Copy(FormatStr, Idx, 2)) = 'h$' Then Begin
            Inc(Idx, 2);
            ResultStr := ResultStr + NumToText(GetHour(CurTime));
          End Else
            If Lower(Copy(FormatStr, Idx, 1)) = 'h' Then Begin
              Inc(Idx);
              Tmp := GetHour(CurTime);
              If Tmp > 12 Then Dec(Tmp, 12);
              If Tmp = 0 Then Tmp := 12;
              ResultStr := ResultStr + IntToString(Tmp);
            End Else
              If Lower(Copy(FormatStr, Idx, 2)) = 'mm' Then Begin
                Inc(Idx, 2);
                TempStr := IntToString(GetMinute(CurTime));
                If Length(TempStr) < 2 Then TempStr := '0' + TempStr;
                ResultStr := ResultStr + TempStr;
              End Else
                If Lower(Copy(FormatStr, Idx, 2)) = 'm$' Then Begin
                  Inc(Idx, 2);
                  Tmp := GetMinute(CurTime);
                  If Tmp < 10 Then
                    If Tmp = 0 Then
                      ResultStr := ResultStr + 'o'#39'clock'
                    Else
                      ResultStr := ResultStr + 'oh-';
                  If Tmp <> 0 Then
                    ResultStr := ResultStr + NumToText(Tmp);
                End Else
                  If Lower(Copy(FormatStr, Idx, 1)) = 'm' Then Begin
                    Inc(Idx);
                    ResultStr := ResultStr + IntToString(GetMinute(CurTime));
                  End Else
                    If Lower(Copy(FormatStr, Idx, 2)) = 'ss' Then Begin
                      Inc(Idx, 2);
                      TempStr := IntToString(GetSecond(CurTime));
                      If Length(TempStr) < 2 Then TempStr := '0' + TempStr;
                      ResultStr := ResultStr + TempStr;
                    End Else
                      If Lower(Copy(FormatStr, Idx, 2)) = 's$' Then Begin
                        Inc(Idx, 2);
                        ResultStr := ResultStr + NumToText(GetSecond(CurTime));
                      End Else
                        If Lower(Copy(FormatStr, Idx, 1)) = 's' Then Begin
                          Inc(Idx);
                          ResultStr := ResultStr + IntToString(GetSecond(CurTime));
                        End Else
                          If Lower(Copy(FormatStr, Idx, 2)) = 'p$' Then Begin
                            If GetHour(CurTime) >= 12 Then
                              ResultStr := ResultStr + 'PM'
                            Else
                              ResultStr := ResultStr + 'AM';
                            Inc(Idx, 2);
                          End Else Begin
                            ResultStr := ResultStr + FormatStr[Idx];
                            Inc(Idx);
                          End;
  End;

  SP_StackPtr^.OpType := SP_STRING;
  SP_StackPtr^.Str := ResultStr;

End;

Procedure SP_Interpret_FN_TIME(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    OpType := SP_Value;
    Val := Now;
  End;
End;

Procedure SP_Interpret_FN_DAYS(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    OpType := SP_STRING;
    Str := Days[(DayOfWeek(SP_StackPtr^.Val) +5) Mod 7];
  End;
End;

Procedure SP_Interpret_FN_MONTHS(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    OpType := SP_STRING;
    Str := Months[GetMonth(SP_StackPtr^.Val) -1];
  End;
End;

Procedure SP_Interpret_FN_DAY(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := GetDay(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_MONTH(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := GetMonth(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_YEAR(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := GetYear(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_HOUR(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := GetHour(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_MINUTES(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := GetMinute(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_SECONDS(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := GetSecond(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_MILLISECONDS(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := GetMillisecond(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_FRAMES(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  SP_StackPtr^.Val := FRAMES;
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_FN_SPFRADDR(Var Info: pSP_iInfo);
Var
  Val1: Integer;
Begin
  Val1 := Round(SP_StackPtr^.Val) +1;
  Dec(SP_StackPtr);
  SP_StackPtr^.Val := SP_GetFrameAddr(Round(SP_StackPtr^.Val), Val1, Info^.Error^);
  If Info^.Error^.Code <> SP_ERR_OK Then
    Dec(SP_StackPtr);
End;

Procedure SP_Interpret_FN_SPRITEX(Var Info: pSP_iInfo);
Var
  Val1: Integer;
Begin
  Val1 := SP_FindSpriteID(Round(SP_StackPtr^.Val), Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    SP_StackPtr^.Val := pSP_Sprite_Info(@SP_BankList[Val1].Info[0])^.X;
  End Else Begin
    Dec(SP_StackPtr);
  End;
End;

Procedure SP_Interpret_FN_SPRITEY(Var Info: pSP_iInfo);
Var
  Val1: Integer;
Begin
  Val1 := SP_FindSpriteID(Round(SP_StackPtr^.Val), Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    SP_StackPtr^.Val := pSP_Sprite_Info(@SP_BankList[Val1].Info[0])^.Y;
  End Else Begin
    Dec(SP_StackPtr);
  End;
End;

Procedure SP_Interpret_FN_SPRITEW(Var Info: pSP_iInfo);
Var
  Val1, Frame: Integer;
  TokenStart: pByte;
Begin
  Frame := Round(SP_StackPtr^.Val) -1;
  Dec(SP_StackPtr);
  Val1 := SP_FindSpriteID(Round(SP_StackPtr^.Val), Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    GlobSprite := @SP_BankList[Val1].Info[0];
    SP_GetFrameData(GlobSprite, TokenStart, Val1, Frame);
    If TokenStart <> nil Then Begin
      Inc(TokenStart, SizeOf(LongWord));
      SP_StackPtr^.Val := dLongWord(TokenStart);
    End Else Begin
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    End;
  End Else Begin
    Dec(SP_StackPtr);
  End;
End;

Procedure SP_Interpret_FN_SPRITEH(Var Info: pSP_iInfo);
Var
  Val1, Frame: Integer;
  TokenStart: pByte;
Begin
  Frame := Round(SP_StackPtr^.Val) -1;
  Dec(SP_StackPtr);
  Val1 := SP_FindSpriteID(Round(SP_StackPtr^.Val), Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    GlobSprite := @SP_BankList[Val1].Info[0];
    SP_GetFrameData(GlobSprite, TokenStart, Val1, Frame);
    If TokenStart <> Nil Then Begin
      Inc(TokenStart, SizeOf(LongWord) * 2);
      SP_StackPtr^.Val := dLongWord(TokenStart);
    End Else Begin
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    End;
  End Else Begin
    Dec(SP_StackPtr);
  End;
End;

Procedure SP_Interpret_FN_SPVISIBLE(Var Info: pSP_iInfo);
Var
  Val1: Integer;
Begin
  Val1 := SP_FindSpriteID(Round(SP_StackPtr^.Val), Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    SP_StackPtr^.Val := Integer(pSP_Sprite_Info(@SP_BankList[Val1].Info[0])^.Enabled);
  End Else Begin
    Dec(SP_StackPtr);
  End;
End;

Procedure SP_Interpret_FN_SPFCOUNT(Var Info: pSP_iInfo);
Var
  Val1: Integer;
Begin
  Val1 := SP_FindSpriteID(Round(SP_StackPtr^.Val), Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    SP_StackPtr^.Val := pSP_Sprite_Info(@SP_BankList[Val1].Info[0])^.NumFrames;
  End Else Begin
    Dec(SP_StackPtr);
  End;
End;

Procedure SP_Interpret_FN_SPROT(Var Info: pSP_iInfo);
Var
  Val1: Integer;
Begin
  Val1 := SP_FindSpriteID(Round(SP_StackPtr^.Val), Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    SP_StackPtr^.Val := pSP_Sprite_Info(@SP_BankList[Val1].Info[0])^.Angle;
    SP_RadToAngle(SP_StackPtr^.Val);
  End Else Begin
    Dec(SP_StackPtr);
  End;
End;

Procedure SP_Interpret_FN_SPSCALE(Var Info: pSP_iInfo);
Var
  Val1: Integer;
Begin
  Val1 := SP_FindSpriteID(Round(SP_StackPtr^.Val), Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    SP_StackPtr^.Val := pSP_Sprite_Info(@SP_BankList[Val1].Info[0])^.Scale;
  End Else Begin
    Dec(SP_StackPtr);
  End;
End;

Procedure SP_Interpret_FN_CALL(Var Info: pSP_iInfo);
Begin
  If SYSTEMSTATE = SS_EVALUATE Then
    Info^.Error^.Code := SP_ERR_PARAMETER_ERROR
  Else
    SP_Interpret_CALL(Info);
End;

Procedure SP_Interpret_FN_FN(Var Info: pSP_iInfo);
Begin
  SP_Interpret_FN(Info);
End;

Procedure SP_Interpret_FN_GETDIR(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    OpType := SP_STRING;
    If PackageIsOpen Then
      Str := SP_GetPackageDir
    Else
      Str := SP_ConvertHostFilename(aString(GetCurrentDir), Info^.Error^);
  End;
End;

Procedure SP_Interpret_FN_BSIZE(Var Info: pSP_iInfo);
Var
  Val1: Integer;
Begin
  Val1 := Round(SP_StackPtr^.Val);
  SP_StackPtr^.Val := SP_GetBankSize(Val1);
  If SP_StackPtr^.Val = -1 Then
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
End;

Procedure SP_Interpret_FN_SLEN(Var Info: pSP_iInfo);
Var
  Val1: Integer;
Begin
  Val1 := Round(SP_StackPtr^.Val);
  SP_StackPtr^.Val := SP_StreamLen(Val1, Info^.Error^);
  If SP_StackPtr^.Val = -1 Then
    Info^.Error^.Code := SP_ERR_INVALID_STREAM_ID;
End;

Procedure SP_Interpret_FN_SPOS(Var Info: pSP_iInfo);
Var
  Val1: Integer;
Begin
  Val1 := Round(SP_StackPtr^.Val);
  SP_StackPtr^.Val := SP_StreamPos(Val1, Info^.Error^);
  If SP_StackPtr^.Val = -1 Then
    Info^.Error^.Code := SP_ERR_INVALID_STREAM_ID;
End;

Procedure SP_Interpret_FN_FONTBANK(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  SP_StackPtr^.Val := FONTBANKID;
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_FN_FONTWIDTH(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  SP_StackPtr^.Val := FONTWIDTH;
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_FN_FONTHEIGHT(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  SP_StackPtr^.Val := FONTHEIGHT;
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_FN_FONTMODE(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  SP_StackPtr^.Val := FONTTYPE;
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_FN_FONTTRANSPARENT(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  SP_StackPtr^.Val := FONTTRANSPARENT;
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_FN_LASTK(Var Info: pSP_iInfo);
var
  l: Integer;
Begin
  Inc(SP_StackPtr);
  l := Length(ActiveKeys);
  If l > 0 Then
    SP_StackPtr^.Val := ActiveKeys[l-1].KeyCode
  Else
    SP_StackPtr^.Val := 0;
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_FN_RADTODEG(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := RadToDeg(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_DEGTORAD(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := DegToRad(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_ERROR_NUM(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    OpType := SP_VALUE;
    Val := LASTERROR;
  End;
End;

Procedure SP_Interpret_FN_ERRORS(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    OpType := SP_STRING;
    Str := ProcessErrorMessage(ErrorMessages[LASTERROR]);
  End;
End;

Procedure SP_Interpret_FN_ERROR_LIN(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    OpType := SP_VALUE;
    Val := LASTERRORLINE;
  End;
End;

Procedure SP_Interpret_FN_ERROR_STA(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    OpType := SP_VALUE;
    Val := LASTERRORSTATEMENT;
  End;
End;

Procedure SP_Interpret_FN_MOUSEX(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := SP_ConvertToScreenX(MOUSEX - SCREENX);
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_MOUSEWHEEL(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := MOUSEWHEEL;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_DRPOSX(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := SP_ConvertToScreenX(Round(DRPOSX));
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_DRPOSY(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := SP_ConvertToScreenY(Round(DRPOSY));
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_MOUSEY(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := SP_ConvertToScreenY(MOUSEY - SCREENY);
    If WINFLIPPED Then
      Val := (SCREENHEIGHT - 1) - Val;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_MOUSEDX(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := M_DELTAX;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_MOUSEDY(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := M_DELTAY;
    If WINFLIPPED Then
      Val := -Val;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_MOUSEBTN(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := MOUSEBTN;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_STK(Var Info: pSP_iInfo);
Var
  v: aFloat;
Begin
  v := SP_StackPtr^.Val;
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := v;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_STKS(Var Info: pSP_iInfo);
Var
  s: aString;
Begin
  s := SP_StackPtr^.Str;
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Str := s;
    OpType := SP_STRING;
  End;
End;

Procedure SP_Interpret_FN_CLIPS(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Try
      Str := aString(ClipBoard.AsText);
    Except
      Info^.Error^.Code := SP_ERR_CLIPBOARD_ERROR;
    End;
    opType := SP_STRING;
  End;
End;

Procedure SP_Interpret_FN_RND(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    if SYSTEMSTATE = SS_EVALUATE Then
      Val := LastRand
    Else Begin
      Val := Random;
      LastRand := Val;
    End;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_INKEYS(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  // Important - yield CPU if necessary to ensure that
  // keyboard messages are processed
  If FRAMES <> LASTINKEYFRAME Then CB_YIELD;
  // Now get the keyboard state
  With SP_StackPtr^ Do Begin
    Str := GetLastKeyChar;
    If KEYSTATE[K_ESCAPE] = 1 Then BreakSignal := True;
    OpType := SP_STRING;
  End;
End;

Procedure SP_Interpret_FN_KEY(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := KEYSTATE[Round(SP_StackPtr^.Val)];
End;

Procedure SP_Interpret_FN_PI(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := Pi;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_TAU(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := Pi * 2;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_HEADING(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := DRHEADING;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_POINT(Var Info: pSP_iInfo);
Var
  YCoord, XCoord: Integer;
  dX, dY: aFloat;
Begin
  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  SP_ConvertToOrigin_d(dX, dY);
  XCoord := Round(dX); YCoord := Round(dY);
  If WINFLIPPED Then
    YCoord := (SCREENHEIGHT - 1) - YCoord;

  If (XCoord >= 0) and (XCoord < SCREENWIDTH) And (YCoord >= 0) And (YCoord < SCREENHEIGHT) Then Begin
    If SCREENBPP = 8 Then
      SP_StackPtr^.Val := pByte(NativeInt(SCREENPOINTER) + ((YCoord * SCREENSTRIDE) + XCoord))^
    Else
      SP_StackPtr^.Val := pLongWord(NativeInt(SCREENPOINTER) + ((YCoord * SCREENSTRIDE) + (XCoord * SizeOf(RGBA))))^;
  End Else Begin
    SP_StackPtr^.Val := -1;
  End;
End;

Procedure SP_Interpret_FN_VALS(Var Info: pSP_iInfo);
Var
  ValPosition: Integer;
  ValTkn: paString;
Begin

  ValPosition := 1;
  If SP_StackPtr^.Str[1] = #$F Then
    ValTokens := Copy(SP_StackPtr^.Str, 2, Length(SP_StackPtr^.Str))
  Else Begin
    Str1 := SP_TokeniseLine(SP_StackPtr^.Str, True, False) + #255;
    ValTokens := SP_Convert_Expr(Str1, ValPosition, Info^.Error^, -1) + #255;
    SP_RemoveBlocks(ValTokens);
    SP_TestConsts(ValTokens, 1, Info^.Error^, False);
    SP_AddHandlers(ValTokens);
  End;
  Dec(SP_StackPtr);
  If ValTokens = #255 Then Begin
    Info^.Error^.Code := SP_ERR_SYNTAX_ERROR;
    Exit;
  End;
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    ValPosition := 1;
    ValTkn := @ValTokens;
    SP_InterpretCONTSafe(ValTkn, ValPosition, Info^.Error^);
    If Info^.Error^.Code = SP_ERR_OK Then Begin
      With SP_StackPtr^ Do
        If OpType = SP_VALUE Then Begin
          Str := aString(aFloatToStr(Val));
          OpType := SP_STRING;
        End;
    End Else Begin
      Exit;
    End;
  End;
End;

Procedure SP_Interpret_FN_UPS(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Str := Upper(SP_StackPtr^.Str);
End;

Procedure SP_Interpret_FN_LOWS(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Str := Lower(SP_StackPtr^.Str);
End;

Procedure SP_Interpret_FN_LEFTS(Var Info: pSP_iInfo);
Begin
  Dec(SP_StackPtr);
  SP_StackPtr^.Str := Copy(SP_StackPtr^.Str, 1, Round(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val));
End;

Procedure SP_Interpret_FN_WINOFF(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := 0;
End;

Procedure SP_Interpret_FN_MIDS(Var Info: pSP_iInfo);
Var
  S, L: Integer;
Begin
  L := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  S := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  SP_StackPtr^.Str := SP_Copy(SP_StackPtr^.Str, S, L);
End;

Procedure SP_Interpret_FN_MID(Var Info: pSP_iInfo);
Var
  A, B, C: aFloat;
Begin
  A := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  B := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  C := SP_StackPtr^.Val;
  SP_StackPtr^.Val := Max(Min(A,B), Min(Max(A,B),C));
End;

Procedure SP_Interpret_FN_RIGHTS(Var Info: pSP_iInfo);
Var
  L: Integer;
Begin
  L := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  SP_StackPtr^.Str := Copy(SP_StackPtr^.Str, Length(SP_StackPtr^.Str) - L + 1, L);
End;

Procedure SP_Interpret_FN_REPS(Var Info: pSP_iInfo);
Var
  Val1: Integer;
Begin
  Dec(SP_StackPtr);
  Str1 := SP_StackPtr^.Str;
  Val1 := Round(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val);
  SP_StackPtr^.Str := '';
  While Val1 > 0 Do Begin SP_StackPtr^.Str := SP_StackPtr^.Str + Str1;
    Dec(Val1);
  End;
End;

Procedure SP_Interpret_FN_CODE(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    If Str = '' Then
      Val := 0
    Else
      Val := Ord(Str[1]);
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_DCODE(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    If Str = '' Then
      Val := 0
    Else Begin
      If Length(Str) = 1 Then
        Str := aChar(0) + Str;
      Val := pWord(@Str[1])^;
    End;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_QCODE(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    If Str = '' Then
      Val := 0
    Else Begin
      While Length(Str) < 4 Do
        Str := aChar(0) + Str;
      Val := dLongWord(@Str[1]);
    End;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_FCODE(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    If Str = '' Then
      Val := 0
    Else Begin
      While Length(Str) < 8 Do
        Str := aChar(0) + Str;
      Val := gaFloat(@Str[1]);
    End;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_VAL(Var Info: pSP_iInfo);
Var
  ValPosition: Integer;
  ValTkn: paString;
Label
  RunIt;
Begin
  If SP_StackPtr^.Str <> '' Then Begin
    ValPosition := 1;
    If SP_StackPtr^.Str[1] = #$F Then Begin
      ValTokens := Copy(SP_StackPtr^.Str, 2, Length(SP_StackPtr^.Str));
      Goto RunIt;
    End Else Begin
      Str1 := SP_TokeniseLine(SP_StackPtr^.Str, True, False) + #255;
      ValTokens := SP_Convert_Expr(Str1, ValPosition, Info^.Error^, -1) + #255;
      SP_RemoveBlocks(ValTokens);
      SP_TestConsts(ValTokens, 1, Info^.Error^, False);
      SP_AddHandlers(ValTokens);
    End;
  End Else Begin
    ValTokens := CreateToken(SP_VALUE, 0, SizeOf(aFloat)) + aFloatToString(0) + #255;
    SP_AddHandlers(ValTokens);
  End;
  If ValTokens = #255 Then Begin
    Info^.Error^.Code := SP_ERR_SYNTAX_ERROR;
    Exit;
  End;
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    RunIt:
    Dec(SP_StackPtr);
    ValPosition := 1;
    ValTkn := @ValTokens;
    SP_InterpretCONTSafe(ValTkn, ValPosition, Info^.Error^);
  End;
End;

Procedure SP_Interpret_FN_LEN(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Val := Length(Str);
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_SIN(Var Info: pSP_iInfo);
Begin
  SP_AngleToRad(SP_StackPtr^.Val);
  SP_StackPtr^.Val := Sin(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_COS(Var Info: pSP_iInfo);
Begin
  SP_AngleToRad(SP_StackPtr^.Val);
  SP_StackPtr^.Val := Cos(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_TAN(Var Info: pSP_iInfo);
Begin
  SP_AngleToRad(SP_StackPtr^.Val);
  SP_StackPtr^.Val := Tan(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_ASN(Var Info: pSP_iInfo);
Var
  Val: aFloat;
Begin
  Val := SP_StackPtr^.Val;
  If (Val >= -1) And (Val <= 1) Then Begin
    SP_AngleToRad(Val);
    SP_StackPtr^.Val := ArcSin(Val);
  End Else Begin
    Info^.Error^.Code := SP_ERR_INVALID_ARGUMENT;
  End;
End;

Procedure SP_Interpret_FN_ACS(Var Info: pSP_iInfo);
Var
  Val: aFloat;
Begin
  Val := SP_StackPtr^.Val;
  If (Val >= -1) And (Val <= 1) Then Begin
    SP_AngleToRad(Val);
    SP_StackPtr^.Val := ArcCos(Val);
  End Else Begin
    Info^.Error^.Code := SP_ERR_INVALID_ARGUMENT;
  End;
End;

Procedure SP_Interpret_FN_ATN(Var Info: pSP_iInfo);
Var
  Val: aFloat;
Begin
  Val := SP_StackPtr^.Val;
  SP_AngleToRad(Val);
  SP_StackPtr^.Val := ArcTan(Val)
End;

Procedure SP_Interpret_FN_SINH(Var Info: pSP_iInfo);
Begin
  SP_AngleToRad(SP_StackPtr^.Val);
  SP_StackPtr^.Val := Sinh(SP_StackPtr^.Val)
End;

Procedure SP_Interpret_FN_COSH(Var Info: pSP_iInfo);
Begin
  SP_AngleToRad(SP_StackPtr^.Val);
  SP_StackPtr^.Val := Cosh(SP_StackPtr^.Val)
End;

Procedure SP_Interpret_FN_TANH(Var Info: pSP_iInfo);
Begin
  SP_AngleToRad(SP_StackPtr^.Val);
  SP_StackPtr^.Val := Tanh(SP_StackPtr^.Val)
End;

Procedure SP_Interpret_FN_ASNH(Var Info: pSP_iInfo);
Begin
  SP_AngleToRad(SP_StackPtr^.Val);
  SP_StackPtr^.Val := ArcSinh(SP_StackPtr^.Val)
End;

Procedure SP_Interpret_FN_ACSH(Var Info: pSP_iInfo);
Begin
  If SP_StackPtr^.Val >= 1 Then Begin
    SP_AngleToRad(SP_StackPtr^.Val);
    SP_StackPtr^.Val := ArcCosh(SP_StackPtr^.Val)
  End Else
    Info^.Error.Code := SP_ERR_INVALID_ARGUMENT;
End;

Procedure SP_Interpret_FN_ATNH(Var Info: pSP_iInfo);
Begin
  If SP_StackPtr^.Val >= -1 Then Begin
    SP_AngleToRad(SP_StackPtr^.Val);
    SP_StackPtr^.Val := ArcTanh(SP_StackPtr^.Val)
  End Else
    Info^.Error.Code := SP_ERR_INVALID_ARGUMENT;
End;

Procedure SP_Interpret_FN_LN(Var Info: pSP_iInfo);
Begin
  If SP_StackPtr^.Val > 0 Then
    SP_StackPtr^.Val := Ln(SP_StackPtr^.Val)
  Else Begin
    Info^.Error^.Code := SP_ERR_INVALID_ARGUMENT;
  End;
End;

Procedure SP_Interpret_FN_EXP(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := Exp(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_INT(Var Info: pSP_iInfo);
Var
  v: aFloat;
Begin
  v := SP_StackPtr^.Val;
  SP_StackPtr^.Val := Int(v - Ord(v < 0)); // Sinclair BASIC compatible - round towards negative infinity
End;

Procedure SP_Interpret_FN_SQR(Var Info: pSP_iInfo);
Begin
  If SP_StackPtr^.Val >= 0 Then
    SP_StackPtr^.Val := Sqrt(SP_StackPtr^.Val)
  Else Begin
    Info^.Error^.Code := SP_ERR_INVALID_ARGUMENT;
  End;
End;

Procedure SP_Interpret_FN_SGN(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := Sign(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_ABS(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := Abs(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_USR(Var Info: pSP_iInfo);
Begin
  Info^.Error^.Code := SP_ERR_OK;
End;

Procedure SP_Interpret_FN_STRS(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Str := aString(aFloatToStr(Val));
    OpType := SP_STRING;
  End;
End;

Procedure SP_Interpret_FN_CHRS(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Str := aChar(Round(Val) And 255);
    OpType := SP_STRING;
  End;
End;

Procedure SP_Interpret_FN_DCHRS(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Str := WordToString(Word(Round(Val)) And 65535);
    OpType := SP_STRING;
  End;
End;

Procedure SP_Interpret_FN_QCHRS(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Str := LongWordToString(LongWord(Round(Val)) And $FFFFFFFF);
    OpType := SP_STRING;
  End;
End;

Procedure SP_Interpret_FN_FCHRS(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Str := aFloatToString(Val);
    OpType := SP_STRING;
  End;
End;

Procedure SP_Interpret_FN_PARAMS(Var Info: pSP_iInfo);
var
  Idx: Integer;
Begin
  With SP_StackPtr^ Do Begin
    Idx := Round(Val);
    OpType := SP_STRING;
    If (Idx < PARAMS.Count) and (Idx >= 0) then
      Str := PARAMS[Idx]
    else
      Str := '';
  End;
End;

Procedure SP_Interpret_FN_POWER(Var Info: pSP_iInfo);
Var
  R, G: aFloat;
Begin
  R := SP_StackPtr^.Val; // Power
  Dec(SP_StackPtr);
  G := SP_StackPtr^.Val; // Base
  SP_StackPtr^.Val := SP_Power(G, R);
End;

Procedure SP_Interpret_FN_PEEK(Var Info: pSP_iInfo);
Var
  Offset, BankIdx: Integer;
  Bank: pSP_Bank;
Begin
  Offset := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  BankIdx := SP_FindBankID(Round(SP_StackPtr^.Val));
  If BankIdx > -1 Then Begin
    Bank := SP_BankList[BankIdx];
    If (Offset >= 0) And (Offset < Length(Bank^.Memory)) Then
      SP_StackPtr^.Val := Bank^.Memory[Offset]
    Else
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
End;

Procedure SP_Interpret_FN_PEEKS(Var Info: pSP_iInfo);
Var
  Val1, Offset, BankIdx: Integer;
  Bank: pSP_Bank;
Begin
  Val1 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Offset := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  BankIdx := SP_FindBankID(Round(SP_StackPtr^.Val));
  If BankIdx > -1 Then Begin
    Bank := SP_BankList[BankIdx];
    TempStr := '';
    If (Offset >= 0) And (Offset < Length(Bank^.Memory)) Then Begin
      If Offset + Val1 > Length(Bank^.Memory) Then
        Val1 := (Length(Bank^.Memory) - Offset) +1;
      With SP_StackPtr^ Do Begin
        SetLength(Str, Val1);
        CopyMem(@Str[1], @Bank^.Memory[Offset], Val1);
        OpType := SP_STRING;
      End;
    End Else
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
End;

Procedure SP_Interpret_FN_DPEEK(Var Info: pSP_iInfo);
Var
  Offset, BankIdx: Integer;
  Bank: pSP_Bank;
Begin
  Offset := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  BankIdx := SP_FindBankID(Round(SP_StackPtr^.Val));
  If BankIdx > -1 Then Begin
    Bank := SP_BankList[BankIdx];
    If (Offset >= 0) And (Offset < Length(Bank^.Memory) - 1) Then
      SP_StackPtr^.Val := pWord(@Bank^.Memory[Offset])^
    Else
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
End;

Procedure SP_Interpret_FN_QPEEK(Var Info: pSP_iInfo);
Var
  Offset, BankIdx: Integer;
  Bank: pSP_Bank;
Begin
  Offset := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  BankIdx := SP_FindBankID(Round(SP_StackPtr^.Val));
  If BankIdx > -1 Then Begin
    Bank := SP_BankList[BankIdx];
    If (Offset >= 0) And (Offset < Length(Bank^.Memory) - 3) Then
      SP_StackPtr^.Val := dLongWord(@Bank^.Memory[Offset])
    Else
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
End;

Procedure SP_Interpret_FN_FPEEK(Var Info: pSP_iInfo);
Var
  Offset, BankIDX: Integer;
  Bank: pSP_Bank;
Begin
  Offset := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  BankIdx := SP_FindBankID(Round(SP_StackPtr^.Val));
  If BankIdx > -1 Then Begin
    Bank := SP_BankList[BankIdx];
    If (Offset >= 0) And (Offset < Length(Bank^.Memory) - 7) Then
      SP_StackPtr^.Val := gaFloat(@Bank^.Memory[Offset])
    Else
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
End;

Procedure SP_Interpret_FN_NOT(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    If Val = 0 Then
      Val := 1
    Else
      Val := 0;
  End;
End;

Procedure SP_Interpret_FN_FRAC(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := Frac(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_CEIL(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := Ceil(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_FLOOR(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := Floor(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_MAX(Var Info: pSP_iInfo);
Var
  Val1, Val2: aFloat;
Begin
  Val1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Val2 := SP_StackPtr^.Val;
  SP_StackPtr^.Val := Max(Val1, Val2);
End;

Procedure SP_Interpret_FN_MIN(Var Info: pSP_iInfo);
Var
  Val1, Val2: aFloat;
Begin
  Val1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Val2 := SP_StackPtr^.Val;
  SP_StackPtr^.Val := Min(Val1, Val2);
End;

Procedure SP_Interpret_FN_MAXS(Var Info: pSP_iInfo);
Var
  Str1, Str2: aString;
Begin
  Str1 := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  Str2 := SP_StackPtr^.Str;
  If Str1 > Str2 Then
    SP_StackPtr^.Str := Str1
  Else
    SP_StackPtr^.Str := Str2;
End;

Procedure SP_Interpret_FN_MINS(Var Info: pSP_iInfo);
Var
  Str1, Str2: aString;
Begin
  Str1 := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  Str2 := SP_StackPtr^.Str;
  If Str1 > Str2 Then
    SP_StackPtr^.Str := Str2
  Else
    SP_StackPtr^.Str := Str1;
End;

Procedure SP_Interpret_FN_ROUND(Var Info: pSP_iInfo);
Var
  Val2: Integer;
  aFloat1: aFloat;
Begin
  Val2 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  aFloat1 := SP_StackPtr^.Val;
  If (Val2 >= -37) and (Val2 < 38) Then Begin
    SP_StackPtr^.Val := RoundTo(aFloat1, Val2);
  End Else Begin
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
  End;
End;

Procedure SP_Interpret_FN_CHPOS(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := SP_GetChannelPos(Round(SP_StackPtr^.Val), Info^.Error^);
End;

Procedure SP_Interpret_FN_ODD(Var Info: pSP_iInfo);
Begin
  If Odd(Round(SP_StackPtr^.Val)) Then
    SP_StackPtr^.Val := 1
  Else
    SP_StackPtr^.Val := 0;
End;

Procedure SP_Interpret_FN_EVEN(Var Info: pSP_iInfo);
Begin
  If Not Odd(Round(SP_StackPtr^.Val)) Then
    SP_StackPtr^.Val := 1
  Else
    SP_StackPtr^.Val := 0;
End;

Procedure SP_Interpret_FN_POS(Var Info: pSP_iInfo);
Begin
  Str1 := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  Str2 := SP_StackPtr^.Str;
  SP_StackPtr^.Val := Pos(Str2, Str1);
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_FN_POSN(Var Info: pSP_iInfo);
Var
  Ps, Pn: Integer;
Begin
  Ps := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Str1 := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  Str2 := SP_StackPtr^.Str;
  Pn := Pos(Str2, Str1, Ps);
  If Pn > 0 then SP_StackPtr^.Val := Pn + Ps -1 Else SP_StackPtr^.Val := 0;
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_FN_INSTR(Var Info: pSP_iInfo);
Begin
  Str1 := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  Str2 := SP_StackPtr^.Str;
  SP_StackPtr^.Val := Pos(Str1, Str2);
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_FN_INSTRN(Var Info: pSP_iInfo);
Var
  Ps, Pn: Integer;
Begin
  Ps := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Str1 := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  Str2 := SP_StackPtr^.Str;
  Pn := Pos(Str1, Str2, Ps);
  If Pn > 0 then SP_StackPtr^.Val := Pn + Ps -1 Else SP_StackPtr^.Val := 0;
  SP_StackPtr^.OpType := SP_VALUE;
End;

Procedure SP_Interpret_FN_TRUNC(Var Info: pSP_iInfo);
Begin
  SP_StackPtr^.Val := Trunc(SP_StackPtr^.Val);
End;

Procedure SP_Interpret_FN_RED(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Val := (Round(Val) Shr 16) And $FF;
  End;
End;

Procedure SP_Interpret_FN_GREEN(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Val := (Round(Val) Shr 8) And $FF;
  End;
End;

Procedure SP_Interpret_FN_BLUE(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Val := Round(Val) And $FF;
  End;
End;

Procedure SP_Interpret_FN_RGB(Var Info: pSP_iInfo);
Var
  RGB: LongWord;
Begin
  With SP_StackPtr^ Do Begin
    RGB := SP_GetPalette(Round(Val));
    Val := ((RGB And $FF) Shl 24) + (RGB Shr 8);
  End;
End;

Procedure SP_Interpret_FN_HEXS(Var Info: pSP_iInfo);
Var
  Val1: aFloat;
Begin
  With SP_StackPtr^ Do Begin
    Val1 := Round(Val);
    If Val1 = 0 Then
      Str := '0'
    Else Begin
      if Val1 < 0 Then
        Str := '-'
      else
        Str := '';
      While Val1 > 0 Do Begin
        Str := aString('0123456789ABCDEF')[(Round(Val1) And $F) + 1] + Str;
        Val1 := Round(Val1) Shr 4;
      End;
    End;
    OpType := SP_STRING;
  End;
End;

Procedure SP_Interpret_FN_BINS(Var Info: pSP_iInfo);
Var
  Val1: aFloat;
Begin
  With SP_StackPtr^ Do Begin
    Val1 := Round(Val);
    If Val1 = 0 Then
      Str := '0'
    Else Begin
      if Val1 < 0 Then
        Str := '-'
      else
        Str := '';
      While Val1 > 0 Do Begin
        Str := aString('01')[(Round(Val1) And 1) + 1] + Str;
        Val1 := Round(Val1) Shr 1;
      End;
    End;
    OpType := SP_STRING;
  End;
End;

Procedure SP_Interpret_FN_WINW(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Val := SP_GetWindowWidth(Round(Val), Info^.Error^);
  End;
End;

Procedure SP_Interpret_FN_WINH(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Val := SP_GetWindowHeight(Round(Val), Info^.Error^);
  End;
End;

Procedure SP_Interpret_FN_SCRW(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := SCREENWIDTH;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_SCRH(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := SCREENHEIGHT;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_TXTW(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := Round(SCREENWIDTH/(FONTWIDTH * T_SCALEX));
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_TXTH(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := Round(SCREENHEIGHT/(FONTHEIGHT * T_SCALEY));
    OpType := SP_VALUE;
  End;
End;


Procedure SP_Interpret_FN_CWIN(Var Info: pSP_iInfo);
Begin
  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    Val := SCREENBANK;
    OpType := SP_VALUE;
  End;
End;

Procedure SP_Interpret_FN_RGBF(Var Info: pSP_iInfo);
Var
  R, G, B: Byte;
Begin
  B := Round(SP_StackPtr^.Val) And $FF;
  Dec(SP_StackPtr);
  G := Round(SP_StackPtr^.Val) And $FF;
  Dec(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    R := Round(Val) And $FF;
    Val := SP_Get_Opposite_Colour(R, G, B);
  End;
End;

Procedure SP_Interpret_FN_RGBN(Var Info: pSP_iInfo);
Var
  R, G, B: Byte;
Begin
  B := Round(SP_StackPtr^.Val) And $FF;
  Dec(SP_StackPtr);
  G := Round(SP_StackPtr^.Val) And $FF;
  Dec(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    R := Round(Val) And $FF;
    Val := SP_Get_Nearest_Colour(R, G, B, -1);
  End;
End;

Procedure SP_Interpret_FN_RGBC(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    Val := SP_Get_Contrasting_Ink(Round(Val));
  End;
End;

Procedure SP_Interpret_FN_iRGBF(Var Info: pSP_iInfo);
Var
  RGB: LongWord;
Begin
  With SP_StackPtr^ Do Begin
    RGB := Round(Val);
    Val := SP_Get_Opposite_Colour((RGB Shr 16) And $FF, (RGB Shr 8) And $FF, RGB And $FF);
  End;
End;

Procedure SP_Interpret_FN_iRGBN(Var Info: pSP_iInfo);
Var
  RGB: LongWord;
Begin
  With SP_StackPtr^ Do Begin
    RGB := Round(Val);
    Val := SP_Get_Nearest_Colour((RGB Shr 16) And $FF, (RGB Shr 8) And $FF, RGB And $FF, -1);
  End;
End;

Procedure SP_Interpret_FN_HSV(Var Info: pSP_iInfo);
Var
  RGB: LongWord;
  R, G, B, H, S, V: aFloat;
Begin
  With SP_StackPtr^ Do Begin
    RGB := SP_GetPalette(Round(Val));
    R := (RGB Shr 24) And $FF;
    G := (RGB Shr 16) And $FF;
    B := (RGB Shr 8) And $FF;
    SP_RGBToHSV(R, G, B, H, S, V);
    Val := (Round(H) Shl 16) + (Round(S) Shl 8) + Round(V);
  End;
End;

Procedure SP_Interpret_FN_HUE(Var Info: pSP_iInfo);
Var
  RGB: LongWord;
  R, G, B, H, S, V: aFloat;
Begin
  With SP_StackPtr^ Do Begin
    RGB := Round(Val);
    R := (RGB Shr 16) And $FF;
    G := (RGB Shr 8) And $FF;
    B := RGB And $FF;
    SP_RGBToHSV(R, G, B, H, S, V);
    Val := H;
  End;
End;

Procedure SP_Interpret_FN_SAT(Var Info: pSP_iInfo);
Var
  RGB: LongWord;
  R, G, B, H, S, V: aFloat;
Begin
  With SP_StackPtr^ Do Begin
    RGB := Round(Val);
    R := (RGB Shr 16) And $FF;
    G := (RGB Shr 8) And $FF;
    B := RGB And $FF;
    SP_RGBToHSV(R, G, B, H, S, V);
    Val := S;
  End;
End;

Procedure SP_Interpret_FN_VALUE(Var Info: pSP_iInfo);
Var
  RGB: LongWord;
  R, G, B, H, S, V: aFloat;
Begin
  With SP_StackPtr^ Do Begin
    RGB := Round(Val);
    R := (RGB Shr 16) And $FF;
    G := (RGB Shr 8) And $FF;
    B := RGB And $FF;
    SP_RGBToHSV(R, G, B, H, S, V);
    Val := V;
  End;
End;

Procedure SP_Interpret_FN_NOISE(Var Info: pSP_iInfo);
Var
  x, y, z: aFloat;
Begin
  z := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  x := SP_StackPtr^.Val;
  SP_StackPtr^.Val := Perlin(x, y, z);
End;

Procedure SP_Interpret_FN_NOISEOCT(Var Info: pSP_iInfo);
Var
  x, y, z, o, p: aFloat;
Begin
  p := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  o := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  z := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  x := SP_StackPtr^.Val;
  SP_StackPtr^.Val := OctavePerlin(x, y, z, Round(o), p);
End;

Procedure SP_Interpret_FN_MAP(Var Info: pSP_iInfo);
Var
  Val, rMin, rMax, mMin, mMax: aFloat;
Begin
  mMax := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  mMin := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  rMax := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  rMin := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Val := SP_StackPtr^.Val;
  SP_StackPtr^.Val := (((Val - rMin) / (rMax - rMin)) * (mMax - mMin)) + mMin;
End;

Procedure SP_Interpret_FN_RGBtoINT(Var Info: pSP_iInfo);
Var
  R, G, B: aFloat;
Begin
  B := Min(255, Max(0, SP_StackPtr^.Val));
  Dec(SP_StackPtr);
  G := Min(255, Max(0, SP_StackPtr^.Val));
  Dec(SP_StackPtr);
  R := Min(255, Max(0, SP_StackPtr^.Val));
  SP_StackPtr^.Val := (Round(R) Shl 16) + (Round(G) Shl 8) + Round(B);
End;

Procedure SP_Interpret_FN_HSVtoINT(Var Info: pSP_iInfo);
Var
  H, S, V: aFloat;
Begin
  V := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  S := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  H := SP_StackPtr^.Val;
  SP_StackPtr^.Val := (Round(H) Shl 16) + (Round(S) Shl 8) + Round(V);
End;

Procedure SP_Interpret_FN_RGBToHSV(Var Info: pSP_iInfo);
Var
  R, G, B, H, S, V: aFloat;
Begin

  B := Round(SP_StackPtr^.Val) And $FF;
  Dec(SP_StackPtr);
  G := Round(SP_StackPtr^.Val) And $FF;
  Dec(SP_StackPtr);
  R := Round(SP_StackPtr^.Val) And $FF;

  SP_RGBToHSV(R, G, B, H, S, V);
  SP_StackPtr^.Val := (Round(H) Shl 16) + (Round(S) Shl 8) + Round(V);

End;

Procedure SP_Interpret_FN_iRGBToHSV(Var Info: pSP_iInfo);
Var
  R, G, B, H, S, V: aFloat;
Begin
  With SP_StackPtr^ Do Begin
    R := (Round(Val) Shr 16) And $FF;
    G := (Round(Val) Shr 8) And $FF;
    B := Round(Val) And $FF;
    SP_RGBToHSV(R, G, B, H, S, V);
    Val := (Round(H) Shl 16) + (Round(S) Shl 8) + Round(V);
  End;
End;

Procedure SP_Interpret_FN_HSVtoRGB(Var Info: pSP_iInfo);
Var
  R, G, B, H, S, V: aFloat;
Begin

  V := Round(SP_StackPtr^.Val) And $FF;
  Dec(SP_StackPtr);
  S := Round(SP_StackPtr^.Val) And $FF;
  Dec(SP_StackPtr);
  H := Round(SP_StackPtr^.Val);

  SP_HSVToRGB(H, S, V, R, G, B);
  SP_StackPtr^.Val := (Round(R) Shl 16) + (Round(G) Shl 8) + Round(B);

End;

Procedure SP_Interpret_FN_iHSVtoRGB(Var Info: pSP_iInfo);
Var
  R, G, B, H, S, V: aFloat;
Begin
  With SP_StackPtr^ Do Begin
    H := (Round(Val) Shr 16);
    S := (Round(Val) Shr 8) And $FF;
    V := Round(Val) And $FF;
    SP_HSVToRGB(H, S, V, R, G, B);
    Val := (Round(R) Shl 16) + (Round(G) Shl 8) + Round(B);
  End;
End;

Procedure SP_Interpret_FN_TRIMS(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    While (Str <> '') And (Str[1] <= ' ') Do
      Str := Copy(Str, 2, Length(Str));
    While (Str <> '') And (Str[Length(Str)] <= ' ') Do
      Str := Copy(Str, 1, Length(Str) - 1);
  End;
End;

Procedure SP_Interpret_FN_LTRIMS(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    While (Str <> '') And (Str[1] <= ' ') Do
      Str := Copy(Str, 2, Length(Str));
  End;
End;

Procedure SP_Interpret_FN_RTRIMS(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    While (Str <> '') And (Str[Length(Str)] <= ' ') Do
      Str := Copy(Str, 1, Length(Str) - 1);
  End;
End;

Function SP_ConvertToTokens(Const s: aString; Var Error: TSP_ErrorCode): aString;
Var
  info: TSP_iInfo;
  iInfo: pSP_iInfo;
Begin
  Inc(SP_StackPtr);
  SP_StackPtr^.Str := s;
  iInfo := @info;
  SP_Interpret_FN_TOKENS(iInfo);
  Error.Code := Info.Error.Code;
  If Error.Code = SP_ERR_OK Then
    Result := SP_StackPtr^.Str
  Else
    Result := '';
  Dec(SP_StackPtr);
End;

Procedure SP_Interpret_FN_TOKENS(Var Info: pSP_iInfo);
Var
  KeyWordID: Integer;
  nError: TSP_ErrorCode;
Begin
  With Info^ Do Begin
    With SP_StackPtr^ Do Begin
      nError.Position := 1;
      nError.Code := SP_ERR_OK;
      If Str <> '' Then Begin
        Str := SP_TokeniseLine(Str, False, False) + SP_TERMINAL_SEQUENCE;
        KeyWordID := 0;
        If Ord(Str[nError.Position]) in [SP_NUMVAR, SP_STRVAR] Then
          KeyWordID := SP_KW_IMPLICIT_LET
        Else
          If (Ord(Str[nError.Position]) = SP_SYMBOL) And (Str[nError.Position +1] = '?') Then Begin
            Str[nError.Position] := aChar(SP_KEYWORD);
            Str := Copy(Str, 1, nError.Position) + LongWordToString(SP_KW_PRINT) + Copy(Str, nError.Position + 2);
          End;
        If (KeyWordID <> 0) or (Ord(Str[nError.Position]) = SP_KEYWORD) Then Begin
          SP_Convert_ToPostFix(Str, nError.Position, nError);
          If (nError.Code = SP_ERR_INVALID_KEYWORD) And (KeyWordID = SP_KW_IMPLICIT_LET) Then Begin
            nError.Position := 1;
            nError.Code := SP_ERR_OK;
            Str := SP_Convert_Expr(Str, nError.Position, nError, -1) + #255;
            SP_RemoveBlocks(Str);
            SP_TestConsts(Str, 1, Info^.Error^, False);
            SP_AddHandlers(Str);
            Str := #$F + Str;
          End Else If nError.Code = SP_ERR_OK Then Begin
            SP_TestConsts(Str, 1, Info^.Error^, False);
            SP_AddHandlers(Str);
          End Else
            Error^.Code := nError.Code;
        End Else Begin
          Str := SP_Convert_Expr(Str, nError.Position, nError, -1) + #255;
          SP_RemoveBlocks(Str);
          SP_TestConsts(Str, 1, Info^.Error^, False);
          SP_AddHandlers(Str);
          Str := #$F + Str;
        End;
        If (Str[2] = #255) or (nError.Code <> SP_ERR_OK) Then Begin
          //SP_StackPtr := SP_StackStart;
          If nError.Code = SP_ERR_OK Then Error^.Code := SP_ERR_SYNTAX_ERROR Else Error^.Code := nError.Code;
        End;
      End Else
        Str := ''
    End;
  End;
End;

Procedure SP_Interpret_FN_UDGS(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    If OpType = SP_VALUE Then
      Str := aChar((Round(Val) And 127) + 128)
    Else
      Str := aChar((Ord(Str[1]) And 127) + 128);
    OpType := SP_STRING;
  End;
End;

Procedure SP_Interpret_FN_UDG(Var Info: pSP_iInfo);
Begin
  With SP_StackPtr^ Do Begin
    If OpType = SP_STRING Then Begin
      If Str <> '' Then
        Val := SP_FindUDG(Byte(Str[1]), Info^.Error^)
      Else
        Val := -1;
      OpType := SP_VALUE;
    End Else
      Val := SP_FindUDG(Round(Val), Info^.Error^);
  End;
End;

Procedure SP_Interpret_FN_POPLINE(Var Info: pSP_iInfo);
Begin

  If SP_GOSUB_STACKPTR = 0 Then Begin
    Info^.Error^.Code := SP_ERR_OUT_OF_STACK;
    Exit;
  End Else Begin
    If SP_GOSUB_Stack[SP_GOSUB_STACKPTR -1].Source = SP_KW_EVERY Then
      ReEnableEvery := True;
    Inc(SP_StackPtr);
    If SP_GOSUB_Stack[SP_GOSUB_STACKPTR -1].Source = SP_KW_ERROR Then IGNORE_ON_ERROR := False;
    SP_StackPtr^.Val := pLongWord(@SP_Program[SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Line][2])^;
    Dec(SP_GOSUB_STACKPTR);
  End;

End;

Procedure SP_Interpret_FN_POPST(Var Info: pSP_iInfo);
Begin

  If SP_GOSUB_STACKPTR = 0 Then Begin
    Info^.Error^.Code := SP_ERR_OUT_OF_STACK;
    Exit;
  End Else Begin
    If SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Source = SP_KW_EVERY Then
      ReEnableEvery := True;
    If SP_GOSUB_Stack[SP_GOSUB_STACKPTR -1].Source = SP_KW_ERROR Then IGNORE_ON_ERROR := False;
    Inc(SP_StackPtr);
    SP_StackPtr^.Val := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].St;
  End;

End;

Procedure SP_Interpret_FN_VOL(Var Info: pSP_iInfo);
Begin

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := SP_GetGlobalVolume;
  SP_StackPtr^.OpType := SP_VALUE;

End;

Procedure SP_Interpret_FN_GETOPT(Var Info: pSP_iInfo);
Begin

  SP_StackPtr^.Val := SP_GetSysVarN(SP_StackPtr^.Str, Info^.Error^);
  SP_StackPtr^.OpType := SP_VALUE;

End;

Procedure SP_Interpret_FN_GETOPTS(Var Info: pSP_iInfo);
Begin

  SP_StackPtr^.Str := SP_GetSysVarS(SP_StackPtr^.Str, Info^.Error^);

End;

Procedure SP_Interpret_FN_DET(Var Info: pSP_iInfo);
Var
  sIdx, Idx, i,j,k,n: Integer;
  Ratio, Det: aFloat;
  Values: Array of aFloat;

  Function GetVal(r, c: Integer): aFloat;
  Begin
    Result := Values[(r*n)+c];
  End;

  Procedure SetVal(r, c: Integer; v: aFloat);
  Begin
    Values[(r*n)+c] := v;
  End;

Begin

  // Get the determinant of a matrix (a 2-dimensional array)
  // Destructive, so make a copy of the array.

  ERRStr := SP_StackPtr^.Str;
  sIdx := SP_FindNumArray(ERRStr);
  If sIdx > -1 Then Begin

    SP_StackPtr^.OpType := SP_VALUE;

    If (NumArrays[sIdx].NumIndices = 2) And (NumArrays[sIdx].Indices[0] = NumArrays[sIdx].Indices[1]) Then Begin

      n := NumArrays[sIdx].Indices[0];
      SetLength(Values, n * n);
      For Idx := 0 To NumArrays[sIdx].Size -1 Do
        Values[Idx] := NumArrays[sIdx].Values[Idx]^.Value;

      For i := 0 To n-1 Do
        For j := 0 To n-1 Do
          If j > i Then
            If GetVal(i,i) = 0 Then Begin
              SP_StackPtr^.Val := 0;
              Exit;
            End Else Begin
              Ratio := GetVal(j,i)/GetVal(i,i);
              For k := 0 To n-1 Do
                SetVal(j, k, GetVal(j, k) - Ratio * GetVal(i, k));
            End;

      Det := 1;
      For i := 0 To n-1 Do
        Det := Det * GetVal(i, i);

      SP_StackPtr^.Val := Det;

    End Else Begin
      Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
    End;

  End Else Begin
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
  End;

End;

Procedure SP_Interpret_FN_MIATTR(Var Info: pSP_iInfo);
Var
  mIdx: Integer;
Begin

  mIdx := Round(SP_StackPtr^.Val);
  SP_StackPtr^.Val := SP_GetItemAttrs(mIdx, Round(SP_StackPtr^.Val), Info^.Error^);

End;

Procedure SP_Interpret_FN_BINV(Var Info: pSP_iInfo);
Var
  n: Integer;
Begin

  // Invert all bits in a range

  n := (1 Shl Round(SP_StackPtr^.Val)) -1;
  Dec(SP_StackPtr);

  SP_StackPtr^.Val := Round(SP_StackPtr^.Val) Xor n;

End;

Procedure SP_Interpret_FN_BREV(Var Info: pSP_iInfo);
Var
  n, m, o, p: Integer;
Begin

  // Reverse lower order bits in a number

  n := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  o := 0; p := Round(SP_StackPtr^.Val);
  For m := 0 To n-1 Do
    o := (o Shl 1) or ((p Shr m) And 1);
  SP_StackPtr^.Val := {p - ((1 Shl n) -1) or }o;

End;

Procedure SP_Interpret_FN_CHOOSE(Var Info: pSP_iInfo);
Begin
  // Nothing doing. The SP_IJMP will take care of this _and_ of SP_FN_CHOOSES.
End;

Procedure SP_Interpret_FN_CHOOSES(Var Info: pSP_iInfo);
Begin
  // As above.
End;

Procedure SP_Interpret_FN_INTERP(Var Info: pSP_iInfo);
Var
  St, Ed, Amt: aFloat;
Begin

  // Interpolate between start and finish by amt

  Amt := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Ed := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  St := SP_StackPtr^.Val;

  SP_StackPtr^.Val := St + (Amt * (Ed-St));

End;

// Begin keyword interpreter procs

Procedure SP_Interpret_OPTION(Var Info: pSP_iInfo);
Var
  sPt: pSP_StackItem;
Begin

  // Set an option. ID-String on stack, followed by value to set.

  sPt := SP_StackPtr;
  Dec(sPt);
  SP_SetSysVar(SP_StackPtr^.Str, sPt^.Val, sPt^.Str, Info^.Error^);
  SP_StackPtr := sPt;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_PR_AT(Var Info: pSP_iInfo);
Var
  X, Y, aX, aY: Integer;
Begin

  // AT numexpr,numexpr

  X := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Y := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  IF T_CENTRE Then SP_FlushCentreBuffer(Info);

  IF OUTSET Then Begin

    OUTBUFFER := OUTBUFFER + aChar(22) + IntegerToString(Y) + IntegerToString(X);

  End Else Begin

    aX := 0; aY := 0;
    SP_ConvertToOrigin_i(aX, aY);

    PRPOSX := aX + Round(FONTWIDTH * X * T_SCALEX);
    PRPOSY := aY + Round(FONTHEIGHT * Y * T_SCALEY);

  End;

End;

Procedure SP_Interpret_PR_TAB(Var Info: pSP_iInfo);
Var
  cW, nx, tc, Y: Integer;
Begin

  // TAB numexpr

  IF T_CENTRE Then SP_FlushCentreBuffer(Info);

  If OUTSET Then Begin

    OUTBUFFER := OUTBUFFER + aChar(23) + IntegerToString(Round(SP_StackPtr^.Val));

  End Else Begin

    Y := Round(PRPOSY);
    Cw := Round(FONTWIDTH * T_SCALEX);
    nx := Round(PRPOSX) Div Cw; // current pos
    tc := Round(SP_StackPtr^.Val) mod (SCREENWIDTH Div Cw);
    If tc < nx Then Inc(tc, SCREENWIDTH Div Cw);
    SP_PRINT(-1, Round(PRPOSX), Y, -1, StringOfChar(aChar(' '), tc - nx), T_INK, T_PAPER, Info^.Error^);

  End;

  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_PR_CENTRE(Var Info: pSP_iInfo);
Var
  Y: Integer;
Begin

  // CENTRE numexpr - if we're already centring then we need to flush the centretext buffer at this
  // point.

  IF T_CENTRE Then SP_FlushCentreBuffer(Info);

  If OUTSET Then Begin

    OUTBUFFER := OUTBUFFER + aChar(24) + IntegerToString(Round(SP_StackPtr^.Val));

  End Else Begin

    Y := Round(SP_StackPtr^.Val * T_SCALEY);
    T_CENTRE := True;
    T_CENTRE_Y := Y;

  End;

  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_PR_MOVE(Var Info: pSP_iInfo);
Begin

  // MOVE numexpr,numexpr

  IF T_CENTRE Then SP_FlushCentreBuffer(Info);

  If OUTSET Then Begin

    OUTBUFFER := OUTBUFFER + aChar(21) + IntegerToString(Round(SP_StackPtr^.Val));
    Dec(SP_StackPtr);
    OUTBUFFER := OUTBUFFER + IntegerToString(Round(SP_StackPtr^.Val));
    Dec(SP_StackPtr);

  End Else Begin

    PRPOSY := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    PRPOSX := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    SP_ConvertToOrigin_d(PRPOSX, PRPOSY);
    If WINFLIPPED Then PRPOSY := (SCREENHEIGHT - 1) - PRPOSY;

  End;

End;

Procedure SP_Interpret_PR_OUT_VAR(Var Info: pSP_iInfo);
Begin

  // OUT str-var$

  IF T_CENTRE Then SP_FlushCentreBuffer(Info);

  SP_FlushOUTBuffer(Info);

  T_OUTEXPR := SP_StackPtr^.Str;
  OUTSET := True;
  T_OUTMODE := 1;
  Dec(SP_StackPtr);
  T_OUTASSIGN := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_PR_OUT_SCREEN(Var Info: pSP_iInfo);
Begin

  // OUT SCREEN

  SP_FlushOUTBuffer(Info);

  OUTSET := False;
  T_OUTMODE := 0;

End;

Procedure SP_Interpret_PR_OUT_STREAM(Var Info: pSP_iInfo);
Begin

  // OUT stream-id

  IF T_CENTRE Then Begin
    // Flush the centretext buffer
    SP_FlushCentreBuffer(Info);
    SP_FlushOUTBuffer(Info);
  End Else Begin
    SP_FlushOUTBuffer(Info);
    T_OUTSTRM := Round(SP_StackPtr^.Val);
    OUTSET := True;
    T_OUTMODE := 2;
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_PR_CLIP(Var Info: pSP_iInfo);
Var
  x1, y1, x2, y2, a: aFloat;
Begin

  // CLIP x1,y1 TO x2,y2

  y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  x2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  x1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_ConvertToOrigin_d(x1, y1);
  SP_ConvertToOrigin_d(x2, y2);

  If WINFLIPPED Then Begin
    y1 := (SCREENHEIGHT -1) - y1;
    y2 := (SCREENHEIGHT -1) - y2;
    If y1 > y2 Then Begin
      a := y1; y1 := y2; y2 := a;
    End;
  End;

  T_CLIPX1 := Round(x1);
  T_CLIPX2 := Round(x2);
  T_CLIPY1 := Round(y1);
  T_CLIPY2 := Round(y2);

End;

Procedure SP_Interpret_PR_CLIP_OFF(Var Info: pSP_iInfo);
Begin

  // CLIP OFF

  T_CLIPX1 := 0;
  T_CLIPX2 := SCREENWIDTH;
  T_CLIPY1 := 0;
  T_CLIPY2 := SCREENHEIGHT;

End;

Procedure SP_Interpret_PR_SCALE(Var Info: pSP_iInfo);
Begin

  // SCALE w,h - scalar values (1.0 being 1:1 size)

  If OUTSET Then Begin

    OUTBUFFER := OUTBUFFER + aChar(25) + aFloatToString(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    OUTBUFFER := OUTBUFFER + aFloatToString(SP_StackPtr^.Val);
    Dec(SP_StackPtr);

  End Else Begin

    T_SCALEY := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    T_SCALEX := SP_StackPtr^.Val;
    Dec(SP_StackPtr);

  End;

End;

Procedure SP_Interpret_SCALE(Var Info: pSP_iInfo);
Var
  ScaleX, ScaleY: aFloat;
  Window: pSP_Window_Info;
Begin

  ScaleX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  ScaleY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  If (ScaleX > 0) And (ScaleY > 0) Then Begin
    SP_GetWindowDetails(SCREENBANK, Window, Info^.Error^);
    If Info^.Error^.Code = SP_ERR_OK Then Begin
      CSCALEX := ScaleX;
      CSCALEY := ScaleY;
      T_SCALEX := CSCALEX;
      T_SCALEY := CSCALEY;
      Window^.ScaleX := CSCALEX;
      Window^.scaley := CSCALEY;
    End;
  End Else
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;

End;

Procedure SP_Interpret_PR_USING(Var Info: pSP_iInfo);
Begin

  // Sets the mask that will be used for subsequent PRINT commands

  T_USINGMASK := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_PR_CENTRE_OFF(Var Info: pSP_iInfo);
Begin

  If T_CENTRE Then SP_FlushCentreBuffer(Info);

End;

Procedure SP_FlushCentreBuffer(Var Info: pSP_iInfo);
Var
  pIdx, lIdx: pByte;
  cCount: Integer;
Begin

  // If Centremode is closing (due to a position move) then PRINT the current buffer.

  If T_CENTRETEXT <> '' Then Begin

    PRPOSY := 0;
    SP_ConvertToOrigin_d_y(PRPOSY);
    PRPOSY := PRPOSY + T_CENTRE_Y * FONTHEIGHT;

    pIdx := pByte(@T_CENTRETEXT[1]);
    lIdx := pIdx + Length(T_CENTRETEXT) -1;
    cCount := 0;
    If pIdx <> Nil Then
      cCount := 0;
      While not (pIdx^ in [6..11, 13]) and (pIdx <= lIdx) Do Begin
        Case pIdx^ Of
          16..20, 26, 27:
            Begin
              Inc(pIdx, SizeOf(LongWord));
            End;
          21..22:
            Begin
              Inc(pIdx, 2 * SizeOf(Integer));
            End;
          23..24:
            Begin
              Inc(pIdx, SizeOf(Integer));
            End;
          25:
            Begin
              Inc(pIdx, SizeOf(aFloat) * 2);
            End;
          32..255:
            Begin
              Inc(cCount);
            End;
        End;
        Inc(pIdx);
      End;
    PRPOSX := (SCREENWIDTH - Round(cCount * FONTWIDTH * T_SCALEX)) Div 2;

    If SP_TextOut(-1, Round(PRPOSX), Round(PRPOSY), T_CENTRETEXT, T_INK, T_PAPER, True) = SP_ERR_PRINT_ABANDONED Then
      Info^.Error^.Code := SP_ERR_BREAK;

  End;

  T_CENTRE := False;
  T_CENTRETEXT := '';

End;

Procedure SP_FlushOUTBuffer(Var Info: pSP_iInfo);
Var
  Tokens: paString;
  cCount, StreamIdx: Integer;
Begin

  If OUTBUFFER <> '' Then Begin

    Case T_OUTMODE Of
      1:
        Begin
          If T_OUTEXPR <> '' Then Begin
            // Execute the stored expression, after having prepended the current string.
            OUTWORKSP := CreateToken(SP_STRING, 0, Length(OUTBUFFER)) + OUTBUFFER + T_OUTEXPR + #255;
            SP_AddHandlers(OUTWORKSP);
            Tokens := @OUTWORKSP;
            cCount := 1;
            SP_InterpretCONTSafe(Tokens, cCount, Info^.Error^);
            If Info^.Error^.Code = SP_ERR_MISSING_VAR Then Begin
              Info^.Error^.Code := SP_ERR_OK;
              OUTWORKSP := CreateToken(SP_STRING, 0, 0) + '' + T_OUTASSIGN + #255;
              SP_AddHandlers(OUTWORKSP);
              Tokens := @OUTWORKSP;
              cCount := 1;
              SP_InterpretCONTSafe(Tokens, cCount, Info^.Error^);
              If Info^.Error^.Code = SP_ERR_OK Then Begin
                OUTWORKSP := CreateToken(SP_STRING, 0, Length(OUTBUFFER)) + OUTBUFFER + T_OUTEXPR + #255;
                SP_AddHandlers(OUTWORKSP);
                Tokens := @OUTWORKSP;
                cCount := 1;
                SP_InterpretCONTSafe(Tokens, cCount, Info^.Error^);
              End Else
                Exit;
            End;
          End;
        End;
      2:
        Begin
          StreamIdx := SP_FindStreamID(T_OUTSTRM, Info^.Error^);
          If StreamIdx > -1 Then
            SP_StreamWrite(StreamIdx, @OUTBUFFER[1], Length(OUTBUFFER), Info^.Error^)
          Else Begin
            Info^.Error^.Code := SP_ERR_INVALID_STREAM_ID;
            Exit;
          End;
        End;
    End;

    OUTBUFFER := '';

  End;

End;

Procedure SP_Interpret_ERROR(Var Info: pSP_iInfo);
Var
  ErrNum: Integer;
Begin

  // Enable or disable errors

  ErrNum := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If Not (ErrNum in [0, 16]) Then
    ErrorEnabled[ErrNum] := SP_StackPtr^.Val <> 0
  Else Begin
    ErrorEnabled[SP_ERR_INVALID_ERRNUM] := True;
    Info^.Error^.Code := SP_ERR_INVALID_ERRNUM;
  End;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_PRINT(Var Info: pSP_iInfo);
Var
  PrItem, CurItem: aString;
  UsingPos: Integer;
  Item: TUsingItem;
  AddReturn: Boolean;
Begin

  // This is the first keyword to be interpreted, and is a template for how this will work for
  // other keywords.

  // Repeat: Unstack values and PRINT them, until there are no values left. That's it :)

  PrItem := '';
  AddReturn := False;
  UsingPos := 1;

  While SP_StackPtr <> SP_StackStart Do Begin
    With SP_StackPtr^ Do Begin
      Case OpType of
        SP_VALUE:
          Begin
            If T_USINGMASK <> '' Then Begin
              Item.Kind := SP_VALUE;
              Item.Value := Val;
              CurItem := SP_Using(T_USINGMASK, [Item], UsingPos);
            End Else
              CurItem := aString(aFloatToStr(Val));
            prItem := PrItem + CurItem;
            AddReturn := True;
            CurItem := '';
          End;
        SP_STRING:
          Begin
            If (Str <> '') And Not (Str[1] in [#16, #17, #18]) Then Begin
              If T_USINGMASK <> '' Then Begin
                Item.Kind := SP_STRING;
                Item.Text := Str;
                CurItem := SP_Using(T_USINGMASK, [Item], UsingPos);
              End Else
                CurItem := Str;
            End Else
              CurItem := Str;
            prItem := PrItem + CurItem;
            AddReturn := True;
            CurItem := '';
          End;
        SP_SYMBOL:
          Begin
            Case Str[1] of
              #39:
                Begin
                  PrItem := PrItem + aChar(13);
                End;
              #255:
                Begin
                  AddReturn := True;
                End;
              ',':
                Begin
                  PrItem := PrItem + aChar(6);
                End;
              ';':
                Begin
                  AddReturn := False;
                End;
            End;
          End;
      End;
    End;
    Dec(SP_StackPtr);

  End;

  If (PrItem = '') and AddReturn Then
    PrItem := #13;

  If PrItem <> '' Then Begin
    If AddReturn and (PRItem[Length(PRItem)] <> #13) Then
      prItem := PrItem + #13;

    If Not T_CENTRE Then Begin
      If SCREENBPP = 8 Then Begin
        If SP_PRINT(-1, Round(PRPOSX), Round(PRPOSY), -1, PrItem, T_INK, T_PAPER, Info^.Error^) = SP_ERR_PRINT_ABANDONED Then Begin
          Info^.Error^.Code := SP_ERR_BREAK;
          T_USINGMASK := '';
          Exit;
        End;
      End Else
        If SP_PRINT32(-1, Round(PRPOSX), Round(PRPOSY), -1, PrItem, T_INK, T_PAPER, Info^.Error^) = SP_ERR_PRINT_ABANDONED Then Begin
          Info^.Error^.Code := SP_ERR_BREAK;
          T_USINGMASK := '';
          Exit;
        End;
    End Else Begin
      T_CENTRETEXT := T_CENTRETEXT + PrItem;
    End;
  End;

  If OUTSET Then SP_FlushOUTBuffer(Info);

  T_OUTMODE := COUTMODE;
  If T_OUTMODE = 1 Then Begin
    T_OUTEXPR := COUTEXPR;
    OUTSET := COUTEXPR <> '';
  End Else
    If T_OUTMODE = 2 Then Begin
      // set OUTSET if stream available - fail silently if not, only raise an error on the next output
      T_OUTSTRM := COUTSTRM;
      OUTSET := True;
    End Else
      OUTSET := False;

  T_USINGMASK := '';

End;

Procedure SP_Interpret_TEXT(Var Info: pSP_iInfo);
Var
  PrItem, CurItem: aString;
  UsingPos: Integer;
  Item: TUsingItem;
  AddReturn: Boolean;
Begin

  PrItem := '';
  AddReturn := False;
  UsingPos := 1;

  While SP_StackPtr <> SP_StackStart Do Begin
    With SP_StackPtr^ Do Begin
      Case OpType of
        SP_VALUE:
          Begin
            If T_USINGMASK <> '' Then Begin
              Item.Kind := SP_VALUE;
              Item.Value := Val;
              CurItem := SP_Using(T_USINGMASK, [Item], UsingPos);
            End Else
              CurItem := aString(aFloatToStr(Val));
            prItem := PrItem + CurItem;
            CurItem := '';
          End;
        SP_STRING:
          Begin
            If T_USINGMASK <> '' Then Begin
              Item.Kind := SP_STRING;
              Item.Text := Str;
              CurItem := SP_Using(T_USINGMASK, [Item], UsingPos);
            End Else
              CurItem := Str;
            prItem := PrItem + CurItem;
            CurItem := '';
          End;
        SP_SYMBOL:
          Begin
            Case Str[1] of
              #39:
                Begin
                  PrItem := PrItem + aChar(13);
                End;
              #255:
                Begin
                  AddReturn := True;
                End;
              ',':
                Begin
                  PrItem := PrItem + aChar(6);
                End;
            End;
          End;
      End;
    End;
    Dec(SP_StackPtr);

  End;

  If PrItem <> '' Then Begin
    If PrItem[Length(PrItem)] = #13 Then
      AddReturn := False;

    If OUTSET Then
      SP_PRINT(-1, Round(PRPOSX), Round(PRPOSY), -1, PrItem, T_INK, T_PAPER, Info^.Error^)
    Else
      If Not T_CENTRE Then Begin
        If SCREENBPP = 8 Then Begin
          If SP_TextOut(-1, Round(PRPOSX), Round(PRPOSY), PrItem, T_INK, T_PAPER, True) = SP_ERR_PRINT_ABANDONED Then Begin
            Info^.Error^.Code := SP_ERR_BREAK;
            T_USINGMASK := '';
            Exit;
          End;
        End Else
          If SP_TextOut32(-1, Round(PRPOSX), Round(PRPOSY), PrItem, T_INK, T_PAPER, True) = SP_ERR_PRINT_ABANDONED Then Begin
            Info^.Error^.Code := SP_ERR_BREAK;
            T_USINGMASK := '';
            Exit;
          End;
      End Else Begin
        T_CENTRETEXT := T_CENTRETEXT + PrItem;
      End;
      if AddReturn Then Begin
        PRPOSX := 0;
        PRPOSY := PRPOSY + Round(FONTHEIGHT * T_SCALEY);
      End;
  End Else
    If AddReturn Then Begin
      PRPOSX := 0;
      PRPOSY := PRPOSY + Round(FONTHEIGHT * T_SCALEY);
    End;

  T_OUTMODE := COUTMODE;
  If T_OUTMODE = 1 Then Begin
    T_OUTEXPR := COUTEXPR;
    OUTSET := COUTEXPR <> '';
  End Else
    If T_OUTMODE = 2 Then Begin
      // set OUTSET if stream available - fail silently if not, only raise an error on the next output
      T_OUTSTRM := COUTSTRM;
      OUTSET := True;
    End Else
      OUTSET := False;

  T_USINGMASK := '';

End;

Procedure SP_Interpret_PR_INK(Var Info: pSP_iInfo);
Var
  Ink: LongWord;
Begin

  // Temporary INK assignment. Add a CHR$ 16, followed by a byte INK value

  With SP_StackPtr^ Do Begin

    Ink := LongWord(Round(SP_StackPtr^.Val));
    Dec(SP_StackPtr);

    If OUTSET Then
      OUTBUFFER := OUTBUFFER + aChar(16) + LongWordToString(Ink)
    Else
      IF T_CENTRE Then
        T_CENTRETEXT := T_CENTRETEXT + aChar(16) + LongWordToString(Ink)
      Else Begin
        If pSP_Window_Info(WINDOWPOINTER)^.bpp <> 32 Then
          T_INK := Ink And 255
        Else
          T_INK := INK;
      End;

  End;

End;

Procedure SP_Interpret_PR_PAPER(Var Info: pSP_iInfo);
Var
  Paper: Integer;
Begin

  With SP_StackPtr^ Do Begin

    Paper := LongWord(Round(SP_StackPtr^.Val));
    Dec(SP_StackPtr);

    If OUTSET Then
      OUTBUFFER := OUTBUFFER + aChar(17) + LongWordToString(Paper)
    Else
      IF T_CENTRE Then
        T_CENTRETEXT := T_CENTRETEXT + aChar(17) + LongWordToString(Paper)
      Else Begin
        If pSP_Window_Info(WINDOWPOINTER)^.bpp <> 32 Then
          T_PAPER := Paper And 255
        Else
          T_PAPER := Paper;
      End;

  End;

End;

Procedure SP_Interpret_PR_ITALIC(Var Info: pSP_iInfo);
Var
  Italic: Integer;
Begin

  Italic := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If (Italic >= 0) And (Italic <= 255) Then Begin
    If Italic <> 8 Then
      If OUTSET Then
        OUTBUFFER := OUTBUFFER + aChar(26) + IntegerToString(Italic)
      Else
        IF T_CENTRE Then
          T_CENTRETEXT := T_CENTRETEXT + aChar(26) + IntegerToString(Italic)
        Else Begin
          T_ITALIC := Italic;
        End;

  End Else
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;

End;

Procedure SP_Interpret_PR_BOLD(Var Info: pSP_iInfo);
Var
  Bold: Integer;
Begin

  Bold := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If (Bold >= 0) And (Bold <= 255) Then Begin
    If Bold <> 8 Then
      If OUTSET Then
        OUTBUFFER := OUTBUFFER + aChar(27) + IntegerToString(Bold)
      Else
        IF T_CENTRE Then
          T_CENTRETEXT := T_CENTRETEXT + aChar(27) + IntegerToString(Bold)
        Else Begin
          T_BOLD := Bold;
        End;

  End Else
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;

End;

Procedure SP_Interpret_PR_INVERSE(Var Info: pSP_iInfo);
Var
  Inverse: Integer;
Begin

  Inverse := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If (Inverse >= 0) And (Inverse <= 255) Then Begin
    If Inverse <> 8 Then
      If OUTSET Then
        OUTBUFFER := OUTBUFFER + aChar(20) + IntegerToString(Inverse)
      Else
        IF T_CENTRE Then
          T_CENTRETEXT := T_CENTRETEXT + aChar(20) + IntegerToString(Inverse)
        Else Begin
          T_INVERSE := Inverse;
        End;

  End Else
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;

End;

Procedure SP_Interpret_PR_OVER(Var Info: pSP_iInfo);
Var
  Over: Integer;
Begin

  Over := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If (Over >= 0) And (Over <= 255) Then Begin
    If OUTSET Then
      OUTBUFFER := OUTBUFFER + aChar(18) + IntegerToString(Over)
    Else
      IF T_CENTRE Then
        T_CENTRETEXT := T_CENTRETEXT + aChar(18) + IntegerToString(Over)
      Else Begin
        T_OVER := Over;
      End;

  End Else
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;

End;

Procedure SP_Interpret_PR_TRANSPARENT(Var Info: pSP_iInfo);
Var
  Trans: Byte;
Begin

  Trans := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If OUTSET Then
    OUTBUFFER := OUTBUFFER + aChar(19) + IntegerToString(Trans)
  Else
    If Trans <> 8 Then
      IF T_CENTRE Then
        T_CENTRETEXT := T_CENTRETEXT + aChar(19) + IntegerToString(Trans)
      Else Begin
        T_TRANSPARENT := Boolean(Trans);
      End;

End;

Procedure SP_Interpret_PR_CURSOR(Var Info: pSP_iInfo);
Var
  Spt: pSP_StackItem;
Begin

  // CURSOR numexpr,numexpr

  sPt := SP_StackPtr;
  Dec(Spt);
  INPUTCSR2 := Round(SP_StackPtr^.Val);
  INPUTCSR1 := Round(sPt^.Val);
  Dec(SP_StackPtr, 2);

End;

Procedure SP_Interpret_INK(Var Info: pSP_iInfo);
Var
  Val: Integer;
  ValI: LongWord;
  Window: pSP_Window_Info;
Begin

  If pSP_Window_Info(WINDOWPOINTER)^.bpp <> 32 Then Begin
    Val := Round(SP_StackPtr^.Val) And 255;
    If (Val >= 0) And (Val <= 255) Then Begin
      CINK := Val;
      T_INK := Val;
    End Else Begin
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
      Exit;
    End;
  End Else Begin
    ValI := LongWord(Round(SP_StackPtr^.Val));
    CINK := ValI;
    T_INK := ValI;
  End;
  SP_GetWindowDetails(SCREENBANK, Window, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then
    Window^.Ink := CINK;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_PAPER(Var Info: pSP_iInfo);
Var
  Val: Integer;
  ValI: LongWord;
  Window: pSP_Window_Info;
Begin

  If pSP_Window_Info(WINDOWPOINTER)^.bpp <> 32 Then Begin
    Val := Round(SP_StackPtr^.Val) and 255;
    If (Val >= 0) And (Val <= 255) Then Begin
      CPAPER := Val;
      T_PAPER := Val;
    End Else Begin
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
      Exit;
    End;
  End Else Begin
    ValI := LongWord(Round(SP_StackPtr^.Val));
    CPAPER := ValI;
    T_PAPER := ValI;
  End;
  SP_GetWindowDetails(SCREENBANK, Window, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then
    Window^.Paper := CPAPER;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_INVERSE(Var Info: pSP_iInfo);
Var
  Window: pSP_Window_Info;
Begin

  If Round(SP_StackPtr^.Val) <> 8 Then Begin
    CINVERSE := Round(SP_StackPtr^.Val);
    T_INVERSE := CINVERSE;
    SP_GetWindowDetails(SCREENBANK, Window, Info^.Error^);
    If Info^.Error^.Code = SP_ERR_OK Then
      Window^.Inverse := CINVERSE;
  End;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_ITALIC(Var Info: pSP_iInfo);
Var
  Window: pSP_Window_Info;
Begin

  If Round(SP_StackPtr^.Val) <> 8 Then Begin
    CITALIC := Round(SP_StackPtr^.Val);
    T_ITALIC := CINVERSE;
    SP_GetWindowDetails(SCREENBANK, Window, Info^.Error^);
    If Info^.Error^.Code = SP_ERR_OK Then
      Window^.Italic := CITALIC;
  End;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_BOLD(Var Info: pSP_iInfo);
Var
  Window: pSP_Window_Info;
Begin

  If Round(SP_StackPtr^.Val) <> 8 Then Begin
    CBOLD := Round(SP_StackPtr^.Val);
    T_BOLD := CBOLD;
    SP_GetWindowDetails(SCREENBANK, Window, Info^.Error^);
    If Info^.Error^.Code = SP_ERR_OK Then
      Window^.Bold := CBOLD;
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_OVER(Var Info: pSP_iInfo);
Var
  Window: pSP_Window_Info;
Begin

  COVER := Round(SP_StackPtr^.Val);
  T_OVER := COVER;
  SP_GetWindowDetails(SCREENBANK, Window, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then
    Window^.Over := COVER;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_TRANSPARENT(Var Info: pSP_iInfo);
Var
  Window: pSP_Window_Info;
Begin

  If Round(SP_StackPtr^.Val) <> 8 Then Begin
    CTRANSPARENT := Round(SP_StackPtr^.Val) <> 0;
    T_TRANSPARENT := CTRANSPARENT;
    SP_GetWindowDetails(SCREENBANK, Window, Info^.Error^);
    If Info^.Error^.Code = SP_ERR_OK Then
      Window^.FontTrans := CTRANSPARENT;
  End;
  Dec(SP_StackPtr);

End;

Procedure SP_StackToString(NumIndices: Integer); inline;
Var
  TokenStart: pByte;
Begin

  // If the indices count is zero then the array is being accessed via
  // a key-string. Otherwise, it's a regular index lookup.

  If NumIndices > 0 Then Begin

    gbKey := '';
    Nl := NumIndices * SizeOf(LongWord);
    If Nl <> Il Then Begin
      SetLength(gbIndices, Nl);
      Il := Nl;
    End;

    Dec(SP_StackPtr);
    TokenStart := pByte(pLongWord(@gbIndices)^ + (Nl - SizeOf(LongWord)));
    While NumIndices > 0 Do Begin
      pInteger(TokenStart)^ := Round(SP_StackPtr^.Val);
      Dec(TokenStart, SizeOf(LongWord));
      Dec(NumIndices);
      Dec(SP_StackPtr);
    End;

  End Else Begin

    Dec(SP_StackPtr);
    gbKey := SP_StackPtr^.Str;
    gbIndices := '';
    Il := 0;
    Dec(SP_StackPtr);

  End;

End;

Procedure SP_Interpret_LET(Var Info: pSP_iInfo);
Var
  SliceFlags: Byte;
  Content, sName: aString;
  Idx, SliceFrom, SliceTo, NumIndices: Integer;
  StrPtr: pSP_StrVarContent;
  Sp1, Sp2: pSP_StackItem;
Begin

  // On entry, the top item will be the variable to update - Val=index, Str=name
  // the next item on the stack will be the value to assign to the variable.

  // for simple string and numeric variable assignment, the code here is now legacy and shouldn't be
  // called. Array assigns are still used here though.

  Sp1 := SP_StackPtr;
  Dec(Sp1);
  Sp2 := Sp1;
  Dec(Sp2);
  ERRStr := Sp2^.Str;

  With SP_StackPtr^ Do
    Case OpType of
      SP_NUMVAR:
        Begin
          SP_UpdateNumVar(Round(Val), Str, Sp1^.Val, Info^.Error^, Ptr);
          Dec(SP_StackPtr, 2);
        End;

      SP_STRVARPTR:
        Begin
          ERRStr := ERRStr + '$';
          SP_SetStructMember(pSP_StrVarContent(Ptr), Sp1^.Str, Sp2^.Str, Sp2^.Val, Info^.Error^);
          Dec(SP_StackPtr, 3);
        End;

      SP_STRVAR:
        Begin
          // If we reach here, we're assigning a structure to a simple string variable
          sName := Sp1^.Str;
          ERRStr := ERRStr + '$';
          SP_AssignStruct(Round(Val), Str, sName, Info^.Error^, Ptr);
          StrPtr := SP_GetStrVarPtr(Round(Val), Str, Info^.Error^, Ptr);
          Dec(SP_StackPtr, 2);
          While SP_StackPtr <> SP_StackStart Do Begin
            // Find any default values now.
            Sp1 := SP_StackPtr;
            Dec(Sp1);
            If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
              SP_SetStructMember(StrPtr, SP_StackPtr^.Str, '', Sp1^.Val, Info^.Error^);
              If Info^.Error^.Code <> SP_ERR_OK Then Exit;
            End Else
              If SP_StackPtr^.OpType = SP_STRVAR Then Begin
                SP_SetStructMember(StrPtr, SP_StackPtr^.Str+'$', Sp1^.Str, 0, Info^.Error^);
                If Info^.Error^.Code <> SP_ERR_OK Then Exit;
              End;
            Dec(SP_StackPtr, 2);
          End;
        End;

      SP_ARRAY_ASSIGN:
        Begin
          SP_StackToString(Round(Val));
          Sp1 := SP_StackPtr;
          Dec(Sp1);
          With SP_StackPtr^ Do Begin
            Idx := Round(Val);
            SP_UpdateNumArray(Idx, Str, gbIndices, gbKey, Sp1^.Val, Info^.Error^);
            If Idx <> -1 Then
              If INPROC = 0 Then
                SP_StackPtr^.Ptr^ := Idx +1;
          End;
          Dec(SP_StackPtr, 2);
        End;

      SP_SLICE_ASSIGN:
        Begin
          ERRStr := ERRStr + '$';
          SliceFlags := Byte(Str[1]);
          NumIndices := Round(Val);
          Dec(SP_StackPtr);
          If SliceFlags And 8 = 8 Then Begin
            SliceFrom := 1;
            SliceTo := MAXINT;
          End Else
            If SliceFlags And 4 = 4 Then Begin
              SliceFrom := Round(SP_StackPtr^.Val);
              SliceTo := SliceFrom;
            End Else Begin
              If SliceFlags And 1 = 1 Then Begin
                SliceTo := Round(SP_StackPtr^.Val);
                if SliceTo < 0 then Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
                Dec(SP_StackPtr);
              End Else
                SliceTo := -1;
              If SliceFlags And 2 = 2 Then Begin
                If SP_StackPtr^.OpType = SP_VALUE Then Begin
                  SliceFrom := Round(SP_StackPtr^.Val);
                  if SliceFrom < 0 then Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
                  Dec(SP_StackPtr);
                End Else
                  SliceFrom := SliceTo;
              End Else
                SliceFrom := -1;
          End;

          // Modify the slicer?

          While SP_StackPtr^.OpType = SP_SLICE_ASSIGN Do Begin
            SliceFlags := Byte(SP_StackPtr^.Str[1]);
            NumIndices := Round(SP_StackPtr^.Val);
            Dec(SP_StackPtr);
            If SliceFlags And 8 = 8 Then Begin
              SliceFrom := 1;
              SliceTo := MAXINT;
            End Else
              If SliceFlags And 4 = 4 Then Begin // Single char
                If SliceFrom = -1 Then
                  SliceFrom := Round(SP_StackPtr.Val)
                Else
                  Inc(SliceFrom, Round(SP_StackPtr^.Val) -1);
                SliceTo := SliceFrom;
                Dec(SP_StackPtr);
              End Else Begin
                If SliceFlags And 1 = 1 Then Begin // TO value
                  If SliceFrom = -1 Then
                    SliceTo := Min(SliceTo, Round(SP_StackPtr^.Val))
                  Else
                    SliceTo := Min(SliceFrom + Round(SP_StackPtr^.Val) -1, SliceTo);
                  Dec(SP_StackPtr);
                End;
                If SliceFlags And 2 = 2 Then Begin // From value
                  If SliceFrom = -1 Then Begin
                    SliceFrom := Round(SP_StackPtr^.Val);
                    Inc(SliceTo, SliceFrom -1);
                  End Else Begin
                    inc(SliceFrom, Round(SP_StackPtr^.Val) -1);
                    If SliceTo <> -1 Then
                      Inc(SliceTo, Round(SP_StackPtr^.Val) -1);
                  End;
                  Dec(SP_StackPtr);
                End;
              End;
          End;

          With SP_StackPtr^ Do
            If OpType in [SP_VALUE, SP_STRING] Then Begin
              Inc(SP_StackPtr);
              SP_StackToString(NumIndices);
            End Else Begin
              gbIndices := LongWordToString(Longword(SliceTo));
              Il := SizeOf(LongWord);
            End;

          ERRStr := SP_StackPtr^.Str + '$';
          If SP_FindStrArray(SP_StackPtr^.Str) = -1 Then Begin
            If Integer(SP_StackPtr^.tPos) = -1 Then Begin
              Idx := SP_FindStrVar(SP_StackPtr^.Str);
              If Idx > -1 Then Begin
                If SliceFlags = 0 Then Begin
                  SliceFrom := pLongWord(@gbIndices[1])^;
                  SliceTo := SliceFrom;
                End Else
                  If SliceFrom = -1 Then SliceFrom := 1;
                If SliceTo > -1 Then
                  SliceTo := Min(SliceTo, Length(StrVars[Idx]^.ContentPtr^.Value));
                If SliceFrom < 1  Then Begin
                  Info^.Error^.Code := SP_ERR_SUBSCRIPT_WRONG;
                  Exit;
                End Else Begin
                  Sp1 := SP_StackPtr;
                  Dec(Sp1);
                  If Info^.Error^.Code = SP_ERR_OK Then
                    SP_SliceAssign(StrVars[Idx]^.ContentPtr^.Value, Sp1^.Str, SliceFrom, SliceTo, Info^.Error^);
                End;
              End Else
                Info^.Error^.Code := SP_ERR_MISSING_VAR;
            End Else
              Info^.Error^.Code := SP_ERR_CONST_IN_ASSIGNMENT;
          End Else Begin
            Sp1 := SP_StackPtr;
            Dec(Sp1);
            If Sp1^.OpType = SP_STRUCT_MEMBER_ASS Then Begin
              With SP_StackPtr^ Do Begin
                If OpType = SP_STRVARPTR Then
                  StrPtr := pSP_StrVarContent(Ptr)
                Else
                  StrPtr := SP_GetStrArrayPtr(Round(Val), Str, gbIndices, gbKey, Info^.Error^);
                If Info^.Error^.Code = SP_ERR_OK Then Begin
                  Sp1 := SP_StackPtr;
                  Dec(Sp1);
                  Sp2 := Sp1;
                  Dec(Sp2);
                  If SliceFlags <> 0 Then Begin
                    Content := SP_GetStructMemberS(StrPtr, Sp1^.Str, Info^.Error^);
                    If (SliceTo < 1) or (SliceTo > Length(Content)) Then Begin
                      Info^.Error^.Code := SP_ERR_SUBSCRIPT_WRONG;
                      Exit;
                    End Else
                      If Info^.Error^.Code = SP_ERR_OK Then Begin
                        SP_SliceAssign(Content, Sp2^.Str, SliceFrom, SliceTo, Info^.Error^);
                        SP_SetStructMember(StrPtr, Sp1^.Str, Content, 0, Info^.Error^);
                      End;
                  End Else
                    SP_SetStructMember(StrPtr, Sp1^.Str, Sp2^.Str, Sp2^.Val, Info^.Error^);
                End;
              End;
            End Else Begin
              Sp1 := SP_StackPtr;
              If gbKey <> '' Then
                Inc(Sp1)
              Else
                Dec(Sp1);
              If Sp1^.OpType = SP_STRING Then Begin
                With SP_StackPtr^ Do
                  SP_UpdateStrArray(Round(Val), Str, gbIndices, gbKey, Sp1^.Str, SliceFrom, SliceTo, Info^.Error^);
                Dec(SP_StackPtr, 2);
              End Else Begin
                // This is assigning a structure to an array string alone. Headache time!
                With SP_StackPtr^ Do Begin
                  StrPtr := SP_GetStrArrayPtr(Round(Val), Str, gbIndices, gbKey, Info^.Error^);
                  SP_AssignStructPtr(StrPtr, Sp1^.Str, Info^.Error^);
                End;
                Dec(SP_StackPtr, 2);
                // Now find any default values...
                While SP_StackPtr <> SP_StackStart Do Begin
                  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
                    SP_SetStructMember(StrPtr, SP_StackPtr^.Str, '', Sp1^.Val, Info^.Error^);
                    If Info^.Error^.Code <> SP_ERR_OK Then Exit;
                  End Else
                    If SP_StackPtr^.OpType = SP_STRVAR Then Begin
                      SP_SetStructMember(StrPtr, SP_StackPtr^.Str+'$', Sp1^.Str, 0, Info^.Error^);
                      If Info^.Error^.Code <> SP_ERR_OK Then Exit;
                    End;
                  Dec(SP_StackPtr, 2);
                End;
              End;
            End;
          End;
        End;
    End;

End;

Procedure SP_Interpret_ENUM(Var Info: pSP_iInfo);
Begin

  With SP_StackPtr^ Do Begin
    Val := Val + ENUMBASE -1;
    If Str <> '' Then
      Str := aChar(Byte(Str[1]) + Round(ENUMBASE) -1);
  End;

End;

Procedure SP_Interpret_ENUM_BASE(Var Info: pSP_iInfo);
Begin

  ENUMBASE := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_CLS(Var Info: pSP_iInfo);
Var
  Val: LongWord;
Begin

  Val := CPAPER;
  If SP_StackPtr <> SP_StackStart Then Begin
    Val := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    If (pSP_Window_Info(WINDOWPOINTER)^.bpp = 8) And (Val > 255) Then Begin
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
      Info^.Error^.Position := SP_StackPtr^.tPos;
      Exit;
    End;
  End;

  SP_CLS(Val);
  PRPOSX := 0;
  PRPOSY := 0;
  SP_ConvertToOrigin_d(PRPOSX, PRPOSY);

End;

Procedure SP_Interpret_KW_CLS_ALPHA(Var Info: pSP_iInfo);
Var
  Val: LongWord;
Begin

  Val := CPAPER;
  If SP_StackPtr <> SP_StackStart Then Begin
    Val := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End;

  SP_CLS32(Val);
  PRPOSX := 0;
  PRPOSY := 0;
  SP_ConvertToOrigin_d(PRPOSX, PRPOSY);

End;

Procedure SP_Interpret_DIM(Var Info: pSP_iInfo);
Var
  StrPtr: pSP_StrVarContent;
  Sp1: pSP_StackItem;
  Idx, aIdx, NumIndices, DLen, DIMBase, VarType: Integer;
  Indices, StructName, Content, VarName, Key: aString;
Begin

  DLen := 0;

  // Stack order for regular array: var, base, numindices, index1, index2...[,structure members:numvar, value...]
  // Stack order for auto-array: var, base, numindices, index1, elements...

  VarType := SP_StackPtr^.OpType;
  VarName := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  // BASE value

  DIMBase := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If DIMBase < 0 Then DIMBase := BASE;

  // If a string, then LEN value follows

  If VarType = SP_STRVAR Then Begin
    DLen := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End;

  // Numindices, followed by dimensions themselves

  Indices := '';
  NumIndices := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  For Idx := 1 To NumIndices Do Begin
    aIdx := Round(SP_StackPtr^.Val);
    If aIdx > 0 Then
      Indices := Indices + LongWordToString(Round(SP_StackPtr^.Val))
    Else Begin
      ERRStr := VarName;
      Info^.Error^.Code := SP_ERR_SUBSCRIPT_WRONG;
      Exit;
    End;
    Dec(SP_StackPtr);
  End;

  Case VarType of
    SP_NUMVAR:
      Begin
        SP_CreateNumArray(VarName, Indices, DIMBase, False, Info^.Error^);
      End;
    SP_STRVAR:
      Begin
        StructName := '';
        If SP_StackPtr <> SP_StackStart Then Begin
          If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
            StructName := SP_StackPtr^.Str;
            Dec(SP_StackPtr);
          End;
        End;
        SP_CreateStrArray(VarName, Indices, DLen, StructName, DIMBase, False, Info^.Error^);

        // Look for default values now for struct members. Assign them to the first in the array,
        // and then copy that one item out to the rest of the string array values.

        If (Info^.Error.Code = SP_ERR_OK) And (StructName <> '') Then Begin
          Key := '';
          Indices := '';
          For Idx := 1 To NumIndices Do
            Indices := Indices + LongWordToString(DIMBase);
          StrPtr := SP_GetStrArrayPtr(0, VarName, Indices, Key, Info^.Error^);
          While SP_StackPtr <> SP_StackStart Do Begin
            Sp1 := SP_StackPtr;
            Dec(Sp1);
            If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
              SP_SetStructMember(StrPtr, SP_StackPtr^.Str, '', Sp1^.Val, Info^.Error^);
              If Info^.Error^.Code <> SP_ERR_OK Then Exit;
            End Else
              If SP_StackPtr^.OpType = SP_STRVAR Then Begin
                SP_SetStructMember(StrPtr, SP_StackPtr^.Str+'$', Sp1^.Str, 0, Info^.Error^);
                If Info^.Error^.Code <> SP_ERR_OK Then Exit;
              End;
            Dec(SP_StackPtr, 2);
          End;
          Content := StrPtr^.Value;
          aIdx := SP_FindStrArray(VarName);
          For Idx := 0 To Length(StrArrays[aIdx].Strings) -1 Do
            StrArrays[aIdx].Strings[Idx]^.Value := Content;
        End;
      End;

  End;

End;

Procedure SP_Interpret_DIM_SPLIT(Var Info: pSP_iInfo);
Var
  VarType, DIMBase, DLen, SplitNOT, Count, Idx, Idx2, SplitterLen, LastSplit, SplitCnt: Integer;
  VarName, SplitString, Indices: aString;
  Splits, Splitters: Array of aString;
Label
  SplitDone, SplitDone2;
Begin

  SplitterLen := 0;
  VarType := SP_StackPtr^.OpType;
  VarName := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  // BASE value

  DIMBase := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If DIMBase < 0 Then DIMBase := BASE;

  // If a string, then LEN value follows

  If VarType = SP_STRVAR Then Begin
    DLen := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End Else
    DLen := 0;

  SplitNOT := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SplitCnt := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SetLength(Splitters, SplitCnt);
  For Idx := 1 To SplitCnt Do Begin
    If SP_StackPtr^.Str <> '' Then
      Splitters[Idx -1] := SP_StackPtr^.Str
    Else Begin
      Info^.Error^.Code := SP_ERR_INVALID_SEPARATOR;
      Exit;
    End;
    Dec(SP_StackPtr);
  End;

  SplitString := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  If (SplitCnt <> 0) And Not ((SplitCnt = 1) And (Splitters[0] = ' ')) Then Begin

    If Length(SplitString) > 0 Then Begin

      Idx := 1;
      Count := 0;
      LastSplit := 1;
      While Idx <= Length(SplitString) Do Begin
        Idx2 := 0;
        While Idx2 < SplitCnt Do Begin
          SplitterLen := Length(Splitters[Idx2]);
          If Copy(SplitString, Idx, SplitterLen) = Splitters[Idx2] Then Begin
            Inc(Count);
            Inc(Idx, SplitterLen);
            LastSplit := Idx;
            Goto SplitDone;
          End;
          Inc(Idx2);
        End;
        Inc(Idx);
        SplitDone:
      End;

      If LastSplit <= Length(SplitString) Then
        Inc(Count);

      SetLength(Splits, Count);
      Indices := LongWordToString(Count);

      Idx := 1;
      Count := 0;
      LastSplit := 1;
      While Idx <= Length(SplitString) - (SplitterLen -1) Do Begin
        Idx2 := 0;
        While Idx2 < SplitCnt Do Begin
          SplitterLen := Length(Splitters[Idx2]);
          If Copy(SplitString, Idx, SplitterLen) = Splitters[Idx2] Then Begin
            If SplitNOT = -1 Then
              Splits[Count] := Copy(SplitString, LastSplit, 1 + Idx - 1 - LastSplit)
            Else
              Splits[Count] := Copy(SplitString, LastSplit, 1 + Idx + SplitterLen -1 - LastSplit);
            Inc(Idx, SplitterLen);
            LastSplit := Idx;
            Inc(Count);
            Goto SplitDone2;
          End;
          Inc(Idx2);
        End;
        Inc(Idx);
        SplitDone2:
      End;

      If LastSplit <= Length(SplitString) Then
        Splits[Count] := Copy(SplitString, LastSplit, Length(SplitString));

      VarType := SP_CreateStrArray(VarName, Indices, DLen, '', DIMBase, False, Info^.Error^) +1;

      For Idx := 0 To Length(Splits) -1 Do Begin
        Indices := LongWordToString(Idx + DIMBase);
        SP_UpdateStrArray(VarType, VarName, Indices, '', Splits[Idx], -1, -1, Info^.Error^);
      End;

    End Else
      Info^.Error^.Code := SP_ERR_EMPTY_SPLIT_STRING;

  End Else
    Info^.Error^.Code := SP_ERR_INVALID_SEPARATOR;


End;

Procedure SP_Interpret_AUTODIM(Var Info: pSP_iInfo);
Var
  Idx, aIdx, ArrIdx, NumIndices, Count, DLen, DIMBase, VarType: Integer;
  Indices, VarName, Key: aString;
Begin

  // Stack order for auto-array: var, base, [len, ] numindices, index1, elements...

  VarType := SP_StackPtr^.OpType;
  VarName := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  // BASE value

  DIMBase := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If DIMBase < 0 Then DIMBase := BASE;

  // If a string, then LEN value follows

  If VarType = SP_STRVAR Then Begin
    DLen := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End Else
    DLen := 0;

  Indices := '';
  NumIndices := Round(SP_StackPtr^.Val);
  Count := 1;
  Dec(SP_StackPtr);

  For Idx := 1 To NumIndices Do Begin
    aIdx := Round(SP_StackPtr^.Val);
    If aIdx > 0 Then Begin
      Indices := Indices + LongWordToString(aIdx);
      Count := Count * aIdx;
    End Else Begin
      ERRStr := VarName;
      Info^.Error^.Code := SP_ERR_SUBSCRIPT_WRONG;
      Exit;
    End;
    Dec(SP_StackPtr);
  End;

  Case VarType of
    SP_NUMVAR:
      Begin
        SP_CreateNumArray(VarName, Indices, DIMBase, False, Info^.Error^);
      End;
    SP_STRVAR:
      Begin
        SP_CreateStrArray(VarName, Indices, DLen, '', DIMBase, False, Info^.Error^);
      End;
  End;

  If ((NativeUInt(SP_StackPtr) - NativeUInt(SP_StackStart)) Div SizeOf(SP_StackItem)) -1 = Count -1 Then Begin

    // A one-dimensional auto-array

    Case VarType of
      SP_NumVar: arrIdx := SP_FindNumArray(VarName);
      SP_StrVar: arrIdx := SP_FindStrArray(VarName);
    Else
      arrIdx := 0;
    End;

    Key := '';
    Count := 0;
    While SP_StackPtr <> SP_StackStart Do Begin

      If VarType = SP_NUMVAR Then
        NumArrays[arrIdx].Values[Count]^.Value := SP_StackPtr^.Val
      Else
        StrArrays[arrIdx].Strings[Count]^.Value := SP_StackPtr^.Str;

      Inc(Count);
      Dec(SP_StackPtr);

    End;

  End;

End;

Procedure SP_Interpret_RUN(Var Info: pSP_iInfo);
Var
  LineNum, Idx, ProgLen: Integer;
  nLabel: TSP_Label;
  tStr: aString;
Label
  RunIt;
Begin

  OnActive := 0;
  If Not SP_CheckProgram(True) Then Begin
    Info^.Error^.Code := SP_ERR_SYNTAX_ERROR;
    Exit;
  End;

  If SP_StackPtr <> SP_StackStart Then Begin
    If SP_StackPtr^.OpType = SP_LABEL Then Begin
      nLabel := SP_FindLabel(SP_StackPtr^.Str, Info^.Error^);
      Dec(SP_StackPtr);
      If nLabel.Line <> -1 Then Begin
        NXTLINE := nLabel.Line;
        NXTSTATEMENT := nLabel.Statement;
        Info^.Error^.Statement := nLabel.St;
        Goto RunIt;
      End Else Begin
        ERRStr := nLabel.Name;
        Info^.Error^.Code := SP_ERR_LABEL_NOT_FOUND;
        Exit;
      End;
    End Else Begin
      LineNum := Round(SP_StackPtr^.Val);
      NXTSTATEMENT := -1;
      Dec(SP_StackPtr);
    End;
  End Else
    LineNum := 0;

  If INCLUDEFROM > -1 Then
    ProgLen := INCLUDEFROM
  Else
    ProgLen := SP_Program_Count;

  Idx := 0;
  While (Idx < ProgLen) And (pInteger(@SP_Program[Idx][2])^ < LineNum) Do
    Inc(Idx);

  If Idx < ProgLen Then
    NXTLINE := Idx
  Else
    NXTLINE := -1;

RunIt :

  While Length(ActiveKeys) <> 0 Do
    CB_YIELD;

  SP_CLS(CPAPER);
  SP_GOSUB_STACKLEN := MAXDEPTH;
  SetLength(SP_GOSUB_Stack, SP_GOSUB_STACKLEN);
  SP_GOSUB_STACKPTR := 0;
  IGNORE_ON_ERROR := False;
  Info^.Error^.ReturnType := SP_NEW;
  BREAKSIGNAL := False;
  BPSIGNAL := False;
  If STEPMODE > 0 Then Begin
    SP_CloseEditorWindows;
    STEPMODE := 0;
  End;
  tStr := '';
  SP_PreParse(True, True, Info^.Error^, tStr);
  SP_GetDebugStatus(dbgVariables or dbgWatches);
  Info^.Error^.Code := SP_EXIT; // Preparse forces a compile, which will invalidate pointers to compiled code in the info^ record, so cause a bailout in the calling proc.

End;

Procedure SP_Interpret_GOTO(Var Info: pSP_iInfo);
Var
  LineNum: Integer; nLabel: TSP_Label;
Begin

  If SP_StackPtr^.OpType = SP_LABEL Then Begin
    nLabel := SP_FindLabel(SP_StackPtr^.Str, Info^.Error^);
    Dec(SP_StackPtr);
    If nLabel.Line <> -1 Then Begin
      NXTLINE := nLabel.Line;
      NXTSTATEMENT := nLabel.Statement;
      Info^.Error^.Statement := nLabel.St;
    End Else Begin
      ERRstr := nLabel.Name;
      Info^.Error^.Code := SP_ERR_LABEL_NOT_FOUND;
      Exit;
    End;
  End Else Begin
    LineNum := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    NXTLINE := SP_FindLine(LineNum, False);
    If (NXTLINE > INCLUDEFROM) And (Info^.Error^.Line < INCLUDEFROM) Then NXTLINE := -1;
    NXTSTATEMENT := -1;
  End;
  Info^.Error^.ReturnType := SP_JUMP;

End;

Procedure SP_Interpret_GOTOC(Var Info: pSP_iInfo);
Begin

  Inc(Info^.StrPtr, SizeOf(LongWord));
  If pLongWord(Info^.StrPtr)^ = $80808080 Then Begin
    NXTLINE := SP_FindLine(pLongWord(NativeUInt(Info^.StrPtr)+SizeOf(LongWord))^, False);
    If (NXTLINE > INCLUDEFROM) And (Info^.Error^.Line < INCLUDEFROM) Then NXTLINE := -1;
    pLongWord(Info^.StrPtr)^ := LongWord(NXTLINE);
  End Else
    NXTLINE := pLongWord(Info^.StrPtr)^;

  NXTSTATEMENT := -1;
  Dec(Info^.StrPtr, SizeOf(LongWord));

  Info^.Error^.ReturnType := SP_JUMP;

End;

Procedure SP_Interpret_GOSUBC(Var Info: pSP_iInfo);
Var
  LineItem: TSP_GOSUB_Item;
Begin

  Inc(Info^.StrPtr, SizeOf(LongWord));
  If pLongWord(Info^.StrPtr)^ = $80808080 Then Begin
    NXTLINE := SP_FindLine(pLongWord(NativeUInt(Info^.StrPtr)+SizeOf(LongWord))^, False);
    If (NXTLINE > INCLUDEFROM) And (Info^.Error^.Line < INCLUDEFROM) Then NXTLINE := -1;
    pLongWord(Info^.StrPtr)^ := LongWord(NXTLINE);
  End Else
    NXTLINE := pLongWord(Info^.StrPtr)^;

  NXTSTATEMENT := -1;
  Dec(Info^.StrPtr, SizeOf(LongWord));

  If Info^.Error^.Line >= 0 Then
    LineItem := SP_ConvertLineStatement(Info^.Error^.Line, Info^.Error^.Statement + 1)
  Else Begin
    LineItem.Line := -2;
    LineItem.Statement := SP_FindStatement(@COMMAND_TOKENS, Info^.Error^.Statement + 1);
    If LineItem.Statement = -1 Then
      LineItem.Statement := Info^.Error^.Position;
    LineItem.St := Info^.Error^.Statement + 1;
  End;

  SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_GOSUB, Info^.Error^);
  Info^.Error^.ReturnType := SP_JUMP;

End;

Procedure SP_Interpret_CONTINUE(Var Info: pSP_iInfo);
Var
  Token: pToken;
Begin

  If (CONTLINE >= 0) And (CONTLINE < SP_Program_Count) Then Begin
    NXTLINE := CONTLINE;
    If CONTSTATEMENT = 0 Then Inc(CONTSTATEMENT);
    NXTSTATEMENT := SP_FindStatement(@SP_Program[NXTLINE], CONTSTATEMENT);
    If NXTSTATEMENT = -1 Then Begin
      If NXTLINE < SP_Program_Count -1 Then Begin
        Inc(NXTLINE);
        NXTSTATEMENT := SP_FindStatement(@SP_Program[NXTLINE], 1);
      End Else Begin
        Info^.Error^.Code := SP_ERR_STATEMENT_LOST;
        Exit;
      End;
    End Else Begin
      Token := pToken(@SP_Program[NXTLINE][NXTSTATEMENT]);
      If Token^.BPIndex >= 0 Then
        Inc(SP_SourceBreakPointList[Token^.BPIndex].PassCount);
    End;
    Info^.Error^.Statement := CONTSTATEMENT;
    Info^.Error^.ReturnType := SP_JUMP;
  End Else
    Info^.Error.Code := SP_ERR_STATEMENT_LOST;

End;

Procedure SP_Interpret_GOSUB(Var Info: pSP_iInfo);
Var
  nLabel: TSP_Label;
  LineNum, Stat: Integer;
  LineItem: TSP_GOSUB_Item;
Begin

  With info^ Do Begin
    Stat := -1;
    If SP_StackPtr^.OpType = SP_LABEL Then Begin
      nLabel := SP_FindLabel(SP_StackPtr^.Str, Error^);
      Dec(SP_StackPtr);
      If nLabel.Line <> -1 Then Begin
        NXTLINE := nLabel.Line;
        NXTSTATEMENT := nLabel.Statement;
        Stat := nLabel.St;
      End Else Begin
        ERRStr := nLabel.Name;
        Error^.Code := SP_ERR_LABEL_NOT_FOUND;
        Exit;
      End;
    End Else Begin
      LineNum := Round(SP_StackPtr^.Val);
      Dec(SP_StackPtr);
      NXTLINE := SP_FindLine(LineNum, False);
      If (NXTLINE > INCLUDEFROM) And (Error^.Line < INCLUDEFROM) Then NXTLINE := -1;
      NXTSTATEMENT := -1;
    End;
    If Error^.Line >= 0 Then
      LineItem := SP_ConvertLineStatement(Error^.Line, Error^.Statement + 1)
    Else Begin
      LineItem.Line := -2;
      LineItem.Statement := SP_FindStatement(@COMMAND_TOKENS, Error^.Statement + 1);
      If LineItem.Statement = -1 Then
        LineItem.Statement := Error^.Position;
      LineItem.St := Error^.Statement + 1;
    End;
    If Stat <> -1 Then
      Error^.Statement := Stat;

    SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_GOSUB, Info^.Error^);
    Error^.ReturnType := SP_JUMP;
  End;

End;

Procedure SP_Interpret_RETURN(Var Info: pSP_iInfo);
Begin

  If SP_GOSUB_STACKPTR = 0 Then Begin
    Info^.Error^.Code := SP_ERR_RETURN_WITHOUT_GOSUB;
    Exit;
  End Else Begin
    If SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Source = SP_KW_EVERY Then Begin
      ReEnableEvery := True;
      IGNORE_ON_ERROR := False;
    End;
    NXTLINE := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Line;
    NXTSTATEMENT := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Statement;
    Info^.Error^.Statement := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].St;
    Dec(SP_GOSUB_STACKPTR);
  End;
  Info^.Error^.ReturnType := SP_JUMP;

End;

Procedure SP_Interpret_STOP(Var Info: pSP_iInfo);
Begin

  Info^.Error^.Code := SP_ERR_STOP;

End;

Procedure SP_Interpret_FOR(Var Info: pSP_iInfo);
Var
  VarIdx, varType, i: Integer;
  LineItem: TSP_GOSUB_Item;
  StartFrom, EndAt, Step: aFloat;
  varName: aString;
Begin

  // On entry, the stack contains: From, To and optional Step values,
  // and finally a numeric variable reference.

  StartFrom := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  EndAt := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  varType := SP_StackPtr^.OpType;
  If varType = SP_NUMVAR Then
    Step := 1
  Else Begin
    Step := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
  End;

  With SP_StackPtr^ Do Begin

    With Info^ Do Begin
      VarIdx := Round(Val);
      varName := Str;
      If Error^.Line >= 0 Then Begin
        LineItem := SP_ConvertLineStatement(Error^.Line, Error^.Statement + 1);
      End Else Begin
        LineItem.Line := -2;
        LineItem.Statement := SP_FindStatement(@COMMAND_TOKENS, Error^.Statement + 1);
        LineItem.St := Error^.Statement + 1;
      End;
      SP_UpdateFORVar(VarIdx, varName, StartFrom, EndAt, Step, LineItem.Line, LineItem.Statement, LineItem.St, Ptr, Error^);
      If ((Step > 0) And (StartFrom > EndAt)) or ((Step < 0) And (StartFrom < EndAt)) Then Begin
        i := 0;
        While i < SP_NextCount Do Begin
          If SP_NextEntries[i].VarName = VarName then
            If SP_NextEntries[i].Line = LineItem.Line Then Begin
              If (SP_NextEntries[i].Statement > LineItem.St) or (SP_NextEntries[i].Statement = -1) Then
                Break;
            End Else
              If SP_NextEntries[i].Line > LineItem.Line Then
                Break;
          Inc(i);
        End;
        If i < SP_NextCount Then Begin
          NXTLINE := SP_NextEntries[i].Line;
          NXTSTATEMENT := SP_NextEntries[i].Statement;
          If NXTStatement = -1 then
            NXTLINE := -1;
          Error.Statement := LineItem.St;
          Error.ReturnType := SP_JUMP;
        End;
      End;
    End;

  End;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_NEXT(Var Info: pSP_iInfo);
Var
  VarIdx: Integer;
  Tkns: paString;
  rType: Byte;
Begin

  With Info^ Do Begin

    With SP_StackPtr^ Do Begin

      If OpType = SP_NUMVAR Then Begin

        VarIdx := Round(Val);
        If VarIdx = 0 Then Begin
          VarIdx := SP_FindNumVar(Str);
          If VarIdx = -1 Then Begin
            Error.Code := SP_ERR_MISSING_VAR;
            Error.Position := Integer(tPos);
            Exit;
          End Else Begin
            If Not NumVars[VarIdx]^.ProcVar Then
              Ptr^ := VarIdx + 1;
          End;
        End Else
          Dec(VarIdx);

        With NumVars[VarIdx]^.ContentPtr^ Do Begin

          Case NumVars[VarIdx]^.Content.VarType Of

            SP_FOREACH:
              Begin

                // If this is a FOR EACH type, then FOR information will be stored in
                // the local content, not the addressed content.

                With NumVars[VarIdx]^ Do Begin
                  Inc(Content.EachArrayIndex, Round(Content.Step));
                  If Content.EachArrayIndex < Length(NumArrays[Content.EachIndex].Values) Then Begin
                    ContentPtr := NumArrays[Content.EachIndex].Values[Content.EachArrayIndex];
                    NXTLINE := Content.LoopLine;
                    NXTSTATEMENT := Content.LoopStatement;
                    Error.Statement := Content.St;
                    Error.ReturnType := SP_JUMP;
                  End Else Begin
                    Error.ReturnType := SP_VALUE;
                    Content.Value := ContentPtr^.Value;
                    ContentPtr := @Content;
                  End;
                End;

              End;

            SP_FORVAR:
              Begin

                // Try to limit fp-rounding errors by comparing what we should be to what we have.
                // If there's a difference then the user probably modified the variable manually

                Inc(Count);
                If InitVal + (Step * (Count -1)) <> Value Then
                  Value := Value + Step
                Else
                  Value := InitVal + (Step * Count);

                If Step > 0 Then Begin

                  If Value + Step <= EndAt + Step Then Begin
                    NXTLINE := LoopLine;
                    NXTSTATEMENT := LoopStatement;
                    Error.Statement := St;
                    Error.ReturnType := SP_JUMP;
                  End Else Begin
                    Error.ReturnType := SP_VALUE;
                    Dec(SP_StackPtr);
                    Exit;
                  End;

                End Else Begin

                  If Value + Step >= EndAt + Step Then Begin
                    NXTLINE := LoopLine;
                    NXTSTATEMENT := LoopStatement;
                    Error.Statement := St;
                    Error.ReturnType := SP_JUMP;
                  End Else Begin
                    Error.ReturnType := SP_VALUE;
                    Dec(SP_StackPtr);
                    Exit;
                  End;

                End;

              End;

            SP_FOREACHRANGE:
              Begin

                // A FOR EACH variable with a range.
                // Increment the value string by STEP bytes, then test if it's less than or equal to the RANGEMAX value.
                // If so, all is good. Otherwise - get the next range info and interpret it.

                Value := Value + RangeStep;

                If ((RangeStep > 0) and (Value > RangeMax)) or ((RangeStep < 0) and (Value < RangeMax)) Then Begin

                  // Another range available?

                  Inc(EachIndex);
                  If EachIndex < Count Then Begin

                    Tkns := @EachTokens;
                    rType := Byte(EachTokens[EachPtr]);
                    Inc(EachPtr, SizeOf(TToken));
                    SP_InterpretCONTSafe(Tkns, EachPtr, Error^);

                    If Error.Code = SP_ERR_OK Then Begin

                      Case rType of
                        SP_EACHSINGLE:
                          Begin
                            Value := SP_StackPtr^.Val;
                            RangeMin := Value;
                            RangeMax := Value;
                            RangeStep := 1;
                            Dec(SP_StackPtr);
                          End;
                        SP_EACHRANGE:
                          Begin
                            RangeMax := SP_StackPtr^.Val;
                            Dec(SP_StackPtr);
                            RangeMin := SP_StackPtr^.Val;
                            Value := RangeMin;
                            Dec(SP_StackPtr);
                            RangeStep := 1;
                          End;
                        SP_EACHSTEP:
                          Begin
                            RangeStep := SP_StackPtr^.Val;
                            Dec(SP_StackPtr);
                            RangeMax := SP_StackPtr^.Val;
                            Dec(SP_StackPtr);
                            RangeMin := SP_StackPtr^.Val;
                            Value := RangeMin;
                            Dec(SP_StackPtr);
                          End;
                      End;

                      // Jump to the stored line/statement.

                      NXTLINE := LoopLine;
                      NXTSTATEMENT := LoopStatement;
                      Error.Statement := St;
                      Error.ReturnType := SP_JUMP;

                    End;

                  End Else Begin

                    // no more ranges, so bail.

                    Error.ReturnType := SP_STRING;

                  End;

                End Else Begin

                  // All good, jump to the stored line/statement

                  NXTLINE := LoopLine;
                  NXTSTATEMENT := LoopStatement;
                  Error.Statement := St;
                  Error.ReturnType := SP_JUMP;

                End;

              End;

            Else
              Begin

                Error.Code := SP_ERR_NEXT_WITHOUT_FOR;
                Error.Position := tPos;
                Exit;

              End;

          End;

        End;

      End Else Begin

        // a string var *must* be a FOR EACH loop! Makes no sense otherwise ;)
        // But which type?

        VarIdx := Round(Val);
        If VarIdx = 0 Then Begin
          VarIdx := SP_FindStrVar(Str);
          If VarIdx = -1 Then Begin
            Error.Code := SP_ERR_MISSING_VAR;
            Error.Position := tPos;
            Exit;
          End Else Begin
            If Not StrVars[VarIdx]^.ProcVar Then
              Ptr^ := VarIdx + 1;
          End;
        End Else
          Dec(VarIdx);

        If StrVars[VarIdx].Content.VarType = SP_FOREACH Then Begin
          With StrVars[VarIdx]^ Do Begin
            Inc(Content.EachArrayIndex, Round(Content.Step));
            If Content.EachArrayIndex < Length(StrArrays[Content.EachIndex].Strings) Then Begin
              ContentPtr := StrArrays[Content.EachIndex].Strings[Content.EachArrayIndex];
              NXTLINE := Content.LoopLine;
              NXTSTATEMENT := Content.LoopStatement;
              Error.Statement := Content.St;
              Error.ReturnType := SP_JUMP;
            End Else Begin
              Error.ReturnType := SP_VALUE;
              ContentPtr := @Content;
            End;
          End;

        End Else

          With StrVars[VarIdx]^.ContentPtr^ Do Begin

            If VarType = SP_FOREACHRANGE Then Begin

              // A FOR EACH variable with a range.
              // Increment the value string by STEP bytes, then test if it's less than or equal to the RANGEMAX value.
              // If so, all is good. Otherwise - get the next range info and interpret it.

              Value := aChar(Byte(Value[1]) + RangeStep);

              If ((RangeStep > 0) and (Byte(Value[1]) > RangeMax)) or ((RangeStep < 0) and (Byte(Value[1]) < RangeMax)) Then Begin

                // Another range available?

                Inc(EachIndex);
                If EachIndex < Count Then Begin

                  Tkns := @EachTokens;
                  rType := Byte(EachTokens[EachPtr]);
                  Inc(EachPtr, SizeOf(TToken));
                  SP_InterpretCONTSafe(Tkns, EachPtr, Error^);

                  If Error.Code = SP_ERR_OK Then Begin

                    Case rType of
                      SP_EACHSINGLE:
                        Begin
                          Value := SP_StackPtr^.Str;
                          RangeMin := Byte(Value[1]);
                          RangeMax := Byte(Value[1]);
                          RangeStep := 1;
                          Dec(SP_StackPtr);
                        End;
                      SP_EACHRANGE:
                        Begin
                          RangeMax := Byte(SP_StackPtr^.Str[1]);
                          Dec(SP_StackPtr);
                          RangeMin := Byte(SP_StackPtr^.Str[1]);
                          Value := aChar(RangeMin);
                          Dec(SP_StackPtr);
                          RangeStep := 1;
                        End;
                      SP_EACHSTEP:
                        Begin
                          RangeStep := Round(SP_StackPtr^.Val);
                          Dec(SP_StackPtr);
                          RangeMax := Byte(SP_StackPtr^.Str[1]);
                          Dec(SP_StackPtr);
                          RangeMin := Byte(SP_StackPtr^.Str[1]);
                          Value := aChar(RangeMin);
                          Dec(SP_StackPtr);
                        End;
                    End;

                    // Jump to the stored line/statement.

                    NXTLINE := LoopLine;
                    NXTSTATEMENT := LoopStatement;
                    Error.Statement := St;
                    Error.ReturnType := SP_JUMP;

                  End;

                End Else Begin

                  // no more ranges, so bail.

                  Error.ReturnType := SP_STRING;

                End;

              End Else Begin

                // All good, jump to the stored line/statement

                NXTLINE := LoopLine;
                NXTSTATEMENT := LoopStatement;
                Error.Statement := St;
                Error.ReturnType := SP_JUMP;

              End;

            End Else

              If VarType = SP_FOREACHSTRING Then Begin

                Inc(EachIndex);

                If EachIndex <= Length(EachTokens) Then Begin

                  Value := aChar(EachTokens[EachIndex]);

                  NXTLINE := LoopLine;
                  NXTSTATEMENT := LoopStatement;
                  Error.Statement := St;
                  Error.ReturnType := SP_JUMP;

                End Else

                  Error.ReturnType := SP_STRING;

              End Else

                Error.Code := SP_ERR_NEXT_WITHOUT_FOR;

          End;

      End;

    End;

  End;

  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_IF(Var Info: pSP_iInfo);
Var
  Tkn: pToken;
  IF_Counter: LongWord;
  Offset: LongWord;
  PtrSave: pByte;
Begin

  With Info^ Do Begin
    Dec(SP_StackPtr);
    If pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Val = 0 Then Begin
      If SP_StackPtr <> SP_StackStart Then Begin
        Offset := pLongWord(StrPosPtr(Tokens, SP_StackPtr^.tPos))^;
        Position := SP_StackPtr^.tPos;
        Dec(SP_StackPtr);
        If Offset = 0 Then Begin
          PtrSave := StrPtr;
          IF_Counter := 0;
          Inc(StrPtr, Token^.TokenLen);
          While True Do Begin
            Tkn := pToken(StrPtr);
            Inc(StrPtr, SizeOf(TToken));
            Case Tkn^.Token of
              SP_KEYWORD: Begin
                  Case pLongWord(StrPtr)^ Of
                    SP_KW_ELSE, SP_KW_ENDIF:
                      Begin
                        If IF_Counter = 0 Then Begin
                          Offset := StrPtr - PtrSave;
                          pLongWord(StrPosPtr(Tokens, Position))^ := Offset;
                          Inc(Error^.Statement);
                          Exit;
                        End Else Begin
                          If pLongWord(StrPtr)^ <> SP_KW_ELSE Then
                            Dec(IF_Counter);
                          Inc(StrPtr, Tkn^.TokenLen);
                        End;
                      End;
                    SP_KW_IF:
                      Begin
                        Inc(IF_Counter);
                        Inc(StrPtr, Tkn^.TokenLen);
                      End;
                  Else
                    Inc(StrPtr, Tkn^.TokenLen);
                  End;
                End;
            Else
              If Tkn^.Token = 255 Then Begin
                Offset := StrPtr - PtrSave - SizeOf(TToken) - SizeOf(LongWord);
                pLongWord(StrPosPtr(Tokens, Position))^ := Offset;
                Error.ReturnType := SP_JUMP;
                Exit;
              End Else
                Inc(StrPtr, Tkn^.TokenLen);
            End;
          End;
        End Else Begin
          Inc(StrPtr, Offset);
          Inc(Error^.Statement);
        End;
      End Else
        Error.ReturnType := SP_JUMP;
    End Else Begin
      Inc(Error^.Statement);
      If SP_StackPtr <> SP_StackStart Then
        Dec(SP_StackPtr);
    End;
  End;

End;

Procedure SP_Interpret_ELSE(Var Info: pSP_iInfo);
Var
  Tkn: pToken;
  Offset, IF_Counter: LongWord;
  PtrSave: pByte;
Begin

  With Info^ Do Begin
    If SP_StackPtr <> SP_StackStart Then Begin
      Position := SP_StackPtr^.tPos;
      Offset := pLongWord(StrPosPtr(Tokens, Position))^;
      Dec(SP_StackPtr);
      If Offset = 0 Then Begin
        PtrSave := StrPtr;
        IF_Counter := 0;
        Inc(StrPtr, Token^.TokenLen);
        While True Do Begin
          Tkn := pToken(StrPtr);
          Inc(StrPtr, SizeOf(TToken));
          Case Tkn^.Token of
            255:
              Begin
                Offset := StrPtr - PtrSave - SizeOf(TToken) - SizeOf(LongWord);
                pLongWord(StrPosPtr(Tokens, Position))^ := Offset;
                Error^.ReturnType := SP_JUMP;
                Exit;
              End;
            SP_KEYWORD: Begin
                Case pLongWord(StrPtr)^ Of
                  SP_KW_ENDIF:
                    Begin
                      If IF_Counter = 0 Then Begin
                        Offset := StrPtr - PtrSave;
                        pLongWord(StrPosPtr(Tokens, Position))^ := Offset;
                        Inc(Error^.Statement);
                        Exit;
                      End Else Begin
                        Dec(IF_Counter);
                        Inc(StrPtr, Tkn^.TokenLen);
                      End;
                    End;
                  SP_KW_IF:
                    Begin
                      Inc(IF_Counter);
                      Inc(StrPtr, Tkn^.TokenLen);
                    End;
                Else
                  Inc(StrPtr, Tkn^.TokenLen);
                End;
              End;
          Else
            Inc(StrPtr, Tkn^.TokenLen);
          End;
        End;
      End Else Begin
        Inc(StrPtr, Offset);
        Inc(Error^.Statement);
      End;
    End Else
      Error^.ReturnType := SP_JUMP;
  End;

End;

Procedure SP_Interpret_Embedded_Colours(Var Info: pSP_iInfo);
Var
  Str: aString;
Begin

  Exit;

  T_INK := CINK;
  T_PAPER := CPAPER;
  T_INVERSE := CINVERSE;
  T_OVER := COVER;

  If SP_StackPtr <> SP_StackStart Then
    While SP_StackPtr^.OpType = SP_STRING Do Begin
      Str := SP_StackPtr^.Str;
      Case Byte(Str[1]) of
        16: // INK
          Begin
            T_INK := pLongWord(@Str[2])^;
          End;
        17: // PAPER
          Begin
            T_PAPER := pLongWord(@Str[2])^;
          End;
        18: // OVER
          Begin
            T_OVER := pByte(@Str[2])^;
          End;
        20: // INVERSE
          Begin
            T_INVERSE := pByte(@Str[2])^;
          End;
      Else
        Exit;
      End;
      Dec(SP_StackPtr);
      If SP_StackPtr = SP_StackStart Then
        Break;
    End;

End;

Procedure SP_Interpret_PLOT(Var Info: pSP_iInfo);
Var
  YPos, XPos, Radius: Integer;
  VarName: aString;
  dX, dY: aFloat;
  Idx, iSize, vIdx, pIdx: Integer;
Begin

  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
      Dec(SP_StackPtr);
      Idx := 0;
      While Idx < Length(NumArrays) Do Begin
        If NumArrays[Idx].Name = VarName Then Begin
          // Array passed - (x, y [,colour [,radius]])
          If NumArrays[Idx].NumIndices >= 2 Then Begin
            iSize := NumArrays[Idx].Indices[1];
            Case iSize of
              2: // x/y info only
                Begin
                  vIdx := 0;
                  For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
                    dX := NumArrays[Idx].Values[vIdx]^.Value;
                    dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
                    Inc(vIdx, iSize);
                    SP_ConvertToOrigin_d(dX, dY);
                    If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dy;
                    If SCREENBPP = 8 Then
                      SP_SetPixel(dX, dY)
                    Else
                      SP_SetPixel32(dX, dY);
                  End;
                End;
              3: // x/y/colour
                Begin
                  vIdx := 0;
                  For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
                    dX := NumArrays[Idx].Values[vIdx]^.Value;
                    dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
                    T_INK := Round(NumArrays[Idx].Values[vIdx + 2]^.Value);
                    Inc(vIdx, iSize);
                    SP_ConvertToOrigin_d(dX, dY);
                    If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dy;
                    If SCREENBPP = 8 Then
                      SP_SetPixel(dX, dY)
                    Else
                      SP_SetPixel32(dX, dY);
                  End;
                End;
              4..10: // x/y/colour/radius
                Begin
                  vIdx := 0;
                  For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
                    dX := NumArrays[Idx].Values[vIdx]^.Value;
                    dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
                    T_INK := Round(NumArrays[Idx].Values[vIdx + 2]^.Value);
                    Radius := Round(NumArrays[Idx].Values[vIdx + 3]^.Value);
                    Inc(vIdx, iSize);
                    SP_ConvertToOrigin_d(dX, dY);
                    If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dy;
                    If Radius < 1 Then Begin
                      If SCREENBPP = 8 Then
                        SP_SetPixel(dX, dY)
                      Else
                        SP_SetPixel32(dX, dY);
                    End Else
                      If SCREENBPP = 8 Then
                        SP_DrawSolidEllipse(Round(dX), Round(dY), Radius, Radius)
                      Else
                        SP_DrawSolidEllipse32(Round(dX), Round(dY), Radius, Radius);
                  End;
                End;
            End;
            If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, SCREENWIDTH, SCREENHEIGHT);
            Exit;
          End Else
            Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
        End;
        Inc(Idx);
      End;
      ERRStr := VarName;
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
    End Else
      Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
  End Else Begin
    dY := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    dX := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    SP_ConvertToOrigin_d(dX, dY);
    If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dy;
    {$R-}
    xPos := Round(dX); yPos := Round(dY);
    If SCREENBPP = 8 Then
      SP_SetPixel(xPos, yPos)
    Else
      SP_SetPixel32(xPos, yPos);
    If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + XPos, SCREENY + YPos, SCREENX + XPos, SCREENY + YPos);
    {$R+}
  End;

  SP_BankList[0]^.Changed := True;
  SP_NeedDisplayUpdate := True;
  SKIPFIRSTPOINT := True;

End;

Procedure SP_Interpret_FORCE(Var Info: pSP_iInfo);
Var
  VarName: aString;
  Idx, iSize, nPart, pIdx, vIdx: Integer;
  GravHeading, GravMag, gx, gy: aFloat;
  cdx, cdy: paFloat;
Const
  pdx = 5; pdy = 6;
Begin
  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
      Dec(SP_StackPtr);
      Idx := 0;
      While Idx < Length(NumArrays) Do Begin
        If NumArrays[Idx].Name = VarName Then Begin
          // Array passed - but this must have x,y,colour,radius *and* mass, dx and dy.
          If NumArrays[Idx].NumIndices = 2 Then Begin
            iSize := NumArrays[Idx].Indices[1];
            If iSize >= 7 Then Begin
              GravHeading := SP_StackPtr^.Val;
              Dec(SP_StackPtr);
              GravMag := SP_StackPtr^.Val;
              Dec(SP_StackPtr);
              SP_AngleToRad(GravHeading);
              gx := GravMag * Cos(GravHeading);
              gy := GravMag * Sin(GravHeading);
              nPart := NumArrays[Idx].Indices[0];
              pIdx := 0;
              While pIdx < nPart Do Begin
                vIdx := pIdx * iSize;
                With NumArrays[Idx] Do Begin
                  cdx := @Values[vIdx + pdx]^.Value;
                  cdy := @Values[vIdx + pdy]^.Value;
                  cdx^ := cdx^ + gx;
                  cdy^ := cdy^ + gy;
                End;
                Inc(pIdx);
              End;
              Exit;
            End Else Begin
              Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
              Exit;
            End;
          End;
        End;
        Inc(Idx);
      End;
      ERRStr := VarName;
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
    End Else
      Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
  End Else
    Info^.Error^.Code := SP_ERR_INVALID_ARRAY_VAR;
End;

Procedure SP_Interpret_PARTICLE(Var Info: pSP_iInfo);
Var
  VarName: aString;
  Idx, iSize, vIdx, pIdx, nIdx, nPart, Ofs: Integer;
  Friction, GravHeading, GravMag, cDist, aDist,
  cna, nx, ny, a1, a2, op, md1, md2, xd, yd, gx, gy,
  cpm, npm, cmass, nmass, refrict: aFloat;
  cpx, cpy, npx, npy, cdx, cdy, ndx, ndy, cpr, npr: paFloat;
Const
  px = 0; py = 1; pc = 2; pr = 3; pm = 4; pdx = 5; pdy = 6;
Begin

  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
      Dec(SP_StackPtr);
      Idx := 0;
      While Idx < Length(NumArrays) Do Begin
        If NumArrays[Idx].Name = VarName Then Begin
          // Array passed - but this must have x,y,colour,radius *and* mass, dx and dy.
          If NumArrays[Idx].NumIndices = 2 Then Begin
            iSize := NumArrays[Idx].Indices[1];
            If iSize >= 7 Then Begin
              Friction := SP_StackPtr^.Val;
              Dec(SP_StackPtr);
              GravHeading := SP_StackPtr^.Val;
              Dec(SP_StackPtr);
              GravMag := SP_StackPtr^.Val;
              Dec(SP_StackPtr);
              If GravMag = 0 Then
                Refrict := 1
              Else
                Refrict := Friction;
              SP_AngleToRad(GravHeading);
              gx := GravMag * Cos(GravHeading);
              gy := GravMag * Sin(GravHeading);
              nPart := NumArrays[Idx].Indices[0];
              pIdx := 0;
              While pIdx < nPart Do Begin
                vIdx := pIdx * iSize;
                With NumArrays[Idx] Do Begin
                  cpx := @Values[vIdx + px]^.Value;
                  cpy := @Values[vIdx + py]^.Value;
                  cpr := @Values[vIdx + pr]^.Value;
                  cdx := @Values[vIdx + pdx]^.Value;
                  cdy := @Values[vIdx + pdy]^.Value;
                  cpm := Values[vIdx + pm]^.Value;
                  cmass := cpm;
                  cpx^ := cpx^ + cdx^;
                  cpy^ := cpy^ + cdy^;
                  If cpm <> 0 Then Begin
                    If GravMag = 0 Then Begin
                      cdx^ := cdx^ * Friction;
                      cdy^ := cdy^ * Friction;
                    End Else Begin
                      cdx^ := cdx^ + gx;
                      cdy^ := cdy^ + gy;
                    End;
                  End;
                  nIdx := 0;
                  If cpm > 0 Then While nIdx < nPart Do Begin
                    If nIdx <> pIdx Then Begin
                      Ofs := nIdx * iSize;
                      npr := @Values[Ofs + pr]^.Value;
                      npx := @Values[Ofs + px]^.Value;
                      npy := @Values[Ofs + py]^.Value;
                      cDist := cpr^ + npr^;
                      xd := npx^ - cpx^; yd := npy^ - cpy^;
                      aDist := Sqrt(Sqr(xd)+Sqr(yd));
                      If aDist <= cDist Then Begin
                        npm := Values[Ofs + pm]^.Value;
                        If npm = 0 Then nmass := 1E300 else nmass := npm;
                        ndx := @Values[Ofs + pdx]^.Value;
                        ndy := @Values[Ofs + pdy]^.Value;
                        cNa := ArcTan2(yd, xd);
                        md1 := (cDist - aDist) * (nmass/(cmass+nmass));
                        md2 := (cDist - aDist) * (cmass/(cmass+nmass));
                        nx := Cos(cNa); ny := Sin(cNa);
                        If cpm > 0 Then Begin
                          cpx^ := cpx^ + md1*Cos(cNa + Pi);
                          cpy^ := cpy^ + md1*Sin(cNa + Pi);
                        End;
                        If npm > 0 Then Begin
                          npx^ := npx^ + md2*nx;
                          npy^ := npy^ + md2*ny;
                        End;
                        a1 := cdx^*nx + cdy^*ny;
                        a2 := ndx^*nx + ndy^*ny;
                        op := (2 * (a1 - a2)) / (cmass + nmass);
                        If cpm > 0 Then Begin
                          cdx^ := cdx^ - (op * nmass * nx) * refrict;
                          cdy^ := cdy^ - (op * nmass * ny) * refrict;
                        End;
                        If npm > 0 Then Begin
                          ndx^ := ndx^ + (op * cmass * nx) * refrict;
                          ndy^ := ndy^ + (op * cmass * ny) * refrict;
                        End;
                      End;
                    End;
                    Inc(nIdx);
                  End;
                End;
                Inc(pIdx);
              End;
              Exit;
            End Else Begin
              Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
              Exit;
            End;
          End;
        End;
        Inc(Idx);
      End;
      ERRStr := VarName;
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
    End Else
      Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
  End Else
    Info^.Error^.Code := SP_ERR_INVALID_ARRAY_VAR;
End;

Procedure SP_Interpret_PAUSE(Var Info: pSP_iInfo);
Var
  Delay: Integer;
Begin

  Delay := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If Delay > 0 Then Begin
    Delay := FRAMES + Delay;
    Repeat
      CB_YIELD;
    Until (FRAMES = Delay) or (Length(ActiveKeys) <> 0);
  End Else
    Repeat
      CB_YIELD;
    Until Length(ActiveKeys) <> 0;

  If KEYSTATE[K_ESCAPE] = 1 Then BreakSignal := True;

End;

Procedure SP_Interpret_DRAW(Var Info: pSP_iInfo);
Var
  Angle, YPos, XPos: aFloat; NumParams: Integer;
  Sp1: pSP_StackItem;
Begin

  Angle := 0;

  NumParams := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If NumParams = 3 Then Begin
    Angle := SP_StackPtr^.Val;
    If WINFLIPPED Then Angle := -Angle;
    Dec(SP_StackPtr);
  End;

  Sp1 := SP_StackPtr;
  Dec(Sp1);
  SP_ConvertToOrigin_d(Sp1^.Val, SP_StackPtr^.Val);

  YPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  XPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If WINFLIPPED Then YPos := -Ypos;

  If SCREENBPP = 8 Then Begin
    If NumParams = 2 Then
      SP_DrawLine(XPos, YPos)
    Else
      SP_DrawSpeccyCurve(XPos, YPos, Angle);
  End Else Begin
    If NumParams = 2 Then
      SP_DrawLine32(XPos, YPos)
    Else
      SP_DrawSpeccyCurve32(XPos, YPos, Angle);
  End;

  SP_NeedDisplayUpdate := True;
  SKIPFIRSTPOINT := True;

End;

Procedure SP_Interpret_DRAWTO(Var Info: pSP_iInfo);
Var
  YPos, XPos, Angle: aFloat; NumParams: Integer;
  sp1: pSP_StackItem;
Begin

  Angle := 0;
  NumParams := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If NumParams = 3 Then Begin
    Angle := SP_StackPtr^.Val;
    If WINFLIPPED Then Angle := -Angle;
    Dec(SP_StackPtr);
  End;

  sp1 := SP_StackPtr;
  Dec(sp1);
  SP_ConvertToOrigin_d(Sp1^.Val, SP_StackPtr^.Val);

  YPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  XPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If WINFLIPPED Then YPos := (SCREENHEIGHT - 1) - YPos;

  If SCREENBPP = 8 Then Begin
    If NumParams = 2 Then
      SP_DrawLine(XPos - DRPOSX, YPos - DRPOSY)
    Else
      SP_DrawSpeccyCurve(XPos - DRPOSX, YPos - DRPOSY, Angle);
  End Else Begin
    If NumParams = 2 Then
      SP_DrawLine32(XPos - DRPOSX, YPos - DRPOSY)
    Else
      SP_DrawSpeccyCurve32(XPos - DRPOSX, YPos - DRPOSY, Angle);
  End;
  SP_NeedDisplayUpdate := True;
  SKIPFIRSTPOINT := True;

End;

Procedure SP_Interpret_DRAW_CTO(Var Info: pSP_iInfo);
Var
  YPos, XPos, dXPos, dYPos, Angle: aFloat; NumParams: Integer;
  Sp1, Sp2: pSP_StackItem;
Begin

  Angle := 0;
  NumParams := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If NumParams = 3 Then Begin
    Angle := SP_StackPtr^.Val;
    If WINFLIPPED Then Angle := -Angle;
    Dec(SP_StackPtr);
  End;

  Sp1 := SP_StackPtr;
  Dec(Sp1);

  SP_ConvertToOrigin_d(Sp1^.Val, SP_StackPtr^.Val);
  Dec(Sp1);
  Sp2 := Sp1;
  Dec(Sp2);
  SP_ConvertToOrigin_d(Sp2^.Val, Sp1^.Val);

  YPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  XPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dYPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dXPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If WINFLIPPED Then Begin
    YPos := (SCREENHEIGHT - 1) - YPos;
    dYPos := (SCREENHEIGHT - 1) - dYPos;
  End;

  SKIPFIRSTPOINT := False;
  DRPOSX := dXPos;
  DRPOSY := dYPos;

  If SCREENBPP = 8 Then Begin
    If NumParams = 2 Then
      SP_DrawLine(XPos - dXPos, YPos - dYPos)
    Else
      SP_DrawSpeccyCurve(XPos - dXPos, YPos - dYPos, Angle);
  End Else Begin
    If NumParams = 2 Then
      SP_DrawLine32(XPos - dXPos, YPos - dYPos)
    Else
      SP_DrawSpeccyCurve32(XPos - dXPos, YPos - dYPos, Angle);
  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_DRAW_GW(Var Info: pSP_iInfo);
Begin

  SP_DRAWGW(SP_StackPtr^.Str, Info^.Error^);
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_MULTIDRAW(Var Info: pSP_iInfo);
Var
  VarName: aString;
  dX, dY, dZ: aFloat;
  Idx, iSize, vIdx, pIdx: Integer;
Begin

  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    Dec(SP_StackPtr);
    Idx := 0;
    While Idx < Length(NumArrays) Do Begin
      If NumArrays[Idx].Name = VarName Then Begin
        If NumArrays[Idx].NumIndices = 2 Then Begin
          iSize := NumArrays[Idx].Indices[1];
          If iSize = 2 Then Begin
            vIdx := 0;
            For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
              dX := NumArrays[Idx].Values[vIdx]^.Value;
              dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
              Inc(vIdx, iSize);
              SP_ConvertToOrigin_d(dX, dY);
              If WINFLIPPED Then dY := -dy;
              If SCREENBPP = 8 Then
                SP_DrawLine(dX, dY)
              Else
                SP_DrawLine32(dX, dY);
            End;
            If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, SCREENWIDTH, SCREENHEIGHT);
            Exit;
          End Else
            If iSize >= 3 Then Begin
              vIdx := 0;
              For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
                dX := NumArrays[Idx].Values[vIdx]^.Value;
                dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
                dZ := NumArrays[Idx].Values[vIdx + 2]^.Value;
                Inc(vIdx, iSize);
                SP_ConvertToOrigin_d(dX, dY);
                If WINFLIPPED Then Begin
                  dY := -dY;
                  dZ := -dZ;
                End;
                If SCREENBPP = 8 Then
                  SP_DrawSpeccyCurve(dX, dY, dZ)
                Else
                  SP_DrawSpeccyCurve32(dX, dY, dZ);
              End;
              If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, SCREENWIDTH, SCREENHEIGHT);
              Exit;
            End Else
              Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
        End Else
          Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
      End;
      Inc(Idx);
    End;
    ERRStr := VarName;
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
  End Else
    Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

End;

Procedure SP_Interpret_MULTIDRAW_TO(Var Info: pSP_iInfo);
Var
  VarName: aString;
  dX, dY, dZ: aFloat;
  Idx, iSize, vIdx, pIdx: Integer;
Begin

  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    Dec(SP_StackPtr);
    Idx := 0;
    While Idx < Length(NumArrays) Do Begin
      If NumArrays[Idx].Name = VarName Then Begin
        If NumArrays[Idx].NumIndices = 2 Then Begin
          iSize := NumArrays[Idx].Indices[1];
          If iSize = 2 Then Begin
            vIdx := 0;
            For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
              dX := NumArrays[Idx].Values[vIdx]^.Value;
              dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
              Inc(vIdx, iSize);
              SP_ConvertToOrigin_d(dX, dY);
              If WINFLIPPED Then dY := -dy;
              If SCREENBPP = 8 Then
                SP_DrawLine(dX - DRPOSX, dY - DRPOSY)
              Else
                SP_DrawLine32(dX - DRPOSX, dY - DRPOSY)
            End;
            If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, SCREENWIDTH, SCREENHEIGHT);
            Exit;
          End Else
            If iSize >= 3 Then Begin
              vIdx := 0;
              For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
                dX := NumArrays[Idx].Values[vIdx]^.Value;
                dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
                dZ := NumArrays[Idx].Values[vIdx + 2]^.Value;
                Inc(vIdx, iSize);
                SP_ConvertToOrigin_d(dX, dY);
                If WINFLIPPED Then Begin
                  dY := -dY;
                  dZ := -dZ;
                End;
                If SCREENBPP = 8 Then
                  SP_DrawSpeccyCurve(dX - DRPOSX, dY - DRPOSY, dZ)
                Else
                  SP_DrawSpeccyCurve32(dX - DRPOSX, dY - DRPOSY, dZ)
              End;
              If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, SCREENWIDTH, SCREENHEIGHT);
              Exit;
            End Else
              Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
        End Else
          Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
      End;
      Inc(Idx);
    End;
    ERRStr := VarName;
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
  End Else
    Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

End;

Procedure SP_Interpret_AMULTIDRAW(Var Info: pSP_iInfo);
Var
  VarName: aString;
  dX, dY, dZ: aFloat;
  Idx, iSize, vIdx, pIdx: Integer;
Begin

  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    Dec(SP_StackPtr);
    Idx := 0;
    While Idx < Length(NumArrays) Do Begin
      If NumArrays[Idx].Name = VarName Then Begin
        If NumArrays[Idx].NumIndices = 2 Then Begin
          iSize := NumArrays[Idx].Indices[1];
          If iSize = 2 Then Begin
            vIdx := 0;
            For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
              dX := NumArrays[Idx].Values[vIdx]^.Value;
              dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
              Inc(vIdx, iSize);
              SP_ConvertToOrigin_d(dX, dY);
              If WINFLIPPED Then dY := -dy;
              SP_DrawLine32Alpha(dX, dY);
            End;
            If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, SCREENWIDTH, SCREENHEIGHT);
            Exit;
          End Else
            If iSize >= 3 Then Begin
              vIdx := 0;
              For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
                dX := NumArrays[Idx].Values[vIdx]^.Value;
                dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
                dZ := NumArrays[Idx].Values[vIdx + 2]^.Value;
                Inc(vIdx, iSize);
                SP_ConvertToOrigin_d(dX, dY);
                If WINFLIPPED Then Begin
                  dY := -dY;
                  dZ := -dZ;
                End;
                SP_DrawSpeccyCurve32Alpha(dX, dY, dZ);
              End;
              If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, SCREENWIDTH, SCREENHEIGHT);
              Exit;
            End Else
              Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
        End Else
          Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
      End;
      Inc(Idx);
    End;
    ERRStr := VarName;
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
  End Else
    Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

End;

Procedure SP_Interpret_AMULTIDRAW_TO(Var Info: pSP_iInfo);
Var
  VarName: aString;
  dX, dY, dZ: aFloat;
  Idx, iSize, vIdx, pIdx: Integer;
Begin

  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    Dec(SP_StackPtr);
    Idx := 0;
    While Idx < Length(NumArrays) Do Begin
      If NumArrays[Idx].Name = VarName Then Begin
        If NumArrays[Idx].NumIndices = 2 Then Begin
          iSize := NumArrays[Idx].Indices[1];
          If iSize = 2 Then Begin
            vIdx := 0;
            For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
              dX := NumArrays[Idx].Values[vIdx]^.Value;
              dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
              Inc(vIdx, iSize);
              SP_ConvertToOrigin_d(dX, dY);
              If WINFLIPPED Then dY := -dY;
              SP_DrawLine32Alpha(dX - DRPOSX, dY - DRPOSY)
            End;
            If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, SCREENWIDTH, SCREENHEIGHT);
            Exit;
          End Else
            If iSize >= 3 Then Begin
              vIdx := 0;
              For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
                dX := NumArrays[Idx].Values[vIdx]^.Value;
                dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
                dZ := NumArrays[Idx].Values[vIdx + 2]^.Value;
                Inc(vIdx, iSize);
                SP_ConvertToOrigin_d(dX, dY);
                If WINFLIPPED Then Begin
                  dY := -dY;
                  dZ := -dZ;
                End;
                SP_DrawSpeccyCurve32Alpha(dX - DRPOSX, dY - DRPOSY, dZ)
              End;
              If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, SCREENWIDTH, SCREENHEIGHT);
              Exit;
            End Else
              Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
        End Else
          Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
      End;
      Inc(Idx);
    End;
    ERRStr := VarName;
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
  End Else
    Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

End;

Procedure SP_Interpret_CIRCLE(Var Info: pSP_iInfo);
Var
  R, dX, dY, Aspect, Radius1, Radius2: aFloat;
  xPos, yPos: Integer;
Begin

  Aspect := (ScaleWidth/DisplayWidth)/(ScaleHeight/DisplayHeight);
  If WINSCALE Then Begin
    R := SP_StackPtr^.Val;
    Radius1 := R/WINSCALEX;
    Radius2 := R/WINSCALEY;
    Aspect := Aspect * (WINSCALEY/WINSCALEX);
  End Else Begin
    Radius1 := SP_StackPtr^.Val;
    Radius2 := Radius1;
  End;

  if CIRCLEASPECT then
    if Aspect <> 1 then
      if Aspect < 1 then
        Radius2 := Radius2 * Aspect
      else
        Radius1 := Radius1 / Aspect;

  Dec(SP_StackPtr);

  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_ConvertToOrigin_d(dX, dY);
  If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dy;

  xPos := Round(dX);
  yPos := Round(dY);
  if (Radius1 > 0) and (Radius1 <= 0.5) and (Radius2 > 0) and (Radius2 <= 0.5) Then Begin
    If SCREENBPP = 8 Then
      SP_SetPixel(xPos, yPos)
    Else
      SP_SetPixel32(xPos, yPos);
    If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + XPos, SCREENY + YPos, SCREENX + XPos, SCREENY + YPos);
    Exit;
  End;

  SP_DrawEllipse(xPos, yPos, Round(Radius1), Round(Radius2));

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_CIRCLEFILL(Var Info: pSP_iInfo);
Var
  Aspect, R, dX, dY, Radius1, Radius2: aFloat;
  tW, tH, BankID, xPos, yPos: Integer;
  TextureStr: aString;
  Valid, BankFill, Bits32: Boolean;
  gBank: pSP_Bank;
  Graphic: pSP_Graphic_Info;
Begin

  tw := 0; th := 0;

  BankFill := False;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    TextureStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
        Graphic := @gBank^.Info[0];
        tW := NativeUInt(Graphic^.Data);
        tH := NativeUInt(Graphic);
        BankFill := True;
      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else Begin
    TextureStr := SP_StackPtr^.Str;
  End;
  Dec(SP_StackPtr);

  If Info^.Error^.Code <> SP_ERR_OK Then Exit;

  Aspect := (ScaleWidth/DisplayWidth)/(ScaleHeight/DisplayHeight);
  If WINSCALE Then Begin
    R := SP_StackPtr^.Val;
    Radius1 := R/WINSCALEX;
    Radius2 := R/WINSCALEY;
    Aspect := Aspect * (WINSCALEY/WINSCALEX);
  End Else Begin
    Radius1 := SP_StackPtr^.Val;
    Radius2 := Radius1;
  End;

  if CIRCLEASPECT then
    if Aspect <> 1 then
      if Aspect < 1 then
        Radius2 := Radius2 * Aspect
      else
        Radius1 := Radius1 / Aspect;

  Dec(SP_StackPtr);

  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_ConvertToOrigin_d(dX, dY);
  If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dy;

  If Not BankFill Then Begin
    Valid := False;
    xPos := Round(dX);
    yPos := Round(dY);
    if (Radius1 > 0) and (Radius1 <= 0.5) and (Radius2 > 0) and (Radius2 <= 0.5) Then Begin
      If SCREENBPP = 8 Then
        SP_SetPixel(xPos, yPos)
      Else
        SP_SetPixel32(xPos, yPos);
      If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + XPos, SCREENY + YPos, SCREENX + XPos, SCREENY + YPos);
      Exit;
    End;

    If TextureStr = '' Then
      SP_DrawSolidEllipse(xPos, yPos, Abs(Round(Radius1)), Abs(Round(Radius2)))
    Else Begin
      If Length(TextureStr) > 10 Then Begin
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
        If TextureStr[10] = #32 Then Begin
          If Length(TextureStr) - 10 = tW * tH * SizeOf(RGBA) Then Valid := True;
        End Else
          If Length(TextureStr) - 10 = tW * tH Then Valid := True;
      End;
      If Not Valid Then Begin
        TextureStr := SP_StringToTexture(TextureStr);
        If TextureStr = '' Then
          SP_DefaultFill(TextureStr, T_INK);
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
      End;
      Bits32 := TextureStr[10] = #32;
      If Bits32 Then Begin
        If SCREENBPP = 32 Then
          SP_DrawTexEllipse32To32(xPos, yPos, Abs(Round(Radius1)), Abs(Round(Radius2)), TextureStr, tW, tH)
        Else
          Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
      End Else
        If SCREENBPP = 8 Then
          SP_DrawTexEllipse(xPos, yPos, Abs(Round(Radius1)), Abs(Round(Radius2)), TextureStr, tW, tH)
        Else
          SP_DrawTexEllipse8To32(xPos, yPos, Abs(Round(Radius1)), Abs(Round(Radius2)), TextureStr, tW, tH);
    End;
  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_ELLIPSE(Var Info: pSP_iInfo);
Var
  rX, rY, dX, dY: aFloat;
  RadiusX, RadiusY: Integer;
Begin

  If WINSCALE Then Begin
    Ry := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    Rx := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    RadiusX := Round(Rx/WINSCALEX);
    RadiusY := Round(Ry/WINSCALEY);
  End Else Begin
    RadiusY := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    RadiusX := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End;

  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_ConvertToOrigin_d(dX, dY);
  If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dy;

  SP_DrawEllipse(Round(dX), Round(dY), RadiusX, RadiusY);

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_ELLIPSEFILL(Var Info: pSP_iInfo);
Var
  Valid, BankFill, Bits32: Boolean;
  TextureStr: aString;
  rX, rY, dX, dY: aFloat;
  tW, tH, RadiusX, RadiusY, BankID: Integer;
  gBank: pSP_Bank;
  Graphic: pSP_Graphic_Info;
Begin

  tw := 0; th := 0;
  BankFill := False;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    TextureStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
        Graphic := @gBank^.Info[0];
        tW := NativeUInt(Graphic^.Data);
        tH := NativeUInt(Graphic);
        BankFill := True;
      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else
    TextureStr := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  If Info^.Error^.Code <> SP_ERR_OK Then Exit;

  If WINSCALE Then Begin
    Ry := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    Rx := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    RadiusX := Round(Rx/WINSCALEX);
    RadiusY := Round(Ry/WINSCALEY);
  End Else Begin
    RadiusY := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    RadiusX := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End;

  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_ConvertToOrigin_d(dX, dY);
  If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dy;

  If Not BankFill Then Begin
    Valid := False;
    If TextureStr = '' Then
      SP_DrawSolidEllipse(Round(dX), Round(dY), Abs(RadiusX), Abs(RadiusY))
    Else Begin
      If Length(TextureStr) > 10 Then Begin
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
        If TextureStr[10] = #32 Then Begin
          If Length(TextureStr) - 10 = tW * tH * SizeOf(RGBA) Then Valid := True;
        End Else
          If Length(TextureStr) - 10 = tW * tH Then Valid := True;
      End;
      If Not Valid Then Begin
        TextureStr := SP_StringToTexture(TextureStr);
        If TextureStr = '' Then
          SP_DefaultFill(TextureStr, T_INK);
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
      End;
      Bits32 := TextureStr[10] = #32;
      If Bits32 Then Begin
        If SCREENBPP = 32 Then
          SP_DrawTexEllipse32To32(Round(dX), Round(dY), Abs(RadiusX), Abs(RadiusY), TextureStr, tW, tH)
        Else
          Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
      End Else
        If SCREENBPP = 8 Then
          SP_DrawTexEllipse(Round(dX), Round(dY), Abs(RadiusX), Abs(RadiusY), TextureStr, tW, tH)
        Else
          SP_DrawTexEllipse8To32(Round(dX), Round(dY), Abs(RadiusX), Abs(RadiusY), TextureStr, tW, tH);
    End;
  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_CURVE(Var Info: pSP_iInfo);
Var
  Y1, X1, X2, Y2: aFloat;
  N: Integer;
Begin

  N := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_ConvertToOrigin_d(X1, Y1);
  SP_ConvertToOrigin_d(X2, Y2);
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  If SCREENBPP = 8 Then
    SP_DrawCurve(DRPOSX, DRPOSY, X1, Y1, X2, Y2, N)
  Else
    SP_DrawCurve32(DRPOSX, DRPOSY, X1, Y1, X2, Y2, N);

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_CURVE_EX(Var Info: pSP_iInfo);
Var
  Y1, X1, X2, Y2, X3, Y3: aFloat;
  N: Integer;
Begin

  N := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Y3 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X3 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_ConvertToOrigin_d(X1, Y1);
  SP_ConvertToOrigin_d(X2, Y2);
  SP_ConvertToOrigin_d(X3, Y3);
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
    Y3 := (SCREENHEIGHT - 1) - Y3;
  End;

  DRPOSX := X1;
  DRPOSY := Y1;

  SKIPFIRSTPOINT := False;
  If SCREENBPP = 8 Then
    SP_DrawCurve(X1, Y1, X2, Y2, X3, Y3, N)
  Else
    SP_DrawCurve32(X1, Y1, X2, Y2, X3, Y3, N);

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_RANDOMIZE(Var Info: pSP_iInfo);
Begin

  If SP_StackPtr <> SP_StackStart Then Begin
    RandSeed := Integer(Round(SP_StackPtr^.Val));
    Dec(SP_StackPtr);
  End Else
    Randomize;

End;

Procedure SP_Interpret_SAVE(Var Info: pSP_iInfo);
Var
  Filename: aString;
  LineStart: Integer;
Begin

  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  If SP_StackPtr <> SP_StackStart then Begin
    LineStart := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End Else
    LineStart := -1;

  If Filename = '' Then
    Filename := OpenFileReq('Save program as...', PROGNAME, '10:ZXASCII;10:ZXPACK', True, Info^.Error^);

  If SP_ExtractFilename(Filename) <> '' Then Begin
    FILECHANGED := False;
    SP_SaveProgram(Filename, LineStart, Info^.Error^);
  End;

End;

Procedure SP_Interpret_SAVEASCII(Var Info: pSP_iInfo);
Var
  Filename: aString;
  LineStart: LongWord;
Begin

  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  If SP_StackPtr <> SP_StackStart then Begin
    LineStart := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End Else
    LineStart := $FFFFFFFF;

  If Filename = '' Then
    Filename := OpenFileReq('Save program as...', PROGNAME, '10:ZXASCII;10:ZXPACK', True, Info^.Error^);

  If SP_ExtractFilename(Filename) <> '' Then Begin
    FILECHANGED := False;
    SP_SaveProgram(Filename, LineStart, Info^.Error^);
  End;

End;

Procedure SP_Interpret_SCREEN_SAVE(Var Info: pSP_iInfo);
Var
  Filename: aString;
  w, h: Integer;
  Pixels, Palette: pByte;
Begin

  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  Filename := SP_ConvertFilenameToHost(Filename, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Pixels := SCREENPOINTER;
    w := SCREENWIDTH;
    h := SCREENHEIGHT;
    Palette := @pSP_Window_Info(WINDOWPOINTER)^.Palette[0];
    CB_Save_Image(Filename, w, h, Pixels, Palette);
  End;

End;

Procedure SP_Interpret_GRAPHIC_SAVE(Var Info: pSP_iInfo);
Var
  Filename: aString;
  ID, Idx, w, h: Integer;
  Pixels, Palette: pByte;
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
Begin

  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @Bank^.Info[0];

      Filename := SP_ConvertFilenameToHost(Filename, Info^.Error^);
      If Info^.Error^.Code = SP_ERR_OK Then Begin
        Pixels := Gfx.Data;
        w := Gfx.Width;
        h := Gfx.Height;
        Palette := @Gfx.Palette[0];
        CB_Save_Image(Filename, w, h, Pixels, Palette);
      End;

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_LOAD(Var Info: pSP_iInfo);
Var
  Filename: aString;
Begin

  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  If Filename = '' Then
    Filename := OpenFileReq('Load program', PROGNAME, '10:ZXASCII;10:ZXPACK', False, Info^.Error^);

  If Filename <> '' Then Begin
    SP_LoadProgram(Filename, False, False, nil, Info^.Error^);
    SP_Interpret_PAL_DEFAULT(Info);
    MATHMODE := 0;
    CSCALEX := 1;
    CSCALEY := 1;
    SP_Reset_Temp_Colours;
    If Filename <> 's:autosave' Then
      SP_CLS(CPAPER);
    If EDITORREADY Then Begin
      SP_FPWrapProgram;
      Listing.FPCLine := 0;
      Listing.FPCPos := 1;
      FPScrollBars[SP_FindScrollBar(FPVertSc)].Position := 0;
      SP_ScrollInView(True);
    End;
  End;

End;

Procedure SP_Interpret_MERGE(Var Info: pSP_iInfo);
Var
  Filename: aString;
Begin

  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  If Filename = '' Then
    Filename := OpenFileReq('Merge program', PROGNAME, '10:ZXASCII', False, Info^.Error^);

  If Filename <> '' Then
    SP_LoadProgram(Filename, True, False, nil, Info^.Error^);

End;

Procedure SP_Interpret_INC(Var Info: pSP_iInfo);
Var
  Idx: Integer;
  VarIdx: Integer;
  Increment, Value: aFloat;
Begin

  Increment := 1;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    Increment := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
  End;

  With SP_StackPtr^ Do
    Case OpType of
      SP_NUMVAR:
        Begin
          VarIdx := Round(Val);
          If VarIdx = 0 Then Begin
            VarIdx := SP_FindNumVar(Str);
            If VarIdx = -1 Then Begin
              Info^.Error^.Code := SP_ERR_MISSING_VAR;
              Info^.Error^.Position := tPos;
              Exit;
            End Else Begin
              If Not NumVars[VarIdx]^.ProcVar Then
                Ptr^ := VarIdx + 1;
            End;
          End
          Else
            Dec(VarIdx);
          NumVars[VarIdx]^.ContentPtr^.Value := NumVars[VarIdx]^.ContentPtr^.Value + Increment;
          Dec(SP_StackPtr);
        End;
      SP_ARRAY_ASSIGN: Begin
          SP_StackToString(Round(Val));
          With SP_StackPtr^ Do Begin
            Idx := Round(Val);
            If Idx = 0 Then Begin
              Idx := SP_FindNumArray(Str);
              If Idx = -1 Then Begin
                ERRStr := Str;
                Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
                Exit;
              End;
              If INPROC = 0 Then Ptr^ := Idx +1;
            End Else
              Dec(Idx);
            Value := SP_QueryNumArray(Idx, gbIndices, gbKey, Info^.Error^);
            If Info^.Error^.Code = SP_ERR_OK Then Begin
              Value := Value + Increment;
              Inc(Idx);
              SP_UpdateNumArray(Idx, Str, gbIndices, gbKey, Value, Info^.Error^);
            End;
          End;
          Dec(SP_StackPtr);
        End;
    End;

End;

Procedure SP_Modulus(Var Value, Min, Max: aFloat);
Begin

  If Value < Min Then
    Value := Max;
  If Value > Max Then
    Value := Min;

End;

Procedure SP_Interpret_INCRANGE(Var Info: pSP_iInfo);
Var
  Idx: Integer;
  taFloat: aFloat;
  VarIdx: Integer;
  Increment, Start, Finish, Value: aFloat;
Begin

  Increment := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Start := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Finish := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  With SP_StackPtr^ Do
    Case OpType of
      SP_NUMVAR: Begin
        VarIdx := Round(Val);
          If VarIdx = 0 Then Begin
            VarIdx := SP_FindNumVar(Str);
            If VarIdx = -1 Then Begin
              Info^.Error^.Code := SP_ERR_MISSING_VAR;
              Info^.Error^.Position := tPos;
              Exit;
            End Else Begin
              If Not NumVars[VarIdx]^.ProcVar Then
                Ptr^ := VarIdx + 1;
            End;
          End Else
            Dec(VarIdx);
          If Start > Finish Then Begin
            taFloat := Start; Start := Finish; Finish := taFloat;
          End;
          If Start = Finish Then
            NumVars[VarIdx]^.ContentPtr^.Value := Start
          Else
            NumVars[VarIdx]^.ContentPtr^.Value := NumVars[VarIdx]^.ContentPtr^.Value + Increment;
          SP_Modulus(NumVars[VarIdx]^.ContentPtr^.Value, Start, Finish);
          Dec(SP_StackPtr);
        End;
      SP_ARRAY_ASSIGN:
        Begin
          SP_StackToString(Round(Val));
          With SP_StackPtr^ Do Begin
            Idx := Round(Val);
            If Idx = 0 Then Begin
              Idx := SP_FindNumArray(Str);
              If Idx = -1 Then Begin
                ERRStr := Str;
                Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
                Exit;
              End;
              If INPROC = 0 Then Ptr^ := Idx +1;
            End Else
              Dec(Idx);
            Value := SP_QueryNumArray(Idx, gbIndices, gbKey, Info^.Error^) + Increment;
            If Info^.Error^.Code = SP_ERR_OK Then Begin
              If Start = Finish Then
                Value := Start
              Else Begin
                If Start > Finish Then Begin
                  taFloat := Start; Start := Finish; Finish := taFloat;
                End;
                SP_Modulus(Value, Start, Finish);
              End;
              Inc(Idx);
              SP_UpdateNumArray(Idx, Str, gbIndices, gbKey, Value, Info^.Error^);
            End;
          End;
          Dec(SP_StackPtr);
        End;
    End;

End;

Procedure SP_Interpret_DEC(Var Info: pSP_iInfo);
Var
  Idx: Integer;
  VarIdx: Integer;
  Decrement, Value: aFloat;
Begin

  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    Decrement := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
  End Else
    Decrement := 1;

  With SP_StackPtr^ Do
    Case OpType of
      SP_NUMVAR:
        Begin
          VarIdx := Round(Val);
          If VarIdx = 0 Then Begin
            VarIdx := SP_FindNumVar(Str);
            If VarIdx = -1 Then Begin
              Info^.Error^.Code := SP_ERR_MISSING_VAR;
              Info^.Error^.Position := tPos;
              Exit;
            End Else Begin
              If Not NumVars[VarIdx]^.ProcVar Then
                Ptr^ := VarIdx + 1;
            End;
          End Else
            Dec(VarIdx);
          NumVars[VarIdx]^.ContentPtr^.Value := NumVars[VarIdx]^.ContentPtr^.Value - Decrement;
          Dec(SP_StackPtr);
        End;
      SP_ARRAY_ASSIGN:
        Begin
          SP_StackToString(Round(Val));
          With SP_StackPtr^ Do Begin
            Idx := Round(Val);
            If Idx = 0 Then Begin
              Idx := SP_FindNumArray(Str);
              If Idx = -1 Then Begin
                ERRStr := Str;
                Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
                Exit;
              End;
              If INPROC = 0 Then Ptr^ := Idx +1;
            End Else
              Dec(Idx);
            Value := SP_QueryNumArray(Idx, gbIndices, gbKey, Info^.Error^);
            If Info^.Error^.Code = SP_ERR_OK Then Begin
              Value := Value - Decrement;
              Inc(Idx);
              SP_UpdateNumArray(Idx, Str, gbIndices, gbKey, Value, Info^.Error^);
            End;
          End;
          Dec(SP_StackPtr);
        End;
    End;

End;

Procedure SP_Interpret_DECRANGE(Var Info: pSP_iInfo);
Var
  Idx: Integer;
  taFloat: aFloat;
  VarIdx: Integer;
  Decrement, Start, Finish, Value: aFloat;
Begin

  Decrement := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Start := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Finish := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  With SP_StackPtr^ Do
    Case OpType of
      SP_NUMVAR:
        Begin
          VarIdx := Round(Val);
          If VarIdx = 0 Then Begin
            VarIdx := SP_FindNumVar(Str);
            If VarIdx = -1 Then Begin
              Info^.Error^.Code := SP_ERR_MISSING_VAR;
              Info^.Error^.Position := tPos;
              Exit;
            End Else Begin
              If Not NumVars[VarIdx]^.ProcVar Then
                Ptr^ := VarIdx + 1;
            End;
          End Else
            Dec(VarIdx);
          NumVars[VarIdx]^.ContentPtr^.Value := NumVars[VarIdx]^.ContentPtr^.Value - Decrement;
          If Start > Finish Then Begin
            taFloat := Start; Start := Finish; Finish := taFloat;
          End;
          If Start = Finish Then
            Value := Start
          Else
            SP_Modulus(NumVars[VarIdx]^.ContentPtr^.Value, Start, Finish);
          Dec(SP_StackPtr);
        End;
      SP_ARRAY_ASSIGN:
        Begin
          SP_StackToString(Round(Val));
          With SP_StackPtr^ Do Begin
            Idx := Round(Val);
            If Idx = 0 Then Begin
              Idx := SP_FindNumArray(Str);
              If Idx = -1 Then Begin
                ERRStr := Str;
                Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
                Exit;
              End;
              If INPROC = 0 Then Ptr^ := Idx +1;
            End Else
              Dec(Idx);
            Value := SP_QueryNumArray(Idx, gbIndices, gbKey, Info^.Error^) - Decrement;
            If Info^.Error^.Code = SP_ERR_OK Then Begin
              If Start = Finish Then
                Value := Start
              Else Begin
                If Start > Finish Then Begin
                  taFloat := Start; Start := Finish; Finish := taFloat;
                End;
                SP_Modulus(Value, Start, Finish);
              End;
              Inc(Idx);
              SP_UpdateNumArray(Idx, Str, gbIndices, gbKey, Value, Info^.Error^);
            End;
          End;
          Dec(SP_StackPtr);
        End;
    End;

End;

Procedure SP_Interpret_PALETTE(Var Info: pSP_iInfo);
Var
  v: aFloat;
  Val1, Val2, Val3, Val4: Integer;
Begin

  Val1 := Trunc(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  v := SP_StackPtr^.Val;
  Val2 := Trunc(v);
  Dec(SP_StackPtr);

  If SP_StackPtr <> SP_StackStart Then Begin

    Val3 := Trunc(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    Val4 := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);

    If (Val1 > 255) or (Val1 < 0) or (Val2 > 255) or (Val2 < 0) or (Val3 > 255) or (Val3 < 0) or (Val4 > 255) or (Val4 < 0) Then Begin
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
      Exit;
    End Else
      SP_SetWindowPalette(Val4, Val3, Val2, Val1);

  End Else Begin

    SP_SetWindowPalette(Round(v), (Val1 Shr 16) And $FF, (Val1 Shr 8) And $FF, Val1 And $FF);

  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_PALETTE_HSV(Var Info: pSP_iInfo);
Var
  Val1, Val2, Val3, Val4: Integer;
  R, G, B, H, S, V: aFloat;
Begin

  Val1 := Trunc(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Val2 := Trunc(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If SP_StackPtr <> SP_StackStart Then Begin

    Val3 := Trunc(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    Val4 := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);

    If (Val1 > 255) or (Val1 < 0) or (Val2 > 255) or (Val2 < 0) or (Val3 > 360) or (Val3 < 0) or (Val4 > 255) or (Val4 < 0) Then Begin
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
      Exit;
    End Else Begin
      H := Val3;
      S := Val2;
      V := Val1;
      SP_HSVToRGB(H, S, V, R, G, B);
      SP_SetWindowPalette(Val4, Round(R), Round(G), Round(B));
    End;

  End Else Begin

    H := (Val1 Shr 16) And $FFFF;
    S := (Val1 Shr 8) And $FF;
    V := Val1 And $FF;
    SP_HSVToRGB(H, S, V, R, G, B);
    SP_SetWindowPalette(Val2, Round(R), Round(G), Round(B));

  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_PALETTESHIFT(Var Info: pSP_iInfo);
Var
  Idx, Idx2, Val1, Val2, Val3, Val4: Integer;
  Pl: LongWord; Str: aString;
  Pal: Array [0 .. 255] of LongWord;
  Wrap: Boolean;
Begin

  Val1 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  If SP_StackPtr <> SP_StackStart Then Begin
    Val2 := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    Val3 := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    Val4 := Val1;
    Val1 := Val3;
    Val3 := Val4;
  End Else Begin
    Val3 := 255;
    Val2 := 0;
  End;

  If (Val2 > 255) or (Val2 < 0) or (Val3 > 255) or (Val3 < 0) Then Begin
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    Exit;
  End;

  For Idx := 0 To 255 Do
    Pal[Idx] := SP_GetPalette(Idx);

  Wrap := False;
  If Val3 < Val2 Then Begin
    SetLength(Str, (256 - Val2) + (Val3 +1));
    Idx2 := Val2;
    For Idx := 1 To Length(Str) Do Begin
      Str[Idx] := aChar(Idx2);
      Inc(Idx2);
      If Idx2 > 255 Then Idx2 := 0;
    End;
    Wrap := True;
  End Else Begin
    SetLength(Str, (Val3 - Val2) + 1);
    For Idx := 1 To Length(Str) Do
      Str[Idx] := aChar(Val2 + Idx - 1);
  End;

  If Val1 > 0 Then Begin
    While Val1 > 0 Do Begin
      Str := Str[Length(Str)] + Copy(Str, 1, Length(Str) - 1);
      Dec(Val1);
    End;
  End Else
    If Val1 < 0 Then Begin
      Val1 := -Val1;
      While Val1 > 0 Do Begin
        Str := Copy(Str, 2, Length(Str)) + Str[1];
        Dec(Val1);
      End;
    End;

  If Not Wrap Then Begin
    For Idx := 1 To Length(Str) Do Begin
      Pl := Pal[Byte(Str[Idx])];
      SP_SetWindowPalette(Idx + Val2 - 1, (Pl Shr 24) And $FF, (Pl Shr 16) And $FF, (Pl Shr 8) And $FF);
    End;
  End Else Begin
    Idx2 := Val2;
    For Idx := 1 To Length(Str) Do Begin
      Pl := Pal[Byte(Str[Idx])];
      SP_SetWindowPalette(Idx2, (Pl Shr 24) And $FF, (Pl Shr 16) And $FF, (Pl Shr 8) And $FF);
      Inc(Idx2);
      If Idx2 > 255 Then Idx2 := 0;
    End;
  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_DO(Var Info: pSP_iInfo);
Var
  LineItem: TSP_GOSUB_Item;
Begin

  With Info^ Do Begin
    If Error^.Line >= 0 Then
      LineItem := SP_ConvertLineStatement(Error^.Line, Error^.Statement +1)
    Else Begin
      LineItem.Line := -2;
      LineItem.Statement := SP_FindStatement(@COMMAND_TOKENS, Error^.Statement +1);
    End;
    SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_DO, Info^.Error^);
  End;

End;

Procedure SP_Interpret_DO_COUNT(Var Info: pSP_iInfo);
Var
  LineItem: TSP_GOSUB_Item;
Begin

  With Info^ Do Begin
    If Error^.Line >= 0 Then
      LineItem := SP_ConvertLineStatement(Error^.Line, Error^.Statement + 1)
    Else Begin
      LineItem.Line := -2;
      LineItem.Statement := SP_FindStatement(@COMMAND_TOKENS, Error^.Statement + 1);
      If LineItem.Statement = -1 Then
        LineItem.Statement := Error^.Position;
      LineItem.St := Error^.Statement + 1;
    End;
    SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_DO_COUNT, Info^.Error^);
    SP_GOSUB_STACK[SP_GOSUB_STACKPTR -1].Count := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_LOOP(Var Info: pSP_iInfo);
Begin

  If SP_GOSUB_STACKPTR = 0 Then Begin
    Info^.Error^.Code := SP_ERR_LOOP_WITHOUT_DO;
    Exit;
  End Else Begin
    If SP_GOSUB_Stack[SP_GOSUB_STACKPTR -1].Source = SP_KW_DO_COUNT Then Begin
      Dec(SP_GOSUB_Stack[SP_GOSUB_STACKPTR -1].Count);
      If SP_GOSUB_Stack[SP_GOSUB_STACKPTR -1].Count <= 0 Then Begin
        Dec(SP_GOSUB_STACKPTR);
        Exit;
      End;
    End;
    NXTLINE := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Line;
    NXTSTATEMENT := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Statement;
    Info^.Error^.Statement := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].St;
    If SP_GOSUB_Stack[SP_GOSUB_STACKPTR -1].Source = SP_KW_ERROR Then
      IGNORE_ON_ERROR := False
    Else
      If SP_GOSUB_Stack[SP_GOSUB_STACKPTR -1].Source = SP_KW_WHILE Then
        Dec(SP_GOSUB_STACKPTR);
  End;
  Info^.Error^.ReturnType := SP_JUMP;

End;

Procedure SP_Interpret_UNTIL(Var Info: pSP_iInfo);
Begin

  If SP_StackPtr^.Val = 0 Then Begin
    Dec(SP_StackPtr);
    SP_Interpret_LOOP(Info);
  End Else Begin
    Dec(SP_GOSUB_STACKPTR);
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_WHILE(Var Info: pSP_iInfo);
Var
  LinePtr, StatementPtr, StPtr: pInteger;
  LineItem: TSP_GOSUB_Item;
  Tkns: aString;
  WhileCount, Line: Integer;
  Tkn: pToken;
Label
  Jump;
Begin

  Line := 0;

  // On entry, the stack should hold two items - pointers to two areas of memory which can be read to
  // find the position of the LOOP that corresponds to this DO WHILE statement. If These pointers read zero,
  // then we need to run through the listing to find it, then fill the pointers accordingly.

  LinePtr := pInteger(SP_StackPtr^.Ptr);
  Dec(SP_StackPtr);
  StatementPtr := pInteger(SP_StackPtr^.Ptr);
  Dec(SP_StackPtr);
  StPtr := pInteger(SP_StackPtr^.Ptr);
  Dec(SP_StackPtr);

  With Info^ Do Begin

    If StPtr^ = 0 Then Begin

      WhileCount := 0;
      Line := Error^.Line;
      If Line >= 0 Then Begin
        LineItem := SP_ConvertLineStatement(Line, Error^.Statement + 1);
        Line := LineItem.Line;
        If Line = -1 Then Begin
          Error^.Code := SP_ERR_WHILE_WITHOUT_LOOP;
          Exit;
        End;
        Tkns := SP_Program[LineItem.Line];
      End Else Begin
        Line := -2;
        LineItem.Line := -2;
        LineItem.Statement := SP_FindStatement(@COMMAND_TOKENS, Error^.Statement + 1);
        LineItem.St := Error^.Statement + 1;
        Tkns := COMMAND_TOKENS;
      End;

      While LineItem.Line < SP_Program_Count Do Begin
        Position := LineItem.Statement;
        While Position <= Length(Tkns) Do Begin
          Tkn := @Tkns[Position];
          If Tkn^.Token = SP_TERMINAL Then
            Break;
          Inc(Position, SizeOf(TToken));
          If Tkn^.Token = SP_SYMBOL Then
            If Tkns[Position] = ':' Then
              Inc(LineItem.St);
          If Tkn^.Token = SP_KEYWORD Then Begin
            Case pLongWord(@Tkns[Position])^ of
              SP_KW_ELSE:
                Begin
                  Inc(LineItem.St);
                End;
              SP_KW_WHILE:
                Begin
                  Inc(WhileCount);
                End;
              SP_KW_UNTIL, SP_KW_LOOP:
                Begin

                  If WhileCount > 0 Then Begin
                    Dec(WhileCount);
                  End Else Begin
                    If Line >= 0 Then Begin
                      LineItem := SP_ConvertLineStatement(LineItem.Line, LineItem.St + 1);
                      If LineItem.St > 1 Then
                        LineItem.Statement := Position + integer(Tkn^.TokenLen);
                    End Else Begin
                      LineItem.Line := -2;
                      LineItem.Statement := Position + integer(Tkn^.TokenLen);
                      LineItem.St := LineItem.St + 1;
                    End;
                    LinePtr^ := LineItem.Line;
                    StatementPtr^ := LineItem.Statement;
                    StPtr^ := LineItem.St;
                    Goto Jump;
                  End;
                End;
            End;
          End;
          Inc(Position, Tkn^.TokenLen);
        End;
        If Line >= 0 Then Begin
          Inc(Line);
          If Integer(Line) < SP_Program_Count Then Begin
            LineItem := SP_ConvertLineStatement(Line, 1);
            Tkns := SP_Program[LineItem.Line];
          End;
        End Else
          Goto Jump;
      End;

    End;

  Jump :

    If StPtr^ = 0 Then Begin
      Error^.Code := SP_ERR_WHILE_WITHOUT_LOOP;
      Exit;
    End;

    If SP_StackPtr^.Val = 0 Then Begin

      Dec(SP_StackPtr);
      NXTLINE := LinePtr^;
      NXTSTATEMENT := StatementPtr^;
      Error^.Statement := StPtr^;
      Error^.ReturnType := SP_JUMP;

    End Else Begin

      If Line >= 0 Then
        LineItem := SP_ConvertLineStatement(Error^.Line, Error^.Statement)
      Else Begin
        LineItem.Line := -2;
        LineItem.Statement := SP_FindStatement(@COMMAND_TOKENS, Error^.Statement);
      End;
      SP_StackLine(LineItem.Line, LineItem.Statement, Error^.Statement, SP_KW_WHILE, Info^.Error^);
      Dec(SP_StackPtr);

    End;

  End;

End;

Procedure SP_Interpret_INSTALL(Var Info: pSP_iInfo);
Begin

{$IFDEF FPC}
  {$IFDEF DARWIN}
    SP_Interpret_PAL_DEFAULT(Info);
    SP_CLS(8);
    T_INK := 0;
    T_PAPER := 8;
    CopyDirectoryRecursive(Copy(INITFOLDER, 1, Pos('macos', Lower(INITFOLDER)) -1) + 'Resources/SpecBAS', GetEnvironmentVariable('HOME')+'/specbas');
    Info^.Error^.Code := SP_ERR_INSTALL_DONE;
  {$ENDIF}
{$ENDIF}

  Info^.Error^.Code := SP_ERR_OK;

End;

Procedure SP_Interpret_EXIT(Var Info: pSP_iInfo);
Var
  LineItem: TSP_GOSUB_Item;
  Tkns: aString;
  WhileCount: Integer;
  Lne, Line: Integer;
  St, Statement: LongWord;
  Tkn: pToken;
Label
  Jump;
Begin

  With Info^ Do Begin

    St := 0;
    Line := 0;
    Statement := 0;
    WhileCount := 0;
    Lne := Error^.Line;
    If Lne >= 0 Then Begin
      LineItem := SP_ConvertLineStatement(Lne, Error^.Statement + 1);
      Lne := LineItem.Line;
      Tkns := SP_Program[LineItem.Line];
    End Else Begin
      Lne := -2;
      LineItem.Line := -2;
      LineItem.Statement := SP_FindStatement(@COMMAND_TOKENS, Error^.Statement + 1);
      LineItem.St := Error^.Statement + 1;
      Tkns := COMMAND_TOKENS;
    End;

    While LineItem.Line < SP_Program_Count Do Begin
      Position := LineItem.Statement;
      While Position <= Length(Tkns) Do Begin
        Tkn := @Tkns[Position];
        If Tkn^.Token = SP_TERMINAL Then Break;
        Inc(Position, SizeOf(TToken));
        If Tkn^.Token = SP_SYMBOL Then
          If Tkns[Position] = ':' Then
            Inc(LineItem.St);
        If Tkn^.Token = SP_KEYWORD Then Begin
          Case pLongWord(@Tkns[Position])^ of
            SP_KW_WHILE:
              Begin
                Inc(WhileCount);
              End;
            SP_KW_UNTIL, SP_KW_LOOP: Begin
                If WhileCount > 0 Then
                  Dec(WhileCount)
                Else Begin
                  If Lne >= 0 Then Begin
                    LineItem := SP_ConvertLineStatement(LineItem.Line, LineItem.St + 1);
                    If LineItem.St > 1 Then
                      LineItem.Statement := Position + Integer(Tkn^.TokenLen);
                  End Else Begin
                    LineItem.Line := -2;
                    LineItem.Statement := Position + Integer(Tkn^.TokenLen);
                    LineItem.St := LineItem.St + 1;
                  End;
                  Line := LineItem.Line;
                  Statement := LineItem.Statement;
                  St := LineItem.St;
                  Goto Jump;
                End;
              End;
          End;
        End;
        Inc(Position, Tkn^.TokenLen);
      End;
      If Lne >= 0 Then Begin
        Inc(Lne);
        If Lne < SP_Program_Count Then Begin
          LineItem := SP_ConvertLineStatement(Lne, 1);
          Tkns := SP_Program[LineItem.Line];
        End;
      End Else
        Goto Jump;
    End;

  Jump :

    If (St = 0) or (SP_GOSUB_STACKPTR = 0) Then Begin
      Error^.Code := SP_ERR_EXIT_WITHOUT_LOOP;
      Exit;
    End;

    Dec(SP_StackPtr);
    NXTLINE := Line;
    NXTSTATEMENT := Statement;
    Error^.Statement := St;
    Error^.ReturnType := SP_JUMP;
    If SP_GOSUB_Stack[SP_GOSUB_STACKPTR -1].Source = SP_KW_ERROR Then
      IGNORE_ON_ERROR := False
    Else
      If SP_GOSUB_Stack[SP_GOSUB_STACKPTR -1].Source = SP_KW_WHILE Then
        Dec(SP_GOSUB_STACKPTR)
      Else
        If SP_GOSUB_Stack[SP_GOSUB_STACKPTR -1].Source = SP_KW_DO Then
          Dec(SP_GOSUB_STACKPTR);

  End;

End;

Procedure SP_Interpret_QUIT(Var Info: pSP_iInfo);
Begin

  TerminateInterpreter := True;
  CB_Quit;

End;

Procedure SP_Interpret_READ(Var Info: pSP_iInfo);
Begin

  If (SP_DATA_Line.Line = -1) or (Length(SP_DATA_Tokens^) = 0) Then Begin

    Info^.Error^.Code := SP_ERR_OUT_OF_DATA;
    Exit;

  End Else Begin

    // What is there at the current DATA pointer position?

    If Byte(SP_DATA_Tokens^[SP_DATA_Line.Statement]) = SP_KEYWORD Then Begin

      // a DATA keyword means that this is the end of this line's DATA. Time to scan for more :(

      Info^.Error^.Code := SP_ERR_NO_ERROR;
      SP_Interpret_DO_RESTORE(Info);

      If SP_DATA_Line.Line = -1 Then Begin
        Info^.Error^.Code := SP_ERR_OUT_OF_DATA;
        Exit;
      End;

    End;

    // Otherwise, interpret the DATA...

    SP_InterpretCONTSafe(SP_DATA_Tokens, SP_DATA_Line.Statement, Info^.Error^);

  End;

End;

Procedure SP_Interpret_READ_LINE(Var Info: pSP_iInfo);
Begin

  If SP_DATA_Line.Line = -1 Then Begin

    Info^.Error^.Code := SP_ERR_OUT_OF_DATA;
    Exit;

  End Else Begin

    // What is there at the current DATA pointer position?

    If Byte(SP_DATA_Tokens^[SP_DATA_Line.Statement]) = SP_KEYWORD Then Begin

      // a DATA keyword means that this is the end of this line's DATA. Time to scan for more :(

      Info^.Error^.Code := SP_ERR_NO_ERROR;
      SP_Interpret_DO_RESTORE(Info);

      If SP_DATA_Line.Line = -1 Then Begin
        Info^.Error^.Code := SP_ERR_OUT_OF_DATA;
        Exit;
      End;

    End;

    // Otherwise, interpret the DATA...

    SP_InterpretCONTSafe(SP_DATA_Tokens, SP_DATA_Line.Statement, Info^.Error^);
    If Info^.Error^.Code = SP_ERR_OK Then Begin
      With SP_StackPtr^ Do Begin
        If OpType = SP_VALUE Then Begin
          OpType := SP_STRING;
          Str := aString(aFloatToStr(Val));
        End;
      End;
    End;

  End;

End;

Procedure SP_Interpret_READ_ASSIGN(Var Info: pSP_iInfo);
Var
  SliceFlags: Byte;
  SliceFrom, SliceTo, NumIndices, Idx: Integer;
  sp1: pSP_StackItem;
Begin

  // On entry, the top item will be the variable to update - Val=index, Str=name
  // the next item on the stack will be the value to assign to the variable.

  Sp1 := SP_StackPtr;
  Dec(Sp1);

  With SP_StackPtr^ Do
    Case OpType of
      SP_NUMVAR:
        Begin
          If Sp1^.OpType <> SP_VALUE Then Begin
            Info^.Error^.Code := SP_ERR_MIXED_TYPES;
            Exit;
          End;
          SP_UpdateNumVar(Round(Val), Str, Sp1^.Val, Info^.Error^, Ptr);
          Dec(SP_StackPtr, 2);
        End;
      SP_STRVAR:
        Begin
          If Sp1^.OpType <> SP_STRING Then Begin
            Info^.Error^.Code := SP_ERR_MIXED_TYPES;
            Exit;
          End;
          SP_UpdateStrVar(Round(Val), Str, Sp1^.Str, -1, -1, Info^.Error^, Ptr);
          Dec(SP_StackPtr, 2);
        End;
      SP_ARRAY_ASSIGN:
        Begin
          SP_StackToString(Round(Val));
          Sp1 := SP_StackPtr;
          Dec(Sp1);
          If Sp1^.OpType <> SP_VALUE Then Begin
            Info^.Error^.Code := SP_ERR_MIXED_TYPES;
            Exit;
          End;
          With SP_StackPtr^ Do Begin
            Idx := Round(Val);
            Idx := SP_UpdateNumArray(Idx, Str, gbIndices, gbKey, Sp1^.Val, Info^.Error^);
            If INPROC = 0 Then Ptr^ := Idx +1;
          End;
          Dec(SP_StackPtr, 2);
        End;
      SP_SLICE_ASSIGN:
        Begin
          SliceFlags := Byte(Str[1]);
          NumIndices := Round(Val);
          Dec(SP_StackPtr);
          If SliceFlags And 1 = 1 Then Begin
            SliceTo := Round(SP_StackPtr^.Val);
            Dec(SP_StackPtr);
          End Else
            SliceTo := -1;
          If SliceFlags And 2 = 2 Then Begin
            If SP_StackPtr^.OpType = SP_VALUE Then Begin
              SliceFrom := Round(SP_StackPtr^.Val);
              Dec(SP_StackPtr);
            End Else
              SliceFrom := SliceTo;
          End Else
            SliceFrom := -1;
          With SP_StackPtr^ Do
            If OpType = SP_VALUE Then Begin
              Inc(SP_StackPtr);
              SP_StackToString(NumIndices);
            End Else Begin
              gbIndices := LongWordToString(SliceTo);
              Il := SizeOf(LongWord);
            End;

          Sp1 := SP_StackPtr;
          Dec(Sp1);

          If Sp1^.OpType <> SP_STRING Then Begin
            Info^.Error^.Code := SP_ERR_MIXED_TYPES;
            Exit;
          End;
          With SP_StackPtr^ Do
            SP_UpdateStrArray(Round(Val), Str, gbIndices, gbKey, Sp1^.Str, SliceFrom, SliceTo, Info^.Error^);
          Dec(SP_StackPtr, 2);

        End;
    End;

End;

Procedure SP_Interpret_RESTORE(Var Info: pSP_iInfo);
Var
  LineItem: TSP_GOSUB_Item;
Begin

  // This can be called by ON RESTORE so just to be safe, we stack the next statement.

  With Info^ Do Begin
    If Error^.Line >= 0 Then
      LineItem := SP_ConvertLineStatement(Error^.Line, Error^.Statement + 1)
    Else Begin
      LineItem.Line := -2;
      LineItem.Statement := SP_FindStatement(@COMMAND_TOKENS, Error^.Statement + 1);
      LineItem.St := Error^.Statement + 1;
    End;
  End;

  SP_Interpret_DO_RESTORE(Info);

  // Now execute a GOSUB/RETURN (which we set up earlier) to get back to where we were.

  SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_GOSUB, Info^.Error^);
  NXTLINE := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Line;
  NXTSTATEMENT := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Statement;
  Info^.Error^.Statement := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].St;
  If SP_GOSUB_Stack[Length(SP_GOSUB_Stack) -1].Source = SP_KW_ERROR Then IGNORE_ON_ERROR := False;
  Dec(SP_GOSUB_STACKPTR);
  If NXTSTATEMENT = -1 Then NXTLINE := -1;

  Info^.Error^.ReturnType := SP_JUMP;

End;

Procedure SP_Interpret_DO_RESTORE(Var Info: pSP_iInfo);
Var
  Line, LineNum, Position: Integer;
  nLabel: TSP_Label;
  Tokens: aString;
  Token: pToken;
Begin

  // There may be a line number on the stack - so go get it. We also might be called
  // by the READ function, so check for that too!

  If (Info^.Error^.Code = SP_ERR_OK) And (SP_StackPtr <> SP_StackStart) Then Begin

    If SP_StackPtr^.OpType = SP_LABEL Then Begin
      nLabel := SP_FindLabel(SP_StackPtr^.Str, Info^.Error^);
      Dec(SP_StackPtr);
      If nLabel.Line <> -1 Then Begin
        SP_DATA_Line.Line := nLabel.Line;
        SP_DATA_Line.Statement := nLabel.Statement;
        SP_DATA_Line.St := nLabel.St;
      End Else Begin
        ERRStr := nLabel.Name;
        Info^.Error^.Code := SP_ERR_LABEL_NOT_FOUND;
        Exit;
      End;
    End Else Begin
      LineNum := SP_FindLine(Round(SP_StackPtr^.Val), False);
      If (LineNum > INCLUDEFROM) And (Info^.Error^.Line < INCLUDEFROM) Then LineNum := -1;
      If LineNum = -1 Then Begin
        SP_DATA_Line.Line := -1;
        SP_DATA_Line.Statement := -1;
        SP_DATA_Line.St := -1;
        Exit;
      End;
      SP_DATA_Line := SP_ConvertLineStatement(LineNum, 1);
      Dec(SP_StackPtr);
    End;

  End Else Begin

    If SP_DATA_Line.Line = -1 Then Begin
      SP_DATA_Line.Line := 0;
      SP_DATA_Line.Statement := 1;
      SP_DATA_Line.St := 1;
    End;
    SP_DATA_Line := SP_ConvertLineStatement(SP_DATA_Line.Line, SP_DATA_Line.St + 1);

  End;

  If Info^.Error^.Code = SP_ERR_NO_ERROR Then
    Info^.Error^.Code := SP_ERR_OK;

  // Now find the first instance of SP_SKIP_DATA, as the only thing that uses it
  // is DATA.

  If SP_DATA_Line.Line > -1 Then Begin

    Line := SP_DATA_Line.Line;
    Tokens := SP_Program[SP_DATA_Line.Line];

    While SP_DATA_Line.Line < SP_Program_Count Do Begin
      Position := SP_DATA_Line.Statement;
      While Position <= Length(Tokens) Do Begin
        Token := @Tokens[Position];
        If Token^.Token = SP_TERMINAL Then Break;
        Inc(Position, SizeOf(TToken));
        If Token^.Token = SP_SKIP_DATA Then Begin
          Inc(Position, Token^.TokenLen);
          SP_DATA_Line.Statement := Position;
          SP_DATA_Tokens := @SP_Program[SP_DATA_Line.Line];
          Exit;
        End;
        If Token^.Token = SP_SYMBOL Then
          If (Tokens[Position + 1] = ':') or (Tokens[Position + 1] = SP_CHAR_SEMICOLON) or (Tokens[Position + 1] = ';') Then
            Inc(SP_DATA_Line.St);
        Inc(Position, Token^.TokenLen);
      End;
      Inc(Line);
      If Line < SP_Program_Count Then Begin
        SP_DATA_Line := SP_ConvertLineStatement(Line, 1);
        Tokens := SP_Program[SP_DATA_Line.Line];
      End Else
        SP_DATA_Line.Line := SP_Program_Count;
    End;
  End;

  // No more DATA :(

  SP_DATA_Line.Line := -1;
  SP_DATA_Line.Statement := -1;
  SP_DATA_Line.St := -1;

End;

Procedure SP_Interpret_SCR_LOCK(Var Info: pSP_iInfo);
Begin

  If Not SCREENLOCK Then Begin
    SP_NeedDisplayUpdate := True;
    SP_WaitForSync;
    SCREENLOCK := True;
  End;

End;

Procedure SP_Interpret_SCR_UNLOCK(Var Info: pSP_iInfo);
Begin

  SCREENLOCK := False;
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_SCR_UPDATE(Var Info: pSP_iInfo);
Begin

  SP_InvalidateWholeDisplay;
  CauseUpdate := True;
  UPDATENOW := True;
  SP_NeedDisplayUpdate := False;

End;

Procedure SP_Interpret_SCR_FULL(Var Info: pSP_iInfo);
Var
  Win: pSP_Window_Info;
Begin

  SP_GetWindowDetails(0, win, Info^.Error^);

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := 1;
  Inc(SP_StackPtr);
  SP_StackPtr^.Val := REALSCREENWIDTH;
  Inc(SP_StackPtr);
  SP_StackPtr^.Val := REALSCREENHEIGHT;
  Inc(SP_StackPtr);
  SP_StackPtr^.Val := Win^.Width;
  Inc(SP_StackPtr);
  SP_StackPtr^.Val := Win^.Height;
  SP_Interpret_SCR_RES(Info);

End;

Procedure SP_Interpret_SCR_WIN(Var Info: pSP_iInfo);
Begin

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := 0;
  Inc(SP_StackPtr);
  SP_StackPtr^.Val := DISPLAYWIDTH;
  Inc(SP_StackPtr);
  SP_StackPtr^.Val := DISPLAYHEIGHT;
  Inc(SP_StackPtr);
  SP_StackPtr^.Val := DISPLAYWIDTH;
  Inc(SP_StackPtr);
  SP_StackPtr^.Val := DISPLAYHEIGHT;
  SP_Interpret_SCR_RES(Info);

End;

Procedure SP_Interpret_SCR_RES(Var Info: pSP_iInfo);
Var
  Height, Width, sWidth, sHeight, Full: Integer;
Begin

  sHeight := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  sWidth := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Height := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Width := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Full := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If sWidth = -1 Then sWidth := Width;
  If sHeight = -1 Then sHeight := Height;

  SP_ChangeRes(sWidth, sHeight, Width, Height, Full = 1, Info^.Error^);
  LISTWINDOW := -1;
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_WIN_NEW(Var Info: pSP_iInfo);
Var
  i, j, w, Left, Top, Width, Height, Trans, Bpp, Alpha, cX1, cY1, cX2, cY2: Integer;
  Window: pSP_Window_Info;
  Graphic: pSP_Graphic_Info;
  fName: aString;
Begin

  Left := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Top := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Width := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Height := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Trans := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Bpp := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Alpha := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  fName := SP_StackPtr^.Str;

  If fName <> '' Then Begin
    ERRStr := fName;
    If SP_FileExists(fName) Then
      i := SP_New_GraphicC(fName, $FFFF, Info^.Error^)
    Else Begin
      Info^.Error^.Code := SP_ERR_FILE_MISSING;
      Exit;
    End;
    i := SP_FindBankID(i);
    Graphic := @SP_BankList[i]^.Info[0];
  End Else Begin
    i := -1;
    Graphic := nil;
  End;

  If (Width = 0) And (i <> -1) Then
    Width := Graphic^.Width;

  If (Height = 0) And (i <> -1) Then
    Height := Graphic^.Height;

  SP_StackPtr^.OpType := SP_Value;
  w := SP_Add_Window(Left, Top, Width, Height, Trans, Bpp, Alpha, Info^.Error^);
  SP_StackPtr^.Val := w;
  SP_StackPtr^.OpType := SP_VALUE;

  If i <> -1 Then Begin
    SP_GetWindowDetails(w, Window, Info^.Error^);
    cX1 := Window^.clipx1;
    cY1 := Window^.clipy1;
    cX2 := Window^.clipx2;
    cY2 := Window^.clipy2;
    SP_PutRegion(Window^.Surface, 0, 0, Window^.Stride, Window^.Height, pByte(Graphic), -1, 0, 1, cX1, cY1, cX2, cY2, Info^.Error^);
    For j := 0 To 255 Do
      Window^.Palette[j] := Graphic^.Palette[j];
    SP_DeleteBank(i, Info^.Error^);
  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_WIN_MOVE(Var Info: pSP_iInfo);
Var
  Window, Left, Top: Integer;
Begin

  Window := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Left := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Top := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  SP_MoveWindow(Window, Left, Top, Info^.Error^);
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_WIN_SCROLL(Var Info: pSP_iInfo);
Var
  Window, X, Y: Integer;
  Window_Info: pSP_Window_Info;
Begin

  Window := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  X := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Y := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_GetWindowDetails(Window, Window_Info, Info^.Error^);
  If (X < -Window_Info^.Width) or (X > Integer(Window_Info^.Width)) or (Y < -Window_Info.Height) or (Y > Integer(Window_Info^.Height)) Then
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE
  Else Begin
    SP_VScroll(Window_Info.Surface, Window_Info.Stride, Window_Info.Height, Y, False);
    SP_HScroll(Window_Info.Surface, Window_Info.Stride, Window_Info.Height, Window_Info.Bpp, X, False);
    If Window_Info^.Visible Then SP_SetDirtyRect(Window_Info^.Left, Window_Info^.Top, Window_Info^.Left + Window_Info^.Width, Window_Info^.Top + Window_Info^.Height);
    SP_NeedDisplayUpdate := True;
  End;

End;

Procedure SP_Interpret_WIN_ROLL(Var Info: pSP_iInfo);
Var
  Window, X, Y: Integer;
  Window_Info: pSP_Window_Info;
Begin

  Window := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  X := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Y := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_GetWindowDetails(Window, Window_Info, Info^.Error^);
  If (X < -Window_Info^.Width) or (X > Integer(Window_Info^.Width)) or (Y < -Window_Info^.Height) or (Y > Integer(Window_Info^.Height)) Then
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE
  Else Begin
    SP_VScroll(Window_Info^.Surface, Window_Info^.Stride, Window_Info^.Height, Y, True);
    SP_HScroll(Window_Info^.Surface, Window_Info^.Stride, Window_Info^.Height, Window_Info^.Bpp, X, True);
    If Window_Info^.Visible Then SP_SetDirtyRect(Window_Info^.Left, Window_Info^.Top, Window_Info^.Left + Window_Info^.Width, Window_Info^.Top + Window_Info^.Height);
    SP_NeedDisplayUpdate := True;
  End;

End;

Procedure SP_Interpret_WIN_SIZE(Var Info: pSP_iInfo);
Var
  Window, Width, Height: Integer;
Begin

  Window := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Width := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Height := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_ResizeWindow(Window, Width, Height, -1, SPFULLSCREEN, Info^.Error^);
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_WIN_ERASE(Var Info: pSP_iInfo);
Var
  Window: Integer;
Begin

  Window := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_DeleteWindow(Window, Info^.Error^);
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_WIN_MERGE(Var Info: pSP_iInfo);
Var
  Window, CX1, CX2, CY1, CY2: Integer;
  nfo, Screen: pSP_Window_Info;
  TempStr: aString;
Begin

  Window := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  With Info^ Do Begin
    SP_GetWindowDetails(Window, nfo, Error^);
    SP_GetWindowDetails(0, Screen, Error^);
    CX1 := 0; CY1 := 0; CX2 := Screen^.Width; CY2 := Screen^.Height;
    If nfo^.bpp = 8 Then
      SP_GetRegion(nfo^.Surface, nfo^.Width, nfo^.Height, TempStr, 0, 0, nfo^.Width, nfo^.Height, -1, Error^)
    Else
      SP_GetRegion32(pLongWord(nfo^.Surface), nfo^.Width, nfo^.Height, TempStr, 0, 0, nfo^.Width, nfo^.Height, Error^);

    If (nfo^.bpp = 8) And (Screen^.bpp = 8) Then
      SP_PutRegion(Screen^.Surface, nfo^.Left, nfo^.Top, nfo^.Width, nfo^.Height, @TempStr[1], Length(TempStr), 0, 1, CX1, CY1, CX2, CY2, Error^)
    Else
      If (nfo^.bpp = 8) And (Screen^.bpp = 32) Then
        SP_PutRegion8To32(pLongWord(Screen^.Surface), nfo^.Left, nfo^.Top, nfo^.Width, nfo^.Height, @TempStr[1], Length(TempStr), @nfo^.Palette[0], 0, 1, CX1, CY1, CX2, CY2, Error^)
      Else
        If (nfo^.bpp = 32) And (Screen^.bpp = 32) Then
          SP_PutRegion32to32(Screen^.Surface, nfo^.Left, nfo^.Top, nfo^.Width, nfo^.Height, @TempStr[1], Length(TempStr), 0, 1, CX1, CY1, CX2, CY2, Error^)
        Else Begin
          Error^.Code := SP_ERR_INVALID_DEPTH;
          Exit;
        End;
    SP_DeleteWindow(Window, Error^);
  End;
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_WIN_MERGEALL(Var Info: pSP_iInfo);
Var
  Idx, CX1, CX2, CY1, CY2: Integer;
  nfo, Screen: pSP_Window_Info;
  TempStr: aString;
Begin

  With Info^ Do Begin
    Idx := 1;
    While Idx < NUMBANKS Do Begin

      If SP_BankList[Idx]^.DataType = SP_WINDOW_BANK Then Begin
        SP_GetWindowDetails(SP_BankList[Idx]^.ID, nfo, Error^);
        SP_GetRegion(nfo^.Surface, nfo^.Width, nfo^.Height, TempStr, 0, 0, nfo^.Width, nfo^.Height, -1, Error^);
        SP_GetWindowDetails(0, Screen, Error^);
        CX1 := 0; CY1 := 0; CX2 := Screen^.Width; CY2 := Screen^.Height;
        SP_PutRegion(Screen^.Surface, nfo^.Left, nfo^.Top, nfo^.Width, nfo^.Height, @TempStr[1], Length(TempStr), 0, 1, CX1, CY1, CX2, CY2, Error^);
        SP_DeleteWindow(nfo^.ID, Error^);
      End Else
        Inc(Idx);

    End;
  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_WIN_SHOW(Var Info: pSP_iInfo);
Var
  WindowID, BankIdx: Integer;
  Window: pSP_Window_Info;
Begin

  WindowID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  BankIdx := SP_FindBankID(WindowID);
  If BankIdx > -1 Then Begin

    SP_GetWindowDetails(WindowID, Window, Info^.Error^);

    If Info^.Error^.Code = SP_ERR_OK Then Begin

      Window^.Visible := True;
      SP_NeedDisplayUpdate := True;

    End;

  End Else

    Info^.Error^.Code := SP_ERR_WINDOW_NOT_FOUND;

End;

Procedure SP_Interpret_WIN_HIDE(Var Info: pSP_iInfo);
Var
  WindowID, BankIdx: Integer;
  Window: pSP_Window_Info;
Begin

  WindowID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  BankIdx := SP_FindBankID(WindowID);
  If BankIdx > -1 Then Begin

    SP_GetWindowDetails(WindowID, Window, Info^.Error^);

    If Info^.Error^.Code = SP_ERR_OK Then Begin

      Window^.Visible := False;
      SP_NeedDisplayUpdate := True;

    End;

  End Else

    Info^.Error^.Code := SP_ERR_WINDOW_NOT_FOUND;

End;

Procedure SP_Interpret_WIN_FRONT(Var Info: pSP_iInfo);
Var
  WindowID: Integer;
  WindowIdx: Integer;
  Idx: Integer;
  Bank: pSP_Bank;
Begin

  // Bring a window to the front (make it the last bank in the banklist)

  WindowID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  DisplaySection.Enter;

  WindowIdx := SP_FindBankID(WindowID);
  If WindowIdx > -1 Then Begin
    Bank := SP_BankList[WindowIdx];
    For Idx := WindowIdx to Length(SP_BankList) -2 do
      SP_BankList[Idx] := SP_BankList[Idx +1];
    SP_BankList[Length(SP_Banklist) -1] := Bank;
    SP_NeedDisplayUpdate := True;
  End Else
    Info^.Error^.Code := SP_ERR_WINDOW_NOT_FOUND;

  DisplaySection.Leave;

End;

Procedure SP_Interpret_WIN_BACK(Var Info: pSP_iInfo);
Var
  WindowID, MinBank: Integer;
  WindowIdx: Integer;
  Bank: pSP_Bank;
Begin

  MinBank := 0;
  While (MinBank < Length(SP_BankList)) And (SP_BankList[MinBank]^.Protection or SP_BankList[MinBank]^.System) Do
    Inc(MinBank);

  If MinBank >= Length(SP_BankList) Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_WINDOW_EX;
    Exit;
  End;

  WindowID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  WindowIdx := SP_FindBankID(WindowID);

  If WindowIdx > -1 Then Begin
    Bank := SP_BankList[WindowIdx];
    For WindowIdx := WindowIdx DownTo MinBank Do
      SP_BankList[WindowIdx] := SP_BankList[WindowIdx -1];
    SP_BankList[MinBank] := Bank;
    SP_NeedDisplayUpdate := True;

  End Else
    Info^.Error^.Code := SP_ERR_WINDOW_NOT_FOUND;

End;


Procedure SP_Interpret_WINDOW(Var Info: pSP_iInfo);
Var
  WindowID: Integer;
  BankIdx: Integer;
  Locked: Boolean;
Begin

  WindowID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  BankIdx := SP_FindBankID(WindowID);
  If BankIdx > -1 Then Begin

    Locked := SCREENLOCK;
    SCREENLOCK := True;
    SCREENBANK := -1;
    SP_SetDrawingWindow(WindowID);
    SCREENLOCK := Locked;
    SP_NeedDisplayUpdate := True;

  End Else
    Info^.Error^.Code := SP_ERR_WINDOW_NOT_FOUND;

End;

Procedure SP_Interpret_WINDOW_GFX(Var Info: pSP_iInfo);
Var
  WindowID: Integer;
  BankIdx: Integer;
  Bank: pSP_Bank;
  Locked: Boolean;
Begin

  WindowID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  BankIdx := SP_FindBankID(WindowID);
  If BankIdx > -1 Then Begin

    Bank := SP_BankList[BankIdx];

    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Locked := SCREENLOCK;
      SCREENLOCK := True;
      SCREENBANK := -1;
      SP_SetDrawingWindow(WindowID);
      SCREENLOCK := Locked;

    End Else

      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else

    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_WIN_GRAB(Var Info: pSP_iInfo);
Var
  dX, dY: aFloat;
  N, W, H, T: Integer;
  Window: pSP_Window_Info;
Begin

  N := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_ConvertToOrigin_d(dX, dY);

  W := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  H := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  T := Round(SP_StackPtr^.Val);

  With Info^ Do Begin
    SP_GetWindowDetails(N, Window, Error^);
    If Error^.Code = SP_ERR_OK Then Begin
      SP_GetRegion(Window^.Surface, Window^.Stride, Window^.Height, SP_StackPtr^.Str, Round(dX), Round(dY), W, H, T, Error^);
      If Error^.Code = SP_ERR_OK Then
        SP_StackPtr^.OpType := SP_STRING;
    End;
  End;

End;

Procedure SP_Interpret_SCR_GRAB(Var Info: pSP_iInfo);
Var
  X, Y, W, H, T: Integer;
  Rgn: Array of Byte;
Begin

  X := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Y := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  W := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  H := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  T := Round(SP_StackPtr^.Val);

  // Using SCREEN GRAB means that the user wants whatever is being displayed (as opposed to what's in a window).
  // So create a dummy screen and render to it, then grab from it :)

  // Includes all windows and sprites.

  SetLength(Rgn, DISPLAYSTRIDE * DISPLAYHEIGHT);
//  SP_Composite(@Rgn[0], 0, 0, DISPLAYWIDTH, DISPLAYHEIGHT);

  SP_GetRegion(@Rgn[0], DISPLAYSTRIDE, DISPLAYHEIGHT, SP_StackPtr^.Str, X, Y, W, H, T, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then
    SP_StackPtr^.OpType := SP_STRING;

  SetLength(Rgn, 0);

End;

Procedure SP_Interpret_WIN_PUT(Var Info: pSP_iInfo);
Var
  dX, dY: aFloat;
  N, cX1, cY1, cX2, cY2, BankID: Integer;
  Window: pSP_Window_Info;
  Graphic: pSP_Graphic_Info;
  gBank: pSP_Bank;
Begin

  N := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_ConvertToOrigin_d(dX, dY);

  With Info^ Do Begin
    SP_GetWindowDetails(N, Window, Error^);
    If Error^.Code = SP_ERR_OK Then Begin
      cX1 := Window^.clipx1;
      cY1 := Window^.clipy1;
      cX2 := Window^.clipx2;
      cY2 := Window^.clipy2;
      If SP_StackPtr^.OpType = SP_VALUE Then Begin
        BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
        If BankID > -1 Then Begin
          gBank := SP_BankList[BankID];
          If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
            Graphic := @gBank^.Info[0];
            SP_PutRegion(Window^.Surface, Round(dX), Round(dY), Window^.Stride, Window^.Height, pByte(Graphic), -1, 0, 1, cX1, cY1, cX2, cY2, Error^);
          End Else
            Error.Code := SP_ERR_INVALID_BANK;
        End Else
          Error.Code := SP_ERR_BANK_NOT_FOUND;
      End Else
        SP_PutRegion(Window^.Surface, Round(dX), Round(dY), Window^.Stride, Window^.Height, @SP_StackPtr^.Str[1], Length(SP_StackPtr^.Str), 0, 1, cX1, cY1, cX2, cY2, Error^);
      If Window^.Visible Then Begin
        Inc(cX1, Window^.Left);
        Inc(cY1, Window^.Top);
        SP_SetDirtyRect(cX1, cY1, cX1 + cX2, cY1 + cY2);
      End;
      SP_NeedDisplayUpdate := True;
      Dec(SP_StackPtr);
    End;
  End;

End;

Procedure SP_Interpret_WIN_PUT_EX(Var Info: pSP_iInfo);
Var
  dX, dY: aFloat;
  N, cX1, cY1, cX2, cY2, BankID: Integer;
  Scale, Rotate: aFloat;
  Window: pSP_Window_Info;
  Graphic: pSP_Graphic_Info;
  gBank: pSP_Bank;
Begin

  N := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_ConvertToOrigin_d(dX, dY);

  Rotate := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Scale := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If Scale > 0 Then Begin
    With Info^ Do Begin
      SP_GetWindowDetails(N, Window, Error^);
      If Error^.Code = SP_ERR_OK Then Begin
        cX1 := Window^.clipx1;
        cY1 := Window^.clipy1;
        cX2 := Window^.clipx2;
        cY2 := Window^.clipy2;
        SP_AngleToRad(Rotate);
        If SP_StackPtr^.OpType = SP_VALUE Then Begin
          BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
          If BankID > -1 Then Begin
            gBank := SP_BankList[BankID];
            If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
              Graphic := @gBank^.Info[0];
              SP_PutRegion(Window^.Surface, Round(dX), Round(dY), Window^.Stride, Window^.Height, pByte(Graphic), -1, Rotate, Scale, cX1, cY1, cX2, cY2, Error^);
            End Else
              Error^.Code := SP_ERR_INVALID_BANK;
          End Else
            Error^.Code := SP_ERR_BANK_NOT_FOUND;
        End Else
          SP_PutRegion(Window^.Surface, Round(dX), Round(dY), Window^.Stride, Window^.Height, @SP_StackPtr^.Str[1], Length(SP_StackPtr^.Str), Rotate, Scale, cX1, cY1, cX2, cY2, Error^);
        If Error^.Code = SP_ERR_OK Then Begin
          If Window^.Visible Then Begin
            Inc(cX1, Window^.Left);
            Inc(cX2, Window^.Top);
            SP_SetDirtyRect(cX1, cY1, cX1 + cX2, cY1 + cY2);
          End;
          SP_NeedDisplayUpdate := True;
        End;
        Dec(SP_StackPtr);
      End;
    End;

  End Else Begin

    Info^.Error^.Code := SP_ERR_INVALID_SCALE;
    Exit;

  End;

End;

Procedure SP_Interpret_WIN_TRANS(Var Info: pSP_iInfo);
Var
  wIdx, TransVal: Integer;
  Window: pSP_Window_Info;
Begin

  wIdx := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  TransVal := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_GetWindowDetails(wIdx, Window, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then
    Window^.Transparent := Word(TransVal);

End;

Procedure SP_Interpret_WIN_ALPHA(Var Info: pSP_iInfo);
Var
  wIdx: Integer;
  Window: pSP_Window_Info;
Begin

  wIdx := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_GetWindowDetails(wIdx, Window, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then
    Window^.AlphaEnabled := Round(SP_StackPtr^.Val) <> 0;

  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_WIN_DEPTH(Var Info: pSP_iInfo);
Var
  wIdx, Depth: Integer;
Begin

  wIdx := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Depth := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_ResizeWindow(wIdx, -1, -1, Depth, SPFULLSCREEN, Info^.Error^);

End;

Procedure SP_Interpret_POKES(Var Info: pSP_iInfo);
Var
  Len, BankID, Offset, BankIdx, vLen: Integer;
  Bank: pSP_Bank;
  sPtr: pByte;
  sP1: pSP_StackItem;
Begin

  Sp1 := SP_StackPtr;
  sPtr := pByte(pNativeUInt(@SP_StackPtr^.Str)^);
  Dec(SP_StackPtr);
  Offset := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  BankID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If BankID > 0 Then
    BankIdx := SP_FindBankID(BankID)
  Else
    BankIdx := 0;

  If BankIdx > -1 Then Begin
    Bank := SP_BankList[BankIdx];
    Len := Length(Bank^.Memory);
    If (Offset >= 0) And (Offset < Len) Then Begin
      vLen := Length(Sp1^.Str);
      If Offset + vLen > Len Then
        vLen := (Len - Offset) +1;
      CopyMem(@Bank^.Memory[Offset], sPtr, vLen);
      Bank^.Changed := True;
      If Bank^.ID = SCREENBANK Then Begin
        SP_NeedDisplayUpdate := True;
        SP_InvalidateWholeDisplay;
      End;
    End Else
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
  End;

End;

Procedure SP_Interpret_POKE(Var Info: pSP_iInfo);
Var
  BankID, Offset, Value, BankIdx: Integer;
  Bank: pSP_Bank;
Begin

  Value := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Offset := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  BankID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If (Value > 255) or (Value < 0) Then
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE
  Else Begin
    BankIdx := SP_FindBankID(BankID);
    If BankIdx > -1 Then Begin
      Bank := SP_BankList[BankIdx];
      If (Offset >= 0) And (Offset < Length(Bank^.Memory)) Then Begin
        Bank^.Memory[Offset] := Value;
        Bank^.Changed := True;
        If Bank^.ID = SCREENBANK Then Begin
          SP_NeedDisplayUpdate := True;
          SP_InvalidateWholeDisplay;
        End;
      End Else
        Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End;

End;

Procedure SP_Interpret_DPOKE(Var Info: pSP_iInfo);
Var
  BankID, Offset, Value, BankIdx: Integer;
  Bank: pSP_Bank;
Begin

  Value := Word(Round(SP_StackPtr^.Val));
  Dec(SP_StackPtr);
  Offset := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  BankID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If (Value > $FFFF) or (Value < 0) Then
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE
  Else Begin
    BankIdx := SP_FindBankID(BankID);
    If BankIdx > -1 Then Begin
      Bank := SP_BankList[BankIdx];
      If (Offset >= 0) And (Offset < Length(Bank^.Memory) - 1) Then Begin
        pWord(@Bank^.Memory[Offset])^ := Value;
        Bank^.Changed := True;
        If Bank^.ID = SCREENBANK Then Begin
          SP_NeedDisplayUpdate := True;
          SP_InvalidateWholeDisplay;
        End;
      End Else
        Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End;

End;

Procedure SP_Interpret_QPOKE(Var Info: pSP_iInfo);
Var
  BankID, Offset, BankIdx: Integer;
  PokeVal: aFloat;
  Value: LongWord;
  Bank: pSP_Bank;
Begin

  PokeVal := SP_StackPtr^.Val;
  If (PokeVal < 0) or (PokeVal > $FFFFFFFF) Then Begin
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    Exit;
  End;

  Value := Round(PokeVal);
  Dec(SP_StackPtr);
  Offset := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  BankID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  BankIdx := SP_FindBankID(BankID);
  If BankIdx > -1 Then Begin
    Bank := SP_BankList[BankIdx];
    If (Offset >= 0) And (Offset < Length(Bank^.Memory) - 3) Then Begin
      pLongWord(@Bank^.Memory[Offset])^ := Value;
      Bank^.Changed := True;
      If Bank^.ID = SCREENBANK Then Begin
        SP_NeedDisplayUpdate := True;
        SP_InvalidateWholeDisplay;
      End;
    End Else
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_FPOKE(Var Info: pSP_iInfo);
Var
  BankID, Offset, BankIdx: Integer;
  Value: aFloat;
  Bank: pSP_Bank;
Begin

  Value := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Offset := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  BankID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  BankIdx := SP_FindBankID(BankID);
  If BankIdx > -1 Then Begin
    Bank := SP_BankList[BankIdx];
    If (Offset >= 0) And (Offset < Length(Bank^.Memory) - 7) Then Begin
      WriteaFloat(@Bank^.Memory[Offset], Value);
      Bank^.Changed := True;
      If Bank^.ID = SCREENBANK Then Begin
        SP_NeedDisplayUpdate := True;
        SP_InvalidateWholeDisplay;
      End;
    End Else
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_NEW(Var Info: pSP_iInfo);
Var
  Dir: aString;
Begin

  With Info^ Do Begin

    DoAutoSave(True);

    SP_DeleteIncludes;
    If PackageIsOpen Then SP_ClosePackage;
    SetLength(SP_Program, 0);
    SP_Program_Count := 0;
    SP_DeleteTempFiles;
    SP_DeleteAllWindows;
    SP_DeleteAllBanks(False);
    SP_CreateSystemUDGs(FONTBANKID);
    SP_Interpret_PAL_DEFAULT(Info);
    CSCALEX := 1;
    CSCALEY := 1;
    GWScaleFactor := 1;

    MATHMODE := 0;

    If SP_FileExists('s:startup-sequence') Then Begin
      Dir := SP_GetCurrentDir;
      SP_Execute('LOAD "s:startup-sequence": RUN', False, Error^);
      SP_SetCurrentDir(Dir, Error^);
    End;

    SP_FPNewProgram;
    SP_Program_Clear;
    CPAPER := 8;
    CINK := 0;
    CBOLD := 0;
    CITALIC := 0;
    SP_Reset_Temp_Colours;
    SP_CLS(CPAPER);
    Error^.Line := -2;
    Error^.Statement := 0;
    Error^.Code := -1;
    NXTLINE := -1;
    NXTSTATEMENT := -1;
    CONTLINE := 0;
    CONTSTATEMENT := 1;
    Error.Position := 1;
    PROGNAME := NEWPROGNAME;
    FILENAMED := False;
    MATHMODE := 0;
    FILECHANGED := False;
    SP_MakeSystemSounds;
    Error.Code := SP_EXIT;

  End;

End;

Procedure SP_Interpret_ON(Var Info: pSP_iInfo);
Var
  Condition: aString; Every: Integer;
Begin

  Condition := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  Every := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  With Info^ Do Begin
    If Every = -1 Then
      SP_ClearEvery
    Else Begin
      SP_AddEvery(Condition, Every, Error^.Line, Error^.Position, Error^.Statement, False);
      IgnoreEvery := True;
    End;

    Error^.ReturnType := SP_JUMP;
    OnActive := OnActive or OnEvery;

  End;

End;

Procedure SP_Interpret_ON_ERR(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    ERROR_LineNum := Error^.Line;
    ERROR_Statement := Error^.Position;
    ERROR_St := Error^.Statement;
    Error^.ReturnType := SP_JUMP;
    OnActive := OnActive or OnError;
  End;

End;

Procedure SP_Interpret_ON_COLLIDE(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    COLLIDE_LineNum := Error^.Line;
    COLLIDE_Statement := Error^.Position;
    COLLIDE_St := Error^.Statement;
    Error^.ReturnType := SP_JUMP;
    OnActive := OnActive or OnCollide;
  End;

End;

Procedure SP_Interpret_ON_MOUSEDOWN(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    MOUSEDOWN_LineNum := Error^.Line;
    MOUSEDOWN_Statement := Error^.Position;
    MOUSEDOWN_St := Error^.Statement;
    Error^.ReturnType := SP_JUMP;
    OnActive := OnActive or OnMouseDown;
  End;

End;

Procedure SP_Interpret_ON_MOUSEMOVE(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    MOUSEMOVE_LineNum := Error^.Line;
    MOUSEMOVE_Statement := Error^.Position;
    MOUSEMOVE_St := Error^.Statement;
    Error^.ReturnType := SP_JUMP;
    OnActive := OnActive or OnMouseMove;
  End;

End;

Procedure SP_Interpret_ON_MOUSEUP(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    MOUSEUP_LineNum := Error^.Line;
    MOUSEUP_Statement := Error^.Position;
    MOUSEUP_St := Error^.Statement;
    Error^.ReturnType := SP_JUMP;
    OnActive := OnActive or OnMouseUp;
  End;

End;

Procedure SP_Interpret_ON_KEYDOWN(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    KEYDOWN_LineNum := Error^.Line;
    KEYDOWN_Statement := Error^.Position;
    KEYDOWN_St := Error^.Statement;
    Error^.ReturnType := SP_JUMP;
    OnActive := OnActive or OnKeyDown;
  End;

End;

Procedure SP_Interpret_ON_KEYUP(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    KEYUP_LineNum := Error^.Line;
    KEYUP_Statement := Error^.Position;
    KEYUP_St := Error^.Statement;
    Error^.ReturnType := SP_JUMP;
    OnActive := OnActive or OnKeyUp;
  End;

End;

Procedure SP_Interpret_ON_WHEELUP(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    WHEELUP_LineNum := Error^.Line;
    WHEELUP_Statement := Error^.Position;
    WHEELUP_St := Error^.Statement;
    Error^.ReturnType := SP_JUMP;
    OnActive := OnActive or OnWheelUp;
  End;

End;

Procedure SP_Interpret_ON_WHEELDOWN(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    WHEELDOWN_LineNum := Error^.Line;
    WHEELDOWN_Statement := Error^.Position;
    WHEELDOWN_St := Error^.Statement;
    Error^.ReturnType := SP_JUMP;
    OnActive := OnActive or OnWheelDown;
  End;

End;

Procedure SP_Interpret_MENU_SHOW_OFF(Var Info: pSP_iInfo);
Begin

  MENUSHOW_LineNum := -1;
  OnActive := OnActive And (65535 - OnMenuShow);

End;

Procedure SP_Interpret_MENU_HIDE_OFF(Var Info: pSP_iInfo);
Begin

  MENUHIDE_LineNum := -1;
  OnActive := OnActive And (65535 - OnMenuHide);

End;

Procedure SP_Interpret_MENUITEM_OFF(Var Info: pSP_iInfo);
Begin

  MENUITEM_LineNum := -1;
  OnActive := OnActive And (65535 - OnMenuItem);

End;

Procedure SP_Interpret_ON_MENU_SHOW(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    MENUSHOW_LineNum := Error^.Line;
    MENUSHOW_Statement := Error^.Position;
    MENUSHOW_St := Error^.Statement;
    Error^.ReturnType := SP_JUMP;
    OnActive := OnActive or OnMenuShow;
  End;

End;

Procedure SP_Interpret_ON_MENU_HIDE(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    MENUHIDE_LineNum := Error^.Line;
    MENUHIDE_Statement := Error^.Position;
    MENUHIDE_St := Error^.Statement;
    Error^.ReturnType := SP_JUMP;
    OnActive := OnActive or OnMenuHide;
  End;

End;

Procedure SP_Interpret_ON_MENUITEM(Var Info: pSP_iInfo);
Begin

  With Info^ Do Begin
    MENUITEM_LineNum := Error^.Line;
    MENUITEM_Statement := Error^.Position;
    MENUITEM_St := Error^.Statement;
    Error^.ReturnType := SP_JUMP;
    OnActive := OnActive or OnMenuItem;
  End;

End;

Procedure SP_Interpret_ON_ERR_OFF(Var Info: pSP_iInfo);
Begin

  ERROR_LineNum := -1;
  OnActive := OnActive And (65535 - OnError);

End;

Procedure SP_Interpret_ON_COLLIDE_OFF(Var Info: pSP_iInfo);
Begin

  COLLIDE_LineNum := -1;
  OnActive := OnActive And (65535 - OnCollide);

End;

Procedure SP_Interpret_MOUSEDOWN_OFF(Var Info: pSP_iInfo);
Begin

  MOUSEDOWN_LineNum := -1;
  OnActive := OnActive And (65535 - OnMouseDown);

End;

Procedure SP_Interpret_MOUSEMOVE_OFF(Var Info: pSP_iInfo);
Begin

  MOUSEMOVE_LineNum := -1;
  OnActive := OnActive And (65535 - OnMouseMove);

End;

Procedure SP_Interpret_MOUSEUP_OFF(Var Info: pSP_iInfo);
Begin

  MOUSEUP_LineNum := -1;
  OnActive := OnActive And (65535 - OnMouseUp);

End;

Procedure SP_Interpret_KEYDOWN_OFF(Var Info: pSP_iInfo);
Begin

  KEYDOWN_LineNum := -1;
  OnActive := OnActive And (65535 - OnKeyDown);

End;

Procedure SP_Interpret_KEYUP_OFF(Var Info: pSP_iInfo);
Begin

  KEYUP_LineNum := -1;
  OnActive := OnActive And (65535 - OnKeyUp);

End;

Procedure SP_Interpret_WHEELUP_OFF(Var Info: pSP_iInfo);
Begin

  WHEELUP_LineNum := -1;
  OnActive := OnActive And (65535 - OnWheelUp);

End;

Procedure SP_Interpret_WHEELDOWN_OFF(Var Info: pSP_iInfo);
Begin

  WHEELDOWN_LineNum := -1;
  OnActive := OnActive And (65535 - OnWheelDown);

End;

Procedure SP_Interpret_CLEAR(Var Info: pSP_iInfo);
var
  tStr: aString;
Begin

  tStr := '';
  SP_PreParse(True, False, Info^.Error^, tStr);
  SP_CLS(CPAPER);

End;

Procedure SP_Interpret_CLEAR_VAR(Var Info: pSP_iInfo);
Var
  VarName: aString;
  VarIdx: Integer;
Begin

  VarName := SP_StackPtr^.Str;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    Dec(SP_StackPtr);
    VarIdx := SP_FindNumArray(VarName);
    If VarIdx = -1 Then Begin
      ERRStr := VarName;
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND
    End Else Begin
      SP_FillNumArray(VarIdx, SP_StackPtr^.Val);
    End;
  End Else
    If SP_StackPtr^.OpType = SP_STRVAR Then Begin
      Dec(SP_StackPtr);
      VarIdx := SP_FindStrArray(VarName);
      If VarIdx = -1 Then Begin
        ERRStr := VarName + '$';
        Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND
      End Else Begin
        SP_FillStrArray(VarIdx, SP_StackPtr^.Str);
      End;
    End;

  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_CLEAR_ERR(Var Info: pSP_iInfo);
Begin

  Info^.Error^.Code := 0;

End;

Procedure SP_Interpret_UNDIM(Var Info: pSP_iInfo);
Var
  VarIdx: Integer;
  VarName: aString;
Begin

  // Removes an array from memory. Quite a lot more complex than it at first seems -
  // Cached indices to other arrays have to be changed to accommodate the deletion.

  VarName := SP_StackPtr^.Str;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    VarIdx := SP_FindNumArray(VarName);
    If VarIdx = -1 Then Begin
      ERRStr := VarName;
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND
    End Else Begin
      SP_DeleteNumArray(VarName, Info^.Error^);
    End;
  End Else
    If SP_StackPtr^.OpType = SP_STRVAR Then Begin
      VarIdx := SP_FindStrArray(VarName);
      If VarIdx = -1 Then Begin
        ERRStr := VarName + '$';
        Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
      End Else Begin
        SP_DeleteStrArray(VarName, Info^.Error^);
      End;
    End;

  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_YIELD(Var Info: pSP_iInfo);
Begin

  CB_Yield;

End;

Procedure SP_Interpret_FILL(Var Info: pSP_iInfo);
Var
  dX, dY: aFloat;
  Ink: Byte;
Begin

  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_ConvertToOrigin_d(dX, dY);
  If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;

  If T_INVERSE = 0 Then
    Ink := T_INK
  Else
    Ink := T_PAPER;

  If (dx >= T_CLIPX1) And (dy >= T_CLIPY1) And (dx < T_CLIPX2) And (dy < T_CLIPY2) Then
    SP_FloodFill(SCREENPOINTER, Round(dX), Round(dY), SCREENSTRIDE, SCREENHEIGHT, Ink);

  If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, DISPLAYWIDTH, DISPLAYHEIGHT);
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_FILLTEX(Var Info: pSP_iInfo);
Var
  dX, dY: aFloat;
  TextureStr: aString;
  tW, tH, BankID: Integer;
  Valid, BankFill: Boolean;
  gBank: pSP_Bank;
  Graphic: pSP_Graphic_Info;
Begin

  tw := 0; th := 0;

  BankFill := False;
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_ConvertToOrigin_d(dX, dY);
  If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;

  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    TextureStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
        Graphic := @gBank^.Info[0];
        tW := NativeUInt(Graphic^.Data);
        tH := NativeUInt(Graphic);
        BankFill := True;
      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else Begin
    TextureStr := SP_StackPtr^.Str;
  End;
  Dec(SP_StackPtr);

  If Not BankFill Then Begin
    Valid := False;
    If TextureStr = '' Then
      SP_DefaultFill(TextureStr, T_INK);
    If Length(TextureStr) > 10 Then Begin
      tW := pLongWord(@TextureStr[1])^;
      tH := pLongWord(@TextureStr[5])^;
      If Length(TextureStr) - 10 = tW * tH Then Valid := True;
    End;
    If Not Valid Then Begin
      TextureStr := SP_StringToTexture(TextureStr);
      If TextureStr = '' Then
        SP_DefaultFill(TextureStr, T_INK);
      tW := pLongWord(@TextureStr[1])^;
      tH := pLongWord(@TextureStr[5])^;
    End;
  End;

  SP_TextureFill(SCREENPOINTER, Round(dX), Round(dY), SCREENSTRIDE, SCREENHEIGHT, TextureStr, tW, tH);
  If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, DISPLAYWIDTH, DISPLAYHEIGHT);
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_RECTANGLE_TO(Var Info: pSP_iInfo);
Var
  Y1, Y2, X1, X2: aFloat;
Begin

  Y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X1 := DRPOSX;
  Y1 := DRPOSY;

  SP_ConvertToOrigin_d(X1, Y1);
  SP_ConvertToOrigin_d(X2, Y2);
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  SP_DrawRectangle(Round(X1), Round(Y1), Round(X2), Round(Y2));

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_RECTFILL_TO(Var Info: pSP_iInfo);
Var
  Valid, BankFill: Boolean;
  TextureStr: aString;
  tW, tH, BankID: Integer;
  X1, Y1, X2, Y2: aFloat;
  gBank: pSP_Bank;
  Graphic: pSP_Graphic_Info;
Begin

  tw := 0; th := 0;
  BankFill := False;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    TextureStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
        Graphic := @gBank^.Info[0];
        tW := NativeUInt(Graphic^.Data);
        tH := NativeUInt(Graphic);
        BankFill := True;
      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else Begin
    TextureStr := SP_StackPtr^.Str;
  End;
  Dec(SP_StackPtr);

  Y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X1 := DRPOSX;
  Y1 := DRPOSY;

  SP_ConvertToOrigin_d(X1, Y1);
  SP_ConvertToOrigin_d(X2, Y2);
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  If Not BankFill Then Begin
    Valid := False;
    If TextureStr = '' Then
      SP_DrawSolidRectangle(Round(X1), Round(Y1), Round(X2), Round(Y2))
    Else Begin
      If Length(TextureStr) > 10 Then Begin
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
        If Length(TextureStr) - 10 = tW * tH Then Valid := True;
      End;
      If Not Valid Then Begin
        TextureStr := SP_StringToTexture(TextureStr);
        If TextureStr = '' Then
          SP_DefaultFill(TextureStr, T_INK);
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
      End;
      SP_DrawTexRectangle(Round(X1), Round(Y1), Round(X2), Round(Y2), TextureStr, tW, tH);
    End;
  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_ARECTANGLE_TO(Var Info: pSP_iInfo);
Var
  Y1, Y2, X1, X2: aFloat;
Begin

  Y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  X1 := DRPOSX;
  Y1 := DRPOSY;

  SP_ConvertToOrigin_d(X1, Y1);
  SP_ConvertToOrigin_d(X2, Y2);
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  SP_DrawRectangle32Alpha(Round(X1), Round(Y1), Round(X2), Round(Y2));

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_ARECTFILL_TO(Var Info: pSP_iInfo);
Var
  Valid, BankFill: Boolean;
  TextureStr: aString;
  tW, tH, BankID: Integer;
  X1, Y1, X2, Y2: aFloat;
  gBank: pSP_Bank;
  Graphic: pSP_Graphic_Info;
Begin

  tw := 0; th := 0;
  BankFill := False;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    TextureStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
        Graphic := @gBank^.Info[0];
        tW := NativeUInt(Graphic^.Data);
        tH := NativeUInt(Graphic);
        BankFill := True;
      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else Begin
    TextureStr := SP_StackPtr^.Str;
  End;
  Dec(SP_StackPtr);

  Y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X1 := DRPOSX;
  Y1 := DRPOSY;
  SP_ConvertToOrigin_d(X1, Y1);
  SP_ConvertToOrigin_d(X2, Y2);
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  If Not BankFill Then Begin
    Valid := False;
    If TextureStr = '' Then
      SP_DrawSolidRectangle32Alpha(Round(X1), Round(Y1), Round(X2), Round(Y2))
    Else Begin
      If Length(TextureStr) > 10 Then Begin
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
        If Length(TextureStr) - 10 = tW * tH Then Valid := True;
      End;
      If Not Valid Then Begin
        TextureStr := SP_StringToTexture(TextureStr);
        If TextureStr = '' Then
          SP_DefaultFill(TextureStr, T_INK);
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
      End;
      SP_DrawTexRectangle32Alpha(Trunc(X1), Trunc(Y1), Trunc(X2), Trunc(Y2), TextureStr, tW, tH);
    End;
  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_RECTANGLE(Var Info: pSP_iInfo);
Var
  Y1, Y2, X1, X2: aFloat;
Begin

  Y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  if NativeUInt(SP_StackPtr) > NativeUInt(SP_StackStart) then Begin
    Y1 := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    X1 := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
  End Else Begin
    X1 := DRPOSX; X2 := X2 + DRPOSX;
    Y1 := DRPOSY; Y2 := Y2 + DRPOSY;
  End;

  SP_ConvertToOrigin_d(X1, Y1);
  SP_ConvertToOrigin_d(X2, Y2);
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  SP_DrawRectangle(Round(X1), Round(Y1), Round(X2), Round(Y2));

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_RECTANGLE2(Var Info: pSP_iInfo);
Var
  Y1, H, X1, W, X2, Y2: aFloat;
Begin

  H := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  W := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  X2 := X1 + W;
  Y2 := Y1 + H;
  SP_ConvertToOrigin_d(X1, Y1);
  SP_ConvertToOrigin_d(X2, Y2);
  X2 := X2 - 1;
  Y2 := Y2 - 1;

  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  SP_DrawRectangle(Round(X1), Round(Y1), Round(X2), Round(Y2));

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_RECTFILL(Var Info: pSP_iInfo);
Var
  Valid, BankFill: Boolean;
  TextureStr: aString;
  tW, tH, BankID: Integer;
  X1, Y1, X2, Y2: aFloat;
  gBank: pSP_Bank;
  Graphic: pSP_Graphic_Info;
Begin

  tw := 0; th := 0;
  BankFill := False;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    TextureStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
        Graphic := @gBank^.Info[0];
        tW := NativeUInt(Graphic^.Data);
        tH := NativeUInt(Graphic);
        BankFill := True;
      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else Begin
    TextureStr := SP_StackPtr^.Str;
  End;
  Dec(SP_StackPtr);

  Y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  if NativeUInt(SP_StackPtr) > NativeUInt(SP_StackStart) then Begin
    Y1 := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    X1 := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
  End Else Begin
    X1 := DRPOSX; X2 := X2 + DRPOSX;
    Y1 := DRPOSY; Y2 := Y2 + DRPOSY;
  End;

  SP_ConvertToOrigin_d(X1, Y1);
  SP_ConvertToOrigin_d(X2, Y2);
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  If Not BankFill Then Begin
    Valid := False;
    If TextureStr = '' Then
      SP_DrawSolidRectangle(Round(X1), Round(Y1), Round(X2), Round(Y2))
    Else Begin
      If Length(TextureStr) > 10 Then Begin
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
        If Length(TextureStr) - 10 = tW * tH Then Valid := True;
      End;
      If Not Valid Then Begin
        TextureStr := SP_StringToTexture(TextureStr);
        If TextureStr = '' Then
          SP_DefaultFill(TextureStr, T_INK);
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
      End;
      SP_DrawTexRectangle(Round(X1), Round(Y1), Round(X2), Round(Y2), TextureStr, tW, tH);
    End;
  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_RECTFILL2(Var Info: pSP_iInfo);
Var
  Valid, BankFill: Boolean;
  TextureStr: aString;
  tW, tH, BankID: Integer;
  X1, Y1, X2, Y2, W, H: aFloat;
  gBank: pSP_Bank;
  Graphic: pSP_Graphic_Info;
Begin

  tw := 0; th := 0;
  BankFill := False;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    TextureStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
        Graphic := @gBank^.Info[0];
        tW := NativeUInt(Graphic^.Data);
        tH := NativeUInt(Graphic);
        BankFill := True;
      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else Begin
    TextureStr := SP_StackPtr^.Str;
  End;
  Dec(SP_StackPtr);

  H := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  W := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  X2 := X1 + W;
  Y2 := Y1 + H;
  SP_ConvertToOrigin_d(X1, Y1);
  SP_ConvertToOrigin_d(X2, Y2);
  X2 := X2 - 1;
  Y2 := Y2 - 1;
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  If Not BankFill Then Begin
    Valid := False;
    If TextureStr = '' Then
      SP_DrawSolidRectangle(Round(X1), Round(Y1), Round(X2), Round(Y2))
    Else Begin
      If Length(TextureStr) > 10 Then Begin
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
        If Length(TextureStr) - 10 = tW * tH Then Valid := True;
      End;
      If Not Valid Then Begin
        TextureStr := SP_StringToTexture(TextureStr);
        If TextureStr = '' Then
          SP_DefaultFill(TextureStr, T_INK);
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
      End;
      SP_DrawTexRectangle(Round(X1), Round(Y1), Round(X2), Round(Y2), TextureStr, tW, tH);
    End;
  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_POLYLINE(Var Info: pSP_iInfo);
Var
  pX, pY, dX, dY: aFloat;
  NumPoints, iSize, Idx, pIdx, vIdx: Integer;
  VarName: aString;
  Points: Array of TSP_Point;
  IsOpen: Boolean;
Begin

  IsOpen := SP_StackPtr^.Val = 1;
  Dec(SP_StackPtr);

  SKIPFIRSTPOINT := False;
  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
      Dec(SP_StackPtr);
      Idx := 0;
      While Idx < Length(NumArrays) Do Begin
        If NumArrays[Idx].Name = VarName Then Begin
          If (NumArrays[Idx].NumIndices = 2) And (NumArrays[Idx].Indices[0] >= 3) Then Begin
            iSize := NumArrays[Idx].Indices[1];
            If iSize >= 2 Then Begin
              dX := NumArrays[Idx].Values[0]^.Value;
              dY := NumArrays[Idx].Values[1]^.Value;
              If iSize > 2 Then Begin
                T_INK := Round(NumArrays[Idx].Values[2]^.Value);
              End;
              SP_ConvertToOrigin_d(dX, dY);
              If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;
              DRPOSX := dX;
              DRPOSY := dY;
              vIdx := iSize;
              For pIdx := 0 To NumArrays[Idx].Indices[0] -2 Do Begin
                pX := NumArrays[Idx].Values[vIdx]^.Value;
                pY := NumArrays[Idx].Values[vIdx + 1]^.Value;
                SP_ConvertToOrigin_d(pX, pY);
                If WINFLIPPED Then pY := (SCREENHEIGHT - 1) - pY;
                SP_DrawLine(pX - DRPOSX, pY - DRPOSY);
                If iSize > 2 Then
                  T_INK := Round(NumArrays[Idx].Values[vIdx + 2]^.Value);
                Inc(vIdx, iSize);
              End;
              If Not IsOpen Then
                SP_DrawLine(dX - DRPOSX, dY - DRPOSY);
              SP_NeedDisplayUpdate := True;
              Exit;
            End;
          End Else
            Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
        End;
        Inc(Idx);
      End;
      ERRStr := VarName;
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
    End Else
      Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
  End Else Begin

    NumPoints := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);

    SetLength(Points, NumPoints);
    Dec(NumPoints);

    While NumPoints >= 0 Do Begin

      pY := SP_StackPtr^.Val;
      Dec(SP_StackPtr);
      pX := SP_StackPtr^.Val;
      Dec(SP_StackPtr);
      SP_ConvertToOrigin_d(pX, pY);
      If WINFLIPPED Then pY := (SCREENHEIGHT - 1) - pY;
      Points[NumPoints].X := pX;
      Points[NumPoints].Y := pY;
      Dec(NumPoints);

    End;

    DRPOSX := Points[0].X;
    DRPOSY := Points[0].Y;

    For NumPoints := 1 To Length(Points) - 1 Do
      SP_DrawLine(Points[NumPoints].X - DRPOSX, Points[NumPoints].Y - DRPOSY);

    If Not IsOpen Then
      SP_DrawLine(Points[0].X - DRPOSX, Points[0].Y - DRPOSY);

  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_POLYFILL(Var Info: pSP_iInfo);
Var
  Points: Array of TSP_Point;
  VarName, TextureStr: aString;
  NumPoints, iSize, Idx, pIdx, vIdx, tW, tH, BankID: Integer;
  pX, pY: aFloat;
  gBank: pSP_Bank;
  Graphic: pSP_Graphic_Info;
  Valid, BankFill: Boolean;
Label
  DrawIt;
Begin

  tw := 0; th := 0;
  BankFill := False;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    TextureStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
        Graphic := @gBank^.Info[0];
        tW := NativeUInt(Graphic^.Data);
        tH := NativeUInt(Graphic);
        BankFill := True;
      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else Begin
    TextureStr := SP_StackPtr^.Str;
  End;
  Dec(SP_StackPtr);

  VarName := '';
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    VarName := Lower(SP_StackPtr^.Str);
    Dec(SP_StackPtr);
  End;

  If VarName <> '' Then Begin
    Idx := 0;
    ERRStr := VarName;
    While Idx < Length(NumArrays) Do Begin
      If NumArrays[Idx].Name = VarName Then Begin
        numPoints := NumArrays[Idx].Indices[0];
        If (NumArrays[Idx].NumIndices = 2) And (NumPoints >= 3) Then Begin
          iSize := NumArrays[Idx].Indices[1];
          If iSize >= 2 Then Begin
            SetLength(Points, numPoints);
            vIdx := 0;
            For pIdx := 0 To NumPoints -1 Do Begin
              pX := NumArrays[Idx].Values[vIdx]^.Value;
              pY := NumArrays[Idx].Values[vIdx + 1]^.Value;
              SP_ConvertToOrigin_d(pX, pY);
              If WINFLIPPED Then pY := (SCREENHEIGHT - 1) - pY;
              Inc(vIdx, iSize);
              Points[pIdx].X := pX;
              Points[pIdx].Y := pY;
            End;
            Goto DrawIt;
          End;
        End Else
          Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
      End;
      Inc(Idx);
    End;
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;

  End Else Begin

    NumPoints := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);

    SetLength(Points, NumPoints);
    Idx := NumPoints - 1;

    While Idx >= 0 Do Begin

      pY := SP_StackPtr^.Val;
      Dec(SP_StackPtr);
      pX := SP_StackPtr^.Val;
      Dec(SP_StackPtr);
      SP_ConvertToOrigin_d(pX, pY);
      If WINFLIPPED Then pY := (SCREENHEIGHT - 1) - pY;
      Points[Idx].X := pX;
      Points[Idx].Y := pY;
      Dec(Idx);

    End;

  End;

  DrawIt:

  If Info^.Error^.Code = SP_ERR_OK Then Begin

    If Not BankFill Then Begin
      Valid := False;
      If TextureStr = '' Then
        SP_PolygonSolidFill(Points)
      Else Begin
        If Length(TextureStr) > 10 Then Begin
          tW := pLongWord(@TextureStr[1])^;
          tH := pLongWord(@TextureStr[5])^;
          If Length(TextureStr) - 10 = tW * tH Then Valid := True;
        End;
        If Not Valid Then Begin
          TextureStr := SP_StringToTexture(TextureStr);
          If TextureStr = '' Then
            SP_DefaultFill(TextureStr, T_INK);
          tW := pLongWord(@TextureStr[1])^;
          tH := pLongWord(@TextureStr[5])^;
        End;
        SP_PolygonFill(Points, TextureStr, tW, tH);
      End;
    End;
    SP_NeedDisplayUpdate := True;

  End;

End;

Procedure SP_Interpret_SCRCOPY(Var Info: pSP_iInfo);
Var
  SrcX, SrcY, DstX, DstY: aFloat;
  SrcIdx, SrcW, SrcH, DstIdx, DstW, DstH: Integer;
  SrcWindow, DstWindow: pSP_Window_Info;
Begin

  // All coords in window space, width and height in pixels

  With Info^ Do Begin

    SrcIdx := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    SrcX := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    SrcY := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    SrcW := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    SrcH := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    DstIdx := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    DstX := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    DstY := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    DstW := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    DstH := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);

    If DstW = 0 Then Begin
      DstW := SrcW;
      DstH := SrcH;
    End;

    SP_GetWindowDetails(SrcIdx, SrcWindow, Error^);
    If Error.Code <> SP_ERR_OK Then Exit;

    SP_GetWindowDetails(DstIdx, DstWindow, Error^);
    If Error.Code <> SP_ERR_OK Then Exit;

    // Convert coords to the ORIGIN-coordinate space for both windows

    If (SrcWindow^.orgx <> 0) or (SrcWindow^.orgy <> 0) Then Begin
      SrcX := SrcX - SrcWindow^.orgx;
      SrcY := SrcY - SrcWindow^.orgy;
    End;

    If (SrcWindow^.orgw - SrcWindow^.orgx <> SrcWindow^.Width) or (SrcWindow^.orgh - SrcWindow^.orgy <> SrcWindow^.Height) Then Begin
      SrcX := SrcX / ((SrcWindow^.orgw - SrcWindow^.orgx)/SrcWindow^.Width);
      SrcY := SrcY / ((SrcWindow^.orgh - SrcWindow^.orgy)/SrcWindow^.Height);
    End;

    If (DstWindow^.orgx <> 0) or (DstWindow^.orgy <> 0) Then Begin
      DstX := DstX - DstWindow^.orgx;
      DstY := DstY - DstWindow^.orgy;
    End;

    If (DstWindow^.orgw - DstWindow^.orgx <> DstWindow^.Width) or (DstWindow^.orgh - DstWindow^.orgy <> DstWindow^.Height) Then Begin
      DstX := DstX / ((DstWindow^.orgw - DstWindow^.orgx)/DstWindow^.Width);
      DstY := DstY / ((DstWindow^.orgh - DstWindow^.orgy)/DstWindow^.Height);
    End;

    If Error^.Code <> SP_ERR_OK Then
      Exit;

    SP_CopyRect(SrcWindow^.Surface, SrcWindow^.Stride, SrcWindow^.Height, Round(SrcX), Round(SrcY), SrcW, SrcH,
                DstWindow^.Surface, DstWindow^.Stride, DstWindow^.Height, Round(DstX), Round(DstY), DstW, DstH,
                DstWindow^.clipx1, DstWindow^.clipy1, DstWindow^.clipx2, DstWindow^.clipy2, Error^);

    If DstWindow^.Visible Then SP_SetDirtyRect(DstWindow^.Left, DstWindow^.Top, DstWindow^.Left + DstWindow^.Width, DstWindow^.Top + DstWindow^.Height);

    SP_NeedDisplayUpdate := True;

  End;

End;

Procedure SP_Interpret_RADIANS(Var Info: pSP_iInfo);
Begin

  MATHMODE := 0;

End;

Procedure SP_Interpret_DEGREES(Var Info: pSP_iInfo);
Begin

  MATHMODE := 1;

End;

Procedure SP_Interpret_TURNS(Var Info: pSP_iInfo);
Begin

  MATHMODE := 2;

End;

Procedure SP_Interpret_GRADIANS(Var Info: pSP_iInfo);
Begin

  MATHMODE := 3;

End;

Procedure SP_Interpret_RECOVER(Var Info: pSP_iInfo);
Var
  aSave: Boolean;
Begin

  aSave := AUTOSAVE;
  AUTOSAVE := False;
  If SP_FileExists('s:autosave') Then Begin
    SP_LoadProgram('s:autosave', False, False, nil, Info^.Error^);
    NXTLINE := -1;
    NXTSTATEMENT := -1;
  End Else
    Info^.Error^.Code := SP_ERR_NO_RECOVER;
  AUTOSAVE := aSave;

End;

Procedure SP_Interpret_OLD(Var Info: pSP_iInfo);
Begin

  SP_SaveProgram('s:old_temp', -1, Info^.Error^);
  If SP_FileExists('s:oldprog') Then Begin
    SP_LoadProgram('s:oldprog', False, False, nil, Info^.Error^);
    NXTLINE := -1;
    NXTSTATEMENT := -1;
  End;
  SP_DeleteFile('s:oldprog', Info^.Error^);
  SP_FileRename(SP_ConvertFilenameToHost('s:old_temp', Info^.Error^), SP_ConvertFilenameToHost('s:oldprog', Info^.Error^), Info^.Error^);

End;

Procedure SP_Interpret_FONT(Var Info: pSP_iInfo);
Var
  FontID: Integer;
Begin

  FontID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_SetSystemFont(FontID, Info^.Error^);

End;

Procedure SP_Interpret_FONT_NEW(Var Info: pSP_iInfo);
Var
  Width, Height, Mode, Trans, WChars, xc, yc: Integer;
  i, j, c, MinChar: Integer;
  Graphic: pSP_Graphic_Info;
  Window: pSP_Window_Info;
  Font: pSP_Font_Info;
  sPtr, dPtr: pByte;
  Bank: pSP_Bank;
  fName: aString;
Begin

  Width := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Height := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Mode := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Trans := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  fName := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  MinChar := Round(SP_StackPtr^.Val);

  If fName <> '' Then Begin
    ERRStr := fName;
    If SP_FileExists(fName) Then
      i := SP_New_GraphicC(fName, $FFFF, Info^.Error^)
    Else Begin
      Info^.Error^.Code := SP_ERR_FILE_MISSING;
      Exit;
    End;
    i := SP_FindBankID(i);
    Graphic := @SP_BankList[i]^.Info[0];
  End Else Begin
    Graphic := nil;
    i := -1;
  End;

  SP_StackPtr^.Val := SP_Font_Bank_Create(Mode, Width, Height, Trans);

  If i <> -1 Then Begin

    WChars := Integer(Graphic^.Width) div Width;
    Bank := SP_BankList[SP_FindBankID(Round(SP_StackPtr^.Val))];
    Font := @Bank^.Info[0];
    For c := MinChar to 127 Do Begin
      j := c - MinChar;
      xc := (j Mod WChars) * Width;
      yc := (j Div WChars) * Height;
      If yc + Height > Integer(Graphic^.Height) Then
        Break
      Else Begin
        sPtr := Graphic^.Data;
        dPtr := @Bank^.Memory[Font^.Font_Info[c].Data];
        SP_CopyRect(sPtr, Graphic^.Width, Graphic^.Height, xc, yc, Width, Height,
                    dPtr, Width, Height, 0, 0, Width, Height,
                    0, 0, Width, Height, Info^.Error^);
      End;
    End;

    SP_GetWindowDetails(SCREENBANK, Window, Info^.Error^);
    For c := 0 To 255 Do
      Window^.Palette[c] := Graphic^.Palette[c];

    SP_DeleteBank(i, Info^.Error^);

  End;

End;

Procedure SP_Interpret_FONT_TRANS(Var Info: pSP_iInfo);
Var
  TransIdx, FontID, Index: Integer;
Begin

  FontID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  TransIdx := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Index := SP_FindBankID(FontID);

  If Index >= 0 Then Begin

    If SP_BankList[Index]^.DataType = SP_FONT_BANK Then Begin

        FONTTRANSPARENT := TransIdx;

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_FONT_ERASE(Var Info: pSP_iInfo);
Var
  FontID, Index: Integer;
Begin

  FontID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If FontID <> SYSFONT Then Begin

    Index := SP_FindBankID(FontID);

    If Index > 0 Then Begin

      If SP_BankList[Index]^.DataType = SP_FONT_BANK Then Begin

        If FontID = FONTBANKID Then
          SP_SetSystemFont(SYSFONT, Info^.Error^);

        SP_DeleteBank(FontID, Info^.Error^);

      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;

    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_PROTECTED;

End;

Procedure SP_Interpret_SAVE_BANK(Var Info: pSP_iInfo);
Var
  Filename: aString; BankNum: LongWord;
Begin

  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  BankNum := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_SaveBank(Filename, BankNum, False, Info^.Error^);

End;

Procedure SP_Interpret_SAVE_BANK_DATA(Var Info: pSP_iInfo);
Var
  Filename: aString; BankNum: LongWord;
Begin

  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  BankNum := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_SaveBank(Filename, BankNum, True, Info^.Error^);

End;

Procedure SP_Interpret_LOAD_BANK(Var Info: pSP_iInfo);
Var
  Filename: aString;
  BankNum: Integer;
Begin

  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  If NativeUInt(SP_StackPtr) > NativeUInt(SP_StackStart) Then Begin
    BankNum := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End Else
    BankNum := -1;

  SP_LoadBank(Filename, BankNum, Info^.Error^);

End;

Procedure SP_Interpret_NEW_BANK(Var Info: pSP_iInfo);
Var
  Filename: aString;
Begin

  Filename := SP_StackPtr^.Str;

  SP_StackPtr^.Val := SP_LoadBank(Filename, -1, Info^.Error^);
  SP_StackPtr^.OpType := SP_VALUE;

End;

Procedure SP_Interpret_WAIT(Var Info: pSP_iInfo);
Var
  Delay: Integer;
  TargetTicks, CurrentTicks: aFloat;
  OldScreenLock: Boolean;
Begin

  Delay := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If Delay < 0 Then Begin // WAIT SCREEN n
    // Force a display update, then wait for it - and then wait for any remaining time
    // necessary to complete the desired period.
    TargetTicks := CB_GETTICKS - Delay;
    OldScreenLock := SCREENLOCK;
    SCREENLOCK := False;
    CauseUpdate := True;
    SP_NeedDisplayUpdate := False;
    SP_ForceScreenUpdate;
    While (CB_GETTICKS < TargetTicks) And (KEYSTATE[K_ESCAPE] = 0) And Not (BREAKSIGNAL Or QUITMSG) Do
      CB_YIELD;
    SCREENLOCK := OldScreenLock;
  End Else
    If Delay = 0 Then // WAIT SCREEN - forces a display update
      SP_ForceScreenUpdate
    Else Begin // WAIT n
      CurrentTicks := Round(CB_GetTicks);
      TargetTicks := CurrentTicks + Delay;
      Repeat
        if Delay >= 10 then CB_YIELD;
      Until (CB_GetTicks >= TargetTicks) or (KEYSTATE[K_ESCAPE] = 1) or BREAKSIGNAL or QUITMSG;
    End;

  If (KEYSTATE[K_ESCAPE] = 1) or BREAKSIGNAL Then
    Info^.Error^.ReturnType := SP_JUMP;

End;

Procedure SP_Interpret_WAIT_KEY(Var Info: pSP_iInfo);
Begin

  // Waits for a key. Returns as soon as a key is pressed.

  SP_ForceScreenUpdate;
  While (Length(ActiveKeys) = 0) And Not QUITMSG Do Begin
    SP_WaitForSync;
    If (KEYSTATE[K_ESCAPE] = 1) or BREAKSIGNAL Then
      Info^.Error^.ReturnType := SP_JUMP;
  End;

End;

Procedure SP_Interpret_WAIT_KEY_PRESS(Var Info: pSP_iInfo);
Begin

  // Waits for a key *press* - if a key is down then wait for it to go up;
  // then wait for any key to go down.

  SP_ForceScreenUpdate;
  While (Length(ActiveKeys) <> 0) And Not (BREAKSIGNAL or QUITMSG) Do SP_WaitForSync;
  While (Length(ActiveKeys) = 0) And Not (BREAKSIGNAL or QUITMSG) Do SP_WaitForSync;
  If (KEYSTATE[K_ESCAPE] = 1) or BREAKSIGNAL Then
    Info^.Error^.ReturnType := SP_JUMP;

End;

Procedure SP_Interpret_WAIT_KEY_UP(Var Info: pSP_iInfo);
Begin

  // If a key is down then wait for it to go up

  SP_ForceScreenUpdate;
  While (Length(ActiveKeys) <> 0) And Not (BREAKSIGNAL or QUITMSG) Do Begin
    SP_WaitForSync;
    If (KEYSTATE[K_ESCAPE] = 1) or BREAKSIGNAL Then
      Info^.Error^.ReturnType := SP_JUMP;
  End;

End;

Procedure SP_Interpret_BANK_NEW(Var Info: pSP_iInfo);
Var
  Size: Integer;
Begin

  If SP_StackPtr^.OpType <> SP_NUMVAR Then
    Size := Round(SP_StackPtr^.Val)
  Else Begin
    Size := 0;
    Inc(SP_StackPtr);
  End;

  SP_StackPtr^.Val := SP_NewBank(Size);

End;

Procedure SP_Interpret_BANK_SIZE(Var Info: pSP_iInfo);
Var
  ID, Size: Integer;
Begin

  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Size := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  ID := SP_FindBankID(ID);
  If ID >= 0 Then
    SP_ResizeBank(ID, Size)
  Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_BANK_ERASE(Var Info: pSP_iInfo);
Var
  ID: Integer;
Begin

  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  ID := SP_FindBankID(ID);
  If ID >= 0 Then
    SP_DeleteBank(ID, Info^.Error^)
  Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_BANK_ERASE_ALL(Var Info: pSP_iInfo);
Var
  Idx: Integer;
Begin

  Idx := 0;
  While Idx < Length(SP_BankList) Do
    If Not pSP_Bank(SP_BankList[Idx])^.Protection Then
      SP_DeleteBank(Idx, Info^.Error^)
    Else
      Inc(Idx);

End;

Procedure SP_Interpret_BANK_COPY(Var Info: pSP_iInfo);
Var
  SrcID, DstID: Integer;
Begin

  SrcID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  DstID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SrcID := SP_FindBankID(SrcID);
  If SrcID >= 0 Then Begin
    DstID := SP_FindBankID(DstID);
    If DstID >= 0 Then
      SP_CopyBank(SrcID, DstID, Info^.Error^)
    Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_BANK_COPY_EX(Var Info: pSP_iInfo);
Var
  SrcID, DstID, Start, Len, Offset: Integer;
Begin

  SrcID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Start := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Len := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  DstID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Offset := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_CopyBankEx(SrcID, Start, Len, DstID, Offset, Info^.Error^)

End;

Procedure SP_Interpret_STREAM_NEW(Var Info: pSP_iInfo);
Begin

  If SP_StackPtr^.OpType = SP_VALUE Then

    SP_StackPtr^.Val := SP_NewStream(Round(SP_StackPtr^.Val), '', Info^.Error^)

  Else Begin

    SP_StackPtr^.Val := SP_NewStream(-1, SP_StackPtr^.Str, Info^.Error^);
    SP_StackPtr^.OpType := SP_VALUE;

  End;

End;

Procedure SP_Interpret_STREAM_READ(Var Info: pSP_iInfo);
Var
  StreamID: Integer;
  Count, BytesRead: Integer;
  Buffer: Array of Byte;
Begin

  StreamID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Count := Round(SP_StackPtr^.Val);

  SetLength(Buffer, Count);
  BytesRead := SP_StreamRead(StreamID, @Buffer[0], Count, Info^.Error^);

  With SP_StackPtr^ Do Begin
    SetLength(Str, BytesRead);
    CopyMem(@Str[1], @Buffer[0], BytesRead);
    OpType := SP_STRING;
  End;

End;

Procedure SP_Interpret_STREAM_READLN(Var Info: pSP_iInfo);
Var
  StreamID: Integer;
  SepChar: aString;
Begin

  If SP_StackPtr^.OpType = SP_Value Then Begin
    If SP_StackPtr^.Val = -1 Then
      SepChar := ''
    Else
      SepChar := aChar(Trunc(SP_StackPtr^.Val) And $FF);
  End Else
    If SP_StackPtr^.Str = '' Then
      SepChar := #0
    Else
      SepChar := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  StreamID := Round(SP_StackPtr^.Val);
  With SP_StackPtr^ Do Begin
    if SepChar = '' Then
      Str := SP_StreamReadline(StreamID, Info^.Error^)
    Else
      Str := SP_StreamReadlineChar(StreamID, SepChar[1], Info^.Error^);
    OpType := SP_STRING;
  End;

End;

Procedure SP_Interpret_STREAM_READFILE(Var Info: pSP_iInfo);
Var
  StreamID, l, idx: Integer;
  SepChar, VarName: aString;
  tempList: TAnsiStringlist;
Begin

  VarName := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_Value Then Begin
    If SP_StackPtr^.Val = -1 Then
      SepChar := ''
    Else
      SepChar := aChar(Trunc(SP_StackPtr^.Val) And $FF);
  End Else
    If SP_StackPtr^.Str = '' Then
      SepChar := #0
    Else
      SepChar := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  StreamID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  l := SP_StreamLen(StreamID, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    tempList := TAnsiStringlist.Create;
    While (SP_StreamPos(StreamID, Info^.Error^) < l) And (Info^.Error^.Code = SP_ERR_OK) Do
      if SepChar = '' Then
        tempList.Add(SP_StreamReadline(StreamID, Info^.Error^))
      Else
        tempList.Add(SP_StreamReadlineChar(StreamID, SepChar[1], Info^.Error^));
    If Info^.Error^.Code = SP_ERR_OK Then Begin
      idx := SP_CreateStrArray(VarName, LongWordToString(tempList.Count), 0, '', BASE, False, Info^.Error^);
      For l := 0 To tempList.Count -1 Do
        SP_UpdateStrArray(idx +1, VarName, LongWordToString(LongWord(l) + BASE), '', tempList[l], -1, -1, Info^.Error^);
    End;
    tempList.Free;
  End;

End;

Procedure SP_Interpret_STREAM_WRITE(Var Info: pSP_iInfo);
Var StreamID: Integer;
Begin

  StreamID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_StreamWrite(StreamID, @SP_StackPtr^.Str[1], Length(SP_StackPtr^.Str), Info^.Error^);
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_STREAM_SEEK(Var Info: pSP_iInfo);
Var StreamID, Position: Integer;
Begin

  StreamID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Position := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If SP_StreamSeek(StreamID, Position, Info^.Error^) < 0 Then
    Info^.Error^.Code := SP_ERR_INVALID_STREAM_ID;

End;

Procedure SP_Interpret_STREAM_CLOSE(Var Info: pSP_iInfo);
Var StreamID: Integer;
Begin

  StreamID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If SP_StreamClose(StreamID, Info^.Error^) < 0 Then
    Info^.Error^.Code := SP_ERR_INVALID_STREAM_ID;

End;

Procedure SP_Interpret_SETDIR(Var Info: pSP_iInfo);
Var
  Dir: aString;
Begin

  Dir := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  SP_SetCurrentDir(Dir, Info^.Error^);

End;

Procedure SP_Interpret_PAL_DEFAULT(Var Info: pSP_iInfo);
Var
  Idx: Integer;
  Palette: Array[0..255] of TP_Colour;
Begin

  For Idx := 0 To 223 Do
    Palette[Idx] := DefaultPalette[Idx];
  Idx := 224;
  While Idx < 256 Do Begin
    Palette[Idx].R := (Idx - 224)*8;
    Palette[Idx].G := (Idx - 224)*8;
    Palette[Idx].B := (Idx - 224)*8;
    Inc(Idx);
  End;
  SP_SetPalette(0, Palette);

End;

Procedure SP_Interpret_PAL_EGA(Var Info: pSP_iInfo);
Var
  Idx: Integer;
  Palette: Array[0..255] of TP_Colour;
Begin

  For Idx := 0 To 63 Do
    Palette[Idx] := EGAPalette[Idx];
  SP_SetPalette(0, Palette);

End;

Procedure SP_Interpret_PAL_CGA(Var Info: pSP_iInfo);
Var
  Idx: Integer;
  Palette: Array[0..255] of TP_Colour;
Begin

  For Idx := 0 To 15 Do
    Palette[Idx] := CGAPalette[Idx];
  SP_SetPalette(0, Palette);

End;

Procedure SP_Interpret_PAL_APPLELGR(Var Info: pSP_iInfo);
Var
  Idx: Integer;
  Palette: Array[0..255] of TP_Colour;
Begin

  For Idx := 0 To 15 Do
    Palette[Idx] := AppleLGRPalette[Idx];
  SP_SetPalette(0, Palette);

End;

Procedure SP_Interpret_PAL_APPLEHGR(Var Info: pSP_iInfo);
Var
  Idx: Integer;
  Palette: Array[0..255] of TP_Colour;
Begin

  For Idx := 0 To 7 Do
    Palette[Idx] := AppleHGRPalette[Idx];
  SP_SetPalette(0, Palette);

End;

Procedure SP_Interpret_PAL_CPC(Var Info: pSP_iInfo);
Var
  Idx: Integer;
  Palette: Array[0..255] of TP_Colour;
Begin

  For Idx := 0 To 26 Do
    Palette[Idx] := CPCPalette[Idx];
  SP_SetPalette(0, Palette);

End;

Procedure SP_Interpret_PAL_LOAD(Var Info: pSP_iInfo);
Var
  Filename: aString;
  Offset: Integer;
Begin

  Offset := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  SP_LoadPalette(Filename, Offset, Info^.Error^);

End;

Procedure SP_Interpret_PAL_SAVE(Var Info: pSP_iInfo);
Var
  Filename: aString;
  num, offset: Integer;
Begin

  num := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Offset := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  SP_SavePalette(Filename, Offset, Num, Info^.Error^);

End;

Procedure SP_Interpret_EXECUTE(Var Info: pSP_iInfo);
Var
  NewError: TSP_ErrorCode;
  LineItem: TSP_GOSUB_Item;
  pTokens: paString;
  OldCommand, Tkns: aString;
  CurLine: Integer;
  NextStatement: Boolean;
Begin

  // Stack our current position in the program, so we can return later

  If SP_StackPtr^.Str = '' Then Exit;

  With Info^ Do Begin

    If Error^.Line >= 0 Then
      LineItem := SP_ConvertLineStatement(Error^.Line, Error^.Statement + 1)
    Else Begin
      LineItem.Line := -2;
      LineItem.Statement := SP_FindStatement(@COMMAND_TOKENS, Error^.Statement + 1);
      LineItem.St := Error^.Statement + 1;
    End;
    SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_GOSUB, Info^.Error^);

    CONTLINE := Error^.Line;
    CONTSTATEMENT := Error^.Statement +1;

    // Store the current COMMAND_TOKENS so that this is a true recursive system
    // Then just execute the string provided.

    With SP_StackPtr^ Do Begin

      NewError.Line := -1;
      NewError.Statement := 1;
      NewError.Position := 1;
      NewError.ReturnType := 0;
      NewError.Code := SP_ERR_OK;

      If Str[1] = #$F Then Begin
        NewError.Code := SP_ERR_SYNTAX_ERROR;
        CopyMem(@Error^.Line, @NewError.Line, SizeOf(TSP_ErrorCode));
        Dec(SP_GOSUB_STACKPTR);
        Dec(SP_StackPtr);
        Exit;
      End Else

        If Str[1] <> #$E Then Begin

          Str := SP_TokeniseLine(Str, False, False) + SP_TERMINAL_SEQUENCE;
          If (Ord(Str[newError.Position]) = SP_SYMBOL) And (Str[newError.Position +1] = '?') Then Begin
            Str[newError.Position] := aChar(SP_KEYWORD);
            Str := Copy(Str, 1, newError.Position) + LongWordToString(SP_KW_PRINT) + Copy(Str, newError.Position + 2);
          End;
          SP_Convert_ToPostFix(Str, NewError.Position, NewError);
          SP_TestConsts(Str, 1, NewError, False);
          If NewError.Code <> SP_ERR_OK Then Begin
            CopyMem(@Error^.Line, @NewError.Line, SizeOf(TSP_ErrorCode));
            Dec(SP_GOSUB_STACKPTR);
            Dec(SP_StackPtr);
            Exit;
          End;

        End;

      NewError.Position := SP_FindStatement(@Str, 1);
      OldCommand := COMMAND_TOKENS;
      COMMAND_TOKENS := Str;
      NXTSTATEMENT := -1;
      NXTLINE := -1;
      Dec(SP_StackPtr);

      Tkns := COMMAND_TOKENS;
      NextStatement := True;

      While NextStatement Do Begin

        NextStatement := False;

        pTokens := @Tkns;
        SP_InterpretCONTSafe(pTokens, NewError.Position, NewError);

        // If the code caused an Error, then bail now and remove the return address from the stack

        If (NewError.Code <> SP_ERR_OK) or (NXTLINE >= SP_Program_Count) Then Begin

          CopyMem(@Error^.Line, @NewError.Line, SizeOf(TSP_ErrorCode));
          Dec(SP_GOSUB_STACKPTR);
          Exit;

        End Else

        // Otherwise, follow the jump if necessary

          If NXTLINE <> -1 Then Begin

            If NXTLINE = -2 Then Begin CurLine := -1;
              Tkns := COMMAND_TOKENS;
              If NXTSTATEMENT = -1 Then
                Break;
              NewError.Position := NXTSTATEMENT;
            End Else Begin
              CurLine := NXTLINE;
              Tkns := SP_Program[CurLine];
              If NXTSTATEMENT <> -1 Then
                NewError.Position := NXTSTATEMENT
              Else Begin
                NewError.Statement := 1;
                NewError.Position := SP_FindStatement(@Tkns, 1);
              End;
            End;

            NXTSTATEMENT := -1;
            Inc(NXTLINE);
            If NXTLINE <> 0 Then Begin
              NewError.Line := CurLine;
              NextStatement := True;
            End;

          End;

      End;

    End;

    // Now execute a RETURN to get back to where we were.

    NXTLINE := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Line;
    NXTSTATEMENT := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Statement;
    Error^.Statement := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].St;
    If SP_GOSUB_Stack[Length(SP_GOSUB_Stack) -1].Source = SP_KW_ERROR Then IGNORE_ON_ERROR := False;
    Dec(SP_GOSUB_STACKPTR);
    COMMAND_TOKENS := OldCommand;

    If NXTSTATEMENT = -1 Then
      NXTLINE := -1;

    Error^.ReturnType := SP_JUMP;

  End;

End;

Procedure SP_Interpret_ROTATE(Var Info: pSP_iInfo);
Begin

  DRHEADING := DRHEADING + SP_StackPtr^.Val;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_ROTATETO(Var Info: pSP_iInfo);
Begin

  DRHEADING := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_FACE(Var Info: pSP_iInfo);
Var
  ToX, ToY: Integer;
Begin

  ToY := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  ToX := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  DRHEADING := ArcTan2(ToY - DRPOSY, ToX - DRPOSX);
  SP_RadToAngle(DRHEADING);

End;

Procedure SP_Interpret_MOVE(Var Info: pSP_iInfo);
Var
  Hdg, Dist, dX, dY: aFloat;
Begin

  Dist := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Hdg := DRHEADING;
  SP_AngleToRad(Hdg);

  dX := SP_ConvertToScreenX(DRPOSX) + (Dist * Cos(Hdg));
  dY := SP_ConvertToScreenY(DRPOSY) + (Dist * Sin(Hdg));
  SP_ConvertToOrigin_d(dX, dY);
  If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;

  DRPOSX := dX;
  DRPOSY := dY;

  SKIPFIRSTPOINT := False;

End;

Procedure SP_Interpret_MOVEXY(Var Info: pSP_iInfo);
Var
  XPos, YPos: aFloat;
Begin

  YPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  XPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_ConvertToOrigin_d(XPos, YPos);
  If WINFLIPPED Then YPos := -YPos;

  DRPOSX := DRPOSX + XPos;
  DRPOSY := DRPOSY + YPos;

  SP_NeedDisplayUpdate := True;
  SKIPFIRSTPOINT := False;

End;

Procedure SP_Interpret_MOVETO(Var Info: pSP_iInfo);
Var
  dX, dY: aFloat;
Begin

  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_ConvertToOrigin_d(dX, dY);
  If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;

  DRPOSX := dX;
  DRPOSY := dY;

  SKIPFIRSTPOINT := False;

End;

Procedure SP_Interpret_DRAWTURTLE(Var Info: pSP_iInfo);
Var
  Hdg, Dist, dX, dY, odX, odY: aFloat;
  tBool: Boolean;
Begin

  Dist := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Hdg := DRHEADING;
  SP_AngleToRad(Hdg);

  tBool := WINORIGIN;
  WINORIGIN := False;
  dX := Dist * Cos(Hdg);
  dY := Dist * Sin(Hdg);
  SP_ConvertToOrigin_d(dX, dY);
  odX := DRPOSX + dX;
  odY := DRPOSY + dY;
  If WINFLIPPED Then dY := -dY;
  SP_DrawLine(dX, dY);
  DRPOSX := odX;
  DRPOSY := odY;
  SP_NeedDisplayUpdate := True;
  WINORIGIN := tBool;

End;

Procedure SP_Interpret_VOLUME(Var Info: pSP_iInfo);
Begin

  SP_SetGlobalVolume(SP_StackPtr^.Val, Info^.Error^);
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_SAMPLE_LOAD(Var Info: pSP_iInfo);
Var
  Filename: aString;
Begin

  Filename := SP_StackPtr^.Str;
  SP_StackPtr^.Val := SP_NewBank(0);
  SP_Sample_Load(Round(SP_StackPtr^.Val), Filename, Info^.Error^);

End;

Procedure SP_Interpret_SAMPLE_PLAY(Var Info: pSP_iInfo);
Var
  Rate, Loops, Volume, Panning, Channel: aFloat;
  Sample: Integer;
  RateStr: aString;
  PlayingChannel: LongWord;
Begin

  Rate := 0;
  Channel := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Sample := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Loops := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  If SP_StackPtr^.OpType = SP_Value Then
    Rate := SP_StackPtr^.Val
  Else
    RateStr := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  Volume := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Panning := SP_StackPtr^.Val;

  PlayingChannel := SP_Sample_Play(Sample, Rate, RateStr, Loops, Volume, Panning, Info^.Error^);

  If Channel = 1 Then
    SP_StackPtr^.Val := PlayingChannel
  Else
    Dec(SP_StackPtr);

End;

Procedure SP_Interpret_SAMPLE_ERASE(Var Info: pSP_iInfo);
Begin

  SP_Sample_Delete(Round(SP_StackPtr^.Val), Info^.Error^);
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_SAMPLE_RATE(Var Info: pSP_iInfo);
Var
  Rate, ID: Integer;
Begin

  Rate := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Sample_Rate(ID, Rate, Info^.Error^);

End;

Procedure SP_Interpret_SAMPLE_DEPTH(Var Info: pSP_iInfo);
Var
  Depth, ID: Integer;
Begin

  Depth := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Sample_Bits(ID, Depth, Info^.Error^);

End;

Procedure SP_Interpret_SAMPLE_VOLUME(Var Info: pSP_iInfo);
Var
  Volume: aFloat;
  ID: Integer;
Begin

  Volume := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Sample_Volume(ID, Volume, Info^.Error^);

End;

Procedure SP_Interpret_SAMPLE_PAN(Var Info: pSP_iInfo);
Var
  Panning: aFloat;
  ID: Integer;
Begin

  Panning := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Sample_Panning(ID, Panning, Info^.Error^);

End;

Procedure SP_Interpret_SAMPLE_STEREO(Var Info: pSP_iInfo);
Var
  Stereo, ID: Integer;
Begin

  Stereo := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Sample_Stereo(ID, Stereo, Info^.Error^);

End;

Procedure SP_Interpret_SAMPLE_NEW(Var Info: pSP_iInfo);
Var
  Rate, Stereo, Bits, Size: Integer;
Begin

  Size := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Stereo := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Bits := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Rate := Round(SP_StackPtr^.Val);

  SP_StackPtr^.Val := SP_Sample_Create(Rate, Bits, Stereo, Size, Info^.Error^);

End;

Procedure SP_Interpret_CHANNEL_PAUSE(Var Info: pSP_iInfo);
Var
  ID: LongWord;
Begin

  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Channel_Pause(ID, Info^.Error^);

End;

Procedure SP_Interpret_CHANNEL_STOP(Var Info: pSP_iInfo);
Var
  ID: LongWord;
Begin

  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Channel_Stop(ID, Info^.Error^);

End;

Procedure SP_Interpret_CHANNEL_RESUME(Var Info: pSP_iInfo);
Var
  ID: LongWord;
Begin

  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Channel_Resume(ID, Info^.Error^);

End;

Procedure SP_Interpret_CHANNEL_SEEK(Var Info: pSP_iInfo);
Var
  ID, Seek: LongWord;
Begin

  Seek := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Channel_Seek(ID, Seek, Info^.Error^);

End;

Procedure SP_Interpret_CHANNEL_RATE_VAL(Var Info: pSP_iInfo);
Var
  ID, Rate: LongWord;
Begin

  Rate := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Channel_Rate(ID, Rate, '', Info^.Error^);

End;

Procedure SP_Interpret_CHANNEL_RATE_STR(Var Info: pSP_iInfo);
Var
  ID: LongWord;
  RateStr: aString;
Begin

  RateStr := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Channel_Rate(ID, 0, RateStr, Info^.Error^);

End;

Procedure SP_Interpret_CHANNEL_PAN(Var Info: pSP_iInfo);
Var
  ID: LongWord; Pan: aFloat;
Begin

  Pan := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Channel_Pan(ID, Pan, Info^.Error^);

End;

Procedure SP_Interpret_CHANNEL_VOLUME(Var Info: pSP_iInfo);
Var
  ID: LongWord; Volume: aFloat;
Begin

  Volume := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Channel_Volume(ID, Volume, Info^.Error^);

End;

Procedure SP_Interpret_PLAY(Var Info: pSP_iInfo);
Var
  aSync: Boolean;
  NumStrs, i: Integer;
  PLAYStrs: Array of aString;
Begin

  aSync := Round(SP_StackPtr^.Val) <> 0;
  Dec(SP_StackPtr);

  NumStrs := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SetLength(PLAYStrs, NumStrs);
  For i := 1 To NumStrs Do Begin
    PLAYStrs[i -1] := SP_StackPtr^.Str;
    Dec(SP_StackPtr);
  End;

  If SoundEnabled Then
    If ASync Then
      SP_PLAY_ASync(PLAYStrs)
    Else
      SP_PLAY(PLAYStrs, Info^.Error^.Code);

End;

Procedure SP_Interpret_PLAY_STOP(Var Info: pSP_iInfo);
Begin

  PLAYSignalHalt(-1);

End;

Procedure SP_Interpret_MUSIC_PLAY(Var Info: pSP_iInfo);
Var
  Filename: aString;
  Volume: aFloat;
  Pause, Loop: Integer;
Begin

  Loop := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Pause := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Volume := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_STRING Then Begin
    Filename := SP_StackPtr^.Str;
    Dec(SP_StackPtr);
    SP_Music_Play(Filename, Volume, Pause, Loop, Info^.Error^);
  End Else Begin
    SP_Music_Play_Bank(Round(SP_StackPtr^.Val), Volume, Pause, Loop, Info^.Error^);
    Dec(SP_StackPtr);
  End;

End;

Procedure SP_Interpret_MUSIC_STOP(Var Info: pSP_iInfo);
Begin

  SP_Music_Stop(Info^.Error^);

End;

Procedure SP_Interpret_MUSIC_PAUSE(Var Info: pSP_iInfo);
Begin

  SP_Music_Pause(Info^.Error^);

End;

Procedure SP_Interpret_MUSIC_RESUME(Var Info: pSP_iInfo);
Begin

  SP_Music_Resume(Info^.Error^);

End;

Procedure SP_Interpret_MUSIC_SEEK(Var Info: pSP_iInfo);
Var
  Seek: aFloat;
Begin

  Seek := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_Music_Seek(Seek, Info^.Error^);

End;

Procedure SP_Interpret_MUSIC_VOLUME(Var Info: pSP_iInfo);
Var
  Volume: aFloat;
Begin

  Volume := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_Music_Volume(Volume, Info^.Error^);

End;

Procedure SP_Interpret_DEF_PROC(Var Info: pSP_iInfo);
Var
  Name: aString;
  Idx: Integer;
  TempLine: TSP_GOSUB_Item;
Begin

  // The name should be on the stack at this point.
  // Scan the procedure list for the correct proc, and jump.

  Name := Lower(SP_StackPtr^.Str);
  If SP_StackPtr^.OpType in [SP_STRING, SP_STRVAR] Then
    Name := Name + '$';
  Dec(SP_StackPtr);

  Idx := 0;
  While Idx <= SP_ProcsListPtr Do Begin

    If SP_ProcsList[Idx].Name = Name Then
      Break
    Else
      Inc(Idx);

  End;

  If Idx <= SP_ProcsListPtr Then Begin

    TempLine := SP_ConvertLineStatement(SP_ProcsList[Idx].EP_Line, SP_ProcsList[Idx].EP_St + 1);
    NXTLINE := TempLine.Line;
    NXTSTATEMENT := TempLine.Statement;
    With Info^ Do Begin
      Error^.Line := SP_ProcsList[Idx].EP_Line;
      Error^.Statement := SP_ProcsList[Idx].EP_St + 1;
      Error^.ReturnType := SP_JUMP;
    End;

  End Else Begin

    ERRStr := Name;
    Info^.Error^.Code := SP_ERR_PROC_NOT_CLOSED;

  End;

End;

Procedure SP_Interpret_PROC(Var Info: pSP_iInfo);
Begin

  SP_SetUpPROC(0, Info^.Token^.Cache, Info^.Error^);

End;

Function SP_SetUpPROC(CALLType: Byte; Var CacheVal: LongWord; Var Error: TSP_ErrorCode): Integer;
Type
  TProcVar = Packed Record
    ID: Byte;
    Len: LongWord;
  End;
  pProcVar = ^TProcVar;
Var
  ProcName, VarList, VarName: aString;
  Idx, Idx2, Idx3, vIdx, VarOffsetN, VarOffsetS, ParamCount,
  VarOffsetNA, VarOffsetSA, NumParams, NumIndices: Integer;
  TempLine: TSP_GOSUB_Item;
  SliceFlags: Byte;
  SliceFrom, SliceTo: Integer;
  nVar: pProcVar;
  Reference: Boolean;
  nPtr: pSP_NumVarContent;
  sPtr: pSP_StrVarContent;
Label
  FoundIt;
Begin

  Result := -1;

  // Get the parameter count and the procedure name

  NumParams := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  // If we've visited this PROC before, then get the cached index, set up the stack
  // and jump forward to skip the proc name search

  If CacheVal > 0 Then Begin
    Idx := CacheVal -1;
    If SP_StackPtr^.Str = '' Then
      Dec(SP_StackPtr);
    If CALLType <> 0 Then
      CALLType := SP_StackPtr^.OpType;
    Dec(SP_StackPtr);
    Goto FoundIt;
  End;

  ProcName := Lower(SP_StackPtr^.Str);
  If ProcName <> '' Then Begin
    If SP_StackPtr^.OpType in [SP_STRVAR, SP_STRING] Then
      ProcName := ProcName + '$';
  End;
  If CALLType <> 0 Then
    CALLType := SP_StackPtr^.OpType;
  Dec(SP_StackPtr);

  If ProcName = '' Then Begin
    // This was a PROCID or PROCID$ call - so get the index from the first parameter, which
    // is the current stack item!
    Dec(NumParams);
    Idx := Round(SP_StackPtr^.Val);
    CacheVal := Idx +1;
    Dec(SP_StackPtr);
    Goto FoundIt;
  End;

  // Find the procedure.

  Idx := 0;
  While Idx <= SP_ProcsListPtr Do Begin
    If SP_ProcsList[Idx].Name = ProcName Then Begin
      CacheVal := Idx +1;
      Break;
    End Else
      Inc(Idx);
  End;

FoundIt:

  If Idx <= SP_ProcsListPtr Then Begin

    // Check the parameter count

    If SP_ProcsList[Idx].NumVars <> NumParams Then Begin
      Error.Code := SP_ERR_PROC_PARAM_COUNT;
    End Else Begin

      // Now pick up the parameters from the proclist entry
      // and create vars with values from the stack.

      Idx2 := 1;
      ParamCount := 0;
      VarList := SP_ProcsList[Idx].VarList;
      VarOffsetN := NumNV;
      VarOffsetS := NumSV;
      VarOffsetNA := Length(NumArrays);
      VarOffsetSA := Length(StrArrays);
      While Idx2 < Length(VarList) Do Begin
        Inc(ParamCount);
        nVar := @VarList[Idx2];
        Inc(Idx2, SizeOf(TProcVar));
        VarName := Copy(VarList, Idx2, nVar.Len);
        Reference := SP_ProcsList[Idx].VarTypes[ParamCount] = '!';
        Inc(Idx2, nVar.Len);
        If nVar.ID = 0 Then Begin
          Case SP_StackPtr^.OpType of
            SP_VALUE:
              Begin
                // User passed a value as an expression result
                If Not Reference Then Begin
                  Idx3 := SP_NewNumVar;
                  NumVars[Idx3]^.Content.VarType := SP_SIMPLE;
                  NumVars[Idx3]^.Name := Lower(VarName);
                  NumVars[Idx3]^.ProcVar := True;
                  NumVars[Idx3]^.Content.Value := SP_StackPtr^.Val;
                  NumVars[Idx3]^.ContentPtr := @NumVars[Idx3].Content;
                  Dec(SP_StackPtr);
                End Else Begin
                  Error.Code := SP_ERR_PARAMETER_ERROR;
                  Exit;
                End;
              End;
            SP_ARRAY_ASSIGN:
              Begin
                // User passed a numeric array element by reference
                SP_StackToString(Round(SP_StackPtr^.Val));
                With SP_StackPtr^ Do
                  nPtr := SP_GetNumArrayPtr(Round(Val), Str, gbIndices, gbKey, Error);
                If Error.Code = SP_ERR_OK Then Begin
                  Idx3 := SP_NewNumVar;
                  NumVars[Idx3]^.Name := Lower(VarName);
                  NumVars[Idx3]^.ProcVar := True;
                  NumVars[Idx3]^.ContentPtr := nPtr;
                End;
                Dec(SP_StackPtr);
              End;
            SP_NUMVAR:
              Begin
                // User passed a numeric variable by reference
                vIdx := Round(SP_StackPtr^.Val);
                If vIdx = 0 Then Begin
                  vIdx := SP_FindNumVar(SP_StackPtr^.Str);
                  If vIdx = -1 Then Begin
                    Error.Code := SP_ERR_MISSING_VAR;
                    SP_ResizeNumVars(VarOffsetN);
                    SP_ResizeStrVars(VarOffsetS);
                    Exit;
                  End;
                End Else
                  Dec(vIdx);
                Idx3 := SP_NewNumVar;
                NumVars[Idx3]^.Name := Lower(VarName);
                NumVars[Idx3]^.ProcVar := True;
                NumVars[Idx3].ContentPtr := NumVars[vIdx].ContentPtr;
                Dec(SP_StackPtr);
              End;
          Else
            Error.Code := SP_ERR_PARAMETER_ERROR;
            Exit;
          End;
        End Else
          Case SP_StackPtr^.OpType of
            SP_STRING:
              Begin
                If Not Reference Then Begin
                  Idx3 := SP_NewStrVar;
                  StrVars[Idx3]^.Name := Lower(VarName);
                  StrVars[Idx3]^.Content.Value := SP_StackPtr^.Str;
                  StrVars[Idx3]^.ProcVar := True;
                  StrVars[Idx3]^.ContentPtr := @StrVars[Idx3]^.Content;
                  StrVars[Idx3]^.Content.DLen := 0;
                  Dec(SP_StackPtr);
                End Else Begin
                  Error.Code := SP_ERR_PARAMETER_ERROR;
                  Exit;
                End;
              End;
            SP_SLICE_ASSIGN:
              With SP_StackPtr^ Do Begin
                SliceFlags := Byte(Str[1]);
                NumIndices := Round(Val);
                Dec(SP_StackPtr);
                If SliceFlags And 1 = 1 Then Begin
                  SliceTo := Round(SP_StackPtr^.Val);
                  Dec(SP_StackPtr);
                End Else
                  SliceTo := -1;
                If SliceFlags And 2 = 2 Then Begin
                  If SP_StackPtr^.OpType = SP_VALUE Then Begin
                    SliceFrom := Round(SP_StackPtr^.Val);
                    Dec(SP_StackPtr);
                  End Else
                    SliceFrom := SliceTo;
                End Else
                  SliceFrom := -1;
                With SP_StackPtr^ Do
                  If OpType = SP_VALUE Then Begin
                    Inc(SP_StackPtr);
                    SP_StackToString(NumIndices);
                  End Else Begin
                    gbIndices := LongWordToString(SliceTo);
                    Il := SizeOf(LongWord);
                    SliceFrom := -1;
                    SliceTo := -1;
                  End;
                If SP_FindStrArray(SP_StackPtr^.Str) = -1 Then Begin
                  Idx3 := SP_FindStrVar(SP_StackPtr^.Str);
                  If Idx3 > -1 Then Begin
                    If (SliceTo < 1) or (SliceTo > Length(StrVars[Idx3].ContentPtr^.Value)) Then Begin
                      ERRStr := SP_StackPtr^.Str;
                      Error.Code := SP_ERR_SUBSCRIPT_WRONG;
                      Exit;
                    End Else Begin
                      vIdx := SP_NewStrVar;
                      StrVars[vIdx]^.Name := Lower(VarName);
                      StrVars[vIdx]^.ProcVar := True;
                      StrVars[vIdx]^.Content.SliceFrom := SliceFrom;
                      StrVars[vIdx]^.Content.SliceTo := SliceTo;
                      StrVars[vIdx]^.ContentPtr := StrVars[Idx3]^.ContentPtr;
                    End;
                  End Else
                    Error.Code := SP_ERR_MISSING_VAR;
                End Else Begin
                  With SP_StackPtr^ Do               // fix me
                    sPtr := SP_GetStrArrayPtr(Round(Val), Str, gbIndices, gbKey, Error);
                  If Error.Code = SP_ERR_OK Then Begin
                    vIdx := SP_NewStrVar;
                    StrVars[vIdx]^.Name := Lower(VarName);
                    StrVars[vIdx]^.ProcVar := True;
                    StrVars[vIdx]^.Content.SliceFrom := SliceFrom;
                    StrVars[vIdx]^.Content.SliceTo := SliceTo;
                    StrVars[vIdx]^.ContentPtr := sPtr;
                  End;
                  Dec(SP_StackPtr);
                End;
              End;
            SP_STRVAR:
              Begin
                // User passed a string variable by reference
                vIdx := Round(SP_StackPtr^.Val);
                If vIdx = 0 Then Begin
                  vIdx := SP_FindStrVar(SP_StackPtr^.Str);
                  If vIdx = -1 Then Begin
                    Error.Code := SP_ERR_MISSING_VAR;
                    SP_ResizeNumVars(VarOffsetN);
                    SP_ResizeStrVars(VarOffsetS);
                    Exit;
                  End;
                End Else
                  Dec(vIdx);
                Idx3 := SP_NewStrVar;
                StrVars[Idx3].Name := Lower(VarName);
                StrVars[Idx3].ProcVar := True;
                StrVars[Idx3].ContentPtr := StrVars[vIdx].ContentPtr;
                Dec(SP_StackPtr);
              End;
          Else
            Error.Code := SP_ERR_PARAMETER_ERROR;
            Exit;
          End;
      End;

      // Finally, having got correct parameters, we set up a procstack entry for this
      // procedure

      If SP_ProcStackPtr < MAXDEPTH Then Begin

        Inc(SP_ProcStackPtr);
        With SP_ProcStack[SP_ProcStackPtr] Do Begin
          ProcIndex := Idx;
          NumVars := NumParams;
          VarPosN := VarOffsetN;
          VarPosS := VarOffsetS;
          VarPosNA := VarOffsetNA;
          VarPosSA := VarOffsetSA;
          StackPtr := SP_StackPtr;
        End;

        // Push the return address

        If CallType = 0 Then Begin
          If Error.Line >= 0 Then
            TempLine := SP_ConvertLineStatement(Error.Line, Error.Statement + 1)
          Else Begin
            TempLine.Line := -2;
            TempLine.Statement := SP_FindStatement(@COMMAND_TOKENS, Error.Statement + 1);
            TempLine.St := Error.Statement + 1;
          End;
        End Else Begin
          TempLine.Line := Error.Line;
          TempLine.Statement := Error.Statement;
          TempLine.St := Error.Position;
        End;
        SP_StackLine(TempLine.Line, TempLine.Statement, TempLine.St, SP_KW_PROC, Error);

        // If this was a CALL, then add the appropriate result var (RESULT or RESULT$)

        If CALLType = SP_NUMVAR Then Begin
          Idx3 := SP_NewNumVar;
          NumVars[Idx3]^.Content.VarType := SP_SIMPLE;
          NumVars[Idx3]^.Name := 'result';
          NumVars[Idx3]^.ProcVar := True;
          NumVars[Idx3]^.Content.Value := 0;
          NumVars[Idx3]^.ContentPtr := @NumVars[Idx3]^.Content;
          Result := Idx3;
        End Else
          If CALLType = SP_STRVAR Then Begin
            Idx3 := SP_NewStrVar;
            StrVars[Idx3]^.Name := 'result';
            StrVars[Idx3]^.Content.Value := '';
            StrVars[Idx3]^.ContentPtr := @StrVars[Idx3]^.Content;
            StrVars[Idx3]^.Content.DLen := 0;
            StrVars[Idx3]^.ProcVar := True;
            Result := Idx3;
          End;
        SP_ProcStack[SP_ProcStackPtr].CALLType := CALLType;

        // Now jump to the statement after the procedure declaration

        TempLine := SP_ConvertLineStatement(SP_ProcsList[Idx].Line, SP_ProcsList[Idx].St + 1);
        NXTLINE := TempLine.Line;
        NXTSTATEMENT := TempLine.Statement;
        NXTST := TempLine.St;
        If CALLType <> 0 Then Begin
          Error.Line := NXTLINE;
          Error.Statement := NXTST;
        End;
        Error.ReturnType := SP_JUMP;
        Inc(INPROC);
        If INPROC >= MAXDEPTH Then
          Error.Code := SP_ERR_OUT_OF_MEMORY;

      End Else

        Error.Code := SP_ERR_OUT_OF_MEMORY;

    End;

  End Else

    Error.Code := SP_ERR_PROC_NOT_FOUND;

End;

Procedure SP_Interpret_END_PROC(Var Info: pSP_iInfo);
Begin

  // Get the last procedure from the stack, and remove the variables it created.

  If SP_ProcStackPtr >= 0 Then Begin

    SP_ResizeNumVars(SP_ProcStack[SP_ProcStackPtr].VarPosN);
    SP_ResizeStrVars(SP_ProcStack[SP_ProcStackPtr].VarPosS);
    SP_TruncateNumArrays(SP_ProcStack[SP_ProcStackPtr].VarPosNA);
    SP_TruncateStrArrays(SP_ProcStack[SP_ProcStackPtr].VarPosSA);
    SP_StackPtr := SP_ProcStack[SP_ProcStackPtr].StackPtr;
    Dec(SP_ProcStackPtr);

    NXTLINE := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Line;
    NXTSTATEMENT := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Statement;
    NXTST := SP_GOSUB_Stack[SP_GOSUB_STACKPTR -1].St;
    If SP_GOSUB_Stack[SP_GOSUB_STACKPTR -1].Source = SP_KW_ERROR Then IGNORE_ON_ERROR := False;
    Info^.Error^.Statement := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].St;

    Dec(SP_GOSUB_STACKPTR);
    Info^.Error^.ReturnType := SP_EXIT;
    Dec(INPROC);

  End Else

    Info^.Error^.Code := SP_ERR_ENDPROC_WITHOUT_PROC_CALL;

End;

Procedure SP_Interpret_EXIT_PROC(Var Info: pSP_iInfo);
Begin

  // Get the last procedure from the stack, and remove the variables it created.

  If SP_ProcStackPtr >= 0 Then Begin

    SP_ResizeNumVars(SP_ProcStack[SP_ProcStackPtr].VarPosN);
    SP_ResizeStrVars(SP_ProcStack[SP_ProcStackPtr].VarPosS);
    SP_TruncateNumArrays(SP_ProcStack[SP_ProcStackPtr].VarPosNA);
    SP_TruncateStrArrays(SP_ProcStack[SP_ProcStackPtr].VarPosSA);
    SP_StackPtr := SP_ProcStack[SP_ProcStackPtr].StackPtr;
    Dec(SP_ProcStackPtr);

    NXTLINE := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Line;
    NXTSTATEMENT := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].Statement;
    Info^.Error^.Statement := SP_GOSUB_Stack[SP_GOSUB_STACKPTR - 1].St;
    Dec(SP_GOSUB_STACKPTR);
    Info^.Error^.ReturnType := SP_EXIT;
    Dec(INPROC);

  End Else
    Info^.Error^.Code := SP_ERR_EXITPROC_WITHOUT_PROC_CALL;

End;

Procedure SP_Interpret_GLOBAL(Var Info: pSP_iInfo);
Var
  Idx: Integer;
  Val: aFloat;
  ValS, Name: aString;
  Ptr: pLongWord;
Begin

  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    Name := SP_StackPtr^.Str;
    Ptr := SP_StackPtr^.Ptr;
    Dec(SP_StackPtr);
    Val := 0;
    If SP_StackPtr^.OpType = SP_VALUE Then Begin
      Val := SP_StackPtr^.Val;
      Dec(SP_StackPtr);
    End;
    Idx := SP_FindGlobalNumVar(Name);
    If Idx = -1 Then Begin
      SP_InsertGlobalNumVar(Idx);
      NumVars[Idx]^.Name := Name;
      NumVars[Idx]^.ProcVar := False;
      NumVars[Idx]^.Content.VarType := SP_SIMPLE;
      NumVars[Idx]^.ContentPtr := @NumVars[Idx]^.Content;
      Ptr^ := Idx +1;
    End;
    SP_UpdateNumVar(Idx +1, Name, Val, Info^.Error^, Ptr);
  End Else Begin
    Name := SP_StackPtr^.Str;
    Ptr := SP_StackPtr^.Ptr;
    Dec(SP_StackPtr);
    ValS := '';
    If SP_StackPtr^.OpType = SP_STRING Then Begin
      ValS := SP_StackPtr^.Str;
      Dec(SP_StackPtr);
    End;
    Idx := SP_FindGlobalStrVar(Name);
    If Idx = -1 Then Begin
      SP_InsertGlobalStrVar(Idx);
      StrVars[Idx]^.Name := Name;
      StrVars[Idx]^.ProcVar := False;
      StrVars[Idx]^.Content.VarType := SP_SIMPLE;
      StrVars[Idx]^.ContentPtr := @StrVars[Idx]^.Content;
      StrVars[Idx]^.Content.SliceFrom := -1;
      StrVars[Idx]^.Content.SliceTo := -1;
      StrVars[Idx]^.Content.DLen := 0;
      Ptr^ := Idx +1;
    End;
    SP_UpdateStrVar(Idx +1, Name, ValS, -1, -1, Info^.Error^, Ptr);
  End;

End;

Procedure SP_Interpret_LOCAL(Var Info: pSP_iInfo);
Var
  Idx: Integer;
  Val: aFloat;
  ValS, Name: aString;
  Ptr: pLongWord;
Begin

  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    Name := SP_StackPtr^.Str;
    Ptr := SP_StackPtr^.Ptr;
    Dec(SP_StackPtr);
    Val := 0;
    If SP_StackPtr^.OpType = SP_VALUE Then Begin
      Val := SP_StackPtr^.Val;
      Dec(SP_StackPtr);
    End;
    Idx := SP_FindNumVar(Name);
    If Idx > -1 Then Begin
      If Idx < SP_ProcStack[SP_ProcStackPtr].VarPosN Then Begin
        Idx := SP_NewNumVar;
        NumVars[Idx]^.Name := Lower(Name);
        NumVars[Idx]^.ProcVar := SP_ProcStackPtr > -1;
        NumVars[Idx]^.Content.VarType := SP_SIMPLE;
        NumVars[Idx]^.ContentPtr := @NumVars[Idx]^.Content;
      End;
    End;
    SP_UpdateNumVar(Idx +1, Name, Val, Info^.Error^, Ptr);
  End Else Begin
    Name := SP_StackPtr^.Str;
    Ptr := SP_StackPtr^.Ptr;
    Dec(SP_StackPtr);
    ValS := '';
    If SP_StackPtr^.OpType = SP_STRING Then Begin
      ValS := SP_StackPtr^.Str;
      Dec(SP_StackPtr);
    End;
    Idx := SP_FindStrVar(Name);
    If Idx > -1 Then Begin
      If Idx < SP_ProcStack[SP_ProcStackPtr].VarPosS Then Begin
        Idx := SP_NewStrVar;
        StrVars[Idx]^.Name := Lower(Name);
        StrVars[Idx]^.ProcVar := SP_ProcStackPtr > -1;
        StrVars[Idx]^.Content.VarType := SP_SIMPLE;
        StrVars[Idx]^.ContentPtr := @StrVars[Idx]^.Content;
      End;
    End;
    SP_UpdateStrVar(Idx +1, Name, ValS, -1, -1, Info^.Error^, Ptr);
  End;

End;

Procedure SP_Interpret_DEF_FN(Var Info: pSP_iInfo);
Var
  FnName, FnExpr, ParamList: aString;
  ParamCount, Count: LongWord;
  Idx: Integer;
Begin

  FnExpr := SP_StackPtr^.Str + SP_TERMINAL_SEQUENCE;
  SP_AddHandlers(FnExpr);
  Dec(SP_StackPtr);
  ParamCount := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  FnName := Lower(SP_StackPtr^.Str);
  Dec(SP_StackPtr);

  ParamList := '';
  Count := ParamCount;
  While Count > 0 Do Begin
    If SP_StackPtr^.OpType = SP_NUMVAR Then
      ParamList := ParamList + aChar(0) + LongWordToString(Length(SP_StackPtr^.Str)) + SP_StackPtr^.Str
    Else
      ParamList := ParamList + aChar(1) + LongWordToString(Length(SP_StackPtr^.Str)) + SP_StackPtr^.Str;
    Dec(SP_StackPtr);
    Dec(Count);
  End;

  Idx := Length(SP_FnList) - 1;
  While Idx > -1 Do Begin
    If SP_FnList[Idx].Name = FnName Then
      Break;
    Dec(Idx);
  End;

  If Idx = -1 Then Begin
    SetLength(SP_FnList, Length(SP_FnList) + 1);
    Idx := Length(SP_FnList) - 1;
  End;

  SP_FnList[Idx].Name := FnName;
  SP_FnList[Idx].Expr := FnExpr;
  SP_FnList[Idx].ParamCount := ParamCount;
  SP_FnList[Idx].ParamList := ParamList;

End;

Procedure SP_Interpret_FN(Var Info: pSP_iInfo);
Var
  NumParams: LongWord;
  FnName, VarList, VarName: aString;
  Idx, Idx2, Idx3, VarOffsetN, VarOffsetS, ValPosition, fnID: Integer;
  nVar: pFnVar; ValTkn: paString;
Begin

  // Get the parameter count and the procedure name

  NumParams := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  FnName := Lower(SP_StackPtr^.Str);
  FnID := Info^.Token^.Cache;
  Dec(SP_StackPtr);

  // Find the procedure.

  If FnID <= 0 Then Begin
    Idx := 0;
    While Idx < Length(SP_FnList) Do Begin
      If SP_FnList[Idx].Name = FnName Then Begin
        Info^.Token^.Cache := Idx +1;
        Break;
      End Else
        Inc(Idx);
    End;
  End Else
    Idx := FnID -1;

  If Idx < Length(SP_FnList) Then Begin

    // Check the parameter count

    If SP_FnList[Idx].ParamCount <> integer(NumParams) Then Begin
      Info^.Error^.Code := SP_ERR_PROC_PARAM_COUNT;
    End Else Begin

      // Now pick up the parameters from the fnlist entry
      // and create vars with values from the stack.

      Idx2 := 1;
      VarList := SP_FnList[Idx].ParamList;
      VarOffsetN := NumNV;
      VarOffsetS := NumSV;
      While Idx2 < Length(VarList) Do Begin
        nVar := @VarList[Idx2];
        Inc(Idx2, SizeOf(TFnVar));
        VarName := Copy(VarList, Idx2, nVar.Len);
        Inc(Idx2, nVar.Len);
        If nVar.ID = 0 Then Begin
          If SP_StackPtr^.OpType = SP_VALUE Then Begin
            Idx3 := SP_NewNumVar;
            NumVars[Idx3]^.Content.VarType := SP_SIMPLE;
            NumVars[Idx3]^.Name := Lower(VarName);
            NumVars[Idx3]^.ProcVar := True;
            NumVars[Idx3]^.Content.Value := SP_StackPtr^.Val;
            NumVars[Idx3]^.ContentPtr := @NumVars[Idx3]^.Content;
            Dec(SP_StackPtr);
          End Else
            Info^.Error^.Code := SP_ERR_PARAMETER_ERROR;
        End Else
          If SP_StackPtr^.OpType = SP_STRING Then Begin
            Idx3 := SP_NewStrVar;
            StrVars[Idx3]^.Name := Lower(VarName);
            StrVars[Idx3]^.Content.Value := SP_StackPtr^.Str;
            StrVars[Idx3]^.Content.DLen := 0;
            StrVars[Idx3]^.ContentPtr := @StrVars[Idx3]^.Content;
            StrVars[Idx3]^.ProcVar := True;
            Dec(SP_StackPtr);
          End Else
            Info^.Error^.Code := SP_ERR_PARAMETER_ERROR;
      End;

      ValPosition := 1;
      ValTkn := @SP_FnList[Idx].Expr;
      Inc(FN_Recursion_Count);
      If FN_Recursion_Count >= MAXDEPTH Then
        Info^.Error^.Code := SP_ERR_OUT_OF_MEMORY
      Else
        SP_InterpretCONTSafe(ValTkn, ValPosition, Info^.Error^);
      Dec(FN_Recursion_Count);

      // Now remove the variables

      SP_ResizeNumVars(VarOffsetN);
      SP_ResizeStrVars(VarOffsetS);

    End;

  End Else

    Info^.Error^.Code := SP_ERR_FN_NOT_FOUND;

End;

Procedure SP_Interpret_BANK_PROTECT(Var Info: pSP_iInfo);
Var
  BankID: Integer;
Begin

  BankID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  If SP_Bank_Protect(BankID, False) < 0 Then
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_BANK_DEPROTECT(Var Info: pSP_iInfo);
Var
  BankID: Integer;
Begin

  BankID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  If SP_Bank_DeProtect(BankID) < 0 Then
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_CALL(Var Info: pSP_iInfo);
Var
  OldError: TSP_ErrorCode;
  pTokens: paString;
  Tkns: aString;
  oldStrPtr: Pointer;
  OldSp: pSP_StackItem;
  TempLine: TSP_Gosub_Item;
  ResultIdx, ResultType: Integer;
  CurLine, OldErrorStatement, OldNxtStatement, OldNxtLine, OldProcStack: Integer;
Label
  NextStatement, BailOut;
Begin

  With Info^ Do Begin

    OldStrPtr := StrPtr;
    CopyMem(@OldError.Line, @Error^.Line, SizeOf(TSP_ErrorCode));
    OldNxtLine := NXTLINE;
    OldNxtStatement := NXTSTATEMENT;
    OldErrorStatement := Error^.Statement;

    OldProcStack := SP_ProcStackPtr;
    ResultIdx := SP_SetUpPROC(1, Token^.Cache, Error^);
    If Error^.Code <> SP_ERR_OK Then Exit;

    CurLine := NXTLINE;
    Error^.ReturnType := OldError.ReturnType;
    Tkns := SP_Program[CurLine];
    Error^.Position := NXTSTATEMENT; //SP_FindStatement(@Tkns, 1);

    TempLine := SP_ConvertLineStatement(NXTLINE, NXTST + 1);
    NXTLINE := TempLine.Line;
    NXTSTATEMENT := TempLine.Statement;
    ResultType := SP_ProcStack[SP_ProcStackPtr].CALLType;
    OldSp := SP_StackPtr;

  NextStatement:

    pTokens := @Tkns;
    SP_Interpret(pTokens, Error^.Position, Error^);

    // If the code caused an error, then bail now and remove the return address from the stack

    If SP_ProcStackPtr = OldProcStack Then Begin
      If Error^.Code = SP_ERR_UNBALANCED_STACK Then
        If NativeUInt(SP_StackPtr) = NativeUInt(SP_StackStart) + SizeOf(SP_StackItem) Then
          Error^.Code := SP_ERR_OK;
      Goto BailOut;
    End;

    If (Error^.Code <> SP_ERR_OK) or (NXTLINE >= SP_Program_Count) Then Begin

      Dec(SP_GOSUB_STACKPTR);
      If Error^.Code = SP_ERR_OK Then
        Error^.ReturnType := SP_JUMP;
      Exit;

    End Else Begin

      // Otherwise, follow the jump if necessary
      // Check if the procedure stack has shrunk back to what it was before we started

      If NXTLINE <> -1 Then Begin

        If NXTLINE = -2 Then Begin CurLine := -1;
          Tkns := COMMAND_TOKENS;
          If NXTSTATEMENT = -1 Then
            Goto BailOut;
          Error^.Position := NXTSTATEMENT;
        End Else Begin
          CurLine := NXTLINE;
          Tkns := SP_Program[CurLine];
          If NXTSTATEMENT <> -1 Then
            Error^.Position := NXTSTATEMENT
          Else Begin
            Error^.Statement := 1;
            Error^.Position := SP_FindStatement(@Tkns, 1);
          End;
        End;

        NXTSTATEMENT := -1;
        Inc(NXTLINE);
        If NXTLINE <> 0 Then Begin
          Error^.Line := CurLine;
          Goto NextStatement;
        End;

      End;

    End;

  BailOut :

    StrPtr := OldStrPtr;
    SP_StackPtr := OldSP;
    If ResultType = SP_NUMVAR Then Begin
      Inc(SP_StackPtr);
      SP_StackPtr^.OpType := SP_VALUE;
      SP_StackPtr^.Val := NumVars[ResultIdx]^.ContentPtr^.Value;
    End Else
      If ResultType = SP_STRVAR Then Begin
        Inc(SP_StackPtr);
        SP_StackPtr^.OpType := SP_STRING;
        SP_StackPtr^.Str := StrVars[ResultIdx]^.ContentPtr^.Value;
      End;

    NXTLINE := OldNxtLine;
    NXTSTATEMENT := OldNxtStatement;
    Error^.Statement := OldErrorStatement;
    CopyMem(@Error^.Line, @OldError.Line, SizeOf(TSP_ErrorCode));

  End;

End;

Procedure SP_Interpret_CAT(Var Info: pSP_iInfo);
Var
  DirString, PathStr, ResultStr, PadStr, Size, Size2, Mask, tStr: aString;
  Idx, FileCount, DirIns, DirCount, MaxSize, MaxLen, SizeCount, Cnt, rLen, dLen: Integer;
  WantEXP, Recurse: Boolean;
  Files, FileSizes: TAnsiStringList;
Begin

  Cnt := 0;

  // The recursion flag (ALL) will be top of the stack.
  // EXP flag will be next on the stack, followed by the folder/filemask as a string
  // If EXP is set, then file dates and sizes will be retrieved.

  Recurse := SP_StackPtr^.Val > 0;
  Dec(SP_StackPtr);

  WantEXP := SP_StackPtr^.Val > 0;
  Dec(SP_StackPtr);

  DirString := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  Files := TAnsiStringList.Create;
  FileSizes := TAnsiStringList.Create;

  Mask := aString(ExtractFileName(String(DirString)));
  If (Mask = DirString) And ((Pos('*',DirString)+Pos('?',DirString)) = 0) Then Mask := '*';

  If Recurse Then Begin

    PathStr := SP_ConvertHostFilename(aString(GetCurrentDir), Info^.Error^);
    ResultStr := SP_GetFileListRecursive(DirString, WantEXP, Info^.Error^);
    SP_SetCurrentDir(PathStr, Info^.Error^);

  End Else Begin

    SP_GetFileList(DirString, Files, FileSizes, Info^.Error^, False);

    If (Info^.Error^.Code = SP_ERR_OK) And (Files.Count > 0) Then Begin

      ResultStr := 'File list for ' + DirString + Mask + #13#13;

      FileCount := 0;
      DirCount := 0;
      DirString := '';
      Files.Sort;
      DirIns := Length(ResultStr);

      MaxSize := 0;
      SizeCount := 0;
      For Idx := 0 To FileSizes.Count -1 Do Begin
        Inc(SizeCount, NativeUInt(FileSizes.Objects[Idx]));
        If Length(FileSizes[Idx]) > MaxSize Then
          MaxSize := Length(FileSizes[Idx]);
      End;

      MaxLen := 0;
      MaxSize := 0;
      SizeCount := 0;
      For Idx := 0 To FileSizes.Count -1 Do Begin
        Inc(SizeCount, NativeUInt(FileSizes.Objects[Idx]));
        If Length(FileSizes[Idx]) > MaxSize Then
          MaxSize := Length(FileSizes[Idx]);
        If Length(Files[Idx]) > MaxLen Then MaxLen := Length(Files[Idx]);
      End;
      Inc(MaxLen, 2);

      If WantEXP Then Begin
        PadStr := aString(StringOfChar(' ', MaxSize +1));
        For Idx := 0 To Files.Count -1 Do Begin
          If NativeUInt(Files.Objects[Idx]) = 1 Then Begin
            DirString := DirString + PadStr + aString(Files[Idx])+'/'+#13;
            Inc(DirCount);
          End Else Begin
            ResultStr := ResultStr + aString(SP_StringOfChar(' ', MaxSize - Length(FileSizes[Idx])) + FileSizes[Idx] + ' ' + Files[Idx])+#13;
            Inc(FileCount);
          End;
        End;
      End Else Begin
        PadStr := '';
        rLen := 0; dLen := 0;
        For Idx := 0 To Files.Count -1 Do Begin
          If NativeUInt(Files.Objects[Idx]) = 1 Then Begin
            tStr := aString(Files[Idx]) + '/';
            Inc(DirCount);
          End Else Begin
            tStr := aString(Files[Idx]);
            Inc(FileCount);
          End;
          While Length(tStr) < MaxLen Do
            tStr := tStr + ' ';
          If NativeUInt(Files.Objects[Idx]) = 1 Then Begin
            If dLen + Length(tStr) < (SCREENWIDTH Div FONTWIDTH) Then Begin
              DirString := DirString + tStr;
            End Else Begin
              DirString := DirString + #13 + tStr;
              dLen := 0;
            End;
            Inc(dLen, Length(tStr));
          End Else Begin
            If rLen + Length(tStr) < (SCREENWIDTH Div FONTWIDTH) Then Begin
              ResultStr := ResultStr + tStr;
            End Else Begin
              ResultStr := ResultStr + #13 + tStr;
              rLen := 0;
            End;
            Inc(rLen, Length(tStr));
          End;
        End;
        ResultStr := ResultStr + #13;
        If DirString <> '' Then
          DirString := DirString + #13 + #13;

      End;

      ResultStr := Copy(ResultStr, 1, DirIns) + DirString + Copy(ResultStr, DirIns +1, Length(ResultStr)) + #13;

      If WantEXP Then Begin

        If SizeCount > 0 Then Begin
          Size := IntToString(SizeCount);
          Idx := Length(Size);
          While Idx > 0 Do Begin
            Size2 := Size[Idx] + Size2;
            Inc(Cnt);
            If (Cnt = 3) And (Idx > 1) Then Begin
              Size2 := ',' + Size2;
              Cnt := 0;
            End;
            Dec(Idx);
          End;
          If SizeCount = 1 Then
            ResultStr := ResultStr + PadStr + Size2 + ' byte.' + #13
          Else
            ResultStr := ResultStr + PadStr + Size2 + ' bytes.' + #13;
        End;

        If DirCount <> 0 Then
          If DirCount > 1 Then
            ResultStr := ResultStr + PadStr + IntToString(DirCount) + ' directories.' + #13
          Else
            ResultStr := ResultStr + PadStr + IntToString(DirCount) + ' directory.' + #13;

        If FileCount <> 0 Then
          If FileCount > 1 Then
            ResultStr := ResultStr + PadStr + IntToString(FileCount) + ' files.' + #13#13
          Else
            ResultStr := ResultStr + PadStr + IntToString(FileCount) + ' file.' + #13#13;

        If (FileCount = 0) And (DirCount = 0) Then
          ResultStr := ResultStr + PadStr + 'No files or directories found.' + #13#13;

      End Else Begin

        If SizeCount > 0 Then Begin
          Size := IntToString(SizeCount);
          Idx := Length(Size);
          While Idx > 0 Do Begin
            Size2 := Size[Idx] + Size2;
            Inc(Cnt);
            If (Cnt = 3) And (Idx > 1) Then Begin
              Size2 := ',' + Size2;
              Cnt := 0;
            End;
            Dec(Idx);
          End;
          If SizeCount = 1 Then
            ResultStr := ResultStr + Size2 + ' byte in '
          Else
            ResultStr := ResultStr + Size2 + ' bytes in ';
          If FileCount > 1 Then
            ResultStr := ResultStr + IntToString(FileCount) + ' files.'
          Else
            ResultStr := ResultStr + IntToString(FileCount) + ' file.';
        End;

        ResultStr := ResultStr + #13#13;

      End;

    End Else

      ResultStr := ResultStr + 'No files found.'+#13#13;

  End;

  If Info^.Error^.Code = SP_ERR_OK Then Begin

    Inc(SP_StackPtr);
    SP_StackPtr^.OpType := SP_STRING;
    SP_StackPtr^.Str := PadStr + ResultStr + #13;
    SP_Interpret_PRINT(Info);

    Files.Free;
    FileSizes.Free;

  End;

End;

Procedure SP_Interpret_ERASE(Var Info: pSP_iInfo);
Var
  Idx, DelCount: Integer;
  DirString, ErrorString: aString;
  Files, FileSizes: TAnsiStringList;
  RemoveDir, Recurse: Boolean;
Begin

  // Erases files only, not for dirs

  With Info^ Do Begin

    RemoveDir := SP_StackPtr^.Val <> 0;
    Dec(SP_StackPtr);

    DirString := SP_StackPtr^.Str;
    Dec(SP_StackPtr);

    Recurse := SP_StackPtr^.Val <> 0;
    Dec(SP_StackPtr);

    ErrorString := DirString;
    If DirString = '' Then Begin
      Error^.Code := SP_ERR_FILE_NOT_FOUND;
      Exit;
    End;

    Files := TAnsiStringList.Create;
    FileSizes := TAnsiStringList.Create;

    If Not RemoveDir Then Begin

      SP_GetFileList(DirString, Files, FileSizes, Error^, False);

      If Error^.Code = SP_ERR_OK Then Begin

        If Files.Count > 0 Then Begin

          DelCount := 0;
          For Idx := 0 To Files.Count -1 Do Begin

            If NativeUInt(Files.Objects[Idx]) = 0 Then Begin

              Inc(DelCount);
              SP_DeleteFile(DirString + aString(Files[Idx]), Error^);
              If Error^.Code <> SP_ERR_OK Then Begin
                ErrStr := Files[Idx];
                Files.Free;
                FileSizes.Free;
                Exit;
              End;

            End;

          End;

          If DelCount = 0 Then

            Error^.Code := SP_ERR_FILE_MISSING;

        End Else

          Error^.Code := SP_ERR_FILE_MISSING;

      End;

    End Else Begin

      // User specified ERASE DIR "directory" [ALL]
      // Directory spec *must* be a directory and exist. If ALL is not specified
      // then it must be empty, otherwise all contents will be recursively deleted.
      // If the user specifies the root directory, then all contents will be erased, but the directory will
      // not be removed.

      If SP_DirectoryExists(DirString) Then Begin

        // If the directory contains other dirs or files, then check - recursive delete?

        SP_GetFileList(DirString, Files, FileSizes, Error^, False);

        If Files.Count > 0 Then Begin

          If Not Recurse Then Begin

            Error^.Code := SP_ERR_DIR_NOT_EMPTY;

          End Else Begin

            // Recursively delete everything in this dir.

            SP_DeleteDirContents(DirString, Error^);

          End;

        End;

        If Error^.Code = SP_ERR_OK Then
          SP_RmDir(DirString, Error^);

      End Else

        Error^.Code := SP_ERR_DIRECTORYNOTFOUND;

    End;

    Files.Free;
    FileSizes.Free;

  End;

  If Info^.Error^.Code <> SP_ERR_OK Then
    ErrStr := ErrorString;

End;

Procedure SP_Interpret_SPRITE_NEW(Var Info: pSP_iInfo);
Var
  SprX, SprY: aFloat;
  SprIndex, Over, Wrap, Copy: Integer;
  Collide: Boolean;
Begin

  // Get Parameters

  SprX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SprY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Collide := SP_StackPtr^.Val <> 0;
  Dec(SP_StackPtr);

  Over := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Wrap := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Copy := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  // Create new sprite

  SprIndex := SP_New_Sprite(SprX, SprY, Collide, Over, Wrap, Copy, Info^.Error^);

  Inc(SP_StackPtr);
  SP_StackPtr^.Val := SprIndex;

End;

Procedure SP_Interpret_SPRITE_ADDFRAME(Var Info: pSP_iInfo);
Var
  SprIndex, Delay, BankID: Integer;
  GraphicStr: aString;
Begin

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    BankID := Round(SP_StackPtr^.Val);
    GraphicStr := '';
  End Else Begin
    BankID := -1;
    GraphicStr := SP_StackPtr^.Str;
  End;
  Dec(SP_StackPtr);

  Delay := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If GraphicStr <> '' Then
    SP_Add_Frame(SprIndex, GraphicStr, Delay, Info^.Error^)
  Else
    SP_Add_Frame_Graphic(SprIndex, BankID, Delay, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_SHOW(Var Info: pSP_iInfo);
Var
  SprIndex: Integer;
Begin

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Show_Sprite(SprIndex, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_HIDE(Var Info: pSP_iInfo);
Var
  SprIndex: Integer;
Begin

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Hide_Sprite(SprIndex, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_MOVE(Var Info: pSP_iInfo);
Var
  Idx, SprIndex: Integer;
  nX, nY: aFloat;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  // Move the sprite by the offset dx,dy

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  nX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  nY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Idx := SP_FindSpriteID(SprIndex, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    Sprite^.X := Sprite^.X + nX;
    Sprite^.Y := Sprite^.Y + nY;
  End;

End;

Procedure SP_Interpret_SPRITE_MOVED(Var Info: pSP_iInfo);
Var
  Idx, SprIndex: Integer;
  nX, nY: aFloat;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  // Move the sprite directly to x,y

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  nX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  nY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Idx := SP_FindSpriteID(SprIndex, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    Sprite^.X := nX;
    Sprite^.Y := nY;
  End;

End;

Procedure SP_Interpret_SPRITE_MOVE_T(Var Info: pSP_iInfo);
Var
  Idx, SprIndex, T: Integer;
  nX, nY: aFloat;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  // Move the sprite by dx,dy over T frames

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  nX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  nY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  T := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindSpriteID(SprIndex, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    Sprite^.DstX := Sprite^.X + nX;
    Sprite^.DstY := Sprite^.Y + nY;
    Sprite^.DstTime := T + integer(FRAMES);
    Sprite^.MoveDuration := T;
    Sprite^.MoveX := nX/T;
    Sprite^.MoveY := nY/T;
    Sprite^.MoveStart := FRAMES;
  End;

End;

Procedure SP_Interpret_SPRITE_MOVED_T(Var Info: pSP_iInfo);
Var
  Idx, SprIndex, T: Integer;
  nX, nY: aFloat;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  // Move the sprite to x,y over T frames

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  nX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  nY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  T := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindSpriteID(SprIndex, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    Sprite^.DstX := nX;
    Sprite^.DstY := nY;
    Sprite^.DstTime := T + integer(FRAMES);
    Sprite^.MoveDuration := T;
    Sprite^.MoveX := (nX - Sprite^.X)/T;
    Sprite^.MoveY := (nY - Sprite^.Y)/T;
    Sprite^.MoveStart := FRAMES;
  End;

End;

Procedure SP_Interpret_SPRITE_MOVE_S(Var Info: pSP_iInfo);
Var
  Idx, SprIndex: Integer;
  nX, nY, Dist, DistX, DistY, T: aFloat;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  // Move the sprite by dx,dy stepping S pixels every frame

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  nX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  nY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  T := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Idx := SP_FindSpriteID(SprIndex, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    Sprite^.DstX := Sprite^.X + nX;
    Sprite^.DstY := Sprite^.Y + nY;
    DistX := Abs(Sprite^.DstX - Sprite^.X);
    DistY := Abs(Sprite^.DstY - Sprite^.Y);
    Dist := Sqrt(DistX * DistX + DistY * DistY);
    If Dist < T Then
      Sprite^.DstTime := FRAMES +1
    Else
      Sprite^.DstTime := Ceil((Dist/T) + FRAMES);
    Sprite^.MoveDuration := Ceil(Dist/T);
    Sprite^.MoveX := nX/Sprite^.MoveDuration;
    Sprite^.MoveY := nY/Sprite^.MoveDuration;
    Sprite^.MoveStart := FRAMES;
  End;

End;

Procedure SP_Interpret_SPRITE_MOVED_S(Var Info: pSP_iInfo);
Var
  Idx, SprIndex: Integer;
  nX, nY, Dist, DistX, DistY, T: aFloat;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  // Move the sprite to x,y stepping S pixels per frame

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  nX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  nY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  T := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Idx := SP_FindSpriteID(SprIndex, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    Sprite^.DstX := nX;
    Sprite^.DstY := nY;
    DistX := Abs(nX - Sprite^.X);
    DistY := Abs(nY - Sprite^.Y);
    Dist := Sqrt(DistX * DistX + DistY * DistY);
    If Dist < T Then
      Sprite^.DstTime := FRAMES +1
    Else
      Sprite^.DstTime := Ceil((Dist/T) + FRAMES);
    Sprite^.MoveDuration := Ceil(Dist/T);
    Sprite^.MoveX := (nX - Sprite^.X)/Sprite^.MoveDuration;
    Sprite^.MoveY := (nY - Sprite^.Y)/Sprite^.MoveDuration;
    Sprite^.MoveStart := FRAMES;
  End;


End;

Procedure SP_Interpret_SPRITE_MOVE_WIN(Var Info: pSP_iInfo);
Var
  Idx, SprIndex, WindowID: Integer;
  Sprite: pSP_Sprite_Info;
Begin

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  WindowID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindSpriteID(SprIndex, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Sprite := @SP_BankList[Idx]^.Info[0];
    If SP_FindBankID(WindowID) > -1 Then
      SP_SpriteToWindow(Sprite, WindowID)
    Else
      Info^.Error^.Code := SP_ERR_WINDOW_NOT_FOUND;
  End;

End;

Procedure SP_Interpret_SPRITE_STOP(Var Info: pSP_iInfo);
Var
  Idx, SprIndex: Integer;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindSpriteID(SprIndex, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    Sprite^.DstX := Sprite^.X;
    Sprite^.DstY := Sprite^.Y;
    Sprite^.DstTime := FRAMES;
    Sprite^.AngleTime := FRAMES;
    Sprite^.DstAngle := 0;
    Sprite^.ScaleTime := FRAMES;
  End;

End;

Procedure SP_Interpret_SPRITE_ROTATE(Var Info: pSP_iInfo);
Var
  SprIndex, Idx: Integer;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
  Delta: aFloat;
Begin

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Delta := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_AngleToRad(Delta);

  Idx := SP_FindSpriteID(SprIndex, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    Sprite^.Angle := Sprite^.Angle + Delta;
  End;

End;

Procedure SP_Interpret_SPRITE_ROTATE_TO(Var Info: pSP_iInfo);
Var
  SprIndex, Idx: Integer;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
  Angle: aFloat;
Begin

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Angle := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_AngleToRad(Angle);

  Idx := SP_FindSpriteID(SprIndex, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    Sprite^.Angle := Angle;
  End;

End;

Procedure SP_Interpret_SPRITE_ROTATE_T(Var Info: pSP_iInfo);
Var
  SprIndex, Idx, Step: Integer;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
  Angle: aFloat;
Begin

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Angle := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_AngleToRad(Angle);

  Step := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindSpriteID(SprIndex, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    Sprite^.DstAngle := Sprite^.Angle + Angle;
    If Angle >= 0 Then
      Sprite^.AngleDir := 1
    Else
      Sprite^.AngleDir := -1;
    Sprite^.AngleTime := Step + integer(FRAMES);
  End;

End;

Procedure SP_Interpret_SPRITE_ROTATE_TO_T(Var Info: pSP_iInfo);
Var
  SprIndex, Idx, Dir, Step: Integer;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
  Angle: aFloat;
Begin

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Angle := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_AngleToRad(Angle);

  Step := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Dir := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindSpriteID(SprIndex, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    Sprite^.DstAngle := Angle;
    Sprite^.AngleDir := Dir;
    Sprite^.AngleTime := Step + integer(FRAMES);
  End;

End;

Procedure SP_Interpret_SPRITE_SCALE(Var Info: pSP_iInfo);
Var
  SprIndex, Idx: Integer;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
  Scale: aFloat;
Begin

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Scale := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Idx := SP_FindSpriteID(SprIndex, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    If Scale > 0 Then
      Sprite^.Scale := Scale
    Else
      Info^.Error^.Code := SP_ERR_INVALID_SCALE;
  End;

End;

Procedure SP_Interpret_SPRITE_SCALE_T(Var Info: pSP_iInfo);
Var
  SprIndex, Idx, Step: Integer;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
  Scale: aFloat;
Begin

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Scale := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Step := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindSpriteID(SprIndex, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    If Scale > 0 Then Begin
      Sprite^.DstScale := Scale;
      Sprite^.ScaleTime := Step + integer(FRAMES);
    End Else
      Info^.Error^.Code := SP_ERR_INVALID_SCALE;
  End;

End;

Procedure SP_Interpret_SPRITE_ERASE(Var Info: pSP_iInfo);
Var
  SprIndex: Integer;
Begin

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_BlockSprites;
  SP_Delete_Sprite(SprIndex, Info^.Error^);
  SP_UnBlockSprites;

End;

Procedure SP_Interpret_SPRITE_CLEAR(Var Info: pSP_iInfo);
Var
  SprIndex: Integer;
Begin

  SprIndex := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_BlockSprites;
  SP_Clear_Sprite(SprIndex, Info^.Error^);
  SP_UnBlockSprites;

End;

Procedure SP_Interpret_SPRITE_CLONE(Var Info: pSP_iInfo);
Var
  Id: Integer;
  X, Y: aFloat;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  X := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Y := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_AddClone(Id, X, Y, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_CLONE_MOVE(Var Info: pSP_iInfo);
Var
  Id, Index: Integer;
  X, Y: aFloat;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Index := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  X := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Y := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_MoveClone(Id, Index, X, Y, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_CLONE_ERASE(Var Info: pSP_iInfo);
Var
  Id, Index: Integer;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Index := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_DeleteClone(Id, Index, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_OVER(Var Info: pSP_iInfo);
Var
  Id, Over: Integer;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Over := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Sprite_SetOver(Id, Over, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_FRONT(Var Info: pSP_iInfo);
Var
  Id: Integer;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Sprite_SetOrder(Id, True, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_FRONT_ADD(Var Info: pSP_iInfo);
Var
  Id, Add: Integer;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Add := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Sprite_SetOrderMove(Id, Add, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_BACK(Var Info: pSP_iInfo);
Var
  Id: Integer;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Sprite_SetOrder(Id, False, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_BACK_DEC(Var Info: pSP_iInfo);
Var
  Id, Dc: Integer;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Dc := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Sprite_SetOrderMove(Id, -Dc, Info^.Error^);

End;

Procedure SP_Interpret_GFX_NEW_SIZE(Var Info: pSP_iInfo);
Var
  W, H: Integer;
  T: Word;
Begin

  W := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  H := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  T := Round(SP_StackPtr^.Val) And $FFFF;

  SP_StackPtr^.Val := SP_New_GraphicA(W, H, T, Info^.Error^);

End;

Procedure SP_Interpret_GFX_NEW_LOAD(Var Info: pSP_iInfo);
Var
  Filename: aString;
  T: Word;
Begin

  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  T := Round(SP_StackPtr^.Val) And $FFFF;

  ERRStr := Filename;
  If SP_FileExists(Filename) Then
    SP_StackPtr^.Val := SP_New_GraphicC(Filename, T, Info^.Error^)
  Else Begin
    SP_StackPtr^.Val := -1;
    Info^.Error^.Code := SP_ERR_FILE_MISSING;
  End;
  SP_StackPtr^.OpType := SP_VALUE;

End;

Procedure SP_Interpret_GFX_NEW_GFXS(Var Info: pSP_iInfo);
Var
  GfxStr: aString;
Begin

  GfxStr := SP_StackPtr^.Str;
  SP_StackPtr^.OpType := SP_VALUE;
  SP_StackPtr^.Val := SP_New_GraphicB(GfxStr, Info^.Error^);

End;

Procedure SP_Interpret_GFX_LOAD(Var Info: pSP_iInfo);
Var
  Id: Integer;
  Filename: aString;
  T: Word;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  T := Round(SP_StackPtr^.Val) And $FFFF;
  Dec(SP_StackPtr);

  SP_Load_Graphic(Id, Filename, T, Info^.Error^);

End;

Procedure SP_Interpret_GFX_GRAB(Var Info: pSP_iInfo);
Var
  dX, dY: aFloat;
  Idx, Id, X, Y, W, H, T: Integer;
  Gfx: pSP_Graphic_Info;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  W := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  H := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  T := Round(SP_StackPtr^.Val);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @SP_BankList[Idx]^.Info[0];
      SP_ConvertWToOrigin_d(dX, dY, @Gfx^.WindowInfo);
      X := Round(dX);
      Y := Round(dY);
      SP_GetRegion(Gfx^.Data, Gfx^.Width, Gfx^.Height, SP_StackPtr^.Str, X, Y, W, H, T, Info^.Error^);
      If Info^.Error^.Code = SP_ERR_OK Then
        SP_StackPtr^.OpType := SP_STRING;

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_GFX_PUT(Var Info: pSP_iInfo);
Var
  GfxStr: aString;
  dX, dY: aFloat;
  Idx, Id, X, Y, cX1, cY1, cX2, cY2, BankID, tW, tH: Integer;
  Gfx, Graphic: pSP_Graphic_Info;
  gBank: pSP_Bank;
  Valid: Boolean;
Begin

  Graphic := nil;

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    GfxStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then
        Graphic := @gBank^.Info[0]
      Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else Begin
    GfxStr := SP_StackPtr^.Str;
    Valid := False;
    If GfxStr = '' Then
      SP_DefaultFill(GfxStr, T_INK);
    If Length(GfxStr) > 10 Then Begin
      tW := pLongWord(@GfxStr[1])^;
      tH := pLongWord(@GfxStr[5])^;
      If Length(GfxStr) - 10 = tW * tH Then Valid := True;
    End;
    If Not Valid Then Begin
      GfxStr := SP_StringToTexture(GfxStr);
      If GfxStr = '' Then
        SP_DefaultFill(GfxStr, T_INK);
    End;
  End;
  Dec(SP_StackPtr);

  If Info^.Error^.Code = SP_ERR_OK Then Begin

    Idx := SP_FindBankID(Id);
    If Idx > -1 Then Begin

      If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

        Gfx := @SP_BankList[Idx]^.Info[0];
        SP_ConvertWToOrigin_d(dX, dY, @Gfx^.WindowInfo);
        X := Round(dX);
        Y := Round(dY);
        cX1 := Gfx^.clipx1; cY1 := Gfx^.clipy1; cX2 := Gfx^.clipx2; cY2 := Gfx^.clipy2;

        If GfxStr <> '' Then
          SP_PutRegion(Gfx^.Data, X, Y, Gfx^.Width, Gfx^.Height, @GfxStr[1], Length(GfxStr), 0, 1, cX1, cY1, cX2, cY2, Info^.Error^)
        Else
          SP_PutRegion(Gfx^.Data, X, Y, Gfx^.Width, Gfx^.Height, pByte(Graphic), -1, 0, 1, cX1, cY1, cX2, cY2, Info^.Error^);

      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;

    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

  End;

End;

Procedure SP_Interpret_GFX_PUT_EX(Var Info: pSP_iInfo);
Var
  GfxStr: aString;
  Idx, Id, X, Y, cX1, cY1, cX2, cY2, BankID, tW, tH: Integer;
  Rot, Scale: aFloat;
  Gfx, Graphic: pSP_Graphic_Info;
  gBank: pSP_Bank;
  Valid: Boolean;
Begin

  Graphic := nil;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    GfxStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then
        Graphic := @gBank^.Info[0]
      Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else Begin
    GfxStr := SP_StackPtr^.Str;
    Valid := False;
    If GfxStr = '' Then
      SP_DefaultFill(GfxStr, T_INK);
    If Length(GfxStr) > 10 Then Begin
      tW := pLongWord(@GfxStr[1])^;
      tH := pLongWord(@GfxStr[5])^;
      If Length(GfxStr) - 10 = tW * tH Then Valid := True;
    End;
    If Not Valid Then Begin
      GfxStr := SP_StringToTexture(GfxStr);
      If GfxStr = '' Then
        SP_DefaultFill(GfxStr, T_INK);
    End;
  End;
  Dec(SP_StackPtr);

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  X := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Y := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Rot := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Scale := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If Info^.Error^.Code = SP_ERR_OK Then Begin

    Idx := SP_FindBankID(Id);
    If Idx > -1 Then Begin

      If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

        Gfx := @SP_BankList[Idx]^.Info[0];
        cX1 := Gfx^.clipx1; cY1 := Gfx^.clipy1; cX2 := Gfx^.clipx2; cY2 := Gfx^.clipy2;
        If GfxStr <> '' Then
          SP_PutRegion(Gfx^.Data, X, Y, Gfx^.Width, Gfx^.Height, @GfxStr[1], Length(GfxStr), Rot, Scale, cX1, cY1, cX2, cY2, Info^.Error^)
        Else
          SP_PutRegion(Gfx^.Data, X, Y, Gfx^.Width, Gfx^.Height, pByte(Graphic), -1, Rot, Scale, cX1, cY1, cX2, cY2, Info^.Error^);

      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;

    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

  End;

End;

Procedure SP_Interpret_GFX_ROTATE(Var Info: pSP_iInfo);
Var
  Gfx: pSP_Graphic_Info;
  Id, Idx: Integer;
  NewGfx: aString;
  Rot: aFloat;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Rot := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_AngleToRad(Rot);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @SP_BankList[Idx]^.Info[0];
      SP_RotAndScaleGfx(Gfx.Data, NewGfx, Rot, 1, Gfx^.Width, Gfx^.Height, Gfx^.Transparent, Info^.Error^);

      SetLength(SP_BankList[Idx]^.Memory, Gfx^.Width * Gfx^.Height);
      Gfx^.Data := @SP_BankList[Idx]^.Memory[0];
      CopyMem(Gfx^.Data, @NewGfx[1], Gfx^.Width * Gfx^.Height);
      Gfx^.WindowInfo.Width := Gfx^.Width;
      Gfx^.WindowInfo.Height := Gfx^.Height;
      Gfx^.winorigin := False;

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_GFX_ORIGIN(Var Info: pSP_iInfo);
Var
  GfxID: Integer;
  x1, y1, x2, y2: aFloat;
Begin

  GfxID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  x1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  x2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_SetGraphicOrigin(GfxID, x1, y1, x2, y2, Info^.Error^);

End;

Procedure SP_Interpret_GFX_SCALE(Var Info: pSP_iInfo);
Var
  Gfx: pSP_Graphic_Info;
  Id, Idx: Integer;
  NewGfx: aString;
  Scale: aFloat;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Scale := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @SP_BankList[Idx]^.Info[0];
      SP_RotAndScaleGfx(Gfx.Data, NewGfx, 0, Scale, Gfx^.Width, Gfx^.Height, Gfx^.Transparent, Info^.Error^);
      SetLength(SP_BankList[Idx]^.Memory, Gfx^.Width * Gfx^.Height);
      Gfx^.Data := @SP_BankList[Idx]^.Memory[0];
      CopyMem(Gfx^.Data, @NewGfx[1], Gfx^.Width * Gfx^.Height);

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_GFX_SCALE_XY(Var Info: pSP_iInfo);
Var
  Gfx: pSP_Graphic_Info;
  Id, Idx: Integer;
  NewGfx: aString;
  ScaleX, ScaleY: aFloat;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  ScaleX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  ScaleY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @SP_BankList[Idx]^.Info[0];
      SP_RotAndScaleGfxXY(Gfx.Data, NewGfx, 0, ScaleX, ScaleY, Gfx^.Width, Gfx^.Height, Gfx^.Transparent, Info^.Error^);
      SetLength(SP_BankList[Idx]^.Memory, Gfx^.Width * Gfx^.Height);
      Gfx^.Data := @SP_BankList[Idx]^.Memory[0];
      CopyMem(Gfx^.Data, @NewGfx[1], Gfx^.Width * Gfx^.Height);

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_GFX_SCALE_TO(Var Info: pSP_iInfo);
Var
  Gfx: pSP_Graphic_Info;
  Id, Idx: Integer;
  NewGfx: aString;
  ScaleX, ScaleY: aFloat;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  ScaleX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  ScaleY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @SP_BankList[Idx]^.Info[0];
      SP_RotAndScaleGfxXY(Gfx.Data, NewGfx, 0, ScaleX/Gfx^.Width, ScaleY/Gfx^.Height, Gfx^.Width, Gfx^.Height, Gfx^.Transparent, Info^.Error^);
      SetLength(SP_BankList[Idx]^.Memory, Gfx^.Width * Gfx^.Height);
      Gfx^.Data := @SP_BankList[Idx]^.Memory[0];
      CopyMem(Gfx^.Data, @NewGfx[1], Gfx^.Width * Gfx^.Height);

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_GFX_FLIP(Var Info: pSP_iInfo);
Var
  Gfx: pSP_Graphic_Info;
  Id, Idx: Integer;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @SP_BankList[Idx]^.Info[0];
      SP_FlipGfx(Gfx^.Data, Gfx^.Width, Gfx^.Height);

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_GFX_FLIP_STR(Var Info: pSP_iInfo);
Var
  Str: aString;
  Src: pByte;
  W, H: Integer;
  Valid: Boolean;
Begin

  W := 0; H := 0;
  Str := SP_StackPtr^.Str;
  Src := StrPosPtr(@Str, 11);

  Valid := False;
  If Str = '' Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_GRAB_STRING;
    Exit;
  End;
  If Length(Str) > 10 Then Begin
    W := pLongWord(StrPosPtr(@Str, 1))^;
    H := pLongWord(StrPosPtr(@Str, 5))^;
    If Length(Str) - 10 = W * H Then Valid := True;
  End;
  If Not Valid Then Begin
    Str := SP_StringToTexture(Str);
    If Str = '' Then Begin
      Info^.Error^.Code := SP_ERR_INVALID_GRAB_STRING;
      Exit;
    End;
    W := pLongWord(StrPosPtr(@Str, 1))^;
    H := pLongWord(StrPosPtr(@Str, 5))^;
  End;

  SP_FlipGfx(Src, W, H);

  SP_StackPtr^.Str := Str;

End;

Procedure SP_Interpret_GFX_MIRROR(Var Info: pSP_iInfo);
Var
  Gfx: pSP_Graphic_Info;
  Id, Idx: Integer;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @SP_BankList[Idx]^.Info[0];
      SP_MirrorGfx(Gfx.Data, Gfx^.Width, Gfx^.Height);

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_GFX_MIRROR_STR(Var Info: pSP_iInfo);
Var
  Str: aString;
  Src: pByte;
  W, H: Integer;
  Valid: Boolean;
Begin

  W := 0; H := 0;
  Str := SP_StackPtr^.Str;
  Src := StrPosPtr(@Str, 11);

  Valid := False;
  If Str = '' Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_GRAB_STRING;
    Exit;
  End;
  If Length(Str) > 10 Then Begin
    W := pLongWord(StrPosPtr(@Str, 1))^;
    H := pLongWord(StrPosPtr(@Str, 5))^;
    If Length(Str) - 10 = W * H Then Valid := True;
  End;
  If Not Valid Then Begin
    Str := SP_StringToTexture(Str);
    If Str = '' Then Begin
      Info^.Error^.Code := SP_ERR_INVALID_GRAB_STRING;
      Exit;
    End;
    W := pLongWord(StrPosPtr(@Str, 1))^;
    H := pLongWord(StrPosPtr(@Str, 5))^;
  End;

  SP_MirrorGfx(Src, W, H);

  SP_StackPtr^.Str := Str;

End;

Procedure SP_Interpret_GFX_ERASE(Var Info: pSP_iInfo);
Var
  Id, Idx: Integer;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

      SP_DeleteBank(Idx, Info^.Error^);

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_GFX_TRANSPARENT(Var Info: pSP_iInfo);
Var
  Gfx: pSP_Graphic_Info;
  Id, Idx, Trans: Integer;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Trans := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @SP_BankList[Idx]^.Info[0];
      Gfx^.Transparent := Word(Trans);

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_GFX_REMAP(Var Info: pSP_iInfo);
Var
  Gfx: pSP_Graphic_Info;
  Id, Idx, Dt: Integer;
  ConvArray: Array of Byte;
Begin

  SetLength(ConvArray, 256);

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Dt := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @SP_BankList[Idx]^.Info[0];
      SP_Dither_Image(Gfx, Dt);

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_GFX_PALETTE(Var Info: pSP_iInfo);
Var
  Gfx: pSP_Graphic_Info;
  Id, Idx, Val1, Val2, Val3, Val4: Integer;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @SP_BankList[Idx]^.Info[0];

      Val1 := Trunc(SP_StackPtr^.Val);
      Dec(SP_StackPtr);

      Val2 := Trunc(SP_StackPtr^.Val);
      Dec(SP_StackPtr);

      If NativeUInt(SP_StackPtr) >= NativeUInt(SP_StackStart) + SizeOf(SP_StackItem) Then Begin

        Val3 := Trunc(SP_StackPtr^.Val);
        Dec(SP_StackPtr);

        Val4 := Round(SP_StackPtr^.Val);
        Dec(SP_StackPtr);

        If (Val1 > 255) or (Val1 < 0) or (Val2 > 255) or (Val2 < 0) or (Val3 > 255) or (Val3 < 0) or (Val4 > 255) or (Val4 < 0) Then Begin
          Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
          Exit;
        End Else Begin
          Gfx^.Palette[Val4].R := Val3;
          Gfx^.Palette[Val4].G := Val2;
          Gfx^.Palette[Val4].B := Val1;
        End;

      End Else Begin

        Gfx^.Palette[Val2].R := (Val1 Shr 16) And $FF;
        Gfx^.Palette[Val2].G := (Val1 Shr 8) And $FF;
        Gfx^.Palette[Val2].B := Val1 And $FF;

      End;

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_GFX_PAL_HSV(Var Info: pSP_iInfo);
Var
  Gfx: pSP_Graphic_Info;
  Id, Idx, Val1, Val2, Val3, Val4: Integer;
  R, G, B, H, S, V: aFloat;
Begin

  Id := Trunc(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @SP_BankList[Idx]^.Info[0];

      Val1 := Trunc(SP_StackPtr^.Val);
      Dec(SP_StackPtr);

      Val2 := Trunc(SP_StackPtr^.Val);
      Dec(SP_StackPtr);

      If NativeUInt(SP_StackPtr) >= NativeUInt(SP_StackStart) + SizeOf(SP_StackItem) Then Begin

        Val3 := Trunc(SP_StackPtr^.Val);
        Dec(SP_StackPtr);
        Val4 := Round(SP_StackPtr^.Val);
        Dec(SP_StackPtr);

        If (Val1 > 255) or (Val1 < 0) or (Val2 > 255) or (Val2 < 0) or (Val3 > 255) or (Val3 < 0) or (Val4 > 255) or (Val4 < 0) Then Begin
          Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
          Exit;
        End Else Begin
          H := Val3;
          S := Val2;
          V := Val1;
          SP_HSVToRGB(H, S, V, R, G, B);
          Gfx^.Palette[Val4].R := Round(R);
          Gfx^.Palette[Val4].G := Round(G);
          Gfx^.Palette[Val4].B := Round(B);
        End;

      End Else Begin

        H := (Val1 Shr 16) And $FFFF;
        S := (Val1 Shr 8) And $FF;
        V := Val1 And $FF;
        SP_HSVToRGB(H, S, V, R, G, B);
        Gfx^.Palette[Val2].R := Round(R);
        Gfx^.Palette[Val2].G := Round(G);
        Gfx^.Palette[Val2].B := Round(B);

      End;

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_GFX_PAL_DEFAULT(Var Info: pSP_iInfo);
Var
  Id, Idx: Integer;
  Gfx: pSP_Graphic_Info;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @SP_BankList[Idx]^.Info[0];

      For Idx := 0 To 223 Do
        Gfx^.Palette[Idx] := DefaultPalette[Idx];
      Idx := 224;
      While Idx < 256 Do Begin
        Gfx^.Palette[Idx].R := (Idx - 224)*8;
        Gfx^.Palette[Idx].G := (Idx - 224)*8;
        Gfx^.Palette[Idx].B := (Idx - 224)*8;
        Inc(Idx);
      End;

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_PAL_COPY(Var Info: pSP_iInfo);
Var
  Id, Idx, Start, Count, Dest, DestObject, DestObjectType: Integer;
  GotDestObject: Boolean;
  Gfx: pSP_Graphic_Info;
  Win: pSP_Window_Info;
  Palette: Array of TP_Colour;
Begin

  Id := Round(SP_StackPtr^.Val); // -ve for a WINDOW, +ve for a GRAPHIC
  Dec(SP_StackPtr);

  Start := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Count := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  GotDestObject := Round(SP_StackPtr^.Val) = 1;
  If GotDestObject Then Begin
    Dec(SP_StackPtr);
    DestObject := Round(SP_StackPtr^.Val); // -ve for a WINDOW, +ve for a GRAPHIC
    If DestObject < 0 Then
      DestObjectType := SP_WINDOW_BANK
    Else
      DestObjectType := SP_GRAPHIC_BANK;
    DestObject := Abs(DestObject);
    Dec(SP_StackPtr);
  End Else Begin
    DestObject := SCREENBANK;
    DestObjectType := SP_WINDOW_BANK;
    Dec(SP_StackPtr);
  End;

  Dest := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If (Start < 0) or (Start > 255) or (Dest < 0) or (Dest > 255) or (Count + Start -1 > 255) or (Count = 0) or (Dest + Count -1 > 255) Then Begin
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    Exit;
  End;

  Idx := SP_FindBankID(Abs(Id));
  If Idx > -1 Then Begin
    If SP_BankList[Idx]^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @SP_BankList[Idx]^.Info[0];
      SetLength(Palette, Count);
      For Idx := Start To Start + Count -1 Do
        Palette[Idx - Start] := Gfx^.Palette[Idx];

    End Else
      If SP_BankList[Idx]^.DataType = SP_WINDOW_BANK Then Begin

        Win := @SP_BankList[Idx]^.Info[0];
        SetLength(Palette, Count);
        For Idx := Start To Start + Count -1 Do
          Palette[Idx - Start] := Win^.Palette[Idx];

      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

  If Info^.Error^.Code = SP_ERR_OK Then Begin

    If GotDestObject Then Begin

      Idx := SP_FindBankID(DestObject);
      If Idx > -1 Then Begin
        If SP_BankList[Idx]^.DataType = DestObjectType Then Begin
          If DestObjectType = SP_GRAPHIC_BANK Then Begin
            Gfx := @SP_BankList[Idx]^.Info[0];
            For Idx := Dest To Dest + Count -1 Do
              Gfx^.Palette[Idx] := Palette[Idx - Dest];
          End Else Begin
            Win := @SP_BankList[Idx]^.Info[0];
            For Idx := Dest To Dest + Count -1 Do
              Win^.Palette[Idx] := Palette[Idx - Dest];
          End;
        End Else
          Info^.Error^.Code := SP_ERR_INVALID_BANK;
      End Else
        Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

    End Else
      SP_SetPalette(Dest, Palette);

  End;

End;

Procedure SP_Interpret_RENUMBER(Var Info: pSP_iInfo);
Var
  Start, Finish, Line, Step: Integer;
Begin

  Step := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Line := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Finish := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Start := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  DoAutoSave;

  SP_FPRenumberListing(Start, Finish, Line, Step, Info^.Error^);

End;

Procedure SP_Interpret_ERASE_LINES(Var Info: pSP_iInfo);
Var
  Start, Finish, ProgLen: Integer;
Begin

  Finish := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If INCLUDEFROM <> -1 Then
    ProgLen := INCLUDEFROM
  Else
    ProgLen := SP_Program_Count;

  If Finish = -1 Then Finish := pLongWord(@SP_Program[ProgLen -1][2])^;

  Start := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  DoAutoSave;

  SP_FPDeleteLines(Start, Finish, Info^.Error^);

End;

Procedure SP_Interpret_LIST(Var Info: pSP_iInfo);
Var
  ProgLen: Integer;
Begin

  // LIST all lines, as one big PRINT.

  Inc(SP_StackPtr);

  If INCLUDEFROM <> -1 Then
    ProgLen := INCLUDEFROM
  Else
    ProgLen := SP_Program_Count;

  SP_StackPtr^.OpType := SP_STRING;
  If SP_Program_Count > 0 Then
    SP_StackPtr^.Str := SP_LIST(0, pLongWord(@SP_Program[ProgLen -1][2])^)
  Else
    SP_StackPtr^.Str := '';
  SP_Interpret_PRINT(Info);

End;

Procedure SP_Interpret_LIST_LINES(Var Info: pSP_iInfo);
Var
  Start, Finish, ProgLen: Integer;
Begin

  If INCLUDEFROM <> -1 Then
    ProgLen := INCLUDEFROM
  Else
    ProgLen := SP_Program_Count;

  Finish := Round(SP_StackPtr^.Val);
  If Finish = -1 Then Finish := pLongWord(@SP_Program[ProgLen -1][2])^;
  Dec(SP_StackPtr);

  Start := Round(SP_StackPtr^.Val);

  If Start > Finish Then Begin
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
    Dec(SP_StackPtr);
    Exit;
  End Else Begin
    SP_StackPtr^.OpType := SP_STRING;
    SP_StackPtr^.Str := SP_LIST(Start, Finish);
    SP_Interpret_PRINT(Info);
    PROGLINE := Start;
  End;

End;

Procedure SP_Interpret_LIST_BANK(Var Info: pSP_iInfo);
Var
  Output, SizeStr, HexStr, AsciiStr: aString;
  Bank: pSP_Bank;
  TextList: TAnsiStringList;
  BankID, Idx, Size, LineW, CurLineW, gW, gH, gBank, nBank, x, y, OldFont: Integer;
  Window_Info: pSP_Window_Info;
  Sprite_Info: pSP_Sprite_Info;
  Tilemap_Info: pSP_Tilemap_Info;
  Font_Info: pSP_Font_Info;
  Screen_Info: pSP_Bank_Screen;
  Sample_Info: pSP_Sample_Info;
  ptr: pByte;
Begin

  TextList := TAnsiStringList.Create;

  Output := '';
  BankID := Round(SP_StackPtr^.Val);

  If BankID = -1 Then Begin

    // List all banks

    For Idx := 0 To Length(SP_BankList) -1 Do Begin

      Bank := SP_BankList[Idx];
      Size := Length(Bank^.Memory);
      SizeStr := ' (';
      If Size > 1048576 Then
        SizeStr := SizeStr + IntToString(Size Div 1048576)+' MBytes)'
      Else
        If Size > 1024 Then
          SizeStr := SizeStr + IntToString(Size Div 1024)+' KBytes)'
        Else
          SizeStr := SizeStr + IntToString(Size) + ' Bytes)';

      Output := IntToString(Bank^.ID);
      While Length(Output) < 8 Do
        Output := '0' + Output;
      Output := Output + ':';

      If Bank^.System Then
        Output := Output + #16#2#0#0#0#248#16 + LongWordToString(T_INK) + ' '
      Else
        If Bank^.Protection Then
          Output := Output + aChar(248) + ' '
        Else
          Output := Output + '  ';

      Case Bank^.DataType of
        0: // Binary object
          Begin
            Output := Output + 'Binary';
          End;
        1: // Graphic
          Begin
            Output := Output + 'Graphic ';
            Output := Output + IntToString(pSP_Graphic_Info(@Bank^.Info[0])^.Width) + 'x';
            Output := Output + IntToString(pSP_Graphic_Info(@Bank^.Info[0])^.Height);
            If pSP_Graphic_Info(@Bank^.Info[0])^.Transparent <> $FFFF Then
              Output := Output + ' T'+IntToString(pSP_Graphic_Info(@Bank^.Info[0])^.Transparent And $FF);
          End;
        2: // Font
          Begin
            Output := Output + 'Font ';
            Output := Output + IntToString(pSP_Font_Info(@Bank^.Info[0])^.Width) + 'x';
            Output := Output + IntToString(pSP_Font_Info(@Bank^.Info[0])^.Height);
          End;
        3: // Screen
          Begin
            Output := Output + 'Screen ';
            Window_Info := pSP_Window_Info(@Bank^.Info[(256 * SizeOf(TP_Colour)) + SizeOf(LongWord)]);
            Output := Output + IntToString(Window_Info^.Width) + 'x';
            Output := Output + IntToString(Window_Info^.Height);
            Output := Output + ', ' + IntToString(pSP_Bank_Screen(@Bank.Info[0])^.NumWindows) + ' windows';
          End;
        4: // Program
          Begin
          End;
        5: // Sample
          Begin
            Output := Output + 'Sample';
          End;
        6: // Sprite
          Begin
            Output := Output + 'Sprite - ';
            Sprite_Info := pSP_Sprite_Info(@Bank^.Info[0]);
            If Sprite_Info^.NumFrames > 0 Then Begin
              Output := Output + IntToString(Sprite_Info^.NumFrames) + ' frames, ' + IntToString((pLongWord(NativeUInt(Sprite_Info^.Data) + SizeOf(LongWord))^)) + 'x';
              Output := Output + IntToString(pLongWord(NativeUInt(Sprite_Info^.Data) + (SizeOf(LongWord) *2))^);
            End Else
              Output := Output + 'no frames';
          End;
        7: // Tilemap
          Begin
            Output := Output + 'Tilemap - ';
            Tilemap_Info := @Bank^.Info[0];
            Output := Output + IntToString(Tilemap_Info.MapWidth) + 'x' + IntToString(Tilemap_Info.MapHeight);
          End;
        8: // Window
          Begin
            Output := Output + 'Window - ';
            Window_Info := pSP_Window_Info(@Bank^.Info[0]);
            Output := Output + IntToString(Window_Info^.Width) + 'x';
            Output := Output + IntToString(Window_Info^.Height)+ ', ';
            Output := Output + IntToString(Window_Info^.Bpp)+ ' Bpp';
          End;
      End;

      Output := Output + SizeStr + #13;
      TextList.Add(Output);

    End;

    TextList.Sort;
    Output := '';
    For Idx := 0 To TextList.Count -1 Do Begin
      AsciiStr := TextList[Idx];
      x := 1;
      While AsciiStr[x] = '0' Do Inc(x);
      If AsciiStr[x] = ':' Then Dec(x);
      Output := Output + Copy(AsciiStr, x, Length(AsciiStr));
    End;
    TextList.Free;

  End Else Begin

    // List one bank, a detailed view of the data within. Each bank is displayed differently, depending
    // on what datatype it contains.

    Output := '';
    BankID := SP_FindBankID(BankID);
    If BankID = -1 Then Begin
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
      Exit;
    End;

    Bank := SP_BankList[BankID];

    Size := Length(Bank^.Memory);
    SizeStr := ' (';
    If Size > 1048576 Then
      SizeStr := SizeStr + IntToString(Size Div 1048576)+' MBytes)'
    Else
      If Size > 1024 Then
        SizeStr := SizeStr + IntToString(Size Div 1024)+' KBytes)'
      Else
        SizeStr := SizeStr + IntToString(Size) + ' Bytes)';
    Output := Output + IntToString(Bank^.ID) + ':';
    If Bank^.System Then
      Output := Output + #16#2#0#0#0#248#16 + LongWordToString(T_INK) + ' '
    Else
      If Bank^.Protection Then
        Output := Output + aChar(248) + ' '
      Else
        Output := Output + '  ';

    Case Bank^.DataType Of

      0: // Object bank - hex display of contents
        Begin
          Output := Output + 'Binary' + SizeStr + #13#13 + HexDump(@Bank^.Memory[0], Length(Bank^.Memory), SCREENWIDTH Div FONTWIDTH);
          SizeStr := '';
        End;

      1: // Graphic bank - display graphic as thumbnail with a maximum width of 128 pixels and palette block.
        Begin
          CurLineW := Length(Output);
          AsciiStr := '';
          While Length(AsciiStr) < CurLineW Do AsciiStr := AsciiStr + ' ';
          gW := pSP_Graphic_Info(@Bank^.Info[0])^.Width;
          gH := pSP_Graphic_Info(@Bank^.Info[0])^.Height;
          Output := Output + 'Graphic ';
          Output := Output + IntToString(gW) + 'x';
          Output := Output + IntToString(gH);
          If pSP_Graphic_Info(@Bank^.Info[0])^.Transparent <> $FFFF Then
            Output := Output + ' T'+IntToString(pSP_Graphic_Info(@Bank^.Info[0])^.Transparent And $FF);
          Output := Output + SizeStr + #13 + AsciiStr + 'Preview:' + #13;

          SP_StackPtr^.OpType := SP_STRING;
          SP_StackPtr^.Str := Output;
          SP_Interpret_PRINT(Info);

          OldFont := FONTBANKID;
          nBank := SP_GraphicToFont(BankID, Output, CurLineW, Info^.Error^);
          SP_SetSystemFont(nBank, Info^.Error^);

          Inc(SP_StackPtr);
          SP_StackPtr^.OpType := SP_STRING;
          SP_StackPtr^.Str := Output;
          SP_Interpret_PRINT(Info);

          SP_SetSystemFont(OldFont, Info^.Error^);

          Output := '';
          SizeStr := '';

          SP_DeleteBank(SP_FindBankID(nBank), Info^.Error^);

        End;

      2: // Font bank - display font metrics and preview the font with ascii chars
        Begin

          Font_Info := @Bank^.Info[0];
          AsciiStr := #23 + LongWordToString(Length(Output));
          Output := Output + 'Font with ';
          If Font_Info^.FontType = 0 Then Output := Output + 'Mono' Else Output := Output + 'Colour';
          Output := Output + ' characters ';
          Output := Output + IntToString(Font_Info^.Width) + 'x';
          Output := Output + IntToString(Font_Info^.Height);
          If Font_Info^.Transparent <> $FFFF Then
            Output := Output + ', T'+IntToString(Font_Info^.Transparent And $FF);
          Output := Output + SizeStr + #13 + AsciiStr + 'Preview:' + #13;

          SP_StackPtr^.OpType := SP_STRING;
          SP_StackPtr^.Str := Output;
          SP_Interpret_PRINT(Info);
          OldFont := FONTBANKID;

          SizeStr := '';
          x := SP_Get_Nearest_Colour($FF, $FF, $FF, -1);
          y := SP_Get_Contrasting_Ink(x);
          Output := aChar(16) + LongWordToString(y);

          For Idx := 32 To 255 Do Begin
            If Idx Mod 32 = 0 Then
               Output := Output + #13 + aChar(17) + LongWordToString(CPAPER) + #23#1#0#0#0 + aChar(17) + LongWordToString(x);
            Output := Output + aChar(Idx);
          End;

          SP_SetSystemFont(Bank^.ID, Info^.Error^);
          Inc(SP_StackPtr);
          SP_StackPtr^.OpType := SP_STRING;
          SP_StackPtr^.Str := Output;
          SP_Interpret_PRINT(Info);
          SP_SetSystemFont(OldFont, Info^.Error^);
          Output := '';
          SizeStr := '';

        End;

      3: // Screen bank - show screen metrics and list windows and their metrics/sizes
        Begin

          CurLineW := Length(Output);
          Output := Output + 'Screen ';
          Screen_Info := @Bank.Info[0];
          Window_Info := pSP_Window_Info(@Bank^.Info[(256 * SizeOf(TP_Colour)) + SizeOf(LongWord)]);
          Output := Output + IntToString(Window_Info^.Width) + 'x';
          Output := Output + IntToString(Window_Info^.Height);
          Output := Output + ',' + SizeStr + #13;
          For x := 1 To CurLineW Do
            Output := Output + ' ';
          Output := Output + 'Palette: ';
          For Idx := 0 To 255 Do Begin
            If Idx Mod 16 = 0 Then Begin
              Output := Output + #13 + aChar(17) + LongWordToString(CPAPER);
              For x := 1 To CurLineW Do
                Output := Output + ' ';
            End;
            Output := output + aChar(17) + LongWordToString(Idx) + ' ';
          End;
          Output := Output + #13#13 + aChar(17) + LongWordToString(CPAPER);
          For x := 1 To CurLineW Do
            Output := Output + ' ';
          If Screen_Info^.NumWindows = 1 Then
            Output := Output + IntToString(Screen_Info^.NumWindows) + ' window:'+#13
          Else
            Output := Output + IntToString(Screen_Info^.NumWindows) + ' windows:'+#13;
          For idx := 0 To Screen_Info^.NumWindows -1 Do Begin
            Window_Info := pSP_Window_Info(@Bank^.Info[(256 * SizeOf(TP_Colour)) + SizeOf(LongWord) + (Idx * SizeOf(SP_Window_Info))]);
            HexStr := ' Window '+IntToString(Window_Info^.ID)+': ';
            For LineW := 2 To CurLineW Do HexStr := ' ' + HexStr;
            Output := Output + HexStr +IntToString(Window_Info^.Width)+'x'+IntToString(Window_Info^.Height);
            Output := Output + ' at '+IntToString(Window_Info^.Left) + ',' + IntToString(Window_Info^.Top)+#13;
            AsciiStr := '';
            While Length(AsciiStr) < Length(HexStr) Do AsciiStr := AsciiStr + ' ';
            If Window_Info^.FontBankID = -1 Then
              Output := Output + AsciiStr + 'Using default font, '
            Else
              Output := Output + AsciiStr + 'Using Font '+IntToString(Window_Info^.FontBankID) + ', ';
            If Window_Info^.SpriteCount > 0 Then
              Output := Output + IntToString(Window_Info^.SpriteCount)+ ' sprites.'+#13
            Else
              Output := Output + 'no sprites.'+#13;
            If Window_Info^.Transparent = Word(-1) Then
              Output := output + AsciiStr + 'Non-transparent, '
            Else
              Output := output + AsciiStr + 'Transparent '+IntToString(Window_Info^.Transparent And $FF)+', ';
            If Window_Info^.Visible Then
              Output := Output + 'visible.'#13
            Else
              Output := Output + 'hidden.'#13;
            Output := Output + AsciiStr + 'Flags: I'+IntToString(Window_Info^.Ink)+' P'+IntToString(Window_Info^.Paper)+' V'+IntToString(Window_Info^.Inverse);
            Output := Output + ' O'+IntToString(Window_Info^.Over)+#13;
          End;

          SizeStr := '';

        End;

      4: // Program bank
        Begin
        End;

      5: // Sample bank - list sample info
        Begin

          CurLineW := Length(Output);
          AsciiStr := '';
          While Length(AsciiStr) < CurLineW Do AsciiStr := AsciiStr + ' ';
          Output := Output + 'Sample data' + SizeStr + #13 + AsciiStr;
          Sample_Info := @Bank.Info[0];

          Output := Output + IntToString(Sample_Info^.Rate) + 'Hz, ' + IntToString(Sample_Info^.Bits) + ' bits ';
          If Sample_Info^.Channels = 1 Then
            Output := Output + 'mono.'
          Else
            Output := Output + 'stereo.';
          Output := Output + #13 + AsciiStr + 'Panned to the ';
          If Sample_Info^.Panning < 0 Then
            Output := Output + 'left ('
          Else
            If Sample_Info^.Panning > 0 Then
              Output := Output + 'right ('
            Else
              Output := Output + 'centre (';
          Output := Output + aString(aFloatToStr(Sample_Info^.Panning))+')' + #13 + AsciiStr;
          Output := Output + 'Volume is set to '+aString(aFloatToStr(Sample_Info^.Volume));
          If Sample_Info^.Volume = 0 Then
            Output := Output + ' (silent)'
          Else
            If Sample_Info^.Volume = 1 then
              Output := Output + ' (full)';
          SizeStr := '';

        End;

      6: // Sprite bank
        Begin
          CurLineW := Length(Output);
          AsciiStr := '';
          While Length(AsciiStr) < CurLineW Do AsciiStr := AsciiStr + ' ';
          Sprite_Info := @Bank.Info[0];
          Output := Output + 'Sprite ' + IntToString(Sprite_Info^.ID) + SizeStr + #13 + AsciiStr;
          Output := Output + 'Associated with Window ' + IntToString(Sprite_Info^.Window^.ID) + ' at ' + aString(aFloatToStr(Sprite_Info^.X)+','+aFloatToStr(Sprite_Info^.Y)) + #13 + AsciiStr;
          If Sprite_Info^.Enabled Then
            Output := Output + 'Sprite is showing, '
          Else
            Output := Output + 'Sprite is hidden, ';
          Output := Output + 'rotated to ' + aString(aFloatToStr(Sprite_Info^.Angle) + ', scale factor ' + aFloatToStr(Sprite_Info^.Scale)) + '.' + #13 + AsciiStr;
          If Sprite_Info^.NumFrames = 0 Then
            Output := Output + 'No frames.'
          Else Begin
            Output := Output + IntToString(Sprite_Info^.NumFrames)+' frames.'+#13+AsciiStr;
            ptr := Sprite_Info^.Data;
            Inc(ptr, SizeOf(LongWord));
            gw := pLongWord(ptr)^;
            gh := pLongWord(NativeUInt(ptr) + SizeOf(LongWord))^;
            Output := Output + 'Preview of 1st frame ('+ IntToString(gw) + 'x' + IntToString(gh) + '):' + #13;
            SetLength(HexStr, (SizeOf(LongWord)*2) + SizeOf(Word) + (gw * gh));
            CopyMem(@HexStr[1], ptr, Length(HexStr));
            gBank := SP_New_GraphicB(HexStr, Info^.Error^);
            SP_StackPtr^.OpType := SP_STRING;
            SP_StackPtr^.Str := Output;
            SP_Interpret_PRINT(Info);

            OldFont := FONTBANKID;
            nBank := SP_GraphicToFont(gBank, Output, CurLineW, Info^.Error^);
            SP_SetSystemFont(nBank, Info^.Error^);

            Inc(SP_StackPtr);
            SP_StackPtr^.OpType := SP_STRING;
            SP_StackPtr^.Str := Output;
            SP_Interpret_PRINT(Info);

            SP_SetSystemFont(OldFont, Info^.Error^);

            Output := '';
            SizeStr := '';

            SP_DeleteBank(SP_FindBankID(nBank), Info^.Error^);
            SP_DeleteBank(SP_FindBankID(gBank), Info^.Error^);

          End;

        End;

      7: // Tilemap

        Begin
          CurLineW := Length(Output);
          AsciiStr := '';
          While Length(AsciiStr) < CurLineW Do AsciiStr := AsciiStr + ' ';
          TileMap_Info := @Bank.Info[0];
          Output := Output + 'TileMap' + SizeStr + #13 + AsciiStr;
          Output := Output + IntToString(TileMap_Info^.MapWidth) + 'x' + IntToString(TileMap_Info^.MapHeight) + ' cells.' + #13 + AsciiStr;
          If TileMap_Info^.InternalGFX Then Begin
            Output := Output + 'Using internal tile graphics - ' + IntToString(TileMap_Info^.NumTiles) + ' in ' +
                               IntToString(TileMap_Info^.NumTilesX * TileMap_Info^.TileWidth) + 'x' +
                               IntToString(TileMap_Info^.NumTilesY * TileMap_Info^.TileHeight) + ' pixels - preview:'+#13;
            ptr := pByte(TileMap_Info^.GraphicData);
            gw := pLongWord(ptr)^;
            gh := pLongWord(NativeUInt(ptr) + SizeOf(LongWord))^;
            SetLength(HexStr, (SizeOf(LongWord)*2) + SizeOf(Word) + (gw * gh));
            CopyMem(@HexStr[1], ptr, Length(HexStr));
            gBank := SP_New_GraphicB(HexStr, Info^.Error^);
            SP_StackPtr^.OpType := SP_STRING;
            SP_StackPtr^.Str := Output;
            SP_Interpret_PRINT(Info);

            OldFont := FONTBANKID;
            nBank := SP_GraphicToFont(gBank, Output, CurLineW, Info^.Error^);
            SP_SetSystemFont(nBank, Info^.Error^);

            Inc(SP_StackPtr);
            SP_StackPtr^.OpType := SP_STRING;
            SP_StackPtr^.Str := Output;
            SP_Interpret_PRINT(Info);

            SP_SetSystemFont(OldFont, Info^.Error^);
            Output := #13#13 + AsciiStr;

          End Else Begin

            Output := Output + 'Using bank ' + IntToString(TileMap_Info^.GraphicID) + ' for tiles.' + #13#13 + AsciiStr;

          End;

          Output := Output + 'Tiles are ' + IntToString(TileMap_Info^.TileWidth) + 'x' + IntToString(TileMap_Info^.TileHeight) + ' pixels.' + #13 + AsciiStr;
          SizeStr := '';

        End;

      8: // Window bank

        Begin

          CurLineW := Length(Output);
          Window_Info := pSP_Window_Info(@Bank^.Info[0]);
          HexStr := 'Window '+IntToString(Window_Info^.ID)+': ';
          For LineW := 2 To CurLineW Do HexStr := ' ' + HexStr;
          Output := Output + HexStr +IntToString(Window_Info^.Width)+'x'+IntToString(Window_Info^.Height);
          Output := Output + ' at '+IntToString(Window_Info^.Left) + ',' + IntToString(Window_Info^.Top)+#13;
          AsciiStr := '';
          While Length(AsciiStr) < Length(HexStr) Do AsciiStr := AsciiStr + ' ';
          If Window_Info^.FontBankID = -1 Then
            Output := Output + AsciiStr + 'Using default font, '
          Else
            Output := Output + AsciiStr + 'Using Font '+IntToString(Window_Info^.FontBankID) + ', ';
          If Window_Info^.SpriteCount > 0 Then
            Output := Output + IntToString(Window_Info^.SpriteCount)+ ' sprites.'+#13
          Else
            Output := Output + 'no sprites.'+#13;
          If Window_Info^.Transparent = Word(-1) Then
            Output := output + AsciiStr + 'Non-transparent, '
          Else
            Output := output + AsciiStr + 'Transparent '+IntToString(Window_Info^.Transparent And $FF)+', ';
          If Window_Info^.Visible Then
            Output := Output + 'visible.'#13
          Else
            Output := Output + 'hidden.'#13;
          Output := Output + AsciiStr + 'Flags: I'+IntToString(Window_Info^.Ink)+' P'+IntToString(Window_Info^.Paper)+' V'+IntToString(Window_Info^.Inverse);
          Output := Output + ' O'+IntToString(Window_Info^.Over)+#13;
          SizeStr := '';

        End;

    End;

    Output := Output + SizeStr + #13;

  End;

  SP_StackPtr^.OpType := SP_STRING;
  SP_StackPtr^.Str := Output;
  SP_Interpret_PRINT(Info);

End;

Procedure SP_Interpret_LIST_BANK_EX(Var Info: pSP_iInfo);
Var
  Output, SizeStr: aString;
  BankID, Size: Integer;
  Bank: pSP_Bank;
Begin

  Output := '';

  BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
  If BankID = -1 Then Begin
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
    Exit;
  End;

  Bank := SP_BankList[BankID];

  Size := Length(Bank^.Memory);
  SizeStr := ' (';
  If Size > 1048576 Then
    SizeStr := SizeStr + IntToString(Size Div 1048576)+' MBytes)'
  Else
    If Size > 1024 Then
      SizeStr := SizeStr + IntToString(Size Div 1024)+' KBytes)'
    Else
      SizeStr := SizeStr + IntToString(Size) + ' Bytes)';
  Output := Output + IntToString(Bank^.ID) + ': ';
  Output := Output + 'Hex Dump' + SizeStr + #13#13 + HexDump(@Bank^.Memory[0], Length(Bank^.Memory), SCREENWIDTH Div FONTWIDTH);
  SP_StackPtr^.OpType := SP_STRING;
  SP_StackPtr^.Str := Output;
  SP_Interpret_PRINT(Info);

End;

Procedure SP_Interpret_LIST_WINDOW(Var Info: pSP_iInfo);
Begin

End;

Procedure SP_MakeListVarOutput(Var List: TAnsiStringlist; UseLiterals: Boolean);
Var
  Str, TempStr: aString;
  Idx, Idx2: Integer;
  nVar: pSP_NumVarContent;
  sVar: pSP_StrVarContent;
  nArr: pSP_NumArray;
  sArr: pSP_StrArray;
Begin

  List.Clear;

  If (NumNV = 0) And (NumSV = 0) And (Length(NumArrays) = 0) And (Length(StrArrays) = 0) Then Begin

    List.Add('No variables defined');
    List.Objects[0] := TObject(-1);

  End Else Begin

    If NumNV > 0 Then

      For Idx := 0 To NumNV -1 Do Begin

        nVar := NumVars[Idx]^.ContentPtr;

        Str := '';
        If NumVars[Idx]^.ProcVar Then
          For Idx2 := SP_ProcStackPtr DownTo 0 Do
            If Idx >= SP_ProcStack[Idx2].VarPosN Then Begin
              Str := '['+SP_ProcsList[SP_ProcStack[Idx2].ProcIndex].Name+'] ';
              Break;
            End;

        Str := Str + NumVars[Idx]^.Name + '=';

        If nVar^.VarType = SP_FORVAR Then Begin

          Str := Str + aString(aFloatToStr(nVar^.Value) + ', FOR ' + aFloatToStr(nVar^.InitVal) + ' TO ' + aFloatToStr(nVar^.EndAt));
          If nVar^.Step <> 1 Then
            Str := Str + ' STEP ' + aString(aFloatToStr(nVar^.Step));
          If (nVar^.LoopLine >= 0) And (nVar^.LoopLine < SP_Program_Count) Then
            Str := Str + ', NEXT at ' + IntToString(pInteger(@SP_Program[nVar^.LoopLine][2])^) + ':' + IntToString(nVar^.St)
          Else
            Str := Str + ', NEXT Statement lost';

        End Else

          Str := Str + aString(aFloatToStr(nVar^.Value));

        List.Add(Str);

      End;

    If NumSV > 0 Then

      For Idx := 0 To NumSV -1 Do Begin

        sVar := StrVars[Idx]^.ContentPtr;
        Str := StrVars[Idx]^.Name + '$="' + Copy(sVar^.Value, 1, (SCREENWIDTH Div FONTWIDTH) - (Length(StrVars[Idx]^.Name) + 3)) + '"';
        if UseLiterals Then
          Str := InsertLiterals(Str)
        Else
          SP_ReplaceSpecialChars(Str);
        List.Add(Str);

      End;

    If Length(numArrays) > 0 Then

      For Idx := 0 To Length(NumArrays) -1 Do Begin
        nArr := @NumArrays[Idx];
        Str := nArr^.Name + '(';
        For Idx2 := 0 To nArr^.NumIndices -1 Do Begin
          Str := Str + IntToString(nArr^.Indices[Idx2]);
          If Idx2 < nArr^.NumIndices -1 Then
            Str := Str + ',';
        End;
        Str := Str + ')=';
        TempStr := SP_NumArrayToString(Idx, (SCREENWIDTH Div FONTWIDTH) - Length(Str) - 4);
        List.Add(Str + TempStr);
      End;

    If Length(strArrays) > 0 Then

      For Idx := 0 To Length(strArrays) -1 Do Begin
        sArr := @strArrays[Idx];
        Str := sArr^.Name + '$(';
        For Idx2 := 0 To sArr^.NumIndices -1 Do Begin
          Str := Str + IntToString(sArr^.Indices[Idx2]);
          If Idx2 < sArr^.NumIndices -1 Then
            Str := Str + ',';
        End;
        Str := Str + ')=';
        TempStr := SP_StrArrayToString(Idx, (SCREENWIDTH Div FONTWIDTH) - Length(Str) - 4);
        if UseLiterals Then
          TempStr := InsertLiterals(TempStr)
        Else
          SP_ReplaceSpecialChars(TempStr);
        List.Add(Str + TempStr);
      End;

    List.Objects[0] := TObject(0);

  End;

End;

Procedure SP_Interpret_LIST_VAR(Var Info: pSP_iInfo);
Var
  Output: aString;
  Idx: Integer;
  Vars: TAnsiStringList;
Begin

  // List the variables currently declared and their values

  Vars := TAnsiStringList.Create;

  SP_MakeListVarOutput(Vars, False);
  Output := '';
  For Idx := 0 To Vars.Count -1 Do
    Output := Output + aString(Vars[Idx]) + #13;

  Vars.Free;

  SP_StackPtr^.OpType := SP_STRING;
  SP_StackPtr^.Str := aString(Output);
  SP_Interpret_PRINT(Info);

End;

Procedure SP_Interpret_LIST_ARRAY(Var Info: pSP_iInfo);
Var
  VarName, Output, TempStr: aString;
  Idx, Idx2: Integer;
Begin

  VarName := Lower(SP_StackPtr^.Str);
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    Idx := 0;
    While Idx < Length(NumArrays) Do
      If NumArrays[Idx].Name = VarName Then Begin
        Output := VarName + '(';
        For Idx2 := 0 To NumArrays[Idx].NumIndices -1 Do Begin
          Output := Output + IntToString(NumArrays[Idx].Indices[Idx2]);
          If Idx2 < NumArrays[Idx].NumIndices -1 Then
            Output := Output + ',';
        End;
        Output := Output + ')=' + SP_NumArrayToString(Idx, -1);
        SP_StackPtr^.OpType := SP_STRING;
        SP_StackPtr^.Str := Output + #13;
        SP_Interpret_PRINT(Info);
        Exit;
      End Else
        Inc(Idx);
  End Else Begin
    Idx := 0;
    While Idx < Length(StrArrays) Do
      If StrArrays[Idx].Name = VarName Then Begin
        Output := VarName + '$(';
        For Idx2 := 0 To StrArrays[Idx].NumIndices -1 Do Begin
          Output := Output + IntToString(StrArrays[Idx].Indices[Idx2]);
          If Idx2 < StrArrays[Idx].NumIndices -1 Then
            Output := Output + ',';
        End;
        TempStr := SP_StrArrayToString(Idx, -1);
        SP_ReplaceSpecialChars(TempStr);
        Output := Output + ')=' + TempStr;
        SP_StackPtr^.OpType := SP_STRING;
        SP_StackPtr^.Str := Output + #13;
        SP_Interpret_PRINT(Info);
        Exit;
      End Else
        Inc(Idx);
  End;

  ERRStr := VarName;
  Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_LIST_ASSIGN(Var Info: pSP_iInfo);
Var
  Output, Ass: aString;
  Idx: Integer;
Begin

  Idx := 0;
  Output := '$: ' + SP_ConvertHostFilename(aString(GetCurrentDir), Info^.Error^)+#13;
  While Idx < Length(SP_Ass_List) Do Begin
    Output := Output + Upper(Copy(SP_Ass_List[Idx], 1, Pos(#255, SP_Ass_List[Idx]) -1)) + ': ';
    Ass := lower(Copy(SP_Ass_List[Idx], Pos(#255, SP_Ass_List[Idx]) +1, Length(SP_Ass_List[Idx])));
    If Copy(Ass, Length(Ass) , 1) <> '/' Then
      Ass := Ass + '/';
    Output := Output + Ass + #13;
    Inc(Idx);
  End;

  Inc(SP_StackPtr);
  SP_StackPtr^.OpType := SP_STRING;
  SP_StackPtr^.Str := Output + #13;
  SP_Interpret_PRINT(Info);

End;

Procedure SP_Interpret_PACKAGE_NEW(Var Info: pSP_iInfo);
Var
  Filename: aString;
Begin

  If PackageIsOpen Then
    SP_ClosePackage;

  If SP_FileExists(Filename) Then Begin

    Info^.Error^.Code := SP_ERR_PACKAGE_NOT_OPEN;
    Dec(SP_StackPtr);

  End Else Begin

    Filename := SP_StackPtr^.Str;
    Dec(SP_StackPtr);

    SP_CreatePackage(Filename, Info^.Error^);

  End;

End;

Procedure SP_Interpret_ASSIGN(Var Info: pSP_iInfo);
Var
  Ass, Path: aString;
Begin

  Ass := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  Path := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  SP_SetAssign(Ass, Path, Info^.Error^);

End;

Procedure SP_Interpret_COPY(Var Info: pSP_iInfo);
Var
  FileSpec, Dest: aString;
  Over: Boolean;
Begin

  FileSpec := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  Dest := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  Over := SP_StackPtr^.Val <> 0;
  Dec(SP_StackPtr);

  SP_CopyFiles(FileSpec, Dest, Over, Info^.Error^);

End;

Procedure SP_Interpret_MOVE_FILES(Var Info: pSP_iInfo);
Var
  FileSpec, Dest: aString;
  Over: Boolean;
Begin

  FileSpec := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  Dest := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  Over := SP_StackPtr^.Val <> 0;
  Dec(SP_StackPtr);

  SP_MoveFiles(FileSpec, Dest, Over, Info^.Error^);

End;

Procedure SP_Interpret_MAKEDIR(Var Info: pSP_iInfo);
Var
  Dir: aString;
Begin

  Dir := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  SP_MakeDir(Dir, Info^.Error^);

End;

Procedure SP_Interpret_RENAME(Var Info: pSP_iInfo);
Var
  SrcFiles, DstFiles: aString;
Begin

  SrcFiles := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  DstFiles := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  SP_RenameFiles(SrcFiles, DstFiles, Info^.Error^);

End;

Procedure SP_Interpret_PACK_ADD(Var Info: pSP_iInfo);
Begin

  SP_PackageAddFile(SP_StackPtr^.Str, Info^.Error^);
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_PACK_CLOSE(Var Info: pSP_iInfo);
Begin

  If PackageIsOpen Then
    SP_ClosePackage
  Else
    Info^.Error^.Code := SP_ERR_PACKAGE_NOT_OPEN;

End;

Procedure SP_Interpret_PACK_PROTECT(Var Info: pSP_iInfo);
Begin

  If PackageIsOpen Then
    SP_ProtectPackage
  Else
    Info^.Error^.Code := SP_ERR_PACKAGE_NOT_OPEN;

End;

Procedure SP_Interpret_PACK_UNPROTECT(Var Info: pSP_iInfo);
Begin

  If PackageIsOpen Then
    SP_UnProtectPackage
  Else
    Info^.Error^.Code := SP_ERR_PACKAGE_NOT_OPEN;

End;

Procedure SP_Interpret_PACKAGE(Var Info: pSP_iInfo);
Var
  Filename: aString;
Begin

  If PackageIsOpen Then
    SP_ClosePackage;

  ERRStr := Filename;
  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  If SP_FileExists(Filename) Then

    SP_CreatePackage(Filename, Info^.Error^)

  Else Begin

    Info^.Error^.Code := SP_ERR_FILE_MISSING;
    Dec(SP_StackPtr);

  End;

End;

Procedure SP_Interpret_DATA_SAVE(Var Info: pSP_iInfo);
Var
  Filename, VarName: aString;
  IsArray: Boolean;
Begin

  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  VarName := SP_StackPtr^.Str;
  If SP_StackPtr^.OpType = SP_STRVAR Then
    VarName := VarName + '$';
  Dec(SP_StackPtr);

  IsArray := SP_StackPtr^.Val = 1;
  Dec(SP_StackPtr);

  SP_SaveVar(Filename, VarName, IsArray, Info^.Error^);

End;

Procedure SP_Interpret_DATA_LOAD(Var Info: pSP_iInfo);
Var
  Filename, VarName: aString;
Begin

  Filename := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  VarName := SP_StackPtr^.Str;
  If VarName <> '' Then
    If SP_StackPtr^.OpType = SP_STRVAR Then
      VarName := VarName + '$';
  Dec(SP_StackPtr);

  SP_LoadVar(Filename, VarName, Info^.Error^);

End;

Procedure SP_Interpret_MERGE_LINES(Var Info: pSP_iInfo);
Var
  Start, Finish: Integer;
Begin

  Start := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Finish := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  DoAutoSave;

  SP_FPMergeLines(Start, Finish, Info^.Error^);

End;

Procedure SP_Interpret_GRAPHIC_ROLL(Var Info: pSP_iInfo);
Var
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
  Id, Idx, dX, dY: Integer;
Begin

  dY := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  dX := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @Bank^.Info[0];
      If dY <> 0 Then SP_VScroll(Gfx.Data, Gfx.Width, Gfx.Height, dY, True);
      If dX <> 0 Then SP_HScroll(Gfx.Data, Gfx.Width, Gfx.Height, Gfx.Depth, dX, True);

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_GRAPHIC_SCROLL(Var Info: pSP_iInfo);
Var
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
  Id, Idx, dX, dY: Integer;
Begin

  dY := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  dX := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @Bank^.Info[0];
      If dY <> 0 Then SP_VScroll(Gfx.Data, Gfx.Width, Gfx.Height, dY, False);
      If dX <> 0 Then SP_HScroll(Gfx.Data, Gfx.Width, Gfx.Height, Gfx.Depth, dX, False);

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_TILEMAP_NEW(Var Info: pSP_iInfo);
Var
  MapWidth, MapHeight, TileWidth, TileHeight: Integer;
  GraphicIsString: Boolean;
  GraphicID: Integer;
  GraphicString: aString;
Begin

  GraphicID := -1;
  MapWidth := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  MapHeight := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_VALUE Then Begin

    GraphicIsString := False;
    GraphicID := Round(SP_StackPtr^.Val);

  End Else Begin

    GraphicIsString := True;
    GraphicString := SP_StackPtr^.Str;

  End;
  Dec(SP_StackPtr);

  TileWidth := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  TileHeight := Round(SP_StackPtr^.Val);

  If GraphicIsString Then
    SP_StackPtr^.Val := SP_New_TileMap_FromString(GraphicString, MapWidth, MapHeight, TileWidth, TileHeight, Info^.Error^)
  Else
    SP_StackPtr^.Val := SP_New_TileMap_FromBank(GraphicID, MapWidth, MapHeight, TileWidth, TileHeight, Info^.Error^);

End;

Procedure SP_Interpret_TILEMAP_DRAW(Var Info: pSP_iInfo);
Var
  ToX, ToY: aFloat;
  TileMapID, OffX, OffY, ToW, ToH, Rx, Ry: Integer;
  Rotate, Scale: aFloat;
Begin

  TileMapID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  OffX := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  OffY := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  RX := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  RY := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Rotate := SP_StackPtr^.Val;
  SP_AngleToRad(Rotate);
  Dec(SP_StackPtr);

  Scale  := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  ToX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  ToY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_ConvertToOrigin_d(ToX, ToY);

  ToW := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  ToH := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_TileMap_Draw(TileMapID, OffX, OffY, Round(ToX), Round(ToY), ToW, ToH, Rx, Ry, Rotate, Scale, Info^.Error^);

End;

Procedure SP_Interpret_TILEMAP_SET(Var Info: pSP_iInfo);
Var
  TileMapID, X, Y, Tile: Integer;
Begin

  TileMapID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  X := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Y := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Tile := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_TileMap_Set(TileMapID, X, Y, Tile, Info^.Error^);

End;

Procedure SP_Interpret_TILEMAP_GRAPHIC(Var Info: pSP_iInfo);
Var
  TileMapID, GraphicID, TileW, TileH: Integer;
  Graphic: aString;
Begin

  TileMapID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_VALUE Then Begin

    GraphicID := Round(SP_StackPtr^.Val);
    TileW := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    TileH := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    SP_Tilemap_GraphicBank(TileMapID, GraphicID, TileW, TileH, Info^.Error^);

  End Else Begin

    Graphic := SP_StackPtr^.Str;
    TileW := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    TileH := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    SP_TileMap_GraphicString(TileMapID, TileW, TileH, Graphic, Info^.Error^);

  End;

End;

Procedure SP_Interpret_TILEMAP_CLEAR(Var Info: pSP_iInfo);
Begin

  SP_Tilemap_Clear(Round(SP_StackPtr^.Val), Info^.Error^);
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_DEF_STRUCT(Var Info: pSP_iInfo);
Var
  DefValue: aFloat;
  stName, mName, DefString: aString;
  StructureID, Fix: Integer;
Begin

  // Pick up the structure name

  stName := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  // Loop to pick up structure members. A string may be followed by a value, which will be the fixed-width of the string.
  // A value following a numeric type is a default value, as is a string following a string type.

  StructureID := SP_NewStruct(stName);
  With Structures[StructureID] Do
    While SP_StackPtr <> SP_StackStart Do Begin
      Case SP_StackPtr^.OpType of
        SP_NUMVAR:
          Begin
            mName := SP_StackPtr^.Str;
            Dec(SP_StackPtr);
            If NativeUInt(SP_StackPtr) >= NativeUInt(SP_StackStart) + SizeOf(SP_StackItem) Then Begin
              If SP_StackPtr^.OpType = SP_VALUE Then Begin
                DefValue := SP_StackPtr^.Val;
                Dec(SP_StackPtr);
              End Else
                DefValue := 0;
            End Else
              DefValue := 0;
            SP_AddStructMember(StructureID, mName, 0, SP_NUMVAR, '', DefValue);
          End;
        SP_STRVAR:
          Begin
            mName := SP_StackPtr^.Str;
            Fix := 0;
            Dec(SP_StackPtr);
            If NativeUInt(SP_StackPtr) >= NativeUInt(SP_StackStart) + SizeOf(SP_StackItem) Then Begin
              If SP_StackPtr^.OpType = SP_VALUE Then Begin
                Fix := Round(SP_StackPtr^.Val);
                Dec(SP_StackPtr);
              End;
            End;
            If NativeUInt(SP_StackPtr) >= NativeUInt(SP_StackStart) + SizeOf(SP_StackItem) Then Begin
              If SP_StackPtr^.OpType = SP_STRING Then Begin
                DefString := SP_StackPtr^.Str;
                Dec(SP_StackPtr);
              End Else
                DefString := '';
            End Else
              DefString := '';
            SP_AddStructMember(StructureID, mName, Fix, SP_STRVAR, DefString, 0);
          End;
      End;
  End;

End;

Procedure SP_Interpret_LIST_STRUCT(Var Info: pSP_iInfo);
Var
  Idx, mIdx, NumIndices: Integer;
  Output, ArrayStr, Indices, Key: aString;
  StrPtr: pSP_StrVarContent;
Begin

  // No parameters? List all structs
  // Parameter is numvar? List members of that struct
  // Parameter is strvar/strarray - list values in that var.

  Output := '';

  If SP_StackPtr = SP_StackStart Then Begin

    If Length(Structures) = 0 Then
      Output := 'No structures defined'#13
    Else
      For Idx := 0 To Length(Structures) -1 Do Begin
        Output := Output + Structures[Idx].Name+'(';
        For mIdx := 0 To Length(Structures[Idx].Members) -1 Do Begin
          Output := Output + Structures[Idx].Members[mIdx].mName;
          If Structures[Idx].Members[mIdx].mType = SP_NUMVAR Then Begin
            If Structures[Idx].Members[mIdx].dValue <> 0 Then
              Output := Output + '=' + aString(aFloatToStr(Structures[Idx].Members[mIdx].dValue));
          End Else Begin
            If Structures[Idx].Members[mIdx].mFix <> 0 Then
              Output := Output + '[' + IntToString(Structures[Idx].Members[mIdx].mFix) + ']';
            If Structures[Idx].Members[mIdx].dString <> '' Then
              Output := Output + '=' + Structures[Idx].Members[mIdx].dString;
          End;
          If mIdx < Length(Structures[Idx].Members) -1 Then
            Output := Output + ',';
        End;
        Output := Output + ')'+#13;
      End;

  End Else Begin

    If SP_StackPtr^.OpType = SP_NUMVAR Then Begin

      Idx := SP_FindStruct(SP_StackPtr^.Str);
      If Idx > -1 Then Begin
        Output := Output + Structures[Idx].Name+'(';
        For mIdx := 0 To Length(Structures[Idx].Members) -1 Do Begin
          Output := Output + Structures[Idx].Members[mIdx].mName;
          If Structures[Idx].Members[mIdx].mType = SP_NUMVAR Then Begin
            If Structures[Idx].Members[mIdx].dValue <> 0 Then
              Output := Output + '=' + aString(aFloatToStr(Structures[Idx].Members[mIdx].dValue));
          End Else Begin
            If Structures[Idx].Members[mIdx].mFix <> 0 Then
              Output := Output + '[' + IntToString(Structures[Idx].Members[mIdx].mFix) + ']';
            If Structures[Idx].Members[mIdx].dString <> '' Then
              Output := Output + '=' + Structures[Idx].Members[mIdx].dString;
          End;
          If mIdx < Length(Structures[Idx].Members) -1 Then
            Output := Output + ',';
        End;
        Output := Output + ')'+#13;
      End Else Begin
        ERRStr := SP_StackPtr^.Str;
        Info^.Error^.Code := SP_ERR_STRUCT_NOT_FOUND;
        Exit;
      End;

      Dec(SP_StackPtr);

    End Else Begin

      // This is a stringvar, so might be either a simple string or an array, depending on parameters.

      With SP_StackPtr^ Do Begin

        If OpType = SP_STRVAR Then Begin

          If SP_FindStrVar(Str) = -1 Then Begin
            Info^.Error^.Code := SP_ERR_MISSING_VAR;
            Exit;
          End;
          StrPtr := SP_GetStrVarPtr(Round(Val), Str, Info^.Error^, Ptr);
          ArrayStr := '';
          If Info^.Error^.Code <> SP_ERR_OK Then
            Exit;

        End Else Begin

          // An array!

          NumIndices := Round(SP_StackPtr^.Val);
          Dec(SP_StackPtr);

          Indices := '';
          ArrayStr := '(';
          For Idx := 1 To NumIndices Do Begin
            Indices := Indices + LongWordToString(Round(SP_StackPtr^.Val));
            ArrayStr := ArrayStr + IntToString(Round(SP_StackPtr^.Val));
            Dec(SP_StackPtr);
          End;
          ArrayStr := ArrayStr + ')';

          // Now the last item will be the stringvar itself.

          Key := '';
          With SP_StackPtr^ Do Begin
            StrPtr := SP_GetStrArrayPtr(Round(Val), Str, Indices, Key, Info^.Error^);
            If Info^.Error^.Code <> SP_ERR_OK Then
              Exit;
          End;

        End;

      End;

      If StrPtr^.StructName <> '' Then Begin
        Output := Output + SP_StackPtr^.Str + '$' + ArrayStr + '=' + StrPtr^.StructName + '(';
        Idx := SP_FindStruct(StrPtr^.StructName);
        For mIdx := 0 To Length(Structures[Idx].Members) -1 Do Begin
          Output := Output + Structures[Idx].Members[mIdx].mName;
          If Structures[Idx].Members[mIdx].mType = SP_NUMVAR Then
            Output := Output + '=' + aString(aFloatToStr(SP_GetStructMemberN(StrPtr, Structures[Idx].Members[mIdx].mName, Info^.Error^)))
          Else begin
            If Structures[Idx].Members[mIdx].mFix <> 0 Then
              Output := Output + '[' + IntToString(Structures[Idx].Members[mIdx].mFix) + ']';
            Output := Output + '=' + SP_GetStructMemberS(StrPtr, Structures[Idx].Members[mIdx].mName, Info^.Error^);
          End;
          If mIdx < Length(Structures[Idx].Members) -1 Then
            Output := Output + ',';
        End;
        Output := Output + ')' + #13;
      End Else Begin
        Info^.Error^.Code := SP_ERR_MISSING_STRUCT;
        Exit;
      End;

      Dec(SP_StackPtr);

    End;

  End;

  Inc(SP_StackPtr);
  With SP_StackPtr^ Do Begin
    OpType := SP_STRING;
    Str := Output;
  End;

  SP_Interpret_PRINT(Info);


End;

Procedure SP_Interpret_STRUCT_ERASE(Var Info: pSP_iInfo);
Var
  stName: aString;
Begin

  // Pick up the structure name

  stName := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  SP_DeleteStruct(stName, Info^.Error^);

End;

Procedure SP_Interpret_INIT_INPUT(Var Info: pSP_iInfo);
Begin

  // Set the input format to nothing, so no mask. Set colours of cursor, and finally set position to bottom-left of the screen, infinite scroll.

  INFORMAT := '';
  INPUTBACK := SP_GrabCurrentWindow;
  SP_Reset_Temp_Colours;
  If SCREENBPP = 8 Then Begin
    INPUTCSR1 := SP_Get_Nearest_Colour($FF, $FF, $FF, -1);
    INPUTCSR2 := SP_Get_Nearest_Colour($0, $0, $FF, -1);
  End Else Begin
    INPUTCSR1 := LongWord(DefaultPalette[15]);
    INPUTCSR2 := LongWord(DefaultPalette[9]);
  End;
  INPUTPOSX := PRPOSX;
  INPUTPOSY := PRPOSY;
  INPUTERRORHANDLED := False;
  INPUTERROR_RPT := False;
  PRPOSX := 0;
  PRPOSY := SCREENHEIGHT - FONTHEIGHT * T_SCALEY;
  SCROLLCNT := MAXINT;

End;

Procedure SP_Interpret_INPUT_FORMAT(Var Info: pSP_iInfo);
Var
  Idx: Integer;
Begin

  Idx := 1;
  INFORMAT := '';
  While Idx <= Length(SP_StackPtr^.Str) Do Begin
    If SP_StackPtr^.Str[Idx] <> '\' Then
      INFORMAT := INFORMAT + SP_StackPtr^.Str[Idx] + SP_StackPtr^.Str[Idx]
    Else
      If Idx < Length(SP_StackPtr^.Str) Then Begin
        INFORMAT := INFORMAT + SP_StackPtr^.Str[Idx] + SP_StackPtr^.Str[Idx +1];
        Inc(Idx);
      End Else
        INFORMAT := INFORMAT + SP_StackPtr^.Str[Idx] + SP_StackPtr^.Str[Idx];
    Inc(Idx);
  End;
  INFORMAT := INFORMAT + '**';
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_INPUT_ERROR(Var Info: pSP_iInfo);
Begin

  INPUTERRVAL := SP_StackPtr^.Val;
  INPUTERRORHANDLED := True;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_INPUT_ERR_RPT(Var Info: pSP_iInfo);
Begin

  INPUTERROR_RPT := True;
  INPUTERRORHANDLED := True;

End;

Procedure SP_Interpret_INPUT_NUM(Var Info: pSP_iInfo);
Label
  Again;
Begin

  // Call the input routine, which will return a string. Evaluate that string,
  // as for VAL, and place the result on the stack. There will be a variable assignment
  // along in a mo which will take care of the rest.

  If PRPOSY + (FONTHEIGHT * T_SCALEY) >= SCREENHEIGHT Then
    PRPOSY := SCREENHEIGHT - (FONTHEIGHT * T_SCALEY);

  With Info^ Do Begin
    INPUTLINE := '';
    Again:
    If SP_GetInput(Error^) Then Begin
      If StripSpaces(INPUTLINE) = '' Then Goto Again;
      Inc(SP_StackPtr);
      With SP_StackPtr^ Do Begin
        OpType := SP_STRING;
        Str := INPUTLINE;
      End;
      SP_Interpret_FN_VAL(Info);
      If (Error.Code <> SP_ERR_OK) And INPUTERRORHANDLED Then Begin
        SP_StackPtr^.Val := INPUTERRVAL;
        SP_StackPtr^.OpType := SP_VALUE;
        Error.Code := SP_ERR_OK;
        INPUTERROR := True;
      End;
    End Else Begin
      // User cancelled the INPUT
      Inc(SP_StackPtr);
      With SP_StackPtr^ Do Begin
        OpType := SP_VALUE;
        Val := 0;
      End;
    End;

    // Clear the temporary format and error handling flags

    CURSORPOS := 1;
    INPUTERRORHANDLED := False;
    INFORMAT := '';
    PRPOSX := PRPOSX + (Length(INPUTLINE) * FONTWIDTH * T_SCALEX);
    While PRPOSX >= SCREENWIDTH Do Begin
      PRPOSY := PRPOSY - (FONTHEIGHT * T_SCALEY);
      PRPOSX := PRPOSX - SCREENWIDTH;
    End;
    INPUTLINE := '';

  End;

End;

Procedure SP_Interpret_INPUT_STR(Var Info: pSP_iInfo);
Begin

  If PRPOSY + (FONTHEIGHT * T_SCALEY) >= SCREENHEIGHT Then
    PRPOSY := SCREENHEIGHT - (FONTHEIGHT * T_SCALEY);

  INPUTLINE := '';
  If SP_GetInput(Info^.Error^) Then Begin
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_STRING;
      Str := INPUTLINE;
    End;
  End Else Begin
    // User cancelled the INPUT
    Inc(SP_StackPtr);
    With SP_StackPtr^ Do Begin
      OpType := SP_STRING;
      Str := '';
    End;
  End;

  // Clear the temporary format and error handling flags

  CURSORPOS := 1;
  INPUTERRORHANDLED := False;
  INFORMAT := '';
    PRPOSX := PRPOSX + (Length(INPUTLINE) * FONTWIDTH * T_SCALEX);
    While PRPOSX >= SCREENWIDTH Do Begin
      PRPOSY := PRPOSY - (FONTHEIGHT * T_SCALEY);
      PRPOSX := PRPOSX - SCREENWIDTH;
    End;
    INPUTLINE := '';

End;

Procedure SP_Interpret_INPUT_FINAL(Var Info: pSP_iInfo);
Begin

  SP_PutCurrentWindow(INPUTBACK);
  PRPOSX := INPUTPOSX;
  PRPOSY := INPUTPOSY;
  SCROLLCNT := 0;

End;

Procedure SP_Interpret_FOR_EACH(Var Info: pSP_iInfo);
Var
  VarIdx: Integer;
  VarName, ArrayName: aString;
  VarPtr: pLongWord;
  LineItem: TSP_GOSUB_Item;
  Step: aFloat;
Begin

  // Stack has variable, then array to use.

  With SP_StackPtr^ Do Begin

    VarIdx := Round(Val);
    VarName := Str;
    VarPtr := Ptr;
    If OpType = SP_STRVAR Then VarName := VarName + '$';
    With Info^ Do Begin
      If Error^.Line >= 0 Then Begin
        LineItem := SP_ConvertLineStatement(Error^.Line, Error^.Statement + 1);
      End Else Begin
        LineItem.Line := -2;
        LineItem.Statement := SP_FindStatement(@COMMAND_TOKENS, Error^.Statement + 1);
        LineItem.St := Error^.Statement + 1;
      End;
    End;

  End;
  Dec(SP_StackPtr);

  ArrayName := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  Step := 1;
  SP_UpdateFOREACHVar(VarIdx, VarName, ArrayName, Step, LineItem.Line, LineItem.Statement, LineItem.St, VarPtr, Info^.Error^);

End;

Procedure SP_Interpret_FOR_EACH_STRING(Var Info: pSP_iInfo);
Var
  VarIdx: Integer;
  VarName, StrContent: aString;
  VarPtr: pLongWord;
  LineItem: TSP_GOSUB_Item;
  Step: aFloat;
Begin

  // Stack has variable, then array to use.

  With SP_StackPtr^ Do Begin

    VarIdx := Round(Val);
    VarName := Str + '$';
    VarPtr := Ptr;
    With Info^ Do Begin
      If Error^.Line >= 0 Then Begin
        LineItem := SP_ConvertLineStatement(Error^.Line, Error^.Statement + 1);
      End Else Begin
        LineItem.Line := -2;
        LineItem.Statement := SP_FindStatement(@COMMAND_TOKENS, Error^.Statement + 1);
        LineItem.St := Error^.Statement + 1;
      End;
    End;

  End;
  Dec(SP_StackPtr);

  StrContent := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  Step := 1;
  SP_UpdateFOREACHVar_Str(VarIdx, VarName, StrContent, Step, LineItem.Line, LineItem.Statement, LineItem.St, VarPtr, Info^.Error^);

End;

Procedure SP_Interpret_FOR_EACH_RANGE(Var Info: pSP_iInfo);
Var
  VarIdx, NumRanges: Integer;
  VarName, EachString: aString;
  VarPtr: pLongWord;
  LineItem: TSP_GOSUB_Item;
Begin

  // At this point, a string and a number should be on the stack. We set up the variable to be used, along with the EACHSTRING which holds this string.
  // Then assign its EACHPTR to point to the first character in the string. We use this to interpret! Bit of a juggling act, but it should
  // work well.

  // The number denotes how many ranges there are in this string.

  With SP_StackPtr^ Do Begin

    VarIdx := Round(Val);
    VarName := Str;
    VarPtr := Ptr;
    With Info^ Do Begin
      If OpType = SP_STRVAR Then VarName := VarName + '$';
      If Error^.Line >= 0 Then Begin
        LineItem := SP_ConvertLineStatement(Error^.Line, Error^.Statement + 1);
      End Else Begin
        LineItem.Line := -2;
        LineItem.Statement := SP_FindStatement(@COMMAND_TOKENS, Error^.Statement + 1);
        LineItem.St := Error^.Statement + 1;
      End;
    End;

  End;
  Dec(SP_StackPtr);

  NumRanges := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  EachString := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  SP_UpdateFOREACHRANGEVar(VarIdx, VarName, EachString, NumRanges, LineItem.Line, LineItem.Statement, LineItem.St, VarPtr, Info^.Error^);

End;

Procedure SP_Interpret_MOUSE_SHOW(Var Info: pSP_iInfo);
Begin

  MOUSEVISIBLE := True;
  USERMOUSEVISIBLE := MOUSEVISIBLE;

End;

Procedure SP_Interpret_MOUSE_HIDE(Var Info: pSP_iInfo);
Begin

  DisplaySection.Enter;
  SP_RestoreMouseRegion;
  MOUSEVISIBLE := False;
  USERMOUSEVISIBLE := MOUSEVISIBLE;
  DisplaySection.Leave;

End;

Procedure SP_Interpret_MOUSE_GRAPHIC(Var Info: pSP_iInfo);
Var
  ID, X, Y: Integer;
Begin

  DisplaySection.Enter;
  SP_RestoreMouseRegion;

  X := 0; Y := 0;
  ID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  If SP_StackPtr <> SP_StackStart Then Begin
    X := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    Y := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End;
  SP_MousePointerFromGraphic(ID, X, Y, Info^.Error^);
  DisplaySection.Leave;

End;

Procedure SP_Interpret_MOUSE_GFXS(Var Info: pSP_iInfo);
Var
  X, Y: Integer;
  Gfx: aString;
Begin

  DisplaySection.Enter;
  SP_RestoreMouseRegion;

  X := 0; Y := 0;
  Gfx := SP_StackPtr^.Str;
  Dec(SP_StackPtr);
  If SP_StackPtr <> SP_StackStart Then Begin
    X := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    Y := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End;
  SP_MousePointerFromString(Gfx, X, Y);
  Dec(SP_StackPtr);
  DisplaySection.Leave;

End;

Procedure SP_Interpret_MOUSE_DEFAULT(Var Info: pSP_iInfo);
Begin

  DisplaySection.Enter;
  SP_RestoreMouseRegion;
  SP_MousePointerFromDefault;
  DisplaySection.Leave;
  //SP_StackPtr := SP_StackStart;

End;

Procedure SP_Interpret_MOUSE_TO(Var Info: pSP_iInfo);
var
  x, y: Integer;
Begin

  x := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  y := Round(SP_StackPtr^.val);
  Dec(SP_StackPtr);

  CB_MouseMove(x, y);

End;

Function GetDebugText(Tokens: aString; IntStatement: Integer; StatementSpecified: Boolean; Statements: TAnsiStringlist): aString;
Var
  Done: Boolean;
  Ps, Idx, Idx2: Integer;
  nOutput, PosStr, s: aString;
  StrPtr, StrStart: pByte;
  Token, nToken: pToken;
  i: LongWord;
Begin

  Result := '';
  Done := False;
  Tokens := Tokens + #255#255#255#255;
  StrPtr := @Tokens[1];
  StrStart := StrPtr;
  While Not Done Do begin

    Token := pToken(StrPtr);
    Inc(StrPtr, SizeOf(TToken));
    nOutput := '';

    Ps := NativeUInt(StrPtr) - NativeUInt(StrStart) + IntStatement;
    PosStr := IntToString(Ps);
    While Length(PosStr) < 8 Do
      PosStr := PosStr + ' ';

    Case Token^.Token Of

      SP_TERMINAL:
        Begin
          nOutput := '------- [END OF STATEMENT]';
          Done := True;
        End;

      SP_JZ:
        Begin
          nOutput := 'JUMP IF ZERO ['+aString(IntToString(pLongWord(StrPtr)^))+' ('+aString(IntToString(Ps + SizeOf(TToken) + Integer(pLongWord(StrPtr)^)))+') ]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_JNZ:
        Begin
          nOutput := 'JUMP IF NON-ZERO ['+aString(IntToString(pLongWord(StrPtr)^))+' ('+aString(IntToString(Ps + SizeOf(TToken) + Integer(pLongWord(StrPtr)^)))+') ]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_INCVAR:
        Begin
          nOutput := 'INC VAR ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_SHLVAR:
        Begin
          nOutput := 'SHL VAR ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_SHRVAR:
        Begin
          nOutput := 'SHR VAR ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_DECVAR:
        Begin
          nOutput := 'DEC VAR ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_MULVAR:
        Begin
          nOutput := 'MUL VAR ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_DIVVAR:
        Begin
          nOutput := 'DIV VAR ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_POWVAR:
        Begin
          nOutput := 'POW VAR ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_ANDVAR:
        Begin
          nOutput := 'AND VAR ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_MODVAR:
        Begin
          nOutput := 'MOD VAR ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_ORVAR:
        Begin
          nOutput := 'OR VAR ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_NOTVAR:
        Begin
          nOutput := 'NOT VAR ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_XORVAR:
        Begin
          nOutput := 'XOR VAR ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_JUMP:
        Begin
          nOutput := 'JUMP ['+aString(IntToString(ps + Integer(Token^.TokenLen) + SizeOf(TToken) + Integer(pLongWord(StrPtr)^)))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_COMPOUND_NNO:
        Begin
          nOutput := '[COMPOUND Var-Var-Op]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_COMPOUND_NVO:
        Begin
          nOutput := '[COMPOUND Var-Num-Op]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_COMPOUND_VNO:
        Begin
          nOutput := '[COMPOUND Num-Var-Op]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_FUNCTION_MARKER:
        Begin
          nOutput := 'FUNCTION MARKER';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_DISPLACEMENT:
        Begin
          nOutput := 'DISPLACEMENT ['+aString(aFloatToStr(gaFloat(StrPtr)))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_IJMP:
        Begin
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_CAUSEERROR:
        Begin
          nOutput := 'ERROR ['+ ErrorMessages[pLongWord(StrPtr)^] + ']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_LABEL:
        Begin
          nOutput := 'LABEL ['+ StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)), Token^.TokenLen) + ']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_RANGE, SP_RANGE_LESS, SP_RANGE_GREATER, SP_RANGE_ARRAYNUM, SP_RANGE_ARRAYSTR:
        Begin
          Case Token^.Token of
            SP_RANGE:
              nOutput := 'RANGE';
            SP_RANGE_LESS:
              nOutput := 'RANGE<';
            SP_RANGE_GREATER:
              nOutput := 'RANGE>';
            SP_RANGE_ARRAYSTR:
              nOutput := 'RANGE ARRAY$';
            SP_RANGE_ARRAYNUM:
              nOutput := 'RANGE ARRAY';
          End;
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_SKIP_STATEMENT:
        Begin
          nOutput := 'SKIP STATEMENT';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_SKIP_DATA:
        Begin
          nOutput := 'SKIP DATA';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_SKIP_LINE:
        Begin
          nOutput := 'SKIP LINE';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_DATA_ITEM:
        Begin
          nOutput := 'DATA ITEM';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_POINTER:
        Begin
          nOutput := 'POINTER ['+LongWordToString(pLongWord(StrPtr)^)+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_ARRAY_ASSIGN:
        Begin
          nOutput := 'ARRAY ASSIGN';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_SLICE_ASSIGN:
        Begin
          nOutput := 'SLICE ASSIGN [';
          Case Byte(StrPtr^) of
            0: nOutput := nOutput + 'No Slicer, ';
            1: nOutput := nOutput + 'Slice TO-Pos, ';
            2: nOutput := nOutput + 'Slice Pos-TO, ';
            3: nOutput := nOutput + 'Slice PosA-TO-PosB, ';
          End;
          If dLongWord(StrPtr +1) = 1 Then
            nOutput := nOutput + aFloatToStr(dLongWord(StrPtr +1)) + ' Index]'
          Else
            nOutput := nOutput + aFloatToStr(dLongWord(StrPtr +1)) + ' Indices]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_VALUE:
        Begin
          nOutput := 'VALUE [' + aString(aFloatToStr(gaFloat(StrPtr)))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_NUMCONST:
        Begin
          nOutput := 'CONST [' + StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) + SizeOf(aFloat) - NativeUInt(StrStart)), Token^.TokenLen - SizeOf(aFloat)) + ':' + aString(aFloatToStr(gaFloat(StrPtr)))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_STRCONST:
        Begin
          Idx2 := pLongWord(NativeUInt(StrPtr) - (SizeOf(LongWord) * 2))^;
          nOutput := 'CONST$ ['+ StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart) + Idx2), Integer(Token^.TokenLen) - Idx2) + ':"' + StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)), Idx2)+'"]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_STRING:
        Begin
          Idx := Min(Token^.TokenLen, SCREENWIDTH Div (2*FontWidth));
          s := StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)), Idx);
          nToken := pToken(NativeUInt(StrPtr) + Token^.TokenLen);
          If (nToken^.Token = SP_KEYWORD) And (pLongWord(NativeUInt(nToken)+SizeOf(TToken))^ = SP_KW_DEF_FN) Then Begin
            s := StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)), Token^.TokenLen);
            nOutput := 'STRING [FUNCTION]';
            Idx := Pos('[', nOutput);
            If Idx <> 0 Then
              If Idx < 21 Then
                For Idx2 := 1 to 21-Idx Do
                  nOutput := Copy(nOutput, 1, Idx-1) + ' ' + Copy(nOutput, Idx, Length(nOutput));
            Result := Result + #13 + PosStr + nOutput + #13;
            Result := Result + GetDebugText(s, 1, False, nil);
            nOutput := '';
            PosStr := '';
          End Else Begin
            nOutput := 'STRING ["'+s+'"';
            If Idx <> Integer(Token^.TokenLen) Then nOutput := nOutput + '...';
            nOutput := nOutput + ']';
          End;
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_NUMVAR:
        Begin
          nOutput := 'NUMVAR ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_NUMVAR_LET_VALID:
        Begin
          nOutput := 'NUMVAR LET VALID ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_NUMVAR_LET:
        Begin
          nOutput := 'NUMVAR LET ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_NUMVAR_EVAL:
        Begin
          nOutput := 'NUMVAR EVAL ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + (SizeOf(LongWord) * 2), pLongWord(StrPtr + SizeOf(LongWord))^)+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_NUMVARSQ:
        Begin
          nOutput := 'NUMVAR SQUARE ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + (SizeOf(LongWord) * 2), pLongWord(StrPtr + SizeOf(LongWord))^)+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_STRVAR:
        Begin
          nOutput := 'STRVAR ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+'$]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_STRVAR_LET_VALID:
        Begin
          nOutput := 'STRVAR LET VALID ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+'$]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_STRVAR_LET:
        Begin
          nOutput := 'STRVAR LET ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord))+'$]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_HYBRID_LET:
        Begin
          s := StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + SizeOf(LongWord), Token^.TokenLen - SizeOf(LongWord));
          s[1] := aChar(Ord(s[1]) - 128);
          nOutput := 'HYBRID LET [' + s + ']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_STRVAR_EVAL:
        Begin
          nOutput := 'STRVAR EVAL ['+StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)) + (SizeOf(LongWord) * 2), pLongWord(StrPtr + SizeOf(LongWord))^)+'$]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_STRUCT_MEMBER_N:
        Begin
          nOutput := 'STRUCT MEMBER VAL [' +StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)), Token^.TokenLen) + ']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_STRUCT_MEMBER_S:
        Begin
          nOutput := 'STRUCT MEMBER STR [' +StringCopy(@Tokens, 1 + (NativeUInt(StrPtr) - NativeUInt(StrStart)), Token^.TokenLen) + ']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_STRUCT_MEMBER_ASS:
        Begin
          nOutput := 'STRUCT MEMBER ASSIGN ['+StringCopy(@Tokens, 1 + NativeUInt(StrPtr) - NativeUInt(StrStart), Token^.TokenLen)+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_STRVARPTR: // For structure members to be attached to :)
        Begin
          nOutput := 'GET STR VAR POINTER ['+StringCopy(@Tokens, NativeUInt(StrPtr) - NativeUInt(Strstart) + SizeOf(longWord) +1, pLongWord(NativeUInt(StrPtr) - SizeOf(longWord))^ - SizeOf(LongWord))+'$]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_NUM_ARRAY_PTR: // Evaluates and places on the stack a pointer to an array element's value
        Begin
          nOutput := 'ARRAY PTR [Expect '+IntToString(pLongWord(StrPtr)^)+' Indices]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_ARRAY: // Evaluates and places on the stack an array element.
        Begin
          nOutput := 'ARRAY EVAL [Expect '+IntToString(pLongWord(StrPtr)^)+' Indices]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_SLICER: // Evaluates and stacks a string after processing by the slicer
        Begin
          nOutput := 'SLICE STRING';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_SPECIAL_SYMBOL:
        Begin
          Case aChar(StrPtr^) Of
            SP_CHAR_UNARYM:
              Begin
                nOutput := 'OPERATOR [UNARY NEG]';
              End;
            SP_CHAR_UNARYP:
              Begin
                nOutput := 'OPERATOR [UNARY POS]';
              End;
          End;
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_SYMBOL:
        Begin
          Case aChar(StrPtr^) Of
            SP_CHAR_STR_MUL1, SP_CHAR_STR_MUL2:
              Begin
                nOutput := 'OPERATOR [STRING MUL]';
              End;
            SP_CHAR_INT_PLUS, SP_CHAR_ADD:
              Begin
                nOutput := 'OPERATOR [INTEGER +]';
              End;
            SP_CHAR_SUB:
              Begin
                nOutput := 'OPERATOR [INTEGER -]';
              End;
            SP_CHAR_MUL:
              Begin
                nOutput := 'OPERATOR [INTEGER *]';
              End;
            SP_CHAR_DIV:
              Begin
                nOutput := 'OPERATOR [INTEGER /]';
              End;
            SP_CHAR_NUM_PLUS:
              Begin
                nOutput := 'OPERATOR [NUMERIC +]';
              End;
            SP_CHAR_STR_PLUS:
              Begin
                nOutput := 'OPERATOR [STRING +]';
              End;
            SP_CHAR_NUM_EQU:
              Begin
                nOutput := 'OPERATOR [NUMERIC =]';
              End;
            SP_CHAR_STR_EQU:
              Begin
                nOutput := 'OPERATOR [STRING =]';
              End;
            SP_CHAR_NUM_LES:
              Begin
                nOutput := 'OPERATOR [NUMERIC <]';
              End;
            SP_CHAR_STR_LES:
              Begin
                nOutput := 'OPERATOR [STRING <]';
              End;
            SP_CHAR_NUM_LTE:
              Begin
                nOutput := 'OPERATOR [NUMERIC <=]';
              End;
            SP_CHAR_STR_LTE:
              Begin
                nOutput := 'OPERATOR [STRING <=]';
              End;
            SP_CHAR_NUM_DNE:
              Begin
                nOutput := 'OPERATOR [NUMERIC <>]';
              End;
            SP_CHAR_STR_DNE:
              Begin
                nOutput := 'OPERATOR [STRING <>]';
              End;
            SP_CHAR_NUM_GTE:
              Begin
                nOutput := 'OPERATOR [NUMERIC >=]';
              End;
            SP_CHAR_STR_GTE:
              Begin
                nOutput := 'OPERATOR [STRING >=]';
              End;
            SP_CHAR_NUM_GTR:
              Begin
                nOutput := 'OPERATOR [NUMERIC >]';
              End;
            SP_CHAR_STR_GTR:
              Begin
                nOutput := 'OPERATOR [STRING >]';
              End;
            '+':
              Begin
                nOutput := 'OPERATOR [+]';
              End;
            '-':
              Begin
                nOutput := 'OPERATOR [-]';
              End;
            '*':
              Begin
                nOutput := 'OPERATOR [*]';
              End;
            '/':
              Begin
                nOutput := 'OPERATOR [/]';
              End;
            '^':
              Begin
                nOutput := 'OPERATOR [^]';
              End;
            ':':
              Begin
                If StatementSpecified Then Begin
                  nOutput := '[END OF STATEMENT]';
                  Done := True
                End Else Begin
                  If Statements.Count > 0 Then Begin
                    nOutput := #13+aString(Statements[0]);
                    PosStr := '';
                    Statements.Delete(0);
                  End;
                End;
              End;
            '=':
              Begin
                nOutput := 'OPERATOR [=]';
              End;
            '>':
              Begin
                nOutput := 'OPERATOR [>]';
              End;
            '<':
              Begin
                nOutput := 'OPERATOR [<]';
              End;
            SP_CHAR_GTE:
              Begin
                nOutput := 'OPERATOR [>=]';
              End;
            SP_CHAR_LTE:
              Begin
                nOutput := 'OPERATOR [<=]';
              End;
            SP_CHAR_DNE:
              Begin
                nOutput := 'OPERATOR [<>]';
              End;
            SP_CHAR_NUM_AND:
              Begin
                nOutput := 'OPERATOR [NUMERIC AND]';
              End;
            SP_CHAR_STR_AND:
              Begin
                nOutput := 'OPERATOR [STRING AND]';
              End;
            SP_CHAR_AND:
              Begin
                nOutput := 'OPERATOR [AND]';
              End;
            SP_CHAR_OR:
              Begin
                nOutput := 'OPERATOR [OR]';
              End;
            SP_CHAR_EQV:
              Begin
                nOutput := 'OPERATOR [EQV]';
              End;
            SP_CHAR_IMP:
              Begin
                nOutput := 'OPERATOR [IMP]';
              End;
            SP_CHAR_MOD:
              Begin
                nOutput := 'OPERATOR [MOD]';
              End;
            SP_CHAR_FMOD:
              Begin
                nOutput := 'OPERATOR [FMOD]';
              End;
            SP_CHAR_XOR:
              Begin
                nOutput := 'OPERATOR [XOR]';
              End;
            SP_CHAR_SHL:
              Begin
                nOutput := 'OPERATOR [SHL]';
              End;
            SP_CHAR_SHR:
              Begin
                nOutput := 'OPERATOR [SHR]';
              End;
            SP_CHAR_NOT:
              Begin
                nOutput := 'OPERATOR [NOT]';
              End;
            '|':
              Begin
                nOutput := 'OPERATOR [| (Bitwise OR)]';
              End;
            '&':
              Begin
                nOutput := 'OPERATOR [& (Bitwise AND)]';
              End;
            SP_CHAR_BITWISE_NOT:
              Begin
                nOutput := 'OPERATOR [! (Bitwise NOT)]';
              End;
            SP_CHAR_STRING_NOT:
              Begin
                nOutput := 'OPERATOR [! (Bitwise string NOT)]';
              End;
            SP_CHAR_INCVAR:
              Begin
                nOutput := 'OPERATOR [Increment and Assign]';
              End;
            SP_CHAR_DECVAR:
              Begin
                nOutput := 'OPERATOR [Decrement and Assign]';
              End;
            SP_CHAR_MULVAR:
              Begin
                nOutput := 'OPERATOR [Multiply and Assign]';
              End;
            SP_CHAR_DIVVAR:
              Begin
                nOutput := 'OPERATOR [Divide and Assign]';
              End;
            SP_CHAR_POWVAR:
              Begin
                nOutput := 'OPERATOR [Raise and Assign]';
              End;
            SP_CHAR_MODVAR:
              Begin
                nOutput := 'OPERATOR [Modulus and Assign]';
              End;
            SP_CHAR_ANDVAR:
              Begin
                nOutput := 'OPERATOR [Bitwise AND and Assign]';
              End;
            SP_CHAR_XORVAR:
              Begin
                nOutput := 'OPERATOR [XOR and Assign]';
              End;
            SP_CHAR_ORVAR:
              Begin
                nOutput := 'OPERATOR [Bitwise OR and Assign]';
              End;
            SP_CHAR_NOTVAR:
              Begin
                nOutput := 'OPERATOR [NOT and Assign]';
              End;
            SP_CHAR_SHLVAR:
              Begin
                nOutput := 'OPERATOR [SHL and Assign]';
              End;
            SP_CHAR_SHRVAR:
              Begin
                nOutput := 'OPERATOR [SHR and Assign]';
              End;
          Else
            nOutput := aString('SYMBOL [')+aChar(StrPtr^)+aString(']');
          End;
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_BLOCK_OPT:
        Begin
          nOutput := '[BLOCK OPT]';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_KEYWORD:
        Begin
          If pLongWord(StrPtr)^ < 4000 Then
            nOutput := 'KEYWORD ['+SP_Keywords[pLongWord(StrPtr)^ - 1000]+']'
          Else
            If Integer(pLongWord(StrPtr)^ - 4051) > Length(SP_KeyWord_Names) Then Begin
              nOutput := 'INVALID KEYWORD';
              Done := True;
            End Else
              nOutput := 'KEYWORD ['+SP_Keyword_Names[pLongWord(StrPtr)^ - 4051]+']';
          If (pLongWord(StrPtr)^ = SP_KW_GOTOC) or (pLongWord(StrPtr)^ = SP_KW_GOSUBC) Then
            nOutput := Copy(nOutput, 1, Length(nOutput) -1) + ':' + IntToString(pLongWord(NativeUInt(StrPtr)+(SizeOf(LongWord)*2))^) + ']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_FUNCTION:
        Begin
          i := pLongWord(StrPtr)^;
          If i >= SP_META_BASE Then
            nOutput := 'FUNCTION ['+SP_Function_Names[i - 3000]+']'
          Else
            nOutput := 'FUNCTION ['+SP_Functions[i - 2000]+']';
          Inc(StrPtr, Token^.TokenLen);
        End;

      SP_RESTORECOLOURS:
        Begin
          nOutput := '[RESTORE TEMP COLOURS]';
        End;

    Else
      Begin
        nOutput := 'INVALID OPCODE';
        Done := True;
      End;

    End;

    Idx := Pos('[', nOutput);
    If Idx <> 0 Then
      If Idx < 21 Then
        For Idx2 := 1 to 21-Idx Do
          nOutput := Copy(nOutput, 1, Idx-1) + ' ' + Copy(nOutput, Idx, Length(nOutput));
    Result := Result + PosStr + nOutput{ + IntToString(Token^.BPIndex)} + #13;

  End;


End;

Procedure SP_Interpret_DEBUG(Var Info: pSP_iInfo);
Var
  LineNum, StatementNum, Idx, StCount, StStart, intLine, intStatement, nxtStatement, MinStatement, MaxStatement: Integer;
  Output, LineText, Tokens: aString;
  StatementSpecified: Boolean;
  Statements: TAnsiStringlist;
Label
  NextStatement;
Begin

  // Decompose a tokenised line into a list of human-readable RPN instructions

  // Get the line and optional statement number

  Statements := TAnsiStringlist.Create;
  StatementSpecified := False;
  LineNum := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  If SP_StackPtr <> SP_StackStart Then Begin
    StatementSpecified := True;
    StatementNum := Round(SP_StackPtr^.Val);
    MinStatement := StatementNum;
    MaxStatement := StatementNum;
    Dec(SP_StackPtr);
  End Else Begin
    MinStatement := 1;
    MaxStatement := 9999;
    StatementNum := 1;
  End;

  intLine := SP_FindLine(LineNum, False);
  If (intLine > INCLUDEFROM) And (Info^.Error^.Line < INCLUDEFROM) Then intLine := -1;

  If intLine <> -1 Then Begin

    LineNum := pLongWord(@SP_Program[intLine][2])^;

    While (StatementNum >= MinStatement) And (StatementNum <= MaxStatement) Do Begin

      intStatement := SP_FindStatement(@SP_Program[intLine], StatementNum);

      If intStatement <> -1 Then Begin

        Tokens := SP_Program[intLine];
        nxtStatement := SP_FindStatement(@Tokens, StatementNum +1);
        If nxtStatement = -1 Then
          Tokens := Copy(Tokens, intStatement, Length(Tokens))
        Else
          Tokens := Copy(Tokens, intStatement, nxtStatement - intStatement);

        Idx := -1;
        LineText := SP_Detokenise(SP_Program[intLine], Idx, False, False);
        Idx := 1; While LineText[Idx] in ['0'..'9', #0..#32] Do Inc(Idx);
        LineText := Copy(LineText, Idx, Length(LineText));

        Idx := 1;
        StCount := 1;

        If StatementNum > 1 Then Begin
          While Idx < Length(LineText) Do Begin
            If LineText[Idx] = ':' Then Begin
              Inc(StCount);
              If StCount = StatementNum Then Begin
                StStart := Idx;
                While LineText[StStart] in [':', ' '] Do
                  Inc(StStart);
                Break;
              End;
            End;
            Inc(Idx);
          End;
        End;

        Inc(Idx);
        While Idx < Length(LineText) Do Begin
          If LineText[Idx] = ':' Then
            Break;
          Inc(Idx);
        End;

        Output := IntToString(LineNum) + ':' + IntToString(StatementNum);
        If StatementNum = 1 Then Output := Output + ' ' + LineText;

        Inc(SP_StackPtr);
        With SP_StackPtr^ Do Begin
          OpType := SP_STRING;
          Str := Output + #13;
        End;

        SP_Interpret_PRINT(Info);

        Output := GetDebugText(Tokens, IntStatement, StatementSpecified, Statements);

        Inc(SP_StackPtr);
        With SP_StackPtr^ Do Begin
          OpType := SP_STRING;
          Str := Output + #13#13;
        End;

        SP_Interpret_PRINT(Info);
        Inc(StatementNum);

      End Else Begin

        Break;

      End;

    End;

  End Else

    Info^.Error^.Code := SP_ERR_LINE_NOT_FOUND;

  Statements.Free;

End;

Procedure SP_Interpret_FPS(Var Info: pSP_iInfo);
Var
  Val: aFloat;
Begin

  Val := SP_StackPtr^.Val;
  If (Val >= 25) And (Val <= 9999) Then Begin
    SP_SetFPS(Val);
  End Else
    Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_PUSH(Var Info: pSP_iInfo);
Var
  LineNum, StatementNum, intLine, intStatement: Integer;
  LineItem: TSP_GOSUB_Item;
Begin

  LineNum := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  If SP_StackPtr <> SP_StackStart Then Begin
    StatementNum := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End Else
    StatementNum := 1;

  intLine := SP_FindLine(LineNum, False);
  If (intLine > INCLUDEFROM) And (Info^.Error^.Line < INCLUDEFROM) Then intLine := -1;

  If intLine <> -1 Then Begin

    intStatement := SP_FindStatement(@SP_Program[intLine], StatementNum);
    If intStatement <> -1 Then Begin

      LineItem := SP_ConvertLineStatement(intLine, StatementNum);
      SP_StackLine(LineItem.Line, LineItem.Statement, LineItem.St, SP_KW_GOSUB, Info^.Error^);

    End Else

      Info^.Error^.Code := SP_ERR_STATEMENT_OUT_OF_REACH;

  End Else

    Info^.Error^.Code := SP_ERR_LINE_NOT_FOUND;

End;

Procedure SP_Interpret_SETNUB(Var Info: pSP_iInfo);
Var
  NubID, Mode: Integer;
  NubFile: THandle;
Const
  NubFiles: Array[0..1] of aString = ('/proc/pandora/nub0/mode', '/proc/pandora/nub1/mode');
  NubModes: Array[0..3] of aString = ('mouse', 'absolute', 'scroll', 'mbuttons');
Begin

  {$IFNDEF PANDORA}
  Info^.Error^.Code := SP_ERR_INVALID_HARDWARE;
  Exit;
  {$ENDIF}

  NubID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Mode := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If (NubID < 1) or (NubID > 2) Then

    Info^.Error^.Code := SP_ERR_INVALID_NUB

  Else Begin

    If (Mode < 0) or (Mode > 3) Then

      Info^.Error^.Code := SP_ERR_INVALID_NUB_MODE

    Else Begin

      CB_ReleaseSticks;

      NubFile := FileCreate(String(NubFiles[NubID -1]), fmOpenWrite);
      FileWrite(NubFile, NubModes[Mode][1], Length(NubModes[Mode]));
      FileClose(NubFile);

      If NubID = 1 Then
        NUBMODE1 := Mode
      Else
        NUBMODE2 := Mode;

      CB_InitSticks;

    End;

  End;

End;

Procedure SP_Interpret_SETCPU(Var Info: pSP_iInfo);
Var
  Speed: Integer;
  SpeedStr: aString;
//  CpuFile: THandle;
Begin

  {$IFNDEF PANDORA}
  Info^.Error^.Code := SP_ERR_INVALID_HARDWARE;
  Exit;
  {$ENDIF}

  Speed := Round(SP_StackPtr^.Val);
  SpeedStr := IntToString(Speed);
  Dec(SP_StackPtr);

  {$IFDEF PANDORA}
  SysUtils.ExecuteProcess('sudo', '-n /usr/pandora/scripts/op_cpuspeed.sh ' + SpeedStr, []);
  {$ENDIF}

  {
  CpuFile := FileCreate('/proc/pandora/cpu_mhz_max', fmOpenWrite);
  FileWrite(CpuFile, SpeedStr[1], Length(SpeedStr));
  FileClose(CpuFile);
  }

End;

Procedure SP_Interpret_MULTIPLOT(Var Info: pSP_iInfo);
Var
  VarName: aString;
  dX, dY: aFloat;
  Idx, iSize, vIdx, pIdx: Integer;
Begin

  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    Dec(SP_StackPtr);
    Idx := 0;
    While Idx < Length(NumArrays) Do Begin
      If NumArrays[Idx].Name = VarName Then Begin
        If NumArrays[Idx].NumIndices = 2 Then Begin
          iSize := NumArrays[Idx].Indices[1];
          If iSize = 2 Then Begin
            vIdx := 0;
            For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
              dX := NumArrays[Idx].Values[vIdx]^.Value;
              dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
              Inc(vIdx, iSize);
              SP_ConvertToOrigin_d(dX, dY);
              If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;
              If SCREENBPP = 8 Then
                SP_SetPixel(dX, dY)
              Else
                SP_SetPixel32(dX, dY);
            End;
            Exit;
          End Else
            If iSize >= 3 Then Begin
              vIdx := 0;
              For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
                dX := NumArrays[Idx].Values[vIdx]^.Value;
                dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
                T_INK := Round(NumArrays[Idx].Values[vIdx + 2]^.Value);
                Inc(vIdx, iSize);
                SP_ConvertToOrigin_d(dX, dY);
                If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;
                If SCREENBPP = 8 Then
                  SP_SetPixel(dX, dY)
                Else
                  SP_SetPixel32(dX, dY);
              End;
              Exit;
            End Else
              Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
        End Else
          Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
      End;
      Inc(Idx);
    End;
    ERRStr := VarName;
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
  End Else
    Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

End;

Procedure SP_Interpret_TRANSFORM3D(Var Info: pSP_iInfo);
Var
  Idx, pIdx, sIdx, dIdx, vIdx, valCount, numTransforms, numPoints, iSize: Integer;
  dX, dY, dZ, xCos, yCos, zCos, xSin, ySin, zSin, pX, pY, pZ, y1, z1, x2, z2, x3, y3: aFloat;
  VarName: aString;
  KeyWordID: LongWord;
Begin

  // TRANSFORM3D - pick up src and optional destination, then commands - ID,x,y,z
  // Get Source array. Must be suitable.

  sIdx := -1;
  valCount := 0;
  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    Dec(SP_StackPtr);
    Idx := 0;
    While Idx < Length(NumArrays) Do Begin
      If NumArrays[Idx].Name = VarName Then Begin
        If NumArrays[Idx].NumIndices = 2 Then Begin
          valCount := NumArrays[Idx].Indices[1];
          If valCount >= 3 Then Begin
            sIdx := Idx;
            Break;
          End Else
            Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
        End Else
          Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
      End;
      Inc(Idx);
    End;
    If sIdx = -1 Then Begin
      ERRStr := VarName;
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
    End;
  End Else
    Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

  numPoints := NumArrays[sIdx].Indices[0];

  // Test for an optional destination array

  dIdx := -1;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    VarName := Lower(SP_StackPtr^.Str);
    Dec(SP_StackPtr);
    Idx := 0;
    While Idx < Length(NumArrays) Do Begin
      If NumArrays[Idx].Name = VarName Then Begin
        dIdx := Idx;
        Break;
      End;
      Inc(Idx);
    End;
    If dIdx = -1 Then Begin
      // Doesn't exist - create it.
      Indices := LongWordToString(numPoints) + LongWordToString(valCount);
      dIdx := SP_CreateNumArray(VarName, Indices, NumArrays[sIdx].Base, False, Info^.Error^);
    End Else Begin
      // Exists - check for (and alter) the metrics to suit.
      If (NumArrays[dIdx].NumIndices <> NumArrays[sIdx].NumIndices) or (NumArrays[dIdx].Indices[0] <> numPoints) or (NumArrays[dIdx].Indices[1] <> valCount) Then Begin
        Indices := LongWordToString(numPoints) + LongWordToString(valCount);
        dIdx := SP_CreateNumArray(VarName, Indices, NumArrays[sIdx].Base, False, Info^.Error^);
      End;
    End;
    // Copy non-3D data to destination
    vIdx := 0;
    iSize := valCount;
    For pIdx := 0 To NumPoints -1 Do Begin
      Inc(vIdx, 3);
      For Idx := 4 to iSize Do Begin
        NumArrays[dIdx].Values[vIdx]^.Value := NumArrays[sIdx].Values[vIdx]^.Value;
        Inc(vIdx);
      End;
    End;
  End Else
    dIdx := sIdx;

  // Now run through the transformations. First get the number of transforms.

  NumTransforms := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If NumTransforms = 0 Then Begin

    vIdx := 0;
    iSize := NumArrays[sIdx].Indices[1];
    For pIdx := 0 To numPoints -1 Do Begin
      NumArrays[dIdx].Values[vIdx]^.Value := NumArrays[sIdx].Values[vIdx]^.Value;
      NumArrays[dIdx].Values[vIdx +1]^.Value := NumArrays[sIdx].Values[vIdx + 1]^.Value;
      NumArrays[dIdx].Values[vIdx +2]^.Value := NumArrays[sIdx].Values[vIdx + 2]^.Value;
      Inc(vIdx, iSize);
    End;

  End Else

    While NumTransforms > 0 Do Begin

      Dec(numTransforms);

      KeyWordID := Round(SP_StackPtr^.Val);
      Dec(SP_StackPtr);

      dx := SP_StackPtr^.Val;
      Dec(SP_StackPtr);
      dy := SP_StackPtr^.Val;
      Dec(SP_StackPtr);
      dz := SP_StackPtr^.Val;
      Dec(SP_StackPtr);

      Case KeyWordID of
        SP_KW_ROTATE:
          Begin
            SP_AngleToRad(dX);
            SP_AngleToRad(dY);
            SP_AngleToRad(dZ);
            xCos := Cos(dX);
            yCos := Cos(dY);
            zCos := Cos(dZ);
            xSin := Sin(dX);
            ySin := Sin(dY);
            zSin := Sin(dZ);
            vIdx := 0;
            iSize := NumArrays[sIdx].Indices[1];
            For pIdx := 0 To numPoints -1 Do Begin
              pX := NumArrays[sIdx].Values[vIdx]^.Value;
              pY := NumArrays[sIdx].Values[vIdx + 1]^.Value;
              pZ := NumArrays[sIdx].Values[vIdx + 2]^.Value;
              y1 := pY * xCos + pZ * xSin;
              z1 := pZ * xCos - pY * xSin;
              x2 := pX * yCos - z1 * ySin;
              z2 := pX * ySin + z1 * yCos;
              x3 := x2 * zCos - y1 * zSin;
              y3 := x2 * zSin + y1 * zCos;
              NumArrays[dIdx].Values[vIdx]^.Value := x3;
              NumArrays[dIdx].Values[vIdx +1]^.Value := y3;
              NumArrays[dIdx].Values[vIdx +2]^.Value := z2;
              Inc(vIdx, iSize);
            End;
          End;
        SP_KW_SCALE:
          Begin
            vIdx := 0;
            iSize := NumArrays[sIdx].Indices[1];
            For pIdx := 0 To numPoints -1 Do Begin
              NumArrays[dIdx].Values[vIdx]^.Value := NumArrays[sIdx].Values[vIdx]^.Value * dX;
              NumArrays[dIdx].Values[vIdx +1]^.Value := NumArrays[sIdx].Values[vIdx + 1]^.Value * dY;
              NumArrays[dIdx].Values[vIdx +2]^.Value := NumArrays[sIdx].Values[vIdx + 2]^.Value * dZ;
              Inc(vIdx, iSize);
            End;
          End;
        SP_KW_MOVE:
          Begin
            vIdx := 0;
            iSize := NumArrays[sIdx].Indices[1];
            For pIdx := 0 To numPoints -1 Do Begin
              NumArrays[dIdx].Values[vIdx]^.Value := NumArrays[sIdx].Values[vIdx]^.Value + dX;
              NumArrays[dIdx].Values[vIdx +1]^.Value := NumArrays[sIdx].Values[vIdx + 1]^.Value + dY;
              NumArrays[dIdx].Values[vIdx +2]^.Value := NumArrays[sIdx].Values[vIdx + 2]^.Value + dZ;
              Inc(vIdx, iSize);
            End;
          End;
      End;

      sIdx := dIdx;

    End;

End;

Procedure SP_Interpret_TRANSFORM2D(Var Info: pSP_iInfo);
Var
  Idx, pIdx, sIdx, dIdx, vIdx, valCount, numTransforms, numPoints, iSize: Integer;
  dX, dY, xCos, xSin, pX, pY, x1, y1: aFloat;
  VarName: aString;
  KeyWordID: LongWord;
Begin

  // TRANSFORM2D - pick up src and optional destination, then commands - ID,param(s)
  // Get Source array. Must be suitable.

  sIdx := -1;
  ValCount := 0;
  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    Dec(SP_StackPtr);
    Idx := 0;
    While Idx < Length(NumArrays) Do Begin
      If NumArrays[Idx].Name = VarName Then Begin
        If NumArrays[Idx].NumIndices = 2 Then Begin
          valCount := NumArrays[Idx].Indices[1];
          If valCount >= 2 Then Begin
            sIdx := Idx;
            Break;
          End Else
            Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
        End Else
          Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
      End;
      Inc(Idx);
    End;
    If sIdx = -1 Then Begin
      ERRStr := VarName;
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
    End;
  End Else
    Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

  numPoints := NumArrays[sIdx].Indices[0];

  // Test for an optional destination array

  dIdx := -1;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    VarName := Lower(SP_StackPtr^.Str);
    Dec(SP_StackPtr);
    Idx := 0;
    While Idx < Length(NumArrays) Do Begin
      If NumArrays[Idx].Name = VarName Then Begin
        dIdx := Idx;
        Break;
      End;
      Inc(Idx);
    End;
    If dIdx = -1 Then Begin
      // Doesn't exist - create it.
      Indices := LongWordToString(numPoints) + LongWordToString(valCount);
      dIdx := SP_CreateNumArray(VarName, Indices, NumArrays[sIdx].Base, False, Info^.Error^);
    End Else Begin
      // Exists - check for (and alter) the metrics to suit.
      If (NumArrays[dIdx].NumIndices <> NumArrays[sIdx].NumIndices) or (NumArrays[dIdx].Indices[0] <> numPoints) or (NumArrays[dIdx].Indices[1] <> valCount) Then Begin
        Indices := LongWordToString(numPoints) + LongWordToString(valCount);
        dIdx := SP_CreateNumArray(VarName, Indices, NumArrays[sIdx].Base, False, Info^.Error^);
      End;
    End;
    vIdx := 0;
    iSize := valCount;
    For pIdx := 0 To NumPoints -1 Do Begin
      Inc(vIdx, 2);
      For Idx := 3 to iSize Do Begin
        NumArrays[dIdx].Values[vIdx]^.Value := NumArrays[sIdx].Values[vIdx]^.Value;
        Inc(vIdx);
      End;
    End;
  End Else
    dIdx := sIdx;

  // Now run through the transformations. First get the number of transforms.

  NumTransforms := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  While NumTransforms > 0 Do Begin

    Dec(numTransforms);

    KeyWordID := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);

    Case KeyWordID of
      SP_KW_ROTATE:
        Begin
          dX := SP_StackPtr^.Val;
          SP_AngleToRad(dX);
          Dec(SP_StackPtr);
          xCos := Cos(dX);
          xSin := Sin(dX);
          vIdx := 0;
          iSize := NumArrays[sIdx].Indices[1];
          For pIdx := 0 To numPoints -1 Do Begin
            pX := NumArrays[sIdx].Values[vIdx]^.Value;
            pY := NumArrays[sIdx].Values[vIdx + 1]^.Value;
            x1 := pX * xCos - pY * xSin;
            y1 := pX * xSin + pY * xCos;
            NumArrays[dIdx].Values[vIdx]^.Value := x1;
            NumArrays[dIdx].Values[vIdx +1]^.Value := y1;
            Inc(vIdx, iSize);
          End;
        End;
      SP_KW_SCALE:
        Begin
          dx := SP_StackPtr^.Val;
          Dec(SP_StackPtr);
          dy := SP_StackPtr^.Val;
          Dec(SP_StackPtr);
          vIdx := 0;
          iSize := NumArrays[sIdx].Indices[1];
          For pIdx := 0 To numPoints -1 Do Begin
            NumArrays[dIdx].Values[vIdx]^.Value := NumArrays[sIdx].Values[vIdx]^.Value * dX;
            NumArrays[dIdx].Values[vIdx +1]^.Value := NumArrays[sIdx].Values[vIdx + 1]^.Value * dY;
            Inc(vIdx, iSize);
          End;
        End;
      SP_KW_MOVE:
        Begin
          dx := SP_StackPtr^.Val;
          Dec(SP_StackPtr);
          dy := SP_StackPtr^.Val;
          Dec(SP_StackPtr);
          vIdx := 0;
          iSize := NumArrays[sIdx].Indices[1];
          For pIdx := 0 To numPoints -1 Do Begin
            NumArrays[dIdx].Values[vIdx]^.Value := NumArrays[sIdx].Values[vIdx]^.Value + dX;
            NumArrays[dIdx].Values[vIdx +1]^.Value := NumArrays[sIdx].Values[vIdx + 1]^.Value + dY;
            Inc(vIdx, iSize);
          End;
        End;
    End;

    sIdx := dIdx;

  End;

End;

Procedure SP_Interpret_PROJECT3D(Var Info: pSP_iInfo);
Var
  VarName, Indices: aString;
  rX, rY, rZ, tX, tY, tZ, sX, sY, sZ, y1, z1, x2, z2, x3, y3, f, dist,
  xSin, ySin, zSin, xCos, yCos, zCos, pX, pY, pZ, pC, scrh, cX, cY: aFloat;
  Idx, Idx2, iSize, vIdx, pIdx, sIdx, dIdx, Params, numPoints, valCount: Integer;
  isColour: Boolean;
Const
  drad: aFloat = PI/180;
Begin

  // PROJECT3D src() TO dst() [MOVE tx,ty,tz] [ROTATE rx,ry,rz] [SCALE sx,sy,sz]

  Params := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If Params And 4 = 4 Then Begin // Translation
    tX := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    tY := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    tZ := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
  End Else Begin
    tX := 0;
    tY := 0;
    tZ := 0;
  End;

  If Params And 2 = 2 Then Begin // Scale
    sX := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    sY := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    sZ := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
  End Else Begin
    sX := 1;
    sY := 1;
    sZ := 1;
  End;

  If Params And 1 = 1 Then Begin // Rotation
    rX := SP_StackPtr^.Val;
    SP_AngleToRad(rX);
    Dec(SP_StackPtr);
    rY := SP_StackPtr^.Val;
    SP_AngleToRad(rY);
    Dec(SP_StackPtr);
    rZ := SP_StackPtr^.Val;
    SP_AngleToRad(rZ);
    Dec(SP_StackPtr);
  End Else Begin
    rX := 0;
    rY := 0;
    rZ := 0;
  End;

  // Get Source array. Must be suitable.

  sIdx := -1;
  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    Dec(SP_StackPtr);
    Idx := 0;
    While Idx < Length(NumArrays) Do Begin
      If NumArrays[Idx].Name = VarName Then Begin
        If NumArrays[Idx].NumIndices = 2 Then Begin
          If NumArrays[Idx].Indices[1] >= 3 Then Begin
            sIdx := Idx;
            Break;
          End Else
            Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
        End Else
          Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
      End;
      Inc(Idx);
    End;
    If sIdx = -1 Then
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
  End Else
    Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

  If Info^.Error^.Code <> SP_ERR_OK Then Exit;

  numPoints := NumArrays[sIdx].Indices[0];
  isColour := NumArrays[sIdx].Indices[1] > 3;
  If isColour Then valCount := NumArrays[sIdx].Indices[1] -1 Else valCount := 2;

  // Get Destination array - doesn't have to exist, will be created if necessary.
  // doesn't have to have the right number of indices or sizes, that will be corrected

  dIdx := -1;
  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    Dec(SP_StackPtr);
    Idx := 0;
    While Idx < Length(NumArrays) Do Begin
      If NumArrays[Idx].Name = VarName Then Begin
        dIdx := Idx;
        Break;
      End;
      Inc(Idx);
    End;
    If dIdx = -1 Then Begin
      // Doesn't exist - create it.
      Indices := LongWordToString(numPoints) + LongWordToString(valCount);
      dIdx := SP_CreateNumArray(VarName, Indices, NumArrays[sIdx].Base, False, Info^.Error^);
    End Else Begin
      // Exists - check for (and alter) the metrics to suit.
      If (NumArrays[dIdx].NumIndices <> 2) or (NumArrays[dIdx].Indices[0] <> numPoints) or (NumArrays[dIdx].Indices[1] <> valCount) Then Begin
        Indices := LongWordToString(numPoints) + LongWordToString(valCount);
        SP_CreateNumArray(VarName, Indices, NumArrays[sIdx].Base, False, Info^.Error^);
      End;
    End;
  End Else
    Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

  // Now iterate through the coords held in sIdx and transform them.

  xCos := Cos(rX);
  yCos := Cos(rY);
  zCos := Cos(rZ);

  xSin := Sin(rX);
  ySin := Sin(rY);
  zSin := Sin(rZ);

  scrh := SORGH - SORGY;
  cX := (SORGW - SORGX) / 2;
  cY := scrh / 2;

  Dist := FDIST;

  If valCount = 2 Then Begin

    vIdx := 0;
    Idx := 0;
    numPoints := 0;
    iSize := NumArrays[sIdx].Indices[1];
    For pIdx := 0 To NumArrays[sIdx].Indices[0] -1 Do Begin

      pX := NumArrays[sIdx].Values[vIdx]^.Value;
      pY := NumArrays[sIdx].Values[vIdx + 1]^.Value;
      pZ := NumArrays[sIdx].Values[vIdx + 2]^.Value;
      Inc(vIdx, iSize);

      If Params And 2 = 2 Then Begin // Scaling
        pX := pX * sX;
        pY := pY * sY;
        pZ := pZ * sZ;
      End;

      If Params And 4 = 4 Then Begin // Translation
        pX := pX + tX;
        pY := pY + tY;
        pZ := pZ + tZ;
      End;

      If Params And 1 = 1 Then Begin // Rotation
        y1 := pY * xCos + pZ * xSin;
        z1 := pZ * xCos - pY * xSin;
        x2 := pX * yCos - z1 * ySin;
        z2 := pX * ySin + z1 * yCos;
        x3 := x2 * zCos - y1 * zSin;
        y3 := x2 * zSin + y1 * zCos;
      End Else Begin
        z2 := pZ;
        x3 := pX;
        y3 := pY;
      End;

      If z2 > -Dist Then Begin
        f := dist / (z2 + dist);
        pX := (x3 * f) + cx;
        pY := scrh - ((y3 * f) + cy);
        NumArrays[dIdx].Values[Idx]^.Value := pX;
        NumArrays[dIdx].Values[Idx +1]^.Value := pY;
        Inc(Idx, 2);
        Inc(numPoints);
      End;

    End;

  End Else Begin

    vIdx := 0;
    Idx := 0;
    numPoints := 0;
    iSize := NumArrays[sIdx].Indices[1];
    For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
      pX := NumArrays[sIdx].Values[vIdx]^.Value;
      pY := NumArrays[sIdx].Values[vIdx + 1]^.Value;
      pZ := NumArrays[sIdx].Values[vIdx + 2]^.Value;
      pC := NumArrays[sIdx].Values[vIdx + 3]^.Value;

      If Params And 2 = 2 Then Begin // Scaling
        pX := pX * sX;
        pY := pY * sY;
        pZ := pZ * sZ;
      End;

      If Params And 4 = 4 Then Begin // Translation
        pX := pX + tX;
        pY := pY + tY;
        pZ := pZ + tZ;
      End;

      If Params And 1 = 1 Then Begin // Rotation
        y1 := pY * xCos + pZ * xSin;
        z1 := pZ * xCos - pY * xSin;
        x2 := pX * yCos - z1 * ySin;
        z2 := pX * ySin + z1 * yCos;
        x3 := x2 * zCos - y1 * zSin;
        y3 := x2 * zSin + y1 * zCos;
      End Else Begin
        z2 := pZ;
        x3 := pX;
        y3 := pY;
      End;

      If z2 > -Dist Then Begin
        f := dist / (z2 + dist);
        pX := (x3 * f) + cx;
        pY := scrh - ((y3 * f) + cy);
        NumArrays[dIdx].Values[Idx]^.Value := pX;
        NumArrays[dIdx].Values[Idx +1]^.Value := pY;
        For Idx2 := 2 To ValCount -1 Do
          NumArrays[dIdx].Values[Idx + Idx2]^.Value := NumArrays[sIdx].Values[vIdx + Idx2 + 1]^.Value;
        Inc(Idx, ValCount);
        Inc(NumPoints);
      End;

      Inc(vIdx, iSize);

    End;

  End;

  If Length(NumArrays[dIdx].Values) <> numPoints * valCount Then Begin
    NumArrays[dIdx].Indices[0] := numPoints;
    NumArrays[dIdx].Size := numPoints * valCount;
  End;

End;

Procedure SP_Interpret_RAINBOW_HSV(Var Info: pSP_iInfo);
Var
  Idx, Idx1, Idx2: Integer;
  ClrA, ClrB: LongWord;
  r1, r2, g1, g2, b1, b2, h1, s1, v1, h2, s2, v2: aFloat;
  Mag, hStep, sStep, vStep: aFloat;
Begin

  Idx1 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Idx2 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If Idx1 > Idx2 Then Begin
    Idx1 := Idx1 Xor Idx2;
    Idx2 := Idx1 Xor Idx2;
    Idx1 := Idx1 Xor Idx2;
  End;
  Idx1 := Max(0, Min(255, Idx1));
  Idx2 := Max(0, Min(255, Idx2));

  ClrA := SP_GetPalette(Idx1);
  r1 := (ClrA Shr 24) And $FF;
  g1 := (ClrA Shr 16) And $FF;
  b1 := (ClrA Shr 8) And $FF;

  ClrB := SP_GetPalette(Idx2);
  r2 := (ClrB Shr 24) And $FF;
  g2 := (ClrB Shr 16) And $FF;
  b2 := (ClrB Shr 8) And $FF;

  SP_RGBToHSV(r1, g1, b1, h1, s1, v1);
  SP_RGBToHSV(r2, g2, b2, h2, s2, v2);

  Mag := Idx2 - Idx1;
  hStep := (h2 - h1)/Mag;
  sStep := (s2 - s1)/Mag;
  vStep := (v2 - v1)/Mag;

  For Idx := Idx1 To Idx2 -1 Do Begin

    SP_HSVToRGB(h1, s1, v1, r1, g1, b1);
    SP_SetWindowPalette(Idx, Round(r1), Round(g1), Round(b1));
    h1 := h1 + hStep;
    s1 := s1 + sStep;
    v1 := v1 + vStep;

  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_RAINBOW(Var Info: pSP_iInfo);
Var
  ClrA, ClrB: LongWord;
  Idx, Idx1, Idx2: Integer;
  r1, r2, g1, g2, b1, b2: aFloat;
  Mag, rStep, gStep, bStep: aFloat;
Begin

  Idx1 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Idx2 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If Idx1 > Idx2 Then Begin
    Idx1 := Idx1 Xor Idx2;
    Idx2 := Idx1 Xor Idx2;
    Idx1 := Idx1 Xor Idx2;
  End;
  Idx1 := Max(0, Min(255, Idx1));
  Idx2 := Max(0, Min(255, Idx2));

  ClrA := SP_GetPalette(Idx1);
  r1 := (ClrA Shr 24) And $FF;
  g1 := (ClrA Shr 16) And $FF;
  b1 := (ClrA Shr 8) And $FF;

  ClrB := SP_GetPalette(Idx2);
  r2 := (ClrB Shr 24) And $FF;
  g2 := (ClrB Shr 16) And $FF;
  b2 := (ClrB Shr 8) And $FF;

  Mag := Idx2 - Idx1;
  rStep := (r2 - r1)/Mag;
  gStep := (g2 - g1)/Mag;
  bStep := (b2 - b1)/Mag;

  For Idx := Idx1 To Idx2 -1 Do Begin

    SP_SetWindowPalette(Idx, Round(r1), Round(g1), Round(b1));
    r1 := r1 + rStep;
    g1 := g1 + gStep;
    b1 := b1 + bStep;

  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_KEYBOARD(Var Info: pSP_iInfo);
Var
  Name: aString;
Begin

  Name := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  SP_LoadKeyboardDefinition(Name, Info^.Error^);

End;

Procedure SP_Interpret_WIN_ORIGIN(Var Info: pSP_iInfo);
Var
  WinID: Integer;
  Flip: Boolean;
  x1, y1, x2, y2: aFloat;
Begin

  WinID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  x1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  x2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Flip := SP_StackPtr^.Val <> 0;
  Dec(SP_StackPtr);

  SP_SetWindowOrigin(WinID, x1, y1, x2, y2, Flip, Info^.Error^);

End;

Procedure SP_Interpret_WIN_ORG_NO_EXT(Var Info: pSP_iInfo);
Var
  WinID: Integer;
  Flip: Boolean;
  x1, y1: aFloat;
Begin

  WinID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  x1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Flip := SP_StackPtr^.Val <> 0;
  Dec(SP_StackPtr);

  SP_SetWindowOriginNoExt(WinID, x1, y1, Flip, Info^.Error^);

End;

Procedure SP_Interpret_GFX_ORG_NO_EXT(Var Info: pSP_iInfo);
Var
  GfxID: Integer;
  x1, y1: aFloat;
Begin

  GfxID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  x1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_SetGraphicOriginNoExt(GfxID, x1, y1, Info^.Error^);

End;

Procedure SP_Interpret_WIN_ORG_OFF(Var Info: pSP_iInfo);
Var
  WinID: Integer;
Begin

  WinID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_SetWindowOriginOff(WinID, Info^.Error^);

End;

Procedure SP_Interpret_GFX_ORG_OFF(Var Info: pSP_iInfo);
Var
  GfxID: Integer;
Begin

  GfxID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_SetGraphicOriginOff(GfxID, Info^.Error^);

End;

Procedure SP_Interpret_CLIP(Var Info: pSP_iInfo);
Var
  x1, y1, x2, y2: aFloat;
Begin

  // CLIP x1,y1 TO x2,y2

  y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  x2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  x1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_ConvertToOrigin_d(x1, y1);
  SP_ConvertToOrigin_d(x2, y2);

  CCLIPX1 := Trunc(x1);
  CCLIPX2 := Round(x2);
  CCLIPY1 := Trunc(y1);
  CCLIPY2 := Round(y2);

  SP_Reset_Temp_Colours;

End;

Procedure SP_Interpret_CLIP_OFF(Var Info: pSP_iInfo);
Begin

  // CLIP OFF

  CCLIPX1 := 0;
  CCLIPX2 := SCREENWIDTH;
  CCLIPY1 := 0;
  CCLIPY2 := SCREENHEIGHT;

  SP_Reset_Temp_Colours;

End;

Procedure SP_Interpret_ORIGIN(Var Info: pSP_iInfo);
Var
  Flip: Boolean;
  x1,y1,x2,y2: aFloat;
Begin

  x1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  x2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Flip := SP_StackPtr^.Val <> 0;
  Dec(SP_StackPtr);

  If SCREENBANK >= 0 Then
    SP_SetWindowOrigin(SCREENBANK, x1, y1, x2, y2, Flip, Info^.Error^)
  Else
    SP_SetGraphicOrigin(-SCREENBANK, x1, y1, x2, y2, Info^.Error^);

End;

Procedure SP_Interpret_ORG_OFF(Var Info: pSP_iInfo);
Begin

  If SCREENBANK >= 0 Then
    SP_SetWindowOriginOff(SCREENBANK, Info^.Error^)
  Else
    SP_SetGraphicOriginOff(-SCREENBANK, Info^.Error^);

End;

Procedure SP_Interpret_ORG_NO_EXT(Var Info: pSP_iInfo);
Var
  Flip: Boolean;
  x1, y1: aFloat;
Begin

  x1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Flip := SP_StackPtr^.Val <> 0;
  Dec(SP_StackPtr);

  If SCREENBANK >= 0 Then
    SP_SetWindowOriginNoExt(SCREENBANK, x1, y1, Flip, Info^.Error^)
  Else
    SP_SetGraphicOriginNoExt(-SCREENBANK, x1, y1, Info^.Error^);

End;

Procedure SP_Interpret_ORG_DIM(Var Info: pSP_iInfo);
Var
  Flip: Boolean;
  x1,y1,w,h: aFloat;
Begin

  x1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  w := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  h := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Flip := SP_StackPtr^.Val <> 0;
  Dec(SP_StackPtr);

  If SCREENBANK >= 0 Then
    SP_SetWindowOrigin(SCREENBANK, x1, y1, x1+w, y1+h, Flip, Info^.Error^)
  Else
    SP_SetGraphicOrigin(-SCREENBANK, x1, y1, x1+w, y1+h, Info^.Error^);

End;

Procedure SP_Interpret_WIN_ORG_DIM(Var Info: pSP_iInfo);
Var
  WinID: Integer;
  Flip: Boolean;
  x1, y1, w, h: aFloat;
Begin

  WinID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  x1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  w := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  h := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Flip := SP_StackPtr^.Val <> 0;
  Dec(SP_StackPtr);

  SP_SetWindowOrigin(WinID, x1, y1, x1 + w, y1 + h, Flip, Info^.Error^);

End;

Procedure SP_Interpret_GFX_ORG_DIM(Var Info: pSP_iInfo);
Var
  GfxID: Integer;
  x1, y1, w, h: aFloat;
Begin

  GfxID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  x1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  w := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  h := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_SetGraphicOrigin(GfxID, x1, y1, x1 + w, y1 + h, Info^.Error^);

End;

Procedure SP_Interpret_WIN_ORG_FLIP(Var Info: pSP_iInfo);
Var
  WinID: Integer;
  Win: pSP_Window_Info;
Begin
  // set the flipped var for the specified window/gfx bank
  WinID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_GetWindowDetails(SCREENBANK, Win, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Win^.Flip := not Win^.Flip;
    If WinID = SCREENBANK Then
      WINFLIPPED := Win^.Flip;
  End;

End;

Procedure SP_Interpret_ORIGIN_FLIP(Var Info: pSP_iInfo);
Var
  Win: pSP_Window_Info;
Begin
  // Set the flipped var for the current window
  SP_GetWindowDetails(SCREENBANK, Win, Info^.Error^);
  If Info^.Error^.Code = SP_ERR_OK Then Begin
    Win^.Flip := Not Win^.Flip;
    WINFLIPPED := Win^.Flip;
  End;
End;

Procedure SP_Interpret_WINDOW_FLIP(Var Info: pSP_iInfo);
Var
  WinID: Integer;
  Win: pSP_Window_Info;
Begin

  WinID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_GetWindowDetails(WinID, Win, Info^.Error^);

  If Info^.Error^.Code = SP_ERR_OK Then Begin

    SP_FlipGfx(Win^.Surface, Win^.Width, Win^.Height);
    If Win^.Visible Then
      SP_SetDirtyRect(Win^.Left, Win^.Top, Win^.Left + Win^.Width, Win^.Top + Win^.Height);

  End;

End;

Procedure SP_Interpret_WINDOW_MIRROR(Var Info: pSP_iInfo);
Var
  WinID: Integer;
  Win: pSP_Window_Info;
Begin

  WinID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_GetWindowDetails(WinID, Win, Info^.Error^);

  If Info^.Error^.Code = SP_ERR_OK Then Begin

    SP_MirrorGfx(Win^.Surface, Win^.Width, Win^.Height);
    If Win^.Visible Then
      SP_SetDirtyRect(Win^.Left, Win^.Top, Win^.Left + Win^.Width, Win^.Top + Win^.Height);

  End;

End;

Procedure SP_Interpret_WIN_CLIP(Var Info: pSP_iInfo);
Var
  WinID: Integer;
  Win: pSP_Window_Info;
  x1, y1, x2, y2: aFloat;
Begin

  // WINDOW CLIP id,x1,y1 TO x2,y2

  y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  x2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  x1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  WinID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_GetWindowDetails(WinID, Win, Info^.Error^);

  If Info^.Error^.Code = SP_ERR_OK Then Begin

    SP_ConvertWToOrigin_d(x1, y1, Win);
    SP_ConvertWToOrigin_d(x2, y2, Win);

    Win^.clipx1 := Trunc(x1);
    Win^.clipy1 := Trunc(y1);
    Win^.clipx2 := Round(x2);
    Win^.clipy2 := Round(y2);

    If WinID = SCREENBANK Then Begin

      CCLIPX1 := Trunc(x1);
      CCLIPX2 := Round(x2);
      CCLIPY1 := Trunc(y1);
      CCLIPY2 := Round(y2);
      SP_Reset_Temp_Colours;

    End;

  End;

End;

Procedure SP_Interpret_GFX_CLIP(Var Info: pSP_iInfo);
Var
  GfxID, Idx: Integer;
  Gfx: pSP_Graphic_Info;
  Bank: pSP_Bank;
  x1, y1, x2, y2: aFloat;
Begin

  // GRAPHIC CLIP id,x1,y1 TO x2,y2

  y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  x2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  x1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  GfxID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(GfxId);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @Bank^.Info[0];

      SP_ConvertWToOrigin_d(x1, y1, @Gfx^.WindowInfo);
      SP_ConvertWToOrigin_d(x2, y2, @Gfx^.WindowInfo);

      Gfx^.clipx1 := Trunc(x1);
      Gfx^.clipy1 := Trunc(y1);
      Gfx^.clipx2 := Round(x2);
      Gfx^.clipy2 := Round(y2);
      SP_GFX_UpdateWindowInfo(Gfx, Bank);

      If SCREENBANK = -GfxId Then Begin
        CCLIPX1 := Trunc(x1);
        CCLIPX2 := Round(x2);
        CCLIPY1 := Trunc(y1);
        CCLIPY2 := Round(y2);
        SP_Reset_Temp_Colours;
        SCREENBANK := -1;
        SP_SetDrawingWindow(-GfxId);
      End;

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_WIN_CLIP_OFF(Var Info: pSP_iInfo);
Var
  WinID: Integer;
  Win: pSP_Window_Info;
Begin

  // WINDOW CLIP id OFF

  WinID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_GetWindowDetails(WinID, Win, Info^.Error^);

  If Info^.Error^.Code = SP_ERR_OK Then Begin

    Win^.clipx1 := 0;
    Win^.clipy1 := 0;
    Win^.clipx2 := Win^.Width;
    Win^.clipy2 := Win^.Height;

    If WinID = SCREENBANK Then Begin

      CCLIPX1 := 0;
      CCLIPX2 := Win^.Width;
      CCLIPY1 := 0;
      CCLIPY2 := Win^.Height;

    End;

  End;

End;

Procedure SP_Interpret_GFX_CLIP_OFF(Var Info: pSP_iInfo);
Var
  GfxID, Idx: Integer;
  Gfx: pSP_Graphic_Info;
  Bank: pSP_Bank;
Begin

  // GRAPHIC CLIP id OFF

  GfxID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindBankID(GfxId);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @Bank^.Info[0];

      Gfx^.clipx1 := 0;
      Gfx^.clipy1 := 0;
      Gfx^.clipx2 := Gfx^.Width;
      Gfx^.clipy2 := Gfx^.Height;
      SP_GFX_UpdateWindowInfo(Gfx, Bank);

      If SCREENBANK = -GfxId Then Begin
        CCLIPX1 := 0;
        CCLIPX2 := 0;
        CCLIPY1 := Gfx^.Width;
        CCLIPY2 := GFx^.Height;
        SCREENBANK := -1;
        SP_SetDrawingWindow(-GfxId);
      End;

    End Else
      Info^.Error^.Code := SP_ERR_INVALID_BANK;

  End Else
    Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Interpret_BEEP(Var Info: pSP_iInfo);
Var
  WaveType, Async: Integer;
  Duration, Pitch, Attack, Decay, Sustain, Release, Noise, Roughness: aFloat;
Begin

  Async := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Duration := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If Duration <= 0 Then Begin

    Info^.Error^.Code := SP_ERR_INVALID_DURATION;
    Exit;

  End;

  // Get the pitch in semitones. If a value, then just pass it on.
  // If a string, convert to semitones above or below middle C (C4)

  If SP_StackPtr^.OpType = SP_VALUE Then
    Pitch := SP_StackPtr^.Val
  Else Begin
    Pitch := SP_StringToSemiTones(SP_StackPtr^.Str, Info^.Error^);
    If Info^.Error^.Code <> SP_ERR_OK Then
      Exit;
  End;

  Dec(SP_StackPtr);

  // If there are more stack entries then they're the wavetype and ADSR envelope

  If SP_StackPtr <> SP_StackStart Then Begin

    WaveType := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);

    Attack := SP_StackPtr^.Val;
    Dec(SP_StackPtr);

    Decay := SP_StackPtr^.Val;
    Dec(SP_StackPtr);

    Sustain := SP_StackPtr^.Val;
    Dec(SP_StackPtr);

    Release := SP_StackPtr^.Val;
    Dec(SP_StackPtr);

    Noise := SP_StackPtr^.Val;
    Dec(SP_StackPtr);

    Roughness := SP_StackPtr^.Val;
    Dec(SP_StackPtr);

  End Else Begin

    WaveType := 0;
    Attack := 0;
    Decay := 0;
    Sustain := 1;
    Release := 0;
    Noise := 0;
    Roughness := 0;

  End;

  // Now create and play the sound!

  SP_MakeBEEP(Duration, Pitch, WaveType, Attack, Decay, Sustain, Release, Noise, Roughness, ASync = 1, Info^.Error^);

End;

Procedure SP_Interpret_OUT_VAR(Var Info: pSP_iInfo);
Begin

  // OUT str-var$

  T_OUTEXPR := SP_StackPtr^.Str;
  COUTEXPR := T_OUTEXPR;
  OUTSET := True;
  T_OUTMODE := 1;
  COUTMODE := 1;
  Dec(SP_StackPtr);
  T_OUTASSIGN := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_OUT_SCREEN(Var Info: pSP_iInfo);
Begin

  // OUT SCREEN

  OUTSET := False;
  T_OUTMODE := 0;
  COUTMODE := 0;

End;

Procedure SP_Interpret_OUT_STREAM(Var Info: pSP_iInfo);
Begin

  // OUT stream-id

  T_OUTSTRM := Round(SP_StackPtr^.Val);
  COUTSTRM := T_OUTSTRM;
  OUTSET := True;
  T_OUTMODE := 2;
  COUTMODE := 2;
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_CASE(Var Info: pSP_iInfo);
Begin

  // On entry, the stack should read the result of the evaluation, and then the END CASE location
  // Add the current CASE information to the case-stack - the value to match, the line and statement of the END CASE
  // and the "completed" flag set to false.

  If SP_CaseListPtr >= MAXDEPTH Then
    Info^.Error^.Code := SP_ERR_OUT_OF_MEMORY
  Else Begin

    Inc(SP_CaseListPtr);
    With SP_CaseList[SP_CaseListPtr] Do Begin
      Statement := Round(SP_StackPtr^.Val);
      Dec(SP_StackPtr);

      Line := Round(SP_StackPtr^.Val);
      Dec(SP_StackPtr);

      AllFlag := Round(SP_StackPtr^.Val) <> 0;
      Dec(SP_StackPtr);

      ExpressionType := SP_StackPtr^.OpType;
      If ExpressionType = SP_VALUE Then
        Expression := SP_StackPtr^.Val
      Else
        ExpressionStr := SP_StackPtr^.Str;
      Dec(SP_StackPtr);

      Completed := False;
    End;

  End;

End;

Procedure SP_Interpret_WHEN(Var Info: pSP_iInfo);
Var
  Sp2: pSP_StackItem;
Begin

  // On encountering a WHEN:
  // Check if we're in a CASE, if so then check if it's been completed.
  // If not, test to see if this WHEN matches the stored value. If it doesn't match, then jump to the next WHEN or OTHERWISE (or END CASE).
  // If it matches, flag it complete and continue execution.
  // If it's already complete then jump to the END CASE.

  If SP_CaseListPtr >= 0 Then Begin
    With SP_CaseList[SP_CaseListPtr] Do Begin
      If Completed And Not AllFlag Then Begin
        NXTLINE := Line;
        NXTSTATEMENT := Statement;
        Info^.Error^.ReturnType := SP_JUMP;
        Dec(SP_StackPtr, 3);
      End Else Begin
        Sp2 := SP_StackPtr;
        Dec(Sp2, 2);
        With Sp2^ Do Begin
          If OpType <> ExpressionType Then Begin
            Info^.Error^.Code := SP_ERR_MISMATCHED_WHEN;
            Exit;
          End;
          If OpType = SP_VALUE Then
            Completed := Expression = Val
          Else
            Completed := ExpressionStr = Str;
        End;
        If Not Completed Then Begin
          NXTSTATEMENT := Round(SP_StackPtr^.Val);
          Dec(SP_StackPtr);
          NXTLINE := Round(SP_StackPtr^.Val);
          Dec(SP_StackPtr, 2);
          Info^.Error^.ReturnType := SP_JUMP;
        End Else
          Dec(SP_StackPtr, 3);
      End;
    End;
  End Else
    Info^.Error^.Code := SP_ERR_OUT_OF_CASE;

End;

Procedure SP_Interpret_WHEN_IN(Var Info: pSP_iInfo);
Var
  nSt, Nline: Integer;
Begin

  // Similar to WHEN, but process a range and check that against the value first.

  If SP_CaseListPtr >= 0 Then Begin
    With SP_CaseList[SP_CaseListPtr] Do Begin
      If Completed And Not AllFlag Then Begin
        NXTLINE := Line;
        NXTSTATEMENT := Statement;
        Info^.Error^.ReturnType := SP_JUMP;
      End Else Begin
        nSt := Round(SP_StackPtr^.Val);
        Dec(SP_StackPtr);
        nLine := Round(SP_StackPtr^.Val);
        Dec(SP_StackPtr);
        If SP_TestRanges(Expression, ExpressionStr, ExpressionType = SP_VALUE, Info^.Error^) Then Begin
          Completed := True;
        End Else Begin
          NXTSTATEMENT := nSt;
          NXTLINE := nLine;
          Info^.Error^.ReturnType := SP_JUMP;
        End;
      End;
    End;
  End Else
    Info^.Error^.Code := SP_ERR_OUT_OF_CASE;

End;

Procedure SP_Interpret_OTHERWISE(Var Info: pSP_iInfo);
Begin

  // No need to match for this one - execute it anyway, but only if the CASE has not already been completed.

  If SP_CaseListPtr >= 0 Then Begin
    With SP_CaseList[SP_CaseListPtr] Do Begin
      If Completed Then Begin
        NXTLINE := Line;
        NXTSTATEMENT := Statement;
        Info^.Error^.ReturnType := SP_JUMP;
      End Else
        Completed := True
    End;
  End Else
    Info^.Error^.Code := SP_ERR_OUT_OF_CASE;

End;

Procedure SP_Interpret_END_CASE(Var Info: pSP_iInfo);
Begin

  // Finish the CASE, and remove it from the case-stack.

  If SP_CaseListPtr >= 0 Then
    Dec(SP_CaseListPtr)
  Else
    Info^.Error^.Code := SP_ERR_OUT_OF_CASE;

End;

Procedure SP_Interpret_INCLUDE(Var Info: pSP_iInfo);
Var
  FileCount, LastLine: Integer;
  Err: TSP_ErrorCode;
  tStr: aString;
Begin

  CopyMem(@Err.Line, @Info^.Error^.Line, SizeOf(TSP_ErrorCode));
  Err.Code := SP_ERR_OK;

  LastLine := SP_Program_Count;

  // Top of the stack is the number of files to process.

  FileCount := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  While FileCount > 0 Do Begin

    SP_IncludeFile(SP_StackPtr^.Str, Err);
    Dec(SP_StackPtr);

    If Info^.Error^.Code <> SP_ERR_OK Then
      Break;

    Dec(FileCount);

  End;

  tStr := '';
  If Err.Code = SP_ERR_OK Then
    SP_PreParse(False, False, Err, tStr);

  // Propagate any errors from the above out to the calling stack, to preserve line numbers.

  Info^.Error^.Code := Err.Code;
  If Info^.Error^.Code = SP_ERR_OK Then
    If INCLUDEFROM = -1 Then
      INCLUDEFROM := LastLine;

End;

Procedure SP_Interpret_HALT(Var Info: pSP_iInfo);
Begin

  // Halt the program with no error. Only called from the include process, so takes error line
  // information from there.

  NXTLINE := -1;
  NXTSTATEMENT := 1;
  If INCLUDEFROM > -1 Then With Info^ Do Begin
    Error^.Line := INCLUDEFROM -1;
    Error^.Statement := pLongWord(@SP_Program[Error^.Line][7])^;
  End;
  Info^.Error^.ReturnType := SP_JUMP;

End;

Procedure SP_Interpret_SORT(Var Info: pSP_iInfo);
Var
  sIdx, Idx, aType: Integer;
  VarName: aString;
  Ascending, Key: Boolean;
Begin

  // Sorts an array. Must be one-dimensional, string or numeric.

  sIdx := -1;
  Ascending := Round(SP_StackPtr^.Val) <> -1;
  Dec(SP_StackPtr);

  Key := Round(SP_StackPtr^.Val) <> -1;
  Dec(SP_StackPtr);

  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  aType := SP_StackPtr^.OpType;
  If aType in [SP_NUMVAR, SP_STRVAR] Then Begin
    Dec(SP_StackPtr);
    Idx := 0;
    Case aType of
      SP_NUMVAR:
        Begin
          While Idx < Length(NumArrays) Do Begin
            If NumArrays[Idx].Name = VarName Then Begin
              If NumArrays[Idx].NumIndices = 1 Then Begin
                sIdx := Idx;
                Break;
              End Else
                Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
            End;
            Inc(Idx);
          End;
        End;
      SP_STRVAR:
        Begin
          While Idx < Length(StrArrays) Do Begin
            If StrArrays[Idx].Name = VarName Then Begin
              If StrArrays[Idx].NumIndices = 1 Then Begin
                sIdx := Idx;
                Break;
              End Else
                Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
            End;
            Inc(Idx);
          End;
        End;
    End;
    If sIdx = -1 Then
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
  End Else
    Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

  If Info^.Error^.Code <> SP_ERR_OK Then Exit;

  Case aType of
    SP_NUMVAR:
      Begin
       SP_SortNumArray(sIdx, Key, Ascending, Info^.Error^);
      End;
    SP_STRVAR:
      Begin
        SP_SortStrArray(sIdx, Key, Ascending, Info^.Error^);
      End;
  End;

End;

Procedure SP_Interpret_KEY(Var Info: pSP_iInfo);
Var
  aIdx: Integer;
Begin

  // Attaches a "key" to an array element. On entry:
  // ArrayName (as num/strvar); NumIndices; Indices in descending order; Keyvalue$

  Case SP_StackPtr^.OpType Of

    SP_NUMVAR:
      Begin
        aIdx := SP_FindNumArray(SP_StackPtr^.Str);
        Dec(SP_StackPtr);
        SP_StackToString(Round(SP_StackPtr^.Val));
        SP_SetNumArrayKey(aIdx, gbIndices, gbKey, SP_StackPtr^.Str, Info^.Error^);
      End;

    SP_STRVAR:
      Begin
        aIdx := SP_FindStrArray(SP_StackPtr^.Str);
        Dec(SP_StackPtr);
        SP_StackToString(Round(SP_StackPtr^.Val));
        SP_SetStrArrayKey(aIdx, gbIndices, gbKey, SP_StackPtr^.Str, Info^.Error^);
      End;

  End;

  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_KEY_CLEAR(Var Info: pSP_iInfo);
Var
  aIdx, Idx: Integer;
  Key: aString;
Begin

  // Remove a key.

  Case SP_StackPtr^.OpType Of

    SP_NUMVAR:
      Begin
        aIdx := SP_FindNumArray(SP_StackPtr^.Str);
        Dec(SP_StackPtr);
        SP_StackToString(Round(SP_StackPtr^.Val));
        Idx := SP_NumArrayGetIndex(aIdx, gbIndices, gbKey, Info^.Error^);
        Key := NumArrays[aIdx].Values[Idx].Key;
        If Info^.Error^.Code = SP_ERR_OK Then
          SP_NumArrayRemoveKey(aIdx, Idx, Key);
      End;

    SP_STRVAR:
      Begin
        aIdx := SP_FindStrArray(SP_StackPtr^.Str);
        Dec(SP_StackPtr);
        SP_StackToString(Round(SP_StackPtr^.Val));
        Idx := SP_StrArrayGetIndex(aIdx, gbIndices, gbKey, Info^.Error^);
        Key := StrArrays[aIdx].Strings[Abs(Idx)].Key;
        If Info^.Error^.Code = SP_ERR_OK Then
          SP_StrArrayRemoveKey(aIdx, Idx, Key);
      End;

  End;

  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_KEY_CLEAR_ALL(Var Info: pSP_iInfo);
Var
  Idx, pIdx: Integer;
  nPtr, Ptr: pHashEntry;
Begin

  Case SP_StackPtr^.OpType Of

    SP_NUMVAR:
      Begin
        Idx := SP_FindNumArray(SP_StackPtr^.Str);
        Dec(SP_StackPtr);
        For pIdx := 0 To 255 Do Begin
          Ptr := NumArrays[Idx].Hashes[pIdx];
          While Ptr <> nil Do Begin
            NumArrays[Idx].Values[Ptr^.Index].Key := '';
            nPtr := Ptr^.NextHash;
            Dispose(Ptr);
            Ptr := nPtr;
          End;
          NumArrays[Idx].Hashes[pIdx] := Nil;
        End;
      End;

    SP_STRVAR:
      Begin
        Idx := SP_FindStrArray(SP_StackPtr^.Str);
        Dec(SP_StackPtr);
        For pIdx := 0 To 255 Do Begin
          Ptr := StrArrays[Idx].Hashes[pIdx];
          While Ptr <> nil Do Begin
            StrArrays[Idx].Strings[Ptr^.Index].Key := '';
            nPtr := Ptr^.NextHash;
            Dispose(Ptr);
            Ptr := nPtr;
          End;
          StrArrays[Idx].Hashes[pIdx] := Nil;
        End;
      End;

  End;

End;

Procedure SP_Interpret_DYNAMIC_DIM(Var Info: pSP_iInfo);
Var
  VarName: aString;
  Len: Integer;
Begin

  // Create a dynamic array!
  // Name and type is top of stack, and then the optional length for a fixed-length
  // string array.

  VarName := SP_StackPtr^.Str;

  Case SP_StackPtr^.OpType Of

    SP_NUMVAR:
      Begin
        SP_CreateNumArray(VarName, '', 0, True, Info^.Error^);
      End;

    SP_STRVAR:
      Begin
        Len := 0;
        If NativeUInt(SP_StackPtr) > NativeUInt(SP_StackStart) + SizeOf(SP_StackItem) Then Begin
          Dec(SP_StackPtr);
          Len := Round(SP_StackPtr^.Val);
        End;
        SP_CreateStrArray(VarName, '', Len, '', 0, True, Info^.Error^);
      End;

  End;

  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_MAT_INTERP(Var Info: pSP_iInfo);
Var
  sIdxA, sIdxB, dIdx, Idx: Integer;
  DestName, IdxStr: aString;
  St, Amt: aFloat;
Begin

  // Array interpolation.
  // Destination array will be overwritten and re-dimensioned.
  // Two source arrays must be identical in dimensions.
  // Amount is 0 to 1 inclusive.

  DestName := SP_StackPtr^.Str;
  dIdx := SP_FindNumArray(DestName);
  Dec(SP_StackPtr);

  sIdxA := SP_FindNumArray(SP_StackPtr^.Str);
  If sIdxA = -1 Then Begin
    ERRStr := SP_StackPtr^.Str;
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND
  End Else Begin
    Dec(SP_StackPtr);
    sIdxB := SP_FindNumArray(SP_StackPtr^.Str);
    If sIdxB = -1 Then Begin
      ERRStr := SP_StackPtr^.Str;
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND
    End Else Begin
      Dec(SP_StackPtr);
      Amt := SP_StackPtr^.Val;
      Dec(SP_StackPtr);
      If NumArrays[sIdxA].Size = NumArrays[sIdxB].Size Then Begin
        // If the destination array doesn't exist, create it:
        IdxStr := '';
        For Idx := 0 To High(NumArrays[sIdxA].Indices) Do
          IdxStr := IdxStr + LongWordToString(NumArrays[sIdxA].Indices[Idx]);
        If dIdx = -1 Then
          dIdx := SP_CreateNumArray(DestName, IdxStr, NumArrays[sIdxA].Base, NumArrays[sIdxA].DynArray, Info^.Error^)
        Else
          // If it doesn't match the first array identically, then recreate it:
          If (NumArrays[dIdx].Size <> NumArrays[sIdxA].Size) or (NumArrays[dIdx].Indices <> NumArrays[sIdxA].Indices) Or
             (NumArrays[dIdx].Base <> NumArrays[sIdxA].Base) or (NumArrays[dIdx].DynArray <> NumArrays[sIdxA].DynArray) Then
            dIdx := SP_CreateNumArray(DestName, IdxStr, NumArrays[sIdxA].Base, NumArrays[sIdxA].DynArray, Info^.Error^);
        // Now do the interpolation.
        For Idx := 0 To NumArrays[sIdxA].Size -1 Do Begin
          St := NumArrays[sIdxA].Values[Idx].Value;
          NumArrays[dIdx].Values[Idx].Value := St + (Amt * (NumArrays[sIdxB].Values[Idx].Value - St));
        End;
      End Else Begin
        ERRStr := '';
        Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
      End;
    End;
  End;

End;

Procedure SP_Interpret_MAT(Var Info: pSP_iInfo);
Var
  sIdx, dIdx: Integer;
Begin

  // Matrix substitution - copying one matrix to another.
  // On entry, first stack item is destination, next is source.

  dIdx := SP_FindNumArray(SP_StackPtr^.Str);
  If dIdx = -1 Then
    dIdx := SP_CreateNumArray(SP_StackPtr^.Str, #1#0#0#0#1#0#0#0, 1, False, Info^.Error^);

  Dec(SP_StackPtr);
  sIdx := SP_FindNumArray(SP_StackPtr^.Str);
  If sIdx = -1 Then Begin
    ERRStr := SP_StackPtr^.Str;
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND
  End Else Begin
    Dec(SP_StackPtr);
    SP_CopyNumArray(sIdx, dIdx, Info^.Error^);
  End;

End;

Procedure SP_Interpret_MAT_ZER(Var Info: pSP_iInfo);
Var
  sIdx, Idx: Integer;
Begin

  // Zero matrix - just fill with 0.

  sIdx := SP_FindNumArray(SP_StackPtr^.Str);
  If sIdx = -1 Then Begin
    ERRStr := SP_StackPtr^.Str;
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND
  End Else Begin
    Dec(SP_StackPtr);
    For Idx := 0 To NumArrays[sIdx].Size -1 Do
      NumArrays[sIdx].Values[Idx]^.Value := 0;
  End;

End;

Procedure SP_Interpret_MAT_IDN(Var Info: pSP_iInfo);
Var
  sIdx, Idx, n, Idx2: Integer;
Begin

  // No parameter given, so need to check the array for compatibility -
  // NxN square only, and MUST exist.

  ERRStr := SP_StackPtr^.Str;
  sIdx := SP_FindNumArray(ERRStr);
  If sIdx = -1 Then
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND
  Else Begin
    Dec(SP_StackPtr);
    n := NumArrays[sIdx].Indices[0];
    If (NumArrays[sIdx].NumIndices = 2) and (n = NumArrays[sIdx].Indices[1]) Then Begin
      Idx := 0;
      While Idx < Length(NumArrays[sIdx].Values) Do Begin
        NumArrays[sIdx].Values[Idx]^.Value := 1;
        For Idx2 := 1 To n Do Begin
          Inc(Idx);
          If Idx < n*n Then
            NumArrays[sIdx].Values[Idx]^.Value := 0;
        End;
        Inc(Idx);
      End;
    End Else
      Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
  End;

End;

Procedure SP_Interpret_MAT_IDN_PARAM(Var Info: pSP_iInfo);
Var
  sIdx, Idx, Idx2, n, Size: Integer;
  Indices: aString;
Begin

  // Identity matrix with a parameter - remove the array (if necessary)
  // and recreate it as NxN.

  Size := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If Size > 0 Then Begin

    ERRStr := SP_StackPtr^.Str;
    sIdx := SP_FindNumArray(ERRStr);
    If sIdx <> -1 Then Begin
      Indices := LongWordToString(Size) + LongWordToString(Size);
      sIdx := SP_CreateNumArray(SP_StackPtr^.Str, Indices, BASE, False, Info^.Error^);
    End Else Begin
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
      Exit;
    End;

    Dec(SP_StackPtr);
    n := NumArrays[sIdx].Indices[0];
    If (NumArrays[sIdx].NumIndices = 2) and (n = NumArrays[sIdx].Indices[1]) Then Begin
      Idx := 0;
      While Idx < Length(NumArrays[sIdx].Values) Do Begin
        NumArrays[sIdx].Values[Idx]^.Value := 1;
        For Idx2 := 1 To n Do Begin
          Inc(Idx);
          If Idx < n*n Then
            NumArrays[sIdx].Values[Idx]^.Value := 0;
        End;
        Inc(Idx);
      End;
    End Else
      Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

  End Else
    Info^.Error^.Code := SP_ERR_INVALID_MATRIX;

End;

Procedure SP_Interpret_MAT_CON(Var Info: pSP_iInfo);
Var
  sIdx, Idx: Integer;
Begin

  // constant matrix with no parameter - just fill with 1.

  sIdx := SP_FindNumArray(SP_StackPtr^.Str);
  If sIdx = -1 Then Begin
    ERRStr := SP_StackPtr^.Str;
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND
  End Else Begin
    Dec(SP_StackPtr);
    For Idx := 0 To NumArrays[sIdx].Size -1 Do
      NumArrays[sIdx].Values[Idx]^.Value := 1;
  End;

End;

Procedure SP_Interpret_MAT_CON_PARAM(Var Info: pSP_iInfo);
Var
  sIdx, Idx: Integer;
  Param: aFloat;
Begin

  // constant matrix with parameter.

  Param := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  sIdx := SP_FindNumArray(SP_StackPtr^.Str);
  If sIdx = -1 Then Begin
    ERRStr := SP_StackPtr^.Str;
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND
  End Else Begin
    Dec(SP_StackPtr);
    For Idx := 0 To NumArrays[sIdx].Size -1 Do
      NumArrays[sIdx].Values[Idx]^.Value := Param;
  End;

End;

Procedure SP_Interpret_MAT_INV(Var Info: pSP_iInfo);
Var
  sIdx, dIdx, i,j,k,l,ll,n, iRow, iCol: Integer;
  pinv, big, dum: aFloat;
  ipiv, indxr, indxc: Array of Integer;
  Sp2: pSP_StackItem;

  Function GetVal(r,c: integer): aFloat;
  Begin
    Result := NumArrays[dIdx].Values[((r-1)*n)+c-1]^.Value;
  End;

  Procedure SetVal(r,c: integer; v: aFloat);
  Begin
    NumArrays[dIdx].Values[((r-1)*n)+c-1]^.Value := v;
  End;

Begin

  // Matrix inversion - non-trivial (for me!), and prone to rounding errors.
  // Translated from the fortran code at
  // http://web.archive.org/web/20030508175036/http://www.rose.brandeis.edu/users/derosier/BHP/brandeis-helical-package/lib/matrix/matrix-inversion.f
  // This performs in-place inversion.

  iRow := 0;
  iCol := 0;
  dIdx := SP_FindNumArray(SP_StackPtr^.Str);
  Dec(SP_StackPtr);
  ERRStr := SP_StackPtr^.Str;
  sIdx := SP_FindNumArray(ERRStr);
  Dec(SP_StackPtr);
  If sIdx <> -1 Then Begin
    If (NumArrays[sIdx].NumIndices = 2) And (NumArrays[sIdx].Indices[0] = NumArrays[sIdx].Indices[1]) Then Begin
      n := NumArrays[sIdx].Indices[0];
      If dIdx = -1 Then Begin
        Sp2 := SP_StackPtr;
        Inc(Sp2, 2);
        dIdx := SP_CreateNumArray(Sp2^.Str, LongWordToString(n)+LongWordToString(n), 1, False, Info^.Error^);
      End;
      If sIdx <> dIdx Then SP_CopyNumArray(sIdx, dIdx, Info^.Error^);
      SetLength(ipiv, n+1);
      SetLength(indxr, n+1);
      SetLength(indxc, n+1);
      For j := 1 To n Do
        ipiv[j] := 0;
      For i := 1 To n Do Begin
        big := 0;
        for j := 1 to n Do Begin
          If ipiv[j] <> 1 Then
            For k := 1 To n Do Begin
              If ipiv[k] = 0 Then Begin
                If Abs(GetVal(j,k)) >= big Then Begin
                  big := GetVal(j,k);
                  iRow := j;
                  iCol := k;
                End;
              End Else
                If ipiv[k] > 1 Then Begin
                  Info^.Error^.Code := SP_ERR_MATRIX_SINGULAR;
                  Exit;
                End;
            End;
        End;
        Inc(ipiv[iCol]);
        If iRow <> iCol Then
          For l := 1 To n Do Begin
            dum := GetVal(iRow, l);
            SetVal(iRow, l, GetVal(iCol, l));
            SetVal(iCol, l, dum);
          End;
        indxr[i] := iRow;
        indxc[i] := iCol;
        If GetVal(iCol, iCol) = 0 Then Begin
          Info^.Error^.Code := SP_ERR_MATRIX_SINGULAR;
          Exit;
        End;
        pinv := 1/GetVal(iCol, iCol);
        SetVal(iCol, iCol, 1);
        For l := 1 To n Do
          SetVal(iCol, l, GetVal(iCol, l)*pinv);
        For ll := 1 To n Do
          If ll <> iCol Then Begin
            dum := GetVal(ll, iCol);
            SetVal(ll, iCol, 0);
            For l := 1 To N Do
              SetVal(ll, l, GetVal(ll, l)-GetVal(iCol, l)*dum);
          End;
      End;
      For l := n DownTo 1 Do
        If indxr[l] <> indxc[l] Then
          For k := 1 To n Do Begin
            dum := GetVal(k, indxr[l]);
            SetVal(k, indxr[l], GetVal(k, indxc[l]));
            SetVal(k, indxc[l], dum);
          End;
    End Else
      Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
  End Else
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;

End;

Procedure SP_Interpret_MAT_TRN(Var Info: pSP_iInfo);
Var
  sIdx, dIdx, n, m, r, c, Idx, Dest: Integer;
  Temp: Array of pSP_NumVarContent;
  Sp2: pSP_StackItem;
Begin

  // Matrix transpose. ie, swap rows for columns. 2-dimensional only.

  dIdx := SP_FindNumArray(SP_StackPtr^.Str);
  Dec(SP_StackPtr);
  ERRStr := SP_StackPtr^.Str;
  sIdx := SP_FindNumArray(ERRStr);
  If sIdx <> -1 Then Begin
    If NumArrays[sIdx].NumIndices = 2 Then Begin
      m := NumArrays[sIdx].Indices[0];
      n := NumArrays[sIdx].Indices[1];
      If dIdx = -1 Then Begin
        Sp2 := SP_StackPtr;
        Inc(Sp2, 2);
        dIdx := SP_CreateNumArray(Sp2^.Str, LongWordToString(n)+LongWordToString(m), 1, False, Info^.Error^);
      End;
      If sIdx <> dIdx Then SP_CopyNumArray(sIdx, dIdx, Info^.Error^);
      SetLength(Temp, NumArrays[sIdx].Size);
      For r := 0 To m -1 Do Begin
        For c := 0 To n -1 Do Begin
          Idx := (r*n)+c;
          Dest := (c*m)+r;
          Temp[Dest] := NumArrays[sIdx].Values[Idx];
        End;
      End;
      NumArrays[dIdx].Indices[0] := n;
      NumArrays[dIdx].Indices[1] := m;
      For Idx := 0 To Length(Temp) -1 Do
        NumArrays[dIdx].Values[Idx] := Temp[Idx];
    End Else
      Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
  End Else
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;

End;

Procedure SP_Interpret_MAT_ADD(Var Info: pSP_iInfo);
Var
  s1Idx, s2Idx, dIdx, Idx: Integer;
  Values: Array of aFloat;
  Indices: aString;
  Sp3: pSP_StackItem;
Begin

  // Matrix addition. C, then B, then A.
  // A() = S1() + S2()

  Dec(SP_StackPtr);
  ERRStr := SP_StackPtr^.Str;
  s2Idx := SP_FindNumArray(ERRStr);
  Dec(SP_StackPtr);

  If s2Idx <> -1 Then Begin

    ERRStr := SP_StackPtr^.Str;
    s1Idx := SP_FindNumArray(ERRStr);
    Dec(SP_StackPtr);

    If s2Idx <> -1 Then Begin

      If NumArrays[s1Idx].NumIndices = NumArrays[s2Idx].NumIndices Then Begin

        Indices := '';
        For Idx := 0 To NumArrays[s1Idx].NumIndices -1 Do Begin
          Indices := Indices + LongWordToString(NumArrays[s1Idx].Indices[Idx]);
          If NumArrays[s1Idx].Indices[Idx] <> NumArrays[s2Idx].Indices[Idx] Then Begin
            Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
            Exit;
          End;
        End;

        SetLength(Values, NumArrays[s1Idx].Size);
        For Idx := 0 To NumArrays[s1Idx].Size -1 Do
          Values[Idx] := NumArrays[s1Idx].Values[Idx]^.Value + NumArrays[s2Idx].Values[Idx]^.Value;

        Sp3 := SP_StackPtr;
        Inc(Sp3, 3);
        dIdx := SP_CreateNumArray(Sp3^.Str, Indices, NumArrays[s1Idx].Base, False, Info^.Error^);
        If Info^.Error^.Code <> SP_ERR_OK Then Exit;
        For Idx := 0 To NumArrays[dIdx].Size -1 Do
          NumArrays[dIdx].Values[Idx]^.Value := Values[Idx];

      End Else
        Info^.Error^.Code := SP_ERR_MISMATCHED_MATRICES;

    End Else
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;

  End Else
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;

End;

Procedure SP_Interpret_MAT_SUB(Var Info: pSP_iInfo);
Var
  s1Idx, s2Idx, dIdx, Idx: Integer;
  Values: Array of aFloat;
  Sp3: pSP_StackItem;
  Indices: aString;
Begin

  // Matrix addition. C, then B, then A.
  // A() = S1() - S2()

  Dec(SP_StackPtr);
  s2Idx := SP_FindNumArray(SP_StackPtr^.Str);
  Dec(SP_StackPtr);

  If s2Idx <> -1 Then Begin

    ERRStr := SP_StackPtr^.Str;
    s1Idx := SP_FindNumArray(SP_StackPtr^.Str);
    Dec(SP_StackPtr);

    If s1Idx <> -1 Then Begin

      If NumArrays[s1Idx].NumIndices = NumArrays[s2Idx].NumIndices Then Begin

        Indices := '';
        For Idx := 0 To NumArrays[s1Idx].NumIndices -1 Do Begin
          Indices := Indices + LongWordToString(NumArrays[s1Idx].Indices[Idx]);
          If NumArrays[s1Idx].Indices[Idx] <> NumArrays[s2Idx].Indices[Idx] Then Begin
            Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
            Exit;
          End;
        End;

        SetLength(Values, NumArrays[s1Idx].Size);
        For Idx := 0 To NumArrays[s1Idx].Size -1 Do
          Values[Idx] := NumArrays[s1Idx].Values[Idx]^.Value - NumArrays[s2Idx].Values[Idx]^.Value;

        Sp3 := SP_StackPtr;
        Inc(Sp3, 2);
        dIdx := SP_CreateNumArray(Sp3^.Str, Indices, NumArrays[s1Idx].Base, False, Info^.Error^);
        If Info^.Error^.Code <> SP_ERR_OK Then Exit;
        For Idx := 0 To NumArrays[dIdx].Size -1 Do
          NumArrays[dIdx].Values[Idx]^.Value := Values[Idx];

      End Else
        Info^.Error^.Code := SP_ERR_MISMATCHED_MATRICES;

    End Else
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;

  End Else
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;

End;

Procedure SP_Interpret_MAT_PROD(Var Info: pSP_iInfo);
Var
  s2Idx, s1Idx, dIdx, m, n, p, r, c, d, Idx: Integer;
  Values: Array of aFloat;
  Sp3: pSP_StackItem;
  Indices: aString;
  Sum: aFloat;
Begin

  // Matrix multiplication. Harder, but not that hard. Dot product.
  // MxN * NxP == MxP matrix, so N must be equal for both matrices.

  // D() = S1() * S2()

  Dec(SP_StackPtr);
  ERRStr := SP_StackPtr^.Str;
  s1Idx := SP_FindNumArray(ERRStr);
  Dec(SP_StackPtr);

  If s1Idx <> -1 Then Begin

    ERRStr := SP_StackPtr^.Str;
    s2Idx := SP_FindNumArray(ERRStr);
    Dec(SP_StackPtr);

    If s2Idx <> -1 Then Begin

      If (NumArrays[s1Idx].NumIndices = 2) and (NumArrays[s2Idx].NumIndices = 2) Then Begin

        m := NumArrays[s1Idx].Indices[0];
        n := NumArrays[s1Idx].Indices[1];
        If NumArrays[s2Idx].Indices[0] <> n Then Begin
          Info^.Error^.Code := SP_ERR_INVALID_MATRIX;
          Exit;
        End;
        p := NumArrays[s2Idx].Indices[1];

        SetLength(Values, m * p);

        For r := 0 To m-1 Do
          For c := 0 To p-1 Do Begin
            Sum := 0;
            For d := 0 To n-1 Do
              Sum := Sum + (NumArrays[s1Idx].Values[(r*n)+d]^.Value * NumArrays[s2Idx].Values[(d*p)+c]^.Value);
            Values[(r*p)+c] := Sum;
          End;

        Sp3 := SP_StackPtr;
        Inc(Sp3, 3);
        Indices := LongWordToString(m) + LongWordToString(p);
        dIdx := SP_CreateNumArray(Sp3^.Str, Indices, NumArrays[s1Idx].Base, False, Info^.Error^);
        If Info^.Error^.Code = SP_ERR_OK Then
          For Idx := 0 To Length(Values) -1 Do
            NumArrays[dIdx].Values[Idx]^.Value := Values[Idx];

      End Else
        Info^.Error^.Code := SP_ERR_INVALID_MATRIX;

    End Else
      Info^.Error.Code := SP_ERR_ARRAY_NOT_FOUND;

  End Else
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;

End;

Procedure SP_Interpret_MAT_SCALE(Var Info: pSP_iInfo);
Var
  sIdx, dIdx, Idx: Integer;
  Values: Array of aFloat;
  Scalar: aFloat;
  Indices: aString;
Begin

  // Matrix multiplied by a scalar.
  // A() = S1() * SCL

  Dec(SP_StackPtr);
  ERRStr := SP_StackPtr^.Str;
  sIdx := SP_FindNumArray(ERRStr);
  Dec(SP_StackPtr);
  Scalar := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  If sIdx <> -1 Then Begin

    Indices := '';
    For Idx := 0 To NumArrays[sIdx].NumIndices -1 Do
      Indices := Indices + LongWordToString(NumArrays[sIdx].Indices[Idx]);

    SetLength(Values, NumArrays[sIdx].Size);
    For Idx := 0 To NumArrays[sIdx].Size -1 Do
      Values[Idx] := NumArrays[sIdx].Values[Idx]^.Value * Scalar;

    dIdx := SP_CreateNumArray(pSP_StackItem(NativeUInt(SP_StackPtr) + SizeOf(SP_StackItem))^.Str, Indices, NumArrays[sIdx].Base, False, Info^.Error^);
    If Info^.Error^.Code <> SP_ERR_OK Then Exit;
    For Idx := 0 To NumArrays[dIdx].Size -1 Do
      NumArrays[dIdx].Values[Idx]^.Value := Values[Idx];

  End Else
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;

End;

Procedure SP_Interpret_SPRITE_POINT(Var Info: pSP_iInfo);
Var
  Sp, X, Y: Integer;
Begin

  // X followed by Y followed by id

  Sp := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  X := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Y := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_SetSpriteHotSpot(Sp, X, Y, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_SET_ANIM(Var Info: pSP_iInfo);
Var
  SpID, aStart, aEnd, Option: Integer;
Begin

  SpId := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Option := -1;

  If NativeUInt(SP_StackPtr) > NativeUInt(SP_StackStart) + SizeOf(SP_StackItem) Then Begin

    aStart := Round(SP_StackPtr^.Val) -1;
    Dec(SP_StackPtr);
    If aStart >= 0 Then Begin

      aEnd := -1;
      If SP_StackPtr <> SP_StackStart Then Begin
        aEnd := Round(SP_StackPtr^.Val) -1;
        Dec(SP_StackPtr);
        If aEnd < 0 Then Begin
          Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
          Exit;
        End;
      End;

      If SP_StackPtr <> SP_StackStart Then Begin
        Option := Round(SP_StackPtr^.Val);
        Dec(SP_StackPtr);
      End;

    End Else Begin

      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
      Exit;

    End;

  End Else Begin

    aStart := -1;
    aEnd := -1;

    If SP_StackPtr <> SP_StackStart Then Begin
      Option := Round(SP_StackPtr^.Val);
      Dec(SP_StackPtr);
    End;

  End;

  SP_Sprite_SetAnim(SpID, aStart, aEnd, Option, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_ANIM_STOP(Var Info: pSP_iInfo);
Var
  SpID: Integer;
Begin

  SpId := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_Sprite_Stop_Anim(SpID, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_FRAME(Var Info: pSP_iInfo);
Var
  SpID, Frame: Integer;
  SpDelay: Integer;
Begin

  SpID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Frame := Round(SP_StackPtr^.Val) -1;
  Dec(SP_StackPtr);

  SpDelay := -1;
  If SP_StackPtr <> SP_StackStart Then Begin

    SpDelay := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);

    If SpDelay < 1 Then Begin
      Info^.Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
      Exit;
    End;

  End;

  SP_Sprite_Set_Frame(SpID, Frame, SpDelay, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_MIRROR(Var Info: pSP_iInfo);
Var
  SpID: Integer;
Begin

  SpID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_MirrorSprite(SpID, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_FLIP(Var Info: pSP_iInfo);
Var
  SpID: Integer;
Begin

  SpID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_FlipSprite(SpID, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_PUT(Var Info: pSP_iInfo);
Var
  SpID: Integer;
Begin

  SpID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_PutSpritePermanent(SpID, Info^.Error^);

End;

Procedure SP_Interpret_SPRITE_COLLIDE_CLEAR(Var Info: pSP_iInfo);
Var
  Idx: Integer;
Begin

  For Idx := 0 To Length(SP_BankList) -1 Do
    If SP_BankList[Idx]^.DataType = SP_SPRITE_BANK Then
      With pSP_Sprite_Info(@SP_BankList[Idx]^.Info[0])^ Do
        If Collided Then Begin
          Collided := False;
          CanCollide := True;
        End;

  COLLIDE_FLAG := False;

End;

Procedure SP_Interpret_SPRITE_COLLIDE_CLEAR_ID(Var Info: pSP_iInfo);
Var
  Idx: Integer;
Begin

  Idx := SP_FindSpriteID(Round(SP_StackPtr^.Val), Info^.Error^);
  If Idx > -1 Then Begin

    If SP_BankList[Idx]^.DataType = SP_SPRITE_BANK Then
      With pSP_Sprite_Info(@SP_BankList[Idx]^.Info[0])^ Do
        If Collided Then Begin
          Collided := False;
          CanCollide := True;
        End;

    COLLIDE_FLAG := False;

  End Else

    Info^.Error^.Code := SP_ERR_SPRITE_NOT_FOUND;

End;

Procedure SP_Interpret_ENDIF(Var Info: pSP_iInfo);
Begin

  // Do nowt

End;

Procedure SP_Interpret_ZONE_NEW(Var Info: pSP_iInfo);
Var
  x1, y1, x2, y2: Integer;
  Idx: Integer;
Begin

  x1 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  y1 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  x2 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  y2 := Round(SP_StackPtr^.Val);

  Idx := SP_NewZone(Info^.Error^);
  SP_UpdateZone(Idx, SCREENBANK, x1, y1, x2, y2, Info^.Error^);

  SP_StackPtr^.Val := Idx;

End;

Procedure SP_Interpret_ZONE_NEW_B(Var Info: pSP_iInfo);
Var
  x1, y1, x2, y2: Integer;
  Idx: Integer;
Begin

  x1 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  y1 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  x2 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  y2 := Round(SP_StackPtr^.Val);

  Idx := SP_NewZone(Info^.Error^);
  SP_UpdateZone_Coord(Idx, SCREENBANK, x1, y1, x2, y2, Info^.Error^);

  SP_StackPtr^.Val := Idx;

End;

Procedure SP_Interpret_ZONE_MOVE(Var Info: pSP_iInfo);
Var
  Id, dX, dY: Integer;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  dX := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  dY := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_MoveZone(Id, dX, dY, Info^.Error^);

End;

Procedure SP_Interpret_ZONE_MOVETO(Var Info: pSP_iInfo);
Var
  Id, dX, dY: Integer;
Begin

  Id := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  dX := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  dY := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_MoveZoneTo(Id, dX, dY, Info^.Error^);

End;

Procedure SP_Interpret_ZONE_UPDATE(Var Info: pSP_iInfo);
Var
  x1, y1, x2, y2: Integer;
  Idx: Integer;
Begin

  Idx := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  x1 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  y1 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  x2 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  y2 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_UpdateZone(Idx, SCREENBANK, x1, y1, x2, y2, Info^.Error^);

End;

Procedure SP_Interpret_ZONE_UPDATE_B(Var Info: pSP_iInfo);
Var
  x1, y1, x2, y2: Integer;
  Idx: Integer;
Begin

  Idx := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  x1 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  y1 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  x2 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  y2 := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_UpdateZone_Coord(Idx, SCREENBANK, x1, y1, x2, y2, Info^.Error^);

End;

Procedure SP_Interpret_ZONE_ERASE(Var Info: pSP_iInfo);
Begin

  SP_DeleteZone(Round(SP_StackPtr^.Val), Info^.Error^);
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_ADRAWTO(Var Info: pSP_iInfo);
Var
  YPos, XPos, Angle: aFloat; NumParams: Integer;
  sp1: pSP_StackItem;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  Angle := 0;
  NumParams := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If NumParams = 3 Then Begin
    Angle := SP_StackPtr^.Val;
    If WINFLIPPED Then Angle := -Angle;
    Dec(SP_StackPtr);
  End;

  sp1 := SP_StackPtr;
  Dec(sp1);
  SP_ConvertToOrigin_d(Sp1^.Val, SP_StackPtr^.Val);

  YPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  XPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  If WINFLIPPED Then YPos := (SCREENHEIGHT - 1) - YPos;

  If NumParams = 2 Then
    SP_DrawLine32Alpha(XPos - DRPOSX, YPos - DRPOSY)
  Else
    SP_DrawSpeccyCurve32Alpha(XPos - DRPOSX, YPos - DRPOSY, Angle);

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_ADRAW_CTO(Var Info: pSP_iInfo);
Var
  YPos, XPos, dXPos, dYPos, Angle: aFloat; NumParams: Integer;
  Sp1, Sp2: pSP_StackItem;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  Angle := 0;
  NumParams := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If NumParams = 3 Then Begin
    Angle := SP_StackPtr^.Val;
    If WINFLIPPED Then Angle := -Angle;
    Dec(SP_StackPtr);
  End;

  Sp1 := SP_StackPtr;
  Dec(Sp1);

  SP_ConvertToOrigin_d(Sp1^.Val, SP_StackPtr^.Val);
  Dec(Sp1);
  Sp2 := Sp1;
  Dec(Sp2);
  SP_ConvertToOrigin_d(Sp2^.Val, Sp1^.Val);

  YPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  XPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dYPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dXPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  If WINFLIPPED Then Begin
    YPos := (SCREENHEIGHT - 1) - YPos;
    dYPos := (SCREENHEIGHT - 1) - dYPos;
  End;

  DRPOSX := XPos;
  DRPOSY := YPos;

  If NumParams = 2 Then
    SP_DrawLine32Alpha(dXPos - XPos, dYPos - YPos)
  Else
    SP_DrawSpeccyCurve32Alpha(dXPos - XPos, dYPos - YPos, Angle);

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_ADRAWTURTLE(Var Info: pSP_iInfo);
Var
  Hdg, Dist, dX, dY: aFloat;
  tBool: Boolean;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  Dist := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  Hdg := DRHEADING;
  SP_AngleToRad(Hdg);

  tBool := WINORIGIN;
  WINORIGIN := False;
  dX := Dist * Cos(Hdg);
  dY := Dist * Sin(Hdg);
  SP_ConvertToOrigin_d(dX, dY);
  If WINFLIPPED Then dY := -dY;
  SP_DrawLine32Alpha(dX, dY);
  SP_NeedDisplayUpdate := True;
  WINORIGIN := tBool;

End;

Procedure SP_Interpret_ACIRCLEFILL(Var Info: pSP_iInfo);
Var
  R, dX, dY: aFloat;
  Radius1, Radius2, tW, tH, BankID: Integer;
  TextureStr: aString;
  Valid, BankFill: Boolean;
  gBank: pSP_Bank;
  Graphic: pSP_Graphic_Info;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  tw := 0; th := 0;

  BankFill := False;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    TextureStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
        Graphic := @gBank^.Info[0];
        tW := NativeUInt(Graphic^.Data);
        tH := NativeUInt(Graphic);
        BankFill := True;
      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else Begin
    TextureStr := SP_StackPtr^.Str;
  End;
  Dec(SP_StackPtr);

  If Info^.Error^.Code <> SP_ERR_OK Then Exit;

  If WINSCALE Then Begin
    R := SP_StackPtr^.Val;
    Radius1 := Round(R/WINSCALEX);
    Radius2 := Round(R/WINSCALEY);
  End Else Begin
    Radius1 := Round(SP_StackPtr^.Val);
    Radius2 := Radius1;
  End;

  Dec(SP_StackPtr);

  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_ConvertToOrigin_d(dX, dY);
  If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;

  If Not BankFill Then Begin
    Valid := False;
    If TextureStr = '' Then
      SP_DrawSolidEllipse32Alpha(Round(dX), Round(dY), Radius1, Radius2)
    Else Begin
      If Length(TextureStr) > 10 Then Begin
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
        If Length(TextureStr) - 10 = tW * tH Then Valid := True;
      End;
      If Not Valid Then Begin
        TextureStr := SP_StringToTexture(TextureStr);
        If TextureStr = '' Then
          SP_DefaultFill(TextureStr, T_INK);
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
      End;
      SP_DrawTexEllipse32Alpha(Trunc(dX), Trunc(dY), Radius1, Radius2, TextureStr, tW, tH);
    End;
  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_AELLIPSEFILL(Var Info: pSP_iInfo);
Var
  Valid, BankFill: Boolean;
  TextureStr: aString;
  rX, rY, dX, dY: aFloat;
  tW, tH, RadiusX, RadiusY, BankID: Integer;
  gBank: pSP_Bank;
  Graphic: pSP_Graphic_Info;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  tw := 0; th := 0;
  BankFill := False;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    TextureStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
        Graphic := @gBank^.Info[0];
        tW := NativeUInt(Graphic^.Data);
        tH := NativeUInt(Graphic);
        BankFill := True;
      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else
    TextureStr := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  If Info^.Error^.Code <> SP_ERR_OK Then Exit;

  If WINSCALE Then Begin
    Ry := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    Rx := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    RadiusX := Round(Rx/WINSCALEX);
    RadiusY := Round(Ry/WINSCALEY);
  End Else Begin
    RadiusY := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    RadiusX := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End;

  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_ConvertToOrigin_d(dX, dY);
  If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;

  If Not BankFill Then Begin
    Valid := False;
    If TextureStr = '' Then
      SP_DrawSolidEllipse32Alpha(Round(dX), Round(dY), RadiusX, RadiusY)
    Else Begin
      If Length(TextureStr) > 10 Then Begin
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
        If Length(TextureStr) - 10 = tW * tH Then Valid := True;
      End;
      If Not Valid Then Begin
        TextureStr := SP_StringToTexture(TextureStr);
        If TextureStr = '' Then
          SP_DefaultFill(TextureStr, T_INK);
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
      End;
      SP_DrawTexEllipse32Alpha(Trunc(dX), Trunc(dY), RadiusX, RadiusY, TextureStr, tW, tH);
    End;
  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_AFILLTEX(Var Info: pSP_iInfo);
Begin
// alpha
  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

End;

Procedure SP_Interpret_ARECTFILL(Var Info: pSP_iInfo);
Var
  Valid, BankFill: Boolean;
  TextureStr: aString;
  tW, tH, BankID: Integer;
  X1, Y1, X2, Y2: aFloat;
  gBank: pSP_Bank;
  Graphic: pSP_Graphic_Info;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  tw := 0; th := 0;
  BankFill := False;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    TextureStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
        Graphic := @gBank^.Info[0];
        tW := NativeUInt(Graphic^.Data);
        tH := NativeUInt(Graphic);
        BankFill := True;
      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else Begin
    TextureStr := SP_StackPtr^.Str;
  End;
  Dec(SP_StackPtr);

  Y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  if NativeUInt(SP_StackPtr) > NativeUInt(SP_StackStart) then Begin
    Y1 := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    X1 := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
  End Else Begin
    X1 := DRPOSX; X2 := X2 + DRPOSX;
    Y1 := DRPOSY; Y2 := Y2 + DRPOSY;
  End;
  SP_ConvertToOrigin_d(X1, Y1);
  SP_ConvertToOrigin_d(X2, Y2);
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  If Not BankFill Then Begin
    Valid := False;
    If TextureStr = '' Then
      SP_DrawSolidRectangle32Alpha(Round(X1), Round(Y1), Round(X2), Round(Y2))
    Else Begin
      If Length(TextureStr) > 10 Then Begin
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
        If Length(TextureStr) - 10 = tW * tH Then Valid := True;
      End;
      If Not Valid Then Begin
        TextureStr := SP_StringToTexture(TextureStr);
        If TextureStr = '' Then
          SP_DefaultFill(TextureStr, T_INK);
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
      End;
      SP_DrawTexRectangle32Alpha(Trunc(X1), Trunc(Y1), Trunc(X2), Trunc(Y2), TextureStr, tW, tH);
    End;
  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_ARECTANGLE2(Var Info: pSP_iInfo);
Var
  Y1, H, X1, W, X2, Y2: aFloat;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  H := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  W := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_ConvertToOrigin_d(X1, Y1);
  X2 := X1 + W -1;
  Y2 := Y1 + H -1;
  SP_ConvertToOrigin_d(X2, Y2);
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  SP_DrawRectangle32Alpha(Round(X1), Round(Y1), Round(X2), Round(Y2));

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_ARECTFILL2(Var Info: pSP_iInfo);
Var
  Valid, BankFill: Boolean;
  TextureStr: aString;
  tW, tH, BankID: Integer;
  X1, Y1, X2, Y2, W, H: aFloat;
  gBank: pSP_Bank;
  Graphic: pSP_Graphic_Info;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  tw := 0; th := 0;
  BankFill := False;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    TextureStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
        Graphic := @gBank^.Info[0];
        tW := NativeUInt(Graphic^.Data);
        tH := NativeUInt(Graphic);
        BankFill := True;
      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else Begin
    TextureStr := SP_StackPtr^.Str;
  End;
  Dec(SP_StackPtr);

  H := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  W := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_ConvertToOrigin_d(X1, Y1);
  X2 := X1 + W -1;
  Y2 := Y1 + H -1;
  SP_ConvertToOrigin_d(X2, Y2);
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  If Not BankFill Then Begin
    Valid := False;
    If TextureStr = '' Then
      SP_DrawSolidRectangle32Alpha(Round(X1), Round(Y1), Round(X2), Round(Y2))
    Else Begin
      If Length(TextureStr) > 10 Then Begin
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
        If Length(TextureStr) - 10 = tW * tH Then Valid := True;
      End;
      If Not Valid Then Begin
        TextureStr := SP_StringToTexture(TextureStr);
        If TextureStr = '' Then
          SP_DefaultFill(TextureStr, T_INK);
        tW := pLongWord(@TextureStr[1])^;
        tH := pLongWord(@TextureStr[5])^;
      End;
      SP_DrawTexRectangle32Alpha(Trunc(X1), Trunc(Y1), Trunc(X2), Trunc(Y2), TextureStr, tW, tH);
    End;
  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_APOLYLINE(Var Info: pSP_iInfo);
Var
  pX, pY, dX, dY: aFloat;
  NumPoints, iSize, Idx, pIdx, vIdx: Integer;
  VarName: aString;
  Points: Array of TSP_Point;
  IsOpen: Boolean;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  SKIPFIRSTPOINT := False;
  IsOpen := SP_StackPtr^.Val = 1;
  Dec(SP_StackPtr);

  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    VarName := Lower(SP_StackPtr^.Str);
    ERRStr := VarName;
    If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
      Dec(SP_StackPtr);
      Idx := 0;
      While Idx < Length(NumArrays) Do Begin
        If NumArrays[Idx].Name = VarName Then Begin
          If (NumArrays[Idx].NumIndices = 2) And (NumArrays[Idx].Indices[0] >= 3) Then Begin
            iSize := NumArrays[Idx].Indices[1];
            If iSize >= 2 Then Begin
              dX := NumArrays[Idx].Values[0]^.Value;
              dY := NumArrays[Idx].Values[1]^.Value;
              SP_ConvertToOrigin_d(dX, dY);
              If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;
              DRPOSX := dX;
              DRPOSY := dY;
              vIdx := iSize;
              For pIdx := 0 To NumArrays[Idx].Indices[0] -2 Do Begin
                pX := NumArrays[Idx].Values[vIdx]^.Value;
                pY := NumArrays[Idx].Values[vIdx + 1]^.Value;
                SP_ConvertToOrigin_d(pX, pY);
                If WINFLIPPED Then pY := (SCREENHEIGHT - 1) - pY;
                Inc(vIdx, iSize);
                SP_DrawLine32Alpha(pX - DRPOSX, pY - DRPOSY);
              End;
              If Not IsOpen Then
                SP_DrawLine32Alpha(dX - DRPOSX, dY - DRPOSY);
              SP_NeedDisplayUpdate := True;
              Exit;
            End;
          End Else
            Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
        End;
        Inc(Idx);
      End;
      ERRStr := VarName;
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
    End Else
      Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
  End Else Begin

    NumPoints := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);

    SetLength(Points, NumPoints);
    Dec(NumPoints);

    While NumPoints >= 0 Do Begin

      pY := SP_StackPtr^.Val;
      Dec(SP_StackPtr);
      pX := SP_StackPtr^.Val;
      Dec(SP_StackPtr);
      SP_ConvertToOrigin_d(pX, pY);
      If WINFLIPPED Then pY := (SCREENHEIGHT - 1) - pY;
      Points[NumPoints].X := pX;
      Points[NumPoints].Y := pY;
      Dec(NumPoints);

    End;

    DRPOSX := Points[0].X;
    DRPOSY := Points[0].Y;

    For NumPoints := 1 To Length(Points) - 1 Do
      SP_DrawLine32Alpha(Points[NumPoints].X - DRPOSX, Points[NumPoints].Y - DRPOSY);

    If Not IsOpen Then
      SP_DrawLine32Alpha(Points[0].X - DRPOSX, Points[0].Y - DRPOSY);

  End;

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_APOLYFILL(Var Info: pSP_iInfo);
Var
  Points: Array of TSP_Point;
  VarName, TextureStr: aString;
  NumPoints, iSize, Idx, pIdx, vIdx, tW, tH, BankID: Integer;
  pX, pY: aFloat;
  gBank: pSP_Bank;
  Graphic: pSP_Graphic_Info;
  Valid, BankFill: Boolean;
Label
  DrawIt;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  tw := 0; th := 0;
  BankFill := False;
  If SP_StackPtr^.OpType = SP_VALUE Then Begin
    TextureStr := '';
    BankID := SP_FindBankID(Round(SP_StackPtr^.Val));
    If BankID > -1 Then Begin
      gBank := SP_BankList[BankID];
      If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
        Graphic := @gBank^.Info[0];
        tW := NativeUInt(Graphic^.Data);
        tH := NativeUInt(Graphic);
        BankFill := True;
      End Else
        Info^.Error^.Code := SP_ERR_INVALID_BANK;
    End Else
      Info^.Error^.Code := SP_ERR_BANK_NOT_FOUND;
  End Else Begin
    TextureStr := SP_StackPtr^.Str;
  End;
  Dec(SP_StackPtr);

  VarName := '';
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    VarName := Lower(SP_StackPtr^.Str);
    Dec(SP_StackPtr);
  End;

  If VarName <> '' Then Begin
    Idx := 0;
    ERRStr := VarName;
    While Idx < Length(NumArrays) Do Begin
      If NumArrays[Idx].Name = VarName Then Begin
        numPoints := NumArrays[Idx].Indices[0];
        If (NumArrays[Idx].NumIndices = 2) And (NumPoints >= 3) Then Begin
          iSize := NumArrays[Idx].Indices[1];
          If iSize >= 2 Then Begin
            SetLength(Points, numPoints);
            vIdx := 0;
            For pIdx := 0 To NumPoints -1 Do Begin
              pX := NumArrays[Idx].Values[vIdx]^.Value;
              pY := NumArrays[Idx].Values[vIdx + 1]^.Value;
              SP_ConvertToOrigin_d(pX, pY);
              If WINFLIPPED Then pY := (SCREENHEIGHT - 1) - pY;
              Inc(vIdx, iSize);
              Points[pIdx].X := pX;
              Points[pIdx].Y := pY;
            End;
            Goto DrawIt;
          End;
        End Else
          Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
      End;
      Inc(Idx);
    End;
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;

  End Else Begin

    NumPoints := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);

    SetLength(Points, NumPoints);
    Idx := NumPoints - 1;

    While Idx >= 0 Do Begin

      pY := SP_StackPtr^.Val;
      Dec(SP_StackPtr);
      pX := SP_StackPtr^.Val;
      Dec(SP_StackPtr);
      SP_ConvertToOrigin_d(pX, pY);
      If WINFLIPPED Then pY := (SCREENHEIGHT - 1) - pY;
      Points[Idx].X := pX;
      Points[Idx].Y := PY;
      Dec(Idx);

    End;

  End;

  DrawIt:

  If Info^.Error^.Code = SP_ERR_OK Then Begin

    If Not BankFill Then Begin
      Valid := False;
      If TextureStr = '' Then
        SP_PolygonSolidFill32Alpha(Points)
      Else Begin
        If Length(TextureStr) > 10 Then Begin
          tW := pLongWord(@TextureStr[1])^;
          tH := pLongWord(@TextureStr[5])^;
          If Length(TextureStr) - 10 = tW * tH Then Valid := True;
        End;
        If Not Valid Then Begin
          TextureStr := SP_StringToTexture(TextureStr);
          If TextureStr = '' Then
            SP_DefaultFill(TextureStr, T_INK);
          tW := pLongWord(@TextureStr[1])^;
          tH := pLongWord(@TextureStr[5])^;
        End;
        SP_PolygonFill32Alpha(Points, TextureStr, tW, tH);
      End;
    End;
    SP_NeedDisplayUpdate := True;

  End;

End;

Procedure SP_Interpret_ACIRCLE(Var Info: pSP_iInfo);
Var
  R, dX, dY: aFloat;
  Radius1, Radius2: Integer;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  If WINSCALE Then Begin
    R := SP_StackPtr^.Val;
    Radius1 := Round(R/WINSCALEX);
    Radius2 := Round(R/WINSCALEY);
  End Else Begin
    Radius1 := Round(SP_StackPtr^.Val);
    Radius2 := Radius1;
  End;

  Dec(SP_StackPtr);

  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_ConvertToOrigin_d(dX, dY);
  If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;
  SP_DrawEllipse32Alpha(Round(dX), Round(dY), Radius1, Radius2);

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_APLOT(Var Info: pSP_iInfo);
Var
  YPos, XPos: Integer;
  VarName: aString;
  dX, dY: aFloat;
  Idx, iSize, vIdx, pIdx: Integer;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
      Dec(SP_StackPtr);
      Idx := 0;
      While Idx < Length(NumArrays) Do Begin
        If NumArrays[Idx].Name = VarName Then Begin
          If NumArrays[Idx].NumIndices = 2 Then Begin
            iSize := NumArrays[Idx].Indices[1];
            If iSize = 2 Then Begin
              vIdx := 0;
              For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
                dX := NumArrays[Idx].Values[vIdx]^.Value;
                dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
                Inc(vIdx, iSize);
                SP_ConvertToOrigin_d(dX, dY);
                If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;
                SP_SetPixel32Alpha(dX, dY)
              End;
              If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, SCREENWIDTH, SCREENHEIGHT);
              Exit;
            End Else
              If iSize >= 3 Then Begin
                vIdx := 0;
                For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
                  dX := NumArrays[Idx].Values[vIdx]^.Value;
                  dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
                  T_INK := Round(NumArrays[Idx].Values[vIdx + 2]^.Value);
                  Inc(vIdx, iSize);
                  SP_ConvertToOrigin_d(dX, dY);
                  If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;
                  SP_SetPixel32Alpha(dX, dY)
                End;
                If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, SCREENWIDTH, SCREENHEIGHT);
                Exit;
              End Else
                Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
          End Else
            Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
        End;
        Inc(Idx);
      End;
      ERRStr := VarName;
      Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
    End Else
      Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
  End Else Begin
    dY := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    dX := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    SP_ConvertToOrigin_d(dX, dY);
    If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;
    xPos := Round(dX); yPos := Round(dY);
    SP_SetPixel32Alpha(xPos, yPos);
    If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + XPos, SCREENY + YPos, SCREENX + XPos, SCREENY + YPos);
  End;

  SP_BankList[0]^.Changed := True;
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_ADRAW(Var Info: pSP_iInfo);
Var
  YPos, XPos, Angle: aFloat; NumParams: Integer;
  Sp1: pSP_StackItem;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  Angle := 0;

  NumParams := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  If NumParams = 3 Then Begin
    Angle := SP_StackPtr^.Val;
    If WINFLIPPED Then Angle := -Angle;
    Dec(SP_StackPtr);
  End;

  Sp1 := SP_StackPtr;
  Dec(Sp1);
  SP_ConvertToOrigin_d(Sp1^.Val, SP_StackPtr^.Val);

  YPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  XPos := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  If WINFLIPPED Then YPos := (SCREENHEIGHT - 1) - YPos;

  If NumParams = 2 Then
    SP_DrawLine32Alpha(XPos, YPos)
  Else
    SP_DrawSpeccyCurve32Alpha(XPos, YPos, Angle);

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_AELLIPSE(Var Info: pSP_iInfo);
Var
  rX, rY, dX, dY: aFloat;
  RadiusX, RadiusY: Integer;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  If WINSCALE Then Begin
    Ry := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    Rx := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    RadiusX := Round(Rx/WINSCALEX);
    RadiusY := Round(Ry/WINSCALEY);
  End Else Begin
    RadiusY := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
    RadiusX := Round(SP_StackPtr^.Val);
    Dec(SP_StackPtr);
  End;

  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_ConvertToOrigin_d(dX, dY);
  If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;

  SP_DrawEllipse32Alpha(Round(dX), Round(dY), RadiusX, RadiusY);

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_ACURVE(Var Info: pSP_iInfo);
Var
  Y1, X1, X2, Y2: aFloat;
  N: Integer;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  N := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_ConvertToOrigin_d(X1, Y1);
  SP_ConvertToOrigin_d(X2, Y2);
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  SP_DrawCurve32Alpha(DRPOSX, DRPOSY, X1, Y1, X2, Y2, N);
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_ACURVE_EX(Var Info: pSP_iInfo);
Var
  Y1, X1, X2, Y2, X3, Y3: aFloat;
  N: Integer;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  N := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);
  Y3 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X3 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  Y1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X1 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_ConvertToOrigin_d(X1, Y1);
  SP_ConvertToOrigin_d(X2, Y2);
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  SP_DrawCurve32Alpha(X1, Y1, X2, Y2, X3, Y3, N);
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_AFILL(Var Info: pSP_iInfo);
Var
  dX, dY: aFloat;
  Ink: Byte;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  dX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  dY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  SP_ConvertToOrigin_d(dX, dY);
  If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;

  If T_INVERSE = 0 Then
    Ink := T_INK
  Else
    Ink := T_PAPER;

  SP_FloodFill32Alpha(SCREENPOINTER, Round(dX), Round(dY), SCREENSTRIDE, SCREENHEIGHT, Ink);

  If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, DISPLAYWIDTH, DISPLAYHEIGHT);
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_ARECTANGLE(Var Info: pSP_iInfo);
Var
  Y1, Y2, X1, X2: aFloat;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  Y2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);
  X2 := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  if NativeUInt(SP_StackPtr) > NativeUInt(SP_StackStart) then Begin
    Y1 := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
    X1 := SP_StackPtr^.Val;
    Dec(SP_StackPtr);
  End Else Begin
    X1 := DRPOSX; X2 := X2 + DRPOSX;
    Y1 := DRPOSY; Y2 := Y2 + DRPOSY;
  End;

  SP_ConvertToOrigin_d(X1, Y1);
  SP_ConvertToOrigin_d(X2, Y2);
  If WINFLIPPED Then Begin
    Y1 := (SCREENHEIGHT - 1) - Y1;
    Y2 := (SCREENHEIGHT - 1) - Y2;
  End;

  SP_DrawRectangle32Alpha(Round(X1), Round(Y1), Round(X2), Round(Y2));

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Interpret_AMULTIPLOT(Var Info: pSP_iInfo);
Var
  VarName: aString;
  dX, dY: aFloat;
  Idx, iSize, vIdx, pIdx: Integer;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  VarName := Lower(SP_StackPtr^.Str);
  ERRStr := VarName;
  If SP_StackPtr^.OpType = SP_NUMVAR Then Begin
    Dec(SP_StackPtr);
    Idx := 0;
    While Idx < Length(NumArrays) Do Begin
      If NumArrays[Idx].Name = VarName Then Begin
        If NumArrays[Idx].NumIndices = 2 Then Begin
          iSize := NumArrays[Idx].Indices[1];
          If iSize = 2 Then Begin
            vIdx := 0;
            For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
              dX := NumArrays[Idx].Values[vIdx]^.Value;
              dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
              Inc(vIdx, iSize);
              SP_ConvertToOrigin_d(dX, dY);
              If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;
              SP_SetPixel32Alpha(dX, dY);
            End;
            Exit;
          End Else
            If iSize >= 3 Then Begin
              vIdx := 0;
              For pIdx := 0 To NumArrays[Idx].Indices[0] -1 Do Begin
                dX := NumArrays[Idx].Values[vIdx]^.Value;
                dY := NumArrays[Idx].Values[vIdx + 1]^.Value;
                T_INK := Round(NumArrays[Idx].Values[vIdx + 2]^.Value);
                Inc(vIdx, iSize);
                SP_ConvertToOrigin_d(dX, dY);
                If WINFLIPPED Then dY := (SCREENHEIGHT - 1) - dY;
                SP_SetPixel32Alpha(dX, dY);
              End;
              Exit;
            End Else
              Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
        End Else
          Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;
      End;
      Inc(Idx);
    End;
    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;
  End Else
    Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

End;

Procedure SP_Interpret_APRINT(Var Info: pSP_iInfo);
Var
  PrItem, CurItem: aString;
  UsingPos: Integer;
  Item: TUsingItem;
  AddReturn: Boolean;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  PrItem := '';
  AddReturn := True;
  UsingPos := 1;

  While SP_StackPtr <> SP_StackStart Do Begin
    With SP_StackPtr^ Do Begin
      Case OpType of
        SP_VALUE:
          Begin
            If T_USINGMASK <> '' Then Begin
              Item.Kind := SP_VALUE;
              Item.Value := Val;
              CurItem := SP_Using(T_USINGMASK, [Item], UsingPos);
            End Else
              CurItem := aString(aFloatToStr(Val));
            prItem := PrItem + CurItem;
            CurItem := '';
            AddReturn := True;
          End;
        SP_STRING:
          Begin
            If T_USINGMASK <> '' Then Begin
              Item.Kind := SP_STRING;
              Item.Text := Str;
              CurItem := SP_Using(T_USINGMASK, [Item], UsingPos);
            End Else
              CurItem := Str;
            prItem := PrItem + CurItem;
            CurItem := '';
            AddReturn := True;
          End;
        SP_SYMBOL:
          Begin
            Case Str[1] of
              #39:
                Begin
                  PrItem := PrItem + aChar(13);
                  AddReturn := False;
                End;
              ';':
                Begin
                  AddReturn := False;
                End;
              ',':
                Begin
                  PrItem := PrItem + aChar(6);
                  AddReturn := False;
                End;
            End;
          End;
      End;
    End;
    Dec(SP_StackPtr);

  End;

  If PrItem <> '' Then Begin
    If PrItem[Length(PrItem)] in [#13, #6] Then
      AddReturn := False;

    If AddReturn Then PrItem := PrItem + #13;
    If Not T_CENTRE Then Begin
      If SP_PRINT32Alpha(-1, Round(PRPOSX), Round(PRPOSY), -1, PrItem, T_INK, T_PAPER, Info^.Error^) = SP_ERR_PRINT_ABANDONED Then Begin
        Info^.Error^.Code := SP_ERR_BREAK;
        T_USINGMASK := '';
        Exit;
      End;
    End Else Begin
      T_CENTRETEXT := T_CENTRETEXT + PrItem;
    End;
  End Else
    If AddReturn Then Begin
      PRPOSX := 0;
      PRPOSY := PRPOSY + FONTHEIGHT;
      If PRPOSY + FONTHEIGHT > SCREENHEIGHT Then
        If Not SP_TestScroll(FONTHEIGHT, Info^.Error^) Then Begin
          Info^.Error^.Code := SP_ERR_BREAK;
          Exit;
        End Else
          Repeat
            PRPOSY := PRPOSY - FONTHEIGHT;
          Until PRPOSY + FONTHEIGHT < SCREENHEIGHT;
    End;

  If OUTSET Then SP_FlushOUTBuffer(Info);

  T_OUTMODE := COUTMODE;
  If T_OUTMODE = 1 Then Begin
    T_OUTEXPR := COUTEXPR;
    OUTSET := COUTEXPR <> '';
  End Else
    If T_OUTMODE = 2 Then Begin
      // set OUTSET if stream available - fail silently if not, only raise an error on the next output
      T_OUTSTRM := COUTSTRM;
      OUTSET := True;
    End Else
      OUTSET := False;

  T_USINGMASK := '';

End;

Procedure SP_Interpret_ATEXT(Var Info: pSP_iInfo);
Var
  PrItem, CurItem: aString;
  UsingPos: Integer;
  Item: TUsingItem;
  AddReturn: Boolean;
Begin

  If SCREENBPP <> 32 Then Begin
    Info^.Error^.Code := SP_ERR_INVALID_DEPTH;
    Exit;
  End;

  PrItem := '';
  AddReturn := True;
  UsingPos := 1;

  While SP_StackPtr <> SP_StackStart Do Begin
    With SP_StackPtr^ Do Begin
      Case OpType of
        SP_VALUE:
          Begin
            If T_USINGMASK <> '' Then Begin
              Item.Kind := SP_VALUE;
              Item.Value := Val;
              CurItem := SP_Using(T_USINGMASK, [Item], UsingPos);
            End Else
              CurItem := aString(aFloatToStr(Val));
            prItem := PrItem + CurItem;
            CurItem := '';
            AddReturn := True;
          End;
        SP_STRING:
          Begin
            If T_USINGMASK <> '' Then Begin
              Item.Kind := SP_STRING;
              Item.Text := Str;
              CurItem := SP_Using(T_USINGMASK, [Item], UsingPos);
            End Else
              CurItem := Str;
            prItem := PrItem + CurItem;
            CurItem := '';
            AddReturn := True;
          End;
        SP_SYMBOL:
          Begin
            Case Str[1] of
              #39:
                Begin
                  PrItem := PrItem + aChar(13);
                  AddReturn := False;
                End;
              ';':
                Begin
                  AddReturn := False;
                End;
              ',':
                Begin
                  PrItem := PrItem + aChar(6);
                  AddReturn := False;
                End;
            End;
          End;
      End;
    End;
    Dec(SP_StackPtr);

  End;

  If PrItem <> '' Then Begin
    If PrItem[Length(PrItem)] in [#13, #6] Then
      AddReturn := False;

    If AddReturn Then PrItem := PrItem + #13;

    If OUTSET Then
      SP_PRINT(-1, Round(PRPOSX), Round(PRPOSY), -1, PrItem, T_INK, T_PAPER, Info^.Error^)
    Else
      If Not T_CENTRE Then Begin
        If SP_TextOut32Alpha(-1, Round(PRPOSX), Round(PRPOSY), PrItem, T_INK, T_PAPER, True) = SP_ERR_PRINT_ABANDONED Then Begin
          Info^.Error^.Code := SP_ERR_BREAK;
          T_USINGMASK := '';
          Exit;
        End;
      End Else Begin
        T_CENTRETEXT := T_CENTRETEXT + PrItem;
      End;
  End Else
    If AddReturn Then Begin
      PRPOSX := 0;
      PRPOSY := PRPOSY + FONTHEIGHT;
    End;

  T_OUTMODE := COUTMODE;
  If T_OUTMODE = 1 Then Begin
    T_OUTEXPR := COUTEXPR;
    OUTSET := COUTEXPR <> '';
  End Else
    If T_OUTMODE = 2 Then Begin
      // set OUTSET if stream available - fail silently if not, only raise an error on the next output
      T_OUTSTRM := COUTSTRM;
      OUTSET := True;
    End Else
      OUTSET := False;

  T_USINGMASK := '';

End;

Procedure SP_Interpret_FILTER_STR(Var Info: pSP_iInfo);
Var
  Filter, VarName: aString;
  Include, ndx, Idx, Idx2, Idx3: Integer;
  Remove: Boolean;
Begin

  // Filters (removes or isolates) string array elements based on a pattern match.
  // One-dimensional arrays only.

  Filter := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  VarName := SP_StackPtr^.Str;
  ERRStr := VarName;
  Dec(SP_StackPtr);

  Include := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindStrArray(VarName);
  ndx := 1;

  If Idx <> -1 Then Begin

    If (StrArrays[Idx].NumIndices = 1) And (Not StrArrays[Idx].DynArray) Then Begin

      Idx2 := 0;
      While Idx2 < Length(StrArrays[Idx].Strings) Do Begin

        If Include = 1 Then
          Remove := SP_RegExp(Filter, StrArrays[Idx].Strings[Idx2]^.Value, ndx, Info^.Error^) <> 0
        Else
          Remove := SP_RegExp(Filter, StrArrays[Idx].Strings[idx2]^.Value, ndx, Info^.Error^) = 0;

        If Remove Then Begin
          Dispose(StrArrays[Idx].Strings[Idx2]);
          For Idx3 := Idx2 To Length(StrArrays[Idx].Strings) -2 Do
            StrArrays[Idx].Strings[Idx3] := StrArrays[Idx].Strings[Idx3 +1];
          SetLength(StrArrays[Idx].Strings, Length(StrArrays[Idx].Strings) -1);
        End Else
          Inc(Idx2);

      End;

      StrArrays[Idx].Size := Length(StrArrays[Idx].Strings);
      StrArrays[Idx].Indices[0] := StrArrays[Idx].Size;

    End Else

      Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

  End Else Begin

    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;

  End;

End;

Procedure SP_Interpret_FILTER_NUM(Var Info: pSP_iInfo);
Var
  VarName: aString;
  Filter: aFloat;
  Include, Idx, Idx2, Idx3: Integer;
  Remove: Boolean;
Begin

  // Filters (removes or isolates) numeric array elements that match a given value.
  // One-dimensional arrays only.

  Filter := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  VarName := SP_StackPtr^.Str;
  ERRStr := VarName;
  Dec(SP_StackPtr);

  Include := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindNumArray(VarName);

  If Idx <> -1 Then Begin

    If (NumArrays[Idx].NumIndices = 1) And (Not NumArrays[Idx].DynArray) Then Begin

      Idx2 := 0;
      While Idx2 < Length(NumArrays[Idx].Values) Do Begin

        Remove := NumArrays[Idx].Values[Idx2]^.Value = Filter;
        If Include = 0 Then Remove := Not Remove;

        If Remove Then Begin
          Dispose(NumArrays[Idx].Values[Idx2]);
          For Idx3 := Idx2 To Length(NumArrays[Idx].Values) -2 Do
            NumArrays[Idx].Values[Idx3] := NumArrays[Idx].Values[Idx3 +1];
          SetLength(NumArrays[Idx].Values, Length(NumArrays[Idx].Values) -1);
        End Else
          Inc(Idx2);

      End;

      NumArrays[Idx].Size := Length(NumArrays[Idx].Values);
      NumArrays[Idx].Indices[0] := NumArrays[Idx].Size;

    End Else

      Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

  End Else Begin

    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;

  End;

End;

Procedure SP_Interpret_FILTER_NUM_R(Var Info: pSP_iInfo);
Type
  TRange = Record
    RType: Byte;
    RMin, RMax: aFloat;
    RName: aString;
  End;
Var
  Ranges: Array of TRange;
  NumRangeItems: Integer;
  VarName: aString;
  Include, Idx, Idx2, Idx3: Integer;
  Remove: Boolean;
  Value: aFloat;
Begin

  // Filters (removes or isolates) numeric array items based on ranges.
  // One-dimensional arrays only.

  NumRangeItems := Round(SP_StackPtr^.Val);
  SetLength(Ranges, NumRangeItems);
  Dec(SP_StackPtr);

  For Idx := 0 To NumRangeItems -1 Do Begin

    With Ranges[Idx] Do Begin

      Case SP_StackPtr^.OpType Of

        SP_RANGE:
          Begin
            Dec(SP_StackPtr);
            RType := SP_RANGE;
            RMax := SP_StackPtr^.Val;
            Dec(SP_StackPtr);
            RMin := SP_StackPtr^.Val;
            Dec(SP_StackPtr);
          End;

        SP_RANGE_LESS:
          Begin
            Dec(SP_StackPtr);
            RType := SP_RANGE_LESS;
            RMax := SP_StackPtr^.Val;
            Dec(SP_StackPtr);
          End;

        SP_RANGE_GREATER:
          Begin
            Dec(SP_StackPtr);
            RType := SP_RANGE_GREATER;
            RMin := SP_StackPtr^.Val;
            Dec(SP_StackPtr);
          End;

        SP_RANGE_ARRAYNUM:
          Begin
            Dec(SP_StackPtr);
            RType := SP_RANGE_ARRAYNUM;
            RName := SP_StackPtr^.Str;
            Dec(SP_StackPtr);
          End;

      End;

    End;

  End;

  VarName := SP_StackPtr^.Str;
  ERRStr := VarName;
  Dec(SP_StackPtr);

  Include := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  Idx := SP_FindNumArray(VarName);

  If Idx <> -1 Then Begin

    If (NumArrays[Idx].NumIndices = 1) And (Not NumArrays[Idx].DynArray) Then Begin

      Idx2 := 0;
      While Idx2 < Length(NumArrays[Idx].Values) Do Begin

        Value := NumArrays[Idx].Values[Idx2]^.Value;

        Remove := False;
        For Idx3 := 0 To NumRangeItems -1 Do Begin
          With Ranges[Idx3] Do Begin
            Case RType Of
              SP_RANGE:
                Begin
                  Remove := (Value >= RMin) And (Value <= RMax);
                End;
              SP_RANGE_LESS:
                Begin
                  Remove := Value <= RMax;
                End;
              SP_RANGE_GREATER:
                Begin
                  Remove := Value >= RMin;
                End;
              SP_RANGE_ARRAYNUM:
                Begin
                  Remove := SP_ValueInNumArray(RName, Value, Info^.Error^);
                End;
            End;
            If Remove Then Break;
          End;
        End;

        If Include = 0 Then Remove := Not Remove;

        If Remove Then Begin
          Dispose(NumArrays[Idx].Values[Idx2]);
          For Idx3 := Idx2 To Length(NumArrays[Idx].Values) -2 Do
            NumArrays[Idx].Values[Idx3] := NumArrays[Idx].Values[Idx3 +1];
          SetLength(NumArrays[Idx].Values, Length(NumArrays[Idx].Values) -1);
        End Else
          Inc(Idx2);

      End;

      NumArrays[Idx].Size := Length(NumArrays[Idx].Values);
      NumArrays[Idx].Indices[0] := NumArrays[Idx].Size;

      SetLength(Ranges, 0);

    End Else

      Info^.Error^.Code := SP_ERR_UNSUITABLE_ARRAY;

  End Else Begin

    Info^.Error^.Code := SP_ERR_ARRAY_NOT_FOUND;

  End;

End;

Procedure SP_Interpret_MENU_NEW(Var Info: pSP_iInfo);
Var
  NumItems, Idx: Integer;
  Items: Array of SP_MENUITEM;
Begin

  NumItems := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SetLength(Items, NumItems);

  For Idx := 0 To NumItems -1 Do Begin

    With Items[Idx] Do Begin
      Caption := SP_StackPtr^.Str;
      Dec(SP_StackPtr);
      Checkable := False;
      Checked :=   False;
      Enabled :=   True;
      Visible :=   True;
      Selected :=  False;
      SubMenu :=   -1;
      Parent :=    -1;
    End;

  End;

  SP_StackPtr^.OpType := SP_VALUE;
  SP_StackPtr^.Val := SP_NewMenu(Items, False);

End;

Procedure SP_Interpret_MENU_ADD_ITEM(Var Info: pSP_iInfo);
Var
  mID: Integer;
  Item: SP_MENUITEM;
Begin

  mID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  With Item Do Begin
    Caption := SP_StackPtr^.Str;
    Checkable := False;
    Checked :=   False;
    Enabled :=   True;
    Visible :=   True;
    Selected :=  False;
    SubMenu :=   -1;
  End;
  Dec(SP_StackPtr);

  SP_AddItem(mID, Item, Info^.Error^);

End;

Procedure SP_Interpret_MENU_INSITEM(Var Info: pSP_iInfo);
Var
  mID: Integer;
  Item: SP_MenuItem;
Begin

  mID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  With Item Do Begin
    Caption := SP_StackPtr^.Str;
    Checkable := False;
    Checked :=   False;
    Enabled :=   True;
    Visible :=   True;
    Selected :=  False;
    SubMenu :=   -1;
  End;
  Dec(SP_StackPtr);

  SP_InsertItem(mID, Round(SP_StackPtr^.Val), Item, Info^.Error^);
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_MENU_DELITEM(Var Info: pSP_iInfo);
Var
  mID: Integer;
Begin

  mID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_DeleteItem(mID, Round(SP_StackPtr^.Val), Info^.Error^);
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_MENU_ADDSUB(Var Info: pSP_iInfo);
Var
  mID, ItemPos: Integer;
Begin

  mID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  ItemPos := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_SetSubMenu(mID, ItemPos, Round(SP_StackPtr^.Val), Info^.Error^);
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_MENU_DELSUB(Var Info: pSP_iInfo);
Var
  mID: Integer;
Begin

  mID := Round(SP_StackPtr.Val);
  Dec(SP_StackPtr);

  SP_RemoveSubMenu(mID, Round(SP_StackPtr^.Val), Info^.Error^);
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_MENU_SHOW(Var Info: pSP_iInfo);
Var
  mID: Integer;
Begin

  mID := SP_FindMenuID(Round(SP_StackPtr^.Val));
  If mID > -1 Then
    CURMENU := mID
  Else
    Info^.Error^.Code := SP_ERR_MENU_NOT_FOUND;

End;

Procedure SP_Interpret_MENU_HIDE(Var Info: pSP_iInfo);
Begin

  CURMENU := -1;

End;

Procedure SP_Interpret_MENU_ERASE_ALL(Var Info: pSP_iInfo);
Begin

  SP_DeleteMenu(Round(SP_StackPtr^.Val), True, Info^.Error^);
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_MENU_ERASE(Var Info: pSP_iInfo);
Begin

  SP_DeleteMenu(Round(SP_StackPtr^.Val), False, Info^.Error^);
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_MENUITEM_ATTR(Var Info: pSP_iInfo);
Var
  mID, iID: Integer;
Begin

  mID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  iID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SP_SetItemAttrs(mID, iID, Round(SP_StackPtr^.Val), Info^.Error^);

End;

Procedure SP_Interpret_MENU_ATTR(Var Info: pSP_iInfo);
Begin

  // Nothing to do here yet.

End;

Procedure SP_Interpret_MENU_FONT(Var Info: pSP_iInfo);
Var
  mIdx, FntID: Integer;
  SclX, SclY: aFloat;
Begin

  mIdx := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  FntID := Round(SP_StackPtr^.Val);
  Dec(SP_StackPtr);

  SclX := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SclY := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  SP_SetMenuFont(mIdx, FntID, SclX, SclY, SP_StackPtr^.Val <> 0, Info^.Error^);
  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_KW_MEMWRITE(Var Info: pSP_iInfo);
Var
  Val: Byte;
  {$IFDEF FPC}
  ptr: pByte;
  {$ENDIF}
Begin

  Val := Round(SP_StackPtr^.Val) And 255;
  Dec(SP_StackPtr);

  {$IFDEF FPC}
  ptr := pByte(Round(SP_StackPtr^.Val));
  Ptr^ := Val;
  {$ELSE}
  pByte(Round(SP_StackPtr^.Val))^ := Val;
  {$ENDIF}

  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_KW_MEMWRITED(Var Info: pSP_iInfo);
Var
  Val: Word;
  {$IFDEF FPC}
  ptr: pWord;
  {$ENDIF}
Begin

  Val := Round(SP_StackPtr^.Val) And 65535;
  Dec(SP_StackPtr);

  {$IFDEF FPC}
  ptr := pWord(Round(SP_StackPtr^.Val));
  Ptr^ := Val;
  {$ELSE}
  pWord(Round(SP_StackPtr^.Val))^ := Val;
  {$ENDIF}

  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_KW_MEMWRITEQ(Var Info: pSP_iInfo);
Var
  Val: LongWord;
  {$IFDEF FPC}
  ptr: pLongWord;
  {$ENDIF}
Begin

  Val := Round(SP_StackPtr^.Val) And $FFFFFFFF;
  Dec(SP_StackPtr);

  {$IFDEF FPC}
  ptr := pLongWord(Round(SP_StackPtr^.Val));
  Ptr^ := Val;
  {$ELSE}
  pLongWord(Round(SP_StackPtr^.Val))^ := Val;
  {$ENDIF}

  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_KW_MEMWRITEF(Var Info: pSP_iInfo);
Var
  Val: aFloat;
  {$IFDEF FPC}
  ptr: paFloat;
  {$ENDIF}
Begin

  Val := SP_StackPtr^.Val;
  Dec(SP_StackPtr);

  {$IFDEF FPC}
  ptr := paFloat(Round(SP_StackPtr^.Val));
  Ptr^ := Val;
  {$ELSE}
  paFloat(Round(SP_StackPtr^.Val))^ := Val;
  {$ENDIF}

  Dec(SP_StackPtr);

End;

Procedure SP_Interpret_KW_MEMWRITES(Var Info: pSP_iInfo);
Var
  Val: aString;
Begin

  Val := SP_StackPtr^.Str;
  Dec(SP_StackPtr);

  CopyMem(Pointer(Round(SP_StackPtr^.Val)), pByte(pNativeUInt(@Val)^), Length(Val));

End;

Initialization

  For Il := 0 To 9999 Do InterpretProcs[Il] := @SP_Interpret_UNHANDLED;

  // KeyWords

  InterpretProcs[SP_KW_ERROR] := @SP_Interpret_ERROR;
  InterpretProcs[SP_KW_UNDIM] := @SP_Interpret_UNDIM;
  InterpretProcs[SP_KW_IF] := @SP_Interpret_IF;
  InterpretProcs[SP_KW_ELSE] := @SP_Interpret_ELSE;
  InterpretProcs[SP_KW_PROC] := @SP_Interpret_PROC;
  InterpretProcs[SP_KW_ENDIF] := @SP_Interpret_ENDIF;
  InterpretProcs[SP_KW_TEXT] := @SP_Interpret_TEXT;
  InterpretProcs[SP_KW_PR_AT] := @SP_Interpret_PR_AT;
  InterpretProcs[SP_KW_PR_SCALE] := @SP_Interpret_PR_SCALE;
  InterpretProcs[SP_KW_PR_TAB] := @SP_Interpret_PR_TAB;
  InterpretProcs[SP_KW_PR_MOVE] := @SP_Interpret_PR_MOVE;
  InterpretProcs[SP_KW_PR_OVER] := @SP_Interpret_PR_OVER;
  InterpretProcs[SP_KW_PR_CENTRE] := @SP_Interpret_PR_CENTRE;
  InterpretProcs[SP_KW_PR_TRANSPARENT] := @SP_Interpret_PR_TRANSPARENT;
  InterpretProcs[SP_KW_INK] := @SP_Interpret_INK;
  InterpretProcs[SP_KW_PAPER] := @SP_Interpret_PAPER;
  InterpretProcs[SP_KW_INVERSE] := @SP_Interpret_INVERSE;
  InterpretProcs[SP_KW_ITALIC] := @SP_Interpret_ITALIC;
  InterpretProcs[SP_KW_BOLD] := @SP_Interpret_BOLD;
  InterpretProcs[SP_KW_OVER] := @SP_Interpret_OVER;
  InterpretProcs[SP_KW_TRANSPARENT] := @SP_Interpret_TRANSPARENT;
  InterpretProcs[SP_KW_SCALE] := @SP_Interpret_SCALE;
  InterpretProcs[SP_KW_PR_INK] := @SP_Interpret_PR_INK;
  InterpretProcs[SP_KW_PR_PAPER] := @SP_Interpret_PR_PAPER;
  InterpretProcs[SP_KW_PR_INVERSE] := @SP_Interpret_PR_INVERSE;
  InterpretProcs[SP_KW_PR_ITALIC] := @SP_Interpret_PR_ITALIC;
  InterpretProcs[SP_KW_PR_BOLD] := @SP_Interpret_PR_BOLD;
  InterpretProcs[SP_KW_LET] := @SP_Interpret_LET;
  InterpretProcs[SP_KW_ENUM_BASE] := @SP_Interpret_ENUM_BASE;
  InterpretProcs[SP_KW_ENUM] := @SP_Interpret_ENUM;
  InterpretProcs[SP_KW_CLS] := @SP_Interpret_CLS;
  InterpretProcs[SP_KW_DIM] := @SP_Interpret_DIM;
  InterpretProcs[SP_KW_AUTODIM] := @SP_Interpret_AUTODIM;
  InterpretProcs[SP_KW_DIM_SPLIT] := @SP_Interpret_DIM_SPLIT;
  InterpretProcs[SP_KW_RUN] := @SP_Interpret_RUN;
  InterpretProcs[SP_KW_GOTO] := @SP_Interpret_GOTO;
  InterpretProcs[SP_KW_GOSUB] := @SP_Interpret_GOSUB;
  InterpretProcs[SP_KW_CONTINUE] := @SP_Interpret_CONTINUE;
  InterpretProcs[SP_KW_RETURN] := @SP_Interpret_RETURN;
  InterpretProcs[SP_KW_STOP] := @SP_Interpret_STOP;
  InterpretProcs[SP_KW_FOR] := @SP_Interpret_FOR;
  InterpretProcs[SP_KW_NEXT] := @SP_Interpret_NEXT;
  InterpretProcs[SP_KW_PLOT] := @SP_Interpret_PLOT;
  InterpretProcs[SP_KW_PARTICLE] := @SP_Interpret_PARTICLE;
  InterpretProcs[SP_KW_FORCE] := @SP_Interpret_FORCE;
  InterpretProcs[SP_KW_PAUSE] := @SP_Interpret_PAUSE;
  InterpretProcs[SP_KW_DRAW] := @SP_Interpret_DRAW;
  InterpretProcs[SP_KW_DRAWTO] := @SP_Interpret_DRAWTO;
  InterpretProcs[SP_KW_CIRCLE] := @SP_Interpret_CIRCLE;
  InterpretProcs[SP_KW_ELLIPSE] := @SP_Interpret_ELLIPSE;
  InterpretProcs[SP_KW_CIRCLEFILL] := @SP_Interpret_CIRCLEFILL;
  InterpretProcs[SP_KW_ELLIPSEFILL] := @SP_Interpret_ELLIPSEFILL;
  InterpretProcs[SP_KW_CURVE] := @SP_Interpret_CURVE;
  InterpretProcs[SP_KW_CURVE_EX] := @SP_Interpret_CURVE_EX;
  InterpretProcs[SP_KW_RANDOMIZE] := @SP_Interpret_RANDOMIZE;
  InterpretProcs[SP_KW_SAVE] := @SP_Interpret_SAVE;
  InterpretProcs[SP_KW_SAVEASCII] := @SP_Interpret_SAVEASCII;
  InterpretProcs[SP_KW_SAVE_BANK] := @SP_Interpret_SAVE_BANK;
  InterpretProcs[SP_KW_LOAD] := @SP_Interpret_LOAD;
  InterpretProcs[SP_KW_LOAD_BANK] := @SP_Interpret_LOAD_BANK;
  InterpretProcs[SP_KW_MERGE] := @SP_Interpret_MERGE;
  InterpretProcs[SP_KW_INC] := @SP_Interpret_INC;
  InterpretProcs[SP_KW_INCRANGE] := @SP_Interpret_INCRANGE;
  InterpretProcs[SP_KW_DEC] := @SP_Interpret_DEC;
  InterpretProcs[SP_KW_DECRANGE] := @SP_Interpret_DECRANGE;
  InterpretProcs[SP_KW_PALETTE] := @SP_Interpret_PALETTE;
  InterpretProcs[SP_KW_PAL_HSV] := @SP_Interpret_PALETTE_HSV;
  InterpretProcs[SP_KW_PALSHIFT] := @SP_Interpret_PALETTESHIFT;
  InterpretProcs[SP_KW_DO] := @SP_Interpret_DO;
  InterpretProcs[SP_KW_DO_COUNT] := @SP_Interpret_DO_COUNT;
  InterpretProcs[SP_KW_LOOP] := @SP_Interpret_LOOP;
  InterpretProcs[SP_KW_UNTIL] := @SP_Interpret_UNTIL;
  InterpretProcs[SP_KW_WHILE] := @SP_Interpret_WHILE;
  InterpretProcs[SP_KW_EXIT] := @SP_Interpret_EXIT;
  InterpretProcs[SP_KW_QUIT] := @SP_Interpret_QUIT;
  InterpretProcs[SP_KW_READ] := @SP_Interpret_READ;
  InterpretProcs[SP_KW_READLINE] := @SP_Interpret_READ_LINE;
  InterpretProcs[SP_KW_READ_ASSIGN] := @SP_Interpret_READ_ASSIGN;
  InterpretProcs[SP_KW_RESTORE] := @SP_Interpret_RESTORE;
  InterpretProcs[SP_KW_SCR_LOCK] := @SP_Interpret_SCR_LOCK;
  InterpretProcs[SP_KW_SCR_UNLOCK] := @SP_Interpret_SCR_UNLOCK;
  InterpretProcs[SP_KW_SCR_UPDATE] := @SP_Interpret_SCR_UPDATE;
  InterpretProcs[SP_KW_FULLSCREEN] := @SP_Interpret_SCR_FULL;
  InterpretProcs[SP_KW_WINDOWED] := @SP_Interpret_SCR_WIN;
  InterpretProcs[SP_KW_SCR_RES] := @SP_Interpret_SCR_RES;
  InterpretProcs[SP_KW_WIN_NEW] := @SP_Interpret_WIN_NEW;
  InterpretProcs[SP_KW_WIN_MOVE] := @SP_Interpret_WIN_MOVE;
  InterpretProcs[SP_KW_WIN_SIZE] := @SP_Interpret_WIN_SIZE;
  InterpretProcs[SP_KW_WIN_SCROLL] := @SP_Interpret_WIN_SCROLL;
  InterpretProcs[SP_KW_WIN_ROLL] := @SP_Interpret_WIN_ROLL;
  InterpretProcs[SP_KW_WIN_DEL] := @SP_Interpret_WIN_ERASE;
  InterpretProcs[SP_KW_WIN_SHOW] := @SP_Interpret_WIN_SHOW;
  InterpretProcs[SP_KW_WIN_HIDE] := @SP_Interpret_WIN_HIDE;
  InterpretProcs[SP_KW_WIN_FRONT] := @SP_Interpret_WIN_FRONT;
  InterpretProcs[SP_KW_WIN_BACK] := @SP_Interpret_WIN_BACK;
  InterpretProcs[SP_KW_WINDOW] := @SP_Interpret_WINDOW;
  InterpretProcs[SP_KW_WINDOW_GFX] := @SP_Interpret_WINDOW_GFX;
  InterpretProcs[SP_KW_WIN_GRAB] := @SP_Interpret_WIN_GRAB;
  InterpretProcs[SP_KW_SCR_GRAB] := @SP_Interpret_SCR_GRAB;
  InterpretProcs[SP_KW_WIN_PUT] := @SP_Interpret_WIN_PUT;
  InterpretProcs[SP_KW_POKE] := @SP_Interpret_POKE;
  InterpretProcs[SP_KW_DPOKE] := @SP_Interpret_DPOKE;
  InterpretProcs[SP_KW_QPOKE] := @SP_Interpret_QPOKE;
  InterpretProcs[SP_KW_FPOKE] := @SP_Interpret_FPOKE;
  InterpretProcs[SP_KW_POKES] := @SP_Interpret_POKES;
  InterpretProcs[SP_KW_NEW] := @SP_Interpret_NEW;
  InterpretProcs[SP_KW_ON] := @SP_Interpret_ON;
  InterpretProcs[SP_KW_MENU_SHOW_OFF] := @SP_Interpret_MENU_SHOW_OFF;
  InterpretProcs[SP_KW_MENU_HIDE_OFF] := @SP_Interpret_MENU_HIDE_OFF;
  InterpretProcs[SP_KW_MENUITEM_OFF] := @SP_Interpret_MENUITEM_OFF;
  InterpretProcs[SP_KW_ON_MENU_SHOW] := @SP_Interpret_ON_MENU_SHOW;
  InterpretProcs[SP_KW_ON_MENU_HIDE] := @SP_Interpret_ON_MENU_HIDE;
  InterpretProcs[SP_KW_ON_MENUITEM] := @SP_Interpret_ON_MENUITEM;
  InterpretProcs[SP_KW_ON_ERR] := @SP_Interpret_ON_ERR;
  InterpretProcs[SP_KW_ON_COLLIDE] := @SP_Interpret_ON_COLLIDE;
  InterpretProcs[SP_KW_ON_MOUSEDOWN] := @SP_Interpret_ON_MOUSEDOWN;
  InterpretProcs[SP_KW_ON_MOUSEMOVE] := @SP_Interpret_ON_MOUSEMOVE;
  InterpretProcs[SP_KW_ON_MOUSEUP] := @SP_Interpret_ON_MOUSEUP;
  InterpretProcs[SP_KW_ON_WHEELUP] := @SP_Interpret_ON_WHEELUP;
  InterpretProcs[SP_KW_ON_WHEELDOWN] := @SP_Interpret_ON_WHEELDOWN;
  InterpretProcs[SP_KW_ON_KEYDOWN] := @SP_Interpret_ON_KEYDOWN;
  InterpretProcs[SP_KW_ON_KEYUP] := @SP_Interpret_ON_KEYUP;
  InterpretProcs[SP_KW_ON_ERR_OFF] := @SP_Interpret_ON_ERR_OFF;
  InterpretProcs[SP_KW_ON_COLLIDE_OFF] := @SP_Interpret_ON_COLLIDE_OFF;
  InterpretProcs[SP_KW_MOUSEDOWN_OFF] := @SP_Interpret_MOUSEDOWN_OFF;
  InterpretProcs[SP_KW_MOUSEMOVE_OFF] := @SP_Interpret_MOUSEMOVE_OFF;
  InterpretProcs[SP_KW_MOUSEUP_OFF] := @SP_Interpret_MOUSEUP_OFF;
  InterpretProcs[SP_KW_KEYDOWN_OFF] := @SP_Interpret_KEYDOWN_OFF;
  InterpretProcs[SP_KW_KEYUP_OFF] := @SP_Interpret_KEYUP_OFF;
  InterpretProcs[SP_KW_WHEELUP_OFF] := @SP_Interpret_WHEELUP_OFF;
  InterpretProcs[SP_KW_WHEELDOWN_OFF] := @SP_Interpret_WHEELDOWN_OFF;
  InterpretProcs[SP_KW_CLEAR] := @SP_Interpret_CLEAR;
  InterpretProcs[SP_KW_CLEAR_VAR] := @SP_Interpret_CLEAR_VAR;
  InterpretProcs[SP_KW_CLEAR_ERR] := @SP_Interpret_CLEAR_ERR;
  InterpretProcs[SP_KW_FILL] := @SP_Interpret_FILL;
  InterpretProcs[SP_KW_FILLTEX] := @SP_Interpret_FILLTEX;
  InterpretProcs[SP_KW_ARECTANGLE_TO] := @SP_Interpret_ARECTANGLE_TO;
  InterpretProcs[SP_KW_ARECTFILL_TO] := @SP_Interpret_ARECTFILL_TO;
  InterpretProcs[SP_KW_RECTANGLE_TO] := @SP_Interpret_RECTANGLE_TO;
  InterpretProcs[SP_KW_RECTFILL_TO] := @SP_Interpret_RECTFILL_TO;
  InterpretProcs[SP_KW_RECTANGLE] := @SP_Interpret_RECTANGLE;
  InterpretProcs[SP_KW_RECTFILL] := @SP_Interpret_RECTFILL;
  InterpretProcs[SP_KW_POLYLINE] := @SP_Interpret_POLYLINE;
  InterpretProcs[SP_KW_POLYFILL] := @SP_Interpret_POLYFILL;
  InterpretProcs[SP_KW_SCRCOPY] := @SP_Interpret_SCRCOPY;
  InterpretProcs[SP_KW_DEGREES] := @SP_Interpret_DEGREES;
  InterpretProcs[SP_KW_RADIANS] := @SP_Interpret_RADIANS;
  InterpretProcs[SP_KW_TURNS] := @SP_Interpret_TURNS;
  InterpretProcs[SP_KW_GRADIANS] := @SP_Interpret_GRADIANS;
  InterpretProcs[SP_KW_RECOVER] := @SP_Interpret_RECOVER;
  InterpretProcs[SP_KW_OLD] := @SP_Interpret_OLD;
  InterpretProcs[SP_KW_FONT] := @SP_Interpret_FONT;
  InterpretProcs[SP_KW_FONT_NEW] := @SP_Interpret_FONT_NEW;
  InterpretProcs[SP_KW_FONT_TRANS] := @SP_Interpret_FONT_TRANS;
  InterpretProcs[SP_KW_FONT_ERASE] := @SP_Interpret_FONT_ERASE;
  InterpretProcs[SP_KW_WAIT] := @SP_Interpret_WAIT;
  InterpretProcs[SP_KW_WAIT_KEY] := @SP_Interpret_WAIT_KEY;
  InterpretProcs[SP_KW_WAIT_KEY_PRESS] := @SP_Interpret_WAIT_KEY_PRESS;
  InterpretProcs[SP_KW_WAIT_KEY_UP] := @SP_Interpret_WAIT_KEY_UP;
  InterpretProcs[SP_KW_BANK] := @SP_Interpret_BANK_NEW;
  InterpretProcs[SP_KW_BANK_SIZE] := @SP_Interpret_BANK_SIZE;
  InterpretProcs[SP_KW_BANK_ERASE] := @SP_Interpret_BANK_ERASE;
  InterpretProcs[SP_KW_BANK_COPY] := @SP_Interpret_BANK_COPY;
  InterpretProcs[SP_KW_STREAM_NEW] := @SP_Interpret_STREAM_NEW;
  InterpretProcs[SP_KW_STREAM_READ] := @SP_Interpret_STREAM_READ;
  InterpretProcs[SP_KW_STREAM_READLN] := @SP_Interpret_STREAM_READLN;
  InterpretProcs[SP_KW_STREAM_READFILE] := @SP_Interpret_STREAM_READFILE;
  InterpretProcs[SP_KW_STREAM_WRITE] := @SP_Interpret_STREAM_WRITE;
  InterpretProcs[SP_KW_STREAM_SEEK] := @SP_Interpret_STREAM_SEEK;
  InterpretProcs[SP_KW_STREAM_CLOSE] := @SP_Interpret_STREAM_CLOSE;
  InterpretProcs[SP_KW_SETDIR] := @SP_Interpret_SETDIR;
  InterpretProcs[SP_KW_CD] := @SP_Interpret_SETDIR;
  InterpretProcs[SP_KW_PAL_LOAD] := @SP_Interpret_PAL_LOAD;
  InterpretProcs[SP_KW_PAL_SAVE] := @SP_Interpret_PAL_SAVE;
  InterpretProcs[SP_KW_PAL_DEFAULT] := @SP_Interpret_PAL_DEFAULT;
  InterpretProcs[SP_KW_PAL_EGA] := @SP_Interpret_PAL_EGA;
  InterpretProcs[SP_KW_PAL_CGA] := @SP_Interpret_PAL_CGA;
  InterpretProcs[SP_KW_PAL_APPLEHGR] := @SP_Interpret_PAL_APPLEHGR;
  InterpretProcs[SP_KW_PAL_APPLELGR] := @SP_Interpret_PAL_APPLELGR;
  InterpretProcs[SP_KW_PAL_CPC] := @SP_Interpret_PAL_CPC;
  InterpretProcs[SP_KW_EXECUTE] := @SP_Interpret_EXECUTE;
  InterpretProcs[SP_KW_ROTATE] := @SP_Interpret_ROTATE;
  InterpretProcs[SP_KW_ROTATETO] := @SP_Interpret_ROTATETO;
  InterpretProcs[SP_KW_FACE] := @SP_Interpret_FACE;
  InterpretProcs[SP_KW_MOVE] := @SP_Interpret_MOVE;
  InterpretProcs[SP_KW_DRMOVETO] := @SP_Interpret_MOVETO;
  InterpretProcs[SP_KW_DRMOVEXY] := @SP_Interpret_MOVEXY;
  InterpretProcs[SP_KW_DRAWTURTLE] := @SP_Interpret_DRAWTURTLE;
  InterpretProcs[SP_KW_SAMPLE_LOAD] := @SP_Interpret_SAMPLE_LOAD;
  InterpretProcs[SP_KW_SAMPLE_PLAY] := @SP_Interpret_SAMPLE_PLAY;
  InterpretProcs[SP_KW_SAMPLE_ERASE] := @SP_Interpret_SAMPLE_ERASE;
  InterpretProcs[SP_KW_SAMPLE_RATE] := @SP_Interpret_SAMPLE_RATE;
  InterpretProcs[SP_KW_SAMPLE_DEPTH] := @SP_Interpret_SAMPLE_DEPTH;
  InterpretProcs[SP_KW_SAMPLE_STEREO] := @SP_Interpret_SAMPLE_STEREO;
  InterpretProcs[SP_KW_SAMPLE_VOLUME] := @SP_Interpret_SAMPLE_VOLUME;
  InterpretProcs[SP_KW_SAMPLE_PAN] := @SP_Interpret_SAMPLE_PAN;
  InterpretProcs[SP_KW_SAMPLE_NEW] := @SP_Interpret_SAMPLE_NEW;
  InterpretProcs[SP_KW_CHANNEL_PAUSE] := @SP_Interpret_CHANNEL_PAUSE;
  InterpretProcs[SP_KW_CHANNEL_STOP] := @SP_Interpret_CHANNEL_STOP;
  InterpretProcs[SP_KW_CHANNEL_VOLUME] := @SP_Interpret_CHANNEL_VOLUME;
  InterpretProcs[SP_KW_CHANNEL_PAN] := @SP_Interpret_CHANNEL_PAN;
  InterpretProcs[SP_KW_CHANNEL_RESUME] := @SP_Interpret_CHANNEL_RESUME;
  InterpretProcs[SP_KW_CHANNEL_SEEK] := @SP_Interpret_CHANNEL_SEEK;
  InterpretProcs[SP_KW_CHANNEL_RATE_VAL] := @SP_Interpret_CHANNEL_RATE_VAL;
  InterpretProcs[SP_KW_CHANNEL_RATE_STR] := @SP_Interpret_CHANNEL_RATE_STR;
  InterpretProcs[SP_KW_PLAY] := @SP_Interpret_PLAY;
  InterpretProcs[SP_KW_PLAY_STOP] := @SP_Interpret_PLAY_STOP;
  InterpretProcs[SP_KW_MUSIC_PLAY] := @SP_Interpret_MUSIC_PLAY;
  InterpretProcs[SP_KW_MUSIC_PAUSE] := @SP_Interpret_MUSIC_PAUSE;
  InterpretProcs[SP_KW_MUSIC_STOP] := @SP_Interpret_MUSIC_STOP;
  InterpretProcs[SP_KW_MUSIC_VOLUME] := @SP_Interpret_MUSIC_VOLUME;
  InterpretProcs[SP_KW_MUSIC_RESUME] := @SP_Interpret_MUSIC_RESUME;
  InterpretProcs[SP_KW_MUSIC_SEEK] := @SP_Interpret_MUSIC_SEEK;
  InterpretProcs[SP_KW_BANK_COPY_EX] := @SP_Interpret_BANK_COPY_EX;
  InterpretProcs[SP_KW_DEF_PROC] := @SP_Interpret_DEF_PROC;
  InterpretProcs[SP_KW_ENDPROC] := @SP_Interpret_END_PROC;
  InterpretProcs[SP_KW_EXIT_PROC] := @SP_Interpret_EXIT_PROC;
  InterpretProcs[SP_KW_GLOBAL] := @SP_Interpret_GLOBAL;
  InterpretProcs[SP_KW_LOCAL] := @SP_Interpret_LOCAL;
  InterpretProcs[SP_KW_DEF_FN] := @SP_Interpret_DEF_FN;
  InterpretProcs[SP_KW_BANK_PROTECT] := @SP_Interpret_BANK_PROTECT;
  InterpretProcs[SP_KW_BANK_DEPROTECT] := @SP_Interpret_BANK_DEPROTECT;
  InterpretProcs[SP_KW_PRINT] := @SP_Interpret_PRINT;
  InterpretProcs[SP_KW_CAT] := @SP_Interpret_CAT;
  InterpretProcs[SP_KW_ERASE] := @SP_Interpret_ERASE;
  InterpretProcs[SP_KW_WIN_PUT_EX] := @SP_Interpret_WIN_PUT_EX;
  InterpretProcs[SP_KW_NEW_SPRITE] := @SP_Interpret_SPRITE_NEW;
  InterpretProcs[SP_KW_SPRITE_ADDFR] := @SP_Interpret_SPRITE_ADDFRAME;
  InterpretProcs[SP_KW_SPRITE_SHOW] := @SP_Interpret_SPRITE_SHOW;
  InterpretProcs[SP_KW_SPRITE_HIDE] := @SP_Interpret_SPRITE_HIDE;
  InterpretProcs[SP_KW_SPRITE_MOVE] := @SP_Interpret_SPRITE_MOVE;
  InterpretProcs[SP_KW_SPRITE_MOVED] := @SP_Interpret_SPRITE_MOVED;
  InterpretProcs[SP_KW_SPRITE_MOVE_T] := @SP_Interpret_SPRITE_MOVE_T;
  InterpretProcs[SP_KW_SPRITE_MOVED_T] := @SP_Interpret_SPRITE_MOVED_T;
  InterpretProcs[SP_KW_SPRITE_MOVE_S] := @SP_Interpret_SPRITE_MOVE_S;
  InterpretProcs[SP_KW_SPRITE_MOVED_S] := @SP_Interpret_SPRITE_MOVED_S;
  InterpretProcs[SP_KW_SPRITE_MOVE_WIN] := @SP_Interpret_SPRITE_MOVE_WIN;
  InterpretProcs[SP_KW_SPRITE_STOP] := @SP_Interpret_SPRITE_STOP;
  InterpretProcs[SP_KW_SPRITE_ROT] := @SP_Interpret_SPRITE_ROTATE;
  InterpretProcs[SP_KW_SPRITE_ROT_TO] := @SP_Interpret_SPRITE_ROTATE_TO;
  InterpretProcs[SP_KW_SPRITE_ROT_T] := @SP_Interpret_SPRITE_ROTATE_T;
  InterpretProcs[SP_KW_SPRITE_ROT_TO_T] := @SP_Interpret_SPRITE_ROTATE_TO_T;
  InterpretProcs[SP_KW_SPRITE_SCALE] := @SP_Interpret_SPRITE_SCALE;
  InterpretProcs[SP_KW_SPRITE_SCALE_T] := @SP_Interpret_SPRITE_SCALE_T;
  InterpretProcs[SP_KW_SPRITE_ERASE] := @SP_Interpret_SPRITE_ERASE;
  InterpretProcs[SP_KW_SPRITE_CLEAR] := @SP_Interpret_SPRITE_CLEAR;
  InterpretProcs[SP_KW_SPRITE_FRONT] := @SP_Interpret_SPRITE_FRONT;
  InterpretProcs[SP_KW_SPRITE_BACK] := @SP_Interpret_SPRITE_BACK;
  InterpretProcs[SP_KW_SPRITE_FRONT_ADD] := @SP_Interpret_SPRITE_FRONT_ADD;
  InterpretProcs[SP_KW_SPRITE_BACK_DEC] := @SP_Interpret_SPRITE_BACK_DEC;
  InterpretProcs[SP_KW_GFX_NEW_SIZE] := @SP_Interpret_GFX_NEW_SIZE;
  InterpretProcs[SP_KW_GFX_NEW_LOAD] := @SP_Interpret_GFX_NEW_LOAD;
  InterpretProcs[SP_KW_GFX_NEW_GFXS] := @SP_Interpret_GFX_NEW_GFXS;
  InterpretProcs[SP_KW_GFX_LOAD] := @SP_Interpret_GFX_LOAD;
  InterpretProcs[SP_KW_GFX_GRAB] := @SP_Interpret_GFX_GRAB;
  InterpretProcs[SP_KW_GFX_PUT] := @SP_Interpret_GFX_PUT;
  InterpretProcs[SP_KW_GFX_PUT_EX] := @SP_Interpret_GFX_PUT_EX;
  InterpretProcs[SP_KW_GFX_ROTATE] := @SP_Interpret_GFX_ROTATE;
  InterpretProcs[SP_KW_GFX_SCALE] := @SP_Interpret_GFX_SCALE;
  InterpretProcs[SP_KW_GFX_SCALE_TO] := @SP_Interpret_GFX_SCALE_TO;
  InterpretProcs[SP_KW_GFX_SCALE_XY] := @SP_Interpret_GFX_SCALE_XY;
  InterpretProcs[SP_KW_GFX_FLIP] := @SP_Interpret_GFX_FLIP;
  InterpretProcs[SP_KW_GFX_MIRROR] := @SP_Interpret_GFX_MIRROR;
  InterpretProcs[SP_KW_GFX_FLIP_STR] := @SP_Interpret_GFX_FLIP_STR;
  InterpretProcs[SP_KW_GFX_MIRROR_STR] := @SP_Interpret_GFX_MIRROR_STR;
  InterpretProcs[SP_KW_GFX_ERASE] := @SP_Interpret_GFX_ERASE;
  InterpretProcs[SP_KW_GFX_TRANSPARENT] := @SP_Interpret_GFX_TRANSPARENT;
  InterpretProcs[SP_KW_GFX_PALETTE] := @SP_Interpret_GFX_PALETTE;
  InterpretProcs[SP_KW_GFX_PAL_HSV] := @SP_Interpret_GFX_PAL_HSV;
  InterpretProcs[SP_KW_GFX_PAL_DEFAULT] := @SP_Interpret_GFX_PAL_DEFAULT;
  InterpretProcs[SP_KW_GFX_REMAP] := @SP_Interpret_GFX_REMAP;
  InterpretProcs[SP_KW_PAL_COPY] := @SP_Interpret_PAL_COPY;
  InterpretProcs[SP_KW_RENUMBER] := @SP_Interpret_RENUMBER;
  InterpretProcs[SP_KW_ERASE_LINES] := @SP_Interpret_ERASE_LINES;
  InterpretProcs[SP_KW_LIST] := @SP_Interpret_LIST;
  InterpretProcs[SP_KW_LIST_LINES] := @SP_Interpret_LIST_LINES;
  InterpretProcs[SP_KW_PACK_NEW] := @SP_Interpret_PACKAGE_NEW;
  InterpretProcs[SP_KW_ASSIGN] := @SP_Interpret_ASSIGN;
  InterpretProcs[SP_KW_COPY] := @SP_Interpret_COPY;
  InterpretProcs[SP_KW_MOVE_FILES] := @SP_Interpret_MOVE_FILES;
  InterpretProcs[SP_KW_MAKEDIR] := @SP_Interpret_MAKEDIR;
  InterpretProcs[SP_KW_RENAME] := @SP_Interpret_RENAME;
  InterpretProcs[SP_KW_PACK_ADD] := @SP_Interpret_PACK_ADD;
  InterpretProcs[SP_KW_PACK_CLOSE] := @SP_Interpret_PACK_CLOSE;
  InterpretProcs[SP_KW_PACK_PROTECT] := @SP_Interpret_PACK_PROTECT;
  InterpretProcs[SP_KW_PACK_UNPROTECT] := @SP_Interpret_PACK_UNPROTECT;
  InterpretProcs[SP_KW_PACKAGE] := @SP_Interpret_PACKAGE;
  InterpretProcs[SP_KW_DATA_SAVE] := @SP_Interpret_DATA_SAVE;
  InterpretProcs[SP_KW_DATA_LOAD] := @SP_Interpret_DATA_LOAD;
  InterpretProcs[SP_KW_MERGE_LINES] := @SP_Interpret_MERGE_LINES;
  InterpretProcs[SP_KW_GFX_ROLL] := @SP_Interpret_GRAPHIC_ROLL;
  InterpretProcs[SP_KW_GFX_SCROLL] := @SP_Interpret_GRAPHIC_SCROLL;
  InterpretProcs[SP_KW_TILEMAP_NEW] := @SP_Interpret_TILEMAP_NEW;
  InterpretProcs[SP_KW_TILEMAP_DRAW] := @SP_Interpret_TILEMAP_DRAW;
  InterpretProcs[SP_KW_TILEMAP_SET] := @SP_Interpret_TILEMAP_SET;
  InterpretProcs[SP_KW_TILEMAP_GRAPHIC] := @SP_Interpret_TILEMAP_GRAPHIC;
  InterpretProcs[SP_KW_TILEMAP_CLEAR] := @SP_Interpret_TILEMAP_CLEAR;
  InterpretProcs[SP_KW_SAVE_BANK_DATA] := @SP_Interpret_SAVE_BANK_DATA;
  InterpretProcs[SP_KW_LIST_BANK] := @SP_Interpret_LIST_BANK;
  InterpretProcs[SP_KW_LIST_WINDOW] := @SP_Interpret_LIST_WINDOW;
  InterpretProcs[SP_KW_LIST_VAR] := @SP_Interpret_LIST_VAR;
  InterpretProcs[SP_KW_LIST_ARRAY] := @SP_Interpret_LIST_ARRAY;
  InterpretProcs[SP_KW_LIST_ASSIGN] := @SP_Interpret_LIST_ASSIGN;
  InterpretProcs[SP_KW_LIST_BANK_EX] := @SP_Interpret_LIST_BANK_EX;
  interpretProcs[SP_KW_BANK_ERASE_ALL] := @SP_Interpret_BANK_ERASE_ALL;
  InterpretProcs[SP_KW_DEF_STRUCT] := @SP_Interpret_DEF_STRUCT;
  InterpretProcs[SP_KW_LIST_STRUCT] := @SP_Interpret_LIST_STRUCT;
  InterpretProcs[SP_KW_STRUCT_ERASE] := @SP_Interpret_STRUCT_ERASE;
  InterpretProcs[SP_KW_PR_CURSOR] := @SP_Interpret_PR_CURSOR;
  InterpretProcs[SP_KW_INIT_INPUT] := @SP_Interpret_INIT_INPUT;
  InterpretProcs[SP_KW_INPUT_FORMAT] := @SP_Interpret_INPUT_FORMAT;
  InterpretProcs[SP_KW_INPUT_NUM] := @SP_Interpret_INPUT_NUM;
  InterpretProcs[SP_KW_INPUT_STR] := @SP_Interpret_INPUT_STR;
  InterpretProcs[SP_KW_INPUT_FINAL] := @SP_Interpret_INPUT_FINAL;
  InterpretProcs[SP_KW_INPUT_ERROR] := @SP_Interpret_INPUT_ERROR;
  InterpretProcs[SP_KW_FOR_EACH] := @SP_Interpret_FOR_EACH;
  InterpretProcs[SP_KW_MOUSE_SHOW] := @SP_Interpret_MOUSE_SHOW;
  InterpretProcs[SP_KW_MOUSE_HIDE] := @SP_Interpret_MOUSE_HIDE;
  InterpretProcs[SP_KW_MOUSE_GRAPHIC] := @SP_Interpret_MOUSE_GRAPHIC;
  InterpretProcs[SP_KW_MOUSE_GFXS] := @SP_Interpret_MOUSE_GFXS;
  InterpretProcs[SP_KW_MOUSE_DEFAULT] := @SP_Interpret_MOUSE_DEFAULT;
  InterpretProcs[SP_KW_MOUSE_TO] := @SP_Interpret_MOUSE_TO;
  InterpretProcs[SP_KW_DEBUG] := @SP_Interpret_DEBUG;
  InterpretProcs[SP_KW_FPS] := @SP_Interpret_FPS;
  InterpretProcs[SP_KW_PUSH] := @SP_Interpret_PUSH;
  InterpretProcs[SP_KW_VOLUME] := @SP_Interpret_VOLUME;
  InterpretProcs[SP_KW_OPTION] := @SP_Interpret_OPTION;
  InterpretProcs[SP_KW_SETNUB] := @SP_Interpret_SETNUB;
  InterpretProcs[SP_KW_SETCPU] := @SP_Interpret_SETCPU;
  InterpretProcs[SP_KW_MULTIPLOT] := @SP_Interpret_MULTIPLOT;
  InterpretProcs[SP_KW_PROJECT3D] := @SP_Interpret_PROJECT3D;
  InterpretProcs[SP_KW_TRANSFORM3D] := @SP_Interpret_TRANSFORM3D;
  InterpretProcs[SP_KW_TRANSFORM2D] := @SP_Interpret_TRANSFORM2D;
  InterpretProcs[SP_KW_RAINBOW] := @SP_Interpret_RAINBOW;
  InterpretProcs[SP_KW_RAINBOW_HSV] := @SP_Interpret_RAINBOW_HSV;
  InterpretProcs[SP_KW_KEYBOARD] := @SP_Interpret_KEYBOARD;
  InterpretProcs[SP_KW_WIN_ORG_FLIP] := @SP_Interpret_WIN_ORG_FLIP;
  InterpretProcs[SP_KW_ORIGIN_FLIP] := @SP_Interpret_ORIGIN_FLIP;
  InterpretProcs[SP_KW_WIN_ORIGIN] := @SP_Interpret_WIN_ORIGIN;
  InterpretProcs[SP_KW_YIELD] := @SP_Interpret_YIELD;
  InterpretProcs[SP_KW_GFX_ORIGIN] := @SP_Interpret_GFX_ORIGIN;
  InterpretProcs[SP_KW_WIN_ORG_NO_EXT] := @SP_Interpret_WIN_ORG_NO_EXT;
  InterpretProcs[SP_KW_GFX_ORG_NO_EXT] := @SP_Interpret_GFX_ORG_NO_EXT;
  InterpretProcs[SP_KW_WIN_ORG_OFF] := @SP_Interpret_WIN_ORG_OFF;
  InterpretProcs[SP_KW_GFX_ORG_OFF] := @SP_Interpret_GFX_ORG_OFF;
  InterpretProcs[SP_KW_GFX_ORG_DIM] := @SP_Interpret_GFX_ORG_DIM;
  InterpretProcs[SP_KW_WIN_ORG_DIM] := @SP_Interpret_WIN_ORG_DIM;
  InterpretProcs[SP_KW_PR_CLIP] := @SP_Interpret_PR_CLIP;
  InterpretProcs[SP_KW_PR_CLIP_OFF] := @SP_Interpret_PR_CLIP_OFF;
  InterpretProcs[SP_KW_CLIP] := @SP_Interpret_CLIP;
  InterpretProcs[SP_KW_CLIP_OFF] := @SP_Interpret_CLIP_OFF;
  InterpretProcs[SP_KW_ORIGIN] := @SP_Interpret_ORIGIN;
  InterpretProcs[SP_KW_ORG_OFF] := @SP_Interpret_ORG_OFF;
  InterpretProcs[SP_KW_ORG_NO_EXT] := @SP_Interpret_ORG_NO_EXT;
  InterpretProcs[SP_KW_ORG_DIM] := @SP_Interpret_ORG_DIM;
  InterpretProcs[SP_KW_WIN_CLIP] := @SP_Interpret_WIN_CLIP;
  InterpretProcs[SP_KW_GFX_CLIP] := @SP_Interpret_GFX_CLIP;
  InterpretProcs[SP_KW_WIN_CLIP_OFF] := @SP_Interpret_WIN_CLIP_OFF;
  InterpretProcs[SP_KW_GFX_CLIP_OFF] := @SP_Interpret_GFX_CLIP_OFF;
  InterpretProcs[SP_KW_SPRITE_CLONE] := @SP_Interpret_SPRITE_CLONE;
  InterpretProcs[SP_KW_SPRITE_CLONE_ERASE] := @SP_Interpret_SPRITE_CLONE_ERASE;
  InterpretProcs[SP_KW_SPRITE_CLONE_MOVE] := @SP_Interpret_SPRITE_CLONE_MOVE;
  InterpretProcs[SP_KW_BEEP] := @SP_Interpret_BEEP;
  InterpretProcs[SP_KW_DRAW_CTO] := @SP_Interpret_DRAW_CTO;
  InterpretProcs[SP_KW_PR_OUT_VAR] := @SP_Interpret_PR_OUT_VAR;
  InterpretProcs[SP_KW_PR_OUT_SCREEN] := @SP_Interpret_PR_OUT_SCREEN;
  InterpretProcs[SP_KW_PR_OUT_STREAM] := @SP_Interpret_PR_OUT_STREAM;
  InterpretProcs[SP_KW_OUT_VAR] := @SP_Interpret_OUT_VAR;
  InterpretProcs[SP_KW_OUT_SCREEN] := @SP_Interpret_OUT_SCREEN;
  InterpretProcs[SP_KW_OUT_STREAM] := @SP_Interpret_OUT_STREAM;
  InterpretProcs[SP_KW_FOR_EACH_RANGE] := @SP_Interpret_FOR_EACH_RANGE;
  InterpretProcs[SP_KW_FOR_EACH_STRING] := @SP_Interpret_FOR_EACH_STRING;
  InterpretProcs[SP_KW_WIN_MERGE] := @SP_Interpret_WIN_MERGE;
  InterpretProcs[SP_KW_WIN_MERGEALL] := @SP_Interpret_WIN_MERGEALL;
  InterpretProcs[SP_KW_CASE] := @SP_Interpret_CASE;
  InterpretProcs[SP_KW_WHEN] := @SP_Interpret_WHEN;
  InterpretProcs[SP_KW_OTHERWISE] := @SP_Interpret_OTHERWISE;
  InterpretProcs[SP_KW_END_CASE] := @SP_Interpret_END_CASE;
  InterpretProcs[SP_KW_INCLUDE] := @SP_Interpret_INCLUDE;
  InterpretProcs[SP_KW_HALT] := @SP_Interpret_HALT;
  InterpretProcs[SP_KW_SORT] := @SP_Interpret_SORT;
  InterpretProcs[SP_KW_WHEN_IN] := @SP_Interpret_WHEN_IN;
  InterpretProcs[SP_KW_KEY] := @SP_Interpret_KEY;
  InterpretProcs[SP_KW_KEY_CLEAR] := @SP_Interpret_KEY_CLEAR;
  InterpretProcs[SP_KW_KEY_CLEAR_ALL] := @SP_Interpret_KEY_CLEAR_ALL;
  InterpretProcs[SP_KW_DYNAMIC_DIM] := @SP_Interpret_DYNAMIC_DIM;
  InterpretProcs[SP_KW_MAT] := @SP_Interpret_MAT;
  InterpretProcs[SP_KW_MAT_ZER] := @SP_Interpret_MAT_ZER;
  InterpretProcs[SP_KW_MAT_IDN] := @SP_Interpret_MAT_IDN;
  InterpretProcs[SP_KW_MAT_IDN_PARAM] := @SP_Interpret_MAT_IDN_PARAM;
  InterpretProcs[SP_KW_MAT_CON] := @SP_Interpret_MAT_CON;
  InterpretProcs[SP_KW_MAT_CON_PARAM] := @SP_Interpret_MAT_CON_PARAM;
  InterpretProcs[SP_KW_MAT_INV] := @SP_Interpret_MAT_INV;
  InterpretProcs[SP_KW_MAT_TRN] := @SP_Interpret_MAT_TRN;
  InterpretProcs[SP_KW_MAT_ADD] := @SP_Interpret_MAT_ADD;
  InterpretProcs[SP_KW_MAT_SUB] := @SP_Interpret_MAT_SUB;
  InterpretProcs[SP_KW_MAT_PROD] := @SP_Interpret_MAT_PROD;
  InterpretProcs[SP_KW_MAT_SCALE] := @SP_Interpret_MAT_SCALE;
  InterpretProcs[SP_KW_MAT_INTERP] := @SP_Interpret_MAT_INTERP;
  InterpretProcs[SP_KW_SPRITE_POINT] := @SP_Interpret_SPRITE_POINT;
  InterpretProcs[SP_KW_SPRITE_SET_ANIM] := @SP_Interpret_SPRITE_SET_ANIM;
  InterpretProcs[SP_KW_SPRITE_ANIM_STOP] := @SP_Interpret_SPRITE_ANIM_STOP;
  InterpretProcs[SP_KW_SPRITE_FRAME] := @SP_Interpret_SPRITE_FRAME;
  InterpretProcs[SP_KW_SPRITE_MIRROR] := @SP_Interpret_SPRITE_MIRROR;
  InterpretProcs[SP_KW_SPRITE_FLIP] := @SP_Interpret_SPRITE_FLIP;
  InterpretProcs[SP_KW_SPRITE_COLLIDE_CLEAR] := @SP_Interpret_SPRITE_COLLIDE_CLEAR;
  InterpretProcs[SP_KW_SPRITE_COLL_CLR_ID] := @SP_Interpret_SPRITE_COLLIDE_CLEAR_ID;
  InterpretProcs[SP_KW_NEW_BANK] := @SP_Interpret_NEW_BANK;
  InterpretProcs[SP_KW_SPRITE_PUT] := @SP_Interpret_SPRITE_PUT;
  InterpretProcs[SP_KW_SPRITE_OVER] := @SP_Interpret_SPRITE_OVER;
  InterpretProcs[SP_KW_ZONE_NEW] := @SP_Interpret_ZONE_NEW;
  InterpretProcs[SP_KW_ZONE_NEW_B] := @SP_Interpret_ZONE_NEW_B;
  InterpretProcs[SP_KW_ZONE_MOVE] := @SP_Interpret_ZONE_MOVE;
  InterpretProcs[SP_KW_ZONE_MOVETO] := @SP_Interpret_ZONE_MOVETO;
  InterpretProcs[SP_KW_ZONE_UPDATE] := @SP_Interpret_ZONE_UPDATE;
  InterpretProcs[SP_KW_ZONE_UPDATE] := @SP_Interpret_ZONE_UPDATE_B;
  InterpretProcs[SP_KW_ZONE_ERASE] := @SP_Interpret_ZONE_ERASE;
  InterpretProcs[SP_KW_RECTANGLE2] := @SP_Interpret_RECTANGLE2;
  InterpretProcs[SP_KW_RECTFILL2] := @SP_Interpret_RECTFILL2;
  InterpretProcs[SP_KW_PR_USING] := @SP_Interpret_PR_USING;
  InterpretProcs[SP_KW_PR_CENTRE_OFF] := @SP_Interpret_PR_CENTRE_OFF;
  InterpretProcs[SP_KW_WIN_TRANS] := @SP_Interpret_WIN_TRANS;
  InterpretProcs[SP_KW_WIN_ALPHA] := @SP_Interpret_WIN_ALPHA;
  InterpretProcs[SP_KW_WIN_DEPTH] := @SP_Interpret_WIN_DEPTH;
  InterpretProcs[SP_KW_ADRAWTO] := @SP_Interpret_ADRAWTO;
  InterpretProcs[SP_KW_ADRAWTURTLE] := @SP_Interpret_ADRAWTURTLE;
  InterpretProcs[SP_KW_ACIRCLEFILL] := @SP_Interpret_ACIRCLEFILL;
  InterpretProcs[SP_KW_AELLIPSEFILL] := @SP_Interpret_AELLIPSEFILL;
  InterpretProcs[SP_KW_AFILLTEX] := @SP_Interpret_AFILLTEX;
  InterpretProcs[SP_KW_ARECTFILL] := @SP_Interpret_ARECTFILL;
  InterpretProcs[SP_KW_ARECTANGLE2] := @SP_Interpret_ARECTANGLE2;
  InterpretProcs[SP_KW_ARECTFILL2] := @SP_Interpret_ARECTFILL2;
  InterpretProcs[SP_KW_APOLYLINE] := @SP_Interpret_APOLYLINE;
  InterpretProcs[SP_KW_APOLYFILL] := @SP_Interpret_APOLYFILL;
  InterpretProcs[SP_KW_ACIRCLE] := @SP_Interpret_ACIRCLE;
  InterpretProcs[SP_KW_APLOT] := @SP_Interpret_APLOT;
  InterpretProcs[SP_KW_ADRAW] := @SP_Interpret_ADRAW;
  InterpretProcs[SP_KW_AELLIPSE] := @SP_Interpret_AELLIPSE;
  InterpretProcs[SP_KW_ACURVE] := @SP_Interpret_ACURVE;
  InterpretProcs[SP_KW_AFILL] := @SP_Interpret_AFILL;
  InterpretProcs[SP_KW_ARECTANGLE] := @SP_Interpret_ARECTANGLE;
  InterpretProcs[SP_KW_AMULTIPLOT] := @SP_Interpret_AMULTIPLOT;
  InterpretProcs[SP_KW_ADRAW_CTO] := @SP_Interpret_ADRAW_CTO;
  InterpretProcs[SP_KW_APRINT] := @SP_Interpret_APRINT;
  InterpretProcs[SP_KW_ATEXT] := @SP_Interpret_ATEXT;
  InterpretProcs[SP_KW_ACURVE_EX] := @SP_Interpret_ACURVE_EX;
  InterpretProcs[SP_KW_FILTER_STR] := @SP_Interpret_FILTER_STR;
  InterpretProcs[SP_KW_FILTER_NUM_R] := @SP_Interpret_FILTER_NUM_R;
  InterpretProcs[SP_KW_FILTER_NUM] := @SP_Interpret_FILTER_NUM;
  InterpretProcs[SP_KW_GOTOC] := @SP_Interpret_GOTOC;
  InterpretProcs[SP_KW_GOSUBC] := @SP_Interpret_GOSUBC;
  InterpretProcs[SP_KW_MENU_NEW] := @SP_Interpret_MENU_NEW;
  InterpretProcs[SP_KW_MENU_ADD_ITEM] := @SP_Interpret_MENU_ADD_ITEM;
  InterpretProcs[SP_KW_MENU_INSITEM] := @SP_Interpret_MENU_INSITEM;
  InterpretProcs[SP_KW_MENU_DELITEM] := @SP_Interpret_MENU_DELITEM;
  InterpretProcs[SP_KW_MENU_ADDSUB] := @SP_Interpret_MENU_ADDSUB;
  InterpretProcs[SP_KW_MENU_DELSUB] := @SP_Interpret_MENU_DELSUB;
  InterpretProcs[SP_KW_MENU_SHOW] := @SP_Interpret_MENU_SHOW;
  InterpretProcs[SP_KW_MENU_HIDE] := @SP_Interpret_MENU_HIDE;
  InterpretProcs[SP_KW_MENU_ERASE_ALL] := @SP_Interpret_MENU_ERASE_ALL;
  InterpretProcs[SP_KW_MENU_ERASE] := @SP_Interpret_MENU_ERASE;
  InterpretProcs[SP_KW_MENUITEM_ATTR] := @SP_Interpret_MENUITEM_ATTR;
  InterpretProcs[SP_KW_MENU_ATTR] := @SP_Interpret_MENU_ATTR;
  InterpretProcs[SP_KW_MENU_FONT] := @SP_Interpret_MENU_FONT;
  InterpretProcs[SP_KW_MEMWRITE] := @SP_Interpret_KW_MEMWRITE;
  InterpretProcs[SP_KW_MEMWRITED] := @SP_Interpret_KW_MEMWRITED;
  InterpretProcs[SP_KW_MEMWRITEQ] := @SP_Interpret_KW_MEMWRITEQ;
  InterpretProcs[SP_KW_MEMWRITEF] := @SP_Interpret_KW_MEMWRITEF;
  InterpretProcs[SP_KW_MEMWRITES] := @SP_Interpret_KW_MEMWRITES;
  InterpretProcs[SP_KW_CLS_ALPHA] := @SP_Interpret_KW_CLS_ALPHA;
  InterpretProcs[SP_KW_MULTIDRAW] := @SP_Interpret_MULTIDRAW;
  InterpretProcs[SP_KW_MULTIDRAW_TO] := @SP_Interpret_MULTIDRAW_TO;
  InterpretProcs[SP_KW_AMULTIDRAW] := @SP_Interpret_AMULTIDRAW;
  InterpretProcs[SP_KW_AMULTIDRAW_TO] := @SP_Interpret_AMULTIDRAW_TO;
  InterpretProcs[SP_KW_INPUT_ERR_RPT] := @SP_Interpret_INPUT_ERR_RPT;
  InterpretProcs[SP_KW_WINDOW_MIRROR] := @SP_Interpret_WINDOW_MIRROR;
  InterpretProcs[SP_KW_WINDOW_FLIP] := @SP_Interpret_WINDOW_FLIP;
  InterpretProcs[SP_KW_INSTALL] := @SP_Interpret_INSTALL;
  InterpretProcs[SP_KW_SCREEN_SAVE] := @SP_Interpret_SCREEN_SAVE;
  InterpretProcs[SP_KW_GRAPHIC_SAVE] := @SP_Interpret_GRAPHIC_SAVE;
  InterpretProcs[SP_KW_COMPILE] := @SP_Interpret_COMPILE;
  InterpretProcs[SP_KW_DRAW_GW] := @SP_Interpret_DRAW_GW;

  // Functions

  InterpretProcs[SP_FN_ITEM] := @SP_Interpret_FN_ITEM;
  InterpretProcs[SP_FN_GPOINT] := @SP_Interpret_FN_GPOINT;
  InterpretProcs[SP_FN_GRGB] := @SP_Interpret_FN_GRGB;
  InterpretProcs[SP_FN_GHSV] := @SP_Interpret_FN_GHSV;
  InterpretProcs[SP_FN_WINX] := @SP_Interpret_FN_WINX;
  InterpretProcs[SP_FN_WINY] := @SP_Interpret_FN_WINY;
  InterpretProcs[SP_FN_GFXW] := @SP_Interpret_FN_GFXW;
  InterpretProcs[SP_FN_GFXH] := @SP_Interpret_FN_GFXH;
  InterpretProcs[SP_FN_GFXT] := @SP_Interpret_FN_GFXT;
  InterpretProcs[SP_FN_GFXS] := @SP_Interpret_FN_GFXS;
  InterpretProcs[SP_FN_TIME] := @SP_Interpret_FN_TIME;
  InterpretProcs[SP_FN_DAYS] := @SP_Interpret_FN_DAYS;
  InterpretProcs[SP_FN_MONTHS] := @SP_Interpret_FN_MONTHS;
  InterpretProcs[SP_FN_DAY] := @SP_Interpret_FN_DAY;
  InterpretProcs[SP_FN_MONTH] := @SP_Interpret_FN_MONTH;
  InterpretProcs[SP_FN_YEAR] := @SP_Interpret_FN_YEAR;
  InterpretProcs[SP_FN_HOUR] := @SP_Interpret_FN_HOUR;
  InterpretProcs[SP_FN_MINUTES] := @SP_Interpret_FN_MINUTES;
  InterpretProcs[SP_FN_SECONDS] := @SP_Interpret_FN_SECONDS;
  InterpretProcs[SP_FN_MILLISECONDS] := @SP_Interpret_FN_MILLISECONDS;
  InterpretProcs[SP_FN_FRAMES] := @SP_Interpret_FN_FRAMES;
  InterpretProcs[SP_FN_SPFRADDR] := @SP_Interpret_FN_SPFRADDR;
  InterpretProcs[SP_FN_SPRITEX] := @SP_Interpret_FN_SPRITEX;
  InterpretProcs[SP_FN_SPRITEY] := @SP_Interpret_FN_SPRITEY;
  InterpretProcs[SP_FN_SPRITEW] := @SP_Interpret_FN_SPRITEW;
  InterpretProcs[SP_FN_SPRITEH] := @SP_Interpret_FN_SPRITEH;
  InterpretProcs[SP_FN_SPVISIBLE] := @SP_Interpret_FN_SPVISIBLE;
  InterpretProcs[SP_FN_SPFCOUNT] := @SP_Interpret_FN_SPFCOUNT;
  InterpretProcs[SP_FN_SPROT] := @SP_Interpret_FN_SPROT;
  InterpretProcs[SP_FN_SPSCALE] := @SP_Interpret_FN_SPSCALE;
  InterpretProcs[SP_FN_CALL] := @SP_Interpret_FN_CALL;
  InterpretProcs[SP_FN_FN] := @SP_Interpret_FN_FN;
  InterpretProcs[SP_FN_GETDIR] := @SP_Interpret_FN_GETDIR;
  InterpretProcs[SP_FN_DIR] := @SP_Interpret_FN_GETDIR;
  InterpretProcs[SP_FN_BSIZE] := @SP_Interpret_FN_BSIZE;
  InterpretProcs[SP_FN_SLEN] := @SP_Interpret_FN_SLEN;
  InterpretProcs[SP_FN_SPOS] := @SP_Interpret_FN_SPOS;
  InterpretProcs[SP_FN_FONTBANK] := @SP_Interpret_FN_FONTBANK;
  InterpretProcs[SP_FN_FONTWIDTH] := @SP_Interpret_FN_FONTWIDTH;
  InterpretProcs[SP_FN_FONTHEIGHT] := @SP_Interpret_FN_FONTHEIGHT;
  InterpretProcs[SP_FN_FONTMODE] := @SP_Interpret_FN_FONTMODE;
  InterpretProcs[SP_FN_FONTTRANSPARENT] := @SP_Interpret_FN_FONTTRANSPARENT;
  InterpretProcs[SP_FN_LASTK] := @SP_Interpret_FN_LASTK;
  InterpretProcs[SP_FN_RADTODEG] := @SP_Interpret_FN_RADTODEG;
  InterpretProcs[SP_FN_DEGTORAD] := @SP_Interpret_FN_DEGTORAD;
  InterpretProcs[SP_FN_ERROR_NUM] := @SP_Interpret_FN_ERROR_NUM;
  InterpretProcs[SP_FN_ERROR_LIN] := @SP_Interpret_FN_ERROR_LIN;
  InterpretProcs[SP_FN_ERROR_STA] := @SP_Interpret_FN_ERROR_STA;
  InterpretProcs[SP_FN_MOUSEX] := @SP_Interpret_FN_MOUSEX;
  InterpretProcs[SP_FN_MOUSEWHEEL] := @SP_Interpret_FN_MOUSEWHEEL;
  InterpretProcs[SP_FN_DRPOSX] := @SP_Interpret_FN_DRPOSX;
  InterpretProcs[SP_FN_DRPOSY] := @SP_Interpret_FN_DRPOSY;
  InterpretProcs[SP_FN_MOUSEY] := @SP_Interpret_FN_MOUSEY;
  InterpretProcs[SP_FN_MOUSEDX] := @SP_Interpret_FN_MOUSEDX;
  InterpretProcs[SP_FN_MOUSEDY] := @SP_Interpret_FN_MOUSEDY;
  InterpretProcs[SP_FN_MOUSEBTN] := @SP_Interpret_FN_MOUSEBTN;
  InterpretProcs[SP_FN_RND] := @SP_Interpret_FN_RND;
  InterpretProcs[SP_FN_STK] := @SP_Interpret_FN_STK;
  InterpretProcs[SP_FN_STKS] := @SP_Interpret_FN_STKS;
  InterpretProcs[SP_FN_CLIPS] := @SP_Interpret_FN_CLIPS;
  InterpretProcs[SP_FN_INKEYS] := @SP_Interpret_FN_INKEYS;
  InterpretProcs[SP_FN_KEY] := @SP_Interpret_FN_KEY;
  InterpretProcs[SP_FN_PI] := @SP_Interpret_FN_PI;
  InterpretProcs[SP_FN_TAU] := @SP_Interpret_FN_TAU;
  InterpretProcs[SP_FN_HEADING] := @SP_Interpret_FN_HEADING;
  InterpretProcs[SP_FN_POINT] := @SP_Interpret_FN_POINT;
  InterpretProcs[SP_FN_VALS] := @SP_Interpret_FN_VALS;
  InterpretProcs[SP_FN_UPS] := @SP_Interpret_FN_UPS;
  InterpretProcs[SP_FN_LOWS] := @SP_Interpret_FN_LOWS;
  InterpretProcs[SP_FN_LEFTS] := @SP_Interpret_FN_LEFTS;
  InterpretProcs[SP_FN_WINOFF] := @SP_Interpret_FN_WINOFF;
  InterpretProcs[SP_FN_MIDS] := @SP_Interpret_FN_MIDS;
  InterpretProcs[SP_FN_MID] := @SP_Interpret_FN_MID;
  InterpretProcs[SP_FN_RIGHTS] := @SP_Interpret_FN_RIGHTS;
  InterpretProcs[SP_FN_REPS] := @SP_Interpret_FN_REPS;
  InterpretProcs[SP_FN_CODE] := @SP_Interpret_FN_CODE;
  InterpretProcs[SP_FN_DCODE] := @SP_Interpret_FN_DCODE;
  InterpretProcs[SP_FN_QCODE] := @SP_Interpret_FN_QCODE;
  InterpretProcs[SP_FN_FCODE] := @SP_Interpret_FN_FCODE;
  InterpretProcs[SP_FN_VAL] := @SP_Interpret_FN_VAL;
  InterpretProcs[SP_FN_LEN] := @SP_Interpret_FN_LEN;
  InterpretProcs[SP_FN_SIN] := @SP_Interpret_FN_SIN;
  InterpretProcs[SP_FN_COS] := @SP_Interpret_FN_COS;
  InterpretProcs[SP_FN_TAN] := @SP_Interpret_FN_TAN;
  InterpretProcs[SP_FN_ASN] := @SP_Interpret_FN_ASN;
  InterpretProcs[SP_FN_ACS] := @SP_Interpret_FN_ACS;
  InterpretProcs[SP_FN_ATN] := @SP_Interpret_FN_ATN;
  InterpretProcs[SP_FN_SINH] := @SP_Interpret_FN_SINH;
  InterpretProcs[SP_FN_COSH] := @SP_Interpret_FN_COSH;
  InterpretProcs[SP_FN_TANH] := @SP_Interpret_FN_TANH;
  InterpretProcs[SP_FN_ASNH] := @SP_Interpret_FN_ASNH;
  InterpretProcs[SP_FN_ACSH] := @SP_Interpret_FN_ACSH;
  InterpretProcs[SP_FN_ATNH] := @SP_Interpret_FN_ATNH;
  InterpretProcs[SP_FN_LN] := @SP_Interpret_FN_LN;
  InterpretProcs[SP_FN_EXP] := @SP_Interpret_FN_EXP;
  InterpretProcs[SP_FN_INT] := @SP_Interpret_FN_INT;
  InterpretProcs[SP_FN_SQR] := @SP_Interpret_FN_SQR;
  InterpretProcs[SP_FN_SGN] := @SP_Interpret_FN_SGN;
  InterpretProcs[SP_FN_ABS] := @SP_Interpret_FN_ABS;
  InterpretProcs[SP_FN_IN] := @SP_Interpret_FN_IN;
  InterpretProcs[SP_FN_USR] := @SP_Interpret_FN_USR;
  InterpretProcs[SP_FN_STRS] := @SP_Interpret_FN_STRS;
  InterpretProcs[SP_FN_CHRS] := @SP_Interpret_FN_CHRS;
  InterpretProcs[SP_FN_DCHRS] := @SP_Interpret_FN_DCHRS;
  InterpretProcs[SP_FN_QCHRS] := @SP_Interpret_FN_QCHRS;
  InterpretProcs[SP_FN_FCHRS] := @SP_Interpret_FN_FCHRS;
  InterpretProcs[SP_FN_PARAMS] := @SP_Interpret_FN_PARAMS;
  InterpretProcs[SP_FN_POWER] := @SP_Interpret_FN_POWER;
  InterpretProcs[SP_FN_PEEK] := @SP_Interpret_FN_PEEK;
  InterpretProcs[SP_FN_PEEKS] := @SP_Interpret_FN_PEEKS;
  InterpretProcs[SP_FN_DPEEK] := @SP_Interpret_FN_DPEEK;
  InterpretProcs[SP_FN_QPEEK] := @SP_Interpret_FN_QPEEK;
  InterpretProcs[SP_FN_FPEEK] := @SP_Interpret_FN_FPEEK;
  InterpretProcs[SP_FN_NOT] := @SP_Interpret_FN_NOT;
  InterpretProcs[SP_FN_FRAC] := @SP_Interpret_FN_FRAC;
  InterpretProcs[SP_FN_CEIL] := @SP_Interpret_FN_CEIL;
  InterpretProcs[SP_FN_FLOOR] := @SP_Interpret_FN_FLOOR;
  InterpretProcs[SP_FN_MAX] := @SP_Interpret_FN_MAX;
  InterpretProcs[SP_FN_MIN] := @SP_Interpret_FN_MIN;
  InterpretProcs[SP_FN_MAXS] := @SP_Interpret_FN_MAXS;
  InterpretProcs[SP_FN_MINS] := @SP_Interpret_FN_MINS;
  InterpretProcs[SP_FN_ROUND] := @SP_Interpret_FN_ROUND;
  InterpretProcs[SP_FN_CHPOS] := @SP_Interpret_FN_CHPOS;
  InterpretProcs[SP_FN_ODD] := @SP_Interpret_FN_ODD;
  InterpretProcs[SP_FN_EVEN] := @SP_Interpret_FN_EVEN;
  InterpretProcs[SP_FN_POS] := @SP_Interpret_FN_POS;
  InterpretProcs[SP_FN_TRUNC] := @SP_Interpret_FN_TRUNC;
  InterpretProcs[SP_FN_RED] := @SP_Interpret_FN_RED;
  InterpretProcs[SP_FN_GREEN] := @SP_Interpret_FN_GREEN;
  InterpretProcs[SP_FN_BLUE] := @SP_Interpret_FN_BLUE;
  InterpretProcs[SP_FN_RGB] := @SP_Interpret_FN_RGB;
  InterpretProcs[SP_FN_HEXS] := @SP_Interpret_FN_HEXS;
  InterpretProcs[SP_FN_BINS] := @SP_Interpret_FN_BINS;
  InterpretProcs[SP_FN_WINW] := @SP_Interpret_FN_WINW;
  InterpretProcs[SP_FN_WINH] := @SP_Interpret_FN_WINH;
  InterpretProcs[SP_FN_SCRW] := @SP_Interpret_FN_SCRW;
  InterpretProcs[SP_FN_SCRH] := @SP_Interpret_FN_SCRH;
  InterpretProcs[SP_FN_TXTW] := @SP_Interpret_FN_TXTW;
  InterpretProcs[SP_FN_TXTH] := @SP_Interpret_FN_TXTH;
  InterpretProcs[SP_FN_CWIN] := @SP_Interpret_FN_CWIN;
  InterpretProcs[SP_FN_RGBF] := @SP_Interpret_FN_RGBF;
  InterpretProcs[SP_FN_RGBN] := @SP_Interpret_FN_RGBN;
  InterpretProcs[SP_FN_HSV] := @SP_Interpret_FN_HSV;
  InterpretProcs[SP_FN_RGBC] := @SP_Interpret_FN_RGBC;
  InterpretProcs[SP_FN_HUE] := @SP_Interpret_FN_HUE;
  InterpretProcs[SP_FN_SAT] := @SP_Interpret_FN_SAT;
  InterpretProcs[SP_FN_VALUE] := @SP_Interpret_FN_VALUE;
  InterpretProcs[SP_FN_NOISE] := @SP_Interpret_FN_NOISE;
  InterpretProcs[SP_FN_NOISEOCT] := @SP_Interpret_FN_NOISEOCT;
  InterpretProcs[SP_FN_MAP] := @SP_Interpret_FN_MAP;
  InterpretProcs[SP_FN_RGBtoINT] := @SP_Interpret_FN_RGBtoINT;
  InterpretProcs[SP_FN_HSVtoINT] := @SP_Interpret_FN_HSVtoINT;
  InterpretProcs[SP_FN_RGBToHSV] := @SP_Interpret_FN_RGBToHSV;
  InterpretProcs[SP_FN_HSVtoRGB] := @SP_Interpret_FN_HSVtoRGB;
  InterpretProcs[SP_FN_TRIMS] := @SP_Interpret_FN_TRIMS;
  InterpretProcs[SP_FN_LTRIMS] := @SP_Interpret_FN_LTRIMS;
  InterpretProcs[SP_FN_RTRIMS] := @SP_Interpret_FN_RTRIMS;
  InterpretProcs[SP_FN_TOKENS] := @SP_Interpret_FN_TOKENS;
  InterpretProcs[SP_FN_UDGS] := @SP_Interpret_FN_UDGS;
  InterpretProcs[SP_FN_UDG] := @SP_Interpret_FN_UDG;
  InterpretProcs[SP_FN_GETTILE] := @SP_Interpret_FN_GETTILE;
  InterpretProcs[SP_FN_POWERTWO] := @SP_Interpret_FN_POWERTWO;
  InterpretProcs[SP_FN_LOGTWO] := @SP_Interpret_FN_LOGTWO;
  InterpretProcs[SP_FN_WORDSWAP] := @SP_Interpret_FN_WORDSWAP;
  InterpretProcs[SP_FN_BYTESWAP] := @SP_Interpret_FN_BYTESWAP;
  InterpretProcs[SP_FN_NYBBLESWAP] := @SP_Interpret_FN_NYBBLESWAP;
  InterpretProcs[SP_FN_POLAR] := @SP_Interpret_FN_POLAR;
  InterpretProcs[SP_FN_CLAMP] := @SP_Interpret_FN_CLAMP;
  InterpretProcs[SP_FN_INRANGE] := @SP_Interpret_FN_INRANGE;
  InterpretProcs[SP_FN_INSERTS] := @SP_Interpret_FN_INSERTS;
  InterpretProcs[SP_FN_ITEMS] := @SP_Interpret_FN_ITEMS;
  InterpretProcs[SP_FN_BIT] := @SP_Interpret_FN_BIT;
  InterpretProcs[SP_FN_BITCNT] := @SP_Interpret_FN_BITCNT;
  InterpretProcs[SP_FN_HIBIT] := @SP_Interpret_FN_HIBIT;
  InterpretProcs[SP_FN_HIWORD] := @SP_Interpret_FN_HIWORD;
  InterpretProcs[SP_FN_LOWORD] := @SP_Interpret_FN_LOWORD;
  InterpretProcs[SP_FN_HIBYTE] := @SP_Interpret_FN_HIBYTE;
  InterpretProcs[SP_FN_LOBYTE] := @SP_Interpret_FN_LOBYTE;
  InterpretProcs[SP_FN_POLARDIST] := @SP_Interpret_FN_POLARDIST;
  InterpretProcs[SP_FN_LPADS] := @SP_Interpret_FN_LPADS;
  InterpretProcs[SP_FN_RPADS] := @SP_Interpret_FN_RPADS;
  InterpretProcs[SP_FN_PROCID] := @SP_Interpret_FN_PROCID;
  InterpretProcs[SP_FN_BTSET] := @SP_Interpret_FN_BTSET;
  InterpretProcs[SP_FN_BTCLR] := @SP_Interpret_FN_BTCLR;
  InterpretProcs[SP_FN_ERRORS] := @SP_Interpret_FN_ERRORS;
  InterpretProcs[SP_FN_IN] := @SP_Interpret_FN_IN;
  InterpretProcs[SP_FN_POPLINE] := @SP_Interpret_FN_POPLINE;
  InterpretProcs[SP_FN_POPST] := @SP_Interpret_FN_POPST;
  InterpretProcs[SP_FN_VOL] := @SP_Interpret_FN_VOL;
  InterpretProcs[SP_FN_GETOPT] := @SP_Interpret_FN_GETOPT;
  InterpretProcs[SP_FN_GETOPTS] := @SP_Interpret_FN_GETOPTS;
  InterpretProcs[SP_FN_MENUBOX] := @SP_Interpret_FN_MENUBOX;
  InterpretProcs[SP_FN_MENUBOX_EX] := @SP_Interpret_FN_MENUBOX_EX;
  InterpretProcs[SP_FN_NUBMODE] := @SP_Interpret_FN_NUBMODE;
  InterpretProcs[SP_FN_NUBX] := @SP_Interpret_FN_NUBX;
  InterpretProcs[SP_FN_NUBY] := @SP_Interpret_FN_NUBY;
  InterpretProcs[SP_FN_FEXISTS] := @SP_Interpret_FN_FEXISTS;
  InterpretProcs[SP_FN_FPATH] := @SP_Interpret_FN_FPATH;
  InterpretProcs[SP_FN_FNAME] := @SP_Interpret_FN_FNAME;
  InterpretProcs[SP_FN_REVS] := @SP_Interpret_FN_REVS;
  InterpretProcs[SP_FN_DEXISTS] := @SP_Interpret_FN_DEXISTS;
  InterpretProcs[SP_FN_PYTH] := @SP_Interpret_FN_PYTH;
  InterpretProcs[SP_FN_LOGW] := @SP_Interpret_FN_LOGW;
  InterpretProcs[SP_FN_LOGH] := @SP_Interpret_FN_LOGH;
  InterpretProcs[SP_FN_ORGX] := @SP_Interpret_FN_ORGX;
  InterpretProcs[SP_FN_ORGY] := @SP_Interpret_FN_ORGY;
  InterpretProcs[SP_FN_LTOPX] := @SP_Interpret_FN_LTOPX;
  InterpretProcs[SP_FN_LTOPY] := @SP_Interpret_FN_LTOPY;
  InterpretProcs[SP_FN_PTOLX] := @SP_Interpret_FN_PTOLX;
  InterpretProcs[SP_FN_PTOLY] := @SP_Interpret_FN_PTOLY;
  InterpretProcs[SP_FN_MSECS] := @SP_Interpret_FN_MSECS;
  InterpretProcs[SP_FN_INV] := @SP_Interpret_FN_INV;
  InterpretProcs[SP_FN_POLYTERM] := @SP_Interpret_FN_POLYTERM;
  InterpretProcs[SP_FN_UNDER] := @SP_Interpret_FN_UNDER;
  InterpretProcs[SP_FN_COMPSIMPSON] := @SP_Interpret_FN_COMPSIMPSON;
  InterpretProcs[SP_FN_MUSICPOS] := @SP_Interpret_FN_MUSICPOS;
  InterpretProcs[SP_FN_MUSICLEN] := @SP_Interpret_FN_MUSICLEN;
  InterpretProcs[SP_FN_BASES] := @SP_Interpret_FN_BASES;
  InterpretProcs[SP_FN_DECIMAL] := @SP_Interpret_FN_DECIMAL;
  InterpretProcs[SP_FN_IIF] := @SP_Interpret_FN_IIF;
  InterpretProcs[SP_FN_IIFS] := @SP_Interpret_FN_IIF;
  InterpretProcs[SP_FN_SEARCH] := @SP_Interpret_FN_SEARCH;
  InterpretProcs[SP_FN_SEARCH_NEXT] := @SP_Interpret_FN_SEARCH_NEXT;
  InterpretProcs[SP_FN_LCM] := @SP_Interpret_FN_LCM;
  InterpretProcs[SP_FN_GCD] := @SP_Interpret_FN_GCD;
  InterpretProcs[SP_FN_DET] := @SP_Interpret_FN_DET;
  InterpretProcs[SP_FN_SPFRAME] := @SP_Interpret_FN_SPFRAME;
  InterpretProcs[SP_FN_SPCOLL] := @SP_Interpret_FN_SPCOLL;
  InterpretProcs[SP_FN_TEXTURES] := @SP_Interpret_FN_TEXTURES;
  InterpretProcs[SP_FN_INZONE] := @SP_Interpret_FN_INZONE;
  InterpretProcs[SP_FN_MATCH] := @SP_Interpret_FN_MATCH;
  InterpretProcs[SP_FN_USINGS] := @SP_Interpret_FN_USINGS;
  InterpretProcs[SP_FN_JOINS] := @SP_Interpret_FN_JOINS;
  InterpretProcs[SP_FN_LBOUND] := @SP_Interpret_FN_LBOUND;
  InterpretProcs[SP_FN_UBOUND] := @SP_Interpret_FN_UBOUND;
  InterpretProcs[SP_FN_ARSIZE] := @SP_Interpret_FN_ARSIZE;
  InterpretProcs[SP_FN_iRGBf] := @SP_Interpret_FN_iRGBf;
  InterpretProcs[SP_FN_iRGBn] := @SP_Interpret_FN_iRGBn;
  InterpretProcs[SP_FN_iRGBtoHSV] := @SP_Interpret_FN_iRGBtoHSV;
  InterpretProcs[SP_FN_iHSVtoRGB] := @SP_Interpret_FN_iHSVtoRGB;
  InterpretProcs[SP_FN_MANDEL] := @SP_Interpret_FN_MANDEL;
  InterpretProcs[SP_FN_SCREENS] := @SP_Interpret_FN_SCREENS;
  InterpretProcs[SP_FN_DATES] := @SP_Interpret_FN_DATES;
  InterpretProcs[SP_FN_TIMES] := @SP_Interpret_FN_TIMES;
  InterpretProcs[SP_FN_REPLACES] := @SP_Interpret_FN_REPLACES;
  InterpretProcs[SP_FN_REPLACEMATCHS] := @SP_Interpret_FN_REPLACEMATCHS;
  InterpretProcs[SP_FN_POSN] := @SP_Interpret_FN_POSN;
  InterpretProcs[SP_FN_INSTR] := @SP_Interpret_FN_INSTR;
  InterpretProcs[SP_FN_INSTRN] := @SP_Interpret_FN_INSTRN;
  InterpretProcs[SP_FN_IVAL] := @SP_Interpret_FN_IVAL;
  InterpretProcs[SP_FN_MIATTR] := @SP_Interpret_FN_MIATTR;
  InterpretProcs[SP_FN_LASTM] := @SP_Interpret_FN_LASTM;
  InterpretProcs[SP_FN_LASTMI] := @SP_Interpret_FN_LASTMI;
  InterpretProcs[SP_FN_KEYS] := @SP_Interpret_FN_KEYS;
  InterpretProcs[SP_FN_SPCLX] := @SP_Interpret_FN_SPCLX;
  InterpretProcs[SP_FN_SPCLY] := @SP_Interpret_FN_SPCLY;
  InterpretProcs[SP_FN_DATADDR] := @SP_Interpret_FN_DATADDR;
  InterpretProcs[SP_FN_WINADDR] := @SP_Interpret_FN_WINADDR;
  InterpretProcs[SP_FN_STRADDR] := @SP_Interpret_FN_STRADDR;
  InterpretProcs[SP_FN_MEMRD] := @SP_Interpret_FN_MEMRD;
  InterpretProcs[SP_FN_DMEMRD] := @SP_Interpret_FN_DMEMRD;
  InterpretProcs[SP_FN_QMEMRD] := @SP_Interpret_FN_QMEMRD;
  InterpretProcs[SP_FN_FMEMRD] := @SP_Interpret_FN_FMEMRD;
  InterpretProcs[SP_FN_MEMRDS] := @SP_Interpret_FN_MEMRDS;
  InterpretProcs[SP_FN_CHOOSE] := @SP_Interpret_FN_CHOOSE;
  InterpretProcs[SP_FN_CHOOSES] := @SP_Interpret_FN_CHOOSES;
  InterpretProcs[SP_FN_BINV] := @SP_Interpret_FN_BINV;
  InterpretProcs[SP_FN_BREV] := @SP_Interpret_FN_BREV;
  InterpretProcs[SP_FN_INTERP] := @SP_Interpret_FN_INTERP;
  InterpretProcs[SP_FN_PAR] := @SP_Interpret_FN_PAR;

  // Tokens

  InterpretProcs[SP_KEYWORD] := @SP_Interpret_SP_KEYWORD;
  InterpretProcs[SP_STRING] := @SP_Interpret_SP_STRING;
  InterpretProcs[SP_NUMVAR] := @SP_Interpret_SP_NUMVAR;
  InterpretProcs[SP_STRVAR] := @SP_Interpret_SP_STRVAR;
  InterpretProcs[SP_SYMBOL] := @SP_Interpret_SP_SYMBOL;
  InterpretProcs[SP_FUNCTION] := @SP_Interpret_SP_FUNCTION;
  InterpretProcs[SP_NUMVAR_EVAL] := @SP_Interpret_SP_NUMVAR_EVAL;
  InterpretProcs[SP_NUMVARSQ] := @SP_Interpret_SP_NUMVARSQ;
  InterpretProcs[SP_STRVAR_EVAL] := @SP_Interpret_SP_STRVAR_EVAL;
  InterpretProcs[SP_ARRAY] := @SP_Interpret_SP_ARRAY;
  InterpretProcs[SP_SLICER] := @SP_Interpret_SP_SLICER;
  InterpretProcs[SP_ARRAY_ASSIGN] := @SP_Interpret_SP_ARRAY_ASSIGN;
  InterpretProcs[SP_SLICE_ASSIGN] := @SP_Interpret_SP_SLICE_ASSIGN;
  InterpretProcs[SP_JUMP] := @SP_Interpret_SP_JUMP;
  InterpretProcs[SP_POINTER] := @SP_Interpret_SP_POINTER;
  InterpretProcs[SP_SKIP_STATEMENT] := @SP_Interpret_SP_SKIP_STATEMENT;
  InterpretProcs[SP_SKIP_LINE] := @SP_Interpret_SP_SKIP_LINE;
  InterpretProcs[SP_DATA_ITEM] := @SP_Interpret_SP_DATA_ITEM;
  InterpretProcs[SP_LABEL] := @SP_Interpret_SP_LABEL;
  InterpretProcs[SP_DISPLACEMENT] := @SP_Interpret_SP_DISPLACEMENT;
  InterpretProcs[SP_CAUSEERROR] := @SP_Interpret_SP_CAUSEERROR;
  InterpretProcs[SP_IJMP] := @SP_Interpret_SP_IJMP;
  InterpretProcs[SP_VALUE] := @SP_Interpret_SP_VALUE;
  InterpretProcs[SP_NUMVAR_LET] := @SP_Interpret_SP_NUMVAR_LET;
  InterpretProcs[SP_STRVAR_LET] := @SP_Interpret_SP_STRVAR_LET;
  InterpretProcs[SP_HYBRID_LET] := @SP_Interpret_SP_HYBRID_LET;
  InterpretProcs[SP_INCVAR] := @SP_Interpret_SP_INCVAR;
  InterpretProcs[SP_DECVAR] := @SP_Interpret_SP_DECVAR;
  InterpretProcs[SP_MULVAR] := @SP_Interpret_SP_MULVAR;
  InterpretProcs[SP_DIVVAR] := @SP_Interpret_SP_DIVVAR;
  InterpretProcs[SP_POWVAR] := @SP_Interpret_SP_POWVAR;
  InterpretProcs[SP_MODVAR] := @SP_Interpret_SP_MODVAR;
  InterpretProcs[SP_ANDVAR] := @SP_Interpret_SP_ANDVAR;
  InterpretProcs[SP_ORVAR] := @SP_Interpret_SP_ORVAR;
  InterpretProcs[SP_NOTVAR] := @SP_Interpret_SP_NOTVAR;
  InterpretProcs[SP_XORVAR] := @SP_Interpret_SP_XORVAR;
  InterpretProcs[SP_SHLVAR] := @SP_Interpret_SP_SHLVAR;
  InterpretProcs[SP_SHRVAR] := @SP_Interpret_SP_SHRVAR;
  InterpretProcs[SP_STRUCT_MEMBER_N] := @SP_Interpret_SP_STRUCT_MEMBER_N;
  InterpretProcs[SP_STRUCT_MEMBER_ASS] := @SP_Interpret_SP_STRUCT_MEMBER_ASS;
  InterpretProcs[SP_STRUCT_MEMBER_S] := @SP_Interpret_SP_STRUCT_MEMBER_S;
  InterpretProcs[SP_STRVARPTR] := @SP_Interpret_SP_STRVARPTR;
  InterpretProcs[SP_NUMVAR_LET_VALID] := @SP_Interpret_SP_NUMVAR_LET_VALID;
  InterpretProcs[SP_STRVAR_LET_VALID] := @SP_Interpret_SP_STRVAR_LET_VALID;
  InterpretProcs[SP_SKIP_DATA] := @SP_Interpret_SP_SKIP_DATA;
  InterpretProcs[SP_RANGE_LESS] := @SP_Interpret_SP_RANGE_LESS;
  InterpretProcs[SP_RANGE_GREATER] := @SP_Interpret_SP_RANGE_GREATER;
  InterpretProcs[SP_RANGE_ARRAYSTR] := @SP_Interpret_SP_RANGE_ARRAYSTR;
  InterpretProcs[SP_RANGE_ARRAYNUM] := @SP_Interpret_SP_RANGE_ARRAYNUM;
  InterpretProcs[SP_RANGE] := @SP_Interpret_SP_RANGE;
  InterpretProcs[SP_COMPOUND_NNO] := @SP_Interpret_NNO;
  InterpretProcs[SP_COMPOUND_NVO] := @SP_Interpret_NVO;
  InterpretProcs[SP_COMPOUND_VNO] := @SP_Interpret_VNO;
  InterpretProcs[SP_SPECIAL_SYMBOL] := @SP_Interpret_SP_SPECIAL_SYMBOL;
  InterpretProcs[SP_NUMCONST] := @SP_Interpret_SP_NUMCONST;
  InterpretProcs[SP_STRCONST] := @SP_Interpret_SP_STRCONST;
  InterpretProcs[SP_TERMINAL] := @SP_Interpret_SP_TERMINAL;
  InterpretProcs[SP_FUNCTION_MARKER] := @SP_Interpret_FUNCTION_MARKER;
  InterpretProcs[SP_BLOCK_OPT] := @SP_Interpret_FUNCTION_MARKER;
  InterpretProcs[SP_JZ] := @SP_Interpret_SP_JZ;
  InterpretProcs[SP_JNZ] := @SP_Interpret_SP_JNZ;
  InterpretProcs[SP_NUM_ARRAY_PTR] := @SP_Interpret_SP_NUM_ARRAY_PTR;
  InterpretProcs[SP_RESTORECOLOURS] := @SP_Interpret_SP_RESTORECOLOURS;

  // Symbols

  For Il := 0 To 255 Do InterpretProcs[6000 + Il] := @SP_Interpret_SP_SYMBOL;

  InterpretProcs[6000 + Ord(SP_CHAR_INT_PLUS)] := @SP_Interpret_SP_CHAR_INT_PLUS;
  InterpretProcs[6000 + Ord(SP_CHAR_NUM_PLUS)] := @SP_Interpret_SP_CHAR_NUM_PLUS;
  InterpretProcs[6000 + Ord(SP_CHAR_STR_PLUS)] := @SP_Interpret_SP_CHAR_STR_PLUS;
  InterpretProcs[6000 + Ord(SP_CHAR_BITWISE_NOT)] := @SP_Interpret_SP_CHAR_BITWISE_NOT;
  InterpretProcs[6000 + Ord(SP_CHAR_STRING_NOT)] := @SP_Interpret_SP_CHAR_STRING_NOT;
  InterpretProcs[6000 + Ord(SP_CHAR_MUL)] := @SP_Interpret_SP_CHAR_MUL;
  InterpretProcs[6000 + Ord(SP_CHAR_DIV)] := @SP_Interpret_SP_CHAR_DIV;
  InterpretProcs[6000 + Ord(SP_CHAR_ADD)] := @SP_Interpret_SP_CHAR_ADD;
  InterpretProcs[6000 + Ord(SP_CHAR_SUB)] := @SP_Interpret_SP_CHAR_SUB;
  InterpretProcs[6000 + Ord(SP_CHAR_STR_MUL1)] := @SP_Interpret_SP_CHAR_STR_MUL1;
  InterpretProcs[6000 + Ord(SP_CHAR_STR_MUL2)] := @SP_Interpret_SP_CHAR_STR_MUL2;
  InterpretProcs[6000 + Ord(SP_CHAR_NUM_EQU)] := @SP_Interpret_SP_CHAR_NUM_EQU;
  InterpretProcs[6000 + Ord(SP_CHAR_STR_EQU)] := @SP_Interpret_SP_CHAR_STR_EQU;
  InterpretProcs[6000 + Ord(SP_CHAR_NUM_LES)] := @SP_Interpret_SP_CHAR_NUM_LES;
  InterpretProcs[6000 + Ord(SP_CHAR_STR_LES)] := @SP_Interpret_SP_CHAR_STR_LES;
  InterpretProcs[6000 + Ord(SP_CHAR_NUM_LTE)] := @SP_Interpret_SP_CHAR_NUM_LTE;
  InterpretProcs[6000 + Ord(SP_CHAR_STR_LTE)] := @SP_Interpret_SP_CHAR_STR_LTE;
  InterpretProcs[6000 + Ord(SP_CHAR_NUM_DNE)] := @SP_Interpret_SP_CHAR_NUM_DNE;
  InterpretProcs[6000 + Ord(SP_CHAR_STR_DNE)] := @SP_Interpret_SP_CHAR_STR_DNE;
  InterpretProcs[6000 + Ord(SP_CHAR_NUM_GTE)] := @SP_Interpret_SP_CHAR_NUM_GTE;
  InterpretProcs[6000 + Ord(SP_CHAR_STR_GTE)] := @SP_Interpret_SP_CHAR_STR_GTE;
  InterpretProcs[6000 + Ord(SP_CHAR_NUM_GTR)] := @SP_Interpret_SP_CHAR_NUM_GTR;
  InterpretProcs[6000 + Ord(SP_CHAR_STR_GTR)] := @SP_Interpret_SP_CHAR_STR_GTR;
  InterpretProcs[6000 + Ord(SP_CHAR_GTE)] := @SP_Interpret_SP_CHAR_GTE;
  InterpretProcs[6000 + Ord(SP_CHAR_LTE)] := @SP_Interpret_SP_CHAR_LTE;
  InterpretProcs[6000 + Ord(SP_CHAR_DNE)] := @SP_Interpret_SP_CHAR_DNE;
  InterpretProcs[6000 + Ord(SP_CHAR_NUM_AND)] := @SP_Interpret_SP_CHAR_NUM_AND;
  InterpretProcs[6000 + Ord(SP_CHAR_STR_AND)] := @SP_Interpret_SP_CHAR_STR_AND;
  InterpretProcs[6000 + Ord(SP_CHAR_AND)] := @SP_Interpret_SP_CHAR_AND;
  InterpretProcs[6000 + Ord(SP_CHAR_OR)] := @SP_Interpret_SP_CHAR_OR;
  InterpretProcs[6000 + Ord(SP_CHAR_EQV)] := @SP_Interpret_SP_CHAR_EQV;
  InterpretProcs[6000 + Ord(SP_CHAR_IMP)] := @SP_Interpret_SP_CHAR_IMP;
  InterpretProcs[6000 + Ord(SP_CHAR_MOD)] := @SP_Interpret_SP_CHAR_MOD;
  InterpretProcs[6000 + Ord(SP_CHAR_FMOD)] := @SP_Interpret_SP_CHAR_FMOD;
  InterpretProcs[6000 + Ord(SP_CHAR_XOR)] := @SP_Interpret_SP_CHAR_XOR;
  InterpretProcs[6000 + Ord(SP_CHAR_SHL)] := @SP_Interpret_SP_CHAR_SHL;
  InterpretProcs[6000 + Ord(SP_CHAR_SHR)] := @SP_Interpret_SP_CHAR_SHR;
  InterpretProcs[6000 + Ord(SP_CHAR_PLUS)] := @SP_Interpret_SP_CHAR_PLUS;
  InterpretProcs[6000 + Ord(SP_CHAR_MINUS)] := @SP_Interpret_SP_CHAR_MINUS;
  InterpretProcs[6000 + Ord(SP_CHAR_MULTIPLY)] := @SP_Interpret_SP_CHAR_MULTIPLY;
  InterpretProcs[6000 + Ord(SP_CHAR_DIVIDE)] := @SP_Interpret_SP_CHAR_DIVIDE;
  InterpretProcs[6000 + Ord(SP_CHAR_POWER)] := @SP_Interpret_SP_CHAR_POWER;
  InterpretProcs[6000 + Ord(SP_CHAR_COLON)] := @SP_Interpret_SP_CHAR_COLON;
  InterpretProcs[6000 + Ord(SP_CHAR_EQUALS)] := @SP_Interpret_SP_CHAR_EQUALS;
  InterpretProcs[6000 + Ord(SP_CHAR_GREATER)] := @SP_Interpret_SP_CHAR_GREATER;
  InterpretProcs[6000 + Ord(SP_CHAR_LESS)] := @SP_Interpret_SP_CHAR_LESS;
  InterpretProcs[6000 + Ord(SP_CHAR_BIT_OR)] := @SP_Interpret_SP_CHAR_BIT_OR;
  InterpretProcs[6000 + Ord(SP_CHAR_BIT_AND)] := @SP_Interpret_SP_CHAR_BIT_AND;
  InterpretProcs[6000 + Ord(SP_CHAR_EXCLAIM)] := @SP_Interpret_SP_CHAR_EXCLAIM;
  InterpretProcs[6000 + Ord(SP_CHAR_TILDE)] := @SP_Interpret_SP_CHAR_TILDE;
  InterpretProcs[6000 + Ord(SP_CHAR_INCVAR)] := @SP_Interpret_SP_CHAR_INCVAR;
  InterpretProcs[6000 + Ord(SP_CHAR_DECVAR)] := @SP_Interpret_SP_CHAR_DECVAR;
  InterpretProcs[6000 + Ord(SP_CHAR_MULVAR)] := @SP_Interpret_SP_CHAR_MULVAR;
  InterpretProcs[6000 + Ord(SP_CHAR_DIVVAR)] := @SP_Interpret_SP_CHAR_DIVVAR;
  InterpretProcs[6000 + Ord(SP_CHAR_POWVAR)] := @SP_Interpret_SP_CHAR_POWVAR;
  InterpretProcs[6000 + Ord(SP_CHAR_MODVAR)] := @SP_Interpret_SP_CHAR_MODVAR;
  InterpretProcs[6000 + Ord(SP_CHAR_ANDVAR)] := @SP_Interpret_SP_CHAR_ANDVAR;
  InterpretProcs[6000 + Ord(SP_CHAR_XORVAR)] := @SP_Interpret_SP_CHAR_XORVAR;
  InterpretProcs[6000 + Ord(SP_CHAR_ORVAR)] := @SP_Interpret_SP_CHAR_ORVAR;
  InterpretProcs[6000 + Ord(SP_CHAR_NOTVAR)] := @SP_Interpret_SP_CHAR_NOTVAR;
  InterpretProcs[6000 + Ord(SP_CHAR_SHLVAR)] := @SP_Interpret_SP_CHAR_SHLVAR;
  InterpretProcs[6000 + Ord(SP_CHAR_SHRVAR)] := @SP_Interpret_SP_CHAR_SHRVAR;
  InterpretProcs[6000 + Ord(SP_CHAR_NOT)] := @SP_Interpret_FN_NOT; // NOT is an operator of very low priority in Sinclair BASIC

  Il := 0;
  Nl := 0;
  gbIndices := '';

  DummyToken.Token := 0;
  DummyToken.Handler := nil;
  DummyToken.TokenPos := 0;
  DummyToken.TokenLen := 0;

  SP_StackStart := @SP_Stack[0];
  Dec(SP_StackStart);

  SP_StackPtr := SP_StackStart;

End.
