unit SP_Display;

{$INCLUDE SpecBAS.inc}

interface

  Uses WinAPI.Windows, System.SysUtils, System.SyncObjs, Graphics, Forms, Classes, System.Types, Math, PNGImage, MainForm, SP_FileIO, {$IFDEF OPENGL}dglOpenGL,{$ENDIF} SP_Util, WinAPI.DWMApi;

  {$IFDEF RefreshThread}
Type

  TRefreshThread = Class(TThread)
    ShouldPause, IsPaused: Boolean;
    Procedure Execute; Override;
  End;
  {$ENDIF}

  {$IFDEF OPENGL}
  Procedure InitGL;
  Procedure CloseGL;
  {$ENDIF}
  Function  SetScreen(Width, Height, sWidth, sHeight: Integer; FullScreen: Boolean): Integer;
  Function  SetScreenResolution(Width, Height: Integer; FullScreen: Boolean): Boolean;
  Function  TestScreenResolution(Width, Height: Integer; FullScreen: Boolean): Boolean;
  Procedure SetScaling(Width, Height, sWidth, sHeight: Integer);
  {$IFDEF RefreshThread}
  Procedure PauseDisplay;
  Procedure ResumeDisplay;
  {$ENDIF}
  Procedure Refresh_Display;
  Function  UpdateDisplay: Boolean;
  Function  GetScreenRefreshRate: Integer;
  Procedure GetOSDString;
  Procedure GLResize;
  Procedure ScreenShot(fullwindow: Boolean);
  Procedure HandleMouse;
  Procedure FrameLoop;

Var

  ScrWidth, ScrHeight, OrgWidth, OrgHeight: Integer;
  GLX, GLY, GLW, GLH, GLMX, GLMY, GLMW, GLMH, GLFX, GLFY, GLFW, GLFH: Integer;
  iRect: TRect;
  {$IFDEF RefreshThread}
  RefreshTimer: TRefreshThread;
  {$ENDIF}
  {$IFDEF OPENGL}
    LastScaledMouseX, LastScaledMouseY: Integer;
    DisplayFlip, GLInitDone, ReScaleFlag: Boolean;
    PixArray, DispArray: Array of Byte;
    RC: HGLRC;
    DC: hDc;
  {$ENDIF}
  DoScale: Boolean = False;
  ScaleFactor: Integer = 1;
  ScaleMouseX, ScaleMouseY: aFloat;
  AvgFrameTime: aFloat;
  LastFrames: NativeUint;
  StartTime, LastTime: aFloat;

implementation

Uses SP_SysVars, SP_Graphics, SP_Graphics32, SP_Main, SP_Tokenise, SP_Errors;

{$IFDEF OPENGL}

Procedure InitGL;
Var
  Pixelformat: GLuint;
  pfd: pixelformatdescriptor;
begin

  If RC <> 0 Then Begin
    wglDeleteContext(RC);
    ReleaseDC(Main.Handle, DC);
  End Else
    InitOpenGL;

  with pfd do begin
    nSize:= SizeOf( PIXELFORMATDESCRIPTOR );
    nVersion:= 1;
    dwFlags:= PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER or PFD_SWAP_COPY;
    iPixelType:= PFD_TYPE_RGBA;
    cColorBits:= 32;
    cRedBits:= 0;
    cRedShift:= 0;
    cGreenBits:= 0;
    cBlueBits:= 0;
    cBlueShift:= 0;
    cAlphaBits:= 0;
    cAlphaShift:= 0;
    cAccumBits:= 0;
    cAccumRedBits:= 0;
    cAccumGreenBits:= 0;
    cAccumBlueBits:= 0;
    cAccumAlphaBits:= 0;
    cDepthBits:= 0;
    cStencilBits:= 0;
    cAuxBuffers:= 0;
    iLayerType:= PFD_MAIN_PLANE;
    bReserved:= 0;
    dwLayerMask:= 0;
    dwVisibleMask:= 0;
    dwDamageMask:= 0;
  end;

  DC := GetDC(Main.Handle);
  PixelFormat := ChoosePixelFormat(DC, @pfd);
  SetPixelFormat(DC,PixelFormat,@pfd);
  RC := wglCreateContext(DC);
  ActivateRenderingContext(DC, RC);
  wglMakeCurrent(DC, RC);
  wglSwapIntervalEXT(1);
  VSYNCENABLED := wglGetSwapIntervalEXT <> 0;

  GLInitDone := True;

