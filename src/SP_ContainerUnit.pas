unit SP_ContainerUnit;

interface

Uses SP_BaseComponentUnit, SP_Util;

Type

SP_Container = Class(SP_BaseComponent)

  Private

    fCaption: aString;
    Procedure SetCaption(s: aString);

  Public

    Procedure Draw; Override;
    Property Caption: aString read fCaption write SetCaption;
    Constructor Create(Owner: SP_BaseComponent);
    Destructor  Destroy; Override;

End;
pSP_Container = ^SP_Container;

SP_ContainerCollection = Class(SP_BaseComponent)

  Private

    fShowing: Integer;
    fContainers: Array of SP_Container;
    Function  GetCount: Integer;
    Function  GetContainer(Index: Integer): SP_Container;

  Public

    Function  Add: SP_Container;
    Procedure Delete(Index: Integer); Overload;
    Procedure Delete(Container: SP_Container); Overload;
    Procedure Clear;
    Procedure Show(Index: Integer); Overload;
    Procedure Show(Container: SP_Container); Overload;
    Procedure SetBounds(x, y, w, h: Integer); Override;

    Property Containers[Index: Integer]: SP_Container read GetContainer;
    Property Count: Integer read GetCount;
    Property Showing: Integer read fShowing;

    Constructor Create(Owner: SP_BaseComponent);
    Destructor  Destroy; Override;

End;


implementation

// SP_Container

Constructor SP_Container.Create(Owner: SP_BaseComponent);
Begin

  Inherited;
  fCaption := '';
  fErase := True;

End;

Destructor SP_Container.Destroy;
Begin

  Inherited;

End;

Procedure SP_Container.Draw;
Var
  yo, c: Integer;
Begin

  If fEnabled Then
    c := fFontClr
  Else
    c := fDisabledFontClr;

  If fBorder Then Begin
    If fCaption <> '' Then
      yo := 0
    Else
      yo := Round(iFH/2);
    DrawRect(0, yo, Width -1, Height -1, fBorderClr);
    If fCaption <> '' Then
      PRINT(ifW, 0, ' '+fCaption+' ', c, fBackgroundClr, iSX, iSY, False, False);
  End Else Begin
    If fCaption <> '' Then
      PRINT(0, 0, ' '+fCaption+' ', c, -1, iSX, iSY, False, False);
  End;

End;

Procedure SP_Container.SetCaption(s: aString);
Begin

  fCaption := s;
  Paint;

End;

// SP_ContainerCollection

Constructor SP_ContainerCollection.Create(Owner: SP_BaseComponent);
Begin

  SetLength(fContainers, 0);

End;

Destructor  SP_ContainerCollection.Destroy;
Begin

  Inherited;

End;

Function  SP_ContainerCollection.Add: SP_Container;
Var
  l: Integer;
Begin

  l := Length(fContainers);
  SetLength(fContainers, l + 1);
  fContainers[l] := SP_Container.Create(Self);
  fContainers[l].SetBounds(0, 0, Width, Height);
  fContainers[l].Visible := False;
  Result := fContainers[l];

End;

Procedure SP_ContainerCollection.Delete(Index: Integer);
Var
  i, j: Integer;
Begin

  If (Index >= 0) And (Index < Length(fContainers)) Then Begin

    If fShowing = Index Then Begin
      If Index = Length(fContainers) Then
        j := Index -1
      Else
        j := Index +1;
      Show(j);
    End;

    fContainers[Index].Free;
    For i := Index to Length(fContainers) -2 do
      fContainers[i] := fContainers[i +1];
    SetLength(fContainers, Length(fContainers) -1);
    Paint;

  End;

end;

Procedure SP_ContainerCollection.Delete(Container: SP_Container);
Var
  i: Integer;
Begin

  For i := 0 to Length(fContainers) -1 do
    if fContainers[i] = Container Then
      Delete(i);

End;

Procedure SP_ContainerCollection.Show(Index: Integer);
Var
  i: Integer;
Begin

  For i := 0 to Length(fContainers) -1 Do
    fContainers[i].Visible := i = Index;
  Paint;

End;

Procedure SP_ContainerCollection.Show(Container: SP_Container);
Var
  i: Integer;
Begin

  For i := 0 to Length(fContainers) -1 Do
    fContainers[i].Visible := fContainers[i] = Container;
  Paint;

End;

Procedure SP_ContainerCollection.Clear;
Begin

  SetLength(fContainers, 0);
  Paint;

End;

Function  SP_ContainerCollection.GetCount: Integer;
Begin

  Result := Length(fContainers);

End;

Procedure SP_ContainerCollection.SetBounds(x, y, w, h: Integer);
Var
  i: Integer;
Begin

  Inherited;
  For i := 0 To Length(fContainers) -1 Do
    fContainers[i].SetBounds(0, 0, Width, Height);

End;

Function  SP_ContainerCollection.GetContainer(Index: Integer): SP_Container;
Begin

  If (Index >= 0) And (Index < Length(fContainers)) Then
    Result := fContainers[Index]
  Else
    Result := nil;

End;

end.
