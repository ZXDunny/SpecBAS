unit SP_UITools;

interface

Uses Types, SysUtils, Math, SP_Tokenise, SP_Components, SP_Util, SP_BankFiling, SP_Errors, SP_SysVars, SP_Graphics, SP_FileIO, SP_BankManager, SP_Package,
     SP_ButtonUnit, SP_RadioGroupUnit, SP_BaseComponentUnit, SP_CheckBoxUnit, SP_ComboBoxUnit, SP_LabelUnit, SP_FileListBoxUnit, SP_EditUnit, SP_ContainerUnit;

Type

  SP_FindReplace = Class
    FindMode: Boolean;
    okBtn, allBtn, caBtn: SP_Button;
    dirGroup, originGroup: SP_RadioGroup;
    caseChk, wholeChk, inselChk, expChk: SP_CheckBox;
    searchEdt, replaceEdt: SP_ComboBox;
    searchLbl, replaceLbl: SP_Label;
    Function Open(Mode: Boolean): Integer;
    Procedure OkBtnClick(Sender: SP_BaseComponent);
    Procedure CancelBtnClick(Sender: SP_BaseComponent);
    Procedure searchEdtChange(Sender: SP_BaseComponent; Text: aString);
    Procedure Accept(Sender: SP_BaseComponent; s: aString);
    Procedure Abort(Sender: SP_BaseComponent);
    Procedure expChkChange;
  end;

  SP_FileRequester = Class
    pBtn, okBtn, caBtn: SP_Button;
    chk: SP_CheckBox;
    PathEdt, FilenameEdt: SP_Edit;
    FilesList: SP_FileListBox;
    Function Open(Caption, Filename: aString; Save: Boolean; Var Error: TSP_ErrorCode): aString;
    procedure ParentButtonClick(Sender: SP_BaseComponent);
    procedure okBtnClick(Sender: SP_BaseComponent);
    procedure caBtnClick(Sender: SP_BaseComponent);
    procedure ChooseDir(Sender: SP_BaseComponent; s: aString);
    procedure ChooseFile(Sender: SP_BaseComponent; s: aString);
    Procedure SelectFile(Sender: SP_BaseComponent; i: Integer);
    Procedure AcceptFile(Sender: SP_BaseComponent; s: aString);
    Procedure AcceptDir(Sender: SP_BaseComponent; s: aString);
    Procedure ChangeFilename(Sender: SP_BaseComponent; s: aString);
    Procedure Abort(Sender: SP_BaseComponent);
  end;

  SP_TextRequester = Class
    LineEdt: SP_Edit;
    okBtn, caBtn: SP_Button;
    shouldEvaluate: Boolean;
    TextKind: Integer;
    Function Open(Caption, DefaultText: aString; Kind: Integer; Evaluate: Boolean; Var Error: TSP_ErrorCode): aString;
    Procedure okBtnClick(Sender: SP_BaseComponent);
    Procedure caBtnClick(Sender: SP_BaseComponent);
    Procedure Abort(Sender: SP_BaseComponent);
    Procedure Accept(Sender: SP_BaseComponent; s: aString);
    Procedure lineEdtChange(Sender: SP_BaseComponent; Text: aString);
  End;

  SP_BreakPointWindow = Class
    cmbType: SP_ComboBox;
    edtLine, edtCondition, edtPassCount: SP_Edit;
    lblLine, lblCondition, lblPassCount, lblType: SP_Label;
    okBtn, caBtn: SP_Button;
    Width, Height, FW, FH: Integer;
    Caption: aString;
    Accepted: Boolean;
    BpLine, BpSt, BpPasses: Integer;
    BpCondition: aString;
    Procedure Open(BpIndex, BpType, Line, Statement, PassCount: Integer; Caption, Condition: aString);
    Procedure PlaceControls;
    Procedure ValidateFields;
    Procedure TypeChange(Sender: SP_BaseComponent; Text: aString);
    Procedure edtLineChange(Sender: SP_BaseComponent; Text: aString);
    Procedure okBtnClick(Sender: SP_BaseComponent);
    Procedure caBtnClick(Sender: SP_BaseComponent);
    Procedure Accept(Sender: SP_BaseComponent; s: aString);
    Procedure Abort(Sender: SP_BaseComponent);
  End;

  Function OpenFileReq(Caption, Filename: aString; Save: Boolean; Var Error: TSP_ErrorCode): aString;

Const

  tkLineStatement = 0;
  tkAnyExpression = 1;
  tkString        = 2;
  tkNumeric       = 3;
  tkText          = 4;

Var

  DefaultWindow: Integer;

implementation

Uses SP_Main, SP_FPEditor, SP_Input, MainForm, SP_Interpret_PostFix;

Var

  FDWindowID: Integer;
  SearchHistory: TStringlist;
  ReplaceHistory: TStringlist;

Procedure WaitForDialog;
Var
  Locked, Mouse: Boolean;
Begin

  Mouse := MOUSEVISIBLE;
  Locked := SCREENLOCK;
  SCREENLOCK := False;
  MOUSEVISIBLE := True;
  While Not ToolWindowDone Do Begin
    SP_WaitForSync;
    If SP_KeyEventWaiting Then
      SP_UnBufferKey;
    DoTimerEvents;
  End;
  SCREENLOCK := Locked;
  MOUSEVISIBLE := Mouse;

End;

Function CreateToolWindow(Caption: aString; Left, Top, Width, Height: Integer): Integer;
Var
  Idx: Integer;
  Win: pSP_Window_Info;
  Error: TSP_ErrorCode;
