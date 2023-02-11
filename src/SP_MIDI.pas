unit SP_MIDI;

interface

Uses Windows, MMSystem, SyncObjs, SysUtils;

Procedure OpenMIDI;
Procedure SendMIDIBytes(Bytes: Array of Byte);
Procedure CloseMIDI;


var
  MidiHandle: HMIDIOUT; //global handle to midi device
  MidiOpen: boolean = False; //refer to this variable to see if a midi device is currently open

  MIDILock: TCriticalSection;

implementation

Procedure OpenMIDI;
Var
  Res: Integer;
Begin

  MIDILock.Enter;

  If Not MIDIOpen Then Begin
    MidiOpen := False;
    If midiOutGetNumDevs > 0 Then Begin
      Res := midiOutOpen(@MidiHandle, MIDI_MAPPER, 0, 0, CALLBACK_NULL);
      if Res = MMSYSERR_NOERROR Then
        MidiOpen := True;
    End;
  End;

  MIDILock.Leave;

End;

Procedure CloseMIDI;
Begin

  MIDILock.Enter;

  If midiOpen Then Begin
    midiOutClose(MidiHandle);
    MidiOpen:=false;
  End;

  MIDILock.Leave;

End;

Procedure SendMIDIBytes(Bytes: Array of Byte);
Begin

  If MIDIOpen Then Begin

    MIDILock.Enter;

    If MidiOpen Then
      MidiOutShortMsg(MIDIHandle, pLongWord(@Bytes[0])^);

    MIDILock.Leave;

  End;

End;

Initialization

  MIDILock := TCriticalSection.Create;

Finalization

  MIDILock.Free;

end.



