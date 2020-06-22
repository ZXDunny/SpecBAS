unit SP_BaseComponentUnit;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}

interface

// SP_BaseComponent - all components descend from this

Uses SysUtils, Types, Math, SyncObjs,
     SP_Util;

Type

SP_BaseComponent = Class;

SP_MouseEvent = Procedure(Mx, My, Button: Integer) of Object;
SP_MouseWheelEvent = Procedure(Mx, My, Button, Delta: Integer) of Object;
SP_KeyEvent = Procedure(Key: Integer; Down: Boolean);
SP_PaintEvent = Procedure of Object;
SP_ResizeEvent = Procedure of Object;
SP_TimerProc = Procedure(evt: Pointer) of Object;
SP_LBSelectEvent = Procedure(Sender: SP_BaseComponent; Index: Integer) of Object;
SP_LBChooseEvent = Procedure(Sender: SP_BaseComponent; Index: Integer; s: aString) of Object;
SP_SortEvent = Function(Val1, Val2: aString): Integer of Object;
SP_TextPrepare = Function(s: aString; c, i: Integer): aString of Object;
SP_EditEvent = Procedure(Sender: SP_BaseComponent; Text: aString) of Object;
SP_ClickEvent = Procedure(Sender: SP_BaseComponent) of Object;
SP_CheckEvent = Procedure Of Object;
SP_AbortEvent = Procedure(Sender: SP_BaseComponent) Of Object;
SP_MenuClickEvent = Procedure(Sender: SP_BaseComponent) Of Object;
SP_ExitEvent = Procedure of Object;
SP_EnterEvent = Procedure(X, Y: Integer) of Object;
SP_VisibleEvent = Procedure of Object;
SP_PopUpEvent = Procedure (Sender: SP_BaseComponent) of Object;
SP_ActivateEvent = Procedure of Object;
SP_DeactivateEvent = Procedure of Object;
SP_FocusEvent = Procedure(Sender: SP_BaseComponent; WillFocus: Boolean) of Object;

SP_ParentType = (spControl, spWindow);
SP_TabPosition = (spTop, spBottom);

SP_Anchor = (aLeft, aTop, aRight, aBottom);
SP_AnchorSet = Set of SP_Anchor;

