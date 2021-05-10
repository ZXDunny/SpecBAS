unit SP_EditUnit;

interface

Uses SP_BaseComponentUnit, SP_Util;

Type

SP_Edit = Class(SP_BaseComponent)

  Private

    fText: aString;
    fCursorPos: Integer;
    fSelStart: Integer;
    fFlashTimer: Integer;
    fCursFG, fCursBG: Integer;
    fGfxMode, fGfxLock: Integer;
    fMouseIsDown: Boolean;
    fAccepted: Boolean;
    fRightJustify: Boolean;
    fUndoList, fRedoList: TStringlist;
    xoff: Integer;
    fOnAccept: SP_EditEvent;
    fOnChange: SP_EditEvent;
    fEditable: Boolean;
    fValidText: Boolean;
    fGhostText: aString;

    Procedure SetText(s: aString);
    Procedure SetEditable(b: Boolean);
    Procedure FlashTimer(p: Pointer);
    Procedure SetCursorPos(v: Integer);
    Procedure DeleteWord(Backwards: Boolean);
    Procedure SetRightJustify(b: Boolean);
    Procedure PerformUndo;
    Procedure PerformRedo;
    Procedure StoreUndo;
    Procedure SetValidText(b: Boolean);
    Procedure SetSelStart(n: Integer);
    Procedure SetGhostText(s: aString);

  Public

    Procedure Draw; Override;
    Procedure PerformKeyDown(Var Handled: Boolean); Override;
    Procedure PerformKeyUp(Var Handled: Boolean); Override;
    Procedure MouseDown(X, Y, Btn: Integer); Override;
    Procedure MouseUp(X, Y, Btn: Integer); Override;
    Procedure MouseMove(X, Y, Btn: Integer); Override;
    Procedure DoubleClick(X, Y, Btn: Integer); Override;
    Procedure SetBounds(x, y, w, h: Integer); Override;

    Property Text: aString read fText Write SetText;
    Property CursorPos: Integer read fCursorPos write SetCursorPos;
    Property OnAccept: SP_EditEvent read fOnAccept write fOnAccept;
    Property OnChange: SP_EditEvent read fOnChange write fOnChange;
    Property Editable: Boolean read fEditable write SetEditable;
    Property RightJustify: Boolean read fRightJustify write SetRightJustify;
    Property ValidText: Boolean read fValidText write SetValidText;
    Property SelStart: Integer read fSelStart write SetSelStart;
    Property GhostText: aString read fGhostText write SetGhostText;

    Constructor Create(Owner: SP_BaseComponent);
    Destructor  Destroy; Override;

    Procedure CutSelection;
    Procedure CopySelection;
    Procedure PasteSelection;
    Procedure DeleteSelection;
    Procedure SelectAll;
    Procedure SelectNone;
    Procedure SelectWord;

End;

implementation

Uses Math, SysUtils, SP_Components, SP_SysVars, SP_Input, SP_Sound, ClipBrd;

// SP_Edit

Constructor SP_Edit.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fText := '';
  xoff := 0;
  fCursorPos := 1;
  fSelStart := 1;
  fCursFg := 9;
  fCursBg := 15;
  fCanFocus := True;
  fAccepted := False;
  fGfxMode := 0;
  fGfxLock := 0;
  fValidText := True;
  fBackgroundClr := 7;
  fBorder := True;
  fEditable := True;
  fTransparent := False;
  fUndoList := TStringList.Create;
  fRedoList := TStringList.Create;

  fFlashTimer := AddTimer(Self, FLASHINTERVAL, FlashTimer, False)^.ID;

End;

Destructor SP_Edit.Destroy;
Begin

  RemoveTimer(fFlashTimer);
  fUndoList.Free;
  fRedoList.Free;

  Inherited;

End;

Procedure SP_Edit.SetGhostText(s: aString);
Begin

  fGhostText := s;
  Paint;

End;

Procedure SP_Edit.SetValidText(b: Boolean);
Begin

  fValidText := b;
  Paint;

End;

Procedure SP_Edit.SetSelStart(n: Integer);
Begin

  fSelStart := n;
  Paint;

End;

Procedure SP_Edit.SetEditable(b: Boolean);
Begin

  fEditable := b;
  fCanFocus := b;
  SetFocus(fEditable And Focused);

