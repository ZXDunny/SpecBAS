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

unit SP_Sound;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}

interface

Uses Classes, SyncObjs, SP_BankManager, SP_BankFiling, SP_FileIO, SP_Errors, SP_Util, SP_SysVars, SP_Package, SP_Input, SP_Samples, Bass, SysUtils, Math;

Type

  TMonitorItem = Record
    ChannelID: HCHANNEL;
    SampleID: HSAMPLE;
  End;

  TChannelMonitor = Class(TThread)
    ChanLock: TCriticalSection;
    ChanList: Array of TMonitorItem;
    Procedure Execute; Override;
    Procedure AddChannel(Channel: HCHANNEL; Sample: HSAMPLE);
  End;

  TPLAYMessage = Record
    ID: Integer;        // Intended channel's ID
    Msg: Integer;       // Message - currently 0:Tempo change 1:Halt
    Data: Integer;      // payload
    TimeStamp: aFloat;  // Timestamp from CB_GETTICKS
  End;

  TPLAYThread = Class(TThread)
    CurTempo: Integer;
    PLAYStr: aString;
    SessionID, ChanID: Integer;
    ErrorCode: pInteger;
    PoolIndex: Integer;
    Halted, IsASync, Playing: Boolean;
    Ticks: aFloat;
    Procedure Execute; Override;
    Procedure SP_PLAY(Str: aString; SessionID: Integer; ASync: Boolean; Var Error: pSP_ErrorCode);
    Procedure CheckMessages;
  End;

Procedure SP_Init_Sound;
Procedure SP_Stop_Sound;
Procedure SP_SetGlobalVolume(sVolume: aFloat; Var Error: TSP_ErrorCode);
Function  SP_GetGlobalVolume: aFloat;
Procedure SP_MakeSystemSounds;

Function  SP_Sample_Create(Rate, Bits, Stereo, Size: Integer; Var Error: TSP_ErrorCode): Integer;
Procedure SP_Sample_Reallocate(BankID: Integer);
Procedure SP_Sample_Delete(BankID: Integer; Var Error: TSP_ErrorCode);
Procedure SP_Sample_Load(BankID: Integer; Filename: aString; Var Error: TSP_ErrorCode);
Procedure SP_Sample_Rate(BankID: Integer; sRate: LongWord; Var Error: TSP_ErrorCode);
Procedure SP_Sample_Bits(BankID: Integer; sBits: LongWord; Var Error: TSP_ErrorCode);
Procedure SP_Sample_Volume(BankID: Integer; sVolume: aFloat; Var Error: TSP_ErrorCode);
Procedure SP_Sample_Panning(BankID: Integer; sPan: aFloat; Var Error: TSP_ErrorCode);
Procedure SP_Sample_Stereo(BankID: Integer; sStereo: LongWord; Var Error: TSP_ErrorCode);
Function  SP_Sample_Play(BankID: Integer; Rate: aFloat; RateStr: aString; Loops, Volume, Panning: aFloat; Var Error: TSP_ErrorCode): LongWord;
Procedure SP_UpdateSampleSize(Bank: pSP_Bank);

Procedure SP_Channel_Stop(ChannelID: LongWord; Var Error: TSP_ErrorCode);
Procedure SP_Channel_Pause(ChannelID: LongWord; Var Error: TSP_ErrorCode);
Procedure SP_Channel_Resume(ChannelID: LongWord; Var Error: TSP_ErrorCode);
Procedure SP_Channel_Rate(ChannelID: LongWord; Rate: Integer; RateStr: aString; Var Error: TSP_ErrorCode);
Procedure SP_Channel_Volume(ChannelID: LongWord; Volume: aFloat; Var Error: TSP_ErrorCode);
Procedure SP_Channel_Pan(ChannelID: LongWord; Pan: aFloat; Var Error: TSP_ErrorCode);
Procedure SP_Channel_Seek(ChannelID, Seek: LongWord; Var Error: TSP_ErrorCode);
Function  SP_GetChannelPos(ChannelID: LongWord; Var Error: TSP_ErrorCode): LongWord;

Procedure SP_Music_Play(Filename: aString; Volume: aFloat; Pause, Loop: Integer; Var Error: TSP_ErrorCode);
Procedure SP_Music_Play_Bank(BankID: Integer; Volume: aFloat; Pause, Loop: Integer; Var Error: TSP_ErrorCode);
Procedure SP_Music_Stop(Var Error: TSP_ErrorCode);
Procedure SP_Music_Pause(Var Error: TSP_ErrorCode);
Procedure SP_Music_Resume(Var Error: TSP_ErrorCode);
Procedure SP_Music_Seek(SeekTo: aFloat; Var Error: TSP_ErrorCode);
Procedure SP_Music_Volume(Volume: aFloat; Var Error: TSP_ErrorCode);
Function  SP_GetMusicPos(Var Error: TSP_ErrorCode): aFloat;
Function  SP_GetMusicLen(Var Error: TSP_ErrorCode): aFloat;

Procedure SP_PlaySystem(Var Channel: LongWord; BankID: Integer);
Procedure SP_PlaySignature;

Function  SP_StringToSemiTones(Str: aString; Var Error: TSP_ErrorCode): aFloat;
Function  SP_SemiTonesToHz(SemiTone: aFloat): aFloat;
Procedure SP_MakeBEEP(Duration, Pitch: aFloat; WaveType: Integer; Attack, Decay, Sustain, Release, Noise, Roughness: aFloat; Async: Boolean; Error: TSP_ErrorCode);

Procedure SP_PLAY(PLAYStrs: Array of aString; Var ErrorCode: Integer);
Procedure SP_PLAY_ASync(PLAYStrs: Array of aString);
Procedure AddPLAYThread(Const Str: aString; ID, Tempo: Integer; aTime: aFloat; ASync: Boolean; Error: pInteger);
Procedure DeletePLAYThread(Index: Integer);
Procedure PLAYTempoChange(ID: Integer; NewTempo: Integer);
Procedure PLAYSignalHalt(ID: Integer);
Function  PLAYSessionIsActive(ID: Integer): Boolean;
Function  GetTempoInformation(Str: aString; Default: Integer): Integer;
Procedure SendPLAYMessage(ChanID, Action, Payload: Integer);
Procedure DeletePLAYMessage(index: Integer);
Procedure DeletePLAYMessages(ChanID: integer);

Var

  BEEPMonitor: TChannelMonitor;
  CurSessionID: Integer = 0;
  CurChanID: Integer = 0;

  PLAYMsgs: Array of TPLAYMessage;
  PLAYPool: Array of TPLAYThread;
  PLAYLock: TCriticalSection;

Const

  PLAYMSG_TEMPO = 0;
  PLAYMSG_HALT = 1;

implementation

Uses SP_Main, SP_Graphics;

Procedure TChannelMonitor.Execute;
Var
  i, j, l: Integer;
Begin

  Priority := TPIdle;
  FreeOnTerminate := True;
  NameThreadForDebugging('BEEP Monitor');

  ChanLock := TCriticalSection.Create;

  While Not Terminated Do Begin

    If ChanLock.TryEnter Then Begin

      i := 0;
      l := Length(ChanList);
      if l > 0 Then Begin
        Priority := tpNormal;
        While i < l Do Begin
          if Not (BASS_ChannelIsActive(ChanList[i].ChannelID) = BASS_ACTIVE_PLAYING) Then Begin
            BASS_SampleFree(ChanList[i].SampleID);
            For j := i To l -2 Do
              ChanList[j] := ChanList[j + 1];
            SetLength(ChanList, l -1);
            Dec(l);
          End Else
            Inc(i);
        End;
      End Else
        Priority := tpIdle;

      ChanLock.Leave;

    End;

    Sleep(1);

  End;

  ChanLock.Free;

End;

Procedure TChannelMonitor.AddChannel(Channel: HCHANNEL; Sample: HSAMPLE);
Var
  l: Integer;
Begin

  ChanLock.Enter;

  l := Length(ChanList);
  SetLength(ChanList, l +1);
  With ChanList[l] Do Begin
    ChannelID := Channel;
    SampleID := Sample;
  End;

  ChanLock.Leave;

End;

Procedure SP_Init_Sound;
Var
  Info: BASS_INFO;
  BASS_Err: Integer;
  Error: TSP_ErrorCode;
Begin

  // Initialise BASS.

  BASS_SetConfig(BASS_CONFIG_DEV_DEFAULT, 1);

  {$IFDEF LINUX}
  BASS_Init(-1, 44100, 0, 0, 0);
  {$ELSE}
  BASS_Init(-1, 44100, 0, 0, nil);
  {$ENDIF}

  BASS_Err := BASS_ErrorGetCode;
  If BASS_Err = 0 Then Begin

    BASS_GetInfo(Info);
    MAXRATE := Info.maxrate;
    MINRATE := Info.minrate;

    If MAXRATE = 0 Then MAXRATE := 256000;
    If MINRATE = 0 Then MINRATE := 1024;
    If MAXRATE = MINRATE Then MINRATE := 1024;

  End;

  SP_SetGlobalVolume(1.0, Error);
  VOLUME := 1.0;
  CLICKVOL := 0.5;

End;

