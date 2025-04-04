// Copyright (C) 2016 By Paul Dunn
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

unit SP_BankFiling;

interface

Uses SysUtils, SP_Util, SP_Errors, SP_BaseComponentUnit, SP_AnsiStringlist;

Type

  SP_Bank = Packed Record
    ID: Integer;
    DataType: Integer;
    InfoLength: LongWord;
    Protection: Boolean;
    System: Boolean;
    Info: Array of Byte;
    Memory: Array of Byte;
    Changed: Boolean;
  End;
  pSP_Bank = ^SP_Bank;

  TP_Colour = Packed Record
    Case Integer of
      0: (B, G, R, A: Byte);
      1: (L: LongWord);
    End;
  pTP_Colour = ^TP_Colour;

  PalArray = Array[0..255] of TP_Colour;
  pPalArray = ^PalArray;

  SP_Character_Info = Packed Record
    Data: LongWord;
  End;
  pSP_Character_Info = ^SP_Character_Info;

  SP_Font_Info = Packed Record
    FontType: Integer;
    Width: Integer;
    Height: Integer;
    Transparent: Integer;
    Palette: Array[0..255] of TP_Colour;
    Font_Info: Array[0..255] of SP_Character_Info;
  End;
  pSP_Font_Info = ^SP_Font_Info;

  SP_Window_Info = Record
    ID, Width, Height, Stride, Inverse, Over, Italic, Bold,
    Left, Top, FontBankID, SpriteCount, scrollcnt, bpp, Menu, CaptionHeight, PrevWin: Integer;
    heading, orgx, orgy, orgw, orgh, winscalex, winscaley, scalex, scaley: aFloat;
    clipx1, clipy1, clipx2, clipy2: Integer; winscale, winorigin, flip: Boolean;
    Visible, AlphaEnabled, FontTrans, System: Boolean;
    pr_posx, pr_posy, dr_posx, dr_posy, GWScale, stroke: aFloat;
    Component: SP_BaseComponent;
    Transparent: Word;
    Offset, Ink, Paper: LongWord;
    Surface: pByte;
    Palette: Array[0..255] of TP_Colour;
  End;
  pSP_Window_Info = ^SP_Window_Info;

  SP_Bank_Screen = Record
    NumWindows: LongWord;
    Palette: Array[0..255] of TP_Colour;
  End;
  pSP_Bank_Screen = ^SP_Bank_Screen;

  SP_Graphic_Info = Packed Record
    Palette: Array[0..255] of TP_Colour;
    WindowInfo: SP_Window_Info;
    Width, Height, Depth: LongWord;
    Transparent: Word;
    orgx, orgy, orgw, orgh, winscalex, winscaley, scalex, scaley: aFloat;
    clipx1, clipy1, clipx2, clipy2: Integer;
    winscale, winorigin: Boolean;
    Data: pByte;
  End;
  pSP_Graphic_Info = ^SP_Graphic_Info;

  SP_Program_Info = Packed Record
    Size: LongWord;         // Size of the total memory array
    NameLen: LongWord;      // The length of the "name" field
    Name: aString;          // The name. Used by GOTO, GOSUB et al to jump into a program.
    NumLines: LongWord;     // number of lines.
  End;
  pSP_Program_info = ^SP_Program_Info;

  SP_LineInfo = Packed Record
    LineNum: LongWord;
    LineLen: LongWord;
    Offset: LongWord;
  End;
  pSP_LineInfo = ^SP_LineInfo;

  SP_Sample_Info = Record
    Size: LongWord;         // The size of the sample data in bytes
    Rate: LongWord;         // The sample rate - 8192, 11025, 22050, 44100, 48000 etc
    Bits: LongWord;         // The Bit depth - generally 8 or 16, but 24 may be used
    Volume: aFloat;         // Volume, from 0 to 1
    Channels: LongWord;     // Number of channels in this sample (1=mono, 2=stereo)
    Panning: aFloat;        // Panning position - -1 left, 0 Centre, 1 right
    Sample: LongWord;       // The BASS_SAMPLE pointer for this sound.
  End;
  pSP_Sample_Info = ^SP_Sample_Info;

  SP_PathPos = Record
    ToX, ToY: aFloat;
  End;

  Clone = Record
    X, Y: aFloat;
  End;

  SP_Sprite_Info = Record
    ID: Integer;            // The sprite's internal ID number used to identify it in a list.
    X, Y,                   // On-screen position
    MoveX, MoveY,           // The position the current move started from
    DstX, DstY: aFloat;     // Destination of the current move
    MoveDuration,           // The intended duration (in frames) of the move.
    MoveStart: Integer;     // The frame number the move started on
    DstTime: Integer;      // Number of frames left to reach dstx,dsty
    Angle: aFloat;          // Rotation angle
    DstAngle: aFloat;       // Destination Angle
    AngleTime: Integer;     // Number of frames left to reach angle
    AngleDir: Integer;      // -1 or 1 to indicate direction of current timed turn
    Scale: aFloat;          // The scaling value the sprite will be drawn with
    DstScale: aFloat;       // The destination scaling value
    ScaleTime: Integer;     // The number of frames to scale over
    AnimStart: Integer;     // First frame of animation
    AnimEnd: Integer;       // Last frame of animation
    AnimMode: LongWord;     // Type of animation
    AnimDelta: Integer;     // Direction of animation flow
    ResumeDelta: Integer;   // Backup of the animation flow direction for when paused
    NumFrames: Integer;     // Number of animation frames
    CurFrame: Integer;      // The current frame
    FrameCounter: LongWord; // Count-down to the next frame
    Window: pSP_Window_Info;// The window ID number this sprite is associated with
    OverMode: Integer;      // Sprites can have their own OVER mode
    CanCollide,             // Sprite can collide with non-PAPER pixels
    Collided,               // Sprite has hit something. Hard.
    HotSpot,                // The hotspot indicates that the user has set a hotspot - affects rotation
    Enabled: Boolean;       // Initially a sprite is disabled until it has a frame associated with it.
    Data: pByte;            // For easily finding the sprite data
    NumClones: LongWord;    // Number of clones this sprite possesses
    HotX, HotY: Integer;    // Hotspot - the offset that will be applied when drawing
    WrapMode: Integer;      // Wrapping - 0; no wrap. 1; Wrap to window; 2; Wrap to window clipping rect
    Clones: Array [0..255] of Clone; // Clone data (x,y coords)
  End;
  pSP_Sprite_Info = ^SP_Sprite_Info;

  SP_TileMap_Info = Record
    InternalGFX: Boolean;   // Does this tilemap have it's own graphic stored internally, or does it use a graphic bank?
    InternalGFXLen: LongWord;
    GraphicID: Integer;     // The ID of the graphic bank if used
    NumTiles: Integer;      // The number of tiles in the associated graphic
    NumTilesX: Integer;
    NumTilesY: Integer;
    MapWidth,
    MapHeight: Integer;     // Width and height of the tilemap
    TileWidth,
    TileHeight: Integer;    // Width and height of the tiles stored in the graphic.
    GraphicData: pByte;     // Pointer to the internal graphic data - nil if using a bank.
    GraphicWidth: Integer;  // Width of the tilemap's associated graphic
    GraphicHeight: Integer; // Height of the tilemap's associated graphic
    GraphicTransparent: Word;
    Rotation,
    Scaling: aFloat;        // The last used rotation and scaling from the last issued DRAW command.
    TileData: pInteger;     // Pointer to the tile data
    DrawX,
    DrawY,
    DrawW,
    DrawH: Integer;         // Info about the last DRAW operation - the rectangle drawn to.
    TileLUT: Array[0..1023] of pByte;
  End;
  pSP_TileMap_Info = ^SP_TileMap_Info;

  Function  INIFindSection(Var INI: TAnsiStringList; Section: aString): Integer;
  Function  INIFindEntry(Var INI: TAnsiStringList; Section, Entry: aString): Integer;

  Function  INIReadBool(Var INI: TAnsiStringList; Section, Entry: aString; Default: Boolean): Boolean;
  Function  INIReadFloat(Var INI: TAnsiStringList; Section, Entry: aString; Default: aFloat): aFloat;
  Function  INIReadString(Var INI: TAnsiStringList; Section, Entry: aString; Default: aString): aString;
  Function  INIReadInt(Var INI: TAnsiStringList; Section, Entry: aString; Default: Integer): Integer;
  Function  INIReadLong(Var INI: TAnsiStringList; Section, Entry: aString; Default: LongWord): LongWord;
  Function  INIReadWord(Var INI: TAnsiStringList; Section, Entry: aString; Default: Word): Word;

  Procedure INIWriteBool(Var INI: TAnsiStringList; Section, Entry: aString; Value: Boolean);
  Procedure INIWriteString(Var INI: TAnsiStringList; Section, Entry: aString; Value: aString);
  Procedure INIWriteInt(Var INI: TAnsiStringList; Section, Entry: aString; Value: Integer);
  Procedure INIWriteFloat(Var INI: TAnsiStringList; Section, Entry: aString; Value: aFloat);
  Procedure INIWriteLong(Var INI: TAnsiStringList; Section, Entry: aString; Value: LongWord);
  Procedure INIWriteWord(Var INI: TAnsiStringList; Section, Entry: aString; Value: Word);
  Procedure INIWriteByte(Var INI: TAnsiStringList; Section, Entry: aString; Value: Byte);

  Procedure SP_SaveBankAsText(Filename: aString; BankNum: LongWord; Var Error: TSP_ErrorCode);
  Function  SP_LoadBankFromText(Filename: aString; BankNum: Integer; Var Error: TSP_ErrorCode): Integer;

  Function  SP_BankToString(BankID: Integer): aString;
  Procedure SP_BankFromString(InBank: aString);

