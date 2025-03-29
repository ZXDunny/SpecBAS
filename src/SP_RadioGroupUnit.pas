unit SP_RadioGroupUnit;

interface

Uses SP_Util, SP_BaseComponentUnit, SP_CheckBoxUnit;

Type

SP_RadioGroup = Class(SP_BaseComponent)

  Public

    fItems: Array of SP_CheckBox;
    fCaption: aString;
    fOnSelect: SP_LBSelectEvent;
    fItemIndex: Integer;
    fCheckColor: Byte;
    IsRadioGroup: Boolean;
    Procedure PlaceItems;
    Procedure SetCaption(s: aString);
    Function  GetItemCaption(Index: Integer): aString;
    Procedure SetItemCaption(Index: Integer; s: aString);
    Procedure SetBackgroundClr(c: Byte); Override;
    Procedure SetFontClr(c: Byte); Override;
    Procedure SetCheckColor(c: Byte);
    Procedure SetItemIndex(v: Integer);
    Procedure Draw; Override;
    Procedure SelectItem;

    Procedure AddItem(Caption: aString);
    Procedure InsertItem(Caption: aString; Index: Integer);
    Procedure DeleteItem(Index: Integer);
    Procedure Clear;

    Property  ItemIndex: Integer read fItemIndex write SetItemIndex;
    Property  Caption: aString read fCaption write SetCaption;
    Property  Items[Index: Integer]: aString read GetItemCaption write SetItemCaption;
    Property  OnSelect: SP_LBSelectEvent read fOnSelect write fOnSelect;
    Property  CheckColour: Byte read fCheckColor write SetCheckColor;
    Constructor Create(Owner: SP_BaseComponent);
    Destructor Destroy; Override;

End;

implementation

Uses SP_Components;

// SP_RadioGroup

Constructor SP_RadioGroup.Create(Owner: SP_BaseComponent);
Begin

  Inherited;
  fCaption := '';
  fTransparent := True;
  IsRadioGroup := True;

End;

Destructor SP_RadioGroup.Destroy;
Begin

  Inherited;

End;

Procedure SP_RadioGroup.PlaceItems;
Var
  y, i, ht, hm, ni: Integer;
  sp: aFloat;
Begin

  If fBorder or (Caption <> '') Then
    ht := Height - Round(iFH * 2)
  Else
    ht := Height;

  ni := Length(fItems);
  sp := ht/ni;
  y := Round(sp/2) - (iFH Div 2);
  if fCaption <> '' Then
    Inc(y, Round(iFH * 1.25));
  hm := Ord(Not IsRadioGroup) * 4;
  For i := 0 To ni -1 Do Begin
    If fBorder Then
      fItems[i].SetBounds(iFW, y, Width - iFW -1, iFH + hm)
    Else
      fItems[i].SetBounds(0, y, Width -1, iFH + hm);
    Inc(y, Round(sp));
  End;

End;

Procedure SP_RadioGroup.SetCheckColor(c: Byte);
Var
  i: Integer;
Begin

  For i := 0 To Length(fItems) -1 Do
    fItems[i].CheckColour := c;

  Paint;

End;

Function  SP_RadioGroup.GetItemCaption(Index: Integer): aString;
Begin

  Result := '';
  If (Index >= 0) And (Index < Length(fItems)) Then
    Result := fItems[Index].Caption;

End;

Procedure SP_RadioGroup.SetItemCaption(Index: Integer; s: aString);
Begin

  If (Index >= 0) And (Index < Length(fItems)) Then
    fItems[Index].Caption := s;
  Paint;

End;

Procedure SP_RadioGroup.SelectItem;
var
  i: Integer;
Begin

  i := 0;
  While i < Length(fItems) Do Begin
    If fItems[i].Checked Then Begin
      fItemIndex := i;
      If Assigned(fOnSelect) Then
        fOnSelect(Self, i);
    End;
    Inc(i);
  End;
  Paint;

End;

Procedure SP_RadioGroup.SetItemIndex(v: Integer);
var
  i: Integer;