SP_BaseComponent = Class

  Public

    fPrevFocus: SP_BaseComponent;
    fLeft, fTop, fWidth, fHeight: Integer;
    fAnchors: SP_AnchorSet;
    fAlign: Integer;
    fOnMouseMove,
    fOnMouseDown,
    fOnMouseUp,
    fOnMouseEnter,
    fOnMouseLeave: SP_MouseEvent;
    fOnMouseWheel: SP_MouseWheelEvent;
    fOnPaintBefore,
    fOnPaintAfter: SP_PaintEvent;
    fOnResize: SP_ResizeEvent;
    fOnKeyDown,
    fOnKeyUp: SP_KeyEvent;
    fOnDblClick: SP_MouseEvent;
    fMouseClickPos: TPoint;
    fMouseLastBtn: Integer;
    fMouseClickTime: Integer;
    fChainControl: SP_BaseComponent;
    fCanClick: Boolean;
    fNeedPaint: Boolean;
    fParentWindowID: Integer;
    fParentControl: SP_BaseComponent;
    fParentType: SP_ParentType;
    fNeedsUpdate: Boolean;
    fCanvas, fTempCanvas: Array of Byte;
    fErase: Boolean;
    fBackgroundClr: Byte;
    fFontClr: Byte;
    fErrorClr: Byte;
    fDisabledFontClr: Byte;
    fHighlightClr: Byte;
    fUnfocusedHighlightClr: Byte;
    fComponentList: Array of SP_BaseComponent;
    fNumComponents: Integer;
    fSize: Integer;
    fLockCount: Integer;
    fTransparentClr: Word;
    fValidCanvas: Boolean;
    fWindowID: Integer;
    fSetLeft, fSetTop, fSetWidth, fSetHeight: Integer;
    fBoundsRect: TRect;
    fEnabled: Boolean;
    fVisible: Boolean;
    fCanFocus: Boolean;
    fFocused: Boolean;
    fOnClick: SP_ClickEvent;
    fOnAbort: SP_AbortEvent;
    fOnEnter: SP_EnterEvent;
    fOnExit:  SP_ExitEvent;
    fOnShow:  SP_VisibleEvent;
    fOnHide:  SP_VisibleEvent;
    fOnFocus: SP_FocusEvent;
    fName: aString;
    fBorder: Boolean;
    fBorderClr: Byte;
    fTransparent: Boolean;
    fMinWidth, fMinHeight, fMaxWidth, fMaxHeight: Integer;
    iFH, iFW: Integer;
    iSX, iSY: aFloat;
    fLastKeyChar: Byte;
    fLastKey: Byte;
    fOverrideScl: Boolean;
    ControlID: Integer;
    Dbl: Boolean;
    fCurFontID: Integer;

    Procedure SetVisible(Value: Boolean);
    Procedure SetTransparent(Value: Boolean);
    Procedure SetWidth(w: Integer);
    Procedure SetHeight(h: Integer);
    Procedure SetLeft(X: Integer);
    Procedure SetTop(Y: Integer);
    Procedure SetEnabled(b: Boolean); Virtual;
    Procedure SetWindowID(id: Integer);
    Procedure SetBorder(b: Boolean);
    Procedure SetMinWidth(w: Integer);
    Procedure SetMinHeight(h: Integer);
    Procedure SetMaxWidth(w: Integer);
    Procedure SetMaxHeight(h: Integer);
    Procedure SetBorderClr(c: Byte); Virtual;
    Procedure SetHighlightClr(c: Byte); Virtual;
    Procedure SetUnfocusedHighlightClr(c: Byte); Virtual;
    Procedure SetBackgroundClr(c: Byte); Virtual;
    Procedure SetFontClr(c: Byte); Virtual;
    Procedure SetErrorClr(c: Byte); Virtual;
    Procedure SetDisabledFontClr(c: Byte); Virtual;
    Procedure SetAlign(newAlign: Integer); Virtual;
    Procedure SetOnFocus(e: SP_FocusEvent); Virtual;
    Procedure SetOverrideScaling(b: Boolean);
    Procedure SetFont(ID: Integer);

    Procedure DoErase;
    Function  DecodeKey(Var Char: Byte): Byte;
    Procedure PerformKeyDown(Var Handled: Boolean); Virtual;
    Procedure PerformKeyUp(Var Handled: Boolean); Virtual;
    Procedure KeyRepeat(p: Pointer);
    Procedure Abort;
    Procedure Draw; Virtual;
    Function  GetWindowDetails: Pointer;
    Function  GetCanvas: NativeUInt;
    Procedure CopyParentCanvas;
    Procedure DoResize(WidthChange, HeightChange: Integer);

    Procedure Paint; Virtual;
    Procedure Render(Dst: pByte; dW, dH: LongWord);
    Procedure BringToFront;
    Procedure SetBounds(x, y, w, h: Integer); Virtual;
    Procedure SetPosition(x, y: Integer); Virtual;
    Procedure DrawLine(x1, y1, x2, y2: Integer; Ink: Byte);
    Procedure SetPixel(x, y: Integer; Ink: Byte); Inline;
    Procedure DrawRect(x1, y1, x2, y2: Integer; Ink: Byte); Overload;
    Procedure DrawRect(r: TRect; Ink: Byte); Overload;
    Procedure FillRect(x1, y1, x2, y2: Integer; Ink: Byte); Overload;
    Procedure FillRect(r: TRect; Ink: Byte); Overload;
    Procedure Print(X, Y: Integer; const Text: aString; Ink, Paper: Integer; ScaleX, ScaleY: aFloat; Italic, Bold: Boolean);
    Procedure DrawBtnFrame(Border, Pressed: Boolean); Overload;
    Procedure DrawBtnFrame(r: TRect; Border, Pressed: Boolean); Overload;
    Function  Components(Idx: Integer): SP_BaseComponent;
    Procedure KeyDown(Key: Integer; Var Handled: Boolean); Virtual;
    Procedure KeyUp(Key: Integer; Var Handled: Boolean); Virtual;
    Procedure MouseDown(X, Y, Btn: Integer); Virtual;
    Procedure MouseUp(X, Y, Btn: Integer); Virtual;
    Procedure MouseMove(X, Y, Btn: Integer); Virtual;
    Procedure MouseWheel(X, Y, Btn, Delta: Integer); Virtual;
    Procedure DoubleClick(X, Y, Btn: Integer); Virtual;
    Function  ClientToScreen(p: TPoint): TPoint;
    Function  ScreenToClient(p: TPoint): TPoint;
    Function  Owner: SP_BaseComponent;
    Procedure SetFocus(b: Boolean); virtual;
    Procedure MouseExit; Virtual;
    Procedure MouseEnter(X, Y: Integer); Virtual;
    Procedure Lock; Virtual;
    Procedure Unlock; Virtual;
    Procedure ChangeFont;
    Procedure SetChainControl(c: SP_BaseComponent); Virtual;
    Function  GetFocused: Boolean;

    Property Align:         Integer             read fAlign         write SetAlign;
    Property Anchors:       SP_AnchorSet        read fAnchors       write fAnchors;
    Property Name:          aString             read fName          write fName;
    Property Count:         Integer             read fNumComponents;
    Property OnMouseMove:   SP_MouseEvent       read fOnMouseMove   write fOnMouseMove;
    Property OnMouseDown:   SP_MouseEvent       read fOnMouseDown   write fOnMouseDown;
    Property OnMouseUp:     SP_MouseEvent       read fOnMouseUp     write fOnMouseUp;
    Property OnMouseEnter:  SP_MouseEvent       read fOnMouseEnter  write fOnMouseEnter;
    Property OnMouseLeave:  SP_MouseEvent       read fOnMouseLeave  write fOnMouseLeave;
    Property OnMouseWheel:  SP_MouseWheelEvent  read fOnMouseWheel  write fOnMouseWheel;
    Property OnKeyDown:     SP_KeyEvent         read fOnKeyDown     write fOnKeyDown;
    Property OnKeyUp:       SP_KeyEvent         read fOnKeyUp       write fOnKeyUp;
    Property OnPaintBefore: SP_PaintEvent       read fOnPaintBefore write fOnPaintBefore;
    Property OnPaintAfter:  SP_PaintEvent       read fOnPaintAfter  write fOnPaintAfter;
    Property BackgroundClr: Byte                read fBackgroundClr write SetBackgroundClr;
    Property FontClr:       Byte                read fFontClr       write SetFontClr;
    Property ErrorClr:      Byte                read fErrorClr      write SetErrorClr;
    Property Width:         Integer             read fWidth         write SetWidth;
    Property Height:        Integer             read fHeight        write SetHeight;
    Property Left:          Integer             read fLeft          write fLeft;
    Property Top:           Integer             read fTop           write fTop;
    Property WindowID:      Integer             read fWindowID      write SetWindowID;
    Property OnResize:      SP_ResizeEvent      read fOnResize      write fOnResize;
    Property Enabled:       Boolean             read fEnabled       write SetEnabled;
    Property Visible:       Boolean             read fVisible       write SetVisible;
    Property CanFocus:      Boolean             read fCanFocus      write fCanFocus;
    Property Focused:       Boolean             read GetFocused     write SetFocus;
    Property OnDblClick:    SP_MouseEvent       read fOnDblClick    write fOnDblClick;
    Property ChainControl:  SP_BaseComponent    read fChainControl  write SetChainControl;
    Property OnClick:       SP_ClickEvent       read fOnClick       write fOnClick;
    Property OnAbort:       SP_AbortEvent       read fOnAbort       write fOnAbort;
    Property OnEnter:       SP_EnterEvent       read fOnEnter       write fOnEnter;
    Property OnExit:        SP_ExitEvent        read fOnExit        write fOnExit;
    Property OnShow:        SP_VisibleEvent     read fOnShow        write fOnShow;
    Property OnHide:        SP_VisibleEvent     read fOnHide        write fOnHide;
    Property BoundsRect:    TRect               read fBoundsrect;
    Property Border:        Boolean             read fBorder        write SetBorder;
    Property MinWidth:      Integer             read fMinWidth      write SetMinWidth;
    Property MinHeight:     Integer             read fMinHeight     write SetMinHeight;
    Property MaxWidth:      Integer             read fMaxWidth      write SetMaxWidth;
    Property MaxHeight:     Integer             read fMaxHeight     write SetMaxHeight;
    Property Canvas:        NativeUInt          read GetCanvas;
    Property DisabledFontClr:   Byte            read fDisabledFontClr   write SetDisabledFontClr;
    Property HighlightClr:  Byte                read fHighlightClr  write SetHighlightClr;
    Property UnfocusedHighlightClr: Byte        read fUnfocusedHighlightClr write SetUnfocusedHighlightClr;
    Property Transparent:   Boolean             read fTransparent   write SetTransparent;
    property OverrideScaling: Boolean           read fOverrideScl   write SetOverrideScaling;
    Property OnFocus: SP_FocusEvent             read fOnFocus       write SetOnFocus;
    Property Erase: Boolean                     read fErase         write fErase;
    Property Font: Integer                      read fCurFontID     write SetFont;

    Constructor Create(Owner: SP_BaseComponent);
    Destructor  Destroy; Override;

End;

pSP_BaseComponent = ^SP_BaseComponent;

Var

  GlobalControlID: Integer = 0;

Const

  SP_AlignNone   = 0;
  SP_AlignLeft   = 1;
  SP_AlignRight  = 2;
  SP_AlignTop    = 3;
  SP_AlignBottom = 4;
  SP_AlignAll    = 5;

implementation

Uses

  SP_Main, SP_Input, SP_Graphics, SP_BankFiling, SP_BankManager, SP_SysVars, SP_Errors,
  SP_PopUpMenuUnit, SP_Components;

Procedure SP_BaseComponent.SetChainControl(c: SP_BaseComponent);
Begin

  fChainControl := c;

End;

Procedure SP_BaseComponent.SetOverrideScaling(b: Boolean);
Begin

  If b <> fOverrideScl Then Begin
    fOverrideScl := b;
    ChangeFont;
    Paint;
  end;

End;

Procedure SP_BaseComponent.SetOnFocus(e: SP_FocusEvent);
Begin

  fOnFocus := e;

End;

Procedure SP_BaseComponent.SetAlign(newAlign: Integer);
var
  parentRect: TRect;
  cp: SP_BaseComponent;
  Win: pSP_Window_Info;
  Error: TSP_ErrorCode;
