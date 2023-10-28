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

unit SP_Graphics;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}

// Various routines for drawing graphics and shit like that.

interface

Uses

  Math, Classes, GraphUtil, SyncObjs, SP_SysVars, SP_Errors, SP_Util, SP_BankManager, SP_BankFiling, SP_FileIO, SP_Streams, SP_Menu;

Type

  TSP_Point = Packed Record X, Y: aFloat; End;
  TCB_SetScreenRes = Function(Width, Height, sWidth, sHeight: Integer; FullScreen: Boolean): Integer;
  TCB_Refresh_Display = Procedure;
  TCB_UpdateScreenPointer = Procedure;
  TCB_Test_Resolution = Function(Width, Height: Integer; FullScreen: Boolean): Boolean;
  TCB_Load_Image = Procedure(Filename: aString; var Error: TSP_ErrorCode);
  TCB_Save_Image = Procedure(Filename: aString; w, h: Integer; Pixels, Palette: pByte);
  TCB_Free_Image = Procedure;
  TWindowSprites = Array of pSP_Sprite_Info;
  TRct = Packed Record
    x, y, w, h: Word;
  End;

Procedure SP_RadToAngle(var Angle: aFloat); inline;
Procedure SP_AngleToRad(var Angle: aFloat); inline;
Procedure SP_InitialGfxSetup(W, H: Integer; IsNEW: Boolean);
Procedure SP_CreateSystemUDGs(ID: Integer);
Procedure SP_ForceScreenUpdate;
Procedure SP_WaitForSync;
Function  SP_GetPalette(Idx: Integer): LongWord;
Procedure SP_SetWindowPalette(Idx, R, G, B: Integer);
Procedure SP_InvalidateWholeDisplay;
Procedure SP_SetDirtyRect(x1, y1, x2, y2: Integer);
Procedure SP_SetDirtyRectEx(x1, y1, x2, y2: Integer);
Procedure SP_SetCurrentWindowSettings;
Procedure SP_SetDrawingWindow(WindowID: Integer);
Function  SP_GrabCurrentWindow: aString;
Procedure SP_PutCurrentWindow(Var Str: aString);
Procedure SP_ChangeRes(Width, Height, sWidth, sHeight: Integer; FullScreen: Boolean; Var Error: TSP_ErrorCode);
Procedure SP_ResizeWindow(WindowID, W, H, Depth: Integer; FullScreen: Boolean; Var Error: TSP_ErrorCode);
Procedure SP_MoveWindow(WindowID, X, Y: Integer; Var Error: TSP_ErrorCode);
Procedure SP_DeleteWindow(WindowID: Integer; Var Error: TSP_ErrorCode);
Procedure SP_SetWindowOrigin(WindowID: Integer; X, Y, W, H: aFloat; Flip: Boolean; Var Error: TSP_ErrorCode);
Procedure SP_SetWindowOriginNoExt(WindowID: Integer; X, Y: aFloat; Flip: Boolean; Var Error: TSP_ErrorCode);
Procedure SP_SetWindowOriginOff(WinID: Integer; Var Error: TSP_ErrorCode);
Procedure SP_GetWindowDetails(WindowID: Integer; Var Window: pSP_Window_Info; Var Error: TSP_ErrorCode);// Inline;
Function  SP_GetWindowLeft(WindowID: Integer; Var Error: TSP_ErrorCode): Integer;
Function  SP_GetWindowTop(WindowID: Integer; Var Error: TSP_ErrorCode): Integer;
Function  SP_GetWindowWidth(WindowID: Integer; Var Error: TSP_ErrorCode): Integer;
Function  SP_GetWindowHeight(WindowID: Integer; Var Error: TSP_ErrorCode): Integer;
Procedure SP_DeleteAllWindows;
Procedure SP_SetPalette(Index: Integer; Colours: Array of TP_Colour);
Procedure SP_FillRect(X, Y, W, H: Integer; Colour: LongWord);
Procedure SP_Scroll(Dy: Integer);
Procedure SP_Reset_Temp_Colours; inline;
Function  SP_TextOut(BankID, X, Y: Integer; const Text: aString; Ink, Paper: Integer; Visible: Boolean; ShowSpecial: Boolean = False): Integer;
Function  SP_PRINT(BankID, X, Y, CPos: Integer; const Text: aString; Ink, Paper: Integer; var Error: TSP_ErrorCode): Integer;
Procedure SP_CLS(Paper: LongWord);
Function  SP_Get_Contrasting_INK(Index: Integer): Integer;
Function  SP_Get_Nearest_Colour(R, G, B: Byte; Exclude: Integer):Integer;
Function  SP_Get_Opposite_Colour(R,G,B: Byte): Integer;
Procedure SP_RGBToHSV(Const R,G,B: aFloat; Var H,S,V: aFloat);
Procedure SP_HSVtoRGB(H,S,V: aFloat; Var R,G,B: aFloat);
Procedure SP_CLS_Lower(Paper: LongWord);
Procedure SP_Restore_Lower;
Function  SP_LineClip(Var x1, y1, x2, y2: Integer; cx1, cy1, cx2, cy2: Integer): Boolean;
Procedure SP_DrawLine(X2, Y2: aFloat);
Procedure SP_DrawLineEx(X1, Y1, X2, Y2: aFloat);
Procedure SP_DrawRect(x1, y1, x2, y2: Integer; Ink: Byte);
Procedure SP_DrawSpeccyCurve(X, Y, Angle: aFloat);
Procedure SP_DrawEllipse(CX, CY, Rx, Ry: Integer);
Procedure SP_DrawTexEllipse(CX, CY, Rx, Ry: Integer; const TextureStr: aString; tW, tH: LongWord);
Procedure SP_DrawSolidEllipse(CX, CY, Rx, Ry: Integer);
Procedure SP_SetPixel(X, Y: aFloat);
Procedure SP_DrawCurve(CurveStartX, CurveStartY, X, Y, CurveEndX, CurveEndY: aFloat; N: Integer);
Procedure SP_GetRegion(Src: pByte; SrcW, SrcH: LongWord; Var Dest: aString; rX, rY, rW, rH, T: Integer; Var Error: TSP_ErrorCode);
Procedure SP_PutRegion(Dst: pByte; dX, dY: Integer; dW, dH: LongWord; Src: pByte; SrcLen: Integer; RotAngle, Scale: aFloat; Var cX1, cY1, cX2, cY2: Integer; Var Error: TSP_ErrorCode);
Procedure SP_PutRegion_NO_OVER(Dst: pByte; dX, dY: Integer; dW, dH: LongWord; Src: pByte; SrcLen: Integer; Var cX1, cY1, cX2, cY2: Integer; Var Error: TSP_ErrorCode);
Function  SP_StringToTexture(const Str: aString; UseLiterals: Boolean = False): aString;
Function  SP_FindUDG(ChrIndex: Integer; Var Error: TSP_ErrorCode): Integer;
Procedure SP_VScroll(Dst: pByte; Width, Height, Amount: Integer; Wrap: Boolean);
Procedure SP_HScroll(Dst: pByte; Width, Height, Bpp, Amount: Integer; Wrap: Boolean);
Procedure SP_FloodFill(Dst: pByte; dX, dY, dW, dH: LongWord; Clr: Byte);
Procedure SP_TextureFill(Dst: pByte; dX, dY, dW, dH: LongWord; const Texture: aString; tW, tH: LongWord);
Procedure SP_GWFloodFill(Dst: pByte; dX, dY, dW, dH: LongWord; Clr, BClr: Byte);
Procedure SP_DrawRectangle(X1, Y1, X2, Y2: Integer);
Procedure SP_DrawTexRectangle(X1, Y1, X2, Y2: Integer; const TextureStr: aString; tW, tH: LongWord);
Procedure SP_DrawSolidRectangle(X1, Y1, X2, Y2: Integer);
Procedure SP_PolygonFill(Var Points: Array of TSP_Point; const TextureStr: aString; tW, tH: LongWord);
Procedure SP_PolygonSolidFill(Var Points: Array of TSP_Point);
Procedure SP_CopyRect(SrcPtr: pByte; SrcW, SrcH, SrcRx, SrcRy, SrcRw, SrcRh: Integer; DstPtr: pByte; DstW, DstH, DstX, DstY, DcW, DcH, cx1, cy1, cx2, cy2: Integer; Var Error: TSP_ErrorCode);
Procedure SP_SavePalette(const Filename: aString; Var Error: TSP_ErrorCode);
Procedure SP_LoadPalette(const Filename: aString; Var Error: TSP_ErrorCode);
Procedure SP_RotateSize(Src: pByte; sW, sH: Integer; Dst: pByte; dX, dY, dW, dH: Integer; Trans: Word; Rot, Scale: aFloat; cX1, cY1, cX2, cY2: Integer);
Procedure SP_RotateSizeXY(Src: pByte; sW, sH: Integer; Dst: pByte; dX, dY, dW, dH: Integer; Trans: Word; Rot, ScaleX, ScaleY: aFloat; cX1, cY1, cX2, cY2: Integer);
Function  SP_WindowVisible(WindowID: Integer; var Error: TSP_ErrorCode): Boolean;
Procedure SP_WindowSetVisible(WindowID: Integer; Visible: Boolean; var Error: TSP_ErrorCode);
Function  SP_TextToGraphic(const Text: aString; Var Error: TSP_ErrorCode): aString;
Procedure SP_RotAndScaleGfx(Var SrcPtr: pByte; Var DstGfx: aString; Rot, Scale: aFloat; Var sW, sH: LongWord; sT: Word; Error: TSP_ErrorCode);
Procedure SP_RotAndScaleGfxXY(Var SrcPtr: pByte; Var DstGfx: aString; Rot, ScaleX, ScaleY: aFloat; Var sW, sH: LongWord; sT: Word; Error: TSP_ErrorCode);
Procedure SP_FlipGfx(Src: pByte; W, H: LongWord);
Procedure SP_MirrorGfx(Src: pByte; W, H: LongWord);
Procedure SP_Dither_Image(Var Gfx: pSP_Graphic_Info; DitherType: Integer);
Procedure SP_DrawMouseImage;
Procedure SP_SaveMouseRegion;
Procedure SP_RestoreMouseRegion;
Procedure SP_MousePointerFromGraphic(BankID, HotX, HotY: Integer; Var Error: TSP_ErrorCode);
Procedure SP_MousePointerFromString(Graphic: aString; HotX, HotY: Integer);
Procedure SP_MousePointerFromDefault;

Procedure SP_ConvertWToOrigin_d(Var X, Y: aFloat; Win: pSP_Window_Info); inline;
Procedure SP_ConvertToOrigin_d(var X, Y: aFloat); inline;
Procedure SP_ConvertToOrigin_i(var X, Y: Integer); inline;
Procedure SP_ConvertToOrigin_l(var X, Y: LongWord); inline;
Procedure SP_ConvertToOrigin_i_x(var X: Integer); inline;
Procedure SP_ConvertToOrigin_i_y(var Y: Integer); inline;
Procedure SP_ConvertToOrigin_d_x(var X: aFloat); inline;
Procedure SP_ConvertToOrigin_d_y(var Y: aFloat); inline;
Function  SP_ConvertToScreenX(X: aFloat): aFloat;  inline;
Function  SP_ConvertToScreenY(Y: aFloat): aFloat; inline;

Procedure SP_OverPixelPtr(Var c1, c2: pByte; Over: Integer); inline;
Procedure SP_OverPixelPtrVal(c1: pByte; c2: Byte; Over: Integer); inline;
Procedure SP_OverPixelPtrl(Var c1, c2: pLongWord; Over: Integer); inline;

Procedure SP_DefaultFill(Var Str: aString; Clr: Byte); Inline;
Procedure SP_DRAWGW(Const str: aString; Var Error: TSP_ErrorCode);

Var

  CB_Refresh_Display: TCB_Refresh_Display;
  CB_SetScreenRes: TCB_SetScreenRes;
  CB_UpdateScreenPointer: TCB_UpdateScreenPointer;
  CB_Test_Resolution: TCB_Test_Resolution;
  CB_Load_Image: TCB_Load_Image;
  CB_Save_Image: TCB_Save_Image;
  CB_Free_Image: TCB_Free_Image;
  SetDR: Boolean = False;
  DPtrBackup: Pointer;
  MOUSEPALETTE: Array[0..255] of TP_Colour;

  {$IFDEF FPC}
  DispRects: Array[0..65535] of TRct;
  GfxUpdRect: Integer;
  {$ENDIF}

  WindowSpriteList: Array of TWindowSprites;

  ImgWidth, ImgHeight, ImgStride, ImgBpp: Integer;
  ImgPtr: pByte;
  ImgPalette: Array[0..255] of TP_Colour;
  FillQueue: Array of Pointer;
  gBuffer: Array of Byte;
  gBuffLen: Integer;
  Sp_BackBuffer: Array of Byte;
  BBuffLen: Integer;
  GWScaleFactor: aFloat = 1;

Const

  DefaultPalette: Array[0..255] of TP_Colour =
  (
    // User interface colours - from the Speccy - Dark colours:

    (B: $00; G: $00; R: $00; A: $FF), // Black
    (B: $B0; G: $00; R: $00; A: $FF), // Blue
    (B: $00; G: $00; R: $B0; A: $FF), // Red
    (B: $B0; G: $00; R: $B0; A: $FF), // Magenta
    (B: $00; G: $B0; R: $00; A: $FF), // Green
    (B: $B0; G: $B0; R: $00; A: $FF), // Cyan
    (B: $00; G: $B0; R: $B0; A: $FF), // Yellow
    (B: $C0; G: $C0; R: $C0; A: $FF), // White

  // BRIGHT black makes no sense, so have a half-bright white:

    (B: $80; G: $80; R: $80; A: $FF),

  // BRIGHT colours:

    (B: $FF; G: $00; R: $00; A: $FF),
    (B: $00; G: $00; R: $FF; A: $FF),
    (B: $FF; G: $00; R: $FF; A: $FF),
    (B: $00; G: $FF; R: $00; A: $FF),
    (B: $FF; G: $FF; R: $00; A: $FF),
    (B: $00; G: $FF; R: $FF; A: $FF),
    (B: $FF; G: $FF; R: $FF; A: $FF),

    // Web-safe palette, with the Speccy colours removed where possible:

    (B: $33; G: $00; R: $00; A: $FF),
    (B: $66; G: $00; R: $00; A: $FF),
    (B: $99; G: $00; R: $00; A: $FF),
    (B: $CC; G: $00; R: $00; A: $FF),
    (B: $00; G: $33; R: $00; A: $FF),
    (B: $33; G: $33; R: $00; A: $FF),
    (B: $66; G: $33; R: $00; A: $FF),
    (B: $99; G: $33; R: $00; A: $FF),
    (B: $CC; G: $33; R: $00; A: $FF),
    (B: $FF; G: $33; R: $00; A: $FF),
    (B: $00; G: $66; R: $00; A: $FF),
    (B: $33; G: $66; R: $00; A: $FF),
    (B: $66; G: $66; R: $00; A: $FF),
    (B: $99; G: $66; R: $00; A: $FF),
    (B: $CC; G: $66; R: $00; A: $FF),
    (B: $FF; G: $66; R: $00; A: $FF),
    (B: $00; G: $99; R: $00; A: $FF),
    (B: $33; G: $99; R: $00; A: $FF),
    (B: $66; G: $99; R: $00; A: $FF),
    (B: $99; G: $99; R: $00; A: $FF),
    (B: $CC; G: $99; R: $00; A: $FF),
    (B: $FF; G: $99; R: $00; A: $FF),
    (B: $00; G: $CC; R: $00; A: $FF),
    (B: $33; G: $CC; R: $00; A: $FF),
    (B: $66; G: $CC; R: $00; A: $FF),
    (B: $99; G: $CC; R: $00; A: $FF),
    (B: $CC; G: $CC; R: $00; A: $FF),
    (B: $FF; G: $CC; R: $00; A: $FF),
    (B: $33; G: $FF; R: $00; A: $FF),
    (B: $66; G: $FF; R: $00; A: $FF),
    (B: $99; G: $FF; R: $00; A: $FF),
    (B: $CC; G: $FF; R: $00; A: $FF),
    (B: $00; G: $00; R: $33; A: $FF),
    (B: $33; G: $00; R: $33; A: $FF),
    (B: $66; G: $00; R: $33; A: $FF),
    (B: $99; G: $00; R: $33; A: $FF),
    (B: $CC; G: $00; R: $33; A: $FF),
    (B: $FF; G: $00; R: $33; A: $FF),
    (B: $00; G: $33; R: $33; A: $FF),
    (B: $33; G: $33; R: $33; A: $FF),
    (B: $66; G: $33; R: $33; A: $FF),
    (B: $99; G: $33; R: $33; A: $FF),
    (B: $CC; G: $33; R: $33; A: $FF),
    (B: $FF; G: $33; R: $33; A: $FF),
    (B: $00; G: $66; R: $33; A: $FF),
    (B: $33; G: $66; R: $33; A: $FF),
    (B: $66; G: $66; R: $33; A: $FF),
    (B: $99; G: $66; R: $33; A: $FF),
    (B: $CC; G: $66; R: $33; A: $FF),
    (B: $FF; G: $66; R: $33; A: $FF),
    (B: $00; G: $99; R: $33; A: $FF),
    (B: $33; G: $99; R: $33; A: $FF),
    (B: $66; G: $99; R: $33; A: $FF),
    (B: $99; G: $99; R: $33; A: $FF),
    (B: $CC; G: $99; R: $33; A: $FF),
    (B: $FF; G: $99; R: $33; A: $FF),
    (B: $00; G: $CC; R: $33; A: $FF),
    (B: $33; G: $CC; R: $33; A: $FF),
    (B: $66; G: $CC; R: $33; A: $FF),
    (B: $99; G: $CC; R: $33; A: $FF),
    (B: $CC; G: $CC; R: $33; A: $FF),
    (B: $FF; G: $CC; R: $33; A: $FF),
    (B: $00; G: $FF; R: $33; A: $FF),
    (B: $33; G: $FF; R: $33; A: $FF),
    (B: $66; G: $FF; R: $33; A: $FF),
    (B: $99; G: $FF; R: $33; A: $FF),
    (B: $CC; G: $FF; R: $33; A: $FF),
    (B: $FF; G: $FF; R: $33; A: $FF),
    (B: $00; G: $00; R: $66; A: $FF),
    (B: $33; G: $00; R: $66; A: $FF),
    (B: $66; G: $00; R: $66; A: $FF),
    (B: $99; G: $00; R: $66; A: $FF),
    (B: $CC; G: $00; R: $66; A: $FF),
    (B: $FF; G: $00; R: $66; A: $FF),
    (B: $00; G: $33; R: $66; A: $FF),
    (B: $33; G: $33; R: $66; A: $FF),
    (B: $66; G: $33; R: $66; A: $FF),
    (B: $99; G: $33; R: $66; A: $FF),
    (B: $CC; G: $33; R: $66; A: $FF),
    (B: $FF; G: $33; R: $66; A: $FF),
    (B: $00; G: $66; R: $66; A: $FF),
    (B: $33; G: $66; R: $66; A: $FF),
    (B: $66; G: $66; R: $66; A: $FF),
    (B: $99; G: $66; R: $66; A: $FF),
    (B: $CC; G: $66; R: $66; A: $FF),
    (B: $FF; G: $66; R: $66; A: $FF),
    (B: $00; G: $99; R: $66; A: $FF),
    (B: $33; G: $99; R: $66; A: $FF),
    (B: $66; G: $99; R: $66; A: $FF),
    (B: $99; G: $99; R: $66; A: $FF),
    (B: $CC; G: $99; R: $66; A: $FF),
    (B: $FF; G: $99; R: $66; A: $FF),
    (B: $00; G: $CC; R: $66; A: $FF),
    (B: $33; G: $CC; R: $66; A: $FF),
    (B: $66; G: $CC; R: $66; A: $FF),
    (B: $99; G: $CC; R: $66; A: $FF),
    (B: $CC; G: $CC; R: $66; A: $FF),
    (B: $FF; G: $CC; R: $66; A: $FF),
    (B: $00; G: $FF; R: $66; A: $FF),
    (B: $33; G: $FF; R: $66; A: $FF),
    (B: $66; G: $FF; R: $66; A: $FF),
    (B: $99; G: $FF; R: $66; A: $FF),
    (B: $CC; G: $FF; R: $66; A: $FF),
    (B: $FF; G: $FF; R: $66; A: $FF),
    (B: $00; G: $00; R: $99; A: $FF),
    (B: $33; G: $00; R: $99; A: $FF),
    (B: $66; G: $00; R: $99; A: $FF),
    (B: $99; G: $00; R: $99; A: $FF),
    (B: $CC; G: $00; R: $99; A: $FF),
    (B: $FF; G: $00; R: $99; A: $FF),
    (B: $00; G: $33; R: $99; A: $FF),
    (B: $33; G: $33; R: $99; A: $FF),
    (B: $66; G: $33; R: $99; A: $FF),
    (B: $99; G: $33; R: $99; A: $FF),
    (B: $CC; G: $33; R: $99; A: $FF),
    (B: $FF; G: $33; R: $99; A: $FF),
    (B: $00; G: $66; R: $99; A: $FF),
    (B: $33; G: $66; R: $99; A: $FF),
    (B: $66; G: $66; R: $99; A: $FF),
    (B: $99; G: $66; R: $99; A: $FF),
    (B: $CC; G: $66; R: $99; A: $FF),
    (B: $FF; G: $66; R: $99; A: $FF),
    (B: $00; G: $99; R: $99; A: $FF),
    (B: $33; G: $99; R: $99; A: $FF),
    (B: $66; G: $99; R: $99; A: $FF),
    (B: $99; G: $99; R: $99; A: $FF),
    (B: $CC; G: $99; R: $99; A: $FF),
    (B: $FF; G: $99; R: $99; A: $FF),
    (B: $00; G: $CC; R: $99; A: $FF),
    (B: $33; G: $CC; R: $99; A: $FF),
    (B: $66; G: $CC; R: $99; A: $FF),
    (B: $99; G: $CC; R: $99; A: $FF),
    (B: $CC; G: $CC; R: $99; A: $FF),
    (B: $FF; G: $CC; R: $99; A: $FF),
    (B: $00; G: $FF; R: $99; A: $FF),
    (B: $33; G: $FF; R: $99; A: $FF),
    (B: $66; G: $FF; R: $99; A: $FF),
    (B: $99; G: $FF; R: $99; A: $FF),
    (B: $CC; G: $FF; R: $99; A: $FF),
    (B: $FF; G: $FF; R: $99; A: $FF),
    (B: $00; G: $00; R: $CC; A: $FF),
    (B: $33; G: $00; R: $CC; A: $FF),
    (B: $66; G: $00; R: $CC; A: $FF),
    (B: $99; G: $00; R: $CC; A: $FF),
    (B: $CC; G: $00; R: $CC; A: $FF),
    (B: $FF; G: $00; R: $CC; A: $FF),
    (B: $00; G: $33; R: $CC; A: $FF),
    (B: $33; G: $33; R: $CC; A: $FF),
    (B: $66; G: $33; R: $CC; A: $FF),
    (B: $99; G: $33; R: $CC; A: $FF),
    (B: $CC; G: $33; R: $CC; A: $FF),
    (B: $FF; G: $33; R: $CC; A: $FF),
    (B: $00; G: $66; R: $CC; A: $FF),
    (B: $33; G: $66; R: $CC; A: $FF),
    (B: $66; G: $66; R: $CC; A: $FF),
    (B: $99; G: $66; R: $CC; A: $FF),
    (B: $CC; G: $66; R: $CC; A: $FF),
    (B: $FF; G: $66; R: $CC; A: $FF),
    (B: $00; G: $99; R: $CC; A: $FF),
    (B: $33; G: $99; R: $CC; A: $FF),
    (B: $66; G: $99; R: $CC; A: $FF),
    (B: $99; G: $99; R: $CC; A: $FF),
    (B: $CC; G: $99; R: $CC; A: $FF),
    (B: $FF; G: $99; R: $CC; A: $FF),
    (B: $00; G: $CC; R: $CC; A: $FF),
    (B: $33; G: $CC; R: $CC; A: $FF),
    (B: $66; G: $CC; R: $CC; A: $FF),
    (B: $99; G: $CC; R: $CC; A: $FF),
    (B: $CC; G: $CC; R: $CC; A: $FF),
    (B: $FF; G: $CC; R: $CC; A: $FF),
    (B: $00; G: $FF; R: $CC; A: $FF),
    (B: $33; G: $FF; R: $CC; A: $FF),
    (B: $66; G: $FF; R: $CC; A: $FF),
    (B: $99; G: $FF; R: $CC; A: $FF),
    (B: $CC; G: $FF; R: $CC; A: $FF),
    (B: $FF; G: $FF; R: $CC; A: $FF),
    (B: $33; G: $00; R: $FF; A: $FF),
    (B: $66; G: $00; R: $FF; A: $FF),
    (B: $99; G: $00; R: $FF; A: $FF),
    (B: $CC; G: $00; R: $FF; A: $FF),
    (B: $00; G: $33; R: $FF; A: $FF),
    (B: $33; G: $33; R: $FF; A: $FF),
    (B: $66; G: $33; R: $FF; A: $FF),
    (B: $99; G: $33; R: $FF; A: $FF),
    (B: $CC; G: $33; R: $FF; A: $FF),
    (B: $FF; G: $33; R: $FF; A: $FF),
    (B: $00; G: $66; R: $FF; A: $FF),
    (B: $33; G: $66; R: $FF; A: $FF),
    (B: $66; G: $66; R: $FF; A: $FF),
    (B: $99; G: $66; R: $FF; A: $FF),
    (B: $CC; G: $66; R: $FF; A: $FF),
    (B: $FF; G: $66; R: $FF; A: $FF),
    (B: $00; G: $99; R: $FF; A: $FF),
    (B: $33; G: $99; R: $FF; A: $FF),
    (B: $66; G: $99; R: $FF; A: $FF),
    (B: $99; G: $99; R: $FF; A: $FF),
    (B: $CC; G: $99; R: $FF; A: $FF),
    (B: $FF; G: $99; R: $FF; A: $FF),
    (B: $00; G: $CC; R: $FF; A: $FF),
    (B: $33; G: $CC; R: $FF; A: $FF),
    (B: $66; G: $CC; R: $FF; A: $FF),
    (B: $99; G: $CC; R: $FF; A: $FF),
    (B: $CC; G: $CC; R: $FF; A: $FF),
    (B: $FF; G: $CC; R: $FF; A: $FF),
    (B: $33; G: $FF; R: $FF; A: $FF),
    (B: $66; G: $FF; R: $FF; A: $FF),
    (B: $99; G: $FF; R: $FF; A: $FF),
    (B: $CC; G: $FF; R: $FF; A: $FF),

    (B: $00; G: $00; R: $00; A: $FF),
    (B: $08; G: $08; R: $08; A: $FF),
    (B: $10; G: $10; R: $10; A: $FF),
    (B: $18; G: $18; R: $18; A: $FF),
    (B: $20; G: $20; R: $20; A: $FF),
    (B: $28; G: $28; R: $28; A: $FF),
    (B: $30; G: $30; R: $30; A: $FF),
    (B: $38; G: $38; R: $38; A: $FF),
    (B: $40; G: $40; R: $40; A: $FF),
    (B: $48; G: $48; R: $48; A: $FF),
    (B: $50; G: $50; R: $50; A: $FF),
    (B: $58; G: $58; R: $58; A: $FF),
    (B: $60; G: $60; R: $60; A: $FF),
    (B: $68; G: $68; R: $68; A: $FF),
    (B: $70; G: $70; R: $70; A: $FF),
    (B: $78; G: $78; R: $78; A: $FF),
    (B: $80; G: $80; R: $80; A: $FF),
    (B: $88; G: $88; R: $88; A: $FF),
    (B: $90; G: $90; R: $90; A: $FF),
    (B: $98; G: $98; R: $98; A: $FF),
    (B: $A0; G: $A0; R: $A0; A: $FF),
    (B: $A8; G: $A8; R: $A8; A: $FF),
    (B: $B0; G: $B0; R: $B0; A: $FF),
    (B: $B8; G: $B8; R: $B8; A: $FF),
    (B: $C0; G: $C0; R: $C0; A: $FF),
    (B: $C8; G: $C8; R: $C8; A: $FF),
    (B: $D0; G: $D0; R: $D0; A: $FF),
    (B: $D8; G: $D8; R: $D8; A: $FF),
    (B: $E0; G: $E0; R: $E0; A: $FF),
    (B: $E8; G: $E8; R: $E8; A: $FF),
    (B: $F0; G: $F0; R: $F0; A: $FF),
    (B: $F8; G: $F8; R: $F8; A: $FF));

  EGAPalette: Array[0..63] of TP_Colour =
   ((B: $00; G: $00; R: $00; A: $FF),
    (B: $55; G: $00; R: $00; A: $FF),
    (B: $00; G: $00; R: $55; A: $FF),
    (B: $55; G: $00; R: $55; A: $FF),
    (B: $00; G: $55; R: $00; A: $FF),
    (B: $55; G: $55; R: $00; A: $FF),
    (B: $00; G: $55; R: $55; A: $FF),
    (B: $55; G: $55; R: $55; A: $FF),

    (B: $AA; G: $00; R: $00; A: $FF),
    (B: $FF; G: $00; R: $00; A: $FF),
    (B: $AA; G: $00; R: $55; A: $FF),
    (B: $FF; G: $00; R: $55; A: $FF),
    (B: $AA; G: $55; R: $00; A: $FF),
    (B: $FF; G: $55; R: $00; A: $FF),
    (B: $AA; G: $55; R: $55; A: $FF),
    (B: $FF; G: $55; R: $55; A: $FF),

    (B: $00; G: $00; R: $AA; A: $FF),
    (B: $55; G: $00; R: $AA; A: $FF),
    (B: $00; G: $00; R: $FF; A: $FF),
    (B: $55; G: $00; R: $FF; A: $FF),
    (B: $00; G: $55; R: $AA; A: $FF),
    (B: $55; G: $55; R: $AA; A: $FF),
    (B: $00; G: $55; R: $FF; A: $FF),
    (B: $55; G: $55; R: $FF; A: $FF),

    (B: $AA; G: $00; R: $AA; A: $FF),
    (B: $FF; G: $00; R: $AA; A: $FF),
    (B: $AA; G: $00; R: $FF; A: $FF),
    (B: $FF; G: $00; R: $FF; A: $FF),
    (B: $AA; G: $55; R: $AA; A: $FF),
    (B: $FF; G: $55; R: $AA; A: $FF),
    (B: $AA; G: $55; R: $FF; A: $FF),
    (B: $FF; G: $55; R: $FF; A: $FF),

    (B: $00; G: $AA; R: $00; A: $FF),
    (B: $55; G: $AA; R: $00; A: $FF),
    (B: $00; G: $AA; R: $55; A: $FF),
    (B: $55; G: $AA; R: $55; A: $FF),
    (B: $00; G: $FF; R: $00; A: $FF),
    (B: $55; G: $FF; R: $00; A: $FF),
    (B: $00; G: $FF; R: $55; A: $FF),
    (B: $55; G: $FF; R: $55; A: $FF),

    (B: $AA; G: $AA; R: $00; A: $FF),
    (B: $FF; G: $AA; R: $00; A: $FF),
    (B: $AA; G: $AA; R: $55; A: $FF),
    (B: $FF; G: $AA; R: $55; A: $FF),
    (B: $AA; G: $FF; R: $00; A: $FF),
    (B: $FF; G: $FF; R: $00; A: $FF),
    (B: $AA; G: $FF; R: $55; A: $FF),
    (B: $FF; G: $FF; R: $55; A: $FF),

    (B: $00; G: $AA; R: $AA; A: $FF),
    (B: $55; G: $AA; R: $AA; A: $FF),
    (B: $00; G: $AA; R: $FF; A: $FF),
    (B: $55; G: $AA; R: $FF; A: $FF),
    (B: $00; G: $FF; R: $AA; A: $FF),
    (B: $55; G: $FF; R: $AA; A: $FF),
    (B: $00; G: $FF; R: $FF; A: $FF),
    (B: $55; G: $FF; R: $FF; A: $FF),

    (B: $AA; G: $AA; R: $AA; A: $FF),
    (B: $FF; G: $AA; R: $AA; A: $FF),
    (B: $AA; G: $AA; R: $FF; A: $FF),
    (B: $FF; G: $AA; R: $FF; A: $FF),
    (B: $AA; G: $FF; R: $AA; A: $FF),
    (B: $FF; G: $FF; R: $AA; A: $FF),
    (B: $AA; G: $FF; R: $FF; A: $FF),
    (B: $FF; G: $FF; R: $FF; A: $FF));

  CGAPalette: Array[0..15] of TP_Colour =
   ((B: $00; G: $00; R: $00; A: $FF),
    (B: $AA; G: $00; R: $00; A: $FF),
    (B: $00; G: $AA; R: $00; A: $FF),
    (B: $AA; G: $AA; R: $00; A: $FF),
    (B: $00; G: $00; R: $AA; A: $FF),
    (B: $AA; G: $00; R: $AA; A: $FF),
    (B: $00; G: $55; R: $AA; A: $FF),
    (B: $AA; G: $AA; R: $AA; A: $FF),

    (B: $55; G: $55; R: $55; A: $FF),
    (B: $FF; G: $55; R: $55; A: $FF),
    (B: $55; G: $FF; R: $55; A: $FF),
    (B: $FF; G: $FF; R: $55; A: $FF),
    (B: $55; G: $55; R: $FF; A: $FF),
    (B: $FF; G: $55; R: $FF; A: $FF),
    (B: $55; G: $FF; R: $FF; A: $FF),
    (B: $FF; G: $FF; R: $FF; A: $FF));

  AppleLGRPalette: Array[0..15] of TP_Colour =
   ((B: $00; G: $00; R: $00; A: $FF),
    (B: $5F; G: $03; R: $99; A: $FF),
    (B: $E1; G: $04; R: $42; A: $FF),
    (B: $FE; G: $13; R: $CA; A: $FF),
    (B: $10; G: $73; R: $00; A: $FF),
    (B: $7F; G: $7F; R: $7F; A: $FF),
    (B: $FF; G: $97; R: $24; A: $FF),
    (B: $FF; G: $A2; R: $AA; A: $FF),

    (B: $01; G: $51; R: $4F; A: $FF),
    (B: $00; G: $5C; R: $F0; A: $FF),
    (B: $BE; G: $BE; R: $BE; A: $FF),
    (B: $E1; G: $85; R: $FF; A: $FF),
    (B: $07; G: $CA; R: $12; A: $FF),
    (B: $13; G: $D4; R: $CE; A: $FF),
    (B: $95; G: $F5; R: $51; A: $FF),
    (B: $FE; G: $FF; R: $FF; A: $FF));

  AppleHGRPalette: Array[0..7] of TP_Colour =
   ((B: $00; G: $00; R: $00; A: $FF),
    (B: $00; G: $C3; R: $43; A: $FF),
    (B: $FF; G: $3D; R: $B6; A: $FF),
    (B: $FF; G: $FF; R: $FF; A: $FF),
    (B: $00; G: $00; R: $00; A: $FF),
    (B: $15; G: $5D; R: $EA; A: $FF),
    (B: $E3; G: $A4; R: $10; A: $FF),
    (B: $FF; G: $FF; R: $FF; A: $FF));

  CPCPalette: Array[0..26] of TP_Colour =
   ((B: $80; G: $00; R: $00; A: $FF),
    (B: $80; G: $00; R: $00; A: $FF),
    (B: $FF; G: $00; R: $00; A: $FF),
    (B: $00; G: $00; R: $80; A: $FF),
    (B: $80; G: $00; R: $80; A: $FF),
    (B: $FF; G: $00; R: $80; A: $FF),
    (B: $00; G: $00; R: $FF; A: $FF),
    (B: $80; G: $00; R: $FF; A: $FF),

    (B: $FF; G: $00; R: $FF; A: $FF),
    (B: $00; G: $80; R: $00; A: $FF),
    (B: $80; G: $80; R: $00; A: $FF),
    (B: $FF; G: $80; R: $00; A: $FF),
    (B: $00; G: $80; R: $80; A: $FF),
    (B: $80; G: $80; R: $80; A: $FF),
    (B: $FF; G: $80; R: $80; A: $FF),
    (B: $00; G: $80; R: $FF; A: $FF),

    (B: $80; G: $80; R: $FF; A: $FF),
    (B: $FF; G: $80; R: $FF; A: $FF),
    (B: $00; G: $FF; R: $00; A: $FF),
    (B: $80; G: $FF; R: $00; A: $FF),
    (B: $FF; G: $FF; R: $00; A: $FF),
    (B: $00; G: $FF; R: $80; A: $FF),
    (B: $80; G: $FF; R: $80; A: $FF),
    (B: $FF; G: $FF; R: $80; A: $FF),

    (B: $00; G: $FF; R: $FF; A: $FF),
    (B: $80; G: $FF; R: $FF; A: $FF),
    (B: $FF; G: $FF; R: $FF; A: $FF));

