unit SP_Testing;

interface

implementation

type

  TTriangle = array[0..2] of TSP_Point;

function IsConvex(P1, P2, P3: TSP_Point): Boolean;
begin
  Result := ((P2.X - P1.X) * (P3.Y - P1.Y) - (P3.X - P1.X) * (P2.Y - P1.Y)) > 0;
end;

function IsPointInTriangle(P, A, B, C: TSP_Point): Boolean;
var
  v0, v1, v2: TSP_Point;
  dot00, dot01, dot02, dot11, dot12, invDenom, u, v: Single;
begin
  v0.X := C.X - A.X; v0.Y := C.Y - A.Y;
  v1.X := B.X - A.X; v1.Y := B.Y - A.Y;
  v2.X := P.X - A.X; v2.Y := P.Y - A.Y;

  dot00 := v0.X * v0.X + v0.Y * v0.Y;
  dot01 := v0.X * v1.X + v0.Y * v1.Y;
  dot02 := v0.X * v2.X + v0.Y * v2.Y;
  dot11 := v1.X * v1.X + v1.Y * v1.Y;
  dot12 := v1.X * v2.X + v1.Y * v2.Y;

  invDenom := 1 / (dot00 * dot11 - dot01 * dot01);
  u := (dot11 * dot02 - dot01 * dot12) * invDenom;
  v := (dot00 * dot12 - dot01 * dot02) * invDenom;

  Result := (u >= 0) and (v >= 0) and (u + v < 1);
end;

procedure TriangulatePolygon(const Points: array of TSP_Point; out Triangles: TArray<TArray<TSP_Point>>);
var
  i, j, k, n: Integer;
  V: TArray<Integer>;
  VertexCount: Integer;
begin
  VertexCount := Length(Points);
  SetLength(V, VertexCount);
  for i := 0 to VertexCount - 1 do
    V[i] := i;

  n := VertexCount;
  k := 2 * n;
  SetLength(Triangles, 0);

  while n > 2 do
  begin
    if (k <= 0) then
      Exit;

    j := (j + 1) mod n;
    k := k - 1;

    if (n <= 3) then
    begin
      SetLength(Triangles, Length(Triangles) + 1);
      SetLength(Triangles[High(Triangles)], 3);
      Triangles[High(Triangles)][0] := Points[V[0]];
      Triangles[High(Triangles)][1] := Points[V[1]];
      Triangles[High(Triangles)][2] := Points[V[2]];
      Break;
    end;

    i := j;
    k := (i + 1) mod n;
    j := (i + 2) mod n;

    if (Points[V[i]].Y < Points[V[k]].Y) or
       ((Points[V[i]].Y = Points[V[k]].Y) and (Points[V[i]].X < Points[V[k]].X)) then
    begin
      continue;
    end;

    SetLength(Triangles, Length(Triangles) + 1);
    SetLength(Triangles[High(Triangles)], 3);
    Triangles[High(Triangles)][0] := Points[V[i]];
    Triangles[High(Triangles)][1] := Points[V[k]];
    Triangles[High(Triangles)][2] := Points[V[j]];

    for i := k to n - 2 do
      V[i] := V[i + 1];
    n := n - 1;
    k := 2 * n;
  end;
end;

procedure DrawTriangle(V1, V2, V3: TSP_Point; Ink: Byte);
const
  q = 8; // Block size
var
  area: aFloat;
  Y1, Y2, Y3: NativeInt;
  X1, X2, X3: NativeInt;
  DX12, DX23, DX31: NativeInt;
  DY12, DY23, DY31: NativeInt;
  FDX12, FDX23, FDX31: NativeInt;
  FDY12, FDY23, FDY31: NativeInt;
  C1, C2, C3: NativeInt;
  MinX, MinY, MaxX, MaxY: NativeInt;
  x, y, ix, iy: NativeInt;
  x0, y0: NativeInt;
  a00, a10, a01, a11: Boolean;
  b00, b10, b01, b11: Boolean;
  c00, c10, c01, c11: Boolean;
  a, b, c: NativeInt;
  ScrPtr, BoxPtr, RowPtr: pByte;
  CX1, CX2, CX3: NativeInt;
  CY1, CY2, CY3: NativeInt;
  Temp: TSP_Point;

  function RoundToFixedPoint(Value: Single): NativeInt;
  begin
    Result := Round(Value * 16.0);
  end;

