unit SP_SliderUnit;

interface

Uses Types, SP_BaseComponentUnit, SP_ButtonUnit, SP_Util;

Type

SP_ScrollBarKind = (spHorizontal, spVertical);
SP_ScrollEvent = Procedure(Delta, NewPos: aFloat) of Object;

SP_Slider = Class(SP_BaseComponent)

  Private

    fMin, fMax, fPosition: aFloat;
    fOnChange: SP_ScrollEvent;
    fKind: SP_ScrollbarKind;
    fThumbColour,
    fTrackColour,
    fTrackFillColour,
    fTrackFillDisabledColour: Integer;
    fIntPos: Integer;
    fStep: aFloat;
    fMousePos: TPoint;
    fMouseIsDown: Boolean;

  Public

    Procedure Draw; Override;
    Constructor Create(Owner: SP_BaseComponent);
    Destructor  Destroy; Override;
    Procedure SetThumbColour(Idx: Integer);
    Procedure SetTrackColour(Idx: Integer);
    Procedure SetFillColour(Idx: Integer);
    Procedure SetFillDisabledColour(Idx: Integer);
    Procedure SetMin(Value: aFloat);
    Procedure SetMax(Value: aFloat);
    Procedure SetPos(Value: aFloat);
    Procedure SetKind(Value: SP_ScrollBarKind);
    Procedure SetUIElements;
    Procedure MouseDown(X, Y, Btn: Integer); Override;
    Procedure MouseUp(X, Y, Btn: Integer); Override;
    Procedure MouseMove(X, Y, Btn: Integer); Override;
    Procedure MouseWheel(X, Y, Btn, Delta: Integer); Override;

    Property OnChange: SP_ScrollEvent read fOnChange write fOnChange;
    Property TrackClr: Integer read fTrackColour write SetTrackColour;
    Property FillClr: Integer read fTrackFillColour write SetFillColour;
    Property ThumbClr: Integer read fThumbColour write SetThumbColour;
    Property Min: aFloat read fMin write SetMin;
    Property Max: aFloat read fMax write SetMax;
    Property Step: aFloat read fStep write fStep;
    Property Kind: SP_ScrollbarKind read fKind write SetKind;
    Property Position: aFloat read fPosition write SetPos;

End;
pSP_Slider = ^SP_Slider;

implementation

Constructor SP_Slider.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fTypeName := 'spSlider';

  fMin := 0;
  fMax := 0;
  fStep := 1;
  fPosition := 0;
  fTrackColour := fBackgroundClr;
  fThumbColour := 7;
  fTrackFillColour := 1; // Fill with Blue by default
  fTrackFillDisabledColour := 8;
  fKind := spHorizontal;
  fMouseIsDown := False;

End;

Destructor SP_Slider.Destroy;
Begin

End;

Procedure SP_Slider.SetUIElements;
Begin

  If fKind = spHorizontal Then
    fIntPos := Trunc((Width - Height) * ((fPosition - fMin) / (fMax - fMin)))
  Else
    fIntPos := Trunc((Height - Width) * ((fPosition - fMin) / (fMax - fMin))) + Width -1;

End;

Procedure SP_Slider.Draw;
Var
  c, cf: Integer;
  thRect: TRect;
Begin

  If fEnabled Then Begin
    c := fTrackColour;
    cf := fTrackFillColour;
  End Else Begin
    c := fBackgroundClr;
    cf := fTrackFillDisabledColour;
  End;

  FillRect(0, 0, Width, Height, c);
  If fKind = spHorizontal Then
    FillRect(0, 0, fIntPos, Height, cf)
  Else
    FillRect(0, Height - 1 - fIntPos, Width, Height, cf);

  If fBorder Then
    DrawRect(0, 0, Width -1, Height -1, fBorderClr);

  If fKind = spHorizontal Then
    thRect := Rect(fIntPos, 0, fIntPos + Height, Height)
  Else
    thRect := Rect(0, Height - 1 - fIntPos, Width, Height - 1 - fIntPos + Width);

  If fBorder Then
    DrawBtnFrame(thRect, True, False);

End;

Procedure SP_Slider.SetKind(Value: SP_ScrollBarKind);
Var
  oKind: SP_ScrollBarKind;
Begin

  oKind := fKind;
  fKind := Value;
  If fKind <> oKind Then Begin
    SetUIElements;
    Paint;
  End;

End;

Procedure SP_Slider.SetThumbColour(Idx: Integer);
Begin

  fThumbColour := Idx;
  Paint;

End;

Procedure SP_Slider.SetTrackColour(Idx: Integer);
Begin

  fTrackColour := Idx;
  Paint;

End;

Procedure SP_Slider.SetFillColour(Idx: Integer);
Begin

  fTrackFillColour := Idx;
  Paint;

End;

Procedure SP_Slider.SetFillDisabledColour(Idx: Integer);
Begin

  fTrackFillDisabledColour := Idx;
  Paint;

End;

Procedure SP_Slider.SetMin(Value: aFloat);
Begin

  fMin := Value;
  SetUIElements;
  Paint;

End;

Procedure SP_Slider.SetMax(Value: aFloat);
Begin

  fMax := Value;
  SetUIElements;
  Paint;

End;

Procedure SP_Slider.SetPos(Value: aFloat);
Var
  oPos: aFloat;
Begin

  oPos := fPosition;
  fPosition := Value;
  If fPosition < fMin Then fPosition := fMin;
  If fPosition > fMax Then fPosition := fMax;
  SetUIElements;
  Paint;

  If oPos <> fPosition Then
    If Assigned(OnChange) Then
      OnChange(fPosition - oPos, fPosition);

End;

Procedure SP_Slider.MouseDown(X, Y, Btn: Integer);
Begin

  If Btn = 1 Then Begin
    fMouseIsDown := True;
    fMousePos := Point(X, Y);
  End;

  Inherited;

End;

Procedure SP_Slider.MouseUp(X, Y, Btn: Integer);
Begin

  fMouseIsDown := False;
  Inherited;

End;

Procedure SP_Slider.MouseMove(X, Y, Btn: Integer);
Var
  Dx, Dy: Integer;
  p, oPos: aFloat;
Begin

  oPos := fPosition;
  If fMouseIsDown Then Begin
    If fKind = spHorizontal Then Begin
      Dx := X - fMousePos.X;
      p := fPosition + (Dx * ((fMax - fMin) / (Width - Height)));
      Position := p;
      If fPosition <> oPos Then
        fMousePos.X := X;
    End Else
      If fKind = spVertical Then Begin
        Dy := fMousePos.Y - Y;
        p := fPosition + (Dy * ((fMax - fMin) / (Height - Width)));
        Position := p;
        If fPosition <> oPos Then
          fMousePos.Y := Y;

      End;
  End;

End;

Procedure SP_Slider.MouseWheel(X, Y, Btn, Delta: Integer);
Begin

  If Delta > 0 Then
    Position := fPosition + fStep
  Else
    If Delta < 0 Then
      Position := fPosition - fStep;

End;


end.
