unit SP_TabBarUnit;

interface

Uses SP_BaseComponentUnit, SP_Util, SP_ContainerUnit;

Type

SP_TabBar = Class(SP_BaseComponent)

  Private

    fShowTabs: Boolean;
    fTabs: TStringlist;
    fPosition: SP_TabPosition;
    fActiveTab: Integer;

  Public

    Procedure Draw; Override;
    Function  GetTab(Index: Integer): aString;
    Procedure SetTab(Index: Integer; s: aString);
    Function  GetTabContainer(Index: Integer): pSP_Container;
    Procedure AddTab(s: String);
    Procedure DeleteTab(Index: Integer);
    Procedure InsertTab(Index: Integer; s: aString);
    Procedure MoveTab(Index, Direction: Integer);
    Procedure SetShowTabs(b: Boolean);

    Property Tabs[Index: Integer]: aString read GetTab write SetTab;
    Property ShowTabs: Boolean read fShowTabs write SetShowTabs;

    Constructor Create(Owner: SP_BaseComponent);
    Destructor Destroy;

End;

implementation

// SP_TabBar

Constructor SP_TabBar.Create(Owner: SP_BaseComponent);
Begin

  Inherited;
  fTabs := TStringlist.Create;

End;

Destructor SP_TabBar.Destroy;
Begin

  Inherited;
  fTabs.Free;

End;

Procedure SP_TabBar.Draw;
Begin

  Fillrect(0, 0, Width -1, Height -1, fBackgroundClr);


End;

Procedure SP_TabBar.SetShowTabs(b: Boolean);
begin

  If b <> fShowTabs Then Begin
    fShowTabs := b;
    Paint;
  End;

end;

Function  SP_TabBar.GetTab(Index: Integer): aString;
Begin

  Result := fTabs[Index];

End;

Procedure SP_TabBar.SetTab(Index: Integer; s: aString);
Begin

  fTabs[Index] := s;
  Paint;

End;

Function  SP_TabBar.GetTabContainer(Index: Integer): pSP_Container;
Begin

  If (Index >= 0) And (Index < fTabs.Count) Then
    Result := pSP_Container(fTabs.Objects[Index])
  Else
    Result := nil;

End;

Procedure SP_TabBar.AddTab(s: String);
Begin

  fTabs.Add(s);
  fTabs.Objects[fTabs.Count -1] := SP_Container.Create(Self);

End;

Procedure SP_TabBar.DeleteTab(Index: Integer);
Begin

  SP_Container(fTabs.Objects[Index]).Free;
  fTabs.Delete(Index);

End;

Procedure SP_TabBar.InsertTab(Index: Integer; s: aString);
Begin

  fTabs.Insert(Index, s);
  fTabs.Objects[Index] := SP_Container.Create(Self);

End;

Procedure SP_TabBar.MoveTab(Index, Direction: Integer);
Var
  tmpCaption: aString;
  tmpObject: TObject;
Begin

  Case Direction of
   -1: // Move left
      Begin
        If Index > 0 Then Begin
          tmpCaption := fTabs[Index -1];
          tmpObject := fTabs.Objects[Index -1];
          fTabs[Index -1] := fTabs[Index];
          fTabs.Objects[Index -1] := fTabs.Objects[Index];
          fTabs[Index] := tmpCaption;
          fTabs.Objects[Index] := tmpObject;
        End;
      End;
    1: // Move right
      Begin
        If Index < fTabs.Count -1 Then Begin
          tmpCaption := fTabs[Index +1];
          tmpObject := fTabs.Objects[Index +1];
          fTabs[Index +1] := fTabs[Index];
          fTabs.Objects[Index +1] := fTabs.Objects[Index];
          fTabs[Index] := tmpCaption;
          fTabs.Objects[Index] := tmpObject;
        End;
      End;
   End;

   Paint;

End;

end.