implementation

Uses SP_Main, SP_Interpret_PostFix, SP_Tokenise, SP_InfixToPostFix, SP_Input, SP_Graphics32, SP_Components, SP_ToolTipWindow, SP_Variables;

Procedure SP_ForceScreenUpdate;
Var
  OldScreenLock: Boolean;
Begin
  OldScreenLock := SCREENLOCK;
  SCREENLOCK := False;
  SP_NeedDisplayUpdate := True;
  SP_WaitForSync;
  SCREENLOCK := OldScreenLock;
End;


Procedure SP_WaitForSync;
Begin
  If RefreshThreadAlive Then Begin
    If CauseUpdate Then Begin
      While CauseUpdate and RefreshThreadAlive Do
        CB_YIELD;
      Exit;
    End;
    SP_NeedDisplayUpdate := True;
    CauseUpdate := True;
    While CauseUpdate and RefreshThreadAlive Do
      CB_YIELD;
  End;
End;

Procedure SP_SetDirtyRect(x1, y1, x2, y2: Integer);
Begin

  // params are coords of TL/BR of a region on screen that has changed.
  // check if that region extends the current "dirty rect", and update it if necessary

  If SCMINX > x1 Then SCMINX := x1;
  If SCMAXX < x2 Then SCMAXX := x2;
  If SCMINY > y1 Then SCMINY := y1;
  If SCMAXY < y2 Then SCMAXY := y2;

End;

Procedure SP_InvalidateWholeDisplay;
Begin

  SCMINX := 0; SCMINY := 0; SCMAXX := DISPLAYWIDTH; SCMAXY := DISPLAYHEIGHT;
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_SetDirtyRectEx(x1, y1, x2, y2: Integer);
Var
  tx, ty: Integer;
Begin

  // As above, but adds bounds-checking and ordering, so slightly slower. Used for
  // lines.

  if (y1<0) or (y2<0) THen
    SP_InvalidateWholeDisplay;

  If x1 > x2 Then Begin tx := x1; x1 := x2; x2 := tx; End;
  If y1 > y2 Then Begin ty := y1; y1 := y2; y2 := ty; End;

  If SCMINX > x1 Then SCMINX := x1;
  If SCMAXX < x2 Then SCMAXX := x2;
  If SCMINY > y1 Then SCMINY := y1;
  If SCMAXY < y2 Then SCMAXY := y2;

End;

Procedure CopyMem(Dst, Src: Pointer; Len: LongInt); inline;
Begin

  Move(Src^, Dst^, Len);

End;

Function SP_GrabCurrentWindow: aString; inline;
Begin

  SetLength(Result, SCREENSTRIDE * SCREENHEIGHT);
  CopyMem(@Result[1], SCREENPOINTER, SCREENSTRIDE * SCREENHEIGHT);

End;

Procedure SP_PutCurrentWindow(Var Str: aString); inline;
Begin

  CopyMem(SCREENPOINTER, @Str[1], SCREENSTRIDE * SCREENHEIGHT);
  If SCREENVISIBLE Then SP_SetDirtyRect(0, 0, SCREENWIDTH, SCREENHEIGHT);

End;

Function  SP_Colour(R, G, B: Byte): LongWord;
Var
  Clr: TP_Colour;
Begin

  Clr.R := R;
  Clr.G := G;
  Clr.B := B;
  Result := Clr.L;

End;

Function SP_GetPalette(Idx: Integer): LongWord;
Begin

  With pSP_Window_Info(WINDOWPOINTER)^.Palette[Idx] Do
    Result := (R Shl 24) + (G Shl 16) + (B Shl 8);

End;

Procedure SP_SetWindowPalette(Idx, R, G, B: Integer);
Begin

  If WINDOWPOINTER <> nil Then
    With pSP_Window_Info(WINDOWPOINTER)^ Do Begin
      Palette[Idx].R := R;
      Palette[Idx].G := G;
      Palette[Idx].B := B;
    End;

  SP_InvalidateWholeDisplay;

End;

Procedure SP_CreateSystemUDGs(ID: Integer);
Var
  BlockIDX, Offset, Idx: Integer;
Const
  BlockChars = '12345678!"£$%^&*';
  BlockOffsets: Array[0..15] of Integer = ( 1,  2,  3,  4,  5, 6, 7, 0,
                                           14, 13, 12, 11, 10, 9, 8, 15);
