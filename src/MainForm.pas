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

{$INCLUDE SpecBAS.inc}
{$DEFINE OPENGL}

interface

uses
  SHFolder, Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Math,
  Dialogs, SP_SysVars, SP_Graphics, SP_Graphics32, SP_BankManager, SP_Util, SP_Main, SP_FileIO,
  ExtCtrls, SP_Input, MMSystem, SP_Errors, SP_Sound, Bass, SP_Tokenise, SP_Menu, PNGImage,
  GIFImg{$IFDEF OPENGL}, dglOpenGL{$ENDIF}, SP_Components, SP_BaseComponentUnit;

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
  private
    { Private declarations }
    Minimised: Boolean;
    procedure OnAppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure CMDialogKey( Var msg: TCMDialogKey ); message CM_DIALOGKEY;
    Procedure OnResizeMain(Var Msg: TMessage); Message WM_RESIZEMAIN;
  public
    { Public declarations }
    Function GetCharFromVirtualKey(Var Key: Word): astring;
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
  Function  GetTicks: LongWord;
  Procedure Quit;
  function  Sto_GetFmtFileVersion(const FileName: String = ''; const Fmt: String = '%d.%d'): String;
  Procedure LoadImage(Filename: aString; Var Error: TSP_ErrorCode);
  Procedure SaveImage(Filename: aString; w, h: Integer; Pixels, Palette: pByte);
  Procedure FreeImageResource;
  Procedure UpdateLinuxBuildStr;

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
  ThreadAlive: Boolean = False;
  lastt, ft: Longword;
  TimerFreq, BaseTime: Int64;
  Bits: Pointer;
  Bitmap: TBitmap = Nil;
  LastMouseX, LastMouseY: Integer;
  {$IFDEF OPENGL}
    GLInitDone: Boolean;
    PixArray, DispArray: Array of Byte;
    RC: HGLRC;
    DC: hDc;
  {$ENDIF}
  DoScale: Boolean = False;
  ScaleFactor: Integer = 1;
  ScaleMouseX, ScaleMouseY: aFloat;
  ScaledWidth, ScaledHeight: Integer;
  MouseInForm: Boolean;

{$IFDEF OPENGL}
Const

  GL_BGRA = $80E1;
{$ENDIF}


implementation

Uses SP_FPEditor;

{$R *.dfm}

Procedure TMain.OnResizeMain(Var Msg: TMessage);
Var
  l, t, w, h, cw, ch: Integer;
Begin

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

End;

Procedure TRefreshThread.Execute;
Var
  LastTime, CurTime, StartTime, LastFrames: LongWord;
  p: TPoint;
Begin

  NameThreadForDebugging('Refresh Thread');

  While Not SP_Interpreter_Ready Do CB_YIELD;

  Priority := tpNormal;
  StartTime := CB_GETTICKS;
  LastFrames := 0;

  While Not QUITMSG Do Begin

    FRAMES := Round((CB_GETTICKS - StartTime)/FRAME_MS);
    If FRAMES <> LastFrames Then Begin
      LastFrames := FRAMES;
      If SP_FrameUpdate Then Begin
        If DisplaySection.TryEnter Then Begin
          If UpdateDisplay Then Begin
            CB_Refresh_Display;
            SP_NeedDisplayUpdate := False;
          End;
          DisplaySection.Leave;
        End;
        UPDATENOW := False;
        CauseUpdate := False;
      End;
    End Else
      TThread.Sleep(1);

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
        MOUSEVISIBLE := USERMOUSEVISIBLE;
        MouseInForm := True;
        SP_InvalidateWholeDisplay;
        SP_NeedDisplayUpdate := True;
      End;
    End;

  End;

  Terminate;

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
    SP_RestoreMouseRegion;
    If (Not SCREENLOCK) or UPDATENOW Then Begin
      If SCMAXX >= SCMINX Then Begin
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
        UPDATENOW := False;
      End;
    End;
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
  x, y, w, h: Integer;