End;

Procedure CloseGL;
Begin
  wglMakeCurrent(0, 0);
  wglDeleteContext(RC);
  ReleaseDC(Main.Handle, DC);
  DeleteDC (DC);
End;

{$ENDIF}

{$IFDEF RefreshThread}
Procedure PauseDisplay; // Used to halt the refresh thread when working on window banks or sprites.
Begin

  If SP_Interpreter_Ready And RefreshThreadAlive Then Begin
    If Not RefreshTimer.IsPaused Then Begin
      RefreshTimer.ShouldPause := True;
      Repeat
        CB_YIELD;
      Until RefreshTimer.IsPaused;
    End;
  End;

End;

Procedure ResumeDisplay;
Begin

  If SP_Interpreter_Ready And RefreshThreadAlive Then Begin
    RefreshTimer.ShouldPause := False;
    Repeat
      CB_YIELD;
    Until Not RefreshTimer.IsPaused;
  End;

End;
{$ENDIF}

Procedure HandleMouse;
Var
  p: TPoint;
Begin
  GetCursorPos(p);
  p := Main.ScreenToClient(p);
  {$IFDEF OpenGL}
    MOUSEX := Integer(Round(p.X / ScaleMouseX));
    MOUSEY := Integer(Round(p.Y / ScaleMouseY));
  {$ELSE}
    MOUSEX := p.X;
    MOUSEY := p.Y;
  {$ENDIF}
  If Not PtInRect(Main.ClientRect, p) Then Begin
    If MouseInForm Then Begin
      MOUSEVISIBLE := False;
      SP_InvalidateWholeDisplay;
      SP_NeedDisplayUpdate := True;
      MouseInForm := False;
    End;
  End Else Begin
    If Not MouseInForm Then Begin
      MOUSEVISIBLE := USERMOUSEVISIBLE or (SYSTEMSTATE in [SS_EDITOR, SS_DIRECT, SS_ERROR]);
      MouseInForm := True;
      SP_InvalidateWholeDisplay;
      SP_NeedDisplayUpdate := True;
    End;
  End;
End;

Procedure FrameLoop;
Var
  SleepTime: Integer;
  TargetTime, CurTime: aFloat;
Begin

  CurTime := CB_GETTICKS;
  FRAMES := Trunc((CurTime - StartTime) / FRAME_MS);

  If FRAMES <> LastFrames Then begin

    FrameElapsed := True;
    Inc(AutoFrameCount);
    LastFrames := FRAMES;

    HandleMouse;

    If SP_FrameUpdate Then Begin
      DisplaySection.Enter;
      If UpdateDisplay Then Begin
        If StartTime = 0 Then
          StartTime := CB_GETTICKS;
        CB_Refresh_Display;
        LASTFRAMETIME := CurTime - LastTime;
        AvgFrameTime := (AvgFrameTime + LASTFRAMETIME)/2;
        LastTime := CurTime;
      End;
      DisplaySection.Leave;
      UPDATENOW := False;
    End;
    CauseUpdate := False;

  End;

 TargetTime := (((FRAMES + 1) * FRAME_MS) + StartTime);
  SleepTime := Trunc(TargetTime - CB_GETTICKS);
  If SleepTime >= 1 Then
    Sleep(SleepTime)
  Else
    While CB_GETTICKS < TargetTime Do
      SwitchToThread;

End;

{$IFDEF RefreshThread}
Procedure TRefreshThread.Execute;
Begin

  FreeOnTerminate := True;
  NameThreadForDebugging('Refresh Thread');
  Priority := tpHigher;
  RefreshThreadAlive := True;

  LastFrames := 0;
  StartTime := 0;
  LastTime := 0;

  While Not (QUITMSG Or Terminated) Do Begin

    If ShouldPause Then Begin
      IsPaused := True;
      Repeat
        CB_YIELD;
      Until Not ShouldPause;
      IsPaused := False;
      LastFrames := FRAMES;
    End;

    FrameLoop;

  End;

  CloseGL;

  RefreshThreadAlive := False;

End;
{$ENDIF}

Procedure RestoreFPSRegion;
Var
  CX1, CY1, CX2, CY2: Integer;
  Error: TSP_ErrorCode;
