unit SP_ComboBoxUnit;

interface

Uses SP_Components, SP_BaseComponentUnit, SP_Util, SP_PopUpMenuUnit, SP_EditUnit, SP_LabelUnit, SP_ButtonUnit, SP_SysVars;

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
    Procedure PlaceItems;
    Procedure OnBtnClick(Sender: SP_BaseComponent);
    Procedure OnMenuSelect(Sender: SP_BaseComponent);
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
    Procedure PerformKeyDown(Var Handled: Boolean); Override;
    Procedure PerformKeyup(Var Handled: Boolean); Override;
    Procedure LabMouseDown(X, Y, Btn: Integer);
    Procedure LabMouseUp(X, Y, Btn: Integer);
    Procedure SetBackgroundClr(c: Byte); Override;
    Procedure SetFontClr(c: Byte); Override;
    Procedure SetHighlightClr(c: Byte); Override;
    Procedure SetDisabledFontClr(c: Byte); Override;
    Procedure SetChainControl(c: SP_BaseComponent); Override;

  Public

    Procedure AddStrings(Strings: TStringlist);
    Procedure AddItem(Caption: aString);
    Procedure InsertItem(Caption: aString; Index: Integer);
    Procedure DeleteItem(Index: Integer);
    Procedure Clear;
    Procedure SetBounds(x, y, w, h: Integer); Override;
    Procedure SetFocus(b: Boolean); Override;

    Property  Border:     Boolean            read GetBorder       write SetBorder;
    Property  Items[Index: Integer]: aString read GetCaption      write SetCaption;
    Property  ItemIndex:  Integer            read fItemIndex      write SetItemIndex;
    Property  Editable:   Boolean            read fEditable       write SetEditable;
    Property  Text:       aString            read GetText         write SetText;
    Property  OnAccept:   SP_EditEvent       read fOnAccept       write fOnAccept;
    Property  OnChange:   SP_EditEvent       read fOnChange       write fOnChange;
    Property  HightlightColour: Byte         read fHighlightClr   write SetHighlightClr;

    Constructor Create(Owner: SP_BaseComponent);
    Destructor Destroy; Override;

End;

implementation

Uses Math, SP_Input, SP_Sound;

// SP_Combobox

Constructor SP_ComboBox.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  Menu := SP_PopUpMenu.Create(Owner, nil);
  Edit := SP_Edit.Create(Self);
  Edit.Visible := False;
  fEditable := False;
  Labl := SP_Label.Create(Self);
  Labl.OnMouseDown := LabMouseDown;
  Labl.OnMouseUp := LabMouseUp;
  Labl.fAlign := 0;
  ChainControl := Edit;
  Edit.ChainControl := Self;
  Edit.OnAccept := EditAccept;
  Edit.OnChange := EditChange;
  Btn := SP_Button.Create(Self);
  Btn.OnClick := OnBtnClick;
  Btn.OverrideScaling := True;
  Btn.Enabled := False;
  Border := True;
  CanFocus := True;
  fItemIndex := -1;

End;

Destructor SP_ComboBox.Destroy;
Begin

  Inherited;

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

  Menu.HightlightClr := c;
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

  Menu.AddItem(CreateItem(Caption, True, True, False, False, Nil, OnMenuSelect));
  If Menu.fCount = 1 Then ItemIndex := 0;
  Btn.Enabled := Menu.fCount > 1;
  Paint;

End;

Procedure SP_ComboBox.InsertItem(Caption: aString; Index: Integer);
Begin

  Menu.InsertItem(CreateItem(Caption, True, True, False, False, Nil, OnMenuSelect), Index);
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

  h := Max(ifH, Edit.Height);
  Menu.MinWidth := w;
  Inherited;

  PlaceItems;

End;

Procedure SP_ComboBox.PlaceItems;
Begin

  Erase;

  Btn.SetBounds(Width - Height, 0, Height, Height);
  Btn.Caption := #252;
  Btn.CentreCaption;

  Edit.SetBounds(0, 0, Width - Height + 1, Height -1);
  Labl.SetBounds(0, 0, Width - Height + 1, Edit.Height);

  Edit.Visible := Editable;
  Labl.Visible := Not Editable;

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

Procedure SP_ComboBox.OnMenuSelect(Sender: SP_BaseComponent);
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

Procedure SP_ComboBox.LabMouseDown(X, Y, Btn: Integer);
begin

  SP_PlaySystem(CLICKCHAN, CLICKBANK);
  Self.btn.State := spPressed;

end;

Procedure SP_ComboBox.LabMouseUp(X, Y, Btn: Integer);
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

end;

Procedure SP_ComboBox.EditChange;
begin

  If Assigned(fOnChange) Then
    fOnChange(Self, Edit.Text);

end;

Procedure SP_ComboBox.PerformKeyDown(Var Handled: Boolean);
Var
  i, j, k: Integer;
  NewChar: Byte;
Begin

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


end.