Begin

  {$IFDEF OPENGL}

    If Not GLInitDone Then Begin
      InitGL;
      SetScaling(DISPLAYWIDTH, DISPLAYHEIGHT, Main.ClientWidth, Main.ClientHeight);
      Main.FormResize(Main);
    End;

    DC := wglGetCurrentDC;

    glDisable(gl_MULTISAMPLE_ARB);
    glClear(GL_COLOR_BUFFER_BIT);
    glLoadIdentity;
    glUseProgramObjectARB(0);

    If DoScale Then Begin
      ScaleBuffers(GLX, GLX + GLW -1, GLY, GLY + GLH -1);
      x := GLX * ScaleFactor;
      y := GLY * ScaleFactor;
      w := GLW * ScaleFactor;
      h := GLH * ScaleFactor;
      glPixelStorei(GL_UNPACK_ROW_LENGTH, ScaledWidth);
      glTexSubImage2D(GL_TEXTURE_2D, 0, X, Y, W, H, GL_BGRA, GL_UNSIGNED_BYTE, @DispArray[X * 4 + ScaledWidth * 4 * Y]);
      If (GLMW > 0) And (GLMH > 0) And MOUSEMOVED Then Begin
        ScaleBuffers(GLMX, GLMX + GLMW -1, GLMY, GLMH + GLMY -1);
        x := GLMX * ScaleFactor;
        y := GLMY * ScaleFactor;
        w := GLMW * ScaleFactor;
        h := GLMH * ScaleFactor;
        glTexSubImage2D(GL_TEXTURE_2D, 0, X, Y, W, H, GL_BGRA, GL_UNSIGNED_BYTE, @DispArray[X * 4 + ScaledWidth * 4 * Y]);
      End;
    End Else Begin
      glPixelStorei(GL_UNPACK_ROW_LENGTH, DISPLAYWIDTH);
      glTexSubImage2D(GL_TEXTURE_2D, 0, GLX, GLY, GLW, GLH, GL_BGRA, GL_UNSIGNED_BYTE, @PixArray[GLX * 4 + DISPLAYWIDTH * 4 * GLY]);
      If (GLMW > 0) And (GLMH > 0) And MOUSEMOVED Then
        glTexSubImage2D(GL_TEXTURE_2D, 0, GLMX, GLMY, GLMW, GLMH, GL_BGRA, GL_UNSIGNED_BYTE, @PixArray[GLMX * 4 + DISPLAYWIDTH * 4 * GLMY]);
    End;

    glBegin(GL_QUADS);
    glTexCoord2D(0, 0); glVertex2D(0, 0);
    glTexCoord2D(1, 0); glVertex2D(ScaleWidth, 0);
    glTexCoord2D(1, 1); glVertex2D(ScaleWidth, ScaleHeight);
    glTexCoord2D(0, 1); glVertex2D(0, ScaleHeight);
    glEnd;

    SwapBuffers(DC);

  {$ELSE}
    InvalidateRect(Main.Handle, iRect, False);
    Main.Repaint;
  {$ENDIF}

End;

Function GetTicks: LongWord;
Var
  t: Int64;
Begin
  QueryPerformanceCounter(t);
  Result := Round(t/TimerFreq * 1000);
End;

Procedure SetScaling(Width, Height, sWidth, sHeight: Integer);
Begin

  {$IFDEF OPENGL}

  SCALEWIDTH := sWidth;
  SCALEHEIGHT := sHeight;
  If INTSCALING Then Begin
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
  l, t, w, h: NativeUInt;
Begin

  Result := 0;

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

  {$IFDEF OPENGL}
  GLInitDone := False; // trigger the OpenGL system to recreate itself with the new window/screen size
  {$ENDIF}
  SetScreenResolution(sWidth, sHeight, FullScreen);
  w := sWidth;
  h := sHeight;
  If FullScreen Then Begin
    l := 0;
    t := 0;
  End Else Begin
    If INSTARTUP Then Begin
      l := (Screen.Width - w) Div 2;
      t := (Screen.Height - h) Div 2;
    End Else Begin
      l := WINLEFT; //(Screen.Width - sWidth) Div 2;
      t := WINTOP; //(Screen.Height - sHeight) Div 2;
    End;
  End;

  SendMessage(Main.Handle, WM_RESIZEMAIN, l + (t shl 16), w + (h Shl 16));