End;

Procedure SP_Edit.SetBounds(x, y, w, h: Integer);
Begin

  h := IfH + (Ord(fBorder) * 4);
  Inherited;

End;

Procedure SP_Edit.Draw;
Var
  tl, ss, sc, p, Clr: Integer;
  c: aChar;
Begin

  tl := Length(fText);
  If fCursorPos <= tl Then
    c := fText[fCursorPos]
  Else
    c := ' ';

  If fEnabled Then Begin
    If fValidText Then
      Clr := fFontClr
    Else
      Clr := fErrorClr;
    If (fGhostText <> '') And (Copy(fGhostText, 1, Length(fText)) = fText) Then
      Print(-xoff + (Ord(fBorder) * 2), (Height - iFH) Div 2, fGhostText, SP_UITextDisabled, -1, iSX, iSY, False, False)
    Else
      fGhostText := '';
  End Else
    Clr := SP_UITextDisabled;

  Print(-xoff + (Ord(fBorder) * 2), (Height - iFH) Div 2, fText, Clr, -1, iSX, iSY, False, False);

  If fBorder Then Begin
    DrawRect(0, 0, Width -1, Height -1, fBorderClr);
    DrawRect(1, 1, Width -2, Height -2, fBackgroundClr);
  End;

  If fEnabled Then Begin

    If fSelStart <> fCursorPos Then Begin
      If Focused Then p := SP_UISelection Else p := SP_UIUnfocusedSelection;

      ss := Min(fSelStart, fCursorPos);
      sc := (Max(fSelStart, fCursorPos) - ss) +1;
      Print(((ss -1)*iFW)-xoff + (Ord(fBorder) * 2), (Height - iFH) Div 2, Copy(fText, ss, sc), Clr, p, iSX, iSY, False, False);
    End;

    If Focused Then Begin
      If fGhostText <> '' Then
        If fCursorPos <= Length(fGhostText) Then
          c := fGhostText[fCursorPos];

      Print(((fCursorPos -1)*iFW)-xoff + (Ord(fBorder) * 2), (Height - iFH) Div 2, c, fCursFg, fCursBg, iSX, iSY, False, False);

    End;


  End;

End;

Procedure SP_Edit.DeleteWord(Backwards: Boolean);
Var
  s: aString;
  p1, p2, t: Integer;
Begin

  s := fText + ' ';
  p1 := fCursorPos;

  p2 := p1;
  If Backwards Then Begin
    If (p1 > 1) And Not (s[p1] in Seps) And (s[p1 -1] in Seps) Then Dec(p1);
    While (p1 > 1) And Not (Not (s[p1] in Seps) And (s[p1 -1] in Seps)) Do Dec(p1);
    If (p1 = 2) And Not (s[1] in Seps) Then p1 := 1;
  End Else Begin
    If (p1 > 1) And (s[p1 -1] in Seps) And Not (s[p1] in Seps) Then Inc(p1);
    While (p1 < Length(s)) And Not (Not (s[p1] in Seps) And (s[p1 -1] in Seps)) Do Inc(p1);
  End;

  If p1 > p2 Then Begin
    t := p1; p1 := p2; p2 := t;
  End;
  s := Copy(s, 1, Length(s) -1);
  s := Copy(s, 1, p1-1) + Copy(S, p2);

  StoreUndo;
  fText := s;
  CursorPos := p1;
  fSelStart := fCursorPos;

End;

Procedure SP_Edit.DeleteSelection;
Var
  SelS, SelE: Integer;
Begin

  If fSelStart <> fCursorPos Then Begin
    StoreUndo;
    SelS := Min(fSelStart, fCursorPos);
    SelE := Max(fSelStart, fCursorPos);
    If fSelStart < fCursorPos Then
      fText := Copy(fText, 1, SelS -1) + Copy(fText, SelE)
    Else
      fText := Copy(fText, 1, SelS) + Copy(fText, SelE +1);
    CursorPos := SelS;
    fSelStart := fCursorPos;
  End;

End;

Procedure SP_Edit.PerformKeyDown(Var Handled: Boolean);
Var
  NewChar: Byte;
  oText: aString;
