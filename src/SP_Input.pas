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

unit SP_Input;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}

interface

Uses SP_SysVars, SP_Util, SP_Errors, SP_BankManager, SP_BankFiling, SP_Graphics, SyncObjs, SP_Components;

Type

  SP_KeyInfo = Packed Record  // Defines a key that is currently down
    KeyChar: aChar;           // The character that is down (for alpha-num-symbols}
    KeyCode: Word;            // For modifier keys etc
    NextFrameTime: Integer;  // When this reaches zero, it's counted as triggering a repeated key event
    Repeating: Boolean;       // Has the key started to repeat yet?
  End;
  pSP_KeyInfo = ^SP_KeyInfo;

  TKeyEvent = Packed Record
    Event: Byte; // 0 = key down, 1 = key up
    KeyCode: Word;
    KeyChar: aChar;
    Flags: Byte;
  End;

  TSP_Zone = Packed Record
    Id: Integer;
    Owner: Integer;
    WinInfo: pSP_Window_Info;
    x1,y1,x2,y2: Integer;
  End;

  TCB_GetKeyLockState = Procedure;

  Procedure WaitForKey;

  Procedure SP_AddKey(var KeyInfo: SP_KeyInfo);
  Procedure SP_RemoveKey(KeyCode: Word);
  Function  GetLastKeyChar: aString;
  Function  SP_AreAnyKeysDown: Boolean;
  Function  SP_GetNextKey(CurFrames: Integer): pSP_KeyInfo;
  Procedure SP_ClearAllKeys;

  Procedure SP_LoadKeyboardDefinition(Name: aString; Var Error: TSP_ErrorCode);
  Procedure SP_BufferKey(Key: pSP_KeyInfo; Event, Flags: Byte);
  Function  SP_KeyEventWaiting: Boolean;
  Procedure SP_UnBufferKey;

  Function  SP_NewZone(Var Error: TSP_ErrorCode): Integer;
  Function  SP_FindZone(Id: Integer; Var Error: TSP_ErrorCode): Integer;
  Procedure SP_UpdateZone(Id, Owner, x1, y1, x2, y2: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_UpdateZone_Coord(Id, Owner, x, y, w, h: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_MoveZone(Id, dX, dY: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_MoveZoneTo(Id, dX, dY: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_DeleteZone(Id: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_WindowDeleteZones(WinID: Integer);
  Function  SP_InZone(x, y: Integer; Var Error: TSP_ErrorCode): Integer;

Var

  CB_GetKeyLockState: TCB_GetKeyLockState;
  SP_ZoneList: Array of TSP_Zone;
  KeyBuffer: Array[0..1024] of TKeyEvent;
  KeyBufferPos: Integer = 0;
  KeyLock: TCriticalSection;
  global_i: integer;

  ActiveKeys: Array of SP_KeyInfo;

Const

  K_LBUTTON =       1;
  K_RBUTTON =       2;
  K_CANCEL =        3;
  K_MBUTTON =       4;
  K_BACK =          8;
  K_TAB =           9;
  K_ALTGR =         10;
  K_CLEAR =         12;
  K_RETURN =        13;
  K_SHIFT =         16;
  K_CONTROL =       17;
  K_ALT =           18;
  K_PAUSE =         19;
  K_CAPITAL =       20;
  K_ESCAPE =        27;
  K_SPACE =         32;
  K_PRIOR =         33;
  K_NEXT =          34;
  K_END =           35;
  K_HOME =          36;
  K_LEFT =          37;
  K_UP =            38;
  K_RIGHT =         39;
  K_DOWN =          40;
  K_SELECT =        41;
  K_PRINT =         42;
  K_EXECUTE =       43;
  K_SNAPSHOT =      44;
  K_INSERT =        45;
  K_DELETE =        46;
  K_HELP =          47;
  K_0 =             48;
  K_1 =             49;
  K_2 =             50;
  K_3 =             51;
  K_4 =             52;
  K_5 =             53;
  K_6 =             54;
  K_7 =             55;
  K_8 =             56;
  K_9 =             57;
  K_A =             65;
  K_B =             66;
  K_C =             67;
  K_D =             68;
  K_E =             69;
  K_F =             70;
  K_G =             71;
  K_H =             72;
  K_I =             73;
  K_J =             74;
  K_K =             75;
  K_L =             76;
  K_M =             77;
  K_N =             78;
  K_O =             79;
  K_P =             80;
  K_Q =             81;
  K_R =             82;
  K_S =             83;
  K_T =             84;
  K_U =             85;
  K_V =             86;
  K_W =             87;
  K_X =             88;
  K_Y =             89;
  K_Z =             90;
  K_LWIN =          91;
  K_RWIN =          92;
  K_APPS =          93;
  K_NUMPAD0 =       96;
  K_NUMPAD1 =       97;
  K_NUMPAD2 =       98;
  K_NUMPAD3 =       99;
  K_NUMPAD4 =       100;
  K_NUMPAD5 =       101;
  K_NUMPAD6 =       102;
  K_NUMPAD7 =       103;
  K_NUMPAD8 =       104;
  K_NUMPAD9 =       105;
  K_MULTIPLY =      106;
  K_ADD =           107;
  K_SEPARATOR =     108;
  K_SUBTRACT =      109;
  K_DECIMAL =       110;
  K_DIVIDE =        111;
  K_F1 =            112;
  K_F2 =            113;
  K_F3 =            114;
  K_F4 =            115;
  K_F5 =            116;
  K_F6 =            117;
  K_F7 =            118;
  K_F8 =            119;
  K_F9 =            120;
  K_F10 =           121;
  K_F11 =           122;
  K_F12 =           123;
  K_F13 =           124;
  K_F14 =           125;
  K_F15 =           126;
  K_F16 =           127;
  K_F17 =           128;
  K_F18 =           129;
  K_F19 =           130;
  K_F20 =           131;
  K_F21 =           132;
  K_F22 =           133;
  K_F23 =           134;
  K_F24 =           135;
  K_NUMLOCK =       144;
  K_SCROLL =        145;
  K_OEM_1 =         186;
  K_OEM_PLUS =      187;
  K_OEM_COMMA =     188;
  K_OEM_MINUS =     189;
  K_OEM_PERIOD =    190;
  K_OEM_2 =         191;
  K_OEM_3 =         192;
  K_OEM_4 =         219;
  K_OEM_5 =         220;
  K_OEM_6 =         221;
  K_OEM_7 =         222;
  K_OEM_8 =         223;
  K_OEM_AX =        225;
  K_OEM_102 =       226;
  K_ICO_HELP =      227;
  K_ICO_00 =        228;
  K_PROCESSKEY =    229;
  K_ICO_CLEAR =     230;
  K_OEM_RESET =     233;
  K_OEM_JUMP =      234;
  K_OEM_PA1 =       235;
  K_OEM_PA2 =       236;
  K_OEM_PA3 =       237;
  K_OEM_WSCTRL =    238;
  K_OEM_CUSEL =     239;
  K_OEM_ATTN =      240;
  K_OEM_FINNISH =   241;
  K_OEM_COPY =      242;
  K_OEM_AUTO =      243;
  K_OEM_ENLW =      244;
  K_OEM_BACKTAB =   245;
  K_ATTN =          246;
  K_CRSEL =         247;
  K_EXSEL =         248;
  K_EREOF =         249;
  K_PLAY =          250;
  K_ZOOM =          251;
  K_NONAME =        252;
  K_PA1 =           253;
  K_OEM_CLEAR =     254;

  // Key flags

  KF_NOCLICK =      1;

Var

  CharStr:        array[0..255] of aString;
  VKStr:          array[0..255] of aString;
  kbi:            Integer;
  KB_IN_USE:      Boolean;

implementation

Uses SP_FileIO, SP_Main;

Procedure WaitForKey;
Begin

  Repeat
    CB_YIELD;
  Until Length(ActiveKeys) > 0;

End;

Procedure SP_LoadKeyboardDefinition(Name: aString; Var Error: TSP_ErrorCode);
Var
  Hdr: aString;
  Idx, FileID, Count: Integer;
  Keybuffer: Array[0..515] of Byte;
Begin

  KB_IN_USE := False;

  If Not SP_FileExists(Name) Then Begin

    // Keyboard file not found - try prepending "keyboards:" to it

    Name := 'keyboards:'+Name;
    ERRStr := Name;
    If Not SP_FileExists(Name) Then Begin
      Error.Code := SP_ERR_FILE_NOT_FOUND;
      Exit;
    End;

  End;

  FileID := SP_FileOpen(Name, False, Error);
  If FileID > -1 Then Begin
    Count := SP_FileRead(FileID, @KeyBuffer[0], 516, Error);
    If Count = 516 Then Begin
      Idx := 0;
      Hdr := '';
      While Idx < 4 Do Begin
        Hdr := Hdr + aChar(KeyBuffer[Idx]);
        Inc(Idx);
      End;
      If Hdr = 'ZXKB' Then Begin
        For Idx := 0 To 255 Do Begin
          CharStr[Idx] := aChar(KeyBuffer[(Idx*2)+4]) + aChar(KeyBuffer[(Idx*2)+5]);
          If CharStr[Idx] = #0#0 Then
            CharStr[Idx] := '';
        End;
        KB_IN_USE := True;
      End Else
        Error.Code := SP_ERR_INVALID_KEYBOARD;
    End Else
      Error.Code := SP_ERR_INVALID_KEYBOARD;
  End Else
    Error.Code := SP_ERR_INVALID_KEYBOARD;

End;

Procedure SP_AddKey(var KeyInfo: SP_KeyInfo);
Var
  b: Boolean;
  i, l: Integer;
Begin
  KeyLock.Enter;
  b := False;
  l := Length(ActiveKeys);
  for i := 0 To l -1 Do
    If KeyInfo.KeyCode = ActiveKeys[i].KeyCode Then Begin
      l := i + 1;
      b := True;
      Break;
    End;
  If Not b Then Begin
    Inc(l);
    SetLength(ActiveKeys, l);
  End;
  KeyInfo.Repeating := False;
  CopyMem(@ActiveKeys[l - 1].KeyChar, @KeyInfo.KeyChar, SizeOf(SP_KeyInfo));
  KeyState[KeyInfo.KeyCode] := 1;
  KeyLock.Leave;
End;

Function SP_GetNextKey(CurFrames: Integer): pSP_KeyInfo;
Var
  i: Integer;
  Modifier: Byte;
Begin

  KeyLock.Enter;

  Result := nil;

  CB_GetKeyLockState;

  If KEYSTATE[K_SHIFT] <> 0 Then
    Modifier := 1
  Else
    Modifier := 0;

  i := Length(ActiveKeys) -1;
  While i >= 0 Do
    If Not (ActiveKeys[i].KeyCode in [16, 17, 18]) And (ActiveKeys[i].NextFrameTime <= CurFrames) Then Begin
      Result := @ActiveKeys[i];
      If Result^.Repeating Then
        Result^.NextFrameTime := CurFrames + REPPER
      Else Begin
        Result^.Repeating := True;
        Result^.NextFrameTime := CurFrames + REPDEL;
      End;
      Break;
    End Else
      Dec(i);

  If Assigned(Result) And KB_IN_USE Then
    If CharStr[Ord(Result.KeyChar)] <> '' Then Begin
      Result.KeyChar := CharStr[Ord(Result.KeyChar)][Modifier +1];
      If CAPSLOCK = 1 Then
        If Result.KeyChar in ['A'..'Z', 'a'..'z'] Then Begin
          Modifier := 1 - Modifier;
          Result.KeyChar := CharStr[Ord(Result.KeyChar)][Modifier +1];
        End;
    End;

  KeyLock.Leave;

End;

Function SP_AreAnyKeysDown: Boolean;
Var
  i: Integer;
Begin
  KeyLock.Enter;
  Result := False;
  i := Length(ActiveKeys) -1;
  While i >= 0 Do
    If (ActiveKeys[i].KeyCode in [16, 17, 18]) or (ActiveKeys[i].NextFrameTime <= FRAMES) Then Begin
      If ActiveKeys[i].Repeating Then
        ActiveKeys[i].NextFrameTime := FRAMES + REPPER
      Else Begin
        ActiveKeys[i].Repeating := True;
        ActiveKeys[i].NextFrameTime := FRAMES + REPDEL;
      End;
      Result := True;
      Break;
    End Else
      Dec(i);
  KeyLock.Leave;
End;

Function GetLastKeyChar: aString;
Var
  l: Integer;
Begin
  KeyLock.Enter;
  l := Length(ActiveKeys);
  If l > 0 Then
    Result := ActiveKeys[l -1].KeyChar
  Else
    Result := '';
  KeyLock.Leave;
End;

Procedure SP_RemoveKey(KeyCode: Word);
Var
  i, j, l: Integer;
Begin
  KeyLock.Enter;
  i := 0;
  l := Length(ActiveKeys);
  While i < l Do
    If ActiveKeys[i].KeyCode = KeyCode Then Begin
      For j := i To l -2 Do
        ActiveKeys[j] := ActiveKeys[j +1];
      Dec(l);
      SetLength(ActiveKeys, l);
    End Else
      Inc(i);
  KeyState[KeyCode] := 0;
  K_UPFLAG := True;
  KeyLock.Leave;
End;

Procedure SP_ClearAllKeys;
Var
  i: Integer;
Begin
  KeyLock.Enter;
  SetLength(ActiveKeys, 0);
  For i := 0 To High(KEYSTATE) Do
    KEYSTATE[i] := 0;
  KeyBufferPos := 0;
  KeyLock.Leave;
End;

Procedure SP_BufferKey(Key: pSP_KeyInfo; Event, Flags: Byte);
Begin
  KeyLock.Enter;
  KeyBuffer[KeyBufferPos].KeyChar := Key^.KeyChar;
  KeyBuffer[KeyBufferPos].Event := Event;
  KeyBuffer[KeyBufferPos].KeyCode := Key^.KeyCode;
  KeyBuffer[KeyBufferPos].Flags := Flags;
  Inc(KeyBufferPos);
  KeyLock.Leave;
End;

Function SP_KeyEventWaiting: Boolean;
Begin

  KeyLock.Enter;
  Result := KeyBufferPos > 0;
  KeyLock.Leave;

End;

Procedure SP_UnBufferKey;
Var
  Key: SP_KeyInfo;
  Idx: Integer;
Begin
  KeyLock.Enter;
  If KeyBufferPos > 0 Then Begin
    Case KeyBuffer[0].Event of
      0: // KeyDown
        Begin
          Key.KeyChar := KeyBuffer[0].KeyChar;
          Key.KeyCode := KeyBuffer[0].KeyCode;
          Key.Repeating := False;
          Key.NextFrameTime := FRAMES;
          SP_AddKey(Key);
        End;
      1: // KeyUp
        Begin
          SP_RemoveKey(KeyBuffer[0].KeyCode);
        End;
    End;
    Dec(KeyBufferPos);
    For Idx := 0 To KeyBufferPos Do Begin
      KeyBuffer[Idx].KeyChar := KeyBuffer[Idx +1].KeyChar;
      KeyBuffer[Idx].Event := KeyBuffer[Idx +1].Event;
      KeyBuffer[Idx].KeyCode := KeyBuffer[Idx +1].KeyCode;
      KeyBuffer[Idx].Flags := KeyBuffer[Idx +1].Flags;
    End;
  End;
  KeyLock.Leave;
End;

// Zone handling

Function  SP_NewZone(Var Error: TSP_ErrorCode): Integer;
Var
  nId, Idx: Integer;
  Found: Boolean;
Begin

  nId := 0;
  Found := False;
  Result := -1;
  While Not Found Do Begin
    For Idx := 0 To Length(SP_ZoneList) -1 Do Begin
      If SP_ZoneList[Idx].Id = nId Then Begin
        Inc(nId);
        Found := True;
        Break;
      End;
    End;
    If Not Found Then Begin
      Result := nId;
      SetLength(SP_ZoneList, Length(SP_ZoneList) +1);
      With SP_ZoneList[Length(SP_ZoneList) -1] Do Begin
        Id := Result;
        WinInfo := nil;
      End;
      Exit;
    End Else
      Found := False;
  End;

End;

Function SP_FindZone(Id: Integer; Var Error: TSP_ErrorCode): Integer;
Begin

  Error.Code := SP_ERR_OK;
  Result := Length(SP_ZoneList) -1;

  While Result > -1 Do
    If SP_ZoneList[Result].Id = Id Then
      Exit
    Else
      Dec(Result);

  Error.Code := SP_ERR_ZONE_NOT_FOUND;

End;

Procedure SP_UpdateZone(Id, Owner, x1, y1, x2, y2: Integer; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
Begin

  Idx := SP_FindZone(Id, Error);

  If Error.Code = SP_ERR_OK Then Begin

    If x1 > x2 Then Begin x1 := x1 xor x2; x2 := x1 xor x2; x1 := x1 xor x2; End;
    If y1 > y2 Then Begin y1 := y1 xor y2; y2 := y1 xor y2; y1 := y1 xor y2; End;

    SP_ZoneList[Idx].Owner := Owner;
    SP_ZoneList[Idx].x1 := x1;
    SP_ZoneList[Idx].y1 := y1;
    SP_ZoneList[Idx].x2 := x2;
    SP_ZoneList[Idx].y2 := y2;

  End;

End;

Procedure SP_UpdateZone_Coord(Id, Owner, x, y, w, h: Integer; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
Begin

  Idx := SP_FindZone(Id, Error);

  If Error.Code = SP_ERR_OK Then Begin

    If w < 0 Then Begin w := Abs(w); Dec(x, w); End;
    If h < 0 Then Begin h := Abs(h); Dec(x, h); End;

    SP_ZoneList[Idx].Owner := Owner;
    SP_ZoneList[Idx].x1 := x;
    SP_ZoneList[Idx].y1 := y;
    SP_ZoneList[Idx].x2 := x + w -1;
    SP_ZoneList[Idx].y2 := y + h -1;

  End;

End;

Procedure SP_MoveZone(Id, dX, dY: Integer; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
Begin

  Idx := SP_FindZone(Id, Error);

  If Error.Code = SP_ERR_OK Then Begin

    Inc(SP_ZoneList[Idx].x1, dx);
    Inc(SP_ZoneList[Idx].x2, dx);
    Inc(SP_ZoneList[Idx].y1, dy);
    Inc(SP_ZoneList[Idx].y2, dy);

  End;

End;

Procedure SP_MoveZoneTo(Id, dX, dY: Integer; Var Error: TSP_ErrorCode);
Var
  Idx, zW, zH: Integer;
Begin

  Idx := SP_FindZone(Id, Error);

  If Error.Code = SP_ERR_OK Then Begin

    zW := SP_ZoneList[Idx].x2 - SP_ZoneList[Idx].x1;
    zH := SP_ZoneList[Idx].y2 - SP_ZoneList[Idx].y1;

    SP_ZoneList[Idx].x1 := dx;
    SP_ZoneList[Idx].y1 := dy;

    SP_ZoneList[Idx].x2 := SP_ZoneList[Idx].x1 + zW;
    SP_ZoneList[Idx].y2 := SP_ZoneList[Idx].y1 + zH;

  End;

End;

Procedure SP_DeleteZone(Id: Integer; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
Begin

  Idx := SP_FindZone(Id, Error);
  If Error.Code = SP_ERR_OK Then Begin
    For Idx := Idx To Length(SP_ZoneList) -2 Do
      CopyMem(@SP_ZoneList[Idx].Id, @SP_ZoneList[Idx +1].Id, SizeOf(TSP_Zone));
    SetLength(SP_ZoneList, Length(SP_ZoneList) -1);
  End;

End;

Procedure SP_WindowDeleteZones(WinID: Integer);
Var
  Idx, Idx2: Integer;
Begin

  // Removes all zones associated with a window.

  Idx := Length(SP_ZoneList) -1;
  While Idx >= 0 Do Begin

    If SP_ZoneList[Idx].Owner = WinID Then Begin

      For Idx2 := Idx To Length(SP_ZoneList) -2 Do
        CopyMem(@SP_ZoneList[Idx2].Id, @SP_ZoneList[Idx +1].Id, SizeOf(TSP_Zone));
      SetLength(SP_ZoneList, Length(SP_ZoneList) -1);

    End;

    Dec(Idx);

  End;

End;

Function SP_InZone(x, y: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Idx, pX, pY, MaxOwner, sBank: Integer;
Begin

  // Iterate through each zone and test the coords supplied against the rectangle the zone inhabits.
  // Coordinates are screen orientated and are physical pixel coords rather than logical.

  // Zones are measured in their owner window's coordinates, though still pixel based.
  // All zones have to be tested - windows can overlap, and the more front-most a window is,
  // the more its zones take precedence over any that lie beneath.

  MaxOwner := -1;
  Result := -1;
  sBank := SP_FindBankID(SCREENBANK);

  For Idx := 0 To Length(SP_ZoneList) -1 Do Begin

    With SP_ZoneList[Idx] Do Begin

      If WinInfo = Nil Then
        SP_GetWindowDetails(Owner, WinInfo, Error);

      If Error.Code = SP_ERR_OK Then

        If WinInfo^.Visible Then Begin

          // Convert the screen coordinates into window coordinates
          pX := x - WinInfo^.Left;
          pY := y - WinInfo^.Top;

          // If the point is inside the zone then check - is it inside the window's visible space?

          If (pX >= x1) and (pX <= x2) and (pY >= y1) and (pY <= y2) Then

            If (pX >= 0) and (pY >= 0) and (pX < WinInfo^.Width) and (pY < WinInfo^.Height) Then Begin

              // Is the Window transparent? If so, is the pixel being pointed at opaque?

              If WinInfo^.Transparent <> $FFFF Then Begin

                If SP_BankList[sbank]^.Memory[pX + (pY * WinInfo^.Width)] <> (WinInfo^.Transparent And $FF) Then

                  If Owner > MaxOwner Then Begin
                    MaxOwner := Owner;
                    Result := SP_ZoneList[Idx].Id;
                  End;

              End Else

                If Owner > MaxOwner Then Begin
                  MaxOwner := Owner;
                  Result := SP_ZoneList[Idx].Id;
                End;

            End;

        End;

    End;

  End;

End;

initialization

  KeyLock := TCriticalSection.Create;

  VKStr[0] := 'Not Used';
  VKStr[1] := 'VK_LBUTTON';
  VKStr[2] := 'VK_RBUTTON';
  VKStr[3] := 'VK_CANCEL';
  VKStr[4] := 'VK_MBUTTON';
  VKStr[5] := 'Undefined';
  VKStr[6] := 'Undefined';
  VKStr[7] := 'Undefined';
  VKStr[8] := 'VK_BACK';
  VKStr[9] := 'VK_TAB';
  VKStr[10] := 'VK_ALTGR';
  VKStr[11] := 'Undefined';
  VKStr[12] := 'VK_CLEAR';
  VKStr[13] := 'VK_RETURN';
  VKStr[14] := 'Undefined';
  VKStr[15] := 'Undefined';
  VKStr[16] := 'VK_SHIFT';
  VKStr[17] := 'VK_CONTROL';
  VKStr[18] := 'VK_MENU';
  VKStr[19] := 'VK_PAUSE';
  VKStr[20] := 'VK_CAPITAL';
  for kbi:= 21{ $15} to 26{ $1A} do VKStr[kbi] := 'Undefined';
  VKStr[27] := 'VK_ESCAPE';
  for kbi:= 28{ $1C} to 31{ $1F} do VKStr[kbi] := 'Undefined';
  VKStr[32] := 'VK_SPACE';
  VKStr[33] := 'VK_PRIOR';
  VKStr[34] := 'VK_NEXT';
  VKStr[35] := 'VK_END';
  VKStr[36] := 'VK_HOME';
  VKStr[37] := 'VK_LEFT';
  VKStr[38] := 'VK_UP';
  VKStr[39] := 'VK_RIGHT';
  VKStr[40] := 'VK_DOWN';
  VKStr[41] := 'VK_SELECT';
  VKStr[42] := 'VK_PRINT';
  VKStr[43] := 'VK_EXECUTE';
  VKStr[44] := 'VK_SNAPSHOT';
  VKStr[45] := 'VK_INSERT';
  VKStr[46] := 'VK_DELETE';
  VKStr[47] := 'VK_HELP';
  VKStr[48] := 'VK_0';
  VKStr[49] := 'VK_1';
  VKStr[50] := 'VK_2';
  VKStr[51] := 'VK_3';
  VKStr[52] := 'VK_4';
  VKStr[53] := 'VK_5';
  VKStr[54] := 'VK_6';
  VKStr[55] := 'VK_7';
  VKStr[56] := 'VK_8';
  VKStr[57] := 'VK_9';
  for kbi:= 56{ $3A} to 64{ $40} do VKStr[kbi] := 'Undefined';
  VKStr[65] := 'VK_A';
  VKStr[66] := 'VK_B';
  VKStr[67] := 'VK_C';
  VKStr[68] := 'VK_D';
  VKStr[69] := 'VK_E';
  VKStr[70] := 'VK_F';
  VKStr[71] := 'VK_G';
  VKStr[72] := 'VK_H';
  VKStr[73] := 'VK_I';
  VKStr[74] := 'VK_J';
  VKStr[75] := 'VK_K';
  VKStr[76] := 'VK_L';
  VKStr[77] := 'VK_M';
  VKStr[78] := 'VK_N';
  VKStr[79] := 'VK_O';
  VKStr[80] := 'VK_P';
  VKStr[81] := 'VK_Q';
  VKStr[82] := 'VK_R';
  VKStr[83] := 'VK_S';
  VKStr[84] := 'VK_T';
  VKStr[85] := 'VK_U';
  VKStr[86] := 'VK_V';
  VKStr[87] := 'VK_W';
  VKStr[88] := 'VK_X';
  VKStr[89] := 'VK_Y';
  VKStr[90] := 'VK_Z';
  VKStr[91] := 'VK_LWIN';
  VKStr[92] := 'VK_RWIN';
  VKStr[93] := 'VK_APPS';
  VKStr[94] := 'Undefined';
  VKStr[95] := 'Undefined';
  VKStr[96] := 'VK_NUMPAD0';
  VKStr[97] := 'VK_NUMPAD1';
  VKStr[98] := 'VK_NUMPAD2';
  VKStr[99] := 'VK_NUMPAD3';
  VKStr[100] := 'VK_NUMPAD4';
  VKStr[101] := 'VK_NUMPAD5';
  VKStr[102] := 'VK_NUMPAD6';
  VKStr[103] := 'VK_NUMPAD7';
  VKStr[104] := 'VK_NUMPAD8';
  VKStr[105] := 'VK_NUMPAD9';
  VKStr[106] := 'VK_MULTIPLY';
  VKStr[107] := 'VK_ADD';
  VKStr[108] := 'VK_SEPARATOR';
  VKStr[109] := 'VK_SUBTRACT';
  VKStr[110] := 'VK_DECIMAL';
  VKStr[111] := 'VK_DIVIDE';
  VKStr[112] := 'VK_F1';
  VKStr[113] := 'VK_F2';
  VKStr[114] := 'VK_F3';
  VKStr[115] := 'VK_F4';
  VKStr[116] := 'VK_F5';
  VKStr[117] := 'VK_F6';
  VKStr[118] := 'VK_F7';
  VKStr[119] := 'VK_F8';
  VKStr[120] := 'VK_F9';
  VKStr[121] := 'VK_F10';
  VKStr[122] := 'VK_F11';
  VKStr[123] := 'VK_F12';
  VKStr[124] := 'VK_F13';
  VKStr[125] := 'VK_F14';
  VKStr[126] := 'VK_F15';
  VKStr[127] := 'VK_F16';
  VKStr[128] := 'VK_F17';
  VKStr[129] := 'VK_F18';
  VKStr[130] := 'VK_F19';
  VKStr[131] := 'VK_F20';
  VKStr[132] := 'VK_F21';
  VKStr[133] := 'VK_F22';
  VKStr[134] := 'VK_F23';
  VKStr[135] := 'VK_F24';
  for kbi:= 136{ $88} to 143{ $8F} do VKStr[kbi] := 'Unassigned';
  VKStr[144] := 'VK_NUMLOCK';
  VKStr[145] := 'VK_SCROLL';
  for kbi:= 146{ $92} to 185{ $B9} do VKStr[kbi] := 'Unassigned';
  VKStr[186] := 'VK_OEM_1';      // ;:
  VKStr[187] := 'VK_OEM_PLUS';   // =+
  VKStr[188] := 'VK_OEM_COMMA';  // ,<
  VKStr[189] := 'VK_OEM_MINUS';  // -_
  VKStr[190] := 'VK_OEM_PERIOD'; // .>
  VKStr[191] := 'VK_OEM_2';    // /?
  VKStr[192] := 'VK_OEM_3';    // '@
  for kbi:= 193{ $C1} to 218{ $DA} do VKStr[kbi] := 'Unassigned';
  VKStr[219] := 'VK_OEM_4';     // [{
  VKStr[220] := 'VK_OEM_5';     // \|
  VKStr[221] := 'VK_OEM_6';     // ]}
  VKStr[222] := 'VK_OEM_7';     // #~
  VKStr[223] := 'VK_OEM_8';     // `¬
  VKStr[224] := 'VK_F17';       // on Olivetti extended keyboard
  VKStr[225] := 'VK_OEM_AX';
  VKStr[226] := 'VK_OEM_102';
  VKStr[227] := 'VK_ICO_HELP';  // on Olivetti extended keyboard
  VKStr[228] := 'VK_ICO_00';    // on Olivetti extended keyboard
  VKStr[229] := 'VK_PROCESSKEY';
  VKStr[230] := 'VK_ICO_CLEAR'; // on Olivetti extended keyboard
  VKStr[231] := 'Unassigned';
  VKStr[232] := 'Unassigned';
  VKStr[233] := 'VK_OEM_RESET';   // only used by Nokia
  VKStr[234] := 'VK_OEM_JUMP';    // only used by Nokia
  VKStr[235] := 'VK_OEM_PA1';     // only used by Nokia
  VKStr[236] := 'VK_OEM_PA2';     // only used by Nokia
  VKStr[237] := 'VK_OEM_PA3';     // only used by Nokia
  VKStr[238] := 'VK_OEM_WSCTRL';  // only used by Nokia
  VKStr[239] := 'VK_OEM_CUSEL';   // only used by Nokia
  VKStr[240] := 'VK_OEM_ATTN';    // only used by Nokia
  VKStr[241] := 'VK_OEM_FINNISH'; // only used by Nokia
  VKStr[242] := 'VK_OEM_COPY';    // only used by Nokia
  VKStr[243] := 'VK_OEM_AUTO';    // only used by Nokia
  VKStr[244] := 'VK_OEM_ENLW';    // only used by Nokia
  VKStr[245] := 'VK_OEM_BACKTAB'; // only used by Nokia
  VKStr[246] := 'VK_ATTN';
  VKStr[247] := 'VK_CRSEL';
  VKStr[248] := 'VK_EXSEL';
  VKStr[249] := 'VK_EREOF';
  VKStr[250] := 'VK_PLAY';
  VKStr[251] := 'VK_ZOOM';
  VKStr[252] := 'VK_NONAME';
  VKStr[253] := 'VK_PA1';
  VKStr[254] := 'VK_OEM_CLEAR';
  VKStr[255] := 'Not Used';

  // Conversion keys for a british keyboard.
  // May be made into a loadable file later for international keyboards

  For global_i := 0 To High(CharStr) Do
    CharStr[KeyBufferPos] := #0#0;

  CharStr[32] := '  ';
  CharStr[48] := '0)';
  CharStr[49] := '1!';
  CharStr[50] := '2"';
  CharStr[51] := '3'#96;
  CharStr[52] := '4$';
  CharStr[53] := '5%';
  CharStr[54] := '6^';
  CharStr[55] := '7&';
  CharStr[56] := '8*';
  CharStr[57] := '9(';
  CharStr[65] := 'aA';
  CharStr[66] := 'bB';
  CharStr[67] := 'cC';
  CharStr[68] := 'dD';
  CharStr[69] := 'eE';
  CharStr[70] := 'fF';
  CharStr[71] := 'gG';
  CharStr[72] := 'hH';
  CharStr[73] := 'iI';
  CharStr[74] := 'jJ';
  CharStr[75] := 'kK';
  CharStr[76] := 'lL';
  CharStr[77] := 'mM';
  CharStr[78] := 'nN';
  CharStr[79] := 'oO';
  CharStr[80] := 'pP';
  CharStr[81] := 'qQ';
  CharStr[82] := 'rR';
  CharStr[83] := 'sS';
  CharStr[84] := 'tT';
  CharStr[85] := 'uU';
  CharStr[86] := 'vV';
  CharStr[87] := 'wW';
  CharStr[88] := 'xX';
  CharStr[89] := 'yY';
  CharStr[90] := 'zZ';
  CharStr[96] := '00';
  CharStr[97] := '11';
  CharStr[98] := '22';
  CharStr[99] := '33';
  CharStr[100] := '44';
  CharStr[101] := '55';
  CharStr[102] := '66';
  CharStr[103] := '77';
  CharStr[104] := '88';
  CharStr[105] := '99';
  CharStr[106] := '**';
  CharStr[107] := '++';
  CharStr[108] := '||';
  CharStr[109] := '--';
  CharStr[110] := '..';
  CharStr[111] := '//';
  CharStr[186] := ';:';
  CharStr[187] := '=+';
  CharStr[188] := ',<';
  CharStr[189] := '-_';
  CharStr[190] := '.>';
  CharStr[191] := '/?';
  CharStr[192] := #39'@';
  CharStr[219] := '[{';
  CharStr[220] := '\|';
  CharStr[221] := ']}';
  CharStr[222] := '#~';

Finalization

  KeyLock.Free;

end.
