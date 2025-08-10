unit SP_Display;

{$INCLUDE SpecBAS.inc}

interface

  Uses WinAPI.Windows, MultiMon, System.SysUtils, System.SyncObjs, Graphics, Forms, Classes, System.Types, Math, PNGImage, MainForm,
       SP_FileIO, {$IFDEF OPENGL}dglOpenGL,{$ENDIF} SP_Util, WinAPI.DWMApi;

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
  procedure SP_GetMonitorMetrics;
  procedure SetPerformingDisplayChange(Value: Boolean);
  function  IsPerformingDisplayChange: Boolean;
  Function  SetScreen(Width, Height, sWidth, sHeight: Integer; FullScreen, AllowResize: Boolean): Integer;
  Function  SetScreenResolution(Width, Height: Integer; FullScreen: Boolean): Boolean;
  Function  TestScreenResolution(Width, Height: Integer; FullScreen: Boolean): Boolean;
  Procedure SetScaling(InternalWidth, InternalHeight, OutputClientWidth, OutputClientHeight: Integer); // Modified signature
  {$IFDEF RefreshThread}
  Procedure PauseDisplay;
  Procedure ResumeDisplay;
  {$ENDIF}
  Procedure Refresh_Display;
  Function  UpdateDisplay: Boolean;
  Function  GetScreenRefreshRate: aFloat;
  Procedure GetOSDString;
  {$IFDEF OpenGL}
  Procedure GLResize;
  {$ENDIF}
  Procedure ScreenShot(fullwindow: Boolean);
  Procedure HandleMouse;
  Procedure FrameLoop;
  Procedure WaitForDisplayInit;

Var

  ScrWidth, ScrHeight, OrgWidth, OrgHeight: Integer; // Note: ScrWidth/Height might be redundant now with DISPLAYWIDTH/HEIGHT
  GLX, GLY, GLW, GLH, GLMX, GLMY, GLMW, GLMH, GLFX, GLFY, GLFW, GLFH: Integer;
  iRect: TRect;
  {$IFDEF RefreshThread}
  RefreshTimer: TRefreshThread;
  {$ENDIF}
  LastScaledMouseX, LastScaledMouseY: Integer; // Still used for mouse region invalidation logic
  {$IFDEF OPENGL}
    DisplayFlip, GLInitDone, ReScaleFlag: Boolean;
    PixArray: Array of Byte; // DispArray removed
    RC: HGLRC;
    DC: hDc;

    // --- Shader Related Variables ---
    ScalerProgramID: GLuint;
    // locVertexPosition, locTextureCoord: GLint; // Not needed if shader uses gl_Vertex/gl_MultiTexCoord0
    locProjectionMatrix: GLint; // If passing projection matrix explicitly
    locOriginalTextureSampler: GLint;
    locOriginalTextureSize: GLint;
    locIntegerNNScale: GLint;
    MainTextureID: GLuint = 0;
    CurrentOutputWidth, CurrentOutputHeight: Integer; // Actual window client size
    CurrentIntegerNNScaleFactor: aFloat;          // Calculated integer scale for shader
    // --- End Shader Related Variables ---

    // FBO vars

    FBO_ID: GLuint = 0;
    IntermediateTextureID: GLuint = 0;
    // Store the dimensions of the intermediate texture
    IntermediateTexWidth, IntermediateTexHeight: Integer;
    // This will store the actual integer scale used for the first NN pass
    ActualNNScaleFactor: Integer; // Can be float if you allow non-uniform NN scaling
  {$ENDIF}
  // DoScale: Boolean = False; // Removed
  // ScaleFactor: Integer = 1; // Removed
  ScaleMouseX, ScaleMouseY: aFloat;
  AvgFrameTime: aFloat;
  LastFrames: NativeUint;
  StartTime, LastTime: aFloat;
  FrameProcessedEvent: TEvent; // Create in InitSystem, Free in FinalizeSystem
  G_DisplayChangeLock: TCriticalSection;
  G_PerformingDisplayChange_Internal: Boolean;


Const

  FrameTimeHistoryLength = 1024;

  // ... (Keep your existing VertexShaderSource constant) ...
  VertexShaderSource: PAnsiChar =
    '#version 120'#10 +
    'varying vec2 v_textureCoord;'#10 +
    'void main() {'#10 +
    '  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;'#10 + // Uses built-in matrices
    '  v_textureCoord = vec2(gl_MultiTexCoord0);'#10 +             // Uses built-in texcoord
    '}';

  FragmentShaderSource: PAnsiChar =
    '#version 120'#10 +
    'varying vec2 v_textureCoord;'#10 +
    'uniform sampler2D u_originalTextureSampler;'#10 + // In Delphi, set this texture to GL_LINEAR
    'uniform vec2 u_originalTextureSize;'#10 +
    'void main() {'#10 +
    // Calculate UV coordinates that point to the *center* of the source texel
    // corresponding to the current fragment, effectively doing a nearest-neighbor lookup.
    '  vec2 uv_pixels = v_textureCoord * u_originalTextureSize;'#10 + // e.g., v_textureCoord.x * 240.0 -> 0.0 to 239.99...
    '  vec2 snapped_uv = (floor(uv_pixels) + 0.5) / u_originalTextureSize;'#10 +
     // floor(uv_pixels) -> integer pixel index (0 to 239)
     // + 0.5 -> center of that pixel (0.5, 1.5, ..., 239.5)
     // / u_originalTextureSize -> normalize to UV [0,1] (e.g., 0.5/240, 1.5/240, ...)
    '  gl_FragColor = texture2D(u_originalTextureSampler, snapped_uv);'#10 +
    '}';

Var

  FrameTimeHistory: Array[0..FrameTimeHistoryLength -1] of aFloat;
  FrameTimeHistoryPos: Integer;

  Procedure AddToFrameTimeHistory(Time: aFloat);

implementation

Uses SP_SysVars, SP_Graphics, SP_Graphics32, SP_Main, SP_Tokenise, SP_Errors;

procedure SetPerformingDisplayChange(Value: Boolean);
begin
  G_DisplayChangeLock.Enter;
  try
    G_PerformingDisplayChange_Internal := Value;
  finally
    G_DisplayChangeLock.Leave;
  end;
end;

function IsPerformingDisplayChange: Boolean;
begin
  G_DisplayChangeLock.Enter;
  try
    Result := G_PerformingDisplayChange_Internal;
  finally
    G_DisplayChangeLock.Leave;
  end;
end;

{$IFDEF OPENGL}

// --- Shader Helper Functions ---
function LoadShader(ShaderType: GLenum; const Source: PAnsiChar): GLuint;
var
  Shader: GLuint;
  Compiled: GLint;
  LogLength: GLint;
  Log: PAnsiChar;
  PSource: PAnsiChar;
begin
  Result := 0;
  Shader := glCreateShader(ShaderType);
  if Shader = 0 then
    Exit;

  PSource := Source; // glShaderSource expects ^PAnsiChar (PPAnsiChar)
  glShaderSource(Shader, 1, @PSource, nil); // nil for lengths means null-terminated
  glCompileShader(Shader);
  glGetShaderiv(Shader, GL_COMPILE_STATUS, @Compiled);

  if Compiled = GLInt(GL_FALSE) then
  begin
    glGetShaderiv(Shader, GL_INFO_LOG_LENGTH, @LogLength);
    if LogLength > 0 then
    begin
      GetMem(Log, LogLength);
      try
        glGetShaderInfoLog(Shader, LogLength, @LogLength, Log);
      finally
        FreeMem(Log);
      end;
    end;
    glDeleteShader(Shader);
    Exit;
  end;
  Result := Shader;
end;

function CreateShaderProgram(const VertSource, FragSource: PAnsiChar): GLuint;
var
  VertexShader, FragmentShader: GLuint;
  Prog: GLuint;
  Linked: GLint;
  LogLength: GLint;
  Log: PAnsiChar;