Begin

  DefaultWindow := SCREENBANK;
  FPEditorDRPOSX := DRPOSX;
  FPEditorDRPOSY := DRPOSY;
  FPEditorPRPOSX := PRPOSX;
  FPEditorPRPOSY := PRPOSY;
  FPEditorOVER := COVER;

  COVER := 0;
  T_OVER := COVER;

  Result := SP_Add_Window(Left, Top, Width, Height, -1, 8, 0, Error);

  COVER := 0;
  CINVERSE := 0;
  CITALIC := 0;
  CBOLD := 0;
  SP_GetWindowDetails(Result, Win, Error);
  For Idx := 0 To 255 Do Win^.Palette[Idx] := DefaultPalette[Idx];

  SP_Decorate_Window(Result, Caption, True, False, True);
  SP_FillRect(1, FPFh +2, Win^.Width -2, Win^.Height - (FPFh + 3), SP_UIWindowBack);

  DRPOSX := FPEditorDRPOSX;
  DRPOSY := FPEditorDRPOSY;
  PRPOSX := FPEditorPRPOSX;
  PRPOSY := FPEditorPRPOSY;
  COVER := FPEditorOVER;
  T_OVER := COVER;
  SP_SetDrawingWindow(DefaultWindow);

  MODALWINDOW := Result;

End;

// File requester

Function OpenFileReq(Caption, Filename: aString; Save: Boolean; Var Error: TSP_ErrorCode): aString;
Var
  FileReq: SP_FileRequester;
Begin

  FileReq := SP_FileRequester.Create;
  Result := FileReq.Open(Caption, Filename, Save, Error);
  FileReq.Free;

End;

Procedure SP_FileRequester.Abort(Sender: SP_BaseComponent);
Begin

  ToolStrResult := '';
  ToolWindowDone := True;

End;

Procedure SP_FileRequester.ParentButtonClick(Sender: SP_BaseComponent);
begin

  FilesList.GoParent;
  PathEdt.Text := FilesList.Directory;

End;

Procedure SP_FileRequester.ChooseDir(Sender: SP_BaseComponent; s: aString);
Begin

  pathEdt.Text := FilesList.Directory;
  OkBtn.Enabled := False;

End;

Procedure SP_FileRequester.OkBtnClick(Sender: SP_BaseComponent);
Begin

  ChooseFile(Sender, FilenameEdt.Text);

End;

Procedure SP_FileRequester.caBtnClick(Sender: SP_BaseComponent);
Begin

  Abort(nil);

End;

Procedure SP_FileRequester.ChooseFile(Sender: SP_BaseComponent; s: aString);
Var
  p: aString;
Begin

  If s <> '' Then Begin
    p := FilesList.Directory;
    If Copy(p, Length(p), 1) <> '/' Then
      p := p + '/';
    FilenameEdt.Text := s;
    ToolStrResult := p + s;
  End Else
    ToolStrResult := '';
  ToolWindowDone := True;

End;

Procedure SP_FileRequester.SelectFile(Sender: SP_BaseComponent; i: Integer);
Var
  p, s, t: aString;
