unit SP_RadioGroupUnit;

{$INCLUDE SpecBAS.inc}

interface

Uses SP_Util, SP_BaseComponentUnit, SP_CheckBoxUnit, SP_Errors;

Type

SP_RadioGroup = Class(SP_BaseComponent)

  Public

    fItems: Array of SP_CheckBox;
    fCaption: aString;
    fOnSelect: SP_LBSelectEvent;
    fItemIndex: Integer;
    fCheckColor: Byte;
    IsRadioGroup: Boolean;

    Compiled_OnSelect,
    User_OnSelect: aString;

    Function  GetCount: Integer;
    Procedure PlaceItems;
    Procedure SetCaption(s: aString);
    Function  GetItemCaption(Index: Integer): aString;
    Procedure SetItemCaption(Index: Integer; s: aString);
    Procedure SetBackgroundClr(c: Byte); Override;
    Procedure SetFontClr(c: Byte); Override;
    Procedure SetCheckColor(c: Byte);
    Procedure SetItemIndex(v: Integer);
    Procedure Draw; Override;
    Procedure SelectItem(Sender: SP_BaseComponent);

    Procedure AddItem(Caption: aString);
    Procedure InsertItem(Caption: aString; Index: Integer);
    Procedure DeleteItem(Index: Integer);
    Procedure MoveItem(Item1, Item2: Integer);
    Procedure Clear;

    Property  Count: Integer read GetCount;
    Property  ItemIndex: Integer read fItemIndex write SetItemIndex;
    Property  Caption: aString read fCaption write SetCaption;
    Property  Items[Index: Integer]: aString read GetItemCaption write SetItemCaption;
    Property  OnSelect: SP_LBSelectEvent read fOnSelect write fOnSelect;
    Property  CheckColour: Byte read fCheckColor write SetCheckColor;

    Constructor Create(Owner: SP_BaseComponent);
    Destructor Destroy; Override;

    // User Properties

    Procedure RegisterProperties; Override;
    Procedure Set_Caption(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Caption: aString;
    Procedure Set_OnSelect(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_OnSelect: aString;
    Procedure Set_CheckColor(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_CheckColor: aString;
    Procedure Set_Index(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Index: aString;
    Procedure Set_Item(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Item: aString;
    Function  Get_Count: aString;
    Function  Get_IndexOf: aString;

    Procedure RegisterMethods; Override;
    Procedure Method_AddItem(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_InsertItem(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_EraseItem(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Clear(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_MoveItem(Params: Array of aString; Var Error: TSP_ErrorCode);

End;

implementation

Uses SP_Components, SP_Interpret_PostFix;

// SP_RadioGroup

Constructor SP_RadioGroup.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fTypeName := 'spGroup';

  fCaption := '';
  fTransparent := True;
  fBackgroundClr := 255;
  IsRadioGroup := True;

End;

Destructor SP_RadioGroup.Destroy;
Begin

  Inherited;

End;

Function SP_RadioGroup.GetCount: Integer;
Begin

  Result := Length(fItems);

End;

Procedure SP_RadioGroup.PlaceItems;
Var
  iy, y, i, ht, hm, cFW, cFH: Integer;
  sp: aFloat;
Begin

  cFH := Round(iFH * iSY);
  cFW := Round(IfW * iSX);

  iy := cFH;
  If fBorder Then Begin
    If IsRadioGroup And (Caption <> '') Then Begin
      ht := Height - Round(cFH * 2.5);
      Inc(iY, Round(cFH / 2));
    End Else Begin
      ht := Height - Round(cFH * 2);
    End;
  End Else
    ht := Height;

  If Count > 0 Then Begin

    sp := (ht - (count * cFH)) / (count + 1);
    hm := Ord(Not IsRadioGroup) * 4;
    y := iy + Round(sp);
    For i := 0 To Count -1 Do Begin
      If fBorder Then
        fItems[i].SetBounds(cFW, y, Width - cFW -1, cFH + hm + 1)
      Else
        fItems[i].SetBounds(0, y, Width -1, cFH + hm);
      Inc(y, Round(cfH + sp));
    End;
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

Procedure SP_RadioGroup.SelectItem(Sender: SP_BaseComponent);
var
  i: Integer;
Begin

  i := 0;
  While i < Length(fItems) Do Begin
    If fItems[i].Checked Then Begin
      fItemIndex := i;
      If Assigned(fOnSelect) Then
        fOnSelect(Self, i);
      If Not Locked And (Compiled_OnSelect <> '') Then
        SP_AddOnEvent(Compiled_OnSelect);
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
      If Not Locked And (Compiled_OnSelect <> '') Then
        SP_AddOnEvent(Compiled_OnSelect);
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
  fItems[l].fShadowClr := ShadowClr;
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
  fItems[Index].fShadowClr := ShadowClr;
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
  i: Integer;
Begin

  DrawGroupBorder(Caption);

  For i := Length(fItems) -1 DownTo 0 Do
    fItems[i].Paint;

End;

Procedure SP_RadioGroup.MoveItem(Item1, Item2: Integer);
Begin

  InsertItem(fItems[Item1].Caption, Item2);
  If Item1 > Item2 Then Inc(Item1);
  DeleteItem(Item1);

End;

// User properties

Procedure SP_RadioGroup.RegisterProperties;
Begin

  Inherited;

  RegisterProperty('caption', Get_Caption, Set_Caption, ':s|s');
  RegisterProperty('onselect', Get_OnSelect, Set_OnSelect, ':s|s');
  RegisterProperty('checkclr', Get_CheckColor, Set_CheckColor, ':v|v');
  RegisterProperty('count', Get_Count, nil, ':v');
  RegisterProperty('item', Get_Item, Set_Item, 'v:s|v:s');
  RegisterProperty('index', Get_Index, Set_Index, ':v|v');
  RegisterProperty('find', Get_IndexOf, nil, 's:v');

End;

Procedure SP_RadioGroup.Set_Caption(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Caption := s;

End;

Function  SP_RadioGroup.Get_Caption: aString;
Begin

  Result := Caption;

End;

Procedure SP_RadioGroup.Set_CheckColor(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  CheckColour := StringToInt(s);

End;

Function  SP_RadioGroup.Get_CheckColor: aString;
Begin

  Result := IntToString(CheckColour);

End;

Procedure SP_RadioGroup.Set_Item(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, p: Integer;
Begin

  p := Pos(':', s);
  If p >= 0 Then Begin
    Idx := StringToInt(Copy(s, 1, p -1)) -1;
    s := Copy(s, p +1);
    If (Idx >= 0) And (Idx < Count) Then
      fItems[Idx].Caption := s;
    Paint;
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function SP_RadioGroup.Get_Item: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < Count) Then
    Result := fItems[Idx].Caption;

End;

Function SP_RadioGroup.Get_IndexOf: aString;
Var
  Idx: Integer;
Begin

  Idx := 0;
  Result := '-1';
  fUserParam := Lower(fUserParam);
  While Idx < Count Do Begin
    If Lower(fItems[Idx].Caption) = fUserParam Then Begin
      Result := IntToString(Idx +1);
      Exit;
    End Else
      Inc(Idx);
  End;

End;

Procedure SP_RadioGroup.Set_Index(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  ItemIndex := StringToInt(s) -1;

End;

Function SP_RadioGroup.Get_Index: aString;
Begin

  Result := IntToString(ItemIndex +1);

End;

Procedure SP_RadioGroup.Set_OnSelect(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Compiled_OnSelect := SP_ConvertToTokens(s, Error);
  If Compiled_OnSelect <> '' Then
    User_OnSelect := s;

End;

Function SP_RadioGroup.Get_OnSelect: aString;
Begin

  Result := User_OnSelect;

End;

Function SP_RadioGroup.Get_Count: aString;
Begin

  Result := IntToString(Count);

End;


// User Methods

Procedure SP_RadioGroup.RegisterMethods;
Begin

  Inherited;
  RegisterMethod('add', 'S', Method_AddItem);
  RegisterMethod('insert', 'ns', Method_InsertItem);
  RegisterMethod('erase', 'n', Method_EraseItem);
  RegisterMethod('clear', '', Method_Clear);
  RegisterMethod('move', 'nn', Method_MoveItem);

End;

Procedure SP_RadioGroup.Method_AddItem(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
Begin

  For i := 0 To Length(Params) -1 do
    AddItem(Params[i]);

End;

Procedure SP_RadioGroup.Method_InsertItem(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
Begin

  i := StringToInt(Params[0], 0) -1;
  If (i >= 0) And (i < Count) then
    InsertItem(Params[1], i)
  Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Procedure SP_RadioGroup.Method_EraseItem(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
Begin

  i := StringToInt(Params[0], 0) -1;
  If (i >= 0) And (i < Count) then
    DeleteItem(i)
  Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Procedure SP_RadioGroup.Method_Clear(Params: Array of aString; Var Error: TSP_ErrorCode);
Begin

  Clear;

End;

Procedure SP_RadioGroup.Method_MoveItem(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i, j: Integer;
Begin

  i := StringToInt(Params[0], 0) -1;
  j := StringToInt(Params[1], 0) -1;
  If (i >= 0) And (i < Count) And (j >= 0) And (j < Count) Then
    MoveItem(i, j);

End;

end.
