unit SP_ButtonUnit;

{$INCLUDE SpecBAS.inc}

interface

Uses Classes, SysUtils, Types, SP_Util, SP_BaseComponentUnit, SP_Errors;

Type

SP_ButtonState = (spNormal, spPressed);

SP_Button = Class(SP_BaseComponent)

  Private

    fCaption:    aString;
    fState:      SP_ButtonState;
    fCaptionPos: TPoint;
    fDrawShadow: Boolean;

    Procedure SetCaption(s: aString);
    Procedure SetCaptionPos(p: TPoint);
    Procedure SetState(s: SP_ButtonState);

  Public

    Procedure Draw; Override;
    Procedure PerformKeyDown(Var Handled: Boolean); Override;
    Procedure PerformKeyUp(Var Handled: Boolean); Override;
    Procedure MouseDown(Sender: SP_BaseComponent; X, Y, Btn: Integer); Override;
    Procedure MouseUp(Sender: SP_BaseComponent; X, Y, Btn: Integer); Override;
    Procedure CentreCaption;

    Property  CaptionPos: TPoint           read fCaptionPos  write SetCaptionPos;
    Property  Caption:    aString          read fCaption     write SetCaption;
    Property  State:      SP_ButtonState   read fState       write SetState;

    Constructor Create(Owner: SP_BaseComponent);

    // User Properties

    Procedure RegisterProperties; Override;
    Procedure Set_Caption(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Caption: aString;
    Procedure Set_CaptionPos(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_CaptionPos: aString;
    Procedure Set_State(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_State: aString;

End;

implementation

Uses SP_Components, SP_ScrollBarUnit, SP_SysVars, SP_Sound, SP_Input;

// SP_Button

Constructor SP_Button.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fTypeName := 'spButton';
  fShadow := True;

  If Owner is SP_ScrollBar Then Begin
    iSX := 1;
    iSY := 1;
    iFH := fH;
    iFW := fW;
    fShadow := False;
  End;

  fBorder := True;
  fState := spNormal;
  fBackgroundClr := 255; // unlikely to be used
  fTransparent := True;
  fDrawShadow := fShadow;
  Paint;

End;

Procedure SP_Button.SetCaption(s: aString);
Begin

  If fCaption <> s Then Begin
    fCaption := s;
    CentreCaption;
    Paint;
  End;

End;

Procedure SP_Button.CentreCaption;
Var
  w, h: Integer;
Begin

  If fOverrideScl Then Begin
    w := Round(fW * iSX);
    h := Round(fH * iSY);
  End Else Begin
    w := Round(iFW * iSX);
    h := Round(iFH * iSY);
  End;

  If Proportional Then
    fCaptionPos.x := Round(fWidth - (TextWidth(fCaption) * iSX)) Div 2
  Else
    fCaptionPos.x := (fWidth - (Length(fCaption) * w)) Div 2;
  fCaptionPos.y := (fHeight - h) Div 2;
  Paint;

End;

Procedure SP_Button.SetCaptionPos(p: TPoint);
Begin

  If (fCaptionPos.X <> p.X) or (fCaptionPos.Y <> p.Y) Then Begin
    fCaptionPos.x := p.x;
    fCaptionPos.y := p.y;
    Paint;
  End;

End;

Procedure SP_Button.SetState(s: SP_ButtonState);
Begin

  If fState <> s Then Begin
    fState := s;
    Paint;
  End;

End;

Procedure SP_Button.Draw;
Begin

  If fState = spNormal Then Begin

    fShadow := fDrawShadow;
    If Border Then DrawBtnFrame(fBorder, False);
    If Enabled Then
      Print(fCaptionPos.x, fCaptionPos.y, Caption, fFontClr, -1, iSX, iSY, False, False, False, False)
    Else
      Print(fCaptionPos.x, fCaptionPos.y, Caption, fDisabledFontClr, -1, iSX, iSY, False, False, False, False)

  End Else Begin

    fShadow := False;
    If Border Then DrawBtnFrame(Rect(1, 1, fWidth, fHeight), fBorder, True);
    If Enabled Then
      Print(fCaptionPos.x+Ord(Border), fCaptionPos.y+Ord(Border), Caption, fFontClr, -1, iSX, iSY, False, False, False, False)
    Else
      Print(fCaptionPos.x+Ord(Border), fCaptionPos.y+Ord(Border), Caption, fDisabledFontClr, -1, iSX, iSY, False, False, False, False);

  End;

End;

Procedure SP_Button.MouseDown(Sender: SP_BaseComponent; X, Y, Btn: Integer);
Begin

  If Enabled Then Begin
    fState := spPressed;
    SP_PlaySystem(CLICKCHAN, CLICKBANK);
    Paint;
  End;

  Inherited;

End;

Procedure SP_Button.MouseUp(Sender: SP_BaseComponent; X, Y, Btn: Integer);
Begin

  fState := spNormal;
  Paint;

  If PtInRect(Rect(0, 0, Width, Height), Point(X, Y)) Then
    Inherited;

End;

Procedure SP_Button.PerformKeyDown(Var Handled: Boolean);
Var
  NewChar: Byte;
Begin

  If not (fEnabled and fFocused) Then Exit;

  NewChar := DecodeKey(cLastKey);
  Handled := False;

  If (NewChar = 0) {$IFNDEF FPC} And (cLastKeyChar <> 1) {$ENDIF} Then Begin

    Case cLastKey of

      K_RETURN, K_SPACE:
        Begin
          if fEnabled then Begin
            fState := spPressed;
            Handled := True;
            Paint;
            SP_PlaySystem(CLICKCHAN, CLICKBANK);
          End;
        End;

    Else
      Inherited;
    End;

  End;

End;

Procedure SP_Button.PerformKeyUp(Var Handled: Boolean);
Begin

  Case cLastKey Of

    K_RETURN, K_SPACE:
      Begin
        fState := spNormal;
        Handled := True;
        Paint;
        If Assigned(OnClick) Then
          OnClick(Self);
      End;

  End;

End;

// User properties

Procedure SP_Button.RegisterProperties;
Begin

  Inherited;

  RegisterProperty('caption', Get_Caption, Set_Caption, ':s|s');
  RegisterProperty('captionpos', Get_CaptionPos, Set_CaptionPos, ':v,v|v,v');
  RegisterProperty('pressed', Get_State, Set_State, ':v|v');

End;

Procedure SP_Button.Set_Caption(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin
  Caption := s;
End;

Function SP_Button.Get_Caption: aString;
Begin
  Result := fCaption;
End;

Procedure SP_Button.Set_CaptionPos(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  xs, ys: aString;
  p: Integer;
Begin
  p := Pos(',', s);
  If p > 0 Then Begin
    xs := Copy(s, 1, p -1);
    ys := Copy(s, p +1);
    CaptionPos := Point(StringToInt(xs), StringToInt(ys));
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;
End;

Function SP_Button.Get_CaptionPos: aString;
Begin
  Result := IntToString(CaptionPos.x) + ',' + IntToString(CaptionPos.y);
End;

Procedure SP_Button.Set_State(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin
  If StringToInt(s) <> 0 Then
    State := spPressed
  Else
    If StringToInt(s) = 0 Then
      State := spNormal
  Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;
End;

Function SP_Button.Get_State: aString;
Begin
  If State = spPressed Then
    Result := '1'
  Else
    Result := '0';
End;

end.