Begin

  Area := (V2.X - V1.X) * (V3.Y - V1.Y) - (V3.X - V1.X) * (V2.Y - V1.Y);
  if Area > 0 then
  begin
    Temp := V2;
    V2 := V3;
    V3 := Temp;
  end;

  // 28.4 fixed-point coordinates
  Y1 := RoundToFixedPoint(v1.y);
  Y2 := RoundToFixedPoint(v2.y);
  Y3 := RoundToFixedPoint(v3.y);
  X1 := RoundToFixedPoint(v1.x);
  X2 := RoundToFixedPoint(v2.x);
  X3 := RoundToFixedPoint(v3.x);

  // Deltas
  DX12 := X1 - X2;
  DX23 := X2 - X3;
  DX31 := X3 - X1;
  DY12 := Y1 - Y2;
  DY23 := Y2 - Y3;
  DY31 := Y3 - Y1;

  // Fixed-point deltas
  FDX12 := DX12 Shl 4;
  FDX23 := DX23 Shl 4;
  FDX31 := DX31 Shl 4;
  FDY12 := DY12 Shl 4;
  FDY23 := DY23 Shl 4;
  FDY31 := DY31 Shl 4;

  // Bounding rectangle
  minx := (min(X1, min(X2, X3)) + $F) Shr 4;
  maxx := (max(X1, max(X2, X3)) + $F) Shr 4;
  miny := (min(Y1, min(Y2, Y3)) + $F) Shr 4;
  maxy := (max(Y1, max(Y2, Y3)) + $F) Shr 4;

  // Start in corner of 8x8 block
  minx := minx And not (q - 1);
  miny := miny And not (q - 1);

  // Half-edge constants
  C1 := DY12 * X1 - DX12 * Y1;
  C2 := DY23 * X2 - DX23 * Y2;
  C3 := DY31 * X3 - DX31 * Y3;

  // Correct for fill convention
  if ((DY12 < 0) or ((DY12 = 0) and (DX12 > 0))) Then Inc(C1);
  if ((DY23 < 0) or ((DY23 = 0) and (DX23 > 0))) Then Inc(C2);
  if ((DY31 < 0) or ((DY31 = 0) and (DX31 > 0))) Then Inc(C3);

  ScrPtr := SCREENPOINTER;
  Inc(ScrPtr, miny * SCREENWIDTH);

  // Loop through blocks
  y := miny;
  While y < maxy Do Begin
    x := minx;
    RowPtr := ScrPtr + minx;
    While x < maxx Do Begin

      // Corners of block
      x0 := x Shl 4;
      x1 := (x + q - 1) Shl 4;
      y0 := y Shl 4;
      y1 := (y + q - 1) Shl 4;

      // Evaluate half-space functions
      a00 := (C1 + DX12 * y0 - DY12 * x0) > 0;
      a10 := (C1 + DX12 * y0 - DY12 * x1) > 0;
      a01 := (C1 + DX12 * y1 - DY12 * x0) > 0;
      a11 := (C1 + DX12 * y1 - DY12 * x1) > 0;
      a := (Ord(a00) Shl 0) or (Ord(a10) Shl 1) or (Ord(a01) Shl 2) or (Ord(a11) Shl 3);

      b00 := (C2 + DX23 * y0 - DY23 * x0) > 0;
      b10 := (C2 + DX23 * y0 - DY23 * x1) > 0;
      b01 := (C2 + DX23 * y1 - DY23 * x0) > 0;
      b11 := (C2 + DX23 * y1 - DY23 * x1) > 0;
      b := (Ord(b00) Shl 0) or (Ord(b10) Shl 1) or (Ord(b01) Shl 2) or (Ord(b11) Shl 3);

      c00 := (C3 + DX31 * y0 - DY31 * x0) > 0;
      c10 := (C3 + DX31 * y0 - DY31 * x1) > 0;
      c01 := (C3 + DX31 * y1 - DY31 * x0) > 0;
      c11 := (C3 + DX31 * y1 - DY31 * x1) > 0;
      c := (Ord(c00) Shl 0) or (Ord(c10) Shl 1) or (Ord(c01) Shl 2) or (Ord(c11) Shl 3);

      // Skip block when outside an edge
      if (a <> 0) And (b <> 0) And (c <> 0) Then Begin
        BoxPtr := RowPtr;
        // Accept whole block when totally covered
        If (a = $F) And (b = $F) And (c = $F) Then Begin
          For iy := 0 to q -1 Do Begin
            For ix := 0 to q -1 Do Begin
              BoxPtr^ := Ink;
              Inc(BoxPtr);
            End;
            Inc(BoxPtr, SCREENWIDTH - q);
          End;
        End Else Begin
          CY1 := C1 + DX12 * y0 - DY12 * x0;
          CY2 := C2 + DX23 * y0 - DY23 * x0;
          CY3 := C3 + DX31 * y0 - DY31 * x0;
          For iy := y To y + q -1 Do Begin
            CX1 := CY1;
            CX2 := CY2;
            CX3 := CY3;
            For ix := x To x +q -1 Do Begin
              If (CX1 > 0) And (CX2 > 0) And (CX3 > 0) Then
                BoxPtr^ := Ink;
              Inc(BoxPtr);
              Dec(CX1, FDY12);
              Dec(CX2, FDY23);
              Dec(CX3, FDY31);
            End;
            Inc(CY1, FDX12);
            Inc(CY2, FDX23);
            Inc(CY3, FDX31);
            Inc(BoxPtr, SCREENWIDTH - q);
          End;
        End;
      End;
      Inc(x, q);
      Inc(RowPtr, q);

    End;

    Inc(y, q);
    Inc(ScrPtr, SCREENWIDTH * q);

  End;

