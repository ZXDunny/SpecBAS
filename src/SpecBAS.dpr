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

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$WEAKLINKRTTI ON}

uses
  {$IFDEF DEBUG}
  //FastMM4,
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  {$ENDIF }
  {$IFNDEF FPC}
  Windows,
  {$ELSE}
  Interfaces,
  {$ENDIF }
  Forms,
  SP_Display,
  MainForm in 'MainForm.pas' {Main};

{$R *.res}
begin
  {$IFNDEF FPC}
  SetProcessDPIAware;
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'SpecBAS';
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