Begin

  i := 0;
  While i < Length(fItems) Do Begin
    If i = v Then Begin
      fItems[i].Checked := True;
      fItemIndex := i;
      If Assigned(fOnSelect) Then
        fOnSelect(Self, i);
    End Else
      fItems[i].Checked := False;
    Inc(i);
  End;
  Paint;

End;

Procedure SP_RadioGroup.AddItem(Caption: aString);
Var
  l: Integer;
Begin

  l := Length(fItems);
  SetLength(fItems, l +1);
  fItems[l] := SP_CheckBox.Create(Self);
  fItems[l].Caption := Caption;
  fItems[l].OnCheck := SelectItem;
  fItems[l].fChecked := IsRadioGroup And (Length(fItems) = 1);
  fItems[l].GroupIndex := Ord(IsRadioGroup);
  fItems[l].CheckColour := fCheckColor;
  fItems[l].fBorder := Not IsRadioGroup;
  If fItems[l].Checked Then fItemIndex := l;
  PlaceItems;
  Paint;

End;

Procedure SP_RadioGroup.InsertItem(Caption: aString; Index: Integer);
Var
  l, i: Integer;
Begin

  l := Length(fItems);
  SetLength(fItems, l +1);
  If index >= Length(fItems) Then
    Index := l;

  For i := l DownTo Index +1 Do
    fItems[i] := fItems[i -1];

  fItems[index] := SP_CheckBox.Create(Self);
  fItems[Index].Caption := Caption;
  fItems[Index].OnCheck := SelectItem;
  fItems[Index].fChecked := IsRadioGroup And (Length(fItems) = 1);
  fItems[Index].CheckColour := fCheckColor;
  fItems[Index].GroupIndex := Ord(IsRadioGroup);
  fItems[Index].fBorder := Not IsRadioGroup;
  If fItems[Index].Checked Then fItemIndex := Index;
  PlaceItems;
  Paint;

End;

Procedure SP_RadioGroup.DeleteItem(Index: Integer);
Var
  i: Integer;
Begin

  If (Index >= 0) and (Index < Length(fItems)) Then Begin
    fItems[Index].Free;
    For i := Index To Length(fItems) -2 Do
      fItems[i] := fItems[i +1];
    SetLength(fItems, Length(fItems) -1);
    PlaceItems;
    Paint;
  End;

End;

Procedure SP_RadioGroup.Clear;
Var
  i: Integer;
Begin

  For i := 0 To Length(fItems) -1 Do
    fItems[i].Free;
  SetLength(fItems, 0);
  PlaceItems;
  Paint;

End;

Procedure SP_RadioGroup.SetCaption(s: aString);
Begin

  fCaption := s;
  PlaceItems;
  Paint;

End;

Procedure SP_RadioGroup.SetBackgroundClr(c: Byte);
Var
  i: Integer;
Begin

  Inherited;
  For i := 0 To Length(fItems) -1 Do
    fItems[i].BackgroundClr := c;

End;

Procedure SP_RadioGroup.SetFontClr(c: Byte);
Var
  i: Integer;
Begin

  Inherited;
  For i := 0 To Length(fItems) -1 Do
    fItems[i].FontClr := c;

End;

Procedure SP_RadioGroup.Draw;
Var
  yo, i: Integer;
Begin

  If fBorder Then Begin
    yo := Round(iFH/2);
    Drawline(0, yo, iFW Div 2, yo, fBorderClr);
    Drawline(((Length(fCaption) +1) * iFW) + (iFW Div 2), yo, Width -1, yo, fBorderClr);
    Drawline(Width -1, yo, Width -1, Height -1, fBorderClr);
    Drawline(0, Height -1, Width -1, Height -1, fBorderClr);
    Drawline(0, yo, 0, Height -1, fBorderClr);
    If fCaption <> '' Then
      PRINT(ifW, 0, fCaption, fFontClr, -1, iSX, iSY, False, False, False, False);
  End Else Begin
    If fCaption <> '' Then
      PRINT(0, 0, fCaption, fFontClr, -1, iSX, iSY, False, False, False, False);
  End;

  For i := 0 To Length(fItems) -1 Do
    fItems[i].Paint;

End;

end.