Procedure SP_Stop_Sound;
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sample_Info: pSP_Sample_Info;
Begin

  // Stops all playing samples

  For Idx := 0 To Length(SP_BankList) -1 Do Begin

    Bank := SP_Banklist[Idx];
    If Bank^.DataType = SP_SAMPLE_BANK Then Begin

      Sample_Info := @Bank^.Info[0];
      BASS_SampleStop(Sample_Info^.Sample);

    End;

  End;

  // Stop the music

  If MUSICHANDLE <> 0 Then
    BASS_ChannelPause(MUSICHANDLE);

  // Release the channels for the keyclicks

  CLICKCHAN := 0;
  ERRORCHAN := 0;
  OKCHAN := 0;

  // Stop all PLAY channels

  PLAYSignalHalt(-1);

End;

Function AYLogVolume(v: aFloat): aFloat;
Begin
  // This, believe it or not, almost perfectly matches voltages from a real AY
  // See: https://groups.google.com/g/comp.sys.sinclair/c/-zCR2kxMryY/m/Ym2WVcS2PGwJ
  Result := Power((v * v * v), 0.95-(v/110));
End;

Procedure SP_SetGlobalVolume(sVolume: aFloat; Var Error: TSP_ErrorCode);
Var
  logVol: aFloat;
Begin

  If (sVolume < 0) or (sVolume > 1) Then
    Error.Code := SP_ERR_VOLUME_OUT_OF_RANGE
  Else Begin
    logVol := AYLogVolume(sVolume);
    BASS_SetConfig(BASS_CONFIG_GVOL_MUSIC, Round(logVol * 10000));
    BASS_SetConfig(BASS_CONFIG_GVOL_SAMPLE, Round(logVol * 10000));
    BASS_SetConfig(BASS_CONFIG_GVOL_STREAM, Round(logVol * 10000));
    VOLUME := sVolume;
    BASS_ChannelStop(CLICKCHAN);
    BASS_ChannelStop(ERRORCHAN);
    BASS_ChannelStop(OKCHAN);
    CLICKCHAN := 0;
    ERRORCHAN := 0;
    OKCHAN := 0;
  End;

End;

Function SP_GetGlobalVolume: aFloat;
Begin

  Result := VOLUME;

End;

Procedure SP_MakeSystemSounds;
Var
  Bank: pSP_Bank;
  Error: TSP_ErrorCode;
  Idx, Rpt, sPos: Integer;
Begin

  If CLICKBANK > 0 Then Begin
    Idx := SP_FindBankID(CLICKBANK);
    SP_BankList[Idx]^.Protection := False;
    SP_DeleteBank(Idx, Error);
  End;
  If OKSNDBANK > 0 Then Begin
    Idx := SP_FindBankID(OKSNDBANK);
    If Idx > -1 Then Begin
      SP_BankList[Idx]^.Protection := False;
      SP_DeleteBank(Idx, Error);
    End;
  End;
  If ERRSNDBANK > 0 Then Begin
    Idx := SP_FindBankID(ERRSNDBANK);
    If Idx > -1 Then Begin
      SP_BankList[Idx]^.Protection := False;
      SP_DeleteBank(Idx, Error);
    End;
  End;

  // Create three sample banks - keyclick, error and OK sounds.

  CLICKBANK := SP_Sample_Create(44100, 16, 2, 1200, Error);

  Bank := SP_BankList[SP_FindBankID(CLICKBANK)];
  Bank^.Protection := True;
  Bank^.System := True;
  For Idx := 0 To (Length(Bank^.Memory) Div 2) -1 Do
    If Idx < 25 Then Begin
      pWord(@Bank^.Memory[Idx * 2])^ := 32767;
    End Else
      pWord(@Bank^.Memory[Idx * 2])^ := 0;

  OKSNDBANK := SP_Sample_Create(44100, 16, 2, 60 * 80 * 2 * 2 * 2, Error);
  Bank := SP_BankList[SP_FindBankID(OKSNDBANK)];
  Bank^.Protection := True;
  Bank^.System := True;
  sPos := 0;
  For Rpt := 0 To 59 Do Begin
    For Idx := 0 To 79 Do Begin
      pWord(@Bank^.Memory[sPos])^ := 16383;
      Inc(sPos, 2);
    End;
    For Idx := 0 To 79 Do Begin
      pWord(@Bank^.Memory[sPos])^ := 0;
      Inc(sPos, 2);
    End;
  End;

  ERRSNDBANK := SP_Sample_Create(44100, 16, 2, 31 * 326 * 2 * 2 * 2, Error);
  Bank := SP_BankList[SP_FindBankID(ERRSNDBANK)];
  Bank^.Protection := True;
  Bank^.System := True;
  sPos := 0;
  For Rpt := 0 To 30 Do Begin
    For Idx := 0 To 325 Do Begin
      pWord(@Bank^.Memory[sPos])^ := 16383;
      Inc(sPos, 2);
    End;
    For Idx := 0 To 325 Do Begin
      pWord(@Bank^.Memory[sPos])^ := 0;
      Inc(sPos, 2);
    End;
  End;

  CLICKCHAN := 0;
  ERRORCHAN := 0;
  OKCHAN    := 0;

End;

Procedure SP_PlaySignature;
Var
  Error: TSP_ErrorCode;
  sPtr, dPtr: pByte;
  Idx: Integer;
  Val, oVal: Byte;
Begin

  If SIGSAMPLEBANK = -1 Then Begin
    SIGSAMPLEBANK := SP_Sample_Create(44100, 8, 0, Length(LoadingTones) Div 2, Error);
    dPtr := @SP_BankList[SP_FindBankID(SIGSAMPLEBANK)]^.Memory[0];
    sPtr := @LoadingTones[1];
    oVal := 0;
    For Idx := 1 To Length(LoadingTones) Div 2 Do Begin
      If sPtr^ in [48..57] Then
        Val := sPtr^ - 48
      Else
        Val := 10 + sPtr^ - 65;
      Inc(sPtr);
      If sPtr^ in [48..57] Then
        Val := (Val Shl 4) + sPtr^ - 48
      Else
        Val := (Val Shl 4) + 10 + sPtr^ - 65;
      Inc(sPtr);
      dPtr^ := Round((Val + oVal)/2);
      oVal := Val;
      Inc(dPtr);
    End;
    SP_Sample_Play(SIGSAMPLEBANK, -1, '', 0, CLICKVOL, -9, Error);
  End;

End;

Procedure SP_UpdateSampleSize(Bank: pSP_Bank);
Var
  Sample_Info: pSP_Sample_Info;
Begin

  Sample_Info := @Bank^.Info[0];
  Sample_Info.Size := Length(Bank^.Memory);
  Bank^.Changed := True;

End;

Procedure SP_Sample_Reallocate(BankID: Integer);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sample_Info: pSP_Sample_Info;
  Flags: LongWord;
  Sample: BASS_SAMPLE;
Begin

  Idx := SP_FindBankID(BankID);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    Sample_Info := @Bank^.Info[0];

    If Sample_Info.Bits = 8 Then
      Flags := BASS_SAMPLE_8BITS or BASS_SAMPLE_OVER_VOL
    Else
      Flags := BASS_SAMPLE_OVER_VOL;

    Sample_Info^.Sample := BASS_SampleCreate(Sample_Info.Size, Sample_Info.Rate, Sample_Info^.Channels, 128, Flags);
    BASS_SampleGetInfo(Sample_info^.Sample, Sample);
    Sample.origres := Sample_Info.Bits;
    Sample.volume := Sample_Info.Volume;
    Sample.pan := Sample_Info.Panning;
    BASS_SampleSetInfo(Sample_Info^.Sample, Sample);
    BASS_SampleSetData(Sample_Info^.Sample, @Bank^.Memory[0]);
    Bank^.Changed := False;

  End;

End;