Begin

  If not fEnabled Then Exit;

  oText := fText;
  fGfxMode := fGfxLock;
  Handled := False;

  NewChar := DecodeKey(cLastKey);

  If (NewChar = 0) {$IFNDEF FPC} And (cLastKeyChar <> 1) {$ENDIF} Then Begin

    Case cLastKey of

      K_SHIFT, K_CONTROL:
        Begin
          Handled := True;
        End;

      K_ESCAPE:
        Begin
          Handled := True;
          fAccepted := True;
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
        End;

      K_ALT, K_ALTGR:
        Begin
          If KEYSTATE[K_SHIFT] = 1 Then Begin
            fGfxLock := 1-fGfxLock;
            SP_PlaySystem(CLICKCHAN, CLICKBANK);
          End;
          Handled := True;
        End;

      K_LEFT:
        Begin
          If fCursorPos > 1 Then
            If KEYSTATE[K_CONTROL] = 1 Then Begin
              If fText <> '' Then Begin
                If fText[fCursorPos -1] in Seps Then Dec(fCursorPos);
                While (fCursorPos > 1) And ((fCursorPos > Length(fText)) or (fText[fCursorPos] in Seps)) Do Dec(fCursorPos);
                While (fCursorPos > 1) and (Not (fText[fCursorPos] in Seps)) Do Dec(fCursorPos);
                If fCursorPos > 1 Then
                  Inc(fCursorPos);
              End;
            End Else Begin
              Dec(fCursorPos);
            End;
          If KEYSTATE[K_SHIFT] = 0 Then
            fSelStart := fCursorPos;
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          Handled := True;
        End;

      K_RIGHT:
        Begin
          If fCursorPos <= Length(fText) Then Begin
            If KEYSTATE[K_CONTROL] = 1 Then Begin
              While (fCursorPos < Length(fText)+1) and (fText[fCursorPos] in Seps) Do Inc(fCursorPos);
              While (fCursorPos < Length(fText)+1) and (Not (fText[fCursorPos] in Seps)) Do Inc(fCursorPos);
              If (fCursorPos < Length(fText)) and (fText[fCursorPos] in Seps) Then Inc(fCursorPos);
            End Else Begin
              Inc(fCursorPos);
            End;
          End Else
            If fGhostText <> '' Then Begin
              fText := fGhostText;
              fCursorPos := Length(Text) + 1;
            End;
          If KEYSTATE[K_SHIFT] = 0 Then
            fSelStart := fCursorPos;
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          Handled := True;
        End;

      K_HOME:
        Begin
          fCursorPos := 1;
          If KEYSTATE[K_SHIFT] = 0 Then
            fSelStart := fCursorPos;
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          Handled := True;
        End;

      K_END:
        Begin
          fCursorPos := Length(fText)+1;
          If KEYSTATE[K_SHIFT] = 0 Then
            fSelStart := fCursorPos;
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          Handled := True;
        End;

      K_BACK:
        Begin
          If KEYSTATE[K_CONTROL] = 1 Then
            DeleteWord(True)
          Else
            If fSelStart <> fCursorPos Then Begin
              DeleteSelection;
            End Else
              If fCursorPos > 1 Then Begin
                StoreUndo;
                fText := Copy(fText, 1, fCursorPos -2) + Copy(fText, fCursorPos, Length(fText));
                Dec(fCursorPos);
              End;
          fSelStart := fCursorPos;
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          Handled := True;
        End;

      K_DELETE:
        Begin
          If fText <> '' Then Begin
            If KEYSTATE[K_CONTROL] = 1 Then
              DeleteWord(False)
            Else
              If fSelStart <> fCursorPos Then Begin
                DeleteSelection;
              End Else
                If fCursorPos <= Length(fText) Then Begin
                  StoreUndo;
                  fText := Copy(fText, 1, fCursorPos -1) + Copy(fText, fCursorPos +1, Length(fText));
                End;
          End;
          fSelStart := fCursorPos;
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          Handled := True;
        End;

      K_INSERT:
        Begin
          INSERT := Not INSERT;
          SP_PlaySystem(CLICKCHAN, CLICKBANK);
          Handled := True;
        End;

      K_RETURN:
        Begin
          Handled := True;
          fAccepted := True;
          If ValidText Then
            SP_PlaySystem(OKCHAN, OKSNDBANK)
          Else
            SP_PlaySystem(ERRORCHAN, ERRSNDBANK);
        End;
    Else
      Inherited;
    End;

  End Else Begin
    If KEYSTATE[K_CONTROL] = 0 Then Begin
      If fSelStart <> fCursorPos Then
        DeleteSelection
      Else
        StoreUndo;
      If INSERT Then
        If fGfxMode = 1 Then
          fText := Copy(fText, 1, fCursorPos -1) + aChar(Byte(NewChar)+128) + Copy(fText, fCursorPos, Length(fText))
        Else
          fText := Copy(fText, 1, fCursorPos -1) + aChar(NewChar) + Copy(fText, fCursorPos, Length(fText))
      Else Begin
        If fGfxMode = 1 Then
          fText := Copy(fText, 1, fCursorPos -1) + aChar(Byte(NewChar)+128) + Copy(fText, fCursorPos +1, LENGTH(fText))
        Else
          fText := Copy(fText, 1, fCursorPos -1) + aChar(NewChar) + Copy(fText, fCursorPos +1, LENGTH(fText));
      End;
      Inc(fCursorPos);
      fSelStart := fCursorPos;
      Handled := True;
    End Else Begin
      Case aChar(NewChar) of
        'z':
          Begin
            If KEYSTATE[K_ALT] = 0 Then
              PerformUndo
            Else
              PerformRedo;
            Handled := True;
          End;
        'c':
          Begin
            CopySelection;
            Handled := True;
          End;
        'x':
          Begin
            CutSelection;
            Handled := True;
          End;
        'v':
          Begin
            PasteSelection;
            Handled := True;
          End;
        'a':
          Begin
            SelectAll;
            Handled := True;
          End;
        'd':
          Begin
            SelectNone;
            Handled := True;
          End;
        'w':
          Begin
            SelectWord;
            Handled := True;
          End;
      Else
        Inherited;
      End;
    End;
    SP_PlaySystem(CLICKCHAN, CLICKBANK);
  End;

  CursorPos := fCursorPos;
  Paint;

  If oText <> fText Then
    If Assigned(OnChange) Then
      OnChange(Self, fText);

