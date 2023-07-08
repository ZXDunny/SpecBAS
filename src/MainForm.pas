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

unit MainForm;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$INCLUDE SpecBAS.inc}
{$DEFINE OPENGL}

interface

uses
  {$IFNDEF FPC}System.Types, SyncObjs, SHellAPI, PNGImage, GIFImg, WIndows, Messages,{$ELSE} LCLIntf, LCLType, {$IFDEF Windows}Windows, Messages{$ELSE}LMessages{$ENDIF}, {$ENDIF}
  SHFolder, SysUtils, Variants, Classes, Graphics, Controls, Forms, Math,
  Dialogs, SP_SysVars, SP_Graphics, SP_Graphics32, SP_BankManager, SP_Util, SP_Main, SP_FileIO,
  ExtCtrls, SP_Input, MMSystem, SP_Errors, SP_Sound, Bass, SP_Tokenise, SP_Menu, RunTimeCompiler,
  {$IFDEF OPENGL}dglOpenGL,{$ENDIF} SP_Components, SP_BaseComponentUnit, Clipbrd;

Const

  WM_RESIZEMAIN = WM_USER + 1;

type

  TMain = class(TForm)
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure FormPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean);
  private
    { Private declarations }
    Minimised: Boolean;
    procedure OnAppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure CMDialogKey( Var msg: TCMDialogKey ); message CM_DIALOGKEY;
    Procedure OnResizeMain(Var Msg: TMessage); Message WM_RESIZEMAIN;
    procedure WMMenuChar(var MessageRec: TWMMenuChar); message WM_MENUCHAR;
  public
    { Public declarations }
    Function  GetCharFromVirtualKey(Var Key: Word): astring;
    procedure DropFiles(var msg: TMessage ); message WM_DROPFILES;
  end;

  TSpecBAS_Thread = Class(TThread)
    Procedure Execute; Override;
  End;

  TRefreshThread = Class(TThread)
    Procedure Execute; Override;
  End;

  {$IFDEF OPENGL}
  Procedure InitGL;
  {$ENDIF}
  Function  SetScreen(Width, Height, sWidth, sHeight: Integer; FullScreen: Boolean): Integer;
  Function  SetScreenResolution(Width, Height: Integer; FullScreen: Boolean): Boolean;
  Function  TestScreenResolution(Width, Height: Integer; FullScreen: Boolean): Boolean;
  Procedure SetScaling(Width, Height, sWidth, sHeight: Integer);
  Procedure Refresh_Display;
  Function  UpdateDisplay: Boolean;

  Procedure YieldProc; inline;
  Procedure MsgProc; inline;
  Procedure GetKeyState;
  Function  GetTicks: aFloat;
  Procedure MouseMoveTo(ToX, ToY: Integer);
  Function  GetTimerFrequency: aFloat;
  Procedure Quit;
  function  Sto_GetFmtFileVersion(const FileName: String = ''; const Fmt: String = '%d.%d'): String;
  Procedure LoadImage(Filename: aString; Var Error: TSP_ErrorCode);
  Procedure SaveImage(Filename: aString; w, h: Integer; Pixels, Palette: pByte);
  Procedure FreeImageResource;
  Procedure UpdateLinuxBuildStr;
  Procedure SetWindowCaption;

var
  Main: TMain;
  ScrWidth, ScrHeight, OrgWidth, OrgHeight: Integer;
  GLX, GLY, GLW, GLH, GLMX, GLMY, GLMW, GLMH: Integer;
  iRect: TRect;
  BASThread: TSpecBAS_Thread;
  RefreshTimer: TRefreshThread;
  Quitting: Boolean = False;
  InitTime: LongWord;
  ImgResource: Array of Byte;
  lastt, ft: Longword;
  TimerFreq, BaseTime: Int64;
  Bits: Pointer;
  Bitmap: TBitmap = Nil;
  LastMouseX, LastMouseY: Integer;
  {$IFDEF OPENGL}
    LastScaledMouseX, LastScaledMouseY: Integer;
    GLInitDone, ReScaleFlag: Boolean;
    PixArray, DispArray: Array of Byte;
    RC: HGLRC;
    DC: hDc;
  {$ENDIF}
  DoScale: Boolean = False;
  ScaleFactor: Integer = 1;
  ScaleMouseX, ScaleMouseY: aFloat;
  MouseInForm, IgnoreNextMenuChar, AltDown, FormActivated: Boolean;
  AltChars: aString;
  MainCanResize: Boolean = True;

{$IFDEF OPENGL}
Const

  GL_BGRA = $80E1;
{$ENDIF}


implementation

Uses {$IFDEF FPC}ShlObj, {$ENDIF}SP_FPEditor, SP_ToolTipWindow;

{$IFDEF FPC}
  {$R *.lfm}
{$ELSE}
  {$R *.dfm}
{$ENDIF}

Procedure TMain.OnResizeMain(Var Msg: TMessage);
Var
  l, t, w, h, cw, ch: Integer;
Begin

  MainCanResize := False;

  cw := ClientWidth;
  ch := ClientHeight;
  l := SmallInt(Msg.wParam And $FFFF);
  t := SmallInt((Msg.wParam Shr 16) And $FFFF);
  w := Msg.lParam And $FFFF;
  h := (Msg.lParam Shr 16) And $FFFF;

  If Visible Then
    SendMessage(Handle, WM_SETREDRAW, WPARAM(False), 0);
  try
    ClientWidth := w;
    ClientHeight := h;
    Left := l;
    Top := t;
  finally
    If Visible Then
      SendMessage(Handle, WM_SETREDRAW, WPARAM(True), 0);
  End;

  FormResize(Self);

  Msg.Result := 0;
  SIZINGMAIN := False;

  MainCanResize := True;

End;

Procedure TRefreshThread.Execute;
Var
  StartTime, LastFrames: NativeUint;
  p: TPoint;
