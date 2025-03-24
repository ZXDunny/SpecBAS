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

  SP_Compiler, SP_FPEditor, SP_Errors, SP_Input, SP_SysVars, SP_DebugPanel;

Procedure ProcessNextControlMsg;
Var
  i: Integer;
  Bp: pSP_BreakPointInfo;
  p: NativeUInt;
  key: SP_KeyInfo;
  s: aString;
Begin

  ControlMsgLock.Enter;

  While Length(ControlMsgList) > 0 Do Begin

    Case ControlMsgList[0].ID of

      clInterpretCommand:
        Begin
          s := ControlMsgList[0].Data;
          DeleteControlMsg(0);
          ControlMsgLock.Leave;
          if s <> '' Then SP_FPExecuteEditLine(s);
          ControlMsgLock.Enter;
        End;

      clKeyPress:
        Begin
          With ControlMsgList[0] Do Begin
            For i := 1 To Length(Data) Do Begin
              Key.KeyChar := Data[i];
              Key.IsKey := True;
              If (Key.KeyChar >= 'A') And (Key.KeyChar <= 'Z') Then Begin
                Key.KeyChar := Lower(Key.KeyChar)[1];
                Key.KeyCode := Ord(Key.KeyChar);
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
                Key.KeyCode := Ord(Key.KeyChar);
              End Else Begin
                Key.KeyCode := Ord(Key.KeyChar);
                Key.KeyChar := #0;
              End;
              SP_BufferKey(@Key, 1, KF_NOCLICK);
            End;
          End;
          DeleteControlMsg(0);
        End;

      clBPEdit:
        Begin
          i := pLongWord(@ControlMsgList[0].Data[1])^;
          p := pNativeUInt(@ControlMsgList[0].Data[SizeOf(LongWord) +1])^;
          BP := pSP_BreakPointInfo(pNativeUInt(p));
          StartBPEditOp(i, Bp);
          DeleteControlMsg(0);
        End;

      clEditWatch:
        Begin
          i := pLongWord(@ControlMsgList[0].Data[1])^;
          StartWatchOp(i);
          DeleteControlMsg(0);
        End;

      clGrabberMouseDown:
        Begin
          SP_StopCompiler;
          FPDebugLastMouseX := Integer(pLongWord(@ControlMsgList[0].Data[1])^);
          FPResizingDebugPanel := True;
          DeleteControlMsg(0);
        End;

      clGrabberMouseMove:
        Begin
          If FPResizingDebugPanel Then
            SP_ResizeDebugPanel(Integer(pLongWord(@ControlMsgList[0].Data[1])^));
          DeleteControlMsg(0);
        End;

      clGrabberMouseUp:
        Begin
          FPResizingDebugPanel := False;
          SetAllToCompile;
          SP_StartCompiler;
          DeleteControlMsg(0);
        End;

    End;

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