Begin
  cX1 := 0; cy1 := 0; cx2 := DISPLAYWIDTH; cy2 := DISPLAYHEIGHT;
  SP_PutRegion_NO_OVER32To32(DISPLAYPOINTER, FPSLEFT, FPSTOP, DISPLAYSTRIDE, DISPLAYHEIGHT, @FPSIMAGE[1], Length(FPSIMAGE), cX1, cY1, cX2, cY2, Error);
  FPSIMAGE := '';
End;

Procedure DrawFPS;
Var
  Error: TSP_ErrorCode;
Begin
  SP_GetRegion32(DISPLAYPOINTER, DISPLAYSTRIDE, DISPLAYHEIGHT, FPSIMAGE, FPSLEFT, FPSTOP, FPSWIDTH, FPSHEIGHT, Error);
  SP_RawTextOut(SYSFONT, DISPLAYPOINTER, DISPLAYSTRIDE Shr 2, DISPLAYHEIGHT, FPSLEFT, FPSTOP, FPSSTRING, $8000FF00, 0, 2, 2, True, True);
End;

Procedure GetOSDString;
Var
  s: String;
  m: Integer;
begin
  s := Format('%.0f', [1000/AvgFrameTime]);
  FPSSTRING := OSD + aString(' ' + s);
  m := Length(FPSSTRING);
  FPSSTRING := aString(StringOfChar(' ', 1 + (MaxOSDLen - length(FPSSTRING)))) + FPSSTRING;
  MaxOSDLen := m;
End;

Procedure PrepFPSVars;
Begin
  If FPSIMAGE <> '' Then RestoreFPSRegion;
  GLFW := (Length(FPSSTRING) * 8 * FPSSCALE);
  GLFX := DISPLAYWIDTH - (GLFW + 8);
  GLFY := 8;
  GLFH := 8 * FPSSCALE;
  FPSTOP := GLFY; FPSLEFT := GLFX;
  FPSWIDTH := GLFW; FPSHEIGHT := GLFH;
End;

Function UpdateDisplay: Boolean;
Var
  X1, Y1, X2, Y2, Mx1, Mx2, My1, My2: Integer;
Begin
  Result := False;
  If Not (Quitting or SCREENCHANGE) Then Begin
    {$IFDEF OPENGL}
    GLMX := MOUSESTOREX; GLMY := MOUSESTOREY;
    GLMW := MOUSESTOREW; GLMH := MOUSESTOREH;
    {$ENDIF}
    If (Not SCREENLOCK) or UPDATENOW Then Begin
      If SCMAXX >= SCMINX Then Begin
        SP_RestoreMouseRegion;
        While SetDR Do Sleep(1); SetDR := True;
        If SHOWFPS Then PrepFPSVars;
        X1 := SCMINX; Y1 := SCMINY; X2 := SCMAXX +1; Y2 := SCMAXY +1;
        {$IFDEF OPENGL}
        // IMPORTANT: Ensure that the region to display doesn't step outside the boundaries of the texture
        GLX := Max(X1, 0); GLY := Max(Y1, 0); GLW := Min(X2 - GLX +1, DISPLAYWIDTH - GLX); GLH := Min(Y2 - GLY +1, DISPLAYHEIGHT - GLY);
        {$ELSE}
        iRect := Rect(X1, Y1, X2, Y2);
        {$ENDIF}
        SCMAXX := 0; SCMAXY := 0; SCMINX := DISPLAYWIDTH; SCMINY := DISPLAYHEIGHT;
        SetDR := False;
        Result := True;
        DRAWING := True;
        If Assigned(DISPLAYPOINTER) Then SP_Composite32(DISPLAYPOINTER, X1 -1, Y1 -1, X2 +1, Y2 +1); // 1-pixel buffer zone for the mouse pointer.
        If SHOWFPS Then DrawFPS;
        MOUSEMOVED := False;
        If MOUSEVISIBLE or (PROGSTATE = SP_PR_STOP) Then Begin
          SP_DrawMouseImage;
          If (MOUSESTOREX <> GLMX) or (MOUSESTOREY <> GLMY) Then Begin
            Mx2 := Max(GLMX + GLMW, MOUSESTOREX + MOUSESTOREW +1);
            My2 := Max(GLMY + GLMH, MOUSESTOREY + MOUSESTOREH +1);
            Mx1 := Min(GLMX, MOUSESTOREX);
            My1 := Min(GLMY, MOUSESTOREY);
            GLMX := Mx1; GLMY := My1; GLMW := Mx2-Mx1; GLMH := My2-My1;
            MOUSEMOVED := True;
            Result := True;
          End;
        End;
        GLMX := Min(Max(GLMX, 0), DISPLAYWIDTH); GLMY := Min(Max(GLMY, 0), DISPLAYHEIGHT);
        If GLMX + GLMW >= DISPLAYWIDTH  Then GLMW := DISPLAYWIDTH - GLMX;
        If GLMY + GLMH >= DISPLAYHEIGHT Then GLMH := DISPLAYHEIGHT - GLMY;
        SP_NeedDisplayUpdate := False;
        UPDATENOW := False;
      End;
    End;
  End;
  DRAWING := False;