Begin

  // Small characters in positions 0..31

  For Idx := 0 To 31 Do
    SP_SetSpeccyStyleChar(ID, Idx, @SmallChars[Idx * 8]);

  // Default font characters

  For Idx := 0 To 95 Do Begin
    SP_Font_Bank_SetChar(ID, Idx + 32, @DefaultFont[Idx * 64]);
    SP_Font_Bank_SetChar(ID, Idx + 32 + 128, @DefaultFont[Idx * 64], True);
  End;

  // UDGs - block graphic characters on 1-8, and shift 1-8

  BlockIdx := 0;
  Offset := 0;
  For Idx := 0 to 15 Do Begin
    SP_SetSpeccyStyleChar(ID, 128 + Ord(BlockChars[Idx +1]), @BlockGraphics[BlockOffsets[Idx] * 8]);
    SP_SetSpeccyStyleChar(ID, 128 + Idx, @BlockGraphics[BlockIdx + Offset]);
    Inc(Offset, 8);
  End;

  // UI UDGs - slope and arrows for scrollbars

  SP_SetSpeccyStyleChar(ID, Byte(aChar(#239)), @MenuUnderline[0]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#240)), @EditGlyph[0]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#241)), @RadioOff[0]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#242)), @RadioOn[0]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#243)), @Outline[0]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#244)), @OkBlock[0]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#245)), @ErrorBlock[0]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#246)), @TickMark[0]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#247)), @MenuSub[0]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#248)), @Lock[0]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#249)), @TitleBar[0]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#250)), @SizeGrip[0]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#251)), @Arrows[0]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#252)), @Arrows[8]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#253)), @Arrows[16]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#254)), @Arrows[24]);
  SP_SetSpeccyStyleChar(ID, Byte(aChar(#255)), @Slope[0]);

ENd;

Procedure SP_InitialGfxSetup(W, H: Integer; IsNEW: Boolean);
Var
  ID: Integer;
  Error: TSP_ErrorCode;
Begin

  {$IFDEF FPC}
  GfxUpdRect := 0;
  {$ENDIF}

  If Not IsNew Then DPtrBackup := DISPLAYPOINTER;

  // Default colours

  CINK := 0;
  CPAPER := 8;
  CINVERSE := 0;
  COVER := 0;
  CSCALEX := 1;
  CSCALEY := 1;
  CTRANSPARENT := False;

  CBLACK := SP_Colour(0, 0, 0);
  CBLUE := SP_Colour(0, 0, 202);
  CRED := SP_Colour(202, 0, 0);
  CMAGENTA := SP_Colour(202, 0, 202);
  CGREEN := SP_Colour(0, 202, 0);
  CCYAN := SP_Colour(0, 202, 202);
  CYELLOW := SP_Colour(202, 202, 0);
  CWHITE := SP_Colour(197, 197, 197);
  CGREY := SP_Colour(128, 128, 128);
  CBRIGHTBLUE := SP_Colour(0, 0, 255);
  CBRIGHTRED := SP_Colour(255, 0, 0);
  CBRIGHTMAGENTA := SP_Colour(255, 0, 255);
  CBRIGHTGREEN := SP_Colour(0, 255, 0);
  CBRIGHTCYAN := SP_Colour(0, 255, 255);
  CBRIGHTYELLOW := SP_Colour(255, 255, 0);
  CBRIGHTWHITE := SP_Colour(255, 255, 255);

  MENUBARPAPER :=     CBRIGHTWHITE;
  MENUBAROUTLINE :=   CBLACK;
  MENUBARINK :=       CBLACK;
  MENUPAPER :=        CBRIGHTWHITE;
  MENUINK :=          CBLACK;
  MENUOUTLINE :=      CBLACK;
  MENUHIGHLIGHT :=    CBRIGHTCYAN;
  MENUHLOUTLINE :=    CBRIGHTCYAN;
  MENUCAPHIGHLIGHT := CBLACK;
  MENUSEP :=          CGREY;
  MENUDISABLEDINK :=  CGREY;

  FONTHEIGHT := 8;

  SCREENBANK := SP_Add_Window(0, 0, W, H, $FFFF, 8, 0, Error);
  SP_ResizeWindow(SCREENBANK, W, H, 8, False, Error);
  SP_Bank_Protect(SCREENBANK, True);

  ID := SCREENBANK;
  SCREENBANK := -1;
  SP_SetDrawingWindow(ID);
  SP_CLS(CPAPER);

  ID := SP_Font_Bank_Create(SP_FONT_TYPE_MONO, 8, 8, 7);
  EDFONTWIDTH := 8;
  EDFONTHEIGHT := 8;
  SP_Bank_Protect(ID, True);
  SYSFONT := ID;
  EDITORFONT := ID;

  SP_CreateSystemUDGs(ID);
  SP_SetSystemFont(ID, Error);
  SP_SetDirtyRect(W, H, 0, 0);
  SP_MousePointerFromDefault;

End;

Procedure SP_SetCurrentWindowSettings;
Var
  WindowIdx: Integer;
  Window: psp_Window_Info;
  Gfx: pSP_Graphic_Info;
  Error: TSP_ErrorCode;
Begin


  If WINDOWPOINTER <> nil Then Begin

    If SCREENBANK >= 0 Then Begin

      WindowIdx := SP_FindBankID(SCREENBANK);

      If WindowIdx > -1 Then Begin

        Window := @SP_BankList[WindowIDX]^.Info[0];
        Window^.Ink := CINK;
        Window^.Paper := CPAPER;
        Window^.Inverse := CINVERSE;
        Window^.Italic := CITALIC;
        Window^.Bold := CBOLD;
        Window^.Over := COVER;
        Window^.pr_posx := PRPOSX;
        Window^.pr_posy := PRPOSY;
        Window^.dr_posx := DRPOSX;
        Window^.dr_posy := DRPOSY;
        Window^.GWScale := GWScaleFactor;
        Window^.heading := DRHEADING;
        Window^.scrollcnt := SCROLLCNT;
        Window^.orgx := SORGX;
        Window^.orgy := SORGY;
        Window^.orgw := SORGW;
        Window^.orgh := SORGH;
        Window^.clipx1 := CCLIPX1;
        Window^.clipy1 := CCLIPY1;
        Window^.clipx2 := CCLIPX2;
        Window^.clipy2 := CCLIPY2;
        Window^.scalex := CSCALEX;
        Window^.scaley := CSCALEY;

      End;

    End Else Begin

      Gfx := SP_GetGraphicDetails(-SCREENBANK, Error);

      If Error.Code = SP_ERR_OK Then Begin

        Window := @Gfx^.WindowInfo;
        Window^.Ink := CINK;
        Window^.Paper := CPAPER;
        Window^.Inverse := CINVERSE;
        Window^.Italic := CITALIC;
        Window^.Bold := CBOLD;
        Window^.Over := COVER;
        Window^.pr_posx := PRPOSX;
        Window^.pr_posy := PRPOSY;
        Window^.dr_posx := DRPOSX;
        Window^.dr_posy := DRPOSY;
        Window^.GWScale := GWScaleFactor;
        Window^.heading := DRHEADING;
        Window^.scrollcnt := SCROLLCNT;
        Window^.scalex := CSCALEX;
        Window^.scaley := CSCALEY;
        Gfx^.orgx := SORGX;
        Gfx^.orgy := SORGY;
        Gfx^.orgw := SORGW;
        Gfx^.orgh := SORGH;
        Gfx^.clipx1 := CCLIPX1;
        Gfx^.clipy1 := CCLIPY1;
        Gfx^.clipx2 := CCLIPX2;
        Gfx^.clipy2 := CCLIPY2;
        Gfx^.scalex := CSCALEX;
        Gfx^.scaley := CSCALEY;

      End;

    End;

  End;

End;

Procedure SP_SetDrawingWindow(WindowID: Integer);
Var
  Idx: Integer;
  Bank: pSP_Bank;
  Gfx: pSP_Graphic_Info;
  Window: pSP_Window_Info;
Begin

  If SCREENBANK = WindowID Then
    Exit;

  SP_SetCurrentWindowSettings;

  Idx := SP_FindBankID(Abs(WindowID));
  If Idx > -1 Then Begin

    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_WINDOW_BANK Then Begin

      Window := @Bank^.Info[0];
      SCREENBANK := WindowID;
      SCREENPOINTER := @Bank^.Memory[0];
      SCREENWIDTH := Window^.Width;
      SCREENHEIGHT := Window^.Height;
      SCREENSTRIDE := Window^.Stride;
      SCREENBPP := Window^.bpp;
      SCREENX := Window^.Left;
      SCREENY := Window^.Top;
      SCREENVISIBLE := Window^.Visible;
      CINK := Window^.Ink;
      CPAPER := Window^.Paper;
      CINVERSE := Window^.Inverse;
      CITALIC := Window^.Italic;
      CBOLD := Window^.Bold;
      COVER := Window^.Over;
      CTRANSPARENT := Window^.FontTrans;
      WINDOWPOINTER := Window;
      SCRBANKPOINTER := Bank;
      PRPOSX := Window^.pr_posx;
      PRPOSY := Window^.pr_posy;
      DRPOSX := Window^.dr_posx;
      DRPOSY := Window^.dr_posy;
      GWScaleFactor := Window^.GWScale;
      DRHEADING := Window^.heading;
      SCROLLCNT := Window^.scrollcnt;
      SORGX := Window^.orgx;
      SORGY := Window^.orgy;
      SORGW := Window^.orgw;
      SORGH := Window^.orgh;
      WINSCALE := Window^.winscale;
      WINORIGIN := Window^.winorigin;
      WINFLIPPED := Window^.Flip;
      WINSCALEX := Window^.winscalex;
      WINSCALEY := Window^.winscaley;
      CCLIPX1 := Window^.clipx1;
      CCLIPY1 := Window^.clipy1;
      CCLIPX2 := Window^.clipx2;
      CCLIPY2 := Window^.clipy2;
      CSCALEX := Window^.scalex;
      CSCALEY := Window^.scaley;
      If FONTWIDTH > 0 Then
        TABSIZE := (Window^.Width Div 2) Div Integer(FONTWIDTH);
      SP_Reset_Temp_Colours;

    End Else

      If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

        Gfx := @Bank.Info[0];
        Window := @Gfx^.WindowInfo;
        SCREENPOINTER := @Bank^.Memory[0];
        SCREENWIDTH := Window^.Width;
        SCREENHEIGHT := Window^.Height;
        SCREENSTRIDE := Window^.Stride;
        SCREENBPP := Window^.bpp;
        SCREENX := Window^.Left;
        SCREENY := Window^.Top;
        SCREENVISIBLE := False;
        CINK := Window^.Ink;
        CPAPER := Window^.Paper;
        CINVERSE := Window^.Inverse;
        COVER := Window^.Over;
        CITALIC := Window^.Italic;
        CBOLD := Window^.Bold;
        CTRANSPARENT := Window^.FontTrans;
        CSCALEX := Window^.scalex;
        CSCALEY := Window^.scaley;
        SCREENBANK := -Abs(WindowID);
        WINDOWPOINTER := Window;
        SCRBANKPOINTER := Bank;
        PRPOSX := Window^.pr_posx;
        PRPOSY := Window^.pr_posy;
        DRPOSX := Window^.dr_posx;
        DRPOSY := Window^.dr_posy;
        GWScaleFactor := Window^.GWScale;
        DRHEADING := Window^.heading;
        SCROLLCNT := Window^.scrollcnt;
        SORGX := Window^.orgx;
        SORGY := Window^.orgy;
        SORGW := Window^.orgw;
        SORGH := Window^.orgh;
        WINSCALE := Window^.winscale;
        WINORIGIN := Window^.winorigin;
        WINFLIPPED := Window^.Flip;
        WINSCALEX := Window^.winscalex;
        WINSCALEY := Window^.winscaley;
        CCLIPX1 := Gfx^.clipx1;
        CCLIPY1 := Gfx^.clipy1;
        CCLIPX2 := Gfx^.clipx2;
        CCLIPY2 := Gfx^.clipy2;
        If FONTWIDTH > 0 Then
          TABSIZE := (Window^.Width Div 2) Div Integer(FONTWIDTH);
        SP_Reset_Temp_Colours;

      End;

  End;

End;

Procedure SP_DeleteAllWindows;
Var
  Idx, Idx2, w, h, b: Integer;
  Bank: pSP_Bank;
  Error: TSP_ErrorCode;
Begin

  Idx := SP_FindBankID(0);
  If Idx > -1 Then Begin

    With pSP_Window_Info(@SP_BankList[Idx].Info[0])^ Do Begin
      w := Width;
      h := Height;
      b := 8;
    End;
    Idx2 := 1;
    While Idx2 < Length(SP_BankList) Do Begin
      Bank := SP_BankList[Idx2];
      If (Bank^.DataType = SP_SPRITE_BANK) or (Bank^.DataType = SP_WINDOW_BANK) Then Begin
        SP_BankList[Idx2]^.Protection := False;
        SP_BankList[Idx2]^.System := False;
        SP_DeleteBank(Idx2, Error);
      End Else
        Inc(Idx2);
    End;

    // Now set up the default window (bank 0). Set NUMWINDOWS to 0, so the default palette will be used.

    SetLength(WindowSpriteList, 0);
    NUMSPRITES := 0;
    WINDOWPOINTER := nil;
    SCREENBANK := -1;
    NUMWINDOWS := 0;
    SP_SetWindowDefaults(SP_BankList[0], pSP_Window_Info(@SP_BankList[0].Info[0]), 0, 0, w, h, -1, b, 0);
    NUMWINDOWS := 1;
    SCREENBANK := -1;
    SP_SetDrawingWindow(0);
    SetLength(SP_ZoneList, 0);

  End;

End;

Procedure SP_ChangeRes(Width, Height, sWidth, sHeight: Integer; FullScreen: Boolean; Var Error: TSP_ErrorCode);
Var
  OldMouse: Boolean;
Begin

  // Switch resolution. First, attempt the switch to the new resolution via a callback, which
  // returns true or false if the resolution is supported. Then set the resolution via a callback which
  // will set up the actual display image. Finally, set Window 0 to the correct size, and update all the pointers to
  // the other windows to reflect the change in size of window 0.

  DisplaySection.Enter;
  SCREENCHANGE := True;
  OldMouse := MOUSEVISIBLE;
  MOUSEVISIBLE := False;

  If CB_Test_Resolution(sWidth, sHeight, FullScreen) Then Begin

    SCALEWIDTH := sWidth;
    SCALEHEIGHT := sHeight;
    SP_ResizeWindow(0, Width, Height, -1, FullScreen, Error);
    SCREENBANK := -1;
    SP_SetDrawingWindow(0);

    SP_CLS(CPAPER);

  End Else

    Error.Code := SP_ERR_SCREENMODE_UNSUPPORTED;

  MOUSEVISIBLE := OldMouse;
  SCREENCHANGE := False;
  DisplaySection.Leave;

End;

Procedure SP_GetWindowDetails(WindowID: Integer; Var Window: pSP_Window_Info; Var Error: TSP_ErrorCode);// Inline;
Var
  BankIdx: Integer;
  Gfx: pSP_Graphic_Info;
Begin

  If WindowID = SCREENBANK Then Begin

    Window := WINDOWPOINTER;

  End Else Begin

    If WindowID >= 0 Then Begin

      BankIdx := SP_FindBankID(WindowID);
      If BankIdx > -1 Then Begin

        Window := @SP_BankList[BankIdx]^.Info[0];
        If SP_BankList[BankIdx].DataType <> SP_WINDOW_BANK Then
          Error.Code := SP_ERR_WINDOW_NOT_FOUND;

      End Else

        Error.Code := SP_ERR_WINDOW_NOT_FOUND;

    End Else Begin // GRAPHIC bank!

      BankIdx := SP_FindBankID(-WindowID);

      If BankIdx > -1 Then Begin

        If SP_BankList[BankIdx]^.DataType = SP_GRAPHIC_BANK Then Begin

          Gfx := @SP_BankList[BankIdx]^.Info[0];
          Window := @Gfx^.WindowInfo;

        End Else

          Error.Code := SP_ERR_BANK_NOT_FOUND;

      End Else

        Error.Code := SP_ERR_INVALID_BANK;

    End;

  End;

End;

Function SP_GetWindowLeft(WindowID: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Window: pSP_Window_Info;
Begin

  Result := 0;
  SP_GetWindowDetails(WindowID, Window, Error);
  If Error.Code = SP_ERR_OK Then
    Result := Window^.Left;

End;

Function SP_GetWindowTop(WindowID: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Window: pSP_Window_Info;
Begin

  Result := 0;
  SP_GetWindowDetails(WindowID, Window, Error);
  If Error.Code = SP_ERR_OK Then
    Result := Window^.Top;

End;

Function SP_GetWindowWidth(WindowID: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Window: pSP_Window_Info;
Begin

  Result := 0;
  SP_GetWindowDetails(WindowID, Window, Error);
  If Error.Code = SP_ERR_OK Then
    Result := Window^.Width;

End;

Function SP_GetWindowHeight(WindowID: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Window: pSP_Window_Info;
Begin

  Result := 0;
  SP_GetWindowDetails(WindowID, Window, Error);
  If Error.Code = SP_ERR_OK Then
    Result := Window^.Height;

End;

// This rather large and unwieldy procedure resizes a window and updates all the window pointers to
// match the new positions of the windows that are listed after it in the screen bank. This could probably be
// alleviated by making each window a separate bank, which I may leave for another time :)

Procedure SP_ResizeWindow(WindowID, W, H, Depth: Integer; FullScreen: Boolean; Var Error: TSP_ErrorCode);
Var
  BankIdx, Idx, Bits, NewBits: Integer;
  Bank: pSP_Bank;
  Window: pSP_Window_Info;
  oW, oH: Integer;
  OldMem: Array of Byte;
  dPtr: pLongWord;
  sPtr: pByte;
  OldMouse: Boolean;
Begin

  If ((W <= 0) or (H <= 0)) and (Depth <= 0) Then Begin
    Error.Code := SP_ERR_SCREENMODE_UNSUPPORTED;
    Exit;
  End;

  Error.Code := SP_ERR_OK;
  BankIdx := SP_FindBankID(WindowID);
  If BankIdx > -1 Then Begin

    Bank := SP_BankList[BankIdx];
    DisplaySection.Enter;

    Window := @Bank^.Info[0];
    oW := Window^.Width;
    oH := Window^.Height;

    If W = -1 Then W := oW;
    If H = -1 Then H := oH;

    Bits := Window^.bpp Div 8;
    If Depth <> -1 Then Begin
      If Not (Depth in [8, 32]) Then Begin
        Error.Code := SP_ERR_INVALID_DEPTH;
        DisplaySection.Leave;
        Exit;
      End Else
        NewBits := Depth Div 8;
    End Else
      NewBits := Bits;

    If (Depth = 32) And (Window^.Bpp = 8) Then Begin
      SetLength(OldMem, Window^.Width * Window^.Height);
      CopyMem(@OldMem[0], @Bank^.Memory[0], Window^.Width * Window^.Height);
    End;

    SetLength(Bank^.Memory, W * H * NewBits);

    Window^.Width := W;
    Window^.Height := H;
    Window^.Stride := W * NewBits;
    Window^.clipx1 := 0;
    Window^.clipy1 := 0;
    Window^.clipx2 := W;
    Window^.clipy2 := H;

    Bank^.Changed := True;

    // MUST reset the drawing window, as pointers may have changed.

    If SCREENBANK = WindowID Then Begin
      CCLIPX1 := 0;
      CCLIPY1 := 0;
      CCLIPX2 := W;
      CCLIPY2 := H;
    End;

    // If we changed depth from 8 up to 32, we can now re-render the display

    If Depth <> -1 Then Begin

      If (NewBits = 4) And (Bits = 1) Then Begin

        dPtr := @Bank^.Memory[0];
        sPtr := @OldMem[0];

        For Idx := 1 To Window^.Width * Window^.Height Do Begin
          dPtr^ := LongWord(Window^.Palette[sPtr^]);
          Inc(dPtr);
          Inc(sPtr);
        End;

      End;

      Window^.bpp := Depth;

    End;

    Window^.Surface := @Bank^.Memory[0];
    Idx := SCREENBANK;
    SCREENBANK := -1;
    SP_SetDrawingWindow(Idx);

    If WindowID = 0 Then Begin
      OldMouse := MOUSEVISIBLE;
      MOUSEVISIBLE := False;
      SIZINGMAIN := True;
      CB_SetScreenRes(Window^.Width, Window^.Height, SCALEWIDTH, SCALEHEIGHT, FullScreen);
      DisplaySection.Leave;
      Repeat
        CB_YIELD;
      Until Not SIZINGMAIN;
      SP_CLS(CPAPER);
      MOUSEVISIBLE := OldMouse;
    End Else Begin
      SP_CLS(CPAPER);
      DisplaySection.Leave;
    End;
  End;

End;

Procedure SP_MoveWindow(WindowID, X, Y: Integer; Var Error: TSP_ErrorCode);
Var
  BankIdx: Integer;
  Bank: pSP_Bank;
  Window: pSP_Window_Info;
Begin

  BankIdx := SP_FindBankID(WindowID);
  If BankIdx > -1 Then Begin

    Bank := SP_BankList[BankIdx];

    DisplaySection.Enter;
    Window := @Bank^.Info[0];
    Window^.Left := X;
    Window^.Top := Y;

    If Window^.ID = SCREENBANK Then Begin
      SCREENX := X;
      SCREENY := Y;
    End;

    If Window^.Visible Then SP_SetDirtyRect(0, 0, DISPLAYWIDTH, DISPLAYHEIGHT);
    DisplaySection.Leave;

  End Else
    Error.Code := SP_ERR_WINDOW_NOT_FOUND;

End;

Procedure SP_DeleteWindow(WindowID: Integer; Var Error: TSP_ErrorCode);
Var
  BankIdx, Idx, Ns: Integer;
  Bank: pSP_Bank;
  Window: pSP_Window_Info;
  SpritesToDelete: Array of Integer;
Begin

  Error.Code := SP_ERR_OK;
  DisplaySection.Enter;

  BankIdx := SP_FindBankID(WindowID);
  If BankIdx > -1 Then Begin

    Bank := SP_BankList[BankIdx];

    If Bank^.DataType = SP_WINDOW_BANK Then Begin

      SP_GetWindowDetails(WindowID, Window, Error);
      Window^.Component.Free;

      If WindowID = SCREENBANK Then Begin
        SCREENBANK := -1;
        SP_SetDrawingWindow(0);
      end;
      If TipWindowID = WindowID Then
        TipWindowID := -1;

      If WindowID = MODALWINDOW Then
        MODALWINDOW := -1;

      If Error.Code = SP_ERR_OK Then Begin

        SP_WindowDeleteZones(WindowID);

        Ns := Window^.SpriteCount;
        SetLength(SpritesToDelete, Ns);
        For Idx := 0 To Ns -1 Do
          SpritesToDelete[Idx] := WindowSpriteList[WindowID][Idx]^.ID;
        For Idx := 0 To Ns -1 Do
          SP_DeleteBank(SpritesToDelete[Idx], Error);
        SetLength(SpritesToDelete, 0);
        SetLength(WindowSpriteList[WindowID], 0);
        Window^.SpriteCount := 0;

        Dec(NUMWINDOWS);
        SP_DeleteBank(BankIdx, Error);

      End;

    End Else

      Error.Code := SP_ERR_WINDOW_NOT_FOUND;

  End;

  DisplaySection.Leave;

End;

Procedure SP_SetWindowOrigin(WindowID: Integer; X, Y, W, H: aFloat; Flip: Boolean; Var Error: TSP_ErrorCode);
Var
  Win: pSP_Window_Info;
  i: integer;
Begin

  SP_GetWindowDetails(WindowID, Win, Error);
  If Error.Code = SP_ERR_OK Then Begin

    If X > W Then
      Error.Code := SP_ERR_ORG_INVALID;

    If Y > H Then
      Error.Code := SP_ERR_ORG_INVALID;

    Win^.orgx := X;
    Win^.orgy := Y;
    Win^.orgw := W;
    Win^.orgh := H;
    Win^.Flip := Flip;

    Win^.winscale := (W - X <> Win^.Width) or (H - Y <> Win^.Height);
    Win^.winorigin := (X <> 0) or (Y <> 0);
    Win^.winscalex := (W - X)/Win^.Width;
    Win^.winscaley := (H - Y)/Win^.Height;
    Win^.clipx1 := 0;
    Win^.clipy1 := 0;
    Win^.clipx2 := Win^.Width;
    Win^.clipy2 := Win^.Height;

    If WindowID = SCREENBANK Then Begin
      SORGX := X;
      SORGY := Y;
      SORGW := W;
      SORGH := H;
      WINSCALE := Win^.winscale;
      WINORIGIN := Win^.winorigin;
      WINSCALEX := Win^.winscalex;
      WINSCALEY := Win^.winscaley;
      WINFLIPPED := Win^.Flip;
      T_CLIPX1 := Win^.clipx1;
      T_CLIPY1 := Win^.clipy1;
      T_CLIPX2 := Win^.clipx2;
      T_CLIPY2 := Win^.clipy2;
      CCLIPX1 := T_CLIPX1;
      CCLIPY1 := T_CLIPY1;
      CCLIPX2 := T_CLIPX2;
      CCLIPY2 := T_CLIPY2;
      i := SCREENBANK;
      SCREENBANK := -1;
      SP_SetDrawingWindow(i);
    End;

  End;

End;

Procedure SP_SetWindowOriginNoExt(WindowID: Integer; X, Y: aFloat; Flip: Boolean; Var Error: TSP_ErrorCode);
Var
  Win: pSP_Window_Info;
  W, H: aFloat;
  i: Integer;
Begin

  SP_GetWindowDetails(WindowID, Win, Error);
  If Error.Code = SP_ERR_OK Then Begin

    W := Win^.Width + X;
    H := Win^.Height + Y;

    Win^.orgx := X;
    Win^.orgy := Y;
    Win^.orgw := W;
    Win^.orgh := H;
    Win^.Flip := Flip;

    Win^.winscale := (W - X <> Win^.Width) or (H - Y <> Win^.Height);
    Win^.winorigin := (X <> 0) or (Y <> 0);
    Win^.winscalex := (W - X)/Win^.Width;
    Win^.winscaley := (H - Y)/Win^.Height;
    Win^.clipx1 := 0;
    Win^.clipy1 := 0;
    Win^.clipx2 := Win^.Width;
    Win^.clipy2 := Win^.Height;

    If WindowID = SCREENBANK Then Begin
      SORGX := X;
      SORGY := Y;
      SORGW := W;
      SORGH := H;
      WINSCALE := Win^.winscale;
      WINORIGIN := Win^.winorigin;
      WINSCALEX := Win^.winscalex;
      WINSCALEY := Win^.winscaley;
      WINFLIPPED := Win^.Flip;
      T_CLIPX1 := Win^.clipx1;
      T_CLIPY1 := Win^.clipy1;
      T_CLIPX2 := Win^.clipx2;
      T_CLIPY2 := Win^.clipy2;
      CCLIPX1 := T_CLIPX1;
      CCLIPY1 := T_CLIPY1;
      CCLIPX2 := T_CLIPX2;
      CCLIPY2 := T_CLIPY2;
      i := SCREENBANK;
      SCREENBANK := -1;
      SP_SetDrawingWindow(i);
    End;

  End;

End;

Procedure SP_SetWindowOriginOff(WinID: Integer; Var Error: TSP_ErrorCode);
Var
  Win: pSP_Window_Info;
  i: Integer;
Begin

  SP_GetWindowDetails(WinID, Win, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Win^.winscale := False;
    Win^.winorigin := False;
    Win^.clipx1 := 0;
    Win^.clipy1 := 0;
    Win^.clipx2 := Win^.Width;
    Win^.clipy2 := Win^.Height;
    Win^.Flip := False;
    If WinID = SCREENBANK Then Begin
      WINSCALE := False;
      WINORIGIN := False;
      WINFLIPPED := False;
      T_CLIPX1 := Win^.clipx1;
      T_CLIPY1 := Win^.clipy1;
      T_CLIPX2 := Win^.clipx2;
      T_CLIPY2 := Win^.clipy2;
      CCLIPX1 := T_CLIPX1;
      CCLIPY1 := T_CLIPY1;
      CCLIPX2 := T_CLIPX2;
      CCLIPY2 := T_CLIPY2;
      i := SCREENBANK;
      SCREENBANK := -1;
      SP_SetDrawingWindow(i);
    End;
  End;

End;

Function SP_WindowVisible(WindowID: Integer; var Error: TSP_ErrorCode): Boolean;
Var
  Win: pSP_Window_Info;
Begin

  Result := False;
  If WindowID >= 0 Then Begin
    Error.Code := SP_ERR_OK;
    SP_GetWindowDetails(WindowID, Win, Error);
    If Error.Code = SP_ERR_OK Then
      Result := Win^.Visible;
  End;

End;

Procedure SP_WindowSetVisible(WindowID: Integer; Visible: Boolean; var Error: TSP_ErrorCode);
Var
  Win: pSP_Window_Info;
Begin

  Error.Code := SP_ERR_OK;
  SP_GetWindowDetails(WindowID, Win, Error);
  If Error.Code = SP_ERR_OK Then Begin
    Win^.Visible := Visible;
    SP_InvalidateWholeDisplay;
  End;

End;


Procedure SP_SetPalette(Index: Integer; Colours: Array of TP_Colour);
Var
  Idx: Integer;
Begin

  For Idx := Index To Index + High(Colours) Do
    SP_SetWindowPalette(Idx, Colours[Idx - Index].R, Colours[Idx - Index].G, Colours[Idx - Index].B);

  SP_NeedDisplayUpdate := True;

End;

Procedure SP_FillRect(X, Y, W, H: Integer; Colour: LongWord);
Var
  Ptr, cPtr: pByte;
  N: Integer;
  NxtLin: pNativeUInt;
  Idx, W2, Clr: LongWord;
  {$IFDEF CPU64}ClrN: NativeUInt;{$ENDIF}
Begin

  // Fills a rectangle with the specified colour

  N := Max(X, T_CLIPX1); If X <> N Then Dec(W, (N-X)); X := N;
  N := Max(Y, T_CLIPY1); If Y <> N Then Dec(H, (N-Y)); Y := N;
  W := Min(X + W, T_CLIPX2) - X;
  H := Min(Y + H, T_CLIPY2) - Y;

  If (W <= 0) or (H <= 0) Then Exit;

  If pSP_Window_Info(WINDOWPOINTER)^.bpp = 8 Then Begin

    Colour := Colour And $FF;
    Clr := Colour + (Colour Shl 8) + (Colour Shl 16) + (Colour Shl 24);
    {$IFDEF CPU64}
    ClrN := (NativeUInt(Clr) Shl 32) Or Clr;
    {$ENDIF}

    Ptr := psp_Window_Info(WINDOWPOINTER).Surface;
    Inc(pByte(Ptr), X + (Y * SCREENSTRIDE));
    If T_OVER = 0 Then Begin
      for Idx := 0 To H -1 Do Begin
        NxtLin := pNativeUInt(Ptr);
        W2 := W;
        {$IFDEF CPU64}
        While W2 > SizeOf(NativeUint) Do Begin
          pNativeUInt(Ptr)^ := ClrN;
          Inc(pNativeUInt(Ptr));
          Dec(W2, SizeOf(NativeUInt));
        End;
        {$ENDIF}
        While W2 > SizeOf(LongWord) do Begin
          pLongWord(Ptr)^ := Clr;
          Inc(pLongWord(Ptr));
          Dec(W2, SizeOf(LongWord));
        End;
        While W2 > 0 do Begin
          pByte(Ptr)^ := Colour;
          Inc(pByte(Ptr));
          Dec(W2);
        End;
        Ptr := pByte(NativeUInt(NxtLin) + longword(SCREENSTRIDE));
      End;
    End Else Begin
      cPtr := @Colour;
      for Idx := 0 To H -1 Do Begin
        NxtLin := pNativeUInt(Ptr);
        W2 := W;
        While W2 > 0 do Begin
          SP_OverPixelPtr(Ptr, cPtr, T_OVER);
          Inc(Ptr);
          Dec(W2);
        End;
        Ptr := pByte(NativeUInt(NxtLin) + longword(SCREENSTRIDE));
      End;
    End;

  End Else

    SP_FillRect32(X, Y, W, H, Colour);

  SP_BankList[0]^.Changed := True;
  SP_NeedDisplayUpdate := True;

  If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X, SCREENY + Y, SCREENX + X+W, SCREENY + Y+H);

End;

Procedure SP_CLS(Paper: LongWord);
Var
  bOver: Integer;
Begin

  PRPOSX := 0;
  PRPOSY := 0;
  DRPOSX := 0;
  DRPOSY := 0;
  SKIPFIRSTPOINT := True;
  SCROLLCNT := 0;
  bOver := T_OVER;
  T_OVER := 0;
  SP_FillRect(0, 0, SCREENWIDTH, SCREENHEIGHT, Paper);
  T_OVER := bOver;
  SP_NeedDisplayUpdate := True;
  SP_ConvertToOrigin_d(PRPOSX, PRPOSY);
  SP_ConvertToOrigin_d(DRPOSX, DRPOSY);

End;

Function SP_Get_Contrasting_INK(Index: Integer): Integer;
Var
  PL: LongWord;
  V: aFloat;
Begin

  PL := SP_GetPalette(Index);
  V := (0.3 * ((PL Shr 24) And $FF)) + (0.59 * ((PL Shr 16) And $FF)) + (0.11 * ((PL Shr 8) And $FF));
  If V < 128 Then
    Result := SP_Get_Nearest_Colour($FF, $FF, $FF, -1)
  Else
    Result := SP_Get_Nearest_Colour($0, $0, $0, -1);

End;

Procedure SP_RGB_To_CIELAB(R, G, B: aFloat; Var cL, cA, cB: aFloat);
Var
  X, Y, Z: aFloat;
  R1, G1, B1: aFloat;
Begin

    R1 := (Min(R, 255) / 255);
    G1 := (Min(G, 255) / 255);
    B1 := (Min(B, 255) / 255);

    If R1 > 0.04045 Then R1 := Power(((R1 + 0.055) / 1.055), 2.4) Else R1 := R1 / 12.92;
    If G1 > 0.04045 Then G1 := Power(((G1 + 0.055) / 1.055), 2.4) Else G1 := G1 / 12.92;
    If B1 > 0.04045 Then B1 := Power(((B1 + 0.055) / 1.055), 2.4) Else B1 := B1 / 12.92;

    X := R1 * 0.4124 + G1 * 0.3576 + B1 * 0.1805;
    y := R1 * 0.2126 + G1 * 0.7152 + B1 * 0.0722;
    Z := R1 * 0.0193 + G1 * 0.1192 + B1 * 0.9505;

    X := X / 0.95047;
    Z := Z / 1.08883;

    If X > 0.008856 Then X := Power(X, (1/3)) Else X := (7.787 * X) + (16/116);
    If y > 0.008856 Then y := Power(y, (1/3)) Else y := (7.787 * y) + (16/116);
    If Z > 0.008856 Then Z := Power(Z, (1/3)) Else Z := (7.787 * Z) + (16/116);

    cL := 116 * Y - 16;
    cA := 500 * (X - Y);
    cB := 200 * (Y - Z);

End;

Function SP_Get_Nearest_Colour_Fast(R, G, B: Byte):Integer;
Var
  r1,r2,g1,g2,b1,b2: aFloat;
  pl, Idx: LongWord;
  MaxDist, Dist: aFloat;
Begin

  r1 := R;
  g1 := G;
  b1 := B;

  MaxDist := 9999999;
  Result := 0;

  For Idx := 0 To 255 Do Begin
    Pl := SP_GetPalette(Idx);
    r2 := (Pl Shr 24) And $FF;
    g2 := (Pl Shr 16) And $FF;
    b2 := (Pl Shr 8) And $FF;
    Dist := ((r1-r2)*(r1-r2))+((g1-g2)*(g1-g2))+((b1-b2)*(b1-b2));
    If Dist < MaxDist Then Begin
      MaxDist := Dist;
      Result := Idx;
    End;
  End;

End;

Function SP_Get_Nearest_Colour(R, G, B: Byte; Exclude: Integer):Integer;
Var
  r1,r2,g1,g2,b1,b2: aFloat;
  pl, Index, Idx: LongWord;
  MaxDist, Dist: aFloat;
Begin

  SP_RGB_To_CIELAB(R, G, B, r1, g1, b1);

  MaxDist := 9999999;
  Index := 0;

  For Idx := 0 To 255 Do
    If Idx <> longWord(Exclude) Then Begin
      Pl := SP_GetPalette(Idx);
      R := (Pl Shr 24) And $FF;
      G := (Pl Shr 16) And $FF;
      B := (Pl Shr 8) And $FF;
      SP_RGB_To_CIELAB(R,G,B,r2,g2,b2);
      Dist := Abs(Sqrt(((r1-r2)*(r1-r2))+((g1-g2)*(g1-g2))+((b1-b2)*(b1-b2))));
      If Dist < MaxDist Then Begin
        MaxDist := Dist;
        Index := Idx;
      End;
    End;

  Result := Index;

End;

Function SP_Get_Opposite_Colour(R, G, B: Byte): Integer;
Var
  r1,r2,g1,g2,b1,b2: Byte;
  pl, Index, Idx: LongWord;
  MaxDist, Dist: aFloat;
Begin

  r1 := R;
  g1 := G;
  b1 := B;

  MaxDist := 0;
  Index := 0;

  For Idx := 0 To 255 Do Begin
    Pl := SP_GetPalette(Idx);
    r2 := (Pl Shr 24) And $FF;
    g2 := (Pl Shr 16) And $FF;
    b2 := (Pl Shr 8) And $FF;
    Dist := Sqrt(((r1-r2)*(r1-r2))+((g1-g2)*(g1-g2))+((b1-b2)*(b1-b2)));
    If Dist > MaxDist Then Begin
      MaxDist := Dist;
      Index := Idx;
    End;
  End;

  Result := Index;

End;

Procedure SP_RGBToHSV(Const R,G,B: aFloat; Var H,S,V: aFloat);
Var
  Delta, Minimum: aFloat;
Begin

  Minimum := Min(Min(R, G), B);
  V := Max(Max(R, G), B);

  Delta := V - Minimum;

  If V =  0.0 Then
     S := 0
  Else
     S := Delta / V;

  If S  = 0.0 Then
     H := 0
  Else Begin
     IF R = V Then
        H := 60.0 * (G - B) / Delta
     Else
        If G = V Then
           H := 120.0 + 60.0 * (B - R) / Delta
        Else
           If  B = V Then
              H := 240.0 + 60.0 * (R - G) / Delta;
      If H < 0.0 Then
        H := H + 360.0;
  End;

  S := S * 255;

End;

Procedure SP_HSVtoRGB(H,S,V: aFloat; Var R,G,B: aFloat);
Var
  f, hTemp, p, q, t: aFloat;
  i: Integer;
Begin
  S := S / 255;
  If S = 0.0 Then Begin
     R := V;
     G := V;
     B := V
  End Else Begin
     IF H = 360.0 Then
        hTemp := 0.0
     Else
        hTemp := H;

     hTemp := hTemp / 60;
     i := TRUNC(hTemp);
     f := hTemp - i;
     p := V * (1.0 - S);
     q := V * (1.0 - (S * f));
     t := V * (1.0 - (S * (1.0 - f)));
     Case i of
        0: Begin R := V; G := t; B := p; End;
        1: Begin R := q; G := V; B := p; End;
        2: Begin R := p; G := V; B := t; End;
        3: Begin R := p; G := q; B := V; End;
        4: Begin R := t; G := p; B := V; End;
        5: Begin R := V; G := p; B := q; End;
     End;
  End;
End;

Procedure SP_CLS_Lower(Paper: LongWord);
Var
  LowerLines: Integer;
  Coord: pByte;
Begin

  // Clears the lower screen prior to an error or an INPUT sequence.

  LowerLines := (SCREENHEIGHT - (Max(MAXLOWER, 2) * Integer(FONTHEIGHT)) -4);
  SetLength(LOWERSAVE, LowerLines * SCREENSTRIDE);

  Coord := SCREENPOINTER;
  Inc(Coord, LongWord(SCREENHEIGHT - LowerLines) * LongWord(SCREENSTRIDE));

  CopyMem(@LOWERSAVE[1], Coord, LowerLines * SCREENSTRIDE);

  SP_FillRect(0, SCREENHEIGHT - (Max(MAXLOWER, 2) * Integer(FONTHEIGHT)) -4, SCREENWIDTH, SCREENHEIGHT, Paper);
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_Restore_Lower;
Var
  LowerLines: Integer;
  Coord: pByte;
Begin

  LowerLines := (SCREENHEIGHT - (Max(MAXLOWER, 2) * Integer(FONTHEIGHT)) -4);
  Coord := SCREENPOINTER;
  Inc(Coord, LongWord(SCREENHEIGHT - LowerLines) * LongWord(SCREENSTRIDE));
  CopyMem(Coord, @LOWERSAVE[1], LowerLines * SCREENSTRIDE);

  SP_NeedDisplayUpdate := True;

  If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX, LowerLines, SCREENWIDTH, SCREENHEIGHT);

End;

Procedure SP_Scroll(Dy: Integer);
Var
  Dst: pLongWord;
  Src: pLongWord;
  Amt, nDy: Integer;
  Paper: Longword;
Begin

  If SCREENBPP = 8 Then Begin

    nDy := Min(Dy, SCREENHEIGHT);

    While Dy > 0 Do Begin

      Dst := SCREENPOINTER;
      Src := pLongWord(NativeUInt(SCREENPOINTER) + (LongWord(nDy) * LongWord(SCREENSTRIDE)));
      Amt := (SCREENSTRIDE * (SCREENHEIGHT - nDy)) Div SizeOf(LongWord);

      While Amt > 0 Do Begin
        Dst^ := Src^;
        Inc(Dst);
        Inc(Src);
        Dec(Amt);
      End;

      Paper := (CPAPER Shl 24) + (CPAPER Shl 16) + (CPAPER Shl 8) + CPAPER;
      Amt := (nDy * SCREENSTRIDE) Div SizeOf(LongWord);
      While Amt > 0 Do Begin
        Dst^ := Paper;
        Dec(Amt);
        Inc(Dst);
      End;

      Dec(dY, SCREENHEIGHT);
      nDy := Min(Dy, SCREENHEIGHT);

    End;

  End Else

    SP_Scroll32(Dy);

  SP_BankList[0]^.Changed := True;
  SP_NeedDisplayUpdate := True;

  If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX, SCREENY, SCREENWIDTH, SCREENHEIGHT);

End;

Procedure SP_Reset_Temp_Colours; inline;
Begin

  T_INK := CINK;
  T_PAPER := CPAPER;
  T_INVERSE := CINVERSE;
  T_OVER := COVER;
  T_CLIPX1 := CCLIPX1;
  T_CLIPX2 := CCLIPX2;
  T_CLIPY1 := CCLIPY1;
  T_CLIPY2 := CCLIPY2;
  T_SCALEX := CSCALEX;
  T_SCALEY := CSCALEY;
  T_ITALIC := CITALIC;
  T_BOLD := CBOLD;
  T_TRANSPARENT := CTRANSPARENT;

End;

Function SP_TextOut(BankID, X, Y: Integer; const Text: aString; Ink, Paper: Integer; Visible: Boolean; ShowSpecial: Boolean = False): Integer;
Var
  CharW, CharH, Idx, cCount, OVER, ItalicOffset, DefPaper, nx: Integer;
  sx, sy, Cw, Ch, yp, xp, TC, t: Integer;
  Transparent, ForceNextChar: Boolean;
  FontBank: pSP_Font_Info;
  Bank: pSP_Bank;
  Coord, Char, pIdx, lIdx: pByte;
  IsScaled, SkipNextPaper: Boolean;
  ScaleX, ScaleY: aFloat;
Begin

  ForceNextChar := False;
  If T_INVERSE <> 0 Then Begin
    Idx := Ink;
    Ink := Paper;
    Paper := Idx;
  End;
  OVER := T_OVER;
  ScaleX := T_SCALEX;
  ScaleY := T_SCALEY;

  DefPaper := Paper;

  If BankID = -1 Then // Use the system font?
    BankID := FONTBANKID;

  Result := SP_FindBankID(BankID);
  If Result <> SP_ERR_BANK_ID_NOT_FOUND Then Begin

    Bank := SP_BankList[Result];
    FontBank := @Bank^.Info[0];
    IsScaled := (ScaleX <> 1) Or (ScaleY <> 1);
    CharW := Max(1, Round(FONTWIDTH * ScaleX));
    CharH := Max(1, Round(FONTHEIGHT * ScaleY));
    Cw := CharW;
    Ch := CharH;
    If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
      Transparent := T_TRANSPARENT And (FontBank^.Transparent <> $FFFF);
      TC := FontBank^.Transparent And $FF;
    End Else Begin
      Transparent := T_TRANSPARENT or (Paper = -1);
      TC := 0;
    End;

    Coord := SCREENPOINTER;
    Inc(Coord, (SCREENSTRIDE * Y) + X);

    Idx := 1;
    While Idx <= Length(Text) Do Begin

      If (Text[Idx] >= ' ') or ForceNextChar Then Begin

        ForceNextChar := False;
        Char := @Bank^.Memory[FontBank^.Font_Info[Byte(Text[Idx])].Data];
        If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X, SCREENY + Y, SCREENX + X + CharW, SCREENY + Y + CharH);
        If T_ITALIC > 0 Then
          ItalicOffset := (65536 Div ItalicScale) + (CharH Div ItalicScale) Shl 16
        Else
          ItalicOffset := 0;
        Coord := SCREENPOINTER;
        Inc(Coord, (SCREENSTRIDE * Y) + X);
        Inc(Coord, ItalicOffset Shr 16);
        if T_ITALIC > 0 Then Dec(Coord, ItalicScale Div 2);

        If IsScaled Then Begin
          // Scaled character
          sx := Integer(FONTWIDTH Shl 16) Div CharW;
          sy := Integer(FONTHEIGHT Shl 16) Div CharH;
          yp := 0;
          While CharH > 0 Do Begin
            pIdx := Char;
            xp := 0;
            SkipNextPaper := False;
            Inc(pIdx, Integer(FONTWIDTH) * (yp Shr 16));
            While CharW > 0 Do Begin
              If (X >= T_CLIPX1) And (Y >= T_CLIPY1) And (X < T_CLIPX2) And (Y < T_CLIPY2) Then
                If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                  If Transparent Then Begin
                    lIdx := pByte(NativeUInt(pIdx) + (xp Shr 16));
                    If lIdx^ <> TC Then
                      If Over > 0 Then Begin
                        SP_OverPixelPtr(Coord, lIdx, T_OVER)
                      End Else
                        Coord^ := lIdx^;
                  End Else
                    If Over > 0 Then Begin
                      lIdx := pByte(NativeUInt(pIdx) + (xp Shr 16));
                      SP_OverPixelPtr(Coord, lIdx, T_OVER)
                    End Else
                      Coord^ := pByte(NativeUInt(pIdx) + (xp Shr 16))^;
                End Else
                  If Over > 0 Then Begin
                    If pByte(NativeUInt(pIdx) + (xp Shr 16))^ = 1 Then Begin
                      SP_OverPixelPtrVal(Coord, Ink, T_OVER);
                      If (T_BOLD > 0) And (X+1 < T_CLIPX2) Then Begin
                        SP_OverPixelPtrVal(pByte(NativeUInt(Coord)+1), Ink, T_OVER);
                        SkipNextPaper := True;
                      End;
                    End Else
                      If Not Transparent And Not SkipNextPaper Then
                        SP_OverPixelPtrVal(Coord, Paper, T_OVER)
                      Else
                        SkipNextPaper := False;
                  End Else
                    If pByte(NativeUInt(pIdx) + (xp Shr 16))^ = 1 Then  Begin
                      Coord^ := Ink;
                      If (T_BOLD > 0) And (X+1 < T_CLIPX2) Then Begin
                        pByte(NativeUInt(Coord)+1)^ := Ink;
                        SkipNextPaper := True;
                      End;
                    End Else
                      If Not Transparent And Not SkipNextPaper Then
                        Coord^ := Paper
                      Else
                        SkipNextPaper := False;
              Inc(Coord);
              Inc(xp, sx);
              Inc(X);
              Dec(CharW);
            End;
            Inc(Y);
            CharW := Cw;
            Dec(X, CharW);
            Inc(Coord, SCREENSTRIDE - (cW + (ItalicOffset Shr 16)));
            If T_ITALIC > 0 Then Dec(ItalicOffset, 65536 Div ItalicScale);
            If ItalicOffset < 0 Then ItalicOffset := 0;
            Inc(Coord, ItalicOffset Shr 16);
            Dec(CharH);
            Inc(yp, sy);
          End;
          CharH := Ch;
          Dec(Y, Ch);
          Dec(Coord, SCREENSTRIDE * CharH);
          Inc(Coord, CharW);
          Inc(X, CharW);
        End Else Begin
          While CharH > 0 Do Begin
            SkipNextPaper := False;
            While CharW > 0 Do Begin
                If (X >= T_CLIPX1) And (Y >= T_CLIPY1) And (X < T_CLIPX2) And (Y < T_CLIPY2) Then
                  If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                    If Transparent Then Begin
                      If Char^ <> TC Then
                        If Over > 0 Then
                          SP_OverPixelPtr(Coord, Char, T_OVER)
                        Else
                          Coord^ := Char^;
                    End Else
                      If Over > 0 Then
                        SP_OverPixelPtr(Coord, Char, T_OVER)
                      Else
                        Coord^ := Char^;
                  End Else
                    If Over > 0 Then Begin
                      If Char^ = 1 Then Begin
                        SP_OverPixelPtrVal(Coord, Ink, T_OVER);
                        If (T_BOLD > 0) And (X+1 < T_CLIPX2) Then Begin
                          SP_OverPixelPtrVal(pByte(NativeUInt(Coord)+1), Ink, T_OVER);
                          SkipNextPaper := True;
                        End;
                      End Else
                        If Not Transparent And Not SkipNextPaper Then
                          SP_OverPixelPtrVal(Coord, Paper, T_OVER)
                        Else
                          SkipNextPaper := False;
                    End Else
                      If Char^ = 1 Then Begin
                        Coord^ := Ink;
                        If (T_BOLD > 0) And (X+1 < T_CLIPX2) Then Begin
                          pByte(NativeUInt(Coord)+1)^ := Ink;
                          SkipNextPaper := True;
                        End;
                      End Else
                        If Not Transparent And Not SkipNextPaper Then
                          Coord^ := Paper
                        Else
                          SkipNextPaper := False;
              Inc(Coord);
              Inc(Char);
              Inc(X);
              Dec(CharW);
            End;
            Inc(Y);
            CharW := Cw;
            Dec(X, CharW);
            Inc(Coord, SCREENSTRIDE - (cW + (ItalicOffset Shr 16)));
            If T_ITALIC > 0 Then Dec(ItalicOffset, 65536 Div ItalicScale);
            If ItalicOffset < 0 Then ItalicOffset := 0;
            Inc(Coord, ItalicOffset Shr 16);
            Dec(CharH);
          End;
          CharH := Ch;
          Dec(Y, CharH);
          Dec(Coord, SCREENSTRIDE * CharH);
          Inc(Coord, CharW);
          Inc(X, CharW);
        End;

      End Else Begin

        // Control codes!
        Case Ord(Text[Idx]) of
          5:
            Begin // Literal character - for characters lower than Space. The next char should be PRINTed regardless.
              If ShowSpecial Then ForceNextChar := True;
            End;
          6:
            Begin // PRINT comma
              nx := X + (TABSIZE * Cw);
              nx := Round(nx / (TABSIZE * Cw)) * (TABSIZE * Cw);
              SP_TextOut(-1, X, Y, StringOfChar(aChar(' '), ((nx - x) Div Cw) +1), Ink, Paper, True);
              X := nx;
            End;
          8:
            Begin // Cursor Left
              X := (X - Cw) Mod SCREENWIDTH;
            End;
          9:
            Begin // Cursor right
              SP_TextOut(-1, X, Y, aString(' '), Ink, Paper, True);
              X := (X + Cw) Mod SCREENWIDTH;
            End;
         10:
            Begin // Cursor down
              Inc(Y, Ch);
            End;
         11:
            Begin // Cursor Up
              Dec(Y, Ch);
              If Y < 0 Then Y := 0;
            End;
         13:
            Begin // Carriage return
              X := 0; Inc(Y, Ch);
            End;
         16:
            Begin // INK control
              T_INK := pLongWord(@Text[Idx+1])^ And $FF;
              Ink := T_INK;
              Inc(Idx, SizeOf(LongWord));
            End;
         17:
            Begin // PAPER control
              T_PAPER := pLongWord(@Text[Idx+1])^ And $FF;
              Paper := T_PAPER;
              Inc(Idx, SizeOf(LongWord));
            End;
         18:
            Begin // OVER control
              T_OVER := pLongWord(@Text[Idx+1])^;
              OVER := T_OVER;
              Inc(Idx, SizeOf(LongWord));
            End;
         19:
            Begin // TRANSPARENT 0/1
              t := pLongWord(@Text[Idx+1])^;
              If t <> 8 Then Begin
                T_TRANSPARENT := t > 0;
                If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                  Transparent := T_TRANSPARENT And (FontBank^.Transparent <> $FFFF);
                  TC := FontBank^.Transparent And $FF;
                End Else
                  Transparent := T_TRANSPARENT;
              End;
              Inc(Idx, SizeOf(LongWord));
            End;
         20:
            Begin // INVERSE control
              t := pLongWord(@Text[Idx+1])^;
              If t <> 8 Then
                If t <> 0 Then Begin
                  Ink := T_PAPER;
                  Paper := T_INK;
                  T_INVERSE := 1;
                End Else Begin
                  Ink := T_INK;
                  Paper := T_PAPER;
                  T_INVERSE := 0;
                End;
              Inc(Idx, SizeOf(LongWord));
            End;
         21:
            Begin // MOVE control
              X := pInteger(@Text[Idx+1])^;
              Inc(Idx, SizeOf(Integer));
              Y := pInteger(@Text[Idx+1])^;
              If WINFLIPPED Then Y := (SCREENHEIGHT - 1) - Y;
              Inc(Idx, SizeOf(Integer));
              SP_ConvertToOrigin_i(X, Y);
            End;
         22:
            Begin // AT control
              X := 0; Y := 0;
              SP_ConvertToOrigin_i(X, Y);
              Inc(Y, pInteger(@Text[Idx+1])^ * Ch);
              Inc(Idx, SizeOf(Integer));
              Inc(X, pInteger(@Text[Idx+1])^ * Cw);
              Inc(Idx, SizeOf(Integer));
            End;
         23:
            Begin // TAB control
              nx := X Div Cw;
              tc := pLongWord(@Text[Idx+1])^;
              If tc < nx Then Inc(tc, SCREENWIDTH Div Cw);
              SP_TextOut(-1, X, Y, StringOfChar(aChar(' '), tc - nx), Ink, Paper, True);
              X := Round(PRPOSX);
              Y := ROUND(PRPOSY);
              Inc(Idx, SizeOf(LongWord));
            End;
         24:
            Begin // CENTRE control
              Y := 0;
              SP_ConvertToOrigin_i_y(Y);
              Inc(Y, pInteger(@Text[Idx+1])^ * Ch);
              Inc(Idx, SizeOf(Integer) +1);
              pIdx := pByte(@Text[Idx]);
              lIdx := pIdx + Length(Text) - Idx;
              cCount := 0;
              While not (pIdx^ in [6..11, 13]) and (pIdx <= lIdx) Do Begin
                Case pIdx^ Of
                  16..20, 26, 27:
                    Begin
                      Inc(pIdx, SizeOf(LongWord));
                    End;
                  21..22:
                    Begin
                      Inc(pIdx, 2 * SizeOf(Integer));
                    End;
                  23..24:
                    Begin
                      Inc(pIdx, SizeOf(Integer));
                    End;
                  25:
                    Begin
                      Inc(pIdx, SizeOf(aFloat) * 2);
                    End;
                  32..255:
                    Begin
                      Inc(cCount);
                    End;
                End;
                Inc(pIdx);
              End;
              X := (SCREENWIDTH - (cCount * Cw)) Div 2;
              Dec(Idx);
            End;
         25:
            Begin // SCALE control
              ScaleX := gaFloat(@Text[Idx+1]);
              Inc(Idx, SizeOf(aFloat));
              ScaleY := gaFloat(@Text[Idx+1]);
              Inc(Idx, SizeOf(aFloat));
              IsScaled := (ScaleX <> 1) Or (ScaleY <> 1);
              If (ScaleX < 0) or (ScaleY < 0) Then Begin
                SP_BankList[0]^.Changed := True;
                SP_NeedDisplayUpdate := True;
                Exit;
              End Else Begin
                CharW := Max(1, Round(FONTWIDTH * ScaleX));
                CharH := Max(1, Round(FONTHEIGHT * ScaleY));
                Cw := CharW;
                Ch := CharH;
              End;
              T_SCALEX := ScaleX;
              T_SCALEY := ScaleY;
            End;
         26:
          Begin
            // ITALIC control
            t := pLongWord(@Text[Idx+1])^;
            If t <> 8 Then
              If t <> 0 Then Begin
                T_ITALIC := 1;
              End Else Begin
                T_ITALIC := 0;
              End;
            Inc(Idx, SizeOf(LongWord));
          End;
         27:
          Begin
            // BOLD control
            t := pLongWord(@Text[Idx+1])^;
            If t <> 8 Then
              If t <> 0 Then Begin
                T_BOLD := 1;
              End Else Begin
                T_BOLD := 0;
              End;
            Inc(Idx, SizeOf(LongWord));
          End;
         28:
          Begin
            Paper := DefPaper;
            Inc(Idx, SizeOf(LongWord));
          End;
        End;
        Coord := SCREENPOINTER;
        Inc(Coord, (SCREENSTRIDE * Y) + X);
      End;
      Inc(Idx);
    End;

  End;

  PRPOSX := X;
  PRPOSY := Y;

  SP_BankList[0]^.Changed := True;
  SP_NeedDisplayUpdate := True;

End;

Function SP_LineClip(Var x1, y1, x2, y2: Integer; cx1, cy1, cx2, cy2: Integer): Boolean;
Const
  CodeBottom = 1; CodeTop    = 2;
  CodeLeft   = 4; CodeRight  = 8;

  Function CompOutCode(x, y : Integer): Byte;
  Begin
    Result := 0;
    If y >= cy2 Then Result := CodeBottom Else If y < cy1 Then Result := CodeTop;
    If x >= cx2 Then Inc(Result, CodeRight) Else If x < cx1 Then Inc(Result, CodeLeft);
  End;

Var
  OutCode0, OutCode1, OutCodeOut: Byte;
  x, y: Integer;

Begin

  OutCode0 := CompOutCode(x1, y1);
  OutCode1 := CompOutCode(x2, y2);
  Result := False;
  x := 0; y := 0;

  While (OutCode0 <> 0) Or (OutCode1 <> 0) Do Begin
    If (OutCode0 And OutCode1) <> 0 Then Exit Else Begin
      If OutCode0 > 0 Then OutCodeOut := OutCode0 Else OutCodeOut := OutCode1;
      If (OutCodeOut And CodeBottom) = CodeBottom Then Begin
        y := cy2 -1;
        x := x1+(x2-x1)*(y-y1) Div (y2-y1);
      End Else
        IF (OutCodeOut And CodeTop) = CodeTop Then Begin
          y := cy1;
          x := x1+(x2-x1)*(y-y1) Div (y2-y1);
        End Else
          If (OutCodeOut And CodeRight) = CodeRight Then Begin
            x := cx2 -1;
            y := y1+(y2-y1)*(x-x1) Div (x2-x1);
          End Else
            If (OutCodeOut And CodeLeft) = CodeLeft Then Begin
              x := cx1;
              y := y1+(y2-y1)*(x-x1) Div (x2-x1);
            End;
      If OutCodeOut = OutCode0 Then Begin
        x1 := x; y1 := y;
        OutCode0 := CompOutCode(x1, y1);
      End Else Begin
        x2 := x; y2 := y;
        OutCode1 := CompOutCode(x2, y2);
      End;
    End;
  End;

  Result := True;

End;

Procedure SP_DrawLineEx(X1, Y1, X2, Y2: aFloat);
Var
  Dx, Dy: aFloat;
Begin

  Dx := DRPOSX;
  Dy := DRPOSY;
  DRPOSX := X1;
  DRPOSY := Y1;
  SKIPFIRSTPOINT := False;
  SP_DrawLine(X2 - X1, Y2 - Y1);
  DRPOSX := Dx;
  DRPOSY := Dy;

ENd;

Procedure SP_DrawLine(X2, Y2: aFloat);
var
  x1, y1, x3, y3, d, ax, ay, sx, sy, dx, dy: Integer;
  Ptr: pByte;
  Ink: Byte;
  stsy: Integer;
  DrX, DrY: aFloat;
  flip: Boolean;
begin

  If SCREENBPP = 8 Then Begin

    x1 := Round(DRPOSX);
    y1 := Round(DRPOSY);
    x2 := x2 + DRPOSX;
    y2 := y2 + DRPOSY;
    x3 := Round(x2);
    y3 := Round(y2);

    DrX := x2;
    DrY := y2;

    If (x1 < T_CLIPX1) or (y1 < T_CLIPY1) or (x1 >= T_CLIPX2) or (y1 >= T_CLIPY2) Then
      SKIPFIRSTPOINT := False;

    flip := False;
    If y2 < y1 then Begin
      y1 := y1 Xor y3; y3 := y1 Xor y3; y1 := y1 Xor y3;
      x1 := x1 Xor x3; x3 := x1 Xor x3; x1 := x1 Xor x3;
      flip := True;
    End;

    If SP_LineClip(x1, y1, x3, y3, T_CLIPX1, T_CLIPY1, T_CLIPX2, T_CLIPY2) Then Begin

      If SCREENVISIBLE Then SP_SetDirtyRectEx(SCREENX + X1, SCREENY + Y1, SCREENX + X3, SCREENY + Y3);

      If T_INVERSE = 1 Then
        Ink := T_PAPER
      Else
        Ink := T_INK and $FF;

      dx := x3 - x1;
      ax := Abs(dx) shl 1;
      if dx < 0 then
        sx := -1
      else
        sx := 1;

      dy := y3 - y1;
      ay := Abs(dy) shl 1;
      if dy < 0 then
        sy := -1
      else
        sy := 1;

      SP_BankList[0]^.Changed := True;

      Ptr := pByte(NativeUInt(SCREENPOINTER) + (y1 * SCREENSTRIDE) + x1);
      stsy := SCREENSTRIDE * sy;

      If T_OVER = 0 Then Begin
       If Not SKIPFIRSTPOINT Then
          Ptr^ := Ink
        Else
          If Flip Then
            Ptr^ := Ink;
        If ax > ay Then Begin
          d := ay - (ax shr 1);
          If SKIPFIRSTPOINT And flip Then
            if x1 < x3 then Dec(x3) else inc(x3);
          while x1 <> x3 do begin
            if d > -1 then begin
              Inc(Ptr, stsy);
              Dec(d, ax);
            end;
            Inc(Ptr, sx);
            Inc(x1, sx);
            Inc(d, ay);
            Ptr^ := Ink;
          end;
        end else begin
          d := ax - (ay shr 1);
          If SKIPFIRSTPOINT And flip Then
            Dec(y3);
          while y1 < y3 do begin
            if d > -1 then begin
              Inc(Ptr, sx);
              Dec(d, ay);
            end;
            Inc(Ptr, stsy);
            Inc(y1, sy);
            Inc(d, ax);
            Ptr^ := Ink;
          end;
        end;
       If Not SKIPFIRSTPOINT and flip Then
          Ptr^ := Ink;
      End Else Begin
        If Not SKIPFIRSTPOINT Then
          SP_OverPixelPtrVal(Ptr, Ink, T_OVER)
        Else
          If Flip Then
            SP_OverPixelPtrVal(Ptr, Ink, T_OVER);
        If ax > ay Then Begin
          d := ay - (ax shr 1);
          If SKIPFIRSTPOINT And flip Then
            if x1 < x3 then Dec(x3) else inc(x3);
          while x1 <> x3 do begin
            if d > -1 then begin
              Inc(Ptr, stsy);
              Dec(d, ax);
            end;
            Inc(Ptr, sx);
            Inc(x1, sx);
            Inc(d, ay);
            SP_OverPixelPtrVal(Ptr, Ink, T_OVER);
          end;
        end else begin
          d := ax - (ay shr 1);
          If SKIPFIRSTPOINT And flip Then Dec(y3);
          while y1 < y3 do begin
            if d > -1 then begin
              Inc(Ptr, sx);
              Dec(d, ay);
            end;
            Inc(Ptr, stsy);
            Inc(y1, sy);
            Inc(d, ax);
            SP_OverPixelPtrVal(Ptr, Ink, T_OVER);
          end;
        end;
        If Not SKIPFIRSTPOINT and flip Then
          SP_OverPixelPtrVal(Ptr, Ink, T_OVER);
      End;

      SP_BankList[0]^.Changed := True;

    End;

    DRPOSX := DrX;
    DRPOSY := DrY;

  End Else

    SP_DrawLine32(X2, Y2);

End;

Procedure SP_DrawLineTo(X1, Y1, X2, Y2: Integer; Ink: Byte);
var
  d, ax, ay, sx, sy, dx, dy, w: Integer;
  Ptr, dst: pByte;
  ink_long: LongWord;
  ink_64: NativeUInt;
  stsy: Integer;
begin

  dst := SCREENPOINTER;

  If y2 < y1 then Begin
    y1 := y1 Xor y2; y2 := y1 Xor y2; y1 := y1 Xor y2;
    x1 := x1 Xor x2; x2 := x1 Xor x2; x1 := x1 Xor x2;
  End;

  If SP_LineClip(x1, y1, x2, y2, T_CLIPX1, T_CLIPY1, T_CLIPX2, T_CLIPY2) Then Begin

    If SCREENVISIBLE Then SP_SetDirtyRectEx(SCREENX +X1, SCREENY + Y1, SCREENX + X2, SCREENY + Y2);

    dx := x2 - x1;
    ax := Abs(dx) shl 1;
    if dx < 0 then
      sx := -1
    else
      sx := 1;

    dy := y2 - y1;
    ay := Abs(dy) shl 1;
    if dy < 0 then
      sy := -1
    else
      sy := 1;

    If dx = 0 then begin
      If y1 > y2 Then Begin
        y1 := y1 Xor y2; y2 := y1 Xor y2; y1 := y1 Xor y2;
      End;
      Ptr := pByte(NativeUInt(dst) + (y1 * SCREENSTRIDE) + x1);
      While y1 <> y2 do begin
        Ptr^ := Ink;
        Inc(y1);
        Inc(Ptr, SCREENSTRIDE);
      End;
      Ptr^ := Ink;
      Exit;
    End;

    If dy = 0 then Begin
      If x1 > x2 Then Begin
        x1 := x1 Xor x2; x2 := x1 Xor x2; x1 := x1 Xor x2;
      End;
      Ptr := pByte(NativeUInt(dst) + (y1 * SCREENSTRIDE) + x1);
      ink_long := Ink + (Ink shl 8) + (Ink Shl 16) + (Ink shl 24);
      w := (x2 - x1) + 1;
      {$IFDEF CPU64}
      ink_64 := ink_Long + (NativeUInt(Ink_Long) Shl 32);
      While w > SizeOf(NativeUint) Do Begin
        pNativeUInt(Ptr)^ := ink_64;
        Inc(pNativeUInt(Ptr));
        Dec(w, SizeOf(NativeUInt));
      End;
      {$ENDIF}
      While w > SizeOf(LongWord) do Begin
        pLongWord(Ptr)^ := Ink_Long;
        Inc(pLongWord(Ptr));
        Dec(w, SizeOf(LongWord));
      End;
      While w > 0 do Begin
        pByte(Ptr)^ := Ink;
        Inc(pByte(Ptr));
        Dec(w);
      End;
      Exit;
    End;

    Ptr := pByte(NativeUInt(dst) + (y1 * SCREENSTRIDE) + x1);
    stsy := SCREENSTRIDE * sy;

    Ptr^ := Ink;
    If ax > ay Then Begin
      d := ay - (ax shr 1);
      while x1 <> x2 do begin
        if d > -1 then begin
          Inc(Ptr, stsy);
          Dec(d, ax);
        end;
        Inc(Ptr, sx);
        Inc(x1, sx);
        Inc(d, ay);
        Ptr^ := Ink;
      end;
    end else begin
      d := ax - (ay shr 1);
      while y1 <> y2 do begin
        if d > -1 then begin
          Inc(Ptr, sx);
          Dec(d, ay);
        end;
        Inc(Ptr, stsy);
        Inc(y1, sy);
        Inc(d, ax);
        Ptr^ := Ink;
      end;
    end;
    Ptr^ := Ink;

  End;

End;

Procedure SP_DrawRect(x1, y1, x2, y2: Integer; Ink: Byte);
Begin

  SP_DrawLineTo(x1, y1, x2, y1, Ink);
  SP_DrawLineTo(x1, y1+1, x1, y2, Ink);
  SP_DrawLineTo(x1+1, y2, x2, y2, Ink);
  SP_DrawLineTo(x2, y1+1, x2, y2 -1, Ink);

End;

Procedure SP_RadToAngle(var Angle: aFloat);
Begin

  If MathMode = 0 Then

    Exit

  Else

    Case MathMode of

      1: Angle := RadToDeg(Angle);    // Radians to degrees
      2: Angle := Angle / (PI * 2);   // Radians to turns
      3: Angle := Angle / (PI / 200); // Radians to Gradians

    End;

End;

Procedure SP_AngleToRad(var Angle: aFloat);
Begin

  If MathMode = 0 Then

    Exit

  Else

    Case MathMode of

      1: Angle := DegToRad(Angle);    // Degrees to radians
      2: Angle := Angle * PI * 2;     // Turns to radians
      3: Angle := Angle * (PI / 200); // Gradians to radians

    End;

End;

Procedure SP_DrawSpeccyCurve(X, Y, Angle: aFloat);
Var
  Z, W, F, M0, M1, M2, M3, M4, SC, MM1: aFloat;
  NumArcs: Integer;
Begin

  SP_AngleToRad(Angle);
  Z := Abs((Abs(X)+Abs(Y))/Sin(Angle/2));
  If (Round(Sin(Angle/2)*10000000) = 0) or (Z < 1) Then
    SP_DrawLine(X, Y)
  Else Begin
    NumArcs := Min(4 * Round(Round(Abs(Angle * Sqrt(Z)) + 0.5) / 1) +4, 252);
    W := Sin(Angle/(2*NumArcs))/Sin(Angle/2);

    M0 := DRPOSY;
    SC := DRPOSX;
    F := 0.5*(Angle-(Angle/NumArcs));
    M1 := (Y*W*Sin(F))+(X*W*Cos(F));
    M2 := (Y*W*Cos(F))-(X*W*Sin(F));
    M3 := Cos(Angle/NumArcs);
    M4 := Sin(Angle/NumArcs);

    While NumArcs > 0 Do Begin

      M0 := M0 + M2;
      SC := SC + M1;

      SP_DrawLine(SC - DRPOSX, M0 - DRPOSY);

      MM1 := M1;
      M1 := (M1*M3)-(M2*M4);
      M2 := (MM1*M4)+(M2*M3);

      Dec(NumArcs);

    End;

  End;

End;

Procedure SP_SetPixel(X, Y: aFloat); Inline;
Var
  xr, yr: Integer;
  Ink: Byte;
  Ptr: pByte;
Begin

  If T_INVERSE = 0 Then
    Ink := T_INK and $FF
  Else
    Ink := T_PAPER and $FF;
  If (x >= T_CLIPX1) And (x < T_CLIPX2) And (y >= T_CLIPY1) And (y < T_CLIPY2) Then Begin
    xr := Round(X); yr := Round(Y);
    Ptr := pByte(NativeUInt(SCREENPOINTER)+(LongWord(yr * SCREENSTRIDE) + LongWord(xr)));
    IF T_OVER = 0 Then
      Ptr^ := Ink
    Else
      SP_OverPixelPtrVal(Ptr, Ink, T_OVER);
  End;

  DRPOSX := X;
  DRPOSY := Y;

End;

Procedure SP_SetPixelPtr(Ptr: pByte); Inline;
Var
  Ink: Byte;
Begin

  If T_INVERSE = 0 Then
    Ink := T_INK and $FF
  Else
    Ink := T_PAPER and $FF;
  IF T_OVER = 0 Then
    Ptr^ := Ink
  Else
    SP_OverPixelPtrVal(Ptr, Ink, T_OVER);

End;

Procedure SP_SetPixelPtrClr(Ptr: pByte; Ink: Byte); Inline;
Begin

  IF T_OVER = 0 Then
    Ptr^ := Ink
  Else
    SP_OverPixelPtrVal(Ptr, Ink, T_OVER);

End;

Procedure SP_SetPixelClr(X, Y: Integer; Ink: Byte); Inline;
Var
  Ptr: pByte;
Begin

  If (X >= T_CLIPX1) And (X < T_CLIPX2) And (Y >= T_CLIPY1) And (Y < T_CLIPY2) Then Begin
    Ptr := pByte(NativeUInt(SCREENPOINTER)+(LongWord(Y * SCREENSTRIDE) + LongWord(X)));
    IF T_OVER = 0 Then
      Ptr^ := Ink
    Else
      SP_OverPixelPtrVal(Ptr, Ink, T_OVER);
  End;

  DRPOSX := X;
  DRPOSY := Y;

End;

Procedure SP_DrawEllipse(CX, CY, Rx, Ry: Integer);
var
  x, y, p, px, py, twoRx2, twoRy2: Integer;
  Rx2, Ry2: Int64;
  cxpx, cypy, cxmx, cymy: Integer;
begin

  If ((rx = 0) and (ry = 0)) or ((cx+rx)<0) or ((cx-rx)>SCREENWIDTH) or ((cy+ry)<0) or ((cy-ry)>SCREENHEIGHT) Then Exit;

  If SCREENBPP = 8 Then Begin

    Rx := Abs(Rx);
    Ry := Abs(Ry);

    Rx2 := Rx * Rx;
    Ry2 := Ry * Ry;
    twoRx2 := 2 * Rx2;
    twoRy2 := 2 * Ry2;
    x := 0;
    y := Ry;
    px := 0;
    py := twoRx2 * y;

    cxpx := Cx + X; cypy := Cy + Y;
    cxmx := Cx - X; cymy := Cy - Y;

    SP_SetPixel(cxpx, cypy);
    SP_SetPixel(cxpx, cymy);
    If cxmx <> cxpx Then Begin
      SP_SetPixel(cxmx, cymy);
      SP_SetPixel(cxmx, cypy);
    End;

    p := Ry2 - (Rx2 * Ry) + (Rx2 div 4);

    while px < py do begin
       Inc(x);
       Inc(px, twoRy2);
       if p < 0 then
          Inc(p, Ry2 + px)
       else begin
          Dec(y);
          Dec(py, twoRx2);
          Inc(p, Ry2 + px - py);
          dec(cypy);
          inc(cymy);
       end;
       inc(cxpx);
       dec(cxmx);
       SP_SetPixel(cxpx, cypy);
       SP_SetPixel(cxmx, cypy);
       SP_SetPixel(cxpx, cymy);
       SP_SetPixel(cxmx, cymy);
    end;

    {$R-}
    p := Round(Ry2 * (x + 0.5) * (x + 0.5) + Rx2 * (y-1) * (y-1) - Rx2 * Ry2);
    {$R-}
    while y > 0 do begin
       Dec(y);
       Dec(py, twoRx2);
       if p > 0 then
          Inc(p, Rx2 - py)
       else begin
          Inc(x);
          Inc(px, twoRy2);
          Inc(p, Rx2 - py + px);
          inc(cxpx);
          dec(cxmx);
       end;
       dec(cypy);
       inc(cymy);
       SP_SetPixel(cxpx, cypy);
       SP_SetPixel(cxmx, cypy);
       if y > 0 Then Begin
         SP_SetPixel(cxpx, cymy);
         SP_SetPixel(cxmx, cymy);
       End;
    end;

  End Else

    SP_DrawEllipse32(Cx, Cy, Rx, Ry);

  If SCREENVISIBLE Then SP_SetDirtyRect((SCREENX + Cx) - Rx, (SCREENY + Cy) - Ry, SCREENX + Cx + Rx, SCREENY + Cy + Ry);
  SP_BankList[0]^.Changed := True;

end;

Procedure SP_DrawTexEllipse(CX, CY, Rx, Ry: Integer; const TextureStr: aString; tW, tH: LongWord);
var
  Trans: Word;
  DstA, TexBase: pByte;
  tClr, Clr: Byte;
  Graphic: pSP_Graphic_Info;
  x, y, p, px, py, twoRx2, twoRy2: Int64;
  Rx2, Ry2: Int64;
  cxpx, cypy, cxmx, cymy, lcypy, lcymy: Integer;

  Procedure DrawTexSpan(X1, X2, Y: Integer);
  Begin
    X1 := Max(T_CLIPX1, X1);
    X2 := Min(T_CLIPX2, X2);
    If X2 > X1 Then Begin
      DstA := pByte(NativeUInt(SCREENPOINTER) + X1 + (Y * SCREENSTRIDE));
      If T_OVER = 0 Then Begin
        If Trans <> $FFFF Then Begin
          While X2 >= X1 Do Begin
            Clr := pByte(TexBase + ((X1 mod Integer(tW)) + ((y mod Integer(tH)) * Integer(tw))))^;
            If Clr <> tClr Then DstA^ := Clr;
            Inc(DstA);
            Inc(X1);
          End;
        End Else
          While X2 >= X1 Do Begin
            DstA^ := pByte(TexBase + ((X1 mod Integer(tW)) + ((y mod Integer(tH)) * Integer(tw))))^;
            Inc(DstA);
            Inc(X1);
          End;
      End Else Begin
        If Trans <> $FFFF Then Begin
          While X2 >= X1 Do Begin
            Clr := pByte(TexBase + ((X1 mod Integer(tW)) + ((y mod Integer(tH)) * Integer(tw))))^;
            If Clr <> tClr Then SP_OverPixelPtrVal(DstA, Clr, T_OVER);;
            Inc(DstA);
            Inc(X1);
          End;
        End Else
          While X2 >= X1 Do Begin
            SP_OverPixelPtrVal(DstA, pByte(TexBase + ((X1 mod Integer(tW)) + ((y mod Integer(tH)) * Integer(tw))))^, T_OVER);
            Inc(DstA);
            Inc(X1);
          End;
      End;
    End;
  End;

begin

  If ((rx = 0) and (ry = 0)) or ((cx+rx)<0) or ((cx-rx)>SCREENWIDTH) or ((cy+ry)<0) or ((cy-ry)>SCREENHEIGHT) Then Exit;

  If SCREENBPP = 8 Then Begin

    tClr := 0;

    // if TextureStr = '' Then tW holds a pointer to the graphic bank's data,
    // and tH holds a pointer to the graphic bank's info field.

    If TextureStr = '' Then Begin
      TexBase := pByte(tW);
      Graphic := pSP_Graphic_Info(tH);
      tW := Graphic.Width;
      tH := Graphic.Height;
      Trans := Graphic.Transparent;
    End Else Begin
      TexBase := @TextureStr[11];
      Trans := pWord(@TextureStr[9])^;
    End;
    If Trans <> $FFFF Then
      tClr := Trans And $FF;

    Rx := Abs(Rx);
    Ry := Abs(Ry);

    Rx2 := Rx * Rx;
    Ry2 := Ry * Ry;
    twoRx2 := 2 * Rx2;
    twoRy2 := 2 * Ry2;
    x := 0;
    y := Ry;
    px := 0;
    py := twoRx2 * y;

    cxpx := Cx + X; cypy := Cy + Y;
    cxmx := Cx - X; cymy := Cy - Y;

    if Ry = 1 Then Begin
      SP_SetPixelClr(cxpx, cypy, pByte(TexBase + ((cxpx mod Integer(tW)) + ((cypy mod Integer(tH)) * Integer(tw))))^);
      SP_SetPixelClr(cxpx, cymy, pByte(TexBase + ((cxpx mod Integer(tW)) + ((cymy mod Integer(tH)) * Integer(tw))))^);
    End;
    If cxmx <> cxpx Then Begin
      SP_SetPixelClr(cxmx, cymy, pByte(TexBase + ((cxmx mod Integer(tW)) + ((cymy mod Integer(tH)) * Integer(tw))))^);
      SP_SetPixelClr(cxmx, cypy, pByte(TexBase + ((cxmx mod Integer(tW)) + ((cypy mod Integer(tH)) * Integer(tw))))^);
    End;

    p := Ry2 - (Rx2 * Ry) + (Rx2 div 4);
    lcypy := -1;
    lcymy := -1;

    while px < py do begin
      Inc(x);
      Inc(px, twoRy2);
      if p < 0 then
        Inc(p, Ry2 + px)
      else begin
        if (lcypy <> cypy) And (cypy >= T_CLIPY1) and (cypy <= T_CLIPY2) Then DrawTexSpan(cxmx, cxpx, cypy);
        if (lcymy <> cymy) And (cypy <> cymy) And (cymy >= T_CLIPY1) and (cymy <= T_CLIPY2) Then DrawTexSpan(cxmx, cxpx, cymy);
        lcypy := cypy;
        lcymy := cymy;
        Dec(y);
        Dec(py, twoRx2);
        Inc(p, Ry2 + px - py);
        dec(cypy);
        inc(cymy);
      end;
      inc(cxpx);
      dec(cxmx);
    end;
    if (lcypy <> cypy) And (cypy >= T_CLIPY1) and (cypy <= T_CLIPY2) Then DrawTexSpan(cxmx, cxpx, cypy);
    if (lcymy <> cymy) And (cypy <> cymy) And (cymy >= T_CLIPY1) and (cymy <= T_CLIPY2) Then DrawTexSpan(cxmx, cxpx, cymy);

    {$R-}
    p := Round(Ry2 * (x + 0.5) * (x + 0.5) + Rx2 * (y-1) * (y-1) - Rx2 * Ry2);
    {$R-}
    while y > 0 do begin
       Dec(y);
       Dec(py, twoRx2);
       if p > 0 then
          Inc(p, Rx2 - py)
       else begin
          Inc(x);
          Inc(px, twoRy2);
          Inc(p, Rx2 - py + px);
          inc(cxpx);
          dec(cxmx);
       end;
       dec(cypy);
       inc(cymy);
       if (cypy >= T_CLIPY1) and (cypy <= T_CLIPY2) Then DrawTexSpan(cxmx, cxpx, cypy);
       if (y > 0) And (cypy <> cymy) And (cymy >= T_CLIPY1) and (cymy <= T_CLIPY2) Then DrawTexSpan(cxmx, cxpx, cymy);
    end;

  End Else

    SP_DrawSolidEllipse32(cX, cY, rX, rY);

  If SCREENVISIBLE Then SP_SetDirtyRect((SCREENX + Cx) - Rx, (SCREENY + Cy) - Ry, SCREENX + Cx + Rx, SCREENY + Cy + Ry);
  SP_BankList[0]^.Changed := True;

end;

Procedure SP_DrawSolidEllipse(CX, CY, Rx, Ry: Integer);
var
  Ink: Byte;
  DstA: pByte;
  x, y, p, px, py, twoRx2, twoRy2: Int64;
  Rx2, Ry2: Int64;
  cxpx, cypy, cxmx, cymy, lcypy, lcymy: Integer;

  Procedure DrawSpan(X1, X2, Y: Integer);
  Begin
    X1 := Max(T_CLIPX1, X1);
    X2 := Min(T_CLIPX2 -1, X2);
    If X2 > X1 Then Begin
      DstA := pByte(NativeUInt(SCREENPOINTER) + X1 + (Y * SCREENSTRIDE));
      If T_OVER = 0 Then Begin
        While X2 >= X1 Do Begin
          DstA^ := Ink;
          Inc(DstA);
          Dec(X2);
        End;
      End Else Begin
        While X2 >= X1 Do Begin
          SP_OverPixelPtrVal(DstA, Ink, T_OVER);
          Inc(DstA);
          Dec(X2);
        End;
      End;
    End;
  End;

begin

  If ((rx = 0) and (ry = 0)) or ((cx+rx)<0) or ((cx-rx)>SCREENWIDTH) or ((cy+ry)<0) or ((cy-ry)>SCREENHEIGHT) Then Exit;

  If SCREENBPP = 8 Then Begin

    If T_INVERSE = 0 Then
      Ink := T_INK
    Else
      Ink := T_PAPER;

    Rx := Abs(Rx);
    Ry := Abs(Ry);

    Rx2 := Rx * Rx;
    Ry2 := Ry * Ry;
    twoRx2 := 2 * Rx2;
    twoRy2 := 2 * Ry2;
    x := 0;
    y := Ry;
    px := 0;
    py := twoRx2 * y;

    cxpx := Cx + X; cypy := Cy + Y;
    cxmx := Cx - X; cymy := Cy - Y;

    If Ry = 1 Then Begin
      SP_SetPixel(cxpx, cypy);
      SP_SetPixel(cxpx, cymy);
    End;
    If cxmx <> cxpx Then Begin
      SP_SetPixel(cxmx, cymy);
      SP_SetPixel(cxmx, cypy);
    End;

    p := Ry2 - (Rx2 * Ry) + (Rx2 div 4);
    lcypy := -1;
    lcymy := -1;

    while px < py do begin
      Inc(x);
      Inc(px, twoRy2);
      if p < 0 then
        Inc(p, Ry2 + px)
      else begin
        if (lcypy <> cypy) And (cypy >= T_CLIPY1) and (cypy < T_CLIPY2) Then DrawSpan(cxmx, cxpx, cypy);
        if (lcymy <> cymy) And (cypy <> cymy) And (cymy >= T_CLIPY1) and (cymy < T_CLIPY2) Then DrawSpan(cxmx, cxpx, cymy);
        lcypy := cypy;
        lcymy := cymy;
        Dec(y);
        Dec(py, twoRx2);
        Inc(p, Ry2 + px - py);
        dec(cypy);
        inc(cymy);
      end;
      inc(cxpx);
      dec(cxmx);
    end;
    if (lcypy <> cypy) And (cypy >= T_CLIPY1) and (cypy < T_CLIPY2) Then DrawSpan(cxmx, cxpx, cypy);
    if (lcymy <> cymy) And (cypy <> cymy) And (cymy >= T_CLIPY1) and (cymy < T_CLIPY2) Then DrawSpan(cxmx, cxpx, cymy);

    {$R-}
    p := Round(Ry2 * (x + 0.5) * (x + 0.5) + Rx2 * (y-1) * (y-1) - Rx2 * Ry2);
    {$R-}
    while y > 0 do begin
       Dec(y);
       Dec(py, twoRx2);
       if p > 0 then
          Inc(p, Rx2 - py)
       else begin
          Inc(x);
          Inc(px, twoRy2);
          Inc(p, Rx2 - py + px);
          inc(cxpx);
          dec(cxmx);
       end;
       dec(cypy);
       inc(cymy);
       if (cypy >= T_CLIPY1) and (cypy < T_CLIPY2) Then DrawSpan(cxmx, cxpx, cypy);
       if (y > 0) And (cypy <> cymy) And (cymy >= T_CLIPY1) and (cymy < T_CLIPY2) Then DrawSpan(cxmx, cxpx, cymy);
    end;

  End Else

    SP_DrawSolidEllipse32(cX, cY, rX, rY);

  If SCREENVISIBLE Then SP_SetDirtyRect((SCREENX + Cx) - Rx, (SCREENY + Cy) - Ry, SCREENX + Cx + Rx, SCREENY + Cy + Ry);
  SP_BankList[0]^.Changed := True;

end;

Procedure SP_DrawRectangle(X1, Y1, X2, Y2: Integer);
Var
  T, a, b, c, d: Integer;
  p: pByte;
Begin

  If X1 > X2 Then Begin T := X1; X1 := X2; X2 := T; End;
  If Y1 > Y2 Then Begin T := Y1; Y1 := Y2; Y2 := T; End;

  If X1 >= T_CLIPX2 Then Exit;
  If Y1 >= T_CLIPY2 Then Exit;
  If X2 < T_CLIPX1 Then Exit;
  If Y2 < T_CLIPY1 Then Exit;

  If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X1, SCREENY + Y1, SCREENX + X2, SCREENY + Y2);

  If SCREENBPP = 8 Then Begin

    a := Max(X1, T_CLIPX1); b := Min(X2, T_CLIPX2 -1);
    c := Max(Y1, T_CLIPY1); d := Min(Y2, T_CLIPY2 -1);

    // Top edge

    If Y1 >= T_CLIPY1 Then Begin
      p := pByte(NativeInt(SCREENPOINTER) + (SCREENSTRIDE * Y1) + a);
      For t := 0 to b - a Do Begin
        SP_SetPixelPtr(p);
        Inc(p);
      End;
    End;

    // Left edge

    If X1 >= T_CLIPX1 Then Begin
      p := pByte(NativeInt(SCREENPOINTER) + (SCREENSTRIDE * c) + X1);
      For t := 0 to d - c Do Begin
        SP_SetPixelPtr(p);
        Inc(p, SCREENSTRIDE);
      End;
    End;

    // Right edge

    If X2 < T_CLIPX2 Then Begin
      p := pByte(NativeInt(SCREENPOINTER) + (SCREENSTRIDE * c) + X2);
      For t := 0 to d - c Do Begin
        SP_SetPixelPtr(p);
        Inc(p, SCREENSTRIDE);
      End;
    End;

    // Bottom Edge

    If Y2 < T_CLIPY2 Then Begin
      p := pByte(NativeInt(SCREENPOINTER) + (SCREENSTRIDE * Y2) + a);
      For t := 0 to b - a Do Begin
        SP_SetPixelPtr(p);
        Inc(p);
      End;
    End;

  End Else

    SP_DrawRectangle32(X1, Y1, X2, Y2);

  SP_BankList[0]^.Changed := True;
  DRPOSX := X2;
  DRPOSY := Y2;

End;

Procedure SP_DrawTexRectangle(X1, Y1, X2, Y2: Integer; const TextureStr: aString; tW, tH: LongWord);
Var
  T, W: Integer;
  Dst, TexBase: pByte;
  Graphic: pSP_Graphic_Info;
  Trans: Word;
  tClr, Clr: Byte;
Begin

  tClr := 0;

  If X1 > X2 Then Begin T := X1; X1 := X2; X2 := T; End;
  If Y1 > Y2 Then Begin T := Y1; Y1 := Y2; Y2 := T; End;

  If X1 < 0 Then X1 := 0; If X1 >= SCREENSTRIDE Then Exit;
  If Y1 < 0 Then Y1 := 0; If Y1 >= SCREENHEIGHT Then Exit;
  If X2 < 0 Then Exit; If X2 >= SCREENSTRIDE Then X2 := SCREENSTRIDE -1;
  If Y2 < 0 Then Exit; If Y2 >= SCREENHEIGHT Then Y2 := SCREENHEIGHT -1;

  If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X1, SCREENY + Y1, SCREENX + X2, SCREENY + Y2);
  Dst := pByte(NativeInt(SCREENPOINTER) + (SCREENSTRIDE * Y1) + X1);
  If TextureStr = '' Then Begin
    TexBase := pByte(tW);
    Graphic := pSP_Graphic_Info(tH);
    tW := Graphic.Width;
    tH := Graphic.Height;
    Trans := Graphic.Transparent;
  End Else Begin
    TexBase := @TextureStr[11];
    Trans := pWord(@TextureStr[9])^;
  End;
  If Trans <> $FFFF Then
    tClr := Trans And $FF;

  If Trans <> $FFFF Then Begin
    While Y1 <= Y2 Do Begin
      If (Y1 >= T_CLIPY1) And (Y1 < T_CLIPY2) Then Begin
        W := X1;
        While W <= X2 Do Begin
          Clr := pByte(TexBase + (W mod Integer(tW)) + ((Y1 mod Integer(tH)) * Integer(tw)))^;
          If Clr <> tClr Then
            If (W >= T_CLIPX1) And (W < T_CLIPX2) Then
              SP_SetPixelPtrClr(Dst, Clr);
          Inc(Dst);
          Inc(W);
        End;
        Inc(Dst, SCREENSTRIDE - (X2 - X1) -1);
      End Else
        Inc(Dst, SCREENSTRIDE);
      Inc(Y1);
    End;
  End Else Begin
    While Y1 <= Y2 Do Begin
      If (Y1 >= T_CLIPY1) And (Y1 < T_CLIPY2) Then Begin
        W := X1;
        While W <= X2 Do Begin
          If (W >= T_CLIPX1) And (W < T_CLIPX2) Then
            SP_SetPixelPtrClr(Dst, pByte(TexBase + (W mod Integer(tW)) + ((Y1 mod Integer(tH)) * Integer(tw)))^);
          Inc(Dst);
          Inc(W);
        End;
        Inc(Dst, SCREENSTRIDE - (X2 - X1) -1);
      End Else
        Inc(Dst, SCREENSTRIDE);
      Inc(Y1);
    End;
  End;

  SP_BankList[0]^.Changed := True;
  DRPOSX := X2;
  DRPOSY := Y2;

End;

Procedure SP_DrawSolidRectangle(X1, Y1, X2, Y2: Integer);
Var
  T, W: Integer;
  Dst: pByte;
Begin

  If X1 > X2 Then Begin T := X1; X1 := X2; X2 := T; End;
  If Y1 > Y2 Then Begin T := Y1; Y1 := Y2; Y2 := T; End;

  If X1 < T_CLIPX1 Then X1 := T_CLIPX1; If X1 >= SCREENSTRIDE Then Exit;
  If Y1 < T_CLIPY1 Then Y1 := T_CLIPY1; If Y1 >= SCREENHEIGHT Then Exit;
  If X2 < 0 Then Exit; If X2 >= T_CLIPX2 Then X2 := T_CLIPX2 -1;
  If Y2 < 0 Then Exit; If Y2 >= T_CLIPY2 Then Y2 := T_CLIPY2 -1;

  If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X1, SCREENY + Y1, SCREENX + X2, SCREENY + Y2);

  If SCREENBPP = 8 Then Begin

    Dst := pByte(NativeInt(SCREENPOINTER) + (SCREENSTRIDE * Y1) + X1);

    If T_OVER = 0 Then Begin

      While Y1 <= Y2 Do Begin
        W := X1;
        While W <= X2 Do Begin
          SP_SetPixelPtr(Dst);
          Inc(Dst);
          Inc(W);
        End;
        Inc(Dst, SCREENSTRIDE - (X2 - X1) -1);
        Inc(Y1);
      End;

    End Else Begin

      While Y1 <= Y2 Do Begin
        W := X1;
        While W <= X2 Do Begin
          SP_OverPixelPtrVal(Dst, T_INK, T_OVER);
          Inc(Dst);
          Inc(W);
        End;
        Inc(Dst, SCREENSTRIDE - (X2 - X1) -1);
        Inc(Y1);
      End;

    End;

  End Else

    SP_DrawSolidRectangle32(X1, Y1, X2, Y2);

  SP_BankList[0]^.Changed := True;
  DRPOSX := X2;
  DRPOSY := Y2;

End;

Procedure SP_DrawCurve(CurveStartX, CurveStartY, X, Y, CurveEndX, CurveEndY: aFloat; N: Integer);
Var
  Idx: Integer;
  t, t2, omt, omt2, omt2t: aFloat;
Begin

  t := 0;

  For Idx := 1 to N Do Begin

    omt := (1 - t);
    omt2 := omt * omt;
    omt2t := 2 * omt * t;
    t2 := t * t;
    t := t + 1/n;
    SP_DrawLine(omt2 * CurveStartX + omt2t * X + t2 * CurveEndX - DRPOSX, omt2 * CurveStartY + omt2t * Y + t2 * CurveEndY - DRPOSY);

  End;

End;

Procedure SP_GetRegion(Src: pByte; SrcW, SrcH: LongWord; Var Dest: aString; rX, rY, rW, rH, T: Integer; Var Error: TSP_ErrorCode);
Var
  W: LongWord;
  Dst: pByte;
Begin

  rX := Max(Rx, 0);
  rY := Max(Ry, 0);
  If rX + rW > Integer(SrcW) Then
    rW := Integer(SrcW) - rX;
  If rY + rH > Integer(SrcH) Then
    rH := Integer(SrcH) - rY;
  If (rW <= 0) or (rH <= 0) or (rW > integer(SrcW)) or (rH > integer(SrcH)) Then Begin
    Error.Code := SP_ERR_INVALID_REGION;
    Exit;
  End;

  SetLength(Dest, rW * rH);
  If T >= 0 Then
    Dest := LongWordToString(rW) + LongWordToString(rH) + aChar(T And $FF) + #0 + Dest
  Else
    Dest := LongWordToString(rW) + LongWordToString(rH) + #255 + #255 + Dest;
  Dst := @Dest[3 + (SizeOf(LongWord) * 2)];

  Inc(Src, (Integer(SrcW) * rY) + rX);

  While rH > 0 Do Begin

    W := rW;
    {$IFDEF CPU64}
    While W > SizeOf(NativeUInt) Do Begin
      pNativeUInt(Dst)^ := pNativeUInt(Src)^;
      Inc(pNativeUInt(Dst));
      Inc(pNativeUInt(Src));
      Dec(W, SizeOf(NativeUInt));
    End;
    {$ENDIF}
    While W > SizeOf(LongWord) Do Begin
      pLongWord(Dst)^ := pLongWord(Src)^;
      Inc(pLongWord(Dst));
      Inc(pLongWord(Src));
      Dec(W, SizeOf(LongWord));
    End;
    While W > 0 Do Begin
      Dst^ := Src^;
      Inc(Dst);
      Inc(Src);
      Dec(W);
    End;
    Dec(rH);
    Inc(Src, Integer(SrcW) - rW);

  End;

  Error.Code := SP_ERR_OK;

End;

Procedure SP_PutRegion(Dst: pByte; dX, dY: Integer; dW, dH: LongWord; Src: pByte; SrcLen: Integer; RotAngle, Scale: aFloat; Var cX1, cY1, cX2, cY2: Integer; Var Error: TSP_ErrorCode);
Var
  W, W2, H, SrcX, SrcY, SrcW, SrcH: LongWord;
  TransparentColour: Word;
  TC: Byte;
  Graphic: pSP_Graphic_Info;
Begin

  If SrcLen >= 10 Then Begin
    W := pLongWord(Src)^;
    Inc(Src, SizeOf(LongWord));
    H := pLongWord(Src)^;
    Inc(Src, SizeOf(LongWord));
    If SrcLen - 10 = Integer(W*H) Then Begin
      TransparentColour := pWord(Src)^;
      Inc(Src, SizeOf(Word));
    End Else Begin
      Error.Code := SP_ERR_INVALID_GRAB_STRING;
      Exit;
    End;
  End Else
    If SrcLen < 0 Then Begin
      Graphic := pSP_Graphic_Info(Src);
      Src := Graphic^.Data;
      W := Graphic^.Width;
      H := Graphic^.Height;
      TransparentColour := Graphic^.Transparent;
    End Else Begin
      Error.Code := SP_ERR_INVALID_GRAB_STRING;
      Exit;
    End;

  If (RotAngle <> 0) or (Scale <> 1) Then
    SP_RotateSize(Src, W, H, Dst, dX, dY, dW, dH, TransparentColour, RotAngle, Scale, cX1, cY1, cX2, cY2)
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
    If COVER = 0 Then Begin
      If TransparentColour <> $FFFF Then Begin
        TC := TransparentColour And $FF;
        While SrcH > 0 Do Begin
          W2 := SrcW;
          While W2 > 0 Do Begin
            If Src^ <> TC Then Dst^ := Src^;
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
          {$IFDEF CPU64}
          While W2 > SizeOf(NativeUInt) Do Begin
            pNativeUInt(Dst)^ := pNativeUInt(Src)^;
            Inc(pNativeUInt(Dst));
            Inc(pNativeUInt(Src));
            Dec(W2, SizeOf(NativeUInt));
          End;
          {$ENDIF}
          While W2 > SizeOf(LongWord) Do Begin
            pLongWord(Dst)^ := pLongWord(Src)^;
            Inc(pLongWord(Dst));
            Inc(pLongWord(Src));
            Dec(W2, SizeOf(LongWord));
          End;
          While W2 > 0 Do Begin
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
            If Src^ <> TC Then SP_OverPixelPtr(Dst, Src, T_OVER);
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
            SP_OverPixelPtr(Dst, Src, T_OVER);
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

Procedure SP_PutRegion_NO_OVER(Dst: pByte; dX, dY: Integer; dW, dH: LongWord; Src: pByte; SrcLen: Integer; Var cX1, cY1, cX2, cY2: Integer; Var Error: TSP_ErrorCode);
Var
  W, W2, H, SrcX, SrcY, SrcW, SrcH: LongWord;
  TransparentColour: Word;
  TC: Byte;
  Graphic: pSP_Graphic_Info;
Begin

  If SrcLen >= 10 Then Begin
    W := pLongWord(Src)^;
    Inc(Src, SizeOf(LongWord));
    H := pLongWord(Src)^;
    Inc(Src, SizeOf(LongWord));
    If SrcLen - 10 = Integer(W*H) Then Begin
      TransparentColour := pWord(Src)^;
      Inc(Src, SizeOf(Word));
    End Else Begin
      Error.Code := SP_ERR_INVALID_GRAB_STRING;
      Exit;
    End;
  End Else
    If SrcLen < 0 Then Begin
      Graphic := pSP_Graphic_Info(Src);
      Src := Graphic^.Data;
      W := Graphic^.Width;
      H := Graphic^.Height;
      TransparentColour := Graphic^.Transparent;
    End Else Begin
      Error.Code := SP_ERR_INVALID_GRAB_STRING;
      Exit;
    End;

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
  If TransparentColour <> $FFFF Then Begin
    TC := TransparentColour And $FF;
    While SrcH > 0 Do Begin
      W2 := SrcW;
      While W2 > 0 Do Begin
        If Src^ <> TC Then Dst^ := Src^;
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
      {$IFDEF CPU64}
      While W2 > SizeOf(NativeUInt) Do Begin
        pNativeUInt(Dst)^ := pNativeUInt(Src)^;
        Inc(pNativeUInt(Dst));
        Inc(pNativeUInt(Src));
        Dec(W2, SizeOf(NativeUInt));
      End;
      {$ENDIF}
      While W2 > SizeOf(LongWord) Do Begin
        pLongWord(Dst)^ := pLongWord(Src)^;
        Inc(pLongWord(Dst));
        Inc(pLongWord(Src));
        Dec(W2, SizeOf(LongWord));
      End;
      While W2 > 0 Do Begin
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

  SP_BankList[0]^.Changed := True;

End;


Function SP_StringToTexture(Const Str: aString; UseLiterals: Boolean = False): aString;
Var
  SP: Pointer;
  SW, SH, SS, Idx, Width, Height, mw: Integer;
  Surface: aString;
  Bits32: Boolean;
Begin

  // Converts a string to a texture. This way, you can convert a string of UDGs
  // or whatever text to a graphic. Returns a 32bpp graphic if the current font is
  // 32bit, otherwise returns an 8bpp graphic.

  Result := '';
  If Str <> '' Then Begin

    // First, strip out location command codes. Codes to change INK and PAPER etc are fine.
    // Also figure out how big the resulting graphic is going to be.

    mw := 0;
    Width := 0;
    Height := 1;
    Idx := 1;
    While Idx <= Length(Str) Do Begin

      Case Ord(Str[Idx]) of
        5: If UseLiterals Then Begin Result := Result + Copy(Str, Idx, 2); Inc(Idx, 2); Inc(Width); End Else Begin Result := Result + Str[Idx]; Inc(Idx); Inc(Width); End;
        6, 8, 9, 10, 11: Begin Inc(Idx); End; // PRINT comma, Cursor moves
        13: Begin Inc(Height); Result := Result + Str[Idx]; Inc(Idx); mw := Max(Width, mw); Width := 0; End; // Carriage return
       16, 17, 18, 19, 20: Begin Result := Result + Copy(Str, Idx, 5); Inc(Idx, 1 + SizeOf(LongWord)); End;
       21, 22: Begin Inc(Idx, 1+(SizeOf(LongWord) * 2)); End;
       25: Begin Result := Result + Copy(Str, Idx, 1 + (SizeOf(aFloat) * 2)); Inc(Idx, 1 + (SizeOf(aFloat) * 2)); End;
       23, 26, 27: Begin Inc(Idx, 1+SizeOf(LongWord)); End;
      Else
        Result := Result + Str[Idx];
        Inc(Width);
        Inc(Idx);
      End;

    End;
    Width := Max(mw, Width);

    // Create a "surface" that we can draw to

    Bits32 := pSP_Font_Info(@SP_BankList[FONTBANKID]^.Info[0])^.FontType = SP_FONT_TYPE_32BIT;
    If Bits32 Then
      SetLength(Surface, Round(Width * Integer(FONTWIDTH * FONTHEIGHT) * Height * T_SCALEX * T_SCALEY * SizeOf(RGBA)))
    Else
      SetLength(Surface, Round(Width * Integer(FONTWIDTH * FONTHEIGHT) * Height * T_SCALEX * T_SCALEY));

    SP := SCREENPOINTER;
    SW := SCREENWIDTH;
    SS := SCREENSTRIDE;
    SH := SCREENHEIGHT;


    SCREENPOINTER := @Surface[1];
    SCREENWIDTH := Round(Width * Integer(FONTWIDTH) * T_SCALEX);
    If Bits32 Then
      SCREENSTRIDE := Round(Width * Integer(FONTWIDTH) * SizeOf(RGBA) * T_SCALEX)
    Else
      SCREENSTRIDE := Round(Width * Integer(FONTWIDTH) * T_SCALEX);
    SCREENHEIGHT := Round(Integer(FONTHEIGHT) * Height * T_SCALEY);
    FillMem(SCREENPOINTER, Length(Surface), T_PAPER);

    T_CLIPX1 := 0; T_CLIPY1 := 0; T_CLIPX2 := SCREENWIDTH; T_CLIPY2 := SCREENHEIGHT;

    If Bits32 Then
      SP_TextOut32(-1, 0, 0, Result, T_INK, T_PAPER, True)
    Else
      SP_TextOut(-1, 0, 0, Result, T_INK, T_PAPER, False, UseLiterals);

    SCREENPOINTER := SP;
    SCREENWIDTH := SW;
    SCREENHEIGHT := SH;
    SCREENSTRIDE := SS;
    T_CLIPX1 := CCLIPX1; T_CLIPY1 := CCLIPY1; T_CLIPX2 := CCLIPX2; T_CLIPY2 := CCLIPY2;

    If Surface <> '' Then Begin
      If Bits32 Then
        Result := LongWordToString(Round(Width * Integer(FONTWIDTH) * T_SCALEX)) + LongWordToString(Round(Height * Integer(FONTHEIGHT) * T_SCALEY)) + #255 + #32 + Surface
      Else
        If T_TRANSPARENT Then
          Result := LongWordToString(Round(Width * Integer(FONTWIDTH) * T_SCALEX)) + LongWordToString(Round(Height * Integer(FONTHEIGHT) * T_SCALEY)) + aChar(T_PAPER) + #0 + Surface
        Else
          Result := LongWordToString(Round(Width * Integer(FONTWIDTH) * T_SCALEX)) + LongWordToString(Round(Height * Integer(FONTHEIGHT) * T_SCALEY)) + #255 + #255 + Surface;
    End Else
      Result := '';

  End;

End;

Function SP_FindUDG(ChrIndex: Integer; Var Error: TSP_ErrorCode): Integer;
Var
  Bank: pSP_Bank;
  FontBank: pSP_Font_Info;
Begin

  Result := 0;
  If (ChrIndex > 0) And (ChrIndex < 128) Then Begin

    Bank := SP_BankList[SP_FindBankID(FONTBANKID)];
    FontBank := @Bank^.Info[0];

    Result := FontBank^.Font_Info[ChrIndex + 128].Data;

  End Else

    Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE;

End;

Procedure SP_HScroll(Dst: pByte; Width, Height, Bpp, Amount: Integer; Wrap: Boolean);
var
  Line: Pointer;
  y, paper: Integer;
begin

  If Bpp = 8 Then Begin

    If T_INVERSE > 0 Then
      paper := T_INK
    Else
      paper := T_PAPER;

    if Amount < 0 then Begin

      Amount := Abs(Amount) Mod Width;
      GetMem(Line, Amount);

      for y:=0 to Height -1 do begin

        If Wrap Then
          CopyMem(Line,pByte(NativeInt(Dst)),Amount)
        Else
          FillMem(Line, Amount, paper);

        MoveMem(Dst, pByte(NativeInt(Dst)+(Amount)),(Width-Amount));
        CopyMem(pByte(NativeInt(Dst) + Width-Amount),Line,Amount);
        Dst := pByte(NativeInt(Dst)+Width);

      End;

    End Else Begin

      GetMem(Line,Amount);

      for y:=0 to Height -1 do begin

        If Wrap Then
          CopyMem(Line,pByte(NativeInt(Dst)+((Width-Amount))),Amount)
        Else
          FillMem(Line, Amount, paper);

        MoveMem(pByte(NativeInt(Dst)+(Amount)),Dst,(Width-Amount));
        CopyMem(Dst,Line,Amount);
        Dst := pByte(NativeInt(Dst)+Width);

      End;

    end;

    FreeMem(Line);

  End Else

    SP_HScroll32(Dst, Width, Height, Amount, Wrap);

  SP_BankList[0]^.Changed := True;

end;

procedure SP_VScroll(Dst: pByte; Width, Height, Amount: Integer; Wrap: Boolean);
var
  Buff: Pointer;
  Paper:  Integer;
begin

  If SCREENBPP = 8 Then Begin

    If T_INVERSE > 0 Then
      paper := T_INK
    Else
      paper := T_PAPER;

    GetMem(Buff, Width * Abs(Amount));

    If Amount < 0 Then Begin

      Amount := Abs(Amount);
      If Wrap Then
        CopyMem(Buff, Dst, Amount * Width)
      Else
        FillMem(Buff, Amount * Width, paper);
      MoveMem(Dst, pByte(NativeInt(Dst) + (Width * Amount)), Width * (Height - Amount));
      CopyMem(pByte(NativeInt(Dst)+(Width * (Height - Amount))), Buff, Amount * Width);

    End Else Begin

      If Wrap Then
        CopyMem(Buff, Dst + (Width * (Height - Amount)), Amount * Width)
      Else
        FillMem(Buff, Amount * Width, paper);
      MoveMem(Dst + (Width * Amount), Dst, Width * (Height - Amount));
      CopyMem(Dst, Buff, Amount * Width);

    End;

    FreeMem(Buff);

  End Else

    SP_VScroll32(Dst, Width, Height, Amount, Wrap);

  SP_BankList[0]^.Changed := True;

end;

Procedure SP_FloodFill(Dst: pByte; dX, dY, dW, dH: LongWord; Clr: Byte);
Var
  o, qStart, qCount: LongWord;
  n, w, e, EdgeW, EdgeE, Up, Down, Top, Bottom: pByte;
  Target: Byte;
Begin

  If Length(FillQueue) <> dW * dH Then
    SetLength(FillQueue, dW * dH);

  qStart := 0;
  qCount := 1;

  If (dX >= dW) or (dY >= dH) Then Exit;
  Top := Dst + (Integer(Dw) * Max(1, T_CLIPY1));
  Bottom := Dst + ((T_CLIPY2 - 1) * integer(dW));
  n := Dst + (dW * dY) + dX;
  FillQueue[0] := n;
  Target := n^;

  If Target = Clr Then Exit;

  While qCount > 0 Do Begin

    n := FillQueue[qStart];
    o := LongWord(n - Dst);
    Inc(qStart);
    Dec(qCount);

    If n^ = Target Then Begin

      w := n; e := n +1;
      EdgeW := pByte(NativeUInt(Dst) + (o - (o mod dW)) -1);
      EdgeE := EdgeW + T_CLIPX2 + 1;
      Inc(EdgeW, T_CLIPX1);

      While (w^ = Target) And (w > EdgeW) Do Begin
        w^ := Clr;
        Up := pByte(w - dW);
        Down := pByte(w + dW);
        If w >= Top Then
          If Up^ = Target Then Begin
            FillQueue[qStart+qCount] := Up;
            Inc(qCount);
          End;
        If w < Bottom Then
          If Down^ = Target Then Begin
            FillQueue[qStart+qCount] := Down;
            Inc(qCount);
          End;
        Dec(w);
      End;

      While (e^ = Target) And (e < EdgeE) Do Begin
        e^ := Clr;
        Up := pByte(e - dW);
        Down := pByte(e + dW);
        If e >= Top Then
          If Up^ = Target Then Begin
            FillQueue[qStart+qCount] := Up;
            Inc(qCount);
          End;
        If e < Bottom Then
          If Down^ = Target Then Begin
            FillQueue[qStart+qCount] := Down;
            Inc(qCount);
          End;
        Inc(e);
      End;

    End;

  End;

  SP_BankList[0]^.Changed := True;

End;

Procedure SP_TextureFill(Dst: pByte; dX, dY, dW, dH: LongWord; const Texture: aString; tW, tH: LongWord);
Var
  Target, tClr, Clr: Byte;
  X, Y, o, qStart, qCount, PixelBase: LongWord;
  n, w, e, EdgeW, EdgeE, Up, Down, Top, Bottom, TexBase: pByte;
  Trans: Word;
  Graphic: pSP_Graphic_Info;
Begin

  tClr := 0;

  // Requires texture to be in GRAB format -
  // 4 bytes width
  // 4 bytes height
  // 1 byte Transparent flag
  // 1 byte Transparent index, if flag is 0

  If Texture = '' Then Begin
    TexBase := pByte(tW);
    Graphic := pSP_Graphic_Info(tH);
    tW := Graphic.Width;
    tH := Graphic.Height;
    Trans := Graphic.Transparent;
  End Else Begin
    TexBase := @Texture[11];
    Trans := pWord(@Texture[9])^;
  End;
  If Trans <> $FFFF Then
    tClr := Trans And $FF;

  If Length(FillQueue) <> dW * dH * 2 Then
    SetLength(FillQueue, dW * dH * 2);
  ZeroMem(@FillQueue[0], dw * dh * 2 * sizeOf(Pointer));
  PixelBase := dW * dH;
  qStart := 0;
  qCount := 1;

  If (dX >= dW) or (dY >= dH) Then Exit;
  Top := Dst + (Dw * longword(Max(1, T_CLIPY1)));
  Bottom := Dst + ((T_CLIPY2 - 1) * integer(dW));
  n := Dst + (dW * dY) + dX;
  FillQueue[0] := n;
  Target := n^;

  If Trans = $FFFF Then Begin

    While qCount > 0 Do Begin

      n := FillQueue[qStart];
      o := LongWord(n - Dst);
      Inc(qStart);
      Dec(qCount);

      If n^ = Target Then Begin

        w := n; e := n +1;
        EdgeW := pByte(NativeUInt(Dst) + (o - (o mod dW)) -1);
        EdgeE := EdgeW + T_CLIPX2 + 1;
        Inc(EdgeW, T_CLIPX1);
        Y := LongWord(n - Dst) Div dW;
        X := LongWord(n - Dst) mod dw;

        While (w^ = Target) And (w > EdgeW) And (FillQueue[X+Y*dW+PixelBase] = nil) Do Begin
          w^ := pByte(TexBase + ((y Mod tH) * tW) + (x Mod tW))^;
          FillQueue[X + Y*dW + PixelBase] := pByte(1);
          Up := pByte(w - dW);
          Down := pByte(w + dW);
          If w >= Top Then
            If (Up^ = Target) And (FillQueue[X + (Y-1)*dW + PixelBase] = nil) Then Begin
              FillQueue[qStart+qCount] := Up;
              Inc(qCount);
            End;
          If w < Bottom Then
            If (Down^ = Target) And (FillQueue[X + (Y+1)*dW + PixelBase] = nil) Then Begin
              FillQueue[qStart+qCount] := Down;
              Inc(qCount);
            End;
          Dec(w);
          Dec(X);
        End;

        While (e^ = Target) And (e < EdgeE) And (FillQueue[X+Y*dW+PixelBase] = nil) Do Begin
          Y := NativeUInt(e - Dst) Div dW;
          X := NativeUInt(e - Dst) mod dw;
          e^ := pByte(TexBase + ((y Mod tH) * tW) + (x Mod tW))^;
          FillQueue[X + Y*dW + PixelBase] := pByte(1);
          Up := pByte(e - dW);
          Down := pByte(e + dW);
          If e >= Top Then
            If (Up^ = Target) And (FillQueue[X + (Y-1)*dW + PixelBase] = nil) Then Begin
              FillQueue[qStart+qCount] := Up;
              Inc(qCount);
            End;
          If e < Bottom Then
            If (Down^ = Target) And (FillQueue[X + (Y+1)*dW + PixelBase] = nil) Then Begin
              FillQueue[qStart+qCount] := Down;
              Inc(qCount);
            End;
          Inc(e);
          Inc(X);
        End;

      End;

    End;

  End Else Begin

    While qCount > 0 Do Begin

      n := FillQueue[qStart];
      o := LongWord(n - Dst);
      Inc(qStart);
      Dec(qCount);

      If n^ = Target Then Begin

        w := n; e := n +1;
        EdgeW := pByte(NativeUInt(Dst) + (o - (o mod dW)) -1);
        EdgeE := EdgeW + T_CLIPX2 + 1;
        Inc(EdgeW, T_CLIPX1);
        Y := LongWord(n - Dst) Div dW;
        X := LongWord(n - Dst) mod dw;

        While (w^ = Target) And (w > EdgeW) And (FillQueue[X+Y*dW+PixelBase] = nil) Do Begin
          Clr := pByte(TexBase + ((y Mod tH) * tW) + (x Mod tW))^;
          If Clr <> tClr Then w^ := Clr;
          FillQueue[X + Y*dW + PixelBase] := pByte(1);
          Up := pByte(w - dW);
          Down := pByte(w + dW);
          If w >= Top Then
            If (Up^ = Target) And (FillQueue[X + (Y-1)*dW + PixelBase] = nil) Then Begin
              FillQueue[qStart+qCount] := Up;
              Inc(qCount);
            End;
          If w < Bottom Then
            If (Down^ = Target) And (FillQueue[X + (Y+1)*dW + PixelBase] = nil) Then Begin
              FillQueue[qStart+qCount] := Down;
              Inc(qCount);
            End;
          Dec(w);
          Dec(X);
        End;

        While (e^ = Target) And (e < EdgeE) And (FillQueue[X+Y*dW+PixelBase] = nil) Do Begin
          Y := NativeUInt(e - Dst) Div dW;
          X := NativeUInt(e - Dst) mod dw;
          Clr := pByte(TexBase + ((y Mod tH) * tW) + (x Mod tW))^;
          If Clr <> tClr Then e^ := Clr;
          FillQueue[X + Y*dW + PixelBase] := pByte(1);
          Up := pByte(e - dW);
          Down := pByte(e + dW);
          If e >= Top Then
            If (Up^ = Target) And (FillQueue[X + (Y-1)*dW + PixelBase] = nil) Then Begin
              FillQueue[qStart+qCount] := Up;
              Inc(qCount);
            End;
          If e < Bottom Then
            If (Down^ = Target) And (FillQueue[X + (Y+1)*dW + PixelBase] = nil) Then Begin
              FillQueue[qStart+qCount] := Down;
              Inc(qCount);
            End;
          Inc(e);
          Inc(X);
        End;

      End;

    End;

  End;

  SP_BankList[0]^.Changed := True;

End;

Procedure SP_GWFloodFill(Dst: pByte; dX, dY, dW, dH: LongWord; Clr, BClr: Byte); // BClr is the boundary colour.
Var
  o, qStart, qCount: LongWord;
  n, w, e, EdgeW, EdgeE, Up, Down, Top, Bottom: pByte;
Begin

  If Length(FillQueue) <> dW * dH Then
    SetLength(FillQueue, dW * dH);

  qStart := 0;
  qCount := 1;

  If (dX >= dW) or (dY >= dH) Then Exit;
  Top := Dst + (Integer(Dw) * Max(1, T_CLIPY1));
  Bottom := Dst + ((T_CLIPY2 - 1) * integer(dW));
  n := Dst + (dW * dY) + dX;
  FillQueue[0] := n;

  If BClr = Clr Then Exit;

  While qCount > 0 Do Begin

    n := FillQueue[qStart];
    o := LongWord(n - Dst);
    Inc(qStart);
    Dec(qCount);

    If (n^ <> BClr) And (n^ <> Clr) Then Begin

      w := n; e := n +1;
      EdgeW := pByte(NativeUInt(Dst) + (o - (o mod dW)) -1);
      EdgeE := EdgeW + T_CLIPX2 + 1;
      Inc(EdgeW, T_CLIPX1);

      While (w^ <> BClr) And (w^ <> Clr) And (w > EdgeW) Do Begin
        w^ := Clr;
        Up := pByte(w - dW);
        Down := pByte(w + dW);
        If w >= Top Then
          If (Up^ <> BClr) And (Up^ <> Clr) Then Begin
            FillQueue[qStart+qCount] := Up;
            Inc(qCount);
          End;
        If w < Bottom Then
          If (Down^ <> BClr) And (Down^ <> Clr) Then Begin
            FillQueue[qStart+qCount] := Down;
            Inc(qCount);
          End;
        Dec(w);
      End;

      While (e^ <> BClr) And (e^ <> Clr) And (e < EdgeE) Do Begin
        e^ := Clr;
        Up := pByte(e - dW);
        Down := pByte(e + dW);
        If e >= Top Then
          If (Up^ <> BClr) And (Up^ <> Clr) Then Begin
            FillQueue[qStart+qCount] := Up;
            Inc(qCount);
          End;
        If e < Bottom Then
          If (Down^ <> BClr) And (Down^ <> Clr) Then Begin
            FillQueue[qStart+qCount] := Down;
            Inc(qCount);
          End;
        Inc(e);
      End;

    End;

  End;

  SP_BankList[0]^.Changed := True;

End;

//  based on code by Darel Rex Finley, 2007

Procedure SP_PolygonFill(Var Points: Array of TSP_Point; const TextureStr: aString; tW, tH: LongWord);
Var
  MinY, MaxY, MinX, MaxX, Idx, I, J, Nodes, NumPoints, PixelY: Integer;
  NodeX: Array of Integer;
  Ptr, TexBase: pByte;
  Ink, tClr: Byte;
  Trans: Word;
  Graphic: pSP_Graphic_Info;
Begin

  tClr := 0;

  If TextureStr = '' Then Begin
    TexBase := pByte(tW);
    Graphic := pSP_Graphic_Info(tH);
    tW := Graphic.Width;
    tH := Graphic.Height;
    Trans := Graphic.Transparent;
  End Else Begin
    TexBase := @TextureStr[11];
    Trans := pWord(@TextureStr[9])^;
  End;
  If Trans <> $FFFF Then
    tClr := Trans And $FF;

  NumPoints := Length(Points);
  SetLength(NodeX, NumPoints);
  Idx := NumPoints -1;
  MinY := 32768;
  MaxY := -32768;
  MinX := 32768;
  MaxX := -32768;

  While Idx >= 0 Do Begin

    Points[Idx].X := Round(Points[Idx].X);
    Points[Idx].Y := Round(Points[Idx].Y);
    If Points[Idx].Y < MinY then MinY := Round(Points[Idx].Y);
    If Points[Idx].Y > MaxY then MaxY := Round(Points[Idx].Y);
    If Points[Idx].X < MinX then MinX := Round(Points[Idx].X);
    If Points[Idx].X > MaxX then MaxX := Round(Points[Idx].X);
    Dec(Idx);

  End;

  MaxY := Min(MaxY, T_CLIPY2 -1);
  MaxX := Min(MaxX, T_CLIPX2 -1);
  MinY := Max(MinY, T_CLIPY1);
  MinX := Max(MinX, T_CLIPX1);

  If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + MinX, SCREENY + MinY, SCREENX + MaxX, SCREENY + MaxY);

  For PixelY := MinY to MaxY Do Begin

    Nodes := 0;
    J := NumPoints -1;
    For I := 0 To NumPoints -1 Do Begin
      If (Points[I].Y < PixelY) And (Points[J].Y >= PixelY) or (Points[J].Y < PixelY) And (Points[I].Y >= PixelY) Then Begin
        NodeX[Nodes] := Round(Points[I].X + (PixelY-Points[I].Y)/(Points[J].Y-Points[I].Y)*(Points[J].X-Points[I].X));
        Inc(Nodes);
      End;
      J := I;
    End;

    I := 0;
    While I < Nodes -1 Do
      If NodeX[I] > NodeX[I+1] Then Begin
        NodeX[I] := NodeX[I] Xor NodeX[I+1]; NodeX[I+1] := NodeX[I] Xor NodeX[I+1]; NodeX[I] := NodeX[I] Xor NodeX[I+1];
        If I > 0 Then Dec(I);
      End Else
        Inc(I);

    If Trans = $FFFF Then Begin

      I := 0;
      While I < Nodes Do Begin
        If NodeX[I] >= T_CLIPX2 Then Break;
        If NodeX[I+1] > T_CLIPX1 Then Begin
          If NodeX[I] < T_CLIPX1 Then NodeX[I] := T_CLIPX1;
          If NodeX[I+1] >= T_CLIPX2 Then NodeX[I+1] := T_CLIPX2;
          Ptr := SCREENPOINTER;
          Inc(Ptr, ((PixelY * SCREENSTRIDE) + NodeX[I]));
          For J := NodeX[I] To NodeX[I+1] -1 Do Begin
            Ink := pByte(TexBase + ((LongWord(PixelY) Mod tH) * tW) + (LongWord(J) Mod tW))^;
            IF T_OVER = 0 Then
              Ptr^ := Ink
            Else
              SP_OverPixelPtrVal(Ptr, Ink, T_OVER);
            Inc(Ptr);
          End;
        End;
        Inc(I, 2);
      End;

    End Else Begin

      I := 0;
      While I < Nodes Do Begin
        If NodeX[I] >= T_CLIPX2 Then Break;
        If NodeX[I+1] > T_CLIPX1 Then Begin
          If NodeX[I] < T_CLIPX1 Then NodeX[I] := T_CLIPX1;
          If NodeX[I+1] >= T_CLIPX2 Then NodeX[I+1] := T_CLIPX2;
          Ptr := SCREENPOINTER;
          Inc(Ptr, ((PixelY * SCREENSTRIDE) + NodeX[I]));
          For J := NodeX[I] To NodeX[I+1] -1 Do Begin
            Ink := pByte(TexBase + ((LongWord(PixelY) Mod tH) * tW) + (LongWord(J) Mod tW))^;
            If Ink <> tClr Then
              IF T_OVER = 0 Then
                Ptr^ := Ink
              Else
                SP_OverPixelPtrVal(Ptr, Ink, T_OVER);
            Inc(Ptr);
          End;
        End;
        Inc(I, 2);
      End;

    End;

  End;

  SP_BankList[0]^.Changed := True;

End;

Procedure SP_PolygonSolidFill(Var Points: Array of TSP_Point);
Var
  Idx, I, J, Nodes, NumPoints, PixelY: Integer;
  MinY, MaxY, MinX, MaxX: Integer;
  NodeX: Array of Integer;
  Ptr: pByte;
  Ink: Byte;
Begin

  If T_INVERSE = 1 Then
    Ink := T_PAPER
  Else
    Ink := T_INK;

  NumPoints := Length(Points);

  Idx := NumPoints -1;
  MinY := 32768;
  MaxY := -32768;
  MinX := 32768;
  MaxX := -32768;

  While Idx >= 0 Do Begin

    Points[Idx].X := Round(Points[Idx].X);
    Points[Idx].Y := Round(Points[Idx].Y);
    If Points[Idx].Y < MinY then MinY := Round(Points[Idx].Y);
    If Points[Idx].Y > MaxY then MaxY := Round(Points[Idx].Y);
    If Points[Idx].X < MinX then MinX := Round(Points[Idx].X);
    If Points[Idx].X > MaxX then MaxX := Round(Points[Idx].X);
    Dec(Idx);

  End;

  MaxY := Min(MaxY, T_CLIPY2 -1);
  MaxX := Min(MaxX, T_CLIPX2 -1);
  MinY := Max(MinY, T_CLIPY1);
  MinX := Max(MinX, T_CLIPX1);

  If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + MinX, SCREENY + MinY, SCREENX + MaxX, SCREENY + MaxY);

  If SCREENBPP = 8 Then Begin

    // First run through - horizontal scanlines

    SetLength(NodeX, NumPoints);

    For PixelY := MinY to MaxY Do Begin

      Nodes := 0;
      J := NumPoints -1;
      For I := 0 To NumPoints -1 Do Begin
        If (Points[I].Y < PixelY) And (Points[J].Y >= PixelY) or (Points[J].Y < PixelY) And (Points[I].Y >= PixelY) Then Begin
          NodeX[Nodes] := Round(Points[I].X + (PixelY-Points[I].Y)/(Points[J].Y-Points[I].Y)*(Points[J].X-Points[I].X));
          Inc(Nodes);
        End;
        J := I;
      End;

      I := 0;
      While I < Nodes -1 Do
        If NodeX[I] > NodeX[I+1] Then Begin
          NodeX[I] := NodeX[I] Xor NodeX[I+1]; NodeX[I+1] := NodeX[I] Xor NodeX[I+1]; NodeX[I] := NodeX[I] Xor NodeX[I+1];
          If I > 0 Then Dec(I);
        End Else
          Inc(I);

      I := 0;
      While I < Nodes -1 Do Begin
        If NodeX[I] >= T_CLIPX2 Then Break;
        If NodeX[I+1] > T_CLIPX1 Then Begin
          If NodeX[I] < T_CLIPX1 Then NodeX[I] := T_CLIPX1;
          If NodeX[I+1] >= T_CLIPX2 Then NodeX[I+1] := T_CLIPX2 -1;
          Ptr := SCREENPOINTER;
          Inc(Ptr, ((Round(PixelY) * SCREENSTRIDE) + NodeX[I]));
          For J := NodeX[I] To NodeX[I+1] Do Begin
            IF T_OVER = 0 Then
              Ptr^ := Ink
            Else
              SP_OverPixelPtrVal(Ptr, Ink, T_OVER);
            Inc(Ptr);
          End;
        End;
        Inc(I, 2);
      End;

    End;

    DRPOSX := Points[0].X;
    DRPOSY := Points[0].Y;
    For Idx := 1 To NumPoints -1 Do
      SP_DrawLine(Points[Idx].X - DRPOSX, Points[Idx].Y - DRPOSY);
    SP_DrawLine(Points[0].X - DRPOSX, Points[0].Y - DRPOSY);
{
    // Now run through with vertical lines - to catch the edge cases which this algorithm can't handle.

    For PixelY := MinX to MaxX Do Begin

      Nodes := 0;
      J := NumPoints -1;
      For I := 0 To NumPoints -1 Do Begin
        If (Points[I].X < PixelY) And (Points[J].X >= PixelY) or (Points[J].X < PixelY) And (Points[I].X >= PixelY) Then Begin
          NodeX[Nodes] := Round(Points[I].Y + (PixelY-Points[I].X)/(Points[J].X-Points[I].X)*(Points[J].Y-Points[I].Y));
          Inc(Nodes);
        End;
        J := I;
      End;

      I := 0;
      While I < Nodes -1 Do
        If NodeX[I] > NodeX[I+1] Then Begin
          Swap := NodeX[I]; NodeX[I] := NodeX[I+1]; NodeX[I+1] := Swap; If I > 0 Then Dec(I);
        End Else
          Inc(I);

      I := 0;
      While I < Nodes -1 Do Begin
        If NodeX[I] >= T_CLIPY2 Then Break;
        If NodeX[I+1] > T_CLIPY1 Then Begin
          If NodeX[I] < T_CLIPY1 Then NodeX[I] := T_CLIPY1;
          If NodeX[I+1] >= T_CLIPY2 Then NodeX[I+1] := T_CLIPY2 -1;
          Ptr := SCREENPOINTER;
          Inc(Ptr, (NodeX[I] * SCREENSTRIDE) + PixelY);
          For J := NodeX[I] To NodeX[I+1] -1 Do Begin
            IF T_OVER = 0 Then
              Ptr^ := Ink
            Else
              SP_OverPixelPtrVal(Ptr, Ink, T_OVER);
            Inc(Ptr, SCREENSTRIDE);
          End;
        End;
        Inc(I,2);
      End;

    End;
}

  End Else

    SP_PolygonSolidFill32(Points, MinX, MinY, MaxX, MaxY, Ink);

  SP_BankList[0]^.Changed := True;

End;

Procedure SP_CopyRect(SrcPtr: pByte; SrcW, SrcH, SrcRx, SrcRy, SrcRw, SrcRh: Integer; DstPtr: pByte; DstW, DstH, DstX, DstY, DcW, DcH, cx1, cy1, cx2, cy2: Integer; Var Error: TSP_ErrorCode);
Var
  BuffPtr, dPtr, sPtr, SLPtr: pLongWord;
  bdPtr, bsPtr: pByte;
  BuffW, W, H, Sx, Sy, X, Y, Xp, Yp, Bx, By, Bw, Bh: Integer;
  rH, rV: aFloat;
Begin

  // A lot of checks to do in this, due to the scaling. First, test to see if the source rect fits the source
  // surface and clip if necessary.

  rH := DcW/SrcRw; rV := DcH/SrcRh;

  If SrcRx < 0 Then Begin
    Inc(SrcRw, SrcRx);
    Inc(DstX, -Trunc(SrcRx * rH));
    DcW := Trunc(SrcRw * rH);
    SrcRx := 0;
  End;

  If SrcRx + SrcRw > SrcW Then Begin
    SrcRw := SrcRw - ((SrcRx + SrcRw) - SrcW);
    DcW := Trunc(SrcRw * rH);
  End;

  If SrcRy < 0 Then Begin
    Inc(SrcRh, SrcRy);
    Inc(DstY, -Trunc(SrcRy * rV));
    DcH := Trunc(SrcRh * rV);
    SrcRy := 0;
  End;

  If SrcRy + SrcRh > SrcH Then Begin
    SrcRh := SrcRh - ((SrcRy + SrcRh) - SrcH);
    DcH := Trunc(SrcRh * rV);
  End;

  If (SrcRw = 0) or (SrcRh = 0) Then Begin
    Error.Code := SP_ERR_INVALID_REGION;
    Exit;
  End;

  // Next check if the destination rectangle will fit into to the destination surface, and if not then
  // recalculate it, changing the source rectangle to fit. Similar calculations will need to be done later
  // as it could still be out of bounds - just not as badly as it could potentially be here.

  If DstX < Cx1 Then Begin
    Bx := SrcRx;
    Inc(SrcRx, Trunc((Cx1 - DstX) / rH));
    Inc(SrcRw, Trunc(DstX /rH));
    DcW := Trunc(SrcRw * rH);
    Inc(DstX, SrcRx - Bx);
  End;

  If DstX + DcW >= Cx2 Then Begin
    Inc(SrcRw, -Trunc(((DstX + DcW) - Cx2) / rH));
    DcW := Trunc(SrcRw * rH);
  End;

  If DstY < Cy1 Then Begin
    By := SrcRy;
    Inc(SrcRy, Trunc(Cy1 - DstY / rV));
    Inc(SrcRh, Trunc(DstY /rV));
    DcH := Trunc(SrcRh * rV);
    Inc(DstY, Trunc((SrcRy - By) * rV));
  End;

  If DstY + DcH >= Cy2 Then Begin
    Inc(SrcRh, -Trunc(((DstY + DcH) - Cy2) / rV));
    DcH := Trunc(SrcRh * rV);
  End;

  // Now stretch or copy to a temporary buffer - this ensures that the source isn't overwritten by the
  // blit if the destination is the same surface.

  H := SrcRh;
  If gBuffLen <> DcW * DcH Then Begin
    gBuffLen := DcW * DcH;
    If gBuffLen > 0 Then
      SetLength(gBuffer, DcW * DcH)
    Else Begin
      Error.Code := SP_ERR_INVALID_REGION;
      Exit;
    End;
  End;
  BuffPtr := pLongWord(@gBuffer[0]);
  BuffW := DcW;

  Inc(SrcPtr, (SrcW * SrcRy) + SrcRx);

  If (DcW = SrcRw) and (DcH = SrcRh) Then Begin

    // Destination and source are the same size

    While H > 0 Do Begin

      W := SrcRw;
      {$IFDEF CPU64}
      While W > SizeOf(NativeUInt) Do Begin
        pNativeUInt(BuffPtr)^ := pNativeUInt(SrcPtr)^;
        Inc(pNativeUInt(BuffPtr));
        Inc(SrcPtr, SizeOf(NativeUInt));
        Dec(W, SizeOf(NativeUInt));
      End;
      {$ENDIF}
      While W > SizeOf(LongWord) Do Begin
        BuffPtr^ := pLongWord(SrcPtr)^;
        Inc(BuffPtr);
        Inc(SrcPtr, SizeOf(LongWord));
        Dec(W, SizeOf(LongWord));
      End;
      While W > 0 Do Begin
        pByte(BuffPtr)^ := SrcPtr^;
        Inc(pByte(BuffPtr));
        Inc(SrcPtr);
        Dec(W);
      End;
      Dec(H);
      Inc(SrcPtr, SrcW - SrcRw);

    End;

  End Else Begin

    // Scaled destination

    Sx := (SrcRW shl 16) div DcW;
    Sy := (SrcRH shl 16) div DcH;
    Yp := 0;

    for Y := 0 to DcH -1 do begin
      SLPtr := pLongWord(NativeUInt(SrcPtr) + (yp Shr 16) * SrcW);
      Xp := 0;
      for X := 0 to DcW -1 do begin
        pByte(BuffPtr)^ := pByte(NativeUInt(SLPtr)+ (Xp shr 16))^;
        Inc(pByte(BuffPtr));
        Inc(Xp, Sx);
      end;
      Inc(Yp, Sy);
    end;

  End;

  BuffPtr := @gBuffer[0];

  // Now clip to the destination window - scaling means that we might still be fractionally
  // too big, despite the earlier checks! Don't worry, this is desirable :)

  Bx := 0; By := 0; Bw := DcW; Bh := DcH;

  If DstX < Cx1 Then Begin
    Inc(Bw, Cx1 - DstX);
    Bx := Cx1 - DstX;
    DstX := 0;
  End;

  If DstY < Cy1 Then Begin
    Inc(Bh, Cy1 - DstY);
    By := Cy1 - DstY;
    DstY := 0;
  End;

  If DstX + Bw >= Cx2 Then
    Inc(Bw, -(DstX + Bw - Cx2));

  If DstY + Bh >= Cy2 Then
    Inc(Bh, -(DstY + Bh - Cy2));

  DPtr := pLongWord(NativeInt(DstPtr) + (DstY * DstW) + DstX);
  SPtr := pLongWord(NativeInt(BuffPtr) + Bx + (By * BuffW));

  If COVER = 0 Then Begin

    While Bh > 0 Do Begin

      W:= Bw;
      {$IFDEF CPU64}
      While W > SizeOf(NativeUInt) Do Begin
        pNativeUInt(dPtr)^ := pNativeUInt(sPtr)^;
        Inc(pNativeUInt(sPtr));
        Inc(pNativeUint(dPtr));
        Dec(W, SizeOf(NativeUInt));
      End;
      {$ENDIF}
      While W > SizeOf(LongWord) Do Begin
        dPtr^ := sPtr^;
        Inc(sPtr);
        Inc(dPtr);
        Dec(W, SizeOf(LongWord));
      End;
      While W > 0 Do Begin
        pByte(dPtr)^ := pByte(sPtr)^;
        Inc(pByte(sPtr));
        Inc(pByte(dPtr));
        Dec(W);
      End;

      Inc(pByte(sPtr), BuffW - Bw);
      Inc(pByte(dPtr), DstW - Bw);
      Dec(Bh);

    End;

  End Else

    While DcH > 0 Do Begin

      W:= DcW;
      While W > SizeOf(LongWord) Do Begin
        SP_OverPixelPtrl(dPtr, sPtr, T_OVER);
        Inc(sPtr);
        Inc(dPtr);
        Dec(W, SizeOf(LongWord));
      End;
      bdPtr := pByte(dPtr);
      bsPtr := pByte(sPtr);
      While W > 0 Do Begin
        SP_OverPixelPtr(bdPtr, bsPtr, T_OVER);
        Inc(bsPtr);
        Inc(bdPtr);
        Dec(W);
      End;

      dPtr := pLongWord(bdPtr);
      sPtr := pLongWord(bsPtr);
      Inc(pByte(sPtr), BuffW - DcW);
      Inc(pByte(dPtr), DstW - DcW);
      Dec(DcH);

    End;

  SP_BankList[0]^.Changed := True;

End;

Procedure SP_SavePalette(const Filename: aString; Var Error: TSP_ErrorCode);
Var
  FileID: Integer;
Const
  BankIDStr: aString = 'ZXPALETTE';
Begin

  FileID := SP_FileOpen(Filename, True, Error);
  If FileID > -1 Then Begin
    SP_FileWrite(FileID, @BankIDStr[1], Length(BankIDStr), Error);
    SP_FileWrite(FileID, @pSP_Window_Info(WINDOWPOINTER)^.Palette[0], SizeOf(TP_Colour) * 256, Error);
    SP_FileClose(FileID, Error);
  End Else Begin
    ERRStr := Filename;
    Error.Code := SP_ERR_SAVE_OPEN_ERROR;
  End;

End;

Procedure SP_LoadPalette(const Filename: aString; Var Error: TSP_ErrorCode);
Var
  Idx, FileID: Integer;
  tBuf: aString;
  Magic: Array of Byte;
Begin

  ERRStr := Filename;
  FileID := SP_FileOpen(Filename, False, Error);

  If FileID > -1 Then Begin

    tBuf := '';
    SetLength(Magic, 9);
    SP_FileRead(FileID, @Magic[0], 9, Error);
    For Idx := 0 To 8 Do tBuf := tBuf + aChar(Magic[Idx]);
    If tBuf = 'ZXPALETTE' Then Begin

      SP_FileRead(FileID, @pSP_Window_Info(WINDOWPOINTER)^.Palette[0], 256 * SizeOf(TP_Colour), Error);
      SP_FileClose(FileID, Error);
      SP_SetPalette(0, pSP_Window_Info(WINDOWPOINTER)^.Palette);

    End Else Begin

      Error.Code := SP_ERR_NOT_PALETTE_FILE;
      SP_FileClose(FileID, Error);

    End;

  End Else

    Error.Code := SP_ERR_FILE_MISSING;

End;

Function SP_PRINT(BankID, X, Y, CPos: Integer; const Text: aString; Ink, Paper: Integer; var Error: TSP_ErrorCode): Integer;
Var
  CharW, CharH, Idx, Scrolls, cCount, OVER, sx, sy, TInk, TPaper, ItalicOffset, nx: Integer;
  yp, xp, Cw, Ch, TC, t: Integer;
  Transparent, ForceNextChar: Boolean;
  FontBank: pSP_Font_info;
  Bank: pSP_Bank;
  Coord, Char, pIdx, lIdx: pByte;
  IsScaled, SkipNextPaper, SwapBack: Boolean;
  ScaleX, ScaleY: aFloat;
  Info: TSP_iInfo;
  pInfo: pSP_iInfo;
Begin

  Result := 0;
  Scrolls := 0;
  SwapBack := False;
  ForceNextChar := False;

  If OUTSET Then Begin

    Info.Error := @Error;
    pInfo := @Info;
    OUTBUFFER := OUTBUFFER + Text;
    SP_FlushOUTBuffer(pInfo);

  End Else Begin

    If T_INVERSE <> 0 Then Begin
      Idx := Ink;
      Ink := Paper;
      Paper := Idx;
    End;
    TInk := Ink; TPaper := Paper;
    OVER := T_OVER;
    ScaleX := T_SCALEX;
    ScaleY := T_SCALEY;

    If BankID = -1 Then // Use the system font?
      BankID := FONTBANKID;

    Idx := SP_FindBankID(BankID);
    If Idx <> SP_ERR_BANK_ID_NOT_FOUND Then Begin

      Bank := SP_BankList[Idx];
      FontBank := @Bank^.Info[0];
      IsScaled := (ScaleX <> 1) Or (ScaleY <> 1);
      CharW := Max(1, Round(FONTWIDTH * ScaleX));
      CharH := Max(1, Round(FONTHEIGHT * ScaleY));
      Cw := CharW;
      Ch := CharH;
      If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
        Transparent := (FontBank^.Transparent <> $FFFF);
        TC := FontBank^.Transparent And $FF;
      End Else Begin
        Transparent := T_TRANSPARENT;
        TC := 0;
      End;

      Idx := 1;
      Scrolls := 0;
      While Idx <= Length(Text) Do Begin

        If (CPos >= Idx) And (Text[Idx] >= ' ') Then Begin
          CURSORX := X;
          CURSORY := Y;
          CURSORCHAR := Byte(Text[Idx]);
          If CURSORX >= SCREENWIDTH - 2 - CharW Then Begin
            Inc(CURSORY, CharH);
            If SYSTEMSTATE = SS_INPUT Then
              CURSORX := 0
            Else
              CURSORX := 2;
          End;
        End;

        If (Text[Idx] >= ' ') or (ForceNextChar) Then Begin

          ForceNextChar := False;
          Char := @Bank^.Memory[FontBank^.Font_Info[Byte(Text[Idx])].Data];

          If X + Cw > SCREENWIDTH Then Begin
            X := 0;
            Inc(Y, Ch);
          End;

          While Y + Ch -1 >= SCREENHEIGHT Do Begin
            If Not SP_TestScroll(Ch, Error) Then Begin
              Result := SP_ERR_PRINT_ABANDONED;
              Exit;
            End;
            Dec(Y, Ch);
            Inc(Scrolls);
          End;

          If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X, SCREENY + Y, SCREENX + X + Cw, SCREENY + Y + Ch);

          If T_ITALIC > 0 Then
            ItalicOffset := (65536 Div ItalicScale) + (CharH Div ItalicScale) Shl 16
          Else
            ItalicOffset := 0;
          Coord := SCREENPOINTER;
          Inc(Coord, (SCREENSTRIDE * Y) + X);
          Inc(Coord, ItalicOffset Shr 16);
          if T_ITALIC > 0 Then Dec(Coord, ItalicScale Div 2);

          If SwapBack Then Begin
            Ink := TInk; Paper := TPaper;
          End;
          If (CPos = Idx) And (SYSTEMSTATE = SS_INPUT) Then Begin
            TInk := Ink; TPaper := Paper;
            If FLASHSTATE = 0 Then Begin
              Ink := CURSORFG; Paper := CURSORBG;
            End Else Begin
              Ink := CURSORBG; Paper := CURSORFG;
            End;
            SwapBack := True;
          End;
          If (X >= T_CLIPX1) And (X + Cw -1 < T_CLIPX2) And (Y >= T_CLIPY1) And (Y + Ch -1 < T_CLIPY2) Then Begin
            If IsScaled Then Begin
              // Scaled character
              sx := (FONTWIDTH Shl 16) Div CharW;
              sy := (FONTHEIGHT Shl 16) Div CharH;
              yp := 0;
              While CharH > 0 Do Begin
                pIdx := Char;
                xp := 0;
                Inc(pIdx, FONTWIDTH * (yp Shr 16));
                SkipNextPaper := False;
                While CharW > 0 Do Begin
                  If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                    If Transparent Then Begin
                      lIdx := pByte(NativeUInt(pIdx) + (xp Shr 16));
                      If lIdx^ <> TC Then
                        If Over > 0 Then Begin
                          SP_OverPixelPtr(Coord, lIdx, T_OVER)
                        End Else
                          Coord^ := lIdx^;
                    End Else
                      If Over > 0 Then Begin
                        lIdx := pByte(NativeUInt(pIdx) + (xp Shr 16));
                        SP_OverPixelPtr(Coord, lIdx, T_OVER)
                      End Else
                        Coord^ := pByte(NativeUInt(pIdx) + (xp Shr 16))^;
                  End Else
                    If Over > 0 Then Begin
                      If pByte(NativeUInt(pIdx) + (xp Shr 16))^ = 1 Then Begin
                        SP_OverPixelPtrVal(Coord, Ink, T_OVER);
                        If (T_BOLD > 0) And (X+1 < T_CLIPX2) Then Begin
                          SP_OverPixelPtrVal(pByte(NativeUInt(Coord)+1), Ink, T_OVER);
                          SkipNextPaper := True;
                        End;
                      End Else
                        If Not Transparent And Not SkipNextPaper Then
                          SP_OverPixelPtrVal(Coord, Paper, T_OVER)
                        Else
                          SkipNextPaper := False;
                    End Else
                      If pByte(NativeUInt(pIdx) + (xp Shr 16))^ = 1 Then Begin
                        Coord^ := Ink;
                        If (T_BOLD > 0) And (X+1 < T_CLIPX2) Then Begin
                          pByte(NativeUInt(Coord)+1)^ := Ink;
                          SkipNextPaper := True;
                        End;
                      End Else
                        If Not Transparent And Not SkipNextPaper Then
                          Coord^ := Paper
                        Else
                          SkipNextPaper := False;
                  Inc(Coord);
                  Inc(xp, sx);
                  Dec(CharW);
                End;
                CharW := Cw;
                Inc(Coord, SCREENSTRIDE - (cW + (ItalicOffset Shr 16)));
                If T_ITALIC > 0 Then Dec(ItalicOffset, 65536 Div ITALICSCALE);
                If ItalicOffset < 0 Then ItalicOffset := 0;
                Inc(Coord, ItalicOffset Shr 16);
                Dec(CharH);
                Inc(yp, sy);
              End;
              CharH := Ch;
              Inc(X, CharW);
            End Else Begin
              While CharH > 0 Do Begin
                SkipNextPaper := False;
                While CharW > 0 Do Begin
                    If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                      If Transparent Then Begin
                        If Char^ <> TC Then
                          If Over > 0 Then
                            SP_OverPixelPtr(Coord, Char, T_OVER)
                          Else
                            Coord^ := Char^;
                      End Else
                        If Over > 0 Then
                          SP_OverPixelPtr(Coord, Char, T_OVER)
                        Else
                          Coord^ := Char^;
                    End Else
                      If Over > 0 Then Begin
                        If Char^ = 1 Then Begin
                          SP_OverPixelPtrVal(Coord, Ink, T_OVER);
                          If (T_BOLD > 0) And (X+1 < T_CLIPX2) Then Begin
                            SP_OverPixelPtrVal(pByte(NativeUInt(Coord)+1), Ink, T_OVER);
                            SkipNextPaper := True;
                          End;
                        End Else
                          If Not Transparent And Not SkipNextPaper Then
                            SP_OverPixelPtrVal(Coord, Paper, T_OVER)
                          Else
                            SkipNextPaper := False;
                      End Else
                        If Char^ = 1 Then Begin
                          Coord^ := Ink;
                          If (T_BOLD > 0) And (X+1 < T_CLIPX2) Then Begin
                            pByte(NativeUInt(Coord)+1)^ := Ink;
                            SkipNextPaper := True;
                          End;
                        End Else
                          If Not Transparent And Not SkipNextPaper Then
                            Coord^ := Paper
                          Else
                            SkipNextPaper := False;
                  Inc(Coord);
                  Inc(Char);
                  Inc(X);
                  Dec(CharW);
                End;
                Inc(Y);
                CharW := FontBank^.Width;
                Dec(X, CharW);
                Inc(Coord, SCREENSTRIDE - (CharW + (ItalicOffset Shr 16)));
                If T_ITALIC > 0 Then Dec(ItalicOffset, 65536 Div ITALICSCALE);
                If ItalicOffset < 0 Then ItalicOffset := 0;
                Inc(Coord, ItalicOffset Shr 16);
                Dec(CharH);
              End;
              CharH := FontBank^.Height;
              Dec(Y, CharH);
              Inc(X, CharW);
            End;
          End Else
            Inc(X, CharW);
        End Else Begin
          // Control codes!
          Case Ord(Text[Idx]) of
            5:
              Begin // Literal character - for characters lower than Space. The next char should be PRINTed regardless.
                ForceNextChar := True;
              End;
            6:
              Begin // PRINT comma
                nx := X + (TABSIZE * Cw);
                nx := Round(nX / (TABSIZE * Cw)) * (TABSIZE * Cw);
                SP_TextOut(-1, X, Y, StringOfChar(aChar(' '), ((nx - x) Div Cw) +1), Ink, Paper, True);
                X := nx;
              End;
            8:
              Begin // Cursor Left
                X := (X - Cw) Mod SCREENWIDTH;
              End;
            9:
              Begin // Cursor right
                SP_TextOut(-1, X, Y, aString(' '), Ink, Paper, True);
                X := (X + Cw) Mod SCREENWIDTH;
              End;
           10:
              Begin // Cursor down
                Inc(Y, Ch);
              End;
           11:
              Begin // Cursor Up
                Dec(Y, Ch);
                If Y < 0 Then Y := 0;
              End;
           13:
              Begin // Carriage return
                X := 0;
                Inc(Y, Ch);
              End;
           16:
              Begin // INK control
                T_INK := pLongWord(@Text[Idx+1])^ And $FF;
                Ink := T_INK;
                Inc(Idx, SizeOf(LongWord));
              End;
           17:
              Begin // PAPER control
                T_PAPER := pLongWord(@Text[Idx+1])^ And $FF;
                Paper := T_PAPER;
                Inc(Idx, SizeOf(LongWord));
              End;
           18:
              Begin // OVER control
                T_OVER := pLongWord(@Text[Idx+1])^;
                OVER := T_OVER;
                Inc(Idx, SizeOf(LongWord));
              End;
           19:
              Begin // TRANSPARENT control
                t := pLongWord(@Text[Idx+1])^;
                If t <> 8 Then Begin
                  T_TRANSPARENT := t > 0;
                  If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                    Transparent := T_TRANSPARENT And (FontBank^.Transparent <> $FFFF);
                    TC := FontBank^.Transparent And $FF;
                  End Else
                    Transparent := T_TRANSPARENT;
                End;
                Inc(Idx, SizeOf(LongWord));
              End;
           20:
              Begin // INVERSE control
                t := pLongWord(@Text[Idx+1])^;
                If t <> 8 Then
                  If t <> 0 Then Begin
                    Ink := T_PAPER;
                    Paper := T_INK;
                  End Else Begin
                    Ink := T_INK;
                    Paper := T_PAPER;
                  End;
                Inc(Idx, SizeOf(LongWord));
              End;
           21:
              Begin // MOVE control
                X := pInteger(@Text[Idx+1])^;
                Inc(Idx, SizeOf(Integer));
                Y := pInteger(@Text[Idx+1])^;
                If WINFLIPPED Then Y := (SCREENHEIGHT - 1) - Y;
                Inc(Idx, SizeOf(Integer));
                SP_ConvertToOrigin_i(X, Y);
              End;
           22:
              Begin // AT control
                X := 0; Y := 0;
                SP_ConvertToOrigin_i(X, Y);
                Inc(Y, pInteger(@Text[Idx+1])^ * Ch);
                Inc(Idx, SizeOf(Integer));
                Inc(X, pInteger(@Text[Idx+1])^ * Cw);
                Inc(Idx, SizeOf(Integer));
              End;
           23:
              Begin // TAB control
                nx := X Div Cw;
                tc := pInteger(@Text[Idx+1])^ mod (SCREENWIDTH Div Cw);
                If tc < nx Then Inc(tc, SCREENWIDTH Div Cw);
                SP_PRINT(-1, X, Y, -1, StringOfChar(aChar(' '), tc - nx), Ink, Paper, Error);
                X := Round(PRPOSX);
                Y := ROUND(PRPOSY);
                Inc(Idx, SizeOf(LongWord));
              End;
           24:
              Begin // CENTRE control
                Y := 0;
                SP_ConvertToOrigin_i_y(Y);
                Inc(Y, pInteger(@Text[Idx+1])^ * Ch);
                Inc(Idx, SizeOf(Integer) +1);
                pIdx := pByte(@Text[Idx]);
                lIdx := pIdx + Length(Text) - Idx;
                cCount := 0;
                While not (pIdx^ in [6..11, 13]) and (pIdx <= lIdx) Do Begin
                  Case pIdx^ Of
                    16..20, 26, 27:
                      Begin
                        Inc(pIdx, SizeOf(LongWord));
                      End;
                    21..22:
                      Begin
                        Inc(pIdx, 2 * SizeOf(Integer));
                      End;
                    23..24:
                      Begin
                        Inc(pIdx, SizeOf(Integer));
                      End;
                    25:
                      Begin
                        Inc(pIdx, SizeOf(aFloat) * 2);
                      End;
                    32..255:
                      Begin
                        Inc(cCount);
                      End;
                  End;
                  Inc(pIdx);
                End;
                X := (SCREENWIDTH - (cCount * Cw)) Div 2;
                Dec(Idx);
              End;
           25:
              Begin // SCALE control
                ScaleX := gaFloat(@Text[Idx+1]);
                Inc(Idx, SizeOf(aFloat));
                ScaleY := gaFloat(@Text[Idx+1]);
                Inc(Idx, SizeOf(aFloat));
                IsScaled := (ScaleX <> 1) Or (ScaleY <> 1);
                If (ScaleX < 0) or (ScaleY < 0) Then Begin
                  SP_BankList[0]^.Changed := True;
                  SP_NeedDisplayUpdate := True;
                  Result := Scrolls;
                  Error.Code := SP_ERR_INVALID_SCALE;
                  Exit;
                End Else Begin
                  CharW := Max(1, Round(FONTWIDTH * ScaleX));
                  CharH := Max(1, Round(FONTHEIGHT * ScaleY));
                  Cw := CharW;
                  Ch := CharH;
                End;
                T_SCALEX := ScaleX;
                T_SCALEY := ScaleY;
              End;
           26:
              Begin
                // ITALIC control
                t := pLongWord(@Text[Idx+1])^;
                If t <> 8 Then
                  If t <> 0 Then Begin
                    T_ITALIC := 1;
                  End Else Begin
                    T_ITALIC := 0;
                  End;
                Inc(Idx, SizeOf(LongWord));
              End;
             27:
              Begin
                // BOLD control
                t := pLongWord(@Text[Idx+1])^;
                If t <> 8 Then
                  If t <> 0 Then Begin
                    T_BOLD := 1;
                  End Else Begin
                    T_BOLD := 0;
                  End;
                Inc(Idx, SizeOf(LongWord));
              End;
          End;
        End;
        Inc(Idx);

      End;

    End;

    If CPos = -1 Then Begin
      PRPOSX := X;
      PRPOSY := Y;
    End;

    SP_BankList[0]^.Changed := True;
    SP_NeedDisplayUpdate := True;
    Result := Scrolls;

  End;

End;

Procedure SP_RotateSize(Src: pByte; sW, sH: Integer; Dst: pByte; dX, dY, dW, dH: Integer; Trans: Word; Rot, Scale: aFloat; cX1, cY1, cX2, cY2: Integer);
Var
  ndW, ndH, cX, cY, iSin, iCos,
  xd, yd, aX, aY, X, Y, sdX, sdY, TLX, TLY, BRX, BRY: Integer;
  tW, tH: aFloat;
  dPtr: pByte;
  TC, sCl: Byte;
Begin

  Rot := -Rot;

  // Calculate the size of the newly rotated+scaled bitmap, so we can alter dx and dy to centre on the destination

  tW := Abs(sW * Scale * Cos(Rot))+Abs(sH * Scale * Sin(Rot));
  tH := Abs(sW * Scale * Sin(Rot))+Abs(sH * Scale * Cos(Rot));
  If Rot <> 0 Then Begin
    If Odd(Trunc(tw)) Then tw := tw + 1;
    If Odd(Trunc(tH)) Then th := th + 1;
  End;
  If dW > 0 Then Begin
    dX := Trunc(dX - (tW - (sW * Scale))/2);
    dY := Trunc(dY - (tH - (sH * Scale))/2);
  End Else
    dW := -dW;
  ndW := Trunc(tW);
  ndH := Trunc(tH);

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

    iSin := Trunc(Sin(Rot)*(65536/Scale));
    iCos := Trunc(Cos(Rot)*(65536/Scale));
    cX := Trunc(ndW / 2);
    cY := Trunc(ndH / 2);

    xd := ((sW Shl 16) - (ndW Shl 16)) Div 2;
    yd := ((sH Shl 16) - (ndH Shl 16)) Div 2;
    ax := (cX Shl 16) - (iCos * cX);
    ay := (cY Shl 16) - (iSin * cX);

    dPtr := Dst;
    Inc(dPtr, (dX + TLX) + ((dY + TLY) * dW));

    If COVER = 0 Then Begin
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
            If (dX < sW) and (dY < sH) Then
              dPtr^ := pByte(NativeUInt(Src) + longword((dY * sW) + dX))^;
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
              If sCL <> TC Then
                dPtr^ := sCL;
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
              SP_OverPixelPtrVal(dPtr, sCl, T_OVER);
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
              If sCL <> TC Then
                SP_OverPixelPtrVal(dPtr, sCl, T_OVER);
            End;
            Inc(dPtr);
          End;
          Inc(dPtr, dW - (BRX - TLX));
        End;
      End;
    End;

  End;

End;

Procedure SP_RotateSizeXY(Src: pByte; sW, sH: Integer; Dst: pByte; dX, dY, dW, dH: Integer; Trans: Word; Rot, ScaleX, ScaleY: aFloat; cX1, cY1, cX2, cY2: Integer);
Var
  ndW, ndH, cX, cY, iSin, iCos,
  xd, yd, aX, aY, X, Y, sdX, sdY, TLX, TLY, BRX, BRY: Integer;
  tW, tH: aFloat;
  dPtr: pByte;
  TC, sCl: Byte;
Begin

  Rot := -Rot;

  // Calculate the size of the newly rotated+scaled bitmap, so we can alter dx and dy to centre on the destination

  tW := Abs(sW * ScaleX * Cos(Rot))+Abs(sH * ScaleY * Sin(Rot));
  tH := Abs(sW * ScaleX * Sin(Rot))+Abs(sH * ScaleY * Cos(Rot));
  If Odd(Round(tw)) Then tw := tw + 1;
  If Odd(Round(tH)) Then th := th + 1;
  If dW > 0 Then Begin
    dX := Round(dX - (tW - (sW * ScaleX))/2);
    dY := Round(dY - (tH - (sH * ScaleY))/2);
  End Else
    dW := -dW;
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

    iSin := Round(Sin(Rot)*(65536/ScaleX));
    iCos := Round(Cos(Rot)*(65536/ScaleY));
    cX := Round(ndW / 2);
    cY := Round(ndH / 2);

    xd := ((sW Shl 16) - (ndW Shl 16)) Div 2;
    yd := ((sH Shl 16) - (ndH Shl 16)) Div 2;
    ax := (cX Shl 16) - (iCos * cX);
    ay := (cY Shl 16) - (iSin * cX);

    dPtr := Dst;
    Inc(dPtr, (dX + TLX) + ((dY + TLY) * dW));

    If COVER = 0 Then Begin
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
            If (dX < sW) and (dY < sH) Then
              dPtr^ := pByte(NativeUInt(Src) + longword((dY * sW) + dX))^;
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
              If sCL <> TC Then
                dPtr^ := sCL;
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
              SP_OverPixelPtrVal(dPtr, sCl, T_OVER);
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
              If sCL <> TC Then
                SP_OverPixelPtrVal(dPtr, sCl, T_OVER);
            End;
            Inc(dPtr);
          End;
          Inc(dPtr, dW - (BRX - TLX));
        End;
      End;
    End;

  End;

End;

Function SP_TextToGraphic(const Text: aString; Var Error: TSP_ErrorCode): aString;
Var
  tW, tH: Integer;
  Valid: Boolean;
Begin

  Result := '';
  Valid := False;
  If Text = '' Then
    Error.Code := SP_ERR_INVALID_FRAME
  Else Begin
    If Length(Text) > 10 Then Begin
      tW := pLongWord(@Text[1])^;
      tH := pLongWord(@Text[5])^;
      If Length(Text) - 10 = tW * tH Then Begin
        Valid := True;
        Result := Text;
      End;
    End;
    If Not Valid Then Begin
      Result := SP_StringToTexture(Text);
      If Text = '' Then
        Error.Code := SP_ERR_INVALID_GRAPHIC_STRING;
    End;
  End;

End;

Procedure SP_RotAndScaleGfx(Var SrcPtr: pByte; Var DstGfx: aString; Rot, Scale: aFloat; Var sW, sH: LongWord; sT: Word; Error: TSP_ErrorCode);
Var
  tW, tH: LongWord;
  cX1, cX2, cY1, cY2, Over: Integer;
Begin

  // Calculate the size of the new bitmap

  tW := Round(Abs(sW * Scale * Cos(Rot))+Abs(sH * Scale * Sin(Rot)));
  tH := Round(Abs(sW * Scale * Sin(Rot))+Abs(sH * Scale * Cos(Rot)));
  If Odd(tW) Then Inc(tW);
  If Odd(tH) Then Inc(tH);

  // Create a string the same size in bytes

  SetLength(DstGfx, tW * tH);

  If sT = $FFFF Then
    FillMem(@DstGfx[1], tW * tH, CPAPER)
  Else
    FillMem(@DstGfx[1], tW * tH, sT And 255);

  cX1 := 0;  cY1 := 0;
  cX2 := tW; cY2 := tH;

  // Now, using DstGfx as a surface, call the Rotate and Scale routine

  Over := T_OVER;
  T_OVER := 0;
  SP_RotateSize(SrcPtr, sW, sH, @DstGfx[1], 0, 0, -tW, tH, $FFFF, Rot, Scale, cX1, cY1, cX2, cY2);
  T_OVER := Over;

  sW := tW;
  sH := tH;

End;

Procedure SP_RotAndScaleGfxXY(Var SrcPtr: pByte; Var DstGfx: aString; Rot, ScaleX, ScaleY: aFloat; Var sW, sH: LongWord; sT: Word; Error: TSP_ErrorCode);
Var
  tW, tH: LongWord;
  cX1, cX2, cY1, cY2, Over: Integer;
Begin

  // Calculate the size of the new bitmap

  tW := Round(Abs(sW * ScaleX * Cos(Rot))+Abs(sH * ScaleY * Sin(Rot)));
  tH := Round(Abs(sW * ScaleX * Sin(Rot))+Abs(sH * ScaleY * Cos(Rot)));
  If Odd(tW) Then Inc(tW);
  If Odd(tH) Then Inc(tH);

  // Create a string the same size in bytes

  SetLength(DstGfx, tW * tH);

  If sT = $FFFF Then
    FillMem(@DstGfx[1], tW * tH, CPAPER)
  Else
    FillMem(@DstGfx[1], tW * tH, sT And 255);

  cX1 := 0;  cY1 := 0;
  cX2 := tW; cY2 := tH;

  // Now, using DstGfx as a surface, call the Rotate and Scale routine

  Over := T_OVER;
  T_OVER := 0;
  SP_RotateSizeXY(SrcPtr, sW, sH, @DstGfx[1], 0, 0, -tW, tH, $FFFF, Rot, ScaleX, ScaleY, cX1, cY1, cX2, cY2);
  T_OVER := Over;

  sW := tW;
  sH := tH;

End;


Procedure SP_FlipGfx(Src: pByte; W, H: LongWord);
var
  Dst, Buffer: pByte;
  W2: LongWord;
begin

  // Reverses the bitmap from top to bottom.

  GetMem(Buffer, W);
  Dst := Src;
  Inc(Dst, W * (H -1));
  If H And 1 = 1 Then
    H := (H -1) Div 2
  Else
    H := H Div 2;

  While H > 0 Do Begin

    W2 := W;
    {$IFDEF CPU64}
    While W2 > SizeOf(NativeUInt) Do Begin
      pNativeUInt(Buffer)^ := pNativeUInt(Src)^;
      Inc(pNativeUInt(Buffer));
      Inc(pNativeUInt(Src));
      Dec(W2, SizeOf(NativeUInt));
    End;
    {$ENDIF}
    While W2 > SizeOf(LongWord) Do Begin
      pLongWord(Buffer)^ := pLongWord(Src)^;
      Inc(pLongWord(Buffer));
      Inc(pLongWord(Src));
      Dec(W2, SizeOf(LongWord));
    End;
    While W2 > 0 Do Begin
      Buffer^ := Src^;
      Inc(Buffer);
      Inc(Src);
      Dec(W2);
    End;
    Dec(Buffer, W);
    Dec(Src, W);

    W2 := W;
    {$IFDEF CPU64}
    While W2 > SizeOf(NativeUInt) Do Begin
      pNativeUInt(Src)^ := pNativeUInt(Dst)^;
      Dec(W2, SizeOf(NativeUInt));
      Inc(pNativeUInt(Src));
      Inc(pNativeUInt(Dst));
    End;
    {$ENDIF}
    While W2 > SizeOf(LongWord) Do Begin
      pLongWord(Src)^ := pLongWord(Dst)^;
      Inc(pLongWord(Src));
      Inc(pLongWord(Dst));
      Dec(W2, SizeOf(LongWord));
    End;
    While W2 > 0 Do Begin
      Src^ := Dst^;
      Inc(Src);
      Inc(Dst);
      Dec(W2);
    End;
    Dec(Dst, W);

    W2 := W;
    {$IFDEF CPU64}
    While W2 > SizeOf(NativeUInt) Do Begin
      pNativeUInt(Dst)^ := pNativeUInt(Buffer)^;
      Dec(W2, SizeOf(NativeUInt));
      Inc(pNativeUInt(Buffer));
      Inc(pNativeUInt(Dst));
    End;
    {$ENDIF}
    While W2 > SizeOf(LongWord) Do Begin
      pLongWord(Dst)^ := pLongWord(Buffer)^;
      Inc(pLongWord(Buffer));
      Inc(pLongWord(Dst));
      Dec(W2, SizeOf(LongWord));
    End;
    While W2 > 0 Do Begin
      Dst^ := Buffer^;
      Inc(Buffer);
      Inc(Dst);
      Dec(W2);
    End;
    Dec(Dst, W *2);
    Dec(Buffer, W);
    Dec(H);

  End;

  FreeMem(Buffer);

End;

Procedure SP_MirrorGfx(Src: pByte; W, H: LongWord);
Var
  Tmp: Byte;
  SSave, Dst: pByte;
  W2, W3: LongWord;
Begin

  // Flips the bitmap left to right

  SSave := Src;
  Dst := pByte(NativeUInt(Src) + (W -1));
  If W And 1 = 1 Then
    W2 := (W -1) Div 2
  Else
    W2 := W Div 2;
  While H > 0 Do Begin
    W3 := W2;
    While W3 > 0 Do Begin
      Tmp := Src^;
      Src^ := Dst^;
      Dst^ := Tmp;
      Inc(Src);
      Dec(Dst);
      Dec(W3);
    End;
    Src := pByte(NativeUInt(SSave) + W);
    Dec(H);
    Dst := pByte(NativeUInt(Src) + (W -1));
    sSave := Src;
  End;

End;

Procedure SP_Dither_Image(Var Gfx: pSP_Graphic_Info; DitherType: Integer);
Var
  ConvArrayRGB: Array[0..255, 0..1] of TP_Colour;
  ConvArray: Array[0..255, 0..1] of Byte;
  d1, d2, dR, dG, dB: aFloat;
  Idx, X, Y, Val, Idx2: LongWord;
  Clr: TP_Colour;
  Ptr: pByte; Closest: Byte;
  dImage: Array of TP_Colour;
  dClr: pTP_Colour;
  R_Error, G_Error, B_Error: aFloat;
  pCl: LongWord;
Const
  DiagonalArray5: Array[0..4, 0..4] of Byte =
    ((4, 2, 1, 3, 5),
     (2, 1, 3, 5, 4),
     (1, 3, 5, 4, 2),
     (3, 5, 4, 2, 1),
     (5, 4, 2, 1, 3));
  DiagonalArray9: Array[0..8, 0..8] of Byte =
    ((8, 6, 4, 2, 1, 3, 5, 7, 9),
     (6, 4, 2, 1, 3, 5, 7, 9, 8),
     (4, 2, 1, 3, 5, 7, 9, 8, 6),
     (2, 1, 3, 5, 7, 9, 8, 6, 4),
     (1, 3, 5, 7, 9, 8, 6, 4, 2),
     (3, 5, 7, 9, 8, 6, 4, 2, 1),
     (5, 7, 9, 8, 6, 4, 2, 1, 3),
     (7, 9, 8, 6, 4, 2, 1, 3, 5),
     (9, 8, 6, 4, 2, 1, 3, 5, 7));
  ClusterArray: Array [0..9] of AnsiString =
     ('000000000',
      '000010000',
      '000011000',
      '010011000',
      '011011000',
      '011011010',
      '011111010',
      '011111110',
      '111111110',
      '111111111');
  DispersedArray: Array [0..9] of AnsiString =
     ('000000000',
      '100000000',
      '100000010',
      '100001010',
      '101001010',
      '101101010',
      '101101110',
      '111101110',
      '111111110',
      '111111111');
  MidToneArray: Array[0..3] of AnsiString =
     ('000',
      '010',
      '101',
      '111');
  DitherArray16: Array[0..3, 0..3] of Byte =
     ((00, 08, 02, 10),
      (12, 04, 14, 06),
      (03, 11, 01, 09),
      (15, 07, 13, 05));
  DitherArray64: Array[0..7, 0..7] of Byte =
     ((16, 34, 26, 42, 18, 36, 28, 44),
      (58, 00, 50, 08, 60, 02, 52, 10),
      (30, 46, 20, 38, 32, 48, 22, 40),
      (54, 12, 62, 04, 56, 14, 64, 06),
      (19, 37, 29, 45, 17, 35, 27, 43),
      (61, 03, 53, 11, 59, 01, 51, 09),
      (33, 49, 23, 41, 31, 47, 21, 39),
      (57, 15, 65, 07, 55, 13, 63, 05));
Begin

  // Populate the LUTs with converted colours. Index 0 is the nearest colour, Index 1 is the next-nearest.

  For Idx := 0 To 255 Do Begin
    Clr := Gfx^.Palette[Idx];
    ConvArray[Idx, 0] := SP_Get_Nearest_Colour(Clr.R, Clr.G, Clr.B, -1);
    ConvArrayRGB[Idx, 0].R := Gfx^.Palette[ConvArray[Idx, 0]].R;
    ConvArrayRGB[Idx, 0].G := Gfx^.Palette[ConvArray[Idx, 0]].G;
    ConvArrayRGB[Idx, 0].B := Gfx^.Palette[ConvArray[Idx, 0]].B;
    ConvArray[Idx, 1] := SP_Get_Nearest_Colour(Clr.R, Clr.G, Clr.B, ConvArray[Idx, 0]);
    ConvArrayRGB[Idx, 1].R := Gfx^.Palette[ConvArray[Idx, 1]].R;
    ConvArrayRGB[Idx, 1].G := Gfx^.Palette[ConvArray[Idx, 1]].G;
    ConvArrayRGB[Idx, 1].B := Gfx^.Palette[ConvArray[Idx, 1]].B;
  End;

  // Each pixel in the source image now has two colours in the screen palette that it is closest to -
  // so dither using these colours.

  Ptr := Gfx^.Data;
  Idx := Gfx^.Width * Gfx^.Height;

  Case DitherType Of

    0: // No dithering
      Begin
        While Idx > 0 Do Begin
          Ptr^ := ConvArray[Ptr^, 0];
          Inc(Ptr);
          Dec(Idx);
        End;
      End;

    1: // Random Dithering
      Begin
        While Idx > 0 Do Begin
          If Random > 0.5 Then
            Ptr^ := ConvArray[Ptr^, 0]
          Else
            Ptr^ := ConvArray[Ptr^, 1];
          Inc(Ptr);
          Dec(Idx);
        End;
      End;

    2..8: // Matrix dither types
      Begin
        X := 0;
        Y := 0;
        While Idx > 0 Do Begin
          dR := Gfx^.Palette[Ptr^].R - ConvArrayRGB[Ptr^, 1].R;
          dG := Gfx^.Palette[Ptr^].G - ConvArrayRGB[Ptr^, 1].G;
          dB := Gfx^.Palette[Ptr^].B - ConvArrayRGB[Ptr^, 1].B;
          d1 := Sqrt(dR*dR+dG*dG+dB*dB);
          dR := Gfx^.Palette[Ptr^].R - ConvArrayRGB[Ptr^, 0].R;
          dG := Gfx^.Palette[Ptr^].G - ConvArrayRGB[Ptr^, 0].G;
          dB := Gfx^.Palette[Ptr^].B - ConvArrayRGB[Ptr^, 0].B;
          d2 := Sqrt(dR*dR+dG*dG+dB*dB);
          If d1 = d2 Then
            Ptr^ := ConvArray[Ptr^, 0]
          Else
            Case DitherType of
              2: // 5-Level Diagonal Dither
                Begin
                  Val := Round((d1 / (d1 + d2)) * 5);
                  If Val >= DiagonalArray5[X Mod 5, Y Mod 5] Then
                    Ptr^ := ConvArray[Ptr^, 0]
                  Else
                    Ptr^ := ConvArray[Ptr^, 1];
                End;
              3: // 9-Level Diagonal Dither
                Begin
                  Val := Round((d1 / (d1 + d2)) * 9);
                  If Val >= DiagonalArray9[X Mod 9, Y Mod 9] Then
                    Ptr^ := ConvArray[Ptr^, 0]
                  Else
                    Ptr^ := ConvArray[Ptr^, 1];
                End;
              4: // Clustered-dot dither
                Begin
                  Val := Min(Round((d1 / (d1 + d2)) * 10), 9);
                  If ClusterArray[Val][(((Y Mod 3) * 3) + X Mod 3) +1] = '1' Then
                    Ptr^ := ConvArray[Ptr^, 0]
                  Else
                    Ptr^ := ConvArray[Ptr^, 1];
                End;
              5: // Dispersed-dot dither
                Begin
                  Val := Min(Round((d1 / (d1 + d2)) * 10), 9);
                  If DispersedArray[Val][(((Y Mod 3) * 3) + X Mod 3) +1] = '1' Then
                    Ptr^ := ConvArray[Ptr^, 0]
                  Else
                    Ptr^ := ConvArray[Ptr^, 1];
                End;
              6: // Halftone dither
                Begin
                  Val := Round(Abs(d1 / (d1 + d2)) * 255);
                  Case Val of
                    0..85:
                      Ptr^ := ConvArray[Ptr^, 1];
                    86..172:
                      Begin
                        If Y And 1 = 0 Then Begin
                          If X And 1 = 0 Then
                            Ptr^ := ConvArray[Ptr^, 0]
                          Else
                            Ptr^ := ConvArray[Ptr^, 1]
                        End Else
                          If X and 1 <> 0 Then
                            Ptr^ := ConvArray[Ptr^, 0]
                          Else
                            Ptr^ := ConvArray[Ptr^, 1];
                      End;
                    173..256:
                      Begin
                        Ptr^ := ConvArray[Ptr^, 0];
                      End;
                  End;
                End;
              7: // 16-Level Ordered Dither
                Begin
                  Val := Round((d1 / (d1 + d2)) * 16);
                  If Val >= DitherArray16[X Mod 4, Y Mod 4] Then
                    Ptr^ := ConvArray[Ptr^, 0]
                  Else
                    Ptr^ := ConvArray[Ptr^, 1];
                End;
              8: // 64-Level Ordered Dither
                Begin
                  Val := Round((d1 / (d1 + d2)) * 64);
                  If Val >= DitherArray64[X Mod 8, Y Mod 8] Then
                    Ptr^ := ConvArray[Ptr^, 0]
                  Else
                    Ptr^ := ConvArray[Ptr^, 1];
                End;
            End;
          Inc(Ptr);
          Dec(Idx);
          Inc(X);
          If X = Gfx^.Width Then Begin
            X := 0;
            Inc(Y);
          End;
        End;
      End;
    9..17: // Error Diffusion. Specific routines below!
      Begin
        SetLength(dImage, Idx);
        Idx2 := 0;
        Ptr := Gfx^.Data;
        While Idx2 < Idx Do Begin
          dImage[Idx2] := Gfx^.Palette[Ptr^];
          Inc(Ptr);
          Inc(Idx2);
        End;
        Ptr := Gfx^.Data;
        Y := 0; Idx2 := 0;

        Case DitherType of

          9:  // Modified Floyd-Steinberg
            Begin

              While Y < Gfx^.Height Do Begin
                X := 0;
                While X < Gfx^.Width Do Begin

                  dClr := @dImage[Idx2];
                  Closest := SP_Get_Nearest_Colour_Fast(dClr^.R, dClr^.G, dClr^.B);
                  pCl := SP_GetPalette(Closest);

                  R_Error := ((dClr^.R) - ((pCl Shr 24) And $FF))/16;
                  G_Error := ((dClr^.G) - ((pCl Shr 16) And $FF))/16;
                  B_Error := ((dClr^.B) - ((pCl Shr 8) And $FF))/16;
                  Ptr^ := Closest;

                  If X < Gfx^.Width -1 Then Begin
                    dClr := @dImage[Idx2 +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 7), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 7), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 7), 0), 255);
                  End;

                  If (X > 0) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width -1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 3), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 3), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 3), 0), 255);
                  End;

                  If (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 5), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 5), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 5), 0), 255);
                  End;

                  If (X < Gfx^.Width -1) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 0), 255);
                  End;

                  Inc(X);
                  Inc(Ptr);
                  Inc(Idx2);

                End;
                Inc(Y);
              End;

            End;

          10: // Jarvis error diffusion
            Begin

              While Y < Gfx^.Height Do Begin
                X := 0;
                While X < Gfx^.Width Do Begin

                  dClr := @dImage[Idx2];
                  Closest := SP_Get_Nearest_Colour_Fast(dClr^.R, dClr^.G, dClr^.B);
                  pCl := SP_GetPalette(Closest);

                  R_Error := ((dClr^.R) - ((pCl Shr 24) And $FF))/48;
                  G_Error := ((dClr^.G) - ((pCl Shr 16) And $FF))/48;
                  B_Error := ((dClr^.B) - ((pCl Shr 8) And $FF))/48;
                  Ptr^ := Closest;

                  If X < Gfx^.Width -1 Then Begin
                    dClr := @dImage[Idx2 + 1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 7), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 7), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 7), 0), 255);
                  End;

                  If X < Gfx^.Width -2 Then Begin
                    dClr := @dImage[Idx2 + 2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 5), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 5), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 5), 0), 255);
                  End;

                  If (X > 1) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + GFx^.Width -2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 3), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 3), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 3), 0), 255);
                  End;

                  If (X > 0) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + GFx^.Width -1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 5), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 5), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 5), 0), 255);
                  End;

                  If Y < Gfx^.Height -1 Then Begin
                    dClr := @dImage[Idx2 + GFx^.Width];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 7), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 7), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 7), 0), 255);
                  End;

                  If (X < Gfx^.Width -1) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + GFx^.Width +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 5), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 5), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 5), 0), 255);
                  End;

                  If (X < Gfx^.Width -2) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + GFx^.Width +2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 3), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 3), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 3), 0), 255);
                  End;

                  If (X > 1) And (Y < Gfx^.Height -2) Then Begin
                    dClr := @dImage[Idx2 + (GFx^.Width * 2) -2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 0), 255);
                  End;

                  If (X > 0) And (Y < Gfx^.Height -2) Then Begin
                    dClr := @dImage[Idx2 + (GFx^.Width * 2) -1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 3), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 3), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 3), 0), 255);
                  End;

                  If Y < Gfx^.Height -2 Then Begin
                    dClr := @dImage[Idx2 + (GFx^.Width * 2)];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 5), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 5), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 5), 0), 255);
                  End;

                  If (X < Gfx^.Width -1) And (Y < Gfx^.Height -2) Then Begin
                    dClr := @dImage[Idx2 + (GFx^.Width * 2) +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 3), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 3), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 3), 0), 255);
                  End;

                  If (X < Gfx^.Width -2) And (Y < Gfx^.Height -2) Then Begin
                    dClr := @dImage[Idx2 + (GFx^.Width * 2) +2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 0), 255);
                  End;

                  Inc(X);
                  Inc(Ptr);
                  Inc(Idx2);

                End;
                Inc(Y);
              End;

            End;

          11: // Stucki error diffusion
            Begin

              While Y < Gfx^.Height Do Begin
                X := 0;
                While X < Gfx^.Width Do Begin

                  dClr := @dImage[Idx2];
                  Closest := SP_Get_Nearest_Colour_Fast(dClr^.R, dClr^.G, dClr^.B);
                  pCl := SP_GetPalette(Closest);

                  R_Error := ((dClr^.R) - ((pCl Shr 24) And $FF))/42;
                  G_Error := ((dClr^.G) - ((pCl Shr 16) And $FF))/42;
                  B_Error := ((dClr^.B) - ((pCl Shr 8) And $FF))/42;
                  Ptr^ := Closest;

                  If X < Gfx^.Width -1 Then Begin
                    dClr := @dImage[Idx2 + 1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 8), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 8), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 8), 0), 255);
                  End;

                  If X < Gfx^.Width -2 Then Begin
                    dClr := @dImage[Idx2 + 2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 4), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 4), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 4), 0), 255);
                  End;

                  If (X > 1) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + GFx^.Width -2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 2), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 2), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 2), 0), 255);
                  End;

                  If (X > 0) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + GFx^.Width -1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 4), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 4), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 4), 0), 255);
                  End;

                  If Y < Gfx^.Height -1 Then Begin
                    dClr := @dImage[Idx2 + GFx^.Width];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 8), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 8), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 8), 0), 255);
                  End;

                  If (X < Gfx^.Width -1) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + GFx^.Width +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 4), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 4), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 4), 0), 255);
                  End;

                  If (X < Gfx^.Width -2) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + GFx^.Width +2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 2), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 2), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 2), 0), 255);
                  End;

                  If (X > 1) And (Y < Gfx^.Height -2) Then Begin
                    dClr := @dImage[Idx2 + (GFx^.Width * 2) -2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 0), 255);
                  End;

                  If (X > 0) And (Y < Gfx^.Height -2) Then Begin
                    dClr := @dImage[Idx2 + (GFx^.Width * 2) -1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 2), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 2), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 2), 0), 255);
                  End;

                  If Y < Gfx^.Height -2 Then Begin
                    dClr := @dImage[Idx2 + (GFx^.Width * 2)];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 4), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 4), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 4), 0), 255);
                  End;

                  If (X < Gfx^.Width -1) And (Y < Gfx^.Height -2) Then Begin
                    dClr := @dImage[Idx2 + (GFx^.Width * 2) +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 2), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 2), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 2), 0), 255);
                  End;

                  If (X < Gfx^.Width -2) And (Y < Gfx^.Height -2) Then Begin
                    dClr := @dImage[Idx2 + (GFx^.Width * 2) +2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 0), 255);
                  End;

                  Inc(X);
                  Inc(Ptr);
                  Inc(Idx2);

                End;
                Inc(Y);
              End;

            End;
          12:
            Begin // Burkes error diffusion

              While Y < Gfx^.Height Do Begin
                X := 0;
                While X < Gfx^.Width Do Begin

                  dClr := @dImage[Idx2];
                  Closest := SP_Get_Nearest_Colour_Fast(dClr^.R, dClr^.G, dClr^.B);
                  pCl := SP_GetPalette(Closest);

                  R_Error := ((dClr^.R) - ((pCl Shr 24) And $FF))/32;
                  G_Error := ((dClr^.G) - ((pCl Shr 16) And $FF))/32;
                  B_Error := ((dClr^.B) - ((pCl Shr 8) And $FF))/32;
                  Ptr^ := Closest;

                  If X < Gfx^.Width -1 Then Begin
                    dClr := @dImage[Idx2 +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 8), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 8), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 8), 0), 255);
                  End;

                  If X < Gfx^.Width -2 Then Begin
                    dClr := @dImage[Idx2 +2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 4), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 4), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 4), 0), 255);
                  End;

                  If (X > 1) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width -2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 2), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 2), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 2), 0), 255);
                  End;

                  If (X > 0) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width -1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 4), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 4), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 4), 0), 255);
                  End;

                  If (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 8), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 8), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 8), 0), 255);
                  End;

                  If (X < Gfx^.Width -1) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 4), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 4), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 4), 255);
                  End;

                  If (X < Gfx^.Width -2) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width +2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 2), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 2), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 2), 255);
                  End;

                  Inc(X);
                  Inc(Ptr);
                  Inc(Idx2);

                End;
                Inc(Y);
              End;

            End;
          13: // Sierra-3
            Begin

              While Y < Gfx^.Height Do Begin
                X := 0;
                While X < Gfx^.Width Do Begin

                  dClr := @dImage[Idx2];
                  Closest := SP_Get_Nearest_Colour_Fast(dClr^.R, dClr^.G, dClr^.B);
                  pCl := SP_GetPalette(Closest);

                  R_Error := ((dClr^.R) - ((pCl Shr 24) And $FF))/32;
                  G_Error := ((dClr^.G) - ((pCl Shr 16) And $FF))/32;
                  B_Error := ((dClr^.B) - ((pCl Shr 8) And $FF))/32;
                  Ptr^ := Closest;

                  If X < Gfx^.Width Then Begin
                    dClr := @dImage[Idx2 +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 5), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 5), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 5), 0), 255);
                  End;

                  If X < Gfx^.Width -1 Then Begin
                    dClr := @dImage[Idx2 +2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 3), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 3), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 3), 0), 255);
                  End;

                  If (X > 1) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width -2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 2), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 2), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 2), 0), 255);
                  End;

                  If (X > 0) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width -1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 4), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 4), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 4), 0), 255);
                  End;

                  If (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 5), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 5), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 5), 0), 255);
                  End;

                  If (X < Gfx^.Width -1) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 4), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 4), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 4), 255);
                  End;

                  If (X < Gfx^.Width -2) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width +2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 2), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 2), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 2), 255);
                  End;

                  If (X > 0) And (Y < Gfx^.Height -2) Then Begin
                    dClr := @dImage[Idx2 + (Gfx^.Width * 2)  -1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 2), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 2), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 2), 255);
                  End;

                  If Y < Gfx^.Height -2 Then Begin
                    dClr := @dImage[Idx2 + (Gfx^.Width * 2)];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 3), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 3), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 3), 255);
                  End;

                  If (X < Gfx^.Width -1) And (Y < Gfx^.Height -2) Then Begin
                    dClr := @dImage[Idx2 + (Gfx^.Width * 2)  +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 2), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 2), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 2), 255);
                  End;

                  Inc(X);
                  Inc(Ptr);
                  Inc(Idx2);

                End;
                Inc(Y);
              End;

            End;
          14: // Sierra-2
            Begin

              While Y < Gfx^.Height Do Begin
                X := 0;
                While X < Gfx^.Width Do Begin

                  dClr := @dImage[Idx2];
                  Closest := SP_Get_Nearest_Colour_Fast(dClr^.R, dClr^.G, dClr^.B);
                  pCl := SP_GetPalette(Closest);

                  R_Error := (dClr^.R - ((pCl Shr 24) And $FF))/16;
                  G_Error := (dClr^.G - ((pCl Shr 16) And $FF))/16;
                  B_Error := (dClr^.B - ((pCl Shr 8) And $FF))/16;
                  Ptr^ := Closest;

                  If X < Gfx^.Width -1 Then Begin
                    dClr := @dImage[Idx2 +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 4), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 4), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 4), 0), 255);
                  End;

                  If X < Gfx^.Width -2 Then Begin
                    dClr := @dImage[Idx2 +2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 3), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 3), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 3), 0), 255);
                  End;

                  If (X > 1) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width -2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 0), 255);
                  End;

                  If (X > 0) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width -1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 2), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 2), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 2), 0), 255);
                  End;

                  If (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 3), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 3), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 3), 0), 255);
                  End;

                  If (X < Gfx^.Width -1) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 2), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 2), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 2), 255);
                  End;

                  If (X < Gfx^.Width -2) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width +2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 1), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 1), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 1), 255);
                  End;

                  Inc(X);
                  Inc(Ptr);
                  Inc(Idx2);

                End;
                Inc(Y);
              End;

            End;
          15: // Sierra Lite
            Begin

              While Y < Gfx^.Height Do Begin
                X := 0;
                While X < Gfx^.Width Do Begin

                  dClr := @dImage[Idx2];
                  Closest := SP_Get_Nearest_Colour_Fast(dClr^.R, dClr^.G, dClr^.B);
                  pCl := SP_GetPalette(Closest);

                  R_Error := (dClr^.R - ((pCl Shr 24) And $FF))/4;
                  G_Error := (dClr^.G - ((pCl Shr 16) And $FF))/4;
                  B_Error := (dClr^.B - ((pCl Shr 8) And $FF))/4;
                  Ptr^ := Closest;

                  If X < Gfx^.Width -1 Then Begin
                    dClr := @dImage[Idx2 +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 2), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 2), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 2), 0), 255);
                  End;

                  If (X > 0) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width -1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 0), 255);
                  End;

                  If (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 0), 255);
                  End;

                  Inc(X);
                  Inc(Ptr);
                  Inc(Idx2);

                End;
                Inc(Y);
              End;

            End;
          16: // Atkinson
            Begin

              While Y < Gfx^.Height Do Begin
                X := 0;
                While X < Gfx^.Width Do Begin

                  dClr := @dImage[Idx2];
                  Closest := SP_Get_Nearest_Colour_Fast(dClr^.R, dClr^.G, dClr^.B);
                  pCl := SP_GetPalette(Closest);

                  R_Error := (dClr^.R - ((pCl Shr 24) And $FF))/8;
                  G_Error := (dClr^.G - ((pCl Shr 16) And $FF))/8;
                  B_Error := (dClr^.B - ((pCl Shr 8) And $FF))/8;
                  Ptr^ := Closest;

                  If X < Gfx^.Width -1 Then Begin
                    dClr := @dImage[Idx2 +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 0), 255);
                  End;

                  If X < Gfx^.Width -2 Then Begin
                    dClr := @dImage[Idx2 +2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 0), 255);
                  End;

                  If (X > 0) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width -1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 0), 255);
                  End;

                  If Y < Gfx^.Height -1 Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 0), 255);
                  End;

                  If (X < Gfx^.Width -1) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 0), 255);
                  End;

                  If Y < Gfx^.Height -2 Then Begin
                    dClr := @dImage[Idx2 + (Gfx^.Width * 2)];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error), 0), 255);
                  End;

                  Inc(X);
                  Inc(Ptr);
                  Inc(Idx2);

                End;
                Inc(Y);
              End;

            End;
          17: // Stevenson-Arce
            Begin

              While Y < Gfx^.Height Do Begin
                X := 0;
                While X < Gfx^.Width Do Begin

                  dClr := @dImage[Idx2];
                  Closest := SP_Get_Nearest_Colour_Fast(dClr^.R, dClr^.G, dClr^.B);
                  pCl := SP_GetPalette(Closest);

                  R_Error := (dClr^.R - ((pCl Shr 24) And $FF))/200;
                  G_Error := (dClr^.G - ((pCl Shr 16) And $FF))/200;
                  B_Error := (dClr^.B - ((pCl Shr 8) And $FF))/200;
                  Ptr^ := Closest;

                  If X < Gfx^.Width -2 Then Begin
                    dClr := @dImage[Idx2 +2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 32), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 32), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 32), 0), 255);
                  End;

                  If (X > 2) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width - 3];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 12), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 12), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 12), 0), 255);
                  End;

                  If (X > 1) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width - 1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 26), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 26), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 26), 0), 255);
                  End;

                  If (X < Gfx^.Width -1) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width +1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 30), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 30), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 30), 0), 255);
                  End;

                  If (X < Gfx^.Width -3) And (Y < Gfx^.Height -1) Then Begin
                    dClr := @dImage[Idx2 + Gfx^.Width +3];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 16), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 16), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 16), 0), 255);
                  End;

                  If (X > 1) And (Y < Gfx^.Height -2) Then Begin
                    dClr := @dImage[Idx2 + (Gfx^.Width * 2) - 2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 12), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 12), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 12), 0), 255);
                  End;

                  If Y < Gfx^.Height -2 Then Begin
                    dClr := @dImage[Idx2 + (Gfx^.Width * 2)];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 26), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 26), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 26), 0), 255);
                  End;

                  If (X < Gfx^.Width -2) And (Y < Gfx^.Height -2) Then Begin
                    dClr := @dImage[Idx2 + (Gfx^.Width * 2) + 2];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 12), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 12), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 12), 0), 255);
                  End;

                  If (X > 2) And (Y < Gfx^.Height -3) Then Begin
                    dClr := @dImage[Idx2 + (Gfx^.Width * 3) - 3];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 5), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 5), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 5), 0), 255);
                  End;

                  If (X > 0) And (Y < Gfx^.Height -3) Then Begin
                    dClr := @dImage[Idx2 + (Gfx^.Width * 3) - 1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 12), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 12), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 12), 0), 255);
                  End;

                  If (X < Gfx^.Width - 1) And (Y < Gfx^.Height -3) Then Begin
                    dClr := @dImage[Idx2 + (Gfx^.Width * 3) + 1];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 12), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 12), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 12), 0), 255);
                  End;

                  If (X < Gfx^.Width - 3) And (Y < Gfx^.Height -3) Then Begin
                    dClr := @dImage[Idx2 + (Gfx^.Width * 3) + 3];
                    dClr^.R := Min(Max(dClr.R + Round(R_Error * 5), 0), 255);
                    dClr^.G := Min(Max(dClr.G + Round(G_Error * 5), 0), 255);
                    dClr^.B := Min(Max(dClr.B + Round(B_Error * 5), 0), 255);
                  End;

                  Inc(X);
                  Inc(Ptr);
                  Inc(Idx2);

                End;
                Inc(Y);
              End;

            End;
        End;
      End;
  End;

