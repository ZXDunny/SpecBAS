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

unit SP_SysVars;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$INCLUDE SpecBAS.inc}

interface

Uses Classes, SP_Util, SP_Errors;

Type

  TConstant = Packed Record Name: aString; Value: aFloat; End;
  TSysVar = Record
    Name: aString;
    svType: Integer;
    Size: Integer;
    Data: Pointer;
  End;

Var

  // System-wide sysvars

  EXENAME:                  String;       // Yes a string, not ansistring. Don't worry about it.
  PAYLOADPRESENT:           Boolean;
  PCOUNT:                   Integer;      // Number of parameters on command line
  {$IFDEF FPC}
  PARAMS:                   TStringList;
  {$ELSE}
  PARAMS:                   TStringlist;  // Commandline parameters
  {$ENDIF}
  BUILDSTR:                 aString;      // Build number of SpecBAS
  HARDWARE:                 aString;      // The hardware platform SpecBAS is running on (Windows/Linux x86/Pandora/Pi etc).
  INSTARTUP:                Boolean;      // Flag that the system is starting up - no recentfiles to be added
  SCREENCHANGE:             Boolean;      // Screen resolution changing?
  SPFULLSCREEN:             Boolean;      // True if we're in Fullscreen mode.
  SCRUPDATENOW:             Boolean;
  LASTFRAMETIME:            aFloat;       // How long the previous frame took to render
  VSYNCENABLED:             Boolean;      // Is System VSync enabled or available?
  DRAWING:                  Boolean;
  SIZINGMAIN:               Boolean;      // True while waiting for the UI thread to resize the main window
  SCMINX, SCMINY,
  SCMAXX, SCMAXY:           Integer;      // "Dirty rectangle" display coordinates for the SP_Composite routine
  SORGX, SORGY, SORGW,
  SORGH, WINSCALEX,
  WINSCALEY:                aFloat;       // The current window's origin and extent metrics
  BORDERSIZE:               Integer;      // The size of the screen border.
  WINSCALE, WINORIGIN,
  WINFLIPPED:               Boolean;      // Are the origin or scaling of a window active?
  NUMSPRITES:               Integer;      // Global number of sprites defined.
  PROGNAME:                 aString;      // Name of current program
  FILENAMED:                Boolean;      // The current program has a filename (ie, it's been saved).
  TIMERES:                  Integer;      // The timer resolution
  MOUSESPRITE:              Integer;      // The sprite used by the mouse
  MOUSEVISIBLE:             Boolean;      // Is the mouse pointer visible?
  MOUSEMOVED:               Boolean;      // Set if the mouse has moved this frame.
  MOUSEIMAGE:               aString;      // The image that the mouse pointer covers
  MOUSESTOREW,
  MOUSESTOREH,
  MOUSESTOREX,
  MOUSESTOREY:              Integer;      // The last known mouse coordinates for restoring the display under the pointer.
  MOUSEISGRAPHIC:           Boolean;      // Is the mouse image a graphic bank?
  MOUSESTR:                 aString;      // If not, then this string holds the mouse pointer image.
  MOUSEHSX, MOUSEHSY:       Integer;      // Mouse hotspot offset coordinates
  NUBMODE1:                 Integer;      // PANDORA ONLY - nub setting - 0/mouse 1/absolute 2/scroll 3/mousebuttons
  NUBMODE2:                 Integer;      // Second (right hand) nub.
  BATTLEVEL:                Integer;      // Pandora battery level
  DRAWINGSPRITES:           Boolean;      // Are we drawing sprites?
  BLOCKSPRITES:             Boolean;      // Temporarily stop sprite updates
  CIRCLEASPECT:             Boolean;      // Are circles aspect correct regardless of display aspect?

  DISPLAYPOINTER:           Pointer;      // A pointer to the display - the one external to SpecOS.
  DISPLAYWIDTH:             Integer;      // The current display surface width
  DISPLAYHEIGHT:            Integer;      // The current display surface height
  DISPLAYSTRIDE:            Integer;      // The *real* width of the display surface
  SCALEWIDTH:               LongWord;
  SCALEHEIGHT:              LongWord;
  NUMWINDOWS:               Integer;
  SHOWFPS:                  Boolean;

  CBLACK,
  CBLUE,
  CRED,
  CMAGENTA,
  CGREEN,
  CCYAN,
  CYELLOW,
  CWHITE,
  CGREY,
  CBRIGHTBLUE,
  CBRIGHTRED,
  CBRIGHTMAGENTA,
  CBRIGHTGREEN,
  CBRIGHTCYAN,
  CBRIGHTYELLOW,
  CBRIGHTWHITE:             LongWord;     // The default palette.

  MENU_SHOWFLAG,
  MENU_HIDEFLAG,
  MENU_HIGHLIGHTFLAG:       Boolean;      // Menu interaction flags for ON MENU.

  LASTMENU,
  LASTMENUITEM:             Integer;      // For the user to query in ON MENU events

  MENUBARPAPER,
  MENUBARINK,
  MENUBAROUTLINE,
  MENUPAPER,
  MENUINK,
  MENUDISABLEDINK,
  MENUOUTLINE,
  MENUHLOUTLINE,
  MENUHIGHLIGHT,
  MENUCAPHIGHLIGHT,
  MENUSEP:                  LongWord;     // The default menu colours.
  MENUSHOWING:              Boolean;      // Is the main menu visible?
  MENUBLOCK:                Boolean;

  FDIST:                    aFloat;       // The focal distance used in 3D calculations.

  NUMBANKS:                 Integer;      // The number of memory banks in use.
  SYSFONT:                  Integer;      // The index of the system font - cannot be deleted.
  ITALICSCALE:              Integer;      // The slope of italics in the TEXT and PRINT commands
  EDITORFONT:               Integer;      // The index of the editor font.
  ANIMSPEED:                Integer;      // Speed in ms that it takes to hide or show a window in the editor
  EDFONTWIDTH:              Integer;      // The size of the editor font. Usually the default system font.
  EDFONTHEIGHT:             Integer;
  EDFONTSCALEX,
  EDFONTSCALEY:             aFloat;       // The editor font's size (as scalars for width and height)
  EDINVERSE:                Byte;
  EDITORMENU:               Integer;      // A backup of the current menu
  EDMENU:                   Integer;      // The menu ID number of the editor's menu
  CURMENU:                  Integer;      // The menu ID number of the currently used menu; -1 for no menu.
  NUMSTREAMS:               Integer;      // The number of streams allocated
  NUMCONSTS:                Integer;      // The number of constants currently allocated

  PROGBANK:                 Integer;      // The Bank ID of the program bank.
  COMMANDBANK:              Integer;      // The Bank ID of the bank which holds direct commands.
  CURPROGBANK:              Integer;      // The currently executing bank - usually the same as one of the above.

  EDITORREADY:              Boolean;      // Has the editor been set up yet?
  FILECHANGED:              Boolean;
  SYSTEMSTATE:              Integer;      // What the system is doing now - SS_INPUT, SS_PAUSE or SS_INTERPRET
  PROGCHANGED:              Boolean;      // Set if the program in memory has changed.
  MAXLOWER:                 Integer;      // Maximum number of rows in the editing area. Minimum of 2.
  EDITLINE:                 aString;      // The current edit line
  CURSORPOS:                Integer;      // The position within the edit line of the cursor during editing.
  CURSORX:                  Integer;      // The X Position of the cursor.
  CURSORY:                  Integer;      // The Y Position of the cursor - used to quickly redraw the cursor on FLASH state-change.
  CURSORCHAR:               Byte;         // The character that is currently being covered by the cursor.
  CURSORFG:                 Longword;     // The foreground colour of the cursor
  CURSORBG:                 Longword;     // The background colour of the cursor. Flipped while flashing.
  CURSORBOLD:               LongWord;     // Is the cursor on a BOLD char?
  CURSORITALIC:             LongWord;     // Is the cursor on an ITALIC char?
  INPUTLINE:                aString;      // The current line of input
  INPUTCSR1:                LongWord;     // Two colours used by the INPUT cursor
  INPUTCSR2:                LongWord;
  INPUTERROR_RPT:           Boolean;      // If an error occurs in INPUT, repeat the INPUT
  INPUTPOSX,
  INPUTPOSY:                aFloat;       // Print position prior to calling an INPUT.
  INPUTERROR:               Boolean;      // Was there an error in INPUT? Set if yes.
  INPUTERRORHANDLED:        Boolean;      // Are errors in INPUT handled by the system?
  INPUTERRVAL:              aFloat;       // Value to return in case of error in INPUT in a number
  INFORMAT:                 aString;      // The INPUT command's current MASK.
  INPUTBACK:                aString;      // Backup (in a string!) of the window used by INPUT
  ERRORSTATE:               Boolean;      // Indicates an error state in the edit line
  LINK:                     Integer;      // The colour of the INK used in the lower screen for editing. Not user-changeable.
  SCREENLOCK:               Boolean;      // True if the screen is locked and cannot be redrawn.
  LASTERROR:                Integer;      // The last error code produced - 0 if the line executed successfully else see sp_errors.pas
  LASTERRORLINE:            Integer;      // The line that the last error occurred on
  LASTERRORSTATEMENT:       Integer;      // The statement within the line that the last error occurred on
  CONTLINE:                 Integer;      // Line that CONTINUE jumps to
  CONTSTATEMENT:            Integer;      // Statement that CONTINUE jumps to
  COMMAND_TOKENS:           aString;      // The current command line.
  PROGSTATE:                Integer;      // Program state - running, or editing.
  IGNORE_ON_ERROR:          Boolean;      // If an ON ERROR command is run, then allow errors in the handler.
  INCLUDEFROM:              Integer;      // The line number that INCLUDEs are appended from, if present (-1 if not)
  INPROC:                   Integer;      // Are we executing code inside a PROC?

  OSD:                      aString;      // User definable on-screen display
  MAXOSDLEN:                Integer;
  FPSLEFT:                  Integer;
  FPSTOP:                   Integer;
  FPSWIDTH:                 Integer;
  FPSHEIGHT:                Integer;
  FPSSTRING:                aString;      // The current FPS (used for displaying in fullscreen mode)
  FPSPROCESSEDSTRING:       aString;
  FPSIMAGE:                 aString;      // Like the mouse, this stores the background under the FPS display
  FPSSCALE:                 Integer;
  FLASHINTERVAL:            Integer;      // The number of frames that must elapse between cursor flash state changes
  FRAMES:                   Integer;      // Elapsed frame counter, 50Hz
  LASTFRAME:                LongWord;
  FLASHSTATE:               Integer;      // 1 or 0 for the cursor flash
  FLASHFRAME:               Boolean;      // Is this frame a flash transition?
  EDITERROR:                Boolean;      // True if the syntax check caught an editing error
  EDITERRORPOS:             Integer;      // Position in the EDITLINE aString of the error
  PROGLINE:                 Integer;      // The currently selected line in the listing
  SHOWLINE:                 Integer;      // The top line of an AUTOLIST
  LASTINKEYFRAME:           Integer;      // The last frame number that INKEY$ yielded CPU
  STEPMODE:                 Integer;      // Is single-step (or Step over) mode active?
  STEPADDR:                 NativeUInt;   // Pointer to the end of the current statement for single-stepping

  DBGSTR:                   aString;      // Debugging purposes
  FPS:                      aFloat;       // Frames per second - default 50.
  FRAME_MS:                 aFloat;       // Frame size in Ms.
  FC:                       Integer;      // Frame Counter
  FCM:                      Integer;
  SKIPDRAW:                 Boolean;      // Did we skip the last wait for vbl?
  DEBUGGING:                Boolean;

  GFXLOCK:                  Integer;      // State of the GRAPHICS mode
  CAPSLOCK:                 Integer;      // State of the CAPSLOCK key
  NUMLOCK:                  Integer;      // State of the NUMLOCK key
  INSERT:                   Boolean;      // State of the Insert/Overwrite flag
  BREAKSIGNAL:              Boolean;      // BREAK pressed?
  BPSIGNAL:                 Boolean;      // Breakpoint triggered, or impending Single-step event
  KEYSTATE:   array[0..255] of Byte;      // The state of the keyboard
  LASTKEYFLAG:              Byte;         // For the last key pressed, these are its flags (currently KF_NOCLICK possible)
  REPDEL:                   Integer;      // The delay in frames before a key repeats when held down
  REPPER:                   Integer;      // Delay between successive repeats of a key that is held down
  REPCOUNT:                 Integer;      // The current counter for key repeats
  DEBUGVAL:                 LongWord;
  VOLUME:                   aFloat;       // The current volume of sounds in SpecBAS
  CLICKVOL:                 aFloat;       // Editor clicks volume
  SIGSAMPLEBANK,
  CLICKBANK,
  OKSNDBANK,
  ERRSNDBANK:               Integer;      // Sample banks for the system sounds
  CLICKCHAN,
  OKCHAN,
  ERRORCHAN:                LongWord;     // Channel numbers for the system sounds

  COLLIDE_FLAG:             Boolean;      // For the ON COLLIDE command
  M_MOVEFLAG:               Boolean;      // For the ON MOUSEMOVE command
  M_DOWNFLAG:               Boolean;      // For the ON MOUSEDOWN command
  M_UPFLAG:                 Boolean;      // For the ON MOUSEUP command
  M_WHEELUPFLAG:            Boolean;      // For the ON WHEELUP command
  M_WHEELDNFLAG:            Boolean;      // For the ON WHEELDOWN command
  K_DOWNFLAG:               Boolean;      // For the ON MOUSEDOWN command
  K_UPFLAG:                 Boolean;      // For the ON MOUSEUP command

  MOUSEX:                   Integer;      // The current mouse x-coordinate
  MOUSEY:                   Integer;      // The current mouse y-coordinate
  MOUSEW:                   Integer;
  MOUSEH:                   Integer;
  MOUSEWHEEL:               Integer;      // The current mouse wheel position.
  MOUSEBTN:                 LongWord;     // The current state of the mouse buttons - bits 0,1,2 for left/right/middle
  M_DELTAX:                 Integer;      // Amount the mouse has moved in the X direction
  M_DELTAY:                 Integer;      // Amount the mouse has moved in the Y direction

  AUTOSAVE:                 Boolean;      // Automatically save your work after each direct command/Line Entry?
  AUTOSAVETIME:             Integer;      // Time between autosave in milliseconds
  HOMEFOLDER:               aString;      // The folder that specbas lives in
  INITFOLDER:               aString;      // The folder that the executable has run from, used in OSX.

  QUITMSG:                  Boolean;      // Signals that the interpreter is to quit when true.

  MP3AVAILABLE:             Boolean;      // Libraries for MP3 decoding are available
  MODAVAILABLE:             Boolean;      // Libraries for MOD/S3M/IT/XM decoding are available
  FLACAVAILABLE:            Boolean;      // Libraries for decoding FLAC files are available
  OGGAVAILABLE:             Boolean;      // Libraries for decoding OGG files are available
  MAXRATE:                  LongWord;     // Maximum sample rate supported
  MINRATE:                  LongWord;     // Minimum sample rate supported
  MUSICHANDLE:              LongWord;     // The handle to the currently loaded music file. 0 if no music loaded.
  MUSICISSTREAM:            Boolean;      // Is the music currently loaded a stream?

  LOGGING:                  Boolean;      // enable debug logging?

  FWEDITOR:                 Integer;
  FWDIRECT:                 Integer;
  LISTWINDOW:               Integer;      // The Window Index of the Listing window
  COMMANDWINDOW:            Integer;      // The Window ID of the direct command window
  SPLITSTATEMENTS:          Boolean;      // Split statements in the editor?
  SPLITREMS:                Boolean;      // Word-wrap REM statements?
  EDITORWRAP:               Boolean;      // Wrap long statements 128k editor style?
  LISTTOPINDEX:             aFloat;       // The topindex of the list window - not the line, but the text index
  LISTLEFTINDEX:            aFloat;       // The Leftmost column in the list window
  LISTSELLINE:              Integer;      // The currently selected linenumber in the LIST window
  LISTLINECOUNT:            Integer;      // Number of lines in the listing, counting statements.
  LISTCOLCOUNT:             Integer;      // The maximum number of characters the listing's longest line holds
  LISTVISLINES:             Integer;      // The number of lines visible in the listing window.
  LISTVISCOLS:              Integer;      // Number of characters visible per line
  LISTWINX:                 Integer;      // The List window metrics
  LISTWINY:                 Integer;
  LISTWINW:                 Integer;
  LISTWINH:                 Integer;
  SCROLLBTNS:               Boolean;      // Scrollbars have buttons?
  CCOMMANDWINDOW:           Boolean;      // True when the command window exists
  CLISTWINDOW:              Boolean;      // True when the LIST window exists.
  COMMANDWINX:              Integer;      // The Command window metrics
  COMMANDWINY:              Integer;
  COMMANDWINW:              Integer;
  COMMANDWINH:              Integer;
  COMMANDSIZETLX:           Integer;
  COMMANDSIZETLY:           Integer;
  COMMANDSIZEBRX:           Integer;
  COMMANDSIZEBRY:           Integer;
  SHOWLIST:                 Boolean;
  EDITORHIDDEN:             Integer;
  HELPBANK:                 Integer;      // The Bank-ID of the help file.
  HELPWINDOW:               Integer;      // The Window-ID of the help window in the editor.

  BackClr:                  aString;
  noClr:                    aString;
  kwdClr:                   aString;
  fnClr:                    aString;
  numClr:                   aString;
  hexClr:                   aString;
  binClr:                   aString;
  baseClr:                  aString;
  strClr:                   aString;
  nvClr:                    aString;
  svClr:                    aString;
  remClr:                   aString;
  constClr:                 aString;
  symClr:                   aString;
  LinClr:                   aString;
  relClr:                   aString;
  mathClr:                  aString;
  labClr:                   aString;
  SelClr:                   aString;
  SelUFClr:                 aString;
  SearchClr:                aString;
  NoSearchClr:              aString;
  BraceClr:                 aString;
  BraceHltClr:              aString;

  lineClr:                  Integer;
  lineErrClr:               Integer;
  gutterClr:                Integer;
  paperClr:                 Integer;
  proglineClr:              Integer;
  proglineGtr:              Integer;

  winBack:                  Integer;
  capBack:                  Integer;
  winBorder:                Integer;
  capText:                  Integer;
  capInactive:              Integer;
  gripClr:                  Integer;

  scrollback:               Integer;
  scrolltrack:              Integer;
  scrollActive:             Integer;
  scrollInactive:           Integer;
  scrollThumb:              Integer;
  BSize:                    Integer;

  debugPanel:               Integer;
  debugCombo:               Integer;
  debugNew:                 Integer;
  debugChg:                 Integer;

  TEMPDIR:                  aString;      // the location of the TEMP directory in the host filesystem.
  ERRStr:                   aString;      // Extra info for errors - like variable name for example

  ENUMBASE:                 aFloat;

  // Thread-specific sysvars

  MULTITHREAD:              Boolean;      // Is the interpreter multi-threaded? False for single-core devices.
  SCREENPOINTER:            Pointer;      // A pointer to the current drawing surface
  SCREENBANK:               Integer;      // The bank ID number of the current window being drawn to
  SCREENWIDTH:              Integer;      // The current drawing surface width
  SCREENHEIGHT:             Integer;      // The current drawing surface height
  SCREENX:                  Integer;      // The current drawing surface X position
  SCREENY:                  Integer;      // The current drawing surface Y position
  SCREENBPP:                Integer;      // The current drawing surface's bitdepth
  SCREENSTRIDE:             Integer;      // The *real* width of the drawing surface - some bitmap formats are 32bit aligned.
  SCREENVISIBLE:            Boolean;      // Is the current surface (potentially) visible?
  WINDOWPOINTER:            Pointer;      // Pointer to the SP_Window_Info structure
  SCRBANKPOINTER:           Pointer;      // As above, but for the display bank.
  FONTBANKID:               Integer;      // The ID number of the bank to use as the current font.
  FONTWIDTH:                Integer;      // The Width of the current font
  FONTHEIGHT:               Integer;      // The Height of the current font
  FONTTRANSPARENT:          Integer;      // The colour index to be used as a transparent colour in the current font
  FONTTYPE:                 Integer;      // The type of font being used (graphical or mono)

  LOWERSAVE:                aString;      // Storage so that the Scroll? prompt doesn't destroy the screen.
  CPAPER:                   LongWord;     // Current PAPER set by the PAPER command
  CINK:                     LongWord;     // Current INK set by the INK command
  CINVERSE:                 Integer;      // Current state of the INVERSE ... state?
  COVER:                    Integer;      // Current state of the OVER flag
  CTRANSPARENT:             Boolean;      // Current state of the TRANSPARENT flag for mono text
  CSTROKE:                  aFloat;       // Current line width for DRAW, PLOT et al
  CCLIPX1:                  Integer;      // Current clip rect
  CCLIPY1:                  Integer;
  CCLIPX2:                  Integer;
  CCLIPY2:                  Integer;
  CSCALEX:                  aFloat;
  CSCALEY:                  aFloat;
  COUTEXPR:                 aString;
  CITALIC:                  Integer;
  CBOLD:                    Integer;
  SKIPFIRSTPOINT:           Boolean;      // Flag that the current DRAW position has been PLOTted
  T_PAPER:                  LongWord;     // Temporary PAPER used by PRINT and INPUT colour items
  T_INK:                    LongWord;     // Temporary INK
  T_INVERSE:                Integer;      // Temporary INVERSE
  T_OVER:                   Integer;      // Temporary OVER
  T_CLIPX1:                 Integer;      // Temporary cliprect
  T_CLIPY1:                 Integer;
  T_CLIPX2:                 Integer;
  T_CLIPY2:                 Integer;
  T_OUTEXPR:                aString;
  T_OUTASSIGN:              aString;
  T_OUTMODE:                Integer;
  T_OUTSTRM:                Integer;
  T_SCALEX:                 aFloat;
  T_SCALEY:                 aFloat;
  T_ITALIC:                 Integer;
  T_BOLD:                   Integer;
  T_USINGMASK:              aString;
  T_TRANSPARENT:            Boolean;
  T_CENTRE:                 Boolean;
  T_CENTRETEXT:             aString;
  T_CENTRE_Y:               Integer;
  T_STROKE:                 aFloat;
  OUTBUFFER:                aString;
  OUTSET:                   Boolean;
  OUTWORKSP:                aString;
  COUTSTRM:                 Integer;
  COUTMODE:                 Integer;      // OUT redirects to screen (0), variable (1) or stream (2)

  DRPOSX:                   aFloat;       // The x-coordinate of the last point plotted
  DRPOSY:                   aFloat;       // The y-coordinate of the last point plotted
  DRHEADING:                aFloat;       // The heading of the "turtle", in whichever angular system is in use (deg, rad)
  XORG:                     Integer;      // The x-coordinate (in screen space) of the graphics origin
  YORG:                     Integer;      // As above, but for y.
  PRPOSX:                   aFloat;       // The X-Coordinate of the PRINT position
  PRPOSY:                   aFloat;       // The Y Coordinate of the PRINT position
  TABSIZE:                  Integer;      // The size in characters of tab stops, starting at the far left of the screen.
  EDTABSIZE:                Integer;      // Editor tab size.
  SCROLLCNT:                Integer;      // The scroll counter - when this reaches the bottom of the screen, the "Scroll?" message is triggered.
  NXTLINE:                  Integer;      // The next line to be executed. If 0, then stop.
  NXTSTATEMENT:             Integer;      // The statement to be executed. Used by the RETURN and NEXT commands.
  NXTST:                    Integer;      // Used by CALL, the next statement number, as opposed to the above index
  MATHMODE:                 Integer;      // 0 - Radians, 1 - Degrees, 2 - Turns, 3 - Gradians
  BASE:                     LongWord;     // The base of arrays. Default to 1.
  UPDATENOW:                Boolean;      // Set to TRUE for an immediate screen update.
  INTSCALING:               Boolean;      // Use integer pre-scaling for high res displays?

  INITMS:                   LongWord;     // The time that SpecBAS was started, in MS.

  WCAPTION:                 aString;      // Window caption for compiled executables
  WINLEFT,
  WINTOP,
  WINWIDTH,
  WINHEIGHT:                Integer;
  MODALWINDOW:              Integer;
  USERMOUSEVISIBLE:         Boolean = True;
  REALSCREENWIDTH,
  REALSCREENHEIGHT:         Integer;
  FocusedWindow:            Integer;
  ScaledWidth,
  ScaledHeight:             Integer;

  CORECOUNT:                Integer;


  NEWPROGNAME:              aString;      // The default project name

