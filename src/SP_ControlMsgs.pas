unit SP_ControlMsgs;

interface

USes SyncObjs, SP_Interpret_PostFix, SP_Util;

Type

  SP_ControlMsg = Record
    ID: Integer;
    Data: aString;
  End;

Procedure ProcessNextControlMsg;
Procedure AddControlMsg(MsgID: Integer; Const MsgData: aString);
Procedure DeleteControlMsg(Index: Integer);

Const

  clInterpretCommand = 1;
  clKeyPress         = 2;
  clBPEdit           = 3;
  clEditWatch        = 4;
  clGrabberMouseDown = 5;
  clGrabberMouseMove = 6;
  clGrabberMouseUp   = 7;

Var

  ControlMsgLock: TCriticalSection;
  ControlMsgList: Array of SP_ControlMsg;

implementation

Uses

  SP_FPEditor, SP_Errors, SP_Input, SP_SysVars, SP_DebugPanel;

Procedure ProcessNextControlMsg;
Var
  i: Integer;
  Error: TSP_ErrorCode;
  Bp: pSP_BreakPointInfo;
  p: NativeUInt;
  key: SP_KeyInfo;
  c: aChar; kc: Word;
Begin

  ControlMsgLock.Enter;

  While Length(ControlMsgList) > 0 Do Begin

    Case ControlMsgList[0].ID of

      clInterpretCommand:
        Begin
          SP_FPExecuteEditLine(ControlMsgList[0].Data);
        End;

      clKeyPress:
        Begin
          With ControlMsgList[0] Do Begin
            For i := 1 To Length(Data) Do Begin
              Key.KeyChar := Data[i];
              If (Key.KeyChar >= 'A') And (Key.KeyChar <= 'Z') Then Begin
                Key.KeyChar := Lower(Key.KeyChar)[1];
                Key.KeyCode := 0
              End Else Begin
                Key.KeyCode := Ord(Key.KeyChar);
                Key.KeyChar := #0;
              End;
              SP_BufferKey(@Key, 0, KF_NOCLICK);
            End;
            For i := Length(Data) DownTo 1 Do Begin
              Key.KeyChar := Data[i];
              If (Key.KeyChar >= 'A') And (Key.KeyChar <= 'Z') Then Begin
                Key.KeyChar := Lower(Key.KeyChar)[1];
                Key.KeyCode := 0
              End Else Begin
                Key.KeyCode := Ord(Key.KeyChar);
                Key.KeyChar := #0;
              End;
              SP_BufferKey(@Key, 1, KF_NOCLICK);
            End;
          End;
        End;

      clBPEdit:
        Begin
          i := pLongWord(@ControlMsgList[0].Data[1])^;
          p := pNativeUInt(@ControlMsgList[0].Data[SizeOf(LongWord) +1])^;
          BP := pSP_BreakPointInfo(pNativeUInt(p));
          StartBPEditOp(i, Bp);
        End;

      clEditWatch:
        Begin
          i := pLongWord(@ControlMsgList[0].Data[1])^;
          StartWatchOp(i);
        End;

      clGrabberMouseDown:
        Begin
          FPDebugLastMouseX := Integer(pLongWord(@ControlMsgList[0].Data[1])^);
          FPResizingDebugPanel := True;
        End;

      clGrabberMouseMove:
        Begin
          If FPResizingDebugPanel Then
            SP_ResizeDebugPanel(Integer(pLongWord(@ControlMsgList[0].Data[1])^));
        End;

      clGrabberMouseUp:
        Begin
          FPResizingDebugPanel := False;
        End;

    End;
    DeleteControlMsg(0);

  End;

  ControlMsgLock.Leave;

End;

Procedure AddControlMsg(MsgID: Integer; Const MsgData: aString);
Var
  l: Integer;
Begin

  ControlMsgLock.Enter;

  l := Length(ControlMsgList);
  SetLength(ControlMsgList, l +1);
  ControlMsgList[l].ID := MsgID;
  ControlMsgList[l].Data := MsgData;

  ControlMsgLock.Leave;

End;

Procedure DeleteControlMsg(Index: Integer);
Var
  i, l: Integer;
Begin

  ControlMsgLock.Enter;

  l := Length(ControlMsgList);
  For i := Index to l -2 Do
    ControlMsgList[i] := ControlMsgList[i +1];
  SetLength(ControlMsgList, l -1);

  ControlMsgLock.Leave;

End;

initialization

  ControlMsgLock := TCriticalSection.Create;

finalization

  ControlMsgLock.Free;

end.
