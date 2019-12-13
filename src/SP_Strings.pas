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

interface

Uses SysUtils, Math, SP_Util, SP_Errors, SP_Tokenise;

Type

  TBackRef = Record
    RegExp, Matched: aString;
  End;

  TUsingItem = Record
    Kind: Byte;       // 0 = Value, 1 = String
    Value: aFloat;
    Text: aString;
  End;

// Regular Expression engine

Function SP_Regexp(RegExp, Text: aString; Var Index: Integer; Var Error: TSP_ErrorCode): Integer;
Function SP_Match(Const RegExp, Text: aString; rIdx: Integer; Var tIdx: Integer; Var Match: aString; Var Error: TSP_ErrorCode): Boolean;
Function SP_MatchOneOf(Matches: aString; txPtr: pByte; Literal: Boolean; Var Accum: aString): Boolean;

// USING and USING$ functionality

Function SP_Using(Mask: aString; Items: Array of TUsingItem; Var Position: Integer): aString;

implementation

// RegExp engine. Supports:
//
// .     Match any character
// *     Match any number (or none) of the preceding item
// +     Match at least one of the preceding item
// ?     Match none, or once only
// []    creates a set of matches that must match at least one
// [-[]] inserts a list of subtractions into a set of matches
// [^]   creates a set of matches that must not match
// |     separates optional regexes
// ()    Creates a sub-expression
// {m}   Repeats the previous item m times
// {m,}  Repeats the previous item at least m times
// {,n}  Match optionally no more than n times
// {m,n} Repeats the previous item at least m and not more than n times
// $     Matches the end of the string
// ^     Matches the start of the string
// \     Escape a character
// \n    Recalls a sub-expression's match, local to the current regex or sub-expression
// \xFF  Matches the character represented by the Hexadecimal number given