begin

  Lock;
  fAlign := newAlign;

  If fParentType = spWindow Then Begin

    SP_GetWindowDetails(fParentWindowID, Win, Error);
    cp := Win^.Component;

  End Else

    cp := fParentControl;

  parentRect := Rect(0, 0, cp.Width, cp.Height);

  Case fAlign of

    SP_AlignNone:
      Begin
        fLeft := fSetLeft;
        fTop := fSetTop;
        fWidth := fSetWidth;
        fHeight := fSetHeight;
      End;

    SP_AlignLeft:
      Begin
        fLeft := 0;
        fTop := 0;
        fWidth := fSetWidth;
        fHeight := parentRect.Bottom;
      End;

    SP_AlignTop:
      Begin
        fLeft := 0;
        Top := 0;
        fWidth := parentRect.Right;
        fHeight := fSetHeight;
      End;

    SP_AlignRight:
      Begin
        fLeft := parentRect.Right - fSetWidth;
        fTop := 0;
        fWidth := fSetWidth;
        fHeight := parentRect.Bottom;
      End;

    SP_AlignBottom:
      Begin
        fLeft := 0;
        fWidth := parentRect.Right;
        fTop := parentRect.Bottom - fSetHeight;
        fHeight := fSetHeight;
      End;

    SP_AlignAll:
      Begin
        fLeft := 0;
        fTop := 0;
        fWidth := ParentRect.Right;
        fHeight := ParentRect.Bottom;
      End;

  end;

  UnLock;

end;

Procedure SP_BaseComponent.SetTransparent(Value: Boolean);
Begin

  fTransparent := Value;
  Paint;

End;

Procedure SP_BaseComponent.SetFont(ID: integer);
begin

  fCurFontID := ID;
  Paint;

end;

Function SP_BaseComponent.GetCanvas: NativeUInt;
Begin

  If fValidCanvas Then
    Result := NativeUInt(@fCanvas[0])
  Else
    Result := 0;

End;

Procedure SP_BaseComponent.Print(X, Y: Integer; const Text: aString; Ink, Paper: Integer; ScaleX, ScaleY: aFloat; Italic, Bold: Boolean);
Var
  BankID, CharW, CharH, Idx, Val, cCount, OVER, ItalicOffset: Integer;
  sx, sy, Cw, Ch, yp, xp, TC, t: LongWord;
  Transparent: Boolean;
  FontBank: pSP_Font_Info;
  Bank: pSP_Bank;
  Dst, Coord, Char, pIdx, lIdx, c: pByte;
  IsScaled, SkipNextPaper: Boolean;
  dX, dY: aFloat;
Begin

  Dst := @fCanvas[0];
  IsScaled := False;
  BankID := SP_FindBankID(Font);
  If BankID <> SP_ERR_BANK_ID_NOT_FOUND Then Begin

    Bank := SP_BankList[BankID];
    FontBank := @Bank^.Info[0];
    IsScaled := (ScaleX <> 1) Or (ScaleY <> 1);
    CharW := Max(1, Trunc(FontBank^.Width * ScaleX));
    CharH := Max(1, Trunc(FontBank^.Height * ScaleY));
    Cw := CharW;
    Ch := CharH;
    If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
      Transparent := FontBank^.Transparent <> $FFFF;
      TC := FontBank^.Transparent And $FF;
    End Else
      Transparent := Paper = -1;

    Idx := 1;
    While Idx <= Length(Text) Do Begin

      If Text[Idx] >= ' ' Then Begin

        Char := @Bank^.Memory[FontBank^.Font_Info[Byte(Text[Idx])].Data];
        If Italic Then
          ItalicOffset := (CharH Div 3) Shl 16
        Else
          ItalicOffset := 0;
        Coord := Dst;
        Inc(Coord, (fWidth * Y) + X);
        Inc(Coord, ItalicOffset Shr 16);

        If IsScaled Then Begin
          // Scaled character
          sx := (FontBank^.Width Shl 16) Div CharW;
          sy := (FontBank^.Height Shl 16) Div CharH;
          yp := 0;
          While CharH > 0 Do Begin
            pIdx := Char;
            xp := 0;
            SkipNextPaper := False;
            Inc(pIdx, FontBank^.Width * (yp Shr 16));
            While CharW > 0 Do Begin
              If (X >= 0) And (Y >= 0) And (X < fWidth) And (Y < fHeight) Then
                If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                  If Transparent Then Begin
                    lIdx := pByte(NativeUInt(pIdx) + (xp Shr 16));
                    If lIdx^ <> TC Then
                      Coord^ := lIdx^;
                  End Else
                    Coord^ := pByte(NativeUInt(pIdx) + (xp Shr 16))^;
                End Else
                  If pByte(NativeUInt(pIdx) + (xp Shr 16))^ = 1 Then  Begin
                    Coord^ := Ink;
                    If Bold And (X+1 < fWidth) Then Begin
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
            Inc(Coord, fWidth - (cW + (ItalicOffset Shr 16)));
            If Italic Then Dec(ItalicOffset, 65536 Div 3);
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
                If (X >= 0) And (Y >= 0) And (X < fWidth) And (Y < fHeight) Then
                  If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                    If Transparent Then Begin
                      If Char^ <> TC Then
                        Coord^ := Char^;
                    End Else
                      Coord^ := Char^;
                  End Else
                    If Char^ = 1 Then Begin
                      Coord^ := Ink;
                      If Bold And (X+1 < fWidth) Then Begin
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
            Inc(Coord, fWidth - (CharW + (ItalicOffset Shr 16)));
            If Italic Then Dec(ItalicOffset, 65536 Div 3);
            Inc(Coord, ItalicOffset Shr 16);
            Dec(CharH);
          End;
          CharH := FontBank^.Height;
          Dec(Y, CharH);
          Dec(Coord, fWidth * CharH);
          Inc(Coord, CharW);
          Inc(X, CharW);
        End;

      End Else Begin

        // Control codes!
        Case Ord(Text[Idx]) of
          8:
            Begin // Cursor Left
              X := (X - Cw) Mod fWidth;
            End;
          9:
            Begin // Cursor right
              X := (X + Cw) Mod fWidth;
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
              Ink := pLongWord(@Text[Idx+1])^ And $FF;
              Inc(Idx, SizeOf(LongWord));
            End;
         17:
            Begin // PAPER control
              Paper := pLongWord(@Text[Idx+1])^ And $FF;
              Inc(Idx, SizeOf(LongWord));
            End;
         19:
            Begin // TRANSPARENT 0/1
              t := pLongWord(@Text[Idx+1])^;
              If t <> 8 Then Begin
                Transparent := t > 0;
                If FontBank^.FontType = SP_FONT_TYPE_COLOUR Then Begin
                  Transparent := Transparent And (FontBank^.Transparent <> $FFFF);
                  TC := FontBank^.Transparent And $FF;
                End;
              End;
              Inc(Idx, SizeOf(LongWord));
            End;
         21:
            Begin // MOVE control
              X := pInteger(@Text[Idx+1])^;
              Inc(Idx, SizeOf(Integer));
              Y := pInteger(@Text[Idx+1])^;
              Inc(Idx, SizeOf(Integer));
            End;
         22:
            Begin // AT control
              Y := pInteger(@Text[Idx+1])^ * LongWord(Ch);
              Inc(Idx, SizeOf(Integer));
              X := pInteger(@Text[Idx+1])^ * LongWord(Cw);
              Inc(Idx, SizeOf(Integer));
            End;
         23:
            Begin // TAB control
              X := (pInteger(@Text[Idx+1])^ Mod LongWord(fWidth Div Cw)) * LongWord(Ch);
              Inc(Idx, SizeOf(Integer));
            End;
         24:
            Begin // CENTRE control
              Y := pInteger(@Text[Idx+1])^ * LongWord(Ch);
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
              X := (fWidth - (cCount * Cw)) Div 2;
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
                Exit;
              End Else Begin
                CharW := Max(1, Trunc(FontBank^.Width * ScaleX));
                CharH := Max(1, Trunc(FontBank^.Height * ScaleY));
                Cw := CharW;
                Ch := CharH;
              End;
            End;
         26:
          Begin
            // ITALIC control
            t := pLongWord(@Text[Idx+1])^;
            If t <> 8 Then
              Italic := t <> 0;
            Inc(Idx, SizeOf(LongWord));
          End;
         27:
          Begin
            // BOLD control
            t := pLongWord(@Text[Idx+1])^;
            If t <> 8 Then
              Bold := t <> 0;
            Inc(Idx, SizeOf(LongWord));
          End;
        End;
        Coord := Dst;
        Inc(Coord, (fWidth * Y) + X);
      End;
      Inc(Idx);
    End;

  End;