Const

  MAXDEPTH = 1024 * 1024;

  SS_INPUT =            0;
  SS_PAUSE =            1;
  SS_INTERPRET =        2;
  SS_ERROR =            3;
  SS_IDLE =             4;
  SS_EDITOR =           5;
  SS_NEW =              6;
  SS_DIRECT =           7;
  SS_EVALUATE =         8;

  BlockGraphics: Array[0..127] of Byte =
    (0, 0, 0, 0, 0, 0, 0, 0,
     15, 15, 15, 15, 0, 0, 0, 0,
     240, 240, 240, 240, 0, 0, 0, 0,
     255, 255, 255, 255, 0, 0, 0, 0,
     0, 0, 0, 0, 15, 15, 15, 15,
     15, 15, 15, 15, 15, 15, 15, 15,
     240, 240, 240, 240, 15, 15, 15, 15,
     255, 255, 255, 255, 15, 15, 15, 15,
     0, 0, 0, 0, 240, 240, 240, 240,
     15, 15, 15, 15, 240, 240, 240, 240,
     240, 240, 240, 240, 240, 240, 240, 240,
     255, 255, 255, 255, 240, 240, 240, 240,
     0, 0, 0, 0, 255, 255, 255, 255,
     15, 15, 15, 15, 255, 255, 255, 255,
     240, 240, 240, 240, 255, 255, 255, 255,
     255, 255, 255, 255, 255, 255, 255, 255);

  Dithers: Array[0..31] of Byte =
    (0, 68, 0, 146, 0, 36, 0, 146,
     0, 170, 0, 170, 0, 170, 0, 170,
     170, 85, 170, 85, 170, 85, 170, 85,
     255, 85, 255, 85, 255, 85, 255, 85);

  MenuUnderline: Array[0..7] of Byte =
    (0, 0, 0, 0, 0, 0, 0, 170);

  TickMark: Array[0..7] of Byte =
    (0, 3, 6, 12, 216, 112, 32, 0);

  MenuSub: Array[0..7] of Byte =
    (0, 0, 8, 12, 14, 12, 8, 0);

  Slope: Array[0..7] of Byte =
    (1, 3, 7, 15, 31, 63, 127, 255);

  Arrows: Array[0..31] of Byte =
    (0, 0, 24, 60, 126, 126, 0, 0,
     0, 0, 126, 126, 60, 24, 0, 0,
     0, 48, 56, 60, 60, 56, 48, 0,
     0, 12, 28, 60, 60, 28, 12, 0);

  SizeGrip: Array[0..7] of Byte =
    (0, 0, 2, 0, 10, 0, 42, 0);

  TitleBar: Array[0..7] of Byte =
    (0, 255, 255, 0, 0, 255, 255, 0);

  Lock: Array[0..7] of Byte =
    (0, 96, 144, 159, 149, 97, 0, 0);

  Outline: Array[0..7] of Byte =
    (60, 126, 255, 255, 255, 255, 126, 60);

  ErrorBlock: Array[0..7] of Byte =
    (0, 60, 126, 126, 126, 126, 60, 0);

  OkBlock: Array[0..7] of Byte =
    (0, 0, 24, 60, 60, 24, 0, 0);

  RadioOff: Array[0..7] of Byte =
    (60, 66, 153, 189, 189, 153, 66, 60);

  RadioOn: Array[0..7] of Byte =
    (60, 66, 129, 129, 129, 129, 66, 60);

  EditGlyph: Array[0..7] of Byte =
    (4, 10, 23, 46, 92, 184, 240, 224);

  SmallChars: Array[0..(32*8)-1] of Byte =
    (0, 34, 85, 85, 85, 85, 34, 0,
     0, 34, 86, 82, 82, 82, 39, 0,
     0, 34, 85, 81, 82, 84, 39, 0,
     0, 38, 81, 82, 81, 81, 38, 0,
     0, 33, 83, 85, 87, 81, 33, 0,
     0, 39, 84, 86, 81, 81, 38, 0,
     0, 34, 84, 86, 85, 85, 34, 0,
     0, 39, 81, 81, 82, 84, 36, 0,
     0, 34, 85, 82, 85, 85, 34, 0,
     0, 34, 85, 85, 83, 81, 38, 0,
     0, 34, 101, 37, 37, 37, 114, 0,
     0, 34, 102, 34, 34, 34, 119, 0,
     0, 34, 101, 33, 34, 36, 119, 0,
     0, 38, 97, 34, 33, 33, 118, 0,
     0, 33, 99, 37, 39, 33, 113, 0,
     0, 39, 100, 38, 33, 33, 118, 0,
     0, 34, 100, 38, 37, 37, 114, 0,
     0, 39, 97, 33, 34, 36, 116, 0,
     0, 34, 101, 34, 37, 37, 114, 0,
     0, 34, 101, 37, 35, 33, 118, 0,
     0, 34, 85, 21, 37, 69, 114, 0,
     0, 34, 86, 18, 34, 66, 119, 0,
     0, 34, 85, 17, 34, 68, 119, 0,
     0, 38, 81, 18, 33, 65, 118, 0,
     0, 33, 83, 21, 39, 65, 113, 0,
     0, 39, 84, 22, 33, 65, 118, 0,
     0, 34, 84, 22, 37, 69, 114, 0,
     0, 39, 81, 17, 34, 68, 116, 0,
     0, 34, 85, 18, 37, 69, 114, 0,
     0, 34, 85, 21, 35, 65, 118, 0,
     0, 98, 21, 37, 21, 21, 98, 0,
     0, 98, 22, 34, 18, 18, 103, 0);

  DefaultFont: Array[0..(96*64)-1] Of Byte =
    (0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 1, 0, 0,
     0, 0, 1, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 1, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 0, 1, 0, 0, 1, 0, 0,
     0, 0, 1, 0, 0, 1, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 0, 1, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 1, 0,
     0, 0, 1, 0, 1, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 1, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 1, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 0, 0, 0, 1, 0,
     0, 1, 1, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 1, 1, 0,
     0, 1, 0, 0, 0, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 1, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 1, 0, 1, 0, 1, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 1, 1, 0, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 1, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 1, 0, 0, 0,
     0, 0, 0, 1, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 1, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 1, 0,
     0, 1, 0, 0, 1, 0, 1, 0,
     0, 1, 0, 1, 0, 0, 1, 0,
     0, 1, 1, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 1, 0, 0, 0,
     0, 0, 1, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 0, 0, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 1, 0, 0, 0,
     0, 0, 1, 0, 1, 0, 0, 0,
     0, 1, 0, 0, 1, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 1, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 1, 0, 1, 0,
     0, 1, 0, 1, 0, 1, 1, 0,
     0, 1, 0, 1, 1, 1, 1, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 0, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 1, 1, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 1, 1, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 1, 0,
     0, 0, 0, 0, 0, 0, 1, 0,
     0, 0, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 1, 0, 0, 0,
     0, 1, 1, 1, 0, 0, 0, 0,
     0, 1, 0, 0, 1, 0, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 1, 0, 0, 1, 1, 0,
     0, 1, 0, 1, 1, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 1, 0, 0, 0, 1, 0,
     0, 1, 0, 1, 0, 0, 1, 0,
     0, 1, 0, 0, 1, 0, 1, 0,
     0, 1, 0, 0, 0, 1, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 1, 0, 0, 1, 0,
     0, 1, 0, 0, 1, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     1, 1, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 0, 0, 1, 0, 0,
     0, 0, 0, 1, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 1, 1, 0, 1, 0,
     0, 0, 1, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 0, 0, 1, 0, 0,
     0, 0, 0, 1, 1, 0, 0, 0,
     0, 0, 0, 1, 1, 0, 0, 0,
     0, 0, 1, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 1, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 1, 1, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 1, 1, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 0, 0, 0,
     0, 1, 0, 1, 0, 1, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     1, 1, 1, 1, 1, 1, 1, 1,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 1, 1, 0, 0,
     0, 0, 1, 0, 0, 0, 1, 0,
     0, 1, 1, 1, 1, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 1, 0, 0, 0, 1, 0,
     0, 0, 1, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 1, 1, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 0, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 1, 1, 1, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 1, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 1, 1, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 0, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 0, 0, 1, 0, 0,
     0, 0, 0, 1, 1, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 1, 0, 0, 0,
     0, 0, 1, 1, 0, 0, 0, 0,
     0, 0, 1, 1, 0, 0, 0, 0,
     0, 0, 1, 0, 1, 0, 0, 0,
     0, 0, 1, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 0, 1, 0, 0, 0,
     0, 1, 0, 1, 0, 1, 0, 0,
     0, 1, 0, 1, 0, 1, 0, 0,
     0, 1, 0, 1, 0, 1, 0, 0,
     0, 1, 0, 1, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 0, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 0, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 1, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 0, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 1, 1, 1, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 1, 1, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 1, 1, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 0, 0, 0,
     0, 1, 0, 0, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 1, 1, 1, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 1, 1, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 1, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 0, 1, 0, 0, 0,
     0, 0, 1, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 1, 0, 1, 0, 0,
     0, 1, 0, 1, 0, 1, 0, 0,
     0, 1, 0, 1, 0, 1, 0, 0,
     0, 0, 1, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 1, 0, 1, 0, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 1, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 1, 0, 0,
     0, 0, 1, 1, 1, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 1, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 1, 1, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 1, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 1, 1, 1, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 1, 1, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 0, 0, 0,
     0, 1, 1, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 1, 0, 1, 0, 0,
     0, 0, 1, 0, 1, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,

     0, 0, 1, 1, 1, 1, 0, 0,
     0, 1, 0, 0, 0, 0, 1, 0,
     1, 0, 0, 1, 1, 0, 0, 1,
     1, 0, 1, 0, 0, 0, 0, 1,
     1, 0, 1, 0, 0, 0, 0, 1,
     1, 0, 0, 1, 1, 0, 0, 1,
     0, 1, 0, 0, 0, 0, 1, 0,
     0, 0, 1, 1, 1, 1, 0, 0);

   svString = 0;
   svArray = 1;
   svBoolean = 2;
   svLongWord = 3;
   svaFloat = 4;
   svInteger = 5;
   svPointer = 6;
   svByte = 7;

   SP_Constants: Array[0..117] of TConstant =
   ((Name: 'TRUE'; Value: 1),
    (Name: 'FALSE'; Value: 0),

    (Name: 'KEY_BACK'; Value: 8),
    (Name: 'KEY_TAB'; Value: 9),
    (Name: 'KEY_ENTER'; Value: 13),
    (Name: 'KEY_SHIFT'; Value: 16),
    (Name: 'KEY_CTRL'; Value: 17),
    (Name: 'KEY_ALT'; Value: 18),
    (Name: 'KEY_PAUSE'; Value: 19),
    (Name: 'KEY_CAPS'; Value: 20),
    (Name: 'KEY_ESC'; Value: 27),
    (Name: 'KEY_SPACE'; Value: 32),
    (Name: 'KEY_PGUP'; Value: 33),
    (Name: 'KEY_PGDN'; Value: 34),
    (Name: 'KEY_END'; Value: 35),
    (Name: 'KEY_HOME'; Value: 36),
    (Name: 'KEY_LEFT'; Value: 37),
    (Name: 'KEY_UP'; Value: 38),
    (Name: 'KEY_RIGHT'; Value: 39),
    (Name: 'KEY_DOWN'; Value: 40),
    (Name: 'KEY_PRINT'; Value: 42),
    (Name: 'KEY_INSERT'; Value: 45),
    (Name: 'KEY_DELETE'; Value: 46),
    (Name: 'KEY_0'; Value: 48),
    (Name: 'KEY_1'; Value: 49),
    (Name: 'KEY_2'; Value: 50),
    (Name: 'KEY_3'; Value: 51),
    (Name: 'KEY_4'; Value: 52),
    (Name: 'KEY_5'; Value: 53),
    (Name: 'KEY_6'; Value: 54),
    (Name: 'KEY_7'; Value: 55),
    (Name: 'KEY_8'; Value: 56),
    (Name: 'KEY_9'; Value: 57),
    (Name: 'KEY_A'; Value: 65),
    (Name: 'KEY_B'; Value: 66),
    (Name: 'KEY_C'; Value: 67),
    (Name: 'KEY_D'; Value: 68),
    (Name: 'KEY_E'; Value: 69),
    (Name: 'KEY_F'; Value: 70),
    (Name: 'KEY_G'; Value: 71),
    (Name: 'KEY_H'; Value: 72),
    (Name: 'KEY_I'; Value: 73),
    (Name: 'KEY_J'; Value: 74),
    (Name: 'KEY_K'; Value: 75),
    (Name: 'KEY_L'; Value: 76),
    (Name: 'KEY_M'; Value: 77),
    (Name: 'KEY_N'; Value: 78),
    (Name: 'KEY_O'; Value: 79),
    (Name: 'KEY_P'; Value: 80),
    (Name: 'KEY_Q'; Value: 81),
    (Name: 'KEY_R'; Value: 82),
    (Name: 'KEY_S'; Value: 83),
    (Name: 'KEY_T'; Value: 84),
    (Name: 'KEY_U'; Value: 85),
    (Name: 'KEY_V'; Value: 86),
    (Name: 'KEY_W'; Value: 87),
    (Name: 'KEY_X'; Value: 88),
    (Name: 'KEY_Y'; Value: 89),
    (Name: 'KEY_Z'; Value: 90),
    (Name: 'KEY_LWIN'; Value: 91),
    (Name: 'KEY_RWIN'; Value: 92),
    (Name: 'KEY_NUMPAD0'; Value: 96),
    (Name: 'KEY_NUMPAD1'; Value: 97),
    (Name: 'KEY_NUMPAD2'; Value: 98),
    (Name: 'KEY_NUMPAD3'; Value: 99),
    (Name: 'KEY_NUMPAD4'; Value: 100),
    (Name: 'KEY_NUMPAD5'; Value: 101),
    (Name: 'KEY_NUMPAD6'; Value: 102),
    (Name: 'KEY_NUMPAD7'; Value: 103),
    (Name: 'KEY_NUMPAD8'; Value: 104),
    (Name: 'KEY_NUMPAD9'; Value: 105),
    (Name: 'KEY_MULTIPLY'; Value: 106),
    (Name: 'KEY_ADD'; Value: 107),
    (Name: 'KEY_SEPARATOR'; Value: 108),
    (Name: 'KEY_SUBTRACT'; Value: 109),
    (Name: 'KEY_DECIMAL'; Value: 110),
    (Name: 'KEY_DIVIDE'; Value: 111),
    (Name: 'KEY_F1'; Value: 112),
    (Name: 'KEY_F2'; Value: 113),
    (Name: 'KEY_F3'; Value: 114),
    (Name: 'KEY_F4'; Value: 115),
    (Name: 'KEY_F5'; Value: 116),
    (Name: 'KEY_F6'; Value: 117),
    (Name: 'KEY_F7'; Value: 118),
    (Name: 'KEY_F8'; Value: 119),
    (Name: 'KEY_F9'; Value: 120),
    (Name: 'KEY_F10'; Value: 121),
    (Name: 'KEY_F11'; Value: 122),
    (Name: 'KEY_F12'; Value: 123),
    (Name: 'KEY_NUM_LOCK'; Value: 144),
    (Name: 'KEY_SCROLL_LOCK'; Value: 145),

    (Name: 'FONT_MONO'; Value: 0),
    (Name: 'FONT_COLOUR'; Value: 1),

    (Name: 'dtNONE'; Value: 0),
    (Name: 'dtRANDOM'; Value: 1),
    (Name: 'dtDIAGONAL5'; Value: 2),
    (Name: 'dtDIAGONAL9'; Value: 3),
    (Name: 'dtCLUSTERED'; Value: 4),
    (Name: 'dtDISPERSED'; Value: 5),
    (Name: 'dtHALFTONE'; Value: 6),
    (Name: 'dtORDERED16'; Value: 7),
    (Name: 'dtORDERED64'; Value: 8),
    (Name: 'dtFLOYD'; Value: 9),
    (Name: 'dtJARVIS'; Value: 10),
    (Name: 'dtSTUCKI'; Value: 11),
    (Name: 'dtBURKES'; Value: 12),
    (Name: 'dtSIERRA3'; Value: 13),
    (Name: 'dtSIERRA2'; Value: 14),
    (Name: 'dtSIERRA'; Value: 15),
    (Name: 'dtATKINSON'; Value: 16),
    (Name: 'dtSTEVENSON'; Value: 17),

    (Name: 'tpLOWER'; Value: -1),
    (Name: 'tpNORMAL'; Value: 0),
    (Name: 'tpHIGHER'; Value: 1),

    (Name: 'nubMOUSE'; Value: 0),
    (Name: 'nubSTICK'; Value: 1),
    (Name: 'nubSCROLL'; Value: 2),
    (Name: 'nubBUTTONS'; Value: 3));

  SysVars: Array[0..251] of TSysVar =
  ((Name: 'BUILDSTR'; svType: svString; Size: 0; Data: @BUILDSTR),
   (Name: 'SCROLLBTNS'; svType: svBoolean; Size: 1; Data: @SCROLLBTNS),
   (Name: 'ANIMSPEED'; svType: svLongWord; Size: 4; Data: @ANIMSPEED),
   (Name: 'HARDWARE'; svType: svString; Size: 0; Data: @HARDWARE),
   (Name: 'SPFULLSCREEN'; svType: svBoolean; Size: 1; Data: @SPFULLSCREEN),
   (Name: 'SCMINX'; svType: svInteger; Size: 4; Data: @SCMINX),
   (Name: 'SCMINY'; svType: svInteger; Size: 4; Data: @SCMINY),
   (Name: 'SCMAXX'; svType: svInteger; Size: 4; Data: @SCMAXX),
   (Name: 'SCMAXY'; svType: svInteger; Size: 4; Data: @SCMAXY),
   (Name: 'NUMSPRITES'; svType: svInteger; Size: 4; Data: @NUMSPRITES),
   (Name: 'PROGNAME'; svType: svString; Size: 0; Data: @PROGNAME),
   (Name: 'MOUSEVISIBLE'; svType: svBoolean; Size: 1; Data: @MOUSEVISIBLE),
   (Name: 'MOUSEIMAGE'; svType: svString; Size: 0; Data: @MOUSEIMAGE),
   (Name: 'MOUSESTOREX'; svType: svInteger; Size: 4; Data: @MOUSESTOREX),
   (Name: 'MOUSESTOREY'; svType: svInteger; Size: 4; Data: @MOUSESTOREY),
   (Name: 'MOUSEISGRAPHIC'; svType: svBoolean; Size: 1; Data: @MOUSEISGRAPHIC),
   (Name: 'MOUSESTR'; svType: svString; Size: 0; Data: @MOUSESTR),
   (Name: 'MOUSEHSX'; svType: svInteger; Size: 4; Data: @MOUSEHSX),
   (Name: 'MOUSEHSY'; svType: svInteger; Size: 4; Data: @MOUSEHSY),
   (Name: 'DISPLAYPOINTER'; svType: svPointer; Size: 4; Data: @DISPLAYPOINTER),
   (Name: 'DISPLAYWIDTH'; svType: svInteger; Size: 4; Data: @DISPLAYWIDTH),
   (Name: 'DISPLAYHEIGHT'; svType: svInteger; Size: 4; Data: @DISPLAYHEIGHT),
   (Name: 'NUMBANKS'; svType: svInteger; Size: 4; Data: @NUMBANKS),
   (Name: 'SYSFONT'; svType: svInteger; Size: 4; Data: @SYSFONT),
   (Name: 'ITALICSCALE'; svType: svInteger; Size: 4; Data: @ITALICSCALE),
   (Name: 'EDITORFONT'; svType: svInteger; Size: 4; Data: @EDITORFONT),
   (Name: 'NUMSTREAMS'; svType: svInteger; Size: 4; Data: @NUMSTREAMS),
   (Name: 'SYSTEMSTATE'; svType: svInteger; Size: 4; Data: @SYSTEMSTATE),
   (Name: 'PROGCHANGED'; svType: svBoolean; Size: 1; Data: @PROGCHANGED),
   (Name: 'EDITLINE'; svType: svString; Size: 0; Data: @EDITLINE),
   (Name: 'CURSORPOS'; svType: svInteger; Size: 4; Data: @CURSORPOS),
   (Name: 'CURSORX'; svType: svInteger; Size: 4; Data: @CURSORX),
   (Name: 'CURSORY'; svType: svInteger; Size: 4; Data: @CURSORY),
   (Name: 'CURSORCHAR'; svType: svByte; Size: 1; Data: @CURSORCHAR),
   (Name: 'CURSORFG'; svType: svByte; Size: 1; Data: @CURSORFG),
   (Name: 'CURSORBG'; svType: svByte; Size: 1; Data: @CURSORBG),
   (Name: 'INPUTLINE'; svType: svString; Size: 0; Data: @INPUTLINE),
   (Name: 'INPUTCSR1'; svType: svByte; Size: 1; Data: @INPUTCSR1),
   (Name: 'INPUTCSR2'; svType: svByte; Size: 1; Data: @INPUTCSR2),
   (Name: 'INPUTPOSX'; svType: svInteger; Size: 4; Data: @INPUTPOSX),
   (Name: 'INPUTPOSY'; svType: svInteger; Size: 4; Data: @INPUTPOSY),
   (Name: 'INPUTERROR'; svType: svBoolean; Size: 1; Data: @INPUTERROR),
   (Name: 'INPUTERRORHANDLED'; svType: svBoolean; Size: 1; Data: @INPUTERRORHANDLED),
   (Name: 'INPUTERRVAL'; svType: svaFloat; Size: 8; Data: @INPUTERRVAL),
   (Name: 'INFORMAT'; svType: svString; Size: 0; Data: @INFORMAT),
   (Name: 'INPUTBACK'; svType: svString; Size: 0; Data: @INPUTBACK),
   (Name: 'ERRORSTATE'; svType: svBoolean; Size: 1; Data: @ERRORSTATE),
   (Name: 'LINK'; svType: svInteger; Size: 4; Data: @LINK),
   (Name: 'SCREENLOCK'; svType: svBoolean; Size: 1; Data: @SCREENLOCK),
   (Name: 'LASTERROR'; svType: svInteger; Size: 4; Data: @LASTERROR),
   (Name: 'LASTERRORLINE'; svType: svInteger; Size: 4; Data: @LASTERRORLINE),
   (Name: 'LASTERRORSTATEMENT'; svType: svInteger; Size: 4; Data: @LASTERRORSTATEMENT),
   (Name: 'CONTLINE'; svType: svInteger; Size: 4; Data: @CONTLINE),
   (Name: 'CONTSTATEMENT'; svType: svInteger; Size: 4; Data: @CONTSTATEMENT),
   (Name: 'COMMAND_TOKENS'; svType: svString; Size: 0; Data: @COMMAND_TOKENS),
   (Name: 'PROGSTATE'; svType: svInteger; Size: 4; Data: @PROGSTATE),
   (Name: 'FRAMES'; svType: svLongWord; Size: 4; Data: @FRAMES),
   (Name: 'FLASHSTATE'; svType: svInteger; Size: 4; Data: @FLASHSTATE),
   (Name: 'EDITERROR'; svType: svBoolean; Size: 1; Data: @EDITERROR),
   (Name: 'EDITERRORPOS'; svType: svInteger; Size: 4; Data: @EDITERRORPOS),
   (Name: 'PROGLINE'; svType: svInteger; Size: 4; Data: @PROGLINE),
   (Name: 'SHOWLINE'; svType: svInteger; Size: 4; Data: @SHOWLINE),
   (Name: 'DBGSTR'; svType: svString; Size: 0; Data: @DBGSTR),
   (Name: 'FPS'; svType: svaFloat; Size: 8; Data: @FPS),
   (Name: 'FRAME_MS'; svType: svaFloat; Size: 8; Data: @FRAME_MS),
   (Name: 'CAPSLOCK'; svType: svInteger; Size: 4; Data: @CAPSLOCK),
   (Name: 'NUMLOCK'; svType: svInteger; Size: 4; Data: @NUMLOCK),
   (Name: 'INSERT'; svType: svBoolean; Size: 1; Data: @INSERT),
   (Name: 'KEYSTATE'; svType: svArray; Size: 256; Data: @KEYSTATE[0]),
   (Name: 'REPDEL'; svType: svLongWord; Size: 4; Data: @REPDEL),
   (Name: 'REPPER'; svType: svLongWord; Size: 4; Data: @REPPER),
   (Name: 'REPCOUNT'; svType: svLongWord; Size: 4; Data: @REPCOUNT),
   (Name: 'DEBUGVAL'; svType: svLongWord; Size: 4; Data: @DEBUGVAL),
   (Name: 'VOLUME'; svType: svaFloat; Size: 8; Data: @VOLUME),
   (Name: 'CLICKBANK'; svType: svInteger; Size: 4; Data: @CLICKBANK),
   (Name: 'OKSNDBANK'; svType: svInteger; Size: 4; Data: @OKSNDBANK),
   (Name: 'ERRSNDBANK'; svType: svInteger; Size: 4; Data: @ERRSNDBANK),
   (Name: 'MOUSEX'; svType: svInteger; Size: 4; Data: @MOUSEX),
   (Name: 'MOUSEY'; svType: svInteger; Size: 4; Data: @MOUSEY),
   (Name: 'MOUSEWHEEL'; svType: svInteger; Size: 4; Data: @MOUSEWHEEL),
   (Name: 'MOUSEBTN'; svType: svLongWord; Size: 4; Data: @MOUSEBTN),
   (Name: 'M_DELTAX'; svType: svInteger; Size: 4; Data: @M_DELTAX),
   (Name: 'M_DELTAY'; svType: svInteger; Size: 4; Data: @M_DELTAY),
   (Name: 'AUTOSAVE'; svType: svBoolean; Size: 1; Data: @AUTOSAVE),
   (Name: 'HOMEFOLDER'; svType: svString; Size: 0; Data: @HOMEFOLDER),
   (Name: 'QUITMSG'; svType: svBoolean; Size: 1; Data: @QUITMSG),
   (Name: 'MP3AVAILABLE'; svType: svBoolean; Size: 1; Data: @MP3AVAILABLE),
   (Name: 'MODAVAILABLE'; svType: svBoolean; Size: 1; Data: @MODAVAILABLE),
   (Name: 'FLACAVAILABLE'; svType: svBoolean; Size: 1; Data: @FLACAVAILABLE),
   (Name: 'OGGAVAILABLE'; svType: svBoolean; Size: 1; Data: @OGGAVAILABLE),
   (Name: 'MAXRATE'; svType: svLongWord; Size: 4; Data: @MAXRATE),
   (Name: 'MINRATE'; svType: svLongWord; Size: 4; Data: @MINRATE),
   (Name: 'MUSICHANDLE'; svType: svLongWord; Size: 4; Data: @MUSICHANDLE),
   (Name: 'MUSICISSTREAM'; svType: svBoolean; Size: 1; Data: @MUSICISSTREAM),
   (Name: 'LOGGING'; svType: svBoolean; Size: 1; Data: @LOGGING),
   (Name: 'LISTWINDOW'; svType: svInteger; Size: 4; Data: @LISTWINDOW),
   (Name: 'COMMANDWINDOW'; svType: svInteger; Size: 4; Data: @COMMANDWINDOW),
   (Name: 'LISTTOPINDEX'; svType: svaFloat; Size: 8; Data: @LISTTOPINDEX),
   (Name: 'LISTLEFTINDEX'; svType: svaFloat; Size: 8; Data: @LISTLEFTINDEX),
   (Name: 'LISTSELLINE'; svType: svInteger; Size: 4; Data: @LISTSELLINE),
   (Name: 'LISTLINECOUNT'; svType: svInteger; Size: 4; Data: @LISTLINECOUNT),
   (Name: 'LISTCOLCOUNT'; svType: svInteger; Size: 4; Data: @LISTCOLCOUNT),
   (Name: 'LISTVISLINES'; svType: svInteger; Size: 4; Data: @LISTVISLINES),
   (Name: 'LISTVISCOLS'; svType: svInteger; Size: 4; Data: @LISTVISCOLS),
   (Name: 'LISTWINX'; svType: svInteger; Size: 4; Data: @LISTWINX),
   (Name: 'LISTWINY'; svType: svInteger; Size: 4; Data: @LISTWINY),
   (Name: 'LISTWINW'; svType: svInteger; Size: 4; Data: @LISTWINW),
   (Name: 'LISTWINH'; svType: svInteger; Size: 4; Data: @LISTWINH),
   (Name: 'CCOMMANDWINDOW'; svType: svBoolean; Size: 1; Data: @CCOMMANDWINDOW),
   (Name: 'CLISTWINDOW'; svType: svBoolean; Size: 1; Data: @CLISTWINDOW),
   (Name: 'COMMANDWINX'; svType: svInteger; Size: 4; Data: @COMMANDWINX),
   (Name: 'COMMANDWINY'; svType: svInteger; Size: 4; Data: @COMMANDWINY),
   (Name: 'COMMANDWINW'; svType: svInteger; Size: 4; Data: @COMMANDWINW),
   (Name: 'COMMANDWINH'; svType: svInteger; Size: 4; Data: @COMMANDWINH),
   (Name: 'COMMANDSIZETLX'; svType: svInteger; Size: 4; Data: @COMMANDSIZETLX),
   (Name: 'COMMANDSIZETLY'; svType: svInteger; Size: 4; Data: @COMMANDSIZETLY),
   (Name: 'COMMANDSIZEBRX'; svType: svInteger; Size: 4; Data: @COMMANDSIZEBRX),
   (Name: 'COMMANDSIZEBRY'; svType: svInteger; Size: 4; Data: @COMMANDSIZEBRY),
   (Name: 'SHOWLIST'; svType: svBoolean; Size: 1; Data: @SHOWLIST),
   (Name: 'TEMPDIR'; svType: svString; Size: 0; Data: @TEMPDIR),
   (Name: 'SCREENPOINTER'; svType: svPointer; Size: 4; Data: @SCREENPOINTER),
   (Name: 'SCREENBANK'; svType: svInteger; Size: 4; Data: @SCREENBANK),
   (Name: 'SCREENWIDTH'; svType: svInteger; Size: 4; Data: @SCREENWIDTH),
   (Name: 'SCREENHEIGHT'; svType: svInteger; Size: 4; Data: @SCREENHEIGHT),
   (Name: 'SCREENX'; svType: svInteger; Size: 4; Data: @SCREENX),
   (Name: 'SCREENY'; svType: svInteger; Size: 4; Data: @SCREENY),
   (Name: 'WINDOWPOINTER'; svType: svPointer; Size: 4; Data: @WINDOWPOINTER),
   (Name: 'SCRBANKPOINTER'; svType: svPointer; Size: 4; Data: @SCRBANKPOINTER),
   (Name: 'FONTBANKID'; svType: svInteger; Size: 4; Data: @FONTBANKID),
   (Name: 'FONTWIDTH'; svType: svInteger; Size: 4; Data: @FONTWIDTH),
   (Name: 'FONTHEIGHT'; svType: svInteger; Size: 4; Data: @FONTHEIGHT),
   (Name: 'FONTTRANSPARENT'; svType: svInteger; Size: 4; Data: @FONTTRANSPARENT),
   (Name: 'FONTTYPE'; svType: svInteger; Size: 4; Data: @FONTTYPE),
   (Name: 'LOWERSAVE'; svType: svString; Size:0; Data: @LOWERSAVE),
   (Name: 'CPAPER'; svType: svInteger; Size: 4; Data: @CPAPER),
   (Name: 'CINK'; svType: svInteger; Size: 4; Data: @CINK),
   (Name: 'CINVERSE'; svType: svInteger; Size: 4; Data: @CINVERSE),
   (Name: 'COVER'; svType: svInteger; Size: 4; Data: @COVER),
   (Name: 'T_PAPER'; svType: svInteger; Size: 4; Data: @T_PAPER),
   (Name: 'T_INK'; svType: svInteger; Size: 4; Data: @T_INK),
   (Name: 'T_INVERSE'; svType: svInteger; Size: 4; Data: @T_INVERSE),
   (Name: 'T_OVER'; svType: svInteger; Size: 4; Data: @T_OVER),
   (Name: 'DRPOSX'; svType: svaFloat; Size: 8; Data: @DRPOSX),
   (Name: 'DRPOSY'; svType: svaFloat; Size: 8; Data: @DRPOSY),
   (Name: 'DRHEADING'; svType: svaFloat; Size: 8; Data: @DRHEADING),
   (Name: 'XORG'; svType: svInteger; Size: 4; Data: @XORG),
   (Name: 'YORG'; svType: svInteger; Size: 4; Data: @YORG),
   (Name: 'PRPOSX'; svType: svInteger; Size: 4; Data: @PRPOSX),
   (Name: 'PRPOSY'; svType: svInteger; Size: 4; Data: @PRPOSY),
   (Name: 'TABSIZE'; svType: svInteger; Size: 4; Data: @TABSIZE),
   (Name: 'SCROLLCNT'; svType: svInteger; Size: 4; Data: @SCROLLCNT),
   (Name: 'NXTLINE'; svType: svInteger; Size: 4; Data: @NXTLINE),
   (Name: 'NXTSTATEMENT'; svType: svInteger; Size: 4; Data: @NXTSTATEMENT),
   (Name: 'MATHMODE'; svType: svInteger; Size: 4; Data: @MATHMODE),
   (Name: 'BASE'; svType: svLongWord; Size: 4; Data: @BASE),
   (Name: 'SPLITSTATEMENTS'; svType: svBoolean; Size: 4; Data: @SPLITSTATEMENTS),
   (Name: 'SPLITREMS'; svType: svBoolean; Size: 1; Data: @SPLITREMS),
   (Name: 'EDITORWRAP'; svType: svBoolean; Size: 1; Data: @EDITORWRAP),
   (Name: 'NUBMODE1'; svType: svInteger; Size: 4; Data: @NUBMODE1),
   (Name: 'NUBMODE2'; svType: svInteger; Size: 4; Data: @NUBMODE1),
   (Name: 'BATTLEVEL'; svType: svInteger; Size: 4; Data: @BATTLEVEL),
   (Name: 'CBLACK'; svType: svLongWord; Size: 4; Data: @CBLACK),
   (Name: 'CBLUE'; svType: svLongWord; Size: 4; Data: @CBLUE),
   (Name: 'CRED'; svType: svLongWord; Size: 4; Data: @CRED),
   (Name: 'CMAGENTA'; svType: svLongWord; Size: 4; Data: @CMAGENTA),
   (Name: 'CGREEN'; svType: svLongWord; Size: 4; Data: @CGREEN),
   (Name: 'CCYAN'; svType: svLongWord; Size: 4; Data: @CCYAN),
   (Name: 'CYELLOW'; svType: svLongWord; Size: 4; Data: @CYELLOW),
   (Name: 'CWHITE'; svType: svLongWord; Size: 4; Data: @CWHITE),
   (Name: 'CGREY'; svType: svLongWord; Size: 4; Data: @CGREY),
   (Name: 'CBRIGHTBLUE'; svType: svLongWord; Size: 4; Data: @CBRIGHTBLUE),
   (Name: 'CBRIGHTRED'; svType: svLongWord; Size: 4; Data: @CBRIGHTRED),
   (Name: 'CBRIGHTMAGENTA'; svType: svLongWord; Size: 4; Data: @CBRIGHTMAGENTA),
   (Name: 'CBRIGHTGREEN'; svType: svLongWord; Size: 4; Data: @CBRIGHTGREEN),
   (Name: 'CBRIGHTCYAN'; svType: svLongWord; Size: 4; Data: @CBRIGHTCYAN),
   (Name: 'CBRIGHTYELLOW'; svType: svLongWord; Size: 4; Data: @CBRIGHTYELLOW),
   (Name: 'CBRIGHTWHITE'; svType: svLongWord; Size: 4; Data: @CBRIGHTWHITE),
   (Name: 'LASTFRAMETIME'; svType: svaFloat; Size: 8; Data: @LASTFRAMETIME),
   (Name: 'FDIST'; svType: svaFloat; Size: 8; Data: @FDIST),
   (Name: 'SORGX'; svType: svaFloat; Size: 8; Data: @SORGX),
   (Name: 'SORGY'; svType: svaFloat; Size: 8; Data: @SORGY),
   (Name: 'SORGW'; svType: svaFloat; Size: 8; Data: @SORGW),
   (Name: 'SORGH'; svType: svaFloat; Size: 8; Data: @SORGH),
   (Name: 'EDFONTSCALEX'; svType: svaFloat; Size: 8; Data: @EDFONTSCALEX),
   (Name: 'EDFONTSCALEY'; svType: svaFloat; Size: 8; Data: @EDFONTSCALEY),
   (Name: 'MENUBARPAPER'; svType: svLongWord; Size: 4; Data: @MENUBARPAPER),
   (Name: 'MENUBARINK'; svType: svLongWord; Size: 4; Data: @MENUBARINK),
   (Name: 'MENUBAROUTLINE'; svType: svLongWord; Size: 4; Data: @MENUBAROUTLINE),
   (Name: 'MENUPAPER'; svType: svLongWord; Size: 4; Data: @MENUPAPER),
   (Name: 'MENUINK'; svType: svLongWord; Size: 4; Data: @MENUINK),
   (Name: 'MENUDISABLEDINK'; svType: svLongWord; Size: 4; Data: @MENUDISABLEDINK),
   (Name: 'MENUOUTLINE'; svType: svLongWord; Size: 4; Data: @MENUOUTLINE),
   (Name: 'MENUHLOUTLINE'; svType: svLongWord; Size: 4; Data: @MENUHLOUTLINE),
   (Name: 'MENUHIGHLIGHT'; svType: svLongWord; Size: 4; Data: @MENUHIGHLIGHT),
   (Name: 'MENUCAPHIGHLIGHT'; svType: svLongWord; Size: 4; Data: @MENUCAPHIGHLIGHT),
   (Name: 'MENUSEP'; svType: svLongWord; Size: 4; Data: @MENUSEP),
   (Name: 'MENUSHOWING'; svType: svBoolean; Size: 1; Data: @MENUSHOWING),
   (Name: 'INTSCALING'; svType: svBoolean; size: 1; Data: @INTSCALING),
   (Name: 'VSYNCENABLED'; svType: svBoolean; size: 1; Data: @VSYNCENABLED),
   (Name: 'CLICKVOL'; svType: svaFloat; Size: 8; Data: @CLICKVOL),
   (Name: 'AUTOSAVETIME'; svType: svLongWord; Size: 4; Data: @AUTOSAVETIME),
   (Name: 'CSTROKE'; svType: svaFloat; Size: 8; Data: @CSTROKE),
   (Name: 'T_STROKE'; svType: svaFloat; Size: 8; Data: @T_STROKE),

   (Name: 'BACKCLR'; svType: svString; Size: 0; Data: @BackClr),
   (Name: 'NOCLR'; svType: svString; Size: 0; Data: @noClr),
   (Name: 'KWDCLR'; svType: svString; Size: 0; Data: @kwdClr),
   (Name: 'FNCLR'; svType: svString; Size: 0; Data: @fnClr),
   (Name: 'NUMCLR'; svType: svString; Size: 0; Data: @numClr),
   (Name: 'HEXCLR'; svType: svString; Size: 0; Data: @hexClr),
   (Name: 'BINCLR'; svType: svString; Size: 0; Data: @binClr),
   (Name: 'BASECLR'; svType: svString; Size: 0; Data: @baseClr),
   (Name: 'STRCLR'; svType: svString; Size: 0; Data: @strClr),
   (Name: 'NVCLR'; svType: svString; Size: 0; Data: @nvClr),
   (Name: 'SVCLR'; svType: svString; Size: 0; Data: @svClr),
   (Name: 'REMCLR'; svType: svString; Size: 0; Data: @remClr),
   (Name: 'CONSTCLR'; svType: svString; Size: 0; Data: @constClr),
   (Name: 'SYMCLR'; svType: svString; Size: 0; Data: @symClr),
   (Name: 'LINCLR'; svType: svString; Size: 0; Data: @linClr),
   (Name: 'RELCLR'; svType: svString; Size: 0; Data: @relClr),
   (Name: 'MATHCLR'; svType: svString; Size: 0; Data: @mathClr),
   (Name: 'LABCLR'; svType: svString; Size: 0; Data: @labClr),
   (Name: 'SELCLR'; svType: svString; Size: 0; Data: @selClr),
   (Name: 'SELUFCLR'; svType: svString; Size: 0; Data: @selUFClr),
   (Name: 'SEARCHCLR'; svType: svString; Size: 0; Data: @searchClr),
   (Name: 'NOSEARCHCLR'; svType: svString; Size: 0; Data: @noSearchClr),
   (Name: 'BRACEHLTCLR'; svType: svString; Size: 0; Data: @BraceHltClr),
   (Name: 'BRACECLR'; svType: svString; Size: 0; Data: @BraceClr),

   (Name: 'LINECLR'; svType: svInteger; Size: 4; Data: @lineClr),
   (Name: 'LINEERRCLR'; svTYpe: svInteger; Size: 4; Data: @LineErrClr),
   (Name: 'GUTTERCLR'; svType: svInteger; Size: 4; Data: @gutterClr),
   (Name: 'PAPERCLR'; svType: svInteger; Size: 4; Data: @paperClr),
   (Name: 'PROGLINECLR'; svType: svInteger; Size: 4; Data: @progLineClr),
   (Name: 'PROGLINEGTR'; svType: svInteger; Size: 4; Data: @progLineGtr),

   (Name: 'WINBACK'; svType: svInteger; Size: 4; Data: @winBack),
   (Name: 'CAPBACK'; svType: svInteger; Size: 4; Data: @capBack),
   (Name: 'WINBORDER'; svType: svInteger; Size: 4; Data: @winBorder),
   (Name: 'CAPTEXT'; svType: svInteger; Size: 4; Data: @capText),
   (Name: 'CAPINACTIVE'; svType: svInteger; Size: 4; Data: @capInactive),
   (Name: 'GRIPCLR'; svType: svInteger; Size: 4; Data: @gripClr),

   (Name: 'SCROLLBACK'; svType: svInteger; Size: 4; Data: @scrollBack),
   (Name: 'SCROLLTRACK'; svType: svInteger; Size: 4; Data: @scrollTrack),
   (Name: 'SCROLLACTIVE'; svType: svInteger; Size: 4; Data: @scrollActive),
   (Name: 'SCROLLINACTIVE'; svType: svInteger; Size: 4; Data: @scrollInactive),
   (Name: 'SCROLLTHUMB'; svType: svInteger; Size: 4; Data: @scrollThumb),
   (Name: 'LASTINKEYFRAME'; svType: svLongWord; Size: 4; Data: @LASTINKEYFRAME),
   (Name: 'GAPSIZE'; svType: svInteger; Size: 4; Data: @BSIZE),
   (Name: 'NATWIDTH'; svType: svLongWord; Size: 4; Data: @REALSCREENWIDTH),
   (Name: 'NATHEIGHT'; svType: svLongWord; Size: 4; Data: @REALSCREENHEIGHT),
   (Name: 'CIRCLEASPECT'; svType: svBoolean; Size: 1; Data: @CIRCLEASPECT),
   (Name: 'SHOWFPS'; svType: svBoolean; Size: 1; Data: @SHOWFPS),
   (Name: 'FPSSTR'; svType: svString; Size: 0; Data: @FPSSTRING),
   (Name: 'OSD'; svType: svString; Size: 0; Data: @OSD));


  Function  SP_GetSysVarN(ID: aString; Var Error: TSP_ErrorCode): aFloat;
  Function  SP_GetSysVarS(ID: aString; Var Error: TSP_ErrorCode): aString;
  Procedure SP_SetSysVar(ID: aString; Val: aFloat; Str: aString; Var Error: TSP_ErrorCode);