Begin

  FreeOnTerminate := True;
  NameThreadForDebugging('Refresh Thread');
  Priority := tpNormal;
  RefreshThreadAlive := True;

  While Not SP_Interpreter_Ready Do CB_YIELD;

  StartTime := Round(CB_GETTICKS);
  LastFrames := 0;

  While Not QUITMSG Do Begin

    FRAMES := Trunc((CB_GETTICKS - StartTime)/FRAME_MS);
    If FRAMES <> LastFrames Then Begin

      FrameElapsed := True;
      Inc(AutoFrameCount);
      LastFrames := FRAMES;

      DisplaySection.Enter;

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

      If SP_FrameUpdate Then Begin
        If UpdateDisplay Then Begin
          CB_Refresh_Display;
          SP_NeedDisplayUpdate := False;
        End;
        UPDATENOW := False;
        CauseUpdate := False;
      End;
      DisplaySection.Leave;

    End Else

      Sleep(1);

  End;

  {$IFDEF OpenGL}
  wglMakeCurrent(0, 0);
  wglDeleteContext(RC);
  ReleaseDC(Main.Handle, DC);
  DeleteDC (DC);
  {$ENDIF}

  RefreshThreadAlive := False;

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
        If Assigned(DISPLAYPOINTER) Then
          SP_Composite32(DISPLAYPOINTER, X1, Y1, X2, Y2);
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
    glClear(GL_COLOR_BUFFER_BIT);
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
    End Else Begin
      if (GLH > 0) And (GLW > 0) Then Begin
        glPixelStorei(GL_UNPACK_ROW_LENGTH, DISPLAYWIDTH);
        glTexSubImage2D(GL_TEXTURE_2D, 0, GLX, GLY, GLW, GLH, GL_BGRA, GL_UNSIGNED_BYTE, @PixArray[GLX * 4 + DISPLAYWIDTH * 4 * GLY]);
      End;
      If (GLMW > 0) And (GLMH > 0) And MOUSEMOVED Then
        glTexSubImage2D(GL_TEXTURE_2D, 0, GLMX, GLMY, GLMW, GLMH, GL_BGRA, GL_UNSIGNED_BYTE, @PixArray[GLMX * 4 + DISPLAYWIDTH * 4 * GLMY]);
    End;

    glBegin(GL_QUADS);
    glTexCoord2D(0, 0); glVertex2D(0, 0);
    glTexCoord2D(1, 0); glVertex2D(ScaleWidth, 0);
    glTexCoord2D(1, 1); glVertex2D(ScaleWidth, ScaleHeight);
    glTexCoord2D(0, 1); glVertex2D(0, ScaleHeight);
    glEnd;

    glGetIntegerv(GL_UNPACK_ROW_LENGTH, @tmp);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    SwapBuffers(DC);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, tmp); //DISPLAYWIDTH);
    glFinish;

  {$ELSE}
    InvalidateRect(Main.Handle, iRect, False);
    Main.Repaint;
  {$ENDIF}

End;

Function GetTicks: aFloat;
Var
  t: Int64;
Begin
  QueryPerformanceCounter(t);
  Result := t/TimerFreq * 1000;
End;

Function GetTimerFrequency: aFloat;
Begin
  Result := TimerFreq;
End;

Procedure SetScaling(Width, Height, sWidth, sHeight: Integer);
Begin

  {$IFDEF OPENGL}

  SCALEWIDTH := sWidth;
  SCALEHEIGHT := sHeight;
  If INTSCALING And Not ((SCALEWIDTH/DISPLAYWIDTH = Floor(SCALEWIDTH/DISPLAYWIDTH)) And (SCALEHEIGHT/DISPLAYHEIGHT = Floor(SCALEHEIGHT/DISPLAYHEIGHT))) Then Begin
    DoScale := (sWidth/Width >= 1.5) or (sHeight/Height >= 1.5);
    ScaleFactor := Max(Round(sWidth/Width), Round(sHeight/Height));
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

procedure TMain.OnAppMessage(var Msg: TMsg; var Handled: Boolean);
begin

  case Msg.message of
    WM_SYSCHAR:
      Handled := aChar(Msg.wParam) in ['a'..'z', 'A'..'Z', '0'..'9'];
    WM_KEYDOWN:
      begin
        if (Msg.lParam shr 30) = 1 then begin
          Handled := True;
        end else
          Handled := False;
      end;
  else
     // Not handled
     Handled := False;
  end;

End;

Procedure TSpecBAS_Thread.Execute;
Begin

  NameThreadForDebugging('Interpreter Thread');

  InterpreterThreadAlive := True;
  Priority := tpNormal;
  SP_MainLoop;
  InterpreterThreadAlive := False;

End;

procedure TMain.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Var
  mi: SP_MenuSelection;
  Win: Pointer;
  Btn, ID: Integer;
  p: TPoint;
  Handled: Boolean;
