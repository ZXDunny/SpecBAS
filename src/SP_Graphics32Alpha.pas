unit SP_Graphics32Alpha;

{$INCLUDE SpecBAS.inc}

interface

  uses SP_Util, SP_Graphics, SP_Errors;

  Function  SP_AlphaBlend(PixelA, PixelB: LongWord): LongWord; inline;

  Procedure SP_SetPixel32Alpha(X, Y: aFloat); Inline;
  Procedure SP_SetPixelPtr32Alpha(Ptr: pLongWord); Inline;
  Procedure SP_SetPixelPtrClr32Alpha(Ptr: pLongWord; Ink: LongWord); Inline;
  Procedure SP_SetPixelClr32Alpha(X, Y: aFloat; Ink: LongWord); Inline;

  Procedure SP_DrawLine32Alpha(X2, Y2: aFloat);
  Procedure SP_DrawLine32ExAlpha(X1, Y1, X2, Y2: aFloat);
  Procedure SP_DrawSpeccyCurve32Alpha(X, Y, Angle: aFloat);
  Procedure SP_DrawCurve32Alpha(CurveStartX, CurveStartY, X, Y, CurveEndX, CurveEndY: aFloat; N: Integer);

  Procedure SP_DrawEllipse32Alpha(CX, CY, Rx, Ry: Integer; Angle: aFloat);
  Procedure SP_DrawThickEllipse32Alpha(CX, CY, R1, R2: Integer; Angle: aFloat);
  Procedure SP_DrawSolidEllipse32Alpha(CX, CY, Rx, Ry: Integer; Angle: aFloat);
  Procedure SP_DrawTexEllipse32Alpha(CX, CY, Rx, Ry: Integer; Angle: aFloat; TextureStr: aString; tW, tH: LongWord);

  Procedure SP_DrawCircle32Alpha(Cx, Cy, R: Integer);
  Procedure SP_DrawSolidCircle32Alpha(Cx, Cy, R: Integer);

  Procedure SP_FillRect32Alpha(X, Y, W, H: Integer; Colour: LongWord);
  Procedure SP_DrawRectangle32Alpha(X1, Y1, X2, Y2: Integer);
  Procedure SP_DrawSolidRectangle32Alpha(X1, Y1, X2, Y2: Integer);
  Procedure SP_DrawTexRectangle32Alpha(X1, Y1, X2, Y2: Integer; TextureStr: aString; tW, tH: LongWord);

  Procedure SP_FloodFill32Alpha(Dst: pLongWord; dX, dY, dW, dH, Clr: LongWord);

  Procedure SP_PolygonFill32Alpha(Var Points: Array of TSP_Point; TextureStr: aString; tW, tH: LongWord);
  Procedure SP_PolygonSolidFill32Alpha(Var Points: Array of TSP_Point; Outline: Boolean);

  Function  SP_PRINT32Alpha(BankID, X, Y, CPos: Integer; const Text: aString; Ink, Paper: LongWord; var Error: TSP_ErrorCode): Integer;
  Function  SP_TextOut32Alpha(BankID, X, Y: Integer; const Text: aString; Ink, Paper: LongWord; Visible: Boolean): Integer;

implementation

Uses

  Math, SP_Main, SP_BankManager, SP_Graphics32, SP_SysVars, SP_BankFiling, SP_Interpret_PostFix;

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
    Inc(Ptr, Add);
  End;

End;

Procedure SP_SetPixel32Alpha(X, Y: aFloat); Inline;
Var
  xr, yr: Integer;
  Ink: LongWord;
  Ptr: pLongWord;
Begin

  If T_INVERSE = 0 Then
    Ink := T_INK
  Else
    Ink := T_PAPER;
  If (X >= T_CLIPX1) And (X < T_CLIPX2) And (Y >= T_CLIPY1) And (Y < T_CLIPY2) Then
    If T_STROKE > 1 Then Begin
      DRPOSX := X;
      DRPOSY := Y;
      xr := Round(X - T_STROKE / 2); yr := Round(Y - T_STROKE / 2);
      SP_FillRect32Alpha(xr, yr, Round(T_STROKE), Round(T_STROKE), Ink);
    End Else Begin
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

Procedure SP_DrawLine32ExAlpha(X1, Y1, X2, Y2: aFloat);
Var
  Dx, Dy: aFloat;