End;

Procedure SP_BaseComponent.SetPixel(x, y: Integer; Ink: Byte);
Begin

  fCanvas[x + (y * fWidth)] := Ink;

End;

Procedure SP_BaseComponent.DrawLine(X1, Y1, X2, Y2: Integer; Ink: Byte);
var
  d, ax, ay, sx, sy, dx, dy: Integer;
  Ptr, dst: pByte;
  ink_long, w: Longword;
  {$IFDEF CPU64}
  ink_64: NativeUInt;
  {$ENDIF}
  stsy: Integer;
begin

  dst := @fCanvas[0];
  If SP_LineClip(x1, y1, x2, y2, 0, 0, fWidth, fHeight) Then Begin

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
      Ptr := pByte(NativeUInt(dst) + (y1 * fWidth) + x1);
      While y1 <> y2 do begin
        Ptr^ := Ink;
        Inc(y1);
        Inc(Ptr, fWidth);
      End;
      Ptr^ := Ink;
      Exit;
    End;

    If dy = 0 then Begin
      If x1 > x2 Then Begin
        x1 := x1 Xor x2; x2 := x1 Xor x2; x1 := x1 Xor x2;
      End;
      Ptr := pByte(NativeUInt(dst) + (y1 * fWidth) + x1);
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

    Ptr := pByte(NativeUInt(dst) + (y1 * fWidth) + x1);
    stsy := fWidth * sy;

    Ptr^ := Ink;
    If ax > ay Then Begin
      d := ay - (ax shr 1);
      while x1 <> x2 do begin
        if d>-1 then begin
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
        if d >= 0 then begin
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

Procedure SP_BaseComponent.DrawRect(x1, y1, x2, y2: Integer; Ink: Byte);
Begin

  DrawLine(x1, y1, x2, y1, Ink);
  DrawLine(x1, y1+1, x1, y2, Ink);
  DrawLine(x1+1, y2, x2, y2, Ink);
  DrawLine(x2, y1+1, x2, y2 -1, Ink);

End;

Procedure SP_BaseComponent.DrawRect(r: TRect; Ink: Byte);
Begin

  DrawRect(r.Left, r.Top, r.Right, r.Bottom, Ink);

End;

Procedure SP_BaseComponent.FillRect(r: TRect; Ink: Byte);
Begin

  FillRect(r.left, r.top, r.right, r.bottom, Ink);

End;

Procedure SP_BaseComponent.FillRect(X1, Y1, X2, Y2: Integer; Ink: Byte);
Var
  W: Integer;
  ink_long: LongWord;
  {$IFDEF CPU64}
  ink_64: NativeUInt;
  {$ENDIF}
  Dst: pByte;
Begin

  X1 := Max(0, X1); X2 := Min(X2, fWidth -1);
  X2 := Max(0, X2); Y2 := Min(Y2, fHeight -1);
  Dst := pByte(NativeInt(@fCanvas[0]) + (fWidth * Y1) + X1);
  ink_long := Ink + (Ink shl 8) + (Ink shl 16) + (Ink shl 24);

  While Y1 <= Y2 Do Begin
    W := (X2 - X1) + 1;
    {$IFDEF CPU64}
    ink_64 := NativeUint(ink_Long) + (NativeUInt(Ink_Long) Shl 32);
    While w > SizeOf(NativeUint) Do Begin
      pNativeUInt(Dst)^ := ink_64;
      Inc(pNativeUInt(Dst));
      Dec(w, SizeOf(NativeUInt));
    End;
    {$ENDIF}
    While w > SizeOf(LongWord) do Begin
      pLongWord(Dst)^ := Ink_Long;
      Inc(pLongWord(Dst));
      Dec(w, SizeOf(LongWord));
    End;
    While w > 0 do Begin
      pByte(Dst)^ := Ink;
      Inc(pByte(Dst));
      Dec(w);
    End;
    Inc(Dst, fWidth - (X2 - X1) -1);
    Inc(Y1);
  End;

End;

Procedure SP_BaseComponent.DrawBtnFrame(Border, Pressed: Boolean);
Var
  x1, y1, x2, y2: Integer;
Begin

  x1 := 0; y1 := 0; x2 := Width -1; y2 := Height -1;

  DrawRect(x1, y1, x2, y2, 0);
  Inc(x1); Inc(y1); Dec(x2); Dec(y2);
  If Pressed Then Begin
    DrawRect(x1, y1, x2, y2, 0);
    Inc(x1); Inc(y1);
  End;

  If Focused Then
    FillRect(x1, y1, x2, y2, SP_UIBtnBackFocus)
  Else
    FillRect(x1, y1, x2, y2, SP_UIBtnBack);
  DrawLine(x1, y1, x2 -1, y1, SP_UIHighlight);
  DrawLine(x1, y1 +1, x1, y2 -1, SP_UIHighlight);
  SetPixel(x1, y2, SP_UIHalfLight);
  SetPixel(x2, y1, SP_UIHalfLight);
  DrawLine(x2, y1 +1, x2, y2, SP_UIShadow);
  DrawLine(x1 +1, y2, x2 -1, y2, SP_UIShadow);

End;

Procedure SP_BaseComponent.DrawBtnFrame(r: TRect; Border, Pressed: Boolean);
Var
  x1, y1, x2, y2: Integer;
Begin

  If ValidRect(r) Then Begin

    x1 := r.Left; y1 := r.Top; x2 := r.Right -1; y2 := r.Bottom -1;

    FillRect(x1, y1, x2, y2, 0);
    Inc(x1); Inc(y1); Dec(x2); Dec(y2);
    If Pressed Then Begin
      DrawRect(x1, y1, x2, y2, 0);
      Inc(x1); Inc(y1);
    End;

    FillRect(x1, y1, x2, y2, SP_UIBtnBack);
    DrawLine(x1, y1, x2 -1, y1, SP_UIHighlight);
    DrawLine(x1, y1 +1, x1, y2 -1, SP_UIHighlight);
    SetPixel(x1, y2, SP_UIHalfLight);
    SetPixel(x2, y1, SP_UIHalfLight);
    DrawLine(x2, y1 +1, x2, y2, SP_UIShadow);
    DrawLine(x1 +1, y2, x2 -1, y2, SP_UIShadow);

  End;

End;

// SP_BaseComponent