begin

  If ScaleMouseX > 0 Then Begin

    SetCapture(Handle);

    {$IFDEF OPENGL}
    X := Round(X / ScaleMouseX);
    Y := Round(Y / ScaleMouseY);
    {$ENDIF}

    MOUSEX := X;
    MOUSEY := Y;
    Btn := Integer(ssLeft in Shift) + (2 * Integer(ssRight in Shift)) + (4 * Integer(ssMiddle in Shift));

    // Menus take precedence over everything

    If CURMENU <> -1 Then Begin

      If (ssRight in Shift) Then
        If Not (MENUSHOWING Or MENUBLOCK) Then Begin

          SP_DisplayMainMenu;
          SP_SetMenuSelection(X, Y, CURMENU);
          SP_InvalidateWholeDisplay;
          MENU_SHOWFLAG := True;
          Exit;

        End;

      If (ssLeft in Shift) Then
        If MENUSHOWING Then Begin

          SP_SetMenuSelection(X, Y, CURMENU);
          mi := SP_WhichItem(X, Y);
          LASTMENU := mi.MenuID;
          LASTMENUITEM := mi.ItemIdx;
          SP_DisplayMainMenu;
          SP_InvalidateWholeDisplay;
          Refresh_Display;
          MENUBLOCK := True;

          MENU_HIDEFLAG := True;
          Exit;

        End;

    End;

    // Now check for controls under the mouse
    // *** TO DO make windowmenu appear when right-clicking if not visible ***

    Handled := False;
    CloseTipWindow;

    If ForceCapture Then Begin
      If CaptureControl.CanFocus Then
        CaptureControl.SetFocus(True);
      p := CaptureControl.ScreenToClient(Point(X, Y));
      SP_BaseComponent(CaptureControl).MouseDown(p.X, p.Y, Btn);
      Handled := True;
    End Else Begin
      Win := WindowAtPoint(X, Y, ID);
      If Assigned(Win) Then Begin
        If Not (SYSTEMSTATE in [SS_EDITOR, SS_DIRECT, SS_EVALUATE]) and (MODALWINDOW = -1) Then
          SwitchFocusedWindow(ID); // The editor handles this.
        Win := ControlAtPoint(Win, X, Y);
        If Assigned(Win) Then Begin
          CaptureControl := pSP_BaseComponent(Win)^;
          If CaptureControl.CanFocus Then
            CaptureControl.SetFocus(True);
          SP_BaseComponent(CaptureControl).MouseDown(X, Y, Btn);
          Handled := True;
        End Else Begin
          If Assigned(CaptureControl) Then
            SP_BaseComponent(CaptureControl).MouseDown(X, Y, Btn);
          If Assigned(FocusedControl) And (MODALWINDOW = -1) Then
            FocusedControl.SetFocus(False);
        End;
      End;
    End;

    // Finally, pass the mouse event to the interpreter

    If Not Handled Then Begin
      MOUSEBTN := Btn;
      M_DOWNFLAG := True;
    End;

  End;

end;

procedure TMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
Var
  Win: Pointer;
  p: TPoint;
  LMenu, LItem, Btn, tX, tY, ID: Integer;
  Handled: Boolean;
begin

  If ((X = LastMouseX) And (Y = LastMouseY)) or SIZINGMAIN or (ScaleMouseX = 0) Then Exit;

  Handled := False;
  LastMouseX := X;
  LastMouseY := Y;
  {$IFDEF OPENGL}
  If ScaleMouseX > 0 Then
    X := Round(X / ScaleMouseX);
  If ScaleMouseY > 0 Then
    Y := Round(Y / ScaleMouseY);
  If (X = LastScaledMouseX) And (Y = LastScaledMouseY) Then Exit;
  LastScaledMouseX := X;
  LastScaledMouseY := Y;
  {$ENDIF}

  // Ensure the mouse pointer is drawn at the new position

  If MOUSEVISIBLE or (PROGSTATE = SP_PR_STOP) Then
    SP_InvalidateWholeDisplay;

  Btn := Integer(ssLeft in Shift) + (2 * Integer(ssRight in Shift)) + (4 * Integer(ssMiddle in Shift));
  M_DELTAX := X - MOUSEX;
  M_DELTAY := Y - MOUSEY;
  MOUSEX := X;
  MOUSEY := Y;

  If (CURMENU <> -1) And (ssRight in Shift) And MENUSHOWING Then Begin

    LMenu := LASTMENU;
    LItem := LASTMENUITEM;
    SP_SetMenuSelection(X, Y, CURMENU);
    SP_InvalidateWholeDisplay;
    SP_NeedDisplayUpdate := True;

    If (LMenu <> LASTMENU) or (LItem <> LASTMENUITEM) Then
      MENU_HIGHLIGHTFLAG := True;

  End Else

    If MOUSEVISIBLE And Not SIZINGMAIN Then Begin

      // Now check for controls under the mouse

      Handled := False;
      If DisplaySection.TryEnter Then Begin

        tX := X; tY := Y;
        If TipWindowID <> -1 Then CheckForTip(tx, ty);
        Win := WindowAtPoint(tX, tY, ID);

        If Assigned(Win) Then Begin
          Win := ControlAtPoint(Win, tX, tY);
          If Assigned(Win) And (MouseControl <> pSP_BaseComponent(Win)^) Then
            If Assigned(MouseControl) Then
              MouseControl.MouseExit;
        End;
        If Assigned(CaptureControl) And CaptureControl.Visible Then Begin
          p := CaptureControl.ScreenToClient(Point(x, y));
          CaptureControl.PreMouseMove(p.x, p.y, Btn);
        End Else Begin
          If Assigned(Win) Then Begin
            If MouseControl <> pSP_BaseComponent(Win)^ Then Begin
              MouseControl := pSP_BaseComponent(Win)^;
              p := MouseControl.ScreenToClient(Point(tX, tY));
              MouseControl.MouseEnter(p.X, p.Y);
            End;
            pSP_BaseComponent(Win)^.PreMouseMove(tX, tY, Btn);
            Handled := True;
          End Else
            If Assigned(MouseControl) Then
              MouseControl.MouseExit;
        End;

      End;

      DisplaySection.Leave;

    End;

    // Fall through to allow user code to get mousemove events

  If Not Handled Then Begin
    M_MOVEFLAG := True;
    MOUSEBTN := Btn;
  End;

end;

procedure TMain.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Var
  mi: SP_MenuSelection;
  Win: Pointer;
  Btn, ID: Integer;
  p: TPoint;
  Handled: Boolean;
