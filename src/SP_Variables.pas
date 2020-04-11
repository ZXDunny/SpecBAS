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

unit SP_Variables;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}

// Variable management functions.

interface

Uses Math, Classes, SysUtils, SP_Math, SP_Tokenise, SP_Errors, SP_SysVars, SP_Util, SP_AnsiStringlist;

Type

  THashEntry = Record
    Key: aString;
    Index: LongWord;
    NextHash: Pointer;
  End;
  pHashEntry = ^THashEntry;

  TSP_NumVarContent = Record
    Value, InitVal: aFloat;
    VarType, LoopLine, LoopStatement, St: Integer;
    EachIndex, EachArrayIndex, Count: Integer;
    EachPtr: Integer;
    EachTokens, Key: aString;
    EndAt, Step, RangeMin, RangeMax, RangeStep: aFloat;
  End;
  pSP_NumVarContent = ^TSP_NumVarContent;

  TSP_NUMVAR = Record
    Name: aString;
    Content: TSP_NumVarContent;
    ContentPtr: pSP_NumVarContent;
    ProcVar: Boolean;
  End;
  pSP_NumVar = ^TSP_NUMVAR;

  TSP_StrVarContent = Record
    Value: aString;
    VarType, SliceFrom, SliceTo, DLen, LoopLine, LoopStatement, St: Integer;
    EachIndex, EachArrayIndex, Count: Integer;
    EachPtr, RangeMin, RangeMax, RangeStep: Integer;
    EachTokens, StructName, Key: aString;
    Step: aFloat;
  End;
  pSP_StrVarContent = ^TSP_StrVarContent;

  TSP_STRVAR = Record
    Name: aString;
    Content: TSP_StrVarContent;
    ContentPtr: pSP_StrVarContent;
    ProcVar: Boolean;
  End;
  pSP_StrVar = ^TSP_STRVAR;

  TSP_NUMARRAY = Record
    Name: aString;
    Size, NumIndices, Base, LastSearchIdx: Integer;
    LastSearchTerm: aFloat;
    Values: Array of pSP_NumVarContent;
    Indices: Array of Integer;
    Hashes: Array[0..255] of pHashEntry;
    DynArray: Boolean;
    DynHashes: Array of pHashEntry;
  End;
  pSP_NumArray = ^TSP_NUMARRAY;

  TSP_STRARRAY = Packed Record
    Name, LastSearchTerm: aString;
    Size, NumIndices, Base, LastSearchIdx, DLen: Integer;
    Strings: Array of pSP_StrVarContent;
    Indices: Array of Integer;
    Hashes: Array[0..255] of pHashEntry;
    DynArray: Boolean;
    DynHashes: Array of pHashEntry;
  End;
  pSP_StrArray = ^TSP_STRARRAY;

  TSP_SLICER = Record
    Indices: aString;
    SliceFrom, SliceTo: Integer;
  End;

  TSP_StructMember = Record
    mType: Byte;        // Type of member - string or value
    mName: aString;     // Name of member, lowercase
    mFix: Integer;      // If string, the length. 0 = Dynamic length
    dString: aString;   // Default string value
    dValue: aFloat;     // Default numeric value
  End;
  pSP_StructMember = ^TSP_StructMember;

  TSP_STRUCTURE = Record
    Name: aString;
    Members: Array of TSP_StructMember;
  End;

  TSP_Constant = Record
    Name: aString;
    Val: aFloat;
    Str: aString;
  End;