End;

Procedure ScaleBuffers(x1, x2, y1, y2: Integer);
var
  w,w2,x,y,i: Integer;
  ps,pd,lpd: pLongWord;
begin
  {$IFDEF OPENGL}
  w2 := (x2 - x1) +1;         // Width of area to scale
  w := w2 * 4 * ScaleFactor;  // Same value scaled. Source is 8bpp, dest is 32bpp
  ps := @PixArray[0];         // Source
  pd := @DispArray[0];        // Dest
  Inc(ps, (y1 * DISPLAYWIDTH) + x1); // Find source topleft pixel
  Inc(pd, (y1 * ScaleFactor * ScaledWidth) + (x1 * ScaleFactor)); // And dest
  for y := y1 to y2 do begin
    lpd := pd;
    for x := x1 to x2 do begin  // Scale columns
      For i := 1 To ScaleFactor Do Begin
        pd^ := ps^;
        Inc(pd);
      End;
      Inc(ps);
    end;
    pd := pLongWord(NativeUint(pd) + (ScaledWidth * 4) - w); // Find next row
    Inc(ps, DISPLAYWIDTH - w2);                              // in both dest and src
    For i := 1 to ScaleFactor -1 Do Begin // Copy rows
      Move(lpd^, pd^, w);
      Inc(pd, ScaledWidth);
    End;
  end;
  {$ENDIF}
end;

Procedure Refresh_Display;
Var
  DC: hDc;
  x, y, w, h, tmp: Integer;