End;

Procedure SP_DrawMouseImage;
Var
  cX1, cY1, cX2, cY2, BankID: Integer;
  Graphic: pSP_Graphic_Info;
  gBank: pSP_Bank;
  Error: TSP_ErrorCode;
Begin

  If Not SCREENCHANGE And (DISPLAYPOINTER <> nil) Then Begin

    SP_SaveMouseRegion;

    cX1 := 0; cY1 := 0;
    cX2 := DISPLAYWIDTH;
    cY2 := DISPLAYHEIGHT;
    If MOUSEISGRAPHIC Then Begin
      BankID := SP_FindBankID(MOUSESPRITE);
      If BankID > -1 Then Begin
        gBank := SP_BankList[BankID];
        If gBank^.DataType = SP_GRAPHIC_BANK Then Begin
          Graphic := @gBank^.Info[0];
          cX1 := 0; cy1 := 0; cx2 := DISPLAYWIDTH; cy2 := DISPLAYHEIGHT;
          SP_PutRegion8To32(DISPLAYPOINTER, MOUSEX - MOUSEHSX, MOUSEY - MOUSEHSY, DISPLAYSTRIDE, DISPLAYHEIGHT, pByte(Graphic), -1, @Graphic^.Palette[0], 0, 1, cX1, cY1, cX2, cY2, Error);
        End;
      End;
    End Else
      SP_PutRegion8To32(DISPLAYPOINTER, MOUSEX - MOUSEHSX, MOUSEY - MOUSEHSY, DISPLAYSTRIDE, DISPLAYHEIGHT, @MOUSESTR[1], Length(MOUSESTR), @MOUSEPALETTE[0], 0, 1, cX1, cY1, cX2, cY2, Error);

    {$IFDEF FPC}
    With DispRects[GfxUpdRect] Do Begin
      x := Max(MOUSEX, 0);
      y := Max(MOUSEY, 0);
      w := Min(DISPLAYWIDTH - MOUSEX, MOUSEW);
      h := Min(DISPLAYHEIGHT - MOUSEY, MOUSEH);
      Inc(GfxUpdRect);
    End;
    {$ENDIF}

  End;