begin

  ReleaseCapture;
  If ScaleMouseX = 0 Then Exit;

  {$IFDEF OPENGL}
  X := Round(X / ScaleMouseX);
  Y := Round(Y / ScaleMouseY);
  {$ENDIF}

  MOUSEX := X;
  MOUSEY := Y;

  Btn := Integer(ssLeft in Shift) + (2 * Integer(ssRight in Shift)) + (4 * Integer(ssMiddle in Shift));

  // Menus take precedence

  If (CURMENU <> -1) And (Not (ssRight in Shift)) And MENUSHOWING Then Begin

    SP_SetMenuSelection(X, Y, CURMENU);
    mi := SP_WhichItem(X, Y);
    LASTMENU := mi.MenuID;
    LASTMENUITEM := mi.ItemIdx;
    SP_DisplayMainMenu;
    SP_InvalidateWholeDisplay;
    SP_NeedDisplayUpdate := True;

    MENU_HIDEFLAG := True;

  End Else Begin

    // Now check for controls under the mouse

    Handled := False;
    If Assigned(CaptureControl) Then Begin
      p := CaptureControl.ScreenToClient(Point(x, y));
      CaptureControl.MouseUp(p.x, p.y, Btn);
      If Not ForceCapture Then
        CaptureControl := Nil;
      Handled := True;
    End Else Begin
      Win := WindowAtPoint(X, Y, ID);
      If Assigned(Win) Then Begin
        Win := ControlAtPoint(Win, X, Y);
        If Assigned(Win) Then Begin
          pSP_BaseComponent(Win)^.MouseUp(X, Y, Btn);
          Handled := True;
        End;
      End;
    End;

    // Finally, pass the mouse event to the interpreter

    MOUSEBTN := Btn;
    If Not Handled Then Begin
      M_UPFLAG := True;
    End;

  End;

  MENUBLOCK := (ssRight in Shift);

end;

Procedure TMain.FormActivate(Sender: TObject);
begin
  FormActivated := True;
end;

procedure TMain.FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean);
var
  nw, nh{, sw, sh}: Integer;
  {Error: TSP_ErrorCode;}
begin

  Exit; // Not yet

  if WindowState = wsMinimized Then Begin
    Resize := False;
  End Else
    If MainCanResize Then Begin
      DisplaySection.Enter;
      NewHeight := Round(NewWidth * (Height / Width));
      nw := NewWidth - (Width - ClientWidth);
      nh := NewHeight - (Height - ClientHeight);
  {    sw := Ceil(nw * (DISPLAYWIDTH/SCALEWIDTH));
      sh := Ceil(nh * (DISPLAYHEIGHT/SCALEHEIGHT));
      SetScreen(sw, sh, nw, nh, SPFULLSCREEN);
      SP_ResizeWindow(0, sw, sh, -1, SPFULLSCREEN, Error);}
      SetScreen(DISPLAYWIDTH, DISPLAYHEIGHT, nw, nh, SPFULLSCREEN);
      SP_InvalidateWholeDisplay;
      SP_NeedDisplayUpdate := True;
      DisplaySection.Leave;
    End;

end;

Procedure TMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin

  PLAYSignalHalt(-1);
  If Not QUITMSG Then Begin
    Quitting := True;
    QUITMSG := True;
  End;

  While InterpreterThreadAlive And RefreshThreadAlive Do
    CB_YIELD;

end;

Procedure MouseMoveTo(ToX, ToY: Integer);
var
  p: TPoint;
Begin

  // Convert to native coords from virtual

  p := Main.ClientToScreen(Point(0, 0));
  ToX := Round(p.x + (ToX * ScaleMouseX));
  ToY := Round(p.y + (Toy * ScaleMouseY));
  SetCursorPos(ToX, ToY);

End;

Procedure SetWindowCaption;
Var
  s: aString;
Begin
  if WCAPTION <> '' Then
    s := WCAPTION
  Else
    s := aString(ChangeFileExt(ExtractFilename(ParamStr(0)), ''));
  Main.Caption := String(s);
End;

procedure TMain.FormCreate(Sender: TObject);
Var
  Path: Array [0..MAX_PATH] of Char;
  idx: Integer;
  p: TPoint;
  s, dir: String;