Procedure SP_BaseComponent.ChangeFont;
Begin

  If SYSTEMSTATE in [SS_EDITOR, SS_DIRECT, SS_NEW, SS_ERROR] Then Begin
    If not fOverrideScl Then Begin
      iFW := Trunc(FONTWIDTH * EDFONTSCALEX);
      iFH := Trunc(FONTHEIGHT * EDFONTSCALEY);
      iSX := EDFONTSCALEX;
      iSY := EDFONTSCALEY;
    End Else Begin
      iFH := FONTHEIGHT;
      iFW := FONTWIDTH;
      iSX := 1;
      iSY := 1;
    End;
  End Else Begin
    iFH := FONTHEIGHT;
    iFW := FONTWIDTH;
    iSX := T_SCALEX;
    iSY := T_SCALEY;
  End;

End;

Constructor SP_BaseComponent.Create(Owner: SP_BaseComponent);
Var
  win: pSP_Window_Info;
  Error: TSP_ErrorCode;
  l: Integer;
  cp: SP_BaseComponent;
Begin

  ChangeFont;
  If SYSTEMSTATE in [SS_EDITOR, SS_DIRECT, SS_NEW, SS_ERROR] Then
    fCurFontID := EDITORFONT
  Else
    fCurFontID := FONTBANKID;

  Inc(GlobalControlID);
  ControlID := GlobalControlID;
  fNumComponents := 0;

  fWindowID := -1;
  If Assigned(Owner) Then Begin
    fParentControl := Owner;
    If Assigned(Owner.fParentControl) then
      fParentType := spControl
    else
      fParentType := spWindow;
    l := Length(Owner.fComponentList);
    SetLength(Owner.fComponentList, l +1);
    Owner.fComponentList[l] := Self;
    Inc(Owner.fNumComponents);
    fParentWindowID := Owner.fParentWindowID;
  End Else Begin
    fParentType := spWindow;
    fParentControl := nil;
  End;

  fTransparentClr := $FFFF;
  If fParentType = spWindow Then Begin
    fBorderClr := SP_UIBorder;
    fBackgroundClr := SP_UIBackground;
    fFontClr := SP_UIText;
    fDisabledFontClr := SP_UITextDisabled;
    fTransparent := True;
    fHighlightClr := SP_UISelection;
    fUnfocusedHighlightClr := SP_UIUnfocusedSelection;
  End Else Begin
    fBackgroundClr := Owner.fBackgroundClr;
    fFontClr := Owner.fFontClr;
    fBorderClr := Owner.fBorderClr;
    fDisabledFontClr := Owner.fDisabledFontClr;
    fUnfocusedHighlightClr := Owner.fUnfocusedHighlightClr;
    fHighlightClr := Owner.fHighlightClr;
    fTransparent := True;
  End;
  fErrorClr := 2;
  fEnabled := True;
  fValidCanvas := False;
  fVisible := True;
  fErase := True;
  fNeedPaint := False;
  fCanFocus := True;
  fBorder := True;
  fMinWidth := 0;
  fMinHeight := 0;
  fMaxWidth := MAXINT;
  fMaxHeight := MAXINT;
  cKeyRepeat := -1;
  fAnchors := [aLeft, aTop];
  fAlign := SP_AlignNone;
  If Assigned(fParentControl) Then Inc(ControlCount);
  fPrevFocus := nil;

End;

Destructor SP_BaseComponent.Destroy;
Var
  Idx, Idx2: Integer;
  Win: pSP_Window_Info;
  cp: SP_BaseComponent;
  Error: TSP_ErrorCode;
Begin

  DisplaySection.Enter;

  // Prevent any paint commands from accessing the canvas.

  fValidCanvas := False;

  // Remove any timer events that have been created by this control

  RemoveTimer(Self);

  // And ensure that mouse and keyboard events don't try to reference this control

  If CaptureControl = Self Then
    CaptureControl := nil;

  If FocusedControl = Self Then
    FocusedControl := nil;

  If MouseControl = Self Then
    MouseControl := nil;

  // Remove any attached components

  While Length(fComponentList) > 0 Do
    FreeAndNil(fComponentList[0]);

  // Remove the canvas

  fSize := 0;
  SetLength(fCanvas, 0);
  SetLength(fTempCanvas, 0);

  // And remove ourselves from the parent control's list.

  If fParentType = spWindow Then Begin

    SP_GetWindowDetails(fParentWindowID, Win, Error);
    cp := Win^.Component;

  End Else

    cp := fParentControl;

  Idx := 0;
  While Idx < Length(cp.fComponentList) Do
    If (Assigned(cp.fComponentList[Idx]) and (cp.fComponentList[Idx].ControlID = Self.ControlID)) or (Not Assigned(cp.fComponentList[Idx])) Then Begin
      For Idx2 := Idx To Length(cp.fComponentList) -2 Do
        cp.fComponentList[Idx2] := cp.fComponentList[Idx2 +1];
      SetLength(cp.fComponentList, Length(cp.fComponentList) -1);
      Dec(cp.fNumComponents);
    End Else
      Inc(Idx);

  If Assigned(fParentControl) Then
    Dec(ControlCount);

  Inherited;

  DisplaySection.Leave;

End;

Procedure SP_BaseComponent.BringToFront;
Var
  i, j: Integer;
  c: SP_BaseComponent;
Begin

  i := 0;
  While fParentControl.fComponentList[i] <> Self Do
    Inc(i);

  c := fParentControl.fComponentList[i];
  For j := i DownTo 1 Do
    fParentControl.fComponentList[j] := fParentControl.fComponentList[j -1];
  fParentControl.fComponentList[0] := c;

  Paint;

End;

Procedure SP_BaseComponent.Draw;
Begin

  // Nothing to do here - components must override this.

End;

Procedure SP_BaseComponent.SetWindowID(Id: Integer);
Begin

  fWindowID := Id;
  fParentWindowID := Id;

End;

Procedure SP_BaseComponent.Abort;
Begin

  If Assigned(OnAbort) Then
    OnAbort(Self)
  Else
    If Assigned(fParentControl) Then
      fParentControl.Abort;

End;

Procedure SP_BaseComponent.Lock;
Begin

  Inc(fLockCount);

End;

Procedure SP_BaseComponent.UnLock;
Begin

  Dec(fLockCount);
  if fLockCount = 0 Then
    if fNeedPaint Then
      Paint;

End;


Procedure SP_BaseComponent.MouseExit;
Begin

  If Assigned(OnExit) Then
    OnExit;

End;

Procedure SP_BaseComponent.MouseEnter(X, Y: Integer);
Begin

  If Assigned(OnEnter) Then
    fOnEnter(X, Y);

End;

Function  SP_BaseComponent.Components(Idx: Integer): SP_BaseComponent;
Begin

  If Idx < fNumComponents Then
    Result := fComponentList[Idx]
  Else
    Result := nil;

End;

Function  SP_BaseComponent.Owner: SP_BaseComponent;
Begin

  Result := fParentControl;

End;

Function  SP_BaseComponent.ClientToScreen(p: TPoint): TPoint;
Var
  Win: pSP_Window_Info;
  c: SP_BaseComponent;
  i: Integer;
Begin

  c := Self;
  Result := Point(p.x + fLeft, p.y + fTop);
  While Assigned(c.fParentControl) And (c.fParentControl.WindowID = -1) Do Begin
    c := c.fParentControl;
    Inc(Result.x, c.Left);
    Inc(Result.y, c.Top);
  End;
  i := SP_FindBankID(c.fParentControl.WindowID);
  Win := @SP_BankList[i]^.Info[0];
  Inc(Result.x, Win.Left);
  Inc(Result.y, Win.Top);

End;