Begin

  {$IFDEF OPENGL}

    If Not GLInitDone Then Begin
      InitGL;
      ReScaleFlag := True;
    End;

    If ReScaleFlag Then Begin
      ReScaleFlag := False;
      SetScaling(DISPLAYWIDTH, DISPLAYHEIGHT, Main.ClientWidth, Main.ClientHeight);
      Main.FormResize(Main);
    End;

    DC := wglGetCurrentDC;

    glDisable(gl_MULTISAMPLE_ARB);
    glLoadIdentity;
    glUseProgramObjectARB(0);

    If DoScale Then Begin
      If (GLH > 0) And (GLW > 0) Then Begin
        ScaleBuffers(GLX, GLX + GLW -1, GLY, GLY + GLH -1);
        x := GLX * ScaleFactor;
        y := GLY * ScaleFactor;
        w := GLW * ScaleFactor;
        h := GLH * ScaleFactor;
        glPixelStorei(GL_UNPACK_ROW_LENGTH, ScaledWidth);
        glTexSubImage2D(GL_TEXTURE_2D, 0, X, Y, W, H, GL_BGRA, GL_UNSIGNED_BYTE, @DispArray[X * 4 + ScaledWidth * 4 * Y]);
      End;
      If (GLMW > 0) And (GLMH > 0) And MOUSEMOVED Then Begin
        ScaleBuffers(GLMX, GLMX + GLMW -1, GLMY, GLMH + GLMY -1);
        x := GLMX * ScaleFactor;
        y := GLMY * ScaleFactor;
        w := GLMW * ScaleFactor;
        h := GLMH * ScaleFactor;
        glTexSubImage2D(GL_TEXTURE_2D, 0, X, Y, W, H, GL_BGRA, GL_UNSIGNED_BYTE, @DispArray[X * 4 + ScaledWidth * 4 * Y]);
      End;
      If (GLFW > 0) And (GLFH > 0) And SHOWFPS Then Begin
        ScaleBuffers(GLFX, GLFX + GLFW -1, GLFY, GLFH + GLFY -1);
        x := GLFX * ScaleFactor;
        y := GLFY * ScaleFactor;
        w := GLFW * ScaleFactor;
        h := GLFH * ScaleFactor;
        glTexSubImage2D(GL_TEXTURE_2D, 0, X, Y, W, H, GL_BGRA, GL_UNSIGNED_BYTE, @DispArray[X * 4 + ScaledWidth * 4 * Y]);
      End;
    End Else Begin
      if (GLH > 0) And (GLW > 0) Then Begin
        glPixelStorei(GL_UNPACK_ROW_LENGTH, DISPLAYWIDTH);
        glTexSubImage2D(GL_TEXTURE_2D, 0, GLX, GLY, GLW, GLH, GL_BGRA, GL_UNSIGNED_BYTE, @PixArray[GLX * 4 + DISPLAYWIDTH * 4 * GLY]);
      End;
      If (GLMW > 0) And (GLMH > 0) And MOUSEMOVED Then
        glTexSubImage2D(GL_TEXTURE_2D, 0, GLMX, GLMY, GLMW, GLMH, GL_BGRA, GL_UNSIGNED_BYTE, @PixArray[GLMX * 4 + DISPLAYWIDTH * 4 * GLMY]);
      If (GLFW > 0) And (GLFH > 0) And SHOWFPS Then
        glTexSubImage2D(GL_TEXTURE_2D, 0, GLFX, GLFY, GLFW, GLFH, GL_BGRA, GL_UNSIGNED_BYTE, @PixArray[GLFX * 4 + DISPLAYWIDTH * 4 * GLFY]);
    End;

    glBegin(GL_QUADS);
    glTexCoord2D(0, 0); glVertex2D(0, 0);
    glTexCoord2D(1, 0); glVertex2D(ScaleWidth, 0);
    glTexCoord2D(1, 1); glVertex2D(ScaleWidth, ScaleHeight);
    glTexCoord2D(0, 1); glVertex2D(0, ScaleHeight);
    glEnd;

    glGetIntegerv(GL_UNPACK_ROW_LENGTH, @tmp);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    glFinish;

    SwapBuffers(DC);

  {$ELSE}
    InvalidateRect(Main.Handle, iRect, False);
    Main.Repaint;
  {$ENDIF}

End;

Procedure SetScaling(Width, Height, sWidth, sHeight: Integer);
Begin

  {$IFDEF OPENGL}

  SCALEWIDTH := sWidth;
  SCALEHEIGHT := sHeight;
  If INTSCALING And Not ((SCALEWIDTH/DISPLAYWIDTH = Floor(SCALEWIDTH/DISPLAYWIDTH)) And (SCALEHEIGHT/DISPLAYHEIGHT = Floor(SCALEHEIGHT/DISPLAYHEIGHT))) Then Begin
    DoScale := (sWidth/Width >= 1.5) or (sHeight/Height >= 1.5);
    ScaleFactor := Max(Round(sWidth/Width), Round(sHeight/Height));
    If ScaleFactor = 0 Then
      ScaleFactor := 1;
  End Else Begin
    DoScale := False;
    ScaleFactor := 1;
  End;
  ScaledWidth := ScaleFactor * Width;
  ScaledHeight := ScaleFactor * Height;
  ScaleMouseX := sWidth/Width;
  ScaleMouseY := sHeight/Height;
  SetLength(DispArray, ScaledWidth * 4 * ScaledHeight);
  SetLength(PixArray, Width * 4 * Height);
  DISPLAYPOINTER := @PixArray[0];

  {$ENDIF}

End;

Function SetScreen(Width, Height, sWidth, sHeight: Integer; FullScreen: Boolean): Integer;
Var
  oW, oH: Integer;
  oFS: Boolean;
  l, t, w, h: NativeInt;
  r: TRect;