begin

  DragAcceptFiles(Handle, True);

  INSTARTUP := True;

  DisplaySection.Enter;

  REALSCREENWIDTH := Round(Screen.Width);
  REALSCREENHEIGHT := Round(Screen.Height);
  OrgWidth := REALSCREENWIDTH;
  OrgHeight := REALSCREENHEIGHT;

  MOUSEVISIBLE := FALSE;

  EXENAME := ParamStr(0);
  PayLoad := TPayLoad.Create(EXENAME);
  PAYLOADPRESENT := PayLoad.HasPayLoad;

  If Not PAYLOADPRESENT Then Begin
    PCOUNT := -1;
    PARAMS := TStringList.Create;
    For Idx := 0 To ParamCount Do Begin
      s := ParamStr(Idx);
      if Copy(s, 1, 1) <> '-' then Begin
        if FileExists(s) then Begin
          PARAMS.Add(aString(s));
          Inc(PCOUNT);
        End;
      End Else Begin
        PARAMS.Add(aString(s));
        Inc(PCOUNT);
      End;
    End;

    dir := GetCurrentDir;
    If (PCOUNT = 0) And FileExists(dir + '\autorun') Then Begin
      PCOUNT := 1;
      PARAMS.Add(aString(dir)+'\autorun');
    End;

  End;

  Cursor := CrNone;

  SetPriorityClass(GetCurrentProcess, $8000{ABOVE_NORMAL_PRIORITY_CLASS});

  QueryPerformanceFrequency(TimerFreq);
  QueryPerformanceCounter(BaseTime);

  InitTime := Round(GetTicks);

  If Not PAYLOADPRESENT Then Begin

    BUILDSTR := aString(Sto_GetFmtFileVersion('', '%d.%d.%d.%d'));
    If IsDebuggerPresent Then UpdateLinuxBuildStr;
    {$IFDEF OPENGL}
      BUILDSTR := BUILDSTR + '-GL';
    {$ENDIF}
    {$IFDEF WIN64}
      BUILDSTR := BUILDSTR + ' x64';
    {$ENDIF}
    {$IFDEF DEBUG}
      BUILDSTR := BUILDSTR + ' [Debug';
    {$ENDIF}
    {$IFDEF DELPHI}
    if (DebugHook <> 0) or IsDebuggerPresent then BUILDSTR := BUILDSTR + ' IDE';
    {$ENDIF}
    {$IFDEF DEBUG}
      BUILDSTR := BUILDSTR + ']';
    {$ENDIF}

    // Set the HOME folder - if we're loading a parameter file, extract the
    // directory and set that as HOMEFOLDER

    If PCOUNT <= 0 Then Begin

      Main.Caption := 'SpecBAS for Windows v'+String(BuildStr);
      SHGetFolderPath(0,$0028,0,SHGFP_TYPE_CURRENT,@path[0]);
      HOMEFOLDER := Path + aString('\specbas');

    End Else Begin

      Main.Caption := ExtractFileName(String(PARAMS[1]));
      HOMEFOLDER := aString(ExtractFileDir(String(PARAMS[1])));
      If HOMEFOLDER = '' Then
        HOMEFOLDER := aString(GetCurrentDir);

    End;

  End Else Begin

    SetCurrentDir(ExtractFilePath(EXENAME));
    HOMEFOLDER := aString(GetCurrentDir);

  End;

  If Not DirectoryExists(String(HOMEFOLDER)) Then
    CreateDir(String(HOMEFOLDER));
  If Not DirectoryExists(String(HOMEFOLDER) + '\temp') Then
    CreateDir(String(HOMEFOLDER) + '\temp');
  TEMPDIR := HOMEFOLDER + '\temp\';

  SetCurrentDir(String(HOMEFOLDER));
  HOMEFOLDER := Lower(HOMEFOLDER);
  If HOMEFOLDER[Length(HOMEFOLDER)] <> '\' Then
    HOMEFOLDER := HOMEFOLDER + '\';

  AUTOSAVE := Not PAYLOADPRESENT;

  ScrWidth := 800;
  ScrHeight := 480;
  SCALEWIDTH := 800;
  SCALEHEIGHT := 480;
  MENUBLOCK := False;

  Application.OnActivate := OnActivate;
  Application.OnDeactivate := OnDeactivate;

  // Initialise callbacks

  CB_GetKeyLockState := GetKeyState;
  CB_Refresh_Display := Refresh_Display;
  CB_Quit := MainForm.Quit;
  CB_SetScreenRes := SetScreen;
  CB_Test_Resolution := TestScreenResolution;
  CB_GetTicks := GetTicks;
  CB_GetTimeFreq := GetTimerFrequency;
  CB_Yield := YieldProc;
  CB_Load_Image := LoadImage;
  CB_Save_Image := SaveImage;
  CB_Free_Image := FreeImageResource;
  CB_Messages := MsgProc;
  CB_MouseMove := MouseMoveTo;
  CB_SETWINDOWCAPTION := SetWindowCaption;

  SP_InitialGFXSetup(ScrWidth, ScrHeight, False);
  SetBounds((REALSCREENWIDTH - Width) Div 2, (REALSCREENHEIGHT - Height) Div 2, Width, Height);
  RefreshTimer := TRefreshThread.Create(False);

  WINLEFT := Left;
  WINTOP := Top;

  // Launch the interpreter

  SP_CLS(CPAPER);
  EDITLINE := '';
  CURSORPOS := 0;
  CURSORCHAR := 32;
  SYSTEMSTATE := SS_IDLE;

  SoundEnabled := LoadLibrary(bassdll) <> 0;
  SP_Init_Sound;

  CORECOUNT := System.CPUCount;
  Setpriorityclass(GetCurrentProcess(), HIGH_PRIORITY_CLASS);
  SetProcessAffinityMask(GetCurrentProcess, $F);

  BASThread := TSpecBAS_Thread.Create(True);
  {$IFNDEF FPC}
  Application.OnMessage := OnAppMessage;
  {$ENDIF}
  SetThreadAffinityMask(GetCurrentThread(), 1);
  SetThreadAffinityMask(BASThread.ThreadID, 2);
  SetThreadAffinityMask(RefreshTimer.ThreadID, 4);

  DisplaySection.Leave;

  BASThread.Start;

  GetCursorPos(p);
  p := Main.ScreenToClient(p);
  MouseInForm := PtInRect(Main.ClientRect, p);

  Activate;

end;

procedure TMain.FormDeactivate(Sender: TObject);
begin
  FormActivated := False;
  SP_ClearAllKeys;
end;

Procedure TMain.FormDestroy(Sender: TObject);
Var
  Error: TSP_ErrorCode;
begin

  Quitting := True;

  If SoundEnabled Then
    BASS_Free;

  If PAYLOADPRESENT or (PCOUNT <> 0) Then Begin
    SP_RmDirUnSafe('/temp', Error);
    SP_RmDir('/s', Error);
    SP_RmDir('/fonts', Error);
    SP_RmDir('/keyboards', Error);
    SP_RmDir('/include', Error);
  End;

  DisplaySection.Enter;

  Bitmap.Free;
  SetScreenResolution(OrgWidth, OrgHeight, False);

  DisplaySection.Leave;

end;

Function TMain.GetCharFromVirtualKey(Var Key: Word): astring;
var
  keyboardState: TKeyboardState;
  asciiResult: Integer;
begin

  GetKeyboardState(keyboardState);

  // Filter out the CTRL key - it'll be picked up later.

  If KeyboardState[18] < 128 Then
    KeyBoardState[17] := 0;

  SetLength(Result, 2);
  asciiResult := ToAscii(key, MapVirtualKey(key, 0), KeyboardState, @Result[1], 0);
  case asciiResult of
    0: If Key < 32 Then Result := aChar(Key) Else Result := '';
    1: SetLength(Result, 1);
    2: Result := '';
    else
      Result := '';
  end;

  If Result <> '' Then Begin
    Case Ord(Result[1]) of
      194, 163: Result := #$60;
      96:  Result := #$7F;
    End;
  End;

end;

procedure TMain.CMDialogKey(var msg: TCMDialogKey);
begin
  if msg.Charcode <> VK_TAB then
    inherited;
end;

procedure TMain.FormKeyPress(Sender: TObject; var Key: Char);
Begin
  Key := #32;
End;

procedure TMain.WMMenuChar(var MessageRec: TWMMenuChar);
Begin
  if IgnoreNextMenuChar Then Begin
    MessageRec.Result := MakeLong(0, 1);
    IgnoreNextMenuChar := False;
  End;
End;

procedure TMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
Var
  k: Word;
  aStr: aString;
  kInfo: SP_KeyInfo;