begin
  Result := 0;
  VertexShader := LoadShader(GL_VERTEX_SHADER, VertSource);
  if VertexShader = 0 then Exit;

  FragmentShader := LoadShader(GL_FRAGMENT_SHADER, FragSource);
  if FragmentShader = 0 then
  begin
    glDeleteShader(VertexShader);
    Exit;
  end;

  Prog := glCreateProgram();
  if Prog = 0 then
  begin
    glDeleteShader(VertexShader);
    glDeleteShader(FragmentShader);
    Exit;
  end;

  glAttachShader(Prog, VertexShader);
  glAttachShader(Prog, FragmentShader);
  glLinkProgram(Prog);
  glGetProgramiv(Prog, GL_LINK_STATUS, @Linked);

  if Linked = GLInt(GL_FALSE) then
  begin
    glGetProgramiv(Prog, GL_INFO_LOG_LENGTH, @LogLength);
    if LogLength > 0 then
    begin
      GetMem(Log, LogLength);
      try
        glGetProgramInfoLog(Prog, LogLength, @LogLength, Log);
      finally
        FreeMem(Log);
      end;
    end;
    glDeleteProgram(Prog);
    Prog := 0; // Ensure result is 0 on failure
  end;

  // Shaders are linked into program; no longer needed.
  glDetachShader(Prog, VertexShader);
  glDetachShader(Prog, FragmentShader);
  glDeleteShader(VertexShader);
  glDeleteShader(FragmentShader);

  Result := Prog;
end;
// --- End Shader Helper Functions ---

Procedure InitGL;
Var
  i: Integer;
  Pixelformat: GLuint;
  pfd: PIXELFORMATDESCRIPTOR; // Corrected type name
begin

  StartTime := CB_GETTICKS;
  For i := 0 To Length(FrameTimeHistory) -1 Do
    FrameTimeHistory[i] := 0;

  If RC <> 0 Then Begin
    wglMakeCurrent(0, 0); // Detach context before deleting
    wglDeleteContext(RC);
    ReleaseDC(Main.Handle, DC);
    DC := 0; // Reset DC
    RC := 0; // Reset RC
    if FBO_ID <> 0 then glDeleteFramebuffers(1, @FBO_ID);
    FBO_ID := 0;
    if IntermediateTextureID <> 0 then
      glDeleteTextures(1, @IntermediateTextureID);
    IntermediateTextureID := 0;
  End Else
    InitOpenGL; // This is from dglOpenGL, loads library pointers

  with pfd do begin
    nSize:= SizeOf( PIXELFORMATDESCRIPTOR );
    nVersion:= 1;
    dwFlags:= PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL {$IFDEF DOUBLEBUFFER}or PFD_DOUBLEBUFFER or PFD_SWAP_COPY{$ENDIF};
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
    cDepthBits:= 0; // Set to 24 or 32 if depth testing is needed for 3D
    cStencilBits:= 0; // Set to 8 if stencil buffer is needed
    cAuxBuffers:= 0;
    iLayerType:= PFD_MAIN_PLANE;
    bReserved:= 0;
    dwLayerMask:= 0;
    dwVisibleMask:= 0;
    dwDamageMask:= 0;
  end;

  DC := GetDC(Main.Handle);

  PixelFormat := ChoosePixelFormat(DC, @pfd);
  If PixelFormat = 0 then begin
    ReleaseDC(Main.Handle, DC);
    DC := 0;
    Exit;
  end;

  If Not SetPixelFormat(DC,PixelFormat,@pfd) then begin
    ReleaseDC(Main.Handle, DC);
    DC := 0;
    Exit;
  end;

  RC := wglCreateContext(DC);
  If RC = 0 then begin ReleaseDC(Main.Handle, DC); DC := 0; Exit; end;

  If Not wglMakeCurrent(DC, RC) then begin
    wglDeleteContext(RC);
    RC := 0;
    ReleaseDC(Main.Handle, DC);
    DC := 0;
    Exit;
  end;

  // Read extensions after a context is current
  ReadImplementationProperties; // from dglOpenGL
  ReadExtensions;             // from dglOpenGL

  {$IFDEF DOUBLEBUFFER}
  If WGL_EXT_swap_control then wglSwapIntervalEXT(1) else glFlush; // Check if extension is available
  {$ELSE}
  If WGL_EXT_swap_control then wglSwapIntervalEXT(0) else glFinish;
  {$ENDIF}
  If WGL_EXT_swap_control then VSYNCENABLED := wglGetSwapIntervalEXT <> 0 else VSYNCENABLED := False;

  // --- Shader Initialization ---
  ScalerProgramID := CreateShaderProgram(VertexShaderSource, FragmentShaderSource);
  if ScalerProgramID <> 0 then begin
    glUseProgram(ScalerProgramID);
    locOriginalTextureSampler := glGetUniformLocation(ScalerProgramID, 'u_originalTextureSampler');
    locOriginalTextureSize    := glGetUniformLocation(ScalerProgramID, 'u_originalTextureSize');
    locIntegerNNScale         := glGetUniformLocation(ScalerProgramID, 'u_integerNNScale');
    glUseProgram(0);
    if (locOriginalTextureSampler = -1) or (locOriginalTextureSize = -1) or (locIntegerNNScale = -1) then begin
      glDeleteProgram(ScalerProgramID); // Clean up partially failed shader
      ScalerProgramID := 0;
    end;
  end;

  // --- Main Texture Initialization ---
  If MainTextureID = 0 then glGenTextures(1, @MainTextureID);
  // Texture parameters will be set in GLResize and Refresh_Display

  // --- FBO Initialization ---
  If FBO_ID = 0 then glGenFramebuffers(1, @FBO_ID);

  GLInitDone := True;
  ReScaleFlag := True; // Force GLResize to run

End;

Procedure CloseGL;
Begin
  If MainTextureID <> 0 then
  begin
    glDeleteTextures(1, @MainTextureID);
    MainTextureID := 0;
  end;

  If IntermediateTextureID <> 0 then
    glDeleteTextures(1, @IntermediateTextureID);
  IntermediateTextureID := 0;
  If FBO_ID <> 0 then
    glDeleteFramebuffers(1, @FBO_ID);
  FBO_ID := 0;

  If ScalerProgramID <> 0 then
  begin
    glDeleteProgram(ScalerProgramID);
    ScalerProgramID := 0;
  end;

  If RC <> 0 then
  begin
    wglMakeCurrent(0, 0);
    wglDeleteContext(RC);
    RC := 0;
  end;
  If DC <> 0 then // DC was obtained from Main.Handle
  begin
    ReleaseDC(Main.Handle, DC); // Use ReleaseDC for DC obtained with GetDC
    DC := 0;
  end;
  // DeleteDC(DC); // DeleteDC is for DCs created with CreateDC or CreateCompatibleDC
End;

{$ENDIF} // OPENGL

Procedure WaitForDisplayInit;
Begin
  // Wait for the display to start
  While StartTime = 0 Do CB_YIELD;
End;

{$IFDEF RefreshThread}
Procedure PauseDisplay; // Used to halt the refresh thread when working on window banks or sprites.
Begin
  If SP_Interpreter_Ready And RefreshThreadAlive Then Begin
    If Assigned(RefreshTimer) and (Not RefreshTimer.IsPaused) Then Begin // Added Assigned check
      RefreshTimer.ShouldPause := True;
      Repeat
        CB_YIELD;
      Until RefreshTimer.IsPaused or (Not RefreshThreadAlive); // Prevent infinite loop on shutdown
    End;
  End;
End;

Procedure ResumeDisplay;
Begin
  If SP_Interpreter_Ready And RefreshThreadAlive Then Begin
     If Assigned(RefreshTimer) then // Added Assigned check
     begin
        RefreshTimer.ShouldPause := False;
        Repeat
          CB_YIELD;
        Until Not RefreshTimer.IsPaused or (Not RefreshThreadAlive); // Prevent infinite loop
     end;
  End;