End;

{
Procedure DrawTriangleHalfSpace(V1, V2, V3: TSP_Point; Ink: Byte);
Var
  Ptr, Ptr2: pByte;
  minx, maxx, miny, maxy, x, y: Integer;
  x1, y1, x2, y2, x3, y3: aFloat;
Begin

  y1 := v1.y;
  y2 := v2.y;
  y3 := v3.y;

  x1 := v1.x;
  x2 := v2.x;
  x3 := v3.x;

  // Bounding rectangle
  minx := Floor(min(x1, min(x2, x3)));
  maxx := Ceil(max(x1, max(x2, x3)));
  miny := Floor(min(y1, min(y2, y3)));
  maxy := Ceil(max(y1, max(y2, y3)));

  Ptr := SCREENPOINTER;
  Inc(Ptr, miny * SCREENWIDTH + minx);

  // Scan through bounding rectangle

  For y := miny To maxy Do Begin
    Ptr2 := Ptr;
    For x := minx To maxx Do Begin
      // When all half-space functions positive, pixel is in triangle
      if (((x1 - x2) * (y - y1) - (y1 - y2) * (x - x1)) > 0) And
         (((x2 - x3) * (y - y2) - (y2 - y3) * (x - x2)) > 0) And
         (((x3 - x1) * (y - y3) - (y3 - y1) * (x - x3)) > 0) Then
         Ptr2^ := Ink;
      Inc(Ptr2);
    End;
    Inc(Ptr, SCREENWIDTH);
  End;

End;
}
{
Procedure DrawTriangle(t0, t1, t2: TSP_Point; Ink: Byte);
Var
  i, j, total_height, segment_Height, alpha, beta: aFloat;
  second_half: Boolean;
  A, B: TSP_Point;

  Procedure Swap(var t1, t2: TSP_Point);
  Var
    Temp: TSP_Point;
  Begin
    Temp := t1;
    t1 := t2;
    t2 := Temp;
  End;

Begin
  T_INK := Ink;
  If t0.y > t1.y Then Swap(t0, t1);
  If t0.y > t2.y Then Swap(t0, t2);
  If t1.y > t2.y Then Swap(t1, t2);
  total_height := t2.y - t0.y;
  i := 0;
  While i < total_Height Do Begin
    second_Half := (i > t1.y - t0.y) or (t1.y = t0.y);
    if second_Half then Begin
      segment_height := t2.y - t1.y;
      beta := (i - (t1.y - t0.y)) / segment_Height;
      B := t1 + (t2 - t1) * beta;
    End else Begin
      segment_Height := t1.y - t0.y;
      beta := i / segment_Height;
      B := t0 + (t1 - t0) * beta;
    End;
    alpha := i / total_height;
    A := t0 + (t2 - t0) * alpha;
    If A.x > B.x Then Swap(A, B);
    j := A.X;
    While j <= B.X Do Begin
      SP_SetPixel(j, t0.y + i);
      j := j + 1;
    End;
    i := i + 1;
  End;
End;
}