End;

Procedure SP_Edit.PerformKeyUp(Var Handled: Boolean);
Begin

  Case cLastKey Of

    K_RETURN:
      Begin
        If fAccepted And Assigned(OnAccept) Then Begin
          OnAccept(Self, fText);
          Handled := True;
        End;
      End;

    K_ESCAPE:
      Begin
        If fAccepted Then Begin
          Abort;
          Handled := True;
        End;
      End;

  End;

End;

Procedure SP_Edit.PerformUndo;
Var
  s: aString;
Begin

  If fUndoList.Count > 0 Then Begin
    fRedoList.Add(LongWordToString(fCursorPos) + LongWordToString(fSelStart) + fText);
    s := fUndoList[fUndoList.Count -1];
    fSelStart := pLongWord(@s[5])^;
    fText := Copy(s, 9);
    CursorPos := pLongWord(@s[1])^;
    Paint;
  End;

End;

Procedure SP_Edit.PerformRedo;
Var
  s: aString;
Begin

  If fRedoList.Count > 0 Then Begin
    fUndoList.Add(LongWordToString(fCursorPos) + LongWordToString(fSelStart) + fText);
    s := fRedoList[fRedoList.Count -1];
    fSelStart := pLongWord(@s[5])^;
    fText := Copy(s, 9);
    CursorPos := pLongWord(@s[1])^;
    Paint;
  End;

End;

Procedure SP_Edit.StoreUndo;
Begin

  fRedoList.Clear;
  fUndoList.Add(LongWordToString(fCursorPos) + LongWordToString(fSelStart) + fText);

End;

Procedure SP_Edit.CutSelection;
Begin

  CopySelection;
  DeleteSelection;

End;

Procedure SP_Edit.CopySelection;
Var
  s: aString;
  SelS, SelE: Integer;
Begin

  If fSelStart <> CURSORPOS Then Begin
    SelS := Min(fSelStart, fCursorPos);
    SelE := Max(fSelStart, fCursorPos);
    If fSelStart < fCursorPos Then
      s := Copy(fText, SelS, SelE - SelS)
    Else
      s := Copy(fText, SelS +1, (SelE - SelS));
  End;

  Clipboard.AsText := String(s);