begin

  aStr := aString(GetCharFromVirtualKey(Key));
  If (aStr = '') or (aStr[1] < ' ') Then aStr := #0;

  kInfo.CanRepeat := True;
  kInfo.IsKey := True;
  kInfo.KeyChar := aStr[1];
  kInfo.KeyCode := Key And $7F;
  kInfo.NextFrameTime := FRAMES;

  If ControlsAreInUse Then Begin
    DisplaySection.Enter;
    If ControlKeyEvent(kInfo.KeyChar, kInfo.KeyCode, True, kInfo.IsKey) Then Begin
      DisplaySection.Leave;
      Exit;
    End Else
      DisplaySection.Leave;
  End;

  If Key = $12 Then Begin // ALT went down

    AltDown := True;
    AltChars := '';

  End Else Begin

    If AltDown then Begin

      If Key in [K_NUMPAD0..K_NUMPAD9, K_0..K_9] Then Begin

        if Key in [K_NUMPAD0..K_NUMPAD9] Then
          k := Key - K_NUMPAD0
        else
          k := Key - K_0;

        IgnoreNextMenuChar := True;
        AltChars := AltChars + IntToString(k);
        If Length(AltChars) = 3 Then Begin
          kInfo.KeyCode := StringToInt(AltChars);
          kInfo.keyChar := aChar(kInfo.KeyCode);
          kInfo.CanRepeat := False;
          kInfo.IsKey := False;
          ALtChars := '';
        End Else Begin
          Key := 0;
          Exit;
        End;

      End;

    End;

  End;

  SP_AddKey(kInfo);

  Key := 0;

end;

Procedure TMain.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin

  KEYSTATE[Key] := 0;
  ControlKeyEvent(#0, Key And $7F, False, True);
  SP_RemoveKey(Key And $7F);

  If AltDown And (Key = $12) Then Begin
    AltDown := False;
    SP_RemoveKey(StringToInt(AltChars));
    AltChars := '';
  End;

end;

procedure TMain.FormMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
Var
  p: TPoint;
  Win: Pointer;
  X, Y, Btn, ID: Integer;
begin

  X := MOUSEX;
  Y := MOUSEY;
  Btn := Integer(ssLeft in Shift) + (2 * Integer(ssRight in Shift)) + (4 * Integer(ssMiddle in Shift));

  Handled := False;
  DisplaySection.Enter;

  If Assigned(CaptureControl) Then Begin
    p := CaptureControl.ScreenToClient(Point(x, y));
    CaptureControl.MouseMove(p.x, p.y, Btn);
  End Else Begin
    Win := WindowAtPoint(X, Y, ID);
    If Assigned(Win) Then Begin
      Win := ControlAtPoint(Win, X, Y);
      If Assigned(Win) Then Begin
        pSP_BaseComponent(Win)^.MouseWheel(X, Y, Btn, 1);
        Handled := True;
      End;
    End;
  End;

  DisplaySection.Leave;

  If Not Handled Then Begin
    M_WHEELDNFLAG := True;
    Inc(MOUSEWHEEL);
  End;

end;

procedure TMain.FormMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
Var
  p: TPoint;
  Win: Pointer;
  X, Y, Btn, ID: Integer;
begin

  X := MOUSEX;
  Y := MOUSEY;
  Btn := Integer(ssLeft in Shift) + (2 * Integer(ssRight in Shift)) + (4 * Integer(ssMiddle in Shift));

  Handled := False;
  DisplaySection.Enter;

  If Assigned(CaptureControl) Then Begin
    p := CaptureControl.ScreenToClient(Point(x, y));
    CaptureControl.MouseMove(p.x, p.y, Btn);
  End Else Begin
    Win := WindowAtPoint(X, Y, ID);
    If Assigned(Win) Then Begin
      Win := ControlAtPoint(Win, X, Y);
      If Assigned(Win) Then Begin
        pSP_BaseComponent(Win)^.MouseWheel(X, Y, Btn, -1);
        Handled := True;
      End;
    End;
  End;

  DisplaySection.Leave;

  If Not Handled Then Begin
    M_WHEELUPFLAG := True;
    Dec(MouseWheel);
  End;

end;

procedure TMain.FormPaint(Sender: TObject);
{$IFNDEF OPENGL}
Var
  H1, H2: HWnd;
{$ENDIF}
begin

  {$IFNDEF OPENGL}
  If DPtrBackup <> Nil Then Begin
    H1 := Canvas.Handle;
    H2 := Bitmap.Canvas.Handle;
    With Canvas.ClipRect Do
      StretchBlt(H1, Left, Top, WIDTH, HEIGHT, H2, Left, Top, DISPLAYWIDTH, DISPLAYHEIGHT, SrcCopy);
  End;
  {$ENDIF}

end;

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
    dwFlags:= PFD_DRAW_TO_WINDOW
      or PFD_SUPPORT_OPENGL
      or PFD_DOUBLEBUFFER;
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
    cDepthBits:= 16;
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

  GLInitDone := True;

End;

{$ENDIF}

procedure TMain.FormResize(Sender: TObject);
{$IFNDEF OPENGL}
Var
    BmInfo: tagBITMAPINFO;
{$ENDIF}
begin


  If Not (Quitting) Then Begin

    {$IFDEF OPENGL}

      If WindowState = wsMinimized Then Begin
        Minimised := True;
        Exit;
      End Else
        If Minimised Then Begin
          Minimised := False;
          GLInitDone := False;
          SP_InvalidateWholeDisplay;
          SP_NeedDisplayUpdate := True;
          Exit;
        End;

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

    {$ELSE}

      If Bitmap <> Nil Then Begin
        DeleteObject(Bitmap.Handle);
        Bitmap.Free;
        Bitmap := Nil;
      End;

      BmInfo.bmiHeader.biSize := SizeOf(tagBITMAPINFOHEADER);
      BmInfo.bmiHeader.biWidth := ClientWidth;
      BmInfo.bmiHeader.biHeight := -ClientHeight;
      BmInfo.bmiHeader.biPlanes := 1;
      BmInfo.bmiHeader.biBitCount := 32;
      BmInfo.bmiHeader.biCompression := BI_RGB;

      Bitmap := TBitmap.Create();
      Bitmap.Width := ClientWidth;
      Bitmap.Height := ClientHeight;
      Bitmap.HandleType := bmDIB;
      Bitmap.Handle := CreateDIBSection(Main.Canvas.Handle, BmInfo, DIB_RGB_COLORS, Bits, 0, 0);

      DISPLAYSTRIDE := ClientWidth * (BmInfo.bmiHeader.biBitCount Div 8);
      DISPLAYPOINTER := Bits;

    {$ENDIF}

  End;

  DPtrBackup := DISPLAYPOINTER;

end;

procedure TMain.FormShow(Sender: TObject);
Begin

  SetFocus;

end;

Procedure Quit;
Begin

  Quitting := True;
  SendMessage(Main.Handle, WM_CLOSE, 0, 0);
  PARAMS.Free;

End;

Procedure GetKeyState;
Begin

  CAPSLOCK := Windows.GetKeyState(VK_CAPITAL) and 1;
  NUMLOCK := WIndows.GetKeyState(VK_NUMLOCK) and 1;

End;

Procedure YieldProc; inline;
Begin

  TThread.Sleep(1);
  LASTINKEYFRAME := FRAMES;

End;

Procedure MsgProc; inline;
Begin

  Application.ProcessMessages;

End;

function Sto_GetFmtFileVersion(const FileName: String = ''; const Fmt: String = '%d.%d'): String;
var
  sFileName: String;
  iBufferSize: DWORD;
  iDummy: DWORD;
  pBuffer: Pointer;
  pFileInfo: Pointer;
  iVer: array[1..4] of Word;
begin
  // set default value
  Result := '';
  // get filename of exe/dll if no filename is specified
  sFileName := Trim(FileName);
  if (sFileName = '') then
    sFileName := GetModuleName(HInstance);
  // get size of version info (0 if no version info exists)
  iBufferSize := GetFileVersionInfoSize(PChar(sFileName), iDummy);
  if (iBufferSize > 0) then
  begin
    GetMem(pBuffer, iBufferSize);
    try
    // get fixed file info (language independent)
    GetFileVersionInfo(PChar(sFileName), 0, iBufferSize, pBuffer);
    VerQueryValue(pBuffer, '\', pFileInfo, iDummy);
    // read version blocks
    iVer[1] := HiWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionMS);
    iVer[2] := LoWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionMS);
    iVer[3] := HiWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionLS);
    iVer[4] := LoWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionLS);
    finally
      FreeMem(pBuffer);
    end;
    // format result string
    Result := IntToStr(iVer[3])+ '.' + IntToStr(iVer[4]);
  end;
