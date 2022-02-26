unit SP_LabelUnit;

interface

Uses Math, SP_BaseComponentUnit, SP_Util;

Type

SP_Label = Class(SP_BaseComponent)

  Public

    fCaption: aString;
    fJustify: Integer; // -1 Left, 0 Centre, 1 Right
    fAlign: Integer;   // -1 Top, 0 Centre, 1 Bottom
    fAutoSize: Boolean;
    fLines: TStringlist;
    fCaplen: Integer;
    Procedure SetCaption(s: aString);
    Procedure SetJustify(i: Integer);
    Procedure SetAlign(i: Integer); Override;
    Procedure SetAutoSize(b: Boolean);
    Procedure Prepare;
    Procedure Draw; Override;

    Property Caption: aString read fCaption write SetCaption;
    Property TextJustify: Integer read fJustify write SetJustify;
    Property TextAlign: Integer read fAlign write SetAlign;
    Property AutoSize: Boolean read fAutoSize write SetAutoSize;

    Constructor Create(Owner: SP_BaseComponent);
    Destructor Destroy; Override;

  End;

implementation

Uses SP_Components;

// SP_Label

Constructor SP_Label.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fJustify := -1;
  fAlign := -1;
  fCaption := '';
  fTransparent := True;
  fBorder := False;
  fLines := TStringlist.Create;

End;

Destructor SP_Label.Destroy;
Begin

  fLines.Free;
  Inherited;

End;

Procedure SP_Label.Prepare;
Var
  i, lsp, cnt, maxw: Integer;
  s: aString;
  BreakNow: Boolean;
Begin

  If (fWidth < iFW) and Not fAutoSize Then Exit;

  i := 1;
  lsp := 1;
  cnt := 0;
  s := '';
  If fAutoSize Then
    maxw := MAXINT
  else
    maxw := fWidth Div iFW;
  BreakNow := False;
  fLines.Clear;
  While i <= Length(fCaption) Do Begin

    Case Ord(fCaption[i]) of

      6, 8, 9, 10:
        Begin // PRINT comma, Cursor Left/right/up/down
          s := s + fCaption[i];
          Inc(i);
        End;
     13:
        Begin // Carriage return
          BreakNow := True;
          Inc(i);
        End;
     16, 17, 18, 19, 20, 23, 24, 26, 27:
        Begin // INK/PAPER/OVER/TRANSPARENT/INVERSE/TAB/ITALIC/BOLD control
          s := s + Copy(fCaption, i, SizeOf(LongWord) +1);
          Inc(i, SizeOf(LongWord) +1)
        End;
     21, 22:
        Begin // MOVE, AT control
          s := s + Copy(fCaption, i, (SizeOf(LongWord) * 2)+1);
          Inc(i, (SizeOf(LongWord) * 2)+1);
        End;
     25:
        Begin // SCALE control
          s := s + Copy(fCaption, i, (SizeOf(aFloat) * 2) +1);
          Inc(i, (SizeOf(aFloat) * 2)+1);
        End;
      32..255:
        Begin
          If cnt >= maxw Then Begin
            BreakNow := True;
            s := Copy(s, 1, Length(s) - (i - lsp));
            i := lsp +1;
          End Else Begin
            If fCaption[i] in Seps Then
              lsp := i;
            s := s + fCaption[i];
            Inc(i);
            Inc(cnt);
          End;
        End;
    End;

    If BreakNow Then Begin
      fLines.Add(s);
      fLines.Objects[fLines.Count -1] := Pointer(cnt);
      cnt := 0;
      s := '';
    End;

  End;

  If fAutoSize Then Begin
    maxw := 0;
    If fLines.Count > 0 Then Begin
      For i := 0 To fLines.Count -1 Do
        If NativeInt(fLines.Objects[i]) > maxw Then maxw := NativeInt(fLines.Objects[i]);
    End Else Begin
      maxw := cnt;
      fCapLen := cnt;
    End;
    Width := maxw * iFW;
    Height := Max(fLines.Count, 1) * iFH;
  End Else
    fCapLen := cnt;

End;

Procedure SP_Label.Draw;
Var
  bOffs, i, x, y: Integer;
Begin

  x := 0; y := 0;
  bOffs := Ord(fBorder) * 2;

  If fBorder Then
    DrawRect(0, 0, Width -1, Height -1, fBorderClr);

  If fLines.Count > 0 Then Begin

    Case fAlign of
      -1:
        Begin // Top
          y := 0;
        End;
      0:
        Begin // Vertically centred
          y := (fHeight - (fLines.Count * iFH)) Div 2;
        End;
      1:
        Begin // Bottom
          y := fHeight - (fLines.Count * iFH);
        End;
    End;

    For i := 0 To fLines.Count -1 Do Begin

      Case fJustify Of
        -1:
          Begin // Left Justify
            x := bOffs;
          End;
        0:
          Begin // Centre
            x := ((fWidth - bOffs) - (Integer(fLines.Objects[i]) * iFW)) Div 2;
          End;
        1:
          Begin // Right Justify
            x := (fWidth - bOffs) - (Integer(fLines.Objects[i]) * iFW);
          End;
      End;
      If fEnabled Then
        PRINT(x, y, fLines[i], fFontClr, -1, iSX, iSY, False, False, False)
      Else
        PRINT(x, y, fLines[i], fDisabledFontClr, -1, iSX, iSY, False, False, False);
      Inc(y, iFH);

    End;

  End Else Begin

    Case fAlign of
      -1: y := 0;
       0: y := (fHeight - iFH) Div 2;
       1: y := fHeight - iFH;
    End;

    Case fJustify Of
      -1: x := bOffs;
       0: x := ((fWidth - bOffs) - (fCaplen * iFW)) Div 2;
       1: x := (fWidth - bOffs) - (fCaplen * iFW);
    End;
    If fEnabled Then
      PRINT(x, y, fCaption, fFontClr, -1, iSX, iSY, False, False, False)
    Else
      PRINT(x, y, fCaption, fDisabledFontClr, -1, iSX, iSY, False, False, False);

  End;

End;

Procedure SP_Label.SetCaption(s: aString);
Begin

  If fCaption <> s Then Begin
    fCaption := s;
    Prepare;
    Paint;
  End;

End;

Procedure SP_Label.SetJustify(i: Integer);
Begin

  If fJustify <> i Then Begin
    fJustify := i;
    Prepare;
    Paint;
  End;

End;

Procedure SP_Label.SetAlign(i: Integer);
Begin

  If fAlign <> i Then Begin
    fAlign := i;
    Prepare;
    Paint;
  End;

End;

Procedure SP_Label.SetAutoSize(b: Boolean);
begin

  If fAutoSize <> b Then Begin
    fAutoSize := b;
    Prepare;
    Paint;
  End;

end;


end.