End;

function TestScreenResolution(Width, Height: Integer; FullScreen: Boolean): Boolean;
var
  DeviceMode: TDeviceMode;
  hMod, wMod: Integer;
begin

  If FullScreen Then Begin

    with DeviceMode do begin
      dmSize := SizeOf(TDeviceMode);
      dmPelsWidth := Width;
      dmPelsHeight := Height;
      dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;
    end;
    Result := ChangeDisplaySettings(DeviceMode, CDS_TEST) = DISP_CHANGE_SUCCESSFUL;

  End Else Begin

    hMod := Main.Height - Main.ClientHeight;
    wMod := Main.Width - Main.ClientWidth;
    Result := (Width + wMod <= Screen.Width) and (Height + hMod <= Screen.Height);

  End;
end;

function SetScreenResolution(Width, Height: Integer; FullScreen: Boolean): Boolean;
var
  DeviceMode: TDeviceMode;
  R: TRect;
begin

  If FullScreen Then Begin
    with DeviceMode do begin
      dmSize := SizeOf(TDeviceMode);
      dmPelsWidth := Width;
      dmPelsHeight := Height;
      dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;
    end;
    Result := ChangeDisplaySettings(DeviceMode, 0) = DISP_CHANGE_SUCCESSFUL;
    SetWindowLongPtr(Main.handle, GWL_STYLE, WS_SYSMENU or WS_POPUP or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or WS_VISIBLE);
    Main.BorderStyle := bsNone;
    SPFULLSCREEN := True;
  End Else Begin
    If SPFULLSCREEN Then Begin
      R := Rect(0, 0, Width, Height);
      SetWindowLongPtr(Main.handle, GWL_STYLE, WS_CAPTION or WS_POPUPWINDOW or WS_VISIBLE);
      AdjustWindowRect(R, WS_CAPTION or WS_POPUPWINDOW, FALSE);
      with DeviceMode do begin
        dmSize := SizeOf(TDeviceMode);
        dmPelsWidth := REALSCREENWIDTH;
        dmPelsHeight := REALSCREENHEIGHT;
        dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;
      End;
      ChangeDisplaySettings(DeviceMode, 0);
      SPFULLSCREEN := False;
      Main.BorderStyle := bsSingle;
    End;
    Result := True;
  End;

end;

procedure TMain.OnAppMessage(var Msg: TMsg; var Handled: Boolean);
begin

  case Msg.message of
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

  ThreadAlive := True;
  Priority := tpNormal;
  SP_MainLoop;
  ThreadAlive := False;
  Terminate;

End;

procedure TMain.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Var
  mi: SP_MenuSelection;
  Win: Pointer;
  Btn: Integer;
  p: TPoint;
  Handled: Boolean;
begin

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

  // Now check for controls under the mouse              *** make windowmenu appear when right-clicking if not visible

  Handled := False;
  DisplaySection.Enter;

  If ForceCapture Then Begin
    If CaptureControl.CanFocus Then
      CaptureControl.SetFocus(True);
    p := CaptureControl.ScreenToClient(Point(X, Y));
    SP_BaseComponent(CaptureControl).MouseDown(p.X, p.Y, Btn);
    Handled := True;
  End Else Begin
    Win := WindowAtPoint(X, Y);
    If Assigned(Win) Then Begin
      Win := ControlAtPoint(Win, X, Y);
      If Assigned(Win) Then Begin
        CaptureControl := Win;
        If CaptureControl.CanFocus Then
          CaptureControl.SetFocus(True);
        SP_BaseComponent(CaptureControl).MouseDown(X, Y, Btn);
        Handled := True;
      End Else Begin
        If Assigned(CaptureControl) Then
          SP_BaseComponent(CaptureControl).MouseDown(X, Y, Btn);
        If Assigned(FocusedControl) Then
          FocusedControl.SetFocus(False);
      End;
    End;
  End;

  DisplaySection.Leave;

  // Finally, pass the mouse event to the interpreter

  If Not Handled Then Begin
    MOUSEBTN := Btn;
    M_DOWNFLAG := True;
  End;

