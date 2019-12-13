unit SP_ButtonUnit;

interface

Uses Classes, SysUtils, Types, SP_Util, SP_BaseComponentUnit;

Type

SP_ButtonState = (spNormal, spPressed);

SP_Button = Class(SP_BaseComponent)

  Private

    fCaption:    aString;
    fState:      SP_ButtonState;
    fCaptionPos: TPoint;

    Procedure SetCaption(s: aString);
    Procedure SetCaptionPos(p: TPoint);
    Procedure SetState(s: SP_ButtonState);
    Procedure Draw; Override;

  Public

    Procedure MouseDown(X, Y, Btn: Integer); Override;
    Procedure MouseUp(X, Y, Btn: Integer); Override;
    Procedure CentreCaption;

    Property CaptionPos: TPoint           read fCaptionPos  write SetCaptionPos;
    Property Caption:    aString          read fCaption     write SetCaption;
    Property State: SP_ButtonState        read fState       write SetState;

    Constructor Create(Owner: SP_BaseComponent);

End;

implementation

Uses SP_Components, SP_ScrollBarUnit, SP_SysVars, SP_Sound;

// SP_Button

Constructor SP_Button.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  If Owner is SP_ScrollBar Then Begin
    iSX := 1;
    iSY := 1;
    iFH := FONTHEIGHT;
    iFW := FONTWIDTH;
  End;

  fBorder := True;
  fState := spNormal;
  fBackgroundClr := SP_UIBtnBack;
  fTransparent := False;
  Paint;

End;

Procedure SP_Button.SetCaption(s: aString);
Begin

  If fCaption <> s Then Begin
    fCaption := s;
    Paint;
  End;

End;

Procedure SP_Button.CentreCaption;
Var
  w, h: Integer;
Begin

  If fOverrideScl Then Begin
    w := FONTWIDTH;
    h := FONTHEIGHT;
  End Else Begin
    w := iFW;
    h := iFH;
  End;

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

    If Border Then DrawBtnFrame(fBorder, False);
    If Enabled Then
      Print(fCaptionPos.x, fCaptionPos.y, Caption, fFontClr, -1, iSX, iSY, False, False)
    Else
      Print(fCaptionPos.x, fCaptionPos.y, Caption, fDisabledFontClr, -1, iSX, iSY, False, False)

  End Else Begin

    If Border Then DrawBtnFrame(fBorder, True);
    If Enabled Then
      Print(fCaptionPos.x+Ord(Border), fCaptionPos.y+Ord(Border), Caption, fFontClr, -1, iSX, iSY, False, False)
    Else
      Print(fCaptionPos.x+Ord(Border), fCaptionPos.y+Ord(Border), Caption, fDisabledFontClr, -1, iSX, iSY, False, False);

  End;

End;

Procedure SP_Button.MouseDown(X, Y, Btn: Integer);
Begin

  If Enabled Then Begin
    fState := spPressed;
    SP_PlaySystem(CLICKCHAN, CLICKBANK);
    Paint;
  End;

  Inherited;

End;

Procedure SP_Button.MouseUp(X, Y, Btn: Integer);
Begin

  fState := spNormal;
  Paint;

  Inherited;

End;


end.