Begin

  Dx := DRPOSX;
  Dy := DRPOSY;
  DRPOSX := X1;
  DRPOSY := Y1;
  SKIPFIRSTPOINT := False;
  SP_DrawLine32Alpha(X2 - X1, Y2 - Y1);
  DRPOSX := Dx;
  DRPOSY := Dy;

End;

{
Procedure SP_DrawThickEllipse32Alpha(CX, CY, R1, R2: Integer);
Var
  fr1, fr2,ir1, ir2, id, rd, ys, ox1, ix1: aFloat;
  y, x: NativeInt;
Begin

  fr1 := r1 + T_STROKE / 2;
  fr2 := r2 + T_STROKE / 2;
  ir1 := fr1 - T_STROKE;
  ir2 := fr2 - T_STROKE;
  id := ir1/ir2;
  rd := r1/r2;

  r2 := Round(fr2);

  For y := -r2 to r2 Do Begin
    ys := y * rd;
    ox1 := sqrt(fr1 * fr1 - ys * ys);

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
}

Procedure SP_DrawThickEllipse32Alpha(CX, CY, R1, R2: Integer; Angle: aFloat);
Var
  fr1, fr2, ir1, ir2, cosA, sinA, ts: aFloat;
  y, minY, maxY: NativeInt;

  Procedure DrawSpansForRow(rowY: Integer);
  Var
    x, spanStart, minX, maxX: Integer;
    inSpan: Boolean;
    rx, ry, outerTest, innerTest: aFloat;
    testY, maxRadius: aFloat;
    i: Integer;
  Begin
    testY := rowY;
    inSpan := False;
    spanStart := 0;
    maxRadius := sqrt(fr1 * fr1 + fr2 * fr2);
    minX := -Round(maxRadius) - 1;
    maxX := Round(maxRadius) + 1;

    For x := minX to maxX Do Begin
      rx := x * cosA + testY * sinA;
      ry := -x * sinA + testY * cosA;
      outerTest := (rx * rx) / (fr1 * fr1) + (ry * ry) / (fr2 * fr2);
      innerTest := (rx * rx) / (ir1 * ir1) + (ry * ry) / (ir2 * ir2);
      If (outerTest <= 1.0) and (innerTest > 1.0) Then Begin
        If not inSpan Then Begin
          spanStart := x;
          inSpan := True;
        End;
      End Else Begin
        If inSpan Then Begin
          For i := spanStart to x - 1 Do
            SP_SetPixel32Alpha(i + CX, rowY + CY);
          inSpan := False;
        End;
      End;
    End;
    If inSpan Then Begin
      For i := spanStart to maxX Do
        SP_SetPixel32Alpha(i + CX, rowY + CY);
    End;
  End;

Begin
    ts := T_STROKE + 0.5;
    fr1 := r1 + ts / 2;
    fr2 := r2 + ts / 2;
    ir1 := fr1 - ts;
    ir2 := fr2 - ts;

    cosA := cos(Angle);
    sinA := sin(Angle);

    minY := -Round(sqrt(fr1*fr1*sinA*sinA + fr2*fr2*cosA*cosA)) - 1;
    maxY := Round(sqrt(fr1*fr1*sinA*sinA + fr2*fr2*cosA*cosA)) + 1;

    T_STROKE := 1;
    For y := minY to maxY Do Begin
      DrawSpansForRow(y);
    End;
    T_STROKE := ts - 0.5;
End;

Procedure SP_DrawEllipse32Alpha(CX, CY, Rx, Ry: Integer; Angle: aFloat);
Var
  cosA, sinA: aFloat;

  Procedure DrawConnectedEllipse;
  Var
    t, stepSize: aFloat;
    x, y: aFloat;
    pixelX, pixelY: Integer;
    lastPixelX, lastPixelY: Integer;
    firstPixelX, firstPixelY: Integer;
    hasFirst: Boolean;
    numSteps, i: Integer;
  Begin
    numSteps := Ceil(Pi * (3 * (Rx + Ry) - sqrt((3 * Rx + Ry) * (Rx + 3 * Ry)))) div 2;
    numSteps := Max(numSteps, 32);

    stepSize := (2 * Pi) / numSteps;
    hasFirst := False;

    firstPixelX := -1;
    firstPixelY := -1;
    lastPixelX := -1;
    lastPixelY := -1;

    For i := 0 to numSteps Do Begin
      t := i * stepSize;
      x := Rx * cos(t) * cosA - Ry * sin(t) * sinA;
      y := Rx * cos(t) * sinA + Ry * sin(t) * cosA;
      pixelX := Round(x) + CX;
      pixelY := Round(y) + CY;

      If not hasFirst Then Begin
        firstPixelX := pixelX;
        firstPixelY := pixelY;
        lastPixelX := pixelX;
        lastPixelY := pixelY;
        hasFirst := True;
      End Else Begin
        If (pixelX <> lastPixelX) or (pixelY <> lastPixelY) Then Begin
          SP_DrawLine32ExAlpha(lastPixelX, lastPixelY, pixelX, pixelY);
          lastPixelX := pixelX;
          lastPixelY := pixelY;
        End;
      End;
    End;
    If (lastPixelX <> firstPixelX) or (lastPixelY <> firstPixelY) Then Begin
      SP_DrawLine32ExAlpha(lastPixelX, lastPixelY, firstPixelX, firstPixelY);
    End;
  End;

