unit SP_LabelUnit;

{$INCLUDE SpecBAS.inc}

interface

Uses Math, SP_BaseComponentUnit, SP_Errors, SP_Util;

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
    procedure WrapCaption;
    Procedure Prepare;
    Procedure Draw; Override;

    Property Caption: aString read fCaption write SetCaption;
    Property TextJustify: Integer read fJustify write SetJustify;
    Property TextAlign: Integer read fAlign write SetAlign;
    Property AutoSize: Boolean read fAutoSize write SetAutoSize;

    Constructor Create(Owner: SP_BaseComponent);
    Destructor Destroy; Override;

    // User Properties

    Procedure RegisterProperties; Override;
    Procedure Set_Caption(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Caption: aString;
    Procedure Set_Justify(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_Justify: aString;
    Procedure Set_vAlign(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_vAlign: aString;
    Procedure Set_AutoSize(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode); Function Get_AutoSize: aString;

  End;

implementation

Uses SP_Components;

// SP_Label

Constructor SP_Label.Create(Owner: SP_BaseComponent);
Begin

  Inherited;

  fTypeName := 'spLabel';

  fJustify := -1;
  fAlign := -1;
  fCaption := '';
  fTransparent := True;
  fBackgroundClr := 255;
  fBorder := False;
  fLines := TStringlist.Create;

End;

Destructor SP_Label.Destroy;
Begin

  fLines.Free;
  Inherited;

End;

procedure SP_Label.WrapCaption;
var
  CurrentLine: aString;
  CurrentCharIdx: Integer;
  LineCharCount: Integer;
  LastSeparatorIdx: Integer;
  WordStartIdx: Integer;
  CharWidth: Integer;
  maxw: Integer;
begin
  fLines.Clear;
  CurrentLine := '';
  CurrentCharIdx := 1;
  LineCharCount := 0;
  LastSeparatorIdx := 0;
  WordStartIdx := 1;
  CharWidth := 1;

  If AutoSize Then
    maxw := MAXINT
  else
    maxw := fWidth div Round(iFW * iSX);

  while CurrentCharIdx <= Length(fCaption) do
  begin
    case Ord(fCaption[CurrentCharIdx]) of
      13: // Carriage return
        begin
          fLines.Add(CurrentLine);
          CurrentLine := '';
          LineCharCount := 0;
          LastSeparatorIdx := 0;
          Inc(CurrentCharIdx);
          WordStartIdx := CurrentCharIdx;
          Continue;
        end;
      6, 7, 8, 9, 10: // PRINT comma, Cursor Left/right/up/down
        begin
          CurrentLine := CurrentLine + fCaption[CurrentCharIdx];
          Inc(CurrentCharIdx);
          Inc(LineCharCount);
          LastSeparatorIdx := 0;
          Continue;
        end;
      15, 16, 17, 18, 19, 20, 23, 24, 26, 27: // FONT/INK/PAPER/OVER/TRANSPARENT/INVERSE/TAB/ITALIC/BOLD control
        begin
          CurrentLine := CurrentLine + Copy(fCaption, CurrentCharIdx, SizeOf(LongWord) +1);
          Inc(CurrentCharIdx, SizeOf(LongWord) +1);
          LastSeparatorIdx := 0;
          Continue;
        end;
      21, 22: // MOVE, AT control
        begin
          CurrentLine := CurrentLine + Copy(fCaption, CurrentCharIdx, (SizeOf(LongWord) * 2)+1);
          Inc(CurrentCharIdx, (SizeOf(LongWord) * 2)+1);
          LastSeparatorIdx := 0;
          Continue;
        end;
      25: // SCALE control
        begin
          CurrentLine := CurrentLine + Copy(fCaption, CurrentCharIdx, (SizeOf(aFloat) * 2) +1);
          Inc(CurrentCharIdx, (SizeOf(aFloat) * 2)+1);
          LastSeparatorIdx := 0;
          Continue;
        end;
      else
        begin
          if (maxw > 0) And ((LineCharCount + CharWidth) > maxw) then
          begin
            if LastSeparatorIdx > 0 then
            begin
              fLines.Add(Copy(fCaption, WordStartIdx, LastSeparatorIdx - WordStartIdx));
              CurrentCharIdx := LastSeparatorIdx + 1;
            end
            else
            begin
              fLines.Add(Copy(fCaption, WordStartIdx, maxw));
              CurrentCharIdx := WordStartIdx + maxw;
            end;
            CurrentLine := '';
            LineCharCount := 0;
            LastSeparatorIdx := 0;
            WordStartIdx := CurrentCharIdx;
            Continue;
          end;
          if fCaption[CurrentCharIdx] in Seps then
          begin
            LastSeparatorIdx := CurrentCharIdx;
          end;
          if (CurrentLine = '') and (fCaption[CurrentCharIdx] = ' ') then
          begin
            Inc(CurrentCharIdx);
            WordStartIdx := CurrentCharIdx;
            Continue;
          end;
          CurrentLine := CurrentLine + fCaption[CurrentCharIdx];
          Inc(LineCharCount, CharWidth);
          Inc(CurrentCharIdx);
        end;
    end;
  end;

  if CurrentLine <> '' then
    fLines.Add(CurrentLine);
end;


Procedure SP_Label.Prepare;
Var
  i, l, maxw, cfW, cfH: Integer;
Begin

  cfW := Round(iFW * iSX);
  cfH := Round(iFH * iSY);

  If (fWidth < cFW) and Not fAutoSize Then Exit;

  WrapCaption;

  maxw := 0;
  For i := 0 To fLines.Count -1 Do Begin
    l := StripLen(fLines[i]);
    If l > maxw Then maxw := l;
  End;

  If fAutoSize Then Begin
    Width := maxw * cFW;
    Height := Max(fLines.Count, 1) * cFH;
  End;

  fCapLen := maxw;

End;

Procedure SP_Label.Draw;
Var
  bOffs, i, x, y, cfW, cfH: Integer;
Begin

  cfW := Round(iFW * iSX);
  cfH := Round(iFH * iSY);

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
          y := (fHeight - (fLines.Count * cFH)) Div 2;
        End;
      1:
        Begin // Bottom
          y := fHeight - (fLines.Count * cFH);
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
            x := ((fWidth - bOffs) - (StripLen(fLines[i]) * cFW)) Div 2;
          End;
        1:
          Begin // Right Justify
            x := (fWidth - bOffs) - (StripLen(fLines[i]) * cFW);
          End;
      End;
      If fEnabled Then
        PRINT(x, y, fLines[i], fFontClr, -1, iSX, iSY, False, False, False, False)
      Else
        PRINT(x, y, fLines[i], fDisabledFontClr, -1, iSX, iSY, False, False, False, False);
      Inc(y, cFH);

    End;

  End Else Begin

    Case fAlign of
      -1: y := 0;
       0: y := (fHeight - cFH) Div 2;
       1: y := fHeight - cFH;
    End;

    Case fJustify Of
      -1: x := bOffs;
       0: x := ((fWidth - bOffs) - (fCaplen * cFW)) Div 2;
       1: x := (fWidth - bOffs) - (fCaplen * cFW);
    End;
    If fEnabled Then
      PRINT(x, y, fCaption, fFontClr, -1, iSX, iSY, False, False, False, False)
    Else
      PRINT(x, y, fCaption, fDisabledFontClr, -1, iSX, iSY, False, False, False, False);

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

// User Properties

Procedure SP_Label.RegisterProperties;
Begin

  Inherited;

  RegisterProperty('caption', Get_Caption, Set_Caption, ':s|s');
  RegisterProperty('halign', Get_Justify, Set_Justify, ':v|v');
  RegisterProperty('valign', Get_vAlign, Set_vAlign, ':v|v');
  RegisterProperty('autosize', Get_AutoSize, Set_AutoSize, ':v|v');

End;

Procedure SP_Label.Set_Caption(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  Caption := s;

End;

Function SP_Label.Get_Caption: aString;
Begin

  Result := Caption;

End;

Procedure SP_Label.Set_Justify(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  TextJustify := StringToInt(s, TextJustify);

End;

Function SP_Label.Get_Justify: aString;
Begin

  Result := IntToString(TextJustify);

End;

Procedure SP_Label.Set_vAlign(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  TextAlign := StringToInt(s, TextAlign);

End;

Function SP_Label.Get_vAlign: aString;
Begin

  Result := IntToString(TextAlign);

End;

Procedure SP_Label.Set_AutoSize(s: aString; Var Handled: Boolean; Var Error: TSP_ErrorCode);
Begin

  AutoSize := StringToInt(s, 0) <> 0;

End;

Function SP_Label.Get_AutoSize: aString;
Begin

  Result := IntToString(Ord(AutoSize));

End;

end.