End;

Procedure SP_MousePointerFromDefault;
Var
  x, y: Integer;
  pStr: aString;
Const
  Pointer: Array[0..10, 0..10] of Byte =
    ((0,  0,  0,  0,  0,  0,  3,  3,  3,  3,  3),
     (0, 15, 15, 15, 15, 15,  0,  3,  3,  3,  3),
     (0, 10, 10, 10, 10, 15,  0,  3,  3,  3,  3),
     (0, 10, 10, 10, 15,  0,  3,  3,  3,  3,  3),
     (0, 10, 10, 10, 10, 15,  0,  3,  3,  3,  3),
     (0, 10, 10,  0, 10, 10, 15,  0,  3,  3,  3),
     (3,  0,  0,  3,  0, 10, 10, 15,  0,  3,  3),
     (3,  3,  3,  3,  3,  0, 10, 10, 15,  0,  3),
     (3,  3,  3,  3,  3,  3,  0, 10, 10, 15,  0),
     (3,  3,  3,  3,  3,  3,  3,  0, 10,  0,  3),
     (3,  3,  3,  3,  3,  3,  3,  3,  0,  3,  3));
Begin

  DisplaySection.Enter;

  pStr := LongWordToString(16) + LongWordToString(16) + WordToString(3);

  For y := 0 To 15 Do
    For x := 0 To 15 Do
      If (x < 11) and (y < 11) Then
        pStr := pStr + aChar(Pointer[y, x])
      Else
        pStr := pStr + aChar(3);

  MOUSESTR := pStr;
  MOUSESPRITE := -1;
  MOUSEISGRAPHIC := False;
  MOUSEHSX := 0;
  MOUSEHSY := 0;
  MOUSEW := pLongWord(@MOUSESTR[1])^;
  MOUSEH := pLongWord(@MOUSESTR[5])^;

  For x := 0 To 255 Do MOUSEPALETTE[x] := DefaultPalette[x];

  DisplaySection.Leave;