Begin

  if (rX = 0) or (ry = 0) then exit;

  If Rx = Ry Then

    SP_DrawCircle32Alpha(Cx, Cy, Rx)

  Else Begin

    If T_STROKE > 1 Then Begin
      SP_DrawThickEllipse32(CX, CY, Rx, Ry, Angle);
      Inc(Rx, Ceil(T_STROKE / 2));
      Inc(Ry, Ceil(T_STROKE / 2));
    End Else Begin
      cosA := cos(Angle);
      sinA := sin(Angle);
      DrawConnectedEllipse;
    End;

  End;

End;

Procedure SP_DrawSolidEllipse32Alpha(CX, CY, Rx, Ry: Integer; Angle: aFloat);
Var
  fr1, fr2, cosA, sinA: aFloat;
  y, minY, maxY: NativeInt;
  Ink: LongWord;

  Procedure DrawSpan(X1, X2, Y: Integer);
  Var
    DstA: pLongWord;
  Begin
    X1 := Max(T_CLIPX1, X1);
    X2 := Min(T_CLIPX2 -1, X2);
    If X2 > X1 Then Begin
      DstA := pLongWord(NativeUInt(SCREENPOINTER) + (X1 * SizeOf(RGBA)) + (Y * SCREENSTRIDE));
      While X2 >= X1 Do Begin
        DstA^ := SP_AlphaBlend(DstA^, Ink);
        Inc(DstA);
        Dec(X2);
      End;
    End;
  End;

  Function SolveEllipseForX(rowY: aFloat; out x1, x2: aFloat): Boolean;
  Var
    A, B, C, discriminant, sqrtDisc: aFloat;
    cos2, sin2, cossin: aFloat;
  Begin
    cos2 := cosA * cosA;
    sin2 := sinA * sinA;
    cossin := cosA * sinA;
    A := cos2/(fr1*fr1) + sin2/(fr2*fr2);
    B := 2 * rowY * cossin * (1/(fr1*fr1) - 1/(fr2*fr2));
    C := rowY*rowY * (sin2/(fr1*fr1) + cos2/(fr2*fr2)) - 1;
    discriminant := B*B - 4*A*C;
    If discriminant < 0 Then Begin
      Result := False;
      Exit;
    End;
    sqrtDisc := sqrt(discriminant);
    x1 := (-B - sqrtDisc) / (2*A);
    x2 := (-B + sqrtDisc) / (2*A);
    Result := True;
  End;

  Procedure DrawSpansForRow(rowY: Integer);
  Var
    x1, x2, testY: aFloat;
    startX, endX: Integer;
  Begin
    testY := rowY;

    If SolveEllipseForX(testY, x1, x2) Then Begin
      startX := Round(x1);
      endX := Round(x2);
      DrawSpan(startX + cX, endX + cX, rowY + Cy);
    End;
  End;

Begin

  if (rX = 0) or (ry = 0) then exit;

  if rx = ry then

    SP_DrawSolidCircle32Alpha(Cx, Cy, Rx)

  Else Begin

    If T_INVERSE = 0 Then
      Ink := T_INK
    Else
      Ink := T_PAPER;

    fr1 := rx;
    fr2 := ry;
    cosA := cos(Angle);
    sinA := sin(Angle);
    minY := -Round(sqrt(fr1*fr1*sinA*sinA + fr2*fr2*cosA*cosA)) - 1;
    maxY := Round(sqrt(fr1*fr1*sinA*sinA + fr2*fr2*cosA*cosA)) + 1;

    For y := Max(T_CLIPY1 - cY, minY) to Min(T_CLIPY2 - cY, maxY) Do
      DrawSpansForRow(y);

  End;

