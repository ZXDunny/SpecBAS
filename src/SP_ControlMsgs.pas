unit SP_ControlMsgs;

interface

USes SyncObjs, SP_Util;

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

Var

  ControlMsgLock: TCriticalSection;
  ControlMsgList: Array of SP_ControlMsg;

implementation

Uses

  SP_FPEditor, SP_Errors, SP_Input, SP_SysVars;

Procedure ProcessNextControlMsg;
Var
  c: aChar;
  i: Integer;
  lk: Byte;
  Error: TSP_ErrorCode;
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
              c := Data[i];
              If (c >= 'a') And (c <= 'z') Then
                lk := 0
              Else
                lk := Ord(c);
              SP_BufferKey(Ord(c), 0, lk);
            End;
            For i := Length(Data) DownTo 1 Do Begin
              c := Data[i];
              If (c >= 'a') And (c <= 'z') Then
                lk := 0
              Else
                lk := Ord(c);
              SP_BufferKey(Ord(c), 1, lk);
            End;
          End;
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