Function SP_BaseComponent.GetWindowDetails: Pointer;
Var
  c: SP_BaseComponent;
  i: Integer;
Begin

  c := Self;
  While Assigned(c.fParentControl) And (c.fParentControl.WindowID = -1) Do
    c := c.fParentControl;
  i := SP_FindBankID(c.fParentControl.WindowID);
  Result := @SP_BankList[i]^.Info[0];

End;

Function SP_BaseComponent.ScreenToClient(p: TPoint): TPoint;
Var
  Win: pSP_Window_Info;
  c: SP_BaseComponent;
  i, ari: Integer;
  ar: Array[0..10] of SP_BaseComponent;
Begin

  ari := 0;
  c := Self;
  Result := Point(p.x, p.y);
  While c.WindowID = -1 Do Begin
    ar[ari] := c;
    c := c.fParentControl;
    Inc(ari);
  End;
  i := SP_FindBankID(c.WindowID);
  Win := @SP_BankList[i]^.Info[0];
  Dec(Result.x, Win.Left);
  Dec(Result.y, Win.Top);

  For i := 0 To ari -1 Do Begin
    Dec(Result.x, ar[i].Left);
    Dec(Result.y, ar[i].Top);
  End;

End;

Function SP_BaseComponent.GetFocused: Boolean;
Begin

  Result := (fFocused and (FocusedControl = Self)) or (CaptureControl = Self);

End;

Procedure SP_BaseComponent.SetFocus(b: Boolean);
Var
  c: SP_BaseComponent;
  ParentCanFocus: Boolean;
Begin

  If b Then Begin

    ParentCanFocus := True;
    c := Self;
    While Assigned(c.fParentControl) And (c.fParentControl.WindowID = -1) Do Begin
      c := c.fParentControl;
      ParentCanFocus := ParentCanFocus And c.CanFocus;
    End;

    If (b And not CanFocus) or Not ParentCanFocus Then Exit;

    If fEnabled Then Begin
      c := FocusedControl;
      fPrevFocus := c;
      If Assigned(FocusedControl) And (FocusedControl <> Self) And b Then
        FocusedControl.SetFocus(False);
      If b Then
        FocusedControl := Self
      Else
        FocusedControl := nil;
      If (fFocused <> b) or (c <> FocusedControl) then Begin
        fFocused := b;
        Paint;
      End;
      If b And Assigned(fOnFocus) then
        fOnFocus(Self, b);
    End;

  End Else Begin

    If Assigned(fOnFocus) Then
      fOnFocus(Self, b);

  End;

End;

Procedure SP_BaseComponent.Paint;
Var
  Win: pSP_Window_Info;
  Idx: Integer;
  p: TPoint;
  Error: TSP_ErrorCode;
Begin

  If fValidCanvas And (fLockCount <= 0) Then Begin

    DisplaySection.Enter;

    // Erase the background if desired

    DoErase;

    // Now execute the before, during and after paint events.
    // the "during" event actually paints the component, so should be set.

    If Assigned(fOnPaintBefore) Then
      fOnPaintBefore;

    Draw;

    If Assigned(fOnPaintAfter) Then
      fOnPaintAfter;

    p := ClientToScreen(Point(0, 0));
    SP_SetDirtyRect(p.x, p.y, p.x + Width, p.y + Height);
    SP_NeedDisplayUpdate := True;
    fNeedPaint := False;

    DisplaySection.Leave;

  End Else

    fNeedPaint := True;

End;

Procedure SP_BaseComponent.SetDisabledFontClr(c: Byte);
Begin

  If fDisabledFontClr <> c Then Begin
    fDisabledFontClr := c;
    Paint;
  End;

End;

Procedure SP_BaseComponent.SetUnfocusedHighlightClr(c: Byte);
Begin

  If fUnfocusedHighlightClr <> c Then Begin
    fUnfocusedHighlightClr := c;
    Paint;
  End;

End;

Procedure SP_BaseComponent.SetBackgroundClr(c: Byte);
Begin

  If fBackgroundClr <> c Then Begin
    fBackgroundClr := c;
    Paint;
  End;

End;

Procedure SP_BaseComponent.SetHighlightClr(c: Byte);
Begin

  If fHighlightClr <> c Then Begin
    fHighlightClr := c;
    Paint;
  End;

End;

Procedure SP_BaseComponent.SetFontClr(c: Byte);
Begin

  If fFontClr <> c Then Begin
    fFontClr := c;
    Paint;
  End;

End;

Procedure SP_BaseComponent.SetErrorClr(c: Byte);
Begin

  If fErrorClr <> c Then Begin
    fErrorClr := c;
    Paint;
  End;

End;

Procedure SP_BaseComponent.SetWidth(w: Integer);
Var
  Error: TSP_ErrorCode;
  OldWidth: Integer;
Begin

  DisplaySection.Enter;

  OldWidth := Width;
  w := Min(Max(w, fMinWidth), fMaxWidth);
  If aRight in fAnchors Then Begin
    fLeft := Left - (w - fWidth);
    fSetLeft := fLeft;
  End;
  fWidth := w;
  fSetWidth := fWidth;

  SetAlign(fAlign);

  fSize := fWidth * fHeight;
  SetLength(fCanvas, fsize);
  SetLength(fTempCanvas, fsize);
  fValidCanvas := (fWidth > 0) And (fHeight > 0);
  fBoundsRect := Rect(Left, Top, Left + Width, Top + Height);

  DisplaySection.Leave;

  If OldWidth <> Width Then
    DoResize(Width - OldWidth, 0);

End;

Procedure SP_BaseComponent.SetHeight(h: Integer);
Var
  Error: TSP_ErrorCode;
  OldHeight: Integer;
Begin

  DisplaySection.Enter;

  OldHeight := Height;
  h := Min(Max(h, fMinHeight), fMaxHeight);
  If aBottom in fAnchors then Begin
    fTop := Top - (h - fHeight);
    fSetTop := fTop;
  End;
  fHeight := h;
  fSetHeight := fHeight;

  SetAlign(fAlign);

  fSize := fWidth * fHeight;
  SetLength(fCanvas, fsize);
  SetLength(fTempCanvas, fsize);
  fValidCanvas := (fWidth > 0) And (fHeight > 0);
  fBoundsRect := Rect(Left, Top, Left + Width, Top + Height);

  DisplaySection.Leave;

  If OldHeight <> Height Then
    DoResize(0, Height - OldHeight);

End;

Procedure SP_BaseComponent.SetLeft(X: Integer);
Var
  Error: TSP_ErrorCode;
Begin

  If aRight in fAnchors Then Begin
    fWidth := Width - (X - fLeft);
    fSetWidth := fWidth;
  End;
  fLeft := X;
  fSetLeft := fLeft;
  SetAlign(fAlign);
  fBoundsRect.Left := fLeft;

End;

Procedure SP_BaseComponent.SetTop(Y: Integer);
Var
  Error: TSP_ErrorCode;
Begin

  If aTop in fAnchors Then Begin
    fHeight := Height - (Y - fTop);
    fSetHeight := Height;
  End;
  fTop := Y;
  fSetTop := fTop;
  SetAlign(fAlign);
  fBoundsRect.Top := Y;

End;

Procedure SP_BaseComponent.SetMinWidth(w: Integer);
Begin

  fMinWidth := w;
  SetWidth(Width);

End;

Procedure SP_BaseComponent.SetMinHeight(h: Integer);
Begin

  fMinHeight := h;
  SetHeight(Height);

End;

