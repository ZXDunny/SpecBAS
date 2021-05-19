unit SP_ScrollBarUnit;

interface

Uses Types, Math, SP_Util, SP_Components, SP_BaseComponentUnit, SP_ButtonUnit;

Type

SP_ScrollBarKind = (spHorizontal, spVertical);
SP_ScrollEvent = Procedure(Delta, NewPos: aFloat) of Object;

SP_ScrollBar = Class(SP_BaseComponent)

  Private

    fMin, fMax:     Integer;
    fRange:         Integer;
    fPosition:      Integer;
    fTargetPos:     Integer;
    fKind:          SP_ScrollBarKind;
    fThumbPos:      Integer;
    fThumbSize:     Integer;
    fThumbGrabbed:  Boolean;
    fThumbGrabPos:  Integer;
    fGrabPos:       Integer;
    fUpEnabled:     Boolean;
    fDownEnabled:   Boolean;
    fOnScroll:      SP_ScrollEvent;
    fPageSize:      Integer;
    fStep:          Integer;
    fTrackRect,
    fThumbRect,
    fUpRect,
    fDownRect:      TRect;
    fUpBtn,
    fDownBtn:       SP_Button;
    fClickDir:      Integer;
    fMouseTimer:    Integer;
    fScrollTimer:   Integer;
    fMousePos:      TPoint;
    fSmoothing:     Integer;
    fWheelStep:     Integer;
    fShowButtons:   Boolean;
    fBtnClr,
    fThumbClr,
    fTrackClr:      Byte;

    Procedure SetMin(m: Integer);
    Procedure SetMax(m: Integer);
    Procedure SetPos(p: Integer);
    Procedure SetPageSize(p: Integer);
    Procedure SetBorder(b: Boolean);
    Procedure SetKind(k: SP_ScrollBarKind);
    Function  SetUIElements: Boolean;
    Procedure SetShowButtons(b: Boolean);
    Procedure Resize;
    Function  GetBorder: Boolean;

    Procedure UpBtnMouseDown(X, Y, Btn: Integer);
    Procedure DnBtnMouseDown(X, Y, Btn: Integer);
    Procedure BtnMouseUp(X, Y, Btn: Integer);
    Procedure ClickTimer(p: Pointer);
    Procedure ScrollTimer(p: Pointer);

  Public

    Procedure SetBackgroundClr(c: Byte); Override;
    Procedure SetDisabledFontClr(c: Byte); Override;
    Procedure SetFontClr(c: Byte); Override;
    Procedure Draw; Override;
    Procedure SetTrackClr(c: Byte);
    Procedure SetBtnClr(c: Byte);
    Procedure SetThumbClr(c: Byte);
    Procedure ScrollInView(p: Integer);

    Property Step:        Integer          read fStep        write fStep;
    Property Min:         Integer          read fMin         write SetMin;
    Property Max:         Integer          read fMax         write SetMax;
    Property Pos:         Integer          read fPosition    write SetPos;
    Property Kind:        SP_ScrollBarKind read fKind        write SetKind;
    Property PageSize:    Integer          read fPageSize    write SetPageSize;
    Property OnScroll:    SP_ScrollEvent   read fOnScroll    write fOnScroll;
    Property WheelStep:   Integer          read fWheelStep   write fWheelStep;
    Property TargetPos:   Integer          read fTargetPos;
    Property Border:      Boolean          read GetBorder    write SetBorder;
    Property ShowButtons: Boolean          read fShowButtons write SetShowButtons;

    Procedure MouseDown(X, Y, Btn: Integer); Override;
    Procedure MouseUp(X, Y, Btn: Integer); Override;
    Procedure MouseMove(X, Y, Btn: Integer); Override;
    Procedure MouseWheel(X, Y, Btn, Delta: Integer); Override;

    Constructor Create(Owner: SP_BaseComponent);
    Destructor  Destroy; Override;

End;

implementation

Uses SP_SysVars, SP_Sound;

// SP_Scrollbar

Constructor SP_ScrollBar.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  Kind := spVertical;
  fMin := 0;
  fMax := 100;
  fPageSize := 10;
  fPosition := 0;
  fStep := 1;
  fSmoothing := 3;
  fTrackClr := SP_UIScrollTrack;
  fBtnClr := SP_UIScrollBtn;
  fThumbClr := SP_UIScrollThumb;
  fTransparent := False;
  fUpBtn := SP_Button.Create(Self);
  fUpBtn.fBorder := False;
  fUpBtn.fBackgroundClr := fBackgroundClr;
  fUpBtn.OnMouseDown := UpBtnMouseDown;
  fUpBtn.OnMouseUp := BtnMouseUp;
  fUpBtn.OnMouseWheel := MouseWheel;
  fDownBtn := SP_Button.Create(Self);
  fDownBtn.fBorder := False;
  fDownBtn.fBackgroundClr := fBackgroundClr;
  fDownBtn.OnMouseDown := DnBtnMouseDown;
  fDownBtn.OnMouseUp := BtnMouseUp;
  fDownBtn.OnMouseWheel := MouseWheel;
  fOnResize := Resize;
  fOnMouseWheel := MouseWheel;
  fWheelStep := SP_ScrollWheelValue;
  If SYSTEMSTATE in [SS_EDITOR, SS_DIRECT, SS_NEW, SS_ERROR] Then
    fShowButtons := SCROLLBTNS;
  SetUIElements;
  fScrollTimer := -1;
  fMouseTimer := -1;
  iSX := 1; iSY := 1;
  iFH := fH; iFW := fW;
  fCanFocus := False;
  Paint;