End;

Procedure SP_Edit.PasteSelection;
Var
  Strings: TStringList;
Begin

  If fSelStart <> fCursorPos Then
    DeleteSelection
  Else
    StoreUndo;
  Strings := TStringlist.Create;
  Strings.Text := aString(Clipboard.AsText);
  If Strings.Count > 0 Then Begin
    fText := Copy(fText, 1, fCursorPos -1) + Strings[0] + Copy(fText, fCursorPos);
    Inc(fCursorPos, Length(Strings[0]));
    fSelStart := fCursorPos;
  End;
  Strings.Free;

End;

Procedure SP_Edit.SelectAll;
Begin

  fSelStart := 1;
  CursorPos := Length(fText) +1;
  Paint;

End;

Procedure SP_Edit.SelectNone;
Begin

  fSelStart := fCursorPos;
  Paint;

End;

Procedure SP_Edit.SelectWord;
Var
  t: Integer;
Begin

  While (fCursorPos > 1) And (fText[fCursorPos] in Seps) Do Dec(fCursorPos);
  While (fCursorPos > 1) And Not (fText[fCursorPos] in Seps) Do Dec(fCursorPos);
  If fText[fCursorPos] in Seps Then Inc(fCursorPos);
  fSelStart := fCursorPos;
  While (fSelStart <= Length(fText)) And Not (fText[fSelStart] in Seps) Do Inc(fSelStart);
  t := fSelStart; fSelStart := fCursorPos; fCursorPos := t;
  Paint;

End;

Procedure SP_Edit.MouseDown(X, Y, Btn: Integer);
Begin

  if not fEnabled Then Exit;

  if fBorder Then Begin
    Dec(X, 2);
    Dec(Y, 2);
  end;

  fMouseIsDown := True;
  SetFocus(True);
  CursorPos := Min(Max((X Div iFW) +1, 0), Length(fText)+1);
  If KEYSTATE[K_SHIFT] = 0 Then
    fSelStart := fCursorPos;
  SP_PlaySystem(CLICKCHAN, CLICKBANK);
  Paint;

  Inherited;

End;

Procedure SP_Edit.MouseMove(X, Y, Btn: Integer);
Begin

  if not fEnabled Then Exit;

  if fBorder Then Begin
    Dec(X, 2);
    Dec(Y, 2);
  end;

  If fMouseIsDown Then
    CursorPos := Max(1, (X Div iFW) +1);

  Inherited;

End;

Procedure SP_Edit.MouseUp(X, Y, Btn: Integer);
Begin

  fMouseIsDown := False;
  Inherited;

End;

Procedure SP_Edit.DoubleClick(X, Y, Btn: Integer);
Begin

  SelectWord;
  Inherited;

End;

Procedure SP_Edit.SetRightJustify(b: Boolean);
begin

  fRightJustify := True;
  SetText(fText);

end;

Procedure SP_Edit.SetText(s: aString);
Begin

  If fText <> s Then Begin
    StoreUndo;
    fText := s;
    CursorPos := Length(s) +1;
    fSelStart := fCursorPos;
    if not Focused then begin
      if fRightJustify then begin
        if iFW * Length(fText) < Width then
          xOff := 0
        else
          xOff := -((Width - (Ord(fBorder) * 4)) - (iFW * Length(fText)))
      end else
        xOff := 0;
    end;
    Paint;

    If Assigned(fOnChange) Then
      fOnChange(Self, fText);

  End;

End;

Procedure SP_Edit.SetCursorPos(v: Integer);
Var
  x, m, n: Integer;
Begin

  fCursorPos := Min(v, Length(fText)+1);
  n := iFW * 3;
  m := Width - n;
  x := (fCursorPos * iFW) - xOff;
  If x > m Then
    Inc(xOff, x - m)
  Else
    If x < n Then
      Dec(xOff, n - x);
  xOff := Max(0, xOff);
  Paint;

End;

Procedure SP_Edit.FlashTimer(p: Pointer);
Var
  t: Integer;
Begin

  If Focused Then Begin
    t := fCursFg;
    fCursFg := fCursBg;
    fCursBg := t;
  End;
  Paint;

End;

end.