implementation

Uses SP_FileIO, SP_Tokenise, SP_BankManager, SP_SysVars, SP_Graphics, SP_Sound;

Function INIFindSection(Var INI: TAnsiStringlist; Section: AnsiString): Integer;
Begin
  Result := 0;
  While (Result < INI.Count) and (Lower(INI[Result]) <> '['+Lower(Section)+']') Do Inc(Result);
  If Result = INI.Count Then Begin
     If Result <> 0 Then Begin
        INI.Add(' ');
        Inc(Result);
     End;
     INI.Add('['+Section+']');
  End;
End;

Function INIFindEntry(Var INI: TAnsiStringlist; Section, Entry: AnsiString): Integer;
Begin
  Result := INIFindSection(INI, Section) +1;
  While Result < INI.Count Do Begin
     If Copy(INI[Result], 1, 1) <> '[' Then Begin
        If Lower(Copy(INI[Result], 1, Length(Entry)+1)) = Lower(Entry+'=') Then
           Exit
        Else
           Inc(Result);
     End Else Break;
  End;
  If Result = INI.Count Then Begin
     Result := INI.Count;
     INI.Add(Entry+'=');
  End Else
    If Copy(INI[Result], 1, 1) = '[' Then Begin
      If Result > 0 Then Begin
        Dec(Result);
        If Result > 0 Then Begin
          While Copy(INI[Result], 1, 1) = ' ' Do
            Dec(Result);
          Inc(Result);
        End Else
          Result := 0;
      End;
      INI.Insert(Result, Entry+'=');
    End;
End;

Function INIReadBool(Var INI: TAnsiStringlist; Section, Entry: AnsiString; Default: Boolean): Boolean;
Var
  EntryPos: Integer;
  Value: AnsiString;
Begin
  Result := Default;
  EntryPos := INIFindEntry(INI, Section, Entry);
  Value := Copy(INI[EntryPos], Length(Entry)+2, 999999);
  If Value = '1' Then Result := True;
  If Value = '0' Then Result := False;
  If Value = '' Then Begin
     Result := Default;
     If Result Then
        INI[EntryPos] := INI[EntryPos] + '1'
     Else
        INI[EntryPos] := INI[EntryPos] + '0';
  End;
End;

Function INIReadString(Var INI: TAnsiStringlist; Section, Entry: AnsiString; Default: AnsiString): AnsiString;
Var
  EntryPos: Integer;
  Value: AnsiString;
Begin
  EntryPos := INIFindEntry(INI, Section, Entry);
  Value := Copy(INI[EntryPos], Length(Entry)+2, 999999);
  If Value = '' Then Begin
     Result := Default;
     INI[EntryPos] := INI[EntryPos] + Default;
  End Else Result := Value;
End;

Function INIReadFloat(Var INI: TAnsiStringlist; Section, Entry: AnsiString; Default: aFloat): aFloat;
Var
  EntryPos, Idx: Integer;
  Value: AnsiString;
Begin
  EntryPos := INIFindEntry(INI, Section, Entry);
  Value := Copy(INI[EntryPos], Length(Entry)+2, 999999);
  If Value = '' Then Begin
     Result := Default;
     Value := aFloatToStr(Default);
     For Idx := 1 To Length(Value) Do
      If Not (Value[Idx] in ['0'..'9', '-']) Then
        Value[Idx] := '.';
     INI[EntryPos] := INI[EntryPos] + Value;
  End Else Result := StrToFloat(String(Value));
End;

Function INIReadInt(Var INI: TAnsiStringlist; Section, Entry: AnsiString; Default: Integer): Integer;
Var
  EntryPos: Integer;
  Value: AnsiString;
Begin
  EntryPos := INIFindEntry(INI, Section, Entry);
  Value := Copy(INI[EntryPos], Length(Entry)+2, 999999);
  If Value = '' Then Begin
     Result := Default;
     INI[EntryPos] := INI[EntryPos] + IntToString(Default);
  End Else
    Result := StringToInt(Value, Default);
End;

Function INIReadLong(Var INI: TAnsiStringlist; Section, Entry: AnsiString; Default: LongWord): LongWord;
Var
  EntryPos: Integer;
  Value: AnsiString;
Begin
  EntryPos := INIFindEntry(INI, Section, Entry);
  Value := Copy(INI[EntryPos], Length(Entry)+2, 999999);
  If Value = '' Then Begin
     Result := Default;
     INI[EntryPos] := INI[EntryPos] + IntToString(Default);
  End Else Result := StringToInt(Value, Default);
End;

Function INIReadWord(Var INI: TAnsiStringlist; Section, Entry: AnsiString; Default: Word): Word;
Var
  EntryPos: Integer;
  Value: AnsiString;
Begin
  EntryPos := INIFindEntry(INI, Section, Entry);
  Value := Copy(INI[EntryPos], Length(Entry)+2, 999999);
  If Value = '' Then Begin
     Result := Default;
     INI[EntryPos] := INI[EntryPos] + IntToString(Default);
  End Else Result := StringToInt(Value, Default);
End;

Procedure INIWriteBool(Var INI: TAnsiStringlist; Section, Entry: AnsiString; Value: Boolean);
Var
  EntryPos: Integer;
Begin
  EntryPos := INIFindEntry(INI, Section, Entry);
  If Value Then
    INI[EntryPos] := INI[EntryPos] + '1'
  Else
    INI[EntryPos] := INI[EntryPos] + '0';
End;

Procedure INIWriteString(Var INI: TAnsiStringlist; Section, Entry: AnsiString; Value: AnsiString);
Var
  EntryPos: Integer;
Begin
  EntryPos := INIFindEntry(INI, Section, Entry);
  INI[EntryPos] := INI[EntryPos] + Value;
End;

Procedure INIWriteInt(Var INI: TAnsiStringlist; Section, Entry: AnsiString; Value: Integer);
Var
  EntryPos: Integer;
