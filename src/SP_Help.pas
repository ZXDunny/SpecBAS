unit SP_Help;

{$INCLUDE SpecBAS.inc}

interface

Uses SP_SysVars, SP_Util, SP_Editor, SP_Graphics, SP_Errors, SP_BankManager;

Procedure ShowGuideWindow(BankID: Integer; Node: aString; X, Y, W, H: Integer);

implementation

Procedure ShowGuideWindow(BankID: Integer; Node: aString; X, Y, W, H: Integer);
{Var
  HelpWindowID: Integer;
  Error: TSP_ErrorCode;}
Begin

  // Opens a window showing an AmigaGuide-style document.
  // Coordinates are screen based, not per-window.

  // HELPWINDOW := SP_Add_Window(DISPLAYWIDTH Div 2, 4, (DISPLAYWIDTH Div 2) - 8, DISPLAYHEIGHT - 16, -1, 8, 0, Error);

End;


end.