End;
{$ENDIF}

Procedure HandleMouse;
Var
  p: TPoint;
Begin
  GetCursorPos(p);
  p := Main.ScreenToClient(p);
  // ScaleMouseX/Y are calculated in SetScaling based on logical vs client size
  MOUSEX := Integer(Round(p.X / ScaleMouseX));
  MOUSEY := Integer(Round(p.Y / ScaleMouseY));
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

Procedure AddToFrameTimeHistory(Time: aFloat);
Var
  d: aFloat;
  const ALPHA_FPS = 0.5; // 0.05
Begin
  // Calculate actual frame time (this was how LASTFRAMETIME was calculated)
  // LASTFRAMETIME := CurTime - LastTime;
  // AvgFrameTime := (AvgFrameTime + LASTFRAMETIME) / 2; // Old method

  // New EMA for AvgFrameTime
  If AvgFrameTime = 0 then // First frame
     AvgFrameTime := Time
  else
     AvgFrameTime := (ALPHA_FPS * Time) + ((1.0 - ALPHA_FPS) * AvgFrameTime);

  // FrameTimeHistory stores deviation from target FRAME_MS
  d := Time - FRAME_MS;
  If Abs(d) > FRAME_MS Then // Cap deviation to one frame period
    d := FRAME_MS * Sign(d);
  FrameTimeHistory[FrameTimeHistoryPos] := d;
  FrameTimeHistoryPos := (FrameTimeHistoryPos + 1) Mod FrameTimeHistoryLength;
End;

Procedure FrameLoop;
Var
  CurTime, FrameDuration: aFloat;
  SleepTime: Integer;
  const MIN_SLEEP_THRESHOLD_MS = 1; // Time before target to wake up and spin
Begin
  CurTime := CB_GETTICKS;
  FRAMES := Trunc((CurTime - StartTime) / FRAME_MS);

  If FRAMES <> LastFrames Then begin
    FrameElapsed := True;
    Inc(AutoFrameCount);

    LastFrames := FRAMES;

    HandleMouse;

    If SP_FrameUpdate Then Begin
      If DisplaySection.TryEnter Then Begin
        Try
          If UpdateDisplay Then Begin // UpdateDisplay prepares GLX, GLY etc.
            // LASTFRAMETIME is now FrameDuration
            FrameDuration := CurTime - LastTime; // Actual duration of the last frame cycle
            LastTime := CurTime; // Update LastTime for the *next* frame's duration calculation
            AddToFrameTimeHistory(FrameDuration);
            // LastTime was already updated above
            CB_Refresh_Display; // This calls Refresh_Display
          End;
        Finally
          DisplaySection.Leave;
        End;
      End;
      UPDATENOW := False;
    End;
    CauseUpdate := False;

    if Assigned(FrameProcessedEvent) then FrameProcessedEvent.SetEvent;

    NEXTFRAMETIME := ((FRAMES + 1) * FRAME_MS) + StartTime;
    SleepTime := Trunc(NEXTFRAMETIME - CB_GETTICKS);

    If SleepTime > 2 Then Begin
      If SleepTime <= 4 Then
        Sleep(1)
      Else If SleepTime <= 6 Then
        Sleep(2)
      Else begin
        Sleep(Trunc(Min(FRAME_MS, SleepTime / 1.6)));
      end;
    End Else
      While CB_GETTICKS < NEXTFRAMETIME Do SwitchToThread;

  End Else
    Sleep(1); // Not time for a new frame yet, sleep a bit.
End;

{$IFDEF RefreshThread}
Procedure TRefreshThread.Execute;
Begin
  FreeOnTerminate := True;
  NameThreadForDebugging('Refresh Thread');
  Priority := tpNormal; // Changed from tpIdle
  RefreshThreadAlive := True;

  LastFrames := 0;
  StartTime := 0;
  LastTime := CB_GETTICKS; // Initialize LastTime

  While Not (QUITMSG Or Terminated) Do Begin
    If ShouldPause Then Begin
      IsPaused := True;
      Repeat
        CB_YIELD; // Sleep(1)
      Until Not ShouldPause Or Terminated Or QUITMSG; // Added Terminated/QUITMSG checks
      IsPaused := False;
      // Reset timing after pause to prevent a large jump
      StartTime := CB_GETTICKS - (FRAMES * FRAME_MS);
      LastTime := CB_GETTICKS;
      LastFrames := FRAMES; // Keep FRAMES to maintain animation position
    End;

    FrameLoop;
  End;

  {$IFDEF OPENGL}
  CloseGL; // Ensure GL resources are cleaned up in the rendering thread
  {$ENDIF}

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
  TxLeft, i, Hx, Hy, Ml, MinSize: Integer;
  ptr: pLongWord;
Begin

  TxLeft := FPSLEFT + FPSWIDTH - (Length(FPSSTRING) * 8 * FPSSCALE);
  SP_GetRegion32(DISPLAYPOINTER, DISPLAYSTRIDE, DISPLAYHEIGHT, FPSIMAGE, FPSLEFT, FPSTOP, FPSWIDTH, FPSHEIGHT, Error);
  SP_RawTextOut(SYSFONT, DISPLAYPOINTER, DISPLAYSTRIDE Shr 2, DISPLAYHEIGHT, TxLeft, FPSTOP, FPSSTRING, $8000FF00, 0, FPSSCALE, FPSSCALE, True, True);

  If SHOWFPSHISTORY Then Begin
    Ml := FPSTOP + (FPSHEIGHT Div 2);
    Hx := TxLeft - 4 * FPSSCALE;

    If FPSSTRING <> '' Then Begin
      i := 1;
      While (i <= Length(FPSSTRING)) And (FPSSTRING[i] <= ' ') Do Begin // Guard against empty string
        Inc(Hx, 8 * FPSSCALE);
        Inc(i);
      End;
    End;

    MinSize := Max(Hx - FPSHISTSIZE, FPSLEFT);

    i := FrameTimeHistoryPos -1;
    if i < 0 Then i := FrameTimeHistoryLength -1;
    Repeat
      Hy := Max(FPSTOP, Min(FPSTOP + FPSHEIGHT -1, Trunc(Ml + FrameTimeHistory[i] / 2))); // FrameTimeHistory is deviation
      ptr := DISPLAYPOINTER;
      Inc(ptr, ((DISPLAYSTRIDE Shr 2) * Hy) + Hx);
      Ptr^ := $8000FF00; // Check if this color is BGRA or RGBA
      If i > 0 Then Dec(i) Else i := FrameTimeHistoryLength -1;
      Dec(Hx);
    Until (i = FrameTimeHistoryPos) or (Hx < MinSize);
  End;
End;

Procedure GetOSDString;
Var
  s: String;
  m: Integer;
  fpsValue: Double; // Use double for calculation
begin
  if AvgFrameTime > 0.00001 then // Avoid division by zero or tiny numbers
    fpsValue := 1000.0 / AvgFrameTime
  else
    fpsValue := 0.0; // Or some other indicator like -1

  if fpsValue > 0 then
    s := Format('%.0f', [fpsValue])
  else
    s := '---'; // For "--- FPS" or similar

  FPSSTRING := OSD + aString(' ' + s);
  m := Length(FPSSTRING);
  FPSSTRING := aString(StringOfChar(' ', 1 + (MaxOSDLen - length(FPSSTRING)))) + FPSSTRING; // MaxOSDLen logic might need review for shrinking OSD
  MaxOSDLen := Max(m, MaxOSDLen); // Prevent MaxOSDLen from shrinking if OSD text gets shorter
end;