Function SP_RegExp(RegExp, Text: aString; Var Index: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  rIdx, tIdx, ctIdx, txLen: Integer;
  Match: aString;
Begin

  // Performs regular expression matching of RegExp onto Text. Returns the position
  // of the first match. This is just the wrapper function called by the interpreter.
  // Returns the last matched character in Index, for counting purposes.

  If RegExp = '' Then

    Result := 0

  Else Begin

    ctIdx := Index -1;
    Result := 0;
    txLen := Length(Text) +1;

    While Result = 0 Do Begin

      rIdx := 1;
      Inc(ctIdx);
      tIdx := ctIdx;
      If tIdx = txLen Then Exit;

      If SP_Match(RegExp, Text, rIdx, tIdx, Match, Error) Then Begin
        Result := ctIdx;
        Index := tIdx;
      End Else
        Result := 0;

      If Error.Code <> SP_ERR_OK Then Exit;

    End;

  End;

End;

Function SP_Match(Const RegExp, Text: aString; rIdx: Integer; Var tIdx: Integer; Var Match: aString; Var Error: TSP_ErrorCode): Boolean;
Var
  MatchList, SubExpr, SubMatch: aString;
  RgLen, TxLen, Idx, BraceCount, Count, ctIdx, m, n: Integer;
  rgPtr, rgEnd, rgAnchor: pByte;
  Literal, Matched: Boolean;
  SubExprs: Array of aString;
  NumSubExprs: Integer;
  Chr: aChar;
Label
  Start, NextOption, Finish;

  Function StrToInt(Const Text: aString; Var Position: Integer): Integer;
  Begin
    If Text[Position] in ['0'..'9'] Then Begin
      Result := 0;
      While (Position <= Length(Text)) And (Text[Position] in ['0'..'9']) Do Begin
        Result := (Result * 10) + Ord(Text[Position]) - 48;
        Inc(Position);
      End;
    End Else
      Result := -1;
  End;

  Procedure ProcessSubtraction(Var MatchList: aString; Var Ptr, EndPtr: pByte);
  Var
    SubtractionList: aString;
    Idx, Psn: Integer;
    Chr: aChar;
  Begin
    SubtractionList := '';
    While Ptr <> EndPtr Do Begin
      If Ptr^ = Ord('-') Then Begin
        Inc(Ptr);
        If (Ptr = EndPtr) or (Ptr^ = Ord(']')) or (SubtractionList = '+') or (SubtractionList = '-') Then
          SubtractionList := SubtractionList + '-'
        Else Begin
          For Idx := Ord(SubtractionList[Length(SubtractionList)])+1 To Ptr^ Do
            SubtractionList := SubtractionList + aChar(Idx);
          Inc(Ptr);
          If (Ptr < EndPtr -1) And (Ptr^ = Ord('-')) and (pByte(Ptr +1)^ = Ord('[')) Then Begin
            Inc(Ptr, 2);
            ProcessSubtraction(SubtractionList, Ptr, EndPtr);
          End Else
            Dec(Ptr);
        End;
      End Else
        If Ptr^ = Ord(']') Then Begin
          If SubtractionList = '' Then
            SubtractionList := SubtractionList + ']'
          Else
            Break;
        End Else
          If Ptr^ = Ord('\') Then Begin
            Inc(Ptr);
            If Ptr = EndPtr Then
              SubtractionList := SubtractionList + '\'
            Else
              SubtractionList := SubtractionList + aChar(Ptr^);
          End Else
            SubtractionList := SubtractionList + aChar(Ptr^);
      Inc(Ptr);
    End;
    If MatchList[1] = '+' Then Begin
      For Idx := 1 To Length(SubtractionList) Do Begin
        Chr := SubtractionList[Idx];
        Repeat
          Psn := Pos(Chr, MatchList);
          If Psn > 1 Then
            MatchList := Copy(MatchList, 1, Psn -1) + Copy(MatchList, Psn +1, Length(MatchList));
        Until Psn < 2;
      End;
    End Else Begin
      For Idx := 1 To Length(SubtractionList) Do Begin
        Chr := SubtractionList[Idx];
        Repeat
          Psn := Pos(Chr, MatchList);
          If Psn < 2 Then
            MatchList := MatchList + Chr;
        Until Psn < 2;
      End;
    End;
  End;

Begin

  // The meat of the regular expression parser.
  // Start by picking up a valid matchable character.

  Result := False;

  Literal := False;
  SubExpr := '';
  Match := '';
  NumSubExprs := 0;

  ctIdx := tIdx;
  RgLen := Length(RegExp);
  rgEnd := pByte(@RegExp[RgLen]) +1;
  TxLen := Length(Text);

  Start:

  While rIdx <= rgLen Do Begin

    MatchList := '+';

    Case RegExp[rIdx] of

      '.': // Match any character
          Begin
            MatchList := '+.';
          End;
      '(': // A sub-expression, lookahead. Don't do anything yet, just collect it up to the closing
           // bracket.
          Begin
            BraceCount := 1;
            SubExpr := '';
            While True Do Begin
              Inc(rIdx);
              If rIdx <= rgLen Then Begin
                Case RegExp[rIdx] of
                  '(':  Inc(BraceCount);
                  ')':  Begin
                          Dec(BraceCount);
                          If BraceCount = 0 Then Break;
                        End;
                Else
                  SubExpr := SubExpr + RegExp[rIdx];
                End;
              End Else Begin
                Error.Code := SP_ERR_REGEXP_ERROR;
                Goto Finish;
              End;
            End;
            SetLength(SubExprs, Length(SubExprs) +1);
            SubExprs[Length(SubExprs) -1] := '';
            Inc(NumSubExprs);
          End;
      '[': // Create a list of characters to match, or not-match
          Begin
            Inc(rIdx);
            MatchList := '+';
            rgPtr := @RegExp[rIdx];
            rgAnchor := rgPtr;
            While rgPtr <> rgEnd Do Begin
              If rgPtr^ = Ord('^') Then Begin
                // a ^ character, if it's the first in the list, indicates
                // that the following characters should *not* be matched. Otherwise
                // It's a literal caret.
                If Matchlist = '+' Then
                  Matchlist[1] := '-'
                Else
                  Matchlist := Matchlist + '^';
              End Else
                If rgPtr^ = Ord(']') Then Begin
                  // A closing bracket - if it's the first (or second after the "^") character,
                  // then it's a literal bracket. Otherwise it closes the list.
                  If (Matchlist = '-') or (Matchlist = '+') Then
                    Matchlist := Matchlist + ']'
                  Else Begin
                    Literal := True;
                    Break;
                  End;
                End Else
                  If rgPtr^ = Ord('-') Then Begin
                    // a "-" denotes a sequence, such as "a-z" or "0-9". Unless it's the first (after the "^")
                    // or last character, in which case it's a literal "-".
                    Inc(rgPtr);
                    If (rgPtr = rgEnd) or (rgPtr^ = Ord(']')) or (Matchlist = '+') or (Matchlist = '-') Then
                      Matchlist := Matchlist + '-'
                    Else Begin
                      For Idx := Ord(Matchlist[Length(Matchlist)])+1 To rgPtr^ Do
                        Matchlist := Matchlist + aChar(Idx);
                      // After a - symbol, we can have a subtraction list. Subtraction lists can be
                      // recursive, so beware of those. Starts with a "-[" and follows the usual rules.
                      Inc(rgPtr);
                      If (rgPtr < rgEnd -1) and (rgPtr^ = Ord('-')) and (pByte(rgPtr +1)^ = Ord('[')) Then Begin
                        Inc(rgPtr, 2);
                        ProcessSubtraction(MatchList, rgPtr, rgEnd);
                      End Else
                        Dec(rgPtr);
                    End;
                  End Else
                    // A backslash denotes a literal character, unless it's the last char in the list,
                    // where it's a literal backslash.
                    If rgPtr^ = Ord('\') Then Begin
                      Inc(rgPtr);
                      If rgPtr = rgEnd Then
                        Matchlist := Matchlist + '\'
                      Else
                        Matchlist := Matchlist + aChar(rgPtr^);
                    End Else
                      Matchlist := Matchlist + aChar(rgPtr^);
              Inc(rgPtr);
            End;
            Inc(rIdx, rgPtr - rgAnchor);
          End;
      '$': // Match the end of the text
          Begin
            // If successful, then there's no more text to process,
            // if unsuccessful then the regex has failed. So exit either way.
            Result := tIdx = txLen +1;
            Goto Finish;
          End;
      '^': // Match the beginning of the text
          Begin
            // If we're not at the start, then we should bail now.
            If tIdx <> 1 Then Begin
              Result := False;
              Goto Finish;
            End;
          End;
      '|': // Marks the start of an option - if there are characters left in the regex.
           // If we encounter it, we should exit with a true result now, as we've successfully matched this far.
          Begin
            If rIdx = rgLen Then
              MatchList := '+|'
            Else Begin
              Result := True;
              Goto Finish;
            End;
          End;
      '\': // A literal character. If it's a number, or sequence of numbers, then it's a backreference.
           // Otherwise it's a character to be added to the matchlist.
          Begin
            Inc(rIdx);
            MatchList := '+';
            If RegExp[rIdx] in ['0'..'9'] Then Begin
              Idx := StrToInt(RegExp, rIdx);
              If (Idx >= 1) And (Idx <= NumSubExprs) Then
                SubExpr := SubExprs[Idx -1]
              Else Begin
                Error.Code := SP_ERR_REGEXP_ERROR;
                Goto Finish;
              End;
            End Else
              If RegExp[rIdx] = 'x' Then Begin
                Inc(rIdx);
                Chr := Upper(RegExp[rIdx])[1];
                If Chr in ['0'..'9'] Then
                  Idx := Ord(Chr) - 48
                Else
                  If Chr in ['A'..'F'] Then
                    Idx := Ord(Chr) - 55
                  Else Begin
                    Error.Code := SP_ERR_REGEXP_ERROR;
                    Exit;
                  End;
                Inc(rIdx);
                Chr := Upper(RegExp[rIdx])[1];
                If Chr in ['0'..'9'] Then
                  Idx := Idx + Ord(Chr) - 48
                Else
                  If Chr in ['A'..'F'] Then
                    Idx := Idx + Ord(Chr) - 55
                  Else Begin
                    Error.Code := SP_ERR_REGEXP_ERROR;
                    Exit;
                  End;
                MatchList := MatchList + aChar(Idx);
              End Else
                Begin
                  MatchList := MatchList + RegExp[rIdx];
                  Literal := True;
                End;
          End;
    Else
      Begin
        // We've encountered a literal character.
        MatchList := MatchList + RegExp[rIdx];
      End;
    End;

    // Now check for modifiers - *,+,? - must have something to match here,
    // either a subexpression or a matchlist

    Inc(rIdx);

    Case RegExp[rIdx] of

      '*': // Match many, or none of the preceding item.
        Begin
          Matched := False;
          Repeat
            If Matchlist <> '+' Then Begin
              Matched := SP_MatchOneOf(MatchList, @Text[tIdx], Literal, Match);
              If Matched Then Inc(tIdx);
            End Else
              If SubExpr <> '' Then Begin
                Idx := tIdx;
                Matched := SP_Match(SubExpr, Text, 1, tIdx, SubMatch, Error);
                If Not Matched Then tIdx := Idx Else SubExprs[Length(SubExprs)] := SubMatch;
              End;
            Until Not Matched;
          Inc(rIdx);
        End;
      '+': // Match at least one of the preceding item.
        Begin
          Count := 0;
          Matched := False;
          Repeat
            If Matchlist <> '+' Then Begin
              Matched := SP_MatchOneOf(MatchList, @Text[tIdx], Literal, Match);
              If Matched Then Inc(tIdx);
            End Else
              If SubExpr <> '' Then Begin
                Idx := tIdx;
                Matched := SP_Match(SubExpr, Text, 1, tIdx, SubMatch, Error);
                If Not Matched Then tIdx := Idx Else SubExprs[Length(SubExprs)] := SubMatch;
              End;
            If Matched Then Inc(Count);
          Until Not Matched;
          If Count = 0 Then Goto NextOption;
          Inc(rIdx);
        End;
      '?': // Match none, or one only of the preceding item.
        Begin
          If Matchlist <> '+' Then Begin
            Matched := SP_MatchOneOf(MatchList, @Text[tIdx], Literal, Match);
            If Matched Then Inc(tIdx);
          End Else
            If SubExpr <> '' Then Begin
              Idx := tIdx;
              Matched := SP_Match(SubExpr, Text, 1, tIdx, SubMatch, Error);
              If Not Matched Then tIdx := Idx Else SubExprs[Length(SubExprs)] := SubMatch;
            End;
          Inc(rIdx);
        End;
      '{': // A minimal count definition. Valid ranges are:
           // {m} Match the last item m times
           // {m,} Match the last item at least m times
           // {m,n} Match the last item at least m, and no more than n times
           // {,n} Match optionally no more than n times
          Begin
            Inc(rIdx);
            If RegExp[rIdx] = ',' Then
              m := 0
            Else
              m := StrToInt(RegExp, rIdx);
            If m >= 0 Then Begin
              If RegExp[rIdx] = '}' Then Begin
                Inc(rIdx);
              End Else
                If RegExp[rIdx] = ',' Then Begin
                  Inc(rIdx);
                  If RegExp[rIdx] = '}' Then Begin
                    Inc(rIdx);
                  End Else Begin
                    n := StrToInt(RegExp, rIdx);
                    If n < m Then Begin
                      Error.Code := SP_ERR_REGEXP_ERROR;
                      Goto Finish;
                    End Else Begin
                      Count := 0;
                      Matched := False;
                      Repeat
                        If Matchlist <> '+' Then Begin
                          Matched := SP_MatchOneOf(MatchList, @Text[tIdx], Literal, Match);
                          If Matched Then Inc(tIdx);
                        End Else
                          If SubExpr <> '' Then Begin
                            Idx := tIdx;
                            Matched := SP_Match(SubExpr, Text, 1, tIdx, SubMatch, Error);
                            If Not Matched Then tIdx := Idx Else SubExprs[Length(SubExprs)] := SubMatch;
                          End;
                        If Matched Then Inc(Count);
                      Until Not Matched or ((Count = n) And (n > m));
                      If Count < m Then Goto NextOption;
                    End;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_REGEXP_ERROR;
                  Goto Finish;
                End;
            End Else Begin
              Error.Code := SP_ERR_REGEXP_ERROR;
              Goto Finish;
            End;
          End;

    Else

      Begin

        // If the above failed, then we've got an item followed by another item, so
        // let's test to see if what we have so far matches! If it does, we inherit the new
        // text position. If not, it gets reset anyway.

        If (tIdx > txLen) And (rIdx <= rgLen) Then
          Goto Finish;

        If Matchlist <> '+' Then Begin

          // This is a list of things to test.

          If Not SP_MatchOneOf(MatchList, @Text[tIdx], Literal, Match) Then
            Goto NextOption
          Else Begin
            Inc(tIdx);
          End;

        End Else

          If SubExpr <> '' Then Begin

            // We've collected a subexpression.

            If Not SP_Match(SubExpr, Text, 1, tIdx, SubMatch, Error) Then
              Goto NextOption
            Else
              SubExprs[Length(SubExprs) -1] := SubMatch;

          End;

      End;

    End;

  End;

  Result := True;
  Goto Finish;

NextOption:

  // We failed at this point, so need to check if there are any optional regexes included in this one.
  // Test for a "|", but only if it's not in parentheses!

  BraceCount := 0;

  While rIdx <= rgLen Do Begin

    Case RegExp[rIdx] of
      '(': Inc(BraceCount);
      ')': Dec(BraceCount);
      '|': If BraceCount = 0 Then Begin
              Inc(rIdx);
              tIdx := ctIdx;
              Goto Start;
           End;
    End;
    Inc(rIdx);

  End;

  // Fall through here with no options found or matched.

Finish:

  SetLength(SubExprs, 0);

End;

Function SP_MatchOneOf(Matches: aString; txPtr: pByte; Literal: Boolean; Var Accum: aString): Boolean;
Var
  NoneOf: Boolean;
Begin

  NoneOf := Matches[1] = '-';
  Matches := Copy(Matches, 2, Length(Matches));
  If NoneOf Then
    Result := Pos(aChar(txPtr^), Matches) = 0
  Else
    If Not Literal And (Matches[1] = '.') Then
      Result := True
    Else
      Result := Pos(aChar(txPtr^), Matches) <> 0;

  If Result Then
    Accum := Accum + aChar(txPtr^);

End;

// Begin USING$ mask parser -

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

Function SP_Using(Mask: aString; Items: Array of TUsingItem; Var Position: Integer): aString;
Var
  InsertCommas, AddDollar, AddPound, AddDecimal, GotField: Boolean;
  SpacingLeft, SpacingRight: aChar;
  iIdx, Idx, NumPreDigits, NumPostDigits, AddSign, StrWanted: Integer;
  TempStr: aString;

  Procedure ProcessField(Var Output: aString);
  Var
    Units, Decimals: aString;
    Idx, Count: Integer;
  Label
    Finish;
  Begin
    Output := '';
    Case Items[iIdx].Kind Of
      SP_VALUE: // Value
        Begin
          If Not AddDecimal Then
            Items[iIdx].Value := Round(Items[iIdx].Value)
          Else
            If NumPostDigits > 0 Then
              Items[iIdx].Value := RoundTo(Items[iIdx].Value, -NumPostDigits);
          Output := aString(aFloatToStr(Abs(Items[iIdx].Value)));
          If Pos('.', Output) > 0 Then Begin
            Units := Copy(Output, 1, Pos('.', Output) -1);
            Decimals := Copy(Output, Pos('.', Output) +1, Length(Output));
          End Else Begin
            Units := Output;
            Decimals := '';
          End;
          If AddPound Then
            Units := '£' + Units
          Else
            If AddDollar Then
              Units := '$' + Units;
          Output := '';
          If InsertCommas Then Begin
            Count := 0;
            Idx := Length(Units);
            While Idx > 0 Do Begin
              If Units[Idx] in ['0'..'9'] Then Begin
                Inc(Count);
                If (Count = 3) and (Idx > 1) Then Begin
                  Units := Copy(Units, 1, Idx -1) + ',' + Copy(Units, Idx, Length(Units));
                  Dec(NumPreDigits);
                  Count := 0;
                End;
              End;
              Dec(Idx);
            End;
          End;
          If AddSign = 2 Then Begin
            If Items[iIdx].Value > 0 Then
              Units := '+' + Units
            Else
              Units := '-' + Units;
          End Else
            If Items[iIdx].Value < 0 Then Begin
              Units := '-' + Units;
              Dec(NumPreDigits);
            End;
          If Length(Units) > NumPreDigits Then Begin
            Output := '';
            For Idx := 1 To NumPreDigits Do
              Output := Output + '*';
          End Else
            If Length(Units) = NumPreDigits Then
              Output := Units
            Else Begin
              For Idx := 1 To NumPreDigits - Length(Units) Do
                Output := Output + SpacingLeft;
              Output := Output + Units;
            End;
          If StrWanted = -1 Then
            Output := Output + Units
          Else
            If StrWanted > 0 Then
              Output := Output + Copy(Units, 1, StrWanted);
          If AddDecimal Then Begin
            Output := Output + '.' + Decimals;
            For Idx := 1 To NumPostDigits - Length(Decimals) Do
              Output := Output + SpacingRight;
          End;
        End;
      SP_STRING: // String
        Begin
          If StrWanted = 0 Then
            Goto Finish
          Else
            If StrWanted = -1 Then
              Output := Items[iIdx].Text
            Else
              Output := Copy(Items[iIdx].Text, 1, StrWanted);
        End;
    End;

  Finish:

    Inc(iIdx);
    InsertCommas := False;
    AddDollar := False;
    AddPound := False;
    NumPreDigits := 0;
    NumPostDigits := 0;
    SpacingLeft := ' ';
    SpacingRight := ' ';
    StrWanted := 0;

  End;

Begin

  Result := '';
  InsertCommas := False;
  AddDollar := False;
  AddPound := False;
  AddDecimal := False;
  GotField := False;

  NumPreDigits := 0;
  NumPostDigits := 0;

  SpacingLeft := ' ';
  SpacingRight := ' ';
  StrWanted := 0;

  iIdx := 0;
  Idx := Position Mod Length(Mask);

  While True Do Begin

    While Idx <= Length(Mask) Do Begin

      // Pick up items - emit non-field items directly.

      Case Mask[Idx] of

        '#': // Digit placeholder
          Begin
            If iIdx > High(Items) Then Begin
              Position := Idx;
              Exit;
            End;
            GotField := True;
            If Not AddDecimal Then
              Inc(NumPreDigits)
            Else
              Inc(NumPostDigits);
          End;
        '.': // Decimal separator position
          Begin
            AddDecimal := True;
          End;
        ',': // Thousands separator
          Begin
            InsertCommas := True;
          End;
        '$': // Insert currency before digits
          Begin
            AddDollar := True;
            Inc(NumPreDigits);
          End;
        '£': // Insert currency before digits
          Begin
            AddPound := True;
            Inc(NumPreDigits);
          End;
        '*': // Padding character pre or post-decimal position
          Begin
            If Idx < Length(Mask) Then Begin
              If AddDecimal Then
                SpacingRight := Mask[Idx +1]
              Else
                SpacingLeft := Mask[Idx +1];
            End Else
              If GotField Then Begin
                ProcessField(TempStr);
                Result := Result + TempStr;
                GotField := False;
              End Else
                Result := Result + '*';
            Inc(Idx);
          End;
        '+': // Insert sign ("+" or "-")
          Begin
            AddSign := 2;
            Inc(NumPreDigits);
          End;
        '-': // Insert only "-" if negative
          Begin
            AddSign := 1;
            Inc(NumPreDigits);
          End;
        '\': // Insert literal character
          Begin
            If GotField Then Begin
              ProcessField(TempStr);
              Result := Result + TempStr;
              GotField := False;
            End;
            If Idx < Length(Mask) Then
              Result := Result + Mask[Idx +1]
            Else
              Result := Result + '\';
            Inc(Idx);
          End;
        '!':
          Begin
            StrWanted := 1;
            GotField := True;
          End;
        '&':
          Begin
            StrWanted := -1;
            GotField := True;
          End;
        '[':
          Begin
            Inc(Idx);
            If Idx < Length(Mask) Then Begin
              StrWanted := 0;
              While (Idx <= Length(Mask)) And (Mask[Idx] in ['0'..'9']) Do Begin
                StrWanted := (Ord(Mask[Idx]) - 48) + (StrWanted * 10);
                Inc(Idx);
              End;
              GotField := True;
              If (Idx < Length(Mask)) And (Mask[Idx] = ']') Then Inc(Idx);
            End Else Begin
              If GotField Then Begin
                ProcessField(TempStr);
                Result := Result + TempStr;
                GotField := False;
              End;
              Result := Result + ']';
            End;
          End;

      Else

        If GotField Then Begin
          ProcessField(TempStr);
          Result := Result + TempStr;
          GotField := False;
        End;
        Result := Result + Mask[Idx];

      End;

      Inc(Idx);

    End;

    If GotField or (NumPreDigits = 0) or ((NumPostDigits = 0) And (AddDecimal)) Then Begin
      ProcessField(TempStr);
      Result := Result + TempStr;
      GotField := False;
    End;

    If iIdx <= High(Items) Then Begin
      iIdx := 0;
      If iIdx = High(Items) Then
        Break;
    End Else Begin
      Position := Idx;
      Break;
    End;

  End;

End;

end.