Begin

  {$IFDEF RefreshThread}
  CB_PauseDisplay;
  {$ENDIF}

  Result := 0;
  oW := SCALEWIDTH;
  oH := SCALEHEIGHT;
  oFS := SPFULLSCREEN;

  // Check for transition from window to fullscreen and vice-versa

  If FullScreen <> SPFULLSCREEN Then Begin
    If FullScreen Then Begin
      // Going from windowed to fullscreen
      WINLEFT := Main.Left;
      WINTOP := Main.Top;
      WINWIDTH := Main.ClientWidth;
      WINHEIGHT := Main.ClientHeight;
    End Else Begin
      sWidth := WINWIDTH;
      sHeight := WINHEIGHT;
    End;
  End Else
    If Not FullScreen Then Begin
      WINLEFT := Main.Left;
      WINTOP := Main.Top;
    End;

  DISPLAYWIDTH := Width;
  DISPLAYHEIGHT := Height;

  if (sWidth <> oW) or (sHeight <> oH) or (oFS <> FullScreen) Then Begin
    {$IFDEF OPENGL}
    GLInitDone := False; // trigger the OpenGL system to recreate itself with the new window/screen size
    {$ENDIF}
    SetScreenResolution(sWidth, sHeight, FullScreen);
  End Else
    {$IFDEF OpenGL}ReScaleFlag := True{$ENDIF};

  w := sWidth;
  h := sHeight;

  SystemParametersInfo(SPI_GETWORKAREA, 0, @r, 0);

  If FullScreen Then Begin
    l := 0;
    t := 0;
  End Else Begin
    If INSTARTUP Then Begin
      l := ((r.Right - r.Left) - Main.Width) Div 2;
      t := ((r.Bottom - r.Top) - Main.Height) Div 2;
    End Else Begin
      l := WINLEFT;
      t := WINTOP;
    End;
  End;

  SendMessage(Main.Handle, WM_RESIZEMAIN, l + (t shl 16), w + (h Shl 16));

End;

Function GetScreenRefreshRate: Integer;
var
  DeviceMode: TDeviceMode;
const
  ENUM_CURRENT_SETTINGS = DWORD(-1);
Begin
  EnumDisplaySettings(nil, ENUM_CURRENT_SETTINGS, DeviceMode);
  Result := DeviceMode.dmDisplayFrequency;
End;

function TestScreenResolution(Width, Height: Integer; FullScreen: Boolean): Boolean;
var
  DeviceMode: TDeviceMode;
  hMod, wMod: Integer;
  error: TSP_ErrorCode;
begin

  If FullScreen Then Begin

    with DeviceMode do begin
      dmSize := SizeOf(TDeviceMode);
      dmPelsWidth := Width;
      dmPelsHeight := Height;
      dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;
    end;
    hMod := ChangeDisplaySettings(DeviceMode, CDS_TEST);
    Result := hMod = DISP_CHANGE_SUCCESSFUL;
    if Not Result then
      SP_PRINT(-1,0,0,-1,IntToString(hMod)+','+inttostring(width)+'x'+inttostring(height),0,8,error);

  End Else Begin

    hMod := Main.Height - Main.ClientHeight;
    wMod := Main.Width - Main.ClientWidth;
    Result := (Width + wMod <= REALSCREENWIDTH) and (Height + hMod <= REALSCREENHEIGHT);

  End;
end;

function SetScreenResolution(Width, Height: Integer; FullScreen: Boolean): Boolean;
var
  oldDeviceMode, DeviceMode: TDeviceMode;
  oW, oH: Integer;
  oFS: Boolean;
  R: TRect;
const
  ENUM_CURRENT_SETTINGS = DWORD(-1);
begin

  If SPFULLSCREEN Then Begin
    EnumDisplaySettings(nil, ENUM_CURRENT_SETTINGS, OldDeviceMode);
    oW := OldDeviceMode.dmPelsWidth;
    oH := OldDeviceMode.dmPelsHeight;
    oFS := True;
  End Else Begin
    oW := WINWIDTH;
    oH := WINHEIGHT;
    oFS := False;
  End;

  If FullScreen Then Begin
    with DeviceMode do begin
      dmSize := SizeOf(TDeviceMode);
      dmPelsWidth := Width;
      dmPelsHeight := Height;
      dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;
    end;
    If (oFS <> FullScreen) or (Width <> oW) or (Height <> oH) Then Begin
      Result := ChangeDisplaySettings(DeviceMode, 0) = DISP_CHANGE_SUCCESSFUL;
      Main.BorderStyle := bsNone;
    End Else
      Result := True;
    SPFULLSCREEN := True;
  End Else Begin
    If SPFULLSCREEN Then Begin
      R := Rect(0, 0, Width, Height);
      AdjustWindowRect(R, WS_CAPTION or WS_POPUPWINDOW, FALSE);
      with DeviceMode do begin
        dmSize := SizeOf(TDeviceMode);
        dmPelsWidth := REALSCREENWIDTH;
        dmPelsHeight := REALSCREENHEIGHT;
        dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;
      End;
      If (oFS <> FullScreen) or (Width <> oW) or (Height <> oH) Then Begin
        ChangeDisplaySettings(DeviceMode, 0);
        Main.BorderStyle := bsSingle;
      End;
      SPFULLSCREEN := False;
    End;
    Result := True;
  End;

