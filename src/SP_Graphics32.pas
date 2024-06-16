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

unit SP_Graphics32;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}

interface

Uses SP_Util, SP_SysVars, SP_BankManager, SP_BankFiling, SP_Graphics, SP_Errors, Math, SP_Menu, SP_Components, SP_Tokenise;

  // This unit handles all graphics routines that are dedicated to 32bit graphics,
  // and routines that convert between 32 and 8 bit.

  // 32 bit graphics, due to needing to throw around 4x as much data, are slower than
  // 8bit. 8Bit is the default. Due to this, more processing is needed to reduce the amount
  // of drawing that the compositor will have to do.

Type

  spRect = Packed Record
    sPtr: pSP_Window_Info;
    bx1, by1, bx2, by2: NativeInt;
  End;

  RGBA = Packed Record
    B, G, R, A: Byte;
  End;

  Procedure SP_Composite32(Dest: Pointer; X1, Y1, X2, Y2: Integer);
  Procedure SP_GetRegion32(Src: pLongWord; SrcW, SrcH: LongWord; Var Dest: aString; rX, rY, rW, rH: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_PutRegion8to32(Dst: pLongWord; dX, dY: Integer; dW, dH: LongWord; Src: pByte; SrcLen: Integer; Palette: pPalArray; RotAngle, Scale: aFloat; Var cX1, cY1, cX2, cY2: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_PutRegion32to32(Dst: pByte; dX, dY: Integer; dW, dH: LongWord; Src: pByte; SrcLen: Integer; RotAngle, Scale: aFloat; Var cX1, cY1, cX2, cY2: Integer; Var Error: TSP_ErrorCode);
  Procedure SP_PutRegion_NO_OVER32To32(Dst: pLongWord; dX, dY: Integer; dW, dH: LongWord; Src: pLongWord; SrcLen: Integer; Var cX1, cY1, cX2, cY2: Integer; Var Error: TSP_ErrorCode);

  Function  IntersectRect(ax1,ay1,ax2,ay2,bx1,by1,bx2,by2: Integer): Integer;
  Function  SP_AlphaBlend(PixelA, PixelB: LongWord): LongWord; inline;

  Procedure SP_SetPixel32(X, Y: aFloat); Inline;
  Procedure SP_SetPixelPtr32(Ptr: pLongWord); Inline;
  Procedure SP_SetPixelPtrClr32(Ptr: pLongWord; Ink: LongWord); Inline;
  Procedure SP_SetPixelClr32(X, Y: aFloat; Ink: LongWord); Inline;

  Procedure SP_SetPixel32Alpha(X, Y: aFloat); Inline;
  Procedure SP_SetPixelPtr32Alpha(Ptr: pLongWord); Inline;
  Procedure SP_SetPixelPtrClr32Alpha(Ptr: pLongWord; Ink: LongWord); Inline;
  Procedure SP_SetPixelClr32Alpha(X, Y: aFloat; Ink: LongWord); Inline;

  Procedure SP_Scroll32(Dy: Integer);
  Procedure SP_HScroll32(Dst: pByte; Width, Height, Amount: Integer; Wrap: Boolean);
  procedure SP_VScroll32(Dst: pByte; Width, Height, Amount: Integer; Wrap: Boolean);
  Procedure SP_FillRect32(X, Y, W, H: Integer; Colour: LongWord);
  Procedure SP_DrawLine32(X2, Y2: aFloat);
  Procedure SP_DrawSpeccyCurve32(X, Y, Angle: aFloat);
  Procedure SP_DrawSpeccyCurve32Alpha(X, Y, Angle: aFloat);
  Procedure SP_DrawCurve32(CurveStartX, CurveStartY, X, Y, CurveEndX, CurveEndY: aFloat; N: Integer);
  Procedure SP_DrawCurve32Alpha(CurveStartX, CurveStartY, X, Y, CurveEndX, CurveEndY: aFloat; N: Integer);
  Procedure SP_DrawEllipse32(CX, CY, Rx, Ry: Integer);
  Procedure SP_DrawThickEllipse32(CX, CY, R1, R2: Integer);
  Procedure SP_DrawTexEllipse8To32(CX, CY, Rx, Ry: Integer; const TextureStr: aString; tW, tH: LongWord);
  Procedure SP_DrawTexEllipse32To32(CX, CY, Rx, Ry: Integer; const TextureStr: aString; tW, tH: LongWord);
  Procedure SP_DrawTexEllipse32Alpha(CX, CY, Rx, Ry: Integer; TextureStr: aString; tW, tH: LongWord);
  Procedure SP_DrawSolidEllipse32(CX, CY, Rx, Ry: Integer);
  Procedure SP_FillRect32Alpha(X, Y, W, H: Integer; Colour: LongWord);
  Procedure SP_DrawLine32Alpha(X2, Y2: aFloat);
  Procedure SP_DrawEllipse32Alpha(CX, CY, Rx, Ry: Integer);
  Procedure SP_DrawThickEllipse32Alpha(CX, CY, R1, R2: Integer);
  Procedure SP_DrawSolidEllipse32Alpha(CX, CY, Rx, Ry: Integer);
  Procedure SP_DrawRectangle32(X1, Y1, X2, Y2: Integer);
  Procedure SP_DrawRectangle32Alpha(X1, Y1, X2, Y2: Integer);
  Procedure SP_DrawSolidRectangle32(X1, Y1, X2, Y2: Integer);
  Procedure SP_DrawSolidRectangle32Alpha(X1, Y1, X2, Y2: Integer);
  Procedure SP_DrawTexRectangle32Alpha(X1, Y1, X2, Y2: Integer; TextureStr: aString; tW, tH: LongWord);
  Procedure SP_FloodFill32(Dst: pLongWord; dX, dY, dW, dH, Clr: LongWord);
  Procedure SP_FloodFill32Alpha(Dst: pLongWord; dX, dY, dW, dH, Clr: LongWord);
  Procedure SP_PolygonFill32Alpha(Var Points: Array of TSP_Point; TextureStr: aString; tW, tH: LongWord);
  Procedure SP_PolygonSolidFill32(Var Points: Array of TSP_Point; MinX, MinY, MaxX, MaxY: Integer; Ink: LongWord; OutLine: Boolean);
  Procedure SP_PolygonSolidFill32Alpha(Var Points: Array of TSP_Point; Outline: Boolean);
  Procedure SP_CLS32(Paper: LongWord);

  Function  SP_PRINT32(BankID, X, Y, CPos: Integer; const Text: aString; Ink, Paper: LongWord; var Error: TSP_ErrorCode): Integer;
  Function  SP_PRINT32Alpha(BankID, X, Y, CPos: Integer; const Text: aString; Ink, Paper: LongWord; var Error: TSP_ErrorCode): Integer;
  Function  SP_TextOut32(BankID, X, Y: Integer; const Text: aString; Ink, Paper: LongWord; Visible: Boolean): Integer;
  Function  SP_TextOut32Alpha(BankID, X, Y: Integer; const Text: aString; Ink, Paper: LongWord; Visible: Boolean): Integer;
  Function  SP_RawTextOut(BankID: Integer; Dest: pLongWord; dW, dH, X, Y: Integer; const Text: aString; Ink, Paper: LongWord; ScaleX, ScaleY: aFloat; Trans, Alpha: Boolean): Integer;
  Procedure SP_DrawStripe32(Dst: pLongWord; Width, StripeWidth, StripeHeight: Integer);

Var

  SP_BackBuffer32: Array of LongWord;
  UpdateRects: Array[0..255] of spRect;
  MaxRect: Integer;

implementation

Uses SP_Main, SP_Interpret_PostFix;

Function IntersectRect(ax1,ay1,ax2,ay2,bx1,by1,bx2,by2: Integer): Integer;
Begin

  // Returns a code if the two rectangles intersect - rects are a and b, and are
  // described by their corner coordinates.

  // The code is a 4bit value, and describes one of the 16 possibilities of intersection.
  // Returns -1 if no intersection.

  If (ax1 < bx2) And (bx1 < ax2) And (ay1 < by2) and (by1 < ay2) Then
    Result := (Byte(ax1 > bx1) Shl 1) + (Byte(ax2 > bx2)) + (Byte(ay1 > by1) Shl 3) + (Byte(ay2 > by2) Shl 2)
  Else
    Result := -1;

End;

Procedure SP_GenerateRects(CX1, CY1, CX2, CY2: Integer);
Var
  Idx, TopRect, nCX1, nCY1, nCX2, nCY2, x, y, w, h: NativeInt;
  Window: pSP_Window_Info;

  Procedure ClipToView(Var x1, y1, x2, y2: NativeInt);
  Begin
    x1 := Max(x1, nCX1);
    y1 := Max(y1, nCY1);
    x2 := Min(x2, nCX2);
    y2 := Min(y2, nCY2);
  End;

  Procedure Subdivide(ax1,ay1,ax2,ay2: NativeInt);
  Var
    Idx: NativeInt;
    Split: Boolean;
  Begin

    If IntersectRect(ax1,ay1,ax2,ay2,CX1,CY1,CX2,CY2) <> -1 Then Begin

      Split := False;
      Idx := TopRect -1;
      While Idx >= 0  Do Begin
        With UpdateRects[Idx] Do Begin
          If (sPtr^.Transparent = $FFFF) And Not (sPtr^.AlphaEnabled) Then
            Case IntersectRect(ax1,ay1,ax2,ay2,bx1,by1,bx2,by2) Of
              $0:
                Begin
                  Split := True;
                  Subdivide(ax1,ay1,ax2,by1-1);
                  Subdivide(ax1,by1,bx1-1,ay2);
                End;
              $1:
                Begin
                  Split := True;
                  Subdivide(ax1,ay1,ax2,by1-1);
                  Subdivide(ax1,by1,bx1-1,ay2);
                  Subdivide(bx2+1,by1,ax2,ay2);
                End;
              $2:
                Begin
                  Split := True;
                  Subdivide(ax1,ay1,ax2,by1-1);
                End;
              $3:
                Begin
                  Split := True;
                  Subdivide(ax1,ay1,ax2,by1-1);
                  Subdivide(bx2+1,by1,ax2,ay2);
                End;

              $4:
                Begin
                  Split := True;
                  Subdivide(ax1,ay1,ax2,by1-1);
                  Subdivide(ax1,by1,bx1-1,by2-1);
                  Subdivide(ax1,by2,ax2,ay2);
                End;
              $5:
                Begin
                  Split := True;
                  Subdivide(ax1,ay1,ax2,by1-1);
                  Subdivide(ax1,by1,bx1-1,by2);
                  Subdivide(bx2+1,by1,ax2,by2);
                  Subdivide(ax1,by2+1,ax2,ay2);
                End;
              $6:
                Begin
                  Split := True;
                  Subdivide(ax1,ay1,ax2,by1-1);
                  Subdivide(ax1,by2+1,ax2,ay2);
                End;
              $7:
                Begin
                  Split := True;
                  Subdivide(ax1,ay1,ax2,by1-1);
                  Subdivide(bx2+1,by1,ax2,by2);
                  Subdivide(ax1,by2+1,ax2,ay2);
                End;

              $8:
                Begin
                  Split := True;
                  Subdivide(ax1,ay1,bx1-1,ay2);
                End;
              $9:
                Begin
                  Split := True;
                  Subdivide(ax1,ay1,bx1-1,ay2);
                  Subdivide(bx2+1,ay1,ax2,ay2);
                End;
              $A:
                Begin
                  Split := True;
                End;
              $B:
                Begin
                  Split := True;
                  Subdivide(bx2+1,ay1,ax2,ay2);
                End;

              $C:
                Begin
                  Split := True;
                  Subdivide(ax1,ay1,bx1-1,by2);
                  Subdivide(ax1,by2+1,ax2,ay2);
                End;
              $D:
                Begin
                  Split := True;
                  Subdivide(ax1,ay1,bx1-1,by2);
                  Subdivide(bx1+1,ay1,ax2,by2);
                  Subdivide(ax1,by2+1,ax2,ay2);
                End;
              $E:
                Begin
                  Split := True;
                  Subdivide(ax1,by2+1,ax2,ay2);
                End;
              $F:
                Begin
                  Split := True;
                  Subdivide(bx2+1,ay1,ax2,by2);
                  Subdivide(ax1,by2+1,ax2,ay2);
                End;

            End;
        End;
        Dec(Idx);
        If Split Then Break;
      End;

      If Not Split Then Begin
        With UpdateRects[TopRect] Do Begin
          sPtr := Window;
          bx1 := ax1; by1 := ay1; bx2 := ax2; by2 := ay2;
          ClipToView(bx1, by1, bx2, by2);
        End;
        Inc(TopRect);
      End;

    End;

  End;

Begin

  // Start by adding the last visible window to the output list. Clip as we go.

  nCX1 := Max(CX1, 0);
  nCY1 := Max(CY1, 0);
  nCX2 := Min(CX2, DISPLAYWIDTH -1);
  nCY2 := Min(CY2, DISPLAYHEIGHT -1);

  MaxRect := 0;
  TopRect := 0;
  Idx := Length(SP_BankList) -1;

  While Idx >= 0 Do Begin

    While SP_BankList[Idx]^.DataType <> SP_WINDOW_BANK Do Dec(Idx); // Should never fail - there will always be a window in bank zero.
    Window := @SP_BankList[Idx].Info[0];

    If Window^.Visible And (IntersectRect(Window^.Left, Window^.Top, Window^.Left + Window^.Width -1, Window^.Top + Window^.Height -1, CX1, CY1, CX2, CY2) <> -1) Then Begin
      With UpdateRects[0] Do Begin
        sPtr := Window;
        bx1 := Sptr^.Left; by1 := sPtr^.Top; bx2 := bx1+sPtr^.Width-1; by2 := by1+sPtr^.Height-1;
        ClipToView(bx1, by1, bx2, by2);
        If sPtr^.Transparent = $FFFF Then
          If (bx1 <= CX1) And (by1 <= CY1) And (bx2 >= CX2) And (by2 >= CY2) Then Begin
            MaxRect := TopRect +1;
            Exit;
          End;
      End;
      Inc(TopRect);
      Dec(Idx); // skip this window, as we've now done it.
      Break;
    End;
    Dec(Idx);

  End;

  // Now, if there are any windows left, call the subdivide() procedure for each until done.

  While Idx >= 0 Do Begin

    While (Idx >= 0) And (SP_BankList[Idx]^.DataType <> SP_WINDOW_BANK) Do Dec(Idx);
    Window := @SP_BankList[Idx].Info[0];

    With Window^ Do
      If Visible Then Begin
        x := Left; y := Top; w := x + Width -1; h := y + Height -1;
        ClipToView(x, y, w, h);
        SubDivide(x, y, w, h);
        If Transparent = $FFFF Then
          If (Left <= CX1) And (Top <= CY1) And (Left + Width -1 >= CX2) And (Top + Height -1 >= CY2) Then Begin
            MaxRect := TopRect;
            Exit;
          End;
      End;
    Dec(Idx);

  End;

  // All done - the output list contains a list of rectangles from windows that don't
  // overlap.

  MaxRect := TopRect;

End;

Procedure SP_Composite32(Dest: Pointer; X1, Y1, X2, Y2: Integer);
Var
  Idx, Width, Height, tw, add1, add2, LastWindowID: Integer;
  dstPtr, srcPtr: pLongWord;
  Sprite: pSP_Sprite_Info;
  Alpha: LongWord;
  Trans: Byte;

  Function IsWindowVisible(sPtr: pSP_Window_Info): Boolean;
  Begin

    Result := IntersectRect(0, 0, DISPLAYWIDTH -1, DISPLAYHEIGHT -1, sPtr^.Left, sPtr^.Top, sPtr^.Left + sPtr^.Width -1, sPtr^.Top + sPtr^.Height -1) <> -1;

  End;

  Function InRange(a, b, c: Integer): Integer;
  Begin
      Result := Max(Min(a, c), b);
  End;

  procedure hilight(j, x1, y1, x2, y2: Integer);
  var
    i:Integer;
    d: pLongWord;
    c: Longword;
  Begin
    inc(j);
    c := (DefaultPalette[j].R shl 16)+(DefaultPalette[j].R shl 8)+(DefaultPalette[j].B);
    d := pLongWord(NativeUInt(Dest) + (y1 * Integer(DISPLAYSTRIDE)) + (x1 * SizeOf(RGBA)));
    for i:=x1 to x2 do Begin d^ := c; inc(d); end;
    d := pLongWord(NativeUInt(Dest) + (y1 * Integer(DISPLAYSTRIDE)) + (x1 * SizeOf(RGBA)));
    for i:=y1 to y2 do Begin d^ := c; inc(d,DISPLAYSTRIDE Div 4); end;
    d := pLongWord(NativeUInt(Dest) + (y1 * Integer(DISPLAYSTRIDE)) + ((x2-1) * SizeOf(RGBA)));
    for i:=y1 to y2 do Begin d^ := c; inc(d,DISPLAYSTRIDE Div 4); end;
    d := pLongWord(NativeUInt(Dest) + ((y2-1) * Integer(DISPLAYSTRIDE)) + ((x2-1) * SizeOf(RGBA)));
    for i:=x1 to x2 do Begin d^ := c; inc(d); end;
  End;


Begin

  // Builds the display using the UpdateRects[] array of non-overlapping rectangles.

  X1 := InRange(x1, 0, DISPLAYWIDTH);
  x2 := InRange(x2, 0, DISPLAYWIDTH);
  y1 := InRange(y1, 0, DISPLAYHEIGHT);
  y2 := InRange(y2, 0, DISPLAYHEIGHT);

  SCRUPDATENOW := True;

  If NUMWINDOWS = 1 Then Begin
    MaxRect := 1;
    With UpdateRects[0] Do Begin
      sPtr := @SP_BankList[0].Info[0];
      bx1 := Max(X1, 0);
      by1 := Max(Y1, 0);
      bx2 := Min(X2 -1, DISPLAYWIDTH -1);
      by2 := Min(Y2 -1, DISPLAYHEIGHT -1);
    End;
  End Else
    SP_GenerateRects(X1, Y1, X2, Y2);

  LastWindowID := -1;

  For Idx := MaxRect -1 DownTo 0 Do

    If IsWindowVisible(UpdateRects[Idx].sPtr) Then With UpdateRects[Idx] Do Begin

      Width := (bx2 - bx1) +1;
      Height := (by2 - by1) +1;

      {$IFDEF FPC}
      DispRects[GfxUpdRect].w := Width;
      DispRects[GfxUpdRect].h := Height;
      DispRects[GfxUpdRect].x := bx1;
      DispRects[GfxUpdRect].y := by1;
      Inc(GfxUpdRect);
      {$ENDIF}

      DstPtr := Dest;
      If (sPtr^.SpriteCount > 0) or (sPtr^.Component.ControlCount > 0) Then Begin
        If sPtr^.ID <> LastWindowID Then Begin
          tw := sPtr^.Width * sPtr^.Height;
          If Length(SP_BackBuffer32) <> tw Then
            SetLength(SP_BackBuffer32, tw);
          dstPtr := @SP_BackBuffer32[0];
          CopyMem(dstPtr, sPtr^.Surface, tw);
        End;
        srcPtr := pLongWord(NativeUInt(@SP_BackBuffer32[0]));
      End Else
        SrcPtr := pLongWord(NativeUInt(sPtr^.Surface));

      If sPtr^.bpp = 8 Then Begin

        If sPtr^.ID <> LastWindowID Then Begin

          If sPtr^.SpriteCount > 0 Then Begin

            SP_BlockSprites;
            DRAWINGSPRITES := True;

            tw := 0;
            While tw < Length(WindowSpriteList[sPtr^.ID]) Do Begin
              Sprite := WindowSpriteList[sPtr^.ID][tw];
              If Assigned(Sprite) And Sprite^.Enabled Then
                SP_DrawSprite(pByte(dstPtr), Sprite, sPtr);
              Inc(tw);
            End;

            DRAWINGSPRITES := False;
            SP_UnblockSprites;

          End;

        End;

        // Render any controls the window may have attached

        If sPtr^.ID <> LastWindowID Then
          If sPtr^.Component.ControlCount > 0 Then
            sPtr^.Component.Render(pByte(srcPtr), sPtr^.Width, sPtr^.Height);

        Inc(pByte(SrcPtr), ((by1 - sPtr^.Top) * sPtr^.Stride));
        Inc(pByte(SrcPtr), bx1 - sPtr^.Left);

        dstPtr := pLongWord(NativeUInt(Dest) + (by1 * DISPLAYSTRIDE) + (bx1 * SizeOf(RGBA)));

        LastWindowID := sPtr^.ID;

        add1 := LongWord(sPtr^.Stride - Width);
        add2 := Integer(DISPLAYSTRIDE) - (Width * SizeOf(RGBA));

        If sPtr^.Transparent = $FFFF Then Begin

          While Height > 0 Do Begin
            tw := Width;
            While tw > 0 Do Begin
              dstPtr^ := sPtr^.Palette[pByte(srcPtr)^].L;
              Dec(tw);
              Inc(pByte(srcPtr));
              Inc(dstPtr);
            End;
            Inc(pByte(dstPtr), add2);
            Inc(pByte(srcPtr), add1);
            Dec(Height);
          End;

        End Else Begin

          Trans := sPtr^.Transparent And $FF;

          While Height > 0 Do Begin
            tw := Width;
            While tw > 0 Do Begin
              If pByte(srcPtr)^ <> Trans Then
                dstPtr^ := sPtr^.Palette[pByte(srcPtr)^].L;
              Dec(tw);
              Inc(pByte(srcPtr));
              Inc(dstPtr);
            End;
            Inc(pByte(dstPtr), add2);
            Inc(pByte(srcPtr), add1);
            Dec(Height);
          End;

        End;

      End Else Begin

        // 32bpp window - optional alpha transparency per pixel and per window.

        SrcPtr := pLongWord(NativeUInt(sPtr^.Surface));
        Inc(pByte(SrcPtr), ((by1 - sPtr^.Top) * sPtr^.Stride));
        Inc(pByte(SrcPtr), ((bx1 - sPtr^.Left) * SizeOf(RGBA)));
        dstPtr := pLongWord(NativeUInt(Dest) + (by1 * DISPLAYSTRIDE) + (bx1 * SizeOf(RGBA)));

        add1 := LongWord(sPtr^.Stride - (Width * (sPtr^.bpp Div 8)));
        add2 := Integer(DISPLAYSTRIDE) - (Width * SizeOf(RGBA));

        If sPtr^.Transparent = $FFFF Then Begin

          // No per-window alpha transparency.

          If sPtr^.AlphaEnabled Then Begin

            While Height > 0 Do Begin
              tw := Width;
              While tw > 0 Do Begin
                dstPtr^ := SP_AlphaBlend(dstPtr^, srcPtr^);
                Dec(tw);
                Inc(pLongWord(srcPtr));
                Inc(dstPtr);
              End;
              Inc(pByte(dstPtr), add2);
              Inc(pByte(srcPtr), add1);
              Dec(Height);
            End;

          End Else Begin

            While Height > 0 Do Begin
              tw := Width;
              {$IFDEF CPU64}
              While tw > SizeOf(NativeUInt) Do Begin
                pNativeUInt(dstPtr)^ := pNativeUInt(srcPtr)^;
                Dec(tw, SizeOf(NativeUInt) Div SizeOf(LongWord));
                Inc(pNativeUInt(SrcPtr));
                Inc(pNativeUInt(dstPtr));
              End;
              {$ENDIF}
              While tw > 0 Do Begin
                dstPtr^ := pLongWord(srcPtr)^;
                Dec(tw);
                Inc(pLongWord(srcPtr));
                Inc(dstPtr);
              End;
              Inc(pByte(dstPtr), add2);
              Inc(pByte(srcPtr), add1);
              Dec(Height);
            End;

          End;

        End Else Begin

          Alpha := (sPtr^.Transparent And $FF) Shl 24;

          // Transparent. Either window-level or per-pixel... or both.

          If sPtr^.AlphaEnabled Then Begin

            While Height > 0 Do Begin
              tw := Width;
              While tw > 0 Do Begin
                dstPtr^ := SP_AlphaBlend(SP_AlphaBlend(dstPtr^, SrcPtr^), dstPtr^ and $00FFFFFF or Alpha);
                Dec(tw);
                Inc(pLongWord(srcPtr));
                Inc(dstPtr);
              End;
              Inc(pByte(dstPtr), add2);
              Inc(pByte(srcPtr), add1);
              Dec(Height);
            End;

          End Else Begin

            While Height > 0 Do Begin
              tw := Width;
              While tw > 0 Do Begin
                dstPtr^ := SP_AlphaBlend(dstPtr^, (srcPtr^ And $00FFFFFF) Or Alpha);
                Dec(tw);
                Inc(pLongWord(srcPtr));
                Inc(dstPtr);
              End;
              Inc(pByte(dstPtr), add2);
              Inc(pByte(srcPtr), add1);
              Dec(Height);
            End;

          End;

        End;

      End;

    End;

  If CURMENU > -1 Then SP_DrawMainMenu(Dest, DISPLAYWIDTH, DISPLAYHEIGHT, CURMENU);

  SCRUPDATENOW := False;

End;

Procedure SP_GetRegion32(Src: pLongWord; SrcW, SrcH: LongWord; Var Dest: aString; rX, rY, rW, rH: Integer; Var Error: TSP_ErrorCode);
Var
  W, sW: LongWord;
  Dst: pLongWord;
Begin

  sW := SrcW Div SizeOf(RGBA);
  rX := Max(Rx, 0);
  rY := Max(Ry, 0);
  If rX + rW > Integer(sW) Then
    rW := Integer(sW) - rX;
  If rY + rH > Integer(SrcH) Then
    rH := Integer(SrcH) - rY;
  If (rW <= 0) or (rH <= 0) or (rW > integer(sW)) or (rH > integer(SrcH)) Then Begin
    Error.Code := SP_ERR_INVALID_REGION;
    Exit;
  End;

  SetLength(Dest, rW * rH * SizeOf(RGBA));
  Dest := LongWordToString(rW) + LongWordToString(rH) + #255 + #32 + Dest;
  Dst := @Dest[3 + (SizeOf(LongWord) * 2)];

  Src := pLongWord(NativeUInt(Src) + (Ry * Integer(SrcW)) + (Rx * SizeOf(RGBA)));

  While rH > 0 Do Begin

    W := rW;
    {$IFDEF CPU64}
    While W > SizeOf(NativeUInt) Do Begin
      pNativeUInt(Dst)^ := pNativeUInt(Src)^;
      Dec(W, SizeOf(NativeUInt) Div SizeOf(LongWord));
      Inc(pNativeUInt(Dst));
      Inc(pNativeUInt(Src));
    End;
    {$ENDIF}
    While W > 0 Do Begin
      Dst^ := Src^;
      Inc(Dst);
      Inc(Src);
      Dec(W);
    End;
    Dec(rH);
    Dec(Src, rW);
    Inc(Src, sW);

  End;

End;

Procedure SP_PutRegion8to32(Dst: pLongWord; dX, dY: Integer; dW, dH: LongWord; Src: pByte; SrcLen: Integer; Palette: pPalArray; RotAngle, Scale: aFloat; Var cX1, cY1, cX2, cY2: Integer; Var Error: TSP_ErrorCode);
Var
  W, W2, H, SrcX, SrcY, SrcW, SrcH: LongWord;
  TransparentColour: Word;
  TC: Byte;
  Graphic: pSP_Graphic_Info;
Begin

  If Dst = Nil Then Exit;

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
//    SP_RotateSize(Src, W, H, Dst, dX, dY, dW, dH, TransparentColour, RotAngle, Scale, cX1, cY1, cX2, cY2)
  Else Begin
    dW := dW Div SizeOf(RGBA);
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
          If Src^ <> TC Then Dst^ := pLongWord(NativeUInt(Palette) + (Src^ Shl 2))^;
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
          Dst^ := pLongWord(NativeUInt(Palette) + (Src^ Shl 2))^;
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

  SP_BankList[0]^.Changed := True;

End;

Procedure SP_PutRegion_NO_OVER32To32(Dst: pLongWord; dX, dY: Integer; dW, dH: LongWord; Src: pLongWord; SrcLen: Integer; Var cX1, cY1, cX2, cY2: Integer; Var Error: TSP_ErrorCode);
Var
  W, W2, H, SrcX, SrcY, SrcW, SrcH: LongWord;
  Graphic: pSP_Graphic_Info;
Begin

  If Dst = Nil Then Exit;

  If SrcLen >= 10 Then Begin
    W := pLongWord(Src)^;
    Inc(Src);
    H := pLongWord(Src)^;
    Inc(Src);
    If SrcLen - 10 = Integer(W*H*SizeOf(RGBA)) Then Begin
      Inc(pByte(Src), SizeOf(Word));
    End Else Begin
      Error.Code := SP_ERR_INVALID_GRAB_STRING;
      Exit;
    End;
  End Else
    If SrcLen < 0 Then Begin
      Graphic := pSP_Graphic_Info(Src);
      Src := pLongWord(Graphic^.Data);
      W := Graphic^.Width;
      H := Graphic^.Height;
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

  Src := pLongWord(NativeUInt(Src) + (W * SrcY * SizeOf(RGBA)) + (SrcX * SizeOf(RGBA)));
  Dst := pLongWord(NativeUInt(Dst) + (Integer(dW) * Dy) + (dX * SizeOf(RGBA)));

  While SrcH > 0 Do Begin
    W2 := SrcW;
    {$IFDEF CPU64}
    While W2 > SizeOf(NativeUInt) Do Begin
      pNativeUInt(Dst)^ := pNativeUInt(Src)^;
      Dec(W2, SizeOf(NativeUInt) Div SizeOf(LongWord));
      Inc(pNativeUInt(Dst));
      Inc(pNativeUInt(Src));
    End;
    {$ENDIF}
    While W2 > 0 Do Begin
      Dst^ := Src^;
      Dec(W2);
      Inc(Dst);
      Inc(Src);
    End;
    Inc(pByte(Dst), dW - (SrcW * SizeOf(RGBA)));
    Inc(Src, W - SrcW);
    Dec(SrcH);
  End;

  SP_BankList[0]^.Changed := True;

End;

Function SP_AlphaBlend(PixelA, PixelB: LongWord): LongWord; inline;
Var
  A: Byte;
Begin

  // PixelA is the background, and its alpha is ignored. PixelB's Alpha is used.

  {$R-}
  A := 255 - RGBA(PixelB).A;

  RGBA(Result).R := (A * (RGBA(PixelA).R - RGBA(PixelB).R) Shr 8) + RGBA(PixelB).R;
  RGBA(Result).G := (A * (RGBA(PixelA).G - RGBA(PixelB).G) Shr 8) + RGBA(PixelB).G;
  RGBA(Result).B := (A * (RGBA(PixelA).B - RGBA(PixelB).B) Shr 8) + RGBA(PixelB).B;
  RGBA(Result).A := A;
  {$R+}

End;

Procedure SP_FillRect32(X, Y, W, H: Integer; Colour: LongWord);
Var
  Ptr, nxtLin: pLongWord;
  Idx, W2: LongWord;
Begin

  // Fills a rectangle with the specified colour

  Ptr := SCREENPOINTER;
  Inc(Ptr, X + (Y * pSP_Window_Info(WINDOWPOINTER)^.Width));

  for Idx := 0 To H -1 Do Begin
    nxtLin := Ptr;
    W2 := W;
    {$IFDEF CPU64}
    While W2 > SizeOf(NativeUInt) Do Begin
      pNativeUInt(Ptr)^ := (NativeUInt(Colour) Shl 32) + Colour;
      Dec(W2, SizeOf(NativeUInt) Div SizeOf(LongWord));
      Inc(pNativeUInt(Ptr));
    End;
    {$ENDIF}
    While W2 > 0 do Begin
      Ptr^ := Colour;
      Inc(Ptr);
      Dec(W2);
    End;
    Ptr := pLongWord(NativeUInt(nxtLin) + longword(SCREENSTRIDE));
  End;

End;

Procedure SP_FillRect32Alpha(X, Y, W, H: Integer; Colour: LongWord);
Var
  Ptr: pLongWord;
  Idx, W2, Add: LongWord;
Begin

  // Fills a rectangle with the specified colour

  Ptr := SCREENPOINTER;
  Inc(Ptr, X + (Y * pSP_Window_Info(WINDOWPOINTER)^.Width));

  Add := pSP_Window_Info(WINDOWPOINTER)^.Width - W;

  for Idx := 0 To H -1 Do Begin
    W2 := W;
    While W2 > 0 do Begin
      Ptr^ := SP_AlphaBlend(Ptr^, Colour);
      Inc(Ptr);
      Dec(W2);
    End;
    Inc(Ptr^, Add);
  End;

End;

Procedure SP_SetPixel32(X, Y: aFloat); Inline;
Var
  Ink: LongWord;
Begin

  If T_INVERSE = 0 Then
    Ink := T_INK
  Else
    Ink := T_PAPER;
  If (X >= T_CLIPX1) And (X < T_CLIPX2) And (Y >= T_CLIPY1) And (Y < T_CLIPY2) Then
    pLongWord(NativeUInt(SCREENPOINTER)+(LongWord(Round(Y) * SCREENSTRIDE) + LongWord(Round(X) * SizeOf(RGBA))))^ := Ink;

  DRPOSX := X;
  DRPOSY := Y;

End;

Procedure SP_SetPixelPtr32(Ptr: pLongWord); Inline;
Begin

  If T_INVERSE = 0 Then
    Ptr^ := T_INK
  Else
    Ptr^ := T_PAPER;

End;

Procedure SP_SetPixelPtrClr32(Ptr: pLongWord; Ink: LongWord); Inline;
Begin

  Ptr^ := Ink;

End;

Procedure SP_SetPixelClr32(X, Y: aFloat; Ink: LongWord); Inline;
Begin

  If (X >= T_CLIPX1) And (X < T_CLIPX2) And (Y >= T_CLIPY1) And (Y < T_CLIPY2) Then
    pLongWord(NativeUInt(SCREENPOINTER)+(LongWord(Round(Y) * SCREENSTRIDE) + LongWord(Round(X) * SizeOf(RGBA))))^ := Ink;

  DRPOSX := X;
  DRPOSY := Y;

End;

Procedure SP_SetPixel32Alpha(X, Y: aFloat); Inline;
Var
  Ink: LongWord;
  Ptr: pLongWord;
Begin

  If T_INVERSE = 0 Then
    Ink := T_INK
  Else
    Ink := T_PAPER;
  If (X >= T_CLIPX1) And (X < T_CLIPX2) And (Y >= T_CLIPY1) And (Y < T_CLIPY2) Then Begin
    Ptr := pLongWord(NativeUInt(SCREENPOINTER)+(LongWord(Round(Y) * SCREENSTRIDE) + LongWord(Round(X) * SizeOf(RGBA))));
    Ptr^ := SP_AlphaBlend(Ptr^, Ink);
  End;

  DRPOSX := X;
  DRPOSY := Y;

End;

Procedure SP_SetPixelPtr32Alpha(Ptr: pLongWord); Inline;
Begin

  If T_INVERSE = 0 Then
    Ptr^ := SP_AlphaBlend(Ptr^, T_INK)
  Else
    Ptr^ := SP_AlphaBlend(Ptr^, T_PAPER);

End;

Procedure SP_SetPixelPtrClr32Alpha(Ptr: pLongWord; Ink: LongWord); Inline;
Begin

  Ptr^ := SP_AlphaBlend(Ptr^, Ink);

End;

Procedure SP_SetPixelClr32Alpha(X, Y: aFloat; Ink: LongWord); Inline;
Var
  Ptr: pLongWord;
Begin

  If (X >= T_CLIPX1) And (X < T_CLIPX2) And (Y >= T_CLIPY1) And (Y < T_CLIPY2) Then Begin
    Ptr := pLongWord(NativeUInt(SCREENPOINTER)+(LongWord(Round(Y) * SCREENSTRIDE) + LongWord(Round(X) * SizeOf(RGBA))));
    Ptr^ := SP_AlphaBlend(Ptr^, Ink);
  End;

  DRPOSX := X;
  DRPOSY := Y;

End;

Procedure SP_Scroll32(Dy: Integer);
Var
  Dst: pLongWord;
  Src: pLongWord;
  Amt, nDy: Integer;
Begin

  nDy := Min(Dy, SCREENHEIGHT);

  While Dy > 0 Do Begin

    Dst := SCREENPOINTER;
    Src := pLongWord(NativeUInt(SCREENPOINTER) + (LongWord(nDy) * LongWord(SCREENSTRIDE)));
    Amt := (SCREENWIDTH * (SCREENHEIGHT - nDy));

    While Amt > 0 Do Begin
      Dst^ := Src^;
      Dec(Amt);
      Inc(Dst);
      Inc(Src);
    End;

    Amt := (nDy * SCREENWIDTH);
    While Amt > 0 Do Begin
      Dst^ := CPAPER;
      Dec(Amt);
      Inc(Dst);
    End;

    Dec(dY, SCREENHEIGHT);
    nDy := Min(Dy, SCREENHEIGHT);

  End;

End;

Procedure SP_HScroll32(Dst: pByte; Width, Height, Amount: Integer; Wrap: Boolean);
var
  Line: Pointer;
  paper: LongWord;
  y: Integer;
begin

  // Width *must* be the stride

  If T_INVERSE > 0 Then
    paper := T_INK
  Else
    paper := T_PAPER;

  Amount := Amount * SizeOf(RGBA);

  if Amount < 0 then Begin

    Amount := Abs(Amount) Mod Width;
    GetMem(Line, Amount);

    for y := 0 to Height -1 do begin

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

end;

procedure SP_VScroll32(Dst: pByte; Width, Height, Amount: Integer; Wrap: Boolean);
var
  Buff: Pointer;
  Paper:  Integer;
begin

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

end;

Procedure SP_DrawThickLine32(X1, Y1, X2, Y2: aFloat);
Var
  xa, ya, xb, yb, angle, app, amp, w: aFloat;
  Points: Array[0..3] of TSP_Point;
Begin

  angle := arctan2(y2-y1,x2-x1);
  app := angle + PI / 2; amp := angle - PI / 2;
  w := T_STROKE / 2;

  xa := x1 + W * Cos(angle + PI);
  ya := y1 + W * Sin(angle + PI);
  xb := x2 + W * Cos(angle);
  yb := y2 + W * Sin(angle);

  Points[0].x := xa + W * Cos(app);
  Points[0].y := ya + W * Sin(app);
  Points[1].x := xa + W * Cos(amp);
  Points[1].y := ya + W * Sin(amp);
  Points[2].x := xb + W * Cos(amp);
  Points[2].y := yb + W * Sin(amp);
  Points[3].x := xb + W * Cos(app);
  Points[3].y := yb + W * Sin(app);

  SP_PolygonSolidFill(Points, False);

  DRPOSX := X2;
  DRPOSY := Y2;

End;

Procedure SP_DrawLine32(X2, Y2: aFloat);
var
  x1, y1, x3, y3, d, ax, ay, sx, sy, dx, dy: Integer;
  Ptr: pLongWord;
  Ink: LongWord;
  stsy: Integer;
  DrX, DrY: aFloat;
  flip: Boolean;
begin

  If T_STROKE > 1 Then Begin

    SP_DrawThickLine32(DRPOSX, DRPOSY, X2 + DRPOSX, Y2 + DRPOSY);

  End Else Begin

    x1 := Round(DRPOSX);
    y1 := Round(DRPOSY);
    x2 := x2 + DRPOSX;
    y2 := y2 + DRPOSY;
    x3 := Round(x2);
    y3 := Round(y2);

    If (x1 < T_CLIPX1) or (y1 < T_CLIPY1) or (x1 >= T_CLIPX2) or (y1 >= T_CLIPY2) Then
      SKIPFIRSTPOINT := False;

    flip := False;
    If y2 < y1 then Begin
      flip := True;
      y1 := y1 Xor y3; y3 := y1 Xor y3; y1 := y1 Xor y3;
      x1 := x1 Xor x3; x3 := x1 Xor x3; x1 := x1 Xor x3;
    End;

    DrX := x2;
    DrY := y2;

    If SP_LineClip(x1, y1, x3, y3, T_CLIPX1, T_CLIPY1, T_CLIPX2, T_CLIPY2) Then Begin

      If SCREENVISIBLE Then SP_SetDirtyRectEx(SCREENX +X1, SCREENY + Y1, SCREENX + X3, SCREENY + Y3);

      If T_INVERSE = 1 Then
        Ink := T_PAPER
      Else
        Ink := T_INK;

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

      Ptr := pLongWord(NativeUInt(SCREENPOINTER) + (y1 * SCREENSTRIDE) + (x1 * SizeOf(RGBA)));
      stsy := SCREENWIDTH * sy;

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

      SP_BankList[0]^.Changed := True;

    End;

    DRPOSX := DrX;
    DRPOSY := DrY;

  End;

end;

Procedure SP_DrawThickLine32Alpha(X1, Y1, X2, Y2: aFloat);
Var
  xa, ya, xb, yb, angle, app, amp, w: aFloat;
  Points: Array[0..3] of TSP_Point;
Begin

  angle := arctan2(y2-y1,x2-x1);
  app := angle + PI / 2; amp := angle - PI / 2;
  w := T_STROKE / 2;

  xa := x1 + W * Cos(angle + PI);
  ya := y1 + W * Sin(angle + PI);
  xb := x2 + W * Cos(angle);
  yb := y2 + W * Sin(angle);

  Points[0].x := xa + W * Cos(app);
  Points[0].y := ya + W * Sin(app);
  Points[1].x := xa + W * Cos(amp);
  Points[1].y := ya + W * Sin(amp);
  Points[2].x := xb + W * Cos(amp);
  Points[2].y := yb + W * Sin(amp);
  Points[3].x := xb + W * Cos(app);
  Points[3].y := yb + W * Sin(app);

  SP_PolygonSolidFill32Alpha(Points, False);

  DRPOSX := X2;
  DRPOSY := Y2;

End;

Procedure SP_DrawLine32Alpha(X2, Y2: aFloat);
var
  x1, y1, x3, y3, d, ax, ay, sx, sy, dx, dy: Integer;
  Ptr: pLongWord;
  Ink: LongWord;
  stsy: Integer;
  DrX, DrY: aFloat;
  flip: Boolean;
begin

  If T_STROKE > 1 Then Begin

    SP_DrawThickLine32Alpha(DRPOSX, DRPOSY, X2 + DRPOSX, Y2 + DRPOSY);

  End Else Begin

    x1 := Round(DRPOSX);
    y1 := Round(DRPOSY);
    x2 := x2 + DRPOSX;
    y2 := y2 + DRPOSY;
    x3 := Round(x2);
    y3 := Round(y2);

    If (x1 < T_CLIPX1) or (y1 < T_CLIPY1) or (x1 >= T_CLIPX2) or (y1 >= T_CLIPY2) Then
      SKIPFIRSTPOINT := False;

    flip := False;
    If y2 < y1 then Begin
      flip := True;
      y1 := y1 Xor y3; y3 := y1 Xor y3; y1 := y1 Xor y3;
      x1 := x1 Xor x3; x3 := x1 Xor x3; x1 := x1 Xor x3;
    End;

    DrX := x2;
    DrY := y2;

    If SP_LineClip(x1, y1, x3, y3, T_CLIPX1, T_CLIPY1, T_CLIPX2, T_CLIPY2) Then Begin

      If SCREENVISIBLE Then SP_SetDirtyRectEx(SCREENX +X1, SCREENY + Y1, SCREENX + X3, SCREENY + Y3);

      If T_INVERSE = 1 Then
        Ink := T_PAPER
      Else
        Ink := T_INK;

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

      Ptr := pLongWord(NativeUInt(SCREENPOINTER) + (y1 * SCREENSTRIDE) + (x1 * SizeOf(RGBA)));
      stsy := SCREENWIDTH * sy;

      If Not SKIPFIRSTPOINT Then
        SP_AlphaBlend(Ptr^, Ink)
      Else
        If Flip Then
          Ptr^ := SP_AlphaBlend(Ptr^, Ink);
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
          Ptr^ := SP_AlphaBlend(Ptr^, Ink);
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
          Ptr^ := SP_AlphaBlend(Ptr^, Ink);
        end;
      end;
      If Not SKIPFIRSTPOINT and flip Then
        Ptr^ := SP_AlphaBlend(Ptr^, Ink);

      SP_BankList[0]^.Changed := True;

    End;

    DRPOSX := DrX;
    DRPOSY := DrY;

  End;

end;

Procedure SP_DrawThickEllipse32(CX, CY, R1, R2: Integer);
Var
  ir1, ir2, id, rd, ys, ox1, ix1: aFloat;
  y, x: NativeInt;
Begin

  r1 := Round(r1 + T_STROKE / 2);
  r2 := Round(r2 + T_STROKE / 2);
  ir1 := r1 - T_STROKE;
  ir2 := r2 - T_STROKE;
  id := ir1/ir2;
  rd := r1/r2;

  For y := -r2 +1 to r2 -1 Do Begin
    ys := y * rd;
    ox1 := sqrt(r1 * r1 - ys * ys);

    If Abs(y) < ir2 Then Begin
      ys := y*id;
      ix1 := sqrt(ir1 * ir1 - ys * ys);
    End Else
      ix1 := 0;

    For x := Round(ix1) to Round(ox1) Do Begin
      SP_SetPixel32(x + CX, y + CY);
      SP_SetPixel32(-x + CX, y + CY);
    End;

  End;

End;

Procedure SP_DrawEllipse32(CX, CY, Rx, Ry: Integer);
var
  x, y, p, px, py, twoRx2, twoRy2: Integer;
  Rx2, Ry2: Int64;
  cxpx, cypy, cxmx, cymy: Integer;
begin

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

  SP_SetPixel32(cxpx, cypy);
  SP_SetPixel32(cxmx, cypy);
  SP_SetPixel32(cxpx, cymy);
  SP_SetPixel32(cxmx, cymy);

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
     SP_SetPixel32(cxpx, cypy);
     SP_SetPixel32(cxmx, cypy);
     SP_SetPixel32(cxpx, cymy);
     SP_SetPixel32(cxmx, cymy);
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
     SP_SetPixel32(cxpx, cypy);
     SP_SetPixel32(cxmx, cypy);
     SP_SetPixel32(cxpx, cymy);
     SP_SetPixel32(cxmx, cymy);
  end;

end;

Procedure SP_DrawTexEllipse32To32(CX, CY, Rx, Ry: Integer; const TextureStr: aString; tW, tH: LongWord);
var
  Rx2, Ry2, twoRx2, twoRy2, p, x, y, Xn, px, py, xMin, xMax: Integer;
  TexBase, DstA, DstB: pLongWord;
  Graphic: pSP_Graphic_Info;
begin

  // if TextureStr = '' Then tW holds a pointer to the graphic bank's data,
  // and tH holds a pointer to the graphic bank's info field.

  If TextureStr = '' Then Begin
    TexBase := pLongWord(tW);
    Graphic := pSP_Graphic_Info(tH);
    tW := Graphic.Width;
    tH := Graphic.Height;
  End Else Begin
    TexBase := @TextureStr[11];
  End;

  Dec(Rx);
  Dec(Ry);
  Rx2 := Rx * Rx;
  Ry2 := Ry * Ry;
  twoRx2 := 2 * Rx2;
  twoRy2 := 2 * Ry2;
  x:=0;
  y := Ry;
  px := 0;
  py := twoRx2 * y;
  p:= Ry2 - (Rx2 * Ry) + (Rx2 div 4);

  while px <= py do begin

    Inc(x);
    Inc(px, twoRy2);
    if p<0 then
      Inc(p, Ry2 + px)
    else begin
      Dec(y);
      Dec(py, twoRx2);
      Inc(p, Ry2 + px - py);
    end;

    xMin := Max(T_CLIPX1, Cx - X);
    xMax := Min(T_CLIPX2 -1, Cx + X);

    DstA := pLongWord(NativeUInt(SCREENPOINTER) + (xMin * SizeOf(RGBA)));
    DstB := pLongWord(NativeUInt(DstA) + (SCREENSTRIDE * (Cy + Y)));
    Inc(DstA, SCREENWIDTH * (Cy - Y));

    If (Cy - y >= T_CLIPY1) And (Cy - y < T_CLIPY2) Then
      For Xn := xMin To xMax Do Begin
        DstA^ := pLongWord(NativeUInt(TexBase) + ((Xn mod Integer(tW)) * SizeOf(RGBA)) + (((Cy-Y) mod Integer(tH)) * Integer(tw) * SizeOf(RGBA)))^;
        Inc(DstA);
      End;

    If (Cy + y >= T_CLIPY1) And (Cy + y < T_CLIPY2) Then
      For Xn := xMin To xMax Do Begin
        DstB^ := pLongWord(NativeUInt(TexBase) + ((Xn mod Integer(tW)) * SizeOf(RGBA)) + (((Cy+Y) mod Integer(tH)) * Integer(tw) * SizeOf(RGBA)))^;
        Inc(DstB);
      End;

  end;

  p:=Trunc(Ry2 * (x + 0.5)*(x + 0.5) + Rx2 * (y -1) * (y -1) - Rx2 * Ry2);

  while y>=0 do begin

    Dec(y);
    Dec(py,twoRx2);

    if p>0 then
       Inc(p,Rx2-py)
    else begin
       Inc(x);
       Inc(px,twoRy2);
       Inc(p,Rx2-py+px);
    end;

    xMin := Max(T_CLIPX1, Cx - X);
    xMax := Min(T_CLIPX2 -1, Cx + X);

    DstA := pLongWord(NativeUInt(SCREENPOINTER) + (xMin * SizeOf(RGBA)));
    DstB := pLongWord(NativeUInt(DstA) + (SCREENSTRIDE * (Cy + Y)));
    Inc(DstA, SCREENWIDTH * (Cy - Y));

    If (Cy - y >= T_CLIPY1) And (Cy - y < T_CLIPY2) Then
      For Xn := xMin To xMax Do Begin
        DstA^ := pLongWord(NativeUInt(TexBase) + ((Xn mod Integer(tW)) * SizeOf(RGBA)) + (((Cy-Y) mod Integer(tH)) * Integer(tw) * SizeOf(RGBA)))^;
        Inc(DstA);
      End;

    If (Cy + y >= T_CLIPY1) And (Cy + y < T_CLIPY2) Then
      For Xn := xMin To xMax Do Begin
        DstB^ := pLongWord(NativeUInt(TexBase) + ((Xn mod Integer(tW)) * SizeOf(RGBA)) + (((Cy+Y) mod Integer(tH)) * Integer(tw) * SizeOf(RGBA)))^;
        Inc(DstB);
      End;

  end;

  If SCREENVISIBLE Then SP_SetDirtyRect((SCREENX + Cx) - Rx, (SCREENY + Cy) - Ry, SCREENX + Cx + Rx, SCREENY + Cy + Ry);
  SP_BankList[0]^.Changed := True;

end;

Procedure SP_DrawTexEllipse8To32(CX, CY, Rx, Ry: Integer; const TextureStr: aString; tW, tH: LongWord);
var
  Rx2, Ry2, twoRx2, twoRy2, p, x, y, Xn, px,py, xMin, xMax: Integer;
  TexBase, DstA, DstB: pByte;
  Graphic: pSP_Graphic_Info;
  Trans: Word;
  tClr, Clr1, Clr2: Byte;
begin

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

  If (rX <= 2) And (rY <= 2) Then Begin
    SP_SetPixelClr32(Cx, Cy, pByte(TexBase)^);
    If SCREENVISIBLE Then SP_SetDirtyRect((SCREENX + Cx) - Rx, (SCREENY + Cy) - Ry, SCREENX + Cx + Rx, SCREENY + Cy + Ry);
    SP_BankList[0]^.Changed := True;
    Exit;
  End;

  Dec(Rx);
  Dec(Ry);
  Rx2 := Rx * Rx;
  Ry2 := Ry * Ry;
  twoRx2 := 2 * Rx2;
  twoRy2 := 2 * Ry2;
  x:=0;
  y := Ry;
  px := 0;
  py := twoRx2 * y;
  p:= Ry2 - (Rx2 * Ry) + (Rx2 div 4);

  If T_OVER = 0 Then Begin

    while px <= py do begin

      Inc(x);
      Inc(px, twoRy2);
      if p<0 then
        Inc(p, Ry2 + px)
      else begin
        Dec(y);
        Dec(py, twoRx2);
        Inc(p, Ry2 + px - py);
      end;

      xMin := Max(T_CLIPX1, Cx - X);
      xMax := Min(T_CLIPX2 -1, Cx + X);

      DstA := pByte(NativeUInt(SCREENPOINTER) + xMin);
      DstB := DstA + (SCREENSTRIDE * (Cy + Y));
      Inc(DstA, SCREENSTRIDE * (Cy - Y));

      If Trans <> $FFFF Then Begin
        If (Cy - y >= T_CLIPY1) And (Cy - y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            Clr1 := pByte(TexBase + (Xn mod Integer(tW)) + (((Cy-Y) mod Integer(tH)) * Integer(tw)))^;
            If Clr1 <> tClr Then DstA^ := Clr1;
            Inc(DstA);
          End;
        If (Cy + y >= T_CLIPY1) And (Cy + y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            Clr2 := pByte(TexBase + (Xn mod Integer(tW)) + (((Cy+Y) mod Integer(tH)) * Integer(tw)))^;
            If Clr2 <> tClr Then DstB^ := Clr2;
            Inc(DstB);
          End;
      End Else Begin
        If (Cy - y >= T_CLIPY1) And (Cy - y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            DstA^ := pByte(TexBase + (Xn mod Integer(tW)) + (((Cy-Y) mod Integer(tH)) * Integer(tw)))^;
            Inc(DstA);
          End;

        If (Cy + y >= T_CLIPY1) And (Cy + y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            DstB^ := pByte(TexBase + (Xn mod Integer(tW)) + (((Cy+Y) mod Integer(tH)) * Integer(tw)))^;
            Inc(DstB);
          End;
      End;

    end;

    p:=Trunc(Ry2 * (x + 0.5)*(x + 0.5) + Rx2 * (y -1) * (y -1) - Rx2 * Ry2);

    while y>=0 do begin

      Dec(y);
      Dec(py,twoRx2);

      if p>0 then
         Inc(p,Rx2-py)
      else begin
         Inc(x);
         Inc(px,twoRy2);
         Inc(p,Rx2-py+px);
      end;

      xMin := Max(T_CLIPX1, Cx - X);
      xMax := Min(T_CLIPX2 -1, Cx + X);

      DstA := pByte(NativeUInt(SCREENPOINTER) + xMin);
      DstB := DstA + (SCREENSTRIDE * (Cy + Y));
      Inc(DstA, SCREENSTRIDE * (Cy - Y));

      If Trans <> $FFFF Then Begin
        If (Cy - y >= T_CLIPY1) And (Cy - y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            Clr1 := pByte(TexBase + (Xn mod Integer(tW)) + (((Cy-Y) mod Integer(tH)) * Integer(tw)))^;
            If Clr1 <> tClr Then DstA^ := Clr1;
            Inc(DstA);
          End;
        If (Cy + y >= T_CLIPY1) And (Cy + y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            Clr2 := pByte(TexBase + (Xn mod Integer(tW)) + (((Cy+Y) mod Integer(tH)) * Integer(tw)))^;
            If Clr2 <> tClr Then DstB^ := Clr2;
            Inc(DstB);
          End;
      End Else Begin
        If (Cy - y >= T_CLIPY1) And (Cy - y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            DstA^ := pByte(TexBase + (Xn mod Integer(tW)) + (((Cy-Y) mod Integer(tH)) * Integer(tw)))^;
            Inc(DstA);
          End;

        If (Cy + y >= T_CLIPY1) And (Cy + y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            DstB^ := pByte(TexBase + (Xn mod Integer(tW)) + (((Cy+Y) mod Integer(tH)) * Integer(tw)))^;
            Inc(DstB);
          End;
      End;

    end;

  End Else Begin

    while px <= py do begin

      Inc(x);
      Inc(px, twoRy2);
      if p<0 then
        Inc(p, Ry2 + px)
      else begin
        Dec(y);
        Dec(py, twoRx2);
        Inc(p, Ry2 + px - py);
      end;

      xMin := Max(T_CLIPX1, Cx - X);
      xMax := Min(T_CLIPX2 -1, Cx + X);

      DstA := pByte(NativeUInt(SCREENPOINTER) + xMin);
      DstB := DstA + (SCREENSTRIDE * (Cy + Y));
      Inc(DstA, SCREENSTRIDE * (Cy - Y));

      If Trans <> $FFFF Then Begin
        If (Cy - y >= T_CLIPY1) And (Cy - y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            Clr1 := pByte(TexBase + (Xn mod Integer(tW)) + (((Cy-Y) mod Integer(tH)) * Integer(tw)))^;
            If Clr1 <> tClr Then SP_OverPixelPtrVal(DstA, Clr1, T_OVER);
            Inc(DstA);
          End;

        If (Cy + y >= T_CLIPY1) And (Cy + y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            Clr2 := pByte(TexBase + (Xn mod Integer(tW)) + (((Cy+Y) mod Integer(tH)) * Integer(tw)))^;
            If Clr2 <> tClr Then SP_OverPixelPtrVal(DstB, Clr2, T_OVER);
            Inc(DstB);
          End;
      End Else Begin
        If (Cy - y >= T_CLIPY1) And (Cy - y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            SP_OverPixelPtrVal(DstA, pByte(TexBase + (Xn mod Integer(tW)) + (((Cy-Y) mod Integer(tH)) * Integer(tw)))^, T_OVER);
            Inc(DstA);
          End;

        If (Cy + y >= T_CLIPY1) And (Cy + y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            SP_OverPixelPtrVal(DstB, pByte(TexBase + (Xn mod Integer(tW)) + (((Cy+Y) mod Integer(tH)) * Integer(tw)))^, T_OVER);
            Inc(DstB);
          End;
      End;

    end;

    p := Trunc(Ry2 * (x + 0.5)*(x + 0.5) + Rx2 * (y -1) * (y -1) - Rx2 * Ry2);

    while y>=0 do begin

      Dec(y);
      Dec(py,twoRx2);

      if p>0 then
         Inc(p,Rx2-py)
      else begin
         Inc(x);
         Inc(px,twoRy2);
         Inc(p,Rx2-py+px);
      end;

      xMin := Max(T_CLIPX1, Cx - X);
      xMax := Min(T_CLIPX2 -1, Cx + X);

      DstA := pByte(NativeUInt(SCREENPOINTER) + xMin);
      DstB := DstA + (SCREENSTRIDE * (Cy + Y));
      Inc(DstA, SCREENSTRIDE * (Cy - Y));

      If Trans <> $FFFF Then Begin
        If (Cy - y >= T_CLIPY1) And (Cy - y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            Clr1 := pByte(TexBase + (Xn mod Integer(tW)) + (((Cy-Y) mod Integer(tH)) * Integer(tw)))^;
            If Clr1 <> tClr Then SP_OverPixelPtrVal(DstA, Clr1, T_OVER);
            Inc(DstA);
          End;

        If (Cy + y >= T_CLIPY1) And (Cy + y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            Clr2 := pByte(TexBase + (Xn mod Integer(tW)) + (((Cy+Y) mod Integer(tH)) * Integer(tw)))^;
            If Clr2 <> tClr Then SP_OverPixelPtrVal(DstB, Clr2, T_OVER);
            Inc(DstB);
          End;
      End Else Begin
        If (Cy - y >= T_CLIPY1) And (Cy - y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            SP_OverPixelPtrVal(DstA, pByte(TexBase + (Xn mod Integer(tW)) + (((Cy-Y) mod Integer(tH)) * Integer(tw)))^, T_OVER);
            Inc(DstA);
          End;

        If (Cy + y >= T_CLIPY1) And (Cy + y < T_CLIPY2) Then
          For Xn := xMin To xMax Do Begin
            SP_OverPixelPtrVal(DstB, pByte(TexBase + (Xn mod Integer(tW)) + (((Cy+Y) mod Integer(tH)) * Integer(tw)))^, T_OVER);
            Inc(DstB);
          End;
      End;

    end;

  End;

  If SCREENVISIBLE Then SP_SetDirtyRect((SCREENX + Cx) - Rx, (SCREENY + Cy) - Ry, SCREENX + Cx + Rx, SCREENY + Cy + Ry);
  SP_BankList[0]^.Changed := True;

end;

Procedure SP_DrawThickEllipse32Alpha(CX, CY, R1, R2: Integer);
Var
  ir1, ir2, id, rd, ys, ox1, ix1: aFloat;
  y, x: NativeInt;
Begin

  r1 := Round(r1 + T_STROKE / 2);
  r2 := Round(r2 + T_STROKE / 2);
  ir1 := r1 - T_STROKE;
  ir2 := r2 - T_STROKE;
  id := ir1/ir2;
  rd := r1/r2;

  For y := -r2 +1 to r2 -1 Do Begin
    ys := y * rd;
    ox1 := sqrt(r1 * r1 - ys * ys);

    If Abs(y) < ir2 Then Begin
      ys := y*id;
      ix1 := sqrt(ir1 * ir1 - ys * ys);
    End Else
      ix1 := 0;

    For x := Round(ix1) to Round(ox1) Do Begin
      SP_SetPixel32Alpha(x + CX, y + CY);
      SP_SetPixel32Alpha(-x + CX, y + CY);
    End;

  End;

End;

Procedure SP_DrawEllipse32Alpha(CX, CY, Rx, Ry: Integer);
var
  Rx2, Ry2, twoRx2, twoRy2, p, x, y, px, py: Integer;
  cxpx, cypy, cxmx, cymy: Integer;
begin

  If T_STROKE > 1 Then Begin

    SP_DrawThickEllipse32Alpha(CX, CY, Rx, Ry);
    Inc(Rx, Ceil(T_STROKE / 2));
    Inc(Ry, Ceil(T_STROKE /2 ));

  End Else Begin

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

    SP_SetPixel32Alpha(cxpx, cypy);
    SP_SetPixel32Alpha(cxmx, cypy);
    SP_SetPixel32Alpha(cxpx, cymy);
    SP_SetPixel32Alpha(cxmx, cymy);

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
       SP_SetPixel32Alpha(cxpx, cypy);
       SP_SetPixel32Alpha(cxmx, cypy);
       SP_SetPixel32Alpha(cxpx, cymy);
       SP_SetPixel32Alpha(cxmx, cymy);
    end;

    {$R-}
    p := Trunc(Ry2 * (x + 0.5) * (x + 0.5) + Rx2 * (y-1) * (y-1) - Rx2 * Ry2);
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
       SP_SetPixel32Alpha(cxpx, cypy);
       SP_SetPixel32Alpha(cxmx, cypy);
       SP_SetPixel32Alpha(cxpx, cymy);
       SP_SetPixel32Alpha(cxmx, cymy);
    end;

  End;

  If SCREENVISIBLE Then SP_SetDirtyRect((SCREENX + Cx) - Rx, (SCREENY + Cy) - Ry, SCREENX + Cx + Rx, SCREENY + Cy + Ry);

end;

Procedure SP_DrawSolidEllipse32(CX, CY, Rx, Ry: Integer);
var
  Ink: LongWord;
  w, xmn, xmx, ymn, ymx: Integer;
  r, rx2, x, y: Int64;
  DstA: pLongWord;
begin

  If T_INVERSE = 0 Then
    Ink := T_INK
  Else
    Ink := T_PAPER;

  r := Trunc((Rx+0.5)*Ry*Rx*rY);
  xmn := Max(T_CLIPX1, Cx - rX) - cX;
  xmx := Min(T_CLIPX2 -1, Cx + rX) - cX;
  ymn := Max(T_CLIPY1, Cy - rY) - cY;
  ymx := Min(T_CLIPY2 -1, Cy + rY) - cY;
  w := (SCREENSTRIDE Div SizeOf(RGBA)) - (xmx - xmn + 1);

  DstA := pLongWord(NativeUInt(SCREENPOINTER) + ((xmn + cX) * SizeOf(RGBA)) + ((ymn + cY) * SCREENSTRIDE));

  y := ymn;
  While y <= ymx Do Begin
    rx2 := y*Rx*y*Rx;
    x := xmn;
    While x <= xmx Do Begin
      If x*rY*x*rY+rx2 <= r Then
        DstA^ := Ink;
      Inc(DstA);
      Inc(x);
    End;
    Inc(DstA, w);
    Inc(y);
  End;

  If SCREENVISIBLE Then SP_SetDirtyRect((SCREENX + Cx) - Rx, (SCREENY + Cy) - Ry, SCREENX + Cx + Rx, SCREENY + Cy + Ry);
  SP_BankList[0]^.Changed := True;

end;

Procedure SP_DrawSolidEllipse32Alpha(CX, CY, Rx, Ry: Integer);
var
  Ink: LongWord;
  x, y, r, rx2: Int64;
  xmn, xmx, ymn, ymx, w: Integer;
  DstA: pLongWord;
begin

  If T_INVERSE = 0 Then
    Ink := T_INK
  Else
    Ink := T_PAPER;

  r := Trunc((Rx+0.5)*Ry*Rx*rY);
  xmn := Max(T_CLIPX1, Cx - rX) - cX;
  xmx := Min(T_CLIPX2 -1, Cx + rX) - cX;
  ymn := Max(T_CLIPY1, Cy - rY) - cY;
  ymx := Min(T_CLIPY2 -1, Cy + rY) - cY;
  w := (SCREENSTRIDE Div SizeOf(RGBA)) - (xmx - xmn + 1);

  DstA := pLongWord(NativeUInt(SCREENPOINTER) + ((xmn + cX) * SizeOf(RGBA)) + ((ymn + cY) * SCREENSTRIDE));

  y := ymn;
  While y <= ymx Do Begin
    rx2 := y*Rx*y*Rx;
    x := xmn;
    While x <= xmx Do Begin
      If x*rY*x*rY+rx2 <= r Then
        DstA^ := SP_AlphaBlend(DstA^, Ink);
      Inc(DstA);
      Inc(x);
    End;
    Inc(DstA, w);
    Inc(y);
  End;

  If SCREENVISIBLE Then SP_SetDirtyRect((SCREENX + Cx) - Rx, (SCREENY + Cy) - Ry, SCREENX + Cx + Rx, SCREENY + Cy + Ry);
  SP_BankList[0]^.Changed := True;

end;

Procedure SP_DrawRectangle32(X1, Y1, X2, Y2: Integer);
Var
  W, W2: Integer;
  Dst: pLongWord;
Begin

  If Y1 > Y2 Then Begin W := Y1; Y1 := Y2; Y2 := W; End;
  If X1 > X2 Then Begin W := X1; X1 := X2; X2 := W; End;

  W := X2 - X1;
  Dst := pLongWord(NativeInt(SCREENPOINTER) + (SCREENSTRIDE * Y1) + (X1 * SizeOf(RGBA)));

  If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X1, SCREENY + Y1, SCREENX + X2 +1, SCREENY + Y2 +1);

  If (Y1 >= T_CLIPY1) And (Y1 < T_CLIPY2) Then Begin // top edge
    W2 := X1;
    While W2 <= X2 Do Begin
      If (W2 >= T_CLIPX1) And (W2 < T_CLIPX2) Then
        SP_SetPixelPtr32(Dst);
      Inc(Dst);
      Inc(W2);
    End;
  End Else
    Inc(Dst, (X2 - X1)+1);

  Inc(Dst, SCREENWIDTH - W -1);
  Inc(Y1);

  While Y1 < Y2 Do Begin
    If (Y1 >= T_CLIPY1) And (Y1 < T_CLIPY2) Then Begin
      If (X1 >= T_CLIPX1) And (X1 < T_CLIPX2) Then // left edge
        SP_SetPixelPtr32(Dst);
      Inc(Dst, X2 - X1);
      If (X2 >= T_CLIPX1) And (X2 < T_CLIPX2) Then // right edge
        SP_SetPixelPtr32(Dst);
    End Else
      Inc(Dst, X2 - X1);
    Inc(Dst, SCREENWIDTH - W);
    Inc(Y1);
  End;

  If Y1 <= Y2 Then
    If (Y2 >= T_CLIPY1) And (Y2 < T_CLIPY2) Then Begin // bottom edge
      W2 := X1;
      While W2 <= X2 Do Begin
        If (W2 >= T_CLIPX1) And (W2 < T_CLIPX2) Then
          SP_SetPixelPtr32(Dst);
        Inc(Dst);
        Inc(W2);
      End;
    End;

End;

Procedure SP_DrawRectangle32Alpha(X1, Y1, X2, Y2: Integer);
Var
  W, W2: Integer;
  Dst: pLongWord;
Begin

  If Y1 > Y2 Then Begin W := Y1; Y1 := Y2; Y2 := W; End;
  If X1 > X2 Then Begin W := X1; X1 := X2; X2 := W; End;

  W := X2 - X1;
  Dst := pLongWord(NativeInt(SCREENPOINTER) + (SCREENSTRIDE * Y1) + (X1 * SizeOf(RGBA)));

  If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X1, SCREENY + Y1, SCREENX + X2 +1, SCREENY + Y2 +1);

  If (Y1 >= T_CLIPY1) And (Y1 < T_CLIPY2) Then Begin // top edge
    W2 := X1;
    While W2 <= X2 Do Begin
      If (W2 >= T_CLIPX1) And (W2 < T_CLIPX2) Then
        SP_SetPixelPtr32Alpha(Dst);
      Inc(Dst);
      Inc(W2);
    End;
  End Else
    Inc(Dst, (X2 - X1)+1);

  Inc(Dst, SCREENWIDTH - W -1);
  Inc(Y1);

  While Y1 < Y2 Do Begin
    If (Y1 >= T_CLIPY1) And (Y1 < T_CLIPY2) Then Begin
      If (X1 >= T_CLIPX1) And (X1 < T_CLIPX2) Then // left edge
        SP_SetPixelPtr32Alpha(Dst);
      Inc(Dst, X2 - X1);
      If (X2 >= T_CLIPX1) And (X2 < T_CLIPX2) Then // right edge
        SP_SetPixelPtr32Alpha(Dst);
    End Else
      Inc(Dst, X2 - X1);
    Inc(Dst, SCREENWIDTH - W);
    Inc(Y1);
  End;

  If Y1 <= Y2 Then
    If (Y2 >= T_CLIPY1) And (Y2 < T_CLIPY2) Then Begin // bottom edge
      W2 := X1;
      While W2 <= X2 Do Begin
        If (W2 >= T_CLIPX1) And (W2 < T_CLIPX2) Then
          SP_SetPixelPtr32Alpha(Dst);
        Inc(Dst);
        Inc(W2);
      End;
    End;

End;

Procedure SP_DrawSolidRectangle32(X1, Y1, X2, Y2: Integer);
Var
  T, W: Integer;
  Dst: pLongWord;
Begin

  If X1 > X2 Then Begin T := X1; X1 := X2; X2 := T; End;
  If Y1 > Y2 Then Begin T := Y1; Y1 := Y2; Y2 := T; End;

  If X1 < 0 Then X1 := 0; If X1 >= SCREENWIDTH Then Exit;
  If Y1 < 0 Then Y1 := 0; If Y1 >= SCREENHEIGHT Then Exit;
  If X2 < 0 Then Exit; If X2 >= SCREENWIDTH Then X2 := SCREENWIDTH -1;
  If Y2 < 0 Then Exit; If Y2 >= SCREENHEIGHT Then Y2 := SCREENHEIGHT -1;

  If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X1, SCREENY + Y1, SCREENX + X2 +1, SCREENY + Y2 +1);
  Dst := pLongWord(NativeUInt(SCREENPOINTER) + (SCREENSTRIDE * Y1) + (X1 * SizeOf(RGBA)));

  While Y1 <= Y2 Do Begin
    If (Y1 >= T_CLIPY1) And (Y1 < T_CLIPY2) Then Begin
      W := X1;
      While W <= X2 Do Begin
        If (W >= T_CLIPX1) And (W < T_CLIPX2) Then
          SP_SetPixelPtr32(Dst);
        Inc(Dst);
        Inc(W);
      End;
      Inc(Dst, SCREENWIDTH - (X2 - X1) -1);
    End Else
      Inc(Dst, SCREENWIDTH);
    Inc(Y1);
  End;

  SP_BankList[0]^.Changed := True;

End;

Procedure SP_DrawSolidRectangle32Alpha(X1, Y1, X2, Y2: Integer);
Var
  T, W: Integer;
  Dst: pLongWord;
Begin

  If X1 > X2 Then Begin T := X1; X1 := X2; X2 := T; End;
  If Y1 > Y2 Then Begin T := Y1; Y1 := Y2; Y2 := T; End;

  If X1 < 0 Then X1 := 0; If X1 >= SCREENWIDTH Then Exit;
  If Y1 < 0 Then Y1 := 0; If Y1 >= SCREENHEIGHT Then Exit;
  If X2 < 0 Then Exit; If X2 >= SCREENWIDTH Then X2 := SCREENWIDTH -1;
  If Y2 < 0 Then Exit; If Y2 >= SCREENHEIGHT Then Y2 := SCREENHEIGHT -1;

  If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X1, SCREENY + Y1, SCREENX + X2 +1, SCREENY + Y2 +1);
  Dst := pLongWord(NativeUInt(SCREENPOINTER) + (SCREENSTRIDE * Y1) + (X1 * SizeOf(RGBA)));

  While Y1 <= Y2 Do Begin
    If (Y1 >= T_CLIPY1) And (Y1 < T_CLIPY2) Then Begin
      W := X1;
      While W <= X2 Do Begin
        If (W >= T_CLIPX1) And (W < T_CLIPX2) Then
          SP_SetPixelPtr32Alpha(Dst);
        Inc(Dst);
        Inc(W);
      End;
      Inc(Dst, SCREENWIDTH - (X2 - X1) -1);
    End Else
      Inc(Dst, SCREENWIDTH);
    Inc(Y1);
  End;

  SP_BankList[0]^.Changed := True;

End;

Procedure SP_FloodFill32(Dst: pLongWord; dX, dY, dW, dH, Clr: LongWord);
Var
  o, qStart, qCount: LongWord;
  n, w, e, EdgeW, EdgeE, Up, Down, Top, Bottom: pLongWord;
  Target: LongWord;
Begin

  If (dX * SizeOf(RGBA) >= dW) or (dY >= dH) Then Exit;

  qStart := 0;
  qCount := 1;

  Top := pLongWord(NativeUInt(Dst) + (Integer(Dw) * Max(1, T_CLIPY1)));
  Bottom := pLongWord(NativeUInt(Dst) + (LongWord(T_CLIPY2 - 1) * dW));
  n := pLongWord(NativeUInt(Dst) + (dW * dY) + (dX * SizeOf(RGBA)));
  Target := n^ And $FFFFFF;

  If Length(FillQueue) <> dw*dh Then
    SetLength(FillQueue, dW * dH);

  FillQueue[0] := n;

  If Target = Clr Then Exit;

  While qCount > 0 Do Begin

    n := FillQueue[qStart];
    o := NativeUInt(n) - NativeUInt(Dst);
    Inc(qStart);
    Dec(qCount);

    If n^ = Target Then Begin

      w := n; e := pLongWord(NativeUInt(n) +1);
      EdgeW := pLongWord(NativeUInt(Dst) + (o - (o mod dW)) -1);
      EdgeE := pLongWord(NativeUInt(EdgeW) + ((T_CLIPX2 + 1)*SizeOf(RGBA)));
      Inc(EdgeW, (T_CLIPX1 * SizeOf(RGBA)));

      While (w^ And $FFFFFF = Target) And (NativeUInt(w) > NativeUInt(EdgeW)) Do Begin
        w^ := Clr;
        Up := pLongWord(NativeUInt(w) - dW);
        Down := pLongWord(NativeUInt(w) + dW);
        If NativeUInt(w) >= NativeUInt(Top) Then
          If Up^ And $FFFFFF = Target Then Begin
            FillQueue[qStart+qCount] := Up;
            Inc(qCount);
          End;
        If NativeUInt(w) < NativeUInt(Bottom) Then
          If Down^ And $FFFFFF = Target Then Begin
            FillQueue[qStart+qCount] := Down;
            Inc(qCount);
          End;
        Dec(w);
      End;

      While (e^ And $FFFFFF = Target) And (NativeUInt(e) < NativeUInt(EdgeE)) Do Begin
        e^ := Clr;
        Up := pLongWord(NativeUInt(e) - dW);
        Down := pLongWord(NativeUInt(e) + dW);
        If LongWord(e) >= NativeUInt(Top) Then
          If Up^ And $FFFFFF = Target Then Begin
            FillQueue[qStart+qCount] := Up;
            Inc(qCount);
          End;
        If LongWord(e) < NativeUInt(Bottom) Then
          If Down^ And $FFFFFF = Target Then Begin
            FillQueue[qStart+qCount] := Down;
            Inc(qCount);
          End;
        Inc(e);
      End;

    End;

  End;

  SP_BankList[0]^.Changed := True;

End;

Procedure SP_FloodFill32Alpha(Dst: pLongWord; dX, dY, dW, dH, Clr: LongWord);
Var
  o, qStart, qCount: LongWord;
  n, w, e, EdgeW, EdgeE, Up, Down, Top, Bottom: pLongWord;
  Target: LongWord;
Begin

  If (dX * SizeOf(RGBA) >= dW) or (dY >= dH) Then Exit;

  qStart := 0;
  qCount := 1;

  Top := pLongWord(NativeUInt(Dst) + (Integer(Dw) * Max(1, T_CLIPY1)));
  Bottom := pLongWord(NativeUInt(Dst) + (LongWord(T_CLIPY2 - 1) * dW));
  n := pLongWord(NativeUInt(Dst) + (dW * dY) + (dX * SizeOf(RGBA)));
  Target := n^ And $FFFFFF;

  If Length(FillQueue) <> dw*dh Then
    SetLength(FillQueue, dW * dH);

  FillQueue[0] := n;

  If Target = Clr Then Exit;

  While qCount > 0 Do Begin

    n := FillQueue[qStart];
    o := LongWord(n) - LongWord(Dst);
    Inc(qStart);
    Dec(qCount);

    If n^ = Target Then Begin

      w := n; e := pLongWord(NativeUInt(n) +1);
      EdgeW := pLongWord(NativeUInt(Dst) + (o - (o mod dW)) -1);
      EdgeE := pLongWord(NativeUInt(EdgeW) + ((T_CLIPX2 + 1)*SizeOf(RGBA)));
      Inc(EdgeW, (T_CLIPX1 * SizeOf(RGBA)));

      While (w^ And $FFFFFF = Target) And (NativeUInt(w) > NativeUInt(EdgeW)) Do Begin
        w^ := SP_AlphaBlend(w^, Clr);
        Up := pLongWord(NativeUInt(w) - dW);
        Down := pLongWord(NativeUInt(w) + dW);
        If LongWord(w) >= NativeUInt(Top) Then
          If Up^ And $FFFFFF = Target Then Begin
            FillQueue[qStart+qCount] := Up;
            Inc(qCount);
          End;
        If LongWord(w) < NativeUInt(Bottom) Then
          If Down^ And $FFFFFF = Target Then Begin
            FillQueue[qStart+qCount] := Down;
            Inc(qCount);
          End;
        Dec(w);
      End;

      While (e^ And $FFFFFF = Target) And (NativeUInt(e) < NativeUInt(EdgeE)) Do Begin
        e^ := SP_AlphaBlend(e^, Clr);
        Up := pLongWord(NativeUInt(e) - dW);
        Down := pLongWord(NativeUInt(e) + dW);
        If LongWord(e) >= NativeUInt(Top) Then
          If Up^ And $FFFFFF = Target Then Begin
            FillQueue[qStart+qCount] := Up;
            Inc(qCount);
          End;
        If LongWord(e) < NativeUInt(Bottom) Then
          If Down^ And $FFFFFF = Target Then Begin
            FillQueue[qStart+qCount] := Down;
            Inc(qCount);
          End;
        Inc(e);
      End;

    End;

  End;

  SP_BankList[0]^.Changed := True;

End;

Procedure SP_PolygonSolidFill32(Var Points: Array of TSP_Point; MinX, MinY, MaxX, MaxY: Integer; Ink: LongWord; Outline: Boolean);
Var
  I, J, Nodes, NumPoints, PixelY: Integer;
  NodeX: Array of Integer;
  Ptr: pLongWord;
Begin

  NumPoints := Length(Points);
  SetLength(NodeX, NumPoints);

  For PixelY := MinY to MaxY Do Begin

    Nodes := 0;
    J := NumPoints -1;

    For I := 0 To NumPoints -1 Do Begin
      If ((Points[I].Y < PixelY) And (Points[J].Y >= PixelY)) or ((Points[J].Y < PixelY) And (Points[I].Y >= PixelY)) Then Begin
        NodeX[Nodes] := Round(Points[I].X+(PixelY-Points[I].Y)/(Points[J].Y-Points[I].Y) * (Points[J].X-Points[I].X));
        Inc(Nodes);
      End;
      J := I;
    End;

    I := 0;
    While I < Nodes -1 Do
      If NodeX[I] > NodeX[I+1] Then Begin
        NodeX[I] := NodeX[I] Xor NodeX[I+1]; NodeX[I+1] := NodeX[I] Xor NodeX[I+1]; NodeX[I] := NodeX[I] Xor NodeX[I+1];
      End Else
        Inc(I);

    I := 0;
    While I < Nodes Do Begin
      If NodeX[I] >= T_CLIPX2 Then Break;
      If NodeX[I+1] > T_CLIPX1 Then Begin
        If NodeX[I] < T_CLIPX1 Then NodeX[I] := T_CLIPX1;
        If NodeX[I+1] >= T_CLIPX2 Then NodeX[I+1] := T_CLIPX2;
        Ptr := SCREENPOINTER;
        Inc(Ptr, ((PixelY * SCREENWIDTH) + NodeX[I]));
        For J := NodeX[I] To NodeX[I+1] -1 Do Begin
          Ptr^ := Ink;
          Inc(Ptr);
        End;
      End;
      Inc(I, 2);
    End;

  End;

  If Outline Then Begin
    DRPOSX := Points[0].X;
    DRPOSY := Points[0].Y;
    For I := 1 To NumPoints - 1 Do
      SP_DrawLine32Alpha(Points[I].X - DRPOSX, Points[I].Y - DRPOSY);
    SP_DrawLine32Alpha(Points[0].X - DRPOSX, Points[0].Y - DRPOSY);
  End;

  SP_BankList[0]^.Changed := True;

End;

Procedure SP_PolygonSolidFill32Alpha(Var Points: Array of TSP_Point; Outline: Boolean);
Var
  MinX, MinY, MaxX, MaxY, Idx, I, J, Nodes, NumPoints, PixelY, Swap: Integer;
  NodeX: Array of Integer;
  Ptr: pLongWord;
  Ink: LongWord;
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

    If Points[Idx].Y < MinY then MinY := Trunc(Points[Idx].Y);
    If Points[Idx].Y > MaxY then MaxY := Trunc(Points[Idx].Y);
    If Points[Idx].X < MinX then MinX := Trunc(Points[Idx].X);
    If Points[Idx].X > MaxX then MaxX := Trunc(Points[Idx].X);
    Dec(Idx);

  End;

  MaxY := Min(MaxY, T_CLIPY2 -1);
  MaxX := Min(MaxX, T_CLIPX2 -1);
  MinY := Max(MinY, T_CLIPY1);
  MinX := Max(MinX, T_CLIPX1);

  If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + MinX, SCREENY + MinY, SCREENX + MaxX, SCREENY + MaxY);
  SetLength(NodeX, NumPoints);

  For PixelY := MinY to MaxY Do Begin

    Nodes := 0;
    J := NumPoints -1;

    For I := 0 To NumPoints -1 Do Begin
      If ((Points[I].Y < PixelY) And (Points[J].Y >= PixelY)) or ((Points[J].Y < PixelY) And (Points[I].Y >= PixelY)) Then Begin
        NodeX[Nodes] := Round(Points[I].X+(PixelY-Points[I].Y)/(Points[J].Y-Points[I].Y) * (Points[J].X-Points[I].X));
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
    While I < Nodes Do Begin
      If NodeX[I] >= T_CLIPX2 Then Break;
      If NodeX[I+1] > T_CLIPX1 Then Begin
        If NodeX[I] < T_CLIPX1 Then NodeX[I] := T_CLIPX1;
        If NodeX[I+1] >= T_CLIPX2 Then NodeX[I+1] := T_CLIPX2;
        Ptr := SCREENPOINTER;
        Inc(Ptr, ((PixelY * SCREENWIDTH) + NodeX[I]));
        For J := NodeX[I] To NodeX[I+1] -1 Do Begin
          Ptr^ := SP_AlphaBlend(Ptr^, Ink);
          Inc(Ptr);
        End;
      End;
      Inc(I, 2);
    End;

  End;

  If Outline Then Begin
    DRPOSX := Points[0].X;
    DRPOSY := Points[0].Y;
    For I := 1 To NumPoints - 1 Do
      SP_DrawLine32(Points[I].X - DRPOSX, Points[I].Y - DRPOSY);
    SP_DrawLine32(Points[0].X - DRPOSX, Points[0].Y - DRPOSY);
  End;

  SP_BankList[0]^.Changed := True;

End;

Procedure SP_DrawSpeccyCurve32(X, Y, Angle: aFloat);
Var
  Z, W, F, M0, M1, M2, M3, M4, SC, MM1: aFloat;
  NumArcs: Integer;
Begin

  SP_AngleToRad(Angle);
  Z := Abs((Abs(X)+Abs(Y))/Sin(Angle/2));
  If (Round(Sin(Angle/2)*10000000) = 0) or (Z < 1) Then
    SP_DrawLine32(Round(X), Round(Y))
  Else Begin
    NumArcs := Min(4*Round(Round(Abs(Angle*Sqrt(Z))+0.5)/8)+4, 252);
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

      SP_DrawLine32(SC - DRPOSX, M0 - DRPOSY);

      MM1 := M1;
      M1 := (M1*M3)-(M2*M4);
      M2 := (MM1*M4)+(M2*M3);

      Dec(NumArcs);

    End;

  End;

End;

Procedure SP_DrawSpeccyCurve32Alpha(X, Y, Angle: aFloat);
Var
  Z, W, F, M0, M1, M2, M3, M4, SC, MM1: aFloat;
  NumArcs: Integer;
Begin

  SP_AngleToRad(Angle);
  Z := Abs((Abs(X)+Abs(Y))/Sin(Angle/2));
  If (Round(Sin(Angle/2)*10000000) = 0) or (Z < 1) Then
    SP_DrawLine(Round(X), Round(Y))
  Else Begin
    NumArcs := Min(4*Round(Round(Abs(Angle*Sqrt(Z))+0.5)/8)+4, 252);
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

      SP_DrawLine32Alpha(SC - DRPOSX, M0 - DRPOSY);

      MM1 := M1;
      M1 := (M1*M3)-(M2*M4);
      M2 := (MM1*M4)+(M2*M3);

      Dec(NumArcs);

    End;

  End;

End;

Procedure SP_DrawCurve32(CurveStartX, CurveStartY, X, Y, CurveEndX, CurveEndY: aFloat; N: Integer);
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
    SP_DrawLine32(omt2 * CurveStartX + omt2t * X + t2 * CurveEndX - DRPOSX, omt2 * CurveStartY + omt2t * Y + t2 * CurveEndY - DRPOSY);

  End;

End;

Procedure SP_DrawCurve32Alpha(CurveStartX, CurveStartY, X, Y, CurveEndX, CurveEndY: aFloat; N: Integer);
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
    SP_DrawLine32Alpha(omt2 * CurveStartX + omt2t * X + t2 * CurveEndX - DRPOSX, omt2 * CurveStartY + omt2t * Y + t2 * CurveEndY - DRPOSY);

  End;

End;

Function SP_PRINT32(BankID, X, Y, CPos: Integer; const Text: aString; Ink, Paper: LongWord; var Error: TSP_ErrorCode): Integer;
Var
  CharW, CharH, Idx, Scrolls, cCount, sx, sy, nx: Integer;
  yp, xp, Cw, Ch, TC: Integer;
  Transparent: Boolean;
  FontBank: pSP_Font_info;
  Bank: pSP_Bank;
  Coord: pLongWord;
  Char, pIdx, lIdx: pByte;
  IsScaled: Boolean;
  ScaleX, ScaleY: aFloat;
  Info: TSP_iInfo;
  pInfo: pSP_iInfo;
Begin

  // Like its graphics.pas counterpart, this draws a font on a 32bpp surface.
  // This one can handle any of the three font types.

  Result := 0;
  Scrolls := 0;

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
    ScaleX := T_SCALEX;
    ScaleY := T_SCALEY;

    If BankID = -1 Then // Use the system font?
      BankID := FONTBANKID;

    Idx := SP_FindBankID(BankID);
    If Idx <> SP_ERR_BANK_ID_NOT_FOUND Then Begin

      Bank := SP_BankList[Idx];
      FontBank := @Bank^.Info[0];
      IsScaled := (ScaleX <> 1) Or (ScaleY <> 1);
      CharW := Max(1, Trunc(FONTWIDTH * ScaleX));
      CharH := Max(1, Trunc(FONTHEIGHT * ScaleY));
      Cw := CharW;
      Ch := CharH;
      If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
        Transparent := T_TRANSPARENT And (FontBank^.Transparent <> $FFFF);
        TC := FontBank^.Transparent And $FF;
      End Else
        If (FontBank^.FontType = SP_FONT_TYPE_32BIT) And (pSP_Window_Info(WINDOWPOINTER)^.bpp <> 32) Then Begin
          Error.Code := SP_ERR_INVALID_DEPTH;
          Exit;
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

        If Text[Idx] >= ' ' Then Begin

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

          Coord := SCREENPOINTER;
          Inc(Coord, (SCREENWIDTH * Y) + X);
          If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X, SCREENY + Y, SCREENX + X + Cw, SCREENY + Y + Ch);

          If (X >= T_CLIPX1) And (X + Cw -1 < T_CLIPX2) And (Y >= T_CLIPY1) And (Y + Ch -1 < T_CLIPY2) Then Begin
            If IsScaled Then Begin
              // Scaled character
              sx := (FONTWIDTH Shl 16) Div CharW;
              sy := (FONTHEIGHT Shl 16) Div CharH;
              yp := 0;
              While CharH > 0 Do Begin
                pIdx := Char;
                xp := 0;
                If FontBank^.FontType = SP_FONT_TYPE_32BIT Then
                  Inc(pLongWord(pIdx), FONTWIDTH * (yp Shr 16))
                Else
                  Inc(pIdx, FONTWIDTH * (yp Shr 16));
                While CharW > 0 Do Begin
                  If FontBank^.FontType = SP_FONT_TYPE_MONO Then Begin
                    // 8 Bpp, mono (INK and PAPER)
                    If (CPos = Idx) And (SYSTEMSTATE in [SS_INPUT, SS_EDITOR, SS_DIRECT]) Then Begin
                      If pByte(NativeUInt(pIdx) + (xp Shr 16))^ = FLASHSTATE Then
                        Coord^ := CURSORFG
                      Else
                        Coord^ := CURSORBG;
                    End Else
                      If pByte(NativeUInt(pIdx) + (xp Shr 16))^ = 1 Then
                        Coord^ := Ink
                      Else
                        If Not Transparent Then
                          Coord^ := Paper;
                  End Else
                    If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                      // 8Bpp, colour - INK only, uses the font's internal palette.
                      If Transparent Then Begin
                        lIdx := pByte(NativeUInt(pIdx) + (xp Shr 16));
                        If lIdx^ <> TC Then
                          Coord^ := LongWord(FontBank^.Palette[lIdx^]);
                      End Else
                        Coord^ := LongWord(FontBank^.Palette[pByte(NativeUInt(pIdx) + (xp Shr 16))^]);
                    End Else
                      If FontBank^.FontType = SP_FONT_TYPE_32BIT Then Begin
                        // 32bpp - plain longword writes.
                        Coord^ := pLongWord(NativeUInt(pIdx) + ((xp Shr 16) * SizeOf(RGBA)))^;
                      End;
                  Inc(Coord);
                  Inc(xp, sx);
                  Dec(CharW);
                End;
                Inc(Coord, SCREENWIDTH - Cw);
                CharW := Cw;
                Dec(CharH);
                Inc(yp, sy);
              End;
              CharH := Ch;
              Inc(X, CharW);
            End Else Begin
              While CharH > 0 Do Begin
                While CharW > 0 Do Begin
                  If FontBank^.FontType = SP_FONT_TYPE_MONO Then Begin
                    If (CPos = Idx) And (SYSTEMSTATE in [SS_INPUT, SS_EDITOR, SS_DIRECT]) Then Begin
                      If Char^ = FLASHSTATE Then
                        Coord^ := CURSORFG
                      Else
                        Coord^ := CURSORBG;
                    End Else
                      If Char^ = 1 Then
                        Coord^ := Ink
                      Else
                        If Not Transparent Then
                          Coord^ := Paper;
                    Inc(Char);
                  End Else
                    If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                      If Transparent Then Begin
                        If Char^ <> TC Then
                          Coord^ := LongWord(FontBank^.Palette[Char^]);
                      End Else
                        Coord^ := LongWord(FontBank^.Palette[Char^]);
                      Inc(Char);
                    End Else
                      If FontBank^.FontType = SP_FONT_TYPE_32BIT Then Begin
                        Coord^ := pLongWord(Char)^;
                        Inc(Char, SizeOf(RGBA));
                      End;
                  Inc(Coord);
                  Inc(X);
                  Dec(CharW);
                End;
                Inc(Y);
                CharW := FontBank^.Width;
                Dec(X, CharW);
                Inc(Coord, SCREENWIDTH - CharW);
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
            6:
              Begin // PRINT comma
                nx := X + (TABSIZE * Cw);
                nx := Round(nX / (TABSIZE * Cw)) * (TABSIZE * Cw);
                SP_TextOut32(-1, X, Y, StringOfChar(aChar(' '), ((nx - x) Div Cw) +1), Ink, Paper, True);
                X := nx;
              End;
            8:
              Begin // Cursor Left
                X := (X - Cw) Mod SCREENWIDTH;
              End;
            9:
              Begin // Cursor right
                SP_TextOut32(-1, X, Y, aString(' '), Ink, Paper, True);
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
                T_INK := pLongWord(@Text[Idx+1])^;
                Ink := T_INK;
                Inc(Idx, SizeOf(LongWord));
              End;
           17:
              Begin // PAPER control
                T_PAPER := pLongWord(@Text[Idx+1])^;
                Paper := T_PAPER;
                Inc(Idx, SizeOf(LongWord));
              End;
           18:
              Begin // OVER control
                T_OVER := pByte(@Text[Idx+1])^;
                Inc(Idx);
              End;
           19:
              Begin
                Transparent := pByte(@Text[Idx+1])^ > 0;
                If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                  Transparent := T_TRANSPARENT And (FontBank^.Transparent <> $FFFF);
                  TC := FontBank^.Transparent And $FF;
                End;
                Inc(Idx);
              End;
           20:
              Begin // INVERSE control
                If pByte(@Text[Idx+1])^ <> 0 Then Begin
                  Ink := T_PAPER;
                  Paper := T_INK;
                End Else Begin
                  Ink := T_INK;
                  Paper := T_PAPER;
                End;
                Inc(Idx);
              End;
           21:
              Begin // MOVE control
                X := pInteger(@Text[Idx+1])^;
                Inc(Idx, SizeOf(Integer));
                Y := pInteger(@Text[Idx+1])^;
                Inc(Idx, SizeOf(Integer));
                SP_ConvertToOrigin_i(X, Y);
                If WINFLIPPED Then Y := (SCREENHEIGHT - 1) - Y;
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
                SP_PRINT32(-1, X, Y, -1, StringOfChar(aChar(' '), tc - nx), Ink, Paper, Error);
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
                While not (pIdx^ in [6..11, 13, 21..25]) and (pIdx <= lIdx) Do Begin
                  Case pIdx^ Of
                    16..20:
                      Begin
                        Inc(pIdx);
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
                  CharW := Max(1, Trunc(FONTWIDTH * ScaleX));
                  CharH := Max(1, Trunc(FONTHEIGHT * ScaleY));
                  Cw := CharW;
                  Ch := CharH;
                End;
                T_SCALEX := ScaleX;
                T_SCALEY := ScaleY;
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

Function SP_TextOut32(BankID, X, Y: Integer; const Text: aString; Ink, Paper: LongWord; Visible: Boolean): Integer;
Var
  CharW, CharH, Idx, cCount, nx: Integer;
  sx, sy, Cw, Ch, yp, xp, TC: Integer;
  Transparent: Boolean;
  FontBank: pSP_Font_Info;
  Bank: pSP_Bank;
  Coord: pLongWord;
  Char, pIdx, lIdx: pByte;
  IsScaled: Boolean;
  ScaleX, ScaleY: aFloat;
Begin

  If T_INVERSE <> 0 Then Begin
    Idx := Ink;
    Ink := Paper;
    Paper := Idx;
  End;
  ScaleX := T_SCALEX;
  ScaleY := T_SCALEY;

  If BankID = -1 Then // Use the system font?
    BankID := FONTBANKID;

  Result := SP_FindBankID(BankID);
  If Result <> SP_ERR_BANK_ID_NOT_FOUND Then Begin

    Bank := SP_BankList[Result];
    FontBank := @Bank^.Info[0];
    IsScaled := (ScaleX <> 1) Or (ScaleY <> 1);
    CharW := Max(1, Trunc(FONTWIDTH * ScaleX));
    CharH := Max(1, Trunc(FONTHEIGHT * ScaleY));
    Cw := CharW;
    Ch := CharH;
    If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
      Transparent := T_TRANSPARENT And (FontBank^.Transparent <> $FFFF);
      TC := FontBank^.Transparent And $FF;
    End Else Begin
      If (FontBank^.FontType = SP_FONT_TYPE_32BIT) And (pSP_Window_Info(WINDOWPOINTER)^.bpp <> 32) Then
        Exit
      Else
        Transparent := T_TRANSPARENT;
      TC := 0;
    End;

    Coord := SCREENPOINTER;
    Inc(Coord, (SCREENWIDTH * Y) + X);

    Idx := 1;
    While Idx <= Length(Text) Do Begin

      If Text[Idx] >= ' ' Then Begin

        Char := @Bank^.Memory[FontBank^.Font_Info[Byte(Text[Idx])].Data];

        If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X, SCREENY + Y, SCREENX + X + CharW, SCREENY + Y + CharH);

        If IsScaled Then Begin
          // Scaled character
          sx := (FONTWIDTH Shl 16) Div CharW;
          sy := (FONTHEIGHT Shl 16) Div CharH;
          yp := 0;
          While CharH > 0 Do Begin
            pIdx := Char;
            xp := 0;
            Inc(pIdx, FONTWIDTH * (yp Shr 16));
            While CharW > 0 Do Begin
              If (X >= T_CLIPX1) And (Y >= T_CLIPY1) And (X < T_CLIPX2) And (Y < T_CLIPY2) Then
                If FontBank^.FontType = SP_FONT_TYPE_MONO Then Begin
                  If pByte(NativeUInt(pIdx) + (xp Shr 16))^ = 1 Then
                    Coord^ := Ink
                  Else
                    If Not Transparent Then
                      Coord^ := Paper;
                End Else
                  If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                    If Transparent Then Begin
                      lIdx := pByte(NativeUInt(pIdx) + (xp Shr 16));
                      If lIdx^ <> TC Then
                        Coord^ := LongWord(FontBank^.Palette[lIdx^]);
                    End Else
                      Coord^ := LongWord(FontBank^.Palette[pByte(NativeUInt(pIdx) + (xp Shr 16))^]);
                  End Else
                    If FontBank^.FontType = SP_FONT_TYPE_32BIT Then Begin
                      // 32bpp - plain longword writes.
                      Coord^ := pLongWord(NativeUInt(pIdx) + ((xp Shr 16) * SizeOf(RGBA)))^;
                    End;
              Inc(Coord);
              Inc(xp, sx);
              Inc(X);
              Dec(CharW);
            End;
            Inc(Y);
            CharW := Cw;
            Dec(X, CharW);
            Inc(Coord, SCREENWIDTH - CharW);
            Dec(CharH);
            Inc(yp, sy);
          End;
          CharH := Ch;
          Dec(Y, Ch);
          Dec(Coord, SCREENWIDTH * CharH);
          Inc(Coord, CharW);
          Inc(X, CharW);
        End Else Begin
          While CharH > 0 Do Begin
            While CharW > 0 Do Begin
              If (X >= T_CLIPX1) And (Y >= T_CLIPY1) And (X < T_CLIPX2) And (Y < T_CLIPY2) Then
                If FontBank^.FontType = SP_FONT_TYPE_MONO Then Begin
                  If Char^ = 1 Then
                    Coord^ := Ink
                  Else
                    If Not Transparent Then
                      Coord^ := Paper;
                  Inc(Char);
                End Else
                  If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                    If Transparent Then Begin
                      If Char^ <> TC Then
                        Coord^ := LongWord(FontBank^.Palette[Char^]);
                    End Else
                      Coord^ := LongWord(FontBank^.Palette[Char^]);
                    Inc(Char);
                  End Else
                    If FontBank^.FontType = SP_FONT_TYPE_32BIT Then Begin
                      Coord^ := pLongWord(Char)^;
                      Inc(Char, SizeOf(RGBA));
                    End;
              Inc(Coord);
              Inc(X);
              Dec(CharW);
            End;
            Inc(Y);
            CharW := FontBank^.Width;
            Dec(X, CharW);
            Inc(Coord, SCREENWIDTH - CharW);
            Dec(CharH);
          End;
          CharH := FontBank^.Height;
          Dec(Y, CharH);
          Dec(Coord, SCREENWIDTH * CharH);
          Inc(Coord, CharW);
          Inc(X, CharW);
        End;

      End Else Begin

        // Control codes!
        Case Ord(Text[Idx]) of
          6:
            Begin // PRINT comma
              nx := X + (TABSIZE * Cw);
              nx := Round(nX / (TABSIZE * Cw)) * (TABSIZE * Cw);
              SP_TextOut32(-1, X, Y, StringOfChar(aChar(' '), ((nx - x) Div Cw) +1), Ink, Paper, True);
              X := nx;
            End;
          8:
            Begin // Cursor Left
              SP_TextOut32(-1, X, Y, aString(' '), Ink, Paper, True);
              X := (X - Cw) Mod SCREENWIDTH;
            End;
          9:
            Begin // Cursor right
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
              T_INK := pLongWord(@Text[Idx+1])^;
              Ink := T_INK;
              Inc(Idx, SizeOf(LongWord));
            End;
         17:
            Begin // PAPER control
              T_PAPER := pLongWord(@Text[Idx+1])^;
              Paper := T_PAPER;
              Inc(Idx, SizeOf(LongWord));
            End;
         18:
            Begin // OVER control
              T_OVER := pByte(@Text[Idx+1])^;
              Inc(Idx);
            End;
         19:
            Begin // TRANSPARENT 0/1
              T_TRANSPARENT := pByte(@Text[Idx+1])^ > 0;
              If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                Transparent := T_TRANSPARENT And (FontBank^.Transparent <> $FFFF);
                TC := FontBank^.Transparent And $FF;
              End;
              Inc(Idx);
            End;
         20:
            Begin // INVERSE control
              If pByte(@Text[Idx+1])^ <> 0 Then Begin
                Ink := T_PAPER;
                Paper := T_INK;
                T_INVERSE := 1;
              End Else Begin
                Ink := T_INK;
                Paper := T_PAPER;
                T_INVERSE := 0;
              End;
              Inc(Idx);
            End;
         21:
            Begin // MOVE control
              X := pInteger(@Text[Idx+1])^;
              Inc(Idx, SizeOf(Integer));
              Y := pInteger(@Text[Idx+1])^;
              Inc(Idx, SizeOf(Integer));
              SP_ConvertToOrigin_i(X, Y);
              If WINFLIPPED Then Y := (SCREENHEIGHT - 1) - Y;
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
              SP_TextOut32(-1, X, Y, StringOfChar(aChar(' '), tc - nx), Ink, Paper, True);
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
              While not (pIdx^ in [6..11, 13, 21..24]) and (pIdx <= lIdx) Do Begin
                Case pIdx^ Of
                  16..20:
                    Begin
                      Inc(pIdx);
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
                CharW := Max(1, Trunc(FONTWIDTH * ScaleX));
                CharH := Max(1, Trunc(FONTHEIGHT * ScaleY));
                Cw := CharW;
                Ch := CharH;
              End;
              T_SCALEX := ScaleX;
              T_SCALEY := ScaleY;
            End;
        End;
        Coord := SCREENPOINTER;
        Inc(Coord, (SCREENWIDTH * Y) + X);
      End;
      Inc(Idx);
    End;

  End;

  PRPOSX := X;
  PRPOSY := Y;

  SP_BankList[0]^.Changed := True;
  SP_NeedDisplayUpdate := True;

End;

Function SP_PRINT32Alpha(BankID, X, Y, CPos: Integer; const Text: aString; Ink, Paper: LongWord; var Error: TSP_ErrorCode): Integer;
Var
  CharW, CharH, Idx, Scrolls, cCount, sx, sy, nx: Integer;
  yp, xp, Cw, Ch, TC: Integer;
  Transparent: Boolean;
  FontBank: pSP_Font_info;
  Bank: pSP_Bank;
  Coord: pLongWord;
  Char, pIdx, lIdx: pByte;
  IsScaled: Boolean;
  ScaleX, ScaleY: aFloat;
  Info: TSP_iInfo;
  pInfo: pSP_iInfo;
Begin


  Result := 0;
  Scrolls := 0;

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
    ScaleX := T_SCALEX;
    ScaleY := T_SCALEY;

    If BankID = -1 Then // Use the system font?
      BankID := FONTBANKID;

    Idx := SP_FindBankID(BankID);
    If Idx <> SP_ERR_BANK_ID_NOT_FOUND Then Begin

      Bank := SP_BankList[Idx];
      FontBank := @Bank^.Info[0];
      IsScaled := (ScaleX <> 1) Or (ScaleY <> 1);
      CharW := Max(1, Trunc(FONTWIDTH * ScaleX));
      CharH := Max(1, Trunc(FONTHEIGHT * ScaleY));
      Cw := CharW;
      Ch := CharH;
      If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
        Transparent := T_TRANSPARENT And (FontBank^.Transparent <> $FFFF);
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

        If Text[Idx] >= ' ' Then Begin

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

          Coord := SCREENPOINTER;
          Inc(Coord, (SCREENWIDTH * Y) + X);
          If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X, SCREENY + Y, SCREENX + X + Cw, SCREENY + Y + Ch);

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
                While CharW > 0 Do Begin
                  If FontBank^.FontType = SP_FONT_TYPE_MONO Then Begin
                    If (CPos = Idx) And (SYSTEMSTATE in [SS_INPUT, SS_EDITOR, SS_DIRECT]) Then Begin
                      If pByte(NativeUInt(pIdx) + (xp Shr 16))^ = FLASHSTATE Then
                        Coord^ := CURSORFG
                      Else
                        Coord^ := CURSORBG;
                    End Else
                      If pByte(NativeUInt(pIdx) + (xp Shr 16))^ = 1 Then
                        Coord^ := SP_AlphaBlend(Coord^, Ink)
                      Else
                        If Not Transparent Then
                          Coord^ := SP_AlphaBlend(Coord^, Paper);
                  End Else
                    If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                      If Transparent Then Begin
                        lIdx := pByte(NativeUInt(pIdx) + (xp Shr 16));
                        If lIdx^ <> TC Then
                          Coord^ := SP_AlphaBlend(Coord^, LongWord(FontBank^.Palette[lIdx^]));
                      End Else
                        Coord^ := SP_AlphaBlend(Coord^, LongWord(FontBank^.Palette[pByte(NativeUInt(pIdx) + (xp Shr 16))^]));
                    End Else
                      If FontBank^.FontType = SP_FONT_TYPE_32BIT Then Begin
                        // 32bpp - plain longword writes.
                        Coord^ := SP_AlphaBlend(Coord^, pLongWord(NativeUInt(pIdx) + ((xp Shr 16) * SizeOf(RGBA)))^);
                      End;
                  Inc(Coord);
                  Inc(xp, sx);
                  Dec(CharW);
                End;
                Inc(Coord, SCREENWIDTH - Cw);
                CharW := Cw;
                Dec(CharH);
                Inc(yp, sy);
              End;
              CharH := Ch;
              Inc(X, CharW);
            End Else Begin
              While CharH > 0 Do Begin
                While CharW > 0 Do Begin
                  If FontBank^.FontType = SP_FONT_TYPE_MONO Then Begin
                    If (CPos = Idx) And (SYSTEMSTATE in [SS_INPUT, SS_EDITOR, SS_DIRECT]) Then Begin
                      If Char^ = FLASHSTATE Then
                        Coord^ := CURSORFG
                      Else
                        Coord^ := CURSORBG;
                    End Else
                      If Char^ = 1 Then
                        Coord^ := SP_AlphaBlend(Coord^, Ink)
                      Else
                        If Not Transparent Then
                          Coord^ := SP_AlphaBlend(Coord^, Paper);
                    Inc(Char);
                  End Else
                    If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                      If Transparent Then Begin
                        If Char^ <> TC Then
                          Coord^ := SP_AlphaBlend(Coord^, LongWord(FontBank^.Palette[Char^]));
                      End Else
                        Coord^ := SP_AlphaBlend(Coord^, LongWord(FontBank^.Palette[Char^]));
                      Inc(Char);
                    End Else
                      If FontBank^.FontType = SP_FONT_TYPE_32BIT Then Begin
                        Coord^ := SP_AlphaBlend(Coord^, pLongWord(Char)^);
                        Inc(Char, SizeOf(RGBA));
                      End;
                  Inc(Coord);
                  Inc(X);
                  Dec(CharW);
                End;
                Inc(Y);
                CharW := FontBank^.Width;
                Dec(X, CharW);
                Inc(Coord, SCREENWIDTH - CharW);
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
            6:
              Begin // PRINT comma
                nx := X + (TABSIZE * Cw);
                nx := Round(nX / (TABSIZE * Cw)) * (TABSIZE * Cw);
                SP_TextOut32Alpha(-1, X, Y, StringOfChar(aChar(' '), ((nx - x) Div Cw) +1), Ink, Paper, True);
                X := nx;
              End;
            8:
              Begin // Cursor Left
                X := (X - Cw) Mod SCREENWIDTH;
              End;
            9:
              Begin // Cursor right
                SP_TextOut32Alpha(-1, X, Y, aString(' '), Ink, Paper, True);
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
                T_INK := pByte(@Text[Idx+1])^;
                Ink := T_INK;
                Inc(Idx);
              End;
           17:
              Begin // PAPER control
                T_PAPER := pByte(@Text[Idx+1])^;
                Paper := T_PAPER;
                Inc(Idx);
              End;
           18:
              Begin // OVER control
                T_OVER := pByte(@Text[Idx+1])^;
                Inc(Idx);
              End;
           19:
              Begin
                Transparent := pByte(@Text[Idx+1])^ > 0;
                If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                  Transparent := T_TRANSPARENT And (FontBank^.Transparent <> $FFFF);
                  TC := FontBank^.Transparent And $FF;
                End;
                Inc(Idx);
              End;
           20:
              Begin // INVERSE control
                If pByte(@Text[Idx+1])^ <> 0 Then Begin
                  Ink := T_PAPER;
                  Paper := T_INK;
                End Else Begin
                  Ink := T_INK;
                  Paper := T_PAPER;
                End;
                Inc(Idx);
              End;
           21:
              Begin // MOVE control
                X := pInteger(@Text[Idx+1])^;
                Inc(Idx, SizeOf(Integer));
                Y := pInteger(@Text[Idx+1])^;
                Inc(Idx, SizeOf(Integer));
                SP_ConvertToOrigin_i(X, Y);
                If WINFLIPPED Then Y := (SCREENHEIGHT - 1) - Y;
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
                SP_PRINT32Alpha(-1, X, Y, -1, StringOfChar(aChar(' '), tc - nx), Ink, Paper, Error);
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
                While not (pIdx^ in [6..11, 13, 21..25]) and (pIdx <= lIdx) Do Begin
                  Case pIdx^ Of
                    16..20:
                      Begin
                        Inc(pIdx);
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
                  CharW := Max(1, Trunc(FONTWIDTH * ScaleX));
                  CharH := Max(1, Trunc(FONTHEIGHT * ScaleY));
                  Cw := CharW;
                  Ch := CharH;
                End;
                T_SCALEX := ScaleX;
                T_SCALEY := ScaleY;
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

Function SP_TextOut32Alpha(BankID, X, Y: Integer; const Text: aString; Ink, Paper: LongWord; Visible: Boolean): Integer;
Var
  CharW, CharH, Idx, cCount, nx: Integer;
  sx, sy, Cw, Ch, yp, xp, TC: Integer;
  Transparent: Boolean;
  FontBank: pSP_Font_Info;
  Bank: pSP_Bank;
  Coord: pLongWord;
  Char, pIdx, lIdx: pByte;
  IsScaled: Boolean;
  ScaleX, ScaleY: aFloat;
Begin

  If T_INVERSE <> 0 Then Begin
    Idx := Ink;
    Ink := Paper;
    Paper := Idx;
  End;
  ScaleX := T_SCALEX;
  ScaleY := T_SCALEY;

  If BankID = -1 Then // Use the system font?
    BankID := FONTBANKID;

  Result := SP_FindBankID(BankID);
  If Result <> SP_ERR_BANK_ID_NOT_FOUND Then Begin

    Bank := SP_BankList[Result];
    FontBank := @Bank^.Info[0];
    IsScaled := (ScaleX <> 1) Or (ScaleY <> 1);
    CharW := Max(1, Trunc(FONTWIDTH * ScaleX));
    CharH := Max(1, Trunc(FONTHEIGHT * ScaleY));
    Cw := CharW;
    Ch := CharH;
    If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
      Transparent := T_TRANSPARENT And (FontBank^.Transparent <> $FFFF);
      TC := FontBank^.Transparent And $FF;
    End Else Begin
      Transparent := T_TRANSPARENT;
      TC := 0;
    End;

    Coord := SCREENPOINTER;
    Inc(Coord, (SCREENWIDTH * Y) + X);

    Idx := 1;
    While Idx <= Length(Text) Do Begin

      If Text[Idx] >= ' ' Then Begin

        Char := @Bank^.Memory[FontBank^.Font_Info[Byte(Text[Idx])].Data];
        If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X, SCREENY + Y, SCREENX + X + CharW, SCREENY + Y + CharH);

        If IsScaled Then Begin
          // Scaled character
          sx := (FONTWIDTH Shl 16) Div CharW;
          sy := (FONTHEIGHT Shl 16) Div CharH;
          yp := 0;
          While CharH > 0 Do Begin
            pIdx := Char;
            xp := 0;
            Inc(pIdx, FONTWIDTH * (yp Shr 16));
            While CharW > 0 Do Begin
              If (X >= T_CLIPX1) And (Y >= T_CLIPY1) And (X < T_CLIPX2) And (Y < T_CLIPY2) Then
                If FontBank^.FontType = SP_FONT_TYPE_MONO Then Begin
                  If pByte(NativeUInt(pIdx) + (xp Shr 16))^ = 1 Then
                    Coord^ := SP_AlphaBlend(Coord^, Ink)
                  Else
                    If Not Transparent Then
                      Coord^ := SP_AlphaBlend(Coord^, Paper);
                End Else
                  If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                    If Transparent Then Begin
                      lIdx := pByte(NativeUInt(pIdx) + (xp Shr 16));
                      If lIdx^ <> TC Then
                        Coord^ := SP_AlphaBlend(Coord^, LongWord(FontBank^.Palette[lIdx^]));
                    End Else
                      Coord^ := SP_AlphaBlend(Coord^, LongWord(FontBank^.Palette[pByte(NativeUInt(pIdx) + (xp Shr 16))^]));
                  End Else
                    If FontBank^.FontType = SP_FONT_TYPE_32BIT Then Begin
                      Coord^ := SP_AlphaBlend(Coord^, pLongWord(NativeUInt(pIdx) + ((xp Shr 16) * SizeOf(RGBA)))^);
                    End;
              Inc(Coord);
              Inc(xp, sx);
              Inc(X);
              Dec(CharW);
            End;
            Inc(Y);
            CharW := Cw;
            Dec(X, CharW);
            Inc(Coord, SCREENWIDTH - CharW);
            Dec(CharH);
            Inc(yp, sy);
          End;
          CharH := Ch;
          Dec(Y, Ch);
          Dec(Coord, SCREENWIDTH * CharH);
          Inc(Coord, CharW);
          Inc(X, CharW);
        End Else Begin
          While CharH > 0 Do Begin
            While CharW > 0 Do Begin
                If (X >= T_CLIPX1) And (Y >= T_CLIPY1) And (X < T_CLIPX2) And (Y < T_CLIPY2) Then
                  If FontBank^.FontType = SP_FONT_TYPE_MONO Then Begin
                    If Char^ = 1 Then
                      Coord^ := SP_AlphaBlend(Coord^, Ink)
                    Else
                      If Not Transparent Then
                        Coord^ := SP_AlphaBlend(Coord^, Paper);
                    Inc(Char);
                  End Else
                    If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                      If Transparent Then Begin
                        If Char^ <> TC Then
                          Coord^ := SP_AlphaBlend(Coord^, LongWord(FontBank^.Palette[Char^]));
                      End Else
                        Coord^ := SP_AlphaBlend(Coord^, LongWord(FontBank^.Palette[Char^]));
                      Inc(Char);
                    End Else
                      If FontBank^.FontType = SP_FONT_TYPE_32BIT Then Begin
                        Coord^ := SP_AlphaBlend(Coord^, pLongWord(Char)^);
                        Inc(Char, SizeOf(RGBA));
                      End;
              Inc(Coord);
              Inc(X);
              Dec(CharW);
            End;
            Inc(Y);
            CharW := FontBank^.Width;
            Dec(X, CharW);
            Inc(Coord, SCREENWIDTH - CharW);
            Dec(CharH);
          End;
          CharH := FontBank^.Height;
          Dec(Y, CharH);
          Dec(Coord, SCREENWIDTH * CharH);
          Inc(Coord, CharW);
          Inc(X, CharW);
        End;

      End Else Begin

        // Control codes!
        Case Ord(Text[Idx]) of
          6:
            Begin // PRINT comma
              nx := X + (TABSIZE * Cw);
              nx := Round(nX / (TABSIZE * Cw)) * (TABSIZE * Cw);
              SP_TextOut32Alpha(-1, X, Y, StringOfChar(aChar(' '), ((nx - x) Div Cw) +1), Ink, Paper, True);
              X := nx;
            End;
          8:
            Begin // Cursor Left
              X := (X - Cw) Mod SCREENWIDTH;
            End;
          9:
            Begin // Cursor right
              SP_TextOut32Alpha(-1, X, Y, aString(' '), Ink, Paper, True);
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
              T_INK := pByte(@Text[Idx+1])^;
              Ink := T_INK;
              Inc(Idx);
            End;
         17:
            Begin // PAPER control
              T_PAPER := pByte(@Text[Idx+1])^;
              Paper := T_PAPER;
              Inc(Idx);
            End;
         18:
            Begin // OVER control
              T_OVER := pByte(@Text[Idx+1])^;
              Inc(Idx);
            End;
         19:
            Begin // TRANSPARENT 0/1
              T_TRANSPARENT := pByte(@Text[Idx+1])^ > 0;
              If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                Transparent := T_TRANSPARENT And (FontBank^.Transparent <> $FFFF);
                TC := FontBank^.Transparent And $FF;
              End;
              Inc(Idx);
            End;
         20:
            Begin // INVERSE control
              If pByte(@Text[Idx+1])^ <> 0 Then Begin
                Ink := T_PAPER;
                Paper := T_INK;
                T_INVERSE := 1;
              End Else Begin
                Ink := T_INK;
                Paper := T_PAPER;
                T_INVERSE := 0;
              End;
              Inc(Idx);
            End;
         21:
            Begin // MOVE control
              X := pInteger(@Text[Idx+1])^;
              Inc(Idx, SizeOf(Integer));
              Y := pInteger(@Text[Idx+1])^;
              Inc(Idx, SizeOf(Integer));
              SP_ConvertToOrigin_i(X, Y);
              If WINFLIPPED Then Y := (SCREENHEIGHT - 1) - Y;
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
              SP_TextOut32Alpha(-1, X, Y, StringOfChar(aChar(' '), tc - nx), Ink, Paper, True);
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
              While not (pIdx^ in [6..11, 13, 21..24]) and (pIdx <= lIdx) Do Begin
                Case pIdx^ Of
                  16..20:
                    Begin
                      Inc(pIdx);
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
                CharW := Max(1, Trunc(FONTWIDTH * ScaleX));
                CharH := Max(1, Trunc(FONTHEIGHT * ScaleY));
                Cw := CharW;
                Ch := CharH;
              End;
              T_SCALEX := ScaleX;
              T_SCALEY := ScaleY;
            End;
        End;
        Coord := SCREENPOINTER;
        Inc(Coord, (SCREENWIDTH * Y) + X);
      End;
      Inc(Idx);
    End;

  End;

  PRPOSX := X;
  PRPOSY := Y;

  SP_BankList[0]^.Changed := True;
  SP_NeedDisplayUpdate := True;

End;

Procedure SP_PutRegion32to32(Dst: pByte; dX, dY: Integer; dW, dH: LongWord; Src: pByte; SrcLen: Integer; RotAngle, Scale: aFloat; Var cX1, cY1, cX2, cY2: Integer; Var Error: TSP_ErrorCode);
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
  End;

  SP_BankList[0]^.Changed := True;

End;

Function SP_RawTextOut(BankID: Integer; Dest: pLongWord; dW, dH, X, Y: Integer; const Text: aString; Ink, Paper: LongWord; ScaleX, ScaleY: aFloat; Trans, Alpha: Boolean): Integer;
Var
  fW, fH, CharW, CharH, Idx: Integer;
  sX, sY, Cw, Ch, TC, xp, yp, pInk, pPaper: Integer;
  FontBank: pSP_Font_Info;
  Transparent: Boolean;
  Bank: pSP_Bank;
  Coord: pLongWord;
  Char, pIdx, lIdx: pByte;
  IsScaled: Boolean;
Begin

  pInk := Ink;
  pPaper := Paper;
  Result := SP_FindBankID(BankID);
  If Result <> SP_ERR_BANK_ID_NOT_FOUND Then Begin

    Bank := SP_BankList[Result];
    FontBank := @Bank^.Info[0];
    fW := FontBank^.Width;
    fH := FontBank^.Height;
    IsScaled := (ScaleX <> 1) Or (ScaleY <> 1);
    CharW := Max(1, Trunc(fW * ScaleX));
    CharH := Max(1, Trunc(fH * ScaleY));
    Cw := CharW;
    Ch := CharH;
    If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
      Transparent := FontBank^.Transparent <> $FFFF;
      TC := FontBank^.Transparent And $FF;
    End Else Begin
      If FontBank^.FontType = SP_FONT_TYPE_32BIT Then
        Exit
      Else
        Transparent := T_TRANSPARENT;
      TC := 0;
    End;

    Coord := Dest;
    Inc(Coord, (dW * Y) + X);

    Idx := 1;
    While Idx <= Length(Text) Do Begin

      If Text[Idx] >= ' ' Then Begin

        Char := @Bank^.Memory[FontBank^.Font_Info[Byte(Text[Idx])].Data];

        If IsScaled Then Begin
          // Scaled character
          sx := (fW Shl 16) Div CharW;
          sy := (fH Shl 16) Div CharH;
          yp := 0;
          While CharH > 0 Do Begin
            pIdx := Char;
            xp := 0;
            Inc(pIdx, fW * (yp Shr 16));
            While CharW > 0 Do Begin
              If (X >= 0) And (Y >= 0) And (X < dW) And (Y < dH) Then
                If FontBank^.FontType = SP_FONT_TYPE_MONO Then Begin
                  If pByte(NativeUInt(pIdx) + (xp Shr 16))^ = 1 Then Begin
                    If Alpha Then
                      Coord^ := SP_AlphaBlend(Coord^, Ink)
                    Else
                      Coord^ := Ink
                  End Else
                    If Not Trans Then
                      If Alpha Then
                        Coord^ := SP_AlphaBlend(Coord^, Paper)
                      Else
                        Coord^ := Paper;
                End Else
                  If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                    If Transparent Then Begin
                      lIdx := pByte(NativeUInt(pIdx) + (xp Shr 16));
                      If lIdx^ <> TC Then
                        Coord^ := LongWord(FontBank^.Palette[lIdx^]);
                    End Else
                      Coord^ := LongWord(FontBank^.Palette[pByte(NativeUInt(pIdx) + (xp Shr 16))^]);
                  End Else
                    If FontBank^.FontType = SP_FONT_TYPE_32BIT Then Begin
                      // 32bpp - plain longword writes.
                      Coord^ := pLongWord(NativeUInt(pIdx) + ((xp Shr 16) * SizeOf(RGBA)))^;
                    End;
              Inc(Coord);
              Inc(xp, sx);
              Inc(X);
              Dec(CharW);
            End;
            Inc(Y);
            CharW := Cw;
            Dec(X, CharW);
            Inc(Coord, dW - CharW);
            Dec(CharH);
            Inc(yp, sy);
          End;
          CharH := Ch;
          Dec(Y, Ch);
          Dec(Coord, dW * CharH);
          Inc(Coord, CharW);
          Inc(X, CharW);
        End Else Begin
          While CharH > 0 Do Begin
            While CharW > 0 Do Begin
              If (X >= 0) And (Y >= 0) And (X < dW) And (Y < dH) Then
                If FontBank^.FontType = SP_FONT_TYPE_MONO Then Begin
                  If Char^ = 1 Then Begin
                    If Alpha Then
                      Coord^ := SP_AlphaBlend(Coord^, Ink)
                    Else
                      Coord^ := Ink
                  End Else
                    If Not Trans Then
                      If Alpha Then
                        Coord^ := SP_AlphaBlend(Coord^, Paper)
                      Else
                        Coord^ := Paper;
                  Inc(Char);
                End Else
                  If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                    If Transparent Then Begin
                      If Char^ <> TC Then
                        Coord^ := LongWord(FontBank^.Palette[Char^]);
                    End Else
                      Coord^ := LongWord(FontBank^.Palette[Char^]);
                    Inc(Char);
                  End Else
                    If FontBank^.FontType = SP_FONT_TYPE_32BIT Then Begin
                      Coord^ := pLongWord(Char)^;
                      Inc(Char, SizeOf(RGBA));
                    End;
              Inc(Coord);
              Inc(X);
              Dec(CharW);
            End;
            Inc(Y);
            CharW := fW;
            Dec(X, CharW);
            Inc(Coord, dW - CharW);
            Dec(CharH);
          End;
          CharH := fH;
          Dec(Y, CharH);
          Dec(Coord, dW * CharH);
          Inc(Coord, CharW);
          Inc(X, CharW);
        End;

      End Else Begin

        // Control codes!
        Case Ord(Text[Idx]) of
         16:
            Begin // INK control
              Ink := pLongWord(@Text[Idx+1])^;
              Inc(Idx, SizeOf(LongWord));
            End;
         17:
            Begin // PAPER control
              Paper := pLongWord(@Text[Idx+1])^;
              Inc(Idx, SizeOf(LongWord));
              Trans := False;
            End;
         20:
            Begin // INVERSE control
              If pByte(@Text[Idx+1])^ <> 0 Then Begin
                Ink := pPaper;
                Paper := pInk;
              End Else Begin
                Ink := pInk;
                Paper := pPaper;
              End;
              Inc(Idx);
            End;
        Else
          Exit;
        End;
        Coord := Dest;
        Inc(Coord, (dW * Y) + X);
      End;
      Inc(Idx);
    End;

  End;

End;

Procedure SP_DrawStripe32(Dst: pLongWord; Width, StripeWidth, StripeHeight: Integer);
Var
  X, Y, X2: Integer;
  oPtr: pLongWord;
  Clrs: Array[0..3] of LongWord;
Begin

  Clrs[0] := CBRIGHTRED;
  Clrs[1] := CBRIGHTYELLOW;
  Clrs[2] := CBRIGHTGREEN;
  Clrs[3] := CBRIGHTCYAN;

  X := Width - ((StripeWidth * 6) + StripeHeight);
  oPtr := pLongWord(NativeUInt(Dst) + (SizeOf(LongWord) * ((Width * StripeHeight) + X)));

  For Y := StripeHeight DownTo 1 Do Begin
    For X2 := X to X + (StripeWidth * 4) -1 Do Begin
      oPtr^ := Clrs[(X2 - X) Div StripeWidth];
      inc(oPtr);
    End;
    Dec(oPtr, Width + (StripeWidth * 4) -1);
  End;

End;

Procedure SP_CLS32(Paper: LongWord);
Var
  bOver: Integer;
Begin

  PRPOSX := 0;
  PRPOSY := 0;
  DRPOSX := 0;
  DRPOSY := 0;
  SCROLLCNT := 0;
  bOver := T_OVER;
  T_OVER := 0;
  SP_FillRect32Alpha(0, 0, SCREENWIDTH, SCREENHEIGHT, Paper);
  T_OVER := bOver;
  SP_NeedDisplayUpdate := True;
  SP_ConvertToOrigin_d(PRPOSX, PRPOSY);
  SP_ConvertToOrigin_d(DRPOSX, DRPOSY);

End;

Procedure SP_PolygonFill32Alpha(Var Points: Array of TSP_Point; TextureStr: aString; tW, tH: LongWord);
Begin
  // TODO Alpha
End;

Procedure SP_DrawTexRectangle32Alpha(X1, Y1, X2, Y2: Integer; TextureStr: aString; tW, tH: LongWord);
Begin
  // TODO Alpha
End;

Procedure SP_DrawTexEllipse32Alpha(CX, CY, Rx, Ry: Integer; TextureStr: aString; tW, tH: LongWord);
Begin
  // TODO Alpha
End;


end.