{
Procedure DrawTriangle(t0, t1, t2: TSP_Point; Ink: Byte);
Var
  x, y, a, b, total_Height, segment_height: Integer;

  Procedure Swap(var t1, t2: TSP_Point);
  Var
    Temp: TSP_Point;
  Begin
    Temp := t1;
    t1 := t2;
    t2 := Temp;
  End;

Begin
  T_INK := Ink;
  If t0.y > t1.y Then Swap(t0, t1);
  If t0.y > t2.y Then Swap(t0, t2);
  If t1.y > t2.y Then Swap(t1, t2);
  total_height := Ceil(t2.y - t0.y);
  If t0.y <> t1.y Then Begin
    segment_height := Ceil(t1.y - t0.y);
    For y := Floor(t0.y) to Ceil(t1.y) Do Begin
      A := Floor(t0.x + ( t2.x - t0.x ) * ( y - t0.y ) / total_height);
			B := Ceil(t0.x + ( t1.x - t0.x ) * ( y - t0.y ) / segment_height);
      SP_DrawLineTo(A, y, B, y, Ink);
    End;
  End;
  If t1.Y <> t2.Y Then Begin
    segment_height := Ceil(t2.y - t1.y);
    For y := Floor(t1.y) to Ceil(t2.y) Do Begin
      A := Floor(t0.x + ( t2.x - t0.x ) * ( y - t0.y ) / total_height);
      B := Ceil(t1.x + ( t2.x - t1.x ) * ( y - t1.y ) / segment_height);
      SP_DrawLineTo(A, y, B, y, Ink);
    End;
  End;
End;
}
procedure SP_PolygonSolidFill(Var Points: Array Of TSP_Point);
var
  Triangles: TArray<TArray<TSP_Point>>;
  Ink: Byte;
  i: Integer;
begin
  if T_INVERSE = 1 then
    Ink := T_PAPER
  else
    Ink := T_INK;

  // Triangulate the polygon
  TriangulatePolygon(Points, Triangles);

  // Draw each triangle
  for i := 0 to High(Triangles) do
  begin
    DrawTriangle(Triangles[i][0], Triangles[i][1], Triangles[i][2], Ink);
  end;

  SP_BankList[0]^.Changed := True;
end;


procedure FillPolygon(Points: array of TPoint);
const
  FixedPointFactor = 16; // 16.0 fixed-point representation
  FixedPointMask = FixedPointFactor - 1;
var
  NodeX: array of Integer;
  Nodes, PixelY, I, J, MinY, MaxY: Integer;
  NumPoints: Integer;
  DeltaY, InterpolatedX: Integer;
begin
  NumPoints := Length(Points);
  SetLength(NodeX, NumPoints);

  // Determine the bounding box of the polygon
  MinY := Points[0].Y;
  MaxY := Points[0].Y;
  for I := 1 to NumPoints - 1 do
  begin
    if Points[I].Y < MinY then
      MinY := Points[I].Y;
    if Points[I].Y > MaxY then
      MaxY := Points[I].Y;
  end;

  // Scanline algorithm
  for PixelY := MinY to MaxY do
  begin
    Nodes := 0;
    J := NumPoints - 1;

    for I := 0 to NumPoints - 1 do
    begin
      DeltaY := Points[J].Y - Points[I].Y;
      if DeltaY = 0 then
        DeltaY := 1;

      // Check if edge (Points[I], Points[J]) crosses the horizontal line at PixelY
      if ((Points[I].Y <= PixelY) and (Points[J].Y > PixelY)) or
         ((Points[J].Y <= PixelY) and (Points[I].Y > PixelY)) or
         ((Points[I].Y = PixelY) and (Points[J].Y = PixelY)) then
      begin
        // Calculate the x-coordinate where the edge crosses the horizontal line
        InterpolatedX := Points[I].X * FixedPointFactor +
          (PixelY * FixedPointFactor - Points[I].Y * FixedPointFactor) div DeltaY *
          (Points[J].X * FixedPointFactor - Points[I].X * FixedPointFactor) div FixedPointFactor;

        NodeX[Nodes] := (InterpolatedX + FixedPointMask) div FixedPointFactor;
        Inc(Nodes);
      end;
      J := I;
    end;

    // Sort nodes
    TArray.Sort<Integer>(NodeX, TComparer<Integer>.Default, 0, Nodes);

    // Fill between node pairs
    for I := 0 to (Nodes div 2) - 1 do
    begin
      DrawLine(NodeX[2 * I], PixelY, NodeX[2 * I + 1], PixelY);
    end;
  end;
