unit SP_CheckListUnit;

interface

Uses SP_RadioGroupUnit, SP_BaseComponentUnit;

Type

SP_CheckList = Class(SP_RadioGroup)

  Private

    Function IsChecked(Index: Integer): Boolean;
    Procedure SetItemChecked(Index: Integer; State: Boolean);

  Public

    Property Checked[Index: Integer]: Boolean read IsChecked write SetItemChecked;
    Constructor Create(Owner: SP_BaseComponent);

End;

implementation

// SP_CheckList

Constructor SP_CheckList.Create(Owner: SP_BaseComponent);
Begin

  Inherited;
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

end.
