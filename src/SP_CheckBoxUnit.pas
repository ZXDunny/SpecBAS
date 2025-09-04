unit SP_CheckBoxUnit;

{$INCLUDE SpecBAS.inc}

interface

Uses SP_BaseComponentUnit, SP_Util, SP_Errors;

Type

SP_CheckBox = Class(SP_BaseComponent)

  Public

    fChecked: Boolean;
    fCaption: aString;
    fOnChecked: SP_CheckEvent;
    fType: Integer;
    fGroupIndex: Integer;
    fCheckColor: Byte;

    User_OnChecked: aString;
    Compiled_OnChecked: aString;

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

    // User Properties

    Procedure RegisterProperties; Override;
    Procedure Set_Caption(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Caption: aString;
    Procedure Set_Checked(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Checked: aString;
    Procedure Set_OnChecked(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_OnChecked: aString;
    Procedure Set_GroupIndex(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_GroupIndex: aString;
    Procedure Set_CheckColor(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_CheckColor: aString;

End;

implementation

Uses Math, SP_Interpret_PostFix, SP_Input, SP_Components, SP_Sound, SP_SysVars;

// SP_CheckBox

Constructor SP_CheckBox.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fTypeName := 'spCheck';

  fChecked := False;
  fCheckColor := SP_UIText;
  fCaption := '';
  fTransparent := True;
  fBackgroundClr := 255;
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
    If Compiled_OnChecked <> '' Then
      SP_AddOnEvent(Compiled_OnChecked);
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
  dX, dy, iH, iY, bClr, cClr, capClr, cFW, cFH: Integer;
  iSC: aFloat;
Begin

  cfW := Round(iFW * iSX);
  cfH := Round(iFH * iSY);

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

  dX := cFW + 4;
  dY := (fHeight - cFH) Div 2;
  iSC := Min(iSX, iSY);
  iH := Min(cFW, cFH);
  iY := (fHeight - iH) Div 2;
  If fGroupIndex = 0 Then Begin
    FillRect(0, iy - 2, 3 + iH, iY + iH + 1, SP_UIBtnBack);
    If fBorder Then
      DrawRect(0, iy - 2, 3 + iH, iY + iH + 1, bClr);
    If Checked Then
      PRINT(2, iy, #246, cClr, -1, iSC, iSC, False, False, False, False);
  End Else Begin
    PRINT(2, dy + ((cFH - iH) Div 2), #243, SP_UiBtnBack, -1, iSC, iSC, False, False, False, False);
    If Checked Then
      PRINT(2, dy + ((cFH - iH) Div 2), #241, cClr, -1, iSC, iSC, False, False, False, False)
    Else
      PRINT(2, dy + ((cFH - iH) Div 2), #242, cClr, -1, iSC, iSC, False, False, False, False);
  End;

  PRINT(dx + (cFW Div 2), dy, Caption, capClr, -1, iSX, iSY, False, False, False, False);

End;

Procedure SP_CheckBox.PerformKeyDown(Var Handled: Boolean);
Begin

  Handled := False;

  If not (fEnabled and fFocused) Then Exit;

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

// User Properties

Procedure SP_CheckBox.RegisterProperties;
Begin

  Inherited;

  RegisterProperty('caption', Get_Caption, Set_Caption, ':s|s');
  RegisterProperty('checked', Get_Checked, Set_Checked, 'v:v|v');
  RegisterProperty('oncheck', Get_OnChecked, Set_OnChecked, 's|s');
  RegisterProperty('groupindex', Get_GroupIndex, Set_GroupIndex, 's|s');
  RegisterProperty('checkclr', Get_CheckColor, Set_CheckColor, 'v|v');

End;

Procedure SP_CheckBox.Set_Caption(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Caption := s;

End;

Function  SP_CheckBox.Get_Caption: aString;
Begin

  Result := Caption;

End;

Procedure SP_CheckBox.Set_Checked(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Checked := StringToInt(s) <> 0;

End;

Function  SP_CheckBox.Get_Checked: aString;
Begin

  Result := IntToString(Ord(Checked));

End;

Procedure SP_CheckBox.Set_OnChecked(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Compiled_OnChecked := SP_ConvertToTokens(s, Error);
  If Compiled_OnChecked <> '' Then
    User_OnChecked := s;

End;

Function  SP_CheckBox.Get_OnChecked: aString;
Begin

  Result := User_OnChecked;

End;

Procedure SP_CheckBox.Set_GroupIndex(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  GroupIndex := StringToInt(s);

End;

Function  SP_CheckBox.Get_GroupIndex: aString;
Begin

  Result := IntToString(GroupIndex);

End;

Procedure SP_CheckBox.Set_CheckColor(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  CheckColour := StringToInt(s);

End;

Function  SP_CheckBox.Get_CheckColor: aString;
Begin

  Result := IntToString(CheckColour);

End;


end.
