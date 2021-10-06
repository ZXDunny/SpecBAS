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

unit SP_Util;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}

// A set of procs and functions that replace those found in Windows.pas and others
// in order to maintain platform independence.

interface

Uses Math, Classes, SysUtils, Types, SyncObjs, SP_AnsiStringlist;

Type

  {$IFDEF FPC}
  aString = String;
  aChar = Char;
  TAnsiStringlist = TStringlist;
  pNativeUInt = ^NativeUInt;
  {$ELSE}

  aString = AnsiString;
  aChar = AnsiChar;

  TStringlist = TAnsiStringList;
  {$ENDIF}

  paChar = ^aChar;
  paString = ^aString;
  aFloat = Extended;
  paFloat = ^aFloat;

Procedure Delay(ms: Integer);
Function  Pos(Const SubStr, s: aString): Integer; Overload;
Function  Pos(Const SubStr: aChar; s: aString): Integer; Overload;
Function  ReadLinuxFile(Filename: aString): aString;
Procedure WriteLinuxFile(Filename, Value: aString);
Function  GetCRC32FromString(Str: aString): LongWord;
Function  SP_Copy(Const Src: aString; Start, Len: Integer): aString; overload; inline;
Function  SP_Copy(Const Src: aString; Start: Integer): aString; overload; inline;
Function  StringCopy(Str: paString; Start, Len: Integer): aString; inline;
Function  StringFromPtr(Ptr: pByte; Len: Integer): aString; inline;
Function  StringFromPtrB(Ptr: pByte; Len: Integer): aString; inline;
Procedure StringFromPtrD(Const Src: aString; Var Dest: aString); inline;
Procedure FillMem(Dst: pByte; Len: LongWord; Value: Byte); inline;
Procedure ZeroMem(Dst: pByte; Len: LongWord); inline;
Procedure CopyMem(Dst, Src: Pointer; Len: LongInt); inline;
Procedure CopyMem2(Var Dst: Pointer; Src: Pointer; Len: LongInt); inline;
Procedure MoveMem(Dst, Src: Pointer; Len: LongInt); inline;
Function  GetFilename(Name: aString): aString; inline;
Function  Upper(const Text: aString): aString; inline;
Function  Lower(const Text: aString): aString; inline;
Function  LowerNoFormatting(const Text: aString): aString; inline;
Function  LowerNoSpaces(const Text: aString): aString; inline;
Function  StringToLong(Str: aString): LongWord; inline;
Function  StringToInt(Str: aString; Default: Integer = 0): Integer; inline;
Function  IntToString(Value: NativeInt): aString; inline;
Function  SP_StringOfChar(ch: aChar; Count: Integer): aString;
Function  StripSpaces(const Text: aString): aString; inline;
Function  StringHasContent(const Text: aString): Boolean; Inline;
Function  StripLeadingSpaces(const Text: aString): aString; inline;
Function  aFloatToString(Value: aFloat): aString; inline;
Procedure WriteaFloat(Addr: Pointer; Var Value: aFloat); inline;
Function  gaFloat(Addr: Pointer): aFloat; inline;
Function  dLongWord(Addr: Pointer): LongWord; inline;
Function  NativeUIntToString(Value: NativeUInt): aString; Inline;
Function  LongWordToString(Value: LongWord): aString; inline;
Function  WordToString(Value: Word): aString; inline;
Function  IntegerToString(Value: Integer): aString; Inline;
Procedure SP_SkipSpaces(Var Line: aString; Var Position: Integer); inline;
Function  GetYear(T: aFloat): Integer; inline;
Function  GetMonth(T: aFloat): Integer; inline;
Function  GetDay(T: aFloat): Integer; inline;
Function  GetHour(T: aFloat): Integer; inline;
Function  GetMinute(T: aFloat): Integer; inline;
Function  GetSecond(T: aFloat): Integer; inline;
Function  GetMillisecond(T: Afloat): Integer; Inline;
Function  HexDump(ptr: pByte; Size, MaxWidth: Integer): aString;
Function  RawHexDump(ptr: pByte; Size: Integer): aString;
Function  ReadRawHex(Var Src: aString): aString;
Function  IntToHex(Value, Digits: Integer): aString;
Function  IntToFrac(Value: Integer): aFloat; inline;
Function  CopyFile(sSource, sDest: string): boolean;
Procedure CopyDir(sSource, sDest: string);
Function  DecodeBase(Text: aString; Var Base: Integer): Boolean;
Procedure SP_ReplaceSpecialChars(Var Output: aString);
Function  NumToText(Number: Integer): aString;
Function  StripLen(Text: aString): Integer;
Procedure Log(Text: aString);
Function  StrPosPtr(Const Str: paString; Position: Integer): Pointer; inline;
{$if defined(RASPI) or defined(PANDORA)}
Function  Copy(Const Str: aString; Start, Len: Integer): aString; Overload;
Function  Copy(Const Str: aString; Start: Integer): aString; Overload;
{$ENDIF}
Function ValidRect(r: TRect): Boolean;
Function SP_ModCalc(v1, v2: aFloat): aFloat;
Function SP_PartialMatch(const s1, s2: aString): Boolean; inline;
Function SP_PartialMatchPtrs(ps, pd: pByte; l: Integer): Boolean;
Function aFloatToStr(Value: aFloat): aString; inline;
Function SP_Power(Base, Exponent: aFloat): aFloat; inline;
Function SP_Max(A, B: Integer): Integer;

Var

  SP_NeedDisplayUpdate: Boolean = False;
  LogFile: TFileStream;
  LogFileAssigned: Boolean = False;

