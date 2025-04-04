unit SP_CheckBoxUnit;

interface

Uses SP_BaseComponentUnit, SP_Util;

Type

SP_CheckBox = Class(SP_BaseComponent)

  Public

    fChecked: Boolean;
    fCaption: aString;
    fOnChecked: SP_CheckEvent;
    fType: Integer;
    fGroupIndex: Integer;
    fCheckColor: Byte;
    Procedure SetChecked(b: Boolean);
    Procedure SetCaption(s: aString);
    Procedure SetType(t: Integer);
    Procedure PerformKeyDown(Var Handled: Boolean); Override;
    Procedure DoCheck(b: Boolean);
    Procedure SetCheckColor(c: Byte);
    Procedure Draw; Override;

    Procedure MouseDown(Sender: SP_BaseComponent; X, Y, Btn: Integer); Override;

    Property Caption: aString read fCaption write SetCaption;
    Property Checked: Boolean read fChecked write SetChecked;
    Property CheckColour: Byte read fCheckColor write SetCheckColor;
    Property OnCheck: SP_CheckEvent read fOnChecked write fOnChecked;
    Property CheckType: Integer read fType write SetType;
    Property GroupIndex: Integer read fGroupIndex write fGroupIndex;

    Constructor Create(Owner: SP_BaseComponent);

End;

implementation

Uses Math, SP_Input, SP_Components, SP_Sound, SP_SysVars;

// SP_CheckBox

Constructor SP_CheckBox.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fChecked := False;
  fCheckColor := SP_UIText;
  fCaption := '';
  fTransparent := True;
  fBorder := True;

End;

Procedure SP_CheckBox.SetCheckColor(c: Byte);
Begin

  fCheckColor := c;
  Paint;

End;

Procedure SP_CheckBox.SetCaption(s: aString);
Begin

  fCaption := s;
  Paint;

End;

Procedure SP_CheckBox.SetChecked(b: Boolean);
Begin

  If fChecked <> b then Begin
    fChecked := b;
    If Assigned(fOnChecked) Then
      fOnChecked(Self);
    Paint;
  End;

End;

Procedure SP_CheckBox.SetType(t: Integer);
Begin

  fType := t;
  Paint;

End;

Procedure SP_CheckBox.Draw;
Var
  dX, dy, iH, bClr, cClr, capClr: Integer;
  iSC: aFloat;
Begin

  If Enabled Then Begin
    bClr := fBorderClr;
    cClr := fCheckColor;
    If Focused Then Begin
      capClr := SP_FocusTextClr;
      cClr := SP_FocusTextClr;
    End Else
      capClr := fFontClr;

  End Else Begin
    bClr := fDisabledFontClr;
    cClr := fDisabledFontClr;
    capClr := fDisabledFontClr;
  End;

  dX := iFW + 4;
  dY := (fHeight - iFH) Div 2;
  If fGroupIndex = 0 Then Begin
    FillRect(0, dy - 2, 3 + iFW, dY + IfH + 1, SP_UIBtnBack);
    If fBorder Then
      DrawRect(0, dy - 2, 3 + iFW, dY + IfH + 1, bClr);
    If Checked Then
      PRINT(2, dy, #246, cClr, -1, iSX, iSY, False, False, False, False);
  End Else Begin
    iSC := Min(iSX, iSY);
    iH := Min(iFW, iFH);
    If Checked Then
      PRINT(2, dy + ((iFH - iH) Div 2), #241, cClr, -1, iSC, iSC, False, False, False, False)
    Else
      PRINT(2, dy + ((iFH - iH) Div 2), #242, cClr, -1, iSC, iSC, False, False, False, False);
    Fill(4, dy + ((iFH - iH) Div 2) + 1, SP_UiBtnBack);
  End;

  PRINT(dx + (iFW Div 2), dy, Caption, capClr, -1, iSX, iSY, False, False, False, False);

End;

Procedure SP_CheckBox.PerformKeyDown(Var Handled: Boolean);
Begin

  Handled := False;
  If cLastKey = K_SPACE Then Begin
    DoCheck(Not Checked);
    Handled := True;
  End;

End;

Procedure SP_CheckBox.DoCheck(b: Boolean);
Var
  i: Integer;
Begin

  If fGroupIndex > 0 Then Begin
    If b and Not fChecked then Begin
      If Assigned(fParentControl) Then With fParentControl Do
        For i := 0 To fNumComponents -1 Do
          If fComponentList[i] <> Self Then
            If fComponentList[i] is SP_CheckBox Then
              If SP_CheckBox(fComponentList[i]).GroupIndex = fGroupIndex Then Begin
                SP_CheckBox(fComponentList[i]).fChecked := False;
                fComponentList[i].Paint;
              End;
      Checked := b;
    End;
  End Else
    Checked := b;

End;

Procedure SP_CheckBox.MouseDown(Sender: SP_BaseComponent; X, Y, Btn: Integer);
Begin

  Inherited;

  If Enabled And (Btn = 1) Then Begin
    DoCheck(Not Checked);
    SP_PlaySystem(CLICKCHAN, CLICKBANK);
  End;

End;

end.