End;

Procedure SP_DrawSolidCircle32Alpha(CX, CY, R: Integer);
var
  x, y: Integer;
  p: Integer;
  Ink: LongWord;

  Procedure DrawSpan(X1, X2, Y_scanline: Integer);
  var
    DstA: pLongWord;
  Begin
    if (y_scanline >= T_CLIPY1) and (y_scanline < T_CLIPY2) then begin
      X1 := Max(T_CLIPX1, X1);
      X2 := Min(T_CLIPX2 -1, X2);
      If X2 > X1 Then Begin
        DstA := pLongWord(NativeUInt(SCREENPOINTER) + X1 * SizeOf(RGBA) + (Y_scanline * SCREENSTRIDE));
        While X2 >= X1 Do Begin
          DstA^ := SP_AlphaBlend(DstA^, Ink);
          Inc(DstA);
          Dec(X2);
        End;
      End;
    end;
  End;

begin

  if R <= 0 then Exit;
  If ((CX + R) < 0) or ((CX - R) > SCREENWIDTH) or ((CY + R) < 0) or ((CY - R) > SCREENHEIGHT) Then Exit;

  x := 0;
  y := R;
  p := 1 - R;
  Ink := T_INK;

  while x <= y do
  begin
    if x < y then
    begin
      DrawSpan(CX - y, CX + y, CY + x);
      if x > 0 then DrawSpan(CX - y, CX + y, CY - x);
    end;
    if p < 0 then
    begin
      p := p + (2 * x) + 3;
      Inc(x);
    end
    else
    begin
      DrawSpan(CX - x, CX + x, CY + y);
      if y > 0 then DrawSpan(CX - x, CX + x, CY - y);
      p := p + (2 * (x - y)) + 5;
      Inc(x);
      Dec(y);
    end;
  end;

end;

Procedure SP_DrawCircle32Alpha(CX, CY, R: Integer);
var
  x, y: Integer;
  p: Integer;

  procedure PlotOctantSymmetries_V2(oct_x, oct_y: Integer);
  begin
    SP_SetPixel32Alpha(CX + oct_x, CY + oct_y);
    if oct_y > 0 then SP_SetPixel32Alpha(CX + oct_x, CY - oct_y);
    if oct_x > 0 then
    begin
      SP_SetPixel32Alpha(CX - oct_x, CY + oct_y);
      if oct_y > 0 then SP_SetPixel32Alpha(CX - oct_x, CY - oct_y);
    end;
    if oct_x < oct_y then
    begin
      SP_SetPixel32Alpha(CX + oct_y, CY + oct_x);
      if oct_x > 0 then SP_SetPixel32Alpha(CX + oct_y, CY - oct_x);
      if oct_y > 0 then
      begin
        SP_SetPixel32Alpha(CX - oct_y, CY + oct_x);
        if oct_x > 0 then SP_SetPixel32Alpha(CX - oct_y, CY - oct_x);
      end;
    end;
  end;

begin

  if R = 0 then
  begin
    SP_SetPixel32Alpha(CX, CY);
    If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + CX, SCREENY + CY, SCREENX + CX + 1, SCREENY + CY + 1);
    SP_BankList[0]^.Changed := True;
    Exit;
  end;

  if R <= 0 then Exit;
  If ((CX + R) < 0) or ((CX - R) > SCREENWIDTH) or ((CY + R) < 0) or ((CY - R) > SCREENHEIGHT) Then Exit;

  x := 0;
  y := R;
  p := 1 - R;

  while x <= y do
  begin
    PlotOctantSymmetries_V2(x, y);
    if x = y then break;
    if p < 0 then
    begin
      p := p + (2 * x) + 3;
      Inc(x);
    end
    else
    begin
      p := p + (2 * (x - y)) + 5;
      Inc(x);
      Dec(y);
    end;
  end;

end;

Procedure SP_DrawRectangle32Alpha(X1, Y1, X2, Y2: Integer);
Var
  W, W2, a, b, c, d: Integer;
  Dst: pLongWord;
  Ink: LongWord;
