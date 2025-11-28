unit SP_SliderUnit;

{$INCLUDE SpecBAS.inc}

interface

Uses SysUtils, Types, SP_BaseComponentUnit, SP_ButtonUnit, SP_Util, SP_Errors;

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

    Compiled_OnChange, User_OnChange: aString;

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
    Procedure MouseDown(Sender: SP_BaseComponent; X, Y, Btn: Integer); Override;
    Procedure MouseUp(Sender: SP_BaseComponent; X, Y, Btn: Integer); Override;
    Procedure MouseMove(Sender: SP_BaseComponent; X, Y, Btn: Integer); Override;
    Procedure MouseWheel(Sender: SP_BaseComponent; X, Y, Btn, Delta: Integer); Override;

    Property OnChange: SP_ScrollEvent read fOnChange write fOnChange;
    Property TrackClr: Integer read fTrackColour write SetTrackColour;
    Property FillClr: Integer read fTrackFillColour write SetFillColour;
    Property ThumbClr: Integer read fThumbColour write SetThumbColour;
    Property Min: aFloat read fMin write SetMin;
    Property Max: aFloat read fMax write SetMax;
    Property Step: aFloat read fStep write fStep;
    Property Kind: SP_ScrollbarKind read fKind write SetKind;
    Property Position: aFloat read fPosition write SetPos;

    // User Properties

    Procedure RegisterProperties; Override;
    Procedure Set_Step(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Step: aString;
    Procedure Set_Min(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Min: aString;
    Procedure Set_Max(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Max: aString;
    Procedure Set_Pos(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Pos: aString;
    Procedure Set_Kind(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Kind: aString;
    Procedure Set_OnChange(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_OnChange: aString;
    Procedure Set_FillClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_FillClr: aString;
    Procedure Set_ThumbClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_ThumbClr: aString;
    Procedure Set_TrackClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_TrackClr: aString;

    Procedure RegisterMethods; Override;
    Procedure Method_SlideTo(Params: Array of aString; Var Error: TSP_ErrorCode);

End;
pSP_Slider = ^SP_Slider;

implementation

Uses SP_Interpret_PostFix;

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
  fShadow := True;

End;

Destructor SP_Slider.Destroy;
Begin

  Inherited;

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

  If oPos <> fPosition Then Begin
    If Assigned(OnChange) Then
      OnChange(fPosition - oPos, fPosition);
    If Not Locked And (Compiled_OnChange <> '') Then
      SP_AddOnEvent(Compiled_OnChange);
  End;

End;

Procedure SP_Slider.MouseDown(Sender: SP_BaseComponent; X, Y, Btn: Integer);
Begin

  If Btn = 1 Then Begin
    fMouseIsDown := True;
    fMousePos := Point(X, Y);
  End;

  Inherited;

End;

Procedure SP_Slider.MouseUp(Sender: SP_BaseComponent; X, Y, Btn: Integer);
Begin

  fMouseIsDown := False;
  Inherited;

End;

Procedure SP_Slider.MouseMove(Sender: SP_BaseComponent; X, Y, Btn: Integer);
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

Procedure SP_Slider.MouseWheel(Sender: SP_BaseComponent; X, Y, Btn, Delta: Integer);
Begin

  If Delta > 0 Then
    Position := fPosition + fStep
  Else
    If Delta < 0 Then
      Position := fPosition - fStep;

End;

// User Properties

Procedure SP_Slider.RegisterProperties;
Begin

  Inherited;

  RegisterProperty('step', Get_Step, Set_Step, ':v|v');
  RegisterProperty('min', Get_Min, Set_Min, ':v|v');
  RegisterProperty('max', Get_Max, Set_Max, ':v|v');
  RegisterProperty('position', Get_Pos, Set_Pos, ':v|v');
  RegisterProperty('kind', Get_Kind, Set_Kind, ':v|v');
  RegisterProperty('onchange', Get_OnChange, Set_OnChange, ':s|s');
  RegisterProperty('fillclr', Get_FillClr, Set_FillClr, ':v|v');
  RegisterProperty('trackclr', Get_TrackClr, Set_TrackClr, ':v|v');
  RegisterProperty('thumbclr', Get_ThumbClr, Set_ThumbClr, ':v|v');

End;

Procedure SP_Slider.Set_Step(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Step := StrToFloatDef(String(s), Step);

End;

Function SP_Slider.Get_Step: aString;
Begin

  Result := aString(FloatToStr(Step));

End;

Procedure SP_Slider.Set_Min(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Min := StrToFloatDef(String(s), Min);

End;

Function SP_Slider.Get_Min: aString;
Begin

  Result := aString(FloatToStr(Min));

End;

Procedure SP_Slider.Set_Max(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Max := StrToFloatDef(String(s), Max);

End;

Function SP_Slider.Get_Max: aString;
Begin

  Result := aString(FloatToStr(Max));

End;

Procedure SP_Slider.Set_Pos(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Position := StrToFloatDef(String(s), Position);

End;

Function SP_Slider.Get_Pos: aString;
Begin

  Result := aString(FloatToStr(Position));

End;

Procedure SP_Slider.Set_Kind(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  if s <> '' Then
    if s[1] = '0' Then
      Kind := spHorizontal
    else
      if s[1] = '1' Then
        Kind := spVertical;

End;

Function SP_Slider.Get_Kind: aString;
Begin

  if Kind = spHorizontal then
    Result := '0'
  Else
    Result := '1';

End;

Procedure SP_Slider.Set_OnChange(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Compiled_OnChange := SP_ConvertToTokens(s, Error);
  If Compiled_OnChange <> '' Then
    User_OnChange := s;

End;

Function SP_Slider.Get_OnChange: aString;
Begin

  Result := User_OnChange;

End;

Procedure SP_Slider.Set_FillClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  FillClr := (StringToInt(s, FillClr));

End;

Function SP_Slider.Get_FillClr: aString;
Begin

  Result := IntToString(FillClr);

End;

Procedure SP_Slider.Set_ThumbClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  ThumbClr := StringToInt(s, fTrackFillColour);

End;

Function SP_Slider.Get_ThumbClr: aString;
Begin

  Result := IntToString(ThumbClr);

End;

Procedure SP_Slider.Set_TrackClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  TrackClr := StringToInt(s, TrackClr);

End;

Function SP_Slider.Get_TrackClr: aString;
Begin

  Result := IntToString(TrackClr);

End;


Procedure SP_Slider.RegisterMethods;
Begin

  Inherited;
  RegisterMethod('slideto', 'n', Method_SlideTo);

End;

Procedure SP_Slider.Method_SlideTo(Params: Array of aString; Var Error: TSP_ErrorCode);
Begin

  Position := StringToInt(Params[0], Round(Position));

End;

end.