implementation

Uses SP_Editor;

Function SP_FindSysVar(ID: aString): Integer;
Begin

  ID := Upper(ID);

  Result := 0;
  While Result <= High(SysVars) Do Begin
    If SysVars[Result].Name = ID Then
      Break;
    Inc(Result);
  End;

  If Result > High(SysVars) then
    Result := -1;

End;

Function SP_GetSysVarN(ID: aString; Var Error: TSP_ErrorCode): aFloat;
Var
  Idx: Integer;
Begin

  // Find the SysVar

  Result := 0.0;
  Idx := SP_FindSysVar(ID);

  If Idx >= 0 Then Begin

    Case SysVars[Idx].svType Of
      svString, svArray:
        Begin
          Error.Code := SP_ERR_INVALID_SYSVAR_TYPE;
        End;
      svBoolean:
        Begin
          Result := Byte(pBoolean(SysVars[Idx].Data)^);
        End;
      svLongWord:
        Begin
          Result := pLongWord(SysVars[Idx].Data)^;
        End;
      svaFloat:
        Begin
          Result := gaFloat(SysVars[Idx].Data);
        End;
      svInteger:
        Begin
          Result := pInteger(SysVars[Idx].Data)^;
        End;
      svPointer:
        Begin
          Result := pLongWord(SysVars[Idx].Data)^;
        End;
      svByte:
        Begin
          Result := pByte(SysVars[Idx].Data)^;
        End;
    End;

  End Else

    Error.Code := SP_ERR_INVALID_SYSVAR;

