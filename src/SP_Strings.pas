// Copyright (C) 2014 By Paul Dunn
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

unit SP_Strings;

{$INCLUDE SpecBAS.inc}

interface

Uses SysUtils, StrUtils, Math, SP_Util, SP_Errors, SP_Tokenise;

Type

  TTokenKind = (tkChar, tkSet, tkAny, tkStartAnchor, tkEndAnchor, tkEnd);

  TRegexToken = Record
    Kind: TTokenKind;
    Data: aString;      // Holds the char, or the set of chars 'abc..z'
    Min, Max: Integer;  // Quantifiers: {0,1}, {0,Max}, {1,Max}
    Negate: Boolean;    // For [^...] sets
  End;

  TCompiledRegex = Array of TRegexToken;

  TUsingItem = Record
    Kind: Byte;       // 0 = Value, 1 = String
    Value: aFloat;
    Text: aString;
  End;

  // Internal record to hold the "Rules" for a specific numeric field
  TNumericMask = Record
    IsValid: Boolean;
    TotalWidth: Integer;      // How many chars wide (min)
    Decimals: Integer;        // Digits after dot
    HasDot: Boolean;
    ThousandSep: Boolean;     // Insert commas
    Currency: aString;         // '$', '£', or ''
    SignMode: (smNone, smMinusOnly, smAlways); // '', '-', '+'
    FillChar: aChar;           // The character to pad with (default space)
    IsLiteral: Boolean;       // Used if we parsed a literal instead of a field
    LiteralChar: aChar;
  End;

  // Internal record for string fields
  TStringMask = Record
    IsValid: Boolean;
    Mode: (smFirst, smAll, smPartial);
    Len: Integer;
  End;

// Regular Expression engine

Function SP_Regexp(RegExp, Text: aString; Var Index: Integer; Var Error: TSP_ErrorCode): Integer;

// USING and USING$ functionality

Function SP_Using(Mask: aString; Items: Array of TUsingItem; Var Position: Integer): aString;

implementation

// RegExp engine. Supports:
//
// ^     Matches the start of the string (Anchored start)
// $     Matches the end of the string (Anchored end)
// .     Match any character
// *     Match any number (or none) of the preceding item
// +     Match at least one of the preceding item
// ?     Match none, or once only
// []    Creates a set of matches (e.g. [abc] or [a-z])
// [^]   Creates a set of matches that must NOT match (e.g. [^0-9])
// \     Escape a character (treats next char as literal)
// \d    Matches any digit [0-9]
// \D    Matches any non-digit [^0-9]
// \w    Matches any word character [a-z, A-Z, 0-9, _]
// \W    Matches any non-word character
// \s    Matches whitespace [Space, Tab]
// \S    Matches non-whitespace
// \n    Matches Newline (#10)
// \r    Matches Carriage Return (#13)
// \t    Matches Tab (#9)
// \xHH  Matches the character represented by the Hexadecimal number given

Function CompileRegExp(Const RegExp: aString; Var Error: TSP_ErrorCode): TCompiledRegex;
Var
  i, Len, HexVal: Integer;
  sData: aString;
  SetNegated: Boolean;

  // Define standard sets for \w, \d etc
  const
    // Note: Constructing these strings is a bit "heavy" but standard for this approach
    cDigits = '0123456789';
    cWord   = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_';
    cSpace  = ' ' + #9; // Space and Tab

  // (Helper AddToken same as before, with the variable name fix applied)
  Procedure AddToken(aKind: TTokenKind; aData: aString; aMin, aMax: Integer; aNeg: Boolean = False);
  Begin
    SetLength(Result, Length(Result) + 1);
    With Result[High(Result)] Do Begin
      Kind := aKind; Data := aData; Min := aMin; Max := aMax; Negate := aNeg;
    End;
  End;

  Function HexToInt(C1, C2: aChar): Integer;
  Var
    C: aChar;
  Begin
    // Helper to convert 2 chars to int
    // High nibble
    C := UpCase(C1);
    If C in ['0'..'9'] Then Result := (Ord(C)-48) Shl 4 Else Result := (Ord(C)-55) Shl 4;
    // Low nibble
    C := UpCase(C2);
    If C in ['0'..'9'] Then Result := Result + (Ord(C)-48) Else Result := Result + (Ord(C)-55);
  End;

  Procedure ParseCharSet;
  Var StartSet, RangeStart, RangeEnd: Integer;
  Begin
    sData := ''; SetNegated := False;
    Inc(i); // Skip '['
    If (i <= Len) and (RegExp[i] = '^') Then Begin SetNegated := True; Inc(i); End;

    StartSet := i;
    While i <= Len Do Begin
      If (RegExp[i] = ']') and (i > StartSet) Then Begin Inc(i); Exit; End;

      If (RegExp[i] = '-') and (i > StartSet) and (i < Len) and (RegExp[i+1] <> ']') Then Begin
        RangeStart := Ord(sData[Length(sData)]) + 1;
        Inc(i); // Skip '-'
        RangeEnd := Ord(RegExp[i]);
        While RangeStart <= RangeEnd Do Begin sData := sData + aChar(RangeStart); Inc(RangeStart); End;
        Inc(i);
      End Else Begin
        If RegExp[i] = '\' Then Begin Inc(i); End;
        if i <= Len then sData := sData + RegExp[i];
        Inc(i);
      End;
    End;
  End;

