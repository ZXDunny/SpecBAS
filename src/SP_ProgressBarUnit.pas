unit SP_ProgressBarUnit;

interface

Uses Types, SP_BaseComponentUnit, SP_ButtonUnit, SP_Util;

Type

SP_ScrollBarKind = (spHorizontal, spVertical);

SP_ProgressBar = Class(SP_BaseComponent)

  Private

    fMin, fMax, fPosition: aFloat;
    fKind: SP_ScrollbarKind;
    fTrackColour,
    fTrackFillColour,
    fTrackFillDisabledColour: Integer;
    fIntPos: Integer;

  Public

    Procedure Draw; Override;
    Constructor Create(Owner: SP_BaseComponent);
    Destructor  Destroy; Override;
    Procedure SetTrackColour(Idx: Integer);
    Procedure SetFillColour(Idx: Integer);
    Procedure SetFillDisabledColour(Idx: Integer);
    Procedure SetMin(Value: aFloat);
    Procedure SetMax(Value: aFloat);
    Procedure SetPos(Value: aFloat);
    Procedure SetKind(Value: SP_ScrollBarKind);
    Procedure SetUIElements;

    Property TrackClr: Integer read fTrackColour write SetTrackColour;
    Property FillClr: Integer read fTrackFillColour write SetFillColour;
    Property Min: aFloat read fMin write SetMin;
    Property Max: aFloat read fMax write SetMax;
    Property Kind: SP_ScrollbarKind read fKind write SetKind;
    Property Position: aFloat read fPosition write SetPos;

End;
pSP_ProgressBar = ^SP_ProgressBar;

implementation

Constructor SP_ProgressBar.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fMin := 0;
  fMax := 0;
  fPosition := 0;
  fTrackColour := fBackgroundClr;
  fTrackFillColour := 4; // Fill with Green by default
  fTrackFillDisabledColour := 8;
  fKind := spHorizontal;

End;

Destructor SP_ProgressBar.Destroy;
Begin

End;

Procedure SP_ProgressBar.SetUIElements;
Begin

  If fKind = spHorizontal Then
    fIntPos := Trunc((Width - Height) * ((fPosition - fMin) / (fMax - fMin)))
  Else
    fIntPos := Trunc((Height - Width) * ((fPosition - fMin) / (fMax - fMin))) + Width -1;

End;

Procedure SP_ProgressBar.Draw;
Var
  c, cf: Integer;
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

End;

Procedure SP_ProgressBar.SetKind(Value: SP_ScrollBarKind);
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

Procedure SP_ProgressBar.SetTrackColour(Idx: Integer);
Begin

  fTrackColour := Idx;
  Paint;

End;

Procedure SP_ProgressBar.SetFillColour(Idx: Integer);
Begin

  fTrackFillColour := Idx;
  Paint;

End;

Procedure SP_ProgressBar.SetFillDisabledColour(Idx: Integer);
Begin

  fTrackFillDisabledColour := Idx;
  Paint;

End;

Procedure SP_ProgressBar.SetMin(Value: aFloat);
Begin

  fMin := Value;
  SetUIElements;
  Paint;

End;

Procedure SP_ProgressBar.SetMax(Value: aFloat);
Begin

  fMax := Value;
  SetUIElements;
  Paint;

End;

Procedure SP_ProgressBar.SetPos(Value: aFloat);
Begin

  fPosition := Value;
  If fPosition < fMin Then fPosition := fMin;
  If fPosition > fMax Then fPosition := fMax;
  SetUIElements;
  Paint;

End;

end.