Procedure SP_BaseComponent.SetMaxWidth(w: Integer);
Begin

  fMaxWidth := w;
  SetWidth(Width);

End;

Procedure SP_BaseComponent.SetMaxHeight(h: Integer);
Begin

  fMaxHeight := h;
  SetHeight(Height);

End;

Procedure SP_BaseComponent.SetEnabled(b: Boolean);
Var
  i: Integer;
Begin

  If fEnabled <> b Then Begin
    fEnabled := b;
    For i := 0 To Length(fComponentList) -1 Do
      fComponentList[i].Enabled := b;

    Paint;
  End;

End;

Procedure SP_BaseComponent.SetBorderClr(c: Byte);
begin

  If fBorderClr <> c Then Begin
    fBorderClr := c;
    Paint;
  End;

end;

Procedure SP_BaseComponent.DoErase;
Var
  Error: TSP_ErrorCode;
Begin

  If fValidCanvas Then
    If fErase Then
      If not fTransparent Then
        FillMem(@fCanvas[0], Length(fCanvas), fBackgroundClr)
      else
        CopyParentCanvas;

End;

Procedure SP_BaseComponent.CopyParentCanvas;
Var
  Source: aString;
  Src, Dst: pByte;
  Win: pSP_Window_Info;
  Error: TSP_ErrorCode;
  cX1, cX2, cY1, cY2, w, h: Integer;
Begin

  Dst := @fCanvas[0];
  If Assigned(Dst) Then Begin
    If fParentType = spWindow Then Begin
      Win := GetWindowDetails;
      Src := Win^.Surface;
      w := Win^.Width;
      h := Win^.Height;
    End Else
      With SP_BaseComponent(fParentControl) Do Begin
        If Length(fCanvas) = 0 Then Exit;
        Src := @fCanvas[0];
        w := Width;
        h := Height;
      End;

    If Assigned(Src) Then Begin
      cx1 := 0; cy1 := 0; cx2 := width; cy2 := height;
      SP_GetRegion(Src, w, h, Source, Left, Top, Width, Height, -1, Error);
      SP_PutRegion(Dst, 0, 0, Width, Height, @Source[1], Length(Source), 0, 1, cx1, cy1, cx2, cy2, Error);
    End;
  End;

End;

Procedure SP_BaseComponent.Render(Dst: pByte; dW, dH: LongWord);
Var
  dX, dY, W, W2, H, SrcX, SrcY, SrcW, SrcH, Idx: LongWord;
  Src: pByte;
  TC: Byte;
Begin

  If Not Assigned(fParentControl) Then Begin

    If fNumComponents > 0 Then
      For Idx := fNumComponents -1 DownTo 0 Do
        fComponentList[Idx].Render(Dst, dW, dH);

  End Else If fValidCanvas And fVisible Then Begin

    CopyMem(@fTempCanvas[0], @fCanvas[0], fSize);

    If fNumComponents > 0 Then
      For Idx := fNumComponents -1 DownTo 0 Do
        if Assigned(fComponentList[Idx]) Then
          fComponentList[Idx].Render(@fTempCanvas[0], fWidth, fHeight);

    dX := fLeft;
    dY := fTop;
    W2 := Width;
    If (dX > dW) or (dX <= -Width) Then Exit;
    If (dY > dH) or (dY <= -Height) Then Exit;
    If dX < 0 Then Begin SrcX := -dX; Dec(W2, SrcX); dX := 0; End Else SrcX := 0;
    If dY < 0 Then Begin SrcY := -dY; Dec(H, SrcY); dY := 0; End Else SrcY := 0;
    If dX + W2 >= dW Then SrcW := dW - dX Else SrcW := Min(W2, dW);
    If dY + Height >= dH Then SrcH := dH - dY Else SrcH := Min(Height, dH);

    Src := @fTempCanvas[0];
    Inc(Src, (W * SrcY) + SrcX);
    Inc(Dst, (Integer(dW) * dY) + dX);
    If fTransparentClr <> $FFFF Then Begin
      TC := fTransparentClr And $FF;
      While SrcH > 0 Do Begin
        W2 := SrcW;
        While W2 > 0 Do Begin
          If Src^ <> TC Then Dst^ := Src^;
          Inc(Dst);
          Inc(Src);
          Dec(W2);
        End;
        Inc(Dst, dW - SrcW);
        Inc(Src, Width - SrcW);
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
        Inc(Src, Width - SrcW);
        Dec(SrcH);
      End;
    End;

  End;

End;

Procedure SP_BaseComponent.DoResize(WidthChange, HeightChange: Integer);
Var
  i: Integer;
  c: SP_BaseComponent;
begin

  For i := 0 to Length(fComponentList) -1 Do Begin
    c := fComponentList[i];
    If WidthChange <> 0 Then Begin
      If not (aLeft in c.Anchors) Then
        c.Left := c.Left + WidthChange;
      If aRight in c.Anchors Then
        c.Width := c.Width + WidthChange;
    End;
    If HeightChange <> 0 Then Begin
      If not (aTop in c.Anchors) Then
        c.Top := c.Top + HeightChange;
      If aBottom in c.Anchors Then
        c.Height := c.Height + HeightChange;
    End;
  End;

  If Assigned(fOnResize) Then
    fOnResize;

end;

Procedure SP_BaseComponent.SetBounds(x, y, w, h: Integer);
Var
  Error: TSP_ErrorCode;
  OldWidth, OldHeight: Integer;
Begin

  If (fWidth <> w) or (fHeight <> h) or (fLeft <> x) or (fTop <> y) Then Begin

    Lock;
    DisplaySection.Enter;

    OldWidth := Width; OldHeight := Height;
    fWidth := Min(Max(w, fMinWidth), fMaxWidth);
    fHeight := Min(Max(h, fMinHeight), fMaxHeight);
    fLeft := x;
    fTop := y;

    fSetLeft := fLeft;
    fSetTop := fTop;
    fSetWidth := fWidth;
    fSetHeight := fHeight;
    SetAlign(fAlign);

    fSize := fWidth * fHeight;

    SetLength(fCanvas, fsize);
    SetLength(fTempCanvas, fsize);
    fValidCanvas := (fWidth > 0) And (fHeight > 0);
    fBoundsRect := Rect(Left, Top, Left + Width, Top + Height);

    If (OldWidth <> Width) or (OldHeight <> Height) Then
      DoResize(Width - OldWidth, Height - OldHeight);

    DisplaySection.Leave;
    Unlock;

    Paint;

  End;

End;

Procedure SP_BaseComponent.SetPosition(x, y: Integer);
Begin

  SetBounds(x, y, fWidth, fHeight);

End;

Procedure SP_BaseComponent.KeyDown(Key: Integer; Var Handled: Boolean);
Var
  b: Boolean;
Begin

  fLastKeyChar := cLastKeyChar;
  fLastKey := cLastKey;
  If Not (Key in [K_CONTROL, K_SHIFT, K_ALT, K_ALTGR]) Then Begin
    if cKeyRepeat >= 0 Then
      RemoveTimer(cKeyRepeat);
    cKeyRepeat := AddTimer(Self, REPDEL, KeyRepeat, False)^.ID;
  End;

  PerformKeyDown(Handled);

  If Assigned(fOnKeyDown) Then
    fOnKeyDown(Key, Handled);

End;

Procedure SP_BaseComponent.PerformKeyDown(Var Handled: Boolean);
Begin

  // Do nothing - individual components must override this

End;

Procedure SP_BaseComponent.PerformKeyUp(Var Handled: Boolean);
Begin

  // Do nothing - individual components must override this

