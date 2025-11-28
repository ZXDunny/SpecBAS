unit SP_ComboBoxUnit;

{$INCLUDE SpecBAS.inc}

interface

Uses SP_Components, SP_BaseComponentUnit, SP_Util, SP_PopUpMenuUnit, SP_EditUnit, SP_LabelUnit, SP_ButtonUnit, SP_SysVars, SP_Errors;

Type

SP_ComboBox = Class(SP_BaseComponent)

  Private

    Menu: SP_PopUpMenu;
    Edit: SP_Edit;
    Labl: SP_Label;
    Btn: SP_Button;
    fItemIndex: Integer;
    fEditable: Boolean;
    fOnAccept: SP_EditEvent;
    fOnChange: SP_EditEvent;

    User_OnAccept,
    User_OnChange,
    Compiled_OnAccept,
    Compiled_OnChange: aString;

    Procedure PlaceItems;
    Procedure OnBtnClick(Sender: SP_BaseComponent);
    Procedure OnMenuSelect(Sender: SP_BaseComponent; ItemIndex: Integer);
    Function  GetBorder: Boolean;
    Procedure SetBorder(b: Boolean);
    Procedure SetItemIndex(i: Integer);
    Procedure SetEditable(b: Boolean);
    Procedure SetText(s: aString);
    Function  GetText: aString;
    Procedure EditAccept(Sender: SP_BaseComponent; Text: aString);
    Procedure EditChange(Sender: SP_BaseComponent; Text: aString);
    Function  GetCaption(Index: Integer): aString;
    Procedure SetCaption(Index: Integer; s: aString);
    Procedure LabMouseDown(Sender: SP_BaseComponent; X, Y, Btn: Integer);
    Procedure LabMouseUp(Sender: SP_BaseComponent; X, Y, Btn: Integer);

  Public

    Procedure Draw; Override;
    Procedure PerformKeyDown(Var Handled: Boolean); Override;
    Procedure PerformKeyUp(Var Handled: Boolean); Override;
    Procedure SetBackgroundClr(c: Byte); Override;
    Procedure SetFontClr(c: Byte); Override;
    Procedure SetShadowClr(c: Byte); Override;
    Procedure SetHighlightClr(c: Byte); Override;
    Procedure SetDisabledFontClr(c: Byte); Override;
    Procedure SetChainControl(c: SP_BaseComponent); Override;
    Procedure SetOnFocus(e: SP_FocusEvent); Override;
    Procedure SetAllowLiterals(b: Boolean);
    Function  GetAllowLiterals: Boolean;

    Procedure AddStrings(Strings: TStringlist);
    Procedure AddItem(Caption: aString);
    Procedure InsertItem(Caption: aString; Index: Integer);
    Procedure DeleteItem(Index: Integer);
    Procedure Clear;
    Procedure SetBounds(x, y, w, h: Integer); Override;
    Procedure SetFocus(b: Boolean); Override;
    Function  GetCount: Integer;

    Property  Border:     Boolean            read GetBorder        write SetBorder;
    Property  Count:      Integer            read GetCount;
    Property  Items[Index: Integer]: aString read GetCaption       write SetCaption;
    Property  ItemIndex:  Integer            read fItemIndex       write SetItemIndex;
    Property  Editable:   Boolean            read fEditable        write SetEditable;
    Property  Text:       aString            read GetText          write SetText;
    Property  OnAccept:   SP_EditEvent       read fOnAccept        write fOnAccept;
    Property  OnChange:   SP_EditEvent       read fOnChange        write fOnChange;
    Property  HightlightColour: Byte         read fHighlightClr    write SetHighlightClr;
    Property  AllowLiterals: Boolean         read GetAllowLiterals write SetAllowLiterals;

    Constructor Create(Owner: SP_BaseComponent);
    Destructor Destroy; Override;

    Procedure RegisterProperties; Override;
    Procedure Set_Border(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Border: aString;
    Function  Get_Count: aString;
    Function  Get_IndexOf: aString;
    Procedure Set_Item(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Item: aString;
    Procedure Set_Index(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Index: aString;
    Procedure Set_Editable(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Editable: aString;
    Procedure Set_Text(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Text: aString;
    Procedure Set_OnAccept(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_OnAccept: aString;
    Procedure Set_OnChange(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_OnChange: aString;
    Procedure Set_HilightClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_HilightClr: aString;

    Procedure RegisterMethods; Override;
    Procedure Method_AddItem(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_InsertItem(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_EraseItem(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_Clear(Params: Array of aString; Var Error: TSP_ErrorCode);
    Procedure Method_MoveItem(Params: Array of aString; Var Error: TSP_ErrorCode);

End;

implementation

Uses Math, SP_Interpret_PostFix, SP_Input, SP_Sound;

// SP_Combobox

Constructor SP_ComboBox.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fTypeName := 'spDropDown';

  Transparent := True;
  fBackGroundClr := 3;
  Edit := SP_Edit.Create(Self);
  Edit.Visible := False;
  fEditable := False;
  Labl := SP_Label.Create(Self);
  Labl.OnMouseDown := LabMouseDown;
  Labl.OnMouseUp := LabMouseUp;
  Labl.fAlign := 0;
  Labl.Transparent := False;
  Menu := SP_PopUpMenu.Create(Owner, nil);
  ChainControl := Edit;
  Edit.ChainControl := Self;
  Edit.OnAccept := EditAccept;
  Edit.OnChange := EditChange;
  Edit.AllowLiterals := False;
  Edit.fShadow := False;
  Btn := SP_Button.Create(Self);
  Btn.OnClick := OnBtnClick;
  Btn.OverrideScaling := True;
  Btn.Enabled := False;
  Btn.fShadow := False;
  Btn.Transparent := True;
  Border := True;
  CanFocus := True;
  fItemIndex := -1;
  fShadow := True;

End;

Destructor SP_ComboBox.Destroy;
Begin

  Inherited;

End;

Function  SP_ComboBox.GetCount: Integer;
Begin

  Result := Length(Menu.fItems);

End;

Procedure SP_ComboBox.SetAllowLiterals(b: Boolean);
Begin

  Edit.AllowLiterals := b;

End;

Function  SP_ComboBox.GetAllowLiterals: Boolean;
Begin

  Result := Edit.AllowLiterals;

End;

Procedure SP_ComboBox.SetOnFocus(e: SP_FocusEvent);
Begin

  fOnFocus := e;
  Menu.OnFocus := e;
  Edit.OnFocus := e;
  Btn.OnFocus := e;

End;

Procedure SP_ComboBox.SetChainControl(c: SP_BaseComponent);
Begin

  Edit.ChainControl := c;
  Menu.ChainControl := c;
  Inherited;

End;

Procedure SP_ComboBox.SetFocus(b: Boolean);
Begin

  If fEditable Then
    Edit.SetFocus(b)
  Else
    Btn.SetFocus(b);

End;

Procedure SP_ComboBox.SetBackgroundClr(c: Byte);
Begin

  Edit.BackgroundClr := c;
  Menu.BackgroundClr := c;
  Labl.BackgroundClr := c;
  Btn.BackgroundClr := c;

  If c = 3 then // Ensure we get a proper transparency if the user selects index 3 as the background.
    c := 4
  else
    c := 3;
  Inherited;

End;

Procedure SP_ComboBox.SetShadowClr(c: Byte);
Begin

  Edit.ShadowClr := c;
  Menu.ShadowClr := c;
  Labl.ShadowClr := c;
  Btn.ShadowClr := c;
  Inherited;

End;

Procedure SP_ComboBox.SetFontClr(c: Byte);
Begin

  Edit.FontClr := c;
  Menu.FontClr := c;
  Labl.FontClr := c;
  Btn.FontClr := c;
  Inherited;

End;

Procedure SP_ComboBox.SetDisabledFontClr(c: Byte);
Begin

  Edit.DisabledFontClr := c;
  Menu.DisabledFontClr := c;
  Labl.DisabledFontClr := c;
  Btn.DisabledFontClr := c;
  Inherited;

End;

Procedure SP_ComboBox.SetHighlightClr(c: Byte);
Begin

  Menu.HighlightClr := c;
  Paint;

End;

Procedure SP_ComboBox.AddStrings(Strings: TStringlist);
Var
  i: Integer;
Begin
  Lock;
  For i := 0 To Strings.Count -1 Do
    AddItem(Strings[i]);
  Unlock;
End;

Procedure SP_ComboBox.AddItem(Caption: aString);
Begin

  Menu.AddItem(CreateItem(Caption, True, True, False, False, '', Nil, OnMenuSelect));
  If Menu.fCount = 1 Then ItemIndex := 0;
  Btn.Enabled := Menu.fCount > 1;
  Paint;

End;

Procedure SP_ComboBox.InsertItem(Caption: aString; Index: Integer);
Begin

  Menu.InsertItem(CreateItem(Caption, True, True, False, False, '', Nil, OnMenuSelect), Index);
  If Menu.fCount = 1 Then ItemIndex := 0;
  Btn.Enabled := Menu.fCount > 1;
  Paint;

End;

Procedure SP_ComboBox.DeleteItem(Index: Integer);
Begin

  Menu.DeleteItem(Index);
  If Menu.fCount = 1 Then ItemIndex := 0;
  Btn.Enabled := Menu.fCount > 1;
  Paint;

End;

Procedure SP_ComboBox.Clear;
Var
  i: Integer;
Begin

  Lock;
  For i := 0 To Length(Menu.fItems) -1 Do
    DeleteItem(0);
  Unlock;
  Paint;

End;

Function SP_ComboBox.GetCaption(Index: Integer): aString;
Begin

  Result := '';
  If (Index >= 0) and (Index < Menu.Count) Then
    Result := Menu.MenuItems[Index].Caption;

End;

Procedure SP_ComboBox.SetCaption(Index: Integer; s: aString);
Begin

  If (Index >= 0) and (Index < Menu.Count) Then
    Menu.fItems[Index].Caption := s;

End;

Procedure SP_ComboBox.SetBounds(x, y, w, h: Integer);
Begin

  If Assigned(Menu) Then Begin

    h := Max(ifH, Edit.Height);
    Menu.MinWidth := w + 1;
    Inherited;

    PlaceItems;

  End;

End;

Procedure SP_ComboBox.PlaceItems;
Begin

  DoErase;

  Btn.SetBounds(Width - Height, 0, Height, Height);
  Btn.Caption := #252;
  Btn.CentreCaption;

  Edit.SetBounds(0, 0, Width - Height + 1, Height -1);
  Labl.SetBounds(0, 0, Width - Height + 1, Edit.Height);

  Edit.Visible := Editable;
  Labl.Visible := Not Editable;

End;

Procedure SP_ComboBox.Draw;
Begin

  FillRect(0, 0, fWidth, fHeight, fBackgroundClr);

End;

Procedure SP_ComboBox.OnBtnClick;
Begin

  If Menu.fCount > 0 Then
    Menu.PopUp(Left, Top + Height + (Ord(Not fBorder) * 2) -1);

End;

Function SP_ComboBox.GetBorder: Boolean;
begin
  Result := fBorder;
end;

Procedure SP_ComboBox.SetBorder(b: Boolean);
begin

  fBorder := b;
  Btn.Border := b;
  Edit.Border := b;
  Labl.Border := b;
  Menu.Border := b;
  PlaceItems;
  Paint;

end;

Procedure SP_ComboBox.OnMenuSelect(Sender: SP_BaseComponent; ItemIndex: Integer);
begin

  Text := Menu.fItems[Menu.fSelected].Caption;
  If Editable Then Begin
    Edit.SetFocus(True);
    Edit.SelectAll;
  End Else
    SetFocus(True);

end;

Procedure SP_ComboBox.SetItemIndex(i: Integer);
Begin

  If (i >= 0) and (i < Length(Menu.fItems)) Then Begin
    SetText(Menu.fItems[i].Caption);
    If Editable Then Begin
      Edit.SetFocus(True);
      Edit.SelectAll;
    End Else
      SetFocus(True);
    fItemIndex := i;
  End;

End;

Procedure SP_ComboBox.SetEditable(b: Boolean);
Begin

  Edit.Editable := b;
  fEditable := b;
  PlaceItems;

End;

Procedure SP_ComboBox.SetText(s: aString);
Var
  i: Integer;
Begin

  fItemIndex := -1;
  For i := 0 To Length(Menu.fItems) -1 Do
    if Lower(Menu.fItems[i].Caption) = Lower(s) Then Begin
      fItemIndex := i;
      Break;
    End;

  Edit.Text := s;
  Labl.Caption := s;

End;

Procedure SP_ComboBox.LabMouseDown(Sender: SP_BaseComponent; X, Y, Btn: Integer);
begin

  SP_PlaySystem(CLICKCHAN, CLICKBANK);
  Self.btn.State := spPressed;

end;

Procedure SP_ComboBox.LabMouseUp(Sender: SP_BaseComponent; X, Y, Btn: Integer);
Begin

  Self.btn.State := spNormal;
  OnBtnClick(Self);

end;

Function  SP_ComboBox.GetText: aString;
Begin

  Result := Edit.Text;

End;

Procedure SP_ComboBox.EditAccept;
begin

  If Assigned(fOnAccept) Then
    fOnAccept(Self, Edit.Text);
  If Compiled_OnAccept <> '' Then
    SP_AddOnEvent(Compiled_OnAccept);

end;

Procedure SP_ComboBox.EditChange;
begin

  If Assigned(fOnChange) Then
    fOnChange(Self, Edit.Text);
  If Not Locked And (Compiled_OnChange <> '') Then
    SP_AddOnEvent(Compiled_OnChange);

end;

Procedure SP_ComboBox.PerformKeyDown(Var Handled: Boolean);
Var
  i: Integer;
  NewChar: Byte;
Begin

  If not (fEnabled and fFocused) Then Exit;

  NewChar := DecodeKey(cLastKey);
  Handled := False;

  If (NewChar = 0) {$IFNDEF FPC} And (cLastKeyChar <> 1) {$ENDIF} Then Begin

    Case cLastKey of

      K_UP, K_DOWN, K_HOME, K_END:
        Begin
          Case cLastKey Of
            K_UP: i := Max(fItemIndex -1, 0);
            K_DOWN: i := Min(fItemIndex +1, Length(Menu.fItems) -1);
            K_HOME: i := 0;
            K_END: i := Length(Menu.fItems) -1;
          Else
            i := -1;
          End;
          ItemIndex := i;
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          Handled := True;
        End;

    Else
      Begin
        Edit.PerformKeyDown(Handled);
        If Not Handled Then
          Inherited;
      End;
    End;

  End Else

    Edit.PerformKeyDown(Handled);

  Paint;

End;

Procedure SP_ComboBox.PerformKeyUp(Var Handled: Boolean);
begin

  Edit.PerformKeyUp(Handled);

end;

// User properties

Procedure SP_ComboBox.RegisterProperties;
Begin

  Inherited;

  RegisterProperty('border', Get_Border, Set_Border, ':v|v');
  RegisterProperty('count', Get_Count, nil, ':v');
  RegisterProperty('item', Get_Item, Set_Item, 'v:s|v:s');
  RegisterProperty('index', Get_Index, Set_Index, ':v|v');
  RegisterProperty('editable', Get_Editable, Set_Editable, ':v|v');
  RegisterProperty('text', Get_Text, Set_Text, ':s|s');
  RegisterProperty('onaccept', Get_OnAccept, Set_OnAccept, ':s|s');
  RegisterProperty('onchange', Get_OnChange, Set_OnChange, ':s|s');
  RegisterProperty('hilightclr', Get_HilightClr, Set_HiLightClr, ':v|v');
  RegisterProperty('find', Get_IndexOf, nil, 's:v');

End;

Procedure SP_ComboBox.Set_Border(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Border := StringToInt(s) <> 0;

End;

Function SP_ComboBox.Get_Border: aString;
Begin

  Result := IntToString(Ord(Border));

End;

Procedure SP_ComboBox.Set_Item(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, p: Integer;
Begin

  p := Pos(':', s);
  If p >= 0 Then Begin
    Idx := StringToInt(Copy(s, 1, p -1)) -1;
    s := Copy(s, p +1);
    If (Idx >= 0) And (Idx < Count) Then
      Menu.SetItemCaption(Idx, s);
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function SP_ComboBox.Get_Item: aString;
Begin

  Result := GetCaption(StringToInt(fUserParam) -1);

End;

Function SP_ComboBox.Get_IndexOf: aString;
Begin

  Result := IntToString(Menu.Find(fUserParam) +1);

End;

Procedure SP_ComboBox.Set_Index(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  ItemIndex := StringToInt(s) -1;

End;

Function SP_ComboBox.Get_Index: aString;
Begin

  Result := IntToString(ItemIndex +1);

End;

Procedure SP_ComboBox.Set_Editable(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Editable := StringToInt(s) <> 0;

End;

Function SP_ComboBox.Get_Editable: aString;
Begin

  Result := IntToString(Ord(Editable));

End;

Procedure SP_ComboBox.Set_Text(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Text := s;

End;

Function SP_ComboBox.Get_Text: aString;
Begin

  Result := Text;

End;

Procedure SP_ComboBox.Set_OnAccept(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Compiled_OnAccept := SP_ConvertToTokens(s, Error);
  If Compiled_OnAccept <> '' Then
    User_OnAccept := s;

End;

Function SP_ComboBox.Get_OnAccept: aString;
Begin

  Result := user_OnAccept;

End;

Procedure SP_ComboBox.Set_OnChange(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Compiled_OnChange := SP_ConvertToTokens(s, Error);
  If Compiled_OnChange <> '' Then
    User_OnChange := s;

End;

Function SP_ComboBox.Get_OnChange: aString;
Begin

  Result := User_OnChange;

End;

Procedure SP_ComboBox.Set_HilightClr(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  HightlightColour := StringToInt(s);

End;

Function SP_ComboBox.Get_HilightClr: aString;
Begin

  Result := IntToString(HightlightColour);

End;

Function SP_ComboBox.Get_Count: aString;
Begin

  Result := IntToString(Count);

End;


// User Methods

Procedure SP_ComboBox.RegisterMethods;
Begin

  Inherited;
  RegisterMethod('add', 'S', Method_AddItem);
  RegisterMethod('insert', 'ns', Method_InsertItem);
  RegisterMethod('erase', 'n', Method_EraseItem);
  RegisterMethod('clear', '', Method_Clear);
  RegisterMethod('move', 'nn', Method_MoveItem);

End;

Procedure SP_ComboBox.Method_AddItem(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
Begin

  For i := 0 To Length(Params) -1 do
    AddItem(Params[i]);

End;

Procedure SP_ComboBox.Method_InsertItem(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
Begin

  i := StringToInt(Params[0], 0) -1;
  If (i >= 0) And (i < Menu.Count) then
    InsertItem(Params[1], i)
  Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Procedure SP_ComboBox.Method_EraseItem(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i: Integer;
Begin

  i := StringToInt(Params[0], 0) -1;
  If (i >= 0) And (i < Menu.Count) then
    Menu.DeleteItem(i)
  Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Procedure SP_ComboBox.Method_Clear(Params: Array of aString; Var Error: TSP_ErrorCode);
Begin

  Menu.Clear;

End;

Procedure SP_ComboBox.Method_MoveItem(Params: Array of aString; Var Error: TSP_ErrorCode);
Var
  i, j: Integer;
Begin

  i := StringToInt(Params[0], 0) -1;
  j := StringToInt(Params[1], 0) -1;
  If (i >= 0) And (i < Menu.Count) And (j >= 0) And (j < Menu.Count) Then
    Menu.MoveItem(i, j);

End;

end.