End;

Destructor SP_ScrollBar.Destroy;
Begin

  RemoveTimer(fScrollTimer);
  RemoveTimer(fMouseTimer);

  Inherited;

End;

Procedure SP_Scrollbar.SetShowButtons(b: Boolean);
Begin

  fShowButtons := b;
  SetUIElements;
  Paint;

End;

Procedure SP_ScrollBar.SetMin(m: Integer);
Begin

  If fMin <> m Then Begin
    fMin := m;
    SetUIElements;
  End;

End;

Procedure SP_ScrollBar.SetPageSize(p: Integer);
Begin

  If fPageSize <> p Then Begin
    fPageSize := p;
    SetUIElements;
  End;

End;

Procedure SP_ScrollBar.SetMax(m: Integer);
Begin

  If fMax <> m Then Begin
    fMax := m;
    SetUIElements;
  End;

End;

Procedure SP_ScrollBar.SetPos(p: Integer);
Var
  e: pSP_TimerEvent;
Begin

  fTargetPos := Math.Min(Math.Max(0, p), fMax - fPageSize);
  If fScrollTimer = -1 Then Begin
    e := AddTimer(Self, 1, ScrollTimer, True);
    fScrollTimer := e^.ID;
  End;

End;

Procedure SP_ScrollBar.ScrollInView(p: Integer);
Begin

  If p < fTargetPos + (iFH * 3) Then
    Pos := p - (iFH * 3)
  Else
    If p > fTargetPos + fPageSize - (iFH * 5) Then
      Pos := p - fPageSize + (iFH * 5);

End;

Procedure SP_ScrollBar.SetBorder(b: Boolean);
Begin

  If fBorder <> b Then Begin
    fBorder := b;
    fUpBtn.Border := b;
    fDownBtn.Border := b;
    If b Then Begin
      fUpBtn.BackgroundClr := SP_UIBtnBack;
      fDownBtn.BackgroundClr := SP_UIBtnBack;
    End Else Begin
      fUpBtn.BackgroundClr := fBackgroundClr;
      fDownBtn.BackgroundClr := fBackgroundClr;
    End;
    Paint;
  End;

End;

Procedure SP_ScrollBar.SetTrackClr(c: Byte);
Begin

  If fTrackClr <> c Then Begin
    fTrackClr := c;
    Paint;
  End;

End;

Procedure SP_ScrollBar.SetBtnClr(c: Byte);
Begin

  If fBtnClr <> c Then Begin
    If Assigned(fUpBtn) Then
      fUpBtn.FontClr := c;
    If Assigned(fDownBtn) Then
      fDownBtn.FontClr := c;
    fBtnClr := c;
    Paint;
  End;

End;

Procedure SP_ScrollBar.SetThumbClr(c: Byte);
Begin

  If fThumbClr <> c Then Begin
    fThumbClr := c;
    Paint;
  End;

End;

Procedure SP_ScrollBar.SetKind(k: SP_ScrollBarKind);
Begin

  If fKind <> k Then Begin
    fKind := k;
    SetUIElements;
  End;

End;

Procedure SP_ScrollBar.Resize;
Begin

  SetUIElements;
  Paint;

End;

Function SP_ScrollBar.GetBorder: Boolean;
begin

  Result := fBorder;

end;

Function SP_ScrollBar.SetUIElements: Boolean;
Var
  op, m: Integer;
  m2: aFloat;
  UpChar, DnChar: aChar;