End;

Function SP_BaseComponent.DecodeKey(Var Char: Byte): Byte;
Var
  Modifier: Byte;
Const
  NumPads: Array[0..9] of Integer = (K_INSERT, K_END, K_DOWN, K_NEXT, K_LEFT, 0, K_RIGHT, K_HOME, K_UP, K_PRIOR);
Begin

  Result := cLastKeyChar;
  CB_GetKeyLockState;

  If KEYSTATE[K_SHIFT] <> 0 Then
    Modifier := 1
  Else
    Modifier := 0;

  If KB_IN_USE Then
    If (KEYSTATE[K_CONTROL] <> 0) And (CharStr[Char] <> '') Then
      cLastKeyChar := Ord(CharStr[Char][Modifier + 1]);

  If (Not KB_IN_USE) And (NUMLOCK = 1) And (Char in [K_NUMPAD0..K_NUMPAD9, K_DECIMAL]) Then
    Result := cLastKeyChar
  Else

    Case Char of

      K_NUMPAD0 .. K_NUMPAD9:
        If NUMLOCK = 1 Then Begin
          If Not KB_IN_USE Then
            Result := cLastKeyChar
          Else
            Result := Ord(CharStr[Char][1]);
        End Else
          Char := NumPads[Char - K_NUMPAD0];

      K_DECIMAL:
        If NUMLOCK = 1 Then Begin
          If Not KB_IN_USE Then
            Result := Ord(GetLastKeyChar[1])
          Else
            Result := Ord(CharStr[K_DECIMAL][1]);
        End Else
          Char := K_DELETE;

    Else

      {$IFDEF PANDORA}
      If CharStr[Char] <> '' Then Begin
        Result := Ord(CharStr[Char][Modifier +1]);
        If CAPSLOCK = 1 Then
          If Result in [Ord('A')..Ord('Z'), Ord('a')..Ord('z')] Then Begin
            Modifier := 1 - Modifier;
            Result := Ord(CharStr[Char][Modifier +1]);
          End;
      End Else
        Result := 0;
      {$ELSE}
      If KB_IN_USE Then Begin
        If CharStr[Char] <> '' Then Begin
          Result := Ord(CharStr[Char][Modifier +1]);
          If CAPSLOCK = 1 Then
            If Result in [Ord('A')..Ord('Z'), Ord('a')..Ord('z')] Then Begin
              Modifier := 1 - Modifier;
              Result := Ord(CharStr[Char][Modifier +1]);
            End;
        End Else
          Result := 0;
      End Else
        If (cLastKeyChar <> 0) And (cLastKeyChar >= 32) Then Begin
        End Else
          Result := 0;
      {$ENDIF}
    End;

  {$IFDEF DARWIN}
  If ((Result = 97) And (cLastKey = 40)) Or    // cmd+up
     ((Result = 109) And (cLastKey = 13)) Or   // cmd+Enter
     ((Result = 98) And (cLastKey = 37)) Or    // cmd+right
     ((Result = 56) And (cLastKey = 8)) Or     // cmd+backspace
     ((Result = 99) And (cLastKey = 39)) And   // cmd+left
     (KEYSTATE[K_CONTROL] = 1) Then
      Result := 0;
  If ((Result = 77) And (cLastKey = 13)) Or    // Shift+Enter
     ((Result = 40) And (cLastKey = 46)) Or    // Fn+Backspace
     ((Result = 44) And (cLastKey = 33)) Or    // PgUp
     ((Result = 45) And (cLastKey = 34)) Or    // PgDn
     ((Result = 41) And (cLastKey = 36)) Or    // Home
     ((Result = 43) And (cLastKey = 35)) Then  // End
     Result := 0;
  If (Result = 0) And (cLastKey = 81) Then
    Result := 113;
  If (Result = 0) And (cLastKey in [65..90]) Then
    Result := cLastKey;
  {$ENDIF}

  {$IFDEF SPECCYKEYS}
  If (cLastKey = K_1) And (KEYSTATE[K_SHIFT] = 1) Then Begin
    cLastKey := K_TAB;
    Result := 0;
  End;
  {$ENDIF}

End;

Procedure SP_BaseComponent.KeyRepeat(p: Pointer);
Var
  b: Boolean;
Begin

  cLastKeyChar := fLastKeyChar;
  cLastKey := fLastKey;

  PerformKeyDown(b);

  pSP_TimerEvent(p)^.Interval := REPPER;
  pSP_TimerEvent(p)^.NextFrameTime := FRAMES + REPPER;

End;

Procedure SP_BaseComponent.KeyUp(Key: Integer; Var Handled: Boolean);
Begin

  If cKeyRepeat >= 0 Then
    RemoveTimer(cKeyRepeat);

  PerformKeyUp(Handled);

  If Assigned(fOnKeyUp) Then
    fOnKeyUp(Key, Handled);

End;

Procedure SP_BaseComponent.MouseDown(X, Y, Btn: Integer);
Begin

  Dbl := False;
  If Enabled Then Begin
    fCanClick := True;
    If (Abs(fMouseClickPos.X - X) < 4) Then
      If (Abs(fMouseClickPos.Y - Y) < 4) Then
        If (FRAMES - fMouseClickTime < FPS/2) Then
          If (fMouseLastBtn = Btn) Then Begin
            DoubleClick(X, Y, Btn);
            dbl := True;
          End;

    fMouseClickPos := Point(X, Y);
    fMouseLastBtn := Btn;
    fMouseClickTime := FRAMES;

    If fCanFocus Then
      SetFocus(True);

    If Assigned(fOnMouseDown) And Not Dbl Then
      fOnMouseDown(X, Y, Btn);

  End;

End;

Procedure SP_BaseComponent.DoubleClick(X, Y, Btn: Integer);
Begin

  If Assigned(OnDblClick) Then
    OnDblClick(X, Y, Btn);

End;

Procedure SP_BaseComponent.MouseUp(X, Y, Btn: Integer);
Begin

  If fCanClick Then Begin
    fCanClick := False;
    If Assigned(OnClick) And Not Assigned(fOnDblClick) Then
      OnClick(Self);
  End;

  If Assigned(fOnMouseUp) Then
    fOnMouseUp(X, Y, Btn);

End;

Procedure SP_BaseComponent.MouseMove(X, Y, Btn: Integer);
Begin

  If Assigned(fOnMouseMove) Then
    fOnMouseMove(X, Y, Btn);

End;

Procedure SP_BaseComponent.MouseWheel(X, Y, Btn, Delta: Integer);
Begin

  Inherited;

  If Assigned(fOnMouseWheel) Then
    fOnMouseWheel(X, Y, Btn, Delta);

End;

Procedure SP_BaseComponent.SetVisible(Value: Boolean);
Var
  p: TPoint;
  Error: TSP_ErrorCode;
Begin

  If fVisible <> Value Then Begin
    fVisible := Value;
    If fVisible Then Begin
      If Assigned(fOnShow) Then
        fOnShow;
      Paint;
    End Else Begin
      If Assigned(fOnHide) Then
        fOnHide;
      p := ClientToScreen(Point(0, 0));
      SP_SetDirtyRect(p.x, p.y, p.x + Width, p.y + Height);
      SP_NeedDisplayUpdate := True;
    End;
  End;

End;

Procedure SP_BaseComponent.SetBorder(b: Boolean);
begin

  If fBorder <> b Then Begin
    fBorder := b;
    Paint;
  End;

end;

end.
