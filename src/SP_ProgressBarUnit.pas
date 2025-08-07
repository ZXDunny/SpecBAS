unit SP_ProgressBarUnit;

{$INCLUDE SpecBAS.inc}

interface

Uses SysUtils, Types, SP_BaseComponentUnit, SP_ButtonUnit, SP_Util, SP_Errors;

Type

SP_CapType = (spUser, spPercent, spValue);
SP_ScrollBarKind = (spHorizontal, spVertical);

SP_ProgressBar = Class(SP_BaseComponent)

  Private

    fCaption: aString;
    fCapType: SP_CapType;
    fMin, fMax, fPosition: aFloat;
    fKind: SP_ScrollbarKind;
    fCapColour,
    fCapInvColour,
    fTrackColour,
    fTrackFillColour,
    fTrackFillDisabledColour: Integer;
    fIntPos: Integer;
    fOnChange: SP_ChangeEvent;

  Public

    Procedure Draw; Override;
    Constructor Create(Owner: SP_BaseComponent);
    Destructor  Destroy; Override;
    Procedure SetCapColour(Idx: Integer);
    Procedure SetCapInvColour(Idx: Integer);
    Procedure SetTrackColour(Idx: Integer);
    Procedure SetFillColour(Idx: Integer);
    Procedure SetFillDisabledColour(Idx: Integer);
    Procedure SetMin(Value: aFloat);
    Procedure SetMax(Value: aFloat);
    Procedure SetPos(Value: aFloat);
    Procedure SetKind(Value: SP_ScrollBarKind);
    Procedure SetCaption(Str: aString);
    Procedure SetUIElements;

    Property Caption: aString read fCaption write SetCaption;
    Property CaptionClr: Integer read fCapColour write SetCapColour;
    Property CaptionInvClr: Integer read fCapInvColour write SetCapInvColour;
    Property TrackClr: Integer read fTrackColour write SetTrackColour;
    Property FillClr: Integer read fTrackFillColour write SetFillColour;
    Property Min: aFloat read fMin write SetMin;
    Property Max: aFloat read fMax write SetMax;
    Property Kind: SP_ScrollbarKind read fKind write SetKind;
    Property Position: aFloat read fPosition write SetPos;

    // User Properties

    Procedure RegisterProperties; Override;
    Procedure Set_Caption(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Caption: aString;
    Procedure Set_CapType(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_CapType: aString;
    Procedure Set_AltColor(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_AltColor: aString;
    Procedure Set_TrackColor(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_TrackColor: aString;
    Procedure Set_FillColor(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_FillColor: aString;
    Procedure Set_Min(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Min: aString;
    Procedure Set_Max(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Max: aString;
    Procedure Set_Position(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Position: aString;
    Procedure Set_Kind(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Kind: aString;

End;
pSP_ProgressBar = ^SP_ProgressBar;

implementation

Constructor SP_ProgressBar.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fTypeName := 'spProgress';

  fMin := 0;
  fMax := 0;
  fPosition := 0;
  fCapType := spPercent;
  fCapColour := 0;
  fCapInvColour := fFontClr;
  fTrackColour := fBackgroundClr;
  fTrackFillColour := 4; // Fill with Green by default
  fTrackFillDisabledColour := 8;
  fKind := spHorizontal;

End;

Destructor SP_ProgressBar.Destroy;
Begin

  Inherited;

End;

Procedure SP_ProgressBar.SetCaption(Str: aString);
Begin

  fCaption := Str;
  Paint;

End;

Procedure SP_ProgressBar.SetUIElements;
Begin

  If fKind = spHorizontal Then
    fIntPos := Trunc((Width - 2 * Ord(fBorder)) * ((fPosition - fMin) / (fMax - fMin)))
  Else
    fIntPos := Trunc((Height - 2 * Ord(fBorder)) * ((fPosition - fMin) / (fMax - fMin)));

End;

Procedure SP_ProgressBar.Draw;
Var
  c, cf, tw, tx, ty, cl: Integer;
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

  If fCaption <> '' Then Begin
    cl := fFontClr;
    tw := (Length(fCaption) * iFW) + fW;
    If fKind = spHorizontal Then Begin
      If fIntPos < tw Then Begin
        tx := fIntPos + fW;
        cl := fCapInvColour;
      End Else
        tx := fIntPos - tw;
      ty := (Height - iFH) Div 2;
    End Else Begin
      If fIntPos < iFH Then Begin
        ty := Height - 1 - fIntPos - fH;
        cl := fCapInvColour;
      End Else
        ty := Height - 1 - fIntPos + fH;
      tx := (Width - (iFW * Length(fCaption))) Div 2;
    End;
    PRINT(tx, ty, fCaption, cl, -1, iSX, iSY, False, False, False, False);
  End;

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

Procedure SP_ProgressBar.SetCapColour(Idx: Integer);
Begin

  fCapColour := Idx;
  Paint;

End;

Procedure SP_ProgressBar.SetCapInvColour(Idx: Integer);
Begin

  fCapInvColour := Idx;
  Paint;

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

  If fCapType = spPercent Then Begin
    fCaption := IntToString(Round(((fPosition - fMin)/(fMax - fMin)) * 100)) + '%';
  End Else
    If fCapType = spValue Then Begin
      fCaption := aString(aFloatToStr(fPosition));
    End;

  If Assigned(fOnChange) Then
    fOnChange(Self);

  SetUIElements;
  Paint;

End;

// User Properties

Procedure SP_ProgressBar.RegisterProperties;
Begin

  Inherited;

  RegisterProperty('caption', Get_Caption, Set_Caption, ':s|s');
  RegisterProperty('captype', Get_CapType, Set_CapType, ':v|v');
  RegisterProperty('altclr', Get_AltColor, Set_AltColor, ':v|v');
  RegisterProperty('trackclr', Get_TrackColor, Set_TrackColor, ':v|v');
  RegisterProperty('fillclr', Get_FillColor, Set_FillColor, ':v|v');
  RegisterProperty('min', Get_Min, Set_Min, ':v|v');
  RegisterProperty('max', Get_Max, Set_Max, ':v|v');
  RegisterProperty('position', Get_Position, Set_Position, ':v|v');
  RegisterProperty('kind', Get_Kind, Set_Kind, ':v|v');

End;

Procedure SP_ProgressBar.Set_Caption(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Caption := s;

End;

Function SP_ProgressBar.Get_Caption: aString;
Begin

  Result := Caption;

End;

Procedure SP_ProgressBar.Set_AltColor(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  CaptionInvClr := StringToInt(s, CaptionInvClr);

End;

Function SP_ProgressBar.Get_AltColor: aString;
Begin

  Result := IntToString(CaptionInvClr);

End;

Procedure SP_ProgressBar.Set_TrackColor(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  TrackClr := StringToInt(s, TrackClr);

End;

Function SP_ProgressBar.Get_TrackColor: aString;
Begin

  Result := IntToString(TrackClr);

End;

Procedure SP_ProgressBar.Set_FillColor(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  FillClr := StringToInt(s, FillClr);

End;

Function SP_ProgressBar.Get_FillColor: aString;
Begin

  Result := IntToString(FillClr);

End;

Procedure SP_ProgressBar.Set_Min(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Min := StrToFloatDef(String(s), Min);

End;

Function SP_ProgressBar.Get_Min: aString;
Begin

  Result := aString(FloatToStr(Min));

End;

Procedure SP_ProgressBar.Set_Max(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Max := StrToFloatDef(String(s), Max);

End;

Function SP_ProgressBar.Get_Max: aString;
Begin

  Result := aString(FloatToStr(Max));

End;

Procedure SP_ProgressBar.Set_Position(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Position := StrToFloatDef(String(s), Position);

End;

Function SP_ProgressBar.Get_Position: aString;
Begin

  Result := aString(FloatToStr(Position));

End;

Procedure SP_ProgressBar.Set_Kind(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  if s <> '' Then
    if s[1] = '0' Then
      Kind := spHorizontal
    else
      if s[1] = '1' Then
        Kind := spVertical;

End;

Function SP_ProgressBar.Get_Kind: aString;
Begin

  if Kind = spHorizontal then
    Result := '0'
  Else
    Result := '1';

End;

Procedure SP_ProgressBar.Set_CapType(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  if s <> '' Then Begin
    if s[1] = '0' Then
      fCapType := spUser
    else
      if s[1] = '1' Then
        fCapType := spPercent
      else
        if s[1] = '2' Then
          fCapType := spValue;

    Paint;

  End;

End;

Function SP_ProgressBar.Get_CapType: aString;
Begin

  Case fCapType of
    spUser: Result := '0';
    spPercent: Result := '1';
    spValue: Result := '2';
  End;

End;

end.