Function  SP_Sample_Create(Rate, Bits, Stereo, Size: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Bank: pSP_Bank;
  Sample_Info: pSP_Sample_Info;
  Flags: LongWord;
  Sample: BASS_SAMPLE;
Begin

  Result := -1;

  // Create a sample of the specified rate, bits and channels (stereo = 2, mono = 1).

  If {(Rate >= integer(MINRATE)) and (Rate <= integer(MAXRATE)) And} ((Bits = 8) or (Bits = 16)) Then Begin

    Result := SP_NewBank(Size);
    Bank := SP_BankList[SP_FindBankID(Result)];
    SetLength(Bank^.Info, SizeOf(SP_Sample_Info));
    Bank^.InfoLength := SizeOf(SP_Sample_Info);
    Sample_Info := @Bank^.Info[0];
    Bank^.DataType := SP_SAMPLE_BANK;

    Sample_Info^.Size := Size;
    Sample_Info^.Rate := Rate;
    Sample_Info^.Bits := Bits;
    If Stereo > 1 Then
      Sample_Info^.Channels := 2
    Else
      Sample_Info^.Channels := 1;
    Sample_Info^.Volume := 1;
    Sample_Info^.Panning := 0;

    If Bits = 8 Then
      Flags := BASS_SAMPLE_8BITS or BASS_SAMPLE_OVER_VOL
    Else
      Flags := BASS_SAMPLE_OVER_VOL;

    Sample_Info^.Sample := BASS_SampleCreate(Size, Rate, Sample_Info^.Channels, 128, Flags);
    BASS_SampleGetInfo(Sample_info^.Sample, Sample);
    Sample.origres := Bits;
    BASS_SampleSetInfo(Sample_Info^.Sample, Sample);

  End Else

    Error.Code := SP_ERR_RATE_OUT_OF_RANGE;

End;

Procedure SP_Sample_Load(BankID: Integer; Filename: aString; Var Error: TSP_ErrorCode);
Var
  Idx, BASS_Err: Integer;
  Bank: pSP_Bank;
  Sample_Info: pSP_Sample_Info;
  pFile: PAnsiChar;
  Sample: BASS_SAMPLE;
  bSample: HSAMPLE;
Label
  LoadRAW;
Begin

  // Loads a sample into the bank specified. Must be supported by SDL_Mixer.
  // First, get the filename - mangled to fit the SpecBAS folder system.

  ERRStr := Filename;
  SP_TestPackageFile(Filename, Error);
  pFile := PAnsiChar(Filename);

  Idx := SP_FindBankID(BankID);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType <> SP_SAMPLE_BANK Then Begin

      SP_ClearBank(Idx, Error);
      Bank^.DataType := SP_SAMPLE_BANK;
      SetLength(Bank^.Info, SizeOf(SP_Sample_Info));
      Bank^.InfoLength := Length(Bank^.Info);
      Sample_Info := @Bank^.Info[0];

    End Else Begin

      BASS_SampleFree(pSP_Sample_Info(@Bank^.Info[0])^.Sample);
      Sample_Info := @Bank^.Info[0];

    End;

    // Now create a new sample with bass, and load the file into that sample.

    bSample := BASS_SampleLoad(False, pFile, 0, 0, 128, BASS_SAMPLE_OVER_VOL);

    If bSample = 0 Then Begin

      BASS_Err := BASS_ErrorGetCode;
      Case BASS_Err of
        BASS_ERROR_FILEOPEN: Error.Code := SP_ERR_FILE_MISSING;
        BASS_ERROR_FORMAT, BASS_ERROR_CODEC, BASS_ERROR_FILEFORM: Error.Code := SP_ERR_UNSUPPORTED_FORMAT;
      Else
        Error.Code := SP_ERR_SOUND_ERROR;
      End;
      Exit;

    End Else Begin

      // Sample loaded, copy the info to a bank!

      BASS_SampleGetInfo(bSample, Sample);

      Sample_Info^.Sample := bSample;
      Sample_Info^.Size := Sample.length;
      Sample_Info^.Rate := Sample.freq;
      Sample_Info^.Bits := Sample.origres;
      Sample_Info^.Volume := Sample.volume;
      Sample_Info^.Channels := Sample.chans;
      Sample_Info^.Panning := 0;

      // Finally, copy the sample data to the memory bank. This means a doubling up of the
      // sample data, but saves us having to copy out from the sample to edit and then send it
      // back again.

      SetLength(Bank^.Memory, Sample.length);
      BASS_SampleGetData(bSample, @Bank^.Memory[0]);

      Bank^.Changed := False;

      Error.Code := SP_ERR_OK;

    End;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Sample_Rate(BankID: Integer; sRate: LongWord; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sample_Info: pSP_Sample_Info;
  SampleData: BASS_SAMPLE;
Begin

  Idx := SP_FindBankID(BankID);

  If Idx > -1 Then Begin

//    If (sRate >= MINRATE) and (sRate <= MAXRATE) Then Begin

      Bank := SP_BankList[Idx];

      If Bank^.DataType <> SP_SAMPLE_BANK Then Begin

        Error.Code := SP_ERR_INVALID_BANK;
        Exit;

      End Else Begin

        Sample_Info := @Bank^.Info[0];
        Sample_Info.Rate := sRate;

        BASS_SampleGetInfo(Sample_Info.Sample, SampleData);
        SampleData.freq := sRate;
        BASS_SampleSetInfo(Sample_Info.Sample, SampleData);

      End;
{
    End Else

      Error.Code := SP_ERR_RATE_OUT_OF_RANGE;
}
  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Sample_Bits(BankID: Integer; sBits: LongWord; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sample_Info: pSP_Sample_Info;
  SampleData: BASS_SAMPLE;
  NewSample: HSAMPLE;
  Buffer: Array of Byte;
Begin

  Idx := SP_FindBankID(BankID);

  If Idx > -1 Then Begin

    If (sBits = 8) or (sBits = 16) Then Begin

      Bank := SP_BankList[Idx];

      If Bank^.DataType <> SP_SAMPLE_BANK Then Begin

        Error.Code := SP_ERR_INVALID_BANK;
        Exit;

      End Else Begin

        Sample_Info := @Bank^.Info[0];
        Sample_Info.Bits := sBits;

        BASS_SampleGetInfo(Sample_Info.Sample, SampleData);
        If sBits = 8 Then
          SampleData.flags := SampleData.flags Or BASS_SAMPLE_8BITS
        Else
          If SampleData.flags And BASS_SAMPLE_8BITS <> 0 Then
            SampleData.flags := SampleData.flags - BASS_SAMPLE_8BITS;

        SampleData.origres := sBits;

        NewSample := BASS_SampleCreate(SampleData.length, SampleData.freq, SampleData.chans, 128, SampleData.flags);
        SetLength(Buffer, SampleData.length);
        BASS_SampleSetData(NewSample, @Bank^.Memory[0]);
        BASS_SampleFree(Sample_Info.Sample);
        Sample_Info.Sample := NewSample;
        Bank^.Changed := False;

      End;

    End Else

      Error.Code := SP_ERR_UNSUPPORTED_BITS;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Sample_Volume(BankID: Integer; sVolume: aFloat; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sample_Info: pSP_Sample_Info;
  SampleData: BASS_SAMPLE;
Begin

  Idx := SP_FindBankID(BankID);

  If Idx > -1 Then Begin

    If (sVolume >= 0) and (sVolume <= 1) Then Begin

      Bank := SP_BankList[Idx];

      If Bank^.DataType <> SP_SAMPLE_BANK Then Begin

        Error.Code := SP_ERR_INVALID_BANK;
        Exit;

      End Else Begin

        Sample_Info := @Bank^.Info[0];
        Sample_Info.Volume := sVolume;

        BASS_SampleGetInfo(Sample_Info.Sample, SampleData);
        SampleData.volume := sVolume;
        BASS_SampleSetInfo(Sample_Info.Sample, SampleData);

      End;

    End Else

      Error.Code := SP_ERR_VOLUME_OUT_OF_RANGE;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Sample_Panning(BankID: Integer; sPan: aFloat; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sample_Info: pSP_Sample_Info;
  SampleData: BASS_SAMPLE;
Begin

  Idx := SP_FindBankID(BankID);

  If Idx > -1 Then Begin

    If (sPan >= -1) And (sPan <= 1) Then Begin

      Bank := SP_BankList[Idx];

      If Bank^.DataType <> SP_SAMPLE_BANK Then Begin

        Error.Code := SP_ERR_INVALID_BANK;
        Exit;

      End Else Begin

        Sample_Info := @Bank^.Info[0];
        Sample_Info.Panning := sPan;

        BASS_SampleGetInfo(Sample_Info.Sample, SampleData);
        SampleData.pan := sPan;
        BASS_SampleSetInfo(Sample_Info.Sample, SampleData);

      End;

    End Else

      Error.Code := SP_ERR_PAN_OUT_OF_RANGE;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Sample_Stereo(BankID: Integer; sStereo: LongWord; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sample_Info: pSP_Sample_Info;
  SampleData: BASS_SAMPLE;
  NewSample: HSAMPLE;
  Buffer: Array of Byte;
Begin

  Idx := SP_FindBankID(BankID);

  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];

    If Bank^.DataType <> SP_SAMPLE_BANK Then Begin

      Error.Code := SP_ERR_INVALID_BANK;
      Exit;

    End Else Begin

      Sample_Info := @Bank^.Info[0];
      if sStereo > 0 Then
        Sample_Info.Channels := 2
      Else
        Sample_Info.Channels := 1;

      BASS_SampleGetInfo(Sample_Info.Sample, SampleData);
      SampleData.chans := Sample_Info.Channels;

      NewSample := BASS_SampleCreate(SampleData.length, SampleData.freq, SampleData.chans, 128, SampleData.flags);
      SetLength(Buffer, SampleData.length);
      BASS_SampleSetData(NewSample, @Bank^.Memory[0]);
      BASS_SampleFree(Sample_Info.Sample);
      Sample_Info.Sample := NewSample;
      Bank^.Changed := False;

    End;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Function SP_Sample_Play(BankID: Integer; Rate: aFloat; RateStr: aString; Loops, Volume, Panning: aFloat; Var Error: TSP_ErrorCode): LongWord;
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Channel: HCHANNEL;
  Sample_Info: pSP_Sample_Info;
  SampleData: BASS_SAMPLE;
Begin

  Result := 0;
  Idx := SP_FindBankID(BankID);

  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];

    If Bank^.DataType <> SP_SAMPLE_BANK Then Begin

      Error.Code := SP_ERR_INVALID_BANK;
      Exit;

    End Else Begin

      Sample_Info := @Bank^.Info[0];
      If Bank^.Changed Then Begin
        BASS_SampleGetInfo(Sample_Info^.Sample, SampleData);
        SampleData.Length := Sample_Info^.Size;
        BASS_SampleSetInfo(Sample_Info^.Sample, SampleData);
        BASS_SampleSetData(Sample_Info^.Sample, @Bank^.Memory[0]);
        Bank^.Changed := False;
      End;
      Channel := BASS_SampleGetChannel(Sample_Info^.Sample, False);
      If RateStr = '' Then Begin
        If Rate < 0 Then Rate := Sample_Info^.Rate;
{        If (Rate < MINRATE) or (Rate > MAXRATE) Then Begin
          Error.Code := SP_ERR_RATE_OUT_OF_RANGE;
          Exit;
        End;}
      End Else Begin
        Rate := SP_StringToSemitones(RateStr, Error);
        If Error.Code = SP_ERR_OK Then Begin
          Rate := Sample_Info^.Rate * (Power(2, Rate/12));
        End Else
          Exit;
      End;
      If Panning = -9 Then
        Panning := Sample_Info.Panning;
      If (Panning < -1) or (Panning > 1) Then Begin
        Error.Code := SP_ERR_PAN_OUT_OF_RANGE;
        Exit;
      End;
      If Volume = -1 Then
        Volume := Sample_Info.Volume;
      If (Volume < 0) or (Volume > 1) Then Begin
        Error.Code := SP_ERR_VOLUME_OUT_OF_RANGE;
        Exit;
      End;

      BASS_ChannelSetAttribute(Channel, BASS_ATTRIB_FREQ, Rate);
      {$IFNDEF RASPI}
      // The arm hardfp build of bass currently raises a SIGFPE on this line :(
      BASS_ChannelSetAttribute(Channel, BASS_ATTRIB_PAN, Panning);
      {$ENDIF}
      BASS_ChannelSetAttribute(Channel, BASS_ATTRIB_VOL, Volume);

      If Loops > 0 Then
        BASS_ChannelFlags(Channel, BASS_SAMPLE_LOOP, BASS_SAMPLE_LOOP)
      Else
        BASS_ChannelFlags(Channel, 0, BASS_SAMPLE_LOOP);

      BASS_ChannelPlay(Channel, True);
      Result := LongWord(Channel);

    End;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Sample_Delete(BankID: Integer; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sample_Info: pSP_Sample_Info;
Begin

  Idx := SP_FindBankID(BankID);

  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];

    If Bank^.DataType <> SP_SAMPLE_BANK Then Begin

      Error.Code := SP_ERR_INVALID_BANK;
      Exit;

    End Else Begin

      Sample_Info := @Bank^.Info[0];
      BASS_SampleFree(Sample_Info^.Sample);
      SP_DeleteBank(Idx, Error);

    End;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Channel_Stop(ChannelID: LongWord; Var Error: TSP_ErrorCode);
Begin

  If Not BASS_ChannelStop(ChannelID) Then
    Error.Code := SP_ERR_CHANNEL_LOST;

End;

Procedure SP_Channel_Pause(ChannelID: LongWord; Var Error: TSP_ErrorCode);
Begin

  If Not BASS_ChannelPause(ChannelID) Then
    If BASS_ErrorGetCode <> BASS_ERROR_ALREADY Then
      Error.Code := SP_ERR_CHANNEL_LOST;

End;

Procedure SP_Channel_Resume(ChannelID: LongWord; Var Error: TSP_ErrorCode);
Begin

  If Not BASS_ChannelPlay(ChannelID, False) Then
    Error.Code := SP_ERR_CHANNEL_LOST;

End;

Procedure SP_Channel_Rate(ChannelID: LongWord; Rate: Integer; RateStr: aString; Var Error: TSP_ErrorCode);
Var
  ChInfo: BASS_CHANNELINFO;
Begin

{  If (Rate < MINRATE) or (Rate > MAXRATE) Then Begin
    Error.Code := SP_ERR_RATE_OUT_OF_RANGE;
    Exit;
  End; }

  If RateStr <> '' Then Begin
    Rate := Round(SP_StringToSemitones(RateStr, Error));
    If Error.Code = SP_ERR_OK Then Begin
      BASS_ChannelGetInfo(ChannelID, ChInfo);
      Rate := Round(ChInfo.Freq * (Power(2, Rate/12)));
    End Else
      Error.Code := SP_ERR_RATE_OUT_OF_RANGE;
  End;
  If Not BASS_ChannelSetAttribute(ChannelID, BASS_ATTRIB_FREQ, Rate) Then
    Error.Code := SP_ERR_CHANNEL_LOST;

End;

Procedure SP_Channel_Volume(ChannelID: LongWord; Volume: aFloat; Var Error: TSP_ErrorCode);
Begin

  If (Volume < 0) or (Volume > 1) Then Begin
    Error.Code := SP_ERR_VOLUME_OUT_OF_RANGE;
    Exit;
  End;
  If Not BASS_ChannelSetAttribute(ChannelID, BASS_ATTRIB_VOL, Volume) Then
    Error.Code := SP_ERR_CHANNEL_LOST;

End;

Procedure SP_Channel_Pan(ChannelID: LongWord; Pan: aFloat; Var Error: TSP_ErrorCode);
Begin

  If (Pan < -1) or (Pan > 1) Then Begin
    Error.Code := SP_ERR_PAN_OUT_OF_RANGE;
    Exit;
  End;

  {$IFNDEF RASPI}
  // The arm hardfp build of bass currently raises a SIGFPE on this line :(
  If Not BASS_ChannelSetAttribute(ChannelID, BASS_ATTRIB_PAN, Pan) Then
    Error.Code := SP_ERR_CHANNEL_LOST;
  {$ENDIF}

End;

Procedure SP_Channel_Seek(ChannelID, Seek: LongWord; Var Error: TSP_ErrorCode);
Begin

  If Not BASS_ChannelSetPosition(ChannelID, Seek, BASS_POS_BYTE) Then
    If BASS_ErrorGetCode = BASS_ERROR_POSITION Then
      Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE
    Else
      Error.Code := SP_ERR_CHANNEL_LOST;

End;

Function SP_GetChannelPos(ChannelID: LongWord; Var Error: TSP_ErrorCode): LongWord;
Begin

  Result := BASS_ChannelGetPosition(ChannelID, BASS_POS_BYTE);
  If Integer(Result) = -1 Then
    Error.Code := SP_ERR_CHANNEL_LOST;

End;

Procedure SP_Music_Play(Filename: aString; Volume: aFloat; Pause, Loop: Integer; Var Error: TSP_ErrorCode);
Var
  Flags: LongWord;
  FileExt: aString;
  pFile: PAnsiChar;
Begin

  ERRStr := Filename;

  If MUSICHANDLE <> 0 Then SP_Music_Stop(Error);
  Error.Code := SP_ERR_OK;

  SP_TestPackageFile(Filename, Error);
  pFile := PAnsiChar(Filename);

  FileExt := Upper(aString(ExtractFileExt(String(Filename))));
  If (Pos(String(FileExt), '.MO3.IT.XM.S3M.MTM.MOD.UMX') <> 0) or (Copy(SP_ExtractFilename(Filename), 1, 4) = 'mod.') Then Begin

    // MOD - style music file. Load as bass music.

    If Loop > 0 Then
      Flags := BASS_SAMPLE_LOOP
    Else
      Flags := BASS_MUSIC_STOPBACK;

    MUSICHANDLE := BASS_MusicLoad(False, pFile, 0, 0, Flags or BASS_MUSIC_RAMPS or BASS_MUSIC_POSRESET or BASS_MUSIC_AUTOFREE or BASS_MUSIC_PRESCAN or BASS_MUSIC_PT1MOD, 0);

    If MUSICHANDLE = 0 Then Begin

      Case BASS_ErrorGetCode of

        BASS_ERROR_FILEOPEN:
          Error.Code := SP_ERR_FILE_MISSING;
        BASS_ERROR_FILEFORM:
          Error.Code := SP_ERR_INVALID_MUSIC_FILE;

      End;

    End Else

      MUSICISSTREAM := False;

  End Else Begin

    // Other music file (WAV, MP3 etc). Load as a bass stream.

    If Loop > 0 Then
      Flags := BASS_SAMPLE_LOOP
    Else
      Flags := 0;

    MUSICHANDLE := BASS_StreamCreateFile(False, pFile, 0, 0, Flags or BASS_STREAM_AUTOFREE or BASS_MUSIC_PRESCAN);

    If MUSICHANDLE = 0 Then Begin

      Case BASS_ErrorGetCode  of

        BASS_ERROR_FILEOPEN:
          Error.Code := SP_ERR_FILE_MISSING;
        BASS_ERROR_FILEFORM, BASS_ERROR_CODEC, BASS_ERROR_FORMAT:
          Error.Code := SP_ERR_INVALID_MUSIC_FILE;

      End;

    End Else

      MUSICISSTREAM := True;

  End;

  If Error.Code = SP_ERR_OK Then Begin
    If Volume > -1 Then
      If (Volume >= 0) and (Volume <= 1) Then
        BASS_ChannelSetAttribute(MUSICHANDLE, BASS_ATTRIB_VOL, Volume)
      Else
        Error.Code := SP_ERR_VOLUME_OUT_OF_RANGE;
    If Error.Code = SP_ERR_OK Then
      If Pause = 0 Then
        BASS_ChannelPlay(MUSICHANDLE, False);
  End;

End;

Procedure SP_Music_Play_Bank(BankID: Integer; Volume: aFloat; Pause, Loop: Integer; Var Error: TSP_ErrorCode);
Var
  Flags: LongWord;
  Idx: Integer;
Begin

  If MUSICHANDLE <> 0 Then SP_Music_Stop(Error);

  ERRStr := '';
  Error.Code := SP_ERR_OK;

  // Determine if the bank exists, and what sort of music it contains

  Idx := SP_FindBankID(BankID);

  If Idx >= 0 Then Begin

    // Try to play it as a .mod/.xm/.it etc - if it fails, then fall back to sample mode

    If Loop > 0 Then
      Flags := BASS_SAMPLE_LOOP
    Else
      Flags := BASS_MUSIC_STOPBACK;

    MUSICHANDLE := BASS_MusicLoad(True, @SP_BankList[Idx]^.Memory[0], 0, Length(SP_BankList[Idx]^.Memory), Flags or BASS_MUSIC_RAMPS or BASS_MUSIC_POSRESET or BASS_MUSIC_AUTOFREE or BASS_MUSIC_PRESCAN or BASS_MUSIC_PT1MOD, 0);

    If MUSICHANDLE = 0 Then Begin

      // Failed with an error - try as a sample.

      If Loop > 0 Then
        Flags := BASS_SAMPLE_LOOP
      Else
        Flags := 0;

      MUSICHANDLE := BASS_StreamCreateFile(True, @SP_BankList[Idx]^.Memory[0], 0, Length(SP_BankList[Idx]^.Memory), Flags or BASS_STREAM_AUTOFREE or BASS_MUSIC_PRESCAN);

      If MUSICHANDLE = 0 Then Begin

        Case BASS_ErrorGetCode  of

          BASS_ERROR_FILEOPEN:
            Error.Code := SP_ERR_FILE_MISSING;
          BASS_ERROR_FILEFORM, BASS_ERROR_CODEC, BASS_ERROR_FORMAT:
            Error.Code := SP_ERR_INVALID_MUSIC_FILE;

        End;

        Exit;

      End Else

        MUSICISSTREAM := True;

    End Else

      MUSICISSTREAM := False;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

  If Error.Code = SP_ERR_OK Then Begin
    If Volume > -1 Then
      If (Volume >= 0) and (Volume <= 1) Then
        BASS_ChannelSetAttribute(MUSICHANDLE, BASS_ATTRIB_VOL, Volume)
      Else
        Error.Code := SP_ERR_VOLUME_OUT_OF_RANGE;
    If Error.Code = SP_ERR_OK Then
      If Pause = 0 Then
        BASS_ChannelPlay(MUSICHANDLE, False);
  End;

End;

Procedure SP_Music_Stop(Var Error: TSP_ErrorCode);
Begin

  If MUSICHANDLE <> 0 Then Begin

    BASS_ChannelStop(MUSICHANDLE);
    If MUSICISSTREAM Then
      BASS_StreamFree(MUSICHANDLE)
    Else
      BASS_MusicFree(MUSICHANDLE);
    MUSICHANDLE := 0;

  End Else

    Error.Code := SP_ERR_MUSIC_LOST;

End;

Procedure SP_Music_Pause(Var Error: TSP_ErrorCode);
Begin

  If MUSICHANDLE <> 0 Then Begin

    BASS_ChannelPause(MUSICHANDLE);

  End Else

    Error.Code := SP_ERR_MUSIC_LOST;

End;

Procedure SP_Music_Resume(Var Error: TSP_ErrorCode);
Begin

  If MUSICHANDLE <> 0 Then Begin

    BASS_ChannelPlay(MUSICHANDLE, False);

  End Else

    Error.Code := SP_ERR_MUSIC_LOST;

End;

Procedure SP_Music_Seek(SeekTo: aFloat; Var Error: TSP_ErrorCode);
Var
  Offset: LongWord;
Begin

  If MUSICHANDLE <> 0 Then Begin

    Offset := BASS_ChannelSeconds2Bytes(MUSICHANDLE, SeekTo);
    If Not BASS_ChannelSetPosition(MUSICHANDLE, Offset, BASS_POS_BYTE or BASS_MUSIC_POSRESET) Then Begin

      Case BASS_ErrorGetCode of
        BASS_ERROR_POSITION:
          Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
      End;

    End;

  End Else

    Error.Code := SP_ERR_MUSIC_LOST;

End;

Procedure SP_Music_Volume(Volume: aFloat; Var Error: TSP_ErrorCode);
Begin

  If MUSICHANDLE <> 0 Then Begin

    If (Volume < 0) or (Volume > 1) Then Begin
      Error.Code := SP_ERR_VOLUME_OUT_OF_RANGE;
      Exit;
    End;
    If Not BASS_ChannelSetAttribute(MUSICHANDLE, BASS_ATTRIB_VOL, Volume) Then
      Error.Code := SP_ERR_MUSIC_LOST;

  End Else

    Error.Code := SP_ERR_MUSIC_LOST;

End;

Function SP_GetMusicPos(Var Error: TSP_ErrorCode): aFloat;
Var
  Position: Int64;
Begin

  Result := 0;
  If MUSICHANDLE <> 0 Then Begin

    Position := BASS_ChannelGetPosition(MUSICHANDLE, BASS_POS_BYTE);
    Result := BASS_ChannelBytes2Seconds(MUSICHANDLE, Position);

  End Else

    Error.Code := SP_ERR_MUSIC_LOST;


End;

Function SP_GetMusicLen(Var Error: TSP_ErrorCode): aFloat;
Var
  Position: Int64;
Begin

  Result := 0;
  If MUSICHANDLE <> 0 Then Begin

    Position := BASS_ChannelGetLength(MUSICHANDLE, BASS_POS_BYTE);
    Result := BASS_ChannelBytes2Seconds(MUSICHANDLE, Position);

  End Else

    Error.Code := SP_ERR_MUSIC_LOST;


End;

Procedure SP_PlaySystem(Var Channel: LongWord; BankID: Integer);
Var
  Error: TSP_ErrorCode;
Begin

  If Channel = 0 Then Begin
    Channel := SP_Sample_Play(BankID, -1, '', 0, CLICKVOL, 0, Error)
  End Else Begin
    BASS_ChannelPlay(Channel, True);
  End;

End;

Function  SP_StringToSemiTones(Str: aString; Var Error: TSP_ErrorCode): aFloat;
Var
  Len, SemiTone, Octave: Integer;
  Relaxed: Boolean;
Const
  Tones: Array[0..6] of Integer = (0, 2, 4, 5, 7, 9, 11);
Begin

  if Copy(Str, 1, 1) = '!' Then Begin
    Relaxed := True;
    Str := Copy(Str, 2);
  End Else
    Relaxed := False;

  Result := 0;
  ERRStr := Str;
  Len := Length(Str);
  If (Len < 1) or (Len > 3) Then Begin
    Error.Code := SP_ERR_INVALID_NOTE;
    Exit;
  End;

  // Convert a string ("C3", "D#2" or say, "E$1") to a semitone value above middle C (C4).
  // "c" is "c5" and "C" is "C5" - default octave is 5, "c" is semitone 0, as is "c5"

  Octave := 5;

  // First, pick up the note name, a..g or A..G

  Case Str[1] of
    'c'..'g': SemiTone := Tones[Byte(Str[1]) - Byte('c')];
    'a', 'b': SemiTone := 9 + (2 * (Byte(Str[1]) - Byte('a')));
    'C'..'G': SemiTone := Tones[Byte(Str[1]) - Byte('C')] + 12;
    'A', 'B': SemiTone := 21 + (2 * (Byte(Str[1]) - Byte('A')));
  Else
    Begin
      Error.Code := SP_ERR_INVALID_NOTE;
      Exit;
    End;
  End;

  If Len > 1 Then Begin

    // Pick up an optional Sharp (#) or flat ($), or an octave number

    Case Str[2] of
      '$':
        If (Str[1] in ['d', 'e', 'g', 'a', 'b', 'D', 'E', 'G', 'A', 'B']) or Relaxed Then
          Dec(SemiTone)
        Else Begin
          Error.Code := SP_ERR_INVALID_NOTE;
          Exit;
        End;
      '#':
        If (Str[1] in ['c', 'd', 'f', 'g', 'a', 'C', 'D', 'F', 'G', 'A']) or Relaxed Then
          Inc(SemiTone)
        Else Begin
          Error.Code := SP_ERR_INVALID_NOTE;
          Exit;
        End;
      '0'..'9':
        Begin
          Octave := Byte(Str[2]) - Byte('0');
          If Len = 3 Then Begin

            // If this is an octave number, then nothing else may follow.

            Error.Code := SP_ERR_INVALID_NOTE;
            Exit;

          End;
        End;
    Else
      Begin
        Error.Code := SP_ERR_INVALID_NOTE;
        Exit;
      End;
    End;

    If Len = 3 Then Begin

      // A note of length 3 *must* be something like "C#6" - so we're expecting an octave number here.

      If Str[3] in ['0'..'9'] Then
        Octave := Byte(Str[3]) - Byte('0')
      Else Begin
        Error.Code := SP_ERR_INVALID_NOTE;
        Exit;
      End;

    End;

  End;

  // Now we have an octave number, and a semitone number. Octave 5, note "c" is SemiTone 0, so figure from there.

  Octave := (Octave - 5) * 12;
  Inc(SemiTone, Octave);

  Result := SemiTone;

End;

Function  SP_SemiTonesToHz(SemiTone: aFloat): aFloat;
Begin

  // Converts a semitone (0 == Middle C) To Hz
  // Semitones are above or below Middle C. Multiply Middle C by 2^(n/12) Where n is the difference.

  Result := (220 * Power(2, (1/4))) * (Power(2, SemiTone/12));

End;

Procedure SP_MakeBEEP(Duration, Pitch: aFloat; WaveType: Integer; Attack, Decay, Sustain, Release, Noise, Roughness: aFloat; Async: Boolean; Error: TSP_ErrorCode);
Var
  Hz, Phase, Amplitude, AttackVol, AttackInc, DecayVol, DecayDec, ReleaseVol, ReleaseDec, mRoughness, Scalar, ScaleInc: aFloat;
  Idx, WaveSize, sampAttack, sampDecay, sampRelease, i, DeClickSize, BASS_Err: Integer;
  Channel: HCHANNEL;
  Sample: HSAMPLE;
  wSample: Integer;
  GotADSR, GotNoise, GotRoughness: Boolean;
  oSample: SmallInt;
  bBuffer: Array of Byte;
Begin

  wSample := 0;

  // Create a sound waveform and play it using the parameters specified.
  // Blocks CPU - will return when sound finished.

  // Calculate the size (Using default Hz and 16bit sound, mono).

  WaveSize := Round(Duration * 44100) * 2;
  SetLength(bBuffer, WaveSize);

  // Calculate the number of samples for each of the AD and R periods

  sampAttack := Round(Attack * 44100) * 2;
  sampDecay := Round(Decay * 44100) * 2;
  sampRelease := Max(Round(Release * 44100) * 2, 32);

  AttackVol := 0;
  AttackInc := 1/sampAttack;

  DecayVol := 1;
  DecayDec := (1 - Sustain)/sampDecay;

  ReleaseVol := Sustain;
  ReleaseDec := Sustain/sampRelease;

  GotADSR := (Attack <> 0) Or (Decay <> 0) Or (Release <> 0) Or (Sustain <> 1);
  GotNoise := Noise <> 0;
  GotRoughness := RoughNess <> 0;

  // Now fill it with the required wavetype.

  mRoughness := Roughness * Pi;
  Hz := SP_SemiTonesToHz(Pitch);
  Amplitude := 32767.0;
  Phase := 0;

  Idx := 0;
  While Idx < WaveSize Do Begin

    // Calculate the level based on the wavetype

    Case WaveType of

      0: wSample := Round(Amplitude * Sign(Sin(Phase)));                     // Square wave, the default
      1: wSample := Round(Amplitude * Sin(Phase));                           // Sine wave
      2: wSample := Round(Amplitude / Pi * Phase);                           // Sawtooth wave
      3: If Phase < Pi Then                                                  // Triangle wave
            wSample := Round(-Amplitude + (2 * Amplitude / Pi) * Phase)
         Else
            wSample := Round((3 * Amplitude) - (2 * Amplitude / Pi) * Phase);

    End;

    If gotNoise Then
      wSample := Round((wSample * (1 - Noise)) + ((Random - 0.5) * Noise * Amplitude * 2));

    // Apply the ADSR envelope to the amplitude requested

    If GotADSR Then
      If Idx < sampAttack Then Begin
        wSample := Round(wSample * AttackVol);
        AttackVol := AttackVol + AttackInc;
      End Else
        If Idx < sampDecay Then Begin
          wSample := Round(wSample * DecayVol);
          DecayVol := DecayVol - DecayDec;
        End Else
          If Idx < WaveSize - (sampRelease * 2) Then Begin
            wSample := Round(wSample * Sustain);
          End Else Begin
            wSample := Round(wSample * ReleaseVol);
            ReleaseVol := ReleaseVol - ReleaseDec;
          End;

    // And write the sample

    pWord(@bBuffer[Idx])^ := Word(wSample);

    // Set up for next sample, and apply roughness if necessary

    Phase := Phase + ((2 * Pi * Hz) / 44100);

    If Phase > 2 * Pi Then Begin
      Phase := Phase - 2 * Pi;
      If gotRoughness Then
        Phase := Phase + ((Random * mRoughness) - (mRoughness/2));
    End;

    Inc(Idx, 2);

  End;

  // Now de-click the start and end.

  DeClickSize := Min(44, WaveSize Div 4);

  Scalar := 0;
  ScaleInc := 1/DeClickSize;
  For i := 0 to DeClickSize -1 Do Begin
    // Start of sample
    oSample := Round(pSmallInt(@bBuffer[i * 2])^ * Scalar);
    pSmallInt(@bBuffer[i * 2])^ := oSample;
    // End of sample
    oSample := Round(pSmallInt(@bBuffer[WaveSize - ((i + 1) * 2)])^ * Scalar);
    pSmallInt(@bBuffer[WaveSize - ((i + 1) * 2)])^ := oSample;
    Scalar := Scalar + ScaleInc;
  End;

  // Finally, play the sample!

  Sample := BASS_SampleCreate(WaveSize, 44100, 1, 1, BASS_SAMPLE_OVER_POS);
  BASS_Err := BASS_ErrorGetCode;

  if BASS_Err = 0 Then Begin

    BASS_SampleSetData(Sample, @bBuffer[0]);

    Channel := BASS_SampleGetChannel(Sample, true);
    BASS_ChannelPlay(Channel, True);

    If ASync Then Begin

      // ASYNC beeps can be monitored by the BEEPMonitor thread.

      BEEPMonitor.AddChannel(Channel, Sample);

    End Else Begin

      // Wait for the sample to finish. Pressing ESC will BREAK, other keys are ignored.

      While (BASS_ChannelIsActive(Channel) = BASS_ACTIVE_PLAYING) And (KEYSTATE[K_Escape] = 0) Do CB_YIELD;
      If KEYSTATE[K_Escape] = 1 Then BREAKSIGNAL := True;

      BASS_SampleFree(Sample);

    End;

  End;

End;

Procedure TPLAYThread.SP_PLAY(Str: aString; SessionID: Integer; ASync: Boolean; Var Error: pSP_ErrorCode);
Type
  TPLAYBracket = Record
    Position: Integer;
    Repeated: Boolean;
  End;

Var
  i, j, k, l, v, bc, Idx, WaveSize, wSample, DeClickSize, BASS_Err, TripletCount, TripletNoteLen, FXStep, Offset,
  CurOctave, CurEffectLen, CurEFfect, CurVolume, CurNoteLen, LastNoteLen, CurSharpMode, CurMixMode: Integer;
  Pitch, Hz, Phase, Amplitude, Duration, Scalar, ScaleInc, NoiseScale, VolScale, FXInc, FXValue: aFloat;
  EnableEffects, EnableVolume, TiedNote: Boolean;
  BracketList: Array[0..10] of TPLAYBracket;
  TempError: TSP_ErrorCode;
  bBuffer: Array of Byte;
  Channel: HCHANNEL;
  oSample: SmallInt;
  NoteStr: aString;
  Sample: HSAMPLE;
  Ch: aChar;

  Function GetPLAYNumber: Integer;
  Begin
    Result := 0;
    While (i <= l) And (Str[i] in ['0'..'9']) Do Begin
      Result := (Result * 10) + Ord(Str[i]) - 48;
      Inc(i);
    End;
  End;

Const

  NoteLengths: Array[1..12] of Integer = (6, 9, 12, 18, 24, 36, 48, 72, 96, 4, 8, 16);
  Effects: Array[0..7] of aString = ('D00', 'A00', 'D11', 'A11', 'DDD', 'AAA', 'ADA', 'DAD');

Begin

  If Assigned(Error) Then
    Error^.Code := SP_ERR_OK;

  // ONLY TO BE CALLED BY A SEPARATE PLAY THREAD.
  // PLAY a$,b$,c$ will create three threads which play a$, b$ and c$ respectively, asynchronously, and then
  // kill themselves.

  CurSharpMode := 0;
  CurOctave := 5;
  EnableEffects := False;
  EnableVolume := False;
  CurVolume := 15;
  CurEffect := 7;
  CurEffectLen := 65535;
  CurNoteLen := 24; // One crotchet == 1 beat
  LastNoteLen := CurNoteLen;
  TripletCount := 0;
  TripletNoteLen := CurNoteLen;
  TiedNote := False;
  CurMixMode := 1;
  bc := -1;

  i := 1;
  l := Length(Str);
  While i <= l Do Begin
    If (Assigned(Error) And (Error^.Code <> SP_ERR_OK)) or Halted Then Exit;
    Ch := Str[i];
    Case Ch of
      'N': // Skip this, it's just a separator
        Begin
          Inc(i);
        End;
      '&': // Rest
        Begin
          Inc(i);
          While (CB_GETTICKS - Ticks < ((1/(96/CurNoteLen)) * (60 / CurTempo) * 4 * 1000)) And Not Halted Do Begin
            CheckMessages;
            CB_YIELD;
          End;
          Ticks := Ticks + ((1/(96/CurNoteLen)) * (60 / CurTempo) * 4 * 1000);
        End;
      '#': // Sharpen next note - can be packed ("C####C')
        Begin
          Inc(CurSharpMode);
          Inc(i);
        End;
      '$': // Flatten next note - can also be packed
        Begin
          Dec(CurSharpMode);
          Inc(i);
        End;
      'a'..'g', 'A'..'G': // Play a note (or rest) using information we've gathered
        Begin
          NoteStr := Ch;
          NoteStr := NoteStr + aChar(Ord(CurOctave) + 48);
          Pitch := SP_StringToSemiTones('!' + NoteStr, TempError) + CurSharpMode;
          Hz := SP_SemiTonesToHz(Pitch);
          Case CurMixMode of
            0: Begin VolScale := 0; NoiseScale := 0;   End;
            1: Begin VolScale := 1; NoiseScale := 0;   End;
            2: Begin VolScale := 1; NoiseScale := 0.5; End;
            3: Begin VolScale := 1; NoiseScale := 1;   End;
          Else
            Begin
              VolScale := 1; NoiseScale := 0;
            End;
          End;
          If EnableVolume Then Begin
            Scalar := AYLogVolume(CurVolume);
            VolScale := VolScale * Scalar;
          End;
          Amplitude := 32767 * VolScale;
          Duration := (1/(96/CurNoteLen)) * 4;
          WaveSize := Ceil(Duration * 44100 * 2);
          SetLength(bBuffer, WaveSize);
          Phase := 0;
          Idx := 0;
          While Idx < WaveSize Do Begin
            wSample := Round(Amplitude * Sign(Sin(Phase)));
            If NoiseScale > 0 Then
              wSample := Round((wSample * (1 - NoiseScale)) + ((Random - 0.5) * NoiseScale * Amplitude * 2));
            pWord(@bBuffer[Idx])^ := Word(wSample);
            Phase := Phase + ((2 * Pi * Hz) / 44100);
            Inc(Idx, 2);
          End;
          If EnableEffects Then Begin
            j := 0;
            FXStep := 1;
            While J < WaveSize Do Begin
              Case Effects[CurEffect][FXStep] of
                'A': // Attack
                  Begin
                    FXValue := 0;
                    FXInc := 1/CurEffectLen;
                  End;
                'D': // Decay
                  Begin
                    FXValue := 1;
                    FXInc := -1/CurEffectLen;
                  End;
                '0': // Silence
                  Begin
                    FXValue := 0;
                    FXInc := 0;
                  End;
                '1': // Tone
                  Begin
                    FXValue := 1;
                    FXInc := 0;
                  End;
              Else
                Begin
                  FXInc := 0;
                  FXValue := 1;
                End;
              End;
              Offset := j;
              For k := 0 to CurEffectLen -1 Do Begin
                Scalar := AYLogVolume(FXValue);
                oSample := Round(pSmallInt(@bBuffer[Offset])^ * Scalar);
                pSmallInt(@bBuffer[Offset])^ := oSample;
                FXValue := FXValue + FXInc;
                Inc(Offset, 2);
                If Offset >= WaveSize Then Break;
              End;
              Inc(j, CurEffectLen * 2);
              Inc(FXStep);
              If FXStep = 4 Then FXStep := 2;
            End;
          End;
          DeClickSize := Min(44, WaveSize Div 4);
          Scalar := 0;
          ScaleInc := 1/DeClickSize;
          For j := 0 to DeClickSize -1 Do Begin
            oSample := Round(pSmallInt(@bBuffer[j * 2])^ * Scalar);
            pSmallInt(@bBuffer[j * 2])^ := oSample;
            oSample := Round(pSmallInt(@bBuffer[WaveSize - ((j + 1) * 2)])^ * Scalar);
            pSmallInt(@bBuffer[WaveSize - ((j + 1) * 2)])^ := oSample;
            Scalar := Scalar + ScaleInc;
          End;
          Sample := BASS_SampleCreate(WaveSize, 44100, 1, 1, BASS_SAMPLE_OVER_POS);
          BASS_Err := BASS_ErrorGetCode;
          if BASS_Err = 0 Then Begin
            BASS_SampleSetData(Sample, @bBuffer[0]);
            Channel := BASS_SampleGetChannel(Sample, true);
            BASS_ChannelPlay(Channel, True);
            While (BASS_ChannelIsActive(Channel) = BASS_ACTIVE_PLAYING) And (CB_GETTICKS - Ticks < ((1/(96/CurNoteLen)) * (60 / CurTempo) * 4) * 1000) And Not Halted Do Begin
              CheckMessages;
              CB_YIELD;
            End;
            BASS_SampleFree(Sample);
            Ticks := Ticks + (((1/(96/CurNoteLen)) * (60 / CurTempo) * 4) * 1000);
          End Else
            Exit;
          If TripletCount > 0 Then Begin
            Dec(TripletCount);
            CurNoteLen := TripletNoteLen
          End Else
            CurNoteLen := LastNoteLen;
          CurSharpMode := 0;
          Inc(i);
        End;
      '0'..'9': // Set note duration. 10, 11 and 12 are Triplets.
        Begin
          CurSharpMode := 0;
          v := GetPLAYNumber;
          If (v >= 1) and (v <= 12) Then Begin
            If v < 10 Then Begin
              LastNoteLen := NoteLengths[v];
              If TiedNote Then
                CurNoteLen := CurNoteLen + LastNoteLen
              Else
                CurNoteLen := LastNoteLen;
            End Else Begin
              TripletCount := 2;
              TripletNoteLen := NoteLengths[v];
              If TiedNote Then
                CurNoteLen := CurNoteLen + TripletNoteLen
              Else
                CurNoteLen := TripletNoteLen;
            End;
          End Else Begin
            If Assigned(Error) Then
              Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
            Exit;
          End;
          TiedNote := False;
        End;
      '_': // Tied note length follows
        Begin
          TiedNote := True;
          Inc(i);
        End;
      'O': // Set Octave 0 to 8
        Begin
          Inc(i);
          v := GetPLAYNumber;
          If (v >= 0) and (v <= 8) Then
            CurOctave := v
          Else Begin
            If Assigned(Error) Then
              Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
            Exit;
          End;
        End;
      '(': // Stack a repeat point.
        Begin
          Inc(i);
          Inc(bc);
          If bc < 5 Then Begin
            BracketList[bc].Position := i;
            BracketList[bc].Repeated := False;
          End Else Begin
            If Assigned(Error) Then
              Error^.Code := SP_ERR_TOO_MANY_BRACKETS;
            Exit;
          End;
        End;
      ')': // UnStack a repeat point and jump to it.
        Begin
          Inc(i);
          If bc >= 0 Then Begin
            If Not BracketList[bc].Repeated Then Begin
              BracketList[bc].Repeated := True;
              i := BracketList[bc].Position;
            End Else Begin
              Dec(bc);
            End;
          End Else Begin
            i := 1;
          End;
        End;
      'T': // Set tempo. Broadcast the tempo change to all PLAY threads with the same sessionID.
        Begin
          Inc(i);
          v := GetPLAYNumber;
          If (v >= 60) And (v <= 240) Then Begin
            PLAYTempoChange(SessionID, v);
          End Else Begin
            If Assigned(Error) Then
              Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
            Exit;
          End;
        End;
      'M': // Mixer. Set 0 = Tone, 1 = Noise, 2 = Tone + Noise for this channel
        Begin
          Inc(i);
          v := GetPLAYNumber;
          If (v >= 0) And (v <= 3) Then
            CurMixMode := v
          Else Begin
            If Assigned(Error) Then
              Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
            Exit;
          End;
        End;
      'V': // Set Volume mode, 0 to 15
        Begin
          Inc(i);
          v := GetPLAYNumber;
          If (v >= 0) and (v <= 15) Then Begin
            EnableVolume := True;
            EnableEffects := False;
            CurVolume := v;
          End Else Begin
            If Assigned(Error) Then
              Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
            Exit;
          End;
        End;
      'U': // Enable waveform effects - set volume to 15.
        Begin
          EnableVolume := False;
          EnableEffects := True;
          CurVolume := 15;
          Inc(i);
        End;
      'X': // Effect duration - 0 to 65535. 1Hz = 6928. Converts to samples per envelope cycle
        Begin
          Inc(i);
          v := GetPLAYNumber;
          If (v >= 0) And (v <= 65535) Then
            CurEffectLen := Round((v/(1773500/256)) * 44100)
          Else Begin
            If Assigned(Error) Then
              Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
            Exit;
          End;
        End;
      'W': // Select the waveform effect to apply to subsequent notes
        Begin
          Inc(i);
          v := GetPLAYNumber;
          If (v >= 0) and (v <= 7) Then
            CurEFfect := v
          Else Begin
            If Assigned(Error) Then
              Error^.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
            Exit;
          End;
        End;
      'H': // Stop all playback. Send a signal to all PLAY threads with this sessionID to quit.
        Begin
          i := l;
          PLAYSignalHalt(SessionID);
          Exit;
        End;
      '!': // Comment block - skip to next '!' or the end of the string.
        Begin
          Inc(i);
          While (i <= l) and (Str[i] <> '!') Do Inc(i);
          If i >= l Then Exit Else Inc(i);
        End;
    Else
      Begin
        // Error - Invalid Note Name
        If Assigned(Error) Then Begin
          Error^.Code := SP_ERR_INVALID_NOTE;
          ERRStr := Ch;
        End;
        Exit;
      End;
    End;
  End;

End;

Procedure SP_PLAY(PLAYStrs: Array of aString; Var ErrorCode: Integer);
Var
  i, SessionID, t: Integer;
  ticks: aFloat;
Begin

  PLAYLock.Enter;
  Inc(CurSessionID);
  SessionID := CurSessionID;
  PLAYLock.Leave;

  t := 120;
  For i := 0 To High(PLAYStrs) Do
    t := GetTempoInformation(PLAYStrs[i], t);

  ticks := CB_GETTICKS;
  ErrorCode := -1;
  For i := 0 To High(PLAYStrs) Do
    AddPLAYThread(PLAYStrs[i], SessionID, t, ticks, False, @ErrorCode);

  ErrorCode := SP_ERR_OK;

  While PLAYSessionIsActive(SessionID) Do
    CB_YIELD;

End;

Procedure SP_PLAY_ASync(PLAYStrs: Array of aString);
Var
  i, SessionID, t, ErrorCode: Integer;
  AllPlaying: Boolean;
  ticks: aFloat;
Begin

  PLAYLock.Enter;
  Inc(CurSessionID);
  SessionID := CurSessionID;
  PLAYLock.Leave;

  t := 120;
  For i := 0 To High(PLAYStrs) Do
    t := GetTempoInformation(PLAYStrs[i], t);

  ticks := CB_GETTICKS;
  ErrorCode := -1;
  For i := 0 To High(PLAYStrs) Do
    AddPLAYThread(PLAYStrs[i], SessionID, t, ticks, True, @ErrorCode);

  ErrorCode := SP_ERR_OK;

  Repeat
    CB_YIELD;
    AllPlaying := True;
    For i := 0 To High(PLAYPool) Do
      AllPlaying := AllPlaying And PLAYPool[i].Playing;
  Until AllPlaying;

End;

Procedure TPLAYThread.Execute;
Var
  Error: TSP_ErrorCode;
  pError: pSP_ErrorCode;
Begin

  // Always create suspended

  Halted := False;
  Playing := False;
  Priority := tpNormal;
  FreeOnTerminate := True;
  NameThreadForDebugging('PLAY #' + IntToString(PoolIndex));
  pError := @Error;

  While Not Terminated Do Begin

    While ErrorCode^ <> SP_ERR_OK Do ;
    Playing := True;
    SP_PLAY(PLAYStr, SessionID, IsASync, pError);
    ErrorCode^ := pError^.Code;
    PLAYLock.Enter;
    DeletePLAYThread(PoolIndex);
    DeletePLAYMessages(ChanID);
    PLAYLock.Leave;
    Terminate;

  End;

End;

Procedure SendPLAYMessage(ChanID, Action, Payload: Integer);
Var
  l: Integer;
Begin

  PLAYLock.Enter;

  l := Length(PLAYMsgs);
  SetLength(PLAYMsgs, l +1);
  With PLAYMsgs[l] Do Begin
    TimeStamp := CB_GETTICKS;
    Msg := Action;
    Data := Payload;
    ID := ChanID;
  End;

  PLAYLock.Leave;

End;

Procedure DeletePLAYMessage(Index: Integer);
Var
  i: Integer;
Begin

  PLAYLock.Enter;

  For i := Index To High(PLAYMsgs) -1 Do
    PLAYMsgs[i] := PLAYMsgs[i +1];
  SetLength(PLAYMsgs, Length(PLAYMsgs) -1);

  PLAYLock.Leave;

End;

Procedure DeletePLAYMessages(ChanID: integer);
Var
  i, j: Integer;
Begin

  PLAYLock.Enter;

  j := 0;
  While j <= High(PLAYMsgs) Do Begin
    If PLAYMsgs[j].ID = ChanID Then Begin
      For i := j To High(PLAYMsgs) -1 Do
        PLAYMsgs[i] := PLAYMsgs[i +1];
      SetLength(PLAYMsgs, Length(PLAYMsgs) -1);
    End Else
      Inc(j);
  End;

  PLAYLock.Leave;

End;

Procedure TPLAYThread.CheckMessages;
Var
  i: Integer;
Begin

  PLAYLock.Enter;

  i := 0;
  While i <= High(PLAYMsgs) Do Begin
    With PLAYMsgs[i] Do
      If CB_GETTICKS - TimeStamp > 1000 Then
        DeletePLAYMessage(i)
      Else Begin
        If ID = ChanID Then Begin
          Case Msg of
            0: // Tempo Change
              Begin
                CurTempo := Data;
              End;
            1: // Halt
              Begin
                Halted := True;
              End;
          End;
          DeletePLAYMessage(i);
        End Else
          Inc(i);
      End;
  End;

  If KEYSTATE[K_Escape] = 1 Then BREAKSIGNAL := True;
  If BREAKSIGNAL Then Halted := True;

  PLAYLock.Leave;

End;

// PLAY thread pool management

Function GetTempoInformation(Str: aString; Default: Integer): Integer;
Var
  i, l: Integer;
  Done: Boolean;

  Function GetPLAYNumber: Integer;
  Begin
    Result := 0;
    While (i <= l) And (Str[i] in ['0'..'9']) Do Begin
      Result := (Result * 10) + Ord(Str[i]) - 48;
      Inc(i);
    End;
  End;

Begin

  i := 1;
  Done := False;
  l := Length(Str);
  Result := Default;
  While Not Done Do Begin
    If i > l Then Exit;
    Case Str[i] of
      '0'..'9', 'a'..'g', 'A'..'G', 'H', '$', '#', '_', '&':
        Exit;
      '(', ')', 'U', 'N':
        Inc(i);
      'O', 'M', 'X', 'V', 'W':
        Begin
          Inc(i);
          GetPLAYNumber;
        End;
      '!':
        Begin
          Inc(i);
          While (i <= l) and (Str[i] <> '!') Do Inc(i);
          If i >= l Then Exit Else Inc(i);
        End;
      'T':
        Begin
          Inc(i);
          Result := GetPLAYNumber;
        End;
    Else
      Inc(i);
    End;
  End;

End;

Procedure AddPLAYThread(Const Str: aString; ID, Tempo: Integer; aTime: aFloat; ASync: Boolean; Error: pInteger);
Var
  l: Integer;
Begin

  PLAYLock.Enter;

  l := Length(PLAYPool);
  SetLength(PLAYPool, l +1);
  PLAYPool[l] := TPLAYThread.Create(True);
  With PLAYPool[l] Do Begin
    Inc(CurChanID);
    ChanID := CurChanID;
    CurTempo := Tempo;
    PLAYStr := Str;
    SessionID := ID;
    ErrorCode := Error;
    PoolIndex := l;
    IsASync := ASync;
    Ticks := aTime;
    Start;
  End;

  PLAYLock.Leave;

End;

Procedure DeletePLAYThread(Index: Integer);
Var
  i: Integer;
Begin

  PLAYLock.Enter;

  If Index < Length(PLAYPool) Then Begin
    PLAYPool[Index].Terminate;
    For i := Index to Length(PLAYPool) -2 do Begin
      PLAYPool[i] := PLAYPool[i +1];
      PLAYPool[i].PoolIndex := i;
    End;
    SetLength(PLAYPool, Length(PLAYPool) -1);
  End;

  PLAYLock.Leave;

End;

Function PLAYSessionIsActive(ID: Integer): Boolean;
Var
  i: Integer;
Begin

  Result := False;

  PLAYLock.Enter;
  For i := 0 to Length(PLAYPool) -1 Do
    Result := Result or ((PLAYPool[i].SessionID = ID) And Not(PLAYPool[i].Halted));

  PLAYLock.Leave;

End;

Procedure PLAYTempoChange(ID: Integer; NewTempo: Integer);
Var
  i: Integer;
Begin

  PLAYLock.Enter;

  For i := 0 To High(PLAYPool) Do
    If PLAYPool[i].SessionID = ID Then
      SendPLAYMessage(PLAYPool[i].ChanID, PLAYMSG_TEMPO, NewTempo);

  PLAYLock.Leave;

End;

Procedure PLAYSignalHalt(ID: Integer);
Var
  i: Integer;
Begin

  PLAYLock.Enter;

  For i := 0 To High(PLAYPool) Do
    If (ID = -1) or (PLAYPool[i].SessionID = ID) Then
      SendPLAYMessage(PLAYPool[i].ChanID, 1, PLAYMSG_HALT);

  PLAYLock.Leave;

  If i = -1 Then
    While Length(PLAYPool) > 0 Do CB_YIELD;

End;

Initialization

  BEEPMonitor := TChannelMonitor.Create(False);
  PLAYLock := TCriticalSection.Create;

Finalization

  PLAYSignalHalt(-1);
  BEEPMonitor.Terminate;
  PLAYLock.Free;

end.