Procedure PrepFPSVars;
Begin
  If FPSIMAGE <> '' Then RestoreFPSRegion;
  // These are in logical (DISPLAYWIDTH/HEIGHT) coordinates
  GLFX := 8; // FPS X position
  GLFY := 8; // FPS Y position
  GLFW := DISPLAYWIDTH - 16; // FPS region width
  GLFH := 8 * FPSSCALE;      // FPS region height
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
    // GLMX etc. are in logical (DISPLAYWIDTH/HEIGHT) coordinates, representing dirty regions
    GLMX := MOUSESTOREX; GLMY := MOUSESTOREY;
    GLMW := MOUSESTOREW; GLMH := MOUSESTOREH;
    {$ENDIF}
    If (Not SCREENLOCK) or UPDATENOW Then Begin
      If SCMAXX >= SCMINX Then Begin // SCMINX/Y/MAXX/Y are dirty rect in logical coordinates
        SP_RestoreMouseRegion;
        While SetDR Do Sleep(1); SetDR := True; // Ensure SetDR is thread-safe if accessed elsewhere
        If SHOWFPS Then PrepFPSVars;
        X1 := SCMINX; Y1 := SCMINY; X2 := SCMAXX +1; Y2 := SCMAXY +1;

        // GLX, GLY, GLW, GLH define the main dirty rectangle for the frame
        // These are in logical (DISPLAYWIDTH/HEIGHT) coordinates
        {$IFDEF OPENGL}
        GLX := Max(X1, 0);
        GLY := Max(Y1, 0);
        GLW := Min(X2 - GLX, DISPLAYWIDTH - GLX); // Width, not X2
        GLH := Min(Y2 - GLY, DISPLAYHEIGHT - GLY); // Height, not Y2
        {$ELSE}
        iRect := Rect(X1, Y1, X2, Y2);
        {$ENDIF}
        SCMAXX := 0; SCMAXY := 0; SCMINX := DISPLAYWIDTH; SCMINY := DISPLAYHEIGHT; // Reset dirty rect
        SetDR := False;
        Result := True; // Display needs to be refreshed
        DRAWING := True; // Flag that drawing operations are happening

        If Assigned(DISPLAYPOINTER) Then
          SP_Composite32(DISPLAYPOINTER, X1 -1, Y1 -1, X2 +1, Y2 +1); // Composite sprites, etc. onto PixArray

        If SHOWFPS Then DrawFPS; // Draw FPS text onto PixArray (after main composite)

        MOUSEMOVED := False;
        If MOUSEVISIBLE or (PROGSTATE = SP_PR_STOP) Then Begin
          SP_DrawMouseImage; // Draws mouse onto PixArray
          // If mouse moved, expand the dirty mouse region (GLMX, GLMY, GLMW, GLMH)
          If (MOUSESTOREX <> GLMX) or (MOUSESTOREY <> GLMY) or (MOUSESTOREW <> GLMW) or (MOUSESTOREH <> GLMH) Then Begin // Check all mouse rect components
            Mx2 := Max(GLMX + GLMW, MOUSESTOREX + MOUSESTOREW); // Old GLMX+GLMW is previous mouse extent
            My2 := Max(GLMY + GLMH, MOUSESTOREY + MOUSESTOREH);
            Mx1 := Min(GLMX, MOUSESTOREX);
            My1 := Min(GLMY, MOUSESTOREY);
            // Update GLMX etc. to be the union of old and new mouse rects
            GLMX := Mx1; GLMY := My1; GLMW := Mx2-Mx1; GLMH := My2-My1;
            MOUSEMOVED := True; // This flag indicates the mouse region needs specific update
            // Result is already true if main content changed
          End;
        End;

        // Ensure GLMX/Y/W/H are within bounds of PixArray
        {$IFDEF OPENGL}
        GLMX := Min(Max(GLMX, 0), DISPLAYWIDTH -1);
        GLMY := Min(Max(GLMY, 0), DISPLAYHEIGHT -1);
        GLMW := Max(0, Min(GLMW, DISPLAYWIDTH - GLMX));
        GLMH := Max(0, Min(GLMH, DISPLAYHEIGHT - GLMY));
        {$ENDIF}

        SP_NeedDisplayUpdate := False; // Handled by Result
        UPDATENOW := False;
      End;
    End;
  End;
  DRAWING := False;
End;

// ScaleBuffers procedure is REMOVED as scaling is now GPU-based via shaders.