Begin
  i := 1; Len := Length(RegExp); SetLength(Result, 0);

  While i <= Len Do Begin
    Case RegExp[i] of
      '^': Begin AddToken(tkStartAnchor, '', 1, 1); Inc(i); End;
      '$': Begin AddToken(tkEndAnchor, '', 1, 1); Inc(i); End;
      '.': Begin AddToken(tkAny, '', 1, 1); Inc(i); End;
      '[': Begin ParseCharSet; AddToken(tkSet, sData, 1, 1, SetNegated); End;
      '\': Begin
             Inc(i); // Move past the backslash
             If i <= Len Then Begin
               Case RegExp[i] of
                 // Hexadecimal \xFF
                 'x': Begin
                        If i + 2 <= Len Then Begin
                          HexVal := HexToInt(RegExp[i+1], RegExp[i+2]);
                          AddToken(tkChar, aChar(HexVal), 1, 1);
                          Inc(i, 3);
                        End Else Begin
                          // Malformed hex, treat 'x' as literal
                          AddToken(tkChar, 'x', 1, 1);
                          Inc(i);
                        End;
                      End;

                 // Shorthand Classes
                 'd': Begin AddToken(tkSet, cDigits, 1, 1); Inc(i); End;
                 'D': Begin AddToken(tkSet, cDigits, 1, 1, True); Inc(i); End; // Negated
                 'w': Begin AddToken(tkSet, cWord, 1, 1); Inc(i); End;
                 'W': Begin AddToken(tkSet, cWord, 1, 1, True); Inc(i); End;   // Negated
                 's': Begin AddToken(tkSet, cSpace, 1, 1); Inc(i); End;
                 'S': Begin AddToken(tkSet, cSpace, 1, 1, True); Inc(i); End;  // Negated

                 // Common Escapes
                 'n': Begin AddToken(tkChar, #10, 1, 1); Inc(i); End;
                 'r': Begin AddToken(tkChar, #13, 1, 1); Inc(i); End;
                 't': Begin AddToken(tkChar, #9, 1, 1); Inc(i); End;

                 // Any other character (e.g. \. or \\) is a literal
                 Else Begin
                   AddToken(tkChar, RegExp[i], 1, 1);
                   Inc(i);
                 End;
               End;
             End;
           End;
      Else
        Begin
          AddToken(tkChar, RegExp[i], 1, 1);
          Inc(i);
        End;
    End;

    // Check Quantifiers (*, +, ?)
    If (Length(Result) > 0) and (i <= Len) Then Begin
      Case RegExp[i] of
        '*': Begin Result[High(Result)].Min := 0; Result[High(Result)].Max := MaxInt; Inc(i); End;
        '+': Begin Result[High(Result)].Min := 1; Result[High(Result)].Max := MaxInt; Inc(i); End;
        '?': Begin Result[High(Result)].Min := 0; Result[High(Result)].Max := 1; Inc(i); End;
      End;
    End;
  End;
  AddToken(tkEnd, '', 0, 0);
End;

// -----------------------------------------------------------------------------
// MATCHER: Recursive Backtracking Engine
// -----------------------------------------------------------------------------
Function MatchRecursive(Const Tokens: TCompiledRegex; TknIdx: Integer; Const Text: aString; TxtIdx: Integer; Var MatchLen: Integer): Boolean;
Var
  Token: TRegexToken;
  i, MatchCount, Limit: Integer;

  Function MatchesChar(C: aChar): Boolean;
  Begin
    Case Token.Kind of
      tkAny:  Result := True;
      tkChar: Result := C = Token.Data[1];
      tkSet:  Result := (Pos(C, Token.Data) > 0) Xor Token.Negate;
      Else    Result := False;
    End;
  End;

Begin
  // 1. Success condition: End of Regex
  If (TknIdx > High(Tokens)) or (Tokens[TknIdx].Kind = tkEnd) Then Begin
    MatchLen := TxtIdx; // Return where we finished
    Result := True;
    Exit;
  End;

  Token := Tokens[TknIdx];

  // 2. Handle Anchors
  If Token.Kind = tkStartAnchor Then Begin
    // Only valid if we are at the very start of the string (assuming index 1 based)
    // Note: The caller handles the loop, so here we just check if TxtIdx is 1
    If TxtIdx <> 1 Then Exit(False);
    Result := MatchRecursive(Tokens, TknIdx + 1, Text, TxtIdx, MatchLen);
    Exit;
  End;
  If Token.Kind = tkEndAnchor Then Begin
    If TxtIdx > Length(Text) Then
      Result := MatchRecursive(Tokens, TknIdx + 1, Text, TxtIdx, MatchLen)
    Else
      Result := False;
    Exit;
  End;

  // 3. Greedy Matching logic for Char, Set, Any

  // Max characters we can possibly consume
  If Token.Max = MaxInt Then Limit := Length(Text) - TxtIdx + 1 Else Limit := Token.Max;

  // Consume as many as possible
  MatchCount := 0;
  While (MatchCount < Limit) and (TxtIdx + MatchCount <= Length(Text)) Do Begin
    If MatchesChar(Text[TxtIdx + MatchCount]) Then Inc(MatchCount) Else Break;
  End;

  // 4. Backtracking Loop
  // If we found enough to satisfy Min, try to match the REST.
  // If the REST fails, give up one char and try again.
  If MatchCount >= Token.Min Then Begin
    For i := MatchCount DownTo Token.Min Do Begin
      If MatchRecursive(Tokens, TknIdx + 1, Text, TxtIdx + i, MatchLen) Then Begin
        Result := True;
        Exit;
      End;
    End;
  End;

  Result := False;
End;

// -----------------------------------------------------------------------------
// MAIN WRAPPER: SP_RegExp
// -----------------------------------------------------------------------------
Function SP_RegExp(RegExp, Text: aString; Var Index: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Compiled: TCompiledRegex;
  StartPos, EndPos: Integer;
Begin
  Result := 0; // Default: No match (0)

  If RegExp = '' Then Exit;

  // 1. Compile
  // Note: For an interpreter, you might want to cache this based on RegExp string
  // to avoid recompiling inside a loop.
  Compiled := CompileRegExp(RegExp, Error);
  If Error.Code <> SP_ERR_OK Then Exit;

  // 2. Execute
  // We loop through the text trying to find a match starting at StartPos
  // The 'Index' parameter passed in is where we start scanning.

  // Optimization: If regex starts with '^', only check at Index
  If (Length(Compiled) > 0) and (Compiled[0].Kind = tkStartAnchor) Then Begin
      If MatchRecursive(Compiled, 0, Text, Index, EndPos) Then
        Result := 1;
  End
  Else Begin
    // Standard substring search
    For StartPos := Index To Length(Text) + 1 Do Begin
      // Note: Length(Text)+1 allows matching an empty string at the very end or $
      If MatchRecursive(Compiled, 0, Text, StartPos, EndPos) Then Begin
        Result := 1; // Success
        Index := EndPos; // Update Index to the end of the match (optional, but useful)
        Break;
      End;
    End;
  End;

  // Clean up dynamic array (handled automatically by compiler usually, but good practice)
  SetLength(Compiled, 0);
End;

// USING$ mask parser -

// Takes:
// #    - specify a digit
// .    - specify the place that a decimal point should be
// *x   - specify a character to either precede or follow the digits
// ,    - insert a thousands separator every three digits
// $    - insert a $ currency unit before the digits
// £    - insert a £ currency unit before the digits
// \x   - insert a literal character
// +    - insert the sign of the value ahead of the digits
// -    - insert the sigh of the value ahead of the digits only if the value is negative

// !    - insert the first character of the supplied string
// &    - insert all of the supplied string
// [nn] - insert the first nn characters of the supplied string

// Helper: Formats a specific number based on a parsed rule structure
Function FormatNumberUsing(Val: aFloat; Rule: TNumericMask): aString;
Var
  S, IntPart, FracPart: aString;
  I: Integer;
  Neg: Boolean;
Begin
  // 1. Handle Rounding
  if Rule.HasDot then
    Val := SimpleRoundTo(Val, -Rule.Decimals) // Math unit
  else
    Val := Round(Val);

  Neg := (Val < 0);
  Val := Abs(Val);

  // 2. Base String Conversion
  if Rule.HasDot then
    S := aString(FloatToStrF(Val, ffFixed, 18, Rule.Decimals))
  else
    S := aFloatToStr(Val);

  // Split parts
  if Pos('.', S) > 0 then begin
    IntPart := Copy(S, 1, Pos('.', S) - 1);
    FracPart := Copy(S, Pos('.', S) + 1, Length(S));
  end else begin
    IntPart := S;
    FracPart := '';
  end;

  // 3. Insert Commas
  if Rule.ThousandSep then begin
    I := Length(IntPart) - 3;
    While I > 0 do begin
      Insert(',', IntPart, I + 1);
      Dec(I, 3);
    end;
  end;

  // 4. Assemble components (Sign + Currency + Integer)
  S := IntPart;

  // Add Currency
  if Rule.Currency <> '' then
    S := Rule.Currency + S;

  // Add Sign
  if Neg then
    S := '-' + S
  else if Rule.SignMode = smAlways then
    S := '+' + S;

  // 5. Append Decimal
  if Rule.HasDot then
    S := S + '.' + FracPart;

  // 6. Padding / Fill
  // Note: BASIC usually calculates the mask width (e.g. #### is 4 chars).
  // If result is smaller, pad left.
  if Length(S) < Rule.TotalWidth then
    S := StringOfChar(Rule.FillChar, Rule.TotalWidth - Length(S)) + S;

  Result := S;
End;

// Main Function
Function SP_Using(Mask: aString; Items: Array of TUsingItem; Var Position: Integer): aString;
Var
  MaskLen, ItemIdx, MaxItem: Integer;
  MaskPtr: Integer; // Current cursor in the Mask string

  // Internal Parser for Numeric Fields
  Function ParseNextNumeric(StartPos: Integer; out NextPos: Integer): TNumericMask;
  Var
    P: Integer;
    InFraction: Boolean;
  Begin
    FillChar(Result, SizeOf(Result), 0);
    Result.FillChar := ' ';
    InFraction := False;
    P := StartPos;

    // Scan the contiguous block of formatting characters
    While (P <= MaskLen) do Begin
      Case Mask[P] of
        '#': Begin
               Inc(Result.TotalWidth);
               if InFraction then Inc(Result.Decimals);
               Result.IsValid := True;
             End;
        '.': Begin
               if InFraction then Break; // Second dot ends the field?
               Result.HasDot := True;
               InFraction := True;
               Inc(Result.TotalWidth); // Dot counts as width
             End;
        ',': Begin
               Result.ThousandSep := True;
               // Commas don't usually add to 'width' calculation in BASIC
               // until applied, but placeholders (#) do.
             End;
        '$': Begin
               Result.Currency := '$';
               Inc(Result.TotalWidth);
             End;
        '£': Begin
               Result.Currency := '£';
               Inc(Result.TotalWidth);
             End;
        '+': Begin
               Result.SignMode := smAlways;
               Inc(Result.TotalWidth);
             End;
        '-': Begin
               Result.SignMode := smMinusOnly;
               Inc(Result.TotalWidth);
             End;
        '*': Begin
               // *x specifies fill char
               if P < MaskLen then begin
                 Inc(P); // Consume the char after *
                 Result.FillChar := Mask[P];
                 // Usually ** counts as 2 width in BASIC, but acts as fill definition
               end;
             End;
        Else
          Break; // Not a numeric format char, stop parsing this field
      End;
      Inc(P);
    End;
    NextPos := P;
  End;

  // Internal Parser for String Fields
  Function ParseNextString(StartPos: Integer; out NextPos: Integer): TStringMask;
  Var
    P, N: Integer;
  Begin
    P := StartPos;
    Result.IsValid := True;

    Case Mask[P] of
      '!': Begin
             Result.Mode := smFirst;
             Inc(P);
           End;
      '&': Begin
             Result.Mode := smAll;
             Inc(P);
           End;
      '[': Begin
             // Parse [nn]
             Inc(P); // skip [
             Result.Mode := smPartial;
             N := 0;
             While (P <= MaskLen) and (Mask[P] in ['0'..'9']) do begin
               N := (N * 10) + (Ord(Mask[P]) - Ord('0'));
               Inc(P);
             end;
             Result.Len := N;
             if (P <= MaskLen) and (Mask[P] = ']') then Inc(P);
           End;
    End;
    NextPos := P;
  End;

Var
  NumRule: TNumericMask;
  StrRule: TStringMask;
  TempS: aString;
Begin
  Result := '';
  MaskLen := Length(Mask);
  MaxItem := High(Items);
  ItemIdx := 0;

  // Normalize Position (Mask index)
  if (Position < 1) or (Position > MaskLen) then Position := 1;
  MaskPtr := Position;

  // Loop until we have processed all items
  While MaskPtr <= MaskLen do Begin

    // Look at current character to decide what to do
    Case Mask[MaskPtr] of
      // --- Numeric Formatters ---
      '#', '+', '-', '.', '$', '£', '*':
        Begin
          // Parse the rules
          NumRule := ParseNextNumeric(MaskPtr, MaskPtr);
          // We found a field, consume an item
          if (ItemIdx <= MaxItem) And (Items[ItemIdx].Kind = SP_VALUE) then begin // It's a Number
            Result := Result + FormatNumberUsing(Items[ItemIdx].Value, NumRule);
          end else Begin // It's a string, but mask wanted number?
             // BASIC behavior varies: Type Mismatch or print 0?
             // Let's assume print 0 formatted
             Result := Result + FormatNumberUsing(0.0, NumRule);
          end;
          Inc(ItemIdx); // Move to next value
        End;

      // --- String Formatters ---
      '!', '&', '[':
        Begin
          StrRule := ParseNextString(MaskPtr, MaskPtr);
          if (ItemIdx <= MaxItem) And (Items[ItemIdx].Kind = SP_STRING) then Begin // It's a String
            TempS := Items[ItemIdx].Text;
            Case StrRule.Mode of
              smFirst: Result := Result + Copy(TempS, 1, 1);
              smAll:   Result := Result + TempS;
              smPartial: Result := Result + Copy(TempS, 1, StrRule.Len);
            End;
          End else Begin // Value provided but String wanted
            // Convert value to string and process
            If ItemIdx <= MaxItem Then
              TempS := aFloatToStr(Items[ItemIdx].Value)
            Else
              TempS := ' ';
            Case StrRule.Mode of
              smFirst: Result := Result + Copy(TempS, 1, 1);
              smAll:   Result := Result + TempS;
              smPartial: Result := Result + Copy(TempS, 1, StrRule.Len);
            End;
          end;
          Inc(ItemIdx);
        End;

      // --- Literal Escape ---
      '\':
        Begin
          Inc(MaskPtr); // Skip slash
          if MaskPtr <= MaskLen then begin
            Result := Result + Mask[MaskPtr];
            Inc(MaskPtr);
          end;
        End;

      // --- Any other character is a literal ---
      Else
        Begin
          Result := Result + Mask[MaskPtr];
          Inc(MaskPtr);
        End;
    End;
  End;

  // Update Position for next call if needed
  Position := MaskPtr;
End;


end.

