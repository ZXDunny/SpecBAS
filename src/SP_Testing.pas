unit SP_Testing;

{$INCLUDE SpecBAS.inc}

interface

uses
  System.SysUtils, System.Math, SP_Util;

type
  TPointFloat = record
    X, Y: aFloat;
  end;

procedure SP_DrawThickEllipseRotated(CX, CY, R1, R2: Integer; Angle: aFloat; Stroke: Integer);

implementation

Uses SP_Graphics;

procedure SP_DrawThickEllipseRotated(CX, CY, R1, R2: Integer; Angle: aFloat; Stroke: Integer);
var
  fr1, fr2, ir1, ir2, id, rd, ys, ox1, ix1: aFloat;
  y: Integer;
  x: Integer;
  cosA, sinA: aFloat;
  OuterPoints, InnerPoints: TArray<TPointFloat>;
  OuterPointCount, InnerPointCount, LeftMostOuter, RightMostOuter, LeftMostInner, RightMostInner: Integer;
  i, j: Integer;
  RotatedOuterPoints, RotatedInnerPoints: TArray<TPointFloat>;
  sx, sy, sx2, sy2: Integer;

  function RoundToInt(Value: aFloat): Integer;
  begin
    Result := Round(Value);
  end;

begin
  fr1 := R1 + Stroke / 2;
  fr2 := R2 + Stroke / 2;
  ir1 := fr1 - Stroke;
  ir2 := fr2 - Stroke;
  id := ir1 / ir2;
  rd := fr1 / fr2;

  OuterPointCount := 0;
  InnerPointCount := 0;
  SetLength(OuterPoints, 0);
  SetLength(InnerPoints, 0);

  // Generate unrotated points
  for y := -RoundToInt(fr2) to RoundToInt(fr2) do
  begin
    ys := y * rd;
    ox1 := sqrt(fr1 * fr1 - ys * ys);

    if Abs(y) < RoundToInt(ir2) then
    begin
      ys := y * id;
      ix1 := sqrt(ir1 * ir1 - ys * ys);
    end
    else
      ix1 := 0;

    for x := RoundToInt(ix1) to RoundToInt(ox1) do
    begin
      SetLength(OuterPoints, OuterPointCount + 2);
      OuterPoints[OuterPointCount].X := x;
      OuterPoints[OuterPointCount].Y := y;
      OuterPoints[OuterPointCount + 1].X := -x;
      OuterPoints[OuterPointCount + 1].Y := y;
      OuterPointCount := OuterPointCount + 2;
    end;
    if Abs(y) < RoundToInt(ir2) then
    begin
      for x := RoundToInt(ix1) to RoundToInt(ox1) do
      begin
        SetLength(InnerPoints, InnerPointCount + 2);
        InnerPoints[InnerPointCount].X := x;
        InnerPoints[InnerPointCount].Y := y;
        InnerPoints[InnerPointCount + 1].X := -x;
        InnerPoints[InnerPointCount + 1].Y := y;
        InnerPointCount := InnerPointCount + 2;
      end;
    end;
  end;

  // Rotate points
  cosA := Cos(Angle);
  sinA := Sin(Angle);

  SetLength(RotatedOuterPoints, OuterPointCount);
  SetLength(RotatedInnerPoints, InnerPointCount);

  for i := 0 to OuterPointCount - 1 do
  begin
    RotatedOuterPoints[i].X := OuterPoints[i].X * cosA - OuterPoints[i].Y * sinA;
    RotatedOuterPoints[i].Y := OuterPoints[i].X * sinA + OuterPoints[i].Y * cosA;
  end;

  for i := 0 to InnerPointCount - 1 do
  begin
    RotatedInnerPoints[i].X := InnerPoints[i].X * cosA - InnerPoints[i].Y * sinA;
    RotatedInnerPoints[i].Y := InnerPoints[i].X * sinA + InnerPoints[i].Y * cosA;
  end;

  // Fill the rotated outline using SP_SetPixel
  for i := 0 to OuterPointCount - 1 do
  begin
    sx := RoundToInt(RotatedOuterPoints[i].X) + CX;
    sy := RoundToInt(RotatedOuterPoints[i].Y) + CY;
    SP_SetPixel(sx, sy);
  end;

  for i := 0 to InnerPointCount - 1 do
  begin
    sx2 := RoundToInt(RotatedInnerPoints[i].X) + CX;
    sy2 := RoundToInt(RotatedInnerPoints[i].Y) + CY;
    SP_SetPixel(sx2, sy2);
  end;

  //Fill between the points
  for y := -RoundToInt(fr2) to RoundToInt(fr2) do
  begin
    LeftMostOuter := MaxInt;
    RightMostOuter := -9000;
    LeftMostInner := MaxInt;
    RightMostInner := -9000;

    for i := 0 to OuterPointCount - 1 do
    begin
      if RoundToInt(RotatedOuterPoints[i].Y) = y then
      begin
        LeftMostOuter := Min(RoundToInt(RotatedOuterPoints[i].X), LeftMostOuter);
        RightMostOuter := Max(RoundToInt(RotatedOuterPoints[i].X), RightMostOuter);
      end;
    end;

    for i := 0 to InnerPointCount - 1 do
    begin
      if RoundToInt(RotatedInnerPoints[i].Y) = y then
      begin
        LeftMostInner := Min(RoundToInt(RotatedInnerPoints[i].X), LeftMostInner);
        RightMostInner := Max(RoundToInt(RotatedInnerPoints[i].X), RightMostInner);
      end;
    end;

    if (LeftMostOuter <> MaxInt) and (RightMostOuter <> -9000) then
    begin
      if (LeftMostInner <> MaxInt) and (RightMostInner <> -9000) then
      begin
        for x := LeftMostInner + CX to RightMostOuter + CX do
        begin
          SP_SetPixel(x, y + CY);
        end;
      end else begin
        for x := LeftMostOuter + CX to RightMostOuter + CX do
        begin
          SP_SetPixel(x, y + CY);
        end;
      end;
    end;
  end;
end;

end.