Begin

  Result := False;
  op := fPosition;
  fRange := (fMax - fMin) -1;
  fPageSize := Math.Min(fPageSize, fRange);
  fPosition := Math.Min(Math.Max(fPosition, fMin), fMax - fPageSize);
  fUpEnabled := fPosition > fMin;
  fDownEnabled := fPosition < fMax - fPageSize;
  If Assigned(fUpBtn) Then Begin
    fUpBtn.Enabled := fUpEnabled;
    fUpBtn.Visible := fShowButtons;
    fDownBtn.Enabled := fDownEnabled;
    fDownBtn.Visible := fShowButtons;
  End;

  // Calculate visual element sizes

  With fBoundsRect Do If fRange > 1 Then Begin
    m := Math.Min(fWidth, fHeight);
    If fKind = spVertical Then Begin
      fUpRect := Rect(0, 0, m, m);
      fDownRect := Rect(0, Height - m, Width, Height);
      If fShowButtons Then
        fTrackRect := Rect(0, fUpRect.Bottom, Width, fDownRect.Top)
      Else
        fTrackRect := Rect(0, 0, Width, Height);
      m2 := (fTrackRect.Bottom - fTrackRect.Top)/fRange;
      fThumbSize := fTrackRect.Bottom - (Trunc((fMax - fPageSize) * m2) + fTrackRect.Top);
      fThumbPos := Trunc(fPosition * m2) + fTrackRect.Top;
      If fThumbPos < fTrackRect.Top Then Begin
        fThumbPos := fTrackRect.Top;
      End Else
        If fThumbPos + fThumbSize > fTrackRect.Bottom Then Begin
          fThumbPos := fTrackRect.Bottom - fThumbSize;
        End;
      fThumbRect := Rect(fTrackRect.Left, fThumbPos, fTrackRect.Right, fThumbPos + fThumbSize);
      UpChar := #251;
      DnChar := #252;
    End Else Begin
      fUpRect := Rect(0, 0, m, m);
      fDownRect := Rect(Width - m, 0, Width, m);
      If fShowButtons Then
        fTrackRect := Rect(fUpRect.Right, 0, fDownRect.Left, Height)
      Else
        fTrackRect := Rect(0, 0, Width, Height);
      m2 := (fTrackRect.Right - fTrackRect.Left)/fRange;
      fThumbSize := fTrackRect.Right - (Trunc((fMax - fPageSize) * m2) + fTrackRect.Left);
      fThumbPos := Trunc(fPosition * m2) + fTrackRect.Left;
      If fThumbPos < fTrackRect.Left Then Begin
        fThumbPos := fTrackRect.Left;
      End Else
        If fThumbPos + fThumbSize > fTrackRect.Right Then Begin
          fThumbPos := fTrackRect.Right - fThumbSize;
        End;
      fThumbRect := Rect(fThumbPos, fTrackRect.Top, fThumbPos + fThumbSize, fTrackRect.Bottom);
      UpChar := #254;
      DnChar := #253;
    End;

    fUpBtn.SetBounds(fUpRect.Left, fUpRect.Top, fUpRect.Right - fUpRect.Left, fUpRect.Bottom - fUpRect.Top);
    fUpBtn.Caption := UpChar;
    fUpBtn.CaptionPos := Point((fUpBtn.Width - fW) Div 2, (fUpBtn.Height - fH) Div 2);

    fDownBtn.SetBounds(fDownRect.Left, fDownRect.Top, fDownRect.Right - fDownRect.Left, fDownRect.Bottom - fDownRect.Top);
    fDownBtn.Caption := DnChar;
    fDownBtn.CaptionPos := Point((fDownBtn.Width - fW) Div 2, (fDownBtn.Height - fH) Div 2);

    Paint;

    If fPosition <> op Then
      If Assigned(fOnScroll) Then Begin
        Result := True;
        fOnScroll(fPosition - op, fPosition);
      End;

  End;

End;

Procedure SP_ScrollBar.SetBackgroundClr(c: Byte);
Begin

  If fBackGroundClr <> c Then Begin
    fBackgroundClr := c;
    fUpBtn.BackgroundClr := c;
    fDownBtn.BackgroundClr := c;
    Paint;
  End;

End;

Procedure SP_ScrollBar.SetDisabledFontClr(c: Byte);
Begin

  If fDisabledFontClr <> c Then Begin
    fDisabledFontClr := c;
    fUpBtn.fDisabledFontClr := c;
    fDownBtn.fDisabledFontClr := c;
    Paint;
  End;

End;

Procedure SP_ScrollBar.SetFontClr(c: Byte);
begin

  If fFontClr <> c Then Begin
    fFontClr := c;
    fUpBtn.FontClr := c;
    fDownBtn.FontClr := c;
    Paint;
  End;

end;

Procedure SP_ScrollBar.Draw;
Var
  r: TRect;