end;

Procedure LoadImage(Filename: aString; Var Error: TSP_ErrorCode);
Var
  Bmp: TPicture;
  NewBmp: TBitmap;
  Idx, y: Integer;
  MaxPal: TMaxLogPalette;
  r, g, b: Byte;
  DPtr: pByte;
  Ext, FirstBytes, OldFilename, tStr: aString;
  FS: TFileStream;
  RGBQ: Array[0..255] of RGBQUAD;

{$IFDEF FPC}
Type
  TPNGImage = TPortableNetworkGraphic;
{$ENDIF}

Begin

  // Loads (using arch-specific routines - GraphicEx under Win32, SDL_Image under linux) an image,
  // and fills the supplied pointer and w/h/s vars with info about the image. Use the "FreeImageResource"
  // proc when we're done with the image.

  // FUCKING UGLY HACK ALERT!

  OldFilename := '';
  If FileExists(String(Filename)) Then Begin
    Ext := Lower(aString(ExtractFileExt(String(Filename))));
    FS := TFileStream.Create(String(FileName), fmOpenRead or fmShareDenyNone);
    SetLength(FirstBytes, 8);
    FS.Read(FirstBytes[1], 8);
    FS.Free;
    Ext := '';
    if Copy(FirstBytes, 1, 2) = 'BM' then Ext := '.bmp';
    if FirstBytes = #137'PNG'#13#10#26#10 then Ext := '.png';
    if Copy(FirstBytes, 1, 3) =  'GIF' then Ext := '.gif';
    if Copy(FirstBytes, 1, 2) = #$FF#$D8 then Ext := '.jpg';
    OldFilename := Filename;
    tStr := aString(ExtractFilename(String(Filename)));
    tStr := Copy(tStr, 1, Length(tStr) - Length(Ext));
    Filename := aString(ExtractFilePath(String(Filename))) + tStr + Ext;
    RenameFile(String(OldFilename), String(Filename));
  End;

  ERRStr := Filename;
  If FileExists(String(Filename)) Then Begin
    Bmp := TPicture.Create;
    Try
      Bmp.LoadFromFile(String(Filename));
      Sleep(20);
    Except
      On E: Exception Do Begin
        Bmp.Free;
        Error.Code := SP_ERR_UNSUPPORTED_IMAGE_FORMAT;
      End;
    End;
    If Error.Code = SP_ERR_OK Then Begin
      If Bmp.Graphic Is TPNGImage Then Begin
        {$IFNDEF FPC}
        If ((Bmp.Graphic as TPNGImage).Header.ColorType <> COLOR_PALETTE) And ((Bmp.Graphic as TPNGImage).Header.ColorType <> COLOR_GRAYSCALE) Then
        {$ELSE}
        If ((Bmp.Graphic as TPNGImage).PixelFormat <> pf8Bit) Then
        {$ENDIF}
          Error.Code := SP_ERR_INVALID_IMAGE_FORMAT

      End Else
        If Bmp.Graphic is TBitmap Then Begin
          If (Bmp.Graphic As TBitmap).PixelFormat <> pf8Bit Then
            Error.Code := SP_ERR_INVALID_IMAGE_FORMAT;
        End;
      If Error.Code = SP_ERR_OK Then Begin
        SetLength(ImgResource, Bmp.Graphic.Width * Bmp.Graphic.Height);
        NewBmp := TBitmap.Create;
        NewBmp.Width := Bmp.Graphic.Width;
        NewBmp.Height := Bmp.Graphic.Height;
        NewBmp.PixelFormat := pf8Bit;
        GetPaletteEntries(Bmp.Graphic.Palette, 0, 256, MaxPal.palPalEntry);
        For Idx := 0 To 255 Do Begin
          r := MaxPal.palPalEntry[Idx].peRed;
          g := MaxPal.palPalEntry[Idx].peGreen;
          b := MaxPal.palPalEntry[Idx].peBlue;
          ImgPalette[Idx].R := r; RGBQ[Idx].rgbRed := r;
          ImgPalette[Idx].G := g; RGBQ[Idx].rgbGreen := g;
          ImgPalette[Idx].B := b; RGBQ[Idx].rgbBlue := b;
        End;
        SetDIBColorTable(NewBmp.Canvas.Handle, 0, 256, RGBQ);
        NewBmp.Canvas.Draw(0, 0, Bmp.Graphic);
        DPtr := @ImgResource[0];
        ImgPtr := DPtr;
        For y := 0 To NewBmp.Height -1 Do Begin
          CopyMem(DPtr, NewBmp.Scanline[y], NewBmp.Width);
          Inc(DPtr, NewBmp.Width);
        End;
        ImgStride := NewBmp.Width;
        ImgHeight := NewBmp.Height;
        ImgWidth := NewBmp.Width;
        NewBmp.Free;
      End;
      Bmp.Free;
    End Else
      Error.Code := SP_ERR_FILE_MISSING;
  End Else
    Error.Code := SP_ERR_FILE_MISSING;

  If OldFilename <> '' Then
    RenameFile(String(Filename), String(OldFileName));