Procedure Refresh_Display;
{$IFDEF OPENGL}
Var
  useTwoPassFBO, useDirectNearest, useDirectLinear: Boolean;
  isPerfectOverallScale: Boolean; // Is final output an exact integer multiple of original?
  effScaleX, effScaleY: aFloat;   // Overall effective scale factors
  {$IFDEF DOUBLEBUFFER}
  currentDC: hDc;
  {$ENDIF}
  originalProjectionMatrix: TMatrix4f; // To save/restore projection
  originalModelViewMatrix: TMatrix4f; // To save/restore modelview
{$ENDIF}
Begin
  {$IFDEF OpenGL}
    If Not GLInitDone Then InitGL;
    If ReScaleFlag Then Begin GLResize; ReScaleFlag := False; End;

    // Ensure resources are ready
    if (MainTextureID = 0) or (not Assigned(DISPLAYPOINTER)) then Exit;

    // --- Upload PixArray to MainTextureID (Source Texture) ---
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, MainTextureID);
    // Set parameters for MainTextureID FOR THE FIRST PASS (if using FBO) or direct rendering
    // This will be GL_NEAREST if FBO is used, or based on logic if direct.
    // Data upload:
    glPixelStorei(GL_UNPACK_ROW_LENGTH, DISPLAYWIDTH);
    If (GLH > 0) And (GLW > 0) Then
      glTexSubImage2D(GL_TEXTURE_2D, 0, GLX, GLY, GLW, GLH, GL_BGRA, GL_UNSIGNED_BYTE, @PixArray[GLX * 4 + DISPLAYWIDTH * 4 * GLY]);
    If MOUSEMOVED And (GLMH > 0) And (GLMW > 0) Then
      glTexSubImage2D(GL_TEXTURE_2D, 0, GLMX, GLMY, GLMW, GLMH, GL_BGRA, GL_UNSIGNED_BYTE, @PixArray[GLMX * 4 + DISPLAYWIDTH * 4 * GLMY]);
    If SHOWFPS And (GLFH > 0) And (GLFW > 0) Then
      glTexSubImage2D(GL_TEXTURE_2D, 0, GLFX, GLFY, GLFW, GLFH, GL_BGRA, GL_UNSIGNED_BYTE, @PixArray[GLFX * 4 + DISPLAYWIDTH * 4 * GLFY]);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    glBindTexture(GL_TEXTURE_2D, 0); // Unbind while deciding path

    // --- Determine Rendering Path ---
    useTwoPassFBO := False;
    useDirectNearest := False;
    useDirectLinear := False;

    if (DISPLAYWIDTH <=0) or (DISPLAYHEIGHT <=0) then // Invalid internal size
      useDirectLinear := True // Safest fallback
    else begin
      effScaleX := CurrentOutputWidth / DISPLAYWIDTH;
      effScaleY := CurrentOutputHeight / DISPLAYHEIGHT;

      // Is the *overall* scale from original to final output a perfect integer?
      isPerfectOverallScale := (Abs(effScaleX - Round(effScaleX)) < 0.001) and
                               (Abs(effScaleY - Round(effScaleY)) < 0.001) and
                               (Round(effScaleX) = Round(effScaleY)) and
                               (Round(effScaleX) > 0);

      if INTSCALING then begin
        if isPerfectOverallScale then // e.g., 240x144 -> 480x288 (perfect 2x) or 800x480 -> 800x480 (perfect 1x)
          useDirectNearest := True
        else
          if (ActualNNScaleFactor > 0) and (FBO_ID <> 0) and (IntermediateTextureID <> 0) then
            // Use FBO if we have a valid NN scale step and resources are ready
            // (ActualNNScaleFactor will be >= 1 due to SetScaling logic)
            useTwoPassFBO := True
          else // Fallback if FBO resources not ready or NN scale is 1 but not perfect overall
            useDirectLinear := True; // Fallback for INTSCALING that can't use FBO or NN
      end else // Not INTSCALING
        useDirectLinear := True;
    end;

    // --- Perform Rendering ---

    // Save current matrices
    glMatrixMode(GL_PROJECTION); glGetFloatv(GL_PROJECTION_MATRIX, @originalProjectionMatrix);
    glMatrixMode(GL_MODELVIEW);  glGetFloatv(GL_MODELVIEW_MATRIX, @originalModelViewMatrix);

    if useTwoPassFBO then
    begin
      // === PASS 1: Render MainTextureID to IntermediateTextureID via FBO (NN scale) ===
      glBindFramebuffer(GL_FRAMEBUFFER, FBO_ID);
      glViewport(0, 0, IntermediateTexWidth, IntermediateTexHeight);

      glMatrixMode(GL_PROJECTION); glLoadIdentity();
      If not DisplayFlip Then
        glOrtho(0, IntermediateTexWidth, IntermediateTexHeight, 0, -1, 1)
      Else
        glOrtho(0, IntermediateTexWidth, 0, IntermediateTexHeight, -1, 1);
      glMatrixMode(GL_MODELVIEW); glLoadIdentity();

      // glClear(GL_COLOR_BUFFER_BIT); // Optional clear of FBO

      glBindTexture(GL_TEXTURE_2D, MainTextureID);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

      glBegin(GL_QUADS);
        glTexCoord2f(0.0, 0.0); glVertex2f(0.0, 0.0);
        glTexCoord2f(1.0, 0.0); glVertex2f(IntermediateTexWidth, 0.0);
        glTexCoord2f(1.0, 1.0); glVertex2f(IntermediateTexWidth, IntermediateTexHeight);
        glTexCoord2f(0.0, 1.0); glVertex2f(0.0, IntermediateTexHeight);
      glEnd;
      glBindTexture(GL_TEXTURE_2D, 0); // Unbind MainTextureID

      // === PASS 2: Render IntermediateTextureID to Screen (Linear scale) ===
      glBindFramebuffer(GL_FRAMEBUFFER, 0); // Back to default framebuffer
      glViewport(0, 0, CurrentOutputWidth, CurrentOutputHeight); // Restore screen viewport

      // Restore screen projection/modelview (or re-setup if GLResize did it)
      glMatrixMode(GL_PROJECTION); glLoadMatrixf(@originalProjectionMatrix);
      glMatrixMode(GL_MODELVIEW);  glLoadMatrixf(@originalModelViewMatrix);
      // If GLResize sets them correctly for the screen, this restore is fine.
      // Or, explicitly:
      // glMatrixMode(GL_PROJECTION); glLoadIdentity();
      // If DisplayFlip Then glOrtho(0, CurrentOutputWidth, CurrentOutputHeight, 0, -1, 1)
      // Else glOrtho(0, CurrentOutputWidth, 0, CurrentOutputHeight, -1, 1);
      // glMatrixMode(GL_MODELVIEW); glLoadIdentity();

      // glClear(GL_COLOR_BUFFER_BIT); // Optional clear of screen

      glBindTexture(GL_TEXTURE_2D, IntermediateTextureID);
      // IntermediateTextureID already has GL_LINEAR from SetupFBOIntermediateTexture

      glBegin(GL_QUADS);
        glTexCoord2f(0.0, 0.0); glVertex2f(0.0, 0.0);
        glTexCoord2f(1.0, 0.0); glVertex2f(CurrentOutputWidth, 0.0);
        glTexCoord2f(1.0, 1.0); glVertex2f(CurrentOutputWidth, CurrentOutputHeight);
        glTexCoord2f(0.0, 1.0); glVertex2f(0.0, CurrentOutputHeight);
      glEnd;
      glBindTexture(GL_TEXTURE_2D, 0);
    end
    else if useDirectNearest then
    begin
      // === DIRECT TO SCREEN: NEAREST NEIGHBOR ===
      // Viewport and matrices should already be set for screen by GLResize
      // glClear(GL_COLOR_BUFFER_BIT); // Optional
      glBindTexture(GL_TEXTURE_2D, MainTextureID);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
      glMatrixMode(GL_PROJECTION); glLoadIdentity();
      If not DisplayFlip Then
        glOrtho(0, CurrentOutputWidth, CurrentOutputHeight, 0, -1, 1)
      Else
        glOrtho(0, CurrentOutputWidth, 0, CurrentOutputHeight, -1, 1);
      glMatrixMode(GL_MODELVIEW); glLoadIdentity();
      glBegin(GL_QUADS);
        glTexCoord2f(0.0, 0.0); glVertex2f(0.0, 0.0);
        glTexCoord2f(1.0, 0.0); glVertex2f(CurrentOutputWidth, 0.0);
        glTexCoord2f(1.0, 1.0); glVertex2f(CurrentOutputWidth, CurrentOutputHeight);
        glTexCoord2f(0.0, 1.0); glVertex2f(0.0, CurrentOutputHeight);
      glEnd;
      glBindTexture(GL_TEXTURE_2D, 0);
    end
    else if useDirectLinear then begin
      // === DIRECT TO SCREEN: LINEAR ===
      // Viewport and matrices should already be set for screen by GLResize
      // glClear(GL_COLOR_BUFFER_BIT); // Optional
      glBindTexture(GL_TEXTURE_2D, MainTextureID);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glMatrixMode(GL_PROJECTION); glLoadIdentity();
      If not DisplayFlip Then
        glOrtho(0, CurrentOutputWidth, CurrentOutputHeight, 0, -1, 1)
      Else
        glOrtho(0, CurrentOutputWidth, 0, CurrentOutputHeight, -1, 1);
      glMatrixMode(GL_MODELVIEW); glLoadIdentity();
      glBegin(GL_QUADS);
        glTexCoord2f(0.0, 0.0); glVertex2f(0.0, 0.0);
        glTexCoord2f(1.0, 0.0); glVertex2f(CurrentOutputWidth, 0.0);
        glTexCoord2f(1.0, 1.0); glVertex2f(CurrentOutputWidth, CurrentOutputHeight);
        glTexCoord2f(0.0, 1.0); glVertex2f(0.0, CurrentOutputHeight);
      glEnd;
      glBindTexture(GL_TEXTURE_2D, 0);
    end;

    // Restore original matrices if they were changed for FBO pass
    // (already handled by saving/loading, or explicit re-setup for screen)

    {$IFDEF DOUBLEBUFFER}
    currentDC := wglGetCurrentDC();
    If currentDC <> 0 then SwapBuffers(currentDC);
    {$ELSE}
    glFlush;
    {$ENDIF}

  {$ELSE} // Not OPENGL
    If StartTime = 0 Then
      StartTime := CB_GetTicks;
    StretchBlt(Main.Canvas.Handle, 0, 0, Main.ClientWidth, Main.ClientHeight, Bitmap.Canvas.Handle, 0, 0, DISPLAYWIDTH, DISPLAYHEIGHT, SrcCopy);
  {$ENDIF} // OPENGL
End;