end;

procedure TMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
Var
  Win: Pointer;
  p: TPoint;
  LMenu, LItem, Btn, tX, tY: Integer;
  Handled: Boolean;
begin

  If ((X = LastMouseX) And (Y = LastMouseY)) or SIZINGMAIN Then Exit;

  LastMouseX := X;
  LastMouseY := Y;
  {$IFDEF OPENGL}
  X := Round(X / ScaleMouseX);
  Y := Round(Y / ScaleMouseY);
  {$ENDIF}

  Btn := Integer(ssLeft in Shift) + (2 * Integer(ssRight in Shift)) + (4 * Integer(ssMiddle in Shift));
  M_DELTAX := X - MOUSEX;
  M_DELTAY := Y - MOUSEY;
  MOUSEX := X;
  MOUSEY := Y;

  // Ensure the mouse pointer is drawn at the new position

  If MOUSEVISIBLE or (PROGSTATE = SP_PR_STOP) Then Begin
    SP_NeedDisplayUpdate := True;
    If PROGSTATE = SP_PR_STOP Then
      UPDATENOW := True;
  End;

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

      If DisplaySection.TryEnter Then Begin
        Handled := False;

        tX := X; tY := Y;
        Win := WindowAtPoint(tX, tY);
        If Assigned(Win) Then Begin
          Win := ControlAtPoint(Win, tX, tY);
          If MouseControl <> SP_BaseComponent(Win) Then
            If Assigned(MouseControl) Then
              MouseControl.MouseExit;
        End;
        If Assigned(CaptureControl) And CaptureControl.Visible Then Begin
          p := CaptureControl.ScreenToClient(Point(x, y));
          CaptureControl.MouseMove(p.x, p.y, Btn);
        End Else Begin
          If Assigned(Win) Then Begin
            If MouseControl <> SP_BaseComponent(Win) Then Begin
              MouseControl := Win;
              p := MouseControl.ScreenToClient(Point(tX, tY));
              MouseControl.MouseEnter(p.X, p.Y);
            End;
            SP_BaseComponent(Win).MouseMove(tX, tY, Btn);
            Handled := True;
          End Else
            If Assigned(MouseControl) Then
              MouseControl.MouseExit;
        End;

        DisplaySection.Leave;

      End;

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
  Btn: Integer;
  p: TPoint;
  Handled: Boolean;
begin

  ReleaseCapture;

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

    DisplaySection.Enter;

    Handled := False;
    If Assigned(CaptureControl) Then Begin
      p := CaptureControl.ScreenToClient(Point(x, y));
      CaptureControl.MouseUp(p.x, p.y, Btn);
      If Not ForceCapture Then
        CaptureControl := Nil;
      Handled := True;
    End Else Begin
      Win := WindowAtPoint(X, Y);
      If Assigned(Win) Then Begin
        Win := ControlAtPoint(Win, X, Y);
        If Assigned(Win) Then Begin
          SP_BaseComponent(Win).MouseUp(X, Y, Btn);
          Handled := True;
        End;
      End;
    End;

    DisplaySection.Leave;

    // Finally, pass the mouse event to the interpreter

    MOUSEBTN := Btn;
    If Not Handled Then Begin
      M_UPFLAG := True;
    End;

  End;

  MENUBLOCK := (ssRight in Shift);

end;

procedure TMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
Var
  Error: TSP_ErrorCode;
begin

  If Not QUITMSG Then Begin

    Error.Code := SP_ERR_OK;
    DoAutoSave(Error);
    Quitting := True;

  End;

  QUITMSG := True;
  Repeat
    Sleep(1);
  Until Not Drawing;

end;

procedure TMain.FormCreate(Sender: TObject);
Var
  Path: Array [0..MAX_PATH] of Char;
  idx: Integer;
  p: TPoint;