end;

Procedure GLResize;
Begin

  DISPLAYSTRIDE := DISPLAYWIDTH * 4;
  SetLength(PixArray, DISPLAYSTRIDE * DISPLAYHEIGHT);
  SetLength(DispArray, ScaledWidth * 4 * ScaledHeight);
  DISPLAYPOINTER := @PixArray[0];

  If GLInitDone and Not ReScaleFlag Then Begin

    glClearColor(0, 0, 0, 0);
    glClearDepth(1);

    glViewPort(0, 0, ScaleWidth, ScaleHeight);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;


    If DisplayFlip Then
      glOrtho(ScaleWidth, 0, 0, ScaleHeight, 1, -1)
    Else
      glOrtho(0, ScaleWidth, ScaleHeight, 0, 1, -1);

    glMatrixMode(GL_MODELVIEW);
    glEnable(GL_TEXTURE_2D);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, ScaledWidth, ScaledHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, Nil);

    If INTSCALING And ((SCALEWIDTH/DISPLAYWIDTH = Floor(SCALEWIDTH/DISPLAYWIDTH)) And (SCALEHEIGHT/DISPLAYHEIGHT = Floor(SCALEHEIGHT/DISPLAYHEIGHT))) Then Begin

      glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
      glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

    End Else Begin

      glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    End;

    glEnable(GL_TEXTURE_2D);
    wglSwapIntervalEXT(1);

  End;

End;

Procedure ScreenShot(fullWindow: Boolean);
var
  Win: HWND;
  DC: HDC;
  Bmp: TBitmap;
  Png: TPNGImage;
  Pixels: pByte;
  FName, FileName: string;
  WinRect, WinRectEx: TRect;
  Width, ox, i: Integer;
  Height: Integer;
  Error: TSP_ErrorCode;
begin

  If Not DirectoryExists(String(HOMEFOLDER) + '\snaps') Then
    CreateDir(String(HOMEFOLDER) + '\snaps');

  FName := Format('/snaps/%s.png', ['Screenshot_' + FormatDateTime('mm-dd-yyyy-hhnnss', Now())]);
  Filename := String(SP_ConvertFilenameToHost(aString(FName), Error));
  Win := GetForegroundWindow;

  if SPFULLSCREEN Then Begin
    Bmp := TBitmap.Create;
    Bmp.Height := DisplayHeight;
    Bmp.Width := DisplayWidth;
    Bmp.PixelFormat := pf32Bit;
    Pixels := @PixArray[0];
    for i := 0 To DISPLAYHEIGHT -1 do Begin
      CopyMem(Bmp.ScanLine[i], Pixels, DisplayWidth * SizeOf(LongWord));
      Inc(Pixels, DisplayWidth * SizeOf(LongWord));
    End;
  End Else Begin
    ox := 0;
    if FullWindow then begin
      if (Win32MajorVersion >= 6) and DwmCompositionEnabled then Begin
        DwmGetWindowAttribute(Win, DWMWA_EXTENDED_FRAME_BOUNDS, @WinRect, SizeOf(WinRect));
        GetWindowRect(Win, WinRectEx);
        Ox := WinRect.Left - WinRectEx.Left;
      End else
        GetWindowRect(Win, WinRect);
      DC := GetWindowDC(Win);
    end else begin
      GetClientRect(Win, WinRect);
      DC := GetDC(Win);
    end;
    Width := WinRect.Right - WinRect.Left;
    Height := WinRect.Bottom - WinRect.Top;
    Bmp := TBitmap.Create;
    Bmp.Height := Height;
    Bmp.Width := Width;
    BitBlt(Bmp.Canvas.Handle, 0, 0, Width, Height, DC, ox, 0, SRCCOPY);
    ReleaseDC(Win, DC);
  End;
  Png := TPNGImage.Create;
  Png.Assign(Bmp);
  Png.SaveToFile(Filename);
  Png.Free;
  Bmp.Free;

end;


end.