Procedure SetScaling(InternalWidth, InternalHeight, OutputClientWidth, OutputClientHeight: Integer);
{$IFDEF OPENGL}
Var
  effScaleX, effScaleY: aFloat;
{$ENDIF}
Begin
  {$IFDEF OPENGL}
  CurrentOutputWidth := OutputClientWidth;
  CurrentOutputHeight := OutputClientHeight;

  if (InternalWidth <= 0) or (InternalHeight <= 0) then
  begin
    ActualNNScaleFactor := 1; // Default
    ScaleMouseX := 1.0;
    ScaleMouseY := 1.0;
  end
  else
  begin
    effScaleX := OutputClientWidth / InternalWidth;
    effScaleY := OutputClientHeight / InternalHeight;

    // Determine the integer scale for the first NN pass
    // This should be the largest integer scale that is LESS THAN OR EQUAL TO the target effective scale.
    if (effScaleX >= 1.0) and (effScaleY >= 1.0) then // Upscaling
    begin
      ActualNNScaleFactor := Max(1, Floor(Min(effScaleX, effScaleY)));
    end
    else // Downscaling or no scaling needed for NN pass
    begin
      ActualNNScaleFactor := 1;
    end;

    // This factor is used if we fallback to the single-pass shader or for other logic.
    CurrentIntegerNNScaleFactor := ActualNNScaleFactor;
    ScaleMouseX := OutputClientWidth / InternalWidth;
    ScaleMouseY := OutputClientHeight / InternalHeight;
  end;

  DISPLAYWIDTH := InternalWidth;
  DISPLAYHEIGHT := InternalHeight;
  DISPLAYSTRIDE := InternalWidth * 4;
  If (Length(PixArray) <> DISPLAYSTRIDE * InternalHeight) or (DISPLAYPOINTER = nil) or (PixArray = nil) then
  Begin
    SetLength(PixArray, DISPLAYSTRIDE * InternalHeight);
    if Length(PixArray) > 0 then FillChar(PixArray[0], Length(PixArray), 0);
    if Length(PixArray) > 0 then DISPLAYPOINTER := @PixArray[0] else DISPLAYPOINTER := nil;
  End;

  ReScaleFlag := True; // Signal GLResize/SetupFBO needs to run
  {$ELSE}
  Main.CreateGDIBitmap;
  ScaleMouseX := OutputClientWidth / InternalWidth;
  ScaleMouseY := OutputClientHeight / InternalHeight;
  {$ENDIF}
End;

Function SetScreen(Width, Height, sWidth, sHeight: Integer; FullScreen, AllowResize: Boolean): Integer;
Var
  oW, oH: Integer; // Old output width/height
  oFS: Boolean;
  l, t, w, h: NativeInt; // Target window left, top, width, height for SendMessage
  r: TRect;
Begin
  SetPerformingDisplayChange(True);
  {$IFDEF RefreshThread}
  CB_PauseDisplay;
  {$ELSE}
  DisplaySection.Enter;
  {$ENDIF}
  Try
    Result := 0;
    {$IFDEF OPENGL}
    oW := CurrentOutputWidth; // Previously SCALEWIDTH
    oH := CurrentOutputHeight; // Previously SCALEHEIGHT
    {$ELSE}
    oW := DISPLAYWIDTH; // Fallback if OpenGL not defined, though SetScaling won't be called
    oH := DISPLAYHEIGHT;
    {$ENDIF}
    oFS := SPFULLSCREEN;

    If FullScreen <> SPFULLSCREEN Then Begin
      If FullScreen Then Begin // Going TO fullscreen
        WINLEFT := Main.Left;
        WINTOP := Main.Top;
        WINWIDTH := Main.ClientWidth;
        WINHEIGHT := Main.ClientHeight;
        // sWidth, sHeight (parameters) are used for the target fullscreen resolution
      End Else Begin // Going FROM fullscreen TO windowed (FullScreen is False, SPFULLSCREEN was True)
        // Always restore to stored WINWIDTH/WINHEIGHT when exiting fullscreen,
        // overriding any sWidth/sHeight parameters passed in this specific transition.
        sWidth := WINWIDTH;
        sHeight := WINHEIGHT;
        // If you wanted to allow SCREEN WINDOW <new_w>, <new_h> to specify a *new* windowed size
        // different from the restored one, you'd check if Param_sWidth/Height were > 0 here
        // and use them. But for a simple "restore", the above is correct.
      End;
    End Else Begin // Not changing fullscreen state (e.g., windowed to windowed resize)
      If Not FullScreen Then Begin // Windowed to Windowed resize
        WINLEFT := Main.Left; // Update stored position for next potential fullscreen switch
        WINTOP := Main.Top;
        // sWidth, sHeight (parameters) are the new target client dimensions for this windowed resize
        // WINWIDTH/WINHEIGHT are NOT updated here. They correctly keep the size from *before* the last time you entered fullscreen.
      End;
      // If Fullscreen to Fullscreen (Resolution Change):
      // sWidth, sHeight (parameters) are new fullscreen res. WINWIDTH/H are not changed.
    End;

    DISPLAYWIDTH := Width;   // Logical/Internal width
    DISPLAYHEIGHT := Height; // Logical/Internal height

    // Check if actual screen resolution or fullscreen state needs to change
    if AllowResize And ((sWidth <> oW) or (sHeight <> oH) or (oFS <> FullScreen)) Then Begin
      {$IFDEF OPENGL}
      GLInitDone := False; // Trigger full GL reinitialization if screen mode changes
      {$ENDIF}
      SetScreenResolution(sWidth, sHeight, FullScreen); // This changes physical screen res / window style
    End Else
      {$IFDEF OpenGL}ReScaleFlag := True{$ENDIF}; // Only scaling parameters changed, or no change

    // Now, set the window size and position
    // w, h here are the target Main.Width, Main.Height (including borders etc.)
    // sWidth, sHeight are target Main.ClientWidth, Main.ClientHeight
    w := sWidth;  // Target client width
    h := sHeight; // Target client height

    SystemParametersInfo(SPI_GETWORKAREA, 0, @r, 0);

    If FullScreen Then Begin
      SP_GetMonitorMetrics; // Updates REALSCREENLEFT, TOP, WIDTH, HEIGHT
      l := REALSCREENLEFT;
      t := REALSCREENTOP;
      // For fullscreen, sWidth and sHeight from SetScreenResolution are already the full monitor size
      // or desired fullscreen resolution. SendMessage will use these for WM_RESIZEMAIN.
      // The WM_RESIZEMAIN should set Main.Width/Height to sWidth/sHeight.
    End Else Begin // Windowed mode
      If INSTARTUP Then Begin
        // Calculate initial centered position based on WORKAREA and target window size (w,h)
        // Note: w,h passed to SendMessage in WM_RESIZEMAIN are expected to be total window size,
        // but we calculated them from client sWidth, sHeight. AdjustWindowRect might be needed
        // if WM_RESIZEMAIN doesn't handle client-to-window size conversion.
        // For simplicity, let's assume WM_RESIZEMAIN takes client dimensions and adjusts.
        l := ((r.Right - r.Left) - sWidth) Div 2; // Center based on client width
        t := ((r.Bottom - r.Top) - sHeight) Div 2; // Center based on client height
      End Else Begin
        l := WINLEFT;
        t := WINTOP;
      End;
    End;

    // WM_RESIZEMAIN should handle setting the form's Left, Top, Width, Height
    // and then call SetScaling with the new ClientWidth/Height
    If AllowResize Then
      SendMessage(Main.Handle, WM_RESIZEMAIN, MakeLong(Word(l), Word(t)), MakeLong(Word(sWidth), Word(sHeight)))
    Else
      SetScaling(DISPLAYWIDTH, DISPLAYHEIGHT, Main.ClientWidth, Main.ClientHeight);
    // After SendMessage, Main.ClientWidth/Height should be sWidth/sHeight.
    // SetScaling should be called from the Main.FormResize triggered by WM_RESIZEMAIN.
    // If not, call it explicitly here:
    // {$IFDEF OPENGL}
    // SetScaling(DISPLAYWIDTH, DISPLAYHEIGHT, Main.ClientWidth, Main.ClientHeight);
    // {$ENDIF}
  Finally
    {$IFDEF RefreshThread}
    CB_ResumeDisplay;
    {$ELSE}
    DisplaySection.Leave;
    {$ENDIF}
    SetPerformingDisplayChange(False);
    If Not AllowResize Then
      SIZINGMAIN := False;
  End;
End;

Function GetScreenRefreshRate: aFloat;
var
  DeviceMode: TDeviceMode;
  TimingInfo: DWM_TIMING_INFO;
  HRes: HRESULT;
  Success: Boolean;