End;

Procedure SP_MousePointerFromGraphic(BankID, HotX, HotY: Integer; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
  Graphic: pSP_Graphic_Info;
  Bank: pSP_Bank;
Begin

  DisplaySection.Enter;

  Idx := SP_FindBankID(BankID);
  If Idx > -1 Then Begin
    Bank := SP_BankList[Idx];
    If Bank^.DataType = SP_GRAPHIC_BANK Then Begin

      Graphic := pSP_Graphic_Info(@SP_BankList[Idx].Info[0]);
      MOUSESPRITE := BankID;
      MOUSEISGRAPHIC := True;
      MOUSEHSX := HotX;
      MOUSEHSY := HotY;
      MOUSEW := Graphic^.Width;
      MOUSEH := Graphic^.Height;

    End Else

      Error.Code := SP_ERR_INVALID_BANK;

  End Else

    Error.Code := SP_ERR_BANK_NOT_FOUND;

  DisplaySection.Leave;

End;

Procedure SP_MousePointerFromString(Graphic: aString; HotX, HotY: Integer);
Var
  Valid: Boolean;
  tW, tH: Integer;
Begin

  DisplaySection.Enter;

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
  End;

  MOUSEISGRAPHIC := False;
  MOUSESTR := Graphic;
  MOUSEHSX := HotX;
  MOUSEHSY := HotY;
  MOUSEW := pLongWord(@MOUSESTR[1])^;
  MOUSEH := pLongWord(@MOUSESTR[5])^;

  For tw := 0 To 255 Do MOUSEPALETTE[tw] := DefaultPalette[tw];

  DisplaySection.Leave;

End;

Procedure SP_SaveMouseRegion;
Var
  BankID: Integer;
  Error: TSP_ErrorCode;
Begin

  DisplaySection.Enter;
  If Not SCREENCHANGE And (DISPLAYPOINTER <> nil) And (MOUSEW > 0) Then Begin

    MOUSEIMAGE := '';
    MOUSESTOREX := Max(MOUSEX - MOUSEHSX, 0);
    MOUSESTOREY := Max(MOUSEY - MOUSEHSY, 0);
    If MOUSEISGRAPHIC Then Begin
      BankID := SP_FindBankID(MOUSESPRITE);
      If BankID > -1 Then
        If SP_BankList[BankID]^.DataType = SP_GRAPHIC_BANK Then
          SP_GetRegion32(DISPLAYPOINTER, DISPLAYSTRIDE, DISPLAYHEIGHT, MOUSEIMAGE, MOUSESTOREX, MOUSESTOREY, MOUSEW, MOUSEH, Error);
    End Else
      SP_GetRegion32(DISPLAYPOINTER, DISPLAYSTRIDE, DISPLAYHEIGHT, MOUSEIMAGE, MOUSESTOREX, MOUSESTOREY, MOUSEW, MOUSEH, Error);

    If MOUSEIMAGE <> '' Then Begin
      MOUSESTOREW := pLongWord(@MOUSEIMAGE[1])^;
      MOUSESTOREH := pLongWord(@MOUSEIMAGE[5])^;
    End;

  End;
  DisplaySection.Leave;

End;

Procedure SP_RestoreMouseRegion;
Var
  cX1, cY1, cX2, cY2: Integer;
  Error: TSP_ErrorCode;
Begin

  DisplaySection.Enter;
  If Not SCREENCHANGE And (DISPLAYPOINTER <> Nil) And (MOUSEIMAGE <> '') Then Begin
    cX1 := 0; cy1 := 0; cx2 := DISPLAYWIDTH; cy2 := DISPLAYHEIGHT;
    SP_PutRegion_NO_OVER32To32(DISPLAYPOINTER, MOUSESTOREX, MOUSESTOREY, DISPLAYSTRIDE, DISPLAYHEIGHT, @MOUSEIMAGE[1], Length(MOUSEIMAGE), cX1, cY1, cX2, cY2, Error);
    {$IFDEF FPC}
    With DispRects[GfxUpdRect] Do Begin
      x := MOUSESTOREX;
      y := MOUSESTOREY;
      w := MOUSESTOREW;
      h := MOUSESTOREH;
      Inc(GfxUpdRect);
    End;
    {$ENDIF}
    MOUSEIMAGE := '';
  End;
  DisplaySection.Leave;

End;

// Backwards procedures! These convert from logical to physical coords.

Procedure SP_ConvertWToOrigin_d(Var X, Y: aFloat; Win: pSP_Window_Info); inline;
Begin

  If Win^.winorigin Then Begin
    X := X - Win^.orgx;
    Y := Y - Win^.orgy;
  End;

  If Win^.winscale Then Begin
    X := X / Win^.winscalex;
    Y := Y / Win^.winscaley;
  End;

End;

Procedure SP_ConvertToOrigin_d(var X, Y: aFloat); inline;
Begin

  If WINORIGIN Then Begin
    X := X - SORGX;
    Y := Y - SORGY;
  End;

  If WINSCALE Then Begin
    X := X / WINSCALEX;
    Y := Y / WINSCALEY;
  End;

End;

Procedure SP_ConvertToOrigin_i(var X, Y: Integer); inline;
Begin

  If WINORIGIN Then Begin
    X := Round(X - SORGX);
    Y := Round(Y - SORGY);
  End;

  If WINSCALE Then Begin
    X := Round(X / WINSCALEX);
    Y := Round(Y / WINSCALEY);
  End;

End;

Procedure SP_ConvertToOrigin_i_x(var X: Integer); inline;
Begin

  If WINORIGIN Then X := Round(X - SORGX);
  If WINSCALE Then X := Round(X / WINSCALEX);

End;

Procedure SP_ConvertToOrigin_i_y(var Y: Integer); inline;
Begin

  If WINORIGIN Then Y := Round(Y - SORGY);
  If WINSCALE Then Y := Round(Y / WINSCALEY);

End;

Procedure SP_ConvertToOrigin_d_x(var X: aFloat); inline;
Begin

  If WINORIGIN Then X := X - SORGX;
  If WINSCALE Then X := X / WINSCALEX;

End;

Procedure SP_ConvertToOrigin_d_y(var Y: aFloat); inline;
Begin

  If WINORIGIN Then Y := Y - SORGY;
  If WINSCALE Then Y := Y / WINSCALEY;

End;

Procedure SP_ConvertToOrigin_l(var X, Y: LongWord); inline;
Begin

  If WINORIGIN Then Begin
    X := Round(X - SORGX);
    Y := Round(Y - SORGY);
  End;

  If WINSCALE Then Begin
    X := Round(X / WINSCALEX);
    Y := Round(Y / WINSCALEY);
  End;

End;

Function SP_ConvertToScreenX(X: aFloat): aFloat;
Begin

  Result := X;

  If WINSCALE Then
    Result := Result * WINSCALEX;

  If WINORIGIN Then
    Result := Result + SORGX;

End;

Function SP_ConvertToScreenY(Y: aFloat): aFloat;
Begin

  Result := Y;

  If WINSCALE Then
    Result := Result * WINSCALEY;

  If WINORIGIN Then
    Result := Result + SORGY;

End;

Procedure SP_OverPixelPtr(Var c1, c2: pByte; Over: Integer); inline;
Begin

  Case Over of
    1: // Xor
      c1^ := c1^ xor c2^;
    2: // Add
      c1^ := c1^ + c2^;
    3: // Subtract
      c1^ := c1^ - c2^;
    4: // And
      c1^ := c1^ And c2^;
    5: // Or
      c1^ := c1^ Or c2^;
    6: // Not
      c1^ := Not c1^;
    7: // Avg
      c1^ := (c1^ + c2^) Shr 1;
    8: // Max
      c1^ := Max(c1^, c2^);
    9: // Min
      c1^ := Min(c1^, c2^);
   10: // Multiply
      c1^ := c1^ * c2^;
   11: // Recolour
      If c1^ = 0 Then
        c1^ := T_PAPER And $FF
      Else
        c1^ := T_INK And $FF;
   12: // Add - limited
      c1^ := Min(c1^ + c2^, 255);
   13: // Subtract - limited
      c1^ := Max(c1^ - c2^, 0);
  End;

End;

Procedure SP_OverPixelPtrl(Var c1, c2: pLongWord; Over: Integer); inline;
Begin

  Case Over of
    1: // Xor
      c1^ := c1^ xor c2^;
    2: // Add
      c1^ := c1^ + c2^;
    3: // Subtract
      c1^ := c1^ - c2^;
    4: // And
      c1^ := c1^ And c2^;
    5: // Or
      c1^ := c1^ Or c2^;
    6: // Not
      c1^ := Not c1^;
    7: // Avg
      c1^ := (c1^ + c2^) Shr 1;
    8: // Max
      c1^ := Max(c1^, c2^);
    9: // Min
      c1^ := Min(c1^, c2^);
   10: // Multiply
      c1^ := c1^ * c2^;
   11: // Recolour
      If c1^ = 0 Then
        c1^ := T_PAPER
      Else
        c1^ := T_INK;
   12: // Add - limited
      c1^ := Min(c1^ + c2^, $FFFFFFFF);
   13: // Subtract - limited
      c1^ := Max(c1^ - c2^, 0);
  End;

End;

Procedure SP_OverPixelPtrVal(c1: pByte; c2: Byte; Over: Integer); inline;
Begin

  Case Over of
    1: // Xor
      c1^ := c1^ xor c2;
    2: // Add
      c1^ := c1^ + c2;
    3: // Subtract
      c1^ := c1^ - c2;
    4: // And
      c1^ := c1^ And c2;
    5: // Or
      c1^ := c1^ Or c2;
    6: // Not
      c1^ := Not c1^;
    7: // Avg
      c1^ := (c1^ + c2) Shr 1;
    8: // Max
      c1^ := Max(c1^, c2);
    9: // Min
      c1^ := Min(c1^, c2);
   10: // Multiply
      c1^ := c1^ * c2;
   11: // Recolour
      If c1^ = 0 Then
        c1^ := T_PAPER And $FF
      Else
        c1^ := T_INK And $FF;
   12: // Add - limited
      c1^ := Min(c1^ + c2, 255);
   13: // Subtract - limited
      c1^ := Max(c1^ - c2, 0);
  End;

End;

Procedure SP_DefaultFill(Var Str: aString; Clr: Byte); Inline;
Var
  Cl: LongWord;
  {$IFDEF CPU64}Cn: NativeUInt;{$ENDIF}
  Idx: Integer;
  dPtr: pByte;
Begin

  SetLength(Str, (SizeOf(LongWord) * 2) + SizeOf(Word) + 64);
  dPtr := pByte(pLongWord(@Str)^);

  pLongWord(dPtr)^ := 8;
  Inc(dPtr, SizeOf(LongWord));
  pLongWord(dPtr)^ := 8;
  Inc(dPtr, SizeOf(LongWord));

  pWord(dPtr)^ := 65535;
  Inc(dPtr, SizeOf(Word));

  {$IFDEF CPU64}
  Cl := (Clr Shl 24) + (Clr Shl 16) + (Clr Shl 8) + Clr;
  Cn := (NativeUInt(Cl) Shl 32) Or Cl;
  For Idx := 1 To 8 Do Begin
    pNativeInt(dPtr)^ := Cn;
    Inc(dPtr, SizeOf(NativeUInt));
  End;
  {$ELSE}
  Cl := (Clr Shl 24) + (Clr Shl 16) + (Clr Shl 8) + Clr;
  For Idx := 1 To 16 Do Begin
    pLongWord(dPtr)^ := Cl;
    Inc(dPtr, SizeOf(LongWord));
  End;
  {$ENDIF}

End;

Procedure SP_DRAWGW(Const str: aString; Var Error: TSP_ErrorCode);
Var
  DoPlot, Return, RelativeX, RelativeY: Boolean;
  LastNum, Xc, Yc: aFloat;
  LastString, Commands: aString;
  Len: NativeUInt;
  Idx: Integer;
  Ch: Byte;
  p: pByte;

  Procedure Draw(Dir: aFloat);
  Var
    Dist, Hdg, dX, dY, oDx, oDy: aFloat;
  Begin
    Dist := GWScaleFactor * LastNum;
    Hdg := DRHEADING;
    SP_AngleToRad(Hdg);
    Hdg := Hdg + Dir;

    dX := Dist * Cos(Hdg);
    dY := Dist * Sin(Hdg);
    SP_ConvertToOrigin_d(dX, dY);
    odX := DRPOSX;
    odY := DRPOSY;
    If WINFLIPPED Then dY := -dY;
    If DoPlot Then
      SP_DrawLine(dX, dY)
    Else Begin
      DRPOSX := DRPOSX + dX;
      DRPOSY := DRPOSY + dY;
    End;
    If Return Then Begin
      DRPOSX := odX;
      DRPOSY := odY;
    End;
    DoPlot := True;
    Return := False;
    SP_NeedDisplayUpdate := True;
  End;

  Procedure DrawCoords;
  Var
    oDx, oDy, dDx, dDy: aFloat;
  Begin
    odX := DRPOSX;
    odY := DRPOSY;
    SP_ConvertToOrigin_d(Xc, Yc);
    If RelativeX Then dDx := odX + Xc Else dDx := Xc;
    If RelativeY Then dDy := ody + Yc Else dDy := Yc;
    If WINFLIPPED Then Yc := (SCREENHEIGHT - 1) - Yc;
    If DoPlot Then
      SP_DrawLineTo(Round(oDx), Round(oDy), Round(dDx), Round(dDy), T_INK);
    If Return Then Begin
      DRPOSX := odX;
      DRPOSY := odY;
    End Else Begin
      DRPOSX := dDx;
      DRPOSY := dDY;
    End;
    DoPlot := True;
    Return := False;
    RelativeX := False;
    RelativeY := False;
    SP_NeedDisplayUpdate := True;
  End;

  Procedure Paint;
  Begin
    SP_GWFloodFill(SCREENPOINTER, Round(DRPOSX), Round(DRPOSY), SCREENSTRIDE, SCREENHEIGHT, Round(Xc), Round(Yc));
    DoPlot := True;
    Return := False;
    SP_NeedDisplayUpdate := True;
  End;

  Procedure GetVarName(IsString: Boolean);
  Begin
    LastString := '';
    While (NativeUInt(p) < Len) And (p^ in [Ord('A')..Ord('Z'), Ord('a')..Ord('z'), Ord('_'), Ord(' ')]) Do Begin
      LastString := LastString + aChar(p^);
      Inc(p);
    End;
    While (NativeUInt(p) < Len) And (p^ in [Ord('A')..Ord('Z'), Ord('a')..Ord('z'), Ord('_'), Ord('0')..Ord('9'), Ord(' ')]) Do Begin
      LastString := LastString + aChar(p^);
      Inc(p);
    End;
    If IsString And (p^ = Ord('$')) Then Begin LastString := LastString + '$'; Inc(p); End;
  End;

  Procedure GetNumber;
  Var
    Dv: aFloat;
    Dc: Integer;
    Neg: Boolean;
  Begin
    Neg := False;
    LastNum := 0;
    If (NativeUInt(p) < Len) And (p^ = Ord('=')) Then Begin
      Inc(p);
      GetVarName(False);
      Dc := SP_FindNumVar(Lower(LastString));
      If Dc > -1 Then Begin
        LastNum := NumVars[Dc]^.ContentPtr^.Value;
      End Else Begin
        Error.Code := SP_ERR_MISSING_VAR;
      End;
    End Else Begin
      While (NativeUInt(p) < Len) And (p^ in [Ord('+'), Ord('-')]) Do Begin
        If p^ = Ord('-') Then
          Neg := Not Neg;
        Inc(p);
      End;
      While (NativeUInt(p) < Len) And (p^ in [Ord('0')..Ord('9')]) Do Begin
        LastNum := (LastNum * 10) + p^ - 48;
        Inc(p);
      End;
      If NativeUint(p) < Len Then Begin
        If p^ = Ord('.') Then Begin
          Inc(p);
          Dv := 0; Dc := 10;
          While (NativeUint(p) < Len) And (p^ in [Ord('0')..Ord('9')]) Do Begin
            Dv := ((p^ - 48) / Dc) + Dv;
            Dc := Dc * 10;
            Inc(p);
          End;
          If Dv <> 0 Then
            LastNum := LastNum + Dv;
        End;
      End;
      if Neg Then LastNum := -LastNum;
    End;
  End;

  Procedure Pyth;
  Begin
    LastNum := Sqrt(LastNum*LastNum+LastNum*LastNum);
  End;

Begin

  DoPlot := True;
  Return := False;

  Commands := StripSpaces(Str);
  p := pByte(pNativeUInt(@Commands)^);
  Len := NativeUint(p) + Length(Commands);

  While NativeUInt(p) < Len Do Begin
    Ch := p^;
    If Ch in [97..122] Then
      Ch := Ch - 32;
    Case Ch of
      Ord('U'): // Up
        Begin
          Inc(p);
          GetNumber;
          Draw(-Pi/2);
        End;
      Ord('D'): // Down
        Begin
          Inc(p);
          GetNumber;
          Draw(Pi/2);
        End;
      Ord('L'): // Left
        Begin
          Inc(p);
          GetNumber;
          Draw(Pi);
        End;
      Ord('R'): // Right
        Begin
          Inc(p);
          GetNumber;
          Draw(0);
        End;
      Ord('E'): // Up+Right
        Begin
          Inc(p);
          GetNumber;
          Pyth;
          Draw(-Pi/4);
        End;
      Ord('F'): // Down+Right
        Begin
          Inc(p);
          GetNumber;
          Pyth;
          Draw(Pi/4);
        End;
      Ord('G'): // Down+Left
        Begin
          Inc(p);
          GetNumber;
          Pyth;
          Draw(-Pi*1.25);
        End;
      Ord('H'): // Up+Left
        Begin
          Inc(p);
          GetNumber;
          Pyth;
          Draw(Pi*1.25);
        End;
      Ord('M'): // Move
        Begin
          Inc(p);
          RelativeX := p^ in [Ord('-'), Ord('+')];
          GetNumber;
          Xc := LastNum;
          If p^ <> Ord(',') Then Exit Else Inc(p);
          RelativeY := p^ in [Ord('-'), Ord('+')];
          GetNumber;
          Yc := LastNum;
          If RelativeX Then Xc := Xc * GWScaleFactor;
          If RelativeY Then Yc := Yc * GWScaleFactor;
          DrawCoords;
        End;
      Ord('B'): // Don't plot pixels
        Begin
          Inc(p);
          DoPlot := False;
        End;
      Ord('N'): // Return to start after draw
        Begin
          Inc(p);
          Return := True;
        End;
      Ord('A'): // Set Angle, 0 to 3 for each quadrant
        Begin
          Inc(p);
          GetNumber;
          DRHEADING := -LastNum * (Pi / 2);
        End;
      Ord('T'): // Set an angle in degrees (0 to 359)
        Begin
          Inc(p);
          If p^ in [Ord('A'), Ord('a')] Then Inc(p);
          GetNumber;
          DRHEADING := -DegToRad(LastNum);
          SP_RadToAngle(DRHEADING);
        End;
      Ord('C'): // Set Colour (INK)
        Begin
          Inc(p);
          GetNumber;
          CINK := Round(LastNum); // Persist between DRAW statements
          T_INK := CINK;
        End;
      Ord('S'): // Set Scaling. Divide by 4.
        Begin
          Inc(p);
          GetNumber;
          GWScaleFactor := LastNum / 4;
        End;
      Ord('P'): // Paint fill colour,boundary colour
        Begin
          Inc(p);
          GetNumber;
          Xc := LastNum;
          If p^ <> Ord(',') Then Exit Else Inc(p);
          GetNumber;
          Yc := LastNum;
          Paint;
        End;
      Ord('X'): // Execute string variable
        Begin
          Inc(p);
          GetVarName(True);
          If (LastString <> '') And (LastString[Length(LastString)] = '$') Then Begin
            Idx := SP_FindStrVar(Lower(Copy(LastString, 1, Length(LastString) -1)));
            If Idx > -1 Then Begin
              LastString := StrVars[Idx]^.ContentPtr^.Value;
              SP_DRAWGW(LastString, Error);
            End Else Begin
              Error.Code := SP_ERR_MISSING_VAR;
            End;
          End Else
            Error.Code := SP_ERR_MISSING_VAR;
        End;
    Else // Skip garbage chars and whitespace
      Inc(p);
    End;
    If Error.Code <> SP_ERR_OK Then
      Exit;
  End;

End;

Initialization

  ITALICSCALE := 4;
  DisplaySection := TCriticalSection.Create;

Finalization

  DisplaySection.Free;

end.