Const

  CRCtable: ARRAY[0..255] Of LongWord =
 ($00000000, $77073096, $EE0E612C, $990951BA, $076DC419, $706AF48F, $E963A535, $9E6495A3,
  $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988, $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91,
  $1DB71064, $6AB020F2, $F3B97148, $84BE41DE, $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7,
  $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC, $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5,
  $3B6E20C8, $4C69105E, $D56041E4, $A2677172, $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B,
  $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940, $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59,
  $26D930AC, $51DE003A, $C8D75180, $BFD06116, $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F,
  $2802B89E, $5F058808, $C60CD9B2, $B10BE924, $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D,
  $76DC4190, $01DB7106, $98D220BC, $EFD5102A, $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433,
  $7807C9A2, $0F00F934, $9609A88E, $E10E9818, $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
  $6B6B51F4, $1C6C6162, $856530D8, $F262004E, $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457,
  $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C, $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65,
  $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2, $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB,
  $4369E96A, $346ED9FC, $AD678846, $DA60B8D0, $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9,
  $5005713C, $270241AA, $BE0B1010, $C90C2086, $5768B525, $206F85B3, $B966D409, $CE61E49F,
  $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4, $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD,
  $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A, $EAD54739, $9DD277AF, $04DB2615, $73DC1683,
  $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8, $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1,
  $F00F9344, $8708A3D2, $1E01F268, $6906C2FE, $F762575D, $806567CB, $196C3671, $6E6B06E7,
  $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC, $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
  $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252, $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B,
  $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60, $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79,
  $CB61B38C, $BC66831A, $256FD2A0, $5268E236, $CC0C7795, $BB0B4703, $220216B9, $5505262F,
  $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04, $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,
  $9B64C2B0, $EC63F226, $756AA39C, $026D930A, $9C0906A9, $EB0E363F, $72076785, $05005713,
  $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38, $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21,
  $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E, $81BE16CD, $F6B9265B, $6FB077E1, $18B74777,
  $88085AE6, $FF0F6A70, $66063BCA, $11010B5C, $8F659EFF, $F862AE69, $616BFFD3, $166CCF45,
  $A00AE278, $D70DD2EE, $4E048354, $3903B3C2, $A7672661, $D06016F7, $4969474D, $3E6E77DB,
  $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0, $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
  $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6, $BAD03605, $CDD70693, $54DE5729, $23D967BF,
  $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94, $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D);