const
  ENUM_CURRENT_SETTINGS = DWORD(-1);
Begin
  ZeroMemory(@TimingInfo, SizeOf(TimingInfo));
  TimingInfo.cbSize := SizeOf(TimingInfo);
  HRes := DwmGetCompositionTimingInfo(0, TimingInfo);
  Success := (HRes = S_OK) And (TimingInfo.rateRefresh.uiDenominator <> 0);
  If Success Then
    Result := TimingInfo.rateRefresh.uiNumerator / TimingInfo.rateRefresh.uiDenominator
  Else Begin
    DeviceMode.dmSize := SizeOf(TDeviceMode);
    FillChar(DeviceMode, DeviceMode.dmSize, 0);
    DeviceMode.dmSize := SizeOf(TDeviceMode);
    EnumDisplaySettings(nil, ENUM_CURRENT_SETTINGS, DeviceMode);
    Result := DeviceMode.dmDisplayFrequency;
  End;
End;

function TestScreenResolution(Width, Height: Integer; FullScreen: Boolean): Boolean;
var
  DeviceMode: TDeviceMode; // Use Ansi version explicitly if issues
  hMod, wMod: Integer;
begin
  If FullScreen Then Begin
    DeviceMode.dmSize := SizeOf(TDeviceMode);
    FillChar(DeviceMode, DeviceMode.dmSize, 0); // Important
    DeviceMode.dmSize := SizeOf(TDeviceMode);
    DeviceMode.dmPelsWidth := Width;
    DeviceMode.dmPelsHeight := Height;
    DeviceMode.dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;
    hMod := ChangeDisplaySettings(DeviceMode, CDS_TEST);
    Result := hMod = DISP_CHANGE_SUCCESSFUL;
  End Else Begin
    SP_GetMonitorMetrics;
    hMod := Main.Height - Main.ClientHeight; // Border/caption height
    wMod := Main.Width - Main.ClientWidth;   // Border/caption width
    Result := (Width + wMod <= REALSCREENWIDTH) and (Height + hMod <= REALSCREENHEIGHT);
  End;
end;

function GetMonitorName(hmon: HMONITOR) : string;
var
  DispDev : TDisplayDevice;
  monInfo : TMonitorInfoEx;
begin
  Result := '';
  monInfo.cbSize := sizeof(monInfo);
  if GetMonitorInfo(hmon, @monInfo) then begin // Use Ansi
    DispDev.cb := sizeof(DispDev);
    EnumDisplayDevices(nil, 0, DispDev, 0); // Use Ansi
    Result := StrPas(monInfo.szDevice); // monInfo.szDevice is array of AnsiChar
  end;
end;

procedure SP_GetMonitorMetrics;
Var
  Monitor: TMonitor;
Begin
  Monitor := Screen.MonitorFromWindow(Main.Handle);
  REALSCREENWIDTH := Monitor.Width; // This is primary monitor width or desktop width.
  REALSCREENHEIGHT := Monitor.Height; // For multi-monitor, Monitor.BoundsRect is better
  REALSCREENLEFT := Monitor.Left;
  REALSCREENTOP := Monitor.Top;
  // If you want the specific monitor's resolution the window is on:
  // REALSCREENWIDTH := Monitor.BoundsRect.Width;
  // REALSCREENHEIGHT := Monitor.BoundsRect.Height;
End;

function SetScreenResolution(Width, Height: Integer; FullScreen: Boolean): Boolean;
var
  MonitorName: String;
  oldDeviceMode, DeviceMode: TDeviceMode;
  oW, oH: Integer;
  oFS: Boolean;
const
  ENUM_CURRENT_SETTINGS = DWORD(-1);
begin
  DeviceMode.dmSize := SizeOf(TDeviceMode); // Init size for all uses
  FillChar(DeviceMode, DeviceMode.dmSize, 0);
  DeviceMode.dmSize := SizeOf(TDeviceMode);

  oldDeviceMode.dmSize := SizeOf(TDeviceMode);
  FillChar(oldDeviceMode, oldDeviceMode.dmSize, 0);
  oldDeviceMode.dmSize := SizeOf(TDeviceMode);

  If SPFULLSCREEN Then Begin
    EnumDisplaySettings(nil, ENUM_CURRENT_SETTINGS, oldDeviceMode);
    oW := oldDeviceMode.dmPelsWidth;
    oH := oldDeviceMode.dmPelsHeight;
    oFS := True;
  End Else Begin
    {$IFDEF OPENGL}
    oW := CurrentOutputWidth; // Was WINWIDTH, but that might be stale
    oH := CurrentOutputHeight; // Was WINHEIGHT
    {$ELSE}
    oW := Main.ClientWidth;
    oH := Main.ClientHeight;
    {$ENDIF}
    oFS := False;
  End;

  SP_GetMonitorMetrics; // Get current monitor info

  If FullScreen Then Begin
    MonitorName := GetMonitorName(Screen.MonitorFromWindow(Main.Handle).Handle);
    DeviceMode.dmPelsWidth := Width;
    DeviceMode.dmPelsHeight := Height;
    DeviceMode.dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;
    // Only change display settings if needed
    If (oFS <> FullScreen) or (Width <> oW) or (Height <> oH) Then Begin
      Main.BorderStyle := bsNone;
      Result := ChangeDisplaySettingsEx(PChar(MonitorName), DeviceMode, 0, CDS_FULLSCREEN, nil) = DISP_CHANGE_SUCCESSFUL;
      // After changing, window might need to be explicitly sized to the new full screen
      SetWindowPos(Main.Handle, HWND_TOPMOST, REALSCREENLEFT, REALSCREENTOP, Width, Height, SWP_SHOWWINDOW);
    End Else
      Result := True; // No change needed
    SPFULLSCREEN := True;
  End Else Begin // Setting to Windowed mode
    If SPFULLSCREEN Then Begin // Was fullscreen, now changing to windowed
      // Restore original desktop resolution if it was changed
      // This needs the *original* desktop mode, not just any mode.
      // It's often better to pass NIL to ChangeDisplaySettings to revert to registry default.
      ChangeDisplaySettings(DeviceMode, 0); // Revert to default screen resolution
      Main.BorderStyle := bsSingle;
      SPFULLSCREEN := False; // Set before potentially resizing main form
      // Window position/size will be handled by SetScreen via WM_RESIZEMAIN
    End;
    Result := True; // Windowed mode change is generally successful unless invalid dimensions
  End;
end;

{$IFDEF OpenGL}
Procedure EnsureMainTextureIsSetup; // NEW HELPER specifically for MainTextureID
begin
  if MainTextureID = 0 then
  begin
    // This should have been done in InitGL, but as a fallback:
    glGenTextures(1, @MainTextureID);
    if MainTextureID = 0 then Exit;
  end;

  glBindTexture(GL_TEXTURE_2D, MainTextureID);
  // Define/Redefine storage if DISPLAYWIDTH/HEIGHT changed or if it's the first time.
  // Using GL_RGBA8 for a sized internal format.
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, DISPLAYWIDTH, DISPLAYHEIGHT, 0, GL_BGRA, GL_UNSIGNED_BYTE, nil);

  // Crucial for non-mipmap-filtered textures if you only upload level 0
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);

  // Default wrap, filtering will be set per-use in Refresh_Display
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glBindTexture(GL_TEXTURE_2D, 0);
end;

Procedure SetupFBOAndIntermediateTexture;
var
  Status: GLenum;