Begin

  p := FilesList.Directory;
  If Copy(p, Length(p), 1) <> '/' Then
    p := p + '/';
  s := FilesList.Items[i];
  If FocusedControl <> FileNameEdt Then
    FilenameEdt.Text := Copy(s, 2, Pos(#255, s) -2)
  Else
    FilenameEdt.GhostText := Copy(s, 2, Pos(#255, s) -2);

  okBtn.Enabled := SP_FileExists(p + FilenameEdt.Text) or (ToolMode = 2);

End;

Procedure SP_FileRequester.AcceptFile(Sender: SP_BaseComponent; s: aString);
Var
  p: aString;
Begin

  If s = '' Then AcceptDir(Sender, '') Else Begin
    If s <> #0 Then Begin
      p := FilesList.Directory;
      If Copy(p, Length(p), 1) <> '/' Then
        p := p + '/';
      ToolStrResult := p + s;
    End Else
      ToolStrResult := '';
    ToolWindowDone := True;
  End;

End;

Procedure SP_FileRequester.AcceptDir(Sender: SP_BaseComponent; s: aString);
Begin

  FilesList.Directory := pathEdt.Text;

End;

Procedure SP_FileRequester.ChangeFilename(Sender: SP_BaseComponent; s: aString);
Var
  p: aString;
Begin

  FilesList.Find(s);
  p := FilesList.Directory;
  If Copy(p, Length(p), 1) <> '/' Then
    p := p + '/';
  s := p + s;
  okBtn.Enabled := SP_FileExists(s) or (ToolMode = 2);

End;

Function SP_FileRequester.Open(Caption, Filename: aString; Save: Boolean; Var Error: TSP_ErrorCode): aString;
Var
  Win: pSP_Window_Info;
  Font, cw, w, h, fw, fh: Integer;
  Str: aString;
Begin

  DisplaySection.Enter;

  Font := SP_SetFPEditorFont;

  ToolWindowDone := False;
  If Save Then ToolMode := 2 Else ToolMode := 1;

  If SYSTEMSTATE in [SS_EDITOR, SS_DIRECT, SS_NEW, SS_ERROR] Then Begin
    FW := Trunc(FONTWIDTH * EDFONTSCALEX);
    FH := Trunc(FONTHEIGHT * EDFONTSCALEY);
  End Else Begin
    FH := FONTHEIGHT;
    FW := FONTWIDTH;
  End;

  w := 35 * FW; h := DISPLAYHEIGHT - (DISPLAYHEIGHT Div 8);
  FDWindowID := CreateToolWindow(Caption, (DISPLAYWIDTH - w) Div 2, (DISPLAYHEIGHT - h) Div 2, w, h);
  SP_GetWindowDetails(FDWindowID, Win, Error);
  SP_SetDrawingWindow(FDWindowID);

  // Add controls - parent button, path, file list, filename, ok, cancel

  pBtn := SP_Button.Create(Win^.Component);
  pBtn.SetBounds(7, FPFh + 8, Fw + 4, Fh + 4);
  pBtn.OverrideScaling := True;
  pBtn.Caption := #251;
  pBtn.CentreCaption;
  pBtn.Enabled := True;

  PathEdt := SP_Edit.Create(Win^.Component);
  PathEdt.SetBounds(pBtn.Left + pBtn.Width + 6, pBtn.Top, w - pBtn.Width - 20, Fh);
  If PackageIsOpen Then
    Str := SP_GetPackageDir
  Else Begin
    Str := SP_ExtractFileDir(Filename);
    If Str = '' Then
      Str := SP_ConvertHostFilename(aString(GetCurrentDir), Error);
  End;
  PathEdt.RightJustify := True;
  PathEdt.Text := SP_DecomposePathWithAssigns(Str);
  PathEdt.SetFocus(False);

  caBtn := SP_Button.Create(Win^.Component);
  caBtn.Caption := 'Cancel';
  cw := Fw * (Length(caBtn.Caption) +2);
  caBtn.SetBounds(w - (cw + 7), h - (FH + 11), cw, FH + 4);
  caBtn.CentreCaption;
  caBtn.Enabled := True;

  okBtn := SP_Button.Create(Win^.Component);
  okBtn.Caption := 'Okay';
  cw := Fw * (Length(OkBtn.Caption) + 2);
  okBtn.SetBounds(caBtn.Left - (cw + 6), caBtn.Top, cw, FH + 4);
  okBtn.CentreCaption;

  FilenameEdt := SP_Edit.Create(Win^.Component);
  FilenameEdt.SetBounds(pBtn.Left, okBtn.Top - (Fh + 10), w - 14, Fh);
  If SP_FileExists(Filename) Then
    FilenameEdt.Text := SP_ExtractFileName(Filename)
  Else
    FilenameEdt.Text := '';
  okBtn.Enabled := SP_FileExists(Filename) or (ToolMode = 2);

  FilesList := SP_FileListBox.Create(Win^.Component);
  FilesList.SetBounds(FilenameEdt.Left + 2, pBtn.Top + pBtn.Height + 8, FilenameEdt.Width -4, FilenameEdt.Top - PathEdt.Top - FileNameEdt.Height - 16);
  FilesList.Directory := PathEdt.Text;
  FilesList.Transparent := False;
  FilesList.Find(SP_ExtractFilename(Filename));

  FilenameEdt.ChainControl := FilesList;
  PathEdt.ChainControl := FilesList;
  FilesList.ChainControl := FilenameEdt;
  FilesList.CanFocus := True;
  FilenameEdt.SetFocus(True);

  pBtn.OnClick := ParentButtonClick;
  FilesList.OnChooseDir := ChooseDir;
  FilesList.OnChooseFile := ChooseFile;
  FilesList.OnSelect := SelectFile;
  FilesList.OnAbort := Abort;
  pathEdt.OnAccept := AcceptDir;
  pathEdt.OnAbort := Abort;
  FilenameEdt.OnAccept := AcceptFile;
  FilenameEdt.OnChange := ChangeFilename;
  FilenameEdt.OnAbort := Abort;
  OkBtn.OnClick := OkBtnClick;
  caBtn.OnClick := caBtnClick;

  pBtn.Paint;
  okBtn.Paint;

  SP_SetDrawingWindow(DefaultWindow);

  DisplaySection.Leave;

  // Spin, waiting for the tool to finish.

  WaitForDialog;

  // Set the filename - might be blank.

  DisplaySection.Enter;
  Result := ToolStrResult;
  SP_SetSystemFont(Font, Error);
  SP_DeleteWindow(FDWindowID, Error);
  DisplaySection.Leave;

End;

// Find Dialog

Function SP_FindReplace.Open(Mode: Boolean): Integer;
Var
  Font, FW, FH, w, h, Idx, tp, bw, bh, cw, OldFocus: Integer;
  Caption: aString;
  Win: pSP_Window_Info;
  Error: TSP_ErrorCode;
  Sel: SP_SelectionInfo;
Begin

  DisplaySection.Enter;

  ToolWindowDone := False;

  Font := SP_SetFPEditorFont;
  If SYSTEMSTATE in [SS_EDITOR, SS_DIRECT, SS_NEW, SS_ERROR] Then Begin
    FW := Trunc(FONTWIDTH * EDFONTSCALEX);
    FH := Trunc(FONTHEIGHT * EDFONTSCALEY);
  End Else Begin
    FH := FONTHEIGHT;
    FW := FONTWIDTH;
  End;

  FindMode := Mode;
  If FindMode Then Caption := 'Find...' else Caption := 'Replace...';

  bw := BSize Div 2; bh := BSize Div 2;
  w := 35 * FW; h := FPFh + 21 + (10 * FH) + (Ord(Not FindMode) * (bh + FH)) + (5 * bh);
  FDWindowID := CreateToolWindow(Caption, (DISPLAYWIDTH - w) Div 2, (DISPLAYHEIGHT - h) Div 2, w, h);
  SP_GetWindowDetails(FDWindowID, Win, Error);
  SP_SetDrawingWindow(FDWindowID);

  // Create find dialog controls

  searchLbl := SP_Label.Create(Win^.Component);
  SearchEdt := SP_ComboBox.Create(Win^.Component);

  If FindMode Then Begin
    searchLbl.Caption := 'Find:';
    searchLbl.SetBounds(7 + BSize, FPFh + 10, FW * Length(searchLbl.Caption), FH);
    searchLbl.TextJustify := 1;
    searchEdt.AddStrings(SearchHistory);
    searchEdt.BackgroundClr := SP_UIBackground;
    searchEdt.SetBounds(searchLbl.Left + searchLbl.Width + bw, searchLbl.Top -2, w - (searchLbl.Left + searchLbl.Width + bw) - bw - BSize, searchLbl.Height);
    searchEdt.Editable := True;
    tp := searchEdt.Top + searchEdt.Height + bh;
  End Else Begin
    searchLbl.Caption := 'Replace:';
    searchLbl.SetBounds(7 + BSize, FPFh + 10, FW * Length(searchLbl.Caption), FH);
    searchLbl.TextJustify := 1;
    replaceLbl := SP_Label.Create(Win^.Component);
    replaceLbl.Caption := 'With:';
    replaceLbl.SetBounds(7 + BSize, searchLbl.Top + searchLbl.Height + bh, FW * Length(searchLbl.Caption), FH);
    replaceLbl.TextJustify := 1;
    searchEdt.AddStrings(SearchHistory);
    searchEdt.SetBounds(searchLbl.Left + searchLbl.Width + bw, searchLbl.Top -2, w - (searchLbl.Left + searchLbl.Width + bw) - bw - BSize, searchLbl.Height);
    searchEdt.Editable := True;
    replaceEdt := SP_ComboBox.Create(Win^.Component);
    replaceEdt.AddStrings(ReplaceHistory);
    replaceEdt.SetBounds(searchEdt.Left, searchLbl.Top + searchLbl.Height + bh, searchEdt.Width, searchLbl.Height);
    replaceEdt.Editable := True;
    replaceEdt.OnAccept := Accept;
    replaceEdt.OnAbort := Abort;
    replaceEdt.ChainControl := searchEdt;
    searchEdt.ChainControl := replaceEdt;
    tp := replaceEdt.Top + replaceEdt.Height + bh;
  End;
  searchEdt.OnAccept := Accept;
  searchEdt.OnAbort := Abort;

  dirGroup := SP_RadioGroup.Create(Win^.Component);
  dirGroup.SetBounds(bw + BSize, tp, (29 * bw) - BSize, FH * 5);
  dirGroup.AddItem('Forward');
  dirGroup.AddItem('Backward');
  dirGroup.Caption := 'Direction';

  originGroup := SP_RadioGroup.Create(Win^.Component);
  originGroup.SetBounds(dirGroup.Left + dirGroup.Width + bw, tp, (bw * 38) - BSize, FH * 5);
  originGroup.AddItem('Start of BASIC');
  originGroup.AddItem('Cursor pos');
  originGroup.Caption := 'Origin';

  caseChk := SP_CheckBox.Create(Win^.Component);
  wholeChk  := SP_CheckBox.Create(Win^.Component);
  inselChk := SP_CheckBox.Create(Win^.Component);
  expChk := SP_CheckBox.Create(Win^.Component);

  caseChk.Caption := 'Match case';
  wholeChk.Caption := 'Whole words';
  inselChk.Caption := 'In selection';
  expChk.Caption := 'Expression';

  caseChk.SetBounds(bw + BSize, dirGroup.Top + dirGroup.Height + bh, dirGroup.Width, FH + bh);
  wholeChk.SetBounds(bw + BSize, caseChk.Top + caseChk.Height + bh, dirGroup.Width, FH + bh);
  inselChk.SetBounds(originGroup.Left, CaseChk.Top, originGroup.Width, FH + bh);
  expChk.SetBounds(inselChk.Left, inSelChk.Top + inSelChk.Height + bh, inselChk.Width, FH + bh);

  // Fill options from search options record

  If soForward in FPSearchOptions Then
    dirGroup.ItemIndex := 0
  Else
    dirGroup.ItemIndex := 1;

  If soStart in FPSearchOptions Then
    originGroup.ItemIndex := 0
  Else
    originGroup.ItemIndex := 1;

  caseChk.Checked := soMatchCase in FPSearchOptions;
  wholeChk.Checked := soWholeWords in FPSearchOptions;
  inSelChk.Checked := soInSelection in FPSearchOptions;
  expChk.Checked := soExpression in FPSearchOptions;
  expChk.OnCheck := expChkChange;

  caBtn := SP_Button.Create(Win^.Component);
  caBtn.Caption := 'Cancel';
  cw := Fw * (Length(caBtn.Caption) +2);
  caBtn.SetBounds(w - (cw + BSize + Bh), h - (FH + 11 + Bh), cw, FH + 4);
  caBtn.CentreCaption;
  caBtn.Enabled := True;

  If FindMode Then
    tp := caBtn.Left
  Else Begin
    allBtn := SP_Button.Create(Win^.Component);
    allBtn.Caption := 'Replace All';
    cw := Fw * (Length(allBtn.Caption) + 2);
    allBtn.SetBounds(caBtn.Left - (cw + 6), caBtn.Top, cw, FH + 4);
    allBtn.CentreCaption;
    tp := allBtn.Left;
  End;

  okBtn := SP_Button.Create(Win^.Component);
  okBtn.Caption := 'Okay';
  cw := Fw * (Length(OkBtn.Caption) + 2);
  okBtn.SetBounds(tp - (cw + 6), caBtn.Top, cw, FH + 4);
  okBtn.CentreCaption;

  okBtn.OnClick := OkBtnClick;
  caBtn.OnClick := CancelBtnClick;
  If not FindMode Then
    allBtn.OnClick := OkBtnClick;

  searchEdt.SetFocus(True);
  searchEdt.OnChange := searchEdtChange;
  If Not FindMode Then
    replaceEdt.OnChange := searchEdtChange;

  // Now run the dialog

  OldFocus := FocusedWindow;
  FocusedWindow := -1;
  SP_SetDrawingWindow(DefaultWindow);
  SP_DisplayFPListing(-1);

  SP_GetSelectionInfo(Sel);
  inSelChk.Enabled := Sel.Active;
  If Not FindMode Then Begin
    okBtn.Enabled := (searchEdt.Text <> '') And (replaceEdt.Text <> '');
    AllBtn.Enabled := okBtn.Enabled;
  End Else
    okBtn.Enabled := searchEdt.Text <> '';

  DisplaySection.Leave;

  WaitForDialog;

  SP_SetSystemFont(Font, Error);
  SP_DeleteWindow(FDWindowID, Error);
  SP_InvalidateWholeDisplay;
  FocusedWindow := OldFocus;

End;

Procedure SP_FindReplace.searchEdtChange(Sender: SP_BaseComponent; Text: aString);
Var
  b: Boolean;
  s: aString;
  Error: TSP_ErrorCode;
Begin

  b := True;
  If expChk.Checked And (SearchEdt.Text <> '') Then Begin
    Error.Code := SP_ERR_OK;
    s := SP_FPExecuteAnyExpression(SearchEdt.Text, Error);
    b := Error.Code = SP_ERR_OK;
    If not b Then
      expChk.FontClr := 2
    else
      expChk.FontClr := 4;
    If Not FindMode Then
      If b And (ReplaceEdt.Text <> '') Then Begin
        s := SP_FPExecuteAnyExpression(ReplaceEdt.Text, Error);
        b := Error.Code = SP_ERR_OK;
        If not b Then
          expChk.FontClr := 2
        else
          expChk.FontClr := 4;
      End;
  End Else
      expChk.FontClr := 0;
  If FindMode Then
    OkBtn.Enabled := b And (SearchEdt.Text <> '')
  Else Begin
    OkBtn.Enabled := b And (SearchEdt.Text <> '') And (ReplaceEdt.Text <> '');
    allBtn.Enabled := OkBtn.Enabled;
  End;

End;

Procedure SP_FindReplace.expChkChange;
Begin

  searchEdtChange(nil, searchEdt.Text);

End;

Procedure SP_FindReplace.OkBtnClick(Sender: SP_BaseComponent);
Var
  i: Integer;
  sOpt: SP_SearchOptions;
  Error: TSP_ErrorCode;
Begin

  sOPt := [];
  FPSearchTerm := searchEdt.Text;
  If Sender = allBtn Then
    sOpt := sOpt + [soAll];

  If Not FindMode Then FPReplaceTerm := replaceEdt.Text;
  If dirGroup.ItemIndex = 0 Then sOpt := sOpt + [soForward] else sOpt := sOpt + [soBackwards];
  If originGroup.ItemIndex = 0 Then sOpt := sOpt + [soStart] else sOpt := sOpt + [soCursorPos];
  If caseChk.Checked Then sOpt := sOpt + [soMatchCase];
  If wholeChk.Checked Then sOpt := sOpt + [soWholeWords];
  If inselChk.Checked Then sOpt := sOpt + [soInSelection];
  If expChk.Checked Then Begin
    sOpt := sOpt + [soExpression];
    FPSearchTerm := SP_FPExecuteAnyExpression(SearchEdt.Text, Error);
    If not FindMode Then
      FPReplaceTerm := SP_FPExecuteAnyExpression(FPReplaceTerm, Error);
  End;

  If FPSearchTerm <> '' then Begin
    i := SearchHistory.IndexOf(FPSearchTerm);
    If i > -1 Then
      SearchHistory.Delete(i);
    SearchHistory.Insert(0, FPSearchTerm);
  End;

  If not FindMode Then
    If FPReplaceTerm <> '' then Begin
      i := ReplaceHistory.IndexOf(FPReplaceTerm);
      If i > -1 Then
        ReplaceHistory.Delete(i);
      ReplaceHistory.Insert(0, FPReplaceTerm);
    End;

  FPSearchOptions := sOpt;
  ToolWindowDone := True;

End;

Procedure SP_FindReplace.CancelBtnClick(Sender: SP_BaseComponent);
Begin

  ToolWindowDone := True;

End;

Procedure SP_FindReplace.Accept(Sender: SP_BaseComponent; s: aString);
Begin
  If OkBtn.Enabled Then
    OkBtnClick(Sender);
End;

Procedure SP_FindReplace.Abort(Sender: SP_BaseComponent);
Begin
  ToolWindowDone := True;
End;

{ Text requester }

Function SP_TextRequester.Open(Caption, DefaultText: aString; Kind: Integer; Evaluate: Boolean; Var Error: TSP_ErrorCode): aString;
Var
  Font, w, h, cw, OldFocus: Integer;
  win: pSP_Window_Info;
Begin

  DisplaySection.Enter;

  ToolWindowDone := False;
  shouldEvaluate := Evaluate;
  TextKind := Kind;

  Font := SP_SetFPEditorFont;
  If SYSTEMSTATE in [SS_EDITOR, SS_DIRECT, SS_NEW, SS_ERROR] Then Begin
    FW := Trunc(FONTWIDTH * EDFONTSCALEX);
    FH := Trunc(FONTHEIGHT * EDFONTSCALEY);
  End Else Begin
    FH := FONTHEIGHT;
    FW := FONTWIDTH;
  End;

  w := (45 * FW) + (BSize * 2); h := (BSize * 3) + (FH + 2) + (FH + 4) + (FH + 4);
  FDWindowID := CreateToolWindow(Caption, (DISPLAYWIDTH - w) Div 2, (DISPLAYHEIGHT - h) Div 2, w, h);
  SP_GetWindowDetails(FDWindowID, Win, Error);
  SP_SetDrawingWindow(FDWindowID);

  // Create find goto controls

  LineEdt := SP_Edit.Create(Win^.Component);
  lineEdt.BackgroundClr := SP_UIBackground;
  lineEdt.SetBounds(BSize, FPFh + 10, w - (BSize * 2), 0);
  lineEdt.Editable := True;
  lineEdt.OnAccept := Accept;
  lineEdt.OnAbort := Abort;
  lineEdt.OnChange := LineEdtChange;
  lineEdt.SetFocus(True);

  caBtn := SP_Button.Create(Win^.Component);
  caBtn.Caption := 'Cancel';
  cw := Fw * (Length(caBtn.Caption) +2);
  caBtn.SetBounds(w - (cw + BSize), h - (FH + 11 + BSize), cw, FH + 11);
  caBtn.CentreCaption;
  caBtn.Enabled := True;

  okBtn := SP_Button.Create(Win^.Component);
  okBtn.Caption := 'Okay';
  cw := Fw * (Length(OkBtn.Caption) + 2);
  okBtn.SetBounds(caBtn.Left - (cw + 6), caBtn.Top, cw, FH + 11);
  okBtn.CentreCaption;
  okBtn.Enabled := False;

  okBtn.OnClick := okBtnClick;
  caBtn.OnClick := caBtnClick;

  // Now run the dialog

  OldFocus := FocusedWindow;
  FocusedWindow := -1;
  SP_DisplayFPListing(-1);
  SP_SetDrawingWindow(DefaultWindow);

  DisplaySection.Leave;

  FPGotoText := '';
  WaitForDialog;

  SP_SetSystemFont(Font, Error);
  SP_DeleteWindow(FDWindowID, Error);
  SP_InvalidateWholeDisplay;
  FocusedWindow := OldFocus;

End;

Procedure SP_TextRequester.OkBtnClick(Sender: SP_BaseComponent);
Begin
  FPGotoText := LineEdt.Text;
  ToolWindowDone := True;
End;

Procedure SP_TextRequester.caBtnClick(Sender: SP_BaseComponent);
Begin
  ToolWindowDone := True;
End;

Procedure SP_TextRequester.Accept(Sender: SP_BaseComponent; s: aString);
Begin
  If OkBtn.Enabled Then
    OkBtnClick(Sender);
End;

Procedure SP_TextRequester.Abort(Sender: SP_BaseComponent);
Begin
  ToolWindowDone := True;
End;

Procedure SP_TextRequester.lineEdtChange(Sender: SP_BaseComponent; Text: aString);
Var
  Error: TSP_ErrorCode;
  s, l, lineTxt, statementTxt: aString;
  b: Boolean;
  searchOpt: SP_SearchOptions;
  Found: TPoint;
  line, statement: aFloat;
  i: Integer;
Begin

  If LineEdt.Text <> '' Then Begin

    i := 1;
    Found.y := -1;
    Error.Code := SP_ERR_OK;

    If Pos(':', lineEdt.Text) > 0 Then Begin
      LineTxt := Copy(Text, 1, Pos(':', Text) -1);
      StatementTxt := Copy(Text, Pos(':', Text) +1);
    End Else Begin
      LineTxt := Text;
      StatementTxt := '1';
    End;

    If TextKind = tkLineStatement Then Begin

      l := SP_FPExecuteAnyExpression(LineTxt, Error);
      If Error.Code = SP_ERR_OK Then
        s := SP_FPExecuteAnyExpression(StatementTxt, Error);

      b := (Error.Code = SP_ERR_OK) and SP_GetNumber(l, i, line, True);
      i := 1;
      b := b And SP_GetNumber(s, i, statement, True);

      If Not b Then Begin
        searchOpt := [soForward, soCondenseSpaces];
        Found := SP_FindText('LABEL @'+lineEdt.Text, 0, 1, searchOpt);
        b := Found.y >= 0;
      End;

    End Else Begin

      b := SP_FPCheckExpression(Text, Error);

      If TextKind = tkAnyExpression Then Begin

        If b and ShouldEvaluate Then Begin
          SP_FPExecuteAnyExpression(Text, Error);
          b := Error.Code = SP_ERR_OK;
        End;

      End Else

        If TextKind = tkString Then Begin

          If b and ShouldEvaluate Then Begin
            SP_FPExecuteStringExpression(Text, Error);
            b := Error.Code = SP_ERR_OK;
          End;

        End Else

          If TextKind = tkNumeric Then Begin

            If b and ShouldEvaluate Then Begin
              SP_FPExecuteNumericExpression(Text, Error);
              b := Error.Code = SP_ERR_OK;
            End;

          End Else

            If TextKind = tkText Then Begin

              b := True;

            End;

    End;

    okBtn.Enabled := b;
    lineEdt.ValidText := b;

  End Else Begin

    okBtn.Enabled := False;
    lineEdt.ValidText := False;

  End;

End;

{ Breakpoint Window }

Procedure SP_BreakpointWindow.Open(BpIndex, BpType, Line, Statement, PassCount: Integer; Caption, Condition: aString);
Var
  Font, w, h, cw, OldFocus: Integer;
  win: pSP_Window_Info;
  Error: TSP_ErrorCode;
begin

  // Edit a breakpoint.

  DisplaySection.Enter;

  ToolWindowDone := False;

  Font := SP_SetFPEditorFont;
  If SYSTEMSTATE in [SS_EDITOR, SS_DIRECT, SS_NEW, SS_ERROR] Then Begin
    FW := Trunc(FONTWIDTH * EDFONTSCALEX);
    FH := Trunc(FONTHEIGHT * EDFONTSCALEY);
  End Else Begin
    FH := FONTHEIGHT;
    FW := FONTWIDTH;
  End;

  w := (45 * FW) + (BSize * 2) -2;
  h := (BSize * 3) + (FH + 2) + ((FH + 4) * 4);
  Width := w; Height := h;
  Self.Caption := Caption;
  FDWindowID := CreateToolWindow(Caption, (DISPLAYWIDTH - w) Div 2, (DISPLAYHEIGHT - h) Div 2, w, h);
  SP_GetWindowDetails(FDWindowID, Win, Error);
  SP_SetDrawingWindow(FDWindowID);

  // Create controls

  lblType := SP_Label.Create(Win^.Component);
  lblType.Caption := 'Type';
  lblType.SetBounds(7 + (10 * FW) + BSize, FPFh + 10, FW * Length(lblType.Caption), FH);
  lblType.TextJustify := 1;

  cmbType := SP_ComboBox.Create(Win^.Component);
  cmbType.SetBounds(lblType.Left + lblType.Width + BSize, lblType.Top -2, 17 * FW, LblType.Height);
  cmbType.AddItem('Source');
  cmbType.AddItem('Conditional');
  cmbType.AddItem('Data');
  cmbType.BackgroundClr := SP_UIWindowBack;

  edtLine := SP_Edit.Create(Win^.Component);
  edtLine.OnChange := edtLineChange;
  edtCondition := SP_Edit.Create(Win^.Component);
  edtCondition.OnChange := edtLineChange;
  edtPassCount := SP_Edit.Create(Win^.Component);
  edtPassCount.OnChange := edtLineChange;

  lblLine := SP_Label.Create(Win^.Component);
  lblLine.Caption := 'Line:Statement';
  lblCondition := SP_Label.Create(Win^.Component);
  lblCondition.Caption := 'Condition';
  lblPassCount := SP_Label.Create(Win^.Component);
  lblPassCount.Caption := 'Pass count';

  cmbType.ChainControl := edtLine;
  cmbType.OnAccept := Accept;
  cmbType.OnAbort := Abort;
  edtLine.ChainControl := edtCondition;
  edtCondition.ChainControl := edtPassCount;
  edtPassCount.ChainControl := cmbType;

  caBtn := SP_Button.Create(Win^.Component);
  caBtn.Caption := 'Cancel';
  caBtn.OnClick := caBtnClick;
  okBtn := SP_Button.Create(Win^.Component);
  okBtn.Caption := 'Okay';
  okBtn.OnClick := okBtnClick;

  // Populate with data passed in

  Case BpType of
    BP_Stop:
      Begin
        cmbType.ItemIndex := 0;
        edtLine.Text := IntToString(Line) + ':' + IntToString(Statement);
        edtCondition.Text := Condition;
      End;
    BP_Conditional:
      Begin
        cmbType.ItemIndex := 1;
        edtCondition.Text := Condition;
      End;
    BP_Data:
      Begin
        cmbType.ItemIndex := 2;
        edtCondition.Text := Condition;
      End;
  End;

  cmbType.OnChange := TypeChange;
  edtPassCount.Text := IntToString(PassCount);

  PlaceControls;
  ValidateFields;

  // Now run the dialog

  Accepted := False;
  OldFocus := FocusedWindow;
  FocusedWindow := -1;
  SP_DisplayFPListing(-1);
  SP_SetDrawingWindow(DefaultWindow);

  DisplaySection.Leave;

  WaitForDialog;

  If Accepted Then Begin

    // No need to validate the input, it's already validated on control change

    Case cmbType.ItemIndex of
      0: // Source breakpoint - remove the old one first!
        Begin
          SP_AddSourceBreakpoint(False, Line, Statement, 0, '');
          SP_AddSourceBreakpoint(False, BpLine, BpSt, BpPasses, BpCondition);
        End;
      1: // Conditional breakpoint
        Begin
          SP_AddConditionalBreakpoint(BpIndex, BpPasses, BpCondition, False);
        End;
      2: // Data breakpoint
        Begin
          SP_AddConditionalBreakpoint(BpIndex, BpPasses, BpCondition, True);
        End;
    End;

  End;

  SP_SetSystemFont(Font, Error);
  SP_DeleteWindow(FDWindowID, Error);
  SP_DisplayFPListing(-1);
  SP_InvalidateWholeDisplay;
  FocusedWindow := OldFocus;

end;

Procedure SP_BreakpointWindow.PlaceControls;
Var
  y, cw: Integer;
  Win: pSP_Window_Info;
  Error: TSP_ErrorCode;
Begin

  SP_GetWindowDetails(FDWindowID, Win, Error);
  SP_SetDrawingWindow(FDWindowID);

  lblCondition.Visible := True;
  edtCondition.Visible := True;
  lblPassCount.Visible := True;
  edtPassCount.Visible := True;
  y := lblType.Top + lblType.Height + BSize;

  lblLine.Enabled := cmbType.ItemIndex = 0;
  edtLine.Enabled := lblLine.Enabled;
  lblLine.SetBounds(7 + BSize, y + 2, Length(LblLine.Caption) * FW, FH);
  edtLine.SetBounds(lblLine.Left + lblLine.Width + BSize, y, 10 * FW, FH);
  Inc(y, FH + BSize);
  Height := 160;

  edtCondition.SetBounds(edtLine.Left, y, 29 * FW, FH);
  lblCondition.SetBounds(edtCondition.Left - BSize - (Length(lblCondition.Caption) * FW), y + 2, Length(lblCondition.Caption) * FW, FH);
  Inc(y, FH + BSize);
  edtPassCount.SetBounds(edtLine.Left, y, 7 * FW, FH);
  lblPassCount.SetBounds(edtPassCount.Left - BSize - (Length(lblPassCount.Caption) * FW), y + 2, Length(lblPassCount.Caption) * FW, FH);
  edtCondition.OnAccept := Accept;
  edtLine.OnAccept := Accept;
  edtPassCount.OnAccept := Accept;

  edtCondition.OnAbort := Abort;
  edtLine.OnAbort := Abort;
  edtPassCount.OnAbort := Abort;

  cw := Fw * (Length(caBtn.Caption) +2);
  caBtn.SetBounds(Width - (cw + BSize), Height - (FH + 4 + BSize), cw, FH + 4);
  caBtn.CentreCaption;
  caBtn.Enabled := True;

  cw := Fw * (Length(OkBtn.Caption) + 2);
  okBtn.SetBounds(caBtn.Left - (cw + 6), caBtn.Top, cw, FH + 4);
  okBtn.CentreCaption;
  okBtn.Enabled := False;

  SP_ResizeWindow(FDWindowID, Width, Height, 8, False, Error);
  SP_Decorate_Window(FDWindowID, Caption, True, False, True);
  SP_FillRect(1, FH +2, Width -2, Height - (FH + 3), SP_UIWindowBack);
  SP_MoveWindow(FDWindowID, (DISPLAYWIDTH - Width) Div 2, (DISPLAYHEIGHT - Height) Div 2, Error);

  SP_SetDrawingWindow(DefaultWindow);

End;

Procedure SP_BreakPointWindow.TypeChange(Sender: SP_BaseComponent; Text: aString);
Begin

  PlaceControls;
  ValidateFields;

End;

Procedure SP_BreakPointWindow.ValidateFields;
Var
  i, ln, st: Integer;
  Found: TPoint;
  Error: TSP_ErrorCode;
  Line, Statement: aFloat;
  LineTxt, StatementTxt, Text, s, l: aString;
  searchOpt: SP_SearchOptions;
  b, b2, b3: Boolean;
Begin

  Text := edtLine.Text;

  If cmbType.ItemIndex = 0 Then Begin

    // Line, statement

    i := 1;
    Found.y := -1;
    Error.Code := SP_ERR_OK;

    If Pos(':', Text) > 0 Then Begin
      LineTxt := Copy(Text, 1, Pos(':', Text) -1);
      StatementTxt := Copy(Text, Pos(':', Text) +1);
    End Else Begin
      LineTxt := Text;
      StatementTxt := '1';
    End;

    If LineTxt <> '' Then Begin
      l := SP_FPExecuteAnyExpression(LineTxt, Error);
      If (Error.Code = SP_ERR_OK) And (StatementTxt <> '') Then
        s := SP_FPExecuteAnyExpression(StatementTxt, Error)
      Else
        Error.Code := SP_ERR_SYNTAX_ERROR;
    End Else
      Error.Code := SP_ERR_SYNTAX_ERROR;

    ln := StrToIntDef(l, MAXINT);
    st := StrToIntDef(s, MAXINT);

    BpLine := Ln;
    BpSt := St;

    b := (Error.Code = SP_ERR_OK) and SP_GetNumber(l, i, line, True) and (ln <> MAXINT) and (ln > 0);
    i := 1;
    b := b And SP_GetNumber(s, i, statement, True) and (st <> MAXINT) and (st > 0);

    If Not b Then Begin
      searchOpt := [soForward, soCondenseSpaces];
      Found := SP_FindText('LABEL @'+edtLine.Text, 0, 1, searchOpt);
      b := Found.y >= 0;
    End;

    If not b Then
      lblLine.FontClr := 2
    Else
      lblLine.FontClr := 0;

  End Else

    b := True;

  // Condition

  b2 := True;
  If edtCondition.Text <> '' Then Begin
    Error.Code := SP_ERR_OK;
    b2 := SP_FPCheckExpression(edtCondition.Text, Error) and (Error.ReturnType = SP_VALUE);
    BpCondition := edtCondition.Text;
    If not b2 Then
      lblCondition.FontClr := 2
    else
      lblCondition.FontClr := 0;
  End Else
    lblCondition.FontClr := 0;

  // Pass count

  If edtPassCount.Text <> '' Then Begin
    Error.Code := SP_ERR_OK;
    BpPasses := Round(SP_FPExecuteNumericExpression(edtPassCount.Text, Error));
    b3 := (Error.Code = SP_ERR_OK) and (Error.ReturnType = SP_VALUE);
  End Else
    b3 := False;

  If not b3 Then
    lblPassCount.FontClr := 2
  else
    lblPassCount.FontClr := 0;

  okBtn.Enabled := b and b2 and b3;
  edtLine.ValidText := b;
  edtCondition.ValidText := b2;
  edtPassCount.ValidText := b3;

End;

Procedure SP_BreakPointWindow.edtLineChange(Sender: SP_BaseComponent; Text: aString);
Begin

  ValidateFields;

End;

Procedure SP_BreakPointWindow.okBtnClick(Sender: SP_BaseComponent);
Begin

  Accepted := True;
  ToolWindowDone := True;

End;

Procedure SP_BreakPointWindow.caBtnClick(Sender: SP_BaseComponent);
Begin

  ToolWindowDone := True;

End;

Procedure SP_BreakpointWindow.Accept(Sender: SP_BaseComponent; s: aString);
Begin

  If OkBtn.Enabled Then
    OkBtnClick(Sender);

  End;

Procedure SP_BreakpointWindow.Abort(Sender: SP_BaseComponent);
Begin

  ToolWindowDone := True;

End;


Initialization

  SearchHistory := TStringlist.Create;
  ReplaceHistory := TStringlist.Create;

Finalization

  SearchHistory.Free;
  ReplaceHistory.Free;

end.
