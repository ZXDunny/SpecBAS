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

unit SP_BankManager;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}

interface

Uses Math, SyncObjs, SP_BankFiling, SP_Util, SP_FileIO, SP_Errors, SP_SysVars, SP_Tokenise, SP_InfixToPostFix, SP_Package, Bass, SP_Components;

Type

  // A bank is a region of memory that stores pretty much anything.
  // They can store any amount of data (practically; upper limit is 2GB)
  // and they can be assigned to store specific types of data.

  // The Flags array stores type-specific information, see later for details.
  // Types currently are:

  // 0 - Binary
  // 1 - Graphics bank
  // 2 - Font bank
  // 3 - Screen bank
  // 4 - Program bank
  // 5 - Sample bank
  // 6 - Sprite bank
  // 7 - Tilemap bank



  // A Character Info record stores the offset and pointer to that character's
  // pixel data, and is part of the Font Bank's structure.

  SP_Character_Info = Packed Record
    Data: LongWord;
  End;
  pSP_Character_Info = ^SP_Character_Info;

  // A Font Bank record stores information about a font. These can be one of three
  // types - a mono font (0), a colour font (1) and a 32bit font (2). Thereafter
  // follow 122 entries which correspond to each one of the 96 characters in the
  // ASCII set, followed by 26 UDGs - stored in the Flags array. Not all characters
  // have to exist in the bank, and if a character has not been defined, its pointer will be nil.

  // Each entry of 8 bytes points to the data for that character, in the Bank's
  // Memory array both as an offset and a pointer.

  // A Screen Bank stores a screen. Screens have their own palette, and can contain
  // numerous windows. Each screen has a default window - its surface. Each window has
  // a pointer. Windows use the same palette as the screen, but have their own fonts.



  // A Graphic Info record stores information about a graphic - width x height in
  // pixels, and the location in the SP_Bank record's Memory array of the first pixel.
  // The Info array will contain:
  //  256 DWords - graphic palette if 8bit
  //    4  Bytes - graphic width
  //    4  Bytes - graphic height
  //    1  Byte  - graphic depth (8/32)
  //    2  Bytes - Transparent Index ($FFFF means no transparency)
  //    32 Bytes - origin info
  // Followed by:
  //    4 Bytes - Graphic Data pointer


  // A program bank - holds a program. By default, there are two - the command line and the
  // current program, but this can be expanded.


  // A Sample bank. This holds one sound sample of any type. Records for volume, sample rate, bitdepth and panning are
  // provided. Stereo samples are not able to be panned.



  // Sprite bank - holds one sprite, and the associated data (animation frames, masks etc).


  // Bank manipulation routines

  Function  SP_NewBank(Size: LongWord): Integer;
  Function  SP_Bank_Protect(ID: Integer; System: Boolean): Integer;
  Function  SP_Bank_DeProtect(ID: Integer): Integer;
  Function  SP_LoadBank(Filename: aString; BankNum: Integer; Var Error: TSP_ErrorCode): Integer;
  Procedure SP_SaveBank(Filename: aString; BankNum: LongWord; Data: Boolean; Var Error: TSP_ErrorCode);
  Procedure SP_DeleteBank(Index: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_ClearBank(Index: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_DeleteAllBanks(SystemToo: Boolean);
  Procedure SP_CopyBank(Source, Dest: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_CopyBankEx(SrcID, Start, Len, DstID, Offset: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_ResizeBank(Index, NewSize: Integer);
  Function  SP_FindBankID(ID: Integer): Integer;

  Function  SP_GetBankPointer(ID: Integer): pByte;
  Function  SP_GetBankSize(ID: Integer): Integer;

  Function  SP_Font_Bank_Create(FontType, Width, Height, Transparent: Integer): Integer;
  Function  SP_Font_Bank_SetChar(ID: Integer; Character: Integer; Data: pByte; Invert: Boolean = False): Integer;
  Procedure SP_SetSystemFont(BankID: Integer; Error: TSP_ErrorCode);
  Function  SP_SetSpeccyStyleChar(ID, Character: Integer; Data: pByte): Integer;

  Function  SP_Screen_Bank_Create(Width, Height: Integer): Integer;
  Procedure SP_SetWindowDefaults(Bank: pSP_Bank; Window: pSP_Window_Info; Left, Top, Width, Height, TransIdx, Bpp, Alpha: Integer);
  Function  SP_Add_Window(Left, Top, Width, Height, TransIdx, Bpp, Alpha: Integer; Var Error: TSP_ErrorCode): Integer;
  Procedure SP_SetWindowVisible(WindowID: Integer; Vis: Boolean; Error: TSP_ErrorCode);
  Procedure SwitchFocusedWindow(ID: Integer);

  Function  SP_Program_Bank_Create(Name: aString): Integer;
  Procedure SP_AddLine(BankID: Integer; Line: aString; Var Error: TSP_ErrorCode);
  Procedure SP_AddTokenisedLine(BankID: Integer; Tokens: aString; Var Error: TSP_ErrorCode);
  Procedure SP_DeleteLine(BankID, LineNum: Integer; Var Error: TSP_ErrorCode);
  Function  SP_FindLineBank(BankID, LineNum: Integer): Integer;
  Function  SP_FindStatement(BankID, LineNum, Statement: Integer): Integer;

  Function  SP_New_Sprite(X, Y: aFloat; Collide: Boolean; Over, Wrap, CopyFrom: Integer; Var Error: TSP_ErrorCode): Integer;
  Procedure SP_SetSpriteHotSpot(Id, X, Y: Integer; Var Error: TSP_ErrorCode);
  Function  SP_FindSpriteID(ID: Integer; Var Error: TSP_ErrorCode): Integer;
  Procedure SP_SpriteToWindow(Sprite: pSP_Sprite_Info; Window: Integer);
  Procedure SP_Add_Frame(SpriteID: Integer; Graphic: aString; Delay: LongWord; Var Error: TSP_ErrorCode);
  Procedure SP_Add_Frame_Graphic(SpriteID: Integer; BankID: Integer; Delay: LongWord; Var Error: TSP_ErrorCode);
  Procedure SP_Sprite_SetOver(Id, Over: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_Sprite_SetAnim(SpID, aStart, aEnd, aType: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_Sprite_Set_Frame(SpID, Frame, Delay: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_Sprite_Stop_Anim(SpID: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_GetFrameData(var Sprite: pSP_Sprite_Info; var StrPtr: pByte; var StrLen: Integer; FrameNum: Integer);
  Function  SP_GetFrameAddr(SpriteID, Frame: Integer; Var Error: TSP_ErrorCode): Integer;
  Procedure SP_MirrorSprite(SpID: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_FlipSprite(SpID: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_Show_Sprite(SpriteID: Integer; Error: TSP_ErrorCode);
  Procedure SP_Hide_Sprite(SpriteID: Integer; Error: TSP_ErrorCode);
  Procedure SP_PutSpritePermanent(SpID: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_DrawSprite(dPtr: pByte; var Sprite: pSP_Sprite_Info; var Window: pSP_Window_Info);
  Function  SP_PutSprite(Dst: pByte; dX, dY, Over, Paper, wTrans: Integer; dW, dH: LongWord; Src: pByte; SrcLen: Integer; RotAngle, Scale: aFloat; Var cX1, cY1, cX2, cY2: Integer; Var Error: TSP_ErrorCode): Boolean;
  Function  SP_RotateSprite(Src: pByte; sW, sH: Integer; Dst: pByte; dX, dY, dW, dH, Over, Paper, wTrans: Integer; Trans: Word; Rot, Scale: aFloat; cX1, cY1, cX2, cY2: Integer): Boolean;
  Procedure SP_Delete_Sprite(SpriteID: Integer; Error: TSP_ErrorCode);
  Procedure SP_Clear_Sprite(SpriteID: Integer; Error: TSP_ErrorCode);
  Procedure SP_RemoveSpriteFromWindowList(Sprite: pSP_Sprite_Info);
  Procedure SP_BlockSprites;
  Procedure SP_UnBlockSprites;
  Procedure SP_AddClone(Id: Integer; X, Y: aFloat; var Error: TSP_ErrorCode);
  Procedure SP_MoveClone(Id, Index: Integer; X, Y: aFloat; var Error: TSP_ErrorCode);
  Procedure SP_DeleteClone(Id, Index: Integer; var Error: TSP_ErrorCode);
  Function  SP_GetClonePos(Id, Index: Integer; Var Error: TSP_ErrorCode): Clone;
  Procedure SP_Sprite_SetOrder(Id: Integer; Front: Boolean; Var Error: TSP_ErrorCode);
  Procedure SP_Sprite_SetOrderMove(Id, Delta: Integer; Var Error: TSP_ErrorCode);

  Function  SP_New_GraphicA(Width, Height: Integer; Trans: Word; Var Error: TSP_ErrorCode): Integer;
  Function  SP_New_GraphicB(GraphicStr: aString; Var Error: TSP_ErrorCode): Integer;
  Function  SP_New_GraphicC(Filename: aString; Trans: Word; Var Error: TSP_ErrorCode): Integer;
  Procedure SP_Load_Graphic(Id: Integer; Filename: aString; Trans: Word; Var Error: TSP_ErrorCode);
  Procedure SP_SetGraphicOrigin(Id: Integer; x1,y1,x2,y2: aFloat; Var Error: TSP_ErrorCode);
  Procedure SP_SetGraphicOriginNoExt(Id: Integer; x1, y1: aFloat; Var Error: TSP_ErrorCode);
  Procedure SP_SetGraphicOriginOff(GfxID: Integer; Var Error: TSP_ErrorCode);
  Function  SP_GfxBankToString(Id: Integer; Var Error: TSP_ErrorCode): aString;
  Function  SP_GetGraphicDetails(Id: Integer; Var Error: TSP_ErrorCode): pSP_Graphic_info;
  Function  SP_GetGraphicPalette(Id, PalIndex: Integer; Var Error: TSP_ErrorCode): LongWord;
  Function  SP_GetGraphicPixel(Id: Integer; X, Y: aFloat; Var Error: TSP_ErrorCode): Integer;
  Procedure SP_SetGraphicPixel(Id: Integer; X, Y: aFloat; Clr: Byte; Var Error: TSP_ErrorCode);
  Procedure SP_GFX_UpdateWindowInfo(Var Gfx: pSP_Graphic_Info; Bank: pSP_Bank);
  Function  SP_GraphicToFont(GfxID: Integer; var Output: aString; Spacing: Integer; Var Error: TSP_ErrorCode): Integer;

  Function  SP_New_Tilemap_FromBank(BankID, MapWidth, MapHeight, TileWidth, TileHeight: Integer; Var Error: TSP_ErrorCode): Integer;
  Function  SP_New_Tilemap_FromString(Gfx: aString; MapWidth, MapHeight, TileWidth, TileHeight: Integer; Var Error: TSP_ErrorCode): Integer;
  Procedure SP_Tilemap_Set(TileMapID, X, Y, Tile: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_Tilemap_GraphicBank(TileMapID, GraphicID, TileWidth, TileHeight: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_Tilemap_GraphicString(TileMapID, TileWidth, TileHeight: Integer; Graphic: aString; Var Error: TSP_ErrorCode);
  Procedure SP_Tilemap_Clear(TileMapID: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_TileMap_Draw(TileMapID, OffX, OffY, ToX, ToY, ToW, ToH, RX, RY: Integer; Rotate, Scale: aFloat; Var Error: TSP_ErrorCode);
  Procedure SP_Tilemap_BuildLUT(TileMap: pSP_TileMap_Info);
  Function  SP_GetTile(id, x, y: Integer; Var Error: TSP_ErrorCode): Integer;

Const

  SP_OBJECT_BANK = 0;
  SP_GRAPHIC_BANK = 1;
  SP_FONT_BANK = 2;
  SP_SCREEN_BANK = 3;
  SP_PROGRAM_BANK = 4;
  SP_SAMPLE_BANK = 5;
  SP_SPRITE_BANK = 6;
  SP_TILEMAP_BANK = 7;
  SP_WINDOW_BANK = 8;

  SP_FONT_TYPE_MONO: Byte = 0;
  SP_FONT_TYPE_COLOUR: Byte = 1;
  SP_FONT_TYPE_32BIT: Byte = 2;

Var

  SP_BankList: Array of pSP_Bank;
  GlobSprite: pSP_Sprite_Info;

implementation

Uses SP_Graphics, SP_Sound, SP_Main, SP_BaseComponentUnit;

Procedure SP_ChangeBankSize(Index: Integer);
Begin

  Case SP_BankList[Index]^.DataType Of
    SP_SAMPLE_BANK:
      SP_UpdateSampleSize(SP_BankList[Index]);

    SP_SPRITE_BANK:
      pSP_Sprite_Info(@SP_BankList[Index]^.Info[0])^.Data := @SP_BankList[Index]^.Memory[0];

    SP_GRAPHIC_BANK:
      Begin
        pSP_Graphic_Info(@SP_BankList[Index]^.Info[0])^.Data := @SP_BankList[Index]^.Memory[0];
        If SCREENBANK = -SP_BankList[Index]^.ID Then Begin
          SCREENBANK := -1;
          SP_SetDrawingWindow(0);
        End;
      End;

    SP_TILEMAP_BANK:
      SP_Tilemap_BuildLUT(pSP_TileMap_Info(@SP_BankList[Index]^.Info[0]));
  End;

End;

Function SP_NewBank(Size: LongWord): Integer;
Var
  Done, Found: Boolean;
  Idx, NewID: Integer;
  Bank: pSP_Bank;
Begin

  // Creates a new, empty bank. Not useful at first, as it will be defined as
  // a Binary Object bank with no data attached. To use it, call one of the
  // Specialised creation procedures for the bank type you want.

  // Find a new IndexID for the new bank - usually the first available
  // lowest number. This will be returned after the bank has been created.

  NewID := 0;
  Done := Length(SP_BankList) = 0;
  While Not Done Do Begin
    Found := False;
    For Idx := 0 To Length(SP_BankList) -1 Do Begin
      If SP_BankList[Idx]^.ID = NewID Then Begin
        Inc(NewID);
        Found := True;
        Break;
      End;
    End;
    If Not Found Then
      Done := True;
  End;

  // Now create the bank. Zero-length, must be resized before use.

  Bank := New(pSP_Bank);
  Bank^.ID := NewID;
  SetLength(Bank^.Info, 0);
  SetLength(Bank^.Memory, Size);
  Bank^.DataType := 0;
  Bank^.InfoLength := 0;
  SetLength(SP_BankList, Length(SP_BankList) +1);
  SP_BankList[Length(SP_BankList) -1] := Bank;
  Bank^.Changed := True;
  Bank^.Protection := False;
  Bank^.System := False;

  // And return the ID.

  Result := NewID;
  Inc(NUMBANKS);

End;

Function SP_Bank_Protect(ID: Integer; System: Boolean): Integer;
Begin

  Result := SP_FindBankID(ID);
  If Result >= 0 Then Begin
    SP_BankList[Result]^.Protection := True;
    SP_BankList[Result]^.System := System;
  End;

End;

Function SP_Bank_DeProtect(ID: Integer): Integer;
Begin

  Result := SP_FindBankID(ID);
  If Result >= 0 Then
    If Not SP_BankList[Result]^.System Then
      SP_BankList[Result]^.Protection := False;

End;

Procedure SP_CheckForDeprecatedBanks(Var Bank: pSP_Bank);
Var
  Idx, Idx2: Integer;
  Gfx: SP_Graphic_Info;
  pGfx: pSP_Graphic_Info;
Begin

  // Check for an old bank type here, and convert if necessary. Fonts and
  // graphic banks now have palettes and suchlike attached.

  Case Bank^.ID of
    SP_FONT_BANK:
      Begin

        If Bank^.InfoLength = (SizeOf(Integer) * 4) + (512 * SizeOf(SP_Character_Info)) Then Begin

          // v1 of the Font bank doesn't have a palette attached, so insert the current window's
          // palette now.

          SetLength(Bank^.Info, Bank^.InfoLength + (256 * SizeOf(TP_Colour)));
          Idx := SizeOf(Integer) * 4;
          For Idx2 := 0 To 511 Do Begin
            Bank^.Info[Idx + (256 * SizeOf(TP_Colour))] := Bank^.Info[Idx];
            Inc(Idx);
          End;
          CopyMem(@Bank^.Info[SizeOf(Integer) * 4], @pSP_Window_Info(WINDOWPOINTER)^.Palette[0], 256 * SizeOf(TP_Colour));

        End;

      End;

    SP_GRAPHIC_BANK:
      Begin

        // If the infolength does not match the expected length then try to reconstruct
        // the bank. WindowInfo struct might have changed, or a new field might have been added.

        If Bank^.InfoLength <> SizeOf(SP_Graphic_Info) Then Begin

          pGfx := @Gfx;
          Idx := Length(Bank^.Info) - SizeOf(LongWord);
          Gfx.Data := pByte(pNativeUInt(@Bank^.Info[Idx])^);

          Dec(Idx, SizeOf(Boolean));
          Gfx.winorigin := pBoolean(@Bank^.Info[Idx])^;
          Dec(Idx, SizeOf(Boolean));
          Gfx.winscale := pBoolean(@Bank^.Info[Idx])^;

          Dec(Idx, SizeOf(Integer));
          Gfx.clipy2 := pInteger(@Bank^.Info[Idx])^;
          Dec(Idx, SizeOf(Integer));
          Gfx.clipx2 := pInteger(@Bank^.Info[Idx])^;
          Dec(Idx, SizeOf(Integer));
          Gfx.clipy1 := pInteger(@Bank^.Info[Idx])^;
          Dec(Idx, SizeOf(Integer));
          Gfx.clipx1 := pInteger(@Bank^.Info[Idx])^;

          Dec(Idx, SizeOf(aFloat));
          Gfx.scaley:= paFloat(@Bank^.Info[Idx])^;
          Dec(Idx, SizeOf(aFloat));
          Gfx.scalex:= paFloat(@Bank^.Info[Idx])^;
          Dec(Idx, SizeOf(aFloat));
          Gfx.winscaley:= paFloat(@Bank^.Info[Idx])^;
          Dec(Idx, SizeOf(aFloat));
          Gfx.winscalex:= paFloat(@Bank^.Info[Idx])^;
          Dec(Idx, SizeOf(aFloat));
          Gfx.orgh:= paFloat(@Bank^.Info[Idx])^;
          Dec(Idx, SizeOf(aFloat));
          Gfx.orgw:= paFloat(@Bank^.Info[Idx])^;
          Dec(Idx, SizeOf(aFloat));
          Gfx.orgy:= paFloat(@Bank^.Info[Idx])^;
          Dec(Idx, SizeOf(aFloat));
          Gfx.orgx:= paFloat(@Bank^.Info[Idx])^;

          Dec(Idx, SizeOf(Word));
          Gfx.Transparent:= pWord(@Bank^.Info[Idx])^;

          Dec(Idx, SizeOf(LongWord));
          Gfx.Height:= pLongWord(@Bank^.Info[Idx])^;
          Dec(Idx, SizeOf(LongWord));
          Gfx.Width:= pLongWord(@Bank^.Info[Idx])^;

          If Idx > 0 Then
            CopyMem(@Gfx.Palette[0], @Bank^.Info[0], 256 * SizeOf(TP_Colour))
          Else
            If WINDOWPOINTER = nil Then
              CopyMem(@Gfx.Palette[0], @DefaultPalette[0], 256 * SizeOf(TP_Colour))
            Else
              CopyMem(@Gfx.Palette, @pSP_Window_Info(WINDOWPOINTER)^.Palette[0], 256 * SizeOf(TP_Colour));

          Gfx.Depth := 8;
          SP_GFX_UpdateWindowInfo(pGfx, Bank);

          SetLength(Bank^.Info, SizeOf(SP_Graphic_Info));
          CopyMem(@Gfx.Palette[0], @Bank^.Info[0], SizeOf(SP_Graphic_Info));

        End;

      End;

  End;

  Bank^.InfoLength := Length(Bank^.Info);

End;

Function SP_LoadBank(Filename: aString; BankNum: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Idx, FileID, BankID, NewID: Integer;
  DataLen: LongWord;
  Bank: pSP_Bank;
  tBuf: aString;
  Sprite: pSP_Sprite_Info;
  TileMap: pSP_TileMap_Info;
  Magic: Array of Byte;
Begin

  // Load a binary file into the specified bank. If the bank does not exist, it will be created,
  // with the ID number specified. If the number specified is -1, then a new bank will be created
  // and the number returned will be used to load the bank. The bank should have been saved previously
  // by the SaveBank() procedure, so will have the magic number - check for that now.

  // If the file has not been saved as a bank (ie, it's a raw binary data file) then the bank is set to
  // object format and the file is loaded into the Memory array.

  Result := SP_LoadBankFromText(Filename, BankNum, Error);

  If Error.Code <> SP_ERR_OK Then Begin

    // Legacy bank files

    FileID := SP_FileOpen(Filename, False, Error);
    Result := -1;

    ERRStr := Filename;
    If FileID > -1 Then Begin

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
        BankID := SP_FindBankID(SP_NewBank(0));
      End;

      Result := SP_BankList[BankID].ID;

      tBuf := '';
      SetLength(Magic, 6);
      SP_FileRead(FileID, @Magic[0], 6, Error);
      For Idx := 0 To 5 Do tBuf := tBuf + aChar(Magic[Idx]);
      If tBuf = 'ZXBANK' Then Begin

        Bank := SP_BankList[BankID];

        If Bank^.DataType = SP_SPRITE_BANK Then Begin
          Sprite := @Bank^.Info[0];
          SP_RemoveSpriteFromWindowList(Sprite);
          If Sprite^.Enabled Then Dec(NUMSPRITES);
        End;

        If MOUSEISGRAPHIC And (MOUSESPRITE = Bank^.ID) Then SP_MousePointerFromDefault;

        NewID := Bank^.ID;

        SP_FileRead(FileID, @Bank^.ID, SizeOf(Integer), Error);
        SP_FileRead(FileID, @Bank^.DataType, SizeOf(Integer), Error);
        SP_FileRead(FileID, @Bank^.InfoLength, SizeOf(LongWord), Error);
        SP_FileRead(FileID, @Bank^.Protection, SizeOf(Boolean), Error);
        SetLength(Bank^.Info, Bank^.InfoLength);
        If Bank^.InfoLength > 0 Then
          SP_FileRead(FileID, @Bank^.Info[0], Bank^.InfoLength, Error);
        SP_FileRead(FileID, @DataLen, SizeOf(LongWord), Error);
        SetLength(Bank^.Memory, DataLen);
        If DataLen > 0 Then
          SP_FileRead(FileID, @Bank^.Memory[0], DataLen, Error);
        Bank^.ID := NewID;

        SP_CheckForDeprecatedBanks(Bank);

        Case Bank^.DataType Of

          SP_SAMPLE_BANK:
            SP_Sample_Reallocate(Bank^.ID);

          SP_SPRITE_BANK:
            Begin
              SP_BlockSprites;
              Sprite := @Bank^.Info[0];
              Sprite^.ID := Bank^.ID;
              Sprite^.Data := @Bank^.Memory[0];
              Sprite^.Window := WINDOWPOINTER;
              SetLength(WindowSpriteList[SCREENBANK], Length(WindowSpriteList[SCREENBANK])+1);
              WindowSpriteList[SCREENBANK][Length(WindowSpriteList[SCREENBANK])-1] := Sprite;
              Sprite^.Window^.SpriteCount := Length(WindowSpriteList[SCREENBANK]);
              If Sprite^.Scale = 0 Then Sprite^.Scale := 1;
              Inc(NUMSPRITES);
              SP_UnblockSprites;
            End;

          SP_TILEMAP_BANK:
            Begin
              TileMap := pSP_TileMap_Info(@Bank^.Info[0]);
              SP_Tilemap_BuildLUT(TileMap);
            End;

          SP_GRAPHIC_BANK:
            pSP_Graphic_Info(@Bank^.Info[0])^.Data := @Bank^.Memory[0];

        End;

        SP_FileClose(FileID, Error);

      End Else Begin

        Bank := SP_BankList[BankID];
        Bank^.DataType := SP_OBJECT_BANK;
        Bank^.InfoLength := 0;
        SetLength(Bank^.Info, 0);
        SetLength(Bank^.Memory, SP_FileSize(FileID, Error));
        SP_FileSeek(FileID, 0, Error);
        SP_FileRead(FileID, @Bank^.Memory[0], SP_FileSize(FileID, Error), Error);
        SP_FileClose(FileID, Error);
        Bank^.Changed := True;
        Error.Code := SP_ERR_OK;

      End;
    End Else
      Error.Code := SP_ERR_FILE_MISSING;

  End;

End;

Procedure SP_SaveBank(Filename: aString; BankNum: LongWord; Data: Boolean; Var Error: TSP_ErrorCode);
Begin

  // Now save banks in human-readable format to avoid issues with bank structure changes in the
  // future

  SP_SaveBankAsText(Filename, BankNum, Error);

End;

Procedure SP_DeleteBank(Index: Integer; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Sprite: pSP_Sprite_Info;
Begin

  // Deletes a bank from the bank list - Index is the *list* index, not the
  // Bank ID! After deletion, the Bank's ID number is then available for
  // a new bank to use.

  If Not SP_BankList[Index]^.Protection Then Begin
    If Index < Length(SP_BankList) Then Begin
      DisplaySection.Enter;
      If MOUSEISGRAPHIC And (MOUSESPRITE = SP_BankList[Index]^.ID) Then SP_MousePointerFromDefault;
      If SP_BankList[Index]^.DataType = SP_SAMPLE_BANK Then
        BASS_SampleFree(pSP_Sample_Info(@SP_BankList[Index]^.Info[0])^.Sample);
      If SP_BankList[Index]^.DataType = SP_SPRITE_BANK Then Begin
        Sprite := @SP_BankList[Index]^.Info[0];
        SP_RemoveSpriteFromWindowList(Sprite);
        If Sprite^.Enabled Then Dec(NUMSPRITES);
      End;
      If SCREENBANK = -SP_BankList[Index]^.ID Then Begin
        SCREENBANK := -1;
        SP_SetDrawingWindow(0);
      End;
      If (FocusedWindow = SP_BankList[Index]^.ID) And (SP_BankList[Index]^.DataType = SP_WINDOW_BANK) Then
        SwitchFocusedWindow(pSP_Window_Info(@SP_BankList[Index]^.Info[0])^.PrevWin);

      Dispose(SP_BankList[Index]);
      For Idx := Index To Length(SP_BankList) -2 Do
        SP_BankList[Idx] := SP_BankList[Idx +1];
      SetLength(SP_BankList, Length(SP_BankList) -1);
      Dec(NUMBANKS);
      If SIGSAMPLEBANK > Index Then Dec(SIGSAMPLEBANK);
      If EDITORFONT > Index Then Dec(EDITORFONT);
      If SYSFONT > Index Then Dec(SYSFONT);
      If CLICKBANK > Index Then Dec(CLICKBANK);
      If OKSNDBANK > Index Then Dec(OKSNDBANK);
      If ERRSNDBANK > Index Then Dec(ERRSNDBANK);
      If FONTBANKID > Index Then Dec(FONTBANKID);
      DisplaySection.Leave;

    End;
  End Else
    Error.Code := SP_ERR_BANK_PROTECTED;

End;

Procedure SP_DeleteAllBanks(SystemToo: Boolean);
Var
  Idx, i: Integer;
  Sprite: pSP_Sprite_Info;
Begin

  DisplaySection.Enter;
  // Use with caution - will remove all banks, including system banks.
  // Intended as a nice way to clear up memory when quitting SpecBAS.
  If Not SystemToo Then Begin
    Idx := 0;
    While Idx < Length(SP_BankList) Do Begin
      If Not SP_BankList[Idx].System Then Begin
        If MOUSEISGRAPHIC And (MOUSESPRITE = SP_BankList[Idx]^.ID) Then SP_MousePointerFromDefault;
        If SP_BankList[Idx]^.DataType = SP_SAMPLE_BANK Then
          BASS_SampleFree(pSP_Sample_Info(@SP_BankList[Idx]^.Info[0])^.Sample);
        If SP_BankList[Idx]^.DataType = SP_SPRITE_BANK Then Begin
          Sprite := @SP_BankList[Idx]^.Info[0];
          SP_RemoveSpriteFromWindowList(Sprite);
          If Sprite^.Enabled Then Dec(NUMSPRITES)
        End;
        Dispose(SP_BankList[Idx]);
        For i := Idx To Length(SP_BankList) -2 Do
          SP_BankList[i] := SP_BankList[i +1];
        SetLength(SP_BankList, Length(SP_BankList) -1);
        Dec(NUMBANKS);
      End Else
        Inc(Idx);
    End;
  End Else Begin
    DISPLAYPOINTER := Nil;
    NUMBANKS := 0;
    NUMSPRITES := 0;
    For Idx := 0 To Length(SP_BankList) -1 Do
      Dispose(SP_BankList[Idx]);
    SetLength(SP_BankList, 0);
  End;
  DisplaySection.Leave;

End;

Procedure SP_ClearBank(Index: Integer; Var Error: TSP_ErrorCode);
Var
  Bank: pSP_Bank;
Begin

  // Removes the data from the specified bank.

  Bank := SP_BankList[Index];

  If Bank^.Protection Then Begin
    Error.Code := SP_ERR_BANK_PROTECTED;
    Exit;
  End;

  If SCREENBANK = -Bank^.ID Then Begin
    SCREENBANK := -1;
    SP_SetDrawingWindow(0);
  End;

  SetLength(Bank^.Memory, 0);
  Bank^.Changed := True;

  If MOUSEISGRAPHIC And (MOUSESPRITE = Bank^.ID) Then SP_MousePointerFromDefault;

  If Bank^.DataType = SP_SAMPLE_BANK Then
    SP_UpdateSampleSize(Bank);

  If Bank^.DataType = SP_SPRITE_BANK Then Begin
    DisplaySection.Enter;
    pSP_Sprite_Info(@Bank^.Info[0])^.Data := nil;
    pSP_Sprite_Info(@Bank^.Info[0])^.NumFrames := 0;
    DisplaySection.Leave;
  End;

End;

Procedure SP_CopyBank(Source, Dest: Integer; Var Error: TSP_ErrorCode);
Var
  Src, Dst: Integer;
  Sprite: pSP_Sprite_Info;
Begin

  // Copy from one Bank ID to another. The Destination doesn't have to exist -
  // it will be created if necessary.

  Src := SP_FindBankID(Source);
  If Src >= 0 Then Begin

    Dst := SP_FindBankID(Dest);
    If Dst = SP_ERR_BANK_ID_NOT_FOUND Then Begin

      // Create the bank, as that ID doesn't exist

      Dst := SP_FindBankID(SP_NewBank(0));
      SP_BankList[Dst].ID := Dest;

    End Else Begin

      If SP_BankList[Dst]^.Protection Then Begin
        Error.Code := SP_ERR_BANK_PROTECTED;
        Exit;
      End;

      If MOUSEISGRAPHIC And (MOUSESPRITE = SP_BankList[Dst]^.ID) Then SP_MousePointerFromDefault;
      If SP_BankList[Dst]^.DataType = SP_SAMPLE_BANK Then
        BASS_SampleFree(pSP_Sample_Info(@SP_BankList[Dst]^.Info[0])^.Sample);
      If SP_BankList[Dst]^.DataType = SP_SPRITE_BANK Then Begin
        Sprite := @SP_BankList[Dst]^.Info[0];
        SP_RemoveSpriteFromWindowList(Sprite);
        If Sprite^.Enabled Then Dec(NUMSPRITES);
      End;
      If SCREENBANK = -SP_BankList[Dst]^.ID Then SP_SetDrawingWindow(0);

    End;

    SP_BankList[Dst]^.DataType := SP_BankList[Src]^.DataType;
    SP_BankList[Dst]^.InfoLength := SP_BankList[Src]^.InfoLength;
    SetLength(SP_BankList[Dst]^.Info, Length(SP_BankList[Src]^.Info));
    CopyMem(@SP_BankList[Dst]^.Info[0], @SP_BankList[Src]^.Info[0], Length(SP_BankList[Src]^.Info));
    SetLength(SP_BankList[Dst]^.Memory, Length(SP_BankList[Src]^.Memory));
    CopyMem(@SP_BankList[Dst]^.Memory[0], @SP_BankList[Src]^.Memory[0], Length(SP_BankList[Src]^.Memory));
    If SP_BankList[Dst]^.DataType = SP_SAMPLE_BANK Then
      SP_Sample_Reallocate(Dest);

    // If the source was a sprite then we need to increment the sprite count!

    If SP_BankList[Dst]^.DataType = SP_SPRITE_BANK Then Begin
      DisplaySection.Enter;
      Sprite := @SP_BankList[Dst]^.Info[0];
      If Sprite^.Enabled Then Inc(NUMSPRITES);
      DisplaySection.Leave;
    End;

    SP_ChangeBankSize(Dst);
    SP_BankList[Dst]^.Changed := True;

  End;

End;

Procedure SP_CopyBankEx(SrcID, Start, Len, DstID, Offset: Integer; Var Error: TSP_ErrorCode);
Var
  sIdx, dIdx: Integer;
  sBank, dBank: pSP_Bank;
  Buffer: Array of Byte;
Begin

  sIdx := SP_FindBankID(SrcID);
  If sIdx >= 0 Then Begin
    dIdx := SP_FindBankID(DstID);
    If dIdx >= 0 Then Begin
      sBank := SP_BankList[sIdx];
      dBank := SP_BankList[dIdx];
      If Start + Len -1 >= Length(sBank^.Memory) Then
        Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE
      Else Begin
        SetLength(Buffer, Len);
        CopyMem(@Buffer[0], @sBank^.Memory[Start], Len);
        If Length(dBank^.Memory) < Offset + Len Then Begin
          SetLength(dBank^.Memory, Offset + Len);
        End;
        CopyMem(@dBank^.Memory[Offset], @Buffer[0], Len);
        dBank^.Changed := True;
        If SP_BankList[dIdx]^.DataType = SP_SAMPLE_BANK Then
          SP_Sample_Reallocate(dBank^.ID);
        SP_ChangeBankSize(dIdx);
      End;
    End Else
      Error.Code := SP_ERR_BANK_NOT_FOUND;
  End Else
    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_ResizeBank(Index, NewSize: Integer);
Var
  CurSize, Idx: Integer;
Begin

  // Shrinks or grows (non-destructively in the "growing") a bank, specified by
  // the Index. Growing a bank fills the new free space with 0s.

  If SP_BankList[Index]^.DataType = SP_SPRITE_BANK Then
    DisplaySection.Enter;
  CurSize := Length(SP_BankList[Index]^.Memory);
  SetLength(SP_BankList[Index]^.Memory, NewSize);

  If CurSize < NewSize Then
    For Idx := CurSize To NewSize -1 Do
      SP_BankList[Index]^.Memory[Idx] := 0;
  SP_BankList[Index]^.Changed := True;

  If SCREENBANK = -SP_BankList[Index]^.ID Then SP_SetDrawingWindow(0);

  SP_ChangeBankSize(Index);
  If SP_BankList[Index]^.DataType = SP_SPRITE_BANK Then
    DisplaySection.Leave;

End;

Function  SP_FindBankID(ID: Integer): Integer; inline;
Var
  Idx: Integer;
Begin

  // Finds the index in the banklist of a particular ID. Returns an error if the
  // BankID does not exist.

  If ID = 0 Then
    Result := 0
  Else Begin
    Idx := 0;
    While Idx < Length(SP_BankList) Do Begin
      If SP_BankList[Idx]^.ID = ID Then Begin
        Result := Idx;
        Exit;
      End;
      Inc(Idx);
    End;
    Result := SP_ERR_BANK_ID_NOT_FOUND;
  End;

End;

Function SP_GetBankPointer(ID: Integer): pByte;
Var
  Idx: Integer;
Begin

  // Returns a pointer to the memory held in a bank, specified by the BankID.

  Result := nil;
  Idx := SP_FindBankID(ID);
  If Idx <> SP_ERR_BANK_ID_NOT_FOUND Then
    Result := @SP_BankList[Idx]^.Memory[0];

End;

Function SP_GetBankSize(ID: Integer): Integer;
Var
  Idx: Integer;
Begin

  Result := SP_ERR_BANK_ID_NOT_FOUND;
  Idx := SP_FindBankID(ID);
  If Idx <> SP_ERR_BANK_ID_NOT_FOUND Then
    Result := Length(SP_BankList[Idx]^.Memory);

End;

Function SP_Font_Bank_Create(FontType, Width, Height, Transparent: Integer): Integer;
Var
  Bank: pSP_Bank;
  FontBank: pSP_Font_Info;
  Idx, CharSize: Integer;
Begin

  // Creates a new Font Bank. The result is either the new bank's ID, or -1
  // if the bank failed to create.

  Result := SP_FindBankID(SP_NewBank(1));

  If Result > -1 Then Begin

    Bank := SP_BankList[Result];
    Bank^.DataType := SP_FONT_BANK;

    // Create a table of 122 character info records

    SetLength(Bank^.Info, SizeOf(SP_Font_Info));
    Bank^.InfoLength := Length(Bank^.Info);
    FontBank := @Bank^.Info[0];
    FontBank^.FontType := FontType;
    FontBank^.Width := Width;
    FontBank^.Height := Height;
    FontBank^.Transparent := Transparent;

    // Fill the palette with the current window's palette

    If WINDOWPOINTER <> nil Then
      CopyMem(@FontBank^.Palette[0], @pSP_Window_Info(WINDOWPOINTER)^.Palette[0], 256 * SizeOf(TP_Colour))
    Else
      CopyMem(@FontBank^.Palette[0], @DefaultPalette[0], 256 * SizeOf(TP_Colour));

    // And make sure all the records point to character data.

    If FontBank^.FontType = SP_FONT_TYPE_32BIT Then
      CharSize := Width * Height * SizeOf(LongWord)
    Else
      CharSize := Width * Height;
    SetLength(Bank^.Memory, 256 * CharSize);
    For Idx := 0 To 255 Do
      FontBank^.Font_Info[Idx].Data := CharSize * Idx;

    Bank^.Changed := True;
    Result := Bank^.ID;

  End;

End;

Function SP_SetSpeccyStyleChar(ID, Character: Integer; Data: pByte): Integer;
Var
  Dst: pByte;
  Bank: pSP_Bank;
  FontBank: pSP_Font_Info;
  LineCount: Integer;
  ByteVal, Bit: Byte;
Begin

  Result := SP_FindBankID(ID);

  If Result >= 0 Then Begin
    Bank := SP_BankList[Result];
    If Character > 255 Then
      Result := SP_ERR_CHAR_OUT_OF_RANGE
    Else Begin
      If SP_BankList[Result]^.DataType = SP_FONT_BANK Then Begin
        FontBank := @Bank^.Info[0];
        Bank^.Changed := True;
        Dst := @Bank^.Memory[FontBank^.Font_Info[Character].Data];
        LineCount := 8;
        While LineCount > 0 Do Begin
          ByteVal := Data^;
          Bit := 128;
          While Bit > 0 Do Begin
            If ByteVal And Bit > 0 Then
              Dst^ := 1
            Else
              Dst^ := 0;
            Bit := Bit Shr 1;
            Inc(Dst);
          End;
          Inc(Data);
          Dec(LineCount);
        End;
      End;
    End;
  End;

End;

Function SP_Font_Bank_SetChar(ID: Integer; Character: Integer; Data: pByte; Invert: Boolean = False): Integer;
Var
  Bank: pSP_Bank;
  CharSize, i: Integer;
  FontBank: pSP_Font_Info;
Begin

  // Inserts character pixel data for the specified character.
  // Characters have to be specified as a numeric code (starting at 0, but only
  // values of 32 to 153 are used) because UDGs cannot be typed on a PC keyboard.

  Result := SP_FindBankID(ID);

  If Result >= 0 Then Begin
    Bank := SP_BankList[Result];
    If Character > 255 Then
      Result := SP_ERR_CHAR_OUT_OF_RANGE
    Else Begin
      If SP_BankList[Result]^.DataType = SP_FONT_BANK Then Begin
        FontBank := @Bank^.Info[0];
        If FontBank^.FontType = SP_FONT_TYPE_32BIT Then
          CharSize := FontBank^.Width * FontBank^.Height * SizeOf(LongWord)
        Else
          CharSize := FontBank^.Width * FontBank^.Height;
        i := FontBank^.Font_Info[Character].Data;
        CopyMem(@Bank^.Memory[FontBank^.Font_Info[Character].Data], Data, CharSize);
        If Invert And (FontBank^.FontType = SP_FONT_TYPE_MONO) Then
          For i := i To i + CharSize -1 Do
            Bank^.Memory[i] := 1 - Bank^.Memory[i];
        Bank^.Changed := True;
      End Else Begin
        Result := SP_ERR_BANK_INVALID_FORMAT;
      End;
    End;
  End;

End;

Procedure SP_SetSystemFont(BankID: Integer; Error: TSP_ErrorCode);
Var
  Index: Integer;
  FontBank: pSP_Font_Info;
Begin

  Index := SP_FindBankID(BankID);
  Error.Code := SP_ERR_OK;

  If Index >= 0 Then Begin

    If SP_BankList[Index]^.DataType = SP_FONT_BANK Then Begin

      FontBank := @SP_BankList[Index]^.Info[0];

      FONTBANKID := BankID;
      FONTWIDTH := FontBank^.Width;
      FONTHEIGHT := FontBank^.Height;
      FONTTRANSPARENT := FontBank^.Transparent;
      FONTTYPE := FontBank^.FontType;

      TABSIZE := (SCREENWIDTH Div Integer(FONTWIDTH)) Div 2;

    End Else
      Error.Code := SP_ERR_INVALID_BANK;

  End Else
    Error.Code := SP_ERR_BANK_NOT_FOUND;

  If (BankID <> SYSFONT) and (Error.Code <> SP_ERR_OK) Then
    SP_SetSystemFont(SYSFONT, Error);

End;

Function SP_Screen_Bank_Create(Width, Height: Integer): Integer;
Var
  Bank: pSP_Bank;
  Idx: Integer;
  ScreenBank: pSP_Bank_Screen;
Begin

  DisplaySection.Enter;

  Result := SP_FindBankID(SP_NewBank(0));

  If Result > -1 Then Begin

    Bank := SP_BankList[Result];
    Bank^.DataType := SP_SCREEN_BANK;

    SetLength(Bank^.Info, SizeOf(LongWord) + (256 * SizeOf(TP_Colour)));
    Bank^.InfoLength := Length(Bank^.Info);
    ScreenBank := @Bank^.Info[0];

    For Idx := 0 To 255 Do
      ScreenBank^.Palette[Idx] := DefaultPalette[Idx];

    ScreenBank^.NumWindows := 0;
    WINDOWPOINTER := nil;
    Bank^.Changed := True;
    Result := Bank^.ID;

  End;

  DisplaySection.Leave;

End;

Procedure SP_SetWindowDefaults(Bank: pSP_Bank; Window: pSP_Window_Info; Left, Top, Width, Height, TransIdx, Bpp, Alpha: Integer);
Var
  Pal: pPalArray;
Begin

  DisplaySection.Enter;

  If NUMWINDOWS = 0 then
    Pal := @DefaultPalette[0]
  Else
    If WINDOWPOINTER = nil Then
      Pal := @pSP_Bank_Screen(@Bank^.Info[0])^.Palette[0]
    Else
      Pal := @pSP_Window_Info(WINDOWPOINTER)^.Palette[0];

  Window^.Left := Left;
  Window^.Top := Top;
  Window^.Width := Width;
  Window^.Height := Height;
  Window^.Stride := Width * (Bpp Div 8);
  Window^.Visible := True;
  Window^.FontBankID := -1;
  Window^.Ink := CINK;
  Window^.Paper := CPAPER;
  Window^.Inverse := CINVERSE;
  Window^.Over := COVER;
  Window^.Transparent := Word(TransIDX);
  Window^.pr_posx := 0;
  Window^.pr_posy := 0;
  Window^.dr_posx := 0;
  Window^.dr_posy := 0;
  Window^.GWScale := 1;
  Window^.heading := 0;
  Window^.Scrollcnt := 0;
  Window^.orgx := 0;
  Window^.orgy := 0;
  Window^.orgw := Width;
  Window^.orgh := Height;
  Window^.clipx1 := 0;
  Window^.clipy1 := 0;
  Window^.clipx2 := Width;
  Window^.clipy2 := Height;
  WIndow^.scalex := CSCALEX;
  Window^.scaley := CSCALEY;
  Window^.winscale := False;
  Window^.winorigin := False;
  Window^.Flip := False;
  Window^.SpriteCount := 0;
  Window^.bpp := Bpp;
  Window^.AlphaEnabled := Alpha = 1;
  Window^.FontTrans := False;
  Window^.CaptionHeight := 0;
  If Assigned(Window^.Component) then
    Window^.Component.Free;
  Window^.Component := SP_BaseComponent.Create(Nil);
  Window^.Component.WindowID := Bank^.ID;
  Window^.ID := Bank^.ID;

  CopyMem(@Window^.Palette[0], Pal, SizeOf(TP_Colour) * 256);

  DisplaySection.Leave;

End;

Procedure SwitchFocusedWindow(ID: Integer);
Begin
  FocusedWindow := ID;
End;

Function SP_Add_Window(Left, Top, Width, Height, TransIdx, Bpp, Alpha: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Idx: Integer;
  Bank: pSP_Bank;
  dPtr: pLongWord;
  Window: pSP_Window_Info;
Begin

  DisplaySection.Enter;

  Result := SP_FindBankID(SP_NewBank(0));

  Bank := SP_BankList[Result];
  SetLength(Bank^.Info, SizeOf(SP_Window_Info));
  Bank^.InfoLength := SizeOf(SP_Window_Info);
  Bank^.DataType := SP_WINDOW_BANK;
  Window := @Bank^.Info[0];

  SP_SetWindowDefaults(Bank, Window, Left, Top, Width, Height, TransIdx, Bpp, Alpha);
  Window^.PrevWin := FocusedWindow;
  SwitchFocusedWindow(Bank^.ID);

  If Window^.bpp in [8, 32] Then Begin

    SetLength(Bank^.Memory, (Window^.Width * Window^.Height * (Window^.bpp Div 8)));
    Window^.Surface := @Bank^.Memory[0];

    If Window^.bpp = 32 Then
      If Window^.AlphaEnabled Then Begin
        dPtr := @Bank^.Memory[0];
        For Idx := 1 To Window^.Width * Window^.Height Do Begin
          dPtr^ := $FF000000;
          Inc(dPtr);
        End;
      End;

    SCREENBANK := -1;
    SP_SetDrawingWindow(Bank^.ID);

    SP_BlockSprites;
    If Bank^.ID < Length(WindowSpriteList) Then
      SetLength(WindowSpriteList[Bank^.ID], 0)
    Else Begin
      While Bank^.ID >= Length(WindowSpriteList) Do
        SetLength(WindowSpriteList, Length(WindowSpriteList) +1);
      SetLength(WindowSpriteList[Bank^.ID], 0);
    End;
    SP_UnBlockSprites;

  End Else
    Error.Code := SP_ERR_INVALID_DEPTH;

  Bank^.Changed := True;
  Result := Bank^.ID;

  Inc(NUMWINDOWS);

  DisplaySection.Leave;

End;

Function  SP_Program_Bank_Create(Name: aString): Integer;
Var
  Bank: pSP_Bank;
  Bank_Prog: pSP_Program_Info;
Begin

  Result := SP_FindBankID(SP_NewBank(0));

  Bank := SP_BankList[Result];
  SetLength(Bank^.Info, SizeOf(SP_Program_Info));
  Bank^.InfoLength := SizeOf(SP_Program_Info);
  Bank^.DataType := SP_PROGRAM_BANK;
  Bank_Prog := @Bank^.Info[0];
  Bank_Prog^.Size := 0;
  Bank_Prog^.NameLen := Length(Name);
  Bank_Prog^.Name := Name;
  Bank_Prog^.NumLines := 0;
  Bank^.Changed := True;
  Result := Bank^.ID;

End;

Procedure SP_AddLine(BankID: Integer; Line: aString; Var Error: TSP_ErrorCode);
Var
  Tokens: aString;
  Position: Integer;
Begin

  // Adds a plain-text line to the program bank. First, tokenise.

  Tokens := SP_TokeniseLine(Line, False, True);

  // Then append the RPN-alike version of the line

  SP_Convert_ToPostFix(Tokens, Position, Error);

  If Error.Code = SP_ERR_OK Then

    // Now insert (or overwrite) the line at the appropriate position.

    SP_AddTokenisedLine(BankID, Tokens, Error);

End;

Procedure SP_AddTokenisedLine(BankID: Integer; Tokens: aString; Var Error: TSP_ErrorCode);
Var
  Bank: pSP_Bank;
  LineNum: LongWord;
  Idx, rIdx, TokenLen: Integer;
  LineInfo: pSP_LineInfo;
Begin

  // Check for a valid program bank

  Idx := SP_FindBankID(BankID);

  If Idx > -1 Then Begin

    // Get Line Number.

    If Tokens[1] = aChar(SP_LINE_NUM) Then Begin

      LineNum := pLongWord(@Tokens[2])^;

      Bank := SP_BankList[Idx];
      If Bank^.DataType = SP_PROGRAM_BANK Then Begin

        // Find the line number in the bank, if it exists, and if so - delete it.

        Idx := SizeOf(SP_Program_Info);
        While Idx < integer(Bank^.InfoLength) Do Begin
          If pSP_LineInfo(@Bank^.Info[Idx])^.LineNum = LineNum Then Begin
            SP_DeleteLine(BankID, pSP_LineInfo(@Bank^.Info[Idx])^.LineNum, Error);
            Break;
          End;
          Inc(Idx, SizeOf(SP_LineInfo));
        End;

        // Now find either the line that has a higher line number, or the end of the
        // program.

        rIdx := SizeOf(SP_Program_Info);
        While rIdx < integer(Bank^.InfoLength) Do Begin
          If pSP_LineInfo(@Bank^.Info[rIdx])^.LineNum > LineNum Then
            Break;
          Inc(rIdx, SizeOf(SP_LineInfo));
        End;
        LineInfo := @Bank^.Info[rIdx];

        // Increase the bank's memory array by the size of the new line

        TokenLen := Length(Tokens);
        SetLength(Bank^.Memory, Length(Bank^.Memory) + TokenLen);

        // Now move the entire program from this point onwards to the new end of the memory array

        Idx := Length(Bank^.Memory)-1;
        While Idx >= integer(LineInfo^.Offset) + TokenLen Do Begin
          Bank^.Memory[Idx] := Bank^.Memory[Idx - TokenLen];
          Dec(Idx);
        End;
        Bank^.Changed := True;

        // Finally Add a record to the Info array, and shift all the records from here up by one

        Idx := Length(Bank^.Info);
        SetLength(Bank^.Info, Bank^.InfoLength + SizeOf(SP_LineInfo));
        While Idx > rIdx Do Begin
          CopyMem(@Bank^.Info[Idx], @Bank^.Info[Idx - SizeOf(SP_LineInfo)], SizeOf(SP_LineInfo));
          Inc(pSP_LineInfo(@Bank^.Info[Idx])^.Offset, TokenLen);
          Dec(Idx, SizeOf(SP_LineInfo));
        End;

        // Now finally populate the new info record. Offset should already be set.

        pSP_LineInfo(@Bank^.Info[rIdx])^.LineNum := LineNum;
        pSP_LineInfo(@Bank^.Info[rIdx])^.LineLen := TokenLen;

      End Else
        Error.Code := SP_ERR_INVALID_BANK;

    End Else
      Error.Code := SP_ERR_SYNTAX_ERROR;

  End Else
    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_DeleteLine(BankID, LineNum: Integer; Var Error: TSP_ErrorCode);
Var
  Idx, mIdx, eIdx: Integer;
  Bank: pSP_Bank;
  LineLen: LongWord;
Begin

  // Removes a line from the specified bank.
  // Check for a valid program bank

  Idx := SP_FindBankID(BankID);

  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];

    // Now find the line number - exact match only.

    Idx := SP_FindLineBank(BankID, LineNum);
    If Idx > -1 Then Begin

      // Delete the line from the Bank's Memory Array.

      LineLen := pSP_LineInfo(@Bank^.Info[Idx])^.LineLen;
      mIdx := pSP_LineInfo(@Bank^.Info[Idx])^.Offset;
      eIdx := mIdx + integer(LineLen);
      While mIdx < eIdx Do Begin
        Bank^.Memory[mIdx] := Bank^.Memory[longword(mIdx) + LineLen];
        Inc(mIdx);
      End;
      SetLength(Bank^.Memory, Length(Bank^.Memory) - integer(LineLen));

      // Finally, remove the info from the info array.

      While Idx < integer(Bank^.InfoLength) - SizeOf(SP_LineInfo) Do Begin
        Bank^.Info[Idx] := Bank^.Info[Idx + SizeOf(SP_LineInfo)];
        Inc(Idx);
      End;

      SetLength(Bank^.Info, Bank^.InfoLength - SizeOf(SP_LineInfo));
      Bank^.InfoLength := Length(Bank^.Info);
      Bank^.Changed := True;

    End Else
      Error.Code := SP_ERR_LINE_NOT_FOUND;

  End Else
    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Function  SP_FindLineBank(BankID, LineNum: Integer): Integer;
Var
  Idx: Integer;
  Bank: pSP_Bank;
Begin

  // Returns the line's position within the info array, where you can
  // read info about where the line resides in the bank's memory.

  Result := -1;

  // Check for a valid program bank

  Idx := SP_FindBankID(BankID);

  If Idx > -1 Then Begin
    Bank := SP_BankList[Idx];
    Idx := SizeOf(SP_Program_Info);
    While Idx < integer(Bank^.InfoLength) Do Begin
      If pSP_LineInfo(@Bank^.Info[Idx])^.LineNum = LongWord(LineNum) Then Begin
        Result := Idx;
        Exit;
      End;
      Inc(Idx, SizeOf(SP_LineInfo));
    End;
  End;

End;

Function SP_FindStatement(BankID, LineNum, Statement: Integer): Integer;
Begin

  // Returns an offset to the statement in the p-code section of the line.

  Result := -1;

End;

Function SP_New_Sprite(X, Y: aFloat; Collide: Boolean; Over, Wrap, CopyFrom: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  Result := -1;
  If SCREENBANK < 0 Then Begin
    Error.Code := SP_ERR_INVALID_WINDOW;
    Exit;
  End;

  Result := SP_FindBankID(SP_NewBank(0));
  Bank := SP_BankList[Result];

  If CopyFrom = -1 Then Begin

    SetLength(Bank^.Info, SizeOf(SP_Sprite_Info));
    Bank^.InfoLength := SizeOf(SP_Sprite_Info);
    Bank^.DataType := SP_SPRITE_BANK;
    Sprite := @Bank^.Info[0];
    Sprite^.X := X;
    Sprite^.Y := Y;
    Sprite^.NumFrames := 0;
    Sprite^.Window := WINDOWPOINTER;
    Sprite^.Enabled := False;
    Sprite^.Data := nil;
    Sprite.ID := Result;
    Sprite^.FrameCounter := 0;
    Sprite^.DstTime := 0;
    Sprite^.Angle := 0;
    Sprite^.DstAngle := 0;
    Sprite^.AngleTime := 0;
    Sprite^.Scale := 1;
    Sprite^.ScaleTime := 0;
    Sprite^.NumClones := 0;
    Sprite^.AnimStart := 0;
    Sprite^.AnimEnd := 0;
    Sprite^.AnimMode := 0;
    Sprite^.AnimDelta := 1;
    Sprite^.CanCollide := Collide;
    If Wrap >= 0 Then Sprite^.WrapMode := Wrap Else Sprite^.WrapMode := 0;
    If Over >= 0 Then Sprite^.OverMode := Over Else Sprite^.OverMode := Sprite^.Window^.Over;

  End Else Begin

    // Copy the sprite from another bank.

    If SP_BankList[SP_FindBankID(CopyFrom)]^.DataType <> SP_SPRITE_BANK Then Begin

      Error.Code := SP_ERR_INVALID_BANK;
      Exit;

    End Else Begin

      SP_CopyBank(CopyFrom, Result, Error);
      If Error.Code = SP_ERR_OK Then Begin

        Sprite := @Bank^.Info[0];

        Sprite^.X := X;
        Sprite^.Y := Y;

        Sprite.ID := Result;
        If Collide Then Sprite^.CanCollide := Collide;
        If Wrap >= 0 Then Sprite^.WrapMode := Wrap;
        If Over >= 0 Then Sprite^.OverMode := Over;

      End Else Begin

        Exit;

      End;

    End;

  End;

  // Add the sprite to the current window, the user can change that later if they wish

  DisplaySection.Enter;

  If Length(WindowSpriteList) < SCREENBANK +1 then
    SetLength(WindowSpriteList, SCREENBANK +1);

  SetLength(WindowSpriteList[SCREENBANK], Length(WindowSpriteList[SCREENBANK])+1);
  WindowSpriteList[SCREENBANK][Length(WindowSpriteList[SCREENBANK])-1] := Sprite;
  Sprite^.Window^.SpriteCount := Length(WindowSpriteList[SCREENBANK]);

  Bank^.Changed := True;
  Result := Bank^.ID;

  DisplaySection.Leave;

End;

Function  SP_FindSpriteID(ID: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Idx: Integer;
Begin

  // Finds the index in the banklist of a particular Sprite ID. Returns an error if the
  // BankID does not exist, or if the bank is not a sprite.

  Result := -1;
  Idx := 0;

  While Idx < Length(SP_BankList) Do Begin
    If SP_BankList[Idx]^.ID = ID Then Begin
      Result := Idx;
      If SP_BankList[Idx]^.DataType <> SP_SPRITE_BANK Then Begin
        Error.Code := SP_ERR_SPRITE_NOT_FOUND;
        Result := -1;
      End;
      Exit;
    End;
    Inc(Idx);
  End;

  Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_SetSpriteHotSpot(Id, X, Y: Integer; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Sprite: pSP_Sprite_Info;
  Bank: pSP_Bank;
Begin

  Idx := SP_FindSpriteID(Id, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    Sprite^.HotSpot := True;
    Sprite^.HotX := X;
    Sprite^.HotY := Y;
  End;

End;

Procedure SP_Sprite_SetOver(Id, Over: Integer; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Sprite: pSP_Sprite_Info;
  Bank: pSP_Bank;
Begin

  Idx := SP_FindSpriteID(Id, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    Sprite^.OverMode := Over;
  End;

End;

Procedure SP_Sprite_SetOrder(Id: Integer; Front: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, sIdx, dIdx: Integer;
  Sprite: pSP_Sprite_Info;
Begin

  DisplaySection.Enter;

  Idx := 0;
  While Idx < Length(WindowSpriteList) Do Begin
    sIdx := 0;
    While sIdx < Length(WindowSpriteList[Idx]) Do Begin
      If WindowSpriteList[Idx][sIdx]^.ID = ID Then Begin
        Sprite := WindowSpriteList[Idx][sIdx];
        If Front Then Begin
          For dIdx := sIdx To Length(WindowSpriteList[Idx]) -2 Do
            WindowSpriteList[Idx][dIdx] := WindowSpriteList[Idx][dIdx +1];
          WindowSpriteList[Idx][Length(WindowSpriteList[Idx]) -1] := Sprite;
        End Else Begin
          For dIdx := sIdx DownTo 1 Do
            WindowSpriteList[Idx][dIdx] := WindowSpriteList[Idx][dIdx -1];
          WindowSpriteList[Idx][0] := Sprite;
        End;
        DisplaySection.Leave;
        Exit;
      End Else
        Inc(sIdx);
    End;
    Inc(Idx);
  End;

  DisplaySection.Leave;

  Error.Code := SP_ERR_SPRITE_NOT_FOUND;

End;

Procedure SP_Sprite_SetOrderMove(Id, Delta: Integer; Var Error: TSP_ErrorCode);
Var
  Idx, sIdx, dIdx, i: Integer;
  Sprite: pSP_Sprite_Info;
Begin

  DisplaySection.Enter;

  Idx := 0;
  While Idx < Length(WindowSpriteList) Do Begin
    sIdx := 0;
    While sIdx < Length(WindowSpriteList[Idx]) Do Begin
      If WindowSpriteList[Idx][sIdx]^.ID = ID Then Begin
        Sprite := WindowSpriteList[Idx][sIdx];
        If Delta > 0 Then Begin
          dIdx := Min(sIdx + Delta, Length(WindowSpriteList[Idx]) -1);
          For i := sIdx To dIdx -1 Do
            WindowSpriteList[Idx][i] := WindowSpriteList[Idx][i +1];
          WindowSpriteList[Idx][dIdx] := Sprite;
        End Else Begin
          dIdx := Max(sIdx - Delta, 0);
          For i := sIdx DownTo dIdx +1 Do
            WindowSpriteList[Idx][i] := WindowSpriteList[Idx][i -1];
          WindowSpriteList[Idx][dIdx] := Sprite;
        End;
        DisplaySection.Leave;
        Exit;
      End Else
        Inc(sIdx);
    End;
    Inc(Idx);
  End;

  DisplaySection.Leave;
  Error.Code := SP_ERR_SPRITE_NOT_FOUND;

End;

Procedure SP_RemoveSpriteFromWindowList(Sprite: pSP_Sprite_Info);
Var
  Idx, Idx2, Idx3: Integer;
Begin

  DisplaySection.Enter;
  SP_BlockSprites;
  For Idx := 0 To Length(WindowSpriteList) -1 Do Begin
    For Idx2 := 0 To Length(WindowSpriteList[Idx]) -1 Do Begin
      If WindowSpriteList[Idx][Idx2]^.ID = Sprite^.ID Then Begin
        For Idx3 := Idx2 To Length(WindowSpriteList[Idx]) -2 Do
          WindowSpriteList[Idx][Idx3] := WindowSpriteList[Idx][Idx3 +1];
        SetLength(WindowSpriteList[Idx], Length(WindowSpriteList[Idx]) -1);
        Sprite^.Window^.SpriteCount := Length(WindowSpriteList[Idx]);
        SP_UnblockSprites;
        DisplaySection.Leave;
        Exit;
      End;
    End;
  End;
  SP_UnblockSprites;
  DisplaySection.Leave;

End;

Procedure SP_SpriteToWindow(Sprite: pSP_Sprite_Info; Window: Integer);
Var
  Idx, Idx2, Idx3: Integer;
  ScrBank: pSP_Bank;
  WindowInfo: pSP_Window_Info;
Label
  ReAssign;
Begin

  // First, find the matching sprite in the window list and remove it

  Idx := SP_FindBankID(Sprite^.Window^.ID);
  ScrBank := SP_BankList[Idx];
  WindowInfo := @ScrBank^.Info[0];

  SP_BlockSprites;

  For Idx := 0 To Length(WindowSpriteList) -1 Do
    For Idx2 := 0 To Length(WindowSpriteList[Idx]) -1 Do
      If WindowSpriteList[Idx][Idx2]^.ID = Sprite^.ID Then Begin
        For Idx3 := Idx2 To Length(WindowSpriteList[Idx]) -2 Do
          WindowSpriteList[Idx][Idx3] := WindowSpriteList[Idx][Idx3 +1];
        SetLength(WindowSpriteList[Idx], Length(WindowSpriteList[Idx]) -1);
        WindowInfo^.SpriteCount := Length(WindowSpriteList[Idx]);
        Goto ReAssign;
      End;

  // Next, add the sprite to the new window list.

  ReAssign:

  If Length(WindowSpriteList) < Window +1 Then
    SetLength(WindowSpriteList, Window +1);
  SetLength(WindowSpriteList[Window], Length(WindowSpriteList[Window]) +1);
  WindowSpriteList[Window][Length(WindowSpriteList[Window])-1] := Sprite;
  WindowInfo^.SpriteCount := Length(WindowSpriteList[SCREENBANK]);

  Sprite^.Window := WindowInfo;
  SP_UnblockSprites;

End;

Procedure SP_Add_Frame(SpriteID: Integer; Graphic: aString; Delay: LongWord; Var Error: TSP_ErrorCode);
Var
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
  Valid: Boolean;
  Idx, tW, tH, Offset: Integer;
Begin

  // Add a graphic frame to the sprite's memory bank.
  // If the graphic isn't a valid GRAB graphic, then make one using the
  // supplied string as a texture.

  Valid := False;
  If Graphic = '' Then
    Error.Code := SP_ERR_INVALID_FRAME
  Else Begin
    If Length(Graphic) > 10 Then Begin
      tW := pLongWord(@Graphic[1])^;
      tH := pLongWord(@Graphic[5])^;
      If Length(Graphic) - 10 = tW * tH Then Begin
        Valid := True;
      End;
    End;
    If Not Valid Then Begin
      Graphic := SP_StringToTexture(Graphic);
      If Graphic = '' Then
        Error.Code := SP_ERR_INVALID_FRAME
      Else
        Valid := True;
    End;
  End;

  If Valid Then Begin

    Graphic := LongWordToString(Delay) + Graphic;

    Idx := SP_FindSpriteID(SpriteID, Error);
    If Error.Code = SP_ERR_OK Then Begin
      Bank := SP_BankList[Idx];
      Sprite := @Bank^.Info[0];

      If Sprite^.Enabled Then
        DisplaySection.Enter;

      Inc(Sprite^.NumFrames);
      If Sprite^.NumFrames = 1 Then
        Sprite^.FrameCounter := Delay;
      Sprite^.AnimEnd := Sprite^.NumFrames -1;
      Offset := Length(Bank^.Memory);
      SetLength(Bank^.Memory, Offset + Length(Graphic));
      CopyMem(@Bank^.Memory[Offset], @Graphic[1], Length(Graphic));
      Sprite^.Data := @Bank^.Memory[0];
      Bank^.Changed := True;

      If Sprite^.Enabled Then
        DisplaySection.Leave;

    End;

  End;

End;

Procedure SP_Add_Frame_Graphic(SpriteID: Integer; BankID: Integer; Delay: LongWord; Var Error: TSP_ErrorCode);
Var
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
  Idx, Offset: Integer;
  Graphic: aString;
Begin

  // Add a graphic frame to the sprite's memory bank from a graphic bank.

  Graphic := LongWordToString(Delay) + SP_GfxBankToString(BankID, Error);

  If Error.Code = SP_ERR_OK Then Begin
    Idx := SP_FindSpriteID(SpriteID, Error);
    If Error.Code = SP_ERR_OK Then Begin
      Bank := SP_BankList[Idx];
      Sprite := @Bank^.Info[0];
      If Sprite^.Enabled Then
        DisplaySection.Enter;
      Inc(Sprite^.NumFrames);
      If Sprite^.NumFrames = 1 Then
        Sprite^.FrameCounter := Delay;
      Sprite^.AnimEnd := Sprite^.NumFrames -1;
      Offset := Length(Bank^.Memory);
      SetLength(Bank^.Memory, Offset + Length(Graphic));
      CopyMem(@Bank^.Memory[Offset], @Graphic[1], Length(Graphic));
      Sprite^.Data := @Bank^.Memory[0];
      Bank^.Changed := True;
      If Sprite^.Enabled Then
        DisplaySection.Leave;
    End;
  End;

End;

Procedure SP_Show_Sprite(SpriteID: Integer; Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  Idx := SP_FindSpriteID(SpriteID, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    If Not Sprite^.Enabled Then Begin
      Sprite^.Enabled := True;
      Inc(NUMSPRITES);
    End;
  End;

End;

Procedure SP_Hide_Sprite(SpriteID: Integer; Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  Idx := SP_FindSpriteID(SpriteID, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    If Sprite^.Enabled Then Begin
      Sprite^.Enabled := False;
      Dec(NUMSPRITES);
    End;
  End;

End;

Procedure SP_GetFrameData(var Sprite: pSP_Sprite_Info; var StrPtr: pByte; var StrLen: Integer; FrameNum: Integer);
Var
  FrameIdx: Integer;
  FrameW, FrameH: LongWord;
Begin

  StrPtr := Nil;
  If (Sprite^.NumFrames > 0) And (FrameNum >= 0) And (FrameNum < Sprite^.NumFrames) Then Begin
    FrameIdx := 0;
    StrPtr := Sprite^.Data;
    Inc(StrPtr, SizeOf(LongWord)); // Skip delay
    FrameW := pLongWord(StrPtr)^;
    Inc(StrPtr, SizeOf(LongWord));
    FrameH := pLongWord(StrPtr)^;
    Inc(StrPtr, SizeOf(LongWord) + SizeOf(Word));
    While FrameIdx <> FrameNum Do Begin
      Inc(FrameIdx);
      Inc(StrPtr, FrameW * FrameH);
      Inc(StrPtr, SizeOf(LongWord));
      FrameW := pLongWord(StrPtr)^;
      Inc(StrPtr, SizeOf(LongWord));
      FrameH := pLongWord(StrPtr)^;
      Inc(StrPtr, SizeOf(LongWord) + SizeOf(Word));
    End;
    Dec(StrPtr, (SizeOf(LongWord) * 3) + SizeOf(Word));
    StrLen := (FrameW * FrameH) + (SizeOf(LongWord) * 3) + SizeOf(Word);
  End;

End;

Function SP_GetFrameAddr(SpriteID, Frame: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  FrameIdx: Integer;
  FrameW, FrameH: LongWord;
  Sprite: pSP_Sprite_Info;
  Idx: Integer;
  StrPtr: pByte;
Begin

  Result := -1;

  Idx := SP_FindSpriteID(SpriteID, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Sprite := @SP_BankList[Idx].Info[0];
    If (Sprite^.NumFrames > 0) And (Frame >= 0) And (Frame < Sprite^.NumFrames) Then Begin
      FrameIdx := 0;
      StrPtr := Sprite^.Data;
      Inc(StrPtr, SizeOf(LongWord));
      FrameW := pLongWord(StrPtr)^;
      Inc(StrPtr, SizeOf(LongWord));
      FrameH := pLongWord(StrPtr)^;
      Inc(StrPtr, SizeOf(LongWord) + SizeOf(Word));
      While FrameIdx < Frame Do Begin
        Inc(FrameIdx);
        Inc(StrPtr, FrameW * FrameH);
        Inc(StrPtr, SizeOf(LongWord));
        FrameW := pLongWord(StrPtr)^;
        Inc(StrPtr, SizeOf(LongWord));
        FrameH := pLongWord(StrPtr)^;
        Inc(StrPtr, SizeOf(LongWord) + SizeOf(Word));
      End;
      Dec(StrPtr, (SizeOf(LongWord) * 3) + SizeOf(Word));
      Result := NativeUInt(StrPtr) - NativeUInt(Sprite^.Data);
    End Else
      Error.Code := SP_ERR_EMPTY_SPRITE;
  End;

End;

Procedure SP_Sprite_SetAnim(SpId, aStart, aEnd, aType: Integer; Var Error: TSP_ErrorCode);
Var
  Sprite: pSP_Sprite_Info;
  Idx, OldAM: Integer;
Begin

  Idx := SP_FindSpriteID(SpId, Error);
  If Error.Code = SP_ERR_OK Then Begin

    Sprite := @SP_BankList[Idx].Info[0];
    OldAM := Sprite^.AnimMode;

    If (aStart = -1) And (aEnd = -1) Then Begin

      // No start or end specified - so assume it's already set previously.
      // If resume_delta is not set then reset it from the stored option.

      Sprite^.AnimDelta := Sprite^.ResumeDelta;

    End Else

      Sprite^.ResumeDelta := 0;

    If (Sprite^.ResumeDelta = 0) or (aType <> -1) Then Begin

      If aType <> -1 Then
        Sprite^.AnimMode := aType;

      Sprite^.AnimStart := Max(0, Min(aStart, aEnd));
      If aEnd = -1 Then
        Sprite^.AnimEnd := Sprite^.NumFrames -1
      Else
        Sprite^.AnimEnd := Min(Sprite^.NumFrames -1, Max(aStart, aEnd));

      Case Sprite^.AnimMode of
        0: // Looping
          Begin
            Sprite^.CurFrame := Sprite^.AnimStart;
            Sprite^.AnimDelta := 1;
            Sprite^.ResumeDelta := 1;
          End;
        1: // Pingpong
          Begin
            Sprite^.CurFrame := Sprite^.AnimStart;
            Sprite^.AnimDelta := 1;
            Sprite^.ResumeDelta := 1;
          End;
        2: // once
          Begin
            Sprite^.CurFrame := Sprite^.AnimStart;
            Sprite^.AnimDelta := 1;
            Sprite^.ResumeDelta := 1;
          End;
        3: // reverse looping
          Begin
            Sprite^.CurFrame := Sprite^.AnimEnd;
            Sprite^.AnimDelta := -1;
            Sprite^.ResumeDelta := -1;
          End;
        4: // reverse Ping-pong
          Begin
            Sprite^.CurFrame := Sprite^.AnimEnd;
            Sprite^.AnimDelta := -1;
            Sprite^.ResumeDelta := -1;
          End;
        5: // reverse once
          Begin
            Sprite^.CurFrame := Sprite^.AnimEnd;
            Sprite^.AnimDelta := -1;
            Sprite^.ResumeDelta := -1;
          End;
      Else
        Begin
          Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
          Sprite^.AnimMode := OldAM;
        End;
      End;

    End;

  End;

End;

Procedure SP_Sprite_Stop_Anim(SpID: Integer; Var Error: TSP_ErrorCode);
Var
  Sprite: pSP_Sprite_Info;
  Idx: Integer;
Begin

  Idx := SP_FindSpriteID(SpId, Error);
  If Error.Code = SP_ERR_OK Then Begin

    Sprite := pSP_Sprite_Info(@SP_BankList[Idx].Info[0]);
    Sprite^.ResumeDelta := Sprite^.AnimDelta;
    Sprite^.AnimDelta := 0;

  End;

End;

Procedure SP_Sprite_Set_Frame(SpID, Frame, Delay: Integer; Var Error: TSP_ErrorCode);
Var
  Sprite: pSP_Sprite_Info;
  Idx, SrcLen: Integer;
  SrcPtr: pByte;
Begin

  Idx := SP_FindSpriteID(SpId, Error);
  If Error.Code = SP_ERR_OK Then Begin

    Sprite := @SP_BankList[Idx].Info[0];

    If (Frame < Sprite^.NumFrames) And (Frame >= 0) Then Begin
      Sprite^.CurFrame := Frame;
      SP_Sprite_Stop_Anim(SpID, Error);
      If Delay >= 0 Then
        Sprite^.FrameCounter := Delay
      Else Begin
        SP_GetFrameData(Sprite, SrcPtr, SrcLen, Sprite^.CurFrame);
        If SrcPtr <> Nil Then
          Sprite^.FrameCounter := pLongWord(SrcPtr)^
        Else
          Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
      End;
    End Else
      Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE;

  End;

End;

Procedure SP_MirrorSprite(SpID: Integer; Var Error: TSP_ErrorCode);
Var
  Sprite: pSP_Sprite_Info;
  SrcPtr: pByte;
  Idx, fW, fH: Integer;
Begin

  Idx := SP_FindSpriteID(SpId, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Sprite := @SP_BankList[Idx].Info[0];
    SrcPtr := Sprite^.Data;
    For Idx := 0 To Sprite^.NumFrames -1 Do Begin
      Inc(SrcPtr, SizeOf(LongWord));
      fW := pLongWord(SrcPtr)^;
      Inc(SrcPtr, SizeOf(LongWord));
      fH := pLongWord(SrcPtr)^;
      Inc(SrcPtr, SizeOf(LongWord) + SizeOf(Word));
      SP_MirrorGfx(SrcPtr, fW, fH);
      Inc(SrcPtr, fW * fH);
    End;
  End;

End;

Procedure SP_FlipSprite(SpID: Integer; Var Error: TSP_ErrorCode);
Var
  Sprite: pSP_Sprite_Info;
  SrcPtr: pByte;
  Idx, fW, fH: Integer;
Begin

  Idx := SP_FindSpriteID(SpId, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Sprite := @SP_BankList[Idx].Info[0];
    SrcPtr := Sprite^.Data;
    For Idx := 0 To Sprite^.NumFrames -1 Do Begin
      Inc(SrcPtr, SizeOf(LongWord));
      fW := pLongWord(SrcPtr)^;
      Inc(SrcPtr, SizeOf(LongWord));
      fH := pLongWord(SrcPtr)^;
      Inc(SrcPtr, SizeOf(LongWord) + SizeOf(Word));
      SP_FlipGfx(SrcPtr, fW, fH);
      Inc(SrcPtr, fW * fH);
    End;
  End;

End;

Procedure SP_PutSpritePermanent(SpID: Integer; Var Error: TSP_ErrorCode);
Var
  SrcPtr, dPtr: pByte;
  Bank: pSP_Bank;
  dX, dY: aFloat;
  Idx, SrcLen, X, Y, CX1, CX2, CY1, CY2, W, H, Mx, wCx, wCy: Integer;
  Sprite: pSP_Sprite_Info;
  Window: pSP_Window_Info;
Begin

  Idx := SP_FindSpriteID(SpId, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Sprite := @SP_BankList[Idx].Info[0];
    Window := Sprite^.Window;
    Idx := SP_FindBankID(Abs(SCREENBANK));
    If Idx > -1 Then Begin
      Bank := SP_BankList[Idx];
      If Bank^.DataType = SP_WINDOW_BANK Then Begin
        dPtr := @Bank^.Memory[0];
        SP_GetFrameData(Sprite, SrcPtr, SrcLen, Sprite^.CurFrame);
        If SrcPtr <> Nil Then Begin
          Inc(SrcPtr, SizeOf(LongWord));
          dX := Sprite^.X - Sprite^.HotX;
          dY := Sprite^.Y - SPrite^.HotY;
          SP_ConvertWToOrigin_d(dX, dY, Window);
          X := Round(dX);
          Y := Round(dY);
          cX1 := Max(Window^.clipx1, 0);
          cY1 := Max(Window^.clipy1, 0);
          cX2 := Min(Window^.Width, Window^.clipx2);
          cY2 := Min(Window^.Height, Window^.clipy2);
          SP_PutSprite(dPtr, X, Y, Sprite^.OverMode, Window^.Paper, $FFFF, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
          If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
          If Sprite^.WrapMode > 0 Then Begin
            W := pLongWord(SrcPtr)^;
            Inc(SrcPtr, SizeOf(LongWord));
            H := pLongWord(SrcPtr)^;
            Dec(SrcPtr, SizeOf(LongWord));
            Mx := Ceil(Sqrt(W*W+H*H) * Sprite^.Scale);
            Case Sprite^.WrapMode of
              1: // Window Wrap
                Begin
                  If X + Mx >= Window^.Width Then Begin
                    SP_PutSprite(dPtr, X - Window^.Width, Y, Sprite^.OverMode, Window^.Paper, $FFFF, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
                    If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
                  End;
                  If Y + Mx >= Window^.Height Then Begin
                    SP_PutSprite(dPtr, X, Y - Window^.Height, Sprite^.OverMode, Window^.Paper, $FFFF, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
                    If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
                  End;
                  If (X + Mx >= Window^.Width) And (Y + Mx >= Window^.Height) Then Begin
                    If Window^.Visible Then SP_PutSprite(dPtr, X - Window^.Width, Y - Window^.Height, Sprite^.OverMode, Window^.Paper, $FFFF, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
                    SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
                  End;
                End;
              2: // Cliprect Wrap
                Begin
                  wcX := Window^.clipx2 - Window^.clipx1;
                  wcY := Window^.clipy2 - Window^.clipy1;
                  If X + Mx >= Window^.clipx2 Then Begin
                    SP_PutSprite(dPtr, X - wCx, Y, Sprite^.OverMode, Window^.Paper, $FFFF, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
                    If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
                  End;
                  If Y + Mx >= Window^.clipy2 Then Begin
                    SP_PutSprite(dPtr, X, Y - wCy, Sprite^.OverMode, Window^.Paper, $FFFF, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
                    If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
                  End;
                  If (X + Mx >= Window^.Width) And (Y + Mx >= Window^.Height) Then Begin
                    SP_PutSprite(dPtr, X - wCx, Y - wCy, Sprite^.OverMode, Window^.Paper, $FFFF, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
                    If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
                  End;
                End;
            End;
          End;
        End Else
          Error.Code := SP_ERR_INVALID_FRAME;
      End Else
        Error.Code := SP_ERR_INVALID_BANK;
    End Else
      Error.Code := SP_ERR_BANK_NOT_FOUND;
  End;

End;

Procedure SP_DrawSprite(dPtr: pByte; var Sprite: pSP_Sprite_Info; var Window: pSP_Window_Info);
Var
  SrcPtr: pByte;
  Delay: LongWord;
  SrcLen, X, Y, Idx, Mx, W, H: Integer;
  cX1, cY1, cX2, cY2, ccX1, ccY1, ccX2, ccY2, wCx, wCy: Integer;
  Error: TSP_ErrorCode;
  Dist, dX, dY: aFloat;
  NewFrame, Collided, CollidedA, CollidedB, CollidedC: Boolean;
Begin

  CollidedA := False;
  CollidedB := False;
  CollidedC := False;

  wcX := 0;
  wcY := 0;
  NewFrame := False;
  If Not Sprite^.Collided Then Begin
    // Animate
    If Sprite^.FrameCounter > 0 Then
      Dec(Sprite^.FrameCounter)
    Else Begin
      NewFrame := True;
      Case Sprite^.AnimMode Of
        0: // Looping
          Begin
            Inc(Sprite^.CurFrame, Sprite^.AnimDelta);
            If Sprite^.CurFrame > Sprite^.AnimEnd Then
              Sprite^.CurFrame := Sprite^.AnimStart;
          End;
        1: // Pingpong
          Begin
            Inc(Sprite^.CurFrame, Sprite^.AnimDelta);
            If Sprite^.CurFrame > Sprite^.AnimEnd Then Begin
              Sprite^.CurFrame := Sprite^.AnimEnd -1;
              Sprite^.AnimDelta := -1;
              Sprite^.ResumeDelta := Sprite^.AnimDelta;
            End Else
              If Sprite^.CurFrame < Sprite^.AnimStart Then Begin
                Sprite^.CurFrame := Sprite^.AnimStart +1;
                Sprite^.AnimDelta := 1;
              End;
          End;
        2: // once then stop
          Begin
            Inc(Sprite^.CurFrame, Sprite^.AnimDelta);
            If Sprite^.CurFrame > Sprite^.AnimEnd Then Begin
              Sprite^.AnimDelta := 0;
              Sprite^.CurFrame := Sprite^.AnimEnd;
            End;
          End;
        3: // looping reversed
          Begin
            Inc(Sprite^.CurFrame, Sprite^.AnimDelta);
            If Sprite^.CurFrame < Sprite^.AnimStart Then
              Sprite^.CurFrame := Sprite^.AnimEnd;
          End;
        4: // Reverse ping-pong
          Begin
            Inc(Sprite^.CurFrame, Sprite^.AnimDelta);
            If Sprite^.CurFrame > Sprite^.AnimEnd Then Begin
              Sprite^.CurFrame := Sprite^.AnimEnd -1;
              Sprite^.AnimDelta := -1;
            End Else
              If Sprite^.CurFrame < Sprite^.AnimStart Then Begin
                Sprite^.CurFrame := Sprite^.AnimStart +1;
                Sprite^.AnimDelta := 1;
              End;
          End;
        5: // once reversed then stop
          Begin
            Inc(Sprite^.CurFrame, Sprite^.AnimDelta);
            If Sprite^.CurFrame < Sprite^.AnimStart Then Begin
              Sprite^.AnimDelta := 0;
              Sprite^.CurFrame := Sprite^.AnimStart;
            End;
          End;
      End;
      Sprite^.ResumeDelta := Sprite^.AnimDelta;
    End;

    // Move
    If Sprite^.DstTime > FRAMES Then Begin
      Delay := FRAMES - Sprite^.MoveStart;
      If Delay > 0 Then Begin
        Sprite^.X := Sprite^.X + (Sprite^.MoveX * Delay);
        Sprite^.Y := Sprite^.Y + (Sprite^.MoveY * Delay);
        Sprite^.MoveStart := FRAMES;
      End;
    End Else
      If Sprite^.DstTime <> 0 Then Begin
        Sprite^.X := Sprite^.DstX;
        Sprite^.Y := Sprite^.DstY;
        Sprite^.DstTime := 0;
      End;

    Case Sprite^.WrapMode of
      1: // Wrap to window
        Begin
          While Sprite^.X - Sprite^.HotX >= Window^.Width Do
            Sprite^.X := Sprite^.X - Window^.Width;
          While Sprite^.X - Sprite^.HotY < 0 Do
            Sprite^.X := Sprite^.X + Window^.Width;
          While Sprite^.Y - Sprite^.HotY >= Window^.Height Do
            Sprite^.Y := Sprite^.Y - Window^.Height;
          While Sprite^.Y - Sprite^.HotY < 0 Do
            Sprite^.Y := Sprite^.Y + Window^.Height;
        End;
      2: // Wrap to clipping rect
        Begin
          wcX := Window^.clipx2 - Window^.clipx1;
          wcY := Window^.clipy2 - Window^.clipy1;
          While Sprite^.X - Sprite^.HotX >= Window^.clipx2 Do
            Sprite^.X := Sprite^.X - wcX;
          While Sprite^.X - Sprite^.HotY < Window^.clipx1 Do
            Sprite^.X := Sprite^.X + wcX;
          While Sprite^.Y - Sprite^.HotY >= Window^.clipy2 Do
            Sprite^.Y := Sprite^.Y - wcY;
          While Sprite^.Y - Sprite^.HotY < Window^.clipy1 Do
            Sprite^.Y := Sprite^.Y + wcY;
        End;
    End;

    // Rotate
    If Sprite^.AngleTime > FRAMES Then Begin
      If Sprite^.AngleDir = -1 Then Begin // CCW, -1
        If Sprite^.Angle < Sprite^.DstAngle Then
          Dist := Sprite^.Angle + (360 - Sprite^.DstAngle)
        Else
          Dist := Sprite^.Angle - Sprite^.DstAngle;
        Sprite^.Angle := Sprite^.Angle - (Dist/(Sprite^.AngleTime - FRAMES));
      End Else Begin // CW, +1
        If Sprite^.Angle > Sprite^.DstAngle Then
          Dist := Sprite^.DstAngle + (360 - Sprite^.Angle)
        Else
          Dist := Sprite^.DstAngle - Sprite^.Angle;
        Sprite^.Angle := Sprite^.Angle + (Dist/(Sprite^.AngleTime - FRAMES));
      End;
    End;

    // Scale
    If Sprite^.ScaleTime > FRAMES Then
      Sprite^.Scale := Sprite^.Scale + ((Sprite^.DstScale - Sprite^.Scale)/(Sprite^.ScaleTime - FRAMES));

  End;

  // Draw the sprite
  SP_GetFrameData(Sprite, SrcPtr, SrcLen, Sprite^.CurFrame);
  If SrcPtr <> Nil Then Begin
    Delay := pLongWord(SrcPtr)^;
    Inc(SrcPtr, SizeOf(LongWord));
    dX := Sprite^.X - Sprite^.HotX;
    dY := Sprite^.Y - Sprite^.HotY;
    If Window^.winorigin Then Begin
      dX := dX - Window^.orgx;
      dY := dY - Window^.orgy;
    End;
    X := Round(dX);
    Y := Round(dY);
    cX1 := Max(Window^.clipx1, 0); ccX1 := cX1;
    cY1 := Max(Window^.clipy1, 0); ccY1 := cY1;
    cX2 := Min(Window^.Width, Window^.clipx2); ccX2 := cX2;
    cY2 := Min(Window^.Height, Window^.clipy2); ccY2 := cY2;
    W := pLongWord(SrcPtr)^;
    Inc(SrcPtr, SizeOf(LongWord));
    H := pLongWord(SrcPtr)^;
    Dec(SrcPtr, SizeOf(LongWord));
    Mx := Ceil(Sqrt(W*W+H*H) * Sprite^.Scale);

    // A note about the parameters - we can use the window width and height as they will be identical to the size of the window that we're
    // masquerading as - this is only called by the compositor.

    Collided := SP_PutSprite(dPtr, X, Y, Sprite^.OverMode, Window^.Paper, Window^.Transparent, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
    If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);

    // Now issue sprite re-draws for wrapping sprites. Basically, if the sprite moves off the right or bottom edges (a wrapped sprite cannot move off the top or left),
    // then re-draw the sprite at an offset.
    If Sprite^.WrapMode > 0 Then Begin
      Case Sprite^.WrapMode of
        1: // Window Wrap
          Begin
            If X + Mx >= Window^.Width Then Begin
              cX1 := ccX1; cY1 := ccY1; cX2 := ccX2; cY2 := ccY2;
              CollidedA := SP_PutSprite(dPtr, X - Window^.Width, Y, Sprite^.OverMode, Window^.Paper, Window^.Transparent, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
              If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
            End;
            If Y + Mx >= Window^.Height Then Begin
              cX1 := ccX1; cY1 := ccY1; cX2 := ccX2; cY2 := ccY2;
              CollidedB := Sprite^.Collided Or SP_PutSprite(dPtr, X, Y - Window^.Height, Sprite^.OverMode, Window^.Paper, Window^.Transparent, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
              If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
            End;
            If (X + Mx >= Window^.Width) And (Y + Mx >= Window^.Height) Then Begin
              cX1 := ccX1; cY1 := ccY1; cX2 := ccX2; cY2 := ccY2;
              CollidedC := Sprite^.Collided Or SP_PutSprite(dPtr, X - Window^.Width, Y - Window^.Height, Sprite^.OverMode, Window^.Paper, Window^.Transparent, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
              If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
            End;
          End;
        2: // Cliprect Wrap
          Begin
            If X + Mx >= Window^.clipx2 Then Begin
              cX1 := ccX1; cY1 := ccY1; cX2 := ccX2; cY2 := ccY2;
              CollidedA := SP_PutSprite(dPtr, X - wCx, Y, Sprite^.OverMode, Window^.Paper, Window^.Transparent, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
              If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
            End;
            If Y + Mx >= Window^.clipy2 Then Begin
              cX1 := ccX1; cY1 := ccY1; cX2 := ccX2; cY2 := ccY2;
              CollidedB := SP_PutSprite(dPtr, X, Y - wCy, Sprite^.OverMode, Window^.Paper, Window^.Transparent, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
              If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
            End;
            If (X + Mx >= Window^.clipx2) And (Y + Mx >= Window^.clipy2) Then Begin
              cX1 := ccX1; cY1 := ccY1; cX2 := ccX2; cY2 := ccY2;
              CollidedC := SP_PutSprite(dPtr, X - wCx, Y - wCy, Sprite^.OverMode, Window^.Paper, Window^.Transparent, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
              If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
            End;
          End;
      End;
    End;

    // Now draw any clones. They don't cause collisions.

    If Sprite^.NumClones > 0 Then Begin
      ccX1 := Max(Window^.clipx1, 0);
      ccY1 := Max(Window^.clipy1, 0);
      ccX2 := Min(Window^.Width, Window^.clipx2);
      ccY2 := Min(Window^.Height, Window^.clipy2);
      For Idx := 0 To Sprite^.NumClones -1 Do Begin
        dX := Sprite^.Clones[Idx].X + Sprite^.X - Sprite^.HotX;
        dY := Sprite^.Clones[Idx].Y + Sprite^.Y - Sprite^.HotY;
        SP_ConvertWToOrigin_d(dX, dY, Window);
        X := Round(dX);
        Y := Round(dY);
        cX1 := ccX1; cY1 := ccY1; cX2 := ccX2; cY2 := ccY2;
        SP_PutSprite(dPtr, X, Y, Sprite^.OverMode, Window^.Paper, Window^.Transparent, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
        If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
        If Sprite^.WrapMode > 0 Then Begin
          Case Sprite^.WrapMode of
            1: // Window Wrap
              Begin
                If X + Mx >= Window^.Width Then Begin
                  cX1 := ccX1; cY1 := ccY1; cX2 := ccX2; cY2 := ccY2;
                  CollidedA := CollidedA Or SP_PutSprite(dPtr, X - Window^.Width, Y, Sprite^.OverMode, Window^.Paper, Window^.Transparent, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
                  If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
                End;
                If Y + Mx >= Window^.Height Then Begin
                  cX1 := ccX1; cY1 := ccY1; cX2 := ccX2; cY2 := ccY2;
                  CollidedB := CollidedB Or SP_PutSprite(dPtr, X, Y - Window^.Height, Sprite^.OverMode, Window^.Paper, Window^.Transparent, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
                  If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
                End;
                If (X + Mx >= Window^.Width) And (Y + Mx >= Window^.Height) Then Begin
                  cX1 := ccX1; cY1 := ccY1; cX2 := ccX2; cY2 := ccY2;
                  CollidedC := CollidedC Or SP_PutSprite(dPtr, X - Window^.Width, Y - Window^.Height, Sprite^.OverMode, Window^.Paper, Window^.Transparent, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
                  If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
                End;
              End;
            2: // Cliprect Wrap
              Begin
                If X + Mx >= Window^.clipx2 Then Begin
                  cX1 := ccX1; cY1 := ccY1; cX2 := ccX2; cY2 := ccY2;
                  CollidedA := CollidedA Or SP_PutSprite(dPtr, X - wCx, Y, Sprite^.OverMode, Window^.Paper, Window^.Transparent, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
                  If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
                End;
                If Y + Mx >= Window^.clipy2 Then Begin
                  cX1 := ccX1; cY1 := ccY1; cX2 := ccX2; cY2 := ccY2;
                  CollidedB := CollidedB Or SP_PutSprite(dPtr, X, Y - wCy, Sprite^.OverMode, Window^.Paper, Window^.Transparent, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
                  If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
                End;
                If (X + Mx >= Window^.clipx2) And (Y + Mx >= Window^.clipy2) Then Begin
                  cX1 := ccX1; cY1 := ccY1; cX2 := ccX2; cY2 := ccY2;
                  CollidedC := CollidedC Or SP_PutSprite(dPtr, X - wCx, Y - wCy, Sprite^.OverMode, Window^.Paper, Window^.Transparent, Window^.Width, Window^.Height, SrcPtr, SrcLen, Sprite^.Angle, Sprite^.Scale, cX1, cY1, cX2, cY2, Error);
                  If Window^.Visible Then SP_SetDirtyRect(Window^.Left + cX1, Window^.Top + cY1, Window^.Left + cX1 + cX2, Window^.Top + cY1 + cY2);
                End;
              End;
          End;
        End;
      End;
    End;

    If NewFrame Then
      Sprite^.FrameCounter := Delay;

    If Collided or CollidedA or CollidedB or CollidedC Then Begin
      Sprite^.Collided := True;
      If Sprite^.CanCollide Then Begin
        COLLIDE_FLAG := True;
      End Else
        Sprite^.Collided := False;
    End;

  End;

End;

Function SP_PutSprite(Dst: pByte; dX, dY, Over, Paper, wTrans: Integer; dW, dH: LongWord; Src: pByte; SrcLen: Integer; RotAngle, Scale: aFloat; Var cX1, cY1, cX2, cY2: Integer; Var Error: TSP_ErrorCode): Boolean;
Var
  W, W2, H, SrcX, SrcY, SrcW, SrcH: LongWord;
  TransparentColour: Word;
  TC: Byte;
Begin

  // Identical to putregion() but does collision checking

  W := pLongWord(Src)^;
  Inc(Src, SizeOf(LongWord));
  H := pLongWord(Src)^;
  Inc(Src, SizeOf(LongWord));
  TransparentColour := pWord(Src)^;
  Inc(Src, SizeOf(Word));

  Result := False;

  If (RotAngle <> 0) or (Scale <> 1) Then
    Result := SP_RotateSprite(Src, W, H, Dst, dX, dY, dW, dH, Over, Paper, wTrans, TransparentColour, RotAngle, Scale, cX1, cY1, cX2, cY2)
  Else Begin
    W2 := W;
    If (dX > cX2) or (dX <= cX1 - integer(W)) Then Exit;
    If (dY > cY2) or (dY <= cY1 - integer(H)) Then Exit;
    If dX < cX1 Then Begin SrcX := cX1 - dX; Dec(W2, SrcX); dX := cX1; End Else SrcX := 0;
    If dY < cY1 Then Begin SrcY := cY1 - dY; Dec(H, SrcY); dY := cY1; End Else SrcY := 0;
    If dX + Integer(W2) >= cX2 Then SrcW := cX2 - dX Else SrcW := Min(W2, cX2);
    If dY + Integer(H) >= cY2 Then SrcH := cY2 - dY Else SrcH := Min(H, cY2);
    cX1 := dX; cY1 := dY; cX2 := W; cY2 := H;
    Inc(Src, (W * SrcY) + SrcX);
    Inc(Dst, (Integer(dW) * dY) + dX);
    If Over = 0 Then Begin
      If TransparentColour <> $FFFF Then Begin
        TC := TransparentColour And $FF;
        While SrcH > 0 Do Begin
          W2 := SrcW;
          While W2 > 0 Do Begin
            If Src^ <> TC Then Begin
              If (Dst^ <> Paper) And ((Dst^ <> wTrans) And (wTrans <> $FFFF)) Then
                Result := True;
              Dst^ := Src^;
            End;
            Inc(Dst);
            Inc(Src);
            Dec(W2);
          End;
          Inc(Dst, dW - SrcW);
          Inc(Src, W - SrcW);
          Dec(SrcH);
        End;
      End Else Begin
        While SrcH > 0 Do Begin
          W2 := SrcW;
          While W2 > 0 Do Begin
            If (Dst^ <> Paper) And ((Dst^ <> wTrans) And (wTrans <> $FFFF)) Then
              Result := True;
            Dst^ := Src^;
            Inc(Dst);
            Inc(Src);
            Dec(W2);
          End;
          Inc(Dst, dW - SrcW);
          Inc(Src, W - SrcW);
          Dec(SrcH);
        End;
      End;
    End Else Begin
      If TransparentColour <> $FFFF Then Begin
        TC := TransparentColour And $FF;
        While SrcH > 0 Do Begin
          W2 := SrcW;
          While W2 > 0 Do Begin
            If Src^ <> TC Then Begin
              If (Dst^ <> Paper) And ((Dst^ <> wTrans) And (wTrans <> $FFFF)) Then
                Result := True;
              SP_OverPixelPtr(Dst, Src, Over);
            End;
            Inc(Dst);
            Inc(Src);
            Dec(W2);
          End;
          Inc(Dst, dW - SrcW);
          Inc(Src, W - SrcW);
          Dec(SrcH);
        End;
      End Else Begin
        While SrcH > 0 Do Begin
          W2 := SrcW;
          While W2 > 0 Do Begin
            If (Dst^ <> Paper) And ((Dst^ <> wTrans) And (wTrans <> $FFFF)) Then
              Result := True;
            SP_OverPixelPtr(Dst, Src, Over);
            Inc(Dst);
            Inc(Src);
            Dec(W2);
          End;
          Inc(Dst, dW - SrcW);
          Inc(Src, W - SrcW);
          Dec(SrcH);
        End;
      End;
    End;
  End;

  SP_BankList[0]^.Changed := True;

End;

Function SP_RotateSprite(Src: pByte; sW, sH: Integer; Dst: pByte; dX, dY, dW, dH, Over, Paper, wTrans: Integer; Trans: Word; Rot, Scale: aFloat; cX1, cY1, cX2, cY2: Integer): Boolean;
Var
  ndW, ndH, cX, cY, iSin, iCos,
  xd, yd, aX, aY, X, Y, sdX, sdY, TLX, TLY, BRX, BRY: Integer;
  tW, tH: aFloat;
  dPtr: pByte;
  TC, sCl: Byte;
Begin

  Rot := -Rot;
  Result := False;

  // Calculate the size of the newly rotated+scaled bitmap, so we can alter dx and dy to centre on the destination

  tW := Abs(sW * Scale * Cos(Rot))+Abs(sH * Scale * Sin(Rot));
  tH := Abs(sW * Scale * Sin(Rot))+Abs(sH * Scale * Cos(Rot));
  If Odd(Round(tw)) Then tw := tw + 1;
  If Odd(Round(tH)) Then th := th + 1;
  dX := Round(dX - (tW - (sW * Scale))/2);
  dY := Round(dY - (tH - (sH * Scale))/2);
  ndW := Round(tW);
  ndH := Round(tH);

  // Adjust the clipping rectangle to the display, and then create the intersection rectangle

  cX1 := Max(cX1, 0);
  cY1 := Max(cY1, 0);
  cX2 := Min(dW, cX2);
  cY2 := Min(dH, cY2);

  TLX := Max(cX1, dX);
  TLY := Max(cY1, dY);
  BRX := Min(cX2, dX + ndW);
  BRY := Min(cY2, dY + ndH);

  Dec(TLX, dX);
  Dec(TLY, dY);
  Dec(BRX, dX);
  Dec(BRY, dY);

  If (TLX <= BRX) And (TLY <= BRY) Then Begin

    // And now render pixel by pixel. Slower than blitting (above) but not bad all the same.
    // Let's face it, this was never going to be *fast*, was it?

    iSin := Round(Sin(Rot)*(65536/Scale));
    iCos := Round(Cos(Rot)*(65536/Scale));
    cX := Round(ndW / 2);
    cY := Round(ndH / 2);

    xd := ((sW Shl 16) - (ndW Shl 16)) Div 2;
    yd := ((sH Shl 16) - (ndH Shl 16)) Div 2;
    ax := (cX Shl 16) - (iCos * cX);
    ay := (cY Shl 16) - (iSin * cX);

    dPtr := Dst;
    Inc(dPtr, (dX + TLX) + ((dY + TLY) * dW));

    If Over = 0 Then Begin
      If Trans = $FFFF Then Begin
        For y := TLY To BRY -1 Do Begin
          dY := cY - Y;
          sdX := (aX + (iSin * Dy)) + xd + (TLX * iCos);
          sdY := (aY - (iCos * Dy)) + yd + (TLX * iSin);
          For X := TLX To BRX - 1 Do Begin
            dX := sdX Shr 16;
            Inc(sdX, iCos);
            dY := sdY Shr 16;
            Inc(sdY, iSin);
            If (dX < sW) and (dY < sH) Then Begin
              If (dPtr^ <> Paper) And ((Dst^ <> wTrans) And (wTrans <> $FFFF)) Then Result := True;
              dPtr^ := pByte(NativeUInt(Src) + longword((dY * sW) + dX))^;
            End;
            Inc(dPtr);
          End;
          Inc(dPtr, dW - (BRX - TLX));
        End;
      End Else Begin
        TC := Trans And $FF;
        For y := TLY To BRY -1 Do Begin
          dY := cY - Y;
          sdX := (aX + (iSin * Dy)) + xd + (TLX * iCos);
          sdY := (aY - (iCos * Dy)) + yd + (TLX * iSin);
          For X := TLX To BRX - 1 Do Begin
            dX := sdX Shr 16;
            Inc(sdX, iCos);
            dY := sdY Shr 16;
            Inc(sdY, iSin);
            If (dX < sW) and (dY < sH) Then Begin
              sCL := pByte(NativeUInt(Src) + longword((dY * sW) + dX))^;
              If sCL <> TC Then Begin
                If (dPtr^ <> Paper) And ((Dst^ <> wTrans) And (wTrans <> $FFFF)) Then Result := True;
                dPtr^ := sCL;
              End;
            End;
            Inc(dPtr);
          End;
          Inc(dPtr, dW - (BRX - TLX));
        End;
      End;
    End Else Begin
      If Trans = $FFFF Then Begin
        For y := TLY To BRY -1 Do Begin
          dY := cY - Y;
          sdX := (aX + (iSin * Dy)) + xd + (TLX * iCos);
          sdY := (aY - (iCos * Dy)) + yd + (TLX * iSin);
          For X := TLX To BRX - 1 Do Begin
            dX := sdX Shr 16;
            Inc(sdX, iCos);
            dY := sdY Shr 16;
            Inc(sdY, iSin);
            If (dX < sW) and (dY < sH) Then Begin
              sCl := pByte(NativeUInt(Src) + longword((dY * sW) + dX))^;
              If (dPtr^ <> Paper) And ((Dst^ <> wTrans) And (wTrans <> $FFFF)) Then Result := True;
              SP_OverPixelPtrVal(dPtr, sCl, Over);
            End;
            Inc(dPtr);
          End;
          Inc(dPtr, dW - (BRX - TLX));
        End;
      End Else Begin
        TC := Trans And $FF;
        For y := TLY To BRY -1 Do Begin
          dY := cY - Y;
          sdX := (aX + (iSin * Dy)) + xd + (TLX * iCos);
          sdY := (aY - (iCos * Dy)) + yd + (TLX * iSin);
          For X := TLX To BRX - 1 Do Begin
            dX := sdX Shr 16;
            Inc(sdX, iCos);
            dY := sdY Shr 16;
            Inc(sdY, iSin);
            If (dX < sW) and (dY < sH) Then Begin
              sCL := pByte(NativeUInt(Src) + longword((dY * sW) + dX))^;
              If sCL <> TC Then Begin
                If (dPtr^ <> Paper) And ((Dst^ <> wTrans) And (wTrans <> $FFFF)) Then Result := True;
                SP_OverPixelPtrVal(dPtr, sCl, Over);
              End;
            End;
            Inc(dPtr);
          End;
          Inc(dPtr, dW - (BRX - TLX));
        End;
      End;
    End;

  End;

End;

Procedure SP_Delete_Sprite(SpriteID: Integer; Error: TSP_ErrorCode);
Var
  Idx: Integer;
Begin

  DisplaySection.Enter;
  Idx := SP_FindSpriteID(SpriteID, Error);
  If Error.Code = SP_ERR_OK Then Begin
    SP_DeleteBank(Idx, Error);
  End;
  DisplaySection.Leave;

End;

Procedure SP_Clear_Sprite(SpriteID: Integer; Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  DisplaySection.Enter;
  Idx := SP_FindSpriteID(SpriteID, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    Sprite := @Bank^.Info[0];
    SetLength(Bank^.Memory, 0);
    Sprite^.NumFrames := 0;
    Sprite^.Enabled := False;
    Sprite^.Data := @Bank^.Memory[0];
    Sprite^.FrameCounter := 0;
    Sprite^.DstTime := 0;
    Sprite^.Angle := 0;
    Sprite^.DstAngle := 0;
    Sprite^.AngleTime := 0;
    Sprite^.Scale := 1;
    Sprite^.ScaleTime := 0;
    Bank^.Changed := True;
  End;
  DisplaySection.Leave;

End;

Procedure SP_BlockSprites;
Begin

  DisplaySection.Enter;

  If Not BLOCKSPRITES Then Begin
    BLOCKSPRITES := True;
    Repeat
      CB_YIELD;
    Until Not DRAWINGSPRITES;
  End;

End;

Procedure SP_UnBlockSprites;
Begin

  BLOCKSPRITES := False;
  DisplaySection.Leave;

End;

Procedure SP_AddClone(Id: Integer; X, Y: aFloat; var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  DisplaySection.Enter;
  Idx := SP_FindSpriteID(Id, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_SPRITE_BANK Then Begin
      Sprite := @Bank^.Info[0];
      If Sprite^.NumClones < 256 Then Begin
        Sprite^.Clones[Sprite^.NumClones].X := X - Sprite^.X;
        Sprite^.Clones[Sprite^.NumClones].Y := Y - Sprite^.Y;
        Inc(Sprite^.NumClones);
      End Else
        Error.Code := SP_ERR_OUT_OF_CLONES;
    End Else
      Error.Code := SP_ERR_INVALID_BANK;
  End Else
    Error.Code := SP_ERR_SPRITE_NOT_FOUND;
  DisplaySection.Leave;

End;

Procedure SP_DeleteClone(Id, Index: Integer; var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  DisplaySection.Enter;
  Idx := SP_FindSpriteID(Id, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_SPRITE_BANK Then Begin
      Sprite := @Bank^.Info[0];
      If (Index < integer(Sprite^.NumClones)) and (Index >= 0) Then Begin
        For Idx := Index To Sprite^.NumClones -2 Do Begin
          Sprite^.Clones[Idx].X := Sprite^.Clones[Idx +1].X;
          Sprite^.Clones[Idx].Y := Sprite^.Clones[Idx +1].Y;
        End;
        Dec(Sprite^.NumClones);
      End Else
        Error.Code := SP_ERR_CLONE_NOT_FOUND;
    End Else
      Error.Code := SP_ERR_INVALID_BANK;
  End Else
    Error.Code := SP_ERR_SPRITE_NOT_FOUND;
  DisplaySection.Leave;

End;

Procedure SP_MoveClone(Id, Index: Integer; X, Y: aFloat; var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  Idx := SP_FindSpriteID(Id, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_SPRITE_BANK Then Begin
      Sprite := @Bank^.Info[0];
      If (Index < Integer(Sprite^.NumClones)) And (Index >= 0) Then Begin
        Sprite^.Clones[Index].X := X - Sprite^.X;
        Sprite^.Clones[Index].Y := Y - Sprite^.Y;
      End Else
        Error.Code := SP_ERR_CLONE_NOT_FOUND;
    End Else
      Error.Code := SP_ERR_INVALID_BANK;
  End Else
    Error.Code := SP_ERR_SPRITE_NOT_FOUND;

End;

Function SP_GetClonePos(Id, Index: Integer; Var Error: TSP_ErrorCode): Clone;
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Sprite: pSP_Sprite_Info;
Begin

  Idx := SP_FindSpriteID(Id, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_SPRITE_BANK Then Begin
      Sprite := @Bank^.Info[0];
      If (Index < Integer(Sprite^.NumClones)) And (Index >= 0) Then Begin
        Result.X := Sprite^.Clones[Index].X;
        Result.Y := Sprite^.Clones[Index].Y;
      End Else
        Error.Code := SP_ERR_CLONE_NOT_FOUND;
    End Else
      Error.Code := SP_ERR_INVALID_BANK;
  End Else
    Error.Code := SP_ERR_SPRITE_NOT_FOUND;

End;

Procedure SP_SetWindowVisible(WindowID: Integer; Vis: Boolean; Error: TSP_ErrorCode);
Var
  BankIdx: Integer;
  Bank: pSP_Bank;
Begin

  Error.Code := SP_ERR_OK;
  BankIdx := SP_FindBankID(WindowID);
  If BankIdx > -1 Then Begin

    Bank := SP_BankList[BankIdx];
    If Bank^.DataType = SP_WINDOW_BANK Then Begin

      pSP_Window_Info(@Bank.Info[0])^.Visible := Vis;
      SP_SetDirtyRect(0, 0, DISPLAYWIDTH, DISPLAYHEIGHT);
      SP_NeedDisplayUpdate := True;

    End Else

      Error.Code := SP_ERR_WINDOW_NOT_FOUND;

  End;

End;

Function  SP_New_GraphicA(Width, Height: Integer; Trans: Word; Var Error: TSP_ErrorCode): Integer;
Var
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
  Idx, BankIdx: Integer;
  PalEntry: LongWord;
Begin

  // New graphic bank - blank graphic width x height.

  Result := SP_NewBank(0);
  BankIdx := SP_FindBankID(Result);
  If BankIdx > -1 Then Begin

    Bank := SP_BankList[BankIdx];
    SetLength(Bank^.Info, SizeOf(SP_Graphic_Info));
    Bank^.InfoLength := SizeOf(SP_Graphic_Info);
    Bank^.DataType := SP_GRAPHIC_BANK;
    Gfx := @Bank^.Info[0];
    Gfx^.Width := Width;
    Gfx^.Height := Height;
    Gfx^.Transparent := Trans;
    Gfx^.orgx := 0;
    Gfx^.orgy := 0;
    Gfx^.orgw := Gfx^.Width;
    Gfx^.orgh := Gfx^.Height;
    Gfx^.clipx1 := 0;
    Gfx^.clipy1 := 0;
    Gfx^.clipx2 := Gfx^.Width;
    Gfx^.clipy2 := Gfx^.Height;
    Gfx^.scalex := 1;
    Gfx^.scaley := 1;
    Gfx^.Depth := 8;
    SetLength(Bank^.Memory, Width * Height);
    Gfx^.Data := @Bank^.Memory[0];

    For Idx:= 0 To 255 Do Begin
      PalEntry := SP_GetPalette(Idx);
      Gfx^.Palette[Idx].B := (PalEntry Shr 8) And $FF;
      Gfx^.Palette[Idx].G := (PalEntry Shr 16) And $FF;
      Gfx^.Palette[Idx].R := (PalEntry Shr 24) And $FF;
    End;

    SP_GFX_UpdateWindowInfo(Gfx, Bank);
    Result := Bank^.ID;

  End;

End;

Function  SP_New_GraphicB(GraphicStr: aString; Var Error: TSP_ErrorCode): Integer;
Var
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
  Width, Height: LongWord;
  PalEntry: LongWord;
  Idx, BankIdx: Integer;
  Trans: Word;
Begin

  // New Graphic bank - use supplied string as a graphic

  Result := SP_NewBank(0);

  BankIdx := SP_FindBankID(Result);
  If BankIdx > -1 Then Begin

    Bank := SP_BankList[BankIdx];
    SetLength(Bank^.Info, SizeOf(SP_Graphic_Info));
    Bank^.InfoLength := SizeOf(SP_Graphic_Info);
    Bank^.DataType := SP_GRAPHIC_BANK;
    Gfx := @Bank^.Info[0];

    GraphicStr := SP_TextToGraphic(GraphicStr, Error);

    If Error.Code = SP_ERR_OK Then Begin

      Width := pLongWord(@GraphicStr[1])^;
      Height := pLongWord(@GraphicStr[5])^;
      Trans := pWord(@GraphicStr[9])^;

      SetLength(Bank^.Memory, Width * Height);
      CopyMem(@Bank^.Memory[0], @GraphicStr[11], Width*Height);

      Gfx^.Width := Width;
      Gfx^.Height := Height;
      Gfx^.Transparent := Trans;
      Gfx^.Data := @Bank^.Memory[0];

      For Idx:= 0 To 255 Do Begin
        PalEntry := SP_GetPalette(Idx);
        Gfx^.Palette[Idx].B := (PalEntry Shr 8) And $FF;
        Gfx^.Palette[Idx].G := (PalEntry Shr 16) And $FF;
        Gfx^.Palette[Idx].R := (PalEntry Shr 24) And $FF;
      End;

      Gfx^.orgx := 0;
      Gfx^.orgy := 0;
      Gfx^.orgw := Gfx^.Width;
      Gfx^.orgh := Gfx^.Height;
      Gfx^.clipx1 := 0;
      Gfx^.clipy1 := 0;
      Gfx^.clipx2 := Gfx^.Width;
      Gfx^.clipy2 := Gfx^.Height;
      Gfx^.scalex := 1;
      Gfx^.scaley := 1;
      Gfx^.Depth := 8;
      SP_GFX_UpdateWindowInfo(Gfx, Bank);

    End Else

      SP_DeleteBank(BankIdx, Error);

  End;

End;

Function  SP_New_GraphicC(Filename: aString; Trans: Word; Var Error: TSP_ErrorCode): Integer;
Var
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
  Idx: LongWord;
  BankIdx: Integer;
  SrcPtr, DstPtr: pByte;
Begin

  // New Graphic Bank - load from file

  Result := SP_NewBank(0);

  BankIdx := SP_FindBankID(Result);
  If BankIdx > -1 Then Begin

    Bank := SP_BankList[BankIdx];
    SetLength(Bank^.Info, SizeOf(SP_Graphic_Info));
    Bank^.InfoLength := SizeOf(SP_Graphic_Info);
    Bank^.DataType := SP_GRAPHIC_BANK;
    Gfx := @Bank^.Info[0];

    SP_TestPackageFile(Filename, Error);
    CB_Load_Image(Filename, Error);

    If Error.Code = SP_ERR_OK Then Begin

      SetLength(Bank^.Memory, ImgWidth * ImgHeight);
      SrcPtr := ImgPtr;
      DstPtr := @Bank.Memory[0];

      For Idx := 1 To ImgHeight Do Begin

        CopyMem(DstPtr, SrcPtr, ImgWidth);
        Inc(SrcPtr, ImgStride);
        Inc(DstPtr, ImgWidth);

      End;

      Gfx^.Width := ImgWidth;
      Gfx^.Height := ImgHeight;
      Gfx^.Transparent := Trans;
      Gfx^.orgx := 0;
      Gfx^.orgy := 0;
      Gfx^.orgw := Gfx^.Width;
      Gfx^.orgh := Gfx^.Height;
      Gfx^.clipx1 := 0;
      Gfx^.clipy1 := 0;
      Gfx^.clipx2 := Gfx^.Width;
      Gfx^.clipy2 := Gfx^.Height;
      Gfx^.scalex := 1;
      Gfx^.scaley := 1;
      Gfx^.Depth := 8;
      Gfx^.Data := @Bank.Memory[0];

      For Idx:= 0 To 255 Do
        Gfx^.Palette[Idx] := ImgPalette[Idx];

      SP_GFX_UpdateWindowInfo(Gfx, Bank);

      CB_Free_Image;

    End Else Begin

      SP_DeleteBank(BankIdx, Error);
      Result := -1;

    End;

  End;

End;

Procedure SP_Load_Graphic(Id: Integer; Filename: aString; Trans: Word; Var Error: TSP_ErrorCode);
Var
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
  Idx: Integer;
  SrcPtr, DstPtr: pByte;
Begin

  Idx := SP_FindBankID(ID);

  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];

    If Not Bank^.Protection Then Begin

      SetLength(Bank^.Info, SizeOf(SP_Graphic_Info));
      Bank^.InfoLength := SizeOf(SP_Graphic_Info);
      Bank^.DataType := SP_GRAPHIC_BANK;
      Gfx := @Bank^.Info[0];

      SP_TestPackageFile(Filename, Error);
      CB_Load_Image(Filename, Error);

      If Error.Code = SP_ERR_OK Then Begin

        SetLength(Bank^.Memory, ImgWidth * ImgHeight);
        SrcPtr := ImgPtr;
        DstPtr := @Bank.Memory[0];

        For Idx := 1 To ImgHeight Do Begin

          CopyMem(DstPtr, SrcPtr, ImgWidth);
          Inc(SrcPtr, ImgStride);
          Inc(DstPtr, ImgWidth);

        End;

        Gfx.Width := ImgWidth;
        Gfx.Height := ImgHeight;
        Gfx.Transparent := Trans;
        Gfx^.orgx := 0;
        Gfx^.orgy := 0;
        Gfx^.orgw := Gfx^.Width;
        Gfx^.orgh := Gfx^.Height;
        Gfx^.clipx1 := 0;
        Gfx^.clipy1 := 0;
        Gfx^.clipx2 := Gfx^.Width;
        Gfx^.clipy2 := Gfx^.Height;
        Gfx^.scalex := 1;
        Gfx^.scaley := 1;
        Gfx^.Depth := 8;
        SP_GFX_UpdateWindowInfo(Gfx, Bank);
        Bank^.Changed := True;

        For Idx:= 0 To 255 Do
          Gfx^.Palette[Idx] := ImgPalette[Idx];

        CB_Free_Image;

      End;

    End Else

      Error.Code := SP_ERR_BANK_PROTECTED;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Function SP_GfxBankToString(Id: Integer; Var Error: TSP_ErrorCode): aString;
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
Begin

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @Bank^.Info[0];
      SetLength(Result, Length(Bank^.Memory));
      CopyMem(@Result[1], @Bank^.Memory[0], Length(Bank^.Memory));
      Result := LongWordToString(Gfx^.Width) + LongWordToString(Gfx^.Height) + WordToString(Gfx^.Transparent) + Result;

    End Else
      Error.Code := SP_ERR_INVALID_BANK;

  End Else
    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Function SP_GetGraphicDetails(Id: Integer; Var Error: TSP_ErrorCode): pSP_Graphic_info;
Var
  Idx: Integer;
  Bank: pSP_Bank;
Begin

  Result := nil;

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Result := @Bank^.Info[0];

    End Else
      Error.Code := SP_ERR_INVALID_BANK;

  End Else
    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Function SP_GetGraphicPalette(Id, PalIndex: Integer; Var Error: TSP_ErrorCode): LongWord;
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
  Clr: TP_Colour;
Begin

  Result := 0;

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @Bank^.Info[0];

      If (PalIndex >= 0) And (PalIndex <= 255) Then Begin

        Clr := Gfx^.Palette[PalIndex];
        Result := (Clr.R Shl 16) + (Clr.G Shl 8) + Clr.B;

      End Else

        Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE;

    End Else
      Error.Code := SP_ERR_INVALID_BANK;

  End Else
    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_SetGraphicOrigin(Id: Integer; x1,y1,x2,y2: aFloat; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
Begin

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @Bank^.Info[0];

      If x2 <> 0 Then
        If x1 > x2 Then
          Error.Code := SP_ERR_ORG_INVALID;

      If y2 <> 0 Then
        If Y1 > y2 Then
          Error.Code := SP_ERR_ORG_INVALID;

      Gfx^.orgx := x1;
      Gfx^.orgy := y1;
      If (x2 <> 0) or (y2 <> 0) Then Begin
        If x2 = 0 Then x2 := Gfx^.Width + x1;
        If y2 = 0 Then y2 := Gfx^.Height + y1;
        Gfx^.orgw := x2;
        Gfx^.orgh := y2;
      End;
      Gfx^.clipx1 := 0;
      Gfx^.clipy1 := 0;
      Gfx^.clipx2 := Gfx^.Width;
      Gfx^.clipy2 := Gfx^.Height;
      SP_GFX_UpdateWindowInfo(Gfx, Bank);

      If SCREENBANK = -Id Then Begin
        SCREENBANK := -1;
        SP_SetDrawingWindow(-Id);
      End;

    End Else
      Error.Code := SP_ERR_INVALID_BANK;

  End Else
    Error.Code := SP_ERR_BANK_NOT_FOUND;


End;

Procedure SP_SetGraphicOriginNoExt(Id: Integer; x1, y1: aFloat; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
  x2, y2: aFloat;
Begin

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @Bank^.Info[0];
      x2 := Gfx^.Width + x1;
      y2 := Gfx^.Height + y1;

      Gfx^.orgx := x1;
      Gfx^.orgy := y1;
      Gfx^.orgw := x2;
      Gfx^.orgh := y2;

      Gfx^.clipx1 := 0;
      Gfx^.clipy1 := 0;
      Gfx^.clipx2 := Gfx^.Width;
      Gfx^.clipy2 := Gfx^.Height;
      SP_GFX_UpdateWindowInfo(Gfx, Bank);

      If SCREENBANK = -Id Then Begin
        SCREENBANK := -1;
        SP_SetDrawingWindow(-Id);
      End;

    End Else
      Error.Code := SP_ERR_INVALID_BANK;

  End Else
    Error.Code := SP_ERR_BANK_NOT_FOUND;


End;

Procedure SP_SetGraphicOriginOff(GfxID: Integer; Var Error: TSP_ErrorCode);
Var
  gfx: pSP_Graphic_Info;
  Idx: Integer;
  Bank: pSP_Bank;
Begin

  Idx := SP_FindBankID(GfxId);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @Bank^.Info[0];
      Gfx^.winscale := False;
      Gfx^.winorigin := False;
      Gfx^.clipx1 := 0;
      Gfx^.clipy1 := 0;
      Gfx^.clipx2 := Gfx^.Width;
      Gfx^.clipy2 := Gfx^.Height;
      SP_GFX_UpdateWindowInfo(Gfx, Bank);

      If SCREENBANK = -GfxId Then Begin
        SCREENBANK := -1;
        SP_SetDrawingWindow(-GfxId);
      End;

    End Else
      Error.Code := SP_ERR_INVALID_BANK;

  End Else
    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Function SP_GetGraphicPixel(Id: Integer; X, Y: aFloat; Var Error: TSP_ErrorCode): Integer;
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
  xP, yP: Integer;
Begin

  Result := -1;

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @Bank^.Info[0];

      SP_ConvertWToOrigin_d(X, Y, @Gfx^.WindowInfo);
      xP := Round(X);
      yP := Round(Y);
      If (Xp < integer(Gfx^.Width)) and (Xp >= 0) and (Yp >= 0) and (Yp < integer(Gfx^.Height)) Then Begin

        Result := pByte(NativeUInt(Gfx^.Data) + LongWord(Xp + (Yp * integer(Gfx^.Width))))^;

      End Else

        Result := -1;

    End Else
      Error.Code := SP_ERR_INVALID_BANK;

  End Else
    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_SetGraphicPixel(Id: Integer; X, Y: aFloat; Clr: Byte; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
  xP, yP: Integer;
Begin

  Idx := SP_FindBankID(Id);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @Bank^.Info[0];

      SP_ConvertWToOrigin_d(X, Y, @Gfx^.WindowInfo);
      xP := Round(X);
      yP := Round(Y);
      If (Xp < Gfx^.clipx2) and (Xp >= Gfx^.clipx1) and (Yp >= gfx^.clipy1) and (Yp < Gfx^.clipy2) Then Begin

        pByte(NativeUInt(Gfx^.Data) + LongWord(Xp + (Yp * integer(Gfx^.Width))))^ := Clr;

      End;

    End Else
      Error.Code := SP_ERR_INVALID_BANK;

  End Else
    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_GFX_UpdateWindowInfo(Var Gfx: pSP_Graphic_Info; Bank: pSP_Bank);
Var
  Idx: Integer;
Begin

  // Because each graphic block can be used as a window (for drawing to its surface),
  // every time a graphic is created or loaded from disk it needs to have the
  // window info structure updated.

  Gfx^.WindowInfo.ID := 0;
  Gfx^.WindowInfo.Width := Gfx^.Width;
  Gfx^.WindowInfo.Height := Gfx^.Height;
  Gfx^.WindowInfo.Stride := Gfx^.Width;
  Gfx^.WindowInfo.Left := 0;
  Gfx^.WindowInfo.Top := 0;
  Gfx^.WindowInfo.FontBankID := FONTBANKID;
  Gfx^.WindowInfo.Transparent := Gfx^.Transparent;
  Gfx^.WindowInfo.SpriteCount := 0;
  Gfx^.WindowInfo.Visible := False;
  Gfx^.WindowInfo.Offset := 0;
  Gfx^.WindowInfo.orgx := Gfx^.orgx;
  Gfx^.WindowInfo.orgy := Gfx^.orgy;
  Gfx^.WindowInfo.orgw := Gfx^.orgw;
  Gfx^.WindowInfo.orgh := Gfx^.orgh;
  Gfx^.WindowInfo.clipx1 := Gfx^.clipx1;
  Gfx^.WindowInfo.clipy1 := Gfx^.clipy1;
  Gfx^.WindowInfo.clipx2 := Gfx^.clipx2;
  Gfx^.WindowInfo.clipy2 := Gfx^.clipy2;
  Gfx^.WindowInfo.winscale := Gfx^.winscale;
  Gfx^.WindowInfo.winorigin := Gfx^.winorigin;
  Gfx^.WindowInfo.winscalex := Gfx^.winscalex;
  Gfx^.WindowInfo.winscaley := Gfx^.winscaley;
  GFx^.WindowInfo.scalex := Gfx^.scalex;
  Gfx^.WindowInfo.scaley := Gfx^.scaley;
  Gfx^.WindowInfo.bpp := Gfx^.Depth;
  Gfx^.WindowInfo.Surface := @Bank^.Memory[0];
  For Idx := 0 to 255 Do Begin
    Gfx^.WindowInfo.Palette[Idx].B := Gfx^.Palette[Idx].B;
    Gfx^.WindowInfo.Palette[Idx].G := Gfx^.Palette[Idx].G;
    Gfx^.WindowInfo.Palette[Idx].R := Gfx^.Palette[Idx].R;
  End;

End;

Function SP_GraphicToFont(GfxID: Integer; var Output: aString; Spacing: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  gBank, nBank, Idx, x, y, gw, gh, NewWidth, NewHeight: Integer;
  Gfx: pSP_Graphic_Info;
  Scale: aFloat;
  AsciiStr, HexStr: aString;
  nByte: Byte;
  ptr: pByte;
Begin

  gBank := SP_NewBank(0);
  SP_CopyBank(GfxID, gBank, Error);
  gBank := SP_FindBankID(gBank);
  Gfx := @SP_BankList[SP_FindBankID(GfxID)]^.Info[0];
  gW := Gfx^.Width;
  gH := Gfx^.Height;

  If (gw > 119) or (gH > 119) Then Begin
    If gW > gH Then Begin
      NewWidth := 119;
    End Else Begin
      NewWidth := Trunc(gW * (119/gH));
    End;
  End Else Begin
    NewWidth := gW;
  End;

  Gfx := @SP_BankList[gBank]^.Info[0];
  Scale := NewWidth/gW;
  SP_RotAndScaleGfx(Gfx.Data, AsciiStr, 0, Scale, Gfx^.Width, Gfx^.Height, Gfx^.Transparent, Error);
  NewWidth := Gfx^.Width;
  NewHeight := Gfx^.Height;
  If Frac(Gfx^.Width/8) > 0 Then Gfx^.Width := (Trunc(Gfx^.Width/8) * 8) + 8 Else Gfx^.Width := Trunc(Gfx^.Width/8) * 8;
  If Frac(Gfx^.Height/8) > 0 Then Gfx^.Height := (Trunc(Gfx^.Height/8) * 8) + 8 Else Gfx^.Height := Trunc(Gfx^.Height/8) * 8;
  SetLength(SP_BankList[gBank]^.Memory, Gfx^.Width * Gfx^.Height);
  Gfx^.Data := @SP_BankList[gBank]^.Memory[0];
  For Idx := 0 To NewHeight -1 Do
    CopyMem(pByte(NativeUInt(Gfx^.Data)+LongWord(Idx * integer(Gfx^.Width))), @AsciiStr[(Idx * NewWidth) +1], NewWidth);
  SP_Dither_Image(Gfx, 7);

  Output := '';
  If NewWidth < integer(Gfx^.Width) Then
    For y := 0 To Gfx^.Height -1 Do Begin
      ptr := pByte(NativeUInt(Gfx^.Data) + Longword((y * integer(Gfx^.Width)) + NewWidth));
      For x := NewWidth To Gfx^.Width -1 Do Begin
        ptr^ := T_PAPER;
        Inc(ptr);
      End;
    End;
  If NewHeight < integer(Gfx^.Height) Then
    For y := NewHeight To Gfx^.Height -1 Do Begin
      ptr := pByte(NativeUInt(Gfx^.Data) + LongWord(y * integer(Gfx^.Width)));
      For x := 0 To Gfx^.Width -1 Do Begin
        ptr^ := T_PAPER;
        Inc(ptr);
      End;
    End;

  nBank := SP_Font_Bank_Create(1, 8, 8, Gfx^.Transparent);
  HexStr := '';
  nByte := 33;
  For Idx := 0 To 63 Do HexStr := HexStr + aChar(0);
  y := 0;
  While y < integer(Gfx^.Height) Do Begin
    x := 0;
    While x < integer(Gfx.Width) Do Begin
      ptr := pByte(NativeUInt(Gfx^.Data) + LongWord((y * integer(Gfx.Width)) + x));
      For Idx := 0 To 7 Do Begin
        CopyMem(@HexStr[1 + (Idx * 8)], ptr, 8);
        Inc(ptr, Gfx^.Width);
      End;
      SP_Font_Bank_SetChar(nBank, nByte, @HexStr[1]);
      Inc(x, 8);
      Inc(nByte);
    End;
    Inc(y, 8);
  End;
  HexStr := '';
  For Idx := 0 To 63 Do HexStr := HexStr + aChar(T_PAPER);
  SP_Font_Bank_SetChar(nBank, 32, @HexStr[1]);

  x := Gfx^.Width Div 8;
  y := Gfx^.Height Div 8;

  AsciiStr := '';
  While Length(AsciiStr) < Spacing Do AsciiStr := AsciiStr + ' ';
  Output := Output + AsciiStr;
  For Idx := 0 To (x * y) -1 Do Begin
    If Idx > 0 Then
      If Idx Mod x = 0 Then
        Output := Output + #13 + AsciiStr;
    Output := OutPut + aChar(Idx + 33);
  End;

  SP_DeleteBank(gBank, Error);
  Result := nBank;

End;

Function SP_New_Tilemap_FromBank(BankID, MapWidth, MapHeight, TileWidth, TileHeight: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
  TMInfo: pSP_TileMap_Info;
  ptr: pInteger;
Begin

  Result := -1;

  Idx := SP_FindBankID(BankId);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @Bank^.Info[0];
      If (Gfx^.Width Mod longword(TileWidth) <> 0) or (Gfx^.Height Mod longword(TileHeight) <> 0) Then Begin
        Error.Code := SP_ERR_GRAPHIC_UNSUITED;
        Exit;
      End;

      Result := SP_NewBank(0);

      Idx := SP_FindBankID(Result);
      If Idx > -1 Then Begin

        Bank := SP_BankList[Idx];
        Bank^.DataType := SP_TILEMAP_BANK;
        SetLength(Bank^.Info, SizeOf(SP_TileMap_Info));
        SetLength(Bank^.Memory, (MapWidth * MapHeight) * SizeOf(Integer));

        TMInfo := @Bank^.Info[0];

        TMInfo^.InternalGFX := False;
        TMInfo^.GraphicID := BankID;
        TMInfo^.NumTiles := (Gfx^.Width Div longword(TileWidth)) * (Gfx^.Height Div longword(TileHeight));
        TMInfo^.NumTilesX := Gfx^.Width Div longword(TileWidth);
        TMInfo^.NumTilesY := Gfx^.Height Div longword(TileHeight);
        TMInfo^.MapWidth := MapWidth;
        TMInfo^.MapHeight := MapHeight;
        TMInfo^.TileWidth := TileWidth;
        TMInfo^.TileHeight := TileHeight;
        TMInfo^.GraphicData := Gfx^.Data;
        TMInfo^.GraphicWidth := Gfx^.Width;
        TMInfo^.GraphicTransparent := Gfx^.Transparent;
        TMInfo^.Rotation := 0;
        TMInfo^.Scaling := 1;
        TMInfo^.TileData := @Bank^.Memory[0];
        TMInfo^.DrawX := 0;
        TMInfo^.DrawY := 0;
        TMInfo^.DrawW := 0;
        TMInfo^.DrawH := 0;

        ptr := TMInfo^.TileData;
        For Idx := 0 To (TMInfo^.MapWidth * TMInfo^.MapHeight) -1 Do Begin
          ptr^ := -1;
          Inc(ptr);
        End;

        SP_TileMap_BuildLUT(TMInfo);

      End Else
        Error.Code := SP_ERR_BANK_NOT_FOUND;

    End Else
      Error.Code := SP_ERR_INVALID_BANK;

  End Else
    Error.Code := SP_ERR_BANK_NOT_FOUND;


End;

Function SP_New_Tilemap_FromString(Gfx: aString; MapWidth, MapHeight, TileWidth, TileHeight: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Idx, tW, tH: Integer;
  Bank: pSP_Bank;
  TMInfo: pSP_TileMap_Info;
  Valid: Boolean;
  Trans: Word;
  ptr: pInteger;
Begin

  tW := 0;
  tH := 0;
  Result := -1;

  Valid := False;
  If Gfx = '' Then
    SP_DefaultFill(Gfx, T_INK);

  If Length(Gfx) > 10 Then Begin
    tW := pLongWord(@Gfx[1])^;
    tH := pLongWord(@Gfx[5])^;
    Valid := Length(Gfx) - 10 = tW * tH;
  End;
  If Not Valid Then Begin
    Gfx := SP_StringToTexture(Gfx);
    If Gfx = '' Then
      SP_DefaultFill(Gfx, T_INK);
    tW := pLongWord(@Gfx[1])^;
    tH := pLongWord(@Gfx[5])^;
  End;
  Trans := pWord(@Gfx[9])^;
  If (tW Mod TileWidth <> 0) or (tH Mod TileHeight <> 0) Then Begin
    Error.Code := SP_ERR_GRAPHIC_UNSUITED;
    Exit;
  End;

  Result := SP_NewBank(0);

  Idx := SP_FindBankID(Result);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    Bank^.DataType := SP_TILEMAP_BANK;
    SetLength(Bank^.Info, SizeOf(SP_TileMap_Info));
    SetLength(Bank^.Memory, Length(Gfx) + ((MapWidth * MapHeight) * SizeOf(Integer)));
    CopyMem(@Bank.Memory[0], @Gfx[1], Length(Gfx));

    TMInfo := @Bank^.Info[0];

    TMInfo^.InternalGFX := True;
    TMInfo^.InternalGFXLen := Length(Gfx);
    TMInfo^.GraphicID := -1;
    TMInfo^.NumTiles := (tW Div TileWidth) * (tH Div TileHeight);
    TMInfo^.NumTilesX := tW Div TileWidth;
    TMInfo^.NumTilesY := tH Div TileHeight;
    TMInfo^.MapWidth := MapWidth;
    TMInfo^.MapHeight := MapHeight;
    TMInfo^.TileWidth := TileWidth;
    TMInfo^.TileHeight := TileHeight;
    TMInfo^.GraphicData := @Bank^.Memory[0];
    TMInfo^.GraphicWidth := tW;
    TMInfo^.GraphicTransparent := Trans;
    TMInfo^.Rotation := 0;
    TMInfo^.Scaling := 1;
    TMInfo^.TileData := @Bank^.Memory[Length(Gfx)];
    TMInfo^.DrawX := 0;
    TMInfo^.DrawY := 0;
    TMInfo^.DrawW := 0;
    TMInfo^.DrawH := 0;

    ptr := TMInfo^.TileData;
    For Idx := 0 To (TMInfo^.MapWidth * TMInfo^.MapHeight) -1 Do Begin
      ptr^ := -1;
      Inc(ptr);
    End;

    SP_TileMap_BuildLUT(TMInfo);

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Tilemap_Set(TileMapID, X, Y, Tile: Integer; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  TileMap: pSP_Tilemap_Info;
Begin

  Idx := SP_FindBankID(TileMapId);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_TILEMAP_BANK Then Begin

      TileMap := @Bank^.Info[0];

      If (X < TileMap^.MapWidth) and (X >= 0) and (Y >= 0) and (Y < TileMap^.MapHeight) And (Tile <= TileMap^.NumTiles) Then Begin

        pInteger(NativeUInt(TileMap^.TileData) + LongWord(((X + (Y * TileMap^.MapWidth)) * SizeOf(Integer))))^ := Tile;
        Bank^.Changed := True;

      End Else

        Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE;

    End Else
      Error.Code := SP_ERR_INVALID_BANK;

  End Else
    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Tilemap_GraphicBank(TileMapID, GraphicID, TileWidth, TileHeight: Integer; Var Error: TSP_ErrorCode);
Var
  Idx, Nt: Integer;
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
  TileMap: pSP_TileMap_Info;
  Ptr: pInteger;
Begin

  Idx := SP_FindBankID(GraphicID);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Gfx := @Bank^.Info[0];

      Idx := SP_FindBankID(TileMapID);
      If Idx > -1 Then Begin

        Bank := SP_BankList[Idx];
        If Bank^.DataType = SP_TILEMAP_BANK Then Begin

          TileMap := @Bank^.Info[0];

          // Check this bank for compatibility - count tiles used, make sure there's enough in the
          // new bank. Tile *size* isn't important, but we need to know there's enough tiles to draw
          // the current map.

          If (Gfx^.Width Mod longword(TileWidth) <> 0) or (Gfx^.Height Mod longword(TileHeight) <> 0) Then Begin
            Error.Code := SP_ERR_GRAPHIC_UNSUITED;
            Exit;
          End;

          Nt := (Gfx^.Width Div longword(TileWidth)) * (Gfx^.Height Div longword(TileHeight));
          Ptr := TileMap.TileData;
          Idx := 0;
          While Idx < TileMap.MapWidth * TileMap.MapHeight Do Begin
            If Ptr^ > Nt Then Begin
              Error.Code := SP_ERR_GRAPHIC_UNSUITED;
              Exit;
            End;
            Inc(Idx);
            Inc(Ptr);
          End;

          If TileMap^.InternalGFX Then Begin
            // Convert from internal graphic to external graphic bank -
            // remove the internal graphic and update pointers
            TileMap^.InternalGFX := False;
            CopyMem(@Bank^.Memory[0], @Bank^.Memory[TileMap^.InternalGFXLen], Length(Bank^.Memory) - integer(TileMap^.InternalGFXLen));
            SetLength(Bank^.Memory, Length(Bank^.Memory) - integer(TileMap^.InternalGFXLen));
            TileMap^.InternalGFXLen := 0;
            TileMap^.TileData := @Bank^.Memory[0];
          End;

          // Update the tilemap info structure with info on the new bank

          TileMap^.GraphicID := GraphicID;
          TileMap^.NumTilesX := integer(Gfx^.Width) Div TileWidth;
          TileMap^.NumTilesY := integer(Gfx^.Height) Div TileHeight;
          TileMap^.TileWidth := TileWidth;
          TileMap^.TileHeight := TileHeight;
          TileMap^.GraphicData := Gfx^.Data;
          TileMap^.GraphicWidth := Gfx^.Width;
          TileMap^.GraphicTransparent := Gfx^.Transparent;

          SP_TileMap_BuildLUT(TileMap);

          Bank^.Changed := True;

        End Else

          Error.Code := SP_ERR_INVALID_BANK;

      End Else

        Error.Code := SP_ERR_BANK_NOT_FOUND;

    End Else

      Error.Code := SP_ERR_INVALID_BANK;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Tilemap_GraphicString(TileMapID, TileWidth, TileHeight: Integer; Graphic: aString; Var Error: TSP_ErrorCode);
Var
  Valid: Boolean;
  Idx, tW, tH, Nt: Integer;
  Bank: pSP_Bank;
  TileMap: pSP_TileMap_Info;
  Ptr: pInteger;
  Trans: Word;
Begin

  tH := 0;
  tW := 0;

  // Check the graphic string for validity

  Valid := False;
  If Graphic = '' Then
    SP_DefaultFill(Graphic, T_INK);

  If Length(Graphic) > 10 Then Begin
    tW := pLongWord(@Graphic[1])^;
    tH := pLongWord(@Graphic[5])^;
    Valid := Length(Graphic) - 10 = tW * tH;
  End;
  If Not Valid Then Begin
    Graphic := SP_StringToTexture(Graphic);
    If Graphic = '' Then
      SP_DefaultFill(Graphic, T_INK);
    tW := pLongWord(@Graphic[1])^;
    tH := pLongWord(@Graphic[5])^;
  End;
  Trans := pWord(@Graphic[9])^;
  If (tW Mod TileWidth <> 0) or (tH Mod TileHeight <> 0) Then Begin
    Error.Code := SP_ERR_GRAPHIC_UNSUITED;
    Exit;
  End;

  // Now locate the tilemap and perform bank -> string conversion if necessary

  Idx := SP_FindBankID(TileMapID);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_TILEMAP_BANK Then Begin

      TileMap := @Bank^.Info[0];

      Nt := (tW Div TileWidth) * (tH Div TileHeight);
      Ptr := TileMap.TileData;
      Idx := 0;
      While Idx < TileMap.MapWidth * TileMap.MapHeight Do Begin
        If Ptr^ > Nt Then Begin
          Error.Code := SP_ERR_GRAPHIC_UNSUITED;
          Exit;
        End;
        Inc(Idx);
        Inc(Ptr);
      End;

      // Check if this is a Graphic Bank based tilemap, and convert to string based
      // if necessary.

      If Not TileMap^.InternalGFX Then Begin
        // Convert from external graphic bank to internal graphic string -
        // add the internal graphic and update pointers
        TileMap^.InternalGFX := True;
        TileMap^.InternalGFXLen := Length(Graphic);
        SetLength(Bank^.Memory, Length(Bank^.Memory) + integer(TileMap^.InternalGFXLen));
        CopyMem(@Bank^.Memory[0], @Graphic[1], Length(Graphic));
        TileMap^.TileData := @Bank^.Memory[TileMap^.InternalGFXLen];
      End;

      // Update the tilemap info structure with info on the new bank

      TileMap^.GraphicID := -1;
      TileMap^.NumTilesX := tW Div TileWidth;
      TileMap^.NumTilesY := tH Div TileHeight;
      TileMap^.TileWidth := TileWidth;
      TileMap^.TileHeight := TileHeight;
      TileMap^.GraphicData := @Bank.Memory[0];
      TileMap^.GraphicWidth := tW;
      TileMap^.GraphicTransparent := Trans;

      SP_TileMap_BuildLUT(TileMap);

      Bank^.Changed := True;

    End Else

      Error.Code := SP_ERR_INVALID_BANK;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_Tilemap_BuildLUT(TileMap: pSP_TileMap_Info);
Var
  cT: Integer;
  ptr: pByte;
Begin

  For cT := 0 To (TileMap^.NumTilesY * TileMap^.NumTilesX) -1 Do Begin

    ptr := TileMap^.GraphicData;
    If TileMap^.InternalGFX Then Inc(ptr, (SizeOf(LongWord) * 2) + SizeOf(Word));
    Inc(ptr, (cT Div TileMap^.NumTilesY) * TileMap^.TileHeight * TileMap^.GraphicWidth);
    Inc(ptr, (cT Mod TileMap^.NumTilesX) * TileMap^.TileWidth);
    TileMap^.TileLUT[cT] := ptr;

  End;

End;

Procedure SP_Tilemap_Clear(TileMapID: Integer; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  TileMap: pSP_TileMap_Info;
  ptr: pInteger;
Begin

  Idx := SP_FindBankID(TileMapID);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_TILEMAP_BANK Then Begin

      TileMap := @Bank^.Info[0];
      ptr := TileMap^.TileData;
      For Idx := 0 To (TileMap^.MapWidth * TileMap^.MapHeight) -1 Do Begin
        ptr^ := -1;
        Inc(ptr);
      End;

    End Else

      Error.Code := SP_ERR_INVALID_BANK;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Procedure SP_TileMap_Draw(TileMapID, OffX, OffY, ToX, ToY, ToW, ToH, RX, RY: Integer; Rotate, Scale: aFloat; Var Error: TSP_ErrorCode);
Var
  destPtr, srcPtr: pByte;
  Idx, CurTile, tX, tY: Integer;
  tmPtr: pInteger;
  pX, pY, SrcX, SrcY, tmWidth, tmHeight, tWidth, tHeight: Integer;
  tdw, tdh, tdx, tdy, nxtrow, w, h: LongWord;
  Bank: pSP_Bank;
  TileMap: pSP_TileMap_Info;
  Transparent: Boolean;
  Clr, tClr: Byte;
  pxPrime, pyPrime, mw, gw, dx, dy, pyPreSin, pyPreCos: Integer;
  iSin, iCos, iScale: integer;
Begin

  tdh := 0;
  tClr := 0;
  SrcX := 0; SrcY := 0;

  // Render the tilemap to the rectangle described by ToX/Y/W/H, with rotation and scaling.
  // Two render paths - one for regular drawing and one for rotation/scaling ensures that basic
  // tilemap rendering is as fast as possible.

  // OffX and OffY are an offset from the top-left of the tilemap.

  Idx := SP_FindBankID(TileMapID);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    TileMap := @Bank^.Info[0];

    If Bank^.DataType <> SP_TILEMAP_BANK Then Begin
      Error.Code := SP_ERR_INVALID_BANK;
      Exit;
    End;

    If Not TileMap^.InternalGFX Then Begin

      Idx := SP_FindBankID(TileMap^.GraphicID);
      If Idx > -1 Then Begin

        If SP_BankList[Idx]^.DataType <> SP_GRAPHIC_BANK then Begin

          Error.Code := SP_ERR_INVALID_BANK;
          Exit;

        End;

      End Else Begin

        Error.Code := SP_ERR_GRAPHIC_LOST;
        Exit;

      End;

    End;

    tmPtr := TileMap^.TileData;
    tWidth := TileMap^.TileWidth;
    tHeight := TileMap^.TileHeight;

    If TileMap^.GraphicTransparent <> $FFFF Then Begin
      Transparent := True;
      tClr := TileMap^.GraphicTransparent And $FF;
    End Else
      Transparent := False;

    // First, make sure the rects (destination and cliprect) intersect, then get the intersection.
    // Treat the tilemap as a large bitmap. We're not concerned with the actual tile graphics at this point.

    mw := TileMap^.MapWidth;
    tmWidth := mw * TileMap^.TileWidth;
    tmHeight := TileMap^.MapHeight * TileMap^.TileHeight;
    gw := TileMap^.GraphicWidth;

    If (ToX = -1) And (ToW = -1) Then Begin

      ToX := 0;
      ToY := 0;
      ToW := SCREENWIDTH;
      ToH := SCREENHEIGHT;

    End Else Begin

      If (ToX >= SCREENWIDTH) or (ToY >= SCREENHEIGHT) or (ToX + ToW < 0) or (ToY + ToH < 0) or
        (OffX > tmWidth) or (OffY > tmHeight) or (OffX + tmWidth < 0) or (OffY + tmHeight < 0) Then Exit;

      // After this, SrcX/Y/W/H describe a rectangle on the tilemap, and the ToX/Y/W/H vars describe the destination rectangle
      // on the destination surface. OffX/OffY are modified to suit if necessary.
      // Note that Unused areas of the tilemap are *not* rendered.

      If ToX < 0 Then Begin
        Dec(OffX, ToX);
        Inc(ToW, ToX);
        ToX := 0;
      End;

      If ToY < 0 Then Begin
        Dec(OffY, ToY);
        Inc(ToH, ToY);
        ToY := 0;
      End;

      If ToX + ToW >= SCREENWIDTH Then ToW := SCREENWIDTH - ToX;
      If ToY + ToH >= SCREENHEIGHT Then ToH := SCREENHEIGHT - ToY;

    End;

    // Test for clipping and adjust TOX/Y/W/H as necessary

    If ToX < T_CLIPX1 Then Begin
      Inc(OffX, T_CLIPX1 - ToX);
      ToX := T_CLIPX1;
    End;

    If ToY < T_CLIPY1 Then Begin
      Inc(OffY, T_CLIPY1 - ToY);
      ToY := T_CLIPY1;
    End;

    If ToX + ToW >= T_CLIPX2 Then
      ToW := T_CLIPX2 - ToX;

    If ToY + ToH >= T_CLIPY2 Then
      ToH := T_CLIPY2 - ToY;

    If (Rotate = 0) And (Scale = 1) Then Begin

      If OffX < 0 Then Begin
        Dec(ToX, OffX);
        Inc(ToW, OffX);
        OffX := 0;
      End;

      If OffY < 0 Then Begin
        Dec(ToY, OffY);
        Inc(ToH, OffY);
        OffY := 0;
      End;

      If ToW + OffX > tmWidth Then ToW := tmWidth - OffX;
      If ToH + OffY > tmHeight Then ToH := tmHeight - OffY;

      // Determine the extent of the visible area on the tilemap, in pixels

      SrcX := OffX;
      SrcY := OffY;

      // Modify OffX and OffY to offset into a tile, rather than into the tilemap now that we have our
      // starting tile position.

      OffX := OffX Mod tWidth;
      OffY := OffY Mod tHeight;

    End;

    // Now render the tilemap. Iterating in tile-sizes over the destination rect, draw one tile at a time.
    // tX and tY indicate our position within the tilemap.

    tX := SrcX Div tWidth;
    tY := SrcY Div tHeight;

    DestPtr := SCREENPOINTER;
    Inc(DestPtr, ToX + (ToY * SCREENWIDTH));

    If (Rotate = 0) And (Scale = 1) Then Begin

      pY := 0;

      While pY < ToH Do Begin

        pX := 0;

        While pX < ToW Do Begin

          // Determine which tile we're in

          CurTile := pInteger(NativeUInt(tmPtr) + LongWord(((tX + (tY * TileMap^.MapWidth)) * SizeOf(Integer))))^;

          // Now figure out how much of the tile we are to draw. tdx and tdy are the starting coords within the tile
          // and tdw/tdh are the amount of width and height to draw. These only affect tiles at the edges of the visible
          // area.

          If pX = 0 Then tdx := OffX Else tdx := 0;
          If pX + tWidth - integer(tdx) >= ToW Then tdw := ToW - pX Else tdw := tWidth - integer(tdx);
          If pY = 0 Then tdy := OffY Else tdy := 0;
          If pY + tHeight - integer(tdy) >= ToH Then tdh := ToH - pY Else tdh := tHeight - integer(tdy);

          If CurTile > -1 Then Begin

            // Find the source offset of the topleft pixel in the tile

            SrcPtr := TileMap^.TileLut[CurTile];
            Inc(SrcPtr, (tdy * LongWord(TileMap^.GraphicWidth)) + tdx);

            // Because we might not be drawing a complete tile width-wise, we need to know how far to jump to the next
            // row of the tile graphic

            nxtrow := LongWord(TileMap^.GraphicWidth) - tdw;

            // Now draw the tile!

            h := tdh;

            If T_OVER = 0 Then Begin

              If Transparent Then Begin

                While h > 0 Do Begin

                  w := tdw;

                  While w > 0 Do begin

                    Clr := SrcPtr^;
                    If Clr <> tClr Then
                      DestPtr^ := Clr;
                    Inc(DestPtr);
                    Inc(SrcPtr);
                    Dec(w);

                  End;

                  Inc(SrcPtr, nxtrow);
                  Inc(DestPtr, LongWord(SCREENWIDTH) - tdw);
                  Dec(h);

                End;

              End Else

                While h > 0 Do Begin

                  w := tdw;

                  {$IFDEF CPU64}
                  While w > SizeOf(LongWord) Do Begin
                    pNativeUInt(DestPtr)^ := pNativeUInt(SrcPtr)^;
                    Dec(w, SizeOf(NativeUInt));
                    Inc(pNativeUInt(DestPtr));
                    Inc(pNativeUInt(SrcPtr));
                  End;
                  {$ENDIF}
                  While w > SizeOf(LongWord) Do Begin
                    pLongWord(DestPtr)^ := pLongWord(SrcPtr)^;
                    Dec(w, SizeOf(LongWord));
                    Inc(pLongWord(DestPtr));
                    Inc(pLongWord(SrcPtr));
                  End;
                  While w > 0 Do begin

                    DestPtr^ := SrcPtr^;
                    Inc(DestPtr);
                    Inc(SrcPtr);
                    Dec(w);

                  End;

                  Inc(SrcPtr, nxtrow);
                  Inc(DestPtr, LongWord(SCREENWIDTH) - tdw);
                  Dec(h);

                End;

            End Else Begin

              If Transparent Then Begin

                While h > 0 Do Begin

                  w := tdw;

                  While w > 0 Do begin

                    Clr := SrcPtr^;
                    If Clr <> tClr Then
                      SP_OverPixelPtrVal(DestPtr, Clr, T_OVER);
                    Inc(DestPtr);
                    Inc(SrcPtr);
                    Dec(w);

                  End;

                  Inc(SrcPtr, nxtrow);
                  Inc(DestPtr, LongWord(SCREENWIDTH) - tdw);
                  Dec(h);

                End;

              End Else

                While h > 0 Do Begin

                  w := tdw;

                  While w > 0 Do begin

                    SP_OverPixelPtr(DestPtr, SrcPtr, T_OVER);
                    Inc(DestPtr);
                    Inc(SrcPtr);
                    Dec(w);

                  End;

                  Inc(SrcPtr, nxtrow);
                  Inc(DestPtr, LongWord(SCREENWIDTH) - tdw);
                  Dec(h);

                End;

            End;

            // Move to the next tile

            Inc(pX, tdw);
            Dec(DestPtr, (tdh * LongWord(SCREENWIDTH)) - tdw);
            Inc(tX);

          End Else Begin

            // Invalid (-1) tile - skip to the next in the row

            Inc(pX, tdw);
            Inc(DestPtr, tdw);
            Inc(tX);

          End;

        End;

        Inc(tY);
        Inc(pY, tdh);
        tX := SrcX Div tWidth;
        DestPtr := pByte(NativeUInt(SCREENPOINTER) + LongWord(ToX + ((ToY + pY) * SCREENWIDTH)));

      End;

      If SCREENVISIBLE Then SP_SetDirtyRect(ToX, ToY, ToX + ToW, ToY + ToH);
      SP_NeedDisplayUpdate := True;

    End Else Begin

      // Slower than the above - iterate over the destination rectangle, and translate those pixels to the tilemap.
      // Then colour the pixels according to tilemap position.

      Rotate := -Rotate;
      iSin := Round(Sin(Rotate) * 65536);
      iCos := Round(Cos(Rotate) * 65536);
      iScale := Round((1/Scale) * 65536);
      DestPtr := SCREENPOINTER;
      Inc(DestPtr, ToX + (ToY * SCREENWIDTH));
      Dec(rX, OffX);
      Dec(rY, OffY);
      Rx := Round(Rx  * Scale);
      Ry := Round(Ry  * Scale);

      If T_OVER = 0 Then Begin

        If Transparent Then Begin

          For pY := 0 To ToH -1 Do Begin

            pYPrime := pY - RY;
            pyPreSin := pYPrime * iSin;
            pyPreCos := pYPrime * iCos;

            For pX := 0 To ToW -1 Do Begin

              pXPrime := pX - RX;
              dX := OffX + ((RX + (pXPrime * iCos - PyPreSin) Div 65536) * iScale) Div 65536;
              dY := OffY + ((RY + (pXPrime * iSin + PyPreCos) Div 65536) * iScale) Div 65536;

              If (dX < tmWidth) and (dY < tmHeight) and (dX >= 0) and (dY >= 0) Then Begin
                tx := dX Div tWidth;
                ty := dY Div tHeight;
                CurTile := pInteger(NativeUint(tmPtr) + LongWord(((tX + (tY * TileMap^.MapWidth)) * SizeOf(Integer))))^;
                If CurTile > -1 Then Begin
                  SrcPtr := TileMap^.TileLut[CurTile];
                  Inc(SrcPtr, ((dy Mod tHeight) * gw) + (dx Mod tWidth));
                  If SrcPtr^ <> tClr Then
                    DestPtr^ := SrcPtr^;
                End;
              End;

              Inc(DestPtr);

            End;

            Inc(DestPtr, SCREENWIDTH - ToW);

          End;

        End Else Begin

          For pY := 0 To ToH -1 Do Begin

            pYPrime := pY - RY;
            pyPreSin := pYPrime * iSin;
            pyPreCos := pYPrime * iCos;

            For pX := 0 To ToW -1 Do Begin

              pXPrime := pX - RX;
              dX := OffX + ((RX + (pXPrime * iCos - PyPreSin) Div 65536) * iScale) Div 65536;
              dY := OffY + ((RY + (pXPrime * iSin + PyPreCos) Div 65536) * iScale) Div 65536;

              If (dX < tmWidth) and (dY < tmHeight) and (dX >= 0) and (dY >= 0) Then Begin
                tx := dX Div tWidth;
                ty := dY Div tHeight;
                CurTile := pInteger(NativeUInt(tmPtr) + LongWord(((tX + (tY * TileMap^.MapWidth)) * SizeOf(Integer))))^;
                If CurTile > -1 Then Begin
                  SrcPtr := TileMap^.TileLut[CurTile];
                  Inc(SrcPtr, ((dy Mod tHeight) * gw) + (dx Mod tWidth));
                  DestPtr^ := SrcPtr^;
                End;
              End;

              Inc(DestPtr);

            End;

            Inc(DestPtr, SCREENWIDTH - ToW);

          End;

        End;

      End Else Begin

        If Transparent Then Begin

          For pY := 0 To ToH -1 Do Begin

            pYPrime := pY - RY;
            pyPreSin := pYPrime * iSin;
            pyPreCos := pYPrime * iCos;

            For pX := 0 To ToW -1 Do Begin

              pXPrime := pX - RX;
              dX := OffX + ((RX + (pXPrime * iCos - PyPreSin) Div 65536) * iScale) Div 65536;
              dY := OffY + ((RY + (pXPrime * iSin + PyPreCos) Div 65536) * iScale) Div 65536;

              If (dX < tmWidth) and (dY < tmHeight) and (dX >= 0) and (dY >= 0) Then Begin
                tx := dX Div Integer(tWidth);
                ty := dY Div Integer(tHeight);
                CurTile := pInteger(NativeInt(NativeUInt(tmPtr)) + ((tX + (tY * Integer(TileMap^.MapWidth))) * SizeOf(Integer)))^;
                If CurTile > -1 Then Begin
                  SrcPtr := TileMap^.TileLut[CurTile];
                  Inc(SrcPtr, ((dy Mod Integer(tHeight)) * gw) + (dx Mod Integer(tWidth)));
                  If SrcPtr^ <> tClr then
                    SP_OverPixelPtr(DestPtr, SrcPtr, T_OVER);
                End;
              End;

              Inc(DestPtr);

            End;

            Inc(DestPtr, SCREENWIDTH - ToW);

          End;

        End Else Begin

          For pY := 0 To ToH -1 Do Begin

            pYPrime := Integer(pY) - RY;
            pyPreSin := pYPrime * iSin;
            pyPreCos := pYPrime * iCos;

            For pX := 0 To ToW -1 Do Begin

              pXPrime := Integer(pX) - RX;
              dX := OffX + ((RX + (pXPrime * iCos - PyPreSin) Div 65536) * iScale) Div 65536;
              dY := OffY + ((RY + (pXPrime * iSin + PyPreCos) Div 65536) * iScale) Div 65536;

              If (dX < Integer(tmWidth)) and (dY < Integer(tmHeight)) and (dX >= 0) and (dY >= 0) Then Begin
                tx := dX Div Integer(tWidth);
                ty := dY Div Integer(tHeight);
                CurTile := pInteger(NativeInt(NativeUInt(tmPtr)) + ((tX + (tY * Integer(TileMap^.MapWidth))) * Integer(SizeOf(Integer))))^;
                If CurTile > -1 Then Begin
                  SrcPtr := TileMap^.TileLut[CurTile];
                  Inc(SrcPtr, ((dy Mod Integer(tHeight)) * gw) + (dx Mod Integer(tWidth)));
                  SP_OverPixelPtr(DestPtr, SrcPtr, T_OVER);
                End;
              End;

              Inc(DestPtr);

            End;

            Inc(DestPtr, SCREENWIDTH - ToW);

          End;

        End;

      End;

      If SCREENVISIBLE Then SP_SetDirtyRect(ToX, ToY, ToX + ToW, ToY + ToH);
      SP_NeedDisplayUpdate := True;

    End;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

Function SP_GetTile(id, x, y: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Idx: Integer;
  Bank: pSP_Bank;
  TileMap: pSP_TileMap_Info;
  ptr: pInteger;
Begin

  Result := -1;
  Idx := SP_FindBankID(ID);
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_TILEMAP_BANK Then Begin

      TileMap := @Bank^.Info[0];
      ptr := TileMap^.TileData;
      If (x >= 0) and (x < TileMap^.NumTilesX) and (y >= 0) and (y < TileMap^.NumTilesY) Then Begin
        Inc(ptr, (y * TileMap^.NumTilesX) + x);
        Result := ptr^;
      End Else

        Result := -1;

    End Else

      Error.Code := SP_ERR_INVALID_BANK;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

End;

end.