begin

  INSTARTUP := True;
  DisplaySection.Enter;

  OrgWidth := Screen.Width;
  OrgHeight := Screen.Height;

  MOUSEVISIBLE := FALSE;

  PCOUNT := ParamCount;
  PARAMS := TStringList.Create;
  For Idx := 0 To PCOUNT Do
    PARAMS.Add(ParamStr(Idx));

  Cursor := CrNone;

  SetPriorityClass(GetCurrentProcess, $8000{ABOVE_NORMAL_PRIORITY_CLASS});

  QueryPerformanceFrequency(TimerFreq);
  QueryPerformanceCounter(BaseTime);

  InitTime := GetTicks;

  BUILDSTR := aString(Sto_GetFmtFileVersion('', '%d.%d.%d.%d'));
  If IsDebuggerPresent Then UpdateLinuxBuildStr;
  {$IFDEF OPENGL}
    BUILDSTR := BUILDSTR + '-GL';
  {$ENDIF}
  {$IFDEF WIN64}
    BUILDSTR := BUILDSTR + ' x64';
  {$ENDIF}
  {$IFDEF DEBUG}
    BUILDSTR := BUILDSTR + ' [Debug]';
  {$ENDIF}

  // Set the HOME folder - if we're loading a parameter file, extract the
  // directory and set that as HOMEFOLDER

  If ParamCount = 0 Then Begin

    Main.Caption := 'SpecBAS for Windows v'+BuildStr;
    SHGetFolderPath(0,$0028,0,SHGFP_TYPE_CURRENT,@path[0]);
    HOMEFOLDER := Path + aString('\specbas');

  End Else Begin

    Main.Caption := SP_GetProgName(PROGNAME);
    HOMEFOLDER := ExtractFileDir(PARAMS[1]);
    If HOMEFOLDER = '' Then
      HOMEFOLDER := GetCurrentDir;

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

  AUTOSAVE := True;

  ScrWidth := 800;
  ScrHeight := 480;
  SCALEWIDTH := 800;
  SCALEHEIGHT := 480;
  REALSCREENWIDTH := Screen.Width;
  REALSCREENHEIGHT := Screen.Height;
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
  CB_Yield := YieldProc;
  CB_Load_Image := LoadImage;
  CB_Save_Image := SaveImage;
  CB_Free_Image := FreeImageResource;
  CB_Messages := MsgProc;

  SP_InitialGFXSetup(ScrWidth, ScrHeight, False);
  SetBounds((Screen.Width - Width) Div 2, (Screen.Height - Height) Div 2, Width, Height);
  RefreshTimer := TRefreshThread.Create(False);

  WINLEFT := Left;
  WINTOP := Top;

  // Launch the interpreter

  SP_CLS(CPAPER);
  EDITLINE := '';
  CURSORPOS := 0;
  CURSORCHAR := 32;
  SYSTEMSTATE := SS_IDLE;

  SP_Init_Sound;

  SetProcessAffinityMask(GetCurrentProcess, $F);

  BASThread := TSpecBAS_Thread.Create(True);
  Application.OnMessage := OnAppMessage;
  SetThreadAffinityMask(GetCurrentThread(), 1);
  SetThreadAffinityMask(BASThread.ThreadID, 2);
  SetThreadAffinityMask(RefreshTimer.ThreadID, 4);

  BASThread.Resume;

  DisplaySection.Leave;

  GetCursorPos(p);
  p := Main.ScreenToClient(p);
  MouseInForm := PtInRect(Main.ClientRect, p);

  Activate;

  Logging := True;

end;

procedure TMain.FormDestroy(Sender: TObject);
Var
  Error: TSP_ErrorCode;
begin

  Quitting := True;
  BASS_Free;
  If ParamCount <> 0 Then Begin
    SP_RmDirUnSafe('/temp', Error);
    SP_RmDir('/s', Error);
    SP_RmDir('/fonts', Error);
    SP_RmDir('/keyboards', Error);
    SP_RmDir('/include', Error);
  End;

  DisplaySection.Enter;

  Bitmap.Free;
  {$IFDEF OPENGL}
  DeactivateRenderingContext;
  wglDeleteContext(RC);
  ReleaseDC(Handle, DC);
  {$ENDIF}

  SetScreenResolution(OrgWidth, OrgHeight, False);

  DisplaySection.Leave;