Begin

  If Y1 > Y2 Then Begin W := Y1; Y1 := Y2; Y2 := W; End;
  If X1 > X2 Then Begin W := X1; X1 := X2; X2 := W; End;

  If T_STROKE > 1 Then Begin

    W := Floor(T_STROKE / 2);

    a := X1 - W;
    b := Y1 - W;
    c := X2 + W;
    d := Y2 + W;

    SP_DrawSolidRectangle32Alpha(a, b, c, Round(b + T_STROKE) -1);
    SP_DrawSolidRectangle32Alpha(a, Round(b + T_STROKE), a + Round(T_STROKE) -1, Round(d - T_STROKE));
    SP_DrawSolidRectangle32Alpha(c - Round(T_STROKE) +1, Round(b + T_STROKE), c, Round(d - T_STROKE));
    SP_DrawSolidRectangle32Alpha(a, Round(d - T_STROKE) +1, c, d);

  End Else Begin

    If T_INVERSE = 0 Then
      Ink := T_INK
    Else
      Ink := T_PAPER;

    W := X2 - X1;
    Dst := pLongWord(NativeInt(SCREENPOINTER) + (SCREENSTRIDE * Y1) + (X1 * SizeOf(RGBA)));

    If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X1, SCREENY + Y1, SCREENX + X2 +1, SCREENY + Y2 +1);

    If (Y1 >= T_CLIPY1) And (Y1 < T_CLIPY2) Then Begin // top edge
      W2 := X1;
      While W2 <= X2 Do Begin
        If (W2 >= T_CLIPX1) And (W2 < T_CLIPX2) Then
          Dst^ := SP_AlphaBlend(Dst^, Ink);
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
          Dst^ := SP_AlphaBlend(Dst^, Ink);
        Inc(Dst, X2 - X1);
        If (X2 >= T_CLIPX1) And (X2 < T_CLIPX2) Then // right edge
          Dst^ := SP_AlphaBlend(Dst^, Ink);
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
            Dst^ := SP_AlphaBlend(Dst^, Ink);
          Inc(Dst);
          Inc(W2);
        End;
      End;

  End;

End;

Procedure SP_DrawSolidRectangle32Alpha(X1, Y1, X2, Y2: Integer);
Var
  T, W: Integer;
  Dst: pLongWord;
  Ink: LongWord;
Begin

  If X1 > X2 Then Begin T := X1; X1 := X2; X2 := T; End;
  If Y1 > Y2 Then Begin T := Y1; Y1 := Y2; Y2 := T; End;

  If X1 < 0 Then X1 := 0; If X1 >= SCREENWIDTH Then Exit;
  If Y1 < 0 Then Y1 := 0; If Y1 >= SCREENHEIGHT Then Exit;
  If X2 < 0 Then Exit; If X2 >= SCREENWIDTH Then X2 := SCREENWIDTH -1;
  If Y2 < 0 Then Exit; If Y2 >= SCREENHEIGHT Then Y2 := SCREENHEIGHT -1;

  If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X1, SCREENY + Y1, SCREENX + X2 +1, SCREENY + Y2 +1);
  Dst := pLongWord(NativeUInt(SCREENPOINTER) + (SCREENSTRIDE * Y1) + (X1 * SizeOf(RGBA)));

  If T_INVERSE = 0 Then
    Ink := T_INK
  Else
    Ink := T_PAPER;

  While Y1 <= Y2 Do Begin
    If (Y1 >= T_CLIPY1) And (Y1 < T_CLIPY2) Then Begin
      W := X1;
      While W <= X2 Do Begin
        If (W >= T_CLIPX1) And (W < T_CLIPX2) Then
          Dst^ := SP_AlphaBlend(Dst^, Ink);
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

  Function SetFontAttrs(ID: Integer): Integer;
  Begin
    Result := SP_FindBankID(ID);
    If Result <> SP_ERR_BANK_ID_NOT_FOUND Then Begin
      Bank := SP_BankList[Result];
      FontBank := @Bank^.Info[0];
      CharW := Max(1, Round(FontBank^.WIDTH * ScaleX));
      CharH := Max(1, Round(FontBank^.HEIGHT * ScaleY));
      Cw := CharW;
      Ch := CharH;
      If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
        Transparent := T_TRANSPARENT And (FontBank^.Transparent <> $FFFF);
        TC := FontBank^.Transparent And $FF;
      End Else Begin
        Transparent := T_TRANSPARENT;
        TC := 0;
      End;
    End Else
      Error.Code := Result;
  End;

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
      BankID := SP_GetFontBank;

    Idx := SetFontAttrs(BankID);
    If Idx <> SP_ERR_BANK_ID_NOT_FOUND Then Begin

      IsScaled := (ScaleX <> 1) Or (ScaleY <> 1);
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
              sx := (FontBank^.WIDTH Shl 16) Div CharW;
              sy := (FontBank^.HEIGHT Shl 16) Div CharH;
              yp := 0;
              While CharH > 0 Do Begin
                pIdx := Char;
                xp := 0;
                Inc(pIdx, FontBank^.WIDTH * (yp Shr 16));
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
           15:
              Begin // FONT
                T_FONT := pLongWord(@Text[Idx+1])^;
                SetFontAttrs(T_FONT);
                If Error.Code <> SP_ERR_OK Then Exit;
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
                If WINORIGIN Then Begin
                  X := Round(X - SORGX);
                  Y := Round(Y - SORGY);
                End;
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
                If WINORIGIN Then
                  Y := Round(Y - SORGY);
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
                  CharW := Max(1, Trunc(FontBank^.WIDTH * ScaleX));
                  CharH := Max(1, Trunc(FontBank^.HEIGHT * ScaleY));
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

  Function SetFontAttrs(ID: Integer): Integer;
  Begin
    Result := SP_FindBankID(ID);
    If Result <> SP_ERR_BANK_ID_NOT_FOUND Then Begin
      Bank := SP_BankList[Result];
      FontBank := @Bank^.Info[0];
      CharW := Max(1, Round(FontBank^.WIDTH * ScaleX));
      CharH := Max(1, Round(FontBank^.HEIGHT * ScaleY));
      Cw := CharW;
      Ch := CharH;
      If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
        Transparent := T_TRANSPARENT And (FontBank^.Transparent <> $FFFF);
        TC := FontBank^.Transparent And $FF;
      End Else Begin
        Transparent := T_TRANSPARENT;
        TC := 0;
      End;
    End;
  End;