Begin

  If fBorder Then Begin
    r.Left := fThumbRect.Left +2;
    r.Top := fThumbRect.Top +2;
    r.Right := fThumbRect.Right -2;
    r.Bottom := fThumbRect.Bottom -2;
    FillRect(fTrackRect, 8);
    If fUpEnabled or fDownEnabled Then Begin
      DrawBtnFrame(fThumbRect, False, False);
      FillRect(r, fTrackClr);
    End;
  End Else Begin
    If fKind = spHorizontal Then Begin
      r.left := fTrackRect.Left;
      r.Right := fTrackRect.Right;
      r.Top := fUpBtn.CaptionPos.y;
      r.Bottom := r.Top + fH -1;
    End Else Begin
      r.Left := fUpBtn.CaptionPos.x;
      r.Right := r.Left + fW -1;
      r.Top := fTrackRect.Top;
      r.Bottom := fTrackRect.Bottom;
    End;
    FillRect(r, fTrackClr);
    If fKind = spHorizontal Then Begin
      r.Left := fThumbRect.Left;
      r.Right := fThumbRect.Right;
    End Else Begin
      r.Top := fThumbRect.Top;
      r.Bottom := fThumbRect.Bottom;
    End;
    If fUpEnabled or fDownEnabled Then
      FillRect(r, fThumbClr);
  End;

End;

Procedure SP_ScrollBar.MouseDown(X, Y, Btn: Integer);
Begin

  SP_PlaySystem(CLICKCHAN, CLICKBANK);
  fMousePos := Point(X, Y);
  If PtInRect(fTrackRect, fMousePos) Then Begin

    If PtInRect(fThumbRect, fMousePos) Then Begin

      fThumbGrabbed := True;
      If fKind = spVertical Then
        fThumbGrabPos := Y
      Else
        fThumbGrabPos := X;
      fGrabPos := fPosition;

    End Else Begin

      If ((fKind = spVertical) And (Y < fThumbRect.Top)) Or ((fKind = spHorizontal) And (X < fThumbRect.Left)) Then
        fClickDir := -fPageSize
      Else
        fClickDir := fPageSize;

      Pos := Pos + fClickDir;
      fMouseTimer := AddTimer(Self, REPDEL, ClickTimer, False)^.ID;

    End;

  End;

End;

Procedure SP_ScrollBar.MouseUp(X, Y, Btn: Integer);
Begin

  fMousePos := Point(X, Y);
  fThumbGrabbed := False;
  RemoveTimer(fMouseTimer);

End;

Procedure SP_ScrollBar.MouseMove(X, Y, Btn: Integer);
Var
  Delta: Integer;
  m: aFloat;
Begin

  fMousePos := Point(X, Y);
  If fThumbGrabbed Then Begin

    If fKind = spVertical Then Begin
      m := fTrackRect.Bottom - fTrackRect.Top;
      Delta := Y - fThumbGrabPos
    End Else Begin
      m := fTrackRect.Right - fTrackRect.Left;
      Delta := X - fThumbGrabPos;
    End;
    m := m/(fRange);
    fPosition := fGrabPos + Trunc(Delta/m);
    If Not SetUIElements Then
      If Assigned(fOnScroll) Then
        fOnScroll(Delta, fPosition);

  End;

End;

Procedure SP_ScrollBar.UpBtnMouseDown(X, Y, Btn: Integer);
Begin

  Pos := Pos - fStep;
  fClickDir := -fStep;
  fMousePos := Point(X, Y);
  fMouseTimer := AddTimer(Self, REPDEL, ClickTimer, False)^.ID;

End;

Procedure SP_ScrollBar.DnBtnMouseDown(X, Y, Btn: Integer);
Begin

  Pos := Pos + fStep;
  fClickDir := fStep;
  fMousePos := Point(X, Y);
  fMouseTimer := AddTimer(Self, REPDEL, ClickTimer, False)^.ID;

End;

Procedure SP_ScrollBar.BtnMouseUp(X, Y, Btn: Integer);
Begin

  RemoveTimer(fMouseTimer);

End;

Procedure SP_ScrollBar.MouseWheel(X, Y, Btn, Delta: Integer);
Begin

  Pos := fTargetPos + (Delta * fWheelStep);

End;

Procedure SP_ScrollBar.ClickTimer(p: Pointer);
Begin

  If pSP_TimerEvent(p)^.Sender = Self Then
    If PtInRect(fThumbRect, fMousePos) Then Begin
      RemoveTimer(fMouseTimer);
      Exit;
    End;

  pSP_TimerEvent(p)^.Interval := REPPER;
  pSP_TimerEvent(p)^.NextFrameTime := FRAMES + REPPER;
  Pos := pos + fClickDir;

End;

Procedure SP_ScrollBar.ScrollTimer(p: Pointer);
Var
  op, Delta: Integer;
Begin

  If fPosition <> fTargetPos Then Begin
    op := fPosition;
    Delta := (fTargetPos - fPosition) Div fSmoothing;
    If Delta = 0 Then
      if fTargetPos < fPosition Then
        Delta := -1
      Else
        If fTargetPos > fPosition Then
          Delta := 1;
    fPosition := fPosition + Delta;
    If Not SetUIElements And (op <> fPosition) Then
      If Assigned(fOnScroll) Then
        fOnScroll(fPosition - op, fPosition);
  End Else
    RemoveTimer(fScrollTimer);

End;

end.
