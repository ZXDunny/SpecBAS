unit SP_Math;

interface

Uses Math, SP_Util, SP_Errors;

Function  SP_Polyterm(x, p, q, r: aFloat; n: Integer): aFloat;
Function  SP_Under(x, p, q, r: aFloat; n: Integer): aFloat;
Function  SP_CompSimpson(fn: aString; a, b: aFloat; n: Integer; Var Error: TSP_ErrorCode): aFloat;
Function  Mandel(x, y: aFloat; MaxIters: Integer): Integer;
Function  Perlin(x, y, z: aFloat): aFloat;
Function  OctavePerlin(x, y, z: aFloat; octaves: Integer; persistence: aFloat): aFloat;

implementation

Uses SP_Interpret_PostFix, SP_Variables;

Function SP_Polyterm(x, p, q, r: aFloat; n: Integer): aFloat;
Var
  acc, mul, harm, zeta: aFloat;
  start: Integer;
Begin

  acc := 0;
  mul := 1;

  For start := 1 to n-1 Do Begin

    harm := ln(start);
    If r = 0 Then zeta := 1 Else zeta := exp(harm * r);
    If p = 0 Then harm := 1 Else harm := exp(harm * p);
    mul := mul * x * harm;
    acc := acc + mul * zeta * cos(q * (start - 1));

  End;

  Result := acc;

End;

Function SP_Under(x, p, q, r: aFloat; n: Integer): aFloat;
Var
  acc, harm: aFloat;
  start: Integer;
Begin

  acc := 0;
  For start := 1 To n -1 Do Begin

    harm := x / Start;
    acc := acc + harm + SP_Polyterm(harm, p, q, r, n);

  End;

  Result := SP_Polyterm(acc, r, q, p, n);

End;

Function SP_CompSimpson(fn: aString; a, b: aFloat; n: Integer; Var Error: TSP_ErrorCode): aFloat;
Var
  h, x, S, FnVal: aFloat;
  i, Idx, Idx2, VarOffsetN, ValPosition: Integer;
  ValTkn: paString;
  ParamName: aString;

  Function ExecuteFN: aFloat;
  Begin

    // Executes a function (as in, a DEF FN function in SpecBAS code) set up
    // in the parent proc.

    VarOffsetN := NVLen;
    Idx2 := SP_NewNumVar;
    NumVars[Idx2]^.Content.VarType := SP_SIMPLE;
    NumVars[Idx2]^.Name := ParamName;
    NumVars[Idx2]^.ProcVar := True;
    NumVars[Idx2]^.Content.Value := FnVal;
    NumVars[Idx2]^.ContentPtr := @NumVars[Idx2]^.Content;

    ValPosition := 1;
    SP_InterpretCONTSafe(ValTkn, ValPosition, Error);

    Result := SP_StackPtr^.Val;
    Dec(SP_StackPtr);

    SP_ResizeNumVars(VarOffsetN);

  End;

Begin

  // A more complex function - requires a function to be executed. Find that function now:
  // Must be numeric, and contain one numeric parameter.

  Idx := 0;
  Result := 0;

  While Idx < Length(SP_FnList) Do Begin

    If SP_FnList[Idx].Name = fn Then
      Break
    Else
      Inc(Idx);

  End;

  If Idx < Length(SP_FnList) Then Begin

    // Check the parameter count - must be one.

    If SP_FnList[Idx].ParamCount <> 1 Then Begin

      Error.Code := SP_ERR_PROC_PARAM_COUNT;

    End Else Begin

      // Now check that it's a numeric parameter

      If pFnVar(@SP_FnList[Idx].ParamList[1])^.ID = 1 Then Begin

        Error.Code := SP_ERR_PARAMETER_ERROR;
        Exit;

      End Else Begin

        ParamName := Copy(SP_FnList[Idx].ParamList, 6, Length(SP_FnList[Idx].ParamList));
        ValTkn := @SP_FnList[Idx].Expr;

      End;

    End;

  End Else Begin

    Error.Code := SP_ERR_FN_NOT_FOUND;
    Exit;

  End;

  h := (b - a) / (2 * n);
  FnVal := a;
  S := ExecuteFn;

  If Error.Code <> SP_ERR_OK Then Exit;

  i := 1;
  While I < 2 * n Do Begin
    x := a + h * i;
    FnVal := x;
    s := s + 4 * ExecuteFn;
    If Error.Code <> SP_ERR_OK Then Exit;
    Inc(i, 2);
  End;

  i := 2;
  While I < 2 * n -1 Do Begin
    x := a + h * i;
    FnVal := x;
    S := S + 2 * ExecuteFn;
    If Error.Code <> SP_ERR_OK Then Exit;
    Inc(i, 2);
  End;

  FnVal := b;
  S := S + ExecuteFn;
  Result := h * S / 3;

