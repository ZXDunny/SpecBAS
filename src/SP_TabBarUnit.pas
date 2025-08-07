unit SP_TabBarUnit;

{$INCLUDE SpecBAS.inc}

interface

Uses SP_BaseComponentUnit, SP_Util, SP_ContainerUnit;

Type

SP_TabBar = Class(SP_BaseComponent)

  Private

    fShowTabs: Boolean;
    fTabs: TStringlist;
    fPosition: SP_TabPosition;
    fActiveTab: Integer;
    fTransBack: Boolean;

  Public

    Procedure Draw; Override;
    Function  GetTab(Index: Integer): aString;
    Procedure SetTab(Index: Integer; s: aString);
    Function  GetTabContainer(Index: Integer): pSP_Container;
    Procedure AddTab(s: aString);
    Procedure DeleteTab(Index: Integer);
    Procedure InsertTab(Index: Integer; s: aString);
    Procedure MoveTab(Index, Direction: Integer);
    Procedure SetShowTabs(b: Boolean);
    Procedure SetTransBack(b: Boolean);
    Procedure SetTabPosition(p: SP_TabPosition);

    Property Tabs[Index: Integer]: aString read GetTab write SetTab;
    Property ShowTabs: Boolean read fShowTabs write SetShowTabs;
    Property Position: SP_TabPosition read fPosition write SetTabPosition;
    Property TransparentBackground: Boolean read fTransBack write SetTransBack;

    Constructor Create(Owner: SP_BaseComponent);
    Destructor Destroy; Override;

End;

implementation

// SP_TabBar

Uses SP_Components;

Constructor SP_TabBar.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fTypeName := 'spTabBar';

  fTabs := TStringlist.Create;
  fPosition := spTop;
  fActiveTab := -1;
  fTransBack := True;

End;

Destructor SP_TabBar.Destroy;
Begin

  Inherited;
  fTabs.Free;

End;

Procedure SP_TabBar.Draw;
var
  BkgClr: Integer;
Begin

  if fTransBack Then
    BkgClr := 255
  else
    BkgClr := fBackgroundClr;

  Fillrect(0, 0, Width -1, Height -1, BkgClr);
  if Align = sp_AlignTop then
    DrawLine(0, fHeight -1, fWidth -1, fHeight -1, fBorderClr)
  else
    if Align = sp_AlignBottom then begin
      DrawLine(0, 0, fWidth -1, 0, fBorderClr);
      DrawLine(0, 2, fWidth -1, 2, SP_UIHalfLight);
      DrawLine(0, 1, fWidth -1, 1, SP_UIShadow);
    end;

End;

Procedure SP_TabBar.SetTransBack(b: Boolean);
Begin

  If b <> fTransBack Then Begin
    fTransBack := b;
    Paint;
  End;

End;

Procedure SP_TabBar.SetTabPosition(p: SP_TabPosition);
Begin

  Case p of
    spTop:
      Begin

      End;
    spBottom:
      Begin

      End;
  End;

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

Procedure SP_TabBar.AddTab(s: aString);
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