end;

procedure DrawLine(x1, y1, x2, y2: Integer);
begin
  // Implementation of drawing a line from (x1, y1) to (x2, y2)
end;

Procedure SP_PolygonSolidFill(Var Points: Array of TSP_Point; Outline: Boolean);   // Uses two nodex arrays to generate thickness. Has issues with missing lines and stepping.
Var
  MinY, MaxY, MinX, MaxX, cx, cy: Integer;
  Idx, I, J, Nodes, NumPoints: Integer;
  NodeX, NodeX2: Array of Integer;
  FirstScan: Boolean;
  PixelY: aFloat;
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

    SetLength(NodeX, NumPoints);
    SetLength(NodeX2, NumPoints);

    FirstScan := True;
    PixelY := MinY;
    While PixelY <= MaxY Do Begin

      Nodes := 0;
      J := NumPoints -1;
      For I := 0 To NumPoints -1 Do Begin
        If ((Points[I].Y < PixelY) And (Points[J].Y >= PixelY)) or ((Points[J].Y < PixelY) And (Points[I].Y >= PixelY)) Then Begin
          NodeX[Nodes] := Round(Points[I].X + (PixelY - 1 - Points[I].Y) / (Points[J].Y - Points[I].Y) * (Points[J].X - Points[I].X));
          NodeX2[Nodes] := Round(Points[I].X + (PixelY - Points[I].Y) / (Points[J].Y - Points[I].Y) * (Points[J].X - Points[I].X - 0.5));
          Inc(Nodes);
        End;
        J := I;
      End;

      I := 0;
      While I < Nodes -1 Do
        If NodeX[I] > NodeX[I+1] Then Begin
          NodeX[I] := NodeX[I] Xor NodeX[I+1]; NodeX[I+1] := NodeX[I] Xor NodeX[I+1]; NodeX[I] := NodeX[I] Xor NodeX[I+1];
          NodeX2[I] := NodeX2[I] Xor NodeX2[I+1]; NodeX2[I+1] := NodeX2[I] Xor NodeX2[I+1]; NodeX2[I] := NodeX2[I] Xor NodeX2[I+1];
          If I > 0 Then Dec(I);
        End Else
          Inc(I);

      I := 0;
      While I < Nodes -1 Do Begin
        If NodeX[I] >= T_CLIPX2 Then Break;
        If NodeX[I+1] > T_CLIPX1 Then Begin
          If NodeX[I] < T_CLIPX1 Then NodeX[I] := T_CLIPX1;
          If NodeX2[I+1] >= T_CLIPX2 Then NodeX2[I+1] := T_CLIPX2 -1;
          Ptr := SCREENPOINTER;
          Inc(Ptr, Round(PixelY * SCREENSTRIDE) + Min(NodeX[I], NodeX2[I]));
          For J := Min(NodeX[I], NodeX2[I]) To Max(NodeX[I+1], NodeX2[I+1]) Do Begin
            IF T_OVER = 0 Then
              Ptr^ := Ink
            Else
              SP_OverPixelPtrVal(Ptr, Ink, T_OVER);
            Inc(Ptr);
          End;
        End;
        Inc(I, 2);
      End;

      PixelY := PixelY + 1;

    End;

    DRPOSX := Points[0].X;
    DRPOSY := Points[0].Y;

  End Else

    SP_PolygonSolidFill32(Points, MinX, MinY, MaxX, MaxY, Ink);

  SP_BankList[0]^.Changed := True;

End;


end.