End;

Function SP_GetSysVarS(ID: aString; Var Error: TSP_ErrorCode): aString;
Var
  Idx: Integer;
  Ptr: pByte;
Begin

  // Find the SysVar

  Result := '';
  Idx := SP_FindSysVar(ID);

  If Idx >= 0 Then Begin

    Case SysVars[Idx].svType Of
      svString:
        Begin
          Result := paString(SysVars[Idx].Data)^;
        End;
      svArray:
        Begin
          SetLength(Result, SysVars[Idx].Size);
          Ptr := pByte(SysVars[Idx].Data);
          For Idx := 0 To SysVars[Idx].Size -1 Do Begin
            pByte(@Result[Idx +1])^ := Ptr^;
            Inc(Ptr);
          End;
        End;
      svBoolean, svLongWord, svaFloat, svInteger, svPointer, svByte:
        Begin
          Error.Code := SP_ERR_INVALID_SYSVAR_TYPE;
        End;
    End;

  End Else

    Error.Code := SP_ERR_INVALID_SYSVAR;

End;

Procedure SP_SetSysVar(ID: aString; Val: aFloat; Str: aString; Var Error: TSP_ErrorCode);
Var
  Idx: Integer;
Begin

  // Find the SysVar.

  Idx := SP_FindSysVar(ID);

  // Set the data parameter according to the value passed

  If Idx >= 0 Then Begin

    Case SysVars[Idx].svType Of
      svString:
        Begin
          paString(SysVars[Idx].Data)^ := Str;
        End;
      svArray:
        Begin
          If Length(Str) = SysVars[Idx].Size Then
            CopyMem(SysVars[Idx].Data, @Str[1], SysVars[Idx].Size)
          Else
            Error.Code := SP_ERR_INVALID_SYSVAR_SIZE;
        End;
      svBoolean:
        Begin
          pBoolean(SysVars[Idx].Data)^ := Round(Val) <> 0;
        End;
      svLongWord:
        Begin
          If (Val >= 0) And (Val <= $FFFFFFFF) Then
            pLongWord(SysVars[Idx].Data)^ := Round(Val)
          Else
            Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
        End;
      svaFloat:
        Begin
          WriteaFloat(SysVars[Idx].Data, Val);
        End;
      svInteger:
        Begin
          pInteger(SysVars[Idx].Data)^ := Round(Val);
        End;
      svPointer:
        Begin
          If (Val >= 0) And (Val <= $FFFFFFFF) Then
            pLongWord(SysVars[Idx].Data)^ := Round(Val)
          Else
            Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
        End;
      svByte:
        Begin
          If (Val >= 0) And (Val <= $FF) Then
            pByte(SysVars[Idx].Data)^ := Round(Val) And 255
          Else
            Error.Code := SP_ERR_INTEGER_OUT_OF_RANGE;
        End;
    End;

  End Else
    Error.Code := SP_ERR_INVALID_SYSVAR;

End;

Initialization

  FPSSCALE := 2;
  MODALWINDOW := -1;
  CIRCLEASPECT := False;

end.
