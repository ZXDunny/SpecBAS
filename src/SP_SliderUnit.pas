unit SP_SliderUnit;

interface

Uses SP_BaseComponentUnit, SP_ScrollbarUnit, SP_ButtonUnit, SP_Util;

Type

SP_Slider = Class(SP_BaseComponent)

  Private

    fMin, fMax, fPosition: aFloat;
    fOnChange: SP_ScrollEvent;
    fKind: SP_ScrollbarKind;
    fThumb: SP_Button;
    fTrackColour,
    fTrackFillColour: Integer;
    fIntPos: Integer;

  Public

    Procedure Draw; Override;
    Constructor Create(Owner: SP_BaseComponent);
    Destructor  Destroy; Override;
    Procedure SetTrackColour(Idx: Integer);
    Procedure SetFillColour(Idx: Integer);
    Procedure SetMin(Value: aFloat);
    Procedure SetMax(Value: aFloat);
    Procedure SetPos(Value: aFloat);
    Procedure SetUIElements;

    Property OnChange: SP_ScrollEvent read fOnChange write fOnChange;
    Property TrackClr: Integer read fTrackColour write SetTrackColour;
    Property FillClr: Integer read fTrackFillColour write SetFillColour;
    Property Min: aFloat read fMin write SetMin;
    Property Max: aFloat read fMax write SetMax;
    Property Position: aFloat read fPosition write SetPos;

End;
pSP_Slider = ^SP_Slider;

implementation

Constructor SP_Slider.Create(Owner: SP_BaseComponent);
Begin

  fMin := 0;
  fMax := 0;
  fKind := spHorizontal;
  fThumb := SP_Button.Create(Self);

End;

Destructor SP_Slider.Destroy;
Begin

  fThumb.Free;

End;

Procedure SP_Slider.SetUIElements;
Begin

//  fIntPos :=

End;

Procedure SP_Slider.Draw;
Begin

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
  SetUIElements;
  Paint;

  If oPos <> fPosition Then
    If Assigned(OnChange) Then
      OnChange(fPosition - oPos, fPosition);

End;

end.