End;

Procedure SaveImage(Filename: aString; w, h: Integer; Pixels, Palette: pByte);
{$IFDEF FPC}
Type
  TPNGImage = TPortableNetworkGraphic;
{$ENDIF}
Var
  Ext: aString;
  i: Integer;
  Bmp: TBitmap;
  Gif: TGIFImage;
  Png: TPNGImage;
  Pal: Array[0..255] of PaletteEntry;
Begin

  For i := 0 To 255 Do Begin
  Pal[i].peRed := Palette^;
  Inc(Palette);
  Pal[i].peGreen := Palette^;
  Inc(Palette);
  Pal[i].peBlue := Palette^;
  Pal[i].peFlags := $FF;
  Inc(Palette, 2);
  End;

  Bmp := TBitmap.Create;
  Bmp.PixelFormat := pf8Bit;
  Bmp.Width := w;
  Bmp.Height := h;
  SetDIBColorTable(Bmp.Canvas.Handle, 0, 256, Pal);
  For i := 0 to h -1 Do Begin
    CopyMem(Bmp.ScanLine[i], Pixels, w);
    Inc(Pixels, w);
  End;

  Ext := Lower(aString(ExtractFileExt(String(Filename))));
  If Ext = '.bmp' Then Begin
    Bmp.SaveToFile(String(Filename));
  End Else
    If Ext = '.png' Then Begin
      Png := TPNGImage.Create;
      Png.Assign(Bmp);
      Png.SaveToFile(String(Filename));
      Png.Free;
    End Else
      If Ext = '.gif' Then Begin
        Gif := TGIFImage.Create;
        Gif.Assign(Bmp);
        Gif.SaveToFile(String(Filename));
        Gif.Free;
      End;

  Bmp.Free;

End;

Procedure FreeImageResource;
Begin

  // Removes an image from memory after loading.

  SetLength(IMGResource, 0);

End;

Procedure UpdateLinuxBuildStr;
{Var
  Str: TStringList;
  Idx: Integer;}
Begin
{
  If FileExists('Linux\specbas.pas') Then Begin

    Str := TStringList.Create;
    Str.LoadFromFile('linux\specbas.pas');
    For Idx := 0 To Str.Count -1 Do Begin
      If Pos('  BUILDSTR := '#39, Str[Idx]) > 0 Then
        If Pos('SDL', Str[Idx]) = 0 Then
          Str[Idx] := '  BUILDSTR := '#39+BuildStr+#39+';'
        Else
          Str[Idx] := '  BUILDSTR := '#39+BuildStr+'-SDL'+#39+';';
    End;

    Str.SaveToFile('linux\specbas.pas');
    Str.Free;

  End;
}
End;

procedure TMain.DropFiles(var msg: TMessage);
var
  i, count, j: integer;
  dropFileName: array [0..511] of Char;
  MAXFILENAME: integer;
  sl: TStringlist;
  paste, s: aString;
begin
  MAXFILENAME := 511;
  count := DragQueryFile(msg.WParam, $FFFFFFFF, dropFileName, MAXFILENAME);
  for i := 0 to count - 1 do
  begin
    DragQueryFile(msg.WParam, i, dropFileName, MAXFILENAME);
    s := '';
    j := 0;
    While (j < 512) and (dropFileName[j] > #0) do Begin
      s := s + aChar(dropFilename[j]);
      inc(j);
    end;
    sl := TStringlist.Create;
    sl.LoadFromHost(String(s));
    Paste := '';
    If sl.Count > 0 Then Begin
      if sl[0] = 'ZXASCII' Then Begin
        for j := 0 To sl.Count -1 Do Begin
          s := aString(sl[j]);
          If (Copy(s, 1, 7) <> 'ZXASCII') and (Copy(s, 1, 4) <> 'AUTO') and (Copy(s, 1, 4) <> 'PROG') and (Copy(s, 1, 7) <> 'CHANGED') Then
            paste := paste + s + #13#10;
        End;
      End;
      Clipboard.AsText := String(paste);
      SP_SwitchFocus(FPWindowID);
      SP_PasteSelection;
    End;
    sl.Free;
  end;
  DragFinish(msg.WParam);
end;

Initialization

  {$IFDEF OPENGL}
  RC := 0;
  {$ENDIF}

end.