Begin
  EntryPos := INIFindEntry(INI, Section, Entry);
  INI[EntryPos] := INI[EntryPos] + IntToString(Value);
End;

Procedure INIWriteLong(Var INI: TAnsiStringlist; Section, Entry: AnsiString; Value: LongWord);
Var
  EntryPos: Integer;
Begin
  EntryPos := INIFindEntry(INI, Section, Entry);
  INI[EntryPos] := INI[EntryPos] + IntToString(Value);
End;

Procedure INIWriteWord(Var INI: TAnsiStringlist; Section, Entry: AnsiString; Value: Word);
Var
  EntryPos: Integer;
Begin
  EntryPos := INIFindEntry(INI, Section, Entry);
  INI[EntryPos] := INI[EntryPos] + IntToString(Value);
End;

Procedure INIWriteByte(Var INI: TAnsiStringlist; Section, Entry: AnsiString; Value: Byte);
Var
  EntryPos: Integer;
Begin
  EntryPos := INIFindEntry(INI, Section, Entry);
  INI[EntryPos] := INI[EntryPos] + IntToString(Value);
End;

Procedure INIWriteFloat(Var INI: TAnsiStringlist; Section, Entry: AnsiString; Value: aFloat);
Var
  Idx, EntryPos: Integer;
  ValueStr: AnsiString;
Begin
  EntryPos := INIFindEntry(INI, Section, Entry);
  ValueStr := aFloatToStr(Value);
  For Idx := 1 To Length(ValueStr) Do
    If Not (ValueStr[Idx] in ['0'..'9','-']) Then
      ValueStr[Idx] := '.';
  INI[EntryPos] := INI[EntryPos] + ValueStr;
End;