Const

  Months: Array[0..11] of aString = ('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');
  MonThree: Array[0..11] of aString = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
  Days: Array[0..6] of aString = ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');
  DayThree: Array[0..6] of aString = ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun');
  Numbers: Array[0..9] of aString = ('zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine');
  Tens: Array[0..9] of aString = ('zero', 'ten', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety');
  Teens: Array[0..9] of aString = ('ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen');

implementation

Uses SP_Main;

Procedure Log(Text: aString);
Begin

  {$IFDEF FPC}
  WriteLn(Text + #13);
  {$ELSE}
  If Not LogFileAssigned Then Begin
    If FileExists('c:\temp\log.txt') Then
      DeleteFile('c:\temp\log.txt');
    LogFile := TFileStream.Create('c:\temp\log.txt', fmCreate);
    LogFileAssigned := True;
  End;
  Text := '['+IntToString(Round(CB_GETTICKS))+'] ' + Text + #13#10;
  LogFile.Write(Text[1], Length(Text));
  {$ENDIF}

End;

Function ReadLinuxFile(Filename: aString): aString;
Var
  lxFile: TextFile;
Begin
  AssignFile(lxFile, String(Filename));
  Reset(lxFile);
  ReadLn(lxFile, Result);
  CloseFile(lxFile);
End;

Procedure WriteLinuxFile(Filename, Value: aString);
Var
  lxFile: TextFile;
Begin
  AssignFile(lxFile, String(Filename));
  Reset(lxFile);
  Write(lxFile, Value);
  CloseFile(lxFile);
End;

Function NumToText(Number: Integer): aString;
Begin

  Case Number of
    0..9: Result := Numbers[Number];
    10..19: Result := Teens[Number -10];
    20..99:
      Begin
        Result := Tens[Number Div 10];
        If Number Mod 10 <> 0 Then
          Result := Result + '-' +Numbers[Number Mod 10];
      End;
  End;

End;

Function GetYear(T: aFloat): Integer; inline;
Var
  Y, M, D: Word;
Begin

  DecodeDate(T, Y, M, D);
  Result := Y;

End;

Function GetMonth(T: aFloat): Integer; inline;
Var
  Y, M, D: Word;
Begin

  DecodeDate(T, Y, M, D);
  Result := M;

End;

Function GetDay(T: aFloat): Integer; inline;
Var
  Y, M, D: Word;
Begin

  DecodeDate(T, Y, M, D);
  Result := D;

End;

Function  GetHour(T: aFloat): Integer; inline;
Var
  H, M, S, Ms: Word;
Begin
  DecodeTime(T, H, M, S, MS);
  Result := H;

End;

Function  GetMinute(T: aFloat): Integer; inline;
Var
  H, M, S, Ms: Word;
Begin

  DecodeTime(T, H, M, S, MS);
  Result := M;

End;

Function  GetSecond(T: aFloat): Integer; inline;
Var
  H, M, S, Ms: Word;
Begin

  DecodeTime(T, H, M, S, MS);
  Result := S;

End;

Function GetMillisecond(T: Afloat): Integer; Inline;
Var
  H, M, S, Ms: Word;
Begin

  DecodeTime(T, H, M, S, MS);
  Result := MS;

End;

Function GetCRC32FromString(Str: aString): LongWord;
Var
  i, CRCValue:  LongWord;
  q: ^BYTE;
Begin
  CRCValue := $FFFFFFFF;
  q := @Str[1];
  For i := 0 TO Length(Str) -1 Do Begin
    CRCvalue := (CRCvalue Shr 8) Xor CRCTable[q^ Xor (CRCvalue And $000000FF)];
    Inc(q)
  End;
  Result := CRCValue;
End;

Function  StrPosPtr(Const Str: paString; Position: Integer): Pointer; inline;
Begin
  Result := pByte(pNativeUInt(Str)^) + Position -1;
End;

Function SP_Copy(Const Src: aString; Start, Len: Integer): aString; overload; inline;
Var
  pSrc, pDst: pByte;
Begin

  If Length(Src) > 0 Then Begin

    If Start + Len -1 > Length(Src) Then Begin
      SetLength(Result, (Length(Src) - Start) +1);
      Len := Length(Result);
    End Else
      SetLength(Result, Len);

    pSrc := pByte(pNativeUInt(@Src)^) + Start -1;
    pDst := pByte(pNativeUInt(@Result)^);

    Move(pSrc^, pDst^, Len);

  End Else

    Result := '';

End;

Function SP_Copy(Const Src: aString; Start: Integer): aString; overload; inline;
Var
  pSrc, pDst: pByte;
  Len: Integer;
Begin

  Len := Length(Src);
  If Len > 0 Then Begin

    If Start + Len -1 > Length(Src) Then Begin
      SetLength(Result, (Length(Src) - Start) +1);
      Len := Length(Result);
    End Else
      SetLength(Result, Len);

    pSrc := pByte(pNativeUInt(@Src)^) + Start -1;
    pDst := pByte(pNativeUInt(@Result)^);

    Move(pSrc^, pDst^, Len);

  End Else

    Result := '';

End;


Function StringCopy(Str: paString; Start, Len: Integer): aString; inline;
Var
  Src, Dst: pByte;
Begin

  If Len > 0 Then Begin
    SetLength(Result, Len);
    Src := @Str^[Start];
    Dst := @Result[1];

    Move(Src^, Dst^, Len);
{
    Idx := 1;
    While Idx <= Len Do Begin
      Dst^ := Src^;
      Inc(Src);
      Inc(Dst);
      Inc(Idx);
    End;}
  end Else
    Result := '';

End;

Function StringFromPtr(Ptr: pByte; Len: Integer): aString; inline;
Var
  dPtr: pByte;
Begin

  SetLength(Result, Len);
  dPtr := pByte(pNativeUInt(@Result)^);

  Move(Ptr^, dPtr^, Len);
{
  While Len > SizeOf(LongWord) Do Begin
    pLongWord(dPtr)^ := pLongWord(Ptr)^;
    Inc(pLongWord(Ptr));
    Inc(pLongWord(dPtr));
    Dec(Len, SizeOf(LongWord));
  End;
  If Len = SizeOf(LongWord) Then Begin
    pLongWord(dPtr)^ := pLongWord(Ptr)^;
    Exit;
  End;
  While Len > 0 Do Begin
    dPtr^ := Ptr^;
    Inc(Ptr);
    Inc(dPtr);
    Dec(Len);
  End;
}
End;

Function StringFromPtrB(Ptr: pByte; Len: Integer): aString; inline;
Var
  dPtr: pByte;
Begin

  SetLength(Result, Len);
  dPtr := pByte(pNativeUInt(@Result)^);

  Move(Ptr^, dPtr^, Len);
{
  While Len > SizeOf(LongWord) Do Begin
    pLongWord(dPtr)^ := pLongWord(Ptr)^;
    Inc(pLongWord(Ptr));
    Inc(pLongWord(dPtr));
    Dec(Len, SizeOf(LongWord));
  End;
  If Len = SizeOf(LongWord) Then Begin
    pLongWord(dPtr)^ := pLongWord(Ptr)^;
    Exit;
  End;
  While Len > 0 Do Begin
    dPtr^ := Ptr^;
    Inc(Ptr);
    Inc(dPtr);
    Dec(Len);
  End;
}
End;

Procedure StringFromPtrD(Const Src: aString; Var Dest: aString); inline;
Var
  Len: Integer;
  dPtr, sPtr: pByte;
Begin

  Len := Length(Src);
  SetLength(Dest, Len);
  dPtr := pByte(pNativeUInt(@Dest)^);
  sPtr := pByte(pNativeUInt(@Src)^);
  Move(sPtr^, dPtr^, Len);
{
  For Idx := 1 To Len Do Begin
    dPtr^ := sPtr^;
    Inc(sPtr);
    Inc(dPtr);
  End;
}
End;

Procedure FillMem(Dst: pByte; Len: LongWord; Value: Byte); Inline;
Var
  LongVal: LongWord;
  {$IFDEF CPU64}QVal: NativeUInt;{$ENDIF}
Begin

  LongVal := Value + (Value Shl 8) + (Value Shl 16) + (Value Shl 24);
  {$IFDEF CPU64}
  QVal := (NativeUInt(LongVal) Shl 32) Or LongVal;
  While Len > SizeOf(NativeUInt) Do Begin
    pNativeUInt(Dst)^ := QVal;
    Inc(Dst, SizeOf(NativeUInt));
    Dec(Len, SizeOf(NativeUInt));
  End;
  {$ENDIF}
  While Len > SizeOf(LongWord) Do Begin
    pLongWord(Dst)^ := LongVal;
    Inc(Dst, SizeOf(LongWord));
    Dec(Len, SizeOf(LongWord));
  End;
  While Len > 0 Do Begin
    Dst^ := Value;
    Inc(Dst);
    Dec(Len);
  End;

End;

Procedure ZeroMem(Dst: pByte; Len: LongWord); Inline;
Begin

  {$IFDEF CPU64}
  While Len > SizeOf(NativeUInt) Do Begin
    pNativeUInt(Dst)^ := 0;
    Inc(Dst, SizeOf(NativeUInt));
    Dec(Len, SizeOf(NativeUInt));
  End;
  {$ENDIF}
  While Len > SizeOf(LongWord) Do Begin
    pLongWord(Dst)^ := 0;
    Inc(Dst, SizeOf(LongWord));
    Dec(Len, SizeOf(LongWord));
  End;
  While Len > 0 Do Begin
    Dst^ := 0;
    Inc(Dst);
    Dec(Len);
  End;

End;

Procedure CopyMem(Dst, Src: Pointer; Len: LongInt); inline;
Begin

  Move(Src^, Dst^, Len);
  Exit;

  // Copies bytes from Src to Dst pointers.

  {$IFDEF CPU64}

  While Len > SizeOf(NativeUInt) Do Begin
     PNativeUInt(Dst)^ := pNativeUint(Src)^;
     Dec(Len, SizeOf(NativeUInt));
     Inc(pNativeUInt(Dst));
     Inc(pNativeUint(Src));
  End;

  {$ENDIF}

  While Len > SizeOf(LongWord) Do Begin
     pLongWord(Dst)^ := pLongWord(Src)^;
     Dec(Len, SizeOf(LongWord));
     Inc(pLongWord(Dst));
     Inc(pLongWord(Src));
  End;

  While Len > 0 Do Begin
    pByte(Dst)^ := pByte(Src)^;
    Dec(Len);
    Inc(pByte(Dst));
    Inc(pByte(Src));
  End;

End;

Procedure CopyMem2(var Dst: Pointer; Src: Pointer; Len: LongInt); inline;
var
  t: NativeUInt;
Begin

  // Copies bytes from Src to Dst pointers - slightly faster than copymem().

  {$IFDEF CPU64}

  While Len > SizeOf(NativeUInt) * 8 Do Begin
    t := pNativeUInt(Src)^;
    PNativeUInt(Dst)^ := t;
    Inc(pNativeUint(Src));
    Inc(pNativeUInt(Dst));
    t := pNativeUInt(Src)^;
    PNativeUInt(Dst)^ := t;
    Inc(pNativeUint(Src));
    Inc(pNativeUInt(Dst));
    t := pNativeUInt(Src)^;
    PNativeUInt(Dst)^ := t;
    Inc(pNativeUint(Src));
    Inc(pNativeUInt(Dst));
    t := pNativeUInt(Src)^;
    PNativeUInt(Dst)^ := t;
    Inc(pNativeUint(Src));
    Inc(pNativeUInt(Dst));
    t := pNativeUInt(Src)^;
    PNativeUInt(Dst)^ := t;
    Inc(pNativeUint(Src));
    Inc(pNativeUInt(Dst));
    t := pNativeUInt(Src)^;
    PNativeUInt(Dst)^ := t;
    Inc(pNativeUint(Src));
    Inc(pNativeUInt(Dst));
    t := pNativeUInt(Src)^;
    PNativeUInt(Dst)^ := t;
    Inc(pNativeUint(Src));
    Inc(pNativeUInt(Dst));
    t := pNativeUInt(Src)^;
    PNativeUInt(Dst)^ := t;
    Inc(pNativeUint(Src));
    Inc(pNativeUInt(Dst));
    Dec(Len, SizeOf(NativeUInt) * 8);
  End;

  If len = 0 then
    Exit
  else
    While Len > SizeOf(NativeUInt) Do Begin
      PNativeUInt(Dst)^ := pNativeUint(Src)^;
      Dec(Len, SizeOf(NativeUInt));
      Inc(pNativeUInt(Dst));
      Inc(pNativeUint(Src));
    End;

  {$ENDIF}

  If len = 0 then
    Exit
  else
    While Len > SizeOf(LongWord) Do Begin
      pLongWord(Dst)^ := pLongWord(Src)^;
      Dec(Len, SizeOf(LongWord));
      Inc(pLongWord(Dst));
      Inc(pLongWord(Src));
    End;

  If len = 0 then
    Exit
  else
    While Len > 0 Do Begin
      pByte(Dst)^ := pByte(Src)^;
      Dec(Len);
      Inc(pByte(Dst));
      Inc(pByte(Src));
    End;

End;

Procedure MoveMem(Dst, Src: Pointer; Len: LongInt); inline;
Var
  D, S, Buffer: pLongWord;
  L: LongWord;
Begin

  // Moves bytes from Src to Dst pointers.

  GetMem(Buffer, Len);
  D := Buffer; S := Src; L := Len;

  {$IFDEF CPU64}
  While L > SizeOf(NativeUInt) Do Begin
     pNativeUInt(D)^ := pNativeUInt(S)^;
     Inc(pNativeUInt(D));
     Inc(pNativeUInt(S));
     Dec(L, SizeOf(NativeUInt));
  End;
  {$ENDIF}

  While L > SizeOf(LongWord) Do Begin
     D^ := S^;
     Inc(D);
     Inc(S);
     Dec(L, SizeOf(LongWord));
  End;

  While L > 0 Do Begin
     pByte(D)^ := pByte(S)^;
     Inc(pByte(D));
     Inc(pByte(S));
     Dec(L);
  End;

  D := Dst; S := Buffer; L := Len;

  {$IFDEF CPU64}
  While L > SizeOf(NativeUInt) Do Begin
     pNativeUInt(D)^ := pNativeUInt(S)^;
     Inc(pNativeUInt(D));
     Inc(pNativeUInt(S));
     Dec(L, SizeOf(NativeUInt));
  End;
  {$ENDIF}

  While L > SizeOf(LongWord) Do Begin
     D^ := S^;
     Inc(D);
     Inc(S);
     Dec(L, SizeOf(LongWord));
  End;

  While L > 0 Do Begin
     pByte(D)^ := pByte(S)^;
     Inc(pByte(D));
     Inc(pByte(S));
     Dec(L);
  End;

  FreeMem(Buffer);

End;

Function GetFilename(Name: aString): aString; inline;
Var
  Ps: Integer;
Begin

  // extracts a filename from a path

  Ps := Length(Name);
  While Ps > 0 Do Begin
     If Name[Ps] in [':', '\'] Then
        Break;
     Dec(Ps);
  End;
  Result := Copy(Name, Ps +1, Length(Name));

End;

Function Lower(const Text: aString): aString; inline;
Var
  Tl: Integer;
  sPtr, dPtr: pByte;
Begin

  // Returns a copy of the supplied aString in lowercase.

  Tl := Length(Text);
  If Tl > 0 Then Begin

    SetLength(Result, Tl);

    sPtr := pByte(pNativeUInt(@Text)^);
    dPtr := pByte(pNativeUInt(@Result)^);

    While Tl > 0 Do Begin
       Dec(Tl);
       If paChar(sPtr)^ in ['A'..'Z'] Then
          dPtr^ := sPtr^ + 32
       Else
          dPtr^ := sPtr^;
       Inc(sPtr);
       Inc(dPtr);
    End;

  End Else

    Result := '';

End;

Function LowerNoFormatting(const Text: aString): aString; inline;
Var
  b: Byte;
  Tl: Integer;
  sPtr, dPtr: pByte;
Begin

  // Returns a copy of the supplied aString in lowercase, and ignores 5-byte formatting commands.

  Tl := Length(Text);
  If Tl > 0 Then Begin

    SetLength(Result, Tl);

    sPtr := pByte(pNativeUInt(@Text)^);
    dPtr := pByte(pNativeUInt(@Result)^);

    While Tl > 0 Do Begin
      Dec(Tl);
      If sPtr^ in [16..27] Then Begin
        b := sPtr^;
        dPtr^ := sPtr^;
        Inc(sPtr);
        Inc(dPtr);
        Case b of
          16..20, 26, 27:
            Begin
              pLongWord(dPtr)^ := pLongWord(sPtr)^;
              Inc(dPtr, SizeOf(LongWord));
              Inc(sPtr, SizeOf(LongWord));
              Dec(TL, SizeOf(LongWord));
            End;
          21..22:
            Begin
              pInteger(dPtr)^ := pInteger(sPtr)^;
              Inc(dPtr, SizeOf(Integer));
              Inc(sPtr, SizeOf(Integer));
              pInteger(dPtr)^ := pInteger(sPtr)^;
              Inc(dPtr, SizeOf(Integer));
              Inc(sPtr, SizeOf(Integer));
              Dec(TL, SizeOf(Integer) * 2);
            End;
          23..24:
            Begin
              pInteger(dPtr)^ := pInteger(sPtr)^;
              Inc(dPtr, SizeOf(Integer));
              Inc(sPtr, SizeOf(Integer));
              Dec(TL, SizeOf(Integer));
            End;
          25:
            Begin
              paFloat(dPtr)^ := paFloat(sPtr)^;
              Inc(dPtr, SizeOf(aFloat));
              Inc(sPtr, SizeOf(aFloat));
              paFloat(dPtr)^ := paFloat(sPtr)^;
              Inc(dPtr, SizeOf(aFloat));
              Inc(sPtr, SizeOf(aFloat));
              Dec(TL, SizeOf(aFloat) * 2);
            End;
        End;
      End Else Begin
        If paChar(sPtr)^ in ['A'..'Z'] Then
          dPtr^ := sPtr^ + 32
        Else
          dPtr^ := sPtr^;
        Inc(sPtr);
        Inc(dPtr);
      End;
    End;

  End Else

    Result := '';

End;


Function LowerNoSpaces(const Text: aString): aString; inline;
Var
  Tl, Cnt: Integer;
  sPtr, dPtr, tPtr: pByte;
Begin

  // Returns a copy of the supplied aString in lowercase, without spaces.
  // Used for variable names and suchlike.

  Tl := Length(Text);

  sPtr := pByte(pNativeUInt(@Text)^);
  tPtr := sPtr;
  Cnt := Tl;
  While Cnt > 0 Do Begin
    If tPtr^ = 32 Then Dec(Tl);
    Dec(Cnt);
    Inc(tPtr);
  End;
  SetLength(Result, Tl);
  dPtr := pByte(pNativeUInt(@Result)^);

  While Tl > 0 Do Begin
     Dec(Tl);
     If paChar(sPtr)^ in ['A'..'Z'] Then Begin
        dPtr^ := sPtr^ + 32;
        Inc(dPtr);
     End Else
        If paChar(sPtr)^ <> ' ' Then Begin
          dPtr^ := sPtr^;
          Inc(dPtr);
        End Else
          Inc(Tl);
     Inc(sPtr);
  End;

End;


Function Upper(const Text: aString): aString; inline;
Var
//  Ps: Integer;
  p, q: pByte;
  c, l: Integer;
Begin

  // Returns a copy of the supplied aString in lowercase.

  l := Length(Text);
  SetLength(Result, l);
  q := pByte(pNativeUInt(@Text)^);
  p := pByte(pNativeUInt(@Result)^);
  CopyMem(p, q, l);
  For c := 1 to l Do Begin
    If p^ in [97..122] Then
      p^ := p^ - 32;
    Inc(p);
  End;

{  Ps := 1;
  While Ps <= Length(Text) Do Begin
     If Text[Ps] in ['a'..'z'] Then
        Result[Ps] := aChar(Ord(Text[Ps])-32)
     Else
        Result[Ps] := Text[Ps];
     Inc(Ps);
  End;}

End;

Function StringToLong(Str: aString): LongWord; inline;
Var
  p: pByte;
  Cnt: Integer;
Begin

  {$WARNINGS Off}
  Result := 0;
  p := pByte(pNativeUInt(@Str)^);
  For Cnt := 1 To Length(Str) Do Begin
    Result := Result * 10 + (p^ - 48); // warning here. Unavoidable?
    Inc(p);
  End;
  {$WARNINGS On}

End;

Function StringToInt(Str: aString; Default: Integer): Integer; inline;
Var
  p: pByte;
  Cnt, Neg: Integer;
Begin

  If Str = '' Then
    Result := Default
  Else Begin
    Neg := 0;
    Result := 0;
    p := pByte(pNativeUInt(@Str)^);
    For Cnt := 1 To Length(Str) Do Begin
      If (aChar(p^) = '-') And (Result = 0) Then
        Neg := 1 - Neg
      Else
        If (p^ >= 48) and (p^ <= 57) Then
          Result := Result * 10 + (p^ - 48)
        Else Begin
          Result := Default;
          Exit;
        End;
      Inc(p);
    End;
    If Neg > 0 Then
      Result := -Result;
  End;

End;

Function IntToString(Value: NativeInt): aString; inline;
Var
  NegFlag: Boolean;
  Len: Integer;
  cPtr: pByte;
Begin

  // Converts an integer into a String.

  NegFlag := False;
  If Value < 0 Then Begin
     Value := -Value;
     NegFlag := True;
     Len := 1;
  End Else
    Len := 0;

  If Value = 0 Then
    Result := '0'
  Else Begin
    Case Value of
      0..9: Inc(Len, 1);
      10..99: Inc(Len, 2);
      100..999: Inc(Len, 3);
      1000..9999: Inc(Len, 4);
      10000..99999: Inc(Len, 5);
      100000..999999: Inc(Len, 6);
      1000000..9999999: Inc(Len, 7);
      10000000..99999999: Inc(Len, 8);
      100000000..999999999: Inc(Len, 9);
    Else
      Begin
        Result := aString(IntToStr(Value));
        Exit;
      End;
    End;

    SetLength(Result, Len);
    cPtr := pByte(pNativeUInt(@Result)^) + Len -1;
    While Value > 0 Do Begin
      cPtr^ := 48 + (Value Mod 10);
      Value := Value Div 10;
      Dec(cPtr);
    End;
    If NegFlag then cPtr^ := 45;

  End;

End;

Function SP_StringOfChar(ch: aChar; Count: Integer): aString;
Var
  ptr: pByte;
Begin

  SetLength(Result, Count);
  ptr := pByte(pNativeUInt(@Result)^);
  While Count > 0 Do Begin
    ptr^ := Ord(ch);
    Inc(ptr);
    Dec(Count);
  End;

End;

Function StripSpaces(const Text: aString): aString; Inline;
Var
  Idx: Integer;
Begin

  Result := '';
  For Idx := 1 To Length(Text) Do
    If Text[Idx] > #32 Then Result := Result + Text[Idx];

End;

Function StringHasContent(const Text: aString): Boolean; Inline;
Var
  Idx: Integer;
Begin

  Result := False;
  For Idx := 1 To Length(Text) Do
    If Text[Idx] > #32 Then Begin
      Result := True;
      Exit;
    End;

End;

Function StripLeadingSpaces(const Text: aString): aString; Inline;
Var
  Idx, Ln: Integer;
Begin

  Idx := 1;
  Ln := Length(Text);
  While (Idx < Ln) And (Text[Idx] <= ' ') Do Inc(Idx);
  If (Idx = Ln) And (Text[Idx] <= ' ') Then
    Result := ''
  Else
    Result := Copy(Text, Idx);

End;

Function aFloatToStr(Value: aFloat): aString; inline;
Var
  m: aFloat;
Begin
  m := Value - Trunc(Value);
  If Abs(m) < 0.000000000000001 Then
    If m > 0 Then
      Value := Value - m
    Else
      Value := Value + m;
  Result := aString(FormatFloat('0.##############', Value));
End;

Function SP_Power(Base, Exponent: aFloat): aFloat; inline;
Begin

  If Base >= 0 Then
    Result := Power(Base, Exponent)
  Else
    Result := -Power(Abs(Base), Exponent);

End;

Function aFloatToString(Value: aFloat): aString; Inline;
Begin

  SetLength(Result, SizeOf(aFloat));
  {$IF DEFINED(PANDORA) OR DEFINED(RASPI)}
  Unaligned(pFloat(pLongWord(@Result)^)^) := Value;
  {$ELSE}
  paFloat(pNativeUInt(@Result)^)^ := Value;
  {$ENDIF}

end;

Procedure WriteaFloat(Addr: Pointer; Var Value: aFloat); inline;
Begin

  {$IF DEFINED(PANDORA) OR DEFINED(RASPI)}
  Unaligned(paFloat(Addr)^) := Value;
  {$ELSE}
  paFloat(Addr)^ := Value;
  {$ENDIF}

end;

Function gaFloat(Addr: Pointer): aFloat; inline;
Begin

  {$IF DEFINED(PANDORA) OR DEFINED(RASPI)}
  Result := Unaligned(paFloat(Addr)^);
  {$ELSE}
  Result := paFloat(Addr)^;
  {$ENDIF}

end;

Function dLongWord(Addr: Pointer): LongWord; inline;
Begin

  Result := pLongWord(Addr)^;

end;

Function NativeUIntToString(Value: NativeUInt): aString; Inline;
Begin

  SetLength(Result, SizeOf(NativeUInt));
  pNativeUInt(pNativeUInt(@Result)^)^ := Value;

End;

Function LongWordToString(Value: LongWord): aString; Inline;
Begin

  SetLength(Result, SizeOf(LongWord));
  pLongWord(pNativeUInt(@Result)^)^ := Value;

End;

Function WordToString(Value: Word): aString; Inline;
Begin

  SetLength(Result, SizeOf(Word));
  pWord(pNativeUInt(@Result)^)^ := Value;

End;

Function IntegerToString(Value: Integer): aString; Inline;
Begin

  SetLength(Result, SizeOf(Integer));
  pInteger(pNativeUInt(@Result)^)^ := Value;

End;

Procedure SP_SkipSpaces(Var Line: aString; Var Position: Integer); Inline;
Begin

  While (Position <= Length(Line)) And (Line[Position] <= ' ') Do
    Inc(Position);

End;

Function IntToHex(Value, Digits: Integer): aString;
Begin
  Result := '';
  If Value < 16 Then
    Result := Result + aChar('0') + aString('0123456789ABCDEF')[Value + 1]
  Else
    Result := Result + aString('0123456789ABCDEF')[(Value Shr 4)+ 1] + aString('0123456789ABCDEF')[(Value And $F) + 1];
End;

Function HexDump(ptr: pByte; Size, MaxWidth: Integer): aString;
Var
  Idx, LineW, CurLineW, AddrSize: Integer;
  AsciiStr, HexStr: aString;
  nByte: Byte;
Begin

  Idx := 0;
  Result := '';
  AddrSize := Length(IntToString(Size));
  LineW := (MaxWidth - (AddrSize + 3)) Div 3;
  While Idx < Size Do Begin
    HexStr := IntToString(Idx);
    While Length(HexStr) < AddrSize Do
      HexStr := ' ' + HexStr;
    HexStr := HexStr + ': ';
    AsciiStr := '';
    CurLineW := 0;
    While CurLineW < LineW Do Begin
      nByte := ptr^;
      If nByte < 16 Then
        HexStr := HexStr + aChar('0') + aString('0123456789ABCDEF')[nByte + 1]
      Else
        HexStr := HexStr + aString('0123456789ABCDEF')[(nByte Shr 4)+ 1] + aString('0123456789ABCDEF')[(nByte And $F) + 1];
      If (nByte < 32) or (nByte > 127) Then
        AsciiStr := AsciiStr + '.'
      Else
        AsciiStr := AsciiStr + aChar(nByte);
      Inc(CurLineW);
      Inc(Idx);
      Inc(ptr);
      If Idx = Size Then Break;
    End;
    While CurLineW < LineW Do Begin
      HexStr := HexStr + '  ';
      Inc(CurLineW);
    End;
    Result := Result + HexStr + ' ' + AsciiStr + #13;
  End;

End;

Function RawHexDump(ptr: pByte; Size: Integer): aString;
Var
  Idx: Integer;
  nByte: Byte;
Begin

  Idx := 0;
  Result := '';
  While Idx < Size Do Begin
    nByte := ptr^;
    If nByte < 16 Then
      Result := Result + aChar('0') + aString('0123456789ABCDEF')[nByte + 1]
    Else
      Result := Result + aString('0123456789ABCDEF')[(nByte Shr 4)+ 1] + aString('0123456789ABCDEF')[(nByte And $F) + 1];

    Inc(Idx);
    Inc(ptr);
  End;

End;

Function ReadRawHex(Var Src: aString): aString;
Var
  Idx, Len: Integer;
  sPtr, dPtr: pByte;

  Function GetNybble: Byte;
  Begin
    If sPtr^ in [Ord('A')..Ord('F')] Then
      Result := 10+(sPtr^ - Ord('A'))
    Else
      If sPtr^ in [Ord('0')..Ord('9')] Then
        Result := sPtr^ - Ord('0')
      Else
        Result := 0;
      Inc(sPtr);
  End;

Begin

  Idx := 1;
  sPtr := @Src[Idx];
  Len := Length(Src) Div 2;
  SetLength(Result, Len);
  dPtr := @Result[1];
  While Idx <= Len Do Begin
    dPtr^ := Byte((GetNybble Shl 4) + GetNybble);
    Inc(Idx);
    Inc(dPtr);
  End;

End;

Function IntToFrac(Value: Integer): aFloat; inline;
Var
  Sgn: Integer;
Begin

  If Value < 0 Then Sgn := -1 Else Sgn := 1;
  Result := Abs(Value);
  While Result > 1 Do
    Result := Result / 10;
  Result := Result * Sgn;

End;

// CopyFile - Cross-platform routine to copy a file. <ccowley>
Function CopyFile(sSource, sDest: string): boolean;
Var
  fsSrc, fsDst: TFileStream;
Begin
  Result := false;

  fsSrc := TFileStream.Create(sSource, fmOpenRead);
  try
    fsDst := TFileStream.Create(sDest, fmCreate);
    try
      fsDst.CopyFrom(fsSrc,0);
      Result := true;
    finally
      fsDst.Free;
    end;
  finally
    fsSrc.Free;
  end;
end;

// CopyDir - Cross-platform routine to recursively copy an entire directory
//           tree. <ccowley>
Procedure CopyDir(sSource, sDest: string);
Var
  SR: TSearchRec;
Begin
  ForceDirectories(sDest); // ensure destination exists

  try
    if FindFirst(sSource + '*', faAnyFile or faDirectory, SR) = 0 then
    begin
      repeat
        if ((SR.Attr and faDirectory) = faDirectory) and
           (SR.Name <> '.') and
           (SR.Name <> '..') then
          CopyDir(sSource + SR.Name + '/', sDest + SR.Name + '/')
        else if (SR.Attr and faDirectory) = 0 then
          CopyFile(sSource + SR.Name, sDest + SR.Name);
      until FindNext(SR)<>0;
    end;
  finally
    FindClose(SR);
  end;
End;

Function DecodeBase(Text: aString; Var Base: Integer): Boolean;
Var
  Idx, Value, txLen, v: Integer;
Begin

  v := 0;
  Idx := 1;
  Value := 0;
  Result := False;
  txLen := Length(Text);
  While Idx <= txLen Do Begin
    If Text[Idx] in ['0'..'9'] Then
      v := Ord(Text[Idx]) - 48
    Else
      If Text[Idx] in ['a'..'z'] Then
        v := Ord(Text[Idx]) - Ord('a') + 10
      Else
        If Text[Idx] in ['A'..'Z'] Then
          v := Ord(Text[Idx]) - Ord('A') + 10;
    If v < Base Then
      Value := Value + Trunc(v * Power(Base, txLen - Idx))
    Else
      Exit;
    Inc(Idx);
  End;

  Result := True;
  Base := Value;

End;

Procedure SP_ReplaceSpecialChars(Var Output: aString);
Var
  Idx: Integer;
  Ptr: pByte;
Begin

  Ptr := @Output[1];
  For Idx := 1 To Length(Output) Do Begin
    If (Ptr^ < 32) and (Ptr^ <> 1) Then Ptr^ := Ord('.');
    Inc(Ptr);
  End;

End;

Function  StripLen(Text: aString): Integer;
Var
  Idx: Integer;
Begin

  Idx := 1;
  Result := 0;
  While Idx <= Length(Text) Do Begin
    If Text[Idx] >= ' ' Then
      Inc(Result)
    Else
      Case Ord(Text[Idx]) of
        16, 17:
          Begin // INK, PAPER control
            Inc(Idx, SizeOf(LongWord));
          End;
        18, 19, 20:
          Begin // OVER control
            Inc(Idx);
          End;
        21, 22:
          Begin // MOVE, AT control
            Inc(Idx, SizeOf(Integer) * 2);
          End;
        23:
          Begin // TAB control
            Inc(Idx, SizeOf(Integer));
          End;
        24:
          Begin // CENTRE control
            Inc(Idx, SizeOf(Integer));
          End;
        25:
          Begin // SCALE control
            Inc(Idx, SizeOf(aFloat) * 2);
          End;
      End;
    Inc(Idx);
  End;

End;

{$if defined(RASPI) or defined(PANDORA)}
Function Copy(Const Str: aString; Start, Len: Integer): aString;
Var
  l: Integer;
Begin
  Result := '';
  l := Length(Str);
  If (Start > l) or (l = 0) Then
    Result := ''
  Else Begin
    If Start + Len > l Then
      Len := l - Start +1;
    SetLength(Result, Len);
    CopyMem(@Result[1], @Str[Start], Len);
  End;
End;

Function Copy(Const Str: aString; Start: Integer): aString;
Begin
  Result := Copy(Str, Start, Length(Str));
End;
{$ENDIF}

Function ValidRect(r: TRect): Boolean;
Begin
  Result := (r.Top < r.Bottom) And (r.Left < r.Right);
End;

Function SP_ModCalc(v1, v2: aFloat): aFloat;
var
  v: Integer;
Begin

  If v1 > 0 Then
    Result := Trunc(v1) mod Trunc(v2)
  Else Begin
    v := Trunc(Abs(v2));
    v1 := v1 + ((Abs(Trunc(v1)) Div v)*v) + v;
    Result := Trunc(v1) mod v;
  End;

End;

Function SP_PartialMatch(const s1, s2: aString): Boolean;
Var
  l: Integer;
  ps, pd: pByte;
Begin

  Result := True;
  ps := pByte(pNativeUInt(@s1)^);
  pd := pByte(pNativeUInt(@s2)^);
  l := NativeUInt(ps) + Length(s1) -1;
  While NativeUint(ps) <= l Do
    If ps^ <> pd^ Then Begin
      Result := False;
      Exit;
    End Else Begin
      Inc(ps);
      Inc(pd);
    End;

End;

Function SP_PartialMatchPtrs(ps, pd: pByte; l: Integer): Boolean;
Begin

  Result := True;
  l := NativeUInt(ps) + l -1;
  While NativeUint(ps) <= l Do
    If ps^ <> pd^ Then Begin
      Result := False;
      Exit;
    End Else Begin
      Inc(ps);
      Inc(pd);
    End;

End;

Function SP_Max(A, B: Integer): Integer;
Begin
  If A > B Then
    Result := A
  Else
    Result := B;
End;

Function Pos(Const SubStr, s: aString): Integer;
Var
  l, l1, l2: Integer;
  ps, pd, pdb, psb: pByte;
Begin

  Result := 1;
  pd := pByte(pNativeUInt(@SubStr)^);
  ps := pByte(pNativeUInt(@s)^);
  pdb := pd;

  l1 := Length(s);
  l2 := Length(SubStr);
  l := NativeUInt(ps) + l1;

  If l2 > l1 Then Begin
    Result := 0;
    Exit;
  End Else
    While NativeUint(ps) <= l Do Begin
      If ps^ = pd^ Then Begin
        psb := ps;
        While (NativeUInt(psb) <= l) and (psb^ = pd^) Do Begin
          Inc(psb);
          Inc(pd);
          If NativeUInt(pd) = NativeUInt(pdb) + l2 Then
            Exit;
        End;
        pd := pdb;
      End;
      Inc(ps);
      Inc(Result);
    End;

  If NativeUInt(ps) >= l Then
    Result := 0;

End;

Function Pos(Const SubStr: aChar; s: aString): Integer;
Var
  ps: pByte;
  pss: NativeUInt;
  l: Integer;
Begin

  Result := 0;
  If s = '' Then Exit;

  ps := pByte(pNativeUInt(@s)^);
  l := NativeUInt(ps) + Length(s);
  pss := NativeUInt(ps);

  While NativeUint(ps) <= l Do
    if ps^ = Ord(SubStr) Then Begin
      Result := (NativeUint(ps) - pss) +1;
      Exit;
    End Else
      Inc(ps);

End;

Procedure Delay(ms: Integer);
Var
  t, ot: aFloat;
Begin

  ot := CB_GETTICKS;
  Repeat
    CB_YIELD;
    t := CB_GETTICKS
  Until t - ot >= ms;

End;

Initialization

  LogFileAssigned := False;

Finalization

  {$IFDEF LOG}LogFile.Free;{$ENDIF}

end.