Begin

  If T_INVERSE <> 0 Then Begin
    Idx := Ink;
    Ink := Paper;
    Paper := Idx;
  End;
  ScaleX := T_SCALEX;
  ScaleY := T_SCALEY;

  If BankID = -1 Then // Use the system font?
    BankID := SP_GetFontBank;

  Result := SetFontAttrs(BankID);
  If Result <> SP_ERR_BANK_ID_NOT_FOUND Then Begin

    IsScaled := (ScaleX <> 1) Or (ScaleY <> 1);
    Coord := SCREENPOINTER;
    Inc(Coord, (SCREENWIDTH * Y) + X);

    Idx := 1;
    While Idx <= Length(Text) Do Begin

      If Text[Idx] >= ' ' Then Begin

        Char := @Bank^.Memory[FontBank^.Font_Info[Byte(Text[Idx])].Data];
        If SCREENVISIBLE Then SP_SetDirtyRect(SCREENX + X, SCREENY + Y, SCREENX + X + CharW, SCREENY + Y + CharH);

        If IsScaled Then Begin
          // Scaled character
          sx := (FontBank^.WIDTH Shl 16) Div CharW;
          sy := (FontBank^.HEIGHT Shl 16) Div CharH;
          yp := 0;
          While CharH > 0 Do Begin
            pIdx := Char;
            xp := 0;
            Inc(pIdx, FontBank^.WIDTH * (yp Shr 16));
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
         15:
            Begin // FONT
              T_FONT := pLongWord(@Text[Idx+1])^;
              If SetFontAttrs(T_FONT) = SP_ERR_BANK_ID_NOT_FOUND Then Exit;
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
              If WINORIGIN Then Begin
                X := Round(X - SORGX);
                Y := Round(Y - SORGY);
              End;
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
              If WINORIGIN Then
                Y := Round(Y - SORGY);
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
                CharW := Max(1, Trunc(FontBank^.WIDTH * ScaleX));
                CharH := Max(1, Trunc(FontBank^.HEIGHT * ScaleY));
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

Procedure SP_PolygonFill32Alpha(Var Points: Array of TSP_Point; TextureStr: aString; tW, tH: LongWord);
Begin
  // TODO Alpha
End;

Procedure SP_DrawTexRectangle32Alpha(X1, Y1, X2, Y2: Integer; TextureStr: aString; tW, tH: LongWord);
Begin
  // TODO Alpha
End;

Procedure SP_DrawTexEllipse32Alpha(CX, CY, Rx, Ry: Integer; Angle: aFloat; TextureStr: aString; tW, tH: LongWord);
Begin
  // TODO Alpha
End;

end.