begin
  // This procedure ONLY deals with FBO_ID and IntermediateTextureID
  // It assumes DISPLAYWIDTH, DISPLAYHEIGHT, and ActualNNScaleFactor are correctly set.

  if (FBO_ID = 0) then // FBO must exist
  begin
    // Ensure any old intermediate texture is cleaned if FBO can't be used
    if IntermediateTextureID <> 0 then begin
      glDeleteTextures(1, @IntermediateTextureID);
      IntermediateTextureID := 0;
    end;
    Exit;
  end;

  if (DISPLAYWIDTH <= 0) or (DISPLAYHEIGHT <= 0) or (ActualNNScaleFactor <= 0) then
  begin
    if IntermediateTextureID <> 0 then begin glDeleteTextures(1, @IntermediateTextureID); IntermediateTextureID := 0; end;
    // Detach from FBO if it was previously attached
    glBindFramebuffer(GL_FRAMEBUFFER, FBO_ID);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    Exit;
  end;

  IntermediateTexWidth := DISPLAYWIDTH * ActualNNScaleFactor;
  IntermediateTexHeight := DISPLAYHEIGHT * ActualNNScaleFactor;

  if (IntermediateTexWidth <= 0) or (IntermediateTexHeight <= 0) then
  begin
    if IntermediateTextureID <> 0 then begin glDeleteTextures(1, @IntermediateTextureID); IntermediateTextureID := 0; end;
    glBindFramebuffer(GL_FRAMEBUFFER, FBO_ID);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    Exit;
  end;

  if IntermediateTextureID <> 0 then glDeleteTextures(1, @IntermediateTextureID); // Always recreate for simplicity if size might change
  glGenTextures(1, @IntermediateTextureID);

  if IntermediateTextureID = 0 then
    Exit;

  glBindTexture(GL_TEXTURE_2D, IntermediateTextureID);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, IntermediateTexWidth, IntermediateTexHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, nil);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); // This texture is always linearly sampled in Pass 2
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);
  glBindTexture(GL_TEXTURE_2D, 0);

  glBindFramebuffer(GL_FRAMEBUFFER, FBO_ID);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, IntermediateTextureID, 0);

  Status := glCheckFramebufferStatus(GL_FRAMEBUFFER);
  if Status <> GL_FRAMEBUFFER_COMPLETE then
  begin
    if IntermediateTextureID <> 0 then begin glDeleteTextures(1, @IntermediateTextureID); IntermediateTextureID := 0; end;
    // FBO_ID itself remains, but it's unusable with this attachment.
    // Refresh_Display logic must check IntermediateTextureID <> 0 before using FBO path.
  end;
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
end;

Procedure GLResize;
Begin
  if Not GLInitDone then Exit;

  // 1. Setup main screen viewport and projection
  glClearColor(0, 0, 0, 0);
  glViewport(0, 0, CurrentOutputWidth, CurrentOutputHeight);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  If DisplayFlip Then
    glOrtho(0, CurrentOutputWidth, CurrentOutputHeight, 0, -1, 1)
  Else
    glOrtho(0, CurrentOutputWidth, 0, CurrentOutputHeight, -1, 1);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  glEnable(GL_TEXTURE_2D); // Default state

  // 2. Ensure MainTextureID (for PixArray) is correctly set up
  EnsureMainTextureIsSetup; // This defines storage and mipmap levels for MainTextureID

  // 3. Setup FBO and IntermediateTextureID IF needed for a two-pass scenario.
  //    ActualNNScaleFactor is determined by SetScaling.
  //    The decision to *use* the FBO is in Refresh_Display. Here we just ensure it's ready if conditions might warrant it.
  if (FBO_ID <> 0) and (ActualNNScaleFactor > 1) and INTSCALING then // Only setup FBO's texture if it might actually be used
  begin                                                              // (i.e. INTSCALING and ActualNNScaleFactor > 1 for NN step)
    SetupFBOAndIntermediateTexture;
  end
  else if IntermediateTextureID <> 0 then // If conditions no longer met, clean up old intermediate FBO texture
  begin
    glDeleteTextures(1, @IntermediateTextureID);
    IntermediateTextureID := 0;
    // Detach from FBO
    if FBO_ID <> 0 then
    begin
      glBindFramebuffer(GL_FRAMEBUFFER, FBO_ID);
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0); // Detach
      glBindFramebuffer(GL_FRAMEBUFFER, 0);
    end;
  end;

  ReScaleFlag := False;

  // VSYNC (should be fine here)
  // ...
End;
{$ENDIF}

Procedure ScreenShot(fullWindow: Boolean);
{$IFDEF OPENGL}
var
  Win: HWND;
  // DC was conflicting with global DC
  ScreenDC: HDC; // Changed name
  Bmp: TBitmap;
  Png: TPNGImage;
  Pixels: pByte;
  FName, FileName: string;
  WinRect, WinRectEx: TRect;
  TheWidth, TheHeight, ox, i: Integer; // Renamed Width, Height to avoid conflict
  Error: TSP_ErrorCode;
  {$ENDIF}
begin
  {$IFDEF OPENGL} // Screenshot logic primarily for OpenGL path for now
  If Not DirectoryExists(String(HOMEFOLDER) + '\snaps') Then
    CreateDir(String(HOMEFOLDER) + '\snaps');

  FName := Format('/snaps/%s.png', ['Screenshot_' + FormatDateTime('mm-dd-yyyy-hhnnss', Now())]);
  Filename := String(SP_ConvertFilenameToHost(aString(FName), Error));

  Bmp := TBitmap.Create;
  try
    if SPFULLSCREEN or (not fullWindow) then // Capture logical display (PixArray) in fullscreen or if !fullWindow
    begin
      // Capture from PixArray (our internal 800x480 buffer)
      if not Assigned(DISPLAYPOINTER) or (Length(PixArray) = 0) then Exit; // No data
      Bmp.Height := DISPLAYHEIGHT; // Logical height
      Bmp.Width := DISPLAYWIDTH;   // Logical width
      Bmp.PixelFormat := pf32bit;
      Pixels := DISPLAYPOINTER;
      for i := 0 To Bmp.Height -1 do Begin // Use Bmp.Height for loop
        // PixArray is BGRA, TBitmap Scanline expects BGRA by default (pf32bit)
        CopyMemory(Bmp.ScanLine[i], Pixels, Bmp.Width * SizeOf(LongWord)); // Use Bmp.Width
        Inc(Pixels, DISPLAYSTRIDE); // DISPLAYSTRIDE is correct for PixArray
      End;
    end
    else // fullWindow is true AND NOT SPFULLSCREEN: Capture entire window DC
    begin
      Win := Main.Handle; // Assuming Main is the TForm
      ox := 0;
      if (Win32MajorVersion >= 6) and DwmCompositionEnabled then Begin
        DwmGetWindowAttribute(Win, DWMWA_EXTENDED_FRAME_BOUNDS, @WinRect, SizeOf(WinRect));
        GetWindowRect(Win, WinRectEx); // Get standard window rect
        Ox := WinRect.Left - WinRectEx.Left; // Offset if DWM adds invisible borders
      End else
        GetWindowRect(Win, WinRect);

      ScreenDC := GetWindowDC(Win); // Get DC for the entire window (including title bar, borders)
      if ScreenDC = 0 then Exit;
      try
        TheWidth := WinRect.Right - WinRect.Left;
        TheHeight := WinRect.Bottom - WinRect.Top;
        Bmp.Height := TheHeight;
        Bmp.Width := TheWidth;
        BitBlt(Bmp.Canvas.Handle, 0, 0, TheWidth, TheHeight, ScreenDC, ox, 0, SRCCOPY);
      finally
        ReleaseDC(Win, ScreenDC);
      end;
    end;

    Png := TPNGImage.Create;
    try
      Png.Assign(Bmp);
      Png.SaveToFile(Filename);
    finally
      Png.Free;
    end;
  finally
    Bmp.Free;
  end;
  {$ENDIF} // OPENGL
end;

Initialization

  StartTime := 0;
  G_DisplayChangeLock := TCriticalSection.Create;
  FrameProcessedEvent := TEvent.Create;

Finalization

  FrameProcessedEvent.Free;
  G_DisplayChangeLock.Free;

end.

