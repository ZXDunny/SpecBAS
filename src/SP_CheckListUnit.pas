unit SP_CheckListUnit;

{$INCLUDE SpecBAS.inc}

interface

Uses SP_RadioGroupUnit, SP_BaseComponentUnit, SP_Errors, SP_Util;

Type

SP_CheckList = Class(SP_RadioGroup)

  Private

    Function IsChecked(Index: Integer): Boolean;
    Procedure SetItemChecked(Index: Integer; State: Boolean);

    Procedure Set_Checked(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
    Function  Get_Checked: aString;

  Public

    Procedure RegisterProperties; Override;
    Property  Checked[Index: Integer]: Boolean read IsChecked write SetItemChecked;
    Constructor Create(Owner: SP_BaseComponent);

End;

implementation

// SP_CheckList

Constructor SP_CheckList.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fTypeName := 'spChecklist';
  IsRadioGroup := False;

End;

Function SP_CheckList.IsChecked(Index: Integer): Boolean;
Begin

  If (Index >= 0) And (Index < Length(fItems)) Then
    result := fItems[Index].fChecked
  Else
    Result := False;

End;

Procedure SP_CheckList.SetItemChecked(Index: Integer; State: Boolean);
Begin

  If (Index >= 0) And (Index < Length(fItems)) Then
    fItems[Index].Checked := State;

End;

// User Properties

Procedure SP_CheckList.RegisterProperties;
Begin

  Inherited;
  RegisterProperty('checked', Get_Checked, Set_Checked, 'v:v|v:v');

End;

Procedure SP_CheckList.Set_Checked(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Var
  Idx, p: Integer;
Begin

  p := Pos(':', s);
  If p >= 0 Then Begin
    Idx := StringToInt(Copy(s, 1, p -1)) -1;
    s := Copy(s, p +1);
    If (Idx >= 0) And (Idx < Count) Then
      fItems[Idx].Checked := StringToInt(s) <> 0;
    Paint;
  End Else
    Error.Code := SP_ERR_INVALID_PROPERTY_VALUE;

End;

Function  SP_CheckList.Get_Checked: aString;
Var
  Idx: Integer;
Begin

  Result := '';
  Idx := StringToInt(fUserParam) -1;
  If (Idx >= 0) And (Idx < Count) Then
    Result := IntToString(Integer(fItems[Idx].Checked));

End;

end.
