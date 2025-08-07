unit SP_VM_Emu;

{$INCLUDE SpecBAS.inc}

interface

Uses SP_Util, SP_BankManager, SP_Variables, SP_Errors, SP_Tokenise, Classes;


  // The BANK opcode - assigns a register to a memory bank, or the default
  // memory read/write to a bank. If the specified bank is -1, then the
  // source assembly memory region is used.

  // 0D - BANK reg1,id.
  // 0E - BANK id.

  // The VAR opcode puts a numeric variable's value into a register, truncated
  // towards zero. The VAR$ opcode assigns a register to the start of a string
  // in the same way that the BANK opcode does.

  // 0F - VAR  reg1,numvar
  // 10 - VAR$ reg1,[strvar$]

Type

  TOpcodeProc = Procedure(Var Param1, Param2: LongWord);
  pOpcodeProc = ^TOpcodeProc;

  TRegister = Record
    MemPtr, MemMinPtr, MemMaxPtr: pByte;
  End;

  TOpcodeDescriptor = Record
    Opcode: aString;
    pSpec: Byte;
  End;

  Function  Assemble(Source: aString; Var Error: TSP_ErrorCode): aString;
  Procedure ExecuteAsm(Var SrcPtr: pByte; Var Error: TSP_ErrorCode);

Var

  FlagZero, FlagCarry: Byte;
  Registers: Array[0..31] of TRegister;
  DefaultMemory: TRegister;

Const

  Opcodes: Array[0..10] of TOpcodeDescriptor =
    ((Opcode: 'nop'; pSpec: 0),
     (Opcode: 'ld'; pSpec: 1),
     (Opcode: 'add'; pSpec: 1),
     (Opcode: 'adc'; pSpec: 1),
     (Opcode: 'sub'; pSpec: 1),
     (Opcode: 'sbc'; pSpec: 1),
     (Opcode: 'mul'; pSpec: 1),
     (Opcode: 'div'; pSpec: 1),
     (Opcode: 'and'; pSpec: 1),
     (Opcode: 'or'; pSpec: 1),
     (Opcode: 'xor'; pSpec: 1));

implementation

Function Assemble(Source: aString; Var Error: TSP_ErrorCode): aString;
Type
  TLabelSpec = Record
    Name: aString;
    Position: Integer;
  End;
Var
  Idx, lIdx, wIdx, Param1, Param2, sLen: Integer;
  OpcodeBase: LongWord;
  ParamBase: Byte;
  cWord: aString;
  Labels: Array of TLabelSpec;

  Function IsOpcode(Const cWord: aString): Integer;
  Var
    Idx: Integer;
  Begin
    Result := -1;
    For Idx := 0 To High(Opcodes) Do
      If Opcodes[Idx].Opcode = cWord Then Begin
        Result := Idx;
        Exit;
      End;
  End;

  Function GetWord(Var Idx: Integer): aString;
  Begin
    Result := '';
    While Idx <= Length(Source) Do Begin
      If (Source[Idx] <= ' ') or (Source[Idx] in [',',':']) Then
        Break
      Else
        Result := Result + Source[Idx];
      Inc(Idx);
    End;
  End;

  Function GetRegID(Const cWord: aString): Integer;
  Var
    Len: Integer;
  Begin
    Len := Length(cWord);
    If (Len < 2) or (Len > 3) Then
      Result := -1
    Else
      If Len = 2 Then
        Result := Ord(cWord[2]) - 48
      Else
        Result := ((10 * Ord(cWord[2])) - 48) + Ord(cWord[3]) - 48;
  End;

  Function GetIntValue(Const cWord: aString; CanAddress, CanLabel: Boolean): Integer;
  Var
    Len, fIdx: Integer;
  Begin
    Result := 0;
    Len := Length(cWord);
    If cWord[1] = '[' Then Begin
      If CanAddress Then Begin
        fIdx := 2;
        If cWord[Length(cWord)] <> ']' Then Begin
          Error.Code := SP_ERR_ASM_ERROR;
          Exit;
        End;
      End Else Begin
        Error.Code := SP_ERR_ASM_ERROR;
        Exit;
      End;
    End Else
      fIdx := 1;
    If fIdx <= Len Then Begin
      If cWord[fIdx] = '@' Then Begin
        If CanLabel Then Begin

        End Else Begin
          Error.Code := SP_ERR_ASM_ERROR;
          Exit;
        End;
      End Else Begin
        If cWord[fIdx] = '$' Then Begin

        End Else
          If cWord[fIdx] = '%' Then Begin

          End Else Begin
            While (fIdx <= Length(cWord)) And (cWord[fIdx] in ['0'..'9']) Do Begin
              Result := (Result * 10) + (Ord(cWord[fIdx]) - 48);
              Inc(fIdx);
            End;
          End;
      End;
    End;
  End;

