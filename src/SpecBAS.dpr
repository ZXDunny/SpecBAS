// Copyright (C) 2010 By Paul Dunn
//
// This file is part of the SpecBAS BASIC Interpreter, which is in turn
// part of the SpecOS project.
//
// SpecBAS is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// SpecBAS is distributed in the hope that it will be entertaining,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with SpecBAS.  If not, see <http://www.gnu.org/licenses/>.
program SpecBAS;
uses
  Forms,
  MainForm in 'MainForm.pas' {Main},
  SP_Graphics in 'SP_Graphics.pas',
  SP_SysVars in 'SP_SysVars.pas',
  SP_BankManager in 'SP_BankManager.pas',
  SP_Util in 'SP_Util.pas',
  SP_FileIO in 'SP_FileIO.pas',
  SP_Errors in 'SP_Errors.pas',
  SP_Main in 'SP_Main.pas',
  SP_Input in 'SP_Input.pas',
  SP_Tokenise in 'SP_Tokenise.pas',
  SP_Variables in 'SP_Variables.pas',
  SP_InfixToPostFix in 'SP_InfixToPostFix.pas',
  SP_Interpret_PostFix in 'SP_Interpret_PostFix.pas',
  SP_Streams in 'SP_Streams.pas',
  SP_Sound in 'SP_Sound.pas',
  SP_Editor in 'SP_Editor.pas',
  SP_Package in 'SP_Package.pas',
  SP_Math in 'SP_Math.pas',
  SP_Help in 'SP_Help.pas',
  SP_Graphics32 in 'SP_Graphics32.pas',
  SP_Strings in 'SP_Strings.pas',
  SP_Menu in 'SP_Menu.pas',
  SP_FPEditor in 'SP_FPEditor.pas',
  SP_Samples in 'SP_Samples.pas',
  SP_BankFiling in 'SP_BankFiling.pas',
  SP_Components in 'SP_Components.pas',
  SP_UITools in 'SP_UITools.pas',
  SP_AnsiStringlist in 'SP_AnsiStringlist.pas',
  SP_ButtonUnit in 'SP_ButtonUnit.pas',
  SP_BaseComponentUnit in 'SP_BaseComponentUnit.pas',
  SP_ScrollBarUnit in 'SP_ScrollBarUnit.pas',
  SP_PopUpMenuUnit in 'SP_PopUpMenuUnit.pas',
  SP_ListBoxUnit in 'SP_ListBoxUnit.pas',
  SP_FileListBoxUnit in 'SP_FileListBoxUnit.pas',
  SP_EditUnit in 'SP_EditUnit.pas',
  SP_CheckBoxUnit in 'SP_CheckBoxUnit.pas',
  SP_WindowMenuUnit in 'SP_WindowMenuUnit.pas',
  SP_LabelUnit in 'SP_LabelUnit.pas',
  SP_ComboBoxUnit in 'SP_ComboBoxUnit.pas',
  SP_RadioGroupUnit in 'SP_RadioGroupUnit.pas',
  SP_CheckListUnit in 'SP_CheckListUnit.pas',
  SP_ContainerUnit in 'SP_ContainerUnit.pas',
  SP_TabBarUnit in 'SP_TabBarUnit.pas',
  SP_MenuActions in 'SP_MenuActions.pas',
  SP_ControlMsgs in 'SP_ControlMsgs.pas',
  SP_DebugPanel in 'SP_DebugPanel.pas',
  SP_SliderUnit in 'SP_SliderUnit.pas',
  SP_ProgressBarUnit in 'SP_ProgressBarUnit.pas';

{$R *.res}
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'SpecBAS';
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