Function SP_LoadBankFromText(Filename: aString; BankNum: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  BankID, FileID, DataSize, Idx, Ps, eIdx, Idx2, Fw, Fh, Fd, Ft: Integer;
  INI: TAnsiStringList;
  Buffer, BankType, Data, TempStr, TempStr2: aString;
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
  Font: pSP_Font_Info;
  NewBank: SP_Bank;
  Window: pSP_Window_Info;
  Sample: pSP_Sample_Info;
  Sprite, OldSprite: pSP_Sprite_Info;
  TileMap: pSP_TileMap_Info;
  IsBinary: Boolean;

  Function GetHexFrom(Var Str: aString; Const SearchStr: aString): Byte;

    Function GetNybble: Byte;
    Var
      Ch: aChar;
    Begin

      Ch := Str[Ps];
      If Ch in ['A'..'F'] Then
        Result := 10+(Ord(Ch) - Ord('A'))
      Else
        If Ch in ['0'..'9'] Then
          Result := Ord(Ch) - Ord('0')
        Else
          Result := 0;
      Inc(Ps);

    End;

  Begin

    Result := 0;
    Ps := Pos(SearchStr, Str);
    If Ps > 0 Then Begin
      Inc(Ps, Length(SearchStr));
      Result := (GetNybble Shl 4) + GetNybble;
      Str := Copy(Str, Ps, Length(Str));
    End;

  End;

  Procedure GetData;
  Begin
    Buffer := '';
    DataSize := INIReadInt(INI, 'Data', 'Content Size', 0);
    Data := INIReadString(INI, 'Data', 'Content', '');
    Buffer := ReadRawHex(Data);
    DataSize := Length(Buffer);
    SetLength(Bank.Memory, DataSize);
    CopyMem(@Bank.Memory[0], @Buffer[1], DataSize);
  End;

Begin

  INI := TAnsiStringList.Create;

  ERRStr := Filename;
  If SP_FileExists(Filename) Then Begin

    // Load into a temporary bank

    Buffer := '';
    FileID := SP_FileOpen(Filename, False, Error);

    If FileID > -1 Then Begin

      SetLength(Buffer, SP_FileSize(FileID, Error));
      SP_FileRead(FileID, @Buffer[1], Length(Buffer), Error);
      IsBinary := True;
      If Length(Buffer) > 11 Then
        If Lower(StringFromPtr(@Buffer[1], 11)) = '[bank info]' Then
          IsBinary := False;

      Idx := 0;
      If Not IsBinary Then Begin
        INI.StrictDelimiter := True;
        INI.Delimiter := #13;
        INI.DelimitedText := Buffer;

        If INI.Count > 0 Then
          If Lower(Copy(INI[0], 1, 11)) = '[bank info]' Then
            For Idx := 0 To INI.Count -1 Do
              If INI[Idx][1] = #10 Then
                INI[Idx] := Copy(INI[Idx], 2);
        Idx := 0;
      End;

      SP_FileClose(FileID, Error);

      Bank := @NewBank;
      If IsBinary Then
        BankType := ''
      Else Begin
        BankType := INIReadString(INI, 'Bank Info', 'Bank Type', '');
        Bank^.Protection := INIReadBool(INI, 'Bank Info', 'Protection', False);
        Bank^.ID := INIReadInt(INI, 'Bank Info', 'OriginalID', 0);
        Bank^.System := INIReadBool(INI, 'Bank Info', 'System', False);
      End;

      If BankType <> '' Then Begin

        If BankType = 'Object Bank' Then Begin

          Bank^.DataType := SP_OBJECT_BANK;
          Bank^.InfoLength := Idx;
          SetLength(Bank^.Info, 0);
          GetData;

        End Else

          If BankType = 'Graphic Bank' Then Begin

            Bank^.DataType := SP_GRAPHIC_BANK;
            SetLength(Bank^.Info, SizeOf(SP_Graphic_Info));
            Gfx := @Bank^.Info[0];

            TempStr := INIReadString(INI, 'Info', 'Palette', '');
            If TempStr <> '' Then Begin
            Idx := 0;
              While (TempStr <> '') And (Idx < 256) Do Begin
                Gfx^.Palette[Idx].r := GetHexFrom(TempStr, 'R:');
                Gfx^.Palette[Idx].g := GetHexFrom(TempStr, ',G:');
                Gfx^.Palette[Idx].b := GetHexFrom(TempStr, ',B:');
                Gfx^.Palette[Idx].a := GetHexFrom(TempStr, ',A:');
                Inc(Idx);
              End;
            End;

            Gfx^.Width := INIReadLong(INI, 'Info', 'Width', 0);
            Gfx^.Height := INIReadLong(INI, 'Info', 'Height', 0);
            Gfx^.Depth := INIReadLong(INI, 'Info', 'Depth', 8);
            Gfx^.Transparent := INIReadWord(INI, 'Info', 'Transparent', $FFFF);
            Gfx^.orgx := INIReadFloat(INI, 'Info', 'OriginX', 0);
            Gfx^.orgy := INIReadFloat(INI, 'Info', 'OriginY', 0);
            Gfx^.orgw := INIReadFloat(INI, 'Info', 'OriginWidth', Gfx^.Width);
            Gfx^.orgh := INIReadFloat(INI, 'Info', 'OriginHeight', Gfx^.Height);
            Gfx^.winscalex := INIReadFloat(INI, 'Info', 'WinScaleX', 1);
            Gfx^.winscaley := INIReadFloat(INI, 'Info', 'WinScaleY', 1);
            Gfx^.scalex := INIReadFloat(INI, 'Info', 'ScaleX', 1);
            Gfx^.scaley := INIReadFloat(INI, 'Info', 'ScaleY', 1);
            Gfx^.clipx1 := INIReadInt(INI, 'Info', 'ClipX1', 0);
            Gfx^.clipx2 := INIReadInt(INI, 'Info', 'ClipX2', 0);
            Gfx^.clipy1 := INIReadInt(INI, 'Info', 'ClipY1', Gfx^.Width);
            Gfx^.clipy2 := INIReadInt(INI, 'Info', 'ClipY2', Gfx^.Height);
            Gfx^.winscale := INIReadBool(INI, 'Info', 'WinScale', False);
            Gfx^.winorigin := INIReadBool(INI, 'Info', 'WinOrigin', False);

            GetData;

          End Else

            If BankType = 'Font Bank' Then Begin

              Bank^.DataType := SP_FONT_BANK;
              SetLength(Bank^.Info, SizeOf(SP_Font_Info));
              Font := @Bank^.Info[0];

              Font^.FontType := INIReadInt(INI, 'Info', 'FontType', SP_FONT_TYPE_MONO);
              Font^.Width := INIReadInt(INI, 'Info', 'Width', 0);
              Font^.Height := INIReadInt(INI, 'Info', 'Height', 0);
              Font^.Transparent := INIReadInt(INI, 'Info', 'Transparent', 65535);

              TempStr := INIReadString(INI, 'Info', 'Palette', '');
              If TempStr <> '' Then Begin
              Idx := 0;
                While (TempStr <> '') And (Idx < 256) Do Begin
                  Font^.Palette[Idx].r := GetHexFrom(TempStr, 'R:');
                  Font^.Palette[Idx].g := GetHexFrom(TempStr, ',G:');
                  Font^.Palette[Idx].b := GetHexFrom(TempStr, ',B:');
                  Font^.Palette[Idx].a := GetHexFrom(TempStr, ',A:');
                  Inc(Idx);
                End;
              End;

              For Idx := 0 To 255 Do
                Font^.Font_Info[Idx].Data := Idx * Font^.Width * Font^.Height;

              GetData;

            End Else

              If BankType = 'Window Bank' Then Begin

                // Load a window bank. Create a new bank, and assign a screen type to it

                Bank^.DataType := SP_WINDOW_BANK;
                SetLength(Bank^.Info, SizeOf(SP_Window_Info));
                Bank^.InfoLength := Length(Bank^.Info);
                Window := @Bank^.Info[0];

                Window^.ID := INIReadInt(INI, 'Info', 'ID', Idx);
                Window^.Width := INIReadInt(INI, 'Info', 'Width', 0);
                Window^.Height := INIReadInt(INI, 'Info', 'Height', 0);
                Window^.Stride := INIReadInt(INI, 'Info', 'Stride', Window^.Width);
                Window^.Inverse := INIReadInt(INI, 'Info', 'Inverse', 0);
                Window^.stroke := INIReadFloat(INI, 'Info', 'stroke', 1);
                Window^.Italic := INIReadInt(INI, 'Info', 'Italic', 0);
                Window^.Bold := INIReadInt(INI, 'Info', 'Bold', 0);
                Window^.Over := INIReadInt(INI, 'Info', 'Over', 0);
                Window^.Left := INIReadInt(INI, 'Info', 'Left', 0);
                Window^.Top := INIReadInt(INI, 'Info', 'Top', 0);
                Window^.PR_PosX := INIReadFloat(INI, 'Info', 'PR_PosX', 0);
                Window^.PR_PosY := INIReadFloat(INI, 'Info', 'PR_PosY', 0);
                Window^.DR_PosX := INIReadFloat(INI, 'Info', 'DR_PosX', 0);
                Window^.DR_PosY := INIReadFloat(INI, 'Info', 'DR_PosY', 0);
                Window^.GWScale := INIReadFloat(INI, 'Info', 'GWScale', 1);
                Window^.ScrollCnt := INIReadInt(INI, 'Info', 'ScrollCnt', 0);
                Window^.Bpp := INIReadInt(INI, 'Info', 'Bpp', 8);
                Window^.Heading := INIReadFloat(INI, 'Info', 'Heading', 0);
                Window^.OrgX := INIReadFloat(INI, 'Info', 'OrgX', 0);
                Window^.OrgY := INIReadFloat(INI, 'Info', 'OrgY', 0);
                Window^.OrgW := INIReadFloat(INI, 'Info', 'OrgW', Window^.Width);
                Window^.OrgH := INIReadFloat(INI, 'Info', 'OrgH', Window^.Height);
                Window^.WinScaleX := INIReadFloat(INI, 'Info', 'WinScaleX', 1);
                Window^.WinScaleY := INIReadFloat(INI, 'Info', 'WinScaleY', 1);
                Window^.ScaleX := INIReadFloat(INI, 'Info', 'ScaleX', 0);
                Window^.ScaleY := INIReadFloat(INI, 'Info', 'ScaleY', 0);
                Window^.ClipX1 := INIReadInt(INI, 'Info', 'ClipX1', 0);
                Window^.ClipX2 := INIReadInt(INI, 'Info', 'ClipX2', 0);
                Window^.ClipY1 := INIReadInt(INI, 'Info', 'ClipY1', 0);
                Window^.ClipY2 := INIReadInt(INI, 'Info', 'ClipY2', 0);
                Window^.WinScale := INIReadBool(INI, 'Info', 'WinScale', False);
                Window^.WinOrigin := INIReadBool(INI, 'Info', 'WinOrigin', False);
                Window^.Flip := INIReadBool(INI, 'Info', 'Flip', False);
                Window^.Visible := INIReadBool(INI, 'Info', 'Visible', True);
                Window^.AlphaEnabled := INIReadBool(INI, 'Info', 'AlphaEnabled', False);
                Window^.FontTrans := INIReadBool(INI, 'Info', 'FontTrans', False);
                Window^.System := INIReadBool(INI, 'Info', 'System', False);
                Window^.Offset := INIReadLong(INI, 'Info', 'Offset', 0);
                Window^.Transparent := INIReadWord(INI, 'Info', 'Transparent', $FFFF);
                Window^.Ink := INIReadLong(INI, 'Info', 'Ink', 0);
                Window^.Paper := INIReadLong(INI, 'Info', 'Paper', 8);
                Window^.PrevWin := FocusedWindow;
                Window^.CaptionHeight := 0;
                Window^.Component := Nil; // TO DO: Save/load components in a window? Worth the bother?
                Buffer := '';
                TempStr2 := INIReadString(INI, 'Info', 'Content', '');
                Buffer := ReadRawHex(TempStr2);
                Ps := (Window^.Width * Window^.Height * (Window^.Bpp Div 8));
                SetLength(Bank^.Memory, Ps);
                CopyMem(@Bank^.Memory[0], @Buffer[1], Ps);
                Window^.Surface := @Bank^.Memory[0];
                TempStr2 := INIReadString(INI, 'Info', 'Palette', '');
                If TempStr2 <> '' Then Begin
                Idx2 := 0;
                  While (TempStr2 <> '') And (Idx2 < 256) Do Begin
                    Window^.Palette[Idx2].r := GetHexFrom(TempStr2, 'R:');
                    Window^.Palette[Idx2].g := GetHexFrom(TempStr2, ',G:');
                    Window^.Palette[Idx2].b := GetHexFrom(TempStr2, ',B:');
                    Window^.Palette[Idx2].a := GetHexFrom(TempStr2, ',A:');
                    Inc(Idx2);
                  End;
                End Else
                  For Idx := 0 To 255 Do Window^.Palette[Idx] := DefaultPalette[Idx];

              End Else
                If BankType = 'Sample Bank' Then Begin

                  Bank^.DataType := SP_SAMPLE_BANK;
                  SetLength(Bank^.Info, SizeOf(SP_Sample_Info));
                  Bank^.InfoLength := Length(Bank^.Info);
                  Sample := @Bank^.Info[0];

                  Sample^.Size := INIReadLong(INI, 'Info', 'Size', 0);
                  Sample^.Rate := INIReadLong(INI, 'Info', 'Rate', 44100);
                  Sample^.Bits := INIReadLong(INI, 'Info', 'Bits', 16);
                  Sample^.Volume := INIReadFloat(INI, 'Info', 'Volume', 1.0);
                  Sample^.Channels := INIReadLong(INI, 'Info', 'Channels', 2);
                  Sample^.Panning := INIReadFloat(INI, 'Info', 'Panning', 0);

                  GetData;

                End Else
                  If BankType = 'Program Bank' Then Begin

                    Bank^.DataType := SP_PROGRAM_BANK;

                  End Else
                    If BankType = 'Sprite Bank' Then Begin

                      SP_BlockSprites;

                      Bank^.DataType := SP_SPRITE_BANK;
                      SetLength(Bank^.Info, SizeOf(SP_Sprite_Info) + 32);
                      Bank^.InfoLength := Length(Bank^.Info);
                      SetLength(Bank^.Memory, 0);
                      Sprite := @Bank^.Info[0];

                      Sprite^.X := INIReadFloat(INI, 'Info', 'X', 0.0);
                      Sprite^.Y := INIReadFloat(INI, 'Info', 'Y', 0.0);
                      Sprite^.MoveX := INIReadFloat(INI, 'Info', 'MoveX', 0.0);
                      Sprite^.MoveY := INIReadFloat(INI, 'Info', 'MoveY', 0.0);
                      Sprite^.DstX := INIReadFloat(INI, 'Info', 'DstX', 0.0);
                      Sprite^.DstY := INIReadFloat(INI, 'Info', 'DstY', 0.0);
                      Sprite^.MoveDuration := INIReadLong(INI, 'Info', 'MoveDuration', 0);
                      Sprite^.MoveStart := INIReadLong(INI, 'Info', 'MoveStart', 0);
                      Sprite^.DstTime := INIReadLong(INI, 'Info', 'DstTime', 0);
                      Sprite^.Angle := INIReadFloat(INI, 'Info', 'Angle', 0.0);
                      Sprite^.DstAngle := INIReadFloat(INI, 'Info', 'DstAngle', 0.0);
                      Sprite^.AngleTime := INIReadLong(INI, 'Info', 'AngleTime', 0);
                      Sprite^.AngleDir := INIReadInt(INI, 'Info', 'AngleDir', 0);
                      Sprite^.Scale := INIReadFloat(INI, 'Info', 'Scale', 0.0);
                      Sprite^.DstScale := INIReadFloat(INI, 'Info', 'DstScale', 0.0);
                      Sprite^.ScaleTime := INIReadLong(INI, 'Info', 'ScaleTime', 0);
                      Sprite^.AnimStart := INIReadInt(INI, 'Info', 'AnimStart', 0);
                      Sprite^.AnimEnd := INIReadInt(INI, 'Info', 'AnimEnd', 0);
                      Sprite^.AnimMode := INIReadLong(INI, 'Info', 'AnimMode', 0);
                      Sprite^.AnimDelta := INIReadInt(INI, 'Info', 'AnimDelta', 0);
                      Sprite^.ResumeDelta := INIReadInt(INI, 'Info', 'ResumeDelta', 0);
                      Sprite^.NumFrames := INIReadLong(INI, 'Info', 'NumFrames', 0);
                      Sprite^.CurFrame := INIReadInt(INI, 'Info', 'CurFrame', 0);
                      Sprite^.FrameCounter := INIReadLong(INI, 'Info', 'FrameCounter', 0);
                      Sprite^.OverMode := INIReadInt(INI, 'Info', 'OverMode', 0);
                      Sprite^.CanCollide := INIReadBool(INI, 'Info', 'CanCollide', True);
                      Sprite^.Collided := INIReadBool(INI, 'Info', 'Collided', False);
                      Sprite^.HotSpot := INIReadBool(INI, 'Info', 'HotSpot', True);
                      Sprite^.Enabled := INIReadBool(INI, 'Info', 'Enabled', True);
                      Sprite^.NumClones := INIReadLong(INI, 'Info', 'NumClones', 0);
                      Sprite^.HotX := INIReadInt(INI, 'Info', 'HotX', 0);
                      Sprite^.HotY := INIReadInt(INI, 'Info', 'HotY', 0);
                      Sprite^.WrapMode := INIReadInt(INI, 'Info', 'WrapMode', 0);

                      If Sprite^.NumClones > 0 Then
                        For Idx := 0 To Sprite^.NumClones -1 Do Begin
                          Sprite^.Clones[Idx].X := INIReadFloat(INI, 'Clone'+IntToString(Idx), 'X', 0.0);
                          Sprite^.Clones[Idx].Y := INIReadFloat(INI, 'Clone'+IntToString(Idx), 'Y', 0.0);
                        End;

                      For Idx := 0 To Sprite^.NumFrames -1 Do Begin
                        TempStr2 := INIReadString(INI, 'Frame '+IntToString(Idx), 'FrameData', '');
                        Buffer := ReadRawHex(TempStr2);

                        Fw := INIReadInt(INI, 'Frame '+IntToString(Idx), 'Width', 0);
                        Fh := INIReadInt(INI, 'Frame '+IntToString(Idx), 'Height', 0);
                        Fd := INIReadInt(INI, 'Frame '+IntToString(Idx), 'Delay', 1);
                        Ft := INIReadInt(INI, 'Frame '+IntToString(Idx), 'Transparency', $FFFF);
                        Ps := (Fw * Fh) + (SizeOf(LongWord) * 3) + SizeOf(Word);

                        eIdx := Length(Bank^.Memory);
                        SetLength(Bank^.Memory, eIdx + Ps);

                        pLongWord(@Bank^.Memory[eIdx])^ := Fd;
                        Inc(eIdx, SizeOf(LongWord));

                        pLongWord(@Bank^.Memory[eIdx])^ := Fw;
                        Inc(eIdx, SizeOf(LongWord));

                        pLongWord(@Bank^.Memory[eIdx])^ := Fh;
                        Inc(eIdx, SizeOf(LongWord));

                        pWord(@Bank^.Memory[eIdx])^ := Ft;
                        Inc(eIdx, SizeOf(Word));

                        CopyMem(@Bank^.Memory[eIdx], @Buffer[1], Length(Buffer));
                      End;

                      SP_UnblockSprites;

                    End Else
                      If BankType = 'Tilemap Bank' Then Begin

                        Bank^.DataType := SP_TILEMAP_BANK;

                      End;

      End Else
        Error.Code := SP_ERR_INVALID_BANK;

    End Else
      Error.Code := SP_ERR_COULD_NOT_OPEN_FILE;

  End Else
    Error.Code := SP_ERR_FILE_NOT_FOUND;

  // Now put the bank where it's supposed to go.
  // If the user specified a number >= 0 Then load into that bank if it exists (and is not protected).
  // If the bank has not been created yet then create that bank with that ID.
  // If the number is -1 then a new bank will be created and the data put in there.

  Result := -1;

  If Error.Code = SP_ERR_OK Then Begin

    If BankNum > -1 Then Begin
      BankID := SP_FindBankID(BankNum);
      If BankID < 0 Then Begin
        BankID := SP_FindBankID(SP_NewBank(0));
        SP_BankList[BankID]^.ID := BankNum;
      End Else Begin
        If SCREENBANK = -SP_BankList[BankID]^.ID Then Begin
          SCREENBANK := -1;
          SP_SetDrawingWindow(0);
        End;
        If SP_BankList[BankID]^.Protection Then Begin
          Error.Code := SP_ERR_BANK_PROTECTED;
          Exit;
        End;
      End;
    End Else Begin
      BankID := SP_FindBankID(SP_NewBank(Bank^.ID));
    End;

    Result := SP_BankList[BankID].ID;

    If Bank^.DataType = SP_SPRITE_BANK Then Begin

      If SP_BankList[BankID].DataType = SP_SPRITE_BANK Then Begin
        OldSprite := @SP_BankList[BankID].Info[0];
        SP_RemoveSpriteFromWindowList(OldSprite);
        If OldSprite^.Enabled Then Dec(NUMSPRITES);
      End;

      If MOUSEISGRAPHIC And (MOUSESPRITE = Bank^.ID) Then SP_MousePointerFromDefault;
      Inc(NUMSPRITES);

    End;

    // Now copy the new bank into the space made for it

    SetLength(SP_BankList[BankID].Info, Length(Bank^.Info));
    CopyMem(@SP_BankList[BankID].Info[0], @Bank^.Info[0], Length(Bank^.Info));
    SetLength(SP_BankList[BankID].Memory, Length(Bank^.Memory));
    CopyMem(@SP_BankList[BankID].Memory[0], @Bank^.Memory[0], Length(Bank^.Memory));

    SP_BankList[BankID].DataType := Bank^.DataType;
    SP_BankList[BankID].InfoLength := Length(Bank^.Info);
    SP_BankList[BankID].Changed := True;

    Case SP_BankList[BankID].DataType Of

      SP_SAMPLE_BANK:
        SP_Sample_Reallocate(SP_BankList[BankID].ID);

      SP_TILEMAP_BANK:
        Begin
          TileMap := pSP_TileMap_Info(@SP_BankList[BankID].Info[0]);
          SP_Tilemap_BuildLUT(TileMap);
        End;

      SP_SPRITE_BANK:
        Begin
          Sprite := pSP_Sprite_Info(@SP_BankList[BankID].Info[0]);
          Sprite^.ID := SP_BankList[BankID]^.ID;
          Sprite^.Window := pSP_Window_Info(WINDOWPOINTER);
          SP_SpriteToWindow(Sprite, pSP_Window_Info(WINDOWPOINTER)^.ID);
          Sprite^.Data := @SP_BankList[BankID].Memory[0];
        End;

      SP_GRAPHIC_BANK:
        Begin
          Gfx := pSP_Graphic_Info(@SP_BankList[BankID].Info[0]);
          Gfx^.Data := @Bank^.Memory[0];
        End;

    End;

  End;

  INI.Free;

End;

Procedure SP_SaveBankAsText(Filename: aString; BankNum: LongWord; Var Error: TSP_ErrorCode);
Var
  FileID, BankID, Idx, cIdx, eIdx, Width, Height, Transparency, Delay, sDataLen: Integer;
  Bank: pSP_Bank;
  INI: TAnsiStringlist;
  TempStr: aString;
  Gfx: pSP_Graphic_Info;
  Font: pSP_Font_Info;
  Prog: pSP_Program_Info;
  Line: pSP_LineInfo;
  Sample: pSP_Sample_Info;
  Sprite: pSP_Sprite_Info;
  tMap: pSP_TileMap_Info;
  Window: pSP_Window_Info;
  sPtr: pByte;
Const
  BankIDStr: aString = 'ZXBANK';

  Procedure WriteData;
  Begin
    INIWriteLong(INI, 'Data', 'Content Size', LongWord(Length(Bank^.Memory)));
    INIWriteString(INI, 'Data', 'Content', RawHexDump(@Bank^.Memory[0], Length(Bank^.Memory)));
  End;

Begin

  BankID := SP_FindBankID(BankNum);
  If BankID >= 0 Then Begin

    Bank := SP_BankList[BankID];

    If SP_FileExists(Filename) Then
      SP_DeleteFile(Filename, Error);

    FileID := SP_FileOpen(Filename, True, Error);
    If FileID > -1 Then Begin

      INI := TAnsiStringlist.Create;

      Case Bank^.DataType of
        SP_OBJECT_BANK:
          Begin
            INIWriteString(INI, 'Bank Info', 'Bank Type', 'Object Bank');
            WriteData;
          End;
        SP_GRAPHIC_BANK:
          Begin
            Gfx := @Bank^.Info[0];
            INIWriteString(INI, 'Bank Info', 'Bank Type', 'Graphic Bank');
            TempStr := '';
            For Idx := 0 To 255 Do
              TempStr := TempStr + 'R:' + IntToHex(Gfx^.Palette[Idx].r, 2) + ',G:' + IntToHex(Gfx^.Palette[Idx].g, 2) +
                                  ',B:' + IntToHex(Gfx^.Palette[Idx].g, 2) + ',A:' + IntToHex(Gfx^.Palette[Idx].a, 2) + ';';
            INIWriteString(INI, 'Info', 'Palette', TempStr);
            INIWriteLong(INI, 'Info', 'Width', Gfx^.Width);
            INIWriteLong(INI, 'Info', 'Height', Gfx^.Height);
            INIWriteLong(INI, 'Info', 'Depth', Gfx^.Depth);
            INIWriteWord(INI, 'Info', 'Transparent', Gfx^.Transparent);
            INIWriteFloat(INI, 'Info', 'OriginX', Gfx^.orgx);
            INIWriteFloat(INI, 'Info', 'OriginY', Gfx^.orgy);
            INIWriteFloat(INI, 'Info', 'OriginWidth', Gfx^.orgw);
            INIWriteFloat(INI, 'Info', 'OriginHeight', Gfx^.orgh);
            INIWriteFloat(INI, 'Info', 'WinScaleX', Gfx^.winscalex);
            INIWriteFloat(INI, 'Info', 'WinScaleY', Gfx^.winscaley);
            INIWriteFloat(INI, 'Info', 'ScaleX', Gfx^.scalex);
            INIWriteFloat(INI, 'Info', 'ScaleY', Gfx^.scaley);
            INIWriteInt(INI, 'Info', 'ClipX1', Gfx^.clipx1);
            INIWriteInt(INI, 'Info', 'ClipX2', Gfx^.clipx2);
            INIWriteInt(INI, 'Info', 'ClipY1', Gfx^.clipy1);
            INIWriteInt(INI, 'Info', 'ClipY2', Gfx^.clipy2);
            INIWriteBool(INI, 'Info', 'WinScale', Gfx^.winscale);
            INIWriteBool(INI, 'Info', 'WinOrigin', Gfx^.winorigin);
            WriteData;
          End;
        SP_FONT_BANK:
          Begin
            Font := @Bank^.Info[0];
            INIWriteString(INI, 'Bank Info', 'Bank Type', 'Font Bank');
            INIWriteInt(INI, 'Info', 'FontType', Font^.FontType);
            INIWriteInt(INI, 'Info', 'Width', Font^.Width);
            INIWriteInt(INI, 'Info', 'Height', Font^.Height);
            INIWriteInt(INI, 'Info', 'Transparent', Font^.Transparent);
            TempStr := '';
            For Idx := 0 To 255 Do
              TempStr := TempStr + 'R:' + IntToHex(Font^.Palette[Idx].r, 2) + ',G:' + IntToHex(Font^.Palette[Idx].g, 2) +
                                  ',B:' + IntToHex(Font^.Palette[Idx].g, 2) + ',A:' + IntToHex(Font^.Palette[Idx].a, 2) + ';';
            INIWriteString(INI, 'Info', 'Palette', TempStr);
            WriteData;
          End;
        SP_WINDOW_BANK:
          Begin
            Window := @Bank.Info[0];
            INIWriteInt(INI, 'Info', 'ID', Window^.ID);
            INIWriteInt(INI, 'Info', 'Width', Window^.Width);
            INIWriteInt(INI, 'Info', 'Height', Window^.Height);
            INIWriteInt(INI, 'Info', 'Stride', Window^.Stride);
            INIWriteInt(INI, 'Info', 'Inverse', Window^.Inverse);
            INIWriteFloat(INI, 'Info', 'stroke', Window^.stroke);
            INIWriteInt(INI, 'Info', 'Italic', Window^.Italic);
            INIWriteInt(INI, 'Info', 'Bold', Window^.Bold);
            INIWriteInt(INI, 'Info', 'Over', Window^.Over);
            INIWriteINt(INI, 'Info', 'Left', Window^.Left);
            INIWriteInt(INI, 'Info', 'Top', Window^.Top);
            INIWriteFloat(INI, 'Info', 'PR_PosX', Window^.pr_posx);
            INIWriteFloat(INI, 'Info', 'PR_PosY', Window^.pr_posy);
            INIWriteFloat(INI, 'Info', 'DR_PosX', Window^.dr_posx);
            INIWriteFloat(INI, 'Info', 'DR_PosY', Window^.dr_posy);
            INIWriteFloat(INI, 'Info', 'GWScale', Window^.GWScale);
            INIWriteInt(INI, 'Info', 'ScrollCnt', Window^.scrollcnt);
            INIWriteInt(INI, 'Info', 'Bpp', Window^.bpp);
            INIWriteFloat(INI, 'Info', 'Heading', Window^.heading);
            INIWriteFloat(INI, 'Info', 'OrgX', Window^.orgx);
            INIWriteFloat(INI, 'Info', 'OrgY', Window^.orgy);
            INIWriteFloat(INI, 'Info', 'OrgW', Window^.orgw);
            INIWriteFloat(INI, 'Info', 'OrgH', Window^.orgh);
            INIWriteFloat(INI, 'Info', 'WinScaleX', Window^.winscalex);
            INIWriteFloat(INI, 'Info', 'WinScaleY', Window^.winscaley);
            INIWriteFloat(INI, 'Info', 'ScaleX', Window^.scalex);
            INIWriteFloat(INI, 'Info', 'ScaleY', Window^.scaley);
            INIWriteInt(INI, 'Info', 'ClipX1', Window^.clipx1);
            INIWriteInt(INI, 'Info', 'ClipX2', Window^.clipx2);
            INIWriteInt(INI, 'Info', 'ClipY1', Window^.clipy1);
            INIWriteInt(INI, 'Info', 'ClipY2', Window^.clipy2);
            INIWriteBool(INI, 'Info', 'WinScale', Window^.winscale);
            INIWriteBool(INI, 'Info', 'WinOrigin', Window^.winorigin);
            INIWriteBool(INI, 'Info', 'Flip', Window^.Flip);
            INIWriteBool(INI, 'Info', 'Visible', Window^.visible);
            INIWriteBool(INI, 'Info', 'AlphaEnabled', Window^.alphaenabled);
            INIWriteBool(INI, 'Info', 'FontTrans', Window^.fonttrans);
            INIWriteBool(INI, 'Info', 'System', Window^.system);
            INIWriteWord(INI, 'Info', 'Transparent', Window^.transparent);
            INIWriteLong(INI, 'Info', 'Offset', Window^.offset);
            INIWriteLong(INI, 'Info', 'Ink', Window^.ink);
            INIWriteLong(INI, 'Info', 'Paper', Window^.paper);
            INIWriteInt(INI, 'Info', 'CaptionHeight', Window^.CaptionHeight);
            INIWriteString(INI, 'Info', 'Content', RawHexDump(@Bank^.Memory[0], Window^.Width * Window^.Height * (Window^.Bpp Div 8)));
            TempStr := '';
            For eIdx := 0 To 255 Do
              TempStr := TempStr + 'R:' + IntToHex(Window^.Palette[eIdx].r, 2) + ',G:' + IntToHex(Window^.Palette[eIdx].g, 2) +
                                  ',B:' + IntToHex(Window^.Palette[eIdx].g, 2) + ',A:' + IntToHex(Window^.Palette[eIdx].a, 2) + ';';
            INIWriteString(INI, 'Info', 'Palette', TempStr);
          End;
        SP_PROGRAM_BANK:
          Begin
            Prog := @Bank^.Info[0];
            INIWriteString(INI, 'Bank Info', 'Bank Type', 'Program Bank');
            INIWriteString(INI, 'Info', 'Name', Prog^.Name);
            INIWriteLong(INI, 'Info', 'LineCount', Prog^.NumLines);
            cIdx := -1;
            For Idx := 0 To Prog^.NumLines -1 Do Begin
              Line := pSP_LineInfo(@Bank^.Memory[SizeOf(SP_Program_Info)+(Idx * SizeOf(SP_LineInfo))]);
              TempStr := StringFromPtr(@Bank^.Memory[Line^.Offset], Line^.LineLen);
              INIWriteString(INI, 'Program Lines', 'Line ' + IntToString(Idx +1), SP_Detokenise(TempStr, cIdx, False, False));
            End;
          End;
        SP_SAMPLE_BANK:
          Begin
            Sample := @Bank^.Info[0];
            INIWriteString(INI, 'Bank Info', 'Bank Type', 'Sample Bank');
            INIWriteLong(INI, 'Info', 'Size', Sample^.Size);
            INIWriteLong(INI, 'Info', 'Rate', Sample^.Rate);
            INIWriteLong(INI, 'Info', 'Bits', Sample^.Bits);
            INIWriteFloat(INI, 'Info', 'Volume', Sample^.Volume);
            INIWriteLong(INI, 'Info', 'Channels', Sample^.Channels);
            INIWriteFloat(INI, 'Info', 'Panning', Sample^.Panning);
            WriteData;
          End;
        SP_SPRITE_BANK:
          Begin
            Sprite := @Bank^.Info[0];
            INIWriteString(INI, 'Bank Info', 'Bank Type', 'Sprite Bank');
            INIWriteFloat(INI, 'Info', 'X', Sprite^.X);
            INIWriteFloat(INI, 'Info', 'Y', Sprite^.Y);
            INIWriteFloat(INI, 'Info', 'MoveX', Sprite^.MoveX);
            INIWriteFloat(INI, 'Info', 'MoveY', Sprite^.MoveY);
            INIWriteFloat(INI, 'Info', 'DstX', Sprite^.DstX);
            INIWriteFloat(INI, 'Info', 'DstY', Sprite^.DstY);
            INIWriteLong(INI, 'Info', 'MoveDuration', Sprite^.MoveDuration);
            INIWriteLong(INI, 'Info', 'MoveStart', Sprite^.MoveStart);
            INIWriteLong(INI, 'Info', 'DstTime', Sprite^.DstTime);
            INIWriteFloat(INI, 'Info', 'Angle', Sprite^.Angle);
            INIWriteFloat(INI, 'Info', 'DstAngle', Sprite^.DstAngle);
            INIWriteLong(INI, 'Info', 'AngleTime', Sprite^.AngleTime);
            INIWriteInt(INI, 'Info', 'AngleDir', Sprite^.AngleDir);
            INIWriteFloat(INI, 'Info', 'Scale', Sprite^.Scale);
            INIWriteFloat(INI, 'Info', 'DstScale', Sprite^.DstScale);
            INIWriteLong(INI, 'Info', 'ScaleTime', Sprite^.ScaleTime);
            INIWriteInt(INI, 'Info', 'AnimStart', Sprite^.AnimStart);
            INIWriteInt(INI, 'Info', 'AnimEnd', Sprite^.AnimEnd);
            INIWriteLong(INI, 'Info', 'AnimMode', Sprite^.AnimMode);
            INIWriteInt(INI, 'Info', 'AnimDelta', Sprite^.AnimDelta);
            INIWriteInt(INI, 'Info', 'ResumeDelta', Sprite^.ResumeDelta);
            INIWriteLong(INI, 'Info', 'NumFrames', Sprite^.NumFrames);
            INIWriteInt(INI, 'Info', 'CurFrame', Sprite^.CurFrame);
            INIWriteLong(INI, 'Info', 'FrameCounter', Sprite^.FrameCounter);
            INIWriteInt(INI, 'Info', 'OverMode', Sprite^.OverMode);
            INIWriteBool(INI, 'Info', 'CanCollide', Sprite^.CanCollide);
            INIWriteBool(INI, 'Info', 'Collided', Sprite^.Collided);
            INIWriteBool(INI, 'Info', 'HotSpot', Sprite^.HotSpot);
            INIWriteBool(INI, 'Info', 'Enabled', Sprite^.Enabled);
            INIWriteLong(INI, 'Info', 'NumClones', Sprite^.NumClones);
            INIWriteInt(INI, 'Info', 'HotX', Sprite^.HotX);
            INIWriteInt(INI, 'Info', 'HotY', Sprite^.HotY);
            INIWriteInt(INI, 'Info', 'WrapMode', Sprite^.WrapMode);
            For Idx := 0 To Sprite^.NumClones -1 Do Begin
              INIWriteFloat(INI, 'Clone'+IntToString(Idx), 'X', Sprite^.Clones[Idx].X);
              INIWriteFloat(INI, 'Clone'+IntToString(Idx), 'Y', Sprite^.Clones[Idx].Y);
            End;
            For Idx := 0 To Sprite^.NumFrames -1 Do Begin
              SP_GetFrameData(Sprite, sPtr, sDataLen, Idx);
              Delay := pLongWord(sPtr)^;
              Inc(pLongWord(sPtr));
              Width := pLongWord(sPtr)^;
              Inc(pLongWord(sPtr));
              Height := pLongWord(sPtr)^;
              Inc(pLongWord(sPtr));
              Transparency := pWord(sPtr)^;
              Inc(pWord(sPtr));
              TempStr := RawHexDump(sPtr, sDataLen - (SizeOf(LongWord) * 3) - SizeOf(Word));
              INIWriteInt(INI, 'Frame '+IntToString(Idx), 'Width', Width);
              INIWriteInt(INI, 'Frame '+IntToString(Idx), 'Height', Height);
              INIWriteInt(INI, 'Frame '+IntToString(Idx), 'Delay', Delay);
              INIWriteInt(INI, 'Frame '+IntToString(Idx), 'Transparency', Transparency);
              INIWriteString(INI, 'Frame '+IntToString(Idx), 'FrameData', TempStr);
            End;
          End;
        SP_TILEMAP_BANK:
          Begin
            TMap := @Bank^.Info[0];
            INIWriteString(INI, 'Bank Info', 'Bank Type', 'TileMap Bank');
            INIWriteBool(INI, 'Info', 'InternalGFX', tMap^.InternalGfx);
            INIWriteLong(INI, 'Info', 'InternalGFXLen', tMap^.InternalGFXLen);
            INIWriteInt(INI, 'Info', 'NumTiles', tMap^.NumTiles);
            INIWriteInt(INI, 'Info', 'NumTilesX', tMap^.NumTilesX);
            INIWriteInt(INI, 'Info', 'NumTilesY', tMap^.NumTilesY);
            INIWriteInt(INI, 'Info', 'MapWidth', tMap^.MapWidth);
            INIWriteInt(INI, 'Info', 'MapHeight', tMap^.MapHeight);
            INIWriteInt(INI, 'Info', 'TileWidth', tMap^.TileWidth);
            INIWriteInt(INI, 'Info', 'TileHeight', tMap^.TileHeight);
            INIWriteInt(INI, 'Info', 'GraphicWidth', tMap^.GraphicWidth);
            INIWriteWord(INI, 'Info', 'GraphicTransparent', tMap^.GraphicTransparent);
            INIWriteFloat(INI, 'Info', 'Rotation', tMap^.Rotation);
            INIWriteFloat(INI, 'Info', 'Scaling', tMap^.Scaling);
            INIWriteInt(INI, 'Info', 'DrawX', tMap^.DrawX);
            INIWriteInt(INI, 'Info', 'DrawY', tMap^.DrawY);
            INIWriteInt(INI, 'Info', 'DrawW', tMap^.DrawW);
            INIWriteInt(INI, 'Info', 'DrawH', tMap^.DrawH);
            WriteData;
          End;
      End;

      INIWriteInt(INI, 'Bank Info', 'OriginalID', Bank^.ID);
      INIWriteBool(INI, 'Bank Info', 'Protection', Bank^.Protection);
      INIWriteBool(INI, 'Bank Info', 'System', Bank^.System);

      For Idx := 0 To INI.Count -1 Do Begin
        INI[Idx] := INI[Idx] + #13#10;
        SP_FileWrite(FileID, @INI[Idx][1], Length(INI[Idx]), Error);
      End;

      SP_FileClose(FileID, Error);
      INI.Free;

    End Else Begin
      ERRStr := Filename;
      Error.Code := SP_ERR_SAVE_OPEN_ERROR;
    End;

  End Else
    Error.Code:= SP_ERR_BANK_NOT_FOUND;

End;

Function  SP_BankToString(BankID: Integer): aString;
Var
  Idx: Integer;
  Bank: pSP_Bank;
Begin

  Idx := SP_FindBankID(BankID);
  Bank := SP_BankList[Idx];

  Idx := SizeOf(LongWord) +1;
  SetLength(Result, SizeOf(LongWord) + SizeOf(SP_Bank) + Length(Bank^.Info) + Length(Bank^.Memory));
  pLongWord(@Result[1])^ := Length(Bank^.Memory);
  CopyMem(@Result[Idx], @Bank^.ID, SizeOf(SP_Bank));
  Inc(Idx, SizeOf(SP_Bank));
  CopyMem(@Result[Idx], @Bank^.Info[0], Length(Bank^.Info));
  Inc(Idx, Length(Bank^.Info));
  CopyMem(@Result[Idx], @Bank^.Memory[0], Length(Bank^.Memory));

End;

Procedure SP_BankFromString(InBank: aString);
Var
  ID, Idx, Size, Idx2: Integer;
  Error: TSP_ErrorCode;
  sBank, Bank: pSP_Bank;
  gfx: pSP_Graphic_Info;
  TileMap: pSP_Tilemap_Info;
  Sprite: pSP_Sprite_Info;
Begin

  Size := pLongWord(@InBank[1])^;
  ID := pInteger(@InBank[SizeOf(LongWord) +1])^;
  Idx := SP_FindBankID(ID);

  if Idx > -1 Then
    SP_DeleteBank(Idx, Error);

  ID := SP_NewBank(Size);
  Idx := SP_FindBankID(ID);
  Bank := SP_BankList[Idx];
  Idx2 := SizeOf(LongWord) +1;

  sBank := @InBank[Idx2];
  Bank^.ID := sBank^.ID;
  Bank^.DataType := sBank^.DataType;
  Bank^.InfoLength := sBank^.InfoLength;
  Bank^.Protection := sBank^.Protection;
  Bank^.System := sBank^.System;
  Bank^.Changed := sBank^.Changed;
  Inc(Idx2, SizeOf(SP_Bank));
  SetLength(Bank^.Info, Bank^.InfoLength);
  CopyMem(@Bank^.Info[0], @InBank[Idx2], Bank^.InfoLength);
  Inc(Idx2, Bank^.InfoLength);
  CopyMem(@Bank^.Memory[0], @InBank[Idx2], Size);
  Case SP_BankList[Idx].DataType Of
    SP_SAMPLE_BANK:
      SP_Sample_Reallocate(SP_BankList[Idx].ID);
    SP_TILEMAP_BANK:
      Begin
        TileMap := pSP_TileMap_Info(@SP_BankList[Idx].Info[0]);
        SP_Tilemap_BuildLUT(TileMap);
      End;
    SP_SPRITE_BANK:
      Begin
        Sprite := pSP_Sprite_Info(@SP_BankList[Idx].Info[0]);
        Sprite^.ID := SP_BankList[Idx]^.ID;
        Sprite^.Window := pSP_Window_Info(WINDOWPOINTER);
        SP_SpriteToWindow(Sprite, pSP_Window_Info(WINDOWPOINTER)^.ID);
        Sprite^.Data := @SP_BankList[Idx].Memory[0];
      End;
    SP_GRAPHIC_BANK:
      Begin
        Gfx := pSP_Graphic_Info(@SP_BankList[Idx].Info[0]);
        Gfx^.Data := @Bank^.Memory[0];
      End;
  End;

End;

end.