end;

Function TMain.GetCharFromVirtualKey(Var Key: Word): astring;
var
  keyboardState: TKeyboardState;
  asciiResult: Integer;
  Idx: Integer;
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

procedure TMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
Var
  aStr: aString;
  Err: TSP_ErrorCode;
  kInfo: SP_KeyInfo;
begin

  aStr := aString(GetCharFromVirtualKey(Key));
  If (aStr = '') or (aStr[1] < ' ') Then aStr := #0;

  kInfo.KeyChar := aStr[1];
  kInfo.KeyCode := Key;
  kInfo.NextFrameTime := FRAMES;

  If ControlsAreInUse Then Begin
    DisplaySection.Enter;
    If Not ControlKeyEvent(kInfo.KeyChar, kInfo.KeyCode, True) Then
      SP_AddKey(kInfo);
    DisplaySection.Leave;
  End Else
    SP_AddKey(kInfo);

  Key := 0;

end;

procedure TMain.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin

  KEYSTATE[Key] := 0;
  If Not ControlKeyEvent(#0, Key, False) Then
    SP_RemoveKey(Key);

end;

procedure TMain.FormMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
Var
  p: TPoint;
  Win: Pointer;
  X, Y, Btn: Integer;
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
    Win := WindowAtPoint(X, Y);
    If Assigned(Win) Then Begin
      Win := ControlAtPoint(Win, X, Y);
      If Assigned(Win) Then Begin
        SP_BaseComponent(Win).MouseWheel(X, Y, Btn, 1);
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
  X, Y, Btn: Integer;
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
    Win := WindowAtPoint(X, Y);
    If Assigned(Win) Then Begin
      Win := ControlAtPoint(Win, X, Y);
      If Assigned(Win) Then Begin
        SP_BaseComponent(Win).MouseWheel(X, Y, Btn, -1);
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
Var
  H1, H2: HWnd;
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
  End;

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

      If GLInitDone Then Begin

        glClearColor(0, 0, 0, 0);
        glClearDepth(1);

        glViewPort(0, 0, ScaleWidth, ScaleHeight);

        glMatrixMode(GL_PROJECTION);
        glLoadIdentity;

        glOrtho(0, ScaleWidth, ScaleHeight, 0, 1, -1);

        glMatrixMode(GL_MODELVIEW);
        glEnable(GL_TEXTURE_2D);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, ScaledWidth, ScaledHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);

        glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

        glEnable(GL_TEXTURE_2D);

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
        If ((Bmp.Graphic as TPNGImage).Header.ColorType <> COLOR_PALETTE) And ((Bmp.Graphic as TPNGImage).Header.ColorType <> COLOR_GRAYSCALE) Then
          Error.Code := SP_ERR_INVALID_IMAGE_FORMAT
      End Else
        If Bmp.Graphic is TBitmap Then Begin
          If (Bmp.Graphic As TBitmap).PixelFormat <> pf8Bit Then
            Error.Code := SP_ERR_INVALID_IMAGE_FORMAT;
        End Else
          If Bmp.Graphic is TGIFImage Then Begin
            // GIFs are always 8bit!
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
    Bmp.SaveToFile(Filename);
  End Else
    If Ext = '.png' Then Begin
      Png := TPNGImage.Create;
      Png.Assign(Bmp);
      Png.SaveToFile(Filename);
      Png.Free;
    End Else
      If Ext = '.gif' Then Begin
        Gif := TGIFImage.Create;
        Gif.Assign(Bmp);
        Gif.SaveToFile(Filename);
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
Var
  Str: TStringList;
  Idx: Integer;
Begin

  If FileExists('Linux\specbas.pas') Then Begin

{    Str := TStringList.Create;
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
}
  End;

End;

Initialization

  {$IFDEF OPENGL}
  RC := 0;
  {$ENDIF}

end.