Function  SP_FindNumVar(const Name: aString): Integer;
Function  SP_FindGlobalNumVar(const Name: aString): Integer; inline;
Function  SP_FindGlobalStrVar(const Name: aString): Integer; inline;
Function  SP_FindStrVar(const Name: aString): Integer;
Function  SP_FindNumArray(const Name: aString): Integer;
Function  SP_FindStrArray(const Name: aString): Integer;
Procedure SP_InsertGlobalNumVar(Var Idx: Integer); inline;
Procedure SP_InsertGlobalStrVar(Var Idx: Integer); inline;
Function  SP_NewNumVar: Integer;
Function  SP_UpdateNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Procedure SP_UpdateNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Function  SP_IncNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Procedure SP_IncNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Function  SP_DecNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Procedure SP_DecNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Function  SP_MulNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Procedure SP_MulNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Function  SP_DivNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Procedure SP_DivNumVarIndex(Idx: Integer; Var Value: aFloat; Var Error: TSP_ErrorCode); inline;
Function  SP_PowNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Procedure SP_PowNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Function  SP_ModNumVar(Idx: Integer; const Name: aString; Var Value: NativeUInt; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Procedure SP_ModNumVarIndex(Idx: Integer; Var Value: NativeUInt; Var Error: TSP_ErrorCode); inline;
Function  SP_AndNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Procedure SP_AndNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Function  SP_OrNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Procedure SP_OrNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Function  SP_XorNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Procedure SP_XorNumVarIndex(Idx: Integer; Var Value: aFloat); inline;

Function  SP_UpdateFORVar(Idx: Integer; const Name: aString; Var Value, EndAt, Step: aFloat; LoopLine, LoopStatement, St: Integer; Ptr: pLongWord; Var Error: TSP_ErrorCode): Integer;
Function  SP_NewStrVar: Integer;
Function  SP_GetStrVarPtr(Idx: Integer; const Name: aString; Var Error: TSP_ErrorCode; Ptr: pLongWord): pSP_StrVarContent;
Function  SP_UpdateStrVar(Idx: Integer; const Name: aString; Value: aString; aSliceFrom, aSliceTo: Integer; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Procedure SP_UpdateStrVarIndex(Idx: Integer; Value: aString);
Procedure SP_ResizeNumVars(Size: Integer);
Procedure SP_ResizeStrVars(Size: Integer);

Procedure SP_CopyNumArray(SrcIdx, DstIdx: Integer; Var Error: TSP_ErrorCode);
Function  SP_CreateNumArray(const Name: aString; const Indices: aString; Base: Integer; Dyn: Boolean; Var Error: TSP_ErrorCode): Integer;
Procedure SP_TruncateNumArrays(Count: Integer);
Procedure SP_RemoveNumArray(Idx: Integer);
Procedure SP_DeleteNumArray(Const Name: aString; Var Error: TSP_ErrorCode);
Function  SP_UpdateNumArray(Var Idx: Integer; const Name: aString; const Indices, Key: ansiString; Var Value: aFloat; Var Error: TSP_ErrorCode): Integer;
Function  SP_NumArrayGetIndex(Idx: Integer; Const Indices, Key: aString; Var Error: TSP_ErrorCode): Integer;
Function  SP_GetKeyFromNumArray(Idx: Integer; Const Indices, Key: aString; Var Error: TSP_ErrorCode): aString;
Function  SP_GetNumArrayKey(Idx: Integer; Const Key: aString): Integer;
Function  SP_FindNumArrayHash(Idx: Integer; Const Key: aString): pHashEntry; Inline;
Procedure SP_NumArrayRemoveKey(Idx, Index: Integer; Const Key: aString);
Procedure SP_SetNumArrayKey(Idx: Integer; Const Indices, Key, NewKey: aString;  Var Error: TSP_ErrorCode);
Function  SP_GetNumArrayPtr(Idx: Integer; const Name: aString; const Indices, Key: aString; Var Error: TSP_ErrorCode): pSP_NumVarContent;
Function  SP_QueryNumArray(Var Idx: Integer; Var Indices, Key: aString; Var Error: TSP_ErrorCode): aFloat;
Procedure SP_FillNumArray(Var Idx: Integer; Value: aFloat);

Function  SP_CreateStrArray(const Name: aString; const Indices: aString; DLen: Integer; const StructName: aString; Base: Integer; Dyn: Boolean; Var Error: TSP_ErrorCode): Integer;
Procedure SP_TruncateStrArrays(Count: Integer);
Procedure SP_RemoveStrArray(Idx: Integer);
Procedure SP_DeleteStrArray(Const Name: aString; Var Error: TSP_ErrorCode);
Function  SP_UpdateStrArray(Idx: Integer; const Name, Indices, Key: aString; Phrase: aString; aSliceFrom, aSliceTo: Integer; Var Error: TSP_ErrorCode): Integer;
Function  SP_StrArrayGetIndex(Idx: Integer; Const Indices, Key: aString; Var Error: TSP_ErrorCode): Integer;
Function  SP_GetKeyFromStrArray(Idx: Integer; Const Indices, Key: aString; Var Error: TSP_ErrorCode): aString;
Procedure SP_SetStrArrayKey(Idx: Integer; Const Indices, Key, NewKey: aString;  Var Error: TSP_ErrorCode);
Function  SP_GetStrArrayKey(Idx: Integer; Const Key: aString): Integer;
Function  SP_FindStrArrayHash(Idx: Integer; Const Key: aString): pHashEntry; Inline;
Procedure SP_StrArrayRemoveKey(Idx, Index: Integer; Const Key: aString);
Function  SP_GetStrArrayPtr(Idx: Integer; const Name: aString; const Indices, Key: aString; Var Error: TSP_ErrorCode): pSP_StrVarContent;
Function  SP_QueryStrArray(Var Idx: Integer; Var Indices, Key: aString; Var Error: TSP_ErrorCode): aString;
Procedure SP_FillStrArray(Var Idx: Integer; Value: aString);

Function  SP_SliceString(const Str: aString; SliceFrom, SliceTo: Integer): aString;
Procedure SP_SliceAssign(Var Dst: aString; const Src: aString; sFrom, sTo: Integer; Var Error: TSP_ErrorCode); inline;

Procedure SP_PreParse(ClearVars: Boolean; Var Error: TSP_ErrorCode);
Procedure SP_FixStatementList(Var Tokens: aString; Position, Displacement: Integer);
Procedure SP_TestConsts(Var Tokens: aString; lIdx: Integer; Var Error: TSP_ErrorCode; Preserve: Boolean);
Procedure SP_ClearVarIndices;

Procedure SP_SaveVar(const Filename, VarName: aString; IsArray: Boolean; var Error: TSP_ErrorCode);
Procedure SP_LoadVar(const Filename, VarName: aString; Var Error: TSP_ErrorCode);

Function  SP_NumArrayToString(Index, MaxLen: Integer): aString;
Function  SP_StrArrayToString(Index, MaxLen: Integer): aString;

Function  SP_NewStruct(const Name: aString): Integer;
Procedure SP_DeleteStruct(const Name: aString; Var Error: TSP_ErrorCode);
Procedure SP_AddStructMember(Idx: Integer; const mName: aString; mFix, mType: Integer; const DefString: aString; DefValue: aFloat);
Function  SP_FindStruct(const Name: aString): Integer;
Function  SP_AssignStruct(Idx: Integer; const Name, StructName: aString; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Procedure SP_AssignStructPtr(sPtr: pSP_StrVarContent; const StructName: aString; Var Error: TSP_ErrorCode);
Procedure SP_SetStructMember(StrPtr: pSP_StrVarContent; const Member, ValStr: aString; ValNum: aFloat; Var Error: TSP_ErrorCode);
Function  SP_GetStructMemberN(sPtr: pSP_StrVarContent; const Member: aString; Var Error: TSP_ErrorCode): aFloat;
Function  SP_GetStructMemberS(sPtr: pSP_StrVarContent; const Member: aString; Var Error: TSP_ErrorCode): aString;
Function  SP_GetDefaultFields(sIdx: Integer): aString;
Procedure SP_ClearStructs;

Function  SP_UpdateFOREACHVar(Idx: Integer; const Name, ArrayName: aString; Var Step: aFloat; LoopLine, LoopStatement, St: Integer; Ptr: pLongWord; Var Error: TSP_ErrorCode): Integer;
Function  SP_UpdateFOREACHRANGEVar(Idx: Integer; const Name, EachString: aString; Var NumRanges, LoopLine, LoopStatement, St: Integer; Ptr: pLongWord; Var Error: TSP_ErrorCode): Integer;

Procedure SP_SortNumArray(sIdx: Integer; Key, Ascending: Boolean; Var Error: TSP_ErrorCode);
Procedure SP_SortStrArray(sIdx: Integer; Key, Ascending: Boolean; Var Error: TSP_ErrorCode);

Function  SP_SearchNumArray(Const Name: aString; Term: aFloat; Var Error: TSP_ErrorCode): Integer;
Function  SP_SearchNumArrayNext(Const Name: aString; Var Error: TSP_ErrorCode): Integer;
Function  SP_SearchStrArray(Const Name, Term: aString; Var Error: TSP_ErrorCode): Integer;
Function  SP_SearchStrArrayNext(Const Name: aString; Var Error: TSP_ErrorCode): Integer;
Function  SP_ValueInNumArray(Const Name: aString; Term: aFloat; Var Error: TSP_ErrorCode): Boolean;
Function  SP_StringInStrArray(Const Name: aString; Term: aString; Var Error: TSP_ErrorCode): Boolean;

Var

  NumVars: Array of pSP_NUMVAR;
  StrVars: Array of pSP_STRVAR;
  NumArrays: Array of TSP_NUMARRAY;
  StrArrays: Array of TSP_STRARRAY;
  Structures: Array of TSP_STRUCTURE;
  LineLUT: Array of Integer;
  Constants: Array of TSP_Constant;
  NVLen, SVLen, NumNV, NumSV: Integer;
  logtext: astring;

Const

  SP_FORVAR = 1;
  SP_SIMPLE = 2;
  SP_FOREACH = 3;
  SP_STRVAR = 4;
  SP_FOREACHRANGE = 5;

implementation

Uses SP_Main, SP_Interpret_PostFix, SP_InfixToPostFix, SP_Graphics, SP_Streams, SP_BankManager, SP_FileIO, SP_Menu, SP_FPEditor;

Function SP_FindNumVar(const Name: aString): Integer; inline;
Begin

  Result := NumNV -1;
  While Result >= 0 Do Begin
    If Name = NumVars[Result]^.Name Then
      Break;
    Dec(Result);
  End;

End;

Function SP_FindGlobalNumVar(const Name: aString): Integer; inline;
Begin

  If SP_ProcStackPtr > -1 Then Begin
    Result := 0;
    While Result < SP_ProcStack[0].VarPosN Do Begin
      If NumVars[Result].Name = Name Then
        Break;
      Inc(Result);
    End;
    If Result = SP_ProcStack[0].VarPosN Then
      Result := -1;
  End Else
    Result := SP_FindNumVar(Name);

End;

Function SP_FindNumArray(const Name: aString): Integer; inline;
Begin

  Result := Length(NumArrays) -1;
  While Result >= 0 Do Begin
    If Name = NumArrays[Result].Name Then
      Break;
    Dec(Result);
  End;

End;

Function SP_FindStrArray(const Name: aString): Integer; inline;
Begin

  Result := Length(StrArrays) -1;
  While Result >= 0 Do Begin
    If Name = StrArrays[Result].Name Then
      Break;
    Dec(Result);
  End;

End;

Function SP_FindStrVar(const Name: aString): Integer; inline;
Begin

  Result := NumSV -1;
  While Result >= 0 Do Begin
    If Name = StrVars[Result]^.Name Then
      Break;
    Dec(Result);
  End;

End;

Function SP_FindGlobalStrVar(const Name: aString): Integer; inline;
Begin

  If SP_ProcStackPtr > -1 Then Begin
    Result := 0;
    While Result < SP_ProcStack[0].VarPosS Do Begin
      If StrVars[Result].Name = Name Then
        Break;
      Inc(Result);
    End;
    If Result = SP_ProcStack[0].VarPosS Then
      Result := -1;
  End Else
    Result := SP_FindStrVar(Name);

End;

Function SP_NewNumVar: Integer;
Begin
  Inc(NumNV);
  If NumNV >= NVLen Then Begin
    Inc(NVLen);
    SetLength(NumVars, NVLen);
  End;
  Result := NumNV -1;
  If NumVars[Result] = nil Then
    NumVars[Result] := New(pSP_NumVar);
End;

Function SP_NewStrVar: Integer;
Begin
  Inc(NumSV);
  If NumSV >= SVLen Then Begin
    Inc(SVLen);
    SetLength(StrVars, SVLen);
  End;
  Result := NumSV -1;
  If StrVars[Result] = nil Then
    StrVars[Result] := New(pSP_StrVar);
End;

Procedure SP_ResizeNumVars(Size: Integer); Inline;
Begin

  NumNV := Size;

End;

Procedure SP_ResizeStrVars(Size: Integer); Inline;
Begin

  NumSV := Size;

End;

Procedure SP_InsertGlobalNumVar(Var Idx: Integer); inline;
Var
  nIdx: Integer;
Begin

  Inc(NumNV);
  If NumNV >= NVLen Then Begin
    Inc(NVLen);
    SetLength(NumVars, NVLen);
  End;

  If SP_ProcStackPtr > -1 Then Begin
    Idx := NVLen -1;
    nIdx := Idx;
    While nIdx >= SP_ProcStack[0].VarPosN Do Begin
      NumVars[nIdx] := NumVars[nIdx-1];
      Dec(nIdx);
    End;
    nIdx := 0;
    While nIdx <= SP_ProcStackPtr Do Begin
      Inc(SP_ProcStack[nIdx].VarPosN);
      Inc(nIdx);
    End;
  End Else
    Idx := NumNV -1;
  If NumVars[Idx] = nil Then
    NumVars[Idx] := New(pSP_NumVar);
End;

Procedure SP_InsertGlobalStrVar(Var Idx: Integer); inline;
Var
  nIdx: Integer;
Begin
  Inc(NumSV);
  If NumSV >= SVLen Then Begin
    Inc(SVLen);
    SetLength(StrVars, SVLen);
  End;
  If SP_ProcStackPtr > -1 Then Begin
    Idx := SVLen -1;
    nIdx := Idx;
    While nIdx > SP_ProcStack[0].VarPosS -1 Do Begin
      StrVars[nIdx] := StrVars[nIdx-1];
      Dec(nIdx);
    End;
    nIdx := 0;
    While nIdx <= SP_ProcStackPtr Do Begin
      Inc(SP_ProcStack[nIdx].VarPosS);
      Inc(nIdx);
    End;
  End Else
    Idx := NumSV -1;
  If StrVars[Idx] = nil Then
    StrVars[Idx] := New(pSP_StrVar);
End;

Function SP_UpdateNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer; inline;
Begin

  If Idx = 0 Then Begin
    Idx := SP_FindNumVar(Name);
    If Idx = -1 Then Begin
      Idx := SP_NewNumVar;
      NumVars[Idx]^.Name := Name;
      NumVars[Idx]^.ProcVar := SP_ProcStackPtr > -1;
      NumVars[Idx]^.Content.VarType := SP_SIMPLE;
      NumVars[Idx]^.ContentPtr := @NumVars[Idx]^.Content;
      If Not NumVars[idx]^.ProcVar Then Ptr^ := Idx +1;
    End;
  End Else
    Dec(Idx);

  NumVars[Idx]^.ContentPtr^.Value := Value;
  Result := Idx;

End;

Procedure SP_UpdateNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Begin

  NumVars[Idx -1]^.ContentPtr^.Value := Value;

End;

Function  SP_IncNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Begin

  If Idx = 0 Then Begin
    Idx := SP_FindNumVar(Name);
    If Idx = -1 Then Begin
      Error.Code := SP_ERR_MISSING_VAR;
      Exit;
    End;
    If Not NumVars[idx]^.ProcVar Then Ptr^ := Idx +1;
  End Else
    Dec(Idx);

  NumVars[Idx]^.ContentPtr^.Value := NumVars[Idx]^.ContentPtr^.Value + Value;
  Result := Idx;

End;

Procedure SP_IncNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Begin

  NumVars[Idx -1]^.ContentPtr^.Value := NumVars[Idx -1]^.ContentPtr^.Value + Value;

End;

Function  SP_DecNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Begin

  If Idx = 0 Then Begin
    Idx := SP_FindNumVar(Name);
    If Idx = -1 Then Begin
      Error.Code := SP_ERR_MISSING_VAR;
      Exit;
    End;
    If Not NumVars[idx]^.ProcVar Then Ptr^ := Idx +1;
  End Else
    Dec(Idx);

  NumVars[Idx]^.ContentPtr^.Value := NumVars[Idx]^.ContentPtr^.Value - Value;
  Result := Idx;

End;

Procedure SP_DecNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Begin

  NumVars[Idx -1]^.ContentPtr^.Value := NumVars[Idx -1]^.ContentPtr^.Value - Value;

End;

Function  SP_MulNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Begin

  If Idx = 0 Then Begin
    Idx := SP_FindNumVar(Name);
    If Idx = -1 Then Begin
      Error.Code := SP_ERR_MISSING_VAR;
      Exit;
    End;
    If Not NumVars[idx]^.ProcVar Then Ptr^ := Idx +1;
  End Else
    Dec(Idx);

  NumVars[Idx]^.ContentPtr^.Value := NumVars[Idx]^.ContentPtr^.Value * Value;
  Result := Idx;

End;

Procedure SP_MulNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Begin

  NumVars[Idx -1]^.ContentPtr^.Value := NumVars[Idx -1]^.ContentPtr^.Value * Value;

End;

Function  SP_DivNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Begin

  If Idx = 0 Then Begin
    Idx := SP_FindNumVar(Name);
    If Idx = -1 Then Begin
      Error.Code := SP_ERR_MISSING_VAR;
      Exit;
    End;
    If Not NumVars[idx]^.ProcVar Then Ptr^ := Idx +1;
  End Else
    Dec(Idx);

  If Value <> 0 Then
    NumVars[Idx]^.ContentPtr^.Value := NumVars[Idx]^.ContentPtr^.Value / Value
  Else
    Error.Code := SP_ERR_DIV_BY_ZERO;
  Result := Idx;

End;

Procedure SP_DivNumVarIndex(Idx: Integer; Var Value: aFloat; Var Error: TSP_ErrorCode); inline;
Begin

  If Value <> 0 Then
    NumVars[Idx -1]^.ContentPtr^.Value := NumVars[Idx -1]^.ContentPtr^.Value / Value
  Else
    Error.Code := SP_ERR_DIV_BY_ZERO;

End;

Function  SP_PowNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Begin

  If Idx = 0 Then Begin
    Idx := SP_FindNumVar(Name);
    If Idx = -1 Then Begin
      Error.Code := SP_ERR_MISSING_VAR;
      Exit;
    End;
    If Not NumVars[idx]^.ProcVar Then Ptr^ := Idx +1;
  End Else
    Dec(Idx);

  NumVars[Idx]^.ContentPtr^.Value := Power(NumVars[Idx]^.ContentPtr^.Value, Value);
  Result := Idx;

End;

Procedure SP_PowNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Begin

  NumVars[Idx -1]^.ContentPtr^.Value := Power(NumVars[Idx -1]^.ContentPtr^.Value, Value);

End;

Function  SP_ModNumVar(Idx: Integer; const Name: aString; Var Value: NativeUInt; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Begin

  If Idx = 0 Then Begin
    Idx := SP_FindNumVar(Name);
    If Idx = -1 Then Begin
      Error.Code := SP_ERR_MISSING_VAR;
      Exit;
    End;
    If Not NumVars[idx]^.ProcVar Then Ptr^ := Idx +1;
  End Else
    Dec(Idx);

  If Value <> 0 Then
    NumVars[Idx]^.ContentPtr^.Value := SP_ModCalc(Round(NumVars[Idx]^.ContentPtr^.Value), Value)
  Else
    Error.Code := SP_ERR_DIV_BY_ZERO;
  Result := Idx;

End;

Procedure SP_ModNumVarIndex(Idx: Integer; Var Value: NativeUInt; Var Error: TSP_ErrorCode); inline;
Begin

  If Value <> 0 Then
    NumVars[Idx -1]^.ContentPtr^.Value := SP_ModCalc(Round(NumVars[Idx -1]^.ContentPtr^.Value), Value)
  Else
    Error.Code := SP_ERR_DIV_BY_ZERO;

End;

Function  SP_AndNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Begin

  If Idx = 0 Then Begin
    Idx := SP_FindNumVar(Name);
    If Idx = -1 Then Begin
      Error.Code := SP_ERR_MISSING_VAR;
      Exit;
    End;
    If Not NumVars[idx]^.ProcVar Then Ptr^ := Idx +1;
  End Else
    Dec(Idx);

  NumVars[Idx]^.ContentPtr^.Value := Round(NumVars[Idx]^.ContentPtr^.Value) And Round(Value);
  Result := Idx;

End;

Procedure SP_AndNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Begin

  NumVars[Idx -1]^.ContentPtr^.Value := Round(NumVars[Idx -1]^.ContentPtr^.Value) And Round(Value);

End;

Function  SP_OrNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Begin

  If Idx = 0 Then Begin
    Idx := SP_FindNumVar(Name);
    If Idx = -1 Then Begin
      Error.Code := SP_ERR_MISSING_VAR;
      Exit;
    End;
    If Not NumVars[idx]^.ProcVar Then Ptr^ := Idx +1;
  End Else
    Dec(Idx);

  NumVars[Idx]^.ContentPtr^.Value := Round(NumVars[Idx]^.ContentPtr^.Value) Or Round(Value);
  Result := Idx;

End;

Procedure SP_OrNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Begin

  NumVars[Idx -1]^.ContentPtr^.Value := Round(NumVars[Idx -1]^.ContentPtr^.Value) Or Round(Value);

End;

Function  SP_XorNumVar(Idx: Integer; const Name: aString; Var Value: aFloat; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Begin

  If Idx = 0 Then Begin
    Idx := SP_FindNumVar(Name);
    If Idx = -1 Then Begin
      Error.Code := SP_ERR_MISSING_VAR;
      Exit;
    End;
    If Not NumVars[idx]^.ProcVar Then Ptr^ := Idx +1;
  End Else
    Dec(Idx);

  NumVars[Idx]^.ContentPtr^.Value := Round(NumVars[Idx]^.ContentPtr^.Value) Xor Round(Value);
  Result := Idx;

End;

Procedure SP_XorNumVarIndex(Idx: Integer; Var Value: aFloat); inline;
Begin

  NumVars[Idx -1]^.ContentPtr^.Value := Round(NumVars[Idx -1]^.ContentPtr^.Value) Xor Round(Value);

End;

Function SP_UpdateFORVar(Idx: Integer; const Name: aString; Var Value, EndAt, Step: aFloat; LoopLine, LoopStatement, St: Integer; Ptr: pLongWord; Var Error: TSP_ErrorCode): Integer;
Begin

  If Idx = 0 Then Begin
    Idx := SP_FindNumVar(Name);
    If Idx = -1 Then Begin
      Idx := SP_NewNumVar;
      NumVars[Idx]^.Name := Name;
      NumVars[Idx]^.ProcVar := SP_ProcStackPtr > -1;
      NumVars[Idx]^.ContentPtr := @NumVars[Idx]^.Content;
      If Not NumVars[Idx]^.ProcVar Then Ptr^ := Idx +1;
    End;
  End Else
    Idx := Idx -1;

  NumVars[Idx]^.ContentPtr^.InitVal := Value;
  NumVars[Idx]^.ContentPtr^.Value := Value;
  NumVars[Idx]^.ContentPtr^.EndAt := EndAt;
  NumVars[Idx]^.ContentPtr^.Step := Step;
  NumVars[Idx]^.ContentPtr^.LoopLine := LoopLine;
  NumVars[Idx]^.ContentPtr^.LoopStatement := LoopStatement;
  NumVars[Idx]^.ContentPtr^.St := St;
  NumVars[Idx]^.ContentPtr^.Count := 0;
  NumVars[Idx]^.ContentPtr^.VarType := SP_FORVAR;

  Result := Idx;

End;

Function  SP_GetStrVarPtr(Idx: Integer; const Name: aString; Var Error: TSP_ErrorCode; Ptr: pLongWord): pSP_StrVarContent;
Begin

  If Idx = 0 Then Begin
    Idx := SP_FindStrVar(Name);
    If Idx = -1 Then Begin
      Idx := SP_NewStrVar;
      StrVars[Idx]^.Name := Name;
      StrVars[Idx]^.ProcVar := SP_ProcStackPtr > -1;
      StrVars[Idx]^.ContentPtr := @StrVars[Idx]^.Content;
      StrVars[Idx]^.ContentPtr^.StructName := '';
      StrVars[Idx]^.ContentPtr^.VarType := SP_STRVAR;
      StrVars[Idx]^.ContentPtr^.DLen := 0;
      If Not StrVars[Idx]^.ProcVar Then Ptr^ := Idx +1;
    End;
  End Else
    Dec(Idx);

  Result := StrVars[Idx]^.ContentPtr;

End;

Function  SP_UpdateStrVar(Idx: Integer; Const Name: aString; Value: aString; aSliceFrom, aSliceTo: Integer; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Var
  cIdx, SliceLen, Len: Integer;
Begin

  If Idx = 0 Then Begin
    Idx := SP_FindStrVar(Name);
    If Idx = -1 Then Begin
      Idx := SP_NewStrVar;
      StrVars[Idx]^.Name := Name;
      StrVars[Idx]^.ProcVar := SP_ProcStackPtr > -1;
      StrVars[Idx]^.ContentPtr := @StrVars[Idx]^.Content;
      StrVars[Idx]^.ContentPtr^.StructName := '';
      StrVars[Idx]^.ContentPtr^.VarType := SP_STRVAR;
      StrVars[Idx]^.ContentPtr^.DLen := 0;
      If Not StrVars[Idx]^.ProcVar Then Ptr^ := Idx +1;
    End;
  End Else
    Dec(Idx);

  If StrVars[Idx]^.ContentPtr^.SliceFrom > 0 Then
    If aSliceFrom > 0 Then Begin
      Inc(aSliceFrom, StrVars[Idx]^.ContentPtr^.SliceFrom -1);
      If aSliceTo > 0 Then
        Inc(aSliceTo, StrVars[Idx]^.ContentPtr^.SliceFrom -1);
    End;

  If StrVars[Idx]^.ContentPtr^.SliceTo > 0 Then
    If aSliceTo > StrVars[Idx]^.ContentPtr^.SliceTo Then
      aSliceTo := StrVars[Idx]^.ContentPtr^.SliceTo;

  If (aSliceFrom = -1) And (aSliceTo = -1) Then
    StrVars[Idx]^.ContentPtr^.Value := Value
  Else Begin
    If aSliceFrom = -1 Then
      aSliceFrom := 1;
    If (aSliceTo = -1) or (aSliceTo > Length(StrVars[Idx]^.ContentPtr^.Value)) Then
      aSliceTo := Length(StrVars[Idx]^.ContentPtr^.Value);
    SliceLen := (aSliceTo - aSliceFrom) +1;
    While Length(Value) < SliceLen Do
      Value := Value + ' ';
    For cIdx := aSliceFrom To aSliceTo Do
      StrVars[Idx]^.ContentPtr^.Value[cIdx] := Value[(cIdx - aSliceFrom)+1];
  End;

  If StrVars[Idx]^.ContentPtr^.DLen > 0 Then Begin
    Len := Length(StrVars[Idx]^.ContentPtr^.Value);
    If Len < StrVars[Idx]^.ContentPtr^.DLen Then Begin
      SetLength(StrVars[Idx]^.ContentPtr^.Value, StrVars[Idx]^.ContentPtr^.DLen);
      For cIdx := Len +1 To StrVars[Idx]^.ContentPtr^.DLen Do
        StrVars[Idx]^.ContentPtr^.Value[cIdx] := ' ';
    End Else
      If Len > StrVars[Idx]^.ContentPtr^.DLen Then
        StrVars[Idx]^.ContentPtr^.Value := Copy(StrVars[Idx]^.ContentPtr^.Value, 1, StrVars[Idx]^.ContentPtr^.DLen);
  End;

  Result := Idx;

End;

Procedure SP_UpdateStrVarIndex(Idx: Integer; Value: aString);
Begin

  StrVars[Idx -1]^.ContentPtr^.Value := Value

End;

// *******************
// * Array handling! *
// *******************

Procedure SP_CopyNumArray(SrcIdx, DstIdx: Integer; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  nVar: pSP_NumVarContent;
  Ptr, nPtr: pHashEntry;
Begin

  // sIdx and dIdx are valid array index markers at this point.

  SP_RemoveNumArray(DstIdx);

  NumArrays[DstIdx].Size := NumArrays[SrcIdx].Size;
  NumArrays[DstIdx].NumIndices := NumArrays[SrcIdx].NumIndices;
  NumArrays[DstIdx].Base := NumArrays[SrcIdx].Base;
  NumArrays[DstIdx].DynArray := NumArrays[SrcIdx].DynArray;

  SetLength(NumArrays[DstIdx].Indices, NumArrays[SrcIdx].NumIndices);
  For Idx := 0 To NumArrays[SrcIdx].NumIndices -1 Do
    NumArrays[DstIdx].Indices[Idx] := NumArrays[SrcIdx].Indices[Idx];

  SetLength(NumArrays[DstIdx].Values, NumArrays[SrcIdx].Size);
  For Idx := 0 To Length(NumArrays[SrcIdx].Values) -1 Do Begin
    nVar := New(pSP_NumVarContent);
    CopyMem(@nVar^, @NumArrays[SrcIdx].Values[Idx]^, SizeOf(TSP_NumVarContent));
    nVar^.EachTokens := NumArrays[SrcIdx].Values[Idx]^.EachTokens;
    nVar^.Key := NumArrays[SrcIdx].Values[Idx]^.Key;
    NumArrays[DstIdx].Values[Idx] := nVar;
  End;

  For Idx := 0 To 255 Do Begin
    Ptr := NumArrays[DstIdx].Hashes[Idx];
    While Ptr <> nil Do Begin
      nPtr := Ptr^.NextHash;
      Dispose(Ptr);
      Ptr := nPtr;
    End;
    NumArrays[DstIdx].Hashes[Idx] := Nil;
    Ptr := NumArrays[SrcIdx].Hashes[Idx];
    If Ptr <> Nil Then Begin
      NumArrays[DstIdx].Hashes[Idx] := New(pHashEntry);
      nPtr := NumArrays[DstIdx].Hashes[Idx];
      nPtr^.Key := Ptr^.Key;
      nPtr^.Index := Ptr^.Index;
      nPtr^.NextHash := Nil;
      Ptr := Ptr^.NextHash;
      While Ptr <> Nil Do Begin
        nPtr^.NextHash := New(pHashEntry);
        nPtr := nPtr^.NextHash;
        nPtr^.Key := Ptr^.Key;
        nPtr^.Index := Ptr^.Index;
        nPtr^.NextHash := Nil;
        Ptr := Ptr^.NextHash;
      End;
    End;
  End;

  If NumArrays[DstIdx].DynArray Then Begin
    For Idx := 0 To Length(NumArrays[DstIdx].DynHashes) -1 Do Begin
      Ptr := NumArrays[DstIdx].DynHashes[Idx];
      While Ptr <> nil Do Begin
        nPtr := Ptr^.NextHash;
        Dispose(Ptr);
        Ptr := nPtr;
      End;
      NumArrays[DstIdx].DynHashes[Idx] := Nil;
      Ptr := NumArrays[SrcIdx].DynHashes[Idx];
      If Ptr <> Nil Then Begin
        NumArrays[DstIdx].DynHashes[Idx] := New(pHashEntry);
        nPtr := NumArrays[DstIdx].DynHashes[Idx];
        nPtr^.Key := Ptr^.Key;
        nPtr^.Index := Ptr^.Index;
        nPtr^.NextHash := Nil;
        Ptr := Ptr^.NextHash;
        While Ptr <> Nil Do Begin
          nPtr^.NextHash := New(pHashEntry);
          nPtr := nPtr^.NextHash;
          nPtr^.Key := Ptr^.Key;
          nPtr^.Index := Ptr^.Index;
          nPtr^.NextHash := Nil;
          Ptr := Ptr^.NextHash;
        End;
      End;
    End;
  End;

End;

Function SP_CreateNumArray(const Name: aString; const Indices: aString; Base: Integer; Dyn: Boolean; Var Error: TSP_ErrorCode): Integer;
Var
  Idx, pIdx, IndexCount: Integer;
  LongWordPtr: pLongWord;
Begin

  // Indices are dimensions, stored in 4byte longword format.
  // If indices are blank ('') then this is a dynamic array.

  Idx := SP_FindNumArray(Name);
  If Idx > -1 Then
    SP_RemoveNumArray(Idx)
  Else Begin
    SetLength(NumArrays, Length(NumArrays)+1);
    Idx := Length(NumArrays) -1;
  End;

  If Indices <> '' Then Begin
    pIdx := 1;
    IndexCount := 1;
    SetLength(NumArrays[Idx].Indices, Length(Indices) Div 4);
    While pIdx < Length(Indices) Do Begin
      LongWordPtr := @Indices[pIdx];
      IndexCount := IndexCount * integer(LongWordPtr^);
      If IndexCount < 0 Then Begin
        SetLength(NumArrays, Length(NumArrays) -1);
        Error.Code := SP_ERR_OUT_OF_MEMORY;
        Exit;
      End;
      NumArrays[Idx].Indices[pIdx Div 4] := LongWordPtr^;
      Inc(pIdx, 4);
    End;
    NumArrays[Idx].NumIndices := Length(Indices) Div 4;
    NumArrays[Idx].DynArray := False;
  End Else Begin
    IndexCount := 0;
    NumArrays[Idx].DynArray := True;
    SetLength(NumArrays[Idx].DynHashes, 65536);
    For pIdx := 0 To 65535 Do NumArrays[Idx].DynHashes[pIdx] := Nil;
  End;
  NumArrays[Idx].Size := IndexCount;
  NumArrays[Idx].Name := Name;
  NumArrays[Idx].LastSearchIdx := -1;
  NumArrays[Idx].LastSearchTerm := 0;
  SetLength(NumArrays[Idx].Values, IndexCount);
  For pIdx := 0 To IndexCount -1 Do Begin
    NumArrays[Idx].Values[pIdx] := New(pSP_NumVarContent);
    NumArrays[Idx].Values[pIdx]^.Value := 0;
  End;
  NumArrays[Idx].Base := Base;
  For pIdx := 0 To 255 Do NumArrays[Idx].Hashes[pIdx] := Nil;
  Result := Idx;

End;

Procedure SP_TruncateNumArrays(Count: Integer);
Var
  Idx: Integer;
Begin

  Idx := Length(NumArrays) -1;
  While Idx > Count Do Begin

    SP_RemoveNumArray(Idx);
    Dec(Idx);

  End;

  If Count < 0 Then Count := 0;
  SetLength(NumArrays, Count);

End;

Procedure SP_RemoveNumArray(Idx: Integer);
Var
  pIdx: Integer;
  Ptr, nPtr: pHashEntry;
Begin

  For pIdx := 0 To Length(NumArrays[Idx].Values) -1 Do
    Dispose(NumArrays[Idx].Values[pIdx]);
  SetLength(NumArrays[Idx].Values, 0);
  SetLength(NumArrays[Idx].Indices, 0);
  For pIdx := 0 To 255 Do Begin
    Ptr := NumArrays[Idx].Hashes[pIdx];
    While Ptr <> nil Do Begin
      nPtr := Ptr^.NextHash;
      Dispose(Ptr);
      Ptr := nPtr;
    End;
    NumArrays[Idx].Hashes[pIdx] := Nil;
  End;
  NumArrays[Idx].Size := 0;
  If NumArrays[Idx].DynArray Then Begin
    For pIdx := 0 To 65535 Do Begin
      Ptr := NumArrays[Idx].DynHashes[pIdx];
      While Ptr <> nil Do Begin
        nPtr := Ptr^.NextHash;
        Dispose(Ptr);
        Ptr := nPtr;
      End;
      NumArrays[Idx].DynHashes[pIdx] := Nil;
    End;
    SetLength(NumArrays[Idx].DynHashes, 0);
  End;

End;

Procedure SP_DeleteNumArray(Const Name: aString; Var Error: TSP_ErrorCode);
Var
  Idx, aIdx: Integer;
Begin

  aIdx := SP_FindNumArray(Name);
  If aIdx > -1 Then Begin

    SP_RemoveNumArray(aIdx);
    SP_ClearVarIndices;

    If aIdx < Length(NumArrays) -1 Then Begin

      For Idx := aIdx To Length(NumArrays) -2 Do
        NumArrays[Idx] := NumArrays[Idx +1];

    End;

    SetLength(NumArrays, Length(NumArrays) -1);

  End Else
    Error.Code := SP_ERR_ARRAY_NOT_FOUND;

End;

Function  SP_NumArrayGetIndex(Idx: Integer; Const Indices, Key: aString; Var Error: TSP_ErrorCode): Integer;
Var
  Ln, iIdx, tIdx, Index, vLen: Integer;
  nHash: pHashEntry;
  pIdx: pLongWord;
Label
  SubWrong;
Begin

  If Not NumArrays[Idx].DynArray Then Begin
    If Key = '' Then Begin
      Ln := Length(Indices) Div SizeOf(LongWord);
      If Ln <> NumArrays[Idx].NumIndices Then Goto SubWrong;
      pIdx := pLongWord(pNativeUInt(@Indices)^);
      iIdx := 0;
      Result := 0;
      vLen := NumArrays[Idx].Size;
      While iIdx < Ln Do Begin
        tIdx := NumArrays[Idx].Indices[iIdx];
        Index := integer(pIdx^) - NumArrays[Idx].Base;
        If (Index >= tIdx) or (Index < 0) Then Goto SubWrong;
        vLen := vLen Div tIdx;
        Result := Result + (Index * vLen);
        Inc(pIdx);
        Inc(iIdx);
      End;
    End Else Begin
      Result := SP_GetNumArrayKey(Idx, Key);
      If Result = -1 Then
        Error.Code := SP_ERR_KEY_NOT_FOUND;
    End;
  End Else Begin
    If Key = '' Then Begin
      nHash := NumArrays[Idx].DynHashes[pWord(@Indices[1])^];
      While nHash <> nil Do Begin
        If nHash^.Key = Indices Then Begin
          Result := nHash^.Index;
          Exit;
        End Else
          nHash := nHash^.NextHash;
      End;
      Goto SubWrong;
    End Else Begin
      Result := SP_GetNumArrayKey(Idx, Key);
      If Result = -1 Then
        Error.Code := SP_ERR_KEY_NOT_FOUND;
    End;
  End;
  Exit;

  SubWrong:
  Error.Code := SP_ERR_SUBSCRIPT_WRONG

End;

Function SP_GetKeyFromNumArray(Idx: Integer; Const Indices, Key: aString; Var Error: TSP_ErrorCode): aString;
Var
  Offset: Integer;
Begin

  // Get the key associated with an array element

  Offset := SP_NumArrayGetIndex(Idx, Indices, Key, Error);
  If Error.Code = SP_ERR_OK Then Result := NumArrays[Idx].Values[Offset]^.Key Else Result := '';

End;

Procedure SP_SetNumArrayKey(Idx: Integer; Const Indices, Key, NewKey: aString;  Var Error: TSP_ErrorCode);
Var
  Offset, OldKey: Integer;
  Ptr, LastPtr: pHashEntry;
Begin

  // Set an associative key to an array element. First, figure out which element.

  Offset := SP_NumArrayGetIndex(Idx, Indices, Key, Error);

  If Error.Code = SP_ERR_OK Then Begin

    // Check if NewKey isn't used anywhere else. Keys *are* case-sensitive.

    OldKey := SP_GetNumArrayKey(Idx, NewKey);
    If OldKey <> -1 Then
      SP_NumArrayRemoveKey(Idx, OldKey, NewKey);

    // Now check that the desired element doesn't already have a key, and remove it if it does

    If NumArrays[Idx].Values[Offset]^.Key <> '' Then
      SP_NumArrayRemoveKey(Idx, Offset, NumArrays[Idx].Values[Offset]^.Key);

    // Ok, now set the key. As well as living in the element themselves, we also need to update the hash-table.

    LastPtr := nil;
    Ptr := NumArrays[Idx].Hashes[Ord(NewKey[1])];
    While Ptr <> Nil Do Begin
      LastPtr := Ptr;
      Ptr := Ptr^.NextHash;
    End;
    Ptr := New(pHashEntry);
    StringFromPtrD(NewKey, Ptr^.Key);
    Ptr^.Index := Offset;
    Ptr^.NextHash := Nil;
    If LastPtr <> Nil Then
      LastPtr^.NextHash := Ptr
    Else
      NumArrays[Idx].Hashes[Ord(NewKey[1])] := Ptr;

    StringFromPtrD(NewKey, NumArrays[Idx].Values[Offset]^.Key);

  End;

End;

Function SP_UpdateNumArray(Var Idx: Integer; const Name: aString; const Indices, Key: ansiString; Var Value: aFloat; Var Error: TSP_ErrorCode): Integer; inline;
Var
  Offset: Integer;
  LastPtr, Ptr: pHashEntry;
Begin

  Result := 0;
  If Idx = 0 Then Begin
    Idx := SP_FindNumArray(Name);
    If Idx = -1 Then Begin
      Error.Code := SP_ERR_ARRAY_NOT_FOUND;
      Exit;
    End;
  End Else
    Dec(Idx);

  Offset := SP_NumArrayGetIndex(Idx, Indices, Key, Error);
  If Error.Code = SP_ERR_OK Then Begin
    NumArrays[Idx].Values[Offset]^.Value := Value;
    Result := Idx;
  End Else Begin
    If NumArrays[Idx].DynArray And ((Error.Code = SP_ERR_SUBSCRIPT_WRONG) or (Error.Code = SP_ERR_KEY_NOT_FOUND)) Then Begin
      Inc(NumArrays[Idx].Size);
      SetLength(NumArrays[Idx].Values, NumArrays[Idx].Size);
      Offset := NumArrays[Idx].Size -1;
      NumArrays[Idx].Values[Offset] := New(pSP_NumVarContent);
      NumArrays[Idx].Values[Offset]^.Value := Value;
      Result := Idx;
      LastPtr := nil;
      If Indices <> '' Then
        Ptr := NumArrays[Idx].DynHashes[pWord(@Indices[1])^]
      Else
        Ptr := NumArrays[Idx].Hashes[Ord(Key[1])];
      While Ptr <> Nil Do Begin
        LastPtr := Ptr;
        Ptr := Ptr^.NextHash;
      End;
      Ptr := New(pHashEntry);
      If Indices <> '' Then
        StringFromPtrD(Indices, Ptr^.Key)
      Else
        StringFromPtrD(Key, Ptr^.Key);
      Ptr^.Index := Offset;
      Ptr^.NextHash := Nil;
      If LastPtr <> Nil Then
        LastPtr^.NextHash := Ptr
      Else
        If Indices <> '' Then
          NumArrays[Idx].DynHashes[pWord(@Indices[1])^] := Ptr
        Else Begin
          NumArrays[Idx].Hashes[Ord(Key[1])] := Ptr;
          StringFromPtrD(Key, NumArrays[Idx].Values[Offset]^.Key);
        End;
      Error.Code := SP_ERR_OK;
    End;
  End;

End;

Function SP_GetNumArrayKey(Idx: Integer; Const Key: aString): Integer;
Var
  nHash: pHashEntry;
Begin

  // Search a numeric array for a particular key.
  // If not found, result is -1. Otherwise it gives the index of that key.

  Result := -1;
  nHash := NumArrays[Idx].Hashes[Ord(Key[1])];

  While nHash <> nil Do Begin

    If nHash^.Key = Key Then Begin

      Result := nHash^.Index;
      Exit;

    End Else

      nHash := nHash^.NextHash;

  End;

End;

Function SP_FindNumArrayHash(Idx: Integer; Const Key: aString): pHashEntry; Inline;
Begin
  Result := NumArrays[Idx].Hashes[Ord(Key[1])];
  While Result <> nil Do Begin
    If Result^.Key = Key Then
      Break
    Else
      Result := Result^.NextHash;
  End;
End;

Procedure SP_NumArrayRemoveKey(Idx, Index: Integer; Const Key: aString);
Var
  Ptr, LastPtr: pHashEntry;
Begin

  Ptr := NumArrays[Idx].Hashes[Ord(Key[1])];
  LastPtr := Ptr;
  While Ptr^.Index <> Index Do Begin
    LastPtr := Ptr;
    Ptr := Ptr^.NextHash;
  End;
  If LastPtr <> Ptr Then Begin
    LastPtr^.NextHash := Ptr^.NextHash;
    Dispose(Ptr);
  End Else Begin
    Dispose(Ptr);
    NumArrays[Idx].Hashes[Ord(Key[1])] := nil;
  End;
  NumArrays[Idx].Values[Index]^.Key := '';

End;

Function SP_GetNumArrayPtr(Idx: Integer; const Name: aString; const Indices, Key: aString; Var Error: TSP_ErrorCode): pSP_NumVarContent; inline;
Var
  Offset: Integer;
Begin

  Result := nil;
  If Idx = 0 Then Begin
    Idx := SP_FindNumArray(Name);
    If Idx = -1 Then Begin
      Error.Code := SP_ERR_ARRAY_NOT_FOUND;
      Exit;
    End;
  End Else
    Dec(Idx);

  Offset := SP_NumArrayGetIndex(Idx, Indices, Key, Error);
  If Error.Code = SP_ERR_OK Then
    Result := NumArrays[Idx].Values[Offset];

End;

Function SP_QueryNumArray(Var Idx: Integer; Var Indices, Key: aString; Var Error: TSP_ErrorCode): aFloat; inline;
Var
  Offset: Integer;
Begin

  Result := 0;

  Offset := SP_NumArrayGetIndex(Idx, Indices, Key, Error);
  If Error.Code = SP_ERR_OK Then
    Result := NumArrays[Idx].Values[Offset]^.Value;

End;

Procedure SP_FillNumArray(Var Idx: Integer; Value: aFloat);
Var
  iIdx: Integer;
Begin

  With NumArrays[Idx] Do
    For iIdx := 0 To Length(Values) -1 Do
      Values[iIdx]^.Value := Value;

End;

Function SP_ValueInNumArray(Const Name: aString; Term: aFloat; Var Error: TSP_ErrorCode): Boolean;
Var
  Idx, sIdx: Integer;
Begin

  // Searches the specified array for the term supplied, returns true or false.

  Result := False;
  Idx := SP_FindNumArray(Name);
  If Idx = -1 Then Begin
    Error.Code := SP_ERR_ARRAY_NOT_FOUND;
    Exit;
  End;

  For sIdx := 0 To NumArrays[Idx].Size -1 Do Begin

    If NumArrays[Idx].Values[sIdx].Value = Term Then Begin
      Result := True;
      Exit;
    End;

  End;

End;

Function SP_SearchNumArray(Const Name: aString; Term: aFloat; Var Error: TSP_ErrorCode): Integer;
Var
  Idx, sIdx: Integer;
Begin

  // Searches the specified array for the term supplied.

  Result := -1;
  Idx := SP_FindNumArray(Name);
  If Idx = -1 Then Begin
    Error.Code := SP_ERR_ARRAY_NOT_FOUND;
    Exit;
  End;

  If NumArrays[Idx].NumIndices <> 1 Then Begin
    Error.Code := SP_ERR_UNSUITABLE_ARRAY;
    Exit;
  End Else Begin

    NumArrays[Idx].LastSearchTerm := Term;
    NumArrays[Idx].LastSearchIdx := -1;

    For sIdx := 0 To NumArrays[Idx].Size -1 Do Begin

      If NumArrays[Idx].Values[sIdx].Value = Term Then Begin
        Result := sIdx + NumArrays[Idx].Base;
        NumArrays[Idx].LastSearchIdx := sIdx;
        Exit;
      End;

    End;

  End;

End;

Function SP_StringInStrArray(Const Name: aString; Term: aString; Var Error: TSP_ErrorCode): Boolean;
Var
  Idx, sIdx: Integer;
Begin

  // Searches the specified array for the term supplied, returns true or false.

  Result := False;
  Idx := SP_FindStrArray(Name);
  If Idx = -1 Then Begin
    Error.Code := SP_ERR_ARRAY_NOT_FOUND;
    Exit;
  End;

  For sIdx := 0 To StrArrays[Idx].Size -1 Do Begin

    If StrArrays[Idx].Strings[sIdx]^.Value = Term Then Begin
      Result := True;
      Exit;
    End;

  End;

End;

Function SP_SearchNumArrayNext(Const Name: aString; Var Error: TSP_ErrorCode): Integer;
Var
  Idx, sIdx: Integer;
Begin

  // Searches the specified array for the next instance of the term supplied.

  Result := -1;
  Idx := SP_FindNumArray(Name);
  If Idx = -1 Then Begin
    Error.Code := SP_ERR_ARRAY_NOT_FOUND;
    Exit;
  End;

  If NumArrays[Idx].NumIndices <> 1 Then Begin
    Error.Code := SP_ERR_UNSUITABLE_ARRAY;
    Exit;
  End Else Begin

    If NumArrays[Idx].LastSearchIdx > -1 Then Begin

      For sIdx := NumArrays[Idx].LastSearchIdx +1 To NumArrays[Idx].Size -1 Do Begin

        If NumArrays[Idx].Values[sIdx].Value = NumArrays[Idx].LastSearchTerm Then Begin
          Result := sIdx + NumArrays[Idx].Base;
          NumArrays[Idx].LastSearchIdx := sIdx;
          Exit;
        End;

      End;

    End;

  End;

End;

Function SP_CreateStrArray(const Name: aString; const Indices: aString; DLen: Integer; const StructName: aString; Base: Integer; Dyn: Boolean; Var Error: TSP_ErrorCode): Integer;
Var
  Idx, pIdx, sIdx, cIdx, IndexCount: Integer;
  LongWordPtr: pLongWord;
  Content: aString;
Begin

  If StructName <> '' Then Begin
    sIdx := SP_FindStruct(StructName);
    If sIdx <> -1 Then
      Content := SP_GetDefaultFields(sIdx)
    Else Begin
      Error.Code := SP_ERR_STRUCT_NOT_FOUND;
      Exit;
    End;
  End Else
    sIdx := -1;

  // Indices are dimensions, stored in 4byte longword format.

  Idx := SP_FindStrArray(Name);
  If Idx > -1 Then Begin
    SP_RemoveStrArray(Idx);
  End Else Begin
    SetLength(StrArrays, Length(StrArrays)+1);
    Idx := Length(StrArrays) -1;
  End;

  If Indices <> '' Then Begin
    pIdx := 1;
    IndexCount := 1;
    SetLength(StrArrays[Idx].Indices, Length(Indices) Div 4);
    While pIdx < Length(Indices) Do Begin
      LongWordPtr := @Indices[pIdx];
      IndexCount := IndexCount * integer(LongWordPtr^);
      StrArrays[Idx].Indices[pIdx Div 4] := LongWordPtr^;
      Inc(pIdx, 4);
    End;
  End Else Begin
    IndexCount := 0;
    StrArrays[Idx].DynArray := True;
    SetLength(StrArrays[Idx].DynHashes, 65536);
    For pIdx := 0 To 65535 Do StrArrays[Idx].DynHashes[pIdx] := Nil;
  End;

  StrArrays[Idx].Size := IndexCount;
  StrArrays[Idx].NumIndices := Length(Indices) Div 4;
  StrArrays[Idx].Name := Name;
  StrArrays[Idx].LastSearchIdx := -1;
  StrArrays[Idx].LastSearchTerm := '';
  SetLength(StrArrays[Idx].Strings, IndexCount);
  For pIdx := 0 To IndexCount -1 Do Begin
    StrArrays[Idx].Strings[pIdx] := New(pSP_StrVarContent);
    StrArrays[Idx].Strings[pIdx]^.DLen := DLen;
    If DLen = 0 Then Begin
      If sIdx <> -1 Then Begin
        StrArrays[Idx].Strings[pIdx]^.StructName := StructName;
        StrArrays[Idx].Strings[pIdx]^.Value := Content;
      End Else
        StrArrays[Idx].Strings[pIdx]^.Value := '';
    End Else Begin
      SetLength(StrArrays[Idx].Strings[pIdx]^.Value, DLen);
      For cIdx := 1 To DLen Do
        StrArrays[Idx].Strings[pIdx]^.Value[cIdx] := ' ';
    End;
  End;
  For pIdx := 0 To 255 Do StrArrays[Idx].Hashes[pIdx] := Nil;
  StrArrays[Idx].Base := Base;
  StrArrays[Idx].DLen := DLen;

  Result := Idx;

End;

Procedure SP_TruncateStrArrays(Count: Integer);
Var
  Idx: Integer;
Begin

  Idx := Length(StrArrays) -1;
  While Idx > Count Do Begin

    SP_RemoveStrArray(Idx);
    Dec(Idx);

  End;

  If Count < 0 Then Count := 0;
  SetLength(StrArrays, Count);

End;

Procedure SP_RemoveStrArray(Idx: Integer);
Var
  pIdx: Integer;
  ptr, nPtr: pHashEntry;
Begin

  For pIdx := 0 To Length(StrArrays[Idx].Strings) -1 Do
    Dispose(StrArrays[Idx].Strings[pIdx]);
  SetLength(StrArrays[Idx].Strings, 0);
  SetLength(StrArrays[Idx].Indices, 0);
  For pIdx := 0 To 255 Do Begin
    Ptr := StrArrays[Idx].Hashes[pIdx];
    While Ptr <> nil Do Begin
      nPtr := Ptr^.NextHash;
      Dispose(Ptr);
      Ptr := nPtr;
    End;
    StrArrays[Idx].Hashes[pIdx] := Nil;
  End;
  StrArrays[Idx].Size := 0;
  If StrArrays[Idx].DynArray Then Begin
    For pIdx := 0 To 65535 Do Begin
      Ptr := StrArrays[Idx].DynHashes[pIdx];
      While Ptr <> nil Do Begin
        nPtr := Ptr^.NextHash;
        Dispose(Ptr);
        Ptr := nPtr;
      End;
      StrArrays[Idx].DynHashes[pIdx] := Nil;
    End;
    SetLength(StrArrays[Idx].DynHashes, 0);
  End;

End;

Procedure SP_DeleteStrArray(Const Name: aString; Var Error: TSP_ErrorCode);
Var
  Idx, aIdx: Integer;
Begin

  aIdx := SP_FindStrArray(Name);
  If aIdx > -1 Then Begin

    SP_RemoveStrArray(aIdx);
    SP_ClearVarIndices;

    If aIdx < Length(StrArrays) -1 Then Begin

      For Idx := aIdx To Length(StrArrays) -2 Do
        StrArrays[Idx] := StrArrays[Idx +1];

    End;

    SetLength(StrArrays, Length(StrArrays) -1);

  End Else
    Error.Code := SP_ERR_ARRAY_NOT_FOUND;

End;

Function  SP_StrArrayGetIndex(Idx: Integer; Const Indices, Key: aString; Var Error: TSP_ErrorCode): Integer;
Var
  pIdx, Ln, iIdx, tIdx, Index, vLen: Integer;
  Overflow: Boolean;
  nHash: pHashEntry;
Begin

  // Finds a string array element based on Idx (the string array to query) and either
  // the indices or the key.

  // Returns a negative value if an extra index has been supplied - a one character
  // slicer.

  If StrArrays[Idx].DynArray Then Begin
    If Key = '' Then Begin
      nHash := StrArrays[Idx].DynHashes[pWord(@Indices[1])^];
      While nHash <> nil Do Begin
        If nHash^.Key = Indices Then Begin
          Result := nHash^.Index;
          Exit;
        End Else
          nHash := nHash^.NextHash;
      End;
      If nHash = nil Then Begin
        Error.Code := SP_ERR_SUBSCRIPT_WRONG;
        Exit;
      End;
    End Else Begin
      Result := SP_GetStrArrayKey(Idx, Key);
      If Result = -1 Then
        Error.Code := SP_ERR_KEY_NOT_FOUND;
    End;
  End Else Begin
    If Key = '' Then Begin
      Overflow := False;
      Ln := Length(Indices);
      iIdx := Length(StrArrays[Idx].Indices);
      If Ln Div SizeOf(LongWord) <> iIdx Then Begin
        While Ln Div SizeOf(LongWord) > iIdx +1 Do Begin
          If pLongWord(@Indices[Ln - SizeOf(LongWord) +1])^ <> 1 Then Begin
            Error.Code := SP_ERR_SUBSCRIPT_WRONG;
            Exit;
          End Else
            Dec(Ln, SizeOf(LongWord));
        End;
        Overflow := True;
        Dec(Ln, SizeOf(LongWord));
        pLongWord(@Indices[Length(Indices) - SizeOf(LongWord) +1])^ := pLongWord(@Indices[Ln +1])^;
      End;
      pIdx := 1;
      iIdx := 0;
      Result := 0;
      vLen := StrArrays[Idx].Size;
      While pIdx < Ln Do Begin
        tIdx := StrArrays[Idx].Indices[iIdx];
        Index := integer(pLongWord(@Indices[pIdx])^) - StrArrays[Idx].Base;
        If (Index >= tIdx) or (Index < 0) Then Begin
          Error.Code := SP_ERR_SUBSCRIPT_WRONG;
          Exit;
        End;
        vLen := vLen Div tIdx;
        Result := Result + (Index * vLen);
        Inc(pIdx, SizeOf(LongWord));
        Inc(iIdx);
      End;
      If Overflow Then
        Result := -(Result +1);
    End Else Begin
      Result := SP_GetStrArrayKey(Idx, Key);
      If Result = -1 Then Begin
        Error.Code := SP_ERR_KEY_NOT_FOUND;
        Exit;
      End;
    End;
  End;

End;

Function SP_UpdateStrArray(Idx: Integer; const Name, Indices, Key: aString; Phrase: aString; aSliceFrom, aSliceTo: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  pIdx, Index, iIdx, tIdx, Offset, vLen, Len: Integer;
  LastPtr, Ptr: pHashEntry;
  Str: aString;
Begin

  Result := 0;

  // Update a String in an array. The index of the String is specified in "indices" and works like a numeric array.
  // Slicing will be performed on the String, like a normal String value slicer.

  If Idx = 0 Then Begin
    Idx := SP_FindStrArray(Name);
    If Idx = -1 Then Begin
      Error.Code := SP_ERR_ARRAY_NOT_FOUND;
      Exit;
    End;
  End Else
    Dec(Idx);

  Offset := SP_StrArrayGetIndex(Idx, Indices, Key, Error);
  If StrArrays[Idx].DynArray And ((Error.Code = SP_ERR_SUBSCRIPT_WRONG) or (Error.Code = SP_ERR_KEY_NOT_FOUND)) Then Begin
    Inc(StrArrays[Idx].Size);
    SetLength(StrArrays[Idx].Strings, StrArrays[Idx].Size);
    Offset := StrArrays[Idx].Size -1;
    StrArrays[Idx].Strings[Offset] := New(pSP_StrVarContent);
    StrArrays[Idx].Strings[Offset]^.DLen := StrArrays[Idx].DLen;
    Result := Idx;
    LastPtr := nil;
    If Indices <> '' Then
      Ptr := StrArrays[Idx].DynHashes[pWord(@Indices[1])^]
    Else
      Ptr := StrArrays[Idx].Hashes[Ord(Key[1])];
    While Ptr <> Nil Do Begin
      LastPtr := Ptr;
      Ptr := Ptr^.NextHash;
    End;
    Ptr := New(pHashEntry);
    If Indices <> '' Then
      StringFromPtrD(Indices, Ptr^.Key)
    Else
      StringFromPtrD(Key, Ptr^.Key);
    Ptr^.Index := Offset;
    Ptr^.NextHash := Nil;
    If LastPtr <> Nil Then
      LastPtr^.NextHash := Ptr
    Else
      If Indices <> '' Then
        StrArrays[Idx].DynHashes[pWord(@Indices[1])^] := Ptr
      Else Begin
        StrArrays[Idx].Hashes[Ord(Key[1])] := Ptr;
        StringFromPtrD(Key, StrArrays[Idx].Strings[Offset]^.Key);
      End;
    Error.Code := SP_ERR_OK;
  End;

  If Error.Code = SP_ERR_OK Then Begin
    If Offset < 0 Then Begin
      Offset := -(Offset +1);
      aSliceFrom := pLongWord(@Indices[1 + Length(Indices) - SizeOf(LongWord)])^;
      aSliceTo := aSliceFrom;
    End Else Begin
      If (aSliceFrom > -1) or (aSliceTo > -1) Then Begin
        If aSliceFrom = -1 Then aSliceFrom := 1;
        If aSliceTo = -1 Then aSliceTo := Length(StrArrays[Idx].Strings[Offset]^.Value);
        If (aSliceTo > Length(StrArrays[Idx].Strings[Offset]^.Value)) or (aSliceFrom < 1) Then Begin
          Error.Code := SP_ERR_SUBSCRIPT_WRONG;
          Exit;
        End;
      End Else Begin
        aSliceFrom := 1;
        aSliceTo := Length(Phrase);
        With StrArrays[Idx].Strings[Offset]^ Do Begin
          Value := Phrase;
          Len := Length(Value);
          If DLen > 0 Then Begin
            If Len < DLen Then Begin
              SetLength(Value, DLen);
              For Idx := Len +1 To DLen Do
                Value[Idx] := ' ';
            End Else
              If Len > DLen Then
                Value := Copy(Value, 1, DLen);
          End;
        End;
      End;
    End;
    vLen := (aSliceTo - aSliceFrom) +1;
    While Length(Phrase) < vLen Do
      Phrase := Phrase + ' ';
    With StrArrays[Idx].Strings[Offset]^ Do Begin
      Value := SP_Copy(Value, 1, aSliceFrom -1) + SP_Copy(Phrase, 1, vLen) + SP_Copy(Value, aSliceTo +1, Length(Value));
      Len := Length(Value);
      If DLen > 0 Then Begin
        If Len < DLen Then Begin
          SetLength(Value, DLen);
          For Idx := Len +1 To DLen Do
            Value[Idx] := ' ';
        End Else
          If Len > DLen Then
            Value := Copy(Value, 1, DLen);
      End;
    End;
  End;

End;

Function SP_GetKeyFromStrArray(Idx: Integer; Const Indices, Key: aString; Var Error: TSP_ErrorCode): aString;
Var
  Offset: Integer;
Begin

  // Get the key associated with an array element

  Result := '';
  Offset := SP_StrArrayGetIndex(Idx, Indices, Key, Error);
  If Offset < 0 Then Offset := -(Offset +1);
  If Error.Code = SP_ERR_OK Then Result := StrArrays[Idx].Strings[Offset]^.Key;

End;

Function SP_GetStrArrayKey(Idx: Integer; Const Key: aString): Integer;
Var
  nHash: pHashEntry;
Begin

  // Search a string array for a particular key.
  // If not found, result is -1. Otherwise it gives the index of that key.

  Result := -1;
  nHash := StrArrays[Idx].Hashes[Ord(Key[1])];

  While nHash <> nil Do Begin

    If nHash^.Key = Key Then Begin

      Result := nHash^.Index;
      Exit;

    End Else

      nHash := nHash^.NextHash;

  End;

End;

Function SP_FindStrArrayHash(Idx: Integer; Const Key: aString): pHashEntry; Inline;
Begin
  Result := NumArrays[Idx].Hashes[Ord(Key[1])];
  While Result <> nil Do Begin
    If Result^.Key = Key Then
      Break
    Else
      Result := Result^.NextHash;
  End;
End;

Procedure SP_SetStrArrayKey(Idx: Integer; Const Indices, Key, NewKey: aString;  Var Error: TSP_ErrorCode);
Var
  pIdx, Ln, iIdx, tIdx, Index, Offset, vLen, OldKey: Integer;
  Ptr, LastPtr: pHashEntry;
Begin

  // Set an associative key to an array element. First, figure out which element.

  If Idx = -1 Then Begin
    Error.Code := SP_ERR_ARRAY_NOT_FOUND;
    Exit;
  End;

  If Key = '' Then Begin
    Ln := Length(Indices);
    If Ln Div SizeOf(LongWord) <> Length(StrArrays[Idx].Indices) Then Begin
      Error.Code := SP_ERR_SUBSCRIPT_WRONG;
      Exit;
    End Else Begin
      pIdx := 1;
      iIdx := 0;
      Offset := 0;
      vLen := StrArrays[Idx].Size;
      While pIdx < Ln Do Begin
        tIdx := StrArrays[Idx].Indices[iIdx];
        Index := integer(pLongWord(@Indices[pIdx])^) - StrArrays[Idx].Base;
        If (Index >= tIdx) or (Index < 0) Then Begin
          Error.Code := SP_ERR_SUBSCRIPT_WRONG;
          Exit;
        End;
        vLen := vLen Div tIdx;
        Offset := Offset + (Index * vLen);
        Inc(pIdx, SizeOf(LongWord));
        Inc(iIdx);
      End;
    End;
  End Else Begin
    Offset := SP_GetStrArrayKey(Idx, Key);
    If Offset = -1 Then Begin
      Error.Code := SP_ERR_KEY_NOT_FOUND;
      Exit;
    End;
  End;

  // Check if NewKey isn't used anywhere else. Keys *are* case-sensitive.

  OldKey := SP_GetStrArrayKey(Idx, NewKey);
  If OldKey <> -1 Then
    SP_StrArrayRemoveKey(Idx, OldKey, NewKey);

  // Now check that the desired element doesn't already have a key, and remove it if it does

  If StrArrays[Idx].Strings[Offset]^.Key <> '' Then
    SP_StrArrayRemoveKey(Idx, Offset, StrArrays[Idx].Strings[Offset]^.Key);

  // Ok, now set the key. As well as living in the element themselves, we also need to update the hash-table.

  LastPtr := nil;
  Ptr := StrArrays[Idx].Hashes[Ord(NewKey[1])];
  While Ptr <> Nil Do Begin
    LastPtr := Ptr;
    Ptr := Ptr^.NextHash;
  End;
  Ptr := New(pHashEntry);
  StringFromPtrD(NewKey, Ptr^.Key);
  Ptr^.Index := Offset;
  Ptr^.NextHash := Nil;
  If LastPtr <> Nil Then
    LastPtr^.NextHash := Ptr
  Else
    StrArrays[Idx].Hashes[Ord(NewKey[1])] := Ptr;

  StringFromPtrD(NewKey, StrArrays[Idx].Strings[Offset]^.Key);

End;

Procedure SP_StrArrayRemoveKey(Idx, Index: Integer; Const Key: aString);
Var
  Ptr, LastPtr: pHashEntry;
Begin

  Ptr := StrArrays[Idx].Hashes[Ord(Key[1])];
  LastPtr := Ptr;
  While Ptr^.Index <> Index Do Begin
    LastPtr := Ptr;
    Ptr := Ptr^.NextHash;
  End;
  If LastPtr <> Ptr Then Begin
    LastPtr^.NextHash := Ptr^.NextHash;
    Dispose(Ptr);
  End Else Begin
    Dispose(Ptr);
    StrArrays[Idx].Hashes[Ord(Key[1])] := nil;
  End;
  StrArrays[Idx].Strings[Index]^.Key := '';

End;

Function SP_GetStrArrayPtr(Idx: Integer; const Name: aString; const Indices, Key: aString; Var Error: TSP_ErrorCode): pSP_StrVarContent;
Var
  Offset: Integer;
Begin

  Result := nil;
  If Idx = 0 Then Begin
    Idx := SP_FindStrArray(Name);
    If Idx = -1 Then Begin
      Error.Code := SP_ERR_ARRAY_NOT_FOUND;
      Exit;
    End;
  End Else
    Dec(Idx);

  Offset := SP_StrArrayGetIndex(Idx, Indices, Key, Error);
  If Error.Code = SP_ERR_OK Then
    If Offset >= 0 Then
      Result := StrArrays[Idx].Strings[Offset]
    Else Begin
      Error.Code := SP_ERR_SUBSCRIPT_WRONG;
      Error.ReturnType := Offset;
    End;

End;

Function SP_QueryStrArray(Var Idx: Integer; Var Indices, Key: aString; Var Error: TSP_ErrorCode): aString;
Var
  pIdx, Index, iLen, iIdx, tIdx, Offset, vLen: Integer;
  ptr: pLongWord;
Begin

  Result := '';
  Offset := SP_StrArrayGetIndex(Idx, Indices, Key, Error);
  If Error.Code = SP_ERR_OK Then
    If Offset >= 0 Then
      Result := StrArrays[Idx].Strings[Offset]^.Value
    Else Begin
      Offset := -(Offset +1);
      Index := pLongWord(@Indices[1 + Length(Indices) - SizeOf(LongWord)])^;
      If Index > Length(StrArrays[Idx].Strings[Offset]^.Value) Then
        Error.Code := SP_ERR_SUBSCRIPT_WRONG
      Else
        Result := StrArrays[Idx].Strings[Offset]^.Value[Index];
    End;

End;

Procedure SP_FillStrArray(Var Idx: Integer; Value: aString);
Var
  iIdx: Integer;
Begin

  With StrArrays[Idx] Do
    For iIdx := 0 To Length(Strings) -1 Do
      Strings[iIdx]^.Value := Value;

End;

Function SP_SearchStrArray(Const Name, Term: aString; Var Error: TSP_ErrorCode): Integer;
Var
  Idx, sIdx: Integer;
Begin

  // Searches the specified array for the term supplied.

  Result := -1;
  Idx := SP_FindStrArray(Name);
  If Idx = -1 Then Begin
    Error.Code := SP_ERR_ARRAY_NOT_FOUND;
    Exit;
  End;

  If StrArrays[Idx].NumIndices > 1 Then Begin
    Error.Code := SP_ERR_UNSUITABLE_ARRAY;
    Exit;
  End Else Begin

    StrArrays[Idx].LastSearchTerm := Term;
    StrArrays[Idx].LastSearchIdx := -1;

    For sIdx := 0 To StrArrays[Idx].Size -1 Do Begin

      If StrArrays[Idx].Strings[sIdx].Value = Term Then Begin
        Result := sIdx + StrArrays[Idx].Base;
        StrArrays[Idx].LastSearchIdx := sIdx;
        Exit;
      End;

    End;

  End;

End;

Function SP_SearchStrArrayNext(Const Name: aString; Var Error: TSP_ErrorCode): Integer;
Var
  Idx, sIdx: Integer;
Begin

  // Searches the specified array for the next instance of the term supplied.

  Result := -1;
  Idx := SP_FindStrArray(Name);
  If Idx = -1 Then Begin
    Error.Code := SP_ERR_ARRAY_NOT_FOUND;
    Exit;
  End;

  If StrArrays[Idx].NumIndices > 1 Then Begin
    Error.Code := SP_ERR_UNSUITABLE_ARRAY;
    Exit;
  End Else Begin

    If StrArrays[Idx].LastSearchIdx > -1 Then Begin

      For sIdx := StrArrays[Idx].LastSearchIdx +1 To StrArrays[Idx].Size -1 Do Begin

        If StrArrays[Idx].Strings[sIdx].Value = StrArrays[Idx].LastSearchTerm Then Begin
          Result := sIdx + StrArrays[Idx].Base;
          StrArrays[Idx].LastSearchIdx := sIdx;
          Exit;
        End;

      End;

    End;

  End;

End;

Function SP_SliceString(const Str: aString; SliceFrom, SliceTo: Integer): aString; Inline;
Begin

  If SliceFrom = -1 Then SliceFrom := 1;
  If SliceTo = -1 Then SliceTo := Length(Str);
  Result := Copy(Str, SliceFrom, (SliceTo - SliceFrom)+1);

End;

Procedure SP_SliceAssign(Var Dst: aString; const Src: aString; sFrom, sTo: Integer; Var Error: TSP_ErrorCode); inline;
Var
  sIdx, sliceFrom, sliceTo, sLen: Integer;
Begin

  If sFrom = -1 Then sliceFrom := 1 Else sliceFrom := sFrom;
  If sTo = -1 Then sliceTo := Length(Dst) Else sliceTo := sTo;
  If sliceFrom > Length(Dst) Then Begin
    Error.Code := SP_ERR_SUBSCRIPT_WRONG;
    Exit;
  End;

  While Length(Dst) < sTo Do Dst := Dst + ' ';
  sIdx := sliceFrom;
  sLen := Length(Src);
  While sIdx <= sliceTo Do Begin
    If (SiDx - SliceFrom) +1 > sLen Then
      Dst[sIdx] := ' '
    Else
      Dst[sIdx] := Src[(sIdx - sliceFrom) +1];
    Inc(sIdx);
  End;

End;

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

Procedure SP_PreParse(ClearVars: Boolean; Var Error: TSP_ErrorCode);
Type
  VarType = Packed Record
    ID: Byte;
    Position: LongWord;
    StrLen: LongWord;
  End;
  pVarType = ^VarType;
Var
  Tkn, Tkn2: pToken;
  Token, TokenLen, Idx, Idx2, Idx3, cIdx, cIdx2, pStatement, cStatement,
  LabelPos, LabelLen, ProcIdx, CASECount, cToken, cTokenLen, LastStrAt, LastStrLen: Integer;
  Tokens, cTokens, Name, s: aString;
  Changed, Reference, cFound, NewStatement: Boolean;
  TempLine, cLine: TSP_GOSUB_Item;
  xVar: pVarType;
  KeyWord, MaxLineNum, cKW, LastKW: LongWord;
  ProcLines: aString;
  Dbl: aFloat;
  StrPtr: pByte;
  KwPtr: pLongWord;
  TknType: Byte;
Label
  NextLine;
Begin

  LabelLen := 0;
  LabelPos := 0;
  CASECount := 0;
  SetLength(Constants, 0);
  INPROC := False;

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
    SP_DATA_Line.Line := -1;
    BASE := 1;
    MOUSEWHEEL := 0;
    SP_CaseListPtr := -1;
    SP_ProcsListPtr := -1;
    SP_ProcStackPtr := -1;
    SP_DeleteAllStreams(Error);
    SetLength(FillQueue, 0);
    SP_DeleteAllMenus;
  End;
  SP_ClearLabels;
  ProcLines := '';
  MaxLineNum := 0;
  NUMCONSTS := 0;
  SetLength(LineLUT, 0);

  SP_CompileProgram;

  Idx := -1;
  While True Do Begin

    NextLine:

    Inc(Idx);
    If Idx = SP_Program_Count Then Break;

    Tokens := SP_Program[Idx];

    Changed := False;
    Idx3 := 1;
    Idx2 := 1;
    If Byte(Tokens[Idx3]) = SP_LINE_NUM Then Begin
      If pLongWord(@Tokens[Idx3 +1])^ > MaxLineNum Then
        MaxLineNum := pLongWord(@Tokens[Idx3 +1])^;
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
              Inc(Idx3, 1 + (SizeOf(LongWord) * 2) + pLongWord(@Tokens[Idx3 + 1 + SizeOf(LongWord)])^);
              NewStatement := False;
            End;
          255:
            Break;
        End;

      End;

      pStatement := 1;

      // Check through the tokenised code now

      While Idx2 <= Length(Tokens) Do Begin

        StrPtr := @Tokens[Idx2];
        Tkn := pToken(StrPtr);
        TknType := Tkn^.Token;
        If Tkn^.Token = SP_TERMINAL Then Break;
        If ClearVars then Tkn^.Cache := 0;
        Inc(Idx2, SizeOf(TToken)); // Idx2 now points to content
        Case Tkn^.Token of
          SP_NUMVAR, SP_NUMVAR_LET, SP_STRVAR, SP_STRVARPTR, SP_STRVAR_LET, SP_STRVAR_EVAL, SP_NUMVAR_EVAL,
          SP_POINTER, SP_NUMVAR_LET_VALID, SP_STRVAR_LET_VALID, SP_INCVAR, SP_DECVAR, SP_MULVAR, SP_DIVVAR,
          SP_POWVAR, SP_MODVAR, SP_ANDVAR, SP_ORVAR, SP_XORVAR:
            Begin
              If ClearVars Then Begin
                pLongWord(@Tokens[Idx2])^ := 0;
                Inc(Idx2, Tkn^.TokenLen);
                Changed := True;
              End Else
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
                SP_KW_DATA:
                  If SP_DATA_Line.Line = -1 Then Begin
                    SP_DATA_Line := SP_ConvertLineStatement(Idx, pStatement);
                    Inc(SP_DATA_Line.Statement, SizeOf(TToken) + SizeOf(LongWord));
                    SP_DATA_Tokens := @SP_Program[Idx];
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
              If Tokens[Idx2] = ':' Then
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
        SetLength(SP_Program[Idx], Length(Tokens));
        CopyMem(@SP_Program[Idx][1], @Tokens[1], Length(Tokens));
      End;

      SP_TestConsts(SP_Program[Idx], Idx, Error, False);
      If Error.Code <> SP_ERR_OK Then Error.Line := Idx;

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
    DisplaySection.Enter;
    SP_DeleteAllWindows;
    SP_DeleteAllStreams(Error);
    SP_DeleteAllBanks(False);
    SP_ResetConditionalBreakPoints;

    SetLength(SP_FnList, 0);
    SP_FileCloseAll;
    NUMSPRITES := 0;
    DisplaySection.Leave;
    SP_ClearEvery;
    EveryEnabled := True;
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

  End;

  // Finally, insert breakpoint flags if necessary

  SP_PrepareBreakpoints(True);

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
    If Tokens[Idx] = aChar(SP_LINE_NUM) Then Begin
      Inc(Idx, 1 + SizeOf(LongWord));
    End;
    If Tokens[Idx] = aChar(SP_STATEMENTS) Then Begin
      StatementListPos := Idx;
      Idx := pLongWord(@Tokens[1 + Idx + SizeOf(LongWord)])^;
    End;
    If StatementListPos >= 0 Then Begin
      Ptr := @Tokens[StatementListPos +1];
      n := Ptr^;
      While n > 0 Do Begin
        Inc(Ptr);
        If Ptr^ >= Position Then
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
  Idx, Idx2, Idx3, LastItemPos, TokenPos, TokenLen, TLen, TknLen2, TknType2, StatementListPos, pStatement, StartPos, SkipCnt: Integer;
  Name: aString;
  LastRefWasConst, Changed: Boolean;
  Tkn, Tkn2: pToken;
  TknType, LastItemType: Byte;
  kwPtr: pLongWord;

  cFound: Boolean;
  CaseCount, cStatement, cIdx, cIdx2: Integer;
  cTokens: aString;
  Dbl: aFloat;
  cLine: TSP_GOSUB_Item;

  Procedure FixStatements(Position, Displacement: Integer);
  Var
    n, Idx, Idx2, Value: LongWord;
    Ptr: pLongWord;
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
    While Idx < Length(Tokens) Do Begin
      Token := @Tokens[Idx];
      Inc(Idx, SizeOf(TToken));
      Case Token^.Token of
        SP_JZ, SP_JNZ:
          Begin
            Jump := pLongWord(@Tokens[Idx])^;
            If (Idx + Jump >= Position - Displacement) And (Jump > 0) Then
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
            If pToken(@Tokens[Idx + Token^.TokenLen])^.Token = SP_FUNCTION Then Begin
              Kwd := pLongWord(@Tokens[Idx + Token^.TokenLen + SizeOf(TToken)])^;
              If (Kwd = SP_FN_IIF) or (Kwd = SP_FN_IIFS) Then Begin
                // Found a value followed by an IIF or IIF$.
                Idx2 := Idx + Token^.TokenLen + SizeOf(TToken) + SizeOf(LongWord);
                Value := Trunc(gaFloat(@Tokens[Idx]));
                If (Position > Idx2) And (Position < Idx2 + Value) Then Begin
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
                If (Position >= Idx2) And (Position < Idx2 + Jump) Then
                  pLongWord(@Tokens[Idx2 - SizeOf(Integer)])^ := Jump + Displacement;
                Inc(Idx, Token^.TokenLen);
              End Else
                Inc(Idx, Token^.TokenLen);
            End Else
              Inc(Idx, Token^.TokenLen);
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
  StatementListPos := -1;
  If Tokens <> '' Then Begin
    If Tokens[Idx] = aChar(SP_LINE_NUM) Then Begin
      Inc(Idx);
      LineNum := pLongWord(@Tokens[Idx])^;
      Inc(Idx, SizeOf(LongWord));
    End;
    If Tokens[Idx] = aChar(SP_STATEMENTS) Then Begin
      StatementListPos := Idx;
      Idx := pLongWord(@Tokens[1 + Idx + SizeOf(LongWord)])^;
    End;

    StartPos := Idx;
    LastItemType := $FF;
    LastItemPos := 0;

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
                  cIdx2 := Idx + Tkn^.TokenLen;
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
                          If pByte(@cTokens[cIdx2])^ = Ord(':') Then
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
        SP_POWVAR, SP_MODVAR, SP_ANDVAR, SP_ORVAR, SP_XORVAR:
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
            End;
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
            Else
              Tkn^.TokenPos := LongWord(-1);
            Inc(Idx, Tkn^.TokenLen);

          End;

        SP_SKIP_STATEMENT:
          Begin

            // If this token is followed by an SP_KEYWORD that is CONST, we're in business - skip it completely.
            // Otherwise, it might be part of a DATA statement, and should be processed.

            Idx2 := Idx + Tkn^.TokenLen;
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
                        Copy(Tokens, Idx + Tkn^.TokenLen, Length(Tokens));
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
                        Copy(Tokens, Idx + Tkn^.TokenLen, Length(Tokens));
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
              Tokens := Copy(Tokens, 1, TokenPos -1) + CreateToken(SP_NUMVAR_EVAL, 0, (SizeOf(LongWord) * 2) + Length(Name)) + LongWordToString(0) + LongWordToString(Length(Name)) + Name + Copy(Tokens, Idx + Tkn^.TokenLen, Length(Tokens));
              FixStatements(Idx, Length(Tokens) - Idx2);
              Inc(Idx, SizeOf(LongWord) + Length(Name));
              LastRefWasConst := False;
              Changed := True;
            End;
          End;

        SP_STRCONST:
          Begin
            LastRefWasConst := True;
            Name := Lower(Copy(Tokens, Idx + Tkn^.TokenPos, Tkn^.TokenLen - Tkn^.TokenPos));
            Idx2 := 0;
            While (Idx2 < NUMCONSTS) And (Constants[Idx2].Name <> Name) Do Inc(Idx2);
            If Idx2 < NUMCONSTS Then Begin
              If Not Preserve Then Begin
                TLen := Length(Tokens);
                Tokens := Copy(Tokens, 1, TokenPos -1) + CreateToken(SP_STRCONST, Length(Constants[Idx2].Str), Length(Constants[Idx2].Str) + Length(Name)) + Constants[Idx2].Str + Name + Copy(Tokens, Idx + Tkn^.TokenLen, Length(Tokens));
                FixStatements(Idx, Length(Tokens) - TLen);
                Inc(Idx, Length(Constants[Idx2].Str) + Length(Name));
                Changed := True;
              End;
            End Else Begin
              Name := Copy(Name, 1, Length(Name) -1);
              Idx2 := Length(Tokens);
              Tokens := Copy(Tokens, 1, TokenPos -1) + CreateToken(SP_STRVAR_EVAL, 0, (SizeOf(LongWord) * 2) + Length(Name)) + LongWordToString(0) + LongWordToString(Length(Name)) + Name + Copy(Tokens, Idx + Tkn^.TokenLen, Length(Tokens));
              FixStatements(Idx, Length(Tokens) - Idx2);
              Inc(Idx, SizeOf(LongWord) + Length(Name));
              LastRefWasConst := False;
              Changed := True;
            End;
          End;

        SP_SYMBOL:
          Begin
            If Tokens[Idx] = ':' Then Begin
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

      LastItemType := TknType;
      LastItemPos := TokenPos;

    End;

    // Now check for Jumps (JZ, JNZ) - They can be nested, so we need to keep a count of them.
    // Once done, remove their corresponding AND or OR, and update the statement list if necessary.

    Idx := StartPos;
    While Idx < Length(Tokens) Do Begin

      Tkn := @Tokens[Idx];
      TknType := Tkn^.Token;
      TokenPos := Idx;
      TokenLen := Tkn^.TokenLen;
      If TknType = SP_TERMINAL Then Break;

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
                              Idx2 := Length(Tokens);
                              Changed := True;
                              SkipCnt := 0;
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
                              SkipCnt := 0;
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
                              SkipCnt := 0;
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

Procedure SP_ClearVarIndices;
Var
  Tkn: pToken;
  Tokens: aString;
  Changed: Boolean;
  Idx, Idx2, Idx3: Integer;
Begin

  Idx := -1;
  While True Do Begin

    Inc(Idx);
    If Idx = SP_Program_Count Then Break;

    Tokens := SP_Program[Idx];
    Idx2 := 1;

    If Tokens <> '' Then Begin

      If Tokens[Idx2] = aChar(SP_LINE_NUM) Then Inc(Idx2, 1 + SizeOf(LongWord));
      If Tokens[Idx2] = aChar(SP_STATEMENTS) Then Idx2 := pLongWord(@Tokens[1 + Idx2 + SizeOf(LongWord)])^;

      Changed := False;

      While Idx2 <= Length(Tokens) Do Begin

        Tkn := @Tokens[Idx2];
        If Tkn^.Token = SP_TERMINAL Then Break;
        Inc(Idx2, SizeOf(TToken)); // Idx2 now points to content
        Case Tkn^.Token of
          SP_NUMVAR, SP_NUMVAR_LET, SP_STRVAR, SP_STRVARPTR, SP_STRVAR_LET, SP_STRVAR_EVAL, SP_NUMVAR_EVAL,
          SP_POINTER, SP_NUMVAR_LET_VALID, SP_STRVAR_LET_VALID, SP_INCVAR, SP_DECVAR, SP_MULVAR, SP_DIVVAR,
          SP_POWVAR, SP_MODVAR, SP_ANDVAR, SP_ORVAR, SP_XORVAR, SP_NUMVARSQ:
            Begin
              pLongWord(@Tokens[Idx2])^ := 0;
              Inc(Idx2, Tkn^.TokenLen);
              Changed := True;
            End;
        Else
          Inc(Idx2, Tkn^.TokenLen);
        End;

      End;

      If Changed Then Begin
        SetLength(SP_Program[Idx], Length(Tokens));
        CopyMem(@SP_Program[Idx][1], @Tokens[1], Length(Tokens));
      End;

    End;

  End;

End;

Procedure SP_SaveVar(const Filename, VarName: aString; IsArray: Boolean; var Error: TSP_ErrorCode);
Var
  SaveData, StructData, TempStr, HashData: aString;
  VarIdx, Idx, sIdx, mIdx, DstFile, DL, HashCount: Integer;
  Structs: TAnsiStringList;
  Ptr: pHashEntry;
Begin

  SaveData := '';

  If IsArray Then Begin

    If Copy(VarName, Length(VarName), 1) = '$' Then Begin

      VarIdx := SP_FindStrArray(Copy(VarName, 1, Length(VarName) -1));
      If VarIdx >= 0 Then Begin

        Structs := TAnsiStringList.Create;

        SaveData := 'ZXABASE'+ LongWordToString(StrArrays[VarIdx].Base) + 'ZXSADAT';

        With StrArrays[VarIdx] Do Begin

          SaveData := SaveData + LongWordToString(Length(Name)) + Name + LongWordToString(Size) + LongWordToString(NumIndices);
          For Idx := 0 To NumIndices -1 Do
            SaveData := SaveData + LongWordToString(Indices[Idx]);
          For Idx := 0 To Size -1 Do Begin
            TempStr := Strings[Idx]^.Value;
            DL := Strings[Idx]^.DLen;
            If Strings[Idx]^.StructName <> '' Then DL := -DL;
            SaveData := SaveData + LongWordToString(Strings[Idx]^.SliceFrom) + LongWordToString(Strings[Idx]^.SliceTo) + LongWordToString(DL) +
                                   LongWordToString(Length(TempStr)) + TempStr;

            If Strings[Idx]^.StructName <> '' Then Begin
              sIdx := 0;
              While sIdx < Structs.Count Do Begin
                If Strings[Idx]^.StructName = aString(Structs[sIdx]) Then
                  Break
                Else
                  Inc(sIdx);
              End;
              If sIdx = Structs.Count Then
                Structs.Add(String(Strings[Idx]^.StructName));
              SaveData := SaveData + LongWordToString(Length(Strings[Idx]^.StructName)) + Strings[Idx]^.StructName;
            End;

          End;

          StructData := '';
          For Idx := 0 To Structs.Count -1 Do Begin

            StructData := 'ZXSTDAT' + LongWordToString(Structs.Count);

            sIdx := SP_FindStruct(aString(Structs[Idx]));
            StructData := StructData + LongWordToString(Length(Structures[sIdx].Name)) + Structures[sIdx].Name + LongWordToString(Length(Structures[sIdx].Members));
            For mIdx := 0 To Length(Structures[sIdx].Members) -1 Do
              StructData := StructData + aChar(Structures[sIdx].Members[mIdx].mType) +
                                         LongWordToString(Length(Structures[sIdx].Members[mIdx].mName)) + Structures[sIdx].Members[mIdx].mName +
                                         LongWordToString(Structures[sIdx].Members[mIdx].mFix) +
                                         LongWordToString(Length(Structures[sIdx].Members[mIdx].dString)) + Structures[sIdx].Members[mIdx].dString +
                                         aFloatToString(Structures[sIdx].Members[mIdx].dValue);
          End;

          SaveData := StructData + SaveData;
          Structs.Free;

          HashData := '';
          HashCount := 0;
          For Idx := 0 To 255 Do Begin

            Ptr := Hashes[Idx];
            While Ptr <> Nil Do Begin

              HashData := HashData + LongWordToString(Length(Ptr^.Key)) + Ptr^.Key + LongWordToString(Ptr^.Index);
              Ptr := Ptr^.NextHash;
              Inc(HashCount);

            End;

          End;

          If HashData <> '' Then Begin

            SaveData := SaveData + 'ZXHASHT' + LongWordToString(HashCount) + HashData;

          End;

          // Check for and save Dynamic hashes

          If DynArray Then Begin

            HashData := '';
            HashCount := 0;
            For Idx := 0 To 65535 Do Begin

              Ptr := DynHashes[Idx];
              While Ptr <> Nil Do Begin

                HashData := HashData + LongWordToString(Length(Ptr^.Key)) + Ptr^.Key + LongWordToString(Ptr^.Index);
                Ptr := Ptr^.NextHash;
                Inc(HashCount);

              End;

            End;

            If HashData <> '' Then Begin

              SaveData := SaveData + 'ZXDYNHT' + LongWordToString(DLen) + LongWordToString(HashCount) + HashData;

            End;

          End;

        End;

      End Else Begin

        Error.Code := SP_ERR_ARRAY_NOT_FOUND;
        Exit;

      End;

    End Else Begin

      VarIdx := SP_FindNumArray(VarName);
      If VarIdx >= 0 Then Begin

        SaveData := 'ZXABASE'+ LongWordToString(NumArrays[VarIdx].Base) + 'ZXNADAT';

        With NumArrays[VarIdx] Do Begin

          SaveData := SaveData + LongWordToString(Length(Name)) + Name + LongWordToString(Size) + LongWordToString(NumIndices);
          For Idx := 0 To NumIndices -1 Do
            SaveData := SaveData + LongWordToString(Indices[Idx]);
          For Idx := 0 To Size -1 Do
            SaveData := SaveData + LongWordToString(Values[Idx]^.VarType) + LongWordToString(Values[Idx]^.LoopLine) + aFloatToString(Values[Idx]^.InitVal) +
                                   LongWordToString(Values[Idx]^.LoopStatement) + LongWordToString(Values[Idx]^.St) + aFloatToString(Values[Idx]^.EndAt) +
                                   aFloatToString(Values[Idx]^.Step) + aFloatToString(Values[Idx]^.Value) + LongWordToString(Values[Idx]^.Count);

          HashData := '';
          HashCount := 0;
          For Idx := 0 To 255 Do Begin

            Ptr := Hashes[Idx];
            While Ptr <> Nil Do Begin

              HashData := HashData + LongWordToString(Length(Ptr^.Key)) + Ptr^.Key + LongWordToString(Ptr^.Index);
              Ptr := Ptr^.NextHash;
              Inc(HashCount);

            End;

          End;

          If HashData <> '' Then Begin

            SaveData := SaveData + 'ZXHASHT' + LongWordToString(HashCount) + HashData;

          End;

          // Check for and save Dynamic hashes

          If DynArray Then Begin

            HashData := '';
            HashCount := 0;
            For Idx := 0 To 65535 Do Begin

              Ptr := DynHashes[Idx];
              While Ptr <> Nil Do Begin

                HashData := HashData + LongWordToString(Length(Ptr^.Key)) + Ptr^.Key + LongWordToString(Ptr^.Index);
                Ptr := Ptr^.NextHash;
                Inc(HashCount);

              End;

            End;

            If HashData <> '' Then Begin

              SaveData := SaveData + 'ZXDYNHT' + LongWordToString(HashCount) + HashData;

            End;

          End;

        End;

      End Else Begin

        Error.Code := SP_ERR_ARRAY_NOT_FOUND;
        Exit;

      End;

    End;

  End Else Begin

    If Copy(VarName, Length(VarName), 1) = '$' Then Begin

      VarIdx := SP_FindStrVar(Copy(VarName, 1, Length(VarName) -1));
      If VarIdx >= 0 Then Begin

        SaveData := 'ZXSVDAT';

        With StrVars[VarIdx]^ Do Begin

          SaveData := SaveData + LongWordToString(Length(Name)) + Name + LongWordToString(ContentPtr^.SliceFrom) + LongWordToString(ContentPtr^.SliceTo) +
                                 LongWordToString(ContentPtr^.DLen) + LongWordToString(Length(ContentPtr^.Value)) + ContentPtr^.Value;

          StructData := '';
          If ContentPtr^.StructName <> '' Then Begin

            SaveData := SaveData + LongWordToString(Length(ContentPtr^.StructName)) + ContentPtr^.StructName;

            StructData := 'ZXSTDAT' + LongWordToString(1);

            sIdx := SP_FindStruct(ContentPtr^.StructName);
            StructData := StructData + LongWordToString(Length(Structures[sIdx].Name)) + Structures[sIdx].Name + LongWordToString(Length(Structures[sIdx].Members));
            For mIdx := 0 To Length(Structures[sIdx].Members) -1 Do
              StructData := StructData + aChar(Structures[sIdx].Members[mIdx].mType) +
                                         LongWordToString(Length(Structures[sIdx].Members[mIdx].mName)) + Structures[sIdx].Members[mIdx].mName +
                                         LongWordToString(Structures[sIdx].Members[mIdx].mFix) +
                                         LongWordToString(Length(Structures[sIdx].Members[mIdx].dString)) + Structures[sIdx].Members[mIdx].dString +
                                         aFloatToString(Structures[sIdx].Members[mIdx].dValue);
          End;

          SaveData := StructData + SaveData;

        End;

      End Else Begin

        Error.Code := SP_ERR_MISSING_VAR;
        Exit;

      End;

    End Else Begin

      VarIdx := SP_FindNumVar(Copy(VarName, 1, Length(VarName) -1));
      If VarIdx >= 0 Then Begin

        SaveData := 'ZXNVDAT';

        With NumVars[VarIdx]^ Do Begin

          SaveData := SaveData + LongWordToString(Length(Name)) + Name + LongWordToString(ContentPtr^.VarType) + LongWordToString(ContentPtr^.LoopLine) + aFloatToString(ContentPtr^.InitVal) +
                                 LongWordToString(ContentPtr^.LoopStatement) + LongWordToString(ContentPtr^.St) + aFloatToString(ContentPtr^.EndAt) +
                                 aFloatToString(ContentPtr^.Step) + aFloatToString(ContentPtr^.Value) + LongWordToString(ContentPtr^.Count);

        End;

      End Else Begin

        Error.Code := SP_ERR_MISSING_VAR;
        Exit;

      End;

    End;

  End;

  If SP_FileExists(Filename) Then
    SP_DeleteFile(Filename, Error);

  If Error.Code = SP_ERR_OK Then Begin

    DstFile := SP_FileOpen(Filename, True, Error);
    If DstFile >= 0 Then Begin

      SP_FileWrite(DstFile, @SaveData[1], Length(SaveData), Error);
      SP_FileClose(DstFile, Error);

    End Else
      Error.Code := SP_ERR_SAVE_OPEN_ERROR;

  End;

End;

Procedure SP_LoadVar(const Filename, VarName: aString; Var Error: TSP_ErrorCode);
Type
  NV_Template = Packed Record
    VarType, LoopLine: LongWord;
    InitVal: aFloat;
    LoopStatement, St: LongWord;
    EndAt, Step, Value: aFloat;
    Count: LongWord;
  End;
  SV_Template = Packed Record
    SliceFrom, SliceTo, DLen, Len: Integer;
  End;
Var
  StrLen, SrcFile, VarIdx, DataLen, Idx, sIdx, mIdx, NumStructs, NumMembers, Ps, HashCount: Integer;
  Size, NumIndices, LwVal, ArrayBase, KeyLen, KeyIndex: LongWord;
  Buffer, InternalName, Str, Key: aString;
  NV: NV_Template;
  SV: SV_Template;
  Ptr, LastPtr: pHashEntry;
  HasStruct, Identical: Boolean;
  NewStruct: TSP_Structure;
  Function GetName: aString;
  Begin
    SetLength(Result, 4);
    SP_FileRead(SrcFile, @Result[1], 4, Error);
    DataLen := dLongWord(@Result[1]);
    SetLength(Result, DataLen);
    SP_FileRead(SrcFile, @Result[1], DataLen, Error);
  End;
Begin

  HasStruct := False;

  If SP_FileExists(Filename) Then Begin

    SrcFile := SP_FileOpen(Filename, False, Error);

    // Determine what sort of file (and what sort of DATA) it is

    SetLength(Buffer, 7);
    SP_FileRead(SrcFile, @Buffer[1], 7, Error);

    // Check for structures - if so, process them and re-read the buffer.

    If Buffer = 'ZXSTDAT' Then Begin

      SP_FileRead(SrcFile, @NumStructs, SizeOf(LongWord), Error);

      For Idx := 1 To NumStructs Do Begin

        SP_FileRead(SrcFile, @StrLen, SizeOf(LongWord), Error);
        SetLength(Str, StrLen);
        SP_FileRead(SrcFile, @Str[1], StrLen, Error);

        NewStruct.Name := Str;

        SP_FileRead(SrcFile, @NumMembers, SizeOf(LongWord), Error);
        SetLength(NewStruct.Members, NumMembers);

        For mIdx := 0 To NumMembers -1 Do Begin

          With NewStruct.Members[mIdx] Do Begin

            SP_FileRead(SrcFile, @mType, SizeOf(Byte), Error);
            SP_FileRead(SrcFile, @StrLen, SizeOf(LongWord), Error);
            SetLength(mName, StrLen);
            SP_FileRead(SrcFile, @mName[1], StrLen, Error);
            SP_FileRead(SrcFile, @mFix, SizeOf(LongWord), Error);
            SP_FileRead(SrcFile, @StrLen, SizeOf(LongWord), Error);
            SetLength(dString, StrLen);
            SP_FileRead(SrcFile, @dString[1], StrLen, Error);
            SP_FileRead(SrcFile, @dValue, SizeOf(aFloat), Error);

          End;

        End;

        sIdx := SP_FindStruct(NewStruct.Name);
        If sIdx = -1 Then
          sIdx := SP_NewStruct(NewStruct.Name)
        Else Begin

          Identical := True;
          If Length(NewStruct.Members) = Length(Structures[sIdx].Members) Then Begin
            For mIdx := 0 To Length(NewStruct.Members) -1 Do Begin
              If (NewStruct.Members[mIdx].mType <> Structures[sIdx].Members[mIdx].mType) or
                 (NewStruct.Members[mIdx].mName <> Structures[sIdx].Members[mIdx].mName) or
                 ((NewStruct.Members[mIdx].mFix <> Structures[sIdx].Members[midx].mFix) and (NewStruct.Members[mIdx].mType = SP_STRVAR)) Then Begin
                Identical := False;
                Break;
              End;
            End;
          End Else
            Identical := False;

          If Not Identical Then Begin
            For mIdx := 0 To NumSV -1 Do
              If StrVars[mIdx].ContentPtr^.StructName = Str Then
                StrVars[mIdx].ContentPtr^.StructName := '';

            For mIdx := 0 To Length(StrArrays) -1 Do
              For LwVal := 0 To Length(StrArrays[mIdx].Strings) -1 Do
                If StrArrays[mIdx].Strings[LwVal]^.StructName = Str Then
                  StrArrays[mIdx].Strings[LwVal]^.StructName := '';
          End;

        End;

        SetLength(Structures[sIdx].Members, Length(NewStruct.Members));
        For mIdx := 0 To Length(NewStruct.Members) -1 Do Begin
          Structures[sIdx].Members[mIdx].mType := NewStruct.Members[mIdx].mType;
          Structures[sIdx].Members[mIdx].mName := NewStruct.Members[mIdx].mName;
          Structures[sIdx].Members[mIdx].mFix := NewStruct.Members[mIdx].mFix;
          Structures[sIdx].Members[mIdx].dValue := NewStruct.Members[mIdx].dValue;
          Structures[sIdx].Members[mIdx].dString := NewStruct.Members[mIdx].dString;
        End;

      End;

      HasStruct := True;

      SP_FileRead(SrcFile, @Buffer[1], 7, Error);

    End;

    If Buffer = 'ZXNVDAT' Then Begin

      InternalName := GetName;
      If VarName <> '' Then
        If VarName[Length(VarName)] = '$' Then Begin
          Error.Code := SP_ERR_MIXED_TYPES;
          SP_FileClose(SrcFile, Error);
          Exit;
        End Else
          InternalName := VarName;

      VarIdx := SP_FindNumVar(InternalName);
      If VarIdx = -1 Then Begin
        VarIdx := SP_NewNumVar;
        NumVars[VarIdx]^.ContentPtr := @NumVars[VarIdx]^.Content;
      End;

      NumVars[VarIdx].Name := LowerNoSpaces(InternalName);
      SP_FileRead(SrcFile, @NV.VarType, SizeOf(NV_Template), Error);
      NumVars[VarIdx].ContentPtr^.Value := NV.Value;
      NumVars[VarIdx].ContentPtr^.VarType := NV.VarType;
      NumVars[VarIdx].ContentPtr^.LoopLine := NV.LoopLine;
      NumVars[VarIdx].ContentPtr^.LoopStatement := NV.LoopStatement;
      NumVars[VarIdx].ContentPtr^.St := NV.St;
      NumVars[VarIdx].ContentPtr^.EndAt := NV.EndAt;
      NumVars[VarIdx].ContentPtr^.Step := NV.Step;
      NumVars[VarIdx].ContentPtr^.InitVal := NV.InitVal;
      NumVars[VarIdx].ContentPtr^.Count := NV.Count;

    End Else

      If Buffer = 'ZXSVDAT' Then Begin

        InternalName := GetName;
        If Length(VarName) > 1 Then
          If VarName[Length(VarName)] <> '$' Then Begin
            Error.Code := SP_ERR_MIXED_TYPES;
            SP_FileClose(SrcFile, Error);
            Exit;
          End Else
            InternalName := Copy(VarName, 1, Length(VarName) -1);

        VarIdx := SP_FindStrVar(InternalName);
        If VarIdx = -1 Then Begin
          VarIdx := SP_NewStrVar;
          StrVars[VarIdx]^.ContentPtr := @StrVars[VarIdx]^.Content;
        End;

        StrVars[VarIdx].Name := LowerNoSpaces(InternalName);
        SP_FileRead(SrcFile, @SV.SliceFrom, SizeOf(SV_Template), Error);
        StrVars[VarIdx].ContentPtr^.SliceFrom := SV.SliceFrom;
        StrVars[VarIdx].ContentPtr^.SliceTo := SV.SliceTo;
        StrVars[VarIdx].ContentPtr^.DLen := SV.DLen;
        StrVars[VarIdx].ContentPtr^.VarType := SP_STRVAR;
        SetLength(StrVars[VarIdx].ContentPtr^.Value, SV.Len);
        SP_FileRead(SrcFile, @StrVars[VarIdx].ContentPtr^.Value[1], SV.Len, Error);

        If HasStruct Then Begin
          SP_FileRead(SrcFile, @LwVal, SizeOf(LongWord), Error);
          SetLength(StrVars[VarIdx].ContentPtr^.StructName, LwVal);
          SP_FileRead(SrcFile, @StrVars[VarIdx].ContentPtr^.StructName[1], LwVal, Error);
        End;

      End Else Begin

        ArrayBase := 1;
        If Buffer = 'ZXABASE' Then Begin

          SP_FileRead(SrcFile, @ArrayBase, SizeOf(LongWord), Error);
          SP_FileRead(SrcFile, @Buffer[1], 7, Error);

        End;

        If Buffer = 'ZXNADAT' Then Begin

          InternalName := GetName;
          If VarName <> '' Then
            If VarName[Length(VarName)] = '$' Then Begin
              Error.Code := SP_ERR_MIXED_TYPES;
              SP_FileClose(SrcFile, Error);
              Exit;
            End Else
              InternalName := VarName;

          VarIdx := SP_FindNumArray(InternalName);
          If VarIdx = -1 Then Begin
            SP_CreateNumArray(InternalName, LongWordToString(1), ArrayBase, False, Error);
            VarIdx := Length(NumArrays) -1;
          End Else
            SP_RemoveNumArray(VarIdx);

          SP_FileRead(SrcFile, @Size, SizeOf(LongWord), Error);
          SP_FileRead(SrcFile, @NumIndices, SizeOf(LongWord), Error);
          NumArrays[VarIdx].Size := Size;
          NumArrays[VarIdx].NumIndices := NumIndices;
          SetLength(NumArrays[VarIdx].Indices, NumIndices);

          For Idx := 0 To NumIndices -1 Do Begin
            SP_FileRead(SrcFile, @Size, SizeOf(longWord), Error);
            NumArrays[VarIdx].Indices[Idx] := Size;
          End;

          SetLength(NumArrays[VarIdx].Values, NumArrays[VarIdx].Size);
          For Idx := 0 To NumArrays[VarIdx].Size -1 Do Begin
            NumArrays[VarIdx].Values[Idx] := New(pSP_NumVarContent);
            SP_FileRead(SrcFile, @NV.VarType, SizeOf(NV_Template), Error);
            With NumArrays[VarIdx].Values[Idx]^ Do Begin
              VarType := NV.VarType;
              LoopLine := NV.LoopLine;
              LoopStatement := NV.LoopStatement;
              St := NV.St;
              EndAt := NV.EndAt;
              Step := NV.Step;
              Value := NV.Value;
              InitVal := NV.InitVal;
              Count := NV.Count;
            End;
          End;

          SP_FileRead(SrcFile, @Buffer[1], 7, Error);
          If Buffer = 'ZXHASHT' Then Begin
            SP_FileRead(SrcFile, @HashCount, SizeOf(LongWord), Error);
            While HashCount > 0 Do Begin
              SP_FileRead(SrcFile, @KeyLen, SizeOf(LongWord), Error);
              SetLength(Key, KeyLen);
              SP_FileRead(SrcFile, @Key[1], KeyLen, Error);
              SP_FileRead(SrcFile, @KeyIndex, SizeOf(LongWord), Error);
              LastPtr := nil;
              Ptr := NumArrays[VarIdx].Hashes[Ord(Key[1])];
              While Ptr <> Nil Do Begin
                LastPtr := Ptr;
                Ptr := Ptr^.NextHash;
              End;
              Ptr := New(pHashEntry);
              Ptr^.Key := Key;
              Ptr^.Index := KeyIndex;
              Ptr^.NextHash := Nil;
              If LastPtr <> Nil Then
                LastPtr^.NextHash := Ptr
              Else
                NumArrays[VarIdx].Hashes[Ord(Key[1])] := Ptr;
              NumArrays[VarIdx].Values[KeyIndex]^.Key := Key;
              Dec(HashCount);
            End;
            SP_FileRead(SrcFile, @Buffer[1], 7, Error);
          End;

          If Buffer = 'ZXDYNHT' Then Begin
            SP_FileRead(SrcFile, @HashCount, SizeOf(LongWord), Error);
            If HashCount > 0 Then Begin
              SetLength(NumArrays[VarIdx].DynHashes, 65536);
              NumArrays[VarIdx].DynArray := True;
              While HashCount > 0 Do Begin
                SP_FileRead(SrcFile, @KeyLen, SizeOf(LongWord), Error);
                SetLength(Key, KeyLen);
                SP_FileRead(SrcFile, @Key[1], KeyLen, Error);
                SP_FileRead(SrcFile, @KeyIndex, SizeOf(LongWord), Error);
                LastPtr := nil;
                Ptr := NumArrays[VarIdx].DynHashes[pWord(@Key[1])^];
                While Ptr <> Nil Do Begin
                  LastPtr := Ptr;
                  Ptr := Ptr^.NextHash;
                End;
                Ptr := New(pHashEntry);
                Ptr^.Key := Key;
                Ptr^.Index := KeyIndex;
                Ptr^.NextHash := Nil;
                If LastPtr <> Nil Then
                  LastPtr^.NextHash := Ptr
                Else
                  NumArrays[VarIdx].DynHashes[pWord(@Key[1])^] := Ptr;
                Dec(HashCount);
              End;
            End;
          End;

        End Else

          If Buffer = 'ZXSADAT' Then Begin

            InternalName := GetName;
            If Length(VarName) > 1 Then
              If VarName[Length(VarName)] <> '$' Then Begin
                Error.Code := SP_ERR_MIXED_TYPES;
                SP_FileClose(SrcFile, Error);
                Exit;
              End Else
                InternalName := Copy(VarName, 1, Length(VarName) -1);

            VarIdx := SP_FindStrArray(InternalName);
            If VarIdx = -1 Then Begin
              SP_CreateStrArray(InternalName, LongWordToString(1), 0, '', ArrayBase, False, Error);
              VarIdx := Length(StrArrays) -1;
            End Else
              SP_RemoveStrArray(VarIdx);

            SP_FileRead(SrcFile, @Size, SizeOf(LongWord), Error);
            SP_FileRead(SrcFile, @NumIndices, SizeOf(LongWord), Error);
            StrArrays[VarIdx].Size := Size;
            StrArrays[VarIdx].NumIndices := NumIndices;
            SetLength(StrArrays[VarIdx].Indices, NumIndices);

            For Idx := 0 To NumIndices -1 Do Begin
              SP_FileRead(SrcFile, @Size, SizeOf(longWord), Error);
              StrArrays[VarIdx].Indices[Idx] := Size;
            End;

            SetLength(StrArrays[VarIdx].Strings, StrArrays[VarIdx].Size);
            For Idx := 0 To StrArrays[VarIdx].Size -1 Do Begin
              StrArrays[VarIdx].Strings[Idx] := New(pSP_StrVarContent);
              SP_FileRead(SrcFile, @SV.SliceFrom, SizeOf(SV_Template), Error);
              With StrArrays[VarIdx].Strings[Idx]^ Do Begin
                SliceFrom := SV.SliceFrom;
                SliceTo := SV.SliceTo;
                DLen := SV.DLen;
                SetLength(Value, SV.Len);
                SP_FileRead(SrcFile, @Value[1], SV.Len, Error);
              End;

              If StrArrays[VarIdx].Strings[Idx]^.DLen < 0 Then Begin
                StrArrays[VarIdx].Strings[Idx]^.DLen := -StrArrays[VarIdx].Strings[Idx]^.DLen;
                SP_FileRead(SrcFile, @LwVal, SizeOf(LongWord), Error);
                SetLength(StrArrays[VarIdx].Strings[Idx]^.StructName, LwVal);
                SP_FileRead(SrcFile, @StrArrays[VarIdx].Strings[Idx]^.StructName[1], LwVal, Error);
              End;

            End;

            If StrArrays[VarIdx].Size > 0 Then
              StrArrays[VarIdx].DLen := StrArrays[VarIdx].Strings[0].DLen;

            SP_FileRead(SrcFile, @Buffer[1], 7, Error);
            If Buffer = 'ZXHASHT' Then Begin
              SP_FileRead(SrcFile, @HashCount, SizeOf(LongWord), Error);
              While HashCount > 0 Do Begin
                SP_FileRead(SrcFile, @KeyLen, SizeOf(LongWord), Error);
                SetLength(Key, KeyLen);
                SP_FileRead(SrcFile, @Key[1], KeyLen, Error);
                SP_FileRead(SrcFile, @KeyIndex, SizeOf(LongWord), Error);
                LastPtr := nil;
                Ptr := StrArrays[VarIdx].Hashes[Ord(Key[1])];
                While Ptr <> Nil Do Begin
                  LastPtr := Ptr;
                  Ptr := Ptr^.NextHash;
                End;
                Ptr := New(pHashEntry);
                Ptr^.Key := Key;
                Ptr^.Index := KeyIndex;
                Ptr^.NextHash := Nil;
                If LastPtr <> Nil Then
                  LastPtr^.NextHash := Ptr
                Else
                  StrArrays[VarIdx].Hashes[Ord(Key[1])] := Ptr;
                StrArrays[VarIdx].Strings[KeyIndex]^.Key := Key;
                Dec(HashCount);
              End;
              SP_FileRead(SrcFile, @Buffer[1], 7, Error);
            End;

            If Buffer = 'ZXDYNHT' Then Begin
              SP_FileRead(SrcFile, @StrArrays[VarIdx].DLen, SizeOf(Integer), Error);
              SP_FileRead(SrcFile, @HashCount, SizeOf(LongWord), Error);
              If HashCount > 0 Then Begin
                SetLength(StrArrays[VarIdx].DynHashes, 65536);
                StrArrays[VarIdx].DynArray := True;
                While HashCount > 0 Do Begin
                  SP_FileRead(SrcFile, @KeyLen, SizeOf(LongWord), Error);
                  SetLength(Key, KeyLen);
                  SP_FileRead(SrcFile, @Key[1], KeyLen, Error);
                  SP_FileRead(SrcFile, @KeyIndex, SizeOf(LongWord), Error);
                  LastPtr := nil;
                  Ptr := StrArrays[VarIdx].DynHashes[pWord(@Key[1])^];
                  While Ptr <> Nil Do Begin
                    LastPtr := Ptr;
                    Ptr := Ptr^.NextHash;
                  End;
                  Ptr := New(pHashEntry);
                  Ptr^.Key := Key;
                  Ptr^.Index := KeyIndex;
                  Ptr^.NextHash := Nil;
                  If LastPtr <> Nil Then
                    LastPtr^.NextHash := Ptr
                  Else
                    StrArrays[VarIdx].DynHashes[pWord(@Key[1])^] := Ptr;
                  Dec(HashCount);
                End;
              End;
            End;

          End Else Begin

            If Buffer = 'ZXNADYN' Then Begin

            End Else Begin

              If Buffer = 'ZXSADYN' Then Begin

              End Else Begin

                Error.Code := SP_ERR_INVALID_DATA_FILE;
                SP_FileClose(SrcFile, Error);
                Exit;

              End;

            End;

          End;

      End;

  End Else

    Error.Code := SP_ERR_FILE_MISSING;

  SP_FileClose(SrcFile, Error);

End;

Function  SP_NumArrayToString(Index, MaxLen: Integer): aString;
Var
  Idx, Idx2, IndexSize, c: Integer;
  nArr: pSP_NumArray;
  Strs, Strs2: TAnsiStringList;
  Str: aString;
Begin

  nArr := @NumArrays[Index];
  Strs := TAnsiStringList.Create;
  Strs2 := TAnsiStringList.Create;

  // Gather all values into strings, comma separated, the size of the last index.

  c := 0;
  Idx := 0;
  If nArr^.NumIndices > 0 Then
    IndexSize := nArr^.Indices[nArr^.NumIndices -1]
  Else
    IndexSize := nArr^.Size;
  If IndexSize > 0 Then Begin
    While Idx < nArr^.Size Do Begin
      Str := '(';
      For Idx2 := 0 To IndexSize -1 Do Begin
        Str := Str + aString(aFloatToStr(nArr^.Values[Idx]^.Value));
        If Idx2 < IndexSize -1 Then
          Str := Str + ',';
        Inc(Idx);
        If Length(Str) > MaxLen Then Break;
      End;
      Str := Str + ')';
      Strs.Add(String(Str));
      If Length(Str) > MaxLen Then Break;
    End;
  End Else
    Strs.Add('()');

  // Now start grouping into higher and higher indices.

  Index := nArr^.NumIndices -1;
  While Index > 0 Do Begin

    // Gather all strings in Strs into groups of IndexSize, in Strs2. Then clear Strs and copy Strs2 over
    // Then repeat.

    Idx := 0;
    IndexSize := nArr^.Indices[Index -1];
    While Idx < Strs.Count Do Begin
      Str := '(';
      For Idx2 := 0 To IndexSize -1 Do Begin
        If Strs[Idx] <> '' Then Begin
          Str := Str + aString(Strs[Idx]);
          If Idx2 < IndexSize -1 Then
            Str := Str + ',';
          Inc(Idx);
        End Else
          Break;
      End;
      Str := Str + ')';
      Strs2.Add(String(Str));
    End;

    Strs.Clear;
    Strs.AddStrings(Strs2);
    Strs2.Clear;

    Dec(Index);

  End;

  // Finally, add all the Strs together!

  Result := '';
  For Idx := 0 To Strs.Count -1 Do
    if Copy(Strs[Idx], 1, 2) <> ',,' Then
      Result := Result + aString(Strs[Idx]);
  Strs.Free;
  Strs2.Free;

End;

Function  SP_StrArrayToString(Index, MaxLen: Integer): aString;
Var
  Idx, Idx2, IndexSize: Integer;
  sArr: pSP_StrArray;
  Strs, Strs2: TAnsiStringList;
  Str: aString;
Begin

  sArr := @StrArrays[Index];
  Strs := TAnsiStringList.Create;
  Strs2 := TAnsiStringList.Create;

  // Gather all values into strings, comma separated, the size of the last index.

  Idx := 0;
  If sArr^.NumIndices > 0 Then
    IndexSize := sArr^.Indices[sArr^.NumIndices -1]
  Else
    IndexSize := sArr^.Size;
  If IndexSize > 0 Then Begin
    While Idx < sArr^.Size Do Begin
      Str := '(';
      For Idx2 := 0 To IndexSize -1 Do Begin
        Str := Str + '"'+sArr^.Strings[Idx]^.Value+'"';
        If Idx2 < IndexSize -1 Then
          Str := Str + ',';
        Inc(Idx);
        If Length(Str) > MaxLen Then Break;
      End;
      Str := Str + ')';
      Strs.Add(string(Str));
      If Length(Str) > MaxLen Then Break;
    End;
  End Else
    Strs.Add('()');

  // Now start grouping into higher and higher indices.

  Index := sArr^.NumIndices -1;
  While Index > 0 Do Begin

    // Gather all strings in Strs into groups of IndexSize, in Strs2. Then clear Strs and copy Strs2 over
    // Then repeat.

    Idx := 0;
    IndexSize := sArr^.Indices[Index -1];
    While Idx < Strs.Count Do Begin
      Str := '(';
      For Idx2 := 0 To IndexSize -1 Do Begin
        If Strs[Idx] <> '' Then Begin
          Str := Str + aString(Strs[Idx]);
          If Idx2 < IndexSize -1 Then
            Str := Str + ',';
          Inc(Idx);
        End Else
          Break;
      End;
      Str := Str + ')';
      Strs2.Add(string(Str));
    End;

    Strs.Clear;
    Strs.AddStrings(Strs2);
    Strs2.Clear;

    Dec(Index);

  End;

  // Finally, add all the Strs together!

  Result := '';
  For Idx := 0 To Strs.Count -1 Do
    if Copy(Strs[Idx], 1, 2) <> ',,' Then
      Result := Result + aString(Strs[Idx]);
  Strs.Free;
  Strs2.Free;

End;

Function  SP_NewStruct(const Name: aString): Integer;
Begin

  Result := 0;
  While Result < Length(Structures) Do Begin
    If Structures[Result].Name <> Name Then
      Inc(Result)
    Else
      Break;
  End;
  If Result = Length(Structures) Then Begin
    SetLength(Structures, Result +1);
    Structures[Result].Name := Name;
  End;

End;

Procedure SP_DeleteStruct(const Name: aString; Var Error: TSP_ErrorCode);
Var
  Idx, sIdx, mIdx: Integer;
Begin

  Idx := SP_FindStruct(Name);

  If Idx > -1 Then Begin

    If Length(Structures) > 1 Then Begin

      For sIdx := Idx To Length(Structures) -2 Do Begin

        Structures[sIdx].Name := Structures[sIdx +1].Name;
        SetLength(Structures[sIdx].Members, Length(Structures[sIdx+1].Members));

        For mIdx := 0 To Length(Structures[sIdx +1].Members) -1 Do Begin

          Structures[sIdx].Members[mIdx].mType := Structures[sIdx +1].Members[mIdx].mType;
          Structures[sIdx].Members[mIdx].mName := Structures[sIdx +1].Members[mIdx].mName;
          Structures[sIdx].Members[mIdx].mFix := Structures[sIdx +1].Members[mIdx].mFix;
          Structures[sIdx].Members[mIdx].dValue := Structures[sIdx +1].Members[mIdx].dValue;
          Structures[sIdx].Members[mIdx].dString := Structures[sIdx +1].Members[mIdx].dString;

        End;

      End;

      SetLength(Structures, Length(Structures) -1);

    End Else

      SetLength(Structures, 0);

    For mIdx := 0 To NumSV -1 Do
      If StrVars[mIdx].ContentPtr^.StructName = Name Then
        StrVars[mIdx].ContentPtr^.StructName := '';

    For mIdx := 0 To Length(StrArrays) -1 Do
      For Idx := 0 To Length(StrArrays[mIdx].Strings) -1 Do
        If StrArrays[mIdx].Strings[Idx]^.StructName = Name Then
          StrArrays[mIdx].Strings[Idx]^.StructName := '';

  End Else

    Error.Code := SP_ERR_STRUCT_NOT_FOUND;

End;

Procedure SP_AddStructMember(Idx: Integer; const mName: aString; mFix, mType: Integer; const DefString: aString; DefValue: aFloat);
Var
  mLen: Integer;
  nName: aString;
Begin

  if mType = SP_STRVAR Then nName := LowerNoSpaces(mName) + '$' Else nName := LowerNoSpaces(mName);
  With Structures[Idx] Do begin
    mLen := Length(Members);
    SetLength(Members, mLen +1);
    Members[mLen].mName := LowerNoSpaces(nName);
    Members[mLen].mType := mType;
    Members[mLen].mFix := mFix;
    Members[mLen].dString := DefString;
    Members[mLen].dValue := DefValue;
  End;

End;

Function SP_FindStruct(const Name: aString): Integer;
Begin

  If Name <> '' Then Begin
    Result := Length(Structures) -1;
    While Result >= 0 Do Begin
      If Structures[Result].Name = Name Then Break;
      Dec(Result);
    End;
  End Else
    Result := -1;

End;

Function SP_AssignStruct(Idx: Integer; const Name, StructName: aString; Var Error: TSP_ErrorCode; Ptr: pLongWord): Integer;
Var
  sIdx: Integer;
Begin

  Result := -1;
  sIdx := SP_FindStruct(StructName);

  If sIdx > -1 Then Begin

    If Idx = 0 Then Begin
      Idx := SP_FindStrVar(Name);
      If Idx = -1 Then Begin
        Idx := SP_NewStrVar;
        StrVars[Idx]^.Name := Name;
        StrVars[Idx]^.ProcVar := SP_ProcStackPtr > -1;
        StrVars[Idx]^.ContentPtr := @StrVars[Idx]^.Content;
        If Not StrVars[Idx]^.ProcVar Then Ptr^ := Idx +1;
      End;
    End Else
      Dec(Idx);

    StrVars[Idx]^.ContentPtr^.StructName := Structures[sIdx].Name;
    Result := Idx;

    StrVars[Result]^.ContentPtr^.Value := SP_GetDefaultFields(sIdx);

  End Else Begin

    Error.Code := SP_ERR_STRUCT_NOT_FOUND;

  End;

End;

Procedure SP_AssignStructPtr(sPtr: pSP_StrVarContent; const StructName: aString; Var Error: TSP_ErrorCode);
Var
  sIdx: Integer;
Begin

  sIdx := SP_FindStruct(StructName);

  If sIdx > -1 Then Begin

    sPtr^.StructName := Structures[sIdx].Name;
    sPtr^.Value := SP_GetDefaultFields(sIdx);

  End Else Begin

    Error.Code := SP_ERR_STRUCT_NOT_FOUND;

  End;

End;

Function SP_GetDefaultFields(sIdx: Integer): aString;
Var
  Idx: Integer;
  NewStr: aString;
Begin

    Result := '';

    For Idx := 0 To Length(Structures[sIdx].Members) -1 Do Begin
      Case Structures[sIdx].Members[Idx].mType of
        SP_NUMVAR:
          Begin
            Result := Result + aFloatToString(Structures[sIdx].Members[Idx].dValue);
          End;
        SP_STRVAR:
          Begin
            If Structures[sIdx].Members[Idx].mFix = 0 Then
              Result := Result + LongWordToString(Length(Structures[sIdx].Members[Idx].dString)) + Structures[sIdx].Members[Idx].dString
            Else Begin
              NewStr := Copy(Structures[sIdx].Members[Idx].dString, 1, Structures[sIdx].Members[Idx].mFix);
              While Length(NewStr) < Structures[sIdx].Members[Idx].mFix Do
                NewStr := NewStr + ' ';
              Result := Result + NewStr;
            End;
          End;
      End;
    End;

End;

Procedure SP_SetStructMember(StrPtr: pSP_StrVarContent; const Member, ValStr: aString; ValNum: aFloat; Var Error: TSP_ErrorCode);
Var
  cIdx, sIdx, mIdx, Size: Integer;
  CurContent, NewContent, TempStr, nValStr: aString;
  nM: pSP_StructMember;
  Done: Boolean;
Begin

  // Determine which structure is associated with this string

  sIdx := SP_FindStruct(StrPtr^.StructName);
  If sIdx > -1 Then begin

    // Now find the member and update it.

    Done := False;
    cIdx := 1;
    mIdx := 0;
    NewContent := '';
    CurContent := StrPtr^.Value;

    While mIdx < Length(Structures[sIdx].Members) Do Begin
      nM := @Structures[sIdx].Members[mIdx];
      If nM^.mName = Member Then Begin
        // Found the member - add the new value to the NewContent var, and skip this member.
        Done := True;
        Case nM^.mType Of
          SP_NUMVAR:
            Begin
              NewContent := NewContent + aFloatToString(ValNum);
              Inc(cIdx, SizeOf(aFloat));
            End;
          SP_STRVAR:
            Begin
              If nM^.mFix = 0 Then Begin
                Inc(cIdx, pLongWord(@CurContent[cIdx])^ + SizeOf(LongWord));
                NewContent := NewContent + LongWordToString(Length(ValStr)) + ValStr;
              End Else Begin
                nValStr := Copy(ValStr, 1, nM^.mFix);
                While Length(nValStr) < nM^.mFix Do
                  nValStr := nValStr + ' ';
                Inc(cIdx, nM^.mFix);
                NewContent := NewContent + nValStr;
              End;
            End;
        End;
      End Else Begin
        Case nM^.mType of
          SP_NUMVAR:
            Begin
              TempStr := Copy(CurContent, cIdx, SizeOf(aFloat));
              If Length(TempStr) < SizeOf(aFloat) Then TempStr := aFloatToString(0);
              NewContent := NewContent + TempStr;
              Inc(cIdx, SizeOf(aFloat));
            End;
          SP_STRVAR:
            Begin
              If nM^.mFix = 0 Then Begin
                Size := pLongWord(@CurContent[cIdx])^;
                Inc(cIdx, SizeOf(LongWord));
                TempStr := Copy(CurContent, cIdx, Size);
                While Length(TempStr) < Size Do
                  TempStr := TempStr + ' ';
                NewContent := NewContent + LongWordToString(Size) + TempStr;
                Inc(cIdx, Size);
              End Else Begin
                TempStr := Copy(CurContent, cIdx, nM^.mFix);
                While Length(TempStr) < nM^.mFix Do
                  TempStr := TempStr + ' ';
                NewContent := NewContent + TempStr;
                Inc(cIdx, nM^.mFix);
              End;
            End;
        End;
      End;
      Inc(mIdx);
    End;

    If Done Then
      StrPtr^.Value := NewContent
    Else
      Error.Code := SP_ERR_INVALID_STRUCT_MEMBER;

  End Else

    Error.Code := SP_ERR_MISSING_STRUCT;

End;

Function SP_GetStructMemberN(sPtr: pSP_StrVarContent; const Member: aString; Var Error: TSP_ErrorCode): aFloat;
Var
  cIdx, sIdx, mIdx: Integer;
  CurContent: aString;
  nM: pSP_StructMember;
Begin

  Result := 0;
  sIdx := SP_FindStruct(sPtr^.StructName);
  If sIdx > -1 Then begin

    cIdx := 1;
    mIdx := 0;
    CurContent := sPtr^.Value;

    While mIdx < Length(Structures[sIdx].Members) Do Begin
      nM := @Structures[sIdx].Members[mIdx];
      If nM^.mName = Member Then Begin
        Result := gaFloat(@CurContent[cIdx]);
        Exit;
      End Else Begin
        Case nM^.mType of
          SP_NUMVAR:
            Begin
              Inc(cIdx, SizeOf(aFloat));
            End;
          SP_STRVAR:
            Begin
              If nM^.mFix = 0 Then Begin
                Inc(cIdx, SizeOf(LongWord) + pLongWord(@CurContent[cIdx])^);
              End Else Begin
                Inc(cIdx, nM^.mFix);
              End;
            End;
        End;
      End;
      Inc(mIdx);
    End;

    Error.Code := SP_ERR_INVALID_STRUCT_MEMBER;

  End Else

    Error.Code := SP_ERR_MISSING_STRUCT;

End;

Function SP_GetStructMemberS(sPtr: pSP_StrVarContent; const Member: aString; Var Error: TSP_ErrorCode): aString;
Var
  cIdx, sIdx, mIdx, Size: Integer;
  CurContent: aString;
  nM: pSP_StructMember;
Begin

  Result := '';
  sIdx := SP_FindStruct(sPtr^.StructName);
  If sIdx > -1 Then begin

    cIdx := 1;
    mIdx := 0;
    CurContent := sPtr^.Value;

    While mIdx < Length(Structures[sIdx].Members) Do Begin
      nM := @Structures[sIdx].Members[mIdx];
      If nM^.mName = Member Then Begin
        If nM^.mFix = 0 Then Begin
          Size := pLongWord(@CurContent[cIdx])^;
          Result := Copy(CurContent, cIdx + SizeOf(LongWord), Size);
          Exit;
        End Else Begin
          Result := Copy(CurContent, cIdx, nM^.mFix);
          Exit;
        End;
      End Else Begin
        Case nM^.mType of
          SP_NUMVAR:
            Begin
              Inc(cIdx, SizeOf(aFloat));
            End;
          SP_STRVAR:
            Begin
              If nM^.mFix = 0 Then Begin
                Inc(cIdx, SizeOf(LongWord) + pLongWord(@CurContent[cIdx])^);
              End Else Begin
                Inc(cIdx, nM^.mFix);
              End;
            End;
        End;
      End;
      Inc(mIdx);
    End;

    Error.Code := SP_ERR_INVALID_STRUCT_MEMBER;

  End Else

    Error.Code := SP_ERR_MISSING_STRUCT;

End;

Procedure SP_ClearStructs;
Var
  Error: TSP_ErrorCode;
Begin

  While Length(Structures) > 0 Do
    SP_DeleteStruct(Structures[0].Name, Error);

End;

Function  SP_UpdateFOREACHVar(Idx: Integer; const Name, ArrayName: aString; Var Step: aFloat; LoopLine, LoopStatement, St: Integer; Ptr: pLongWord; Var Error: TSP_ErrorCode): Integer;
Var
  StrVar: Boolean;
  nIdx: Integer;
  nName: aString;
Begin

  // Find the variable to use. Can be string or numeric.

  StrVar := False;
  If Idx = 0 Then Begin
    If Name[Length(Name)] <> '$' Then Begin
      StrVar := False;
      Idx := SP_FindNumVar(Name);
      If Idx = -1 Then Begin
        Idx := SP_NewNumVar;
        NumVars[Idx]^.Name := Name;
        NumVars[Idx]^.ProcVar := SP_ProcStackPtr > -1;
        NumVars[Idx]^.ContentPtr := @NumVars[Idx]^.Content;
        If Not NumVars[Idx]^.ProcVar Then Ptr^ := Idx +1;
      End;
    End Else Begin
      StrVar := True;
      nName := Copy(Name, 1, Length(Name) -1);
      Idx := SP_FindStrVar(nName);
      If Idx = -1 Then Begin
        Idx := SP_NewStrVar;
        StrVars[Idx]^.Name := nName;
        StrVars[Idx]^.ProcVar := SP_ProcStackPtr > -1;
        StrVars[Idx]^.ContentPtr := @StrVars[Idx]^.Content;
        If Not StrVars[Idx]^.ProcVar Then Ptr^ := Idx +1;
      End;
    End;
  End Else
    Idx := Idx -1;

  // Find the Array

  If StrVar Then Begin

    nIdx := SP_FindStrArray(ArrayName);
    If nIdx > -1 Then Begin

      StrVars[Idx]^.ContentPtr^.EachIndex := nIdx;
      StrVars[Idx]^.ContentPtr^.EachArrayIndex := 0;
      StrVars[Idx]^.ContentPtr^.Step := Step;
      StrVars[Idx]^.ContentPtr^.LoopLine := LoopLine;
      StrVars[Idx]^.ContentPtr^.LoopStatement := LoopStatement;
      StrVars[Idx]^.ContentPtr^.St := St;
      StrVars[Idx]^.ContentPtr^.VarType := SP_FOREACH;
      StrVars[Idx]^.ContentPtr := StrArrays[nIdx].Strings[0];

    End Else Begin

      Error.Code := SP_ERR_ARRAY_NOT_FOUND;

    End;

  End Else Begin

    nIdx := SP_FindNumArray(ArrayName);
    If nIdx > -1 Then Begin

      NumVars[Idx]^.ContentPtr^.EachIndex := nIdx;
      NumVars[Idx]^.ContentPtr^.EachArrayIndex := 0;
      NumVars[Idx]^.ContentPtr^.Step := Step;
      NumVars[Idx]^.ContentPtr^.LoopLine := LoopLine;
      NumVars[Idx]^.ContentPtr^.LoopStatement := LoopStatement;
      NumVars[Idx]^.ContentPtr^.St := St;
      NumVars[Idx]^.ContentPtr^.VarType := SP_FOREACH;
      NumVars[Idx]^.ContentPtr := NumArrays[nIdx].Values[0];

    End Else Begin

      Error.Code := SP_ERR_ARRAY_NOT_FOUND;

    End;

  End;

  Result := Idx;

End;

Function  SP_UpdateFOREACHRANGEVar(Idx: Integer; const Name, EachString: aString; Var NumRanges, LoopLine, LoopStatement, St: Integer; Ptr: pLongWord; Var Error: TSP_ErrorCode): Integer;
Var
  StrVar: Boolean;
  nIdx: Integer;
  rType: Byte;
  Tokens: paString;
  nName: aString;
Begin

  // Find the variable to use. Can be string or numeric.

  StrVar := False;
  If Idx = 0 Then Begin
    If Name[Length(Name)] <> '$' Then Begin
      StrVar := False;
      Idx := SP_FindNumVar(Name);
      If Idx = -1 Then Begin
        Idx := SP_NewNumVar;
        NumVars[Idx]^.Name := Name;
        NumVars[Idx]^.ProcVar := SP_ProcStackPtr > -1;
        NumVars[Idx]^.ContentPtr := @NumVars[Idx]^.Content;
        If Not NumVars[Idx]^.ProcVar Then Ptr^ := Idx +1;
      End;
    End Else Begin
      StrVar := True;
      nName := Copy(Name, 1, Length(Name) -1);
      Idx := SP_FindStrVar(nName);
      If Idx = -1 Then Begin
        Idx := SP_NewStrVar;
        StrVars[Idx]^.Name := nName;
        StrVars[Idx]^.ProcVar := SP_ProcStackPtr > -1;
        StrVars[Idx]^.ContentPtr := @StrVars[Idx]^.Content;
        If Not StrVars[Idx]^.ProcVar Then Ptr^ := Idx +1;
      End;
    End;
  End Else
    Idx := Idx -1;

  If StrVar Then With StrVars[Idx]^ Do Begin

    ContentPtr^.EachTokens := EachString;
    ContentPtr^.EachPtr := 1;
    ContentPtr^.EachIndex := 0;
    ContentPtr^.Count := NumRanges;
    ContentPtr^.LoopLine := LoopLine;
    ContentPtr^.LoopStatement := LoopStatement;
    ContentPtr^.St := St;
    ContentPtr^.VarType := SP_FOREACHRANGE;

    // Now we're all set up, interpret the first range item.

    Tokens := @ContentPtr^.EachTokens;
    rType := Byte(ContentPtr^.EachTokens[ContentPtr^.EachPtr]);
    Inc(ContentPtr^.EachPtr, SizeOf(TToken));
    SP_InterpretCONTSafe(Tokens, ContentPtr^.EachPtr, Error);

    If Error.Code = SP_ERR_OK Then Begin

      Case rType of
        SP_EACHSINGLE:
          Begin
            ContentPtr^.Value := SP_StackPtr^.Str;
            ContentPtr^.RangeMin := Byte(ContentPtr^.Value[1]);
            ContentPtr^.RangeMax := Byte(ContentPtr^.Value[1]);
            ContentPtr^.RangeStep := 1;
            Dec(SP_StackPtr);
          End;
        SP_EACHRANGE:
          Begin
            ContentPtr^.RangeMax := Byte(SP_StackPtr^.Str[1]);
            Dec(SP_StackPtr);
            ContentPtr^.RangeMin := Byte(SP_StackPtr^.Str[1]);
            ContentPtr^.Value := aChar(ContentPtr^.RangeMin);
            Dec(SP_StackPtr);
            ContentPtr^.RangeStep := 1;
          End;
        SP_EACHSTEP:
          Begin
            ContentPtr^.RangeStep := Round(SP_StackPtr^.Val);
            Dec(SP_StackPtr);
            ContentPtr^.RangeMax := Byte(SP_StackPtr^.Str[1]);
            Dec(SP_StackPtr);
            ContentPtr^.RangeMin := Byte(SP_StackPtr^.Str[1]);
            ContentPtr^.Value := aChar(ContentPtr^.RangeMin);
            Dec(SP_StackPtr);
          End;
      End;

    End;

  End Else With NumVars[Idx]^ Do Begin

    ContentPtr^.EachTokens := EachString;
    ContentPtr^.EachPtr := 1;
    ContentPtr^.EachIndex := 0;
    ContentPtr^.Count := NumRanges;
    ContentPtr^.LoopLine := LoopLine;
    ContentPtr^.LoopStatement := LoopStatement;
    ContentPtr^.St := St;
    ContentPtr^.VarType := SP_FOREACHRANGE;

    // Now we're all set up, interpret the first range item.

    Tokens := @ContentPtr^.EachTokens;
    rType := Byte(ContentPtr^.EachTokens[ContentPtr^.EachPtr]);
    Inc(ContentPtr^.EachPtr, SizeOf(TToken));
    SP_InterpretCONTSafe(Tokens, ContentPtr^.EachPtr, Error);

    If Error.Code = SP_ERR_OK Then Begin

      Case rType of
        SP_EACHSINGLE:
          Begin
            ContentPtr^.Value := SP_StackPtr^.Val;
            ContentPtr^.RangeMin := ContentPtr^.Value;
            ContentPtr^.RangeMax := ContentPtr^.Value;
            ContentPtr^.RangeStep := 1;
            Dec(SP_StackPtr);
          End;
        SP_EACHRANGE:
          Begin
            ContentPtr^.RangeMax := SP_StackPtr^.Val;
            Dec(SP_StackPtr);
            ContentPtr^.RangeMin := SP_StackPtr^.Val;
            ContentPtr^.Value := ContentPtr^.RangeMin;
            Dec(SP_StackPtr);
            ContentPtr^.RangeStep := 1;
          End;
        SP_EACHSTEP:
          Begin
            ContentPtr^.RangeStep := SP_StackPtr^.Val;
            Dec(SP_StackPtr);
            ContentPtr^.RangeMax := SP_StackPtr^.Val;
            Dec(SP_StackPtr);
            ContentPtr^.RangeMin := SP_StackPtr^.Val;
            ContentPtr^.Value := ContentPtr^.RangeMin;
            Dec(SP_StackPtr);
          End;
      End;

    End;

  End;

  Result := Idx;

End;

Procedure SP_SortNumArray(sIdx: Integer; Key, Ascending: Boolean; Var Error: TSP_ErrorCode);

  Procedure SortNumArray(sIdx, L, R: Integer);
  Var
    I, J: Integer;
    P, T: pSP_NumVarContent;
  Begin

    With NumArrays[sIdx] Do Begin

      Repeat

        I := L;
        J := R;

        P := Values[(L + R) shr 1];

        Repeat

          If Ascending Then Begin

            If Key Then Begin

              While Values[I]^.Key < P^.Key Do
                Inc(I);

              while Values[J]^.Key > P^.Key Do
                Dec(J);

            End Else Begin

              While Values[I]^.Value < P^.Value Do
                Inc(I);

              while Values[J]^.Value > P^.Value Do
                Dec(J);

            End;

          End Else Begin

            If Key Then Begin

              While Values[I]^.Key > P^.Key Do
                Inc(I);

              while Values[J]^.Key < P^.Key Do
                Dec(J);

            End Else Begin

              While Values[I]^.Value > P^.Value Do
                Inc(I);

              while Values[J]^.Value < P^.Value Do
                Dec(J);

            End;

          End;

          If I <= J Then Begin
            If Values[I].Key <> '' Then
              SP_FindNumArrayHash(sIdx, Values[I].Key)^.Index := J;
            If Values[J].Key <> '' Then
              SP_FindNumArrayHash(sIdx, Values[J].Key)^.Index := I;
            T := Values[I];
            Values[I] := Values[J];
            Values[J] := T;
            Inc(I);
            Dec(J);
          End;

        Until I > J;

        If L < J then
          SortNumArray(sIdx, L, J);

        L := I;

      Until I >= R;

    End;

  End;

Begin

  SortNumArray(sIdx, 0, Length(NumArrays[sIdx].Values) -1);

End;

Procedure SP_SortStrArray(sIdx: Integer; Key, Ascending: Boolean; Var Error: TSP_ErrorCode);

  Procedure SortStrArray(sIdx, L, R: Integer);
  Var
    I, J: Integer;
    P, T: pSP_StrVarContent;
  Begin

    With StrArrays[sIdx] Do Begin

      Repeat

        I := L;
        J := R;

        P := Strings[(L + R) shr 1];

        Repeat

          If Ascending Then Begin

            If Key Then Begin

              While Strings[I]^.Key < P^.Key Do
                Inc(I);

              while Strings[J]^.Key > P^.Key Do
                Dec(J);

            End Else Begin

              While Strings[I]^.Value < P^.Value Do
                Inc(I);

              while Strings[J]^.Value > P^.Value Do
                Dec(J);

            End;

          End Else Begin

            If Key Then Begin

              While Strings[I]^.Key > P^.Key Do
                Inc(I);

              while Strings[J]^.Key < P^.Key Do
                Dec(J);

            End Else Begin

              While Strings[I]^.Value > P^.Value Do
                Inc(I);

              while Strings[J]^.Value < P^.Value Do
                Dec(J);

            End;

          End;

          If I <= J Then Begin
            If Strings[I].Key <> '' Then
              SP_FindStrArrayHash(sIdx, Strings[I].Key)^.Index := J;
            If Strings[J].Key <> '' Then
              SP_FindStrArrayHash(sIdx, Strings[J].Key)^.Index := I;
            T := Strings[I];
            Strings[I] := Strings[J];
            Strings[J] := T;
            Inc(I);
            Dec(J);
          End;

        Until I > J;

        If L < J then
          SortStrArray(sIdx, L, J);

        L := I;

      Until I >= R;

    End;

  End;

Begin

  SortStrArray(sIdx, 0, Length(StrArrays[sIdx].Strings) -1);

End;

end.