Begin

  Idx := 1;
  sLen := Length(Source);
  SP_SkipSpaces(Source, Idx);
  Result := '';

  While Idx < sLen Do Begin

    // Get the opcode class

    cWord := Lower(GetWord(Idx));
    If cWord = '' Then Begin
      Error.Code := SP_ERR_ASM_ERROR;
      Exit;
    End Else
      SP_SkipSpaces(Source, Idx);

    wIdx := IsOpcode(cWord);
    If wIdx = -1 Then Begin
      Error.Code := SP_ERR_ASM_ERROR;
      Exit;
    End;

    Case Opcodes[wIdx].pSpec Of
      0:  Begin

            // Nop - no operation.

            Result := Result + LongWordToString(0);

          End;

      1:  Begin

          // Parameters: <size> destination, <size> source
          // destination can be any of reg,[reg],[address]
          // source can be any of reg,[reg],[address],value
          // Size can be BYTE, WORD, DWORD or nothing (DWORD assumed)

          OpcodeBase := 1; // LD = 001

          ParamBase := 0;
          cWord := Lower(GetWord(Idx));
          If cWord = '' Then Begin
            Error.Code := SP_ERR_ASM_ERROR;
            Exit;
          End Else
            SP_SkipSpaces(Source, Idx);

          If Not (cWord[1] in ['[', 'r']) Then Begin

            If cWord = 'byte' Then
              ParamBase := ParamBase Or 0
            Else
              If cWord = 'word' Then
                ParamBase := ParamBase Or 4
              Else
                If cWord = 'dword' Then
                  ParamBase := ParamBase or 8
                Else Begin
                  Error.Code := SP_ERR_ASM_ERROR;
                  Exit;
                End;

            // Pick up the next parameter, as this one was a valid size.

            cWord := Lower(GetWord(Idx));
            If cWord = '' Then Begin
              Error.Code := SP_ERR_ASM_ERROR;
              Exit;
            End Else
              SP_SkipSpaces(Source, Idx);

          End Else

            ParamBase := ParamBase Or 8; // Default is DWORD.

          // Destination Parameter - reg, [reg] or [address]

          If cWord[1] = 'r' Then Begin
            Param1 := GetRegID(cWord);
            ParamBase := ParamBase Or 1;
            If Param1 = -1 Then Begin
              Error.Code := SP_ERR_ASM_ERROR;
              Exit;
            End;
          End Else
            If cWord[1] = '[' Then Begin
              If Length(cWord) > 1 Then Begin
                If cWord[2] = 'r' Then Begin
                  If cWord[Length(cWord)] = ']' Then Begin
                    cWord := Copy(cWord, 2, Length(cWord) -2);
                    Param1 := GetRegID(cWord);
                    ParamBase := ParamBase Or 2;
                    If Param1 = -1 Then Begin
                      Error.Code := SP_ERR_ASM_ERROR;
                      Exit;
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_ASM_ERROR;
                    Exit;
                  End;
                End Else Begin
                  Param1 := GetIntValue(cWord, True, True);
                  If Error.Code <> SP_ERR_OK Then Exit;
                End;
              End Else Begin
                Error.Code := SP_ERR_ASM_ERROR;
                Exit;
              End;
            End Else Begin
              Error.Code := SP_ERR_ASM_ERROR;
              Exit;
            End;

          // Comma, followed by Source Parameter - value, reg, [reg] or [address]

          If Source[Idx] = ',' Then Begin

            Inc(Idx);
            cWord := Lower(GetWord(Idx));
            If cWord = '' Then Begin
              Error.Code := SP_ERR_ASM_ERROR;
              Exit;
            End Else
              SP_SkipSpaces(Source, Idx);

            If Not (cWord[1] in ['[', 'r']) Then Begin

              If cWord = 'byte' Then
                ParamBase := ParamBase Or 0
              Else
                If cWord = 'word' Then
                  ParamBase := ParamBase Or 64
                Else
                  If cWord = 'dword' Then
                    ParamBase := ParamBase or 128
                  Else Begin
                    Error.Code := SP_ERR_ASM_ERROR;
                    Exit;
                  End;

              // Pick up the next parameter, as this one was a valid size.

              cWord := Lower(GetWord(Idx));
              If cWord = '' Then Begin
                Error.Code := SP_ERR_ASM_ERROR;
                Exit;
              End Else
                SP_SkipSpaces(Source, Idx);

            End Else

              ParamBase := ParamBase Or 128; // Default is DWORD.

            If cWord[1] = 'r' Then Begin
              Param2 := GetRegID(cWord);
              ParamBase := ParamBase Or 16;
              If Param2 = -1 Then Begin
                Error.Code := SP_ERR_ASM_ERROR;
                Exit;
              End;
            End Else
              If cWord[1] = '[' Then Begin
                If Length(cWord) > 1 Then Begin
                  If cWord[2] = 'r' Then Begin
                    If cWord[Length(cWord)] = ']' Then Begin
                      cWord := Copy(cWord, 2, Length(cWord) -2);
                      Param2 := GetRegID(cWord);
                      ParamBase := ParamBase Or 32;
                      If Param2 = -1 Then Begin
                        Error.Code := SP_ERR_ASM_ERROR;
                        Exit;
                      End;
                    End Else Begin
                      Error.Code := SP_ERR_ASM_ERROR;
                      Exit;
                    End;
                  End Else Begin
                    Param2 := GetIntValue(cWord, True, True);
                    If Error.Code <> SP_ERR_OK Then Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_ASM_ERROR;
                  Exit;
                End;
              End Else Begin
                Param2 := GetIntValue(cWord, False, True);
                ParamBase := ParamBase Or 48;
                If Error.Code <> SP_ERR_OK Then Exit;
              End;

          End Else Begin
            Error.Code := SP_ERR_ASM_ERROR;
            Exit;
          End;

          OpcodeBase := OpcodeBase Or (ParamBase Shl 8);
          Result := Result + LongWordToString(OpcodeBase) + LongWordToString(Param1) + LongWordToString(Param2);

        End;

    2:  Begin

          // BANK sets a register (or the default addressing mode) to a bank ID.
          // Expecting a register or a numeric ID.

          ParamBase := 0;
          OpcodeBase := 2; // BANK = 002

          cWord := Lower(GetWord(Idx));
          SP_SkipSpaces(Source, Idx);
          If cWord <> '' Then Begin
            If cWord[1] = 'r' Then Begin
              ParamBase := 0;
              Param1 := GetRegID(cWord);
              If Param1 > -1 Then Begin
                If (Idx <= sLen) And (Source[Idx] = ',') Then Begin
                  Inc(Idx);
                  If Idx <= sLen Then
                    SP_SkipSpaces(Source, Idx);
                  If Idx <= sLen Then Begin
                    cWord := Lower(GetWord(Idx));
                    If cWord <> '' Then Begin
                      Param2 := GetIntValue(cWord, False, False);
                      If Error.Code <> SP_ERR_OK Then Exit;
                      OpcodeBase := OpcodeBase Or (ParamBase Shl 8);
                      Result := Result + LongWordToString(OpcodeBase) + LongWordToString(Param1) + LongWordToString(Param2);
                    End;
                  End Else Begin
                    Error.Code := SP_ERR_ASM_ERROR;
                    Exit;
                  End;
                End Else Begin
                  Error.Code := SP_ERR_ASM_ERROR;
                  Exit;
                End;
              End Else Begin
                Error.Code := SP_ERR_ASM_ERROR;
                Exit;
              End;
            End Else Begin
              Param1 := GetIntValue(cWord, False, False);
              ParamBase := 1;
              If Error.Code <> SP_ERR_OK Then Exit;
              OpcodeBase := OpcodeBase Or (ParamBase Shl 8);
              Result := Result + LongWordToString(OpcodeBase) + LongWordToString(Param1);
            End;
          End;

        End;

    3:  Begin

          // Parameters are register,variable[$]

          OpcodeBase := 3; // VAR = 003

          cWord := Lower(GetWord(Idx));
          If cWord = '' Then Begin
            Error.Code := SP_ERR_ASM_ERROR;
            Exit;
          End Else
            SP_SkipSpaces(Source, Idx);

          If cWord[1] = 'r' Then Begin

            Param1 := GetRegID(cWord);
            If Param1 = -1 Then Begin
              Error.Code := SP_ERR_ASM_ERROR;
              Exit;
            End;

            If Source[Idx] = ',' Then Begin

              Inc(Idx);
              cWord := Lower(GetWord(Idx));
              If cWord = '' Then Begin
                Error.Code := SP_ERR_ASM_ERROR;
                Exit;
              End Else
                SP_SkipSpaces(Source, Idx);

              If cWord[Length(cWord)] = '$' Then
                ParamBase := 1
              Else
                ParamBase := 0;

              OpcodeBase := OpcodeBase Or (ParamBase Shl 8);
              Result := Result + LongWordToString(OpcodeBase) + LongWordToString(Param1) + LongWordToString(Length(cWord)) + cWord;

            End Else Begin
              Error.Code := SP_ERR_ASM_ERROR;
              Exit;
            End;

          End Else Begin
            Error.Code := SP_ERR_ASM_ERROR;
            Exit;
          End;

        End;

    4:  Begin

        End;

    End;

  End;

End;

Procedure ExecuteAsm(Var SrcPtr: pByte; Var Error: TSP_ErrorCode);
Begin
End;

end.