End;

Function Mandel(x, y: aFloat; MaxIters: Integer): Integer;
Var
  p2y, q, zr, zi, ckr, cki, tmp: aFloat;
  p, ptot: Integer;
Begin

  Result := 0;

  p2y := y * y;
  q := ((x - 0.25) * (x - 0.25)) + p2y;
  If (((x + 1)*(x + 1)) + p2y < 0.0625) or (q * (q + (x - 0.25)) < p2y / 4) Then
    Exit;

  zr := x;
  zi := y;
  p := 0;
  ptot := 8;

  Repeat

    ckr := zr;
    cki := zi;
    Inc(pTot, pTot);
    If pTot > MaxIters Then
      pTot := MaxIters;

    Repeat

      Inc(p);
      tmp := (zr * zr) - (zi * zi) + x;
      zi := (zi * 2 * zr) + y;
      zr := tmp;

      If (zr * zr) + (zi * zi) > 4 Then Begin
        Result := p;
        Exit;
      End Else
        If (zr = ckr) And (zi = cki) Then
          Exit;

    Until p >= ptot;

  Until ptot = MaxIters;

End;

// Perlin noise

Var

  p2: Array[0..511] of Integer = (151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
    190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,
    77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,200,196,
    135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
    223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,
    251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,
    138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
    190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,
    77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,200,196,
    135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
    223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,
    251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,
    138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180);

Function lerp(a, b, x: aFloat): aFloat; inline;
Begin
  result := a + x * (b - a);
End;

Function fade(t: aFloat): aFloat; inline;
Begin
  result := t * t * t * (t * (t * 6 - 15) + 10);
End;

Function grad(hash: Integer; x, y, z: aFloat): aFloat; inline;
Begin
  Case hash And $F of
    0:  Result :=  x + y;
    1:  Result := -x + y;
    2:  Result :=  x - y;
    3:  Result := -x - y;
    4:  Result :=  x + z;
    5:  Result := -x + z;
    6:  Result :=  x - z;
    7:  Result := -x - z;
    8:  Result :=  y + z;
    9:  Result := -y + z;
    $A: Result :=  y - z;
    $B: Result := -y - z;
    $C: Result :=  y + x;
    $D: Result := -y + z;
    $E: Result :=  y - x;
    $F: Result := -y - z;
  Else
    Result := 0;
  End;
End;

Function perlin(x, y, z: aFloat): aFloat;
Var
  xf, yf, zf, u, v, w, x1, y1, x2, y2: aFloat;
  xi, yi, zi, aaa, aba, aab, abb, baa, bba, bab, bbb, t, p: Integer;
Begin

  x := Abs(x);
  y := Abs(y);
  z := Abs(z);

  t := Trunc(x);
  xi := t And $FF;
  xf := x-t;

  t := Trunc(y);
  yi := t And $FF;
  yf := y-t;

  t := trunc(z);
  zi := t And $FF;
  zf := z-t;

  u := fade(xf);
  v := fade(yf);
  w := fade(zf);

  p := p2[xi];
  aaa := p2[p2[p+yi]+zi];
  aba := p2[p2[p+yi+1]+zi];
  aab := p2[p2[p+yi]+zi+1];
  abb := p2[p2[p+yi+1]+zi+1];

  p := p2[xi+1];
  baa := p2[p2[p+yi]+zi];
  bba := p2[p2[p+yi+1]+zi];
  bab := p2[p2[p+yi]+zi+1];
  bbb := p2[p2[p+yi+1]+zi+1];

  x1 := lerp(grad(aaa, xf  , yf  , zf), grad(baa, xf-1, yf  , zf),	u);
  x2 := lerp(grad(aba, xf  , yf-1, zf), grad(bba, xf-1, yf-1, zf), u);
  y1 := lerp(x1, x2, v);
  x1 := lerp(grad(aab, xf  , yf  , zf-1), grad(bab, xf-1, yf  , zf-1), u);
  x2 := lerp(grad(abb, xf  , yf-1, zf-1), grad(bbb, xf-1, yf-1, zf-1), u);
  y2 := lerp (x1, x2, v);

  result := lerp(y1, y2, w) + 0.5;

End;

Function OctavePerlin(x, y, z: aFloat; octaves: Integer; persistence: aFloat): aFloat;
Var
  i: integer;
  total, frequency, amplitude, maxvalue: aFloat;
Begin
  total := 0;
  frequency := 1;
  amplitude := 1;
  maxValue := 0;
  for i := 0 To octaves -1 Do Begin
    total := total + perlin(x * frequency, y * frequency, z * frequency) * amplitude;
    maxValue := maxvalue + amplitude;
    amplitude := amplitude * persistence;
    frequency := frequency * 2;
  End;
  result := total/maxValue;
End;

end.


